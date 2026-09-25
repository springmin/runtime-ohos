# OpenHarmony .NET/MAUI 真机测试快速上手（外部测试方）

> 拿到交付包后：怎么装、先测什么、回传什么。结论以你设备上的实测为准。
> 当前发布 = **kit #25**（2026-09-25，权限链 + Share/Scan 探测降级 + AOT 启动路径）：`libs/arm64-v8a/` 原地携带 254 个 payload 文件与 `.dotnet-payload.json`（签名 hap ~75.43 MB；`dotnet.zip` 254 项仅作回退）；5 项权限变体补齐 `reason`/`usedScene`（运行时授权弹窗应显示理由文案）；Share/Scan 在 OpenHarmony SDK 上探测为 `shareDispatch=False`/`scanSupported=False` 并干净降级（`ARKTS_SDK_FLAVOR=harmony` 的 HarmonyOS SDK 变体才启用面板/扫码）；宿主新增 AOT 启动路径（`lib<stem>.so` → `openharmony_app_main`，hostfxr 回退）。主选就是 kit #25 本身（含 kit #22 起的设备回灌、#24 的 payload-in-libs/显式 W^X=0 与自 #17 起全部安全/性能/启动修复）。对照载荷（dynpkg/normalized/importb/importd/importprobe a–c）与 P1–P4 探针仍在同一 release，按交付方指示取用；本轮判定点（权限弹窗文案 / Share 面板 / Scan 返回 / AOT 启动）见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`。
> **设备里程碑（2026-09-24）**：kit #18 + 测试方 5 项本地修复后首次完整运行成功（`managed app hello-maui-app.dll started (UI shell)`、进程存活、无崩溃）；**stock kit（#22 起，含本轮 #25）尚未上机**，本轮就是它的首次设备复测。详见 `docs/plans/2026-09-24-ohos-device-milestone.md`。

## 1. 下载与校验

交付包在 `springmin/sdk-ohos` 的 release **`device-test-kit`**；同一资产也镜像在滚动 release **`workload-latest`**（二选一下载）：

```sh
base=https://github.com/springmin/sdk-ohos/releases/download
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz"   # 镜像：$base/workload-latest/device-test-kit.tar.gz
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz.sha256"
sha256sum -c device-test-kit.tar.gz.sha256        # ① 压缩包传输校验（外层 .tar.gz.sha256）
mkdir -p device-test-kit && tar xzf device-test-kit.tar.gz -C device-test-kit
cd device-test-kit
sh verify-kit.sh \
  --anchor "$(awk '{print $1}' ../device-test-kit.tar.gz.sha256)" \
  --anchor-file ../device-test-kit.tar.gz         # ② 包内逐文件校验 + tar.gz 文件锚定
sh verify-kit.sh --expect-tree-digest <device-test-kit 发布说明「## Integrity」中的 tree sha256>   # ③ 绑定解压内容树
# 发布说明没给 tree sha256 时，先打印再人工比对：sh verify-kit.sh --tree-digest
```

**先校验外层 `.tar.gz.sha256`，再解压**：包内的 `SHA256SUMS` 与文件在同一个压缩包里，只能证明包内自洽；`--anchor`（或 `KIT_ANCHOR`）只校验磁盘上的 `.tar.gz` 文件本身是发布件，**不能**证明解压出来的目录与其一致（解压发生在本脚本之外）。因此要绑定"解压后的内容"用内容树摘要：交付方在 `device-test-kit` release 说明的「## Integrity」小节给出 `tree sha256`（本文件不复述固定值），用 `--expect-tree-digest <hex>`（或 `KIT_TREE_DIGEST=<hex>`）校验，不匹配会直接失败；发布说明未给出该值时，可用 `--tree-digest` 打印后人工比对。**正确顺序：先校验压缩包（①），再解压，最后校验内容树（③）。**

> **verify-kit 变严了（kit #23 起；旧包会 FAIL 属预期）**：kit #23 包内 `verify-kit.sh` 在逐文件校验之外，逐 hap 断言 `resources.index`（缺/空 = FAIL）、abc 版本 `13.0.1.0` 与当前壳大小、`libs/arm64-v8a` 14 个 `.so`、`dotnet.zip` 不含 `.so`、宿主 ELF `DT_NEEDED`/未定义符号白名单。FAIL → 退出码 1；WARN → 打印但仍是 `KIT OK`。**kit #24 起再加 payload-in-libs 断言**：每个 hap 的 `libs/arm64-v8a/.dotnet-payload.json` 必须存在且自洽（入口程序集已入 libs、条目数与实际文件数一致、`payloadEntries == zipEntries`、`zipSha256` 匹配打包字节），缺失/不一致 = FAIL（该 hap 会回退到被设备拒绝的 data 目录解包）。**kit #25 的期望值更新为**：abc `234620`/`18532`（旧壳大小仍按 WARN 提示）、`dotnet.zip` 254 项、`resources.index` 上限 2 KiB（1588/1780）。**kit #22 全部通过；kit #21 及更早的包会被明确报 FAIL（缺 index、旧宿主 NEEDED 等真实缺陷），不是误报** —— 旧包请用它自带的 verify-kit，强化结果请用 kit #22+（当前 #25）。新增可选参数 `--expected-abc` / `--host-deps`，`--anchor`/`--tree-digest` 用法不变。

