# runtime-ohos 新面具安全复查 #5c：M4 焦点/IME/生命周期/a11y/pinch 分区（SEC-SCAN-5c，2026-10-06）

**范围：** ow `l/m4-focus-ime` @ `06859d4`（`2c0f1f5`+`27055f9`+`9738d7e`+`06859d4`，相对 5b tip `fb493e1`：壳子窗 Active/Inactive + 主窗 HIDDEN/Home 扇出 + `Closed` 兜底；子窗隐藏 TextInput + focusable XComponent(onKeyEvent) + onBackPress；AppStorage 焦点通道 op 6；text/composition/submit/key/back tagged；pinch 按窗（新导出 157/157）；每窗 a11y 影子帧；alert 归属/几何按窗）· maui `l/m4-per-window-focus` @ `c2a59fbf27`（`c7f440fc65`+`c2a59fbf27`：按窗 ResolveWindowId 路由 Entry/Editor/SearchBar、WindowPinch、a11y 分区、overlay 隔离）。**口径：** 离线读码 + 1 次纯 C host selftest 构建；未上机、未构建 C#；设备结论一律「设备未验证」。**修复已落 L 分支（ow `a1ebde2`、maui `23d98a9615`，普通推送；未并 master、未动 #49）。**

## Verdict

**PASS WITH FINDINGS（0 高 / 1 中已修 / 1 低报告 / 4 信息报告）。** ② 主→子全局文本泄漏已修（按窗门禁 + 反转隔离 pin）；子窗 prompt 键盘全局化、③ 顺序假设、⑥ Back/按键无消费者、① pinch 非有限几何、④ 子窗帧常驻为报告项；其余 ① 边界、⑤ 降级路径无缺陷。

| 指标 | 数值 |
|---|---|
| 复查面 | 6（① 导出/桥 · ② 焦点/IME · ③ 状态机 · ④ a11y 分区 · ⑤ 降级 · ⑥ 输入/Back） |
| 候选 | 6（中 1 · 低 1 · 信息 4） |
| 已修 | 1（A）+ 回归 pin 1（ow 套件 662→663） |
| 报告未修 | 5（B/C/D/E/F） |
| 构建/设备 | 1×host selftest（bridge 12/12 script、14/14 unit、0 fail）；无设备 |

## 发现表

| 编号 | 面 | 严重度 | 标题 | 证据（扫描 tip） | 判定 |
|---|---|---|---|---|---|
| SEC5C-A | ② | 中 | 主窗全局文本未按窗门禁：主窗击键可进入子窗逻辑仍聚焦的 Entry/Editor/SearchBar（TextInput/Composition/Submitted） | `OpenHarmonyEntryHandler.cs:143-145,176-180`（`c2a59fbf27`）；`OpenHarmonyWindowHost.cs:380-396` Deactivated 不清焦点；`SubWindow.ets:277-286` 只 blur ArkUI 输入 | **已修** `23d98a9615`：全局订阅改 `OnGlobal*` 包装，按 `OpenHarmonyWindowInputRouter.IsPrimaryWindow` 门禁；tagged port 不变；ow 套件 +1 反转隔离 pin（`s_textInputThunk` 驱动） |
| SEC5C-B | ② | 低 | 子窗 Prompt 键盘仍走进程全局：任何窗口的 prompt 都 `SetKeyboardText/RequestTextInput(true)`（焦点落主窗 IME）；全局 prompt 追加入口无归属检查 | `OpenHarmonyAlertManager.cs:90-91`；`OpenHarmonyMauiAppHost.cs:75-76` | 报告：修正需 tagged 文本按窗接入 alert host（随按窗 overlay 下波）；现状子窗 prompt 反依赖全局路径 |
| SEC5C-C | ③ | 信息 | `Activated()` 清 `_stopped`：ACTIVE 若落在 STOPPED 与 RESUMED 之间会吞掉 `IWindow.Resumed`/`Application.SendResume` | `OpenHarmonyWindowHost.cs:356-378`（368/373 行）；壳同回调内先 emit RESUMED 再报 ACTIVE（`Index.ets:2685-2689,2454-2468`） | 报告：当前壳序不可达，状态机对顺序有隐含假设（未改） |
| SEC5C-D | ⑥ | 信息 | 子窗 Back/按键通道无生产消费者：`WindowInputRouter.Back`、`KeyListener.WindowKeyEvent` 无订阅；子窗 `onBackPress` 返回 false，不进主窗 `BackPressed` 链 | `OpenHarmonyWindowInputRouter.cs:53,107`；`OpenHarmonyKeyListener.cs:65,81-86`；`SubWindow.ets:341-344` | 报告：无串窗（非焦点窗不能触发主窗 Back），功能仅线缆未接线 |
| SEC5C-E | ① | 信息 | pinch 不做 nan/inf 校验：非有限中心被 managed 命中测试丢弃；非有限 scale 需平台触摸点非有限；NAPI 只暴露 register，notify 仅 OnTouch 内部可达 | `host_napi.cpp:1047-1136`；`OpenHarmonyWindowRenderer.cs:2272-2274` | 报告：8 槽满即丢、注销随窗释放；无 JS/伪造 id 注入面 |
| SEC5C-F | ④ | 信息 | 子窗 a11y 帧与差分基线按 id 常驻、关窗不回收；子窗 publish 不触碰 host provider | `OpenHarmonyAccessibility.cs:164,195,535,642-675` | 报告：主 `s_frame` 路径零变化、无双呈现；单子窗 id 复用下有界 |

