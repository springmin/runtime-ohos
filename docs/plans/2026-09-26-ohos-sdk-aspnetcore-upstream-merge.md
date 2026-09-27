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
- **结果（2026-09-26 22:46 CST）：失败** —— 未进入 aspnetcore/sdk 阶段，失败于 **Stage 1（runtime 构建）**：
  - `src/coreclr/tools/aot/ILCompiler/ILCompiler_publish.csproj`：`NETSDK1112: The runtime pack for Microsoft.NETCore.App.Runtime.linux-musl-arm64 was not downloaded`
  - 失败步骤：`Build runtime -> aspnetcore -> sdk`（步骤 16）；CI 检出的 `runtime=d43f9ce2`（kit #28 tip）
  - 初步归因（**非本次 merge 引起**）：
    1. 失败发生在 Stage 1，先于 aspnetcore/sdk —— 两仓 merge 的内容不参与该阶段
    2. 本次 merge 未改动 sdk 的 `eng/ohos-install/**` 与 workflow（fork-local 文件原样保留）
    3. runtime 分支自上次绿色运行（09-21）以来有 **63 个非文档文件**变更（interpreter / AOT / native / targetingpacks 等，kit #27/#28 线）；sdk 侧脚本/workflow 09-23 也有改动（hostfeed 校验、portable RID graph 注入）。当前 workflow 只预置了 **linux-x64** 主机运行时包，缺 **linux-musl-arm64** portable 包
- **根因定位（2026-09-26 深夜，确认版）**：
  1. Stage 1 的 `clr.aot+packs` 会构建 installer 的 **ILCompiler 官方包工程**（`src/installer/pkg/projects/Microsoft.DotNet.ILCompiler/Microsoft.DotNet.ILCompiler.pkgproj`）
  2. 其 RID 清单 `ILCompilerRIDs.props` 包含全部 `OfficialBuildRID`，其中有 **`linux-musl-arm64`**
  3. 为 `linux-musl-arm64` 构建该包时会调用 `ILCompiler_publish.csproj`（其 RID = `$(PortableOS)-$(TargetArchitecture)`，此时解析为 `linux-musl-arm64`），自包含发布需要 `Microsoft.NETCore.App.Runtime.linux-musl-arm64` 运行时包
  4. 该包在 CI 中不可得：workflow 只预置 `linux-x64`（+fork Ref/runtime pack）；`eng/targetingpacks.targets` 的本地 pack 覆盖只覆盖 `TargetsOpenHarmony`（`openharmony-arm64`）；且 fork 线版本 `11.0.0-rc.1.26451.109` 在 dnceng（最新 rc `26431.118`）与 nuget.org（`26425.128`）都不存在
  5. → `NETSDK1112` → Stage 1 中止
  - 同型清单 `src/installer/pkg/projects/netcoreappRIDs.props` 也含 `linux-musl-arm64`；若 `packs` 对 runtime pack 同样做全 RID 展开，需要一并处理
- **建议的最小修复（runtime 侧，约 3–4 行）**：在 `ILCompilerRIDs.props` 末尾对 OpenHarmony 构建收窄官方 RID 集（仅保留 `$(TargetRid)`），从根上避免 `linux-musl-arm64` 的 NuGet 还原；fork 的 `runtime.openharmony-arm64.Microsoft.DotNet.ILCompiler` 包本就由脚本的 re-publish + `assemble-ilc-pack.py` 产出，不依赖其它 RID：
  ```xml
  <ItemGroup Condition="'$(TargetsOpenHarmony)' == 'true'">
    <OfficialBuildRID Remove="@(OfficialBuildRID)" Condition="'%(OfficialBuildRID.Identity)' != '$(TargetRid)'" />
  </ItemGroup>
  ```
  同法核对 `netcoreappRIDs.props`（若确有全 RID 展开）
- **备选**：a) 扩展 `eng/targetingpacks.targets` 的本地 pack 覆盖，把 portable `linux-musl-arm64` 重定向到 `LocalRuntimePackDir`；b) pipeline 侧把本地 `openharmony-arm64` 包装成 `linux-musl-arm64` 别名喂给 AOT 还原（改动 sdk 脚本，链路更长）
- **验证方式**：runtime 侧 scratch 分支 → 本地/CI 复跑（`runtime_ref=scratch` + merged sdk/aspnetcore refs）→ 绿后合入 `feature/openharmony`

### 实际修复与结果（2026-09-27）

- **Stage 1 采用 pipeline 侧别名（原"备选 b"，未动 runtime 源码）**：
  1. sdk `eng/ohos-install/build/build-ohos-all.sh` 新增 `seed_musl_runtime_pack_alias_from_release()`：在 `clr+libs+packs` 主构建重试循环前，把本地 `openharmony-arm64` runtime pack 复制出 `runtimes/linux-musl-arm64` 路径，生成 `microsoft.netcore.app.runtime.linux-musl-arm64` 版本别名包（`eng/ohos-install/build/alias-runtime-pack.py`）并注入 `$FEED`
  2. 验证：run `36279517870` Stage 1 通过（`framework R2R 180/180`）
  3. 合入：`e6c14aac33` FF → sdk `feature/openharmony`（runtime 侧 RID 收窄方案未采用）
