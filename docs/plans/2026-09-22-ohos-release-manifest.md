# OpenHarmony .NET/MAUI 交付物清单（2026-09-26 快照）

> **本页是静态快照**（文件名为创建日期；数值于 2026-09-26 随 kit #27（KIT-EXT2：壳侧对 Push/Account/Map 三个 Kit 做特性探测（ui/shell abc 234,620 → **245,412**）；宿主新增 12 个 kit sink（托管导出契约 118/118 → **130/130**）并含 FIX-R1-NAPI-6D 边界加固；反向入口改为 marshal off（FIX-R1-MARSHAL-OFF：hosting 与 maui 切片用 `[UnmanagedCallersOnly]` + `delegate* unmanaged[Cdecl]` thunk）；交互门禁 **329/floor 309**；`OpenHarmonyHapPayloadZip` opt-out 在三套 preview pack 同步；发布波另含 verify-kit abc 重锚与 maui/sdk CI pin 推进）刷新；kit #26 = P2-INTEROP/TASK-MIG/PLAT-GAP；kit #25 = 权限链/Share+Scan 探测/AOT 启动路径/导出契约 118/118；kit #22 = 设备里程碑回灌（宿主按需 dlsym + `resources.index` + ZIP/mkdir + DevEco 工程布局），kit #23 = 工具刷新，kit #24 = payload-in-libs）：只回答「截至该时点，当前交付物有哪些、数字是多少、去哪里取」。
> 所有数字在 2026-09-26 核对：本地文件重算 sha256 + GitHub release API digest 双向一致；任何重签、预签或重新打包都会改变哈希。
> kit 编号（#27）是团队跟踪口径，release 本身不带编号；以后续文档与 release 说明为准。本轮发布波含两笔 **kit 波次修复提交**（`ohos-workload 898f4a1`：包内 verify-kit 的 abc 期望值重锚 234,620 → 245,412；`75cdc26`：CI 的 maui pin `1a754753` → `a0a2c087` + ridgraph-sync sdk pin `97cad7c59a` → `f27b20f4cc`）。

## 1. 当前 kit（kit #27，`device-test-kit` release，KIT-EXT2：壳 Push/Account/Map 特性探测（abc 245,412）/ 宿主 12 个 kit sink（导出契约 130/130）+ FIX-R1-NAPI-6D 边界加固 / FIX-R1-MARSHAL-OFF 反向入口 marshal off / 交互门禁 329/floor 309 / payload-zip opt-out pack 同步：重建 Hosting 桥（55,296 B）与新 bundle；`tester-run.sh` v8 随附（本轮未变，未重传）；tar.gz + sidecar 于 2026-09-26 重传）

- 位置：`https://github.com/springmin/sdk-ohos/releases/tag/device-test-kit`（下载前缀 `https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/`）。
- `device-test-kit.tar.gz`：**195,951,029 B**，sha256 `74211b6e5f6381a0d866b3e2f7a06783d5ee643f2afb88cc788c8a2a0c417b6d`（kit #26：195,748,984 B / `c8b13e56…`；kit #25：195,567,555 B / `e0502709…`；单个签名 hap 仍约 75.56 MB，payload 随签名 `libs/arm64-v8a/` 一起打包）。
- `device-test-kit.tar.gz.sha256` 边车（89 B）：内容 = tar.gz 哈希；边车自身 sha256 `cc26f830ffaf32004e5edd50bbda5bb0c9a9be700a34a7242b16e6ec47dc9df8`（kit #26 边车：`854135fc…`）。
- 解压内容树摘要（tree digest，绑定解压后的内容而非仅 tar 包）：`6abff90e69bcac4235791ce705f6851bc0ad67ba352619c1922d925977f347ca`。
  验证：解压后在包内执行 `sh verify-kit.sh --expect-tree-digest 6abff90e69bcac4235791ce705f6851bc0ad67ba352619c1922d925977f347ca`（kit #26 tree：`2f247e40…`；#25 tree：`9014b428…`）。
