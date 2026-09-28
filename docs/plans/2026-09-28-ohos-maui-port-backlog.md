# MAUI 移植缺口审计与本地可执行 Backlog（MAUI-GAP-AUDIT，2026-09-28；Wave 1–3 收口复核 2026-09-29）

> **口径**：只读代码/文档审计，无构建、无真机；「已实现」= 代码路径 + 离设备证据（交互套件基线 **438 / floor 418**，
> `ohos-workload/test/maui-platform-verify/Program.cs:15`），上设备前 ≠ 已验证。基线 = maui-ohos `feature/openharmony`
> tip `843a6c7c`（121 个 `.cs`）+ 覆盖矩阵（`2026-09-22-ohos-maui-coverage-matrix.md`）与 Kit 缺口复核（`2026-09-24-ohos-kit-gap-analysis.md`）。
> **增量与更正**：WebView W 系列（`d6325990`）与 SEC-SCAN-3（`7c75b88f`/`3c2cd28c`/`33b0af79`）已计入；矩阵旧结论中
> MainThread（rc.1 框架 `BridgeMainThreadFromDispatcher` 桥接）、SoftInput、ConnectivityProfiles 已由后续提交修正。
> **Wave 1–3 收口（2026-09-29 复核）**：T1/T2/T3/T4/T5/T10/T7/T9/T11 已落地 ✅（见 §2.1；套件 398/378 → 438/418，
> pin 仍 `b6a58645`、tip `843a6c7c` → §2.2 A2）；§1 已按收口结果改状态，§2.2 为下一波可执行清单。

## 1. 状态矩阵（34 面）

