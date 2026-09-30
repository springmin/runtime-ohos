# 复测任务单（一页）：kit #36 一轮设备判定（payload 原地直载 / host 预注册缓冲 / 像素 Known 清零 / a11y 修复 / AOT `-r2` + 承 #35 回归）（2026-10-01）

> 目标：一轮拿全 **#36 增量**（payload 原地直载（AOT 路径实测 BLZ）+ host 预注册缓冲 +
> 像素 Known 清零 + a11y 渲染帧修复 + rc.2 AOT pack `-r2`）
> + **承 #35** 的 W9/W10（B2（`BLZ_BOOT`/`BLZ_RENDERED`）/ T14 flyout / T21 字体缩放 / T8 不等高 TableView /
> T20 媒体传输层 / T19 深链 / AOT 入口）+ **承 #34** 的 rc.2 版本自述、W6/W7/W8（T14/T12/N1/FIX-SHELL；
> T15/T16/N4/T18/N5/N6）与 **承 #33** 的 Blazor 双 hap A/B / TabbedPage / W5，并采 JIT/XWE/AOT/解释器/harmony 与无障碍。
> 执行入口 = `tester-run.sh`（版本/大小/摘要**以包内 `SCRIPT_VERSION` 与 release 资产页为准**；承 **v14**，
> 含 `--blazor-probe` / `--mode-matrix` / `--a11y-probe`）。
> 判定树与细节：`docs/plans/2026-10-01-ohos-tester-handoff-kit36.md`（逐项勾选 + §3 rc.2/AOT `-r2` + §4 本机直测）、
> `docs/plans/2026-09-29-ohos-blazor-regression-retest-card.md`（#33 A/B + 主体一页卡）、
> `docs/plans/2026-09-27-ohos-runtime-mode-determination.md`（JIT/XWE/AOT/解释器）、
> 承 `docs/plans/2026-09-30-ohos-tester-handoff-kit35.md`（W9/W10 + rc.2）、
> `docs/plans/2026-09-28-ohos-webview-blazor-device-card.md`（WebView/B1）。
> 本页只给「取件 → 执行 → 回传 → 判定」。**kit #36 的一切数字以 release「## Integrity（kit #36）」、
> `.tar.gz.sha256` sidecar 与随包 `SHA256SUMS` 为准**（发布在途；#35 实测 tar **375,629,423 B / `419d42e2…`**、
> 树 **`d3b1b317…`**、sidecar **`d7e79d39…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `2dd447a7…`** 仅作上一版对照；
> #34 = tar 375,181,367 / `55834aeb…`）。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #36，2026-10-01） | **以 release 为准**（#35 = 375,629,423） | **以 release 为准**（#35 = `419d42e2…`；sidecar `d7e79d39…`；树 `d3b1b317…`；`SHA256SUMS` 17 项 / 1,517 B / `2dd447a7…`） | **7 hap** = 5 MAUI（新壳 abc **339,964**/24,324、hap 内宿主 **293,792（`cfbbe461…`）**）+ **2 个 Blazor 对照 hap**（bundle `com.example.opendotnet`，无 INTERNET）+ `verify-kit.sh` + 文档 |
| `preSigned-haps.tar.gz`（**预签直装**；#34 起加发） | **375,834,798**（#35/#36 本批未刷新，沿 #34 件；#36 如需预签请回传 UDID 代签） | **`b492b284…`**（sidecar 88 B / `83cbff13…`；树 `e693ae3a…`） | 7 hap 按 tester UDID `60CF7B27…F8A19` 预签：`sha256sum -c SHA256SUMS` → `hdc install -r` **直装**；非本 UDID 设备仍 `9568344` |
| AOT 复测取件（`aot-haps*`；**rc.2 pack `-r2` 已修 OpenSSL shim，撤 rc.1 钉**） | **18,185,012**（`aot-haps-v3-rc2.tar.gz`；本批未动） | **`3d24f716…`** | AOT hap（含 UIPage 出画修复）；rc.2 设备/本机构建用修正版 pack **`…11.0.0-rc.2.26451.112-r2.nupkg`**（28,904,657 B / `542058cf…`，asset 601289590）；JIT 主体崩溃或黑屏时用它；装前重签 |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`） |
| `ohos-interpreter-pack.tar.gz` | 2,419,988 | `a10699b3…` | 解释器载荷（`-p:OpenHarmonyInterpreterPack=<解包目录>` 或设备侧 `interp.txt=3`） |
| `tester-run.sh`（随包） | 以包内为准（承 v14 = 140,197 / `a174fcd0…`） | 以包内为准 | 执行器；`--blazor-probe`、`--mode-matrix`、`--a11y-probe` 承 #33 |

