# OpenHarmony .NET/MAUI 移植最终状态（2026-09-21）

> 一页版收官状态：五仓库（`runtime-ohos` 文档、`ohos-workload` 宿主/壳/脚本/套件、`maui-ohos` 切片、
> `sdk-ohos` 发布、`aspnetcore-ohos`）截至 **2026-09-23 09:00（CST）** 可核实的事实（含 9 月 21 日晚间真机跟进、
> 22 日凌晨探针 P1–P4 更新、22 日下午至傍晚的**三个启动阻塞修复（入口 record / abc 13.0.1.0 / host undefined）**、
> **kit #14** 刷新（评审整改 REV/RA/RB/RC-A..D、真实缺陷修复 PI1、UX 深化 PJ1/PJ2）与 **297 条**套件基线，见 §4、§5、§10）。
> 数字均来自仓库提交、审计报告与 GitHub 实测读取；无法读取或未落名的一律标注，不做推测。
> 详细依据见主审计报告 `docs/plans/2026-09-19-ohos-code-audit.md`（§1–§41）与索引 `docs/plans/README.md`。

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

- **交互套件**：`test/maui-platform-verify` 现为 **297 条** `[verify]` = 284 交互检查（含 audit-batch-2 源码契约）+ 4 fuzz + 1 帧性能门 + 8 无障碍发布路径性能门；
  `ohos-workload deaab95` 记录最近一次套件运行：**297 条、0 Unhandled、全部 perf `within=True`**；更早一次本地完整 preflight（2026-09-22，套件为 284 条时）含 pixel `PIXEL ASSERTIONS PASSED` 与 markdownlint 0 issues；
  README 期望 297，CI 门限 **≥277**（297-20，`ohos-workload 2f43bb4`），本地 `scripts/preflight.sh` 门限 **≥226**。
- **帧性能门（2026-09-22 采样）**：200 帧 / 401 节点，`avg=2.868ms p50=2.704ms p95=3.847ms max=5.109ms max/avg=1.78`，`within=True`
  （预算 avg≤20ms、max≤250ms、max/avg≤100）。
- **无障碍发布路径性能门（2026-09-22 采样）**：未变化帧跳过 vs 变化帧重发：render `0.363ms` vs `2.872ms`（7.91×，下限 1.25×）、
  publish `0.033ms` vs `2.418ms`（72.96×，下限 2×），全部 `within=True`。
- **像素套件**：`test/headless-render` 最近一次含像素套件的 preflight（2026-09-22）实测 **PIXEL ASSERTIONS PASSED**，2 项 `[KNOWN]`（复选框描边取样、选择态取样）
  为测试侧已记录项（设备清单 §7）。
- **CI（`springmin/ohos-workload`）**：pin 现为 `maui-ohos 8430ac06`（PJ1/PJ2 tip，随 297 条套件一起把下限升到 **≥277**，
  `ohos-workload 2f43bb4`，2026-09-23）；推进后的 CI run **尚未产生**。此前 `df221b6`（pin `be5d471f`）三条 run 全绿（interaction
  `35629780806`、pixel `35629780800`、markdownlint `35629780817`，2026-09-21T17:05:36Z）；更早的
  `interaction-regression` 红是 pin 停在 `maui-ohos 90c8373f`（缺 B 系列符号）所致，**不是套件回归**。
- **发布前刷新链**：`build-arkts-shell.sh` → 壳归档入包 → `build-host.sh`（`selfsign ok`）→ 校验和 → bundle → release → hap
  （审计 §8、§35.2；hap 均 `verify-app success`）。

## 5. 发布物（当前 = `device-test-kit` release 说明的「## Integrity」小节，文档内简称 kit #14）

- **当前发布 = `device-test-kit` release**（2026-09-18 创建、**2026-09-23** 刷新；基线 `1.0.0-preview.24`；当前 kit #14 = 评审整改（REV/RA/RB/RC-A..D）+ 真实缺陷修复（PI1）+ UX 深化（PJ1/PJ2））：整包大小/sha256、解压内容树 sha256、`.tar.gz.sha256` sidecar（边车）与探针 P1–P4 的数字**一律以 release 说明的「## Integrity」小节或 sidecar 为准**（`workload-latest` 镜像同值）——重签、预签或重新打包后必然变化，本页不写死任何哈希。

