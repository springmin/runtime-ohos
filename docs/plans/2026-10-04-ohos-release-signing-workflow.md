# Release 签名工作流（AGC 发布证书/Profile，2026-10-04；接收端 2026-10-15 已实现）

> 目的：debug（SDK 模板/测试方材料，绑 UDID）→ release（华为发布证书 + 无 UDID Profile）的工作流；**接收端已接线**（ow `sign-for-device.sh --release` + ACL 验收脚本），材料一到即可一键签/验/装。
> 输入：`2026-09-28-ohos-agc-store-readiness.md` §2、`2026-09-19-ohos-signing-and-udid-guide.md` §3–5、`ohos-workload/scripts/{sign-for-device,sign-huawei,selfsign}.sh`。
> 边界：不登录 AGC、不生成华为私钥（p12 由 DevEco/本地生成并自管）；字段名/入口以控制台为准；**真实发布材料未到**——发布域真机安装与 ACL 获批后的运行验收未做（离线自测已覆盖到真签真验）。

## 1. 控制台申请顺序（发布材料四件套）

| 步 | AGC 入口 | 产出 | 注意 |
|---|---|---|---|
| 1 | 证书、App ID 和 Profile > 证书管理 | 发布证书 `.cer`（上传 CSR；DevEco「生成密钥和 CSR」或 keytool） | 私钥 `.p12` 只留本地/CI secret；签名算法 SHA256withECDSA |
| 2 | 项目设置 > 常规 > 应用 > SHA256 公钥指纹 | 指纹登记 | 与签名证书一致；Push/Map/Account/LiveView 依赖此项 |
| 3 | 证书、App ID 和 Profile > Profile | 发布 Profile `.p7b`（release 类型、**无 UDID**） | 先启用受限服务/ACL 再申请；权限写入 Profile，改服务后须重申请 |
| 4 | 应用信息/版本 | bundleName、versionCode/Name | hap `module.json` 必须与 Profile `bundle-info.bundle-name` 一致，版本号须递增 |

- 自签 release（仅 OpenHarmony 设备）用 `UnsgnedReleasedProfileTemplate.json` + 测试根；华为商用 HarmonyOS 设备不适用（验签链为华为 CA），必须走 §1 四件套。
- ACL（`READ_PASTEBOARD` 等）走 §1 同一 Profile 申请入口 + ACL 权限说明；先申请「试用调试 Profile」（5 天、绑 UDID、不可上架）做 debug 域验证，获批后重申请发布 Profile 再重签；验收见 §3。

## 2. `--release` 接收端（ow 已实现，2026-10-15）

```sh
# 一键：材料按 §2.1 落料后（debug 默认路径字节不变；--release 与 --huawei/--external 并列）
sh scripts/sign-for-device.sh --release --unsigned <app>-unsigned.hap

# 显式材料：--profile/--key/--cert（+ --key-alias/--key-pwd-file|--pwd-input-mode）
sh scripts/sign-for-device.sh --release \
  --profile <ohos-release.p7b> --key <ohos-release.p12> --cert <ohos-release.cer> \
  --key-alias <alias> --key-pwd-file <0600 口令文件> --out-dir <dir> \
  --unsigned <app>-unsigned.hap
```

1. **预检 fail-closed**（以 `hap-sign-tool verify-profile` 输出为准，先于任何签名）：`type=release`；无 `debug-info.device-ids`；`bundle-info.bundle-name` == 每个 hap 的 `module.json` bundleName；`--cert` 证书链（≥2 张）含 Profile 的 `distribution-certificate`；debug Profile 误用/带 UDID/身份不符/缺料分别点名拒绝（debug 材料指向 `--external` 或设备路径）。
2. 签名 `sign-app -keyAlias <alias> -signAlg SHA256withECDSA -mode localSign -signCode 1`；口令走 `--key-pwd-file` 或 `--pwd-input-mode`（script(1) pty），不进 argv/日志。
3. 产物 `verify-app -outCertChain/-outProfile` 通过才落盘并打印 SHA-256；默认产物名 `<hap>-release.hap`；`--out`/`--out-dir` 同 `--external`。

### 2.1 落料路径（材料一到即可一键）

