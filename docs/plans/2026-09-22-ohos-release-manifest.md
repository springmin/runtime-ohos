# OpenHarmony .NET/MAUI 交付物清单（2026-09-28 快照）

> **本页是静态快照**（文件名为创建日期；数值于 2026-09-28 随 kit #31（Blazor WASM（ArkWeb）组件（第 6 个**未签名** hap `hello-blazorwasm-host-unsigned.hap`，bundle `com.example.opendotnet`，26,794,931 B/`36010a9c…`，210 内嵌站点文件；`--with-blazor` 配方门禁 `run-smoke.sh --require --slim` + `pack-host.sh --slim --unsigned-only`）+ `verify-kit.sh` Blazor 分节（自验 0 FAIL/0 WARN）+ `tester-run.sh` v13 `--blazor-probe`（BLZ_BOOT/BLZ_RENDERED）；门禁 host 143/143、abc 281,052/20,916、交互 391/floor 371、全 selftest（verify-kit 92 / tester-run 666）；bundle 元数据级重打包并同步三处、sdk-ohos 锚 `b2b79e27d9`）刷新；kit #30（MS-MODE 运行时模式开关（`-p:OpenHarmonyRuntimeMode=jit|aot|interp` → 包内 `libs/<abi>/runtime-mode.txt`，宿主在 hostfxr 前读取并按 file>manifest>default 记录 `runtime-mode=<v> source=…`，aot 缺库时打印显式 JIT 回退行；宿主 281,504 B/`f6b3581a…`）+ MAPFIX harmony 覆盖层真编译（静态 import 注入 + `MapOverlayNode` 基类构造修正；harmony ui abc 291,628 B/`a637a513…` 带 `entry/ets/map/MapOverlay` record 与探针符号，`harmony-haps` 资产已重切）+ `tester-run.sh` v12（读 manifest marker 到 `summary runtime_mode`，file>manifest>default，矩阵 Run C 可直接跑 stock interp hap）；交互门禁 **391/floor 371**；selftest build-arkts 165→**185**、verify-harmony 82→**102**、hap-targets 50；打包链重建宿主/targets 并重打包 bundle，历史）；kit #29 = P2c-DEEPLINK + TTS/HUKS + tester-run v11 + devloop + P0c/P1a/P1b/P2b；kit #28 = R2-SHELL-EXT + R2-3 + R2-2；kit #27 = KIT-EXT2；kit #25 = 权限链/Share+Scan 探测/AOT 启动；kit #22 = 设备里程碑回灌，kit #23 = 工具刷新，kit #24 = payload-in-libs）：只回答「截至该时点，当前交付物有哪些、数字是多少、去哪里取」。
> 所有数字在 2026-09-28 核对：本地文件重算 sha256 + GitHub release API digest 双向一致；任何重签、预签或重新打包都会改变哈希。
> kit 编号（#31）是团队跟踪口径，release 本身不带编号；以后续文档与 release 说明为准。本轮发布波含 kit 侧的 Blazor 集成提交（`ohos-workload 9a03f76`：`--with-blazor` + `verify-kit.sh` 2c + `tester-run.sh` v13 + 92/666 selftests + packaging doc）、同一树基线的 ENV-FINISH 环境加固（`ohos-workload 3dddf69`/`c3bb4cd`/`47ececc`：lib-dotnet-env + 短 TMPDIR 默认）、一笔 bundle 外锚提交（`sdk-ohos b2b79e27d9`：`versions.env` 的 workload bundle 锚 `c4647fc8` → `43a78c8f`）以及 docs agent 的 kit #31 测试方文档同步（runtime-ohos `8dbc4f1134b`/`b720ee61d86`/`f75f978a88e`/`10a0a95af9d` 系）。

## 1. 当前 kit（kit #31，`device-test-kit` release，Blazor WASM（ArkWeb）组件 + tester-run v13（abc 281,052 / 宿主导出契约 143/143 / 交互门禁 391/floor 371）：新增第 6 个**未签名** hap `hello-blazorwasm-host-unsigned.hap`（26,794,931 B / `36010a9c…`，bundle `com.example.opendotnet`；内嵌 210 文件站点），`verify-kit.sh` 增加 Blazor 分节（0 FAIL/0 WARN），`tester-run.sh` v13 增加 `--blazor-probe`；tar.gz + sidecar + tester-run.sh 于 2026-09-28 重传；bundle 元数据级重打包并同步三处、sdk-ohos 锚更新）

- 位置：`https://github.com/springmin/sdk-ohos/releases/tag/device-test-kit`（下载前缀 `https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/`）。
- `device-test-kit.tar.gz`：**207,023,588 B**，sha256 `f4325d2f789788f4ed4fb133ebecc3601107927f36276f3f9f4093e9275accb5`（kit #30：196,992,264 B / `a781c25b…`；kit #29：196,990,205 B / `e895cc0a…`；单个签名 hap 约 75.91 MB，payload 随签名 `libs/arm64-v8a/` 一起打包；本波新增 26.8 MB 未签名 Blazor 宿主 hap）。
- `device-test-kit.tar.gz.sha256` 边车（89 B）：内容 = tar.gz 哈希；边车自身 sha256 `7d0cba77c4d92fa5a17e0be8bfc044b68e07ba5eba7c49b5a630fc0634593e75`（kit #30 边车：`a63cd34f…`；kit #29 边车：`ce9f467f…`）。
- 解压内容树摘要（tree digest，绑定解压后的内容而非仅 tar 包）：`52e77ee8d0aecca535b7e3d169cc0b0815c0bbd38579984388f9cb88416af723`。
  验证：解压后在包内执行 `sh verify-kit.sh --expect-tree-digest 52e77ee8d0aecca535b7e3d169cc0b0815c0bbd38579984388f9cb88416af723`（kit #30 tree：`cc1ca935…`；#29 tree：`5b28d577…`）。
