# 启动崩溃根因：四个独立阻塞（入口 record / abc 版本 / host undefined / napi 注册名；exit 254 与黑屏）

> **2026-10-07 更新（kit #51，当前）**：kit #51 = **kit #50 全量（MULTIWINDOW-L M1–M4 + SEC-SCAN-5a/5b/5c + polish-49，承 #49 MULTIWINDOW-M/SEC-SCAN-4 与 #48–#45）+ MULTIWINDOW-L2 并存整合（a 子窗 a11y provider + b 子窗 ArkWeb 第二宿主）+ SEC-SCAN-6 A/B/C + L2CAP 平台容量探针**：①a 线（ow `c562a32`/`f5a892a`、maui `9faacf3`/`ba7581022c`）：`host_a11y_table.c/h` 节点表按 provider instance 分区（legacy 主分区逐字保留、`*_for(instance)` 命名分区 ≤8、instance ≤63 可打印 ASCII）、`OH_ArkUI_AccessibilityProviderRegisterCallbackWithInstance` + 带窗动作 `set_window_action_listener`、壳 `SubWindow.ets` NodeContent/ContentSlot 双点 attach；导出 157→**163**；真机 HAD-W32（OH 7.0.0.111）**W0 并存 PASS**（`subwindow a11y provider status=1 instance=sub-1`，主窗 status=1/72 节点不回退）与 **W2 自检 PASS**（`subwindow a11y selfcheck status=1 nodes=10 instance=sub-1`，主窗 72 节点零回归）；**动作 e2e 平台受限**（镜像无读屏/第三方 a11y 服务，`AccessibleManagerService accessible: 0`；离线 7 checks + 红控 4 条覆盖）；②b 线（ow `094ad51`/`3c486cf`、maui `086d358`/`2e441c35c9`）：`host_napi.cpp` child web sink（`child:` 前缀按窗路由并去前缀、主路径字节不变；`registerChildWebSink`/`registerChildWebEvalSink` NAPI 探测降级）、新 `OpenHarmonyChildWeb.cs`（sub-N 槽池 Max=2、64 条预就绪队列、`w:<win>|capacity|<n>` 就绪）、切片 5 文件按窗路由；首轮暴露 **capacity wire 不一致**（state 携 `capacity` 但 managed 只认 `capacity|<n>` → 事件被丢、队列不冲刷）→ 修复壳发 `w:<win>|capacity|<n>` + 双侧兼容 URL 形 + 套件 `capacity wire` pin；真机闭环（JIT）`child web host registered`→`child web capacity: sub-1 2`→`child web cmd: data s0`→`slot create/attached`→`CHILD WEB OK`→`navigated: Success`→`eval title`→click 读回 `CHILD WEB TAP`；主窗零回归（双窗 60.0/60.0 fps、close slot destroy + WMS 残留 0、0 新 fault）；③**SEC-SCAN-6 A/B/C 全闭**（A 分区分配仅 `begin_for`、B 主窗 id 在子通道拒绝、C 关窗 close hook 清 child Capacity/Pending + a11y frame/first-publish 标记，+2 checks、红控 3×assert=False）；④**L2CAP 容量探针**：平台并发子窗上限 **255**（第 256 个 `1300002`、3 轮一致；destroy 255/255、残留 0、可恢复）⇒ **应用级 N=1 为壳契约而非平台限制**（产品化另立项、本波不动壳单实例/801 契约）；⑤**降级声明（明示，不判失败）**：子窗 a11y **动作 e2e 平台限制**（读屏服务不可得，外部复跑）、**子窗 ArkWeb hybrid/blazor 资产桥显式拒绝**（不建组件、命令丢弃、eval 即错；下波壳侧 `onInterceptRequest` serving + 按窗注册回放）、**子窗 IME 实敲人工卡**（uitest 无子窗注入面，`2026-10-06-ohos-multiwindow-l-m4.md` 末节）、子窗 B6 导航否决未接（外部导航直载）、子窗池满（>2 控件）不挂载与就绪队列溢出丢 1 行日志、ArkWeb `loadData` 裸 `#` 截断平台注记、SEC-6 余留（原生 a11y 分区常驻、有界）；**预签已刷新（#51 件：68,447,288 / `e9fb1e90…`，asset 617093322；sidecar 88 B / `96948b04…`，asset 617094016）**；壳 abc **473,048（`298622c0…`）**/24,324、宿主 **347,040（`36acfc1d…`，导出 163/163、UND 250）**、套件 **688/690 floor 670**（超集 663+7+18+2）；发布实测 tar **68,550,333 / `e5f6541c…`**、树 `a06d3897…`、sidecar `5c471871…`、`SHA256SUMS` 18 项 / 1,600 B / `5f8c1512…`；bundle **73,147,751 / `f4b4fe8d…`**（sdk 锚 **`a00e810c92`**）；CI 5/5 @ `696ebc0`（interaction 37548888210 / pixel 37548888313 / host-export 37548888169 / ridgraph 37548888051 / markdownlint 37548888104）+ sdk run `37553127808`；数字以 release「## Integrity（kit #51）」与随包校验为准；判定点 = `docs/plans/2026-10-07-ohos-l2-consolidate.md` + `docs/plans/2026-10-06-ohos-tester-handoff-kit50.md`（卡片沿用）。
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

