# 复测任务单（一页）：kit #32 一轮设备判定（含 WebView / B1 razor / Blazor 段）（2026-09-28）

> 目标：一轮拿全 JIT / XWE / AOT / 解释器 / harmony 五态证据 + WebView 六项（9 项卡）+ B1 razor 首帧/JS 往返 + Blazor 组件两条标记，一并采无障碍。
> 执行入口 = `tester-run.sh` **v14（140,197 B / `a174fcd0…`，asset 595131362；#31 = v13）**（v12 = 126,658 B / `87763a3e…` 为 #30 值；
> v13 增 `--blazor-probe`。`summary runtime_mode` 读 hap 的 `libs/<abi>/runtime-mode.txt`，优先级
> file（interp.txt）> manifest（清单标记）> default；`--mode-matrix` 的 Run C 在清单 interp 包上直接跑
> stock hap，`run_c_via=manifest`）；判定树与细节见
> `2026-09-27-ohos-runtime-mode-determination.md`，逐项勾选见 `2026-09-28-ohos-tester-handoff-kit32.md` §2（WebView/B1/SEC）与 `2026-09-29-ohos-tester-handoff-kit31.md` §2（Blazor）
> 与 `2026-09-28-ohos-tester-handoff-kit30.md` §2（MS-MODE）。
> 本页只给「取件 → 执行 → 回传 → 判定」。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #32，2026-09-28 发布） | **207,114,608** | **`8f690949…`**（sidecar `344760e7…`；树 `645879bc…`；`SHA256SUMS` 16 项 / 1,410 B / `2d3f2fad…`） | 6 个 hap（5 MAUI JIT 重建 = 新壳 abc `289992` + 1 未签名 Blazor `hello-blazorwasm-host-unsigned.hap`，bundle `com.example.opendotnet`；#32 起无 INTERNET）＋`verify-kit.sh`（66,661 / `f72a4a3c…`）＋文档 |
| **B1 razor 独立资产** `maui-razor-haps.tar.gz`（kit #32 起） | **38,968,818** | **`5e549506…`**（sidecar `3f4cc4d6…`；README 2,617 B / `ff56faff…`；内未签 hap **73,656,242 / `b4d305f0…`**，0 权限） | MAUI Blazor Hybrid（bundle `com.example.hellomauirazor`）；重签后按《WebView / Blazor Hybrid 真机验证卡》#8–#9 判读 |
| `aot-haps.tar.gz` | 17,093,146 | `91e1b9d3…` | AOT hap（已内置桥宿主，开箱 `aot=1`；对应 `-p:OpenHarmonyRuntimeMode=aot` 的产物形态） |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`；旧 196,118,871/`f7a4faa2…` 无 overlay 记录已替换） |
| `ohos-interpreter-pack.tar.gz` | 2,419,988 | `a10699b3…` | 解释器载荷（`-p:OpenHarmonyInterpreterPack=<解包目录>` 或设备侧 `interp.txt=3`） |
| `tester-run.sh` **v14**（随包） | **140,197** | **`a174fcd0…`**（asset 595131362；v13 = 137,113 / `2caa06bd…`） | 执行器（`--blazor-probe` 在 #32 起做 pid+nonce 绑定校验、`summary` 增 `blazor_marker_pid`/`blazor_session_nonce`；另有 `--mode-matrix` / `--a11y-probe`） |

包内 6 hap（5 MAUI + 1 Blazor；kit #32 实测，`SHA256SUMS` 16 项 / 1,410 B / `2d3f2fad…`；abc 期望 `289992`/`20916`、Blazor hap 0 权限）：

| hap | 大小 (B) | sha256（前缀） |
|---|---|---|
| `hello-maui-app.hap` | 75,866,199 | `ffa545fd…`（0 权限） |
| `hello-maui-app-permissions.hap` | 75,870,309 | `973f692f…`（5 权限） |
| `hello-maui-app-api20.hap` | 75,866,219 | `b614f9a2…` |
| `hello-maui-app-api20-permissions.hap` | 75,870,334 | `71bb121d…`（5 权限） |
| `hello-maui-app-unsigned.hap` | 73,684,666 | `8658f45a…` |
| `hello-blazorwasm-host-unsigned.hap`（第 6 个，kit #31 起；#32 无 INTERNET） | 26,803,570 | `5011cf73…`（219 条目；自身 abc 21,084/`4069e453…`；0 权限） |

> #30 包内指纹（历史对照）：zip 279 = 24 + 254 payload + `runtime-mode.txt`；`libs` 270 = 14 `.so` + 254 payload +
> `.dotnet-payload.json` + `runtime-mode.txt=jit`；hap 内宿主 285,600 B/`de9b30dd…`、pack 281,504/`f6b3581a…`。
> Blazor hap 为 ArkTS 宿主 + `resources/rawfile/blazor` 站点，无 `.so` payload（不适用 MAUI 的 libs 断言）。

## 2. 执行顺序（每步「期望 → 回传」）

1. **校验 kit**：解压后在包内 `sh verify-kit.sh` → 期望 0 FAIL / 0 WARN（abc 锚 **289,992/20,916**（#32 新壳）；Blazor 权限集为空；**新增 Blazor 分节**：`resources/rawfile/blazor/index.html`、`_framework/` ≥1 个 `*.wasm` 与 `blazor.webassembly*.js`、bundle `com.example.opendotnet`、无 `.br/.gz/.map` 与 `icudt*.dat`）→ 回传终端输出。
2. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./aot-haps.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60`
   → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全（`run_*_install/start/probe_1/xwe/aot_route/interp_mode/runtime_mode/frame/crash`＋`conclusion`）
   → 回传 `mode-matrix/` 全目录＋四个 `tester-report-*.tar.gz`。
