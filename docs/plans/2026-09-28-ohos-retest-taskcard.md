# 复测任务单（一页）：kit #49 一轮设备判定（**应用内子窗 MULTIWINDOW-M**：create/move/resize/close + 主窗协同 + **a11y 密码脱敏 SEC-SCAN-4** + 承 #48 R2R/JIT 启动 1031→710 ms + AOT 首帧 796→534 ms + 帧率投票 60 + 多窗 S + FIXRR + 承 #47 a11y Flyout 1→70 / 抢占原文 + 承 #46/#45 全量）（2026-10-05）

> 目标：一轮拿全 **#49 主判点**：①**应用内子窗**（MULTIWINDOW-M：壳 `Window.createSubWindowWithOptions` 子窗控制器
> —— 命令 0 create/1 move/2 resize/3 show/4 hide（无公开 hide API：如实回 Failed 801）/5 close，事件
> 0 created…10 resumed；`pages/SubWindow.ets` 壳绘 named-route（`ohos_dotnet_subwindow` + `WindowProperties.name`
> move guard）；主窗 HIDDEN/SHOWN 转 suspended/resumed + 挂起期命令抑制；宿主 `registerSubWindowSink`/
> `notifySubWindowEvent` NAPI + `ohos_host_sub_window_command`（op 99 探针）/`ohos_host_sub_window_event_listener`
> （导出 151→**153**）；切片 `OpenHarmonySubWindow`（AOT 安全、离设备退化）；真机 HAD-W32：
> `app://subwindow/demo` **create id=344（120,160 720×480）→ move 420,360 → resize 900×600 → close**，
> `app://subwindow/open` id=346 **touch #57 / drag #51→269,259**，主窗 HIDDEN/SHOWN→suspended/resumed、60fps
> 无新 fault；诚实边界：单 surface/renderer，子窗内容为壳侧 ArkUI 自绘，非第二 MAUI 视觉树）；
> ②**a11y 密码脱敏**（SEC-SCAN-4：影子树不再发布密码明文——`OpenHarmonyAccessibility` 对
> `IEntry{IsPassword}`/平台 `IsPassword` 走同一 `MaskPassword` 发布等长圆点；套件 +2 pin；离线红/绿负控、
> **设备未验证**；其余 6 项报告级）
> + **承 #48** 的 **R2R/JIT 启动**（CG2-R2R：JIT 冷启 **1031→710 ms**、in-proc 575→307；interp R2R=0 FIXRR）、
> **AOT 首帧**（796→534 ms、attach→surface 239→13）、**帧率投票 60**（46.2→60.0 fps）、**多窗 S**（2in1
> 2090×1394→3120×1955）
> + **承 #47** 的 FIX-A11YFLYOUT（`--a11y-probe` **nodeCount 1→70**）与 FIX-PREEMPT-RAW（`[maui-capacity]`
> 抢占/恢复/重放原文）
> + **承 #46** 的 INTERP-DRAW2（interp draw 14.4→9.4 ms、33.9→60.1 fps、每帧 CPU −27%）与 FIX-A11YBUTTON
> + **承 #45** 的自动释放（Remove→`web slot destroy`→re-add→`web slot create`+交互恢复）与 INTERP-RENDER
> + **承 #44/#43** 动态槽（MAX/HOT 4/2 + 3 控件并发 + 第 5 槽 LRU）与默认 AOT、FRAMEPACING（60.00 fps）
> + **承 #42** 的 JIT 解锁（JITFORT）/解释器 rc2b/FIX-SLICERACE
> + **承 #41–#35** 的 MULTI-OVERLAY-FULL / DEVCOMPAT / FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP /
> HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10 与 **承 #34/#33** 的 rc.2 版本自述、W6/W7/W8、
> Blazor 双 hap A/B，并采 JIT/XWE/AOT/解释器/harmony 与无障碍。
> 执行入口 = `tester-run.sh`（版本/大小/摘要**以包内 `SCRIPT_VERSION` 与 release 资产页为准**；承 **v14**，
> 含 `--blazor-probe` / `--mode-matrix` / `--a11y-probe`）。
> 判定树与细节：`docs/plans/2026-10-05-ohos-tester-handoff-kit49.md`（逐项勾选 + §3 rc.2/AOT/Crossgen2 + §4 本机直测）、
> `docs/plans/2026-10-05-ohos-multiwindow-m.md`（M 落地：命令/事件/真机流程/L 余量）、
> `docs/plans/2026-10-05-ohos-security-scan-4.md`（密码脱敏 +2 断言与红/绿负控）、
> `…tester-handoff-kit48.md`（R2R/首帧/帧率/多窗 S/FIXRR）、`…tester-handoff-kit47.md`
> （FIX-A11YFLYOUT/FIX-PREEMPT-RAW）、`…interp-draw.md`、`…a11y-and-capacity.md`、`…jit-interp-soak.md`、
> `…interp-render.md`、`…kit45`/`…kit44`/`…framepacing.md`/`…jitfort-enable.md`。
> 本页只给「取件 → 执行 → 回传 → 判定」。**kit #49 发布实测（release「## Integrity（kit #49）」；发布已完成，
> 一切数字以 release 与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准）**：tar **67,888,851 B / `477974bb…`**、
> 树 **`8d03cb4c…`**、sidecar **`3803b3db…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `b142639d…`**
> （#48 = tar 67,735,148 / `5c22704f…`、#47 = 67,706,719 / `3d6bb58b…`、#46 = 67,708,823 / `c7c11814…` 对照）。
> **预签已刷新至 #49**（7 hap；**67,807,185 / `56aaf08f…`**，asset **612929512**；sidecar 88 B /
> `4ba00cf8…`，asset **612930421**）；非 tester UDID 设备请回传 UDID 代签。
>
> **运行时口径（kit #43 起）**：**默认 AOT**；JIT 需 ACL/豁免（release/生产域 AGC ACL 或厂商豁免；debug/内测签名域免；
> 亦可用 `--runtime-mode jit` 自建，加 R2R 见 §2 步骤 3）；interp 为实验路径（独立 pack，不随主包）。
> **发布域（2026-10-04 实测）**：**发布形态请用 AOT**（release×AOT 正常出画）；**release×JIT 自签件 ~44 ms 崩**
> （`coreclr_initialize`，`SIGSEGV(SEGV_ACCERR)`）——需**华为发布 Profile + ACL/JIT 豁免**后复验；**覆盖装先卸载**
> （release↔debug `9568286`）、**过期 p7b=`9568329`**；**rc.2 监测**：官方 rc.2 **未发布（WAIT）**，
> ohos-workload `rc2-watch`（`1d39eb7`）触发后按清单换 pin。
> **a11y 口径**：交付方沙箱无读屏客户端（AMS `accessible=0`/client=0），nodeCount=70 为壳自检读数、密码脱敏为
> 离线红/绿负控；朗读/焦点顺序/动作类（T2/L1/N1/F2/E1 role）与密码节点实读**需测试方带 ScreenReader 环境**复跑。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #49，2026-10-05） | **67,888,851** | **`477974bb…`**（sidecar `3803b3db…`；树 `8d03cb4c…`；`SHA256SUMS` 18 项 / 1,600 B / `b142639d…`；dtk **612922031** / latest **612923086**；asset **612922031** / **612923086**） | **7 hap**（5 MAUI 全 AOT：`runtime-mode.txt=aot`、3 `.so`（app.so + host **301,984** + `libc++_shared.so` 1,267,392）、无 libcoreclr/libhostfxr/libclrjit；abc **414,532（`e016db13…`）**/24,324、宿主 **301,984（`cf4cc706…`）**、导出 **153**；AOT payload `libhello-maui-app.so` 19,258,128）+ **2 个 Blazor 对照 hap**（bundle `com.example.opendotnet`，无 INTERNET）+ `verify-kit.sh`（`--expected-abc 414532` → 0 FAIL/0 WARN）+ 文档 + `runtime-mode.txt=aot` |
| `preSigned-haps.tar.gz`（**预签直装**；#34 起加发；**本波已刷新至 #49**） | **67,807,185**（asset **612929512**；sidecar 88 B / `4ba00cf8…`，asset **612930421**；树 `acce2fe9…`） | **`56aaf08f…`** | 7 hap = **kit #49 原名件**，按 tester UDID `60CF7B27…` 预签：`sha256sum -c SHA256SUMS` → `hdc install -r` **直装**；非本 UDID 设备仍 `9568344` |
| AOT 复测取件（`aot-haps*`；rc.2 pack 已重出 `-struct1`：结构修复 + shim） | **18,185,012**（`aot-haps-v3-rc2.tar.gz`；本批未动；dtk 599996905） | **`3d24f716…`** | AOT hap（含 UIPage 出画修复）；rc.2 设备/本机构建用 **`-struct1`**（`…rc.2.26451.112-struct1.nupkg` 28,905,116 / `09345f95…`，asset 607541145；sdk fetch 现锚）；`-r2`（28,904,657 / `542058cf…`，asset 601289590）与原包（`46d221f2…`）仅历史、不再钉锚；装前重签 |
| **Crossgen2 rc.2 包（承 #48；JIT R2R）** | **43,792,647**（`crossgen2-packs-11.0.0-rc.2`；asset `RA_kwDOT39XK84kdPmt`） | **`6bb8a375…`** | JIT 自建包 `-p:PublishReadyToRun=true` 的 folder feed（NU1100 消除）；含 `crossgen2` apphost + `ILCompiler.*` + openharmony overlay；与 runtime-ohos release 同字节 |
| **解释器 pack** `ohos-interpreter-pack-rc2b.tar.gz` | **2,410,595**（asset **606999003**；README **606999004**；sidecar **606999001**） | **`5974430509…`** | **INTERP-NULL 修复 + WX-PATCH2**（`libcoreclr` `4b30a4c1…`/`e150558a…` + `libclrinterpreter` `11fc5052…`/`3e4b4d10…`）；配 #42+ 宿主（JITFORT + 8 MB 栈 + interp R2R=0）使用；rc2 旧件（605924427）/rc.1 旧件（2,419,988 / `a10699b3…`）保留作对照 |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`） |
| `tester-run.sh`（随包） | 以包内为准（承 v14 = 140,197 / `a174fcd0…`） | 以包内为准 | 执行器；`--blazor-probe`、`--mode-matrix`、`--a11y-probe` 承 #33 |

