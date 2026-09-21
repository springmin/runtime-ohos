# OpenHarmony .NET/MAUI 移植最终状态（2026-09-21）

> 一页版收官状态：五仓库（`runtime-ohos` 文档、`ohos-workload` 宿主/壳/脚本/套件、`maui-ohos` 切片、
> `sdk-ohos` 发布、`aspnetcore-ohos`）截至 **2026-09-22 00:25（CST）** 可核实的事实（含 9 月 21 日晚间真机跟进与 22 日凌晨 kit #5 / 探针 P1–P4 更新，见 §5、§10）。
> 数字均来自仓库提交、审计报告与 GitHub 实测读取；无法读取或未落名的一律标注，不做推测。
> 详细依据见主审计报告 `docs/plans/2026-09-19-ohos-code-audit.md`（§1–§37）与索引 `docs/plans/README.md`。

## 1. 交付主线：第 1–3 项与已解除的受限项

| 项 | 内容 | 状态 | 依据 |
|---|---|---|---|
| 主线 1 | 弹层 / Swipe / ToolbarItem / SwipeView / RefreshView | ✅ 完成并验证 | 交接状态 §1 |
| 主线 2 | Sensor（Accelerometer / Gyroscope / Shake）与 Notification（宿主→NAPI→ArkTS） | ✅ 完成并验证 | 交接状态 §1 |
| 主线 3 | 相机拍摄（picker 管线 + 壳内 cameraPicker） | ✅ 完成并验证 | 交接状态 §1 |
| 受限解除 | `SwipeItem.Invoked`、Pointer 手势、真实悬停、Pinch（宿主直算） | ✅ 已实现并有套件证据 | 交接状态 §1、maui-ohos `1f8ee9c5` 等 |
| 受限解除 | Launcher / Browser / Share 的“受限”标签（AbilityKit startAbility 桥） | ✅ 转为正常能力路径 | 审计 §5b 第 2 项、§7 |
| 受限解除 | `ShareFileRequest`（原记录为 no-op，S4 单文件落地；多文件仍 no-op） | ✅ 单文件 / ⚠ 多文件明确 no-op | 审计 §34、§35.4 |
| 受限解除 | 手电筒（Camera Kit torch，S3）；`DeviceDisplay.KeepScreenOn`（T8） | ✅ 桥已落地；真机行为待证 | 审计 §33、§37 |
| 仍受限 | TextToSpeech：本 SDK 无 Speech Kit，链路已接、sink 如实返回不可用 | ⛔ SDK 门控 | 审计 §5c |

## 2. 架构批次 D1 / D2（及 D3 / D4）

| 批次 | 内容 | 状态 |
|---|---|---|
| D1 视觉诊断 overlay | `OpenHarmonyDiagnostics.Enabled` → 每帧描边 + 类型名，`OutlinesDrawn` 计数（108/帧实证） | ✅ |
| D2 无障碍 | 影子节点树 + 角色/标题 + 帧间差分发布（无变化跳过原生通信）+ 宿主 provider 7 回调 + 动作回传 + 事件 + 节点数导出 + 16 参发布契约；provider 附着状态 0–4 日志 | ✅（数据链与契约；唯一真机待证：原生 CUSTOM 节点上 provider 返回非 null，期望 `status=1`） |
| D3 BlazorWebView / HybridWebView | 里程碑 1/2/2b/3.0 + S1 管理器与 T5 演示页；Hybrid JS→.NET 往返离设备验证 | 🔄 真机渲染与 `Blazor.start()` 未证 |
| D4 Hot Reload | 依赖 `dotnet watch`/agent、设备通道与运行时 metadata update | ⛔ 硬阻塞（hdc 策略） |

## 3. 并行批次：A–J、K、P、Q、R、S、T、U 与 V 队列