包内自带 **`SHA256SUMS`**，含 5 个 hap（4 个**自签名** + 1 个**未签名**）、8 个说明文档、`签名说明.txt` 与 `verify-kit.sh`；**每次重签哈希都会变**，一律以随包的 `SHA256SUMS` / `.sha256` 为准（内容树摘要由发布方在 release 说明「## Integrity」中给出）。

> **签名状态（先读，2026-09-22 真机实测）**：4 个默认 hap 是**自签名（设备会拒绝，需要重签）** —— 用我方调试证书/调试 profile 签名，profile 只绑定示例设备 UDID，
> 真机安装会报 `9568257 fail to verify pkcs7 file` 或 `9568344 install parse profile prop check error`，**这是预期结果，重试无用**。
> 能安装的只有 `hello-maui-app-unsigned.hap` **用你自己的华为账号自动签名后**的产物（也可回传 UDID 由我们重签，或改用发布方预签包；详见包内 `签名说明.txt`）。
> 重签一行（路径/密码换成你的，完整步骤见 `自签说明.md`）：
> `hap-sign-tool sign-app -keyAlias debugKey -signAlg SHA256withECDSA -mode localSign -signCode 1 -appCertFile <你的>.cer -profileFile <你的>.p7b -inFile hello-maui-app-unsigned.hap -outFile hello-maui-app-yourself.hap -keystoreFile <你的>.p12 -keyPwd "<key密码>" -keystorePwd "<store密码>"`
>
> **关于包内 `签名说明.txt`**：kit #22 起「PA1 重建壳的下一版 kit」历史句已随源修复（`ohos-workload c6a4cd95e`）；若你手上副本仍出现该句，按历史文案处理，判读以 `签名说明` 其余内容与 release notes 为准。

**哈希一律以发布说明为准，本文不写死**：整包 sha256 与解压内容树 sha256 见 `device-test-kit` release 说明的「## Integrity」小节（`workload-latest` 镜像同值），③ 的参数就用那里的 tree sha256；`tester-run.sh`（v8）会把整包摘要与主 hap 摘要写进证据包 `meta/kit-hap-sha256.txt` 与 `summary.txt` 的 `main_hap_sha256`，可直接对照。当前发布为 **kit #25**（2026-09-25；权限链 + Share/Scan 探测降级 + AOT 启动路径；`tester-run.sh` 仍为 v8），包内版本原文见 `最终状态.md`「发布物」/`README-交付说明.md`「构建基线」。重签、预签或重新打包后的哈希必然不同 —— 以发布说明与随包 `SHA256SUMS` 为准。

## 1b. 自 kit #17 以来的变化（速览）

