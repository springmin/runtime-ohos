# 测试方交接：kit #40、FIX-JSCALL（BlazorWebView IPC 出站 JSCall 枚举 AOT 扎根 → razor 计数往返 0→1→2）（2026-10-02）

> 日期口径：文件名按撰写日；**kit #40 发布实测（release「## Integrity（kit #40）」；发布已完成，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **375,836,470 B / `31ab8732…`**、树
> **`e950de54…`**、sidecar **`9b051247…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `7667b6bd…`**
> （#39 = tar **375,765,521 B / `e95eed49…`** 对照）。重签/重打包后哈希必变；CI run id 见 §7。
> 构建基线（rc.2 线，同 #34–#39）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（承 #36，保持）**：rc.2 NativeAOT OpenHarmony pack 用修正版资产
> **`Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.2.26451.112-r2.nupkg`**
> （28,904,657 B / `542058cf…`，release `aot-packs-11.0.0-rc.2` asset 601289590）；**rc.1 钉保持撤销**。
> **上一版在途项本版达成**：#39 的「razor 计数按钮往返（count>0）在途」由 **FIX-JSCALL** 关闭（真机 0→1→2）。
> **本轮在途/后续（明确）**：`blzProbe` 样例未定义（过线后 JSException；`plain ok` 已证 managed→JS 半边）、
> `NavigationOptions` 为预防性扎根（未点 live Navigate）、多覆盖层（单 ArkWeb）仍为后续——相关项登记
> 「未测（在途）」不判失败。

> 结论先行：kit #40 = **kit #39 + FIX-JSCALL**：**BlazorWebView IPC 出站半边 AOT 扎根**。根因：`IpcSender.BeginInvokeJS`
> 经 WebView 包**静态反射解析器**序列化 `JSInvocationInfo.ResultType`（`JSCallResultType`）与 `.CallType`（`JSCallType`），
> `IpcSender.Navigate` 序列化 `NavigationOptions`；枚举是值类型，NativeAOT 没有解析器构造的
> `EnumConverter<T>`/`JsonTypeInfo<T>` 闭合实例的原生代码（FIX-BWVMount `JsonElement[]` 同族）→ 渲染器 attach interop
> （fire-and-forget）死在 `IpcCommon.Serialize`、interop 方法未注册（`attach-state=not-attached`），而 #39 的
> FIX-BWVMount 桩 interop 又吞掉后续点击——count 永远 0。修复（maui `15d81f31b1`）：切片源生成上下文
> `OpenHarmonySliceJsonContext` 重新携带三类型（BlazorWebView 门控下）+ handler 静态构造触碰这些 type info
> 与 `JsonElement[]` + **移除桩 attach/合成点击探针**（不动包自身 options）。设备（HAD-W32，AOT）：两次
> `uitest uiInput click` 命中 BUTTON → **count 0→1→2**（截图 r0/r1/r2），`missing native code`=0、
> `BeginInvokeDotNet` accepted=4、`send head=__bwv:["BeginInvokeJS",2,…]`。**FIX-HOME/FIX-ITOUCH/FIX-DISMISS/
> FIX-WVP/FIX-BACKSIZE/FIX-BWVMount 全量保留。壳 abc 342,160（`ffda66da…`）/ headless 24,324（逐字节未变）、
> 宿主 293,792（`384e552a…`）（逐字节重建）、导出 150/150、套件 555/floor 535（+1 FIX-JSCALL pin）**。
> 判定点见 §2；承接 #39/#38/#37/#36/#35/#34/#33 的判定点**继续有效**，本文只覆盖 #40 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（同 #39：runtime_mode 键、execmem、a11y 可选）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 探针（B2 走 MAUI WebView 内嵌 WASM；判定继续有效）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段用本轮 AOT 资产；rc.2 pack 用 -r2 feed，rc.1 钉保持撤销）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；#35–#40 本批未刷新）

`device-test-kit` release 自 #34 起有并列预签资产 **`preSigned-haps.tar.gz`**（asset 600101072，
375,834,798 B / `b492b284…`）：7 hap 全部按 **tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`**
预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装、无需重签**（同 bundle 换件仍先卸载）；
非 tester UDID 设备报 `9568344` → 回传 UDID 重出或按包内 README 自签。**#35–#40 本批未刷新预签件
（沿 #34 件；#40 如需预签请回传 UDID 代签）**；预签包是并列附加件，完整一轮仍用 `device-test-kit.tar.gz`。