| 批次 | 内容（可核实范围） | 状态 / 证据 |
|---|---|---|
| A–J | A 传感器扩展；B TextToSpeech（SDK 无 Speech Kit）；C Launcher/Browser/Share；D 桌面菜单；E 拖放；F 触感+主题；G ArkWeb JS 桥 + 最小 HybridWebView；H 日历+联系人（Kit 编译通过）；I 蓝牙+打印+地图评估；J 蓝牙发现/电池/显示/无障碍探测；① rot-vector 四元数 ② `InstallEssentials` 空操作 ③ 脚本 log() | 均完成并有套件证据（131→191 条），见交接状态 §9 与审计 §6–§20 |
| K | K-1 壳侧 `napi_threadsafe_function`（14 个 sink）；K-2 多目标（20.0/26.0）与 API 波段解码 | ✅ 审计 §22–§23 |
| P | P1 交付资产（device-test-kit release）+ 构建横幅；P2 蓝牙发现去重 + BlazorWebView 里程碑 1 | ✅ 审计 §24（191/195 条） |
| Q | Q1 宿主 TSFN 与动作发布；Q2 壳 `window.external` + A11Y 自检入口；Q3 确定性打包与 per-TFM 波段；Q4 CI 门禁 + 种子 fuzz；Q5 上手文档（+Q5b 里程碑 2 骨架） | ✅ 审计 §25–§27 |
| R | R2/R2b 无障碍 provider（方向焦点、editable/checkable、16 参契约）；R3 DevEco CLT 盘点（hdc only，R3 取消）；R7 上游三分支/补丁预备 | ✅ 审计 §29–§32 |
| S | S1 BlazorWebView 管理器；S2 无障碍节点数/分组层级；S3 手电筒；S4 分享文件；S5 preview.24 刷新 | ✅ 审计 §33–§35 |
| T | T5 演示 Hybrid 页；T6 静态资产指纹回退 + 缓存头；T7 `IDeviceDisplay`；T8 `KeepScreenOn`；kit 一键构建（`c00e358`）、`verify-kit.sh`（`7a112f9`）、华为材料代签（`5d46e2e`/`4addd43`）、.24 bundle 挂到 SDK release（`3b92ac7`） | ✅ 除 T5/T6/T7/T8 按审计 §35.4–§37 外，其余为交付/签名/发布项；**T1–T4 编号未在文档中逐一落名** |
| U | U3 演示 BlazorWebView 路径（`3fb370d`）；U4 无障碍发布路径性能门（`40384e6`，216 条） | U3/U4 已核实；**U1/U2 的编号对应在写作时无法从仓库文档核实** |
| V | 排队中的后续批次 | ⏳ **写作时未在任何已提交文档中落名/落内容** |

## 4. 验证基线（离设备）

- **交互套件**：`test/maui-platform-verify` 现为 **256 条** `[verify]` = 243 交互检查 + 4 fuzz + 1 帧性能门 + 8 无障碍发布路径性能门；
  最近一次本地 preflight（2026-09-21 22:52–22:54）：**256 条、0 Unhandled、exit 0**；README 期望 256，CI 门限 **≥224**，本地 preflight 门限 **≥226**。
- **帧性能门**：200 帧 / 401 节点，`avg=3.121ms p50=3.003ms p95=4.009ms max=4.987ms max/avg=1.60`，`within=True`
  （预算 avg≤20ms、max≤250ms、max/avg≤100）。
- **无障碍发布路径性能门**：未变化帧跳过 vs 变化帧重发：render `0.276ms` vs `3.299ms`（11.93×，下限 1.25×）、
  publish `0.033ms` vs `2.795ms`（84.97×，下限 2×），全部 `within=True`。
- **像素套件**：`test/headless-render` 本次 preflight（22:54）实测 **PIXEL ASSERTIONS PASSED**，2 项 `[KNOWN]`（复选框描边取样、选择态取样）
  为测试侧已记录项（设备清单 §7）。
