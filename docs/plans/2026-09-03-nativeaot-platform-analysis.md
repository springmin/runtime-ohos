# NativeAOT 平台分流机制分析：macOS / linux-musl / OpenHarmony

**Date:** 2026-09-03 · **Repo:** runtime-ohos (feature/ohos-cross-runtime) · **Scope:** 只读源码分析

**Purpose:** 为 OHOS 从"linux-musl 继承者"演进为"真正独立旁支"提供基线。回答：三平台在 NativeAOT 工具链各层如何分流、OHOS 当前在哪里被"抹平"成 linux/musl、独立旁支化需要在哪些层补什么。

---

## 0. 结论摘要

1. **OHOS 当前不是独立旁支，而是 linux-musl 的"换皮"**：RID 继承（`ohos → linux-musl → linux`）、MSBuild 映射（`_targetOS: ohos → linux` + `_linuxLibcFlavor: musl`）、CMake 映射（`CLR_CMAKE_TARGET_OPENHARMONY` 仅作附加 flag）、ilc 内部零 OHOS 概念（`TargetOS` 枚举无 ohos）、NativeAOT runtime C++ 零 `TARGET_OPENHARMONY`。
2. **真正的旁支是 Apple 系**：从 RID（`osx → unix` 不经 linux）到 MSBuild（`_IsApplePlatform`）、ilc（`TargetOS.OSX/MacCatalyst/iOS/tvOS` 枚举 + `IsApplePlatform`）、runtime（`TARGET_APPLE` 伞宏 + ObjC 层）、native 库（`Cryptography.Native.Apple` / SecureTransport）全链路独立。
3. **独立旁支化的代价主要在工具链集成层（MSBuild targets + CMake）**，ilc/runtime 源码层 OHOS 可保持"linux 特例 + 少量 `TARGET_OPENHARMONY` guard"的混合模式——与 Android（同为 linux 继承者但已相当独立）看齐是务实的中间态。
4. **已知缺陷**：`Microsoft.NETCore.Native.Unix.targets` 中 OHOS 分支依赖 `CrossCompileRid.StartsWith('ohos-')`，本机（host==target）publish 时该属性为空 → 走错分支（真机 round-9 已实证：bfd 链接器 + 误链 Net.Security.Native）。独立旁支化必须修此根因。

---

## 1. RID 层（`src/libraries/Microsoft.NETCore.Platforms/src/runtime.json`）

```
ohos       → #import [linux-musl]
ohos-arm64 → #import [ohos, linux-musl-arm64]
linux-musl → #import [linux]
osx        → #import [unix]            ← 不经 linux
osx-arm64  → #import [osx, unix-arm64]
```

| 平台 | RID 父链 | 含义 |
|---|---|---|
| osx | unix | 独立分支，无 linux 血缘 |
| linux-musl | linux → unix | linux 的 libc 变体 |
| ohos | **linux-musl** → linux → unix | musl 的超集，内核无关但 libc=musl |

含义：**RID 层面 ohos 就已继承全部 linux-musl 资产**；若独立化，需新增 `ohos → #import [unix]`（去掉 musl 继承）并在各层改用显式 ohos 分支——但这会丢失 musl 兼容资产的自动继承，属于破坏性变更，必须与各层 guard 改造同步。

---

## 2. 工具链集成层（MSBuild + CMake）—— OHOS 在此被"抹平"的主战场

### 2.1 MSBuild：`src/coreclr/nativeaot/BuildIntegration/Microsoft.DotNet.ILCompiler.SingleEntry.targets:40-51`

```xml
<!-- ohos is a standalone RID (kernel-agnostic) but uses musl libc; map it here. -->
<_linuxLibcFlavor Condition="'$(_targetOS)' == 'ohos'">musl</_linuxLibcFlavor>   <!-- :49 -->
<_targetOS Condition="$(_targetOS.StartsWith($(_linuxToken)))">linux</_targetOS>  <!-- :50 -->
<_targetOS Condition="'$(_targetOS)' == 'ohos'">linux</_targetOS>                 <!-- :51 -->
```

