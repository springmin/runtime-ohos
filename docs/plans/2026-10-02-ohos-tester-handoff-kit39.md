# 测试方交接：kit #39、FIX-BACKSIZE（Back 关抽屉 + BlazorWebView 真实尺寸）+ FIX-BWVMount（NativeAOT `.razor` 挂载）（2026-10-02）

> 日期口径：文件名按撰写日；**kit #39 发布实测（release「## Integrity（kit #39）」；发布已完成，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **375,765,521 B / `e95eed49…`**、树
> **`932e7955…`**、sidecar **`e5fc82de…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `f7871fa8…`**
> （#38 = tar **375,641,619 B / `ced5583f…`** 对照）。重签/重打包后哈希必变；CI run id 见 §7。
> 构建基线（rc.2 线，同 #34–#38）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（承 #36，保持）**：rc.2 NativeAOT OpenHarmony pack 用修正版资产
> **`Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.2.26451.112-r2.nupkg`**
> （28,904,657 B / `542058cf…`，release `aot-packs-11.0.0-rc.2` asset 601289590）；**rc.1 钉保持撤销**。
> **在途/后续项（明确）**：计数按钮往返（count>0）截图在途复核；一条 `hybrid message rejected` 为 Hybrid
> 静态 sink 噪声（设计内）；多覆盖层（单 ArkWeb）仍为后续——相关项登记「未测（在途）」不判失败。

> 结论先行：kit #39 = **kit #38 + 两项**：①**FIX-BACKSIZE**——系统 Back 键此前只把窗口收后台（平台在页面
> `onKeyEvent` 前消费；壳/宿主只注册触摸、无按键转发）；`BlazorWebView` 因切片编译 `ViewHandlerOfT.Standard`
> （`GetDesiredSize => Size.Zero`）排 0 高 frame → 退化被壳忽略、自身不出画。修复：切片 `OpenHarmonyFlyoutPageHandler`/
> `OpenHarmonyShellHandler` 订阅 `OpenHarmonyBridge.BackPressed`（开抽屉时回写 `IsPresented`/`FlyoutOpen` 并返回 true，
> 否则 false 交回系统）+ `OpenHarmonyBlazorWebViewHandler.GetDesiredSize`（宽=约束、高=min(400,约束) 或
> `HeightRequest`）+ hybrid 已注册时 withhold frame（maui `be09a48817`）；壳 `onBackPress(): boolean`（abc 升
> **342,160/`ffda66da…`**）+ 宿主 `host.backPressed`/`ohos_host_register_back_pressed`（导出 **149→150**，
> host 升 **384e552a…**）+ hosting `BackPressed`/`CompleteBackPressed`（ow `9e6519e`）。设备：开抽屉 → Back →
> `web cmd resume` + `#FOREGROUND`（**Back 关抽屉**）；再 Back → `#BACKGROUND`；`hello-maui-razor` 页在控件
> frame 内出画（RSTree `Web [547,501][2573,1101]`）。②**FIX-BWVMount**——WebView 包把每个 `__bwv:` 载荷解析为
> `JsonElement[]`（自有静态 options、**reflection-only** resolver）；NativeAOT 下反射构造的
> `ArrayConverter<JsonElement[], JsonElement>` 无本地代码，`AttachPage` 在包内抛错 → `.razor` 组件不挂载
> （host 页本身正常，故表现为"组件缺失"而非崩溃）。修复：handler 静态构造触碰源生成
> `OpenHarmonySliceJsonContext.Default.GetTypeInfo(typeof(JsonElement[]))`，把数组转换器（及元数据）留在 AOT 镜像
> （不动包自身 options）；加 `[maui] blazor start/connect` + diag dispatcher + `BLZ_DIAG` 消息探针（maui `52b082a071`；
> razor 样例计数器往返 ow `11ef0fc`）。设备：`BLZ_DIAG message accepted → dispatch in → enqueue → run → send`
> （`AttachPage`→`AttachToDocument`）+ 截图出现 **"BlazorWebView component (.razor)"** + `count: 0` + "Blazor click"
> 按钮。**FIX-HOME/FIX-ITOUCH/FIX-DISMISS/FIX-WVP 全量保留。壳 abc 342,160（`ffda66da…`）/ headless 24,324
> （`798b2477…`）、宿主 293,792（`384e552a…`，UND 238）、导出 150/150、套件 554/floor 534（+4 FIX-BACKSIZE pin；由 550/530 起）**。
> 判定点见 §2；承接 #38/#37/#36/#35/#34/#33 的判定点**继续有效**，本文只覆盖 #39 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（同 #38：runtime_mode 键、execmem、a11y 可选）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 探针（B2 走 MAUI WebView 内嵌 WASM；判定继续有效）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段用本轮 AOT 资产；rc.2 pack 用 -r2 feed，rc.1 钉保持撤销）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；#35–#39 本批未刷新）

