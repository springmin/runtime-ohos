# 复测任务单（一页）：kit #33 一轮设备判定（含 Blazor 回归 A/B / TabbedPage 主体 / W5 / AOT v2）（2026-09-29）

> 目标：一轮拿全 **Blazor 双 hap A/B**（默认 CSP / `-nocsp`，各装一次、记录 `BLZ_*`）+ **MAUI 主体渲染**（TabbedPage 双页签出画；JIT 若仍 `SEGV_ACCERR` 改 `aot-haps-v3`）+ **W5 四件** + 承 #32 的 WebView 六项 / B1 razor，并采 JIT/XWE/AOT/解释器/harmony 与无障碍。
> 执行入口 = `tester-run.sh`（版本/大小/摘要**以包内 `SCRIPT_VERSION` 与 release 资产页为准**；#32 = **v14**，含 `--blazor-probe` / `--mode-matrix` / `--a11y-probe`）。
> 判定树与细节：`docs/plans/2026-09-29-ohos-tester-handoff-kit33.md`（逐项勾选）、`docs/plans/2026-09-29-ohos-blazor-regression-retest-card.md`（A/B + 主体一页卡）、`docs/plans/2026-09-27-ohos-runtime-mode-determination.md`（JIT/XWE/AOT/解释器）、承 `docs/plans/2026-09-28-ohos-tester-handoff-kit32.md`（WebView/B1/SEC）与 `docs/plans/2026-09-28-ohos-webview-blazor-device-card.md`。
> 本页只给「取件 → 执行 → 回传 → 判定」。**kit #33 的一切数字以 release「## Integrity（kit #33）」、`.tar.gz.sha256` sidecar 与随包 `SHA256SUMS` 为准**（#32 实测 tar 207,114,608 / `8f690949…` 仅作对照）。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #33，2026-09-29 发布） | **218,138,546** | **`38e4d57a…`**（sidecar `8297363e…`；树 `064cb001…`；`SHA256SUMS` 17 项 / 1,517 B / `37031b9a…`；dtk id 597711909 / sidecar 597714378） | **7 hap** = 5 MAUI（含 TabbedPage/W5 修复；重建 = 新壳 abc **294,976 B / `6cf7dda2…`**）+ **2 个 Blazor 对照 hap**（默认 27,216,958 / `69de2eea…` 与包内名 `hello-blazorwasm-host-nocsp-unsigned.hap` 27,216,659 / `c1ef7e06…`；bundle `com.example.opendotnet`，无 INTERNET）+ `verify-kit.sh`（2c 断言 `_framework/dotnet.js`）+ 文档 |
| `aot-haps-v3.tar.gz`（复测取 v3；v2/旧包仅对照） | **17,537,186** | **`004ba03c…`**（asset 597904340；sidecar `0e28a268…`；README `abe541dd…`） | AOT hap（含 TabbedPage 修复 + **UIPage 修复/UI 壳出画**；已签 20,624,089 / `46d7a9ee…`（UDID `60CF…`）、未签 20,369,300 / `5422b683…`；本侧本机已出画：`ohos_dotnet_surface` buffer=1）；**JIT 主体崩溃或仍黑屏时用它** |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`） |
| `ohos-interpreter-pack.tar.gz` | 2,419,988 | `a10699b3…` | 解释器载荷（`-p:OpenHarmonyInterpreterPack=<解包目录>` 或设备侧 `interp.txt=3`） |
| `tester-run.sh`（随包） | 以包内为准（#32 = 140,197 / `a174fcd0…`） | 以包内为准 | 执行器；`--blazor-probe`（pid+nonce 标记）、`--mode-matrix`、`--a11y-probe` |

包内 7 hap（kit #33 实测，`SHA256SUMS` 17 项 / 1,517 B / `37031b9a…`）：

| hap | 大小 (B) | sha256（前缀） |
|---|---|---|
| `hello-maui-app.hap` | 76,072,282 | `04b45359…` |
| `hello-maui-app-unsigned.hap` | 73,880,100 | `218e8ca4…` |
| `hello-maui-app-permissions.hap` | 76,076,322 | `622c970a…` |
| `hello-maui-app-api20.hap` | 76,072,243 | `e4cb95f0…` |
| `hello-maui-app-api20-permissions.hap` | 76,076,383 | `cb50dd04…` |
| `hello-blazorwasm-host-unsigned.hap`（默认 CSP） | 27,216,958 | `69de2eea…` |
| `hello-blazorwasm-host-nocsp-unsigned.hap`（对照） | 27,216,659 | `c1ef7e06…` |

## 2. 执行顺序（每步「期望 → 回传」）

1. **校验 kit**：包内 `sh verify-kit.sh` → 发布实测 **0 FAIL / 0 WARN**（脚本 69,355 B / `08fe852c…`；2c 断言 `_framework/dotnet.js` 存在且与指纹版逐字节一致；abc 期望 `294976`/`20916`；对 #31/#32 旧包 FAIL 属预期）→ 回传终端输出。
2. **Blazor A/B（本轮重点；先分别重签两个变体）**：装默认件 → `sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe` → 记录 `BLZ_BOOT`/`BLZ_RENDERED`（宿主 pid + `[blz:<nonce>]`）与人工首屏/`/counter` +1/截图；**卸载后**装 `-nocsp` 件 → 同一命令 → 同样记录。判读：默认 ✅ → CSP 非瓶颈；默认 ❌ 而 nocsp ✅ → CSP 至少是次因；两者 ❌ → 按失败回传（`blazor-hilog.txt` + 截图 + 两 hap sha256）。
3. **MAUI 主体（FIX-TABBED）**：重签装默认 MAUI hap → FlyoutPage → TabbedPage → 期望**双页签内容出画、切页正常**（修复前只画 tab 栏/主体黑屏）；失败回传截图 + hilog。**JIT 若启动/主体仍崩（`SEGV_ACCERR`）：重签安装 `aot-haps-v3.tar.gz` 内未签 hap（会顶替 kit 主包）→ 启动 → `aot=1` → 判主体渲染（v3 已修 UIPage；本侧本机出画）**。
4. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./aot-haps-v3.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60` → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全（`conclusion` 给建议）→ 回传 `mode-matrix/` 全目录 + 四个 `tester-report-*.tar.gz`。
5. **无障碍（含 A11Y-TABBED 新判点）**：加 `--a11y-probe` → 期望 `a11y/selfcheck.txt`（status=1 + 正整数节点数）+ `a11y/hilog-a11y.txt`；TabbedPage 页面：影子树只发布**当前页**、切页跟随 → 回传 `a11y/` 两文件 + `summary a11y_*` + 录屏。
6. **W5 四件**：T13 GroupFooter 视图模板（非 Label）/ N3 Picker·Date·TimePicker `IsOpen` 双向映射（Opened/Closed）/ T21 系统字号跟随 / T22 套件自报 **470/floor 450** → 逐条截图/终端输出。
7. **WebView 六项 + B1 razor（承 #32）**：按《WebView / Blazor Hybrid 真机验证卡》9 项逐条操作（frame 几何/history/CanGoBack/Cookie/HttpOnly/DOM 持久化/失败清屏 + B1 `BLZ_*` + JS 往返）→ 回传截图 + hilog。
8. **harmony 变体（AGC 就绪时）**：同指纹重签 `harmony-haps.tar.gz` → Map/LiveView 点亮 + TTS/HUKS 证据（同 #29）→ 回传截图/状态原文。

