# OpenSSL 对 OpenHarmony 的支持调研（2026-11-03）

> 调研对象：OpenSSL 上游对 OpenHarmony 的官方支持、OHOS 上的可构建性，以及这对 .NET upstream 官方支持的影响。
>
> 数据源：OpenSSL GitHub 仓库的 `Configurations/10-main.conf`（`master`、`4.1.0`、`4.0.0`、`3.5`）；OpenSSL 发布策略；`openharmony/third_party_openssl`；`ohos-rs/ohos-openssl`；本地 OpenHarmony SDK 与 HAP。
>
> 时间：2026-11-03。本文只记录调研结论，不包含代码变更。

## 0. 结论速览

- **严格定义：OpenSSL 上游不支持 OHOS。** `master`、`4.1.0`、`4.0.0`、`3.5` 都没有 `ohos` / `openharmony` target；文档、CI、PR/issue 中也没有 OHOS 支持项。
- **工程定义：OpenSSL 可以在 OHOS 上构建和运行。** 可以用 `linux-aarch64` target、OHOS clang/sysroot 和 `-D__MUSL__` 交叉编译；OpenHarmony 自己和社区都已经这样做。
- **OpenHarmony 自带的是 fork，不是上游支持。** `openharmony/third_party_openssl` 基于 OpenSSL 3.0.9，使用 `linux-aarch64` target 构建；它是系统组件，不等于 OpenSSL 官方支持 OHOS。
- **社区有可用的构建方案。** `ohos-rs/ohos-openssl` 通过 patch 增加 `ohos-aarch64`、`ohos-arm`、`ohos-x86_64` target，并提供 arm64-v8a、armeabi-v7a、x86_64 的预编译产物。
- **OHOS public SDK 不提供 `libssl` / `libcrypto`。** SDK sysroot 只有 `libohcrypto.so`；HAP 必须自带 OpenSSL，或由 .NET workload/runtime pack 提供。
- **对 .NET 官方支持的含义：** OpenSSL-on-OHOS 可行，且不需要等 OH_Crypto 补齐 X.509/TLS。建议以 **OpenSSL 3.5 LTS** 作为官方支持的 crypto provider 候选；OH_Crypto 仍作为后续优化项。
- **已验证（2026-11-04）：** OpenSSL 3.5.9 已用 `linux-aarch64` + OHOS clang/sysroot 交叉构建成功；在 HarmonyOS 宿主和 AOT HAP 内均完成了 SHA/AES-GCM/RSA/ECDSA/X.509/TLS 1.3/`HttpClient` 自检，HAP 内 `failures=0`。任意 bundle 的 UI shell 已用 `build-arkts-shell.sh` 手工生成并验证。
- **仍待验证：** workload 自动生成任意 bundle 的 ArkTS shell、JIT HAP 启动（安装已通过）、OpenSSL 静态链接、HAP 启动/内存，以及 CA 系统 store 的设备契约和完整负控。

## 1. 调研口径

本文区分三个概念：

| 概念 | 定义 | 本文结论 |
|---|---|---|
| OpenSSL 官方支持 OHOS | OpenSSL 上游有 OHOS target、CI、文档和维护承诺 | **否** |
| OpenSSL 可在 OHOS 上构建 | 使用 OpenSSL 源码和 OHOS 工具链可以生成可用的 `libssl` / `libcrypto` | **是，已有先例** |
| .NET 官方支持使用 OpenSSL | .NET 在 OHOS 上以 OpenSSL 作为 crypto/TLS provider，并由 .NET 发行物提供库 | **可行，需打包和验证** |

“能编译”不等于“OpenSSL 官方支持”。OHOS 特有的 bug、构建问题和安全更新由集成方负责，不能依赖 OpenSSL 上游修复。

## 2. OpenSSL 上游状态

### 2.1 没有 OHOS target

检查 OpenSSL 的 `Configurations/10-main.conf`：

| 版本 | OHOS target | 备注 |
|---|---|---|
| `master` | 无 | 没有任何 `ohos` / `openharmony` / `harmony` 条目 |
| `4.1.0` | 无 | 当前最新版本 |
| `4.0.0` | 无 |  |
| `3.5` | 无 | LTS 分支 |

上游只有 Linux target，例如：

```text
linux-aarch64
linux-armv4
linux-x86_64
```

其中 `linux-aarch64` 是 OpenHarmony 和社区方案实际使用的 target。

### 2.2 文档、PR、issue

- OpenSSL 的平台说明只列 Unix/Linux、Android、Windows、VMS、DJGPP 等，没有 OHOS。
- OpenSSL 仓库中没有找到 OHOS/OpenHarmony 相关的支持 PR 或 issue。
- 因此不能把 OpenSSL 上游文档作为 OHOS 支持的依据；只能把它当作“Linux 目标可复用”的依据。

