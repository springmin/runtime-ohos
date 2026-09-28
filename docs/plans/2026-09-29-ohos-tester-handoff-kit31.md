# 测试方交接：kit #31、Blazor WASM/ArkWeb 组件（tester-run v13 `--blazor-probe`）（2026-09-29）

> 结论先行：kit #31 = **kit #30 + Blazor WebAssembly（ArkWeb 承载）组件** ——
> ① 新增第 **6** 个 hap **`hello-blazorwasm-host-unsigned.hap`（26 MB，未签名）**：一个 ArkTS-only 宿主
> （ArkWeb `Web` 组件）把 `dotnet publish` 出的 Blazor WASM 静态站点内嵌在 `resources/rawfile/blazor`，
> `onInterceptRequest` 直供、无本地服务/无网络权限；**bundle = `com.example.opendotnet`**（与本包 MAUI
> 系列的 `com.example.hellomauiapp` **不同**），署名规则与 `com.example.mauiapp` 一节完全相同（需按你自己的
> 账号重签，`-signCode 1` 不变）。
> ② **`tester-run.sh` v13**：新增 **`--blazor-probe`** —— 安装重签后的 Blazor hap → `aa start -b
> com.example.opendotnet -a EntryAbility` → 3–5 s 后 `hilog -x | grep BlazorWebHost` 断言两条标记；
> 失败时落盘 **`blazor-hilog.txt`** 供回传。
> ③ **判读**：自动（必过）= `marker: BLZ_BOOT` + `marker: BLZ_RENDERED`；人工 = 首屏
> **“Hello from Blazor WebAssembly”** + 进 `/counter` 点击 **+1** + **截图 1 张**；`BLZ_ERROR <msg>`
> 即失败（宿主把 JS 错误转发 hilog），回传 `blazor-hilog.txt` + 截图（可附
> `bm dump -n com.example.opendotnet`）。
> ④ **门禁与指纹**：abc **281,052**/`20916`、导出契约 **143/143**、交互套件 **391/floor 371** 均承 #30
> **不变**；`verify-kit.sh` 新增 Blazor hap 分节断言（见 §1/§5）。
> ⑤ **kit #31 发布实测：数字入口见 release「## Integrity（kit #31）」**（本轮 RELEASE-VALUES 未在窗口内产出，
> tar/树/sidecar/资产 id 以 release 说明与随包 `SHA256SUMS` 为准；重签/重打包后哈希必变）。
>
> 本组件规格与交付输入见 ohos-workload `docs/blazor-arkweb-kit-handoff.md`（§3 接线清单 / §4 判读与失败采集）。
> 承接 kit #30 交接（`2026-09-28-ohos-tester-handoff-kit30.md`）：MS-MODE（runtime-mode 打包开关）/ tester-run v12 /
> MAPFIX harmony 重切的判定点**继续有效**（本文 §2 给出口径）；#29 R3（TTS / HUKS / a11y / 自绘深度）、
> #28 R2（Map 覆盖层 / LiveView / `start_app` AOT 桥 / 解释器）、#27 KIT-EXT2、#26 P2-INTEROP/TASK-MIG/PLAT-GAP、
> #25 权限链/Share/Scan/AOT 与 #24 的 JIT A/B、`probe:`×`xwe` 判定表**一字未改**。本文只覆盖 #31 的增量与判定点。

## 0. 一键执行（tester-run v13）