- 镜像：`workload-latest` release 上的同名资产逐字节同值（大小、sha256 相同；tree digest 同值；2026-09-26 kit #27 波次同步更新，bundle 亦同波重打包并更新）。
- 包内 tester 文档**按设计不写死哈希**：9 个文本文件（8 文档 + `签名说明.txt`）的 64-hex 计数均为 0；校验一律以 release 说明「## Integrity」小节、`.tar.gz.sha256` 边车与随包 `SHA256SUMS` 为准。
- 本快照的本地复核：tree digest OK；`sha256sum -c SHA256SUMS` **15/15** 通过（5 hap + 9 文档 + `verify-kit.sh`）；`verify-kit.sh`（kit #27 修订版，abc 期望重锚 245,412）自验 **0 FAIL / 0 WARN**（锚点 + tree + 5 hap 深度断言全过，含逐 hap payload-in-libs marker（新 `zipSha256` 值）与权限条目断言）；发布侧 API digest 与本地同哈希重算一致（含 `device-test-kit.tar.gz` 的 `74211b6e…`）；gh-proxy 下载端到端复验 KIT OK（kit #27 与三处 bundle 逐字节同值）。
- kit #27 内容（全新解包实测）：5 个 hap 在批末 `fa8a28e`（发布波 `898f4a1`/`75cdc26` 为其上收口）重建；均带 `"libIsolation": true`、`bundleName=com.example.hellomauiapp` 与 **278** 个 zip 条目（24 + 254 payload）；`ets/modules.abc` = **245,412 B**、头 `13.0.1.0`（`0e31b619…`，ui/shell，Push/Account/Map 探测；headless 变体 18,532 B / `d7ec9ca7…` 随 pack，未变）；`libs/arm64-v8a/` = **269** 个文件 = 14 个 `.so`（12 个 .NET 运行时原生库 + `libopenharmonyhost.so` **265,120 B** / `366720e0…`（= pack **261,024 B** / `2ea5fd92cd4718c8b8d16437e98de3562823d979afd6da615e452e3c5d3955d1` + 4096 B 签名块；`DT_NEEDED` 仅 5 项、UND 239 且无 denylist 命中、**130/130** 托管导出契约（+12 个 Push/Account/Map kit sink；`check-host-exports.py` 同时解析 `DllImport`/`LibraryImport`），反向入口走 marshal-off thunk）+ `libc++_shared.so`）+ **254** 个 payload 文件 + `.dotnet-payload.json`（`entries=268`、`payloadEntries=254`、`zipEntries=254`、`zipSha256` 与回退 zip 字节一致：26.0 波段 `ae3f603e…` / 20.0 波段 `457c65aa…`，因重建后的 Hosting 桥在 `dotnet.zip` 内；第 254 项为 Razor 静态资产管线产出的 `*.endpoints.json`）；`resources.index` = **1,588 B** / `db1f1bbb…`（26.0 波段）、**1,780 B** / `33227e61…`（API 20 波段，与 #25 同值）；`dotnet.zip` **254** 项且 **0** 个 `.so`（16,038,874 B / 20.0 波段 16,038,824 B）；hap sha256：`hello-maui-app.hap` = 75,559,923 B / `d9b53fc3829851cdc1fcb3112a50ba53c2d2d70b4683e2367e6e9fba432ff0a6`、`hello-maui-app-permissions.hap` = 75,559,968 B / `830eee05…`、`hello-maui-app-api20.hap` = 75,559,979 B / `7f62992b…`、`hello-maui-app-api20-permissions.hap` = 75,559,990 B / `ceadcee3…`、`hello-maui-app-unsigned.hap` = 73,388,632 B / `7815f271…`（每个签名 hap 较 #26 约 +85.9 KB，来自新 abc 与 marshal-off 托管重建；`Microsoft.OpenHarmony.Hosting.dll` = **55,296 B** / `4c121725…`，was 55,808 B / `38f5a3d2…`；`Microsoft.OpenHarmony.Maui.Graphics.dll` = **16,384 B** / `01a09b32…`，was `8de00efd…`）；两个 `*-permissions` 变体各带 5 条 `requestPermissions`，均含 `reason`（`$string:permission_reason_*`）与 `usedScene`（`abilities=[EntryAbility]`、`when=inuse`），默认变体为 0 条；包内 `verify-kit.sh` = 53,999 B / `7f3420d2…`（abc 期望重锚 245,412/18,532；`dotnet.zip` 254、index 阈值 2 KiB 不变）；`module.json` 26.0 波段 min `50002014` / target `60101024`、20.0 波段 min=target `60000020`（均未变）。
- 本版（kit #27 波次）**已重打包 bundle**：headless 变体 abc **18,532 B** / `d7ec9ca7…`（未变）、UI/shell abc **245,412 B** / `0e31b619…`（Push/Account/Map 探测；was 234,620 / `34325332…`）、宿主 **261,024 B** / `2ea5fd92…`（12 个 kit sink + FIX-R1-NAPI-6D 边界加固；was 236,448 / `8fa24895…`）；Sdk pack **305,204 B**：`tools/Microsoft.OpenHarmony.Tasks.dll` = **32,256 B** / `28c47cbf…`（未变），`targets/OpenHarmony.Hap.targets` = **57,750 B** / `390ea180…`（payload-zip opt-out pack 同步；was 55,473 / `2f2c234c…`），`targets/OpenHarmony.PlatformItems.targets` = **3,918 B** / `70ac714b…`（未变），`Sdk/Sdk.targets` = **5,736 B** / `fd59a681…`（未变）；hosting/Maui.Graphics = **55,296 B** / `4c121725…`（FIX-R1-MARSHAL-OFF 反向入口 marshal off；was 55,808 / `38f5a3d2…`）、**16,384 B** / `01a09b32…`（was `8de00efd…`）；Ref.20/26 = 25,135 B、Runtime.20/26 = 32,953 B（6 个 feed nupkg 按设计变化）；新 bundle **30,508,149 B / `bc30c65b…`** 已同步三处 release 并更新 `sdk-ohos` 锚（见 §3/§4）。
- kit #22 起 `签名说明.txt` 的「PA1 重建壳的下一版 kit」历史文案已随源修复（`ohos-workload c6a4cd95e`）；若手上副本仍出现该句，按历史文案处理，判读以 `签名说明` 其余内容 + release notes 为准。
- kit 编号演进（团队跟踪口径，非连续）：#7（22 日凌晨）→ #10（入口 record）→ #11（abc `13.0.1.0`）→ #12（宿主 dlopen-only + 壳 `host` 守卫）→ #14（评审整改 + PI1 + UX 深化）→ #15（rawfile 资源桥）→ #16（宿主按两个 napi 名注册）→ #17（RM1 libIsolation repack）→ #18（安全/性能第一批）→ #19（启动/TLS/评审合规）→ #20（最终热点回填 H10/P16/P9/P10/P19）→ #21（headless abc `24.0.0.0` → `13.0.1.0` 修复 + tester-run v6r2 + slice pin `236d18a9`）→ #22（设备里程碑回灌——宿主 `DT_NEEDED` 5 + 可选 API dlsym、`resources.index`（restool）、ZIP offset/mkdir、DevEco `modelVersion 6.0.2` 工程布局；tester-run v6r2）→ #23（工具刷新——强化 `verify-kit.sh` 逐 hap 深度断言 + `tester-run.sh` v7 入包）→ #24（payload-in-libs——payload 随签名 `libs/<abi>/` 原地启动 + `.dotnet-payload.json` marker、`dotnet.zip` 回退；显式 W^X=0（`xwe.txt` A/B）+ exec-memory 探针；重建 UI/headless abc；`tester-run.sh` v8）→ #25（权限链 + Share/Scan 特性探测（宿主导出契约 118/118）+ AOT 启动路径 + present 缓存 + JSON 源生成 + targets 强化；重建壳/宿主/targets/托管程序集；bundle 重打包）→ #26（P2-INTEROP 设备/kit 桥全量 source-generated LibraryImport（125 处；118/118 导出契约不变）+ TASK-MIG 打包任务编译进 `tools/Microsoft.OpenHarmony.Tasks.dll`（targets 拆分出 `PlatformItems.targets`）+ PLAT-GAP AspNetCore KFR/默认 RID/apphost 修正；重建 Hosting 桥并重打包 bundle）→ **#27（当前：KIT-EXT2 — 壳 Push/Account/Map 特性探测（abc 245,412）+ 宿主 12 个 kit sink（导出契约 130/130）+ FIX-R1-NAPI-6D 边界加固 + FIX-R1-MARSHAL-OFF 反向入口 marshal off + payload-zip opt-out pack 同步 + 交互门禁 329/floor 309；重建壳/宿主/targets/托管程序集并重打包 bundle）**。
- **kit 波次修复（2026-09-26，`898f4a1` + `75cdc26`，均在批末 `fa8a28e` 之上）**：`898f4a1` 把包内 verify-kit 的 abc 期望从 234,620/18,532 重锚到 **245,412**/18,532（KIT-EXT2 壳重建后的新值），自验恢复 0 FAIL；`75cdc26` 把交互/像素/宿主导出三套 CI 的 maui pin 从 `1a754753` 推进到 `a0a2c087`、ridgraph-sync 的 sdk-ohos pin 从 `97cad7c59a` 推进到 `f27b20f4cc`（批末 `fa8a28e` 的 interaction run 36205005783 因旧 pin 红，修复后 CI 5/5 success：interaction 36209459719 / pixel 36209459728 / host-export 36209459748 / ridgraph 36209459732 / markdownlint 36209459740）。
- release 最后更新 2026-09-26（kit #27 资产；`tester-run.sh` v8 未动；bundle 已重打包并同步三处 release）；`2026-09-21-ohos-final-status.md` 已同步到 kit #24 并指向 `2026-09-24-ohos-device-milestone.md`，本页与之一致锚定当前 release。