### 2.3 版本生命周期

OpenSSL 官方发布策略（2026-11 快照）：

| 版本 | 状态 | 支持截止 |
|---|---|---|
| 3.0 | **已不再支持** | 已结束 |
| 3.5 | **LTS** | 2030-04-08 |
| 4.0 | 当前支持 | 2027-05-14 |
| 4.1 | 当前最新 | 按 4.1 策略 |

`openharmony/third_party_openssl` 的 `VERSION.dat` 仍是 **3.0.9**（2023-05-30），并带有 CVE backport。它适合 OpenHarmony 系统内部维护，但**不适合作为 .NET 官方支持的长期基线**。

建议 .NET 官方支持使用 **OpenSSL 3.5 LTS**，不要依赖 OpenHarmony 的 3.0.9 fork。

## 3. OHOS 上的构建现状

### 3.1 OpenHarmony 的 `third_party_openssl`

`openharmony/third_party_openssl`：

- 版本：OpenSSL 3.0.9
- License：Apache-2.0
- 构建系统：GN
- OHOS 分支在 `BUILD.gn` 中对 `current_os == "ohos"` 选择：

```text
linux-aarch64
```

armv7 使用 `linux-armv4`，LoongArch64 使用 `linux64-loongarch64`。

这说明 OpenHarmony 的集成方式是：

```text
OpenSSL Linux target + OHOS clang/sysroot + 平台补丁
```

而不是等待 OpenSSL 上游新增 OHOS target。

该仓库构建 `libcrypto_shared`、`libcrypto_static`、`libssl_shared`、`libssl_static` 等目标，属于 OpenHarmony 系统组件；public SDK 并不直接暴露这些库给应用。

### 3.2 社区 `ohos-rs/ohos-openssl`

`ohos-rs/ohos-openssl` 提供 OpenSSL 的 OHOS 预编译和构建脚本。

patch 增加：

```text
ohos-aarch64   -> inherit_from linux-aarch64
ohos-arm       -> inherit_from linux-generic32
ohos-x86_64    -> inherit_from linux-x86_64
```

构建脚本使用：

```text
-target aarch64-linux-ohos
--sysroot=${OHOS_NDK_HOME}/native/sysroot
-D__MUSL__
```

支持：

```text
arm64-v8a
armeabi-v7a
x86_64
```

这说明 `ohos-*` target 本质上是对 Linux target 的命名和少量 flags 适配，不是完整移植。

### 3.3 推荐构建方式

对 .NET 官方支持，优先验证：

```text
OpenSSL 3.5 LTS
target: linux-aarch64
CC: OHOS clang
CFLAGS: -target aarch64-linux-ohos --sysroot=<sdk>/native/sysroot -D__MUSL__
```

**2026-11-04 验证：** OpenSSL 3.5.9 直接使用 `linux-aarch64` 构建成功，不需要 `ohos-aarch64` target patch。唯一的构建环境问题是宿主机的 `lld` 需要 `libxml2.so.16`，通过 `LD_LIBRARY_PATH=<SDK>/llvm/lib` 解决；这不是 OpenSSL 源码适配。仍不要直接依赖 OpenHarmony 3.0.9 的系统 fork。

## 4. SDK 与 HAP 打包

### 4.1 Public SDK 没有 `libssl` / `libcrypto`

本地 OpenHarmony SDK（`26.0.0.18_2`）的 sysroot 中：

```text
native/sysroot/usr/lib/aarch64-linux-ohos/libohcrypto.so
```

没有：

```text
libssl.so
libcrypto.so
```

`libohcrypto.so` 是 CryptoArchitectureKit 的高层 API，不是 OpenSSL ABI，不能替代 `libssl` / `libcrypto`。

### 4.2 HAP 需要自带 OpenSSL

检查 `hello-maui-app-debug.hap` 的 `libs/arm64-v8a`：

```text
libc++_shared.so
libhello-maui-app.so
libopenharmonyhost.so
```

没有 `libssl` / `libcrypto`。

因此：

- 只使用基础 primitives 且不建立 TLS 的 app，可能不会立即暴露问题；
- 使用 `SslStream`、`HttpClient` HTTPS、gRPC 或需要证书链的 app，必须把 OpenSSL 放进 HAP；
- 或者由 .NET workload/runtime pack 在构建时把库复制进 HAP。

### 4.3 与 `#136194` 的关系

`#136194` 的相邻目录 fallback 解决的是：

```text
dotnet exec myapp.dll
```

这种场景下 OpenSSL 不在 loader 的默认搜索路径，需要从 native shim 所在目录加载。

