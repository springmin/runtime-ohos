# 运行时模式判定卡：JIT / AOT / 解释器 / 渲染（2026-09-27）

> **2026-10-06 更新（kit #50，当前）**：kit #50 = **kit #49（MULTIWINDOW-M + SEC-SCAN-4 + 承 #48 CG2-R2R/AOT-STARTUP/FPS48/MULTIWINDOW-S/FIXRR 与 #47/#46/#45 全量）+ MULTIWINDOW-L 全套（M1–M4 + SEC-SCAN-5a/5b/5c）+ polish-49**：①**M1 宿主每窗 surface 注册表**（window-id claim/release/route；registry 84/84、bridge 26/26）；②**M2 切片 per-window renderer**（每窗 `OpenHarmonyWindowSurface`/`Renderer` + `OpenHarmonyWindowHost`；`RouteSurface/RouteTouch/RouteFrame` 按 window-id 路由；headless 双窗 22 checks）；③**M3 子窗挂 XComponent + managed surface id**（第二 MAUI 视觉树；真机 `sub-1` 720×480 `first frame=True`、触摸按窗、close 回收、reopen 同 id、churn ×20 无残留）；④**M4 每窗焦点/IME/生命周期/a11y 分区/pinch**（壳 ACTIVE/INACTIVE → per-window `IWindow.Activated/Deactivated/Stopped/Resumed` 状态机；每窗 a11y 影子帧、主 provider 零变化；per-window pinch 经 `ohos_host_notify_window_pinch` → 该窗 renderer，导出 156→**157**）；**SEC-5a/5b/5c**（unregisterXComponent 失败闭合 + surface 事件按组件路由；window-id 校验失败闭合 + registerXComponent 身份；主窗→子窗文本 thunk 仅主窗、跨窗文本泄漏修复）；**polish-49**（`ParseSubWindowOptions` 三可选布尔补齐 → 真机 E=0；close WARN 平台内部仅注释；Home 键经焦点丢失链 suspend：INACTIVE→600 ms 宽限、`clearSubWindow` 取消定时器）；真机 HAD-W32/W24（2in1）：双窗稳态 **60.0/60.0 fps**、40 min 长稳（RSS 净 −34 MB、pid 恒定）、churn ×20（WMS 残留 0）、JIT 与 AOT 各过轮；**降级声明（明示，不判失败）**：子窗 a11y provider（主 provider 零变化、子窗影子帧本地保持）、子窗 ArkWeb 第二宿主（槽池留主窗、子窗 web 不挂载、无回归）、平台级多子窗上限未探（应用级 N=1 失败闭合）、**子窗 IME 实敲人工卡**（uitest `uiInput` 无子窗 XComponent/多点注入面，步骤见 `2026-10-06-ohos-multiwindow-l-m4.md` 末节）、SEC-5c B–F 报告级（B 子窗 prompt 键盘全局化 / C 状态机顺序假设 / D Back·按键无消费者 / E pinch 非有限几何 / F 子窗 a11y 帧常驻）；**预签已刷新（#50 件：68,157,557 / `028d29f4…`，asset 615517779；sidecar 88 B / `02397318…`，asset 615518466）**；壳 abc **436,808（`289a5e5d…`）**/24,324、宿主 **330,656（`fdeb94eb…`，导出 157/157、UND 249）**、套件 **661/663 floor 643**；发布实测 tar **68,264,136 / `d70dc786…`**、树 `b4b5055c…`、sidecar `2ffb3b6a…`、`SHA256SUMS` 18 项 / 1,600 B / `98fd0dd2…`；bundle **73,119,180 / `6a83c0f3…`**（sdk 锚 **`a3417a5489`**）；CI 5/5 @ `afa6d7a`（interaction 37460790068 / pixel 37460790072 / host-export 37460790087 / ridgraph 37460790138 / markdownlint 37460790028）+ sdk run `37465689708`；数字以 release「## Integrity（kit #50）」与随包校验为准；判定点 = `docs/plans/2026-10-06-ohos-tester-handoff-kit50.md`。
>
> **2026-10-05 更新（kit #49，上一版）**：kit #49 = **kit #48（CG2-R2R + AOT-STARTUP + FPS48 + MULTIWINDOW-S + FIXRR；承 #47 FIX-A11YFLYOUT/FIX-PREEMPT-RAW 与 #46/#45 全量）+ 应用内子窗（MULTIWINDOW-M）+ a11y 密码脱敏（SEC-SCAN-4）**：①**MULTIWINDOW-M**（maui 切片 `b093e33825` + ohos-workload `be70a73`/`16df9a3`）：壳 `Window.createSubWindowWithOptions` 子窗控制器——命令 0 create/1 move/2 resize/3 show/4 hide（无公开 hide API：如实回 Failed 801）/5 close，事件 0 created…10 resumed；`pages/SubWindow.ets` 壳绘 named-route（`ohos_dotnet_subwindow`，`WindowProperties.name` move guard，touch/drag hilog；无 create 零分配）；主窗 HIDDEN/SHOWN 转 suspended/resumed + 挂起期命令抑制；宿主 `registerSubWindowSink`/`notifySubWindowEvent` NAPI + `ohos_host_sub_window_command`（op 99 可用性探针）/`ohos_host_sub_window_event_listener`（导出 151→**153**）；切片 `OpenHarmonySubWindow`（IsSupported/IsOpen/IsVisible/IsSuspended/IsContentReady/WindowId/Bounds + Changed/Touched，Utf8JsonWriter/JsonDocument AOT 安全，离设备退化 false/无操作）；真机 HAD-W32（2in1）：`app://subwindow/demo` create **id=344（120,160 720×480）** → page ready `name=ohos_dotnet_subwindow drag=on` → move **420,360** → resize **900×600** → close（截图 mw-seq1/2/3）；`app://subwindow/open` id=346 → touch `OHOS_MAUI_SUB touch #57`、swipe `drag #51 → 269,259`（PanGesture 自移动）；主窗 HIDDEN/SHOWN → `subwindow suspended/resumed`，主页面 `canvas presented (2090×1324) avg=16ms max=21ms`（60fps），无新 fault；诚实边界：单 surface/renderer（子窗内容为壳侧 ArkUI 自绘，非第二 MAUI 视觉树；per-window surface/renderer 属 L）；②**SEC-SCAN-4**（maui `5f3efd55e5`）：a11y 影子树不再发布密码明文——`OpenHarmonyAccessibility` 对 `IEntry{IsPassword}`/平台 `IsPassword` 走同一 `MaskPassword` 发布等长圆点；套件 +2 pin（`a11y-password` 明文不得出现 + `draw cull edge` 零尺寸/shadow 外延/屏外 Image 不得剔除），离线红/绿负控（还原修复 → plainHidden=False assert=False，exit 134）、设备未验证；另 6 项报告级（WebView 区 2 / 供应链 1 / 加固 3）；③承 #48：**R2R/JIT 启动**（CG2-R2R：JIT 冷启 1031→710 ms、in-proc present 575→307；interp R2R=0 FIXRR）、**AOT 首帧**（796→534 ms、attach→surface 239→13）、**帧率投票 60**（46.2→60.0 fps）、**多窗 S**（2in1 3120×1955）、**FIX-A11YFLYOUT**（nodeCount 1→70）、**FIX-PREEMPT-RAW**（`[maui-capacity]`）与 #46/#45 全量（INTERP-DRAW2、FIX-A11YBUTTON、AUTODISCONNECT、INTERP-RENDER、动态槽 MAX/HOT 4/2、AOT 默认、FRAMEPACING）；**预签已刷新（#49 件：67,807,185 / `56aaf08f…`，asset 612929512；sidecar 88 B / `4ba00cf8…`，asset 612930421）**；壳 abc **414,532（`e016db13…`）**/24,324、宿主 **301,984（`cf4cc706…`，导出 153/153）**、套件 **607/609 floor 589**；发布实测 tar **67,888,851 / `477974bb…`**、树 `8d03cb4c…`、sidecar `3803b3db…`、`SHA256SUMS` 18 项 / 1,600 B / `b142639d…`；bundle **73,085,186 / `7d06e781…`**（sdk 锚 **`7abaf8132f`**）；CI 5/5 @ `e0803bedad`（interaction 37321721695 / pixel 37321721683 / host-export 37321721786 / ridgraph 37321722030 / markdownlint 37321721810）+ sdk run `37331391778`；数字以 release「## Integrity（kit #49）」与随包校验为准；判定点 = `docs/plans/2026-10-05-ohos-tester-handoff-kit49.md`。
>
> **2026-10-05 更新（kit #48，上一版）**：kit #48 = **kit #47（FIX-A11YFLYOUT + FIX-PREEMPT-RAW；承 #46 INTERP-DRAW2/FIX-A11YBUTTON） + R2R/JIT 启动（CG2-R2R） + AOT 首帧省时（AOT-STARTUP） + 帧率投票 60（FPS48） + 多窗 S（MULTIWINDOW-S） + FIXRR**：①**CG2-R2R**（sdk-ohos `crossgen2-packs-11.0.0-rc.2`，43,792,647 / `6bb8a375…`，folder feed）：JIT `PublishReadyToRun=true` 冷启 **1031→710 ms（−31%；n=3）**、in-proc present 575→307；interp 不执行 R2R 原生码且付 +350 ms → host 在 `interp=3` 置 **`DOTNET_ReadyToRun=0`**（FIXRR，ow `08ccbe8`；runtime 对 `InterpMode>=2` 本就强制 `fReadyToRun=false`，显式行同效；JIT/混合 1/2 不变）；②**AOT-STARTUP**（ow `22ca602`/`372c35e`/`92ea222`）：隐藏 ArkWeb 覆盖层**首用才挂载** + 宿主对相同 app-context **跳过 surface 重放**，CEF 初始化（~240 ms）移出首帧路径 → AOT AMS→首帧 **796→534 ms（−262，−33%）**、Main→首帧 386→151、attach→surface 239→13；JIT/interp 不回归；③**FPS48**（ow `67a1de8`）：宿主注册 XComponent 时声明期望 60 Hz（`{60,60,60}`）→ RS 60/30 仲裁消失，第二重绘窗口干扰态 5s 窗均值 **46.2→60.0 fps**（清净态 60.1；app 每帧 work 不变）；④**MULTIWINDOW-S**（maui `ed02203bfd` + ow `c5df1de`）：壳声明 `supportWindowModes` fullscreen/split/floating + `windowSizeChange`/`freeWindowModeChange` 订阅；切片 `CanArrangeSurface`（Created/Changed 尺寸>0 重排、Destroyed/0x0 保末帧）→ 真机 2in1 最大化 **2090×1394→3120×1955**（`surface state=Changed 3120x1885` → `canvas presented`）；套件 +2；⑤kit #47 全部保留（FIX-A11YFLYOUT nodeCount 1→70、FIX-PREEMPT-RAW `[maui-capacity]`、INTERP-DRAW2 60.1 fps、FIX-A11YBUTTON、AUTODISCONNECT、INTERP-RENDER、动态槽 MAX/HOT 4/2、AOT 默认、FRAMEPACING 60.00 fps）；**预签已刷新至 #48**（67,651,331 / `2f2f4c40…`，asset 612061141；sidecar 88 B / `50a1f38e…`，asset 612062470）；壳 abc **375,268（`9cd2b4c3…`）**/24,324、宿主 **297,888（`319db8e5…`，导出 151/151）**、套件 **599/601 floor 581**；发布实测 tar **67,735,148 / `5c22704f…`**、树 `6b2b493c…`、sidecar `1c51cdbc…`、`SHA256SUMS` 18 项 / 1,600 B / `a05caba0…`；bundle **73,053,084 / `3b62cee2…`**（sdk 锚 **`767c03ee71`**）；CI 5/5 @ `c42cfa43` + sdk run `37286847476`；数字以 release「## Integrity（kit #48）」与随包校验为准；判定点 = `docs/plans/2026-10-05-ohos-tester-handoff-kit48.md`。
>
> **2026-10-05 更新（kit #47，上一版）**：kit #47 = **kit #46（INTERP-DRAW2 + FIX-A11YBUTTON）+ FlyoutPage 无障碍（FIX-A11YFLYOUT）+ 抢占原文导出（FIX-PREEMPT-RAW）**：①**FIX-A11YFLYOUT**（maui 切片 `d5384d6cc3`）：`PushChildren` 补 `FlyoutPage.Detail`（恒入树）/`FlyoutPage.Flyout`（仅 `IsPresented`）分支（rc.1 FlyoutPage 非 `IContentView`，旧分支覆盖不到 → 只发布根）；headless 断言 `a11y-flyout detail/panel` + 负控制红，真机 `--a11y-probe` **nodeCount 1→70**；②**FIX-PREEMPT-RAW**（ohos-workload `f538c84`）：壳 `pollManagedStatus` 把 `dotnet-status.txt` 新增段中含 `overlay preempted/restored/replay` 的行以 **`[maui-capacity]`** 前缀直写 hilog（trim 时整文件回退）→ 真机低噪声复放取到 5 行原文（`preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`）；③承 #46：**INTERP-DRAW2**（面外剔除：interp draw 14.4→9.4 ms、33.9→60.1 fps、每帧 CPU −27%；JIT 无回归）、**FIX-A11YBUTTON**（自检按钮左下角 + 覆盖层之上，两态真机可达 `[523,1622][607,1668]`）；④承 #45：自动释放（FIX-AUTODISCONNECT）/INTERP-RENDER/动态槽（MAX/HOT 4/2 + 3 控件）/默认 AOT/FRAMEPACING 与 #42… 全部修复；**预签已刷新至 #47**（67,639,132 / `f58c4906…`，asset 610975429；sidecar 88 B / `c95344ac…`，asset 610976421）；壳 abc **370,240（`4b439e83…`）**/24,324、宿主 **297,888（`7b1694d9…`，导出 151/151）**、套件 **593/595 floor 575**；发布实测 tar **67,706,719 / `3d6bb58b…`**、树 `0f266636…`、sidecar `4adb0b60…`、`SHA256SUMS` 18 项 / 1,600 B / `6bbc2235…`；bundle **73,059,625 / `27c54c62…`**（sdk 锚 **`266b196106`**）；CI 5/5 @ `3de9a95fe0` + sdk run `37245230111`；数字以 release「## Integrity（kit #47）」与随包校验为准；判定点 = `docs/plans/2026-10-05-ohos-tester-handoff-kit47.md`。
>
> **2026-10-04 更新（kit #45，上一版）**：kit #45 = **#44（动态槽 + 默认 AOT + FRAMEPACING）+ 自动释放（FIX-AUTODISCONNECT：移除 web 控件即销毁槽/重挂重建）+ 渲染门控（INTERP-RENDER：interp 22.0→30.1 fps、meas 13.0→0.0 ms/帧、CPU −13pt；JIT/AOT 60 fps 不变）**——真机 kit 样例 Remove C → `web slot destroy: 2`（12:40:50）、re-add → `web slot create: 2`（12:41:00）并恢复交互；壳 abc 368,812（`1076a700…`）/24,324、宿主 297,888（`7b1694d9…`）、导出 151/151、套件 587/589 floor 569；预签刷新至 #45（67,624,950 / `e1ce8ab6…`，asset 609411819）；发布实测 tar 67,695,181 / `ca48a93c…`、树 `ae0f7fce…`、sidecar `9741aced…`、bundle 73,058,366 / `a8334c4c…`（sdk 锚 `c7ac81ccdf`）；数字以 release「## Integrity（kit #45）」为准；判定点 = `docs/plans/2026-10-04-ohos-tester-handoff-kit45.md`。
> **2026-10-04 更新（kit #44，上一版）**：kit #44 = **#43（默认 AOT + FRAMEPACING）+ 动态槽（SLOTS-DYNAMIC）**——覆盖层池 MAX/HOT 默认 4/2、按需创建/释放即拆、容量事件降级、壳 ForEach + defer 队列；**3 控件并发出画/交互**；壳 abc 368,812（`1076a700…`）/24,324、宿主 297,888（`7b1694d9…`）、导出 151/151、套件 584/586 floor 566；预签刷新至 #44（67,627,789 / `75a40110…`，asset 608782132）；发布实测 tar 67,680,863 / `b777d8d8…`、树 `db2604d5…`、sidecar `85d62a6e…`、bundle 73,052,763 / `3b3008a4…`（sdk 锚 `2abf4fcaa3`）；数字以 release「## Integrity（kit #44）」为准；判定点 = `docs/plans/2026-10-04-ohos-tester-handoff-kit44.md`。
> **2026-10-03 更新（DECIDE-BASELINE 决策）**：**三路径设备基线落定**（AOT/JIT/interp 各 3 轮 + 31 min 长跑 + 前后台 ×10；数字见下表，完整文 `2026-10-03-ohos-three-path-baseline.md`，证据 scratch `decide-baseline/`）。三路径首帧同档（冷启 payload→canvas ≈3.2 s；r3 热缓存 ≈0.5 s），帧节奏 ~17.6 fps 同档；**AOT 内存最低**（~255–287 MB，31 min 平），JIT/interp ~330 MB 且长跑回落；三路径长跑 0 崩溃/0 重启。
> **JITFORT 发现（WX-PROBE / WX-TOKENS / WX-HOST-PRCTL）**：①解锁面 = 宿主 `prctl(0x6a6974, 0, 0)`（NDK `sys/prctl.h` 无 `PR_SET_JITFORT` 定义，隐藏接口；`arg3=1` 为 fortify/加固；解锁后 `/proc/self/xpm_region` 由 `0-0` 变 4 GB）；②**非调用者隔离**：任意加载自签原生代码的 app 都能翻转该进程状态；③**跨 app 生效**：解锁后后续 app 进程启动即 `1=OK 2=OK`（A/B 对照：`(0,1)` fortify → 下一 app `probe 1=22` + CoreLib `0x800701E7` 失败）；④**官方路径 = 受限 ACL**：`ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`（API14+，PC/2in1/Tablet；系统 JS 引擎用 `ALLOW_USE_JITFORT_INTERFACE`，API16+），经 AGC「项目设置 → ACL 权限」申请（实名+审核，单次 ≤30 条，可先建试用调试 Profile 上机、不可上架；预置 os_integration 也不解锁）；**坚盾守护模式全局禁 JIT（已授权亦然）** → 分发必须 AOT 兜底。
> **推荐默认**：**AOT 为分发默认**（同帧率、内存最低、无动态码/隐藏接口依赖，坚盾/无 ACL/手机域可用）；**JIT = 性能升级形态**（仅 debug/内测签名域由宿主 JITFORT 默认开；release/生产域须 ACL 或厂商豁免；逃生口 `DOTNET_OHOS_NO_JITFORT=1`、无 ICU 镜像自动 `InvariantGlobalization`）；**interp = 实验形态**（独立 pack 资产，不随主包分发）。分级 = 设备（2in1/平板可 ACL-JIT；手机只发 AOT）× 签名域（debug=JIT 可；release=ACL 或 AOT）。**（已落地：AOT-DEFAULT，出包默认 aot + 真机复核，见 §4 执行项闭合）**

