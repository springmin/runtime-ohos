# docs/plans 文档索引

> 本目录是 OpenHarmony .NET/MAUI 移植的过程文档库：测试/交付文档、主审计报告、交接状态与历史批次记录。
> 「状态（最后更新）」列 = 用途 + 该文件最近一次 git 提交日期。图例：✅ 当前生效 · 🔄 进行中/计划 · ⏳ 待执行 · 📦 阶段快照（已完成工作的记录）。
> 「包内名」指该文档随设备测试 kit 分发时的文件名。
> kit 自检：解压后在包内运行 `sh verify-kit.sh`（逐文件校验 `SHA256SUMS` + 打印 5 个 hap 摘要与安装/回传指引）。

## 面向测试与交付（外部读者优先）

| 文档 | 一句话 | 状态（最后更新）|
|---|---|---|
| `2026-09-22-ohos-release-manifest.md` | OpenHarmony 交付物总清单（**已刷新至 kit #21**，2026-09-24 快照）：kit 的 tar/树摘要（编号与数值以 release「## Integrity」为准）、release 资产（探针/tester-run.sh/新功能清单）、bundle、五仓库分支短哈希、校验三步、两条签名路径、SDK 门控与阅读入口 | ✅ 已刷新（2026-09-24，kit #21）|
| `2026-09-20-ohos-tester-quickstart.md` | 外部测试方一页版：下载校验 → 选 hap（4 自签 + 1 未签）→ 安装 → 先测 5 条 → 回传格式；含「自 kit #17 以来的变化」速览 | ✅ 当前（kit #21，2026-09-24）|
| `2026-09-22-ohos-tester-runner.md` | 一条命令跑完一轮真机测试（`tester-run.sh` **v6r2**，随 kit release 单独发布）：本地校验 kit → 安装/启动/抓 hilog（含 applib/dlopen 证据）→ 跑 P1–P4 → 打包回传；默认 dry-run、无设备拒绝执行 | ✅ 当前（v6r2，2026-09-24）|
| `2026-09-22-ohos-new-features-device-checklist.md` | 本轮新功能真机验证清单（M1–M13：权限/连通性/剪贴板/邮件短信拨号/截图/地理编码/窗口安全区/图像与单元格/无障碍/Shell 扩展 + 真实缺陷修复/UX 深化/rawfile 桥）：逐项「步骤/期望/证据」+ 探针 hap 与 `tester-run.sh` 用法 | ✅ 当前（kit #21，2026-09-24）|
| `2026-09-21-ohos-device-crash-diagnostics.md` | 启动崩溃分支（JsError / exit 254）：当前 kit（#21）重测与校验记录 + 最小 hilog/faultlog/status 取证 + §2.4 app-lib/别名/首帧证据 + 三个 A/B + 回传清单 | ✅ 当前（kit #21，2026-09-24）|
| `2026-09-21-ohos-crash-probes.md` | 启动崩溃探针 P1–P4（壳 / 宿主 dlopen / 宿主入口 dlsym / 逐依赖）：五层定位决策表 + 免安装 14 库自检；四类历史分支均已在 kit #16/#17 前修复，kit #21 为当前包；4 个未签名 hap 挂在 `device-test-kit` release | ✅ 当前（kit #21，2026-09-24）|
| `2026-09-22-ohos-startup-crash-rootcause.md` | 启动崩溃根因（测试方证据链）：9568257 自签名被拒属预期；签后启动 `ReferenceError: Cannot find module '…EntryAbility'`（exit 254）= 壳 abc 入口 record 缺陷（E1–E5 + cc-switch 37 vs 1~2 + 华为 FAQ `useNormalizedOHMUrl=false`）；H1/H2 是硬化非本因；修复 = PA1 重建壳 abc；四个阻塞均已在 kit #10–#17 修复（顶部已加 kit #21 状态注） | ✅ 当前（kit #21 注，2026-09-24）|
| `2026-09-21-ohos-device-report-template.md` | 下一轮真机回传一页模板（填补空白即可）：kit 身份/重签（含 p7b+p12+cer 预签路径）/安装/启动/§4b 验签/§4c app-lib 与首帧/探针 P1–P4/附件清单，供机器解析归档；数字一律指向 release「## Integrity」与 `tester-run.sh` 摘要 | ✅ 当前（kit #21，2026-09-24）|
| `2026-09-19-ohos-hap-acceptance-for-testers.md` | 完整验收说明：交付物、安装、A1–K2 与 N1–N7 清单、日志关键字与 status 对照、回传模板（包内名 `验收说明.md`；kit #21 已同步）| ✅ 当前（kit #21，preview.24）|
| `2026-09-21-ohos-device-run-playbook.md` | 真机运行操作手册：包内 `sh verify-kit.sh` 校验 → 安装/启动 → hilog 取证 → 5 条冒烟 → 9568344/E00C001 失败分支（含预签路径）与回传 | ✅ 当前（kit #21，v6r2）|
| `2026-09-19-ohos-signing-and-udid-guide.md` | `9568344` 根因（调试 profile 绑定 UDID）与自助/代签重签流程；含华为自动签名材料代签（`scripts/sign-huawei.sh`，包内名 `签名与UDID指南.md`）| ✅ 当前（2026-09-21）|
| `2026-09-20-ohos-dotnet-getting-started.md` | 第三方开发者英文上手：安装 workload、选 TFM/publish hap、签名与 UDID、故障排查 | ✅ 当前（2026-09-20）|
| `2026-09-21-ohos-tester-selfsign.md` | 未签名 hap 自助签名（DevEco 自动签名 + hap-sign-tool）；包内名 `自签说明.md`；kit #21 的 `签名说明.txt` PA1 句按历史文案处理 | ✅ 当前（kit #21，preview.24）|
| `2026-09-21-ohos-delivery-kit-readme.md` | kit 交付包总说明：基线 preview.24、5 hap 用途、安装与 9568344 指路（含预签路径）；包内名 `README-交付说明.md`；kit #21 已同步 | ✅ 当前（kit #21，preview.24）|

