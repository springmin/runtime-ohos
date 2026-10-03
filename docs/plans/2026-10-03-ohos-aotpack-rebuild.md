# AOT pack 结构修复后重出（AOTPACK-REBUILD，2026-10-03）

> 承接 L-AOTPACK（`2026-10-03-ohos-aotpack-structural.md`，runtime 修复并入 merge
> `796220a6787`）与 RC2-AOTPACK §5：用结构修复后的源重出 rc.2 线 AOT runtime pack，
> 消除 `-r2` 人工重打特例（新后缀 `-struct1`，避免与旧件/NuGet 缓存混淆）。
> 执行 scratch `/data/storage/el2/base/tmp/opencode/aotpack-rebuild/`。

## 1. 构建（走结构修复后的同一路径）

- 源：`feature/openharmony` @ `66e6f2d6cef`（含结构修复 `c1c85422715` +
  `796220a6787`）；`src/native/libs/build-native.sh` sha256 `e57fb6c6…`、
  `System.Security.Cryptography.Native/CMakeLists.txt` sha256 `7380d4a9…`。
- 独立 native libs 构建（与 pack 同源的 native 路径）：`build-native.sh … -linkstaticopenssl`
  → CMake cache `FEATURE_DISTRO_AGNOSTIC_SSL=0` / `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC=1` /
  `CMAKE_STATIC_LIB_LINK=1`；`ninja System.Security.Cryptography.Native.OpenSsl-Static
  System.Security.Cryptography.Native.OpenSsl` 一次产出静态归档与共享 `.so`（不再需要
  RC2-AOTPACK 的离群 `-DFEATURE_DISTRO_AGNOSTIC_SSL=1` 小构建）。
- 环境注记：本机 `LD_LIBRARY_PATH` 中 harmonybrew 的 `libxml2.so.16` 会遮蔽 NDK
  lld 所需版本（`xmlNewNs: symbol not found`）；链接时把 NDK `native/llvm/lib` 前置。
- 产物：静态归档 1,573,084 B / sha256
  `9b95c5096bf9628b8675ccb1b0f74ef391c5b3bc8f07560c1f4fa2929dba2c25`；共享 `.so`
  NEEDED 仅 `libc.so`、动态未决 OpenSSL=0、entrypoints 校验通过（构建 POST_BUILD）。

## 2. pack 重出

- 基线：原 rc.2 pack（`46d221f2…`）；仅替换
  `runtimes/openharmony-arm64/native/libSystem.Security.Cryptography.Native.OpenSsl.a`，
  其余 409 条目内容逐字节不变（重打脚本逐条比对）。
- 新资产：`Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.2.26451.112-struct1.nupkg`
  （28,905,116 B / sha256
  `09345f9515612f2b090fd0e0f54c815156105127cc1686240a3cad8521dab11c`）。

## 3. 验证

1. 归档判据（从新 nupkg 解出）：36 成员（含 `opensslshim.c.o`）、
   `local_(EVP|SSL|X509)` = 5/5、非 `local_` 且非 `_ptr` 的未决 OpenSSL = 0；
   定义符号 1118 个与 `-r2` 全同、undefined `*_ptr` 752。
2. cryptotest A/B（`~/.dotnet.rc2-fix`，feed 内换 pack，清 NuGet `.112` 缓存）：
   - `-struct1` feed：publish **rc=0**；最终 ELF 动态未决 OpenSSL=0、NEEDED 仅
     `libc.so`；缓存归档 5/5（sha `9b95c509…` == 新编归档）。
   - 坏归档 feed（原 `46d221f2…` pack）：publish **rc=1**，
     `ld.lld: undefined symbol: ERR_clear_error / X509_* …`。
3. fetch 正例（换锚后的 `fetch-nativeaot-packs.sh --local`）：`sha256 OK` +
   `OpenSSL shim OK (5/5 local_*(EVP|SSL|X509) symbols)`，rc=0。
4. AOT publish 冒烟（ohos-workload `test/hello-maui-app/publish-aot.sh`，rc.2 SDK +
   本地 `-struct1` feed）：EXIT=0、IL2026/IL3050/IL3051=0、
   `libhello-maui-app.so` 19,204,880 B / `86b11901…`、
   `hello-maui-app.hap` 22,308,737 B / `e44fdd6f…`、app 动态未决 OpenSSL=0。

## 4. 发布（release `springmin/sdk-ohos` tag `aot-packs-11.0.0-rc.2`）

- 新资产 asset id **607541145**：API digest + by-id（`assets/607541145`）下载均逐字节
  等于本地 `09345f95…`。
- `SHA256SUMS` 显式 clobber 为 4 件 nupkg（原包、`-r2`、`-struct1`、ILCompiler），
  下载复核一致；release notes 追加一行「结构修复后重出，不再需要 `-r2`」。
- sdk-ohos 换锚：`versions.env`（`-struct1` + sha pin）、`fetch-nativeaot-packs.sh`
  （资产名/注记/错误提示）、`NATIVE-AOT.md`（§4 资产表与 `-struct1` 说明）。

## 5. 文档与提交

- runtime-ohos：本文 + `docs/plans/README.md` 索引行。
- sdk-ohos：`feat/aotpack-rebuild`（cherry-pick 构建守卫 `2721c4d3a0` + 上述换锚/文档）。

## 6. 不确定项

- 未重跑 sdk-ohos 全量 `build-ohos-all.sh`（时间/内存纪律；以“同路径小构建 + 构建
  守卫自测”平移 RC2-AOTPACK 的归档修复证据）。下一次全量构建起 AOT runtime pack 由
  结构修复直接产出；`verify_aot_crypto_shim` 在缺 shim 时直接 fail（本次 grep 守卫
  函数逻辑已含布局 + nupkg 两处校验）。
- `-struct1` 与原包同 id+版本（`11.0.0-rc.2.26451.112`）；已有坏 `.112` NuGet 缓存的
  环境仍需按 `NATIVE-AOT.md` 清缓存。
- 设备 dlopen 重跑仍受设备 exec 限制（L-AOTPACK §4 未决），本次以“与 `-r2` 逐符号
  等同 + cryptotest 链接/加载闭环 + MAUI publish 冒烟”平移。