- **Stage 3（aspnetcore）修复**：
  - 现象：`Microsoft.NET.Sdk.StaticWebAssets.References.targets(175,7): error : Manifest file at '.../Microsoft.AspNetCore.App.Internal.Assets/Release/net11.0/staticwebassets.build.json' not found`
  - 根因：上游 #66412 起 `Microsoft.AspNetCore.App.Internal.Assets` 改用 SDK Static Web Assets "asset groups" 模型；本 CI 的 aspnetcore 阶段是 `--no-build-nodejs` 子集构建，该 manifest 不产出，而 `src/Components/Directory.Build.targets` 的消费者仍会读它
  - 修复：stage3 追加 `-p:IncludeComponentsWebAssets=false`（该阶段只构建 App.Runtime pack/shared framework，不需要组件 web assets）→ `e7f8972b29`
- **Stage 4（sdk）修复**：
  - 现象：`src/Tasks/Microsoft.NET.Build.Tasks/ElfSigner.cs(9,1): error IDE0240: Nullable directive is redundant`（net472 / net11.0 / dotnet.csproj）
  - 根因：本仓 merge 带进的 `Directory.Build.props` 全局 `<Nullable>enable</Nullable>` 使 fork 新增文件的 `#nullable enable` 冗余；`.editorconfig` 的 warning 在 warnings-as-errors 下成为 error
  - 修复：删除该冗余指令 → `d5c1a46413`（其余 fork 新增文件已核对无此问题）
- **最终绿色 run（2026-09-27 16:10 CST 触发，35 分钟）**：https://github.com/springmin/sdk-ohos/actions/runs/36305386249
  - 输入：`runtime_ref`/`aspnetcore_ref`=`feature/openharmony`、`sdk_ref=fix/ohos-aspnet-webassets`（含 `e7f8972b29` + `d5c1a46413`；随后 FF 入 sdk `feature/openharmony`）
  - 结果：**全链成功**；`framework R2R 180/180`、`aspnetcore R2R 132/132`、`sdk redist produced`、Stage 5 收集 **31 个文件**
  - artifact：`ohos-build-openharmony-arm64-36305386249`（**486.6 MB**，保留 30 天）
  - 关键制品：
    | 文件 | 大小 |
    |---|---|
    | `dotnet-sdk-11.0.100-rc.2.26451.109-openharmony-arm64.tar.gz`（27 ELF 已签名） | 178.3 MB |
    | `aspnetcore-runtime-11.0.0-rc.1.26451.109-openharmony-arm64.tar.gz` | 43.9 MB |
    | `dotnet-runtime-11.0.0-rc.1.26451.109-openharmony-arm64.tar.gz` | 32.9 MB |
    | `Microsoft.NETCore.App.Runtime.openharmony-arm64.11.0.0-rc.1.26451.109.nupkg` | 37.5 MB |
    | `Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.1.26451.109.nupkg` | 25.9 MB |
    | `Microsoft.AspNetCore.App.Runtime.openharmony-arm64.11.0.0-rc.1.26451.109.nupkg` | 11.1 MB |
  - workload bundle 未包含（workload 线未动，符合边界）

## 6. 边界与后续

- 本仓（runtime-ohos）与上游 PR 不受影响；`pr/ohos-*` 系列分支未改动
- 既有约束不变：基于 net12 的 runtime PR 分支仍不能通过本 CI（需 CI 引导升 12，另案）
- maui：不 rebase 到 main（10 带）；继续跟 `release/11.0.1xx-rc1`
- workload：未动（随 runtime pack 线）
- sdk `feature/openharmony`：`e6c14aac33..d5c1a46413` FF（含上述两个修复）
- 后续：如需发布制品 → 全 `feature/openharmony` refs + `upload_release=true` 复跑；清理 scratch 分支/worktree（`fix/ohos-aspnet-webassets`、`fix/ohos-musl-alias-pack`、`fix/ohos-aot-official-rids` 与 `sdk-ohos-merge` / `aspnetcore-ohos-merge`）

## 7. CI 迭代效率（分析结论，未实施）

- `runtime → aspnetcore → sdk` 是**产物级硬依赖**（aspnetcore 的 restore 需 runtime 的本地 feed 包与 tarball；sdk 的布局需 runtime+aspnetcore 包），**不能三仓并行编译**；单轮全链约 35–55 分钟，其中 Stage 1 约占 3/4
- 可优化点（按收益排序）：
  1. **阶段缓存 + 跳过**：脚本已内置 `--skip-runtime/--skip-aspnetcore/--skip-sdk/--stage-only=N`；只改 sdk/aspnetcore 时复用上游阶段的 `$WORK/feed` + `$WORK/assets`，迭代周期可降到 ~10–20 分钟
  2. **CI-env（NDK/OpenSSL/ICU）缓存未命中约 7 分钟/次**：失败 run 不落盘新 key（最新有效条目为 09-21），建议独立 job 或 `actions/cache/save` + `if: always()`
  3. job 拆分（`needs:`）+ 单阶段重跑；多 RID matrix（未来）才是真正的并行收益
- 缓存 key 需绑定 `*_ref` SHA + `versions.env`，避免"旧包配新脚本"的假通过
