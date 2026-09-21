# 五仓库代码规范审计（2026-09-19）
聚焦：稳定性 · 性能 · 边界。范围：`maui-ohos`（OpenHarmony 切片）、`ohos-workload`（宿主/NAPI/脚本/套件）、
`runtime-ohos`（文档）、`sdk-ohos`、`aspnetcore-ohos`（fork 增量部分）。

## 1. 探针结果（通过项）
| 检查 | 结果 |
|---|---|
| 宿主 C 分配后判空 | **5/5** ✓ |
| `strstr`/字符串解引用判空 | 已判空（`nodeText`/`description` 双条件）✓ |
| 托管 P/Invoke 异常保护 | 全仓 35 处 `catch`，逐调用点包裹（DllNotFound/EntryPointNotFound → 降级）✓ |
| 脚本健壮性 | 11 个脚本 **10 个 `set -e`**（`env.sh` 为 source 用，例外合理）✓ |
| 现有边界守卫 | `Math.Max(1, Span)`、`Math.Max(1, Interval)`、`Math.Clamp(ms, 1, 3000)`、差分循环用 `Math.Min` ✓ |
| NAPI 参数校验 | `argc` 检查 + `nullptr` 守卫 ✓ |

## 2. 本轮修复（含验证）
| 级别 | 问题 | 修复 | 验证 |
|---|---|---|---|
| **高（性能）** | 每帧**无条件**把整棵影子树发布给宿主：3 次 P/Invoke × N 节点 + 每节点 UTF-8 封送（60fps 下可达万级调用/秒）| `Publish` 先做帧间差分；**无变化则跳过全部原生通信**（新增 `WouldPublish` 可观测属性、`FramesSkipped` 计数）| 断言：`wouldPublish=False`（未变化帧）；回归 **128 项** ✓ |
| **中（边界）** | 无障碍屏幕矩形由 `float` 直接转 `int32`：极端坐标/NaN 会溢出或未定义 | 宿主新增 `A11yCoord()`：NaN→0，钳制到 ±32767，两处填充点统一使用 | 宿主构建+自签名 ✓ |

## 3a. 建议项落地情况（2026-09-19 本轮）
| 建议 | 状态 |
|---|---|
| 1 C# 分析器策略 | ✅ 已落地：`ohos-workload/Directory.Build.props`（`Nullable=enable`、`AnalysisLevel=latest`、`TreatWarningsAsErrors=false`，渐进式清理基线）|
| 2 节点刷新缓冲复用 | ✅ 已落地：帧间差分改为复用 `List`（不再每帧 `ToArray()`）|
| 3 递归改迭代 | ✅ 已落地：无障碍树遍历与诊断描边遍历均改为显式 `Stack`（深树无栈风险）|
| 4 无障碍按 id 索引 | ✅ 已落地：`TryFindNode` 改为 `Dictionary` O(1)（原线性扫描）|
| 5 脚本统一 `log()` 前缀 | ⏸ 未落地（纯外观、涉及 11 个脚本的改动面；收益低、回归风险相对高），保留为后续清理项 |

验证：交互回归 **128 项**全绿（快照 71 节点/3 按钮/26 文本、点击回流 `taps 0->1`、未变化帧 `wouldPublish=False`）。

## 3b. 原建议项清单（供对照）
1. **（规范，中）** `ohos-workload` 缺少 C# 分析器策略（无 `Directory.Build.props`：`TreatWarningsAsErrors`/`Nullable`/`AnalysisLevel`）。
   建议作为独立批次引入，先以 `Nullable=enable` + 警告清单基线化，避免一次性淹没。
2. **（性能，低）** `OpenHarmonyAccessibility.Refresh` 每帧重建节点 `List` 并读取 `SemanticProperties`；
   可复用缓冲 + 仅在布局/文本变化时重建（收益中等，风险低）。
3. **（性能，低）** 视图树遍历为递归实现（`ChildrenOf`/`DrawDiagnosticsFor`）；超深树有栈风险，可改迭代。
4. **（稳定性，低）** 宿主无障碍回调为 O(节点数) 线性查找；超大 UI 建议建索引（当前规模足够）。
5. **（规范，低）** 脚本输出日志目前散落；可统一为 `log()` 前缀（可读性）。

## 4. 结论
- 稳定性：无未判空分配、无未保护 P/Invoke、脚本普遍 `set -e`；本轮未发现崩溃级缺陷。
- 性能：**消除每帧全树发布**（最大热点）；其余为低收益项。
- 边界：矩形填充已钳制；索引访问均有界（差分循环用 `Math.Min`，`Math.Max(1,…)` 防零除）。
- 复现：`test/maui-platform-verify`（128 项，含无障碍快照/点击回流/未变化帧跳过断言）。


## 5. 对照上游 MAUI / 鸿蒙 Kit 的再次盘点（2026-09-19）

### 5a. 已实现（切片 handler 实测清单）
ActivityIndicator · Border · BoxView · Button · CarouselView · CheckBox · CollectionView · ContentView ·
DatePicker · Editor · Entry · FlyoutPage · Frame · GraphicsView · Image · IndicatorView · Label · Layout ·
ListView · NavigationPage · Page · Picker · ProgressBar · RadioButton · RefreshView · ScrollView ·
SearchBar · Shape · Shell · Slider · Stepper · SwipeView · Switch · TabbedPage · TimePicker · View ·
WebView · Window（＋G/手势/指针/捏合/无障碍/诊断/Essentials 系列/选择器）

### 5b. 可实现但尚未实现（按价值/成本排序，含平台能力依据）
1. **传感器扩展**（Magnetometer/Compass/Barometer/OrientationSensor 等）— NDK `oh_sensor.h`，复用现有管线 ✅ *正在实施（后台工作流 A）*
2. **应用启动类**（Launcher/Browser/Share）— AbilityKit start-ability（ArkTS 桥）→ 原"受限"标签可解除
3. **拖放 + 桌面菜单**（DragGesture/DropGesture、MenuBarItem/MenuFlyout）— ArkUI
4. **音频/视频播放**（MediaElement 等）— AudioKit / MediaKit / AVSessionKit
5. **触感**（HapticFeedback）— vibrator NDK（已有 Vibrator）
6. **主题/显示**（AppTheme、DeviceDisplay、屏幕常亮、文本缩放）— ArkUI 配置回调 + BasicServicesKit
7. **BlazorWebView / HybridWebView** — ArkWeb JS 桥（配方见交接文档 §7）
8. 地图 / 联系人 / 日历 / 打印 / 蓝牙 — MapKit / ContactsKit / CalendarKit / PrintingKit / ConnectivityKit

### 5c. **SDK 门控（不可实现，实测）**
- **TextToSpeech**：本 SDK（ohos-sdk 26.0.0.18，API 26）**既无 `@kit.CoreSpeechKit` 也无 `@ohos.ai.tts`**
  （两次真实 hvigor 编译均报 `Cannot find module`）。工作流 B 已把**完整链路**接好并留占位：
  托管 `SpeakAsync` → `ohos_host_tts_speak` → 壳 sink → `host.notifyTtsResult` → 结果回调；
  壳 sink 目前如实返回 `rc=-1`（不可用），待 SDK 含语音套件时替换 sink 内实现即可。
  另：`GetLocalesAsync` 降级为设备区域（无引擎枚举）。

### 5d. 归档刷新待办（由工作流 B 引出）
壳归档已重建（`dist/ets/modules.abc` 24,220 B，含 TTS sink 与"不可用"应答）→ 但 **preview.23 包内
`templates/ets/modules.ui.abc` 与 `dist/SHA256SUMS` 尚未同步** ✗。需要：把新 abc 拷入包 → 重打包 →
重发布 → 重建 hap（一条链，见第 5 节验证入口）。

## 6. 传感器扩展（工作流 A）的精度不确定项（需真机确认，已记录）

1. **Barometer 单位冲突**：实现按"宿主为 Pa → /100 得 hPa"（`101325 → 1013.25 hPa` ✓ 已单测）。
   但 OH NDK 文档对 `SENSOR_TYPE_BAROMETER` 写的是 **data[0] 为 hPa** —— 若设备按文档且宿主原样透传，
   真机可能显示 10.13 而非 1013.25。**修正只需改一个常量**（`PascalPerHectopascal`），待真机读数定夺。
2. **Orientation 语义**：NDK 文档称 `SENSOR_TYPE_ORIENTATION` 是**三个欧拉角（度）**，而当前实现按任务约定
   把 x/y/z 当作四元数向量部并重建 `w = sqrt(max(0, 1- x²-y²-z²))`。**若真机为欧拉角则不正确**；
   正解是 `ROTATION_VECTOR (259)`（4 分量）或切片内做欧拉→四元数换算。**宿主的传感器回调目前只带 x/y/z**
   （+timestamp），要支持四元数需扩展宿主回调再带一个 `w` —— 列为下一批小改动。
3. **Compass 轴向**：按约定用磁场的 x/y 轴做 `atan2(y,x)`；设备轴向约定可能导致航向旋转/翻转，
   真机核对后可加轴向修正表。
4. 三者均已有**离设备单测覆盖换算逻辑**（µT 透传 / 0-90-180-270-45° / Pa→hPa / 四元数与钳制），
   宿主不可用时 `IsSupported=false` 且不抛异常 ✓。

## 7. 工作流 C（Launcher/Browser/Share）结果与不确定项

- **导入探测**：`@ohos.app.ability.common`（`UIAbilityContext`）与 `@ohos.app.ability.Want` **均可编译** ✓
  （无需回退），壳归档重建为 **25,972 B**。
- **链路**：托管 `ohos_host_ability_start(kind, uri, text)` → 宿主转发 JS sink
  （`host.registerAbilitySink`）→ 壳 `startAbility`：kind 0 = `ohos.want.action.viewData`（Launcher/Browser/OpenFile），
  kind 1 = `ohos.want.action.sendData`（文本），kind 2 = 可用性探测（供 `CanOpenAsync`，属扩展语义）。
- **验证**：宿主 `selfsign ok` ✓；套件 **138 项** 0 unhandled ✓；离线降级均不抛异常 ✓。
- **不确定项（已记录）**：
  1. **分享文本键**：本 SDK **无 Share Kit**（`systemShare`），且 `wantConstant` 无纯文本键 →
     暂用 `'ohos.extra.param.key.content'`（Share Kit 之前生态惯例；接收方若用新键将读不到）。
  2. `CanOpenAsync` 语义 = **桥可用性**（OpenHarmony 无同步 handler 查询）。
  3. `BrowserLaunchOptions` 已接收但未透传（仅外部 ability）；`ShareFileRequest`/`ShareMultipleFilesRequest`
     为记录在案的 no-op（需 Share Kit 或 FD/URI 授权标志）；`OpenFileRequest` 以裸 `file://` 派发（未附带读权限标志）。
  4. **既有观察（未改动）**：`MauiOpenHarmonyExtensions.InstallEssentials` 反射设置 **get-only** 的 `Current`
     属性会在安装任何东西之前抛异常；实际默认经 MAUI 自身 builder 的 DI 与各处 `[ModuleInitializer]` 生效 →
     该函数应清理或改为显式空操作（列为技术债）。

## 8. 迭代规则（由多次归档刷新引出）

任何**触碰壳模板**的批次完成后，必须执行一次"归档刷新链"，否则包内 `modules.ui.abc`、`dist/SHA256SUMS`
与已签名 hap 会与源码不一致：
```
bash scripts/build-arkts-shell.sh  (HVIGOR_MIRROR=file://…/npm-mirror)
cp dist/ets/modules.abc packs/Microsoft.OpenHarmony.Sdk/<ver>/templates/ets/modules.ui.abc   (+ modules.shell.abc)
bash scripts/release-checksums.sh && bash scripts/pack-workload-bundle.sh && bash scripts/publish-workload-release.sh
cd test/hello-maui-app && dotnet publish … -p:OpenHarmonyHapPackage=true
```

## 9. 工作流 D（桌面菜单）结果与不确定项

- **编译通过的 ArkUI 方案**：`bindMenu` + **动态 `MenuElement[]`**，挂在右上角一个仅在菜单表非空时出现的
  `Button('Menu')` 上；壳从宿主表拉取（`host.menuCount()`/`host.menuItem(i)`）→ `@State` → tap 回调
  `host.notifyMenuAction(index)`。壳归档重建为 **30,228 B**。
- **链路**：`Page.MenuBarItems` → `ohos_host_menu_begin/item/commit` → `registerMenuChangedSink` → 壳 `bindMenu`
  → `notifyMenuAction(index)` → `ohos_host_menu_set_listener` → 托管 `Activate(index)` → **`IMenuItemController.Activate()`（Clicked + Command 均触发）**。
- **自动刷新**（仅新文件自接线）：`[ModuleInitializer]` 订阅 `OpenHarmonyBridge.RedrawRequested` 与 `Frame`，
  解析当前页（**模态感知**，解包 NavigationPage/TabbedPage/FlyoutPage/Shell），表格变化即重发布（含空表隐藏菜单）。
- **验证**：宿主 `selfsign ok` ✓；导出符号已确认；套件 **144 项** 0 unhandled ✓；
  断言含表内容/顺序/启用态、`disabledBlocked`、未变化帧跳过、换页自动同步。
- **不确定项（已记录）**：宿主表仅含 `text`/`enabled` → **子菜单被展平**、分隔符与小标题未发布（depth 仅在托管快照）；
  hvigor 以 `typeCheck:false` 运行（编译级验证，未在真机验证锚定行为）；菜单表发布在离设备时返回 false（以
  `WouldPublish/LastPublishedCount/IsAvailable` 为可观测信号）。

## 10. 批次节奏（已固化为流程）

每完成一个批次：① 复核其提交与验证结论 → ② 合并/同步仓库内套件 → ③ **§8 归档刷新链** → ④ 记录结果与不确定项
→ ⑤ 启动下一批次。壳归档体积随批次增长（23,880 → 24,220 → 25,972 → 30,228 B），每次都必须刷新，否则
包/校验和/hap 与源码不一致。

## 11. 工作流 E（拖放）结果与不确定项

- **分发 API 是公开的**（反射 dump 实证，*无需* 反射分发）：
  `DragGestureRecognizer.SendDragStarting/SendDropCompleted`、`DropGestureRecognizer.SendDragOver/SendDragLeave/SendDrop`
  （`SendDrop` 返回 `Task`）；事件参数构造器公开，平台参数可传 `null` ✓；所有分发均 try/catch（异步 `SendDrop` 以
  faulted continuation 观测）→ 不会破坏帧循环。
- **判定**：长按 **500 ms**（`Environment.TickCount64`，阈值常量可配）+ 位移 **8 px**（与渲染器既有 slop 一致）；
  超时后首次越过 slop 的移动即从**最深**且启用的 `DragGestureRecognizer` 视图**提升**为拖拽（并接管 down 时捕获的
  pan/swipe/slider/scroll/selection 轨道）；拖拽中命中**最深** `AllowDrop` 视图（含滚动偏移，pointer 式查找），
  目标变化发 `DragLeave`/`DragOver`；释放发 `Drop` + `DropCompleted`；文本回退 `IText/ILabel` → `AutomationId` → 空包。
- **验证**：0 error ✓；套件 **147 项**（基线 144 逐字未变，因在既有视图上附加识别器而非新增视图 ✓）0 unhandled；
  断言覆盖 `starting/over/leave/drop(text)/completed`、空处释放 `success=false`、提前移动不触发 ✓。
- **不确定项（已记录）**：`DropCompletedEventArgs.DropResult` 为 **internal 且无公开 setter** → 成功拖放亦报 `None`
  （harness 反射读取，仅对"空处释放"断言 None；成功性由 `Drop` 带正确负载证明）；判定为**触摸专用**（未合成鼠标按键拖拽）。
- **范围**：managed-only（**未改**宿主/NAPI/壳）→ **无需** §8 归档刷新 ✓。

## 12. 工作流 F（触感 + 主题跟随）结果与不确定项

- **触感（managed-only ✓）**：复用既有导出 **`ohos_host_vibrate`**（`OH_Vibrator_PlayVibration(duration, 默认属性)`）——
  与既有 `Vibration` 同源，**未改宿主**。新文件 `OpenHarmonyHaptics.cs`：`IHapticFeedback` 默认实现经私有静态字段
  反射 + `[ModuleInitializer]` 安装；映射 **Click → 30 ms 短振、LongPress → 300 ms 长振**（导出只接受时长，
  **无法表达强度/类型**）；一切调用守卫，`IsSupported` = 受守卫的 `VIBRATE` 权限查询，缺宿主库即 false，`Perform` 不抛。
- **主题跟随（shell + NAPI 桥，已实现）**：宿主新增 `notifyTheme` 与 `ohos_host_theme_set_listener`；壳用
  `Environment.envProp('colorMode')` + `@StorageProp`/`@Watch` 上报初值/变化；托管 `OpenHarmonyTheme` 注册回调并
  写 `Application.Current.UserAppTheme`（应用创建前到达的模式由 `Run` 中一行加性代码在 `Attach` 时补上）。
- **证据**：ArkTS 编译通过（生成的 `Index.ts` 含 `reportTheme`/`notifyTheme`/`declareWatch`）；宿主 `selfsign ok` +
  `llvm-nm -D` 见 `T ohos_host_theme_set_listener`；套件断言主题在暗/亮间切换并复原 ✓。
- **验证**：宿主重建（113,568 B，已签名）；套件 **152 项** 0 unhandled ✓；壳归档重建为 **31,868 B**（未入包，
  由 §8 刷新链统一处理 ✓）。
- **不确定项（已记录）**：触感无强度表达（仅时长）；主题仅编译/符号/托管三层验证，**未真机运行**；在包内壳归档
  刷新前，设备仍用旧壳（无 `notifyTheme`）→ 托管侧保持 MAUI 默认，**不会崩溃** ✓；触感 `IsSupported` 反映的是
  VIBRATE 权限而非真实振子能力探测（NDK 导出无探测接口）。
- **既有阻塞说明（非本批引入）**：切片 `.csproj` 在本部分树中因缺 `eng/AndroidX.targets` 无法独立构建 ✗，
  因此 harness（编译全部切片源码）是当前有效验证载体。

## 13. 工作流 G（ArkWeb JS 桥 + HybridWebView）结果与不确定项

- **链路**：壳 `registerWebEvalSink((script, requestId) => runJavaScript(...))` +
  `registerJavaScriptProxy({postMessage}, 'dotnetHost', ['postMessage'])`（在 `onControllerAttached` 注册，
  过早注册会触发 BusinessError 17100001）+ `onPageEnd` 重注入 `window.__ohosDotNet`；
  宿主 NAPI `registerWebEvalSink/notifyWebEvalResult/notifyJsMessage` 与 `extern "C"` 的
  `ohos_host_web_eval` / `ohos_host_web_js_register_result` / `ohos_host_web_js_register_message`（符号已核）；
  托管 `OpenHarmonyWebViewHandler.EvaluateJavaScriptAsync`（按 requestId 等待 + 超时）+ `JsMessage` 事件。
- **HybridWebView：已实现（最小）**——`IHybridWebView` 复用同一通道（`SendRawMessage`→`window.external.receiveMessage`
  或 `HybridWebViewMessageReceived`；`RawMessageReceived`；`InvokeJavaScriptAsync` 采用标准
  `__InvokeJavaScriptCompleted|taskId|json` 协议），并注册进 `SliceHandlers` ✓。
- **未实现（文件头已注明）**：**资源服务**（`HybridRoot`/`DefaultFile` 需 ArkWeb `onInterceptRequest` + 流式提供
  `wwwroot` 与 `_framework/hybridwebview.js`）→ 在其落地前 HybridWebView **不显示页面**；BlazorWebView 未尝试（同需该资源管线 + 框架文件与 IPC）。
- **验证**：宿主 `selfsign ok` + 新符号 ✓；壳归档重建 **34,412 B**（含 `dotnetHost` 等字符串）；套件 **157 项** 0 unhandled ✓。
- **不确定项（如实）**：① **未真机运行**——`CompleteEvalResult` 路径已接但未实测；壳 sink 从宿主回调线程调用
  `runJavaScript`，而 ArkWeb 文档要求 UI 线程，**这是主要真机风险**（同步失败已捕获并报 `error=1`）；
  ② JS 异常仅表现为 `null`/空，不携带异常类型；③ `registerJavaScriptProxy` **仅对下次页面加载生效**；
  ④ 入站 JS 消息**广播**给所有 HybridWebView handler（共享单一 ArkWeb 覆盖层，与既有页面事件模型一致）。

## 14. §8 刷新链的修正（本轮发现）