3. **harmony 变体（AGC 就绪时）**：解压 `harmony-haps.tar.gz`，按《自签说明》**同指纹重签**（与 AGC 登记的证书指纹一致）→
   AGC 配置地图 AppKey → `sh tester-run.sh --kit-dir ./device-test-kit --hap ./hello-maui-app.hap --install --start --capture 60`
   → 期望 `IsOverlayAvailable=true`（flags bit1；MAPFIX 后 abc 已含 `entry/ets/map/MapOverlay` 模块记录，
   无 AppKey/指纹不一致时才按降级路径登记）、Map `Ready/MarkerClick/CameraIdle`、LiveView create/update/stop
   → 回传截图/录屏＋状态原文＋AGC 开通截图。
4. **无障碍采集（可并入任一轮）**：加 `--a11y-probe` → 期望 `a11y/selfcheck.txt`（`accessibilityStatus: 1`＋正整数节点数）与 `a11y/hilog-a11y.txt`（缺失容忍、不算失败）→ 回传 `a11y/` 两文件＋`summary a11y_*`。
5. **Blazor 段（kit #31 起；必须先重签；kit #32 起标记 pid+nonce 绑定）**：按《自签说明》Blazor 条目重签 `hello-blazorwasm-host-unsigned.hap`（工程 `AppScope/app.json5` 的 bundleName 必须为 **`com.example.opendotnet`**）→
   `sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe`
   → 期望 hilog 出现 `BlazorWebHost ... marker: BLZ_BOOT`（window load）与 `marker: BLZ_RENDERED`（Blazor 首帧）两条，无 `marker: BLZ_ERROR`；
   人工：首屏显示 **“Hello from Blazor WebAssembly”**、进 `/counter` 点击一次 **+1**、**截图 1 张**
   → 回传 `blazor/` 证据（失败为 `blazor-hilog.txt`）＋截图。无 hdc/不能重签时：自动两项登记「未测（无 hdc）」，人工两项照做。
6. **WebView 六项 + B1 razor（kit #32 新增）**：按《WebView / Blazor Hybrid 真机验证卡》（`docs/plans/2026-09-28-ohos-webview-blazor-device-card.md`）9 项逐条操作；B1 razor 重签安装后看 MAUI 窗口首屏 + `BLZ_*` + `/counter` → 回传截图 + hilog。

## 3. 判定表（逐 Run 填）

