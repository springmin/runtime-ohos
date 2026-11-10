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
