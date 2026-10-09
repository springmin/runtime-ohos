# OpenHarmony 分支卫生 phase-4（2026-10-09，BATCH-MERGE 后收尾）

> 范围：ow（`ohos-workload`）/ maui（`maui-ohos`）BATCH-MERGE 后已并分支 + 陈旧 worktree（实测 clean 才删）；runtime/sdk/aspnet 仅 `worktree prune -v`；**远端零删除**（全程无远端删除；仅本文档提交按旁路直推 FF，不 force）。
> 主线口径：ow=`master` `ab43ba2` · maui=`feature/openharmony` `4fa0170900`；共享检出已恢复至各自主线（ow 原已在 master；maui 由 `maint/preprobe-sweep` 切回）。
> 复核方法：`git merge-base --is-ancestor <b> <主线>` 逐支二次复核为真才 `git branch -d`（无 `-D`）；worktree 先 `status --porcelain` 空，再 `git worktree remove`（无 `--force`，逐条 rc=0），随后 `prune -v`。

## 分支删除（8 = ow 5 + maui 3）

- ow（全 ancestor）：`tooling/cut-kit-2` 3773c64 · `feat/overlay-capacity8` 30a8651 · `feat/loaddata-navrate` e6e4f41 · `feat/webauthenticator` b49ea76 · `maint/sec5c-ef` 95e4a68。
- maui（全 ancestor）：`maint/sec5c-ef` 6f278ee99b · `feat/webauthenticator` 2803e15b6c · `maint/preprobe-sweep` f8ef3c89b4（BATCH-MERGE `619c40a483` 并入，恢复检出后删除）。
- `feat/n-subwindow`（ow/maui）虽已并，但 L7 phase2 redo 在用 `nsub/*` worktree → 跳过。

## 分支保留（原因）

- ow：`master`（基线）· `feat/l8-popup-probe` 19b02da（参考探针，未并）· `sample/hybrid-subwindow` 09d244b（测试资产，未并）· `wip/l2-consolidate-stale` f954e86（WIP 存档）。
- maui：`feature/openharmony`/`main`（基线）· `w2b-int` f333e24da9 · `w2b-t3t5` 48c01d69f1（未落）· `wip/l2-consolidate-stale` 952551df67（WIP 存档）。

## worktree 删除（17 = ow 8 + maui 6 + runtime 2 + sdk 1）

- ow 8：`e4-fix/ow` · `l3l4/ow` · `l8-probe/ow` · `sec5c-ef/ow` · `smoke-cut-kit/scratch/ow` · `wt-wa/ohos-workload` · `hybrid-sample/wt` · `reg-kit53/ow`。
- maui 6：`preprobe-merge/maui` · `sec5c-ef/maui` · `smoke-cut-kit/scratch/maui` · `wt-wa/maui-ohos` · `hap-final15/slice-caa463434b` · `reg-kit53/maui`。
- runtime 2：`reg-kit53/runtime` · `smoke-cut-kit/scratch/runtime`；sdk 1：`reg-kit53/sdk-anchor-wt`。
- prune：五仓 `worktree prune -v` rc=0、附加 0；删除前全部 clean。

## worktree / 证据保留（原因）

- 跳过：`nsub/ow`、`nsub/maui`（L7 在用）；`bundle-retest/ohos-workload`（脏 7，他会话）。
- 保留（非清单）：runtime `split827/wt`（pr/ohos-named-mutex，上游 PR 本 session 不处理）· `wt-rt-subweb` · `*-rc2*` 检出；sdk 共享检出停 `feat/aotpack-rebuild`（未切换，非本阶段范围）。
- 证据保留（scratch，均未入库、未删除）：`wt-wa/` 根 `device-round*/webauth-kit*/installed-backup`（WebAuth SECRET1/2 真机串）· `smoke-cut-kit/SMOKE-REPORT.md`+`logs/`（kit #54 演练，报告注明 kept for reuse）· `hap-final15/` 根 logs/out/raw（kit53）· `reg-kit53/` 根 gates 日志 · `l8-probe/`、`hybrid-sample/` 根证据。
- 非范围：CDGSS `hap-final15/wt`（另仓 clean worktree）保留未动。

## 计数

- 本地删除 8（ow 5 / maui 3）· worktree 删除 17（ow 8 / maui 6 / runtime 2 / sdk 1）· prune 附加 0 · 远端 0。
- 本文档提交按旁路直推 FF 至 runtime origin/feature/openharmony（未 amend/未 force）。
- 明细日志（scratch，未入库）：`hygiene-phase4/{remove-*.log,delete-*.log,prune.log,checkout-maui.log}`。