- **osx**：`_targetOS` 保持 `osx` → 下游 `_IsApplePlatform=true`（`Microsoft.NETCore.Native.targets:33`）全套 Apple 分支。
- **linux-musl**：`_linuxLibcFlavor=musl`，`_targetOS=linux`。
- **ohos**：显式两行映射到 linux + musl —— 即 ohos 与 alpine 在 MSBuild 层**完全同化**（仅剩 CrossCompileRid/CrossCompileAbi 里的 `ohos-` 前缀残留）。

### 2.2 MSBuild：`Microsoft.NETCore.Native.Unix.targets` 关键分流

| 行 | 条件 | 行为 | osx | linux-musl | ohos |
|---|---|---|---|---|---|
| :25-32 | LinkerFlavor | freebsd/openbsd/bionic/ohos*/android→lld; linux→bfd | (Apple 不走) | bfd | lld* |
| :33 | `_linuxLibcFlavor==musl` | `IlcDefaultStackSize=1572864` | — | ✓ | ✓ |
| :56-62 | CrossCompileAbi | `ohos-`→ohos; `linux-musl-`/`alpine-`→musl; bionic/android→android24 | — | musl | ohos |
| :80-85 | TargetTriple | `$(arch)-linux-$(abi)` (alpine 特例) | Apple 用 `x86_64-apple-macosXX`(:119-124) | arch-linux-musl | arch-linux-ohos |
| :129-148 | Apple SDK | xcrun --sdk 取 SysRoot | ✓ | — | — |
| :164-172 | NetCoreAppNativeLibrary | Net.Security.Native 排除: tvOS/bionic/ohos* | 链 (除 tvOS) | 链 | **不链** |
| :231-239 | NativeFramework | CoreFoundation/CryptoKit/Foundation/Network/Security/GSS | ✓ | — | — |
| :242-256 | NativeSystemLibrary | objc/swiftCore/icucore/… Apple; rt 排除 bionic/openbsd | 多 objc 等 | rt 等 | rt 等 |

（* 见 §6 缺陷：`CrossCompileRid` 依赖）

### 2.3 CMake：`eng/native/configureplatform.cmake`

```cmake
# :16-20  OHOS 由 NDK toolchain 设 CMAKE_SYSTEM_NAME=OHOS → 立即改写为 linux+musl
if(CLR_CMAKE_HOST_OS STREQUAL ohos)
    set(CLR_CMAKE_HOST_OS linux)
    set(CLR_CMAKE_HOST_LINUX_MUSL 1)
    set(CLR_CMAKE_HOST_OPENHARMONY 1)     # 唯一保留的 OHOS 痕迹
endif()

# :350-369 target 侧
linux        → TARGET_UNIX + TARGET_LINUX
host musl    → + TARGET_LINUX_MUSL
HOST_OPENHARMONY → TARGET_OPENHARMONY      # 附加 flag，不改变 linux/musl 身份
darwin       → TARGET_UNIX + TARGET_APPLE + TARGET_OSX   # 真独立
android      → TARGET_UNIX + TARGET_LINUX + TARGET_ANDROID  # 参考系：linux 继承者但更独立
```

### 2.4 CMake 编译宏注入：`eng/native/configurecompiler.cmake:840-890`

```cmake
CLR_CMAKE_TARGET_UNIX   → -DTARGET_UNIX
CLR_CMAKE_TARGET_APPLE  → -DTARGET_APPLE
CLR_CMAKE_TARGET_OSX    → -DTARGET_OSX
CLR_CMAKE_TARGET_LINUX  → -DTARGET_LINUX
CLR_CMAKE_TARGET_LINUX_MUSL → -DTARGET_LINUX_MUSL   # (TARGET_MUSL 不存在)
CLR_CMAKE_TARGET_OPENHARMONY → -DTARGET_OPENHARMONY
```

注意：**没有 `TARGET_MUSL` 宏，只有 `TARGET_LINUX_MUSL`**；`TARGET_OPENHARMONY` 存在但 NativeAOT runtime 不用（见 §4）。

---

## 3. ilc 编译器层（C#）—— OHOS 完全隐身

### 3.1 TargetOS 枚举与解析

`src/coreclr/tools/Common/TypeSystem/Common/TargetDetails.cs:12`：

```csharp
public enum TargetOS { Unknown, Windows, Linux, OSX, MacCatalyst, iOS, iOSSimulator,
                       tvOS, tvOSSimulator, FreeBSD, NetBSD, OpenBSD, SunOS, Browser, Wasi }
```

