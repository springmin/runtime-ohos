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
