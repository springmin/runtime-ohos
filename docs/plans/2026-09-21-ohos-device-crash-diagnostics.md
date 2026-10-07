# 设备侧启动崩溃：诊断与重测包（JsError / exit 254）

> **2026-10-07 更新（kit #52，当前）**：kit #52 = **kit #51 全量（MULTIWINDOW-L2 并存整合 + SEC-SCAN-6 A/B/C + L2CAP；承 #50 MULTIWINDOW-L M1–M4/SEC-SCAN-5a/5b/5c/polish-49 与 #49/#48–#45）** + **MULTIWINDOW-L3 N=2 多子窗产品化（M1–M4 全并入主线）** + **L3 尾项（①a11y 分区 release：导出 163→164；②子窗 hybrid/Blazor 资产桥：离线绿、真机未抽验）**：①**M1 会话注册表**（壳 `sub-N` 最低空闲复用、`SUB_WINDOW_MAX=2`、create/close/move/resize/show/text-focus 全按 `cmd.surfaceId` 路由、容量 801 诚实拒绝、末会话全局 suspend；maui `MaxManagedSubWindows=2`）；②**M2 每窗身份握手/生命周期**（会话 `generation` + per-child claim 表 + managed op7 ack（`surfaceId+id+gen` 全等才发布 identity）；错名/无 claim fail-closed、旧代际忽略；宿主窗口 op 上限 `kSubWindowLastOp 5→7`）；③**M3 每窗服务**（单键盘焦点窗 IME + 切窗 `text blur forwarded`、per-window alert 槽/几何、Back 焦点窗 + modal 先消费、per-instance a11y 分区复用）；④**M4 按窗 child ArkWeb 槽池**（`child:<window>|<op>` 路由 + `ChildWebWindowSinks` + `unregisterChildWebSink`；maui `WindowTagged`/4 参 codec 按 `(windowIndex,slot)` 分派 ⇒ 两窗同 slot 0 各回各窗、未知窗 fail-closed）；⑤尾项①**a11y 分区 release**（`ohos_host_accessibility_table_release` + 新导出 `ohos_host_accessibility_release_for`；关窗 hook 释放命名分区 + 重置 per-instance 注册态；selftest 15/15 + 双红控）；尾项②**子窗 hybrid/Blazor 资产桥**（`onInterceptRequest` serving + `window.external` shim + Blazor bootstrap + bit30 child invoke（`ChildInvokeFlag/Encode/TryDecodeChildInvokeRequestId`）+ 同槽 fail-closed；离线 +3 checks）。真机 HAD-W32（OH 7.0.0.111）N=2：**windows=2**（`sub-1.g1`/`sub-2.g2`、双端 `identity confirmed`、双 a11y `status=1`）+ **输入分窗**（sub-2 tap=1 / sub-1 ×2 tap=2 不串）+ **定向关**（`closed: surface=sub-2 remaining=1`）+ **重开 gen 递进**（`sub-2 gen=3`）+ churn ×20（pid 恒定、WMS/会话残留 0）+ 主窗零回归（59.6–60.0 fps）；两窗各自 `CHILD-WEB-1/2` + `CHILD WEB TAP 1/2` 不串、**40 min 双窗 soak**（RSS 284–363 MB 无单调增长、线程 70–71、0 crash/fault）；**统一参数**：`sh verify-kit.sh` 裸跑即绿 / `--expected-abc 534192`（#51=473048、#50=436808、#49=414532 旧值 FAIL 属预期）；**降级/人工卡（明示，不判失败）**：a11y selfcheck 3 s 探针 `nodes=0`（首发布时机）· **子窗 IME 实敲人工卡**（uitest 无子窗注入面）· uitest Back/alert 注入限制（子窗 Back 未送达、alert 无样例触发点）· 子窗 a11y 动作 e2e 平台限（读屏服务不可得、外部复跑）· 子窗 B6 导航否决未接（外部导航直载）· hybrid/Blazor 资产桥真机未抽验 + 多窗同槽 invoke fail-closed · 子窗池满（>2 控件）不挂载与就绪队列溢出丢 1 行日志 · ArkWeb `loadData` 裸 `#` 截断（平台共性）· SEC-6 原生 a11y 分区常驻（有界）· 应用级 N=2 为壳契约（平台上限 255）；**预签已刷新（#52 件：68,732,127 / `5abf7629…`，asset 618854752；sidecar 88 B / `2d8390bf…`，asset 618855844）**；壳 abc **534,192（`e6516424…`）**/24,324（`798b2477…`）、宿主 **367,520（`ad7ab986…`，导出 164/164、UND 252）**、套件 **731/734 floor 714**（超集 690+11+15+7+8）；发布实测 tar **68,853,027 / `9e60fdc0…`**、树 `c1fa6421…`、sidecar `d10ae2e7…`、`SHA256SUMS` 18 项 / 1,600 B / `fbc035f8…`；bundle **73,199,515 / `5a00331f…`**（sdk 锚 **`9609da7a47`**）；maui `277967cc56`、ow `0685d7b`；CI 5/5 @ `0685d7b`（interaction 37625969429 / pixel 37625969211 / host-export 37625969178 / ridgraph 37625969029 / markdownlint 37625969127）+ sdk run `37631943842`；数字以 release「## Integrity（kit #52）」与随包校验为准；判定点 = `docs/plans/2026-10-07-ohos-tester-handoff-kit52.md`（承 #51 交接卡）。
>
> **2026-10-07 更新（kit #51，上一版）**：kit #51 = **kit #50 全量（MULTIWINDOW-L M1–M4 + SEC-SCAN-5a/5b/5c + polish-49，承 #49 MULTIWINDOW-M/SEC-SCAN-4 与 #48–#45）+ MULTIWINDOW-L2 并存整合（a 子窗 a11y provider + b 子窗 ArkWeb 第二宿主）+ SEC-SCAN-6 A/B/C + L2CAP 平台容量探针**：①a 线（ow `c562a32`/`f5a892a`、maui `9faacf3`/`ba7581022c`）：`host_a11y_table.c/h` 节点表按 provider instance 分区（legacy 主分区逐字保留、`*_for(instance)` 命名分区 ≤8、instance ≤63 可打印 ASCII）、`OH_ArkUI_AccessibilityProviderRegisterCallbackWithInstance` + 带窗动作 `set_window_action_listener`、壳 `SubWindow.ets` NodeContent/ContentSlot 双点 attach；导出 157→**163**；真机 HAD-W32（OH 7.0.0.111）**W0 并存 PASS**（`subwindow a11y provider status=1 instance=sub-1`，主窗 status=1/72 节点不回退）与 **W2 自检 PASS**（`subwindow a11y selfcheck status=1 nodes=10 instance=sub-1`，主窗 72 节点零回归）；**动作 e2e 平台受限**（镜像无读屏/第三方 a11y 服务，`AccessibleManagerService accessible: 0`；离线 7 checks + 红控 4 条覆盖）；②b 线（ow `094ad51`/`3c486cf`、maui `086d358`/`2e441c35c9`）：`host_napi.cpp` child web sink（`child:` 前缀按窗路由并去前缀、主路径字节不变；`registerChildWebSink`/`registerChildWebEvalSink` NAPI 探测降级）、新 `OpenHarmonyChildWeb.cs`（sub-N 槽池 Max=2、64 条预就绪队列、`w:<win>|capacity|<n>` 就绪）、切片 5 文件按窗路由；首轮暴露 **capacity wire 不一致**（state 携 `capacity` 但 managed 只认 `capacity|<n>` → 事件被丢、队列不冲刷）→ 修复壳发 `w:<win>|capacity|<n>` + 双侧兼容 URL 形 + 套件 `capacity wire` pin；真机闭环（JIT）`child web host registered`→`child web capacity: sub-1 2`→`child web cmd: data s0`→`slot create/attached`→`CHILD WEB OK`→`navigated: Success`→`eval title`→click 读回 `CHILD WEB TAP`；主窗零回归（双窗 60.0/60.0 fps、close slot destroy + WMS 残留 0、0 新 fault）；③**SEC-SCAN-6 A/B/C 全闭**（A 分区分配仅 `begin_for`、B 主窗 id 在子通道拒绝、C 关窗 close hook 清 child Capacity/Pending + a11y frame/first-publish 标记，+2 checks、红控 3×assert=False）；④**L2CAP 容量探针**：平台并发子窗上限 **255**（第 256 个 `1300002`、3 轮一致；destroy 255/255、残留 0、可恢复）⇒ **应用级 N=1 为壳契约而非平台限制**（产品化另立项、本波不动壳单实例/801 契约）；⑤**降级声明（明示，不判失败）**：子窗 a11y **动作 e2e 平台限制**（读屏服务不可得，外部复跑）、**子窗 ArkWeb hybrid/blazor 资产桥显式拒绝**（不建组件、命令丢弃、eval 即错；下波壳侧 `onInterceptRequest` serving + 按窗注册回放）、**子窗 IME 实敲人工卡**（uitest 无子窗注入面，`2026-10-06-ohos-multiwindow-l-m4.md` 末节）、子窗 B6 导航否决未接（外部导航直载）、子窗池满（>2 控件）不挂载与就绪队列溢出丢 1 行日志、ArkWeb `loadData` 裸 `#` 截断平台注记、SEC-6 余留（原生 a11y 分区常驻、有界）；**预签已刷新（#51 件：68,447,288 / `e9fb1e90…`，asset 617093322；sidecar 88 B / `96948b04…`，asset 617094016）**；壳 abc **473,048（`298622c0…`）**/24,324、宿主 **347,040（`36acfc1d…`，导出 163/163、UND 250）**、套件 **688/690 floor 670**（超集 663+7+18+2）；发布实测 tar **68,550,333 / `e5f6541c…`**、树 `a06d3897…`、sidecar `5c471871…`、`SHA256SUMS` 18 项 / 1,600 B / `5f8c1512…`；bundle **73,147,751 / `f4b4fe8d…`**（sdk 锚 **`a00e810c92`**）；CI 5/5 @ `696ebc0`（interaction 37548888210 / pixel 37548888313 / host-export 37548888169 / ridgraph 37548888051 / markdownlint 37548888104）+ sdk run `37553127808`；数字以 release「## Integrity（kit #51）」与随包校验为准；判定点 = `docs/plans/2026-10-07-ohos-l2-consolidate.md` + `docs/plans/2026-10-06-ohos-tester-handoff-kit50.md`（卡片沿用）。
>
> **2026-10-06 更新（kit #50，上一版）**：kit #50 = **kit #49（MULTIWINDOW-M + SEC-SCAN-4 + 承 #48 CG2-R2R/AOT-STARTUP/FPS48/MULTIWINDOW-S/FIXRR 与 #47/#46/#45 全量）+ MULTIWINDOW-L 全套（M1–M4 + SEC-SCAN-5a/5b/5c）+ polish-49**：①**M1 宿主每窗 surface 注册表**（window-id claim/release/route；registry 84/84、bridge 26/26）；②**M2 切片 per-window renderer**（每窗 `OpenHarmonyWindowSurface`/`Renderer` + `OpenHarmonyWindowHost`；`RouteSurface/RouteTouch/RouteFrame` 按 window-id 路由；headless 双窗 22 checks）；③**M3 子窗挂 XComponent + managed surface id**（第二 MAUI 视觉树；真机 `sub-1` 720×480 `first frame=True`、触摸按窗、close 回收、reopen 同 id、churn ×20 无残留）；④**M4 每窗焦点/IME/生命周期/a11y 分区/pinch**（壳 ACTIVE/INACTIVE → per-window `IWindow.Activated/Deactivated/Stopped/Resumed` 状态机；每窗 a11y 影子帧、主 provider 零变化；per-window pinch 经 `ohos_host_notify_window_pinch` → 该窗 renderer，导出 156→**157**）；**SEC-5a/5b/5c**（unregisterXComponent 失败闭合 + surface 事件按组件路由；window-id 校验失败闭合 + registerXComponent 身份；主窗→子窗文本 thunk 仅主窗、跨窗文本泄漏修复）；**polish-49**（`ParseSubWindowOptions` 三可选布尔补齐 → 真机 E=0；close WARN 平台内部仅注释；Home 键经焦点丢失链 suspend：INACTIVE→600 ms 宽限、`clearSubWindow` 取消定时器）；真机 HAD-W32/W24（2in1）：双窗稳态 **60.0/60.0 fps**、40 min 长稳（RSS 净 −34 MB、pid 恒定）、churn ×20（WMS 残留 0）、JIT 与 AOT 各过轮；**降级声明（明示，不判失败）**：子窗 a11y provider（主 provider 零变化、子窗影子帧本地保持）、子窗 ArkWeb 第二宿主（槽池留主窗、子窗 web 不挂载、无回归）、平台级多子窗上限未探（应用级 N=1 失败闭合）、**子窗 IME 实敲人工卡**（uitest `uiInput` 无子窗 XComponent/多点注入面，步骤见 `2026-10-06-ohos-multiwindow-l-m4.md` 末节）、SEC-5c B–F 报告级（B 子窗 prompt 键盘全局化 / C 状态机顺序假设 / D Back·按键无消费者 / E pinch 非有限几何 / F 子窗 a11y 帧常驻）；**预签已刷新（#50 件：68,157,557 / `028d29f4…`，asset 615517779；sidecar 88 B / `02397318…`，asset 615518466）**；壳 abc **436,808（`289a5e5d…`）**/24,324、宿主 **330,656（`fdeb94eb…`，导出 157/157、UND 249）**、套件 **661/663 floor 643**；发布实测 tar **68,264,136 / `d70dc786…`**、树 `b4b5055c…`、sidecar `2ffb3b6a…`、`SHA256SUMS` 18 项 / 1,600 B / `98fd0dd2…`；bundle **73,119,180 / `6a83c0f3…`**（sdk 锚 **`a3417a5489`**）；CI 5/5 @ `afa6d7a`（interaction 37460790068 / pixel 37460790072 / host-export 37460790087 / ridgraph 37460790138 / markdownlint 37460790028）+ sdk run `37465689708`；数字以 release「## Integrity（kit #50）」与随包校验为准；判定点 = `docs/plans/2026-10-06-ohos-tester-handoff-kit50.md`。
>
> **2026-10-05 更新（kit #49，上一版）**：kit #49 = **kit #48（CG2-R2R + AOT-STARTUP + FPS48 + MULTIWINDOW-S + FIXRR；承 #47 FIX-A11YFLYOUT/FIX-PREEMPT-RAW 与 #46/#45 全量）+ 应用内子窗（MULTIWINDOW-M）+ a11y 密码脱敏（SEC-SCAN-4）**：①**MULTIWINDOW-M**（maui 切片 `b093e33825` + ohos-workload `be70a73`/`16df9a3`）：壳 `Window.createSubWindowWithOptions` 子窗控制器——命令 0 create/1 move/2 resize/3 show/4 hide（无公开 hide API：如实回 Failed 801）/5 close，事件 0 created…10 resumed；`pages/SubWindow.ets` 壳绘 named-route（`ohos_dotnet_subwindow`，`WindowProperties.name` move guard，touch/drag hilog；无 create 零分配）；主窗 HIDDEN/SHOWN 转 suspended/resumed + 挂起期命令抑制；宿主 `registerSubWindowSink`/`notifySubWindowEvent` NAPI + `ohos_host_sub_window_command`（op 99 可用性探针）/`ohos_host_sub_window_event_listener`（导出 151→**153**）；切片 `OpenHarmonySubWindow`（IsSupported/IsOpen/IsVisible/IsSuspended/IsContentReady/WindowId/Bounds + Changed/Touched，Utf8JsonWriter/JsonDocument AOT 安全，离设备退化 false/无操作）；真机 HAD-W32（2in1）：`app://subwindow/demo` create **id=344（120,160 720×480）** → page ready `name=ohos_dotnet_subwindow drag=on` → move **420,360** → resize **900×600** → close（截图 mw-seq1/2/3）；`app://subwindow/open` id=346 → touch `OHOS_MAUI_SUB touch #57`、swipe `drag #51 → 269,259`（PanGesture 自移动）；主窗 HIDDEN/SHOWN → `subwindow suspended/resumed`，主页面 `canvas presented (2090×1324) avg=16ms max=21ms`（60fps），无新 fault；诚实边界：单 surface/renderer（子窗内容为壳侧 ArkUI 自绘，非第二 MAUI 视觉树；per-window surface/renderer 属 L）；②**SEC-SCAN-4**（maui `5f3efd55e5`）：a11y 影子树不再发布密码明文——`OpenHarmonyAccessibility` 对 `IEntry{IsPassword}`/平台 `IsPassword` 走同一 `MaskPassword` 发布等长圆点；套件 +2 pin（`a11y-password` 明文不得出现 + `draw cull edge` 零尺寸/shadow 外延/屏外 Image 不得剔除），离线红/绿负控（还原修复 → plainHidden=False assert=False，exit 134）、设备未验证；另 6 项报告级（WebView 区 2 / 供应链 1 / 加固 3）；③承 #48：**R2R/JIT 启动**（CG2-R2R：JIT 冷启 1031→710 ms、in-proc present 575→307；interp R2R=0 FIXRR）、**AOT 首帧**（796→534 ms、attach→surface 239→13）、**帧率投票 60**（46.2→60.0 fps）、**多窗 S**（2in1 3120×1955）、**FIX-A11YFLYOUT**（nodeCount 1→70）、**FIX-PREEMPT-RAW**（`[maui-capacity]`）与 #46/#45 全量（INTERP-DRAW2、FIX-A11YBUTTON、AUTODISCONNECT、INTERP-RENDER、动态槽 MAX/HOT 4/2、AOT 默认、FRAMEPACING）；**预签已刷新（#49 件：67,807,185 / `56aaf08f…`，asset 612929512；sidecar 88 B / `4ba00cf8…`，asset 612930421）**；壳 abc **414,532（`e016db13…`）**/24,324、宿主 **301,984（`cf4cc706…`，导出 153/153）**、套件 **607/609 floor 589**；发布实测 tar **67,888,851 / `477974bb…`**、树 `8d03cb4c…`、sidecar `3803b3db…`、`SHA256SUMS` 18 项 / 1,600 B / `b142639d…`；bundle **73,085,186 / `7d06e781…`**（sdk 锚 **`7abaf8132f`**）；CI 5/5 @ `e0803bedad`（interaction 37321721695 / pixel 37321721683 / host-export 37321721786 / ridgraph 37321722030 / markdownlint 37321721810）+ sdk run `37331391778`；数字以 release「## Integrity（kit #49）」与随包校验为准；判定点 = `docs/plans/2026-10-05-ohos-tester-handoff-kit49.md`。
>
> **2026-10-05 更新（kit #48，上一版）**：kit #48 = **kit #47（FIX-A11YFLYOUT + FIX-PREEMPT-RAW；承 #46 INTERP-DRAW2/FIX-A11YBUTTON） + R2R/JIT 启动（CG2-R2R） + AOT 首帧省时（AOT-STARTUP） + 帧率投票 60（FPS48） + 多窗 S（MULTIWINDOW-S） + FIXRR**：①**CG2-R2R**（sdk-ohos `crossgen2-packs-11.0.0-rc.2`，43,792,647 / `6bb8a375…`，folder feed）：JIT `PublishReadyToRun=true` 冷启 **1031→710 ms（−31%；n=3）**、in-proc present 575→307；interp 不执行 R2R 原生码且付 +350 ms → host 在 `interp=3` 置 **`DOTNET_ReadyToRun=0`**（FIXRR，ow `08ccbe8`；runtime 对 `InterpMode>=2` 本就强制 `fReadyToRun=false`，显式行同效；JIT/混合 1/2 不变）；②**AOT-STARTUP**（ow `22ca602`/`372c35e`/`92ea222`）：隐藏 ArkWeb 覆盖层**首用才挂载** + 宿主对相同 app-context **跳过 surface 重放**，CEF 初始化（~240 ms）移出首帧路径 → AOT AMS→首帧 **796→534 ms（−262，−33%）**、Main→首帧 386→151、attach→surface 239→13；JIT/interp 不回归；③**FPS48**（ow `67a1de8`）：宿主注册 XComponent 时声明期望 60 Hz（`{60,60,60}`）→ RS 60/30 仲裁消失，第二重绘窗口干扰态 5s 窗均值 **46.2→60.0 fps**（清净态 60.1；app 每帧 work 不变）；④**MULTIWINDOW-S**（maui `ed02203bfd` + ow `c5df1de`）：壳声明 `supportWindowModes` fullscreen/split/floating + `windowSizeChange`/`freeWindowModeChange` 订阅；切片 `CanArrangeSurface`（Created/Changed 尺寸>0 重排、Destroyed/0x0 保末帧）→ 真机 2in1 最大化 **2090×1394→3120×1955**（`surface state=Changed 3120x1885` → `canvas presented`）；套件 +2；⑤kit #47 全部保留（FIX-A11YFLYOUT nodeCount 1→70、FIX-PREEMPT-RAW `[maui-capacity]`、INTERP-DRAW2 60.1 fps、FIX-A11YBUTTON、AUTODISCONNECT、INTERP-RENDER、动态槽 MAX/HOT 4/2、AOT 默认、FRAMEPACING 60.00 fps）；**预签已刷新至 #48**（67,651,331 / `2f2f4c40…`，asset 612061141；sidecar 88 B / `50a1f38e…`，asset 612062470）；壳 abc **375,268（`9cd2b4c3…`）**/24,324、宿主 **297,888（`319db8e5…`，导出 151/151）**、套件 **599/601 floor 581**；发布实测 tar **67,735,148 / `5c22704f…`**、树 `6b2b493c…`、sidecar `1c51cdbc…`、`SHA256SUMS` 18 项 / 1,600 B / `a05caba0…`；bundle **73,053,084 / `3b62cee2…`**（sdk 锚 **`767c03ee71`**）；CI 5/5 @ `c42cfa43` + sdk run `37286847476`；数字以 release「## Integrity（kit #48）」与随包校验为准；判定点 = `docs/plans/2026-10-05-ohos-tester-handoff-kit48.md`。
>
> **2026-10-05 更新（kit #47，上一版）**：kit #47 = **kit #46（INTERP-DRAW2 + FIX-A11YBUTTON）+ FlyoutPage 无障碍（FIX-A11YFLYOUT）+ 抢占原文导出（FIX-PREEMPT-RAW）**：①**FIX-A11YFLYOUT**（maui 切片 `d5384d6cc3`）：`PushChildren` 补 `FlyoutPage.Detail`（恒入树）/`FlyoutPage.Flyout`（仅 `IsPresented`）分支（rc.1 FlyoutPage 非 `IContentView`，旧分支覆盖不到 → 只发布根）；headless 断言 `a11y-flyout detail/panel` + 负控制红，真机 `--a11y-probe` **nodeCount 1→70**；②**FIX-PREEMPT-RAW**（ohos-workload `f538c84`）：壳 `pollManagedStatus` 把 `dotnet-status.txt` 新增段中含 `overlay preempted/restored/replay` 的行以 **`[maui-capacity]`** 前缀直写 hilog（trim 时整文件回退）→ 真机低噪声复放取到 5 行原文（`preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`）；③承 #46：**INTERP-DRAW2**（面外剔除：interp draw 14.4→9.4 ms、33.9→60.1 fps、每帧 CPU −27%；JIT 无回归）、**FIX-A11YBUTTON**（自检按钮左下角 + 覆盖层之上，两态真机可达 `[523,1622][607,1668]`）；④承 #45：自动释放（FIX-AUTODISCONNECT）/INTERP-RENDER/动态槽（MAX/HOT 4/2 + 3 控件）/默认 AOT/FRAMEPACING 与 #42… 全部修复；**预签已刷新至 #47**（67,639,132 / `f58c4906…`，asset 610975429；sidecar 88 B / `c95344ac…`，asset 610976421）；壳 abc **370,240（`4b439e83…`）**/24,324、宿主 **297,888（`7b1694d9…`，导出 151/151）**、套件 **593/595 floor 575**；发布实测 tar **67,706,719 / `3d6bb58b…`**、树 `0f266636…`、sidecar `4adb0b60…`、`SHA256SUMS` 18 项 / 1,600 B / `6bbc2235…`；bundle **73,059,625 / `27c54c62…`**（sdk 锚 **`266b196106`**）；CI 5/5 @ `3de9a95fe0` + sdk run `37245230111`；数字以 release「## Integrity（kit #47）」与随包校验为准；判定点 = `docs/plans/2026-10-05-ohos-tester-handoff-kit47.md`。
>
> **2026-10-04 更新（kit #45，上一版）**：kit #45 = **kit #44（动态槽 SLOTS-DYNAMIC + 默认 AOT + FRAMEPACING）+ 自动释放（FIX-AUTODISCONNECT）+ 渲染门控（INTERP-RENDER）**：①**FIX-AUTODISCONNECT**（maui 切片 `189b87ca8a` + ohos-workload `64ee9c4`）：页面/ContentView/Layout 子树 watcher 驱动切片 `IOpenHarmonyOverlaySlotLifetime`——**移除 web 控件即发 hide 并释放槽位**（动态槽在壳内 `web slot destroy` 销毁；热对 [0,1] 保留组件）、**再挂回自动重领槽并重放 load/注册**（`web slot create`）；handler 保持连接、晚到注册被忽略；真机 kit 样例（无显式 DisconnectHandler）Remove C → `web slot destroy: 2`（12:40:50）、re-add → `web slot create: 2`（12:41:00）并恢复交互（c1–c5）；套件 **+3 pin → 587/589 floor 569**；②**INTERP-RENDER**（maui `7c731a7ca3` + ow `8ed35f4`）：布局门控（仅真实失效信号才 Measure/Arrange）→ **interp 22.0→30.1 fps（20.7→30）、meas 13.0→0.0 ms/帧、主线程 CPU 79.6–81.8%→65.5–70.5%（−13pt）**；JIT/AOT 60 fps 不变、draw/pres 不变、交互不变（Count 0→1）；③承 #44：动态槽 3 控件并发/释放重建、默认 AOT（5 MAUI hap 全 NativeAOT）、FRAMEPACING（60.00 fps）；**预签已刷新至 #45**（67,624,950 / `e1ce8ab6…`，asset 609411819；sidecar 88 B / `a7ab0943…`，asset 609416429）；壳 abc **368,812（`1076a700…`）**/24,324、宿主 **297,888（`7b1694d9…`，导出 151/151、UND 241）**、套件 **587/589 floor 569**；发布实测 tar **67,695,181 B / `ca48a93c…`**、树 **`ae0f7fce…`**、sidecar **`9741aced…`**、`SHA256SUMS` 18 项 / 1,600 B / `9f677c40…`；bundle **73,058,366 / `a8334c4c…`**（sdk 锚 **`c7ac81ccdf`**）；CI 5/5 @ `b6ad0b0`；数字以 release「## Integrity（kit #45）」与随包校验为准；判定点 = `docs/plans/2026-10-04-ohos-tester-handoff-kit45.md`（#44 = 上一版：动态槽 + 默认 AOT + FRAMEPACING；tar 67,680,863 / `b777d8d8…`；#43 = 更早：默认 AOT + FRAMEPACING；tar 67,638,015 / `57c7bf44…`）。
>
> **2026-10-04 更新（kit #44，上一版）**：kit #44 = **#43（默认 AOT + FRAMEPACING）+ 动态槽（SLOTS-DYNAMIC）**：①**动态槽**（ohos-workload `88e5aec` + maui 切片 `3feb347414`）：覆盖层池 **MAX/HOT 默认 4/2**（clamp 2..8 / 2..max）、**按需 ensure/destroy**（热对 [0,1] 常驻、释放的动态槽立即拆）、**容量事件降级 + owner-LRU 抢占**（保持 #41 恢复语义）、**延迟命令回放**（壳未 attach 命令按槽排队 ≤32、`onControllerAttached` 按序重放）、**壳 `ForEach` 槽 + `SetShellCapacity`**——**3 控件并发出画/交互**（第 3 槽回收/重建、Blazor 热换）；②**默认 AOT**（承 #43）：5 MAUI hap 全 NativeAOT、`runtime-mode.txt=aot`、无 JIT 运行时（JIT 保形态；release/生产域需 AGC ACL/豁免；`--runtime-mode jit` 可自建）；③**FRAMEPACING**（承 #43，ow `aa6f485`）：宿主 present telemetry + stats harness——17.7 fps 系壳状态轮询伪影，实际 **60.00 fps**；**预签已刷新至 #44**（7 hap；67,627,789 B / `75a40110…`，asset 608782132；sidecar 88 B / `b880a68f…`，asset 608782732）；壳 abc **368,812（`1076a700…`）**/headless 24,324（`798b2477…`）、宿主 **297,888（`7b1694d9…`，导出 151/151、UND 241）**、套件 **584/586 floor 566**；发布实测 tar **67,680,863 B / `b777d8d8…`**、树 **`db2604d5…`**、sidecar **`85d62a6e…`**、`SHA256SUMS` 18 项 / 1,600 B / `41c1f3c3…`；bundle **73,052,763 / `3b3008a4…`**（sdk 锚 **`2abf4fcaa3`**）；CI 5/5 @ `86b0e89`；数字以 release「## Integrity（kit #44）」与随包校验为准；判定点 = `docs/plans/2026-10-04-ohos-tester-handoff-kit44.md`（#43 = 上一版：默认 AOT + FRAMEPACING；tar 67,638,015 / `57c7bf44…`；#42 = 更早：三路径首帧；tar 376,256,128 / `ea4e3b58…`）。
> **2026-10-03 更新（kit #42，更早）**：kit #42 = #41 + **JIT 解锁 + 解释器 rc2b 首帧 + FIX-SLICERACE（8/8）+ L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c/镜像扩展**（①**JIT 解锁**（WX-HOST-PRCTL：宿主 `prctl(0x6a6974)` JITFORT 默认开 + 无 ICU 镜像自动 `InvariantGlobalization`）→ **JIT 首帧**（`canvas presented` 4–8 + UI 截图；探针 `1=OK 2=OK`；逃生口 `DOTNET_OHOS_NO_JITFORT=1`/`DOTNET_OHOS_ICU`）；②**解释器 rc2b**（新资产 `ohos-interpreter-pack-rc2b.tar.gz` 2,410,595/`5974430509…`，asset 606999003；含 WX-PATCH2）→ **解释器首帧**（`canvas presented 2090x1324`；INTERP-NULL 根因 = 旧测试件 rc.1 托管 CoreLib × rc.2 原生 QCall ABI 错配，非 pack 缺陷）；③**FIX-SLICERACE**（切片 handler 并发设置竞争：可重入串行化 + `_ready` 门闩）→ **JIT 8/8 设备轮 PASS**、套件 **578/580 floor 560**；④L6（Screenshot JPEG/Title 心跳；壳 abc **356,468/`dd04dad1…`**）、LEGACY Toolbar 闭合、SAMPLE-FIX（`blzProbe`=`dotnet-ref ok`、Blazor `#app` 恢复挂载、`dotnet.zip` 258 项）、WX-PATCH2 双映射预检+写屏障提交检查、P2c `skills[].uris`、镜像扩展（`m-web-mirror d47f1fcb3b`）；宿主全量重建 **297,888（`08abe185…`，导出 151/151、UND 240）**；**预签未刷新（仍 #41 件，指向 #41 内容）**；FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount/FIX-JSCALL/MULTI-OVERLAY-FULL/DEVCOMPAT 全量保留；发布实测 tar **376,256,128 B / `ea4e3b58…`**、树 **`13f3a086…`**、sidecar **`878d05a1…`**；数字以 release「## Integrity（kit #42）」与随包校验为准；判定点 = `docs/plans/2026-10-03-ohos-tester-handoff-kit42.md`（#41 = 上一版，见其交接文）。
> **2026-10-03 更新（kit #41，上一版）**：kit #41 = #40 + **MULTI-OVERLAY-FULL + DEVCOMPAT-DEFAULT + INTERP-FIX（三大彻底修复）**（①**MULTI-OVERLAY-FULL**（maui `07423dfe93` + ow `0e0129e`）：双槽 ArkWeb 覆盖层池 + **owner 感知 LRU 抢占/恢复**（`IOpenHarmonyOverlaySlotOwner`）、per-slot hybrid serve/message/**invoke 通道**（slot-tagged invoke id）、**激活序 z-order**、payload-in-libs appDir 探测——同页两 Hybrid 各自 invoke/消息闭环，>2 控件按 LRU 抢占退化、activate 恢复重放 load；②**DEVCOMPAT-DEFAULT**（ow `12be59c`）：payload 逐文件码签重写**默认化**（无扩展名→`.so`、恰 4096 B→+4 B）——enforcing 7.0.0.111+ **开箱可装**；kit 现 15 `.so` / 257 zip 条目；③**INTERP-FIX**（ow `c9916cd`）：宿主 **8 MB app 线程栈** + `interp=3` 关 GC 写屏障拷贝；**rc.2 重建解释器 pack** 独立资产 `ohos-interpreter-pack-rc2.tar.gz`（2,409,070 B / `34709a94…`，asset 605924427）；④**预签刷新至 #41**（tester UDID；376,684,381 / `2075650a…`，asset 606183753）；FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount/FIX-JSCALL 全量保留；壳 abc **356,140（`2a90f0d7…`）**/headless 24,324、宿主 **293,792（`8d67def3…`）**、导出 **150**、套件 **563/floor 543**；发布实测 tar **376,036,502 B / `bed460ae…`**、树 **`7ce1946e…`**、sidecar **`2a95e764…`**；数字以 release「## Integrity（kit #41）」与随包校验为准；判定点 = `docs/plans/2026-10-03-ohos-tester-handoff-kit41.md`（#40 = 上一版，见其交接文）。
> **2026-10-02 更新（kit #40，上一版）**：kit #40 = #39 + **FIX-JSCALL**（maui `15d81f31b1` + 套件 pin `2028cc2`/`9073c65`）：**BlazorWebView IPC 出站半边 AOT 扎根**——`IpcSender.BeginInvokeJS` 序列化 `JSCallResultType`/`JSCallType`、`IpcSender.Navigate` 序列化 `NavigationOptions`（均经 WebView 包反射解析器）；NativeAOT 缺 `EnumConverter<T>`/`JsonTypeInfo<T>` 闭合实例原生代码 → attach interop 死在 `IpcCommon.Serialize`（#39 的 FIX-BWVMount 桩 interop 又吞掉后续点击）；切片把三类型并入源生成上下文 + handler 静态构造触碰 type info + 移除桩探针 → **razor 计数往返 0→1→2 真机达成**（截图 r0/r1/r2；`missing native code`=0、`BeginInvokeDotNet` accepted=4）；FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount 全量保留；壳 abc **342,160（`ffda66da…`）**/headless 24,324（未变）、宿主 **293,792（`384e552a…`）**（未变）、导出 **150**、套件 **555/floor 535**；发布实测 tar **375,836,470 B / `31ab8732…`**、树 **`e950de54…`**、sidecar **`9b051247…`**；数字以 release「## Integrity（kit #40）」与随包校验为准；判定点 = `docs/plans/2026-10-02-ohos-tester-handoff-kit40.md`（#39 = 上一版，见其交接文）。
> **2026-10-02 更新（kit #39，上一版）**：kit #39 = #38 + **FIX-BACKSIZE + FIX-BWVMount**（①**FIX-BACKSIZE**（maui `be09a48817` + 壳/宿主 `9e6519e`）：系统 Back 键经壳 `onBackPress(): boolean` → 宿主 `host.backPressed`/`ohos_host_register_back_pressed`（导出 **149→150**）**关闭抽屉**（第二次 Back 交回系统 `#BACKGROUND`）；`BlazorWebView` 覆写 `GetDesiredSize`（真实尺寸——此前 `Standard` 返回 0 → frame 退化被壳忽略、自身不出画）；hybrid 已注册时 Blazor frame 有意 withheld；②**FIX-BWVMount**（maui `52b082a071`）：**NativeAOT 下 `.razor` 组件真机挂载**——handler 静态构造触碰源生成 `JsonElement[]` 类型信息，使 WebView 包反射构造的 `ArrayConverter` 留在 AOT 镜像（此前 `AttachPage` 在包内抛错、组件不挂载）；`[maui] blazor start/connect` + `BLZ_DIAG` 可观测；FIX-HOME/FIX-ITOUCH/FIX-DISMISS/FIX-WVP 全量保留）；壳 abc **342,160（`ffda66da…`）**/headless **24,324（`798b2477…`）**、宿主 **293,792（`384e552a…`）**、导出 **150**、套件 **554/floor 534**；发布实测 tar **375,765,521 B / `e95eed49…`**、树 **`932e7955…`**、sidecar **`e5fc82de…`**；数字以 release「## Integrity（kit #39）」与随包校验为准；判定点 = `docs/plans/2026-10-02-ohos-tester-handoff-kit39.md`（#38 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #38，上一版）**：kit #38 = #37 + **FIX-DISMISS + FIX-WVP**（①**FIX-DISMISS**（maui `86b439ffc8`）：抽屉**外点不关闭**的根因 = `FlyoutPage.Default` 版式在非 Phone idiom/landscape 下关闭被 `InvalidOperationException` 守卫拒绝（异常被触摸回调边界吞掉、面板保持）→ 默认 `Default` 改置 **`Popover`**（overlay 抽屉），外点正常关闭并重绘；②**FIX-WVP**（maui `47d79add01` + 壳 `acbe750`）：Hybrid overlay 坐标 **px→vp**（frame 为设备像素、壳按 ArkUI vp 用 → ×1.9 落窗外）、hybrid origin `https://0.0.0.1/` **注册仲裁**（后到 Blazor 只武装不加载）、`Web` 后置到 `ContentSlot` 之上（z-order 真出画）、抽屉/切 tab 时 **suspend/resume/hide** 状态机 + `WebCommandSent` 诊断）；FIX-HOME/FIX-ITOUCH 全量保留；壳 abc **341,560（`4f02cb1d…`）**/headless **24,324（`798b2477…`）**、宿主 **293,792（`4e9f3c3e…`）**、导出 **149**、套件 **550/floor 530**；**FIX-BACK 波次未入包**（Back 关抽屉 / BlazorWebView 尺寸在途，将随下一版）；发布实测 tar **375,641,619 B / `ced5583f…`**、树 **`307004e1…`**、sidecar **`8982fad0…`**；数字以 release「## Integrity（kit #38）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit38.md`（#37 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #37，上一版）**：kit #37 = #36 + **FIX-HOME + FIX-ITOUCH**（①**FIX-HOME**（maui 切片 `68ec598037`）：`OpenHarmonyNavigationPageHandler.PlatformArrange` 下钻 `CurrentPage`（safe-area walk + arrange 防递归标记）——Home tab（FlyoutPage→TabbedPage→NavigationPage）不再停在 `-1x-1`，AOT 真机首屏整页出画（截图 `fix-home/device/home-cold.jpeg`）；交互套件 +4 pin；②**FIX-ITOUCH**（宿主 `4e9f3c3e`）：`OnTouch` 改读 touch point **element** 坐标（与鼠标同一 surface 空间；free window 的 window 系含 70 px 系统标题栏 → 注入点击整体下移）——uitest 注入点击命中内容元素（"fading out…" → "animations done"）、偏心探针不误命中、tab 切换不变；宿主 UND 240→238）；壳 abc 字节不变 **339,964（`fc54d2b8…`）/24,324（`798b2477…`）**、hap 内宿主 **293,792（`4e9f3c3e…`）**、导出 **149**、套件 **544/floor 524**；发布实测 tar **375,652,577 B / `3a7259d6…`**、树 **`ab517b57…`**、sidecar **`7db60a77…`**；数字以 release「## Integrity（kit #37）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit37.md`（#36 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #36，上一版）**：kit #36 = #35 + **payload 原地直载（AOT 路径真机 BLZ）+ host 预注册缓冲 + 像素 Known 清零 + a11y 渲染帧修复 + rc.2 AOT pack `-r2`**（①壳 `findLibsPayloadDir` 兼容模块布局 `<bundleCodeDir>/<module>/libs/<abi>`——真机 hello-maui-wasm 直接自 `/data/storage/el1/bundle/entry/libs/arm64` 原地启动（`dotnet.zip not unpacked`，pid 49565）且 `BLZ_BOOT`/`BLZ_RENDERED` 双标记齐；②host 缓冲壳 `registerWebSink` 注册前到达的 web 命令（16 条 / 64 KiB，注册即 flush；套件 pin `moduleRoot`/`webPending`）；③像素套件不再有 `Known(...)`（selection tint 改字节量化精确断言 `#3959B3`）；④a11y `nodeCount 0` 根因 = shadow tree 未 publish，S2a pin `renderAttached=True`、`--a11y-probe` 实测 `status=1`、nodeCount 5/24 稳定；⑤rc.2 AOT pack 修正版 `-r2`（28,904,657 B / `542058cf…`，asset 601289590）修复 OpenSSL shim → 撤 rc.1 钉）；新壳 abc **339,964（`fc54d2b8…`）/24,324（`798b2477…`）**、hap 内宿主 **293,792（`cfbbe461…`）**、导出 **149**、套件 **540/floor 520**；发布实测 tar **375,627,841 B / `9eb9cecf…`**、树 **`9764827c…`**、sidecar **`4d7062c3…`**；数字以 release「## Integrity（kit #36）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit36.md`（#35 = 上一版，见其交接文）。
> **2026-09-30 更新（kit #35，上一版）**：kit #35 = #34 + **W9/W10 并入主线**（W9A **B2：MAUI WebView 承载 Blazor WASM**——真机 `BLZ_BOOT`/`BLZ_RENDERED` 打通（pid 6157），#34 的 AOT 入口缺口由 W10 修复；W9B T14 收尾 + T21 字体缩放；W9C T8 不等高 TableView；W9D **T20 媒体传输层**（本机镜像无 MediaKit 属预期，`IsSupported=false` 降级不抛）+ T19 深链判定（热 `delivered=1`）；W10 **AOT 入口修复**（宿主自身 libs 解析 `lib<stem>.so` + `dotnet-status.txt` 可观测、壳 AOT payload 探针/`fs` 别名/静态资源指纹；rc.2 AOT 包 OpenSSL shim 缺陷 → 本地钉 rc.1）；新壳 abc **339,164（`74054e2d…`）**/headless **23,516（`6bce4063…`）**、hap 内宿主 **293,792（`983e8f74…`）**、导出 **149**、套件 **540/floor 520**；发布实测 tar **375,629,423 B / `419d42e2…`**、树 **`d3b1b317…`**、sidecar **`d7e79d39…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `2dd447a7…`**（发布已完成，以 release「## Integrity（kit #35）」与随包校验为准）；判定点 = `docs/plans/2026-09-30-ohos-tester-handoff-kit35.md`（#34 = 上一版，见其交接文）。

