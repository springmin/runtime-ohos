# OpenHarmony .NET/MAUI 交付物清单（2026-09-23 快照）

> **本页是静态快照**（文件名为创建日期；数值于 2026-09-23 随 kit #17 刷新）：只回答「截至该时点，当前交付物有哪些、数字是多少、去哪里取」。
> 所有数字在 2026-09-23 核对：本地文件重算 sha256 + GitHub release API digest 双向一致；任何重签、预签或重新打包都会改变哈希。
> kit 编号（#17）是团队跟踪口径，release 本身不带编号；以后续文档与 release 说明为准。

## 1. 当前 kit（kit #17，`device-test-kit` release，RM1 lib-isolation repack；tar.gz + sidecar 上传于 2026-09-23T11:47+08:00）

- 位置：`https://github.com/springmin/sdk-ohos/releases/tag/device-test-kit`（下载前缀 `https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/`）。
- `device-test-kit.tar.gz`：**115,822,672 B**，sha256 `e09a5b6e6a678629c1ce928d4c9dce5a354d6ace708b27ba62e6d126ecdf3d8a`。
- `device-test-kit.tar.gz.sha256` 边车（89 B）：内容 = tar.gz 哈希；边车自身 sha256 `094e790fa6df3f7fca0e52b45c559b050efea0317bee3b47d7329656259963e0`。
- 解压内容树摘要（tree digest，绑定解压后的内容而非仅 tar 包）：`d5e624dcff89a176dc3b02ba3ceb8ac87fe1f7bfe7a65a91a6171a4acea0659b`。
  验证：解压后在包内执行 `sh verify-kit.sh --expect-tree-digest d5e624dcff89a176dc3b02ba3ceb8ac87fe1f7bfe7a65a91a6171a4acea0659b`。
- 镜像：`workload-latest` release 上的同名资产逐字节同值（大小、sha256 相同；tree digest 同值）。
- 包内 tester 文档**按设计不写死哈希**：9 个文本文件（8 文档 + `签名说明.txt`）的 64-hex 计数均为 0；校验一律以 release 说明「## Integrity」小节、`.tar.gz.sha256` 边车与随包 `SHA256SUMS` 为准。
- 本快照的本地复核：tree digest OK；`sha256sum -c SHA256SUMS` **15/15** 通过（5 hap + 9 文档 + `verify-kit.sh`）；发布侧 API digest 与本地同哈希重算一致。
- kit #17 内容（全新解包实测）：5 个 hap 均带 `"libIsolation": true`（RM1：安装时注册模块级 `<bundle>/<module>` app-lib key）；`ets/modules.abc` = **204,780 B**、头 `13.0.1.0`（非标准化壳 + 静态 host import，入口 record 为 kit #10 已确认形式）；`libs/arm64-v8a/` 含 **14** 个 `.so`（12 个 .NET 运行时原生库 + `libopenharmonyhost.so` 199,584 B 别名宿主 + `libc++_shared.so`）；`dotnet.zip` **253** 项且 **0** 个 `.so`。
- kit 编号演进（团队跟踪口径，非连续）：#7（22 日凌晨）→ #10（入口 record）→ #11（abc `13.0.1.0`）→ #12（宿主 dlopen-only + 壳 `host` 守卫）→ #14（评审整改 + PI1 + UX 深化；真机崩溃清零/启动存活里程碑——kit #14/#16 口径）→ #15（rawfile 资源桥）→ #16（宿主按两个 napi 名注册）→ **#17（当前：RM1 libIsolation repack）**。
- release 最后更新 2026-09-23T13:35+08:00（`tester-run.sh` v3 资产）；与旧文档的口径差异：`2026-09-21-ohos-final-status.md` 记录到 kit #14（以该页 §11 为准），本页锚定其后刷新的当前 release（跟踪编号 #17），哈希以当前 release 为准。

## 2. `device-test-kit` release 上的全部资产（2026-09-23 快照，15 项）