- 镜像：`workload-latest` release 上的同名资产逐字节同值（大小、sha256 相同；tree digest 同值；2026-09-28 kit #31 波次同步更新，bundle 亦同波重打包并更新）。
- 包内 tester 文档**按设计不写死哈希**：9 个文本文件（8 文档 + `签名说明.txt`）的 64-hex 计数均为 0；校验一律以 release 说明「## Integrity」小节、`.tar.gz.sha256` 边车与随包 `SHA256SUMS` 为准。包内 8 个文档已是 kit #31 同步版（含 `com.example.opendotnet` 自签条目、Blazor 验收段与 tester-run v13 的 `--blazor-probe` 判读点）。
- 本快照的本地复核：tree digest OK；`sha256sum -c SHA256SUMS` **16/16** 通过（6 hap + 9 文档 + `verify-kit.sh`）；`verify-kit.sh`（kit #31 修订版 63,301 B / `676227710b…`，新增 Blazor 分节，abc 期望 281,052/20,916）自验 **0 FAIL / 0 WARN**（锚点 + tree + 6 hap 深度断言全过，含逐 hap payload-in-libs marker（`entries=269` = libs 270 - marker）与 Blazor 2c 断言：210 站点文件 / 204 `.wasm` / bundle `com.example.opendotnet` / 站点级零压缩残留）；发布侧 API digest 与本地同哈希重算一致（含 `device-test-kit.tar.gz` 的 `f4325d2f…` 与 `tester-run.sh` 的 `2caa06bd…`）；gh-proxy 下载端到端复验：边车字节一致、tar HEAD 200/207,023,588、bundle sha 与包内断言全过（kit #31 与三处 bundle 逐字节同值）。
- kit #31 内容（全新解包实测）：5 个 MAUI hap 在本波（批末 `9a03f76`）重建，另新增第 6 个**未签名** Blazor 宿主 hap；MAUI hap 均带 `"libIsolation": true`、`bundleName=com.example.hellomauiapp` 与 **279** 个 zip 条目（24 + 254 payload + `runtime-mode.txt`）；`ets/modules.abc` = **281,052 B**、头 `13.0.1.0`（`5c06143a…`，ui/shell，与 #30 逐字节同值；harmony flavor 另证 291,628 B / `a637a513…`）；`libs/arm64-v8a/` = **270** 个文件 = 14 个 `.so`（`libopenharmonyhost.so` **285,600 B** / `de9b30dd…`（= pack **281,504 B** / `f6b3581a…` + 4,096 B 签名块；`DT_NEEDED` 仅 5 项、UND 239 且无 denylist 命中、**143/143** 托管导出契约）+ `libc++_shared.so` 与 12 个 .NET 运行时库）+ **254** 个 payload 文件 + `.dotnet-payload.json`（`entries=269`、`payloadEntries=254`、`zipEntries=254`、`zipSha256` 与回退 zip 字节一致：26.0 波段 `52c53f3a…` / 20.0 波段 `4b582fff…`）+ `runtime-mode.txt` = **jit**；`resources.index` = **1,588 B** / `db1f1bbb…`（26.0 波段）、**1,780 B** / `33227e61…`（API 20 波段）；`dotnet.zip` **254** 项且 **0** 个 `.so`（26.0 波段 16,127,712 B / 20.0 波段 16,127,701 B；与 #30 的差异仅为 demo `hello-maui-app.dll`/`.pdb` 重编译字节，内容/条目一致）；`libs/arm64-v8a/Microsoft.OpenHarmony.Hosting.dll` = **66,048 B** / `e15b5e92…`、`Microsoft.OpenHarmony.Maui.Graphics.dll` = 16,384 B / `cbcf5ca4…`（均在 payload 内，未变）；hap sha256：`hello-maui-app.hap` = 75,911,479 B / `1aba610a1f1bf7ab96c459f3252ba4ea337dc3f6de4a940a699b1162403805a5`、`hello-maui-app-permissions.hap` = 75,911,514 B / `97cb56b69c0d61883b720f9163509620a5ee513a39f57886503708b34f1f2b74`、`hello-maui-app-api20.hap` = 75,911,552 B / `e36df60f8fbe5d8cd1c9489419f29fdf7dc4b59f1e497eb1b22cc5252adf0e42`、`hello-maui-app-api20-permissions.hap` = 75,911,464 B / `28e77e06878b4183754b1d8cb0d3783a0c9bda983299a00a4b77a61321ce6a1b`、`hello-maui-app-unsigned.hap` = 73,718,252 B / `1a520fd2ab806281104e6f06ebc600a312c83f64a3eb0f89d2ad83d19d8acb62`；**第 6 个 hap `hello-blazorwasm-host-unsigned.hap`** = 26,794,931 B / `36010a9c80d226ed85ea1ca362ad31562ed4566a7b5cc49debd985da2e33ae2e`（**219** 条目；bundle **`com.example.opendotnet`**、min `18`/target `26`、`requestPermissions=1`（`ohos.permission.INTERNET`）；内嵌站点 `resources/rawfile/blazor/` **210** 文件 = `_framework` 208（**204** `.wasm` + `blazor.webassembly.js`）+ `index.html` 1,269 B；自有 ArkTS 壳 abc **16,352 B** @13.0.1.0 / `ecadbd38…`；无 `libs/`、无 `dotnet.zip`；站点级零 `.br/.gz/.map`/`icudt*.dat`，`ets/sourceMaps.map` 8,593 B 为宿主自身编译产物；**未签名，安装前必须按 自签说明.md 重签**）；两个 `*-permissions` 变体各带 5 条 `requestPermissions`（`reason` + `usedScene`），默认变体为 0 条；包内 `verify-kit.sh` = **63,301 B** / `67622771…`（新增 Blazor 分节）；`module.json` 26.0 波段 min `50002014` / target `60101024`、20.0 波段 min=target `60000020`（均未变）。
- 本版（kit #31 波次）**重打包 bundle（元数据级）**：bundle **30,570,394 B / `43a78c8f…`**（126 条目，成员集与上版一致；6 个当前 feed nupkg 的**内部文件逐字节不变**（0 changed/0 added/0 removed），仅容器元数据刷新）；Sdk pack **346,067 B** / `053427b0…`、Ref/Runtime preview.24 托管桥、BCL runtime pack（27,608,052 B）内部文件全部与 #30 同值；新 bundle 已同步三处 release 并更新 `sdk-ohos` 锚（`4d1a88e6f5..b2b79e27d9`；安装器 43/43 + 10/10 + 5/5；见 §3/§4）。
- 本版（kit #30 波次，历史）**已重打包 bundle**：Sdk pack **346,067 B**（was 343,080）携带 UI/shell abc **281,052 B** / `5c06143a…`（未变）、headless abc **20,916 B** / `54a1a201…`（未变）、宿主 **281,504 B** / `f6b3581a…`（MS-MODE 运行时模式读取；was `9c82237e…`）、`targets/OpenHarmony.Hap.targets` = **66,415 B** / `db9a5491…`（`OpenHarmonyRuntimeMode` staging target；was 58,610 / `c9ad710e…`）、`targets/OpenHarmony.PlatformItems.targets` = 4,678 B / `31e0bb8d…`（未变）、`Sdk/Sdk.targets` = 5,736 B / `fd59a681…`（未变）、`tools/Microsoft.OpenHarmony.Tasks.dll` = 32,256 B / `28c47cbf…`（未变）；`templates/ets/map/MapOverlay.ets` = **11,396 B** / `1d9871ec…`（MAPFIX 修正：`new MapOverlayNode()` + `DEFAULT_MAP_REGION`；三套 preview pack 逐字节同值）；Ref/Runtime preview.24 pack 的托管桥**未变**（`Microsoft.OpenHarmony.Hosting.dll` = 66,048 B / `e15b5e92…`、`Microsoft.OpenHarmony.Maui.Graphics.dll` = 16,384 B / `cbcf5ca4…`）；Ref.20/26 = 28,771 B、Runtime.20/26 = 36,602 B、BCL runtime pack 27,608,052 B（按设计重打包）；新 bundle **30,563,349 B / `c4647fc8…`** 已同步三处 release 并更新 `sdk-ohos` 锚（见 §3/§4）。
- kit #22 起 `签名说明.txt` 的「PA1 重建壳的下一版 kit」历史文案已随源修复（`ohos-workload c6a4cd95e`）；若手上副本仍出现该句，按历史文案处理，判读以 `签名说明` 其余内容 + release notes 为准。
- kit 编号演进（团队跟踪口径，非连续）：#7（22 日凌晨）→ #10（入口 record）→ #11（abc `13.0.1.0`）→ #12（宿主 dlopen-only + 壳 `host` 守卫）→ #14（评审整改 + PI1 + UX 深化）→ #15（rawfile 资源桥）→ #16（宿主按两个 napi 名注册）→ #17（RM1 libIsolation repack）→ #18（安全/性能第一批）→ #19（启动/TLS/评审合规）→ #20（最终热点回填 H10/P16/P9/P10/P19）→ #21（headless abc `24.0.0.0` → `13.0.1.0` 修复 + tester-run v6r2 + slice pin `236d18a9`）→ #22（设备里程碑回灌——宿主 `DT_NEEDED` 5 + 可选 API dlsym、`resources.index`（restool）、ZIP offset/mkdir、DevEco `modelVersion 6.0.2` 工程布局；tester-run v6r2）→ #23（工具刷新——强化 `verify-kit.sh` 逐 hap 深度断言 + `tester-run.sh` v7 入包）→ #24（payload-in-libs——payload 随签名 `libs/<abi>/` 原地启动 + `.dotnet-payload.json` marker、`dotnet.zip` 回退；显式 W^X=0（`xwe.txt` A/B）+ exec-memory 探针；重建 UI/headless abc；`tester-run.sh` v8）→ #25（权限链 + Share/Scan 特性探测（宿主导出契约 118/118）+ AOT 启动路径 + present 缓存 + JSON 源生成 + targets 强化；重建壳/宿主/targets/托管程序集；bundle 重打包）→ #26（P2-INTEROP 设备/kit 桥全量 source-generated LibraryImport（125 处；118/118 导出契约不变）+ TASK-MIG 打包任务编译进 `tools/Microsoft.OpenHarmony.Tasks.dll`（targets 拆分出 `PlatformItems.targets`）+ PLAT-GAP AspNetCore KFR/默认 RID/apphost 修正；重建 Hosting 桥并重打包 bundle）→ #27（KIT-EXT2 — 壳 Push/Account/Map 特性探测（ui/shell abc 245,412）+ 宿主 12 个 kit sink（导出契约 130/130）+ FIX-R1-NAPI-6D 边界加固 + FIX-R1-MARSHAL-OFF 反向入口 marshal off + payload-zip opt-out pack 同步 + 交互门禁 329/floor 309）→ #28（R2-SHELL-EXT — 壳 harmony-flavor MapComponent 覆盖层（`ets/map/MapOverlay.ets`）+ Live View 探测/桥（ui/shell abc 264,136）+ 宿主导出契约 134/134 + `start_app` 的 AOT 路由桥（`aot=1`/回退）与 `interp.txt` 解释器 pack 注入 + 交互门禁 334/floor 314）→ #29（P2c-DEEPLINK + 本批全部深度功能 — 壳侧深链/激活路由 + A2-TTS + P2a-HUKS + tester-run v11 + devloop + P0c/P1a/P1b/P2b（ui/shell abc 281,052，headless 20,916）+ 宿主导出契约 143/143 + 交互门禁 387/floor 367；重建壳/宿主/Ref-Runtime 托管桥并重打包 bundle）→ **#30（当前：MS-MODE 运行时模式开关 — `-p:OpenHarmonyRuntimeMode=jit|aot|interp` 写 `libs/<abi>/runtime-mode.txt`，aot 要求 NativeAOT 应用库并打印显式 JIT 回退，interp 叠加解释器 pack；宿主读 marker 并按 file>manifest>default 记 `runtime-mode=<v> source=…`（宿主 281,504 B）+ MAPFIX harmony 覆盖层真编译（静态 import 注入 + `MapOverlayNode` 基类构造修正；harmony abc 291,628 B / `a637a513…`，`harmony-haps` 已重切）+ tester-run v12（marker→`runtime_mode`，矩阵 Run C `run_c_via=manifest`）；交互门禁 391/floor 371；重建宿主/targets 并重打包 bundle（30,563,349 B / `c4647fc8…`））→ **#31（当前：Blazor WASM（ArkWeb）组件 — 第 6 个**未签名** hap `hello-blazorwasm-host-unsigned.hap`（bundle `com.example.opendotnet`，26,794,931 B / `36010a9c…`，219 条目，210 内嵌站点文件 = 208 `_framework`（204 `.wasm` + `blazor.webassembly.js`））；`make-device-test-kit.sh --with-blazor`（离线配方门禁 `run-smoke.sh --require --slim` + `pack-host.sh --slim --unsigned-only`）；`verify-kit.sh` 新增 Blazor 分节（selftest 72→92）；`tester-run.sh` v13 新增 `--blazor-probe`/`--blazor-hap`（`marker: BLZ_BOOT` + `marker: BLZ_RENDERED`；失败落盘 `blazor/blazor-hilog.txt` + 重签提示；selftest 634→666）；bundle 元数据级重打包（30,570,394 B / `43a78c8f…`））**。
- **kit 波次收口（2026-09-28，KIT31 `9a03f76` + ENV-FINISH `3dddf69`/`c3bb4cd`/`47ececc` + sdk-ohos `b2b79e27d9`）**：Blazor WASM（ArkWeb）组件入 kit —— `make-device-test-kit.sh --with-blazor`（离线配方门禁 `run-smoke.sh --require --slim` + `pack-host.sh --slim --unsigned-only`）产出第 6 个**未签名** hap（26,794,931 B / `36010a9c…`）；`verify-kit.sh` 2c 分节（`KIT_BLAZOR_HAP`/`KIT_BLAZOR_BUNDLE` 可覆盖）；`tester-run.sh` v13 `--blazor-probe`；selftest verify-kit 72→**92**、tester-run 634→**666**；门禁全绿（host 143/143 重建逐字节同值、build-arkts ui/headless abc 逐字节同值（281,052/20,916）、交互 391/floor 371、像素 PASS、preflight OK、全 selftest）；bundle 元数据级重打包并同步三处；sdk-ohos 锚更新（安装器 43/43+10/10+5/5，`ohos-install-tests` 36378113086 success）；CI 5/5（interaction 36379033705 / pixel 36379033801 / host-export 36379033789 / ridgraph 36379033819 / markdownlint 36379033881）。
- **kit 波次收口（2026-09-28，MS-MODE（历史）：`b30006e`/`2bb41db`/`57d8edf`/`7e41923`/`6cdd1fa` + MAPFIX `a313a02`/`569ff61`/`39998c7` + pin `d1d7b70`）**：MS-MODE 批把运行时模式开关做进三套 pack 的 `Hap.targets` 与宿主 C（`OhosHostReadRuntimeMode*`、`OhosHostLogAotFallback`），并把交互门禁推进到 **391/floor 371**（4 个 ms-mode pin）；MAPFIX 批修掉 harmony 覆盖层「复制但未编译」的根因（`Index.ets` 变量 specifier 不产生 abc record；`MapOverlay.ets:135` 把 UIContext 传给 NodeController 隐式无参基类构造 10505001），并以 `HARMONY_REQUIRE_MAP_OVERLAY=1` + 符号断言把 gate 从 WARN 翻成 FAIL；pin 提交 `d1d7b70` 把 ridgraph-sync 的 sdk-ohos pin 从 `82dc57c64c` 推进到 `6c86e2d13b`（图字节不变，`6e4137cc…`）。CI：批末 `6cdd1fa` 5/5 success（interaction 36357605608 / pixel 36357605602 / host-export 36357605604 / ridgraph 36357605624 / markdownlint 36357605605），pin 提交 `d1d7b70` 5/5 success（interaction 36364725359 / pixel 36364725327 / host-export 36364725283 / ridgraph 36364725293 / markdownlint 36364725282）。本轮**未**重跑 `prepare-packs`（托管桥源未变，宿主与 targets 由 pack 同步进入安装后的 packs）。
- **kit 波次收口（2026-09-28，`bd14599` + `ff9c348` + `sdk-ohos 82dc57c64c`，历史）**：`bd14599` 把包内 verify-kit 的 abc 期望重锚到 281,052/20,916 并同步内嵌 host-deps 的 `OH_DecodingOptions_`；`ff9c348` 把 ridgraph-sync 的 sdk-ohos pin 推进到 `82dc57c64c`；`sdk-ohos 82dc57c64c` 把 `versions.env` 的 bundle 锚更新到 `c2b527d3…`；`ohos-install-tests` run 36340451030 success。
- release 最后更新 2026-09-28（kit #31 资产；tar.gz + sidecar + `tester-run.sh` v13 已重传，bundle 已重打包并同步三处 release）；`2026-09-21-ohos-final-status.md` 已同步到 kit #31（docs agent b720ee61d86 系）并指向 `2026-09-24-ohos-device-milestone.md`，本页与之一致锚定当前 release。