包内 7 hap（kit #49 发布实测，`SHA256SUMS` 18 项 / 1,600 B / `b142639d…`）：`hello-maui-app.hap` **22,422,722 / `39a2433e…`**（AOT）、`…-unsigned` **22,121,783 / `3e9adba2…`**、`…-permissions` **22,422,716 / `a825629b…`**、`…-api20` **22,422,704 / `6183f813…`**、`…-api20-permissions` **22,422,700 / `a050e0a0…`**、Blazor 默认 **27,218,497 / `3a82a082…`**（未签名）、`-nocsp` **27,218,194 / `eb14048e…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。

**预签直装捷径（可选）**：`sha256sum -c SHA256SUMS` 后 `hdc install -r` 直装，**§2 的「先重签」可跳过**（同 bundle
换件仍先卸载）；预签件已刷新至 #49，可直接用于本轮。完整一轮 / 源码复测请用 `device-test-kit.tar.gz`。

## 2. 执行顺序（每步「期望 → 回传」）

0. **校验 kit**：包内 `sh verify-kit.sh --expected-abc 414532` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap；
   5 MAUI hap 期望 `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；abc 期望 **414,532/24,324**）。
   #49 包内脚本默认仍是 #48 的 375268（裸跑 5 条历史 WARN、不阻断）；默认重锚 414532 已提交 ohos-workload
   `71fe00c` 并随下一包生效 → 回传终端输出。
1. **应用内子窗（#49 主判点 1，MULTIWINDOW-M）**：装默认 kit 主 hap（AOT）→ 打开子窗样例页，按
   `app://subwindow/demo` 流程逐步操作：**create**（期望 id=344 档、120,160 720×480）→ page ready
   （`name=ohos_dotnet_subwindow drag=on`）→ **move 420,360** → **resize 900×600** → **close**（子窗消失）；
   再 `app://subwindow/open`（id=346 档）→ 点按（`OHOS_MAUI_SUB touch #`）与 swipe（`drag #` → 坐标跟随）；
   `hide` 期望如实 `Failed 801`（无公开 hide API，属预期不判失败）→ 回传每步壳 hilog + 主页面状态行 + 截图
   （create/move/resize/close 四态）。
