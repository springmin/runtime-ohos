# MAUI on OpenHarmony 覆盖矩阵（2026-09-22）

> **范围**：`maui-ohos` 平台切片（`src/Core/src/Platform/OpenHarmony`，82 个 `.cs`，tip `be5d471f`）
> + `ohos-workload`（`src/OpenHarmonyHost` 原生宿主/NAPI、`src/Microsoft.OpenHarmony.Hosting` 托管宿主、
> `scripts/build-arkts-shell.sh` 壳构建、`packs/`、`test/`）+ 256 条校验套件
> （`test/maui-platform-verify`：243 交互 + 4 fuzz + 1 帧性能 + 8 无障碍性能）+ 演示工程
> （`test/hello-maui-app`，多目标 20.0/26.0）。
> **方法**：只读代码审计，无构建、无测试运行；每条结论可回指到文件与行。
> **真机口径**：全部结论均为**离设备**核实；真机现状见 §6。上设备前，"已实现"≠"已验证"。
> 本文件是独立盘点产物，不替代主审计 `2026-09-19-ohos-code-audit.md` 与最终状态 `2026-09-21-ohos-final-status.md`。

## 1. 已实现（Implemented）

| 区域 | 覆盖 | 锚点 |
|---|---|---|
| 视图 handlers | **39 个**注册项 | `MauiOpenHarmonyExtensions.cs` 的 `SliceHandlers` |
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
| 额外平台 API | 菜单 / 通知 / 经典蓝牙发现 / 打印 / 联系人 / 日历 / Keystore / 字体 | `OpenHarmonyMenus.cs`、`OpenHarmonyNotifications.cs`、`OpenHarmonyBluetoothPrinting.cs`、`OpenHarmonyCalendarContacts.cs`、`OpenHarmonyKeystore.cs`、`OpenHarmonyFontManager.cs` |

## 2. 部分实现（Partial，附证据）

| API | 现状 | 证据 |
|---|---|---|
| `Permissions.RequestAsync` | 恒返回 `Denied`（"needs the abilityAccessCtrl kit in the ArkTS shell"），即桥接前状态 | `OpenHarmonyEssentialsUnsupported.cs:63` |
| `Connectivity` | 恒 `Unknown`；注：宿主已有导出但未使用 | `OpenHarmonyEssentialsExtras.cs:77` |
| `Clipboard` | 文件后备（数据目录 `clipboard.txt`），无系统剪贴板、无 `ClipboardContentChanged` | `OpenHarmonyEssentialsExtras.cs:11` |
| `Share` | 文本 + 单文件（隐式 `sendData` Want + `FLAG_AUTH_READ_URI_PERMISSION`）；多文件为记录在案的 no-op | `OpenHarmonyAppLauncher.cs:22`、`:193` |
| `SecureStorage` | HUKS 应答时走 HUKS；否则回退每安装文件密钥（明确非硬件后备） | `OpenHarmonySecureStorage.cs:1` |
| Window mapper | 只映射 `Content`；无 `SafeArea` 符号 | `OpenHarmonyWindowHandler.cs:9` |
| 键盘 / 焦点 | 仅文本控件（Entry / Editor）有焦点处理，无通用键盘与焦点遍历 | `OpenHarmonyEntryHandler.cs:81`、`OpenHarmonyEditorHandler.cs:70` |
| ImageButton | 未注册（`SliceHandlers` 无 `IImageButton`）；`FontImageSource` 缺失 | `MauiOpenHarmonyExtensions.cs:15` |
| `MainThread` | 无实现 | （全切片无 `MainThread`） |
| 单元格 | `SwitchCell` / `EntryCell` 缺失 | （全切片无对应 handler） |
| `Window.Created` | 从不触发；壳侧 `Create` 事件映射到 `Activated` | `OpenHarmonyMauiAppHost.cs:87` |

## 3. 未实现（Not implemented）

