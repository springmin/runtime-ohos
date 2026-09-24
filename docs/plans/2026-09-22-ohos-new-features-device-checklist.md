# 2026-09-22 新功能真机验证清单（测试者版）

> 面向拿到 `device-test-kit`（kit #24，preview.24 基线）与 `tester-run.sh` 的测试者：验证本轮（2026-09-22）落地的 MAUI on OpenHarmony 新能力。
> kit #24（2026-09-24）已含自 kit #17 起的全部安全/性能/启动修复，并在设备里程碑回灌中补齐：宿主按需 dlsym、HAP `resources.index`（restool）、ZIP offset/length + mkdir、DevEco `modelVersion 6.0.2` 工程布局；kit #24 再叠加 payload-in-libs（`libs/arm64-v8a/` 原地启动 + `.dotnet-payload.json`，`dotnet.zip` 回退）、宿主显式 W^X=0 与 exec-memory 探针。主选就是它本身（`libIsolation` + 全部修复）。**kit #24 未新增 UI 入口**——逐项「现有入口/无入口」沿用本清单（标「kit #23 无入口」的项在 #24 同样无入口；运行时与打包层改动见 §0.4/§0.5 与 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`）。对照载荷（dynpkg/normalized/importb/importd/importprobe a–c）与 P1–P4 探针仍在同一 release，按交付方指示取用。2026-09-24 真机里程碑（kit #18 + 测试方 5 项本地修复首次完整运行）见 `docs/plans/2026-09-24-ohos-device-milestone.md`；**stock kit（#22 起，含 #24）尚未上机**。
> 与 `验收说明.md`（A1–K2、N1–N7）互补：A–N 覆盖既有能力，本清单覆盖 **M1–M13**（M11–M13 为 2026-09-23 深化批：真实缺陷修复 / UX 深化 / 原始 HAP 资源桥）。
> 逐项格式：**入口 → 步骤 → 期望 → 证据（抓什么）→ 可能失败**。绝大多数步骤需人工操作：`tester-run.sh` 只能自动**安装 / 启动 / 录 hilog / 跑启动崩溃探针**，触发 UI、切换系统设置、接受弹窗、截图、取沙箱文件都要人工完成。

---

## 0. 先读

### 0.1 本轮范围与托管实现锚点

代码位于 `maui-ohos`（托管切片）与 `ohos-workload`（宿主/ArkTS 壳）；下表路径省略前两个仓名。

| # | 能力 | 托管实现（锚点文件） | kit #23/#24 现有入口 |
|---|---|---|---|
| M1 | 运行时权限（`IPermissions.RequestAsync` / `CheckStatusAsync`）| `maui-ohos:src/Core/src/Platform/OpenHarmony/OpenHarmonyEssentialsUnsupported.cs`（`OpenHarmonyPermissions`）+ `OpenHarmonyEssentialsBridges.cs`（`OpenHarmonyPermissionBridge`）| 无按钮，需功能探针页 |
| M2 | 连通性（`NetworkAccess` / `ConnectivityChanged`）| `.../OpenHarmonyEssentialsExtras.cs`（`OpenHarmonyConnectivity`）+ `OpenHarmonyEssentialsBridges.cs`（`OpenHarmonyConnectivityBridge`）| 无按钮，需功能探针页 |
| M3 | 剪贴板（`HasText` / `GetTextAsync` / `ClipboardContentChanged`）| `.../OpenHarmonyEssentialsExtras.cs`（`OpenHarmonyClipboard`）+ `OpenHarmonyEssentialsBridges.cs`（`OpenHarmonyClipboardBridge`）| 无按钮，需功能探针页 |
| M4 | 邮件 / 短信 / 拨号 | `.../OpenHarmonyCommunication.cs`（`OpenHarmonyEmail` / `OpenHarmonySms` / `OpenHarmonyPhoneDialer`）| 无按钮，需功能探针页 |
| M5 | 截图（`IScreenshot`）| `.../OpenHarmonyScreenshot.cs`（`OpenHarmonyScreenshot` / `OpenHarmonyScreenshotBridge`）| 无按钮，需功能探针页 |
| M6 | 地理编码（`IGeocoding`）| `.../OpenHarmonyGeocoding.cs` | 无按钮，需功能探针页 |
| M7 | 窗口生命周期 / 标题 / 每页安全区 | `.../OpenHarmonyMauiAppHost.cs`、`OpenHarmonyWindowHandler.cs`、`OpenHarmonySafeArea.cs`、`OpenHarmonySafeAreaArrange.cs`、`OpenHarmonyPageHandler.cs` | **部分可直接观察**（启动日志、状态栏/刘海安全区）|
| M8 | FontImageSource / SwitchCell / EntryCell / ImageButton | `.../OpenHarmonyImageHandler.cs`、`OpenHarmonyImageButtonHandler.cs`、`OpenHarmonyListViewHandler.cs` | 无按钮，需功能探针页 |
| M9 | 无障碍（节点树 / Announce / 自检）| `.../OpenHarmonyAccessibility.cs`、`OpenHarmonySemanticScreenReader.cs` | **可直接测**：壳左下角 `A11Y` 按钮 |
| M10 | Shell 扩展（SearchHandler / FlyoutHeader / FlyoutFooter / TabBarIsVisible / FlyoutBehavior）| `.../OpenHarmonyShellHandler.cs`、`OpenHarmonyShellExtras.cs` | 无入口（演示页用 FlyoutPage/TabbedPage，不是 Shell）|

宿主/壳侧对照：`ohos-workload:src/OpenHarmonyHost/host_napi.cpp`（导出与 sink）、
`ohos-workload:packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/templates/ets/pages/Index.ets`（`registerPermissionSink` / `registerClipboardSink` / `registerScreenshotSink` / `registerGeocodeSink` / `A11Y` 自检等）。

### 0.2 关键前提：当前演示页没有本轮新入口

交付包里 `hello-maui-app`（含 permissions 变体）的演示页源码是 `ohos-workload:test/hello-maui-app/App.cs`：
只有 HybridWebView / BlazorWebView / 计数器 / Entry / 值控件 / 列表 / 滚动 / 动画 / 手势等，**没有**权限、剪贴板、连通性、邮件短信拨号、截图、地理编码、FontImageSource、SwitchCell/EntryCell、ImageButton、Announce、Shell 搜索的按钮。

因此：

- **M1–M6、M8、M10 必须配合"功能探针 hap"才能逐项触发**。探针页由交付方构建（最小示意见附录 A，含权限声明命令），已带探针页时按下表逐项点按即可；**若你手上的包没有探针页，请只登记"本包无入口"，不要判失败**，并完成所有能做的间接检查（能启动/不崩、状态文件、module.json）。
- M7 的启动日志与安全区、M9 的 `A11Y` 按钮**在 kit #23/#24 上即可完成**；M11–M13 深化批里 **M12 的滚动惯性与自动隐藏滚动条在默认演示长列表上直接可测**，M11 的窗口激活需探针页挂 `Window.Created/Activated` 计数，其余项需探针页或重打包 hap——没有入口同样登记「未测（本包无入口）」，不要判失败。
- 同理，`验收说明.md` §4b 的 N1–N7（蓝牙/打印/联系人/日历等）也以各自界面入口是否存在为准；没有入口的项登记「未测（本包无入口）」，不要判失败。

### 0.3 证据：两类 `[maui]` 行，别找错地方

