# 真机回传模板（下一轮设备测试）

> 复制本页填空白；能填就填，填不了写「不可得 + 原因」。取证命令出处：`docs/plans/2026-09-21-ohos-device-crash-diagnostics.md`（安装/启动/hilog/jscrash/dotnet-status）；探针 P1–P4 与 14 库自检：`docs/plans/2026-09-21-ohos-crash-probes.md`。本页只采集，不重复两文内容。

## 0. 快速事实

| 项 | 值 |
|---|---|
| 设备 UDID（`hdc shell bm get -u`） | `<...>` |
| kit tar.gz sha256（实测） | `<...>`（期望值见 `device-test-kit` release「## Integrity」；`tester-run.sh` v6r2 会写入 `meta/kit-hap-sha256.txt` 与 `summary.txt` 的 `main_hap_sha256`） |
| tree digest（实测） | `<...>`（期望 = release「## Integrity」的 tree sha256；`summary.txt` 的 `tree_digest` 同值） |
| `tester-run.sh` 版本（`summary.txt` 的 `script_version`） | `<...>`（当前 v6r2 = `6`） |
| 应用版本（`最终状态.md`「发布物」原文） | `<...>`（当前基线 `1.0.0-preview.24`，kit #21） |

## 1. 下载与校验

```sh
base=https://github.com/springmin/sdk-ohos/releases/download   # 下载时间/来源：<YYYY-MM-DD HH:MM 时区；release 或 workload-latest 镜像>
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz"       # 以及 .tar.gz.sha256
sha256sum -c device-test-kit.tar.gz.sha256                       # 结果：<OK / 失败原文>
sha256sum device-test-kit.tar.gz                                 # 写入 kit-sha256.txt：<实测 sha256>
mkdir -p device-test-kit && tar xzf device-test-kit.tar.gz -C device-test-kit && cd device-test-kit
sh verify-kit.sh --anchor-file ../device-test-kit.tar.gz
sh verify-kit.sh --expect-tree-digest <上面的 tree digest>
# 版本原文（最终状态.md / README-交付说明.md「构建基线」）：<...>｜校验结论：<KIT OK / FAIL/WARN 原文>
```

## 2. 重签（三选一）

- [ ] A. 直接用 kit 内已签 hap（profile 绑定示例 UDID；报 `9568344` 即未绑定你的设备）
- [ ] B. 自签：用你自己的证书（p7b/UDID）；命令原文：`<...>`（见包内 `自签说明.md` / `签名与UDID指南.md`）；重签后 hap 名 + sha256（可选）：`<name.hap  sha256>`
- [ ] C. 外部预签：把 **p7b + p12 + cer + keyAlias** 走安全通道发回，由我方按你的 UDID 预签 —— 命令示例：`sh scripts/sign-for-device.sh --external --profile <你的.p7b> --key <你的.p12> --cert <你的.cer> --key-alias <alias> --pwd-input-mode --expect-udid 60CF7B27…`（UDID 换成你的；p7b 的 `debug-info.device-ids` 必须含它，fail closed）。

## 3. 安装

```sh
hdc install <你的 hap 路径>          # 期望 install bundle successfully；失败贴原文（如 9568344 ...）
hdc shell bm dump -a | grep -i <bundleName>          # 确认已安装
hdc shell param get const.product.model              # 机型
hdc shell param get const.product.software.version   # 系统版本
hdc shell param get const.ohos.apiversion            # API level
```
- bundleName：`<实际安装的 bundleName>`；安装结果：`<成功 / 错误码 + 原文>`；机型/系统版本/API：`<...>` / `<...>` / `<...>`

## 4. 启动

```sh
hdc shell hilog -r && hdc shell hilog > hilog-crash.txt   # 先清缓冲、开录
hdc shell aa start -a EntryAbility -b <bundleName>        # 另一终端；结果：<success 或错误码 + 原文>
grep -inE "hellomaui|maui|dotnet|openharmonyhost|AppKilledReporter|appspawn|PROBE" hilog-crash.txt   # Ctrl-C 后过滤
```
- 若崩溃：`aa start` → 退出耗时约 `<...>` 秒；exit 254：`<是/否>`
- `AppKilledReporter` / `JsError` 行（含时间戳）：`<...>`；jscrash 文件名：`<...>`；前后各 200 行或整份 hilog 已附：`<文件名>`
```text
# files/dotnet-status.txt（/data/app/el2/100/base/<bundleName>/files/dotnet-status.txt；不可得写原因）：
<粘贴全文；不存在或未更新也要写明>
```

