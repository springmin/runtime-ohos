# 仓面/分支/worktree 卫生（REPO-HYGIENE，2026-10-04）

> 范围：五仓（runtime-ohos / ohos-workload / maui-ohos / sdk-ohos / aspnetcore-ohos）。不改产品代码；不删远端分支；未推且有值者以**新 ref** 归档推送（禁强推）。配套 `2026-10-03-ohos-scratch-script-rescue.md`（建议 1），为后续 scratch 清理的仓面底册。
> 方法：`git fetch origin '+refs/heads/*:refs/remotes/origin/*'` 刷新远端跟踪 ref 后逐支分类（已推同步 / 已并入主线 / 未推）；worktree 以 `git worktree list` + 工作目录 `.git` 有效性核验。

## 1. maui `src/Compatibility/`（初检出残留，已核实）

- 内容：70 文件 = **66 未跟踪 + 4 忽略**（`Tizen/Log/*.log` 命中 .gitignore），仅 Tizen 子树（`Core/src/{*.Tizen.cs,Tizen/**}`、`Maps/src/Tizen/**`、`Material/src/Tizen/**`）。
- 来源：与 `origin/main` 中该目录（1138 文件）的对应 blob **逐字节一致（70/70）**；`feature/openharmony` 不含该目录（上游 `#35870` 移除兼容包，为分支祖先）；非切片源（slice README 未引用；仓库内无 csproj/sln 引用）。
- 定夺：属初检出/稀疏残留 → 记入 maui `.git/info/exclude`（`/src/Compatibility/`）本地静默；**未改 tracked .gitignore、未删文件**；如需回收可直接删（内容在 origin/main）。

## 2. 分支底册（2026-10-04；`origin/*` 已刷新）

| 仓 | 本地 | 已推同步 | 本地已并 | 未推 | 归档推送 | 可删候选 |
|---|---:|---:|---:|---:|---:|---:|
| runtime-ohos | 49 | 26 | 4（docs/\*） | 19（rehearse/\*） | 1 | 23 |
| ohos-workload | 18 | 3 | 11 | 4（backup/\* 3 + feat/payload-zip-optin） | 2 | 15 |
| maui-ohos | 23 | 9 | 8 | 6（4 superseded + backup/r1×2） | 1 | 14 |
| sdk-ohos | 21 | 8 | 13（含 2 支 behind） | 0 | 0 | 13 |
| aspnetcore-ohos | 5 | 5 | 0 | 0 | 0 | 0 |

- 未推归档（新 ref，未强推；推送后 `ls-remote` 校验通过）：runtime `archive/ohos-sandbox-fixes-2511c989`（2511c989，8 提交）；ow `archive/r1-recovery-45c1fb0`（45c1fb0，覆盖 3 支 backup 共 4 提交）与 `archive/payload-zip-optin`（3bfdf97）；maui `archive/r1-managed-bridges-45b44cd4`（45b44cd4，覆盖 backup/r1×2）。
- 未推但**未归档**（经比对为已推版本的旧基线/rebase 前状态）：runtime `rehearse/*` 19 支（对应 `pr/*` 已推）；maui `t10-integration`（T10 = origin `c56bf0fa2d`）、`w2b-t3t5`/`w2b-int`（T5 = origin `c1c05f3b`）、`w9-merge-ebffdd`（B2/AOT/T8/T20/T14/T21 均已推）。
- 可删候选（**只列不删，交用户**）：runtime = 4 `docs/*`（已并）+ 19 `rehearse/*`（被 pr/* 取代）；ow = 11 支已并（`a11y-tab-suite, consol-pins, fix-dev1-optional-dlsym, fix-tab-suite, interp-fix-host, merge/ohos-rc2-master, p1b-list, p2c-deeplink, w2b-t5, w5b-suite, w6b-suite`）+ 3 `backup/*`（已归档）；maui = 8 支已并（`a11y-tab, consol-t3, p1b-list, p2c-deeplink, w2b-t5, w4b-t6, w5b-t21, w6b-t12`）+ 4 superseded（`t10-integration, w2b-int, w2b-t3t5, w9-merge-ebffdd`）+ 2 `backup/r1-*`（已归档）；sdk = 13 支已并/落后（`ci-sdk/arch-guard-fix, feature/openharmony(-8), fix/ohos-msbuild-pipe-patch, fix/rc2-pins, interp-fix-pack, kit32..kit39-anchor, lo-b/aot-asset-pointer, lo-d/aot-doc-rc2, m-web-mirror(-2)`）；aspnet = 0。

## 3. worktree / prune

- `git worktree list` 五仓注册 **2 / 17 / 20 / 4 / 2** 个；逐个核验工作目录存在且 `.git` 有效 → **0 个失效**；`git worktree prune -n -v`（五仓）均无输出、rc=0 → **本轮无 prune 动作**（MISC-42 已清过；脏 worktree 按当时分类保留）。

## 4. 提交与不确定

- 本文件 + docs/plans 索引/覆盖矩阵回填经 `commit-paths.sh` 提交（runtime-ohos `feature/openharmony`，未强推）；分支/worktree 明细脚本与输出在 scratch `hygiene/`（未入库）。
- 不确定：sdk 本地 `feature/openharmony`（-8）与 `m-web-mirror`（-2）为落后镜像，未自动快进（避免与并发代理竞态）；归档 ref 未设 upstream 跟踪；rehearse/backup 的删除价值由用户最终定夺。
- 另记（未处理）：runtime-ohos 根目录 2 个 pgrep 误产物（`51013`、含换行的 `51013\n54065\n54197`，20/26 B）未跟踪，随后续 scratch 清理处置。