> 2026-09-22 记录测试方真机反馈的完整证据链与结论（一手材料：《OpenHarmony MAUI device-test-kit 真机验证反馈报告》）；
> §5d/§5e 为 2026-09-23 kit #14 真机进展（里程碑 + 第四个阻塞，一手材料：《kit #14 真机验证结论》）。
> **结论先说**：
> 1. 安装报 `9568257 fail to verify pkcs7 file` 是包内**自签名 hap 的预期拒绝** —— 设备不信任我方调试签名；
>    必须重签 `hello-maui-app-unsigned.hap`（唯一可重签安装的变体）或用发布方预签包，与启动崩溃无关。
> 2. 重签安装成功后启动即崩（约 1 秒 / `exit 254` / `JsError`）的根因是 **ArkTS 壳 `modules.abc` 缺少入口模块
>    record 索引**（记录名与 `module.json` 的 `srcEntry` 不匹配），**不是**宿主缺 `libc++_shared.so`（H1），
>    也不是宿主 dlopen/入口（H2）。修复：PA1 重建壳 abc（`ohos-workload/scripts/build-arkts-shell.sh`）后重出 kit —— 已随 kit #10 落地并被测试方真机确认。
> 3. 修复入口 record 后的同一轮真机复测暴露第二个独立阻塞：**壳 abc 字节码版本 `24.0.0.0` 超出设备的 ark runtime
>    上限 `13.0.1.0`**（hilog `export objects of native so is undefined` / `Cannot read property … of undefined`），
>    已随 kit #11（`compatibleSdkVersion 18`）修复。前两个根因的收尾见 §5b。
> 4. kit #11 真机复测确认 abc 修复生效（`[maui]` 日志出现、崩溃推进到页面/渲染阶段），同时暴露**第三个独立阻塞**：
>    宿主 `.so` 加载失败使壳 `host` 为 undefined，此前唯一未加守卫的 `host.registerXComponent()` 抛 TypeError
>    （`exit 254`）。修复随 kit #12（`ohos-workload 7e71c39` + 壳归档 `2411a8e`）：宿主不在链接期依赖
>    `libhostfxr`（全部经既有 dlopen/dlsym 表）、`build-host.sh` 增加构建期 DT_NEEDED 审计、壳把每个
>    `host.<api>` 调用纳入守卫。见 §5c。
> 5. **里程碑（kit #14，2026-09-23）**：应用首次**正常启动并稳定存活**（60 s+，主进程 + `:gpu` 进程），
>    **零崩溃日志**（无 `TypeError` / `JsError` / `exit 254`）—— 前三个根因（入口 record、abc `13.0.1.0`、
>    运行时原生库随 `libs/arm64-v8a/`，对应本文 §5b/§5c）均已在真机确认修复；但页面**黑屏**（进程不退出）。
>    第四个独立阻塞：宿主 napi 注册名 `nm_modname = "openharmonyhost"` 与 `useNormalizedOHMUrl=false` 下
>    abc 的 import 记录名 `@app:com.example.hellomauiapp/entry/openharmonyhost` 不匹配 → 设备按记录名
>    加载 native 模块失败 → 宿主 exports 为空 → XComponent 表面从未交给 .NET → 黑屏；RH1 修复
>    （别名注册覆盖两种约定 + 标准化壳构建，保留入口 record 修复所用的 bundle 名）**进行中（in flight）**。
>    见 §5d/§5e。
>
> **2026-09-24 状态（2026-10-01 更新至 kit #36）**：四个启动阻塞均已在 kit #10/#11/#12/#16（+ #17 `libIsolation` repack）修复；当前发布 = **kit #45**（2026-10-04；#45 = #44 + **自动释放（FIX-AUTODISCONNECT）+ 渲染门控（INTERP-RENDER）**；发布实测 tar **67,695,181 / `ca48a93c…`**、树 `ae0f7fce…`、sidecar `9741aced…`、bundle 73,058,366 / `a8334c4c…`（sdk 锚 `c7ac81ccdf`）；套件 587/589 floor 569；预签刷新至 #45（67,624,950 / `e1ce8ab6…`，asset 609411819）；#44 = #43 + **动态槽（SLOTS-DYNAMIC：MAX/HOT 默认 4/2、按需 ensure/destroy、容量事件降级/LRU、释放即拆、壳 ForEach + defer 队列；**3 控件并发出画/交互**）**；壳 abc **368,812（`1076a700…`）**/headless 24,324（`798b2477…`）、宿主 **297,888（`7b1694d9…`）**、导出 **151**、套件 **584/586 floor 566**；**预签已刷新（#44 件：67,627,789 / `75a40110…`，asset 608782132）**；发布实测 tar **67,680,863 B / `b777d8d8…`**、树 **`db2604d5…`**、sidecar **`85d62a6e…`**、bundle **73,052,763 / `3b3008a4…`**（sdk 锚 **`2abf4fcaa3`**；发布已完成，以 release「## Integrity（kit #44）」与随包校验为准）；更早 = **kit #43**（2026-10-04；#43 = **默认 AOT（5 MAUI hap 全 NativeAOT、`runtime-mode.txt=aot`、无 JIT 运行时；JIT 保形态需 ACL/豁免）+ FRAMEPACING（宿主 present telemetry；17.7 fps 系壳状态轮询伪影、实际 60.00 fps）**；套件 578/580 floor 560、导出 151、abc 356,468（`dd04dad1…`）/24,324、宿主 297,888（`7b1694d9…`）；发布实测 tar **67,638,015 B / `57c7bf44…`**、树 `0c41f071…`、sidecar `bd1f8e33…`、bundle **73,037,790 / `929b7263…`**（sdk 锚 `1c4f21ce13`；预签 67,585,222 / `08412475…`））；更早 = **kit #42**（2026-10-03；#42 = #41 + **JIT 解锁（prctl JITFORT + ICU invariant → JIT 首帧）+ 解释器 rc2b（首帧；`ohos-interpreter-pack-rc2b.tar.gz` 2,410,595/`5974430509…`，asset 606999003）+ FIX-SLICERACE（8/8）+ L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c/镜像扩展**；壳 abc **356,468（`dd04dad1…`）**/headless 24,324、宿主 **297,888（`08abe185…`）**、导出 **151**、套件 **578/580 floor 560**；**预签未刷新（仍 #41 件）**；发布实测 tar **376,256,128 B / `ea4e3b58…`**、树 **`13f3a086…`**、sidecar **`878d05a1…`**、bundle **73,047,352 / `570c0821…`**（sdk 锚 **`35101fe1f5`**；发布已完成，以 release「## Integrity（kit #42）」与随包校验为准）；更早 = **kit #41**（2026-10-03；#41 = #40 + **MULTI-OVERLAY-FULL（双槽 LRU 覆盖层池 + per-slot hybrid invoke/消息 + z-order）+ DEVCOMPAT-DEFAULT（payload 码签重写默认化，enforcing 镜像开箱可装）+ INTERP-FIX（8 MB 栈 + 关写屏障；rc.2 解释器 pack `ohos-interpreter-pack-rc2.tar.gz` 2,409,070 / `34709a94…`）**；壳 abc **356,140（`2a90f0d7…`）**/headless 24,324、宿主 293,792（`8d67def3…`）、导出 150、套件 563/floor 543；**预签刷新至 #41**（376,684,381 / `2075650a…`，asset 606183753）；发布实测 tar **376,036,502 B / `bed460ae…`**、树 **`7ce1946e…`**、sidecar **`2a95e764…`**、bundle **73,040,293 / `c98375a5…`**（sdk 锚 **`2222ba959f`**；发布已完成，以 release「## Integrity（kit #41）」与随包校验为准）；更早 = **kit #40**（2026-10-02；#40 = #39 + **FIX-JSCALL（BlazorWebView IPC 出站 JSCall 枚举/NavigationOptions AOT 扎根 → razor 计数往返 0→1→2 真机；截图 r0/r1/r2）**；壳 abc **342,160（`ffda66da…`）**/headless 24,324（未变）、宿主 293,792（`384e552a…`）（未变）、导出 150、套件 555/floor 535；发布实测 tar **375,836,470 B / `31ab8732…`**、树 **`e950de54…`**、sidecar **`9b051247…`**、bundle **77,750,495 / `434d2b6f…`**（sdk 锚 **`77ffe1dad6`**；发布已完成，以 release「## Integrity（kit #40）」与随包校验为准）；更早 = **kit #39**（2026-10-02；#39 = #38 + **FIX-BACKSIZE（Back 关抽屉：壳 `onBackPress()`→host `host.backPressed`/`ohos_host_register_back_pressed`，导出 150；`BlazorWebView.GetDesiredSize` 覆写）+ FIX-BWVMount（NativeAOT `.razor` 组件挂载出画）**；壳 abc **342,160（`ffda66da…`）**/headless 24,324、宿主 293,792（`384e552a…`）、导出 150、套件 554/floor 534；发布实测 tar **375,765,521 B / `e95eed49…`**、树 **`932e7955…`**、sidecar **`e5fc82de…`**、bundle **77,760,996 / `84d57989…`**（sdk 锚 **`2f1ace0a58`**；发布已完成，以 release「## Integrity（kit #39）」与随包校验为准）；更早 = **kit #38**（2026-10-01；#38 = #37 + **FIX-DISMISS（抽屉外点关闭：`Default`→`Popover`）+ FIX-WVP（Hybrid overlay px→vp / hybrid origin / z-order / 抽屉与切页 suspend）**；壳 abc **341,560（`4f02cb1d…`）**/headless 24,324、宿主 293,792（`4e9f3c3e…`）、套件 550/floor 530、导出 149；**FIX-BACK 波次未入包**（Back 关抽屉/BlazorWebView 尺寸在途，将随下一版）；发布实测 tar **375,641,619 B / `ced5583f…`**、树 **`307004e1…`**、sidecar **`8982fad0…`**、bundle **77,742,112 / `3284e317…`**（sdk 锚 **`ee1163a004`**；发布已完成，以 release「## Integrity（kit #38）」与随包校验为准）；更早 = **kit #37**（2026-10-01；#37 = #36 + **FIX-HOME（NavigationPage arrange 下钻 → Home 页整页出画）+ FIX-ITOUCH（element 坐标：注入/触摸与鼠标同面，页内点击命中）**；套件 544/floor 524、导出 149、abc 339,964/24,324（壳字节不变）、宿主 293,792（`4e9f3c3e…`）；发布实测 tar **375,652,577 B / `3a7259d6…`**、树 **`ab517b57…`**、sidecar **`7db60a77…`**、bundle **77,754,907 / `8abba9b1…`**（sdk 锚 **`d05247b90b`**；发布已完成，以 release「## Integrity（kit #37）」与随包校验为准）；更早 = **kit #36**（2026-10-01；#36 = #35 + **payload 原地直载（AOT 路径真机 BLZ）+ host 预注册缓冲 + 像素 Known 清零 + a11y 渲染帧修复 + rc.2 AOT pack `-r2`**；套件 540/floor 520、导出 149、abc 339,964/24,324、宿主 293,792；发布实测 tar **375,627,841 B / `9eb9cecf…`**、树 **`9764827c…`**、sidecar **`4d7062c3…`**、bundle **77,749,969 / `aeb6888a…`**（sdk 锚 **`b59c3d02e3`**；发布已完成，以 release「## Integrity（kit #36）」与随包校验为准）；更早 = **kit #35**（2026-09-30；W9/W10 并入主线：B2 真机 BLZ 打通（`BLZ_BOOT`/`BLZ_RENDERED`，pid 6157）+ T20 媒体传输层（本机镜像无 MediaKit 属预期）+ T14/T21/T8 余项 + AOT 入口修复（rc.2 AOT 包 shim 缺陷 → 本地钉 rc.1）；套件 540/floor 520、导出 149、abc 339,164/23,516、宿主 293,792；发布实测 tar **375,629,423 B / `419d42e2…`**、树 **`d3b1b317…`**、sidecar **`d7e79d39…`**、bundle **77,754,383 / `acd26821…`**（sdk 锚 **`02a31ef348`**；发布已完成，以 release「## Integrity（kit #35）」与随包校验为准）；更早 = **kit #34**（2026-09-30；rc.2 基线 + MAUI W6/W7/W8（套件 513/floor 493、导出 145）+ AOT v3）；更早 = **kit #33**（Blazor 回归修复/双 hap A/B + TabbedPage/A11Y + W5 470/450 + AOT v2）；更早 = **kit #32**（WebView 六项接线 + B1 razor 独立资产 + SEC 收口；tester-run v14；abc 289992；#31 = Blazor WASM/ArkWeb 组件：第 6 个 hap **`hello-blazorwasm-host-unsigned.hap`**（26,794,931 B / `36010a9c…`，未签名，bundle **`com.example.opendotnet`**，需自签）+ tester-run v13（`--blazor-probe`：`BLZ_BOOT`/`BLZ_RENDERED` 断言）；#30：runtime-mode 打包开关（`-p:OpenHarmonyRuntimeMode` → `libs/<abi>/runtime-mode.txt`；宿主 file>manifest>default）、tester-run v12（`runtime_mode`）与 MAPFIX harmony 重切（MapOverlay 真编译）；R3（#29）CoreSpeechKit TTS（无 Kit 降级不抛；真朗读需 HMS 设备 + harmony 壳）+ HUKS-first SecureStorage（设备绑定 AES-256-GCM 密钥、0 权限；无 HUKS 回退文件密钥）+ 自绘深度五连（文本编辑/动画/列表/图片/深链）；R2（#28）Map 覆盖层/LiveView/`start_app` AOT 桥/解释器；#27 KIT-EXT2 Push/Account/Map 探测 + 130/130 导出 + marshal-off；#26 P2-INTEROP `LibraryImport` hosting + TASK-MIG + PLAT-GAP；自 #21 起含 headless 变体 abc `13.0.1.0` 修复；#24 起含 payload-in-libs + 显式 W^X=0 + exec-memory 探针；#25 含权限链/Share-Scan/AOT），§5d/§5e 的「进行中」均为当时快照。设备侧诊断（app-lib 键、别名注册行、首帧、execmem）已并入 `tester-run.sh`，见 `docs/plans/2026-09-21-ohos-device-crash-diagnostics.md` §2.4–§2.6。
> **2026-09-24 设备证据修正（新增；2026-09-30 更新至 kit #34）**：当前发布已前进到 **kit #34**（#34 = rc.2 基线 + W6/W7/W8 + AOT v3；此前 #33 = Blazor 回归修复 + TabbedPage/A11Y + W5 + AOT v2；此前 #32 = WebView 接线/B1/SEC 收口；此前 #22 设备里程碑回灌（宿主按需 dlsym、`resources.index`、ZIP offset/mkdir、DevEco 工程布局）→ #23 工具刷新 → #24 payload-in-libs + 显式 W^X=0 + exec-memory 探针 → #25 权限链 + Share/Scan 探测 + AOT 启动路径 → #26 LibraryImport hosting 重建 + pack 任务程序集 + PLAT-GAP 缺省化 → #27 KIT-EXT2 Push/Account/Map 探测 + 130/130 导出 + marshal-off → #28 R2 Map 覆盖层 + LiveView 探测 + `start_app` AOT 桥 + 解释器开关 → #29 R3 TTS/HUKS/自绘深度 + `tester-run.sh` v11 → #30 MS-MODE runtime-mode 打包开关 + `tester-run.sh` v12 + MAPFIX harmony 重切（导出契约 143/143、套件 387/367 → 391/371）→ #31 Blazor WASM/ArkWeb 组件 + tester-run v13（`--blazor-probe`：`BLZ_BOOT`/`BLZ_RENDERED`；MAUI 主包不变；整包 tar **207,023,588 B / `f4325d2f…`**、树 **`52e77ee8…`**、sidecar **`7d0cba77…`**）；见 `2026-09-24-ohos-device-milestone.md`、`2026-09-25-ohos-tester-handoff-kit25.md`、`2026-09-26-ohos-tester-handoff-kit26.md`、`2026-09-27-ohos-tester-handoff-kit27.md`、`2026-09-26-ohos-tester-handoff-kit28.md`、`2026-09-28-ohos-tester-handoff-kit29.md`、`2026-09-28-ohos-tester-handoff-kit30.md`、`2026-09-29-ohos-tester-handoff-kit31.md` 与 `2026-09-22-ohos-release-manifest.md`）；旧 #4（libIsolation/napi path）降级为「**无害加固、非关键**」——真实直接链 5 项、回灌映射与边界见 §5f。

