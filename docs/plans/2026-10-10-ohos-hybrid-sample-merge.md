# HYBRID-SAMPLE-MERGE：子窗 hybrid/Blazor 样例并入主线（2026-10-10）

> 口径：ow `master` ← `sample/hybrid-subwindow` @ `09d244b`（**--no-ff**、普通推送、禁强推；合并后本地分支删、远端保留、零删除）；maui 未动（pin `625177750f`）；无壳/abc/套件影响；#49–#53 资产不动；样例 = 新增 `test/hello-maui-hybrid/**`（17 文件 1718 行）。

## 1) 合并 / 预检

- ow merge **`cf4b944`**（`cf4b94414e588e0dc6bfea76fec99b47959b9164`；父 `8e871f4` + `09d244b`）；`8e871f4..cf4b944` 普通推送 OK、未强推。
- 预检（合并树 vs `8e871f4`）：仅新增 17 样例文件；`packs/`、`scripts/`、`test/maui-platform-verify`、`test/headless-render` 零 diff；ui abc **576,664/`e69563c3…`**、headless **24,324/`798b2477…`**、provenance `1f9d8d4d…` 前后同；`EXPECT_ABC` 仍 `576664,24324`、套件计数 771 floor 751 未动（无重编/未重锚）。
- 本地 `scripts/preflight.sh --quick`（合并提交 = scratch worktree，前置补宿主 .so + `MAUI_SLICE_DIR`；主检出首两跑遇 rc.2-era 已知 csc 活锁）→ 第三跑 **OK**：repo gates ridgraph 20 / packs 25 / hap-targets 84 / tasks 9 / hygiene 25 / host 84+26+47 / cut-kit 52、sh -n 54/54、lint 0；两套件按 `--quick` 跳过（文件零 diff）。

## 2) CI / 清理 / rc.2

- CI（push `cf4b944` 触发 5，全 success）：interaction `38095681928` · pixel `38095681842` · host-export `38095681841` · ridgraph `38095681839` · markdownlint `38095681847`；harmony-flavor 路径过滤未触发（样例不在 flavor 面，预期）、rc2-watch 仅 schedule/dispatch；pin 不变 ⇒ 门禁同 BATCH-3。
- 清理：`hybrid-aot/wt2` 残留（106 文件 = 17 源文件与合并树逐字节同 + bin/obj 315 MB）先删残留再 `worktree remove` rc=0（无 --force）；`hybrid-aot/wt`（clean）`worktree remove` rc=0；本地 `sample/hybrid-subwindow` 删除（was `09d244b`）；`bundle-retest/ohos-workload`（他会话）未触碰、远端零删除。
- rc.2：`scripts/rc2-official-watch.sh` **rc=0 / WAIT**——nuget 四包 `11.0.0-rc.1.26451.6`、GitHub `11.0.100-rc.1.26458.5`，无 rc.2+ ⇒ #54 仍待。

## 3) 不确定项

- wt2 的 bin/obj（315 MB）按可重生成直接删除、未逐件留档；hybrid 真机证据（AOT hap/round）在 `hybrid-aot/` 保留。
- 本页提交：runtime `feature/openharmony`（`commit-paths.sh` 限本文件 + README 索引；fetch/rebase 被拒时旁路，不 force）。
