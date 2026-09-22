# OHOS ELF 代码签名研究：app 内 `.so` 的签名凭据是谁（PE1）

> 2026-09-22，PE1 研究记录。范围：回答「`libopenharmonyhost.so` 的 keyless self-sign（`.codesign`，
> flags=0x10）是否会被设备以“未用 app 签名证书签名”为由拒绝」。结论先说，证据分级：**A = 官方文档 /
> 上游源码实测**；**B = 上游源码推断**；**C = 社区/二手来源**；**U = 不确定**。

## 结论摘要

1. **强制校验存在**（A/B）：HarmonyOS/OpenHarmony 对应用加载的可执行代码有强制代码签名
   （XPM + fs-verity），普通应用进程的 `mmap(PROT_EXEC)`/`dlopen` 要求目标文件是已使能的 fs-verity
   文件或位于 dm-verity 分区；否则拒绝（`E_HM_PERM`）。
2. **app 内 `.so` 的签名凭据是 HAP 的 code signing block，而不是 `.so` 自带的 `.codesign`**（A）：
   `hap-sign-tool sign-app`（`-signCode` 默认 1）在 HAP 签名块里写入 `SoInfoSegment`，为每个
   `libs/**` / `*.an` 条目生成「该文件 fs-verity digest 的 PKCS7 + ownerID（appIdentifier/debug）」，
   安装时由 `EnforceCodeSignForApp*` 用它使能 fs-verity。签名用的是 app 签名证书/Profile，与
   `.so` 文件内是否有 `.codesign` 无关。
3. **keyless self-sign 是“独立二进制”机制**（A）：`binary-sign-tool sign -selfSign 1` / lld
   `--code-sign` 写 v3 `.codesign`（flags=0x10，signature = SHA-256(descriptor)）。我们的
   `ElfSigner` 端口与上游该格式**字段级一致**（实测：SDK `binary-sign-tool` 对本机 `host.so` 输出
   `code signature is self-sign`）。开放源码里 `dlopen` 路径**不读**这个 `.codesign`（只在 exec 独立
   二进制时由 `elf_file_enable_fs_verity` 读 v1 sign-head）；它**不是** app 内 `.so` 的凭证。
4. **因此 PE1 假设需要修正**（B/U）：`host` 加载失败的签名类原因不是“self-sign 不够格”，而是
   **host.so 是否被 HAP 代码签名覆盖并在安装时使能 fs-verity**。测试方默认 `hap-sign-tool sign-app`
   （不带 `-signCode 0`）就会覆盖；若其重签流程关闭/绕过了 code signing，或用旧工具（无 native-lib
   代码签名），libs 不受保护 → XPM 拒绝 dlopen。**决定性判据是设备 kmsg 里的 `xpm` 事件**（§6）。
5. **新发现 1（必然阻塞下一步）**（A/B）：`resources/rawfile/dotnet.zip` 里解压出来的 .NET runtime
   `.so`（`libhostfxr.so`/`libcoreclr.so` …）**不在** HAP 的 `libs/` 里，不受 HAP 代码签名覆盖；在被
   强制的 app 进程里 `dlopen` 它们会被 XPM 拒绝。修复方向：把这些 native 库放进 `libs/<abi>/`
   （或按 HNP 机制声明），让 hap 签名覆盖它们（§7）。
6. **新发现 2（签名降级）**（A）：SDK 随包的 `libc++_shared.so` 是 **Huawei CBG DevID PKCS7 证书
   签名**（`.codesign`，flags=0）；我们的打包流程把它**重签成 keyless**（`OpenHarmonyCodesign` 的
   `IsValidlySigned` 只承认 `signSize==32` 的自签，把证书签名判为“无效”后 strip+self-sign）。这是
   签名强度降级；应用内由 hap 块覆盖，风险主要在“离开 app 安装使能路径”的场景（§5.3）。
7. **修复路径排序**：①测试方按 `-signCode 1`（显式）重签 + 我们把 payload native 库挪进 hap libs
   （或 HNP）；②对方把签名材料交我方预签（同一限制）；③要求设备接受 self-sign —— 对 app 内 `.so`
   **没有证据支持**，排最后（§7）。