## 2. `device-test-kit` release 上的全部资产（2026-09-28 快照，24 项）

| 资产 | 大小 (B) | sha256 | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz` | 207,023,588 | `f4325d2f789788f4ed4fb133ebecc3601107927f36276f3f9f4093e9275accb5` | 当前 kit #31（Blazor WASM（ArkWeb）组件 + tester-run v13；ui/shell abc 281,052；宿主导出契约 143/143；交互门禁 391/floor 371；`tester-run.sh` v13 随附） |
| `device-test-kit.tar.gz.sha256` | 89 | `7d0cba77c4d92fa5a17e0be8bfc044b68e07ba5eba7c49b5a630fc0634593e75` | 整包边车（内容 = 上一行哈希） |
| `dynpkg-haps.tar.gz` | 115,317,981 | `1212d53de6afd8266ab36ac08c5aac5f5fffed662008a4e35e437ffaf19e7650` | 候选载荷（fallback #3）：动态加载 + 包声明；libIsolation + abc host-binding record + 已确认入口形式 |
| `normalized-haps.tar.gz` | 115,234,685 | `89ee8fa6d8fce27512921d75cecca27bd3f25babd962c133b22817168e86fdbc` | 候选载荷（C）：`useNormalizedOHMUrl=true` + `pkgContextInfo.json` |
| `importb-haps.tar.gz` | 115,228,059 | `605e34cde42ef25dd7afb3f70a78c6d3d39ce97d5303b2ead421a9f1c0d8a1bd` | 命名空间静态 import 壳的 5 hap（A1/探针 B 载荷） |
| `importd-haps.tar.gz` | 230,454,182 | `892af75756e296b5dabb7d690c4607274a319678b72d20a56232df69275b0dd6` | 动态加载 D1（`openharmonyhost`）/D2（`libopenharmonyhost.so`）各 5 hap |
| `hello-mauiapp-importprobe-a-unsigned.hap` | 1,479,264 | `c4871259515fdee7afdacf5d9442f7fe3ad50583703e4c8f2510d9ec41ffb1ca` | 探针 A：静态 `default` import 对照 |
| `hello-mauiapp-importprobe-b-unsigned.hap` | 1,479,272 | `7014f32ae4b27a9bfd15bef1226bc3ee90e4ed8c114976388938fecc50c3ed98` | 探针 B：命名空间 import（NAMESPACE_IMPORT） |
| `hello-mauiapp-importprobe-c-unsigned.hap` | 1,479,656 | `7a2ecb186d4b922cab7dea17ae16bbb32570fdafe64be2a25fffcecb9c9543c1` | 探针 C：动态 `loadNativeModule` |
| `hello-mauiapp-probe1-unsigned.hap` | 12,004 | `bec893c2ea6120b360b45e5b7a61593d5799b0702d31856afaeba1f724c0a951` | P1：纯 ArkTS 壳侧 |
| `hello-mauiapp-probe2-unsigned.hap` | 215,384 | `5bdce033d00a561dc22dd4196a4f17aa2e5d6df025682adbe98c30836f6c1960` | P2：宿主 dlopen |
| `hello-mauiapp-probe3-unsigned.hap` | 222,954 | `43557cfe9c274406ad8cc4985eadace9eb4a7f13d560af2e452491727a5e5b6c` | P3：宿主入口/dlsym |
| `hello-mauiapp-probe4-unsigned.hap` | 223,178 | `d24d26cd168ee34ea6c6352e80d25a556a096765b0f95d163203b8789e3f8d63` | P4：逐依赖预检 |
| `new-features-device-checklist.md` | 52,580 | `8d30542087d70eac1d51bdc41bf00962e6cab95dec0a0014554de088188c6c54` | 本轮新功能 M1–M13 真机清单（2026-09-24 与仓库文档同步重传，kit #22 口径）|
| `tester-run.sh` | 137,113 | `2caa06bd5fd472c04631311222a94c81e47ea8b3edf7b85ade41b583053f52dc` | **v13**（内嵌 `SCRIPT_VERSION="13 (2026-09-28)"`）：v8 全部能力（校验 + 安装 + 启动 + 30 s hilog + RM1 无重建 app-lib/dlopen 证据、bootstrap/rawfile 失败特征、payload 状态与逐 hap kit 自检、exec-memory 证据、bundle 名校验 A1、kit 摘要 P16）+ v9 AOT/解释器路由证据（`aot=`/`interp=`）+ v10 一键 runtime-mode 矩阵（A/B/C/D）+ v11 `--a11y-probe` + v12 读 hap 内 `libs/<abi>/runtime-mode.txt` 到 `summary runtime_mode`（`jit|aot|interp(hap)`、`invalid(<v>)`、`<absent>`；设备日志优先 file>manifest>default，无行时以 packed marker 填 `3(manifest)`/`1(manifest)`；矩阵 Run C 在 marker=interp 时可直接跑 stock hap：`run_c_via=manifest`）。**2026-09-28 重传 v13（asset 594519342；新增 `--blazor-probe`/`--blazor-hap`/`--blazor-bundle`，其余 v12 能力不变）**（与仓库逐字节一致） |
| `aot-haps-README.md` | 4,092 | `46ef70b1ecbd670681c44dfc6ecf1424f005f64edd1f2a66c97a76e75d2b18d6` | AOT hap 资产说明（AOT-RECUT 2026-09-27：已内置桥宿主 `bb51826e…`，开箱 `aot=1`） |
| `aot-haps.tar.gz` | 17,093,146 | `91e1b9d3d66bb69c1797627aac7553c29f7de29ea25874a0ac45505470fa490d` | MAUI NativeAOT hap 变体（另有资产，不在 kit 内；AOT-RECUT：宿主含 `start_app` AOT 桥） |
| `aot-haps.tar.gz.sha256` | 82 | `a4e2c74f6eac0e0c07dd720ca487f1ada56e97be80d6320d4492e5badbb8257e` | AOT hap 边车（内容 = AOT tar 的 sha256） |
| `harmony-haps-README.md` | 9,071 | `4cd711df15ff1a868e00493db1f28f3be961a925dd2fbea347a428fb0aaaacee` | harmony-flavor（HMS Kit）hap 资产说明（MAPFIX 2026-09-28 重切：overlay 真编译，abc 291,628 B/`a637a513…`、逐 hap 断言 102/102） |
| `harmony-haps.tar.gz` | 196,898,796 | `9b0506faad357ccdabc92ec505ab1086a47d39e3de3211005211ecb48f1a8eba` | harmony-flavor hap 变体（另有资产，不在 kit 内；MAPFIX 重切，abc 291,628/`a637a513…`，带 `entry/ets/map/MapOverlay` record） |
| `harmony-haps.tar.gz.sha256` | 86 | `c0b866455e129a2439123b646c8e53481fb8cce52825c383740930046d56f9b1` | harmony hap 边车（内容 = harmony tar 的 sha256 `9b0506fa…`） |
| `ohos-interpreter-pack-README.md` | 3,324 | `44c4fc78b3ef3961c98da167acdb7d9938f7125648700ba2efc8d2080347314f` | 解释器 pack 说明（R2-INTERP-FULL，独立于本 kit；kit #30 波次未动） |
| `ohos-interpreter-pack.tar.gz` | 2,419,988 | `a10699b3da9c26602556ce141375644d61541bfdfe7d3eceff2de52aa113f873` | 解释器 pack（另有资产；`interp.txt` 开关由宿主消费，不在 kit 内；kit #30 波次未动） |
| `ohos-interpreter-pack.tar.gz.sha256` | 95 | `4eb569cbe3551d856fec10bc9d852e9d45de337b076cf2dd3e75d5fcb378424b` | 解释器 pack 边车（未动） |

- 诊断资产对应关系：`dynpkg-haps.tar.gz` 为候选矩阵中最强单候选（动态加载 + `runtimeOnly.packages`/`file:` 包声明；随包 5 hap 带 libIsolation、abc 新增 host-binding `.record libopenharmonyhost.so`、入口 record 保持已确认形式）；`normalized-haps.tar.gz` 的 normalized 入口 record 的设备解析未证。`importb`/`importd` 分别对应静态命名空间与动态加载实验；三个 `importprobe` hap 无 .NET 载荷，只测三种 import 形式的路由。P1–P4 仍用于 dlopen/缺库/宿主入口/运行时类崩溃的五层定位。
- 全部数字均为 2026-09-28 读取：release API digest 与本地重算一致（kit、bundle、dynpkg、normalized、importb、importd、tester-run.sh、AOT/harmony hap、解释器 pack）；本轮 kit #31 变化 **3 项**：`device-test-kit.tar.gz`、`.sha256` 边车与 `tester-run.sh`（v13 重传）；其余 **21 项**（探针 hap、诊断 tarball、dynpkg/importb/importd/normalized、`checklist`、AOT hap 3 项、harmony hap 3 项、解释器 pack 3 项）与上一快照逐字节同值；`workload-latest` 上同步镜像是 `device-test-kit.tar.gz` + `.sha256` **2 项**，且本轮 bundle + `SHA256SUMS` 亦重传（4 项全变）；`workload-1.0.0-preview.24` 变化 2 项（bundle + `SHA256SUMS`）；SDK release 变化 2 项（bundle + `SHA256SUMS`，合并 sums 仍为两行 212 B / `a7026779…`），其余 33 项零变化。`importprobe` a/b/c 的 API digest 与实验文档记录一致。诊断 tarball 内的 hap 均未签名或为陈旧签名，测试方需重签（§6）。**MAPFIX 重切（2026-09-28，同日早于 kit #30 读取）**：release 392356147 仅 **harmony 3 项**被显式 clobber 替换（旧 id 592540230/592541627/592540464 → 新 593867614/593868367/593867941，size/digest 见上表；旧件 overlay 未编译），其余 **21 项** id/size/digest 零改动（before/after release API 快照 diff）。

## 3. Workload bundle（versioned + rolling + SDK release）

| 资产 | 大小 (B) | sha256 | 位置 |
|---|---|---|---|
| `openharmony-workload-1.0.0-preview.24.tar.gz` | 30,570,394 | `43a78c8ff78931a43a46eca6aecf577b31e85b25d163c9ce467d4c6477cdfb90` | `workload-1.0.0-preview.24` / `workload-latest` release |
| `openharmony-workload-latest.tar.gz` | 30,570,394 | `43a78c8ff78931a43a46eca6aecf577b31e85b25d163c9ce467d4c6477cdfb90` | `workload-latest` release（与 versioned 逐字节一致） |

- 两名字指向同一份字节；`SHA256SUMS`（212 B，自身 sha256 `a702677985df1f1e74965d9a26bb35f1d7b4607c8259c1bf97f9f0d8c1639730`，kit #30 为 `145928a5…`）同时列出上述两条，与本地 `dist/SHA256SUMS` 重算一致；`sha256sum -c` 2/2 通过（gh-proxy 抽验目录内）。
- **FIX-RESID 重打包（2026-09-23T17:16+08:00，历史）**：旧 bundle 30,477,923 B / `6d8c4480…` 内的 preview.24 平台包还是修复前托管；该次重打包后 Ref.20.0/26.0 与 Runtime.20.0/26.0 均为 34,816 B / `d776b1d5…`，另含重建的 `Microsoft.OpenHarmony.Maui.Graphics.dll`（16,384 B / `6b5de857…`）。此后各版依次为：kit #19 = 30,482,709 B / `5e84fe21…`；kit #20 = 30,499,901 B / `ba43c2e8…`；kit #21 = 30,498,612 B / `41d94901…`。
- **kit #21 重打包（2026-09-24，历史）**：bundle 30,498,612 B / `41d94901…`（130 条目）修复 headless 变体 abc（`24.0.0.0` 3,580 B → `13.0.1.0` **13,572 B** / `70a61636…`）并让 pack 模板 README 指向 `ARKTS_SHELL_VARIANT=headless`。
- **kit #22 重打包（2026-09-24，历史）**：bundle 30,498,838 B / `04b96cec…`（130 条目）——原生宿主按需 dlopen/dlsym 重建（**215,968 B / `3332c8ac…`**，DT_NEEDED 收窄为 5）；UI/shell abc **212,952 B / `6e616f5b…`** 与 headless **15,608 B / `c72990c1…`** 按 DevEco 布局重建；Sdk pack `targets/OpenHarmony.Hap.targets` = **46,213 B / `e4318436…`**。
- **kit #23 波次（2026-09-24，历史）**：bundle 与 #22 **逐字节相同**（`04b96cec…` / 30,498,838 B），该波**未重发 bundle、未更新 `sdk-ohos` 锚**。
- **kit #24 重打包（2026-09-24，历史）**：bundle **30,524,164 B / `d28578e2…`**（130 条目；6 个 feed nupkg 变化）：Sdk pack **344,301 B** 携带 payload-in-libs `Hap.targets` = **57,438 B / `fcf54c97…`**、UI/shell abc **215,680 B / `0def57e0…`**、headless abc **18,308 B / `25ab7a9e…`**、宿主 **220,064 B / `19d9d4b4…`**。
- **kit #25 重打包（2026-09-25，历史）**：bundle **30,487,575 B / `6c607c73…`**（130 条目）：Sdk pack **284,047 B** 携带 UI/shell abc **234,620 B / `34325332…`**、headless abc **18,532 B / `d7ec9ca7…`**、`Hap.targets` = **94,123 B / `4b2a10be…`**、宿主 **236,448 B / `8fa24895…`**。
- **kit #26 重打包（2026-09-26，历史）**：bundle **30,501,359 B / `7b9ccd6e…`**（130 条目）：Sdk pack **290,854 B** 新增 `tools/Microsoft.OpenHarmony.Tasks.dll` = **32,256 B / `28c47cbf…`**，`Hap.targets` = **55,473 B / `2f2c234c…`**，新增 `PlatformItems.targets` = **3,918 B / `70ac714b…`**，`Sdk/Sdk.targets` = **5,736 B / `fd59a681…`**；hosting 55,808 B / `38f5a3d2…`。
- **kit #27 重打包（2026-09-26，历史）**：bundle **30,508,149 B / `bc30c65b…`**（130 条目）：Sdk pack **305,204 B** 携带 UI/shell abc **245,412 B / `0e31b619…`**、`Hap.targets` = **57,750 B / `390ea180…`**；hosting 55,296 B / `4c121725…`、graphics 16,384 B / `01a09b32…`。
- **kit #28 重打包（2026-09-26，历史）**：bundle **30,525,614 B / `7d614517…`**（130 条目）：Sdk pack **322,441 B** 携带 UI/shell abc **264,136 B / `9020ec5e…`**、`PlatformItems.targets` = **4,678 B / `31e0bb8d…`**；宿主 = **265,120 B / `30addfbe…`**（134/134 导出契约）。
- **kit #29 重打包（2026-09-28，历史）**：bundle **30,552,107 B / `c2b527d3…`**（130 条目；6 个 feed nupkg 按设计变化）：Sdk pack **343,080 B** 携带 UI/shell abc **281,052 B / `5c06143a…`**、headless abc **20,916 B / `54a1a201…`**、`Hap.targets` = **58,610 B / `c9ad710e…`**、宿主 **281,504 B / `9c82237e…`**（143/143 导出契约）；Ref/Runtime preview.24 的托管桥补跑 `prepare-packs.sh` 重建（hosting **66,048 B / `e15b5e92…`**、graphics **16,384 B / `cbcf5ca4…`**）；Ref.20/26 `28,771 B`、Runtime.20/26 `36,602 B`。
- **kit #30 重打包（2026-09-28，本轮）**：bundle **30,563,349 B / `c4647fc8…`**（130 条目，成员集与上版一致；6 个 feed nupkg 按设计变化）：Sdk pack **346,067 B**（was 343,080）携带 `Hap.targets` = **66,415 B / `db9a5491…`**（MS-MODE `OpenHarmonyRuntimeMode` staging target；was 58,610 / `c9ad710e…`）、`MapOverlay.ets` = **11,396 B / `1d9871ec…`**（MAPFIX 修正版：`new MapOverlayNode()` + `DEFAULT_MAP_REGION`；was 9,736 B / `3e658063…`，overlay 复制但未进编译图）、宿主 **281,504 B / `f6b3581a…`**（MS-MODE 运行时模式读取；was 281,504 / `9c82237e…`，同尺寸异哈希）、UI/shell abc 281,052 / `5c06143a…`、headless abc 20,916 / `54a1a201…`（均未变）、`PlatformItems.targets` 4,678 / `31e0bb8d…`、`Sdk.targets` 5,736 / `fd59a681…`、`tools/Microsoft.OpenHarmony.Tasks.dll` 32,256 / `28c47cbf…`（均未变）；Ref/Runtime preview.24 托管桥**未变**（hosting 66,048 / `e15b5e92…`、graphics 16,384 / `cbcf5ca4…`）；Ref.20/26 `28,771 B`、Runtime.20/26 `36,602 B`；BCL runtime pack 重打包同尺寸（27,608,052 B / `8e2033d7…`）。发布后经 API（by-id）与 gh-proxy 下载抽验：三处（`workload-latest`、`workload-1.0.0-preview.24`、SDK release）新 bundle 逐字节一致，`sha256sum -c` 通过；包内断言含 abc 281,052/20,916、宿主 281,504/`f6b3581a`、`Hap.targets` 的 runtime-mode 开关与 `runtime-mode.txt`、overlay 模板修正（`new MapOverlayNode()` + `DEFAULT_MAP_REGION`）、深链 `notifyActivation`（ui+headless abc）、TTS（`HmsCoreSpeechKit`/`probeTtsKit`）、LiveView、Map 与 HUKS keystore 导出；`sdk-ohos` 锚已更新并推送（见 §4）。
- SDK release `v11.0.100-rc.1.26451.109-openharmony`（id **388357742**）：`https://github.com/springmin/sdk-ohos/releases/tag/v11.0.100-rc.1.26451.109-openharmony`；其上随 SDK 发布附带的 workload bundle 已同步为 kit #31 重打包（**30,570,394 B / `43a78c8f…`**，`SHA256SUMS` **212 B / `a7026779…`**（两行，与 `workload-latest`/`preview.24` 同值）；变更资产 = bundle + `SHA256SUMS`，其余 33 项不变；SDKREL-31，2026-09-28）。SDK 包 `dotnet-sdk-11.0.100-rc.1.26451.109-openharmony-arm64.tar.gz` = 178,005,544 B / sha256 `f3a1bba4…`、runtime `10b7877f…`、selfsign `85284499…` 三锚逐字节不变；`sdk-ohos` 外锚已更新并推送（`4d1a88e6f5..b2b79e27d9`，`versions.env`，`WORKLOAD_BUNDLE_SHA256 = 43a78c8f…`；安装器测试 43/43 + hostfeed 10/10 + codesign 5/5（`ohos-install-tests` run 36378113086 success））。

