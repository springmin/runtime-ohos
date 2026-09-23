# OpenHarmony .NET/MAUI 交付物清单（2026-09-24 快照）

> **本页是静态快照**（文件名为创建日期；数值于 2026-09-24 随 kit #21 与 headless abc 修复的 workload bundle 重打包刷新）：只回答「截至该时点，当前交付物有哪些、数字是多少、去哪里取」。
> 所有数字在 2026-09-24 核对：本地文件重算 sha256 + GitHub release API digest 双向一致；任何重签、预签或重新打包都会改变哈希。
> kit 编号（#21）是团队跟踪口径，release 本身不带编号；以后续文档与 release 说明为准。

## 1. 当前 kit（kit #21，`device-test-kit` release，headless abc `13.0.1.0` 修复 + tester-run v6r2；tar.gz + sidecar 上传于 2026-09-24）

- 位置：`https://github.com/springmin/sdk-ohos/releases/tag/device-test-kit`（下载前缀 `https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/`）。
- `device-test-kit.tar.gz`：**115,971,128 B**，sha256 `cdb2a813bdddb6b0790062d7ced2458672cfef11b0b4e4604bffed2337580c50`。
- `device-test-kit.tar.gz.sha256` 边车（89 B）：内容 = tar.gz 哈希；边车自身 sha256 `c808074f2fd413afbaa756ac2bb4c1d49d9fb99ae56141d824b97e197fdf0a92`。
- 解压内容树摘要（tree digest，绑定解压后的内容而非仅 tar 包）：`3e9f46a17e4a44d3ae024bd8a250b2266b218aa9247fc85f1f646f2be29181d3`。
  验证：解压后在包内执行 `sh verify-kit.sh --expect-tree-digest 3e9f46a17e4a44d3ae024bd8a250b2266b218aa9247fc85f1f646f2be29181d3`。
- 镜像：`workload-latest` release 上的同名资产逐字节同值（大小、sha256 相同；tree digest 同值）。
- 包内 tester 文档**按设计不写死哈希**：9 个文本文件（8 文档 + `签名说明.txt`）的 64-hex 计数均为 0；校验一律以 release 说明「## Integrity」小节、`.tar.gz.sha256` 边车与随包 `SHA256SUMS` 为准。
- 本快照的本地复核：tree digest OK；`sha256sum -c SHA256SUMS` **15/15** 通过（5 hap + 9 文档 + `verify-kit.sh`）；发布侧 API digest 与本地同哈希重算一致；gh-proxy 下载端到端复验 KIT OK。
- kit #21 内容（全新解包实测）：5 个 hap 均带 `"libIsolation": true`（RM1：安装时注册模块级 `<bundle>/<module>` app-lib key）；`ets/modules.abc` = **211,032 B**、头 `13.0.1.0`（`7d513f72…`，H-C2 固定模板重建）；`libs/arm64-v8a/` 含 **14** 个 `.so`（12 个 .NET 运行时原生库 + `libopenharmonyhost.so` **215,968 B** / `e0df7c2bdca61556b39090a85d8055c27e437a782ceba54dbf178a2e68368b76`，pack 内为 211,872 B / `33baff42…` + `libc++_shared.so`）；`dotnet.zip` **253** 项且 **0** 个 `.so`（15,974,592/15,974,558 B）；`Microsoft.OpenHarmony.Hosting.dll` = **35,840 B** / `7f84f019b509931c22e487a334237569e6d98350b9ada71ac9c368fde18ee83d`（在 `1f7ef76` 随源修订重建，相对 kit #20 仅内嵌 source revision 变化）。
- 本版（kit #21 发布波次）另修复 **headless 变体 abc**（位于 workload bundle / SDK packs 的模板，不在 kit hap 内）：`modules.headless.abc` 旧 stub 3,580 B / `24.0.0.0`（超出设备 ark runtime）→ **13,572 B** / `70a616363d52be75c673823545d77e01d3fe6f9cbd2f775069a386e808bb162f` / `13.0.1.0`（`ohos-workload 4e5491d`），模板 README 指向 `ARKTS_SHELL_VARIANT=headless`（`e995cef`）。
- kit #21 包内 `签名说明.txt` 第三节的「PA1 重建壳的下一版 kit」句为**历史文案**（源已在 `ohos-workload c6a4cd95e` 修正，随下个 kit 生效；本 kit 不含该缺陷）；测试方判读以 `签名说明` 其余内容 + release notes 为准。
- kit 编号演进（团队跟踪口径，非连续）：#7（22 日凌晨）→ #10（入口 record）→ #11（abc `13.0.1.0`）→ #12（宿主 dlopen-only + 壳 `host` 守卫）→ #14（评审整改 + PI1 + UX 深化）→ #15（rawfile 资源桥）→ #16（宿主按两个 napi 名注册）→ #17（RM1 libIsolation repack）→ #18（安全/性能第一批）→ #19（启动/TLS/评审合规）→ #20（最终热点回填 H10/P16/P9/P10/P19）→ **#21（当前：headless abc `24.0.0.0` → `13.0.1.0` 修复 + tester-run v6r2 + slice pin `236d18a9`）**。
- release 最后更新 2026-09-24（kit #21 资产 + `tester-run.sh` v6r2）；`2026-09-21-ohos-final-status.md` §11 已同步到 kit #21，本页与之一致锚定当前 release。