## 1. kit #40 相对 #39 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **FIX-JSCALL（razor 计数往返 0→1→2）** | #39 已把受信任点击送达原生 BUTTON 与 `DispatchEventAsync`，但 `count` 恒 0；页面 probe 报 `EnumConverter\`1[JSCallResultType] missing native code`。根因 = IPC **出站**半边：`IpcSender.BeginInvokeJS` 序列化 `JSCallResultType`/`JSCallType`、`IpcSender.Navigate` 序列化 `NavigationOptions`（均经包反射解析器）；NativeAOT 缺 `EnumConverter<T>`/`JsonTypeInfo<T>` 闭合实例原生代码 → attach interop 死在 `IpcCommon.Serialize`（`attach-state=not-attached`），#39 的桩 interop 又吞掉后续点击。修复 = 切片源生成上下文携带三类型 + handler 静态构造触碰 + 移除桩探针。设备：点击两次 → **count 0→1→2**（截图 `r0-page.jpeg`/`r1-click.jpeg`/`r2-click2.jpeg`）；hilog `missing native code`=0、`interop-call`/`attach-state`=0、`BeginInvokeDotNet` accepted=4、`send head=__bwv:["BeginInvokeJS",2,"Blazor._internal.attachW…`；probe tail `\| plain ok` | razor 页点 "Blazor click" 两次 → **count 0→1→2**；`missing native code`=0 |
| 1.2 | **门禁/指纹/7 hap** | 交互套件 **555/floor 535**（+1 FIX-JSCALL pin：JsonContext 三类型 + handler 静态构造 + 桩探针移除；`verifyCheckTotal` 554→555、floor 534→535，只增不降）、像素 `PIXEL ASSERTIONS PASSED`（无 `Known`）、宿主导出契约 **150/150**、host **UND 238**/DT_NEEDED 5/denylist 0；**壳 abc 342,160（`ffda66da…`）/ headless 24,324（`798b2477…`）逐字节未变**、hap 内宿主 **293,792（`384e552a…`）**、payload Hosting 68,608（`9d9facd9…`）；`verify-kit` 期望不变（342160/24324，脚本 `0b7dbfe9…`）；**7 hap 重建（MAUI 5 约 +13 KB/hap；Blazor 双 hap 随站点 `dotnet.js` 指纹 `dotnet.17opwway9i.js`）**：见表 §6.3 | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**；套件自报行 `[suite] checks=555 total=555 floor=535 assert=True` |
| 1.3 | **同族扫描与预防口径** | 已扎根（rooted）：`JsonElement[]`（入站，BWVMount）、`JSCallResultType`/`JSCallType`（BeginInvokeJS）、`NavigationOptions`（Navigate）。已安全：`byte[]`（非泛型 `ByteArrayConverter`，解析器注入）、long/string/bool/int（基元已在镜像）、`ElementReference`（显式非泛型转换器）、`DotNetObjectReference<T>`（引用类型共享泛型）。**预防：任何新上线的值类型都需要 context 条目 + 静态构造触碰**（harness 已 pin 三处根）；上游解（包自带源生成上下文）超出切片范围 | 供后续回归判读；harness pin 绿 |
| 1.4 | **在途/后续项（明确）** | ①`blzProbe` 未被 razor 样例定义——该 probe 调用过线后报 JSException（`plain ok` 已证 managed→JS 半边；样例未动）；②`NavigationOptions` 为**预防性扎根**，本轮未在真机点 live Navigate；③**多覆盖层**（同页多 web 控件共享单 ArkWeb；hybrid 已注册时 Blazor frame 有意 withheld；Blazor-only 页不受影响）仍为后续 | 登记「未测（在途）」，**不判失败** |

