# MAUI on OpenHarmony 覆盖矩阵（2026-09-22）

> **范围**：`maui-ohos` 平台切片（`src/Core/src/Platform/OpenHarmony`；写作时点 96 个 `.cs`/tip `c4ac6a5e`，
> 2026-09-26 已达 112 个/`a0a2c087`，后续批次见 §1c）
> + `ohos-workload`（`src/OpenHarmonyHost` 原生宿主/NAPI、`src/Microsoft.OpenHarmony.Hosting` 托管宿主、
> `scripts/build-arkts-shell.sh` 壳构建、`packs/`、`test/`）+ 校验套件
> （`test/maui-platform-verify`，写作时点 284 条：271 交互 + 4 fuzz + 1 帧性能 + 8 无障碍性能；现为
> 387 条 `[verify]`/floor 367，P2b-IMG 4 条 + P2c-DEEPLINK 10 条在 P1b 的 373 之上，见 §5）+ 演示工程（`test/hello-maui-app`，多目标 20.0/26.0）。
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

### 1c. 2026-09-26 新落地批次（IMPLEMENTED；离设备，真机待证）

| 批次 | 覆盖 | 提交锚点 |
|---|---|---|
| KIT-EXT2 平台桥 | Push / Account / Map 平台扩展（特性探测 + 降级）：`OpenHarmonyPush`（`GetTokenAsync`/`DeleteTokenAsync`，`1000900010`/`1000900012` 等映射）、`OpenHarmonyAccount`（`GetQuickLoginAnonymousPhoneAsync`/`AuthorizeAsync(scopes)`，`1001502014`/`1001500001` 等映射）、`OpenHarmonyMap`（方案 (b)：`QueryCapabilitiesAsync`/`MapKitImportable`/`IsSupported`；方案 (a) MapComponent overlay 已落地（R2-3）：`IsOverlayAvailable`/show/hide/close/区域/标记 + `Ready`/`MarkerClick`/`CameraIdle`，需 harmony flavor + AGC AppKey，默认 flavor 降级不抛）；壳变量 `import()` 探测成功才注册 sink，无 Kit/AGC/HMS 一律 `Unavailable`/null/false 且不抛 | `maui-ohos 7b0500de`；`ohos-workload c89ed4a`（壳模板）、`aa44caa`（host C ABI，导出契约 118 → 130）、`e240f9a`/`a757bac`/`112b6e9`（R2-3/R2-SHELL-EXT，导出 134） |
| Share Kit 多文件 | `OpenHarmonyShareKitBridge` 多文件分支走壳 Share Kit sink；无 sink 时保留一次 no-op + 状态（默认 OpenHarmony 壳） | `maui-ohos fc7fbfdc`；`ohos-workload ccf61e6` |
| NAPI 边界加固 | 每个 C 导出加异常边界（`HostCxxBoundary`/`HostNapiEntry`）、原子 sink listener、NodeContent 身份/重绑日志、按线程 bundle-info、位置会话/IME/绘制效果与 finalizer 随代次释放 | `ohos-workload b3510c1` |
| marshal 迁移（去运行时 marshal） | 反向入口：10 个 `OpenHarmonyBridge` 回调 + pinch listener 改 `[UnmanagedCallersOnly(Cdecl)]` + `delegate* unmanaged[Cdecl]`（不再持有 delegate / 不经运行时 marshaller）；正向桥 P2 批次（125 处）走源生成 `LibraryImport` | `ohos-workload 080f422`；`maui-ohos a0a2c087`（反向）、`31f4dbac`/`096c1720`/`1a754753`（P2 B1–B3） |
| 套件契约 | kit4/kit5/kit6（Push/Account/Map 契约 + 无 Kit 降级）+ kit7（Map 覆盖层含 flavor 门）+ kit8/kit9/kit10（LiveView 探测/桥/降级）；指针驱动条目（`NativeThunks`，避免从托管直调 `UnmanagedCallersOnly`）；总数 334/floor 314 | `ohos-workload 843d371`、`18c9637`、`626f4bc`、`112b6e9` |

真机口径同 §6：以上为代码路径 + 离设备套件证据，"已实现" ≠ "已验证"。