| 渠道 | 资产 | 数字入口 |
|---|---|---|
| `workload-1.0.0-preview.24` | `openharmony-workload-1.0.0-preview.24.tar.gz` | release 说明 / GitHub API digest |
| `workload-1.0.0-preview.24` / `workload-latest` | `SHA256SUMS` | 内容为当前 bundle 与滚动名两条（本地 `dist/SHA256SUMS` 重算一致）|
| `workload-latest` | `openharmony-workload-latest.tar.gz` | 与 bundle 逐字节一致 |
| `device-test-kit`（也在 `workload-latest`） | `device-test-kit.tar.gz` + `.tar.gz.sha256` sidecar | release 说明「## Integrity」或 sidecar |
| `device-test-kit` | `hello-mauiapp-probe{1..4}-unsigned.hap`（P1 壳侧、P2 宿主 dlopen、P3 宿主入口/dlsym、P4 逐依赖） | release 说明 / API digest |
| SDK release `v11.0.100-rc.1.26451.109-openharmony` | `openharmony-workload-1.0.0-preview.24.tar.gz`、`dotnet-sdk-11.0.100-rc.1.26451.109-openharmony-arm64.tar.gz` | GitHub API digest |

- `device-test-kit` release 创建于 2026-09-18；当前 **kit #14** 于 **2026-09-23** 刷新（tar.gz + sidecar 同批上传，同一 tar.gz 同步到 `workload-latest` 与 SDK release；具体时间与哈希见 release 说明「## Integrity」）。kit 编号演进：#7（22 日凌晨）→ #10（入口 record 修复）→ #11（abc `13.0.1.0`）→ #12（宿主 dlopen-only + 壳 `host` 守卫）→ … → **#14（当前：评审整改 + 真实缺陷修复 + UX 深化）**；探针 P1–P4（已随 preview.24 宿主重建）仍挂该 release。
- bundle 与滚动 `workload-latest` 指向**同一份** tar.gz（本地 `dist/`、`.feed/openharmony-workload-latest.tar.gz` 对发布侧 `SHA256SUMS` 重算一致）；SDK release 上同名资产已同步为当前快照（时间以 release `updated_at` 为准）。
- 交付 kit 组成（当前快照全新解包核实）：5 个 hap（26 默认/权限、20 默认/权限、未签名）+ 9 个文档
  （`README-交付说明.md`、`快速开始.md`、`文档索引.md`、`最终状态.md`、`真机操作手册.md`、`签名与UDID指南.md`、`自签说明.md`、`验收说明.md`、`签名说明.txt`）
  + `SHA256SUMS`（15 项：5 hap + 9 文档 + `verify-kit.sh`）+ `verify-kit.sh` 自检脚本。校验三步：① `sha256sum -c device-test-kit.tar.gz.sha256`（或 `verify-kit.sh --anchor-file …`）→ ② 解压 → ③
  `sh verify-kit.sh --expect-tree-digest <device-test-kit release 说明「## Integrity」中的 tree sha256>`；包内 `sha256sum -c SHA256SUMS` 应 15/15 通过，sidecar 内容 = tar.gz 的 sha256。整包未从线上重新下载，以 GitHub API digest 绑定本地同哈希 tar.gz。