`src/coreclr/tools/Common/CommandLineHelpers.cs:78-93`：`GetTargetOS(token)` —— "linux"/"android"→Linux；**无 ohos**。MSBuild 层传 `--targetos linux`，ilc 无从知道 ohos。

### 3.2 Apple vs Linux 在 ilc 内的分流点（全部经由 TargetDetails 属性）

Apple 专属（`Target.OperatingSystem` 属 OSX/MacCatalyst/iOS/… → `IsApplePlatform`，见 `TargetDetails.cs` IsApplePlatform 属性定义区）：
- `InstructionSetHelpers.cs`（Common）：x64 Apple 基线 x86-64-v2（非 Apple 可 v3）、ARM64 Apple 用 apple-m1 baseline
- `PETargetExtensions.cs`（ObjectWriter）：OS → 目标文件格式，Apple→Mach-O
- `MachObjectWriter.cs`：Mach-O 输出（LC_BUILD_VERSION 等）
- `MarshalHelpers.cs`：ObjC 互操作（objc_msgSend 待决异常检查、ObjC block marshalling）
- `EETypeBuilderHelpers.cs`：Apple 专属 tracked-reference-with-finalizer 布局
- `CorInfoImpl.cs`（TargetToOs）：JIT 只收三态 —— **CORINFO_OS: WINNT / APPLE / UNIX**（ohos/musl 都报 UNIX）
- 入口点/符号：Apple 前置 `_`（`_SymbolPrefix`）

Linux 专属（ohos/musl 一起走）：
- `CorInfoImpl.cs`（ARM64 unwind）：linux → CompressARM64CFI
- `CorInfoImpl.RyuJit.cs`：x64/arm64 linux+win → ThreadStatic 内联 TLS（Apple 无）
- 其余大量逻辑只分 Windows / 非 Windows（`IsWindows`），Apple 与 Linux/ohos 同侧

结论：**ilc 内部 OHOS 与 musl 完全同路**；若独立化，至少需 `TargetOS.OHOS`（或复用 Linux + 新 flag 传参）——但 ilc 的 OS 相关行为（布局/异常/互操作）几乎都在 Linux 与 Apple 之间二分，ohos 与 linux 在这些点上无差异可拆。

---

## 4. NativeAOT Runtime 层（C++）—— OHOS 零存在

`src/coreclr/nativeaot/Runtime/` 全局统计：
- `TARGET_OPENHARMONY`：**0 处**
- `TARGET_LINUX_MUSL` / `TARGET_MUSL`：**0 处**
- `TARGET_OSX`：**0 处**（Apple 一律用伞宏 `TARGET_APPLE`）
- `TARGET_LINUX`：少量（PalUnix.cpp dl_iterate_phdr 取 build-id、pthread_key 线程关闭探测等）
- `TARGET_UNIX`：主 guard（thread/threadstore/startup/EHHelpers/Pal.h…）
- `TARGET_APPLE`：6 处以上（UnixNativeCodeManager、UnwindHelpers、PalUnix mach vm_remap thunk 分配、ObjC 互操作文件 `interoplibinterface_objc.cpp` 仅 Apple 编译等）

唯一进入 NativeAOT 且带 OHOS guard 的源码是**共享 GC** `src/gc/unix/numasupport.cpp`（OHOS/Android → 空桩，禁 NUMA）。

CMake 源文件分组（`Runtime/CMakeLists.txt`）：Windows / Unix（含全部 Apple+linux+ohos）二分；Apple 额外加 `interoplibinterface_objc.cpp`；libunwind 符号本地化 Apple OFF、其余 Unix ON。

结论：runtime C++ 层 OHOS 与 linux 零差异。独立化在此层无实质内容（除非将来有 OHOS 特有 syscall/信号/内存语义要 guard）。

---

## 5. Native 库层（`src/native/libs`）—— OHOS 已有专属分支，但以"排除"为主

### 5.1 主 CMakeLists：`src/native/libs/CMakeLists.txt:150-175`

| 平台 | System.Net.Security.Native | 密码学库 |
|---|---|---|
| Apple (非 tvOS) | ✓ 构建（GSSAPI） | `Cryptography.Native.Apple`（SecureTransport + Network.framework）|
| Android | — | `Cryptography.Native.Android` |
| **OHOS** | **✗ 跳过**（无 krb5/gssapi，:165） | `Cryptography.Native`（OpenSSL，:164）|
| linux / musl | ✓ | `Cryptography.Native`（OpenSSL）|