包内 `hosts/arm64-v8a/libopenharmonyhost.so` 由 `build-host.sh` 就地更新，但 **hap 打包读取的是
`~/.dotnet/packs/...` 的已安装副本** → 曾出现 hap 内宿主为旧体积（84,896 B）而包内已是新宿主 ✗。
**刷新链补一步**：把 `packs/Microsoft.OpenHarmony.Sdk/<ver>/hosts/arm64-v8a/libopenharmonyhost.so`
同步到 `~/.dotnet/packs/Microsoft.OpenHarmony.Sdk/*/hosts/arm64-v8a/`，再重建 hap，并以"hap 内 `.so` 体积"作为校验点 ✓。

## 15. 收尾批次：rotation-vector 取向、InstallEssentials 空操作、脚本日志辅助

### 15a. 取向传感器改用 `SENSOR_TYPE_ROTATION_VECTOR (259)`（宿主 + 托管）
- **宿主** `openharmony_host.c`：`g_sensor_listener` 签名由 `(int, float, float, float, long long)` 扩展为
  `(int, float, float, float, float, long long)`；`OhosSensorEventCallback` 在 `length > 3` 时取 `data[3]` 作为 w，
  否则 w 默认 `1.0`（对三轴传感器是无害的兼容值）；setter 强转同步更新。
- **托管** `OpenHarmonySensors.cs`：`SensorCallback` 与 `OnReading` 均改为 6 参数；`OrientationType` 由
  `256`（NDK 文档：绕 z/x/y 的欧拉角）改为 **`259`**（`SENSOR_TYPE_ROTATION_VECTOR`：data[0..2] 向量部 +
  data[3] 标量部）；`OpenHarmonyOrientationSensor.OnReading` 改为 `(x, y, z, w)` 并**原样**构造
  `OrientationSensorData`，删除 `w = sqrt(max(0, 1-x²-y²-z²))` 重建。Magnetometer/Compass 仍为 6、Barometer 8、
  Accelerometer 1、Gyroscope 2。
- **验证**：`bash scripts/build-host.sh` → **`selfsign ok`**（包内 `libopenharmonyhost.so` 113,568 B，已签名）；
  harness 新增断言：经 6 参数 `SensorCallback` 委托（`Delegate.CreateDelegate`，同时钉住原生签名）调用托管回调，
  断言 `type=259` 且 `(0.5, -0.25, 0.125, 0.75)` 原样到达 `OrientationSensorData.Orientation`（unchanged=True）✓。
  对应 §6 第 2 条不确定项（取向语义）已消除。

### 15b. `MauiOpenHarmonyExtensions.InstallEssentials` 技术债清理（managed-only）
- 删除反射设置 get-only `Current`/`Default` 的循环：该循环在第一次 `SetValue` 即抛异常，**从未生效**；方法保留为
  **显式空操作**并注明真实默认来自 `UseOpenHarmony` 的 DI 注册与各特性 `[ModuleInitializer]`（app-launching/
  haptics/menus/TextToSpeech/theme）。**DI 注册一行未动**。对应 §7 第 4 条技术债。
- **验证**：套件内 Preferences/FileSystem/SecureStorage/AppInfo/DeviceInfo/VersionTracking/Clipboard/Connectivity/
  Launcher/Browser/Share 等断言与基线一致 ✓（158 项 0 unhandled，0 error）。

### 15c. 脚本统一 `log()` / `warn()`（`ohos-workload/scripts`，仅本仓自有的 5 个脚本）
- helper（时间戳前缀、`printf`）：`log()` 写 stdout `[HH:MM:SS] …`；`warn()` 写 stderr `[HH:MM:SS] WARN: …`。
- 落地：`sign-for-device.sh`、`release-checksums.sh`、`verify-clean-install.sh`、`pack-workload-bundle.sh`、
  `publish-workload-release.sh`（均无既有 `info()`，未重复定义）。状态行 → `log`，错误/用法行 → `warn`；
  未改变控制流、退出码与输出流（错误仍在 stderr）。
- **验证**：5 个脚本 `sh -n` 全部通过 ✓。

### 15d. 本批验证汇总
- 宿主：`build-host.sh` 以 `selfsign ok` 结束 ✓（签名后 113,568 B）。
- harness（临时目录与仓库内 `test/maui-platform-verify` 同步逐字节一致）：`dotnet build` 0 error；
  运行 **158 项 `[verify]`、0 `Unhandled`**（基线 157 → 158，新增 rotation-vector 断言）✓。
- 脚本：`sh -n` 5/5 ✓。
- 仓库：`maui-ohos`（传感器 + InstallEssentials）、`ohos-workload`（宿主 + 套件 + 脚本）、`runtime-ohos`（本节）。
- **注**：本批未触发 §8 归档刷新链（未改壳模板）；包内 `.so` 已由 `build-host.sh` 就地更新，
  `dist` 归档与 hap 内嵌副本（§14 的 `~/.dotnet/packs` 同步步骤）留待下一次释放批次统一刷新。

## 16. 工作流 H（日历 + 联系人）结果、探测结论与后续

- **联系人（平台扩展）**：`OpenHarmonyContacts.FindAsync(prefix, limit)` → `ohos_host_contacts_query` →
  壳 `registerContactsSink` → 申请 `READ_CONTACTS` → `contact.queryContacts`（`@kit.ContactsKit`，**编译通过**）
  → 前缀过滤 + 限量 → `notifyContactsResult` → 托管 Task；拒绝/异常/无 sink → 空列表且 `IsSupported=false`，不抛。
- **日历（平台扩展）**：`OpenHarmonyCalendar.ListUpcomingAsync(days)` / `AddEventAsync(title, startIso, endIso)`
  → `ohos_host_calendar_list/_add` → 壳 `registerCalendarSink`（op 0/1）→ `READ_CALENDAR`（+`WRITE_CALENDAR`）→
  `calendarManager.getCalendarManager().getCalendar()` → `getEvents(EventFilter.filterByTime(...))` / `addEvent({type: EventType.NORMAL, ...})`
  （`@kit.CalendarKit`，**编译通过、0 ArkTS 错误**）→ `notifyCalendarResult` → 托管 Task；同等降级。
- **验证**：宿主重建 **117,664 B**（`selfsign ok`，7 个新导出已核）；套件 **163 项** 0 unhandled ✓
  （新增：离线空结果/立即 `IsSupported=false`、模拟 sink 负载解析含畸形行丢弃）；壳归档 **40,048 B**。
- **能力探测（本 SDK 实测）**：
  | 模块 | 结论 |
  |---|---|
  | `@kit.PrintingKit` | **缺失**（`Cannot find module`）；但 `@ohos.print` 存在且可编译 → 后续批次可用 |
  | `@kit.ConnectivityKit` | **存在且可编译**（`connection.BluetoothTransport` 通过）；注意 `connection.GattClientDevice` 未导出、`bluetooth`/`bluetoothManager` 已标记废弃 |
  | `@kit.MapKit` | **缺失**（OpenHarmony SDK 无 MapKit） |
- **首要后续（H 引出）**：`templates/module.json.template` **未声明权限**（READ_CONTACTS / READ_CALENDAR / WRITE_CALENDAR）
  → 真机将如实报不可用。该模板为**所有应用共享**，故本批未改动（避免给所有应用增加安装期权限提示）；
  建议以**可选属性**（如 `-p:OpenHarmonyExtraPermissions=...`）在打包时注入，再逐应用启用。
- **不确定项**：联系人前缀过滤为**客户端过滤**（Kit 无前缀查询）→ 大通讯录下会先全量拉取再截断；真机侧仅"降级"被验证，
  套件执行未真机运行。

## 17. 权限注入 + HybridWebView 资源服务（2026-09-20）

### ① 打包权限注入（已实现并实测）
- 属性 **`OpenHarmonyExtraPermissions`**（默认空）加入 `preview.22|23` 的 `targets/OpenHarmony.Hap.targets`。
- 语义：非空时在生成的 `module.json` 追加 `"requestPermissions":[{"name":"..."}]`（**最小条目**，无 `usedScene`）；
  以 `;`/`,` 分隔、去空白、丢空项；**未设置时目标代码路径不进入** → `module.json` 与改动前**逐字一致** ✓。
- 实测（同一 publish 命令两次构建）：无属性 hap 的 `module.json` 982 B 与改动前 **cmp 逐字相同** ✓；
  设属性后 1129 B，**diff 仅新增三个权限条目**（READ_CONTACTS / READ_CALENDAR / WRITE_CALENDAR）✓。
- **用法注意**：`-p:Prop="a;b"` 会被 shell 去引号导致 MSB1006 → 需 `-p:'Prop="a;b"'`（或 `%3B`）；已在 target 顶部注明 ✓。
- 证据目录：`/data/storage/el2/base/tmp/opencode/item1/{baseline,no-prop,with-prop}`。

### ② HybridWebView 资源服务（探测 + 实现）
- **探测更正**：`@ohos.web.webview.d.ts` **不含** `onInterceptRequest`/`WebResourceRequest/Response`；
  它们位于 **ArkUI 组件声明** `ets/component/web.d.ts`（`onInterceptRequest` L9433、`WebResourceRequest` L3951、
  `WebResourceResponse.setResponseData` L4347 等），返回 `null` 表示不拦截 ✓。
- **编译验证**：壳 `CompileArkTS` 通过（abc **49,120 B**，含 `onInterceptRequest`/`hybrid`/`__hwvSendMessage`）；
  另以 `typeCheck: true` 的最小拦截页复验 **0 ArkTS 错误** ✓。
- **实现**：壳经 `onInterceptRequest` + `@ohos.file.fs` 提供 `<AppDir>/<HybridRoot>/…` 与
  `<AppDir>/_framework/hybridwebview.js`；`__hwvSendMessage`（token/body 头）转发 `host.notifyJsMessage`；
  仅在注册后拦截；handler 提取内嵌引导资源并映射 `HybridRoot`/`DefaultFile`；
  **本批补充**：HybridWebView 连接时调用 `EnsureMessageRegistered`（此前纯 Hybrid 应用不会绑定消息 sink）✓。
- **仍未实现（记录在案）**：`__hwvInvokeDotNet`（需 `setResponseIsReady` 延迟数据）→ 页面侧 `InvokeDotNet` 不可用，
  **.NET→JS 可用**；**BlazorWebView 未触碰**。
- **不确定项**：ArkWeb 无真机执行（顶层导航拦截 `https://0.0.0.1/`、自定义头投递、`fileIo` 读取均**仅编译级验证**）；
  应在下次真机发布中复验 `InApp` 行为。

### ③ 新发现的环境怪癖（后续项）
`_OpenHarmonyHapStageDir` 为空（workload 目标求值时 `PublishDir` 未设置）→ publish 把 `module.json`/`ets`/`resources`/`libs`
**落进 demo 工程目录**，会覆盖受跟踪的示例文件（本批已恢复、未提交）。建议修正暂存目录或加入 `.gitignore`。

## 18. 批次 I（蓝牙 + 打印 + 地图评估）与 J-2（暂存目录修复）

### 批次 I（174 项）
- **蓝牙**（平台扩展）：`IsEnabledAsync/GetPairedDevicesAsync/StartDiscoveryAsync/StopDiscoveryAsync` →
  `ohos_host_bluetooth_query` → 壳 `registerBluetoothSink` → 权限 `ohos.permission.ACCESS_BLUETOOTH`（user_grant）→
  `access.getState()` / `connection.getPairedDevices()+getRemoteDeviceName()` / `start|stopBluetoothDiscovery()` →
  结果回调；**仅用可编译成员**（避未导出的 `GattClientDevice` 与废弃 `bluetooth*`）；配对设备 `name\taddress` 行；
  `IsSupported` 探测权限；代码 `0` 完成 / `-1` 不可用 / `-2` 瞬时（适配器关闭）。
- **打印**（平台扩展）：`PrintTextAsync(jobName, text)` → 生成 **A4 PDF**（Helvetica/WinAnsi、53 行/页、转义完备）→
  `PrintFileAsync` → `ohos_host_print_file` → `print.print([path], context)` → 结果回调；权限
  `ohos.permission.PRINT`（system_grant，无弹窗）；PDF 结构经**独立 Python xref/stream 解析器**验证 ✓。
- **地图（仅评估）**：建议默认 **(c) 交给应用**；若需一方地图面，首选 **(b) ArkWeb 承载**（JS 桥 + 资源服务已具备）；
  (a) GraphicsView+瓦片仅适合静态预览。
- 验证：宿主 `selfsign ok`（**121,760 B**，6 新导出已核）· 壳 `typeCheck:true` **0 ArkTS 错误**（abc **53,240 B**）·
  套件 **174 项** 0 unhandled · 单文件在 `TreatWarningsAsErrors` 下 0 警告 ✓。
- 随后需经 `-p:'OpenHarmonyExtraPermissions="ohos.permission.ACCESS_BLUETOOTH;ohos.permission.PRINT"'` 声明权限，
  否则真机如实不可用。

### J-2：hap 暂存目录修复（已实测）
- **根因**：`_OpenHarmonyHapStageDir` 在**求值期**依赖尚未赋值的 `PublishDir` → 为空 → 所有暂存路径塌缩成项目相对路径，
  把 `module.json`/`ets`/`resources`/`libs` 写进 **demo 工程目录** ✗。
- **修复**：新增 `_OpenHarmonyResolveHapStageDir`（执行期解析）→ `OpenHarmonyHapStageDir`（可覆盖）默认
  `$(IntermediateOutputPath)openharmony-hap/`，备选 `$(BaseIntermediateOutputPath)`/`$(PublishDir)` 派生；
  **解析到工程目录即 `Error`**；`_OpenHarmonyStageHap`/`_OpenHarmonyPackHap` 均依赖之；文件头文档化 ✓。
  实测暂存路径：`test/hello-maui-app/obj/Release/net11.0-openharmony26.0/openharmony-arm64/openharmony-hap/`。
- **验收证据**：① publish 后 `git status --short test/hello-maui-app` **空**（连发 3 次）且受跟踪文件 sha256 前后一致 ✓
  ② `sign-app success`/`verify-app success` ✓ ③ hap 9 项含 `ets/modules.abc 53,240`、`libs/...so 117,664` ✓
  ④ 植入 `STALE_MARKER.txt`/`ets/STALE.abc` 后下次 publish **被清理且不入包**；两次发布 **242 个负载文件逐字节一致**
  （仅外层 hap 因签名时间戳不同）✓；套件 174 ✓。
- **环境备注**：MSBuild workload 解析走**已安装**的 `~/.dotnet/packs/.../preview.22`（忽略 `DOTNETSDK_WORKLOAD_PACK_ROOTS`），
  已同步修复后的 targets 到该副本（备份于 `/data/.../hap-stage-fix/installed-22-Hap.targets.bak`）——属环境副本，非仓库改动。
- **既有环境怪癖（非本修复引入）**：publish 退出后 ~3 s 有外部进程给 13 个运行时 `.so` **追加 ELF `.codesign` 段**
  （+4–8 KB），使 `dotnet.zip` 在连续发布间必然不同；确定性检查在清理 `publish/` 后进行。
- **后续**：feed 安装要拿到本修复需**重打包 preview.22/23**（发布刷新步骤已覆盖 ✓）。

## 19. JS→.NET 调用闭环（`__hwvInvokeDotNet`）与 BlazorWebView 就绪评估

- **探测证据（SDK 26.0.0.18）**：`ets/component/web.d.ts` 提供 `setResponseIsReady(bool)`（@since 9）、
  `setResponseData`、`setResponseCode/MimeType/Encoding`、`setReasonMessage`、`getResponseIsReady()`（@since 13）；
  以 `typeCheck: true` 的 scratch 页验证**顺序可用**：拦截时返回 `setResponseIsReady(false)` → 稍后
  `setResponseData` + `setResponseIsReady(true)`，**0 ArkTS 错误** ✓（探测日志 `/data/.../probe-build.log`）。
- **链路**：`hybridwebview.js` POST `https://0.0.0.1/__hwvInvokeDotNet`（`X-Maui-Invoke-Token` / `X-Maui-Request-Body`）
  → 壳 `hybridInvokeResponse`（code 200/JSON/utf-8，**先挂起**，注册 pending + 15 s 兜底）→
  `host.notifyHybridInvoke(requestId, method, argsJson)` → 宿主 NAPI `notifyHybridInvoke` / 原生
  `ohos_host_hwv_register_invoke` / `ohos_host_hwv_invoke_result` → 托管
  `IHybridWebView.Invoker.InvokeMethodAsync(method, params)`（10 s 超时）→ `DotNetInvokeResult` JSON 回填（成功
  `Result/IsJson`；失败 `IsError/ErrorMessage/ErrorType/ErrorStackTrace`）→ 壳下一 tick `setResponseData` + `setResponseReady(true)`。
- **降级（页面 promise 永不悬挂）**：错 token/体 → 400；坏 JSON → 400；缺宿主导出 → 错误负载；无活动页/无 invoker/
  未知方法/坏参数/超时 → 错误负载；壳兜底计时器 → 错误负载 ✓。
- **验证**：宿主 `selfsign ok` + `T ohos_host_hwv_invoke_result`/`_register_invoke`（含 NAPI 字符串）✓；
  壳 `TYPECHECK=1` **0 ArkTS 错误**（abc **58,420 B**，并新增 `TYPECHECK=1` 开关与 typeCheck loader 所需的
  `node_modules` 链接，均非侵入、默认行为不变）✓；套件 **181 项** 0 unhandled ✓（新增 `Echo`→`"echo:hi"`(IsJson)、
  `Add`→`42`、缺方法、坏参数 JSON、无目标、断连页、无宿主桥等 6 类负载）；demo publish 后
  `git status --short test/hello-maui-app` **空** ✓（J-2 验收点保持）。
- **BlazorWebView：评估为多日工程，未实现**。可复用：ArkWeb 拦截 + 刚验证的**延迟响应**、`dotnetHost.postMessage`、
  `ohos_host_web_eval`、内嵌脚本抽取。**缺口**：`Microsoft.AspNetCore.Components.WebView.Maui` 包（本地缓存无、源可拉）、
  OpenHarmony 版 `BlazorWebViewHandler`（maui-ohos 树内仅有 Tizen partial）、`OpenHarmonyWebViewManager`
  （`NavigateCore/SendMessage/MessageReceivedInternal`）、**Blazor 感知的资源提供器**（内容根 + `_framework`：`blazor.webview.js`/
  `dotnet.wasm`/`_*.dll`）、`window.external`↔`dotnetHost` 初始化脚本、带帧的 JS↔.NET 传输。**风险**：ArkWeb 内 WASM 执行未证、
  单 `postMessage` 代理无顺序/背压、ohos-arm64 publish 不产出 Blazor WASM 资产。
- **不确定项**：往返为**离设备验证**（ArkTS 类型检查 + 托管侧经与原生回调相同入口驱动）；**ArkWeb 延迟响应投递**与
  跨线程 NAPI 回填（continuation 调 `ohos_host_hwv_invoke_result`）**未真机验证**（该 NAPI 模式与既有 `ohos_host_web_eval`/picker 一致）；
  调用路由假设**单 Hybrid 页**（多实例时为 best-effort）；包内壳二进制未变 → hap 需经
  `-p:OpenHarmonyArktsModulesAbc=<repo>/dist/ets/modules.abc` 才能带上新壳。

## 20. 批次 J：蓝牙发现上抛 · 电池 · 显示 · 无障碍节点探测（191 项）

- **蓝牙发现（已实现）**：探测 `@ohos.bluetooth.connection` 的 `connection.on('bluetoothDeviceFind', Callback<string[]>)`
  （@since 10/跨设备 13）可编译 ✓ → 壳在 `StartDiscoveryAsync`（op 2）清表并注册监听，逐地址 `getRemoteDeviceName` 解析后
  经 `host.notifyBluetoothDeviceFound("name\taddress")` 推送；停止时移除监听；**op 4** 返回累积表；
  宿主新增 `ohos_host_bluetooth_register_device_found` / `_device_found`（**与查询路径分离** → 旧宿主最多丢推送，绝不丢配对列表 ✓）；
  托管新增 `DeviceFound` 事件与 `GetDiscoveredDevicesAsync()`；离线：空表、事件不触发、不抛 ✓。
- **电池（已实现）**：探测 `@kit.BasicServicesKit` 的 `batteryInfo`（`batterySOC`/`chargingStatus`/`pluggedType`/`isBatteryPresent`）
  与 `power.getPowerMode()`（`DevicePowerMode` 600–650）✓；本 MAUI 版本有 `IBattery` 与 **可设置的 `Battery.defaultImplementation`**
  → 实现并安装（反射 + `[ModuleInitializer]`）；壳在启动与 `BATTERY_CHANGED`/`CHARGING`/`DISCHARGING`/`POWER_SAVE_MODE_CHANGED`
  公共事件时推 `soc\tcharge\tplugged\tpresent\tpowerMode`；宿主在监听注册时**重放最后负载** ✓。
  映射：`DISABLE`→`Discharging`（OpenHarmony 无 `NotCharging` 区分）；plugged `NONE`→`Battery` ✓（已记录）。