## 当前状态与规划

| 文档 | 一句话 | 状态（最后更新）|
|---|---|---|
| `2026-09-23-ohos-pr-review-compliance.md` | 上游 PR 评审规则遵循报告：R1–R11 规则表（来源评论/约定）、三份只读审计（runtime / sdk+aspnet / workload+maui）的偏差/违例 → 修复提交 → 脚本化复审计证据（grep/sha256/json/diff/树哈希/远端 ref）、有意保留与结构性清单、待上游动作（arcade 合并 / rerun / 复评 / issue 三问）；结论：硬违例 0、R1–R11 全合规 | ✅ 当前（2026-09-23）|
| `2026-09-23-ohos-security-scan-2.md` | 五仓库安全扫描 #2（3+2 猎手 + 4 份独立 PoC 对抗）：16 条候选（A1–A3、MB-1–3、H-C1–3、D-1–6、sec-e C3），**16 条全部已修**（含 H-C3 绝对路径 dlopen + 静态链接开关、CLI 已编译验证、binary-sign-tool 可选 pin、tar 成员负测）；上轮 23 条复核 21 有效 / B5 改名 / B6→H-C2 已修；含逐条攻击路径、`文件:行` 证据、复现命令与残留风险 | ✅ 当前（2026-09-23）|
| `2026-09-23-ohos-performance-scan.md` | 五仓库性能扫描 #2（宿主/原生 12 + 托管/UI/CI 19 个热点）：31 热点全部收口——扫描窗口 10 + 后置批次 16 + 最终回填 5（H10/P16/P9/P10/P19），**已修 29 · 残留 2**（Flatten 1144 B/帧属 Maui.Graphics、订阅 churn 有意保留）；帧分配 241,688→72,864→**4,504 B/帧**（门禁 13,824 B、CI 实测 3,720 B）、轮播 1759.7→441.2 ms、P12 读 **−82.9%**、P16 每轮少读 163.5 MB，门禁已加固（断言/jitter/缓存/PR/单一阈值） | ✅ 当前（2026-09-23）|
| `2026-09-23-ohos-napi-import-fix-playbook.md` | NAPI 导入形式修复作战手册（黑屏阻塞 #4）：问题复盘、候选修复 A（壳 import 形式，含精确 diff/重建/验证/入包发布链）/ B（`loadNativeModule` 动态加载）/ C（打包侧 pkgContextInfo 待研究落地），以及结果决策表与回滚步骤 | 🔄 待实验定形（2026-09-23）|
| `2026-09-22-ohos-render-route-decision.md` | 渲染路线决议（PJ4）：保持自绘合成器路线（单 XComponent + canvas + 自绘 IView/materializer + 影子无障碍树），不转原生 ArkUI 控件；附理由、混合路线与 UX 深度自实现清单（PJ1/PJ2 进行中，文本编辑/窗口 overlay/阴影未接） | ✅ 决议（2026-09-22）|
| `2026-09-22-ohos-elf-signing-research.md` | OHOS ELF 代码签名研究（PE1）：app 内 `.so` 的凭证是 HAP code signing block（`SoInfoSegment`，app 证书/Profile），不是文件内 `.codesign`；keyless self-sign（flags=0x10）只属独立二进制/PC 场景；新发现 payload 库不经 hap 签名、SDK 厂商 DevID 证书签名被我方重签为 keyless 两个问题；含工具矩阵、真机 kmsg/签名块检查命令与修复排序 | ✅ 当前（2026-09-22）|
| `2026-09-22-ohos-arkts-abc-version-history.md` | abc 版本史与 SDK 映射研究：version 字段/isa.yaml 对照、es2abc 与 `compatibleSdkVersion` 接线、可下载 SDK 清单、设备查询命令；结论：现有 SDK 26 工具链把 `compatibleSdkVersion` 设为 18–23 即产出设备可接受的 `13.0.1.0`（推荐 22 重建壳）| ✅ 当前（2026-09-22）|
| `2026-09-19-ohos-code-audit.md` | 主审计报告 §1–§37：五仓库代码/批次审计、真机前硬化、Blazor 与无障碍、S 系列（S1–S5）收官、T6/T8 补丁（要点见下节）| ✅ 当前主参考（2026-09-21）|
| `2026-09-22-ohos-maui-coverage-matrix.md` | MAUI on OpenHarmony 覆盖矩阵：切片/宿主/套件/演示只读审计——已实现（39 handlers 等）、部分（附代码证据）、未实现、SDK 阻塞与 Top-10 缺口（真机状态已指向 kit #21） | ✅ 当前（kit #21 注，2026-09-24）|
| `2026-09-21-ohos-security-scan.md` | 五仓库安全扫描（A1–A8、B1–B7、C1–C8）：23 项全部解决（22 项修复 + B6 构造性修复）、另 16 个区域无发现；修复均未经真机验证 | ✅ 当前（2026-09-21）|
| `2026-09-19-ohos-arkts-handover-status.md` | 交接状态：主线与版本、架构批次（D1–D4）、无障碍配方、操作坑、阻塞与剩余队列 | ✅ 当前（2026-09-20）|
| `2026-09-16-ohos-platform-workload-plan.md` | 以 iOS 为参照的完整平台 workload 迁移规划（终态/pack 拆分/TFM/安装器）| 🔄 规划基线（W1–W22 已据此执行，2026-09-16）|
| `2026-09-18-ohos-arkts-essentials-bridge-plan.md` | ArkTS 桥接 Essentials 的集成模式与逐 API 落地管线 | 🔄 计划（2026-09-19）|
| `2026-09-18-ohos-secure-storage-huks-plan.md` | SecureStorage 改用 HUKS 硬件密钥库的改造计划（当前为 XOR 回退实现）| 🔄 计划（2026-09-18）|
| `2026-09-18-ohos-openharmony-api-proposal.md` | 上游 API 提案草稿（`OSPlatform.OpenHarmony`、`OperatingSystem.IsOpenHarmony` 等）| 🔄 草稿待上游评审（2026-09-18）|
| `2026-09-18-ohos-device-validation-checklist.md` | 设备侧验证清单（英文）：每一步含命令与可观察结果；已更新到 kit #21（2026-09-24，数字指向 release「## Integrity」）| ⏳ 待设备（kit #21）|

