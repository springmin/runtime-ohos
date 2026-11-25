# VMR 代码构成与本仓移植工作盘点（2026-11-18）

> 范围：`dotnet/dotnet`（VMR）由哪些仓库构成、代码往哪里提；以及 `runtime-ohos`
> 在这套合成代码的 runtime 部分之上做了哪些工作。
> 基线：VMR 快照 = **.NET 10**（本机 `Huawei Share/dotnet.zipdotnet`，SDK `10.0.103`）；
> 本仓 = `release/ohos-11.0.0`（.NET 11 GA `deae2e3`）。两者版本线不同，比较时只看结构不看内容。
> 方法：`src/source-manifest.json` 枚举仓库；`git rev-list --count` / `--author` /
> `--name-only` 统计提交与文件；文件数为 on-disk walk（含测试资产，非编译输入）。

## 1. 结论

1. **`dotnet/dotnet` 不是提功能代码的地方。** 它是由 25 个源仓库（+13 个 submodule）
   通过 `src/source-mappings.json` 同步合成的虚拟单体仓库；组件代码提到各自仓库，
   再由 Maestro/darc 依赖流汇入 VMR。VMR 仓库本身只接受基础设施改动
   （`source-mappings.json`、`patches/`、`repo-projects/`、构建编排）。
2. 本机 VMR 快照含 **25 个仓库、约 18.7 万文件**，其中 `dotnet/runtime` 占 66,751 个文件。
3. 本仓在 `dotnet/runtime` 之上有 **1,113 个自有提交**（878 docs / 235 代码与构建），
   非文档代码文件 **157 个**：CoreCLR 58、libraries 42、native 24、eng/native 6，
   其余为 tests/installer/tools/mono、脚本与 CI。
4. 移植工作可归为 10 个子系统（构建、平台标识、PAL/GC、NativeAOT、host、原生库、
   CoreLib、打包、测试 CI、发布版本），详细见 §4。

## 2. dotnet/dotnet 的代码构成（25 个仓库）

`src/source-manifest.json` 固定每个仓库的精确 commit；按文件数排序：

| 分类 | 仓库 | 文件数 | 作用 |
|---|---|---:|---|
| **运行时** | `dotnet/runtime` | 66,751 | CoreCLR、Mono、NativeAOT、BCL、host、installer/packs |
| **编译器** | `dotnet/roslyn` | 20,304 | C#/VB 编译器、分析器、Razor 后端 |
| | `dotnet/razor` | 14,189 | Razor 编译与工具 |
| | `dotnet/fsharp` | 10,610 | F# 编译器与核心库 |
| | `dotnet/cecil` | 586 | Mono.Cecil IL 读写 |
| | `dotnet/symreader` | 283 | 托管符号读取 |
| | `dotnet/sourcelink` | 550 | PDB SourceLink |
| **Web 框架** | `dotnet/aspnetcore` | 17,492 | Kestrel、SignalR、Blazor、Identity |
| | `dotnet/efcore` | 5,955 | EF Core |
| **工具链** | `dotnet/sdk` | 9,130 | dotnet CLI、MSBuild targets、workload、AOT 管线 |
| | `dotnet/msbuild` | 2,645 | MSBuild 引擎 |
| | `nuget/nuget.client` | 5,333 | NuGet 客户端 |
| | `dotnet/templating` | 1,886 | `dotnet new` 模板 |
| | `dotnet/command-line-api` | 402 | System.CommandLine |
| | `dotnet/xdt` | 244 | MSBuild XDT 转换 |
| **诊断/测试** | `dotnet/diagnostics` | 2,617 | dotnet-dump/trace、SOS |
| | `microsoft/vstest` | 2,396 | 测试平台 |
| | `dotnet/scenario-tests` | 203 | 端到端场景测试 |
| **Windows 桌面** | `dotnet/wpf` | 7,365 | WPF（仅 Windows） |
| | `dotnet/winforms` | 5,983 | WinForms（仅 Windows） |
| | `dotnet/windowsdesktop` | 236 | WindowsDesktop 共享框架 |
| **构建/依赖** | `dotnet/arcade` | 2,078 | 构建基础设施（CI、签名、打包） |
| | `dotnet/source-build-reference-packages` | 9,268 | 源码构建参考包 |
| | `dotnet/emsdk` | 278 | WASM 工具链 |
| | `dotnet/deployment-tools` | 375 | 部署脚本 |
| | | **187,159** | 合计 |

### 2.1 submodule（13 个）

构建/测试用外部依赖，不进入产品代码路径：googletest、MessagePack-CSharp、
NuGet.Build.Localization、abstractions.xunit、ApplicationInsights-dotnet、
azure-activedirectory-identitymodel-extensions-for-dotnet、cssparser、
docker-creds-provider、Humanizer、MSBuildLocator、Newtonsoft.Json、
Spectre.Console、vs-solutionpersistence。

