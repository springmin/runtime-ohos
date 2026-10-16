# RELEASE-FIRST-SIGN：首个真·发布签名（AGC 材料落地，2026-10-15）

> 结论：AGC 发布链打通——本地 openssl 生成 CSR → AGC 签发发布证书（3 链）→ Release Profile →
> `sign-for-device.sh --release` 真签 + 内建 `verify-app` 通过。首件 release-signed hap =
> **`hello-maui-app-unsigned-release.hap`**（sha256 `b57261006e1743873c637fa40c28970641cc001ea416e9b5e8df15339a70381f`），
> bundle = **`mauidemo.dotnet.springmin.com`**。真机安装/冒烟因设备连接再次波动**待补**（TCP 端口在、hdc 握手失败；与 #57 窗口同签名）。

## 1. 材料与落点（`~/Documents/ohos/release/`，chmod 在本挂载为 no-op、单用户可接受）
- `release.csr`（本地生成，sha256 `84e440efe9a6…`）→ 于 AGC「证书管理」上传
- `maui demo.cer`（AGC 下载；3 链 = Huawei CBG Root CA G2 → Huawei CBG Developer Relations CA G2 →
  Leaf `CN=冉启春(2044064257653363457)\,Release`；**Leaf 公钥与私钥 MATCH**）
- `mauidemo.profileRelease.p7b`（type=**release** · `bundle-name=mauidemo.dotnet.springmin.com` · 无 device-ids ·
  distribution-cert = 上述 Leaf；ACL=空——`READ_PASTEBOARD` 尚未申请）
- `release.p12`（alias **`releasekey`**，见 §2）+ `release.p12.pwd`

## 2. 两处坑与修法
- **别名大小写**：openssl 以 `-name releaseKey` 存 friendlyName → hap-sign-tool 查询小写 `releasekey` 未命中
  （`KEY_ALIAS_ERROR -109`）→ 以 `-name releasekey` 重导出即通（keytool/Java 对 PKCS12 别名同样小写规范化）。
- **构建**：`make-mode-kit.sh --mode aot --tfm net11.0-openharmony26.0 --property OpenHarmonyBundleName=…`；
  csc 一次 139 崩 → 按既有对策 `DOTNET_PROCESSOR_COUNT=1` + `--property UseSharedCompilation=false` 重试成功。

## 3. 签名与验证（一条命令）
- `OHOS_RELEASE_PWD_FILE=…/release.p12.pwd sh scripts/sign-for-device.sh --release <hap>`（材料自动取材）
- 日志链：`app cert chain OK (3 certificates)` → `release sign … → hello-maui-app-unsigned-release.hap` → **`verify-app OK`**
  （`-outCertChain/-outProfile` 内建）；#49–#57 资产未动、无上游 PR。

## 4. 待补（设备回线后）
- `hdcp4 install -r <release hap>` → 启动冒烟（pid/窗口/fault diff）→ 记录 release 域 AOT 安装/运行行为
- ACL 获批后：更新同一 Profile（`allowed-acls += READ_PASTEBOARD`）→ `clipboard-acl-accept.sh` 一键验收；
  A4（release 域 JIT）亦可在 ACL 后随试——AOT 路径预期不受 A4 限制。

## 5. 不确定项
- 设备再现性波动（hdc 握手失败）非本件引入；华为发布链在本镜像的**安装接受性**待装机确认。
