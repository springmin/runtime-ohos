# 用你的 DevEco Studio 给未签名 hap 自签（无需我们介入）

## 为什么
我们的包用**自签名证书**签发，其调试 profile 只包含我们机器的 UDID → 你的设备安装会报
`9568344 install parse profile prop check error`。用**你自己的华为账号自动签名**即可解决。

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

## 安装后请回传
- 日志两行：`[maui] openharmony build …` 与 `[maui] accessibility provider status=<n>`（期望 1）
- 左下角 **A11Y** 角标弹窗内容（状态 + 节点数）
- `验收说明.md` §4b 的 N1–N7 与 §5b 关键字清单结果