## 0. 一手材料与验证环境

- 反馈原文（2026-09-22）：`ohos-device-test-kit-feedback.md`（本机 `~/Download/com.haitai.htbrowser/`）；反馈对象 springmin。
- 测试包：GitHub release `springmin/sdk-ohos` tag `device-test-kit`（commit `38a53d7`）。
- 设备：HUAWEI MateBook Pro（HAD-W24），HarmonyOS 7.0.0.105（SP7ENTC293E102R2P1log），`const.ohos.apiversion=26`，arm64-v8a。
- UDID：`60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`；hdc 3.2.0c（DevEco SDK toolchains）。
- 测试方签名：PKI 在线签名（调试证书绑定上述 UDID；bundleName `com.example.hellomauiapp`；profile type=debug；有效期 2026-09-22 ~ 2027-07-21）。
- 交付包校验：`device-test-kit.tar.gz` sha256 与外层 sidecar 一致 ✅；解压后
  `verify-kit.sh --expect-tree-digest e0eea6719c12334285910027cf9dbe0eb0163544f30727f3f55b1057ea64c660` 全部通过 ✅
  （即崩溃与传输/解压损坏无关）。

## 1. 现象（两步）

### 1.1 包内 hap 安装：`9568257`（预期，与崩溃无关）

```
failed to install bundle. code:9568257 error: fail to verify pkcs7 file
```