- **安全**：bundleName 白名单校验（发任何 `hdc` 命令前）、hvigor 下载锚定、安装器 https + 哈希锚定、ElfSigner 数据保全、符号链接跳过、外来签名不静默洗白、URL 允许列表、反向回调守卫、路径规范化、TLS 绝对路径 `dlopen`。
- **性能**：交互套件帧分配 **241,688 → 4,504 B/帧**（present/图片/文本/触摸/轮播/rawfile 等热点已修；余 2 项有意保留并在文档中记录）。
- **启动**：P17 启动跳过重复解压、H7 rawfile 文件描述符直读、headless 变体 abc `24.0.0.0` → `13.0.1.0`。
- **设备里程碑回灌（kit #22 起）**：宿主 `DT_NEEDED` 只剩 5 个（缺库设备也能 dlopen），可选系统库/API（IME、Vibrator、Sensor、Location、NetConn、ImageSource 等）全部按需 dlsym；HAP 内带 `resources.index`（restool）；启动解压按 ZIP offset/length 分块复制并在解压前建目录；abc 工程对齐 DevEco（`modelVersion 6.0.2`）并带 hvigor 00302013 诊断。
- **工具刷新（kit #23）**：`verify-kit.sh` 增加逐 hap 深度断言（index/abc/libs/dotnet.zip/宿主依赖，FAIL 才退出 1）；`tester-run.sh` 升到 v7（新增 bootstrap/rawfile 失败特征、payload 状态与 kit 自检采集，见 §6）。**kit #24** 再把 `tester-run.sh` 升到 **v8**（新增 execmem 采集与 kit 自检 `payload=yes|no`）。
- **kit #24（payload-in-libs + JIT 判定装置）**：payload 直接进 hap `libs/arm64-v8a/`（marker 校验后原地启动，`dotnet.zip` 回退；签名 hap ~75.3 MB）；宿主显式 `DOTNET_EnableWriteXorExecute=0`、`xwe.txt` A/B（`xwe=0|1 source=default|file`）与 exec-memory 探针（`OHOS_DOTNET probe: 1=… 2=… 3=… 4=…`）；`tester-run.sh` v8 采集 `hilog/hilog-execmem.txt`（`summary.txt` 的 `execmem_capture`/`execmem_lines`）。kit #24 不含上轮的 seccomp 拦截器（不再需要，且会 strip `PROT_EXEC`）：请直接用 stock kit 重测。JIT 判定表与 NativeAOT 指引见 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`。
- **kit #25（权限链 + Share/Scan 探测 + AOT 启动路径）**：权限变体的 5 项权限补齐 `reason`（`$string:permission_reason_*`）与 `usedScene`（`EntryAbility`、`when=inuse`）——运行时授权弹窗应显示**理由文案**；Share/Scan 用 `canIUse`+变量 import 探测，OpenHarmony SDK 上降级为 `shareDispatch=False`/`scanSupported=False`（sink 不注册，不崩），HarmonyOS SDK 变体（`ARKTS_SDK_FLAVOR=harmony`）才启用系统分享面板/扫码；宿主新增 AOT 启动路径（`lib<stem>.so` → `openharmony_app_main`，hostfxr 回退）。指纹：hap ~75.43 MB（zip 278；`libs` 269 = 14 `.so` + 254 payload + marker）、abc 234,620/18,532、宿主 240,544（hap 内）/236,448（pack）、index 1588/1780、`dotnet.zip` 254/0 `.so`。判定点见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`。
- 主选仍是 **kit #25 本身**（含 `libIsolation` 与全部修复）；对照载荷与探针只在交付方指定时使用。

## 2. 选哪个 hap

| hap | 用途 |
|---|---|
| `hello-maui-app.hap` | **默认包**（无额外权限）：UI、交互、手势、IME、通知、安全区、WebView、无障碍、Hybrid；**自签名，设备会拒绝，需要重签** |
| `hello-maui-app-permissions.hap` | 追加蓝牙/打印/联系人/日历（首次使用弹运行时授权；PRINT 为 system_grant 不弹）；**自签名，设备会拒绝，需要重签** |
| `hello-maui-app-api20.hap` | API 20 波段设备；band 值 `60000020` 解码为**平台 6.0.0 / API 20**；**自签名，设备会拒绝，需要重签** |
| `hello-maui-app-api20-permissions.hap` | 同上，带权限；**自签名，设备会拒绝，需要重签** |
| `hello-maui-app-unsigned.hap` | **未签名**（同 26 默认包）；**本包唯一可重签安装的变体**：用你自己的华为账号自动签名后再装，见 `自签说明.md` |

设备 API ≥26 用默认包；只有 API 20 波段设备才用 api20 包。

当前 kit 的 5 个 hap 均为合法 `bundleName`（`com.example.hellomauiapp`）且按设备波段打包：**无需改名、无需改 `module.json`**（上轮的重命名/波段手改请勿再带入）。

## 3. 安装

1. **无需安装 .NET 运行时**：运行时随 hap 打包 —— kit #24 起 payload 直接位于 hap `libs/arm64-v8a/`（marker 校验通过时原地启动），`resources/rawfile/dotnet.zip` 仍保留为回退。
2. 把 hap 拷到设备（U 盘/文件管理器/局域网），在**文件管理器中打开**该 hap，按提示安装。
3. 需要**开发者模式** + 允许调试/外部来源安装（设置 → 安全，各 ROM 名称略有差异）。
4. 设备允许 hdc 时：先重签（见 §1 签名状态）；`hdc install <重签后的 hap>`；启动用 `hdc shell aa start -a EntryAbility -b com.example.hellomauiapp`，或直接点桌面图标（首帧为黑色导航栏 + 标题「Root」的长列表）。

