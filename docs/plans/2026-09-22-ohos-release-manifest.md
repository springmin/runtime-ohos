# OpenHarmony .NET/MAUI 交付物清单（2026-09-26 快照）

> **本页是静态快照**（文件名为创建日期；数值于 2026-09-26 随 kit #28（R2-SHELL-EXT + R2-3 + R2-2：壳侧 harmony-flavor 落地 MapComponent 覆盖层（`ets/map/MapOverlay.ets`；默认 OpenHarmony flavor 动态 import 失败并按文档降级为 capability bit 0）与 Live View Kit 探测/桥（`registerLiveViewSink`/`notifyLiveViewResult`）；宿主导出契约 118/118 → **134/134**（Map overlay command 复用既有 Map sink + 4 个 LiveView sink）；`start_app` 桥接 AOT 路由（`aot=1`，缺入口回退 `aot=0`）与 `interp.txt` 解释器 pack 注入；ui/shell abc 245,412 → **264,136**（三套 preview pack 同源）；交互门禁 **334/floor 314**；发布波另含 maui pin `a0a2c087` → `63d13d15` 与 ridgraph-sync sdk pin 推进）刷新；kit #27 = KIT-EXT2（Push/Account/Map 特性探测 + 12 kit sink（130/130）+ FIX-R1-NAPI-6D + FIX-R1-MARSHAL-OFF）；kit #25 = 权限链/Share+Scan 探测/AOT 启动路径/导出契约 118/118；kit #22 = 设备里程碑回灌（宿主按需 dlsym + `resources.index` + ZIP/mkdir + DevEco 工程布局），kit #23 = 工具刷新，kit #24 = payload-in-libs）：只回答「截至该时点，当前交付物有哪些、数字是多少、去哪里取」。
> 所有数字在 2026-09-26 核对：本地文件重算 sha256 + GitHub release API digest 双向一致；任何重签、预签或重新打包都会改变哈希。
> kit 编号（#28）是团队跟踪口径，release 本身不带编号；以后续文档与 release 说明为准。本轮发布波含两笔收口提交（`ohos-workload dfbe2a6`：CI 的 maui pin `a0a2c087` → `63d13d15` + ridgraph-sync sdk pin `f27b20f4cc` → `3eb480fb4b`；`sdk-ohos 93350abcae`：`versions.env` 的 workload bundle 锚 `bc30c65b` → `7d614517`）。

## 1. 当前 kit（kit #28，`device-test-kit` release，R2-SHELL-EXT：Map 覆盖层 + LiveView 探测/桥 + AOT `start_app` 桥 + `interp.txt`（abc 264,136）/ 宿主导出契约 134/134 / 交互门禁 334/floor 314：重建壳与新 bundle；`tester-run.sh` v8 随附（本轮未变，未重传）；tar.gz + sidecar 于 2026-09-26 重传）

- 位置：`https://github.com/springmin/sdk-ohos/releases/tag/device-test-kit`（下载前缀 `https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/`）。
- `device-test-kit.tar.gz`：**196,220,486 B**，sha256 `091dcc562a6da00ab2a5d9c13025f3479790bdb22b13061702755b715bc3267c`（kit #27：195,951,029 B / `74211b6e…`；kit #26：195,748,984 B / `c8b13e56…`；单个签名 hap 仍约 75.67 MB，payload 随签名 `libs/arm64-v8a/` 一起打包）。
- `device-test-kit.tar.gz.sha256` 边车（89 B）：内容 = tar.gz 哈希；边车自身 sha256 `d7efd251a2ee281ae222522e4a20acf6cb2480aacecb134804a840ba06fded25`（kit #27 边车：`cc26f830…`）。
- 解压内容树摘要（tree digest，绑定解压后的内容而非仅 tar 包）：`0a7a3215cfd66b1e89a69e7bd89ec7b8881a8819d4557de607db55e2828c2231`。
  验证：解压后在包内执行 `sh verify-kit.sh --expect-tree-digest 0a7a3215cfd66b1e89a69e7bd89ec7b8881a8819d4557de607db55e2828c2231`（kit #27 tree：`6abff90e…`；#26 tree：`2f247e40…`）。
