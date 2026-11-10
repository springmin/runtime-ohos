# OpenHarmony .NET 上游策略与 workload 方案

**日期:** 2026-11-09
**状态:** 策略草案（待执行）
**范围:** dotnet/runtime、dotnet/aspnetcore、dotnet/sdk、ohos-workload、MAUI

## 1. 总原则

```text
通用平台能力          → dotnet/runtime / sdk / aspnetcore 上游
OpenHarmony 应用平台   → ohos-workload
SDK 自身构建/自签      → SDK build 仓（或 build-only fork）
```

不再把 OpenHarmony 专属的发行、签名、沙箱策略往 dotnet/sdk 上游推；上游只保留通用
RID、构建 enablement 和平台抽象。

## 2. 目标架构

```text
dotnet/runtime
  native/PAL、RID graph、OS 检测、runtime packs
  代表：#136194

dotnet/aspnetcore
  RID/AOT
  代表：#69952（已合并）

dotnet/sdk
  RID graph + crossgen2 mapping、通用 build enablement
  代表：#56732

ohos-workload
  TFM、Sdk/Ref/Runtime packs、KnownFrameworkReference/RuntimePack/AppHost、
  .hap 打包、ELF/hap 签名、selfsign、templates、sandbox/env 默认值、
  WorkloadDependencies、MAUI Hosting/Graphics

SDK build 仓
  OpenHarmony host 构建、SDK tarball selfsign/预签名、发布
```

## 3. PR 处置

| PR | 处理 | 说明 |
|---|---|---|
| prereqs#1786 | 继续 review | 已 ping dkurepa；CI 绿；解锁 runtime#136206 |
| aspnetcore#69952 | 已合并 | 5/5 threads resolved |
| runtime#136194 | 等合并 | APPROVED；失败是已知问题，不需要重跑 |
| sdk#56732 | 继续 upstream | 通用 RID/crossgen2；marcpopMSFT 已更新分支 |
| sdk#56733 | 拆分 | 通用 build enablement 可上游；环境默认值/沙箱 → workload |
| sdk#56735 | 撤下/转 workload | ElfSigner/OpenHarmonyCodesign/selfsign → workload tools；SDK 自签 → build |
| sdk#56760 | 撤下/转 workload | 应用 publish 签名已在 workload；SDK 自身签名 → build |
| sdk#56761 | 转 workload/fork | SDK tools sandbox 默认值不适合 upstream |
| docs#56529 | 等 review | 继续 ping baronfel |
| runtime#136206 | #1786 后 rerun | 先重跑 runtime-community，再 undraft |
| runtime#137191 | 保持 open | .NET 侧 7.1 close_range 跟踪 |
| AtomGit #3599 | 保持 open | OpenHarmony 侧 close_range 跟踪 |

对 marcpopMSFT 的回复口径：

```text
Agreed. OpenHarmony-specific distribution/signing/sandbox pieces will live
in the OpenHarmony workload/fork, not dotnet/sdk.

We'd like to land only the generic RID graph + crossgen2 mapping (#56732)
upstream. For #56733 we'll split the generic build enablement from the
OpenHarmony environment defaults; the latter moves to the workload.

The ELF signer/selfsign and SDK output signing will stay in the SDK build
pipeline; app-facing signing/sandbox targets move to Microsoft.OpenHarmony.Sdk.
```

## 4. Workload 自包含改造

workload 目前仍依赖 sdk-ohos 的 `ElfSigner` / `Microsoft.NET.Build.Tasks`，必须解除。

### 4.1 迁移签名实现

从 sdk-ohos 移到 `ohos-workload`：

```text
src/Tasks/Microsoft.NET.Build.Tasks/ElfSigner.cs
src/Tasks/Microsoft.NET.Build.Tasks/OpenHarmonyCodesign.cs
```

编译进：

```text
packs/Microsoft.OpenHarmony.Sdk/<ver>/tools/Microsoft.OpenHarmony.Tasks.dll
```

修改 `OpenHarmony.Hap.targets`：

```xml
<UsingTask TaskName="OpenHarmonyCodesign"
           AssemblyFile="$(MSBuildThisFileDirectory)../tools/Microsoft.OpenHarmony.Tasks.dll" />
```

这样不再依赖 OpenHarmony SDK fork 的 `MicrosoftNETBuildTasksAssembly`。

### 4.2 selfsign 去 SDK 依赖

`scripts/selfsign.sh` 当前从 sdk-ohos 复制 `ElfSigner.cs`。改为：

- 使用 workload 自己的 `ElfSigner` 源码；或
- 使用已发布的 `Microsoft.OpenHarmony.Tasks.dll` / 独立 selfsign CLI。

