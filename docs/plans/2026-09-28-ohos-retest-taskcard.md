# 复测任务单（一页）：kit #50 一轮设备判定（**真多窗 MULTIWINDOW-L（M1–M4 + SEC-SCAN-5a/5b/5c）** + polish-49 + 承 #49 MULTIWINDOW-M / a11y 密码脱敏 + 承 #48 R2R/JIT 启动 1031→710 ms + AOT 首帧 796→534 ms + 帧率投票 60 + 多窗 S + FIXRR + 承 #47 a11y Flyout 1→70 / 抢占原文 + 承 #46/#45 全量）（2026-10-06）

> 目标：一轮拿全 **#50 主判点**：①**真多窗 MULTIWINDOW-L（M1–M4）**——宿主每窗 XComponent surface 注册表
> （window-id claim/release/route；registry 84/84）+ 切片 per-window `OpenHarmonyWindowSurface`/`Renderer` +
> 带窗事件路由（`RouteSurface/RouteTouch/RouteFrame`）+ 子窗挂 XComponent 携 managed surface id 得**第二 MAUI
> 视觉树**（真机 `sub-1` 720×480 `first frame=True`、触摸按窗、close 回收、reopen 同 id、churn ×20 无 WMS
> 残留）+ 每窗焦点/生命周期（壳 ACTIVE/INACTIVE → `IWindow.Activated/Deactivated/Stopped/Resumed`；Home→
> suspended→`aa start`→resumed ×10 每轮 1/1）+ 每窗 a11y 分区（主 provider 零变化、子窗影子帧本地保持）+
> per-window pinch（`ohos_host_notify_window_pinch`→该窗 renderer；导出 156→**157**）；双窗稳态 **60.0/60.0
> fps**、40 min 长稳（RSS 净 −34 MB）、JIT 与 AOT 各过轮；
> ②**polish-49**——建窗 `ParseSubWindowOptions` E=0、close WARN 平台内部、Home 焦点丢失链 suspend；
> ③**SEC-SCAN-5a/5b/5c**——unregisterXComponent 失败闭合 / window-id 校验失败闭合 / 跨窗文本泄漏修复
> （反转隔离 pin）；**人工卡 = 子窗 IME 实敲**（uitest 无子窗 XComponent/多点注入面）；
> **降级声明（明示，不判失败）**：子窗 a11y provider、子窗 ArkWeb 第二宿主、平台级多子窗上限（应用级 N=1）、
> IME 人工卡、SEC-5c B–F 报告项。
> + **承 #49**：MULTIWINDOW-M（`app://subwindow/demo` create/move/resize/close + 主窗协同）与 SEC-SCAN-4
> （a11y 密码脱敏：影子树等长圆点、离线红/绿负控、设备待验）
> + **承 #48** 的 **R2R/JIT 启动**（CG2-R2R：JIT 冷启 **1031→710 ms**、in-proc 575→307；interp R2R=0 FIXRR）、
> **AOT 首帧**（796→534 ms、attach→surface 239→13）、**帧率投票 60**（46.2→60.0 fps）、**多窗 S**（2in1
> 2090×1394→3120×1955）
> + **承 #47** FIX-A11YFLYOUT（`--a11y-probe` **nodeCount 1→70**）与 FIX-PREEMPT-RAW（`[maui-capacity]` 抢占/恢复/重放原文）
> + **承 #46** INTERP-DRAW2（interp draw 14.4→9.4 ms、33.9→60.1 fps、每帧 CPU −27%）与 FIX-A11YBUTTON
> + **承 #45** 自动释放（Remove→`web slot destroy`→re-add→`web slot create`+交互恢复）与 INTERP-RENDER
> + **承 #44/#43** 动态槽（MAX/HOT 4/2 + 3 控件并发 + 第 5 槽 LRU）与默认 AOT、FRAMEPACING（60.00 fps）
> + **承 #42** JIT 解锁（JITFORT）/解释器 rc2b/FIX-SLICERACE
> + **承 #41–#35** MULTI-OVERLAY-FULL / DEVCOMPAT / FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME /
> ITOUCH / payload / a11y / 像素 / B2 / W9-W10 与 **承 #34/#33** rc.2 版本自述、W6/W7/W8、Blazor 双 hap A/B。
> 执行入口 = `tester-run.sh`（版本/大小/摘要**以包内 `SCRIPT_VERSION` 与 release 资产页为准**；承 **v14**，含
> `--blazor-probe` / `--mode-matrix` / `--a11y-probe`）。
> 判定树与细节：`docs/plans/2026-10-06-ohos-tester-handoff-kit50.md`（逐项勾选 + §3 rc.2/AOT/Crossgen2 + §4 本机直测）、
> `docs/plans/2026-10-06-ohos-multiwindow-l-m4.md`（逐项表 + 降级 + **人工卡**）、`…-m2-exit.md`/`-m3.md`/
> `…-l-consolidate.md`（M1–M4 收口）、`docs/plans/2026-10-06-ohos-security-scan-5c.md`（A 修复 + B–F 报告）、
> `…handoff-kit49.md`、`…handoff-kit48.md`、`…interp-draw.md`、`…a11y-and-capacity.md`、`…jit-interp-soak.md`、
> `…interp-render.md`、`…kit45`/`…kit44`/`…framepacing.md`/`…jitfort-enable.md`。
> 本页只给「取件 → 执行 → 回传 → 判定」。**kit #50 发布实测（release「## Integrity（kit #50）」；发布已完成，
> 一切数字以 release 与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准）**：tar **68,264,136 B / `d70dc786…`**、
> 树 **`b4b5055c…`**、sidecar **`2ffb3b6a…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `98fd0dd2…`**
> （#49 = tar 67,888,851 / `477974bb…`、#48 = 67,735,148 / `5c22704f…`、#47 = 67,706,719 / `3d6bb58b…` 对照）。
> **预签已刷新至 #50**（7 hap；**68,157,557 / `028d29f4…`**，asset **615517779**；sidecar 88 B /
> `02397318…`，asset **615518466**）；非 tester UDID 设备请回传 UDID 代签。
>
> **运行时口径（kit #43 起）**：**默认 AOT**；JIT 需 ACL/豁免（release/生产域 AGC ACL 或厂商豁免；debug/内测签名域免；
> 亦可用 `--runtime-mode jit` 自建，加 R2R 见 §2 步骤 7）；interp 为实验路径（独立 pack，不随主包）。
> **发布域（2026-10-04 实测）**：**发布形态请用 AOT**（release×AOT 正常出画）；**release×JIT 自签件 ~44 ms 崩**
> （`coreclr_initialize`，`SIGSEGV(SEGV_ACCERR)`）——需**华为发布 Profile + ACL/JIT 豁免**后复验；**覆盖装先卸载**
> （release↔debug `9568286`）、**过期 p7b=`9568329`**；**rc.2 监测**：官方 rc.2 **未发布（WAIT）**，
> ohos-workload `rc2-watch`（`1d39eb7`）触发后按清单换 pin。
> **a11y/IME 口径**：交付方沙箱无读屏客户端（AMS `accessible=0`/client=0），nodeCount=70 为壳自检读数、密码脱敏为
> 离线红/绿负控、子窗 a11y 为降级；朗读/焦点顺序/动作类与密码节点实读**需测试方带 ScreenReader 环境**复跑；
> **子窗 IME 实敲 = 人工卡**（uitest `uiInput` 无子窗 XComponent/多点注入面，步骤见 `-l-m4.md` 末节）。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #50，2026-10-06） | **68,264,136** | **`d70dc786…`**（sidecar `2ffb3b6a…`；树 `b4b5055c…`；`SHA256SUMS` 18 项 / 1,600 B / `98fd0dd2…`；dtk asset **615507454** / latest **615508545**） | **7 hap**（5 MAUI 全 AOT：`runtime-mode.txt=aot`、3 `.so`（app.so **19,364,624** + host **330,656** + `libc++_shared.so` 1,267,392）、无 libcoreclr/libhostfxr/libclrjit；abc **436,808（`289a5e5d…`）**/24,324、宿主 **330,656（`fdeb94eb…`）**、导出 **157**）+ **2 个 Blazor 对照 hap**（bundle `com.example.opendotnet`，无 INTERNET）+ `verify-kit.sh`（默认期望 436,808 → 0 FAIL/0 WARN）+ 文档 + `runtime-mode.txt=aot` |
| `preSigned-haps.tar.gz`（**预签直装**；#34 起加发；**本波已刷新至 #50**） | **68,157,557**（asset **615517779**；sidecar 88 B / `02397318…`，asset **615518466**；树 `440a2cb5…`） | **`028d29f4…`** | 7 hap = **kit #50 原名件**，按 tester UDID `60CF7B27…` 预签：`sha256sum -c SHA256SUMS` → `hdc install -r` **直装**；非本 UDID 设备仍 `9568344` |
| AOT 复测取件（`aot-haps*`；rc.2 pack 已重出 `-struct1`：结构修复 + shim） | **18,185,012**（`aot-haps-v3-rc2.tar.gz`；本批未动；dtk 599996905） | **`3d24f716…`** | AOT hap（含 UIPage 出画修复）；rc.2 设备/本机构建用 **`-struct1`**（`…rc.2.26451.112-struct1.nupkg` 28,905,116 / `09345f95…`，asset 607541145；sdk fetch 现锚）；`-r2`（28,904,657 / `542058cf…`，asset 601289590）与原包（`46d221f2…`）仅历史、不再钉锚；装前重签 |
| **Crossgen2 rc.2 包（承 #48；JIT R2R）** | **43,792,647**（`crossgen2-packs-11.0.0-rc.2`；asset `RA_kwDOT39XK84kdPmt`） | **`6bb8a375…`** | JIT 自建包 `-p:PublishReadyToRun=true` 的 folder feed（NU1100 消除）；含 `crossgen2` apphost + `ILCompiler.*` + openharmony overlay；与 runtime-ohos release 同字节 |
| **解释器 pack** `ohos-interpreter-pack-rc2b.tar.gz` | **2,410,595**（asset **606999003**；README **606999004**；sidecar **606999001**） | **`5974430509…`** | **INTERP-NULL 修复 + WX-PATCH2**；配 #42+ 宿主（JITFORT + 8 MB 栈 + interp R2R=0）使用；rc2 旧件（605924427）/rc.1 旧件（2,419,988 / `a10699b3…`）保留作对照 |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`） |
| `tester-run.sh`（随包） | 以包内为准（承 v14 = 140,197 / `a174fcd0…`） | 以包内为准 | 执行器；`--blazor-probe`、`--mode-matrix`、`--a11y-probe` 承 #33 |