---

## 1. 机制总览（上游源码）

### 1.1 安装期：HAP → 每 lib 一个签名 → 内核 fs-verity

- HAP 签名（`hap-sign-tool sign-app`，`-signCode` 默认 1；见 §3）在 zip 的 central directory 前插入
  HapSigningBlock，其中的 `CodeSignBlock` 含 `SoInfoSegment`（datastructure:
  `NativeLibInfoSegment.java`）：每个 native 条目一个「文件名 + `SignInfo`」。`SignInfo` 是
  **该文件 fs-verity digest 的 PKCS7 签名**，PKCS7 里带 `ownerID`（OID
  `1.3.6.1.4.1.2011.2.376.1.4.1`）。
- 签名对象：`CodeSigning.signNativeLibs()`（Java）对 `libs/**` 与 `*.an` 逐个 `signFile(...)`；
  另有 `signNativeHnps()` 对 `hnp/**.hnp` 内 ELF 签名（public/private owner 规则不同）。
- 安装：BMS 调用 `EnforceCodeSignForApp*`（`security_code_signature` 部件）；`EnforceCodeSignForAppWithOwnerId`
  在 profile 为 **debug** 时把 ownerId 置为 `OWNERID_DEBUG_TAG`，否则用 `appIdentifier`；
  `CodeSignHelper` 从 hap 签名块取「条目 + 签名」，对每个已落盘文件执行
  `EnableCodeSignForFile`（`FS_IOC_ENABLE_CODE_SIGN`，`arg.cs_version` 非 0 时走代码签名版）。
- 内核：`code_sign_init_descriptor()` 把 flags/cs_version/data_size/root_hash 写进 descriptor；
  之后 `fsverity_verify_signature()` 用 `.fs-verity` keyring 校验 PKCS7（`require_signatures=1` 时
  未签名文件直接在 open/enable 失败）。设备的 keyring 由 `key_enable` 服务初始化；debug 应用的
  开发者证书通过 `EnableKeyInProfile` 进入信任列表。

### 1.2 运行期：XPM 执行权限检查

- `xpm/core/xpm_security_hooks.c`：`mmap_region` / `file_mprotect` 上检查
  `PROT_EXEC` 或 XPM 区域；`check_exec_file_is_verity()` 判定：
  - inode 已有 fs-verity → `FILE_SIGNATURE_FS_VERITY`；
  - 文件在 dm-verity 分区（`/system` 等）→ `FILE_SIGNATURE_DM_VERITY`；
  - `is_exec && elf_file_enable_fs_verity(file)`（v1 sign-head 路径：**仅 exec 独立 ELF**，
    且要求 **developer mode ON** + 证书链类型通过；不覆盖 dlopen）；
  - 否则 `FILE_SIGNATURE_INVALID` → 拒绝。
- owner-ID 策略（`ownerid_policy` 矩阵，源码级，默认 `DENY`）：
  - `APP × APP = CHECK`（必须同 owner），`APP × SYSTEM/SHARED = ALLOW`；
  - `DEBUG × DEBUG/SYSTEM/SHARED = ALLOW`；
  - 其它组合（例如 `APP × DEBUG`、`DEBUG × APP`）**未列出 = DENY**。
- `XPM README`：普通应用类「强制检查二进制可执行文件和 abc 字节码的合法代码签名」；调测类不强制
  （进程 SELinux 标签决定类别；debug 签名不等于“调测类进程”，但这是需要设备实测确认的点，§8）。

### 1.3 两种“文件内 `.codesign`”格式