SDK build 也调用同一个工具，避免两份实现。

### 4.3 HAP/HAP 签名

`OpenHarmony.Hap.targets` 已有：

- `ohos_packing_tool` 打包；
- `hap-sign-tool` + OpenHarmony profile 签 HAP；
- `OpenHarmonyCodesign` 签 libs 下的 ELF。

迁移后这些全部由 workload 负责，MAUI HAP 构建直接验证。

### 4.4 Workload 能力补全

- `ridgraph` 保留作为 fallback；
- 如需要，增加 `KnownCrossgen2Pack`，与 #56732 对齐；
- 应用构建的 sandbox/env 默认值放入 `Sdk/AutoImport.props` 或 `Sdk.targets`；
- `WorkloadDependencies` 继续声明 NDK/hap 工具/hdc；
- manifest band 对齐 `11.0.100-rc.3` / `11.0.100`。

## 5. 签名分工

| 产物 | 处理 |
|---|---|
| 应用 ELF | workload `Microsoft.OpenHarmony.Tasks.dll` 里的 ElfSigner |
| HAP | workload `hap-sign-tool` + OpenHarmony debug profile |
| SDK tarball 内 ELF | SDK build 仓调用 selfsign 工具 |
| Windows/macOS 标准产物 | ESRP（保持现状） |
| HarmonyOS 商用签名 | 华为证书/profile，不走 ESRP |

**ESRP 不处理 ELF selfsign**：它是 SHA-256 Merkle root + `.codesign` 的
OpenHarmony 自签名格式，没有证书/私钥，ESRP 没有这种签名类型。

**Arcade 只做编排**：在 SDK build 里加自定义 target，调用 selfsign 工具并验证
`.codesign`，不把算法放进 Arcade/ESRP。

## 6. 版本线与发布

继续执行 P2 A：

```text
OpenHarmony 栈：.NET 11.0 rc.3
  runtime        release/ohos-rc3
  aspnetcore     feature/openharmony（11.0）
  sdk            feature/openharmony（11.0）
  workload       11.0.100-rc.3 / 11.0.100

runtime feature/openharmony（12.0）只用于上游 PR 集成，不作为栈构建 runtime。
```

12.0 迁移门槛：

- runtime 12.0 OpenHarmony packs 可用；
- aspnetcore/sdk 12.0 集成分支建立；
- workload band 增加 12.0；
- 全栈构建 + 设备冒烟通过；
- 11.0 rc.3 资产保留回滚。

## 7. 验证矩阵

| 层 | 验证 |
|---|---|
| 上游 | #136194 runtime CI、#56732 sdk CI、#1786 image CI |
| 全栈 | runtime rc.3 → aspnetcore feature → sdk feature 全栈构建 |
| SDK | `dotnet --info`、SDK tarball 签名 |
| Workload | `dotnet workload install openharmony`、MAUI HAP build |
| 设备 | HAP 安装/启动、ELF `.codesign` 校验、ASP.NET smoke |
| 签名 | ElfSigner 重签/验证、hap-sign-tool 签名 |

已验证：

```text
全栈构建 success（run 42532205493 / 42536366339）
aspnetcore 目标构建 + 设备 smoke success
SDK rc.3 产物 + 设备 dotnet --info success
```

## 8. 执行顺序

### P0

1. #136194：等 maintainer 合并（无需重跑）。
2. #1786：等 dkurepa 复审。
3. #56732：回复 marcpopMSFT，明确只 upstream 通用部分。
4. Workload 自包含：迁移 `ElfSigner`/`OpenHarmonyCodesign` 到
   `Microsoft.OpenHarmony.Tasks.dll`，改 HAP targets 和 selfsign.sh。

### P1

1. #56733 拆分：通用 build enablement vs 环境默认值。
2. #56735 / #56760 / #56761：撤下或转 workload/build。
3. Workload：补 sandbox/env 默认值、`KnownCrossgen2Pack`、manifest/pack 发布。
4. MAUI：用 HAP 构建 + 设备安装验证 workload 自包含。

### P2

1. SDK host build enablement：通用部分 upstream，OpenHarmony 专属留 build 仓。
2. Workload W2–W5：Hosting/Ref 完整化、多 band、模板、发布。
3. 12.0 迁移准备。

### P3

- docs#56529 review；
- runtime#136206 rerun/undraft；
- #137191 / AtomGit #3599 跟踪 7.1 `close_range`；
- 发布/文档/CI。

## 9. ohos-workload 如何"提到上游"

workload 不是通过单个 PR 提到 dotnet/sdk；它走"平台仓 + workload manifest 分发"模式。

### 9.1 推荐路径：OpenHarmony 组织托管