- 当前 5 个 hap 实测（**快照示例，仅作参照，以随包文件与 release 说明为准**）：`bundleName=com.example.hellomauiapp`、26 波段 `minAPIVersion 50002014`、`targetAPIVersion 60101024`、`apiReleaseType Release`（api20 波段 `60000020`）、
  `compileSdkType HarmonyOS`、`compileSdkVersion 6.0.2.130`；`libs/arm64-v8a/` 含 14 个 `.so` = 12 个 .NET 运行时原生库（`libcoreclr`/`libclrjit`/`libhostfxr`/…）+ `libopenharmonyhost.so`（含 BATCH-1/2 Essentials 桥与加固）+ `libc++_shared.so`（kit #5 起该 in-kit 副本由 SDK ElfSigner 重签：`flags=0x10`、有效，此前为厂商 PKCS#7 签名，`ohos-workload 732766a`）；`dotnet.zip` 253 项且 0 个 `.so`（运行时原生库只随 hap `libs/<abi>/` 提供）；壳归档 `ets/modules.abc` 为加固壳（当前 kit #14 = 201,228 B，五 hap 同值），自 kit #10 起入口 record 走非标准化 OHM URL（`useNormalizedOHMUrl=false`，`c2c4a9a`/`6e55ae6`），自 kit #11 起 abc 头为 `13.0.1.0`（`compatibleSdkVersion 18`，`95c89a7`/`ef1c947`）。文件大小与哈希以随包 `SHA256SUMS` 为准。
- 历史对照：本页早期与审计 §35 的 S 系列 kit/bundle 快照（含当时大小与哈希）均已被当前快照取代，不再复述。
- **包内 tester 文档不再写死 kit 哈希**：`快速开始.md`、`自签说明.md`、设备校验清单、`验收说明.md` 等一律指向 `device-test-kit` release 说明的「## Integrity」小节（`workload-latest` 镜像同值）或 `.tar.gz.sha256` sidecar；本页只锚定快照日期（2026-09-23），不记录当次快照数字。
- 演示工程 `test/hello-maui-app` 多目标（`net11.0-openharmony20.0` / `26.0`），含 S1/T5 Blazor/hybrid 验证页；
  hap 打包走 `-p:OpenHarmonyHapPackage=true` 并注入 5 项权限变体。

## 6. 关键证据文档（`docs/plans/`）

| 文档 | 用途 |
|---|---|
| `2026-09-19-ohos-code-audit.md` | 主审计报告 **§1–§41**：探针/修复、A–J、K、P、Q、R、S、T、V 各批次与不确定项 |
| `2026-09-22-ohos-maui-coverage-matrix.md` | MAUI 覆盖矩阵：已实现 / 部分（附代码证据）/ 未实现 / SDK 阻塞 + Top-10 缺口（只读审计） |
| `2026-09-21-ohos-security-scan.md` | 五仓库安全扫描 **PASS WITH FINDINGS**：23 项全部处置（22 修复 + B6 构造性修复），修复均未真机验证 |
| `README.md` | 文档索引（含 §1–§41 要点、交付文档与历史阶段） |
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
12. **启动崩溃根因（已修复）**：三个根因均已定位并进入 kit #10–#12（当前 kit #14 含全部修复）—— ① 壳 abc 入口 record（`ReferenceError: Cannot find module '…EntryAbility'`，
    kit #10 修复、测试方真机复测确认）；② abc 字节码版本 `24.0.0.0` 超出设备 ark runtime `13.0.1.0`
    （`export objects of native so is undefined` / `Cannot read property … of undefined`，kit #11 以 `compatibleSdkVersion 18` 修复为 `13.0.1.0`）；
    ③ 宿主 `.so` 加载失败使壳 `host` 为 undefined、未守卫的 `host.registerXComponent()` 抛 TypeError（`exit 254`，
    kit #11 真机复测暴露），修复随 kit #12：宿主无 `libhostfxr` 链接依赖（全部经 dlopen/dlsym）+ `build-host.sh`
    构建期 DT_NEEDED 审计 + 壳全量 `host.<api>` 守卫（`ohos-workload 7e71c39` + 壳归档 `2411a8e`）。
    判读见 `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md` §5b/§5c 与 `docs/plans/2026-09-21-ohos-crash-probes.md` §4.0/§4.0b/§4.0c；
    P1–P4 阶梯仍用于 dlopen / 缺库 / 宿主入口 / .NET 运行时类崩溃。

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
4. **发布面待办**：SDK release 上的 bundle 已随当前快照更新（`workload-1.0.0-preview.24`；当前 kit #14 = 评审整改 + 真实缺陷修复 + UX 深化；
   探针 P1–P4 同挂该 release），无需再跑
   `publish-workload-release.sh --also-sdk-release <tag>`；其 sidecar、release 说明「## Integrity」的 tree digest
   与包内 15 项校验一致（数字以 release 说明/sidecar 为准）；整包未从线上重新下载解压核对。

