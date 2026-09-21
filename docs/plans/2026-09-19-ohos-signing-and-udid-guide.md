# 签名与 UDID 指南（面向测试方与团队）

> 目的：解决安装报错 **`failed to install bundle. code:9568344 error: install parse profile prop check error`**，
> 并说明如何为**任意测试设备**产出可安装的 hap。

---

## 1. 症状与根因

| 现象 | 含义 |
|---|---|
| `9568344 install parse profile prop check error` | 应用属性与**签名 profile（.p7b）** 属性校验失败 |

最常见原因：**调试 profile 绑定了固定设备 UDID**，而目标设备的 UDID 不在其中。

本仓库产出的 hap 使用 SDK 调试模板（`toolchains/lib/UnsgnedDebugProfileTemplate.json`）生成的 **debug** profile；
模板内 `debug-info.device-ids` 是**示例 UDID**（`69C7505B…`、`7EED0650…`），
所以**只有被显式加入的设备**才能安装。

**30 秒判断法**：`sh scripts/sign-for-device.sh --show-profile-devices` 直接打印 profile 中嵌入的
`debug-info.device-ids`（旧方法：查看 `profile-work/profile.json`）；不包含目标设备 UDID →
必须重签（见第 3 节）或改走第 4b/4c 节（对方证书/材料代签）。

---

## 2. 获取目标设备 UDID

| 方式 | 命令/位置 | 备注 |
|---|---|---|
| hdc（设备允许调试时）| `hdc shell bm get -u` | 返回 64 位十六进制 UDID |
| DevEco Studio | **Device Manager → 设备信息** | 设备连接后可见 |
| 无调试通道时 | 由设备管理员/IT 提供，或使用第 5 节方案（对方自行签名）| — |

> 注意：设备需开启**开发者模式**，并允许"调试安装"。

---

## 3. 方案 A（推荐）：我们按 UDID 重签

```bash
cd ohos-workload

# 单个设备
sh scripts/sign-for-device.sh <UDID>

# 多设备（逗号分隔）
sh scripts/sign-for-device.sh "<UDID1>,<UDID2>"

# 自定义输出 / 版本
sh scripts/sign-for-device.sh <UDID> --out /tmp/hello-maui-app-<name>.hap
sh scripts/sign-for-device.sh <UDID> --version 1.0.0-preview.24

# 查看 profile 绑定了哪些设备（两种模式都可用；不带路径 = 最近一次签名的
# profile-work/out.p7b，没有则回退到 SDK 调试模板并提示）
sh scripts/sign-for-device.sh --show-profile-devices
sh scripts/sign-for-device.sh --show-profile-devices <某个.p7b>
sh scripts/sign-for-device.sh --show-profile-devices --config <configDir>
```

脚本做的事：复制 SDK 调试模板 → 替换 `bundle-info.bundle-name` 与 `debug-info.device-ids` →
`hap-sign-tool sign-profile` → `hap-sign-tool sign-app` → 打印 **SHA-256** 与输出路径。
若 `module.json` 的 `bundleName` 与 `--bundle`（缺省 `com.example.hellomauiapp`）不一致，脚本会先给出 **WARN**
（这种 hap 装不上，bundle-name 必须一致——见第 4b 节的硬性规则）。

**交付给测试方**：新 hap + 新的 SHA-256（重签后哈希必然变化）。

---

## 4. 方案 B：测试方自助签名（无需我们介入）

适用于对方有 DevEco Studio、可登录华为开发者账号并为其设备自动签名：

1. 取**未签名 hap**：`hello-maui-app-unsigned.hap`（随交付提供，哈希见 `SHA256SUMS`）。
2. 在 DevEco 中任意工程执行一次**自动签名**（Signing Configs → Automatically generate signature），
   其工程目录会生成 `*.p12` / `*.cer` / `*.p7b`（该 `*.p7b` 已绑定其设备）。
