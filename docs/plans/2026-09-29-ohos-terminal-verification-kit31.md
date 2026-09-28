# 终态复核（kit #31）：五仓 / 发布资产 / kit 抽验 / bundle / CI / 文档一致性（2026-09-29）

> 独立只读终态复核（KIT31-VERIFY）。两段时点：**首发 11:14–11:54 CST**（`reg-kit31/RELEASE-VALUES.txt` 60s×40min 未产出；
> 第 1 项完成、2/3/4/6 登记待值）；**发布后补记 12:15–13:25**（VALUES 产出后第 2/3/4/6 项补齐）。证据：`git fetch/rev-parse/rev-list/reflog`、
> `gh api`（release by-id/body、Actions runs）、本地 `reg-kit31` 解包 + 包内 `verify-kit.sh` + 独立深断言、gh-proxy 小件独立下载（v13/边车/HEAD）。
> 本报告为新增文件（初版 11:58 提交 `f75f978a`，本次补记），不改动他人文档。

## 1. 五仓一致性 — PASS（含在途注记）
- runtime-ohos：tips `e1914789`→`8dbc4f11`→`b720ee61`→`78b8f8a2`→`9eca9d3`→`10a0a95a`→`16f627a16e7`（含本报告初版 `f75f978a`）；
  最终 local==origin `16f627a16e7`（0/0），工作树干净；remote-tracking reflog 逐条 push/ff 线性，无强推。
- ohos-workload：`fc5f6ba`→`02316f6`→`9a03f76`，local==origin `9a03f76db33c`（0/0），干净；线性。
- maui-ohos：local==origin `4b5756de4425`（0/0；该检出 refspec 仅 `main`，显式 fetch + GitHub branch API 双证）；43 条稀疏 `??`（固有）。
- sdk-ohos：origin `b2b79e27d9`（锚提交，`4d1a88e6f5..b2b79e27d9` 为 fetch fast-forward，无强推）；锚提交在本地 detached worktree
  `reg-kit31/sdk-anchor-wt`；本地 `feature/openharmony` 分支 ref 因挂在 `reg-kit30/sdk-anchor-wt` 仍指 `4d1a88e6f5`（陈旧，未改动）；
  主检出 `fix/ohos-msbuild-pipe-patch` 上游 gone、提交已并入，工作树干净。
- aspnetcore-ohos：local==origin `07ed2fe38d47`（0/0），干净。

## 2. 发布资产 vs RELEASE-VALUES — PASS
- 四口 release（sdk-ohos：dtk `392356147` / workload-latest `392077166` / preview.24 `392616481` / SDKREL rc1 `388357742`）：changed/added/removed
  与 VALUES 完全相符——dtk 24→24 恰 {tar, sidecar, tester-run.sh}（新 asset id 594513459/594518587/594519342）；latest 4→4 全换；preview24 2→2；
  SDKREL 35→35 仅 {bundle, SHA256SUMS}；added/removed 全 0；其余 21+33 项 digest 零变化（含 aot-haps、harmony v2、interp、7 个探针 hap）。
- by-id digest+size == VALUES == 本地 sha：tar **207,023,588 / `f4325d2f…`**、sidecar **89 / `7d0cba77…`**、tester-run **137,113 / `2caa06bd…`**、
  bundle **30,570,394 / `43a78c8f…`**、SHA256SUMS **212 / `a7026779…`**（9/9 PASS）。
- 四处 notes 均含 `## Integrity (kit #31)`；dtk/latest/preview24 已去除 kit #30 段；SDKREL 仅在「inner pack files byte-identical to kit #30」历史句出现 #30。

## 3. kit #31 实质抽验 — PASS
- 本地 `reg-kit31/device-test-kit.tar.gz` sha == VALUES `f4325d2f…`；解包后包内 `verify-kit.sh`（63,301 B / `67622771…`）
  `--anchor-file ../device-test-kit.tar.gz --expect-tree-digest 52e77ee8…`：**RC=0 / KIT OK / 0 FAIL / 0 WARN**（anchor OK、tree OK、2c Blazor 分节通过）。
