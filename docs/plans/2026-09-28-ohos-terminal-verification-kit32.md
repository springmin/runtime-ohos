# 终态复核（kit #32）：五仓 / 发布资产 / kit 抽验 / bundle / CI / 文档一致性（2026-09-28）

> 日期口径：文件名按任务指定日；kit #32 发布日 = **2026-09-28**（RELEASE-VALUES `date`）。
> 独立只读复核（KIT32-VERIFY）。轻量策略：by-id digest == 本地 sha + 本地 verify-kit + 自取小件（bundle 30.6 MB / v14 140 KB）；
> 不做 207 MB 全量下载。证据：`reg-kit32/RELEASE-VALUES.txt`（98 行 FINAL）、GitHub release API（by-id digest/size + body）、`gh api` branch tips / Actions runs、
> 全新解包 `kit32-verify/kit` + 包内 verify-kit + 独立深断言 + gh-proxy 独立下载（bundle/v14/边车/README）；
> 证据留存 `/data/storage/el2/base/tmp/opencode/kit32-verify/`（verify-kit-fresh.log / verify-kit-bare.log / api/ / dl/ / ci-sdk-*-failed.log）。本报告为新增文件；不改动他人文档。

## 1. 五仓一致性 — PASS（含并发推送注记）
- runtime-ohos：复核起点 local==origin `79b806a7f38`，工作树干净；复核期间远端线性前进两笔（`100c65f1c2a` docs 回填 kit #32 实测值、`3739db31460` rc2 迭代 6），本报告基于 fetch 后 tip。
- ohos-workload：`0669fbc` local==origin（0/0），干净；reflog 全 `update by push`（无强推）。
- maui-ohos：`33b0af79`（本地 == GitHub API；检出 refspec 仅 main，remote-tracking 陈旧属预期）；43 条稀疏 `??`（固有）；无强推。
- sdk-ohos：`feature/openharmony` 复核窗口内 tip 三易（起点 `021fa55c31` → `06585cc9f4` → `50e3538e85`，全部线性 push）；锚 `b4e76a6239` 在该历史内；anchor worktree = `reg-kit31/sdk-anchor-wt`。
- aspnetcore-ohos：`07ed2fe38d47` local==origin（0/0），干净；线性。

## 2. 发布资产 vs RELEASE-VALUES — PASS
- by-id digest+size（4 口 release，gh api 重取）：dtk tar 595109152 **207,114,608/`8f690949…`**、sidecar 595113031 **89/`344760e7…`**、tester-run 595131362 **140,197/`a174fcd0…`**、
  razor 595131900 **38,968,818/`5e549506…`** + 边车 595132961 **89/`3f4cc4d6…`** + README 595133464 **2,617/`ff56faff…`**；latest：bundle 595134398 `286a923e…`、sums 595135585 `0d6a8fa8…`、
  kit 595136171、sidecar 595139864；preview24：bundle 595140367、sums 595141265；sdkrel：bundle 595141700、sums 595142987。全部 == VALUES。
- changed/added/removed（对 `reg-kit31/cur-*` 原响应快照重算）：dtk 24→27 恰 +3 razor、changed {kit tar, sidecar, tester-run}、**21 项零改动**；latest 4/4 全换；preview24 2/2；
  sdkrel 35→35 恰 {bundle, sums}、**33 项零改动**；其余 added/removed 全 0。与 `zero_change_list` 逐项一致。
- 4 处 body 均含 `## Integrity (kit #32)` 且无 `## Integrity (kit #31)` 段（仅 dtk 保留一处 #31 历史对照词）。

## 3. kit #32 实质抽验 — PASS
- 全新解包（本地 tar sha == release by-id）：`sha256sum -c SHA256SUMS` **16/16**（`SHA256SUMS` 1,410 B/`2d3f2fad…`）；包内 `verify-kit.sh` 66,661/`f72a4a3c…`。
- `sh verify-kit.sh --anchor 8f690949… --anchor-file <tar> --expect-tree-digest 645879bc… --expected-abc 289992,20916` → **RC=0 / KIT OK / 0 FAIL / 0 WARN**（anchor OK、tree OK）。
- 6 hap sha 全等 VALUES（75,866,199/`ffa545fd`、73,684,666/`8658f45a`、75,870,309/`973f692f`、75,866,219/`b614f9a2`、75,870,334/`71bb121d`、26,803,570/`5011cf73`）；
  5 个 MAUI hap `ets/modules.abc` = **289,992/`e005f236`**；Blazor hap **requestPermissions=0（缺省）**、own abc 21,084/`4069e453`。
- razor 资产内 `hello-maui-razor-unsigned.hap` **73,656,242/`b4d305f0`**、bundle `com.example.hellomauirazor`、**requestPermissions=0**、abc 289,992/`e005f236`、
  `dotnet.zip` 259 项含 `wwwroot/index.html` + `_framework/blazor.webview.js` + `_framework/blazor.modules.json` + `js/app.js`、0 `.wasm`/无 `dotnet.js`。