3. 用同一套 SDK 的 `hap-sign-tool` 重签：

```bash
hap-sign-tool sign-app \
  -keyAlias "<自动签名生成的 keyAlias>" \
  -signAlg SHA256withECDSA -mode localSign \
  -appCertFile <their-app-cert.pem> \
  -profileFile <their-debug.p7b> \
  -inFile hello-maui-app-unsigned.hap \
  -outFile hello-maui-app-signed.hap \
  -keystoreFile <their.p12> -keyPwd <pwd> -keystorePwd <pwd>
```

### 4b. 华为自动签名材料代签（`scripts/sign-for-device.sh --huawei`）

**何时用**：测试方已用 DevEco Studio 的 **Automatically generate signature**（登录华为账号）生成
`*.p12` / `*.cer` / `*.p7b`，但不想自己敲 `hap-sign-tool`——于是把 Studio 的整个 `config` 目录
（通常是 `~/Documents/ohos/config/`，含 `material/{fd,ac,ce}` 密钥材料）发给我们，由我们离线代签。
这是"方案 B 的自助签名"与"方案 A 的 SDK 调试模板重签"之外的第三条路径：**证书/profile 是对方的**，
所以 profile 里绑定的是**对方的设备**，签出的 hap 对方可直接安装。

`--huawei` 模式是 `scripts/sign-huawei.sh` 的入口封装：先做 **bundle-name 校验**（见下），
再转交 `sign-huawei.sh` 完成解密、签名与 `verify-app`。

```bash
cd ohos-workload

# 基本用法（configDir 默认 ~/Documents/ohos/config；encryptedPassword 必填，也可用
# OHOS_ENC_PWD 环境变量传入以免出现在 argv；明文不再落盘缓存）
sh scripts/sign-for-device.sh --huawei [configDir] [encryptedPassword]

# 交互式输入密码（推荐；密码不进任何 argv）：-pwdInputMode 1，由 hap-sign-tool 在终端读取密码；
# 不需要 encryptedPassword，也跳过 hvigor 插件解密。stdin 不是 tty（CI/构建脚本）时
# sign-huawei.sh 自动用 script(1) 提供伪终端，密码可从 stdin 送进 pty（明文仍不进 argv）；
# 环境里没有 script(1) 时该模式明确报错。
sh scripts/sign-for-device.sh --huawei --pwd-input-mode [configDir]

# 指定输入/输出（--out 默认 hello-maui-app-huawei.hap）
sh scripts/sign-for-device.sh --huawei ~/Documents/ohos/config \
  --unsigned hello-maui-app-unsigned.hap --out hello-maui-app-huawei.hap

# 先看对方 profile 绑定了哪些设备（解析配置目录里的 *.p7b）
sh scripts/sign-for-device.sh --show-profile-devices --huawei ~/Documents/ohos/config
```

`sign-huawei.sh` 做的事（全部本地、离线）：

1. 在 `configDir` 下找 `*.p12` / `*.cer` / `*.p7b`（缺一即报错），并确认
   `<hvigor-ohos-plugin>/src/utils/decipher-util.js`（`ARKTS_PLUGIN_DIR`，默认 `~/arkts-build/…`）与
   SDK 的 `toolchains/lib/hap-sign-tool` 存在；
2. 若 `build-profile.json5` 里的密码是 DevEco 加密值（`00000020…`），用**插件自己的 `DecipherUtil`**
   配合 `config/material/{fd,ac,ce}` 就地解密：解密助手临时生成在私有 `mktemp -d`（0700，退出/信号时删除），
   加密密码经环境变量传入、明文只留在进程内存；不再写入共享目录（旧版 `…/ohos-pwd.txt` 缓存已移除）。
   encryptedPassword 可通过第四个参数或 `OHOS_ENC_PWD` 环境变量传入；
