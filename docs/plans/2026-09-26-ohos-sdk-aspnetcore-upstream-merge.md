# sdk / aspnetcore 集成分支合并 upstream main（kit #28 线）

**日期：** 2026-09-26
**目的：** 在不改写历史、不动 runtime / maui / workload 的前提下，让 sdk-ohos 与 aspnetcore-ohos 的 `feature/openharmony` 跟进各自 upstream `main`（同为 .NET 11 带），并通过 sdk-ohos 三仓 CI 直接产出 runtime→aspnetcore→sdk 制品。

## 1. 背景与决策

- upstream 带号现状（2026-09-26）：

  | 仓库 | main 带号 |
  |---|---|
  | dotnet/runtime | **12**（MajorVersion=12，09-09 起） |
  | dotnet/sdk | **11.0.100-rc.2**（消费 Ref `11.0.0-rc.1.26453.118`） |
  | dotnet/aspnetcore | **11 带**（Ref `11.0.0-rc.1.26453.108`） |
  | dotnet/maui | **10 维护线**（11-rc 线在 `release/11.0.1xx-rc1`） |

- 结论：**sdk / aspnetcore 可同带跟进**；runtime 集成分支保持 11 带不动（避免"runtime 12 + 其余 11"撕裂）；maui（方向相反）与 workload（随 runtime pack 线）不动。
- 方式：**merge upstream/main 进 feature/openharmony**（fast-forward 推送、无强推、一次性解冲突），与 `pr/ohos-sandbox-fixes` 的先例一致；两仓历史也已有同类 upstream merge。

## 2. 执行记录（本地 merge → fast-forward 推送）

| 仓 | fork 基线 | 合并的 upstream/main | merge 提交 | 推送 |
|---|---|---|---|---|
| sdk-ohos | `93350abcae`（kit #28 tip） | `3b1d59fe28`（09-25，"Suppress default values for .NET CLI flag options" #55928） | `3080fb8441` | FF `93350abcae..3080fb8441` → `feature/openharmony` |
| aspnetcore-ohos | `eace90c8fb`（09-23） | `c7cef3bfad`（09-25，deps bump #69542） | `07ed2fe38d` | FF `eace90c8fb..07ed2fe38d` → `feature/openharmony` |

推送前核对远端 `feature/openharmony` 与 merge 第一父提交一致 → 均为 fast-forward，未触发禁强推。

## 3. 冲突与解决

- **sdk-ohos：仅 `src/Tasks/Common/Resources/Strings.resx` 1 处**
  - 双方在文件末尾各自追加新资源：上游 `NETSDK1245/1246`（`Crossgen2UnsupportedHostRuntimeIdentifier` / `Crossgen2UnsupportedTargetFramework`）；fork `NETSDK1247–1250`（`OpenHarmonyCodesign*`）
  - 解决：保留双方全部条目（编号无冲突），"latest message" 注释统一指向 `OpenHarmonyCodesignSkippedSymbolicLink`（1250）
- **aspnetcore-ohos：零冲突**

## 4. 自检结果（merge 后）

| 检查 | sdk-ohos | aspnetcore-ohos |
|---|---|---|
| 对比 upstream/main 的 delta 文件数 | 89（与原 fork delta 一致） | 8（一致） |
| 资源重复（resource name / `<value>` NETSDK id） | 无 | — |
| 上游新条目保留 | ✅（1245/1246） | ✅ |
| xlf 同步抽查（cs.xlf） | ✅ | — |
| fork 标记（RID 图 / codesign / ElfSigner / EnvironmentDefaults） | ✅ | ✅ |
| 高风险文件 fork delta 精确性 | GenerateLayout +18 / redist +7 / dotnet.csproj +8 / Strings.resx +18 | Directory.Build.props（`NativeAotSupported=false` + RID 追加） |
| 冲突标记残留 | 无 | 无 |
| 工作区状态 | clean | clean |

## 5. 三仓 CI

- **Run：** https://github.com/springmin/sdk-ohos/actions/runs/36248160509 （2026-09-26 22:20 CST 触发）
- 输入：`runtime_ref=feature/openharmony`、`aspnetcore_ref=feature/openharmony`、`sdk_ref=feature/openharmony`、`rid=openharmony-arm64`
- Preflight（只校验 runtime_ref 的 OpenHarmony 支持与 band=11.0.0）：runtime 未动 → 通过
- 预期制品：runtime / aspnetcore / sdk 三仓 `artifacts/packages/Release/Shipping/*` → artifact `ohos-build-openharmony-arm64-<run_id>`；可选 `upload_release=true` 发布到三个 `-ohos` release
- **结果：** 待补（构建完成后在此追加结论与制品清单）

## 6. 边界与后续

- 本仓（runtime-ohos）与上游 PR 不受影响；`pr/ohos-*` 系列分支未改动
- 既有约束不变：基于 net12 的 runtime PR 分支仍不能通过本 CI（需 CI 引导升 12，另案）
- maui：不 rebase 到 main（10 带）；继续跟 `release/11.0.1xx-rc1`
- workload：未动（随 runtime pack 线）
- 后续：CI 结果回填；绿后如需发布走 `upload_release=true`；清理两个 merge worktree（`sdk-ohos-merge` / `aspnetcore-ohos-merge`）