1. 把 `ohos-workload` 迁到 OpenHarmony 组织（AtomGit/GitCode），例如
   `openharmony/ohos-workload` 或 `openharmony/dotnet-workload`。
2. 发布 workload packs + manifests 到公共 feed（AtomGit release / NuGet）。
3. 文档化 `dotnet workload install openharmony` 的 manifest source。
4. 由 OpenHarmony 维护者负责版本、签名、发布节奏。
5. MAUI 侧增加 `maui-openharmony extends [maui-blazor, openharmony]`。

这是与 `dotnet/macios`、`dotnet/android` 对应的模型：平台专属代码在平台仓，不在
dotnet/sdk。

### 9.2 可选路径：dotnet org 新仓

如果希望放到 `dotnet/` 下（如 `dotnet/openharmony`）：

1. 先在 `dotnet/designs` 提交平台 workload 设计；
2. 获得 .NET 团队对 repo ownership、release、security 的认可；
3. 建立 `Microsoft.OpenHarmony.Sdk/Ref/Runtime/Manifest` 发布流程；
4. 纳入官方 workload set / feed。

成本高，周期长，但可获得官方发现度。短期内建议先走 9.1。

### 9.3 让 workload 可被 dotnet SDK 发现

- `WorkloadManifest.json` 使用稳定 ID `microsoft.net.sdk.openharmony`；
- band 目录与 SDK feature band 对齐（`11.0.100-rc.3`、`11.0.100`）；
- packs 发布到 feed，manifest 提供 pack ID/version；
- `WorkloadDependencies.json` 声明 OpenHarmony SDK/NDK、hap 工具、hdc；
- 用户可通过 manifest source 安装：

```sh
dotnet workload install openharmony --source <feed>
```

- 若希望默认可用，需要 .NET SDK workload 团队把 manifest 纳入官方 workload set
  或文档；这一步不是普通代码 PR，需要 owner 和发布流程。

### 9.4 前置条件

- workload 自包含（不依赖 sdk-ohos 的 ElfSigner）；
- RID graph/runtime packs 可用（#56732 + runtime 支持）；
- MAUI HAP 构建 + 设备安装验证通过；
- manifest/pack 版本与 SDK band 对齐；
- 公共 feed 和发布签名流程。

## 10. 当前状态快照（2026-11-09）

```text
aspnetcore#69952   MERGED
runtime#136194     APPROVED，等合并
prereqs#1786       REVIEW_REQUIRED，已 ping dkurepa
sdk#56732          REVIEW_REQUIRED，marcpopMSFT 已更新分支并提出 fork 建议
sdk#56733          marcpopMSFT APPROVED，分支已 merge main
sdk#56735/#56760/#56761  待转 workload/build
docs#56529         等 baronfel
runtime#136206     draft，依赖 #1786
```

评审 thread：

```text
29 total
22 resolved（#136194 15 + #69952 5 + #56733 2）
7 unresolved（#1786 2、#136194 3、非行动项 2）
```

OpenHarmony 平台：

```text
Gitee 仓库 status=关闭
GitHub openharmony org 是只读镜像
活跃平台是 AtomGit
close_range tracking: https://atomgit.com/openharmony/startup_init/issues/3599
.NET tracking: https://github.com/dotnet/runtime/issues/137191
```

## 11. 风险

1. Workload 不能替代 SDK build：SDK 在 OpenHarmony host 上构建、tarball 自签仍需
   build 仓。
2. Workload 仍依赖通用上游能力：RID graph、runtime packs、OS 检测。
3. ESRP 不适合 ELF selfsign：只能 Arcade 编排 + OpenHarmony 工具。
4. OpenHarmony 平台已迁到 AtomGit：Gitee/GitHub 镜像关闭/只读。
5. reviewer 响应：marcpopMSFT 已明确平台专属部分倾向 fork/workload，需要尽快按
   上述边界回复。

## 12. 最终形态

```text
上游（通用）:
  runtime + aspnetcore + sdk
  #136194、#69952、#56732

平台层（workload）:
  ohos-workload
  TFM、Sdk/Ref/Runtime packs、HAP 打包、ELF/hap 签名、
  selfsign、templates、sandbox/env 默认值、MAUI Hosting

构建层（build）:
  SDK host build、SDK tarball selfsign/预签名、发布
  Arcade 编排，ESRP 只处理标准产物
```

## 13. MAUI 平台切片调整（2026-11-10）

按 runtime/sdk/aspnetcore 已建立的评审口径，MAUI 侧完成以下调整（不急于开 PR）：

### 13.1 已完成的代码调整