> **2026-10-03 更新（kit #42，上一版）**：kit #42 = #41 + **JIT 解锁 + 解释器 rc2b 首帧 + FIX-SLICERACE（8/8）+ L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c/镜像扩展**（①**JIT 解锁**（WX-HOST-PRCTL：宿主 `prctl(0x6a6974)` JITFORT 默认开 + 无 ICU 镜像自动 `InvariantGlobalization`）→ **JIT 首帧**（`canvas presented` 4–8 + UI 截图；探针 `1=OK 2=OK`；逃生口 `DOTNET_OHOS_NO_JITFORT=1`/`DOTNET_OHOS_ICU`）；②**解释器 rc2b**（新资产 `ohos-interpreter-pack-rc2b.tar.gz` 2,410,595/`5974430509…`，asset 606999003；含 WX-PATCH2）→ **解释器首帧**（`canvas presented 2090x1324`；INTERP-NULL 根因 = 旧测试件 rc.1 托管 CoreLib × rc.2 原生 QCall ABI 错配，非 pack 缺陷）；③**FIX-SLICERACE**（切片 handler 并发设置竞争：可重入串行化 + `_ready` 门闩）→ **JIT 8/8 设备轮 PASS**、套件 **578/580 floor 560**；④L6（Screenshot JPEG/Title 心跳；壳 abc **356,468/`dd04dad1…`**）、LEGACY Toolbar 闭合、SAMPLE-FIX（`blzProbe`=`dotnet-ref ok`、Blazor `#app` 恢复挂载、`dotnet.zip` 258 项）、WX-PATCH2 双映射预检+写屏障提交检查、P2c `skills[].uris`、镜像扩展（`m-web-mirror d47f1fcb3b`）；宿主全量重建 **297,888（`08abe185…`，导出 151/151、UND 240）**；**预签未刷新（仍 #41 件，指向 #41 内容）**；FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount/FIX-JSCALL/MULTI-OVERLAY-FULL/DEVCOMPAT 全量保留；发布实测 tar **376,256,128 B / `ea4e3b58…`**、树 **`13f3a086…`**、sidecar **`878d05a1…`**；数字以 release「## Integrity（kit #42）」与随包校验为准；判定点 = `docs/plans/2026-10-03-ohos-tester-handoff-kit42.md`（#41 = 上一版，见其交接文）。
> **2026-10-03 更新（kit #41，上一版）**：kit #41 = #40 + **MULTI-OVERLAY-FULL + DEVCOMPAT-DEFAULT + INTERP-FIX（三大彻底修复）**（①**MULTI-OVERLAY-FULL**（maui `07423dfe93` + ow `0e0129e`）：双槽 ArkWeb 覆盖层池 + **owner 感知 LRU 抢占/恢复**（`IOpenHarmonyOverlaySlotOwner`）、per-slot hybrid serve/message/**invoke 通道**（slot-tagged invoke id）、**激活序 z-order**、payload-in-libs appDir 探测——同页两 Hybrid 各自 invoke/消息闭环，>2 控件按 LRU 抢占退化、activate 恢复重放 load；②**DEVCOMPAT-DEFAULT**（ow `12be59c`）：payload 逐文件码签重写**默认化**（无扩展名→`.so`、恰 4096 B→+4 B）——enforcing 7.0.0.111+ **开箱可装**；kit 现 15 `.so` / 257 zip 条目；③**INTERP-FIX**（ow `c9916cd`）：宿主 **8 MB app 线程栈** + `interp=3` 关 GC 写屏障拷贝；**rc.2 重建解释器 pack** 独立资产 `ohos-interpreter-pack-rc2.tar.gz`（2,409,070 B / `34709a94…`，asset 605924427）；④**预签刷新至 #41**（tester UDID；376,684,381 / `2075650a…`，asset 606183753）；FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount/FIX-JSCALL 全量保留；壳 abc **356,140（`2a90f0d7…`）**/headless 24,324、宿主 **293,792（`8d67def3…`）**、导出 **150**、套件 **563/floor 543**；发布实测 tar **376,036,502 B / `bed460ae…`**、树 **`7ce1946e…`**、sidecar **`2a95e764…`**；数字以 release「## Integrity（kit #41）」与随包校验为准；判定点 = `docs/plans/2026-10-03-ohos-tester-handoff-kit41.md`（#40 = 上一版，见其交接文）。
> **2026-10-02 更新（kit #40，上一版）**：kit #40 = #39 + **FIX-JSCALL**（maui `15d81f31b1` + 套件 pin `2028cc2`/`9073c65`）：**BlazorWebView IPC 出站半边 AOT 扎根**——`IpcSender.BeginInvokeJS` 序列化 `JSCallResultType`/`JSCallType`、`IpcSender.Navigate` 序列化 `NavigationOptions`（均经 WebView 包反射解析器）；NativeAOT 缺 `EnumConverter<T>`/`JsonTypeInfo<T>` 闭合实例原生代码 → attach interop 死在 `IpcCommon.Serialize`（#39 的 FIX-BWVMount 桩 interop 又吞掉后续点击）；切片把三类型并入源生成上下文 + handler 静态构造触碰 type info + 移除桩探针 → **razor 计数往返 0→1→2 真机达成**（截图 r0/r1/r2；`missing native code`=0、`BeginInvokeDotNet` accepted=4）；FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount 全量保留；壳 abc **342,160（`ffda66da…`）**/headless 24,324（未变）、宿主 **293,792（`384e552a…`）**（未变）、导出 **150**、套件 **555/floor 535**；发布实测 tar **375,836,470 B / `31ab8732…`**、树 **`e950de54…`**、sidecar **`9b051247…`**；数字以 release「## Integrity（kit #40）」与随包校验为准；判定点 = `docs/plans/2026-10-02-ohos-tester-handoff-kit40.md`（#39 = 上一版，见其交接文）。
> **2026-10-02 更新（kit #39，上一版）**：kit #39 = #38 + **FIX-BACKSIZE + FIX-BWVMount**（①**FIX-BACKSIZE**（maui `be09a48817` + 壳/宿主 `9e6519e`）：系统 Back 键经壳 `onBackPress(): boolean` → 宿主 `host.backPressed`/`ohos_host_register_back_pressed`（导出 **149→150**）**关闭抽屉**（第二次 Back 交回系统 `#BACKGROUND`）；`BlazorWebView` 覆写 `GetDesiredSize`（真实尺寸——此前 `Standard` 返回 0 → frame 退化被壳忽略、自身不出画）；hybrid 已注册时 Blazor frame 有意 withheld；②**FIX-BWVMount**（maui `52b082a071`）：**NativeAOT 下 `.razor` 组件真机挂载**——handler 静态构造触碰源生成 `JsonElement[]` 类型信息，使 WebView 包反射构造的 `ArrayConverter` 留在 AOT 镜像（此前 `AttachPage` 在包内抛错、组件不挂载）；`[maui] blazor start/connect` + `BLZ_DIAG` 可观测；FIX-HOME/FIX-ITOUCH/FIX-DISMISS/FIX-WVP 全量保留）；壳 abc **342,160（`ffda66da…`）**/headless **24,324（`798b2477…`）**、宿主 **293,792（`384e552a…`）**、导出 **150**、套件 **554/floor 534**；发布实测 tar **375,765,521 B / `e95eed49…`**、树 **`932e7955…`**、sidecar **`e5fc82de…`**；数字以 release「## Integrity（kit #39）」与随包校验为准；判定点 = `docs/plans/2026-10-02-ohos-tester-handoff-kit39.md`（#38 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #38，上一版）**：kit #38 = #37 + **FIX-DISMISS + FIX-WVP**（①**FIX-DISMISS**（maui `86b439ffc8`）：抽屉**外点不关闭**的根因 = `FlyoutPage.Default` 版式在非 Phone idiom/landscape 下关闭被 `InvalidOperationException` 守卫拒绝（异常被触摸回调边界吞掉、面板保持）→ 默认 `Default` 改置 **`Popover`**（overlay 抽屉），外点正常关闭并重绘；②**FIX-WVP**（maui `47d79add01` + 壳 `acbe750`）：Hybrid overlay 坐标 **px→vp**（frame 为设备像素、壳按 ArkUI vp 用 → ×1.9 落窗外）、hybrid origin `https://0.0.0.1/` **注册仲裁**（后到 Blazor 只武装不加载）、`Web` 后置到 `ContentSlot` 之上（z-order 真出画）、抽屉/切 tab 时 **suspend/resume/hide** 状态机 + `WebCommandSent` 诊断）；FIX-HOME/FIX-ITOUCH 全量保留；壳 abc **341,560（`4f02cb1d…`）**/headless **24,324（`798b2477…`）**、宿主 **293,792（`4e9f3c3e…`）**、导出 **149**、套件 **550/floor 530**；**FIX-BACK 波次未入包**（Back 关抽屉 / BlazorWebView 尺寸在途，将随下一版）；发布实测 tar **375,641,619 B / `ced5583f…`**、树 **`307004e1…`**、sidecar **`8982fad0…`**；数字以 release「## Integrity（kit #38）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit38.md`（#37 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #37，上一版）**：kit #37 = #36 + **FIX-HOME + FIX-ITOUCH**（①**FIX-HOME**（maui 切片 `68ec598037`）：`OpenHarmonyNavigationPageHandler.PlatformArrange` 下钻 `CurrentPage`（safe-area walk + arrange 防递归标记）——Home tab（FlyoutPage→TabbedPage→NavigationPage）不再停在 `-1x-1`，AOT 真机首屏整页出画（截图 `fix-home/device/home-cold.jpeg`）；交互套件 +4 pin；②**FIX-ITOUCH**（宿主 `4e9f3c3e`）：`OnTouch` 改读 touch point **element** 坐标（与鼠标同一 surface 空间；free window 的 window 系含 70 px 系统标题栏 → 注入点击整体下移）——uitest 注入点击命中内容元素（"fading out…" → "animations done"）、偏心探针不误命中、tab 切换不变；宿主 UND 240→238）；壳 abc 字节不变 **339,964（`fc54d2b8…`）/24,324（`798b2477…`）**、hap 内宿主 **293,792（`4e9f3c3e…`）**、导出 **149**、套件 **544/floor 524**；发布实测 tar **375,652,577 B / `3a7259d6…`**、树 **`ab517b57…`**、sidecar **`7db60a77…`**；数字以 release「## Integrity（kit #37）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit37.md`（#36 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #36，上一版）**：kit #36 = #35 + **payload 原地直载（AOT 路径真机 BLZ）+ host 预注册缓冲 + 像素 Known 清零 + a11y 渲染帧修复 + rc.2 AOT pack `-r2`**（①壳 `findLibsPayloadDir` 兼容模块布局 `<bundleCodeDir>/<module>/libs/<abi>`——真机 hello-maui-wasm 直接自 `/data/storage/el1/bundle/entry/libs/arm64` 原地启动（`dotnet.zip not unpacked`，pid 49565）且 `BLZ_BOOT`/`BLZ_RENDERED` 双标记齐；②host 缓冲壳 `registerWebSink` 注册前到达的 web 命令（16 条 / 64 KiB，注册即 flush；套件 pin `moduleRoot`/`webPending`）；③像素套件不再有 `Known(...)`（selection tint 改字节量化精确断言 `#3959B3`）；④a11y `nodeCount 0` 根因 = shadow tree 未 publish，S2a pin `renderAttached=True`、`--a11y-probe` 实测 `status=1`、nodeCount 5/24 稳定；⑤rc.2 AOT pack 修正版 `-r2`（28,904,657 B / `542058cf…`，asset 601289590）修复 OpenSSL shim → 撤 rc.1 钉）；新壳 abc **339,964（`fc54d2b8…`）/24,324（`798b2477…`）**、hap 内宿主 **293,792（`cfbbe461…`）**、导出 **149**、套件 **540/floor 520**；发布实测 tar **375,627,841 B / `9eb9cecf…`**、树 **`9764827c…`**、sidecar **`4d7062c3…`**；数字以 release「## Integrity（kit #36）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit36.md`（#35 = 上一版，见其交接文）。
> **2026-09-30 更新（kit #35，上一版）**：kit #35 = #34 + **W9/W10 并入主线**（W9A **B2：MAUI WebView 承载 Blazor WASM**——真机 `BLZ_BOOT`/`BLZ_RENDERED` 打通（pid 6157），#34 的 AOT 入口缺口由 W10 修复；W9B T14 收尾 + T21 字体缩放；W9C T8 不等高 TableView；W9D **T20 媒体传输层**（本机镜像无 MediaKit 属预期，`IsSupported=false` 降级不抛）+ T19 深链判定（热 `delivered=1`）；W10 **AOT 入口修复**（宿主自身 libs 解析 `lib<stem>.so` + `dotnet-status.txt` 可观测、壳 AOT payload 探针/`fs` 别名/静态资源指纹；rc.2 AOT 包 OpenSSL shim 缺陷 → 本地钉 rc.1）；新壳 abc **339,164（`74054e2d…`）**/headless **23,516（`6bce4063…`）**、hap 内宿主 **293,792（`983e8f74…`）**、导出 **149**、套件 **540/floor 520**；发布实测 tar **375,629,423 B / `419d42e2…`**、树 **`d3b1b317…`**、sidecar **`d7e79d39…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `2dd447a7…`**（发布已完成，以 release「## Integrity（kit #35）」与随包校验为准）；判定点 = `docs/plans/2026-09-30-ohos-tester-handoff-kit35.md`（#34 = 上一版，见其交接文）。

