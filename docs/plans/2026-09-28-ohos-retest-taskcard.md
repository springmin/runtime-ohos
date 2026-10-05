# 复测任务单（一页）：kit #47 一轮设备判定（**a11y Flyout 节点数 1→70** + **抢占/恢复/重放原文（`[maui-capacity]`）** + 承 #46 INTERP-DRAW2 / FIX-A11YBUTTON + 承 #45 自动释放/INTERP-RENDER + 动态槽 + AOT 默认）（2026-10-05）

> 目标：一轮拿全 **#47 主判点**：①**FlyoutPage 无障碍节点数**（FIX-A11YFLYOUT：`PushChildren` 补
> `FlyoutPage.Detail`（恒入树）/ `FlyoutPage.Flyout`（仅 `IsPresented`）分支；真机 `--a11y-probe` **nodeCount
> 1→70**，此前只发布根 → 1；**测试方请带读屏（ScreenReader）环境**复跑 T2 开启态/L1/N1/F2/E1 role）；
> ②**抢占/恢复/重放原文**（FIX-PREEMPT-RAW：壳把 `dotnet-status.txt` 新增段中含 `overlay
> preempted/restored/replay` 的行以 `[maui-capacity]` 前缀直写 hilog——加 C/D/E（E 抢 A 槽）→ Activate A
> 后应取到 `preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`，活覆盖层 ≤4）
> + **承 #46** 的 INTERP-DRAW2（面外剔除：interp draw 14.4→9.4 ms、33.9→60.1 fps、每帧 CPU −27%；JIT 无回归）
> 与 FIX-A11YBUTTON（自检按钮左下角 + 覆盖层之上，两态可达 `[523,1622][607,1668]`）
> + **承 #45** 的自动释放（FIX-AUTODISCONNECT：Remove→`web slot destroy`→re-add→`web slot create`+交互恢复）
> 与 INTERP-RENDER（interp ≥30 fps、meas≈0、CPU −13pt；JIT/AOT 60 fps 不变）
> + **承 #44/#43** 动态槽（MAX/HOT 4/2 + 3 控件并发 + 第 5 槽 LRU 已真机点验）与默认 AOT、FRAMEPACING（60.00 fps）
> + **承 #42** 的 JIT 解锁（JITFORT）/解释器 rc2b/FIX-SLICERACE
> + **承 #41–#35** 的 MULTI-OVERLAY-FULL / DEVCOMPAT / FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP /
> HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10 与 **承 #34/#33** 的 rc.2 版本自述、W6/W7/W8、
> Blazor 双 hap A/B，并采 JIT/XWE/AOT/解释器/harmony 与无障碍。
> 执行入口 = `tester-run.sh`（版本/大小/摘要**以包内 `SCRIPT_VERSION` 与 release 资产页为准**；承 **v14**，
> 含 `--blazor-probe` / `--mode-matrix` / `--a11y-probe`）。
> 判定树与细节：`docs/plans/2026-10-05-ohos-tester-handoff-kit47.md`（逐项勾选 + §3 rc.2/AOT + §4 本机直测）、
> `docs/plans/2026-10-05-ohos-a11yflyout-preempt-export.md`（FIX-A11YFLYOUT/FIX-PREEMPT-RAW 定因）、
> `docs/plans/2026-10-04-ohos-interp-draw.md`（INTERP-DRAW2）、`docs/plans/2026-10-04-ohos-a11y-and-capacity.md`
> （FIX-A11YBUTTON / 第 5 槽）、`docs/plans/2026-10-04-ohos-jit-interp-soak.md`（SOAK-JI）、`…interp-render.md`、
> `…kit45`/`…kit44`/`…framepacing.md`/`…jitfort-enable.md`。
> 本页只给「取件 → 执行 → 回传 → 判定」。**kit #47 发布实测（release「## Integrity（kit #47）」；发布已完成，
> 一切数字以 release 与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准）**：tar **67,706,719 B / `3d6bb58b…`**、
> 树 **`0f266636…`**、sidecar **`4adb0b60…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `6bbc2235…`**
> （#46 = tar 67,708,823 / `c7c11814…`、#45 = tar 67,695,181 / `ca48a93c…`、#44 = 67,680,863 / `b777d8d8…` 对照）。
> **预签已刷新至 #47**（7 hap；**67,639,132 / `f58c4906…`**，asset **610975429**；sidecar 88 B /
> `c95344ac…`，asset **610976421**）；非 tester UDID 设备请回传 UDID 代签。
>
> **运行时口径（kit #43 起）**：**默认 AOT**；JIT 需 ACL/豁免（release/生产域 AGC ACL 或厂商豁免；debug/内测签名域免；亦可用 `--runtime-mode jit` 自建）；interp 为实验路径（独立 pack，不随主包）。
> **发布域（2026-10-04 实测）**：**发布形态请用 AOT**（release×AOT 正常出画）；**release×JIT 自签件 ~44 ms 崩**（`coreclr_initialize`，
> `SIGSEGV(SEGV_ACCERR)`）——需**华为发布 Profile + ACL/JIT 豁免**后复验；**覆盖装先卸载**（release↔debug `9568286`）、**过期 p7b=`9568329`**；
> **rc.2 监测**：官方 rc.2 **未发布（WAIT）**，ohos-workload `rc2-watch`（`1d39eb7`）触发后按清单换 pin。
> **a11y 口径**：交付方沙箱无读屏客户端（AMS `accessible=0`/client=0），nodeCount=70 为壳自检读数；
> 朗读/焦点顺序/动作类（T2/L1/N1/F2/E1 role）**需测试方带 ScreenReader 环境**复跑。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #47，2026-10-05） | **67,706,719** | **`3d6bb58b…`**（sidecar `4adb0b60…`；树 `0f266636…`；`SHA256SUMS` 18 项 / 1,600 B / `6bbc2235…`；dtk **392356147** / latest **392077166**；asset **610969198** / **610970271**） | **7 hap**（5 MAUI 全 AOT：`runtime-mode.txt=aot`、3 `.so`（app.so + host 297,888 + `libc++_shared.so` 1,267,392）、无 libcoreclr/libhostfxr/libclrjit；abc **370,240（`4b439e83…`）**/24,324、宿主 **297,888（`7b1694d9…`）**、导出 **151**）+ **2 个 Blazor 对照 hap**（bundle `com.example.opendotnet`，无 INTERNET）+ `verify-kit.sh`（0 FAIL/0 WARN）+ 文档 + `runtime-mode.txt=aot` |
| `preSigned-haps.tar.gz`（**预签直装**；#34 起加发；**本波已刷新至 #47**） | **67,639,132**（asset **610975429**；sidecar 88 B / `c95344ac…`，asset **610976421**；树 `70775143…`） | **`f58c4906…`** | 7 hap = **kit #47 原名件**，按 tester UDID `60CF7B27…` 预签：`sha256sum -c SHA256SUMS` → `hdc install -r` **直装**；非本 UDID 设备仍 `9568344` |
| AOT 复测取件（`aot-haps*`；rc.2 pack 已重出 `-struct1`：结构修复 + shim） | **18,185,012**（`aot-haps-v3-rc2.tar.gz`；本批未动；dtk 599996905） | **`3d24f716…`** | AOT hap（含 UIPage 出画修复）；rc.2 设备/本机构建用 **`-struct1`**（`…rc.2.26451.112-struct1.nupkg` 28,905,116 / `09345f95…`，asset 607541145；sdk fetch 现锚）；`-r2`（28,904,657 / `542058cf…`，asset 601289590）与原包（`46d221f2…`）仅历史、不再钉锚；装前重签 |
| **解释器 pack** `ohos-interpreter-pack-rc2b.tar.gz` | **2,410,595**（asset **606999003**；README **606999004**；sidecar **606999001**） | **`5974430509…`** | **INTERP-NULL 修复 + WX-PATCH2**（`libcoreclr` `4b30a4c1…`/`e150558a…` + `libclrinterpreter` `11fc5052…`/`3e4b4d10…`）；配 #42+ 宿主（JITFORT + 8 MB 栈）使用；rc2 旧件（605924427）/rc.1 旧件（2,419,988 / `a10699b3…`）保留作对照 |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`） |
| `tester-run.sh`（随包） | 以包内为准（承 v14 = 140,197 / `a174fcd0…`） | 以包内为准 | 执行器；`--blazor-probe`、`--mode-matrix`、`--a11y-probe` 承 #33 |