## 4. 五仓库分支 tip（2026-09-28 终检快照，远端分支 tip；已按 fetch/API 与远端 ref 核对）

| 仓库 | 分支 | 短哈希 | 备注 |
|---|---|---|---|
| `ohos-workload` | `master` | `9a03f76` | kit #31 发布链：Blazor WASM（ArkWeb）组件 + `tester-run.sh` v13（提交 `9a03f76`；同树基线 ENV-FINISH `3dddf69`/`c3bb4cd`/`47ececc`）；preflight 全绿（391/floor 371 + pixel + 全 selftest），CI 5/5 success（interaction 36379033705 / pixel 36379033801 / host-export 36379033789 / ridgraph 36379033819 / markdownlint 36379033881） |
| `maui-ohos` | `feature/openharmony` | `4b5756de` | MAUI 平台切片（P2c 深链/激活路由，含 P2b/P1b/P1a/P0c/P2a-HUKS/A2-TTS 批次；CI 三 workflow pin 同值，本轮未推进）|
| `sdk-ohos` | `feature/openharmony` | `b2b79e27d9` | SDK 与 release 宿主（bundle 外锚更新并推送 `4d1a88e6f5..b2b79e27d9`，`WORKLOAD_BUNDLE_SHA256 = 43a78c8f…`；安装器 43/43 + hostfeed 10/10 + codesign 5/5；`ohos-install-tests` run 36378113086 success）|
| `runtime-ohos` | `feature/openharmony` | `10a0a95af9d` | 本页 kit #31 刷新提交前的 tip（docs agent 的 kit #31 文档同步/Blazor 一页纸/终端验证快照；本次 manifest 提交会再前进一格）|
| `aspnetcore-ohos` | `feature/openharmony` | `07ed2fe38d` | aspnetcore 移植（upstream/main 合并批次）|