### 1d. 2026-09-27 新落地批次（IMPLEMENTED；离设备，真机待证）

| 批次 | 覆盖 | 提交锚点 |
|---|---|---|
| P0c-TEXT-EDIT 文本编辑深度（自绘合成路线） | 光标：按字符宽度前缀和的插字符 + 500 ms 闪烁节拍 + 焦点门（非焦点不显示、不请求帧）；随滚动/焦点定位（拖拽按按下时内容空间差值换算）。选区：高亮用同一前缀和（原比例估算移除）；两个圆形选择手柄（半径 9 px、命中 24 px slop）绘制/命中/拖拽，拖拽只移动被抓手的一端（另一端为锚），并回写 `InputView.CursorPosition`/`SelectionLength`；文本手势取消在飞惯性并抑制抬手甩动（`SuppressReleaseFling`）。IME 组合（预编辑）：壳 `onChange` 的 `PreviewText` 第二参数经 `host.notifyTextComposition(value, offset)` → `ohos_host_register_text_composition`；托管在 offset 处绘制预编辑（高亮 + 下划线）并把插字符放到组合串之后，提交（空值）清预编辑并把光标推进到 `offset + 组合长度`；托管光标经 `ohos_host_keyboard_set_caret`（随 text-input sink 第二参数）同步到壳输入框；无组合导出/旧 host 时如实降级（无预编辑、不抛）。`Editor` 补齐 `CursorPosition`/`SelectionLength` 映射；`PublicAPI` 增加 public `MapCursor` | `maui-ohos e6b6ecbb`；`ohos-workload 45756e0`（壳/host）、`5e08861`（套件/文档） |
| P1a-ANIM 动画与转场深度（自绘合成路线） | 页面转场：NavigationPage/Shell 的 push/pop 在栈提交后对**新页**做进场（不透明度 0→自身值 + 水平轻位移：页宽 5%、上限 48 px，push 自右/pop 自左），由共享帧循环驱动；`DurationMs`（180）/`Curve`（CubicOut）/`Enabled`/`SlideFactor` 可配；几何在首帧惰性就位（MAUI 换页会重置页面 Width，回退 Width→Frame→SurfaceViewportWidth），提交时精确还原捕获的不透明度/位移，中断的转场先提交再开新。控件状态：Switch 旋钮+轨道（0→1 插值，轨道色以 alpha 叠加实现无分配混合）、CheckBox 对勾双段 draw-on、按压反馈（保留既有 OrangeRed 观感，以跟随进度的 alpha 叠加绘制；渐变/图片底按进度做 50% 调暗）——每通道一个惰性 `ProgressChannel`（到达目标显式退休以便重新注册），帧循环上无每帧分配。共享元素（最小可行）：键为 `AutomationId` 的保留前缀 `shared:`；出页 frame 在栈变更时捕获（虚拟 frame 无效则回退平台 view 的最后绘制 frame），入页元素在首帧读取**实时** frame，做位置 + 等比缩放（源/目标宽度比，clamp 0.2..5）+ 不透明度 morph；约束文档化（只动画进场元素——合成器只画一页；每次导航一个主元素为已验证路径）。减少动效：壳经 `@kit.AccessibilityKit`（API 23，惰性导入 + syscap/typeof 双门）→ `host.notifyAnimationReduce` → `ohos_host_animation_reduce_set`（宿主记忆最后值并对迟到的 listener 回放；导出契约 139→141）→ `OpenHarmonyMotion.ReduceMotion`：转场跳过、控件 snap、`OpenHarmonyTicker.SystemEnabled=false`（MAUI 在下一 tick force-finish）。公开动画对齐：ticker 运行期在帧循环注册只请求重绘的驱动（`FadeToAsync/TranslateToAsync/ScaleToAsync` 采样仍由 ticker 的定时器提供，重绘按平台帧对齐——自己绘制面只画 dirty）；顺带修复渲染器 transform/alpha 作用域（子树继承、不泄漏给兄弟、后端 alpha 字段随退出显式恢复） | `maui-ohos f9b63ee2`；`ohos-workload 150c14d`（壳/host/abc）、`784ddbb`（套件/文档） |
| P1b-LIST 列表深度与滚动物理（自绘合成路线；全托管，壳/host 零改动） | 增量加载：`RemainingItemsThresholdReached` 进入阈值区触发一次、区内滚动不重复、离开阈值区或条目数变化后重新武装（外加发送中的重入门，Reached 处理器扩源不会逐帧触发）。`ItemsUpdatingScrollMode`：KeepItemsInView/KeepLastItemInView 按**条目身份**（索引会在前方插入行时指向别的条目）锚定首/末可见条目并保持其屏幕位置/底对齐；KeepScrollOffset 保持原始偏移并 clamp 到收缩后的内容末端；换源丢弃物化行、槽位投影变化重排（池只回收模板行，组头/组尾重建，避免旧文本泄漏成条目）。`ScrollTo(index, group, position, animate)`：Start/Center/End/MakeVisible 全参数（已可见项不动、折叠组自动展开），`animate:true` 经共享帧循环做 160–420 ms ease-out 三次缓动（每视图一个动画；减少动效直接落位；程序化写偏移不再被采样成甩动速度）。分组：`GroupFooterTemplate` 组尾行（行布局 = 组头 + 条目 + 组尾）；`OpenHarmonyCollectionViewExtensions.SetGroupCollapsed/ToggleGroupCollapsed/IsGroupCollapsed`（PublicAPI 基线已登记）在 **ItemsSource 不变**前提下只改槽位投影与偏移（折叠视口上方组时上拉偏移，下方内容不跳），`SetGroupHeaderTogglesCollapse(true)` 打开组头点击折叠（物化行的 tap 随开关重挂）。滚动物理：拖拽越界橡皮筋（上限 64 px）、抬手回弹弹簧、甩动撞边把剩余速度转为有界过冲后精确停在边上（减少动效改为硬 clamp）；滚动条 hold/fade/`ThumbOpacity` 可调、减少动效在 hold 到期帧直接隐藏、淡出结束清注册位（修复此前每次进程只淡出一次）；1,200 条长列表检查窗口有界（13–22 行）与稳态滚动 ≤1 KiB/帧分配。壳/host 无改动：UI abc 278,760 B / `c84fbf34…`、导出契约 141 不变 | `maui-ohos cde18e60`（列表）、`150ac92f`（物理）；`ohos-workload 2ad391b`（套件/文档/工作流 pin） |

