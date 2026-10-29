# MAUI 上游差异清单（UPSTREAM-DELTA，2026-10-28）

> 口径：`maui-ohos` `feature/openharmony` tip `868d3c8727b`（2026-10-19，merge of
> `dotnet/maui` `d32b7992870` = `release/11.0.1xx-rc2`）。本文只做**离线只读度量**，不构建、不上设备。
> 目的：把“长期 fork 的同步成本”从感觉变成数字，作为 P0 计划
> `2026-10-28-ohos-maui-p0-execution.md` 的输入。

## 1. 总量（相对 rc.2 上游基线）

| 指标 | 数值 |
|---|---|
| 变更文件 | **152** |
| 新增 / 修改 / 删除 | **148 / 4 / 0** |
| 行数 | **+50,766 / −3** |
| 平台切片文件 | **143**（`src/Core/src/Platform/OpenHarmony/**`） |
| 平台切片代码行 | **48,176** |
| 切片起点 | `c7f92a6088f`（2026-09-30，re-anchor 到 rc.2） |

**结论：99.9% 是纯新增（additive）**；对上游文件的侵入只有 4 个，且合计 **+77 / −3**。
理论上，每次上游同步的冲突面就集中在这 4 个文件，而不是 48k 行。

## 2. 侵入面（仅 4 个文件）

| 文件 | +/− | 作用 |
|---|---|---|
| `Directory.Build.props` | +37 / −3 | 平台 TFM 与构建常量接线 |
| `src/Core/src/Core.csproj` | +18 / 0 | TFM 条件、源引入、包引用 |
| `src/MultiTargeting.targets` | +15 / 0 | 多目标分派（`net-openharmony`） |
| `src/Workload/Microsoft.NET.Sdk.Maui.Manifest/WorkloadManifest.in.json` | +7 / 0 | workload manifest 增加平台项 |

另有两个 **新增**（非修改）公开 API 文件：
`src/Core/src/PublicAPI/net-openharmony/PublicAPI.Shipped.txt` /
`PublicAPI.Unshipped.txt`。

## 3. 切片构成（143 文件）

| 类别 | 文件数（近似） | 代表 |
|---|---|---|
| Handler | **45** | Button / Entry / CollectionView / Shell / WebView / MediaElement … |
| Window / 多窗 | **8** | `OpenHarmonyWindowHost` / Surface / Renderer / InputRouter / Decoration |
| App / 生命周期 | **5** | `OpenHarmonyMauiAppHost` / Application / Dispatcher |
| Web / Blazor | **6** | WebView / HybridWebView / BlazorWebView / WebAuthenticator / Loopback |
| Shell / 导航 | **6** | Shell / Flyout / Chrome / NavigationPage / TabbedPage |
| 其余 | ~73 | Essentials、传感器、媒体、SecureStorage、a11y、手势、字体、主题… |

## 4. 同步策略（建议）

| 事件 | 动作 | 时限 |
|---|---|---|
| 上游 `release/11.0.1xx` 有新提交 | 合并到 `feature/openharmony`，只处理 4 个侵入文件的冲突；跑套件 | 每周一次 |
| 上游 `main`（下一版本预览） | 月度合并；只做编译修复，不追新特性 | 每月 |
| **.NET 11 / MAUI 11 GA** | 重 pin 四包 + 全量套件 + 真机冒烟 | 发布后 48h |
| 安全修复 | 随时 cherry-pick | 24h |

复现命令：

```bash
cd /storage/Users/currentUser/springsources/maui-ohos
BASE=d32b7992870   # 当前 rc.2 上游基线；每次同步后更新
git diff --shortstat "$BASE"..HEAD
git diff --name-status "$BASE"..HEAD | cut -f1 | sort | uniq -c
git diff --numstat "$BASE"..HEAD -- \
  Directory.Build.props src/Core/src/Core.csproj \
  src/MultiTargeting.targets \
  src/Workload/Microsoft.NET.Sdk.Maui.Manifest/WorkloadManifest.in.json
git ls-files 'src/Core/src/Platform/OpenHarmony/**' | wc -l
```

## 5. 风险与判读

- **4 个侵入文件是同步风险的全部**：其中 `Directory.Build.props` 最容易冲突（上游经常改），
  应保持我们的改动为“末尾追加 + 条件包裹”，不要重排原有内容。
- **`MultiTargeting.targets` / workload manifest** 与 SDK/工作负载版本强耦合，RTM 时优先复核。
- **PublicAPI 文件**是新增文件，不构成冲突，但每次上游 API 基线更新需要重新生成/对齐。
- 299 个提交数会包含 merge 带入的上游历史，**不能**当作切片工作量；按路径统计，
  切片自 2026-09-30 起只有 **72 个提交**触及 `Platform/OpenHarmony`。

## 6. 后续

- 本清单进入 P0 计划 Task 1；T2–T4（第三方库兼容、Reference App、性能门禁）见
  `2026-10-28-ohos-maui-p0-execution.md`。