> 对象：本轮真机首发报告的测试方 —— 设备 **OpenHarmony 7.0.0.105 / API 26 / 2in1**，
> UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`。
> 现象：hap 安装成功，`aa start` 后约 1 秒应用退出（exit 254），`AppKilledReporter` 报 `reason=JsError`。
> 本页只做三件事：**换当前 kit 重测** → **取最小崩溃证据** → **回传 §5 清单**。命令可照抄；结论以设备实测为准。
> 相关文档（kit 内）：`真机操作手册.md`（校验/安装/取证）、`验收说明.md`（完整清单与模板）、`签名与UDID指南.md`（9568344）。
>
> **2026-09-24 更新（kit #24）**：本文所写的三类旧崩溃 —— 入口 record（kit #10）、abc 版本（kit #11）、宿主加载（kit #12）—— 均已在当前 kit 修复；此后追加 P17 跳过重复解压、H7 rawfile 文件描述符直读、headless 变体 abc `13.0.1.0`，并在 kit #22 回灌设备里程碑修复：宿主 `DT_NEEDED` 5 库 + 可选 API 按需 dlsym、HAP `resources.index`（restool）、启动解压 ZIP offset/length + mkdir、DevEco 工程布局（kit #23 = 工具刷新：强化 `verify-kit.sh` + `tester-run.sh` v7 入包）。**kit #24**：payload 进 hap `libs/arm64-v8a/` 原地启动（`.dotnet-payload.json`，`dotnet.zip` 回退）、宿主显式 `DOTNET_EnableWriteXorExecute=0` + `xwe.txt` A/B + exec-memory 探针（§2.6，采集为 `hilog/hilog-execmem.txt`）；不含 seccomp 拦截器。**2026-09-24 设备证据修正**：黑屏/失败的直接链是宿主加载 + bootstrap 三项（`resources.index` / ZIP offset / mkdir）+ abc 编译，共 5 项，而非旧 #4（`libIsolation`/napi 记录名；已降级为无害加固）—— 见 `docs/plans/2026-09-24-ohos-device-milestone.md` 与 `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md` §5f。JIT 崩溃（`SEGV_ACCERR`）的判定与 NativeAOT 指引见 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`；`tester-run.sh` **v8** 会自动采集 `hilog/hilog-applib.txt`、`hilog/hilog-dlopen.txt`、`hilog/hilog-bootstrap.txt`、`hilog/hilog-execmem.txt`、`device/app-libs-arm64.txt`、`device/payload-files.txt`/`payload-marker.txt`、`meta/kit-selfcheck.txt`（§2.4–§2.6）；整包/内容树数字以 release「## Integrity」为准。`签名说明.txt` 的 PA1 历史句已随源修复（`c6a4cd95e`），若副本仍出现按历史文案处理。
>
> **2026-09-28 更新（kit #32，上一版）**：**WebView 六项接线 + B1 razor 独立资产 + SEC 收口** —— WebView/Hybrid/Blazor 三 handler（history/CanGoBack、Cookie、frame 定位、导航事件、失败清屏；真机 9 项卡 `docs/plans/2026-09-28-ohos-webview-blazor-device-card.md`）；B1 `hello-maui-razor`（bundle `com.example.hellomauirazor`）；Blazor hap **无 INTERNET**（重签保持）；tester-run **v14**（pid+nonce 绑定）；abc `289992`、交互 398/378。
>
> **2026-09-29 更新（kit #31）**：**Blazor WASM/ArkWeb 组件** —— 新增第 6 个 hap **`hello-blazorwasm-host-unsigned.hap`**（26,794,931 B / `36010a9c…`，未签名，bundle **`com.example.opendotnet`**，需自签；ArkTS 宿主 + `resources/rawfile/blazor` 内嵌站点、`onInterceptRequest` 直供）；**tester-run v13** 的 `--blazor-probe` 断言 `BlazorWebHost ... marker: BLZ_BOOT` 与 `marker: BLZ_RENDERED` 两条 hilog 标记（失败转发 `BLZ_ERROR <msg>` 并落盘 `blazor-hilog.txt`）；人工首屏 “Hello from Blazor WebAssembly” + `/counter` +1 + 截图；整包 tar **207,023,588 B / `f4325d2f…`**（树 `52e77ee8…`、sidecar `7d0cba77…`、`SHA256SUMS` 16 项）。MAUI 主包与下一条 #30 的启动判定不变。
>
> **2026-09-28 更新（kit #30；历史）**：MS-MODE —— **runtime-mode 打包开关**（`-p:OpenHarmonyRuntimeMode=jit|aot|interp`（默认 jit）→ hap `libs/<abi>/runtime-mode.txt`；宿主在 `xwe.txt`/`interp.txt` 同点读取，优先级 file>manifest>default，日志 `runtime-mode=<v> source=…`；aot 缺 `lib<stem>.so` 显式回退 JIT（`falling back to the JIT route`）；interp 可带 `-p:OpenHarmonyInterpreterPack`）、**tester-run v12**（`summary runtime_mode` 键；清单 interp 的 Run C `run_c_via=manifest`）与 **MAPFIX harmony 重切**（MapOverlay 真编译：abc 291,628 B/`a637a513…`、tar `9b0506fa…`；旧件 `d3a7b718…`/`f7a4faa2…` 已替换）。R3 批不变：**CoreSpeechKit TTS**（`canIUse` + `@kit.CoreSpeechKit` 双门、五 op；无 Kit 时 `IsSupported=false`、调用降级不抛；真朗读需 HMS 设备 + harmony 壳）、**HUKS-first SecureStorage**（设备绑定 AES-256-GCM 密钥、**0 权限**；无 HUKS 时回退文件密钥并如实标注非硬件后备）与**自绘深度五连**（文本编辑/动画/列表/图片/深链）。宿主导出契约 **143/143**；ui/shell abc **281,052 B**（headless 20,916 B）。**启动崩溃判定（`probe:`/`xwe`、P1–P4、bootstrap）不变**，kit #30 回归点 = 重建宿主（runtime-mode 标记解析）后的 payload 仍正常启动（`runtime-mode=jit source=manifest` 行出现且不阻塞）、JIT hap 的 AOT 探针以 `aot=0` 回退不阻塞、原生桥/回调行为与 #29 一致、TTS/HUKS/深链探针不崩。`verify-kit.sh` 的 abc 期望沿用 `281052`/`20916`（用 #28 的 `264136` 或更旧值校验会 FAIL，属预期）。整包发布实测：tar **196,992,264 B / `a781c25b…`**、树 **`cc1ca935…`**、sidecar **`a63cd34f…`**（#29 196,990,205 / `e895cc0a…`；重签后必变，以 release「## Integrity（kit #30）」为准）。本轮增量判定点见 `docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2（#29 见 `docs/plans/2026-09-28-ohos-tester-handoff-kit29.md` §2）。
>
> **2026-09-26 更新（kit #28；历史）**：R2 —— **Map 覆盖层**（`ARKTS_SDK_FLAVOR=harmony` 壳 + AGC 地图 AppKey；默认 flavor 下 `IsSupported` 可为 true 而 `IsOverlayAvailable=false`，show/hide/区域/标记等调用**降级不抛**）、**LiveView 特性探测**（无 Kit/权益时 `IsSupported=false`、Start/Update/Stop `Unavailable` 不抛）、**壳 `start_app` AOT 启动桥**（`lib<stem>.so` → `openharmony_app_main`，日志 `aot=1`；失败 `aot=0` 回退 hostfxr）与**解释器实验**（`<files>/interp.txt` → `DOTNET_InterpMode`，日志 `interp=3 source=file`）。宿主导出契约 **134/134**；ui/shell abc → **264,136 B**。**启动崩溃判定（`probe:`/`xwe`、P1–P4、bootstrap）不变**，kit #28 回归点 = 重建 payload（新 abc + 新宿主 + R2 壳桥）仍正常启动、JIT hap 的 AOT 探针以 `aot=0` 回退不阻塞、原生桥/回调行为与 #27 一致、无 Kit 探测不崩。`verify-kit.sh` 的 abc 期望已重锚 `264136`（用 #27 的 `245412` 或更旧值校验会 FAIL，属预期）。整包数字（tar **196,220,486 B** / `091dcc56…`、树 **`0a7a3215…`**、sidecar `d7efd251…`）见交接页文首指纹块与 release「## Integrity」。本轮增量判定点见 `docs/plans/2026-09-26-ohos-tester-handoff-kit28.md` §2。
>
> **2026-09-27 更新（kit #27；历史）**：KIT-EXT2 —— 壳对 Push/Account/Map 三个 HMS Kit 做特性探测（无 Kit/AGC/HMS 时 sink 不注册、值 `Unavailable`/null/false，**不抛**）、宿主新增 12 个 kit sink（导出契约 118/118 → **130/130**）+ FIX-R1-NAPI-6D 边界加固、反向条目改走 off-runtime marshaller（`[UnmanagedCallersOnly]` + `delegate* unmanaged[Cdecl]` thunk）；ui/shell abc → **245,412 B**、hap 内宿主 → **265,120 B**、hosting DLL → 55,296 B。kit #27 回归点 = 重建 payload（新 abc + 新宿主 + marshal-off 托管）仍正常启动、原生桥/回调行为与 #26 一致、无 HMS 探测不崩（判定点见 `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md` §2）。
>
> **2026-09-26 更新（kit #26；历史）**：互操作/打包/平台缺口收口 —— hosting 桥全量 `LibraryImport`（125 处，`DllImport` 归零，导出契约 118/118；hap 内 hosting DLL 55,808 B）、hap 打包任务程序集化（pack `tools/Microsoft.OpenHarmony.Tasks.dll`）、AspNetCore KFR/RID/apphost 缺省化（消费方无需工程级规避）；**启动崩溃判定（`probe:`/`xwe`、P1–P4、bootstrap）不变**，kit #26 回归点 = 重建 payload（LibraryImport hosting）仍正常启动、原生桥行为与 #25 一致。kit #25 的权限/Share/Scan/AOT 判定点继续有效（见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`），其增量判定点见 `docs/plans/2026-09-26-ohos-tester-handoff-kit26.md` §2。
>
> **2026-09-25 更新（kit #25）**：新增权限链（`reason`/`usedScene` + 请求点门禁）、Share/Scan 特性探测（OpenHarmony SDK 上 `shareDispatch=False`/`scanSupported=False` 干净降级）与 AOT 启动路径（`lib<stem>.so` → `openharmony_app_main`，hostfxr 回退）；启动崩溃判定（`probe:`/`xwe`、P1–P4、bootstrap）**不变**，kit #25 回归点 = JIT hap 仍走 hostfxr 回退正常启动。本轮判定点（权限弹窗文案 / Share 面板 / Scan 返回 / AOT 启动）见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`。

