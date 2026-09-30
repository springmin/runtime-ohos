# 复测任务单（一页）：kit #34 一轮设备判定（rc.2 基线 + MAUI W6/W7/W8 + 承 #33 回归）（2026-09-30）

> 目标：一轮拿全 **rc.2 版本自述** + **MAUI W6/W7/W8**（T14 富 flyout / T12 CarouselView 分组 / N1 多指坐标 / FIX-SHELL；
> T15 富 TitleView / T16 结构化菜单 / N4 TitleBar a11y / T18 Essentials IMap / N5 覆盖层触摸抑制 / N6 标题栏系统装饰）
> + **承 #33 的 Blazor 双 hap A/B / TabbedPage / W5**，并采 JIT/XWE/AOT/解释器/harmony 与无障碍。
> 执行入口 = `tester-run.sh`（版本/大小/摘要**以包内 `SCRIPT_VERSION` 与 release 资产页为准**；承 **v14**，含
> `--blazor-probe` / `--mode-matrix` / `--a11y-probe`）。
> 判定树与细节：`docs/plans/2026-09-30-ohos-tester-handoff-kit34.md`（逐项勾选 + §3 rc.2 + §4 本机直测）、
> `docs/plans/2026-09-29-ohos-blazor-regression-retest-card.md`（#33 A/B + 主体一页卡）、
> `docs/plans/2026-09-27-ohos-runtime-mode-determination.md`（JIT/XWE/AOT/解释器）、
> 承 `docs/plans/2026-09-28-ohos-tester-handoff-kit32.md`（WebView/B1/SEC）与 `2026-09-28-ohos-webview-blazor-device-card.md`。
> 本页只给「取件 → 执行 → 回传 → 判定」。**kit #34 的一切数字以 release「## Integrity（kit #34）」、
> `.tar.gz.sha256` sidecar 与随包 `SHA256SUMS` 为准**（#33 实测 tar **218,138,546 / `38e4d57a…`**、树 `064cb001…`、
> sidecar `8297363e…` 仅作上一版对照）。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #34，2026-09-30） | **375,181,367** | **`55834aeb…`**（sidecar `c03ea23d…`；树 `d08de3ec…`；`SHA256SUMS` 17 项 / 1,517 B / `94fedc66…`；dtk id 以 release 为准） | **7 hap** = 5 MAUI（~133.8 MB/件，rc.2 payload 变大；abc **311,424**/20,916）+ **2 个 Blazor 对照 hap**（默认 27,216,958 / `8e407504…` 与 `-nocsp` 27,216,659 / `68606606…`；bundle `com.example.opendotnet`，无 INTERNET）+ `verify-kit.sh`（69,522 / `dcd81f33…`）+ 文档 |
| `preSigned-haps.tar.gz`（**预签直装**，2026-09-30 加发；asset 600101072） | **375,834,798** | **`b492b284…`**（sidecar 88 B / `83cbff13…`；树 `e693ae3a…`） | **7 hap 全部按 tester UDID `60CF7B27…F8A19` 预签**（MAUI 5 + Blazor 默认/`-nocsp`；SDK 默认调试材料）：`sha256sum -c SHA256SUMS` → `hdc install -r` **直装、无需重签**；每件 bundle/原 sha/新 sha/安装命令见包内 `preSigned-README.md`；非本 UDID 设备仍 `9568344`（包内附重签指引）；并列附加件、不替换 kit |
| `aot-haps-v3.tar.gz`（复测取 v3；v2/旧包仅对照） | **17,537,186** | **`004ba03c…`**（asset 597904340；sidecar `0e28a268…`；README `abe541dd…`） | AOT hap（含 TabbedPage 修复 + **UIPage 修复/UI 壳出画**；已签 20,624,089 / `46d7a9ee…`、未签 20,369,300 / `5422b683…`；本侧本机已出画：`ohos_dotnet_surface` buffer=1）；**JIT 主体崩溃或仍黑屏时用它**；如本轮另发 AOT 资产以 release 为准 |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`） |
| `ohos-interpreter-pack.tar.gz` | 2,419,988 | `a10699b3…` | 解释器载荷（`-p:OpenHarmonyInterpreterPack=<解包目录>` 或设备侧 `interp.txt=3`） |
| `tester-run.sh`（随包） | 以包内为准（承 v14 = 140,197 / `a174fcd0…`） | 以包内为准 | 执行器；`--blazor-probe`、`--mode-matrix`、`--a11y-probe` 承 #33 |

包内 7 hap（kit #34 实测，`SHA256SUMS` 17 项 / 1,517 B / `94fedc66…`）：`hello-maui-app.hap` **133,827,313 / `9614f69d…`**、
`…-unsigned` **131,304,609 / `f0def954…`**、`…-permissions` **133,831,417 / `a7a3391c…`**、`…-api20` **133,831,490 / `701104e8…`**、
`…-api20-permissions` **133,831,449 / `d3bf37f6…`**；Blazor 默认 **27,216,958 / `8e407504…`**、`-nocsp` **27,216,659 / `68606606…`**。

**预签直装捷径（可选；2026-09-30 加发）**：`preSigned-haps.tar.gz` 的 7 hap 已全部按 tester UDID `60CF7B27…F8A19`
预签——`sha256sum -c SHA256SUMS` 后 `hdc install -r` 直装，**§2 步骤 5 的「先分别重签两个变体」可跳过**（同 bundle
换件仍先卸载）；每件 bundle/原 sha/新 sha/安装命令见包内 `preSigned-README.md`。它是并列附加件：`verify-kit.sh`
全包校验与 `tester-run.sh` 完整轮仍用 `device-test-kit.tar.gz`。交付方本机对照（HAD-W32/7.0.0.111）：同法本机-UDID
件与本 tester 绑定件在本机均 `hdc install -r` 成功并启动（本机桌面镜像不校验 `device-ids`；tester 机被拒按 `9568344` 流程）。

## 2. 执行顺序（每步「期望 → 回传」）

1. **校验 kit**：包内 `sh verify-kit.sh` → 发布实测 **0 FAIL / 0 WARN**（深度断言逐 hap；abc 期望 311,424/20,916；脚本 69,522 / `dcd81f33…`）→ 回传终端输出。
2. **rc.2 版本自述**：读包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary → 期望 SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；无 rc.1 混装告警 → 回传自述原文 + summary。
3. **W6 三项 + 一修复**：① T14 富 Shell flyout（头/尾/项模板行出画、点行选中+关闭、模板内按钮可点）；② T12 分组 CarouselView（GroupHeader/Footer 滑片、滑动跨组、`CurrentItem` 跟随）；③ FIX-SHELL（Shell 页面主体出画、切页重绘）；④ N1 多指（Pinch 两指轨迹正确）→ 逐条截图 + 结果。
4. **W7/W8 六项**：T15 富 TitleView（标题带出模板视图 + 视图内按钮；隐藏/清除回退）；T16 结构化菜单（组头/嵌套/禁用门控/叶激活）；N4 TitleBar a11y（`--a11y-probe` 含 TitleBar 行/文本/按钮）；T18 Essentials IMap（`Map.Default.OpenAsync` 拉起系统地图；无 app 时 `TryOpenAsync=false` 不抛）；N5 覆盖层触摸抑制（选择器开 → 下层 Entry 不聚焦；关 → 恢复）；N6 系统装饰（桌面窗口最小化/最大化/关闭 + 拖拽 + `TitleBar.Content` 按钮不被抢）→ 逐条截图/终端输出。
5. **承 #33：Blazor A/B（先分别重签两个变体；用预签直装包可直接装，跳过重签、见 §1 捷径注）**：装默认件 → `sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe` → 记录 `BLZ_BOOT`/`BLZ_RENDERED`（宿主 pid + `[blz:<nonce>]`）与人工首屏/`/counter` +1/截图；**卸载后**装 `-nocsp` 件 → 同一命令 → 同样记录；按 #33 判读表落结论。
6. **承 #33：MAUI 主体（TabbedPage/W5）**：FlyoutPage → TabbedPage 双页签内容出画、切页正常；T13 GroupFooter / N3 `IsOpen` / T21 字号跟随 / T22 套件自报 **513/floor 493**；失败回传截图 + hilog。**JIT 若启动/主体仍崩（`SEGV_ACCERR`）或黑屏：重签安装 `aot-haps-v3.tar.gz` 内未签 hap（会顶替 kit 主包）→ 启动 → `aot=1` → 判主体渲染**。
7. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./aot-haps-v3.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60` → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全 → 回传 `mode-matrix/` 全目录 + 四个 `tester-report-*.tar.gz`。
8. **无障碍（含 N4 新判点）**：加 `--a11y-probe` → `a11y/selfcheck.txt`（status=1 + 正整数节点数）+ `a11y/hilog-a11y.txt`；TabbedPage 当前页跟随（承 #33）+ `Window.TitleBar` 行进树（#34）→ 回传 `a11y/` 两文件 + `summary a11y_*` + 录屏。
9. **WebView 六项 + B1 razor（承 #32）**：按《WebView / Blazor Hybrid 真机验证卡》9 项逐条操作 → 回传截图 + hilog。
10. **harmony 变体（AGC 就绪时）**：同指纹重签 `harmony-haps.tar.gz` → Map/LiveView 点亮 + TTS/HUKS 证据 → 回传截图/状态原文。

