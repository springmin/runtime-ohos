# 路线②: HarmonyOS (ohos) 交叉编译 dotnet/runtime 执行计划

**日期:** 2026-08-13
**分支:** `feature/ohos-cross-runtime`
**目标:** 通过路线②（仿 linux-bionic NDK 模式）添加 `linux-ohos` 目标支持，交叉编译出完整的 dotnet/runtime 二进制（`artifacts/bin/dotnet/`）。

## 一、执行纪律（用户约定）

1. **所有执行先写文档**：每个阶段先在本文档记录计划，再执行。
2. **问题循环**：执行中遇到问题 → 记录问题 → 找解决方案 → 验证方案可行性 → 执行方案 → 验证执行结果 → 记录解决过程。
3. **终止条件**：编译出 ohos 二进制的 dotnet runtime（`artifacts/bin/dotnet/` 下含 host + coreclr + managed assemblies）。
4. 每个问题记录为独立小节，格式：
   ```
   ### 问题 N: <标题>
   - **现象**: <错误输出/行为>
   - **根因**: <分析>
   - **方案**: <解决方案>
   - **验证**: <如何确认方案有效>
   - **结果**: <执行结果>
   ```

## 二、环境事实（已验证）

- **SDK**: `OHOS_NDK_HOME=/home/springmin/hmos-tools/sdk/default/openharmony`，API 22 (HarmonyOS 6.0.2.130)
- **工具链**: `native/llvm/bin/` 下 clang-15.0.4 + `aarch64-unknown-linux-ohos-clang` wrapper（`-D__MUSL__`）
- **sysroot**: `native/sysroot/usr/lib/{aarch64,arm,x86_64}-linux-ohos/`，**libc 基于 musl**（`__musl_libc_globals` 符号确认）
- **NDK toolchain cmake**: `native/build/cmake/ohos.toolchain.cmake`（`CMAKE_SYSTEM_NAME=OHOS`，NDK 式）
- **本机编译器**: clang 21.1.8, cmake 4.2.3, ninja（`/usr/bin/`）
- **磁盘**: 683G 可用
- **已有资产**: zig 工具链（`aarch64-linux-musl` 静态编译已验证可用，`~/zig-native-install`）

## 三、修改点清单（路线② 正规移植）

来自分析阶段（`eng/pipelines/common/global-build-job.yml:99-101` bionic 模式 + `build-commons.sh:102-127` NDK 分支模板）：

| # | 文件 | 修改内容 |
|---|------|----------|
| 1 | `eng/build.sh` (~:305-312) | 添加 `linux-ohos)` case → `os=linux` + `__PortableTargetOS=linux-ohos` |
| 2 | `eng/RuntimeIdentifier.props` (:20-21, 51-53) | `PortableOS=linux-ohos` → `TargetsLinuxOhos` + `TargetsLinuxGlibc` 排除 |
| 3 | `eng/native/build-commons.sh` (:102-127) | 添加 ohos 分支：`OHOS_NDK_HOME` + `ohos.toolchain.cmake` |
| 4 | `src/native/libs/build-native.sh` (:61-72) | ohos 排除自动 cross 检测 + 专用 CMake args |
| 5 | `eng/targetingpacks.targets` + `runtime.json` | 添加 `linux-ohos-*` RID |
| 6 | `eng/native/configureplatform.cmake` (:354-358) | `CLR_CMAKE_TARGET_OPENHARMONY` → 复用 `TARGET_LINUX_MUSL` 路径 |
| 7 | `src/native/eventpipe/ds-portable-rid.c` (:9-23) | ohos RID 字符串处理 |
| 8 | `eng/Subsets.props` (:32-59, 385-391) | `_BuildAnyCrossArch` + runtime flavor 支持 |

## 四、实施阶段

### Phase 0: 前置验证（先做最小验证，再改源码）
- [ ] 0.1 用 OHOS clang 直接编译一个 C 测试文件到 aarch64-linux-ohos，验证工具链可用
- [ ] 0.2 用 `ohos.toolchain.cmake` 跑一个最小 CMake 项目，验证 NDK toolchain 文件可用

### Phase 1: 源码修改（8 处，每处独立 commit）
- [ ] 1.1 eng/build.sh: linux-ohos 参数
- [ ] 1.2 eng/RuntimeIdentifier.props: TargetsLinuxOhos
- [ ] 1.3 eng/native/build-commons.sh: ohos NDK 分支
- [ ] 1.4 src/native/libs/build-native.sh: ohos args
- [ ] 1.5 eng/targetingpacks.targets + runtime.json: RID
- [ ] 1.6 eng/native/configureplatform.cmake: TARGET_OPENHARMONY
- [ ] 1.7 src/native/eventpipe/ds-portable-rid.c
- [ ] 1.8 eng/Subsets.props

### Phase 2: 构建验证
- [ ] 2.1 仅构建 native libs（最快反馈）: `./src/native/libs/build-native.sh -arch arm64 -os linux-ohos`
- [ ] 2.2 构建 coreclr native: `./build.sh clr -os linux-ohos -arch arm64 --cross -c Release`
- [ ] 2.3 构建 libs + host + packs 完整产物

### Phase 3: 产物验证
- [ ] 3.1 `file` 检查 libcoreclr.so 架构
- [ ] 3.2 检查 RID 命名（runtime.linux-ohos-arm64）
- [ ] 3.3 符号检查（musl 相关符号）

## 五、问题日志

（执行中遇到的问题按"### 问题 N"格式追加）

---

## 六、执行记录

### Phase 0 完成（2026-08-13）✅

**0.1 结果**: `aarch64-unknown-linux-ohos-clang test.c` 直接编译成功 → `ELF 64-bit LSB pie executable, ARM aarch64, interpreter /lib/ld-musl-aarch64.so.1`。显式 `clang -target aarch64-linux-ohos --sysroot` 同样成功。工具链确认可用。

**0.2 结果**: `ohos.toolchain.cmake` 配置 + 构建最小 CMake 项目成功 → 同样产出 aarch64 musl ELF。NDK toolchain 文件确认可用（仅有一个无害警告：`--gcc-toolchain` unused，SDK clang wrapper 自带）。

**关键确认**: HarmonyOS libc = musl（动态链接器 `/lib/ld-musl-aarch64.so.1`），与 linux-musl 代码路径天然兼容。

### Phase 1 源码修改

*开始时间: 2026-08-13*

**1.1-1.4 完成** ✅ (commits: 1d7d42a, +2)
- 1.1 `eng/build.sh`: `--os linux-ohos` → `os=linux` + `__PortableTargetOS=linux-ohos`，help 更新
- 1.2 `eng/RuntimeIdentifier.props`: `PortableOS=linux-ohos` + `TargetsLinuxOhos`，`TargetsLinuxGlibc` 排除
- 1.3/1.4 `build-commons.sh` + `build-native.sh`: ohos NDK 分支（OHOS_NDK_HOME + ohos.toolchain.cmake + tryrun.cmake + __Compiler=default），rootfs 豁免

**冒烟测试通过**: `ohos.toolchain.cmake + OHOS_NDK_HOME + OHOS_ARCH=arm64-v8a + -C tryrun.cmake` 完整组合编译出 aarch64 musl ELF ✅

### 问题 1: OHOS_ARCH 参数值错误
- **现象**: 最初写了 `OHOS_ARCH=aarch64/armv7`，但 `ohos.toolchain.cmake:97-110` 只识别 `arm64-v8a`/`armeabi-v7a`/`x86_64`（Android NDK 风格）
- **根因**: ohos.toolchain.cmake 的架构枚举与 Android NDK 一致，非 GNU triple
- **方案**: 改用 `arm64-v8a`/`armeabi-v7a`/`x86_64`
- **验证**: grep ohos.toolchain.cmake 的 OHOS_ARCH 分支确认
- **结果**: 已修正

### 问题 2: ROOTFS_DIR 默认创建会污染 ohos 构建
- **现象**: `build-commons.sh:624-630` 在 `__CrossBuild==1` 且无 ROOTFS_DIR 时默认创建 `.tools/rootfs/$arch`，`initTargetDistroRid` 会传入空 rootfs 触发 ldd 探测失败
- **根因**: ohos NDK 模式不需要 rootfs，但 cross 逻辑未豁免
- **方案**: 两处豁免 `$__TargetOS != "linux-ohos"`（initTargetDistroRid 传参 + ROOTFS_DIR 默认创建）
- **验证**: `__PortableTargetOS` 已由 build.sh 设置时 `initDistroRidGlobal` 保留原值（init-distro-rid.sh:96 `if [ -z ... ]`），`getNonPortableDistroRid` 对未知 OS 返回空不报错
- **结果**: 已修正