真机口径同 §6：以上为代码路径 + 离设备套件证据，"已实现" ≠ "已验证"。设备侧 IME 行为（系统输入法的预览文本节拍、隐藏输入框内的组合）仍需真机确认。

### 1e. 2026-09-27 壳深链批次（P2c-DEEPLINK；IMPLEMENTED；离设备，真机待证）

| 批次 | 覆盖 | 提交锚点 |
|---|---|---|
| P2c-DEEPLINK 壳深链与路由对齐（want/activation → `GoToAsync`） | **冷启动深链**：`onCreate` 捕获 want，`bootstrap` 在 `startApp` **前**经 `host.notifyActivation(payload)`（uri/action/parameters/linkHosts/sequence）经宿主 sink 交给托管；宿主在托管回调注册前按序入队（上限 8、丢最旧）并在注册时回放，want 不会与 runtime 启动竞争。**热激活深链**：`onNewWant` 走同一通道（bootstrap 发布前到达的 want 顶替 pending 槽，仍只产生一次激活）；壳每次递增 sequence，托管按到达顺序串行应用并丢弃重复/过期序号。**路由**：`OpenHarmonyAppLinks`（maui-ohos）把 `app://host/path?query` 映射为 `//host/path?query`、白名单内 `https://` 映射为 `//path`（白名单 = 打包写入 app.json 的 `linkHosts` ← `OpenHarmonyAppLinkHosts`，托管 `AllowedHttpsHosts` 可扩展），其余记一条状态并忽略；尚无 Shell/NavigationPage 时请求保持排队，由 `Run`/Create/Foreground/adopt 触发的 host-ready 重试（**未知路由**：无 Shell 时对 `Routing.RegisterRoute` 注册路由走 `NavigationPage.PushAsync`，未注册路由记状态、不抛、不崩）。**审批协同**：Shell 路径一律过 `GoToAsync`（即 `Navigating` 审批链，可取消），取消以"当前页未变"识别并记录为 not applied、绝不半应用；无法解析/异常一律不抛入壳回调。打包补 `OpenHarmonyAppLinkHosts`（app.json `linkHosts`），壳/host/abc：UI 281,052 B / `5c06143a…`、headless 20,916 B / `54a1a201…`、导出契约 141→143 | `maui-ohos 4b5756de`；`ohos-workload 402ed46`（壳/host/abc/打包）、`3e6d9f4`（套件/文档/工作流 pin） |