- 镜像：`workload-latest` release 上的同名资产逐字节同值（大小、sha256 相同；tree digest 同值；2026-09-26 kit #28 波次同步更新，bundle 亦同波重打包并更新）。
- 包内 tester 文档**按设计不写死哈希**：9 个文本文件（8 文档 + `签名说明.txt`）的 64-hex 计数均为 0；校验一律以 release 说明「## Integrity」小节、`.tar.gz.sha256` 边车与随包 `SHA256SUMS` 为准。
- 本快照的本地复核：tree digest OK；`sha256sum -c SHA256SUMS` **15/15** 通过（5 hap + 9 文档 + `verify-kit.sh`）；`verify-kit.sh`（kit #28 修订版，abc 期望重锚 264,136）自验 **0 FAIL / 0 WARN**（锚点 + tree + 5 hap 深度断言全过，含逐 hap payload-in-libs marker（新 `zipSha256` 值）与权限条目断言）；发布侧 API digest 与本地同哈希重算一致（含 `device-test-kit.tar.gz` 的 `091dcc56…`）；gh-proxy 下载端到端复验 KIT OK（kit #28 与三处 bundle 逐字节同值）。
- kit #28 内容（全新解包实测）：5 个 hap 在批末 `b6f0302`（发布波 `dfbe2a6` 为其上收口）重建；均带 `"libIsolation": true`、`bundleName=com.example.hellomauiapp` 与 **278** 个 zip 条目（24 + 254 payload）；`ets/modules.abc` = **264,136 B**、头 `13.0.1.0`（`9020ec5e…`，ui/shell，Map 覆盖层 + LiveView 探测；headless 变体 18,532 B / `d7ec9ca7…` 随 pack，未变）；`libs/arm64-v8a/` = **269** 个文件 = 14 个 `.so`（12 个 .NET 运行时原生库 + `libopenharmonyhost.so` **269,216 B** / `bb51826e…`（= pack **265,120 B** / `30addfbeaf0a6124a4bb76e16107a414c1370224de1632d262e8098fec0e05cb` + 4096 B 签名块；`DT_NEEDED` 仅 5 项、UND 239 且无 denylist 命中、**134/134** 托管导出契约（+4 个 LiveView sink，Map overlay command 复用既有 Map sink；`check-host-exports.py` 同时解析 `DllImport`/`LibraryImport`））+ `libc++_shared.so`）+ **254** 个 payload 文件 + `.dotnet-payload.json`（`entries=268`、`payloadEntries=254`、`zipEntries=254`、`zipSha256` 与回退 zip 字节一致：26.0 波段 `93706234…` / 20.0 波段 `d1005952…`，含 Map/LiveView 切片编译产物；第 254 项为 Razor 静态资产管线产出的 `*.endpoints.json`）；`resources.index` = **1,588 B** / `db1f1bbb…`（26.0 波段）、**1,780 B** / `33227e61…`（API 20 波段，与 #25 同值）；`dotnet.zip` **254** 项且 **0** 个 `.so`（16,058,589 B / 20.0 波段 16,058,587 B）；hap sha256：`hello-maui-app.hap` = 75,669,608 B / `9870e50d3a33079d4a36460fa470cd28a5e3922445d51b8d2c729b64a162a03a`、`hello-maui-app-permissions.hap` = 75,669,641 B / `ea2c2d16…`、`hello-maui-app-api20.hap` = 75,669,629 B / `2d22fb25…`、`hello-maui-app-api20-permissions.hap` = 75,669,642 B / `f3d06dab…`、`hello-maui-app-unsigned.hap` = 73,499,383 B / `f013d431…`（每个签名 hap 较 #27 约 +109.7 KB，来自新 abc 与 Map/LiveView 切片；`Microsoft.OpenHarmony.Hosting.dll` = **55,296 B** / `4c121725…`（未变）；`Microsoft.OpenHarmony.Maui.Graphics.dll` = **16,384 B** / `01a09b32…`（未变））；两个 `*-permissions` 变体各带 5 条 `requestPermissions`，均含 `reason`（`$string:permission_reason_*`）与 `usedScene`（`abilities=[EntryAbility]`、`when=inuse`），默认变体为 0 条；包内 `verify-kit.sh` = 53,999 B / `8f855ad9…`（abc 期望重锚 264,136/18,532；`dotnet.zip` 254、index 阈值 2 KiB 不变）；`module.json` 26.0 波段 min `50002014` / target `60101024`、20.0 波段 min=target `60000020`（均未变）。
- 本版（kit #28 波次）**已重打包 bundle**：headless 变体 abc **18,532 B** / `d7ec9ca7…`（未变）、UI/shell abc **264,136 B** / `9020ec5e…`（Map 覆盖层 + LiveView 探测；was 245,412 / `0e31b619…`）、宿主 **265,120 B** / `30addfbe…`（134/134 导出契约；was 261,024 / `2ea5fd92…`）；Sdk pack **322,441 B**：`tools/Microsoft.OpenHarmony.Tasks.dll` = **32,256 B** / `28c47cbf…`（未变），`targets/OpenHarmony.Hap.targets` = **57,750 B** / `390ea180…`（未变），`targets/OpenHarmony.PlatformItems.targets` = **4,678 B** / `31e0bb8d…`（MapOverlay 模块拷贝逻辑；was 3,918 / `70ac714b…`），`Sdk/Sdk.targets` = **5,736 B** / `fd59a681…`（未变）；hosting/Maui.Graphics = **55,296 B** / `4c121725…`、**16,384 B** / `01a09b32…`（均未变）；Ref.20/26 = 25,135 B、Runtime.20/26 = 32,953 B（6 个 feed nupkg 按设计变化）；新 bundle **30,525,614 B / `7d614517…`** 已同步三处 release 并更新 `sdk-ohos` 锚（见 §3/§4）。
- kit #22 起 `签名说明.txt` 的「PA1 重建壳的下一版 kit」历史文案已随源修复（`ohos-workload c6a4cd95e`）；若手上副本仍出现该句，按历史文案处理，判读以 `签名说明` 其余内容 + release notes 为准。
- kit 编号演进（团队跟踪口径，非连续）：#7（22 日凌晨）→ #10（入口 record）→ #11（abc `13.0.1.0`）→ #12（宿主 dlopen-only + 壳 `host` 守卫）→ #14（评审整改 + PI1 + UX 深化）→ #15（rawfile 资源桥）→ #16（宿主按两个 napi 名注册）→ #17（RM1 libIsolation repack）→ #18（安全/性能第一批）→ #19（启动/TLS/评审合规）→ #20（最终热点回填 H10/P16/P9/P10/P19）→ #21（headless abc `24.0.0.0` → `13.0.1.0` 修复 + tester-run v6r2 + slice pin `236d18a9`）→ #22（设备里程碑回灌——宿主 `DT_NEEDED` 5 + 可选 API dlsym、`resources.index`（restool）、ZIP offset/mkdir、DevEco `modelVersion 6.0.2` 工程布局；tester-run v6r2）→ #23（工具刷新——强化 `verify-kit.sh` 逐 hap 深度断言 + `tester-run.sh` v7 入包）→ #24（payload-in-libs——payload 随签名 `libs/<abi>/` 原地启动 + `.dotnet-payload.json` marker、`dotnet.zip` 回退；显式 W^X=0（`xwe.txt` A/B）+ exec-memory 探针；重建 UI/headless abc；`tester-run.sh` v8）→ #25（权限链 + Share/Scan 特性探测（宿主导出契约 118/118）+ AOT 启动路径 + present 缓存 + JSON 源生成 + targets 强化；重建壳/宿主/targets/托管程序集；bundle 重打包）→ #26（P2-INTEROP 设备/kit 桥全量 source-generated LibraryImport（125 处；118/118 导出契约不变）+ TASK-MIG 打包任务编译进 `tools/Microsoft.OpenHarmony.Tasks.dll`（targets 拆分出 `PlatformItems.targets`）+ PLAT-GAP AspNetCore KFR/默认 RID/apphost 修正；重建 Hosting 桥并重打包 bundle）→ #27（KIT-EXT2 — 壳 Push/Account/Map 特性探测（abc 245,412）+ 宿主 12 个 kit sink（导出契约 130/130）+ FIX-R1-NAPI-6D 边界加固 + FIX-R1-MARSHAL-OFF 反向入口 marshal off + payload-zip opt-out pack 同步 + 交互门禁 329/floor 309）→ **#28（当前：R2-SHELL-EXT — 壳 harmony-flavor MapComponent 覆盖层（`ets/map/MapOverlay.ets`）+ Live View 探测/桥（ui/shell abc 264,136）+ 宿主导出契约 134/134 + `start_app` 的 AOT 路由桥（`aot=1`/回退）与 `interp.txt` 解释器 pack 注入 + 交互门禁 334/floor 314；重建壳/宿主并重打包 bundle）**。
- **kit 波次收口（2026-09-26，`dfbe2a6` + `sdk-ohos 93350abcae`，均在批末 `b6f0302` 之上）**：`dfbe2a6` 把交互/像素/宿主导出三套 CI 的 maui pin 从 `a0a2c087` 推进到 `63d13d15`（Map/LiveView 切片）、ridgraph-sync 的 sdk-ohos pin 从 `f27b20f4cc` 推进到 `3eb480fb4b`（图字节未变）；CI 5/5 success：interaction 36228452281 / pixel 36228452257 / host-export 36228452262 / ridgraph 36228452256 / markdownlint 36228452264（批末 `b6f0302` 的 host-export run 36226434585 因导出契约口径未同步红，收口后恢复）；`93350abcae` 把 `versions.env` 的 workload bundle 锚从 `bc30c65b` 更新到 `7d614517`（安装器 43/43 + hostfeed 10/10 + codesign 5/5）。
- release 最后更新 2026-09-26（kit #28 资产；`tester-run.sh` v8 未动；bundle 已重打包并同步三处 release）；`2026-09-21-ohos-final-status.md` 已同步到 kit #24 并指向 `2026-09-24-ohos-device-milestone.md`，本页与之一致锚定当前 release。