> 尺寸预算：以 release 资产表为准（#39 = 375,765,521 B；#40 = 375,836,470 B，delta = FIX-JSCALL 切片重建的 5 MAUI hap）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **razor 计数往返（主判点）** | 打开 razor 页 → 点 "Blazor click" 两次 | **count 0→1→2**；`missing native code`=0；`BeginInvokeDotNet` accepted；`send head=__bwv:["BeginInvokeJS",…]` | 截图 r0/r1/r2 + hilog |
| **`.razor` 挂载（承 #39）** | 打开 razor 页 | "BlazorWebView component (.razor)" + `count: 0` + "Blazor click"；`[maui] blazor start/connect` + `BLZ_DIAG` | 截图 + hilog |
| **Back 关抽屉（承 #39）** | 开抽屉 → 系统 Back | 抽屉关闭且仍 `#FOREGROUND`；再 Back → `#BACKGROUND` | 截图 + hilog |
| **BlazorWebView 尺寸（承 #39）** | 打开 BlazorWebView 页 | 控件在自身 frame 内出画（非整窗/退化） | 截图 + RSTree |
| **套件基座** | 有源码测试者跑 `test/maui-platform-verify` | `[suite] checks=555 total=555 floor=535 assert=True`；+1 pin 绿；导出 150/150 | 终端输出 |
| **承 #38：FIX-DISMISS / FIX-WVP** | 抽屉外点关闭；Hybrid 出画 + bridge | 同 #38 期望（外点关、`origin https://0.0.0.1/`、`hybrid raw message`、挂起恢复） | 截图 + hilog |
| **承 #37：FIX-HOME / FIX-ITOUCH** | Home 首屏；注入点击页内元素 | Home 整页出画 + 切走/切回；注入命中（element 坐标） | 截图 + hilog |
| **承 #36：payload/a11y/像素/AOT `-r2`** | 见 `2026-10-01-ohos-tester-handoff-kit36.md` §2 | hilog `payload-in-libs: running from …`；`status=1`/nodeCount 5/24；像素无 `Known`；`-r2` AOT 构建成立 | hilog + `a11y/` + 终端 |
| **承 #35：W9/W10** | 按 handoff #36 §2（B2/T14/T21/T8/T20/T19/AOT 入口） | 同 #35–#39 期望；套件自报行 `555/floor 535` | 截图 + hilog + `dotnet-status.txt` |
| **承 #34：rc.2 版本自述 + W6/W7/W8** | 包内《最终状态.md》/`README-交付说明.md`；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6 | SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；逐项同 #34 | 自述原文 + 截图 + `--a11y-probe` |
| **承 #33：Blazor 双 hap A/B / TabbedPage / W5** | 按 #33 判定树与一页卡 | 同 #33 期望（默认 ✅ → CSP 非瓶颈；默认 ❌ nocsp ✅ → CSP 至少次因） | `BLZ_BOOT`/`BLZ_RENDERED` + 截图 |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项（出画/点击/截图）照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#39）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.2.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（承 #36）**：用 `-r2` 修正版 pack（asset 601289590）；设备/本机 AOT 构建无需本地 hooks；
   最小复现与判据见 `docs/plans/2026-09-30-rc2-aotpack-openssl-shim-fix.md` §1/§4。
3. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`（CoreLib `417ab220532` 起）。
4. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 上架后换 pin、删 feed step（承 #34 注记）。
5. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（本文随附；kit #40 manifest 刷新
   **`27bf46a63df`**）；maui = **`15d81f31b1`**（FIX-JSCALL 切片；其上 `52b082a071` FIX-BWVMount / `be09a48817` FIX-BACKSIZE）；
   ohos-workload master **`9073c65`**（三 workflow pin → `15d81f31b1`，注释 555/535、150/150；套件 pin `2028cc2`）；
   sdk 锚 **`77ffe1dad6`**（bundle 锚 84d57989 → **434d2b6f**；`-r2` pack 引用保留；SDK CI run `36993177948`）；
   aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#39）：本机桌面 HAD-W32 / OpenHarmony 7.0.0.111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`
  （UDID `1BCE13C8…AEA0`）；SDK `sign-hap.sh` 自签；AOT 路径已验证（rc.2 线；`-r2` feed）。
