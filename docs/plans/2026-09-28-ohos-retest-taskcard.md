# 复测任务单（一页）：kit #44 一轮设备判定（**动态槽 3 控件并发 + 释放/重建** + **AOT 默认** + 承 #43 FRAMEPACING + 承 #42 三路径回归）（2026-10-04）

> 目标：一轮拿全 **#44 主判点 = 动态槽（SLOTS-DYNAMIC）**：①**3 控件并发出画/交互**（MAX/HOT 默认 4/2、按需创建）；
> ②**释放即拆/重建**（第 3 槽 destroy→ensure，热对 [0,1] 不受影响）；③**AOT 默认**（5 MAUI hap 全 NativeAOT、
> `runtime-mode.txt=aot`、无 JIT 运行时；首帧/交互回归；JIT 走 `--runtime-mode jit` 自建，release 域需 ACL/豁免）
> + **承 #43** 的 FRAMEPACING（真实 60.00 fps；17.7 fps 系壳状态轮询伪影）
> + **承 #42** 的 JIT 解锁（JITFORT；保形态）/解释器 rc2b/FIX-SLICERACE
> + **承 #41** 的 MULTI-OVERLAY-FULL / DEVCOMPAT-DEFAULT / INTERP-FIX（8 MB 栈 + 关写屏障 + rc2 pack 线）
> + **承 #40–#35** 的 FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10
> 与 **承 #34/#33** 的 rc.2 版本自述、W6/W7/W8、Blazor 双 hap A/B，并采 JIT/XWE/AOT/解释器/harmony 与无障碍。
> 执行入口 = `tester-run.sh`（版本/大小/摘要**以包内 `SCRIPT_VERSION` 与 release 资产页为准**；承 **v14**，
> 含 `--blazor-probe` / `--mode-matrix` / `--a11y-probe`）。
> 判定树与细节：`docs/plans/2026-10-04-ohos-tester-handoff-kit44.md`（逐项勾选 + §3 rc.2/AOT + §4 本机直测）、
> `docs/plans/2026-10-02-ohos-multi-overlay.md` §DYNAMIC（动态槽设计/设备证据）、`…framepacing.md`（60 fps 归因）、
> `…jitfort-enable.md`、`…interp-null.md`、`…handler-race.md`、`…sample-fix.md`、`…legacy-toolbar.md`、
> `…wx-patch2-fallback.md`、`…m-web-mirror.md`、`…zorder-nav-device.md`、`…maui-final-audit.md`。
> 本页只给「取件 → 执行 → 回传 → 判定」。**kit #44 发布实测（release「## Integrity（kit #44）」；发布已完成，
> 一切数字以 release 与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准）**：tar **67,680,863 B / `b777d8d8…`**、
> 树 **`db2604d5…`**、sidecar **`85d62a6e…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `41c1f3c3…`**
> （#43 = tar 67,638,015 / `57c7bf44…`、#42 = tar 376,256,128 / `ea4e3b58…` 对照）。
> **预签已刷新至 #44**（7 hap；67,627,789 / `75a40110…`，asset 608782132）；非 tester UDID 设备请回传 UDID 代签。
>
> **运行时口径（kit #43 起）**：**默认 AOT**；JIT 需 ACL/豁免（release/生产域 AGC ACL 或厂商豁免；debug/内测签名域免；亦可用 `--runtime-mode jit` 自建）；interp 为实验路径（独立 pack，不随主包）。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #44，2026-10-04） | **67,680,863** | **`b777d8d8…`**（sidecar `85d62a6e…`；树 `db2604d5…`；`SHA256SUMS` 18 项 / 1,600 B / `41c1f3c3…`；dtk **392356147** / latest **392077166**；tar/边车 asset **608775822**/**608776466**，latest 同件 **608776640**/**608777124**） | **7 hap**（5 MAUI 全 AOT：`runtime-mode.txt=aot`、3 `.so`（app.so 19,208,976 + host 297,888 + `libc++_shared.so` 1,267,392）、无 libcoreclr/libhostfxr/libclrjit；abc **368,812（`1076a700…`）**/24,324、宿主 **297,888（`7b1694d9…`）**、导出 **151**）+ **2 个 Blazor 对照 hap**（bundle `com.example.opendotnet`，无 INTERNET）+ `verify-kit.sh`（76,707 / `b205ae64…`）+ 文档 + `runtime-mode.txt=aot` |
| `preSigned-haps.tar.gz`（**预签直装**；#34 起加发；**本波已刷新至 #44**） | **67,627,789**（asset **608782132**；sidecar 88 B / `b880a68f…`，asset **608782732**；树 `03abdce3…`） | **`75a40110…`** | 7 hap = **kit #44 原名件**，按 tester UDID `60CF7B27…` 预签：`sha256sum -c SHA256SUMS` → `hdc install -r` **直装**；非本 UDID 设备仍 `9568344` |
| AOT 复测取件（`aot-haps*`；rc.2 pack 已重出 `-struct1`：结构修复 + shim） | **18,185,012**（`aot-haps-v3-rc2.tar.gz`；本批未动；dtk 599996905） | **`3d24f716…`** | AOT hap（含 UIPage 出画修复）；rc.2 设备/本机构建用 **`-struct1`**（`…rc.2.26451.112-struct1.nupkg` 28,905,116 / `09345f95…`，asset 607541145；sdk fetch 现锚、`versions.env` sha `09345f95…`）；`-r2`（28,904,657 / `542058cf…`，asset 601289590）与原包（`46d221f2…`）仅历史、不再钉锚；装前重签 |
| **解释器 pack** `ohos-interpreter-pack-rc2b.tar.gz` | **2,410,595**（asset **606999003**；README **606999004**；sidecar **606999001**） | **`5974430509…`** | **INTERP-NULL 修复 + WX-PATCH2**（`libcoreclr` `4b30a4c1…`/`e150558a…` + `libclrinterpreter` `11fc5052…`/`3e4b4d10…`）；配 #42+ 宿主（JITFORT + 8 MB 栈）使用；rc2 旧件（605924427）/rc.1 旧件（2,419,988 / `a10699b3…`）保留作对照 |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`） |
| `tester-run.sh`（随包） | 以包内为准（承 v14 = 140,197 / `a174fcd0…`） | 以包内为准 | 执行器；`--blazor-probe`、`--mode-matrix`、`--a11y-probe` 承 #33 |

