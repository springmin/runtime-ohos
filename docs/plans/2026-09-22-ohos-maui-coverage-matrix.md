# MAUI on OpenHarmony 覆盖矩阵（2026-09-22）

> **范围**：`maui-ohos` 平台切片（`src/Core/src/Platform/OpenHarmony`，96 个 `.cs`，tip `c4ac6a5e`）
> + `ohos-workload`（`src/OpenHarmonyHost` 原生宿主/NAPI、`src/Microsoft.OpenHarmony.Hosting` 托管宿主、
> `scripts/build-arkts-shell.sh` 壳构建、`packs/`、`test/`）+ 284 条校验套件
> （`test/maui-platform-verify`：271 交互 + 4 fuzz + 1 帧性能 + 8 无障碍性能）+ 演示工程
> （`test/hello-maui-app`，多目标 20.0/26.0）。
> **方法**：只读代码审计，无构建、无测试运行；每条结论可回指到文件与行。
> **真机口径**：全部结论均为**离设备**核实；真机现状见 §6。上设备前，"已实现"≠"已验证"。
> 本文件是独立盘点产物，不替代主审计 `2026-09-19-ohos-code-audit.md` 与最终状态 `2026-09-21-ohos-final-status.md`。

## 1. 已实现（Implemented）

| 区域 | 覆盖 | 锚点 |
|---|---|---|
| 视图 handlers | **41 个**注册项（含本轮新增的 `IApplication`） | `MauiOpenHarmonyExtensions.cs` 的 `SliceHandlers` |
| 布局 | Layout handler + 内容排布 | `OpenHarmonyLayoutHandler.cs`、`OpenHarmonyContentArrange.cs` |
| 形状 | Shape / Border / BoxView / Frame / IndicatorView | `OpenHarmonyShapeHandler.cs`、`OpenHarmonyBorderHandler.cs`、`OpenHarmonyBoxViewHandler.cs`、`OpenHarmonyFrameHandler.cs`、`OpenHarmonyIndicatorViewHandler.cs` |
| 页面与导航 | Page / NavigationPage / TabbedPage / FlyoutPage / Shell | `OpenHarmony{Page,NavigationPage,TabbedPage,FlyoutPage,Shell}Handler.cs` |
| 列表与滚动 | CollectionView（grid/grouped）/ ListView / CarouselView；ScrollView / SwipeView / RefreshView | `OpenHarmony{CollectionView,ListView,CarouselView,ScrollView,SwipeView,RefreshView}Handler.cs` |
| Web | WebView / HybridWebView / BlazorWebView（构建门控注册） | `OpenHarmonyWebViewHandler.cs`、`OpenHarmonyHybridWebViewHandler.cs`、`OpenHarmonyBlazorWebView*.cs` |
| 手势 | tap / pan / swipe / pinch / pointer / hover / drag-drop | `OpenHarmonyGestures.cs`、`OpenHarmonyPinch.cs`、`OpenHarmonyPointer.cs`、`OpenHarmonyDragAndDrop.cs` |
| 无障碍 | 影子节点树 + ArkUI provider + 16 参发布契约 + 动作回传 | `OpenHarmonyAccessibility.cs` |
| 窗口生命周期 | Activated / Resumed / Stopped / Destroying（缺口见 §2） | `OpenHarmonyMauiAppHost.cs` |
| 弹层 | Alert / ActionSheet / Prompt | `OpenHarmonyAlertManager.cs`、`OpenHarmonyAlertHost.cs` |
| Essentials 核心清单 | 各 `OpenHarmony*` Essentials 实现（有缺口的单列 §2） | `OpenHarmonyEssentialsUnsupported.cs`、`OpenHarmonyEssentialsExtras.cs`、`OpenHarmonyAppLauncher.cs`、`OpenHarmonyFileSystem.cs`、`OpenHarmonyPreferences.cs` 等 |
| 传感器 | 6 个：Accelerometer / Barometer / Compass / Gyroscope / Magnetometer / OrientationSensor | `OpenHarmonySensors.cs` |
| 额外平台 API | 菜单 / 通知 / 经典蓝牙发现 / **BLE GATT 客户端（平台扩展）** / 打印 / 联系人 / 日历 / Keystore / 字体 | `OpenHarmonyMenus.cs`、`OpenHarmonyNotifications.cs`、`OpenHarmonyBluetoothPrinting.cs`、`OpenHarmonyBluetoothGatt.cs`、`OpenHarmonyCalendarContacts.cs`、`OpenHarmonyKeystore.cs`、`OpenHarmonyFontManager.cs` |

