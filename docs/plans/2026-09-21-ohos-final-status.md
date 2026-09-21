# OpenHarmony .NET/MAUI 移植最终状态（2026-09-21）

> 一页版收官状态：五仓库（`runtime-ohos` 文档、`ohos-workload` 宿主/壳/脚本/套件、`maui-ohos` 切片、
> `sdk-ohos` 发布、`aspnetcore-ohos`）截至 **2026-09-21 11:38（CST）** 可核实的事实。
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

- **交互套件**：`test/maui-platform-verify` 现为 **216 条** `[verify]` = 203 交互检查 + 4 fuzz + 1 帧性能门 + 8 无障碍发布路径性能门；
  最近一次仓库内运行（2026-09-21 10:33）：**216 条、0 Unhandled、exit 0**；README 与 CI 阈值均为 **≥216**。
- **帧性能门**：200 帧 / 401 节点，`avg=6.485ms p50=6.205ms p95=9.483ms max=29.668ms max/avg=4.57`，`within=True`
  （预算 avg≤20ms、max≤250ms、max/avg≤100）。
- **无障碍发布路径性能门**：未变化帧跳过 vs 变化帧重发：render `0.302ms` vs `6.319ms`（20.91×，下限 1.25×）、
  publish `0.051ms` vs `5.634ms`（110.23×，下限 2×），全部 `within=True`。
- **像素套件**：`test/headless-render` 本次实测 **PIXEL ASSERTIONS PASSED**，2 项 `[KNOWN]`（复选框描边取样、选择态取样）
  为测试侧已记录项（设备清单 §7）。
- **CI（`springmin/ohos-workload`）**：最新 master（`40384e6`）运行 `interaction-regression` **success**
  （run 35554634466，37s）与 `markdownlint` **success**（run 35554634472）；`pixel-regression` **failure**，
  但失败在构建阶段（runner 未物化切片/两个 Hosting 程序集，无法编译像素工程），**不是像素断言失败** —— 像素套件目前是本地门禁。
- **发布前刷新链**：`build-arkts-shell.sh` → 壳归档入包 → `build-host.sh`（`selfsign ok`）→ 校验和 → bundle → release → hap
  （审计 §8、§35.2；hap 均 `verify-app success`）。

## 5. 发布物（2026-09-21 11:38 读取自 GitHub releases）

| 渠道 | 资产 | 大小（B） | sha256 |
|---|---|---|---|
| `workload-1.0.0-preview.24` | `openharmony-workload-1.0.0-preview.24.tar.gz` | 30,328,703 | `98d72a04b54b245c1de46c05e8dd4227124d9b8a2e5ad8bb0f73fa8a334599b0` |
| `workload-1.0.0-preview.24` / `workload-latest` | `SHA256SUMS` | 1,529 | `a4f25a47b7a10c1857388ddf92deaed086d358e687f20032f3ffd5bee2b72caf` |
| `workload-latest` | `openharmony-workload-latest.tar.gz` | 30,328,703 | `98d72a04…`（同上，逐字节一致） |
| `device-test-kit`（也在 `workload-latest`） | `device-test-kit.tar.gz` | 111,688,616 | `1e42a14cda6b7d3bb6d57a95bb001335bbda10ff70dce27a23441242e570ea7b`（`.sha256` 内容实测一致） |
| `device-test-kit` | `device-test-kit.tar.gz.sha256` | 89 | `bd3b857ab4bc5b5833c097eab6414b6e80008b1371d27e4c1e70c675532dc825` |
| SDK release `v11.0.100-rc.1.26451.109-openharmony` | `openharmony-workload-1.0.0-preview.24.tar.gz` | 30,325,661 | 未读哈希（早一批 bundle 快照，未随 T6/T8 重打） |
| SDK release 同上 | `dotnet-sdk-11.0.100-rc.1.26451.109-openharmony-arm64.tar.gz` | 178,005,544 | 未读哈希 |

- `device-test-kit` release 创建于 2026-09-18、资产更新于 **2026-09-21T02:46:56Z**；bundle 与滚动 `workload-latest` 指向**同一份**
  `98d72a04…` bundle（本地 `dist/` 重新计算 sha256 一致），说明 T6/T8 刷新后的壳已进包（pack 内 `modules.ui.abc` = 82,936 B）。
- 交付 kit 组成（本地 11:26 刷新目录）：5 个 hap（26 默认/权限、20 默认/权限、未签名）+ 6 个文档
  （`README-交付说明.md`、`快速开始.md`、`文档索引.md`、`签名与UDID指南.md`、`自签说明.md`、`验收说明.md`）
  + `SHA256SUMS`（12 项，`verify-kit.sh` 自检脚本）；已发布资产的内部清单未下载核对。
