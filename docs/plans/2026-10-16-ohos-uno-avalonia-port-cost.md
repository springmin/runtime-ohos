# Uno Platform / Avalonia 支持 OpenHarmony 的移植代价研究（2026-10-16）

> 结论：**两者都可行且代价可控，远低于 MAUI 移植**——Avalonia **有真实先例**（社区单人已在真机跑通，后归档），
> 基于本仓现有 OHOS 资产（壳 / host / IME / 剪贴板 / a11y）**beta ≈ 1–3 人月**；Uno **无先例**但架构有
> Host Builder 缝（与其 X11/Framebuffer 宿主同型），**beta ≈ 2–5 人月**。二者成本量级都来自同一原因：
> **单画布 Skia 渲染 = 无 per-control handler**（与 MAUI 的 140 文件 / 1+ 年团队形成对照）。
> 对 ECM（WinForms）不改变既有结论（三者都需重写 UI）；若目标是"WPF 存量上 OHOS"，**Avalonia（XPF 线）价值最高**、Uno 次之（XAML 保留度最高）。

## 1. 关键证据（联网核实）

### 1.1 Avalonia
- **官方无支持计划**：讨论 #14019（2023）/ #17060（2024），官方回复（2025）"no changes to our supported platforms"；
  社区共识：需要 .NET + Skia + 输入三条先打通。
- **真实先例 `OpenHarmony-NET/OpenHarmony.Avalonia`（CeSun，2025-02 真机可运行）**：后端文件清单证明**平台缝很窄**——
  `TopLevelImpl` / `XComponent` / `OpenHarmonyFramebuffer` / `OpenHarmonyInputMethod` / `OpenHarmonyPlatformThreading` /
  `OpenHarmonyRenderTimer` / `CustomFontManagerImpl` + `Entry`（注册 XComponent/NAPI）。
- 其运行时方案 = **NativeAOT**（HarmonyOS NEXT ≥5.0.0(12) 禁匿名可执行内存 → 无 JIT；mono 解释器性能不足；musl 兼容 →
  `linux-musl-arm64` .so + dlopen/dlsym + P/Invoke/NAPI；跨平台 AOT 用 `PublishAotCross`）。
- **归档事件**：OpenHarmony-NET 组织公告（2025 春节）——与华为的合作谈判未成、项目全部停更归档；华为侧走竞标，
  Avalonia-HarmonyOS 适配由外包公司接盘（转闭源，未来或以 SIG 名义开源）→ **该赛道存在真实商业需求**。

### 1.2 Uno Platform
- **无任何支持或先例**（issue #15808 / #19154 仅请求）；官方口径".NET 须先在 OHOS 跑起来"——**这一前提本仓已完成**。
- 架构缝 = Skia 渲染器（iOS/Android/macOS/Windows/Linux-X11/Linux-Framebuffer/WASM）+ `UnoPlatformHostBuilder`
  （其 Framebuffer 宿主证明"最小宿主、无 OS API"亦可启动）。

### 1.3 Skia 原生（两者共同前置，也是唯一新增 native 件）
- **OpenHarmony 源树自带 `third_party_skia`（m133）** → 可编；
- **SkiaSharp 已随包提供 `linux-musl-arm64` 原生资产**（Alpine 变体，musl ABI 与 OHOS 同源；CeSun 的运行时正吃这条）；
- 本仓核查：我们栈内**无 Skia**（`OpenHarmonyCanvasBackend` = host canvas 自绘）→ 需一次引入。

### 1.4 背景：为什么先排除"移植 WinForms"（对照基线）
代际（Framework→CoreCLR 无 WinForms 实现）、UI（DevExpress/GDI+ Windows 独占）、桥接（无 Mono/Wine/X11）三重墙；
且 System.Drawing.Common 非 Windows 自 .NET 7 起被官方移除（libgdiplus 已归档）→ 不在候选。

## 2. 代价分解