它不是完整的官方支持方案；官方支持还需要：

- HAP 打包 `libssl.so.3` / `libcrypto.so.3`
- CA 信任路径或 CA bundle
- `X509Chain` / `SslStream` 设备测试
- OpenSSL CVE 更新和 servicing

## 5. 对 .NET upstream 官方支持的含义

### 5.1 OpenSSL-on-OHOS 可以作为正式 provider

与 Linux 类似：

```text
System.Security.Cryptography.Native.OpenSsl
        -> bundled libssl/libcrypto
```

这条路线的好处：

- 保留完整的 X.509、TLS、ASN.1、OCSP、PKCS#7 能力
- 不需要新增 409 个 native entrypoints
- 不需要等 OH_Crypto 补齐 X.509/TLS
- 可以复用现有的 OpenSSL backend 和测试体系
- 与 `#136194` 的 fallback 方向一致

### 5.2 OH_Crypto 不是官方支持的前置条件

OH_Crypto 当前覆盖：

```text
Digest / HMAC / KDF / AES / RSA / ECC / SM2 / DH / X25519 / RNG
```

但没有：

```text
X.509 解析和链验证
ASN.1 / BIO / EVP
PKCS#7 / CMS / OCSP
TLS
```

即使全部 primitives 换成 OH_Crypto，`SslStream` 和 `X509Chain` 仍然需要 OpenSSL。因此：

> 官方支持不应以 OH_Crypto 全量 backend 为前提；先把 OpenSSL-on-OHOS 做成受支持路径，OH_Crypto 作为后续优化。

### 5.3 与现有 PR 的关系

| PR | 关系 |
|---|---|
| `dotnet/runtime#136194` | 保留相邻目录 fallback；是 `dotnet exec` 的加载修复，不是完整 crypto 方案 |
| `dotnet/dotnet-buildtools-prereqs-docker#1786` | OpenHarmony image；可在镜像构建阶段产出 OpenSSL 资产 |
| `dotnet/runtime#136206` | OHOS CI leg；官方支持需要稳定 CI |
| `dotnet/sdk`、`dotnet/aspnetcore` | workload/runtime pack、HAP 打包、shared framework |

## 6. 验证记录（2026-11-04）

> 验证根目录：`/data/storage/el2/base/tmp/opencode/openssl-ohos-3.5.9/`
>
> 环境：HarmonyOS 宿主（aarch64）；OpenHarmony SDK `26.0.0.18_2`；设备 `HAD-W24 / OpenHarmony 7.0.0.111`，hdc target `127.0.0.1:36823`。

### 6.1 OpenSSL 3.5.9 交叉构建

已验证：使用 OpenSSL 3.5.9 源码和 OHOS SDK 构建成功，target 为 `linux-aarch64`，不需要 `ohos-aarch64` patch。

关键命令：

```sh
SDK=/storage/Users/currentUser/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_2/native
CC=$SDK/llvm/bin/clang
CFLAGS="-target aarch64-linux-ohos --sysroot=$SDK/sysroot -D__MUSL__ -O2 -fPIC"
LDFLAGS="-target aarch64-linux-ohos --sysroot=$SDK/sysroot"
./Configure linux-aarch64 shared no-tests no-docs \
  --prefix=<install> --openssldir=<install>/ssl --libdir=lib
LDFLAGS="$LDFLAGS" LD_LIBRARY_PATH=$SDK/llvm/lib make -j4
```

另外需要把 `AR`、`RANLIB`、`NM`、`STRIP`、`OBJCOPY`、`OBJDUMP` 指向同一 SDK 的 `llvm/bin` 工具。

构建环境有一个宿主侧问题：SDK 的 `lld` 需要 `libxml2.so.16`，默认找不到时链接会失败。设置：

```sh
LD_LIBRARY_PATH=$SDK/llvm/lib
```

后构建通过。这不是 OpenSSL 源码问题。

产物：

| 文件 | 大小 | SHA-256 |
|---|---:|---|
| `libcrypto.so.3` | 5,716,480 | `60849c69d66da40b45701ca068a93438449f043f047fd5ba180068f8907d860e` |
| `libssl.so.3` | 1,018,432 | `734c8db88aa2991df21263f013bceef50dd7bc891bb6898cb4ea5901b5ceaf8b` |
| `apps/openssl` | 1,120,832 | `a50abd8ea1a48be5642f094fc6f3abce89b4303126faf1878e3939e2ee3ce8ce` |

### 6.2 HarmonyOS 宿主侧 OpenSSL 自检

在宿主上直接执行刚构建的 `openssl`：