## 0. 一页摘要

1. 你报告里用的是 **workload preview.23**；当前交付基线是 **preview.24**，且 2026-09-21 当天落下的
   一批**启动相关修复**（宿主 pending-context 释放、早到生命周期事件排队、宿主失败路径清理等，见安全扫描 A1/A6/A7/N1–N4）
   **只在当前 kit 里**。请先花几分钟用当前 kit 重测一次 —— 这比任何离线分析都快，且可能直接消掉崩溃。
2. 若仍崩：按 §2 录一段 `hilog`（崩溃点前后各 200 行）回传，顺手做 §3 的三个 A/B（各 5 分钟）。
3. 你上轮为安装改过的两处（bundleName 去连字符、module.json 波段对齐）**我们已确认在修**（§4），下轮无需再手改；
   这两点能解释"装不上"，但**不一定**解释 JsError，所以仍以 §1–§3 的证据为准。

## 1. 第一步：用当前 kit 重测（务必先做）

### 1.1 下载 + 校验（先记录 sha256 与 tree digest，再安装）

```sh
base=https://github.com/springmin/sdk-ohos/releases/download
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz"          # 镜像：$base/workload-latest/device-test-kit.tar.gz
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz.sha256"
sha256sum -c device-test-kit.tar.gz.sha256        # ① 外层压缩包校验
sha256sum device-test-kit.tar.gz > kit-sha256.txt # ② 记录（回传用）
mkdir -p device-test-kit && tar xzf device-test-kit.tar.gz -C device-test-kit
cd device-test-kit
sh verify-kit.sh --anchor-file ../device-test-kit.tar.gz              # ③ 包内逐文件 + 外层锚定
sh verify-kit.sh --expect-tree-digest <发布说明给出的 tree sha256>    # ④ 绑定解压内容树
# 发布说明没有 tree sha256 时：先打印，再把它回传
sh verify-kit.sh --tree-digest
```

