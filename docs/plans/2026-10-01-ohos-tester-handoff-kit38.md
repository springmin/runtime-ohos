# 测试方交接：kit #38、FIX-DISMISS（抽屉外点关闭）+ FIX-WVP（Hybrid overlay px→vp / origin / z-order / 挂起）（2026-10-01）

> 日期口径：文件名按撰写日；**kit #38 发布实测（release「## Integrity（kit #38）」；发布已完成，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **375,641,619 B / `ced5583f…`**、树
> **`307004e1…`**、sidecar **`8982fad0…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `9a07ddbf…`**
> （#37 = tar **375,652,577 B / `3a7259d6…`** 对照）。重签/重打包后哈希必变；CI run id 见 §7。
> 构建基线（rc.2 线，同 #34–#37）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（承 #36，保持）**：rc.2 NativeAOT OpenHarmony pack 用修正版资产
> **`Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.2.26451.112-r2.nupkg`**
> （28,904,657 B / `542058cf…`，release `aot-packs-11.0.0-rc.2` asset 601289590）；**rc.1 钉保持撤销**。
> **注明：FIX-BACK 波次未入本包**——Back 键关抽屉（需宿主/壳 `onBackPress` 转发 + host 导出 + 桥事件）与
> BlazorWebView 期望尺寸为 0 的自身出画在途，**将随下一版**；本轮相关项登记「未测（在途）」不判失败。

> 结论先行：kit #38 = **kit #37 + 两项**：①**FIX-DISMISS**——抽屉面板外点不关闭的根因 = `FlyoutPage.Default`
> 版式在本机（非 Phone idiom + landscape 快照）触发 `ShouldShowSplitMode`，关闭 `IsPresented=false` 被
> `InvalidOperationException` 守卫拒绝，异常又被 hosting 触摸回调边界吞掉（应用不崩、面板保持）→ 默认
> `Default` 改置 **`Popover`**（overlay 抽屉；应用显式值不动），外点正常关闭/重绘（maui `86b439ffc8`；
> 设备：开→外点关→再开→再关，像素差 0.0000 无残影，0 条 `touch callback failed`）。②**FIX-WVP**——Hybrid
> overlay 白区无内容的三处叠加根因：**element px 当 vp**（frame 为设备像素、壳按 ArkUI vp 用 → ×1.9 落窗外）、
> **hybrid origin 被 Blazor 注册顶掉**（`0.0.0.1` 零请求）、**覆盖层画在托管表面之下**（`Web` 声明在
> `XComponent/ContentSlot` 之前）；另加 Flyout/Tabbed **suspend/resume/hide**（抽屉/切页时挂起，防托管
> 自绘被压住）→ 修复后白区真出画、页↔宿主 bridge 闭环（maui `47d79add01` + 壳 `acbe750`，`WebCommandSent`
> 诊断）。**FIX-HOME/FIX-ITOUCH 全量保留。壳 abc 341,560（`4f02cb1d…`）/ headless 24,324（`798b2477…`）、
> 宿主 293,792（`4e9f3c3e…`，UND 238）、导出 149/149、套件 550/floor 530（+2 FIX-DISMISS +4 FIX-WVP pin）**。
> 判定点见 §2；承接 #37 的 FIX-HOME/FIX-ITOUCH、#36 的 payload/a11y/像素与 #35/#34/#33 的判定点**继续有效**，
> 本文只覆盖 #38 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（同 #37：runtime_mode 键、execmem、a11y 可选）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 探针（B2 走 MAUI WebView 内嵌 WASM；判定继续有效）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段用本轮 AOT 资产；rc.2 pack 用 -r2 feed，rc.1 钉保持撤销）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；#35–#38 本批未刷新）

`device-test-kit` release 自 #34 起有并列预签资产 **`preSigned-haps.tar.gz`**（asset 600101072，
375,834,798 B / `b492b284…`）：7 hap 全部按 **tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`**
预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装、无需重签**（同 bundle 换件仍先卸载）；
非 tester UDID 设备报 `9568344` → 回传 UDID 重出或按包内 README 自签。**#35–#38 本批未刷新预签件
（沿 #34 件；#38 如需预签请回传 UDID 代签）**；预签包是并列附加件，完整一轮仍用 `device-test-kit.tar.gz`。

