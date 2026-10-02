# 复测任务单（一页）：kit #41 一轮设备判定（MULTI-OVERLAY-FULL / DEVCOMPAT-DEFAULT / INTERP-FIX + 预签刷新 + 承 #40 回归）（2026-10-03）

> 目标：一轮拿全 **#41 三大彻底修复**（**MULTI-OVERLAY-FULL**（双槽 ArkWeb 覆盖层池 + owner 感知 LRU 抢占/恢复 +
> per-slot hybrid serve/message/invoke + 动态 z-order）· **DEVCOMPAT-DEFAULT**（payload 逐文件码签重写默认化，
> enforcing 镜像开箱可装）· **INTERP-FIX**（宿主 8 MB app 栈 + `interp=3` 关 GC 写屏障；rc.2 解释器 pack））
> + **#41 预签刷新**（tester UDID；直装捷径已更新）
> + **承 #40** 的 FIX-JSCALL（razor 计数往返 0→1→2）+ **承 #39** 的 FIX-BACKSIZE（Back 关抽屉 + BlazorWebView 尺寸）/
> FIX-BWVMount（`.razor` 挂载）+ **承 #38** 的 FIX-DISMISS / FIX-WVP + **承 #37** 的 FIX-HOME / FIX-ITOUCH
> + **承 #36** 的 payload 原地直载 / a11y / 像素清零 / rc.2 AOT pack `-r2` + **承 #35** 的 W9/W10
> 与 **承 #34/#33** 的 rc.2 版本自述、W6/W7/W8、Blazor 双 hap A/B，并采 JIT/XWE/AOT/解释器/harmony 与无障碍。
> 执行入口 = `tester-run.sh`（版本/大小/摘要**以包内 `SCRIPT_VERSION` 与 release 资产页为准**；承 **v14**，
> 含 `--blazor-probe` / `--mode-matrix` / `--a11y-probe`）。
> 判定树与细节：`docs/plans/2026-10-03-ohos-tester-handoff-kit41.md`（逐项勾选 + §3 rc.2/AOT + §4 本机直测）、
> `docs/plans/2026-10-02-ohos-multi-overlay.md`（§FULL：LRU 槽/per-slot 通道/r13 设备证据）、
> `docs/plans/2026-10-02-ohos-payload-sign-default.md`（DEVCOMPAT-DEFAULT）、
> `docs/plans/2026-10-02-ohos-interp-fix.md`（INTERP-FIX 根因/rc2 重建）、
> `docs/plans/2026-10-02-ohos-final-consolidation.md`（三修复合并对账）、
> 承 `docs/plans/2026-10-02-ohos-tester-handoff-kit40.md`（FIX-JSCALL）、
> `docs/plans/2026-10-02-ohos-tester-handoff-kit39.md`（FIX-BACKSIZE/BWVMount）。
> 本页只给「取件 → 执行 → 回传 → 判定」。**kit #41 发布实测（release「## Integrity（kit #41）」；发布已完成，
> 一切数字以 release 与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准）**：tar **376,036,502 B / `bed460ae…`**、
> 树 **`7ce1946e…`**、sidecar **`2a95e764…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `421a819c…`**
> （#40 = tar 375,836,470 / `31ab8732…` 对照）。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #41，2026-10-03） | **376,036,502** | **`bed460ae…`**（sidecar `2a95e764…`；树 `7ce1946e…`；`SHA256SUMS` 17 项 / 1,517 B / `421a819c…`；dtk **392356147** / latest **392077166**；tar/边车 asset **606151881**/**606161455**，latest 同件 **606161664**/**606170379**） | **7 hap** = 5 MAUI（壳 abc **356,140（`2a90f0d7…`）**/24,324、hap 内宿主 **293,792（`8d67def3…`）**、UND 239；15 `.so` / 257 zip 条目）+ **2 个 Blazor 对照 hap**（bundle `com.example.opendotnet`，无 INTERNET）+ `verify-kit.sh`（69,717 / `efa27d31…`）+ 文档 |
| `preSigned-haps.tar.gz`（**预签直装**；#34 起加发；**已刷新至 kit #41**） | **376,684,381**（2026-10-03 刷新；asset **606183753**；sidecar 88 B / `4198a3ec…`，asset **606192909**；树 `9923ad22…`；包内 `preSigned-README.md` 5,502 B / `b995c131…`；`SHA256SUMS` 8 项 / 764 B / `2c3cf6c8…`） | **`2075650a…`** | **7 hap = kit #41 原名件**（MAUI 5 + Blazor 默认/`-nocsp`，7/7 ZIP 条目与 kit 原件逐字节一致），按 tester UDID `60CF7B27…F8A19` 预签：`sha256sum -c SHA256SUMS` → `hdc install -r` **直装**；非本 UDID 设备仍 `9568344`；#40 旧件（`193f5fb1…`/asset 605502130）已被**显式替换**、旧哈希作废 |
| AOT 复测取件（`aot-haps*`；**rc.2 pack `-r2` 已修 OpenSSL shim，撤 rc.1 钉**） | **18,185,012**（`aot-haps-v3-rc2.tar.gz`；本批未动） | **`3d24f716…`** | AOT hap（含 UIPage 出画修复）；rc.2 设备/本机构建用修正版 pack **`…11.0.0-rc.2.26451.112-r2.nupkg`**（28,904,657 B / `542058cf…`，asset 601289590）；JIT 主体崩溃或黑屏时用它；装前重签 |
| **解释器 pack（本轮更新）** `ohos-interpreter-pack-rc2.tar.gz` | **2,409,070**（asset **605924427**） | **`34709a94…`** | **INTERP-FIX 的 rc.2 重建**（`libcoreclr.so` 5,130,328 / `fd79f2bf…` + `libclrinterpreter.so` 268,320 / `75360e65…`）；配 #41 宿主（8 MB 栈 + `interp=3` 关写屏障）使用；**旧 rc.1 pack（2,419,988 / `a10699b3…`）保留作对照** |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`） |
| `tester-run.sh`（随包） | 以包内为准（承 v14 = 140,197 / `a174fcd0…`） | 以包内为准 | 执行器；`--blazor-probe`、`--mode-matrix`、`--a11y-probe` 承 #33 |