### 2.2 代码流

- 组件仓库 → VMR：每个仓库的指定分支经 `source-mappings.json` 的 include/exclude
  规则同步进 `src/<repo>/`，commit 记录在 `source-manifest.json`。
- 反方向（VMR → 组件仓库）只用于 VMR 特有的补丁/构建修复。
- 因此功能 PR 的**唯一正确去向是组件仓库**，在 VMR 里改 `src/runtime/...`
  会在下次同步时被覆盖。

## 3. 本仓的基线与本仓定位

| 项 | 值 |
|---|---|
| fork 来源 | `dotnet/runtime` |
| 分支 | `release/ohos-11.0.0` |
| 合并基线 | `deae2e3`（upstream release/11.0 GA） |
| 相对 `upstream/main` merge-base（`29afde2`）领先 | 1,433 提交 |
| 其中本仓作者提交 | **1,113**（878 docs / 235 代码与构建） |
| 非文档文件（本仓作者触碰） | **157** |
| `docs/plans` 过程文档 | 373 个条目（含 README） |
| 整分支 diff（含 upstream 合并，仅作量级参考） | 1,003 文件 / +83,079 / −7,218 |

> 说明：整分支 diff 混入了 upstream `release/11.0` 与 main-tail 的合并内容，
> 不能当作 OHOS 净增量；净增量以「本仓作者触碰的 157 个非文档文件」为准。

## 4. 本仓做了什么（按子系统）

| 子系统 | 工作内容 | 代表文件 |
|---|---|---|
| **构建系统** | `openharmony` 作为独立 `TargetOS`（不再用 `linux-ohos`）；接 NDK toolchain、跳过 rootfs、tryrun 走 FIFO 缓存、编译器参数（`-fno-emulated-tls`、`-ftls-model=global-dynamic`、`-Qunused-arguments`） | `eng/RuntimeIdentifier.props`、`eng/build.sh`、`eng/native/{build-commons,gen-buildsys,configureplatform,configurecompiler,configuretools}.cmake`、`eng/Subsets.props`、`eng/liveBuilds.targets` |
| **平台标识 / RID** | portable RID graph 增加 `openharmony`、`openharmony-{arm,arm64,x64}`；`OSPlatformName="OPENHARMONY"`；internal `IsOpenHarmony()`；无 OHOS TFM，用 `SupportedPlatform` 规避 CA1418 | `Microsoft.NETCore.Platforms/src/PortableRuntimeIdentifierGraph.json`、`System.Private.CoreLib/.../OperatingSystem.cs`、`System.Private.CoreLib.Shared.projitems` |
| **CoreCLR 原生层** | PAL configure/link 适配（无 LTTng、无 gcc_s/pthread/rt 特殊链接）；GC NUMA syscall 禁用（seccomp 下 `get_mempolicy`/`mbind` 触发 SIGSYS）；W^X/double-mapping 与 executable allocator 校验；signal 处理；线程/TLS | `src/coreclr/gc/unix/numasupport.cpp`、`src/coreclr/minipal/Unix/doublemapping.cpp`、`src/coreclr/utilcode/executableallocator.cpp`、`src/coreclr/pal/src/*`、`src/coreclr/vm/*` |
| **NativeAOT / ILCompiler** | crossgen2 改为 host IL 工具（`PublishAot=false`）；ILCompiler single-entry 打包；Unix targets；类型名 mangling/boxed types；ModuleHeaders | `src/coreclr/tools/aot/**`、`src/coreclr/nativeaot/BuildIntegration/*.targets` |
| **corehost** | Unix PAL 路径/dlopen 适配；apphost static 使用传统 `--whole-archive`；FX muxer | `src/native/corehost/hostmisc/pal.unix.*`、`apphost/static/CMakeLists.txt`、`fxr/fx_muxer.cpp` |
| **原生库** | System.Native：屏蔽 `close_range`/`inotify_init1`（seccomp trap）、`pal_process`、`pal_signal`、网卡 speed 字段差异；OpenSSL shim：绝对路径 dlopen + 符号本地化 + 静态归档保留；zstd C90 排序；EventPipe portable RID | `src/native/libs/System.Native/*`、`System.Security.Cryptography.Native/opensslshim.c`、`src/native/external/zstd.cmake`、`src/native/eventpipe/ds-portable-rid.c` |
| **CoreLib** | `Path.GetTempPath()` 尊重 `TMPDIR`（OHOS `/tmp` 只读）；`NamedMutex` 禁用 robust pthread mutex；GA 的 Number/Globalization/Numerics 代码同步 | `System.Private.CoreLib/src/System/{IO/SharedMemoryManager,Threading/NamedMutex}.Unix.cs`、`System/Number.*.cs` |
| **打包 / installer** | `openharmony-arm64` 的 CoreCLR/Mono/NativeAOT runtime pack、apphost pack、ILCompiler pack、SFX、targetingpacks；OHOS 禁用 ReadyToRun | `eng/targetingpacks.targets`、`src/installer/pkg/**`、`src/libraries/sfx*.proj` |
| **测试 / CI** | OHOS 运行期缺陷复现套件；crossgen2 smoke；GitHub Actions 复现流水线；csc 卡死看门狗；解释器全量构建脚本 | `src/tests/**`、`.github/workflows/ohos-runtime-repro.yml`、`scripts/ohos-*.sh` |
| **版本 / 发布** | GA 11.0.0、servicing 11.0.1 / SDK 11.0.101、dev 快照、AOT `-rtm` 资产 | `eng/Versions.props` |

