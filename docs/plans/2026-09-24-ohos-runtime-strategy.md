# OHOS 运行时策略（JIT 现实核查 → 四条路线）(2026-09-24)

> 输入：测试方《ohos-kit22-verification-summary》§4/§6/§7（本机 `~/Download/com.haitai.htbrowser/`）；
> 本仓只读核查 + 华为/OpenHarmony 官方文档检索（2026-09-24）。范围：JIT / 解释器 / NativeAOT / Mono 的取舍。

## 1. 平台策略核实（回应测试方 §4.1/§7.2）

| 主张 | 核查 | 依据 |
|---|---|---|
| 自 HarmonyOS 5.0.0(12) 起禁止匿名内存可执行 | 变更说明存在、第三方引文一致；官方变更页本次抓取失败（需登录），以官方 JSVM/权限文档为准 | 华为 `changelogs-for-all-apps-b031`（引文）；`jsvm-apply-jit-profile` |
| 受限 ACL `ALLOW_EXECUTABLE_FORT_MEMORY` 是 CoreCLR 的钥匙 | **错位**：该权限语义 = "系统 JS 引擎申请带 `MAP_FORT` 标识的匿名可执行内存"（system_basic / system_grant / ACL / API 14+），不是通用 VM JIT 权限 | OpenHarmony `restricted-permissions`（镜像） |
| — | 对口权限另有两条：`ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`（可写可执行匿名内存）与 `...DISABLE_CODE_MEMORY_PROTECTION`；文档限定平板/PC 2in1，社区 2026-04 反馈为受邀申请 | 同上；HiSH #155 |
| 调试/自签包不能申请 | 正确：ACL 随 AGC profile 下发；官方明确"声明权限但无权限证书 → 安装失败" | `jsvm-apply-jit-profile` |
| 发布包经 AGC 申请的现实性 | 低/长线：面向 JSVM 与受邀跨平台框架；且"坚盾守护模式"全局禁 JIT（含已授权应用） | 同上 |

**反证（必须先解决）**：本仓 2026-09-01 真机（HarmonyOS / HongMeng 1.13，**CLI 域**）匿名 `mmap(RWX)`、`mmap(RW)+mprotect(RX)` 均通过、JIT 冒烟全绿；仅 file-backed（memfd）`PROT_EXEC` 被拒——这正是 `EnableWriteXorExecute=0` 默认的由来（`src/coreclr/inc/clrconfigvalues.h:637-643`，提交 `678ac21836c`；证据见 `2026-09-01-ohos-ondevice-verification.md` §1/§6）。测试方崩溃形态（`mprotect(PROT_READ|PROT_EXEC)` 后 `memcpy` → SEGV_ACCERR）恰是 **W^X=1（memfd 双映射）**路径（优先假设，未证实）。在接受"匿名可执行被封"前先做两个决定性复核：① kit coreclr 显式 `DOTNET_EnableWriteXorExecute=0`（关 seccomp）复跑；② HAP 域内 mmap/mprotect/memfd 探针。差异源还可能是 **HAP 应用域 vs CLI 域**（SELinux/seccomp）或 HarmonyOS 7(API 26) vs 旧内核。

## 2. CoreCLR 解释器：在，可构建，不在 stock 包

