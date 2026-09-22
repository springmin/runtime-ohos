# OpenHarmony .NET/MAUI 交付物清单（2026-09-22 快照）

> **本页是 2026-09-22 的静态快照，不会再维护**：只回答「截至该时点，当前交付物有哪些、数字是多少、去哪里取」。
> 所有数字在 2026-09-22 核对：本地文件重算 sha256 + GitHub release API digest 双向一致；任何重签、预签或重新打包都会改变哈希。
> kit 编号（#9）是团队跟踪口径，release 本身不带编号；以后续文档与 release 说明为准。

## 1. 当前 kit（kit #9，`device-test-kit` release，2026-09-22T02:27Z 刷新）

- 位置：`https://github.com/springmin/sdk-ohos/releases/tag/device-test-kit`（下载前缀 `https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/`）。
- `device-test-kit.tar.gz`：**114,387,779 B**，sha256 `4bf775e1bf1019335061a580c435e7260263c4bdf374968eee803463639001bc`。
- `device-test-kit.tar.gz.sha256` 边车（89 B）：内容 = tar.gz 哈希；边车自身 sha256 `dc244decd88965b5580f71473bedfc6ca7521a9a1c87b1df3cdbd01caeb6ea2b`。
- 解压内容树摘要（tree digest，绑定解压后的内容而非仅 tar 包）：`2257d74f5d25a07258f798708b70c0d10f70bf6651192653fbeb57f3545cc269`。
  验证：解压后在包内执行 `sh verify-kit.sh --expect-tree-digest 2257d74f5d25a07258f798708b70c0d10f70bf6651192653fbeb57f3545cc269`。
- 镜像：`workload-latest` release 上的同名资产逐字节同值（大小、sha256 相同；tree digest 同值）。
- 包内 tester 文档**按设计不写死哈希**：校验一律以 release 说明「## Integrity」小节、`.tar.gz.sha256` 边车与随包 `SHA256SUMS` 为准。
- 本快照的本地复核：tree digest OK；`sha256sum -c SHA256SUMS` **14/14** 通过（5 hap + 8 文档 + `verify-kit.sh`）；包内文档 64-hex 计数 0。
- 与旧文档的口径差异：`2026-09-21-ohos-final-status.md` / 设备清单里的 kit #7 指 2026-09-22T01:01Z 快照；本页锚定其后 02:27Z 刷新的当前 release（跟踪编号 #9），哈希以当前 release 为准。

## 2. `device-test-kit` release 上的全部资产（2026-09-22 快照）

| 资产 | 大小 (B) | sha256 |
|---|---|---|
| `device-test-kit.tar.gz` | 114,387,779 | `4bf775e1bf1019335061a580c435e7260263c4bdf374968eee803463639001bc` |
| `device-test-kit.tar.gz.sha256` | 89 | `dc244decd88965b5580f71473bedfc6ca7521a9a1c87b1df3cdbd01caeb6ea2b` |
| `tester-run.sh` | 32,226 | `f02b0d40daf625bf8a8d1726f6edf58fc49291d7bea996970b8f5b8f6a06cf8d` |
| `new-features-device-checklist.md` | 36,911 | `0ee2f1eaeb59ba9cc601e38fab9357e1df0a4069a992cdf6ff84c678f4d00569` |
| `hello-mauiapp-probe1-unsigned.hap`（P1 纯壳） | 11,988 | `92ef933cf7e0eadce1b415f67362dbba0f533dfff8cbbde89ee0eb6c4dcbeac4` |
| `hello-mauiapp-probe2-unsigned.hap`（P2 宿主 dlopen） | 178,492 | `70bbc687ba1f131185d72eae6b7dfaddf934d8a296726c792385b901eac9d7b0` |
| `hello-mauiapp-probe3-unsigned.hap`（P3 宿主入口/dlsym） | 186,002 | `5727e00f11c960b060628441b6119702027aa38414d25ddb0e7a4ea823486f3a` |
| `hello-mauiapp-probe4-unsigned.hap`（P4 逐依赖） | 177,466 | `209c8b10de4dd963a5f454c2586fb294c57fea22828856fd799289d8d62303fc` |

## 3. Workload bundle（versioned + rolling + SDK release）

| 资产 | 大小 (B) | sha256 | 位置 |
|---|---|---|---|
| `openharmony-workload-1.0.0-preview.24.tar.gz` | 30,406,412 | `01c782edfe8d556ebd993e509f3c766054e4a551dbeefbe09ce3f729f84c4b51` | `workload-latest` release；SDK release `v11.0.100-rc.1.26451.109-openharmony` |
| `openharmony-workload-latest.tar.gz` | 30,406,412 | `01c782edfe8d556ebd993e509f3c766054e4a551dbeefbe09ce3f729f84c4b51` | `workload-latest` release（与 versioned 逐字节一致） |

