# 复测任务单（一页）：kit #42 一轮设备判定（**三路径首帧**：JIT 解锁 / AOT / 解释器 rc2b + FIX-SLICERACE + 承 #41 回归）（2026-10-03）

> 目标：一轮拿全 **#42 主判点 = 三路径首帧**：**JIT**（宿主 `prctl(0x6a6974)` JITFORT 默认开 + 无 ICU 镜像自动
> `InvariantGlobalization` → `canvas presented`）· **AOT**（回归不变）· **解释器**（rc2b pack：
> `ohos-interpreter-pack-rc2b.tar.gz` 2,410,595/`5974430509…` → `canvas presented`）
> + **FIX-SLICERACE**（JIT 8/8 设备轮）＋ L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c
> + **承 #41** 的 MULTI-OVERLAY-FULL / DEVCOMPAT-DEFAULT / INTERP-FIX（8 MB 栈 + 关写屏障 + rc2 pack 线）
> + **承 #40** 的 FIX-JSCALL（计数往返）+ **承 #39** 的 FIX-BACKSIZE/FIX-BWVMount + **承 #38** 的 FIX-DISMISS/FIX-WVP
> + **承 #37** 的 FIX-HOME/FIX-ITOUCH + **承 #36** 的 payload/a11y/像素 + **承 #35** 的 W9/W10
> 与 **承 #34/#33** 的 rc.2 版本自述、W6/W7/W8、Blazor 双 hap A/B，并采 JIT/XWE/AOT/解释器/harmony 与无障碍。
> 执行入口 = `tester-run.sh`（版本/大小/摘要**以包内 `SCRIPT_VERSION` 与 release 资产页为准**；承 **v14**，
> 含 `--blazor-probe` / `--mode-matrix` / `--a11y-probe`）。
> 判定树与细节：`docs/plans/2026-10-03-ohos-tester-handoff-kit42.md`（逐项勾选 + §3 rc.2/AOT + §4 本机直测）、
> `docs/plans/2026-10-03-ohos-jitfort-enable.md`（JIT 解锁根因/设备）、`…interp-null.md`（解释器首帧/rc2b）、
> `…handler-race.md`（FIX-SLICERACE 8/8）、`…sample-fix.md`、`…legacy-toolbar.md`、`…wx-patch2-fallback.md`、
> `…m-web-mirror.md`、`…zorder-nav-device.md`、`…maui-final-audit.md`。
> 本页只给「取件 → 执行 → 回传 → 判定」。**kit #42 发布实测（release「## Integrity（kit #42）」；发布已完成，
> 一切数字以 release 与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准）**：tar **376,256,128 B / `ea4e3b58…`**、
> 树 **`13f3a086…`**、sidecar **`878d05a1…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `9ce72b56…`**
> （#41 = tar 376,036,502 / `bed460ae…` 对照）。**预签未刷新（仍 #41 件，指向 #41 内容）**——#42 如需预签请回传 UDID 代签。
>
> **运行时口径（kit #43 起）**：**默认 AOT**；JIT 需 ACL/豁免（release/生产域 AGC ACL 或厂商豁免）；interp 为实验路径（独立 pack，不随主包）。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #42，2026-10-03） | **376,256,128** | **`ea4e3b58…`**（sidecar `878d05a1…`；树 `13f3a086…`；`SHA256SUMS` 17 项 / 1,517 B / `9ce72b56…`；dtk **392356147** / latest **392077166**；tar/边车 asset **607136666**/**607139045**，latest 同件 **607139215**/**607141763**） | **7 hap** = 5 MAUI（壳 abc **356,468（`dd04dad1…`）**/24,324、hap 内宿主 **297,888（`08abe185…`）**、UND 240；15 `.so` / 258 zip）+ **2 个 Blazor 对照 hap**（bundle `com.example.opendotnet`，无 INTERNET）+ `verify-kit.sh`（69,717 / `0995a406…`）+ 文档 |
| `preSigned-haps.tar.gz`（**预签直装**；#34 起加发；**本批未刷新**） | **376,684,381**（仍为 **kit #41 件**；asset **606183753**；sidecar 88 B / `4198a3ec…`，asset **606192909**；指向 #41 内容） | **`2075650a…`** | 7 hap = **kit #41 原名件**，按 tester UDID `60CF7B27…F8A19` 预签：`sha256sum -c SHA256SUMS` → `hdc install -r` **直装**；非本 UDID 设备仍 `9568344`；**#42 内容请用 kit tar（或回传 UDID 代签 #42 预签件）** |
| AOT 复测取件（`aot-haps*`；**rc.2 pack 已重出 `-struct1`：结构修复 + shim**） | **18,185,012**（`aot-haps-v3-rc2.tar.gz`；本批未动） | **`3d24f716…`** | AOT hap（含 UIPage 出画修复）；rc.2 设备/本机构建用 **`-struct1`**（`…rc.2.26451.112-struct1.nupkg` 28,905,116 / `09345f95…`，asset 607541145；sdk fetch 现锚、`versions.env` sha `09345f95…`）；`-r2`（28,904,657 / `542058cf…`，asset 601289590）与原包（`46d221f2…`）仅历史、不再钉锚；装前重签 |
| **解释器 pack（本轮更新）** `ohos-interpreter-pack-rc2b.tar.gz` | **2,410,595**（asset **606999003**；README **606999004**；sidecar **606999001**） | **`5974430509…`** | **INTERP-NULL 修复 + WX-PATCH2**（`libcoreclr` `4b30a4c1…`/`e150558a…` + `libclrinterpreter` `11fc5052…`/`3e4b4d10…`）；配 #42 宿主（JITFORT + 8 MB 栈）使用；**rc2 旧件（605924427）/rc.1 旧件（2,419,988 / `a10699b3…`）保留作对照** |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`） |
| `tester-run.sh`（随包） | 以包内为准（承 v14 = 140,197 / `a174fcd0…`） | 以包内为准 | 执行器；`--blazor-probe`、`--mode-matrix`、`--a11y-probe` 承 #33 |

