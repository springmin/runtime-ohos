# Blazor 组件重签与验收操作卡（kit #39 · 一页版；含 CSP/no-csp 双 hap A/B + B2 WASM + `.razor` 挂载）

> **2026-10-02 更新（kit #39，当前）**：kit #39 = #38 + **FIX-BACKSIZE + FIX-BWVMount**（①**FIX-BACKSIZE**（maui `be09a48817` + 壳/宿主 `9e6519e`）：系统 Back 键经壳 `onBackPress(): boolean` → 宿主 `host.backPressed`/`ohos_host_register_back_pressed`（导出 **149→150**）**关闭抽屉**（第二次 Back 交回系统 `#BACKGROUND`）；`BlazorWebView` 覆写 `GetDesiredSize`（真实尺寸——此前 `Standard` 返回 0 → frame 退化被壳忽略、自身不出画）；hybrid 已注册时 Blazor frame 有意 withheld；②**FIX-BWVMount**（maui `52b082a071`）：**NativeAOT 下 `.razor` 组件真机挂载**——handler 静态构造触碰源生成 `JsonElement[]` 类型信息，使 WebView 包反射构造的 `ArrayConverter` 留在 AOT 镜像（此前 `AttachPage` 在包内抛错、组件不挂载）；`[maui] blazor start/connect` + `BLZ_DIAG` 可观测；FIX-HOME/FIX-ITOUCH/FIX-DISMISS/FIX-WVP 全量保留）；壳 abc **342,160（`ffda66da…`）**/headless **24,324（`798b2477…`）**、宿主 **293,792（`384e552a…`）**、导出 **150**、套件 **554/floor 534**；发布实测 tar **375,765,521 B / `e95eed49…`**、树 **`932e7955…`**、sidecar **`e5fc82de…`**；数字以 release「## Integrity（kit #39）」与随包校验为准；判定点 = `docs/plans/2026-10-02-ohos-tester-handoff-kit39.md`（#38 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #38，上一版）**：kit #38 = #37 + **FIX-DISMISS + FIX-WVP**（①**FIX-DISMISS**（maui `86b439ffc8`）：抽屉**外点不关闭**的根因 = `FlyoutPage.Default` 版式在非 Phone idiom/landscape 下关闭被 `InvalidOperationException` 守卫拒绝（异常被触摸回调边界吞掉、面板保持）→ 默认 `Default` 改置 **`Popover`**（overlay 抽屉），外点正常关闭并重绘；②**FIX-WVP**（maui `47d79add01` + 壳 `acbe750`）：Hybrid overlay 坐标 **px→vp**（frame 为设备像素、壳按 ArkUI vp 用 → ×1.9 落窗外）、hybrid origin `https://0.0.0.1/` **注册仲裁**（后到 Blazor 只武装不加载）、`Web` 后置到 `ContentSlot` 之上（z-order 真出画）、抽屉/切 tab 时 **suspend/resume/hide** 状态机 + `WebCommandSent` 诊断）；FIX-HOME/FIX-ITOUCH 全量保留；壳 abc **341,560（`4f02cb1d…`）**/headless **24,324（`798b2477…`）**、宿主 **293,792（`4e9f3c3e…`）**、导出 **149**、套件 **550/floor 530**；**FIX-BACK 波次未入包**（Back 关抽屉 / BlazorWebView 尺寸在途，将随下一版）；发布实测 tar **375,641,619 B / `ced5583f…`**、树 **`307004e1…`**、sidecar **`8982fad0…`**；数字以 release「## Integrity（kit #38）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit38.md`（#37 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #37，上一版）**：kit #37 = #36 + **FIX-HOME + FIX-ITOUCH**（①**FIX-HOME**（maui 切片 `68ec598037`）：`OpenHarmonyNavigationPageHandler.PlatformArrange` 下钻 `CurrentPage`（safe-area walk + arrange 防递归标记）——Home tab（FlyoutPage→TabbedPage→NavigationPage）不再停在 `-1x-1`，AOT 真机首屏整页出画（截图 `fix-home/device/home-cold.jpeg`）；交互套件 +4 pin；②**FIX-ITOUCH**（宿主 `4e9f3c3e`）：`OnTouch` 改读 touch point **element** 坐标（与鼠标同一 surface 空间；free window 的 window 系含 70 px 系统标题栏 → 注入点击整体下移）——uitest 注入点击命中内容元素（"fading out…" → "animations done"）、偏心探针不误命中、tab 切换不变；宿主 UND 240→238）；壳 abc 字节不变 **339,964（`fc54d2b8…`）/24,324（`798b2477…`）**、hap 内宿主 **293,792（`4e9f3c3e…`）**、导出 **149**、套件 **544/floor 524**；发布实测 tar **375,652,577 B / `3a7259d6…`**、树 **`ab517b57…`**、sidecar **`7db60a77…`**；数字以 release「## Integrity（kit #37）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit37.md`（#36 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #36，上一版）**：kit #36 = #35 + **payload 原地直载（AOT 路径真机 BLZ）+ host 预注册缓冲 + 像素 Known 清零 + a11y 渲染帧修复 + rc.2 AOT pack `-r2`**（①壳 `findLibsPayloadDir` 兼容模块布局 `<bundleCodeDir>/<module>/libs/<abi>`——真机 hello-maui-wasm 直接自 `/data/storage/el1/bundle/entry/libs/arm64` 原地启动（`dotnet.zip not unpacked`，pid 49565）且 `BLZ_BOOT`/`BLZ_RENDERED` 双标记齐；②host 缓冲壳 `registerWebSink` 注册前到达的 web 命令（16 条 / 64 KiB，注册即 flush；套件 pin `moduleRoot`/`webPending`）；③像素套件不再有 `Known(...)`（selection tint 改字节量化精确断言 `#3959B3`）；④a11y `nodeCount 0` 根因 = shadow tree 未 publish，S2a pin `renderAttached=True`、`--a11y-probe` 实测 `status=1`、nodeCount 5/24 稳定；⑤rc.2 AOT pack 修正版 `-r2`（28,904,657 B / `542058cf…`，asset 601289590）修复 OpenSSL shim → 撤 rc.1 钉）；新壳 abc **339,964（`fc54d2b8…`）/24,324（`798b2477…`）**、hap 内宿主 **293,792（`cfbbe461…`）**、导出 **149**、套件 **540/floor 520**；发布实测 tar **375,627,841 B / `9eb9cecf…`**、树 **`9764827c…`**、sidecar **`4d7062c3…`**；数字以 release「## Integrity（kit #36）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit36.md`（#35 = 上一版，见其交接文）。
> **2026-09-30 更新（kit #35，上一版）**：kit #35 = #34 + **W9/W10 并入主线**（W9A **B2：MAUI WebView 承载 Blazor WASM**——真机 `BLZ_BOOT`/`BLZ_RENDERED` 打通（pid 6157），#34 的 AOT 入口缺口由 W10 修复；W9B T14 收尾 + T21 字体缩放；W9C T8 不等高 TableView；W9D **T20 媒体传输层**（本机镜像无 MediaKit 属预期，`IsSupported=false` 降级不抛）+ T19 深链判定（热 `delivered=1`）；W10 **AOT 入口修复**（宿主自身 libs 解析 `lib<stem>.so` + `dotnet-status.txt` 可观测、壳 AOT payload 探针/`fs` 别名/静态资源指纹；rc.2 AOT 包 OpenSSL shim 缺陷 → 本地钉 rc.1）；新壳 abc **339,164（`74054e2d…`）**/headless **23,516（`6bce4063…`）**、hap 内宿主 **293,792（`983e8f74…`）**、导出 **149**、套件 **540/floor 520**；发布实测 tar **375,629,423 B / `419d42e2…`**、树 **`d3b1b317…`**、sidecar **`d7e79d39…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `2dd447a7…`**（发布已完成，以 release「## Integrity（kit #35）」与随包校验为准）；判定点 = `docs/plans/2026-09-30-ohos-tester-handoff-kit35.md`（#34 = 上一版，见其交接文）。