4 个默认 hap（默认 / permissions / api20 / api20-permissions）与 P1–P4 探针包均如此。测试方拆包检查未发现
可用签名块（无 `HapSignInfo`、`signature/` 目录、`profile.p7b`）；交付方口径是"这 4 个 hap 用我方调试材料自
签名（`sign-profile`/`sign-app` + `verify-app` 只证明**包内自洽**，不等于设备信任）"。两种描述指向同一结论：
**真机以 `9568257`（profile/绑定不通过时为 `9568344`）拒绝属预期**，必须重签或用预签包，不需要把它当崩溃线索。

### 1.2 重签后安装成功，启动即退（真实崩溃）

```
ReferenceError: Cannot find module 'ets/entryability/EntryAbility' , which is application Entry Point
```

hilog 关键行：

```
AppKit: com.example.hellomauiapp is about to exit due to RuntimeError
AppKit: Error type:ReferenceError
AppKit: Error message:Cannot find module 'ets/entryability/EntryAbility' , which is application Entry Point
AppKit: ... ModulePathHelper::ConcatFileNameWithMerge ... HostResolveImportedModuleWithMerge
appspawn: com.example.hellomauiapp with pid xxxx exit with code:254
```

退出耗时约 1 秒；`exit 254`。

## 2. 证据链

### 2.1 基线事实（HAP 内容与声明）

- HAP 内 `ets/` 只有单个文件 `ets/modules.abc`（159,224 字节，kit 版本）。
- `module.json`：`module.mainElement="EntryAbility"`；`module.abilities[0].srcEntry="./ets/entryability/EntryAbility.ets"`；
  `compileMode="esmodule"`；`deviceTypes=["phone","tablet","2in1"]`。
- abc 字符串表里的模块记录名：
  - 短路径 `entry/src/main/ets/entryability/EntryAbility`（**带 `entry/` 前缀**）；
  - 长名 `entry|entry|1.0.0|src/main/ets/entryability/EntryAbility.ts`（**带 `entry|entry|1.0.0|src/main/` 前缀**）；
  - 该名字在 abc 中仅出现 **1~2 处**。

### 2.2 E1–E5 真机实验（全部实测，非推断）

