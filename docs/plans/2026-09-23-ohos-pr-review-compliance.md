# OpenHarmony 移植 · 上游 PR 评审规则遵循报告（2026-09-23）

**范围：** `runtime-ohos` / `sdk-ohos` / `aspnetcore-ohos` / `ohos-workload` / `maui-ohos` 的 fork 分支。
**规则来源：** dotnet/runtime #132953/#132827 评审 thread、tracking issue #132866、dotnet/arcade #17608 与仓库协作约定；上游状态与评论对账引 `scan2/pr-rev/report.md`（只读输入）。
**方法：** `scan2/audit-{1,2,3}/report.md` 的偏差/违例清单逐项对账修复提交，并跑脚本化复审计（grep / sha256 / `json.load` 等值 / three-dot diff 静默 / `eng/common` 树哈希 / `gh api` 远端 ref 清单）；证据输出在 `/data/storage/el2/base/tmp/opencode/compliance/`。
**结论：** 硬违例 0（审计发现的唯一硬违例 V1 已修且复核清零）；R1–R11 全合规；有意保留 5 项、结构性 4 类、未改小项 2 个（均非评审要求，见 §④/§⑤/§⑦）。

## ① 上游评审状态摘要（2026-09-23 中午快照；arcade#17608 行更新至 2026-09-24 合并，引 pr-rev）

| 对象 | head | 状态 | 未 resolve thread | CI（head 上 check-runs） |
|---|---|---|---|---|
| runtime#132953 | `be8e6f6988d` | REVIEW_REQUIRED（jkotas 09-10 批准被新提交作废） | 4/10（全部 outdated） | 5 红：Monitor Helix、Build Analysis/Insights、**osx-arm64**（sccache 片段 11，判偶发）、父 runtime |
| runtime#132827 | `6ed2f9ab9a6` | REVIEW_REQUIRED（09-15 起停滞） | 6/7（全部 outdated） | 4 红：Monitor Helix、Build Analysis/Insights、父 runtime |
| #132866 | — | tracking issue（6 评论；3 个 scope 问题自 09-14 无答复） | n/a | — |
| arcade#17608 | `4975a234c` | **已批准并合并**：`fff3b6bb`（2026-09-24 02:36 +08）；`eng/common` 支持将随 arcade 同步自动进入 | 1/1（outdated） | — |

- 全量检索 `author:springmin`：上游 PR 仅 runtime#132953/#132827 + arcade#17608；其余 18 个 `pr/ohos-*` 为本地预备分支、无上游 PR。09-22 起三 PR/issue 无新评论（截至 09-23 中午）；arcade#17608 于 09-24 批准并合并；4 条回复/催评草稿已写未发（arcade 一条已作废，见 `2026-09-23-ohos-upstream-reply-drafts.md`；pr-rev §4③）。

## ② 规则表 R1–R11（来源评审/约定）

| R | 规则 | 来源 |
|---|---|---|
| R1 | 平台标识统一长名 `openharmony`；`ohos` 仅限 NDK/工具契约与允许的资产名 | #132953-6、#132827-1/2/3（am11/jkotas） |
| R2 | 只保留 Portable RID 图，`openharmony → #import ["any"]`，三仓同字节 | jkotas 09-21（#132953-9）；am11 09-21 |
| R3 | 不假装 Linux：RID/PortableOS 独立，C/C++ 层 NDK 决策本地化 | jkotas（#132953-1，已接受） |
| R4 | 不回退 `runtime.json`（冻结），SDK 布局只允许 portable 图覆盖 | am11 09-21（#132953-8） |
| R5 | 平台判定用 `IsOSPlatform("openharmony")` / `OSPlatformName`，无字符串硬编码比较 | akoeplinger（#132827-6） |
| R6 | 禁改同步区 `eng/common`；OHOS 支持走 arcade#17608 合并后同步回 | am11 issue 评论 + 同步规则 |
| R7 | 注释简洁，不注水 | jkotas（#132953-7） |
| R8 | 不依赖 Mono（OHOS 默认子集只用 CoreCLR） | jkotas（#132953-3） |
| R9 | 抑制须带退出条件；公共 API 无未批准新增；arm64-only 文档化 | 仓库规则 + pr-rev R6/R7/R9 |
| R10 | `DOTNET_` 前缀、不手改生成文件、单主题提交 | AGENTS.md/上游通用（COMPlus_/生成物） |
| R11 | 未经许可不推上游（fork 分支/发布标签口径） | 协作约定 |