- **存在**：`src/coreclr/interpreter/**`（`compiler.cpp`/`eeinterp.cpp`/`interpalloc.h`…）；上游 dotnet/runtime#112158（"CoreCLR Interpreter"，Mono 解释器移植，milestone **11.0.0**，已关闭）→ 已在 .NET 11 主线；本仓含最新提交（如 #132539）。
- **构建**：`./build.sh ... -clrinterpreter` → `/p:FeatureInterpreter=true` → `-DFEATURE_INTERPRETER=1`（`src/coreclr/runtime.proj:59`）。`clrfeatures.cmake:82-93` 默认仅 Debug/Checked（排除 Android，**OHOS 未排除**）；Release 需显式开关。
- **出货**：`libclrinterpreter.so` 仅在 Debug/Checked 或 `FeatureInterpreter=true` 进 runtime pack（`src/installer/pkg/sfx/Microsoft.NETCore.App/Directory.Build.props:126-128`）；官方 CI 的可见用途是 SOS 诊断腿（`eng/pipelines/runtime-diagnostics.yml:123-136`）→ **stock RC1 包不含解释器**，需自建。
- **启用**：`DOTNET_InterpMode=1|2|3`（3 = 纯解释：无 JIT/R2R、禁 HW intrinsics、>128bit 向量，tiered 自动关）或 `DOTNET_Interpreter=<MethodSet>`（`interpconfigvalues.h:32-36`、`eeconfig.cpp:452-484`）；`clrinterpreter` 动态加载（`codeman.cpp:4035,5798`）。
- **无 JIT 内存语义**：方法体走非可执行 code heap（`jitinterface.cpp:11906` "Interpreter doesn't use executable memory"；`codeman.cpp:2708` `LoaderCodeHeap(fMakeExecutable=false)`）。
- **残余风险**：非 WASM 仍用 `InterpreterPrecode`，从**可执行** stub precode 堆分配（`precode.cpp:237-256`、`precode.h:310-357`；UMEntryThunk 同池）；只有 WASM-only `FEATURE_PORTABLE_ENTRYPOINTS` 把入口数据化（`loaderallocator.hpp:657-661`；`jitinterface.cpp:13995-14022`）。→ 解释器可能仍需少量匿名可执行页；若 HAP 域全面禁匿名 exec，需追加 portable-entrypoints 试验（非 WASM 可编译性未验证）。
- **最小验证（spike）**：
  1. 交叉构建：`./build.sh clr+libs+host+packs -os openharmony -arch arm64 --cross -c Release -clrinterpreter`（`OHOS_NDK_HOME` + OpenSSL/ICU 见 `2026-08-13-ohos-cross-compile.md`）；
  2. 确认 pack 含 `libclrinterpreter.so`，随 payload 放 HAP `libs/arm64-v8a/`（namespace 允许路径）；
  3. 宿主在 coreclr 启动前 `setenv`：`DOTNET_InterpMode=3`、`DOTNET_EnableWriteXorExecute=0`；**移除 seccomp 拦截器**；
  4. 冒烟 console（Main/泛型/LINQ/Task/GC）；判定：无 SEGV、无匿名 `r-x` 段（`/proc/self/maps`）、栈帧来自解释器；
  5. 失败：记录首个 `PROT_EXEC` 请求来源（precode / UMEntryThunk），再评估 portable-entrypoints。

### Spike 结果（R1-INTERP-SPIKE, 2026-09-26，本机 OHOS aarch64 主机）

**结论：构建侧打通**（`-os openharmony -arch arm64 --cross -c Release` + `-clrinterpreter`）：

- CMake configure 通过（`-DFEATURE_INTERPRETER=1`）。
- `interpreter/libclrinterpreter.so` 构建成功：stripped、**268,320 B（262 KiB）**、sha256 `8bcb573411fd6f0f3e244f496e9ce14b5db22539f7831efb8bc64b5c4ec0d59b`、BuildID `7380afe1b8ae43a56f6246ca8e7cf7eca27cdb90`；`DT_NEEDED = libc++_shared.so, libc.so`，`SONAME=libclrinterpreter.so`；导出 `getJit@@V1.0` / `jitStartup@@V1.0`（与 libclrjit 同 ABI）；`GNU_STACK = RW`（无 exec stack）。
- 解释器相关 VM TU 在 `FEATURE_INTERPRETER=1` 下逐一编译通过（`logs/build-vm-interp.log`，15/15）：`eeconfig.cpp`/`precode.cpp`/`method.cpp`/`codeman.cpp`/`jitinterface.cpp`/`interpexec.cpp`（`cee_wks_core`/`cee_wks`）；只有 `'++lse' is not a recognized feature` 一类无害告警 → 编译器层对 openharmony-arm64 无解释器相关阻塞。
- 全量 `libcoreclr.so` 链接本轮未完成（`logs/build-coreclr.log`）：`clr.native` 的 ninja 在 `[2/651]` 失败于 `libs-native/System.Globalization.Native/pal_common.c` → `fatal error: 'unicode/ucurr.h' file not found`（`$SCR/icu/include` 是空占位）。coreclr 内嵌的 `src/native/libs`（Crypto 用 OpenSSL、Globalization 用 ICU）要**真实 OHOS 交叉资产**；本机 `/tmp/icu-ohos-install` 与 `/tmp/openssl-ohos` 已丢失，须先用 sdk-ohos `eng/ohos-install/build/ohos-ci-env.sh` 重建。不影响解释器库这一 spike 主产物。
- 证据（构建机 scratch）：`logs/configure.log`（`CONFIGURE_EXIT=0`，6 min 10 s）、`logs/build-interp.log`（52/52，含 strip）、`logs/build-vm-interp.log`、`logs/build-coreclr.log`、`artifacts/libclrinterpreter.so{,.dbg}` 副本；主产物在 `artifacts/obj/coreclr/openharmony.arm64.Release/interpreter/`（`.dbg` 1,481,472 B，同 BuildID）。

