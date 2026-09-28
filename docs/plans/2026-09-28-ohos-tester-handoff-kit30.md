# 测试方交接：kit #30、MS-MODE（runtime-mode 打包开关 / tester-run v12 / MAPFIX harmony 重切）判定点（2026-09-28）

> 运行时模式判定（JIT/AOT/解释器/渲染四态）：取件清单、判定树与每态步骤/期望/回传见
> `2026-09-27-ohos-runtime-mode-determination.md`（`tester-run.sh` **v12** 的 `--mode-matrix` 一键矩阵 +
> `--a11y-probe` 无障碍采集）；无障碍逐项判据见 `2026-09-27-ohos-accessibility-device-verification.md`。

> 承接 kit #29 交接（`2026-09-28-ohos-tester-handoff-kit29.md`）：R3（CoreSpeechKit TTS /
> HUKS-first SecureStorage / devloop / 自绘深度五连）与 #28 的 R2（Map 覆盖层 / LiveView 探测 /
> 壳 `start_app` AOT 启动桥 / 解释器实验）、#27 KIT-EXT2（Push/Account/Map 探测、130 导出、marshal-off）、
> #26 的 P2-INTEROP/TASK-MIG/PLAT-GAP、#25 的权限链/Share/Scan/AOT 判定点**继续有效**（本文 §2 给出口径）；
> JIT A/B 指令与 `probe:`×`xwe` 判定表（kit #24 交接 §3–§5）**一字未改**。本文只覆盖 #30 的增量与判定点。
> 结论先行：kit #30 = **MS-MODE 打包批** ——
> ① **runtime-mode 打包开关**（规则与验证见 ohos-workload `docs/openharmony-hap-packaging.md`
> 「Runtime mode switch」）：`-p:OpenHarmonyRuntimeMode=jit|aot|interp`（默认 `jit`）一个属性选择启动形态，
> 标记由 `_OpenHarmonyStageRuntimeMode` 写入 hap `libs/<abi>/runtime-mode.txt`（payload-in-libs 暂存之后、
> codesign 之前 —— 随签名载荷、并被稍后的 `.dotnet-payload.json` marker 计入）；`aot` 要求 publish 载荷里有
> `lib<stem>.so`（缺则**构建期报错**并指名 aot-haps 的 publish 参数：`-p:PublishAot=true
> -p:PublishAotUsingRuntimePack=true -p:NativeLib=Shared`）、`interp` 可带
> `-p:OpenHarmonyInterpreterPack=<解包目录>`（`<dir>/` 或 `<dir>/native/` 的 `libcoreclr.so` +
> `libclrinterpreter.so` 覆盖 publish natives 并与其余 natives 同一次 codesign 重签）；非法值、
> `interp` 之外的 pack 均为构建期错误。宿主在 `xwe.txt`/`interp.txt` 同点读取标记，优先级
> **file（`<filesDir>/interp.txt`，可写沙箱）> manifest（打包标记）> default（jit）**，每次启动都记
> `runtime-mode=<v> source=file|manifest|default`（hilog + stderr）；`aot` 标记但 `lib<stem>.so`
> 缺失/不可加载时**显式**记 `runtime-mode=aot but <path> ...; falling back to the JIT route`（不再静默 JIT 穿透）；
> 过期/手改的非法标记只警告一次（`runtime-mode.txt carries an unknown value; keeping jit`）并保持 jit；
> 标记先查生效 `app_dir`、再查宿主库自身目录（`dladdr`），解压回退布局（`<filesDir>/dotnet`）也能读到。
> ② **tester-run v12**（126,658 B / `87763a3e…`，release asset id 593961018）：summary 增
> `runtime_mode` 键（读主 hap `libs/<abi>/runtime-mode.txt`：`jit|aot|interp(hap)`、非法值
> `invalid(<值>)`、无标记 `<absent>`），`interp_mode`/`aot_route` 按 **file>manifest>default** 取值
> （采集窗口没有日志行时由标记补：interp 记 `3(manifest)`、aot 记 `1(manifest)`），execmem 过滤保留
> `runtime-mode=` 行（含 aot 回退警告）；`--mode-matrix` 的 Run C 在主 hap 标记为 interp 时**直接跑 stock hap**
> （`run_c_via=manifest`，不写 `interp.txt`、不重打包；`--interp-hap` 仍为逃生口）。
> ③ **MAPFIX harmony 重切**（kit #29 发布后替换，asset id 593868367）：MapOverlay 真编译（abc
> **291,628 B / `a637a513…`**、tar **196,898,796 B / `9b0506fa…`**；旧 A1 件 abc 263,784 B / `d3a7b718…`、
> tar `f7a4faa2…` 缺 `entry/ets/map/MapOverlay` 模块记录、bit1 恒 0，已 clobber 替换）；判定点 =
> **AGC 地图 AppKey + 同指纹重签**（见 §2）。
> ④ **门禁与指纹**：交互套件 **391/floor 371**（+4 = MS-MODE：宿主标记解析 / 优先级与生效模式日志 /
> aot 回退 / pack 契约；`[suite] checks=391 total=391 floor=371 assert=True`）；ui/shell abc
> **281,052 B / `5c06143a…`**（headless **20,916 B / `54a1a201…`**）与宿主导出契约 **143/143** 不变。
> **kit #30 发布实测（2026-09-28，release `## Integrity (kit #30)` 已 PATCH）**：tar **196,992,264 B /
> `a781c25b…`**（#29 196,990,205 / `e895cc0a…`）、sidecar **`a63cd34f…`**（89 B）、树 **`cc1ca935…`**、
> `SHA256SUMS` **15 项 / 1,309 B / `3a369dd8…`**；下载发布的 tar 解包后 `verify-kit.sh --expect-tree-digest`
> = tree OK + **KIT OK（0 FAIL / 0 WARN）**。5 hap **~75.91 MB**：默认 **75,911,491 / `333b0436…`**、
> permissions 75,911,431 / `d86cf095…`、api20 75,911,487 / `cda37a2b…`、api20-permissions 75,911,523 /
> `2106703b…`、unsigned 73,718,261 / `458ee58d…`；zip **279** 条 = 24 + 254 payload + `runtime-mode.txt`；
> `libs` **270** = 14 `.so` + 254 payload + `.dotnet-payload.json` + **`runtime-mode.txt=jit`**（五 hap 同值）；
> hap 内宿主 **285,600 B / `de9b30dd…`**（pack 281,504 / `f6b3581a…`）；bundle **30,563,349 B / `c4647fc8…`**
> （Sdk pack 346,067 / `913bcadb…`；sdk-ohos 锚 `a691bf11dd`，`WORKLOAD_BUNDLE_SHA256` c2b527d3 → c4647fc8）。
> 包内 `verify-kit.sh` 的 abc 期望沿用 `281052`/`20916`，用 #28 的 `264136`（或更旧值）校验本包会 FAIL ——
> 属脚本预期；重签、预签或重新打包后哈希必然不同，以 release「## Integrity」与随包 `SHA256SUMS` 为准。