- **显示（已实现）**：探测 `@ohos.display` 的 `getDefaultDisplaySync()`（宽高/`densityDPI`/`rotation`/`refreshRate`/`orientation`）
  与 `display.on('change')` ✓；实现 `IDeviceDisplay`（密度 = densityDPI/160；rotation 0..3 → Rotation0..270；方向含宽高回退），
  快照去重后触发 `MainDisplayInfoChanged`；`KeepScreenOn` **无平台路径**（getter false、setter 忽略，已注明）✓；
  推路径 `host.notifyDisplay`（启动 + change，宿主重放）✓。
- **无障碍 CUSTOM 节点（仅探测，关键结论）**：
  - **编译通过**：`import { FrameNode, NodeContent, NodeController, typeNode } from '@ohos.arkui.node'`、`typeNode.createNode(uiContext,'Column')`、
    `NodeContent.addFrameNode(node)`、`FrameNode.getNodeType()/isAttached()/getUniqueId()`、`UIContext.getFrameNodeById/ByUniqueId()`、
    `NodeController.makeNode()`、`NodeContainer(controller)`、`host.attachAccessibilityNode(frameNode)` ✓。
  - **编译失败**：`typeNode.createNode(uiContext, 'custom')` → `10505001 No overload… '"custom"' is not assignable to … 'GridItem'`
    → **ArkTS 无自定义节点创建类型** ✗。
  - **正确解法（头文件证据）**：`OH_ArkUI_NativeModule_GetNativeAccessibilityProvider` 在节点非 `ARKUI_NODE_CUSTOM` 时返回 PARAM_INVALID
    （`native_interface_accessibility.h`，`libace_ndk.z.so`）；**原生模块可自建该节点**：
    `OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1)` → `createNode(ARKUI_NODE_CUSTOM)` →
    `OH_ArkUI_NodeContent_AddNode(content, node)`（`native_node.h`）→ 再取 provider（预期 **status 1**）✓。
  - **🔴 发现真实缺陷**：`SetNodeContent` 中的 `AttachAccessibilityValue(...)` 调用**位于 `return` 之后不可达** ✗，
    且壳从未调用 `attachAccessibilityNode` ✗ → **当前 provider 根本无法附着**；真机应先用 `typeNode.createNode` 的 FrameNode 验证
    `GetNodeHandleFromNapiValue`（预期 status 2），再按上面的**原生 CUSTOM 节点**路径接线（下一批）。
- **验证**：宿主 `selfsign ok`（新增 4 导出，共 **101** 个 `ohos_host_*`）✓；壳 `TYPECHECK=1` **0 ArkTS 错误**（abc **65,296 B**）✓；
  套件 **191 项** 0 unhandled（+10：发现降级/解析/事件、电池与显示默认安装、负载解析、原生形状推送）✓。
- **不确定项**：电池公共事件订阅与 `display.on('change')` 的真机行为未验证（有守卫；启动快照即使订阅被拒也可用）；
  事件回调运行在壳/UI 线程（重负载应由用户自行派发）；`typeNode.createNode` FrameNode 能否通过 `GetNodeHandleFromNapiValue`
  与 CUSTOM 节点所需布局仍需真机确认；切片独立 `.csproj` 受既有 `eng/AndroidX.targets` 缺失影响，验证走 harness 编译路径 ✓。

## 21. 无障碍附着修复（host-only，2026-09-20）

- **修复的缺陷**：`SetNodeContent` 中 `AttachAccessibilityValue(...)` 原位于 `return` 之后（死代码 ✗）→ 现为
  "先存 content，再执行附着"，并加 `argc/argv[0]` 与 env/value 守卫 ✓。
- **新增原生 CUSTOM 节点路径**（ArkTS 无法创建自定义节点，故必须在原生侧建）：
  `OH_ArkUI_GetNodeContentFromNapiValue` → `OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1)`
  → `api->createNode(ARKUI_NODE_CUSTOM)` → `OH_ArkUI_NodeContent_AddNode(content, custom)`
  → `OH_ArkUI_NativeModule_GetNativeAccessibilityProvider(&custom, &provider)` → `RegisterCallback` ✓。
  provider 指针**仅在回调注册成功后提交**；自定义节点**缓存复用**，页面重入不重复添加；已附着直接返回 ✓。
- **状态映射（真机日志判读）**：`0` 未附着 · **`1` 已附着+回调注册（期望）** · `2` frame node 被拒（非 CUSTOM）·
  `3` NodeContent 收到但 CUSTOM 节点未能创建/挂载 · `4` CUSTOM 已挂但 provider 被拒 → **3/4 精确定位失败步骤** ✓。
- **头文件逐字签名**（SDK 26.0.0.18_1）：`OH_ArkUI_GetModuleInterface`（宏，底层 `OH_ArkUI_QueryModuleInterfaceByName`）·
  `ArkUI_NodeHandle (*createNode)(ArkUI_NodeType)`（`ARKUI_NODE_CUSTOM = 0`）· `OH_ArkUI_NodeContent_AddNode`（@since 12）·
  `OH_ArkUI_NativeModule_GetNativeAccessibilityProvider`（@since 23，**非 CUSTOM 即 PARAM_INVALID**）✓。
- **验证**：宿主 `selfsign ok` + 导入符号（`NodeContent_AddNode`/`QueryModuleInterfaceByName`/`GetNativeAccessibilityProvider`）✓；
  套件 **191 项** 0 unhandled ✓（离设备仍为 0，**未伪造设备结果**）。
- **真机唯一待确认**：provider 对原生 CUSTOM 节点是否返回非 null（预期 status=1）；`setNodeContent` 于 `aboutToAppear`
  （早于 `build` 挂载 `NodeContainer`）执行，provider 只校验节点类型，预期可行，**由真机确认**。

## 22. 真机前壳侧风险消除（K-1，2026-09-20）

### 风险 1：ArkWeb 调用来自非 UI 线程
- **采用机制（实测可编译）**：壳内单一助手
  ```ts
  private runOnUiThread(task: () => void): void {
    setTimeout(() => { this.getUIContext().runScopedTask(task); }, 0);
  }
  ```
  **诚实说明**：`UIContext.runScopedTask` 是**同步的作用域绑定**（`syncInstanceId` → 回调 → `restoreInstanceId`），
  **不切换线程**；真正的线程跳变来自 `setTimeout(...,0)` 的**延迟执行**（由页面 ArkTS/UI 事件循环服务）✓。
- **包裹的全部宿主回调 → ArkWeb 路径**：`registerWebSink`（`loadUrl`/`loadData`/`accessBackward`/`backward`/`registerHybridAssets` 的 `loadUrl`）、
  `registerWebEvalSink`（`runJavaScript`，保持同脚本/同 requestId/同错误应答）、`completeHybridInvoke`
  （`setResponseData`/`Code`/`ReasonMessage`/`setResponseIsReady(true)`，原裸 `setTimeout` 改为该助手，**避免双重延迟**并保持
  not-ready → data → ready 顺序）✓。
- **有意不加包裹**：`onControllerAttached`/`onPageBegin`/`onPageEnd`/`onInterceptRequest`（ArkUI 原生事件，非宿主回调）✓。

### 风险 2：附着发生在页面挂载之前
- `build()` **本就**在 Stack 内以 `ContentSlot(this.content)` 承载（约 L1049）→ **未新增 NodeContainer、布局未变** ✓。
- `host.setNodeContent(this.content)` 由 `aboutToAppear` **移至 `onPageShow()`**（挂载后执行）→ 目标：真机 status 从 3 → **1** ✓；
  `host.notifyLifecycle(2)` 保留在 `aboutToAppear`；宿主已缓存自定义节点，重复 show 不会重复添加 ✓。

### 验证与提交
- `TYPECHECK=1`：`CompileArkTS` 通过，**`ArkTS:ERROR` 计数 = 0**（仅既有 WARN：权限提示、`getContext` 废弃、NAPI 校验）✓；
  仅 `PackageHap`（缺 `app_packing_tool.jar`）失败，属既有容忍项 ✓。
- 普通重建：`dist/ets/modules.abc` = **66,392 B**（typecheck 与普通构建一致，md5 `10228e9e…`）；**未入包、未跑发布刷新** ✓。
- 套件：干净构建 + **191 项** 0 unhandled ✓。preview.22 与 preview.23 为**逐字节镜像**（`cmp` 验证）✓。
- 提交：`ohos-workload d12aeb2`（PUSHED ✓）。

### 不确定项（已记录）
- `setTimeout` 注册在托管线程后**是否由 UI 事件循环服务**无法离设备证明（既有 hybrid 代码与本任务均按此约定）；
  若真机仍报 `17100001`，**确定性修复是宿主改用 `napi_threadsafe_function`**（在 `host_napi.cpp`，超出本批文件范围）→ 已写入提交信息 ✓。
- `registerTextInputSink` 的 `focusControl.requestFocus(...)` 属同类"非 UI 线程 UI 调用"但**非 ArkWeb**，按范围未动；
  另发现既有小怪癖（`registerNotificationSink` 嵌在 picker sink 内）也未改动 ✓。

## 23. 多目标与 API 波段（K-2，2026-09-20）

### 交付
- **demo 改为多目标**：`<TargetFrameworks>net11.0-openharmony20.0;net11.0-openharmony26.0</TargetFrameworks>`
  （不带 `-f` 时**两者都构建**；`TargetFramework` 为空，已在 `project.assets.json` 验证两个 TFM 的还原与 `openharmony-arm64` 目标）✓。
- **四个 hap（均通过独立 `hap-sign-tool verify-app`）**：
  | 产物 | 大小 | SHA-256 | 权限 | 波段 |
  |---|---|---|---|---|
  | 26 默认 | 21,708,016 B | `cbe69482…d9be52` | 0 | min 60001021 / target 60101024 / Beta1 |
  | 26 权限 | 21,708,011 B | `f2023d8c…4e660d` | 5 | 同上 |
  | 20 默认 | 21,695,727 B | `076a08c1…c84e55` | 0 | 同上 |
  | **20 权限（新补）** | 21,699,816 B | `c49512a5…c96a97d` | 5 | 同上 |
  权限五项 = ACCESS_BLUETOOTH / PRINT / READ_CONTACTS / READ_CALENDAR / WRITE_CALENDAR；权限变体以
  `-p:'OpenHarmonyExtraPermissions="…"'` **整体单引号**传入（无 MSB1006）✓。
- **干净度**：六次 publish 后 `git status --short test/hello-maui-app` 仅含预期的 csproj 改动；所有受跟踪夹具
  sha256 **前后逐字节一致** ✓（J-2 暂存修复持续生效）。套件 **191 项** 0 unhandled ✓。
- 提交：`ohos-workload 943e398`（PUSHED ✓）。

### 🔴 波段发现（重要，含证据与解码）
`targets/OpenHarmony.Hap.targets`（preview.22/23 逐字节相同）**无条件硬编码**：
`OpenHarmonyMinApiVersion=60001021`、`OpenHarmonyTargetApiVersion=60101024`、`OpenHarmonyApiReleaseType=Beta1`。
- **解码**（DevEco hvigor 6.26.4 的 `apiTransform` + `sdkmanager-common` 的 `parseApiVersion/ApiVersion`）：
  格式 = `<major><minor:02><patch:02><api:03>`（去前导零）→ `60001021` = **平台 6.0.1 / API 21**；`60101024` = **平台 6.1.1 / API 24**。
  设备侧印证：`ServiceConstants::API_VERSION_MOD=1000`、`BundleDataMgr::GreatOrEqualTargetAPIVersion` 取 `%1000` 为 API 级别。
- **结论**：**API 20 变体实际声明 min API 21** ✗ → 在 API 20 设备上（OpenHarmony 6.0.0/API 20 的 `const.ohos.apiversion=20`，
  `module.json` 未写 `compileSdkType` → 默认 `OpenHarmony`，参考 BMS `CheckApiInfo` **裸比较**）会以
  **`ERR_APPEXECFWK_INSTALL_SDK_INCOMPATIBLE`（bm 9568297）** 被拒 ✗。
- **修正值（按同一解码推导，待真机确认）**：API 20 波段应传
  `-p:OpenHarmonyMinApiVersion=60000020 -p:OpenHarmonyTargetApiVersion=60000020`（平台 6.0.0 / API 20）✓；
  若目标设备为 HarmonyOS 6.0.1/API 21，则维持 `60001021` ✓。

### 不确定项（如实记录）
- 拒装判定源自开源 OpenHarmony BMS（`bundlemanager_bundle_framework`）；测试设备为**厂商 HarmonyOS 栈**（BMS 闭源），
  故未能在真机上执行确认；但两种解释下 **min 21 > 20** 的风险都成立 ✓。
- `60101024` → 平台 6.1.1/API 24 的解码仅有 6.0.1(21) 有外部印证。
- 四个 hap **负载不完全一致**：`dotnet.zip` 内的原生负载（如 `libcoreclr.so`）在发布间漂移 4–8 KB（每次有 1 个合法的 4096 字节
  ELF `.codesign` 段，由共享构建/签名流程引入）；四者验签与清单/权限均正确 ✓，但**若真机轮次要求负载逐字节一致需先处理** ✗。

### 待办（并入下一轮刷新）
1. 用 **API 20 正确波段**（`60000020`）重建 API 20 的默认/权限 hap（若测试设备确为 API 20）；
2. 结合 P1/P2（版本标识日志 / 蓝牙去重 / Blazor 探测）后的新切片与壳归档（66,392 B）**统一 §8 刷新**；
3. 重建交付包（4 hap + 指南 + `SHA256SUMS`）并给出最终哈希。

## 24. P1/P2 收尾（交付资产 + 版本横幅 + 蓝牙去重 + Blazor 里程碑 1）

- **交付包发布为 release 资产（P1）**：脚本新增 `--kit/--kit-tag/--skip-kit` 与 `DEVICE_TEST_KIT(_TAG)`；
  实测发布 `device-test-kit`（`device-test-kit.tar.gz` + `.sha256`，round-trip `sha256sum -c → OK` ✓）并在
  `workload-latest` 一并附带（与 bundle、`SHA256SUMS` 共 4 资产）；缺件时仅记日志、不破坏既有发布 ✓（`ohos-workload fb38bdc`）。
- **启动构建标识（P1）**：`OpenHarmonyBuildBanner.cs`（`[ModuleInitializer]` + `Interlocked` 一次性 + try/catch），
  格式 `[maui] openharmony build <ver> abi=<arch> provider=<n|n/a>`；实测输出恰一行 ✓；
  **启动时 `provider=0` 属预期**（壳在 `onPageShow` 才附着），附着后真实值由既有 `accessibility provider status=` 行报告 ✓（`maui-ohos e19e152`）。
- **蓝牙发现去重/排序（P2）**：trim + 空地址丢弃 + 同地址合并（后到者补名）+ **按 name→address 序**（OrdinalIgnoreCase，文化无关）；
  `DeviceFound` **每新地址至多一次**（`ConcurrentDictionary.TryAdd`），`StartDiscoveryAsync` 成功时清零（与壳清表一致）；
  `ParseDevices/ParsePairedDevices` 保持**原样**（线序/重复），共享 harness 断言不变 ✓（`maui-ohos 268cf66`）。
- **BlazorWebView 里程碑 1（P2）**：**NuGet 包可还原** ✓（`Microsoft.AspNetCore.Components.WebView.Maui 11.0.0-rc.1.26451.6`，经 darc
  `dotnet-public` feed，20 包、0 警告 0 错误）；已交付**与包无关**的资产映射文件 `OpenHarmonyBlazorWebView.cs`
  （`AppOrigin=https://0.0.0.0/`、`ContentRoot=wwwroot`、`ResolveAssetPath` 含 percent-decode 与**路径穿越拒绝**、`IsFrameworkRequest`）✓；
  里程碑 2 = handler partial / WebViewManager / Blazor 资产提供器 / `window.external` 初始化 ✓。
- **验证**：两批各在**独立 harness 副本**运行（P1: 191/0；P2: 195/0 含 4 条草稿断言）；共享目录未被污染 ✓；
  推送均 `fetch→rebase`（禁强推）✓。
- **备注**：`git fetch origin` 默认不更新 `origin/feature/openharmony`（refspec 仅映射 `main`）→ 需
  `git fetch origin feature/openharmony` 或 `git ls-remote` 核对远端 tip ✓（已写入本记录）。

## 25. 真机前硬化批次（Q1–Q3；Q4 待重试）

- **Q1 宿主（`ohos-workload 269dbfc`）**：**14 个 sink 改经 `napi_threadsafe_function` 投递**
  （每 sink 一个 TSFN，`max_queue=64`、`initial_thread_count=1`；替换时 `napi_tsfn_abort`；参数拷入堆负载后非阻塞投递，
  JS/UI 线程重建参数并以原 `this` 调用；每 sink 互斥锁 + 待处理表，中止项释放，无 UAF/泄漏；队列满每轮一次告警后丢弃）
  → **ArkWeb 线程风险由"假设"变为确定性投递** ✓；**唯一保持直连**：launcher/browser/share（同步布尔语义无法经 TSFN 表达，
  否则会谎报"已派发"）✓ 已注明。同时 **`SetOperationActions` 发布动作列表**：12 个动作位全覆盖（CLICK/LONG_CLICK/
  GAIN·CLEAR_FOCUS/SCROLL_*/COPY·PASTE·CUT/SELECT_TEXT/SET_TEXT/SET_CURSOR_POSITION；掩码为 0 不调用）✓。
- **Q2 壳（`ohos-workload 7d7acc8`）**：`injectPageBridge()` 提供 **`window.external.sendMessage/receiveMessage`**
  （后者派发 `HybridWebViewMessageReceived` CustomEvent，与托管 `SendRawMessage` 形状一致；**仅补缺不覆盖**）✓；
  新增**无障碍自检入口**（左下 44×24 `A11Y` 按钮 → 弹窗显示 `accessibilityStatus` 0–4 映射 +（若导出存在）节点数；
  不占布局、不动 XContent/ContentSlot）✓；abc → **70,392 B**；`TYPECHECK=1` **0 `ArkTS:ERROR`** ✓。
- **Q3 打包（`ohos-workload 60e2cf7`）**：
  - **`.codesign` 漂移根因**：SDK 的 `_OpenHarmonyCodesignBuildOutputs`（Build 后、`Directories=$(TargetDir)` **递归**）
    会提前重签 `publish/` 内 ELF，而 hap 打包在 Publish 之后 → 打入陈旧重签副本；`ElfSigner` 每轮 strip+注入 4 KB 页 →
    **每脏发布累积 2 页（8 KB）**；另有 `ZipDirectory` 的 FS 序 + mtime 不稳定 ✗。
  - **修复**：① `_OpenHarmonyResetHapPublishOutputs`（`BeforeTargets=PrepareForPublish`，仅 hap）清复用 publish 目录，
    从单次签名 runtime pack 重拷贝 → 载荷仅保留**一份**标准 `.codesign`；② `dotnet.zip` 改由内联
    **`OpenHarmonyDeterministicZip`**（序数排序 + 固定 `1980-01-01` 时间戳 + deflate）写出 ✓。
  - **验证**：26.0 载荷 `4ac80200…3379` **连续 3 次一致**；20.0 `b03a313f…77c7` **两次一致**；两 hap `verify-app success` ✓。
  - **按 TFM 波段**：20.0 → min=target=**60000020**（6.0.0/API 20）、`apiReleaseType=Release`；26.0 → min **60001021**、
    target **60101024**、`Beta1`（阈值可覆盖；解码规则 `<major><minor:02><patch:02><api:03>` 已写入 targets 头）✓。
- **Q4（CI 191 项门禁 + 确定性模糊/压力）**：**首次运行因 OOM 失败** ✗ → 已按缩减范围重试（先 CI，fuzz 后补）；
  其产物（workflow/harness）**不影响** 包与 hap，故本轮刷新不等它 ✓。
- 三批均在**独立 harness 副本**验证（191/0）✓，未触碰共享目录与 demo 工程 ✓，推送均 `fetch→rebase`（禁强推）✓。

## 26. Q4/Q5 收官（CI 门禁 · fuzz · 上手文档；2026-09-20）

### Q4-A：191 项成为**真实 CI 门禁**（`ohos-workload 81531b8`，已推送 ✓）
- Workflow（`.github/workflows/interaction-regression.yml`）：①检出本仓 ②**检出 `springmin/maui-ohos@feature/openharmony`**
  （切片仅存在于该分支；fork 公开，`fetch-depth: 1`）③`setup-dotnet 11.0.x preview` ④Release 构建
  `Microsoft.OpenHarmony.Hosting` 与 `Microsoft.OpenHarmony.Maui.Graphics`（harness 的 HintPath 两者都引用）
  ⑤以 `MAUI_SLICE_DIR`/`HOSTING_DLL`/`OPENHARMONY_GRAPHICS_DLL` 运行套件；`set -euo pipefail` 下**要求**：
  退出 0、`[verify]` **≥191**、无 `Unhandled`，否则失败 ✓；**不再依赖仓库变量**；像素 workflow 未动 ✓。