### 2.1 Avalonia（推荐优先）
| 工作项 | 复用度 | 估时 |
|---|---|---|
| 表面（XComponent / 宿主 surface） | **复用本仓壳 + host** | 已有，接线 ≈1 周 |
| 输入（指针 / 键盘 / IME） | 复用本仓 input / IME wire | 1–2 周 |
| 渲染回路（Skia 软件光栅→native buffer；进阶 GL/EGL） | Skia 资产直试 / 必要时 OHOS 工具链编译 | 2–4 周 |
| 服务（剪贴板✓ / 存储选择器 / 对话框 / DPI / Dispatcher→壳事件循环 / 字体） | 剪贴板已复用 | 2–4 周 |
| **beta 合计** | — | **≈1–3 人月** |
| 后续波次（a11y 走本仓 a11y 桥 / 多窗 / WebView / 打印） | 桥可复用 | 每项 1–4 周 |

### 2.2 Uno Platform
```
同 Skia 前置 + 新 Host（对照其 X11/Framebuffer host 形状）+ WinUI 一致性所需平台服务
（FileOpenPicker / 通知 / WebView / 传感器…其"逐平台缺口矩阵"模式）
beta ≈ 2–5 人月；服务补齐按客户需要递增
独有优势：**WPF XAML 资产保留度最高**（逐屏迁移、可增量、AI-assisted 流程成熟）
```

## 3. 与 MAUI 移植对照（本仓标尺）与关键利好
| | MAUI（已做） | Avalonia（拟） | Uno（拟） |
|---|---|---|---|
| 平台面 | **per-control handlers（42 控件 + 全能力，140 文件 / 多波 / 1+ 年）** | 宿主 + ≈10 类（有先例清单） | 宿主 + WinUI 服务面 |
| 渲染 | host canvas（自绘） | 单画布 Skia | 单画布 Skia |
| 新增 native | 无 | Skia（musl 资产可直试） | Skia（同） |
| 既有资产复用 | — | **壳 / host / IME / 剪贴板 / a11y 全复用** | 同 |
| **估时** | 1+ 年（团队） | **1–3 人月** | **2–5 人月** |
| 先例 | 本仓 | CeSun（单人，已归档） | 无 |

> 关键利好：CeSun 受困的"无 JIT→只能 NativeAOT"是 **HarmonyOS NEXT 商用机**限制；本仓目标（OpenHarmony 2in1 dev 镜像）
> **JIT 在 debug 域可用**（见 `2026-10-05-ohos-platform-limitations.md` A1–A5）——Avalonia/Uno 可直接跑本仓 CoreCLR，
> 省掉其 PublishAotCross 绕行（对齐 AOT 亦在，line 与 MAUI 一致）。

## 4. 建议与风险
- 只服务 ECM → **不移植框架**：MAUI/Blazor 重托管（见 `2026-10-16-ohos-ecm-migration-analysis.md`）。
- 战略目标"WinForms/WPF 存量上 OHOS"：
  ① **Avalonia 优先**（先例 + 缝最窄 + **XPF 二进制兼容线**（WPF 三方控件不动）可谈商业支持；华为已发标=市场存在）；
  ② Uno 次之（仅当客户 WPF 资产重、必须保 XAML）；
  ③ 两者均 MIT：可自研 / 可上游 / 可赞助；与本仓 MAUI 共享同一 OHOS 底座（壳/host/IME/a11y）——做任一后端=底座价值再放大。
- 风险：上游不接纳非官方平台（需自维护 fork 与升级跟进）；Skia 在 OHOS 的 GL/字体细节；a11y/多窗/WebView 为后置波次；
  HarmonyOS NEXT 商用机若为目标则回到 NativeAOT-only 故事线。

## 5. 方法与来源
- 联网：Avalonia 讨论 #14019/#17060 · `OpenHarmony-NET/OpenHarmony.Avalonia`（提交/文件结构）· OpenHarmony-NET 组织公告 ·
  Uno issue #15808/#19154 + Skia 渲染器/宿主文档 · `openharmony/third_party_skia`（m133）· SkiaSharp 原生构建文档
  （linux-musl-arm64 资产 / GN 参数）· dotnet/designs system-drawing-win-only 与 Mono libgdiplus 归档状态。
- 本仓核查：`Microsoft.OpenHarmony.Maui.Graphics/OpenHarmonyCanvasBackend.cs`（host canvas，无 Skia）；设备库权限与 GL 路径实测。
