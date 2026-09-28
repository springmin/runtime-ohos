# 复测任务单（一页）：kit #31 一轮设备判定（含 Blazor 段）（2026-09-29）

> 目标：一轮拿全 JIT / XWE / AOT / 解释器 / harmony 五态证据 + Blazor 组件两条标记，一并采无障碍。
> 执行入口 = `tester-run.sh` **v13**（v12 = 126,658 B / `87763a3e…` / `script_version=12 (2026-09-28)` 为 #30 值；
> v13 增 `--blazor-probe`。`summary runtime_mode` 读 hap 的 `libs/<abi>/runtime-mode.txt`，优先级
> file（interp.txt）> manifest（清单标记）> default；`--mode-matrix` 的 Run C 在清单 interp 包上直接跑
> stock hap，`run_c_via=manifest`）；判定树与细节见
> `2026-09-27-ohos-runtime-mode-determination.md`，逐项勾选见 `2026-09-29-ohos-tester-handoff-kit31.md` §2（Blazor）
> 与 `2026-09-28-ohos-tester-handoff-kit30.md` §2（MS-MODE）。
> 本页只给「取件 → 执行 → 回传 → 判定」。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #31，已发布 2026-09-29） | 以 release 为准（#30 = 196,992,264） | 以 release 为准（#30 = `a781c25b…`；sidecar `a63cd34f…`；树 `cc1ca935…`） | 6 个 hap（5 MAUI JIT + 1 未签名 Blazor `hello-blazorwasm-host-unsigned.hap`，26 MB，bundle `com.example.opendotnet`）＋`verify-kit.sh`＋文档；`SHA256SUMS` 项数以发布为准（#30 = 15 项 / 1,309 B） |
| `aot-haps.tar.gz` | 17,093,146 | `91e1b9d3…` | AOT hap（已内置桥宿主，开箱 `aot=1`；对应 `-p:OpenHarmonyRuntimeMode=aot` 的产物形态） |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`；旧 196,118,871/`f7a4faa2…` 无 overlay 记录已替换） |
| `ohos-interpreter-pack.tar.gz` | 2,419,988 | `a10699b3…` | 解释器载荷（`-p:OpenHarmonyInterpreterPack=<解包目录>` 或设备侧 `interp.txt=3`） |
| `tester-run.sh` v13（当前） | 以 release 资产页为准（v12 = 126,658） | 以 release 为准（v12 = `87763a3e…`） | 执行器（v13 增 `--blazor-probe`；另有 `--mode-matrix` / `--a11y-probe`；`summary runtime_mode=jit|aot|interp(hap)|invalid(...)|<absent>`） |

包内 6 hap（5 MAUI + 1 Blazor；#31 数字以 release 与随包 `SHA256SUMS` 为准，#30 快照对照如下）：

| hap | 大小 (B) | sha256（前缀） |
|---|---|---|
| `hello-maui-app.hap` | 75,911,491（#30） | `333b0436…`（#30） |
| `hello-maui-app-permissions.hap` | 75,911,431（#30） | `d86cf095…`（#30） |
| `hello-maui-app-api20.hap` | 75,911,487（#30） | `cda37a2b…`（#30） |
| `hello-maui-app-api20-permissions.hap` | 75,911,523（#30） | `2106703b…`（#30） |
| `hello-maui-app-unsigned.hap` | 73,718,261（#30） | `458ee58d…`（#30） |
| `hello-blazorwasm-host-unsigned.hap`（第 6 个，kit #31） | 26 MB 级（未签名） | 以 release/`SHA256SUMS` 为准 |

> #30 包内指纹（历史对照）：zip 279 = 24 + 254 payload + `runtime-mode.txt`；`libs` 270 = 14 `.so` + 254 payload +
> `.dotnet-payload.json` + `runtime-mode.txt=jit`；hap 内宿主 285,600 B/`de9b30dd…`、pack 281,504/`f6b3581a…`。
> Blazor hap 为 ArkTS 宿主 + `resources/rawfile/blazor` 站点，无 `.so` payload（不适用 MAUI 的 libs 断言）。

## 2. 执行顺序（每步「期望 → 回传」）

1. **校验 kit**：解压后在包内 `sh verify-kit.sh` → 期望 0 FAIL / 0 WARN（abc 锚 **281,052/20,916**；**新增 Blazor 分节**：`resources/rawfile/blazor/index.html`、`_framework/` ≥1 个 `*.wasm` 与 `blazor.webassembly*.js`、bundle `com.example.opendotnet`、无 `.br/.gz/.map` 与 `icudt*.dat`）→ 回传终端输出。
2. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./aot-haps.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60`
   → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全（`run_*_install/start/probe_1/xwe/aot_route/interp_mode/runtime_mode/frame/crash`＋`conclusion`）
   → 回传 `mode-matrix/` 全目录＋四个 `tester-report-*.tar.gz`。
