# runtime-ohos 新面具安全复查 #5b：M2-exit 桥 + M3 消费/呈现（SEC-SCAN-5b，2026-10-06）

**范围：** ow `l/m3-shell-xcomponent` @ `35df4f4`（M2-exit 桥：`host_window_bridge.c`、`WindowSurfaceChanged/Touch/Frame`、`ohos_host_register_window_bridge`、导出 156；M3：per-window `BeginWindow/PresentWindow`、显式 id 认领/rename、壳 `SubWindow.ets`/`Index.ets`）· maui `l/m3-per-window-content` @ `d4ff7d445e`（tagged 通道订阅、deferred OpenWindow→RouteSurface、非主窗绕过进程 overlay 钩子）。**口径：** 离线读码 + 纯 C 单测 + 1 次 host 门禁；未上机，设备结论一律「设备未验证」。**修复已落 L 分支（ow `fb493e1`、maui `f2fa86cec5`，普通推送；未并 master、未动 #49 资产）。**

## Verdict

**PASS WITH FINDINGS（0 高 / 0 中 / 4 低已修 + 4 信息报告）。** ① id 字符面与 ⑤ 显式 id 认领的假成功已修；② 壳拒绝无消费导致的 parked 窗口泄漏已按单子窗契约 fail-closed；③ 输入按窗隔离、④ per-window canvas/overlay 钩子边界、⑤ 壳绘降级逐项无缺陷。

| 指标 | 数值 |
|---|---|
| 复查面 | 6（① id/参数 · ② 事件/replay · ③ 输入路由 · ④ 画布/钩子 · ⑤ 壳降级 · ⑥ 上限/线程） |
| 候选 | 8（低 4 · 信息 4） |
| 已修 | 5（A1/A2/R1/P1/P2） |
| 报告未修 | 3（L1/L2/L3） |
| 构建/设备 | 1×host selftest（registry 78/78）+ host_napi syntax-only；无设备 |

## 发现表

| 编号 | 面 | 严重度 | 标题 | 证据（扫描 tip） | 判定 |
|---|---|---|---|---|---|
| SEC5B-A1 | ① | 低 | 注册表 id 仅长度帽，C0/DEL 控制字符原样进 stderr/hilog/status 证据行（SEC5A-L1 未收口），可伪造/串行日志 | `host_window_registry.c:16-18`；`host_napi.cpp:995,1007,1012`；`OpenHarmonyApp.cs:1801` | **已修** `fb493e1`：WindowIdValid 拒绝 <0x20/0x7F（可打印 UTF-8 保留）+2 单测 |
| SEC5B-A2 | ① | 低 | rename 在 primary 缺失时可将子窗改成 `main`：tagged 事件被 managed 当主窗过滤（暗窗），`lookup("main")` 指向子窗 | `host_window_registry.c:105-127`；`host_napi.cpp:1226-1227` | **已修** `fb493e1`：非 primary 记录禁改主窗 id（DUPLICATE）+3 单测 |
| SEC5B-R1 | ⑤ | 低 | `registerXComponent(id)` 用 `lookup(id)` 判成功：rename 被 DUPLICATE 拒但该 id 属另一组件时仍回 1，壳隐藏降级画布而组件未绑目标 id（fail-open） | `host_napi.cpp:1379-1381`；rename 1226-1239 | **已修** `fb493e1`：改按本组件 `record.id` 等值判成功（`lookup_component` 单锁拷出） |
| SEC5B-P1 | ②/⑥ | 低 | 壳 801 拒绝无消费：deferred 请求后 `_awaitingWindows` 常驻、`LastOpenWindowResult=OpenedWindow`、窗口留 `Application.Windows`；重复 OpenWindow 继续 park（第二 id→801 缺省行为名不副实） | `OpenHarmonyMauiAppHost.cs:522-566,427-430`；`OpenHarmonyApplicationHandler.cs:164-187`；`Index.ets:2464-2468` | **已修** `f2fa86cec5`：已有 awaiting/已绑子窗时 deferred 直接 null（诚实 NotSupported+关窗，不再 park） |
| SEC5B-P2 | ② | 信息 | Destroyed-before-adoption 只摘记录不 `Destroying()` → 窗口常驻 `Application.Windows` | `OpenHarmonyMauiAppHost.cs:637-644` | **已修** `f2fa86cec5`：转统一 destroyedWindow→Destroying（锁外） |
| SEC5B-L1 | ② | 信息 | `s_windowSurfaces` 不随 Destroyed 清除：保留死 `OHNativeWindow*`，晚订阅 replay 含 Destroyed、按 id 缓慢增长 | `OpenHarmonyApp.cs:376,890-895,1798` | 报告：M4 按 state 清指针（replay Destroyed 是 M2 pin 契约） |
| SEC5B-L2 | ④/⑥ | 信息 | per-window draw target（8 槽）无锁、不随关窗回收；>7 个历史 id 后 begin 拒绝（本单子窗+id 复用不触发）；依赖 managed 单线程串行 | `openharmony_host.c:4041-4075,4153,5130` | 报告：M4 上限/线程注记；present 有 registry state 双查（无 UAF） |
| SEC5B-L3 | ②/⑤ | 信息 | 壳自绘关闭依赖 surface Destroyed 先于 `onDestroy`(unregister) 到达；`OpenHarmonySubWindow.Changed`(Closed) 无消费方，顺序反了 managed 会话残留（渲染被 registry 拒绝，无 UAF） | `SubWindow.ets:207-211,136-151`；`Index.ets:closeSubWindow`；AppHost 无订阅 | 报告：M4 接 Closed 兜底 |