**开关细节（细化 §2）**：

- `./build.sh … -clrinterpreter`（`eng/build.sh:397`）→ `/p:FeatureInterpreter=true` → `runtime.proj:59` 追加 `-cmakeargs "-DFEATURE_INTERPRETER=1"`；`src/coreclr/CMakeLists.txt:284` 据此 `add_subdirectory(interpreter)`。
- `clrfeatures.cmake:82-93`：默认仅 Debug/Checked 打开；Release 必须显式传开关；排除 Android，**不排除 openharmony**（arm64 在允许列表）。
- `FEATURE_STANDALONE_GC` 与解释器**无耦合**：默认 1（`clrfeatures.cmake:95`），OHOS 不在清零列表（`CMakeLists.txt:34`，仅 Apple 移动/WASM/Android）；解释器只链接 `gcinfo` + `minipal` + `dn-containers`。
- 入 pack 判定：`src/installer/pkg/sfx/Microsoft.NETCore.App/Directory.Build.props:126-128` 仅在 Debug/Checked 或 `FeatureInterpreter=true` 时把 `libclrinterpreter.so` 加进 runtime pack；本机 stock RC1 pack 的 13 个 native lib 已核对，无解释器。
- 纯解释模式：`interpconfigvalues.h:32-36` `DOTNET_InterpMode=3`（全解释、隐含 `DOTNET_ReadyToRun=0`、`DOTNET_EnableHWIntrinsic=0`、tiered 关）；`DOTNET_Interpreter=<MethodSet>` 为按方法集 opt-in；`codeman.cpp:5809` 按 `MAKEDLLNAME_W("clrinterpreter")` 动态加载，`DOTNET_InterpreterName` 可覆盖。

**本机（OHOS 主机）复现绕过**（均为主机环境/属性，零源码改动；复现脚本 `scripts/ohos-runtime-clrinterpreter-build.sh`，即本次 scratch `run-configure.sh` 的泛化版）：

