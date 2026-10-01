# 测试方交接：kit #37、FIX-HOME（Home 页整页出画）+ FIX-ITOUCH（注入/触摸 element 坐标）（2026-10-01）

> 日期口径：文件名按撰写日；**kit #37 发布实测（release「## Integrity（kit #37）」；发布已完成，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **375,652,577 B / `3a7259d6…`**、树
> **`ab517b57…`**、sidecar **`7db60a77…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `1ce87838…`**
> （#36 = tar **375,627,841 B / `9eb9cecf…`** 对照）。重签/重打包后哈希必变；CI run id 见 §7。
> 构建基线（rc.2 线，同 #34–#36）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（承 #36，保持）**：rc.2 NativeAOT OpenHarmony pack 用修正版资产
> **`Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.2.26451.112-r2.nupkg`**
> （**28,904,657 B / `542058cf…`**，release `aot-packs-11.0.0-rc.2` asset **601289590**）→ **rc.1 钉保持撤销**
> （详见 `docs/plans/2026-09-30-rc2-aotpack-openssl-shim-fix.md`）。

> 结论先行：kit #37 = **kit #36 + 两项 UI 修复**：①**FIX-HOME**——`OpenHarmonyNavigationPageHandler.PlatformArrange`
> 下钻 `CurrentPage`（safe-area walk + arrange 防递归标记），Home tab（FlyoutPage→TabbedPage→NavigationPage）
> 不再停在 `-1x-1`，**AOT 真机首屏整页出画**（截图 `fix-home/device/home-cold.jpeg`；maui 切片 `68ec598037`）；
> ②**FIX-ITOUCH**——宿主 `4e9f3c3e` 的 `OnTouch` 改读 touch point **element** 坐标（与鼠标同一 surface 空间；
> free window 的 window 系含 70 px 系统标题栏 → 此前注入点击整体下移、页内小控件不命中）——uitest 注入点击
> 命中内容元素（"fading out…" → "animations done"）、偏心探针不误命中、tab 切换不变；宿主 UND 240→238。
> **壳 abc 字节不变 339,964（`fc54d2b8…`）/24,324（`798b2477…`）、hap 内宿主 293,792（`4e9f3c3e…`）、
> 导出 149/149、套件 544/floor 524（+4 FIX-HOME pin）**。判定点见 §2；承接 #36 的 payload 原地直载/a11y/像素、
> #35 的 W9/W10 与 #34/#33 的判定点**继续有效**，本文只覆盖 #37 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（同 #36：runtime_mode 键、execmem、a11y 可选）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 探针（B2 走 MAUI WebView 内嵌 WASM；判定继续有效）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段用本轮 AOT 资产；rc.2 pack 用 -r2 feed，rc.1 钉保持撤销）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；#35–#37 本批未刷新）

`device-test-kit` release 自 #34 起有并列预签资产 **`preSigned-haps.tar.gz`**（asset 600101072，
375,834,798 B / `b492b284…`）：7 hap 全部按 **tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`**
预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装、无需重签**（同 bundle 换件仍先卸载）；
非 tester UDID 设备报 `9568344` → 回传 UDID 重出或按包内 README 自签。**#35–#37 本批未刷新预签件
（沿 #34 件；#37 如需预签请回传 UDID 代签）**；预签包是并列附加件，完整一轮仍用 `device-test-kit.tar.gz`。

