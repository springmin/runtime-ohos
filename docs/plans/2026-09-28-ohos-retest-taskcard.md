# 复测任务单（一页）：kit #40 一轮设备判定（FIX-JSCALL：razor 计数往返 0→1→2 + 挂载/Back/抽屉/注入等承 #39 回归）（2026-10-02）

> 目标：一轮拿全 **#40 增量**（**FIX-JSCALL**（BlazorWebView IPC 出站半边 AOT 扎根：`JSCall` 枚举/
> `NavigationOptions` → **razor 计数往返 0→1→2** 真机））
> + **承 #39** 的 FIX-BACKSIZE（Back 关抽屉 + `BlazorWebView.GetDesiredSize`）/ FIX-BWVMount（`.razor` 挂载）
> + **承 #38** 的 FIX-DISMISS（抽屉外点关闭）/ FIX-WVP（Hybrid 出画+bridge+挂起）
> + **承 #37** 的 FIX-HOME（Home 整页出画）/ FIX-ITOUCH（注入/触摸 element 坐标，页内点击命中）
> + **承 #36** 的 payload 原地直载 / host 预注册缓冲 / 像素 Known 清零 / a11y 渲染帧 / rc.2 AOT pack `-r2`
> + **承 #35** 的 W9/W10（B2 / T14 / T21 / T8 / T20 / T19 / AOT 入口）与 **承 #34/#33** 的 rc.2 版本自述、
> W6/W7/W8、Blazor 双 hap A/B / TabbedPage / W5，并采 JIT/XWE/AOT/解释器/harmony 与无障碍。
> 执行入口 = `tester-run.sh`（版本/大小/摘要**以包内 `SCRIPT_VERSION` 与 release 资产页为准**；承 **v14**，
> 含 `--blazor-probe` / `--mode-matrix` / `--a11y-probe`）。
> 判定树与细节：`docs/plans/2026-10-02-ohos-tester-handoff-kit40.md`（逐项勾选 + §3 rc.2/AOT + §4 本机直测）、
> `docs/plans/2026-10-02-ohos-jscallresult-aot.md`（FIX-JSCALL 根因/`0→1→2` 截图/hilog）、
> `docs/plans/2026-10-02-ohos-kit39-local-verification.md`（#39 本机轮：计数在途的定位）、
> 承 `docs/plans/2026-10-02-ohos-tester-handoff-kit39.md`（FIX-BACKSIZE/BWVMount）、
> `docs/plans/2026-10-01-ohos-tester-handoff-kit38.md`（FIX-DISMISS/FIX-WVP）、
> `docs/plans/2026-09-29-ohos-blazor-regression-retest-card.md`（#33 A/B）。
> 本页只给「取件 → 执行 → 回传 → 判定」。**kit #40 发布实测（release「## Integrity（kit #40）」；发布已完成，
> 一切数字以 release 与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准）**：tar **375,836,470 B / `31ab8732…`**、
> 树 **`e950de54…`**、sidecar **`9b051247…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `7667b6bd…`**
> （#39 = tar 375,765,521 / `e95eed49…` 对照；#38 = tar 375,641,619 / `ced5583f…`）。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #40，2026-10-02） | **375,836,470** | **`31ab8732…`**（sidecar `9b051247…`；树 `e950de54…`；`SHA256SUMS` 17 项 / 1,517 B / `7667b6bd…`；dtk **392356147** / latest **392077166**；tar/边车 asset **605346629**/**605372761**，latest 同件 **605373164**/**605385920**） | **7 hap** = 5 MAUI（壳 abc **342,160（`ffda66da…`）**/24,324（未变）、hap 内宿主 **293,792（`384e552a…`）**（未变）、UND 238；FIX-JSCALL 切片重建 +13KB/hap）+ **2 个 Blazor 对照 hap**（bundle `com.example.opendotnet`，无 INTERNET）+ `verify-kit.sh`（69,522 / `0b7dbfe9…`）+ 文档 |
| `preSigned-haps.tar.gz`（**预签直装**；#34 起加发；**已刷新至 kit #40**） | **376,463,885**（2026-10-02 刷新；asset **605502130**；sidecar 88 B / `9fa506e3…`，asset **605534061**；树 `175c8a4a…`；包内 `SHA256SUMS` 8 项 / 764 B / `efbb28ae…`） | **`193f5fb1…`** | **7 hap = kit #40 原名件**（MAUI 5 + Blazor 默认/`-nocsp`），按 tester UDID `60CF7B27…F8A19` 预签：`sha256sum -c SHA256SUMS` → `hdc install -r` **直装**；非本 UDID 设备仍 `9568344`；#34 旧件（`b492b284…`/asset 600101072）已显式替换、旧哈希作废 |
| AOT 复测取件（`aot-haps*`；**rc.2 pack `-r2` 已修 OpenSSL shim，撤 rc.1 钉**） | **18,185,012**（`aot-haps-v3-rc2.tar.gz`；本批未动） | **`3d24f716…`** | AOT hap（含 UIPage 出画修复）；rc.2 设备/本机构建用修正版 pack **`…11.0.0-rc.2.26451.112-r2.nupkg`**（28,904,657 B / `542058cf…`，asset 601289590）；JIT 主体崩溃或黑屏时用它；装前重签。**#40 的 FIX-JSCALL 请用本轮 kit 件（切片重建）** |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`） |
| `ohos-interpreter-pack.tar.gz` | 2,419,988 | `a10699b3…` | 解释器载荷（`-p:OpenHarmonyInterpreterPack=<解包目录>` 或设备侧 `interp.txt=3`） |
| `tester-run.sh`（随包） | 以包内为准（承 v14 = 140,197 / `a174fcd0…`） | 以包内为准 | 执行器；`--blazor-probe`、`--mode-matrix`、`--a11y-probe` 承 #33 |

