# runtime-ohos 新面具安全复查 #5a：MULTIWINDOW-L M1 窗口注册表（SEC-SCAN-5a，2026-10-06）

**范围：** ow `l/m1-window-registry` @ `82ef4e7`（8 文件 +1034/−60：新增纯 C 8 槽 component→window 注册表 `host_window_registry.{h,c}` + 单测，`host_napi.cpp` Init 按 XComponent 登记、surface/touch/frame 按 component 路由、新增 `registerXComponent(id?)`/`unregisterXComponent(id?)`，build/preflight 接线）。**口径：** 离线读码 + 纯 C 单测/ASan+UBSan/TSan + `build-host.sh` 三门禁；未上机，设备可见结论一律「设备未验证」。**修复已落 ow `df2a246`（普通推送；未并 master）。**

## Verdict

**PASS WITH FINDINGS（0 高 / 0 中 / 2 低已修 + 5 信息报告）。** ① 输入/边界（id 溢出拒绝不截断、容量 8 FULL、重复 id/组件拒绝、双注销 NOT_FOUND、注销后 surface/touch/frame 丢弃）与 ② 路由可信面（component 取自平台 `napi_unwrap`，JS 只能传有界字符串，null/类型校验齐全）逐项无缺陷；两处 fail-open 面（`unregisterXComponent` 非法参数回落主窗、surface 路由 lookup+update 非原子）已最小修复；其余 5 条信息项给建议。

| 指标 | 数值 |
|---|---|
| 复查面 | 5（① 输入/边界 · ② 路由可信面 · ③ 并发/线程 · ④ 单窗退化 · ⑤ 日志/错误路径） |
| 候选 | 7（低 2 · 信息 5） |
| 已修 | 2（SEC5A-U1、SEC5A-R1） |
| 报告未修 | 5（信息） |
| 设备验证 | 无（离线；设备未验证） |

## 发现表

| 编号 | 面 | 严重度 | 标题 | 证据（@82ef4e7） | 判定 |
|---|---|---|---|---|---|
| SEC5A-U1 | ⑤ 错误路径 | 低 | `unregisterXComponent` 传非字符串/空串时静默回落释放主窗（`''`、数字、对象都会注销 `main`） | `host_napi.cpp:4163-4170`；影响路径 4172-4195 | **已修** `df2a246`：仅缺省/undefined 释放主窗，非法参数告警返回 0（fail-closed） |
| SEC5A-R1 | ② 路由 / ③ 并发 | 低 | `HostRouteSurface` 先按 component 查询、再按 id 更新，两锁间 id 被注销并重登记 → 事件落进新组件记录（surface/尺寸/state/计数错配） | `host_napi.cpp:984,991`；`host_window_registry.c:105-122`；任意线程承诺 `host_window_registry.h:21` | **已修** `df2a246`：`ohos_host_window_surface_component` 单锁 lookup+update（`host_window_registry.c:130`），host 改走该口（`host_napi.cpp:987`） |
| SEC5A-L1 | ⑤ 日志 | 信息 | 页面可控 id 原样进 stderr 证据行（`%s`），C0/DEL/换行可伪造 surface/注册日志 | `host_window_registry.c:16`；`host_napi.cpp:995-996,1290-1292` | 报告：M2/M3 前在 id 校验或打印处拒绝/转义控制字符（同信任域，无内存安全问题） |
| SEC5A-L2 | ① 生命周期 | 信息 | state=DESTROYED 后注册表仍保存 `record.surface`（含真实销毁指针） | `host_window_registry.c:115`；`host_napi.cpp:1020-1021` | 报告：M2 消费前按 `state<2` 使用或销毁时清空；M1 无解引用 |
| SEC5A-L3 | ② 路由契约 | 信息 | 显式 `registerXComponent('sub-N')` 对 Init 已登记的组件是 no-op（忽略 requested id），随后按 `'sub-N'` 注销返回 0 → 残留到 env 拆除；M3 计划的 reg/unreg 成对流程会踩 | `host_napi.cpp:1200-1202,1317-1331,4146` | 报告：M3 让 XComponent `id` 属性 = 目标 window id（Init 派生同名），或注销用派生 id；否则 M3-04 churn 会耗尽 8 槽 |
| SEC5A-L4 | ① 容量退化 | 信息 | >8 个组件 fail-closed 不挂回调，但仅 stderr/hilog 一行，壳不可见 | `host_napi.cpp:1228-1233`；`host_window_registry.c:89-92` | 报告：M3-05 上限探测把拒绝计数/标志回传壳（判定卡拉红） |
| SEC5A-L5 | ④ 单窗不变式 | 信息 | primary 判定 = 注册时 `main` 不存在；主窗注销后下一 claim（可能是子窗）接管老桥 | `host_napi.cpp:1206-1211`；注销路径 4174-4195 | 报告：M3 壳主窗销毁时避免子窗抢先 claim；后续可按 binding 记录 primary 曾登记位 |