| # | 面 | 状态 | 证据（maui-ohos 切片，除注明外） | 缺口 |
|---|---|---|---|---|
| 1 | Layouts（Stack/Grid/Flex/Absolute/Relative） | 已实现 ✅（W2B） | LayoutHandler/ContentArrange/SafeArea + `c1c05f3d` ZIndex/Clip/InputTransparent/Anchor | — |
| 2 | Shapes/路径 | 已实现 | ShapeHandler/Paths | — |
| 3 | Brushes/阴影 | 已实现 | Shape/Border 绘制；gradient/image paint 走 canvas | 阴影仅纯色 Paint（已记录降级） |
| 4 | 基础控件 Label/Button/Image/ImageButton/BoxView/Frame/Border/ContentView | 已实现 ✅（W2A） | 各 handler + `043e6468` FormattedText/Span runs | span 手势/span 字体族/斜体诚实降级（已记录） |
| 5 | 选择/范围 Switch/CheckBox/RadioButton/Slider/Stepper | 已实现 | 各 handler | — |
| 6 | 进度/指示 ProgressBar/ActivityIndicator/IndicatorView | 已实现 | 各 handler | — |
| 7 | InputView Entry/Editor/SearchBar | 已实现 ✅（W1A） | Entry/Editor/SearchBar handler + `dcc7eaac` | Keyboard 仅 Numeric/Telephone 过滤，其余记录 |
| 8 | Picker/DatePicker/TimePicker | 已实现 ✅（W3A） | Picker/Date/Time handler + `843a6c7c` 日历/Min/Max 钳制 | `IsOpen`/Opened/Closed 未映射（N3） |
| 9 | RefreshView | 已实现 | RefreshViewHandler | — |
| 10 | ScrollView | 已实现 | ScrollViewHandler + 滚动物理/滚动条 | — |
| 11 | CollectionView | 已实现 | CollectionViewHandler + materializer | GroupFooterTemplate 仅 Label 文本（T13） |
| 12 | ListView（含 Cell） | 已实现 | ListViewHandler（SwitchCell/EntryCell/TextCell/ViewCell） | — |
| 13 | CarouselView | 部分 | CarouselViewHandler + 分组扁平化 | 分组头/尾不可表达（T12） |
| 14 | SwipeView | 已实现 | SwipeViewHandler | — |
| 15 | TableView | 缺失 | 无 ITableViewController/渲染器 | 无平台实现（可复用 ListView 行物化，T8） |
| 16 | WebView | 已实现 ✅（W1A） | WebViewHandler + `8241f1b3` Cookie 同步 + 壳 `7cb1f31`（#11/#12/#13） | 真机弹窗/URI 授权（E1）、真多窗（E3） |
| 17 | HybridWebView | 已实现 | HybridWebViewHandler | — |
| 18 | BlazorWebView | 部分 | Blazor handler（B1 门控） | B2 WASM staging/引导/布局未做（T17） |
| 19 | 手势 Tap/Pan/Swipe/Pinch/Pointer/Drag | 已实现 | Gestures/Pinch/Pointer/DragAndDrop | 文件/URI 拖放载荷受 Controls 契约限制 |
| 20 | Navigation/Page/Tabbed/Flyout | 已实现 | 各 handler + PageTransitions | — |
| 21 | Shell | 部分 | ShellHandler/Extras/Chrome/AppLinks/Menus | 富 flyout（T14）/富 TitleView（T15）仅文本；菜单平铺无子菜单（T16） |
| 22 | 动画 | 已实现 | AnimationLoop/Ticker/Transitions/SharedTransition/Motion | — |
| 23 | GraphicsView | 已实现 ✅（W1B） | GraphicsViewHandler + `b6a58645`（`a6e65250`+`db9359fb`） | — |
| 24 | Window/App 生命周期 | 已实现 | AppHost/WindowHandler/ApplicationHandler | — |
| 25 | 多窗口 | 部分 | ApplicationHandler 诚实单窗语义 | 真多窗未实现（设备 2in1/平板，E3） |
| 26 | 平台扩展 Menu/Notify/BLE/Print/Scan/Push/Account/Map/LiveView/Contacts/Sensors | 已实现（探测） | 各 `OpenHarmony*.cs` + 壳 sink | 真调用需 HMS/AGC（E2） |
| 27 | Essentials | 部分 | DI 全表（MauiOpenHarmonyExtensions.cs） | IMap 缺失（T18）；WebAuthenticator/AppActions 降级（T19）；Screenshot JPEG→PNG |
| 28 | 无障碍 | 已实现 ✅（W2C） | OpenHarmonyAccessibility + `c56bf0fa` 自绘弹层进树 | 真机待验（E1）；TitleBar 行未进树（N4） |
| 29 | 字体/本地化 | 已实现 | FontManager（字体文件解析）；本地化无平台面 | 无系统字体缩放跟随（T21） |
| 30 | RTL | 缺失 | 全切片无 FlowDirection 引用 | 排布/绘制/命中未镜像（T6，下一波） |
| 31 | 打印 | 已实现（平台扩展） | OpenHarmonyBluetoothPrinting（PDF 渲染/打印） | 无上游 IPrint 契约；设备验证外部 |
| 32 | TitleBar/Adorner/快捷键 | 部分 | `05935db3` TitleBar 行 + `89e41efa` Adorner | 每元素快捷键（E6 上游）；TitleBar 行 a11y（N4）；系统装饰（N6） |
| 33 | 主题（明暗） | 已实现 | OpenHarmonyTheme | — |
| 34 | MediaElement（社区工具包） | 缺失 | 无 | 需 AudioKit/MediaKit/AVSessionKit 播放层（T20） |

计数（Wave 1–3 收口后）：已实现 25 · 部分 6 · 缺失 3 · 外部依赖 9（§3）。

## 2. 本地可执行任务清单

### 2.1 已完成（Wave 1–3，✅ 已落地并合并 `feature/openharmony`）