| 资产 | 大小 (B) | sha256 | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz` | 115,822,672 | `e09a5b6e6a678629c1ce928d4c9dce5a354d6ace708b27ba62e6d126ecdf3d8a` | 当前 kit #17（RM1 libIsolation） |
| `device-test-kit.tar.gz.sha256` | 89 | `094e790fa6df3f7fca0e52b45c559b050efea0317bee3b47d7329656259963e0` | 整包边车（内容 = 上一行哈希） |
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
| `new-features-device-checklist.md` | 36,911 | `0ee2f1eaeb59ba9cc601e38fab9357e1df0a4069a992cdf6ff84c678f4d00569` | 本轮新功能 M1–M10 真机清单 |
| `tester-run.sh` | 53,839 | `193409d863ce3f5c256e90e3e5904c0abc5908d6d62d48bb5c9a75053c6f1a1d` | v3：校验 + 安装 + 启动 + 30 s hilog + app-lib/dlopen 证据收集 |

- 诊断资产对应关系：`dynpkg-haps.tar.gz` 为候选矩阵中最强单候选（动态加载 + `runtimeOnly.packages`/`file:` 包声明；随包 5 hap 带 libIsolation、abc 新增 host-binding `.record libopenharmonyhost.so`、入口 record 保持已确认形式）；`normalized-haps.tar.gz` 的 normalized 入口 record 的设备解析未证。`importb`/`importd` 分别对应静态命名空间与动态加载实验；三个 `importprobe` hap 无 .NET 载荷，只测三种 import 形式的路由。P1–P4 仍用于 dlopen/缺库/宿主入口/运行时类崩溃的五层定位。
- 全部数字均为 2026-09-23 读取：release API digest 与本地重算一致（kit、bundle、dynpkg、normalized、importb、importd、tester-run.sh）；`importprobe` a/b/c 的 API digest 与实验文档记录一致。诊断 tarball 内的 hap 均未签名或为陈旧签名，测试方需重签（§6）。

## 3. Workload bundle（versioned + rolling + SDK release）

| 资产 | 大小 (B) | sha256 | 位置 |
|---|---|---|---|
| `openharmony-workload-1.0.0-preview.24.tar.gz` | 30,477,923 | `6d8c44802187929f904de86ccde1262061e3cb9f5de428b17b0fc0aed8c18d47` | `workload-1.0.0-preview.24` / `workload-latest` release；SDK release `v11.0.100-rc.1.26451.109-openharmony` |
| `openharmony-workload-latest.tar.gz` | 30,477,923 | `6d8c44802187929f904de86ccde1262061e3cb9f5de428b17b0fc0aed8c18d47` | `workload-latest` release（与 versioned 逐字节一致） |

- 两名字指向同一份字节；`SHA256SUMS`（212 B，自身 sha256 `7d2297d0cb0f1ef9f58abd24bb126fdcbb27946401b25e7738194c2735781733`）同时列出上述两条，与本地 `dist/SHA256SUMS` 重算一致；本地 `dist/` 与 `.feed/` 的 bundle 重算 sha256 与 API digest 一致。
- SDK release `v11.0.100-rc.1.26451.109-openharmony`：`https://github.com/springmin/sdk-ohos/releases/tag/v11.0.100-rc.1.26451.109-openharmony`，其上的 bundle 资产（preview.24）与 `SHA256SUMS` digest 与上表一致；同 release 的 SDK 包 `dotnet-sdk-11.0.100-rc.1.26451.109-openharmony-arm64.tar.gz` = 178,005,544 B / sha256 `f3a1bba4fd712db5ae231bb4e65cd10ca50c8acb4f0a4d8650681f66c1772c60`（仅 API digest 读取，未本地复核）。

## 4. 五仓库分支 tip（2026-09-23 快照，`git ls-remote` 远端值）