| 格式 | 产生工具 | 结构 | 设备端消费点 |
|---|---|---|---|
| v1 sign-head（文件尾 `SIGN` 头 + 块） | `hap-sign-tool sign-app -inForm elf`（证书） | 尾部块（`CODE_SIGNING` + `PROFILE`），无 `.codesign` 段 | `elf_file_enable_fs_verity()`（**exec**，需 developer mode） |
| v3 `.codesign`（4 KB 段） | `binary-sign-tool sign`（证书）或 `-selfSign 1`；lld `--code-sign`；我们的 `ElfSigner` | `ElfSignInfo`：type=1, length=288, descriptor 256 B, signature（PKCS7 或 32 B 摘要）；self-sign 时 `flags=0x10`, `csVersion=3` | 用户态 `EnforceCodeSignForFile(path)`（v1 失败后回退到 v3）→ 内核 ioctl；**不用于 app libs 的安装期使能** |

---

## 2. Q1：是否强制、是否必须绑定 app 证书

**A（强制）**：`security_code_signature` README 明确「供应用安装的时候调用，为应用和代码文件使能
代码签名」「代码所有者标记及校验」；`xpm/README_zh.md`「普通应用类：强制检查二进制可执行文件和
abc 字节码的合法代码签名」；`fs.verity.require_signatures=1` 由 `key_enable` 在
`post-fs-data` 写入（`services/key_enable/cfg/enable_xpm/*/key_enable.cfg`）。

**A（app 内 .so 的凭证是 hap 块）**：见 §1.1（`CodeSigning.signNativeLibs` / `SoInfoSegment` /
`EnforceCodeSignForAppWithOwnerId`）。`binary-sign-tool` 的官方定位是「对二进制文件进行代码签名」
（OpenHarmony PC/2in1 的独立 ELF）；华为文档与 OpenHarmony 文档都只描述它对 ELF 文件本身签
`.codesign`，不描述它替代 HAP 签名。

**A（self-sign 不是 app 路径的凭证）**：开放内核/XPM 的 dlopen 判定只认「已使能 fs-verity / dm-verity」；
安装期使能只使用 hap 块里的签名。`.so` 内的 self-sign `.codesign` 在该路径里是**惰性数据**。
self-sign 被 SDK 工具（`display-sign` 输出 `code signature is self-sign`）与上游 `verify_elf.cpp`
（`(flags & 0x10) != 0 → 直接判过`）承认，但这是**工具/独立二进制**语义；`FLAG_SELF_SIGN` 在开放
内核源码中**没有**任何处理点——设备是否放行由 HarmonyOS 侧策略（HKES/HCK）决定（**U**）。

**C（社区实测）**：鸿蒙 PC HiShell 下 self-sign 的独立二进制/`.so` 可以运行（`binary-sign-tool
-selfSign 1`、lld `--code-sign`），失败时 kmsg 会打 `xpm ... unsigned file`。这支持“self-sign 对
PC 独立程序有效”，不等价于“app 内 dlopen 有效”。

**结论**：app 内 `.so` 的签名必须绑定 app 签名材料——但绑定发生在 **HAP 签名块**层，不是文件内
`.codesign` 层。把 host.so 换成 keyless self-sign **不会**使它获得 app 绑定；反过来，只要 HAP 带
code signing block，host.so 带什么 `.codesign`（甚至没有）都不影响安装期使能（**B**，需 §6 实测确认）。

### 2.1 版本强制性

- 华为 hapsigner 指导（C/B）：`-signCode` 默认对 hap/hsp/hqf/elf 开启。
- 社区文章引「从 HarmonyOS 5.0.2 Beta1 起必须开启代码签名，否则包无法安装」（**C**）。
- BMS 错误码 `17700048`「代码签名校验失败：安装应用时，安装包的代码签名文件校验失败」（**C**，镜像站）。

---

## 3. 工具全景（含本机实测输出）

本机 SDK：`/storage/Users/currentUser/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_2`（arm64 原生工具，
可直接运行）。所有帮助输出为实测（read-only）。

### 3.1 `hap-sign-tool`

- 子命令：`generate-keypair / generate-csr / generate-cert / generate-ca / generate-app-cert /
  generate-profile-cert / sign-profile / verify-profile / sign-app / verify-app`。
  **没有**独立 `sign-code`；代码签名是 `sign-app` 的一部分（`-signCode`）。