## 逐面判定

- ① **无缺陷**：`ohos_host_register_window_pinch` 进契约表（157/157），注册/注销/重置对称（`bridge.c:28-41,91-102`）；`WindowIdValid` 拒 NULL/空，未知 id 在 managed `RoutePinch` 丢弃；pinch 表 8 槽、满即丢、unregister 释放（`host_napi.cpp:4334`）。
- ② **A 已修，B 报告**：op 6 经壳 `forwardSubWindowTextFocus` 按 `surfaceId` 校验 live managed 子窗，非匹配回 801；子窗侧再按 `request.surfaceId === this.surfaceId` 复核；空 id 回落当前子窗（应用自家信任域，注记）。
- ③ **C 报告**：Activated/Deactivated 双向幂等（`_activated` 守卫），Stopped/Resumed 由 `_stopped` 单飞；close 后事件经 `FindSecondaryBySurface`/`_window=null` 全丢弃；`Closed` 兜底 `CloseSecondaryBySurface` 锁外 Destroying。
- ④ **无缺陷**：主 `s_frame` 的 Volatile 读写、begin/node/commit、action/modal 门禁逐字保留，action 门禁改为仅主窗归属 alert（`MauiAppHost.cs:1242`）；子窗帧本地化且 alert 只进归属窗；子窗销毁/异常不触碰主帧。
- ⑤ **无缺陷**：子窗 a11y 无 provider 时不部分发布、不双呈现（`Publish` 对非主窗直接返回）；ArkWeb 未启用保持单宿主降级（本波无 web 改动）；人工卡仅文档，无脚本注入面。
- ⑥ **无缺陷（D 注记）**：触摸/pinch 均按 registry `route.id` 分区；子窗 Back 仅 advisory 且无消费者，主窗 Back 链只由主页面 `onBackPress` 触发。

## 修复验证与提交

- `selftest-host-window-bridge.sh`：12/12 script + 14/14 unit、0 fail（含 pinch id/相位/缩放/中心、第二窗独立流、NULL/空 id 丢弃、重注册替换）；`host-exports.txt` 含 pinch register。
- 未跑：host 全量 build（157 导出/DT_NEEDED）与 `maui-platform-verify`（本次 pin 未构建）；maui 修复仅源码审查，下轮 CI pin/preflight 生效。
- 提交：本文件 → runtime-ohos `feature/openharmony`（`commit-paths.sh`；被拒 fetch+rebase）；修复 → maui `23d98a9615`（已推 `origin/l/m4-per-window-focus`）、ow `a1ebde2`（已推 `origin/l/m4-focus-ime`）。
- 不确定：B 的子窗 prompt 键盘需真机复核；C 的顺序假设仅由壳当前时序保证；D 的 Back/按键消费未接线；A 的反转 pin 未经 C# 构建执行。