> 目标：**一轮设备定运行时模式**。三条硬证据：`hilog/hilog-execmem.txt`（路由行）、managed 输出/首帧、`/proc/<pid>/maps`。
> 判定用 `tester-run.sh` **v13**（v13 = **137,113 B / `2caa06bd…`** / asset **594519342**；v12 = 126,658 B / `87763a3e…` / `script_version=12 (2026-09-28)` 为 #30 值：v10 起 `--mode-matrix` 一键矩阵（见 §2.0），v11 起另加 `--a11y-probe`，v12 起 `summary runtime_mode` 读 hap `libs/<abi>/runtime-mode.txt` 且 `interp_mode`/`aot_route` 按 file（interp.txt）> manifest（清单）> default 取值）：证据包 `tester-report-*.tar.gz` 含
> `hilog/hilog-execmem.txt` 与 `summary.txt` 键 `aot_route=0|1|0+1|1(manifest)|<unavailable>`、`interp_mode=<v>(file|manifest|default)|<unavailable>`、`runtime_mode=<v>(hap)|invalid(<值>)|<absent>`（缺失容忍；file>manifest>default）；
> 矩阵轮另出 `mode-matrix/summary.txt`（逐 Run 安装/启动/probe_1/xwe/首帧/崩溃/报告 tar + 结论建议行）；
> **打包期单开关（MS-MODE，2026-09-28）**：`-p:OpenHarmonyRuntimeMode=jit|aot|interp`（默认 jit）直接把同一 publish 产出对应形态——
> aot 校验 `lib<stem>.so` 存在，interp 可用 `-p:OpenHarmonyInterpreterPack=<解包目录>` 换入 `libcoreclr.so`+`libclrinterpreter.so`；
> 标记写入 hap `libs/<abi>/runtime-mode.txt`，宿主在 `xwe.txt`/`interp.txt` 同点读取（`interp.txt` 仍优先），日志
> `runtime-mode=<v> source=file|manifest|default`；规则与验证见 ohos-workload `docs/openharmony-hap-packaging.md`「Runtime mode switch」；
> 下文 AOT/解释器设备轮仍按 Run D/C 用既有资产，本开关是后续 hap 变体的打包入口；
> 三形态一键出包（构建侧）：`sh ohos-workload/scripts/make-mode-kit.sh --project <app.csproj> --tfm <tfm> --out-dir <dir> --interp-pack <pack> [--mode jit,aot,interp] [--sign <UDID>]` → `out/<mode>/<stem>-<mode>.hap`（逐模式断言 marker + lib 后保留；`--sign` 沿用 sign-for-device 口令纪律），规则与验证见 ohos-workload `docs/openharmony-hap-packaging.md`「Runtime mode kits」；
> **当前 kit = #31**（Blazor WASM/ArkWeb 组件增量 = 第 6 个 hap `hello-blazorwasm-host-unsigned.hap`（26,794,931 B / `36010a9c…`，未签名，bundle `com.example.opendotnet`）+ tester-run v13（`--blazor-probe`：`BLZ_BOOT`/`BLZ_RENDERED`）；MS-MODE（#30）= runtime-mode 打包开关 + tester-run v12 + MAPFIX harmony 重切；
> R3 增量（CoreSpeechKit TTS / HUKS-first SecureStorage / 自绘深度五连）仍然有效，见
> `2026-09-28-ohos-tester-handoff-kit30.md`（#29 见 `2026-09-28-ohos-tester-handoff-kit29.md`）；
> 下表 kit #28 行是历史 API 复核快照，kit #30 行为 2026-09-28 发布实测（#31 实测 tar 207,023,588 / `f4325d2f…`、树 `52e77ee8…`、sidecar `7d0cba77…` 仅作对照）；#32 实测 tar **207,114,608 / `8f690949…`**、树 `645879bc…`、sidecar `344760e7…`）。