## 4b. 签名与内核验签（XPM / fs-verity；命令出处：`2026-09-22-ohos-elf-signing-research.md` Tester checklist / §6）

```sh
hdc shell "cat /proc/sys/kernel/xpm/xpm_mode"              # 0=关闭；1..5=各级 XPM
hdc shell "cat /proc/sys/fs/verity/require_signatures"     # 1=fs-verity 文件必须带签名
hdc shell "hilog -t kmsg" > kmsg.log                       # 与 §4 启动复现同一时刻抓
grep -iE "xpm|unsigned file|fs_security_verity|libopenharmonyhost" kmsg.log
# 在测试方 PC 上对重签产物跑（SoInfoSegment magic 命中数；期望 >=1）：
python3 -c 'import re,sys; d=open(sys.argv[1],"rb").read(); print("SoInfoSegment magic hits:", len(re.findall(bytes.fromhex("20e7d20e"), d)))' <重签后的 hap>
# 对照一个能跑的 app（cc-switch）的某个 libs/*.so：
binary-sign-tool display-sign -inFile <cc-switch 的 libs/*.so>
```
- `xpm_mode`：`<0..5 / 不可得 + 原因>`
- `require_signatures`：`<0 / 1>`
- kmsg 过滤输出（逐字粘贴；特别注意含 `unsigned file`、`is not protected by dmverity`、`lib_no_signed event waken: -9(E_HM_PERM)` 的行及其路径）：`<粘贴 / 无此类事件>`
- 重签 hap 的 `SoInfoSegment` magic 命中数：`<n>`（0 = 本次 sign-app 未做 code signing，检查是否漏了 `-signCode 1`）
- cc-switch 某个 lib 的 `display-sign` 输出：`<code signature is not found / self-sign / 证书链原文>`

## 4c. app-lib / 别名注册 / 首帧（tester-run v6r2 自动采集；手工命令如下）

```sh
hdc shell "hilog -x | grep -E 'SetAppLibPath|appLibPathKey|NativeLibPath|lib path'"   # -> hilog/hilog-applib.txt
hdc shell "hilog -x | grep -E 'dlopen|cannot find library|openharmonyhost'"          # -> hilog/hilog-dlopen.txt
hdc shell "ls -l /data/storage/el1/bundle/libs/arm64/" > app-libs-arm64.txt          # -> device/app-libs-arm64.txt
```
- `appLibPathKey` 行（含 `lib path:` 原文）：`<粘贴 / 未出现>`（出现 `appLibPathKey: <bundle>/<module>` = 模块级 app-lib key 已注册，`libIsolation` 生效）
- 别名注册行（`[openharmony-host] … bound via alias '…'`，逐字）：`<粘贴 / 未出现>`
- 首帧判定（`registerXComponent=function` / 首帧出现 / 无 `Load native module failed`）：`<逐条>`

## 5. 探针阶梯（仍崩溃时；签装与判读见 crash-probes）

```sh
hdc install hello-mauiapp-probeN-unsigned.hap        # N=1..4
hdc shell aa start -a EntryAbility -b com.example.hellomauiapp.probeN
```
- P1 `PROBE1` 链：`<通过 / 停在哪一行>`；P2 `PROBE2 HOST_DLOPEN_RESULT`：`<...>`；P3 `PROBE3 HOST_ENTRY_RESULT`：`<...>`
```text
# P4 全部 PROBE4|... 行逐字（含 deps|N/14、host|...，勿截断）：
<粘贴>
# 免安装自检（命令见 crash-probes §2.1）：hdc shell ls -l /system/lib64/<14 库>
<14 行原样粘贴；缺失打印 No such file>
```

## 6. 附件清单

- [ ] 实际安装的 `module.json`（从 hap 解出 / 你手改后的那份）
- [ ] `hilog-crash.txt` 或 `hilog-filtered.txt`（含崩溃点前后各 200 行）
- [ ] jscrash 文件名（+ 内容或截图，有则附）
- [ ] 4 个探针 hap 重签后的 sha256
- [ ] `tester-report-<时间戳>.tar.gz`（+ `.sha256`；含 `summary.txt`、`hilog/hilog-applib.txt`、`hilog/hilog-dlopen.txt`、`device/app-libs-arm64.txt`、`meta/kit-hap-sha256.txt`）

## 7. 未测项

- 我没测：`<如 P3/P4 未跑、AB-1 未做、faultlog 取不到；原因>`；其它：`<...>`
