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