- `verify.csproj` 新增 `OPENHARMONY_GRAPHICS_DLL → OpenHarmonyGraphicsDll`（原 Graphics HintPath 为硬编码绝对路径 ✗），
  保留旧绝对回退 ✓；README 记录环境变量、门禁与计数 ✓。
- **本地已验证**：PyYAML `safe_load` 解析两个 workflow ✓；`bash -n` 通过（替换 `${{ }}` 后）✓；
  独立 harness 副本以三环境变量构建并**两次运行：exit 0 / 195 项 / 0 Unhandled** ✓。
  **仅 runner 可验**：maui-ohos 检出、其上的 Release 构建、workflow 驱动的套件 ✓；MAUI 包在 nuget.org 上存在 ✓。

### Q4-B：确定性 fuzz 尾段（`ohos-workload add3a5f`，已推送 ✓）
- 固定种子 `20260920`，**0.14–0.21 s**（断言 <30 s）：300 组 down/move/up（含 ±2,000,000 与 ±`float.MaxValue` 等**有限极值**，
  每 5 次落在 1080×1920 内）；32 KiB `__RawMessage` 与 48 KiB `notifyJsMessage` 负载（**往返断言**）；
  **301 节点/150 层深树**经 `OpenHarmonyWindowRenderer.Render`（迭代式无障碍 Visit + 诊断遍历）与 `Describe` 驱动；
  断言**无未处理异常、无挂起** ✓（新增 4 条 `[verify]`）。

### 过程记录（诚实）
- Q4 分为两个提交：Part A 提交后**并发会话推送**导致 README 冲突（`git fetch` 显示远端已前进），
  **禁止强推** → Part B 作为后续提交落在其上（Part A 的树已正确 rebase，无历史改写）✓。
- **runner 前提**：`springmin/maui-ohos` 需保持公开（或提供可读 token）；workflow 本机无法执行 ✓。
- Q5 的**上手文档已交付**（`runtime-ohos f0f5071ffda`：feed 安装 / TFM publish / 签名与 UDID / 故障排查）；
  **BlazorWebView 里程碑 2 骨架未落地** ✗（重启中断）——包可还原 ✓，方向见 §19/§24；建议作为 Q5b 续做 ✓。

## 27. BlazorWebView 里程碑 2 骨架（Q5b，2026-09-20；编译级）

### 交付（`maui-ohos`，已推送 `feature/openharmony`）
- **包引用可用** ✓：`Microsoft.AspNetCore.Components.WebView.Maui 11.0.0-rc.1.26451.6`（darc `dotnet-public`）
  已加入切片 csproj。资产：`lib/net11.0`（本次编译面）+ `net11.0-android37.0 / ios26.5 / maccatalyst26.5 /
  windows10.0.19041 / windows10.0.20348`；net11.0 依赖 `Microsoft.AspNetCore.Components.WebView`、
  `Microsoft.JSInterop`、`Microsoft.AspNetCore.Authorization` 均为 `11.0.0-preview.7.26381.103`；该 net11.0
  程序集**引用 `Microsoft.Maui.Controls`**（编译车辆必须可解析，见"门"；切片现只引 Core+Graphics，留给里程碑 3 决策）。
- **新文件** `src/Core/src/Platform/OpenHarmony/OpenHarmonyBlazorWebViewHandler.cs`（365 行，整体
  `#if OPENHARMONY_BLAZOR_WEBVIEW`）：
  - `OpenHarmonyBlazorWebViewHandler : OpenHarmonyViewHandler<IBlazorWebView>, IBlazorWebViewHandler`：Mapper
    （HostPage/RootComponents）、`CreatePlatformView`（`IsWebView=true`）、`ConnectHandler`（挂
    `OpenHarmonyWebViewHandler.JsMessage` + `EnsureMessageRegistered` + `RegisterBlazorAssets`）、
    `CreateFileProvider`、`TryDispatchAsync`；`RegisterBlazorAssets` 经里程碑 1 `ResolveContentRoot` 校验后向壳发
    `blazor` 命令（`origin`/`base`/`root`/`defaultFile` 的 JSON 描述符）。
  - `OpenHarmonyWebViewManager : WebViewManager`：按包签名构造；`NavigateCore` → 壳 `load` 命令；`SendMessage` →
    `window.__dispatchMessageCallback`（优先）/ 壳 `window.external.receiveMessage`（bootstrap 前回退）；
    `MessageReceivedFromShell` 包装基类 protected `MessageReceived`。
  - `OpenHarmonyBlazorFileProvider`（+`FileInfo`/`DirectoryContents`）：每个子路径都过里程碑 1
    `ResolveAssetPath`（根路径 / `\` / `.`/`..` 拒绝），`Watch` = `NullChangeToken.Singleton`。
- **编译门（诚实口径）**：独立切片 csproj 在本部分检出仍不可构建（`eng/AndroidX.targets` 缺失，既有条件），
  可工作的门是 **harness 副本**。注意 `tmp/opencode/maui-platform-verify` 共享副本滞后（13:23，无 fuzz 尾段），
  本批改从 `ohos-workload/test/maui-platform-verify`（Q4-B 最新版）拷到 `/data/.../verify-q5b`，在副本临时加包引用 +
  `OPENHARMONY_BLAZOR_WEBVIEW` → `dotnet build` **0 error**，该文件 0 warning，`verify.dll` 元数据含
  `OpenHarmonyBlazorWebViewHandler`/`OpenHarmonyWebViewManager`/`OpenHarmonyBlazorFileProvider`；再把副本恢复
  canonical（无包/无常量）重建 → **0 error** 且运行 **exit 0 / 195 `[verify]` / 0 Unhandled**，证明共享 CI 口径不回归。
  两次构建均为内存保护模式（`-m:1`、`UseSharedCompilation=false`、禁 MSBuild server）✓。
- **回归与边界**：扩展口径同样 exit 0 / **195 项** / 0 Unhandled（含 fuzz 4 项，~0.13 s）✓；未跑 demo publish、
  未做 release 刷新 ✓。
- **提交**：`5c61b95`（csproj 包引用 + 骨架）→ `706ee40`（传输语义修正，见下），两者已推 `feature/openharmony`。
- **显式未交付（里程碑 3）**：壳侧 `blazor` 命令与 `https://0.0.0.0/` 拦截、真实 `WebViewManager` 实例化 +
  `Blazor.start()` bootstrap、hap 内 `wwwroot/_framework` 资产、`UsePlatformHandler` 注册接线、真机 WASM 验证 ✗。

### 🔴 传输语义发现（包内 JS 反查；骨架据此修正）
- `Microsoft.AspNetCore.Components.WebView 11.0.0-preview.7.26381.103` 的
  `staticwebassets/blazor.webview.js`（604,610 B，唯一权威）确认：JS→.NET 走
  `window.external.sendMessage(message)`（壳 `sendMessage` → `dotnetHost`，现成 ✓）；.NET→JS 是
  `window.external.receiveMessage(callback)` = **注册接收回调**，投递必须走 `window.__dispatchMessageCallback(message)`
  （与包内 Tizen 实现一致）。
- 壳 `injectPageBridge` 的 `window.external.receiveMessage(message)`（HybridWebView 语义：派发
  `HybridWebViewMessageReceived` CustomEvent）与 Blazor 的注册语义**不同**；若 bootstrap 后仍先调壳版本会吞掉消息 →
  `706ee40` 已把骨架 `SendMessage` 改为 `__dispatchMessageCallback` 优先、壳 shim 仅作 bootstrap 前回退，并把契约写入文件头。

### 里程碑 3 清单（精确）
1. **包/TFM**：保持 `Microsoft.AspNetCore.Components.WebView.Maui 11.0.0-rc.1.26451.6`（`lib/net11.0`）；编译面同时
   提供 `Microsoft.Maui.Controls`（net11.0 程序集引用它）。
2. **handler 注册**：`builder.Services.AddMauiBlazorWebView().UsePlatformHandler<OpenHarmonyBlazorWebViewHandler>()`
   （`BlazorWebViewServiceCollectionExtensions.AddMauiBlazorWebView` + `MauiBlazorWebViewBuilderExtensions.UsePlatformHandler<T>`，
   包 XML 文档口径）；**不要**复用包内 net11.0 的 `BlazorWebViewHandler`（无平台实现）。
3. **handler 形状**（对齐包内 Tizen partial，`src/BlazorWebView/src/Maui/Tizen/BlazorWebViewHandler.Tizen.cs` 是本部分检出里
   唯一可参考的完整平台 partial）：`RequiredStartupPropertiesSet`（HostPage + Services）、幂等
   `StartWebViewCoreIfPossible`、`contentRootDir`/`hostPageRelativePath`、`VirtualView.CreateFileProvider`、
   `new MauiDispatcher(Services.GetRequiredService<IDispatcher>())`、`BlazorWebViewInitializing/Initialized` 事件、
   `RootComponent.AddToWebViewManagerAsync`、`Navigate(VirtualView.StartPath)`、`DisconnectHandler` 里 `DisposeAsync` + 解绑。
4. **WebViewManager 成员**（包 XML 全量）：基类 ctor `(IServiceProvider, Dispatcher, Uri, IFileProvider,
   JSComponentConfigurationStore, string)`；抽象 `NavigateCore(Uri)`、`SendMessage(string)`；protected
   `MessageReceived(Uri,string)`；供壳拦截的 `TryGetResponseContent(string,bool,out int,out string,out Stream,
   out IDictionary<string,string>)`；`AddRootComponentAsync`/`RemoveRootComponentAsync`；`DisposeAsync`；
   `TryDispatchAsync`；`Dispatcher` 属性；可选 `StaticContentHotReloadManager.AttachToWebViewManagerIfEnabled`。
5. **资产管线**：内容根 `<AppDir>/wwwroot`（HostPage `wwwroot/index.html`）；包 target
   `ConvertStaticWebAssetsToMauiAssets`（`Microsoft.AspNetCore.Components.WebView.Maui/build/*.targets`，
   `ComputeStaticWebAssetsTargetPaths PathPrefix="wwwroot"`）把 `@(StaticWebAsset)` 变 `@(MauiAsset)`（带 `TargetPath`）；
   **必须先确认 ohos TFM 谁消费 `@(MauiAsset)` 并写进 publish/hap**——本部分检出的 OpenHarmony SDK targets 与
   maui-ohos `Microsoft.Maui.Sdk` 均未发现消费者，现有 demo 也没有 `wwwroot`；否则壳侧只能沿用 hybrid 的
   "内嵌资源/启动时解包"路径。要服务的文件以 `blazor.webview.js` 为入口 = dotnet 运行时/加载器（`dotnet.js`、
   `dotnet.native.js`、`dotnet.native.wasm` 等，随 SDK 波段变化）+ 应用程序集（Release 默认 WebCIL `.wasm`；
   `WasmEnableWebcil=false` 时为 `_*.dll`）+ `blazor.boot.json` + satellite；**以应用自己的静态 Web 资产 manifest 为准，不猜名**。
6. **壳侧 `blazor` 命令与拦截**：`https://0.0.0.0/` origin + `<AppDir>/<contentRoot>` 根 + 默认文件，复用 hybrid 的
   `onInterceptRequest` 延迟响应（`setResponseIsReady(false)`）路径；`_framework/*` 与普通文件同路径（里程碑 1
   `IsFrameworkRequest` 仅为诊断/特例保留）。
7. **bootstrap（每文档一次，load 前注入）**：Tizen 式 `window.__receiveMessageCallbacks` +
   `__dispatchMessageCallback`；`window.external = window.external || {}`，`sendMessage` → 壳 `dotnetHost`
   （`__ohosDotNet`）postMessage，`receiveMessage` → push callback（**覆盖该页**壳 shim）；随后 `Blazor.start()`；
   `onpageshow` persisted → reload。
8. **JS↔.NET 帧**：JS 负载 = `blazor.webview.js` 私有前缀 + `JSON.stringify([messageType,...args])`，壳**原样**
   转 `OpenHarmonyWebViewHandler.JsMessage` → `OnJsMessage` → `MessageReceived(AppOrigin, payload)`；.NET 方向
   `SendMessage` 经 eval 送 `__dispatchMessageCallback(message)`（字符串用 `JsonSerializer.Serialize` 转义）。
9. **真机/风险**：ArkWeb 的 WebAssembly 执行未验证（对齐 §19）；`dotnet publish -f net11.0-openharmony26.0` /
   `openharmony-arm64` **不会**产出 browser-wasm 负载（Blazor WASM SDK 只认 `browser-wasm` RID）→ 需独立 WASM 发布 +
   `MauiAsset`/内嵌资源搬运，或为 ohos TFM 增加静态 Web 资产管线；两条路都未实现 ✗。

### 不确定项
- 本批是**编译级**：只证明骨架对 `11.0.0-rc.1.26451.6` 的 net11.0 资产可编译；`UsePlatformHandler` 注册、dispatcher/服务范围、
  `WebViewManager.MessageReceived` 的前缀解析与真机行为**未运行** ✗。
- 运行时加载器文件名（`dotnet.wasm` vs `dotnet.native.wasm` + loader 脚本）随 .NET 11 波段变化，清单第 5 条以 manifest 为准 ✓。
- net11.0 包程序集引用 `Microsoft.Maui.Controls` 而切片现只引 Core+Graphics；独立切片本来就不可构建，故本批未改引用集，
  留给里程碑 3 决定（handler 放 Controls 侧程序集 vs. 给切片补 Controls）✓。
- 共享 `tmp/opencode/maui-platform-verify` 副本滞后于 Q4-B（无 fuzz 尾段）；本批用仓库内最新 harness 的独立副本验证，
  **未改共享树** ✓。若要把骨架纳入真实 CI 门禁，需给 `ohos-workload/test/maui-platform-verify` 加包引用 + 常量（另仓提交，见待办）。

### 待办（并入下一轮）
1. 里程碑 3 清单 1–9（尤其第 2、5、6、7 条：注册、`MauiAsset` 落 hap、壳拦截、bootstrap）。
2. 如需 CI 级回归，给 ohos-workload harness 加 `Microsoft.AspNetCore.Components.WebView.Maui` 包引用 +
   `OPENHARMONY_BLAZOR_WEBVIEW` 常量，并把 `[verify]` 期望值从 195 上调（本批未改该仓）。
3. §8 归档刷新与 release 不受本批影响（无 hap 产物）✓。

## 28. BlazorWebView 里程碑 3.0：hap 资产管线 + ArkTS bootstrap（native 模型；2026-09-20）

### 🔑 关键洞察：native 模型，不是 WASM 模型
- 宿主在**进程内**运行托管应用（CoreCLR 在 `libopenharmonyhost.so` 里），因此本平台的 MAUI Blazor 是
  **native 模型**（与 Android/iOS 相同），不是 WebAssembly 模型：**不需要** `dotnet.wasm` /
  `dotnet.native.js` / `_*.dll` 浏览器资产，WebView 侧只需要 `blazor.webview.js` + `window.external`
  消息传输。
- 反查包内唯一权威 `blazor.webview.js`（`Microsoft.AspNetCore.Components.WebView 11.0.0-preview.7.26381.103`
  的 `staticwebassets/blazor.webview.js`，604,610 B，sha256 `713e519fcd217fa2ca56e8307a166ae89bb296008fd18f2b79f65daeaa7ae1aa`）：
  JS→.NET 只有 `window.external.sendMessage(…)`（`__bwv:` 前缀负载）；.NET→JS 是
  `window.external.receiveMessage(callback)` 注册 + `__dispatchMessageCallback(message)` 投递；bundle 对
  `window.external` 的读取全部发生在 `Blazor.start()`（`jt()`）内部，页面 script 标签本身不读它。
  **没有任何 wasm/dotnet loader 代码路径**。
- 里程碑 2 待办第 9 条的"需独立 WASM 发布 + `MauiAsset`/内嵌资源搬运"是**被否定的假设**，不是待办；
  本批没有搬运任何浏览器资产 ✓。

### Task A：pack 资产管线（`ohos-workload 811f0d5`）
- 新目标 `_OpenHarmonyStageBlazorAssets`（`packs/.../targets/OpenHarmony.Hap.targets`，preview.23 + 镜像
  preview.22），挂在 `_OpenHarmonyStageHap` 的 `DependsOnTargets`：**Publish 之后、写
  `resources/rawfile/dotnet.zip` 之前**；无 `wwwroot` 时 no-op（无 item、无 copy、无消息），payload 不变。
- **staging 约定**：`<project>/wwwroot/**` → `<PublishDir>/wwwroot/**`；hap 里 `dotnet.zip` 由
  `EntryAbility.bootstrap()` 解包到 `<AppDir>`（`filesDir/dotnet`），运行时路径即 `<AppDir>/wwwroot/...`
  = 壳的 `<base>/<root>/...` **与 hybrid 的 `https://0.0.0.1/` 服务约定完全同构**（Blazor 的
  `https://0.0.0.0/` 从这个根服务）。
- `wwwroot/_framework/blazor.webview.js` 来源优先级：`@(StaticWebAsset)`（Razor/静态资产管线跑过时，
  版本最匹配）→ NuGet 缓存
  `$(NuGetPackageRoot)microsoft.aspnetcore.components.webview/*/staticwebassets/blazor.webview.js`；
  另消费 `@(MauiAsset)` 中 `TargetPath` 以 `wwwroot/` 开头的项（本部分树缺失的 MauiAsset consumer 的替代，
  `wwwroot/` 前缀同时防止越出内容根）。约定已写入目标文件头。

### Task B：壳 bootstrap（`ohos-workload 811f0d5`；`Index.ets`，双版本）
- 新 `blazor` web command：解析 `{origin, base, root, defaultFile}`、加上尾 `/`、注册后 load origin
  （与 hybrid 同形；2b manager 落地后 `Navigate` 会再 load 一次，属等价重载）。
- `onInterceptRequest`：Blazor origin 一律按 `<base>/<root>/<path>` 服务；`_framework/blazor.webview.js`
  在 Blazor 下是普通内容根文件（不同于 hybrid 的 `_framework/hybridwebview.js` 特例）。读取逻辑抽成
  `servePayloadFile`，`serveHybridFile`/`serveBlazorFile` 只是薄封装，**hybrid 行为逐字不变**。
- `onPageEnd`（Blazor root 文档、`onPageBegin` 重置一次性守卫）注入包期望的序列（与 Tizen/iOS 平台实现同款）：
  1. `window.__receiveMessageCallbacks = []`；`window.__dispatchMessageCallback(message)` fan-out；
  2. `window.external.sendMessage` → `dotnetHost.postMessage`（复用注入的 hybrid shim）；
  3. `window.external.receiveMessage(callback)` 改为**注册式**（只覆盖 Blazor 文档，hybrid 页面的 Event 语义不动）；
  4. `Blazor.start()`：`typeof Blazor !== 'undefined'` 时立即调用；否则复用/注入
     `<script src="https://0.0.0.0/_framework/blazor.webview.js" autostart="false">` 并在其 `load` 后启动；
     另设 `window.onpageshow` persisted → reload。
- UI 线程：注入发生在 `onPageEnd`（ArkUI 回调，UI 线程），`runJavaScript` 调用方式与既有 `injectPageBridge`
  一致；host→壳的 `blazor` 命令继续走既有 `runOnUiThread` 路径 ✓。

### Task C：切片对齐（`maui-ohos dc91e92`，注释级）
- 只更新 `OpenHarmonyBlazorWebViewHandler.cs` 的过时 TODO 注释（文件头、`ConnectHandler`、
  `RegisterBlazorAssets`、`NavigateCore`），说明 milestone 3 的壳/资产管线/bootstrap 已落地、bootstrap 不
  由 handler eval；**无代码变化**，`#if OPENHARMONY_BLAZOR_WEBVIEW` 编译门未动 ✓。

### 验证
- **ArkTS 类型检查**：`TYPECHECK=1 HVIGOR_MIRROR=file:///data/storage/el2/base/tmp/opencode/npm-mirror bash
  scripts/build-arkts-shell.sh` → `Finished :entry:default@CompileArkTS`，**0 `ArkTS:ERROR`**（只有既有
  warning：napi 未验证、蓝牙权限、`getContext` 弃用等）；新 `dist/ets/modules.abc` = **78,060 B**
  （旧 70,392 B），**未复制进 pack**（发布刷新仍是独立步骤）✓。