## 3. 判定表（逐 Run 填）

| 态/项 | 判据 | 结论 |
|---|---|---|
| rc.2 基线 | 版本自述 = SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；无混装 | rc.2 线成立 |
| T14 富 flyout | 富头/尾/项行出画；点行选中+关闭；模板内按钮生效不误关 | W6 落地 |
| T12 分组 Carousel | `GroupHeader`/`GroupFooter` 滑片出现、滑动跨组、`CurrentItem` 跟随、清除回落 | W6 落地 |
| FIX-SHELL | Shell 页面主体出画 + 切页重绘；a11y 含当前页 | W6 修复成立 |
| N1 多指 | 双指/多指轨迹正确（不再坍缩到单指） | 多指坐标成立 |
| T15 富 TitleView | 标题带出模板视图（非文本）+ 按钮可点；隐藏回退/清除消失 | W7 落地 |
| T16 结构化菜单 | 组头=栏标题；子菜单按层级；禁用门控；叶激活、头不激活 | W7 落地 |
| N4 TitleBar a11y | 影子树含 TitleBar 行（根首子节点 + bounds）/文本/按钮节点；隐藏/恢复/清除跟随 | W7 落地 |
| T18 IMap | 有 app → 拉起系统地图；无 → `TryOpenAsync=false`、不抛 | W8 落地 |
| N5 触摸抑制 | 选择器开 → 下层不激活；关 → 恢复穿透 | W8 落地 |
| N6 系统装饰 | 桌面窗口 min/max/close + 拖拽生效；Content 按钮不被抢；全屏手机不出装饰 | W8 落地 |
| Blazor A/B（默认 CSP） | `BLZ_BOOT` + `BLZ_RENDERED`（pid+nonce，无 `BLZ_ERROR`）+ 首屏 + `/counter` 0→1 | #33 修复保持 |
| Blazor A/B（`-nocsp`） | 同上；默认不通而它通 → CSP 至少是次因 | 按 #33 判读表落结论 |
| MAUI 主体（TabbedPage/W5） | 双页签出画 + 切页；T13/N3/T21/T22 四项；套件 `513 total=513 floor=493 assert=True` | #33 保持 |
| JIT | `run_a_probe_1=OK` + `xwe=0 source=default` | JIT 直起可用；`SEGV_ACCERR` → 用 aot-haps-v3 |
| XWE | A 不通时 B：`xwe=1 source=file` 且能起 | 需 `xwe.txt=1` |
| AOT（v3） | `run_d_aot_route=1` + `NativeAOT payload … aot=1` + 主体渲染 | AOT 直启 + 主体成立 |
| 解释器 | `run_c_interp_mode=3(file)`（清单包 `3(manifest)`/`run_c_via=manifest`）+ maps 含 `libclrinterpreter.so` | 解释器激活 |
| harmony | `IsOverlayAvailable=true` + Map/LiveView 点亮（AppKey + 同指纹重签） | Map/LiveView 可用 |
| runtime_mode | `summary runtime_mode=jit(hap)` + execmem `runtime-mode=jit source=manifest`；`interp.txt` 切换 file/default | 标记/优先级正确 |
| WebView / B1 razor | 同 #32（9 项卡 + B1 两标记 + JS 往返） | 按 #32 判据 |

