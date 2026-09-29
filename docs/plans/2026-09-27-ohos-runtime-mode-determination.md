# 运行时模式判定卡：JIT / AOT / 解释器 / 渲染（2026-09-27）

> **2026-09-29 更新（kit #33，当前）**：kit #33 = #32 + **Blazor 回归修复**（读路径恢复 `blazor/<x>`、`_framework/dotnet.js` 物化、**双 hap 默认 CSP/`-nocsp` A/B**；FIX-BLZ-PATH/FIX-BLZ-JS）+ **MAUI TabbedPage 渲染/无障碍修复**（FIX-TABBED/A11Y-TABBED）+ **W5 四件**（T13/N3/T21/T22，套件 **470/floor 450**）+ **AOT v2 独立资产**（`aot-haps-v2.tar.gz` 17,323,220 / `265e014f…`）。**7 hap** = MAUI 5 重建（新壳 abc **294,976 B / `6cf7dda2…`**）+ Blazor 默认（27,216,958 / `69de2eea…`）与 `-nocsp`（27,216,659 / `c1ef7e06…`，包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）；bundle/preview.28 **77,689,347 B / `155960f4…`**（锚 `e7727959cc`）；整包 tar **218,138,546 B / `38e4d57a…`**、树 **`064cb001…`**、sidecar **`8297363e…`**、`SHA256SUMS` **17 项 / 1,517 B / `37031b9a…`**（dtk id 597711909 / sidecar 597714378；重签/重打包后必变）—— 数字以 release「## Integrity（kit #33）」与随包校验为准；判定点 = `docs/plans/2026-09-29-ohos-tester-handoff-kit33.md` + `docs/plans/2026-09-29-ohos-blazor-regression-retest-card.md`（#32 = 上一版，见其交接文）。

> 目标：**一轮设备定运行时模式**。三条硬证据：`hilog/hilog-execmem.txt`（路由行）、managed 输出/首帧、`/proc/<pid>/maps`。
> 判定用 `tester-run.sh` **v13**（v13 = **137,113 B / `2caa06bd…`** / asset **594519342**；v12 = 126,658 B / `87763a3e…` / `script_version=12 (2026-09-28)` 为 #30 值：v10 起 `--mode-matrix` 一键矩阵（见 §2.0），v11 起另加 `--a11y-probe`，v12 起 `summary runtime_mode` 读 hap `libs/<abi>/runtime-mode.txt` 且 `interp_mode`/`aot_route` 按 file（interp.txt）> manifest（清单）> default 取值）：证据包 `tester-report-*.tar.gz` 含
> `hilog/hilog-execmem.txt` 与 `summary.txt` 键 `aot_route=0|1|0+1|1(manifest)|<unavailable>`、`interp_mode=<v>(file|manifest|default)|<unavailable>`、`runtime_mode=<v>(hap)|invalid(<值>)|<absent>`（缺失容忍；file>manifest>default）；
> 矩阵轮另出 `mode-matrix/summary.txt`（逐 Run 安装/启动/probe_1/xwe/首帧/崩溃/报告 tar + 结论建议行）；
> **打包期单开关（MS-MODE，2026-09-28）**：`-p:OpenHarmonyRuntimeMode=jit|aot|interp`（默认 jit）直接把同一 publish 产出对应形态——
> aot 校验 `lib<stem>.so` 存在，interp 可用 `-p:OpenHarmonyInterpreterPack=<解包目录>` 换入 `libcoreclr.so`+`libclrinterpreter.so`；
> 标记写入 hap `libs/<abi>/runtime-mode.txt`，宿主在 `xwe.txt`/`interp.txt` 同点读取（`interp.txt` 仍优先），日志
> `runtime-mode=<v> source=file|manifest|default`；规则与验证见 ohos-workload `docs/openharmony-hap-packaging.md`「Runtime mode switch」；
> 下文 AOT/解释器设备轮仍按 Run D/C 用既有资产，本开关是后续 hap 变体的打包入口；
> 三形态一键出包（构建侧）：`sh ohos-workload/scripts/make-mode-kit.sh --project <app.csproj> --tfm <tfm> --out-dir <dir> --interp-pack <pack> [--mode jit,aot,interp] [--sign <UDID>]` → `out/<mode>/<stem>-<mode>.hap`（逐模式断言 marker + lib 后保留；`--sign` 沿用 sign-for-device 口令纪律），规则与验证见 ohos-workload `docs/openharmony-hap-packaging.md`「Runtime mode kits」；
> **当前 kit = #31**（Blazor WASM/ArkWeb 组件增量 = 第 6 个 hap `hello-blazorwasm-host-unsigned.hap`（26,794,931 B / `36010a9c…`，未签名，bundle `com.example.opendotnet`）+ tester-run v13（`--blazor-probe`：`BLZ_BOOT`/`BLZ_RENDERED`）；MS-MODE（#30）= runtime-mode 打包开关 + tester-run v12 + MAPFIX harmony 重切；
> R3 增量（CoreSpeechKit TTS / HUKS-first SecureStorage / 自绘深度五连）仍然有效，见
> `2026-09-28-ohos-tester-handoff-kit30.md`（#29 见 `2026-09-28-ohos-tester-handoff-kit29.md`）；
> 下表 kit #28 行是历史 API 复核快照，kit #30 行为 2026-09-28 发布实测（#31 实测 tar 207,023,588 / `f4325d2f…`、树 `52e77ee8…`、sidecar `7d0cba77…` 仅作对照）；#32 实测 tar **207,114,608 / `8f690949…`**、树 `645879bc…`、sidecar `344760e7…`）。

