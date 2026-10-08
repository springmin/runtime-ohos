# 上游开局动作草稿：#132827 / #132953 / #132866（2026-10-08）

> **⚠ 状态：全部「待用户许可，未发送」（ALL DRAFTS UNSENT）。**
> **严禁发送评论、严禁触发 rerun/`/azp run`、严禁任何 `gh` 写操作**（POST/PATCH/review/comment）。
> 本文件只含**草稿与操作建议**；纪律依据 = `2026-09-28-ohos-upstream-fork-sync-playbook.md` §3（所有上游可见动作逐次报备、等「发」）。
> 数据口径：2026-10-08 **只读** `gh` 复核 + 本地 `git merge-tree`（对 `upstream/main` `14e8bce614e`）；发送前按各「发送前检查清单」重拉。
> 风格与数字来源：`2026-09-23-ohos-upstream-reply-drafts.md`（风格）· playbook §3/§5/§6 · kit #53（`2026-10-08-ohos-tester-handoff-kit53.md`）。

## 0. 10-08 只读复核摘要（与任务输入的口径差异）

| 项 | 复核结果（只读） | 与输入差异 |
|---|---|---|
| #132827 | open · head `4c3b303419bb` · labels `area-System.Threading`/`blocked`/`community-contribution` · reviewDecision **APPROVED** · **159 checks：157 绿/跳/中性 + 2 FAILURE**（`runtime`、`runtime (Build Monitor Helix Jobs)`，均出自 build **1613197**，09-26）。末条评论 **10-07** springmin（拆分说明）；jkotas/akoeplinger 09-25 动作已确认 | 输入「末评论 09-01」未复现（实际末条 10-07）；其余一致 |
| #132953 | open · head `be8e6f6988d3` · labels `area-Infrastructure-libraries`/`community-contribution`（**无 blocked 标签**）· reviewDecision **REVIEW_REQUIRED** · **167 checks：162 绿/中性 + 5 FAILURE**（Build Analysis、Build Insights、`runtime`(build **1605552**)、Monitor Helix Jobs、`runtime (Build osx-arm64 Debug Libraries_CheckedCoreCLR)`) | 输入「blocked」= 可合并性/待复批语义，非标签；末条评论为 **10-01 + 10-06** springmin（输入「09-10」未复现）；红行 5 个（4 类成因） |
| #132866 | open · 6 评论 · 末条 **09-14** springmin 计划更新 · huoyaoyuan 08-28「Already tracked at **#103627**」确认 | 一致 |
| 共通 | 两 PR head 对 `upstream/main` `14e8bce614e` **merge-tree 均 CLEAN**（本地 10-08）；GitHub `mergeable` 字段返回 `UNKNOWN`（重算中）——发送前重查 | 输入 `mergeable_state` 以重拉为准 |
| #135321 | **MERGED 2026-10-07T20:14:53Z**（`5b3285fb8158`，1 file +2/−2，「Skip robust mutexes on OpenHarmony」） | 一致 |

「+2 行冗余注释」定位（本地复核）：`NamedMutex.Unix.cs` 的 2 行 fork 注释（musl sysroot 无 robust mutex API）已被 #135321 合并后的注释覆盖，属候选删除项。

---

## 1. dotnet/runtime#132827（sandbox fixes：余 TMPDIR + MutexTests）

### 1.1 事实与净差（只读复核）

- 评审：@akoeplinger **APPROVED**（09-25）；@jkotas 09-25 两条 COMMENTED（「wait for @jkoritzinsky 的 shared-memory 设计变更」＋「与 shared mutex 无关的改动拆出即可合」）——拆分已执行（#134670、#135321 均已合并）。
- CI：159 项仅 2 红，均为 build 1613197（09-26）：`runtime`（title「had test failures」，2 errors；Tests：4 failed / 3,124,971 = 0.00%）与 `runtime (Build Monitor Helix Jobs)`（2 errors；同类失败在 09-10 已分析为**非本平台** work items）。
- **净差复核**：`merge-tree(upstream/main, 4c3b303419bb)` = **CLEAN**（本地）；merge 结果对 main = **3 files / +18 −1**：`SharedMemoryManager.Unix.cs` TMPDIR `#if TARGET_OPENHARMONY`（+8）· `MutexTests.cs`（+8 −1）· `NamedMutex.Unix.cs` 冗余注释（+2，候选删除）。功能 hunk 已随 #135321 去重。
- 公开记录注：PR 仍带 **`blocked`** 标签；springmin 10-07 曾公开表示「park 至设计变更落地」——见 §1.3 备选尾句。

### 1.2 ① rerun 触发方式建议