包内 7 hap（kit #50 发布实测，`SHA256SUMS` 18 项 / 1,600 B / `98fd0dd2…`）：`hello-maui-app.hap` **22,580,658 / `2b8d39ba…`**（AOT）、`…-unsigned` **22,279,282 / `60b559c3…`**、`…-permissions` **22,580,648 / `7a2b9913…`**、`…-api20` **22,580,647 / `ddf54f31…`**、`…-api20-permissions` **22,580,653 / `bcd0afbf…`**、Blazor 默认 **27,218,497 / `769c81f1…`**（未签名）、`-nocsp` **27,218,194 / `0761973e…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。

**预签直装捷径（可选）**：`sha256sum -c SHA256SUMS` 后 `hdc install -r` 直装，**§2 的「先重签」可跳过**（同 bundle 换件仍先卸载）；预签件已刷新至 #50，可直接用于本轮。完整一轮 / 源码复测请用 `device-test-kit.tar.gz`。

## 2. 执行顺序（每步「期望 → 回传」）

0. **校验 kit**：包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（#50 默认期望已重锚 **436,808**，裸跑即绿；
   深度断言逐 hap；5 MAUI hap 期望 `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；abc 期望 **436,808/24,324**）→ 回传终端输出。
1. **真多窗（#50 主判点 1，M1–M4）**：装默认 kit 主 hap（AOT）→ `aa start -U app://subwindow/open`（或包内样例入口）→
   等 `windows=2`：期望子窗 **`first frame=True`（第二 MAUI 视觉树 720×480）**、子窗内点按/拖动只影响子窗、close 后子窗
   消失、reopen 同 id → 回传每步 hilog（`windows=`/`first frame`/`subwindow closed`）+ 双窗截图（主/子各一）。