> 日期口径：文件名按撰写日；kit #32 发布日 = **2026-09-28**，数字以 release「## Integrity（kit #32）」为准（#31 发布日 = 2026-09-28）。

> 对象：kit #39（承 #33–#38；#35 起 B2 = MAUI WebView 内嵌 Blazor WASM 已在真机打通：`BLZ_BOOT`/`BLZ_RENDERED`；#36 起 payload 原地直载（AOT 路径真机 BLZ）；#37 起 Home 整页出画 + 注入点击命中；#38 起 Hybrid overlay px→vp / hybrid origin 仲裁 / 挂起；#39 起 `BlazorWebView.GetDesiredSize` 真实尺寸 + **NativeAOT `.razor` 组件挂载出画**、系统 Back 关抽屉）的 Blazor 宿主 hap（**默认 CSP 与 `-nocsp` 双变体，各重签/各装一次做 A/B**，判定表见 `2026-09-29-ohos-blazor-regression-retest-card.md`）；原 #32 条目：第 6 个 hap `hello-blazorwasm-host-unsigned.hap`（#31 起；**#32 起无 INTERNET**，重签保持；#32 = **26,803,570 B / `5011cf73…`**（0 权限），#31 = 26,794,931 B / `36010a9c…`；bundle **`com.example.opendotnet`**）；流程 = 重签 → 安装 → 启动 → 自动/人工判读 → 失败回传；细节见包内《自签说明》与 `2026-09-28-ohos-tester-handoff-kit32.md` §2。