- **首选**：请维护者只重跑失败项——GitHub **Checks 页 `Re-run failed checks`**（仓库 PR 指南口径；对 AzDO 亦可在 build **1613197** 页面 **Rerun failed jobs**，更省资源）。我方为外部贡献者、无 repo 写权限，**不能自行触发**任何重跑。
- **备选**：维护者在 PR 评论 **`/azp run runtime`**（dotnet/runtime 标准整批重跑命令；重跑 runtime pipeline 全部检查；`/azp` 仅写权限者可触发）。不建议关/开 PR（打扰面最大，仓库文档虽列为选项）。
- **口径注**：仓库对重跑保守（资源），且现行 agent-merge 口径要求先按 Build Analysis 归类（非本 PR 失败登记 KBE，而非反复重跑）——草稿给出证据供维护者归类/处置。

### 1.3 ② 评论草稿（英文，≤120 词；正文不含 @）

```text
Following up on the #135321 split (merged 10-07). This head merges cleanly into current main; the remaining delta is the `SharedMemoryManager` `TMPDIR` handling and `MutexTests.cs` (two comment lines in `NamedMutex.Unix.cs` are redundant against main and can be dropped).

The only red checks are from the 09-26 build (1613197): the `runtime` umbrella (2 errors; 4 failed tests out of 3.12M) and `Monitor Helix Jobs`, whose work items are on platforms this PR does not touch (the 09-10 analysis class). The head is approved (09-25).

Could you rerun those checks — and, if the remaining shape is acceptable, merge? If the shared-memory redesign still argues for holding this, that is fine; a rerun keeps the board fresh either way.
```

- **备选尾句（若决定维持 park 口径）**：把末段替换为 `Could you rerun those checks so the board is fresh? No merge action needed yet if the shared-memory redesign still argues for holding.`

### 1.4 发送前检查清单

1. **数字复核**：head 仍 `4c3b3034…`；159/2 红、build 1613197、2 errors、tests 4/3,124,971、09-26；#135321 仍 merged（`5b3285fb…`）；净差 3 files +18/−1 未变；`blocked` 标签是否仍在。
2. **链接**：PR `https://github.com/dotnet/runtime/pull/132827` · build `https://dev.azure.com/dnceng-public/cbb18261-c48f-4abb-8651-8cdcb5474649/_build/results?buildId=1613197` · #135321 `https://github.com/dotnet/runtime/pull/135321`。
3. **收件人**：已批人 @akoeplinger、留有意见的 @jkotas；正文不含 @（如需直接提醒由用户定）。发送账号 = springmin。
4. **许可**：用户明确「发」后才可发送；rerun 请求属维护者动作，不得由我方代触。

---

## 2. dotnet/runtime#132953（infra：pr/ohos-infra）

### 2.1 事实（只读复核）

- 评审：@jkotas **09-10 APPROVED**（后续 head 更新 → reviewDecision `REVIEW_REQUIRED`，需复批）；@jkoritzinsky 09-08 提过命名项（已闭环）；09-21 @am11/@jkotas COMMENTED（`eng/common` 项已随 dotnet/arcade#17608 合并闭环）。末评论 10-01、10-06（均为 springmin 状态/轻提醒）。
- CI：167 项，5 红行 = 3 类成因：①`Build Analysis`/`Build Insights`（结果分析器，跟随父构建）；②`runtime` build 1605552（09-21，「4 errors」；Tests：**Failed 0** / 3,042,322）＋其红 leg `osx-arm64 Debug Libraries_CheckedCoreCLR`（编译器进程内崩溃：sccache SIGSEGV 于 `jit/utils.cpp.o`，该文件本 PR 未触碰；09-23 已公开分析、此后未重跑）；③`Monitor Helix Jobs`（infra 监控；09-10 已分析为**非本平台** work items）。
- 合并性：head 09-21，落后 main；`merge-tree(upstream/main, be8e6f6988d3)` = **CLEAN**（本地，10-08）——**无需 rebase**；若维护者偏好重锚，可刷新 head（会触发全量 CI、需复批，二者等价）。

### 2.2 ① rerun/重跑范围建议

- **首选**：请维护者只重跑失败项（Checks 页 `Re-run failed checks`；或 AzDO build **1605552** 页 `Rerun failed jobs`，优先只重跑 `osx-arm64` leg——仓库对重跑保守）。
- **备选**：维护者评论 **`/azp run runtime`**（整批重跑）。分析器（Build Analysis/Insights）会随父构建刷新，无需单独处理。
- **rebase 说明**：本地 merge-tree 对当前 main CLEAN，可不 rebase；若维护者要求 rebase 到新 main，推送新 head 后需重新走 CI 与复批——发送前由用户确认走哪条。

### 2.3 ② 评论草稿（英文，≤120 词；正文不含 @）

```text
Status update on head `be8e6f69` (09-21; still merges cleanly into current main — a rebase is available if you prefer one).

All five red rows come from build 1605552: `Build Analysis`/`Build Insights` are the result analyzers that mirror the parent build; the `runtime` umbrella reports 4 errors with 0 failed tests (of 3.04M) and includes the osx-arm64 Libraries_CheckedCoreCLR leg, which died in the compiler process on `jit/utils.cpp.o`, a file this PR does not touch; `Monitor Helix Jobs` is the infra monitor (unrelated-platform work items, analyzed 09-10). Nothing points at this diff.

If you could rerun the build and take a look, a fresh sign-off would unblock the porting queue behind this PR.
```