2. **每窗帧率/长稳（主判点 1 续）**：双窗持续出帧 ≥60 s；churn ×10–20；可加 40 min soak：期望主/子稳态
   **60/60 fps**（冻结阈值：主 ≥50 / 子 ≥40 / 主窗较单窗退化 ≤10% / 连续 >33 ms×3=0）、churn 无 WMS 残留、pid 恒定、
   soak 无 fault/RSS 单调增长 → 回传 `WindowFrameStats` 每窗 5s 行 + pid/fault 采样 + 截图。
3. **每窗焦点/生命周期（主判点 2）**：Home/最小化 → 等 suspended → `aa start` 恢复；重复 ≥10 次：期望
   `subwindow suspended`→`resumed` 每轮 1/1、焦点只在活动窗、主窗进程生命周期零变化 → 回传 hilog 事件序 + 每轮计数。
4. **每窗 a11y 分区（主判点 3）**：主窗 `sh tester-run.sh --kit-dir ./device-test-kit --a11y-probe`；子窗渲染中复跑：
   期望主 provider 路径**零变化**（status=1、nodeCount 70 档）、子窗帧本地保持（status 行 `keeps its shadow frame
   locally (no per-window provider yet …)`）、主窗树不被覆盖 → 回传 `a11y/` 两文件或 dump + 截图 + `summary a11y_*`。