- 期望最后一行 `KIT OK`；出现 `FAIL/WARN`（校验不符、缺 hap/文档）**先重新下载解压**，不要带病安装。
- ③④ 的区别：`SHA256SUMS` 在包内，只能证明包内自洽；`--anchor` 只绑定下载的 `.tar.gz` 文件本身；
  `--expect-tree-digest` 才绑定**解压后的内容树**（文件被增删改会失败）。
- **版本核对**：打开 kit 内 `最终状态.md`（「发布物」一节）或 `README-交付说明.md`（「构建基线」行），
  把版本原文回传（当前官方基线应为 `1.0.0-preview.24`）。
  若你手上没有 `最终状态.md`、或它写的是 **preview.23** → 说明是旧包：请换包重测，旧包的崩溃结论我们不会采用。

### 1.2 安装与启动

沿用你上轮的成功路径（你自己的华为 debug 证书）；当前 kit（#26，P2-INTEROP/TASK-MIG/PLAT-GAP；权限链/Share-Scan/AOT 沿用 #25，含 #24 payload-in-libs）的 5 个 hap 已是合法 bundleName 与设备波段，**无需改名、无需手改 module.json**，其它文件也不要动：

```sh
hdc install hello-maui-app.hap
hdc shell aa start -a EntryAbility -b <你安装时的 bundleName>
```