| 实验 | 修改 | 结果 |
|---|---|---|
| E1 | 复制 `modules.abc` → `ets/entryability/EntryAbility.abc` | 仍报 `Cannot find module 'ets/entryability/EntryAbility'` |
| E2 | `srcEntry` → `./src/main/ets/entryability/EntryAbility.ets` | 报 `Cannot find module 'src/main/ets/entryability/EntryAbility'`（系统按 srcEntry 去 `./` 后查模块） |
| E3 | `srcEntry` → `./entry\|entry\|1.0.0\|src/main/ets/entryability/EntryAbility.ets` | 报 `Cannot find module 'entry\|entry\|1.0.0\|src/main/ets/entryability/EntryAbility'`（原样查） |
| E4 | 用 `es2abc --module --merge-abc --extension ts --record-name ets/entryability/EntryAbility --target-api-version 26` 编译最小壳替换 | **安装成功、模块名解析通过**（错误变为 `Cannot find module '@kit.AbilityKit' imported from 'ets/entryability/EntryAbility'`） |
| E5 | 在 E4 基础上把源码 import 改为 `@ohos.app.ability.UIAbility` 等点号老式写法 | 报 `Cannot find module '@ohos.app.ability.UIAbility'`（设备只认 DevEco 编译器转换后的 `@ohos:app.ability.*` 冒号格式） |

结论（E4 为关键证据）：**模块名 `ets/entryability/EntryAbility` 正确时设备能解析入口**；kit 的 abc 因模块
记录名/索引与 `srcEntry` 不匹配而入口定位失败。

### 2.3 与可运行工程 `cc-switch-ohos` 的对照（决定性证据）

测试方本机有一个可正常构建、安装、运行的鸿蒙工程 `cc-switch-ohos`（Tauri 应用，
`entry/build/default/intermediates/loader_out/default/ets/modules.abc`）：

- 相同点：记录名同样带 `entry|entry|1.0.0|src/main/…` 前缀；`srcEntry` 同样为 `./ets/entryability/EntryAbility.ets`；
  import 同样是 `@ohos:app.ability.*` 冒号格式（DevEco 编译产物）。
- 关键差异：

```
cc-switch（可运行）abc:
  'entry/src/main/ets/entryability/EntryAbility' 出现 37 次
  含 &entry/src/main/ets/entryability/EntryAbility&.#<唯一ID># 形式的完整 record 索引/引用条目
  本机 SDK ark_disasm 可正常反汇编（输出 286KB）

kit（崩溃）abc:
  'entry/src/main/ets/entryability/EntryAbility' 出现 1~2 次
  无 record 索引条目
  本机 SDK ark_disasm 报：abc file version 24.0.0.0, Maximum supported abc file version is 13.0.1.0
```

即：**kit 的 `modules.abc` 缺少设备运行时所需的 record 索引/映射结构**。`ark_disasm` 的版本差（kit 产物
24.0.0.0，本机 SDK 工具上限 13.0.1.0；本机为 OpenHarmony 6.0.2 / API 22）当时被判为工具侧限制；
**2026-09-22 更正**：入口 record 修复后的真机复测表明该版本差同时是**第二个独立阻塞**（设备 ark runtime
拒收高于 `13.0.1.0` 的 abc），见 §5b 与 `2026-09-22-ohos-arkts-abc-version-history.md`。

### 2.4 官方检索佐证（华为）

- 华为开发者论坛存在**一字不差的同类报错**：`Cannot execute module buffer file 'arkuix/ets/entryability/EntryAbility.abc'`
  + `Cannot find module '...' , which is application Entry Point`；官方答复为：把工程级 `build-profile.json5` 的
  **`useNormalizedOHMUrl` 设为 `false`** 试试。
- 华为 es2abc FAQ：`useNormalizedOHMUrl=true` 时工具链会对模块 URL 做标准化处理；HAR 中 Record 与工程实际依赖
  不一致会触发冲突。
- 华为 arkts-module-faq：`cannot find record` 类报错需检查编译产物（`filesInfo.txt`）与报错路径是否一致。

## 3. 根因

kit 打包时 ArkTS 壳的编译/归档配置（疑似 `useNormalizedOHMUrl=true` 或等价的标准化选项，也可能是
es2abc/hvigor 参数未对齐 `srcEntry`）导致：

1. `modules.abc` 内模块记录名带 `entry|entry|1.0.0|src/main/…` 前缀，与 `module.json` 的
   `srcEntry: ./ets/entryability/EntryAbility.ets` 不匹配；
2. abc 缺少设备运行时解析所需的 record 索引条目。

设备 ArkTS 运行时按 `srcEntry` 无法定位入口模块记录 → 应用启动即 `ReferenceError` 退出（`exit 254`）。

> 测试方原话保留：本机 `cc-switch` 的 `useNormalizedOHMUrl` 亦为 `true` 且可运行，故该配置是否为**唯一**根因
> 请以构建环境实测为准；**更确定的事实是 kit 的 abc 缺少 record 索引结构**。

## 4. 对既有假设的影响（H1/H2）

- **H1（宿主缺 `libc++_shared.so` → dlopen 失败）与 H2（宿主 dlopen / 入口 / dlsym）是硬化方向，不是本次崩溃
  的原因**：本次崩溃发生在 ArkTS 壳入口解析阶段，宿主 `.so` 尚未被加载。
- kit #5 起的随包 `libs/arm64-v8a/libc++_shared.so`（SDK ElfSigner 重签）、壳对非核心 Kit 的按需 `import()`、
  宿主 8 条 hilog 诊断均保留有效，但都不能修复入口 record 缺陷。
- 判读顺序调整：**先看退出错误**；命中本 ReferenceError 的 kit（截至 PA1 重建前）不需要再跑 P1–P4。P1–P4 阶梯
  仍适用于 dlopen / 缺库 / 宿主入口 / .NET 运行时类崩溃。

## 5. 修复（PA1；已完成，见 §5b）与验证计划

- 修复：`ohos-workload/scripts/build-arkts-shell.sh`（PA1，另一 agent）——让壳 abc 带完整、与 `srcEntry` 匹配的
  入口 record 索引（含试行 `useNormalizedOHMUrl=false` / 对齐 es2abc+hvigor 归档参数）。
- 出包：重建 `dist/ets/modules.abc` → `scripts/make-device-test-kit.sh` 重出 kit（本版同时新增 `签名说明.txt`，
  并让 `verify-kit.sh` 打印自签名警告）。
- 验证（设备侧）：重签 `hello-maui-app-unsigned.hap`（或按 UDID 预签）后安装启动；期望不再出现
  `ReferenceError … EntryAbility`，再按 `验收说明.md` / P1–P4 判读宿主与运行时（回归）。
- 状态：**已修复并验证**（kit #10：入口 record，测试方真机确认；kit #11：abc 版本，待真机回归）——
  收尾结论见 §5b。

## 5b. Resolution（已修复，2026-09-22）

前两个独立阻塞都已修复并进入交付：

