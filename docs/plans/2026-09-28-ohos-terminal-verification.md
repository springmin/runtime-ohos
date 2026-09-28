# 终态复核（kit #30）：五仓 / 发布资产 / kit 抽验 / bundle / CI / 文档一致性（2026-09-28）

> 独立只读终态复核（final-verify）。两段时点：**首发 08:50**（kit #30 未发布；第 1/4/5 项完成，第 2/3/6 项登记「待 VALUES」）；
> **发布后补记 10:05**（kit #30 已发布、`reg-kit30/RELEASE-VALUES.txt` 120 行 0 PENDING；第 2/3/6 项补齐，全部 PASS）。
> 证据：`gh api`（release/run/body/asset by-id）、gh-proxy 独立下载（sha256/解包/verify-kit）、`git rev-parse/rev-list/reflog`、
> install-tests 日志。本报告为新增文件，不改动他人文档。

## 1. 五仓一致性 — PASS（含并行的非 kit 工作注记）
- runtime-ohos：首发 local `66484ea9508` vs origin `ad807b92b39`（0/1）；窗口内 origin 依次前进 `e26a03ea`（他人 docs）→ 本报告
  `9b713233270`（临时 worktree 快进推送）→ `1ec0efec16b`/`479596c8d28`/`eab59f0f410`（KIT30-DOCS 文档同步与 manifest）；全程线性链，
  无强推（remote-tracking reflog 逐条 old==前条 new）；`main` local==origin `719009acffb`（0/0）。
- ohos-workload `master`：`6cdd1faa289` → 发布批 `d1d7b70`（ridgraph pin）；sdk-ohos `feature/openharmony`：`6c86e2d13b` →
  `a691bf11dd`（bundle 重锚）→ `1cbc1b8a6a`（后续 MSBuild pipe 提交，已 fetch 复核）；aspnetcore-ohos `07ed2fe38d`、maui-ohos
  `4b5756de44` 均 0/0。
- 工作树：另有一并行代理的 Blazor WASM 冒烟在途残留 2 条（ohos-workload `M .gitignore` + `?? test/hello-blazorwasm/`，非 kit #30）；
  maui 44 条稀疏 `??`（固有）；其余仓 0 跟踪修改。本评审全程未触碰共享检出。

## 2. 发布资产 vs RELEASE-VALUES（kit #30）— PASS
- kit tar：**196,992,264 B / `a781c25b…`**（gh-proxy 独立下载 sha == 本地 sha == `gh api` by-id digest == VALUES）；sidecar 89 B
  内容 == tar sha、文件 sha `a63cd34f…` == VALUES；tree digest `cc1ca935…`（verify-kit 实测一致）。
- 变更集（我自采 pre/post `gh api` 快照 diff）：dtk 24→24，恰好 {tar, sidecar} 2 项变化（新 asset id 594175824/594188879）、
  22 项字节不变、0 增 0 删；workload-latest 4/4 全换；preview.24 2/2 全换；SDKREL 35→35 仅 {bundle, SHA256SUMS} 变化、33 项不变；
  与 VALUES `*_assets_changed/unchanged` 及 zero-change 清单相符。
- 零改动资产复核：tester-run v12 `87763a3e…`/126,658（id 593961018）、harmony v2 `9b0506fa…`/196,898,796（593868367）、
  aot `91e1b9d3…`/17,093,146（592465115）、interp `a10699b3…`/2,419,988（590052493）。
- bundle 三处（workload-latest / preview.24 / SDKREL）**30,563,349 B / `c4647fc8…`**；两处 `SHA256SUMS` 212 B / `145928a5…`，
  内容两行均指向 `c4647fc8…`（独立下载复核）。
- 四处 release notes（dtk / workload-latest / preview.24 / SDKREL）均含 `## Integrity (kit #30)`（fresh `gh api` body 复核，4/4）。

## 3. kit #30 实质抽验 — PASS
- 独立下载 tar → `sh verify-kit.sh --anchor-file <我下载的 tar> --expect-tree-digest cc1ca935…`：**rc=0 / KIT OK / 0 FAIL / 0 WARN**
  （anchor `a781c25b` OK、tree OK、5 hap 的 index/abc/libs/payload-in-libs/宿主依赖断言全过）。注：该脚本无 `--kit-tar` 旗标，
  以 `--anchor-file` 绑定 tar（KIT30 本地亦用 `--expect-tree-digest`），策略已在命令中注明。
