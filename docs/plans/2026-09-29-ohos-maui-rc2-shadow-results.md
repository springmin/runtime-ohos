# MAUI rc2 影子分支对齐结果（2026-09-29 执行）

> 执行 [`2026-09-29-ohos-maui-rc2-alignment-plan.md`](2026-09-29-ohos-maui-rc2-alignment-plan.md)。方法 = rc2 全树 + 138 文件 delta；不 merge/rebase。
> 影子分支（**未合并 feature/openharmony、未建 kit**）：maui-ohos `fix/ohos-maui-rc2` = `41ec9901`；ohos-workload `fix/ohos-rc2` = `b531cc98`。
> scratch 证据：`/data/storage/el2/base/tmp/opencode/rc2-align/`（logs/、packages/、slice/ 编译车辆、EVIDENCE.md）。

## 1. delta 应用（maui-ohos `41ec9901`，3 提交）

| 项 | 结果 |
|---|---|
| 上游 | `dotnet/maui` `release/11.0.1xx-rc2` tip `349017b7`（ls-remote 复核未动） |
| 载体 | 138 文件 = 134 新增照搬（127 切片 `.cs` 等）+ 4 修改三方合并（相对 rc2 祖先 `1cd2e15b`） |
| 真冲突 | 3 文件：`Directory.Build.props` 手解 1 块（保留 OpenHarmony 平台属性，删 rc2 已移除的 `COMPATIBILITY_ENABLED`）；`Core.csproj`、`WorkloadManifest.in.json` 自动合净；`MultiTargeting.targets` 照搬 |
| 补丁 | 首个切片编译报 CS0246 ×5：eval 快照 136 文件清单缺 T18/N6 两文件（`OpenHarmonyMapLauncher.cs`、`OpenHarmonyWindowDecoration.cs`，fork 现今 138 文件）→ 提交 3 补入 |

## 2. pin 对齐（`11.0.0-rc.1.26451.6 → 11.0.0-rc.2.26478.12`）

- maui-ohos：切片 csproj 4 处 + 文档/头注释 10 处（3 docs + 切片 README + 4 个 `.cs`）= 14 处 / 8 文件。
- ohos-workload：7 csproj 15 处（Graphics 1 + 6 个测试工程）。
- 演练期 feed：rc2 daily 未上 nuget.org，restore 需 dnceng `dotnet11`；workload 侧本地 `NuGet.config`（未提交）。

## 3. 门禁 1（离设备，全绿）

| 门禁 | 结果 |
|---|---|
| 切片 Release + trim/AOT 分析（rc2 包） | Build succeeded；**0 error / IL2026+IL3050 = 0**；71 条白名单警告 |
| 交互套件（rc2 重建） | **`[suite] checks=513 total=513 floor=493 assert=True`**；grep=513（declared==printed）；perf warmup/a11y 均 `within=True`；无 Unhandled；exit=0 |
| 像素 | `PIXEL ASSERTIONS PASSED`，exit=0 |
| 导出契约 | `OK: all 145 expected exports…`（145/145） |

- 切片门禁在 **fork 布局的 sparse 车辆**中执行（rc2 全树 checkout 下切片 restore 不收敛，见 §5）；交互/像素/导出按 CI 原样针对影子切片。

## 4. 门禁 2（设备冒烟，未做）

- 设备在线 `127.0.0.1:35111`（hdc 可用）。
- 未做原因：`publish-aot.sh` 的 heavy-build guard 会等并发构建 30 min 后 `GUARD-TIMEOUT`；另一会话 bundle-retest 构建已跑 8h+ 仍占用 CPU，按内存纪律不并跑 ILC。
- 重跑：`AOT_WORKDIR=<scratch>/aot OpenHarmonyMauiPlatformDir=<slice> sh test/hello-maui-app/publish-aot.sh` → `scripts/sign-for-device.sh <udid>` → `hdc install` + `aa start` + 截图/RSTree。

## 5. 漂移与环境发现

- rc1↔rc2 行为漂移：**门禁层面 0**（套件/像素/导出在 rc2 下同数通过）；无需 cherry-pick 或硬修。
- 环境坑（复现用）：① NuGet 对"半安装"包会挂死/SIGSEGV（Pkcs 签名路径）→ 清半装目录 + `DOTNET_NUGET_SIGNATURE_VERIFICATION=false` + 本地 flat feed + `RestoreDisableParallel=true`；② MSBuild 多节点不可用（PlatformNotSupported）→ `-m:1`；③ VBCSCompiler 共享服务器被并发构建卡死 → `UseSharedCompilation=false`。
- rc2 全树内切片构建：restore 阶段不收敛（>13 min CPU 空转），CI 对全树影子分支需稀疏/eng 支架改造，另议。

## 6. 回滚

- 两影子分支均未合并，丢弃即可；rc1 pin 未动，主线可复现。
- 若后续采用：`feature/openharmony` 快进前打 backup tag；kit #34 前必须换 rc2 正式 pin、删本地 feed 配置、补设备门禁 2。