### 5.2 平台宏体系（`configureplatform.cmake` + 各库 CMakeLists）

- OHOS 特有宏：`CLR_CMAKE_TARGET_OPENHARMONY`（附加在 linux+musl 之上）
- musl：`CLR_CMAKE_TARGET_LINUX_MUSL`（Alpine 与 OHOS 都置位）
- 源码内平台判断用 `TARGET_APPLE` / `TARGET_ANDROID` / `TARGET_LINUX_MUSL` 等编译宏（由 §2.4 注入），另有少量 `__OHOS_FAMILY__` 等编译器内建宏

### 5.3 关键结论：macOS 的 TLS 不在 Net.Security.Native

macOS SslStream = managed `SslStreamPal.OSX.cs` → `Cryptography.Native.Apple` 的 `pal_ssl.c`（SecureTransport）+ `pal_networkframework.m`（异步 Network.framework）；mac 的 Net.Security.Native 只含 GSSAPI。OHOS 由于整体跳过 Net.Security.Native + 自带 OpenSSL，与 linux 走同一 Cryptography.Native(OpenSSL) 路径。

---

## 6. 已知缺陷（round-9 真机实证，独立化必改）

`Microsoft.NETCore.Native.Unix.targets` 的 OHOS 判断全部依赖 **`$(CrossCompileRid).StartsWith('ohos-')`**（:30 lld、:59 ABI、:167 Net.Security 排除），但 `CrossCompileRid` 仅在 host≠target 时赋值（Unix.targets:47-48）：

```xml
<CrossCompileRid />
<CrossCompileRid Condition="'$(_hostOS)' != '$(_originalTargetOS)' or '$(_hostArchitecture)' != '$(_targetArchitecture)'">$(RuntimeIdentifier)</CrossCompileRid>
```

→ **本机（host==target==ohos-arm64）publish 时 CrossCompileRid 为空**：
- LinkerFlavor 落到 :32 linux→**bfd**（OHOS NDK 只有 lld）→ 链接失败
- :167 排除失效 → 误链不存在的 libSystem.Net.Security.Native.a → 链接失败

设备侧 workaround：`-p:LinkerFlavor=lld` + Directory.Build.targets 移除 Net.Security.Native（round-9 completion 已记录）。

**根因修复方向**：OHOS 判断应从 `CrossCompileRid` 迁移到 `'$(_originalTargetOS)' == 'ohos'`（本机+交叉都成立）或 `RuntimeIdentifier.StartsWith('ohos-')`。此改动同时是独立旁支化的第一块基石。

---

## 7. 独立旁支化路线图（分层工作项）

> 目标形态参照：**Android**（linux 继承者，但拥有 TARGET_ANDROID 专属宏、独立 native 库分支、独立 ilc 入口）为务实中间态；**Apple**（彻底独立 RID/枚举/宏）为终极态。OHOS 的独立诉求主要是：① 不再被 musl 资产误伤（如 Net.Security.Native 这种"musl 有而 OHOS 无"的库）；② 内核无关语义（无 bfd、无 krb5、NUMA 禁、syscall 面不同）有专属表达；③ 本机 publish 正确。

### L1 — 工具链 MSBuild（最高优先，含 bug 修复）
- [ ] Unix.targets :30/:59/:167 的 `CrossCompileRid.StartsWith('ohos-')` → 增加/替换为 `'$(_originalTargetOS)' == 'ohos'`（修 §6 缺陷，交叉+本机双覆盖）
- [ ] SingleEntry.targets:49-51：评估是否保留 `_targetOS=linux` 抹平 vs 引入 `_targetOS=ohos` 直通 + Unix.targets 显式 ohos 分支（需同时改 ilc 调用参数面）
- [ ] 新增 ohos 专属属性面（如 `_IsOHOS`）镜像 `_IsApplePlatform`，供后续独立分支挂载

### L2 — CMake（eng/native）
- [ ] `configureplatform.cmake`：保留 `CLR_CMAKE_TARGET_OPENHARMONY` 作为一等变量（已是），评估增加 `CLR_CMAKE_TARGET_OHOS` 与 linux/musl 解耦（对照 android 的 TARGET_ANDROID 模式）
- [ ] `configurecompiler.cmake`：宏注入面已支持 TARGET_OPENHARMONY ✓（无需改），但需在 nativeaot runtime/ilc 侧建立消费点

