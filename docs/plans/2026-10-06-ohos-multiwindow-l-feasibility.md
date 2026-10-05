# 真·多窗口 L 可行性预研（只读 + 2 探针，2026-10-06）

> 口径：kit #49 M（maui `b093e33825` / ow `be70a73`+`16df9a3`）+ SDK 26.0.0.18 / API26 d.ts + 设备 HAD-W32 / OpenHarmony 7.0.0.111 / 2in1（debug 域）。**未改产品代码**；探针源码/日志/截图在 scratch `mw-l/`（未入库）。人日为粗估区间（单人）。
> 关联：`2026-10-05-ohos-multiwindow-prestudy.md`（平台面/权限面）· `2026-10-05-ohos-multiwindow-m.md`（M = 壳绘单 surface）· `2026-10-05-ohos-platform-limitations.md` E2。

## 1. 结论摘要（推荐）

- **B（真第二 MAUI 窗）平台面可行**：应用内子窗内可创建 XComponent（SURFACE）并拿到独立 surface id、独立原生 surface 回调；同一页两个 XComponent 会**各触发一次 NAPI `Init`**（共享 env/exports，各自 OH_NativeXComponent 与 ANativeWindow），即"第二视觉树"的渲染承载无平台/权限障碍（探针 §4）。
- **A 的原始形态（第二 NAPI/宿主实例）不可行**：宿主核心 `openharmony_host.c` 明确"one bridged application per process"，`ohos_host_start_app` 对第二次启动直接拒绝（`g_app`/`g_launch_in_progress`，1676 行）；也不应再起第二套 CoreCLR/hostfxr。可行形态是 **A′ = 同一宿主模块 + 每窗 host/surface/renderer**，与 B 收敛为同一条路线（下文称 A′/B）。
- **C（跨窗 surface/纹理共享）不建议**：没有免系统权限的跨窗 surface 共享 API；只剩像素搬运路线（ImageReceiver/PixelMap → 子窗 ArkUI Image/Canvas），有逐帧拷贝、帧率与输入重映射成本，而 A′ 已证明可行，C 无必要。
- **建议（不建议，除非…）**：近期不以独立 kit 排全量 L；若产品必须补 `OpenWindow` 真多窗语义，走 **A′/B**，第一刀只做"宿主多 XComponent + surface/touch/frame window-id 化 + 第二 surface/renderer 实例（不含 overlay/a11y）"，量级为 M 的 3–5×（粗估 20–35 人日），先交付"第二窗出 MAUI 画面 + 触摸"闭环，overlay/a11y/IME 逐项后补。

## 2. 能力矩阵

| 能力 | SDK / 权限 | 架构现状 | 性能 | 判定 |
|---|---|---|---|---|
| 应用内子窗 `createSubWindowWithOptions` | API 11+/12（syscap SessionManager），**无 ACL**；M 已用 | 壳侧控制器已有（Index.ets 2380+） | 子窗随主窗，60fps 主窗无回退（M） | 可用（已落地） |
| 子窗内 XComponent（SURFACE） | ArkUI.Full，无权限 | **探针新增**：surface id + 原生回调可用 | 探针 surface 空闲，未绘制 | 平台可达（P1/P2） |
| 同 library 多 XComponent | NAPI module 语义 | **探针**：`Init` 每 XComponent 调用一次，同 env/exports、不同 native 组件；`registerXComponent()` 单槽会早退 | 2 个 720×171 surface 并存无 fault | 平台可达；宿主需改造（P2） |
| 第二 NAPI/宿主实例（第二 `startApp`/CoreCLR） | 非 SDK 限制 | 宿主核心单 `g_app`，二次启动拒绝 | — | **不可行（设计）** |
| 系统独立窗 `TYPE_FLOAT` | 需 `SYSTEM_FLOAT_WINDOW`（系统级） | 未用 | — | 三方不可达（预研/M） |
| MAUI `OpenWindow` → 第二窗 | 无平台 API 障碍 | `OpenHarmonyApplicationHandler` 诚实降级 `CurrentWindowKept`；`OpenHarmonyMauiAppHost` 单 `_window`/renderer/surface；DI 单例（MauiOpenHarmonyExtensions 164–166） | — | 需 A′/B 改造 |
| 跨窗 surface/纹理共享 | 无公开 API | 无 | 像素路径未测 | 不可达/不建议（C） |
| a11y / overlay / IME / 避让区 | — | 进程级单实例（a11y provider、overlay 槽池、IME overlay、safe-area） | — | 多窗下需分区（L 主体成本） |

## 3. 路线评估（A′/B 合并，C 单列）

### A′/B：同宿主模块多 XComponent + 每窗 MAUI Window/surface/renderer

要点：`OpenHarmonyBridge` 的 surface/touch/frame 为静态单槽（`OpenHarmonyApp.cs` s_context/s_surface/s_surfaceHandlers）；宿主 native 侧 `HostBinding` 每 env 一个 xcomponent 槽、`g_host` 单当前绑定（`host_napi.cpp` 245–251/316–318），`Init` 已按 env 复用；`host` 核心 `g_surface_window/g_native_window_*` 单套（`openharmony_host.c` 1569+/2311+）。改造 = 把组件登记从"JS 调 `registerXComponent()` 读 OBJ"改为"`Init` 时按组件登记"，事件（surface/touch/frame）带 window id，managed 侧按 id 建 surface/renderer/host。

