# 真机回传模板（下一轮设备测试）

> 复制本页填空白；能填就填，填不了写「不可得 + 原因」。取证命令出处：`docs/plans/2026-09-21-ohos-device-crash-diagnostics.md`（安装/启动/hilog/jscrash/dotnet-status）；探针 P1–P4 与 14 库自检：`docs/plans/2026-09-21-ohos-crash-probes.md`。本页只采集，不重复两文内容。

## 0. 快速事实

| 项 | 值 |
|---|---|
| 设备 UDID（`hdc shell bm get -u`） | `<...>` |
| kit tar.gz sha256（实测） | `<...>`（期望值见 `device-test-kit` release「## Integrity」；`tester-run.sh` v8 会写入 `meta/kit-hap-sha256.txt` 与 `summary.txt` 的 `main_hap_sha256`） |
| tree digest（实测） | `<...>`（期望 = release「## Integrity」的 tree sha256；`summary.txt` 的 `tree_digest` 同值） |
| `tester-run.sh` 版本（`summary.txt` 的 `script_version`） | `<...>`（当前 v8 = `8`） |
| 应用版本（`最终状态.md`「发布物」原文） | `<...>`（当前基线 `1.0.0-preview.24`，kit #27） |

> 里程碑背景：2026-09-24 kit #18 + 测试方 5 项本地修复后设备首次完整运行（`managed app hello-maui-app.dll started (UI shell)`）；
> **stock kit（#22 起；#23 为同负载工具刷新、#24 为 payload-in-libs 正式版、#25 为权限链 + Share/Scan 探测 + AOT 启动路径、#26 为 P2-INTEROP/TASK-MIG/PLAT-GAP 收口）的首次设备复测就是本轮**，判定点（宿主加载 / bootstrap / 里程碑回归）见 `docs/plans/2026-09-24-ohos-device-milestone.md` §6；#25 判定点见 §4d，#26 增量判定点见 §4e。

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

## 4c. app-lib / 别名注册 / 首帧 / bootstrap / payload（tester-run v8 自动采集；手工命令如下）

```sh
hdc shell "hilog -x | grep -E 'SetAppLibPath|appLibPathKey|NativeLibPath|lib path'"   # -> hilog/hilog-applib.txt
hdc shell "hilog -x | grep -E 'dlopen|cannot find library|openharmonyhost'"          # -> hilog/hilog-dlopen.txt
hdc shell "hilog -x | grep -E 'GetRawFileContent|bootstrap failed|BusinessError|900002|900003|ZIP entry|destination path|Load native module failed|symbol not found|cannot find library'"   # -> hilog/hilog-bootstrap.txt（v7 起）
hdc shell "ls -l /data/storage/el1/bundle/libs/arm64/" > app-libs-arm64.txt          # -> device/app-libs-arm64.txt
hdc shell "ls -l /data/storage/el2/base/haps/entry/files/" | grep -E 'dotnet|payload' # -> device/payload-files.txt（v7 起）
hdc shell "cat /data/storage/el2/base/haps/entry/files/dotnet.marker"                # -> device/payload-marker.txt（v7 起，或为空）
```
- `appLibPathKey` 行（含 `lib path:` 原文）：`<粘贴 / 未出现>`（出现 `appLibPathKey: <bundle>/<module>` = 模块级 app-lib key 已注册，`libIsolation` 生效）
- 别名注册行（`[openharmony-host] … bound via alias '…'`，逐字）：`<粘贴 / 未出现>`
- 首帧判定（`registerXComponent=function` / 首帧出现 / 无 `Load native module failed`）：`<逐条>`
- `summary.txt` 的 v7/v8 键（原文照抄）：`bootstrap_errors=<...> rawfile_errors=<...> libload_errors=<...> payload_present=<...> payload_marker=<...> kit_index_ok=<...> execmem_capture=<...> execmem_lines=<...>`；`kit_index_ok=no` 请换 kit #22+ 再测；`bootstrap/rawfile` 计数 >0 时附 `hilog-bootstrap.txt`；JIT 判定见 `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md` §4 / `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md` §5

## 4d. kit #25 判定点（权限弹窗文案 / Share 面板 / Scan 返回 / AOT 启动；#26/#27 继续按此判读）