1. `uname -s = HarmonyOS` → Arcade `eng/common/native/init-os-and-arch.sh` 报 `Unsupported OS harmonyos detected!`；用 PATH 前置的 `uname` shim（仅 `-s` 输出 `Linux`）绕过（不碰 `eng/common`）。
2. `global.json` 要求 bootstrap SDK `11.0.100-rc.1.26420.103`，公网不可得（builds.dotnet.microsoft.com 404、ci.dot.net 超时）。令 `DOTNET_INSTALL_DIR` 指向 scratch 布局（`sdk/11.0.100-rc.1.26420.103` 符号链接 → 已装 `26451.109`）；Arcade 只做目录存在性检查，实际由 host rollForward 使用 26451.109。
3. OHOS seccomp 禁止 MSBuild 出进程节点绑定控制 UDS（`SocketException (13): Permission denied`，已见 `MSBuild_pid-*.failure.txt`）→ 追加 `/m:1`（末位覆盖 Arcade 的 `/m`）+ `DOTNET_CLI_USE_MSBUILD_SERVER=0`。
4. 静态图 restore 的 `NuGet.Build.Tasks.Console` 子进程在 OHOS 上 `System.Console.get_Out()` 抛 `PlatformNotSupportedException` → `/p:RestoreUseStaticGraphEvaluation=false`。
5. `dotnet tool restore`（Arcade `Tools.proj`：coverlet/xharness…）在 OHOS 上失败（`Settings file 'DotnetToolSettings.xml' was not found in package 'coverlet.console@6.0.4'`，包本身完整）→ `/p:_RepoToolManifest=/nonexistent` 跳过；native clr 构建不需要这些工具。
6. `cdac-build-tool.csproj` 未进 restore 图（`NETSDK1004`）→ 手工 `dotnet restore`（同全局属性，输出到 `artifacts/obj/coreclr/cdac-build-tool`）。
7. NDK `lld`（26.0.0.18_2）在此主机上加载自带 `llvm/lib/libxml2.so.16` 失败（`Error loading shared library libxml2.so.16`，随后符号全缺失，链接报 `linker command failed due to signal`）；把该 `libxml2.so.16` 复制到 scratch 目录并 `LD_LIBRARY_PATH` 指向即可（configure 与 ninja 都需要）。
8. OpenSSL/ICU 只为 configure 的 `find_package`/头文件检查需要（`clr` 子集会在 coreclr CMake 内配置 `src/native/libs` 的 Crypto/Globalization）；本次用占位 include/lib 满足 configure、且 `ninja` 只编到解释器/VM 目标。**完整 `clr+libs+packs` 需先用 sdk-ohos `eng/ohos-install/build/ohos-ci-env.sh` 重建 OHOS 交叉 ICU/OpenSSL**。

**启用/入 pack 最小步骤（不发布）**：

- **前置（关键加载条件）**：解释器加载路径全在 `#ifdef FEATURE_INTERPRETER` 内——`InterpreterJitManager::LoadInterpreter`（`codeman.cpp:3995-4040`）、`GetInterpreterName`（`codeman.cpp:5795-5811`）、开关解析（`eeconfig.cpp:451-484`、`interpreter/interpconfigvalues.h`）。本机 stock RC1 pack 的 `libcoreclr.so` 已实测**不含** `clrinterpreter`/`InterpMode`/`InterpreterName` 任一宽字符串（UTF-16/UTF-32 均无）→ **只把 `libclrinterpreter.so` 叠进 stock pack 不会生效**；必须先有 `-clrinterpreter` 重建的 `libcoreclr.so`（Release 需显式开关；Debug/Checked 默认开）。overlay 脚本会对目标 coreclr 做该检查并告警。
- 脚本 `scripts/ohos-runtime-clrinterpreter-overlay.sh <libclrinterpreter.so> --pack <runtime-pack.nupkg> [--install-cache]`，或 `--dir <已解开的 shared/publish 目录>`（假定目标 coreclr 已启用 `FEATURE_INTERPRETER`）；目标位置 `runtimes/openharmony-arm64/native/libclrinterpreter.so`（与 `libcoreclr.so` 同目录即可被宿主 `dlopen` 找到）。
- 应用/设备启动前注入：`DOTNET_InterpMode=3`（纯解释，隐含 `DOTNET_ReadyToRun=0`/`DOTNET_EnableHWIntrinsic=0`）——宿主已支持从应用沙箱 `<files>/interp.txt`（首字符数字）读取该值（见 §2「设备侧验证」步骤 3）；可选 `DOTNET_Interpreter=<MethodSet>`；`DOTNET_InterpreterName` 覆盖库名。JIT 回退路径仍需 `DOTNET_EnableWriteXorExecute=0`，并移除 seccomp 拦截器。
- `libc++_shared.so` 必须可解析：解释器 `DT_NEEDED` 与 stock `libcoreclr.so`/`libclrjit.so` 完全一致（`libc++_shared.so, libc.so`），沿用现有 payload/系统解析即可，无新增依赖。
- **残余 W^X 风险不变**：`Precode::AllocateInterpreterPrecode`（`vm/precode.cpp:237-256`）仍从 `GetNewStubPrecodeHeap()->AllocStub()`（可执行 stub precode 堆）分配 → 纯解释模式仍可能产生匿名 exec 页；`FEATURE_PORTABLE_ENTRYPOINTS` 仅 WASM 默认开启，非 WASM 可行性未验证，仍列为备选。

