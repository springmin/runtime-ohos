# RELEASE-SIGN-WIRE：发布签名接收端 + ACL 验收接线（2026-10-15）

> 结论：AGC 发布材料（.p12/.cer/.p7b）与 ACL 批准（`READ_PASTEBOARD`）到位后，可「一键签/验」并跑完 ACL 装机-回读验收；本波不涉上游 PR、不使用真实发布材料（设备非必需）。
> 载体：ow master（`sign-for-device.sh --release` + `selftest-sign-for-device.sh` 346 检查；`clipboard-acl-accept.sh` + `selftest-clipboard-acl-accept.sh` 111 检查）＋本文（runtime `docs/plans/`）。

## 1. 交付

- `--release`（ow `sign-for-device.sh`）：参数/env/落料目录（默认 `~/Documents/ohos/release/`，唯一 `*.p7b`/`*.p12`/`*.cer` 自动取材）；预检 fail-closed = `type=release` + 无 device-ids + `bundle-name`==hap `module.json` bundleName + 证书链含 `distribution-certificate`（先于任何签名）；`sign-app -signCode 1`；产物 `verify-app -outCertChain/-outProfile` 通过才落盘（默认 `<hap>-release.hap`）；缺料点名文件/flag/env。用法与预期错误码见 `2026-10-04-ohos-release-signing-workflow.md` §2。
- 自测：stub 红绿（缺料/多候选、误用 debug、带 UDID、bundle 不符、签/验失败不落盘、口令不进 argv/日志）+ SDK-gated 真签段（SDK 测试钥匙合成 UDID-free release Profile → 真 `hap-sign-tool` 签一个真 hap → 脚本内 `verify-app` + 外部 `verify-app`/`verify-profile` 双验；真 debug Profile 与带 UDID release Profile 均拒绝）。
- ACL 验收：`clipboard-acl-accept.sh`（build `-p:OpenHarmonyFeatures=clipboard -p:ClipboardProbe=true` → ACL Profile 预检 fail-closed → `--sign release|external` → 装机 → `bm dump` 含且 granted → `app://clipboard/write|read` 回读 marker → `report.md`）；离线 stub 自测 111 检查；设备侧共享 `.device-lock` + 补丁 hdc。
- 文档：workflow 文档状态=已实现（§2 用法/落料路径 + §3 ACL 验收）；ow `scripts/README.md` 行。

## 2. 边界

- 真机段未跑（材料未到）：发布域安装、ACL 授权后的运行读、华为发布链验签以材料到位后的首跑为准（设备非必需；本波离线证据为真签真验 + stub 全路径）。
- `bm dump` 的 ACL 形态（`allowed-acls` vs `requestPermissions.granted`）两形皆收，首次真机验收以 `report.md` 存证为准；华为发布 Profile 的 p12 别名默认 `releaseKey` 仅为建议值。