## 5. 怎么校验（三步）与 tester-run.sh 一条命令

三步（手工路径）：

```sh
base=https://github.com/springmin/sdk-ohos/releases/download/device-test-kit
curl -L -O "$base/device-test-kit.tar.gz" -O "$base/device-test-kit.tar.gz.sha256"
sha256sum -c device-test-kit.tar.gz.sha256          # ① 整包锚定
tar xzf device-test-kit.tar.gz && cd device-test-kit
sha256sum -c SHA256SUMS                             # ② 包内 16/16（verify-kit 另做逐 hap 深度断言）
sh verify-kit.sh --expect-tree-digest 52e77ee8d0aecca535b7e3d169cc0b0815c0bbd38579984388f9cb88416af723   # ③ 内容树绑定
```

一条命令（校验 + 安装 + 启动 + 录 30 秒 hilog，`tester-run.sh` v13 默认 dry-run，无设备不动作；需 `hdc`，多设备加 `--device <id>`；v13 在 v8–v12 的全部能力之上新增 `--blazor-probe`/`--blazor-hap`/`--blazor-bundle`（安装重签后的第 6 个 hap → `aa start -b com.example.opendotnet -a EntryAbility` → 4 s → `hilog -x` → 断言 `marker: BLZ_BOOT` + `marker: BLZ_RENDERED`；失败落盘 `blazor/blazor-hilog.txt` 并给重签提示），v12 的 `runtime_mode`/矩阵能力不变：