包内 7 hap（kit #47 发布实测，`SHA256SUMS` 18 项 / 1,600 B / `6bbc2235…`）：`hello-maui-app.hap` **22,331,837 / `37c958f2…`**（AOT）、`…-unsigned` **22,032,434 / `c0fa3727…`**、`…-permissions` **22,331,836 / `faf84159…`**、`…-api20` **22,331,829 / `c22343fb…`**、`…-api20-permissions` **22,331,832 / `5dcbd219…`**、Blazor 默认 **27,216,958 / `8ef34e95…`**（未签名）、`-nocsp` **27,216,659 / `2d4cd004…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。

**预签直装捷径（可选）**：`sha256sum -c SHA256SUMS` 后 `hdc install -r` 直装，**§2 的「先重签」可跳过**（同 bundle
换件仍先卸载）；预签件已刷新至 #47，可直接用于本轮。完整一轮 / 源码复测请用 `device-test-kit.tar.gz`。

## 2. 执行顺序（每步「期望 → 回传」）

0. **校验 kit**：包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap；5 MAUI hap 期望
   `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；abc 期望 **370,240/24,324**）→ 回传终端输出。
1. **FlyoutPage a11y 节点数（#47 主判点 1，FIX-A11YFLYOUT）**：装默认 kit 主 hap（AOT）→
   `sh tester-run.sh --kit-dir ./device-test-kit --a11y-probe`（或 `uitest` 点自检按钮）→ 期望
   `a11y/selfcheck.txt`：`accessibilityStatus: 1 (attached - expected)`、**nodeCount=70**（此前同路径 1）；
   展开抽屉（flyout presented）时 flyout 入树且 **detail 保留**；收起后 flyout 不入树。**带读屏环境**复跑
   T2 读屏开启态 / L1 Label / N1 List / F2 滚动焦点保持 / E1 role → 回传 `a11y/` 两文件 + 截图 + `summary a11y_*`。
2. **抢占/恢复/重放原文（#47 主判点 2，FIX-PREEMPT-RAW）**：加满 3 控件（A/B/C）后加 C/D/E（共 5 控件，
   **E 抢 A 槽**）→ Activate A（A 恢复领槽、B 被抢）→ 抓 hilog：期望 **`[maui-capacity]`** 原文
   `preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`（交付方一轮共 5 行导出）；
   全程活覆盖层 ≤4；截图/JSON 对应覆盖层出现/消失。注意 512K hilog 时长按窗内节奏复放；行落入窗内才导出。
   → 回传 `hilog | grep maui-capacity` 原文 + `hybrid assets slot=` 行 + 截图。
3. **INTERP-DRAW2（#46 主判点，承）**：解释器轮（rc2b pack + rc.2 kit hap + `interp.txt=3`）出画稳定后统计：
   期望 interp **draw ≤10 ms/帧、稳态 60 fps**（交付方 14.4→9.4 ms、33.9→60.1 fps、每帧 CPU −27%）；JIT/AOT
   60 fps 不回归（JIT draw −15%）；交互不变（Count 0→1）→ 回传帧统计（`FPH` 行）+ 截图 + hilog。
4. **FIX-A11YBUTTON（#46 主判点，承）**：有 web 控件（Home）与 no-web 变体两态点自检按钮：期望按钮在
   **左下角、覆盖层之上**可点（`[523,1622][607,1668]`，窗口相对左下 8/7 px）、点按出对话框 `status=1`
   → 回传 `uitest` dump/截图两态。
5. **自动释放（#45 主判点，承）**：加满 3 个 Web 控件 → **移除第 3 个**：期望 `web slot destroy: 2`、覆盖层消失、
   热对 [0,1] 不受影响 → **再加回**：期望 `web slot create: 2` 重建、交互恢复（`sent raw C-raw-ping (stock)` /
   `invoke: "C-echo:Echo:1"`）→ 回传移除/重挂截图（c1–c5 同构）+ hilog。
6. **INTERP-RENDER（#45 主判点，承）**：解释器轮出画稳定后统计：期望 **≥30 fps（交付方复测 38–44）**、
   meas≈0 ms/帧、主线程 CPU 65.5–70.5%（−13pt）、无 `SIGSEGV(NULL)`；JIT/AOT 60 fps 不变 → 回传帧统计 + 截图 + hilog。
7. **动态槽 3 控件 + 第 5 槽（承 #44/#45）**：同页 3 控件并发出画/交互（`web cmd: slot`→`web slot create: 2`、
   容量 `web capacity: 4`）；第 5 槽超容量：主动抢占→slot 0、Activate→恢复重放、活覆盖层 ≤4 → 回传截图 + hilog。
8. **AOT 默认 + FRAMEPACING（承 #44/#43）**：默认包冷启 → 期望 kit 根/逐 hap `runtime-mode.txt=aot`、
   无 libcoreclr/libclrjit、首帧 + 交互回归（`aot=1`、`canvas presented`）；present 聚合真实 **60.00 fps**（旧 17.7 系
   壳状态轮询伪影）→ 回传截图 + hilog + 帧统计。
9. **rc.2 版本自述**：读包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary → 期望 SDK
   `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；无 rc.1 混装告警 → 回传自述原文 + summary。