| 来源 | 位置 | 说明 |
|---|---|---|
| 托管侧 `[maui]` 行（权限超时、地理编码空结果、Shell 状态、生命周期、无障碍状态、构建横幅等）| **应用沙箱文件 `<filesDir>/dotnet-status.txt`**，不在 hilog | 路径通常为 `/data/app/el2/100/base/<bundleName>/files/dotnet-status.txt`；优先用 DevEco Studio 的 Device File Browser 导出；只有 hdc 时试 `hdc shell "ls /data/app/el2/100/base/<bundleName>/files"`，被权限拒绝就注明"取不到" |
| 壳（ArkTS）`[maui]` 行：console.info/error，如 `[maui] permission request failed:`、`[maui] ability start failed:`、`[maui] screenshot rejected:` | hilog | `tester-run.sh` 的过滤会命中（含 `maui`）|
| 宿主 `[openharmony-host]` 行（OH_LOG，如 `set_window_title` 警告；stderr 的 avoid area 行）| hilog 全量文件 | 过滤关键字 `openharmonyhost` **不含连字符**，可能漏掉；请在 `hilog/hilog-full.txt` 里另 grep `openharmony-host` |
| `PROBE1`–`PROBE4` | hilog | 仅启动崩溃探针用（见 §12）|

桥接 API 名（对照壳代码/排查用，不是日志关键字）：`host.permissionResult`、`host.clipboardResult`、`host.notifyClipboardChanged`、`host.notifyNetworkAccess`、`host.geocodeResult`、`host.notifyShellSearch`。

### 0.4 tester-run.sh 怎么用（本清单固定动作）

```sh
# 完整一轮（安装主包 -> 启动 -> 录 60 秒 hilog）；录制窗口内人工按 M1→M10 操作
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60

# 带功能探针 hap（可重复 --hap；主包取第一个）
sh tester-run.sh --kit-dir ./device-test-kit --install --hap ./hello-maui-app-probe.hap --start --capture 90

# 只录 hilog（自己在窗口内操作应用）
sh tester-run.sh --kit-dir ./device-test-kit --capture 60

# 启动崩溃探针 P1–P4（探针 hap 需先自签，见「自签说明.md」）
sh tester-run.sh --kit-dir ./device-test-kit --probes ./probes
```

归档 `tester-report-<时间戳>.tar.gz` 里有 `hilog/hilog-full.txt`、`hilog/hilog-filtered.txt`、`hilog/hilog-applib.txt`、`hilog/hilog-dlopen.txt`、`hilog/hilog-bootstrap.txt`、`hilog/hilog-execmem.txt`（kit #24：`OHOS_DOTNET probe:`/`xwe=` 行）、`kmsg/`、`device/app-libs-arm64.txt`、`device/payload-files.txt`、`device/payload-marker.txt`、`meta/kit-hap-sha256.txt`、`meta/kit-selfcheck.txt`、`probes/`、`summary.txt`（含 `script_version`、`main_hap_sha256`、`bootstrap_errors`/`rawfile_errors`/`libload_errors`、`payload_present`/`payload_marker`、`kit_index_ok`、`execmem_capture`/`execmem_lines` 等字段）。截图/录屏与 `dotnet-status.txt` **不在**归档内，需人工另发；失败项请标注发生时间点。

`tester-run.sh` 当前为 **v7**（`script_version=7`；kit #24 版脚本大小/摘要以 release 资产页「## Integrity」与随附 `gh api` 查询为准，本文不写死）：v6r2 的 `--tree-digest` 复用已校验摘要保持不变（P16，实测每轮少读 163.5 MB 量级）、证据包含 `meta/kit-hap-sha256.txt`/`main_hap_sha256`；v7 新增 bootstrap/rawfile 失败特征（`hilog-bootstrap.txt` + `bootstrap_errors`/`rawfile_errors`/`libload_errors`）、payload 状态（`payload-files`/`payload-marker` + `payload_present`/`payload_marker`）与 kit hap 自检（`meta/kit-selfcheck.txt` + `kit_index_ok`/`payload=yes|no`）；**kit #24 再增 execmem 采集**（`hilog-execmem.txt` + `execmem_capture`/`execmem_lines`，判定见 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`）。判定：`kit_index_ok=no` → 包早于 kit #22，换当前 kit 再测；`bootstrap_errors`/`rawfile_errors`>0 → 附 `hilog-bootstrap.txt` 回传（不影响退出码）；`payload_present=no` 在 kit #24 起属正常（payload 在 hap `libs/` 原地运行；该键只反映回退布局的 filesDir 解包，kit 自检 `payload=yes|no` 才是 marker 信号）。行为与输出字段对旧调用兼容。

### 0.5 自 kit #17 以来的变化（速览）与签名说明

- **安全**：bundleName 白名单校验（发任何 `hdc` 命令前）、hvigor 下载锚定、安装器 https + 哈希锚定、ElfSigner 数据保全、符号链接跳过、外来签名不静默洗白、URL 允许列表、反向回调守卫、路径规范化、TLS 绝对路径 `dlopen`。
- **性能**：套件帧分配 **241,688 → 4,504 B/帧**（present/图片/文本/触摸/轮播/rawfile 等热点已修；余 2 项有意保留并在扫描文档中记录）。
- **启动**：P17 启动跳过重复解压、H7 rawfile 文件描述符直读、headless 变体 abc `24.0.0.0` → `13.0.1.0`。
- **设备里程碑回灌（kit #22 起）**：宿主 `DT_NEEDED` 收窄为 5 库（缺库设备不再 dlopen 失败）、可选系统 API 全部按需 dlsym；HAP 内 `resources.index`（restool）；启动解压 ZIP offset/length 分块复制 + 解压前 mkdir；abc 工程对齐 DevEco（`modelVersion 6.0.2`）并带 hvigor 00302013 诊断。真机里程碑见 `docs/plans/2026-09-24-ohos-device-milestone.md`；stock kit（#22 起）尚未上机。
- **工具刷新（kit #23）**：`verify-kit.sh` 增加逐 hap 深度断言（`resources.index`/abc/libs/dotnet.zip/宿主依赖；FAIL → 退出码 1，WARN → 仍 `KIT OK`；kit #22 全过，kit #21 及更早会报真实 FAIL）；`tester-run.sh` 升到 v7（新增 bootstrap/rawfile/payload/kit 自检采集，见 §0.4）。
- **kit #24（payload-in-libs + JIT 判定装置）**：payload 直接进 hap `libs/arm64-v8a/`（`.dotnet-payload.json` 校验后原地启动，`dotnet.zip` 回退；签名 hap ~75.3 MB）；`verify-kit.sh` 逐 hap 断言 marker（缺失/不一致 = FAIL）；宿主显式 `DOTNET_EnableWriteXorExecute=0` + `xwe.txt` A/B + exec-memory 探针；`tester-run.sh` 采集 `hilog/hilog-execmem.txt`（`execmem_capture`/`execmem_lines`）；重建壳 abc 期望 `215680`/`18308`。不含 seccomp 拦截器（stock kit 直接测）。详见 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`。
- **签名说明**：kit #22 起 `签名说明.txt` 的「PA1 重建壳的下一版 kit」历史句已随源修复（`ohos-workload c6a4cd95e`）；若副本仍出现该句，按历史文案处理。

---

## M1 运行时权限（Permissions）

**入口**：功能探针页按钮（请求相机/麦克风/定位各一次 + 显示 `CheckStatusAsync` 结果）。kit #23 无入口。

**代码行为**：MAUI 权限类型映射为 OH 权限名后，经 `ohos_host_request_permission` 交给壳的 `abilityAccessCtrl.requestPermissionsFromUser`；结果由 `host.permissionResult(id, granted)` 回来；30 秒无应答按拒绝处理。`CheckStatusAsync` 走 `OH_AT_CheckSelfPermission`（不弹窗）。映射：Camera→`ohos.permission.CAMERA`、Microphone→`MICROPHONE`、LocationWhenInUse→`APPROXIMATELY_LOCATION`、LocationAlways→`LOCATION`、StorageRead/Photos→`READ_IMAGEVIDEO`、StorageWrite→`WRITE_IMAGEVIDEO`、Vibrate→`VIBRATE`、NetworkState→`GET_NETWORK_INFO`；未映射类型直接 `Denied`（`CheckStatusAsync` 为 `Unknown`）。