## 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`；asset id/尺寸/digest 2026-09-27 API 复核，AOT-RECUT 后；harmony 行 2026-09-28 MAPFIX 后复核；kit #30 行为 2026-09-28 发布实测）

| 资产 | asset id | 大小 (B) | sha256（前缀） | 取件注意 |
|---|---|---|---|---|
| `device-test-kit.tar.gz`（kit #32，2026-09-28 发布） | 392356147 | **207,114,608** | **`8f690949…`**（sidecar `344760e7…`；树 `645879bc…`；`SHA256SUMS` 16 项 / 1,410 B / `2d3f2fad…`） | 6 个 hap（5 个 MAUI JIT（#32 新壳 abc 289992）+ 1 个未签名 Blazor `hello-blazorwasm-host-unsigned.hap`、#32 = **26,803,570 B / `5011cf73…`（0 权限）**、bundle `com.example.opendotnet`；`libs/arm64-v8a/runtime-mode.txt=jit`；zip 279 = 24 + 254 payload + marker、`libs` 270）＋文档＋verify-kit；#29 196,990,205 / `e895cc0a…`、#28 196,220,486 / `091dcc56…` 为历史对照 |
| `device-test-kit.tar.gz`（kit #33，2026-09-29 发布） | 597711909 | **218,138,546** | **`38e4d57a…`**（sidecar `8297363e…`；树 `064cb001…`；`SHA256SUMS` 17 项 / 1,517 B / `37031b9a…`） | 7 hap（MAUI 5 重建含 TabbedPage/W5 + Blazor 默认/`-nocsp`；AOT 段用 `aot-haps-v2.tar.gz`；abc 期望 294,976/20,916） |
| `aot-haps.tar.gz` | 592465115 | 17,093,146 | `91e1b9d3…` | `hello-maui-app-aot{,-unsigned}.hap`＋README（**已内置桥宿主 `bb51826e…`**，开箱 `aot=1`，见 §2.2） |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 593868367 | 196,898,796 | `9b0506fa…`（sidecar `c0b86645…`；README `4cd711df…`） | 5 个 harmony-flavor hap（壳 **291,628 B / `a637a513…` @13.0.1.0，overlay 真编译**；`MapOverlay.ets`/LiveView sink 在包内）＋README；**前置 = 自备重签材料 + AGC 开通/权益**（Map 地图服务＋签名指纹 / LiveView TIMER 权益 / Push/Account），判定见 §2.5。旧 A1 件 592541627 / 196,118,871 / `f7a4faa2…`（abc 263,784 / `d3a7b718…`）**无 overlay 模块记录**，已 clobber 替换 |
| `ohos-interpreter-pack.tar.gz` | 590052493 | 2,419,988 | `a10699b3…` | `native/libcoreclr.so`＋`libclrinterpreter.so`＋README/sidecar |
| `tester-run.sh` **v13**（当前） | **594519342** | **137,113** | **`2caa06bd…`**（v12 = 593961018 / 126,658 / `87763a3e…` 为 #30 值） | v12 = `runtime_mode` 清单键（`libs/<abi>/runtime-mode.txt`）+ file>manifest>default 回退 + 清单 interp 的 Run C（见 §2.0）；v11 = 119,452 B / `2355e493…`（`--mode-matrix` + `--a11y-probe`）、v10 = 109,227 B / `714ae9b5…`、v9 = 75,917 B / `3c2d33bf…`（`aot=`/`interp=` 采集）、v8 = 73,375 B / `6ca2093e…` |