10. **承 #42**：①JIT（自建 `--runtime-mode jit` 包或 ACL 域）：`jitfort rc=0` + 探针 `1=OK 2=OK` + 首帧；
    ②解释器：rc2b pack + rc.2 kit hap + `interp.txt=3` → `canvas presented`、无 `SIGSEGV(NULL)`；
    ③FIX-SLICERACE：JIT 8 轮 `race=0 pvnull=0 conc=0 unhandled=0`；④L6/SAMPLE-FIX/WX-PATCH2/P2c 同 #42 判读 → 回传截图 + hilog。
11. **承 #41**：MULTI-OVERLAY-FULL（双 Hybrid 各自 invoke/消息；3–5 控件场景已覆盖；旧壳 >2 按 LRU 抢占）；
    DEVCOMPAT-DEFAULT（enforcing 开箱可装）；INTERP-FIX（8 MB 栈 + 关写屏障）→ 回传截图 + hilog。
12. **承 #40**：FIX-JSCALL = razor 页点 "Blazor click" 两次 → **count 0→1→2**（SAMPLE-FIX 后 `blzProbe` 报
    `dotnet-ref ok`）→ 回传截图 r0/r1/r2 + hilog。
13. **承 #39/#38/#37**：FIX-BACKSIZE = 抽屉开 → 系统 Back 关抽屉（仍 `#FOREGROUND`）；FIX-BWVMount = `.razor` 挂载；
    FIX-DISMISS = 抽屉外点关闭；FIX-WVP = Hybrid 出画 + bridge；FIX-HOME = Home tab 整页出画；FIX-ITOUCH =
    注入点击命中 → 回传截图 + hilog。