包内 7 hap（kit #40 发布实测，`SHA256SUMS` 17 项 / 1,517 B / `7667b6bd…`）：`hello-maui-app.hap` **134,016,353 / `712bd947…`**、`…-unsigned` **131,497,113 / `87e10197…`**、`…-permissions` **134,016,342 / `8773a913…`**、`…-api20` **134,016,335 / `88c6a165…`**、`…-api20-permissions` **134,016,346 / `a35c3467…`**、Blazor 默认 **27,216,958 / `8db8e4ec…`**（own abc 21,200 B、site 213 files、dotnet.js 93,218 B == `dotnet.17opwway9i.js` / `43f9f87e…`）、`-nocsp` **27,216,659 / `0e0af68b…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`；own abc 21,016 B）。

**预签直装捷径（可选）**：`sha256sum -c SHA256SUMS` 后 `hdc install -r` 直装，**§2 的「先重签」可跳过**（同 bundle
换件仍先卸载）；每件 bundle/原 sha/新 sha/安装命令见包内 `preSigned-README.md`（**#40 件已就位**，2026-10-02 刷新；
#34 旧件作废）。它是并列附加件：`verify-kit.sh` 全包校验与 `tester-run.sh` 完整轮仍用 `device-test-kit.tar.gz`。

## 2. 执行顺序（每步「期望 → 回传」）