| 任务 | 切片提交（maui-ohos） | 伴随提交（壳/套件 = ohos-workload） | 离线证据（套件 checks/floor） |
|---|---|---|---|
| T1 InputView 映射补全 | `dcc7eaac` | `7cb1f31`（壳接线 + T1/T2 断言）、`1809ad6`（pin） | 405/385 |
| T2 WebView 小缺口批（#11/#12/#13 + Cookie） | `8241f1b3` | 同上（#11/#12/#13 在 `7cb1f31`） | 405/385 |
| T3 GraphicsView 交互 | `b6a58645`（`a6e65250`+`db9359fb`） | `d8b75de` | 409/389 + 像素 |
| T4 Label FormattedText/Spans | `043e6468` | `938d710`、`888a956` | 420/400 + 像素 |
| T5 Layout 语义补齐 | `c1c05f3d` | `b6222ae`、`b67eddf`（pin `b6a58645`） | 424/404 + 像素 |
| T10 弹层进无障碍影子树 | `c56bf0fa` | `612a057` | 416/396 |
| T9 Window.TitleBar 行 | `05935db3` | `7ab12f1` | 428/408 + 像素 |
| T11 VisualDiagnosticsOverlay | `89e41efa` | `31d21b7` | 432/412 |
| T7 DatePicker 日历 + Min/Max | `843a6c7c` | `ad2d688` | 438/418 |

> pin 现状：三 workflow 仍为 `b6a58645`（`b67eddf`，424/404）；切片 tip `843a6c7c` → Wave 4 套件任务 A2 一次性推进并对齐 checks/floor。

### 2.2 下一波可执行（Wave 4–11；T8 置首，T6/N2 为最高收益）

| 波次 | # | 任务 | 规模 | 目标文件 | 门禁 | 依赖 |
|---|---|---|---|---|---|---|
| W4 | T8 | TableView + ITableViewController（复用 ListView 行物化） | M/L | 新 TableViewHandler + ListViewHandler + 注册 | 切片+交互套件+harness | — |
| W4 | T6 | RTL/FlowDirection 镜像（排布/绘制/命中/菜单） | M | ContentArrange + OpenHarmonyView + renderer | 切片+交互套件+像素 | — |
| W4 | N2 | 空 Content 页排布无限递归（栈溢出，既有缺陷） | S/M | ContentArrange + PageHandler（+SafeAreaArrange） | 切片+交互套件 | W3B 证据（§5 A3） |
| W4 | A2 | 推进三 workflow pin → `843a6c7c` + checks/floor 对齐（套件） | S | ohos-workload `.github/workflows/*` + 套件 | CI+交互套件 | Wave 1–3 已合并 |
| W5 | T13 | CollectionView GroupFooter 视图模板（非 Label） | S | CollectionViewHandler + materializer | 切片+交互套件 | — |
| W5 | N3 | Picker/Date/TimePicker `IsOpen` 映射（开/关 + Opened/Closed） | S | 三个 picker handler | 切片+交互套件 | — |
| W5 | T21 | 字体缩放跟随（系统字号） | S | FontManager + 文本绘制 | 切片+交互套件+像素 | — |
| W5 | T22 | MainThread 桥接断言（固化框架 dispatcher 桥；套件） | S | ohos-workload 套件 Program.cs | 交互套件 | — |
| W6 | T14 | Shell 富 flyout（View/DataTemplate 头尾与项模板） | M/L | ShellExtras + 壳 | 切片+交互套件 | 壳同波串行 |
| W6 | T12 | CarouselView 分组头/尾 | M | CarouselViewHandler + materializer | 切片+交互套件 | — |
| W6 | N1 | host 多指坐标（逐点上报 + 按 pointer id 消费；原 A1） | M | host_napi.cpp + OpenHarmonyApp.cs + app host/renderer | 切片+交互套件 | — |
| W7 | T15 | Shell 富 TitleView | M | ShellChrome + renderer | 切片+交互套件+像素 | — |
| W7 | T16 | 菜单子菜单/MenuBar 标题 | M | Menus + 壳 | 切片+交互套件 | 壳同波串行 |
| W7 | N4 | TitleBar 行进 a11y 影子树 | S | OpenHarmonyTitleBar + Accessibility | 切片+交互套件 | — |
| W8 | T17 | BlazorWebView B2（WASM staging + 引导/服务模式 + 布局） | M | Blazor handler + ohos-workload pack/壳 | 切片+harness+像素 | E7 + B1 真机（E1）；staging 可先行 |
| W8 | T18 | Essentials IMap 启动地图 | S | 新 MapLauncher + 注册 | 切片+交互套件 | — |
| W8 | N5 | 诊断覆盖层触摸穿透抑制（T11 余项） | S | OpenHarmonyWindowOverlay | 切片+交互套件 | — |
| W9 | T19 | WebAuthenticator 真流程（深链回跳 + skill 声明） | M | WebAuthenticator + AppLinks + 壳模板 | 切片+交互套件+harness | 真机（E1） |
| W10 | T20 | MediaElement（AudioKit/MediaKit 播放层，社区契约） | L | 新 MediaElement 文件 + 壳 sink | 切片+交互套件 | 设备播放（E9） |
| W11 | N6 | TitleBar 系统装饰（min/max/close + 拖拽区；壳协作） | S/M | TitleBar + 壳 | 切片+交互套件 | 壳同波串行 |