| 切片 | 内容 | 人日 |
|---|---|---|
| N1 宿主/桥 | 多 XComponent 注册表（Init 登记/teardown 注销）+ surface/touch/frame 带窗 id | 3–5 |
| N2 maui 分片 | 每窗 `OpenHarmonyWindowSurface`/`Renderer`/输入/键盘/焦点状态；`OpenHarmonyMauiAppHost` 按窗对象化 | 5–8 |
| N3 OpenWindow 映射 | `OpenWindow` → 壳 `createSubWindowWithOptions` + XComponent 子窗页；每窗 Created/Activated/… 生命周期 | 3–5 |
| N4 子系统分区 | 每窗 overlay/CEF、a11y、IME 镜像、避让区、alert/flyout | 5–10 |
| N5 验证 | 套件/真机轮/回归/文档（含多窗判定卡） | 3–5 |
| 合计 | | **19–33（≈4–7 周）** |

关键未知（先验则先解）：子窗数量上限与多子窗并存；子窗焦点/z-order/软键盘；a11y provider 是否覆盖子窗节点树；CEF/ArkWeb 槽位池如何按窗共存；触摸进子窗 XComponent 后的宿主路由（pointer id/hover/pinch）；真实绘制下第二视觉树帧率/内存。
风险：N4 里任一项可能需要第二 page 的独立 overlay 宿主，成本上探；单设备 2in1/debug 结论不能外推手机/release（E1）。

### C：壳绘增强（宿主渲染共享/纹理）

- 直接共享 native window 无 API；`OH_NativeImage` 走 GL 纹理需 ContentSlot/GL 环境，不在公开跨窗路径内。
- 退化路线 = 宿主离屏渲染 → PixelMap/ImageReceiver → 子窗页 `Image`/`Canvas` 轮询显示：~5–10 人日原型，逐帧 CPU 拷贝 + ArkUI 合成，720p×60fps 存疑；输入仍需 shell→managed 重映射。
- 结论：**不建议**（无平台优势，性能/复杂度都劣于 A′）。

## 4. 探针结果（2026-10-06，设备互斥锁下；scratch `mw-l/`）

构装：scratch 拷贝 ow（scripts + packs + `.arkts-build`）→ 仅改 `templates/ets/pages/SubWindow.ets` 加 XComponent → UI abc（417,320/419,060/420,296 B，13.0.1.0）→ 重打包 kit #49 unsigned hap → `sign-for-device.sh`（UDID 1BCE13C8…）→ hdc 安装/启动 `app://subwindow/open`。全程主窗保持 `canvas presented (2090x1324) avg 16ms`、0 fault，子窗 open/close 正常。

- **P1（绑定宿主库 `libopenharmonyhost`，子窗 1 个 XComponent）**：`onLoad` 得到 `surface=8267812046416`，`host.registerXComponent()` 调用未抛（`register=called-ok`）；关闭时 `onDestroy`。但状态文件尾（native stderr）未出现该组件的第二条 `surface state=` 行（推断：现宿主单槽早退，组件未被登记；属实现限制而非平台限制）。
- **P2（探针库 `libmwlprobe`，子窗同页 2 个 XComponent）**：`MWLPROBE init env=0x5abf8ae000 exports=0x5abf96a020 native=0x5ac15c8218`；第二次 `init` 同 env/exports、`native=0x5ac15c8838`；两次 `register rc=0`；两条 `surface-created`（各自 window 0x5ac139f860/0x5ac139f9a0，720x171）；关闭时两条 destroy。**结论：框架按每个 XComponent 调 `Init`，但模块实例（env/exports/JS 函数）共享，组件句柄必须按次登记。**
- 截图 `mwl-p2.jpeg`：子窗内两条黑色 XComponent 带 + 主窗正常；`GetXComponentId` 在回调期返回失败（`id=(id-failed)`，未深究，不影响结论）。
- 限制：只证"承载/回调"，未绘制进 surface、未测子窗 XComponent 的触摸/pinch/焦点、未测多子窗；单设备 2in1、debug 域。

## 5. 对平台限制 E2 行的更新建议

现 E2 把 L 描述为"无入口…**需外部/上游**"。建议改为：

> **L（真 OpenWindow：per-window renderer/surface/输入/a11y）平台已证可达、宿主未实现** — 2026-10-06 L 预研（P1/P2 真机）：应用内子窗可承载 XComponent、同 library 多 XComponent 各自触发 NAPI `Init`/surface 回调（无 ACL）；剩余为宿主架构改造（静态单 surface 桥 + 单 `g_app` 核心 → per-window 状态），量级 M×3–5。`TYPE_FLOAT` 系统窗仍不可达；第二 `startApp` 仍被宿主设计拒绝。

## 6. 证据与提交

- 探针源码/日志/截图（未入库）：`/data/storage/el2/base/tmp/opencode/mw-l/`（`probe/mwlprobe.cpp`、`hilog-probe2.raw`、`hilog-native2.raw`、`mwl-p2.jpeg`、`build-ui*.log`、`sign*.log`）。
- 只读盘点：maui `OpenHarmonyWindowRenderer/WindowSurface/MauiAppHost/ApplicationHandler`、ow `host_napi.cpp`/`openharmony_host.c`、壳 `packs/.../templates/ets/pages/{Index,SubWindow}.ets`；SDK d.ts `@ohos.window`（createSubWindowWithOptions/TYPE_FLOAT）与 `component/xcomponent.d.ts`。
- 提交：本文（runtime-ohos `feature/openharmony`）；探针不落库、无产品改动、无上游提交。