| 评审要求 | 调整 |
|---|---|
| 不硬编码仓库外路径 | 删除 `Core.csproj` 和 standalone slice 里的 sibling `ohos-workload` 路径；改为必需属性 `OpenHarmonyHostingAssembly` / `OpenHarmonyGraphicsAssembly`，缺失时由 `_MauiValidateOpenHarmonyGraphicsAssembly` / `_OpenHarmonyValidateSliceAssemblies` 给出可操作错误 |
| 不靠 suppression 过构建 | 删除 `src/Core/src/Platform/OpenHarmony/.editorconfig`（19 条 CA 规则目录级降级）和 csproj 的 `WarningsNotAsErrors` 白名单；逐条修复 61 个 CA 诊断（CA1307/CA1311/CA1806/CA1822/CA1845/CA1846/CA1859/CA1865/CA2249），并把 CS0618/CA2255 收窄到具体文件/成员并写明理由 |
| 不关闭 NuGet 审计 | 删除 standalone slice 的 `NuGetAudit=false`；离线 partial checkout 由调用方显式覆盖 |
| AOT 用共享门控 | root `Directory.Build.props` import `eng/common/native/NativeAotSupported.props`，对 OpenHarmony 设 `NativeAotSupported=false`；`Controls.TestCases.HostApp` 的 `PublishAot` 条件改为 `'$(NativeAotSupported)' != 'false'`（对齐 aspnetcore#69952） |
| previous TFM 一致 | 移除 `MauiPreviousPlatforms` / `MauiSamplePreviousPlatforms` / `MauiManualTestsPreviousPlatforms` 里的 OpenHarmony 条目；当前平台仍由 `MauiPlatforms` / `MauiSamplePlatforms` 提供 |
| 默认 API level | `OpenHarmonyTargetFrameworkVersion=20.0`（public SDK）；device SDK 用 `-p:OpenHarmonyTargetFrameworkVersion=26.0` 覆盖 |
| 平台代码隔离 | 保持 `src/Core/src/Platform/OpenHarmony/` + `src/MultiTargeting.targets` 的 TFM 移除规则；非 OpenHarmony TFM 不会编译/引用平台依赖 |
| 真实 TFM 构建 | Core 保持平台中立；OpenHarmony TFM 下 `Microsoft.Maui.Controls` 链接编译整个切片并带 Standard fallback，`--tfm` 同时构建 Core/Controls |
| workload Ref pack | `Microsoft.OpenHarmony.Maui.Graphics.dll` 加入 Ref.20.0/Ref.26.0 的 `FrameworkList.xml` 并由 `prepare-packs.sh` 复制；Controls 改用 framework reference，不再需要显式 `OpenHarmonyGraphicsAssembly` |

额外清理：删除无接口来源、无调用方的 `OpenHarmonyPermissions.EnsureDeclared<TPermission>()` 公共 API 及其
`PublicAPI.Unshipped.txt` 条目；`OpenHarmonyFilePicker.PickMultipleAsync` 的返回值空值标注对齐
`IFilePicker.PickMultipleAsync`（`Task<IEnumerable<FileResult>?>`）。

### 13.2 新增测试与门禁

```text
src/Core/tests/OpenHarmony.UnitTests/        25 个 host-runnable 单元测试
  OpenHarmonyPlatformTests.cs                text transform、a11y action map、rawfile/file 路径校验
eng/openharmony/verify-slice.sh              build（warnings-as-errors）+ test 的唯一入口
eng/openharmony/README.md                    用法、workload 发现规则、CI leg 边界
```

验证结果（2026-11-10）：

```text
verify-slice.sh --tfm (workload Ref pack only, no explicit assembly paths,
PublicApiAnalyzers Validate):
  Core -> artifacts/bin/Core/Release/net11.0-openharmony20.0/Microsoft.Maui.dll
  Controls.Core -> artifacts/bin/Controls.Core/Release/net11.0-openharmony20.0/Microsoft.Maui.Controls.dll
  verify-slice: OK (0 errors)

verify-slice.sh (net11.0):
  Build succeeded. 0 Warning(s) 0 Error(s)
  Passed! - Failed: 0, Passed: 25, Skipped: 0

verify-slice.sh --slice-tfm:
  Microsoft.Maui.Platform.OpenHarmony -> .../net11.0-openharmony20.0/...dll
  verify-slice: OK

ohos-workload:
  selftest-tasks.sh        checks: 9, failed: 0
  selftest-hap-targets.sh  checks: 128, failed: 0, skipped: 1
  selftest-selfsign.sh     checks: 13, failed: 0
  selftest-sdk-defaults.sh checks: 19, failed: 0
  selftest-packs.sh        checks: 30, failed: 0
  task unit tests          [tasks-tests] checks=184 failed=0 assert=True
  maui-platform-verify     [suite] checks=826 total=829 floor=809 assert=True
  headless-render          PIXEL ASSERTIONS PASSED
```