## ③ 三仓审计结论 → 修复提交 → 复审计证据

### A. `runtime-ohos`（audit-1；审计 tip `d7b730e5030`，= `origin/feature/openharmony`）

| 原判（audit-1） | 处置（本轮提交） | 复审计证据 |
|---|---|---|
| D1 R9 偏差：条件性 `NoWarn=CA1416` | **已修 + 有意保留**：`f1bc67bee25` 注释写明退出条件（具备平台 TFM 后删除） | 新增 `NoWarn` 仅 1 处且条件=中性 TFM；`pragma warning disable` 新增 0；`PublicAPI*.txt` diff 0 |
| D2/D3 R1 建议：注释残留 "ohos/OHOS" | **已修**：`39c0dc07e87`（build-commons.sh、Subsets.props 等） | grep：非 docs 词级 `ohos`=18 处全为 NDK 契约/注释/环境变量；`TargetOS=ohos`、`linux-ohos` RID、`TargetsOhos`、`IsOhos`=0 |
| D4 R8 建议：`MonoSupported=true` 未排除 | **有意保留**（非评审要求；OHOS 默认子集已排除 Mono） | `eng/Subsets.props:44-46`；`src/mono` 仅 package-lock 命中 |
| R1–R11 判定：合规 10 · 偏差 1 · 违例 0 | 偏差已闭环 | R2/R4：`PortableRuntimeIdentifierGraph.json` sha256 `24f2dd66…`、`json.load` 中 `#import ["any"]`、`runtime.json` three-dot diff 静默；R5：`.cs` 仅 `OSPlatformName` + 测试 2 处；R6：`eng/common` diff 0 行、tree `c41de916`；R8：illink `_UseManagedNtlm` 托管实现；R10：新增 `COMPlus_`=0（AGENTS.md 规则文本除外）、生成头文件 diff 0；R11：dotnet/runtime `matching-refs pr/ohos*`/`feature/ohos*`/`tls-flag-cleanup`/`illink-ntlm` 全 0 |

### B. `sdk-ohos` / `aspnetcore-ohos`（audit-2；tips `1e8827a87d` / `eace90c8fb`，= 各自 origin）

| 原判（audit-2） | 处置（本轮提交） | 复审计证据 |
|---|---|---|
| **V1 R4 违例（最高）**：SDK 布局仍用 fork runtime.json 覆盖 | **已修**：`e53b6513ac`（删钩子+检入图）+ `54d929cd4c`（构建脚本只注入 portable） | 代码中 `RidGraphOverrideRuntimeJson` 命中 0（仅历史文档）；`eng/RuntimeIdentifierGraph.openharmony.json` tracked=0；`GenerateLayout.targets` 只留 `RidGraphOverridePortableJson`，runtime.json 固定取 Platforms 包副本 |
| V2 R2/R7：README 仍写 `openharmony → {}` | **已修**：`a1b2d8896f` | `documentation/ohos-install/README.md:183` = `{"#import": ["any"]}`，只描述 portable |
| V3 R7：14 行签名注释块 | **已修**：`0759bfe684` | `Microsoft.NET.Sdk.targets` 注释 4 行 + 算法落在 `ElfSigner.cs` |
| V4 R9：冗余 `NoWarn=IDE0073` | **已修**：`df28f87336` | `eng/ohos-install/selfsign.csproj` 无 `NoWarn` |
| V5 R1 注释层残留 | **已修**：`32268b82da`（sdk）+ `eace90c8fb`（aspnet 文档） | 残留仅 `eng/ohos-install/**`、`OHOS_*`、`HarmonyOS` 事实指代（§④） |
| V6 R10：xlf 手改/单主题夹带 | **已处理**：`db7dc5545f`（按生成形状 resync）；`.omo` 早先已移除忽略 | 生成文件不让手改；aspnet `f2b9d780c0` 历史多主题属结构性（§⑤） |
| V7 R2 位置：RID 列表次序 | **已修（aspnet）**：`06517e8448` 追加到最后 OS 块之后；**sdk 未改小项**（见 §⑦） | `src/Tools/Directory.Build.props` 末位；sdk `GenerateBundledVersions.targets:295` openharmony 仍在社区 RID 首位 |
| U2：`OpenHarmonyCodesign` 公共任务无 API 备忘 | **已记录**：`4425502754` | 提交注明 fork-only、上游前须 API memo |
| R2 跨仓字节统一 | **已修**：`1e8827a87d` | sdk portable 图 sha256 `24f2dd66…` = runtime 规范文件 |
| R6/R9/R11 复核 | 合规 | 两仓 `eng/common` diff 0、tree `c41de916`；aspnet `CompatibilitySuppressions` 净改 0、pragma/NoWarn 新增 0；dotnet/{sdk,aspnetcore,maui} 的 ohos ref/PR 全 0 |