**成本与下一步**：本机 configure ≈10 min（含 restore），解释器 target ≈2 min（-j4），VM 抽样 TU ≈数分钟；全量 `clr.native` 预计 30–60 min（-j4），但需先补真实 ICU/OpenSSL 资产。下一步：sdk-ohos `eng/ohos-install/build/ohos-ci-env.sh` 建交叉资产 → `clr+libs+host+packs -clrinterpreter` 产出 feature-enabled `libcoreclr.so` + pack（或用 `scripts/ohos-runtime-clrinterpreter-build.sh` 只产解释器库）→ 设备侧验证 `DOTNET_InterpMode=3` 启动冒烟、`/proc/self/maps` 匿名 `r-x` 检查、栈帧来自解释器。

### R2-INTERP-FULL 结果（2026-09-26）：feature-enabled runtime 构建成功，CLI 域运行被平台代码完整性阻断

**1) 交叉依赖重建（R1 阻塞解除）**：`/tmp` 资产已丢，离线重建：

- ICU 75.1：仓内源码 `icu4c-75_1-src.tgz` → 交叉静态构建（`--enable-static --disable-shared --with-data-packaging=static`、OHOS NDK clang、`-fPIC`）；`libicuuc.a` 4,826,018 B / `libicui18n.a` 8,524,842 B / `libicudata.a` 30,729,916 B，含 `unicode/ucurr.h`。
- OpenSSL 3.3.1：GitHub release tarball（网络可达）→ `./Configure linux-aarch64 no-shared no-tests no-async no-module` + `make build_libs install_dev`；`libcrypto.a` 9,125,248 B / `libssl.a` 1,706,390 B。
- 复现坑（已固化进脚本）：① NDK `lld` 需 `LD_LIBRARY_PATH` 指向自带 `libxml2.so.16` 的 scratch 副本（quirk #7）；② 交互式 harmonybrew shell 导出的 `CPPFLAGS=-I~/.harmonybrew/include`（ICU **78** 头）会遮蔽 ICU 75 源码，脚本内 `unset CPPFLAGS CFLAGS CXXFLAGS LDFLAGS` 后通过。

**2) 全量构建（`-clrinterpreter`，Release/openharmony-arm64）**：

- 用 `-subset clr.native`（而非 `clr+libs`）：`clr.tools` 的 ILCompiler/crossgen2 host 工具在 `ohos-arm64` RID 上触发 `NETSDK1084`（SDK 无 apphost 解析）且与本产物无关；`clr.native` 已包含 `clr.runtime`/`clr.jit`/`clr.hosts` 及 `src/native/libs` 全量本机库。
- NuGet：本机所有 dnceng/nuget.org 源不可达（超时），改用只读全局缓存的 `NuGet.offline.config`（`<clear/>`）以快速失败/离线恢复（`clr+libs` 曾在源上挂死 10+ min）。
- 两处 clean-build 修复：① `src/native/libs/System.Native/pal_process.c` 的 `CLOSE_RANGE_CLOEXEC` 在 OHOS 下定义但所有使用点都被 `!TARGET_OPENHARMONY` 排除 → `-Werror,-Wunused-macros`；补 `!defined(TARGET_OPENHARMONY)` 到定义（fork 自身补丁的 guard 不一致）；② `libruntimeinfo.a` 链接顺序（clean build 先链 singlefilehost）→ 预构建 `ninja debug/runtimeinfo/libruntimeinfo.a`（sdk-ohos 脚本同款自愈）。
- 产物（`artifacts/bin/coreclr/openharmony.arm64.Release/`）：`libcoreclr.so` **5,163,096 B**、sha256 `1ae17c23f1e161853ca8b540b0c1f14e464af8628f499e85fea4a3bbc5d04af8`（`FEATURE_INTERPRETER=1`；宽字符串 `clrinterpreter`/`InterpMode`/`InterpreterName` 全在；`DT_NEEDED` 与 stock 一致：`libc++_shared.so, libc.so`）；`libclrinterpreter.so` **268,320 B**、sha256 `5f87067920b75eab0bbcd87c1716ba80ef98851bda08ab53b4a470ae7a9750ca`（export `getJit`/`jitStartup`）。构建脚本 `scripts/ohos-runtime-interp-fullbuild.sh`；日志 `full-build.log`/`.binlog`、`fullbuild-native*.log`。