> 失败 Run 保留报告 tar；无入口项登记「未测（本包无入口/无 hdc）」，不判失败。

## 4. 注意

- 包内 hap 为自签：**9568257 / 9568344 属预期**，先重签（需华为调试证书 + Profile 绑 UDID）；**Blazor 双变体同名（`com.example.opendotnet`），装前卸载**；两变体均无 INTERNET（重签保持）。
- **rc.2 相关**：MAUI `11.0.0-rc.2.26478.12` 为 dnceng daily（nuget.org 尚未上架）；交付方 restore 走 dnceng `dotnet11` feed，官方 rc.2 上 nuget.org 后换 pin 并删 feed（kit #34 后立即）。rc.1 回滚线保留；应用侧构建请同步 rc.2 线（`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5）。
- AOT v3 安装会顶替 kit 主包，回 JIT 需重装 kit hap；AOT hap 只有 3 个 `.so`，勿用 JIT 期望值核对。
- **hilog 缓冲（探针误报防护）**：本机实测 512K 环在噪声大时只保留 ≈4–5 s，`--blazor-probe` 4 s 窗口曾丢 `BLZ_BOOT` 报 `boot=no`（同轮流式复核两标记齐全，非渲染缺陷）；临时 `hilog -G 16M -t app,core` 重跑即全绿（**跑完还原 512K**）。**tester 机缓冲待核对**——若同样报 `boot=no` 而 `rendered=yes`，先临时调大缓冲（事后还原）或先 `--capture 60` 流式复核，再判失败。
- **本机直测（交付方）**：设备已可测（hdc 无线 `127.0.0.1:35111` + SDK 自签 + AOT 路径）；**JIT payload-in-libs 主包在本机新镜像装不上属已知**（`9568393`，非 kit 缺陷），主包 JIT 判定仍以 tester 机为准。
- 所有数字 = kit #34 发布实测（重签/重打包后必变）：tar **375,181,367 / `55834aeb…`**、树 `d08de3ec…`、sidecar `c03ea23d…`、`SHA256SUMS` 17 项 / 1,517 B / `94fedc66…`；bundle/preview.28（rc.2 重打包进行中，新 sha 以 release 为准；#33 = 77,689,347 / `155960f4…`，锚 `e7727959cc`）；#33（tar 218,138,546 / `38e4d57a…`）与 tester-run v14（140,197 / `a174fcd0…`）仅作对照；以 release「## Integrity（kit #34）」与随包校验为准。
- 细判（TTS/HUKS/自绘深度/权限/Share-Scan）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2 与 `…kit29/kit28/kit27/kit26/kit25`；无障碍逐项：`docs/plans/2026-09-27-ohos-accessibility-device-verification.md`（含新增 N4）。