### C. `ohos-workload` / `maui-ohos`（audit-3；tips `686bf89` / `0e9d90cd`，= 各自 origin）

| 原判（audit-3） | 处置（本轮提交） | 复审计证据 |
|---|---|---|
| D1 R2 非逐字节 | **已修**：`1910c75`（3 个 pack）+ sdk `1e8827a87d` | 3 pack sha256 全 = `24f2dd66…`，`json.load` = runtime 文件（键序一致） |
| D2 R6：maui 切片删除整棵 eng/common | **结构性保留**（切片分支不能原样上游，§⑤） | HEAD tracked `eng/common`=0、全树 117 文件；上游增量须从 upstream main 另起 |
| D3 R7：6 处长注释（Hap.targets 138 行等） | **已修**：`feed6ca`（头注 138→7 行+文档）、`1375c61`/`b3fd9fb`（脚本 49→19、35→12）、`06fa9b9f`（maui 头注 10/8/8 行+`docs/openharmony-slice-notes.md`） | 复核头注行数；comment-stripped 文件与 HEAD 逐字节相同（修复代理记录） |
| D4 R10：maui 6 个多主题提交 | **结构性**（历史不可改写；新提交单主题） | 近 20 提交中历史 6 个多主题仍在；f2937413 起按主题拆分 |
| D5 R10：公共 API 未见上游提案 | **结构性待上游**：`a096881f` 标注 fork-only；须走 dotnet/maui api-proposal | `PublicAPI/net-openharmony` Shipped 1 + Unshipped 1359 行 |
| D6 R1 文档 typo | **已修**：`1017674f` | `docs/openharmony-platform-slice.md:29` = `OpenHarmonyRuntime.IsOpenHarmony` |
| D7 R2 口径：11.0.100 band 陈旧 | **已修**：`ad1795d` | 两个 band manifest 均 `1.0.0-preview.24` |
| D8 R9 灰区：`WarningsNotAsErrors` | **有意保留（fork 车）**：`a096881f` 注释"never travel upstream" | 仅存在于切片 csproj；workload 无 |
| R2/R9/R10/R11 复核 | 合规 | workload `NoWarn`/`pragma`/`COMPlus_`=0、`f54e222` 移除 IDE0073；RID 非便携图=冻结 runtime.json+4 条（有意）；远端仅 `master`/`main`+`feature/openharmony` |

**复审计汇总：** R1–R11 按各仓适用维度逐条复核（sdk/aspnet 的 R5 不适用）；硬违例 0；有意保留 5 项；结构性 4 类；未改小项 2 个（sdk RID 次序、workload pack 无 graph sha256 自动校验）。

## ④ 有意保留清单（允许口径，连续复审计不变）

1. **NDK/工具契约字面量**：`ohos.toolchain.cmake`、`CMAKE_SYSTEM_NAME=OHOS`、`aarch64-linux-ohos` 等 NDK triple、`OHOS_ARCH`。
2. **环境变量与冻结 ABI**：`OHOS_NDK_HOME`、48 个 `OHOS_*` 变量、`ohos_host_*`/`OHOS_HOST_APP_CONTEXT`（跨 ArkTS/NAPI，改名破坏已发布 bundle）。
3. **仓/分支/资产标签**：仓库名 `ohos-workload`、`pr/ohos-*` 分支、`v*-ohos`/`*-ohos` 发布资产（改名需连带 mirror）。
4. **事实性 `HarmonyOS`**：NDK/设备/签名语境（非平台标识）；`harmonybrew` 路径、npm `@ohos/*`。
5. **历史文档与生成物**：`docs/plans/**`、`eng/ohos-install/build/*.md`、workload 非便携 `RuntimeIdentifierGraph.openharmony.json`（= 冻结 runtime.json + 4 条 openharmony）。