包内 7 hap（kit #41 发布实测，`SHA256SUMS` 17 项 / 1,517 B / `421a819c…`）：`hello-maui-app.hap` **134,087,950 / `99691f13…`**、`…-unsigned` **131,564,335 / `9b489acb…`**、`…-permissions` **134,087,949 / `9d4224b1…`**、`…-api20` **134,088,542 / `6e0c23d2…`**、`…-api20-permissions` **134,088,499 / `7b0ac346…`**、Blazor 默认 **27,216,958 / `d6237e96…`**（own abc 21,200 B、site 213 files、dotnet.js 93,218 B == `dotnet.bx7u3hgxop.js` / `9f8a0ab4…`）、`-nocsp` **27,216,659 / `1d763d35…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`；own abc 21,016 B）。

**预签直装捷径（可选）**：`sha256sum -c SHA256SUMS` 后 `hdc install -r` 直装，**§2 的「先重签」可跳过**（同 bundle
换件仍先卸载）；每件 bundle/原 sha/新 sha/安装命令见包内 `preSigned-README.md`（**#41 件已就位**，2026-10-03 刷新；
#40 旧件作废）。它是并列附加件：`verify-kit.sh` 全包校验与 `tester-run.sh` 完整轮仍用 `device-test-kit.tar.gz`。

## 2. 执行顺序（每步「期望 → 回传」）