## 1. kit #38 相对 #37 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **FIX-DISMISS（抽屉外点关闭）** | 现象：抽屉（`Drawer`/`tap outside to close` + 灰面板）出画后，面板外 click/drag/doubleClick 均不关闭、也不崩。根因：面板外按下 → `FlyoutDismiss` → `IsPresented=false`，但 `FlyoutPage.OnIsPresentedPropertyChanging` 在 `ShouldShowSplitMode`（非 Phone idiom × `Default` × landscape）为真时**抛** `InvalidOperationException("Can't change IsPresented when setting Default")`，异常被 touching 回调边界吞掉。修复：默认 `Default` → **`Popover`**（slice 唯一版式=overlay 抽屉）。设备：d1 汉堡开抽屉 → d2 外点关闭 → d3 再开 → d4 再关；像素 d0 vs d2 mean **0.0000**（无残影）、开/关 mean 53.5；hilog eid 0–9 全投递、0 条 `touch callback failed` | 外点（click/drag）关闭 + 重开/再关；无残留、无异常；Back 键见 §1.4（未入包） |
| 1.2 | **FIX-WVP（Hybrid overlay 几何/origin/z-order/挂起）** | ①**px→vp**：合成器按设备像素布局（`RequestDisplayDensity`=1），`frame` 是 px，壳直接当 ArkUI vp 用 → ×1.9 落窗外（RSTree 修复前 abs(576,1704) 3849×1324；修复后 `Bounds[0 0 2026 400]` 与 HybridWebView element 重合）；②**hybrid origin 注册仲裁**：单 ArkWeb，hybrid `loadUrl(0.0.0.1)` 后被 blazor `loadUrl(0.0.0.0)` 覆盖 → `0.0.0.1` 零请求；修复后 `hybrid assets: origin=https://0.0.0.1/` + `blazor origin armed…` + `web serve:`/`web page:` `0.0.0.1`；③**z-order**：`Web` 声明在 `XComponent/ContentSlot` 之前 → 一直被托管表面盖住；把 `Web` 移到 `ContentSlot` 之后（Map overlay 前）→ 白区真出画；④**suspend/resume/hide**：抽屉打开/关闭发 suspend/resume、TabbedPage 切页发 hide（防止覆盖层压住托管自绘）；⑤`WebCommandSent` 诊断事件（导出仍 149/149） | 白区出画（element 重合）；页显 `origin https://0.0.0.1/` + probe 表；页→宿主 bridge 往返；抽屉挂起/恢复；切 tab 隐藏/切回恢复 |
| 1.3 | **门禁/指纹/7 hap** | 交互套件 **550/floor 530**（+2 FIX-DISMISS：landscape 快照+非 Phone idiom 下版式=Popover、开→外点→双 false；+4 FIX-WVP；`verifyCheckTotal` 544→550、floor 524→530，只增不降）、像素 `PIXEL ASSERTIONS PASSED`（无 `Known`）、导出 **149/149**、host **UND 238**/DT_NEEDED 5/denylist 0；**新壳 abc 341,560（`4f02cb1d…`）/ headless 24,324（`798b2477…`）**（`Index.ets 296,184/2cc54147`、provenance `6c702f4e`；headless/host 逐字节不变）、hap 内宿主 **293,792（`4e9f3c3e…`）**；`verify-kit` 期望已重锚 **341560/24324**（脚本 `1ed34afe…`）；7 hap 重签（见表 §6.3） | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**（abc 期望 341560/24324）；套件自报行 `[suite] checks=550 total=550 floor=530 assert=True` |
| 1.4 | **FIX-BACK 波次未入包（明确）** | 本批**不含**：Back 键关抽屉（宿主/壳只注册触摸、无按键转发；`keyEvent Back` 由系统消费 → 窗口收后台）；BlazorWebView 期望尺寸为 0（无 `GetDesiredSize` → frame 被忽略、自身不出画）；同页多 web 控件共享单 ArkWeb 的多 overlay 支持 | 登记「未测（在途）」，**不判失败**；将随下一版 |