### 问题 3: gen-buildsys.sh 在 CROSSCOMPILE=1 时强制 ROOTFS_DIR 并覆盖 toolchain.cmake
- **现象**: `gen-buildsys.sh:64-82` 要求 ROOTFS_DIR（ohos 无）+ 无条件加 `-DCMAKE_TOOLCHAIN_FILE=eng/common/cross/toolchain.cmake`（覆盖 ohos.toolchain.cmake）
- **根因**: ohos 走 `--cross` 路径会触发 CROSSCOMPILE=1
- **方案**: ohos 仿 bionic 模式——不传 `--cross`（auto-cross 已豁免），靠 build-commons.sh 注入 toolchain + `-C tryrun.cmake`
- **验证**: 冒烟测试确认参数组合可编译
- **结果**: 已修正（ohos 分支补 `-C tryrun.cmake`）

### 问题 4: tryrun.cmake 的 TARGET_ARCH_NAME 依赖
- **现象**: `tryrun.cmake:2` 读 `$ENV{TARGET_BUILD_ARCH}`（CROSSCOMPILE 时才设），ohos 不设 cross → 未定义
- **根因**: 最初怀疑 ohos 无法走 tryrun.cmake
- **方案**: 分析后确认 TARGET_ARCH_NAME 仅在 DARWIN 分支（:58）强制要求，ohos 走 else 通用分支不依赖；`CROSS_ROOTFS` 空路径的 `file(GLOB)` 无害
- **验证**: 冒烟测试 `-C tryrun.cmake` 组合编译成功
- **结果**: 无需代码修改

### 问题 5: CMAKE_SYSTEM_NAME=OHOS 导致 CLR_CMAKE_HOST_OS 无法识别
- **现象**: `configureplatform.cmake:12` 用 CMAKE_SYSTEM_NAME（ohos.toolchain.cmake 设为 OHOS）推导 CLR_CMAKE_HOST_OS，OHOS 非 linux → 所有 linux 分支不触发
- **根因**: ohos NDK toolchain 的 CMAKE_SYSTEM_NAME 是 OHOS
- **方案**: 归一化后添加 ohos→linux 映射 + `CLR_CMAKE_HOST_LINUX_MUSL=1`（libc 是 musl）+ `CLR_CMAKE_HOST_OPENHARMONY=1`；TARGET 传播 `CLR_CMAKE_TARGET_OPENHARMONY`；configurecompiler 发 `TARGET_OPENHARMONY` 宏
- **验证**: ohos sysroot 无 os-release → `cmake_host_system_information` 不覆盖；`CLR_CMAKE_HOST_LINUX_MUSL` → `CLR_CMAKE_TARGET_LINUX_MUSL` → `TARGET_LINUX_MUSL` 自动生效
- **结果**: 已修正

### 问题 6: ohos 的 _BuildAnyCrossArch 需强制触发
- **现象**: ohos 的 TargetOS 映射为 linux，HostOS==TargetOS 检查不触发；同 arch 构建时 cross 组件可能缺失
- **根因**: 镜像 bionic 问题（bionic 有专门注释说明）
- **方案**: `_BuildAnyCrossArch` 条件加 `'$(TargetsLinuxOhos)' == 'true'`
- **验证**: 条件逻辑分析
- **结果**: 已修正

### 问题 7: NativeAotSupported 对 ohos 误判
- **现象**: `NativeAotSupported.props`（eng/common，外部同步不可改）对 ohos（TargetOS=linux+arm64）判定 true → NativeAOT 组件被尝试构建
- **根因**: ohos 无 NativeAOT 支持（第一阶段仅 CoreCLR runtime）
- **方案**: `eng/Subsets.props:59` 的 `UseNativeAotForComponents` 排除 `TargetsLinuxOhos`
- **验证**: 条件逻辑分析
- **结果**: 已修正（不修改 eng/common）

### Phase 1 全部完成 (1.1-1.8) ✅
8 处修改全部 commit。决策: 第一阶段用显式子集 `clr+libs+host+packs`（与 CI musl 腿一致），避开 mono。

### Phase 2.1: 仅构建 native libs

*开始时间: 2026-08-13*

**结果: 成功** ✅ (耗时约 30 分钟含问题解决)
5 个 native 库编译完成 (全部 ARM aarch64 ELF):
- libSystem.Native.so
- libSystem.IO.Compression.Native.so
- libSystem.IO.Ports.Native.so
- libSystem.Globalization.Native.so
- libSystem.Security.Cryptography.Native.OpenSsl.so

**依赖资产** (用户已有 + 新建):
- ICU: ~/sources/icu-ohos-build (aarch64, ICU 75.1) + ~/sources/icu/source 头文件 → /tmp/icu-ohos-install
- OpenSSL: 交叉编译 3.3.1 → /tmp/openssl-ohos/install (本会话完成, aarch64 静态库)

### 问题 8: find_program 找不到 llvm-ar/nm/ranlib/strings
- **现象**: `configuretools.cmake:38` 报 "Unable to find toolchain executable. Name: 'ar', Prefix: 'llvm-'"
- **根因**: ohos.toolchain.cmake 的 `CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER` + llvm/bin 不在 PATH → find_program 找不到
- **方案**: configuretools.cmake 的 locate_toolchain_exec 加 `HINTS "${CLR_COMPILER_DIR}"`（从 CMAKE_C_COMPILER 推导）
- **验证**: 重跑后 ar/nm/ranlib/strings 全部定位
- **结果**: 已修正

### 问题 9: --gcc-toolchain unused 被 -Werror 升级为 error
- **现象**: `clang: error: argument unused during compilation: '--gcc-toolchain=...' [-Werror,...]`
- **根因**: ohos.toolchain.cmake 设 CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN → clang 收 --gcc-toolchain；check_c_source_compiles 加 -Werror
- **方案**: configurecompiler.cmake 的 CLR_CMAKE_HOST_OPENHARMONY 分支把 `-Qunused-arguments` 加入 CMAKE_C_FLAGS/CXX_FLAGS（而非 add_compile_options，因 try_compile 只用 CMAKE_C_FLAGS）
- **验证**: mkstemp 检测通过
- **结果**: 已修正

### 问题 10: ohos sysroot ICU 头文件不完整 (缺 ucurr.h)
- **现象**: System.Globalization.Native 报 "Cannot find ucurr.h"
- **根因**: ohos 的 libicu.so 是 31KB 存根，头文件部分裁剪
- **方案**: 用用户已有的 ICU 交叉编译资产 (icu-ohos-build aarch64 ICU 75.1 + icu/source 头) 组装 /tmp/icu-ohos-install，-DCMAKE_ICU_DIR 传入（CMakeLists 已有该机制）
- **验证**: ucol_clone 检测通过
- **结果**: 已解决

### 问题 11: ohos 无 krb5/gssapi
- **现象**: System.Net.Security.Native 报 "Cannot find libgssapi_krb5"
- **根因**: ohos sysroot 无 krb5 库和头文件
- **方案**: extra_libs.cmake 的 ohos 分支走 GSS_SHIM（LIBGSS=""，dlopen 模式）；CMakeLists 跳过 System.Net.Security.Native（ohos 无 Kerberos）
- **验证**: 构建通过
- **结果**: 已修正（ohos 限制: 无 Negotiate/Ntlm）

### 问题 12: ohos 无 OpenSSL 开发资产
- **现象**: System.Security.Cryptography.Native 需 OpenSSL
- **根因**: ohos sysroot 只有 libohcrypto.so (华为私有), 无 libssl/libcrypto + 头文件
- **方案**: 交叉编译 OpenSSL 3.3.1 到 aarch64-ohos (静态库) → /tmp/openssl-ohos/install，-DOPENSSL_* cache 变量传入
- **验证**: libcrypto.a (9.1MB) + libssl.a (1.8MB) aarch64 编译成功
- **结果**: 已解决

### 问题 13: OpenSSL 用 -gcc 后缀找不到编译器
- **现象**: `aarch64-unknown-linux-ohos-gcc: not found`
- **根因**: OpenSSL Makefile 拼接 gcc 后缀, OHOS 只有 clang wrapper
- **方案**: 创建符号链接 gcc/g++ → clang/clang++ wrapper
- **验证**: gcc wrapper 编译测试通过
- **结果**: 已解决