## 逐面判定

- ① **A1/A2 已修，无其余缺陷**：NAPI 参数 `typeof` 校验（`host_napi.cpp:4191-4194,4221-4238`）、长度帽拒绝不截断、重复 id/组件/满表 fail-closed、陌生 id 在 native 与 managed 双侧丢弃；bridge 侧 id 只来自注册表记录，无独立 JS 入口。
- ② **P1/P2 已修，L1/L3 报告**：surface 有 per-id replay（含 Destroyed，M2 pin 契约）；touch/frame 瞬态无 replay；同 id 重开 native 重建记录、managed 复最低空 id，无串扰（设备 M3-5）。
- ③ **无缺陷**：native 回调用 `lookup_component` 路由，子窗 touch/frame/mouse 走 tagged、主窗走 untagged（`host_napi.cpp:1125-1133,1155-1160,1171-1176`）；managed 按 id 分发；套件断言子窗触摸不触主窗（main clicks=0）。
- ④ **无缺陷**：`WindowRenderer` 对非主窗强制自身 `WindowSurface.Present()` 且不落进程 `SurfacePresent`（overlay/tooltip 只属主窗，M4 分区）；native begin/present 复核 registry surface/state；`BeginWindow("main")` 仅同信任域 managed 可达，不构成越权。
- ⑤ **无缺陷（语义由 A2/R1 收紧）**：`surfaceBound` 初始 false，register!=1 保持壳绘（Stack 隐藏降级内容，无双渲染/泄漏）；onLoad 异常被 catch 保持降级；unbind 复位。
- ⑥ **P1/L2 已收口/注记**：registry 8 满 FULL（单测）；单壳第二 managed id 801；P1 后 managed 不再 park；draw target/线程假设见 L2。

## 修复验证与提交

- `selftest-host-registry.sh`：78/78 checks、0 fail（floor 40；+2 控制字符、+3 主窗 id 保留），T1/T2/T4 过；`host_napi.cpp` 用同一 NDK（26.0.0.18_2，`--target=aarch64-linux-ohos`）`-fsyntax-only` 通过。
- 未跑：`build-host.sh`（DT_NEEDED/UND/156 导出）与 M3 真机轮（预算/离线）；ow 套件 pin 仍 `d4ff7d445e`，maui 修复在下次 pin 前不进 CI。
- 提交：本文件 → runtime-ohos `feature/openharmony`（`commit-paths.sh`；被拒 fetch+rebase）；修复 → ow `fb493e1`、maui `f2fa86cec5`。
- 不确定：壳 register 失败但不发 Failed 事件时 managed 仍保留单只 parked 窗口（需 M4 超时/Closed 兜底）；L3 关闭顺序未上机验证。