```sh
sh tester-run.sh --kit-tar ./device-test-kit.tar.gz \
  --expect-tree-digest 52e77ee8d0aecca535b7e3d169cc0b0815c0bbd38579984388f9cb88416af723 \
  --install --start --capture 30
```

## 6. 测试方两条签名路径（安装报 `9568344` 时二选一）

| 路径 | 测试方提供 | 交付方执行 |
|---|---|---|
| ① 重签（按你的 UDID） | `hdc shell bm get -u` 的 UDID（或按包内 `自签说明.md` 用 DevEco 自动签名自行完成） | `sh scripts/sign-for-device.sh <UDID>`（多设备逗号分隔） |
| ② 外部预签（用你的材料） | p7b + p12 + cer + keyAlias（华为材料亦可） | `sh scripts/sign-for-device.sh --external --profile <p7b> --key <p12> --cert <cer> --key-alias <alias> --pwd-input-mode --expect-udid 60CF7B27…`（UDID 换成目标设备；p7b 的 `debug-info.device-ids` 必须含它，fail closed）；华为材料可走 `scripts/sign-huawei.sh` |

根因：hap 内调试 profile 的 `debug-info.device-ids` 只含示例 UDID；重签/预签后哈希必变，以新产物随附的 `SHA256SUMS` 为准。kit #30 的 4 个已签 hap 为自签名（默认 `-signCode 1` 会重签 `libs/<abi>/*.so`），诊断 tarball 内的 hap 为陈旧签名或未签名，均需按 §5/自签说明重签。详见 `2026-09-19-ohos-signing-and-udid-guide.md`。