**3) overlay 资产**：`scripts/ohos-runtime-clrinterpreter-overlay.sh <interp.so> --dir <stock pack 布局>` 输出 `coreclr interpreter support: YES (clrinterpreter, InterpMode, InterpreterName)`；打包 `ohos-interpreter-pack.tar.gz`（`native/{libcoreclr.so,libclrinterpreter.so}` + `README.md` + `VERIFICATION.md` + `SHA256SUMS` + `build-info.json`；**2,419,988 B**，sha256 `a10699b3da9c26602556ce141375644d61541bfdfe7d3eceff2de52aa113f873`；本地路径 `/data/storage/el2/base/tmp/opencode/r2-interp/assets/`）。**未发布 release**（自验未完成，见下）。组合方式：kit payload HAP `libs/arm64-v8a/` 替换 `libcoreclr.so` + 新增 `libclrinterpreter.so` → 重新打包签名；env `DOTNET_InterpMode=3`、`DOTNET_EnableWriteXorExecute=0`。

**4) 本机 CLI 域自验：被平台代码完整性策略阻断（非构建问题）**。overlay root（自带 muxer/hostfxr + stock 框架 + 两个新 `.so`）启动 hello 时在 dlopen 阶段失败：`Error loading shared library .../libcoreclr.so: Permission denied`（`HRESULT 0x80008088`）。最小探针复现：

| 探针 | 结果 |
|---|---|
| 现编 `tiny.so` / 构建产物 `libclrinterpreter.so`、`libcoreclr.so`、`corerun` → dlopen/exec | **EACCES** |
| stock `libSystem.Native.so` / `dotnet` 复制到同目录 → dlopen/exec | **OK** |
| 修改 stock 副本（追加 1 字节） | **EPERM**（HMFS 密封） |
| 两者 xattrs（`security.selinux`/`security.isolate`/`user.hmdfs.perm`） | 完全一致 |

即：CLI（hishell）域只允许**可信来源安装**的 ELF 做 file-backed `PROT_EXEC`（execve/mmap），HMFS 对被信任文件加密封（EPERM）；与本机构建产物的 label 无关。这与 §1 已记录的「file-backed（memfd）PROT_EXEC 被拒、匿名 exec 通过」一致 → **本机构建的 runtime 在 CLI 域不可运行**，唯一执行路径是 HAP/应用域（签名 bundle 内 `libs/`）。

**下一步（解释器）**：将 overlay 走 kit payload（HAP `libs/arm64-v8a` → 重新签名 → 安装），在 HAP 域复跑判定点（maps 含 `libclrinterpreter.so`、`InterpreterName` 负对照、匿名 `r-x` 计数、hello 输出）；再决定是否发布资产。CLI 域验证路线至此关闭（平台策略，预期固件/HAP 域差异待测试方复核）。

### 设备侧验证（interpreter）（2026-09-26，R2-INTERP-PUBLISH）

解释器 pack 已发布为可测试资产：release `device-test-kit`（`springmin/sdk-ohos`）新增 3 个资产、其余资产零改动——`ohos-interpreter-pack.tar.gz`（id `590052493`，2,419,988 B，sha256 `a10699b3…13f873`）、其 `.sha256`（id `590067457`）与 `ohos-interpreter-pack-README.md`（id `590050562`）。上文 R2-INTERP-FULL 的「4) 本机 CLI 域自验」已确认 CLI 域被平台封印阻断，**唯一验证域是签名 HAP**；步骤：