> 你的重命名与 module.json 对齐是**你侧唯一的改动**（其余条目你已证明与原件 CRC 一致）。
> 请把改动后的 module.json 原样发我们（§5 第 3 项）——它是默认包与崩溃包之间唯一的差异来源。

## 2. 最小崩溃证据（若重测仍崩）

### 2.1 hilog：清缓冲 → 录制 → 启动 → 过滤

```sh
D=60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19   # 你的设备 UDID

hdc -t "$D" shell hilog -r                        # ① 清空日志缓冲，缩短窗口
hdc -t "$D" shell hilog > hilog-crash.txt         # ② 前台录制（保持这个终端不动）
# 另开一个终端：③ 启动（bundleName 用你实际安装的）
hdc -t "$D" shell aa start -a EntryAbility -b <bundleName>
# ④ 等应用退出（约 1 秒），回到录制终端按 Ctrl-C，然后过滤：
grep -inE "hellomaui|hello-maui|maui|dotnet|openharmonyhost|libentry|dlopen|AppKilledReporter|appspawn|JsError|jscrash|napi|EntryAbility|abc" hilog-crash.txt > hilog-filtered.txt
```

- **回传 `hilog-filtered.txt`（命中行）+ 崩溃时间戳前后各 200 行**；整份 `hilog-crash.txt` 更好。
- 崩溃时间点取第一条含 `AppKilledReporter` / `JsError` / `jscrash` 的行，标注出来即可，不必自行解读。
- 若 `hilog -r` 在你的 ROM 上不可用：跳过①，记录 `aa start` 的准确时间即可。
- 若上轮 preview.23 的 hilog 还留着，也发一份 —— 两份对照能直接看出复发与差异。