## 3. 外部依赖（设备 / AGC / 上游，不排入本地波次）

> **判据**：下列 E1–E9 是「§2.2 全部本地项落地后仍属外部」的完整清单；此前各波次完成的面若需上设备判定，一律归入 E1/E2/E9。

| # | 项 | 类型 | 判据 |
|---|---|---|---|
| E1 | 真机验证（kit #31 清单：Blazor BLZ 标记、P0b-A11Y 15 项、WebView 六项、B1/B2、IME、HUKS、深链 want/App Linking 投递、滚动物理、拖放；**新增 W1–W3 面**：InputView 映射/FormattedText/Layout 语义/DatePicker 日历/TitleBar/诊断覆盖层/WebView 四缺口） | 设备 | 各验证清单逐项判据 |
| E2 | HMS/AGC（Push `1000900010`/`1000900012`、Account `1001502014`、Map AppKey、LiveView 权益、ShareKit/Scan/TTS 真机 + harmony 壳构建） | HMS 设备 + AGC + HarmonyOS SDK | kit 判定卡 |
| E3 | 真多窗口（2in1/平板自由窗） | 设备 | OpenWindow 语义升级 |
| E4 | Hot Reload（hdc `E00C001`） | 组织策略 | devloop.sh v1 为本地替代 |
| E5 | arm32（无 32 位设备/packs） | 设备/工具链 | arm32 gap 文档 |
| E6 | 每元素 KeyboardAccelerators + 键消费契约 | 上游 MAUI API | slice-notes 三条件（集合/Mapper/消费语义） |
| E7 | Blazor WASM 发布链（dnceng rc.2 flight 的 runtime pack 不在 nuget.org） | 外部 feed/版本 | B2 发布配方随 SDK 复核 |
| E8 | VisualDiagnosticsOverlay 元素选择器 tap（`Tapped` raiser 在 Microsoft.Maui 内部，rc.1 无公开 seam） | 上游 MAUI 内部 | T11 slice-notes 记录 |
| E9 | MediaElement 真机播放/音频焦点验证（AudioKit/MediaKit 设备能力） | 设备 | T20 落地后随 kit 验证 |

## 4. 建议执行顺序（Wave 4 起）与每波并行上限