- **#40 本轮证据**（scratch `fix-jscall/`）：device `r0-page.jpeg`/`r1-click.jpeg`/`r2-click2.jpeg`（count 0→1→2）；
  hilog（`missing native code`=0、`BeginInvokeDotNet` accepted=4、`send head=__bwv:["BeginInvokeJS",…]`）；
  件 `hello-maui-razor` AOT hap 21,893,981 B / `6aa54c5d…`（shell abc 342,176/`1af2e2e7…` razor 变体、host `384e552a…`）。
- **#39 本机轮**（`2026-10-02-ohos-kit39-local-verification.md`）：资产核验/双 hap A/B/tester-run 16M/AOT razor 挂载；
  计数在途的定位（`EnumConverter` missing native code）即本版 FIX-JSCALL 的输入。
- **已知（承 #34–#39）**：JIT payload-in-libs 主包在本机新镜像装不上（`9568393`）；主包 JIT 真机判定仍以 tester 机为准；
  本机可用 AOT 路径。命令模板 = `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`（窗口竞态与 hilog 缓冲注见其 §4）。

## 5. 自签与包布局要点（测试方视角；承 #34–#39）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap**：payload-in-libs 布局不变（`libs/arm64-v8a/` 原地携带 payload + `.dotnet-payload.json`，
  `dotnet.zip` 回退）；**壳 abc 342,160（`ffda66da…`）/ 宿主 `384e552a` 与 #39 同值**（FIX-JSCALL 只改 maui 切片）；
  新 hap sha 以 release/包内 `SHA256SUMS` 为准。
- **AOT 资产**：独立资产，不在 kit tar 内；安装会顶替 kit 主包，回 JIT 需重装 kit hap；数字以 release asset
  与 AOT README 为准（本轮 AOT 包若仍为 `aot-haps-v3*` 系列，以 release 为准；pack 用 `-r2`）。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #40）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs/宿主依赖（UND 238）；abc 期望 = **342,160（`ffda66da…`）/24,324（`798b2477…`）** 不变，
   脚本哈希 `0b7dbfe9…` 以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮 / `--blazor-probe` / `--mode-matrix` /
   `--a11y-probe` 四件同 #39。
3. **7 hap 表（kit #40 发布实测；`SHA256SUMS` 17 项 / 1,517 B / `7667b6bd…`）**：`hello-maui-app.hap`
   **134,016,353 / `712bd947…`**、`…-unsigned` **131,497,113 / `87e10197…`**、`…-permissions`
   **134,016,342 / `8773a913…`**、`…-api20` **134,016,335 / `88c6a165…`**、`…-api20-permissions`
   **134,016,346 / `a35c3467…`**、Blazor 默认 **27,216,958 / `8db8e4ec…`**（own abc 21,200 B、site 213 files、
   dotnet.js 93,218 B == `dotnet.17opwway9i.js` / `43f9f87e…`）、`-nocsp` **27,216,659 / `0e0af68b…`**（包内名
   `hello-blazorwasm-host-nocsp-unsigned.hap`；own abc 21,016 B）。整包 tar **375,836,470 / `31ab8732…`**、
   树 `e950de54…`、sidecar `9b051247…`；bundle `openharmony-workload-1.0.0-preview.28.tar.gz`
   **77,750,495 / `434d2b6f…`**（三处同步 versioned `398936638` / latest `392077166` / sdkrc2 `398739326`；
   dist sums 212 B / `38281349…`；sdkrc2 合并 sums 1,960 B / `c53fca53…`；sdk-ohos 锚 **`77ffe1dad6`**，
   `WORKLOAD_BUNDLE_SHA256` 84d57989 → 434d2b6f）；发布已完成：kit tar/边车两处（dtk **392356147** /
   latest **392077166**；tar/边车 asset **605346629**/**605372761**，latest 同件 **605373164**/**605385920**）
   + bundle 三处；四条 release body 含 `## Integrity (kit #40)`；by-id 抽验 0 FAIL + 公开直连抽验（边车
   `9b051247…`、preview.28 sums `38281349…` 一致）。重签/重打包后必变，以 release 与随包校验为准；
   有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#39）。