### 2.2 faultlog（能取就取，取不到属预期）

- `/data/log/faultlog` 在应用沙箱/普通 shell 权限之外，`hdc shell` 读不到是**正常的**，不是你的操作问题；
  不用在这上面耗时间。
- 手上有 DevEco Studio 时：设备在线后用 **FaultLog**（你的版本若有该入口）查看 JS 崩溃记录，能打开就导出；
  若你有 **DevEco 云端调试/云真机**通道，也可在云设备复现后取 faultlog。
- **回传**：只要一个 **jscrash 文件名**（FaultLog 列表里那个）+ 内容/截图（有则附，无则注明"取不到"）。

### 2.3 应用沙箱 `files/dotnet-status.txt`（可选，能取就取）

托管宿主每次启动会写状态文件，路径通常为：

```text
/data/app/el2/100/base/<bundleName>/files/dotnet-status.txt
```

- 优先进沙箱的工具：**DevEco Studio 的文件浏览器（Device File Browser，调试应用可进 `files/`）** → 导出该文件；
- 只有 `hdc shell` 时试：`hdc -t "$D" shell "ls /data/app/el2/100/base/<bundleName>/files"`；被权限拒绝就跳过并注明；
- 文件**不存在或没有新内容本身就是证据**（说明宿主可能还没执行到写状态文件）——请在回传里写明。