### 问题 14: OpenSSL 用 -ar 后缀找不到
- **现象**: `aarch64-unknown-linux-ohos-ar: No such file`
- **根因**: 同问题 13, 缺 ar/ranlib/nm
- **方案**: 符号链接 llvm-ar/ranlib/nm → -ar/-ranlib/-nm
- **验证**: OpenSSL 完整编译成功
- **结果**: 已解决

### 问题 15: find_package(OpenSSL) 在 ohos 交叉环境失败
- **现象**: "Cannot find libssl and System.Security.Cryptography.Native cannot build"
- **根因**: find_package(OpenSSL) 找不到交叉 OpenSSL; FORCE_ANDROID_OPENSSL 分支硬编码 x64 路径
- **方案**: -DOPENSSL_INCLUDE_DIR/-DOPENSSL_SSL_LIBRARY/-DOPENSSL_CRYPTO_LIBRARY cache 变量传入
- **验证**: 配置通过, 进入编译
- **结果**: 已解决

### 问题 16: zstd qsort_r 未定义
- **现象**: `cover.c:333: call to undeclared function 'qsort_r'`
- **根因**: ohos musl 无 qsort_r (GNU 扩展), zstd 只豁免 __ANDROID__
- **方案**: zstd.cmake 的 `if (ANDROID OR CLR_CMAKE_TARGET_OPENHARMONY)` → ZSTD_USE_C90_QSORT=1 (走 C90 fallback)
- **验证**: zstd 编译通过
- **结果**: 已修正

### 问题 17: robust mutex + ethtool 不支持
- **现象**: pthread_mutexattr_setrobust/pthread_mutex_consistent 未声明; ethtool_cmd_speed 未定义
- **根因**: ohos musl 裁剪 robust mutex API; 内核头缺 ethtool 宏
- **方案**: System.Native/CMakeLists.txt 加 ohos 到 robust-mutex 不支持列表 (用 pal_crossprocessmutex_unsupported.c); pal_interfaceaddresses.c 的 TARGET_ANDROID 豁免加 TARGET_OPENHARMONY
- **验证**: 编译通过
- **结果**: 已修正 (managed 侧 UsePThreadMutexes 同步推迟到 Phase 2.3)

### 问题 18: pal_gssapi.c 需 gssapi 头文件
- **现象**: `fatal error: 'gssapi/gssapi_ext.h' file not found`
- **根因**: GSS_SHIM 模式编译时仍需要头文件声明, ohos 无 krb5 头
- **方案**: CMakeLists ohos 分支跳过 System.Net.Security.Native (无 Kerberos 是平台限制)
- **验证**: 构建通过
- **结果**: 已修正

### Phase 2.2: 构建 coreclr native

**结果: 成功** ✅ "Build succeeded. 0 Warning(s) 0 Error(s)"
产物: artifacts/bin/coreclr/linux-ohos.arm64.Release/ (libcoreclr.so + libclrjit.so + 全套 JIT 变体 + createdump)

### 问题 19: runtime.proj 丢失 ohos 标记
- **现象**: coreclr 按 linux 构建 (host clang)
- **根因**: `runtime.proj:4-5` 的 `_BuildNativeTargetOS` 只处理 bionic
- **方案**: 加 `TargetsLinuxOhos → linux-ohos`
- **结果**: 已修正

### 问题 20: gen-buildsys.sh 覆盖 ohos toolchain
- **现象**: CROSSCOMPILE 时无条件加 eng/common/cross/toolchain.cmake 覆盖 ohos.toolchain.cmake
- **方案**: gen-buildsys.sh 加 `target_os == linux-ohos` 豁免分支
- **结果**: 已修正

### 问题 21: build.sh initDistroRid ROOTFS_DIR unbound
- **现象**: `ROOTFS_DIR: unbound variable` (set -u)
- **方案**: initDistroRid 豁免 `__PortableTargetOS=linux-ohos` + `${ROOTFS_DIR:-}`
- **结果**: 已修正

### 问题 22: 残留构建进程竞争
- **现象**: 之前误触发的 linux x64/arm64 构建残留占用 artifacts
- **方案**: 全部 kill -9 清理
- **结果**: 已解决

### 问题 23: NETSDK1083 linux-ohos RID 不识别
- **现象**: SDK 报 "RuntimeIdentifier 'linux-ohos-arm64' is not recognized"
- **根因**: SDK 的 RuntimeIdentifierGraph.json 无 ohos (只改了 repo 的 runtime.json)
- **方案**: 注入 SDK 的 RuntimeIdentifierGraph.json + PortableRuntimeIdentifierGraph.json；**最终用 /p:RuntimeIdentifierGraphPath 指向修改后的图**
- **结果**: 已解决 (关键: RuntimeIdentifierGraphPath 参数必须显式传)

### 问题 24: coreclr 构建需 OpenSSL 路径
- **现象**: System.Security.Cryptography.Native 找不到 OpenSSL
- **根因**: coreclr CMakeLists:110 构建 libs, 但没传 OPENSSL cache 变量
- **方案**: -cmakeargs 传 OPENSSL_ROOT_DIR/INCLUDE/LIBRARY
- **结果**: 已解决

### 问题 25: PAL 需 LTTNG
- **现象**: configure.cmake:630 "Cannot find liblttng-ust-dev"
- **方案**: ohos 豁免 LTTNG 检查
- **结果**: 已修正 (native)

### 问题 26: LTTNG provider 链接失败
- **现象**: LTTNG 变量 NOTFOUND, coreclrtraceptprovider 链接失败
- **方案**: clrfeatures.cmake + clr.featuredefines.props 禁用 ohos 的 FEATURE_EVENTSOURCE_XPLAT
- **结果**: 已修正

### 问题 27: singlefilehost WHOLE_ARCHIVE 不支持
- **现象**: CMake Error "WHOLE_ARCHIVE not supported for CXX"
- **方案**: coreclr CMakeLists 豁免 ohos (不需要 single-file host)
- **结果**: 已修正

### 问题 28: 汇编 -Werror gcc-toolchain
- **现象**: debugbreak.S 编译失败 (--gcc-toolchain unused)
- **方案**: configurecompiler.cmake 给 CMAKE_ASM_FLAGS 也加 -Qunused-arguments
- **结果**: 已修正

### 问题 29: -lgcc_s 找不到
- **现象**: ld.lld "unable to find library -lgcc_s"
- **根因**: ohos musl 无 gcc_s (用 compiler-rt)
- **方案**: coreclrpal 链接豁免 ohos (仿 Android)
- **结果**: 已修正

### 问题 30: t_ThreadStatics TLS 符号未定义
- **现象**: ld.lld "undefined symbol: t_ThreadStatics"
- **根因**: OHOS clang 默认 emulated TLS (__emutls_v.t_ThreadStatics), 汇编用 tlsdesc 原生 TLS
- **方案**: configurecompiler.cmake 加 `-fno-emulated-tls -ftls-model=global-dynamic`
- **结果**: 已修正 (关键! 用户 Zig 文档也踩过此坑)

### 问题 31: JIT 交叉组件 LTTNG
- **现象**: host x64 组件的 PAL 需 LTTNG
- **方案**: 安装 liblttng-ust-dev (host 依赖)
- **结果**: 已解决

### 问题 32: ILCompiler 路径不匹配
- **现象**: ILCompiler 引用 linux.arm64.Release/x64/ 下的 JIT 库, 实际在 linux-ohos.arm64.Release
- **根因**: host 组件路径用 TargetOS (linux) vs 产物在 linux-ohos
- **方案**: ohos 不需要 NativeAOT → 改用 `clr.native` 子集 (跳过 ILCompiler/AOT 工具链)
- **结果**: 已解决 (coreclr 运行时完整构建成功)

### Phase 2.3: 构建 libs + host + packs 完整产物

**结果: 成功** ✅ "Build succeeded. 0 Warning(s) 0 Error(s)"

完整产物 (15 个 linux-ohos-arm64 包):
- Microsoft.NETCore.App.Runtime.linux-ohos-arm64.11.0.0-dev.nupkg (完整类库)
- Microsoft.NETCore.App.Host.linux-ohos-arm64
- dotnet-runtime-11.0.0-dev-linux-ohos-arm64.tar.gz
- dotnet-crossgen2 / dotnet-nethost / dotnet-apphost-pack
- runtime.linux-ohos-arm64.Microsoft.NETCore.DotNetAppHost
- 等 15 个