### 4.1 与上游的关系

- 文档中引用 **29 处 `dotnet/runtime` PR**；已提交的上游 PR 包括
  **#132827**（`OSPlatformName="OPENHARMONY"`）、**#132953**（RID 导入 `any` 的 review 修正）。
- 安装脚本侧的上游 PR：**dotnet/install-scripts#752**（`openharmony` OS 识别 +
  `--os` 值 + dry-run 测试；仅检测层，feed/签名/workload 留在 fork）。
- 移植按「4 个可独立评审的 PR」组织：
  A 构建基础设施、B RID/packs、C 原生编译修复、D OHOS 沙箱运行期修复。
  早期口径约 34 文件 / 230 行（`2026-08-27-ohos-upstream-pr-prep.md`）。

## 5. 同一产品线的其他仓库

| 仓库 | 基于 | 本项目的改动 |
|---|---|---|
| `springmin/runtime-ohos` | `dotnet/runtime` | 本文 §4 的运行时/AOT/打包工作 |
| `springmin/sdk-ohos` | `dotnet/sdk` | `OpenHarmonyEnvironmentDefaults`、`dotnet-aot`、`OpenHarmonyCodesign`、redist/layout、本地 RID 图注入（约 14 个候选文件） |
| `springmin/aspnetcore-ohos` | `dotnet/aspnetcore` | runtime-pack RID、NativeAOT 关闭、Kestrel/SignalR 修补（约 4–5 个候选文件） |
| `springmin/maui-ohos` | `dotnet/maui` | UI 层适配（**不在 VMR 内**） |
| `springmin/ohos-workload` | 自有仓 | workload 清单、安装器、设备部署脚本 |
| `springmin/install-scripts-ohos` | `dotnet/install-scripts` | `dotnet-install.sh` 的 HarmonyOS/OpenHarmony 支持（OS 识别、feed/直链、SHA256、ELF 签名、workload bundle、`dotnet-install-ohos.sh` 包装）；上游 PR #752 仅含检测层 |

## 6. 提交去向对照

| 改动类型 | 提交目标 |
|---|---|
| CoreCLR / PAL / NativeAOT / BCL / host / packs | `dotnet/runtime` |
| CLI、MSBuild targets、AOT 管线、workload、签名 | `dotnet/sdk` |
| Kestrel / SignalR / Blazor 运行时补丁 | `dotnet/aspnetcore` |
| MAUI 控件与平台实现 | `dotnet/maui` |
| VMR 同步规则、补丁队列、构建编排 | `dotnet/dotnet`（仅基础设施） |
| 不提交上游：`AGENTS.md`、`docs/plans/`、`scripts/ohos-*`、安装/签名脚本、设备侧 shim | 保留在 fork |

## 7. 复现方式

```bash
# 1) VMR 组成（在 VMR 快照根目录）
python3 -c "import json;d=json.load(open('src/source-manifest.json'));\
[print(r['path'], r['remoteUri'], r['commitSha'][:12]) for r in d['repositories']]"

# 2) 本仓提交与文件面
git log --author=springmin --no-merges --oneline $(git merge-base HEAD upstream/main)..HEAD | wc -l
git log --author=springmin --no-merges --name-only --pretty=format: \
  $(git merge-base HEAD upstream/main)..HEAD | grep -v '^$' | grep -v '^docs/' | sort -u | wc -l

# 3) 子系统清单
git log --author=springmin --no-merges --name-only --pretty=format: \
  $(git merge-base HEAD upstream/main)..HEAD | grep '^src/coreclr/' | sort -u
```

## 8. 参考

- `src/source-manifest.json` / `src/source-mappings.json`（VMR 组成与同步规则）
- `2026-08-27-ohos-upstream-pr-prep.md`（PR A–D 拆分与文件清单）
- `2026-09-03-ohos-pr-inclusion-audit.md`（三个仓库的上游候选/排除清单）
- `2026-09-15-ohos-platform-identity.md`（平台身份决策）
- `2026-11-14-ohos-11.0-closeout.md`（GA/servicing/dev 收尾）