5. **pinch 按窗（主判点 4）**：有注入面/多指设备在子窗内 pinch；交付方沙箱无多点注入面：期望缩放只作用于该窗
   renderer（`ohos_host_notify_window_pinch`→`WindowPinch`）、主窗/未知/空 id 被拒 → 有注入面回传 hilog/截图；
   否则登记「未测（无注入面）」并以离线 pin/单测（12+14 checks）背书。
6. **子窗 IME 实敲（人工卡，不阻塞）**：解锁设备 → open 子窗 → 鼠标/触摸点子窗 Entry → 实敲 `hello-child` + 回车 →
   切主窗敲字 → close/reopen：期望键盘在子窗、文本只在子窗、跨窗事件=0、close 键盘收起、reopen Entry 回 `seed`
   → 按 `-l-m4.md` 末节 4 行格式回传（设备/包/时间 + 每步 OK/FAIL + ≤20 行 hilog + 2 截图；失败附 `hilog -x` 与 `uitest dumpLayout`）。
7. **R2R/JIT 启动（承 #48，CG2-R2R）**：自建 JIT R2R 变体（rc.2 SDK + `crossgen2-packs-11.0.0-rc.2` folder feed +
   `-p:PublishReadyToRun=true`；详见交接 §3）→ 冷启 3 次：期望 **AMS→首帧 ≈0.71 s 档**（≤0.8 s；IL 对照 ~1.03 s）、
   in-proc present ≤350 ms、`canvas presented`、交互正常 → 回传冷启计时 + 截图 + `hello-maui-app.dll` 含 `RTR\0`（可选）。
8. **AOT 首帧省时（承 #48，AOT-STARTUP）**：装默认 kit 主 hap（AOT）→ 冷启 3 次：期望 **AMS→首帧 ≈0.53 s 档**
   （≤0.6 s；旧 0.80 s）；`web overlays mounted on first use` 出现在首帧后；hybrid 装载照常 → 回传冷启计时 + hilog + 截图。
9. **帧率投票 60（承 #48，FPS48）**：另开一个持续重绘应用（干扰态）→ kit 主包动画页采样 ≥60 s：期望 5s 窗稳态均值
   **≥58 fps**（交付方 46.2→60.0）、无整段 30 窗、draw/pres 不变；无动画态 0 app 帧属预期 → 回传 `FPH`/帧统计 + 截图。
10. **多窗 S（承 #48，MULTIWINDOW-S）**：2in1 拖拽最大化/分屏/恢复（或不拖拽直接最大化）：期望窗口尺寸跟随
    （`window size change: WxH free=…` + `[maui] window size WxH` + `canvas presented (WxH)`）；收窗/0×0 **保末帧**不白屏；
    a11y 自检 nodeCount 70、无新 fault → 回传最大化前后截图 + hilog + `surface state=` 行。
11. **FIXRR：interp R2R=0（承 #48）**：解释器轮（rc2b pack + rc.2 kit hap + `interp.txt=3`）冷启：期望 `canvas presented`、
    无 `SIGSEGV(NULL)`、Main→首帧与 IL 件同档（交付方 614 vs 609）→ 回传 hilog/截图/帧统计。
12. **承 #49：MULTIWINDOW-M**：装默认 kit 主 hap（AOT）→ `app://subwindow/demo` create（id=344 档 120,160 720×480）→
    move 420,360 → resize 900×600 → close；`hide` 如实 `Failed 801`；再 `app://subwindow/open` 点按/swipe → 回传每步
    hilog + 状态行 + 四态截图（L 主路径按步骤 1 判；M 流程作为回归）。
13. **承 #49：a11y 密码脱敏（SEC-SCAN-4）**：含密码 `Entry` 页面 → `--a11y-probe`/dump：期望密码节点文本为等长圆点、
    明文不出现、节点数/桥接照常 → 回传 `a11y/` 两文件或 dump + 截图；带读屏环境复跑朗读/焦点顺序/动作类。
14. **FlyoutPage a11y 节点数（承 #47）**：`--a11y-probe`（或 `uitest` 点 A11Y 自检按钮）：`accessibilityStatus: 1`、
    **nodeCount=70**（此前 1）→ 回传 `a11y/` 两文件 + 截图 + `summary a11y_*`。
15. **抢占/恢复/重放原文（承 #47）**：加满 3 控件后加 C/D/E（E 抢 A 槽）→ Activate A → 抓 hilog：`[maui-capacity]` 原文
    `preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`；活覆盖层 ≤4 → 回传 hilog 原文 + JSON/截图。
