# 终态复核（kit #30）：五仓 / 发布资产 / kit 抽验 / bundle / CI / 文档一致性（2026-09-28）

> 独立只读终态复核（final-verify）。复核时点 **2026-09-28 08:50 前后**；截至该时点 **kit #30 未发布**
> （`reg-kit30/RELEASE-VALUES.txt` 未写、release 资产未替换、KIT30 仍在 preflight），故第 2/3/6 项按
> 「待 VALUES」登记，第 1/4/5 项为实测结论。证据：`gh api`（release/run/body）、gh-proxy 实测下载（sha256/解包/
> verify-kit）、`git rev-parse/rev-list/reflog`、install-tests 日志。本报告为新增文件，不改动他人文档。

## 1. 五仓一致性 — PASS（含时点说明）
- runtime-ohos：复核起点 local `66484ea9508` vs origin `ad807b92b39`（0/1，本地落后 1）；复核窗口内 origin 再前进到
  `e26a03ea8fd`（另一并行代理 08:00 的 docs 提交，与本批评审无关）；本报告经临时 worktree 基于 origin 当前 tip
  快进推送（无强推），未触碰共享检出；`main` local==origin `719009acffb`（0/0）。
- ohos-workload `master` local==origin `6cdd1faa289`（0/0）；sdk-ohos `feature/openharmony` `6c86e2d13b`（0/0）；
  aspnetcore-ohos `feature/openharmony` `07ed2fe38d`（0/0）；maui-ohos `feature/openharmony` `4b5756de44`（0/0）。
- 工作树：runtime-ohos 有 KIT30-DOCS 的 19 处未提交 docs 编辑（非本评审文件，未触碰）；ohos-workload/sdk-ohos/
  aspnetcore 0 处跟踪修改；maui-ohos 0 跟踪修改 + 44 条稀疏 `??`（固有）。
- 五仓 remote-tracking reflog 全为线性链（旧值=前一条新值），无强推/回卷痕迹。

## 2. 发布资产 vs RELEASE-VALUES — 待 VALUES
- 复核时点 release `392356147` 仍为 kit #29 资产：dtk tar 196,990,205 / `e895cc0a…`（18:28Z）、tester-run v12
  126,658 / `87763a3e…`（23:05Z）、harmony v2 196,898,796 / `9b0506fa…`（22:03Z）；四处 notes 仍
  `## Integrity (kit #29)`（dtk / workload-latest `392077166` / preview.24 `392616481` / SDKREL `388357742`）。
- 先行的独立实测（可复用）：tester-run v12 下载 sha 一致；harmony v2 tar sha 一致且 abc 291,628 / `a637a513…`
  含 `entry/ets/map/MapOverlay` 模块记录 + `mapOverlayView`/`markerClick`/`cameraIdle`；aot-haps 17,093,146 /
  `91e1b9d3…`、interp pack 2,419,988 / `a10699b3…` 下载 sha 与包内 `SHA256SUMS` 全过。
- 待补（kit #30 发布后）：全资产表逐项对照 VALUES + 四处 notes 含 `## Integrity (kit #30)`。

## 3. kit #30 实质抽验 — 待 VALUES
- 待做：tar 下载 → sha256 → 解包 `verify-kit.sh --anchor-file … --expect-tree-digest …` 期望 0 FAIL/0 WARN；
  抽查 `libs/arm64-v8a/runtime-mode.txt`（MS-MODE 预期 jit）、宿主 `runtime-mode=`/aot 回退行、TTS/深链/HUKS
  字面量、tester-run v12 版本行。
- 基线（本地实跑）：kit #29 verify-kit rc=0 / KIT OK / 0 FAIL / 0 WARN（tree `5b28d577…`）；kit #29 宿主无
  `runtime-mode` 串；kit #29 bundle 的 `Microsoft.OpenHarmony.Sdk` pack（343,080 B）Hap.targets 无
  `OpenHarmonyRuntimeMode` —— 均为 kit #30 的对照点。

## 4. bundle / 锚 — PASS（kit #29 尾态；kit #30 重打包后需复验）
- 三处一致：`openharmony-workload-latest.tar.gz` = `openharmony-workload-1.0.0-preview.24.tar.gz`（workload-latest
  `392077166` / preview.24 `392616481` / SDKREL `388357742` 同名资产）= 30,552,107 B / `c2b527d3…`；两处
  `SHA256SUMS`（212 B）字节相同。
- sdk-ohos `eng/ohos-install/versions.env`：`WORKLOAD_BUNDLE_VERSION=1.0.0-preview.24` /
  `WORKLOAD_BUNDLE_SHA256=c2b527d3…`（与三处同锚）。
- 安装器测试：`ohos-install-tests` run `36357437640`（tip `6c86e2d13b`）success；D-4 日志含 anchored digest /
  版本化+滚动 bundle 名 → 64-hex 锚 PASS。

## 5. CI — PASS（harmony-flavor 0 runs）
- ohos-workload @`6cdd1faa28`：interaction `36357605608` / pixel `36357605602` / host-export `36357605604` /
  ridgraph `36357605624` / markdownlint `36357605605` 全 success。
- sdk-ohos @`6c86e2d13b`：ohos-install-tests `36357437640` success；ohos-full-build `36356790450` success。
- harmony-flavor（workflow 368592158）：0 runs（触发仅 workflow_dispatch + 周计划，不随 push）——见残余风险。

## 6. 文档一致性 — 待 VALUES
- 预核（committed）：handoff30 草稿引用的 asset id/数字与当前 release API 一致（tester-run id `593961018`；
  harmony id `593868367`；aot `592465115` / interp `590052493` 与判定卡一致）。KIT30-DOCS 的 19 处编辑未提交，
  待 VALUES 后复核复测任务单 / handoff-kit30 / final-status / 判定卡。
- 旧值扫描：`d3a7b718`/`f7a4faa2` 仅出现在历史对照（kit28/kit29 交接、README 快照行、判定卡旧件对照）；
  `2355e493` 仅出现在 v11 历史语境（quickstart/tester-runner/final-status/crash-probes 等）——final-status 尚未
  更新到 v12/kit30（待其本轮提交后复核）。

## 外部依赖清单（不在本仓/本复核控制）
- 真机轮（JIT/XWE/AOT/解释器/harmony 五态 + 无障碍）：测试方设备与回传。
- HMS 设备 + AGC 权益（Map 地图服务/指纹、LiveView TIMER、Push、Account）与 CoreSpeechKit 真朗读；
  华为调试证书/Profile（UDID 绑定）用于重签（包内为自签）。

## 残余风险
- kit #30 未发布（复核截止时 KIT30 仍在 preflight，08:26 重启过一轮）→ 发布后须补第 2/3/6 项与 kit 抽验。
- kit #30（stock）设备复测未执行；本报告不替代真机判定（任务单明确 stock 包未上机）。
- harmony-flavor 门禁从未运行（dispatch/周计划）；MAPFIX 记录由构建证据 + harmony v2 abc 记录支撑。
- TTS 真朗读 / HUKS 打包 hap 全回合 / 深链系统投递依赖外部环境，未验边界不变。
- runtime-ohos 共享检出落后 origin 2（KIT30-DOCS 未提交编辑所在）；本报告经临时 worktree 快进推送。