### 2.4 发送前检查清单

1. **数字复核**：head 仍 `be8e6f69…`；167/5 红、build 1605552、4 errors、tests Failed 0/3,042,322、日期 09-21；reviewDecision 仍 `REVIEW_REQUIRED`；是否已有他人 rerun/新回复（10-06 后）。
2. **链接**：PR `https://github.com/dotnet/runtime/pull/132953` · build `https://dev.azure.com/dnceng-public/cbb18261-c48f-4abb-8651-8cdcb5474649/_build/results?buildId=1605552` · arcade #17608 `https://github.com/dotnet/arcade/pull/17608`。
3. **收件人**：@jkoritzinsky（10-06 已 ping；若再发，建议按 A2 改请**第二 reviewer**，避免同日重复打扰同一人）；正文不含 @。
4. **许可**：发送与 rerun 均待用户明确许可；我方不得自行 `/azp`。

---

## 3. dotnet/runtime#132866（tracking issue：里程碑更新）

### 3.1 事实（只读复核）

- 6 评论（dotnet-policy-service 1 + huoyaoyuan 1 + springmin 4）；huoyaoyuan 08-28 指「Already tracked at #103627」（#103627 = 2025-08 起的 HarmonyOS 支持总追踪，open、24 评论）；末条 09-14 springmin 计划更新（BSD/Haiku 模型 + N1–N16 清单）。
- 里程碑（自 09-14 起，以 kit #53 口径为准）：kit #50（10-06）真多窗 L；kit #51（10-07）L2 + SEC-6 + L2CAP；kit #52（10-07）多子窗 N=2（M1–M4）+ 尾项；kit #53（10-08）a11y selfcheck 修复 + B6 子窗导航否决。
- 发布资产（kit #53，release「## Integrity」口径）：tar 68,883,057 / `dba88961…`；bundle 73,213,144 / `031ba342…`（SDK 11.0.100-rc.2）；预签 HAP 68,755,353 / `d1732195…`；门禁 737/740 floor 720、导出 164/164；设备 = 2in1 / API 26 / debug 签名域。

### 3.2 评论草稿（英文，≤120 词；正文不含 @）

```text
Milestone update (2026-10-06–08). Noting the earlier pointer: platform-wide HarmonyOS tracking remains at #103627; this issue stays the working index for this contribution queue.

Since the September update: kit #50 completed true multi-window support; kit #51 added per-window accessibility and a second ArkWeb host; kit #52 added multi-subwindow N=2 with per-window IME, overlay/Back; kit #53 fixed the subwindow a11y selfcheck and landed the child WebView navigation veto. Current release assets are device-verified on 2in1/API 26 (debug-signed): device-test-kit tar 68,883,057 B (`dba88961…`), workload bundle 73,213,144 B (`031ba342…`, SDK 11.0.100-rc.2), presigned HAPs 68,755,353 B; gates 737/740 checks and 164/164 host exports.

Upstream: #135321 merged (10-07); #132827 and #132953 remain open.
```

### 3.3 发送前检查清单

1. **数字复核**：kit #50–#53 日期与主题；tar 68,883,057 / `dba88961…`、bundle 73,213,144 / `031ba342…`、预签 68,755,353 / `d1732195…`、737/740、164/164（以 release「## Integrity (kit #53)」与 `2026-10-08-ohos-tester-handoff-kit53.md` 为准；#54 未切）。
2. **链接**：#132866 本身即可；#103627 `https://github.com/dotnet/runtime/issues/103627`；kit release `https://github.com/springmin/sdk-ohos/releases/tag/device-test-kit`（正文未放链接，如需再加）。
3. **收件人**：huoyaoyuan（#103627 指路人）与订阅者；正文不含 @。
4. **许可**：发送待用户明确许可；若 #103627 状态变化（关闭/迁移），先改「引用/归并」措辞。

---

## 4. 通用发送前动作（每条都要过）

1. 用户明确「发」；发送前重拉 `gh pr view`/`gh issue view`（确认无他人新回复、CI/head 未变）。
2. 每条草稿 ≤120 词、正文无 @、无承诺性措辞；沿旧口径可选在正文后另加一行 AI 披露尾注（不计词数）：`> [!NOTE] This comment was drafted with AI assistance (agent tooling) under the reporter's direction.`
3. 发送与 rerun 请求**分开许可**：#132827/#132953 的重跑由维护者执行，我方不得代触。
4. 本文件提交：runtime-ohos `feature/openharmony`（`commit-paths.sh` 限路径；直推，被拒则旁路钉 `140.82.112.3`，均不 force）。