16. **INTERP-DRAW2 / FIX-A11YBUTTON（承 #46）**：interp draw ≤10 ms/帧、稳态 60 fps；两态点自检按钮（左下角可达
    `[523,1622][607,1668]`、点按出对话框 `status=1`）→ 回传 `FPH` + 截图 + hilog。
17. **自动释放 / INTERP-RENDER（承 #45）**：加满 3 控件 → 移除第 3 个 → 再加回：`web slot destroy: 2` → `web slot create: 2`
    + 交互恢复；interp ≥30 fps、meas≈0、CPU −13pt → 回传截图 + hilog + `FPH`。
18. **动态槽 3 控件 + 第 5 槽（承 #44/#45）**：3 控件并发出画/交互（`web slot create: 2`、`web capacity: 4`）；第 5 槽
    超容量：主动抢占→slot 0、Activate→恢复重放、活覆盖层 ≤4 → 回传截图 + hilog。
19. **AOT 默认 + FRAMEPACING（承 #44/#43）**：默认包冷启 → `runtime-mode.txt=aot`、无 libcoreclr/libclrjit、首帧/交互
    回归；present 聚合真实 **60.00 fps** → 回传截图 + hilog + 帧统计。
20. **rc.2 版本自述**：读包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary → SDK `11.0.100-rc.2.26451.112` /
    workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；无 rc.1 混装告警 → 回传自述原文 + summary。
21. **承 #42**：①JIT（自建 `--runtime-mode jit` 包或 ACL 域）：`jitfort rc=0` + 探针 `1=OK 2=OK` + 首帧；②解释器：
    rc2b pack + rc.2 kit hap + `interp.txt=3` → `canvas presented`、无 `SIGSEGV(NULL)`；③FIX-SLICERACE：JIT 8 轮
    `race=0 pvnull=0 conc=0 unhandled=0`；④L6/SAMPLE-FIX/WX-PATCH2/P2c 同 #42 → 回传截图 + hilog。
22. **承 #41**：MULTI-OVERLAY-FULL（双 Hybrid 各自 invoke/消息；3–5 控件场景已覆盖）；DEVCOMPAT-DEFAULT（enforcing 开箱可装）；
    INTERP-FIX（8 MB 栈 + 关写屏障）→ 回传截图 + hilog。
23. **承 #40–#35**：FIX-JSCALL（razor 页点 "Blazor click" 两次 → count 0→1→2）；FIX-BACKSIZE/FIX-BWVMount/FIX-DISMISS/
    FIX-WVP/FIX-HOME/FIX-ITOUCH；payload/a11y/像素；B2（`BLZ_BOOT`+`BLZ_RENDERED` 同 pid）；W9B/W9C/W9D/W10
    （无 MediaKit 属预期）→ 逐条截图/回传。
24. **承 #34/#33**：W6/W7/W8（套件自报行 **`[suite] checks=661 total=663 floor=643 assert=True`**）；Blazor A/B 双 hap 各装
    一次（`--blazor-probe`）；MAUI 主体（TabbedPage/W5、T13/N3/T21/T22）。
25. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60`
    → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全 → 回传 `mode-matrix/` 全目录 + 四个 `tester-report-*.tar.gz`。
26. **WebView 六项 + B1 razor（承 #32）**；**harmony 变体（AGC 就绪时）**：按卡逐条 / 同指纹重签 → 回传截图 + hilog +
    Map/LiveView/TTS/HUKS 证据。

## 3. 判定表（逐 Run 填）

| 态/项 | 判据 | 结论 |
|---|---|---|
| **真多窗（#50 主判点 1）** | `app://subwindow/open` → `windows=2` + 子窗 `first frame=True`（720×480 第二 MAUI 视觉树）+ 触摸按窗 + close/reopen 同 id + churn 无残留 | #50 落地 |
| **每窗帧率/长稳（主判点 1 续）** | 主/子稳态 60/60 fps（主 ≥50/子 ≥40/退化 ≤10%/长帧 0）；soak 0 fault、RSS 无单调增长 | #50 落地 |
| **每窗焦点/生命周期（#50 主判点 2）** | Home→`subwindow suspended`→`aa start`→`resumed` ×10 每轮 1/1；焦点只在活动窗 | #50 落地 |
| **每窗 a11y 分区（#50 主判点 3）** | 主 provider 零变化（status=1、nodeCount 70 档）+ 子窗帧本地保持、不覆盖主窗 | #50 落地（子窗 provider 降级） |
| **pinch 按窗（#50 主判点 4）** | 缩放只作用于该窗 renderer；主窗/未知/空 id 被拒（离线 pin；真机注入面受限） | #50 落地（无注入面=未测） |
| **子窗 IME 实敲（#50 人工卡）** | 键盘在子窗、文本只在子窗、跨窗事件=0、close 收起、reopen 回 `seed` | 人工判定（不阻塞） |
| **polish-49（#50）** | 建窗 E=0；close WARN 平台内部；Home 焦点丢失链 suspend 可见 | #50 落地 |
| **SEC-5a/5b/5c（#50）** | 非主窗不改写主窗文本/输入；unregister/窗口 id 失败闭合；反转隔离 pin 在 | #50 落地（离线） |
| **承 #49：MULTIWINDOW-M / SEC-SCAN-4** | `app://subwindow/demo` create/move/resize/close；hide 如实 Failed 801；密码节点=等长圆点、明文不出现 | 承 #49（密码脱敏设备待验） |
| **R2R/JIT 启动（承 #48）** | R2R 件 AMS→首帧 ≈0.71 s（≤0.8 s；IL 1.03 s 对照）、in-proc ≤350 ms、`RTR\0` 在 | 承 #48 保持 |
| **AOT 首帧（承 #48）** | AOT AMS→首帧 ≈0.53 s（≤0.6 s）；`web overlays mounted on first use` 在首帧后 | 承 #48 保持 |
| **帧率投票 60（承 #48）** | 干扰态 5s 窗 ≥58 fps（46.2→60.0）、无 30 窗 | 承 #48 保持 |
| **多窗 S（承 #48）** | 最大化后尺寸跟随（3120×1955）；收窗保末帧 | 承 #48 保持 |
| **FIXRR（承 #48）** | interp `canvas presented`、无 NULL 崩；首帧与 IL 同档 | 承 #48 保持 |
| **a11y Flyout / 抢占原文（承 #47）** | nodeCount=70；`[maui-capacity]` 四行原文；活覆盖层 ≤4 | 承 #47 保持 |
| **INTERP-DRAW2 / FIX-A11YBUTTON（承 #46）** | interp draw ≤10 ms、60 fps；按钮两态可达 | 承 #46 保持 |
| **自动释放 / INTERP-RENDER（承 #45）** | `web slot destroy: 2` → `web slot create: 2`；interp ≥30 fps、meas≈0 | 承 #45 保持 |
| **动态槽 / 第 5 槽（承 #44/#45）** | 3 控件并发；抢占→slot 0、Activate→恢复重放 | 承 #44/#45 闭环 |
| **AOT 默认 / FRAMEPACING（承 #44/#43）** | `runtime-mode.txt=aot` + 3 `.so`/无 JIT 库；真实 60.00 fps | 承 #43 保持 |
| **门禁（#50）** | `[suite] checks=661 total=663 floor=643 assert=True`；导出 157/157；verify-kit 0 FAIL/0 WARN | #50 基座 |
| **JIT/解释器/FIX-SLICERACE（承 #42）** | `jitfort rc=0`+探针 OK；rc2b 首帧无 NULL；8 轮 race=0 | 承 #42 保持 |
| **L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c（承 #42）** | JPEG/标题心跳；Toolbar 契约；计数 0→1→2；无 `ACCERR` | 承 #42 保持 |
| **MULTI-OVERLAY-FULL/DEVCOMPAT/INTERP-FIX（承 #41）** | 双 Hybrid/per-slot invoke/z-order；enforcing 开箱可装；8 MB 栈 | 承 #41 保持 |
| **FIX-JSCALL/BACKSIZE/BWVMount/DISMISS/WVP/HOME/ITOUCH（承 #40–#37）** | count 0→1→2；Back 关抽屉；`.razor` 挂载；外点关；Home 整页；注入命中 | 承 #40–#37 保持 |
| **payload/像素/a11y/AOT `-struct1`（承 #36）** | 原地启动；无 Known；status=1；`-struct1` 构建成立 | 承 #36 保持 |
| **B2/W9/W10（承 #35）** | 双标记齐；T14/T21/T8/T20/T19 | 承 #35 落地 |
| **rc.2 基线 + W6/W7/W8（承 #34）** | 版本自述；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6 | rc.2 线成立 |
| **Blazor A/B + 主体（承 #33）** | 默认/nocsp 双标记；TabbedPage/W5 | 承 #33 保持 |
| **WebView / B1 razor（承 #32）** | 9 项卡 + B1 两标记 + JS 往返 | 按 #32 判据 |

> 失败 Run 保留报告 tar；无入口项登记「未测（本包无入口/无 hdc）」；**降级项（子窗 a11y provider / 子窗 ArkWeb /
> 平台级多子窗上限 / IME 人工卡 / SEC-5c B–F）按预期登记，不判失败**。

## 4. 注意