## 0. 一键执行（tester-run v12）

```sh
# 常规一轮（含 runtime_mode 键与 execmem 的 runtime-mode= 行）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# 运行时四态一键（JIT / XWE / 解释器 / AOT；清单 interp 包无需资产即走 Run C manifest 路线）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
# 无障碍采集（可并入任一轮）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60 --a11y-probe
```

## 1. kit #30 相对 #29 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1 | **runtime-mode 打包开关（MS-MODE）**：`-p:OpenHarmonyRuntimeMode=jit|aot|interp`（默认 `jit`）产出标记 `libs/<abi>/runtime-mode.txt`；`aot` 需 `lib<stem>.so`（缺 = 构建报错）、`interp` 可带 `-p:OpenHarmonyInterpreterPack=<目录>`（两个 `.so` 覆盖并重签） | kit #30 的 5 个 hap 为默认 **jit** 形态（包内可见 `libs/arm64-v8a/runtime-mode.txt`）；AOT/解释器变体从此是同一个 publish 属性，不必再手工换 payload | 用 v12 记 `runtime_mode=jit(hap)`；对交付方提供的 aot/interp 形态包记 `aot(hap)`/`interp(hap)`（§2） |
| 2 | **宿主标记解析与优先级**（与 `xwe.txt`/`interp.txt` 同启动点）：file（`<filesDir>/interp.txt`）> manifest（标记）> default（jit）；每次启动记 `runtime-mode=<v> source=…`；`aot` 缺库**显式回退**行；非法标记警告一次并保持 jit | 普通启动多一行 `runtime-mode=jit source=manifest`；写过 `interp.txt` 的机器上为 `source=file`；删掉后回落 `source=manifest`；aot 形态缺库时看到 `falling back to the JIT route`（不崩、不静默） | **优先级**与**回退行**（§2；四态矩阵的 Run A/C/D 各有一份日志） |
| 3 | **tester-run v12**：summary 增 `runtime_mode`；`interp_mode`/`aot_route` 的清单补值（`3(manifest)`/`1(manifest)`）；execmem 保留 `runtime-mode=` 行；Run C 支持清单 interp（`run_c_via=manifest`，无 `--interp-pack`/`--interp-hap`） | 一条命令拿到 `summary.txt`（含 `runtime_mode`、`run_c_via`）与 `mode-matrix/summary.txt`；解释器轮在清单包上不再需要资产 | **模式矩阵 / 优先级**（§2；判定树见判定卡 §2.0） |
| 4 | **MAPFIX harmony 重切**：构建脚本向 harmony `Index.ets` 注入静态 import 并修 `MapOverlay.ets:135` 的 NodeController 构造，CI 门 `HARMONY_REQUIRE_MAP_OVERLAY=1` 由 WARN 转绿 | `harmony-haps.tar.gz` 新件（abc 291,628 B/`a637a513…`、tar `9b0506fa…`）abc 内有 `entry/ets/map/MapOverlay` 模块记录 + `mapOverlayView`/`markerClick`/`cameraIdle` 符号；旧件 bit1 只可能为 0 | **Map overlay 点亮**（§2：AGC AppKey + 同指纹重签；无 AppKey 时按降级路径登记） |
| 5 | **门禁与重建**：交互套件 **387/floor 367 → 391/floor 371**（MS-MODE 4 检查）；abc **281,052 B**（headless 20,916 B）与导出契约 **143/143** 不变；`verify-kit.sh` abc 期望沿用 `281052`/`20916` | 校验步骤、证据字段与 #29 相同，**只换套件行与脚本版本（v12）**；用 #28 的 `264136` 或更旧值校验本包会 FAIL（脚本预期） | 校验时以 release「## Integrity」与包内 `verify-kit.sh` 为准 |

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **runtime_mode 标记（默认 jit 包）** | 重签 → 装默认 hap → `sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60` | `summary runtime_mode=jit(hap)`；execmem 含 `runtime-mode=jit source=manifest`；`interp=`/`aot=` 行与 #29 一致（default/0） | `summary.txt` + `hilog/hilog-execmem.txt` |
| **file 覆盖 manifest（解释器轮）** | 在清单 interp 的主 hap 上写 `<files>/interp.txt=3` 启动（或按判定卡 §2.3 换 payload） | `interp=3 source=file`；`summary interp_mode=3(file)`、`runtime_mode=interp(hap)`（清单包）；删掉 `interp.txt` 后回落 `3(manifest)`/`source=manifest` | 两轮 execmem 行 + summary |
| **aot 显式回退（aot 形态包，可选）** | 对交付方提供的 aot 形态 hap（或 `aot-haps.tar.gz` 资产）安装启动；缺/坏 `lib<stem>.so` 时 | 正常启动（JIT 回退）且日志有 `runtime-mode=aot but <path> …; falling back to the JIT route`；有库时为 `aot=1`（承 #28 口径） | 启动日志 + `summary run_*_aot_route` |
| **模式矩阵 Run C 清单路线（v12）** | 用标记为 interp 的主 hap（无需 `--interp-pack`/`--interp-hap`）跑 `--mode-matrix` | Run C 装 stock hap、**不写 `interp.txt`**、不重打包；`run_c_via=manifest`、`run_c_interp_mode=3(manifest)`，`conclusion` 读 `3(manifest)`；结束后 stock hap 已还原 | `mode-matrix/summary.txt` + Run C 报告 tar |
| **优先级回归（file>manifest>default）** | 同一 hap 三轮：无 `interp.txt`（default/manifest）→ 写 `interp.txt`（file）→ 删除（回落） | 三轮的 `runtime-mode=` 行 `source=` 依序为 `manifest`（或 `default`）/`file`/`manifest`；行为一致、无崩溃 | 三轮 execmem 行 |
| **Map 覆盖层点亮（MAPFIX harmony + AppKey）** | 解压 `harmony-haps.tar.gz`（新件）→ 按《自签说明》**同指纹重签** → AGC 配置地图 AppKey（与签名证书指纹一致）→ 启动 | `IsOverlayAvailable=true`（flags bit1）、地图视图出现、`Ready`/`MarkerClick`/`CameraIdle` 可达；无 AppKey/指纹不一致时按 `1000900010` 类错误排查并登记降级 | 截图/录屏 + flags/事件日志 + AGC 开通截图 |
| **Map 覆盖层降级不抛（默认包，承 #28）** | 默认 flavor 5 hap 上触发 Map 探针/自检 | `IsOverlayAvailable=false`；show/hide/close/区域/标记全部降级不抛 | 状态原文 + hilog；无入口登记「未测（本包无入口）」 |
| **TTS / HUKS / a11y / 自绘深度（承 #29）** | 同 #29 交接 §2（默认包 TTS 降级不抛、HUKS 重启读回/删除清 key、`--a11y-probe`、文本编辑/动画/列表/图片/深链） | 与 #29 一致；本轮宿主/壳重建后仍不回归 | 对应证据（本包仍为 JIT payload、默认 flavor） |
| **无 HMS 降级不抛（承 #27）** | OpenHarmony SDK 包上触发 Push/Account/Map/TTS 探针 | `Unavailable`/null/false + `IsSupported=false`，**无异常** | 启动日志 + 状态原文 |
| **权限弹窗 / Share / Scan / PLAT-GAP / 新 payload 首次运行**（承 #25–#28） | 同对应交接步骤 | 与 #28/#29 相同口径；**本包首次运行判定 = 重签 → 安装默认 hap → 启动 → 5 条冒烟 + verify-kit（abc 281,052/20,916）** | 对应材料 + `tester-run.sh` 证据包 |