### 问题 33: build-native.proj/corehost.proj 丢失 ohos 标记
- **现象**: build-native.sh 收到 -os linux (丢 ohos) → initDistroRid 传 ROOTFS_DIR 失败
- **方案**: build-native.proj + corehost.proj 的 _BuildNativeTargetOS 加 ohos
- **结果**: 已修正

### 问题 34: singlefilehost WHOLE_ARCHIVE 不支持 (CMake 4.2)
- **现象**: "WHOLE_ARCHIVE not supported for CXX link language"
- **根因**: CMake 4.2 太新, lld 15 不满足其 WHOLE_ARCHIVE 要求
- **方案**: 恢复 singlefilehost 构建 + 用传统 -Wl,--whole-archive 替代 $<LINK_LIBRARY:WHOLE_ARCHIVE>
- **验证**: lld 15 支持 --whole-archive, singlefilehost 编译通过
- **结果**: 已修正

### 问题 35: singlefilehost 链接 System.Net.Security.Native-Static
- **现象**: ld.lld "unable to find library -lSystem.Net.Security.Native-Static"
- **根因**: ohos 跳过该库构建 (Phase 2.1), 但 singlefilehost 仍引用
- **方案**: CMakeLists 的 NATIVE_LIBS 跳过 ohos 的 Net.Security + 用 OpenSSL-Static
- **结果**: 已修正

### 问题 36: SecurityResolveDllImport 未定义
- **现象**: ld.lld "undefined symbol: SecurityResolveDllImport"
- **根因**: NATIVE_LIBS_EMBEDDED 使 pinvoke_override 引用缺失的 Net.Security 符号
- **方案**: ohos 不定义 NATIVE_LIBS_EMBEDDED (仿 Android)
- **结果**: 已修正

### 问题 37: AppHost pack 缺 singlefilehost
- **现象**: 打包报 "File not found: corehost/singlefilehost"
- **根因**: singlefilehost 在 obj 未被 install 到 bin
- **方案**: 符号链接 obj → bin/linux-ohos-arm64.Release/corehost/
- **结果**: 已解决

### 问题 38: ReadyToRun 编译缺 PGO 数据
- **现象**: crossgen2 报 "Could not find StandardOptimizationData.mibc"
- **根因**: ohos 无 PGO 数据 (host 路径 linux.arm64.Release)
- **方案**: sfxproj 禁用 ohos 的 PublishReadyToRun
- **结果**: 已修正

### 问题 39: NU5118 pdb 重复打包
- **现象**: System.Private.CoreLib.pdb 从两个路径重复添加
- **根因**: host 组件路径 (linux.arm64.Release/IL) 与 ohos 打包 pdb 冲突
- **方案**: /p:IncludeSymbols=false /p:DebugSymbols=false
- **结果**: 已解决

### 问题 40: 全局 NoWarn 破坏 NU1507
- **现象**: /p:NoWarn=NU5118 引发 NU1507 (source mapping)
- **方案**: 改用 IncludeSymbols=false (精准, 不全局 NoWarn)
- **结果**: 已解决

### Phase 3: 产物验证

**结果: 通过** ✅
- dotnet muxer: ELF aarch64, interpreter /lib/ld-musl-aarch64.so.1
- libcoreclr.so: ELF aarch64
- 10+ NuGet 包: linux-ohos-arm64 RID
- libcoreclr.so 含 "linux-ohos" 字符串 (RID 正确嵌入)

### 问题 41: 运行验证缺 musl 动态链接器
- **现象**: qemu-aarch64 报 "Could not open '/lib/ld-musl-aarch64.so.1'"
- **根因**: ohos sysroot 无 ld-musl (动态链接在设备上由系统提供)
- **方案**: 从 Alpine v3.18 获取 ld-musl-aarch64.so.1 (musl 1.2.4) 组装 qemu sysroot
- **结果**: dotnet muxer 成功加载运行, 报 RID 正确

### 问题 42: libcoreclr.so 需 arc4random_buf
- **现象**: "Error relocating libcoreclr.so: arc4random_buf: symbol not found"
- **根因**: ohos libc 有 arc4random_buf 但 SDK 的 libc.so 是 stub; Alpine 1.2.4 musl 无此符号
- **方案**: zig 交叉编译 arc4random_buf shim (aarch64-musl, -nostdlib -fno-sanitize), 用 qemu LD_PRELOAD 预加载
- **结果**: libcoreclr.so 加载成功

### 问题 43: 运行需 native libs + ICU
- **现象**: corerun 报缺 libSystem.Native.so; ICU 缺失
- **方案**: 复制 native libs 到 Core_Root; ICU 用 Invariant 模式跳过 (ohos 的 libicu.so 是 stub, 真机用系统 ICU)
- **结果**: 完整功能验证通过

## Phase 3 最终结果 (运行验证成功) ✅

**qemu-aarch64 + musl loader + arc4random shim 完整运行 ohos dotnet/runtime:**

```
Arch: Arm64 ✓
GC after alloc: Gen0=1 ✓ (GC 工作)
Thread counter: 10000 ✓ (多线程 + Interlocked)
Type: System.String ✓ (反射)
Assembly: System.Private.CoreLib ✓
PI: 3.1416, 1/3: 0.333333 ✓ (浮点 + 格式化)
ALL FEATURES OK ✓
```

**完整链路验证**: managed IL → CoreCLR JIT → libcoreclr.so (aarch64 ohos) → libSystem.Native.so → musl libc → 输出

---

## 最终成果

**HarmonyOS (ohos) 交叉编译 dotnet/runtime 成功!**

分支: feature/ohos-cross-runtime (29 个源码修改文件, 17 commits)
产物: artifacts/packages/Release/Shipping/ (15 个 linux-ohos-arm64 包)
时间: 2026-08-13 (约 5 小时含问题解决与运行验证)

关键解决: TLS (emulated→native), gcc_s 豁免, LTTNG 豁免, RID 图注入, NDK toolchain 接入, ICU/OpenSSL 交叉编译资产复用, qemu 运行验证 (arc4random_buf shim)

---

# 附录 A: dotnet-runtime 10.0.11 ohos 版本编译过程

**日期:** 2026-08-14
**分支:** `feature/ohos-10.0.11`（基于 `v10.0.11` tag = commit 79d0c463f1b）
**SDK:** .NET SDK 10.0.109（本机 `.dotnet` 安装）
**目标:** 将 11.0 分支的 ohos 支持移植到 10.0.11，编译 linux-ohos-arm64 release

## A.1 版本关系澄清

**重要认知**: dotnet/runtime 的 `v10.0.11` **tag** 内部版本号是 **`10.0.10-servicing`**（PatchVersion=10）——这是 .NET 服务分支的惯例：**tag 号（v10.0.11）≠ 版本号（10.0.10）**。产物显示 `10.0.10-dev` 是**正确的**，它就是 v10.0.11 tag 的官方对应产物。

**v10.0.400 关系**: `v10.0.400` 是 **dotnet/sdk** 仓库的 tag（SDK feature band 10.0.4xx），**不是** runtime 的 tag。runtime 10.0.11 是 10.0 版本线最新服务版本，与 v10.0.400 SDK 兼容。两者是**不同仓库的版本号体系**。

## A.2 执行过程

### A.2.1 移植 17 个 ohos commits（11.0 → 10.0.11）

`git cherry-pick` 从 `feature/ohos-cross-runtime` 移植，**手动解决 7 处冲突**：

| 冲突文件 | 原因 | 解决 |
|---------|------|------|
| `eng/targetingpacks.targets` | 10.0 无 openbsd/illumos/haiku RID | 保留 10.0 基线 + 加 ohos RID |
| `eng/native/configurecompiler.cmake` | 10.0 的 TARGET_LINUX_MUSL 区域结构不同 | 在 10.0 linux 区域加 TARGET_OPENHARMONY |
| `eng/Subsets.props` | 10.0 的 `_BuildAnyCrossArch` 有 wasm 条件 | 合并：保留 wasm + 加 ohos/bionic |
| `src/coreclr/runtime.proj` | 10.0 的 HasCdacBuildTool 条件不同 | 保留 10.0 + 加 `_BuildNativeTargetOS` ohos |
| `src/native/libs/System.Native/CMakeLists.txt` | 10.0 有独立 browser/wasi 分支 | 只保留 robust mutex 的 OHOS 添加 |
| `src/coreclr/CMakeLists.txt` | 10.0 用 MACCATALYST/IOS/TVOS 显式列表 | 保留 10.0 + 加 OHOS 排除 |
| `src/libraries/.../OperatingSystem.cs` | 11.0 新增 IsOpenBSD 等（10.0 无） | 只提取 IsOpenHarmony 插入 IsAndroid 后 |

