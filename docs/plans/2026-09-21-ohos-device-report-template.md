# 真机回传模板（下一轮设备测试）

> 复制本页填空白；能填就填，填不了写「不可得 + 原因」。取证命令出处：`docs/plans/2026-09-21-ohos-device-crash-diagnostics.md`（安装/启动/hilog/jscrash/dotnet-status）；探针 P1–P4 与 14 库自检：`docs/plans/2026-09-21-ohos-crash-probes.md`。本页只采集，不重复两文内容。

## 0. 快速事实

| 项 | 值 |
|---|---|
| 设备 UDID（`hdc shell bm get -u`） | `<...>` |
| kit tar.gz sha256（实测） | `<...>`（期望 `869d1d10…bce27`） |
| tree digest（实测） | `<...>`（期望 `ac869484…a9cfb`） |
| 应用版本（`最终状态.md`「发布物」原文） | `<...>`（当前基线 `1.0.0-preview.24`） |

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

## 2. 重签（二选一）

- [ ] A. 直接用 kit 内已签 hap（profile 绑定示例 UDID；报 `9568344` 即未绑定你的设备）
- [ ] B. 自签：用你自己的证书（p7b/UDID）；命令原文：`<...>`（见包内 `自签说明.md` / `签名与UDID指南.md`）；重签后 hap 名 + sha256（可选）：`<name.hap  sha256>`

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

## 7. 未测项

- 我没测：`<如 P3/P4 未跑、AB-1 未做、faultlog 取不到；原因>`；其它：`<...>`