> 本轮 kit 的 5 个 hap 仍是 **JIT payload**（hostfxr 回退；`runtime-mode.txt=jit`）；AOT/interp 形态与 harmony
> 壳、HMS 设备、AGC 权益均需测试方侧外部条件，本环境不可代办。没有对应入口/资产时按「未测（本包无入口）」
> 登记，不要判失败。

## 3. 启动路径与 JIT 判定（一字未改，承 #24–#29）

- 启动相关修复不变：P17 跳过重复解压、H7 rawfile fd 直读、headless abc `13.0.1.0`、
  payload-in-libs（`libs/arm64-v8a/` 原地启动 + `.dotnet-payload.json` 校验，`dotnet.zip` 回退）；
  kit #30 宿主新增 runtime-mode 标记解析（MS-MODE），启动判定不变（JIT 路径仍是 hostfxr）。
- exec-memory 探针与 `xwe.txt` A/B **未变**（v12 仍采集 `hilog/hilog-execmem.txt`，并保留 `aot=`/`interp=` 路由行、
  新增保留 `runtime-mode=` 行；`summary.txt` 的 `aot_route`/`interp_mode` 键自 v9 起、`runtime_mode` 键自 v12 起，
  file>manifest>default）；判定表、A/B 指令与 NativeAOT 指引见 `2026-09-24-ohos-tester-handoff-kit24.md` §3–§5。