- **demo 发布**（hello-maui-app，`net11.0-openharmony26.0`；本机安装态是 preview.22 pack，发布前把其
  `targets/OpenHarmony.Hap.targets` 同步成仓库新文件）：
  - 无 wwwroot：publish 成功，`git status --short test/hello-maui-app` **空** ✓，`verify-app success`；
  - 临时加 `wwwroot/index.html` + `wwwroot/css/app.css`：staging 消息出现；hap（21,905,242 B，
    sha256 `9c736db450c07d5fa01ccb81767f5db5bd37415c3f1a45d4b233457907e8f83d`）内 `dotnet.zip` 含
    `wwwroot/index.html`（533 B，sha256 `16a1e226…`）、`wwwroot/css/app.css`（34 B，`0bf4d668…`）、
    `wwwroot/_framework/blazor.webview.js`（604,610 B，`713e519f…` == NuGet 缓存原件）；独立
    `hap-sign-tool verify-app` **success** ✓；
  - 删除 wwwroot 重发：无 staging 消息、dotnet.zip **无 wwwroot 项**（`_OpenHarmonyResetHapPublishOutputs`
    同时清掉 stale publish）、21,725,015 B（sha256 `c3346277…`）、`verify-app success`、git status 空 ✓。
- **bootstrap JS 冒烟**（Node vm，对从 Index.ets 抽出的模板）：14 项断言全过——fan-out、sendMessage、
  注入 `autostart="false"`、load 后 start、已加载立即 start、二次运行 no-op、已有 script 标签等待其 load ✓。
- **harness**（自建副本 `/data/storage/el2/base/tmp/opencode/verify-r1`，`-m:1` +
  `UseSharedCompilation=false` + `UseMSBuildServer=false`）：exit 0，**195 `[verify]` / 0 `Unhandled` /
  0 `assert=False`** ✓；副本 `bin/`/`obj/` 已删除。
- `sh -n`：本批未改任何 shell 脚本 ✓。

### 提交与推送
- `ohos-workload master`：**`811f0d5`**（pack targets ×2 + Index.ets ×2）。
- `maui-ohos feature/openharmony`：**`dc91e92`**（注释级契约对齐）。
- 本档位于 `runtime-ohos feature/openharmony` 同步提交中（见仓库 `git log`）。
- 推送按 `git -c http.version=HTTP/1.1 push origin <branch>`（失败重试 6 次、间隔 15s；远端前进则
  fetch+rebase）；结果以会话报告/远端 `git ls-remote` 为准。

### 不确定项
- **真机未验**：壳的拦截/bootstrap 只过了 ArkTS 类型检查与 JS 冒烟，没有设备上 `Blazor.start()`、组件渲染、
  JS↔.NET 往返的运行时证据；managed `WebViewManager` 实例化仍是 milestone 2b（未接 `UsePlatformHandler`），
  所以端到端本来就是"资产 + 壳就绪、管理器待接"的状态。
- 壳在 `blazor` 注册时会自动 load origin；2b manager 落地后 `Navigate` 会重复 load 一次（等价重载，非错误）。
- NuGet 缓存 fallback 在多个 `microsoft.aspnetcore.components.webview` 版本共存时由文件系统枚举顺序决定
  （`@(StaticWebAsset)` 存在时优先且唯一）；本机只有一个版本。
- demo 发布用的是**机器已安装**的 preview.22 pack；仓库 preview.23 的 targets/Index 与 preview.22 逐字节一致，
  但 preview.23 的 pack 没有经过一次真实 `dotnet workload install` 流程（发布刷新另步）。
- "0 `ArkTS:ERROR`" 只覆盖编译/类型检查，不覆盖 ArkWeb 运行时；bootstrap 的 JS 行为用 Node 桩验证，
  **不是在 ArkWeb 引擎里执行**。

### 待办（并入下一轮）
1. milestone 2b：实例化 `OpenHarmonyWebViewManager`（services/dispatcher + `UsePlatformHandler` 注册）、
   `AddToWebViewManagerAsync`、`Navigate`、`DisconnectHandler` 的 `DisposeAsync`。
2. 真机验证 Blazor Hybrid：首屏渲染、计数器/JS interop 往返、`blazor.webview.js` 指纹路由与
   缓存头（本批只按非指纹 URL 服务）。
3. release 刷新时把 78,060 B 的 `modules.abc` 装进 pack 模板并重新生成设备测试 kit。

## 29. 无障碍 provider R2：方向焦点 · editable/checkable · range 缺口（host-only，2026-09-20）

### 范围与原则
- 仅改 `ohos-workload/src/OpenHarmonyHost/host_napi.cpp`（无障碍回调与元素填充）。托管切片与 C 节点表
  （`openharmony_host.c`）**只读未动**；C 符号/链接不变，无壳改动，无新导出。
- 契约审计结论：角色/文本/描述/矩形可靠；**flags/actions 在真机上目前不可靠**（既有错位，见 §4）；
  勾选值与范围值（min/max/current）**没有任何发布字段** → 不伪造。

### 1. 方向焦点（`findNextFocusAccessibilityNode`）
- 原实现忽略 `direction`，固定返回"下一个可聚焦"。现按 `ArkUI_AccessibilityFocusMoveDirection` 分两类：
  - **UP/DOWN/LEFT/RIGHT（几何启发式）**：以当前节点屏幕矩形**中心**为原点；候选须是可聚焦节点且在主轴上
    "严格在前"（主轴增量 ≥ `kA11yFocusEpsilon = 1px`，因此身后的、与原点重叠的、NaN 矩形全部跳过）；
    评分 `主轴增量 + 2 × 垂直增量`（`kA11yFocusPerpendicularPenalty = 2.0`，单位同为像素），平局先比垂直
    距离、再比发布索引（确定性）。
  - **FORWARD/BACKWARD（索引顺序）**：按发布顺序（托管树先根后子）从当前索引前/后开始，环形回绕。
  - 语义边界：`elementId <= 0` 视为"无当前节点"——几何方向用根（索引 0；托管发布以根为首、findById 对 ≤0
    返回根）矩形为原点；FORWARD 从首个可聚焦、BACKWARD 从末个可聚焦开始。id 不在表中但 > 0 时保留
    R2 前的 `id == index+1` 回退；`INVALID`/未知方向保留 R2 前的顺序移动。无候选 → `FAILED`。
- 常数、平局规则、跳过条件全部写在代码注释里；47 项原生断言（真实抽取代码 + 真实节点表）覆盖 6 个方向、
  回绕、非可聚焦诱饵、NaN、越界 id 与无候选分支。

### 2. editable / checkable（角色派生）
- `textInput` → `SetEditable(true)`；`checkBox`/`switch` → `SetCheckable(true)`；列表查询（findById/findByText）
  与单节点填充（findFocused/findNextFocus）共用同一 helper。
- **`SetChecked` 不调用**：节点记录没有 checked 值；对可能已打开的开关报"未选中"比不报更糟。

### 3. range 决策：不可表达 → 记录发布扩展（不伪造）
- `ArkUI_AccessibleRangeInfo` 需要 min/max/current 三值；`ohos_host_accessibility_node`/`get` 都没有值字段，
  且托管 `RoleOf` 连 `IProgress` → "progress" 都没映射（只有 slider）。填默认 0/100/0 会把任意位置的滑块
  报成"0/100"，属于伪造 → **本轮不调用 `SetRangeInfo`**（构建后 `llvm-nm -D` 验证：`SetEditable`/`SetCheckable`
  已引用，`SetChecked`/`SetRangeInfo` 未引用）。
- 需要的发布扩展（精确签名；一次补齐 hint 错位 + 勾选值 + 范围值）：
  ```c
  int ohos_host_accessibility_node(int id, int parent_id, const char* role, const char* text,
                                   const char* description, const char* hint,
                                   float x, float y, float width, float height,
                                   int flags, int actions,
                                   double range_min, double range_max, double range_current,
                                   int checked);
  ```
  读取侧相应扩为：
  ```c
  int ohos_host_accessibility_get(int index, int* id, int* parent_id, const char** role,
                                  const char** text, const char** description, const char** hint,
                                  float* x, float* y, float* width, float* height,
                                  int* flags, int* actions,
                                  double* range_min, double* range_max, double* range_current,
                                  int* checked);
  ```
  约定：`hint` 可为 NULL；仅当 `range_min <= range_max`（且非 NaN）时范围有效，host 侧才调用 `SetRangeInfo`
  （slider/progress）；`checked` -1 = 未知/不适用，0/1 时调用 `SetChecked`（`SetCheckable` 仍由角色派生）。
  托管侧配套（本轮未动）：记录增加值字段（`ISlider.Minimum/Maximum/Value`、`ICheckBox.IsChecked`、
  `ISwitch.IsToggled`）、`RoleOf` 增加 `IProgress`→"progress"、`Publish` 按序追加参数；**pack 版本必须成对递增**
  （旧托管 + 新宿主会把未初始化寄存器当 range/checked 读）。

### 4. ★ 既有契约错位（本轮实测发现；宿主侧无法修，托管/C 均超出本文件所有权）
- **现象**：托管 `DllImport AccessibilityNode(...)` 声明 **12** 个参数（第 6 个是 `hint`），而
  `ohos_host_accessibility_node` 定义只有 **11** 个（`description` 后直接是 `x`，没有 hint）。AAPCS64 下整数/
  指针与浮点寄存器分开编号：被调方第 10 个参数 `flags` 实际读到 **hint 指针**，第 11 个 `actions` 读到
  **托管发布的 flags**，真正的 actions 被丢弃。
- **后果（真机现存）**：节点表 `flags` = 指针低位、（本应 0..3 的）`actions` = flags ∈ {0,1,2,3}。于是
  `SetEnabled`/`SetFocusable` 随机、`SetClickable` 恒 false、操作动作列表恒空；R2 之前的 `findFocused`/
  `findNextFocus` 依赖的 `flags & 2` 同样是随机的。R2 的 editable/checkable 按角色派生、不受影响；方向焦点
  在**表按正确形状填充时**可用（47 项原生断言），真机上要等错位修复后才生效。
- **实测证据**：scratch 原生测试用真实 .NET marshaller 以 12 参形状调用 11 参实现对端，发布
  `(flags=3, actions=0x10)` 后对端收到 `flags=68151328`（hint 指针低位，随分配变化）、`actions=3`；同一 TU
  用真实 11 参形状填表则落位正确（`flags=3, actions=0x10`）。
- **修法二选一**（建议与 §3 扩展一次完成）：
  (a) 托管：`AccessibilityNode` 去掉 `hint` 形参（最小改动，flags/actions 立即对齐，hint 继续不送达宿主）；
  (b) C：按 §3 签名把 `hint` 补为第 6 参并存入节点（`OhosAccessibilityNode` + `get` 出参同步），
      宿主侧顺带补 `SetHintText`。

### 验证
- 宿主 `bash scripts/build-host.sh` → **`selfsign ok`**（仅既有 C-as-C++ 警告）。
- 原生自测（scratch，**不入库**）：从 `host_napi.cpp` 抽取真实无障碍代码块 + 真实 `openharmony_host.c` 节点表，
  ArkUI setter 打桩后在真机（aarch64 HarmonyOS）运行 → **47/47 通过**（方向几何/回绕/边界/状态派生/既有查询回归
  + §4 错位实证）；自签后执行（未签 ELF 被设备拒绝，用 `scripts/selfsign.sh`）。
- 托管 harness（自建 scratch 副本，`-m:1`）：exit 0，**195 `[verify]` / 0 `Unhandled` / 0 `assert=False`**
  （未改托管，与基线一致）；副本含 bin/obj 已删。
- 未跑 demo 发布、未做 release 刷新（按要求）。

### 不确定项
- **真机无屏幕阅读器实测**：几何启发式只有原生仿真证据；中心点比较在重叠/包裹元素上的取舍需真机手感确认。
- RTL 下 LEFT/RIGHT 仍是物理方向（非逻辑读向）；`elementId <= 0` 以索引 0 为根是约定（托管发布先根），
  未见框架文档明确。
- §4 修复前，真机上的焦点与动作结果不可信；editable/checkable 不受影响。
- `1px` 前沿阈值、`2:1` 垂直惩罚、平局规则都是启发式，集中在 `kA11yFocus*` 常数，可按真机调整。

## 30. 无障碍发布契约 R2b：16 参统一 · range/checked · 漂移断言（host + 托管 + harness，2026-09-20）

### 修复的缺陷（真机证据）
- 托管 DllImport 声明 12 参（`hint` 第 6 个），`ohos_host_accessibility_node` 定义只有 11 参（无 `hint`）。
  AAPCS64 下整数/指针与浮点寄存器分开编号，被调方第 10 参 `flags` 实际读到 `hint` 指针、第 11 参 `actions`
  读到托管的 flags：发布 `(flags=3, actions=0x10)` 到达节点表为 `(flags=68151328, actions=3)`（§29 §4 实测）。
- 后果：真机上 enabled/focusable/clickable 与操作动作列表全部错乱；R2 的方向焦点依赖 `flags & 2`，同样不可用。
- 修法采用 §29 的方案 (b)：C 侧一次补齐 `hint` + range/checked，托管与宿主同批更新，签名只动一次。

### 统一契约（16 参，单一声明源）
- `openharmony_host.h` 新增完整声明（`begin`/`node`/`commit`/`count`/`get`/`set_action_listener`/`send_event`/
  `provider_status`）；`openharmony_host.c` 与 `host_napi.cpp` 都包含该头 → C↔C++ 在编译期锁定，不再可能静默漂移。
  ```c
  int ohos_host_accessibility_node(int id, int parent_id, const char* role, const char* text,
                                   const char* description, const char* hint,
                                   float x, float y, float width, float height,
                                   int flags, int actions,
                                   double range_min, double range_max, double range_current,
                                   int checked);
  int ohos_host_accessibility_get(int index, int* id, int* parent_id, const char** role,
                                  const char** text, const char** description, const char** hint,
                                  float* x, float* y, float* width, float* height,
                                  int* flags, int* actions,
                                  double* range_min, double* range_max, double* range_current,
                                  int* checked);
  ```
- 节点结构新增 `hint` / `range_min` / `range_max` / `range_current` / `checked`，`free` 覆盖 `hint`；`get` 出参同步。
- 约定（头文件与 .c 都写明"参数顺序即契约"）：`hint` 可为 NULL；range 仅当 `range_min <= range_max` 时有效
  （NaN 比较为 false）；`checked` -1 = 未知/不适用，0/1 有效。

### 托管发布（每帧、无分配）
- slider：`Minimum/Maximum/Value`；progress（`RoleOf` 新增 `IProgress` → `"progress"`）：`0/1/Progress`
  （`IProgress.Progress` 本身就是 0..1 分数，不放大到 0..100）。
- 其他角色 range 记为 `NaN/NaN`（宿主 `min <= max` 永不成立）；`checked`：`ISwitch.IsOn` / `ICheckBox.IsChecked`
  → 1/0，其余 -1；`hint` 继续发布 `SemanticProperties.GetHint`。
- `DiffFrames` 增加 hint（文本事件）与 range/checked（0x20 状态事件）比较；NaN 用 `double.Equals`（NaN 等于 NaN），
  避免"无 range"被当成每帧变化。必要性：拖动 slider 不改文本/矩形，不比较 range 则宿主永远收不到新值。

### 宿主填充（host_napi.cpp）
- 读取统一走 `A11yNodeRecord` + `A11yReadNode`；列表查询与单节点回调共用 `A11yFillElement`，删除两份重复填充，
  避免两条路径再次分叉。
- `SetHintText`（hint 非空）、`SetRangeInfo`（仅 slider/progress 且 `min <= max`）、`SetChecked`（仅 0/1）；
  R2 的 `SetEditable`/`SetCheckable` 保留。
- `llvm-nm -D` 复核：`SetRangeInfo`/`SetChecked`/`SetHintText`/`SetEditable`/`SetCheckable` 均已引用，
  `ohos_host_accessibility_*` 8 个导出仍在。

### harness 漂移断言（本类问题不再上设备才发现）
- 反射托管 `AccessibilityNode`（16 参）并解析 `openharmony_host.c` 的 node 定义、`openharmony_host.h` 的声明：
  比较参数个数、归一化名字（`parent_id` ↔ `parentId`）、类型种类（`int/float/double/const char*` ↔
  `int/float/double/string`）与每个 string 形参的 `LPUTF8Str` marshalling；`get` 断言为 17 参。
- 负向验证（scratch，不入库）：把源码副本的 `hint` 形参删掉后断言报 `nativeArgs=15 / assert=False` 且 harness
  非零退出，证明断言非空转。
- 值映射断言：slider `-5/15/7.5`、progress `0/1/0.25`、switch `1`、checkBox `0`、label 无 range/checked；
  滑块值变化（文本/矩形不变）触发 0x20 状态事件，无变化帧保持 0。

### 验证
- 宿主 `bash scripts/build-host.sh` → **selfsign ok**（仅既有 C-as-C++ 警告）；导出/引用复核如上。
- 托管 harness（自建 scratch 副本，`-m:1`）：exit 0，**199 `[verify]` / 0 `Unhandled` / 新断言 assert=True**
  （基线 195 + 4 项 R2b）；`test/maui-platform-verify/README.md` 与 CI 门槛同步更新为 >=195。
- 未跑 demo 发布、未做 release 刷新（按要求）。

### 不确定项
- **真机只实证过错位症状**：修复后的整体行为（读屏播报 hint/range/checked 的措辞、ArkUI 对 `0..1` progress range
  的呈现、`SetChecked` 对 switch/checkBox 的读法）仍需真机 + 屏幕阅读器确认。
- 托管切片的独立 `dotnet build` 在本机 partial checkout 因缺 `eng/AndroidX.targets` 不可用（与 §29 相同的既有
  环境限制）；托管编译由 harness（直接编译 slice 源）覆盖，未改变任何工程文件。
- **托管与宿主必须成对发布**：旧托管 + 新宿主仍会把未初始化寄存器/哨兵当 range/checked 读；本轮按要求未发布、
  未刷新 pack 版本（版本配对留给发布轮次）。

## 31. R3 残留（仅文档）：DevEco CLT 盘点 · hvigor 解析复核（2026-09-20）

R3（设备/工具链探索轮次）在产出代码前被取消，**未做任何代码改动**；本节是该轮次唯一、也是全部的
文档残留，供后续轮次复用。结论先行：`build-arkts-shell.sh` 现有的 hvigor file-mirror 解析保持不变；
CLT 目前只能贡献 `hdc` 二进制，`devecocli` 的设备能力在本机被策略拦截。

### CLT 安装事实（`/storage/Users/currentUser/ohos-clt`）
| 项 | 实测 |
|---|---|
| 版本 | `version.txt` = `# Version: 26.0.0.999` |
| 提供 | `sdk/default/openharmony/toolchains/hdc`（arm64/musl ELF，可执行）；`tool/node/` 目录存在 |
| 不提供 | 无 `hvigor/`、无 `hvigorw`、无 `ohpm/bin/pm-cli.js`；`tool/node/bin/` 在本机为空（无 node 可执行文件） |
| 对 devecocli 的含义 | 其 CLT 约定路径 `<root>/hvigor/bin/hvigorw.js`、`<root>/ohpm/bin/pm-cli.js`、`<root>/tool/node/bin/node` 均不存在 → CLT 无法驱动 hvigor 构建 |

### hvigor 解析复核（`scripts/build-arkts-shell.sh`）
- 现行路径（脚本 §1/§2/§4）：从 `HVIGOR_MIRROR`（默认 `https://repo.harmonyos.com/npm`）下载
  `@ohos/hvigor`、`@ohos/hvigor-ohos-plugin` 到 `.arkts-build/hvigor/node_modules`（file mirror），
  再以 `.arkts-build/sdk/<platformVersion>/` 符号链接出 hvigor 要求的 `<sdkRoot>/<platformVersion>/<component>`
  布局，最后 `node hvigor.js assembleHap`。
- 因 CLT 没有 hvigor/hvigorw（上表），该 file mirror **仍是唯一可用且已验证的 hvigor 解析路径**；
  本轮不修改任何构建脚本。

### devecocli（`DEVECO_CLI_CLT_PATH`）
- 入口 `/storage/Users/currentUser/npm/bin/devecocli` v1.3.3；`DEVECO_CLI_CLT_PATH=/storage/Users/currentUser/ohos-clt`
  时按 CLT 模式解析。`--help` 列出的相关子命令：`build`/`run`/`device`/`emulator`/`log`/`auth`
  （另有 `ui`/`check`/`signature`/`skills`/`init`/`serve`/`docs`/`create`/`update`）。
- 设备访问被策略拦截：`devecocli device list` 输出
  `[E00C001]Operation restricted by the organization.`，无法枚举/操作设备。因此 `run`/`ui`/`log`
  等依赖设备（或 hvigor）的子命令在本环境不可用；`hdc` 二进制本身也未经真机验证。

