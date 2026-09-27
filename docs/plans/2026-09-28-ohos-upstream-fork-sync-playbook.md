# 上游同步 playbook：runtime fork（#132827 合并后）（2026-09-28）

> 适用：`dotnet/runtime#132827`（sandbox fixes）合并后，把 `springmin/runtime-ohos` fork 与 upstream 对齐；
> 同时作为 `#132953` rerun 与 17 支预备分支落地的操作索引。
> 现状（2026-09-26 复核）：OperatingSystem/numa 切片已由上游 **#134670**（`7408c77328c`，2026-09-25）落了 main；
> `#132827` 已按评审拆分，只余 1 commit `4c3b303419b`（SharedMemoryManager TMPDIR＋NamedMutex robust 跳过＋MutexTests）。
> fork `feature/openharmony` = 11 带尾 `29afde215f6`；`upstream/main` = `bd36a2deb2d`。

## 1. 同步六步（fetch → merge → 去重 → 校验 → 基线 → 记录）

1. `git fetch upstream`（直连不稳用 `git -c http.version=HTTP/1.1 fetch upstream`）。
2. `git merge upstream/main` 进 `feature/openharmony`；逐文件解冲突。
3. **去重已上游切片**（以上游为准，不重放 fork 旧 hunk）：
   - #134670 切片：`System.Private.CoreLib/src/System/OperatingSystem.cs`、`src/coreclr/gc/unix/numasupport.cpp`、`System.Private.CoreLib.Shared.projitems`；
   - #132827 同名 hunk：`SharedMemoryManager.Unix.cs`、`NamedMutex.Unix.cs`、`System.Threading/tests/MutexTests.cs`；
   - 目标态：`git diff upstream/main feature/openharmony -- <上述文件>` 为空或只剩 fork 专属 delta。
4. 校验：受影响面构建（至少 `./build.sh clr.runtime -c Release`，libraries 变动回跑 `MutexTests`）；`git merge-tree` 对 `pr/*` 跑零冲突预测。
5. **更新 `pr/*` 与 rehearse2 基线**：按 2026-09-23 演练法（scratch `rehearse2/REPORT.md`：clone `--shared` → 按落地顺序 rebase → `range-diff`/`-U0 patch-id` SAME → merge-tree 双检 → 推送新 ref），把 17 支重锚到新 upstream/main。
6. **记录**：在 `docs/plans/` 追加一页（merge tip、去重文件、演练/双检结论、新 tip 对照），并回填 release manifest 与交接页。

## 2. #132953 rerun 与 17 支落地顺序（引用 branch-map）

- `#132953`（infra）：重审通过 + rerun 绿后**先合并**；未合并前给 N 组开 PR 会把 12 个 infra 提交算进 diff。
- 17 支顺序（`prep-upstream/branch-map.md` ④ ＋ `rehearse2/REPORT.md`）：
  ① infra → ② N1 clrfeatures / N2 pal / N3 zstd / N4 libs-native / N5 apphost / N14 tryrun →
  ③ N7 pal-process / N8 ifaddrs / N9 wx-default / N10 crossgen-corelib → ④ N11 aot-unix / N12 aot-singleentry →
  ⑤ N13 packs → ⑥ N15 libs-tfm → ⑦ N16 console（堆叠于 N15）→ ⑧ C2 shims-tfm-cleanup / C3 illink-ntlm（待 #132866 归属答复）。
- `#132953` 合并后把各 `pr/*` rebase 到 post-infra main 再逐支开 PR；`rehearse2/*` 是演练产物，**不要直接当 PR head**。
- `eng/common` 同步依赖 arcade#17608（已合并）；infra 落地后先同步 `eng/common`，再落 N 组。

## 3. 纪律

- **评论需许可**：上游评论/催评草稿（`2026-09-23-ohos-upstream-reply-drafts.md`）**未经明确许可不得发送**；#132953 rerun 的对外动作同样先报备。
- 禁强推；`pr/*` 演练只读重放；数字以 release「## Integrity」/`.sha256` sidecar 为准。