真机口径同 §6：以上为代码路径 + 离设备套件证据，"已实现" ≠ "已验证"。真机仍需确认：系统 App Linking/`want` 的实际投递（`onNewWant` 是否按预期触发、uri/parameters 形状）、以及 `module.json` 的 `abilities[].skills[].uris` 清单声明（本轮只做 app.json 白名单 + 托管校验，清单侧声明为设备后续项）。

## 2. 部分实现（Partial，附证据）

2026-09-22 更新：下表带 ✅ 的行已在本轮转为 IMPLEMENTED（已实现；提交锚点行内 + §1b），原缺口证据保留作审计轨迹；其余行仍为缺口。

| API | 现状 | 证据 |
|---|---|---|
| `Permissions.RequestAsync` | ✅ 已实现（2026-09-22；原为恒返回 `Denied`） | `maui-ohos b942952a` + `ohos-workload b7fa6da`/`e0cfc24`；原缺口 `OpenHarmonyEssentialsUnsupported.cs:63` |
| `Connectivity` | ✅ 已实现（2026-09-22；原恒 `Unknown`） | `maui-ohos b942952a` + `ohos-workload b7fa6da`；原缺口 `OpenHarmonyEssentialsExtras.cs:77` |
| `Clipboard` | ✅ 已实现（2026-09-22：系统剪贴板 + `ClipboardContentChanged`；读拒绝不弹窗并缓存） | `maui-ohos b942952a`、`6a4062b7` + `ohos-workload b7fa6da`/`e0cfc24`；原为文件后备 `OpenHarmonyEssentialsExtras.cs:11` |
| `Share` | ✅ 已实现（2026-09-26：Share Kit 多文件分支 `OpenHarmonyShareKitBridge`；无 Kit 时仍一次 no-op + 状态） | `maui-ohos fc7fbfdc`；原 `OpenHarmonyAppLauncher.cs:22`、`:193`（文本 + 单文件） |
| `SecureStorage` | ✅ 已实现（2026-09-27 P2a-HUKS：HUKS 优先 —— host 原生 AES-256-GCM 引擎（`host_keystore.c`，`libhuks_ndk.z.so` 经 dlopen 探测）生成并持有设备绑定密钥，密文 `k1:<nonce‖ct‖tag>` 落盘；别名 `maui.ohos.securestorage.v1.<path-hash>`；无 HUKS/操作失败时回退每安装文件密钥并明确标注非硬件后备；`IsHardwareBacked` 如实；`RemoveAll` 清 key。真机已验证跨进程读回 / 换别名不可解 / 删除后不可解） | `maui-ohos 99ac1818` + `ohos-workload 681bcb9`/`f333856`（原 `OpenHarmonySecureStorage.cs:1`） |
| Window mapper | ✅ 已实现（2026-09-22：每页 `SafeArea` + 窗口标题；原只映射 `Content`） | `maui-ohos aef91b0b` + `ohos-workload 29f1fbf`；原缺口 `OpenHarmonyWindowHandler.cs:9` |
| 键盘 / 焦点 | ✅ 文本编辑深度已实现（2026-09-27 P0c-TEXT-EDIT：光标闪烁/选区高亮/选择手柄拖拽/IME 组合预编辑；见 §1d）；非文本焦点遍历 / 硬件键转发仍为记录在案的 shell/host 缺口 | `maui-ohos e6b6ecbb`（原文本焦点 `OpenHarmonyEntryHandler.cs:81`、`OpenHarmonyEditorHandler.cs:70`、`b439bf73`） |
| ImageButton | ✅ 已实现（2026-09-22：已注册，含 `FontImageSource` 字形支持） | `maui-ohos 71df935f`；原缺口 `MauiOpenHarmonyExtensions.cs:15` |
| `MainThread` | 无实现 | （全切片无 `MainThread`） |
| 单元格 | ✅ 已实现（2026-09-22：`SwitchCell` / `EntryCell`） | `maui-ohos 71df935f`；原缺口（全切片无对应 handler） |
| `Window.Created` | ✅ 已实现（2026-09-22；原壳侧 `Create` 映射到 `Activated`） | `maui-ohos aef91b0b`；原缺口 `OpenHarmonyMauiAppHost.cs:87` |

