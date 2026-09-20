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

**30 秒判断法**：查看 profile 的 `device-ids`（`profile-work/profile.json`）是否包含目标设备 UDID。
不包含 → 必须重签（见第 3 节）。

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
```

脚本做的事：复制 SDK 调试模板 → 替换 `bundle-info.bundle-name` 与 `debug-info.device-ids` →
`hap-sign-tool sign-profile` → `hap-sign-tool sign-app` → 打印 **SHA-256** 与输出路径。

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

### 4b. 华为自动签名材料代签（`scripts/sign-huawei.sh`）

**何时用**：测试方已用 DevEco Studio 的 **Automatically generate signature**（登录华为账号）生成
`*.p12` / `*.cer` / `*.p7b`，但不想自己敲 `hap-sign-tool`——于是把 Studio 的整个 `config` 目录
（通常是 `~/Documents/ohos/config/`，含 `material/{fd,ac,ce}` 密钥材料）发给我们，由我们离线代签。
这是"方案 B 的自助签名"与"方案 A 的 SDK 调试模板重签"之外的第三条路径：**证书/profile 是对方的**，
所以 profile 里绑定的是**对方的设备**，签出的 hap 对方可直接安装。

```bash
cd ohos-workload
sh scripts/sign-huawei.sh <unsigned.hap> <out.hap> [configDir] [encryptedPassword]
# 例：sh scripts/sign-huawei.sh hello-maui-app-unsigned.hap hello-maui-app-huawei.hap ~/Documents/ohos/config
```

脚本做的事（全部本地、离线）：

1. 在 `configDir` 下找 `*.p12` / `*.cer` / `*.p7b`（缺一即报错），并确认
   `<hvigor-ohos-plugin>/src/utils/decipher-util.js`（`ARKTS_PLUGIN_DIR`，默认 `~/arkts-build/…`）与
   SDK 的 `toolchains/lib/hap-sign-tool` 存在；
2. 若 `build-profile.json5` 里的密码是 DevEco 加密值（`00000020…`），用**插件自己的 `DecipherUtil`**
   配合 `config/material/{fd,ac,ce}` 就地解密（明文只在本地 `/data/storage/el2/base/tmp/opencode/ohos-pwd.txt`，
   权限 600，下次自动复用）；也可显式传 `encryptedPassword`；
3. `hap-sign-tool sign-app -keyAlias debugKey -signAlg SHA256withECDSA -mode localSign` 用对方的
   p12/cer/p7b 签名；
4. **`hap-sign-tool verify-app` 通过后才打印路径与 SHA-256**（失败即 `die`，不会给出未验证的产物）。

**注意**：签出的 hap 只能装进该 profile 绑定的设备（对方新加设备需重新自动签名再发 `config`）；
我们不修改对方的证书材料，明文密码不做持久化以外的传播。

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
- 华为自动签名材料代签脚本：`ohos-workload/scripts/sign-huawei.sh`（本文第 4b 节）