- 包内 hap 为自签：**9568257 / 9568344 属预期**，先重签（需华为调试证书 + Profile 绑 UDID）；**预签件已刷新至 #50**——可直接
  `hdc install -r` 直装（非 tester UDID 仍 `9568344`，请回传 UDID 代签）；**Blazor 双变体同名（`com.example.opendotnet`），装前卸载**；
  两变体均无 INTERNET（重签保持）。
- **多窗口径（#50）**：L 为真多窗（第二 MAUI 视觉树 + per-window surface/renderer/输入/焦点）；**降级**：子窗 a11y provider
  （主 provider 零变化、子窗帧本地）、子窗 ArkWeb 第二宿主（槽池留主窗、子窗 web 不挂载）、平台级多子窗上限未探（应用级 N=1）、
  **子窗 IME 实敲人工卡**、SEC-5c B–F（B 子窗 prompt 键盘全局 / C 状态机顺序假设 / D Back·按键无消费者 / E pinch 非有限几何 /
  F 子窗 a11y 帧常驻）。2in1 debug 域结论，不外推手机/release；明细见 `-l-m4.md`、`-security-scan-5c.md`、平台限制 E5。
- **IME 人工卡（#50）**：uitest `uiInput` 无子窗 XComponent/多点注入面（click/text 未达子窗）；只有真实键鼠/触摸可测，
  步骤与回传格式见 `-l-m4.md` 末节；不阻塞。
- **密码脱敏口径（承 #49）**：修复在 a11y 影子树发布侧（密码节点只发等长圆点），不改变绘制；离线红/绿负控通过、
  **设备未验证**——复测以设备 dump 为准；读屏可达性取决于服务启用，不判失败。
- **R2R 口径（承 #48）**：Crossgen2 包作**本地 folder feed** + `RestoreConfigFile`（消除 NU1100）；只用于 JIT；R2R 件
  +11 MB；interp 抑制（FIXRR：`interp=3` 置 `DOTNET_ReadyToRun=0`）。R2R 不是 kit 内资产，需自建 jit 变体（debug 域）或在 ACL 域构建。
- **AOT 首帧 / FPS48 口径（承 #48）**：CEF 初始化 ~240 ms 从 attach→surface 段移出；首帧后 3–17 ms 才挂覆盖层属预期；
  投票在 XComponent 注册期常驻（可见即 60）；无动画时 0 app 帧属门控预期；idle 动态撤票为后续项（不判失败）。
- **多窗 S 口径（承 #48）**：S 项仅形态响应（`supportWindowModes` + 尺寸/自由模式订阅 + surface 活性重排）；
  `freeWindowModeChange`/split 真形态与手机域未测。
- **a11y Flyout / 抢占原文口径（承 #47）**：nodeCount=70 为壳自检读数；`[maui-capacity]` 只导出新增段（12×3 s 轮询；
  trim 整文件回退）；512K 环噪声大时按「未测」登记。
- **INTERP-DRAW2 / 自动释放 / 动态槽 / INTERP-RENDER 口径（承 #45–#46）**：面外剔除只做 surface 级；MAX/HOT 默认 4/2
  （clamp 2..8）、热对 [0,1] 常驻、释放即拆、重挂重放；N=8 实测 >4 不挂（安全上限 4）；静态帧不再每帧全树 Measure/Arrange。
- **AOT 默认 / 发布域口径（#43 起）**：5 MAUI hap 全 NativeAOT（`runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libhostfxr/libclrjit）；
  JIT 保形态（`--runtime-mode jit` 自建；debug 域 JITFORT 默认；release 域需 AGC ACL `ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`
  （2in1/平板）或厂商豁免——手机只发 AOT）；interp 实验（独立 pack）。**发布形态请用 AOT**；覆盖装先卸载（`9568286`）、
  过期 p7b=`9568329`（`2026-10-04-ohos-release-domain-and-pidloss.md`）。
- **启动/帧率基线（#48 新基线）**：三路径冷启（AMS→首帧）**AOT 534 ms / JIT R2R 710 ms / JIT IL 1031 ms**；interp 首帧与 IL
  同档（614）；干扰态 60.0 fps（清净 60.1）、interp 稳态 60.1 fps；旧基线（#45 切片 1.56–1.69 s、interp 38–44 fps）已被 #48 取代。
- **JIT/interp 浸泡（SOAK-JI，2026-10-05）**：JIT 45 min（+21.6 MB、60.1 fps、0 崩/0 冻结/0 失 pid）、interp 45 min
  （rc2b+优化件、34.3 fps 镜像口径、0 崩）→ 与 AOT soak2 对照背书成立（`2026-10-04-ohos-jit-interp-soak.md`）。
