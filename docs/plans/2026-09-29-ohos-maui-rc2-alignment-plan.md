# MAUI rc2 对齐就绪评估与执行清单（2026-09-29）

> 只读评估（不切包、不改代码）：为窗口期把 maui-ohos 切片与 harness 从 MAUI rc.1 线对齐到 rc.2 线准备执行清单。
> 触发口径（主会话结论）：**backlog 收敛后 + 四仓一次性 + 捆 kit #34**。
> 证据/产物：`/data/storage/el2/base/tmp/opencode/maui-rc2/`（fetch 日志、rc2 变更清单、merge-tree 原始输出、三方合并样本）。

## 1. 上游 rc2 就绪：是

| 项 | 值 |
|---|---|
| 分支 | `dotnet/maui` `release/11.0.1xx-rc2` |
| tip | `349017b7d3e0…`（2026-09-29T10:44:53Z；`net11.0 → rc2` 自动合并 #38980） |
| 版本面 | `Major 11 / PreRelease rc / iteration 2`，`SdkBandVersion 11.0.100` |
| rc1 对照 | `release/11.0.1xx-rc1` tip `484132f9e51f…` |
| 包 | dnceng `dotnet11`：`11.0.0-rc.2.26478.12`（Controls/Core/Graphics/WebView.Maui 同版，最新 daily）；nuget.org 仍只有 `11.0.0-rc.1.26451.6` |
| fork 基线 | `1cd2e15b`（2026-09-15，#38564）是 rc2 祖先（ahead=779 / behind=0） |

## 2. fork delta（maui-ohos `feature/openharmony`）

- 载体设计：首个提交 `e55e1e27` 将上游全树收缩为切片（删 26,317 / 加 23）；分支实际跟踪 **136 文件** = 125 切片 `.cs` + csproj/README + 3 docs + 4 修改 + PublicAPI 2；工作树其余全量文件为未跟踪（构建用）。
- rc2 相对基线的改动：3,449 路径（1,675 M / 613 A / 1,161 D）。
- `git merge-tree --write-tree refs/remotes/upstream-rc2/tip feature/openharmony`（2026-09-29）：**1,672 modify/delete + 1 content = 1,673** 冲突项；前者是载体删除与 rc2 改动的交叉（重放无意义，属噪声）。
- **真冲突面 = 3 文件**（fork 保留 ∩ rc2 改动）：`Directory.Build.props`（1 内容块，需手解）、`src/Core/src/Core.csproj`（自动合净）、`src/Workload/Microsoft.NET.Sdk.Maui.Manifest/WorkloadManifest.in.json`（自动合净）。
- 对齐手段 = **rc2 全树 + 136 文件 delta 应用**；merge/rebase 不可行（首个提交的 26k 删除会被重放）。

## 3. 包清单 diff（rc1 → rc2）

| 包 | 现状（rc1） | 目标（rc2 候选） |
|---|---|---|
| Microsoft.Maui.Controls / Core / Graphics / AspNetCore.Components.WebView.Maui | `11.0.0-rc.1.26451.6`（nuget.org；本地缓存已有） | `11.0.0-rc.2.26478.12`（dnceng `dotnet11`；正式 pin 待 RC2 定版/上 nuget.org） |

需改：8 个 csproj、19 处 pin（无 `Directory.Packages.props`，版本内联）——
- maui-ohos：`src/Core/src/Platform/OpenHarmony/Microsoft.Maui.Platform.OpenHarmony.csproj`（4）
- ohos-workload：`src/Microsoft.OpenHarmony.Maui.Graphics/…csproj`（1）+ `test/headless-render(3)`、`hello-app(1)`、`hello-maui-app(3)`、`hello-maui-razor(3)`、`hello-maui(1)`、`maui-platform-verify(3)`
- 源：两仓均无 `dotnet11` 源（rc2 未上 nuget.org）→ 演练期本地 NuGet.config 增源
- 同 pin 引用：`README-openharmony-slice.md`、`docs/openharmony-slice-notes.md`、切片 `README.md` 与 4 个 `.cs` 头注释（KeyListener/ToolTipManager/WindowOverlay/BlazorWebView）

## 4. 影响面与风险

- 切片（125 `.cs`）：rc2 改动面 Core/src 189、Controls/src 358、Graphics/src 14、BlazorWebView/src 36、PublicAPI 58 文件；编译期 API 漂移落在 Controls/Core 公共面（"verified against rc.1" 的 4 处最可能先报错），精确清单由门禁 1 的编译输出给出。
- harness/套件（当前 **489/469**；HEAD 485/465 + 在途 +4）：门禁为 ≥ floor；rc2 行为漂移（文本度量/几何/默认样式）可能需逐条归因与新 pin。
- 依赖顺序：runtime/aspnetcore/sdk 的 rc.2 已完成、发布并经设备验证（见 `2026-09-28-rc2-conflict-sharding-plan.md` §6，bundle preview.28）→ **MAUI rc2 是第四仓**；不阻塞前三仓，但 kit #34 出包前须完成。
- 风险：① 26478.12 是 daily build，官方 RC2 pin 未定；② 行为漂移量不可预知；③ 捆绑 kit #34 时 bundle/hap 需随 rc2 重打一次（协调 tester 空档）。

## 5. 执行清单（影子分支、一次性）

1. maui-ohos：`git worktree add <scratch> -b fix/ohos-maui-rc2 refs/remotes/upstream-rc2/tip`。
2. 应用 delta：131 新增照搬 + 4 修改三方合并（`Directory.Build.props` 手解 1 块，其余自动）→ 单提交「slice on rc2」。
3. 按 §3 改 19 处 pin + 文档/注释；本地 feed 配置（不入上游）。
4. 门禁 1（离设备）：切片独立编译 `0 error / 0 IL2026/IL3050`；交互 harness ≥ **489/469**；API 修复回灌切片。
5. 门禁 2（设备）：`hello-maui-app` JIT + AOT 打包与本机冒烟（kit #34 资产基线）。
6. 全绿：`feature/openharmony` 快进（旧 tip 打 backup tag），随 kit #34 出包；失败：丢弃影子分支（pin 不动，rc1 可复现）。

触发窗口：
- **A（默认）**：backlog 收敛后 + 四仓一次性 + 捆 kit #34（主会话结论）。
- **B（提前）**：rc2 正式包上 nuget.org 且含影响切片的修复 → 先对齐、仍捆 #34。
- **C（顺延）**：kit #34 撞 tester 轮 → 移至 #34 后作 #35 首项（避免 bundle 重打两次）。
- **D（应急）**：rc2 行为漂移阻塞门禁 → 只 cherry-pick 所需 rc1 修复，整线顺延。