2. **a11y 密码脱敏（#49 主判点 2，SEC-SCAN-4）**：进入含密码 `Entry` 的页面 →
   `sh tester-run.sh --kit-dir ./device-test-kit --a11y-probe`（或 `uitest` dump）→ 期望影子树/a11y dump 中
   密码节点文本为**等长圆点**、明文口令不出现，节点数/桥接照常（nodeCount 70 承 #47）→ 回传 `a11y/` 两文件
   或 dump + 截图；带读屏环境复跑朗读/焦点顺序/动作类。
3. **R2R/JIT 启动（承 #48 主判点，CG2-R2R）**：自建 JIT R2R 变体（rc.2 SDK + `crossgen2-packs-11.0.0-rc.2`
   folder feed + `-p:PublishReadyToRun=true`；详见交接 §3）→ 冷启 3 次：期望 **AMS→首帧 ≈0.71 s 档**（≤0.8 s；
   IL 对照 ~1.03 s）、in-proc present ≤350 ms、`canvas presented`、交互正常 → 回传冷启计时 + 截图 +
   `hello-maui-app.dll` 含 `RTR\0`（可选）。
4. **AOT 首帧省时（承 #48，AOT-STARTUP）**：装默认 kit 主 hap（AOT）→ 冷启 3 次：期望 **AMS→首帧
   ≈0.53 s 档**（≤0.6 s；旧 0.80 s）；`web overlays mounted on first use` 出现在首帧后；hybrid 装载照常
   （`web cmd: hybrid`→`hybrid assets`→`web serve`）→ 回传冷启计时 + hilog + 截图。