## 1. kit #37 相对 #36 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **FIX-HOME（Home 页整页出画）** | `TabbedPage`/`FlyoutPage`/`Shell` 容器 handler 以 `content.Arrange(frame)` 摆当前页，但 `OpenHarmonyNavigationPageHandler` 没有下钻 → Home（FlyoutPage→TabbedPage→NavigationPage）的 `ContentPage` 子树停在 `-1x-1`，合成器只画 chrome（白标题条/紫导航栏/tab 栏，内容区黑）。修复 = 导航 handler 下钻 `CurrentPage`（safe-area walk + `OpenHarmonyContentArrange.IsArranging` 防递归标记，与 `OpenHarmonyPageHandler` 同模式；maui `68ec598037`）。AOT 真机首屏 Home **整页出画**（标题/副标题/Hybrid 白区/Count 按钮/Entry/值控件/形状行/媒体区），切 Animations 再切回仍出画；headless 复现（未修复 `ContentPage frame=0,0,-1x-1`） | Home tab 首屏整页出画；切走/切回保持；无 `-1x-1` 黑区 |
| 1.2 | **FIX-ITOUCH（注入/触摸 element 坐标）** | 宿主 `OnTouch` 原用 `GetTouchPointWindowX/Y` 上报：free window（2in1）的 window 系含页面之上的系统标题栏（本机 70 px），而 XComponent/MAUI 画布与鼠标（`MouseEvent.x/y`）在 **element（surface）系** → 实测 `disp=(1560,719) → win=(1045,438) → elem=(1045,368)`，注入点整体下移 70 px；小控件（按钮 surface y≈334..403）不命中；底部 tab 栏因判据无上界"碰巧"命中（tab 能切、页内不能点的假象）。修复（宿主 `4e9f3c3e`）= 读 touch point 自身 `x/y`（element 系），changed-pointer 主坐标与 pinch 中心一并归一；`openharmony_host.h` 契约注释同步；UND 240→238 | `uiInput click` 命中页内元素（"fading out…" → "animations done"）；偏心探针 0 变化；tab 切换不变 |
| 1.3 | **门禁/指纹** | 交互套件 **544/floor 524**（+4 FIX-HOME pin：父容器 arrange 下钻 / 合成出画 / 切走、切回；`verifyCheckTotal` 540→544、floor 520→524，只增不降）、像素 `PIXEL ASSERTIONS PASSED`（无 `Known`）、宿主导出契约 **149/149**、host UND **238**、denylist 0；**壳 abc 字节不变 339,964/24,324**（无壳源变更）、hap 内宿主 **293,792（`4e9f3c3e…`）**；`verify-kit` 期望不变（339964/24324）；packs/repo-hygiene 25/0、hap-targets 49+1skip、sh -n 39；CI 5/5（见 §7） | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**；套件自报行 `[suite] checks=544 total=544 floor=524 assert=True` |
| 1.4 | **7 hap 重签（新 sha）** | MAUI 5 hap 因宿主变更重建（尺寸小幅变动，最大约 +3 KB；壳/宿主布局不变）、Blazor 两 hap 随站点 `dotnet.js` 指纹刷新（own abc 21,200/21,016 B 不变）：见表 §6.3 | 取件以 release「## Integrity（kit #37）」与包内 `SHA256SUMS` 为准 |

> 尺寸预算：以 release 资产表为准（#36 = 375,627,841 B；#37 = 375,652,577 B，delta = 宿主 + 5 MAUI hap 重建）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **FIX-HOME（主判点 1）** | AOT 件（或包内演示 hap）冷启 → Home tab | 首屏**整页出画**（标题/控件/形状行可见，非纯 chrome 黑区）；切 Animations → 切回 Home 仍出画 | 首屏/切回截图 + hilog |
| **FIX-ITOUCH（主判点 2）** | Animations 页以 `uitest uiInput click` 点「Run animations」（坐标取绘制位） | 按钮文本 **"fading out…" → "animations done"**；偏心/偏靶点（阈值外）**0 变化**；底部 tab 色带切换正常 | 截图（点击前后）+ hilog |
| **套件基座** | 有源码测试者跑 `test/maui-platform-verify` | `[suite] checks=544 total=544 floor=524 assert=True`；4 条 FIX-HOME pin 绿 | 终端输出 |
| **承 #36：payload 原地直载** | MAUI 演示 hap 冷启 | hilog `payload-in-libs: running from …/entry/libs/arm64 (dotnet.zip not unpacked)`；应用出画 | hilog 行 + 截图 |
| **承 #36：a11y 渲染帧** | `--a11y-probe` | `status=1`（attached）+ 正整数 nodeCount（wasm 5 / 主包 24）稳定 | `a11y/selfcheck.txt` + hilog |
| **承 #36：像素 Known 清零（套件侧）** | `test/headless-render` | `PIXEL ASSERTIONS PASSED`，无 `Known(...)` | 终端输出 |
| **承 #36：rc.2 AOT pack `-r2`** | 设备/本机 AOT 构建（feed 用 `-r2`）→ 启动 | publish rc=0；`aot=1` + 主体渲染 | publish 日志 + 启动 hilog |
| **承 #35：W9/W10** | 按 `2026-10-01-ohos-tester-handoff-kit36.md` §2（B2/T14/T21/T8/T20/T19/AOT 入口） | 同 #35/#36 期望；套件自报行 `544/floor 524` | 截图 + hilog + `dotnet-status.txt` |
| **承 #34：rc.2 版本自述 + W6/W7/W8** | 包内《最终状态.md》/`README-交付说明.md`；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6 | SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；逐项同 #34 | 自述原文 + 截图 + `--a11y-probe` |
| **承 #33：Blazor 双 hap A/B / TabbedPage / W5** | 按 #33 判定树与一页卡 | 同 #33 期望（默认 ✅ → CSP 非瓶颈；默认 ❌ nocsp ✅ → CSP 至少次因） | `BLZ_BOOT`/`BLZ_RENDERED` + 截图 |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项（出画/点击/截图）照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#36）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.2.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（承 #36）**：用 `-r2` 修正版 pack（asset 601289590）；设备/本机 AOT 构建无需本地 hooks；
   最小复现与判据见 `docs/plans/2026-09-30-rc2-aotpack-openssl-shim-fix.md` §1/§4。
3. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`（CoreLib `417ab220532` 起）。
4. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 上架后换 pin、删 feed step（承 #34 注记）。
5. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（本文随附；kit #37 manifest 刷新
   **`cfb13f09aab`**）；maui = **`68ec598037`**（FIX-HOME 切片；`eec30c01cd` 为 W9 合并基座）；ohos-workload master
   **`aade43c`**（pin 提交；其上 `30d2adf` FIX-ITOUCH + `5d82f40` FIX-HOME 套件 + `ce4588c` #36）；sdk 锚
   **`d05247b90b`**（bundle 锚 aeb6888a → **8abba9b1**；`-r2` pack 引用保留；SDK CI run `36797281279`）；
   aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#36）：本机桌面 HAD-W32 / OpenHarmony 7.0.0.111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`
  （UDID `1BCE13C8…AEA0`）；SDK `sign-hap.sh` 自签；AOT 路径已验证（rc.2 线；`-r2` feed）。
- **#37 本轮证据**（scratch）：FIX-HOME `fix-home/`（headless 复现 + AOT hap 真机 `device/home-cold.jpeg`/
  `anim.jpeg`/`home-back.jpeg`）；FIX-ITOUCH `fix-itouch/`（exp1–exp5、诊断件、K0–K7 截图：注入
  `(2030,1650)` 切 Animations、偏靶 `(1560,660)` 0 变化、绘制位 `(1560,719)` → "fading out…" → "animations done"、
  tab 往返）——件 `hello-maui-app-fix1.hap` 21,626,085 B / `c5cf86e8…`（基座）；另 `fix-home` 件 21,626,073 B /
  `13549f81…`。
- **已知（承 #34–#36）**：JIT payload-in-libs 主包在本机新镜像装不上（`9568393`；libs 内无扩展名文件不在
  码签块 / 恰好 4096 B 文件的 fs-verity）——主包 JIT 真机判定仍以 tester 机为准；本机可用 AOT 路径。
- **本机可直接闭环**：AOT 出画、Home 页/注入点击、Blazor 标记、a11y/日志/截图回路；命令模板 =
  `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`（窗口竞态与 hilog 缓冲注见其 §4）。

## 5. 自签与包布局要点（测试方视角；承 #34–#36）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap**：payload-in-libs 布局不变（`libs/arm64-v8a/` 原地携带 payload + `.dotnet-payload.json`，
  `dotnet.zip` 回退；模块布局探测命中后原地启动、不解压）；壳 abc **字节不变**（339,964/24,324）；宿主升
  **`4e9f3c3e`**（UND 238）；新 hap sha 以 release/包内 `SHA256SUMS` 为准。
- **AOT 资产**：独立资产，不在 kit tar 内；安装会顶替 kit 主包，回 JIT 需重装 kit hap；数字以 release asset
  与 AOT README 为准（本轮 AOT 包若仍为 `aot-haps-v3*` 系列，以 release 为准；pack 用 `-r2`）。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #37）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs/宿主依赖（UND 238）；abc 期望 = **339,964（`fc54d2b8…`）/24,324（`798b2477…`）** 不变，
   脚本哈希以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮 / `--blazor-probe` / `--mode-matrix` /
   `--a11y-probe` 四件同 #36。
