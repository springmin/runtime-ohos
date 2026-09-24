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
- 解释器在 openharmony-arm64 的构建与运行；残余 exec 页是否必然出现；portable-entrypoints 非 WASM 可行性。
- NativeAOT：MAUI 切片、ilc pack 签名/exec 位、SDK `NETSDK1203`；坚盾守护模式对 NativeAOT（预期无影响）。
- 对口 ACL 在 2in1/受邀之外机型的实际可达性。