### 三路径设备基线摘要（DECIDE-BASELINE，2026-10-03；完整表见 `2026-10-03-ohos-three-path-baseline.md`）

| 路径 | 启动 ms（r1/r2/r3） | fps40 | VmRSS（三轮均值） | Threads | RSTree buffer | 31 min 长跑 | 前后台 ×10（Back） |
|---|---|---|---|---|---|---|---|
| AOT | 3575/3508/521 | 15.4 | ~250 MB | 68–70 | 5 × 10.7 MiB = 54,620 KiB | 0 崩溃/0 重启，RSS 平（首/末 5 min 均 ~275 MB） | BG 4/10、FG 10/10，0 崩溃 |
| JIT | 6562/3530/515 | 18.2 | ~329 MB | 66–76 | 54,620 KiB | 0 崩溃/0 重启，RSS 342→244 MB | 10/10，0 崩溃 |
| interp | 3657/3531/502 | 18.0 | ~335 MB | 67–71 | 32,772–43,696 KiB（3–4 buf） | 0 崩溃/0 重启，RSS 333→281 MB | 10/10，0 崩溃 |

（注：r3 为热缓存轮，冷启对比用 r1/r2；AOT r3 的 fps 10.8 为窗口抖动，均值为三轮平均。）

## 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`；asset id/尺寸/digest 2026-09-27 API 复核，AOT-RECUT 后；harmony 行 2026-09-28 MAPFIX 后复核；kit #30 行为 2026-09-28 发布实测）