包内 7 hap（kit #42 发布实测，`SHA256SUMS` 17 项 / 1,517 B / `9ce72b56…`）：`hello-maui-app.hap` **134,191,673 / `f94cbc0f…`**、`…-unsigned` **131,635,004 / `5a0a908b…`**、`…-permissions` **134,191,645 / `2b91a1a4…`**、`…-api20` **134,191,733 / `2180bc83…`**、`…-api20-permissions` **134,191,691 / `acc3f684…`**、Blazor 默认 **27,216,958 / `2b64bc5a…`**（own abc 21,200 B、site 213 files、未签名）、`-nocsp` **27,216,659 / `ec224092…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`；own abc 21,016 B）。

**预签直装捷径（可选）**：`sha256sum -c SHA256SUMS` 后 `hdc install -r` 直装，**§2 的「先重签」可跳过**（同 bundle
换件仍先卸载）；**注意：本波未刷新预签件——它仍是 kit #41 内容**。完整一轮 / #42 内容请用 `device-test-kit.tar.gz`。

## 2. 执行顺序（每步「期望 → 回传」）

0. **三路径首帧（#42 主判点）**：①**JIT**：装默认 kit 主 hap（DeviceCompat）→ 期望 status/hilog `OHOS_DOTNET jitfort: rc=0 errno=0 state=off` + 探针 `1=OK 2=OK` + `OHOS_DOTNET globalization: invariant=1 icu=0 source=…`（本镜像无 ICU 自动 invariant）+ **`canvas presented`（4–8 次）+ UI 出画截图**（逃生口 `DOTNET_OHOS_NO_JITFORT=1` 可回退）；②**AOT**：装 AOT 资产（重签）→ `aot=1` + `canvas presented`（回归不变）；③**解释器**：用 **rc2b pack** 对 **rc.2 kit hap**（重签）换入两库 + `interp.txt=3` → 期望 **`canvas presented`（2090x1324）**、无 `cppcrash`、`SIGSEGV(NULL)` 不再出现；④**FIX-SLICERACE**：冷启/force-stop/再启循环（JIT）→ 期望 **race=0 pvnull=0 conc=0**（8 轮全过）+ 首帧；⑤套件自报行 **`[suite] checks=578 total=580 floor=560 assert=True`** → 回传截图 + hilog + `[suite]` 行。
1. **校验 kit**：包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap；abc 期望 **356,468/24,324**、**15 `.so` / 258 zip 条目**、host UND 240，脚本哈希 `0995a406…` 以包内为准）→ 回传终端输出。
2. **rc.2 版本自述**：读包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary → 期望 SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；无 rc.1 混装告警 → 回传自述原文 + summary。
3. **承 #41**：MULTI-OVERLAY-FULL（双 Hybrid 各自 invoke/消息 → 第三控件 LRU 抢占 → Activate 恢复；重叠页 z-order 已由 ZORDER-NAV 取到 97.2% 翻转证据）；DEVCOMPAT-DEFAULT（enforcing 开箱可装）；INTERP-FIX（8 MB 栈 + 关写屏障）→ 回传截图 + hilog。
4. **承 #40**：FIX-JSCALL = razor 页点 "Blazor click" 两次 → **count 0→1→2**（SAMPLE-FIX 后 `blzProbe` 报 `dotnet-ref ok`；demo `#app` 恢复挂载）→ 回传截图 r0/r1/r2 + hilog。
5. **承 #39**：FIX-BACKSIZE = 抽屉开 → 系统 Back 关抽屉（仍 `#FOREGROUND`）；BlazorWebView 在控件 frame 内出画；FIX-BWVMount = `.razor` 挂载 → 回传截图 + hilog。
6. **承 #38**：FIX-DISMISS = 抽屉开 → **面板外 click 关闭**（重开/再关）；FIX-WVP = Hybrid 出画 + 页↔宿主 bridge → 回传截图 + hilog。
7. **承 #37**：FIX-HOME = Home tab 首屏整页出画 + 切走/切回；FIX-ITOUCH = 注入点击命中页内元素（偏心点 0 变化）→ 回传截图 + hilog。
8. **承 #36**：payload 原地直载 + `--a11y-probe`（`status=1`、nodeCount 正整数；wasm 5 / 主包 24）→ 回传 hilog + `a11y/` 两文件。
9. **B2：MAUI WebView 内嵌 Blazor WASM（承 #35 主判点）**：装含 WebView/WASM 入口的包内演示 hap（或按 release/包内说明构建），AOT 路径启动 → 打开嵌入式 Blazor 页 → 期望 **`BLZ_BOOT` + `BLZ_RENDERED` 同 pid 双标记齐**（无 `BLZ_ERROR`）、首屏渲染、`/counter` 类交互 +1 → 回传 hilog + 首屏/交互截图。
10. **W9B：T14 收尾 + T21 字体缩放**；**W9C：T8 不等高 TableView**；**W9D：T20 媒体 + T19 深链**；**W10：AOT 入口可观测**：同 #35 各步（无 MediaKit 属预期不判失败；热 `delivered=1`；`dotnet-status.txt` 托管行）→ 逐条截图/回传。
11. **LEGACY Toolbar（#42 新增）**：NavigationPage/Shell 标题栏工具栏：图标（File/Font 字形）+ 文字 + `Order/Priority` 停靠 + 禁用暗显 + Secondary 溢出下拉（内容前 hit-test，禁用不激活）→ 截图 + 激活结果。
12. **L6（#42 新增）**：截图格式 JPEG（默认/切换）+ 标题心跳（`webZOrder` 无关）→ 截图文件按 JPEG 落盘（`ohos_host_screenshot_format` 导出在 151/151 内）。
13. **P2c `skills[].uris`（#42 本机部分）**：设 `OpenHarmonyAppLinkHosts` 构建 → 包内 `module.json` `module.abilities[0].skills[].uris` 出现 browsable/viewData + https uri + `domainVerify`（未设时字节不变；非法 host 拒绝）→ 回传 `module.json` 摘录（**真机 https 投递/AGC 登记仍为外部项**）。
14. **承 #34：W6/W7/W8**：W6 = T14/T12/N1/FIX-SHELL；W7/W8 = T15/T16/N4（`--a11y-probe`）/T18/N5/N6 → 逐条截图/终端输出（套件自报行 **`[suite] checks=578 total=580 floor=560 assert=True`**）。
15. **承 #33：Blazor A/B**：装默认件 → `--blazor-probe` → 记录 `BLZ_BOOT`/`BLZ_RENDERED`（pid+nonce）与人工首屏/`/counter` +1/截图；**卸载后**装 `-nocsp` 件 → 同命令 → 按 #33 判读表落结论。
16. **承 #33：MAUI 主体（TabbedPage/W5）**：双页签出画 + 切页；T13/N3/T21/T22。**JIT 首帧已解锁（本版）**；若仍崩再按 AOT 回退流程。
17. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./<aot-asset>.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60` → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全 → 回传 `mode-matrix/` 全目录 + 四个 `tester-report-*.tar.gz`。
18. **无障碍（含 N4）**：加 `--a11y-probe` → `a11y/selfcheck.txt`（status=1 + 正整数节点数）+ `a11y/hilog-a11y.txt` → 回传 `a11y/` 两文件 + `summary a11y_*` + 录屏。
19. **WebView 六项 + B1 razor（承 #32）**；**harmony 变体（AGC 就绪时）**：按卡逐条 / 同指纹重签 → 回传截图 + hilog + Map/LiveView/TTS/HUKS 证据。

## 3. 判定表（逐 Run 填）

| 态/项 | 判据 | 结论 |
|---|---|---|
| **JIT 首帧（#42 主判点 1）** | `OHOS_DOTNET jitfort: rc=0 errno=0 state=off` + 探针 `1=OK 2=OK` + `canvas presented`（4–8）+ UI 出画；无 ICU 镜像 `globalization: invariant=1` | #42 落地 |
| **AOT 首帧（#42 主判点 2）** | `aot=1` + `canvas presented`（回归不变） | #42 回归成立 |
| **解释器首帧（#42 主判点 3）** | rc2b pack + rc.2 kit hap → `canvas presented`（2090x1324）；无 `cppcrash`、无 `SIGSEGV(NULL)`；`summary interp_mode=3(file)` | #42 落地 |
| **FIX-SLICERACE（#42）** | JIT 冷启/重启循环 8 轮：`race=0 pvnull=0 conc=0 unhandled=0` + 首帧 | #42 落地 |
| **L6（#42）** | 截图格式 JPEG 落盘；标题心跳正常 | #42 落地 |
| **LEGACY Toolbar（#42）** | 图标/文字/Order/Priority/禁用/溢出下拉符合契约；禁用不激活 | #42 落地 |
| **SAMPLE-FIX（#42）** | `blzProbe` = `dotnet-ref ok`；demo `#app` 挂载（AttachPage/AttachToDocument/计数 0→1→2）；`dotnet.zip` 258 项 | #42 落地 |
| **WX-PATCH2（#42）** | 双映射预检 + 写屏障 Commit 检查；解释器 rc2b 内含；无 `ACCERR` | #42 落地 |
| **P2c `skills[].uris`（#42）** | 构建产物 `module.json` 含 browsable/viewData + https uri + domainVerify；负例拒绝 | #42 落地（真机投递/AGC 外部） |
| **套件基座（#42）** | `[suite] checks=578 total=580 floor=560 assert=True`；导出 151/151 | #42 基座 |
| **MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX（承 #41）** | 双槽 LRU/per-slot invoke/z-order（重叠 97.2%）；enforcing 开箱可装；8 MB 栈 + 关写屏障 | 承 #41 保持 |
| **FIX-JSCALL（承 #40）** | razor 点两次 → count 0→1→2；`missing native code`=0 | 承 #40 保持 |
| **FIX-BACKSIZE / FIX-BWVMount（承 #39）** | Back 关抽屉；`.razor` 挂载 | 承 #39 保持 |
| **FIX-DISMISS / FIX-WVP / FIX-HOME / FIX-ITOUCH（承 #38/#37）** | 外点关；Hybrid 出画+bridge；Home 整页出画；注入命中 | 承 #37/#38 保持 |
| **payload / 像素 / a11y / AOT `-r2`（承 #36）** | `payload-in-libs: running from …`；无 `Known`；`status=1`+nodeCount；`-r2` 构建成立 | 承 #36 保持 |
| **B2 / W9 / W10（承 #35）** | 双标记齐；T14/T21/T8/T20/T19；AOT 入口行 | 承 #35 落地 |
| rc.2 基线 + W6/W7/W8（承 #34） | 版本自述；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6 | rc.2 线成立 |
| Blazor A/B + 主体（承 #33） | 默认/nocsp 双标记；TabbedPage/W5；套件 `578 total=580 floor=560` | #33 保持 |
| JIT / XWE / AOT / 解释器 / harmony / runtime_mode | 各态判据同前；JIT 首帧已解锁（#42） | 各判定成立 |
| WebView / B1 razor（承 #32） | 9 项卡 + B1 两标记 + JS 往返 | 按 #32 判据 |

