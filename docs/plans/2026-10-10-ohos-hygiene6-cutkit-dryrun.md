# OpenHarmony 卫生 phase-6 + kit #54 切包干跑（2026-10-10）

> 范围：BATCH-3 合并后卫生（ow/maui 已并分支 + l7m2/l8rem/mb3 worktree 实测）与 kit #54 P0/bump 干跑（零写）；远端零删除、#49–#53 资产不动、无设备/无构建。
> 主线：ow=`master` `8e871f4` · maui=`feature/openharmony` `625177750f`（均原位 clean）；worktree 先 `status --porcelain` 空再 `git worktree remove`（无 --force，rc=0）。

## 1) 分支删除（4 = ow 2 + maui 2，逐支 ancestor 复核后 `git branch -d`）

- ow：`feat/n-subwindow-m2` `ee95143`（merge `a2b3567` 系）· `fix/l8-remainder` `373bee0`（merge `db565fe`）。
- maui：`feat/n-subwindow-m2` `14cc245902` · `fix/l8-remainder` `31ed839fd6`（merge `625177750f`）。
- 保留：`feat/l8-popup-probe` · `sample/hybrid-subwindow` · `wip/l2-consolidate-stale`；远端零删除。

## 2) worktree 实测（删 2；prune 附加 0；检出恢复 2 = 原位 0 切换）

- 删：`l7m2/wt-ow`（`ee95143`）· `l7m2/wt-maui`（`14cc245902`），均 clean。
- 跳过 7：`bundle-retest/ohos-workload`（他会话）· `hybrid-aot/wt`、`hybrid-aot/wt2`（资产；wt2 脏 1）· `split827/wt`、`wt-rt-subweb`、`sdk-ohos-rc2fix`、`hap-final15/wt`（非范围/上游）。
- `l8rem/*` 无 git worktree（仅 HAP staging）；`mb3/*` 全盘未见（0）；l7m2/l8rem 根证据保留（scratch 未入库）。
- 五仓 `worktree prune -v` rc=0；复核：ow `master@8e871f4`、maui `feature/openharmony@625177750f`，clean。

## 3) kit #54 干跑（零写；scratch `cut-kit54` 未创建）

- `cut-kit.sh --kit 54 --phase P0 --dry-run` **rc=3**（仅 docs 门）：pins PASS（ow `8e871f456a`/maui `625177750f`/runtime `13e855568e`，workflows 一致）· packs abc PASS（4 预览包 576664/`e69563c3…`, 24324/`798b2477…`）· suite PASS（771 floor 751）· exports PASS（164）· selftests 2/2 · worktrees PASS（none yet）。
- docs 门 **37 issue(s)**：18 块仍 #53 + 18 缺 abc 576664 + README 索引；hint 指向 `--bump-docs`（idempotent, --dry-run）。
- `bump-tester-docs.sh --kit 54 --dry-run` **rc=1 refuse**：18 docs 计划 `#53 -> #54` + README index，但全缺 abc 576664 → 「refusing the wave: 18 issue(s); no file was written」；复跑时间戳归一后一致（幂等）；未 --apply。
- 零写核验：三仓 status 0 行、HEAD 不变；docs/plans 322 md sha256 全同；selftest 零新增残留。

## 4) 不确定项

- bump 干跑揭示：#54 真切包需先人工把 18 份 tester 文档 abc 刷到 576664（bump 只动块号+索引），再 bump/手工提交；本 session 未改。
- `hybrid-aot/wt2` 脏 1（未跟踪 `test/hello-maui-hybrid/`）属 hybrid 资产区，保留待 owner 处置。