```sh
# 常规一轮（含 runtime_mode 键与 execmem 的 runtime-mode= 行；承 #30）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# 本轮新增：Blazor 组件探针（先按《自签说明》重签 hello-blazorwasm-host-unsigned.hap）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（JIT / XWE / 解释器 / AOT；承 #30，无需 Blazor 资产）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

## 1. kit #31 相对 #30 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1 | **第 6 个 hap：Blazor WASM/ArkWeb 组件**（`hello-blazorwasm-host-unsigned.hap`，26 MB，未签名） | 包内多一个 ArkTS-only 宿主 hap（bundle **`com.example.opendotnet`**），内嵌站点：`resources/rawfile/blazor/index.html` + `_framework/`（`.wasm` + `blazor.webassembly*.js`；`--slim`：无 `.br/.gz/.map`、无 ICU）；**只有未签名变体**，必须按《自签说明》重签（与 MAUI 未签包同一流程） | 重签 → 安装 → 启动 → 两条 `BLZ_*` 标记（§2） |
| 2 | **tester-run v13：`--blazor-probe`** | 一条命令完成「装重签 hap → 启动 `com.example.opendotnet`/`EntryAbility` → 3–5 s 采集 → 断言标记」；失败落 `blazor-hilog.txt`（`hilog -x` 原文，含 `BlazorWebHost` 与 `BLZ_ERROR` 行） | `BLZ_BOOT` + `BLZ_RENDERED` 必过；失败物 = `blazor-hilog.txt` + 截图（§2/§4） |
| 3 | **判读标记（宿主 → hilog）** | 宿主输出 `BlazorWebHost ... marker: BLZ_BOOT`（window load）与 `marker: BLZ_RENDERED`（Blazor 首帧，.NET→JS interop）；JS 异常转发为 `marker: BLZ_ERROR <msg>` | 两条标记 = 自动必过；`BLZ_ERROR` = 失败并原样回传 |
| 4 | **`verify-kit.sh` Blazor 分节**（建议断言，包内脚本为准） | 断言 `resources/rawfile/blazor/index.html` 存在、`_framework/` ≥1 个 `*.wasm` 与 `blazor.webassembly*.js`、`module.json` 的 bundle 为 `com.example.opendotnet`、无 `.br/.gz/.map` 与 `icudt*.dat`（`--slim` 生效） | `verify-kit.sh` 0 FAIL / 0 WARN（§5） |
| 5 | **门禁与指纹不变**（承 #30） | abc **281,052 B**（headless **20,916 B**）、导出契约 **143/143**、交互套件 **391/floor 371**；MS-MODE 的 `runtime-mode.txt`/优先级、MAPFIX harmony 件、R3/R2/KIT-EXT2 判定点均不动 | 校验步骤、证据字段与 #30 相同，只多 Blazor 一节与 `--blazor-probe` |

> 尺寸预算：kit #29 为 361 MB；+1 个 26 MB unsigned hap ≈ **+7%**（#31 整包数字以 release 为准）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **自动必过：两条 `BLZ_*` 标记** | ① `hap-sign-tool sign-app ... -inFile hello-blazorwasm-host-unsigned.hap -outFile hello-blazorwasm-yourself.hap`（bundle 已为 `com.example.opendotnet`，profile 需绑你的 UDID）→ ② `sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe` | `BlazorWebHost ... marker: BLZ_BOOT` 与 `marker: BLZ_RENDERED` 均出现；无 `marker: BLZ_ERROR` | `blazor/hilog-blazor.txt`（或 `blazor-hilog.txt`）+ `summary` 行 |
| **人工首屏** | 打开应用（或探针后看前台） | 首屏显示 **“Hello from Blazor WebAssembly”**，无空白/错误页/持续加载 | **截图 1 张** |
| **人工 `/counter` +1** | 点 `Counter` 链接 → 点一次 `Click me` | 进入 `/counter`，计数 0 → 1（路由/事件/interop 全通） | 截图（可与首屏同图，或第二张） |
| **失败采集（任一不满足）** | 标记缺失 / 只有 `BLZ_BOOT` 无 `BLZ_RENDERED` / `BLZ_ERROR <msg>` / 白屏 | 原样回传：`hilog -x`（含 `BlazorWebHost` 与 `BLZ_ERROR` 行）+ 截图；`bm dump` 可用时附 `bm dump -n com.example.opendotnet` | `blazor-hilog.txt` + 截图 |
| **回归：MAUI 主包与 #30 判定点** | 默认 hap 重签安装后跑常规一轮 | 与 #30 相同（`runtime-mode=jit source=manifest`、5 条冒烟、`verify-kit.sh` 全过；abc 锚 `281052`/`20916`） | 同 #30 交接 §2 |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 无法自动断言：按「人工首屏 + `/counter` + 截图」登记；自动两项标注「未测（无 hdc）」 | 截图 + 说明 |

> 一页操作卡（重签/安装/判读/失败回传，含预签路线 B）：`2026-09-29-ohos-blazor-resign-one-pager.md`。
> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**。Blazor hap 与 MAUI hap 互不依赖：
> Blazor 失败不影响主包判定，反之亦然。

## 3. Blazor 组件自签与打包要点（测试方视角）

- **自签**：bundle = `com.example.opendotnet`；新建自动签名工程时把 `AppScope/app.json5` 的 `bundleName`
  设为同名（否则属性校验失败）；`hap-sign-tool sign-app` 的 **`-signCode 1` 必须带上**（`libs/**` 的
  `SoInfoSegment` 凭据；机制见《自签说明》与 ELF 签名研究文档）。验签用同 SDK `verify-app`。
- **安装**：`hdc install hello-blazorwasm-yourself.hap`；启动 `hdc shell aa start -b com.example.opendotnet -a EntryAbility`。
- **站点内容**（交付时已内嵌，无需本地服务）：`index.html` + `_framework/`（Blazor WASM 运行时）；
  `--slim` 变体不带 `.br/.gz/.map`、无 ICU，宿主协商自然回退未压缩（功能等价）。
- **与 MAUI 包无耦合**：这是首个 ArkTS-only hap；`verify-kit.sh` 的断言按 hap 分节，新增 Blazor 一节，
  其余 hap 的断言与期望值（abc `281052`/`20916` 等）不变。

## 4. 启动路径与 JIT 判定（一字未改，承 #24–#30）

- MAUI 主包的启动相关修复不变：P17 跳过重复解压、H7 rawfile fd 直读、headless abc `13.0.1.0`、
  payload-in-libs（`libs/arm64-v8a/` 原地启动 + `.dotnet-payload.json` 校验，`dotnet.zip` 回退）、
  MS-MODE 的 runtime-mode 标记解析（file>manifest>default）。**kit #31 的 MAUI 5 hap 与 #30 同负载**
  （重建/重签只会改哈希）。
- Blazor hap 是 **ArkTS 宿主 + WASM 站点**，不加载 `libopenharmonyhost.so`、不走 hostfxr/JIT 路径：
  其判定只用 `BLZ_*` 标记与首屏，不要套 MAUI 的 `probe:`/`xwe=`/`aot=` 判据。
- 最直接的回归检查（MAUI 主包）：应用能起（`[maui] openharmony build …` 出现）、原生桥调用不抛
  `EntryPointNotFoundException`/`DllNotFoundException`、TTS/HUKS/深链探针不崩、`runtime-mode=` 行出现且不阻塞启动。

## 5. 校验与取证（与 #30 相同，只多 Blazor 一节与 `--blazor-probe`）

1. 下载/校验/重签/安装同 `快速开始.md` §1/§3；kit 内 `verify-kit.sh` 逐 hap 断言 abc **`281052`**/`20916`、
   `dotnet.zip` 254 项、`libs/arm64-v8a` 14 个 `.so` + `.dotnet-payload.json`、`resources.index` 1588/1780（≤ 2 KiB）；
   **新增** Blazor hap 的 `rawfile/blazor` 断言（§1 #4）。语义不变（FAIL → 退出码 1；WARN → 仍 `KIT OK`）。
   用 #28 的旧期望值 `264136`（或更早的 `245412`/`234620`）校验本包会 FAIL —— 那是脚本的预期行为。
   **整包数字（tar/树/sidecar/6 hap/`SHA256SUMS`）以 release「## Integrity（kit #31）」与 `.tar.gz.sha256`
   sidecar 为准**；#30 实测（tar **196,992,264 B / `a781c25b…`**、树 **`cc1ca935…`**、sidecar **`a63cd34f…`**、
   `SHA256SUMS` 15 项 / 1,309 B）仅作对照 —— #31 因新增 hap 必然变化。