`device-test-kit` release 自 #34 起有并列预签资产 **`preSigned-haps.tar.gz`**（asset 600101072，
375,834,798 B / `b492b284…`）：7 hap 全部按 **tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`**
预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装、无需重签**（同 bundle 换件仍先卸载）；
非 tester UDID 设备报 `9568344` → 回传 UDID 重出或按包内 README 自签。**#35–#39 本批未刷新预签件
（沿 #34 件；#39 如需预签请回传 UDID 代签）**；预签包是并列附加件，完整一轮仍用 `device-test-kit.tar.gz`。

## 1. kit #39 相对 #38 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **FIX-BACKSIZE（Back 关抽屉 + BlazorWebView 尺寸）** | 现象：系统 Back 只把窗口收后台（平台在页面 `onKeyEvent` 前消费 Back；壳/宿主无按键转发）；BlazorWebView `GetDesiredSize=0` → 0 高 frame 退化被壳忽略、控件不出画；修尺寸后连带暴露：BlazorWebView frame 会把单 ArkWeb 覆盖层从已注册 hybrid 的页面挪走（hybrid 区空白）。修复 = 切片订阅 `OpenHarmonyBridge.BackPressed`（抽屉开时回写并返回 true；否则交回系统）+ `GetDesiredSize`（宽=约束、高=min(400,约束) 或 `HeightRequest`）+ hybrid 已注册时 withhold frame；壳 `onBackPress(): boolean` + 宿主 `host.backPressed`/`ohos_host_register_back_pressed`（**导出 149→150**）+ hosting `BackPressed`。设备：d1 开抽屉（`web cmd suspend`×2）→ d2 Back → `web cmd resume` + `#FOREGROUND`（**Back 关抽屉**）；d3 再 Back → `#BACKGROUND`；d0 vs d2 像素 mean **0.068**（抽屉全关）、hybrid 区与 FIX-WVP `w0-home` mean **0.0**；`hello-maui-razor` 页在控件 frame 内出画（RSTree `Web [547,501][2573,1101]`，非整窗） | 抽屉开 → Back 关抽屉（仍 FOREGROUND）；再 Back 收后台；BlazorWebView 在控件 frame 内出画 |
| 1.2 | **FIX-BWVMount（NativeAOT `.razor` 挂载）** | 现象：host 页出画、桥对象齐全，但 `.razor` 组件不挂载；每 ~3s 一条 `hybrid message rejected`（Hybrid 静态 sink 噪声），页面持续发 `__bwv:` attach 消息在 WebView 包内失败。根因：包用自有静态 options（reflection-only）把 `__bwv:` 解析为 `JsonElement[]`，NativeAOT 下反射构造的 `ArrayConverter<JsonElement[], JsonElement>` 无本地代码 → `AttachPage` 抛错（host 页只需桥对象，故表现为"组件缺失"非崩溃）。修复 = handler 静态构造触碰源生成 `OpenHarmonySliceJsonContext.Default.GetTypeInfo(typeof(JsonElement[]))`，把转换器及元数据留在 AOT 镜像。设备：`[maui] blazor connect: hostPage=wwwroot/index.html services=set`；`BLZ_DIAG message accepted head=__bwv:["AttachPage",…]` → `dispatch in / enqueue / run` → `send head=__bwv:["AttachToDocument",0,"#app"]`；截图出现 "MAUI + Razor on OpenHarmony" → "host page loaded; shell bridge: …" → **"BlazorWebView component (.razor)"** + `count: 0` + "Blazor click" 按钮 | `.razor` 组件挂载出画（组件区 + count + 按钮）；`[maui] blazor start/connect` + `BLZ_DIAG` 行；计数往返见 §1.4 |
| 1.3 | **门禁/指纹/7 hap** | 交互套件 **554/floor 534**（+4 FIX-BACKSIZE pin：Back 转发/抽屉下钻 + BlazorWebView desired size；`verifyCheckTotal` 550→554、floor 530→534，只增不降）、像素 `PIXEL ASSERTIONS PASSED`（无 `Known`）、宿主导出契约 **150/150**（+`ohos_host_register_back_pressed`）、host **UND 238**/DT_NEEDED 5/denylist 0；**新壳 abc 342,160（`ffda66da…`）/ headless 24,324（`798b2477…`）**（`Index.ets 297,005/81e7d9b1`、provenance `d07e1f26`）、hap 内宿主 **293,792（`384e552a…`）**；payload Hosting **68,608（`9d9facd9…`）**（was 67,072，桥）；`verify-kit` 期望已重锚 **342160/24324**（脚本 `0b7dbfe9…`）；7 hap 重签（见表 §6.3） | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**（abc 期望 342160/24324）；套件自报行 `[suite] checks=554 total=554 floor=534 assert=True` |
| 1.4 | **在途/后续项（明确）** | 本批**未决**：计数按钮往返（点 "Blazor click" → `count>0`）截图仍在途（时序 vs 采轮，未决定性）；一条 `hybrid message rejected` 为 Hybrid 静态 sink 噪声（设计内）；**多覆盖层**（同页多 web 控件共享单 ArkWeb；hybrid 已注册时 Blazor frame 有意 withheld；Blazor-only 页不受影响）仍为后续 | 登记「未测（在途）」，**不判失败**；计数往返如取到决定性证据请附截图/hilog |