5. **帧率投票 60（承 #48，FPS48）**：另开一个持续重绘应用（干扰态）→ kit 主包动画页采样 ≥60 s：期望
   5s 窗稳态均值 **≥58 fps**（交付方 46.2→60.0）、无整段 30 窗、draw/pres 不变；无动画态 0 app 帧属预期
   → 回传 `FPH`/帧统计 + 截图。
6. **多窗 S（承 #48，MULTIWINDOW-S）**：2in1 拖拽最大化/分屏/恢复（或不拖拽直接最大化）：期望窗口
   尺寸跟随（`window size change: WxH free=…` + `[maui] window size WxH` + `canvas presented (WxH)`）；
   收窗/0×0 **保末帧**不白屏；a11y 自检 nodeCount 70、无新 fault → 回传最大化前后截图 + hilog +
   `surface state=` 行。
7. **FIXRR：interp R2R=0（承 #48）**：解释器轮（rc2b pack + rc.2 kit hap + `interp.txt=3`）冷启：
   期望 `canvas presented`、无 `SIGSEGV(NULL)`、Main→首帧与 IL 件同档（交付方 614 vs 609）→ 回传 hilog/截图/帧统计。
8. **FlyoutPage a11y 节点数（承 #47，FIX-A11YFLYOUT）**：装默认 kit 主 hap（AOT）→
   `sh tester-run.sh --kit-dir ./device-test-kit --a11y-probe`（或 `uitest` 点自检按钮）→ 期望
   `a11y/selfcheck.txt`：`accessibilityStatus: 1 (attached - expected)`、**nodeCount=70**（此前同路径 1）；
   带读屏环境复跑 T2/L1/N1/F2/E1 → 回传 `a11y/` 两文件 + 截图 + `summary a11y_*`。
9. **抢占/恢复/重放原文（承 #47，FIX-PREEMPT-RAW）**：加满 3 控件（A/B/C）后加 C/D/E（共 5 控件，
   **E 抢 A 槽**）→ Activate A → 抓 hilog：期望 **`[maui-capacity]`** 原文 `preempted: slot 0` /
   `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`（交付方一轮共 5 行导出）；活覆盖层 ≤4
   → 回传 hilog 原文 + `hybrid assets slot=` 行 + 截图/JSON。
10. **INTERP-DRAW2（承 #46）**：解释器轮出画稳定后统计：期望 interp **draw ≤10 ms/帧、稳态 60 fps**
    （14.4→9.4、33.9→60.1）；JIT/AOT 60 fps 不回归（JIT draw −15%）→ 回传帧统计（`FPH` 行）+ 截图 + hilog。
11. **FIX-A11YBUTTON（承 #46）**：有 web 控件（Home）与 no-web 变体两态点自检按钮：期望按钮在
    **左下角、覆盖层之上**可点（`[523,1622][607,1668]`）、点按出对话框 `status=1` → 回传 `uitest` dump/截图两态。
12. **自动释放（承 #45）**：加满 3 个 Web 控件 → **移除第 3 个**：期望 `web slot destroy: 2`、覆盖层消失；
    **再加回**：期望 `web slot create: 2` 重建、交互恢复 → 回传移除/重挂截图 + hilog。
13. **INTERP-RENDER（承 #45）**：解释器轮出画稳定后统计：期望 **≥30 fps（交付方复测 38–44）**、
    meas≈0 ms/帧、主线程 CPU 65.5–70.5%、无 `SIGSEGV(NULL)`；JIT/AOT 60 fps 不变 → 回传帧统计 + 截图 + hilog。
14. **动态槽 3 控件 + 第 5 槽（承 #44/#45）**：同页 3 控件并发出画/交互（`web slot create: 2`、容量
    `web capacity: 4`）；第 5 槽超容量：主动抢占→slot 0、Activate→恢复重放、活覆盖层 ≤4 → 回传截图 + hilog。
15. **AOT 默认 + FRAMEPACING（承 #44/#43）**：默认包冷启 → 期望 kit 根/逐 hap `runtime-mode.txt=aot`、
    无 libcoreclr/libclrjit、首帧 + 交互回归；present 聚合真实 **60.00 fps** → 回传截图 + hilog + 帧统计。