## 2. `device-test-kit` release 上的全部资产（2026-09-26 快照，21 项）

| 资产 | 大小 (B) | sha256 | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz` | 196,220,486 | `091dcc562a6da00ab2a5d9c13025f3479790bdb22b13061702755b715bc3267c` | 当前 kit #28（R2-SHELL-EXT：Map 覆盖层 + LiveView 探测/桥 + AOT `start_app` 桥 + `interp.txt`；ui/shell abc 264,136；宿主导出契约 134/134；交互门禁 334/floor 314；`tester-run.sh` v8 随附） |
| `device-test-kit.tar.gz.sha256` | 89 | `d7efd251a2ee281ae222522e4a20acf6cb2480aacecb134804a840ba06fded25` | 整包边车（内容 = 上一行哈希） |
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
| `tester-run.sh` | 73,375 | `6ca2093e8ed2b76b6ca73b0c9e8ad87fa07a14c86514a9d21c75d790ac5129b1` | **v8**（内嵌 `SCRIPT_VERSION="8 (2026-09-24)"`；仓库脚本 commit `8b162a1`）：校验 + 安装 + 启动 + 30 s hilog + RM1 无重建 app-lib/dlopen 证据；bootstrap/rawfile 失败特征、payload 状态与逐 hap kit 自检（`resources.index`/libs/`payload=yes\|no`/abc 头，`meta/kit-selfcheck.txt`、`kit_index_ok`）；v8 的 exec-memory 证据采集（`hilog/hilog-execmem.txt`：`xwe=0\|1 source=default\|file` 决策行 + `OHOS_DOTNET probe:`，`summary.txt` 的 `execmem_capture`/`execmem_lines`）；发任何 hdc 命令前校验 bundle 名（A1）；复用已校验摘要产出 kit 摘要（P16）。**kit #28 波次未改动、未重传**（仍与仓库逐字节一致） |
| `aot-haps-README.md` | 3,414 | `105e88fc6c33ddf6504036904bde5479200c0baf1c4809660a19bc083ae7f737` | AOT hap 资产说明（R2-2，独立于本 kit；kit #28 波次未动） |
| `aot-haps.tar.gz` | 17,090,044 | `67519d118d14ffb48d9db19bf1c86ec3582ce94b9db1602fa2900e041bd69ef1` | MAUI NativeAOT hap 变体（另有资产，不在 kit 内；kit #28 波次未动） |
| `aot-haps.tar.gz.sha256` | 82 | `f4d5cdbccfc6fdd42fde2ec3632bcace0b187adca969700a4ae7dcdbe74a9a7c` | AOT hap 边车（未动） |
| `ohos-interpreter-pack-README.md` | 3,324 | `44c4fc78b3ef3961c98da167acdb7d9938f7125648700ba2efc8d2080347314f` | 解释器 pack 说明（R2-INTERP-FULL，独立于本 kit；kit #28 波次未动） |
| `ohos-interpreter-pack.tar.gz` | 2,419,988 | `a10699b3da9c26602556ce141375644d61541bfdfe7d3eceff2de52aa113f873` | 解释器 pack（另有资产；`interp.txt` 开关由宿主消费，不在 kit 内；kit #28 波次未动） |
| `ohos-interpreter-pack.tar.gz.sha256` | 95 | `4eb569cbe3551d856fec10bc9d852e9d45de337b076cf2dd3e75d5fcb378424b` | 解释器 pack 边车（未动） |

- 诊断资产对应关系：`dynpkg-haps.tar.gz` 为候选矩阵中最强单候选（动态加载 + `runtimeOnly.packages`/`file:` 包声明；随包 5 hap 带 libIsolation、abc 新增 host-binding `.record libopenharmonyhost.so`、入口 record 保持已确认形式）；`normalized-haps.tar.gz` 的 normalized 入口 record 的设备解析未证。`importb`/`importd` 分别对应静态命名空间与动态加载实验；三个 `importprobe` hap 无 .NET 载荷，只测三种 import 形式的路由。P1–P4 仍用于 dlopen/缺库/宿主入口/运行时类崩溃的五层定位。
- 全部数字均为 2026-09-26 读取：release API digest 与本地重算一致（kit、bundle、dynpkg、normalized、importb、importd、tester-run.sh）；本轮 kit #28 变化 **2 项**：`device-test-kit.tar.gz` 与 `.sha256` 边车（重打包重传，`tester-run.sh` 保持 v8 未动）；其余 **19 项**（探针 hap、诊断 tarball、dynpkg/importb/importd/normalized、`checklist`、`tester-run.sh`、AOT hap 3 项、解释器 pack 3 项）与上一快照逐字节同值；`workload-latest` 上同步镜像是 `device-test-kit.tar.gz` + `.sha256` **2 项**，且本轮 bundle + `SHA256SUMS` 亦重传（4 项全变）；`workload-1.0.0-preview.24` 变化 2 项（bundle + `SHA256SUMS`）；SDK release 变化 2 项（bundle + `SHA256SUMS`，合并 sums 仍为两行 212 B / `5ce7594c…`），其余 33 项零变化。`importprobe` a/b/c 的 API digest 与实验文档记录一致。诊断 tarball 内的 hap 均未签名或为陈旧签名，测试方需重签（§6）。

## 3. Workload bundle（versioned + rolling + SDK release）

| 资产 | 大小 (B) | sha256 | 位置 |
|---|---|---|---|
| `openharmony-workload-1.0.0-preview.24.tar.gz` | 30,525,614 | `7d6145173c195dd8a7eb699ef2bb25095ca5b98c71a64b43a53591e8a9d3b201` | `workload-1.0.0-preview.24` / `workload-latest` release |
| `openharmony-workload-latest.tar.gz` | 30,525,614 | `7d6145173c195dd8a7eb699ef2bb25095ca5b98c71a64b43a53591e8a9d3b201` | `workload-latest` release（与 versioned 逐字节一致） |

- 两名字指向同一份字节；`SHA256SUMS`（212 B，自身 sha256 `5ce7594c59d3895ec694e8eda4a13f995ef3f97d01269e2763a22f3510cdd3ee`，kit #27 为 `cf22fe1a…`）同时列出上述两条，与本地 `dist/SHA256SUMS` 重算一致；`sha256sum -c` 2/2 通过（gh-proxy 抽验目录内）。
- **FIX-RESID 重打包（2026-09-23T17:16+08:00，历史）**：旧 bundle 30,477,923 B / `6d8c44802187929f904de86ccde1262061e3cb9f5de428b17b0fc0aed8c18d47` 内的 preview.24 平台包还是修复前托管（`Microsoft.OpenHarmony.Hosting.dll` 32,256 B）；该次重打包后 Ref.20.0/26.0 与 Runtime.20.0/26.0 均为 34,816 B / `d776b1d5811e28149bb095b77cf2f4b80049c52f04b5042c3a10271072083ff1`，另含重建的 `Microsoft.OpenHarmony.Maui.Graphics.dll`（16,384 B / `6b5de857…`），即 kit #18 的 bundle（30,484,382 B / `4ba913c6…`）。此后各版依次为：kit #19 = 30,482,709 B / `5e84fe21…`；kit #20 = 30,499,901 B / `ba43c2e8…`；kit #21 = 30,498,612 B / `41d94901…`（headless abc `13.0.1.0`）。
- **kit #21 重打包（2026-09-24，历史）**：bundle 30,498,612 B / `41d94901…`（130 条目）修复 headless 变体 abc（`24.0.0.0` 3,580 B → `13.0.1.0` **13,572 B** / `70a61636…`）并让 pack 模板 README 指向 `ARKTS_SHELL_VARIANT=headless`（`e995cef`）；hosting/Maui.Graphics 托管在 `1f7ef76` 重建（仅内嵌 source revision 变化）；UI/shell abc 211,032 B / `7d513f72…` 与宿主 211,872 B / `33baff42…` 未变。
- **kit #22 重打包（2026-09-24，历史）**：bundle 30,498,838 B / `04b96cec…`（130 条目）——原生宿主按需 dlopen/dlsym 重建（**215,968 B / `3332c8ac…`**，DT_NEEDED 收窄为 5）；UI/shell abc **212,952 B / `6e616f5b…`** 与 headless **15,608 B / `c72990c1…`** 按 DevEco 布局 `modelVersion 6.0.2` 重建；Sdk pack `targets/OpenHarmony.Hap.targets` = **46,213 B / `e4318436…`**（restool 生成 `resources.index`）；hosting/Maui.Graphics 在 `0f26b74` 重建（**35,840 B / `e588b655…`**、**16,384 B / `0604c536…`**）。发布后三处 release 新 bundle 逐字节一致。
- **kit #23 波次（2026-09-24，历史）**：bundle 与 #22 **逐字节相同**（`04b96cec…` / 30,498,838 B），该波**未重发 bundle、未更新 `sdk-ohos` 锚**。
- **kit #24 重打包（2026-09-24，历史）**：bundle **30,524,164 B / `d28578e2…`**（130 条目；6 个 feed nupkg 变化）：Sdk pack **344,301 B** 携带 payload-in-libs `targets/OpenHarmony.Hap.targets` = **57,438 B / `fcf54c97…`**、UI/shell abc **215,680 B / `0def57e0…`**、headless abc **18,308 B / `25ab7a9e…`**、宿主 **220,064 B / `19d9d4b4…`**；Ref.20/26 `18391 B`、Runtime.20/26 `26215 B`；hosting/Maui.Graphics 在 `8b162a1` 重建（**35,840 B / `2f9993cb…`**、**16,384 B / `f861e06e…`**）。
- **kit #25 重打包（2026-09-25，历史）**：bundle **30,487,575 B / `6c607c73…`**（130 条目）：Sdk pack **284,047 B** 携带 UI/shell abc **234,620 B / `34325332…`**、headless abc **18,532 B / `d7ec9ca7…`**、`targets/OpenHarmony.Hap.targets` = **94,123 B / `4b2a10be…`**、宿主 **236,448 B / `8fa24895…`**；Ref.20/26 `23,368 B`、Runtime.20/26 `31,193 B`；hosting/Maui.Graphics 在 `5ecd8a5` 重建（**47,616 B / `e4f6fade…`**、**16,384 B / `7a7c5531…`**；JSON 源生成 + AOT 入口点）。
- **kit #26 重打包（2026-09-26，历史）**：bundle **30,501,359 B / `7b9ccd6e…`**（130 条目，成员集与上版一致；6 个 feed nupkg 按设计变化）：Sdk pack **290,854 B**（was 284,047）新增 `tools/Microsoft.OpenHarmony.Tasks.dll` = **32,256 B / `28c47cbf…`**，`targets/OpenHarmony.Hap.targets` = **55,473 B / `2f2c234c…`**（TASK-MIG：任务体移出，只留 `UsingTask`/调用面），新增 `targets/OpenHarmony.PlatformItems.targets` = **3,918 B / `70ac714b…`**（PLAT-GAP：AspNetCore KFR `11.0.0-rc.1.26425.128` + `openharmony-*`→`linux-musl-*` 映射），`Sdk/Sdk.targets` = **5,736 B / `fd59a681…`**（默认 `RuntimeIdentifier=openharmony-arm64` + `EnableAppHostPackDownload=false`）；abc 与宿主与 #25 逐字节相同；Ref.20/26 `25,510 B`、Runtime.20/26 `33,334 B`；hosting/Maui.Graphics 在 `123a223`（P2-INTEROP 桥）/`7075b67` 重建（**55,808 B / `38f5a3d2…`**（was 47,616）、**16,384 B / `8de00efd…`**）。成员级对比：130=130、无增删，仅 6 个 feed nupkg 变化（BCL runtime pack 成员 386/386 内容一致，仅重打包 zip 元数据）。发布后经 API（by-id）与 gh-proxy 下载抽验：三处（`workload-latest`、`workload-1.0.0-preview.24`、SDK release）新 bundle 逐字节一致，`sha256sum -c` 通过；`sdk-ohos` 锚已更新并推送（见 §4）。
- **kit #27 重打包（2026-09-26，历史）**：bundle **30,508,149 B / `bc30c65b…`**（130 条目，成员集与上版一致；6 个 feed nupkg 按设计变化）：Sdk pack **305,204 B**（was 290,854）携带 UI/shell abc **245,412 B / `0e31b619…`**（KIT-EXT2 Push/Account/Map 探测；was 234,620）、headless abc **18,532 B / `d7ec9ca7…`**（未变）、`targets/OpenHarmony.Hap.targets` = **57,750 B / `390ea180…`**（payload-zip opt-out pack 同步；was 55,473）、`targets/OpenHarmony.PlatformItems.targets` = **3,918 B / `70ac714b…`**（未变）、`Sdk/Sdk.targets` = **5,736 B / `fd59a681…`**（未变）、`tools/Microsoft.OpenHarmony.Tasks.dll` = **32,256 B / `28c47cbf…`**（未变）；Ref.20/26 `25,135 B`、Runtime.20/26 `32,953 B`；hosting/Maui.Graphics 在 `080f422`（marshal-off hosting）/ maui 切片 `a0a2c087` 重建（**55,296 B / `4c121725…`**（was 55,808）、**16,384 B / `01a09b32…`**）。发布后经 API（by-id）与 gh-proxy 下载抽验：三处（`workload-latest`、`workload-1.0.0-preview.24`、SDK release）新 bundle 逐字节一致，`sha256sum -c` 通过；`sdk-ohos` 锚已更新并推送（见 §4）。
- **kit #28 重打包（2026-09-26，本轮）**：bundle **30,525,614 B / `7d614517…`**（130 条目，成员集与上版一致；6 个 feed nupkg 按设计变化）：Sdk pack **322,441 B**（was 305,204）携带 UI/shell abc **264,136 B / `9020ec5e…`**（Map 覆盖层 + LiveView 探测；was 245,412）、headless abc **18,532 B / `d7ec9ca7…`**（未变）、`targets/OpenHarmony.Hap.targets` = **57,750 B / `390ea180…`**（未变）、`targets/OpenHarmony.PlatformItems.targets` = **4,678 B / `31e0bb8d…`**（MapOverlay 模块拷贝逻辑；was 3,918）、`Sdk/Sdk.targets` = **5,736 B / `fd59a681…`**（未变）、`tools/Microsoft.OpenHarmony.Tasks.dll` = **32,256 B / `28c47cbf…`**（未变）；宿主 = **265,120 B / `30addfbe…`**（134/134 导出契约；was 261,024 / `2ea5fd92…`）；Ref.20/26 `25,135 B`、Runtime.20/26 `32,953 B`；hosting/Maui.Graphics 未变（**55,296 B / `4c121725…`**、**16,384 B / `01a09b32…`**）。发布后经 API（by-id）与 gh-proxy 下载抽验：三处（`workload-latest`、`workload-1.0.0-preview.24`、SDK release）新 bundle 逐字节一致，`sha256sum -c` 通过；`sdk-ohos` 锚已更新并推送 `3eb480fb4b..93350abcae`（见 §4）。
- SDK release `v11.0.100-rc.1.26451.109-openharmony`（id **388357742**）：`https://github.com/springmin/sdk-ohos/releases/tag/v11.0.100-rc.1.26451.109-openharmony`；其上随 SDK 发布附带的 workload bundle 已同步为 kit #28 重打包（**30,525,614 B / `7d614517…`**，`SHA256SUMS` **212 B / `5ce7594c…`**（两行，与 `workload-latest`/`preview.24` 同值）；变更资产 = bundle + `SHA256SUMS`，其余 33 项不变；SDKREL-28，2026-09-26）。SDK 包 `dotnet-sdk-11.0.100-rc.1.26451.109-openharmony-arm64.tar.gz` = 178,005,544 B / sha256 `f3a1bba4…`、runtime `10b7877f…`、selfsign `85284499…` 三锚逐字节不变；`sdk-ohos` 外锚已更新并推送 `3eb480fb4b..93350abcae`（`versions.env`，`WORKLOAD_BUNDLE_SHA256 = 7d614517…`；安装器测试 43/43 + hostfeed 10/10 + codesign 5/5）。

