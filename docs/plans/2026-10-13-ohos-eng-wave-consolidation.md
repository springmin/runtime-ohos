# ENG-WAVE-CONSOLIDATION：合并两条 ow 工程分支 + 套件重锚 + pin bump（2026-10-13）

> 结论：ow `master` **`630a10b`** 并入 `feat/securestorage-failclosed`（`5ecf0b2`）与 `feat/webauth-loopback`（`5b2dc94`）——两 `[verify]` 块相邻不重叠，`ort` 自动并集、无冲突；套件重锚 **810/813 floor 793**（804 + 9，printed 810 实测）；三 workflow pin 升 **`5cfb1b8991`**；CI 5/5 + harmony dispatch 绿；两分支/三 worktree 收尾。本 session 不处理上游 PR。

## ① 合并（ow 主树，禁强推）

- `621bc4d` merge fc → `2a1dc2e` merge loopback：`test/maui-platform-verify/Program.cs` 自动并（FAILCLOSED 块与 loopback 块相邻、零重叠；+156/+224）+ `WebAuthProbe.cs` +46/−3；两分支实测 806/805 的增量在合并树共存。
- 两分支 tip 已在远端；主树合并经 Git Data API 逐提交重放（tree/sha 与本地逐一相等、非强推），远端 master = `630a10b`。

## ② 套件重锚（total 804 → 813，floor 793）

- 合并树 + maui `5cfb1b8991` 首测 printed **810**（801 +5 fc +4 loopback），rc=0、assert=True、perf within、无 Unhandled；`verifyCheckTotal` 804→813，注释链前插 `// +5 SECURE-STORAGE-FAILCLOSED` 与 `// +4 WEBAUTH-LOOPBACK`；floor 随动 813−20=**793**（重锚提交 `f314409`）。
- 复跑 `[suite] checks=810 total=813 floor=793 assert=True`、rc=0、`grep -c '[verify]'` = 810。

## ③ pin bump / 引用随动（`630a10b`）

- interaction/pixel/host-export `MAUI_OHOS_REF` → **`5cfb1b89916d17d2bb65406a4dae2f66cf773b33`**（复核 maui `feature/openharmony` tip；含 `ffa9f68a77` fail-closed merge + `2a195809db` loopback）。
- 注释按实况刷新：导出 **164/164**、壳 abc **620,908/`c473b7be` 不变**（kit #55 实况；旧注释 623,784 系 FINAL-BATCH 值）、套件 **810/813/793**；历史口径不动。`scripts/preflight.sh` 动态读 `[suite]` 行，无字面量。

## ④ CI / 收尾

- CI @ `630a10b`（6/6）：interaction `38426798245`（`[suite] checks=810 total=813 floor=793 assert=True`）· pixel `38426798082` · host-export `38426798059` · ridgraph `38426797980` · markdownlint `38426797947` + harmony 手动 dispatch `38426890461`。
- 删已并本地分支 `feat/securestorage-failclosed`/`feat/webauth-loopback`；移除 worktree `secstore-failclosed/ow`、`webauth-loopback/ow`、`cut-kit55/ow`（陈旧；其 tasks dll 修改 = 构建件 `dfa3a085` 同源、无独有工作）；保留 `bundle-retest`；主树 clean == origin。

## ⑤ 随下一次切

- loopback + fail-closed 均已入库（ow `630a10b` / maui `5cfb1b8991`），随下一次切（rc.2 对齐 / 下一 kit）一并带货；Asset 后端仍开放（口径见 mail-lessons）。本文 + README 行 + rc2-align-runbook 待定项小注 → runtime（HTTP/1.1/旁路）。
