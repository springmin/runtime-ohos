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

## 5) A0 形态适配实现（MULTIWINDOW-S，2026-10-05）
- 切片（maui `ed02203bfd`，已推 `feature/openharmony`）：`OpenHarmonyMauiAppHost.CanArrangeSurface`（Created/Changed 且尺寸>0；Destroyed/0x0 保留末帧）+ Changed 分支 re-arrange/render/`WriteStatus "[maui] window size WxH"`；无新宿主导出；standalone Release + trim/AOT analyzer **0 error / 0 IL**。
- 壳（ow `c5df1de`，已推 `master`）：`module.json.template` 四包（22/23/24/28）声明 `supportWindowModes:["fullscreen","split","floating"]`；`Index.ets` 订阅主窗 `windowSizeChange`/`freeWindowModeChange`（日志 `[maui] window size change: WxH free=…`，并 `reportWindowAvoidArea` 重读避免区），disposer 解注册。abc **375,268 B / `9cd2b4c3…`**（headless 24,324），provenance 四包同步；`--check-sources`/`--check-pack-abc` 绿。
- 套件 +2（只增）：surface arrange gate（Created/Changed 真、Destroyed/0x0 假）+ Changed replay 后窗口帧跟随、Destroyed 保留 → `checks=597 total=599 floor=579`（declared==printed，perf/a11y within=True，0 Unhandled）。
- 真机（HAD-W32 / OpenHarmony 7.0.0.111 / 2in1；签名有效基座 + 本侧 payload/abc 重打包）：窗口最大化 2090x1394 → 3120x1955；`surface: state=Changed 3120x1885` → `canvas presented (3120x1885)`（重排重绘）→ 壳 `window size change: 3120x1955 free=true` + 切片 `[maui] window size 3120x1885`；A11Y 自检 `accessibilityStatus: 1 / nodeCount 70`、无新 fault。回归交互通过。
- 不足 / 后续：`freeWindowModeChange` 与 split 真形态、手机域未测（S 项按设计仅形态响应）；**M（应用内子窗）已随 kit #49 落地**（见 `2026-10-05-ohos-multiwindow-m.md`：壳 `createSubWindowWithOptions` 子窗 create/move/resize/close + 主窗 HIDDEN/SHOWN 协同；真机 `app://subwindow/demo` id=344 720×480→420,360→900×600→close）；L（真 OpenWindow 多窗：per-window renderer/surface/输入/a11y）按预研排期。

> kit #49 发布回填（2026-10-05）：M（应用内子窗）随 kit #49 交付（maui `b093e33825` + ow `be70a73`/`16df9a3`；真机 `app://subwindow/demo` id=344 720×480→420,360→900×600→close；壳 abc 414,532 / `e016db13…`、套件 607/609 floor 589、发布实测 tar 67,888,851 / `477974bb…`）；tester 复测 = `2026-10-05-ohos-tester-handoff-kit49.md` §2 主判点 1；平台边界见 `2026-10-05-ohos-platform-limitations.md` E2（S+M 已落地，L 余）。
>
> kit #48 发布回填（2026-10-05）：S 随 kit #48 交付（壳 abc 375,268 / `9cd2b4c3…`、套件 599/601 floor 581、发布实测 tar 67,735,148 / `5c22704f…`）；tester 复测 = `2026-10-05-ohos-tester-handoff-kit48.md` §2 主判点 4；平台边界见 `2026-10-05-ohos-platform-limitations.md` E2。