1. T8 TableView（M/L）｜2. T6 RTL 镜像（M）｜3. N2 空 Content 栈溢出修复（S/M）｜4. A2 pin/checks 收口（S，套件）
5. T13 CollectionView GroupFooter（S）｜6. N3 三 Picker `IsOpen`（S）｜7. T21 字体缩放（S）｜8. T22 MainThread 断言（S，套件）
9. T14 Shell 富 flyout（M/L）｜10. T12 CarouselView 分组（M）｜11. N1 host 多指坐标（M）
12. T15 Shell TitleView（M）｜13. T16 菜单子菜单（M）｜14. N4 TitleBar a11y（S）
15. T17 Blazor B2（M）｜16. T18 IMap（S）｜17. N5 诊断穿透（S）｜18. N6 TitleBar 系统装饰（S/M）
19. T19 WebAuthenticator（M）｜20. T20 MediaElement（L）｜21. N6 TitleBar 系统装饰（S/M，壳协作）

- **每波上限 3 个切片任务**；每波恰好 1 个「套件」任务统一推进 checks/floor 与 pin（避免 Program.cs 冲突），
  且触壳任务（T14/T16/T17/T19/T20/N6）与触像素基线的任务同波各限 1 个（abc/导出契约与像素基线各自串行）。
- **预期波次**：W4–W11 共 8 波、20 项（§2.2；W9–W11 为触壳收尾，T19/T20/N6 各占一波）。
  A2/T22 已具名，W6+ 的套件任务在各波切片落地后按同一规则生成。本轮仅产出清单，未开始执行。

## 5. 追加登记（2026-09-29 Wave 1–3 复核）

- **A1 host 多指坐标**：`host_napi.cpp` 的 `OnTouch` 每事件仅按 **point 0** 取窗口坐标上报（`ohos_host_notify_touch(type, x, y, numPoints, event.id)` 已把指针数量/身份贯通到托管桥，但坐标只有第 0 指；Pinch 为独立旁路、读 0/1 两指算距离）。多指手势（拖拽/悬停/笔）的坐标精度受此限制；修复 = 宿主逐点上报（通知接口/结构扩展）+ 托管 Gestures/Pointer 按 pointer id 消费。**已归入 §2.2 N1（W6）**。
- **A2 slice pin 推进（时机）**：Wave 1–3 已收口（tip `843a6c7c`，套件 438/418），三 workflow pin 仍为 `b6a58645`（`b67eddf`，424/404）。**推进改为 §2.2 A2（W4 套件任务）一次性完成**：pin → `843a6c7c` + checks/floor 对齐，仍避免逐任务 churn（口径同 §4：每波恰好 1 个套件任务统一推进）。
- **A3 T9 空 Content 栈溢出（既有缺陷，W3B 暴露）**：`OpenHarmonyContentArrange.Arrange` 对**无 `PresentedContent` 的 Page** 直接 `view.Measure/Arrange` → 重入 `OpenHarmonyPageHandler.PlatformArrange` → `OpenHarmonyContentArrange.Arrange` 再入（depth 每次从 0 起，`depth > 4` 守卫不生效）→ 无限递归/栈溢出。W3B 空页渲染时触发（栈帧 `PlatformArrange → ContentPage.ArrangeOverride → IView.Arrange → ContentArrange.Arrange` 重复 921 次）。修复 = 空页分支落 frame 后 return（或 PlatformArrange 重入守卫）+ 空 ContentPage 回归。**已归入 §2.2 N2（W4）**。
- **A4 三 Picker `IsOpen` 未映射（T7 余项）**：rc.1 `IDatePicker/IPicker/ITimePicker.IsOpen` 均在契约内（`Microsoft.Maui.xml` 已核），三个 handler 的 Mapper 均无 `MapIsOpen`（内部已有开/关路径与 `PopupClosed`，缺双向映射与 Opened/Closed）。**已归入 §2.2 N3（W5）**。
- **A5 T9/T11 slice-notes 遗留三项**：TitleBar 行未进 a11y 影子树 → N4（W7）；诊断覆盖层不抑制触摸穿透（T11 余项）→ N5（W8）；ArkUI 壳系统装饰（min/max/close + 拖拽区）未映射 → N6（W8，壳协作）。