## 主审计报告要点（`2026-09-19-ohos-code-audit.md`，§1–§37）

- **§1–§5**：探针通过项、本轮修复与建议项落地、对照上游 MAUI / 鸿蒙 Kit 的再次盘点。
- **§6–§13**：工作流 A–G 结果与不确定项（传感器精度、Launcher/Browser/Share、桌面菜单、拖放、触感+主题、ArkWeb JS 桥 + HybridWebView）。
- **§14–§19**：§8 刷新链修正；日历+联系人（H）；权限注入 + HybridWebView 资源服务；`__hwvInvokeDotNet` JS→.NET 闭环与 BlazorWebView 就绪评估。
- **§20–§22**：蓝牙发现/电池/显示/无障碍节点探测（191 项）；无障碍附着修复（host-only）；壳侧风险消除 K-1（14 个 sink 改走 `napi_threadsafe_function`）。
- **§23–§25**：多目标与 API 波段（20.0 → min=target=`60000020`/`Release`；26.0 → `60001021`/`60101024`/`Beta1`）；交付资产 + 版本横幅 + 蓝牙去重 + Blazor 里程碑 1；真机前硬化 Q1–Q3（`.codesign` 漂移根因与确定性打包）。
- **§26**：Q4/Q5 收官——交互回归套件纳入 CI 门禁、确定性 fuzz、上手文档交付。
- **§27–§28**：BlazorWebView 里程碑 2/3——native 模型（非 WASM）；Hap 资产管线与 ArkTS bootstrap 落地；托管 `WebViewManager`/handler 注册（2b）与真机验证待做。
- **§29–§31**：无障碍 provider R2/R2b（方向焦点、editable/checkable、16 参发布契约、range/checked 缺口）与 R3 文档级盘点（DevEco CLT 缺 hvigor、设备访问被策略拦截）。
- **§32–§34**：上游门控收尾项（R7，三分支/补丁就绪）；S3 手电筒（Camera Kit torch 跨三仓）与 S4 分享文件（`sendData` Want + `FLAG_AUTH_READ_URI_PERMISSION`）。
- **§35**：S 系列收官（S1 Blazor 管理器 · S2 无障碍节点数/分组层级 · S3 手电筒 · S4 文件分享 · S5 preview.24 刷新）：workload 1.0.0-preview.24、
  bundle/滚动 release/device-test-kit 重发（4 已签 + 1 未签 hap）、harness 208 条与真机前不确定项。