## 2. `device-test-kit` release 上的全部资产（2026-09-26 快照，15 项）

| 资产 | 大小 (B) | sha256 | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz` | 195,951,029 | `74211b6e5f6381a0d866b3e2f7a06783d5ee643f2afb88cc788c8a2a0c417b6d` | 当前 kit #27（KIT-EXT2 Push/Account/Map 探测 / 12 kit sink + 130/130 导出 / FIX-R1-NAPI-6D + FIX-R1-MARSHAL-OFF；重建 Hosting 桥；`tester-run.sh` v8 随附） |
| `device-test-kit.tar.gz.sha256` | 89 | `cc26f830ffaf32004e5edd50bbda5bb0c9a9be700a34a7242b16e6ec47dc9df8` | 整包边车（内容 = 上一行哈希） |
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
| `tester-run.sh` | 73,375 | `6ca2093e8ed2b76b6ca73b0c9e8ad87fa07a14c86514a9d21c75d790ac5129b1` | **v8**（内嵌 `SCRIPT_VERSION="8 (2026-09-24)"`；仓库脚本 commit `8b162a1`）：校验 + 安装 + 启动 + 30 s hilog + RM1 无重建 app-lib/dlopen 证据；bootstrap/rawfile 失败特征、payload 状态与逐 hap kit 自检（`resources.index`/libs/`payload=yes\|no`/abc 头，`meta/kit-selfcheck.txt`、`kit_index_ok`）；v8 的 exec-memory 证据采集（`hilog/hilog-execmem.txt`：`xwe=0\|1 source=default\|file` 决策行 + `OHOS_DOTNET probe:`，`summary.txt` 的 `execmem_capture`/`execmem_lines`）；发任何 hdc 命令前校验 bundle 名（A1）；复用已校验摘要产出 kit 摘要（P16）。**kit #27 波次未改动、未重传**（仍与仓库逐字节一致） |

- 诊断资产对应关系：`dynpkg-haps.tar.gz` 为候选矩阵中最强单候选（动态加载 + `runtimeOnly.packages`/`file:` 包声明；随包 5 hap 带 libIsolation、abc 新增 host-binding `.record libopenharmonyhost.so`、入口 record 保持已确认形式）；`normalized-haps.tar.gz` 的 normalized 入口 record 的设备解析未证。`importb`/`importd` 分别对应静态命名空间与动态加载实验；三个 `importprobe` hap 无 .NET 载荷，只测三种 import 形式的路由。P1–P4 仍用于 dlopen/缺库/宿主入口/运行时类崩溃的五层定位。
- 全部数字均为 2026-09-26 读取：release API digest 与本地重算一致（kit、bundle、dynpkg、normalized、importb、importd、tester-run.sh）；本轮 kit #27 变化 **2 项**：`device-test-kit.tar.gz` 与 `.sha256` 边车（重打包重传，`tester-run.sh` 保持 v8 未动）；其余 **13 项**（探针 hap、诊断 tarball、dynpkg/importb/importd/normalized、`checklist`、`tester-run.sh`）与上一快照逐字节同值；`workload-latest` 上同步镜像是 `device-test-kit.tar.gz` + `.sha256` **2 项**，且本轮 bundle + `SHA256SUMS` 亦重传（4 项全变）；`workload-1.0.0-preview.24` 变化 2 项（bundle + `SHA256SUMS`）；SDK release 变化 2 项（bundle + `SHA256SUMS`；本轮发布脚本把 SDK release 的合并 sums 从 versioned-only 111 B 扩为两行 212 B / `cf22fe1a…`），其余 33 项零变化。`importprobe` a/b/c 的 API digest 与实验文档记录一致。诊断 tarball 内的 hap 均未签名或为陈旧签名，测试方需重签（§6）。

## 3. Workload bundle（versioned + rolling + SDK release）

| 资产 | 大小 (B) | sha256 | 位置 |
|---|---|---|---|
| `openharmony-workload-1.0.0-preview.24.tar.gz` | 30,508,149 | `bc30c65b7c9e89b66e3f7d22f46cfd48e5c3ffa7affad9aeeebeed347ca365cd` | `workload-1.0.0-preview.24` / `workload-latest` release |
| `openharmony-workload-latest.tar.gz` | 30,508,149 | `bc30c65b7c9e89b66e3f7d22f46cfd48e5c3ffa7affad9aeeebeed347ca365cd` | `workload-latest` release（与 versioned 逐字节一致） |

- 两名字指向同一份字节；`SHA256SUMS`（212 B，自身 sha256 `cf22fe1a58d1ae160774f9a23305db97b18f3c03fc7382931cc169bbfa6fff78`，kit #26 为 `0d1462a2…`）同时列出上述两条，与本地 `dist/SHA256SUMS` 重算一致；`sha256sum -c` 2/2 通过（gh-proxy 抽验目录内）。
- **FIX-RESID 重打包（2026-09-23T17:16+08:00，历史）**：旧 bundle 30,477,923 B / `6d8c44802187929f904de86ccde1262061e3cb9f5de428b17b0fc0aed8c18d47` 内的 preview.24 平台包还是修复前托管（`Microsoft.OpenHarmony.Hosting.dll` 32,256 B）；该次重打包后 Ref.20.0/26.0 与 Runtime.20.0/26.0 均为 34,816 B / `d776b1d5811e28149bb095b77cf2f4b80049c52f04b5042c3a10271072083ff1`，另含重建的 `Microsoft.OpenHarmony.Maui.Graphics.dll`（16,384 B / `6b5de857…`），即 kit #18 的 bundle（30,484,382 B / `4ba913c6…`）。此后各版依次为：kit #19 = 30,482,709 B / `5e84fe21…`；kit #20 = 30,499,901 B / `ba43c2e8…`；kit #21 = 30,498,612 B / `41d94901…`（headless abc `13.0.1.0`）。
- **kit #21 重打包（2026-09-24，历史）**：bundle 30,498,612 B / `41d94901…`（130 条目）修复 headless 变体 abc（`24.0.0.0` 3,580 B → `13.0.1.0` **13,572 B** / `70a61636…`）并让 pack 模板 README 指向 `ARKTS_SHELL_VARIANT=headless`（`e995cef`）；hosting/Maui.Graphics 托管在 `1f7ef76` 重建（仅内嵌 source revision 变化）；UI/shell abc 211,032 B / `7d513f72…` 与宿主 211,872 B / `33baff42…` 未变。
- **kit #22 重打包（2026-09-24，历史）**：bundle 30,498,838 B / `04b96cec…`（130 条目）——原生宿主按需 dlopen/dlsym 重建（**215,968 B / `3332c8ac…`**，DT_NEEDED 收窄为 5）；UI/shell abc **212,952 B / `6e616f5b…`** 与 headless **15,608 B / `c72990c1…`** 按 DevEco 布局 `modelVersion 6.0.2` 重建；Sdk pack `targets/OpenHarmony.Hap.targets` = **46,213 B / `e4318436…`**（restool 生成 `resources.index`）；hosting/Maui.Graphics 在 `0f26b74` 重建（**35,840 B / `e588b655…`**、**16,384 B / `0604c536…`**）。发布后三处 release 新 bundle 逐字节一致。
- **kit #23 波次（2026-09-24，历史）**：bundle 与 #22 **逐字节相同**（`04b96cec…` / 30,498,838 B），该波**未重发 bundle、未更新 `sdk-ohos` 锚**。
- **kit #24 重打包（2026-09-24，历史）**：bundle **30,524,164 B / `d28578e2…`**（130 条目；6 个 feed nupkg 变化）：Sdk pack **344,301 B** 携带 payload-in-libs `targets/OpenHarmony.Hap.targets` = **57,438 B / `fcf54c97…`**、UI/shell abc **215,680 B / `0def57e0…`**、headless abc **18,308 B / `25ab7a9e…`**、宿主 **220,064 B / `19d9d4b4…`**；Ref.20/26 `18391 B`、Runtime.20/26 `26215 B`；hosting/Maui.Graphics 在 `8b162a1` 重建（**35,840 B / `2f9993cb…`**、**16,384 B / `f861e06e…`**）。
- **kit #25 重打包（2026-09-25，历史）**：bundle **30,487,575 B / `6c607c73…`**（130 条目）：Sdk pack **284,047 B** 携带 UI/shell abc **234,620 B / `34325332…`**、headless abc **18,532 B / `d7ec9ca7…`**、`targets/OpenHarmony.Hap.targets` = **94,123 B / `4b2a10be…`**、宿主 **236,448 B / `8fa24895…`**；Ref.20/26 `23,368 B`、Runtime.20/26 `31,193 B`；hosting/Maui.Graphics 在 `5ecd8a5` 重建（**47,616 B / `e4f6fade…`**、**16,384 B / `7a7c5531…`**；JSON 源生成 + AOT 入口点）。
- **kit #26 重打包（2026-09-26，历史）**：bundle **30,501,359 B / `7b9ccd6e…`**（130 条目，成员集与上版一致；6 个 feed nupkg 按设计变化）：Sdk pack **290,854 B**（was 284,047）新增 `tools/Microsoft.OpenHarmony.Tasks.dll` = **32,256 B / `28c47cbf…`**，`targets/OpenHarmony.Hap.targets` = **55,473 B / `2f2c234c…`**（TASK-MIG：任务体移出，只留 `UsingTask`/调用面），新增 `targets/OpenHarmony.PlatformItems.targets` = **3,918 B / `70ac714b…`**（PLAT-GAP：AspNetCore KFR `11.0.0-rc.1.26425.128` + `openharmony-*`→`linux-musl-*` 映射），`Sdk/Sdk.targets` = **5,736 B / `fd59a681…`**（默认 `RuntimeIdentifier=openharmony-arm64` + `EnableAppHostPackDownload=false`）；abc 与宿主与 #25 逐字节相同；Ref.20/26 `25,510 B`、Runtime.20/26 `33,334 B`；hosting/Maui.Graphics 在 `123a223`（P2-INTEROP 桥）/`7075b67` 重建（**55,808 B / `38f5a3d2…`**（was 47,616）、**16,384 B / `8de00efd…`**）。成员级对比：130=130、无增删，仅 6 个 feed nupkg 变化（BCL runtime pack 成员 386/386 内容一致，仅重打包 zip 元数据）。发布后经 API（by-id）与 gh-proxy 下载抽验：三处（`workload-latest`、`workload-1.0.0-preview.24`、SDK release）新 bundle 逐字节一致，`sha256sum -c` 通过；`sdk-ohos` 锚已更新并推送（见 §4）。
- **kit #27 重打包（2026-09-26，本轮）**：bundle **30,508,149 B / `bc30c65b…`**（130 条目，成员集与上版一致；6 个 feed nupkg 按设计变化）：Sdk pack **305,204 B**（was 290,854）携带 UI/shell abc **245,412 B / `0e31b619…`**（KIT-EXT2 Push/Account/Map 探测；was 234,620）、headless abc **18,532 B / `d7ec9ca7…`**（未变）、`targets/OpenHarmony.Hap.targets` = **57,750 B / `390ea180…`**（payload-zip opt-out pack 同步；was 55,473）、`targets/OpenHarmony.PlatformItems.targets` = **3,918 B / `70ac714b…`**（未变）、`Sdk/Sdk.targets` = **5,736 B / `fd59a681…`**（未变）、`tools/Microsoft.OpenHarmony.Tasks.dll` = **32,256 B / `28c47cbf…`**（未变）；Ref.20/26 `25,135 B`、Runtime.20/26 `32,953 B`；hosting/Maui.Graphics 在 `080f422`（marshal-off hosting）/ maui 切片 `a0a2c087` 重建（**55,296 B / `4c121725…`**（was 55,808）、**16,384 B / `01a09b32…`**）。发布后经 API（by-id）与 gh-proxy 下载抽验：三处（`workload-latest`、`workload-1.0.0-preview.24`、SDK release）新 bundle 逐字节一致，`sha256sum -c` 通过；`sdk-ohos` 锚已更新并推送（见 §4）。
- SDK release `v11.0.100-rc.1.26451.109-openharmony`（id **388357742**）：`https://github.com/springmin/sdk-ohos/releases/tag/v11.0.100-rc.1.26451.109-openharmony`；其上随 SDK 发布附带的 workload bundle 已同步为 kit #27 重打包（**30,508,149 B / `bc30c65b…`**，`SHA256SUMS` **212 B / `cf22fe1a…`**——本轮发布脚本把该 release 的合并 sums 从上一版 versioned-only 111 B / `b4f7de16…` 扩为两行（与 `workload-latest`/`preview.24` 同值）；变更资产 = bundle + `SHA256SUMS`，其余 33 项不变；SDKREL-27，2026-09-26）。SDK 包 `dotnet-sdk-11.0.100-rc.1.26451.109-openharmony-arm64.tar.gz` = 178,005,544 B / sha256 `f3a1bba4…`、runtime `10b7877f…`、selfsign `85284499…` 三锚逐字节不变；`sdk-ohos` 外锚已更新并推送 `f27b20f4cc..3eb480fb4b`（`versions.env`，`WORKLOAD_BUNDLE_SHA256 = bc30c65b…`；安装器测试 43/43 + hostfeed 10/10 + codesign 5/5）。