## 2. `device-test-kit` release 上的全部资产（2026-09-24 快照，15 项）

| 资产 | 大小 (B) | sha256 | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz` | 115,971,128 | `cdb2a813bdddb6b0790062d7ced2458672cfef11b0b4e4604bffed2337580c50` | 当前 kit #21（headless abc `13.0.1.0` + tester-run v6r2） |
| `device-test-kit.tar.gz.sha256` | 89 | `c808074f2fd413afbaa756ac2bb4c1d49d9fb99ae56141d824b97e197fdf0a92` | 整包边车（内容 = 上一行哈希） |
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
| `new-features-device-checklist.md` | 51,825 | `7d923af9e8bb5b0d37e4e52c3e20f5d1f2ab56a83e64cbf3c180a944a46fbd35` | 本轮新功能 M1–M13 真机清单（2026-09-24 与仓库文档同步重传，kit #21 口径）|
| `tester-run.sh` | 60,429 | `a7db7d8c78ccdf4ac9d2112972e7739ac788a65772d4374cc8fcf54c7230d884` | v6r2（内嵌 script version 6，2026-09-24；仓库脚本 commit `8408a90`）：校验 + 安装 + 启动 + 30 s hilog + RM1 无重建 app-lib/dlopen 证据；发任何 hdc 命令前校验 bundle 名（A1）；复用已校验摘要产出 kit 摘要（P16） |

- 诊断资产对应关系：`dynpkg-haps.tar.gz` 为候选矩阵中最强单候选（动态加载 + `runtimeOnly.packages`/`file:` 包声明；随包 5 hap 带 libIsolation、abc 新增 host-binding `.record libopenharmonyhost.so`、入口 record 保持已确认形式）；`normalized-haps.tar.gz` 的 normalized 入口 record 的设备解析未证。`importb`/`importd` 分别对应静态命名空间与动态加载实验；三个 `importprobe` hap 无 .NET 载荷，只测三种 import 形式的路由。P1–P4 仍用于 dlopen/缺库/宿主入口/运行时类崩溃的五层定位。
- 全部数字均为 2026-09-24 读取：release API digest 与本地重算一致（kit、bundle、dynpkg、normalized、importb、importd、tester-run.sh）；本轮 kit #21 变化 4 项：`device-test-kit.tar.gz`/`.sha256` sidecar/`tester-run.sh` 三项 + `checklist`（2026-09-24 与仓库文档同步重传）；其余 **11 项**（探针 hap、诊断 tarball、dynpkg/importb/importd/normalized）与上一快照逐字节同值（`dtk_assets_unchanged=11`）。`importprobe` a/b/c 的 API digest 与实验文档记录一致。诊断 tarball 内的 hap 均未签名或为陈旧签名，测试方需重签（§6）。

## 3. Workload bundle（versioned + rolling + SDK release）

| 资产 | 大小 (B) | sha256 | 位置 |
|---|---|---|---|
| `openharmony-workload-1.0.0-preview.24.tar.gz` | 30,498,612 | `41d949019c86864d8a9d96d1aa4aab730f44d0711351e3c539a24899e9084321` | `workload-1.0.0-preview.24` / `workload-latest` release |
| `openharmony-workload-latest.tar.gz` | 30,498,612 | `41d949019c86864d8a9d96d1aa4aab730f44d0711351e3c539a24899e9084321` | `workload-latest` release（与 versioned 逐字节一致） |

- 两名字指向同一份字节；`SHA256SUMS`（212 B，自身 sha256 `3fc29faf607e47339b0662c256cfbaa38c6cee4b3e5bdb90054f7b5cca31e512`）同时列出上述两条，与本地 `dist/SHA256SUMS` 重算一致；`sha256sum -c` 2/2 通过。
- **FIX-RESID 重打包（2026-09-23T17:16+08:00，历史）**：旧 bundle 30,477,923 B / `6d8c44802187929f904de86ccde1262061e3cb9f5de428b17b0fc0aed8c18d47` 内的 preview.24 平台包还是修复前托管（`Microsoft.OpenHarmony.Hosting.dll` 32,256 B）；该次重打包后 Ref.20.0/26.0 与 Runtime.20.0/26.0 均为 34,816 B / `d776b1d5811e28149bb095b77cf2f4b80049c52f04b5042c3a10271072083ff1`，另含重建的 `Microsoft.OpenHarmony.Maui.Graphics.dll`（16,384 B / `6b5de857fb8f8bd3f19163dce31e99a4ca91f5ccddf907bfe0dc602b9b6c14d6`），即 kit #18 的 bundle（30,484,382 B / `4ba913c6…`）。此后各版依次为：kit #19 = 30,482,709 B / `5e84fe21…`；kit #20 = 30,499,901 B / `ba43c2e8…`。
- **kit #21 重打包（2026-09-24）**：新 bundle 30,498,612 B / `41d94901…`（130 条目）修复 headless 变体 abc（`24.0.0.0` 3,580 B → `13.0.1.0` **13,572 B** / `70a616363d52be75c673823545d77e01d3fe6f9cbd2f775069a386e808bb162f`）并让 pack 模板 README 指向 `ARKTS_SHELL_VARIANT=headless`（`e995cef`）；hosting/Maui.Graphics 托管在 `1f7ef76` 重建（仅内嵌 source revision 变化：`7bad00b8`/`9a414ce4` → `7f84f019`/`8ae4d394`；无源码变更）；UI/shell abc 211,032 B / `7d513f72…` 与宿主 211,872 B / `33baff42…` 未变。发布后经 API（by-id）与 gh-proxy 下载抽验：三处（`workload-latest`、`workload-1.0.0-preview.24`、SDK release）新 bundle 逐字节一致，`sha256sum -c` 各 2/2 通过。
- SDK release `v11.0.100-rc.1.26451.109-openharmony`（id **388357742**）：`https://github.com/springmin/sdk-ohos/releases/tag/v11.0.100-rc.1.26451.109-openharmony`；其上随 SDK 发布附带的 workload bundle 已同步为 kit #21 重打包（**30,498,612 B / `41d94901…`**，`SHA256SUMS` 212 B / `3fc29faf…`；变更资产 = bundle + `SHA256SUMS`，其余 33 项不变；SDKREL-21，2026-09-24）。SDK 包 `dotnet-sdk-11.0.100-rc.1.26451.109-openharmony-arm64.tar.gz` = 178,005,544 B / sha256 `f3a1bba4fd712db5ae231bb4e65cd10ca50c8acb4f0a4d8650681f66c1772c60`、runtime `10b7877f…`、selfsign `85284499…` 三锚逐字节不变，与 `eng/ohos-install/versions.env` 一致。