1. **预签/安装**：按 kit handoff 的签名流程预签/重签 HAP 后 `hdc install` 安装；重签会改变包哈希，以本地重签件为准。
2. **应用 pack**：解包资产并核对 `sha256sum -c SHA256SUMS`（应全过）。在 payload 的 HAP `libs/arm64-v8a/` 内**替换** `libcoreclr.so`、**新增** `libclrinterpreter.so`（kit #27 的 payload-in-libs 布局 `libs/arm64-v8a/`；kit #28 的 payload 同法。`.dotnet-payload.json` 只锚入口程序集/`dotnet.zip`，不锚 native 库），随后重新打包签名。已解开的本地布局可直接用 `scripts/ohos-runtime-clrinterpreter-overlay.sh <pack>/native/libclrinterpreter.so --dir <layout>`（脚本会核对目标 coreclr 含 `clrinterpreter`/`InterpMode` 宽字符串并打印 `coreclr interpreter support: YES`）。
3. **env（coreclr 初始化前进入应用进程）**：`DOTNET_InterpMode=3`、`DOTNET_EnableWriteXorExecute=0`（后者宿主自 kit #24 起默认已 `setenv`；**前者宿主已支持**：在应用沙箱 `<files>/interp.txt` 写入首字符为数字的值（如 `3`）即可——宿主在 coreclr 启动前（`OhosHostApplyExecMemoryPolicy`，与 `xwe.txt` 同一 A/B 位置）读取并 `setenv("DOTNET_InterpMode", <值>)`，日志 `interp=<v> source=file|default`；无文件则不写入该变量（环境已有的值保持不变），运行时默认 JIT 路径不变。测试方无需再等待宿主/启动路径注入）；可选 `DOTNET_InterpreterName`（负对照用）。
4. **判定点（须全部成立）**：① 启动日志/hilog 出现解释器生效迹象（`libclrinterpreter.so` 被 dlopen；runtime 若无显式行，以 ② 为准）；② 运行中 `/proc/self/maps` 含 `libclrinterpreter.so`（只在解释器激活时加载）；③ `/proc/self/maps` **无匿名 `r-x`**（残余 W^X 判定点）；④ managed app 正常输出/首帧，无 `SEGV_ACCERR`；⑤ 负对照 `DOTNET_InterpreterName=libclrinterpreter-missing.so` 必须启动失败（证明开关被解析而非忽略）。
5. **风险与口径**：残余匿名 exec 页可能来自 `Precode`/UMEntryThunk stub（解释器代码堆本身不可执行）；③ 不达标先记录，勿改 W^X。解释器性能数量级慢于 JIT，本 pack 只回答「可用性/可行性」。
6. **包内文档勘误**：`VERIFICATION.md` 的 `libclrinterpreter.so` BuildID 行（`7380afe1…`）系 R1 spike 残留，实际 `0bd8fdfc…`；「未发布 release」为打包时状态，以本小节为准。哈希/尺寸/`NEEDED`（`libc++_shared.so, libc.so`）/宽字符串已逐项复核一致。

## 3. 四条路线对比

| 路线 | 机制 | OHOS 现状（本仓证据） | 阻塞/成本 | 结论 |
|---|---|---|---|---|
| JIT + ACL | CoreCLR JIT（W^X=0 匿名 RWX） | lab CLI 域已验证可用；HAP 域待复核 | 对口 ACL 限 2in1/受邀；坚盾模式全局禁 | 不作路线（长线合作） |
| CoreCLR 解释器 | `-clrinterpreter` + `DOTNET_InterpMode=3` | 源码/开关齐备，OHOS 未排除；export 侧未验证 | 残余 exec 入口桩；性能（数量级慢于 JIT） | 待验证惊喜（bounded spike） |
| **NativeAOT** | ilc 预编译为原生 .so | `openharmony-arm64` 已是 NativeAOT 一等 RID（RID graph:77、`targetingpacks.targets:72`、`SingleEntry.targets:44-48`、`Unix.targets:30,169`）；round-9 真机 publish 打通 | MAUI 平台切片（maui-ohos，非本仓）+ ilc pack（musl NEEDED/exec 位/签名）+ SDK `NETSDK1203` 登记 | **主路线** |
| Mono | full AOT 或解释器 | `src/mono` 无 OPENHARMONY（grep 0） | 整机移植 runtime+BCL；社区明确性能不接受 | 不做 |