| 资产 | asset id | 大小 (B) | sha256（前缀） | 取件注意 |
|---|---|---|---|---|
| `device-test-kit.tar.gz`（kit #32，2026-09-28 发布） | 392356147 | **207,114,608** | **`8f690949…`**（sidecar `344760e7…`；树 `645879bc…`；`SHA256SUMS` 16 项 / 1,410 B / `2d3f2fad…`） | 6 个 hap（5 个 MAUI JIT（#32 新壳 abc 289992）+ 1 个未签名 Blazor `hello-blazorwasm-host-unsigned.hap`、#32 = **26,803,570 B / `5011cf73…`（0 权限）**、bundle `com.example.opendotnet`；`libs/arm64-v8a/runtime-mode.txt=jit`；zip 279 = 24 + 254 payload + marker、`libs` 270）＋文档＋verify-kit；#29 196,990,205 / `e895cc0a…`、#28 196,220,486 / `091dcc56…` 为历史对照 |
| `device-test-kit.tar.gz`（kit #47，2026-10-05 发布） | 610969198 | **67,706,719** | **`3d6bb58b…`**（sidecar 610970096 / `4adb0b60…`；树 `0f266636…`；`SHA256SUMS` 18 项 / 1,600 B / `6bbc2235…`） | 7 hap（承 #46 全 AOT 线：5 MAUI NativeAOT + Blazor 默认/`-nocsp`；abc **370,240（`4b439e83…`）**/24,324、宿主 297,888（`7b1694d9…`）、导出 **151**；**FIX-A11YFLYOUT（真机 nodeCount 1→70）+ FIX-PREEMPT-RAW（`[maui-capacity]` 抢占/恢复/重放原文）**；套件 593/595 floor 575） |
| `device-test-kit.tar.gz`（kit #45，2026-10-04 发布） | 609394479 | **67,695,181** | **`ca48a93c…`**（sidecar 609400064 / `9741aced…`；树 `ae0f7fce…`；`SHA256SUMS` 18 项 / 1,600 B / `9f677c40…`） | 7 hap（承 #44 全 AOT 线：5 MAUI NativeAOT + Blazor 默认/`-nocsp`；abc **368,812（`1076a700…`）**/24,324、宿主 297,888（`7b1694d9…`）、导出 **151**；**自动释放 + INTERP-RENDER**；套件 587/589 floor 569） |
| `device-test-kit.tar.gz`（kit #44，2026-10-04 发布） | 608775822 | **67,680,863** | **`b777d8d8…`**（sidecar 608776466 / `85d62a6e…`；树 `db2604d5…`；`SHA256SUMS` 18 项 / 1,600 B / `41c1f3c3…`） | 7 hap（5 MAUI 全 AOT：`runtime-mode.txt=aot`、3 `.so`（app.so 19,208,976 + host 297,888 + `libc++_shared.so` 1,267,392）、无 libcoreclr/libhostfxr/libclrjit；abc **368,812（`1076a700…`）**/24,324（SLOTS-DYNAMIC 壳）、宿主 297,888（`7b1694d9…`）、导出 **151**；payload `dotnet.zip` 200,144 B / 9 项） |
| `device-test-kit.tar.gz`（kit #43，2026-10-04 发布） | 608594629 | **67,638,015** | **`57c7bf44…`**（sidecar 608608236 / `bd1f8e33…`；树 `0c41f071…`；`SHA256SUMS` 18 项 / 1,600 B） | 7 hap（5 MAUI 全 AOT、`runtime-mode.txt=aot`；abc **356,468/24,324**、宿主 297,888（`7b1694d9…`）、导出 **151**；FRAMEPACING 宿主） |
| `device-test-kit.tar.gz`（kit #42，2026-10-03 发布） | 607136666 | **376,256,128** | **`ea4e3b58…`**（sidecar 607139045 / `878d05a1…`；树 `13f3a086…`；`SHA256SUMS` 17 项 / 1,517 B / `9ce72b56…`） | 7 hap（承 #41；AOT 段用本轮 AOT 资产（rc.2 pack `-r2`，撤 rc.1 钉；见 handoff §3）；abc **356,468/24,324**（L6 壳）、宿主 297,888（`08abe185…`）、导出 **151**；15 `.so` / 258 zip） |
| `device-test-kit.tar.gz`（kit #41，2026-10-03 发布） | 606151881 | **376,036,502** | **`bed460ae…`**（sidecar 606161455 / `2a95e764…`；树 `7ce1946e…`；`SHA256SUMS` 17 项 / 1,517 B / `421a819c…`） | 7 hap（承 #40；AOT 段用本轮 AOT 资产（rc.2 pack `-r2`，撤 rc.1 钉；见 handoff §3）；abc **356,140/24,324**（MULTI-OVERLAY-FULL 壳）、宿主 293,792（`8d67def3…`）、导出 **150**；15 `.so` / 257 zip） |
| `device-test-kit.tar.gz`（kit #40，2026-10-02 发布） | 605346629 | **375,836,470** | **`31ab8732…`**（sidecar 605372761 / `9b051247…`；树 `e950de54…`；`SHA256SUMS` 17 项 / 1,517 B / `7667b6bd…`） | 7 hap（承 #39；AOT 段用本轮 AOT 资产（rc.2 pack `-r2`，撤 rc.1 钉；见 handoff §3）；abc **342,160/24,324**（未变）、宿主 293,792（`384e552a…`）（未变）、导出 **150**；FIX-JSCALL 切片） |
| `device-test-kit.tar.gz`（kit #39，2026-10-02 发布） | 605039193 | **375,765,521** | **`e95eed49…`**（sidecar 605058022 / `e5fc82de…`；树 `932e7955…`；`SHA256SUMS` 17 项 / 1,517 B / `f7871fa8…`） | 7 hap（承 #38；AOT 段用本轮 AOT 资产（rc.2 pack `-r2`，撤 rc.1 钉；见 handoff §3）；abc **342,160/24,324**（FIX-BACKSIZE 壳）、宿主 293,792（`384e552a…`）、导出 **150**） |
| `device-test-kit.tar.gz`（kit #38，2026-10-01 发布） | 602780725 | **375,641,619** | **`ced5583f…`**（sidecar 602782257 / `8982fad0…`；树 `307004e1…`；`SHA256SUMS` 17 项 / 1,517 B / `9a07ddbf…`） | 7 hap（承 #37；AOT 段用本轮 AOT 资产（rc.2 pack `-r2`，撤 rc.1 钉；见 handoff §3）；abc **341,560/24,324**（FIX-WVP 壳）、宿主 293,792（`4e9f3c3e…`）） |
| `device-test-kit.tar.gz`（kit #37，2026-10-01 发布） | 602091003 | **375,652,577** | **`3a7259d6…`**（sidecar 602092652 / `7db60a77…`；树 `ab517b57…`；`SHA256SUMS` 17 项 / 1,517 B / `1ce87838…`） | 7 hap（承 #36；AOT 段用本轮 AOT 资产（rc.2 pack `-r2`，撤 rc.1 钉；见 handoff §3）；abc **339,964/24,324**（字节不变）、宿主 293,792（`4e9f3c3e…`）） |
| `device-test-kit.tar.gz`（kit #36，2026-10-01 发布） | 601446043 | **375,627,841** | **`9eb9cecf…`**（sidecar 601448752 / `4d7062c3…`；树 `9764827c…`；`SHA256SUMS` 17 项 / 1,517 B / `d643493c…`） | 7 hap（承 #35；AOT 段用本轮 AOT 资产（rc.2 pack `-r2`，撤 rc.1 钉；见 handoff §3）；abc **339,964/24,324**） |
| `device-test-kit.tar.gz`（kit #35，2026-09-30 发布） | 以 release 为准 | **375,629,423** | **`419d42e2…`**（sidecar `d7e79d39…`；树 `d3b1b317…`；`SHA256SUMS` 17 项 / 1,517 B / `2dd447a7…`） | 7 hap（承 #34；AOT 段用本轮 AOT 资产（rc.1 pack 钉注见 handoff §3）；abc **339,164/23,516**） |
| `aot-haps.tar.gz` | 592465115 | 17,093,146 | `91e1b9d3…` | `hello-maui-app-aot{,-unsigned}.hap`＋README（**已内置桥宿主 `bb51826e…`**，开箱 `aot=1`，见 §2.2） |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 593868367 | 196,898,796 | `9b0506fa…`（sidecar `c0b86645…`；README `4cd711df…`） | 5 个 harmony-flavor hap（壳 **291,628 B / `a637a513…` @13.0.1.0，overlay 真编译**；`MapOverlay.ets`/LiveView sink 在包内）＋README；**前置 = 自备重签材料 + AGC 开通/权益**（Map 地图服务＋签名指纹 / LiveView TIMER 权益 / Push/Account），判定见 §2.5。旧 A1 件 592541627 / 196,118,871 / `f7a4faa2…`（abc 263,784 / `d3a7b718…`）**无 overlay 模块记录**，已 clobber 替换 |
| `ohos-interpreter-pack-rc2b.tar.gz`（**当前；INTERP-NULL 修复 + WX-PATCH2，首帧**） | 606999003 | 2,410,595 | `5974430509…` | `native/libcoreclr.so`（`4b30a4c1…` / sha `e150558a…`）＋`libclrinterpreter.so`（`11fc5052…` / sha `3e4b4d10…`）＋README/sidecar；配 #42 宿主（JITFORT + 8 MB 栈）使用；首帧已达成（`canvas presented`） |
| `ohos-interpreter-pack-rc2.tar.gz`（**rc2 旧件，保留**） | 605924427 | 2,409,070 | `34709a94…` | rc.2 重建但未含 INTERP-NULL 更正与 WX-PATCH2；仅作历史对照 |
| `ohos-interpreter-pack.tar.gz`（**rc.1 旧件，保留**） | 590052493 | 2,419,988 | `a10699b3…` | 其记录的 `coreclr_initialize+440` 崩溃已更正诊断（见 `2026-10-02-ohos-interp-fix.md`）；仅作历史对照 |
| `tester-run.sh` **v13**（当前） | **594519342** | **137,113** | **`2caa06bd…`**（v12 = 593961018 / 126,658 / `87763a3e…` 为 #30 值） | v12 = `runtime_mode` 清单键（`libs/<abi>/runtime-mode.txt`）+ file>manifest>default 回退 + 清单 interp 的 Run C（见 §2.0）；v11 = 119,452 B / `2355e493…`（`--mode-matrix` + `--a11y-probe`）、v10 = 109,227 B / `714ae9b5…`、v9 = 75,917 B / `3c2d33bf…`（`aot=`/`interp=` 采集）、v8 = 73,375 B / `6ca2093e…` |

