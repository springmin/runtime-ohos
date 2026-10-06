# MULTIWINDOW-L M2：maui 切片 per-window renderer（2026-10-06）

> 口径：M1 已就绪（ow `l/m1-window-registry` @ `82ef4e7`：宿主 window-id 注册表 + component→window 路由，153/153 导出）。本切片 = maui 分支 `l/m2-per-window-renderer` @ `1a15f56b30`（从 `feature/openharmony` `b093e33825` 切出、已推送，未并主线、未强推）；**ow 仓未改**（仅消费其桥/宿主），设备未动，#49 资产未动。证据 scratch `/data/storage/el2/base/tmp/opencode/mw-l/m2-*`（未入库）。验收口径对照 `2026-10-06-ohos-multiwindow-l-acceptance.md` §2。

## 改动（maui `l/m2-per-window-renderer`）

- `OpenHarmonyWindowSurface`：按窗对象化。新增 `WindowId`（主窗 `"main"`）/`PrimaryWindowId`，主窗保留 bridge `SurfaceChanged` 订阅，第二窗 surface 由路由喂入；`Begin`/`Present` 成为绘制目标 seam（默认仍是共享 host canvas），`BeginHook`/`PresentHook` 供离设备测试按窗绑定目标。
- `OpenHarmonyWindowRenderer`：新增 `WindowSurface`（M2），`Render`/`Present` 解析顺序 = 静态测试 seam → 窗口 surface → host canvas；现有套件的静态 seam 仍优先，单窗行为不变。
- 新增 `OpenHarmonyWindowHost`：**每窗状态对象**（window/surface/renderer/尺寸/dirty/ready + 输入/frame；`Adopt`/`Reset`/`Arrange`/`Render`/`HandleTouch`/`HandleMove`/`HandleCancel`/`OnFrame`/`Describe`）；共享的 arrange 尾（safe-area）走宿主 `ArrangeContent`。
- `OpenHarmonyMauiAppHost`：新增按窗注册与路由——`CanOpenWindow`/`TryOpenWindow`/`FindSecondaryWindow`/`SecondaryWindows`/`PendingSurfaceCount` 与 `RouteSurface(id,info)`/`RouteTouch(id,args)`/`RouteFrame(id)`；**无窗时 surface 记录态**、`OpenWindow` 时绑定；未知 id 的 `Destroyed` 报告丢弃不滞留。主窗路径（Run/TryAdoptWindow/NotifyWindowClosed/Arrange/Render/触摸/生命周期）源码形状与行为零变化（套件 source pin 全保留）。
- `OpenHarmonyApplicationHandler.MapOpenWindow`：有可绑定第二 surface 时，`OpenWindow` 真开第二个 managed 窗（`OpenedWindow`，独立 surface/renderer/尺寸）；无可绑 surface 时原样诚实降级 `CurrentWindowKept`（首窗、关窗后重开语义不变）。
- `MauiOpenHarmonyExtensions`：**未改**（偏离计划说明见下）。

## 窗口化边界

- 已按窗：surface、renderer、arrange 尺寸、frame 输出、触摸输入（主窗 = 历史 legacy 槽，第二窗 = `OpenHarmonyWindowHost`）；window-id 即 M1 注册表 id，首窗固定 `"main"`。
- DI：`OpenHarmonyWindowRenderer`/`OpenHarmonyWindowSurface` 单例仍是**主窗对**（现有 `resolve` 语义与套件依赖不动）；第二窗对由宿主按窗构造（等价工厂语义；按窗 DI/窗口作用域服务留 M4）。
- 仍进程级（M4）：a11y 影子树与动作、overlay 宿主、pinch 监听、IME、safe-area、系统字体缩放、`MauiContext`。
- 设备侧：桥事件尚不带 window-id（计划 §M2 的 ow 部分未做），故第二窗真 surface 事件→managed 的链路以 `RouteSurface` 适配口预留；本 M 以 headless 驱动验证，M3 壳显式 id 后由桥直接调用。