- `sign-app` 关键参数（本机 help 原文）：
  - `-mode localSign|remoteSign|remoteResign`
  - `-inForm zip|elf|bin`（hap=zip，独立 ELF=elf）
  - `-signCode`：`Whether the HAP file is signed code, The value 1 means enable sign code, and value 0
    means disable sign code. The default value is 1. It is optional.`
  - `-profileSigned`、`-appCertFile`、`-profileFile`、`-keystoreFile/-keyPwd/-keystorePwd`
- 实测（SDK 自带 OpenHarmony 测试材料 + 本 kit 的未签名 hap）：
  - 默认（不写 `-signCode`）→ 产物出现 `SoInfoSegment` magic `0x0ED2E720`，2 个 lib 条目，
    `sig_size≈2248`（PKCS7）。
  - `-signCode 0` → 无 magic（无每 lib 签名）。
- `sign-app -inForm elf` 实测：产物**没有** `.codesign` 段（尾部 sign-head 格式），
  `binary-sign-tool display-sign` 对它输出 `code signature is not found`（格式不同）。

**开发者的 app 内 .so 不需要单独用本工具签**：用带 `-signCode 1` 的 `sign-app` 签 HAP 即可。

### 3.2 `binary-sign-tool`

本机 help：`USAGE: <sign|display-sign>`。
- `sign`：证书签名（`-keyAlias/-keyPwd/-appCertFile/-profileFile/-keystoreFile/-keystorePwd/
  -signAlg SHA256withECDSA|SHA384withECDSA/-moduleFile`）或 `-selfSign 1`（无 key/cert）。
- `display-sign`：打印权限（`permission is not found`）与签名类别（`code signature is not found` /
  `code signature is self-sign` / 证书链）。

实测对比（同一输入 ELF）：

| 产物 | 命令要点 | 大小 | `.codesign` | `display-sign` |
|---|---|---|---|---|
| keyless self-sign（我们的 ElfSigner，hap 内 host） | — | 191,392 B | @0x2d000, 0x1000 | `code signature is self-sign` |
| SDK `binary-sign-tool sign -selfSign 1` | 同输入 stripped | 182,784 B | @0x2b000, 0x1000 | `code signature is self-sign` |
| SDK `binary-sign-tool sign`（证书） | OpenHarmonyApplication.pem | 186,944 B | 有 | 输出 certificate #0 链 |
| SDK `hap-sign-tool sign-app -inForm elf`（证书） | 同上材料 | 194,274 B | **无** | `code signature is not found` |

对“我们的 ElfSigner 是否等价于上游 self-sign”的实测：两者 descriptor 字段完全一致
（type=1, length=288, version=1, hash=1, log2BlockSize=12, saltSize=0, signSize=32, fileSize=len(file),
`flags=0x10`, `csVersion=3`），且 `SHA-256(descriptor with signSize=0) == signature`。
**差异只在布局**：上游把 `.codesign` 追加到原 section-header table 之后（保留原 shstrtab/SHT 位置），
我们的端口把 shstrtab+SHT 移到 `.codesign` 页之后（host.so 大 8,608 B；`libc++_shared.so` 大 4,344 B）。
两者都能被 `display-sign`/`ElfCodeSignBlock::ParseSignBlock` 解析（B）。

### 3.3 我们的 selfsign 管线

- `ohos-workload/scripts/selfsign.sh` → `selfsign` CLI（`sdk-ohos/eng/ohos-install/selfsign.cs`）→
  `ElfSigner.cs`（`sdk-ohos/src/Tasks/Microsoft.NET.Build.Tasks/ElfSigner.cs`）：4 KB `.codesign`，
  flags=0x10，`csVersion=3`，signature=SHA-256(descriptor)。
- `packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/targets/OpenHarmony.Hap.targets` 对
  `libs/` 下的每个 ELF 执行 `OpenHarmonyCodesign`；其注释明确写「SDK 的 libc++_shared.so 带 PKCS#7
  Huawei DevID blob（flags=0），不是 ElfSigner 格式 → 重签」。实际上 `IsValidlySigned()` 只承认
  `signSize==32` 的自签，因此**任何证书签名的 `.codesign` 都会被判无效并替换**（A，代码级）。