> 尺寸预算：以 release 资产表为准（#37 = 375,652,577 B；#38 = 375,641,619 B，delta = 新壳 + 5 MAUI hap 重建）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **FIX-DISMISS（主判点 1）** | AOT 件冷启 Home → 点汉堡开抽屉 → **面板外 click** → 再开 → 外点 | 两次外点均**关闭**；无残影；无 `touch callback failed`；应用不崩 | 抽屉开/关截图 + hilog |
| **FIX-WVP 出画（主判点 2）** | 切到含 Hybrid 的页 | 白区**真出画**（与 element frame 重合）；页显 `origin https://0.0.0.1/ | readyState: interactive` + probe 表对象；页内 drag 滚动正常 | 截图（w0-home/s3c）+ RSTree/hilog |
| **FIX-WVP bridge** | 页内 click（Send ping） | 页面 `sent #n via window.external.sendMessage … origin: https://0.0.0.1/` + 托管 label `hybrid raw message: {"kind":"ohos-bridge-ping",…}`（页→宿主闭环） | 截图 + hilog |
| **注入动画（承 FIX-ITOUCH）** | Animations 页注入点击「Run animations」 | "fading out…" → "animations done"；偏心点 0 变化 | 截图（f4/f5）+ hilog |
| **挂起/恢复** | 抽屉打开时看白区；切 Animations 再看；切回 Home | 抽屉打开时覆盖层挂起（抽屉完整可见、无被压）；切 tab 隐藏；切回再出画 | 截图（f1–f3、f6）+ hilog |
| **套件基座** | 有源码测试者跑 `test/maui-platform-verify` | `[suite] checks=550 total=550 floor=530 assert=True`；2+4 条 fix pin 绿 | 终端输出 |
| **承 #37：FIX-HOME / FIX-ITOUCH** | Home 首屏；注入点击页内元素 | Home 整页出画 + 切走/切回；注入命中（element 坐标） | 截图 + hilog |
| **承 #36：payload/a11y/像素/AOT `-r2`** | 见 `2026-10-01-ohos-tester-handoff-kit36.md` §2 | hilog `payload-in-libs: running from …`；`status=1`/nodeCount 5/24；像素无 `Known`；`-r2` AOT 构建成立 | hilog + `a11y/` + 终端 |
| **承 #35：W9/W10** | 按 handoff #36 §2（B2/T14/T21/T8/T20/T19/AOT 入口） | 同 #35/#36/#37 期望；套件自报行 `550/floor 530` | 截图 + hilog + `dotnet-status.txt` |
| **承 #34：rc.2 版本自述 + W6/W7/W8** | 包内《最终状态.md》/`README-交付说明.md`；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6 | SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；逐项同 #34 | 自述原文 + 截图 + `--a11y-probe` |
| **承 #33：Blazor 双 hap A/B / TabbedPage / W5** | 按 #33 判定树与一页卡 | 同 #33 期望（默认 ✅ → CSP 非瓶颈；默认 ❌ nocsp ✅ → CSP 至少次因） | `BLZ_BOOT`/`BLZ_RENDERED` + 截图 |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项（出画/点击/截图）照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#37）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.2.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（承 #36）**：用 `-r2` 修正版 pack（asset 601289590）；设备/本机 AOT 构建无需本地 hooks；
   最小复现与判据见 `docs/plans/2026-09-30-rc2-aotpack-openssl-shim-fix.md` §1/§4。
3. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`（CoreLib `417ab220532` 起）。
4. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 上架后换 pin、删 feed step（承 #34 注记）。
5. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（本文随附；kit #38 manifest 刷新
   **`895b5a71339`**）；maui = **`47d79add01`**（FIX-WVP 切片；其上 `86b439ffc8` FIX-DISMISS；`68ec598037` 为 FIX-HOME 基座）；
   ohos-workload master **`becc13e`**（pin 提交；其上 `acbe750` FIX-WVP 壳+宿主+套件 / `d00cf7e` FIX-DISMISS 套件 / `aade43c` #37）；
   sdk 锚 **`ee1163a004`**（bundle 锚 8abba9b1 → **3284e317**；`-r2` pack 引用保留；SDK CI run `36835697774`）；
   aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#37）：本机桌面 HAD-W32 / OpenHarmony 7.0.0.111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`
  （UDID `1BCE13C8…AEA0`）；SDK `sign-hap.sh` 自签；AOT 路径已验证（rc.2 线；`-r2` feed）。