## 4. 五仓库分支 tip（2026-09-26 终检快照，远端分支 tip；已按 fetch/API 与远端 ref 核对）

| 仓库 | 分支 | 短哈希 | 备注 |
|---|---|---|---|
| `ohos-workload` | `master` | `dfbe2a6` | kit #28 发布链：批末 `b6f0302`（`71205b8` AOT 暂存恢复；`e240f9a` 壳 MapComponent 覆盖层；`a757ba0` Map sink command 复用；`626f4bc` 交互套件 Map 断言；`e11a0b7` 文档；`72910f7` AOT hap 变体打包；`1c120e7` `start_app` AOT 桥；`112b6e9` LiveView 探测/桥 + `interp.txt` + verify-kit abc 重锚 264,136；`b6f0302` aot-smoke aot=0 回退）之上发布波 `dfbe2a6`（CI maui pin `a0a2c087`→`63d13d15`、ridgraph-sync sdk pin `f27b20f4cc`→`3eb480fb4b`）；preflight 全绿（334/floor 314 + pixel），CI 5/5 success（interaction 36228452281 / pixel 36228452257 / host-export 36228452262 / ridgraph 36228452256 / markdownlint 36228452264） |
| `maui-ohos` | `feature/openharmony` | `63d13d15` | MAUI 平台切片（Map 覆盖层 `OpenHarmonyMap.cs` + Live View 桥 `OpenHarmonyLiveView.cs`；CI 三 workflow pin 同值）|
| `sdk-ohos` | `feature/openharmony` | `93350abcae` | SDK 与 release 宿主（bundle 外锚更新并推送 `3eb480fb4b..93350abcae`，`WORKLOAD_BUNDLE_SHA256 = 7d614517…`；安装器 43/43 + hostfeed 10/10 + codesign 5/5）|
| `runtime-ohos` | `feature/openharmony` | `618040a9432` | 本页 kit #28 刷新提交前的 tip（`618040a9432` 测试方文档已同步 kit #28；`e44c22d91e8` 为 R2-SHELL-EXT 文档回填；本次文档提交会再前进一格）|
| `aspnetcore-ohos` | `feature/openharmony` | `eace90c8f` | aspnetcore 移植（fork 指南文档）|