- 实测：SDK 原 `libc++_shared.so` = DevID 证书签名（issuer `Huawei CBG Developer Relations CA G2`，
  subject `开放原子开源基金会…DevID`），1,267,392 B；kit 内同文件被重签为 self-sign，1,271,736 B。

---

## 4. Q3：DevEco 对普通 app 做了什么

- DevEco 的 `Signing Configs`（p12/cer/p7b）→ hvigor 构建签名步骤调用同一套 hapsigner
  （`hap-sign-tool`）用 `sign-app` 签 HAP；`-signCode` 无 UI 开关、默认 1（A/B，官方签名指导 +
  hapsigner 源码）。因此**正常 app 的 `.so` 会被“用开发者证书签”，但形式是 hap 块里的
  `SoInfoSegment`，不是给 `.so` 注入 `.codesign`**。
- 推断/可验证：DevEco 构建的工程 `.so` 默认没有 `.codesign` 段（lld 的 `--code-sign` 不是默认
  参数）；若 cc-switch 的 libs 在设备上 `display-sign` 输出 `code signature is not found` 且 app
  正常运行，就直接证明「app 内 lib 不依赖文件内签名」。
- 我们的缺口：kit 里的 `hello-maui-app-unsigned.hap` 没有签名块；测试方重签时若沿用默认即补上
  （实测：SDK 工具对同一未签名 hap 默认重签 → 2 个 lib 的 `SoInfoSegment`）。若他们的流程
  `-signCode 0`/旧工具/只签 zip 不解 native lib，则缺口成立。

---

## 5. PE1 假设的核对

### 5.1 「host 是 keyless self-sign 所以被拒」——不成立（作为主因）

app 内 `.so` 的安装期使能不用文件内 `.codesign`（§1.1/§2）。只要 HAP 带 code signing block，
host.so 的 `.codesign` 是什么都不影响安装期使能；若 HAP 不带，则 keyless self-sign 也救不了
dlopen（安装期使能路径不会读它）。所以**判据是 HAP 是否被 code-signed**，而不是 host 的签名类型。
（**U**：HarmonyOS 闭源内核/策略是否额外读取/偏好 app lib 的文件内 `.codesign`，开放源码无法证实。）

### 5.2 直接否决/支持该假设的设备检查

见 §6 的 kmsg 事件：若 host 的 dlopen 被签名拒绝，会出现
`[xpm:...] <path> is not protected by dmverity` → `xpm get signature info failed` →
`{"event_type":"unsigned file", ... "filename": ".../libopenharmonyhost.so" ...}` →
`[fs_security_verity:...] lib_no_signed event waken: -9(E_HM_PERM)`。
若启动日志里**没有**针对 host.so 的这类事件，签名假设即被否定，应回到 NAPI/依赖/加载路径排查。

### 5.3 两个真问题（本次研究新增，优先于“文件内签名格式”）

1. **payload native 库不在 hap libs**：`resources/rawfile/dotnet.zip`（22.5 MB）里的
   `libhostfxr.so/libcoreclr.so/...` 解压到 app 数据目录，不受 hap 代码签名覆盖；被强制的 app
   进程里 `dlopen` 会 EPERM。这不解释“host undefined”（host 在 libs/），但会阻塞 host 之后的
   .NET 启动，必须与签名问题一起解决（§7）。
2. **libc++_shared.so 的证书签名被我们替换成 keyless**（§3.3）：把厂商 DevID 签名降级为 self-sign，
   在“非 app 安装使能”的加载路径上风险更高；且 `OpenHarmonyCodesign` 的“有效性”判定只认自签，
   会把合法的证书签名重签。建议先做 A/B（保留 DevID vs 自签）或至少取消对 SDK 厂商库的重签。

---

## 6. Q4：测试方可执行的检查（精确命令）

> 前提：`hdc` 可用；部分路径读取需要 root。所有“期望”都给出判读规则。

### 6.1 决定性：内核验签日志（在复现启动/`host` undefined 的同一时刻采集）