1. **入口 record（PA1）**：壳构建改为 `useNormalizedOHMUrl=false` + bundle 前缀 record
   （`ohos-workload c2c4a9a`，壳归档 `6e55ae6`，162,996 B），随 **kit #10** 发布；测试方真机复测确认
   入口可解析（不再报 `ReferenceError … EntryAbility`）。
2. **abc 字节码版本**：修复入口后，真机复测暴露第二个阻塞 —— 壳 abc 头为 `24.0.0.0`，超出测试设备
   ark runtime 上限 `13.0.1.0`（hilog `export objects of native so is undefined` /
   `Cannot read property … of undefined`）。修复：壳构建固定 `compatibleSdkVersion 18`，
   SDK 26 工具链即产出 `13.0.1.0`（`ohos-workload 95c89a7`，壳归档 `ef1c947`，191,072 B），
   随 **kit #11** 发布（当前 kit；校验值见 release 说明「## Integrity」）。
3. **设备侧查询**：`xxd -l16 modules.abc`（期望 `0d 00 01 00` = `13.0.1.0`；`18 00 00 00` = `24.0.0.0`）
   与 `hdc shell param get const.ark.version`（设备运行时上限）；版本→API/SDK 映射与完整版本史见
   `2026-09-22-ohos-arkts-abc-version-history.md` §5。
4. **待办**：kit #12 的真机回归（重签 `hello-maui-app-unsigned.hap` 后按 `验收说明.md` 走）；
   三个分支已并入 `2026-09-21-ohos-crash-probes.md` §4.0/§4.0b/§4.0c 与决策表。

## 5c. 第三个阻塞：`host` undefined（宿主 `.so` 加载失败；kit #11 → kit #12）

kit #11 真机复测确认 abc 修复生效，并暴露第三个独立阻塞：

- **已验证的进展**：本机 `ark_disasm` 成功解析 kit #11 的 `ets/modules.abc`（头 `13.0.1.0`，191,072 B，
  反汇编输出 619,941 B；kit #10 的 `24.0.0.0` 当时被拒绝）；重签安装后 `[maui]` 日志大量出现，
  崩溃从入口模块解析推进到**页面/渲染阶段**；kit #11 已有的 `typeof host !== 'undefined'` 守卫把
  kit #10 的 `aboutToAppear` 崩溃降级为 `[maui] host export unavailable: <api>` 日志（不再抛异常）。
- **崩溃点**：`Index.ets` 的 XComponent `.onLoad` 中 `host.registerXComponent()` 是当时**唯一未纳入守卫**
  的宿主调用；`host` 为 undefined 时按名取属性（`ldobjbyname`）抛
  `TypeError: Cannot read property registerXComponent of undefined`（堆栈含
  `BCStub_HandleLdobjbynameImm8Id16StwCopy`），进程 `exit 254`。
- **归因（测试方报告）**：`host` undefined = `libopenharmonyhost.so` 加载失败。壳在 `EntryAbility.ui.ets` 的
  模块级 `import host from 'libopenharmonyhost.so'` 在 ability 加载时即触发 dlopen，而 `dotnet.zip`
  的解压发生在 `onCreate` 内稍后；宿主 `.so` 的加载期依赖若含只存在于 payload（`dotnet.zip`）中的库，
  加载器就无法解析 → NAPI 模块不初始化 → `host` 为 undefined（报告用 `readelf` 指认该项为
  `libhostfxr.so`）。官方依据：
  - 华为 FAQ `faqs-jsvm-9`：`readelf -d` 读出的依赖 so **必须打包进 HAP 或存在于系统库**，
    缺失会在应用启动过程中闪退；
  - 华为论坛主题「递归加载 DT_NEEDED」：任一依赖缺失、ABI 不符或存在未解析符号，都会在 NAPI 模块
    初始化前后直接闪退；
  - 华为论坛主题「启动时必加载的 .ets 中 import so」：`entryability.ets` 或首页 `.ets` 中 import 的 so
    会在 APP 启动时主动加载；
  - 「`export objects of native so is undefined` = native so 加载失败」的同类实测。
- **修复（kit #12；`ohos-workload 7e71c39` + 壳归档 `2411a8e`，2026-09-22）**：
  1. **链接期不依赖 `libhostfxr`**：宿主全部 `hostfxr_*` 入口保持经 `openharmony_host.c` 既有的
     `dlopen`/`dlsym` 表在 `start_app`/`run_app` 时解析（此时 payload 已解压，从
     `${payloadDir}/libhostfxr.so` 加载）；动态符号表无未定义的 `hostfxr_*` 符号；
  2. `scripts/build-host.sh` 增加**构建期 DT_NEEDED 审计**：`llvm-readelf` 打印加载期依赖面，出现
     `libhostfxr` 即构建失败（本次构建输出 `selfsign ok`，NEEDED 无 `libhostfxr`）；
  3. 宿主 dlopen 成功但入口缺失时，`run_app`/`start_app` 逐名打印缺失的 `hostfxr_*`（stderr + hilog），
     `dlerror` 路径保留；
  4. 壳模板（preview.22/23/24 三份保持一致：`Index.ets`、`EntryAbility.ets`、`EntryAbility.ui.ets`）
     把**每个** `host.<api>` 访问纳入 `hostCall` + `typeof host !== 'undefined'` 守卫，包括此前裸调的
     `host.registerXComponent()`、`pullMenu` 的 `menuCount`/`menuItem` 读与 `publishAppContext` 的
     显式 undefined 早退；宿主缺失时只记一次性 `host export unavailable` 日志，不再从页面/生命周期
     回调抛 TypeError。
- **产物证据（readelf/symbols）**：`readelf -d libopenharmonyhost.so | grep NEEDED` = 14 项
  （`libace_napi.z.so`、`libace_ndk.z.so`、`libhilog_ndk.z.so`、`libnative_window.so`、`libnative_drawing.so`、
  `libimage_source.so`、`libpixelmap.so`、`libohvibrator.z.so`、`libnet_connection.so`、
  `libability_access_control.so`、`liblocation_ndk.so`、`libohsensor.so`、`libc++_shared.so`、`libc.so`），
  **不含 `libhostfxr.so`**；`.dynstr` 无 `hostfxr`，动态符号表无未定义 `hostfxr_*`
  （`libhostfxr.so` 仅作为 dlopen 路径字符串出现）。壳重建：`13.0.1.0` abc（200,508 B，0 ArkTS:ERROR），
  交互套件 284 条 / 0 Unhandled / 性能门 within=True。