- **§36**：静态 Web 资产指纹回退与响应缓存头（shell T6）：hybrid/Blazor 共用负载路径按 `name.<hash>.ext → name.ext` 只回退一次；
  指纹请求 `immutable`、其余 `no-cache`；ArkTS 探查证明对象字面量 header map 可编译（被拒的是 `RegExpMatchArray` 显式标注）。
- **§37**：`DeviceDisplay.KeepScreenOn` 跨三仓（T8）：托管 `ohos_host_keep_screen_on` → 宿主单向 sink → 壳
  `window.getLastWindow` + `setWindowKeepScreenOn`；类型检查与 216 条 harness 断言通过，真机常亮行为待验证。

## 运行时 / SDK 上游移植阶段（历史：2026-08-13 → 2026-09-15）

> 记录 dotnet/runtime、sdk、aspnetcore 上游化过程中已完成的工作与决策（RID 命名、syscall、版本对齐、PR 拆分等）；当前状态以审计报告与交接文档为准。

| 文档 | 一句话 | 状态（最后更新）|
|---|---|---|
| `2026-08-13-ohos-cross-compile.md` | 路线②交叉编译 dotnet/runtime 执行计划（仿 linux-bionic NDK；执行纪律/问题循环）| 📦 历史（2026-09-01）|
| `2026-08-27-ohos-upstream-pr-prep.md` | 上游 PR 准备：`linux-ohos` RID 范围与全量交叉构建验证 | 📦 历史（2026-08-31）|
| `2026-08-28-ohos-pr-plan-post-132827.md` | PR#132827 之后剩余 3 个 PR 的拆分、29 文件清单与依赖 | 📦 历史（2026-08-31）|
| `2026-08-28-ohos-pr-plan-revised.md` | NativeAOT E2E 后修订的 runtime+SDK PR 计划（含评审反馈）| 📦 历史（2026-09-14）|
| `2026-09-01-ohos-ondevice-verification.md` | runtime/sdk/aspnetcore 真机验证（交叉构建产物 + NativeAOT）| 📦 历史（2026-09-02）|
| `2026-09-01-ohos-syscall-audit.md` | `TARGET_LINUX` / `__NR_*` 系统调用审计（回答评审问题）| 📦 历史（2026-09-16）|
| `2026-09-02-cxx-runtime-handoff.md` | cxx-runtime 第三轮重建/重发交接（ilc 缺库往返）| 📦 历史（2026-09-06）|
| `2026-09-03-nativeaot-platform-analysis.md` | NativeAOT 平台分流机制分析（macOS / linux-musl / OpenHarmony 独立旁支）| 📦 历史（2026-09-03）|
| `2026-09-03-ohos-openharmony-rename-impact.md` | RID 改名 `ohos` → `openharmony` 的影响分析与决策过程 | 📦 历史（2026-09-13）|
| `2026-09-03-ohos-pr-inclusion-audit.md` | 上游 PR 文件纳入审计（不得进入 PR 的文件清单）| 📦 历史（2026-09-04）|
| `2026-09-04-26451-109-device-verify.md` | 26451.109 pure-IL CoreLib 真机验证 | 📦 历史（2026-09-05）|
| `2026-09-04-openharmony-rename-build-verify.md` | 改名分支的构建侧验证清单 | 📦 历史（2026-09-04）|
| `2026-09-05-26451-109-fresh-install.md` | 全新安装 SDK 验证与 console 回归阻塞记录 | 📦 历史（2026-09-06）|
| `2026-09-06-porting-code-compliance-audit.md` | 移植代码规范合规审计（对照上游 conventions）| 📦 历史（2026-09-16）|
| `2026-09-06-version-alignment-darc-vmr.md` | 版本对齐策略（darc/VMR 研究 + 手工 fork 方案）| 📦 历史（2026-09-06）|
| `2026-09-07-ohos-pr-plan-bsd-haiku-model.md` | 按 BSD/Haiku 落地模型重排的上游 PR 计划 | 📦 历史（2026-09-16）|
| `2026-09-15-ohos-platform-identity.md` | 平台身份决策记录（`IsOSPlatform("openharmony")` 语义）| 📦 决议（2026-09-15）|
| `2026-09-16-maui-ohos-feasibility.md` | MAUI → OpenHarmony 可行性分析（Tizen 先例、UI 层工作量）| 📦 历史（2026-09-16）|
| `2026-09-16-maui-ohos-p0.md` | 应用内 host 探针 P0（设备节点可达 + ArkUI NDK 节点创建）| 📦 历史（2026-09-16）|