- **CI（`springmin/ohos-workload`）**：最新 master（`00d27c1`，2026-09-21T14:55Z 推送）运行 `markdownlint` **success**
  （run 35615374665）、`pixel-regression` **success**（run 35615374630）；`interaction-regression` **failure**
  （run 35615374619），失败在编译阶段 —— workflow 固定在 `maui-ohos 90c8373f`，该切片尚无 B 系列的
  `PageDocumentId` / `SanitizeUrlForLog` / `NavigationApprovalSent` 符号；本地 preflight 编译本地切片，256 条全绿，故该 CI 红为 pin 未随 B 系列推进，**不是套件回归**。
- **发布前刷新链**：`build-arkts-shell.sh` → 壳归档入包 → `build-host.sh`（`selfsign ok`）→ 校验和 → bundle → release → hap
  （审计 §8、§35.2；hap 均 `verify-app success`）。

## 5. 发布物（2026-09-22 00:12–00:25 读取自 GitHub releases API 与本地重算）

| 渠道 | 资产 | 大小（B） | sha256 |
|---|---|---|---|
| `workload-1.0.0-preview.24` | `openharmony-workload-1.0.0-preview.24.tar.gz` | 30,374,768 | `a588ca7a109de8d7f386bb758e99b240244150717d411597d0a7b5465fde63f2` |
| `workload-1.0.0-preview.24` / `workload-latest` | `SHA256SUMS` | 212 | `b09230d40e4321771ca5a630fd41750b7fb0fa152d7c74d3843d42373adaef45`（内容为当前 bundle 与滚动名两条 `a588ca7a…`；本地 `dist/SHA256SUMS` 重算一致） |
| `workload-latest` | `openharmony-workload-latest.tar.gz` | 30,374,768 | `a588ca7a…`（同上，逐字节一致） |
| `device-test-kit`（也在 `workload-latest`；当前 kit #5） | `device-test-kit.tar.gz` | 113,995,310 | `869d1d10ec2e21a65001dd18824597602a227d02568ac42be19edff3a4fbce27`（`.sha256` sidecar 内容实测一致；解包 tree digest `ac8694844d8f8b19713f0059690c19ef39d0b7cabc54c641628cb0e72d8a9cfb`） |
| `device-test-kit` | `device-test-kit.tar.gz.sha256` | 89 | `c12a0cd73eb4572ed928157b8a4a34bb76cb3afdd31c2175452254db2379c4db` |
| `device-test-kit` | `hello-mauiapp-probe1-unsigned.hap`（P1，壳侧） | 11,988 | `92ef933cf7e0eadce1b415f67362dbba0f533dfff8cbbde89ee0eb6c4dcbeac4` |
| `device-test-kit` | `hello-mauiapp-probe2-unsigned.hap`（P2，宿主 dlopen） | 178,492 | `70bbc687ba1f131185d72eae6b7dfaddf934d8a296726c792385b901eac9d7b0` |
| `device-test-kit` | `hello-mauiapp-probe3-unsigned.hap`（P3，宿主入口/dlsym） | 186,002 | `5727e00f11c960b060628441b6119702027aa38414d25ddb0e7a4ea823486f3a` |
| `device-test-kit` | `hello-mauiapp-probe4-unsigned.hap`（P4，逐依赖） | 177,466 | `209c8b10de4dd963a5f454c2586fb294c57fea22828856fd799289d8d62303fc` |
| SDK release `v11.0.100-rc.1.26451.109-openharmony` | `openharmony-workload-1.0.0-preview.24.tar.gz` | 30,374,768 | `a588ca7a…`（GitHub API digest 与本地包重算一致；2026-09-21T16:08:24Z 更新） |
| SDK release 同上 | `dotnet-sdk-11.0.100-rc.1.26451.109-openharmony-arm64.tar.gz` | 178,005,544 | `f3a1bba4fd712db5ae231bb4e65cd10ca50c8acb4f0a4d8650681f66c1772c60`（GitHub API digest；未下载核对） |