- **设备侧复核（宿主仍加载失败时）**：
  ```sh
  unzip -p hello-maui-app.hap libs/arm64-v8a/libopenharmonyhost.so > /tmp/host.so
  readelf -d /tmp/host.so | grep NEEDED                  # 加载期依赖面：每项都必须在下面两处之一
  unzip -l hello-maui-app.hap | grep 'libs/arm64-v8a/'   # ① 随 HAP 的 libs/<abi>/
  hdc shell ls -l /system/lib64/<每个 NEEDED 名>          # ② 设备系统库（libc++_shared.so 随包）
  hdc shell hilog | grep -iE "dlopen|not found|cannot find library|export objects of native so"
  ```
- **核验注（与报告 readelf 清单的差异）**：对测试方报告同哈希的 kit #11 tarball 内 5 个 hap 逐一
  `readelf -d`，宿主 NEEDED 均为上述 14 项、均不含 `libhostfxr.so`；宿主源码自始使用 dlopen/dlsym。
  报告的 NEEDED 清单（含 `libhostfxr.so`、缺 `libc.so`）与产物不一致，故本节把**症状链与官方依据**
  记为事实、把“具体缺失哪个加载期依赖”留给设备 hilog 的 `dlopen`/`dlerror` 行确认；kit #12 的守卫
  保证即使宿主再次加载失败也只逐 API 记 `host export unavailable`，不再 `exit 254`。

## 5d. 里程碑：kit #14 启动并稳定存活（2026-09-23）

测试方 kit #14 真机报告（包经 `verify-kit.sh` 树摘要校验通过，abc 被 `ark_disasm` 正常解析）。
**以下为设备实测（测试方日志）**：

- **首次启动成功且进程稳定存活**：`aa start` 返回 `start ability successfully.`；1 分钟+ 后主进程与
  `com.example.hellomauiapp:gpu` 进程仍在（`ps` 实测两行；此前各轮均为启动约 1 s 后 `exit 254`）。
- **零崩溃日志**：`hilog | grep hellomauiapp | grep -iE 'TypeError|JsError|exit with code|PROCESS_KILL|Error message'`
  为空；无 `AppKilledReporter` / jscrash。
- **三个既有根因在真机确认修复**（测试方四轮口径，对应本文 §5b/§5c）：① 入口 record（kit #10，
  `useNormalizedOHMUrl=false` + bundle 前缀 record）；② abc 字节码版本 `13.0.1.0`（kit #11，
  `compatibleSdkVersion 18`）；③ 运行时原生库不再留在 `dotnet.zip`，随 hap `libs/arm64-v8a/` 打包
  （kit #13/#14；`libs/` 实测含 `libhostfxr.so` / `libhostpolicy.so` / `libcoreclr.so` / `libclrjit.so`
  等 13 个 .NET 运行时 `.so` + `libopenharmonyhost.so` + `libc++_shared.so`，`dotnet.zip` 内已无 `.so`，
  宿主 `DT_NEEDED` 已不含 `libhostfxr.so`）—— 即 §5c 的宿主加载序问题在交付侧的最终落地。
- 里程碑句：**kit #14 是第一个「启动成功、进程存活、零崩溃日志」的构建**；黑屏是其后暴露的独立问题（§5e），
  不是崩溃回归。

## 5e. 第四个阻塞：黑屏 —— napi 注册名与 abc import 记录名不匹配（kit #14 暴露；RH1 进行中）

kit #14 的崩溃清零后，新现象是**黑屏（进程不退出）**：

- **设备实测证据（测试方 kit #14 日志）**：
  - ArkUI 侧 XComponent 已创建、挂树、表面已创建：
    `AceXcomponent: XComponent[ohos_dotnet_surface] AttachToMainTree …` 与
    `AceXcomponent: XComponent[ohos_dotnet_surface] triggers onLoad and OnSurfaceCreated callback`；
  - 同时段 `[maui] host export unavailable: <api>` 覆盖全部宿主 API（`setNodeContent`、`registerXComponent`、
    `setBundleInfo`、`register*Sink`、`menuCount` …）→ **host exports 整体为空**；
  - **决定性日志**：`ArkCompiler: [ecmascript] Load native module failed, ModuleName:
    @app:com.example.hellomauiapp/entry/openharmonyhost`，且全量 hilog 中**只有失败行、无任何成功加载行**
    （so 的 `Init` 从未被调用）；
  - 可运行对照工程 `cc-switch`：`useNormalizedOHMUrl=true`，abc 记录名 `@normalized:Y&&&libentry.so&`，
    so 注册名 `libentry.so` —— 两者匹配，正常渲染。
- **代码/包内事实**：宿主 `src/OpenHarmonyHost/host_napi.cpp` 的 `g_hostModule.nm_modname` 为裸名
  `"openharmonyhost"`；kit #14 壳 abc 在 `useNormalizedOHMUrl=false` 下把
  `import host from 'libopenharmonyhost.so'` 编译为记录名
  `@app:com.example.hellomauiapp/entry/openharmonyhost`，两者字符串形式不一致。
- **官方依据（华为，与设备无关的文档证据）**：ArkTS `import xxx from libxxx.so` 后 `xxx` 为
  undefined / not callable 时，须排查 native 模块注册名与 so / 模块名一致
  （`napi-faq-about-common-basic`；`use-napi-process` / `faqs-ndk-46`：导入模块名与注册模块名大小写一致，
  模块名 `entry` ↔ `libentry.so` ↔ `nm_modname = "entry"`）。
- **机制（设备日志 + 代码推断，非新增设备实验）**：设备按 abc 的 import 记录名查找 native 模块 → 注册名
  不匹配 → 模块从未初始化（无成功加载日志）→ host exports 为空 → `setNodeContent` / `registerXComponent`
  均不可用 → 表面虽已创建但从未交给 .NET/MAUI → 黑屏。
- **修复（RH1，进行中 / in flight；方案，非设备实测）**：宿主侧**别名注册**覆盖两种约定（裸名 +
  bundle 前缀记录名），并出**标准化壳构建**（`useNormalizedOHMUrl=true` 一侧），同时保留入口 record 修复
  所用的 bundle 名（`com.example.hellomauiapp`），**入口 record 需重新核验**。**截至本页写作时 RH1 尚未落地**：
  `ohos-workload` 工作树中 `host_napi.cpp` 仍为 `nm_modname = "openharmonyhost"`，无别名注册；最近提交是
  kit #15 的 rawfile 资源桥（与 RH1 无关）。RH1 落地后按「so 注册名 ↔ abc import 记录名」对照 +
  设备 `hilog | grep 'Load native module failed'` 是否消失来复核。