2. 一条命令取证（`tester-run.sh` **v13**）：常规轮同 #30（`--kit-dir/--install/--start/--capture`）；
   Blazor 轮加 `--blazor-probe`（证据 = `BlazorWebHost` 两标记 + 失败时的 `blazor-hilog.txt`），
   人工补截图与 `/counter` 结果。模式矩阵（四态一键）与无障碍专项（`--a11y-probe`）同 #30。
3. 有 harmony flavor / HMS 的测试者请附：壳的构建出处（可直接取 `harmony-haps.tar.gz`，MAPFIX 重切件
   abc 291,628 B/`a637a513…`，仍需同指纹重签与 AGC 权益）、Map/LiveView 点亮证据、TTS/HUKS/深链证据同 #29。

## 6. 风险 / 未验证（诚实清单）

- **ArkWeb 渲染未在我的工作区验证**（无 UI/无 `hdc`）：真机首帧/Counter 交互正是本组件要闭环的两项；
  `BLZ_ERROR` 已把 JS 错误转发 hilog，便于区分「宿主 rawfile 供给/协商问题」还是「WASM/ArkWeb 能力问题」。
- `--slim` 站点不带 `.br/.gz`：传输量略增（本地 rawfile 读取无感）；如需压缩变体请取非 slim 包或注明。
- Blazor hap **只有 unsigned 变体**（我方调试 profile 绑定我方 UDID）：不重签无法安装；重签后哈希必变，
  一切数字以 release 与随包 `SHA256SUMS` 为准。
- 包内 `verify-kit.sh` 对 Blazor 一节的具体期望文本以包内脚本为准（本文按接线清单描述其语义）。