- `device-test-kit` release 创建于 2026-09-18；kit #5 于 **2026-09-21T16:12:09Z** 更新（sidecar 16:11:47Z，同一 tar.gz 同步到 `workload-latest`），探针 P1–P4 更新于 14:13:24Z / 15:01:33Z / 15:45:09Z / 15:57:59Z（P2–P4 内嵌当前 kit 宿主）。
- bundle 与滚动 `workload-latest` 指向**同一份** `a588ca7a…`（本地 `dist/`、`.feed/openharmony-workload-latest.tar.gz` 与发布侧 `SHA256SUMS` 重算一致）；SDK release 上同名资产已更新为同一大小与 API digest（2026-09-21T16:08:24Z）。
- 交付 kit 组成（本地 2026-09-22 00:18 全新解包目录，kit #5）：5 个 hap（26 默认/权限、20 默认/权限、未签名）+ 8 个文档
  （`README-交付说明.md`、`快速开始.md`、`文档索引.md`、`最终状态.md`、`真机操作手册.md`、`签名与UDID指南.md`、`自签说明.md`、`验收说明.md`）
  + `SHA256SUMS`（14 项：5 hap + 8 文档 + `verify-kit.sh`）+ `verify-kit.sh` 自检脚本；2026-09-22 00:18 以本地同哈希 tar.gz 解包复核实测：`sha256sum -c` 14/14 通过、`--expect-tree-digest ac8694…` OK、`.sha256` sidecar 内容 = tar.gz 哈希；整包（114 MB）未从线上重新下载。
- 当前 5 个 hap 实测：`bundleName=com.example.hellomauiapp`、`minAPIVersion 50002014`、`targetAPIVersion 60101024`、`apiReleaseType Release`、
  `compileSdkType HarmonyOS`、`compileSdkVersion 6.0.2.130`；`libs/arm64-v8a/` 含 `libopenharmonyhost.so`（`0c15a68a…`）与 `libc++_shared.so`（kit #5 起该 in-kit 副本由 SDK ElfSigner 重签：`flags=0x10`、有效，此前为厂商 PKCS#7 签名，`ohos-workload 732766a`）；`ets/modules.abc` = 119,912 B。
- 历史对照：本页早期的 kit 快照 114,000,630 / `7ec0475c…`（tree `799dfce2…`）与 bundle 30,374,980 / `638e4932…`，以及审计 §35 的 S 系列快照 bundle 30,325,661 / `639513dc…`、kit 107,510,820 / `537153e0…`，均已被本表（kit #5 / `a588ca7a…`）取代。
- 演示工程 `test/hello-maui-app` 多目标（`net11.0-openharmony20.0` / `26.0`），含 S1/T5 Blazor/hybrid 验证页；
  hap 打包走 `-p:OpenHarmonyHapPackage=true` 并注入 5 项权限变体。

## 6. 关键证据文档（`docs/plans/`）