说明：本机共享 Roslyn 编译器会出现已知 livelock，`verify-slice.sh` 支持
`VERIFY_MSBUILD_ARGS="-p:UseSharedCompilation=false"`，CI 默认不需要。

### 13.3 未完成（需要上游/外部条件）

1. **MAUI CI leg**：入口脚本已就绪（`eng/openharmony/verify-slice.sh --tfm`）；workload
   manifest/packs 发布到公共 feed 后，增加
   `dotnet workload install openharmony --source <feed>` + 该脚本的独立 leg。默认 CI 不启用，
   避免平台中立构建依赖外部 workload。
2. **设备测试**：HAP 安装、启动、交互、像素与无障碍验证继续在
   `ohos-workload/test/maui-platform-verify` 等外部 harness 运行。
3. **Public API 拆分（已完成基线迁移/收敛，待 API review）**：基线已迁移到
   `Controls/src/Core/PublicAPI/net-openharmony/` 并重新生成；Core 基线独立生成。切片公共
   面从 1,734 行 / 156 类型降到 799 行 / 90 类型，Phase 2/3 实现类型已 internal 化，
   `PublicApiAnalyzers` Validate 通过。剩余是 90 个 feature/handler 类型的 MAUI API review；
   清单见 `maui-ohos/docs/openharmony-api-review.md`。
4. **workload manifest**：`maui-openharmony extends [maui-blazor, openharmony]` 依赖
   `microsoft.net.sdk.openharmony` manifest source；该依赖是平台 side 的职责，MAUI 默认
   workload 不安装它，因此不会影响 `dotnet workload install maui`。
5. **Core/Controls fallback 清理**：OpenHarmony TFM 现在借助 Core/Controls 的 Standard
   fallback 让共享 handler 基类完整编译；实际运行时由切片注册的 `OpenHarmony*Handler` 接管。
   后续按 Phase 2 把 Core-only handler 拆回 Core，并逐步替换 Standard no-op。

### 13.4 Workload 环境默认值与 crossgen2

- **环境默认值**：`Microsoft.OpenHarmony.Sdk/Sdk/Sdk.targets` 对 `openharmony` 平台设置
  `UseAppHost=false`、`SelfContained=true`、默认 `RuntimeIdentifier=openharmony-arm64`、
  `GenerateDependencyFile=false`、`CopyLocalLockFileAssemblies=true`。trust payload
  （`OpenHarmonyTrustMode` / `trust.json` / CA bundle）与 static OpenSSL 由
  `OpenHarmony.Hap.targets` 处理，`selftest-hap-targets.sh` 的 T13/T14 已覆盖。
  `selftest-sdk-defaults.sh` 用已安装的 `Microsoft.OpenHarmony.Sdk` 评估真实
  `net11.0-openharmony20.0` 可执行工程，断言上述默认值、`TargetPlatformSupported`、
  `EnableAppHostPackDownload=false`、`AllowSelfContainedWithoutRuntimeIdentifier=true`
  以及默认 R2R/NativeAOT 未开启。
- **KnownCrossgen2Pack**：当前栈只发布 JIT/self-contained 运行包，未启用 ReadyToRun 或
  crossgen2，且 OpenHarmony 的 NativeAOT 已显式关闭（`NativeAotSupported=false`），因此
  manifest 不声明 `KnownCrossgen2Pack`。`selftest-sdk-defaults.sh` 断言已安装的
  `Sdk.targets` 不声明该属性、不默认开启 R2R/AOT，且 manifest 的 `packs` 中没有
  Crossgen2 pack。如果后续启用 R2R，需要在 workload manifest 增加
  `KnownCrossgen2Pack`（Key: `openharmony-arm64`），并补 crossgen2 pack 的发布/签名验证。
- **rc.3 runtime pack pin**：`scripts/cut-kit.sh` 已补
  `Microsoft.AspNetCore.App.Runtime.openharmony-arm64/11.0.0-rc.3.26522.148` 的 release tag
  `v11.0.0-rc.3.26522.148-openharmony` 和 nupkg SHA-256
  `1104f0704709e2ae5f09a653088455510b03d1ad814d0c33a97b2c43d9f99a3a`；
  `selftest-packs.sh` 30/30 通过。

## 14. 上游 SDK 评审最新状态（2026-11-10 重新拉取）

### 14.1 PR 状态