| 步骤 | 期望 | 证据 |
|---|---|---|
| 1. **确认权限已声明**：`unzip -p hello-maui-app-probe.hap module.json`，看 `requestPermissions` 含目标权限 | 声明齐全；未声明的权限不会弹窗（部分 ROM 直接报错） | module.json 原文 |
| 2. 点探针页「请求相机」 | **出现系统权限弹窗**（首次）；点允许后返回 `Granted` | 弹窗截图（弹窗一闪而过，事先准备好截屏）+ 探针页结果截图 |
| 3. 再点一次「请求相机」 | 已授权时**不再弹窗**，直接 `Granted` | 探针页结果 |
| 4. 点探针页「CheckStatus」 | 返回 `Granted` | 探针页结果截图 |
| 5. 另选一个权限点「请求」→ 弹窗中点**拒绝** | 返回 `Denied`；`CheckStatusAsync` 为 `Denied`；应用不崩 | 探针页结果 + 弹窗截图 |
| 6. 拒绝后再点同一权限 | **不再弹窗**（系统已记拒绝），直接 `Denied` | 探针页结果 |
| 7. 请求一个未映射类型（如 `Permissions.Battery`） | 不弹窗，直接 `Denied`；应用不崩 | 探针页结果 |
| 8. 若 30 秒内没有操作弹窗 | 超时后返回 `Denied`，并出现状态行 | `dotnet-status.txt`: `[maui] permission request for <权限名> was not answered; denying` |

**可能失败**：弹窗不出现（权限未声明、或壳 sink 未注册）；弹窗出现但结果恒 `Denied`；点允许后 `CheckStatusAsync` 仍 `Denied`（授权未落盘）；应用崩溃。**抓**：`dotnet-status.txt` 的 `permission request` 行；hilog 壳侧 `[maui] permission request failed: <msg>`；弹窗前后截图。

---

## M2 连通性（Connectivity）

**入口**：功能探针页（显示 `NetworkAccess` + `ConnectivityChanged` 次数/最后一次值）。kit #23 无入口。

**代码行为**：`NetworkAccess` 读宿主 NDK 级别（0 unknown / 1 none / 2 local / 3 internet）；壳订阅 NetworkKit 的 `netAvailable` / `netLost` / `netCapabilitiesChange` / `netUnavailable`，每次变化推 `host.notifyNetworkAccess`，宿主重读级别后触发 `ConnectivityChanged`。`ConnectionProfiles` **恒为空**（本桥不带传输类型，属预期，不是缺陷）。

| 步骤 | 期望 | 证据 |
|---|---|---|
| 1. 记下探针页初始 `NetworkAccess` | 联网时为 `Internet` | 探针页截图 |
| 2. 关闭 Wi-Fi/移动数据（或开飞行模式） | 值变为 `None`（或 `Local`，取决于 ROM 判级），`ConnectivityChanged` 次数 +1 | 变化前后截图 |
| 3. 恢复网络 | 值回到 `Internet`，事件次数再 +1 | 变化前后截图 |
| 4. 全程观察应用 | 不崩溃、不卡死 | 录屏/截图 |

**可能失败**：值恒 `Unknown`（宿主读失败/NetworkKit 缺失）；值不随网络变化（观察者未注册）；事件重复或缺失。**抓**：探针页数值截图；hilog `[maui] networkKit unavailable on this device: <msg>`（NetworkKit 导入失败时）；`dotnet-status.txt` 无专用行（该能力不写状态行）。

---

## M3 剪贴板（Clipboard）

**入口**：功能探针页（`HasText` 显示、`GetTextAsync` 按钮、`SetTextAsync` 按钮、`ClipboardContentChanged` 计数）。kit #23 无入口。

**代码行为**：读写走系统剪贴板（`@ohos.pasteboard`）。`HasText` 是同步值，来自缓存（get/set 与剪贴板 `update` 推送都会刷新，**不弹窗**）；只有显式 `GetTextAsync`（op 1）可能弹 `ohos.permission.READ_PASTEBOARD` 授权；拒绝会被缓存（壳与托管各一层），之后不再弹。`SetTextAsync` 不需要权限。**读必须声明 `READ_PASTEBOARD`**：默认 kit 包未声明，读会返回 `null`（不弹窗、不崩）；探针包请用下面的属性构建：

```sh
dotnet publish -c Release -r openharmony-arm64 \
  -p:OpenHarmonyUIPage=pages/Index \
  -p:OpenHarmonyArktsModulesAbc=<ohos-workload>/packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/templates/ets/modules.ui.abc \
  -p:OpenHarmonyHapPackage=true \
  -p:'OpenHarmonyExtraPermissions="ohos.permission.READ_PASTEBOARD"'
```

（`-p:` 参数整体单引号包裹，避免 shell 去引号导致 MSB1006；属性写法见随包 `验收说明.md` §1b。）

| 步骤 | 期望 | 证据 |
|---|---|---|
| 1. 点「SetTextAsync」写入 `m-probe-clip` | `HasText` 变为 `true`（不弹窗） | 探针页截图 |
| 2. 点「GetTextAsync」 | **首次弹** `READ_PASTEBOARD` 授权；允许后读到 `m-probe-clip` | 弹窗截图 + 探针页文本 |
| 3. 切到别的应用复制一段文字，再回探针页 | `ClipboardContentChanged` 次数 +1，`HasText` 为 `true` | 前后截图 |
| 4. 清空剪贴板（或复制非文本）后回探针页 | 事件仍触发（计数 +1），`HasText` 为 `false` | 截图 |
| 5. 若第 2 步点**拒绝** | `GetTextAsync` 返回 `null`；`HasText` 为 `false`；**再点不再弹窗**（拒绝已缓存）；应用不崩 | 探针页截图 |
| 6. 全程观察 | 剪贴板变化不会在后台弹出授权框 | 录屏 |

**可能失败**：授权后仍读不到文本；拒绝后仍反复弹窗；`HasText` 与实际不一致（缓存未刷新）；应用崩溃。**抓**：hilog 壳侧 `[maui] clipboard permission request failed: <msg>`、`[maui] clipboard op 1 failed: <msg>`、`[maui] clipboard observer unavailable: <msg>`；探针页截图。

---

## M4 邮件 / 短信 / 拨号

**入口**：功能探针页（`Email.Default.ComposeAsync` / `Sms.Default.ComposeAsync` / `PhoneDialer.Default.Open`）。kit #23 无入口。

**代码行为**：三者都经现有 startAbility 桥（隐式 `ohos.want.action.viewData` Want，kind 0）拉起系统应用：

- 邮件：`mailto:?to=…&cc=…&bcc=…&subject=…&body=…`（各值 URL 转义）；**附件不会带上**（一条 Want 只能带一个 mailto URI），带附件时仍打开撰写页并记一条日志。
- 短信：`sms:<收件人逗号分隔>[?body=…]`。
- 拨号：`tel:<号码>`；号码为 null/空白时按 MAUI 语义抛 `ArgumentNullException`（这是预期校验）。

| 步骤 | 期望 | 证据 |
|---|---|---|
| 1. 触发「写邮件」（带收件人/主题/正文）| 系统邮件应用打开，收件人/主题/正文已预填（具体外观取决于设备上的邮件应用）| 系统邮件截图 |
| 2. 触发「写短信」（带号码/正文）| 系统短信应用打开，号码/正文已预填 | 截图 |
| 3. 触发「拨号」 | 系统拨号盘打开并带入号码（不会直接拨出）| 截图 |
| 4. 触发带附件的邮件 | 撰写页打开，附件缺失；应用不崩 | 截图 + 状态行 `[maui] email compose dropped 1 attachment(s): the mailto bridge cannot carry files` |
| 5. 设备无邮件/短信应用（或未配置）| 应用保持稳定；系统日志出现派发失败 | hilog 壳侧 `[maui] ability start failed: kind=0 <message>`（无处理器时的可观察行为）|
| 6. 全程观察 | 点击后应用不崩溃、返回后界面正常 | 录屏 |