| 文档 | 用途 |
|---|---|
| `2026-09-19-ohos-code-audit.md` | 主审计报告 **§1–§37**：探针/修复、A–J、K、P、Q、R、S、T 各批次与不确定项 |
| `2026-09-21-ohos-security-scan.md` | 五仓库安全扫描 **PASS WITH FINDINGS**：23 项全部处置（22 修复 + B6 构造性修复），修复均未真机验证 |
| `README.md` | 文档索引（含 §1–§37 要点、交付文档与历史阶段） |
| `2026-09-19-ohos-hap-acceptance-for-testers.md` | 验收说明 §4b/§5b/§6（A1–K2、N1–N7 清单与回传模板；包内名 `验收说明.md`） |
| `2026-09-20-ohos-tester-quickstart.md` | 一页版快速开始（下载校验 → 选 hap → 安装 → 先测 5 条；包内名 `快速开始.md`） |
| `2026-09-19-ohos-signing-and-udid-guide.md` | `9568344` 根因与重签/华为材料代签（`scripts/sign-for-device.sh`、`sign-huawei.sh`；包内名 `签名与UDID指南.md`） |
| `2026-09-20-ohos-dotnet-getting-started.md` | 第三方开发者英文上手（feed 安装、TFM publish、签名、排障） |
| `2026-09-21-ohos-tester-selfsign.md` | 未签名 hap 自助签名（包内名 `自签说明.md`） |
| `2026-09-18-ohos-device-validation-checklist.md` | 设备侧验证清单；**§6 为 S/T 系列**（Blazor/hybrid 页、常亮、指纹回退、分享、手电筒、节点数、性能预算） |
| `2026-09-21-ohos-device-run-playbook.md` | 真机运行手册（`verify-kit.sh` → 安装/启动 → hilog 取证 → 5 条冒烟 → 失败分支/回传） |
| `2026-09-21-ohos-device-crash-diagnostics.md` | 启动崩溃分支（`JsError` / exit 254）：当前 kit 重测与校验记录、最小 hilog/faultlog/`dotnet-status.txt` 取证、三个 A/B 与回传清单 |
| `2026-09-21-ohos-crash-probes.md` | P1–P4 最小探针（壳 / 宿主 dlopen / 宿主入口 dlsym / 逐依赖）与五层定位决策表；四个探针挂在 `device-test-kit` release |
| `2026-09-21-ohos-delivery-kit-readme.md` | kit 交付说明（基线 preview.24、5 hap 用途） |
| `2026-09-19-ohos-arkts-handover-status.md` | 交接状态（主线、D 批次、环境坑、剩余队列） |
| `2026-09-18-ohos-openharmony-api-proposal.md` | 上游 API 提案草稿（`OSPlatform.OpenHarmony` 等） |
| `patches/pr-ohos-{tls-flag-cleanup,shims-tfm-cleanup,illink-ntlm}.patch` | R7 三分支的可 `git am` 补丁副本 |

## 7. 真机专有不确定项（离设备无法定论）

1. **无障碍 provider 附着**：期望 `[maui] accessibility provider status=1`；2/3/4 分别定位 frame node/CUSTOM 节点/provider 失败步骤（审计 §21、§29–§30）。
2. **T8 常亮**：`setWindowKeepScreenOn` 是否被窗口服务接受、屏幕是否真的常亮；托管 getter 只缓存“最后一次被宿主接受（入队）的值”（审计 §37.5）。
3. **T6 指纹回退与缓存头**：ArkWeb 下 200/404、`Cache-Control` 值与路径穿越拒绝（设备清单 §6.3）。
4. **S1/T5 Blazor/hybrid**：`Blazor.start()` 与首屏渲染、hybrid 探针表、JS→.NET 往返的**真机**投递（审计 §19、§27–§28、§35.4）。
5. **S3 手电筒**：`setTorchMode` 返回 true 仅代表 Camera Kit 受理，LED 是否点亮需看设备（审计 §33.5）。
6. **S4 分享**：接收方能否真正读取 `file://` URI（`FLAG_AUTH_READ_URI_PERMISSION` 只表达授权意图）；多文件为文档化 no-op（审计 §34.5）。
7. **A 传感器精度**：Barometer 单位（Pa vs hPa 常量）、Orientation 欧拉角 vs 四元数语义、Compass 轴向（审计 §6）。
8. **J 推送类**：电池公共事件与 `display.on('change')` 的真机订阅行为（审计 §20）。
9. **B 语音**：本 SDK 无 Speech Kit，真机同样应如实不可用（审计 §5c）。
10. **D4 Hot Reload**：设备通道 + 运行时 metadata update，均为硬阻塞（交接状态 §8）。
11. **签名**：4 个已签 hap 的调试 profile 绑定示例 UDID，其他设备安装报 `9568344`；重签后哈希必变，以随包 `SHA256SUMS` 为准（审计 §35.4）。
12. **启动崩溃根因**：`JsError` / exit 254 需 P1–P4 探针（或当前 kit #5 重测）的设备日志定论 —— P1 失败 = 壳/设备 SDK 侧；
    P1 过、P2 失败 = 宿主 `.so` dlopen；P2 过、P3 失败 = 宿主入口/dlsym；P4 逐依赖点名缺失项；四者全过仍失败 = .NET 运行时/主启动（`docs/plans/2026-09-21-ohos-crash-probes.md` 决策表）。