> 尺寸预算：以 release 资产表为准（#38 = 375,641,619 B；#39 = 375,765,521 B，delta = 壳/宿主/桥 + 5 MAUI hap 重建）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **Back 关抽屉（主判点 1）** | AOT 件冷启 Home → 开抽屉 → 系统 Back | 抽屉**关闭**且窗口仍 `#FOREGROUND`（`web cmd resume`）；再 Back → `#BACKGROUND`；无 `touch callback failed` | 抽屉前后截图 + hilog |
| **BlazorWebView 尺寸（主判点 1b）** | 打开 BlazorWebView 页 | 控件在自身 frame 内出画（非整窗/非退化；RSTree 有 `Web` 节点）；hybrid 区不被挪走 | 截图 + RSTree + hilog |
| **`.razor` 挂载（主判点 2）** | 打开 razor 页 | 页内出现 **"BlazorWebView component (.razor)"** + `count: 0` + "Blazor click"；`[maui] blazor start/connect` + `BLZ_DIAG`（accepted→dispatch→enqueue→run→send） | 截图 + hilog |
| **计数往返（在途）** | 点 "Blazor click" | `count` 递增（>0）且截图/hilog 双证 | **在途复核项**；未决定性不判失败 |
| **套件基座** | 有源码测试者跑 `test/maui-platform-verify` | `[suite] checks=554 total=554 floor=534 assert=True`；4 条 fix pin 绿；导出 150/150 | 终端输出 |
| **承 #38：FIX-DISMISS / FIX-WVP** | 抽屉外点关闭；Hybrid 出画 + bridge | 同 #38 期望（外点关、`origin https://0.0.0.1/`、`hybrid raw message`、挂起恢复） | 截图 + hilog |
| **承 #37：FIX-HOME / FIX-ITOUCH** | Home 首屏；注入点击页内元素 | Home 整页出画 + 切走/切回；注入命中（element 坐标） | 截图 + hilog |
| **承 #36：payload/a11y/像素/AOT `-r2`** | 见 `2026-10-01-ohos-tester-handoff-kit36.md` §2 | hilog `payload-in-libs: running from …`；`status=1`/nodeCount 5/24；像素无 `Known`；`-r2` AOT 构建成立 | hilog + `a11y/` + 终端 |
| **承 #35：W9/W10** | 按 handoff #36 §2（B2/T14/T21/T8/T20/T19/AOT 入口） | 同 #35–#38 期望；套件自报行 `554/floor 534` | 截图 + hilog + `dotnet-status.txt` |
| **承 #34：rc.2 版本自述 + W6/W7/W8** | 包内《最终状态.md》/`README-交付说明.md`；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6 | SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；逐项同 #34 | 自述原文 + 截图 + `--a11y-probe` |
| **承 #33：Blazor 双 hap A/B / TabbedPage / W5** | 按 #33 判定树与一页卡 | 同 #33 期望（默认 ✅ → CSP 非瓶颈；默认 ❌ nocsp ✅ → CSP 至少次因） | `BLZ_BOOT`/`BLZ_RENDERED` + 截图 |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项（出画/点击/截图）照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#38）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.2.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（承 #36）**：用 `-r2` 修正版 pack（asset 601289590）；设备/本机 AOT 构建无需本地 hooks；
   最小复现与判据见 `docs/plans/2026-09-30-rc2-aotpack-openssl-shim-fix.md` §1/§4。
3. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`（CoreLib `417ab220532` 起）。
4. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 上架后换 pin、删 feed step（承 #34 注记）。
5. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（本文随附；kit #39 manifest 刷新
   **`2e5c45095b0`**）；maui = **`52b082a071`**（FIX-BWVMount 切片；其上 `be09a48817` FIX-BACKSIZE；`47d79add01` 为 #38 基座）；
   ohos-workload master **`7d9e316`**（pin 修复提交；其上 `10d01c3`/`11ef0fc` BWVMOUNT 计数器探针、`641e6ea` FIX-BACKSIZE pin、
   `9e6519e` FIX-BACKSIZE 壳+宿主+套件）；sdk 锚 **`2f1ace0a58`**（bundle 锚 3284e317 → **84d57989**；`-r2` pack 引用保留；
   SDK CI run `36977120266`）；aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#38）：本机桌面 HAD-W32 / OpenHarmony 7.0.0.111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`
  （UDID `1BCE13C8…AEA0`）；SDK `sign-hap.sh` 自签；AOT 路径已验证（rc.2 线；`-r2` feed）。
- **#39 本轮证据**（scratch）：FIX-BACKSIZE `fix-backsize/`（suite/abc/publish/device 日志与截图：Back 关抽屉、
  d0 vs d2 像素 mean 0.068、hybrid 区恢复 0.0、`hello-maui-razor` RSTree `Web [547,501][2573,1101]`）；
  FIX-BWVMount `fix-bwvmount/`（device `e3-click3.jpeg`：`.razor` 组件区 + count + Blazor click；`BLZ_DIAG` hilog）。
- **已知（承 #34–#38）**：JIT payload-in-libs 主包在本机新镜像装不上（`9568393`；libs 内无扩展名文件不在
  码签块 / 恰好 4096 B 文件的 fs-verity）——主包 JIT 真机判定仍以 tester 机为准；本机可用 AOT 路径。
- **本机可直接闭环**：AOT 出画、Back/抽屉、Hybrid/razor 挂载、注入点击、Blazor 标记、a11y/日志/截图回路；命令模板 =
  `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`（窗口竞态与 hilog 缓冲注见其 §4）。

## 5. 自签与包布局要点（测试方视角；承 #34–#38）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap**：payload-in-libs 布局不变（`libs/arm64-v8a/` 原地携带 payload + `.dotnet-payload.json`，
  `dotnet.zip` 回退；模块布局探测命中后原地启动、不解压）；**壳 abc 升 342,160（`ffda66da…`）**（FIX-BACKSIZE
  `onBackPress`）、**宿主升 384e552a（导出 150）**、headless 24,324 不变；新 hap sha 以 release/包内 `SHA256SUMS` 为准。
- **AOT 资产**：独立资产，不在 kit tar 内；安装会顶替 kit 主包，回 JIT 需重装 kit hap；数字以 release asset
  与 AOT README 为准（本轮 AOT 包若仍为 `aot-haps-v3*` 系列，以 release 为准；pack 用 `-r2`）。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #39）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs/宿主依赖（UND 238）；abc 期望 = **342,160（`ffda66da…`）/24,324（`798b2477…`）**，
   脚本哈希 `0b7dbfe9…` 以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮 / `--blazor-probe` / `--mode-matrix` /
   `--a11y-probe` 四件同 #38。