- 抽包内断言（独立 `kit31-deep.py`，**7 PASS / 0 FAIL**）：6 hap sha 全等 VALUES；5 个 MAUI hap abc 281,052/13.0.1.0、libs 270/14 `.so`、
  runtime-mode=jit、zip 279、payload entries=269；Blazor hap `36010a9c…`：219 条目、bundle `com.example.opendotnet`、站点 210 文件
  （204 `.wasm` + `blazor.webassembly.js`）、index.html、零 `.br/.gz/.map`/icudt、abc PANDA 13.0.1.0。
- tester-run v13：gh-proxy 独立下载 137,113 B == `2caa06bd…`，`SCRIPT_VERSION="13 (2026-09-28)"`、`--blazor-probe` 22 行。
- 下载策略（轻量）：不做 207 MB 全量独立下载——by-id digest == 本地 sha（主证）+ gh-proxy 独立取 89 B 边车（与本地字节相同、内容==tar sha）
  + tar HEAD 200 / content-length 207,023,588 + v13 全量独立下载（137 KB）。

## 4. bundle / 锚 — PASS
- bundle `43a78c8f…`（30,570,394）三处 release == 本地 `dist/` == sdk `versions.env` 锚（锚提交 `b2b79e27d9`，1 文件 1 行，fast-forward 无强推）；
  `dist/SHA256SUMS` `a7026779…`（212 B）同样三处一致。本次为重打包但 metadata-only（容器级刷新、nupkg 内文件零变化；VALUES note）。
- 安装器测试：锚提交 `b2b79e27d9` 的 ohos-install-tests `36378113086` success；前次 `36371922385`（`4d1a88e6`）success；
  VALUES 记 test-installer 43/43、hostfeed 10/10、codesign-filewrites 5/5（`sdk-test-*.log`）。

## 5. CI — PASS
- ohos-workload @`9a03f76`：interaction `36379033705`、pixel `36379033801`、host-export `36379033789`、ridgraph `36379033819`、markdownlint `36379033881` 全 success；
  `02316f6`/`fc5f6bae`/`47ececc` 各 5/5 success。
- blazor-recipe `36371263137` success @`5272ee54fb5f`（dispatch）；harmony-flavor `36369308089`（push）/`36369863335`（dispatch）success
  （当前 tip 非 flavor-surface，无 run，属预期）。
- sdk-ohos：ohos-install-tests `36378113086` success @`b2b79e27d9`；ohos-full-build `36373081395` @`4d1a88e6f5` completed/success。

## 6. 文档一致性 — PASS（一项表述异常）
- manifest（`16f627a16e7`）已按 VALUES 刷新（f4325d2f/52e77ee8/7d0cba77/2caa06bd/43a78c8f/b2b79e27d9、6 hap、v13）；handoff-kit31 /
  任务单 / final-status 均以「当前 = kit #31 + 数字入口 release『## Integrity（kit #31）』」表述；旧值（`a781c25b`/`cc1ca935`/`a63cd34f`/`87763a3e`/`c4647fc8`）
  仅历史对照语境，无「当前 kit」误用。
- 异常记录（不代改他方文档）：Blazor hap `module.json` 声明 `requestPermissions=[ohos.permission.INTERNET]`（dev-only），而 handoff-kit31 开头
  「无本地服务/无网络权限」与 2026-09-28 演示/可行性文档「权限=无」表述不符；manifest 与 VALUES `note_blazor_permission` 已如实标注。
- README 中 kit #30 终态复核行仍标 🔄（其报告已说明 2/3/6 项补齐）——建议文档 owner 翻 ✅。

## 外部依赖清单（不在本仓/本复核控制）
- 真机轮（JIT/XWE/AOT/解释器/harmony + Blazor 两标记 + 无障碍）与重签：测试方设备/UDID；ArkWeb 首帧与 `/counter` 人工两项只能真机闭环。
- HMS 设备 + AGC 权益（Map/LiveView/TTS）；Blazor 未签 hap 必须按 `自签说明.md` 重签后才能安装。

## 残余风险
- Blazor 组件真机渲染/交互（`BLZ_BOOT`→`BLZ_RENDERED`、首屏、`/counter`）仍未验证——本复核只到包内静态断言。
- bundle 为 metadata-only 重打包（语义同 kit #30，digest/锚已前移）；若团队偏好保持原 bundle，需回滚锚与四口资产（VALUES note 已给选项）。
- sdk 本地 `feature/openharmony` 分支 ref 陈旧（挂 worktree，未改动）；harmony-flavor 未随当前 tip 触发（无 flavor-surface 变化）。