- 包内抽验：`libs/arm64-v8a/runtime-mode.txt=jit`（5/5，MS-MODE 标记）；hap 内宿主 285,600 B / `de9b30dd…`（签名自 `f6b3581a…`）；
  abc 281,052 B / `5c06143a…` @13.0.1.0（5/5）；libs 270 项；宿主字面量 `runtime-mode=`×7 / `OH_Huks_`×11 / `ohos_host_tts_available`
  / `notifyActivation`；abc 字面量 CoreSpeechKit×5 / probeTtsKit×2 / registerTtsSink / notifyActivation；`SHA256SUMS` 15 项全过；
  tester-run v12 版本行（`SCRIPT_VERSION="12 (2026-09-28)"`）。
- bundle（独立下载 `c4647fc8`）Sdk pack preview.24：346,067 B；`Hap.targets` 66,415 B / `db9a5491…`（含 `_OpenHarmonyStageRuntimeMode`
  + 23 处 runtime-mode 引用）；`MapOverlay.ets` 11,396 B / `1d9871ec…`；host 281,504 B / `f6b3581a…`（含 aot 回退与 unknown-value 警告文案）。

## 4. bundle / 锚 — PASS
- 三处 bundle 与 sdk-ohos `eng/ohos-install/versions.env` 同锚：`WORKLOAD_BUNDLE_SHA256=c4647fc8…`（`WORKLOAD_BUNDLE_VERSION=1.0.0-preview.24`）；
  锚提交 `a691bf11dd`（"re-anchor the workload bundle digest (kit #30)"，仅 versions.env 1 行）在历史中，tip `1cbc1b8a6a` 同值。
- 安装器测试：`ohos-install-tests` run `36367015490`（锚提交 `a691bf11dd`）success；`36357437640`（`6c86e2d13b` 锚期）success；
  VALUES 记录本地 43/43、10/10、5/5（新锚）。
- 首发时点记录的 kit #29 尾态 `c2b527d3…` → 现 `c4647fc8…`，属重打包预期。

## 5. CI — PASS（harmony-flavor 例外）
- ohos-workload @发布批 `d1d7b70`：interaction `36364725359` / pixel `36364725327` / host-export `36364725283` / ridgraph `36364725293`
  / markdownlint `36364725282` 全 success；批次 tip `6cdd1faa28` 五门禁全 success（36357605608/602/604/624/605）。
- sdk-ohos：ohos-install-tests `36367015490` success + `36357437640` success；ohos-full-build `36356790450` success。
- harmony-flavor（workflow 368592158）：0 runs（仅 workflow_dispatch + 周计划，不随 push）——残余风险。

## 6. 文档一致性 — PASS
- 复测任务单 / handoff-kit30 / final-status 与发布后版本均与 VALUES 一致：taskcard（kit #30、v12 126,658/`87763a3e`、abc 锚 281,052/20,916、
  aot/harmony/interp 数字）；handoff30（391/floor 371、abc `5c06143a`/headless `54a1a201`、143/143、runtime-mode 口径）；final-status
  （当前 = kit #30，kit #29 标历史，v12 126,658/`87763a3e`、391/371）；release-manifest 收录全量精确数字（tar/sidecar/tree/bundle/
  host/targets/MapOverlay/锚提交）。
- 旧值扫描（committed tip）：`e895cc0a` / `d3a7b718` / `f7a4faa2` / `2355e493` 仅出现在历史对照语境（kit28/kit29 快照、旧件说明、
  v11 版本沿革），无「当前 kit」误用；sdk 锚 `a691bf11dd` == bundle sha（见 §4）。
- 过时指针提示：`docs/plans/README.md` 中本报告的行仍写「🔄 待 kit #30 发布后补第 2/3/6 项」——已补齐，建议文档 owner 翻为 ✅
  （本评审只写本文件，不与他人文档并行抢改）。

## 外部依赖清单（不在本仓/本复核控制）
- 真机轮（JIT/XWE/AOT/解释器/harmony 五态 + 无障碍）：测试方设备与回传。
- HMS 设备 + AGC 权益（Map 地图服务/指纹、LiveView TIMER、Push、Account）与 CoreSpeechKit 真朗读；华为调试证书/Profile（UDID）用于重签（包内自签）。

## 残余风险
- kit #30（stock）设备复测仍未执行：包已发布 + 本地全量抽验（含独立下载与 verify-kit 0/0），真机证据待测试方。
- harmony-flavor 门禁从未运行（dispatch/周计划）；MAPFIX 由 harmony v2 abc 记录与本地 102/102 复核支撑。
- TTS 真朗读 / HUKS 打包 hap 全回合 / 深链系统投递依赖外部环境，未验边界不变。
- 并行代理在 ohos-workload 留有 2 条未提交 Blazor WASM 冒烟残留（§1），发布链以外、不影响本批复核结论。