16. **rc.2 版本自述**：读包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary → 期望 SDK
    `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；无 rc.1 混装告警 → 回传自述原文 + summary。
17. **承 #42**：①JIT（自建 `--runtime-mode jit` 包或 ACL 域）：`jitfort rc=0` + 探针 `1=OK 2=OK` + 首帧；
    ②解释器：rc2b pack + rc.2 kit hap + `interp.txt=3` → `canvas presented`、无 `SIGSEGV(NULL)`；
    ③FIX-SLICERACE：JIT 8 轮 `race=0 pvnull=0 conc=0 unhandled=0`；④L6/SAMPLE-FIX/WX-PATCH2/P2c 同 #42 → 回传截图 + hilog。
18. **承 #41**：MULTI-OVERLAY-FULL（双 Hybrid 各自 invoke/消息；3–5 控件场景已覆盖）；DEVCOMPAT-DEFAULT（enforcing
    开箱可装）；INTERP-FIX（8 MB 栈 + 关写屏障）→ 回传截图 + hilog。
19. **承 #40–#35**：FIX-JSCALL（razor 页点 "Blazor click" 两次 → count 0→1→2）；FIX-BACKSIZE/FIX-BWVMount/FIX-DISMISS/
    FIX-WVP/FIX-HOME/FIX-ITOUCH；payload/a11y/像素；B2（`BLZ_BOOT`+`BLZ_RENDERED` 同 pid）；W9B/W9C/W9D/W10
    （无 MediaKit 属预期）→ 逐条截图/回传。
20. **承 #34/#33**：W6/W7/W8（套件自报行 **`[suite] checks=607 total=609 floor=589 assert=True`**）；
    Blazor A/B 双 hap 各装一次（`--blazor-probe`）；MAUI 主体（TabbedPage/W5、T13/N3/T21/T22）。
21. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60`
    → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全 → 回传 `mode-matrix/` 全目录 + 四个 `tester-report-*.tar.gz`。
22. **WebView 六项 + B1 razor（承 #32）**；**harmony 变体（AGC 就绪时）**：按卡逐条 / 同指纹重签 → 回传截图 + hilog +
    Map/LiveView/TTS/HUKS 证据。

## 3. 判定表（逐 Run 填）

| 态/项 | 判据 | 结论 |
|---|---|---|
| **应用内子窗（#49 主判点 1）** | `app://subwindow/demo` create id=344（120,160 720×480）→ move 420,360 → resize 900×600 → close；`open` 后 touch #57 / drag #51→269,259；hide 如实 Failed 801；close 后子窗消失 | #49 落地 |
| **主窗协同（#49 主判点 1 续）** | 主窗 HIDDEN/SHOWN → `subwindow suspended/resumed` + 挂起期命令抑制；主页面 60fps、无新 fault | #49 落地 |
| **a11y 密码脱敏（#49 主判点 2）** | 密码节点文本 = 等长圆点、明文不出现；节点数/桥接照常（70）；读屏环境实读同上 | #49 落地（离线，设备待验） |
| **R2R/JIT 启动（承 #48）** | R2R 件 AMS→首帧 ≈0.71 s（≤0.8 s；IL 1.03 s 对照）、in-proc ≤350 ms、`canvas presented`；`RTR\0` 在 | 承 #48 保持 |
| **AOT 首帧（承 #48）** | AOT AMS→首帧 ≈0.53 s（≤0.6 s）；`web overlays mounted on first use` 在首帧后；hybrid 照常 | 承 #48 保持 |
| **帧率投票 60（承 #48）** | 干扰态 5s 窗 ≥58 fps（46.2→60.0）、无 30 窗；draw/pres 不变 | 承 #48 保持 |
| **多窗 S（承 #48）** | 最大化后 `window size change`/`[maui] window size`/`canvas presented` 跟随（3120×1955）；收窗保末帧 | 承 #48 保持 |
| **FIXRR（承 #48）** | interp `canvas presented`、无 NULL 崩；首帧与 IL 同档（614 vs 609） | 承 #48 保持 |
| **a11y Flyout 节点数（承 #47）** | `status=1` + **nodeCount=70**（此前 1）；detail 恒发布、flyout 仅 presented 且保 detail | 承 #47 保持 |
| **抢占原文（承 #47）** | `[maui-capacity]` 原文：`preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`；活覆盖层 ≤4 | 承 #47 保持 |
| **INTERP-DRAW2（承 #46）** | interp draw ≤10 ms/帧、稳态 60 fps（33.9→60.1）；JIT draw −15%、fps 不变 | 承 #46 保持 |
| **FIX-A11YBUTTON（承 #46）** | 两态按钮左下角可达 `[523,1622][607,1668]`、点按出对话框 | 承 #46 保持 |
| **自动释放（承 #45）** | Remove C → `web slot destroy: 2` + 覆盖层消失；re-add → `web slot create: 2` + 交互恢复 | 承 #45 保持 |
| **INTERP-RENDER（承 #45）** | interp ≥30 fps（复测 38–44）+ meas≈0 + CPU −13pt；JIT/AOT 60 fps 不变 | 承 #45 保持 |
| **动态槽 3 控件并发（承 #44）** | 3 控件各自出画 + 交互回显（A/B/C）；`web slot create: 2` / `web capacity: 4` | 承 #44 保持 |
| **第 5 槽超容量（承 #45 已真机点验）** | 主动抢占→slot 0、Activate→恢复重放、活覆盖层 ≤4 | 承 #45 闭环 |
| **AOT 默认（承 #44/#43）** | `runtime-mode.txt=aot` + 3 `.so`/无 libcoreclr/libclrjit + 首帧/交互回归 | 承 #43 保持 |
| **发布域（2026-10-04 实测，交测口径）** | 发布形态 = **AOT**（release×AOT 正常）；release×JIT 自签 ~44 ms 崩 → 需华为发布 Profile + ACL/JIT 豁免 | 交测口径 |
| **FRAMEPACING（承 #44/#43）** | 真实呈现 60.00 fps（17.7 = 壳状态轮询伪影） | 承 #43 保持 |
| **门禁（#49）** | `[suite] checks=607 total=609 floor=589 assert=True`；导出 153/153；pixel 43 PASS | #49 基座 |
| **JIT 解锁（承 #42）** | 自建 jit 或 ACL 域：`jitfort rc=0` + 探针 `1=OK 2=OK` + 首帧 | 承 #42 保持 |
| **解释器首帧（承 #42）** | rc2b pack + rc.2 kit hap → `canvas presented`；无 `cppcrash`、无 `SIGSEGV(NULL)` | 承 #42 保持 |
| **FIX-SLICERACE（承 #42）** | JIT 冷启/重启循环 8 轮：`race=0 pvnull=0 conc=0 unhandled=0` + 首帧 | 承 #42 保持 |
| **L6 / LEGACY / SAMPLE-FIX / WX-PATCH2 / P2c（承 #42）** | JPEG 落盘/标题心跳；Toolbar 契约；`blzProbe`=`dotnet-ref ok`、计数 0→1→2；无 `ACCERR`；`module.json` skills | 承 #42 保持 |
| **MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX（承 #41）** | 双 Hybrid/per-slot invoke/z-order；enforcing 开箱可装；8 MB 栈 + 关写屏障 | 承 #41 保持 |
| **FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME / ITOUCH（承 #40–#37）** | count 0→1→2；Back 关抽屉；`.razor` 挂载；外点关；Hybrid 出画+bridge；Home 整页；注入命中 | 承 #40–#37 保持 |
| **payload / 像素 / a11y / AOT `-struct1`（承 #36）** | `payload-in-libs: running from …`；无 `Known`；`status=1`+nodeCount；`-struct1` 构建成立 | 承 #36 保持 |
| **B2 / W9 / W10（承 #35）** | 双标记齐；T14/T21/T8/T20/T19；AOT 入口行 | 承 #35 落地 |
| **rc.2 基线 + W6/W7/W8（承 #34）** | 版本自述；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6；套件 607/609 floor 589 | rc.2 线成立 |
| **Blazor A/B + 主体（承 #33）** | 默认/nocsp 双标记；TabbedPage/W5 | #33 保持 |
| **JIT / XWE / AOT / 解释器 / harmony / runtime_mode** | 各态判据同前；AOT 为默认、JIT 为形态保留（R2R 为 JIT 加速项） | 各判定成立 |
| **WebView / B1 razor（承 #32）** | 9 项卡 + B1 两标记 + JS 往返 | 按 #32 判据 |