**可能失败**：系统应用没被拉起；字段为空/错位；点击后崩溃。**抓**：系统应用截图；hilog `[maui] ability start dispatched: kind=0`（派发成功）/ `[maui] ability start failed: kind=0 …` / `[maui] ability start threw: kind=0 …`；`dotnet-status.txt`: `[maui] email compose could not be dispatched`、`[maui] sms compose could not be dispatched`、`[maui] phone dialer could not be dispatched`。

---

## M5 截图（Screenshot）

**入口**：功能探针页（`Screenshot.Default.IsCaptureSupported` + `CaptureAsync`，显示 `Width×Height` 与字节数，并把 PNG `CopyToAsync` 到应用 cache 供取证）。kit #23 无入口。

**代码行为**：`IsCaptureSupported` 探测宿主是否导出 `ohos_host_screenshot`；不支持时 `CaptureAsync` 返回 `null`。支持时：管理端在临时目录生成 `maui-ohos-screenshot-<guid>.png`，宿主请求壳对主窗口 `snapshot()` 并写成 PNG；管理端轮询 ≤5 秒直到文件是**完整 PNG**（签名 + IHDR 尺寸 + IEND 尾块），读出后**删除临时文件**，返回内存结果；`Width/Height` 取 IHDR。请求 Jpeg 也返回同一份 PNG（本切片无转码器，属记录在案的偏差）。壳侧**包含性规则**：输出路径必须规范化后落在应用的 `tempDir`/`cacheDir` 之下，出现 `..` 或符号链接一律拒绝。

| 步骤 | 期望 | 证据 |
|---|---|---|
| 1. 查看探针页 `IsCaptureSupported` | 真机应为 `true` | 探针页截图 |
| 2. 点「截图」 | 返回结果，显示 `Width×Height`（= 窗口快照像素尺寸，可与设备分辨率/窗口尺寸对照）与 PNG 字节数（非 0）| 探针页截图 |
| 3. 把结果 `CopyToAsync` 到 `FileSystem.CacheDirectory/m-probe-shot.png`，导出后校验 | `file` 识别为 PNG；`python3 -c` 读前 24 字节：签名 `89 50 4E 47 0D 0A 1A 0A`、`IHDR` 尺寸与第 2 步一致、文件尾有 `IEND` | 导出文件 + `file`/`sha256sum` 输出 |
| 4. 连续截图 3 次 | 每次都成功；应用不崩 | 探针页截图 |
| 5. 检查应用临时目录 | 不残留 `maui-ohos-screenshot-*.png`（管理端读完即删）| `hdc shell ls` 或文件浏览器截图（取不到就注明）|

**可能失败**：`IsCaptureSupported=false`（宿主缺导出）；`CaptureAsync` 返回 `null`；5 秒内文件没写完；壳拒绝路径。**抓**：`dotnet-status.txt`: `[maui] screenshot request was not queued (host rc=<n>)`、`[maui] screenshot file was not written within 5000 ms`、`[maui] screenshot capture failed: <Type>`；hilog 壳侧 `[maui] screenshot rejected: output path is not under the app temp/cache dir`（若出现，原样回传——宿主/运行时的临时目录与壳允许的 `temp/cache` 不一致）、`[maui] screenshot failed: <msg>`、`[maui] imagePacker unavailable on this device: <msg>`。

---

## M6 地理编码（Geocoding）

**入口**：功能探针页（地址→坐标、坐标→地址各一次，显示条数与首条内容）。kit #23 无入口。

**代码行为**：地址→坐标（op 0）与坐标→地址（op 1）经宿主/壳请求 `@ohos.geoLocationManager`，15 秒无应答按"无结果"处理；返回 JSON 被宽容解析（`placeName→FeatureName`、`administrativeArea→AdminArea`、`streetNumber→SubThoroughfare` 等，也接受嵌套 `coordinates` 与 `lat/lon/lng` 拼写）；**任何失败/超时/格式错误都返回空结果，不抛异常**。坐标→地址在壳里按需申请 `ohos.permission.APPROXIMATELY_LOCATION`（需**已声明**才会弹窗；未声明则不弹、返回空）。

| 步骤 | 期望 | 证据 |
|---|---|---|
| 1. **确认声明**：探针包 `module.json` 的 `requestPermissions` 含 `ohos.permission.APPROXIMATELY_LOCATION`（否则看第 4 行）| 声明齐全 | module.json 原文 |
| 2. 「地址→坐标」输入一个已知地址（如所在城市的地标）| 返回 ≥1 条坐标，纬度/经度在合理范围；或在无网络时**干净地返回 0 条**（不崩）| 探针页截图 |
| 3. 「坐标→地址」输入设备附近的已知坐标 | 首次弹 `APPROXIMATELY_LOCATION` 授权；允许后返回 ≥1 条含地址字段（FeatureName/AdminArea 等）| 弹窗 + 结果截图 |
| 4. 第 3 步点**拒绝**权限 | 返回 0 条；应用不崩；不再反复弹窗 | 探针页截图 |
| 5. 乱填地址/非法坐标（如 `999,999`）| 返回 0 条，不抛异常、不崩 | 探针页截图 |

**可能失败**：一直返回空（权限/网络/Kit 缺失）；坐标明显错误（解析错位）；超时过长。**抓**：探针页输入/输出截图；hilog 壳侧 `[maui] geocode op <0/1> failed: <msg>`、`[maui] location permission request failed: <msg>`；`dotnet-status.txt`: `[maui] forward geocoding was not answered; returning no locations` / `[maui] reverse geocoding was not answered; returning no placemarks`。

---

## M7 窗口：生命周期 / 标题 / 安全区

**入口**：kit #23 直接可测（启动 + 观察页面布局）。

**代码行为**：应用启动时窗口先 `Created` 后 `Activated`（`Created` 由 `Run` 或平台 `Create` 事件中先到者触发且**恰好一次**），随后 `Foreground` / `Background` / `Destroy` 各写一行状态。`IWindow.Title` 被映射并**记录**，但本切片没有把它应用到壳的原生窗口（`OpenHarmonyWindowHandler.MapTitle` 只保存值，宿主导出 `ohos_host_set_window_title` 存在但托管未接）——**标题不会改变系统窗口/导航栏文字**，页面自身标题栏照常。安全区：壳上报系统避让区（状态栏/导航栏/刘海，类型 `TYPE_SYSTEM`），每页按 `SafeAreaEdges` 决定是否内缩（默认 Container：避开状态栏/导航栏/刘海；`SoftInput` **未跟踪键盘**，故键盘弹出不改变安全区内缩）。

| 步骤 | 期望 | 证据 |
|---|---|---|
| 1. 启动应用（`tester-run.sh --install --start --capture 30`）| 出现启动日志两行，顺序合理；应用不崩 | `dotnet-status.txt`: `[maui] window created (Window), content=<…>`、`[maui] lifecycle Create (window=Window)`，随后 `[maui] lifecycle Foreground` |
| 2. 按 Home 回桌面再回应用 | 出现 `Background`、再 `Foreground` | `dotnet-status.txt` 增量 |
| 3. 观察页面顶部/底部 | 状态栏、手势条、刘海**不遮挡**可交互内容；页面背景可铺满；**无避让区（无刘海且系统栏隐藏）时不应额外内缩**（与历史布局一致）| 有/无刘海对照截图（含状态栏）|
| 4. 旋转/改窗口大小（平板/2in1）| 内容重新排布、无越界；避让区在页面出现时上报**一次**（本轮未接系统变化监听），旋转后若不更新请如实记录 | 变化前后截图 |
| 5. 点 Entry 弹出软键盘 | 布局不因安全区跳变（本切片不跟踪键盘内缩；被键盘盖住属已知限制）| 键盘前后截图 |
| 6. （探针页/应用内部设置标题后）观察页面标题栏与系统窗口标题 | 页面标题栏显示正确；系统窗口标题**保持原样**（标题未接平台设置，属已知缺口）| 截图 + 对照说明 |

