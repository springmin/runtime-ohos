# 测试方交接：kit #57（官方 rc.2 线重切（RC2-OFFICIAL）+ JIT/interp 件与三卡补齐）+ kit #56 全量（2026-10-14）

> 本页 = kit #57 的判定点与证据入口。kit #57 = **kit #56 全量（功能面零改动）** 按 **官方 rc.2 戳重切**：
> 构建位 `~/.dotnet.rc2-105`（SDK `11.0.100-rc.2.26504.105` + workload `1.0.0-preview.29`，packs 随动 `.105`）、
> 7 hap 全 AOT 重出；另 **JIT/interp 件**（CG2-R2R / FIXRR 卡的构建件）与三卡（+ AOT-STARTUP）补齐。
> 发布：`device-test-kit` release **392356147**（kit 资产已刷新）；bundle = **复用已发布 `1.0.0-preview.29`**
> （`21e2d128…`；sdk-ohos 锚 `49df3e8220` 不变——本刀无新包变化）。
>
> 先读：`2026-10-14-ohos-tester-handoff-kit56.md`（功能面判定点 #56 全部有效）；本页只列 **#57 增量与复跑项**。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
sh tester-run.sh --install --start --capture 30 --probes probes --kit-dir device-test-kit
# #57 主判点 1：RC2-OFFICIAL——装机件已是官方 .105/.29 线（AOT 原生 + BCL 均 .105）；功能面同 #56
# #57 主判点 2：三卡——CG2-R2R（JIT IL vs R2R）/ AOT-STARTUP（首帧时间线）/ FIXRR（interp + R2R=0）
# 承 #56 主判点：TOUCH-PASTE / WEBAUTH-LOOPBACK / SECURE-STORAGE-FAILCLOSED / launcher+INTERNET / clipboard / media / 子窗
# 门禁回归：sh verify-kit.sh → 0 FAIL/0 WARN；套件 814/817 floor 797；导出 164/164
```

## 0b. 预签直装（#34 起加发资产；**已刷新至 #57**）

- `preSigned-haps.tar.gz`（7 hap 按 tester UDID `60CF7B27…` 预签，`hdc install -r` 直装）：**70,242,500 B / `52baf033…`**（asset 640169891）、sidecar **88 B / `2ca8e4f0…`**（asset 640171632）、tree `00252de1…`；逐件原/新 sha 与安装命令见包内 `preSigned-README.md`（dtk release 392356147「预签直装」note 行同值）。

## 1. kit #57 相对 #56 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **RC2-OFFICIAL（官方 rc.2 戳重切）** | 构建位 = `~/.dotnet.rc2-105`（官方 SDK `11.0.100-rc.2.26504.105` + workload `1.0.0-preview.29`：BCL/Aspnet 均 `.105`），P0 门禁 = 安装 pack == repo `.29`（7 sdk + 20 ref/runtime/bcl 文件）+ 红控 rc=1；7 hap 全 AOT 重出（`.105` BCL + `.105` AOT packs `Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64` / `runtime.openharmony-arm64.Microsoft.DotNet.ILCompiler` `11.0.0-rc.2.26504.105`，来自 runtime `.105` release）。功能面零改动 | 装机件行为沿 #56 判定点逐条复核（launcher / TOUCH-PASTE / loopback / SecureStorage 默认关 / media / 子窗）；`runtime-mode.txt=aot`；托管件版本 = 官方 `.105` |
| 1.2 | **JIT/interp 件 + 三卡** | **CG2-R2R**：JIT IL 件 135,688,505 B vs JIT+R2R 件 147,389,459 B（`PublishReadyToRun=true` + `.105` crossgen2 feeds；RTR 签名在案）——复跑 A/B（冷启 AMS→首帧）；**AOT-STARTUP**：发布 AOT kit hap 复跑（attach→surface / 首帧时间线）；**FIXRR**：interp 件（rc2b pack 2,410,595 B / `5974430509…`，宿主 `DOTNET_ReadyToRun=0` 语义）复跑 | CG2-R2R：JIT R2R 冷启 ≤ IL（#48 口径 1031→710 ms）；AOT-STARTUP：#48 优化无回归（attach→surface ≈14 ms 档）；FIXRR：interp 不执行 R2R 原生码（宿主显式关闭；与 runtime 隐式 `InterpMode>=2 → fReadyToRun=false` 同效） |
| 1.3 | **bundle 决策 = 复用/一致化** | 本刀无新包变化 → 不回炉：bundle 保持 `21e2d128…`（46,365,380 B；`workload-1.0.0-preview.29` / `workload-latest` / SDK `.105 -ohos` release 三处同值）；sdk-ohos `versions.env` 锚 `49df3e8220`（`already anchored`，恰好一处）。canonical P3 重打包仅作对照（scratch 工作树缺 AspNet pack 载荷 → 桩件；且 tar mtime 使字节必不同） | `dotnet workload list` = `1.0.0-preview.29/11.0.100-rc.2`；安装器/四锚校验通过（锚未动） |
| 1.4 | **承 #56 全量** | rc.2 官方包对齐（MAUI `26505.5`；无 dnceng feed）+ TOUCH-PASTE（壳级 `PasteButton`；opt-in 标记）+ WEBAUTH-LOOPBACK（`127.0.0.1` 单次监听回跳）+ SECURE-STORAGE-FAILCLOSED（默认关）+ ENG-WAVE + kit #55 全量 | 同 `2026-10-14-ohos-tester-handoff-kit56.md` §2（全部继续有效） |
| 1.5 | **门禁/指纹/7 hap/预签** | 交互套件 **814/817 floor 797**、像素 PASS、宿主导出 **164/164**、abc **637,224（`8503a3c2…`）**/headless 24,324、宿主 **367,520/`8826adde…`**；7 hap = 5 MAUI 全 AOT + Blazor 默认/`-nocsp`；**预签刷新至 #57**；`SHA256SUMS` 18 项 | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**（默认期望 **637224,24324**，裸跑即绿；#56=637224 同值、`--expected-abc 620908`（#55）等旧值 FAIL 属预期）；`[suite] checks=814 total=817 floor=797 assert=True`；`runtime-mode.txt=aot` |

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **RC2-OFFICIAL 装机复核（#57 主判点 1）** | 装机（默认件）→ 沿 #56 主判点 1–4 复核（launcher+INTERNET / TOUCH-PASTE 探针 / loopback / SecureStorage 默认关） | 功能面与 #56 一致；kit 内 `runtime-mode.txt=aot`、托管件为 `.105` 线 | 截图/hilog + `bm` dump 原文 |
| **CG2-R2R（#57 主判点 2a）** | 有源码者：`make-mode-kit.sh --mode jit`（IL）与 `-p:PublishReadyToRun=true`（R2R）各出 StartupProbe 件；装机后冷启 ×3（`aa force-stop` 后 `aa start`），读 `[startup]` 行（main→present）与 hilog AMS→首帧 | R2R < IL（−0.3 s 档）；两路径 0 崩、pid 尾活 | `startup.json` 或 `[startup]` hilog 行 + 冷启表；本刀件与数值见 evidence |
| **AOT-STARTUP（#57 主判点 2b）** | 发布 AOT kit hap：`aa start` 后取 `attach→XComponent→OnSurfaceCreated→首帧` 时间线（hilog `-x`） | attach→surface ≈ 10–20 ms 档、无回归（#48 优化在案；CEF 初始化仍在首帧后） | hilog 时间线表 |
| **FIXRR（#57 主判点 2c）** | 有源码者：`make-mode-kit.sh --mode interp`（rc2b pack）+ StartupProbe；`aa start` 冷启；hilog `interp=3` 与宿主行 | interp 件启动平位（不执行 R2R 原生码；`DOTNET_ReadyToRun=0`）；无退化 | `[startup]` 行 + 宿主 `interp=` 行 |
| **承 #56 判定点** | 同 `2026-10-14-ohos-tester-handoff-kit56.md` §2 | 不变 | 同上各卡 |
| **门禁回归 / 指纹基座** | 有源码测试者跑 `sh verify-kit.sh` 与 `test/maui-platform-verify` | verify-kit **0 FAIL/0 WARN**（默认 637224,24324）；`[suite] checks=814 total=817 floor=797 assert=True`；导出 **164/164**；像素 PASS | 终端输出 |

> **本刀执行时的设备状态（如实）**：发布侧全部完成（P0–P6、预签、manifest、CI 6/6 + sdk install-tests、轮包/证据归档）；
> **三卡的本机设备复跑（CG2-R2R/AOT-STARTUP/FIXRR）与发布件设备冒烟**在本刀执行窗口内**未完成**——`hdc` 服务在运行、
> 但目标设备（HDU/W32 环回 `127.0.0.1:36823`，与 `2026-10-14-ohos-device-round-56.md` 同址）在窗口内 0 targets/无回显
> （多次重试 + `tconn`/server 重启均无效；证据 = `kit57-evidence-20261014.tar.gz` 的 `device/attempts.txt`）。
> 三卡构建件与配方已就绪（见 1.2 与包内 `cards/README.md`）；设备回归后按 §2 勾卡并回填。

## 3. 环境与边界要记（增量）

- 构建位 = `~/.dotnet.rc2-105`（rc.1 回滚线 `~/.dotnet` 与 `.112` 线 `~/.dotnet.rc2-fix` 保持不动）；`.29` bundle 的 `.28` 保留历史。
- AOT packs `.105` 来自 runtime `.105` release 资产（`aot-packs-11.0.0-rc.2` 镜像仍为 `.112` 系——本刀 AOT 件用 runtime release 的 `.105` 包；feed 注入见 `~/.nuget/packages` 与 evidence）。
- canonical P3 在**新鲜 worktree** 重打包会产出 AspNet 桩件（缺 pack 载荷）→ 本刀据此不发布重打包件（复用已发布 `.29`）；对外消费面不受影响。
- 降级/人工卡：同 #56（`2026-10-14-ohos-tester-handoff-kit56.md` §3）；api20 镜像级边界（9568297）等继续有效。

## 4. 证据与指针

- release「## Integrity (kit #57)」（四 release：dtk 392356147 / workload-latest 392077166 / workload-1.0.0-preview.29 412533677 / SDK `.105 -ohos` 412433510）；
- kit 数字：tar **70,428,755 B / `bc0e8c4790f4400b4c0cc8fe4eaf2146e4f470ed055575d0748fe030d3327f95`**、树 `a1d72306ea9e533e8de51e7938a89658cfaf691a664c65a571bf8d269a095e35`、sidecar `9f51ac4891c27470…`（89 B）；pins ow `6b62a49128f3ee5d50bef9a62e425f5dc365991e`（承 `fc66209`）/ maui `1c5ff3cbeb` / runtime `88e84fa8b5c`；
- 证据归档 `kit57-evidence-20261014.tar.gz`（91,951 B / `0539fbe0…`；asset 640183713 区；含本刀全部 log/state/values、三卡构建件 sha 与配方、bundle 决策对照、设备连接尝试记录）；
- 轮包 `tester-round-kit57.tar.gz`（204,544,452 B / `9e7d3e23…`；61 件；asset 640188005，sidecar 640193233；含 kit+预签+解释器 rc2b+AOT v3 rc2+Crossgen2 引用（`.112` 档 + **`.105` 官方 nupkg**）+ 三卡说明 `cards/` + 文档 + device-round）；
- 预签：`preSigned-haps.tar.gz`（70,242,500 / `52baf033…`，asset 640169891；刷新至 #57）。