## 4. 报 `9568257` / `9568344`（自签名被拒 / profile 未绑定你的 UDID）

- `9568257 fail to verify pkcs7 file`：4 个默认 hap 是**自签名（设备会拒绝，需要重签）** —— 设备不信任我方调试签名，属预期结果；先按 `自签说明.md` 重签 `hello-maui-app-unsigned.hap` 再装（详见包内 `签名说明.txt`）。
- `9568344 install parse profile prop check error`：调试 profile **只绑定了示例设备 UDID**。三选一：

- 把本机 **UDID** 发回（`hdc shell bm get -u`，或 DevEco Studio → Device Manager → 设备信息）→ 我们按 UDID 重签发新包（哈希会变）；
- 按 `签名与UDID指南.md` 用 DevEco 自动签名后自助重签；
- 把 **p7b + p12 + cer + keyAlias**（p12 密码走安全通道）发回 → 我们用 `ohos-workload/scripts/sign-for-device.sh --external --profile <你的.p7b> --key <你的.p12> --cert <你的.cer> --key-alias <alias> --pwd-input-mode --expect-udid 60CF7B27…`（UDID 换成你的）按其 UDID **预签**（p7b 的 `debug-info.device-ids` 必须含该 UDID；细节见 `签名与UDID指南.md` §4c）。

另：`E00C001 Operation restricted by the organization` = 设备策略关闭了 hdc → 改用文件管理器安装。

## 5. 五分钟测试路径（先跑这 5 条）

| # | 操作 | 通过标准 |
|---|---|---|
| 1 | 启动应用，看首帧 | 无花屏/黑块；文字清晰、控件不重叠、安全区不遮挡 |
| 2 | 打开一个 `DisplayAlert`（应用内「显示弹窗」）| 遮罩+对话框出现；「取消/确定」分别返回 false/true |
| 3 | 在 Entry 里打字（中英混输）| 键盘弹出、光标可见、上屏无重字/漏字、收起后布局恢复 |
| 4 | 打开 Hybrid 演示页，点按钮触发 JS→.NET | 调用返回结果并回显（`Echo`/`Add`）|
| 5 | 点左下角小按钮 **`A11Y`** | 弹出 Accessibility self-check（`accessibilityStatus` + 节点数）|

失败就记下步骤和现象；完整清单见 `验收说明.md`（A1–K2、N1–N7）。

**启动即退（约 1 秒退出 / `exit 254` / `JsError`）先确认不是旧 kit**：`ReferenceError: Cannot find module 'ets/entryability/EntryAbility' , which is application Entry Point`（入口 record 缺陷）已在 kit #10 修复并由真机确认，abc 版本（kit #11）与宿主加载（kit #12）分支也已清除 —— **kit #25 不含这些旧缺陷**（背景见 `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md`）。当前启动相关修复：P17 跳过重复解压、H7 rawfile 文件描述符直读、headless 变体 abc `13.0.1.0`；kit #22 的设备回灌（宿主 5 个 `DT_NEEDED` + 可选 API 全部 dlsym、HAP `resources.index`、ZIP offset/length + mkdir）、kit #24 的 payload-in-libs/显式 W^X=0 与 kit #25 的 AOT 启动路径（app export + hostfxr 回退）；stock kit（#22 起，含 #25）仍未上机。若在当前 kit 上仍崩：先照 `docs/plans/2026-09-21-ohos-device-crash-diagnostics.md` 取最小证据，再用 `tester-run.sh`（v8）跑 P1–P4 探针阶梯 —— `docs/plans/2026-09-21-ohos-crash-probes.md` 有探针下载地址、五层定位决策表，以及**免安装的 14 库自检**（`hdc shell ls -l /system/lib64/…`）。当前 kit 的 hap 已随包 `libs/arm64-v8a/libc++_shared.so`（SDK ElfSigner 重签，修上轮 P4 指出的缺库分支）并带启动诊断 hilog，请先用本包重测再判读探针。

## 6. 回传什么

**两条启动行**（应用日志区；有 hdc 时 `hdc hilog` 过滤应用包名，无 hdc 请截图）：

| 行 | 说明 |
|---|---|
| `[maui] openharmony build <ver> abi=<arch> provider=<n>` | 构建版本 + ABI + provider 值；启动早期出现，`provider=0` 属预期 |
| `[maui] accessibility provider status=<n>` | provider 附着状态；**1 = 已附着（理想）** |

`<n>` 映射（0–4；界面显示 unknown status 的更大值请原样回传）：