**可能失败**：只有 `Created` 没有 `Activated`（或重复 `Created` 抛错）；生命周期事件缺失；刘海设备上内容被遮挡；键盘弹出后页面跳变；旋转后避让区不更新。**抓**：`dotnet-status.txt` 全部 `[maui] window/lifecycle` 行；hilog 全量里的 `[openharmony-host] avoid area t=… b=… l=… r=…`；截图（有/无刘海、旋转前后对照）。

---

## M8 FontImageSource / SwitchCell / EntryCell / ImageButton

**入口**：功能探针页（4 组控件）。kit #23 无入口。

**代码行为**：`FontImageSource` 由合成器文字路径绘制（不是位图），按（字形/字体/字号/颜色/缩放）缓存；`ImageButton` 支持 file/stream/URI/FontImageSource 来源、`Aspect`、圆角、边框色/宽、背景色，按下/抬起映射 `IsPressed`，点击触发 `Clicked`；`ListView` 的 `SwitchCell` 渲染为「标签 + Switch」并把切换同步回 `cell.On`，`EntryCell` 渲染为「标签 + Entry」，沿用 Entry 的键盘与 `Completed` 行为。

| 步骤 | 期望 | 证据 |
|---|---|---|
| 1. 观察 FontImageSource 图像 | 字形可见（如 `\uf013`）、颜色/字号正确；不是空白或"豆腐块" | 截图 |
| 2. 观察 ImageButton（字体图标 + 文件图片两种）| 图像清晰不变形；圆角/边框/背景符合设定 | 截图 |
| 3. 按住 ImageButton 再松开 | 有按下/抬起视觉反馈；`Clicked` 计数 +1 | 按下/抬起截图 + 计数 |
| 4. ListView 里的 SwitchCell：点开关 | 开关切换；`cell.On` 同步（探针页显示值随之变化）| 前后截图 |
| 5. EntryCell：点输入框打字、按回车 | 键盘弹出、文本上屏；`Completed` 计数 +1 | 截图 |
| 6. 全程观察 | 不崩溃、不串行错位 | 录屏 |

**可能失败**：字形不渲染/乱码（字体族缺失）；ImageButton 无按下反馈或点击不触发；SwitchCell 状态不同步；EntryCell 键盘不弹/回车无事件。**抓**：截图/录屏；`dotnet-status.txt` 的 `[maui] image file not found: <path>` / `[maui] image load failed: <msg>`（文件来源失败时）。

---

## M9 无障碍（Accessibility）

**入口**：kit #23 **直接可测**：壳左下角半透明 `A11Y` 按钮 → 弹出 `Accessibility self-check` 对话框。Announce 需功能探针页。

**代码行为**：合成器自绘，无 ArkUI 节点树，因此托管侧构建影子节点树并经宿主注册 ArkUI provider（status：`0` 未附着 / `1` 已附着（理想）/ `2` frame node 被拒 / `3` CUSTOM 节点未创建 / `4` provider 拒绝）。对话框显示 `accessibilityStatus: N (…)`；宿主有新导出时附 `accessibilityNodeCount`。首次发布时写状态行。`SemanticScreenReader.Default.Announce(text)` 走携带文本的 `ohos_host_accessibility_announce`（provider 未附着时不发声、返回失败）；旧宿主回退到只带事件类型的老路径（文本仍记录）。CLICK 动作会回放进普通点击路径。

| 步骤 | 期望 | 证据 |
|---|---|---|
| 1. 应用启动后点左下角 `A11Y` | 对话框出现，显示 `accessibilityStatus: 1 (attached - expected)`；有节点数时为正整数 | 对话框截图 |
| 2. 若显示 0/2/3/4 | 原样拍照回传（含义见下方对照）| 对话框截图 |
| 3. 设置 → 辅助功能，开启系统读屏（屏幕朗读）| 读屏能聚焦应用内控件并朗读角色/文本；滑动切换焦点；双击激活按钮/开关 | 录屏/截图 |
| 4. 用读屏遍历到按钮并双击 | 按钮被激活（等价一次点按）| 录屏 |
| 5. 读屏下对输入框/滑块操作 | 输入框可聚焦并输入；滑块可用读屏手势调整（range 状态发布）| 录屏 |
| 6. （探针页）点「Announce」 | 系统读屏朗读所传文本；应用不崩 | 录屏 + 状态行 |
| 7. 观察状态行 | 出现一次 provider 状态 | `dotnet-status.txt`: `[maui] accessibility provider status=<N> (1=attached, 2=frame node, 3=node content)` |

**status 对照**：`0` 未附着（启动初值属预期）；`1` 已附着、回调注册成功（理想）；`2` 收到 frame node 但不是 CUSTOM 节点被拒；`3` 收到 NodeContent 但 CUSTOM 节点未创建/加入；`4` CUSTOM 节点已加入但 provider 拒绝。

**可能失败**：状态停在 0（provider 未注册）；2/3/4（附着链路问题）；读屏遍历不到控件；双击不激活；Announce 无声（状态非 1 时属预期）。**抓**：对话框截图；`dotnet-status.txt` 状态行与 `[maui] screen reader announce fell back to ohos_host_accessibility_send_event …`（旧宿主回退时）；读屏录屏。

---

## M10 Shell 扩展（SearchHandler / FlyoutHeader / FlyoutFooter / TabBarIsVisible / FlyoutBehavior）

**入口**：功能探针页（一个最小 `Shell`：2 个 ShellContent + 页内 `SearchHandler`、`Shell.FlyoutHeader/Footer`、切换 `TabBarIsVisible`/`FlyoutBehavior` 的按钮）。kit #23 无入口（演示页用 FlyoutPage/TabbedPage）。

**代码行为**：`FlyoutBehavior.Disabled` 隐藏汉堡并关闭抽屉；`Locked` 保持抽屉常开；`TabBarIsVisible` 取「当前页及其祖先最近一次显式值，否则 Shell 值，都未设则可见」，切换后重新排布内容；`FlyoutHeader/Footer` 为字符串或 `Label` 时，作为合成器抽屉面板的**首行/末行**纯文本出现（非交互行），富视图/模板本切片不能绘制；`SearchHandler` 的附着/查询/占位符/可见性只在托管侧跟踪并写一条状态行——**当前托管实现未调用宿主的 `ohos_host_shell_search_set`**（宿主/壳的搜索面板接口存在但托管未接），所以**屏上不会出现搜索框**，属记录在案的缺口。

| 步骤 | 期望 | 证据 |
|---|---|---|
| 1. 观察 Shell 底部标签栏 | 显示各 Shell 项标题，可点按切换 | 截图 |
| 2. 点「隐藏/显示 TabBar」| 底栏按 `TabBarIsVisible` 出现/消失，内容占满剩余区域 | 前后截图 |
| 3. 点抽屉/汉堡 | 抽屉开合；`FlyoutBehavior=Locked` 时保持常开（点空白处也不关），`Disabled` 时无汉堡 | 录屏/截图 |
| 4. 设置 `FlyoutHeader="HDR"` / `FlyoutFooter="FTR"` | 抽屉面板首行出现 `HDR`、末行出现 `FTR`（纯文本、不可点）；富视图不绘制属预期 | 抽屉截图 |
| 5. 页面带 `SearchHandler`（含 Placeholder/Query）| 托管状态行出现；**屏上不出现搜索框**（见上，属缺口）；应用不崩 | `dotnet-status.txt`: `[maui] shell search attached page='…' query='…' placeholder='…' enabled=… (no ArkTS bridge: needs ohos_host_shell_search_set/listener …; the managed state is observable meanwhile)` |
| 6. 若探针页提供搜索框（后续接桥后）| 输入 → `SearchHandler.Query` 更新；回车 → `QueryConfirmed()`；取消 → 清空 | 录屏 |