## 5. 怎么校验（三步）与 tester-run.sh 一条命令

三步（手工路径）：

```sh
base=https://github.com/springmin/sdk-ohos/releases/download/device-test-kit
curl -L -O "$base/device-test-kit.tar.gz" -O "$base/device-test-kit.tar.gz.sha256"
sha256sum -c device-test-kit.tar.gz.sha256          # ① 整包锚定
tar xzf device-test-kit.tar.gz && cd device-test-kit
sha256sum -c SHA256SUMS                             # ② 包内 15/15（新 verify-kit 另做逐 hap 深度断言）
sh verify-kit.sh --expect-tree-digest 0a7a3215cfd66b1e89a69e7bd89ec7b8881a8819d4557de607db55e2828c2231   # ③ 内容树绑定
```

一条命令（校验 + 安装 + 启动 + 录 30 秒 hilog，`tester-run.sh` v8 默认 dry-run，无设备不动作；需 `hdc`，多设备加 `--device <id>`；v8 另收集 app-lib 路径与 dlopen 证据（RM1）、bootstrap/rawfile 失败特征、payload 状态与逐 hap kit 自检（index/libs/`payload=yes|no`/abc）以及 exec-memory 证据，复用已校验摘要产出 kit 摘要（P16），并在发任何 `hdc` 命令前校验 bundle 名（A1），`--extra-probes` 可带 importprobe/importb 载荷）：