## 逐面判定

- ① 输入/边界 **无缺陷**：`WindowIdValid` 长度帽拒绝不截断（`registry.c:16-17`）、CopyId 有界（19-26）、重复 id/组件拒绝（72-81）、满表 FULL（89-92）、双注销 NOT_FOUND（154-166）、注销后事件全 NOT_FOUND（105-113,124-136,139-151）、teardown/unregister 先掉注册再删 wrapper 引用（`host_napi.cpp:824,4179-4195`）。
- ② 路由可信面 **无缺陷（契约见 L3）**：component 只能来自平台 `OH_NATIVE_XCOMPONENT_OBJ` 的 `napi_unwrap`（`host_napi.cpp:1299-1311`），JS 仅能提供 ≤63 字符的字符串 id（1203-1227），注册表唯一性兜底（`registry.c:67-81`）。
- ③ 并发/线程 **R1 已修，其余无缺陷**：注册表全程互斥且记录按值拷出（`registry.h:21`）；secondary 回调只计数、不做 napi 调用；`window_claims` 仅 JS 线程读写（824/1192/4160）；TSan 4 线程压测无报告。
- ④ 单窗退化 **无缺陷（边界 L5）**：首个 claim = `main`/primary（1206-1211），primary surface 仍走 `ohos_host_set_native_window` 老路径（988-990），重复 claim 幂等（1200-1202），非注册组件事件丢弃（983-986）。
- ⑤ 日志/错误路径 **U1 已修，其余 fail-closed**：`RegisterCallback`/wrapper 引用失败均注销并返回（1244-1250,1263-1268）；导出面无新增 managed DllImport（153 不变）。

## 修复验证（ow `df2a246`，普通推送，`ls-remote` 复核同值）

- diff 4 文件 +84/−12：注册表新增 component 键 surface 更新口，`unregisterXComponent` 参数改 fail-closed；单测 61→66 checks（+5：component 键更新/拷出、旧 owner 迟到事件丢弃、NULL/未知拒绝）。
- `selftest-host-registry.sh` 66/66（floor 40）；ASan+UBSan 66/66；TSan 4×20k register/surface/lookup/unregister 零报告。
- `build-host.sh`（SKIP_SIGN=1）：DT_NEEDED 白名单 / UND denylist / 153 导出三门禁过；M1 设备证据未重跑。

## 提交与不确定

- 提交：本文件 → runtime-ohos `feature/openharmony`（`commit-paths.sh`；被拒 fetch+rebase）；修复 → ow `l/m1-window-registry` `df2a246`。分支 check 数已 66，L 计划/验收文中的「66 checks」待回填。
- 不确定：单窗 #49 日志对拍与双 XComponent 真机轮未在本轮重跑（离线扫描）；L2 待 M2 消费面出现后定夺；L3 需 M3 壳接线时按建议落地并加 churn 回归。