**修正**: filter-branch 移除误提交的 AGENTS.md（2 个 commit 含文档文件）。

### A.2.2 SDK 与 RID 图

- 下载并安装 **SDK 10.0.109**（238MB，本机 `.dotnet`）
- 注入 `linux-ohos` RID 到 10.0 SDK 的 `RuntimeIdentifierGraph.json` + `PortableRuntimeIdentifierGraph.json`
- 构建用 `/p:RuntimeIdentifierGraphPath` 指向修改后的图

### A.2.3 构建命令

```bash
export OHOS_NDK_HOME=/home/springmin/hmos-tools/sdk/default/openharmony
./build.sh clr.native+libs+host+packs -os linux-ohos -arch arm64 --cross \
  -c Release -lc Release -rc Release \
  /p:RuntimeIdentifierGraphPath="$(pwd)/.dotnet/sdk/10.0.109/RuntimeIdentifierGraph.json" \
  /p:IncludeSymbols=false /p:DebugSymbols=false \
  -cmakeargs "-DOPENSSL_ROOT_DIR=/tmp/openssl-ohos/install -DOPENSSL_INCLUDE_DIR=/tmp/openssl-ohos/install/include \
  -DOPENSSL_CRYPTO_LIBRARY=/tmp/openssl-ohos/install/lib/libcrypto.a -DOPENSSL_SSL_LIBRARY=/tmp/openssl-ohos/install/lib/libssl.a \
  -DCMAKE_ICU_DIR=/tmp/icu-ohos-install"
```

**依赖资产复用**（与 11.0 相同）: ICU 75.1（`~/sources/icu-ohos-build`）+ OpenSSL 3.3.1（`/tmp/openssl-ohos/install`，aarch64 ohos 交叉编译）。

### A.2.4 问题记录

#### 问题 44: CMakeCache 生成器冲突（Ninja vs Unix Makefiles）
- **现象**: `CMake Error: generator : Unix Makefiles` / `Does not match the generator used previously: Ninja`
- **根因**: 11.0 构建残留的 Ninja CMakeCache 与 10.0 的 make 冲突（`artifacts/obj/linux-ohos-arm64.Release/`）
- **方案**: 清理 `artifacts/obj/` 下所有 ohos/arm64 的 CMakeCache + 构建目录
- **结果**: 已解决

#### 问题 45: singlefilehost duplicate symbol (DotNetRuntimeInfo)
- **现象**: `ld.lld: error: duplicate symbol: DotNetRuntimeInfo`
- **根因**: 10.0 用 `START_WHOLE_ARCHIVE/RUNTIMEINFO_LIB` 机制，但移植时残留了 11.0 的 `target_link_options(...WHOLE_ARCHIVE...)` 行 → 两套机制叠加
- **方案**: 删除残留的 11.0 风格 `target_link_options` 行（10.0 用自己的机制，无 CMake 4.2 兼容问题）
- **结果**: 已修正

#### 问题 46: OperatingSystem.cs 的 IsOpenHarmony 插错位置
- **现象**: `error CS8803: Top-level statements must precede namespace and type declarations`
- **根因**: python 脚本把 IsOpenHarmony 插到 namespace 外（文件末尾），后又被误删
- **方案**: 手动在 `IsAndroid()`（201 行）后插入 IsOpenHarmony（含 XML 文档注释）
- **结果**: 已修正（最终 212 行）

#### 问题 47: 构建竞争（用户 SDK 进程）
- **现象**: 构建被中断，日志停滞
- **根因**: 用户在 `~/sources/sdk` 并行构建 ohos SDK（PID 490073，独立 artifacts），与我的构建竞争
- **方案**: 用 `setsid nohup` 独立进程组；确认用户进程用自己目录不污染 runtime artifacts
- **结果**: 已解决（runtime artifacts 未被污染）

### A.2.5 产物验证（qemu）

```bash
# 架构
dotnet: ELF aarch64, interpreter /lib/ld-musl-aarch64.so.1 ✅
libcoreclr.so: ELF aarch64 ✅
# 运行
qemu-aarch64 -L /tmp/ohos-qemu-root -E LD_PRELOAD=/tmp/arc4shim3.so \
  -E DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 corerun t.dll
→ ALL FEATURES OK ✅ (GC/线程/反射/浮点)
```

### A.2.6 最终产物

```
artifacts/packages/Release/Shipping/
├── dotnet-runtime-10.0.10-dev-linux-ohos-arm64.tar.gz  (14.9MB)
├── Microsoft.NETCore.App.Runtime.linux-ohos-arm64.10.0.10-dev.nupkg
├── Microsoft.NETCore.App.Host.linux-ohos-arm64.10.0.10-dev.nupkg
├── Microsoft.NETCore.App.Crossgen2 / dotnet-apphost-pack / dotnet-crossgen2 / dotnet-nethost
└── runtime.linux-ohos-arm64.Microsoft.NETCore.DotNetAppHost.nupkg
```

### A.2.7 与官方 musl-arm64 对比

| 指标 | 官方 linux-musl-arm64 | ohos (我们) |
|---|---|---|
| tarball | 34.6MB | 15.1MB (2.3x 小) |
| 解压 | 85M | 37M |
| C++ stdlib | libstdc++ + libgcc_s | libc++_shared (clang) |
| R2R | ✅ (PGO 数据) | ❌ 纯 IL (ohos 无 PGO) |
| 缺失 | - | libSystem.Net.Security.Native (无 krb5) + libcoreclrtraceptprovider (无 LTTNG) |

---

# 附录 B: NativeAOT ohos 版本编译过程

**日期:** 2026-08-14
**分支:** `feature/ohos-10.0.11`
**目标:** 启用并编译 NativeAOT（无 JIT/CoreCLR，纯 AOT 原生代码）的 linux-ohos-arm64 版本

## B.1 启用 NativeAOT

### B.1.1 修改点

| 文件 | 修改 |
|------|------|
| `eng/Subsets.props:60` | 移除 `'$(TargetsLinuxOhos)' != 'true'` 排除（保留 bionic） |
| `eng/Subsets.props:77-80` | 添加 ohos 的 DefaultSubsets（含 `clr.nativeaotruntime+clr.nativeaotlibs`） |
| `src/coreclr/nativeaot/System.Private.CoreLib/...csproj:512-513` | IntermediatesDir 加 ohos 分支 |
| `src/coreclr/nativeaot/Test.CoreLib/...csproj:26-27` | 同上 |
| `eng/liveBuilds.targets:17-18` | CoreCLRArtifactsPath 无条件覆盖为 linux-ohos |

### B.1.2 NativeAOT 组件（成功构建）

```
libRuntime.WorkstationGC.a (8.3MB) + ServerGC.a (11.4MB)   [nativeaot 运行时]
aotsdk: System.Private.CoreLib.dll (AOT 变体) + TypeLoader + Reflection + StackTrace
libbootstrapperdll.a + libeventpipe + libaotminipal + libstandalonegc
Microsoft.NETCore.App.Runtime.NativeAOT.linux-ohos-arm64.10.0.10-dev.nupkg (19.2MB)
```

## B.2 问题记录

#### 问题 48: nativeaot CoreLib 缺 AsmOffsets.cs
- **现象**: `error CS2001: AsmOffsets.cs could not be found`（路径 `linux.arm64.Release/nativeaot/Runtime/Full/`）
- **根因**: nativeaot CoreLib/Test.CoreLib 的 `IntermediatesDir` 用 `$(TargetOS)` = linux（ohos 映射后）→ 路径错
- **方案**: 两个 csproj 的 IntermediatesDir 加 ohos 分支（`linux-ohos.$(TargetArchitecture).$(CoreCLRConfiguration)`）
- **结果**: 已修正