3. **7 hap 表（kit #37 发布实测；`SHA256SUMS` 17 项 / 1,517 B / `1ce87838…`）**：`hello-maui-app.hap`
   **133,976,081 / `f3343b22…`**、`…-unsigned` **131,446,919 / `0697abd6…`**、`…-permissions`
   **133,976,112 / `02cf5b6c…`**、`…-api20` **133,976,143 / `0722553d…`**、`…-api20-permissions`
   **133,976,092 / `34b7d5ca…`**、Blazor 默认 **27,216,958 / `d06b3cf5…`**（own abc 21,200 B、site 213 files、
   dotnet.js 93,218 B）、`-nocsp` **27,216,659 / `4613e4c2…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`；
   own abc 21,016 B）。整包 tar **375,652,577 / `3a7259d6…`**、树 `ab517b57…`、sidecar `7db60a77…`；bundle
   `openharmony-workload-1.0.0-preview.28.tar.gz` **77,754,907 / `8abba9b1…`**（三处同步 versioned `398936638` /
   latest `392077166` / sdkrc2 `398739326`；dist sums 212 B / `a2322146…`；sdkrc2 合并 sums 1,960 B / `999b1e4e…`；
   sdk-ohos 锚 **`d05247b90b`**，`WORKLOAD_BUNDLE_SHA256` aeb6888a → 8abba9b1）；发布已完成（08:35-08:44）：
   kit tar/边车两处（dtk **392356147** / latest **392077166**；tar/边车 asset **602091003**/**602092652**，
   latest 同件 **602092868**/**602094897**）+ bundle 三处；四条 release body 含 `## Integrity (kit #37)`；
   by-id 抽验 0 FAIL + gh-proxy 校验通过（tar HEAD 200/375,652,577）。重签/重打包后必变，以 release 与随包校验为准；
   有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#36）。
4. 离线证据（供复核）：套件 **544/524**（+4 FIX-HOME pin）、像素 PASS（Known 清零）、导出 **149/149**、
   壳 abc **339,964/24,324**（四包一致 + provenance）、host **`4e9f3c3e`**/UND 238、`build-arkts-shell 185/0`、
   `verify-kit 108/0`、packs/repo-hygiene 25/0、hap-targets 49+1skip；#37 设备证据见 scratch
   `fix-home/`、`fix-itouch/` 与 `docs/plans/2026-10-01-ohos-home-page-render.md`、`…injected-touch.md`；
   #36 证据见 `docs/plans/2026-10-01-ohos-tester-handoff-kit36.md` §4。

## 7. 风险 / 未验证（诚实清单）

- **FIX-HOME/FIX-ITOUCH 的 tester 机复核仍待做**：交付方在本机 AOT 闭环（Home 整页出画 + 注入点击命中）；
  不同窗口形态（全屏/分屏）与不同缩放下的注入坐标请按 §2 同法复测；无入口按「未测」登记，不判失败。
- **FIX-ITOUCH 范围**：修的是宿主上报坐标（element 系）；**需要本轮宿主 `4e9f3c3e`**——旧件（`cfbbe461`）
  页内注入不命中属 #36 前已知问题。未改 pin、未改切片（maui 侧仅 FIX-HOME 一笔）。
- **payload 探针 `bundleCodeDir`（承 #36）**：模块布局命中后原地启动；两者皆 miss 时打一行提示并回退
  `dotnet.zip`（功能不丢，仅回到解压路径）——请附该行 hilog 回传。
- **AOT pack 结构性缺陷（上游面，未彻底；承 #36）**：共享 `.so` 与静态 `.a` 对 `FEATURE_DISTRO_AGNOSTIC_SSL`
  需求相反；当前以 fetch 端 shim 内容校验兜底（`-r2`），彻底解法见 `2026-09-30-rc2-aotpack-openssl-shim-fix.md` §5。
- **ICU/InvariantGlobalization**：无 ICU 镜像的 AOT demo 需 `InvariantGlobalization`（demo 配方已含；
  应用侧如遇 hosting 模块初始化 FailFast 可参考）。
- **门禁（本轮已跑）**：交互 544/floor 524（4 FIX-HOME pin；FIX-ITOUCH 无新增行）、像素 PASS（无 `Known(...)`）、
  导出 149/149、包内 `verify-kit.sh` 0 FAIL/0 WARN（abc 期望 339964/24324 不变）、`ohos-workload` master
  **`aade43c`**；CI **5/5** @ `aade43c`（interaction `36797368928` / pixel `36797368976` / host-export
  `36797368951` / ridgraph `36797368923` / markdownlint `36797368944`）、sdk `ohos-install-tests` @ `d05247b90b`
  run `36797281279`（installer 43/43 · hostfeed 10/10 · codesign-filewrites 5/5）。
- 本次构建基线 = **rc.2 线**（SDK `.112` / workload `preview.28` / MAUI `rc2.26478.12`）；应用侧构建请同步该线
  （`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5；rc.1 回滚路径保留）。
