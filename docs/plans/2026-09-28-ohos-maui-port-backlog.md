# MAUI 移植缺口审计与本地可执行 Backlog（MAUI-GAP-AUDIT，2026-09-28）

> **口径**：只读代码/文档审计，无构建、无真机；「已实现」= 代码路径 + 离设备证据（交互套件基线 **398 / floor 378**，
> `ohos-workload/test/maui-platform-verify/Program.cs:16`），上设备前 ≠ 已验证。基线 = maui-ohos `feature/openharmony`
> tip `33b0af79`（119 个 `.cs`）+ 覆盖矩阵（`2026-09-22-ohos-maui-coverage-matrix.md`）与 Kit 缺口复核（`2026-09-24-ohos-kit-gap-analysis.md`）。
> **增量与更正**：WebView W 系列（`d6325990`）与 SEC-SCAN-3（`7c75b88f`/`3c2cd28c`/`33b0af79`）已计入；矩阵旧结论中
> MainThread（rc.1 框架 `BridgeMainThreadFromDispatcher` 桥接）、SoftInput、ConnectivityProfiles 已由后续提交修正。

## 1. 状态矩阵（34 面）

| # | 面 | 状态 | 证据（maui-ohos 切片，除注明外） | 缺口 |
|---|---|---|---|---|
| 1 | Layouts（Stack/Grid/Flex/Absolute/Relative） | 部分 | LayoutHandler/ContentArrange/SafeArea | ZIndex 空实现、视图级 Clip 不裁剪、InputTransparent 未接、AnchorX/Y 未参与变换 |
| 2 | Shapes/路径 | 已实现 | ShapeHandler/Paths | — |
| 3 | Brushes/阴影 | 已实现 | Shape/Border 绘制；gradient/image paint 走 canvas | 阴影仅纯色 Paint（已记录降级） |
| 4 | 基础控件 Label/Button/Image/ImageButton/BoxView/Frame/Border/ContentView | 部分 | 各 handler | Label 无 FormattedText/Spans |
| 5 | 选择/范围 Switch/CheckBox/RadioButton/Slider/Stepper | 已实现 | 各 handler | — |
| 6 | 进度/指示 ProgressBar/ActivityIndicator/IndicatorView | 已实现 | 各 handler | — |
| 7 | InputView Entry/Editor/SearchBar | 部分 | Entry/Editor/SearchBar handler | MaxLength/IsPassword/IsReadOnly/ClearButton/ReturnType/PlaceholderColor/对齐/Keyboard 未映射 |
| 8 | Picker/DatePicker/TimePicker | 部分 | Picker/Date/Time handler | DatePicker 仅 ±7 天下拉、无日历、Min/Max 忽略 |
| 9 | RefreshView | 已实现 | RefreshViewHandler | — |
| 10 | ScrollView | 已实现 | ScrollViewHandler + 滚动物理/滚动条 | — |
| 11 | CollectionView | 已实现 | CollectionViewHandler + materializer | GroupFooterTemplate 仅 Label 文本 |
| 12 | ListView（含 Cell） | 已实现 | ListViewHandler（SwitchCell/EntryCell/TextCell/ViewCell） | — |
| 13 | CarouselView | 部分 | CarouselViewHandler | 分组头/尾不可表达 |
| 14 | SwipeView | 已实现 | SwipeViewHandler | — |
| 15 | TableView | 缺失 | 无 ITableViewController/渲染器 | 无平台实现（可复用 ListView 行物化） |
| 16 | WebView | 部分 | WebViewHandler（W1–W5：历史/Cookie/frame/导航事件） | 文件选择/媒体权限/多窗口/CookieContainer 同步 |
| 17 | HybridWebView | 已实现 | HybridWebViewHandler | — |
| 18 | BlazorWebView | 部分 | Blazor handler（B1 门控） | B2 WASM staging/引导/布局未做 |
| 19 | 手势 Tap/Pan/Swipe/Pinch/Pointer/Drag | 已实现 | Gestures/Pinch/Pointer/DragAndDrop | 文件/URI 拖放载荷受 Controls 契约限制 |
| 20 | Navigation/Page/Tabbed/Flyout | 已实现 | 各 handler + PageTransitions | — |
| 21 | Shell | 部分 | ShellHandler/Extras/Chrome/AppLinks/Menus | 富 flyout/TitleView 仅文本；菜单平铺无子菜单 |
| 22 | 动画 | 已实现 | AnimationLoop/Ticker/Transitions/SharedTransition/Motion | — |
| 23 | GraphicsView | 部分 | GraphicsViewHandler | 仅 tap；无 drag/hover/多点/Invalidate 请求 |
| 24 | Window/App 生命周期 | 已实现 | AppHost/WindowHandler/ApplicationHandler | — |
| 25 | 多窗口 | 部分 | ApplicationHandler 诚实单窗语义 | 真多窗未实现（设备 2in1/平板） |
| 26 | 平台扩展 Menu/Notify/BLE/Print/Scan/Push/Account/Map/LiveView/Contacts/Sensors | 已实现（探测） | 各 `OpenHarmony*.cs` + 壳 sink | 真调用需 HMS/AGC（外部） |
| 27 | Essentials | 部分 | DI 全表（MauiOpenHarmonyExtensions.cs） | IMap 缺失；WebAuthenticator/AppActions 降级；Screenshot JPEG→PNG |
| 28 | 无障碍 | 部分 | OpenHarmonyAccessibility + 影子树/动作/announce | 自绘弹层未进树；真机待验 |
| 29 | 字体/本地化 | 已实现 | FontManager（字体文件解析）；本地化无平台面 | 无系统字体缩放跟随 |
| 30 | RTL | 缺失 | 全切片无 FlowDirection 引用 | 排布/绘制/命中未镜像 |
| 31 | 打印 | 已实现（平台扩展） | OpenHarmonyBluetoothPrinting（PDF 渲染/打印） | 无上游 IPrint 契约；设备验证外部 |
| 32 | TitleBar/Adorner/快捷键 | 部分 | slice-notes「零引用接口」记录 | Window.TitleBar 无；VisualDiagnosticsOverlay 未初始化；每元素快捷键缺上游 API |
| 33 | 主题（明暗） | 已实现 | OpenHarmonyTheme | — |
| 34 | MediaElement（社区工具包） | 缺失 | 无 | 需 AudioKit/MediaKit/AVSessionKit 播放层 |