14. **承 #36**：payload 原地直载 + `--a11y-probe`（`status=1` + 正整数节点数；#47 主包 70、wasm 5）
    → 回传 hilog + `a11y/` 两文件。
15. **B2：MAUI WebView 内嵌 Blazor WASM（承 #35 主判点）**：装含 WebView/WASM 入口的包内演示 hap，AOT 路径启动 →
    打开嵌入式 Blazor 页 → 期望 **`BLZ_BOOT` + `BLZ_RENDERED` 同 pid 双标记齐**（无 `BLZ_ERROR`）、首屏渲染、
    `/counter` 类交互 +1 → 回传 hilog + 首屏/交互截图。
16. **W9B/W9C/W9D/W10（承 #35）**：T14/T21/T8/T20/T19/AOT 入口可观测 → 逐条截图/回传（无 MediaKit 属预期不判失败；
    热 `delivered=1`；`dotnet-status.txt` 托管行）。
17. **承 #34：W6/W7/W8**：W6 = T14/T12/N1/FIX-SHELL；W7/W8 = T15/T16/N4（`--a11y-probe`）/T18/N5/N6 → 逐条截图/终端输出
    （套件自报行 **`[suite] checks=593 total=595 floor=575 assert=True`**）。
18. **承 #33：Blazor A/B**：装默认件 → `--blazor-probe` → 记录 `BLZ_BOOT`/`BLZ_RENDERED`（pid+nonce）与人工首屏/`/counter`
    +1/截图；**卸载后**装 `-nocsp` 件 → 同命令 → 按 #33 判读表落结论。