- `OpenSSL 3.5.9 29 Sep 2026`
- SHA-256 `abc`：`ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`
- AES-256-CBC roundtrip：PASS
- AES-256-GCM：PASS（`openssl enc` 不支持 AEAD，改用 `EVP_Encrypt*` C harness）
- RSA-2048 sign/verify：PASS
- ECDSA P-256 sign/verify：PASS
- X.509 自签名证书 `verify`：PASS
- TLS 1.3 loopback：PASS，cipher `TLS_AES_256_GCM_SHA384`，group `X25519MLKEM768`

日志：`selfcheck2.log`、`gcm.c`。

### 6.3 HarmonyOS 宿主侧 .NET 自检

用 RC3 SDK（`11.0.100-rc.3.26522.148` / runtime `11.0.0-rc.3.26522.148`）运行一个 `net11.0` 探针，环境：

```sh
LD_LIBRARY_PATH=<openssl-3.5.9>/src
SSL_CERT_FILE=/etc/ssl/certs/cacert.pem
DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
```

结果：

```text
sha256=PASS
aes_gcm=PASS
rsa_sign_verify=PASS
ecdsa_sign_verify=PASS
x509_load=PASS
x509_chain_default=False status=UntrustedRoot
x509_chain_custom=True
tls13_custom_root=PASS
tls_protocol=Tls13
tls_cipher=TLS_AES_256_GCM_SHA384
http_status=200
http_default_trust=PASS
failures=0
```

说明：

- `x509_chain_default=False` 对自签名测试证书是预期结果；自定义 root 链验证通过。
- `HttpClient` 默认信任在设置 `SSL_CERT_FILE` 后返回 200。
- 这是 **HarmonyOS 宿主进程**验证，不是 HAP 沙箱内验证；HAP 内的路径和 CA 仍需单独测试。
- 探针通过 `LD_LIBRARY_PATH` 指向 3.5.9 产物；尚未抓 loader 级路径，HAP 内还需再次确认实际加载的库。

日志：`netprobe4.log`。

### 6.4 设备与 HAP 侧

设备侧 `hdc shell` 不能直接执行 `/data/local/tmp` 下的 ELF：

- 最小 OHOS ELF 也会返回 `Permission denied`（`rc=126`）。
- `binary-sign-tool -selfSign 1` 签名后结果相同。
- 这说明 standalone CLI 验证受执行域限制，不能用它直接跑 `openssl`；应通过 HAP/ability 运行。

HAP 安装验证：

- 现有 AOT `hello-maui-app-debug.hap` 用 `sign-hap.sh` 重签后 `hdc install` **成功**。
- 旧布局 JIT `hello-app.hap` 用同一流程重签后 `hdc install` 返回 `9568393 verify code signature failed`；2026-11-04 的 A/B 已确认根因是 payload-in-libs 的 DeviceCompat 两个陷阱，不是 JIT/OpenSSL 错误（见 6.6）。

HAP 内容检查：

- `hello-app.hap`（JIT）和 `hello-maui-app-debug.hap`（AOT）都没有 `libssl.so.3` / `libcrypto.so.3`。
- 两者只有 `libSystem.Security.Cryptography.Native.OpenSsl.so`。
- 因此使用 TLS 的 HAP 必须显式打包 OpenSSL，或者由 workload/runtime pack 注入。

最小 AOT probe HAP：

- probe 已构建并安装（`hap-aot/`，AOT、shared OpenSSL）。
- HAP `libs/arm64-v8a` 明确包含 `libssl.so.3`、`libcrypto.so.3`、`libProbe.so`。
- 设备上日志确认 `OpenSSL_version=OpenSSL 3.5.9 29 Sep 2026`，即加载的是 HAP 内 3.5.9。
- HAP 内结果：

```text
sha256=PASS
aes_gcm=PASS
rsa=PASS
ecdsa=PASS
x509_create=PASS
x509_chain_default_expected_untrusted=PASS
x509_chain_custom_root=PASS
sslstream_tls13=PASS
http_default_trust=PASS
failures=0
```

- 任意 bundle 验证：先用 `scripts/build-arkts-shell.sh` 生成指定 bundle 的 UI shell：

```sh
ARKTS_BUILD_DIR=<shell-build> \
ARKTS_SHELL_BUNDLE_NAME=com.example.opensslprobe \
ARKTS_SHELL_VARIANT=ui \
OUT_DIR=<shell-build>/dist/ets \
bash scripts/build-arkts-shell.sh
```

- 生成的 `modules.abc`：637,256 B，SHA-256
  `1806cc5dc3a8dfe8549820bcf20fed5212bd9e8abb042fba29b0a55358085c7d`。
- 再用该 abc 打包：

```text
-p:OpenHarmonyUIPage=pages/Index
-p:OpenHarmonyArktsModulesAbc=<shell-build>/dist/ets/modules.abc
-p:OpenHarmonyBundleName=com.example.opensslprobe
```