包内 7 hap（kit #44 发布实测，`SHA256SUMS` 18 项 / 1,600 B / `41c1f3c3…`）：`hello-maui-app.hap` **22,325,065 / `bbc2cd7c…`**（AOT）、`…-unsigned` **22,022,815 / `825e5ae9…`**、`…-permissions` **22,325,078 / `f5cf7271…`**、`…-api20` **22,325,069 / `adc42995…`**、`…-api20-permissions` **22,325,068 / `17f272b3…`**、Blazor 默认 **27,216,958 / `ea920cf6…`**（own abc 21,200 B，未签名）、`-nocsp` **27,216,659 / `47b1e79d…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`；own abc 21,016 B）。

**预签直装捷径（可选）**：`sha256sum -c SHA256SUMS` 后 `hdc install -r` 直装，**§2 的「先重签」可跳过**（同 bundle
换件仍先卸载）；预签件已刷新至 #44，可直接用于本轮。完整一轮 / 源码复测请用 `device-test-kit.tar.gz`。

## 2. 执行顺序（每步「期望 → 回传」）

0. **动态槽（#44 主判点）**：①装默认 kit 主 hap（AOT，免 ACL）→ 加满 **3 个 Web 控件**：期望**三控件并发出画/可交互**（A、B、C 各自 invoke/raw 回显 label `A/B/C raw`）；hilog `web cmd: slot`→`web slot create: 2`→defer hybrid/frame→`hybrid assets slot=2`→`web page (slot 2)`，容量 `web capacity: 4`；②移除第 3 控件：期望 C 区消失、label `removed (slot destroy)`（原文可能因日志轮转缺失，以截图为准）；③再加回：slot 2 重建后 C 仍可交互（`sent raw C-raw-ping (stock)`）；④N=2 对照可参考交付方 `slots-dyn/` 既有证据。→ 回传 3 控件截图 + 移除/重建前后截图 + hilog。
1. **AOT 默认（#44 主判点）**：默认包冷启 → 期望 kit 根/逐 hap `runtime-mode.txt=aot`、无 libcoreclr/libclrjit、**首帧 + 交互回归**（`aot=1`、`canvas presented`）→ 回传截图 + hilog + `verify-kit` 输出。
2. **校验 kit**：包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap；5 MAUI hap 期望 `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；abc 期望 **368,812/24,324**，脚本哈希 `b205ae64…` 以包内为准）→ 回传终端输出。
3. **rc.2 版本自述**：读包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary → 期望 SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；无 rc.1 混装告警 → 回传自述原文 + summary。
4. **承 #43：FRAMEPACING**：出画稳定后统计呈现节奏 → 期望真实 **60.00 fps**（旧 17.7 系壳状态轮询伪影）；动画/滚动主观流畅 → 回传帧统计（如可得）+ 录屏/截图。
5. **承 #42**：①JIT（自建 `--runtime-mode jit` 包或 ACL 域）：`jitfort rc=0` + 探针 `1=OK 2=OK` + 首帧；②解释器：rc2b pack + rc.2 kit hap + `interp.txt=3` → `canvas presented`、无 `SIGSEGV(NULL)`；③FIX-SLICERACE：JIT 8 轮 `race=0 pvnull=0 conc=0 unhandled=0`；④L6/SAMPLE-FIX/WX-PATCH2/P2c 同 #42 判读 → 回传截图 + hilog。
6. **承 #41**：MULTI-OVERLAY-FULL（双 Hybrid 各自 invoke/消息；3 控件场景已覆盖；旧壳 >2 按 LRU 抢占）；DEVCOMPAT-DEFAULT（enforcing 开箱可装）；INTERP-FIX（8 MB 栈 + 关写屏障）→ 回传截图 + hilog。
7. **承 #40**：FIX-JSCALL = razor 页点 "Blazor click" 两次 → **count 0→1→2**（SAMPLE-FIX 后 `blzProbe` 报 `dotnet-ref ok`；demo `#app` 恢复挂载）→ 回传截图 r0/r1/r2 + hilog。
8. **承 #39/#38/#37**：FIX-BACKSIZE = 抽屉开 → 系统 Back 关抽屉（仍 `#FOREGROUND`）；FIX-BWVMount = `.razor` 挂载；FIX-DISMISS = 抽屉外点关闭；FIX-WVP = Hybrid 出画 + bridge；FIX-HOME = Home tab 整页出画；FIX-ITOUCH = 注入点击命中（偏心点 0 变化）→ 回传截图 + hilog。
9. **承 #36**：payload 原地直载 + `--a11y-probe`（`status=1`、nodeCount 正整数；wasm 5 / 主包 24）→ 回传 hilog + `a11y/` 两文件。
10. **B2：MAUI WebView 内嵌 Blazor WASM（承 #35 主判点）**：装含 WebView/WASM 入口的包内演示 hap，AOT 路径启动 → 打开嵌入式 Blazor 页 → 期望 **`BLZ_BOOT` + `BLZ_RENDERED` 同 pid 双标记齐**（无 `BLZ_ERROR`）、首屏渲染、`/counter` 类交互 +1 → 回传 hilog + 首屏/交互截图。
11. **W9B/W9C/W9D/W10（承 #35）**：T14/T21/T8/T20/T19/AOT 入口可观测 → 逐条截图/回传（无 MediaKit 属预期不判失败；热 `delivered=1`；`dotnet-status.txt` 托管行）。
12. **承 #34：W6/W7/W8**：W6 = T14/T12/N1/FIX-SHELL；W7/W8 = T15/T16/N4（`--a11y-probe`）/T18/N5/N6 → 逐条截图/终端输出（套件自报行 **`[suite] checks=584 total=586 floor=566 assert=True`**）。
13. **承 #33：Blazor A/B**：装默认件 → `--blazor-probe` → 记录 `BLZ_BOOT`/`BLZ_RENDERED`（pid+nonce）与人工首屏/`/counter` +1/截图；**卸载后**装 `-nocsp` 件 → 同命令 → 按 #33 判读表落结论。
14. **承 #33：MAUI 主体（TabbedPage/W5）**：双页签出画 + 切页；T13/N3/T21/T22。AOT 为默认路径。
15. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60` → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全 → 回传 `mode-matrix/` 全目录 + 四个 `tester-report-*.tar.gz`。
16. **无障碍（含 N4）**：加 `--a11y-probe` → `a11y/selfcheck.txt`（status=1 + 正整数节点数）+ `a11y/hilog-a11y.txt` → 回传 `a11y/` 两文件 + `summary a11y_*` + 录屏。
17. **WebView 六项 + B1 razor（承 #32）**；**harmony 变体（AGC 就绪时）**：按卡逐条 / 同指纹重签 → 回传截图 + hilog + Map/LiveView/TTS/HUKS 证据。

## 3. 判定表（逐 Run 填）

| 态/项 | 判据 | 结论 |
|---|---|---|
| **动态槽 3 控件并发（#44 主判点 1）** | 3 控件各自出画 + 交互回显（A/B/C）；`web slot create: 2` / `web capacity: 4` | #44 落地 |
| **释放即拆/重建（#44 主判点 2）** | 第 3 槽移除后 C 区消失（`removed (slot destroy)`）；重建后仍可交互 | #44 落地 |
| **AOT 默认（#44 主判点 3）** | `runtime-mode.txt=aot` + 3 `.so`/无 libcoreclr/libclrjit + 首帧/交互回归 | #44 落地 |
| **FRAMEPACING（承 #43）** | 真实呈现 60.00 fps（17.7 = 壳状态轮询伪影） | 承 #43 保持 |
| **SLOTS 门禁（#44）** | `[suite] checks=584 total=586 floor=566 assert=True`；导出 151/151 | #44 基座 |
| **JIT 解锁（承 #42）** | 自建 jit 或 ACL 域：`jitfort rc=0` + 探针 `1=OK 2=OK` + 首帧 | 承 #42 保持 |
| **解释器首帧（承 #42）** | rc2b pack + rc.2 kit hap → `canvas presented`；无 `cppcrash`、无 `SIGSEGV(NULL)`；`summary interp_mode=3(file)` | 承 #42 保持 |
| **FIX-SLICERACE（承 #42）** | JIT 冷启/重启循环 8 轮：`race=0 pvnull=0 conc=0 unhandled=0` + 首帧 | 承 #42 保持 |
| **L6 / LEGACY / SAMPLE-FIX / WX-PATCH2 / P2c（承 #42）** | JPEG 落盘/标题心跳；Toolbar 契约；`blzProbe`=`dotnet-ref ok`、`#app`、计数 0→1→2；无 `ACCERR`；`module.json` skills | 承 #42 保持 |
| **MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX（承 #41）** | 双 Hybrid/per-slot invoke/z-order；enforcing 开箱可装；8 MB 栈 + 关写屏障 | 承 #41 保持 |
| **FIX-JSCALL（承 #40）** | razor 点两次 → count 0→1→2；`missing native code`=0 | 承 #40 保持 |
| **FIX-BACKSIZE / FIX-BWVMount（承 #39）** | Back 关抽屉；`.razor` 挂载 | 承 #39 保持 |
| **FIX-DISMISS / FIX-WVP / FIX-HOME / FIX-ITOUCH（承 #38/#37）** | 外点关；Hybrid 出画+bridge；Home 整页出画；注入命中 | 承 #37/#38 保持 |
| **payload / 像素 / a11y / AOT `-struct1`（承 #36）** | `payload-in-libs: running from …`；无 `Known`；`status=1`+nodeCount；`-struct1` 构建成立（`-r2` 仅历史） | 承 #36 保持 |
| **B2 / W9 / W10（承 #35）** | 双标记齐；T14/T21/T8/T20/T19；AOT 入口行 | 承 #35 落地 |
| **rc.2 基线 + W6/W7/W8（承 #34）** | 版本自述；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6 | rc.2 线成立 |
| **Blazor A/B + 主体（承 #33）** | 默认/nocsp 双标记；TabbedPage/W5；套件 `584 total=586 floor=566` | #33 保持 |
| **JIT / XWE / AOT / 解释器 / harmony / runtime_mode** | 各态判据同前；AOT 为默认、JIT 为形态保留 | 各判定成立 |
| **WebView / B1 razor（承 #32）** | 9 项卡 + B1 两标记 + JS 往返 | 按 #32 判据 |

