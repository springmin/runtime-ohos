# 终态复核（kit #31）：五仓 / 发布资产 / kit 抽验 / bundle / CI / 文档一致性（2026-09-29）

> 独立只读终态复核（KIT31-VERIFY）。**首发时点 11:14–11:54 CST**：`reg-kit31/RELEASE-VALUES.txt` 60s×40min 轮询
> 未产出（release 四口仍为 kit #30 @2026-09-28T01:42Z；REG 的 kit 构建 11:46 起在 `reg-kit31/blazor-dev` 进行中）——
> 第 1/4/5/6 项完成，第 2/3 项登记「待 VALUES」。证据：`git rev-parse/rev-list/reflog`、`gh api`（release by-id/body、
> Actions runs）、本地解包 `verify-kit.sh` + 独立深断言、`sha256sum`。本报告为新增文件，不改动他人文档。

## 1. 五仓一致性 — PASS（含并行在途注记）
- runtime-ohos `feature/openharmony`：复核窗内 tip 依次 `e1914789`→`8dbc4f11`→`b720ee61`→`78b8f8a2`（KIT31-DOCS 文档批，逐笔 push）；`main` `719009acffb`（0/0）；
  remote-tracking reflog 逐条 `update by push` 线性，无强推；本复核不触碰共享检出（发布脚本批在途时为快照口径）。
- ohos-workload `master`：`fc5f6bae`→`02316f64`（并发批）均 local==origin；reflog 线性；工作树 5 脚本 + 1 docs 在途（KIT31-REG，非本复核）。
- maui-ohos `feature/openharmony`：local==origin `4b5756de4425`（0/0）。该检出 refspec 仅 `main`，默认 fetch 不更新该 tracking ref；
  以 `git fetch origin feature/openharmony:refs/remotes/origin/feature/openharmony` + GitHub branch API 双证对齐（head 相同）；43 条稀疏 `??`（固有）。
- sdk-ohos `feature/openharmony`：local==origin `4d1a88e6f5a9`（0/0）；工作树干净；当前 checkout 的 `fix/ohos-msbuild-pipe-patch` 上游 gone、
  其提交已并入该分支（`b52765daab` 为祖先）；reflog 逐条 push 线性。
- aspnetcore-ohos `feature/openharmony`：local==origin `07ed2fe38d47`（0/0），干净。
- 强推检查：五仓全部 remote-tracking reflog old 值为新值祖先（push/ff），无 rewind；与各 GitHub branch head 一致。

## 2. 发布资产 vs RELEASE-VALUES — 待 VALUES（窗口内未产出）
- 复核窗内 `dtk/workload-latest/preview.24/SDKREL(rc1)` 四口 updated_at 均停在 `2026-09-28T01:42Z`（kit #30 尾态，24/4/2/35 项，body 无 `kit #31`）；「by-id digest == 本地 sha」「四处 `## Integrity (kit #31)`」「added/removed vs 零改动清单」需发布后补。
- 已备好比对基线：四口 before 快照 + 本地 sha（`reg-kit30` 解包树）已存 `kit31-verify/`；`check-digests.py` 一键复核。

## 3. kit #31 实质抽验 — 部分完成（第 6 hap 已验，整包待 VALUES）
- 第 6 个 hap（REG 11:49 构建产物 `reg-kit31/hello-blazorwasm-host-unsigned.hap`，26,794,931 B / `ef7513b62f2d…`）独立断言全过：
  bundle `com.example.opendotnet`、219 zip 条目、`rawfile/blazor` 210 文件（204 `*.wasm` 含 app wasm + `blazor.webassembly.js`）、
  `index.html` 在、无 `.br/.gz/.map`/`icudt`、abc `PANDA 13.0.1.0`（16,352 B）。