## 3. 未实现（Not implemented）

- WebAuthenticator（**诚实降级已落地 2026-09-22**：`OpenHarmonyWebAuthenticator.cs` 抛
  `Microsoft.Maui.ApplicationModel.FeatureNotSupportedException`（预取消 token 报 `TaskCanceledException`、空 options 报
  `ArgumentNullException`）并写一条 `[maui]` status；`WebAuthenticator.Default`（`defaultImplementation` 字段，ModuleInitializer
  安装）与 DI（`UseOpenHarmony` 注册 `IWebAuthenticator`）均解析到该实现，reference-assembly 的
  `NotImplementedInReferenceAssemblyException` 不再可能露出。对照：rc.1 net11.0 Essentials 的 `Default` 是内部
  `WebAuthenticatorImplementation`，调用即同步抛 reference 异常）
  - 真实 OAuth 流程仍缺：① HAP 为 callback scheme 声明 ability skill（`module.json5` `abilities[].skills[].uris`，读回为
    `SkillUri.scheme/host/port/path/pathStartWith/pathRegex/type`）；skill 是静态清单数据，SDK 26.0.0.18 无运行时 scheme
    注册 API，`@ohos.app.ability.wantAgent` 只做延迟 Want 的创建/比较/触发（`getWantAgent`/`trigger`/`equal`/`cancel`）；
    ② ✅ 已落地（P2c-DEEPLINK）：壳 `EntryAbility` 在 `onCreate`/`onNewWant` 把 `want.uri`/parameters 经
    `host.notifyActivation` 转交 `Microsoft.OpenHarmony.Hosting` 的 want/activation 事件（见 §1e）；③ 浏览器 hand-off 可复用
    现有 viewData want 路径；④ PKCE/state 存储按 MAUI 契约为 app 侧职责。剩余为 ① 的清单声明 + 设备侧回调投递验证 —— 提交
    `maui-ohos 783a7fcb`、`4b5756de`；`ohos-workload 402ed46`。
- MediaElement
- TableView + legacy compatibility renderers + TitleBar + Core Toolbar

2026-09-22：Email / Sms / PhoneDialer、Screenshot / Geocoding、`SemanticScreenReader.Announce`、
Shell 扩展（SearchHandler / FlyoutHeader / TabBarIsVisible / FlyoutBehavior）已转 §1b 的
IMPLEMENTED（离设备）。`AppActions` 已有如实降级的实现（本 SDK 无动态快捷方式 setter，
`maui-ohos 2eb25493`），不再列在“未实现”。

## 4. SDK 阻塞（ohos-sdk 26.0.0.18 / API 26）