### 验证与不确定项
- 上述事实来自本机直接检查：`version.txt`、`ls`/`find` 目录清单、`file hdc`、`devecocli --help`、
  `devecocli device list`；未改动任何仓库文件。R4（本轮）同样未改 runtime/slice/host，交互套件
  scratch 副本以 `-m:1` 复核为 **199 `[verify]` / 0 `Unhandled`**（与 §30 基线一致）。
- 不确定项：`tool/node/bin` 为空可能是本机解包不完整（官方 CLT 可能随附 node），但 hvigor/ohpm 缺失是
  目录级事实，不依赖该假设；`E00C001` 是本机组织策略的提示，可能随策略放开而改变；CLT 的 `hdc`
  未对真机执行过任何命令（设备访问被拦截）。

## 32. 上游门控收尾项：三分支/补丁预备（R7，2026-09-20）

把此前记为「等上游合并后再做」的三项收尾各自做成**单关注点分支**，推送到 runtime fork
（`origin` = `springmin/runtime-ohos`），并导出 patch 副本。**本轮无任何上游交互**：未向
dotnet/runtime 发评论、未开 PR、未 push `upstream`；#132953 / #132827 的两条无 @ 评论文案
仍按用户要求**保持未发**。

### 32.1 找到的条目（改前记录，含判定）

| # | 位置 | 改前代码/事实 | 上游门控 | 依据文档 |
|---|---|---|---|---|
| 1 | `eng/native/configurecompiler.cmake`（`pr/ohos-infra`，`CLR_CMAKE_HOST_OPENHARMONY` 块 666-667 行） | `add_compile_options(-fno-emulated-tls)` 后跟 `add_compile_options(-ftls-model=global-dynamic)` | dotnet/runtime **#132953**（该文件就是 PR 内容） | `2026-09-07-ohos-pr-plan-bsd-haiku-model.md` §6.1（OHOS NDK clang 15.0.4 实测：带/不带该 flag 生成码逐字节相同）；`2026-09-17-ohos-workload-w10-status.md:28` |
| 2 | `src/libraries/Directory.Build.props:14-19` + `src/libraries/shims/Directory.Build.props:7-8` | `LibrariesOpenHarmonySfxTfm = $(NetCoreAppCurrent)-linux` 与 `LibrariesOpenHarmonyShimsTfm = $(NetCoreAppCurrent)-unix` 两套映射 | **#132953**（前置）+ N15 `pr/ohos-libs-tfm` 的 #132866 评审 | `2026-09-02-cxx-runtime-handoff.md` round-14d（1105-1112）与「Remaining TODO」（1140-1143）；`2026-09-17-ohos-workload-w10-status.md:28-29` |
| 3 | `src/tools/illink/src/ILLink.Tasks/build/Microsoft.NET.ILLink.targets:59-60`（仅 `feature/openharmony`） | openharmony RID 的 `_UseManagedNtlm=true`（与 linux-bionic 同形） | **没有 PR**；tools/ 归属待评审（#132866 开放问题） | `2026-09-03-ohos-pr-inclusion-audit.md` 开放项 3；`2026-09-07-ohos-pr-plan-bsd-haiku-model.md`（illink held out，§5 第 2 问） |

判定：
- 条目 1 是**实测 no-op** 的冗余 flag：删除是一行，保留 `-fno-emulated-tls`（TLS 模型必须各 TU 一致，
  `initial-exec` 不可用）。#132953 合并后独立提交，或在该 PR 评审回复中顺手删除。
- 条目 2 是**会实际破坏布局的 workaround**：shims 编译 `net11.0-unix`，而共享框架遍历用
  `net11.0-linux`，`sfx-src` 的 `OmitIncompatibleProjectReferences` 把全部 60 个 facade 判为不兼容并
  滤掉（round-14d 只能手工编译+拷贝）。真修法 = shims 与 libs 同一 TFM 组（linux）；压缩/Brotli 等
  unix-only 引用从 linux 消费者解析的机制已在 `2aff77173c2`（共享框架）验证过。
- 条目 3 确认**不存在 PR**：该 hunk 只在 `feature/openharmony`；逐个 `pr/ohos-*` 分支与 `main` 比 diff
  均不含它。按「独立 tools PR」的候选形态隔离成单文件分支，但提交时机仍取决于上游对 tools/ 归属的答复。

### 32.2 预备产物（分支已推送 + patch 副本）

| 分支 | 基线 | commit | 文件 | 改动 |
|---|---|---|---|---|
| `pr/ohos-tls-flag-cleanup` | `pr/ohos-infra` `cece42439a1` | `f9dffc0cd78` | 1 | 删 `-ftls-model=global-dynamic`，注释改为「-fno-emulated-tls 下模型已是 global-dynamic(TLSDESC)，无需显式 flag」；commit message 写明 #132953 依赖与 Haiku 先例 |
| `pr/ohos-shims-tfm-cleanup` | `pr/ohos-libs-tfm`（N15 栈顶）`01667c2c6d5` | `1157f1daf5c` | 2 | 删 `LibrariesOpenHarmonyShimsTfm`；shims 改用 `LibrariesOpenHarmonySfxTfm`（linux 组），注释解释兼容性过滤 |
| `pr/ohos-illink-ntlm` | `main` `719009acffb` | `f8495f47ae3` | 1 | 加 openharmony `_UseManagedNtlm=true`；commit message 写明 tools/ 归属待 #132866 |

patch 副本（`git format-patch` 导出，与分支 commit 逐字节一致，可直接 `git am`）：
- `docs/plans/patches/pr-ohos-tls-flag-cleanup.patch`
- `docs/plans/patches/pr-ohos-shims-tfm-cleanup.patch`
- `docs/plans/patches/pr-ohos-illink-ntlm.patch`

### 32.3 验证（本轮实际能做的）

- 三分支 `git diff --check` 全部干净；`xmllint --noout` 通过（两个 `.props` + 一个 `.targets`）。
- 回读改动上下文确认语法/注释；全仓 grep 确认 `LibrariesOpenHarmonyShimsTfm` 无残留引用。
- `pr/ohos-illink-ntlm` 的单文件 diff blob（`e3788a15793`）与 `feature/openharmony` 中 held-out 的
  hunk 相同 —— 隔离改动不是重写猜测。
- **无构建**：checkout 内没有 `.dotnet/` 也没有 `artifacts/`（未 bootstrap SDK），OHOS 交叉编译还需要
  NDK/rootfs；按本轮要求不做重型构建。因此条目 2 的 TFM 解析（shims 在 linux 组、Compression 的 unix
  引用可解析）**未在构建层验证**，仅沿用既有实测结论 + 代码推理。
- 远端核对：`git ls-remote origin` 三个 ref SHA 与本地一致。

### 32.4 推送与剩余

- 推送规则：`git -c http.version=HTTP/1.1 push origin <branch>`，6 次×15s，**从未 force**。
  - `pr/ohos-tls-flag-cleanup`、`pr/ohos-shims-tfm-cleanup`、`pr/ohos-illink-ntlm` 均**第 1 次即成功**
    （此前 HTTPS 探测短暂超时，重试脚本按规则兜底；全程未 force）。
  - 本 commit（§32 文档）按同一规则推送 `feature/openharmony`。
- 剩余（提交顺序）：
  1. #132953 合并后：删 TLS flag（条目 1）；N15（`pr/ohos-libs-tfm`）评审时决定 shims 对齐是并入该
     PR 还是紧随其后（条目 2；属性命名/shape 可能按 reviewer 意见调整）。
  2. #132866 答复 tools/ 归属后：`pr/ohos-illink-ntlm` 作为独立 tools PR，或并入 NativeAOT PR（条目 3）。
  3. 两条上游评论文案（#132953/#132827）已按用户指示于 **2026-09-21** 发出
     （#132953 `#issuecomment-5757951166`、#132827 `#issuecomment-5757951615`）。

## 33. S3 手电筒（Camera Kit torch）跨三仓（2026-09-21）

把 MAUI Essentials 的 `IFlashlight` 接到 OpenHarmony Camera Kit（`@ohos.multimedia.camera`，
也可经 `@kit.CameraKit` 的 `camera` 重导出）。三仓各一个提交：workload（壳 + host）、
maui-ohos（托管实现）、runtime-ohos（本文档）。

### 33.1 探针（先探针后写码）

先读 SDK d.ts（`ets/api/@ohos.multimedia.camera.d.ts`，API 26/26.0.0.18 波段），再把临时
torch 片段放进整页、以真实编译器探针（`typeCheck: true` 跑 hvigor）。结果：

| 成员 | 结果 |
|---|---|
| `camera.getCameraManager(getContext(this))` → `camera.CameraManager` | 编译通过（仅 "Function may throw exceptions" / "getContext deprecated" 警告，与既有页面同级） |
| `CameraManager.isTorchSupported(): boolean` | 编译通过 |
| `CameraManager.getTorchMode(): camera.TorchMode` | 编译通过 |
| `CameraManager.isTorchModeSupported(mode: TorchMode): boolean` | 编译通过 |
| `CameraManager.setTorchMode(mode: TorchMode): void`，`camera.TorchMode.ON`(1)/`OFF`(0)（另有 `AUTO`=2） | 编译通过（同上警告） |
| `CameraManager.on('torchStatusChange', cb)` | **只有双参 `AsyncCallback` 形态 `(err: BusinessError, info: TorchStatusInfo)` 能编译**；单参 `(info: TorchStatusInfo)` 报 `No overload matches this call`（本切片不订阅） |
| `camera.TorchStatusInfo.isTorchAvailable/isTorchActive/torchLevel`（只读） | 在上述双参回调里编译通过 |

torch 成员在 d.ts 上**没有** `@permission`（只有创建输入/会话的成员标
`ohos.permission.CAMERA`），ArkTS 检查器也未对手电筒调用输出权限告警，因此该功能不需要
清单权限声明。

### 33.2 桥与托管映射

- **host**（`src/OpenHarmonyHost/host_napi.cpp`）：新导出 `ohos_host_flashlight_set(int on)`。
  它用 `napi_call_function` 直调壳回调，与 ability sink 同形——托管侧要消费布尔答案，而
  `napi_threadsafe_function` 只能报告"已入队"。返回 `0` = 壳答 true；`-1` = 没有已注册的
  sink、调用失败或壳答 false。壳通过 `host.registerFlashlightSink(fn)` 注册。
- **壳**（`packs/.../templates/ets/pages/Index.ets`，preview.22 与 preview.23 逐字节一致）：
  `on` 为 0=关、1=开、2=支持探测（只跑 `isTorchSupported()`，不碰手电筒）。首次使用时
  `camera.getCameraManager(getContext(this))` 并缓存 manager；`setTorchMode` 是同步调用、会抛
  （7400102 不允许 / 7400201 服务致命），无 torch、无 kit、shell 无相机或调用异常一律答 false，
  且丢弃缓存的 manager 以便下次重试。布尔只表示"kit 接受了请求"，不是 LED 的点亮确认。
- **托管**（新文件 `OpenHarmonyFlashlight.cs`，未改其他切片文件）：`IFlashlight` 的真实形态
  用反射从 `Microsoft.Maui.Essentials` 程序集读出——`Task<bool> IsSupportedAsync()`、
  `Task TurnOnAsync()`、`Task TurnOffAsync()`（该波段不是常见文档写法的 `bool IsSupported`
  属性）。`IsSupportedAsync` 走 op 2 探测；开/关走 op 1/0。`Flashlight.Default` 由
  `[ModuleInitializer]` + 字段反射安装（get-only 入口的背衬字段 `Flashlight.defaultImplementation`，
  与 haptics/battery/TTS/sensors 同模式）。所有原生调用有 guard：`DllNotFoundException` /
  `EntryPointNotFoundException` 一次性把桥标记为不可用并让 `IsSupportedAsync` 之后恒 false；
  开/关只写一行 `OpenHarmonyBridge` 状态并以 no-op 完成，**不抛**——这是与参考平台
  （TurnOn/TurnOffAsync 抛 `FeatureNotSupportedException`）的有意差异，为的是让离机/无相机
  调用方得到诚实的降级而不是异常。

### 33.3 验证（本轮实际执行）

- host：`bash scripts/build-host.sh` → `selfsign ok`；`llvm-nm -D` 可见
  `T ohos_host_flashlight_set`。
- 壳：`TYPECHECK=1 HVIGOR_MIRROR=file:///data/storage/el2/base/tmp/opencode/npm-mirror \
  bash scripts/build-arkts-shell.sh` → **0 条 `ArkTS:ERROR`**（hvigor 日志
  `TYPE CHECK SUCCESSFUL` + `Finished :entry:default@CompileArkTS`；仅 PackageHap 因本机
  无 java 失败，脚本按既定规则忽略）。新的 `dist/ets/modules.abc` = **79416 字节**（旧的
  模板/发布体为 78060 字节；本轮按要求未把它复制进 pack）。
- harness：把 `test/maui-platform-verify` 复制到 scratch，加 3 条断言（默认实现是
  `OpenHarmonyFlashlight`、`IsSupportedAsync`=false、`TurnOnAsync`/`TurnOffAsync` 不抛），
  `-m:1 -p:UseSharedCompilation=false` 构建后运行：**203 条 `[verify]`、0 条 Unhandled**、
  perf `within=True`；scratch 副本已删除，仓库内 harness 未改。
- 两份 pack 模板 `cmp` 逐字节一致；模板之外的 `.arkts-build` 构建状态已还原，未进提交。

### 33.4 提交与推送

| 仓 / 分支 | commit | 内容 |
|---|---|---|
| ohos-workload `master` | `a8f6456`（`a8f64569580308cb32553776b7a3986551789a3e`） | 壳 preview.22/23 + host 导出/注册 |
| maui-ohos `feature/openharmony` | `f95bc801`（`f95bc801eb1b78bbd18af59393355348f770e555`） | 新增 `OpenHarmonyFlashlight.cs` |
| runtime-ohos `feature/openharmony` | 本 commit（§33） | 本文档 |

推送规则：`git -c http.version=HTTP/1.1 push origin <branch>`，6 次×15s 兜底；两个分支
**第 1 次即成功**，未 force；`git ls-remote` 复核远端 SHA 与本地一致，推送前 `git fetch` 确认
远端是本地祖先（fast-forward）。host 的 `.so` 与 `dist/modules.abc` 是忽略/未跟踪产物，未进
提交；本轮无 release refresh、无 demo publish。

### 33.5 真机前不确定项

1. **未在真机验证**：camera 服务是否接受从 host 回调线程（托管 .NET 线程）发起的
   `getCameraManager`/`setTorchMode`。该直调沿用 ability sink 的既有形态，本轮只到类型检查 +
   离机 harness。
2. 真机 LED 是否点亮、`setTorchMode` "被接受"到实际点亮之间的时延；`torchStatusChange`
   事件本切片未订阅（其双参回调形态已在探针中确认可编译，后续可加）。
3. 壳 sink 注册前（页面 `aboutToAppear` 之前）调用 `IsSupportedAsync` 会瞬时答 false；代码
   只在缺失库/导出时缓存不可用，sink 注册后仍会重新探测。
4. 无 torch、相机被占用（7400102）、服务重启（7400201）在托管侧都归一为 false + 一条状态
   日志，调用方无法区分具体原因。


## 34. S4 分享文件（ShareFileRequest）跨三仓：sendData Want + FLAG_AUTH_READ_URI_PERMISSION（2026-09-21）

### 34.1 探针（先探针后写码）

- SDK（`$HOME/.harmonybrew/opt/ohos-sdk/ets/api`，本机解析到
  `/storage/Users/currentUser/.harmonybrew/opt/ohos-sdk/`）实际声明：
  - `@ohos.app.ability.Want`（default class）有 `uri?: string`、`type?: string`、`flags?: number`、
    `action?: string`、`parameters?: Record<string, Object>`；`type` 的文档自 API 18 起出现，本 SDK 可写。
  - `@ohos.app.ability.wantConstant` 的 `Flags.FLAG_AUTH_READ_URI_PERMISSION = 0x00000001`
    （旧模块 `@ohos.ability.wantConstant` 同值但标 `@useinstead` 指向新模块）。
  - `@ohos.file.fileuri` 有 `getUriFromPath(path)`（app sandbox path → file uri），本轮**未使用**（见 34.5）。
  - 本 SDK 仍无 Share Kit（`systemShare`）；Want 只有单个 `uri` 槽，多文件没有载体。
- 探针方式：把形状直接写进 pack 模板再跑官方工具链，而不是猜。`import wantConstant from
  '@ohos.app.ability.wantConstant'` + `new Want()` + `want.flags =
  wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION` 编译通过：`TYPECHECK=1` → **0 条
  `ArkTS:ERROR`**、hvigor 日志 `TYPE CHECK SUCCESSFUL`、`Finished :entry:default@CompileArkTS`；
  新的 `dist/ets/modules.abc` = **79676 字节**（S3 为 79416）。
- 结论（实际编译过的文件分享形状）：`new Want()` + `action='ohos.want.action.sendData'` +
  `uri=<file:// URI>` + `type=<MIME>` + `flags=FLAG_AUTH_READ_URI_PERMISSION`。不用 viewData：
  viewData 是既有 kind 0 的"打开文件"语义，分享是 sendData。

### 34.2 桥与派发（kind 3；host 未改）

- **壳**（`packs/.../templates/ets/pages/Index.ets`，preview.22/23 逐字节一致）：新增
  `kind === 3` 分支——`uri` 槽 = file:// URI，`text` 槽 = MIME type（两者都由托管侧准备），
  `flags` 用上述常量；kind 0/1/2 的代码与行为原样保留，文本路径零变化。
- **host**（`src/OpenHarmonyHost/host_napi.cpp`）：**未改、未重编**。`ohos_host_ability_start(kind,
  uri, text)` 对 kind 是不透明透传（只有壳解释 kind），不需要第 4 个参数或新导出。
- **托管**（`src/Core/src/Platform/OpenHarmony/OpenHarmonyAppLauncher.cs`，未新增文件）：
  - `KindShareFile = 3` + `TryShareFile(fileUri, mime)` → 复用同一条 `Dispatch` guard
    （`DllNotFoundException` / `EntryPointNotFoundException` 一次性把桥标记不可用并降级 false，不抛）。
  - `Share.RequestAsync(ShareFileRequest)`：`File.FullPath` → `FileUriForPath`（`"file://"` + 绝对
    路径，`/data/...` → `file:///data/...`；已带 scheme 的原样通过）+ `MimeTypeForPath`（扩展名小写后
    查表），调用桥；无论派发成功与否都返回 `Task.CompletedTask`，失败只写一行
    `OpenHarmonyBridge.WriteStatus`——与文本路径完全一致。
  - `Share.RequestAsync(ShareMultipleFilesRequest)`：**恰 1 个文件**时走同一条派发；0 个或 >1 个
    保持 no-op + 状态行（一个 Want 只带一个 uri，多文件载体是缺失的 Share Kit），不静默地只分享第一个。
- **MIME 映射**（20 个扩展名，其余 `*/*`）：txt/log→text/plain，csv→text/csv，html/htm→text/html，
  json→application/json，xml→application/xml，pdf→application/pdf，png→image/png，
  jpg/jpeg→image/jpeg，gif→image/gif，webp→image/webp，mp3→audio/mpeg，wav→audio/wav，
  mp4→video/mp4，zip→application/zip，doc→application/msword，
  docx→…wordprocessingml.document，xls→application/vnd.ms-excel，xlsx→…spreadsheetml.sheet，
  ppt→application/vnd.ms-powerpoint，pptx→…presentationml.presentation。

### 34.3 验证（本轮实际执行）

- 壳：`TYPECHECK=1 HVIGOR_MIRROR=file:///data/storage/el2/base/tmp/opencode/npm-mirror   bash scripts/build-arkts-shell.sh` → **0 条 `ArkTS:ERROR`**（`TYPE CHECK SUCCESSFUL`；仅
  PackageHap 因本机无 java 失败，脚本按既定规则忽略）。新 `dist/ets/modules.abc` = 79676 字节，
  按要求未复制进 pack、未做 demo publish / release refresh；模板构建状态 `.arkts-build` 未进提交。
- host：未改，未重编（无新导出）。
- harness：把 `test/maui-platform-verify` 复制到 scratch，加 3 条断言（MIME map 的
  pdf/png/未知扩展名、`file://` URI 形状、单文件与多文件 `ShareFileRequest` 离机派发不抛），
  `-m:1 -p:UseSharedCompilation=false -p:UseMSBuildServer=false` 构建（0 error；首次触发
  CA1307 指向 `StartsWith('/')`，改为 `StartsWith("/", StringComparison.Ordinal)` 后过）并运行：
  **203 条 `[verify]`、0 条 `Unhandled`**、exit 0、perf `within=True`；scratch 副本已删除，
  仓库内 harness 未改。