- 两名字指向同一份字节；`workload-latest` 上的 `SHA256SUMS`（212 B，自身 sha256 `fea1683c97bcee38054418ac7bc879816e89c3fd925294047d0cfc1d4649710c`）同时列出上述两条，与本地 `dist/SHA256SUMS` 重算一致。
- SDK release `v11.0.100-rc.1.26451.109-openharmony`：`https://github.com/springmin/sdk-ohos/releases/tag/v11.0.100-rc.1.26451.109-openharmony`，其上的 bundle 资产 digest 与上表一致；同 release 的 SDK 包 `dotnet-sdk-11.0.100-rc.1.26451.109-openharmony-arm64.tar.gz` = 178,005,544 B / sha256 `f3a1bba4fd712db5ae231bb4e65cd10ca50c8acb4f0a4d8650681f66c1772c60`（仅 API digest 读取，未本地复核）。

## 4. 五仓库分支 tip（2026-09-22 快照，`git ls-remote` 与本地 `rev-parse` 一致）

| 仓库 | 分支 | 短哈希 | 备注 |
|---|---|---|---|
| `ohos-workload` | `master` | `a48d6ee` | 宿主/壳/脚本/套件与发布链 |
| `maui-ohos` | `feature/openharmony` | `6a4062b` | MAUI 平台切片 |
| `sdk-ohos` | `feature/openharmony` | `9ad6a1f` | SDK 与 release 宿主 |
| `runtime-ohos` | `feature/openharmony` | `5e29a38` | 本清单提交前的 tip（本页文档提交会前进一格） |
| `aspnetcore-ohos` | `feature/openharmony` | `ad9603d` | aspnetcore 移植 |

## 5. 怎么校验（三步）与 tester-run.sh 一条命令

三步（手工路径）：

```sh
base=https://github.com/springmin/sdk-ohos/releases/download/device-test-kit
curl -L -O "$base/device-test-kit.tar.gz" -O "$base/device-test-kit.tar.gz.sha256"
sha256sum -c device-test-kit.tar.gz.sha256          # ① 整包锚定
tar xzf device-test-kit.tar.gz && cd device-test-kit
sha256sum -c SHA256SUMS                             # ② 包内 14/14
sh verify-kit.sh --expect-tree-digest 2257d74f5d25a07258f798708b70c0d10f70bf6651192653fbeb57f3545cc269   # ③ 内容树绑定
```

一条命令（校验 + 安装 + 启动 + 录 30 秒 hilog，`tester-run.sh` 默认 dry-run，无设备不动作；需 `hdc`，多设备加 `--device <id>`）：

```sh
sh tester-run.sh --kit-tar ./device-test-kit.tar.gz \
  --expect-tree-digest 2257d74f5d25a07258f798708b70c0d10f70bf6651192653fbeb57f3545cc269 \
  --install --start --capture 30
```

## 6. 测试方两条签名路径（安装报 `9568344` 时二选一）

| 路径 | 测试方提供 | 交付方执行 |
|---|---|---|
| ① 重签（按你的 UDID） | `hdc shell bm get -u` 的 UDID（或按包内 `自签说明.md` 用 DevEco 自动签名自行完成） | `sh scripts/sign-for-device.sh <UDID>`（多设备逗号分隔） |
| ② 外部预签（用你的材料） | p7b + p12 + cer + keyAlias（华为材料亦可） | `sh scripts/sign-for-device.sh --external --profile <p7b> --key <p12> --cert <cer> --key-alias <alias> --expect-udid <UDID>`；华为材料可走 `scripts/sign-huawei.sh` |

根因：hap 内调试 profile 的 `debug-info.device-ids` 只含示例 UDID；重签/预签后哈希必变，以新产物随附的 `SHA256SUMS` 为准。详见 `2026-09-19-ohos-signing-and-udid-guide.md`。

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
| `2026-09-21-ohos-crash-probes.md` | P1–P4 启动崩溃探针与五层定位决策表 |
| `2026-09-21-ohos-device-crash-diagnostics.md` | 崩溃最小取证（hilog/faultlog/status）与 A/B 清单 |
| `2026-09-21-ohos-device-report-template.md` | 真机回传一页模板（机器可解析） |
| `2026-09-22-ohos-new-features-device-checklist.md` | 本轮新功能 M1–M10 真机验证清单（即 release 上的 `new-features-device-checklist.md`） |
| `2026-09-22-ohos-maui-coverage-matrix.md` | MAUI 覆盖矩阵与 SDK 阻塞/Top-10 缺口 |
| `2026-09-21-ohos-security-scan.md` | 五仓库安全扫描（PASS WITH FINDINGS，23 项已处置） |
| `2026-09-21-ohos-final-status.md` | 一页版最终状态（交付主线、批次、真机待证项） |
| `README.md` | `docs/plans` 文档索引（本目录入口） |