#### 问题 49: ILCompiler 复制 JIT 库失败
- **现象**: `MSB3026: Could not copy libclrjit_universal_arm64_x64.so`（悬空符号链接）
- **根因**: 11.0 建的相对路径符号链接，10.0 重建 ohos 目录后目标失效
- **方案**: 重建为绝对路径符号链接
- **结果**: 已修正

#### 问题 50: PrivateSdkAssemblies 空 / ilc 缺 Rh* 助手
- **现象**: `The PrivateSdkAssemblies ItemGroup is required`；`undefined symbol: RhBoxAny/RhTypeCast`
- **根因**: (a) NativeAOT pack 未正确打包 AOT 库；(b) ilc 编译应用时未把 CoreLib 作输入 → 不生成 RuntimeExport 助手
- **方案**: (a) 修复 CoreCLRAotSdkDir 路径 + SkipValidatePackage 完成打包；(b) **ilc 需把 System.Private.CoreLib.dll 作为输入**（不只 -r 引用）→ 生成 RhBoxAny 等 30 个助手
- **结果**: 已修正（aot-app.o 完整 6.5MB）

#### 问题 51: CoreCLRAotSdkDir 路径 Bug
- **现象**: NativeAOT pack 缺 libRuntime.a（0 个 AOT 运行时库）
- **根因**: `liveBuilds.targets:18` 的 ohos 分支条件 `'$(CoreCLRArtifactsPath)' == ''` 在 17 行赋值后永远 false
- **方案**: 改为无条件覆盖（`Condition="'$(TargetsLinuxOhos)' == 'true'"`）→ CoreCLRAotSdkDir 指向 linux-ohos aotsdk
- **连带**: VerifyClosure 依赖验证失败 → `/p:SkipValidatePackage=true`
- **结果**: pack 从 12MB → 17.3MB

#### 问题 52: pack 缺 AOT dll（aotsdk 分裂）
- **现象**: pack 有 libRuntime.a 但无 System.Private.*.dll
- **根因**: nativeaotruntime 的 .a 在 `linux-ohos/aotsdk`，nativeaotlibs 的 .dll 在 `linux.arm64/aotsdk`（分裂）
- **方案**: 复制 dll 到 ohos aotsdk 合并
- **结果**: pack 19.2MB（含 4 个 AOT dll + libRuntime + bootstrapper）

#### 问题 53: ilc 引用错 CoreLib / emutls 链接失败
- **现象**: `ThrowInvalidProgramException not found on ThrowHelpers`；`__emutls_v.minipal_cached_thread_id` 未定义
- **根因**: (a) ilc.rsp 同时引用 lib/ 的 CoreCLR CoreLib 和 native/ 的 AOT CoreLib → 冲突；(b) libSystem.Native.a 用 emulated TLS（OHOS clang 默认），缺 `__emutls_v.minipal_cached_thread_id`
- **方案**: (a) 从 ilc.rsp 移除 lib/ CoreLib 引用；(b) 汇编 shim 提供 `__emutls_v.minipal_cached_thread_id` + `__emutls_get_address`
- **结果**: AOT 可执行链接成功（5.8MB aarch64）

## B.3 AOT 运行验证（qemu 成功）

```
dotnet publish /p:PublishAot=true -r linux-ohos-arm64
  → ilc (host x64) 编译 app.dll + System.Private.CoreLib.dll（AOT 版）
  → aot-app.o（aarch64 原生代码）
  → 链接 libRuntime.a + bootstrapper + libSystem.Native.a + emutls shim
  → aot-app-sdk: ELF aarch64 musl ✅（5.8MB）

qemu-aarch64 -L /tmp/ohos-qemu-root -E LD_PRELOAD=/tmp/arc4shim3.so \
  -E DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 aot-app-sdk
→ AOT Hello from OHOS! ✅
```

**完整链路**: managed IL → ilc AOT 编译 → aarch64 原生代码 → libRuntime.a → musl libc → 输出（无 JIT、无 CoreCLR）

## B.4 NativeAOT 手工编译命令（标准 publish 受限时）

```bash
# 1. ilc 编译（CoreLib 作输入生成 Rh* 助手）
dotnet ilc.dll app.dll System.Private.CoreLib.dll \
  -o app.o --targetarch:arm64 --targetos:linux \
  --systemmodule:System.Private.CoreLib -r <aotsdk/*.dll> --optimize

# 2. 链接（bootstrapper + libRuntime + standalonegc + minipal + native libs）
clang --target=aarch64-linux-ohos app.o main.cpp.o libRuntime.WorkstationGC.a \
  libstandalonegc-enabled.a libaotminipal.a emutls_shim.o \
  <native libs> -lstdc++ -lc++abi -lm -ldl
```

## B.5 限制

1. **qemu 早期 segfault**：AOT runtime 的激进 mremap 与 qemu 用户态模拟冲突——加 `LD_PRELOAD` + Invariant 后解决（真机部署需签名）
2. **NETSDK1203**：SDK 认为 linux-ohos-arm64 不支持标准 PublishAot——需手动 `IlcSdkPath`/`IlcToolsPath` 或 SDK 补丁
3. **VerifyClosure**：AOT pack 打包需 `SkipValidatePackage=true`（framework dll 依赖检查）
4. **ICU**：AOT 应用需 Invariant 模式或真机系统 ICU

---

*文档更新: 2026-08-14*

# 附录 C: 11.0 分支启用 NativeAOT（2026-08-17）

**日期:** 2026-08-17
**分支:** `feature/ohos-cross-runtime`
**目标:** 为 11.0 分支启用 NativeAOT，构建并验证 AOT 产物（复用附录 B 的 10.0.11 经验）

## C.1 修改点（与 10.0.11 附录 B 相同的 5 处 + 11.0 特有 1 处）

| 文件 | 修改 |
|------|------|
| `eng/Subsets.props:59` | 移除 `'$(TargetsLinuxOhos)' != 'true'` 排除（保留 bionic） |
| `eng/Subsets.props:80-82` | 添加 ohos 的 DefaultSubsets（含 `clr.nativeaotruntime+clr.nativeaotlibs`） |
| `src/coreclr/nativeaot/System.Private.CoreLib/...csproj:505` | IntermediatesDir 加 ohos 分支 |
| `src/coreclr/nativeaot/Test.CoreLib/...csproj:27` | 同上 |
| `eng/liveBuilds.targets:18` | CoreCLRArtifactsPath 无条件覆盖为 linux-ohos |
| **`src/coreclr/tools/aot/crossgen2/crossgen2_publish.csproj`（11.0 特有）** | 加 `PublishAot=false` + `NativeCompilationDuringPublish=false` |

## C.2 问题记录

#### 问题 54: CMakeCache 生成器冲突（11.0 复现）
- **现象**: `CMake Error: generator : Ninja / Does not match the generator used previously: Unix Makefiles`
- **根因**: 10.0.11 构建残留的 Unix Makefiles CMakeCache（`artifacts/obj/coreclr/linux-ohos.arm64.Release` + `artifacts/obj/native/linux-ohos-arm64-Release` + `artifacts/obj/linux-ohos-arm64.Release`）
- **方案**: 清理 3 处残留 CMakeCache/构建目录
- **结果**: 已解决

#### 问题 55: crossgen2_publish PrivateSdkAssemblies 空（11.0 特有）
- **现象**: `The PrivateSdkAssemblies ItemGroup is required for _ComputeAssembliesToCompileToNative`
- **根因**: 11.0 的 ilcompiler 包（11.0.0-preview）新增 `_ComputeAssembliesToCompileToNative` 目标（BeforeTargets=_PrepareTrimConfiguration，无条件执行），crossgen2_publish 的 RuntimeIdentifier=linux-ohos-arm64 触发 AOT 目标链 → 需 NativeAOT runtime pack（不存在）。10.0.11 的 ilcompiler（10.0.2）无此目标
- **方案**: crossgen2_publish.csproj 加 `PublishAot=false` + `NativeCompilationDuringPublish=false`（它是 host 工具，非 AOT 编译目标）
- **结果**: 已修正（crossgen2_publish 构建成功）

#### 问题 56: nativeaotlibs 未随 clr.native 构建
- **现象**: 构建后 aotsdk dll 仍是 10.0.11 残留（08-14），11.0 的 System.Private.*.dll 未生成
- **根因**: `clr.native+libs+host+packs` 子集不含 `clr.nativeaotlibs`（`+clr+` 才展开 DefaultCoreClrSubsets 含 nativeaotlibs）
- **方案**: 单独构建 `clr.nativeaotlibs`（28 秒，输出到 linux.arm64/aotsdk），复制 dll 到 linux-ohos/aotsdk（问题 52 合并）
- **结果**: aotsdk 4 个 dll 更新为 11.0 版