- 历史对照：审计 §35 的 S 系列快照为 bundle 30,325,661 / `639513dc…`、kit 107,510,820 / `537153e0…`，已被本表数字取代。
- 演示工程 `test/hello-maui-app` 多目标（`net11.0-openharmony20.0` / `26.0`），含 S1/T5 Blazor/hybrid 验证页；
  hap 打包走 `-p:OpenHarmonyHapPackage=true` 并注入 5 项权限变体。

## 6. 关键证据文档（`docs/plans/`）

| 文档 | 用途 |
|---|---|
| `2026-09-19-ohos-code-audit.md` | 主审计报告 **§1–§37**：探针/修复、A–J、K、P、Q、R、S、T 各批次与不确定项 |
| `README.md` | 文档索引（含 §1–§37 要点、交付文档与历史阶段） |
| `2026-09-19-ohos-hap-acceptance-for-testers.md` | 验收说明 §4b/§5b/§6（A1–K2、N1–N7 清单与回传模板；包内名 `验收说明.md`） |
| `2026-09-20-ohos-tester-quickstart.md` | 一页版快速开始（下载校验 → 选 hap → 安装 → 先测 5 条；包内名 `快速开始.md`） |
| `2026-09-19-ohos-signing-and-udid-guide.md` | `9568344` 根因与重签/华为材料代签（`scripts/sign-for-device.sh`、`sign-huawei.sh`；包内名 `签名与UDID指南.md`） |
| `2026-09-20-ohos-dotnet-getting-started.md` | 第三方开发者英文上手（feed 安装、TFM publish、签名、排障） |
| `2026-09-21-ohos-tester-selfsign.md` | 未签名 hap 自助签名（包内名 `自签说明.md`） |
| `2026-09-18-ohos-device-validation-checklist.md` | 设备侧验证清单；**§6 为 S/T 系列**（Blazor/hybrid 页、常亮、指纹回退、分享、手电筒、节点数、性能预算） |
| `2026-09-21-ohos-device-run-playbook.md` | 真机运行手册（`verify-kit.sh` → 安装/启动 → hilog 取证 → 5 条冒烟 → 失败分支/回传） |
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

## 8. 剩余外部依赖

1. **测试设备 UDID 或自助签名**：测试方回传 UDID（`hdc shell bm get -u`）由我们重签，或按 `自签说明.md` 用其 DevEco 自动签名；
   Huawei 材料可代签（`scripts/sign-huawei.sh`，签名指南 §4b）。
2. **上游 PR**：`dotnet/runtime#132953`（Add OpenHarmony build infrastructure）状态 **OPEN / APPROVED / MERGEABLE**（2026-09-16 更新）；
   `#132827`（read-only /tmp、NUMA/robust-mutex）**OPEN / REVIEW_REQUIRED / MERGEABLE**；R7 三分支与补丁已就绪，等上述 PR/评审后按序提交；
   两条无 @ 评论文案仍按约束未发；`#132866` 在本环境 `gh` 查询报 “Could not resolve to a PullRequest”（编号/归属以评审线程为准）。
3. **hdc 策略**：本环境 `hdc` 被组织策略拦截（`E00C001 Operation restricted by the organization`）；无 hdc 时用文件管理器安装（设备手册 §2/§6）。
   DevEco CLT 26.0.0.999 仅带 hdc、无 hvigor/hvigorw，R3 已取消（审计 §31）。
4. **发布面待办**：SDK release 上的 bundle 仍是较早快照（30,325,661），如需对齐当前 `98d72a04…` 需
   `publish-workload-release.sh --also-sdk-release <tag>`；kit 在写作时点后有本地重建（11:26，含 `verify-kit.sh` 与最新演示页），
   已发布资产的内部清单未核对。

## 9. 核实说明

- **实测读取（2026-09-21 11:38 CST）**：GitHub releases（bundle/kit 大小与 sha256、`.sha256` 内容）、
  PR 132953/132827、CI run 列表与失败日志；本地：像素套件运行（PASSED）、仓库内交互套件日志（216 条）、
  `test/maui-platform-verify/README.md` 与 workflow 阈值、`dist/` 与 pack 内壳归档字节数。
- **未核实（如实标注）**：T1–T4 与 U1/U2 的编号对应（仅 T5–T8、U3/U4 有落名证据）；V 系列的范围与条目；
  已发布 kit 的内部清单/逐文件哈希（未下载）；SDK release 上两条资产的 sha256（未读）；`#132866` 的仓库归属与状态。
- **一致性提示**：任何文档中早于本页的计数（如 getting-started 的 191 条、审计 §35 的 208 条与 kit 107,510,820）
  均为其写作时点快照，以本页数字与随包 `SHA256SUMS` 为准。
