# docs/plans 文档索引

> 本目录是 OpenHarmony .NET/MAUI 移植的过程文档库：测试/交付文档、主审计报告、交接状态与历史批次记录。
> 「状态（最后更新）」列 = 用途 + 该文件最近一次 git 提交日期。图例：✅ 当前生效 · 🔄 进行中/计划 · ⏳ 待执行 · 📦 阶段快照（已完成工作的记录）。
> 「包内名」指该文档随设备测试 kit 分发时的文件名。

## 面向测试与交付（外部读者优先）

| 文档 | 一句话 | 状态（最后更新）|
|---|---|---|
| `2026-09-20-ohos-tester-quickstart.md` | 外部测试方一页版：下载校验 → 选 hap → 安装 → 先测 5 条 → 回传格式 | ✅ 当前（2026-09-21）|
| `2026-09-19-ohos-hap-acceptance-for-testers.md` | 完整验收说明：交付物、安装、A1–K2 与 N1–N7 清单、日志关键字与 status 对照、回传模板（包内名 `验收说明.md`）| ✅ 当前（2026-09-20）|
| `2026-09-19-ohos-signing-and-udid-guide.md` | `9568344` 根因（调试 profile 绑定 UDID）与自助/代签重签流程（包内名 `签名与UDID指南.md`）| ✅ 当前（2026-09-19）|
| `2026-09-20-ohos-dotnet-getting-started.md` | 第三方开发者英文上手：安装 workload、选 TFM/publish hap、签名与 UDID、故障排查 | ✅ 当前（2026-09-20）|

## 当前状态与规划

| 文档 | 一句话 | 状态（最后更新）|
|---|---|---|
| `2026-09-19-ohos-code-audit.md` | 主审计报告 §1–§31：五仓库代码/批次审计、真机前硬化、Blazor 与无障碍等（要点见下节）| ✅ 当前主参考（2026-09-21）|
| `2026-09-19-ohos-arkts-handover-status.md` | 交接状态：主线与版本、架构批次（D1–D4）、无障碍配方、操作坑、阻塞与剩余队列 | ✅ 当前（2026-09-20）|
| `2026-09-16-ohos-platform-workload-plan.md` | 以 iOS 为参照的完整平台 workload 迁移规划（终态/pack 拆分/TFM/安装器）| 🔄 规划基线（W1–W22 已据此执行，2026-09-16）|
| `2026-09-18-ohos-arkts-essentials-bridge-plan.md` | ArkTS 桥接 Essentials 的集成模式与逐 API 落地管线 | 🔄 计划（2026-09-19）|
| `2026-09-18-ohos-secure-storage-huks-plan.md` | SecureStorage 改用 HUKS 硬件密钥库的改造计划（当前为 XOR 回退实现）| 🔄 计划（2026-09-18）|
| `2026-09-18-ohos-openharmony-api-proposal.md` | 上游 API 提案草稿（`OSPlatform.OpenHarmony`、`OperatingSystem.IsOpenHarmony` 等）| 🔄 草稿待上游评审（2026-09-18）|
| `2026-09-18-ohos-device-validation-checklist.md` | 设备侧验证清单：每一步含命令与可观察结果（等待可安装设备；示例产物为 preview.14）| ⏳ 待执行（2026-09-18）|

## 主审计报告要点（`2026-09-19-ohos-code-audit.md`，§1–§31）

- **§1–§5**：探针通过项、本轮修复与建议项落地、对照上游 MAUI / 鸿蒙 Kit 的再次盘点。
- **§6–§13**：工作流 A–G 结果与不确定项（传感器精度、Launcher/Browser/Share、桌面菜单、拖放、触感+主题、ArkWeb JS 桥 + HybridWebView）。
- **§14–§19**：§8 刷新链修正；日历+联系人（H）；权限注入 + HybridWebView 资源服务；`__hwvInvokeDotNet` JS→.NET 闭环与 BlazorWebView 就绪评估。
- **§20–§22**：蓝牙发现/电池/显示/无障碍节点探测（191 项）；无障碍附着修复（host-only）；壳侧风险消除 K-1（14 个 sink 改走 `napi_threadsafe_function`）。
- **§23–§25**：多目标与 API 波段（20.0 → min=target=`60000020`/`Release`；26.0 → `60001021`/`60101024`/`Beta1`）；交付资产 + 版本横幅 + 蓝牙去重 + Blazor 里程碑 1；真机前硬化 Q1–Q3（`.codesign` 漂移根因与确定性打包）。
- **§26**：Q4/Q5 收官——交互回归套件纳入 CI 门禁、确定性 fuzz、上手文档交付。
- **§27–§28**：BlazorWebView 里程碑 2/3——native 模型（非 WASM）；Hap 资产管线与 ArkTS bootstrap 落地；托管 `WebViewManager`/handler 注册（2b）与真机验证待做。
- **§29–§31**：无障碍 provider R2/R2b（方向焦点、editable/checkable、16 参发布契约、range/checked 缺口）与 R3 文档级盘点（DevEco CLT 缺 hvigor、设备访问被策略拦截）。

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
