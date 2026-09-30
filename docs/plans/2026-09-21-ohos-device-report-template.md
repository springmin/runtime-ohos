# 真机回传模板（下一轮设备测试）

> **2026-09-30 更新（kit #35，当前）**：kit #35 = #34 + **W9/W10 并入主线**（W9A **B2：MAUI WebView 承载 Blazor WASM**——真机 `BLZ_BOOT`/`BLZ_RENDERED` 打通（pid 6157），#34 的 AOT 入口缺口由 W10 修复；W9B T14 收尾 + T21 字体缩放；W9C T8 不等高 TableView；W9D **T20 媒体传输层**（本机镜像无 MediaKit 属预期，`IsSupported=false` 降级不抛）+ T19 深链判定（热 `delivered=1`）；W10 **AOT 入口修复**（宿主自身 libs 解析 `lib<stem>.so` + `dotnet-status.txt` 可观测、壳 AOT payload 探针/`fs` 别名/静态资源指纹；rc.2 AOT 包 OpenSSL shim 缺陷 → 本地钉 rc.1）；新壳 abc **339,164（`74054e2d…`）**/headless **23,516（`6bce4063…`）**、hap 内宿主 **293,792（`983e8f74…`）**、导出 **149**、套件 **540/floor 520**；发布实测 tar **375,629,423 B / `419d42e2…`**、树 **`d3b1b317…`**、sidecar **`d7e79d39…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `2dd447a7…`**（发布已完成，以 release「## Integrity（kit #35）」与随包校验为准）；判定点 = `docs/plans/2026-09-30-ohos-tester-handoff-kit35.md`（#34 = 上一版，见其交接文）。

> 复制本页填空白；能填就填，填不了写「不可得 + 原因」。取证命令出处：`docs/plans/2026-09-21-ohos-device-crash-diagnostics.md`（安装/启动/hilog/jscrash/dotnet-status）；探针 P1–P4 与 14 库自检：`docs/plans/2026-09-21-ohos-crash-probes.md`。本页只采集，不重复两文内容。

## 0. 快速事实

| 项 | 值 |
|---|---|
| 设备 UDID（`hdc shell bm get -u`） | `<...>` |
| kit tar.gz sha256（实测） | `<...>`（kit #35 = tar **375,629,423 B / `419d42e2…`**、tree **`d3b1b317…`**、sidecar **`d7e79d39…`**、`SHA256SUMS` 17 项 / 1,517 B / `2dd447a7…`（7 hap）；#34 = tar **375,181,367 B / `55834aeb…`**、tree **`d08de3ec…`**、sidecar **`c03ea23d…`**、`SHA256SUMS` 17 项 / `94fedc66…`；#33 = tar **218,138,546 B / `38e4d57a…`**、tree **`064cb001…`**、sidecar **`8297363e…`**、`SHA256SUMS` 17 项 / 1,517 B / `37031b9a…`（7 hap）；kit #32 = tar **207,114,608 B / `8f690949…`**、tree **`645879bc…`**、sidecar **`344760e7…`**；#31 = tar **207,023,588 B / `f4325d2f…`**、tree **`52e77ee8…`** 仅作对照；见 release「## Integrity（kit #34）」/`docs/plans/2026-09-30-ohos-tester-handoff-kit34.md` 文首；`tester-run.sh` v14 会写入 `meta/kit-hap-sha256.txt` 与 `summary.txt` 的 `main_hap_sha256`） |
| tree digest（实测） | `<...>`（期望 = release「## Integrity（kit #35）」的 tree sha256，kit #35 = **`d3b1b317…`**（#34 = `d08de3ec…`；#33 = `064cb001…`；#32 = `645879bc…`、#31 = `52e77ee8…` 仅作对照）；`summary.txt` 的 `tree_digest` 同值） |
| `tester-run.sh` 版本（`summary.txt` 的 `script_version`） | `<...>`（当前 **v14** = `14`（140,197 B / `a174fcd0…`、asset 595131362）；v13 = `13` 为 #31 值；v12 = `12 (2026-09-28)` 为 #30 值） |
| 应用版本（`最终状态.md`「发布物」原文） | `<...>`（kit #35 = rc.2 线（SDK 同 #34）；#34 = rc.2 线（SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`）；#32 及以前 = `1.0.0-preview.24`） |

> 里程碑背景：2026-09-24 kit #18 + 测试方 5 项本地修复后设备首次完整运行（`managed app hello-maui-app.dll started (UI shell)`）；
> **stock kit（#22 起；#23 为同负载工具刷新、#24 为 payload-in-libs 正式版、#25 为权限链 + Share/Scan 探测 + AOT 启动路径、#26 为 P2-INTEROP/TASK-MIG/PLAT-GAP 收口、#27 为 KIT-EXT2、#28 为 R2、#29 为 R3、#30 为 MS-MODE、#31 为 Blazor WASM/ArkWeb 组件）的首次设备复测就是本轮**，判定点（宿主加载 / bootstrap / 里程碑回归）见 `docs/plans/2026-09-24-ohos-device-milestone.md` §6；#25 判定点见 §4d，#26 增量判定点见 §4e，#27 见 §4f，#28 见 §4g，#29 见 §4h，#30 见 §4i，#31 见 §4j，#32 见 §4k，#33 见文首更新块，#34 见 §4l。

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
- `summary.txt` 的 v7/v8 键（原文照抄）：`bootstrap_errors=<...> rawfile_errors=<...> libload_errors=<...> payload_present=<...> payload_marker=<...> kit_index_ok=<...> execmem_capture=<...> execmem_lines=<...>`；`kit_index_ok=no` 请换 kit #22+ 再测；`bootstrap/rawfile` 计数 >0 时附 `hilog-bootstrap.txt`；JIT 判定见 `docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §3（#28 见 `docs/plans/2026-09-26-ohos-tester-handoff-kit28.md` §3）/ `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md` §5

