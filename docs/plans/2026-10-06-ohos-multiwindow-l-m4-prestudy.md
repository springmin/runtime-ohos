# MULTIWINDOW-L M4 只读预研与去风险（焦点/IME/a11y/叠加层分区，2026-10-06）

> 口径：为计划 §M4（8–15 人日）去风险；**只读**（SDK 26.0.0.18 / API26 d.ts + 代码走查），未用设备、未构建、未写产品代码。
> 载体：ow `l/m3-shell-xcomponent` @ `35df4f4` · maui `l/m3-per-window-content` @ `d4ff7d445e`；证据为源码/接口面，非真机。
> 相关：`-l-plan.md` §M4 · `-l-acceptance.md` §3/§4（M4-01…07）· `-l-m2.md`（进程级清单）· `-l-feasibility.md` §3（N4）。

## 1) 焦点模型（窗激活 → MAUI 焦点；键/Back 路由）

- **现状（壳）**：Index.ets 已消费主/子窗 `windowEvent`：HIDDEN/SHOWN 直接启停、ACTIVE/INACTIVE 经 600ms 宽限（Home 链）归并为 `setSubWindowSuspended`，只上报 `SUB_EVENT_SUSPENDED/RESUMED`；子窗 DESTROYED 收口。**焦点身份未上报**（哪个窗有焦点、何时失焦没有 managed 事件）。
- **现状（managed）**：主窗走进程级 `LifecycleChanged`；子窗 `OpenHarmonyWindowHost.EnsureWindowActivated()` 只发一次 `Activated`，无 `Deactivated/Stopped/Resumed`（仅 surface Destroyed→`Destroying`）。元素级焦点：`OpenHarmonyFocusManager`（非文本）与 Entry/Editor/SearchBar 最终都调 `OpenHarmonyFocusBridge`，目标 id 固定为主窗页面的 `ohos_dotnet_surface`/`ohos_dotnet_input`；`RequestTextInput` 走全局 sink——**子窗里的 `Focus()` 会去点主窗的 ArkUI 目标，等于跨窗错认**。
- **键/Back**：只有主窗 XComponent `.focusable(true).onKeyEvent` → `host.keyEvent` → 单回调 `ohos_host_register_key_event` → 全局 `OpenHarmonyKeyListener`/`OpenHarmonyKeyboardAcceleratorManager`；SubWindow.ets 的 XComponent 无 focusable/onKeyEvent，页面无 `onBackPress`。
- **M4 映射**：窗激活 = 子窗 ACTIVE/INACTIVE/HIDDEN/SHOWN（+主窗失焦）→ 子窗 `IWindow.Activated/Deactivated/Stopped/Resumed` 状态机；元素焦点 = per-window 目标 id（子窗页自身的 surface/input id）+ 该窗 `FocusController`；键 = 子窗 XComponent 带窗 id 的 keyEvent + 按窗 dispatch；Back = SubWindow.ets 增 `onBackPress`（携窗 id）→ 该窗内容（drawer 等）。
- **风险**：`focusController.requestFocus` 按 UIContext 生效，主窗 id 在子窗无效（预期失败而非静默）；失焦时 MAUI 期望 `Unfocus`（当前无人发）；系统 Back 能否被子窗页截获未证。→ 先做单窗内自洽 + M4 首轮真机探针。

## 2) IME / 软键盘