19. **承 #33：MAUI 主体（TabbedPage/W5）**：双页签出画 + 切页；T13/N3/T21/T22。AOT 为默认路径。
20. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60`
    → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全 → 回传 `mode-matrix/` 全目录 + 四个 `tester-report-*.tar.gz`。
21. **WebView 六项 + B1 razor（承 #32）**；**harmony 变体（AGC 就绪时）**：按卡逐条 / 同指纹重签 → 回传截图 + hilog +
    Map/LiveView/TTS/HUKS 证据。

## 3. 判定表（逐 Run 填）

| 态/项 | 判据 | 结论 |
|---|---|---|
| **FlyoutPage a11y 节点数（#47 主判点 1）** | `status=1` + **nodeCount=70**（此前 1）；detail 恒发布、flyout 仅 presented 且保 detail；读屏环境复跑 T2/L1/N1/F2/E1 | #47 落地 |
| **抢占原文（#47 主判点 2）** | `[maui-capacity]` 原文：`preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`；活覆盖层 ≤4 | #47 落地 |
| **INTERP-DRAW2（#46 主判点）** | interp draw ≤10 ms/帧、稳态 60 fps（33.9→60.1）；JIT draw −15%、fps 不变 | #46 落地 |
| **FIX-A11YBUTTON（#46 主判点）** | 两态按钮左下角可达 `[523,1622][607,1668]`、点按出对话框 | #46 落地 |
| **自动释放（#45 主判点 0）** | Remove C → `web slot destroy: 2` + 覆盖层消失；re-add → `web slot create: 2` + 交互恢复 | 承 #45 保持 |
| **INTERP-RENDER（#45 主判点）** | interp ≥30 fps（复测 38–44）+ meas≈0 + CPU −13pt；JIT/AOT 60 fps 不变；交互 Count 0→1 | 承 #45 保持 |
| **动态槽 3 控件并发（承 #44）** | 3 控件各自出画 + 交互回显（A/B/C）；`web slot create: 2` / `web capacity: 4` | 承 #44 保持 |
| **第 5 槽超容量（承 #45 已真机点验）** | 主动抢占→slot 0、Activate→恢复重放、活覆盖层 ≤4（复跑同序） | 承 #45 闭环 |
| **AOT 默认（承 #44/#43）** | `runtime-mode.txt=aot` + 3 `.so`/无 libcoreclr/libclrjit + 首帧/交互回归 | 承 #43 保持 |
| **发布域（2026-10-04 实测，交测口径）** | 发布形态 = **AOT**（release×AOT 正常）；release×JIT 自签 ~44 ms 崩 → 需华为发布 Profile + ACL/JIT 豁免；覆盖装先卸载（9568286）、过期 p7b=9568329 | 交测口径 |
| **FRAMEPACING（承 #44/#43）** | 真实呈现 60.00 fps（17.7 = 壳状态轮询伪影） | 承 #43 保持 |
| **门禁（#47）** | `[suite] checks=593 total=595 floor=575 assert=True`；导出 151/151；pixel 43 PASS | #47 基座 |
| **JIT 解锁（承 #42）** | 自建 jit 或 ACL 域：`jitfort rc=0` + 探针 `1=OK 2=OK` + 首帧 | 承 #42 保持 |
| **解释器首帧（承 #42）** | rc2b pack + rc.2 kit hap → `canvas presented`；无 `cppcrash`、无 `SIGSEGV(NULL)`；`summary interp_mode=3(file)` | 承 #42 保持 |
| **FIX-SLICERACE（承 #42）** | JIT 冷启/重启循环 8 轮：`race=0 pvnull=0 conc=0 unhandled=0` + 首帧 | 承 #42 保持 |
| **L6 / LEGACY / SAMPLE-FIX / WX-PATCH2 / P2c（承 #42）** | JPEG 落盘/标题心跳；Toolbar 契约；`blzProbe`=`dotnet-ref ok`、`#app`、计数 0→1→2；无 `ACCERR`；`module.json` skills | 承 #42 保持 |
| **MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX（承 #41）** | 双 Hybrid/per-slot invoke/z-order；enforcing 开箱可装；8 MB 栈 + 关写屏障 | 承 #41 保持 |
| **FIX-JSCALL（承 #40）** | razor 点两次 → count 0→1→2；`missing native code`=0 | 承 #40 保持 |
| **FIX-BACKSIZE / FIX-BWVMount（承 #39）** | Back 关抽屉；`.razor` 挂载 | 承 #39 保持 |
| **FIX-DISMISS / FIX-WVP / FIX-HOME / FIX-ITOUCH（承 #38/#37）** | 外点关；Hybrid 出画+bridge；Home 整页出画；注入命中 | 承 #37/#38 保持 |
| **payload / 像素 / a11y / AOT `-struct1`（承 #36）** | `payload-in-libs: running from …`；无 `Known`；`status=1`+nodeCount；`-struct1` 构建成立 | 承 #36 保持 |
| **B2 / W9 / W10（承 #35）** | 双标记齐；T14/T21/T8/T20/T19；AOT 入口行 | 承 #35 落地 |
| **rc.2 基线 + W6/W7/W8（承 #34）** | 版本自述；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6 | rc.2 线成立 |
| **Blazor A/B + 主体（承 #33）** | 默认/nocsp 双标记；TabbedPage/W5；套件 `593 total=595 floor=575` | #33 保持 |
| **JIT / XWE / AOT / 解释器 / harmony / runtime_mode** | 各态判据同前；AOT 为默认、JIT 为形态保留 | 各判定成立 |
| **WebView / B1 razor（承 #32）** | 9 项卡 + B1 两标记 + JS 往返 | 按 #32 判据 |