### 1b. 2026-09-22 新落地批次（IMPLEMENTED；离设备，真机待证）

| 批次 | 覆盖 | 提交锚点 |
|---|---|---|
| BATCH-1 Essentials | `Permissions.RequestAsync`、系统 `Clipboard`（含 `ClipboardContentChanged`）、`Connectivity` | `maui-ohos b942952a`、`6a4062b7`；`ohos-workload b7fa6da`、`e0cfc24` |
| BATCH-2 Essentials | Email / Sms / PhoneDialer、Screenshot、Geocoding | `maui-ohos d5a8145e`；`ohos-workload 29f1fbf`、`6759f84` |
| 视图/窗口收尾 | `FontImageSource`、`SwitchCell` / `EntryCell`、`ImageButton`、`Window.Created`、每页 `SafeArea`、窗口标题 | `maui-ohos 71df935f`、`aef91b0b` |
| 无障碍 / Shell 扩展 | `SemanticScreenReader.Announce`（走携带文本的导出）、`SearchHandler` / `FlyoutHeader` / `TabBarIsVisible` / `FlyoutBehavior` | `maui-ohos 8954a0a1`、`9cd47b92`；`ohos-workload 9b9cb9c` |
| 安全加固 | 上述新桥接面（权限 / 剪贴板 / 连通性 / window / announce）加固 | `ohos-workload e0cfc24` |
| BATCH-3 平台扩展 | BLE GATT 客户端（connect / discover / read / write / notify / MTU / release；无 host/shell 时如实返回 `Unavailable`，不抛） | `maui-ohos 14da7879`；`ohos-workload 4040d48` |
| BATCH-3 AppInfo | `IAppInfo.ShowSettingsUI`（ability kind 4 → `com.ohos.settings`）、真实 `VersionString`/`Version`/`BuildString`/`PackageName`（host `setBundleInfo` → `ohos_host_get_bundle_{version,build,name}`，保留 1.0.0 后备） | `maui-ohos df023b62`；`ohos-workload a1c95eb` |
| BATCH-3 权限 | `Permissions.PostNotifications`（读系统通知使能状态 / 唤起使能对话框；非 abilityAccessCtrl 权限，桥缺失时如实 `Unknown`/`Denied`） | `maui-ohos df023b62`；`ohos-workload a1c95eb` |
| BATCH-3 应用/窗口 | 真 `IApplication` handler + 诚实单窗口语义（Quit/OpenWindow/CloseWindow/ActivateWindow；`OpenHarmonyOpenWindowResult`） | `maui-ohos 3c0457b9` |
| BATCH-3 列表/滑动 | CollectionView 多选 / `EmptyView` / header-footer / `ScrollTo`、CarouselView peek、SwipeView `SwipeItemView` | `maui-ohos c4ac6a5e` |
| BATCH-3 Shell 标题栏 | 可见 `Label` 的 Shell/NavigationPage `TitleView` 文本 + 当前页 `ToolbarItems` 镜像到合成器标题栏（富 TitleView 回退页标题并记一次） | `maui-ohos b439bf73` |
| BATCH-3 其他收尾 | 权限全表 / `AppActions` 降级实现 / 诚实 App-Device info；文件-媒体 picker 多选；无障碍动作执行、样式文本、paint-aware shapes | `maui-ohos 2eb25493`、`436e71c4`、`7f66f13e` |

仍未闭合的 **shell/host 补全**（本轮诚实降级，均只记一次 status，不静默错误）：Launch/Browser/Share 无法表达 Subject/Title、in-app 浏览器选项与 `file://` 读取授权；`Connectivity.ConnectionProfiles` 仍为空；`SoftInput` 高度仍为 0；非文本焦点遍历 / 硬件键转发；Screenshot JPEG 请求仍回 PNG；拖拽 payload 只覆盖 image/property（`maui-ohos b439bf73`）。BLE GATT 依赖随 kit 的壳 sink（`@kit.ConnectivityKit` 的 `ble` + `ACCESS_BLUETOOTH`），设备侧行为待真机验证。

真机口径同 §6：以上为代码路径 + 离设备套件证据，"已实现" ≠ "已验证"。

## 2. 部分实现（Partial，附证据）