3. **7 hap 表（kit #39 发布实测；`SHA256SUMS` 17 项 / 1,517 B / `f7871fa8…`）**：`hello-maui-app.hap`
   **134,003,293 / `e113abbc…`**、`…-unsigned` **131,485,176 / `173762a7…`**、`…-permissions`
   **134,003,306 / `adc6720a…`**、`…-api20` **134,003,380 / `fb9c7af3…`**、`…-api20-permissions`
   **134,003,389 / `bdf60d14…`**、Blazor 默认 **27,216,958 / `c4660e4f…`**（own abc 21,200 B、site 213 files、
   dotnet.js 93,218 B == `dotnet.auou8t5gwr.js`）、`-nocsp` **27,216,659 / `9b0cd3e6…`**（包内名
   `hello-blazorwasm-host-nocsp-unsigned.hap`；own abc 21,016 B）。整包 tar **375,765,521 / `e95eed49…`**、
   树 `932e7955…`、sidecar `e5fc82de…`；bundle `openharmony-workload-1.0.0-preview.28.tar.gz`
   **77,760,996 / `84d57989…`**（三处同步 versioned `398936638` / latest `392077166` / sdkrc2 `398739326`；
   dist sums 212 B / `e2abc570…`；sdkrc2 合并 sums 1,960 B / `53564360…`；sdk-ohos 锚 **`2f1ace0a58`**，
   `WORKLOAD_BUNDLE_SHA256` 3284e317 → 84d57989）；发布已完成：kit tar/边车两处（dtk **392356147** /
   latest **392077166**；tar/边车 asset **605039193**/**605058022**，latest 同件 **605058246**/**605079225**）
   + bundle 三处；四条 release body 含 `## Integrity (kit #39)`；by-id 抽验 0 FAIL。重签/重打包后必变，
   以 release 与随包校验为准；有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#38）。
4. 离线证据（供复核）：套件 **554/534**（+4 FIX-BACKSIZE pin）、像素 PASS（Known 清零）、导出 **150/150**、
   壳 abc **342,160/24,324**（四包一致 + provenance）、host **`384e552a`**/UND 238、`build-arkts-shell 185/0`、
   `verify-kit 108/0`、packs/repo-hygiene 25/0、hap-targets 49+1skip；#39 设备证据见 scratch `fix-backsize/`、
   `fix-bwvmount/` 与 `docs/plans/2026-10-01-ohos-back-blazorwebview.md`、`2026-10-02-ohos-blazorwebview-mount.md`、
   `2026-10-01-ohos-fix3-consolidation.md`；#38 证据见 `docs/plans/2026-10-01-ohos-tester-handoff-kit38.md` §4。

## 7. 风险 / 未验证（诚实清单）

- **FIX-BACKSIZE/FIX-BWVMount 的 tester 机复核仍待做**：交付方在本机 AOT 闭环（Back 关抽屉、`.razor` 挂载、
  `BLZ_DIAG`）；不同窗口形态与共享桌面环境请按 §2 同法复测；无入口按「未测」登记，不判失败。
- **计数按钮往返（在途）**：点 "Blazor click" → `count>0` 的决定性截图仍在途（时序 vs 采轮）；**不判失败**，
  如取到证据请附截图/hilog。
- **`hybrid message rejected` 噪声**：Hybrid 静态 sink 对 Blazor 页消息的日志（设计内）；Blazor handler 无拒绝日志。
- **多覆盖层（后续）**：同页多 web 控件共享单 ArkWeb；hybrid 已注册时 Blazor 的 frame 有意 withheld
  （Blazor-only 页不受影响）。
- **payload 探针 `bundleCodeDir`（承 #36）**：模块布局命中后原地启动；两者皆 miss 时打一行提示并回退
  `dotnet.zip`（功能不丢，仅回到解压路径）——请附该行 hilog 回传。
- **AOT pack 结构性缺陷（上游面，未彻底；承 #36）**：共享 `.so` 与静态 `.a` 对 `FEATURE_DISTRO_AGNOSTIC_SSL`
  需求相反；当前以 fetch 端 shim 内容校验兜底（`-r2`），彻底解法见 `2026-09-30-rc2-aotpack-openssl-shim-fix.md` §5。
- **ICU/InvariantGlobalization**：无 ICU 镜像的 AOT demo 需 `InvariantGlobalization`（demo 配方已含；
  应用侧如遇 hosting 模块初始化 FailFast 可参考）。
- **门禁（本轮已跑）**：交互 554/floor 534（+4 fix pin）、像素 PASS（无 `Known(...)`）、导出 150/150、
   包内 `verify-kit.sh` 0 FAIL/0 WARN（abc 期望 342160/24324）、`ohos-workload` master **`7d9e316`**；
   CI **5/5** @ `7d9e316`（interaction `36974115596` / pixel `36974115651` / host-export `36974115631` /
   ridgraph `36974115625` / markdownlint `36974115608`）、sdk `ohos-install-tests` @ `2f1ace0a58` run
   `36977120266`（installer 43/43 · hostfeed 10/10 · codesign-filewrites 5/5）。
- 本次构建基线 = **rc.2 线**（SDK `.112` / workload `preview.28` / MAUI `rc2.26478.12`）；应用侧构建请同步该线
  （`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5；rc.1 回滚路径保留）。
