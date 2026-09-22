# 2026-09-22 新功能真机验证清单（测试者版）

> 面向拿到 `device-test-kit`（kit #7，preview.24 基线）与 `tester-run.sh` 的测试者：验证本轮（2026-09-22）落地的 MAUI on OpenHarmony 新能力。
> 与 `验收说明.md`（A1–K2、N1–N7）互补：A–N 覆盖既有能力，本清单覆盖 **M1–M10**。
> 逐项格式：**入口 → 步骤 → 期望 → 证据（抓什么）→ 可能失败**。绝大多数步骤需人工操作：`tester-run.sh` 只能自动**安装 / 启动 / 录 hilog / 跑启动崩溃探针**，触发 UI、切换系统设置、接受弹窗、截图、取沙箱文件都要人工完成。

---

## 0. 先读

### 0.1 本轮范围与托管实现锚点

代码位于 `maui-ohos`（托管切片）与 `ohos-workload`（宿主/ArkTS 壳）；下表路径省略前两个仓名。

| # | 能力 | 托管实现（锚点文件） | kit #7 现有入口 |
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
- M7 的启动日志与安全区、M9 的 `A11Y` 按钮**在 kit #7 上即可完成**。
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

归档 `tester-report-<时间戳>.tar.gz` 里有 `hilog/hilog-full.txt`、`hilog/hilog-filtered.txt`、`probes/`、`summary.txt`。截图/录屏与 `dotnet-status.txt` **不在**归档内，需人工另发；失败项请标注发生时间点。

---

## M1 运行时权限（Permissions）

**入口**：功能探针页按钮（请求相机/麦克风/定位各一次 + 显示 `CheckStatusAsync` 结果）。kit #7 无入口。

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

**入口**：功能探针页（显示 `NetworkAccess` + `ConnectivityChanged` 次数/最后一次值）。kit #7 无入口。

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

**入口**：功能探针页（`HasText` 显示、`GetTextAsync` 按钮、`SetTextAsync` 按钮、`ClipboardContentChanged` 计数）。kit #7 无入口。

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

**入口**：功能探针页（`Email.Default.ComposeAsync` / `Sms.Default.ComposeAsync` / `PhoneDialer.Default.Open`）。kit #7 无入口。

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

**入口**：功能探针页（`Screenshot.Default.IsCaptureSupported` + `CaptureAsync`，显示 `Width×Height` 与字节数，并把 PNG `CopyToAsync` 到应用 cache 供取证）。kit #7 无入口。

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

**入口**：功能探针页（地址→坐标、坐标→地址各一次，显示条数与首条内容）。kit #7 无入口。

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

**入口**：kit #7 直接可测（启动 + 观察页面布局）。

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

**入口**：功能探针页（4 组控件）。kit #7 无入口。

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

**入口**：kit #7 **直接可测**：壳左下角半透明 `A11Y` 按钮 → 弹出 `Accessibility self-check` 对话框。Announce 需功能探针页。

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

**入口**：功能探针页（一个最小 `Shell`：2 个 ShellContent + 页内 `SearchHandler`、`Shell.FlyoutHeader/Footer`、切换 `TabBarIsVisible`/`FlyoutBehavior` 的按钮）。kit #7 无入口（演示页用 FlyoutPage/TabbedPage）。

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
