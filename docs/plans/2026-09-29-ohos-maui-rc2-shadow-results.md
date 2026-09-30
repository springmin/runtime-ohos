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

## 4. 门禁 2（设备冒烟 ✓ 已验，2026-09-30）

| 项 | 结果 |
|---|---|
| rc2 线 | ow `fix/ohos-rc2` `b531cc98` + maui 稀疏车辆 `fix/ohos-maui-rc2` `41ec990196`；SDK `.dotnet.rc2-fix` 11.0.100-rc.2.26451.112 / workload preview.28 / rc2 AOT packs |
| 发布 | guard 旁路（主会话裁决：唯一并发 = bundle-retest 1 核构建，无 OOM 风险）；记录坑照用（`-m:1`、`UseSharedCompilation=false`、`RestoreDisableParallel=true`、`DOTNET_NUGET_SIGNATURE_VERIFICATION=false`、flat feed）；EXIT=0，IL2026/IL3050/IL3051=0；so 18,529,040 B `3f9983e0…`；unsigned hap 21,210,762 B `2d52a33b…`；host-in-hap `f6b3581a…` == rc1 v3 host 逐字节相同 |
| 签名/安装 | `hello-maui-app-rc2-aot-60cf.hap` 21,478,557 B `223fd333…`（UDID 60CF7B27… 单值 profile，verify-app ✓；本机桌面不校验 device-ids，同 rc1）→ `hdc install -r` ✓ → `aa start` ✓（pid 61286；VmRSS 184 MB；Threads 71 含 OS_GC_Thread/ThreadPool） |
| 出画 | RSTree `ohos_dotnet_surface` ×2 全 **hasSurfaceBuffer=1**（重启后复核同）；WMS `uiContent is null`=0；截图 = 渐变底 + 居中「Accessibility self-check」对话卡（status 1 attached / nodeCount 0 / OK，preview.28 ArkTS 壳渲染，host 供状态）；rc1 v3 对照 = 渐变底 + 仅按钮（当帧对话卡未绘出）；edge-density 0.83% vs 0.02%，均非白窗 |
| 证据 | scratch `/data/storage/el2/base/tmp/opencode/rc2-gate2/`（EVIDENCE.md、publish-aot.log、signed/、device/ 全套 + 截图） |

- 过程注：首次 `aa start` 被 springmin 锁屏拦（10106102；dev mode 不自动解锁），解锁后成功；窗口一度浮于全屏 shell 之下，最小化 shell 截得应用窗口后恢复。
- 重跑口径：`DOTNET=$HOME/.dotnet.rc2-fix/dotnet AOT_WORKDIR=<scratch>/aot OpenHarmonyMauiPlatformDir=<slice> sh test/hello-maui-app/publish-aot.sh` → `scripts/sign-for-device.sh 60CF7B27…` → `hdc install -r` + `aa start` + RSTree/截图；本轮 publish 由 `rc2-gate2/publish-aot-rc2-noguard.sh` 旁路 guard 复刻。

## 5. 漂移与环境发现

- rc1↔rc2 行为漂移：**门禁层面 0**（套件/像素/导出在 rc2 下同数通过）；无需 cherry-pick 或硬修。
- 环境坑（复现用）：① NuGet 对"半安装"包会挂死/SIGSEGV（Pkcs 签名路径）→ 清半装目录 + `DOTNET_NUGET_SIGNATURE_VERIFICATION=false` + 本地 flat feed + `RestoreDisableParallel=true`；② MSBuild 多节点不可用（PlatformNotSupported）→ `-m:1`；③ VBCSCompiler 共享服务器被并发构建卡死 → `UseSharedCompilation=false`。
- rc2 全树内切片构建：restore 阶段不收敛（>13 min CPU 空转），CI 对全树影子分支需稀疏/eng 支架改造，另议。

## 6. 回滚

- 两影子分支均未合并，丢弃即可；rc1 pin 未动，主线可复现。
- 若后续采用：`feature/openharmony` 快进前打 backup tag；kit #34 前必须换 rc2 正式 pin、删本地 feed 配置（设备门禁 2 已于 2026-09-30 在影子上验过，§4）。