- 默认目录 `~/Documents/ohos/release/`（`OHOS_RELEASE_DIR` 可改）：放**唯一**的 `*.p7b`/`*.p12`/`*.cer`，`--release` 自动取材；多份候选 fail-closed 并列出候选。
- 覆盖顺序：`--profile/--key/--cert/--key-alias/--key-pwd-file` > `OHOS_RELEASE_{P7B,P12,CER,ALIAS,PWD_FILE}` > 落料目录；缺料报错点名所需文件/flag/env。
- 别名默认 `releaseKey`（日志点名该默认值；p12 别名不同时用 `--key-alias`/`OHOS_RELEASE_ALIAS`）。材料指纹随 `SHA256SUMS` 记录（§4）。

## 3. ACL 验收（ow `scripts/clipboard-acl-accept.sh`，2026-10-15）

> `READ_PASTEBOARD`（system_basic 受限 user_grant）批准后随 Profile 下发；普通签名包声明即装机拒（9568289 类）。一条命令跑完「构建-预检-签装-回读-运行读」：

```sh
sh scripts/clipboard-acl-accept.sh --build \
    --sign release --profile <acl.p7b> --key <acl.p12> --cert <acl.cer> --key-pwd-file <file>
# 或调试域：--sign external + 试用调试 Profile（--expect-udid 可省，自动读设备）
```

1. 构建 `-p:OpenHarmonyFeatures=clipboard -p:ClipboardProbe=true` 探针（hap `module.json` 必含 `READ_PASTEBOARD`，否则拒）。
2. **Profile ACL 预检 fail-closed**：`acls.allowed-acls`（或 `restricted-permissions`）不含 `ohos.permission.READ_PASTEBOARD` 即拒，不签不装。
3. 签名 → 装机（9568289 提示指向 profile 未带 ACL）→ `bm dump` 回读须含且 granted（`allowed-acls` 与 `requestPermissions.granted` 两形态皆认）。
4. 运行探针：先 `app://clipboard/write/<marker>`（壳写路径，零权限）再 `app://clipboard/read`（宿主 NDK 读），hilog 回读 marker 才算放行；`read null`/`GetPasteDataInner# check permission failed` 判拒。
5. 证据 + `report.md` 落 `--out`；`--dry-run` 只跑 ACL 预检并打印计划；设备侧走共享 `.device-lock` + 补丁 hdc（`OHOS_HDC_PATCHED`，普通 hdc 不可见时回退 `$HOME/.ohos-tools/hdcp4`）；离线 stub 自测 `selftest-clipboard-acl-accept.sh`（111 检查，含装机/回读/读拒红控）。

## 4. CI 集成点

- 材料：`OHOS_RELEASE_{P12,P7B,CER}` 与口令从 CI secret 或 0600 文件注入，**永不入库**；落料目录只在本机用。
- 任务：release 构建 = publish → `sign-for-device.sh --release` → `verify-app` → `release-checksums.sh` → 归档 + sidecar。
- 触发：tag/手动 workflow，与 debug/tester-kit（`make-device-test-kit.sh`）路径分离；发布/镜像走现有 `ohos-release-mirror.yml` 通道。
- 纪律：指纹/Profile 更新后旧包失效；重签后哈希必变，数字以 `SHA256SUMS` 为准。
- 自测（离线；SDK 测试钥匙合成 UDID-free release Profile 端到端）：`selftest-sign-for-device.sh` 346 检查 = `--release` 预检红绿 + stub 全路径 + 真签真验（无 SDK 时该段 SKIP）。

## 5. UDID/设备策略

- debug Profile：绑 UDID（每 Profile ≤100 台；试用调试 Profile 5 天、每应用 ≤5 个）；新增设备须重新生成/申请。
- release Profile：无 UDID，合规设备通用；安装失败先对照错误码（9568344 profile 校验 / 9568257 自签链 / 9568289 ACL 声明无授权）。
- 域：debug/内测域用试用调试 Profile + 预签（`目标设备.txt` 记 UDID + profile sha256）；release 域必须发布证书 + 发布 Profile。
- 坚盾/无 ACL 设备全局禁 JIT → 保持 AOT 兜底并两态验收（`2026-10-03-ohos-three-path-baseline.md`）。

## 6. 不确定项

- 控制台字段名、CSR 交互与审核时长以 AGC 为准；**真实发布材料未到**：`--release` 目前只用 SDK 测试钥匙合成的 release Profile 端到端验证过，华为发布链/发布域真机安装待材料到位后按 §2 一条命令复跑。
- ACL（`READ_PASTEBOARD`）获批时间与 Profile 下发形态未实测；验收脚本对 `bm dump` 的两种形态容忍，真机形态以首次验收为准；华为发布 Profile 的 p12 别名由申请人生成时自定，默认 `releaseKey` 只是建议值。