计数：已实现 18 · 部分 13 · 缺失 3 · 外部依赖 7（§3）。

## 2. 本地可执行任务清单（按建议优先级排序）

| # | 任务 | 规模 | 目标文件 | 门禁 | 依赖 |
|---|---|---|---|---|---|
| T1 | InputView 映射补全（MaxLength/IsPassword/IsReadOnly/ClearButton/ReturnType/PlaceholderColor/对齐/Keyboard） | S | Entry/Editor/SearchBar handler + OpenHarmonyView | 切片+交互套件+像素 | — |
| T2 | WebView 小缺口批（#11 文件选择 / #12 媒体权限 / #13 window.open + CookieContainer 同步） | S×4 | OpenHarmonyWebViewHandler + 壳 Index.ets + 套件 | 切片+交互套件+harness | 壳同波串行 |
| T3 | GraphicsView 交互（drag/hover/多点 + Invalidate 重绘请求） | M | GraphicsViewHandler + OpenHarmonyView + renderer | 切片+交互套件+像素 | — |
| T4 | Label FormattedText/Spans 富文本 | M | LabelHandler + OpenHarmonyView | 切片+交互套件+像素 | — |
| T5 | Layout 语义补齐（ZIndex 绘制序/Clip/InputTransparent/AnchorX/Y） | M | renderer + LayoutHandler + OpenHarmonyView | 切片+交互套件+像素 | — |
| T6 | RTL/FlowDirection 镜像（排布/绘制/命中/菜单） | M | ContentArrange + OpenHarmonyView + renderer | 切片+交互套件+像素 | T5 |
| T7 | DatePicker 日历 + Min/Max 钳制 | M | DatePickerHandler + Picker | 切片+交互套件 | — |
| T8 | TableView + ITableViewController（复用 ListView 行物化） | M/L | 新 TableViewHandler + ListViewHandler + 注册 | 切片+交互套件+harness | — |
| T9 | TitleBar 行（Window.TitleBar：measure/arrange/draw/touch/返回位） | M | 新 TitleBar 文件 + WindowHandler + renderer | 切片+交互套件+像素 | — |
| T10 | 自绘弹层进无障碍影子树（Alert/ActionSheet + 焦点陷阱） | S/M | AlertHost + Accessibility | 切片+交互套件 | — |
| T11 | VisualDiagnosticsOverlay 初始化（IAdorner） | S | WindowHandler/MauiApplication | 切片+交互套件 | — |
| T12 | CarouselView 分组头/尾 | M | CarouselViewHandler + materializer | 切片+交互套件 | — |
| T13 | CollectionView GroupFooter 视图模板（非 Label） | S | CollectionViewHandler + materializer | 切片+交互套件 | — |
| T14 | Shell 富 flyout（View/DataTemplate 头尾与项模板） | M/L | ShellExtras + 壳 | 切片+交互套件 | 壳同波串行 |
| T15 | Shell 富 TitleView | M | ShellChrome + renderer | 切片+交互套件+像素 | — |
| T16 | 菜单子菜单/MenuBar 标题 | M | Menus + 壳 | 切片+交互套件 | 壳同波串行 |
| T17 | BlazorWebView B2（WASM staging + 专用引导/服务模式 + 布局） | M | Blazor handler + ohos-workload pack/壳 | 切片+harness+像素 | B1 真机结果（外部）；staging 可先行 |
| T18 | Essentials IMap 启动地图 | S | 新 MapLauncher + 注册 | 切片+交互套件 | — |
| T19 | WebAuthenticator 真流程（深链回跳 + module.json5 skill 声明） | M | WebAuthenticator + AppLinks + 壳模板 | 切片+交互套件+harness | 真机验证（外部） |
| T20 | MediaElement（AudioKit/MediaKit 播放层，社区契约） | L | 新 MediaElement 文件 + 壳 sink | 切片+交互套件 | 设备播放验证（外部） |
| T21 | 字体缩放跟随（系统字号） | S | FontManager + 文本绘制 | 切片+交互套件+像素 | — |
| T22 | MainThread 桥接断言（固化框架 dispatcher 桥） | S | ohos-workload 套件 Program.cs | 交互套件 | — |