### 34.4 提交与推送

| 仓 / 分支 | commit | 内容 |
|---|---|---|
| ohos-workload `master` | `437cf52`（`437cf52b3a87fa00183990b92baf8907ee8006ac`） | 壳 preview.22/23：kind 3 + `wantConstant` 导入/注释 |
| maui-ohos `feature/openharmony` | `0a88b8a1`（`0a88b8a1ced13c1718a6122b556d46bfdd870f10`） | `OpenHarmonyAppLauncher.cs`：kind 3 桥 + 文件派发 + MIME/URI 映射 |
| runtime-ohos `feature/openharmony` | 本 commit（§34） | 本文档 |

推送规则：`git -c http.version=HTTP/1.1 push origin <branch>`，6 次 × 15s 兜底，失败则
fetch+rebase（不 force）。推送前已复核：三仓本地 HEAD 都是远端分支 tip 的后代
（fast-forward）；其中 maui-ohos 的 `origin/feature/openharmony` remote-tracking ref 因
fetch refspec 只含 main 而陈旧，`git ls-remote` 复核实际远端为 `f95bc801`，本地提交在其之上。

### 34.5 真机前不确定项

1. **接收方能否读到文件**：壳已设 `FLAG_AUTH_READ_URI_PERMISSION`，但托管侧发的是
   `file://` + sandbox 绝对路径（`file:///data/storage/...`）。`fileUri.getUriFromPath` 的
   bundle-qualified 形式没有用——托管侧不知道 bundleName；若目标应用/ability 管理器要求带
   bundle 前缀或 content URI，接收方会打不开。属设备验证项。
2. **隐式 sendData Want 的匹配**：聊天/邮件类应用是否需要额外的 `entities`/`parameters`
   （如 `ohos.extra.param.key.content` 只对文本路径设置）才能出现在选择器里，离机不可见；
   目标应用也可能按 `type` 过滤。
3. `type` 按扩展名映射，与真实内容不符时可能匹配不到 activity；未读取
   `ShareFile.ContentType`（`ShareFile(path, contentType)` 的显式值），一律以扩展名为准，
   未知扩展名用 `*/*`（选择器会变宽）。
4. 多文件（>1）仍是 no-op；若后续要真支持，需要 Share Kit 或逐个 uri 的多次派发语义，
   本轮明确不做。

---

## 35. S 系列收官：S1 Blazor 管理器 · S2 无障碍节点数/分组层级 · S3 手电筒 · S4 文件分享 · S5 preview.24 刷新（2026-09-21）

S1–S4 的能力改动分散在三个仓库（见 35.1），S5 把它们随 **workload 1.0.0-preview.24** 打包重发，并更新交付 kit
与文档。本节记录提交、产物与真机前不确定项。

### 35.1 S 系列提交总览

| 批次 | 仓库 / 分支 | commit | 内容 |
|---|---|---|---|
| S1 | maui-ohos `feature/openharmony` | `1b4509a7` | BlazorWebView 里程碑 2b：`OpenHarmonyWebViewManager` 实例化、root components 绑定、`UsePlatformHandler` 注册入口 |
| S2 | ohos-workload `master` | `72e7034` | `ohos_host_accessibility_node_count`（C/NAPI/头文件）+ 元素信息 `SetAccessibilityGroup(true)`/`SetAccessibilityLevel`（host-only，harness 未改） |
| S3 | ohos-workload `master` | `a8f6456` | 壳 `registerFlashlightSink`（Camera Kit torch，0=关/1=开/2=探测）+ host 导出 `ohos_host_flashlight_set` |
| S3 | maui-ohos `feature/openharmony` | `f95bc801` | Essentials `IFlashlight` 映射到该桥 |
| S4 | ohos-workload `master` | `437cf52` | 壳 kind 3：隐式 `sendData` Want + `FLAG_AUTH_READ_URI_PERMISSION`（preview.22/23 模板一致） |
| S4 | maui-ohos `feature/openharmony` | `0a88b8a1` | `Share.RequestAsync(ShareFileRequest/ShareMultipleFilesRequest)`、MIME 表、`file://` URI |
| S4 | runtime-ohos `feature/openharmony` | `8ab824a92d8` | 审计 §34（含 4 项真机前不确定项） |
| S5 | ohos-workload `master` | `84c184c` | preview.24 版本刷新：manifest/脚本/pack 树（Sdk+targets+ridgraph+templates，含最新壳归档）+ 演示 fixture 刷新 |
| S5 | ohos-workload `master` | `070f92f` | `publish-workload-release.sh`：新建版本化 release 时一并上传 `SHA256SUMS`（原先只在更新分支上传）|
| S5 | runtime-ohos `feature/openharmony` | 本 commit（§35） | 本节 + 文档同步（索引、验收说明、快速开始、签名指南、kit 说明）|

### 35.2 S5 版本刷新（实际执行）

1. **版本源**：`WorkloadManifest.json` 与 `scripts/{prepare-packs,build-host,build-arkts-shell}.sh` 的 `VER=` 全部
   `1.0.0-preview.23` → `1.0.0-preview.24`；`packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/` 由 `.23` 逐目录继承
   （`Sdk/`、`targets/`、`ridgraph/`、`templates/`），其中 `Sdk.targets` 与 `BundledVersions.props` 的
   `KnownFrameworkReference` 版本引用同步改为 `.24`。
2. **最新壳归档**：`dist/ets/modules.abc`（S4 typecheck 产物）**79,676** 字节、sha256
   `cce508fc245a08f79fb300019b62960e21190e386c15f71a0577b2d66ed99fca`，复制为
   `templates/ets/modules.ui.abc` 与 `modules.shell.abc`（两者逐字节相同；headless `modules.abc` 仍为 3,580 字节）。
3. **宿主**：`scripts/build-host.sh` 重编 + 自签 → **"selfsign ok"**，产物 **138,144** 字节、sha256
   `9fa7c90830c8ddbb2bbde8ce2c16e724234bb0282219e2071b6764040b70e972`（与 preview.23 的构建**逐字节相同**，说明宿主构建可复现）；
   `llvm-nm` 确认导出含 `ohos_host_accessibility_node_count`（S2）、`ohos_host_flashlight_set`（S3）与 16 参发布函数
   `ohos_host_accessibility_node`。
4. **已安装 workload**：本轮把仓库 feed（`scripts/pack-local-workload.sh`）**安装进 `~/.dotnet`**（安装器等价路径：
   manifest 复制 + `dotnet workload install openharmony --skip-manifest-update --source .feed`），`dotnet workload list`
   显示 **1.0.0-preview.24**；安装把 preview.22 的 pack 垃圾回收掉，宿主 `.so` 随 pack 一起进入 `~/.dotnet/packs/.../1.0.0-preview.24/hosts/arm64-v8a/`。
   *注*：上一轮的做法是只把 `.so` 拷进已装 pack；本轮直接升到 `.24`，否则演示 hap 的 `dotnet.zip` 会带 preview.22 的托管框架 DLL。
5. **bundle**：`dist/openharmony-workload-1.0.0-preview.24.tar.gz`，**30,325,661** 字节、sha256
   `639513dcd8242c18368cfb83a455dff8fc88d43ab62dc7f39a785a75221475ec`（`release-checksums.sh` 生成
   `dist/SHA256SUMS`，1,529 字节）；从 GitHub 下载回读的资产与本地产物 sha256 **一致**。