**可能失败**：底栏/抽屉行为与设置不符；header/footer 行缺失；状态行不出现。**抓**：截图/录屏；`dotnet-status.txt` 的 `[maui] shell search attached …` / `search detached` / `flyout header='…' footer='…'` 行。

---

## M11 真实缺陷修复（PI1 / 2026-09-23）

**入口**：**窗口激活（下表第 1 行）**在 kit 包上即可观察（状态文件 + 探针页计数）；其余 4 项需功能探针页。

**代码行为**：壳三份模板改发 `lifecycle Create=0`；宿主在 `Run` 之前收到 `Create` 时先 `Created`，窗口建好后立即补 `Activated`，两者各恰好一次。分组 `CarouselView`（`ItemsSource` 每项本身是非字符串集合）按「展平到项」物化幻灯片（组头/组尾画不出、只提示一次），页码用同一份展平结果计数。`IView.Shadow` 经宿主画布阴影层按偏移/模糊/单色绘制（跟随圆角），Shadow 变化请求重绘，非纯色画刷不绘制并提示一次。`SecureStorage` 优先 HUKS，HUKS 静默时回退每安装文件密钥并**只写一次**状态行。`OpenAppPackageFile*` 先查 payload 目录（`AppDir`，即解包后的 `dotnet.zip` 负载根），未命中再走 rawfile 桥（M13）。

**本轮前离机验证**：交互套件（315 条 `[verify]`）中的源码契约 pin（逐项见末列）；**无真机证据**。

| 项 | 步骤 | 期望 | 证据 | 本轮前离机验证 |
|---|---|---|---|---|
| **窗口 `Activated`**（参考 M7）| ① 启动应用（`tester-run.sh --install --start --capture 30`）后看状态文件；② 探针页读取挂在 `Window.Created` / `Window.Activated` 上的计数（显示 `created=N activated=N`）| `[maui] lifecycle Create (window=…)` 与 `[maui] window created (…), content=…` 都出现、都在 `[maui] lifecycle Foreground` 之前（两行相对顺序取决于壳的 Create 早于还是晚于 `Run`，都算通过）；`Created` 与 `Activated` **各恰好一次**、顺序 Created→Activated（修复前 Create 先到时 Activated 会丢）；无重复 `Created` 异常 | 状态文件两行片段 + 探针页计数截图 | 源码 pin（壳模板 `notifyLifecycle(0)` + 宿主 `_createReceived` / `EnsureWindowActivated`）；无行为测试 |
| **分组 `CarouselView`** | 探针页打开一个分组 `CarouselView`（`ItemsSource` 每项本身是小集合，如 3 组 × 2 项），左右滑动走完全部页 | 每「项」一页（例中共 6 页），不是每组一页；底部页码点数与页数一致；滑动/循环行为与普通 CarouselView 相同；不崩 | 首/中/末页截图（含页码点）+ `dotnet-status.txt`: `[maui] CarouselView.ItemsSource is grouped (every item is a collection): each group's items are shown as slides; group headers/footers cannot be expressed by this carousel`（一次）| 源码 pin（`MaterializeItems` 展平 + 页码取展平条数）|
| **阴影** | 探针页两组视图：① `Shadow` 用纯色 Brush（如黑色，`Offset=(6,6)`、`Radius=12`、`Opacity≈0.6`）；② 改用渐变/图片 Brush；③ 运行时改一次 ① 的 Shadow | ① 视图后出现阴影，偏移/模糊/颜色随设定；③ 无须别的交互即重画；圆角视图阴影跟随圆角；② 不画阴影、不崩、只提示一次 | ①/② 截图 + ③ 改动前后截图 + `[maui] IShadow.Paint '<类型名>' is not a solid colour: the OpenHarmony shadow layer carries a single colour, so this shadow was not drawn` | 源码 pin（`DrawShadow` + Shadow mapper 重绘 + 渲染器调用顺序）|
| **`SecureStorage` 回退** | 探针页（或默认包 F2 入口）写/读/删一个键；杀进程重开再读；看状态文件 | 读回一致、删除后为空（同 F2）；HUKS 静默时读写仍正常、不抛异常；状态行**只写一次**；重启后仍读得到 | 探针页截图 + `[maui] secure storage is using the per-install file key: HUKS is unavailable, values are obfuscated but not hardware-backed`（一次；HUKS 可用时不出现）| 源码 pin + 套件内 SecureStorage 读写行为（未断言该状态行）|
| **应用内资源解析** | 探针页分别读：① payload 文件（如 `hello-maui-app.dll`）；② 只在 rawfile 的文件（如 `app.json`，详见 M13）；③ payload 与 rawfile 同名的文件；④ 不存在的名字 | ① 有内容；② 有内容（需带 rawfile sink 的壳，见 M13）；③ 读到 **payload** 版本（payload 先查）；④ `FileNotFoundException` 且消息含所查名字 | 探针页文本 + 异常消息截图 + `dotnet-status.txt` 的 `raw file bridge unavailable`（仅旧壳/超限时）| 源码 pin（payload 目录解析 + `FileNotFoundException` 文案）+ rawfile scratch 驱动（payload 命中 / 桥命中 / 缺文件 / 空文件）|

**可能失败**：`Activated` 仍不触发（只有 `Created`）；重复 `Created` 抛错；分组 carousel 把整组当一页（屏上出现集合的 `ToString`）或页码与页数不一致；阴影不画 / 效果泄漏到别的内容 / 改 Shadow 不重画；`SecureStorage` 抛异常或状态行不出现；payload 资源读不到（`AppDir` 错）。**抓**：`dotnet-status.txt` 对应状态行；探针页截图；必要时附 `unzip -p … resources/rawfile/app.json` 对照。

---

## M12 UX 深化（PJ1/PJ2）

**入口**：**滚动惯性/自动隐藏滚动条**在默认演示长列表上直接可测；焦点环、Tooltip、加速键、Overlay 需探针页（Tooltip 需鼠标、加速键需键盘）。

**代码行为**：帧驱动动画循环（有动画才订阅帧，空闲不 tick）驱动滚动惯性（指数摩擦、到边精确夹紧；按下/程序化写入/`ScrollTo`/数据变化取消）与滚动条淡出；滚动条是右缘 4px 圆角细条，内容纵向溢出时出现，停滚约 0.9 秒后约 0.25 秒淡出；焦点环给 `IsFocused` 的非文本平台视图画 3px 内描边（跟随圆角）；Tooltip 监听 `ToolTip` 映射项，悬停 650ms 后在指针附近绘制文本气泡，移开/按下/触摸消失；加速键从键盘监听匹配，修饰键自跟踪并精确匹配，命中后按「Button 点击 / 菜单项激活 / 回调或 Command」派发；窗口 Overlay 由宿主在每帧 present 前绘制 `IWindow.Overlays` 中可见且已初始化的项，`IPlatformApplication.Current` 同期发布。

**本轮前离机验证**：交互套件中的源码契约 pin（逐项见末列）；**无真机证据**。