| 态 | 判据 | 结论 |
|---|---|---|
| JIT | `run_a_probe_1=OK`＋managed 输出/首帧＋`xwe=0 source=default` | JIT 直起可用 |
| XWE | A 不通（probe≠OK/SEGV）时看 B：`xwe=1 source=file` 且能起 | 需 `xwe.txt=1` |
| AOT | `run_d_aot_route=1`＋`NativeAOT payload … aot=1`＋无 `The application to execute does not exist`；aot 标记缺库时应见显式 `falling back to the JIT route` 行 | AOT 直启成立 |
| 解释器 | `run_c_interp_mode=3(file)`（清单包 `3(manifest)`、`run_c_via=manifest`）＋maps 含 `libclrinterpreter.so`＋managed 输出 | 解释器激活 |
| harmony | `IsOverlayAvailable=true`＋Map/LiveView 实际点亮（AppKey 与重签指纹一致） | Map/LiveView 可用 |
| runtime_mode | 默认包 `summary runtime_mode=jit(hap)`＋execmem 含 `runtime-mode=jit source=manifest`；写/删 `<files>/interp.txt` 应分别切到 `source=file` / 回落 `source=manifest` | 标记/优先级正确 |
| **Blazor（kit #31 起；#32 起标记带 nonce）** | `--blazor-probe` 输出含 `marker: BLZ_BOOT` 与 `marker: BLZ_RENDERED`（宿主 pid + 同一 `[blz:<nonce>]`；无 `BLZ_ERROR`）；人工首屏 “Hello from Blazor WebAssembly” + `/counter` 0→1 | Blazor/ArkWeb 承载可用 |
| **WebView（kit #32）** | 设备卡 9 项（frame 几何 / history / CanGoBack / Cookie / HttpOnly / DOM 持久化 / 失败清屏） | 每项满足卡内判据 | 截图 + `tester-run` 证据包 |
| **B1 razor（kit #32）** | 重签装 B1 hap → MAUI 窗口首屏 + `/counter` +1 | 首屏出；`BLZ_BOOT`/`BLZ_RENDERED` 齐（带标记时）、无 `BLZ_ERROR`；计数 0 → 1 | hilog + 截图 |

> 失败 Run 保留对应报告 tar，`summary conclusion` 给建议行；无入口项登记「未测（本包无入口）」，不判失败。

## 4. 注意

- 包内 hap 为自签：安装失败码 **9568257**（及 **9568344**）**属预期**，先重签；重签需**华为调试证书**（Profile 绑定 UDID）。
  Blazor hap **kit #32 起无 `ohos.permission.INTERNET`**（rawfile 直供；重签不修改 module.json，重签后保持；#31 旧包声明 INTERNET，verify-kit 以 WARN 记录）。
  **Blazor hap 的 bundle 与其他不同**（`com.example.opendotnet`）：重签工程的 bundleName 必须同名，`-signCode 1` 不变。
- AOT hap 只有 3 个 `.so`，勿用 kit 的 JIT 期望值核对；AOT/harmony 安装会顶替 kit 主包，回 JIT 需重装 kit hap。
- 自建变体用 **`-p:OpenHarmonyRuntimeMode=jit|aot|interp`**（默认 jit；aot 需 `lib<stem>.so`，interp 可带
  `-p:OpenHarmonyInterpreterPack=<目录>`）；设备侧仍是 `xwe.txt`/`interp.txt` 优先（file>manifest>default）。
- 所有数字以 release「## Integrity」与 `.tar.gz.sha256` sidecar 为准（重签/重打包后哈希必变）；#32 实测 tar **207,114,608 / `8f690949…`**、树 `645879bc…`、sidecar `344760e7…`、bundle **30,566,929 / `286a923e…`**（锚 **`b4e76a6239`**）、v14 **140,197 / `a174fcd0…`**。（#31 = tar 207,023,588 / `f4325d2f…`、bundle 30,570,394 / `43a78c8f…`、锚 `b2b79e27d9` 仅作对照。）
- 细判（TTS/HUKS/文本编辑/动画/列表/图片/深链）：`2026-09-28-ohos-tester-handoff-kit30.md` §2；**WebView/B1/Blazor #32 细判**：`2026-09-28-ohos-tester-handoff-kit32.md` §2–§3 与 `2026-09-28-ohos-webview-blazor-device-card.md`（#31 Blazor 见 `2026-09-29-ohos-tester-handoff-kit31.md` §2/§4）；无障碍逐项判据：`2026-09-27-ohos-accessibility-device-verification.md`。