- **NativeAOT 两种走法**：(a) 宿主交叉编译——ilc 跑在 x64 主机，`dotnet publish -r openharmony-arm64 -p:PublishAot=true -p:LinkerFlavor=lld -p:SysRoot=$OHOS_NDK_HOME/native/sysroot -p:CppCompilerAndLinker=.../clang`；(b) 预编译包——CI 产 `runtime.*.Microsoft.DotNet.ILCompiler` + runtime pack 入本地 feed，设备端只推已签名 .so。
- **测试方三阻塞的归属**：MAUI `Platform/OpenHarmony/` 空 → maui-ohos 仓库；ilc 不可下载 → 由我们 feed；`NETSDK1203` → SDK 仓库 AOT RID 名单（runtime 侧已登记）。

## 4. seccomp 拦截器评估（结论：不采用）

- 拦截器把 exec 请求降级为 RW：只能让 `coreclr_initialize` 不崩，JIT 代码仍不可执行；对解释器会打断必须可执行的入口桩。→ 仅是诊断探针，不是产品机制（叠加 app 审核/固件差异风险）。
- LD_PRELOAD / RTLD_GLOBAL / GOT/PLT 补丁失败符合预期：coreclr 经 `DT_NEEDED` 直接解析 musl libc；平台另有 `DISABLE_GOTPLT_RO_PROTECTION` ACL，说明 GOT/PLT RO 是刻意防护 → 不再投入。
- 保留物：把"mmap RWX / mmap RW+mprotect RX / memfd exec / JIT 调用"最小探针 HAP 化，与 `DOTNET_EnableWriteXorExecute=0` A/B 一起交测试方取证。

## 5. 推荐与对测试方的回应

1. **NativeAOT 主路线不变**；先解 MAUI 切片 + SDK AOT RID 名单 + ilc pack（自建 feed）。
2. **解释器 spike**（§2）并行做，成功条件 = 全链无匿名 exec 需求；失败即归档。
3. **JIT+ACL 改为长线**：更正 ACL 引用；不建议测试方继续 seccomp/二进制补丁路线。
4. **Mono 不做**。
5. 请测试方先跑决定性 A/B：kit coreclr + `DOTNET_EnableWriteXorExecute=0`（关 seccomp）与 HAP 内 mmap 探针；回传 maps/errno。

## 6. 仍未验证

- HAP 应用域 vs CLI 域、HarmonyOS 7(API 26) vs lab 内核 1.13 的 exec 策略差异；`DOTNET_EnableWriteXorExecute=0` 在 HAP 域是否足以让 JIT 启动。
- 解释器：**构建侧已全量打通**（R2-INTERP-FULL：feature-enabled `libcoreclr.so` + `libclrinterpreter.so` + overlay 资产，见 §2「R2-INTERP-FULL 结果」）；**CLI 域运行侧已关闭**——本机 hishell/CLI 域对任何本机构建（未受信）ELF 的 file-backed `PROT_EXEC` 一律 EACCES，stock 受信文件可运行且被 HMFS 密封（EPERM），故只能在 HAP/应用域验证：`DOTNET_InterpMode=3` 冒烟、`/proc/self/maps` 含 `libclrinterpreter.so`、`DOTNET_InterpreterName` 负对照、残余匿名 exec 页；portable-entrypoints 非 WASM 可行性仍未验证。
- NativeAOT：MAUI 切片、ilc pack 签名/exec 位、SDK `NETSDK1203`；坚盾守护模式对 NativeAOT（预期无影响）。
- 对口 ACL 在 2in1/受邀之外机型的实际可达性。