> 失败 Run 保留报告 tar；无入口项登记「未测（本包无入口/无 hdc）」，不判失败。

## 4. 注意

- 包内 hap 为自签：**9568257 / 9568344 属预期**，先重签（需华为调试证书 + Profile 绑 UDID）；**预签件已刷新至 #44**——可直接 `hdc install -r` 直装（非 tester UDID 仍 `9568344`，请回传 UDID 代签）；**Blazor 双变体同名（`com.example.opendotnet`），装前卸载**；两变体均无 INTERNET（重签保持）。
- **动态槽口径**：MAX/HOT 默认 4/2（env 不可按应用注入；clamp 2..8 / 2..max）；热对 [0,1] 常驻、空闲 >2 不养 ArkWeb 引擎/文档（重建只付一次组件+加载）；容量下调按 suspend 抢占超容量 claim（旧 2 槽壳安全降级）；`web slot destroy` 原文可能秒级轮转丢失——以截图 + 重建交互闭环为准，静置可复核；第 4 槽未真机点验（headless 限值 drill 覆盖 2/4 夹取）。
- **AOT 默认口径（#43 起）**：5 MAUI hap 全 NativeAOT（`runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libhostfxr/libclrjit）；JIT 保形态（`--runtime-mode jit` 自建；debug 域 JITFORT 默认；release 域需 AGC ACL `ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`（2in1/平板）或厂商豁免——手机只发 AOT）；interp 实验（独立 pack）。
- **解释器口径**：用 **rc2b pack** + **rc.2 kit hap**（重签）；勿用 rc.1 托管 CoreLib 的旧测试件（QCall ABI 错配会 `SIGSEGV(NULL)@coreclr_initialize`，属测试件问题、非 pack 缺陷）。`interp.txt=1|2` 混合模式保留默认（不注入 barrier skip）。
- **AOT pack 结构修复**：`FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分（静态 `.a` 保留 dlopen shim、共享 `.so` 仍静态链 OpenSSL；sdk 构建在布局与 nupkg 两处校验）——**当前资产 = `-struct1`**（asset 607541145；`-r2`/原包仅历史），后续 runtime pack 无需再重打。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递（`skills[].uris` 本机产物已可验）；②镜像扩展分支 `m-web-mirror d47f1fcb3b` 尚未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过（未定位）；④stock JIT 长跑/后台唤醒未覆盖；⑤第 4 槽未真机点验。相关项登记「未测（在途）」不判失败。
- **rc.2 相关**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；rc.1 回滚线保留；应用侧构建请同步 rc.2 线（`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5）。
- **hilog 缓冲（探针误报防护）**：512K 环在噪声大时只保留 ≈4–5 s（`--blazor-probe` 曾丢 `BLZ_BOOT` 报 `boot=no`）；临时 `hilog -G 16M -t app,core` 重跑（**跑完还原 512K**）。另注意**状态文件伪影**：`dotnet-status.txt`/壳轮询可能输出上一轮残留行——**以本轮时序内状态为准**。
- **本机直测（交付方）**：设备已可测（hdc 无线 `127.0.0.1:35111` + SDK 自签 + AOT/JIT/解释器三路径）；AOT 默认在 enforcing 镜像开箱可装（DEVCOMPAT-DEFAULT，承 #41）。
- 所有数字 = **kit #44 发布实测（以 release「## Integrity（kit #44）」与随包校验为准）**：tar **67,680,863 / `b777d8d8…`**、树 `db2604d5…`、sidecar `85d62a6e…`、`SHA256SUMS` 18 项 / 1,600 B / `41c1f3c3…`；#43 = tar 67,638,015 / `57c7bf44…`、#42 = tar 376,256,128 / `ea4e3b58…`、#41 = tar 376,036,502 / `bed460ae…`、#40 = tar 375,836,470 / `31ab8732…`（对照）；tester-run v14 = 140,197 / `a174fcd0…` 仅作对照；bundle = `workload-1.0.0-preview.28` **73,052,763 / `3b3008a4…`**（三处同步；dist sums `fee52445…`；sdkrc2 合并 sums 1,960 B / `2c64c534…`；sdk 锚 **`2abf4fcaa3`**）；dtk **392356147** / latest **392077166**（asset **608775822**/**608776466**；预签 **608782132**/**608782732**；interp pack rc2b asset **606999003**）；CI **5/5** @ `86b0e89`（interaction `37161898886` / pixel `37161898880` / host-export `37161898883` / ridgraph `37161898877` / markdownlint `37161898899`）；sdk `ohos-install-tests` @ `2abf4fcaa3` run `37164183212`。
- 细判（TTS/HUKS/自绘深度/权限/Share-Scan）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2 与 `…kit29/kit28/kit27/kit26/kit25`；无障碍逐项：`docs/plans/2026-09-27-ohos-accessibility-device-verification.md`（含 N4）；#44 细节：`2026-10-02-ohos-multi-overlay.md` §DYNAMIC、`2026-10-03-ohos-framepacing.md` 与 `2026-10-04-ohos-tester-handoff-kit44.md`。