2026-09-22 更新：下表带 ✅ 的行已在本轮转为 IMPLEMENTED（已实现；提交锚点行内 + §1b），原缺口证据保留作审计轨迹；其余行仍为缺口。

| API | 现状 | 证据 |
|---|---|---|
| `Permissions.RequestAsync` | ✅ 已实现（2026-09-22；原为恒返回 `Denied`） | `maui-ohos b942952a` + `ohos-workload b7fa6da`/`e0cfc24`；原缺口 `OpenHarmonyEssentialsUnsupported.cs:63` |
| `Connectivity` | ✅ 已实现（2026-09-22；原恒 `Unknown`） | `maui-ohos b942952a` + `ohos-workload b7fa6da`；原缺口 `OpenHarmonyEssentialsExtras.cs:77` |
| `Clipboard` | ✅ 已实现（2026-09-22：系统剪贴板 + `ClipboardContentChanged`；读拒绝不弹窗并缓存） | `maui-ohos b942952a`、`6a4062b7` + `ohos-workload b7fa6da`/`e0cfc24`；原为文件后备 `OpenHarmonyEssentialsExtras.cs:11` |
| `Share` | 文本 + 单文件（隐式 `sendData` Want + `FLAG_AUTH_READ_URI_PERMISSION`）；多文件为记录在案的 no-op | `OpenHarmonyAppLauncher.cs:22`、`:193` |
| `SecureStorage` | HUKS 应答时走 HUKS；否则回退每安装文件密钥（明确非硬件后备） | `OpenHarmonySecureStorage.cs:1` |
| Window mapper | ✅ 已实现（2026-09-22：每页 `SafeArea` + 窗口标题；原只映射 `Content`） | `maui-ohos aef91b0b` + `ohos-workload 29f1fbf`；原缺口 `OpenHarmonyWindowHandler.cs:9` |
| 键盘 / 焦点 | 仅文本控件（Entry / Editor）有焦点处理；非文本焦点遍历 / 硬件键转发为记录在案的 shell/host 缺口 | `OpenHarmonyEntryHandler.cs:81`、`OpenHarmonyEditorHandler.cs:70`、`b439bf73` |
| ImageButton | ✅ 已实现（2026-09-22：已注册，含 `FontImageSource` 字形支持） | `maui-ohos 71df935f`；原缺口 `MauiOpenHarmonyExtensions.cs:15` |
| `MainThread` | 无实现 | （全切片无 `MainThread`） |
| 单元格 | ✅ 已实现（2026-09-22：`SwitchCell` / `EntryCell`） | `maui-ohos 71df935f`；原缺口（全切片无对应 handler） |
| `Window.Created` | ✅ 已实现（2026-09-22；原壳侧 `Create` 映射到 `Activated`） | `maui-ohos aef91b0b`；原缺口 `OpenHarmonyMauiAppHost.cs:87` |

## 3. 未实现（Not implemented）

- WebAuthenticator（**未落地**：截至本刷新，切片内无 `WebAuthenticator` 实现，诚实降级版本也尚未提交）
- MediaElement
- TableView + legacy compatibility renderers + TitleBar + Core Toolbar

2026-09-22：Email / Sms / PhoneDialer、Screenshot / Geocoding、`SemanticScreenReader.Announce`、
Shell 扩展（SearchHandler / FlyoutHeader / TabBarIsVisible / FlyoutBehavior）已转 §1b 的
IMPLEMENTED（离设备）。`AppActions` 已有如实降级的实现（本 SDK 无动态快捷方式 setter，
`maui-ohos 2eb25493`），不再列在“未实现”。

## 4. SDK 阻塞（ohos-sdk 26.0.0.18 / API 26）

| 能力 | 阻塞原因 | 现状 |
|---|---|---|
| TextToSpeech | 本 SDK 既无 `@kit.CoreSpeechKit` 也无 `@ohos.ai.tts` | 链路已接，sink 如实返回不可用（审计 §5c） |
| Map | 本 SDK 无 MapKit | 未实现（审计 §7、§20） |
| 系统分享面板 / 多文件分享 | 无 Share Kit（`systemShare`），一个 Want 只有单个 uri 槽 | 文本 + 单文件可用（S4），多文件 no-op |
| Hot Reload | hdc 策略 | 硬阻塞（交接状态 §8，D4） |
| arm32 | 无 runtime packs、无 32 位设备 | 见 `2026-09-21-ohos-arm32-support-gap.md` |

## 5. 套件与 CI 基线