## 7. SDK 门控清单（快速参考，详见覆盖矩阵 §4）

- TextToSpeech — 本 SDK 无 `@kit.CoreSpeechKit` / `@ohos.ai.tts`（kit #29 起壳侧 probe 与宿主 `tts` 桥已就位，sink 在缺失时如实返回不可用）。
- Map — 本 SDK 无 MapKit；kit #28 的 harmony-flavor 壳以 MapComponent 覆盖层接入 HMS，默认 OpenHarmony flavor 按 capability bit 0 降级。**MAPFIX（2026-09-28）后 harmony ui abc 真带 `entry/ets/map/MapOverlay` record 与 `mapOverlayView/markerClick/cameraIdle` 符号**（`Index.ets` 静态 import 注入 + `MapOverlayNode` 基类构造修正）；真机点亮仍需 AGC Map 服务与同指纹重签（外部依赖）。
- Live View — 本 SDK 无 `@kit.LiveViewKit`（harmony-flavor 壳侧探测；缺失时 sink 如实返回不可用）。
- 系统分享面板 / 多文件分享 — 无 Share Kit，一个 Want 仅单个 uri 槽（文本 + 单文件可用，多文件 no-op）；kit #25 起宿主对 Share/Scan Kit 做特性探测并在缺失时降级。
- BLE GATT client — `connection.GattClientDevice` 未导出（经典蓝牙发现可用）。
- Hot Reload — hdc 策略硬阻塞。
- arm32 — 无 runtime packs、无 32 位设备。

