# OpenHarmony OpenSSL 链接策略（H-C3 修复）

日期: 2026-09-23
关联: `docs/plans/2026-09-23-ohos-security-scan-2.md`（H-C3）。

## 1. 背景

OHOS 目标按 portable 方式构建（`src/native/libs/build-native.sh` 默认
`-DFEATURE_DISTRO_AGNOSTIC_SSL=1`），因此
`System.Security.Cryptography.Native.OpenSsl` 走 `opensslshim.c`：编译期不链接
OpenSSL，运行时 `dlopen` 裸名 `libssl.so.3`。构建脚本虽然通过
`-DOPENSSL_CRYPTO_LIBRARY=.../libcrypto.a -DOPENSSL_SSL_LIBRARY=.../libssl.a`
提供了交叉编译的静态库，但它们只满足 `find_package(OpenSSL)`，不参与链接。

裸名 `dlopen` 会让动态链接器的搜索路径（`LD_LIBRARY_PATH`、应用 lib 目录等）
决定进程使用哪份 OpenSSL，即 TLS 信任锚；同 HAP 内第三方 SDK 自带的
`libssl.so.3` 也可能被静默选中（CWE-427）。

## 2. 修复 (b)：shim 只按绝对路径解析（默认）

`src/native/libs/System.Security.Cryptography.Native/opensslshim.c`：

- OHOS（`TARGET_OPENHARMONY`）下所有候选库（`libssl.so.3`、`.1.1`、`.4`，以及
  `DOTNET_OPENSSL_VERSION_OVERRIDE` 指定的版本）都通过 `dladdr()` 求出本
  shim 所在目录，拼成 `<本库目录>/libssl.so.<ver>` 绝对路径后 `dlopen`。
- 找不到时**不回退裸名**：`OpenLibrary()` 返回 0，`InitializeOpenSSLShim()`
  以明确信息 abort（fail-closed）。
- 非 OHOS 平台编译产物与本修复前逐指令一致（见 §4）。

部署要求：随包提供 `libssl.so.3` / `libcrypto.so.3`，与
`libSystem.Security.Cryptography.Native.OpenSsl.so` 放在同一目录
（`libssl.so.3` 自身 `DT_NEEDED` 的 `libcrypto.so.3` 由应用 linker namespace
解析，应用 native lib 目录在其搜索路径内）。
注意：同目录仍属应用自身信任域（应用 lib 目录），本修复消除的是“搜索路径”
与“任意同名库”问题，不做跨信任域的摘要校验。

## 3. 修复 (a)：改为链接静态 OpenSSL（可选开关）

`-linkstaticopenssl`（`src/native/libs/build-native.sh`）或
`/p:LinkStaticOpenSsl=true`（`src/native/libs/build-native.proj`）会：

- 仅对 `-os openharmony` 生效，把 `FEATURE_DISTRO_AGNOSTIC_SSL` 置 0；
- 同时置 `CMAKE_STATIC_LIB_LINK=1`，使 `extra_libs.cmake` 把
  `OPENSSL_CRYPTO_LIBRARY` / `OPENSSL_SSL_LIBRARY` 直接链入。

前置条件：`libcrypto.a` / `libssl.a` 必须以 `-fPIC` 构建（否则链接
`libSystem.Security.Cryptography.Native.OpenSsl.so` 时报重定位错误，fail-closed）。
官方 OHOS 构建由 `sdk-ohos/eng/ohos-install/build/ohos-ci-env.sh` 交叉编译
OpenSSL（`no-shared no-tests -static`），启用该开关前应先跑一次链接验证。

用法（根构建）：

```sh
./build.sh clr+libs+packs -os openharmony -arch arm64 --cross \
  -cmakeargs "-DOPENSSL_ROOT_DIR=$OPENSSL_DIR -DOPENSSL_INCLUDE_DIR=$OPENSSL_DIR/include \
  -DOPENSSL_CRYPTO_LIBRARY=$OPENSSL_DIR/lib/libcrypto.a -DOPENSSL_SSL_LIBRARY=$OPENSSL_DIR/lib/libssl.a" \
  /p:LinkStaticOpenSsl=true
```

或直接跑 native libs 脚本：