0. **#41 三大修复（新，AOT 件优先）**：①**MULTI-OVERLAY-FULL**：打开含两个 web 控件的页 → **两白区同时出画**（上 hybrid `origin https://0.0.0.1/ | readyState: complete`、下 Blazor `https://0.0.0.0/`）；hybrid 页内按钮 → 托管 label `A raw: A-raw-ping` / `B raw: B-raw-ping`（**per-slot 消息闭环**）；两页各自 `invoke: "A-echo:Echo:1"` / `"B-echo:Echo:1"`（**per-slot invoke 闭环**）→ 点 **"Add web C"** → 按钮变 "web C added (3 web controls, 2 slots)"、**A 被 LRU 抢占（空白）**、B/C 仍出画 → 点 **"Activate hybrid A"** → A 恢复重放、B 被抢（空白）、C 仍在；B 对称；**动态 z-order**：重叠控件页复核（在途，见 §4）；②**DEVCOMPAT-DEFAULT**：默认设置下装主 hap（enforcing 7.0.0.111+）→ **开箱可装**（无扩展名→`.so`、恰 4096 B→+4100；构建日志 `device compat: enabled … (N rewrite(s))`）；③**INTERP-FIX**：`--mode-matrix` Run C 用 **rc2 pack**（`ohos-interpreter-pack-rc2.tar.gz`）→ 存活出画、faultlogger **0 条新 `cppcrash`**、`canvas presented`；maps 含 `libclrinterpreter.so`；④套件自报行 **`[suite] checks=563 total=563 floor=543 assert=True`** → 回传截图 + hilog + `[suite]` 行。
1. **校验 kit**：包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap；abc 期望 **356,140/24,324**、**15 `.so` / 257 zip 条目**、host UND 239，脚本哈希 `efa27d31…` 以包内为准）→ 回传终端输出。
2. **rc.2 版本自述**：读包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary → 期望 SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；无 rc.1 混装告警 → 回传自述原文 + summary。
3. **承 #40**：FIX-JSCALL = razor 页点 "Blazor click" 两次 → **count 0→1→2**；hilog `missing native code`=0 → 回传截图 r0/r1/r2 + hilog。
4. **承 #39**：FIX-BACKSIZE = 抽屉开 → 系统 Back 关抽屉（仍 `#FOREGROUND`）、再 Back → `#BACKGROUND`；BlazorWebView 在控件 frame 内出画；FIX-BWVMount = `.razor` 挂载（组件区 + count + 按钮）→ 回传截图 + hilog。
5. **承 #38**：FIX-DISMISS = 抽屉开 → **面板外 click 关闭**（重开/再关）；FIX-WVP = Hybrid 出画 + 页↔宿主 bridge（`sent #n via window.external.sendMessage` + `hybrid raw message`）→ 回传截图 + hilog。
6. **承 #37**：FIX-HOME = Home tab 首屏整页出画 + 切走/切回；FIX-ITOUCH = 注入点击命中页内元素（偏心点 0 变化）→ 回传截图 + hilog。
7. **承 #36**：payload 原地直载（hilog `payload-in-libs: running from …/entry/libs/arm64 (dotnet.zip not unpacked)`）+ `--a11y-probe`（`status=1`、nodeCount 正整数；wasm 5 / 主包 24）→ 回传 hilog + `a11y/` 两文件。
8. **B2：MAUI WebView 内嵌 Blazor WASM（承 #35 主判点）**：装含 WebView/WASM 入口的包内演示 hap（或按 release/包内说明构建），AOT 路径启动 → 打开嵌入式 Blazor 页 → 期望 **`BLZ_BOOT` + `BLZ_RENDERED` 同 pid 双标记齐**（无 `BLZ_ERROR`）、首屏渲染、`/counter` 类交互 +1 → 回传 hilog + 首屏/交互截图。
9. **W9B：T14 收尾 + T21 字体缩放**：T14 = flyout 富头/项/尾行、项模板（`Shell.ItemTemplate`）/多段项、点行选中 + 关抽屉、模板内按钮可点不误关；T21 = 系统字号/`FontScale` 变化（含 0.5/3 边界与非法值）后 Label/Formatted 尺寸与 Entry 光标跟随、越界被钳制 → 逐条截图 + 结果。
10. **W9C：T8 不等高 TableView**：不等高行（含等高切换、滚动、更新/增删）→ 行不重叠、总高一致、滚动/更新正确；切回等高恢复 → 截图 + 滚动/更新结果。
11. **W9D：T20 媒体传输层 + T19 深链**：媒体演示入口/热触发（`app://media/probe` 类）→ **无 MediaKit 镜像属预期**：`IsSupported=false`、各调用 `Unavailable/Failed` **不抛**（真播放需 Kit 完整镜像/HMS 设备，回传壳自检 `media self-test …` 行）；深链用 `hdc shell aa start -U app://…` 冷/热各一次 → 热期望 `delivered=1`（冷 `delivered=0` 为设计内）→ 回传 hilog 行。
12. **W10：AOT 入口可观测（承 #35）**：AOT hap 启动后读 `<files>/dotnet-status.txt`（壳轮询 tail 打 hilog）→ 期望出现托管入口/AOT 决策行（不再只有宿主 probe 行）；附 `aot=` 行 → 回传 status 文本/hilog。
13. **承 #34：W6/W7/W8**：W6 = T14（步骤 9 已含）/T12 CarouselView 分组/N1 多指/FIX-SHELL 主体；W7/W8 = T15 富 TitleView / T16 结构化菜单 / N4 TitleBar a11y（`--a11y-probe`）/ T18 IMap / N5 覆盖层触摸抑制 / N6 系统装饰 → 逐条截图/终端输出（期望同 #34；套件自报行 **`[suite] checks=563 total=563 floor=543 assert=True`**）。
14. **承 #33：Blazor A/B（先分别重签两个变体；用预签直装包可直接装）**：装默认件 → `sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe` → 记录 `BLZ_BOOT`/`BLZ_RENDERED`（宿主 pid + nonce）与人工首屏/`/counter` +1/截图；**卸载后**装 `-nocsp` 件 → 同命令 → 按 #33 判读表落结论。
15. **承 #33：MAUI 主体（TabbedPage/W5）**：双页签内容出画、切页正常；T13/N3/T21/T22；失败回传截图 + hilog。**JIT 若启动/主体仍崩（`SEGV_ACCERR`）或黑屏：重签安装 AOT 资产内未签 hap（会顶替 kit 主包；本轮设备构建用 rc.2 pack `-r2`）→ 启动 → `aot=1` → 判主体渲染**。
16. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./<aot-asset>.tar.gz --interp-pack ./ohos-interpreter-pack-rc2.tar.gz --capture 60` → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全 → 回传 `mode-matrix/` 全目录 + 四个 `tester-report-*.tar.gz`。
17. **无障碍（含 N4）**：加 `--a11y-probe` → `a11y/selfcheck.txt`（status=1 + 正整数节点数，wasm 页 5 / 主包 24 为最新实测参照）+ `a11y/hilog-a11y.txt`；TabbedPage 当前页跟随（承 #33）+ `Window.TitleBar` 行进树（#34）→ 回传 `a11y/` 两文件 + `summary a11y_*` + 录屏。
18. **WebView 六项 + B1 razor（承 #32）**：按《WebView / Blazor Hybrid 真机验证卡》9 项逐条操作 → 回传截图 + hilog。
19. **harmony 变体（AGC 就绪时）**：同指纹重签 `harmony-haps.tar.gz` → Map/LiveView 点亮 + TTS/HUKS 证据 → 回传截图/状态原文。

## 3. 判定表（逐 Run 填）

| 态/项 | 判据 | 结论 |
|---|---|---|
| **MULTI-OVERLAY-FULL 出画（#41）** | 同页两 web 控件**两白区同时出画**（hybrid `0.0.0.1` + Blazor `0.0.0.0`）；hilog `web serve`/`web page (slot 0/1)` | #41 落地 |
| **per-slot invoke/消息（#41）** | A/B 两 Hybrid 各自 `invoke: "X-echo:Echo:1"` + 托管 label `X raw: X-raw-ping`（互不串槽） | #41 落地 |
| **LRU 抢占与恢复（#41）** | "Add web C" → A 空白、B/C 出画（"3 web controls, 2 slots"）；"Activate hybrid A" → A 恢复重放、B 空白、C 仍在；B 对称 | #41 落地 |
| **动态 z-order（#41，重叠页在途）** | 重叠 web 控件页：最近激活者置顶（`webZOrder`） | **在途复核项**（纵向不重叠布局未取决定性截图，不判失败） |
| **DEVCOMPAT-DEFAULT（#41）** | enforcing 7.0.0.111+ 默认设置下主 hap **开箱可装**（无 `9568393`）；构建日志 `device compat: enabled … (N rewrite(s))`；15 `.so` / 257 zip | #41 落地 |
| **INTERP-FIX（#41）** | `--mode-matrix` Run C（rc2 pack）→ 存活出画、**0 条新 `cppcrash`**、`canvas presented`；maps 含 `libclrinterpreter.so`；`summary interp_mode=3(file)` | #41 落地 |
| **套件基座（#41）** | `[suite] checks=563 total=563 floor=543 assert=True`（+4 MULTI-OVERLAY-FULL pin）；导出 150/150 | #41 基座 |
| **FIX-JSCALL（承 #40）** | razor 页点 "Blazor click" 两次 → count 0→1→2；`missing native code`=0 | 承 #40 保持 |
| **FIX-BACKSIZE / FIX-BWVMount（承 #39）** | Back 关抽屉（再 Back 收后台）；`.razor` 挂载（组件区 + count + 按钮） | 承 #39 保持 |
| **FIX-DISMISS / FIX-WVP（承 #38）** | 抽屉外点关闭（重开/再关）；Hybrid 出画 + bridge 往返；抽屉/切页挂起恢复 | 承 #38 保持 |
| **FIX-HOME / FIX-ITOUCH（承 #37）** | Home tab 首屏整页出画 + 切走/切回；注入/触摸 element 坐标命中 | 承 #37 保持 |
| **payload 原地直载 / 像素 / a11y（承 #36）** | hilog `payload-in-libs: running from …`；像素无 `Known`；`status=1` + nodeCount 5/24 | 承 #36 保持 |
| **AOT pack `-r2`（承 #36）** | rc.2 AOT pack `-r2`（asset 601289590）设备 AOT 构建 publish/启动成立；rc.1 钉撤销 | 承 #36 保持 |
| **B2 真机 BLZ** | `BLZ_BOOT` + `BLZ_RENDERED` 同 pid 双标记、无 `BLZ_ERROR`；首屏 + `/counter` 类交互 | 承 #35 落地 |
| **T14 / T21 / T8 / T20 / T19 / AOT 入口（承 #35）** | 同 #35 各判据（无 Kit 媒体不判失败；冷 `delivered=0` 设计内） | 承 #35 落地 |
| rc.2 基线 + W6/W7/W8（承 #34） | 版本自述 = SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6 | rc.2 线成立 |
| Blazor A/B + 主体（承 #33） | 默认/nocsp 双标记 + 首屏/`/counter`；TabbedPage/W5 四项；套件 `563 total=563 floor=543 assert=True` | #33 保持 |
| JIT / XWE / AOT / 解释器 / harmony / runtime_mode | 各态判据同 #27–#35；解释器轮见 INTERP-FIX 行 | 各判定成立 |
| WebView / B1 razor（承 #32） | 9 项卡 + B1 两标记 + JS 往返 | 按 #32 判据 |

> 失败 Run 保留报告 tar；无入口项登记「未测（本包无入口/无 hdc）」，不判失败。

## 4. 注意

- 包内 hap 为自签：**9568257 / 9568344 属预期**，先重签（需华为调试证书 + Profile 绑 UDID）；**预签件已刷新至 #41**（直装路径可跳过重签；非本 UDID 仍 `9568344`）；**Blazor 双变体同名（`com.example.opendotnet`），装前卸载**；两变体均无 INTERNET（重签保持）。
- **MULTI-OVERLAY-FULL 口径**：槽池上限 2——第 3 个并发 web 控件按 **LRU 抢占**（未 engaged 优先、其后最久未用）；被抢 handler suspend，显式使用（Source/重载/eval/注册/激活）才恢复并重放 load；z-order 随激活序动态置顶。**多 Hybrid 同页**需 per-slot invoke（本版已带）；旧无槽 id 仍回退"最后注册 hybrid"（兼容）。
- **DEVCOMPAT-DEFAULT 口径**：默认重写（无扩展名→`.so`/`.bin`、恰 4096 B→+4 B、`dotnet.zip` 回退保原字节）；逃生口 `-p:OpenHarmonyHapPayloadInLibsDeviceCompat=false`（原名原字节 + 告警点名）。**4096 B 规则仅本镜像实测**（7.0.0.105 未复测）。
- **INTERP-FIX 口径**：宿主 8 MB app 栈覆盖 PAL 1.5 MB 探针（`EnsureStackSize` `SIGSEGV_MAPERR` 根因）；`interp=3` 时注入 `DOTNET_UseGCWriteBarrierCopy=0`（JIT/混合模式保持默认）。rc2 pack 只配 #41 宿主使用；`interp.txt=1|2` 混合模式保留默认。
- **在途/后续项（明确）**：①z-order 重叠控件真机截图**在途**（纵向不重叠布局已断言/编译实测）；②hello-maui-app 的 Blazor `#app` 因样例缺 `modules.json` 未挂载（razor 样例正常）；③stock JIT 路径未单独复测（8 MB 栈预期修复 `+440`；JIT 仍受 RWX 拒绝限制）；④rc.2 csc 并行活锁仅以 `DOTNET_PROCESSOR_COUNT=1` 绕过、未定位。相关项登记「未测（在途）」不判失败。
- **rc.2 相关**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；rc.1 回滚线保留；应用侧构建请同步 rc.2 线（`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5）。
- **AOT 包（承 #36）**：rc.2 NativeAOT OpenHarmony pack 的 OpenSSL shim 缺陷已由修正版 **`-r2`**（asset **601289590**，`nm … | grep -cE 'local_(EVP|SSL|X509)'` ≥ 5）修复——**撤销 #35 的 rc.1 钉**；若环境缓存过坏包，删 `~/.nuget/packages/microsoft.netcore.app.runtime.nativeaot.openharmony-arm64/11.0.0-rc.2.26451.112` 后再 publish。AOT hap 只有 3 个 `.so`，勿用 JIT 期望值核对。
- **hilog 缓冲（探针误报防护）**：本机实测 512K 环在噪声大时只保留 ≈4–5 s，`--blazor-probe` 4 s 窗口曾丢 `BLZ_BOOT` 报 `boot=no`（同轮流式复核两标记齐全，非渲染缺陷）；临时 `hilog -G 16M -t app,core` 重跑即全绿（**跑完还原 512K**）。tester 机缓冲待核对。
- **本机直测（交付方）**：设备已可测（hdc 无线 `127.0.0.1:35111` + SDK 自签 + AOT 路径）；**JIT payload-in-libs 主包在本机新镜像装不上**曾属已知（`9568393`）——**DEVCOMPAT-DEFAULT 已默认修复**（本机 enforcing 镜像开箱可装）；AOT/解释器路径均可用。
- 所有数字 = **kit #41 发布实测（以 release「## Integrity（kit #41）」与随包校验为准）**：tar **376,036,502 / `bed460ae…`**、树 `7ce1946e…`、sidecar `2a95e764…`、`SHA256SUMS` 17 项 / 1,517 B / `421a819c…`；#40 = tar 375,836,470 / `31ab8732…`、#34 = tar 375,181,367 / `55834aeb…`；tester-run v14 = 140,197 / `a174fcd0…` 仅作对照；bundle = `workload-1.0.0-preview.28` **73,040,293 / `c98375a5…`**（三处同步；dist sums `80ebfdf6…`；sdkrc2 合并 sums 1,960 B / `4be65073…`；sdk 锚 **`2222ba959f`**）；dtk **392356147** / latest **392077166**（asset **606151881**/**606161455**；预签 **606183753**/**606192909**；interp pack rc2 asset **605924427**）；CI **5/5** @ `4bfcd68`（interaction `37040903892` / pixel `37040904000` / host-export `37040904035` / ridgraph `37040903746` / markdownlint `37040904026`）；sdk `ohos-install-tests` @ `2222ba959f` run `37042236958`）。
- 细判（TTS/HUKS/自绘深度/权限/Share-Scan）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2 与 `…kit29/kit28/kit27/kit26/kit25`；无障碍逐项：`docs/plans/2026-09-27-ohos-accessibility-device-verification.md`（含 N4）；B2 细节：`docs/plans/2026-09-30-ohos-blazor-wasm-webview-b2.md`、`…wave10-consolidation.md`；#41 三大修复细节：`2026-10-02-ohos-multi-overlay.md`（§FULL）、`…payload-sign-default.md`、`…interp-fix.md`、`…final-consolidation.md` 与 `2026-10-03-ohos-tester-handoff-kit41.md`。