- **#38 本轮证据**（scratch）：FIX-DISMISS `fix-dismiss/`（harness/套件日志/AOT/device：d0–d7 截图，外点关、
  像素 mean 0.0000、Back 未转发）；FIX-WVP `fix-wvp/`（device w0-home/s3c/ping/drawer/anim/f0..f6 + hilog-phase1/final
  + rstree-now；`suite-retry3.log` 终版绿）；件 `hello-maui-app-fixwvp-signed.hap`（壳 341,560/24,324）。
- **已知（承 #34–#37）**：JIT payload-in-libs 主包在本机新镜像装不上（`9568393`；libs 内无扩展名文件不在
  码签块 / 恰好 4096 B 文件的 fs-verity）——主包 JIT 真机判定仍以 tester 机为准；本机可用 AOT 路径。
- **本机可直接闭环**：AOT 出画、抽屉/外点、Hybrid bridge、注入点击、Blazor 标记、a11y/日志/截图回路；命令模板 =
  `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`（窗口竞态与 hilog 缓冲注见其 §4）。

## 5. 自签与包布局要点（测试方视角；承 #34–#37）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap**：payload-in-libs 布局不变（`libs/arm64-v8a/` 原地携带 payload + `.dotnet-payload.json`，
  `dotnet.zip` 回退；模块布局探测命中后原地启动、不解压）；**壳 abc 升 341,560（`4f02cb1d…`）**（FIX-WVP 的
  px→vp/z-order/挂起），headless 24,324 不变；宿主 `4e9f3c3e` 不变；新 hap sha 以 release/包内 `SHA256SUMS` 为准。
- **AOT 资产**：独立资产，不在 kit tar 内；安装会顶替 kit 主包，回 JIT 需重装 kit hap；数字以 release asset
  与 AOT README 为准（本轮 AOT 包若仍为 `aot-haps-v3*` 系列，以 release 为准；pack 用 `-r2`）。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #38）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs/宿主依赖（UND 238）；abc 期望 = **341,560（`4f02cb1d…`）/24,324（`798b2477…`）**，
   脚本哈希 `1ed34afe…` 以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮 / `--blazor-probe` / `--mode-matrix` /
   `--a11y-probe` 四件同 #37。
3. **7 hap 表（kit #38 发布实测；`SHA256SUMS` 17 项 / 1,517 B / `9a07ddbf…`）**：`hello-maui-app.hap`
   **133,973,558 / `6b6ea90b…`**、`…-unsigned` **131,450,495 / `2db7da30…`**、`…-permissions`
   **133,973,558 / `4b15313d…`**、`…-api20` **133,973,547 / `24f84265…`**、`…-api20-permissions`
   **133,973,594 / `0d677257…`**、Blazor 默认 **27,216,958 / `8d3d2a05…`**（own abc 21,200 B、site 213 files、
   dotnet.js 93,218 B == `dotnet.lcjismsp3p.js`）、`-nocsp` **27,216,659 / `b3494513…`**（包内名
   `hello-blazorwasm-host-nocsp-unsigned.hap`；own abc 21,016 B）。整包 tar **375,641,619 / `ced5583f…`**、
   树 `307004e1…`、sidecar `8982fad0…`；bundle `openharmony-workload-1.0.0-preview.28.tar.gz`
   **77,742,112 / `3284e317…`**（三处同步 versioned `398936638` / latest `392077166` / sdkrc2 `398739326`；
   dist sums 212 B / `9a0b8b1a…`；sdkrc2 合并 sums 1,960 B / `87e95a38…`；sdk-ohos 锚 **`ee1163a004`**，
   `WORKLOAD_BUNDLE_SHA256` 8abba9b1 → 3284e317）；发布已完成：kit tar/边车两处（dtk **392356147** /
   latest **392077166**；tar/边车 asset **602780725**/**602782257**，latest 同件 **602782442**/**602784388**）
   + bundle 三处；四条 release body 含 `## Integrity (kit #38)`；by-id 抽验 0 FAIL + gh-proxy 校验通过
   （tar HEAD 200/375,641,619）。重签/重打包后必变，以 release 与随包校验为准；
   有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#37）。