> 失败 Run 保留报告 tar；无入口项登记「未测（本包无入口/无 hdc）」，不判失败。

## 4. 注意

- 包内 hap 为自签：**9568257 / 9568344 属预期**，先重签（需华为调试证书 + Profile 绑 UDID）；**预签件已刷新至 #47**——可直接
  `hdc install -r` 直装（非 tester UDID 仍 `9568344`，请回传 UDID 代签）；**Blazor 双变体同名（`com.example.opendotnet`），装前卸载**；
  两变体均无 INTERNET（重签保持）。
- **a11y Flyout 口径（#47）**：a11y 走查自 `IWindow.Content`；`PushChildren` 补 `FlyoutPage.Detail`（恒入树）与
  `FlyoutPage.Flyout`（仅 `IsPresented`）分支（rc.1 FlyoutPage 非 `IContentView`，旧分支覆盖不到 → 只发布根 → 1）；
  headless 断言 detail（nodes>1、未展开无 flyout）与 panel（flyout 入树且保 detail），负控制红；真机自检 nodeCount=70
  （此前 1）。**无读屏客户端时朗读/焦点顺序/动作类不可测**，测试方请带 ScreenReader 环境复跑 T2/L1/N1/F2/E1。
- **抢占原文口径（#47）**：壳 `pollManagedStatus` 只导出自上次轮询的**新增段**（12×3 s 轮询节奏；文件被 trim 时
  整文件回退）；`[maui-capacity]` 行 = `overlay preempted/restored/replay` 原文。512K 环噪声大时可能丢行——以原文 +
  截图/覆盖层出现消失 + invoke 回显组合判据；无对应入口登记「未测」。
- **INTERP-DRAW2 口径（#46）**：面外剔除 = 节点自身 Canvas 矩形（含 shadow 外延）不与 surface 相交且无 `shifted`
  祖先时跳过自身绘制（子树照走；Image/弹层/TitleView 永不剔除）；只做 surface 级（ScrollView 子树仍随 `shifted` 走）；
  interp 已触 60 Hz 上界，JIT 无回归。判定以 `FPH` 稳态窗 + 交互回归为准。