## 0. 四态矩阵

| 态 | 取件/前置 | 关键日志（execmem 文件） | 判定 | 回传 |
|---|---|---|---|---|
| JIT | kit #30 stock hap（默认 `runtime-mode.txt=jit`；#28 快照同流程） | `xwe=0 source=default`、`runtime-mode=jit source=manifest|default`、`probe: 1=OK`、`aot=0 dir=…` | `1=OK` 且 managed 运行 → JIT 可用；`1≠OK` 或 SEGV/`mprotect` 拒 → 走 `xwe.txt=1` A/B | tar |
| AOT | aot-haps（已内置桥宿主）＋重签 | `NativeAOT payload … aot=1` | managed 输出，且**无** `The application to execute does not exist` | tar |
| 解释器 | interp pack 替换 payload＋`interp.txt`=3＋重签（或清单 `runtime-mode.txt=interp` 的包） | `interp=3 source=file`（清单包为 `runtime-mode=interp source=manifest` + `interp=3 source=manifest`） | maps 含 `libclrinterpreter.so`、匿名 `r-x` 照录（Precode stub 风险，不得改策略）、managed 输出 | tar＋maps |
| 渲染/交互 | 任一态起来后 | —（功能性） | ①首帧 ②触摸→handler ③导航 ④列表/WebView | 截图/录屏/日志 |

## 1. 判定树（自上而下；先证跑通，再判模式）