> 失败 Run 保留报告 tar；无入口项登记「未测（本包无入口/无 hdc）」，不判失败。

## 4. 注意

- 包内 hap 为自签：**9568257 / 9568344 属预期**，先重签（需华为调试证书 + Profile 绑 UDID）；**预签件本波未刷新（仍 #41 内容）**——#42 内容用 kit tar，或回传 UDID 代签；**Blazor 双变体同名（`com.example.opendotnet`），装前卸载**；两变体均无 INTERNET（重签保持）。
- **JIT 解锁口径**：宿主每条启动路径（hostfxr 前）调 `prctl(0x6a6974)`（默认开；失败不致命、保持 xwe 路径并记录）；`runtime-mode=aot` 跳过（`jitfort: skipped runtime-mode=aot`）。无 ICU 镜像自动 `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`（`DOTNET_OHOS_ICU=0|1` 可覆盖）；**应用侧如自行预置 Invariant 也兼容**。
- **解释器口径**：用 **rc2b pack** + **rc.2 kit hap**（重签）；勿用 rc.1 托管 CoreLib 的旧 `--no-restore` 测试件（QCall ABI 错配会 `SIGSEGV(NULL)@coreclr_initialize`，属测试件问题、非 pack 缺陷）。`interp.txt=1|2` 混合模式保留默认（不注入 barrier skip）。
- **AOT pack 结构修复**：`FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分（静态 `.a` 保留 dlopen shim、共享 `.so` 仍静态链 OpenSSL；sdk 构建在布局与 nupkg 两处校验）——**当前资产 = `-struct1`**（asset 607541145；`-r2`/原包仅历史），后续 runtime pack 无需再重打。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递（`skills[].uris` 本机产物已可验）；②镜像扩展分支 `m-web-mirror d47f1fcb3b` 尚未并入 `feature/openharmony`；③z-order 重叠真机截图已取（97.2%）；④rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过（未定位）；⑤stock JIT 长跑/后台唤醒未覆盖（本轮覆盖为 8/8 短轮 + 首帧）。相关项登记「未测（在途）」不判失败。
- **rc.2 相关**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；rc.1 回滚线保留；应用侧构建请同步 rc.2 线（`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5）。
- **AOT 包（承 #36）**：rc.2 NativeAOT OpenHarmony pack 的 OpenSSL shim × 结构缺陷已由结构修复后重出的 **`-struct1`**（28,905,116 / `09345f95…`，asset **607541145**）收口——**撤销 #35 的 rc.1 钉**；`-r2`（601289590）/原包（`46d221f2…`）仅历史、不再钉锚。若环境缓存过坏包，删 `~/.nuget/packages/microsoft.netcore.app.runtime.nativeaot.openharmony-arm64/11.0.0-rc.2.26451.112` 后再 publish。AOT hap 只有 3 个 `.so`，勿用 JIT 期望值核对。
- **hilog 缓冲（探针误报防护）**：512K 环在噪声大时只保留 ≈4–5 s（`--blazor-probe` 曾丢 `BLZ_BOOT` 报 `boot=no`）；临时 `hilog -G 16M -t app,core` 重跑（**跑完还原 512K**）。另注意**状态文件伪影**：`dotnet-status.txt`/壳轮询可能输出上一轮残留行（INTERP-FRAME 记录过 411 行同刻伪影）——**以本轮时序内状态为准**。
- **本机直测（交付方）**：设备已可测（hdc 无线 `127.0.0.1:35111` + SDK 自签 + AOT/JIT/解释器三路径）；JIT 主包在 enforcing 镜像**已可开箱安装**（DEVCOMPAT-DEFAULT，承 #41）。
- 所有数字 = **kit #42 发布实测（以 release「## Integrity（kit #42）」与随包校验为准）**：tar **376,256,128 / `ea4e3b58…`**、树 `13f3a086…`、sidecar `878d05a1…`、`SHA256SUMS` 17 项 / 1,517 B / `9ce72b56…`；#41 = tar 376,036,502 / `bed460ae…`、#40 = tar 375,836,470 / `31ab8732…`；tester-run v14 = 140,197 / `a174fcd0…` 仅作对照；bundle = `workload-1.0.0-preview.28` **73,047,352 / `570c0821…`**（三处同步；dist sums `b72a0e81…`；sdkrc2 合并 sums 1,960 B / `65bd6947…`；sdk 锚 **`35101fe1f5`**；其后 **`7d62af56ba`** 并入 `-struct1` AOT 换锚）；dtk **392356147** / latest **392077166**（asset **607136666**/**607139045**；预签仍 **606183753**/**606192909**；interp pack rc2b asset **606999003**）；CI **5/5** @ `740980d`（interaction `37096467502` / pixel `37096467496` / host-export `37096467506` / ridgraph `37096467507` / markdownlint `37096467538`）；sdk `ohos-install-tests` @ `35101fe1f5` run `37096319182`）。
- 细判（TTS/HUKS/自绘深度/权限/Share-Scan）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2 与 `…kit29/kit28/kit27/kit26/kit25`；无障碍逐项：`docs/plans/2026-09-27-ohos-accessibility-device-verification.md`（含 N4）；#42 细节：`2026-10-03-ohos-jitfort-enable.md`、`…interp-null.md`、`…handler-race.md`、`…sample-fix.md`、`…legacy-toolbar.md`、`…wx-patch2-fallback.md`、`…m-web-mirror.md`、`…zorder-nav-device.md` 与 `2026-10-03-ohos-tester-handoff-kit42.md`。