## 4d. kit #25 判定点（权限弹窗文案 / Share 面板 / Scan 返回 / AOT 启动；#26–#29 继续按此判读）

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
> kit #27/#28/#29/#30 继续沿用本节（重建 payload 首次运行 / 回调路径无 ABI 回归）；kit #28 的 abc 期望为 `264136`（#27 为 `245412`）、kit #29 为 `281052`/`20916`（#30 沿用）；PLAT-GAP 路径同。

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

## 4g. kit #28 增量判定点（Map 覆盖层 / LiveView / AOT 启动桥 / 解释器实验；历史，仍按此判读）

> R2 默认 flavor 的 5 个 hap **无 Map/LiveView UI 入口**；首要判定是**降级不抛**与**重建 payload 首次运行**。
> Map 点亮需 `ARKTS_SDK_FLAVOR=harmony` 构建 + AGC 地图 AppKey；LiveView 需 AGC 实况窗权益 + 设备开关；
> AOT 直启需 `aot-haps.tar.gz` 重签 hap；解释器为独立实验资产。没有对应入口/资产的项登记「未测」，不要判失败。
> 完整判读见 `docs/plans/2026-09-26-ohos-tester-handoff-kit28.md` §2。

- Map 覆盖层降级不抛（`IsOverlayAvailable` / show/hide/close/区域/标记）：`<false/不可用原文 + 有无异常 + 未测（本包无入口）>`
- Map 覆盖层点亮（harmony + AGC AppKey）：`<flags bit1 + 地图截图 + Ready/MarkerClick/CameraIdle 事件日志 / 未做>`
- LiveView 降级不抛（`IsSupported` / Start/Update/Stop）：`<false/Unavailable 原文 + 有无异常 + 未测（本包无入口）>`
- LiveView 点亮（HMS + 权益）：`<卡片截图 + 1003500004/1003500005 错误码原文 / 未做>`
- AOT 启动桥（`aot-haps.tar.gz` 重签）：`<aot=1 日志 + managed 输出 + 有无 The application to execute does not exist>`
- 解释器实验（替换两个 .so + `<files>/interp.txt`）：`<interp=3 source=file + maps 含 libclrinterpreter.so / 无匿名 r-x + managed 输出>`
- 新 payload 首次运行（新 abc 264,136 + R2 壳桥）：`<启动两行日志原文 + verify-kit 结果（abc=264136）+ 是否存活>`

## 4h. kit #29 增量判定点（CoreSpeechKit TTS / HUKS-first SecureStorage / tester-run v11 / 自绘深度五连）

> R3 默认 flavor 的 5 个 hap **无 TTS UI 入口**（sink 不注册）：首选判定是**降级不抛**与**重建 payload 首次运行**。
> TTS 真朗读需 HMS 设备 + harmony 壳（无 AGC 权益/权限门槛）；HUKS 在默认 flavor/headless 均可走（有
> `libhuks_ndk.z.so` 时为硬件后备）；文本编辑/动画/列表/图片需演示或探针页入口；深链需系统 want 投递。
> 没有对应入口的项登记「未测（本包无入口）」，不要判失败。完整判读见 `docs/plans/2026-09-28-ohos-tester-handoff-kit29.md` §2。

- TTS 降级不抛（`IsSupported` / `SpeakAsync` / `Stop` / locales）：`<false/直接返回/no-op/设备 locale 原文 + 有无异常 + 未测（本包无入口）>`
- TTS 点亮（HMS + harmony 壳）：`<实际发声计时 + stop 静音 + locales 列表 + 错误码 1002300002/3/5 排查原文 / 未做>`
- HUKS 重启读回：`<读回值 + 是否 k1: 前缀 + IsHardwareBacked + hilog>`
- HUKS 换设备不可解 / 删除清 key：`<不可解原文 + RemoveAll 后旧值结果 + hilog / 未做>`
- HUKS 回退如实：`<回退文件密钥时 IsHardwareBacked=false 原文>`
- 模式矩阵（v11 `--mode-matrix`）：`<mode-matrix/summary.txt 逐 Run 键 + conclusion 原文>`
- 无障碍（v11 `--a11y-probe`）：`<a11y/selfcheck.txt 的 accessibilityStatus/NodeCount + summary a11y_* / 缺失容忍>`
- 文本编辑 / 动画·减少动效 / 列表 / 图片：`<录屏文件名 + 关键状态原文 / 未测（本包无入口）>`
- 深链（冷启动 / 热激活）：`<截图 + activation 日志（uri/sequence）+ 未知路由状态原文 / 未做>`
- 新 payload 首次运行（新 abc 281,052 + R3 壳桥）：`<启动两行日志原文 + verify-kit 结果（abc=281052/20916）+ 是否存活>`

