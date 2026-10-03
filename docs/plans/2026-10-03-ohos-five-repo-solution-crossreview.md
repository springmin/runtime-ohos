# OHOS 五仓移植 — 问题/方案交叉评审（2026-10-03）

> 范围：runtime-ohos / sdk-ohos / aspnetcore-ohos / ohos-workload / maui-ohos 五仓在移植中
> **已解决的具体问题**及其**解法**；对"同一根因"是否出现**不同解法**做判定，并对异解对比优劣。
> 证据源：各仓代码/工作流（`eng/ohos-install/*`、`msbuild-pipe-patch`、`lib-dotnet-env.sh`、
> workload manifest、maui slice 提交）、本仓计划文档（rc2 分片 §8/§9、平台身份、fork-sync playbook、
> rc2-line-notes、hap-packaging "Known environment quirks"）、以及上游 PR（#132827/#132953/#134670）。

## 1. 总表：问题域 × 载体 × 解法（★=同题异解）

| # | 问题（根因） | 载体 | 解法 | 异解 |
|---|---|---|---|---|
| A | `/tmp` 只读 + 拒 AF_UNIX bind | **runtime** | `TARGET_OPENHARMONY` 守卫 + **CoreLib 三修**（共享内存管理回退、无 robust mutex 回退、命名；#132827） | ★ |
| | | sdk | 安装器把 `TMPDIR` 写入 shell profile；CLI `OpenHarmonyEnvironmentDefaults` 设默认 | ★ |
| | | ohos-workload | `lib-dotnet-env.sh`：TMPDIR 择优（短路径/可写探测/长度守卫）+ 服务器关闭 | ★ |
| B | MSBuild/编译器服务器握手挂起 | **sdk** | **msbuild-pipe-patch**（Cecil 翻转一条 IL → 管道走 `Path.GetTempPath()`/TMPDIR 感知；Blazor WASM 构建 **5:06→15.4s**） | ★★ |
| | | ohos-workload | `lib-dotnet-env.sh` 关 MSBuild server；fork 侧再关 **Roslyn 编译器服务器**（`UseSharedCompilation=false`，实测 300s+→6s） | ★★ |
| C | 平台身份：`IsOSPlatform("Linux")=false` | **runtime** | ①先试"报 LINUX"（**弃**：破坏 `openharmony` 身份与 S1b）→ ②**别名方案**：规范名 `OPENHARMONY` + 追加接受 `LINUX` + `IsLinux()=true` | ★ |
| | | sdk | CLI 用 `IsOSPlatform("openharmony")` + `SupportedPlatform` 项（S1b）；RID 图 openharmony→linux-musl | ★ |
| D | RID 图：openharmony 无上游基座 | **runtime** | 上游 `PortableRuntimeIdentifierGraph.json` 加 openharmony（#132953）；`TargetsLinux` 含 openharmony（linux 组） | ★ |
| | | sdk | fork 的 override 图（bootstrap 注入，legacy 图仅 fork 本地）；RID 加宽 | ★ |
| | | ohos-workload | workload 内 **ridgraph 副本**：与 sdk 规范图**逐字节同步** + 摘要守卫 | ★ |
| E | AspNetCore 传递 pack 解析失败（NU1101） | ohos-workload | ①用户侧开关 `DisableTransitiveFrameworkReferenceDownloads`（治标）→ ②**manifest 收编 pack**（`packs`+`workloads.*.packs`）+ KFR **RID 加宽**（`.28` 起免开关） | ★ |
| F | 设备拒绝未签/坏签 ELF | sdk | ①CI 预签（设备拒 EPERM ✗）→ ②安装器 **`binary-sign-tool` 自举**（默认路径）；③download 镜像回退 | ★ |
| | | sdk（selfsign 线） | ④跨构建 selfsign（SIGSEGV ✗）→ ⑤**设备自建 AOT**（剥离未签名 + 自举验证）→ 重上发布 + 锚 | ★ |
| | | ohos-workload | ⑥宿主 `.so`/壳 **预签**（`SKIP_SIGN=1` 可选）+ 打包期 ElfSigner | ★ |
| G | NativeAOT 在 OHOS | sdk | fork **aot-packs 镜像**（`fetch-nativeaot-packs.sh` + 摘要）；AOT 覆盖层（ILCompiler/RuntimePack RID 追加） | ★ |
| | | 工具链 | 链接器修复：CI 静态 OpenSSL vs 设备 `LD_LIBRARY_PATH` 前置 NDK `llvm/lib`（libxml2 遮蔽）+ 系统 OpenSSL 后备 | ★ |
| H | GitHub 下载抖动/限速 | sdk | 安装器 `gh-proxy` 回退 + 有界重试；CI env 镜像 | ✓ |
| | | kit/设备 | by-id 下载 + `.sha256` sidecar 判据；注意 proxy 按**原 URL** 缓存（查询串击穿无效） | ✓ |
| I | 发布面一致性 | sdk | 锚刷新协议（三锚→**四锚**）；`SELFSIGN_SHA256` fail-closed；镜像工作流（当前不覆盖 `workload-*`，已发现一次滞后） | ✓ |
| J | MAUI 产品级互操作（FIX-HOME/FIX-DISMISS/FIX-WVP/FIX-BACKSIZE/T20/T21/T14/T8…） | maui | 各问题专解（arrange 下钻、桥上下文刷新、WebView 站点暂存、媒体桥、字体缩放、模板化 flyout、行高测量） | — |

## 2. 同题异解对比（优劣）

### B. 服务器握手挂起：**"修工具" vs "关服务器"**