0. **#40 增量（新，AOT 件优先）**：①**FIX-JSCALL 计数往返（主判点）**：打开 razor 页 → 点 **"Blazor click" 两次** → 期望 **count 0→1→2**（截图 r0/r1/r2）；hilog 期望 `missing native code`=0、`BeginInvokeDotNet accepted`、`send head=__bwv:["BeginInvokeJS",…]`；页内 probe tail `| plain ok`（managed→JS 半边）；②**承 #39**：`.razor` 组件挂载（"BlazorWebView component (.razor)" + count + 按钮）、系统 **Back 关抽屉**（再 Back 收后台）、BlazorWebView 在控件 frame 内出画；③套件自报行 **`[suite] checks=555 total=555 floor=535 assert=True`** → 回传截图 + hilog + `[suite]` 行。
1. **校验 kit**：包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap；abc 期望 **342,160/24,324**、host UND 238，脚本哈希 `0b7dbfe9…` 以包内为准）→ 回传终端输出。
2. **rc.2 版本自述**：读包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary → 期望 SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；无 rc.1 混装告警 → 回传自述原文 + summary。
3. **承 #39**：FIX-BACKSIZE = 抽屉开 → 系统 Back 关抽屉（窗口仍 `#FOREGROUND`）、再 Back → `#BACKGROUND`；BlazorWebView 尺寸 = 控件 frame 内出画；FIX-BWVMount = `.razor` 挂载 → 回传截图 + hilog。
4. **承 #38**：FIX-DISMISS = 抽屉开 → **面板外 click 关闭**（重开/再关）；FIX-WVP = Hybrid 白区真出画（`origin https://0.0.0.1/` + probe 表）+ 页↔宿主 bridge（`sent #n via window.external.sendMessage` + 托管 `hybrid raw message: …`）+ 抽屉/切页挂起恢复 → 回传截图 + hilog。
5. **承 #37**：FIX-HOME = Home tab 首屏整页出画 + 切走/切回；FIX-ITOUCH = 注入点击命中页内元素（偏心点 0 变化）→ 回传截图 + hilog。
6. **承 #36**：payload 原地直载（hilog `payload-in-libs: running from /data/storage/el1/bundle/entry/libs/arm64 (dotnet.zip not unpacked)`）+ `--a11y-probe`（`status=1`、nodeCount 正整数；wasm 5 / 主包 24）→ 回传 hilog + `a11y/` 两文件。
7. **B2：MAUI WebView 内嵌 Blazor WASM（承 #35 主判点）**：装含 WebView/WASM 入口的包内演示 hap（或按 release/包内说明构建），AOT 路径启动 → 打开嵌入式 Blazor 页 → 期望 **`BLZ_BOOT` + `BLZ_RENDERED` 同 pid 双标记齐**（无 `BLZ_ERROR`）、首屏渲染、`/counter` 类交互 +1 → 回传 hilog + 首屏/交互截图。
8. **W9B：T14 收尾 + T21 字体缩放**：T14 = flyout 富头/项/尾行、项模板（`Shell.ItemTemplate`）/多段项、点行选中 + 关抽屉、模板内按钮可点不误关；T21 = 系统字号/`FontScale` 变化（含 0.5/3 边界与非法值）后 Label/Formatted 尺寸与 Entry 光标跟随、越界被钳制 → 逐条截图 + 结果。
9. **W9C：T8 不等高 TableView**：不等高行（含等高切换、滚动、更新/增删）→ 行不重叠、总高一致、滚动/更新正确；切回等高恢复 → 截图 + 滚动/更新结果。
10. **W9D：T20 媒体传输层 + T19 深链**：媒体演示入口/热触发（`app://media/probe` 类）→ **无 MediaKit 镜像属预期**：`IsSupported=false`、各调用 `Unavailable/Failed` **不抛**（真播放需 Kit 完整镜像/HMS 设备，回传壳自检 `media self-test …` 行）；深链用 `hdc shell aa start -U app://…` 冷/热各一次 → 热期望 `delivered=1`（冷 `delivered=0` 为设计内）→ 回传 hilog 行。
11. **W10：AOT 入口可观测（承 #35）**：AOT hap 启动后读 `<files>/dotnet-status.txt`（壳轮询 tail 打 hilog）→ 期望出现托管入口/AOT 决策行（不再只有宿主 probe 行）；附 `aot=` 行 → 回传 status 文本/hilog。
12. **承 #34：W6/W7/W8**：W6 = T14（步骤 8 已含）/T12 CarouselView 分组/N1 多指/FIX-SHELL 主体；W7/W8 = T15 富 TitleView / T16 结构化菜单 / N4 TitleBar a11y（`--a11y-probe`）/ T18 IMap / N5 覆盖层触摸抑制 / N6 系统装饰 → 逐条截图/终端输出（期望同 #34；套件自报行 **`[suite] checks=555 total=555 floor=535 assert=True`**）。
13. **承 #33：Blazor A/B（先分别重签两个变体；用预签直装包可直接装）**：装默认件 → `sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe` → 记录 `BLZ_BOOT`/`BLZ_RENDERED`（宿主 pid + nonce）与人工首屏/`/counter` +1/截图；**卸载后**装 `-nocsp` 件 → 同命令 → 按 #33 判读表落结论。
14. **承 #33：MAUI 主体（TabbedPage/W5）**：双页签内容出画、切页正常；T13/N3/T21/T22；失败回传截图 + hilog。**JIT 若启动/主体仍崩（`SEGV_ACCERR`）或黑屏：重签安装 AOT 资产内未签 hap（会顶替 kit 主包；本轮设备构建用 rc.2 pack `-r2`）→ 启动 → `aot=1` → 判主体渲染**。
15. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./<aot-asset>.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60` → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全 → 回传 `mode-matrix/` 全目录 + 四个 `tester-report-*.tar.gz`。
16. **无障碍（含 N4）**：加 `--a11y-probe` → `a11y/selfcheck.txt`（status=1 + 正整数节点数，wasm 页 5 / 主包 24 为最新实测参照）+ `a11y/hilog-a11y.txt`；TabbedPage 当前页跟随（承 #33）+ `Window.TitleBar` 行进树（#34）→ 回传 `a11y/` 两文件 + `summary a11y_*` + 录屏。
17. **WebView 六项 + B1 razor（承 #32）**：按《WebView / Blazor Hybrid 真机验证卡》9 项逐条操作 → 回传截图 + hilog。
18. **harmony 变体（AGC 就绪时）**：同指纹重签 `harmony-haps.tar.gz` → Map/LiveView 点亮 + TTS/HUKS 证据 → 回传截图/状态原文。

## 3. 判定表（逐 Run 填）

| 态/项 | 判据 | 结论 |
|---|---|---|
| **FIX-JSCALL 计数往返（#40 主判点）** | razor 页点 "Blazor click" 两次 → **count 0→1→2**（截图 r0/r1/r2）；`missing native code`=0；`BeginInvokeDotNet` accepted；`send head=__bwv:["BeginInvokeJS",…]` | #40 落地 |
| **套件基座（#40）** | `[suite] checks=555 total=555 floor=535 assert=True`（+1 FIX-JSCALL pin：JsonContext 三类型 + handler 静态构造 + 桩探针移除）；导出 150/150 | #40 基座 |
| **FIX-BACKSIZE Back（承 #39）** | 抽屉开 → 系统 Back 关抽屉（仍 `#FOREGROUND`）；再 Back → `#BACKGROUND` | 承 #39 保持 |
| **FIX-BACKSIZE 尺寸（承 #39）** | `BlazorWebView` 在控件 frame 内出画（非整窗/退化） | 承 #39 保持 |
| **FIX-BWVMount（承 #39）** | `.razor` 挂载：页内 "BlazorWebView component (.razor)" + `count: 0` + "Blazor click"；`[maui] blazor start/connect` + `BLZ_DIAG` | 承 #39 保持 |
| **FIX-DISMISS / FIX-WVP（承 #38）** | 抽屉外点关闭（重开/再关）；Hybrid 白区真出画 + bridge 往返；抽屉/切页挂起恢复 | 承 #38 保持 |
| **FIX-HOME / FIX-ITOUCH（承 #37）** | Home tab 首屏整页出画 + 切走/切回；注入/触摸 element 坐标命中 | 承 #37 保持 |
| **payload 原地直载（承 #36）** | hilog `payload-in-libs: running from …/entry/libs/arm64 (dotnet.zip not unpacked)`；B2 页正常出画 | 承 #36 保持 |
| **像素/a11y（承 #36）** | 像素套件无 `Known(...)`（套件侧）；`--a11y-probe`：`status=1` + 正整数 nodeCount（5/24）稳定 | 承 #36 保持 |
| **AOT pack `-r2`（承 #36）** | rc.2 AOT pack `-r2`（asset 601289590）设备 AOT 构建 publish/启动成立；rc.1 钉撤销 | 承 #36 保持 |
| **B2 真机 BLZ** | `BLZ_BOOT` + `BLZ_RENDERED` 同 pid 双标记、无 `BLZ_ERROR`；首屏 + `/counter` 类交互 | 承 #35 落地 |
| **T14 收尾 / T21 / T8** | 同 #35：flyout 富行；字体缩放跟随/钳制；不等高行不重叠、滚动/更新正确 | 承 #35 落地 |
| **T20 媒体（无 Kit 降级）** | 无 MediaKit：`IsSupported=false`、各调用 `Unavailable/Failed` 不抛；有 Kit：播放/事件/状态 | 承 #35；无 Kit 不判失败 |
| **T19 深链** | 冷/热均投递 ability，**热 `delivered=1`**；未知路由无异常（冷 `delivered=0` 设计内） | 承 #35 判定成立 |
| **AOT 入口可观测** | `<files>/dotnet-status.txt` 出现托管入口/AOT 决策行 + `aot=1` | 承 #35 落地 |
| rc.2 基线 | 版本自述 = SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；无混装 | rc.2 线成立 |
| T12 分组 Carousel / FIX-SHELL / N1 | `GroupHeader`/`GroupFooter` 滑片、跨组滑动、`CurrentItem` 跟随；Shell 出画 + 切页重绘；多指轨迹正确 | W6（承 #34） |
| T15 / T16 / N4 | 富 TitleView 出模板 + 按钮可点；结构化菜单组头/层级/门控；TitleBar 行进影子树 | W7（承 #34） |
| T18 IMap / N5 / N6 | 有 app 拉起、无 `TryOpenAsync=false` 不抛；选择器下层不激活/关恢复；窗口装饰 + 拖拽 + Content 按钮不被抢 | W8（承 #34） |
| Blazor A/B（默认 CSP） | `BLZ_BOOT` + `BLZ_RENDERED`（pid+nonce，无 `BLZ_ERROR`）+ 首屏 + `/counter` 0→1 | #33 修复保持 |
| Blazor A/B（`-nocsp`） | 同上；默认不通而它通 → CSP 至少是次因 | 按 #33 判读表落结论 |
| MAUI 主体（TabbedPage/W5） | 双页签出画 + 切页；T13/N3/T21/T22 四项；套件 `555 total=555 floor=535 assert=True` | #33 保持 |
| JIT / XWE / AOT | `run_a_probe_1=OK` + `xwe=0 source=default`；A 不通时 B `xwe=1 source=file`；AOT `run_d_aot_route=1` + `aot=1` + 主体渲染（rc.2 pack `-r2`） | 直启/回退判定 |
| 解释器 / harmony / runtime_mode | `run_c_interp_mode=3(file)`（清单 `3(manifest)`）+ maps 含 `libclrinterpreter.so`；`IsOverlayAvailable=true` + Map/LiveView 点亮；`summary runtime_mode=jit(hap)` + `runtime-mode=jit source=manifest` | 各判定成立 |
| WebView / B1 razor | 同 #32（9 项卡 + B1 两标记 + JS 往返） | 按 #32 判据 |