```sh
sh tester-run.sh --kit-tar ./device-test-kit.tar.gz \
  --expect-tree-digest 0a7a3215cfd66b1e89a69e7bd89ec7b8881a8819d4557de607db55e2828c2231 \
  --install --start --capture 30
```

## 6. 测试方两条签名路径（安装报 `9568344` 时二选一）

| 路径 | 测试方提供 | 交付方执行 |
|---|---|---|
| ① 重签（按你的 UDID） | `hdc shell bm get -u` 的 UDID（或按包内 `自签说明.md` 用 DevEco 自动签名自行完成） | `sh scripts/sign-for-device.sh <UDID>`（多设备逗号分隔） |
| ② 外部预签（用你的材料） | p7b + p12 + cer + keyAlias（华为材料亦可） | `sh scripts/sign-for-device.sh --external --profile <p7b> --key <p12> --cert <cer> --key-alias <alias> --pwd-input-mode --expect-udid 60CF7B27…`（UDID 换成目标设备；p7b 的 `debug-info.device-ids` 必须含它，fail closed）；华为材料可走 `scripts/sign-huawei.sh` |

根因：hap 内调试 profile 的 `debug-info.device-ids` 只含示例 UDID；重签/预签后哈希必变，以新产物随附的 `SHA256SUMS` 为准。kit #28 的 4 个已签 hap 为自签名（默认 `-signCode 1` 会重签 `libs/<abi>/*.so`），诊断 tarball 内的 hap 为陈旧签名或未签名，均需按 §5/自签说明重签。详见 `2026-09-19-ohos-signing-and-udid-guide.md`。