## 5f. 2026-09-24 设备证据修正（真机完整运行；旧 #4 降级为无害加固）

测试方 kit #17→#18 + 5 项本地修复后，在设备（HUAWEI MateBook Pro HAD-W24 / HarmonyOS 7.0.0.105 /
API 26 / arm64-v8a）**首次完整运行成功**：`managed app hello-maui-app.dll started (UI shell)`、
进程持续存活（主进程 + `:gpu`）、XComponent `native OnSurfaceCreated` 回调触发、ArkUI 渲染层工作
（`AceAppBar: callNative`）、`SmartGC: app cold start just finished`、无崩溃（无 `TypeError` /
`JsError` / `exit 254`）。**边界：这是 kit #18 + 测试方本地修复链的结果，stock kit #22 尚未上机。**

**对 §5d/§5e 第四阻塞（黑屏）的修正**：

- 旧 #4 的两个半边 —— RM1 `libIsolation`（模块级 app-lib `<bundle>/<module>` key）与 RH1
  nm 别名/注册名 —— **并非本次失败的关键**：成功运行的整份日志中没有 `Load native module failed`
  阻断；两项保留为**无害加固**（不撤、不回滚）。
- **直接链是另外 5 项**（按设备证据顺序）：① 宿主 `.so` dlopen 失败（设备缺 10 个系统库 + 62 个符号，
  含 IME `OH_InputMethodProxy_ShowKeyboard`）→ ② `dotnet publish` 的 HAP 缺 `resources.index`
  （`GetRawFileContent failed, name is empty`）→ ③ `fs.copyFile(zip.fd)` 忽略 `getRawFd` 的
  offset/length（`BusinessError 900003`）→ ④ 解压前缺 mkdir（`BusinessError 900002`）→
  ⑤ abc 由 DevEco 新建工程编译（hvigor `00302013`）。完整证据见
  `2026-09-24-ohos-device-milestone.md` §2。
- **libhostfxr 的 dlopen 候选 1/2 已由设备验证**：经宿主自身目录（`libs/arm64-v8a/`，namespace 允许）
  成功加载，未回退到解压目录（§5c 的候选逻辑生效）。
- **回灌映射（随 kit #22）**：`ohos-workload 64c989b`（宿主 NEEDED 5 库 + 可选 API dlsym + 门禁）·
  `61e6e81`/`4dd12a2`（ZIP offset / mkdir）+ `76a6f7a`（abc 重建）· `0f26b74`（`resources.index` via restool）·
  `019ddae`（DevEco 工程布局 + 00302013 诊断）；里程碑 §3 有权重与回归证据。
- **仍未验证**：stock kit #22、无 hilog/libnative_window 环境分支、`resources.index` legacy（579 B）与
  RestoolV2（707 B）的设备兼容、其余功能面与对照载荷 —— 见里程碑 §5/§6。

> §5b–§5e 保留当时的判断、证据与时间线，不改写；本节只做增量修正。

## 6. 六类错误的关系（避免混淆）

| 错误 | 含义 | 是否预期 | 处置 |
|---|---|---|---|
| `9568257 fail to verify pkcs7 file` | 自签名 hap 被设备拒绝（签名不受信任/无效） | 是（包内 4 个默认 hap） | 重签 `hello-maui-app-unsigned.hap` 或用预签包 |
| `9568344 install parse profile prop check error` | 调试 profile 未绑定本设备 UDID | 是 | 重签 / 回传 UDID 重签 / `--sign-external` 预签 |
| `ReferenceError … EntryAbility` + `exit 254` | 壳 abc 入口 record 缺陷 | **否**（kit #10 前） | kit #10 起已修复；重签新 kit 重测 |
| `export objects of native so is undefined` / `Cannot read property … of undefined` | 壳 abc 字节码版本高于设备 ark runtime 上限（`24.0.0.0` > `13.0.1.0`） | **否**（kit #11 前） | kit #11 起已修复（`compatibleSdkVersion 18` → `13.0.1.0`）；`xxd -l16 modules.abc` + `hdc shell param get const.ark.version` 复核 |
| `[maui] host export unavailable: <api>` / `Cannot read property registerXComponent of undefined` + `exit 254` | 宿主 `.so` 加载失败 → 壳 `host` 为 undefined（加载期 DT_NEEDED 在 `dotnet.zip` 解压前解析） | **否**（kit #12 前） | kit #12 起：宿主无 `libhostfxr` 链接依赖（dlopen/dlsym）+ 构建期 DT_NEEDED 审计；壳全部 `host.<api>` 守卫；`readelf -d … \| grep NEEDED` 对照 hap `libs/<abi>/` 与设备系统库（§5c） |
| `Load native module failed, ModuleName: @app:<bundle>/entry/openharmonyhost` + 全部 `[maui] host export unavailable: <api>`，应用启动后**黑屏但不崩** | napi 注册名（`nm_modname`）与 `useNormalizedOHMUrl=false` 下 abc 的 import 记录名不匹配 → host exports 为空 → XComponent 表面未交给 .NET | **否**（kit #14） | RH1（宿主别名注册覆盖两种约定 + 标准化壳构建、保留 bundle 名）**进行中（in flight）**；复核 so 注册名 ↔ abc 记录名，并用 `hilog \| grep 'Load native module failed'` 看失败行是否消失（§5e） |

## 7. 参考

- 测试方反馈原文：`ohos-device-test-kit-feedback.md`（2026-09-22；本机 `~/Download/com.haitai.htbrowser/`）
- 测试方 kit #11 报告：`ohos-device-test-kit-kit11-verification.md`（2026-09-22；同目录；第三个阻塞与官方依据出处）
- 测试方 kit #14 报告：`ohos-device-test-kit-kit14-verification.md`（2026-09-23；同目录；里程碑、黑屏根因、
  host exports 为空与 XComponent 日志、`cc-switch` 对照、华为 napi 注册名依据）
- 自签与重签：`2026-09-21-ohos-tester-selfsign.md`（包内 `自签说明.md`）、`2026-09-19-ohos-signing-and-udid-guide.md`
- 崩溃探针与决策表：`2026-09-21-ohos-crash-probes.md`（§4.0/§4.0b/§4.0c/§4.0d 已加四个分支）
- abc 版本史与设备查询：`2026-09-22-ohos-arkts-abc-version-history.md`
- 交付与状态：`2026-09-21-ohos-delivery-kit-readme.md`、`2026-09-21-ohos-final-status.md`