- 任意 bundle 的 signed probe HAP：**19,805,008 B**，SHA-256
  `6a35e786b13e01fe64362dbaa6f5dcff0f4706e149ad62c1ea7c66cfecb3ed13`。
- 设备日志以 `com.example.opensslprobe` 包名输出同一组 PASS，并确认
  `OpenSSL_version=OpenSSL 3.5.9`；因此任意 bundle 的 UI shell 已手工验证可行。

构建过程中确认的另一个非 OpenSSL 问题：

- 项目不引用 `Microsoft.Maui.dll` 时，`_OpenHarmonyStageHybridWebViewScript` 仍调用
  `OpenHarmonyExtractEmbeddedResource`，`AssemblyPath` 为空，报 `MSB4044`。
  已在 `ohos-workload` 的 HAP target 加空 item 条件修复，并让 T9/T11 fixture 不再覆盖该 target；
  `selftest-hap-targets.sh` 结果为 **119 checks / 0 failed / 1 skipped**（T12 gate 加入后的完整计数）。
- 预编译 `templates/ets/modules.ui.abc` 固定写入 `mauidemo.dotnet.springmin.com`；
  默认 `OpenHarmonyUIPage` 路径不能直接用于任意 bundle。已用 `build-arkts-shell.sh` 按 bundle 生成并验证；正式支持仍需要 workload 自动生成/选择对应 shell，而不是依赖手工命令。

- `/data/local/tmp` 写入失败是应用沙箱限制，不是测试失败；结果通过 `OH_LOG_PrintMsg`（tag `openssl-probe`）输出。

日志：`hap-aot/hilog-version.txt`、`hap-aot/hilog-arbitrary.txt`、
`arkts-shell-opensslprobe/build.log`、`publish-arbitrary.log`、`sign-arbitrary.log`、
`hap-targets-green2.log`。

### 6.5 任意 bundle shell：单份通用 abc 不可行，target 增加前置校验

2026-11-04 继续验证了“single generic ArkTS shell + `pkgContextInfo.json`”方案：

- `useNormalizedOHMUrl=true` 时 hvigor 会生成 `pkgContextInfo.json`，但 HAP 还必须通过
  `ohos_packing_tool --pkg-context-path` 打包，并且 `module.json` 必须带
  `packageName`；缺 `packageName` 时设备日志报
  `The PkgContextInfo is empty ... currentModuleName:entry`，ability 仍按旧路径查找。
- 补齐 `packageName` 后，normalized 的 **EntryAbility 记录**可以加载；但 ArkUI 页面元数据
  仍把构建时 bundle 写进 abc（`pagePath`/`pageFullPath` 旁的 bundle 字符串），换 bundle 后
  报 `Load Page Failed: pages/Index`。命名路由（`@Entry({ routeName })` +
  `loadContentByName`）实验未得到可用的跨 bundle 结果，不能作为通用方案。
- 结论：**页面能力要求 per-bundle shell**；在没有改写 abc 页面元数据的情况下，单份
  `modules.ui.abc` 不能同时服务任意 bundle。

workload target 现在的行为：

- `preview.22`–`preview.31` 的 `OpenHarmony.Hap.targets` 新增
  `_OpenHarmonyValidateArktsShellBundle`：当 `OpenHarmonyBundleName` 与预编译 shell 的
  `OpenHarmonyBundledArktsShellBundle` 不一致，且没有显式 `OpenHarmonyArktsModulesAbc` 时，
  在 staging 前失败。该属性按 pack 设置：`preview.22`–`24`、`28`–`31` 为
  `mauidemo.dotnet.springmin.com`，`preview.25`–`27` 的预编译 shell 是
  `com.example.hellomauiapp`。
- UI 和 headless 分支分别给出对应重建命令；显式 `OpenHarmonyArktsModulesAbc` 是逃生口，
  适用于已经按目标 bundle 构建好 shell 的调用方。
- `selftest-hap-targets.sh` 新增 T12 覆盖该 gate，并给 T9/T11 的打包-only fixture 显式传入
  预编译 shell；完整结果为 **119 checks / 0 failed / 1 skipped**（T6 无设备跳过）。
  日志：`hap-targets-shell-gate2.log`。

按 bundle 重建的现场验证：

- 用 `build-arkts-shell.sh` 为 `com.example.opensslprobe2` 构建 non-normalized UI shell：
  637,264 B，SHA-256 `2ec972fb95d4e731c0ac3ba102a93baa0aba6bcb91d3a85849be94b9975f4d8c`。
- 直接将 abc 放进现有 AOT probe HAP（不传 `pkg-context-path`），签名后安装运行：
  HAP 19,804,999 B，SHA-256
  `fe0aefa39b148b43bbb9058fc2942252c1431c427a508e45e3ca4645247af491`。
