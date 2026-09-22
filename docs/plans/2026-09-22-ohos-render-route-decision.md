# 渲染路线决议：保持自绘合成器路线（2026-09-22）

**Date:** 2026-09-22
**Status:** 决议记录（PJ4）——MAUI OpenHarmony 平台切片的渲染/交互架构保持**自绘合成器**，不切换到原生 ArkUI 控件路线
**Related:** `2026-09-16-maui-ohos-feasibility.md`（三条路线与分期）、`2026-09-22-ohos-maui-coverage-matrix.md`（覆盖矩阵）、`2026-09-19-ohos-arkts-handover-status.md`（宿主/无障碍契约）、`maui-ohos/docs/openharmony-platform-slice.md`（切片现状）

## 决议

**继续自绘合成器路线。** 单个 ArkUI `XComponent`（壳内 id `ohos_dotnet_surface`）承载全部托管 UI：
compositor（`OpenHarmonyWindowRenderer`）用 `Microsoft.Maui.Graphics` canvas 自绘整棵树，每个 MAUI 元素
由切片自己的平台视图（`OpenHarmonyView`）与列表 materializer（`OpenHarmonyItemListMaterializer`）承载
测量/排布/命中状态，无障碍经影子节点树（`OpenHarmonyAccessibility`）发布给宿主/ArkUI provider。
**不采用**「每个控件一个原生 ArkUI NDK 节点」的路线（NodeContent 树 + 逐控件映射重写）。

## 理由

1. **现有路线在 API 层已广且接近完整**：41 个 handler 注册项（页面/导航/Shell、列表与滚动、Shapes、
   WebView 族、手势、无障碍、Essentials；其中 BlazorWebView 为构建门控），离设备校验基线
   `ohos-workload/test/maui-platform-verify` **288 条 `[verify]`（floor 268）全绿**。切换会把上述覆盖与
   证据全部作废。
2. **原生路线是 L+ 级重构，不是补丁**：需按控件重建测量/排布、虚拟化、命中、焦点/键盘、无障碍与主题映射，
   等于把现在共享的 compositor/renderer 层拆成 41 份平台映射。可行性分析中该路线（P2 原生控件后端）
   估算 3–6 个月 × 2–4 人。
3. **MAUI 测量契约与 ArkUI 约束布局存在硬阻抗**：MAUI handler 以 `GetDesiredSize` + 显式 frame 驱动，
   ArkUI 节点由父容器约束/声明式规则布局；两者无法一一对应，强制映射会产生「测量-排布」双源真相与难以
   收敛的布局偏差。自绘路线天然让 MAUI 布局成为唯一真相。
4. **UX 深度投入已按合成器模型落地**：样式文本、paint-aware Shapes、帧驱动 Dispatcher、软键盘安全区、
   焦点桥等都已离设备验证；掉头成本远高于在现有路线上继续补齐（见下）。

## 代价：原生路线「免费」的 UX 深度现在必须自实现

| 能力 | 现状（2026-09-22） | 说明 |
|---|---|---|
| 动画循环 / 惯性滚动 / 滚动条 / 焦点环 | **PJ1 进行中** | 焦点环已落地（`OpenHarmonyFocusManager`：非文本 `Focus()/Unfocus()` 路由 + 独占焦点语义）；帧驱动动画循环与惯性物理在工作树（`OpenHarmonyAnimationLoop`、`OpenHarmonyScrollPhysics`），未提交；滚动条未开始 |
| Tooltip / 键盘快捷键 | **PJ2 进行中** | 硬件键事件的内部面已落地（`OpenHarmonyKeyListener`：`KeyDown/KeyUp`、`Dispatch()`）；tooltip 与 accelerator 映射尚未开始 |
| 文本编辑细节 | 未开始 | Entry/Editor/SearchBar 已有文本、占位、焦点桥、软键盘与安全区内边距；选区/光标手势、系统编辑菜单、IME 组合与候选窗等平台细节仍缺 |
| 窗口 overlay | 未开始 | 切片无 `IWindowOverlay` 实现；需要把 overlay 绘制接到合成器帧路径 |
| 阴影 | 部分（仅画布层） | workload 绘图后端已实现 `ICanvas.SetShadow`；MAUI 视图级 `Shadow`/`IShadow` mapper 未接 |

这份清单就是路线切换的**持续成本**：每一项都是「走原生节点会由 ArkUI 自带」的能力。

## 混合路线（保留的未来路径）

宿主桥同时提供 `OpenHarmonyBridge.NodeContent`（ArkUI `NodeContent` 嵌入点），因此未来可按控件混合：
以单 XComponent 合成器为主，只把个别能力换成语义化原生节点（ArkWeb 已是原生节点路径）。触发条件：
某个 UX 缺口在自绘路线上的成本显著高于原生节点，且混入不破坏「MAUI 布局为唯一真相」。当前不启动。

## 路线无关：设备 bring-up

设备 bring-up 链与渲染路线**无关**：hap 签名/安装 → 壳 abc 入口 record 与字节码版本 → 宿主 `.so` dlopen →
hostfxr 启动 → 表面握手/首帧，两种路线完全相同。三个启动阻塞已由 kit #12 修复，真机复测在测试方手上；
本决议不改变 bring-up 队列，也不改变套件/像素基线。

## 参考

- 三条路线与分期：`2026-09-16-maui-ohos-feasibility.md`
- 覆盖矩阵与切片/套件 pin（写作时 284 条，其后 `maui-platform-verify` 基线升至 288 条）：
  `2026-09-22-ohos-maui-coverage-matrix.md`
- 宿主契约与 D 批次：`2026-09-19-ohos-arkts-handover-status.md`
- 切片现状与验证入口：`maui-ohos/docs/openharmony-platform-slice.md`
- 启动阻塞与 kit 轨迹：`2026-09-22-ohos-startup-crash-rootcause.md`、`2026-09-21-ohos-crash-probes.md`