## 4. 五仓库分支 tip（2026-09-26 终检快照，远端分支 tip；已按 fetch/API 与远端 ref 核对）

| 仓库 | 分支 | 短哈希 | 备注 |
|---|---|---|---|
| `ohos-workload` | `master` | `75cdc26` | kit #27 发布链：批末 `fa8a28e`（`c89ed4a` 壳 Push/Account/Map 探针；`aa44caa` 12 个 kit sink；`b3510c1` NAPI 加固；`080f422` marshal-off hosting；`843d371`/`0b27ed1`/`18c9637` 交互套件与文档；`fa8a28e` payload-zip opt-out pack 同步）之上两笔发布波 `898f4a1`（verify-kit abc 重锚 245,412）与 `75cdc26`（CI maui pin `1a754753`→`a0a2c087`、ridgraph-sync sdk pin `97cad7c59a`→`f27b20f4cc`）；preflight 全绿（329/floor 309 + pixel），CI 5/5 success |
| `maui-ohos` | `feature/openharmony` | `a0a2c087` | MAUI 平台切片（Push/Account/Map 桥 + FIX-R1-MARSHAL-OFF 反向入口切片；CI 三 workflow pin 同值）|
| `sdk-ohos` | `feature/openharmony` | `3eb480fb4b` | SDK 与 release 宿主（bundle 外锚更新并推送 `f27b20f4cc..3eb480fb4b`，`WORKLOAD_BUNDLE_SHA256 = bc30c65b…`；安装器 43/43 + hostfeed 10/10 + codesign 5/5）|
| `runtime-ohos` | `feature/openharmony` | `909bbeb0532` | 本页 kit #27 刷新提交前的 tip（含 KIT-GAP/覆盖矩阵与 R1-INTERP 回填；本次文档提交会再前进一格）|
| `aspnetcore-ohos` | `feature/openharmony` | `eace90c8f` | aspnetcore 移植（fork 指南文档）|