## 与 M1/M3 接口约定

- M1：首窗仍走 `main`/legacy；后续窗 id = 宿主注册表 id（component id 或 `surface-N`）；关闭走壳 `unregisterXComponent`，同 id 可重注册。
- M2 适配口：`RouteSurface(id, info)`（未知 id → pending，`TryOpenWindow` 绑定；`Destroyed` 丢弃）、`RouteTouch(id, args)`、`RouteFrame(id)`；M2-ow 的 managed 桥以 id 事件调用这三个入口即可，主窗用 `"main"`。
- M3：壳 `registerXComponent('sub-N')` 的 id 必须与管理侧会话 id 一致（`OpenWindow` 绑定取 pending 首个 id）；每窗 lifecycle/焦点后续在 `OpenHarmonyWindowHost` 扩展。

## 测试证据（headless；日志 scratch `mw-l/m2-*`）

- 切片构建：standalone `IsAotCompatible+EnableTrimAnalyzer+EnableAotAnalyzer -warnaserror:IL2026,IL3050` → **0 error / 0 IL2026/3050**，74 warning 全为基线既知白名单（CS0618/CS8604/CA2255）；`m2-build-slice.log`。
- 交互套件 `test/maui-platform-verify`（编译本切片源码）：**`[suite] checks=607 total=609 floor=589 assert=True`、0 Unhandled**；`m2-run-interaction3.log`（首轮 `m2-run-interaction2.log` 同绿）。
- 像素套件 `test/headless-render`：**`PIXEL ASSERTIONS PASSED`**；`m2-run-pixel.log`。
- 新增 headless 双窗 harness（scratch `m2-headless/`，编译切片 + 22 checks，全 true）：单面 `OpenWindow` 降级 → 第二 surface `pending` → `OpenWindow` 绑定（`OpenedWindow`、独立 640×480）→ 双窗各自 canvas 出画（互不串标签）→ 第二窗 resize 800×600 不影响主窗 1080×1920 → `RouteTouch` 只击中第二窗按钮 → 关窗只删其会话、主窗存活 → 同 id 重建可再次 `OpenedWindow`；`m2-run-headless3.log`。
- AOT publish：**环境阻塞**（非切片问题，见余项）；`m2-aot/publish-aot.log`。

## 余项 / 不确定

- **对照验收矩阵 §2，M2 退出未达项**（本切片按任务约束只交 maui + 文档，三项留 M2 收口）：M2-01 双窗用例 pin 入 `test/maui-platform-verify`（+22 checks、floor 抬升）；M2-ow 桥事件带 window-id 与 `host-exports.txt`/`check-host-exports.py SOURCES`/selftest 同步；M2-03 AOT publish（需 workload .28 解阻塞）。
- **M2-ow 未做**（本切片显式只碰 maui）：`Microsoft.OpenHarmony.Hosting` 的 `s_surface/s_surfaceHandlers` 带 window-id 事件 + 宿主第二 surface 的 per-window canvas 目标；真机第二窗绘制/触摸未验证（本 M 退出标准为 headless）。
- AOT publish 阻塞：`~/.dotnet` 的 workload ref pack preview.24 在 csc 中屏蔽工作树 hosting DLL（缺 `IOpenHarmonyOverlaySlotOwner`，均为未改文件；基线同样失败），且宿主重载下 ilc 未跑完；需刷新 workload（.28）后重跑，切片自身 0 IL 已由分析器构建覆盖。
- 主窗对称抽到 `OpenHarmonyWindowHost`（与 a11y/overlay/IME/safe-area 分区）留 M4；字体缩放/生命周期/激活目前仍驱动主窗。
- 设备轮未跑：无第二 surface 分发（M2-ow）前真机双面联动无意义；kit #49 状态未动、设备锁未取。
