# rc.2 AOT pack OpenSSL shim 修复（RC2-AOTPACK，2026-09-30）

> 修复 W10 记录的上游缺陷：`aot-packs-11.0.0-rc.2` 镜像里的
> `Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64` 静态
> `libSystem.Security.Cryptography.Native.OpenSsl.a` 无 dlopen shim，NativeAOT
> 一旦用到 crypto 即链接/`dlopen` 失败。修正版资产 `...-r2.nupkg` 已发布并
> 重锚 fetch 脚本；执行 scratch `/data/storage/el2/base/tmp/opencode/rc2-aotpack/`。

## 1. 最小复现（W10 判据）

```sh
A=~/.nuget/packages/microsoft.netcore.app.runtime.nativeaot.openharmony-arm64
nm --defined-only $A/11.0.0-rc.1.26451.109/runtimes/openharmony-arm64/native/libSystem.Security.Cryptography.Native.OpenSsl.a \
  | grep -cE 'local_(EVP|SSL|X509)'   # rc.1 = 5
nm --defined-only $A/11.0.0-rc.2.26451.112/runtimes/openharmony-arm64/native/libSystem.Security.Cryptography.Native.OpenSsl.a \
  | grep -cE 'local_(EVP|SSL|X509)'   # rc.2 = 0（缺陷）
```

归档面：rc.1 = 36 成员（含 `opensslshim.c.o`，591 `*_ptr` 定义），rc.2 = 35 成员，
raw undefined OpenSSL API 符号 rc.1 = 0 / rc.2 = 495（`EVP_*`/`X509_*`/`ERR_*` …），
rc.2 的 `openssl.c.o`/`pal_*.o` 全部直连 OpenSSL 符号。rc.2 nupkg = 镜像资产
`46d221f2…`（28,166,644 B），即 W10 钉 rc.1 所规避的那份。

## 2. 根因

sdk-ohos `d97ec984e7`（2026-09-27，TLS 加固后续）在
`eng/ohos-install/build/build-ohos-all.sh` 的全量构建上加
`/p:LinkStaticOpenSsl=true`，让共享 crypto shim 静态链接 OpenSSL。
该开关经 `src/native/libs/build-native.sh` 把 `FEATURE_DISTRO_AGNOSTIC_SSL`
置 0，**同时**作用于同一 cmake 构建产出的 NativeAOT runtime pack 静态归档：
`pal_*.o` 改为直连 `EVP_*`，`opensslshim.c.o` 不再进入归档。

- 共享 `.so`（coreclr/JIT 线）：静态链接 OpenSSL，自洽；
- NativeAOT：ilc 链接命令直接把 `libSystem.Security.Cryptography.Native.OpenSsl.a`
  链进 app（未见 `libssl.a`/`libcrypto.a`），于是任何走 crypto 的 AOT app
  留下未决 `EVP_*`/`X509_*`（rc.2 映像 ~401 处）→ 设备 dlopen 拒绝。
- rc.1（9 月 11 日构建，早于该开关）仍是 shim 版，所以设备端 AOT 一直可用。

修复路径选择“重建 shim 归档 + 重打 pack”，而不是往 app 链静态 OpenSSL：
后者要动 ILCompiler 链接输入（每 app 多带 ~10 MB 且偏离 TLS 策略）。

## 3. 修复（重建 + 重打 + 引脚）

源码基线：`runtime-ohos-rc2` 检出 `417ab220532`（`d4a4e25c89f` + CoreLib 别名，
`src/native/libs` 与 `d4a4e25c89f` 零 diff）= rc.2 pack 的构建源。

```sh
# 一次小构建：仅配置 + 只编 crypto 静态库（FEATURE_DISTRO_AGNOSTIC_SSL=1）
OHOS_NDK_HOME=$HOME/.harmonybrew/opt/ohos-sdk \
LD_LIBRARY_PATH=/data/storage/el2/base/tmp/opencode/r2-interp/libs \
src/native/libs/build-native.sh arm64 Release -os openharmony -arch arm64 \
  -outconfig net11.0-openharmony-Release-arm64 -configureonly -numproc 4 \
  -cmakeargs "… -DOPENSSL_ROOT_DIR=<openssl-3.3.1> … \
    -DFEATURE_DISTRO_AGNOSTIC_SSL=1 -DCMAKE_STATIC_LIB_LINK=0"
ninja -C artifacts/obj/native/net11.0-openharmony-Release-arm64 -j4 \
  System.Security.Cryptography.Native.OpenSsl-Static
# 产物：…/System.Security.Cryptography.Native/libSystem.Security.Cryptography.Native.OpenSsl.a
#       36 成员 / 5 local_* / raw undefined OpenSSL = 0（与 rc.1 同构）
```

重打：解 rc.2 nupkg，仅替换 `runtimes/openharmony-arm64/native/libSystem.Security.Cryptography.Native.OpenSsl.a`，
其余 409 条目原字节保留（id/版本不变，仍 `11.0.0-rc.2.26451.112`）。