## workload 工作项 W 系列快照（历史：2026-09-16 → 2026-09-18）

> W1–W22 逐工作项的交付记录（无 W4 文档）；后续演进与真机结论见主审计报告、交接状态。

| 文档 | 一句话 | 状态（最后更新）|
|---|---|---|
| `2026-09-16-ohos-workload-w1-status.md` | 本地 DevEco-less workload 骨架（Sdk/Ref/Runtime pack + manifest）| 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w2-status.md` | 原生宿主 + ArkTS 壳 + `publish → hap` 管线 | 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w3-status.md` | 壳↔托管打通（生命周期/宿主路径/NodeContent 通道 + ELF 签名）| 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w5-status.md` | workload 可安装（本地 feed）+ MAUI 自动检测闭环 | 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w6-status.md` | workload 打包为可交付 bundle 并接入 SDK 安装/构建流 | 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w7-status.md` | 发布通道（版本化 + 滚动 `workload-latest`）与安装器加固 | 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w8-status.md` | 官方 ArkTS 工具链（hvigor，无需 DevEco）构建 UI 壳 | 📦 快照（2026-09-17）|
| `2026-09-16-ohos-workload-w9-status.md` | 渲染表面握手：ArkUI `XComponent` 到达托管 | 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w10-status.md` | W9 收尾（预构建 UI 壳随包等）+ W10 渲染器点亮（首帧/宿主填面 API）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w11-status.md` | XComponent 表面上的渲染器路径（`native_drawing` 画布）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w12-status.md` | `Microsoft.Maui.Graphics` 画布后端 | 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w13-status.md` | `ICanvas` 语义补全（近似/no-op → 真实实现）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w14-status.md` | 渐变与阴影（清除最后的绘图 no-op）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w15-status.md` | 输入与帧 tick 钩子 + Graphics 视图树 demo | 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w16-status.md` | pattern paints（最后的 `ICanvas` 缺口）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w17-status.md` | MAUI 双轨启动：平台切片 A + 可真机验证 demo B | 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w18-status.md` | 首批真实 MAUI handlers 与合成器 | 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w19-status.md` | 真实 MAUI 应用接入平台契约（应用宿主）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w20-status.md` | 真实 MAUI 应用打包为可安装 hap（`test/hello-maui-app`）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w21-status.md` | window handler 完成 + 控件面扩展（headless 验证）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w22-status.md` | 最大一批：Entry 输入、值控件/导航/动画/Picker/Shell/虚拟化、Essentials、像素 harness 与缺陷定位（W22-1…-28）| 📦 快照（2026-09-18）|
