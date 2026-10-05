# 上游同步 playbook：runtime fork（#132827 合并后）（2026-09-28）

> 适用：`dotnet/runtime#132827`（sandbox fixes）合并后，把 `springmin/runtime-ohos` fork 与 upstream 对齐；
> 同时作为 `#132953` rerun 与 17 支预备分支落地的操作索引。
> 现状（2026-09-28 演练复核）：OperatingSystem/numa 切片已由上游 **#134670**（`7408c77328c`，2026-09-25）落了 main；
> `#132827`（sandbox fixes）仍 open，只余 1 commit `4c3b303419b`（SharedMemoryManager TMPDIR＋NamedMutex robust 跳过＋MutexTests）；`#132953`（infra）仍 open（head `be8e6f6988d`）。
> 演练时 `upstream/main` = `caf6b2a2243`（2026-09-28）；fork `feature/openharmony` = `ccade4009c4`（落后 377，尚未含 #134670）。

## 1. 同步六步（fetch → merge → 去重 → 校验 → 基线 → 记录）

1. `git fetch upstream`（直连不稳用 `git -c http.version=HTTP/1.1 fetch upstream`）。
2. `git merge upstream/main` 进 `feature/openharmony`；逐文件解冲突。
3. **去重已上游切片**（以上游为准，不重放 fork 旧 hunk）：
   - #134670 切片：`System.Private.CoreLib/src/System/OperatingSystem.cs`、`src/coreclr/gc/unix/numasupport.cpp`、`System.Private.CoreLib.Shared.projitems`；
   - #132827 同名 hunk：`SharedMemoryManager.Unix.cs`、`NamedMutex.Unix.cs`、`System.Threading/tests/MutexTests.cs`；
   - 目标态：`git diff upstream/main feature/openharmony -- <上述文件>` 为空或只剩 fork 专属 delta。
4. 校验：受影响面构建（至少 `./build.sh clr.runtime -c Release`，libraries 变动回跑 `MutexTests`）；`git merge-tree` 对 `pr/*` 跑零冲突预测（09-28 已复跑：merge-tree 39/39 CLEAN、rebase 20/21 CLEAN，见 `2026-09-28-ohos-upstream-rebase-rehearsal.md`）。
5. **更新 `pr/*` 与 rehearse2 基线**：按 2026-09-23 演练法（scratch `rehearse2/REPORT.md`：clone `--shared` → 按落地顺序 rebase → `range-diff`/`-U0 patch-id` SAME → merge-tree 双检 → 推送新 ref），把 17 支重锚到新 upstream/main。
6. **记录**：在 `docs/plans/` 追加一页（merge tip、去重文件、演练/双检结论、新 tip 对照），并回填 release manifest 与交接页。

## 2. #132953 rerun 与 17 支落地顺序（2026-09-28 演练确定版）

- `#132953`（infra）：重审通过 + rerun 绿后**先合并**；未合并前给 N 组开 PR 会把 12 个 infra 提交算进 diff。
- **上游 tip / 演练**：`upstream/main = caf6b2a2243`（09-28）；演练见 `2026-09-28-ohos-upstream-rebase-rehearsal.md`（merge-tree 39/39 CLEAN；rebase 20/21 CLEAN，19 支语义 SAME；0 支需重做）。
- **周期维护（非待办）**：上游前进时按上条**只读**重跑预演并更新 rehearsal 文档（可随 rc2-watch 周程）；
  预演不动上游、不重写已推分支（不可强推）；PR 描述等上游写操作按 §「评论需许可」执行。
- 确定顺序与每支前置（演练后）：
  ① infra（前置=#132953 合并 + `eng/common` 同步）→
  ② N1 clrfeatures / N2 pal / N3 zstd / N4 libs-native / N5 apphost / N14 tryrun（前置=①）→
  ③ N7 pal-process / N8 ifaddrs / N9 wx-default / N10 crossgen-corelib（前置=①）→
  ④ N11 aot-unix / N12 aot-singleentry（前置=①）→ ⑤ N13 packs（前置=①＋④）→ ⑥ N15 libs-tfm（前置=①）→
  ⑦ N16 console（前置=⑥，堆叠）→ ⑧ C2 shims-tfm-cleanup（前置=①＋#132866；若⑥先落需 rebase 到⑥后并去掉与 N15 重复的首提交）/ C3 illink-ntlm（前置=#132866 答复）。
- 已决例外：`pr/ohos-platform-numa` 丢弃（＝已合并 #134670，patch-id 相同）；`pr/ohos-tls-flag-cleanup` 丢弃（已被 infra `8ef4e925163` 吸收）；`pr/ohos-sandbox-fixes` = #132827 本体（open，不阻塞 N 组）。
- `#132953` 合并后把各 `pr/*` rebase 到 post-infra main 再逐支开 PR；`rehearse2/*` 是 09-23 演练产物（滞后 75 提交），**不要直接当 PR head**。
- `eng/common` 同步依赖 arcade#17608（已合并）；infra 落地后先同步 `eng/common`，再落 N 组。

## 3. 纪律

- **评论需许可**：上游评论/催评草稿（`2026-09-23-ohos-upstream-reply-drafts.md`）**未经明确许可不得发送**；#132953 rerun 的对外动作同样先报备。
- 禁强推；`pr/*` 演练只读重放；数字以 release「## Integrity」/`.sha256` sidecar 为准。

## 4. #134670 对账与 3-way 分析：四处差异点、预计零人工冲突（2026-09-30 核对）

上游 `#134670`（`main` @ `7408c77328c2`，单提交 `12457f848b5d`）与 fork 对账，印证 §3 的"已决例外"（`pr/ohos-platform-numa` 丢弃 ✓，**fork 内容已在**）：

- `src/coreclr/gc/unix/numasupport.cpp` — **逐字节一致** ✓（下次合并该文件零冲突）
- `System.Private.CoreLib.Shared.projitems` — `TARGET_OPENHARMONY` 行一致 ✓
- `OperatingSystem.cs` — 与 `upstream/main` 做 **3-way**（基 `29afde215f65` ✗）后：双方各自改动共四处，**无真冲突**：
  1. `#elif TARGET_OPENHARMONY "OPENHARMONY"`（OSPlatformName 分支）— **双方内容相同** ✓ → git 自动去重 ✓
  2. `internal static bool IsOpenHarmony()`（内部辅助）— **双方相同** ✓ → 自动 ✓
  3. **LINUX 别名 + `IsLinux()` 对 OHOS 为真** — **fork 独有**（`417ab220532`）→ 自动保留 ✓（上游尚无该别名；上游路径见 `2026-09-15-ohos-platform-identity.md` 附录"方案 B"）
  4. **OpenBSD 公共 API**（`public IsOpenBSD()` + `IsOpenBSDVersionAtLeast`）— **上游独有** → 自动采纳 ✓（fork 侧仅为滞后 ✗）

  → C3 合并该文件**无需人工解冲突**；合并后**校验**：别名/`IsLinux()` 仍在 ✓、OpenBSD 为上游形 ✓。