## 3. 外部依赖（设备 / AGC / 上游，不排入本地波次）

| # | 项 | 类型 | 判据 |
|---|---|---|---|
| E1 | 真机验证（kit #31：Blazor BLZ 标记、P0b-A11Y 15 项、WebView 六项、B1/B2、IME、HUKS、深链 want/App Linking 投递、滚动物理、拖放） | 设备 | 各验证清单逐项判据 |
| E2 | HMS/AGC（Push `1000900010`/`1000900012`、Account `1001502014`、Map AppKey、LiveView 权益、ShareKit/Scan/TTS 真机 + harmony 壳构建） | HMS 设备 + AGC + HarmonyOS SDK | kit 判定卡 |
| E3 | 真多窗口（2in1/平板自由窗） | 设备 | OpenWindow 语义升级 |
| E4 | Hot Reload（hdc `E00C001`） | 组织策略 | devloop.sh v1 为本地替代 |
| E5 | arm32（无 32 位设备/packs） | 设备/工具链 | arm32 gap 文档 |
| E6 | 每元素 KeyboardAccelerators + 键消费契约 | 上游 MAUI API | slice-notes 三条件（集合/Mapper/消费语义） |
| E7 | Blazor WASM 发布链（dnceng rc.2 flight 的 runtime pack 不在 nuget.org） | 外部 feed/版本 | B2 发布配方随 SDK 复核 |

## 4. 建议执行顺序（前 10）与每波并行上限

1. T1 InputView 映射补全（S）｜2. T2 WebView 小缺口批（S×4）｜3. T3 GraphicsView 交互（M）｜4. T4 Label 富文本（M）
5. T5 Layout 语义补齐（M）｜6. T10 弹层无障碍（S/M）｜7. T11 VisualDiagnostics 初始化（S）｜8. T7 DatePicker 日历（M）
9. T9 TitleBar（M）｜10. T8 TableView（M/L）

- **每波上限 3 个切片任务**；每波恰好 1 个「套件」任务统一推进 checks/floor 与 pin（避免 Program.cs 冲突），
  且触壳任务（T2/T14/T16/T17/T20）与触像素基线的任务同波各限 1 个（abc/导出契约与像素基线各自串行）。
- **预期波次**：前 10 项 ≈ 4 波；全部 22 项 ≈ 8–9 波。本轮仅产出清单，未开始执行。