### 2.4 app-lib / 别名注册 / 首帧（RM1 诊断；tester-run v8 自动采集）

```sh
hdc -t "$D" shell "hilog -x | grep -E 'SetAppLibPath|appLibPathKey|NativeLibPath|lib path'"   # -> hilog/hilog-applib.txt
hdc -t "$D" shell "hilog -x | grep -E 'dlopen|cannot find library|openharmonyhost'"          # -> hilog/hilog-dlopen.txt
hdc -t "$D" shell "ls -l /data/storage/el1/bundle/libs/arm64/" > app-libs-arm64.txt
```

- `appLibPathKey: <bundle>/<module>`（含 `lib path:` 原文）出现 => 模块级 app-lib key 已注册（`libIsolation` 生效）；
  只有 `default`/app 级路径 => 非隔离安装；完全没有 `appLibPathKey`/`lib path` => 注册代码未跑到（窗口错或应用早退）。
  `GetEtsHapSoPath` 在 DEBUG 级别，必要时先 `hdc -t "$D" shell hilog -b D`。
- `[openharmony-host] native module register function bound via alias '…'` 出现 => 宿主 `.so` 已加载并注册到该别名；
  别名字符串（裸 `openharmonyhost` vs 文件别名 `libopenharmonyhost.so`）是决定性信号。