## 5. 怎么校验（三步）与 tester-run.sh 一条命令

三步（手工路径）：

```sh
base=https://github.com/springmin/sdk-ohos/releases/download/device-test-kit
curl -L -O "$base/device-test-kit.tar.gz" -O "$base/device-test-kit.tar.gz.sha256"
sha256sum -c device-test-kit.tar.gz.sha256          # ① 整包锚定
tar xzf device-test-kit.tar.gz && cd device-test-kit
sha256sum -c SHA256SUMS                             # ② 包内 15/15（新 verify-kit 另做逐 hap 深度断言）
sh verify-kit.sh --expect-tree-digest 6abff90e69bcac4235791ce705f6851bc0ad67ba352619c1922d925977f347ca   # ③ 内容树绑定
```

一条命令（校验 + 安装 + 启动 + 录 30 秒 hilog，`tester-run.sh` v8 默认 dry-run，无设备不动作；需 `hdc`，多设备加 `--device <id>`；v8 另收集 app-lib 路径与 dlopen 证据（RM1）、bootstrap/rawfile 失败特征、payload 状态与逐 hap kit 自检（index/libs/`payload=yes|no`/abc）以及 exec-memory 证据，复用已校验摘要产出 kit 摘要（P16），并在发任何 `hdc` 命令前校验 bundle 名（A1），`--extra-probes` 可带 importprobe/importb 载荷）：