6. **发布**（`springmin/sdk-ohos`）：
   - 版本化 release [`workload-1.0.0-preview.24`](https://github.com/springmin/sdk-ohos/releases/tag/workload-1.0.0-preview.24)：
     `openharmony-workload-1.0.0-preview.24.tar.gz`（30,325,661）+ `SHA256SUMS`（1,529）；
   - 滚动 release [`workload-latest`](https://github.com/springmin/sdk-ohos/releases/tag/workload-latest)：
     `openharmony-workload-latest.tar.gz`（30,325,661）+ `SHA256SUMS` + `device-test-kit.tar.gz`（107,510,820）+ `.sha256`；
   - [`device-test-kit`](https://github.com/springmin/sdk-ohos/releases/tag/device-test-kit)：`device-test-kit.tar.gz`
     （107,510,820）+ `device-test-kit.tar.gz.sha256`（内容 `537153e0…`，与本地 tar 一致）。
   发布前在本地补打 `workload-1.0.0-preview.23` 标签（指向 `2e52da6`）以获得正确的提交区间；**本次 notes 由
   `scripts/release-notes.sh` 生成**（7 commits：`72e7034`/`437cf52`/`a8f6456`/`4addd43`/`20bacbb`/`84c184c`/`070f92f`，
   末尾为 "Bundle and setup" 安装段）。
7. **bundle 内容核验**：解包后的 `manifests/…/WorkloadManifest.json` = `1.0.0-preview.24`；
   `feed/Microsoft.OpenHarmony.Sdk.1.0.0-preview.24.nupkg` 内 `modules.ui.abc` = `modules.shell.abc` = 79,676（`cce508fc…`）、
   `modules.abc` = 3,580、`hosts/arm64-v8a/libopenharmonyhost.so` = 138,144（`9fa7c908…`）；`install-ohos-workload.sh --dry-run` 正常。
8. **交付 hap（5 个，`-m:1` 构建，每次 publish 均打印 `verify-app success`，`git status --short test/hello-maui-app` 保持为空）**：

| 文件 | 字节 | sha256 | 波段 | 权限 | `ets/modules.abc` | `libs/arm64-v8a/libopenharmonyhost.so` |
|---|---|---|---|---|---|---|
| `hello-maui-app.hap`（26 默认）| 21,739,782 | `498db6e9…` | `60001021`/`60101024` Beta1 | 0 | 79,676 | 138,144 |
| `hello-maui-app-permissions.hap`（26 权限）| 21,739,783 | `5fbfa6e0…` | `60001021`/`60101024` Beta1 | 5 | 79,676 | 138,144 |
| `hello-maui-app-api20.hap`（20 默认）| 21,739,781 | `70ccc70d…` | `60000020`/`60000020` Release | 0 | 79,676 | 138,144 |
| `hello-maui-app-api20-permissions.hap`（20 权限）| 21,739,780 | `ba650ddd…` | `60000020`/`60000020` Release | 5 | 79,676 | 138,144 |
| `hello-maui-app-unsigned.hap`（26 默认、未签名）| 21,706,354 | `ba16483a…` | `60001021`/`60101024` Beta1 | 0 | 79,676 | 138,144 |

   - 权限恰为 5 项：`ACCESS_BLUETOOTH` / `PRINT` / `READ_CONTACTS` / `READ_CALENDAR` / `WRITE_CALENDAR`；
   - 4 个已签包用 `hap-sign-tool verify-app` 独立复验 **success**，未签包 verify-app 失败（符合预期）；
   - `dotnet.zip` 内的托管框架 DLL 与本轮 `.24` runtime pack 的 sha256 一致（`Microsoft.OpenHarmony.dll` `4f1650a0…`、
     `Hosting.dll` `8cb302ea…`、`Maui.Graphics.dll` `4ef21cc5…`），即 hap 真的构建在 `.24` 上；
   - 顺带清理：删除了 `bin/Release/net11.0-openharmony20.0/` 下两个**上一轮遗留**的 `hello-maui-app-api20[-permissions].hap`
     （旧壳/Beta1 波段的过期副本，会污染 `SHA256SUMS`）；TFM 输出目录里现只有本轮产物。
9. **交付 kit**：`/data/storage/el2/base/tmp/opencode/device-test-kit/` → tar **107,510,820** 字节、sha256
   `537153e076af40ba78bb503e37fa97ddf958efb1961f3553a5befdadbf82d6e2`；内含 5 hap + `验收说明.md`、`快速开始.md`、
   `文档索引.md`、`签名与UDID指南.md`、`自签说明.md`、`README-交付说明.md` + `SHA256SUMS`（5 hap + 6 文档，
   `sha256sum -c` 全过）。kit 内 4 个文档是运行 `docs/plans/` 对应文件的**逐字节副本**（本轮改动已同步）。
10. **harness**：`test/maui-platform-verify` 复制到 scratch，加 8 条 S 系列断言（S5 壳/清单/脚本/宿主导出、S2 节点数与
    group/level、S3 手电筒、S4 分享、S1 Blazor 管理器），`-m:1 -p:UseSharedCompilation=false -p:UseMSBuildServer=false`
    构建后运行：**208 条 `[verify]`、0 条 `Unhandled`、exit 0**，perf `within=True`（avg 4.211ms / p95 6.152ms / max 7.818ms，
    首次冷跑 avg 10.27ms 也在预算内）；scratch 副本已删除，仓库内 harness 未改（仍 200 条，CI 阈值 199 不变）。

### 35.3 提交与推送

| 仓 / 分支 | commit | 内容 |
|---|---|---|
| ohos-workload `master` | `84c184c`（`84c184c…`）、`070f92f` | preview.24 版本刷新（含 pack/templates 与 demo fixture）；release 脚本 `SHA256SUMS` 修复 |
| runtime-ohos `feature/openharmony` | 本 commit（§35） | 本节 + 索引/验收说明/快速开始/签名指南/kit 说明同步 |

推送规则：`git -c http.version=HTTP/1.1 push origin <branch>`，6 次 × 15s 兜底，失败则 fetch+rebase（不 force）。
推送前 `ls-remote` 复核远端 tip（ohos-workload `437cf52`、runtime-ohos `8ab824a9`），本地均为其后代（fast-forward）。

### 35.4 真机前不确定项与遗留

1. **S1/S3/S4 的运行时行为仍只在设备上可证**：`Blazor.start()` 与首屏渲染、torch 是否真的点亮（`setTorchMode` 返回 true
   只代表 Camera Kit 接受）、接收方能否真正读取 `file://` URI（`FLAG_AUTH_READ_URI_PERMISSION` 只表达授权意图）、
   多文件分享仍是文档化 no-op。
2. **S2 的分组/层级效果**：`SetAccessibilityGroup(true)`/`SetAccessibilityLevel("yes"|"no")` 的读屏实际播报差异需要设备；
   节点数导出只在 A11Y 角标弹窗可见。
3. **签名**：4 个已签 hap 用 SDK 自签材料、profile 绑定示例 UDID → 其他设备安装会报 `9568344`（按 `签名与UDID指南.md`
   重签，或用 `hello-maui-app-unsigned.hap` + `自签说明.md` 自助签名）；签名含时间戳，**同负载重新签名的哈希必然变化**，
   交付文档中的 sha256 以随包 `SHA256SUMS` 为准。
4. **本轮顺手做的小修正**（与刷新链直接相关，非行为改动）：`publish-workload-release.sh` 新建 release 时补传
   `SHA256SUMS`；删除 `bin/…/openharmony20.0/` 下两个上一轮遗留的 api20 副本；tracked 演示 fixture
   （`test/hello-maui-app/{ets/modules.abc,libs/…/libopenharmonyhost.so,resources/rawfile/dotnet.zip}`）刷新为本轮
   staging 输出——它们只是仓库内快照，不参与打包路径。
5. **未动的发布面**：SDK release `v11.0.100-rc.1.26451.109-openharmony` 上仍挂着旧 workload bundle（最新 preview.22）；
   `workload-1.0.0-preview.22/23` 两个版本化 release 保持原样（`.23` 的 bundle 仍是 02:0x 打包、不含 S2/S3/S4 的版本，
   新版以 `.24` 提供）。如需把 `.24` 也挂到 SDK release，用 `publish-workload-release.sh --also-sdk-release <tag>`。
6. **kit 专有文档**：`自签说明.md`、`README-交付说明.md` 只存在于 kit 目录（未在本仓库建副本）；`文档索引.md` 是
   `docs/plans/README.md` 的副本。
7. **harness 的 S 系列断言只在 scratch**（与 §34 同一做法），仓库内套件仍是 200 条；若要固化进 CI，需要单独提交
   （S5 未做，避免把验证脚本与交付刷新混在一个提交里）。
8. 本机 `dotnet workload list` 现在指向 `.24`；preview.22 的 pack 已被 `dotnet workload install` 回收，回退需重新安装旧
   bundle。安装/核验过程中对 `~/.dotnet` 的改动都可从 `dist/*.tar.gz`（或 release 资产）重放。

---

## 36. 静态 Web 资产指纹回退与响应缓存头（shell，T6；2026-09-21）

S1 记录的问题：MAUI/Blazor 的静态 Web 资产按指纹名（`name.<hash>.ext`）请求时，壳的
`onInterceptRequest` 只按 `<base>/<root>/<path>` 精确查找，指纹名 404。本节把指纹回退与响应缓存
策略落到壳的公共负载读取路径（hybrid 与 Blazor 两条桥共用），并记录 `WebResourceResponse` 头部
API 的探查结论。

### 36.1 改动（`packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.{22,23,24}/templates/ets/pages/Index.ets`）

- **指纹回退 `staticFingerprintBase(filePath)`**：只重写最后一个路径段的文件名；回收
  `^(.+)\.[0-9a-f]{8,32}$`（8–32 位小写十六进制、必须是主干的最后一段且主干非空），
  `name.<hash>.ext → name.ext`。因此 `app.settings.css`、`.hidden.css`、7/33 位十六进制等原样返回；
  父目录直接取自 `hybridFilePath`/`blazorFilePath` 已校验过的入参（`..`、`\`、编码穿越拒绝保持原样），
  重写只可能缩短最后一段文件名，不会把服务范围移出内容根。
- **`servePayloadFile`**：精确路径优先；未命中且名字含指纹时，用去掉指纹的基名**只重试一次**；
  仍未命中返回 404。hybrid / Blazor 两桥共享该路径，非指纹请求路径逐字不变。
- **缓存头**：`readPayloadFile` 在 200 响应上调用
  `WebResourceResponse.setResponseHeader([{ headerKey: 'Cache-Control', headerValue: ... }])`：
  指纹请求 → `public, max-age=31536000, immutable`；其余（`blazor.webview.js`、`hybridwebview.js`、
  宿主页、应用资产）→ `no-cache`（每次重验证，刷新 pack 不被热 WebView 缓存掩盖）。

### 36.2 头部 API 探查（ArkTS 类型检查）

- SDK 声明：`ets/component/web.d.ts` 的 `WebResourceResponse.setResponseHeader(header: Array<Header>)`
  （API 9+；`Header { headerKey; headerValue }`）；`setResponseData` 等既有成员不变。
- 探查 1：显式标注 `const match: RegExpMatchArray | null = /.../.exec(stem)` + 对象字面量 header map
  → **FAIL**（`{ERROR:2}`），打印 `10605030 ArkTS Compiler Error: Structural typing is not supported
  (arkts-no-structural-typing)`，位置在 `RegExpMatchArray` 标注行。
- 探查 2：`.exec()` 结果改为推断、其余不变 → **0 条 `ArkTS:ERROR`**，
  `Finished :entry:default@CompileArkTS`。结论：**`setResponseHeader` + 对象字面量 header map 可编译**
  （不需要名义类）；被拒的是 `RegExpMatchArray` 的显式标注（结构类型规则），与 header map 无关。
- 中间产物：`736d332` 首版带 `class PayloadHeader implements Header`（同样 0 错误，abc 81,916 B）；
  探查 2 后由 `1542b72` 删除（abc 81,556 B），无行为差异。

### 36.3 验证

- **壳类型检查**：`TYPECHECK=1 HVIGOR_MIRROR=file:///data/storage/el2/base/tmp/opencode/npm-mirror
  bash scripts/build-arkts-shell.sh` → **0 条 `ArkTS:ERROR`**（`Finished :entry:default@CompileArkTS`；
  仅既有 warning；PackageHap 仍因本机打包工具失败，按脚本既定规则忽略）。最终
  `dist/ets/modules.abc` = **81,556 字节**（首版 81,916），**未复制进 pack**、未做 demo publish /
  release refresh；模板构建状态 `.arkts-build` 未进提交。
- **三份镜像**：preview.22/23/24 的 `Index.ets` 在改动前逐字节相同，本轮改完后仍逐字节一致
  （70,039 B，md5 `fd92ce328fb44759d488f19225957da7`）；pack 选择器读取所选版本的模板，三份必须同步。
- **harness**：把 `test/maui-platform-verify`（`5d88377` 折叠 S 系列后仓库内已是 **208** 条）复制到
  scratch，加 8 条 T6 断言：
  1. 模板含该正则/函数（`private staticFingerprintBase(...)`、`.exec(stem)`）；
  2. 同一正则 + 同名切分算法重放 9 个样例全部符合期望（`blazor.webview.713e519f.js→blazor.webview.js`、
     `css/app.0a1b2c3d4e5f6a7b.css→css/app.css`、32 位十六进制、7/33 位不匹配、
     `app.css`/`app.settings.css`/`blazor.modules.json` 原样）；
  3. 精确优先（`exactAt < fallbackAt`）；
  4. 父目录/主干切分与 `..`/`\` 穿越拒绝仍在；
  5. `readPayloadFile(` 调用点 = 3（声明 + 精确 + 回退一次）；
  6. 缓存值 immutable / no-cache；
  7. `setResponseHeader` + header map 存在、无多余名义类；
  8. preview.22/23/24 逐字节一致（70,039 B）。
  `-m:1 -p:UseSharedCompilation=false` 构建（0 error）并运行：**216 条 `[verify]`、0 条 `Unhandled`、
  exit 0**，perf `within=True`（avg 3.061ms / p95 3.871ms / max 5.795ms）；scratch 副本已删除，
  仓库内 harness 未改（仍 208 条，CI 阈值 199 不变）。
  说明：ArkTS 函数不能在本机 C# harness 里执行，第 2 条是"模板必须含该正则 + 同算法重放"，
  壳函数本身的运行时行为仍只由类型检查覆盖。

### 36.4 提交与推送

| 仓 / 分支 | commit | 内容 |
|---|---|---|
| ohos-workload `master` | `736d332`（`736d332869551cdfb3428570efa987acbe55e366`） | 指纹回退 + 缓存头（首版含名义 `PayloadHeader`） |
| ohos-workload `master` | `1542b72`（`1542b729566f7216dc8316c004a293d98c2ba556`） | 探查后删除名义类（对象字面量 header map 可编译） |
| runtime-ohos `feature/openharmony` | 本 commit（§36） | 本节 |

推送规则：`git -c http.version=HTTP/1.1 push origin <branch>`，6 次 × 15s 兜底，失败则 fetch+rebase
（不 force）。ohos-workload 推送前 `ls-remote` 复核远端 tip 为 `5d46e2e`（另一 agent 的签名提交），
本地提交在其上（fast-forward），两次 push 均一次成功；远端 tip 最终为 `1542b72`。runtime-ohos 推送前
远端 tip 为 `8a15f3b`（签名文档提交），本节提交在其上。

### 36.5 不确定项与遗留

1. **真实指纹形态**：本节的保守文法只覆盖 8–32 位小写十六进制；若部署清单使用其他字母表
   （base36/base62 等含 g–z 字母的指纹），**不会**匹配。按名单映射需要
   `*.staticwebassets*.json` 清单，而本应用模型（提取的 payload 目录）不带清单；当前 demo 的
   `wwwroot` 只引用基名（`js/app.js`、`_framework/blazor.webview.js`、`blazor.modules.json`），
   指纹请求只在真实静态资产管线生成的页面里出现。若真机日志出现其他形态，单独放宽文法（保留精确优先）。
2. **无清单 / 无内容校验**：回退按名字推断，不校验"基名文件内容确实对应那个指纹"；错误名字会命中基文件
   （可接受：服务的是同一份内容）。
3. **没有条件请求处理**：壳不实现 `If-None-Match`/`If-Modified-Since`；`no-cache` 只要求重验证，
   壳每次都回 200 全量内容（离线仍可用，只是没有 304 优化）。
4. **运行时未验证**：类型检查只证明头部 API 可编译；ArkWeb 是否把拦截响应的 `Cache-Control` 用于
   其缓存策略、指纹回退在真机是否命中，都需要设备验证。
5. 指纹回退对 hybrid 桥同时生效（共享 `servePayloadFile`）；`_framework/hybridwebview.js` 特例与
   `_hwv*` 端点仍先精确命中，非指纹请求行为不变。
6. `dist/ets/modules.abc`（81,556 B）只是本轮构建产物：把最新 abc 装进 pack、刷新 release/kit 仍是
   独立步骤（与 §28/§35 的待办相同）。
7. 本节的 ohos-workload 改动是**两个**提交：首版 `736d332` 推送后，T6 的头部探查把失败根因定位到
   `RegExpMatchArray` 标注而非 header map，删除名义类只能在已推送历史之上追加 `1542b72`（不 force）。

---

## 37. DeviceDisplay.KeepScreenOn 跨三仓（T8；2026-09-21）

T7 批次的 IDeviceDisplay 把 `KeepScreenOn` 留成 getter=false / setter 忽略。本节补齐
托管 → 宿主 → 壳的窗口管理链：`ohos_host_keep_screen_on(on)` → 壳
`registerKeepScreenOnSink` → `window.getLastWindow(context)` → `setWindowKeepScreenOn(on === 1)`。

### 37.1 SDK 探查（`ets/api/@ohos.window.d.ts`，ohos-sdk 26.0.0.18，API 26）

| 成员 | 签名 | since | 结论 |
|---|---|---|---|
| `window.getLastWindow` | `(ctx: BaseContext): Promise<Window>` | 9 | 采用（壳的 avoid-area 报告已在用同一调用） |
| `Window.setWindowKeepScreenOn` | `(isKeepScreenOn: boolean): Promise<void>` | 11 | 采用（Promise 形式；回调重载同版本存在，未采用） |
| `Window.setKeepScreenOn` | 同形 | 6，**9 起废弃**（`@useinstead Window#setWindowKeepScreenOn`） | 不采用 |
| `Window.isKeepScreenOn` | `boolean` 属性 | 11 | 未采用（getter 取"最后一次被宿主接受的值"，不做回推） |

TYPECHECK=1 证明上述用法在 ArkTS 严格模式下可编译；`getContext(this)` 作为 `BaseContext` 与
既有 avoid-area 行完全同形，无新 import（`window` 已导入）。

### 37.2 改动

- **宿主 `src/OpenHarmonyHost/host_napi.cpp`**：新增单向 `HostSink g_keep_screen_on_sink("keep screen on", false)`
  （复用既有 `HostSinkRegister`/`HostSinkPost`，回调在 JS 线程执行）、
  `extern "C" int ohos_host_keep_screen_on(int on)`（0 = 已入队 / -1 = 丢弃）与
  `RegisterKeepScreenOnSink`（导出表 `registerKeepScreenOnSink`）。0/1 之外的 int 原样透传。
- **壳 `packs/…/1.0.0-preview.{22,23,24}/templates/ets/pages/Index.ets`**：新增 `applyKeepScreenOn(on)`，
  用 `window.getLastWindow(getContext(this)).then(...)` 调 `win.setWindowKeepScreenOn(on === 1)`，
  `.catch` 只记日志（窗口服务拒绝不落页）；`aboutToAppear` 中 try/catch 注册 sink（旧宿主库缺导出
  时静默降级）。三份模板逐字节一致（71,280 B，md5 `e40c8204087f90daac443ae142dc8b90`）。
- **托管切片 `src/Core/src/Platform/OpenHarmony/OpenHarmonyBatteryDisplay.cs`**（仅此文件）：`KeepScreenOn`
  setter 调 `ohos_host_keep_screen_on`，仅当宿主返回 0（已入队）时缓存请求值；缺失库/导出
  `DllNotFoundException`/`EntryPointNotFoundException` 只记一次（`s_keepScreenOnUnavailable`）并经
  `WriteStatus` 记一行，值保持 false。单向设计：壳的窗口调用是异步的、不回推，getter 反映
  "最后一次被宿主接受（入队）的值"。

### 37.3 验证

- **宿主构建**：`bash scripts/build-host.sh` → `selfsign ok`；`llvm-nm -D` 见
  `T ohos_host_keep_screen_on`（相邻 `T ohos_host_display_set_listener` / `T ohos_host_flashlight_set` 完好）。
- **壳类型检查**：`TYPECHECK=1 HVIGOR_MIRROR=file:///data/storage/el2/base/tmp/opencode/npm-mirror
  bash scripts/build-arkts-shell.sh` → **0 条 `ArkTS:ERROR`**（`Finished :entry:default@CompileArkTS`；
  PackageHap 仍因本机打包工具失败，按脚本既定规则忽略）；`dist/ets/modules.abc` = **82,936 字节**
  （上轮 81,556），**未复制进 pack**、未做 demo publish / release refresh。
- **harness**：把 `test/maui-platform-verify` 复制到 scratch，加 8 条 T8 断言：
  1. 托管切片含 `EntryPoint = "ohos_host_keep_screen_on"` + `KeepScreenOnSet(...) == 0` 门控 + 缓存赋值；
  2. 宿主含 `extern "C" int ohos_host_keep_screen_on(int on)`、单向 sink 名/`AddInt(on)`/`? 0 : -1`；
  3. 宿主导出表含 `registerKeepScreenOnSink` 且用 `HostSinkRegister`；
  4. 壳 sink 注册带 try/catch；
  5. 壳 apply 走 `getLastWindow` + `setWindowKeepScreenOn` + 失败日志；
  6. preview.22/23/24 模板逐字节一致（71,280 B）；
  7. 托管缺失库守卫记忆化；
  8. 离线 set(true/false) 不抛且缓存保持 false。
  `-m:1 -p:UseSharedCompilation=false` 构建（0 error）并运行：**216 条 `[verify]`、0 条 `Unhandled`、
  exit 0**，perf `within=True`（avg 10.418ms / p95 14.734ms / max 19.968ms）；scratch 副本已删除，
  仓库内 harness 未改（仍 208 条，CI 阈值 199 不变）。
- **回归兼容**：离线时 setter 不改变 getter，§6 起就有的断言
  （`KeepScreenOn` 在 `= true` 后仍为 false）继续通过，仓库内 208 条套件不被本次切片改动打破。

### 37.4 提交与推送

| 仓 / 分支 | commit | 内容 |
|---|---|---|
| ohos-workload `master` | `9c6ea79`（`9c6ea79ce51dd0bd051bab7b70143056770d9c29`） | 宿主 sink/导出 + 三份壳模板（推送前远端 tip `76de081`，其上是另一 agent 的 demo/release 提交） |
| maui-ohos `feature/openharmony` | `caaa4a99`（`caaa4a99e9949cfe445feafdf48c5e10c3eca7a4`） | 托管 `KeepScreenOn` 桥（推送前远端 tip `0a88b8a1`） |
| runtime-ohos `feature/openharmony` | 本 commit（§37） | 本节（推送前远端 tip `b02597273ab`） |

推送规则：`git -c http.version=HTTP/1.1 push origin <branch>`，6 次 × 15s 兜底，失败则 fetch+rebase
（不 force）。ohos-workload 与 maui-ohos 两次 push 均一次成功（`76de081..9c6ea79`、`0a88b8a1..caaa4a99`）。
maui-ohos 的 sparse-checkout 不含切片目录，`git add` 需 `--sparse`（本次照做，未改 sparse 定义）。

### 37.5 不确定项与遗留

1. **运行时未验证**：类型检查只证明 API 可编译；真机上窗口服务是否接受 `setWindowKeepScreenOn`、
   屏幕是否真的常亮，需设备验证。壳的失败只在日志留 `[maui] keep screen on failed: ...`。
2. **单向语义**：宿主返回 0 只代表"请求已入队"，不代表窗口已生效；getter 缓存的是最后一次被接受
   （入队）的请求值，而非窗口真实状态。若需真实状态，可用 `Window.isKeepScreenOn` 回推（本次未做）。
3. **每次请求都 `getLastWindow`**：未缓存窗口对象；KeepScreenOn 变更很少，成本可忽略。
4. **abc 未入包**：`dist/ets/modules.abc`（82,936 B）仍只是构建产物；把最新 abc 装进 pack、刷新
   release/kit 与 §28/§35/§36 同一待办链。
5. **demo/harness 未动**：按批次边界，仓库内 harness 未加 T8 断言（仅在 scratch 验证），demo 与
   `scripts/` 未动。

## 38. V 系列收官（2026-09-21）

| 批次 | 内容 | 提交 |
|---|---|---|
| **V1** | 去掉 BlazorWebView 初始冗余 `load`（仅当壳已加载 host page 时抑制首次导航；后续显式导航照常 ✓；双配置 216/0 + 原生桩探针实证）| `maui-ohos 96da93de` |
| **V2** | 宿主桥**重发布应用上下文**（`ReadContext` 优选含负载目录的快照；`RefreshContext` 由 surface/lifecycle/晚订阅/重复 `Attach` 触发；单飞/仅变化才发布/**空读不降级**/不清 `NodeContent`/订阅者异常不外溢；`s_contextVersion` 保证精确一次）| `ohos-workload f847224` |
| **V3** | U1"晚到上下文"演练**入 CI**（10 条 `hybrid late …`，驱动真实私有缝；计数 216→**226**；阈值 216→**222**——注：226−20=206 会**降低**门禁，故取 count−4 ✓）| `ohos-workload 074f491` |
| **V4** | kit **自带 `verify-kit.sh`**（`SHA256SUMS` 12 项；包内 `sha256sum -c` 12×OK、`sh verify-kit.sh` → `KIT OK`）+ 索引补 §36/§37 与手册行 | `ohos-workload 37b91bd` · `runtime-ohos 8cb6c8af1a1` |
| **V6** | **最终状态页**（交付/批次/基线/发布/证据/不确定项/外部依赖；如实标注不可核项）| `runtime-ohos f9feacfc1d4` |
| **V7** | **真机操作手册**（校验→安装→启动→采集→五分钟冒烟→失败分支→回传；§5 的"Blazor 不在本轮"注记已过时 → 本批修正 ✓）| `runtime-ohos dea854be427` |
| **像素 CI 修复** | pixel-regression 现在检出切片 + 构建两个 hosting 程序集 + 物化绝对根（`sudo mkdir /storage/...` + 符号链接）；**发现 `headless-render.csproj` 不读环境变量（硬编码）** ✗ → 推荐后续将其改为环境变量间接并删除链接步骤 | `ohos-workload 13ec6e8` |

**待办（排队）**：
1. **V5** `.razor` 变体（切 `Microsoft.NET.Sdk.Razor` 会激活静态 web 资产管线，有改变"4 条 wwwroot"不变量之险 ✗ → 加开关 + 独立工程验证后再评估 ✓）；
2. **V8** 宿主侧**上下文 setter / 壳重发**（V2 只能重读环境变量与原生入口；原生宿主目前只在 `ohos_host_start_app` 存一次 JSON ✗ → 需新增可被壳调用的下发路径才能彻底闭环 ✓）；
3. `headless-render.csproj` 环境变量化（消除 CI 的 sudo/绝对路径依赖 ✓）；
4. 上游三预备分支待 #132953/N15 ✗；两条评论文案待许可 ✗。

**验证基线（V 后）**：交互回归 **226 项**（含 10 条 late-context 演练）· CI 阈值 **222** · 双 perf 门禁（frame + a11y skip/republish）`within=True` · 像素套件本地 PASSED · 五仓库全部 PUSHED。

## 39. V8 宿主侧上下文 setter 与壳重发（2026-09-21）

V2 让托管桥在 surface/lifecycle 事件上重读上下文（`OHOS_HOST_APP_CONTEXT` 优先、原生入口兜底），但原生宿主只在
`ohos_host_start_app` 存一次 JSON：壳启动时若上下文不含负载目录（`appDir` 为空/缺失），托管侧就再也没有渠道拿到新
快照。本节补齐最后一段——**壳可随时向宿主重发上下文，宿主替换当前快照并通过既有通知路径叫醒托管桥**。

### 39.1 机制

| 层 | 入口 | 行为 |
|---|---|---|
| C/头文件 | `ohos_host_set_app_context(const char* json)` | `strdup` 新 JSON → `setenv(OHOS_HOST_APP_CONTEXT)` → 替换 `ohos_host_get_app_context` 快照 → 重放当前 surface 状态；句柄存在前存为 **pending**，`start_app` 在自己的上下文缺失或 `appDir` 为空时采纳它（紧凑 JSON 的 `"appDir"` 非空判定），app 自带的有效上下文优先 |
| C/头文件 | `ohos_host_notify_context(void)` | 不改快照，只重放通知；返回 1=已通知 / 0=无可用通道（无句柄、无桥或无 created/changed surface；后续 surface/lifecycle 事件仍会重读） |
| NAPI | `host.setAppContext(json)` / `host.notifyAppContext()` | 返回原生 rc（0 成功；-1 参数缺失/空或拷贝失败） |
| ArkTS 壳 | `preview.22/23/24 Index.ets` XComponent `.onLoad()` | surface 就绪后 `publishAppContext()` 由 `getContext(this)` 重建 `appDir=<filesDir>/dotnet` + files/cache/bundle/ability 的 JSON 并 `host.setAppContext(json)`；`typeof` 守卫 + try/catch，旧宿主库静默降级 |

**通知路径**：重放的是已存 surface 状态（仅 CREATED/CHANGED），托管 `OnSurfaceNative` 在转发事件前先跑
`RefreshContext()`（V2 实现），因此 setter 一次调用即可让托管侧读到新快照；无 surface 时通知返回 0，但下一次
surface/lifecycle 事件、或托管桥注册时 `register_bridge` 既有的 surface 重放仍会重读，快照不丢。

**内存与并发守卫**：被替换的旧快照进入 `retired_contexts` 链、join 时统一释放（托管 reader 可能仍在校验 getter 指针）；
pending 在采纳或后续 `start_app` 自带有效上下文时释放；retire 节点分配失败时选择泄漏旧串而不是在读者脚下释放。

### 39.2 验证（ohos-workload e77c803）

- **宿主**：`bash scripts/build-host.sh` → **"selfsign ok"**（`libopenharmonyhost.so` 142,240 B，含签名）；`llvm-nm -D`
  导出表含 `T ohos_host_set_app_context`、`T ohos_host_notify_context` 与既有 `T ohos_host_get_app_context`。
- **壳类型检查**：`TYPECHECK=1 HVIGOR_MIRROR=file:///data/storage/el2/base/tmp/opencode/npm-mirror bash scripts/build-arkts-shell.sh`
  → **0 条 `ArkTS:ERROR`**（`Finished :entry:default@CompileArkTS`；PackageHap 失败按脚本既定规则忽略），
  `dist/ets/modules.abc` = **84,040 字节**（上轮 82,936），**未复制进 pack**、未做 demo publish / release refresh。
- **壳模板**：preview.22/23/24 `Index.ets` 逐字节一致（**72,847 B**，md5 `dca1fc9b9b09108147a74075a3710f02`）。
- **harness**：`test/maui-platform-verify` 复制到 scratch，`dotnet build -m:1 -p:UseSharedCompilation=false`（0 error）
  并运行：**226 条 `[verify]`、0 条 `Unhandled`、exit 0**；frame perf `within=True`（avg 9.601ms / p95 11.459ms /
  max 13.158ms），a11y skip/republish 全部 `within=True`（ratio render 28.65x / publish 147.38x）；scratch 副本已删除，
  仓库内 harness 未改（仍 226 条，CI 阈值 222 不变）。
- **既有行为**：未调用新入口时 `start_app`/getter/join 与 V2 完全一致（pending 为空即走原路径）；`ohos_host_run_app` 未动。

### 39.3 提交与推送

| 仓 / 分支 | commit | 内容 |
|---|---|---|
| ohos-workload `master` | `e77c803`（`e77c80321586cfebd2d1c60793d0f8c26e68a59b`） | 宿主 set_app_context/notify_context + NAPI 导出 + 三份壳模板（推送前远端 tip `9a17d3b`，其上为另一 agent 的 preflight/kit 提交）|
| runtime-ohos `feature/openharmony` | 本 commit（§39） | 本节 |

推送规则同 §37：`git -c http.version=HTTP/1.1 push origin master`，6 次 × 15s 兜底，失败则 fetch+rebase（不 force）；
ohos-workload 一次成功（`9a17d3b..e77c803`）。

### 39.4 不确定项与遗留

1. **真机未验证**：交叉编译/类型检查只证明契约可编译；宿主重放的 surface 事件在真机上是否总能让混合资产的晚注册
   落地（`AppDir` 生效后的重试窗口），需设备实证。
2. **`appDir` 判定是紧凑 JSON 文本扫描**：`start_app` 的 pending 采纳只识别 `"appDir":"..."` 形态；带空格的格式化
   JSON 可能被判定为"不含负载目录"而让 pending 优先——本平台壳均由 `JSON.stringify` 生成紧凑 JSON；false negative
   只会保留 start 上下文，不会崩溃。
3. **abc 仍未入 pack**：`dist/ets/modules.abc`（84,040 B）只是构建产物，与 §28/§35/§37 同一待办链（V8 不做版本刷新）。
4. **harness 未加 V8 断言**：按批次边界，仓库内 harness 未动（仅 scratch 复跑）；如需把 C/NAPI/壳三处字符串源码级
   pin 进 CI，可在后续批次并入（当前 CI 阈值 222 不受影响）。
5. **V5（`Microsoft.NET.Sdk.Razor` 变体）与 `headless-render.csproj` 环境变量化仍在队列**（§38 待办 1/3）。