4. 离线证据（供复核）：套件 **550/530**（2 FIX-DISMISS + 4 FIX-WVP pin）、像素 PASS（Known 清零）、
   导出 **149/149**、壳 abc **341,560/24,324**（四包一致 + provenance）、host **`4e9f3c3e`**/UND 238、
   `build-arkts-shell 185/0`、`verify-kit 108/0`、packs/repo-hygiene 25/0、hap-targets 49+1skip；#38 设备证据见
   scratch `fix-dismiss/`、`fix-wvp/` 与 `docs/plans/2026-10-01-ohos-flyout-dismiss.md`、`…webview-overlay.md`、
   `…fix2-consolidation.md`；#37 证据见 `docs/plans/2026-10-01-ohos-tester-handoff-kit37.md` §4。

## 7. 风险 / 未验证（诚实清单）

- **FIX-DISMISS/FIX-WVP 的 tester 机复核仍待做**：交付方在本机 AOT 闭环（外点关、Hybrid 出画+bridge、
  挂起/恢复）；不同窗口形态（全屏/分屏）与多页组合请按 §2 同法复测；无入口按「未测」登记，不判失败。
- **FIX-BACK 波次未入包（本轮明确项）**：Back 键关抽屉（宿主/壳无按键转发；系统消费 Back → 窗口收后台）与
  **BlazorWebView 期望尺寸为 0**（无 `GetDesiredSize` → frame 被忽略、自身不出画）在途；**同页多 web 控件
  多 overlay 支持**亦为后续项。相关项登记「未测（在途）」。
- **挂起范围**：suspend/resume 覆盖 FlyoutPage 呈现/关闭、hide 覆盖 TabbedPage 切页；Shell 抽屉与非
  Tabbed/Flyout 页面切换未挂 suspend/hide（后续）。
- **payload 探针 `bundleCodeDir`（承 #36）**：模块布局命中后原地启动；两者皆 miss 时打一行提示并回退
  `dotnet.zip`（功能不丢，仅回到解压路径）——请附该行 hilog 回传。
- **AOT pack 结构性缺陷（上游面，未彻底；承 #36）**：共享 `.so` 与静态 `.a` 对 `FEATURE_DISTRO_AGNOSTIC_SSL`
  需求相反；当前以 fetch 端 shim 内容校验兜底（`-r2`），彻底解法见 `2026-09-30-rc2-aotpack-openssl-shim-fix.md` §5。
- **ICU/InvariantGlobalization**：无 ICU 镜像的 AOT demo 需 `InvariantGlobalization`（demo 配方已含；
  应用侧如遇 hosting 模块初始化 FailFast 可参考）。
- **门禁（本轮已跑）**：交互 550/floor 530（2+4 fix pin）、像素 PASS（无 `Known(...)`）、导出 149/149、
  包内 `verify-kit.sh` 0 FAIL/0 WARN（abc 期望 341560/24324）、`ohos-workload` master **`becc13e`**；
  CI **5/5** @ `becc13e`（interaction `36830400978` / pixel `36830401093` / host-export `36830400995` /
  ridgraph `36830401002` / markdownlint `36830400969`）、sdk `ohos-install-tests` @ `ee1163a004` run
  `36835697774`（installer 43/43 · hostfeed 10/10 · codesign-filewrites 5/5）。
- 本次构建基线 = **rc.2 线**（SDK `.112` / workload `preview.28` / MAUI `rc2.26478.12`）；应用侧构建请同步该线
  （`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5；rc.1 回滚路径保留）。