```sh
hdc shell "hilog -t kmsg" > kmsg.log
grep -iE "xpm|unsigned file|fs_security_verity|xpm get signature|libopenharmonyhost|hellomauiapp" kmsg.log
```

判读：
- 出现 `<path> is not protected by dmverity`、`xpm get signature info failed, etype: 1`、
  `{"event_type": "unsigned file", ... "filename": "...libopenharmonyhost.so"...}`、
  `lib_no_signed event waken: -9(E_HM_PERM)` → **签名拒绝成立**，记录被拒的完整路径。
- 无上述事件 → 签名假设被否定（回到加载/依赖/NAPI 排查）。

### 6.2 设备的强制级别（只读）

```sh
hdc shell "cat /proc/sys/kernel/xpm/xpm_mode"              # 0=关闭；1..5=各级 XPM
hdc shell "cat /proc/sys/fs/verity/require_signatures"     # 1=所有 fs-verity 文件必须带签名
```

### 6.3 重签后的 HAP 是否含 native-lib 代码签名（在测试方 PC 上）

```sh
# 期望 >=1；0 = 这次 sign-app 没有 code signing（-signCode 0 / 旧工具），libs 不受保护
python3 -c 'import re,sys; d=open(sys.argv[1],"rb").read();
print("SoInfoSegment magic hits:", len(re.findall(bytes.fromhex("20e7d20e"), d)))' \
  hello-maui-app-yourself.hap
```

```sh
# 取出 host.so 自身，确认它带的签名类别（对照用）
unzip -p hello-maui-app-yourself.hap libs/arm64-v8a/libopenharmonyhost.so > host.so
llvm-readelf -S host.so | grep -i codesign
binary-sign-tool display-sign -inFile host.so     # 期望：code signature is self-sign（我方预置）
```

### 6.4 对照“能跑的 app”（cc-switch）

```sh
# 任取一个 cc-switch 的 libs/*.so（来自其已安装 hap/目录），看它是否带文件内签名
binary-sign-tool display-sign -inFile <cc-switch-lib.so>
# 若输出 "code signature is not found" 而 app 可运行 => app 内 lib 不依赖文件内签名（§4 成立）
```

### 6.5 安装目录与文件状态（可选，best-effort）

```sh
hdc shell "find /data/app/el1/bundle/public/com.example.hellomauiapp -name 'libopenharmonyhost.so' 2>/dev/null"
hdc shell "ls -lZ <上一步路径>"      # SELinux 标签；如需 fs-verity 位可试 lsattr（可能不可用）
```

### 6.6 回传清单（最小集）

1. `kmsg.log` 过滤输出（6.1）+ 复现时间点；
2. `xpm_mode` / `require_signatures`（6.2）；
3. 重签 hap 的 SoInfoSegment 计数（6.3）；
4. cc-switch 一个 lib 的 `display-sign` 输出（6.4）；
5. 重签命令原文（是否带 `-signCode`）。

---

## 7. Q5：修复路径（按证据强度排序）

**①（首选）测试方显式 `-signCode 1` 重签 + 我们把 payload native 库放进 hap 覆盖范围。**
- 重签命令（在 `自签说明.md` 的命令上补 `-signCode 1`，并改用已签名变体要求）：
  ```sh
  hap-sign-tool sign-app -keyAlias debugKey -signAlg SHA256withECDSA -mode localSign \
    -appCertFile <你的>.cer -profileFile <你的>.p7b \
    -inFile hello-maui-app-unsigned.hap -outFile hello-maui-app-yourself.hap \
    -keystoreFile <你的>.p12 -keyPwd "<key密码>" -keystorePwd "<store密码>" -signCode 1
  ```
  然后用 6.3 确认 `SoInfoSegment` 出现（实测：本机 SDK 工具默认即如此，2 个 lib）。
