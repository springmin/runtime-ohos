# AOT pack 结构性修复：共享 .so / 静态 .a 的 OpenSSL 模式拆分（L-AOTPACK，2026-10-03）

> 承接 `2026-09-30-rc2-aotpack-openssl-shim-fix.md` §5 的结构性未决：`LinkStaticOpenSsl=true`
> 让共享 `.so` 静态链接 OpenSSL，同时把同一 CMake 对象库编出的 AOT 静态归档
> （`libSystem.Security.Cryptography.Native.OpenSsl.a`）也去掉了 dlopen shim。
> 本次按“拆分对象库”落地：一次构建同时产出正确的 `.so` 与 `.a`；sdk-ohos 构建脚本
> 在布局与 nupkg 两处新增 shim 校验（fetch 端校验保留）。执行 scratch `/data/storage/el2/base/tmp/opencode/l-aotpack/`。

## 1. 根因与修复点

触发链（sdk-ohos → runtime）：

```
build-ohos-all.sh  /p:LinkStaticOpenSsl=true
  → src/native/libs/build-native.proj  -linkstaticopenssl
    → build-native.sh  FEATURE_DISTRO_AGNOSTIC_SSL=0, CMAKE_STATIC_LIB_LINK=1
      → System.Security.Cryptography.Native/CMakeLists.txt
         单个 objlib 同时喂 SHARED 与 STATIC
```

修复（runtime-ohos，分支 `fix/aotpack-structural`）：

- `src/native/libs/build-native.sh`：新增 `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC`
  （默认 = `FEATURE_DISTRO_AGNOSTIC_SSL`）；`-linkstaticopenssl` 时置 1。
- `src/native/libs/System.Security.Cryptography.Native/CMakeLists.txt`：
  当 `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC=1` 且 `FEATURE_DISTRO_AGNOSTIC_SSL=0` 时，
  为静态归档单独建 `objlib_static`（`NATIVECRYPTO_SOURCES + opensslshim.c`，
  `target_compile_definitions(... FEATURE_DISTRO_AGNOSTIC_SSL)` + `-pthread`）；
  共享 `.so` 仍用 `objlib` + `libcrypto.a/libssl.a`（`--exclude-libs,ALL`）。
  其余平台/构建（portable、coreclr 内嵌 STATIC_LIBS_ONLY）行为不变。

sdk-ohos 守卫（分支 `fix/aotpack-structural`）：

- `build-ohos-all.sh` 新增 `verify_aot_crypto_shim`：`nm --defined-only | grep -cE
  'local_(EVP|SSL|X509)'` ≥5 否则 `die`。主构建后校验
  `artifacts/bin/native/*-openharmony-<Config>-<Arch>/…OpenSsl.a`（布局），
  NativeAOT sfxproj 后解包校验 `Microsoft.NETCore.App.Runtime.NativeAOT.<rid>.*.nupkg`
  内的同一归档（防止坏包出仓）。fetch 脚本的内容校验保留（纵深防御）。

## 2. 验证（scratch）

1. **构建图（mode0 / `-linkstaticopenssl`）**：`FEATURE_DISTRO_AGNOSTIC_SSL=0`、
   `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC=1`、`CMAKE_STATIC_LIB_LINK=1`；
   `objlib_static` 带 `-DFEATURE_DISTRO_AGNOSTIC_SSL`/`-pthread`，静态链接输入含
   `opensslshim.c.o` 且不依赖 `libcrypto.a/libssl.a`；共享链接显式依赖二者。
2. **产物判据**：静态 `.a` 1,571,956 B / 36 成员（含 `opensslshim.c.o`）/
   `local_(EVP|SSL|X509)` = 5 / 非 `_ptr` 未决 OpenSSL = 0；共享 `.so` NEEDED 仅
   `libc.so`（无 `libssl/libcrypto`）、动态未决 OpenSSL = 0、entrypoints 校验通过
   （构建 POST_BUILD）。
3. **与 `-r2` 修复归档逐符号对照**：36 成员与 1118 个 defined 符号名全同
   （仅尺寸差 3,376 B，来自路径/版本串）；即设备侧对 `-r2` 的 dlopen 证据可平移。
4. **portable（mode1）回归**：`FEATURE_DISTRO_AGNOSTIC_SSL=1` 时 build.ninja 无
   `objlib_static`，静态归档仍由 `objlib`（含 shim）构成——旧路径不变。
5. **cryptotest A/B**（feed 内替换归档，`~/.dotnet.rc2-fix`）：
   - struct 归档：`publish rc=0`；最终 ELF 动态未决 OpenSSL = 0、NEEDED 仅 `libc.so`；
     NuGet 缓存归档 sha = 新编归档 `bd66063e…`。
   - 坏归档（原 `46d221f2…` 包内容）：`publish rc=1`，
     `ld.lld: undefined symbol: ERR_clear_error / EVP_sha1 / X509_digest / X509_get0_notBefore …`。
6. **fetch 正/负用例**（当前 `feature/openharmony` 脚本）：
   - `--local` `-r2`：sha OK + `OpenSSL shim OK (5/5 …)`，rc=0；
   - 坏归档改名 `-r2` + 临时改锚匹配其 sha：`0/5` 拒绝、坏件从 dest 删除、rc=1。
7. **构建守卫自测**：struct 归档 → `AOT crypto shim OK (…, 5/5 …)` rc=0；
   坏归档 / 缺文件 → `die` rc=1（错误含修复指引）。

## 3. 提交 / 资产

- runtime-ohos：`fix/aotpack-structural` @ `c1c85422715`（CMake + build-native.sh + 本文 +
  RC2-AOTPACK §5 闭合指针）。
- sdk-ohos：`fix/aotpack-structural` @ `2721c4d3a0`（build-ohos-all.sh 守卫 + NATIVE-AOT.md 注记）。
- 未新发 nupkg 资产：rc.2 线已有 `-r2`（asset 601289590）；后续构建由上述修复
  直接产出带 shim 的静态归档，不再需要人工重打。证据日志在 scratch `l-aotpack/`
  （`configure-struct.log`、`ninja-struct*.log`、`cryptotest-{struct,bad}.log`、
  `fetch-{pos,neg}.log`、`struct-probe.so` 等）。

## 4. 未决 / 不确定

- **设备 dlopen 复跑受阻**：本机/设备对 `/data/local/tmp` 的任意 ELF exec 均
  `Permission denied`（已签名 `dlopen-smoke` 与既有 `wxprobe` 同样 rc=126），无法在
  本会话重放 RC2-AOTPACK §4.4 的 now/lazy 探针；以“新归档与 `-r2` 符号等同 +
  cryptotest 链接闭环”平移该项证据。
- AOT 静态归档仍是 shim 语义：运行时需要可 dlopen 的 `libssl/libcrypto`（与共享
  `.so` 的静态 OpenSSL 策略并存，属 AOT 侧固有部署要求，非本次回归）。
- 上游化：`LinkStaticOpenSsl` / `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 为 fork 构型；
  上游 mainline 无此开关，但“AOT 归档必须自带 shim”的拆分方式与上游兼容。