| 项 | 步骤 | 期望 | 证据 | 本轮前离机验证 |
|---|---|---|---|---|
| **滚动惯性 / 边缘夹紧** | 默认长列表：① 快速上滑后松手；② 滑到顶/底后继续甩；③ 惯性滑行中途按一下 | ① 松手后继续滑行并逐渐减速停下；② 到顶/底**精确停住**、不回弹/不越界；③ 按下立即停住；不漂移、不卡死 | 录屏（正常滑动 / 到边 / 中途按下）| 源码 pin（最小甩动速度 320px/s、摩擦 4.5/s、4 秒上限、边缘 clamp）；无真机行为数据 |
| **自动隐藏滚动条** | 长列表滚动一次，停止后静止看 2 秒 | 滚动时右缘出现 4px、白 35% 透明度的圆角细条（距边 3px）；停滚约 0.9s 后约 0.25s 淡出消失；内容不溢出时不出现；静止时无额外动画/重绘 | 滚动后立即截图 + 约 1.5s 后截图（对照）| 源码 pin（尺寸/停留/淡出常量）|
| **焦点环** | 探针页：① 对一个非文本控件调用 `Focus()`；② 再 `Unfocus()` 或让另一个控件聚焦 | 聚焦控件四周出现 3px 蓝色描边、跟随圆角、完整在边界内；移焦后消失；其他控件不乱画 | 聚焦前后截图 | 源码 pin（`FocusRing.Draw` + 平台视图 Draw 调用）；真机聚焦链路未验（`Focus()` 返回 false 时登记「未测」，不判失败）|
| **Tooltip（悬停延迟）** | **接鼠标**：① 悬停在设置了 `ToolTipProperties.SetText` 的控件上约 0.7s；② 移开；③ 悬停未满延迟时按下；④ 改文本后再悬停 | ① 约 650ms 后在指针附近弹出文本气泡；② 立即消失；③ 按下立即消失；④ 新文本生效；不吞点击/滚动 | 带时间戳截图或录屏 | 源码 pin（`ShowDelayMs=650` + SurfacePresent 链）；真机行为未验 |
| **键盘加速键** | 接键盘：探针页注册一个加速键（如 Ctrl+S，需交付方经切片内部入口接入）；依次按 Ctrl+S、只按 S、Ctrl+Shift+S；再试 Meta 组合 | 只有 Ctrl+S 触发一次（点击/命令计数 +1）；只按 S 与 Ctrl+Shift+S 不触发（修饰键**精确匹配**）；Meta 按 Cmd 与 Windows 语义匹配；无注册时键盘无副作用 | 录屏 + 计数截图 | 源码 pin（修饰键自跟踪、精确匹配、三层派发）；公开 rc.1 面没有元素级集合，真机入口由探针提供 |
| **窗口 Overlay / `IPlatformApplication.Current`** | 探针页：① 显示 `IPlatformApplication.Current != null`（冒烟）；② `Window.AddOverlay` 加一个自绘半透明 overlay；③ `RemoveOverlay`；④ `IsVisible=false` 再观察 | `Current` 非空且 `Current.Services` 可解析；overlay 画在页面内容之上、移除/隐藏后消失；触摸抬起对 `OpenHarmonyWindowOverlay` 派生 overlay 报 `Tapped`；**已知限制**：overlay 不拦截触摸（底层控件仍收到）| 加/移除前后截图 + 录屏 | 源码 pin（Overlay/宿主 present 链/应用对象发布）；无行为测试 |

**加速键键码（文档，`Key` 名称大小写不敏感）**：字母 A–Z = 2017–2042；数字 0–9 = 2000–2009（也认 D0..D9 / Number0..9）；F1–F12 = 2090–2101；方向键 = 2012–2015；Enter = 2054、Esc = 2070、Tab = 2049、Space = 2050、Backspace = 2055、Delete = 2071、Home = 2081、End = 2082、PageUp/PageDown = 2068/2069、Insert = 2083；`Key` 全为数字时直接按 ArkUI 数字码匹配（子集外的逃生口）。修饰键码：Alt 2045/2046、Shift 2047/2048、Ctrl 2072/2073、Meta 2076/2077（Meta 映射到 Cmd 与 Windows 两个标志）。

**可能失败**：滑动松手即停（惯性未启动）或到边回弹/越界；滚动条不出现或永不淡出（帧循环未退订，注意耗电）；焦点环不画（`Focus()` 未成功属未测）；Tooltip 不弹/延迟不符/移开不消失；加速键多按一个修饰键也触发；overlay 不画/移除后仍在/`Current` 为 null（库内解析平台服务会抛）。**抓**：录屏/截图；`dotnet-status.txt` 的 `IShadow.Paint …`（仅阴影项）；无专用行时以人工观察为准。

---

## M13 原始 HAP 资源桥（`resources/rawfile/**`）

**入口**：功能探针页的 rawfile 读取按钮（约定名如 `m-probe-raw.txt`；包内已有的 `app.json` 也可直接读）。重打包自测：用 zip 工具往 `hello-maui-app-unsigned.hap` 的 `resources/rawfile/` 加自己的文件（**不要动** `module.json` 与 `dotnet.zip`），按同包 `自签说明.md` 重签后安装。

**代码行为**：壳的 `registerRawFileSink` 用 `resourceManager` 读 `resources/rawfile/**`（op 0 读、op 1 探测存在），答案以 base64 单串回传（无临时文件/共享路径）；**8 MiB** 上限在三处生效（壳编码前、宿主参数、托管解码）；缺失（`9001005`）映射为「未找到」；缺文件在托管侧按约定抛 `FileNotFoundException`；旧壳/无 sink 退化为 `null`/`false`，并写一次 `[maui] raw file bridge unavailable (rc=-1)`（3 秒超时）。

| 步骤 | 期望 | 证据 |
|---|---|---|
| 1. 探针页读包内 rawfile（如 `app.json`，或重打包加入的 `m-probe-raw.txt`）| 返回内容与 hap 内条目一致；空文件返回空流、不抛异常 | 探针页文本截图 + `unzip -p hello-maui-app-unsigned.hap resources/rawfile/app.json` 对照 |
| 2. `AppPackageFileExistsAsync(同一名字)` | `true` | 探针页截图 |
| 3. 读一个不存在的名字（如 `nope.txt`）| `FileNotFoundException`，消息含所查名字（`App package file 'nope.txt' was not found.`）；**不挂起** | 异常消息截图 |
| 4. （重打包 hap）加入/替换 `resources/rawfile/m-probe-raw.txt` 并重签安装后再读 | 读到重打包后的新内容（rawfile 随 hap 走，不经过 payload 解包）| `unzip -l` 的条目 + 探针页截图 |
| 5. （可选，交付方探针）放一个 >8 MiB 的文件读它 | 与缺失一样得到 `FileNotFoundException`；状态行 `[maui] raw file bridge unavailable (rc=-3)`（一次）；不崩 | 状态文件 + 探针页截图 |

**可能失败**：旧壳上读到 `null`/`false` 并出现一次 `rc=-1` 行（登记「本包壳不支持」，不算失败）；超限不立即拒绝（长时间等待）；重打包后条目没进去或缺文件消息不含所查名字。**抓**：`dotnet-status.txt` 的 `raw file bridge unavailable` 行；hilog 壳侧 `[maui] rawfile read failed: <msg>`（读取异常时，一次）；**缺文件属正常答案、不写任何日志**。

**本轮前离机验证**：rawfile 桥的 scratch 驱动已覆盖 payload 命中（不走桥）、桥命中、缺文件 `FileNotFoundException`、空文件；宿主新符号与壳类型检查通过。真机与重打包 hap 均未验证。

---

## 11. 结果怎么填、往哪回传

每项按 `M1 通过/失败/未测 + 现象`，失败项附：

1. 步骤号与发生时间点；
2. 对应日志关键字行（`dotnet-status.txt` 片段与/或 hilog 片段）；
3. 截图/录屏文件名（例如 `M3-clipboard-prompt.png`）；
4. 若"无入口"（没有探针页），写 `M1 未测（本包无入口，无功能探针）`，不要写失败。

回传渠道与 kit 相同；整轮报告用 `tester-run.sh` 生成的 `tester-report-<时间戳>.tar.gz`（连同 `.sha256`），截图/状态文件另附。

## 12. 如果启动就崩（JsError / exit 254）

**症状**：`aa start` 后约 1 秒退出，hilog 出现 `AppKilledReporter` / `reason=JsError`，`exit 254`（见 hilog）。此时**先不要做本清单的功能项**（它们都建立在应用能稳定运行之上），按启动崩溃分支走：