- 最直接的回归检查：应用能起（`[maui] openharmony build …` 出现）、原生桥调用不抛
  `EntryPointNotFoundException`/`DllNotFoundException`、TTS/HUKS/深链探针不崩、JIT payload 的 AOT 探针
  以 `aot=0` 回退不阻塞启动、`runtime-mode=` 行出现且不阻塞启动。

## 4. 校验与取证（与 #29 相同，只换套件行与脚本版本）

1. 下载/校验/重签/安装同 `快速开始.md` §1/§3；kit 内 `verify-kit.sh` 逐 hap 断言 abc **`281052`**/`20916`、
   `dotnet.zip` 254 项、`libs/arm64-v8a` 14 个 `.so` + `.dotnet-payload.json` payload-in-libs 断言、
   `resources.index` 1588/1780（≤ 2 KiB）；语义不变（FAIL → 退出码 1；WARN → 仍 `KIT OK`）。**用 #28 的旧期望值
   `264136`（或更早的 `245412`/`234620`）校验本包会 FAIL —— 那是脚本的预期行为，不是包坏。**
   本轮整包数字（tar/树/sidecar/5 hap）发布实测：tar **196,992,264 B / `a781c25b…`**、树 **`cc1ca935…`**、
   sidecar **`a63cd34f…`**、`SHA256SUMS` 15 项 / 1,309 B / `3a369dd8…`（下载解包复核 = tree OK + KIT OK）；
   重签/重打包后以 release「## Integrity」与 `.tar.gz.sha256` sidecar 为准。