- **现状**：壳在主页面挂隐藏 `TextInput`（id `ohos_dotnet_input`），`registerFocusSink`/`registerTextInputSink` 单槽；宿主 NDK 侧 `openharmony_host.c` 单套 `g_editor_proxy`/`g_inputmethod_proxy`/`g_ime_text`（进程级 attach；`ohos_host_keyboard_show/hide`）。子窗要收键盘必须有自己的输入控件/焦点路径。
- **平台面**：SDK 支持按窗绑定——`@ohos.inputMethod` `attachWithUIContext(uiContext, textConfig, attachOptions)`、`TextConfig.windowId`、`setCallingWindow(windowId)`；NDK `OH_InputMethodController_AttachWithUIContext(context,…)`、`OH_TextConfig_SetWindowId`（attach 生命周期"到下一次 attach/detach"）。→ 子窗页可自挂隐藏 `TextInput`+onChange/onSubmit（沿用主页面模式），managed 侧按窗 sink/焦点窗选路。
- **互斥**：系统 IME 同一时刻只服务焦点窗（键盘唯一）；切窗时旧窗 hide/新窗 show（或按 UIContext 重新 attach），`g_ime_text`/回调缓冲需 per-window 化或按焦点窗路由。
- **测试**：M4-02 真机：子窗 Entry 聚焦 → 键盘覆子窗、`uitest uiInput` 文本只进子窗；切主窗 Entry → 键盘跟随、子窗文本不变；失焦收起；证据 = 带窗 id 的 text-sink hilog + 截图。离线：断言 focus/text-input 调用携带窗 id；红控 = 去掉 tag 后子窗文本落主窗（断言 False）。

## 3) a11y 分区

- **现状**：单 `OpenHarmonyAccessibility.s_frame` + 单宿主 provider（主窗 NodeContent 的 CUSTOM 节点）；`Renderer.Render` 每帧 `Refresh(content)+Publish()`——M3 后**两个窗的渲染会互相覆盖影子树**（后渲者胜），子窗节点无法被稳定读出。`PushChildren` 本身按 root 走树（可复用），但 alert 节点是进程级追加。
- **必要性**：不分区则（a）子窗渲染破坏主窗 a11y 快照，（b）子窗树无 provider 归属。分区 = `Refresh/Publish` 带窗 id（每窗一个 Frame）；宿主节点表按窗（或合成根）；子窗要在 SubWindow.ets 挂 ContentSlot 并 `setNodeContent`（按窗导出），或探 `OH_ArkUI_AccessibilityProviderRegisterCallbackWithInstance`（API15+）并存两个 provider。
- **PushChildren 影响面**：仅 `Visit` 的 root/titleBar/alert 语境；改为「每窗 Frame」后 walker 不变；`BuildNode/TryFindNode/TryFindView/IsModalNode` 需显式窗参数；`OpenHarmonyAlertHost` 全局 → alert 归属随窗（见 §4）。
- **无读屏机离线红/绿**：绿 = headless 先发布 A 窗再发布 B 窗，断言 A 节点仍完整、动作路由到 A 的 view、nodeCount 分窗；红 = 还原全局 `s_frame` 后 A 被 B 覆盖（断言 False）。SEC-SCAN-4 密码脱敏 pin 复制到子窗。真机 `--a11y-probe` 扩窗化 self-check（main/sub nodeCount），不依赖读屏服务。
- **风险**：主+子两个 provider 能否并存未证；子窗无宿主时降级为「主窗 provider 不覆盖子窗」并如实标注。→ 第一刀先做「互不覆盖 + 主窗零回归」，子窗 provider 上探 ≤2pd。

## 4) overlay / pinch / safe-area / fonts / MauiContext