1. `probe: 1=OK`？否（`1=1|12|13|38` 或启动 SEGV/`mprotect` 拒绝）→ 写 `xwe.txt=1` 复跑 A/B，两轮都记录；仍未通按崩溃分支取证。
2. 应用 managed 起来了（`[maui] openharmony build …`＋首帧）？否 → 按崩溃分支（applib/dlopen/bootstrap + `aot=`/`interp=` 行）取证，不进入后续态。
3. `aot=1`＋managed 输出＋无 `The application to execute does not exist`？是 → AOT 直启成立；若见 `bridged start_app … JIT payloads only` → 误用了旧的 R2-2 资产（现资产已内置桥宿主，应无此行）；aot 标记缺库时应见 `runtime-mode=aot but …; falling back to the JIT route`（显式回退，不崩）。
4. `interp=3 source=file`（清单包 `source=manifest`）＋maps 含 `libclrinterpreter.so`？是 → 解释器激活；匿名 `r-x` 只计数（`Precode`/UMEntryThunk 残余先记录）。
5. 之后按 §2.4 做四项功能性判定；每态单独一轮，不混轮。

## 2. 精确步骤 / 期望 / 回传

### 2.0 一键执行（v10 `--mode-matrix`，推荐入口）

```sh
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

一条命令跑四个 Run（每个 Run 是本脚本的独立子轮：kit 校验与 bundleName 白名单照走，**任一步失败只记录、不中断其余**）：

| Run | 做什么 | 前置资产 |
|---|---|---|
| A | JIT stock：卸载+安装主 hap → 启动 → 录 `--capture` 秒 | kit（必需） |
| B | XWE A/B：写 `<files>/xwe.txt=1` → `aa force-stop` → 启动/录制 → 清理 `xwe.txt` | kit |
| C | 解释器：校验 `--interp-pack` sha → 换入 `libcoreclr.so`+`libclrinterpreter.so`（`--interp-overlay` 可换成指定脚本）→ 装变体 hap → 写 `<files>/interp.txt=3` → 启动/录制 → 清理 + 重装 stock；**v12**：主 hap 清单声明 interp 时不需资产（直接装 stock hap、不写 `interp.txt`，摘要 `3(manifest)`） | `--interp-pack`（或已重签的 `--interp-hap`；或清单 interp 的主 hap） |
| D | AOT：校验 `--aot-haps` sha → 安装 `hello-maui-app-aot*.hap` → 启动/录制 → 重装 stock | `--aot-haps` |

产出 `<out>/mode-matrix/summary.txt`（每 Run 一份 `tester-report-*.tar.gz` + `mode-matrix/<run>.log` 在同一目录）：

| 键 | 含义 |
|---|---|
| `run_<x>_install` / `run_<x>_start` / `run_<x>_alive` | 安装结果（ok / code:9568297 / …）、启动结果、存活检查 |
| `run_<x>_aot_route` / `run_<x>_interp_mode` / `run_<x>_runtime_mode` | `0|1|0+1|1(manifest)|<unavailable>` / `<v>(file|manifest|default)|<unavailable>` / `<v>(hap)|invalid(...)|<absent>` |
| `run_<x>_probe_1` | 宿主 `OHOS_DOTNET probe: 1=` 的取值（JIT 可用性第一判据） |
| `run_<x>_xwe` | `xwe=0` / `xwe=1`（A/B 对照） |
| `run_<x>_frame` / `run_<x>_crash` | 首帧关键字命中（yes/no，未录到记 `<unavailable>`）/ 崩溃关键字（`SEGV_ACCERR`、`SIGSEGV`、`cppcrash`、`bootstrap failed`、`The application to execute does not exist`… 或 `none`） |
| `run_<x>_report` | 该 Run 的报告 tar 路径 |
| `run_c_via` / `run_c_overlay` / `run_c_hap` / `run_c_hap_sha256` / `run_c_signed` / `run_c_coreclr_check` | 清单路线（`manifest` = 主 hap 标记 interp、直接跑 stock hap，不写 `interp.txt`、不重打包）或变体构建方式（`builtin` / `script:<路径>` / `given`）、变体路径与 sha、是否重签、解释器宽字符串检查 |
| `interp_pack_sha256`/`interp_pack_check`/`interp_pack_members`、`aot_pack_sha256`/`aot_pack_check`/`aot_pack_members` | 可选资产校验（sidecar=ok；包内 `SHA256SUMS` 逐成员复核） |
| `preclean_*_rm` / `switch_*_write|_rm` / `force_stop` / `restore_install` | 切换文件清理与写删、重启、还原 stock 的执行结果（`ok`/`fail(rc=…)`） |
| `matrix_failures` / `conclusion` | 未通过计数 / 结论建议行（JIT 直起可用 / 需 xwe=1 / 解释器 3(file) / AOT aot=1） |

注意：

- `--dry-run` 只打印计划与资产清单（不碰设备，含必需资产列表）；无 `hdc` 时给出明确提示（退出码 3）。
- Run C 变体是本地重打包（**未重签**）；设备拒绝未签包时按 `自签说明.md` 重签后，用 `--interp-hap <重签 hap>` 重跑（其余 Run 不受影响）。
- `--capture` 的秒数对每个 Run 生效（默认 30，四态整轮建议 60）；矩阵轮不执行 `--probes`/`--extra-probes`（会提示）。

### 2.1 JIT（kit #47 stock 为 AOT 默认；JIT 走 `--runtime-mode jit` 自建或 ACL/豁免 —— JITFORT 承 #42；#32/#30 快照同流程）
```sh
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60 --out tester-report
hdc shell "echo 1 > /data/storage/el2/base/haps/entry/files/xwe.txt"   # A/B：仅当 probe 1≠OK/SEGV 才写
sh tester-run.sh --kit-dir ./device-test-kit --start --capture 60 --out tester-report-xwe1
hdc shell "rm -f /data/storage/el2/base/haps/entry/files/xwe.txt"
```
期望：`summary aot_route=0 interp_mode=0(default) runtime_mode=jit(hap)`；`xwe=0 source=default`（A/B 轮为 `xwe=1 source=file`）、`runtime-mode=jit source=manifest`（写过 `interp.txt` 的机器为 `source=file`）；**`OHOS_DOTNET jitfort: rc=0 errno=0 state=…` + 探针 `1=OK 2=OK`（#42 JIT 解锁）**与 `OHOS_DOTNET globalization: invariant=… icu=… source=…`（无 ICU 镜像自动 invariant）；`probe: 1=OK`；managed 输出＋首帧。
回传：`tester-report*.tar.gz`（A/B 两轮都发）。

### 2.2 AOT（aot-haps）
> **已内置桥宿主（AOT-RECUT，2026-09-27）**：资产内宿主 = kit #28 桥版 **269,216 B / `bb51826e…`**，
> `start_app` 直接探测 `lib<stem>.so` → `openharmony_app_main` 并记 `aot=1`；**无需换宿主**，
> 按《自签说明.md》重签后 `aa start` / 桌面启动即可判定（旧 R2-2 包才会打
> `bridged start_app supports JIT payloads only`）。**MS-MODE（2026-09-28）起**：用
> `-p:OpenHarmonyRuntimeMode=aot` 构建的包（标记 `runtime-mode.txt=aot`）走同一探测；标记为 aot 而
> `lib<stem>.so` 缺失/不可加载时，宿主记 `runtime-mode=aot but <path> …; falling back to the JIT route`
> 并回退（不崩、不再静默穿透）。
```sh
sh tester-run.sh --kit-dir ./device-test-kit --hap ./hello-maui-app-aot-signed.hap --install --start --capture 60 --out tester-report-aot
```
期望：`summary aot_route=1`；`NativeAOT payload … aot=1`；managed 输出/首帧；无 `The application to execute does not exist`；hap 内无 `libcoreclr.so`/`libhostfxr.so`（AOT 形态）。
注意：AOT hap 的 bundle 与 kit 主包相同（`com.example.hellomauiapp`），装 AOT 会顶替 JIT 主包；回 JIT 需重装 kit 主 hap。

### 2.3 解释器（interp pack）
```sh
# #42 起用 rc2b pack（rc2/rc.1 旧 pack 保留作对照）
tar xzf ohos-interpreter-pack-rc2b.tar.gz && (cd ohos-interpreter-pack-rc2b && sha256sum -c SHA256SUMS)
# 取 hello-maui-app-unsigned.hap：libs/arm64-v8a/ 内替换 libcoreclr.so ＋ 加入 libclrinterpreter.so；重签
hdc shell "echo 3 > /data/storage/el2/base/haps/entry/files/interp.txt"
sh tester-run.sh --kit-dir ./device-test-kit --hap ./hello-maui-app-interp.hap --install --start --capture 60 --out tester-report-interp
hdc shell "pidof com.example.hellomauiapp"; hdc shell "cat /proc/<pid>/maps" | grep -E 'libclrinterpreter|r-x.*\[anon' > maps-interp.txt
hdc shell "rm -f /data/storage/el2/base/haps/entry/files/interp.txt"
```
期望：`summary interp_mode=3(file)`（清单包为 `3(manifest)`、`run_c_via=manifest`）；`interp=3 source=file`（清单包先记 `runtime-mode=interp source=manifest`、再记 `interp=3 source=manifest`；写过 `interp.txt` 时 file 覆盖标记）；maps 含 `libclrinterpreter.so`、匿名 `r-x` 计数照录；managed 输出；无 `SEGV_ACCERR`。
回传：tar（含 execmem）＋maps 摘录＋pack `sha256sum -c` 输出。

### 2.4 渲染/交互（任一态）
① 首帧（截图）→ ② 触摸→managed handler（日志/状态）→ ③ 导航（页面切换）→ ④ 列表滚动＋WebView 加载；各附截图或日志。

### 2.5 harmony 变体（`harmony-haps.tar.gz`，Map/LiveView 点亮的唯一打包入口）
> 壳 = HarmonyOS SDK 构建（包内即 harmony flavor：`MapOverlay.ets` + LiveView sink，**无需测试方自建壳**）；
> 前置 = 自备重签材料（自签会被 9568257/9568344 拒绝，属预期）＋ **AGC 开通/权益**（Map 地图服务 + 证书指纹；
> LiveView 实况窗 TIMER 权益 + 设备开关；Push/Account 按需）。5 个 hap 与 kit 同包名，装 harmony 会顶替 kit 主包；
> 回 JIT 重装 kit hap（同 §2.2）。静态形态（交付方逐 hap 断言 **102/102** + kit `verify-kit.sh --expected-abc 291628`
> KIT OK；与同提交默认 control 构建**仅 `ets/modules.abc` 不同**）：abc **291,628 B/`a637a513…`**（PANDA 13.0.1.0，
> 含 `entry/ets/map/MapOverlay` 模块记录 + `mapOverlayView`/`markerClick`/`cameraIdle` 符号）、libs 269
> （14 `.so`+254 payload+marker）、hap 内宿主 285,600 B/`5248c6a9…`、`module.json` 与 kit #30/#31 MAUI 对应 hap 逐字节相同、
> 14 `.so` 均带 `.codesign`；默认 JIT payload 不变（**AOT 走 §2.2 的 `aot-haps.tar.gz`**）。
> **更正（MAPFIX 2026-09-28）**：旧 A1 件（abc 263,784 B/`d3a7b718…`）的「`MapOverlay.ets` 真编译」不成立 ——
> 模块仅被复制、从未进编译图（abc 无模块记录，bit1 只能为 0）。本版由构建脚本向 harmony 的 `Index.ets`
> 副本注入静态 import 并修好 `MapOverlay.ets:135` 的 NodeController 无参构造，CI 门
> `HARMONY_REQUIRE_MAP_OVERLAY=1` 由 WARN 转绿；新 tar `9b0506fa…`（旧 `f7a4faa2…`）。
```sh
sh tester-run.sh --kit-dir ./device-test-kit --hap ./hello-maui-app.hap --install --start --capture 60 --out tester-report-harmony
```
期望：`IsOverlayAvailable=true`（flags bit1=1）、show/hide/区域/标记有真实地图视图与 `Ready`/`MarkerClick`/`CameraIdle`；
LiveView create/update/stop 出 TIMER 卡片（开关关 `-3`/`1003500004`、权益未批 `1003500005`）；Push/Account/Scan/Share 面板正常。
回传：截图/录屏＋状态原文＋AGC 开通/审批截图。

## 3. 回传物汇总
`tester-report-*.tar.gz`（`hilog/hilog-execmem.txt`＋`summary.txt`＋install/start 日志）＋解释器轮 maps 摘录＋重签说明；
AOT/解释器轮附被替换 .so 的 sha256。数字以 release「## Integrity」/ `.sha256` sidecar 为准（重签、重打包后必变）。
无障碍专项（可选）：`tester-run.sh` v13 `--a11y-probe` → `a11y/`（`selfcheck.txt`＋`hilog-a11y.txt`，`summary a11y_*`）；
逐项判定见 `2026-09-27-ohos-accessibility-device-verification.md`。

## 4. 分发形态建议（DECIDE-BASELINE，2026-10-03）

1. 产品/上架默认 **AOT**（`runtime-mode.txt=aot`，`lib<stem>.so` 探测；坚盾/无 ACL/手机域可用）。
2. JIT 仅两类可用域：a) debug/内测签名域（宿主 JITFORT 默认开，勿用于生产）；b) release/生产域已获 AGC ACL（`ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）或平台/厂商豁免。
3. 手机不开放 JIT ACL → 只发 AOT（或实验 interp）。
4. interp 不随主分发；以独立 pack（rc2b）供验证/兜底研究。
5. 包内 marker 三态 `jit/aot/interp`，宿主按 marker 探测 + 显式回退（aot 缺 `lib<stem>.so` → JIT 路，不崩）。
6. 坚盾守护模式 JIT 全局禁用（已授权亦然）→ 运行时须回落 AOT；文案不得承诺 JIT 可用。
7. 合规材料（jit-acl-prerec）：场景 = MAUI/.NET 自带 CoreCLR VM（CEF/Electron 先例）、代码随包签名、非热更新、W^X 说明；避免依赖未公开 prctl。
8. 内测分发用 MS-MODE/`make-mode-kit.sh` 逐模式出包；AOT 兜底包常备。