- 设备 `hilog` 以 `com.example.opensslprobe2` 输出 `OpenSSL 3.5.9`、全部探针 PASS
  （`failures=0`），当前测试没有新的 jscrash；证明 per-bundle shell 路径可用。
- 这次 target gate 采用 **fail-fast**，不是 pack-time 自动 hvigor 构建；自动构建仍受
  Node/网络、Windows shell 和构建耗时约束，是否作为 opt-in 需单独决定。

### 6.6 JIT `9568393`：已确认根因，不是 JIT 特有问题

2026-11-04 在 HAD-W24（7.0.0.111 enforcing 镜像）上做了最小 A/B/C：

- **对照 E（DeviceCompat 布局）**：`stock-kit/jit/hello-maui-app-jit.hap`
  （SHA-256 `93e2634c…`，`libs/arm64-v8a` 无无扩展名文件、无 4096 B 文件）
  `hdc install` **成功**，`bm dump` 可读到 `com.example.hellomauiapp`。
- **回归 A（无扩展名）**：把同一 unsigned HAP 的 `createdump.so` 改回无扩展名
  `createdump` 后重签，install 返回 `9568393`；hilog：
  `ParseNativeLibSignInfo: Libs signature not found: signMap_ size:274, signMapPreSize:1`
  → `enable code signature failed: 8519738`。
- **回归 B（4096 B）**：只把 `Microsoft.OpenHarmony.dll` 从 4100 B 改回 4096 B（保留
  `createdump.so`）后重签，install 仍返回 `9568393`；hilog：
  `EnableCodeSignForFile ... Microsoft.OpenHarmony.dll, ret = -768` →
  `EnforceCodeSignForAppWithPluginId: Enforcing done, ret = -768` →
  `enable code signature failed: 8519738`。
- **结论**：`9568393` 是 enforcing 镜像对 `libs/<abi>/` 的逐文件代码签名要求与
  payload-in-libs 布局的兼容性问题；默认
  `OpenHarmonyHapPayloadInLibsDeviceCompat=true` 已通过改名/补 4 B 解决。旧 kit HAP 必须
  重出包，或使用 `-p:OpenHarmonyHapPayloadInLibs=false`。本次不需要再改 target 代码。
- 证据：`/data/storage/el2/base/tmp/opencode/jit-9568393-ab/` 下的
  `control-install.log`、`install-hilog.txt`、`install-4096-hilog.txt`；
  重签 HAP 的 SHA-256：
  - 无扩展名回归：`ccda70209cb0e1a09bf605a0355bdaba5073d986ecaedf6c5cf0ccb8bc8cc476`
  - 仅 4096 B 回归：`a43dfdf3cb50db151da5e732a4cfb954099f9c9f99071c565ba5094de33a5f5c`

### 6.7 HAP CA 信任路径（已实现并验证）

2026-11-04 在 AOT probe HAP（bundle `com.example.opensslprobe`）中增加了 CA 路径日志：

```text
ssl_cert_file_env=<unset>
ssl_cert_dir_env=<unset>
openssl_default_cert_file=/data/storage/el2/base/tmp/opencode/openssl-ohos-3.5.9/install/ssl/cert.pem
openssl_default_cert_dir=/data/storage/el2/base/tmp/opencode/openssl-ohos-3.5.9/install/ssl/certs
http_default_trust=PASS
```

- 这两个默认路径是构建机的 OpenSSL install prefix；当前 HAP 只带 `libssl.so.3` /
  `libcrypto.so.3`，没有 CA 文件，因此不能把这两个路径当作可移植的信任来源。
- .NET 侧 `pal_x509_root.c` 先读 `SSL_CERT_FILE` / `SSL_CERT_DIR`，再回退到 OpenSSL 默认；
  `OpenSslCachedSystemStoreProvider` 在默认 store 为空时还会尝试 `/etc/ssl/certs`。
  观测到的 `http_default_trust=PASS` 与“使用设备系统 CA store”一致，但 HAP 自身没有
  携带 CA bundle。
- 待定策略：如果目标 OHOS 镜像保证系统 CA store 可读，可以明确依赖系统 store；否则需要在
  HAP 中带 CA bundle，并在 OpenSSL 初始化前设置 `SSL_CERT_FILE`/`SSL_CERT_DIR`，同时补
  自签名/过期/错误主机名的负控。当前证据不支持“HAP 自带 CA”这一说法。
- 证据：`hap-aot/hilog-ca-paths.txt`；HAP 文件列表中没有 `*.pem`/`*.crt`/CA bundle。

实现（2026-11-04）：