- payload 修复（我方工作量）：把 .NET runtime 的 native 库（`libhostfxr.so`/`libcoreclr.so`/
  `libSystem.Native.so` …）以 `libs/<abi>/` 形式随 hap 交付（hap 会因此变大；或走 HNP：
  `hnp/**.hnp` + `module.json.hnpPackages`，hapsigner 对 HNP 内 ELF 同样签名、owner 规则区分
  public/private）。解压到数据目录的纯 `.codesign` self-sign 方案不可依赖。

**②（并行/保守）由我方用发布方/测试方密钥预签。**
- 测试方把签名材料（或 DevEco `material/` 目录）交我方，用 `ohos-workload/scripts/sign-huawei.sh`
  一条命令产出完整 code-signed hap。适合“重签步骤不可控”的交付；与 ① 一样不能覆盖 payload 库，
  除非先做 payload 修复。

**③（不推荐）要求设备接受 SDK self-sign。**
- app 内 `.so` 的凭证不是文件内 `.codesign`（§2），self-sign 也没有 app 绑定；开放源码中 app
  dlopen 路径不接受文件内 `.codesign`。只有在 6.1 明确显示 self-sign 被接受、失败在别处时才有意义。
- 独立二进制/HiShell 场景（非 app）self-sign 是有效且常用的（C）。

补充（低风险清理项，建议随 ① 一起做）：不要让 `OpenHarmonyCodesign` 重签 SDK 厂商库
（`libc++_shared.so` 保留 DevID 证书签名）；把 `IsValidlySigned` 的“只认 32 字节自签”改成“格式
合法即视为已签名（含证书签名）”，避免把强签名降级。是否影响设备加载需 A/B 实测（U）。

---

## 8. 不确定性与待证

- **U1**：HarmonyOS 闭源内核/HKES 是否对 `FLAG_SELF_SIGN`（0x10）有策略白名单；开放源码里
  `fsverity_verify_signature` 只做 PKCS7 + `.fs-verity` keyring 校验，`verify_elf.cpp` 的 self-sign
  跳过只是**工具侧**行为。
- **U2**：debug 签名应用是否仍按“普通应用类”强制 XPM 校验，还是落“调测类”不强制；需 6.1/6.2 实测。
- **U3**：安装期是否为 `libs/`（stage 模型可能是 bind mount/只读挂载）逐文件使能 fs-verity；源码
  路径（`ENABLE_APP_BASE_PATH=/data/app/el1/bundle`）显示会，但 HarmonyOS 具体实现未验证。
- **U4**：测试方 hap-sign-tool 版本与默认 `signCode`；6.3 可判。
- **U5**：我们 ElfSigner 的非上游布局（SHT 后移）是否被设备接受；`display-sign` 与用户态解析器
  接受，但内核/策略未实测。

## 9. 引用

官方/上游（A/B 级）：

- OpenHarmony 文档《二进制签名工具》：<https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/tools/binary-sign-tool.md>
- 华为文档中心《二进制签名工具》：<https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/binary-sign-tool>
- OpenHarmony 文档《应用包签名工具指导》：<https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/security/hapsigntool-guidelines.md>
- hapsigner 源码（`signNativeLibs` / `SoInfoSegment`）：<https://github.com/openharmony/developtools_hapsigner>
  - `hapsigntool/.../codesigning/sign/CodeSigning.java`、`.../datastructure/NativeLibInfoSegment.java`
  - `binary_sign_tool/codesigning/sign/src/code_signing.cpp`（self-sign：`FLAG_SELF_SIGN=1<<4`、`ELF_CODE_SIGN_VERSION=0x3`、signature=descriptor digest）
  - `binary_sign_tool/hap/verify/src/verify_elf.cpp`（self-sign 判定）
- 代码签名部件：<https://github.com/openharmony/security_code_signature>
  - `README_zh.md`、`interfaces/inner_api/code_sign_utils/src/code_sign_utils.cpp`、`.../code_sign_helper.cpp`、`.../include/constants.h`、`utils/src/elf_code_sign_block.cpp`
- XPM：<https://github.com/openharmony/kernel_linux_common_modules/blob/master/xpm/README_zh.md>
  - `xpm/core/xpm_security_hooks.c`（owner 矩阵、执行校验）、`xpm/validator/exec_signature_info.c`