## 4. 五仓库分支 tip（2026-09-24 终检快照，远端分支 tip；已按 fetch/API 与远端 ref 核对）

| 仓库 | 分支 | 短哈希 | 备注 |
|---|---|---|---|
| `ohos-workload` | `master` | `c6a4cd95e` | 宿主/壳/脚本/套件与发布链（headless 变体 abc 重建 `4e5491d`、tester-run v6 `8408a90`、模板 README `e995cef`、pin `236d18a9`；tip 清理签名说明中的过期指引） |
| `maui-ohos` | `feature/openharmony` | `236d18a99` | MAUI 平台切片（文档基线刷新到 315/floor 295；kit #21 pin） |
| `sdk-ohos` | `feature/openharmony` | `821330d55` | SDK 与 release 宿主（D-1..D-6/H-C1 安装器加固；bundle 外锚已入库并推送 `821330d55e`，`versions.env` 四锚含 `WORKLOAD_BUNDLE_SHA256`） |
| `runtime-ohos` | `feature/openharmony` | `5355fbf3d6a` | 本页刷新提交前的 tip（本次文档提交会再前进一格） |
| `aspnetcore-ohos` | `feature/openharmony` | `eace90c8f` | aspnetcore 移植 |

## 5. 怎么校验（三步）与 tester-run.sh 一条命令