| PR | 状态 | 最新评审 |
|---|---|---|
| sdk#56732 | open / mergeable / 7 commits / **all checks green** | 无 maintainer review comment；marcpopMSFT 在 #56732 的 conversation 中明确“其他四个 OpenHarmony 专属改动应放 fork”，当前 PR 只保留 RID graph + crossgen2 mapping。2026-11-10 已发 status ping：https://github.com/dotnet/sdk/pull/56732#issuecomment-6764071019 |
| sdk#56733 | open / mergeable / 13 commits | marcpopMSFT 2026-11-09 APPROVED；jkotas 2026-11-10 追问“NativeAOT 对 SDK 工具几乎必需，OpenHarmony 为什么不启用” |
| sdk#56735 | closed | 按 marcpopMSFT 意见移到 workload/fork（ELF signer/selfsign） |
| sdk#56760 | closed | 按意见移到 SDK build pipeline/workload（build/publish 签名） |
| sdk#56761 | closed | 按意见移到 workload/fork（sandbox 默认值） |

### 14.2 已满足的评审要求

- 平台专属的 distribution/signing/sandbox 不再进 `dotnet/sdk`，与 marcpopMSFT 的
  “OpenHarmony specific fork” 口径一致。
- #56732 只保留通用 RID graph + crossgen2 mapping；#56733 只保留通用 build enablement，
  OpenHarmony environment defaults 已拆分/撤下。
- #56733 已按 review 改为只在 Net120 RID 列表加入 openharmony，并补
  `_KnownRuntimeIdentifierPlatforms`、crossgen2 TargetOS 映射。
- 当前 MAUI/workload 分层（runtime/sdk 通用能力、workload 平台层、SDK build 仓自签）
  与该口径一致。

### 14.3 尚未满足：`jkotas` 的 NativeAOT 问题

jkotas 在 #56733 的问题是当前唯一未回复的 review thread。PR 目前：

- 在 `Directory.Build.props` 设置 `NativeAotSupported=false`（condition: `OSName == openharmony`）；
- `dn` / `dotnet-aot` 的 `PublishAot` 只在 `NativeAotSupported == true` 时启用；
- 说明是“OpenHarmony 没有 NativeAOT toolchain”。

技术现状：

- `dotnet/runtime#136185` 已合并 OpenHarmony NativeAOT/pack 构建集成（TargetOS 映射、
  lld/ohos ABI、ILCompiler 本地 pack、ILLink managed NTLM 等）。
- 但面向 SDK 的可发布 `runtime.openharmony-arm64.Microsoft.DotNet.ILCompiler` 和
  NativeAOT runtime pack 尚未发布到 NuGet/SDK feed；直接 `PublishAot` 会在 restore 阶段
  找不到 ILCompiler pack。
- 因此 #56733 的 gate 是“pack 未发布”期间的安全开关，而不是宣称平台永远不支持 AOT。

已创建 runtime 跟踪 issue：https://github.com/dotnet/runtime/issues/137243
（标题：Publish OpenHarmony ILCompiler and NativeAOT runtime packs）。

已在 dotnet/sdk#56733 回复并链接该 issue：
https://github.com/dotnet/sdk/pull/56733#issuecomment-6763961614

建议回复文本：

```text
NativeAOT is the right direction; the blocker is pack availability, not the platform.
dotnet/runtime#136185 wired OpenHarmony into NativeAOT and the local pack build, but the
publishable runtime.openharmony-arm64.Microsoft.DotNet.ILCompiler and NativeAOT runtime packs
are not in the SDK feeds yet, so PublishAot for dn/dotnet-aot fails during restore. The PR
gates PublishAot on NativeAotSupported (same pattern as linux-musl) to keep the SDK build green;
once the runtime packs are published we can remove the override and enable AOT without source
changes. Would a follow-up issue tracking the pack publication be acceptable?
```

### 14.4 对当前 MAUI/workload 方案的影响

- MAUI 的 `NativeAotSupported=false` 只用于 **repo-side/test** AOT（`Controls.TestCases.HostApp`
  等），不是“用户 publish AOT 永久不可用”；用户 AOT 仍依赖 runtime ILCompiler pack。
  已在 MAUI 注释中改为这一口径（不再写“OpenHarmony is not a NativeAOT target”）。
- 在 runtime ILCompiler/NativeAOT packs 发布前，不启用 MAUI test-asset AOT；发布后移除
  gate 并重跑 `--tfm` 的 AOT leg。
- #56732 仍需要 maintainer review/merge；#56733 需要先回复 jkotas，再请求 re-review。

## 15. 边界审计修正（2026-11-10）：SDK build-output codesign 不是冗余

原审计把 sdk-ohos `feature/openharmony` 的 `_OpenHarmonyCodeSign*` 视为“应用侧签名重复”。
进一步核对 `dotnet run` / file-based 路径后修正：