3. `hap-sign-tool sign-app -keyAlias debugKey -signAlg SHA256withECDSA -mode localSign` 用对方的
   p12/cer/p7b 签名（`--pwd-input-mode` 时加 `-pwdInputMode 1` 并省略 `-keyPwd/-keystorePwd`，
   由终端提示输入密码，第 2 步的解密随之跳过）；
4. **`hap-sign-tool verify-app` 通过后才打印路径与 SHA-256**（失败即 `die`，不会给出未验证的产物）。

#### 硬性规则：hap 的 bundle-name 必须与 profile 一致

签名不改变应用身份：hap 内 `module.json` 的 `app.bundleName` 必须与 profile（p7b）里的
`bundle-info.bundle-name` **完全相同**，否则设备安装会报 `9568344`。
`--huawei` 模式在签名前解压 `module.json` 与 p7b 对比，不一致直接拒绝签名：

```
ERROR: bundle-name mismatch: .../hello-maui-app-unsigned.hap is 'com.example.hellomauiapp'
but the Huawei profile .../default_MyApplication....p7b is bound to 'com.example.myapplication'.
Rebuild the hap with -p:OpenHarmonyBundleName=com.example.myapplication (or pass --unsigned
with a matching hap), then re-run
```

两条出路：

- **重新打包**（推荐）：`dotnet publish ... -p:OpenHarmonyBundleName=<profile 的 bundle-name>`，
  或直接改工程里的 `OpenHarmonyBundleName` 属性，让 `module.json` 与对方 profile 一致；
- **换输入**：`--unsigned` 指向一个 `module.json` 已经匹配的未签名 hap。

`--huawei` 模式下 **`--bundle` 不可用**（发布时改 bundle 无效，脚本会直接报错）；
bundle 身份只能靠重新打包决定。`--version` 在 `--huawei` 模式下忽略（SDK 由 `OHOS_SDK_ROOT` 决定）。

#### 已知限制

- **profile 与设备绑定**：签出的 hap 只能装进该 profile `debug-info.device-ids` 里列出的设备；
  可以先 `sh scripts/sign-for-device.sh --show-profile-devices --huawei <configDir>`
  核对目标设备 UDID 是否在列表里。
- **新增设备需要对方操作**：每加一台设备，都要在 DevEco Studio / AGC 里把该设备 UDID 加入自动签名
  （重新生成 p7b）后把新的 `config` 目录发给我们；我们无法为对方的证书/profile 增删设备。
- **加密密码需要 hvigor 插件**：Studio 的 `00000020…` 密码必须用 `@ohos/hvigor-ohos-plugin` 的
  `DecipherUtil` 配合 `config/material/{fd,ac,ce}` 解密；只发 p12/cer/p7b 而没有 `material`/插件时无法代签。
- 我们不修改对方的证书材料；解密后的明文密码不再缓存到任何路径（旧版共享 scratch 缓存已移除）。
- **签名密码的 argv 残留（仅默认模式）**：默认（非 tty/CI）路径下 `hap-sign-tool` 只接受命令行密码，
  因此签名调用期间明文会短暂出现在该子进程的 `-keyPwd/-keystorePwd` argv 中，进程结束即消失，不落盘、
  不随产物分发。`--pwd-input-mode`（或 `OHOS_PWD_INPUT_MODE=1`）改用 `-pwdInputMode 1` 并**完全省略**
  这两个参数：密码由 `hap-sign-tool` 在终端/pty 上读取，argv 残留彻底消失，且不需要
  encryptedPassword、不需要 hvigor 插件（跳过解密步骤）。该模式有 tty 时直接提示输入；stdin 不是 tty
  （CI/构建脚本）时脚本自动用 `script(1)` 提供伪终端，密码可从 stdin 送进 pty（仍不进 argv）。
  残留只剩一种：调用环境既没有 tty、又找不到 `script(1)`，此时脚本明确报错（安装 util-linux/busybox
  的 script 即可）。

### 4c. 外部材料代签（对方自备 p7b + p12，`--external`）