三步（手工路径）：

```sh
base=https://github.com/springmin/sdk-ohos/releases/download/device-test-kit
curl -L -O "$base/device-test-kit.tar.gz" -O "$base/device-test-kit.tar.gz.sha256"
sha256sum -c device-test-kit.tar.gz.sha256          # ① 整包锚定
tar xzf device-test-kit.tar.gz && cd device-test-kit
sha256sum -c SHA256SUMS                             # ② 包内 15/15
sh verify-kit.sh --expect-tree-digest 3e9f46a17e4a44d3ae024bd8a250b2266b218aa9247fc85f1f646f2be29181d3   # ③ 内容树绑定
```

一条命令（校验 + 安装 + 启动 + 录 30 秒 hilog，`tester-run.sh` 默认 dry-run，无设备不动作；需 `hdc`，多设备加 `--device <id>`；v6r2 另收集 app-lib 路径与 dlopen 证据（RM1）、复用已校验摘要产出 kit 摘要（P16），并在发任何 `hdc` 命令前校验 bundle 名（A1），`--extra-probes` 可带 importprobe/importb 载荷）：

```sh
sh tester-run.sh --kit-tar ./device-test-kit.tar.gz \
  --expect-tree-digest 3e9f46a17e4a44d3ae024bd8a250b2266b218aa9247fc85f1f646f2be29181d3 \
  --install --start --capture 30
```

## 6. 测试方两条签名路径（安装报 `9568344` 时二选一）

| 路径 | 测试方提供 | 交付方执行 |
|---|---|---|
| ① 重签（按你的 UDID） | `hdc shell bm get -u` 的 UDID（或按包内 `自签说明.md` 用 DevEco 自动签名自行完成） | `sh scripts/sign-for-device.sh <UDID>`（多设备逗号分隔） |
| ② 外部预签（用你的材料） | p7b + p12 + cer + keyAlias（华为材料亦可） | `sh scripts/sign-for-device.sh --external --profile <p7b> --key <p12> --cert <cer> --key-alias <alias> --pwd-input-mode --expect-udid 60CF7B27…`（UDID 换成目标设备；p7b 的 `debug-info.device-ids` 必须含它，fail closed）；华为材料可走 `scripts/sign-huawei.sh` |