- Email / Sms / PhoneDialer
- Screenshot / Geocoding / WebAuthenticator / AppActions
- MediaElement
- TableView + legacy compatibility renderers + TitleBar + Core Toolbar
- Shell 扩展：SearchHandler / FlyoutHeader / TabBarIsVisible / FlyoutBehavior
- `SemanticScreenReader.Announce`

## 4. SDK 阻塞（ohos-sdk 26.0.0.18 / API 26）

| 能力 | 阻塞原因 | 现状 |
|---|---|---|
| TextToSpeech | 本 SDK 既无 `@kit.CoreSpeechKit` 也无 `@ohos.ai.tts` | 链路已接，sink 如实返回不可用（审计 §5c） |
| Map | 本 SDK 无 MapKit | 未实现（审计 §7、§20） |
| 系统分享面板 / 多文件分享 | 无 Share Kit（`systemShare`），一个 Want 只有单个 uri 槽 | 文本 + 单文件可用（S4），多文件 no-op |
| BLE GATT client | `connection.GattClientDevice` 未导出 | 经典蓝牙发现可用，GATT 客户端不可实现（审计 §20） |
| Hot Reload | hdc 策略 | 硬阻塞（交接状态 §8，D4） |
| arm32 | 无 runtime packs、无 32 位设备 | 见 `2026-09-21-ohos-arm32-support-gap.md` |

## 5. 套件与 CI 基线

- `test/maui-platform-verify` 期望 **256** 条 `[verify]`（243 交互 + 4 fuzz + 1 帧性能 + 8 无障碍性能），CI 下限 224。
- 切片 pin：`ohos-workload` `df221b6`（2026-09-22）将 interaction / pixel 两个 workflow 固定到
  `maui-ohos` `be5d471f4c962c47533cda919fc57c825a932776`（B4/B5/B6/B7 套件 tip）。
- `df221b6` 上三条 run 全绿：interaction `35629780806`、pixel `35629780800`、markdownlint `35629780817`
  （均 2026-09-21T17:05:36Z）。
- 此前 interaction 红的原因是 pin 停在 `90c8373f`（缺 B 系列符号），属 pin 未推进，不是套件回归。

## 6. 真机状态（caveat）

- 上述所有内容均为**离设备**验证；256 条套件与像素套件只在无设备环境运行。
- 当前 hap 可安装，但 `aa start` 后约 **1 秒**退出（exit 254，`AppKilledReporter` 报 `reason=JsError`）；
  探针 P1–P4（壳 / 宿主 dlopen / 宿主入口 dlsym / 逐依赖）**尚未执行/待回传**。
  见 `2026-09-21-ohos-device-crash-diagnostics.md`、`2026-09-21-ohos-crash-probes.md`。
- 因此本矩阵中"已实现"仅代表代码路径与离设备套件证据，不代表真机行为。

## 7. 剩余缺口 Top-10（工作量 S / M / L）

| # | 工作项 | 工作量 / 依赖 | 状态（2026-09-22） |
|---|---|---|---|
| 1 | 真机启动崩溃定位决策表 | 需要设备 | 待设备 |
| 2 | 把切片作为 MAUI 平台矩阵的一部分交付 | L；离线 + 上游 | 未开始 |
| 3 | `Permissions.RequestAsync` 桥接 | M；离线 | **进行中** |
| 4 | 推进 CI 切片 pin | S；离线 | **已完成（`df221b6`，CI 绿）** |
| 5 | Connectivity 桥接 | S/M | 未开始 |
| 6 | 系统剪贴板 | S/M | 未开始 |
| 7 | Email / Sms / PhoneDialer | 各 S | 未开始 |
| 8 | Screenshot + Geocoding | S/M | 未开始 |
| 9 | 无障碍 announce / 焦点遍历 + Window / SafeArea / Toolbar 收尾 | M | 未开始 |
| 10 | 真机验证扫尾 | 仅设备 | 待设备 |