- tester-run v14（自取字节 == `a174fcd0…/140,197`）：`SCRIPT_VERSION="14 (2026-09-28)"`，pidof + `session nonce` 绑定逻辑在位。
- 注：包内 verify-kit 默认 abc 集仍为 `281052,20916`；直跑为 **5 WARN / KIT OK**，0 WARN 需按文档固定 `--expected-abc 289992,20916`（两次运行均复现）。

## 4. bundle / 锚 — PASS
- bundle `286a923e…/30,566,929` 三处 release by-id 一致；自取 gh-proxy 字节 == 本地 == VALUES；`SHA256SUMS` `0d6a8fa8…/212` 三处一致（自取同值，两行均指 bundle）。
- 锚 `b4e76a6239`：1 文件 1 行（`versions.env` `43a78c8f…` → `286a923e…`）；tip `06585cc9f4` 的 `versions.env` == `286a923e`；push 线性无强推；安装器测试 43/43+10/10+5/5。

## 5. CI — 如实记录（ow 5/5；sdk 红，复核后已修复）
- ohos-workload @`0669fbc`：interaction 36413679129、pixel 36413679114、host-export 36413679364、ridgraph 36413679183、markdownlint 36413679200 全 success（5/5）。
- sdk-ohos `ohos-install-tests` @`b4e76a6239` run 36408131147 **failure**：job `install-tests` step 6「SDK tarball architecture guard (libdotnet-aot, P1-2)」= **17 passed / 4 failed（rc=127）**。
  初步归因：`test-sdk-arch-check.sh:151-152` 仍从 `build/build-ohos-all.sh` sed 抽取 `prune_stale_sdk_aot_libs`/`verify_sdk_tarball_arch` helper，而 `83b5a2f8d8`（stage 4 拆分）后定义在 `build/pack-sdk.sh`
  （`build-ohos-all.sh:36` 自述）→ 抽到空定义。该 workflow 自 `83b5a2f8d8` 首红起连红 10 笔（首个红 run 36391099451；最后绿 = `b2b79e27d9` run 36378113086）；steps 3/4/5 全过、本地三脚本全绿、锚提交仅 1 行差异 → 与 kit #32 发布无因果。
  日志：https://github.com/springmin/sdk-ohos/actions/runs/36408131147 （`gh run view 36408131147 --log-failed`）。
- **复核后补记（19:47）**：sdk-ohos `50e3538e85`「read the SDK arch helpers from their stage-4 owner」把 `BUILD_SCRIPT` 改指 `build/pack-sdk.sh`——与本报告归因一致；`ohos-install-tests` run 36417772507 **success（21/0）**。上条红色为发布时点如实记录。
- 注：`ohos-full-build` run 36411484465（dispatch @`b4e76a6239`）当前状态 = **cancelled**（VALUES 记「in progress at report time」）。

## 6. 文档一致性 — PASS（3 处小陈旧，非阻断）
- manifest（`79b806a7f38`）发布数字逐项 == VALUES：tar/树/sidecar/16 项 SUMS/6 hap/v14/razor 3 项/bundle+sums/锚/CI 5/5/abc 289,992；包内测试文档按设计不写死哈希。
- 旧值扫描：kit #32 波文档中的 #31 值（`f4325d2f`、`2caa06bd`、`43a78c8f`、`b2b79e27d9`、`36010a9c`、`281052` 等）均在「#31 = … 对照 / 历史」语境，无冒充当前发布值。
- 待修小项（供 docs agent）：① manifest §2 标题「24 项」而表内 27 行；② manifest「一条命令」段仍以 v13 描述当前器（应 v14）；③ README 索引 3 行滞后：
  blazor 一页纸行（对象列仍写 #31 hap `26,794,931/36010a9c`、状态「kit #31」，文件自身已是 #32）、复测单行（摘引 v13 `137,113/2caa06bd`，卡片自身已是 v14）、manifest 行（状态「kit #31」）。

## 残余风险 / 不确定项
- WebView 9 项、B1 razor 两标记/JS 往返、Blazor 组件（0 权限）重签后行为仍只能真机闭环——本复核只到包内静态断言。
- sdk `ohos-install-tests` 为仓库测试接线 bug（第 5 节），复核后已修复并转绿（`50e3538e85`，run 36417772507 success 21/0）。`ohos-full-build` 被取消，SDK 全量构建本轮无绿色结论。
- 签名的本机 razor hap 两处数字不一致（交接文/接线文 `75,889,768 B` vs VALUES `75,896,983 B/2124fa7c…`）；均本地留存、不在发布资产，发布以未签 `b4d305f0` 为准。
- 并发推送：runtime-ohos 与 sdk-ohos 在复核窗口内各有新提交（tip 已注明）；不影响已发布资产与锚（锚在历史内）。
- 未做 207 MB 全量独立下载：by-id digest == 本地 sha 为主证 + 自取小件字节证；如需补全量可另跑（MemAvailable ≈ 9.2 GB）。

## 外部依赖清单（不在本仓/本复核控制）
- 真机轮（JIT/XWE/AOT/解释器/harmony + WebView 9 项 + Blazor/B1 两标记 + 无障碍）与重签：测试方设备/UDID；HMS 设备 + AGC 权益项同 #31。