## 8. 剩余外部依赖

1. **测试设备 UDID 或自助签名 / 外部预签**：测试方回传 UDID（`hdc shell bm get -u`）由我们重签，或按 `自签说明.md` 用其 DevEco 自动签名；
   若要我们按其 UDID 预签，需 p7b + p12 + cer + keyAlias（`scripts/sign-for-device.sh --external --profile … --key … --key-alias … --expect-udid 60CF7B27…`，
   p7b 的 `debug-info.device-ids` 必须含该 UDID、bundleName 需与包内一致，否则失败关闭；每个 hap 逐个 `verify-app`）；
   Huawei 材料可代签（`scripts/sign-huawei.sh`，签名指南 §4b）。
2. **上游 PR**：`dotnet/runtime#132953`（Add OpenHarmony build infrastructure）状态 **OPEN / REVIEW_REQUIRED / MERGEABLE**（2026-09-21T15:06Z 更新）；
   `#132827`（read-only /tmp、NUMA/robust-mutex）**OPEN / REVIEW_REQUIRED**（mergeable 未返回，2026-09-21T09:01Z 更新）；R7 三分支与补丁已就绪，等上述 PR/评审后按序提交；
   两条无 @ 评论文案仍按约束未发；`#132866` 在本环境 `gh` 查询报 “Could not resolve to a PullRequest”（编号/归属以评审线程为准）。
3. **hdc 策略**：本环境 `hdc` 被组织策略拦截（`E00C001 Operation restricted by the organization`）；无 hdc 时用文件管理器安装（设备手册 §2/§6）。
   DevEco CLT 26.0.0.999 仅带 hdc、无 hvigor/hvigorw，R3 已取消（审计 §31）。
4. **发布面待办**：SDK release 上的 bundle 已更新为当前快照（30,374,768 / `a588ca7a…`，2026-09-21T16:08:24Z），无需再跑
   `publish-workload-release.sh --also-sdk-release <tag>`；kit #5 已于 2026-09-21T16:12:09Z 上传（含重签的 `libc++_shared.so`、lazy-shell、8 条 hilog 诊断；探针 P1–P4 同挂该 release），
   其 sidecar 与本地 tree digest（`ac8694…`）/包内 14 项校验一致；整包（114 MB）未从线上重新下载解压核对。

## 9. 核实说明

- **实测读取（2026-09-21 23:05–23:10 CST）**：GitHub releases（bundle/kit/`SHA256SUMS`/`.sha256` sidecar/探针的大小与 sha256、
  SDK release 资产列表与更新时间）、PR 132953/132827、CI run 列表与失败日志；本地：preflight 全绿（256 条 + 像素 PASSED）、
  kit 解包 tree digest 与 14 项校验、5 hap 的 `module.json`/libs 清单、`dist/` 与 `.feed/` bundle 重算、探针哈希。
- **kit #5 复核（2026-09-22 00:12–00:25 CST）**：本地 kit tar.gz / bundle / `dist/SHA256SUMS` 重算 sha256 与发布侧 API digest 及资产一致；
  kit 全新解包 `verify-kit.sh --expect-tree-digest ac8694…` OK、14 项 `sha256sum -c` 全过、`.sha256` sidecar 内容 = tar.gz 哈希；探针 P1–P4 大小/哈希读取自 API（P3/P4 为本轮新增资产）。