3. **harmony 变体（AGC 就绪时）**：解压 `harmony-haps.tar.gz`，按《自签说明》**同指纹重签**（与 AGC 登记的证书指纹一致）→
   AGC 配置地图 AppKey → `sh tester-run.sh --kit-dir ./device-test-kit --hap ./hello-maui-app.hap --install --start --capture 60`
   → 期望 `IsOverlayAvailable=true`（flags bit1；MAPFIX 后 abc 已含 `entry/ets/map/MapOverlay` 模块记录，
   无 AppKey/指纹不一致时才按降级路径登记）、Map `Ready/MarkerClick/CameraIdle`、LiveView create/update/stop
   → 回传截图/录屏＋状态原文＋AGC 开通截图。
4. **无障碍采集（可并入任一轮）**：加 `--a11y-probe` → 期望 `a11y/selfcheck.txt`（`accessibilityStatus: 1`＋正整数节点数）与 `a11y/hilog-a11y.txt`（缺失容忍、不算失败）→ 回传 `a11y/` 两文件＋`summary a11y_*`。
5. **Blazor 段（kit #31 新增；必须先重签）**：按《自签说明》Blazor 条目重签 `hello-blazorwasm-host-unsigned.hap`（工程 `AppScope/app.json5` 的 bundleName 必须为 **`com.example.opendotnet`**）→
   `sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe`
   → 期望 hilog 出现 `BlazorWebHost ... marker: BLZ_BOOT`（window load）与 `marker: BLZ_RENDERED`（Blazor 首帧）两条，无 `marker: BLZ_ERROR`；
   人工：首屏显示 **“Hello from Blazor WebAssembly”**、进 `/counter` 点击一次 **+1**、**截图 1 张**
   → 回传 `blazor/` 证据（失败为 `blazor-hilog.txt`）＋截图。无 hdc/不能重签时：自动两项登记「未测（无 hdc）」，人工两项照做。

## 3. 判定表（逐 Run 填）

| 态 | 判据 | 结论 |
|---|---|---|
| JIT | `run_a_probe_1=OK`＋managed 输出/首帧＋`xwe=0 source=default` | JIT 直起可用 |
| XWE | A 不通（probe≠OK/SEGV）时看 B：`xwe=1 source=file` 且能起 | 需 `xwe.txt=1` |
| AOT | `run_d_aot_route=1`＋`NativeAOT payload … aot=1`＋无 `The application to execute does not exist`；aot 标记缺库时应见显式 `falling back to the JIT route` 行 | AOT 直启成立 |
| 解释器 | `run_c_interp_mode=3(file)`（清单包 `3(manifest)`、`run_c_via=manifest`）＋maps 含 `libclrinterpreter.so`＋managed 输出 | 解释器激活 |
| harmony | `IsOverlayAvailable=true`＋Map/LiveView 实际点亮（AppKey 与重签指纹一致） | Map/LiveView 可用 |
| runtime_mode | 默认包 `summary runtime_mode=jit(hap)`＋execmem 含 `runtime-mode=jit source=manifest`；写/删 `<files>/interp.txt` 应分别切到 `source=file` / 回落 `source=manifest` | 标记/优先级正确 |
| **Blazor（kit #31）** | `--blazor-probe` 输出含 `marker: BLZ_BOOT` 与 `marker: BLZ_RENDERED`（无 `BLZ_ERROR`）；人工首屏 “Hello from Blazor WebAssembly” + `/counter` 0→1 | Blazor/ArkWeb 承载可用 |

> 失败 Run 保留对应报告 tar，`summary conclusion` 给建议行；无入口项登记「未测（本包无入口）」，不判失败。

## 4. 注意

- 包内 hap 为自签：安装失败码 **9568257**（及 **9568344**）**属预期**，先重签；重签需**华为调试证书**（Profile 绑定 UDID）。
  **Blazor hap 的 bundle 与其他不同**（`com.example.opendotnet`）：重签工程的 bundleName 必须同名，`-signCode 1` 不变。
- AOT hap 只有 3 个 `.so`，勿用 kit 的 JIT 期望值核对；AOT/harmony 安装会顶替 kit 主包，回 JIT 需重装 kit hap。
- 自建变体用 **`-p:OpenHarmonyRuntimeMode=jit|aot|interp`**（默认 jit；aot 需 `lib<stem>.so`，interp 可带
  `-p:OpenHarmonyInterpreterPack=<目录>`）；设备侧仍是 `xwe.txt`/`interp.txt` 优先（file>manifest>default）。
- 所有数字以 release「## Integrity」与 `.tar.gz.sha256` sidecar 为准（重签/重打包后哈希必变）；#31 数字入口见
  release「## Integrity（kit #31）」（#30 快照仅作对照）。
- 细判（TTS/HUKS/文本编辑/动画/列表/图片/深链）：`2026-09-28-ohos-tester-handoff-kit30.md` §2；**Blazor 细判**：`2026-09-29-ohos-tester-handoff-kit31.md` §2/§4；无障碍逐项判据：`2026-09-27-ohos-accessibility-device-verification.md`。