- `ohos-workload` HAP target 新增 `OpenHarmonyTrustMode=system|app|both`、
  `OpenHarmonyCaBundle` 和 `OpenHarmonySystemCaDir`。target 把 `trust.json` +
  `trust-ca.pem` 写入 publish payload，因此 payload-in-libs（`libs/<abi>/`）和
  `dotnet.zip` fallback 都带同一份信任配置。
- native host 新增 `host_trust.c`/`host_trust.h`；`openharmony_host.c` 在 hostfxr/coreclr
  启动前读取 `<app_dir>/trust.json` 并设置 `SSL_CERT_FILE`/`SSL_CERT_DIR`。`app` 模式显式
  设置空 `SSL_CERT_DIR`，阻止系统 store 回退；`both` 缺少 CA 时退化为 system-only。
- 设备 A/B：
  - `both`：`trust: mode=both ca=.../trust-ca.pem dir=/etc/ssl/certs app=1 system=1`，
    `ssl_cert_file_env`/`ssl_cert_dir_env` 与配置一致，`http_default_trust=PASS`；
  - `app`：`trust: mode=app ... app=1 system=0`，`ssl_cert_dir_env=""`，
    `http_default_trust=FAIL`（预期负控，证明系统 store 被抑制）。
  - HAP 内 `etc_ssl_certs_count=1`（`cacert.pem`）、`system_certificates_count=125`
    （hash `*.0` 文件），两者对应用可见。
- TLS 负控（同一 `both` HAP）：
  - `sslstream_custom_root=PASS`；
  - `sslstream_self_signed_expected_reject=PASS expected AuthenticationException`；
  - `sslstream_wrong_host_expected_reject=PASS expected AuthenticationException`；
  - `sslstream_expired_expected_reject=PASS expected AuthenticationException`；
  - `sslstream_public_default=PASS`、`http_default_trust=PASS`、`failures=0`。
- 系统 CA 契约：`/etc/ssl/certs` 是单文件 `cacert.pem`，`/system/etc/security/certificates`
  是 125 个 hash 文件；默认仍使用 `/etc/ssl/certs`，跨镜像需确认两者是否同时存在。
- HAP target 的 T13 覆盖 trust.json/ca 的复制、`app` 缺 CA、`system` 与 CA 冲突、
  `both` 无 CA 退化和非法 mode；`selftest-host-trust.sh` 覆盖三种 mode 的 pure-C 策略。
- 证据：`hap-aot/hilog-trust-both.txt`、`hap-aot/hilog-trust-app.txt`、
  `hap-aot/hilog-tls-negative.txt`、`publish-trust-both.log`、`publish-trust-app.log`。

### 6.8 AOT probe 的启动与内存（首轮）

2026-11-04 对 `Probe-ca-probe.hap`（bundle `com.example.opensslprobe`，AOT、shared
OpenSSL 3.5.9，HAP 19,805,009 B）做了一次设备侧观测：

- `aa start` 命令前的设备时间 `1793794813850 ms`；首条
  `openharmony_app_main entered` 日志为 `1793794814.341 s`，约 **0.49 s**（包含
  `aa start` 调度，不是纯进程启动时间）。
- 启动后约 2 s：`VmRSS=121,628 kB`、`VmHWM=121,628 kB`；`hidumper --mem` 的 PSS
  分量包括 native heap 20,950 kB、`.so` 18,192 kB、ark ts heap 7,257 kB、Graph 10,940 kB、
  `.hap` 3,614 kB 等。
- 这是**首轮、非稳态**数据，未做多次冷启动/热启动、TLS 吞吐或长时间内存增长测试；
  不能当作最终性能指标。

## 7. 风险与待验证项

### 7.1 状态