- 新资产：`Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.2.26451.112-r2.nupkg`
  （28,904,657 B / `542058cf953a3e9c1a42cbf287c5df1177bc5c9f4de70957ca384d472570e4a2`，
  release `aot-packs-11.0.0-rc.2` asset id `601289590`；原 `46d221f2…` 保留为历史记录）。
- sdk-ohos 提交 **`48c8b210dc`**（分支 `fix/rc2-aotpack-openssl-shim`，基于
  `origin/feature/openharmony`）：`versions.env` 换锚到 `-r2`/`542058cf…`；
  `fetch-nativeaot-packs.sh` 资产名换 `-r2` 并新增 **shim 内容校验**
  （unzip 出归档，`nm --defined-only … | grep -cE 'local_(EVP|SSL|X509)'` ≥5，
  否则拒绝入 feed，校验失败的文件会被删除；无 nm/unzip 时降级为警告）；
  `NATIVE-AOT.md` 记录 `-r2` 与 NuGet 缓存注意项；`build-ohos-all.sh`
  在 `LinkStaticOpenSsl=true` 处加后果注释（见 §5）。

## 4. 验证

1. **归档判据**：新 nupkg 内 `.a` = 36 成员 / 5 `local_*(EVP|SSL|X509)`（0→5）/
   raw undefined OpenSSL = 0 / `*_ptr` 定义 589。fetch 脚本 `--local` 实测
   输出 `OpenSSL shim OK (5/5 …)`；负测试（把坏归档改名成 `-r2` 且临时改锚匹配其
   sha）被内容校验拒绝并删除。
2. **AOT 链接 A/B**（scratch `cryptotest`，`X509Certificate2.CreateFromPem`，
   `~/.dotnet.rc2-fix` + 本地 feed）：
   - 坏 pack：`ld.lld: error: undefined symbol: ERR_clear_error / EVP_sha1 /
     X509_digest / X509_get0_notBefore …`（link rc=1）；
   - `-r2` pack：publish **rc=0**，链接命令含该 `.a`，最终 ELF 0 个未决
     OpenSSL dynsym。
3. **MAUI AOT publish**：`hello-maui-app`（maui-ohos `eec30c01cd` 切片 + rc.2
   SDK）用 `-r2` feed publish rc=0，出已签名 HAP 21,696,601 B /
   `d8466a0e117c7f0aba7da7e415b9685764c153ec607ba8d5bdeb26de0053c558`，
   `libhello-maui-app.so` 18,696,976 B（注意该 MAUI 映像不拉 crypto，故其
   0 未决不算本修复证据，crypto 证据取 §4.2）。
4. **本机真机 dlopen**（同 W10 口径，probe 由两个归档各链一个 `.so`）：
   - 坏归档 probe：`now = ERR: Error relocating … ERR_clear_error: symbol not found`、
     `lazy = ERR`；
   - 修复归档 probe：`now = OK`、`lazy = OK`。
5. 环境收尾：`~/.nuget/packages/…rc.2.26451.112` 已换成 `-r2` 内容（shim 5/5）。

## 5. 未决 / 建议

- **结构性修复**（sdk-ohos/上游线）：一次 `build-native.sh` 同时产出静态 `.a`
  与共享 `.so`，二者对 `FEATURE_DISTRO_AGNOSTIC_SSL` 的需求相反。彻底解法是
  拆分对象库（共享走静态 OpenSSL、静态 `.a` 走 shim）或在 pack 阶段用 shim 版
  重编归档后再 `packs`；当前以 fetch 端内容校验兜底，`build-ohos-all.sh` 已注记。
  本次为 **fork 构型缺陷**，上游 mainline 不设 `LinkStaticOpenSsl`；
  但“AOT pack 静态归档必须自带 shim（或把静态 OpenSSL 归档纳入 ilc 链接输入）”
  对上游同样成立。
  > **2026-10-03 闭合（L-AOTPACK）**：已按“拆分对象库”落地——
  > `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 让静态归档始终带 shim，共享 `.so`
  > 仍静态链 OpenSSL；`build-ohos-all.sh` 在布局与 nupkg 两处加 shim 校验。
  > 见 `docs/plans/2026-10-03-ohos-aotpack-structural.md`。
- **NuGet 缓存**：修正资产复用 `.112` 版本号，已恢复过坏包的环境需删
  `~/.nuget/packages/microsoft.netcore.app.runtime.nativeaot.openharmony-arm64/11.0.0-rc.2.26451.112`
  再 publish（文档已写明）；本机已处理。
- 设备 HAP 域的“crypto-using AOT app 安装启动”未跑（用 CLI 域 dlopen 探针
  闭环）；W10 的本机 hooks 钉 rc.1 可撤（改用 `-r2` feed 即可）。