## 4i. kit #30 增量判定点（runtime-mode 打包开关 / tester-run v12 / MAPFIX harmony 重切）

> MS-MODE 默认 flavor 的 5 个 hap 为 **jit 形态**（`libs/<abi>/runtime-mode.txt=jit`）：首选判定是
> **标记录入 + 优先级**与**重建 payload 首次运行**。MAPFIX 的 Map overlay 点亮需 harmony 壳 + AGC 地图
> AppKey + **与 AGC 证书指纹一致的重签**。没有对应入口/资产时登记「未测（本包无入口）」，不要判失败。
> 完整判读见 `docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2。

- runtime_mode 标记（默认包）：`<summary runtime_mode=jit(hap) + execmem 的 runtime-mode=jit source=manifest 原文>`
- 优先级（file>manifest>default）：`<写/删 <files>/interp.txt 前后的 source=file / source=manifest 原文 + 是否切到 3(file)/3(manifest)>`
- aot 显式回退（aot 形态包，可选）：`<runtime-mode=aot but …; falling back to the JIT route 行 / 无此资产 → 未测>`
- 模式矩阵 Run C 清单路线（v12）：`<run_c_via=manifest + run_c_interp_mode=3(manifest) + conclusion 原文 + 是否未写 interp.txt>`
- Map 覆盖层点亮（MAPFIX harmony + AppKey + 同指纹重签）：`<IsOverlayAvailable=true + 地图截图 + Ready/MarkerClick/CameraIdle 事件日志 / 未做>`
- 新 payload 首次运行（新宿主 MS-MODE + #29 abc）：`<启动两行日志原文 + verify-kit 结果（abc=281052/20916）+ 是否存活>`

## 4m. kit #35 增量（W9/W10：B2 真机 BLZ 打通 / T20 媒体传输层 / T14+T21+T8 余项 / AOT 入口修复）

> 见 `docs/plans/2026-09-30-ohos-tester-handoff-kit35.md` §2：B2（MAUI WebView 内嵌 Blazor WASM，`BLZ_BOOT`/`BLZ_RENDERED`）、
> T20 媒体传输层（无 MediaKit 属预期）、T14 收尾 / T21 字体缩放 / T8 不等高 TableView、AOT 入口修复
> （`dotnet-status.txt`；rc.2 AOT 包 shim 缺陷 → 本地钉 rc.1）；套件 **540/floor 520**、导出 **149**、abc **339,164**/23,516；bundle **77,754,383 / `acd26821…`**（sdk 锚 **`02a31ef348`**；dtk **392356147** / latest **392077166**；manifest **`f5fe6f35dc5`**）。

## 4l. kit #34 增量（rc.2 基线 + MAUI W6/W7/W8 + AOT v3；上一版）

> 见 `docs/plans/2026-09-30-ohos-tester-handoff-kit34.md` §2/§3：rc.2 版本自述（SDK `11.0.100-rc.2.26451.112` /
> workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`）；W6（T14/T12/N1/FIX-SHELL）+ W7/W8（T15/T16/N4/T18/N5/N6）
> 逐项勾选（套件 **513/floor 493**、导出 **145**）；JIT 主包崩溃/黑屏时重签 `aot-haps-v3.tar.gz` 判主体。

## 4k. kit #32 增量（WebView 六项 / B1 razor / SEC 收口 / Blazor 无 INTERNET）

> 9 项设备卡：`docs/plans/2026-09-28-ohos-webview-blazor-device-card.md`；判定点：`docs/plans/2026-09-28-ohos-tester-handoff-kit32.md` §2–§3；tester-run **v14**（`summary` 增 `blazor_marker_pid`/`blazor_session_nonce`）。

## 4j. kit #31 Blazor 段（第 6 个 hap / tester-run v13 `--blazor-probe`；历史）

> Blazor 组件与 MAUI 包互不依赖；没有 hdc/无法重签时登记「未测」，不判失败。完整判读见
> `docs/plans/2026-09-29-ohos-tester-handoff-kit31.md` §2/§4。

- Blazor 重签（`com.example.opendotnet`，工程 bundleName 必须同名）：`<签出文件名 + verify-app 结果 + hdc install 结果原文>`
- 两条 `BLZ_*` 标记（必过；`sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe`）：`<hilog 里 BlazorWebHost ... marker: BLZ_BOOT / BLZ_RENDERED 原文 / 未测（无 hdc）>`
- 失败采集：`<blazor-hilog.txt 文件名（含 BLZ_ERROR 行原文）+ bm dump -n com.example.opendotnet 原文 / 无>`
- 人工首屏：`<截图文件名 + 是否显示 “Hello from Blazor WebAssembly”>`
- 人工 `/counter` +1：`<0→1 原文（截图）>`

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
