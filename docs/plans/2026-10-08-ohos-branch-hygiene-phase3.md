# OpenHarmony 分支卫生 phase-3（2026-10-08）

> 范围：ow（`ohos-workload`）/ maui（`maui-ohos`）本地 l2/l3 分支 + 陈旧 worktree（`reg-kit49..52` 各仓实测）；**远端零删除**（未执行任何 fetch/push/远端删除）；KIT53 并行资产（`reg-kit53/`）与 #49–#53 资产零触碰。
> 主线口径：ow=`master` `7259a0f` · maui=`feature/openharmony` `caa463434b`（两条工作主线）。
> 复核方法：`git merge-base --is-ancestor <b> <主线>` 或 `git cherry <主线> <b>` 全 `-`（patch-id 内容等价 = replay 前件）；删除前逐支二次复核；worktree 先 `status --porcelain` 空，再 `git worktree remove`（无 `--force`，逐条 rc=0），随后 `git worktree prune -v`。

## 分支删除（24 = ow 12 + maui 12）

- ow（9 ancestor + 3 cherry 全 `-`）：`l/m4-focus-ime` a1ebde2 · `l2/a11y-provider` f5a892a · `l2/arkweb-subwindow` afa6d7a · `l2/arkweb-subwindow-wt` 3c486cf · `l3/a11y-cleanup` 19e8cb7 · `l3/a11y-selfcheck` 887e172 · `l3/b6-nav-veto` d25c0eb · `l3/m2-identity` 512cc25 · `l3/m3-services` c44a0e9 · `l3/m4-childweb` 0834941 · `l3/multi-subwindow` ec0a6e4 · `l3/web-assets` fc186bf
- maui（9 ancestor + 3 cherry 全 `-`）：`l/m4-per-window-focus` 23d98a9615 · `l2/a11y-provider` ba7581022c · `l2/arkweb-subwindow` 74e0bde5b9 · `l2/arkweb-subwindow-wt` 2e441c35c9 · `l3/a11y-cleanup` 70b279548a · `l3/a11y-selfcheck` 8c7a859c91 · `l3/b6-nav-veto` b64c477f8e · `l3/m2-identity` a5bf98bf64 · `l3/m3-services` 1946b968da · `l3/m4-childweb` 0a45ef605e · `l3/multi-subwindow` fd7451adbf · `l3/web-assets` 4b9598d9f3

## 分支保留（含原因）

- maui：`feature/openharmony` caa463434b · `main` 7de682ea17（基线）· `w2b-int` f333e24da9 · `w2b-t3t5` 48c01d69f1（未落内容）· `wip/l2-consolidate-stale` 952551df67（+1 未并，WIP 存档）。
- ow：`master` 7259a0f（基线）· `wip/l2-consolidate-stale` f954e86（+1 未并，WIP 存档）。

## worktree 删除（30 = maui 11 + ow 12 + runtime 3 + sdk 4）

- maui 11：`b6/wt-maui` · `mw-l/m1-regress/maui` · `reg-kit49/50/51/52/maui` · `scan5c/maui` · `wt-maui-a11y` · `wt-maui-a11y-l3` · `wt-maui-subweb` · `wt-maui-web-l3`。
- ow 12：`b6/wt-ow` · `mw-l/m1-regress/wt` · `mw-l/m1-regress/final/wt` · `reg-kit49/50/51/52/ow` · `scan5c/ow` · `wt-ow-a11y` · `wt-ow-a11y-l3` · `wt-ow-subweb` · `wt-ow-web-l3`。
- runtime 3：`reg-kit50/51/52/runtime` · sdk 4：`reg-kit49/50/51/52/sdk-anchor-wt`（`各仓`口径；删除前全部 clean）。
- prune：ow/maui/runtime/sdk/aspnet 各 `worktree prune -v` rc=0、无额外残留条目（0）。

## worktree 保留（含原因）

- ow `bundle-retest/ohos-workload`（脏 7 项）· runtime `split827/wt`、`wt-rt-subweb`、`runtime-ohos-rc2` · sdk `sdk-ohos-rc2fix` · aspnet `aspnetcore-ohos-rc2`（非清单或分支占用）。
- **`reg-kit53`（KIT53 并行：ow/maui/runtime 已建，sdk 待建）零触碰**。

## 计数

- 本地删除 24（ow 12 / maui 12）· worktree 删除 30（maui 11 / ow 12 / runtime 3 / sdk 4）· prune 附加 0 · 远端 0。
- 明细日志（scratch，未入库）：`hygiene-phase3/{wt-before.txt,remove-*.log,delete-branches-*.log}`。