- **自动释放口径（#45）**：MAUI 移除子项只改子列表、handler 保持连接（MAUI 语义）；本波由页面/ContentView/Layout 子树
  watcher 驱动切片 `IOpenHarmonyOverlaySlotLifetime`——detach 时 hide + 释放槽（动态槽在壳内 destroy）、re-attach/后续 arrange
  时重领槽 + 重放 load/注册；晚到属性/挂载 pass 被忽略；LRU 抢占/恢复不变。热对 [0,1] 的移除只 hide、槽位保留。
- **动态槽口径（承 #44）**：MAX/HOT 默认 4/2（env 不可按应用注入；clamp 2..8 / 2..max）；热对 [0,1] 常驻、空闲 >2 不养
  ArkWeb 引擎/文档（重建只付一次组件+加载）；容量下调按 suspend 抢占超容量 claim（旧 2 槽壳安全降级）；`web slot destroy`
  原文可能秒级轮转丢失——以截图 + 重建交互闭环为准。
- **INTERP-RENDER 口径（#45）**：解释器固有放大（draw + present > vsync）是主因；本波去掉的是**静态帧全树 Measure/Arrange**，
  非脏区/裁剪。判定以 `FPH` 稳态窗 + 交互回归为准；JIT/AOT 60 fps 不应回归。
- **AOT 默认口径（#43 起）**：5 MAUI hap 全 NativeAOT（`runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libhostfxr/libclrjit）；
  JIT 保形态（`--runtime-mode jit` 自建；debug 域 JITFORT 默认；release 域需 AGC ACL
  `ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`（2in1/平板）或厂商豁免——手机只发 AOT）；interp 实验（独立 pack）。
- **发布域口径（2026-10-04 实测）**：**发布形态请用 AOT**（release×AOT 正常）；**release×JIT 自签件 ~44 ms 崩**
  （`coreclr_initialize`，`SIGSEGV(SEGV_ACCERR)`）→ 需**华为发布 Profile + ACL/JIT 豁免**后复验，不能由自签外推；
  **覆盖装先卸载**（release↔debug `9568286`）、**过期 p7b=`9568329`**（`2026-10-04-ohos-release-domain-and-pidloss.md`）。
- **启动/帧率基线（#45 切片复测，2026-10-04）**：三路径 cold/warm 首帧（`t0→首帧`）**1.56–1.69 s**（JIT 1.68/1.68、
  interp 1.62/1.56、AOT 1.69/1.64；差异 <200 ms）；interp 稳态 **38–44 fps**（安静桌面；≥30 判过）、JIT/AOT **60 fps**
  （`2026-10-04-ohos-jit-interp-recheck.md`）。
- **JIT/interp 浸泡（SOAK-JI，2026-10-05）**：JIT 45 min（+21.6 MB、60.1 fps、0 崩/0 冻结/0 失 pid）、interp 45 min
  （rc2b+优化件，−102.3 MB 尾段大回收、34.3 fps 镜像口径、0 崩）→ 与 AOT soak2 对照背书成立
  （`2026-10-04-ohos-jit-interp-soak.md`）。
- **解释器口径**：用 **rc2b pack** + **rc.2 kit hap**（重签）；勿用 rc.1 托管 CoreLib 的旧测试件（QCall ABI 错配会
  `SIGSEGV(NULL)@coreclr_initialize`，属测试件问题、非 pack 缺陷）。`interp.txt=1|2` 混合模式保留默认（不注入 barrier skip）。