## 0. 四态矩阵

| 态 | 取件/前置 | 关键日志（execmem 文件） | 判定 | 回传 |
|---|---|---|---|---|
| JIT | kit #30 stock hap（默认 `runtime-mode.txt=jit`；#28 快照同流程） | `xwe=0 source=default`、`runtime-mode=jit source=manifest|default`、`probe: 1=OK`、`aot=0 dir=…` | `1=OK` 且 managed 运行 → JIT 可用；`1≠OK` 或 SEGV/`mprotect` 拒 → 走 `xwe.txt=1` A/B | tar |
| AOT | aot-haps（已内置桥宿主）＋重签 | `NativeAOT payload … aot=1` | managed 输出，且**无** `The application to execute does not exist` | tar |
| 解释器 | interp pack 替换 payload＋`interp.txt`=3＋重签（或清单 `runtime-mode.txt=interp` 的包） | `interp=3 source=file`（清单包为 `runtime-mode=interp source=manifest` + `interp=3 source=manifest`） | maps 含 `libclrinterpreter.so`、匿名 `r-x` 照录（Precode stub 风险，不得改策略）、managed 输出 | tar＋maps |
| 渲染/交互 | 任一态起来后 | —（功能性） | ①首帧 ②触摸→handler ③导航 ④列表/WebView | 截图/录屏/日志 |

## 1. 判定树（自上而下；先证跑通，再判模式）

1. `probe: 1=OK`？否（`1=1|12|13|38` 或启动 SEGV/`mprotect` 拒绝）→ 写 `xwe.txt=1` 复跑 A/B，两轮都记录；仍未通按崩溃分支取证。
2. 应用 managed 起来了（`[maui] openharmony build …`＋首帧）？否 → 按崩溃分支（applib/dlopen/bootstrap + `aot=`/`interp=` 行）取证，不进入后续态。
3. `aot=1`＋managed 输出＋无 `The application to execute does not exist`？是 → AOT 直启成立；若见 `bridged start_app … JIT payloads only` → 误用了旧的 R2-2 资产（现资产已内置桥宿主，应无此行）；aot 标记缺库时应见 `runtime-mode=aot but …; falling back to the JIT route`（显式回退，不崩）。
4. `interp=3 source=file`（清单包 `source=manifest`）＋maps 含 `libclrinterpreter.so`？是 → 解释器激活；匿名 `r-x` 只计数（`Precode`/UMEntryThunk 残余先记录）。
5. 之后按 §2.4 做四项功能性判定；每态单独一轮，不混轮。