- 内核代码签名：<https://github.com/openharmony/kernel_linux_common_modules/tree/master/code_sign>
  - `code_sign_elf.c`（v1 sign-head 使能，需 developer mode）、`verify_cert_chain.c`、`code_sign_ioctl.c`
- 内核 fs-verity：`kernel_linux_5.10` → `include/uapi/linux/fsverity.h`（`FS_IOC_ENABLE_CODE_SIGN`、`code_sign_enable_arg`）、`fs/verity/enable.c`、`fs/verity/signature.c`、`fs/verity/open.c`
- lld `--code-sign`：self-sign 链接期能力（社区 PR，见下）

社区/二手（C 级，仅作线索）：

- 鸿蒙 PC 底层开发技术详解（一/四/七）：self-sign 算法、xpm/`fs_security_verity` kmsg 实例、`hilog -t kmsg` 排障：<http://www.pwwt.cn/news/3196642/>、<https://ai6s.net/69f750d10a2f6a37c5a7ad1e.html>
- hu60 论坛：`binary-sign-tool -selfSign 1` 让 ELF 在 HiShell 执行/依赖 .so 需一并签名：<https://www.hu60.cn/q.php/bbs.topic.107186.html>
- SwimmingTiger/command-line-tools：`--code-sign` 包装脚本 + 批量签名实践：<https://github.com/SwimmingTiger/command-line-tools>
- 「从 HarmonyOS 5.0.2 Beta1 起必须开启代码签名」（CSDN 镜像）：<https://ost.51cto.com/posts/33292>
- BMS 错误码 17700048「代码签名校验失败」：<https://www.seaxiang.com/blog/RTssne>

## 附录 A：本机实测记录（可复现）

环境：`ohos-sdk 26.0.0.18_2`（harmonybrew Cellar）；工具：
`toolchains/lib/{hap-sign-tool,binary-sign-tool}`（arm64 原生，可直接执行）。
签名的测试材料：`OpenHarmony.p12`（口令 123456，alias `openharmony application release`）、
`OpenHarmonyApplication.pem`、`SgnedReleaseProfileTemplate.p7b`。

| 对象 | 大小 | sha256（前 16） | `.codesign` / 备注 |
|---|---|---|---|
| hap 内 `libopenharmonyhost.so` | 191,392 | `886cdbfb540ef8fe` | `.codesign`@0x2d000, 0x1000；flags=0x10, csVersion=3, signSize=32 |
| 上述 stripped（llvm-objcopy 去段） | 177,192 | `6dd6d490e5a40e41` | 无 `.codesign` |
| SDK `binary-sign-tool -selfSign 1` 产物 | 182,784 | `2085d4f91fb3f5f5` | `.codesign`@0x2b000；self-sign |
| SDK `binary-sign-tool sign`（证书）产物 | 186,944 | `714385ad3ec1b537` | 证书链（OpenHarmony Application Release） |
| SDK `hap-sign-tool sign-app -inForm elf` 产物 | 194,274 | `c07a80a2789923c0` | 无 `.codesign`（尾部 sign-head） |
| kit `libc++_shared.so`（self-sign） | 1,271,736 | `f957ec5d67a10e27` | flags=0x10 |
| SDK `libc++_shared.so`（DevID 证书签名） | 1,267,392 | `ddb8622253a0f11b` | `.codesign`@0x134000；PKCS7 Huawei CBG DevID |

HAP 级实测：

- `kit/hello-maui-app.hap`（我方自签，debug）：`SoInfoSegment` magic 命中 1 次；2 个条目
  （host、libc++_shared），`sig_size≈2248`（PKCS7）。
- `kit/hello-maui-app-unsigned.hap`：无 magic。
- SDK 材料默认重签 unsigned：命中 1 次，2 条目 `sig_size≈2212`；`-signCode 0` 重签：无 magic。
- `hap-sign-tool verify-app` 对带/不带 code signing 的 hap 都成功（**verify-app 不能用来判定
  code signing 是否存在**）。