- **AOT pack 结构修复**：`FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分（静态 `.a` 保留 dlopen shim、共享 `.so` 仍静态链 OpenSSL；
  sdk 构建在布局与 nupkg 两处校验）——**当前资产 = `-struct1`**（asset 607541145；`-r2`/原包仅历史），后续 runtime pack 无需再重打。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递（`skills[].uris` 本机产物已可验）；②镜像扩展分支
  `m-web-mirror d47f1fcb3b` 尚未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过（未定位）；
  ④stock JIT 长跑/后台唤醒未覆盖（JIT 现非默认）；⑤解释器混合模式保留默认。其余相关项登记「未测（在途）」不判失败。
- **rc.2 相关（2026-10-04 复核：WAIT）**：官方 rc.2 **未发布**（nuget.org 最新仍 `11.0.0-rc.1.26451.6`）；ohos-workload 已加监测
  `rc2-watch`（`1d39eb7`；`scripts/rc2-official-watch.sh` + `.github/workflows/rc2-watch.yml`，周一 03:17 UTC + dispatch；
  状态 `docs/rc2-official-watch.md`）；触发（exit 10）后按 `docs/plans/2026-09-30-rc2-mainline-adoption.md` §8 换 pin、删
  dnceng feed step；触发前 restore 仍走 dnceng `dotnet11` feed；rc.1 回滚线保留；应用侧构建请同步 rc.2 线（同文 §4/§5）。
- **hilog 缓冲（探针误报防护）**：512K 环在噪声大时只保留 ≈4–5 s（`--blazor-probe` 曾丢 `BLZ_BOOT` 报 `boot=no`）；临时
  `hilog -G 16M -t app,core` 重跑（**跑完还原 512K**）。另注意**状态文件伪影**：`dotnet-status.txt`/壳轮询可能输出上一轮
  残留行——**以本轮时序内状态为准**（抢占原文导出亦按本轮新增段判读）。
- **本机直测（交付方）**：设备已可测（hdc 无线 `127.0.0.1:35111` + SDK 自签 + AOT/JIT/解释器三路径）；AOT 默认在 enforcing
  镜像开箱可装（DEVCOMPAT-DEFAULT，承 #41）。
- 所有数字 = **kit #47 发布实测（以 release「## Integrity（kit #47）」与随包校验为准）**：tar **67,706,719 / `3d6bb58b…`**、
  树 `0f266636…`、sidecar `4adb0b60…`、`SHA256SUMS` 18 项 / 1,600 B / `6bbc2235…`；
  #46 = tar 67,708,823 / `c7c11814…`、#45 = 67,695,181 / `ca48a93c…`、#44 = 67,680,863 / `b777d8d8…`、#43 = 67,638,015 / `57c7bf44…`、
  #42 = 376,256,128 / `ea4e3b58…`（对照）；tester-run v14 = 140,197 / `a174fcd0…` 仅作对照；
  bundle = `workload-1.0.0-preview.28` **73,059,625 / `27c54c62…`**（三处同步；dist sums `2954ab3d…`；sdkrc2 合并 sums
  1,960 B / `c63de22e…`；sdk 锚 **`266b196106`**）；dtk **392356147** / latest **392077166**（kit tar/边车 asset
  **610969198**/**610970096**、latest **610970271**/**610971070**；bundle 三处 preview.28 **610961477**/**610964667**、
  latest **610964837**/**610966356**、sdkrc2 **610966541**/**610968963**；预签 **610975429**/**610976421**；
  interp pack rc2b asset **606999003**；AOT `-struct1` asset **607541145**）；CI **5/5** @ `3de9a95fe0`
  （interaction `37243299311` / pixel `37243299320` / host-export `37243299309` / ridgraph `37243299327` / markdownlint `37243299305`）；
  sdk `ohos-install-tests` @ `266b196106` run `37245230111`。
- 细判（TTS/HUKS/自绘深度/权限/Share-Scan）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2 与 `…kit29/kit28/kit27/kit26/kit25`；
  无障碍逐项：`docs/plans/2026-09-27-ohos-accessibility-device-verification.md`（含 N4）；#47 细节：
  `2026-10-05-ohos-a11yflyout-preempt-export.md` 与 `2026-10-05-ohos-tester-handoff-kit47.md`；#46 细节：
  `2026-10-04-ohos-interp-draw.md`、`2026-10-04-ohos-a11y-and-capacity.md`；#45 细节：
  `2026-10-04-ohos-interp-render.md`、`2026-10-04-ohos-a11y-and-capacity.md`。