### §4 执行项闭合（AOT-DEFAULT，2026-10-03）

- ✅ **出包开关落地**：`ohos-workload/scripts/make-device-test-kit.sh --runtime-mode aot|jit|interp`（**默认 aot**；
  `DEVICE_TEST_KIT_RUNTIME_MODE` 同义）；jit 保留（默认 kit 目录/out 加 `-jit` 后缀）；interp 拒入主包并指向
  `scripts/make-mode-kit.sh --mode interp --interp-pack <dir>` 独立 pack。AOT 变体 = 5 MAUI hap 用
  `publish-aot.sh` 配方（`PublishAot`/`PublishAotUsingRuntimePack`/`NativeLib=Shared` + `OpenHarmonyUIPage` +
  `InvariantGlobalization`；DEVCOMPAT 默认与静态 web 资产 staging 保留），kit 根 `runtime-mode.txt` + 每 hap
  `libs/arm64-v8a/runtime-mode.txt` 标注；`--dry-run` 打印四种发布命令；`check_mode_hap` 逐 hap 断言 marker +
  AOT 应用库。ohos-workload 侧 `selftest-make-device-test-kit.sh` **37 项**绿。
- ✅ **verify-kit/期望值同步**：模式感知（aot ≥3 `.so` + `lib<stem>.so` 必需 + `dotnet.zip` 9 项 + 无
  `libcoreclr.so` + kit/hap 模式交叉校验 + payload marker 按形态判定；jit 历史 15/258 不变）；S16 AOT 夹具 + 5 个
  负例；`selftest-verify-kit` **129 项**全绿。新 hap 指纹见 `2026-10-03-ohos-three-path-baseline.md` §5。
- ✅ **AOT 默认 kit 变体（旁路 tar）**：`device-test-kit-aot.tar.gz` **47,344,695 B / `13eb41f2…`**（树
  `ed5d951f…`、SHA256SUMS 16 项、verify-kit KIT OK 0 FAIL/0 WARN）；正式 7-hap kit #43（含 Blazor 组件）
  随下一批量出，本轮变体旁路 + 说明。
- ✅ **真机复核**：AOT 变体件重签装机 → `aot=1` + 首帧；与 JIT（kit #42 件）对照 = 同首帧 3534 ms / 同 fps 17.7 /
  0 崩溃，AOT VmRSS −74.8 MB（15 s）~−84.1 MB（42 s）；表与证据行见上述 §5。
- ⏳ **JIT 变体 tar 未出**：`--runtime-mode jit` 已过 dry-run + selftest（发布配方/JIT marker/命名），按需可出。