| 能力 | 阻塞原因 | 现状 |
|---|---|---|
| TextToSpeech | **已解（A2-TTS 2026-09-27）**：CLT HarmonyOS SDK（6.0.1.251）的 `hms/ets` 确认 `@kit.CoreSpeechKit` → `@hms.ai.textToSpeech`（syscap `SystemCapability.AI.TextToSpeech`，since 4.1.0(11)）；默认 OpenHarmony SDK 仍无此 Kit | 链路已落地（壳 `canIUse`+变量 import 双门、五 op sink、托管 `SpeakAsync`/`GetLocalesAsync`/`Stop`/`IsSupported`）；默认 flavor 降级不抛，harmony flavor 编译证据 abc 273,932 B / `13.0.1.0`；真机朗读需 HMS 设备 + harmony 壳（Kit 无 AGC 权益/权限门槛，AGC 清单第 13 行；见 `2026-09-24-ohos-kit-gap-analysis.md` §1/§6） |
| Map | 本 SDK 无 MapKit | 方案 (b) 能力探测已落地（`OpenHarmonyMap.QueryCapabilitiesAsync`/`MapKitImportable`/`IsSupported`，无 Kit 返 null/false）；方案 (a) MapComponent overlay 已落地（R2-3：`IsOverlayAvailable`/show/hide/close/区域/标记 + `Ready`/`MarkerClick`/`CameraIdle`），需 harmony flavor + AGC AppKey，默认 flavor 降级不抛 |
| 系统分享面板 / 多文件分享 | 无 Share Kit（`systemShare`），一个 Want 只有单个 uri 槽 | 文本 + 单文件可用（S4）；Share Kit 多文件分支已落地（无 Kit 时仍走 no-op + 一次状态） |
| Hot Reload | hdc 策略 | 硬阻塞（交接状态 §8，D4）；**开发侧替代已落地**：`ohos-workload/scripts/devloop.sh` v1（2026-09-27，28,582 B / `7491d0c3…`）一键 build → (sign) → install → start → logs（+ `--watch`），见 kit #31 交接（#30 见 kit #30 交接，#29 见 kit #29 交接） |
| arm32 | 无 runtime packs、无 32 位设备 | 见 `2026-09-21-ohos-arm32-support-gap.md` |

## 5. 套件与 CI 基线

- `test/maui-platform-verify` 期望 **391** 条 `[verify]`、门限 **floor 371**（MS-MODE 的 4 条 runtime-mode 检查
  加在 P2c-DEEPLINK 的 10 条深链/激活检查之上，后者加在 P2b-IMG 的 4 条之上；套件自报 `[suite]` 行，preflight 与 CI 同源解析；
  历史值（写作时点）：**284** 条（271 交互 + 4 fuzz + 1 帧性能 + 8 无障碍性能）、CI 下限 **264**（284-20）；
  315/floor 295 为 2026-09-22 批次值；`fb533f0` 新增 9 条 audit 检查；334/floor 314 为 KIT-EXT2 批次值，
  340/floor 320 为 P2a-HUKS 批次值；347/327 为 P0c-TEXT-EDIT、357/337 为 P1a-ANIM 批次值；
  373/353 为 P1b-LIST、377/357 为 P2b-IMG、387/367 为 P2c-DEEPLINK 批次值）。
- 切片 pin：`ohos-workload` `3e6d9f4`（2026-09-27，P2c-DEEPLINK 批次）将三个 workflow 的 `maui_ohos_ref`
  固定到 `maui-ohos` `4b5756de44257914be6fd44c62b5c03cc09329bf`（P2c-DEEPLINK tip：want/activation 深链路由；
  其下依次为 P2b-IMG `d3122bb5`、P1b-LIST `150ac92f`、P1a-ANIM `f9b63ee2`、P0c-TEXT-EDIT `e6b6ecbb`、
  P2a-HUKS、A2-TTS、R2-SHELL-EXT/KIT-EXT2 批次），下限 371（MS-MODE 起；此前 367）；三个 workflow_dispatch 的输入默认值一并推进
  （此前停滞在 `150ac92f`/`d3122bb5`，手动派发会绕过 env pin 编译旧切片）。
  演进：`df221b6` → `be5d471f`（下限 224）→ `fb533f0` → `90b21416`（下限 264）
  → `ab09918` → `c4ac6a5e` → …（KIT-EXT2 334/314、P2a-HUKS 340/320）→ `e6b6ecbb`（347/327）
  → `f9b63ee2`（357/337）→ `150ac92f`（373/353）→ `d3122bb5`（377/357）→ `4b5756de`（387/367）
  → MS-MODE 批次（`ohos-workload 57d8edf` 追加 4 检查，**391/floor 371**）。