> 失败 Run 保留报告 tar；无入口项登记「未测（本包无入口/无 hdc）」，不判失败。

## 4. 注意

- 包内 hap 为自签：**9568257 / 9568344 属预期**，先重签（需华为调试证书 + Profile 绑 UDID）；**Blazor 双变体同名（`com.example.opendotnet`），装前卸载**；两变体均无 INTERNET（重签保持）。
- **FIX-JSCALL 口径**：需本轮 kit 件（切片 `15d81f31b1` 重建；壳/宿主与 #39 同值）；修复点 = IPC 出站半边三类型（`JSCallResultType`/`JSCallType`/`NavigationOptions`）并入切片源生成上下文 + handler 静态构造触碰 + 移除 FIX-BWVMount 桩探针。**任何新上线的值类型都需要 context 条目 + 静态构造触碰**（预防口径见 handoff §1.3）。
- **在途/后续项（明确）**：①`blzProbe` 未被 razor 样例定义——该 probe 调用过线后报 JSException（`plain ok` 已证 managed→JS 半边，样例未动）；②`NavigationOptions` 为**预防性扎根**，本轮未在真机点 live Navigate；③**多覆盖层**（同页多 web 控件共享单 ArkWeb；hybrid 已注册时 Blazor frame 有意 withheld）仍为后续。相关项登记「未测（在途）」不判失败。
- **rc.2 相关**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；rc.1 回滚线保留；应用侧构建请同步 rc.2 线（`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5）。
- **AOT 包（承 #36）**：rc.2 NativeAOT OpenHarmony pack 的 OpenSSL shim 缺陷已由修正版 **`-r2`**（asset **601289590**，`nm … | grep -cE 'local_(EVP|SSL|X509)'` ≥ 5）修复——**撤销 #35 的 rc.1 钉**，设备/本机 AOT 构建直接用 `-r2` feed；若环境缓存过坏包，删 `~/.nuget/packages/microsoft.netcore.app.runtime.nativeaot.openharmony-arm64/11.0.0-rc.2.26451.112` 后再 publish。AOT hap 只有 3 个 `.so`，勿用 JIT 期望值核对。
- **hilog 缓冲（探针误报防护）**：本机实测 512K 环在噪声大时只保留 ≈4–5 s，`--blazor-probe` 4 s 窗口曾丢 `BLZ_BOOT` 报 `boot=no`（同轮流式复核两标记齐全，非渲染缺陷）；临时 `hilog -G 16M -t app,core` 重跑即全绿（**跑完还原 512K**）。tester 机缓冲待核对。
- **本机直测（交付方）**：设备已可测（hdc 无线 `127.0.0.1:35111` + SDK 自签 + AOT 路径）；**JIT payload-in-libs 主包在本机新镜像装不上属已知**（`9568393`，非 kit 缺陷），主包 JIT 判定仍以 tester 机为准。
- 所有数字 = **kit #40 发布实测（以 release「## Integrity（kit #40）」与随包校验为准）**：tar **375,836,470 / `31ab8732…`**、树 `e950de54…`、sidecar `9b051247…`、`SHA256SUMS` 17 项 / 1,517 B / `7667b6bd…`；#39 = tar 375,765,521 / `e95eed49…`、#34 = tar 375,181,367 / `55834aeb…`；tester-run v14 = 140,197 / `a174fcd0…` 仅作对照；bundle = `workload-1.0.0-preview.28` **77,750,495 / `434d2b6f…`**（三处同步；dist sums `38281349…`；sdkrc2 合并 sums 1,960 B / `c53fca53…`；sdk 锚 **`77ffe1dad6`**）；dtk **392356147** / latest **392077166**（asset **605346629**/**605372761**）；CI **5/5** @ `9073c65`（interaction `36989506879` / pixel `36989506893` / host-export `36989506617` / ridgraph `36989506653` / markdownlint `36989506646`）；sdk `ohos-install-tests` @ `77ffe1dad6` run `36993177948`）。
- 细判（TTS/HUKS/自绘深度/权限/Share-Scan）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2 与 `…kit29/kit28/kit27/kit26/kit25`；无障碍逐项：`docs/plans/2026-09-27-ohos-accessibility-device-verification.md`（含 N4）；B2 细节：`docs/plans/2026-09-30-ohos-blazor-wasm-webview-b2.md`、`…wave10-consolidation.md`；FIX-JSCALL 细节：`2026-10-02-ohos-jscallresult-aot.md` 与 `2026-10-02-ohos-tester-handoff-kit40.md`。