4. 离线证据（供复核）：套件 **555/535**（+1 FIX-JSCALL pin）、像素 PASS（Known 清零）、导出 **150/150**、
   壳 abc **342,160/24,324**（四包一致 + provenance）、host **`384e552a`**/UND 238、`build-arkts-shell 185/0`、
   `verify-kit 108/0`、packs/repo-hygiene 25/0、hap-targets 49/0/0；#40 设备证据见 scratch `fix-jscall/` 与
   `docs/plans/2026-10-02-ohos-jscallresult-aot.md`；#39 证据见 `2026-10-02-ohos-kit39-local-verification.md`
   与 `docs/plans/2026-10-02-ohos-tester-handoff-kit39.md` §4。

## 7. 风险 / 未验证（诚实清单）

- **FIX-JSCALL 的 tester 机复核仍待做**：交付方在本机 AOT 闭环（计数 0→1→2）；不同窗口形态与共享桌面环境
  请按 §2 同法复测；无入口按「未测」登记，不判失败。
- **在途项（明确）**：①`blzProbe` 未被 razor 样例定义——调用过线后 JSException（`plain ok` 已证 managed→JS 半边）；
  ②`NavigationOptions` 预防性扎根（未点 live Navigate）；③多覆盖层（单 ArkWeb；hybrid 已注册时 Blazor frame
  有意 withheld）。相关项登记「未测（在途）」。
- **同族预防**：任何新上线 IPC 的值类型都需要源生成 context 条目 + handler 静态构造触碰；harness 已 pin
  `JsonElement[]`/`JSCallResultType`/`JSCallType` 三处根（上游解 = 包自带源生成上下文，超出切片范围）。
- **payload 探针 `bundleCodeDir`（承 #36）**：模块布局命中后原地启动；两者皆 miss 时打一行提示并回退
  `dotnet.zip`（功能不丢，仅回到解压路径）——请附该行 hilog 回传。
- **AOT pack 结构性缺陷（上游面，未彻底；承 #36）**：共享 `.so` 与静态 `.a` 对 `FEATURE_DISTRO_AGNOSTIC_SSL`
  需求相反；当前以 fetch 端 shim 内容校验兜底（`-r2`），彻底解法见 `2026-09-30-rc2-aotpack-openssl-shim-fix.md` §5。
- **ICU/InvariantGlobalization**：无 ICU 镜像的 AOT demo 需 `InvariantGlobalization`（demo 配方已含；
  应用侧如遇 hosting 模块初始化 FailFast 可参考）。
- **门禁（本轮已跑）**：交互 555/floor 535（+1 fix pin）、像素 PASS（无 `Known(...)`）、导出 150/150、
   包内 `verify-kit.sh` 0 FAIL/0 WARN（abc 期望 342160/24324）、`ohos-workload` master **`9073c65`**；
   CI **5/5** @ `9073c65`（interaction `36989506879` / pixel `36989506893` / host-export `36989506617` /
   ridgraph `36989506653` / markdownlint `36989506646`）、sdk `ohos-install-tests` @ `77ffe1dad6` run
   `36993177948`（installer 43/43 · hostfeed 10/10 · codesign-filewrites 5/5）。
- 本次构建基线 = **rc.2 线**（SDK `.112` / workload `preview.28` / MAUI `rc2.26478.12`）；应用侧构建请同步该线
  （`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5；rc.1 回滚路径保留）。