- 首帧判定（通过）：`registerXComponent=function`、首帧出现、无 `Load native module failed`。

判读与回退见 `docs/plans/2026-09-23-ohos-native-import-experiment.md` §8.4/§8.5。

### 2.5 bootstrap / rawfile / payload（v7 起采集、v8 沿用；黑屏或早退时的第一手证据）

```sh
hdc -t "$D" shell "hilog -x | grep -E 'GetRawFileContent|bootstrap failed|bootstrap retry|BusinessError|900002|900003|ZIP entry|destination path|Load native module failed|symbol not found|cannot find library'"   # -> hilog/hilog-bootstrap.txt
hdc -t "$D" shell "ls -l /data/storage/el2/base/haps/entry/files/" | grep -E 'dotnet|payload'   # -> device/payload-files.txt
hdc -t "$D" shell "cat /data/storage/el2/base/haps/entry/files/dotnet.marker"                   # -> device/payload-marker.txt
```

- `summary.txt` 对应键：`bootstrap_errors`/`rawfile_errors`/`libload_errors`（命中计数）与 `payload_present`/`payload_marker`，另有本地 hap 自检键 `kit_index_ok`/`payload=yes|no`（`meta/kit-selfcheck.txt`）。这些键**只提示、不改退出码**。
- `GetRawFileContent failed, name is empty` + `kit_index_ok=no` => hap 缺 `resources.index`（早于 kit #22 的旧包），**换当前 kit 再测**，不是设备问题。
- `ZIP entry`/`destination path` => 启动解压/路径问题（对照 kit #22 的 ZIP offset/mkdir 修复）。
- `Load native module failed`/`symbol not found`/`cannot find library` => 宿主/依赖加载问题，转 P1–P4 阶梯（§5）。
- **kit #24 起 payload 在 hap `libs/arm64-v8a/` 原地运行**：`payload_present=no` 属常态（这些键只反映回退布局的 filesDir 解包）；`payload_marker=empty` 只在回退布局有意义。真正的 payload-in-libs 信号是 `meta/kit-selfcheck.txt` 的 `payload=yes|no`（marker 缺失 = 该 hap 会回退到被 namespace 拒绝的 data 目录解包，`verify-kit.sh` 直接 FAIL）。

### 2.6 exec-memory 探针与 JIT 判定（kit #24；崩溃为 `SEGV_ACCERR` 时先看这里）

```sh
hdc -t "$D" shell "hilog -x | grep -E 'OHOS_DOTNET probe:|xwe='"     # -> hilog/hilog-execmem.txt
grep -E 'probe:|xwe=' <证据包>/hilog/hilog-execmem.txt               # 归档内同文件
grep execmem_lines <证据包>/summary.txt                              # 0 = 未捕获，加长 --capture 重跑
```

- 每个探针 token 为 `OK` 或失败 `errno`：**1** = 匿名 `mmap(RWX)`（W^X=0 的 JIT 路径）· **2** = 匿名 `mmap(RW)`→`mprotect(RX)` · **3** = `memfd` + `mprotect(RX)`（W^X=1 路径）· **4** = 临时文件 `mmap(RX)`。典型 errno：`1` EPERM · `12` ENOMEM · `13` EACCES · `38` ENOSYS。
- 判定：`1=OK` ⇒ 匿名可执行在 HAP 域可用，JIT（默认 `EnableWriteXorExecute=0`）应可用，报证 = managed app 运行 + 无 `SEGV_ACCERR`；若 `1=OK` 仍 `SEGV_ACCERR`，附 probe 行/xwe 行/崩溃栈继续定位。`1≠OK` ⇒ 本固件 HAP 域拒绝匿名可执行，JIT 不可用，转 NativeAOT。
- A/B：在 `<filesDir>/xwe.txt` 写入首字节 `1`（DevEco Device File Browser）→ hilog 出现 `xwe=1 source=file`，复现 W^X=1 的同形崩溃；删除后恢复 `xwe=0 source=default`。完整判定表与 NativeAOT 步骤见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md` §3 与 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md` §5。
- 注意 kit #24 起（含 #26）**不含 seccomp 拦截器**（不再需要，且会 strip `PROT_EXEC` 破坏 JIT）；请确认未叠加旧本地补丁后再判读。

## 3. 四个快速 A/B（各 5 分钟，能跑几个跑几个）

| # | 问题 | 怎么做 | 结论怎么读 |
|---|---|---|---|
| AB-1 | 普通 ArkTS hap 能在这台设备起吗？ | 用 DevEco 新建 Empty Ability 工程（API 波段与设备一致）→ 安装 → `aa start` | 能正常起 → 设备/ArkTS 运行时没问题，焦点回到我们的包；同样 JsError → 设备/固件侧问题优先；两者日志都留着做对照 |
| AB-2 | 宿主动态库加载了吗？ | 在 §2 的 hilog 里搜 `libopenharmonyhost` / `dlopen` / `libentry` / `[maui] openharmony build` | 有 `[maui] openharmony build ...` → 托管宿主已启动，崩溃在更后面；只有 `libentry.so`/napi 记录、没有 host 行 → 崩在 napi 加载/入口；两者都没有 → 崩在 ArkTS/Ability 阶段，宿主没起来 |
| AB-3 | 崩溃前最后一行日志是什么？ | 取第一条 `AppKilledReporter`/`JsError` 之前最后的 5–10 行（连同 §2 的 200 行） | 这行通常直接点名失败点（native module 加载失败、abc/运行时版本不符、`pages/Index` 加载失败等）；原样贴回，不用自行解读 |
| AB-4 | 匿名可执行内存与 W^X 哪条路可用？（kit #24 起，`SEGV_ACCERR` 时必做）| 读 §2.6 的 `probe:` 行；再按 A/B 写 `<filesDir>/xwe.txt`=首字节 `1` 复跑一轮 | `1=OK` = JIT 可用路径；`xwe=1 source=file` 下复现 `SEGV_ACCERR`、默认 `xwe=0` 下不崩 = 平台 W^X memfd 路径被拒，默认 0 是正确设置；`1≠OK` = HAP 域禁匿名可执行，转 NativeAOT。判定表见交接文档 |

## 4. 我们已确认在修的两点（你不必排查）

| 项 | 你上轮的取值 | 我们侧的处理 |
|---|---|---|
| bundleName | 原包 `com.example.hello-maui-app` 含连字符不合法，你重命名为无连字符 | 打包侧改为合法 bundleName（与 profile 一致），下轮安装无需改名 |
| module.json 波段/profile | 你改为 `minAPIVersion=50002014`、`apiReleaseType=Release`、`compileSdkType=HarmonyOS`、`compileSdkVersion=6.0.2.130`、`virtualMachine=ark13.0.1.0`、`debug=false` | 打包侧按设备波段生成合法 profile，避免手改引入变量 |

> 目的：让下一版开箱即装，并把你侧的变量（改名/profile 手改）从崩溃等式中移除。
> 本轮请仍保留这两处改动记录（module.json 原件）以便我们核对。

## 5. 回传清单（照抄勾选）

1. [ ] kit 外层 `.tar.gz` 的 sha256（`kit-sha256.txt`）+ `verify-kit.sh --tree-digest` 输出。
2. [ ] kit 内 `最终状态.md` / `README-交付说明.md` 的版本原文（若为 preview.23 或没有该文件，请注明）。
3. [ ] 你实际安装的 `module.json` 原文（从 hap 解出/你改后的那份）+ 重命名后的 bundleName。
4. [ ] 一个 jscrash 文件名（+ 内容/截图，若有）。
5. [ ] §2 的 hilog 过滤片段（含崩溃点前后各 200 行）与崩溃时间戳；旧包日志若有也附。
6. [ ] §3 四条 A/B 的结果（每条一行：通过/失败 + 一句话现象）。
7. [ ] **JIT 相关（kit #24 起，kit #30/#31 沿用）**：`hilog-execmem.txt` 原文（`probe:` 行 + `xwe=` 行 + `runtime-mode=` 行）与 `summary.txt` 的 `execmem_lines`/`runtime_mode`；做过 A/B 的附两轮对照。判定表见 `docs/plans/2026-09-29-ohos-tester-handoff-kit31.md` §4（Blazor 段）/§3（JIT 承 #30：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §3；#29 见 `docs/plans/2026-09-28-ohos-tester-handoff-kit29.md` §3）/ `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md` §5。

> 收到后我们按 `验收说明.md` §6 模板归档；若重测后一切正常，回传 1–2 与一句"已通过"即可。
