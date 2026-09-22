# 用你的 DevEco Studio 给未签名 hap 自签（无需我们介入）

## 为什么
包内 4 个默认 hap 是**自签名（设备会拒绝，需要重签）**包：用我方调试证书 / 调试 profile 签名，profile 只包含
我们机器的 UDID → 在你的设备上安装会被系统拒绝，报
`9568257 fail to verify pkcs7 file`（设备不信任该签名）或 `9568344 install parse profile prop check error`
（profile 未绑定你的 UDID）。**这是预期结果，重试无用**。用**你自己的华为账号自动签名**即可解决。

本流程签的是包内**未签名变体** `hello-maui-app-unsigned.hap`（与默认包同一负载）——它是 kit 里**唯一**适合重签
安装的 hap；不要直接拿 4 个自签名 hap 重签。签完的 hap 绑定你的证书/UDID，设备才会接受。

> 未签名 hap 随 `device-test-kit` release（镜像在 `workload-latest`）交付；下载/解压前先按该
> release 说明的「## Integrity」小节（整包 sha256、内容树 digest）或 `.tar.gz.sha256` sidecar
> 校验。本文件与包内文档都不写死哈希 —— 一律以 release notes 为准（重签后哈希必变）。

## 步骤（约 3 分钟）
1. DevEco Studio → 新建任意工程（Empty Ability 即可）→ 在 `AppScope/app.json5` 里把 **bundleName 改为
   `com.example.hellomauiapp`**（必须与我们的 hap 一致，否则同样会因属性校验失败）。
2. File → **Project Structure → Signing Configs** → 勾选 **Automatically generate signature**（需登录华为开发者账号）
   → Studio 会生成 `*.p12` / `*.cer` / `*.p7b`（目录通常在 `~/Documents/ohos/config/`，含 `material/` 子目录）。
3. 用同一 SDK 的 `hap-sign-tool` 给我们的未签名 hap 签名（把下面路径换成你的）：
   ```bash
   hap-sign-tool sign-app -keyAlias debugKey -signAlg SHA256withECDSA -mode localSign \
     -appCertFile <你的>.cer -profileFile <你的>.p7b \
     -inFile hello-maui-app-unsigned.hap -outFile hello-maui-app-signed.hap \
     -keystoreFile <你的>.p12 -keyPwd "<key密码>" -keystorePwd "<store密码>"
   hap-sign-tool verify-app -inFile hello-maui-app-signed.hap -outCertChain out.cer -outProfile out.p7b
   ```
   > 若 `build-profile.json5` 里的密码显示为 `00000020…`（DevEco 加密值），可让 Studio 的 Signing Configs 界面显示/复制明文；
   > 或把该 `config` 目录整体发回给我们，我们用插件离线解密后代签（一条命令：`ohos-workload/scripts/sign-huawei.sh`，
   > 见 `签名与UDID指南.md` 第 4b 节）。
4. `hdc install hello-maui-app-signed.hap`，或把 hap 拷到设备用文件管理器打开安装。
   若仍报 `9568257`/`9568344`，说明这次签名的证书/profile 没绑定本设备：检查 profile 的 `debug-info.device-ids`
   是否含你的 UDID、bundleName 是否与包一致（`com.example.hellomauiapp`），再重签。

## 安装后请回传
- 日志两行：`[maui] openharmony build …` 与 `[maui] accessibility provider status=<n>`（期望 1）
- 左下角 **A11Y** 角标弹窗内容（状态 + 节点数）
- `验收说明.md` §4b 的 N1–N7 与 §5b 关键字清单结果
- 一页回传模板：`docs/plans/2026-09-21-ohos-device-report-template.md`；若启动即崩，先看错误：`ReferenceError: Cannot find module 'ets/entryability/EntryAbility' , which is application Entry Point`（约 1 秒退出 / `exit 254`）是本版 kit 的壳 abc 入口 record 缺陷，等 PA1 重建壳后的下一版 kit 重测即可，**无需 P1–P4**（`docs/plans/2026-09-22-ohos-startup-crash-rootcause.md`）；其他崩溃附 `docs/plans/2026-09-21-ohos-crash-probes.md` 的 P1–P4 探针结果（含免安装 14 库自检）