- 该 pass 的触发条件是 `RuntimeIdentifier` 或 `AppHostRuntimeIdentifier` 以 `openharmony`
  开头，覆盖：
  - `dotnet run file.cs`（file-based app，RID 来自 SDK 自身，没有 OH TFM）；
  - portable/self-contained build（`TargetPlatformIdentifier` 不是 openharmony，workload 的
    `Sdk.targets` 不会导入）；
  - `dotnet build` / `dotnet publish` 的直接输出。
- workload 的 `OpenHarmonyCodesign` 在 `OpenHarmony.Hap.targets` 里只签 HAP staging 的
  `libs/<abi>`，由 `TargetPlatformIdentifier == openharmony` 触发，覆盖不了上面两类。
- 因此两者不是同一职责的重复：
  - SDK：build/publish output codesign（类比 `_EnableMacOSCodeSign`）；
  - workload：HAP payload codesign。
- `ElfSigner.cs` 仍是 SDK install selfsign（`eng/ohos-install/selfsign.csproj`）的共享源；
  workload 为保持自包含保留自己的副本，二者算法需同步。
- `dotnet selfsign` 不是死代码：`NETSDK1249` 的消息指向它；本次保留。若后续要移除，需要同步
  修改资源字符串、文档和用户工作流。

本次处理（sdk-ohos `feature/openharmony`，提交 `4485967fba`）：

- 把 `_OpenHarmonyCodeSign*` / `UsingTask` 从通用 `Microsoft.NET.Sdk.targets` 拆到
  `Microsoft.NET.Sdk.OpenHarmony.targets`，通用文件只保留一行 import；
- 更新 `test-codesign-filewrites.sh`（新增 import 检查）、tests README 和安装文档；
- 验证：
  - `sh eng/ohos-install/tests/test-codesign-filewrites.sh` -> `6 passed, 0 failed`；
  - MSBuild `-pp` 预处理新 targets（临时 project import）-> `rc=0`；
  - 完整 SDK 构建未完成：本机 `dotnet build` 在 restore 阶段超时（无输出），未取得 baseline。

结论：item 1 的正确收口是“隔离 + 明确职责”，不是删除 SDK 侧签名；删除会破坏
`dotnet run file.cs` 和 portable 构建。

### 15.1 macOS 对照：同一套两层签名模型

macOS 也没有把签名全部放在 workload，而是分两层：

| 层 | macOS | OpenHarmony |
|---|---|---|
| SDK 触发 | `_EnableMacOSCodeSign`：RID/AppHostRID 以 `osx` 开头 | `_EnableOpenHarmonyCodeSign`：RID/AppHostRID 以 `openharmony` 开头 |
| SDK 范围 | 只签 apphost / single-file host | 递归签 `$(TargetDir)`/`$(PublishDir)` 的 ELF |
| SDK 签名类型 | ad-hoc CMS（`codesign --sign -`） | self-sign `.codesign` section |
| SDK 工具 | `HostWriter` + `MachObjectFile.AdHocSignFile`；layout 用 `codesign` | `OpenHarmonyCodesign` + `ElfSigner`；`dotnet selfsign` |
| workload 触发 | `EnableCodeSigning` + `_DetectSigningIdentity`（`Microsoft.macOS.Sdk`/`Microsoft.iOS.Sdk`/`Microsoft.MacCatalyst.Sdk`） | `TargetPlatformIdentifier == openharmony` 的 HAP targets |
| workload 范围 | `.app` bundle、嵌套 code、entitlements、provisioning | HAP staging 的 `libs/<abi>` + HAP 包 |
| workload 工具 | `Codesign` task + `BuildIpa`/`CreatePackage` | `OpenHarmonyCodesign` + `hap-sign-tool` |
| 签名性质 | 本地执行（ad-hoc） vs 分发（Developer ID + provisioning/notarization） | 本地执行（self-sign） vs 分发（HAP profile/cert） |

关键证据：

- `sdk-ohos/src/Tasks/Microsoft.NET.Build.Tasks/targets/Microsoft.NET.Sdk.targets:832`
  - `_EnableMacOSCodeSign` 只在 RID/AppHostRID 以 `osx` 开头时设置。
- `sdk-ohos/src/Tasks/Microsoft.NET.Build.Tasks/CreateAppHost.cs:50,104`
  - `EnableMacOSCodeSign` 只传给 `HostWriter.CreateAppHost`。
- `runtime-ohos/src/installer/managed/Microsoft.NET.HostModel/AppHost/HostWriter.cs:62,115`
  - `enableMacOSCodeSign` 的注释是 “Sign the app binary with an anonymous certificate.”；
  - 只对 apphost / single-file host 调用 `MachObjectFile.AdHocSignFile`。
