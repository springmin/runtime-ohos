# OpenHarmony 分支卫生 phase-7（2026-10-11，rev2 后收尾）

> 范围：MEDIAELEMENT 波 + MODAL-OVERLAY / SUBWINDOW-DEFAULT4 并线后 ow/maui 已并本地分支 + 完成态 worktree 清收；runtime/sdk/aspnet 仅 `worktree prune -v`；**远端零删除**（仅本文档单提交 FF 直推）。
> 主线：ow=`master` `77fc502` · maui=`feature/openharmony` `36da77cba4` · runtime=`feature/openharmony` `942096add71`（复核时三仓原位 clean）。
> 方法：逐支 `merge-base --is-ancestor` + `rev-list --count <主线>..<b>`=0 复核 → `git branch -d`（无 `-D`）；worktree 先 `status --porcelain` 空再 `git worktree remove`（无 `--force`，逐条 rc=0）。

## 1) 分支删除（5 = ow 3 + maui 2）

- ow：`fix/modal-overlay` `fc848f0` · `feat/subwindow-default4` `5c6289a` · `feat/media-micro` `a118ed8`（MEDIA-MICRO 波；均 ancestor）。
- maui：`fix/modal-overlay` `01fd603404` · `feat/subwindow-default4` `144b5b6a09`（均 ancestor）。
- 本地无 `feat/media-subwin-hls`/`tooling/*`/`sample/*`（前波已清或仅存远端）；远端零删除（`origin/feat/subwindow-default4`、`origin/fix/modal-overlay`、`origin/tooling/*`、`origin/feat/mediaelement-arkweb` 均不动）。

## 2) worktree 删除（11 = ow 4 + maui 4 + runtime 2 + sdk 1；删前全 clean）

- ow：`reg-kit54/ow` · `reg-kit54-rev2/ow` · `mofix/ow` · `sw-default4/ow`。
- maui：`reg-kit54/maui` · `reg-kit54-rev2/maui` · `mofix/maui` · `sw-default4/maui`。
- runtime：`reg-kit54/runtime` · `reg-kit54-rev2/runtime`；sdk：`reg-kit54/sdk-anchor-wt`。
- 根 scratch 证据（kit54/rev2 门禁日志、mofix/sw-default4 真机产出、`subwinhls/` 媒体证据）未入库、未删除。

## 3) 保留（原因）

- worktree：`bundle-retest/ohos-workload`（他会话，脏 7）· `split827/wt`（`pr/ohos-named-mutex`，上游 PR 本 session 不处理）· `wt-rt-subweb`（`l2/arkweb-subwindow-doc` 参考，前置阶段已列保留）· rc2 三处（runtime-ohos-rc2 / aspnetcore-ohos-rc2 / sdk-ohos-rc2fix，他会话；sdk 共享检出停 `feat/aotpack-rebuild` 未切）。
- 分支：ow `feat/l8-popup-probe`（参考，未并）· ow/maui `wip/l2-consolidate-stale` · maui `main` · runtime `rehearse/*`+`pr/ohos-named-mutex`（上游 PR 线）· `fix/ohos-rc2`（runtime/aspnet）与 `fix/rc2-aotpack-openssl-shim`（sdk）（已并但检出于保留 worktree）。
- media 相关 worktree：无（`subwinhls` 仅 scratch 证据，非 git worktree，保留）。

## 4) prune / 检出 / 计数

- 五仓 `worktree prune -v` rc=0、附加 0；复核 ow=`master@77fc502`、maui=`feature/openharmony@36da77cba4`、runtime=`feature/openharmony@942096add71`，全 clean。
- 计数：本地分支删 5（ow 3 / maui 2）· worktree 删 11（ow 4 / maui 4 / runtime 2 / sdk 1）· prune 附加 0 · 远端 0。
- 不确定项：无阻塞项；media 相关 worktree 在本轮实测中不存在（scratch 证据区保留）。