## ⑤ 结构性说明（不可通过改码消除）

1. **maui 切片 fork 删除上游文件**：`e55e1e27` 删除含 `eng/common` 的 26,322 个上游文件——该分支定位为切片工作分支（117 文件），**不能原样作为 PR**；上游增量必须从 upstream main 起、只含 `src/Core/src/Platform/OpenHarmony/**` + 配置文件，公共 API 先走 api-proposal。
2. **历史多主题提交不可改**：maui 6 个历史提交（87ceb75f 等）与 aspnet f2b9d780c0 已推 fork 且被引用，改写会破坏 pin/回归基线；新提交已单主题。
3. **公共 API 走 api-proposal**：`OSPlatform.OpenHarmony`/`IsOpenHarmony`（runtime，draft 见 `2026-09-18-ohos-openharmony-api-proposal.md`）与 maui 1359 行基线在获批前保持 fork 内。
4. **`WarningsNotAsErrors`/`NuGetAudit=false` 仅 fork 编译车**：`a096881f` 已注明禁止随切片上游。

## ⑥ 待上游动作（评论草稿在 pr-rev，未发送）

1. **arcade#17608：已合并，无需动作**（`fff3b6bb`，2026-09-24 02:36 +08）→ `eng/common` OpenHarmony 支持将随 arcade 同步自动进入；同步落地后 runtime#132953 可复评/重跑（不再构成跨仓前置）。
2. **#132953**：rerun（osx-arm64 sccache 偶发）→ 7 天内请求重批 → 请 reviewer resolve 4 条 outdated thread（`runtime.json` 已回退、`any` 已 import、`__PortableTargetOS` 已删）。
3. **#132827**：请复评并 resolve 6 条 outdated thread（引 `6ed2f9ab9a6`）。
4. **#132866**：第三次请求答复 3 个 scope 问题（illink 归属 / S1c codesign 上游 / 提交粒度），解除 N1–N16 排队。
5. **#19–#21 追加修复（本轮落地）：** headless abc `24.0.0.0` → `13.0.1.0`（`ohos-workload 4e5491d`，随 kit #21；模板 README 指向 `ARKTS_SHELL_VARIANT=headless`，`e995cef`）与 workload bundle 外锚 `WORKLOAD_BUNDLE_SHA256`（`sdk-ohos/eng/ohos-install/versions.env:74`；锚优先/`WORKLOAD_SHA256` 覆盖告警与回归用例见 `install-dotnet-ohos.sh`、`tests/test-installer-verification.sh`——该批已入库并推送：`sdk-ohos 821330d55e`（`versions.env` 四锚）。

## ⑦ 不确定项

- **sdk V7 未改小项**：`GenerateBundledVersions.targets:295`/`:315` 把 openharmony 置于追加社区 RID 首位；仅美观，最小修复 = 移到 openbsd 之后（本轮 R2b 复核仍未改）。
- **workload pack 无 graph sha256 自动校验**：三份字节已一致并有 diff/json 复核，但未在 pack 脚本加等值断言（audit-3 建议 1 的剩余半句；本轮 R2b 复核仍未改）。
- **`a10b73e` 已推（原「未推」已解决）**：alloc 门禁基线提交已随 `origin/master` 推送；本报告审计 tip 当时为 `686bf89`，当前 `ohos-workload master = c6a4cd95e`（headless abc `4e5491d`、tester-run v6 `8408a90`、模板 README `e995cef`、pin `236d18a9`；tip 清理签名说明中的过期指引）。
- osx-arm64 失败判为 sccache 偶发（仅日志，未复跑）；maui 公共 API 仅类型级对账（成员级未逐条）；R7 注释统计含主观性；设备未验证项见安全/性能报告。