## 1. 取件

- 解出 `hello-blazorwasm-host-unsigned.hap`（只拿这一个文件也可操作）；**kit #32 起该 hap 无 `ohos.permission.INTERNET`**（rawfile 直供；重签不修改 module.json，重签后保持）；kit #32 实测 tar **207,114,608 B / `8f690949…`**、sidecar `344760e7…`、tree `645879bc…`、Blazor hap **26,803,570 B / `5011cf73…`**（0 权限）；以随包 `SHA256SUMS`/`.tar.gz.sha256` 为准（#31 = 207,023,588 / `f4325d2f…`、26,794,931 / `36010a9c…` 对照）；重签后哈希必变，以新产出 + 新验签为准。

## 2. 重签（与 MAUI 未签包同流程）

1. **bundle + 材料/UDID**：自签工程 `AppScope/app.json5` 的 `bundleName` = `com.example.opendotnet`（否则属性校验失败）；DevEco「Automatically generate signature」得 `*.p12`/`*.cer`/`*.p7b` + `keyAlias`（默认 `debugKey`），profile 的 `debug-info.device-ids` 必须含 `hdc shell bm get -u` 的 UDID。
2. **签名 + 验签**：`hap-sign-tool sign-app -keyAlias <alias> -signAlg SHA256withECDSA -mode localSign -signCode 1 -appCertFile <cer> -profileFile <p7b> -inFile hello-blazorwasm-host-unsigned.hap -outFile blazor-signed.hap -keystoreFile <p12> -pwdInputMode 1`（**`-signCode 1` 必带**；**口令不进 argv**）→ 同 SDK `hap-sign-tool verify-app -inFile blazor-signed.hap -outCertChain out.cer -outProfile out.p7b`。
3. 路线 B（材料发回、我方预签）：p7b + p12 + cer + keyAlias 走安全通道 → `sh scripts/sign-for-device.sh --external --profile <p7b> --key <p12> --cert <cer> --key-alias <alias> --pwd-input-mode --expect-udid <UDID>`（口令不进 argv，fail closed）。

## 3. 安装 / 启动

```sh
hdc install -r blazor-signed.hap        # 或：hdc shell bm install -p /data/local/tmp/blazor-signed.hap
hdc shell aa start -b com.example.opendotnet -a EntryAbility
```

## 4. 自动判读（必过；启动后 3–5 s）

```sh
hdc shell "hilog -x | grep BlazorWebHost"    # 期望：marker: BLZ_BOOT 与 marker: BLZ_RENDERED
```

- 两条都在 = 通过；出现 `marker: BLZ_ERROR <msg>` = 失败（原文记录并回传）。一键版（推荐）：`sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe`（**tester-run 版本以包内自述为准（#32 = v14）**；标记只认宿主 pid + session nonce；失败自动落 `blazor-hilog.txt`）。

## 5. 人工判读（截图 1 张）

- 首屏 = “Hello from Blazor WebAssembly”（无白屏 / 错误页 / 持续加载）；进入 `/counter` 点一次 `Click me`：计数 0 → 1（路由 + 事件 + interop 全通）。

## 6. 失败回传

- `hdc shell hilog -x > blazor-hilog.txt`（须含 `BlazorWebHost` / `BLZ_ERROR` 行）+ 截图 1 张；可附 `hdc shell bm dump -n com.example.opendotnet`。

## 7. 常见问题

| 现象 | 原因 / 处理 |
|---|---|
| 安装失败（bundle 不一致） | 第 2.1 步：自签工程 bundleName 必须 = `com.example.opendotnet` |
| `9568257`（未重签）/ `9568344`（profile 未绑 UDID） | 属预期：按第 2 节重签后再装 |
| 有 `BLZ_BOOT` 无 `BLZ_RENDERED`（首帧超时） | 先看 `BLZ_ERROR` 原文：多为 WASM/ArkWeb 能力或 rawfile 供给；原样回传 hilog + 截图 |
| 白屏排查序 | ① `aa start` 已启动 → ② 有 `BLZ_BOOT`（宿主页面已载）→ ③ 看 `BLZ_ERROR` → ④ 截图 + `blazor-hilog.txt` 回传 |