| 仓库 | 分支 | 短哈希 | 备注 |
|---|---|---|---|
| `ohos-workload` | `master` | `49cd70f3d1` | 宿主/壳/脚本/套件与发布链（libIsolation 模板 + tester-run v3 诊断） |
| `maui-ohos` | `feature/openharmony` | `11e9751e5c` | MAUI 平台切片（远端 tip；本工作区 checkout `7f712ecb`，未 fetch 到该 tip） |
| `sdk-ohos` | `feature/openharmony` | `f2ada2dabc` | SDK 与 release 宿主 |
| `runtime-ohos` | `feature/openharmony` | `520f852eba` | 本清单提交前的 tip（本页文档提交会前进一格） |
| `aspnetcore-ohos` | `feature/openharmony` | `ad9603db67` | aspnetcore 移植 |

## 5. 怎么校验（三步）与 tester-run.sh 一条命令

三步（手工路径）：

```sh
base=https://github.com/springmin/sdk-ohos/releases/download/device-test-kit
curl -L -O "$base/device-test-kit.tar.gz" -O "$base/device-test-kit.tar.gz.sha256"
sha256sum -c device-test-kit.tar.gz.sha256          # ① 整包锚定
tar xzf device-test-kit.tar.gz && cd device-test-kit
sha256sum -c SHA256SUMS                             # ② 包内 15/15
sh verify-kit.sh --expect-tree-digest d5e624dcff89a176dc3b02ba3ceb8ac87fe1f7bfe7a65a91a6171a4acea0659b   # ③ 内容树绑定
```

一条命令（校验 + 安装 + 启动 + 录 30 秒 hilog，`tester-run.sh` 默认 dry-run，无设备不动作；需 `hdc`，多设备加 `--device <id>`；v3 另收集 app-lib 路径与 dlopen 证据，`--extra-probes` 可带 importprobe/importb 载荷）：

```sh
sh tester-run.sh --kit-tar ./device-test-kit.tar.gz \
  --expect-tree-digest d5e624dcff89a176dc3b02ba3ceb8ac87fe1f7bfe7a65a91a6171a4acea0659b \
  --install --start --capture 30
```

## 6. 测试方两条签名路径（安装报 `9568344` 时二选一）

| 路径 | 测试方提供 | 交付方执行 |
|---|---|---|
| ① 重签（按你的 UDID） | `hdc shell bm get -u` 的 UDID（或按包内 `自签说明.md` 用 DevEco 自动签名自行完成） | `sh scripts/sign-for-device.sh <UDID>`（多设备逗号分隔） |
| ② 外部预签（用你的材料） | p7b + p12 + cer + keyAlias（华为材料亦可） | `sh scripts/sign-for-device.sh --external --profile <p7b> --key <p12> --cert <cer> --key-alias <alias> --expect-udid <UDID>`；华为材料可走 `scripts/sign-huawei.sh` |

根因：hap 内调试 profile 的 `debug-info.device-ids` 只含示例 UDID；重签/预签后哈希必变，以新产物随附的 `SHA256SUMS` 为准。kit #17 的 4 个已签 hap 为自签名（默认 `-signCode 1` 会重签 `libs/<abi>/*.so`），诊断 tarball 内的 hap 为陈旧签名或未签名，均需按 §5/自签说明重签。详见 `2026-09-19-ohos-signing-and-udid-guide.md`。

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
| `2026-09-22-ohos-new-features-device-checklist.md` | 本轮新功能 M1–M10 真机验证清单（即 release 上的 `new-features-device-checklist.md`） |
| `2026-09-22-ohos-maui-coverage-matrix.md` | MAUI 覆盖矩阵与 SDK 阻塞/Top-10 缺口 |
| `2026-09-21-ohos-security-scan.md` | 五仓库安全扫描（PASS WITH FINDINGS，23 项已处置） |
| `2026-09-21-ohos-final-status.md` | 一页版最终状态（交付主线、批次、真机待证项、§11 收官） |
| `README.md` | `docs/plans` 文档索引（本目录入口） |