> 本 kit 的 5 个 hap 是 **JIT payload**（hostfxr 回退路径）；Share/Scan 的 sink 在 OpenHarmony SDK 下
> **不注册**（`shareDispatch=False`/`scanSupported=False`），面板/扫码 UI 需 `ARKTS_SDK_FLAVOR=harmony`
> 的 HarmonyOS SDK 构建 + HMS 设备。没有对应入口的项登记「未测（本包无入口）」，不要判失败。
> 完整判读见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md` §2。

- 权限弹窗文案（权限变体）：`<弹窗是否显示理由文案 + 截图文件名>`
- 权限声明原文（`unzip -p <hap> module.json` 的 `requestPermissions`，含 `reason`/`usedScene`）：`<粘贴 / 未做>`
- Share 面板：`<OpenHarmony 下是否干净降级（shareDispatch=False，不崩）/ HarmonyOS 变体面板结果 / 未测（本包无入口）>`
- Scan 返回：`<scanSupported=False 时 IsSupported/ScanAsync 结果 / HarmonyOS 变体 originalValue / 未测（本包无入口）>`
- AOT 启动：`<AOT hap 启动结果（app export）/ 未提供 AOT hap → JIT hostfxr 回退回归结果>`

## 4e. kit #26 增量判定点（新 payload 首次运行 / 原生桥 ABI / PLAT-GAP 恢复路径；历史，仍按此判读）

> 完整判读见 `docs/plans/2026-09-26-ohos-tester-handoff-kit26.md` §2；§4d 的权限/Share/Scan/AOT 口径不变。
> kit #27 继续沿用本节（重建 payload 首次运行 / 回调路径无 ABI 回归），abc 期望改为 `245412`；PLAT-GAP 路径同。

- 新 payload 首次运行（LibraryImport hosting 重建）：`<启动两行日志原文 + 是否存活 + 5 条冒烟结果>`
- 原生桥 ABI 抽查（权限请求 / `A11Y` / Hybrid `Echo`·`Add`）：`<结果截图/回显 + 有无 EntryPointNotFound/DllNotFound/参数错乱>`
- PLAT-GAP 消费方路径（用 kit #26 workload 发布引用 `Microsoft.AspNetCore.App` 的项目）：`<dotnet publish 结果 + 是否需要工程级 KFR/RID/apphost 规避 / 未做>`

## 4f. kit #27 增量判定点（无 HMS 降级不抛（Push/Account/Map）/ 新 payload 首次运行）

> KIT-EXT2 **未新增 UI 入口**：5 个 hap 里没有 Push/Account/Map 的按钮。首选判定是**降级不抛**；真 Kit 调用需
> `ARKTS_SDK_FLAVOR=harmony` 构建 + HMS 设备 + AGC 开通/审批。没有对应入口的项登记「未测（本包无入口）」，不要判失败。
> 完整判读见 `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md` §2。

- 无 HMS 降级不抛（Push `GetTokenAsync` / Account `AuthorizeAsync`·`GetQuickLoginAnonymousPhoneAsync` / Map `QueryCapabilitiesAsync`·`MapKitImportable`·`IsSupported`）：`<Unavailable/null/false 原文 + 有无异常/崩溃 + 未测（本包无入口）>`
- Push token（需 HMS/AGC）：`<token 首尾片段 + 错误码 1000900010/1000900012 排查原文 / 未测>`
- Account 授权（需 HMS + scope 审批）：`<匿名手机号 + authorizationCode 结果 + 错误码 1001502014/1001500001 排查原文 / 未测>`
- Map 能力位（需 HMS/AGC + AppKey）：`<capability bits（bit0）+ QueryCapabilitiesAsync 结果原文 / 未测>`
- 新 payload 首次运行（新 abc 245,412 + 新宿主 + marshal-off）：`<启动两行日志原文 + verify-kit 结果（abc=245412）+ 是否存活>`
- 回调路径（marshal-off）：`<权限请求 / A11Y / Hybrid Echo·Add 结果 + 有无 EntryPointNotFound/DllNotFound/参数错乱>`

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
- [ ] `tester-report-<时间戳>.tar.gz`（+ `.sha256`；含 `summary.txt`、`hilog/hilog-applib.txt`、`hilog/hilog-dlopen.txt`、`hilog/hilog-bootstrap.txt`、`device/app-libs-arm64.txt`、`device/payload-files.txt`、`device/payload-marker.txt`、`meta/kit-hap-sha256.txt`、`meta/kit-selfcheck.txt`）

## 7. 未测项

- 我没测：`<如 P3/P4 未跑、AB-1 未做、faultlog 取不到；原因>`；其它：`<...>`
