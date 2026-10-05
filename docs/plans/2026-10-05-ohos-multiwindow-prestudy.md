# 多窗口 / 2in1 可行性预研（只读研究，2026-10-05）

> 口径：kit #47 切片（maui `d5384d6cc3` / ow `f538c84`）+ 本机 SDK 26.0.0.18 / API26 d.ts（`@ohos.window`、`bundleManager`），设备 HAD-W32 / OpenHarmony 7.0.0.109–111 / 2in1。**未改码**；工作量级 S/M/L ≈ 天 / 周 / 月。
> 上游边界：`2026-10-05-ohos-platform-limitations.md` E2（真多窗未实现，单窗+同窗弹窗降级）；backlog #25；ArkWeb 矩阵 #13（`onWindowNew` 未接）。

## 1. 平台能力（API 面 × 权限）

| 路线 | API | ACL/权限 | 备注 |
|---|---|---|---|
| 同 ability 子窗 | `WindowStage.createSubWindow(name)`（API 9+）/ `createSubWindowWithOptions`（API 11+）→ `Window.setUIContent` | 无 | 应用内多窗，最小可行；子窗随主窗生命周期 |
| 主窗自由化 | `WindowStage.isInFreeWindowMode()` + `'freeWindowModeChange'`；ability `supportWindowModes:[FULLSCREEN,SPLIT,FLOATING]`（`StartOptions` / `setSupportedWindowModes`，SessionManager @15+） | 无（2in1/平板能力） | 用户拖拽/最大化/分屏；手机域不保证 FLOATING |
| 系统独立窗 | `window.createWindow({ windowType: TYPE_FLOAT })` | `ohos.permission.SYSTEM_FLOAT_WINDOW`（系统级，permissions.d.ts） | 三方应用默认不可用（`801 Capability not supported`） |
| 第二 UIAbility 窗 | `startAbility` + `StartOptions.windowMode`/`supportWindowModes`；ability `launchType: "multiton"` | 无 | 独立任务栈窗；壳/宿主切换与返回栈成本中等 |

## 2. MAUI 切片现状（单窗边界）

- 壳 `EntryAbility.ui.ets` 只 `windowStage.loadContent('pages/Index')` 一个主窗；`module.json5` 未声明 `supportWindowModes`/子窗。
- `OpenHarmonyMauiAppHost` 持单个 `_window` / `OpenHarmonyWindowSurface` / `OpenHarmonyWindowRenderer`；`OpenHarmonyApplicationHandler` 的 OpenWindow 只诚实降级（`CurrentWindowKept`），其文件头已列真多窗三前置：① `ohos_host_open_window/close_window` 平台窗桥 + 第二 XComponent 面；② 按 window id 的 host/surface/renderer/输入路由；③ 按窗生命周期（Created/Activated/Resumed/Stopped/Destroying 带窗 id）。
- 现有输入已用窗口坐标（`GetTouchPointWindowX/Y`，`2026-10-01-ohos-injected-touch.md`），但 overlay 槽池/避让区/a11y 均为进程级单实例。

## 3. 方案与工作量

- **A0 2in1 形态适配（S）**：壳声明 `supportWindowModes`（FULLSCREEN+SPLIT+FLOATING）并接 `windowSizeChange`/`freeWindowModeChange` 转发 → slice 更新 Window 尺寸/布局（现有 arrange 已按 surface 尺寸，接事件即可）；不改 OpenWindow 语义，不动宿主契约。
- **A1 应用内子窗（M）**：`createSubWindow` + 第二 NodeContent/页面 + 宿主 per-window surface/renderer（host 状态按窗 id）；`OpenWindow` 映射到子窗；overlay 槽池按窗分区或 `(windowId, slot)` 编码；壳需新增子窗页面/生命周期桥。
- **B 真·OpenWindow 多窗（L）**：A1 + 平台窗桥（`ohos_host_open_window/close_window`）+ `multiton` 第二 UIAbility 窗 + 每窗生命周期/输入/焦点/a11y/软键盘/避让区隔离 + WebView/CEF overlay 池按窗重建；量级 = A1 的 3–5×。

**建议**：先 A0（S，风险最低，立即让 2in1 自由窗/分屏可用）；A1 作为 OpenWindow 语义升级第一刀；B 待窗口管理语义（freeWindowMode 限制、子窗数量上限、`setSupportedWindowModes` syscap）确认后再排。

## 4. 风险 / 未验证

- 子窗数量上限、子窗↔主窗 z-order/焦点/软键盘、`setSupportedWindowModes` 在手机/部分镜像返回 `801` 均未真机验证（需 2in1 + 手机两态判定卡）。
- overlay 槽池进程级单池：多窗共享会跨窗抢占；多窗下 CEF/ArkWeb overlay 的输入命中与 z-order 需重验。
- 单设备（HAD-W32 2in1 / debug 域）结论不能外推手机/release；a11y/像素/输入回归需新增多窗判定点。