- 最近一次本地完整验证（2026-09-27，P2c-DEEPLINK；隔离 worktree，含 P2b-IMG + P2c-DEEPLINK 切片）：
  interaction **387** 条、0 Unhandled、五条性能门 `within=True`（帧 avg 7.32 ms、4,496 B/帧；a11y skip/republish
  render + publish 两条 skip/两条 republish `within=True`）；pixel `PIXEL ASSERTIONS PASSED`；markdownlint 0 issues；
  `scripts/build-arkts-shell.sh --check-pack-abc` 三包同源（UI 281,052 B / `5c06143a…`、headless 20,916 B /
  `54a1a201…`，abc 13.0.1.0；0 ArkTS errors、三包源码字节一致）；
  host 重建（`build-host.sh`：DT_NEEDED/UND 门绿，nm 全命中 **143** 名，`check-host-exports.py --cross-check` 全绿）；
  `selftest-build-arkts-shell.sh`（165 项）、`selftest-packs.sh`（25 项）、`selftest-repo-hygiene.sh`（25 项）、
  `selftest-hap-targets.sh`（34 项）全绿；`selftest-ridgraph.sh`（20 项）在主 checkout 全绿（隔离 worktree 无
  `sdk-ohos` sibling 时 T5 的 scratch 树取不到 canonical，属环境）；`selftest-tasks.sh` 的 S3 漂移仅源于 worktree
  路径嵌入（`-p:PathMap=<worktree>=<主 checkout>` 重建后与 pack 内 `Microsoft.OpenHarmony.Tasks.dll` 逐字节一致，
  源码等价），非源码回归。
- 历史 CI：`df221b6` 上三条 run 全绿：interaction `35629780806`、pixel `35629780800`、markdownlint `35629780817`
  （均 2026-09-21T17:05:36Z）。
- 此前 interaction 红的原因是 pin 停在 `90c8373f`（缺 B 系列符号），属 pin 未推进，不是套件回归。
- 注意：MS-MODE 批次（`ohos-workload 6cdd1fa`）的离线门禁 = `selftest-hap-targets.sh` T7（runtime-mode 暂存
  fixture：jit/非法/aot 缺库与带库/interp 两种 pack 布局）、`selftest-tester-run.sh` S1–S17b（marker 解析/优先级/
  aot 回退/Run C manifest 路线）与交互套件 `[suite] checks=391 total=391 floor=371 assert=True`（4 条 ms-mode 检查）；
  CI run 状态以 GitHub Actions 结果为准。

## 6. 真机状态（caveat）

- 上述所有内容均为**离设备**验证；套件（现 391 条 / floor 371，见 §5）与像素套件只在无设备环境运行。
- 启动崩溃已定位并修复：**入口 record**（kit #10，`useNormalizedOHMUrl=false` + bundle 前缀 record；
  测试方真机复测确认入口可解析）与 **abc 字节码版本**（kit #11，`compatibleSdkVersion 18` → `13.0.1.0`；
  此前 `24.0.0.0` 超出设备 ark runtime）。**kit #31 为当前发布**（Blazor WASM/ArkWeb 组件批 = 第 6 个 hap **`hello-blazorwasm-host-unsigned.hap`**（26,794,931 B / `36010a9c…`，未签名，bundle `com.example.opendotnet`，需自签）+ tester-run v13（`--blazor-probe`：`BLZ_BOOT`/`BLZ_RENDERED`）；#30 批 = runtime-mode 打包开关（`libs/<abi>/runtime-mode.txt`；宿主 file>manifest>default）+ tester-run v12 + MAPFIX harmony 重切（MapOverlay 真编译）；含自 #17 起全部安全/性能/启动修复，并回灌设备里程碑修复：宿主按需 dlsym、`resources.index`、ZIP/mkdir、DevEco 工程布局；R2 批 = Map 覆盖层 + LiveView 探测 + `start_app` AOT 桥 + 解释器开关，R3 批 = CoreSpeechKit TTS + HUKS-first SecureStorage + 自绘深度五连（文本编辑/动画/列表/图片/深链）；kit #31 实测 tar 207,023,588/`f4325d2f…`、树 `52e77ee8…`、sidecar `7d0cba77…`、`SHA256SUMS` 16 项 / 1,410 B（#30 = 196,992,264/`a781c25b…` 仅作对照；#29 196,990,205/`e895cc0a…`））；
  详情见 `2026-09-22-ohos-startup-crash-rootcause.md` §5b/§5f 与 `2026-09-22-ohos-arkts-abc-version-history.md`。
  **2026-09-24 设备里程碑**：kit #18 + 测试方 5 项本地修复后首次完整运行成功（`managed app hello-maui-app.dll started (UI shell)`、无崩溃）；
  旧「黑屏 #4 = napi 记录名」结论已修正为无害加固 —— 直接链见 `2026-09-24-ohos-device-milestone.md` §2，**stock kit（#22 起，当前 #30）尚未上机**。
  P1–P4 阶梯仍适用于 dlopen / 缺库 / 宿主入口 / .NET 运行时类崩溃（判读分支见
  `2026-09-21-ohos-crash-probes.md` §4.0/§4.0b）。