**何时用**：测试方用自己在 DevEco/AGC 侧的流程为目标设备申请到了 **Huawei 签发的 debug profile
（`.p7b`，已绑定其设备 UDID）**，并本地生成了配套私钥（`.p12`），但不想自己跑 `hap-sign-tool`；
于是把材料发来由我们**离线预签**，产物装到对方设备即可。与 4b 的区别：不需要 DevEco 的
`config/material`，也不需要 hvigor 插件解密——密码由对方直接提供（或交互输入）。

**对方需要发送（走安全通道；只发 debug 材料，勿用明文邮件/群聊）**：

| 材料 | 说明 |
|---|---|
| `*.p7b` | Huawei 签发的 debug profile；`debug-info.device-ids` 必须包含目标设备 UDID |
| `*.p12` | 配套私钥库（对方本地生成） |
| `keyAlias` | p12 中的密钥别名（DevEco 自动签名默认 `debugKey`） |
| p12 密码 | 建议放 `0600` 的 pwd 文件随材料发送，或单独走更安全的通道；不会写进任何日志/产物 |
| `*.cer` | 与该 p12 匹配的 app 证书链（DevEco 配置目录的 `default_*.cer`）。p7b 里只有**叶子**证书，而 `hap-sign-tool sign-app` 需要完整链（root/sub CA/leaf），请一并发送；放在 p7b 同目录会自动识别，或用 `--cert <cer>` 显式指定 |
| 目标 UDID | `hdc shell bm get -u` 的 64 位十六进制值，供前置校验 |

**我们校验什么（fail closed：任何一项不通过都拒绝签名）**：

1. 用 `hap-sign-tool verify-profile` 提取 p7b 的 JSON，读取 `debug-info.device-ids`：
   **必须包含 `--expect-udid`**；找不到列表（如 release profile）或 UDID 不在其中都直接报错退出；
2. 每个 hap 的 `module.json` `bundleName` 必须与 p7b 的 `bundle-info.bundle-name` 完全一致（否则装时报 9568344）；
3. app 证书链必须包含 p7b 的 `bundle-info.development-certificate`（防止拿错 `.cer`）；
4. 每个 hap 签完都跑 `hap-sign-tool verify-app`，不通过就不保留产物。

**用法**（支持一次签多个 hap；密码不进 argv、不打印）：

```bash
cd ohos-workload

# 交互式：hap-sign-tool 在终端提示 keystorePwd/keyPwd（两次）；无 tty 时自动用 script(1)
# 提供 pty（stdin 需送两行密码）
sh scripts/sign-for-device.sh --external \
  --profile <对方.p7b> --key <对方.p12> --key-alias <alias> \
  --expect-udid <目标UDID> --pwd-input-mode \
  --unsigned hello-maui-app-unsigned.hap --out /tmp/hello-maui-app-<name>.hap

# 批量：密码放 0600 文件。加 --pwd-input-mode 时经 script(1) pty 送入，仍不进 argv；
# 不加时沿用 --huawei 默认模式的 argv 短暂残留（见 4b 已知限制）
sh scripts/sign-for-device.sh --external \
  --profile <对方.p7b> --key <对方.p12> --key-alias <alias> \
  --expect-udid <目标UDID> --key-pwd-file /secure/pwd.txt \
  --unsigned a.hap --unsigned b.hap --out-dir out/

# 不签名，只查看 profile 绑定了哪些设备
sh scripts/sign-for-device.sh --show-profile-devices <对方.p7b>
```

**一键产出预签交付包**（kit 内全部 hap、含 unsigned 变体都会预签为该 UDID 后再打包）：

```bash
cd ohos-workload
# 把对方的 .cer 放在 .p7b 同目录（自动识别），或用 OHOS_EXT_CERT=... 指定
OHOS_KEY_PWD_FILE=/secure/pwd.txt sh scripts/make-device-test-kit.sh \
  --sign-external <对方.p7b> <对方.p12> <alias> <目标UDID> \
  [--kit-dir <dir>] [--skip-tar]
```