### L3 — ilc（C#）
- [ ] 决策：`TargetOS.OHOS` 枚举值 vs 维持 Linux。若加枚举，需同步 `CommandLineHelpers.GetTargetOS`（收 "ohos"）、`TargetDetails` 属性、`TargetToOs`（CORINFO_OS 三态外扩 or 复用 UNIX）、`PETargetExtensions`、help 文本
- [ ] 若不加枚举：为 OHOS 引入独立 feature flag（类似 `TargetAbi` 或 ilc 参数 `--targetos linux --libc musl --ohos`），在需要处分流（Net.Security direct-pinvoke 排除等）

### L4 — NativeAOT runtime（C++）
- [ ] 暂无需独立宏（OHOS 与 linux 在 runtime 层零差异）；若未来出现 OHOS 专属语义（如 OHOS 版信号/内存/musl 差异），按 `TARGET_OPENHARMONY` guard 模式追加（GC numasupport.cpp 已有先例）

### L5 — native 库
- [ ] Net.Security.Native 的 OHOS 排除已正确（CMakeLists:165）；若 OHOS 未来提供 krb5/gssapi 可反转
- [ ] Cryptography.Native(OpenSSL) OHOS 路径已工作（round-9 验证）；保持 OPENSSL_* cache var 传递机制
- [ ] 建立"OHOS 专属库分支"模式参照：`Cryptography.Native.Android`/`.Apple` 的目录结构

### L6 — 测试/验证面
- [ ] 本机 publish（host==target）纳入自检：`dotnet publish -r ohos-arm64 -p:PublishAot=true` 为必测项（round-9 已打通）
- [ ] 交叉 publish（host linux-x64 → ohos-arm64）回归：确认 CrossCompileRid 路径仍工作
- [ ] 将 §2.2 的"期望表"固化为 CI 检查（ldd/linker flavor/native 库列表）

---

## 8. 参考文件索引

| 层 | 文件 |
|---|---|
| RID | `src/libraries/Microsoft.NETCore.Platforms/src/runtime.json` |
| MSBuild 映射 | `src/coreclr/nativeaot/BuildIntegration/Microsoft.DotNet.ILCompiler.SingleEntry.targets` (:40-56) |
| MSBuild 链接 | `src/coreclr/nativeaot/BuildIntegration/Microsoft.NETCore.Native.Unix.targets` (:25-33, :47-63, :119-124, :164-179, :231-256, :258-321) |
| MSBuild 通用 | `src/coreclr/nativeaot/BuildIntegration/Microsoft.NETCore.Native.targets` (:32-33 IsApplePlatform) |
| CMake 平台 | `eng/native/configureplatform.cmake` (:14-20, :350-415) |
| CMake 宏 | `eng/native/configurecompiler.cmake` (:840-890) |
| ilc 枚举 | `src/coreclr/tools/Common/TypeSystem/Common/TargetDetails.cs` (:12 枚举, IsApplePlatform/IsWindows 属性) |
| ilc 解析 | `src/coreclr/tools/Common/CommandLineHelpers.cs` (:61-94) |
| ilc Apple/Linux 分流 | `PETargetExtensions.cs` / `MachObjectWriter.cs` / `InstructionSetHelpers.cs` / `MarshalHelpers.cs` / `CorInfoImpl.cs`(TargetToOs, ARM64 CFI) / `CorInfoImpl.RyuJit.cs`(TLS) |
| Runtime C++ | `src/coreclr/nativeaot/Runtime/CMakeLists.txt`, `unix/PalUnix.cpp`, `unix/UnixNativeCodeManager.cpp`, `gcenv.ee.cpp` |
| 共享 GC | `src/gc/unix/numasupport.cpp` (OHOS guard) |
| Native 库 | `src/native/libs/CMakeLists.txt` (:150-175), `src/native/libs/System.Security.Cryptography.Native.Apple/pal_ssl.c` + `pal_networkframework.m`, `System.Net.Security.Native/pal_gssapi.c` |
| 实证记录 | `docs/plans/2026-09-02-cxx-runtime-handoff.md` (round-9: 本机 publish 缺陷 + workaround) |