> 失败 Run 保留报告 tar；无入口项登记「未测（本包无入口/无 hdc）」，不判失败。

## 4. 注意

- 包内 hap 为自签：**9568257 / 9568344 属预期**，先重签（需华为调试证书 + Profile 绑 UDID）；**预签件已刷新至 #49**——可直接
  `hdc install -r` 直装（非 tester UDID 仍 `9568344`，请回传 UDID 代签）；**Blazor 双变体同名（`com.example.opendotnet`），装前卸载**；
  两变体均无 INTERNET（重签保持）。
- **子窗口径（#49）**：M 为应用内子窗（壳侧 `createSubWindowWithOptions` + ArkUI 自绘 named-route + 宿主
  command/event 双导出）；管理侧仍是单 surface/renderer，**子窗内容不是第二 MAUI 视觉树**、也不进 MAUI a11y 树；
  `hide` 无公开 API 如实 `Failed 801` 属预期；多子窗上限/软键盘/焦点/z-order/手机域未测；L（真 OpenWindow）余量见
  `2026-10-05-ohos-multiwindow-m.md` 末节与平台限制 E2。
- **密码脱敏口径（#49）**：修复在 a11y 影子树发布侧（密码节点只发等长圆点），不改变绘制；离线红/绿负控通过、
  **设备未验证**——复测以设备 dump 为准；读屏可达性取决于服务启用，不判失败。
- **R2R 口径（承 #48）**：Crossgen2 包作**本地 folder feed** + `RestoreConfigFile`（消除 NU1100）；只用于 JIT；R2R 件
  +11 MB；interp 抑制（FIXRR：`interp=3` 置 `DOTNET_ReadyToRun=0`，与 runtime 隐式行为同效）。R2R 不是 kit 内资产，
  需自建 jit 变体（debug 域）或在 ACL 域构建。