- 5 MAUI hap 的整包断言（abc 281,052/20,916、libs 270/14 `.so`、payload marker、runtime-mode=jit）与包内 `verify-kit.sh` 0 FAIL/0 WARN：
  待 kit tar/解包树产出后执行（独立脚本 `kit31-deep.py` 已在 kit #30 树上自证 6 PASS/0 FAIL；新 `verify-kit.sh` 预检在 kit #30 上 0 FAIL）。

## 4. bundle / 锚 — 现状一致（待确认是否重打包）
- 三处 bundle（workload-latest / preview.24 / SDKREL（rc1））asset digest+size == 本地 `dist/openharmony-workload-1.0.0-preview.24.tar.gz`
  == `sdk-ohos eng/ohos-install/versions.env` 锚：30,563,349 B / `c4647fc8…`（= kit #30 发布值，三处 + 本地 + 锚逐一 sha 复核通过）。
  若 #31 未重打包则锚一致即成立；重打包则需 VALUES 后重锚复核。
- 安装器测试：sdk-ohos ohos-install-tests 最近 3 次 success（`4d1a88e6f5a9`/`b94fd513a3`/`1cbc1b8a6a`；见 §5）。

## 5. CI — PASS
- ohos-workload @`02316f64a4a6`：interaction `36373701446`、pixel `36373701412`、host-export `36373701418`、ridgraph `36373701462`、markdownlint `36373701434` 全 success；上一批 `fc5f6bae` 5/5 success（`36373198777/742/732/784/760`）、`47ececc` 5/5。
- blazor-recipe `36371263137` success @`5272ee54fb5f`（workflow_dispatch，该工作流唯一 run）；harmony-flavor `36369308089`（push）success @`6ce1ec1d`、`36369863335`（dispatch）success @`3e7de36f`（当前 tip 非 flavor-surface，无 run，属预期）。
- sdk-ohos：ohos-install-tests `36371922385` success @`4d1a88e6f5a9`；ohos-full-build `36373081395` 同 tip（复核时 in_progress，后补）。

## 6. 文档一致性 — PASS（预核；精确数字待 VALUES）
- handoff-kit31 / 任务单 / final-status / README 均已把「当前」切到 kit #31（Blazor hap + tester-run v13 `--blazor-probe`；abc 281,052/20,916、
  143/143、391/floor 371 承 #30 不变），且把 #31 精确数字（tar/树/sidecar/bundle/v13 大小与 sha）全部委托给 release
  「## Integrity（kit #31）」与随包 `SHA256SUMS`（窗口内尚未产出，口径一致、无编造数字）。
- 旧值语境复核：`a781c25b`/`cc1ca935`/`a63cd34f`/`87763a3e` 在四个文档中仅出现于「#30 = …」「v12 = …」历史对照，无「当前 kit」误用。
- README 中 kit #30 终态复核行仍标 🔄（其报告已说明第 2/3/6 项已补齐）——建议文档 owner 翻 ✅（本复核不改他人文件）。

## 外部依赖清单（不在本仓/本复核控制）
- 真机轮（JIT/XWE/AOT/解释器/harmony 五态 + Blazor 两标记 + 无障碍）：测试方设备与回传。
- HMS 设备 + AGC 权益（Map/LiveView/TTS）与华为调试证书/Profile（UDID）用于重签；ArkWeb 首帧/`/counter` 人工两项只能在真机闭环。
- `reg-kit31/RELEASE-VALUES.txt` 与四口 release 更新由 KIT31-REG 在途产出（本复核窗口内未完成）。

## 残余风险
- kit #31 整包（tar/树/sidecar/v13/四处 notes/零改动清单）未经本复核实测——以发布后补记或后续复核为准。
- bundle 是否随 #31 重打包未定；若重打包，三处 + `versions.env` 锚需重核（当前五处同值 `c4647fc8…`）。
- ohos-full-build `36373081395`（sdk tip）复核时仍在跑；ohos-workload 在途脚本未提交，CI 尚未覆盖该批新改动。