- `test/maui-platform-verify` 期望 **284** 条 `[verify]`（271 交互 + 4 fuzz + 1 帧性能 + 8 无障碍性能；
  `fb533f0` 新增 9 条 audit 检查，`6759f84`/`9b9cb9c` 的 BATCH-1/2 与 announce 检查在内），CI workflow 下限
  **264**（284-20）。
- 切片 pin：`ohos-workload` `ab09918`（2026-09-22，与本矩阵同批）将 interaction workflow 固定到
  `maui-ohos` `c4ac6a5e8c0ed4f2138a7b5d06faf8b92940bdb3`（BLE GATT / settings-AppInfo / IApplication /
  列表补齐 tip），下限 264。演进：`df221b6` → `be5d471f`（下限 224）→ `fb533f0` → `90b21416`（下限 264）
  → `ab09918` → `c4ac6a5e`。
- 最近一次本地完整 preflight（2026-09-22）全绿：interaction **284** 条、0 Unhandled、两条性能门
  `within=True`，pixel `PIXEL ASSERTIONS PASSED`，markdownlint 0 issues。
- 历史 CI：`df221b6` 上三条 run 全绿：interaction `35629780806`、pixel `35629780800`、markdownlint `35629780817`
  （均 2026-09-21T17:05:36Z）。
- 此前 interaction 红的原因是 pin 停在 `90c8373f`（缺 B 系列符号），属 pin 未推进，不是套件回归。
- 注意：pin 推进到 `c4ac6a5e` 后的 CI run **尚未产生**（2026-09-22 已 push `ab09918`）；套件在 `90b21416`
  上 284 条全绿，`c4ac6a5e` 相对该 tip 只增不减已 pin 的面。

## 6. 真机状态（caveat）

- 上述所有内容均为**离设备**验证；284 条套件与像素套件只在无设备环境运行。
- 启动崩溃已定位并修复：**入口 record**（kit #10，`useNormalizedOHMUrl=false` + bundle 前缀 record；
  测试方真机复测确认入口可解析）与 **abc 字节码版本**（kit #11，`compatibleSdkVersion 18` → `13.0.1.0`；
  此前 `24.0.0.0` 超出设备 ark runtime）。kit #11 为当前发布，校验值以 release 说明「## Integrity」为准；
  详情见 `2026-09-22-ohos-startup-crash-rootcause.md` §5b 与 `2026-09-22-ohos-arkts-abc-version-history.md`。
  P1–P4 阶梯仍适用于 dlopen / 缺库 / 宿主入口 / .NET 运行时类崩溃（判读分支见
  `2026-09-21-ohos-crash-probes.md` §4.0/§4.0b）。
- 因此本矩阵中"已实现"仅代表代码路径与离设备套件证据，不代表真机行为。

## 7. 剩余缺口 Top-10（2026-09-22 刷新）

| # | 工作项 | 工作量 / 依赖 | 状态（2026-09-22） |
|---|---|---|---|
| 1 | 真机启动崩溃定位决策表（入口 record / abc 版本 / P1–P4 + 最小证据） | 需要设备 | 两个根因已修复；待 kit #11 真机回归 |
| 2 | 把切片作为 MAUI 平台矩阵的一部分交付（ship-the-slice 打包） | L；离线 + 上游 | 未开始 |
| 3 | 真机验证扫尾（284 条套件 + 像素 + 真机行为） | 仅设备 | 待设备（kit #11 重签后） |

已落地（原 #3、#5–#9）：`Permissions.RequestAsync`、Connectivity、系统剪贴板、
Email / Sms / PhoneDialer、Screenshot + Geocoding、Announce / Shell 扩展、
Window / SafeArea / 标题收尾 —— 见 §1b（提交锚点）。
本轮（BATCH-3）另落地：BLE GATT 平台扩展、`ShowSettingsUI`/真实 AppInfo/`PostNotifications`、
`IApplication` handler、列表/轮播/滑动补齐、Shell 标题栏镜像 —— 见 §1b。
原 #4（推进 CI 切片 pin）经 `fb533f0` 到 `ab09918` 持续推进，当前 pin `c4ac6a5e` / 下限 264（§5）。

§4 的 **SDK 阻塞清单**：TextToSpeech / Map / Share Kit 多文件分享 / Hot Reload / arm32 不变；
原 **BLE GATT** 一栏已移出（以 host/NAPI/壳桥接的平台扩展落地，见 §1b）。