## 9. 核实说明

- **实测读取（2026-09-21 23:05–23:10 CST）**：GitHub releases（bundle/kit/`SHA256SUMS`/`.sha256` sidecar/探针的大小与 sha256、
  SDK release 资产列表与更新时间）、PR 132953/132827、CI run 列表与失败日志；本地：preflight 全绿（256 条 + 像素 PASSED）、
  kit 解包 tree digest 与 14 项校验、5 hap 的 `module.json`/libs 清单、`dist/` 与 `.feed/` bundle 重算、探针哈希。
- **kit #7 复核（2026-09-22 08:59–09:10 CST）**：本地 kit tar.gz / bundle / `dist/SHA256SUMS` 重算 sha256 与发布侧 API digest 及资产一致；
  kit 解包 `verify-kit.sh --expect-tree-digest <release 说明「## Integrity」中的 tree sha256>` OK、14 项 `sha256sum -c` 全过、
  `.sha256` sidecar 内容 = tar.gz 哈希（与 API digest 一致）；探针 P1–P4 大小/哈希读取自 API（数字不写入本页）。
- **kit #14 与 297 基线（2026-09-23 上午）**：`ohos-workload deaab95` 记录套件 **297** 条 / 0 Unhandled / 全部 perf `within=True`；
  当前 kit (#14) 解包实测五 hap 的 `ets/modules.abc` = 201,228 B（头 `13.0.1.0`）、`libs/arm64-v8a` 14 个 `.so`、
  `dotnet.zip` 253 项 0 `.so`、`sha256sum -c SHA256SUMS` 15/15 与 tree digest 校验 OK（数字只指向 release 说明/边车与交付物清单，不写入本页）。
- **哈希入口**：包内 tester 文档（`快速开始.md`、`自签说明.md`、设备校验清单、`验收说明.md`、`签名说明.txt`）与本页均已去掉固定 kit 哈希，
  统一指向 `device-test-kit` release 说明的「## Integrity」小节（`workload-latest` 镜像同值）或 `.tar.gz.sha256` sidecar；本页只锚定 2026-09-23 的快照日期。
- **未核实（如实标注）**：T1–T4 与 U1/U2 的编号对应（仅 T5–T8、U3/U4 有落名证据）；V 系列的范围与条目；
  SDK release 上 bundle/SDK 包的**文件本体**（仅 API digest 与本地同哈希 bundle 对照，未下载核对）；kit 整包线上内容（未从线上重新下载，以 sidecar + tree digest 绑定本地同哈希文件）；`#132866` 的仓库归属与状态。
- **一致性提示**：任何文档中早于本页的计数与大小（如 getting-started 的 191 条、审计 §35 的 208 条与其 kit 快照）
  均为其写作时点数值；kit/hap 的数字一律以 `device-test-kit` release 说明的「## Integrity」、sidecar 与随包 `SHA256SUMS` 为准。

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
  （hostfxr dlopen/dlerror、hostfxr 初始化 rc、缺失符号、托管 Main 退出码、`start_app` begin/launch）。当前 kit 的壳归档 `ets/modules.abc` 为加固版（大小/哈希以随包 `SHA256SUMS` 为准）。
- **诊断探针**：P1–P4 四个未签名 hap 已挂到 `device-test-kit` release —— `hello-mauiapp-probe1-unsigned.hap`（纯 ArkTS 壳侧）、
  `hello-mauiapp-probe2-unsigned.hap`（宿主 dlopen）、`hello-mauiapp-probe3-unsigned.hap`（宿主入口/dlsym）、`hello-mauiapp-probe4-unsigned.hap`（逐依赖预检；P2–P4 内嵌当前 kit 宿主）；
  定位决策表见 `docs/plans/2026-09-21-ohos-crash-probes.md`，最小证据与回传模板见 `docs/plans/2026-09-21-ohos-device-crash-diagnostics.md`。
- **安全扫描**：仍为 **PASS WITH FINDINGS**；23 个候选项已全部处置（22 修复 + B6 构造性修复），所有修复均未真机验证（`docs/plans/2026-09-21-ohos-security-scan.md`）。
- **根因修复与真机复测（2026-09-22）**：入口 record 缺陷在 **kit #10** 修复（`useNormalizedOHMUrl=false` + bundle 前缀 record，
  `ohos-workload c2c4a9a`/`6e55ae6`），测试方真机复测确认入口可解析；同一轮真机复测暴露第二个独立阻塞 —— 壳 abc 版本
  `24.0.0.0` 超出设备 ark runtime `13.0.1.0`（`export objects of native so is undefined`），**kit #11** 以
  `compatibleSdkVersion 18` 修复为 `13.0.1.0`（`ohos-workload 95c89a7`/`ef1c947`）。详见
  `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md` §5b 与 `docs/plans/2026-09-22-ohos-arkts-abc-version-history.md`。
- **当前基线与待办**：交互套件 **297** 条 / 0 Unhandled（CI 门限 ≥277，本地 preflight 门限 ≥226；`ohos-workload 2f43bb4`/`deaab95`）；
  待测试方用 **kit #14** 重测（自行重签；先看 §7 第 12 项的**三个**已修复分支），或回传 p7b + p12 + cer + keyAlias，
  用 `--external` 按其 UDID `60CF7B27…F8A19` 预签（§8 第 1 项）。
- **第三个启动阻塞与 kit #12（2026-09-22 晚）**：kit #11 真机复测确认 abc 修复生效（`ark_disasm` 可解析 `13.0.1.0`、
  `[maui]` 日志出现、崩溃推进到页面/渲染阶段），但壳 `host` 为 undefined —— 未守卫的 `host.registerXComponent()`
  抛 TypeError（`exit 254`，其余调用只记 `[maui] host export unavailable`）。归因：宿主 `.so` 加载失败
  （加载期 DT_NEEDED 解析早于 `dotnet.zip` 解压；测试方 readelf 清单指认 `libhostfxr.so`，对同哈希 kit #11 产物的
  逐 hap 复核见 `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md` §5c 核验注）。修复（`ohos-workload 7e71c39` +
  壳归档 `2411a8e`，随 kit #12 出包）：宿主不在链接期依赖 `libhostfxr`（全部经 dlopen/dlsym），`build-host.sh`
  增加构建期 DT_NEEDED 审计（含 `libhostfxr` 即失败），壳模板每个 `host.<api>` 访问纳入 `hostCall` +
  `typeof host !== 'undefined'` 守卫（含 `registerXComponent`）。详见同 §5c 与 `docs/plans/2026-09-21-ohos-crash-probes.md` §4.0c。
- **kit #14 真机进展（2026-09-23，里程碑）**：应用首次**正常启动并稳定存活**（1 分钟+，主进程 + `:gpu` 进程均在；
  `hilog` 无 `TypeError`/`JsError`/`exit 254`）—— 前三个既有根因在真机确认修复（入口 record（kit #10）、
  abc `13.0.1.0`（kit #11）、运行时原生库随 `libs/arm64-v8a/`（kit #13/#14，即 §7 第 12 项第 ③ 分支加载序链的
  最终落地））；但页面**黑屏**（进程不退出）：设备日志 `Load native module failed, ModuleName:
  @app:com.example.hellomauiapp/entry/openharmonyhost` + 全部 `[maui] host export unavailable: <api>`、XComponent
  已 `AttachToMainTree`/`onLoad` —— 宿主 napi 注册名（`nm_modname = "openharmonyhost"`）与 `useNormalizedOHMUrl=false`
  下 abc 的 import 记录名不匹配 → host exports 为空 → 表面未交给 .NET → 黑屏。修复（RH1：宿主别名注册覆盖两种约定 +
  标准化壳构建、保留入口 record 的 bundle 名，入口 record 重新核验）**进行中（in flight）**；依据见
  `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md` §5d/§5e 与 `docs/plans/2026-09-21-ohos-crash-probes.md` §4.0d 及决策表新增行。

## 11. 最终收官（2026-09-23，本页最后一节）

- **四个真机根因（按确认顺序）**：① **入口 record**（`ReferenceError: Cannot find module '…EntryAbility'`）—— kit #10 修复并真机复测确认；
  ② **abc `13.0.1.0`**（壳 abc `24.0.0.0` 超出设备 ark runtime）—— kit #11 以 `compatibleSdkVersion 18` 修复；
  ③ **运行时原生库随 `libs/arm64-v8a/`**（宿主 dlopen 缺库/加载序）—— kit #13/#14 落地。①②③ 合流后**崩溃清零**；
  ④ **napi/app-lib path**（黑屏阻塞 #4）—— 非隔离 hap 的模块级 native path 为空（`<bundle>/<module>` app-lib key 未注册）
  叠加 abc host import 记录名与宿主注册名不匹配；kit #16（别名宿主）与 kit #17（RM1 `libIsolation`）分别覆盖两半边，
  record/name 另一半由候选实验裁定。
- **里程碑**：kit #14（本页口径；`ohos-workload` 发布说明口径为 kit #16）为第一个「**崩溃清零 + 应用正常启动并稳定存活**」
  （1 分钟+，主进程 + `:gpu`，无 `TypeError`/`JsError`/`exit 254`）的构建；黑屏是其后暴露的独立问题（§10）。
- **基线**：离设备交互套件现为 **315** 条 `[verify]`（含 MB/H-C2/审计与门禁新增 pin），门限 **floor 295**（套件自报 `[suite]` 行，preflight 与 CI 同源解析）
  （`ohos-workload 92f7555`/`a10b73e`；§4 的 297/277/308/288 为历史值）。
- **候选矩阵（选一，设备跑批结果待回传）**：**dynpkg**（`libIsolation` + abc host-binding record + 已确认入口形式）为
  **最强单候选**；其次 **kit #17 单独**（仅 RM1 `libIsolation`，覆盖 path/key 半边）；再次 **normalized**
  （`useNormalizedOHMUrl=true` + `pkgContextInfo.json`，入口 record 形状改变、设备入口解析未证）。`importb`（命名空间静态 import）与
  `importd`（动态加载 D1/D2）为其余探针载荷。候选载荷（dynpkg/normalized/importb/importd）仍在 `device-test-kit` release 上供对照；
  **当前发布 = kit #19**（见下条），数字入口见 `docs/plans/2026-09-22-ohos-release-manifest.md`（更新快照），实验依据见
  `docs/plans/2026-09-23-ohos-native-import-experiment.md` §8 与 `docs/plans/2026-09-23-ohos-napi-import-fix-playbook.md` §5。
- **kit #18 → kit #19（2026-09-23 发布，替代上文 kit #17 口径）**：kit #18 携带安全 + 性能第一批修复（A1/A2/A3、H-C1/H-C2、D-1..D-6、MB-1..MB-3、FIX-P1/P2）；**kit #19（当前）** 在其上追加 P17 启动解压跳过、H7 rawfile 描述符直读、H8/H11/H12、TLS 加固（H-C3 绝对路径 `dlopen` + H3 探测）、P12 增量签名、PR 评审合规整改与门禁加固（alloc 门禁 13,824 B、CI 缓存/PR 触发、`[suite]` 单一 floor 来源）。`device-test-kit` 与 bundle 的数字入口见 release `## Integrity` 与 `docs/plans/2026-09-22-ohos-release-manifest.md`（本页保持哈希无关）。