Kit 里会多出 `目标设备.txt`（目标 UDID、profile 的 sha256、签名方式与覆盖范围；**不含任何密钥/密码**），
`SHA256SUMS` 照常覆盖它，随包 `verify-kit.sh` 的 tree digest 也覆盖它。密码只在签名进程内使用：
`--pwd-input-mode` 下由终端/pty 读取；脚本从不打印密码（pty 回显也被丢弃）。

**注意**：

- 只收 debug 材料；签名完成后材料由双方各自销毁，本仓库不保存任何外部材料；
- profile 的 bundle-name 必须与目标 hap 一致：kit 内 hap 的实际 bundle 以 `verify-kit.sh` 输出的
  `bundle=...` 为准。若对方 profile 绑的是别的 bundle（例如 `com.example.myapplication`），
  需要按 4b 节重新打包 hap，或让对方为对应 bundle 重新生成 profile；
- 外部材料模式也可直接签单个 hap：日志会打印每个产物的 SHA-256，交付时同步给对方。

---

## 5. 方案 C：release 型自签名（仅 OpenHarmony 设备）

- 使用 `toolchains/lib/UnsgnedReleasedProfileTemplate.json`（`type: release`，**无 UDID 绑定**）；
- 设备需信任自签证书链；
- **华为商用 HarmonyOS 设备不适用**（验签链为华为 CA）。

---

## 6. 产物校验与发布

```bash
sh scripts/release-checksums.sh     # 生成 dist/SHA256SUMS（bundle / abc / 已签与未签 hap）
```

- 每次重签或重新打包，**哈希都会变化**：交付文档中的 SHA-256 需同步更新；
- 建议随每次交付附带 `SHA256SUMS` 与"本次适用 UDID"说明。

---

## 7. 错误码对照（本仓库踩过的）

| 错误 | 含义 | 处理 |
|---|---|---|
| `9568344 install parse profile prop check error` | profile 属性/UDID 校验失败 | 第 3/4 节重签 |
| 签名前置检查失败（bundle-name mismatch）| hap 的 `module.json` 与 profile 的 `bundle-name` 不一致 | 按第 4b 节重新打包（`-p:OpenHarmonyBundleName=`）或换匹配的 `--unsigned` hap |
| `E00C001 Operation restricted by the organization`（hdc）| 系统组织策略关闭了 hdc（`const.usb.port.user_hdc.disable=true`）| 由设备管理员放开策略；或改走人工安装/方案 B |
| 安装被拒（未知来源）| 设备未允许外部/调试安装 | 开发者模式 + 允许调试安装 |
| 签名校验失败（非 9568344）| 证书链不受信任 | 方案 B（对方证书）或方案 C（OpenHarmony 设备）|

---

## 8. 相关文档

- 验收清单（随 hap 交付）：`docs/plans/2026-09-19-ohos-hap-acceptance-for-testers.md`
- 快速上手（随包一页版）：`docs/plans/2026-09-20-ohos-tester-quickstart.md`
- 交接状态与操作规程：`docs/plans/2026-09-19-ohos-arkts-handover-status.md`
- 测试方自助签名（随包）：`自签说明.md`
- 按 UDID 重签脚本：`ohos-workload/scripts/sign-for-device.sh`（本文第 3 节）
- 华为自动签名材料代签：`ohos-workload/scripts/sign-for-device.sh --huawei`（封装 `scripts/sign-huawei.sh`，本文第 4b 节）
- 外部材料代签（对方 p7b + p12）：`ohos-workload/scripts/sign-for-device.sh --external`（本文第 4c 节）
- 一键预签交付包：`ohos-workload/scripts/make-device-test-kit.sh --sign-external`（本文第 4c 节）
- profile 设备列表查看：`ohos-workload/scripts/sign-for-device.sh --show-profile-devices`（两种模式通用）