## 2. 精确步骤 / 期望 / 回传

### 2.0 一键执行（v10 `--mode-matrix`，推荐入口）

```sh
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

一条命令跑四个 Run（每个 Run 是本脚本的独立子轮：kit 校验与 bundleName 白名单照走，**任一步失败只记录、不中断其余**）：

| Run | 做什么 | 前置资产 |
|---|---|---|
| A | JIT stock：卸载+安装主 hap → 启动 → 录 `--capture` 秒 | kit（必需） |
| B | XWE A/B：写 `<files>/xwe.txt=1` → `aa force-stop` → 启动/录制 → 清理 `xwe.txt` | kit |
| C | 解释器：校验 `--interp-pack` sha → 换入 `libcoreclr.so`+`libclrinterpreter.so`（`--interp-overlay` 可换成指定脚本）→ 装变体 hap → 写 `<files>/interp.txt=3` → 启动/录制 → 清理 + 重装 stock；**v12**：主 hap 清单声明 interp 时不需资产（直接装 stock hap、不写 `interp.txt`，摘要 `3(manifest)`） | `--interp-pack`（或已重签的 `--interp-hap`；或清单 interp 的主 hap） |
| D | AOT：校验 `--aot-haps` sha → 安装 `hello-maui-app-aot*.hap` → 启动/录制 → 重装 stock | `--aot-haps` |

产出 `<out>/mode-matrix/summary.txt`（每 Run 一份 `tester-report-*.tar.gz` + `mode-matrix/<run>.log` 在同一目录）：

| 键 | 含义 |
|---|---|
| `run_<x>_install` / `run_<x>_start` / `run_<x>_alive` | 安装结果（ok / code:9568297 / …）、启动结果、存活检查 |
| `run_<x>_aot_route` / `run_<x>_interp_mode` / `run_<x>_runtime_mode` | `0|1|0+1|1(manifest)|<unavailable>` / `<v>(file|manifest|default)|<unavailable>` / `<v>(hap)|invalid(...)|<absent>` |
| `run_<x>_probe_1` | 宿主 `OHOS_DOTNET probe: 1=` 的取值（JIT 可用性第一判据） |
| `run_<x>_xwe` | `xwe=0` / `xwe=1`（A/B 对照） |
| `run_<x>_frame` / `run_<x>_crash` | 首帧关键字命中（yes/no，未录到记 `<unavailable>`）/ 崩溃关键字（`SEGV_ACCERR`、`SIGSEGV`、`cppcrash`、`bootstrap failed`、`The application to execute does not exist`… 或 `none`） |
| `run_<x>_report` | 该 Run 的报告 tar 路径 |
| `run_c_via` / `run_c_overlay` / `run_c_hap` / `run_c_hap_sha256` / `run_c_signed` / `run_c_coreclr_check` | 清单路线（`manifest` = 主 hap 标记 interp、直接跑 stock hap，不写 `interp.txt`、不重打包）或变体构建方式（`builtin` / `script:<路径>` / `given`）、变体路径与 sha、是否重签、解释器宽字符串检查 |
| `interp_pack_sha256`/`interp_pack_check`/`interp_pack_members`、`aot_pack_sha256`/`aot_pack_check`/`aot_pack_members` | 可选资产校验（sidecar=ok；包内 `SHA256SUMS` 逐成员复核） |
| `preclean_*_rm` / `switch_*_write|_rm` / `force_stop` / `restore_install` | 切换文件清理与写删、重启、还原 stock 的执行结果（`ok`/`fail(rc=…)`） |
| `matrix_failures` / `conclusion` | 未通过计数 / 结论建议行（JIT 直起可用 / 需 xwe=1 / 解释器 3(file) / AOT aot=1） |

注意：

- `--dry-run` 只打印计划与资产清单（不碰设备，含必需资产列表）；无 `hdc` 时给出明确提示（退出码 3）。
- Run C 变体是本地重打包（**未重签**）；设备拒绝未签包时按 `自签说明.md` 重签后，用 `--interp-hap <重签 hap>` 重跑（其余 Run 不受影响）。
- `--capture` 的秒数对每个 Run 生效（默认 30，四态整轮建议 60）；矩阵轮不执行 `--probes`/`--extra-probes`（会提示）。

### 2.1 JIT（kit #33 stock；#32/#30 快照同流程）
```sh
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60 --out tester-report
hdc shell "echo 1 > /data/storage/el2/base/haps/entry/files/xwe.txt"   # A/B：仅当 probe 1≠OK/SEGV 才写
sh tester-run.sh --kit-dir ./device-test-kit --start --capture 60 --out tester-report-xwe1
hdc shell "rm -f /data/storage/el2/base/haps/entry/files/xwe.txt"
```
期望：`summary aot_route=0 interp_mode=0(default) runtime_mode=jit(hap)`；`xwe=0 source=default`（A/B 轮为 `xwe=1 source=file`）、`runtime-mode=jit source=manifest`（写过 `interp.txt` 的机器为 `source=file`）；`probe: 1=OK`；managed 输出＋首帧。
回传：`tester-report*.tar.gz`（A/B 两轮都发）。

### 2.2 AOT（aot-haps）
> **已内置桥宿主（AOT-RECUT，2026-09-27）**：资产内宿主 = kit #28 桥版 **269,216 B / `bb51826e…`**，
> `start_app` 直接探测 `lib<stem>.so` → `openharmony_app_main` 并记 `aot=1`；**无需换宿主**，
> 按《自签说明.md》重签后 `aa start` / 桌面启动即可判定（旧 R2-2 包才会打
> `bridged start_app supports JIT payloads only`）。**MS-MODE（2026-09-28）起**：用
> `-p:OpenHarmonyRuntimeMode=aot` 构建的包（标记 `runtime-mode.txt=aot`）走同一探测；标记为 aot 而
> `lib<stem>.so` 缺失/不可加载时，宿主记 `runtime-mode=aot but <path> …; falling back to the JIT route`
> 并回退（不崩、不再静默穿透）。
```sh
sh tester-run.sh --kit-dir ./device-test-kit --hap ./hello-maui-app-aot-signed.hap --install --start --capture 60 --out tester-report-aot
```
期望：`summary aot_route=1`；`NativeAOT payload … aot=1`；managed 输出/首帧；无 `The application to execute does not exist`；hap 内无 `libcoreclr.so`/`libhostfxr.so`（AOT 形态）。
注意：AOT hap 的 bundle 与 kit 主包相同（`com.example.hellomauiapp`），装 AOT 会顶替 JIT 主包；回 JIT 需重装 kit 主 hap。

### 2.3 解释器（interp pack）
```sh
tar xzf ohos-interpreter-pack.tar.gz && (cd ohos-interpreter-pack && sha256sum -c SHA256SUMS)
# 取 hello-maui-app-unsigned.hap：libs/arm64-v8a/ 内替换 libcoreclr.so ＋ 加入 libclrinterpreter.so；重签
hdc shell "echo 3 > /data/storage/el2/base/haps/entry/files/interp.txt"
sh tester-run.sh --kit-dir ./device-test-kit --hap ./hello-maui-app-interp.hap --install --start --capture 60 --out tester-report-interp
hdc shell "pidof com.example.hellomauiapp"; hdc shell "cat /proc/<pid>/maps" | grep -E 'libclrinterpreter|r-x.*\[anon' > maps-interp.txt
hdc shell "rm -f /data/storage/el2/base/haps/entry/files/interp.txt"
```
期望：`summary interp_mode=3(file)`（清单包为 `3(manifest)`、`run_c_via=manifest`）；`interp=3 source=file`（清单包先记 `runtime-mode=interp source=manifest`、再记 `interp=3 source=manifest`；写过 `interp.txt` 时 file 覆盖标记）；maps 含 `libclrinterpreter.so`、匿名 `r-x` 计数照录；managed 输出；无 `SEGV_ACCERR`。
回传：tar（含 execmem）＋maps 摘录＋pack `sha256sum -c` 输出。

### 2.4 渲染/交互（任一态）
① 首帧（截图）→ ② 触摸→managed handler（日志/状态）→ ③ 导航（页面切换）→ ④ 列表滚动＋WebView 加载；各附截图或日志。

### 2.5 harmony 变体（`harmony-haps.tar.gz`，Map/LiveView 点亮的唯一打包入口）
> 壳 = HarmonyOS SDK 构建（包内即 harmony flavor：`MapOverlay.ets` + LiveView sink，**无需测试方自建壳**）；
> 前置 = 自备重签材料（自签会被 9568257/9568344 拒绝，属预期）＋ **AGC 开通/权益**（Map 地图服务 + 证书指纹；
> LiveView 实况窗 TIMER 权益 + 设备开关；Push/Account 按需）。5 个 hap 与 kit 同包名，装 harmony 会顶替 kit 主包；
> 回 JIT 重装 kit hap（同 §2.2）。静态形态（交付方逐 hap 断言 **102/102** + kit `verify-kit.sh --expected-abc 291628`
> KIT OK；与同提交默认 control 构建**仅 `ets/modules.abc` 不同**）：abc **291,628 B/`a637a513…`**（PANDA 13.0.1.0，
> 含 `entry/ets/map/MapOverlay` 模块记录 + `mapOverlayView`/`markerClick`/`cameraIdle` 符号）、libs 269
> （14 `.so`+254 payload+marker）、hap 内宿主 285,600 B/`5248c6a9…`、`module.json` 与 kit #30/#31 MAUI 对应 hap 逐字节相同、
> 14 `.so` 均带 `.codesign`；默认 JIT payload 不变（**AOT 走 §2.2 的 `aot-haps.tar.gz`**）。
> **更正（MAPFIX 2026-09-28）**：旧 A1 件（abc 263,784 B/`d3a7b718…`）的「`MapOverlay.ets` 真编译」不成立 ——
> 模块仅被复制、从未进编译图（abc 无模块记录，bit1 只能为 0）。本版由构建脚本向 harmony 的 `Index.ets`
> 副本注入静态 import 并修好 `MapOverlay.ets:135` 的 NodeController 无参构造，CI 门
> `HARMONY_REQUIRE_MAP_OVERLAY=1` 由 WARN 转绿；新 tar `9b0506fa…`（旧 `f7a4faa2…`）。
```sh
sh tester-run.sh --kit-dir ./device-test-kit --hap ./hello-maui-app.hap --install --start --capture 60 --out tester-report-harmony
```
期望：`IsOverlayAvailable=true`（flags bit1=1）、show/hide/区域/标记有真实地图视图与 `Ready`/`MarkerClick`/`CameraIdle`；
LiveView create/update/stop 出 TIMER 卡片（开关关 `-3`/`1003500004`、权益未批 `1003500005`）；Push/Account/Scan/Share 面板正常。
回传：截图/录屏＋状态原文＋AGC 开通/审批截图。

## 3. 回传物汇总
`tester-report-*.tar.gz`（`hilog/hilog-execmem.txt`＋`summary.txt`＋install/start 日志）＋解释器轮 maps 摘录＋重签说明；
AOT/解释器轮附被替换 .so 的 sha256。数字以 release「## Integrity」/ `.sha256` sidecar 为准（重签、重打包后必变）。
无障碍专项（可选）：`tester-run.sh` v13 `--a11y-probe` → `a11y/`（`selfcheck.txt`＋`hilog-a11y.txt`，`summary a11y_*`）；
逐项判定见 `2026-09-27-ohos-accessibility-device-verification.md`。