## 7. SDK 门控清单（快速参考，详见覆盖矩阵 §4）

- TextToSpeech — 本 SDK 无 `@kit.CoreSpeechKit` / `@ohos.ai.tts`（链路已接，sink 如实返回不可用）。
- Map — 本 SDK 无 MapKit；kit #28 的 harmony-flavor 壳以 MapComponent 覆盖层接入 HMS，默认 OpenHarmony flavor 按 capability bit 0 降级（`ets/map/MapOverlay.ets` 仅在 harmony flavor 编译）。
- Live View — 本 SDK 无 `@kit.LiveViewKit`（harmony-flavor 壳侧探测；缺失时 sink 如实返回不可用）。
- 系统分享面板 / 多文件分享 — 无 Share Kit，一个 Want 仅单个 uri 槽（文本 + 单文件可用，多文件 no-op）；kit #25 起宿主对 Share/Scan Kit 做特性探测并在缺失时降级。
- BLE GATT client — `connection.GattClientDevice` 未导出（经典蓝牙发现可用）。
- Hot Reload — hdc 策略硬阻塞。
- arm32 — 无 runtime packs、无 32 位设备。

## 8. 接下来读什么

| 文档 | 用途 |
|---|---|
| `2026-09-24-ohos-device-milestone.md` | **真机里程碑**：kit #17→#18 + 测试方 5 项本地修复后首次完整运行（设备/证据/根因链 5 项/回灌映射/kit #22 指纹/仍未验证/复测建议） |
| `2026-09-24-ohos-kit-gap-analysis.md` | HarmonyOS SDK 与 kit 能力缺口重盘点（KIT-GAP；含 Share/Scan 切片落地与可行性结论，kit #25 据此加特性探测） |
| `2026-09-22-ohos-startup-crash-rootcause.md` | 启动崩溃根因 §5b/§5c（kit #10–#12）与 kit #14 里程碑/黑屏阻塞 §5d/§5e；**§5f = 2026-09-24 设备证据修正（旧 #4 降级为无害加固）** |
| `2026-09-23-ohos-napi-import-fix-playbook.md` | 黑屏阻塞 #4 的候选修复 A/B/C、决策表与回滚（设备证据修正后降级为备用） |
| `2026-09-23-ohos-native-import-experiment.md` | importprobe a/b/c 三形式实验 + RM1 lib-isolation 修复与无重建诊断（降级为无害加固） |
| `2026-09-21-ohos-crash-probes.md` | P1–P4 启动崩溃探针与五层定位决策表（kit #22 复测的失败分支入口） |
| `2026-09-21-ohos-device-crash-diagnostics.md` | 崩溃最小取证（hilog/faultlog/status）与 A/B 清单 |
| `2026-09-21-ohos-device-report-template.md` | 真机回传一页模板（机器可解析） |
| `2026-09-22-ohos-new-features-device-checklist.md` | 本轮新功能 M1–M13 真机验证清单（即 release 上的 `new-features-device-checklist.md`；仓库页已同步 kit #22） |
| `2026-09-22-ohos-maui-coverage-matrix.md` | MAUI 覆盖矩阵与 SDK 阻塞/Top-10 缺口（真机状态已指向 kit #22） |
| `2026-09-21-ohos-security-scan.md` | 五仓库安全扫描（第一轮；PASS WITH FINDINGS，23 项已处置） |
| `2026-09-23-ohos-security-scan-2.md` | 五仓库安全扫描 #2（16 条候选，16 修；kit #21/#22 已含全部修复提交；#19–#22 追加 headless abc、bundle 外锚、TLS H-C3、设备回灌等） |
| `2026-09-23-ohos-performance-scan.md` | 五仓库性能扫描（31 热点，29 修 + 2 项有意保留；kit #21/#22 已含已修项） |
| `2026-09-23-ohos-pr-review-compliance.md` | 上游 PR 评审规则遵循（R1–R11、硬违例 0、修复提交与复审计证据；含 #19–#21 追加修复） |
| `2026-09-25-ohos-ms-hmos-compliance.md` | 四域技能合规报告（kit #25 波次查证） |
| `2026-09-23-ohos-upstream-reply-drafts.md` | 未发送的上游回复/催评草稿（#132953、#132827、#132866；arcade#17608 一条已随其合并作废），等审批 |
| `2026-09-23-ohos-tls-policy.md` | TLS 加固策略（H-C3 绝对路径 `dlopen` + 静态链接开关）与设备负向验证 |
| `2026-09-21-ohos-final-status.md` | 一页版最终状态（交付主线、批次、真机待证项、§11 收官；已同步 kit #24 并指向里程碑） |
| `README.md` | `docs/plans` 文档索引（本目录入口） |