## 3. 判定表（逐 Run 填）

| 态/项 | 判据 | 结论 |
|---|---|---|
| Blazor A/B（默认 CSP） | `BLZ_BOOT` + `BLZ_RENDERED`（pid+nonce，无 `BLZ_ERROR`）+ 首屏 + `/counter` 0→1 | 路径+dotnet.js 修复成立、CSP 非瓶颈 |
| Blazor A/B（`-nocsp`） | 同上；默认不通而它通 → CSP 至少是次因 | 按 §2.2 判读表落结论 |
| MAUI 主体（FIX-TABBED） | TabbedPage 双页签内容出画 + 切页 | 主体渲染修复成立 |
| JIT | `run_a_probe_1=OK` + `xwe=0 source=default` | JIT 直起可用；`SEGV_ACCERR` → 用 aot-haps-v3 |
| XWE | A 不通时 B：`xwe=1 source=file` 且能起 | 需 `xwe.txt=1` |
| AOT（v2） | `run_d_aot_route=1` + `NativeAOT payload … aot=1` + 主体渲染 | AOT 直启 + 主体修复成立 |
| 解释器 | `run_c_interp_mode=3(file)`（清单包 `3(manifest)`/`run_c_via=manifest`）+ maps 含 `libclrinterpreter.so` | 解释器激活 |
| harmony | `IsOverlayAvailable=true` + Map/LiveView 点亮（AppKey + 同指纹重签） | Map/LiveView 可用 |
| runtime_mode | `summary runtime_mode=jit(hap)` + execmem `runtime-mode=jit source=manifest`；`interp.txt` 切换 file/default | 标记/优先级正确 |
| 无障碍（T3） | 影子树含当前页、未选中页不在，切页跟随 | A11Y-TABBED 成立 |
| W5 | 四项按 §2.6；套件自报 `470 total=470 floor=450 assert=True` | 四项落地 |
| WebView / B1 razor | 同 #32（9 项卡 + B1 两标记 + JS 往返） | 按 #32 判据 |

> 失败 Run 保留报告 tar；无入口项登记「未测（本包无入口/无 hdc）」，不判失败。

## 4. 注意

- 包内 hap 为自签：**9568257 / 9568344 属预期**，先重签（需华为调试证书 + Profile 绑 UDID）；**Blazor 双变体同名（`com.example.opendotnet`），装前卸载**；两变体均无 INTERNET（重签保持）。
- AOT v2 安装会顶替 kit 主包，回 JIT 需重装 kit hap；AOT hap 只有 3 个 `.so`，勿用 JIT 期望值核对。
- 所有数字 = kit #33 发布实测（重签/重打包后必变）：**7 hap**（表见 §1）、tar **218,138,546 / `38e4d57a…`**、树 `064cb001…`、sidecar `8297363e…`、bundle/`workload-1.0.0-preview.28` **77,689,347 / `155960f4…`**（三处同哈希，锚 `e7727959cc`）；#32 实测 tar 207,114,608 / `8f690949…`、v14 140,197 / `a174fcd0…` 仅作对照；以 release「## Integrity（kit #33）」与随包校验为准。
- 细判（TTS/HUKS/自绘深度/权限/Share-Scan）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2 与 `…kit29/kit28/kit27/kit26/kit25`；无障碍逐项：`docs/plans/2026-09-27-ohos-accessibility-device-verification.md`。