包内 7 hap（kit #36 以 release「## Integrity（kit #36）」与包内 `SHA256SUMS` 为准；#35 对照 = `SHA256SUMS` 17 项 / 1,517 B / `2dd447a7…`：`hello-maui-app.hap` **133,965,654 / `e0f49a57…`**、`…-unsigned` **131,444,590 / `55d84827…`**、`…-permissions` **133,969,645 / `7cf2183c…`**、`…-api20` **133,965,601 / `711374cb…`**、`…-api20-permissions` **133,969,757 / `39292e9b…`**；Blazor 默认 **27,216,958 / `6227d0e6…`**、`-nocsp` **27,216,659 / `a83ea068…`**。

**预签直装捷径（可选）**：`sha256sum -c SHA256SUMS` 后 `hdc install -r` 直装，**§2 的「先重签」可跳过**（同 bundle
换件仍先卸载）；每件 bundle/原 sha/新 sha/安装命令见包内 `preSigned-README.md`。它是并列附加件：`verify-kit.sh`
全包校验与 `tester-run.sh` 完整轮仍用 `device-test-kit.tar.gz`。

## 2. 执行顺序（每步「期望 → 回传」）

0. **#36 增量（新）**：`sh verify-kit.sh` 深度断言 abc 期望 **339,964/24,324**；安装/启动 hello-maui-wasm（或包内演示 hap）→ hilog 期望 `payload-in-libs: running from /data/storage/el1/bundle/entry/libs/arm64 (dotnet.zip not unpacked)`（解析不到时一行 miss 后回退 `dotnet.zip`，属降级不判失败）；打开嵌入式 Blazor 页 → `BLZ_BOOT`/`BLZ_RENDERED` 双标记齐（host **预注册缓冲**：壳 `registerWebSink` 注册前到达的 web 命令不丢，16 条 / 64 KiB 注册即 flush）；`--a11y-probe` 期望 `status=1` + 正整数 nodeCount（wasm 页 **5** / 主包 **24**，重复读稳定）；**AOT 构建用 rc.2 pack `-r2`（撤 rc.1 钉）** → 回传 hilog/status 文本/`a11y/` 两文件。
1. **校验 kit**：包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap；abc 期望 **339,964/24,324**，脚本哈希以包内为准）→ 回传终端输出。
2. **rc.2 版本自述**：读包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary → 期望 SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；无 rc.1 混装告警 → 回传自述原文 + summary。
3. **B2：MAUI WebView 内嵌 Blazor WASM（承 #35 主判点）**：装含 WebView/WASM 入口的包内演示 hap（或按 release/包内说明构建），AOT 路径启动 → 打开嵌入式 Blazor 页 → 期望 **`BLZ_BOOT` + `BLZ_RENDERED` 同 pid 双标记齐**（无 `BLZ_ERROR`）、首屏渲染、`/counter` 类交互 +1；壳 hilog 可见 `BlazorWebHost` / `web cmd blazor … mode=wasm` → 回传 hilog + 首屏/交互截图。
4. **W9B：T14 收尾 + T21 字体缩放**：T14 = flyout 富头/项/尾行、项模板（`Shell.ItemTemplate`）/多段项、点行选中 + 关抽屉、模板内按钮可点不误关；T21 = 系统字号/`FontScale` 变化（含 0.5/3 边界与非法值）后 Label/Formatted 尺寸与 Entry 光标跟随、越界被钳制 → 逐条截图 + 结果。
5. **W9C：T8 不等高 TableView**：不等高行（含等高切换、滚动、更新/增删）→ 行不重叠、总高一致、滚动/更新正确；切回等高恢复 → 截图 + 滚动/更新结果。
6. **W9D：T20 媒体传输层 + T19 深链**：媒体演示入口/热触发（`app://media/probe` 类）→ **无 MediaKit 镜像属预期**：`IsSupported=false`、各调用 `Unavailable/Failed` **不抛**（真播放需 Kit 完整镜像/HMS 设备，回传壳自检 `media self-test …` 行）；深链用 `hdc shell aa start -U app://…` 冷/热各一次 → 热期望 `delivered=1`（冷 `delivered=0` 为设计内）→ 回传 hilog 行。
7. **W10：AOT 入口可观测（承 #35）**：AOT hap 启动后读 `<files>/dotnet-status.txt`（壳轮询 tail 打 hilog）→ 期望出现托管入口/AOT 决策行（不再只有宿主 probe 行）；附 `aot=` 行 → 回传 status 文本/hilog。
8. **承 #34：W6/W7/W8**：W6 = T14（步骤 4 已含）/T12 CarouselView 分组/N1 多指/FIX-SHELL 主体；W7/W8 = T15 富 TitleView / T16 结构化菜单 / N4 TitleBar a11y（`--a11y-probe`）/ T18 IMap / N5 覆盖层触摸抑制 / N6 系统装饰 → 逐条截图/终端输出（期望同 #34；套件自报行改为 **`[suite] checks=540 total=540 floor=520 assert=True`**）。
9. **承 #33：Blazor A/B（先分别重签两个变体；用预签直装包可直接装）**：装默认件 → `sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe` → 记录 `BLZ_BOOT`/`BLZ_RENDERED`（宿主 pid + nonce）与人工首屏/`/counter` +1/截图；**卸载后**装 `-nocsp` 件 → 同命令 → 按 #33 判读表落结论。
10. **承 #33：MAUI 主体（TabbedPage/W5）**：双页签内容出画、切页正常；T13/N3/T21/T22；失败回传截图 + hilog。**JIT 若启动/主体仍崩（`SEGV_ACCERR`）或黑屏：重签安装 AOT 资产内未签 hap（会顶替 kit 主包；本轮设备构建用 rc.2 pack `-r2`）→ 启动 → `aot=1` → 判主体渲染**。
11. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./<aot-asset>.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60` → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全 → 回传 `mode-matrix/` 全目录 + 四个 `tester-report-*.tar.gz`。
12. **无障碍（含 N4）**：加 `--a11y-probe` → `a11y/selfcheck.txt`（status=1 + 正整数节点数，wasm 页 5 / 主包 24 为最新实测参照）+ `a11y/hilog-a11y.txt`；TabbedPage 当前页跟随（承 #33）+ `Window.TitleBar` 行进树（#34）→ 回传 `a11y/` 两文件 + `summary a11y_*` + 录屏。
13. **WebView 六项 + B1 razor（承 #32）**：按《WebView / Blazor Hybrid 真机验证卡》9 项逐条操作 → 回传截图 + hilog。
14. **harmony 变体（AGC 就绪时）**：同指纹重签 `harmony-haps.tar.gz` → Map/LiveView 点亮 + TTS/HUKS 证据 → 回传截图/状态原文。

## 3. 判定表（逐 Run 填）

| 态/项 | 判据 | 结论 |
|---|---|---|
| **payload 原地直载（#36）** | hilog `payload-in-libs: running from …/entry/libs/arm64 (dotnet.zip not unpacked)`；miss 时一行提示后回退 `dotnet.zip`；B2 页正常出画 | #36 落地 |
| **host 预注册缓冲（#36）** | 壳 `registerWebSink` 注册前到达的 web 命令不丢（`webPending` 路径）；B2 双标记齐 | #36 落地 |
| **像素 Known 清零（#36，套件侧）** | `test/headless-render` 无 `Known(...)`（selection tint 字节量化精确断言）；`PIXEL ASSERTIONS PASSED` | #36 落地 |
| **a11y 渲染帧挂接（#36）** | `--a11y-probe`：`status=1`（attached）+ 正整数 nodeCount（wasm 5 / 主包 24）稳定 | #36 落地 |
| **AOT pack `-r2`（#36）** | rc.2 AOT pack `-r2`（asset 601289590）替换坏包后设备 AOT 构建 publish/启动成立；rc.1 钉撤销 | #36 回归成立 |
| **B2 真机 BLZ** | `BLZ_BOOT` + `BLZ_RENDERED` 同 pid 双标记、无 `BLZ_ERROR`；首屏 + `/counter` 类交互 | 承 #35 落地 |
| **T14 收尾** | flyout 富头/项/尾行 + 项模板/多段项；点行选中+关闭；模板内按钮不误关 | 承 #35 落地 |
| **T21 字体缩放** | Label/Formatted 随缩放（`w` 近似翻倍/还原）；Entry 光标跟随；0.5/3 边界与非法值不崩 | 承 #35 落地 |
| **T8 不等高 TableView** | 行高混排不重叠、总高一致；滚动/更新正确；等高切换恢复 | 承 #35 落地 |
| **T20 媒体（无 Kit 降级）** | 无 MediaKit：`IsSupported=false`、各调用 `Unavailable/Failed` 不抛；有 Kit：播放/事件/状态 | 承 #35；无 Kit 不判失败 |
| **T19 深链** | 冷/热均投递 ability，**热 `delivered=1`**；未知路由无异常（冷 `delivered=0` 设计内） | 承 #35 判定成立 |
| **AOT 入口可观测** | `<files>/dotnet-status.txt` 出现托管入口/AOT 决策行 + `aot=1` | 承 #35 落地 |
| rc.2 基线 | 版本自述 = SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；无混装 | rc.2 线成立 |
| T12 分组 Carousel | `GroupHeader`/`GroupFooter` 滑片出现、滑动跨组、`CurrentItem` 跟随、清除回落 | W6（承 #34） |
| FIX-SHELL / N1 | Shell 主体出画 + 切页重绘；多指轨迹正确（不再坍缩到单指） | W6（承 #34） |
| T15 富 TitleView | 标题带出模板视图（非文本）+ 按钮可点；隐藏回退/清除消失 | W7（承 #34） |
| T16 结构化菜单 | 组头=栏标题；子菜单按层级；禁用门控；叶激活、头不激活 | W7（承 #34） |
| N4 TitleBar a11y | 影子树含 TitleBar 行（根首子节点 + bounds）/文本/按钮节点；隐藏/恢复/清除跟随 | W7（承 #34） |
| T18 IMap / N5 / N6 | 有 app → 拉起地图，无 → `TryOpenAsync=false` 不抛；选择器开 → 下层不激活、关恢复；桌面窗口 min/max/close + 拖拽 + Content 按钮不被抢 | W8（承 #34） |
| Blazor A/B（默认 CSP） | `BLZ_BOOT` + `BLZ_RENDERED`（pid+nonce，无 `BLZ_ERROR`）+ 首屏 + `/counter` 0→1 | #33 修复保持 |
| Blazor A/B（`-nocsp`） | 同上；默认不通而它通 → CSP 至少是次因 | 按 #33 判读表落结论 |
| MAUI 主体（TabbedPage/W5） | 双页签出画 + 切页；T13/N3/T21/T22 四项；套件 `540 total=540 floor=520 assert=True` | #33 保持 |
| JIT | `run_a_probe_1=OK` + `xwe=0 source=default` | JIT 直起可用；`SEGV_ACCERR` → AOT 资产 |
| XWE | A 不通时 B：`xwe=1 source=file` 且能起 | 需 `xwe.txt=1` |
| AOT | `run_d_aot_route=1` + `aot=1` + 主体渲染；设备构建 rc.2 pack `-r2` | AOT 直启 + 主体成立 |
| 解释器 | `run_c_interp_mode=3(file)`（清单包 `3(manifest)`/`run_c_via=manifest`）+ maps 含 `libclrinterpreter.so` | 解释器激活 |
| harmony | `IsOverlayAvailable=true` + Map/LiveView 点亮（AppKey + 同指纹重签） | Map/LiveView 可用 |
| runtime_mode | `summary runtime_mode=jit(hap)` + execmem `runtime-mode=jit source=manifest`；`interp.txt` 切换 file/default | 标记/优先级正确 |
| WebView / B1 razor | 同 #32（9 项卡 + B1 两标记 + JS 往返） | 按 #32 判据 |

> 失败 Run 保留报告 tar；无入口项登记「未测（本包无入口/无 hdc）」，不判失败。

## 4. 注意

- 包内 hap 为自签：**9568257 / 9568344 属预期**，先重签（需华为调试证书 + Profile 绑 UDID）；**Blazor 双变体同名（`com.example.opendotnet`），装前卸载**；两变体均无 INTERNET（重签保持）。
- **rc.2 相关**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；rc.1 回滚线保留；应用侧构建请同步 rc.2 线（`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5）。
- **AOT 包（#36 更新）**：rc.2 NativeAOT OpenHarmony pack 的 OpenSSL shim 缺陷已由修正版 **`-r2`**（`…11.0.0-rc.2.26451.112-r2.nupkg`，asset **601289590**，`nm … | grep -cE 'local_(EVP|SSL|X509)'` ≥ 5）修复——**撤销 #35 的 rc.1 钉**，设备/本机 AOT 构建直接用 `-r2` feed；若环境缓存过坏包，删 `~/.nuget/packages/microsoft.netcore.app.runtime.nativeaot.openharmony-arm64/11.0.0-rc.2.26451.112` 后再 publish。AOT hap 只有 3 个 `.so`，勿用 JIT 期望值核对。
- **hilog 缓冲（探针误报防护）**：本机实测 512K 环在噪声大时只保留 ≈4–5 s，`--blazor-probe` 4 s 窗口曾丢 `BLZ_BOOT` 报 `boot=no`（同轮流式复核两标记齐全，非渲染缺陷）；临时 `hilog -G 16M -t app,core` 重跑即全绿（**跑完还原 512K**）。tester 机缓冲待核对。
- **本机直测（交付方）**：设备已可测（hdc 无线 `127.0.0.1:35111` + SDK 自签 + AOT 路径）；**JIT payload-in-libs 主包在本机新镜像装不上属已知**（`9568393`，非 kit 缺陷），主包 JIT 判定仍以 tester 机为准。
- 所有数字 = **kit #36 以 release「## Integrity（kit #36）」与随包校验为准**（发布在途；#35 = tar **375,629,423 / `419d42e2…`**、树 `d3b1b317…`、sidecar `d7e79d39…`、`SHA256SUMS` 17 项 / 1,517 B / `2dd447a7…`；#34 = tar 375,181,367 / `55834aeb…`、#33 = tar 218,138,546 / `38e4d57a…`；tester-run v14 = 140,197 / `a174fcd0…` 仅作对照；bundle 以 release 为准（#35 = `workload-1.0.0-preview.28` **77,754,383 / `acd26821…`**，三处同步；sdk 锚 **`02a31ef348`**）；dtk **392356147** / latest **392077166**）。
- 细判（TTS/HUKS/自绘深度/权限/Share-Scan）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2 与 `…kit29/kit28/kit27/kit26/kit25`；无障碍逐项：`docs/plans/2026-09-27-ohos-accessibility-device-verification.md`（含 N4）；B2/#36 细节：`docs/plans/2026-09-30-ohos-blazor-wasm-webview-b2.md`、`…wave10-consolidation.md` 与 `2026-10-01-ohos-tester-handoff-kit36.md`。