| | sdk `msbuild-pipe-patch`（修） | ohos-workload `lib-dotnet-env`（关） |
|---|---|---|
| 机制 | Cecil 补丁翻转 IL：管道路径改走 TMPDIR | 环境关闭 MSBuild/Roslyn server（改用 in-proc） |
| 优 | **治本**：所有工具链（含用户/CI 构建）无差别受益；性能保留（实测 5:06→**15.4s**）；对未知调用方透明 | **零侵入**、零维护面；不动二进制；对上游工具升级免疫 |
| 劣 | 需随 SDK/MSBuild 版本维护补丁（IL 偏移/结构变动风险）；引入 Cecil 构建环节；补丁产物需签名/装载链配合 | 牺牲 server 收益（长构建变慢、内存/进程模型变化）；**覆盖不全**（Roslyn 服务器需另加开关，我们补的 `UseSharedCompilation=false` 即是补洞）；不能修复 3rd-party 直接连管道的场景 |
| 建议 | **保留为默认**（CI/发布链），并把"补丁覆盖点清单"文档化（MSBuild 管道 + Roslyn 管道） | **保留为兜底**（面向用户/无补丁环境）；两法组合 = 现状，判定**合理** |

### A. `/tmp` 只读/不可 bind：**库层回退 vs 环境层绕行**

| | runtime CoreLib（#132827） | sdk/工作负载 env（TMPDIR 注入） |
|---|---|---|
| 优 | 从根上消除（GetTempPath/共享内存/命名不依赖 `/tmp`），**上游可收**（已是 PR） | 覆盖面广、无代码改动、可运维 |
| 劣 | 仅覆盖 .NET 自身路径；仍需上游评审/合并 | 依赖每个入口都设对 TMPDIR；漏设即回归；对第三方原生组件无效 |
| 建议 | 双轨保留 ✓（库层为上游主线 ✓，env 为运维保险 ✓） | 同左 |

### C. 平台身份：**"报成 Linux" vs "独立身份 + 别名"**

| | 报 LINUX（弃） | OPENHARMONY + LINUX 别名（采用） |
|---|---|---|
| 优 | 最省事、所有 Linux 分支一次生效 | 保留平台独立性（评审/CA1418/S1b 语义）；工具（MSBuild）兼容通过别名达成；上游方向（方案 B）不被挡 |
| 劣 | 破坏 `IsOSPlatform("openharmony")`（S1b 失效）| 两套名称并存需要文档与测试固定（本次已补 3-way 对账） |
| 建议 | 保持现方案 ✓；上游若接收 `IsOpenHarmony()`/TFM，再评估别名去留（附录已注明） |

### E. AspNetCore 传递包：**用户开关 vs manifest 收编**

| | `DisableTransitiveFrameworkReferenceDownloads` | manifest 收编 + RID 加宽（`.28`） |
|---|---|---|
| 优 | 立即解除阻塞（无需重打包） | 用户**零开关**；与官方 KFR 模型一致；可镜像/锁定 |
| 劣 | 每个项目/每次发布都要记得加；隐藏真实解析差异 | 需要重打 workload、维护 pack 版本、加宽 RID 的一致性校验 |
| 建议 | 作为诊断手段保留；**产品默认 = 收编** ✓（已实证免开关 publish ✓） |

### F. 签名：**预签 vs 自举 vs 设备自建**

| | CI 预签 | 安装器自举（binary-sign-tool） | 设备自建 selfsign |
|---|---|---|---|
| 优 | 一次签好、分发即用（理想态） | 不依赖发布资产质量；设备上有可用的 OHOS SDK 即可 | 端到端可自证（我们实测签名被设备接受 ✓）；不依赖 CI 交叉工具链 |
| 劣 | 签名块可能被设备拒（实测 EPERM ✗）；跨构建工具坏 → 连带资产坏 | 需要设备侧工具存在且可信（shim 坑我们踩过）；时效/路径依赖 | 依赖平台修复后的运行时；分发溯源需要人工上架（本次已重上 ✓） |
| 建议 | 保留为可选（门默认关 ✓） | **默认回退** ✓（fail-closed 锚 ✓） | 作为**设备侧可信路径** ✓（发布资产 + 锚已就绪 ✓） |

### I. 发布面锚：单锚 vs 多锚（现状四锚）

- 利：每类资产独立可验证；fail-closed 防呆。
- 弊：每次重跑要**全量重测**（时间开销），镜像/分发面需二次同步（本次镜像滞后即由此暴露）。
- 建议：把"发布重跑 → 四锚刷新 → 镜像复核"写成**单张检查单**（已提案，待纳入 §9/line-notes ✓）。

## 3. 结论

1. **同题异解是"分层"而非"分裂"**：runtime 管语义（身份/RID/库回退）、sdk 管工具链与安装器、
   workload 管打包与解析、maui 管产品行为——**跨层重复实现仅两处**（B 的服务器关/修、A 的 tmp 库/环境），
   且两者都已被**实测收敛**为"一主一兜底"。
2. **需收敛/固化的点**：
   - B：把 Roslyn 服务器开关（`UseSharedCompilation=false`）与 MSBuild 补丁**同档管理**（同一入口清单），避免"全新 checkout 开箱挂"（已在 `lib-dotnet-env` 修正 ✓）。
   - H：镜像回退与 sidecar 判据统一为**一条约定**（gh-proxy 前缀 + by-id + `.sha256`），写进安装器/CI/kit 三处 README（部分已存在 ✓）。
   - I：镜像工作流覆盖 `workload-*` 发布（当前缺口，lag 事件的根因）。
3. **不建议**把五仓方案强行统一为一种（会丢层次收益）；以**"主路径 + 兜底 + 锚"**三段式作为移植方法论沉淀。