| 项 | 状态 | 说明 |
|---|---|---|
| OpenSSL 3.5 LTS 交叉构建 | **已验证** | `linux-aarch64` + OHOS clang/sysroot 成功 |
| 是否需要 `ohos-aarch64` patch | **已验证：不需要** | 3.5.9 直接使用 `linux-aarch64` |
| 宿主 OpenSSL 算法/X.509/TLS | **已验证** | SHA/AES/RSA/ECDSA/X.509/TLS 1.3 |
| 宿主 .NET `SslStream`/`X509Chain` | **已验证** | `failures=0`，默认信任依赖 `SSL_CERT_FILE` |
| HAP 内 `SslStream`/`X509Chain` | **已验证** | AOT probe HAP `failures=0`，日志确认 OpenSSL 3.5.9 |
| HAP 签名/打包闭环 | **部分验证** | AOT HAP 可安装并运行；JIT DeviceCompat HAP 安装成功，旧布局 `9568393` 已确认根因；JIT 启动未测 |
| 空 Maui batching | **已验证修复** | target 增加空 item 条件；`selftest-hap-targets.sh` 119/0/1 |
| NativeAOT 静态 vs JIT 共享 | **部分验证** | AOT + shared OpenSSL 已验证；静态链接和 JIT 未验证 |
| HAP 体积/启动/内存 | **部分验证** | AOT probe HAP 19,805,009 B；首轮 `aa start` 到托管入口约 0.49 s、2 s 时 VmRSS 121,628 kB；冷/热启动、TLS 吞吐和稳态内存未测 |
| HAP 内 CA 路径 | **已验证** | target/host 支持 `system`/`app`/`both`；HAP CA 与系统 `/etc/ssl/certs` 可同时生效；自签名/过期/错误主机名均被拒，`app` 模式系统 store 被抑制 |
| 任意 bundle 的 UI shell | **已验证 + target gate** | per-bundle shell 在 `com.example.opensslprobe2` 上启动并跑完探针；target 对 bundle 不匹配且未显式给 abc 的构建 fail-fast；自动生成仍待决定 |

### 7.2 风险

| 风险 | 说明 |
|---|---|
| OpenSSL 上游不支持 OHOS | OHOS 特定问题由集成方负责，需要自维护构建/补丁 |
| OpenSSL 3.0 已 EOL | 不能把 OpenHarmony 3.0.9 当作长期基线 |
| CA 信任路径 | 已实现 system/app/both 与 payload CA；自签名/过期/错误主机名负控已通过；跨镜像仍需确认 `/etc/ssl/certs` 与 `/system/etc/security/certificates` 的并存关系 |
| 库加载 | HAP 的 `$ORIGIN`、`dotnet exec` 的相邻目录 fallback 需要分别验证 |
| UI shell bundle 绑定 | 预编译 `modules.ui.abc` 固定 `mauidemo.dotnet.springmin.com`；target 已 fail-fast 并给出手工生成命令，自动按 bundle 生成仍待决定 |
| JIT HAP 签名 | 旧布局 payload-in-libs HAP 出现 `9568393`；根因是无扩展名/4096 B 文件，默认 DeviceCompat 已修复，旧 kit HAP 需重出包 |
| 安全更新 | OpenSSL CVE 需要重新构建并发布 HAP/workload |
| License | 需要随包附 Apache-2.0 NOTICE，并做再分发合规检查 |

## 8. 下一步

1. 决定任意 bundle ArkTS shell 的自动生成策略：当前 target 已对 bundle 不匹配 fail-fast，并给出 `build-arkts-shell.sh` 命令；是否在 pack time 自动运行（受 Node/网络、Windows shell、构建耗时约束）仍需单独评估。
2. JIT `9568393` 已确认是 DeviceCompat 两个陷阱：旧 kit HAP 需要重出包或 `-p:OpenHarmonyHapPayloadInLibs=false`；如需验证 JIT 运行路径，再补安装后的启动/崩溃排查。
3. 验证 NativeAOT **静态链接** OpenSSL（当前 probe 是 AOT + 共享 libssl/libcrypto）。
4. CA 策略已实现 system/app/both + payload CA；自签名/过期/错误主机名负控已通过；剩余跨镜像确认系统 `/etc/ssl/certs` 与 `/system/etc/security/certificates` 的契约。
5. 补 HAP 冷/热启动、TLS 握手/吞吐和长时间常驻内存；首轮已有 HAP 19.8 MB、约 0.49 s 到托管入口、2 s VmRSS 121,628 kB 的数据。
6. 以上通过后，起草 upstream support proposal，把 OpenSSL-on-OHOS 定为 crypto provider 方案。
7. OH_Crypto 继续作为后续优化项，不作为官方支持 blocker。

## 9. 参考

- OpenSSL target 配置：<https://github.com/openssl/openssl/blob/master/Configurations/10-main.conf>
- OpenSSL 3.5 target 配置：<https://github.com/openssl/openssl/blob/openssl-3.5/Configurations/10-main.conf>
- OpenSSL 发布策略：<https://openssl-library.org/policies/releasestrat/>
- OpenHarmony OpenSSL fork：<https://github.com/openharmony/third_party_openssl>
- OpenHarmony `BUILD.gn`：<https://github.com/openharmony/third_party_openssl/blob/master/BUILD.gn>
- 社区 OpenSSL for OHOS：<https://github.com/ohos-rs/ohos-openssl>
- OHOS CryptoArchitectureKit 头文件：本地 SDK `native/sysroot/usr/include/CryptoArchitectureKit`
- 本地 SDK：`~/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_2`
- 本地 HAP：`/data/storage/el2/base/tmp/opencode/rc3-device/hello-maui-app-debug.hap`