## 8. 接下来读什么

| 文档 | 用途 |
|---|---|
| `2026-09-29-ohos-tester-handoff-kit31.md` | **本批测试方交接页**：Blazor WASM/ArkWeb 组件（第 6 个未签名 hap、bundle `com.example.opendotnet`、重签流程与 `BLZ_*` 判读）、`tester-run.sh` v13 `--blazor-probe` 与失败采集、承 #30 的回归判定点 |
| `2026-09-29-ohos-blazor-resign-one-pager.md` | Blazor 组件重签与验收一页纸（kit #31） |
| `2026-09-29-ohos-terminal-verification-kit31.md` | kit #31 终端复核快照（五仓库/发布 feed/kit 探针/CI；门禁/kit/bundle 数值以本页与 release `## Integrity` 为准） |
| `2026-09-28-ohos-tester-handoff-kit30.md` | 上一批测试方交接页（MS-MODE 运行时模式开关/宿主 marker 判读、tester-run v12 的 `runtime_mode` 与矩阵 Run C、MAPFIX harmony 覆盖层与重签要求、判读点与未验证项 |
| `2026-09-28-ohos-terminal-verification.md` | kit #30 终端复核快照（门禁/kit/bundle 数值以本页与 release `## Integrity` 为准） |
| `2026-09-24-ohos-device-milestone.md` | **真机里程碑**：kit #17→#18 + 测试方 5 项本地修复后首次完整运行（设备/证据/根因链 5 项/回灌映射/kit #22 指纹/仍未验证/复测建议） |
| `2026-09-24-ohos-kit-gap-analysis.md` | HarmonyOS SDK 与 kit 能力缺口重盘点（KIT-GAP；含 Share/Scan 切片落地与可行性结论，kit #25 据此加特性探测） |
| `2026-09-22-ohos-startup-crash-rootcause.md` | 启动崩溃根因 §5b/§5c（kit #10–#12）与 kit #14 里程碑/黑屏阻塞 §5d/§5e；**§5f = 2026-09-24 设备证据修正** |
| `2026-09-23-ohos-napi-import-fix-playbook.md` | 黑屏阻塞 #4 的候选修复 A/B/C、决策表与回滚（设备证据修正后降级为备用） |
| `2026-09-23-ohos-native-import-experiment.md` | importprobe a/b/c 三形式实验 + RM1 lib-isolation 修复与无重建诊断（降级为无害加固） |
| `2026-09-21-ohos-crash-probes.md` | P1–P4 启动崩溃探针与五层定位决策表（kit #22 复测的失败分支入口） |
| `2026-09-21-ohos-device-crash-diagnostics.md` | 崩溃最小取证（hilog/faultlog/status）与 A/B 清单 |
| `2026-09-21-ohos-device-report-template.md` | 真机回传一页模板（机器可解析） |
| `2026-09-22-ohos-new-features-device-checklist.md` | 本轮新功能真机验证清单（即 release 上的 `new-features-device-checklist.md`；kit #30 口径已同步） |
| `2026-09-22-ohos-maui-coverage-matrix.md` | MAUI 覆盖矩阵与 SDK 阻塞/Top-10 缺口 |
| `2026-09-21-ohos-security-scan.md` | 五仓库安全扫描（第一轮；PASS WITH FINDINGS，23 项已处置） |
| `2026-09-23-ohos-security-scan-2.md` | 五仓库安全扫描 #2（16 条候选，16 修；kit #21/#22 已含全部修复提交；#19–#22 追加 headless abc、bundle 外锚、TLS H-C3、设备回灌等） |
| `2026-09-23-ohos-performance-scan.md` | 五仓库性能扫描（31 热点，29 修 + 2 项有意保留；kit #21/#22 已含已修项） |
| `2026-09-23-ohos-pr-review-compliance.md` | 上游 PR 评审规则遵循（R1–R11、硬违例 0、修复提交与复审计证据） |
| `2026-09-25-ohos-ms-hmos-compliance.md` | 四域技能合规报告（kit #25 波次查证） |
| `2026-09-23-ohos-upstream-reply-drafts.md` | 未发送的上游回复/催评草稿（#132953、#132827、#132866；arcade#17608 一条已随其合并作废），等审批 |
| `2026-09-23-ohos-tls-policy.md` | TLS 加固策略（H-C3 绝对路径 `dlopen` + 静态链接开关）与设备负向验证 |
| `2026-09-21-ohos-final-status.md` | 一页版最终状态（交付主线、批次、真机待证项；已同步 kit #31） |
| `README.md` | `docs/plans` 文档索引（本目录入口） |
