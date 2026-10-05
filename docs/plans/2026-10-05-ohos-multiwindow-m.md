# 应用内子窗 MULTIWINDOW-M 落地报告（建议 4-1，2026-10-05）

> 口径：kit #48 基座 + 本切片；设备 HAD-W32 / OpenHarmony 7.0.0.109 / API 26 / 2in1（内核模式 2090×1394 自由窗测，60fps 维持）。走预研 A1（M）第一刀：主窗 `Window.createSubWindowWithOptions` 无 ACL 路径；`TYPE_FLOAT`/`SYSTEM_FLOAT_WINDOW` 系统窗未使用（仍不可达）。**硬降级（如实）**：管理侧仍是单 surface/renderer，子窗内容为壳侧 ArkUI 自绘（named-route 页），不是第二个 MAUI 视觉树；per-window surface/renderer 属 L（见末节余量）。

## 落地范围

- **壳（ow）**：`Index.ets` 子窗控制器 —— 命令 0 create/1 move/2 resize/3 show/4 hide（无公开 hide API：如实回 Failed 801）/5 close，事件 0 created…10 resumed；`pages/SubWindow.ets`（routeName `ohos_dotnet_subwindow`，`import './SubWindow'` 注册；拖拽自移动带 `WindowProperties.name` guard，触摸/拖动 hilog）。主窗 HIDDEN/SHOWN → suspended/resumed 转发 + 挂起期命令抑制；无子窗零分配（只在 create 建窗）。
- **宿主**：`host_napi.cpp` 新增 `ohos_host_sub_window_command`（op 99 = 可用性探针）与 `ohos_host_sub_window_event_listener`（shell→managed），NAPI `registerSubWindowSink`/`notifySubWindowEvent`；`host-exports.txt` 151→**153**（`check-host-exports.py --cross-check` 绿，`build-host.sh` 门绿）。
- **切片（maui `feature/openharmony`）**：`OpenHarmonySubWindow`（命令/事件状态机：IsSupported/IsOpen/IsVisible/IsSuspended/IsContentReady/WindowId/Bounds + Changed/Touched；`Utf8JsonWriter`/`JsonDocument`，AOT 安全；离设备/旧宿主退化 false/无操作）。
- **构建**：`build-arkts-shell.sh` ui 项目 main_pages 双页 + SubWindow 复制/来源哈希/字面量；abc **414,532 B / `e016db13…`**（headless 24,324 / `798b2477…`）同步 preview.22/23/24/28，provenance 四包一致。

## 断言与套件（只增）

- 套件 +6：命令集与 JSON、生命周期/几何状态机、触摸事件、畸形/未知事件鲁棒、离设备退化、壳/宿主/切片源码 + 四包 identity → **`checks=607 total=609 floor=589`**、0 Unhandled、perf/a11y within=True。
- 切片 0 IL：standalone `IsAotCompatible+EnableTrimAnalyzer+EnableAotAnalyzer -warnaserror:IL2026,IL3050` → Build succeeded / 无 IL 警告；样例 AOT publish（kit 配方 `CompressSymbols=false`）rc=0 且 **0 × IL2026/3050/3051**。

## 真机证据（签名基座 + 本侧 abc/payload 重打包；scratch `multiwin-m/`）

- managed 深链 `app://subwindow/demo`：create **id=344 (120,160 720×480)** → page ready `name=ohos_dotnet_subwindow drag=on` → move **420,360** → resize **900×600** → close；每步 shell hilog + 主页面状态行，截图 `mw-seq1/2/3`。
- 内容/交互：`app://subwindow/open`（id=346）后设备点击 → `OHOS_MAUI_SUB touch #57`（down/up 坐标）；`uiInput swipe` → `drag #51 -> 269,259`（PanGesture 自移动；截图 `mw-drag`）。
- 协同/回归：主窗 HIDDEN/SHOWN → `subwindow suspended/resumed`；主页面正常出画，`canvas presented (2090×1324) avg=16ms max=21ms`（60fps），无新 fault；close 后子窗消失。
- 未测：`freeWindowModeChange` 真形态、手机域、多子窗上限、子窗 a11y 树（壳内容不进 MAUI a11y 树——单 surface 的边界）。

## L 余量（真·OpenWindow 多窗 ≈ A1 的 3–5×）

- **per-window renderer/surface/输入/a11y**：现单 `OpenHarmonyWindowSurface`/`Renderer`；子窗要渲染 MAUI 内容需 host/surface/renderer 按 window id 分片（L 第一前置）。
- `ApplicationHandler.OpenWindow` 仍未映射（诚实单窗）；overlay 槽池、避让区、软键盘、CEF/ArkWeb 按窗分区；`multiton` 第二 UIAbility 窗与 `ohos_host_open_window/close_window` 平台桥未做。子窗容量/软键盘/焦点与主窗 z-order 需 L 判定卡。

> 提交：maui `b093e33825`（OpenHarmonySubWindow）、ow `be70a73`（壳+宿主+harness+样例+四包 abc）+ `16df9a3`（子窗页注释修正，abc 字节不变）、本文（runtime-ohos）。设备脚本/日志/截图留在 scratch（未入库）。