- **解释器口径**：用 **rc2b pack** + **rc.2 kit hap**（重签）；勿用 rc.1 托管 CoreLib 的旧测试件（QCall ABI 错配会
  `SIGSEGV(NULL)@coreclr_initialize`，属测试件问题、非 pack 缺陷）。`interp.txt=1|2` 混合模式保留默认。
- **AOT pack 结构修复**：`FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分——**当前资产 = `-struct1`**（asset 607541145），后续 runtime pack 无需再重打。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递；②镜像扩展分支 `m-web-mirror d47f1fcb3b` 尚未并入
  `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过（未定位）；④stock JIT 长跑/后台唤醒未覆盖
  （JIT 现非默认）；⑤解释器混合模式保留默认；⑥Crossgen2 包未本机重编；⑦平台级多子窗上限未探（应用级 N=1）。其余相关项
  登记「未测（在途）」不判失败。
- **rc.2 相关（2026-10-04 复核：WAIT）**：官方 rc.2 **未发布**；ohos-workload 已加监测 `rc2-watch`（`1d39eb7`）；触发（exit 10）后按
  `docs/plans/2026-09-30-rc2-mainline-adoption.md` §8 换 pin、删 dnceng feed step；rc.1 回滚线保留；应用侧构建请同步 rc.2 线。
- **hilog 缓冲（探针误报防护）**：512K 环在噪声大时只保留 ≈4–5 s；临时 `hilog -G 16M -t app,core` 重跑（**跑完还原 512K**）。
  注意**状态文件伪影**：`dotnet-status.txt`/壳轮询可能输出上一轮残留行——**以本轮时序内状态为准**（抢占原文导出亦按本轮新增段判读）。
- **本机直测（交付方）**：设备已可测（hdc 无线 `127.0.0.1:35111` + SDK 自签 + AOT/JIT（含 R2R）/解释器三路径 + 真多窗流程）；
  AOT 默认在 enforcing 镜像开箱可装（DEVCOMPAT-DEFAULT，承 #41）。
- **数字口径注（不确定项）**：kit 内 5 MAUI AOT hap 用 `~/.dotnet.rc2-fix`（SDK `26451.112` = 声明基线）打包；构建机默认
  `~/.dotnet`（`26451.109`）的 ILCompiler 为 `11.0.0-rc.1.26451.109` 有偏离（两安装 preview.28 pack 已逐字节同步）。
- 所有数字 = **kit #50 发布实测（以 release「## Integrity（kit #50）」与随包校验为准）**：tar **68,264,136 / `d70dc786…`**、
  树 `b4b5055c…`、sidecar `2ffb3b6a…`、`SHA256SUMS` 18 项 / 1,600 B / `98fd0dd2…`；#49 = tar 67,888,851 / `477974bb…`、
  #48 = 67,735,148 / `5c22704f…`、#47 = 67,706,719 / `3d6bb58b…`、#45 = 67,695,181 / `ca48a93c…`（对照）；
  bundle = `workload-1.0.0-preview.28` **73,119,180 / `6a83c0f3…`**（三处同步；dist sums `ff3d5550…`（212 B）；sdk 锚
  **`a3417a5489`**）；dtk asset **615507454** / latest **615508545**（sidecar 615508271/615509231；bundle 三处
  preview.28 615504519/615505218、latest 615505489/615506292、sdkrc2 615506528/615507247；预签 **615517779**/**615518466**；
  interp pack rc2b asset **606999003**；AOT `-struct1` asset **607541145**；Crossgen2 rc.2 asset `RA_kwDOT39XK84kdPmt`）；
  CI **5/5** @ pin `afa6d7a`（interaction `37460790068` / pixel `37460790072` / host-export `37460790087` /
  ridgraph `37460790138` / markdownlint `37460790028`）+ sdk `ohos-install-tests` @ `a3417a5489` run `37465689708`。
- 细判（TTS/HUKS/自绘深度/权限/Share-Scan）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2 与
  `…kit29/kit28/kit27/kit26/kit25`；无障碍逐项：`docs/plans/2026-09-27-ohos-accessibility-device-verification.md`（含 N4）；
  #50 细节：`2026-10-06-ohos-multiwindow-l-feasibility.md`、`…-l-plan.md`、`…-l-m2.md`、`…-l-m2-exit.md`、`…-l-m3.md`、
  `…-l-m4-prestudy.md`、`…-l-m4.md`、`…-l-consolidate.md`、`…-security-scan-5a/5b/5c.md` 与 `…tester-handoff-kit50.md`；
  #49 细节：`2026-10-05-ohos-multiwindow-m.md`、`…security-scan-4.md`、`…mw4-consolidate.md` 与 `…tester-handoff-kit49.md`。