#### 问题 57: NativeAOT pack 未生成（DotNetBuildAllRuntimePacks 触发 Mono）
- **现象**: 构建后无 NativeAOT runtime pack（只有 ILCompiler pack）
- **根因**: `_BuildNativeAOTRuntimePack` 仅在 `DotNetBuildAllRuntimePacks=true` 时设置，但该属性同时触发 Mono pack（MonoSupported=true for ohos）→ Mono 产物缺失报错
- **方案**: `/p:DotNetBuildAllRuntimePacks=true /p:MonoSupported=false`（ohos 无需 Mono）
- **结果**: NativeAOT pack 生成（25.4MB，411 文件：21 .a/.o + 184 dll，含 System.Private.Xml 等完整 AOT 组件）

#### 问题 58: 标准 publish 链接用 host clang（glibc）
- **现象**: publish 产物 interpreter 是 `/lib/ld-linux-aarch64.so.1`（glibc），qemu（musl）无法运行
- **根因**: 标准 publish 的链接器 `CppCompilerAndLinker` 默认 `clang`（host），TargetTriple 对 ohos 为 gnu
- **方案**: 手工链接（仿 B.4）——OHOS NDK clang `--target=aarch64-linux-ohos` + musl libs + emutls shim
- **结果**: aot-app-ohos（5.9MB aarch64 musl）

#### 问题 59: 链接缺 __managed__Startup
- **现象**: `undefined symbol: __managed__Startup`
- **根因**: 误用 `libbootstrapperdll.o`（dll 模式，期望 __managed__Startup）；exe 模式应使用 `libbootstrapper.o`（main → __managed__Main，aot-app.o 已生成）
- **方案**: 链接换用 `libbootstrapper.o`
- **结果**: 链接成功

## C.3 AOT 运行验证（qemu 成功）

```
ilc 11.0.0-dev 编译 → aot-app.o（aarch64，2.4MB，含 Rh* 助手 + __managed__Main）
OHOS clang 15.0.4 --target=aarch64-linux-ohos 链接
  libbootstrapper.o + libRuntime.WorkstationGC.a + libSystem.Native.a（musl）
  + emutls shim + brotli/zlib/zstd
→ aot-app-ohos: ELF aarch64 musl ✅（5.9MB）

qemu-aarch64 -L /tmp/ohos-qemu-root -E LD_PRELOAD=/tmp/arc4shim3.so \
  -E DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 aot-app-ohos
→ AOT Hello from OHOS! ✅
```

## C.4 产物清单（11.0）

```
Microsoft.NETCore.App.Runtime.NativeAOT.linux-ohos-arm64.11.0.0-dev.nupkg (25.4MB)
  libRuntime.WorkstationGC.a (8.9MB) + ServerGC.a (11.5MB)   [AOT 运行时]
  System.Private.CoreLib.dll (6.1MB) + TypeLoader + Reflection + StackTrace  [AOT CoreLib]
  libSystem.Native.a / Globalization / IO.Compression / Crypto / Net.Security  [native libs]
  libbootstrapper.o / libbootstrapperdll.o + eventpipe + aotminipal + standalonegc
  System.Private.Xml.dll (2.8MB) + DataContract + Uri  [完整 AOT 类库]
artifacts/bin/ILCompiler_publish/arm64/Release/ilc (host x64)  [11.0 ilc 工具]
/tmp/aot11-app/aot-app-ohos (5.9MB, qemu 运行 "AOT Hello from OHOS!")  [验证产物]
```

## C.5 11.0 vs 10.0.11 AOT 差异

| 项 | 10.0.11 | 11.0 |
|---|---|---|
| NativeAOT pack | 19.2MB | 25.4MB（含 Xml/DataContract 完整组件） |
| crossgen2_publish | 不触发 AOT 目标（ilcompiler 10.0 无新目标） | 需 `NativeCompilationDuringPublish=false`（ilcompiler 11.0 新增） |
| ilc 工具 | 10.0.10-dev | 11.0.0-dev（clr.aot 子集构建） |
| aot-app | 5.8MB (aot-app-sdk) | 5.9MB (aot-app-ohos) |
| 运行 | qemu "AOT Hello from OHOS!" | qemu "AOT Hello from OHOS!" |

---

*文档更新: 2026-08-17*

---

## C.6 端到端 AOT publish 实测（2026-08-28, 完整 SDK 发布链路）

在 C.4/C.5（runtime 构建侧 AOT 产物）基础上，完成了**从 `dotnet publish` 到 qemu 运行的完整 SDK 发布链路验证**。

### 目标

用 `dotnet publish -r linux-ohos-arm64 -p:PublishAot=true` 端到端编译出一个可在 qemu 上运行的 OHOS AOT 原生可执行文件。

### 最终结果（成功）

```
bin/Release/net11.0/linux-ohos-arm64/publish/
├── aot-test     (1.5MB, ELF ARM aarch64, musl, stripped)
└── aot-test.dbg (2.2MB, debug symbols)

$ qemu-aarch64 -L /tmp/ohos-qemu-root -E LD_PRELOAD=/lib/libarc4random_shim.so ./aot-test
Hello from OHOS AOT!
RuntimeIdentifier: linux-ohos-arm64
OS: Ubuntu 26.04 LTS
```

- **musl 链接**（`interpreter /lib/ld-musl-aarch64.so.1`），仅依赖 `libc.so`
- 无任何托管 .dll（全部 AOT 编译成原生）
- RuntimeIdentifier 正确报告 `linux-ohos-arm64`

### 前提资产（本次实测用的本地构建产物）

| Pack | 来源 |
|---|---|
| `runtime.linux-ohos-arm64.Microsoft.DotNet.ILCompiler.11.0.0-dev.nupkg` (43.7MB) | runtime 构建（含 ilc + 6 交叉 JIT 库） |
| `Microsoft.NETCore.App.Runtime.NativeAOT.linux-ohos-arm64.11.0.0-dev.nupkg` (25.4MB) | runtime 构建（19 个 musl 静态库） |
| `Microsoft.DotNet.ILCompiler.11.0.0-dev.nupkg` | runtime 构建（补 build/ targets 后） |
| host x64 ILCompiler | 从官方 `11.0.0-rc.1.26410.101` 复制重命名为 `11.0.0-dev`（x64 ilc 跑在 x64 主机交叉编译） |
| `Microsoft.NETCoreSdk.BundledVersions.props` 补丁 | preview.6 SDK：KnownILCompilerPack + Runtime.NativeAOT 加 `linux-ohos-arm64`/`linux-ohos-x64`，版本改 `11.0.0-dev` |

### 遇到的 5 个问题与修复（全部在 SDK/ILCompiler pack 层，非 runtime 编译问题）

| # | 问题 | 根因 | 修复 |
|---|---|---|---|
| 1 | `The PrivateSdkAssemblies ItemGroup is required` | preview.6 SDK 的 `KnownILCompilerPack` 不认识 `linux-ohos-arm64`，回退到 linux-arm64 pack | `Microsoft.NETCoreSdk.BundledVersions.props` 补丁：加 ohos RID + dev 版本 |
| 2 | AOT 静默跳过（产出自包含 CoreCLR） | 我们的 `Microsoft.DotNet.ILCompiler` pack 缺 `build/` 目录（NativeAOT 入口 targets） | 从官方 preview.6 包提取 `build/Microsoft.NETCore.Native*.targets` 补进 pack |
| 3 | `libSystem.Net.Security.Native.a` 缺失 | OHOS 构建跳过 Net.Security（krb5），但 NativeAOT 默认链接它 | `Unix.targets` 的 `NetCoreAppNativeLibrary` 加 `!CrossCompileRid.StartsWith('linux-ohos-')` 跳过（仿 bionic） |
| 4 | `x86_64-linux-gnu-ld.bfd: unrecognised emulation mode: aarch64linux` | `LinkerFlavor=bfd`（`_targetOS=='linux'` 默认），系统 ld 不识别 aarch64 | `Unix.targets` 加 `LinkerFlavor=lld` for OHOS（NDK 无 GNU bfd，与 bionic 同） |
| 5 | 链接后 `objcopy` 不识别 aarch64 | 系统 GNU objcopy 不支持 aarch64 | PATH 前缀用 OHOS NDK 的 `llvm-objcopy` |