- `runtime-ohos/src/installer/managed/Microsoft.NET.HostModel/MachO/MachObjectFile.cs:133`
  - `AdHocSignFile` 生成的是 ad-hoc CMS 签名，没有身份、provisioning、entitlements。
- `sdk-ohos/src/Layout/redist/targets/GenerateLayout.targets:79`
  - SDK 自己的 Roslyn/MSBuild apphost 也是 `codesign --sign - --entitlements ...` 自签。
- `dotnet/macios/msbuild/Xamarin.Shared/Xamarin.Shared.targets:2171,2722,2771`
  - `_DetectSigningIdentity` 解析 `CodesignKey`/`CodesignProvision`/`CodesignEntitlements`；
  - `_CodesignAppBundle` 调用 `ComputeCodesignItems` + `Codesign` 签整个 app bundle。
- `dotnet/macios/dotnet/targets/Xamarin.Shared.Sdk.targets:3023`
  - `_ComputeCodesignItems`；
- `dotnet/macios/dotnet/targets/Xamarin.Shared.Sdk.Publish.targets`
  - `BuildIpa` / `CreatePackage` 在签名后打包。

对照结论：

- **职责相同**：SDK 负责“本地能执行”，workload 负责“可分发”。
- **范围不同**：macOS 只签 apphost，是因为 Mach-O 只需要主可执行文件签名；
  OpenHarmony 递归签所有 ELF，是因为 loader/installer 要求每个 ELF 都有 `.codesign`。
  这是平台约束，不是边界错误。
- **不要删除 SDK pass**：删除会破坏 `dotnet run file.cs` 和 portable/self-contained 构建。
- **不要把 HAP 分发签名放进 SDK**：HAP profile/cert 属于 workload/平台分发层。
- `ElfSigner` 的两份副本是“workload 自包含”的代价；修改算法时必须同步
  `sdk-ohos/src/Tasks/Microsoft.NET.Build.Tasks/ElfSigner.cs` 和
  `ohos-workload/src/Microsoft.OpenHarmony.Tasks/ElfSigner.cs`。

## 16. MAUI Core/Controls split（2026-11-10）

第一批按依赖把 6 个内部平台服务移入 `Microsoft.Maui.Core`：

- `OpenHarmonyPaths`
- `OpenHarmonyPreferences`
- `OpenHarmonyFlashlight`
- `OpenHarmonyHaptics`
- `OpenHarmonyKeystore`
- `OpenHarmonyNotifications`

仍留在 `Microsoft.Maui.Controls`：

- handlers/host（依赖 Controls 具体类型；90 个 public 类型仍待 API review）；
- `OpenHarmonyFileSystem`：编译进 Core 时在 OH host 触发 `csc` exit 139；先保留在 Controls，
  后续拆 raw-file bridge 或修复编译器问题。

工程改动：

- `src/Core/src/Core.csproj` 增加 6 个 `Compile Include`；
- `src/Controls/src/Core/Controls.Core.csproj` 的 slice glob 排除同一组 6 个文件；
- 6 个文件补显式 `using`，不再依赖 slice 的 `GlobalUsings.OpenHarmony.cs`（该文件仍留在
  Controls 供其余 slice 文件使用）。

验证：

- `verify-slice.sh --tfm` 在同一 6-file split 上曾通过（Core + Controls +
  PublicApiAnalyzers）；
- 随后重试时 OH host 的 `csc` 在 Essentials/Core 阶段出现 exit 139（内存/编译器不稳定），
  不是代码诊断；默认 `verify-slice.sh` 的 slice vehicle + 25/25 测试通过。
- 结论：6 个服务的 split 可编译；`--tfm` 的最终门禁需要一台内存充足的 OH host 重新跑。

验证补充（2026-11-10）：rc3 runtime 的 `libcrypto.so.3` 是 **OpenSSL 3.0.12**；系统
`/usr/lib/libcrypto.so.3` 也是 3.0.12，`openssl@4` 只提供 `.so.4`，所以 `openssl` CLI 升级
4.1.0 不等于 runtime 的 `.so.3` ABI 变了。把 rc3 / 3.5.9 / 4.1.0 的库前置到
`LD_LIBRARY_PATH` 后，`csc` 仍然 hang/crash；`OPENSSL_CONF=/dev/null` + no-locking 只让部分
运行通过，不是确定性修复。结论：`csc` 139 不能只归因于 OpenSSL 版本，需要稳定 host 或
`csc` dump 继续定位。OH 沙箱还会拒绝 `createdump`（`/proc/<pid>/mem` permission denied），
抓 dump 需要非沙箱/稳定 host。`OpenHarmonyFileSystem` 移入 Core 的实验同样受此影响，已回退。