- **未核实（如实标注）**：T1–T4 与 U1/U2 的编号对应（仅 T5–T8、U3/U4 有落名证据）；V 系列的范围与条目；
  SDK release 上 bundle/SDK 包的**文件本体**（仅 API digest 与本地同哈希 bundle 对照，未下载核对）；kit 整包线上内容（未从线上重新下载，以 sidecar + tree digest 绑定本地同哈希文件）；`#132866` 的仓库归属与状态。
- **一致性提示**：任何文档中早于本页的计数（如 getting-started 的 191 条、审计 §35 的 208 条与 kit 107,510,820）
  均为其写作时点快照，以本页数字与随包 `SHA256SUMS` 为准。

## 10. 真机跟进（on-device follow-up，2026-09-21 晚间）

- **测试方首轮**（OpenHarmony 7.0.0.105 / API 26 / 2in1，UDID `60CF7B27…F8A19`）：旧 kit（preview.23）先后遇 `9568344`（连字符 bundleName）与
  `9568297`（波段不符）；改用合法 bundleName + 设备波段安装成功后，`aa start` 约 1 秒退出（`exit 254`，`AppKilledReporter` `reason=JsError`）。
- **安装侧修复**（`ohos-workload bbfa03c`）：默认 bundleName 改为 `com.example.hellomauiapp`（`hello-maui-razor` 同理），
  新增打包期校验 `_OpenHarmonyValidateBundleName`，非法名在编译前失败；设备波段默认
  `minAPIVersion 50002014 / targetAPIVersion 60101024 / apiReleaseType Release / compileSdkType HarmonyOS / compileSdkVersion 6.0.2.130`（修 `9568297`），
  API 20 波段保持 `60000020` 不变。当前 kit 的 5 个 hap 实测均为上述取值。
- **崩溃相关修复**（`ff2e11e`、`89a4a6c`、`00d27c1`、`732766a`）：(a) haps 随包 `libs/arm64-v8a/libc++_shared.so`（宿主 `DT_NEEDED`，缺失即 dlopen 失败；kit #5 起该副本由 SDK ElfSigner 重签，`flags=0x10`/有效，为 kit #4→#5 的唯一内容差异）；
  (b) ArkTS 壳把 Camera/Contacts/Connectivity/print 等非核心 Kit 改为按需 guarded `import()`（缺模块只降级，不再在启动前杀死页面），
  同时修 notification sink 的嵌套作用域、给 UI/事件路径的 `host.*` 调用加 `hostCall` 守卫；(c) 宿主新增 8 条 hilog 诊断
  （hostfxr dlopen/dlerror、hostfxr 初始化 rc、缺失符号、托管 Main 退出码、`start_app` begin/launch）。当前 kit 的 `ets/modules.abc` = 119,912 B。
- **诊断探针**：P1–P4 四个未签名 hap 已挂到 `device-test-kit` release —— `hello-mauiapp-probe1-unsigned.hap`（纯 ArkTS 壳侧）、
  `hello-mauiapp-probe2-unsigned.hap`（宿主 dlopen）、`hello-mauiapp-probe3-unsigned.hap`（宿主入口/dlsym）、`hello-mauiapp-probe4-unsigned.hap`（逐依赖预检；P2–P4 内嵌当前 kit 宿主）；
  定位决策表见 `docs/plans/2026-09-21-ohos-crash-probes.md`，最小证据与回传模板见 `docs/plans/2026-09-21-ohos-device-crash-diagnostics.md`。
- **安全扫描**：仍为 **PASS WITH FINDINGS**；23 个候选项已全部处置（22 修复 + B6 构造性修复），所有修复均未真机验证（`docs/plans/2026-09-21-ohos-security-scan.md`）。
- **当前基线与待办**：本地 preflight 256 条全绿（含像素套件），CI 门限 ≥224；待测试方用当前 **kit #5** 重测（自行重签），
  或回传 p7b + p12 + cer + keyAlias，用 `--external` 按其 UDID `60CF7B27…F8A19` 预签（§8 第 1 项）。