根因：hap 内调试 profile 的 `debug-info.device-ids` 只含示例 UDID；重签/预签后哈希必变，以新产物随附的 `SHA256SUMS` 为准。kit #21 的 4 个已签 hap 为自签名（默认 `-signCode 1` 会重签 `libs/<abi>/*.so`），诊断 tarball 内的 hap 为陈旧签名或未签名，均需按 §5/自签说明重签。详见 `2026-09-19-ohos-signing-and-udid-guide.md`。

## 7. SDK 门控清单（快速参考，详见覆盖矩阵 §4）

- TextToSpeech — 本 SDK 无 `@kit.CoreSpeechKit` / `@ohos.ai.tts`（链路已接，sink 如实返回不可用）。
- Map — 本 SDK 无 MapKit。
- 系统分享面板 / 多文件分享 — 无 Share Kit，一个 Want 仅单个 uri 槽（文本 + 单文件可用，多文件 no-op）。
- BLE GATT client — `connection.GattClientDevice` 未导出（经典蓝牙发现可用）。
- Hot Reload — hdc 策略硬阻塞。
- arm32 — 无 runtime packs、无 32 位设备。

## 8. 接下来读什么

| 文档 | 用途 |
|---|---|
| `2026-09-22-ohos-startup-crash-rootcause.md` | 启动崩溃根因 §5b/§5c（kit #10–#12）与 kit #14 里程碑/黑屏阻塞 §5d/§5e |
| `2026-09-23-ohos-napi-import-fix-playbook.md` | 黑屏阻塞 #4 的候选修复 A/B/C、决策表与回滚 |
| `2026-09-23-ohos-native-import-experiment.md` | importprobe a/b/c 三形式实验 + RM1 lib-isolation 修复与无重建诊断 |
| `2026-09-21-ohos-crash-probes.md` | P1–P4 启动崩溃探针与五层定位决策表 |
| `2026-09-21-ohos-device-crash-diagnostics.md` | 崩溃最小取证（hilog/faultlog/status）与 A/B 清单 |
| `2026-09-21-ohos-device-report-template.md` | 真机回传一页模板（机器可解析） |
| `2026-09-22-ohos-new-features-device-checklist.md` | 本轮新功能 M1–M13 真机验证清单（即 release 上的 `new-features-device-checklist.md`；kit #21 已同步） |
| `2026-09-22-ohos-maui-coverage-matrix.md` | MAUI 覆盖矩阵与 SDK 阻塞/Top-10 缺口 |
| `2026-09-21-ohos-security-scan.md` | 五仓库安全扫描（第一轮；PASS WITH FINDINGS，23 项已处置） |
| `2026-09-23-ohos-security-scan-2.md` | 五仓库安全扫描 #2（16 条候选，16 修；kit #21 已含全部修复提交；#19–#21 追加 headless abc、bundle 外锚、TLS H-C3 等） |
| `2026-09-23-ohos-performance-scan.md` | 五仓库性能扫描（31 热点，29 修 + 2 项有意保留；kit #21 已含已修项） |
| `2026-09-23-ohos-pr-review-compliance.md` | 上游 PR 评审规则遵循（R1–R11、硬违例 0、修复提交与复审计证据；含 #19–#21 追加修复） |
| `2026-09-23-ohos-upstream-reply-drafts.md` | 未发送的上游回复/催评草稿（#132953、#132827、#132866；arcade#17608 一条已随其合并作废），等审批 |
| `2026-09-23-ohos-tls-policy.md` | TLS 加固策略（H-C3 绝对路径 `dlopen` + 静态链接开关）与设备负向验证 |
| `2026-09-21-ohos-final-status.md` | 一页版最终状态（交付主线、批次、真机待证项、§11 收官；已同步 kit #21） |
| `README.md` | `docs/plans` 文档索引（本目录入口） |