2. 一条命令取证（`tester-run.sh` **v12**）：`sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60`
   → 证据包含 `hilog/hilog-{applib,dlopen,bootstrap,execmem}.txt`、`device/payload-*.txt`、
   `meta/kit-selfcheck.txt`（`kit_index_ok`/`payload=yes|no`）与 `summary.txt`（`aot_route`/`interp_mode`/`runtime_mode` 键）。
   模式矩阵（四态一键）：`--mode-matrix`；无障碍专项：`--a11y-probe`（`a11y/` + `summary a11y_*`）。
3. 有 harmony flavor / HMS 的测试者请附：壳的构建出处（可直接取 `harmony-haps.tar.gz`，MAPFIX 重切件
   abc 291,628 B/`a637a513…`、含 overlay 模块记录；仍需自备**同指纹**重签材料与 AGC 权益）、
   Map/LiveView 点亮证据（flags/事件/卡片）、TTS/HUKS/深链证据同 #29、解释器轮附 `interp=` 行与 maps 摘录。
4. AOT hap 不要用 kit `verify-kit.sh` 的 JIT 期望值（14 `.so`）核对（AOT hap 只有 3 个 `.so`）；用
   `aot-haps-README.md` 的 5 条形态判定。

## 5. 仍未验证（如实边界）

- 本轮增量（runtime-mode 标记经打包 hap 的真机回合、aot 显式回退行、清单 interp 的 Run C 路线、
  MAPFIX harmony 包的真机 Map 点亮）**均未上机**：kit 的 hap 是自签名（`9568257`/`9568344` 属预期，先重签）。
- MS-MODE 的离线证据：`selftest-hap-targets.sh` T7（默认/非法/aot 缺库与带库/interp 两种 pack 布局/错误；
  **50 检查 / 0 失败 / 1 skip**）、交互套件 ms-mode 4 检查（**391/floor 371**）、
  `test/aot-smoke/run-local-smoke.sh`（默认/aot/interp 标记、aot 回退、`interp.txt` 覆盖）；
  `selftest-build-arkts-shell.sh` **185**（T18 = overlay-index patch ±）、`selftest-verify-harmony.sh` **102/102**
  （对已发布的 MAPFIX harmony hap + control 复跑）、`selftest-tester-run.sh` **634/0**（S14b/S14c/S17b
  runtime_mode 标记）、`selftest-verify-kit.sh` **72/0**（abc fixtures 281052/20916）；真机回合仍待测试方。
- MAPFIX 的静态证据：逐 hap 断言 102/102、`verify-kit.sh --expected-abc 291628` KIT OK、与同提交默认 control
  构建仅 `ets/modules.abc` 不同；Map overlay 的 AppKey/AGC 前置与真机事件（`Ready`/`MarkerClick`/`CameraIdle`）
  仍待外部条件。
- TTS 真机验收需 HMS 设备 + harmony 壳（Kit 无 AGC 权益/权限门槛）；HUKS 打包 hap 全回合、深链系统投递、
  文本编辑 IME 节拍、动画减少动效开关、列表/图片演示入口（#29 口径）仍未有真机回传。
- 权限弹窗 / Share 面板 / Scan 返回 / AOT（#25 口径）自 #25 起、PLAT-GAP 消费方路径（#26）与无 HMS 降级
  不抛（#27）、R2（#28）自各自批次起**仍未有真机回传**；stock kit（#22 起，含 #30）的首次设备复测仍待做
  （里程碑与判定点见 `2026-09-24-ohos-device-milestone.md` §6）。
- 批次注记：kit #30 的门禁为交互套件 **391/floor 371**（MS-MODE 批次；`ohos-workload 6cdd1fa`/`d1d7b70` 等）；
  `tester-run.sh` v12（126,658 B / `87763a3e…`，`script_version=12 (2026-09-28)`）；CI（`ohos-workload d1d7b70`）：
  interaction `36364725359` / pixel `36364725327` / host-export `36364725283` / ridgraph `36364725293` /
  markdownlint `36364725282`，sdk-ohos `a691bf11dd` ohos-install-tests `36367015490`（全 success）；
  本页所记数字 = 2026-09-28 实测（abc 281,052/20,916、导出 143、套件 391/371、tar 196,992,264/`a781c25b…`），
  重签、预签或重新打包后以 release「## Integrity」与 `.sha256` sidecar 为准。