| 值 | 含义 |
|---|---|
| 0 | 未附着（启动初值，属预期）|
| 1 | 已附着、回调注册成功（理想）|
| 2 | 收到 frame node，但因不是 CUSTOM 节点被拒 |
| 3 | 收到 NodeContent，但 CUSTOM 节点未创建/加入 |
| 4 | CUSTOM 节点已加入，但 provider 拒绝 |

**关键字摘录**：`bluetooth` / `print` / `contacts` / `calendar` / `share` / `scan` / `HybridWebView`、`__hwvInvokeDotNet` / `webview`、`eval` / `notification` / `picker`、`camera` / IME 输入法系统日志（完整表见 `验收说明.md` §5b）。

**结果模板**：优先用一页版 `docs/plans/2026-09-21-ohos-device-report-template.md`（照抄填空，含 kit 哈希/版本核对与探针栏；A1–K2、N1–N7 逐项仍按 `验收说明.md` §6）。安装失败附**完整错误文案**；有 hdc 时附 `hdc hilog > log.txt` 片段与各失败项时间点；启动崩溃另附 P1–P4 探针结果与 hilog 崩溃点前后各 200 行。

**tester-run v8 证据包**（字段与旧版兼容）：归档内已含 `hilog/hilog-applib.txt`（`SetAppLibPath|appLibPathKey|NativeLibPath|lib path`）、`hilog/hilog-dlopen.txt`（`dlopen|cannot find library|openharmonyhost`）、`device/app-libs-arm64.txt`、`meta/kit-hap-sha256.txt` 与 `summary.txt` 的 `main_hap_sha256`；v7 新增 `hilog/hilog-bootstrap.txt`（bootstrap/rawfile 失败特征）、`device/payload-files.txt`/`device/payload-marker.txt`、`meta/kit-selfcheck.txt`，以及 `summary.txt` 的 `bootstrap_errors`/`rawfile_errors`/`libload_errors`/`payload_present`/`payload_marker`/`kit_index_ok` 等键。**v8（kit #24 起，kit #25 沿用）再增 execmem 采集**：`hilog/hilog-execmem.txt`（`OHOS_DOTNET probe:` 与 `xwe=` 行；`summary.txt` 的 `execmem_capture`/`execmem_lines`，0 = 未捕获，加长 `--capture` 重跑；kit 自检另加 `payload=yes|no`），判定表见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md` §3（指向 kit #24 交接的 `probe:`×`xwe` 判定表）。判定建议：`kit_index_ok=no` → 换 kit #22+ 再测；`payload_present=no` 在 kit #24 起属**正常**（payload 在 hap `libs/` 原地运行，该键只看回退布局的 filesDir 解包；本地 kit 自检的 `payload=yes|no` 才是 marker 信号；回退布局/旧包首次启动前也为 no）；`bootstrap_errors`/`rawfile_errors>0` → 附 `hilog-bootstrap.txt` 回传（不因此判失败）。`--tree-digest` 因 P16 复用已校验摘要明显更快，结果不变。

## 7. 相关文档

- 完整验收：`docs/plans/2026-09-19-ohos-hap-acceptance-for-testers.md`（包内 `验收说明.md`）
- 签名/UDID：`docs/plans/2026-09-19-ohos-signing-and-udid-guide.md`（包内 `签名与UDID指南.md`）
- 上手（开发）：`docs/plans/2026-09-20-ohos-dotnet-getting-started.md`
- 启动崩溃取证：`docs/plans/2026-09-21-ohos-device-crash-diagnostics.md`
- 崩溃探针 P1–P4 与决策表：`docs/plans/2026-09-21-ohos-crash-probes.md`（4 个未签名 hap 挂在 `device-test-kit` release）
- 启动崩溃根因（2026-09-22 定论）：`docs/plans/2026-09-22-ohos-startup-crash-rootcause.md`
- 真机里程碑（2026-09-24，kit #22 回灌与复测判定点）：`docs/plans/2026-09-24-ohos-device-milestone.md`
- **kit #25 交接（权限弹窗文案 / Share 面板 / Scan 返回 / AOT 启动判定点）：`docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`**
- kit #24 交接（JIT A/B、`probe:`×`xwe` 判定表、NativeAOT 主路线）：`docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`
- MAUI 平台切片（NativeAOT 阻塞 #4.2）：`docs/plans/2026-09-24-ohos-nativeaot-maui-slice.md`
- 运行时策略与部署模型（JIT/解释器/NativeAOT 取舍）：`docs/plans/2026-09-24-ohos-runtime-strategy.md`、`docs/plans/2026-09-24-ohos-runtime-deployment-models.md`
- 回传模板（一页）：`docs/plans/2026-09-21-ohos-device-report-template.md`