```sh
src/native/libs/build-native.sh arm64 Release -os openharmony -arch arm64 \
  -linkstaticopenssl -cmakeargs "-DOPENSSL_SSL_LIBRARY=.../libssl.a -DOPENSSL_CRYPTO_LIBRARY=.../libcrypto.a"
```

**为什么默认不开 (a)**：静态链接更彻底，但对 `.a` 的 `-fPIC` 有硬依赖，且本
次修复未在交叉构建上验证链接结果，因此默认保留 fail-closed 的加固 shim；
(a) 作为可审计、可回退的显式开关。不要用上游的 `-portablebuild=false` 走
OHOS：`initDistroRid openharmony` 返回空 RID（实测 `__DistroRid=<>`），会把
`TargetRid` 置空，影响打包路径。

## 4. 附：TLS 静态访问快路径（H3）

`src/coreclr/vm/threadstatics.cpp` 原来对 `TARGET_LINUX_MUSL && TARGET_ARM64`
直接关闭 JIT 优化；现改为 OHOS 不早退、参与 `IsValidTLSResolver()` 指令序列
探测（静态解析器才启用，失败保持数组间接），其它平台不变。

设备实测（OHOS arm64 + NDK clang 15.0.4，`-fno-emulated-tls`，harness 见
`/data/storage/el2/base/tmp/opencode/fix-tls/tls/`）：

- `GetTLSResolverAddress` 指令序列匹配预置检查；
- 但 musl 的 TLSDESC 解析器是动态解析器：
  `stp x1,x2,[sp,#-16]!; mrs x1, TPIDR_EL0; ldr x0,[x0,#8]; ...`，
  且 `t_ProbeThreadStatic` 的地址每线程不同；
- `IsValidTLSResolver()` 实测返回 0 → OHOS 仍走 `_NOJITOPT` 数组间接路径，
  行为与修复前一致；只有未来 musl 提供静态解析器（或换 libc）时才会启用
  快路径。

## 5. 验证记录（2026-09-23）

```sh
# 编译 shim（OHOS NDK clang 15.0.4 + 目标 sysroot）
clang-15 --target=aarch64-linux-ohos --sysroot=$NDK/sysroot \
  -I.../System.Security.Cryptography.Native -I.../Common -I.../src/native \
  -D_GNU_SOURCE -DFEATURE_DISTRO_AGNOSTIC_SSL -DTARGET_OPENHARMONY \
  -DTARGET_LINUX -DTARGET_LINUX_MUSL -DTARGET_UNIX \
  -fPIC -pthread -O2 -Wall -Werror -Wno-deprecated-declarations \
  -c opensslshim.c
# 链接后 readelf -d: NEEDED 仅 [libc.so]

# 设备端前后对比（decoy libssl.so.3 放在 LD_LIBRARY_PATH，不在 shim 目录）
#  HEAD shim:  OpenLibrary=1   ← 裸名被 LD_LIBRARY_PATH 劫持
#  修复 shim:  OpenLibrary=0   ← 拒绝加载；把 decoy 放到 shim 同目录才 =1

# 构建参数模拟（build-native.sh 副本 + 假 uname，源仓 eng/native 逻辑）
#  OHOS 默认              -> -DFEATURE_DISTRO_AGNOSTIC_SSL=1, CMAKE_STATIC_LIB_LINK=0
#  OHOS -linkstaticopenssl -> -DFEATURE_DISTRO_AGNOSTIC_SSL=0, CMAKE_STATIC_LIB_LINK=1
#  linux -linkstaticopenssl-> 开关被忽略（保持 1/0）

# H3 分支选择（从 threadstatics.cpp 机械抽取 CanJITOptimizeTLSAccess 编译运行）
#  linux musl arm64（无 OHOS）      -> 0   （早退保留，非 OHOS 不变）
#  OHOS + 探测成功                  -> 1   （只有探测通过才启用）
#  OHOS + 探测失败                  -> 0   （fail-closed）

# H3 设备实测：由 asmhelpers.S 抽出的 GetTLSResolverAddress/探测体
#  probe(before/after TLS access)=0；resolver code 首 4 字 = a9bf0be1 d53bd041
#  f9400400 a9400800（动态解析器），故保持慢路径。
```

未做：全量 OHOS 交叉构建、`-linkstaticopenssl` 的真实 `.a` 链接、设备端
SslStream/HTTPS 自检。