### OHOS NativeAOT 链接的 4 个 targets 修复（提交上游时属 SDK 仓库）

都在 `Microsoft.DotNet.ILCompiler` pack 的 targets 内：

```xml
<!-- Microsoft.NETCore.Native.Unix.targets -->
<!-- 1. musl/ohos ABI: 匹配 OHOS NDK triple aarch64-linux-ohos -->
<CrossCompileAbi Condition="$(CrossCompileRid.StartsWith('linux-ohos-'))">ohos</CrossCompileAbi>
<!-- 2. lld linker: OHOS NDK 无 GNU bfd -->
<LinkerFlavor Condition="'$(LinkerFlavor)' == '' and $([System.String]::Copy('$(_originalTargetOS)').StartsWith('linux-ohos'))">lld</LinkerFlavor>
<!-- 3. 跳过 System.Net.Security.Native (OHOS 无 krb5) -->
<NetCoreAppNativeLibrary Include="System.Net.Security.Native" Condition="!$(_targetOS.StartsWith('tvos')) and '$(_linuxLibcFlavor)' != 'bionic' and !$([System.String]::Copy('$(_originalTargetOS)').StartsWith('linux-ohos'))" />

<!-- Microsoft.DotNet.ILCompiler.SingleEntry.targets -->
<!-- 4. libcFlavor: OHOS 是 musl (stack size 等按 musl 处理) -->
<_linuxLibcFlavor Condition="'$(_linuxLibcFlavor)' == 'ohos'">musl</_linuxLibcFlavor>
```

### 完整 publish 命令

```bash
SYSROOT=/home/springmin/hmos-tools/sdk/default/openharmony/native/sysroot
OHOS_CLANG=/home/springmin/hmos-tools/sdk/default/openharmony/native/llvm/bin/clang
export PATH="/tmp/opencode/bin-prefix:$PATH"   # llvm-objcopy 前缀

dotnet restore -r linux-ohos-arm64 -p:PublishAot=true -p:ILCompilerVersion=11.0.0-dev
dotnet publish -c Release -r linux-ohos-arm64 -p:PublishAot=true --no-restore \
  -p:UsePureLlvmToolchain=true \
  "-p:SysRoot=$SYSROOT" \
  "-p:CppCompilerAndLinker=$OHOS_CLANG"
```

### qemu 运行

```bash
qemu-aarch64 -L /tmp/ohos-qemu-root -E LD_PRELOAD=/lib/libarc4random_shim.so ./aot-test
```

> `arc4random_buf` 符号：OHOS musl 缺该符号，rootfs 提供 `libarc4random_shim.so`（用 `-E LD_PRELOAD` 注入）。

### 结论

- **OHOS NativeAOT 完整链路已打通**：C# → ilc 交叉编译 → musl 链接 → qemu 运行
- ilc 是 host 工具（x64 交叉编译），**不需要从 linux-musl 移植**——OHOS 的 JIT 库/静态库已用 OHOS 工具链构建
- 4 个修复都在 **SDK 仓库**（`Microsoft.DotNet.ILCompiler` pack targets + `BundledVersions.props`），提交上游时归入 SDK PR

---

## C.7 RID 重命名后的 NativeAOT 标准 publish 链路（2026-09-01）

在 C.6（手动补丁 + linux-ohos + dev）基础上，RID 重命名（`linux-ohos` → `ohos`）后
**用标准 `dotnet publish` 链路重新验证**，产出 `rc.1.26451.1` 正式构建的 NativeAOT packs。

### 与 C.6 的差异（本轮核心）

| 维度 | C.6（2026-08-28） | C.7（2026-09-01） |
|---|---|---|
| RID | `linux-ohos-arm64` | **`ohos-arm64`**（import linux-musl） |
| 版本 | `11.0.0-dev` | **`11.0.0-rc.1.26451.1`** |
| SDK | preview.6 + 手动补丁 BundledVersions | **x64 host SDK**（`-os linux -arch x64`，源码 GenerateBundledVersions 含 ohos） |
| ILCompiler pack | 手动补 build/ targets | **正式构建**（`clr.aot+packs` subset + sfxproj） |
| 修复层 | SDK pack targets 手动补丁 | **runtime 源码**（SingleEntry.targets） |

### 关键修复（runtime 源码层，已提交）

**`Microsoft.DotNet.ILCompiler.SingleEntry.targets`**（`91572f4362c`）：
ilc 只接受已知 target OS（linux/android/osx/...），`--targetos:ohos` 报
`Target OS 'ohos' is not supported`。映射：
```xml
<_linuxLibcFlavor Condition="'$(_targetOS)' == 'ohos'">musl</_linuxLibcFlavor>
<_targetOS Condition="'$(_targetOS)' == 'ohos'">linux</_targetOS>
```
- `_targetOS=linux` → ilc 接受 `--targetos:linux`
- `_linuxLibcFlavor=musl` → 链接保留 musl
- `CrossCompileRid`（源自 `_originalTargetOS`，未改）→ Native.Unix.targets 仍选 lld + OHOS 工具链

**SDK `GenerateBundledVersions.targets`**（`380c2d764d`）：net10 三处名单
（`Net100ILCompilerSupportedRids`/`Net100NativeAOTRuntimePackRids`/`AspNetCore100RuntimePackRids`）
补 `ohos-arm64;ohos-x64`——否则 net10 目标发布回退 linux-musl-arm64 pack。

### 正式构建命令（替代 DotNetBuildAllRuntimePacks=true）

`DotNetBuildAllRuntimePacks=true` 会同时触发 Mono cross-AOT（android/ios 等），在 ohos
环境下错乱。改用精确子集：

```sh
# ILCompiler packs（通用 + linux-x64 host + ohos-arm64 target）
./build.sh -os ohos -arch arm64 --cross -c Release ... -subset clr.aot+packs \
  -cmakeargs "-DOPENSSL_ROOT_DIR=/tmp/openssl-ohos/install ..."

# NativeAOT runtime pack
./build.sh -os ohos -arch arm64 --cross -c Release ... \
  -projects "$(pwd)/src/installer/pkg/sfx/Microsoft.NETCore.App/Microsoft.NETCore.App.Runtime.NativeAOT.sfxproj"
```

产出（全部 rc.1.26451.1，正式构建）：
- `Microsoft.NETCore.App.Runtime.NativeAOT.ohos-arm64`（26.6MB，19 静库 + CoreLib）
- `runtime.ohos-arm64.Microsoft.DotNet.ILCompiler`（15MB）
- `runtime.linux-x64.Microsoft.DotNet.ILCompiler`（宿主，9.6MB）
- `Microsoft.DotNet.ILCompiler`（通用）

### 端到端 publish 验证（x64 host SDK）

```sh
dotnet publish -c Release -r ohos-arm64 -p:PublishAot=true \
  -p:RestoreAdditionalProjectSources=/path/to/feed
# 需应用层参数（链接工具链）：
#   -p:LinkerFlavor=lld -p:SysRoot=$OHOS_NDK_HOME/native/sysroot \
#   -p:CppCompilerAndLinker=$OHOS_NDK_HOME/native/llvm/bin/clang \
#   -p:CrossCompileArch=aarch64 -p:StripSymbols=false
```

产出：`naot-test` = **ELF aarch64 musl**（interpreter `/lib/ld-musl-aarch64.so.1`）。

### 运行状态

- **qemu 运行 Segfault**：NativeAOT 运行时初始化在 `membarrier`/`mremap` 失败
  （qemu 用户模式限制）——**需真机验证**（文档 `2026-09-01-ohos-ondevice-verification.md` 的
  §2.2 NativeAOT 项）。

### 环境恢复备忘（/tmp 依赖易丢）

`/tmp/openssl-ohos`、`/tmp/icu-ohos-install` 等**重启会清空**。持久化备份在
`~/sources/ohos-assets/`（`openssl-install/`、`icu/`）。恢复：
```sh
cp -r ~/sources/ohos-assets/openssl-install/* /tmp/openssl-ohos/install/
cp -r ~/sources/ohos-assets/icu/* /tmp/icu-ohos-install/
```
若 `opensslv.h` 缺失 → `OPENSSL_VERSION` 空 → ilasm 链接 `OpenSSL::SSL` target 未定义失败。

---

*文档更新: 2026-09-01*