- **AOT 首帧口径（承 #48）**：CEF 初始化 ~240 ms 从 attach→surface 段移出（覆盖层首用才挂载 + 宿主跳过相同 app-context
  surface 重放）；首帧后 3–17 ms 才挂覆盖层属预期；hybrid/Blazor 注册路径不变。JIT 死锁修复的代价是相同快照不再重放，
  不同 app-context 仍重放（宿主 `set_app_context`）。
- **FPS48 口径（承 #48）**：投票在 XComponent 注册期常驻（可见即 60）；无动画时 0 app 帧属门控预期；判定以
  `FPH` 稳态窗 + 交互回归为准；idle 动态撤票为后续项（不判失败）。
- **多窗 S 口径（承 #48）**：S 项仅形态响应（`supportWindowModes` + 尺寸/自由模式订阅 + surface 活性重排）；
  `freeWindowModeChange`/split 真形态与手机域未测。
- **a11y Flyout 口径（承 #47）**：`PushChildren` 补 `FlyoutPage.Detail`（恒入树）与 `FlyoutPage.Flyout`
  （仅 `IsPresented`）；真机自检 nodeCount=70（此前 1）；无读屏客户端时朗读/焦点顺序/动作类不可测。
- **抢占原文口径（承 #47）**：壳只导出自上次轮询的**新增段**（12×3 s 轮询节奏；trim 时整文件回退）；
  `[maui-capacity]` 行 = `overlay preempted/restored/replay` 原文；512K 环噪声大时按「未测」登记。
- **INTERP-DRAW2 口径（承 #46）**：面外剔除只做 surface 级（ScrollView 子树仍随 `shifted` 走）；interp 已触
  60 Hz 上界；判定以 `FPH` 稳态窗 + 交互回归为准。
- **自动释放/动态槽口径（承 #45/#44）**：MAX/HOT 默认 4/2（clamp 2..8）；热对 [0,1] 常驻、释放即拆、重挂重放；
  容量下调按 suspend 抢占（旧 2 槽壳安全降级）；env 不可按应用注入；N=8 实测 >4 不挂（安全上限 4）。
- **INTERP-RENDER 口径（承 #45）**：静态帧不再每帧全树 Measure/Arrange；判定以 `FPH` 稳态窗 + 交互回归为准。
- **AOT 默认口径（#43 起）**：5 MAUI hap 全 NativeAOT（`runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libhostfxr/libclrjit）；
  JIT 保形态（`--runtime-mode jit` 自建；debug 域 JITFORT 默认；release 域需 AGC ACL
  `ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`（2in1/平板）或厂商豁免——手机只发 AOT）；interp 实验（独立 pack）。
- **发布域口径（2026-10-04 实测）**：**发布形态请用 AOT**；release×JIT 自签件 ~44 ms 崩
  （`coreclr_initialize`，`SIGSEGV(SEGV_ACCERR)`）→ 需**华为发布 Profile + ACL/JIT 豁免**后复验；**覆盖装先卸载**
  （release↔debug `9568286`）、**过期 p7b=`9568329`**（`2026-10-04-ohos-release-domain-and-pidloss.md`）。
- **启动/帧率基线（#48 新基线，2026-10-05）**：三路径冷启（AMS→首帧）**AOT 534 ms / JIT R2R 710 ms / JIT IL 1031 ms**；
  interp 首帧与 IL 同档（614）；干扰态 60.0 fps（清净 60.1）、interp 稳态 60.1 fps（INTERP-DRAW2）；旧基线
  （#45 切片 1.56–1.69 s、interp 38–44 fps）**已被 #48 取代**（数字以本页与 release 为准）。
- **JIT/interp 浸泡（SOAK-JI，2026-10-05）**：JIT 45 min（+21.6 MB、60.1 fps、0 崩/0 冻结/0 失 pid）、interp 45 min
  （rc2b+优化件、34.3 fps 镜像口径、0 崩）→ 与 AOT soak2 对照背书成立（`2026-10-04-ohos-jit-interp-soak.md`）。
- **解释器口径**：用 **rc2b pack** + **rc.2 kit hap**（重签）；勿用 rc.1 托管 CoreLib 的旧测试件（QCall ABI 错配会
  `SIGSEGV(NULL)@coreclr_initialize`，属测试件问题、非 pack 缺陷）。`interp.txt=1|2` 混合模式保留默认。
