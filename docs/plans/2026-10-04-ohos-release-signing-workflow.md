# Release 签名工作流骨架（AGC 发布证书/Profile，2026-10-04）

> 目的：debug（SDK 模板/测试方材料，绑 UDID）→ release（华为发布证书 + 无 UDID Profile）的工作流骨架，离线可备料；账号/控制台操作待人工。
> 输入：`2026-09-28-ohos-agc-store-readiness.md` §2、`2026-09-19-ohos-signing-and-udid-guide.md` §3–5、`ohos-workload/scripts/{sign-for-device,sign-huawei,selfsign}.sh`、`packs/*/templates/scripts/sign-hap.sh`。
> 边界：不登录 AGC、不生成华为私钥（p12 由 DevEco/本地生成并自管）；字段名/入口以控制台为准。

## 1. 控制台申请顺序（发布材料四件套）

| 步 | AGC 入口 | 产出 | 注意 |
|---|---|---|---|
| 1 | 证书、App ID 和 Profile > 证书管理 | 发布证书 `.cer`（上传 CSR；DevEco「生成密钥和 CSR」或 keytool） | 私钥 `.p12` 只留本地/CI secret；签名算法 SHA256withECDSA |
| 2 | 项目设置 > 常规 > 应用 > SHA256 公钥指纹 | 指纹登记 | 与签名证书一致；Push/Map/Account/LiveView 依赖此项 |
| 3 | 证书、App ID 和 Profile > Profile | 发布 Profile `.p7b`（release 类型、**无 UDID**） | 先启用受限服务/ACL 再申请；权限写入 Profile，改服务后须重申请 |
| 4 | 应用信息/版本 | bundleName、versionCode/Name | hap `module.json` 必须与 Profile `bundle-info.bundle-name` 一致，版本号须递增 |

- 自签 release（仅 OpenHarmony 设备）用 `UnsgnedReleasedProfileTemplate.json` + 测试根；华为商用 HarmonyOS 设备不适用（验签链为华为 CA），必须走 §1 四件套。
- ACL（JIT）走 §1 同一 Profile 申请入口 + ACL 权限说明；先申请「试用调试 Profile」（5 天、绑 UDID、不可上架）做 debug 域验证，获批后重申请发布 Profile 再重签。

## 2. `sign-hap.sh` 释放模式扩展草案（未实现，仅骨架）

现状（`templates/scripts/sign-hap.sh`）只支持 debug：模板写 bundle+UDID → `sign-profile`（SDK 测试密钥）→ `sign-app`。草案新增 release 分支（`OHOS_RELEASE_{PROFILE,KEY,CERT,ALIAS}` 或 `--release`）：

1. `verify-profile`/`verify-app` 预检 p7b：`type=release`、无 `debug-info.device-ids`、bundle-name 等于 hap（fail-closed）；
2. `sign-app -appCertFile <release.cer> -profileFile <release.p7b> -keystoreFile <release.p12> -signCode 1`（密码走 `-pwdInputMode 1`，不进 argv）；
3. 产物 `verify-app` 通过才落盘并打印 SHA-256。
   落地：优先扩展现有脚本（debug 默认路径字节不变）；入口在 `scripts/sign-for-device.sh` 增 `--release`（与 `--huawei/--external` 并列），复用其 bundle-name/证书链校验。

## 3. CI 集成点

- 材料：`OHOS_RELEASE_P12/P7B/CER` 与密码从 CI secret 或 0600 文件注入，**永不入库**；
- 任务：release 构建 = publish → 签名 → `verify-app` → `release-checksums.sh` → 归档 + sidecar；
- 触发：tag/手动 workflow，与 debug/tester-kit（`make-device-test-kit.sh`）路径分离；发布/镜像走现有 `ohos-release-mirror.yml` 通道；
- 纪律：指纹/Profile 更新后旧包失效；重签后哈希必变，数字以 `SHA256SUMS` 为准。

## 4. UDID/设备策略

- debug Profile：绑 UDID（每 Profile ≤100 台；试用调试 Profile 5 天、每应用 ≤5 个）；新增设备须重新生成/申请；
- release Profile：无 UDID，合规设备通用；安装失败先对照错误码（9568344 profile 校验 / 9568257 自签链）；
- 域：debug/内测域用试用调试 Profile + 预签（`目标设备.txt` 记 UDID + profile sha256）；release 域必须发布证书 + 发布 Profile；
- 坚盾/无 ACL 设备全局禁 JIT → 保持 AOT 兜底并两态验收（`2026-10-03-ohos-three-path-baseline.md`）。

## 5. 不确定项

控制台字段名、CSR 交互与审核时长以 AGC 为准；`sign-hap.sh --release` 仅为草案，未用真实发布材料在设备验证；release 域 ACL（JIT）尚未获批。