| 项 | 进程级现状 | per-window 需要 | 结论（做 / 延后）与量 |
|---|---|---|---|
| overlay 宿主 | `OpenHarmonyWindowOverlayHost` 全局注册表 + `SurfacePresent` 钩子 + N5 免穿透会话；M3 已让非主窗绕过 `SurfacePresent` | overlay→窗归属；N5 会话按窗；子窗自绘 overlay | **做**（否则子窗不画、N5 跨窗吞触摸）1–2pd |
| alert/flyout | `OpenHarmonyAlertHost` 单 `Current`/尺寸（最后渲染者写几何），两窗都画同一弹窗 | 每窗 alert 状态/归属（或按窗实例化） | **做**，1pd |
| ArkWeb/CEF 槽 | 槽池只声明在 Index.ets，managed web handler 全局领槽 | 子窗页第二宿主 + 带窗槽命令 | 条件做：时间盒 ≤2pd，超限**延后**（单宿主主窗化 + 文档） |
| pinch | 宿主只在主路由算 pinch；`OpenHarmonyBridge.Pinch` 全局→主 renderer | 两条路由都算 + 带窗事件 + 每窗 renderer | **做**，0.5–1pd（M4-04 交互面一部分） |
| safe-area | `OpenHarmonySafeArea`/native 单套 avoid+soft-input；壳从主窗上报 | 子窗 avoid/键盘按窗上报，`ArrangeContent` 已共享 | **做软键盘项**（随 IME），系统条 0.5–1.5pd 可**延后**（2in1 子窗常为 0） |
| fonts | 全局上报一次，主 host 重排 | 子窗 host 订阅 `Changed` 重排（scale 本身全局一致） | **做**，0.5pd（不做则子窗字号/布局不回排） |
| MauiContext/DI | 单 `MauiContext`、renderer/surface 单例；子窗共享 | 窗作用域 DI/服务 | **延后**：现无样本可见失败 → 记录限制（仅失败才做，0–1pd） |

## 5) M4×7 用例 ↔ 实现项映射与顺序（先易后难）

| 用例 | 实现项（ow / maui） | 顺序 |
|---|---|---|
| M4-05 suspend/resume | 子窗 ACTIVE/INACTIVE/HIDDEN/SHOWN→`IWindow` 状态机；主窗 HIDDEN 扇出；Home 链（#50） | 1（地基） |
| M4-02 焦点/IME | SubWindow：focusable XComponent+onKeyEvent+onBackPress+隐藏 TextInput；宿主带窗 focus/text/键路由；maui per-window 焦点/键盘 | 2 |
| M4-03 a11y | 每窗 Frame + 窗化 Publish/setNodeContent（子窗 provider 探针）+ self-check 分窗 | 3（可与 2 后半并行） |
| M4-04 overlay/ArkWeb | overlay/alert 归属隔离 + pinch 带窗 + 子窗 web 宿主（时间盒） | 4 |
| M4-01 双窗帧率 | framepacing + 双窗动画/滚动对照（阈值 M3 后冻结） | 5（需 2–4 交互面） |
| M4-07 混合 JIT/AOT | mode kit 双窗主路径 + probe/首帧对照 | 6（可 4 后启动，长跑排后） |
| M4-06 40min 长稳 | device-round soak + 双窗 churn/suspend 叠加 | 7（全栈最后） |

## 6) 人日再估与关键未知

- **再估 13–20 人日**（计划 8–15）：焦点/生命周期 3–4 · IME 2–3 · a11y 3–5 · overlay/pinch/safe-area/fonts 2–3 · 全量验证轮（矩阵/长稳/性能/混合模式/文档）3–5。M3 与套件地基好可取下沿；a11y 子窗 provider 与子窗 ArkWeb 任一项超时间盒即加上沿。
- **建议**：M4 进场时把 12–18 重新冻结，并预置降级线——子窗 a11y provider 失败 → 主窗零回归 + 子窗不覆盖（文档标注）；子窗 ArkWeb 超 2pd → 单 overlay 宿主（主窗）+ 后补。
- **关键未知**：① 主+子两个 a11y provider 能否并存（NodeContent/CUSTOM 或 instanceId）；② 子窗能否经 `attachWithUIContext`/子窗页 TextInput 真收 IME（含互斥/切窗序列）；③ 子窗 XComponent `.focusable(true)` 的键事件与子窗页 `onBackPress` 是否被平台派发；④ 子窗 ArkWeb 第二宿主成本；⑤ M3-03（焦点/z-order/Back）未列 M3 真机卡，M4 视为待证；⑥ 双窗帧率/内存阈值未冻结（M3 首测校准）；⑦ M4-05 Home 路径依赖 #50 `b5928d1` 出包。