- **AOT pack 结构修复**：`FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分（静态 `.a` 保留 dlopen shim、共享 `.so` 仍静态链 OpenSSL；
  sdk 构建在布局与 nupkg 两处校验）——**当前资产 = `-struct1`**（asset 607541145），后续 runtime pack 无需再重打。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递（`skills[].uris` 本机产物已可验）；②镜像扩展分支
  `m-web-mirror d47f1fcb3b` 尚未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过（未定位）；
  ④stock JIT 长跑/后台唤醒未覆盖（JIT 现非默认）；⑤解释器混合模式保留默认；⑥Crossgen2 包未本机重编；⑦L（真 OpenWindow
  多窗：per-window renderer/surface/输入/a11y）未做。其余相关项登记「未测（在途）」不判失败。
- **rc.2 相关（2026-10-04 复核：WAIT）**：官方 rc.2 **未发布**；ohos-workload 已加监测 `rc2-watch`（`1d39eb7`；
  `scripts/rc2-official-watch.sh` + `.github/workflows/rc2-watch.yml`，周一 03:17 UTC + dispatch；状态
  `docs/rc2-official-watch.md`）；触发（exit 10）后按 `docs/plans/2026-09-30-rc2-mainline-adoption.md` §8 换 pin、删
  dnceng feed step；触发前 restore 仍走 dnceng `dotnet11` feed；rc.1 回滚线保留；应用侧构建请同步 rc.2 线（同文 §4/§5）。
- **hilog 缓冲（探针误报防护）**：512K 环在噪声大时只保留 ≈4–5 s（`--blazor-probe` 曾丢 `BLZ_BOOT` 报 `boot=no`）；临时
  `hilog -G 16M -t app,core` 重跑（**跑完还原 512K**）。另注意**状态文件伪影**：`dotnet-status.txt`/壳轮询可能输出上一轮
  残留行——**以本轮时序内状态为准**（抢占原文导出亦按本轮新增段判读）。
- **本机直测（交付方）**：设备已可测（hdc 无线 `127.0.0.1:35111` + SDK 自签 + AOT/JIT（含 R2R）/解释器三路径 + 子窗流程）；AOT 默认在
  enforcing 镜像开箱可装（DEVCOMPAT-DEFAULT，承 #41）。
- 所有数字 = **kit #49 发布实测（以 release「## Integrity（kit #49）」与随包校验为准）**：tar **67,888,851 / `477974bb…`**、
  树 `8d03cb4c…`、sidecar `3803b3db…`、`SHA256SUMS` 18 项 / 1,600 B / `b142639d…`；
  #48 = tar 67,735,148 / `5c22704f…`、#47 = 67,706,719 / `3d6bb58b…`、#46 = 67,708,823 / `c7c11814…`、#45 = 67,695,181 /
  `ca48a93c…`（对照）；tester-run v14 = 140,197 / `a174fcd0…` 仅作对照；
  bundle = `workload-1.0.0-preview.28` **73,085,186 / `7d06e781…`**（三处同步；dist sums `443061e7…`（212 B）；sdkrc2 合并
  sums 1,960 B / `4c1ec616…`；sdk 锚 **`7abaf8132f`**）；dtk **612922031** / latest **612923086**（kit tar/边车 asset
  **612922031**/**612922832**、latest **612923086**/**612923769**；bundle 三处 preview.28 **612918212**/**612919038**、
  latest **612919415**/**612920711**、sdkrc2 **612921037**/**612921767**；预签 **612929512**/**612930421**；
  interp pack rc2b asset **606999003**；AOT `-struct1` asset **607541145**；Crossgen2 rc.2 asset **RA_kwDOT39XK84kdPmt**）；
  CI **5/5** @ pin `e0803bedad`（interaction `37321721695` / pixel `37321721683` / host-export `37321721786` /
  ridgraph `37321722030` / markdownlint `37321721810`）+ sdk `ohos-install-tests` @ `7abaf8132f`
  run `37331391778`。
- 细判（TTS/HUKS/自绘深度/权限/Share-Scan）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2 与
  `…kit29/kit28/kit27/kit26/kit25`；无障碍逐项：`docs/plans/2026-09-27-ohos-accessibility-device-verification.md`
  （含 N4）；#49 细节：`2026-10-05-ohos-multiwindow-m.md`、`…security-scan-4.md`、`…mw4-consolidate.md` 与
  `2026-10-05-ohos-tester-handoff-kit49.md`；#48 细节：`2026-10-05-ohos-cg2-r2r.md`、`…aot-startup.md`、
  `…fps48.md`、`…fixrr-consolidate.md` 与 `…tester-handoff-kit48.md`；#47 细节：
  `2026-10-05-ohos-a11yflyout-preempt-export.md`；#46 细节：
  `2026-10-04-ohos-interp-draw.md`、`2026-10-04-ohos-a11y-and-capacity.md`；#45 细节：
  `2026-10-04-ohos-interp-render.md`、`2026-10-04-ohos-a11y-and-capacity.md`。