```sh
sh tester-run.sh --kit-tar ./device-test-kit.tar.gz \
  --expect-tree-digest 6abff90e69bcac4235791ce705f6851bc0ad67ba352619c1922d925977f347ca \
  --install --start --capture 30
```

## 6. 测试方两条签名路径（安装报 `9568344` 时二选一）

| 路径 | 测试方提供 | 交付方执行 |
|---|---|---|
| ① 重签（按你的 UDID） | `hdc shell bm get -u` 的 UDID（或按包内 `自签说明.md` 用 DevEco 自动签名自行完成） | `sh scripts/sign-for-device.sh <UDID>`（多设备逗号分隔） |
| ② 外部预签（用你的材料） | p7b + p12 + cer + keyAlias（华为材料亦可） | `sh scripts/sign-for-device.sh --external --profile <p7b> --key <p12> --cert <cer> --key-alias <alias> --pwd-input-mode --expect-udid 60CF7B27…`（UDID 换成目标设备；p7b 的 `debug-info.device-ids` 必须含它，fail closed）；华为材料可走 `scripts/sign-huawei.sh` |

根因：hap 内调试 profile 的 `debug-info.device-ids` 只含示例 UDID；重签/预签后哈希必变，以新产物随附的 `SHA256SUMS` 为准。kit #26 的 4 个已签 hap 为自签名（默认 `-signCode 1` 会重签 `libs/<abi>/*.so`），诊断 tarball 内的 hap 为陈旧签名或未签名，均需按 §5/自签说明重签。详见 `2026-09-19-ohos-signing-and-udid-guide.md`。

## 7. SDK 门控清单（快速参考，详见覆盖矩阵 §4）

- TextToSpeech — 本 SDK 无 `@kit.CoreSpeechKit` / `@ohos.ai.tts`（链路已接，sink 如实返回不可用）。
- Map — 本 SDK 无 MapKit。
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