- 因此本矩阵中"已实现"仅代表代码路径与离设备套件证据，不代表真机行为。

## 7. 剩余缺口 Top-10（2026-09-22 刷新）

| # | 工作项 | 工作量 / 依赖 | 状态（2026-09-26 刷新） |
|---|---|---|---|
| 1 | 真机启动崩溃定位决策表（入口 record / abc 版本 / P1–P4 + 最小证据） | 需要设备 | 四个历史根因已修复；2026-09-24 里程碑已达成（kit #18 + 本地修复）；待 **stock kit #28** 复测（判定点见里程碑 §6） |
| 2 | 把切片作为 MAUI 平台矩阵的一部分交付（ship-the-slice 打包） | L；离线 + 上游 | 未开始 |
| 3 | 真机验证扫尾（387 条套件 + 像素 + 真机行为） | 仅设备 | 待设备（stock kit #28 重签后；套件现为 387/floor 367；P2c 深链还需真机 want/App Linking 投递与清单声明验证） |
| 4 | CoreCLR 解释器路线（R2-INTERP 构建/发布完成 → 设备侧 `DOTNET_InterpMode=3` 冒烟） | 需真实 OHOS 交叉 ICU/OpenSSL 资产；设备侧需 `-clrinterpreter` 重建的 coreclr | **构建侧已全量打通**（2026-09-26）：feature-enabled `libcoreclr.so` 5,163,096 B + `libclrinterpreter.so` 268,320 B；`ohos-interpreter-pack.tar.gz`（2,419,988 B / `a10699b3…`）已发布到 `device-test-kit`；宿主 `<files>/interp.txt` → `DOTNET_InterpMode`（`interp=3 source=file`）；设备侧判定点见 `2026-09-24-ohos-runtime-strategy.md` §2「设备侧验证」 |

已落地（原 #3、#5–#9）：`Permissions.RequestAsync`、Connectivity、系统剪贴板、
Email / Sms / PhoneDialer、Screenshot + Geocoding、Announce / Shell 扩展、
Window / SafeArea / 标题收尾 —— 见 §1b（提交锚点）。
本轮（BATCH-3）另落地：BLE GATT 平台扩展、`ShowSettingsUI`/真实 AppInfo/`PostNotifications`、
`IApplication` handler、列表/轮播/滑动补齐、Shell 标题栏镜像 —— 见 §1b。
原 #4（推进 CI 切片 pin）经 `fb533f0` 到 `ab09918` 持续推进；interaction 套件现由 `ohos-workload` 的
workflow 直跑 `test/maui-platform-verify`（编译 pin 见 `.github/workflows/interaction-regression.yml`，
套件 387/floor 367，pin `maui-ohos 4b5756de`）。

§4 的 **SDK 阻塞清单**：TextToSpeech / Hot Reload / arm32 不变；Map 转方案 (b) 能力探测已落地、
Share Kit 多文件分享转已落地（无 Kit 时仍降级）；原 **BLE GATT** 一栏已移出（以 host/NAPI/壳桥接的
平台扩展落地，见 §1b）。