1. 保留本轮 hilog（`hdc shell hilog -r` 后重录）与沙箱 `files/dotnet-status.txt`；
2. 用自签好的探针包跑 P1–P4：`sh tester-run.sh --kit-dir ./device-test-kit --probes ./probes`；
3. 按五层决策表读结论：**P1 失败** = 设备/框架/包波段问题；**P2 失败**（`…_FAIL=<dlerror>`）= 宿主 `.so` dlopen 问题；**P3 失败**（`dlsym.…=NULL`）= 宿主导出/链接命名空间问题；**P4 失败**（`PROBE4|<库名>|FAIL|<dlerror>`）= 缺依赖，库名就是答案；**P1–P4 全过** = 崩在 .NET 运行时/主启动，转 `dotnet-status.txt` + 100–200 行 hilog 取证；
4. 回传：探针 `PROBE1…PROBE4` 行原文 + 崩溃点前后各 200 行 hilog + 一个 jscrash 文件名（能取则取）。

参考（交付方文档）：`docs/plans/2026-09-21-ohos-crash-probes.md`（五层决策表）、`2026-09-21-ohos-device-crash-diagnostics.md`（取证与回传）、`2026-09-21-ohos-device-report-template.md`（一页模板）。

---

## 附录 A. 功能探针页最小示意（供交付方/有构建环境者）

> 目的：给 M1–M6、M8、M10 提供可点按入口。示意代码按需裁剪；把页面加进 `ohos-workload:test/hello-maui-app` 后用 §0.4 的发布命令打包（探针变体建议加 `-p:'OpenHarmonyExtraPermissions="ohos.permission.READ_PASTEBOARD;ohos.permission.APPROXIMATELY_LOCATION;ohos.permission.CAMERA;ohos.permission.MICROPHONE"'`）。

```csharp
// 探针页（示意）：每个按钮触发一条本轮能力，结果直接显示在页面标签上。
var log = new Label { FontSize = 22, LineBreakMode = LineBreakMode.WordWrap };
void Show(string text) => log.Text = text;

var permissions = new Button { Text = "M1 request camera" };
permissions.Clicked += async (_, _) =>
{
    var before = await Permissions.CheckStatusAsync<Permissions.Camera>();
    var result = await Permissions.RequestAsync<Permissions.Camera>();
    var after = await Permissions.CheckStatusAsync<Permissions.Camera>();
    Show($"permission before={before} request={result} after={after}");
};

var connectivity = new Button { Text = "M2 network access" };
int networkEvents = 0;
Connectivity.Current.ConnectivityChanged += (_, e) => networkEvents++;
connectivity.Clicked += (_, _) =>
    Show($"network={Connectivity.Current.NetworkAccess} events={networkEvents}");

var clipboard = new VerticalStackLayout();
int clipEvents = 0;
Clipboard.Default.ClipboardContentChanged += (_, _) => clipEvents++;
clipboard.Add(new Button { Text = "M3 set text" }.With(b => b.Clicked += async (_, _) =>
{
    await Clipboard.Default.SetTextAsync("m-probe-clip");
    Show($"hasText={Clipboard.Default.HasText} events={clipEvents}");
}));
clipboard.Add(new Button { Text = "M3 get text" }.With(b => b.Clicked += async (_, _) =>
    Show($"text='{await Clipboard.Default.GetTextAsync()}' hasText={Clipboard.Default.HasText} events={clipEvents}")));

var email = new Button { Text = "M4 email" };
email.Clicked += async (_, _) => await Email.Default.ComposeAsync(new EmailMessage
{
    To = new List<string> { "probe@example.com" }, Subject = "M4", Body = "m-probe",
});
var sms = new Button { Text = "M4 sms" };
sms.Clicked += async (_, _) => await Sms.Default.ComposeAsync(new SmsMessage("10086", "m-probe"));
var dial = new Button { Text = "M4 dial" };
dial.Clicked += (_, _) => PhoneDialer.Default.Open("10086");

var screenshot = new Button { Text = "M5 screenshot" };
screenshot.Clicked += async (_, _) =>
{
    if (!Screenshot.Default.IsCaptureSupported) { Show("screenshot unsupported"); return; }
    var shot = await Screenshot.Default.CaptureAsync();
    if (shot is null) { Show("capture returned null"); return; }
    string path = Path.Combine(FileSystem.CacheDirectory, "m-probe-shot.png");
    using (var stream = File.Create(path)) { await shot.CopyToAsync(stream); }
    Show($"png {shot.Width}x{shot.Height} -> {path}");
};

var geocode = new Button { Text = "M6 geocode" };
geocode.Clicked += async (_, _) =>
{
    var locations = (await Geocoding.Default.GetLocationsAsync("深圳市南山区")).ToList();
    var places = (await Geocoding.Default.GetPlacemarksAsync(22.53, 113.93)).ToList();
    Show($"locations={locations.Count} placemarks={places.Count}" +
        (places.Count > 0 ? $" first='{places[0].FeatureName}'" : string.Empty));
};

var announce = new Button { Text = "M9 announce" };
announce.Clicked += (_, _) => SemanticScreenReader.Default.Announce("m-probe announce");

var image = new Image { Source = new FontImageSource { Glyph = "\uf013", Size = 48, Color = Colors.OrangeRed } };
var imageButton = new ImageButton
{
    Source = new FontImageSource { Glyph = "\uf0f3", Size = 40, Color = Colors.White },
    BackgroundColor = Colors.DarkSlateBlue, CornerRadius = 12, BorderColor = Colors.Gold, BorderWidth = 2,
};
int imageClicks = 0;
imageButton.Clicked += (_, _) => Show($"imageButton clicks={++imageClicks}");

// Shell 扩展探针：单独用 Shell 包一个内容页（按钮切换 FlyoutBehavior / TabBarIsVisible / SearchHandler）。
// 把以上控件放进一个 VerticalStackLayout/ScrollView 作为页面 Content 即可。
```

（`With` 是示意扩展；实现时直接写事件订阅即可。`Screenshot`、`Geocoding`、`Email`、`Sms`、`PhoneDialer`、`SemanticScreenReader` 均为 MAUI Essentials 静态入口。）

## 附录 B. 关键字速查

| 项 | `dotnet-status.txt`（托管 `[maui]`）| hilog（壳 `[maui]` / 宿主 `[openharmony-host]`）|
|---|---|---|
| M1 权限 | `permission request for <name> was not answered; denying` | `[maui] permission request failed:` |
| M2 连通性 | —（无专用行）| `[maui] networkKit unavailable on this device:` |
| M3 剪贴板 | —（无日志；看探针页）| `[maui] clipboard permission request failed:`、`[maui] clipboard op <n> failed:`、`[maui] clipboard observer unavailable:` |
| M4 邮件/短信/拨号 | `email compose dropped <n> attachment(s)`、`… could not be dispatched` | `[maui] ability start dispatched: kind=0`、`ability start failed: kind=0`、`ability start threw: kind=0` |
| M5 截图 | `screenshot request was not queued (host rc=<n>)`、`screenshot file was not written within 5000 ms`、`screenshot capture failed:` | `[maui] screenshot rejected: output path is not under the app temp/cache dir`、`screenshot failed:`、`imagePacker unavailable on this device:` |
| M6 地理编码 | `forward geocoding was not answered; returning no locations`、`reverse geocoding was not answered; returning no placemarks` | `[maui] geocode op <0/1> failed:`、`location permission request failed:` |
| M7 窗口 | `window created (<Type>), content=`、`lifecycle <Create/Foreground/Background/Destroy>`、`lifecycle <e> ignored:` | `[openharmony-host] avoid area t=… b=… l=… r=…`、`[openharmony-host] set_window_title:` |
| M8 图像/控件 | `image file not found:`、`image load failed:` | （壳侧图像失败一般无 hilog）|
| M9 无障碍 | `accessibility provider status=<N>`、`screen reader announce fell back to …` | — |
| M10 Shell | `shell search attached …`、`search detached`、`flyout header='…' footer='…'` | — |
| 启动通用 | `[maui] openharmony build <ver> abi=<arch> provider=<n>`、`bridge attached: …` | `hellomaui`、`dotnet`、`libopenharmonyhost`、`AppKilledReporter`、`JsError`、`PROBE1..4` |
