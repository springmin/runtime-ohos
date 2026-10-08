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
  ⑦ N16 console（前置=⑥，堆叠）→ ⑧ C2 shims-tfm-cleanup（前置=①＋#132866；若⑥先落需 rebase 到⑥后并去掉与 N15 近乎重复的首提交；`shims/Directory.Build.props` 1 行条件差异见 §6）/ C3 illink-ntlm（前置=#132866 答复）。
- 已决例外：`pr/ohos-platform-numa` 丢弃（＝已合并 #134670，patch-id 相同）；`pr/ohos-tls-flag-cleanup` 丢弃（已被 infra `8ef4e925163` 吸收）；`pr/ohos-sandbox-fixes` = #132827 本体（open，不阻塞 N 组）；`pr/ohos-named-mutex` 丢弃（＝已合并 **#135321**，2026-10-07，rebase 后净差为空，#135321 同时去重 `pr/ohos-sandbox-fixes` 的 mutex hunk，剩余 TMPDIR＋MutexTests，见 §5 10-07）。
- `#132953` 合并后把各 `pr/*` rebase 到 post-infra main 再逐支开 PR；`rehearse2/*` 是 09-23 演练产物（滞后 75 提交），**不要直接当 PR head**。
- `eng/common` 同步依赖 arcade#17608（已合并）；infra 落地后先同步 `eng/common`，再落 N 组。

## 3. 纪律

- **评论/动作需许可（2026-10-08 强化）**：**所有对上游（dotnet/*）可见的动作——PR 评论、评审回复、
  新建 PR、向 PR 分支推送（含应用评审建议 ✗）——逐次先出草稿/说明，等待明确的「发」再执行** ✗；
  **不得自动发送** ✓。上游评论/催评草稿（`2026-09-23-ohos-upstream-reply-drafts.md`）同理 ✓；
  #132953 rerun 的对外动作亦先报备 ✓。**不受影响** ✓：我方仓库（runtime-ohos/sdk-ohos/aspnetcore-ohos/
  ohos-workload/maui-ohos）的本地提交与推送、文档、设备/CI 操作（发布面变更仍逐次报备 ✓）。
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

## 5. 漂移表与周期复演（2026-10-05 / 2026-10-07）

周期只读复演：三仓 `git fetch upstream main`（重试）；runtime 39 ref merge-tree ＋ 21 支 rebase；sdk 2 支、aspnetcore 1 支；原分支/远端零改动、未推送。

| 上游 | 10-04 基准 | 10-05 tip | 漂移 |
|---|---|---|---|
| dotnet/runtime | `cfe8a6c4600`（10-04） | **`8e6821d2d912`**（10-05，"Fix allocation-by-class profiler cache ownership" #134390） | +15 commit / 258 文件 |
| dotnet/sdk | `590b0970fe66`（10-03） | `590b0970fe66`（未动） | 0 |
| dotnet/aspnetcore | `dc8b384c43`（10-03） | **`7eef82517d72`**（10-05，#69634） | +4 commit / 18 文件 |

- **2026-10-07 只读复核（`git ls-remote`，未 fetch、零 ref 改动）**：runtime `f963e45bdd70`（10-05 `8e6821d2d912`）、sdk `fbf921a87f1f`（10-05 `590b0970fe66`）、aspnetcore `16e71d2fdda9`（10-05 `7eef82517d72`）——三仓均有漂移；**已于 10-07 周期复演**（结果见本节末「2026-10-07 周期复演」）。

| 仓 | merge-tree | rebase dry-run | 与 10-04 对比 |
|---|---|---|---|
| runtime | 33/39 CLEAN；6 CONFLICT（`libs-tfm`/`console`/`shims-tfm-cleanup` 的 `pr/*` 与 `rehearse2/*`） | 17/21 CLEAN（16 支 SAME＋`platform-numa` EMPTY；`console` 自身提交 CLEAN、受阻于 libs-tfm）；3 CONFLICT＝`libs-tfm`、`shims-tfm-cleanup`（新增，§6）、`tls-flag-cleanup`（既定丢弃） | 10-04 = 39/39＋20/21；**新增 2 支冲突，落地需按 §6 解一次（内容无需重写）** |
| sdk | 2/2 CLEAN | 2/2 CLEAN・SAME（rids 3 提交／sandbox 5 提交；预演 tip `11df3fa955`/`048d1c8250`） | 同 10-04（上游未动） |
| aspnetcore | 1/1 CLEAN | 1/1 CLEAN・SAME（预演 tip `fe879f3a18`） | 同 10-04 |

- **状态：非全绿** —— 上游 `#134813`（`fa693c42fb6`）与 fork OH TFM 块在 `src/libraries/Directory.Build.props` 同一插入点相邻新增（**已预解**：§6 解决经 2026-10-05 本机复演验证，6 ref 应用后全 CLEAN）；**与 §1 步 4 的"零冲突"预期不同，需见 §6**。
- runtime 复演产物：infra 重锚 tip `fe80d24e72`；其余 16 支 `-U0` patch-id SAME、`platform-numa` EMPTY（同 10-04）。
- 证据：`/data/storage/el2/base/tmp/opencode/ur1005/`（`mergetree.tsv`、`rebase-results.tsv`、`rebase-sdk.tsv`、`rebase-asp.tsv`、`mergetree-conflicts.tsv`、`*.log`）；scratch worktree 已清、未创建临时 ref。
- 口径备注：复演期间本地 `pr/*` 已被并发 branch-hygiene 清理，本表用同 SHA 的 `origin/pr/*`（21 支，与 10-04 表逐支一致）。

### 2026-10-07 周期复演（第 2 次，UPSTREAM-REHEARSE-1007）

三仓 `git fetch upstream main` 一次成功（runtime/aspnetcore 直连、sdk 经 gh-proxy，HTTP/1.1）；runtime 40 ref merge-tree ＋ 22 支 rebase，sdk 2 支、aspnetcore 1 支；原分支/远端零改动、未推送、未创建临时 ref（全程 detached HEAD）。

| 上游 | 10-05 tip | 10-07 tip | 漂移 |
|---|---|---|---|
| dotnet/runtime | `8e6821d2d912`（10-05） | **`14e8bce614e`**（"Add support for WASM in Disassembler" #135324） | +55 commit / 430 文件 |
| dotnet/sdk | `590b0970fe66`（10-05） | **`e4ea7d5ffa`**（#56438 incremental workload manifest layout） | +64 commit / 114 文件 |
| dotnet/aspnetcore | `7eef82517d72`（10-05） | **`851622243f`**（#69696；含 #69631 CPM 重构 `121024a14a`） | +10 commit / 680 文件 |

| 仓 | merge-tree | rebase dry-run | 与 10-05 对比 |
|---|---|---|---|
| runtime | 34/40 CLEAN；6 CONFLICT＝`libs-tfm`/`console`/`shims-tfm-cleanup`＋`rehearse2/*` 同形 3 支，唯一文件 `src/libraries/Directory.Build.props`（按 10-05 的 39-ref 口径＝33/39＋同样 6 冲突；新增第 22 支 `pr/ohos-named-mutex` CLEAN） | 17/22 CLEAN（15 支 SAME＋`sandbox-fixes` 预期 DIFF＋`named-mutex` 净差空）；3 CONFLICT（同 10-05：`libs-tfm`、`shims-tfm-cleanup`、`tls-flag-cleanup`）；`platform-numa` EMPTY；`console` 自身提交 CLEAN（受阻 libs-tfm） | 冲突集与 10-05 逐支一致；**上游 #135321 合入**：`named-mutex` 内容已上游（丢弃）、`sandbox-fixes` 去重后 patch-id DIFF |
| sdk | 2/2 CLEAN | 2/2 CLEAN・SAME（预演 tip `68f824b668`/`65a3b9dd87`） | 同 10-05（上游 +64 提交，两支仍 SAME） |
| aspnetcore | 0/1 CLEAN；1 CONFLICT（`eng/Dependencies.props`，delete/modify） | 1/1 CONFLICT → 按解化解出 CLEAN(resolved)（`2277673c61`；语义 5 files/21+/4- 不变） | **新增冲突**（上游 #69631；见 §7） |

- **上游进展（10-07）**：runtime **#135321**（`5b3285fb815`，springmin，"Skip robust mutexes on OpenHarmony"）＝`pr/ohos-named-mutex` 本体 → rebase 后对 `upstream/main` 净差为空，**按 `platform-numa` 同法丢弃**；`pr/ohos-sandbox-fixes`（#132827 本体）的 `NamedMutex.Unix.cs` 条件 hunk 随 #135321 自动去重，剩余 delta＝`SharedMemoryManager.Unix.cs` TMPDIR＋`MutexTests.cs`（该文件另余 2 行已被上游改写过的冗余注释，落地时应丢）→ rebase CLEAN、patch-id DIFF 为预期。
- **runtime 6 冲突 union 复验（本机只读，2026-10-07，`14e8bce614e`）**：**仍可 union 解**——`libs-tfm`/`console`/`shims-tfm-cleanup` 与 `rehearse2/*` 3 支全部 `CLEAN(resolved)`、`-U0` patch-id SAME、merge-tree 冲突 blob 同 union 解后与 rebase 结果 byte-EQUIV（EQUIV ×6）、解后 tip 对 upstream merge-tree CLEAN；解后 `src/libraries/Directory.Build.props` 与 10-05 解 **byte-一致**（上游自 10-05 未再触碰该文件）。§2 ⑧ 去重路径（丢 c1 应用 c2）：仅 `src/libraries/shims/Directory.Build.props` 冲突一次，按 §6 残余草图解后 CLEAN，主 props 与完整重放 byte-一致、dedup tip merge-tree CLEAN。详见 §6 末条。
- **aspnetcore 冲突（新增）**：`eng/Dependencies.props` delete/modify（上游 #69631 删除该文件），解＝接受删除＋4 行 RID 移植至新 CPM 目录 `Directory.Packages.props`；详见 §7。
- 证据：`/data/storage/el2/base/tmp/opencode/ur1007/`（`fetch.log`、`mergetree.tsv`、`mergetree-conflicts.tsv`、`rebase-results.tsv`、`rebase-sdk.tsv`、`rebase-asp.tsv`、`rt-fix/`、`asp-*` 等）；scratch worktree 已清、未创建 ref、未推送。

## 6. 新冲突记录：`src/libraries/Directory.Build.props`（2026-10-05；解决已验证 2026-10-05）

- **文件**：`src/libraries/Directory.Build.props`（唯一冲突文件；add/add 邻近插入）。
- **双方**：上游 WASI `PropertyGroup`＋`Import`（`TestWasmReadyToRun`/`TargetOS==wasi`，`fa693c42fb6`） vs fork OH `PropertyGroup`（`TargetsOpenHarmony` 的 `LibrariesOpenHarmonySfxTfm`/`ShimsTfm`，`2bab0935bf6`）；插入点同为 `<Import Project="..\..\Directory.Build.props" />` 之后、`UseBootstrap` 组之前。
- **解决（=草图，已验证）**：两块都保留——上游 WASI 块在前，fork OH 块紧跟其后、空行分隔，其余上下文不变。条件真互斥：`TargetsOpenHarmony` ⇔ `PortableOS==openharmony`（`eng/RuntimeIdentifier.props:57`），而 `PortableOS=$(TargetOS)` 直接派生（同文件 L9-15），wasi 构建下为 false；且两块属性名不相交（`AfterMicrosoftNETSdkTargets` vs `LibrariesOpenHarmonySfxTfm`），即便同时命中也无冲突。解后 XML 合法（ElementTree parse 通过）。
- **复演（本机只读，2026-10-05，upstream/main `8e6821d2d912`）**：scratch worktree＋临时分支 `rehearse-fix/*`（用后即删；`pr/*`、`rehearse2/*` 零改动、未推送）。命令：`git rebase --onto <post-infra tip> <base>`，冲突时唯一文件 `src/libraries/Directory.Build.props` → union 解（ours＝WASI 块、theirs＝OH 块，保留两者）→ `git add` → `GIT_EDITOR=true git rebase --continue`。结果：`libs-tfm` / `console` / `shims-tfm-cleanup` / `rehearse2/libs-tfm` / `rehearse2/console` / `rehearse2/shims-tfm-cleanup` **6 ref 全 CLEAN**；`-U0 patch-id` 全 SAME（fork 内容零改写；range-diff 仅 WASI 块上下文位移，`console` 自身提交 `=`）；merge-tree 冲突 blob 按同一 union 解出的文件与 rebase 结果逐字节相同（EQUIV ×6）；解后 tip 对 upstream/main merge-tree CLEAN。
- **残余（去重路径，§2 ⑧）**：shims 首提交与 libs-tfm 首提交并非完全 patch 相同——`src/libraries/shims/Directory.Build.props` 条件写法差 1 行（shims c1 `'$(TargetOS)' == 'openharmony'` vs libs-tfm `'$(TargetsOpenHarmony)' == 'true'`）。⑥先落后 ⑧ 去重（丢首提交）会在该文件冲突一次；解：取 c2 的注释与 `$(LibrariesOpenHarmonySfxTfm)` 值、条件保留已落的 `TargetsOpenHarmony` 形态（两者等价，见上）。该去重路径复演 CLEAN，主 props 与完整重放逐字节一致。
- **影响/落地**：`pr/ohos-libs-tfm`（1 提交）、`pr/ohos-shims-tfm-cleanup`（2 提交，首个近乎重复）、`pr/ohos-console`（自身只改 `System.Console.csproj`：解掉 libs-tfm 后自动 clean）；按 §2 顺序 ⑥/⑧ 各解一次（一次性）；`rehearse2/*` 同法可解但不直接当 PR head；`tls-flag-cleanup` 维持丢弃。
- **证据**：`/data/storage/el2/base/tmp/opencode/ur1005/rehearse-fix/`（`rehearse-fix.tsv`、`rehearse-fix.log`、`merge-equiv.tsv`、`conditions.txt`、`resolution.diff`、`resolved-Directory.Build.props`、`mergeconf-*.txt`）；worktree 与临时分支已清、未推送。
- **10-07 状态（仍可 union 解）**：upstream/main `14e8bce614e` 复验——3 支冲突 `pr/*`＋3 支 `rehearse2/*` 全 `CLEAN(resolved)`、`-U0` patch-id SAME、merge-tree blob union 解 byte-EQUIV ×6；解后文件与 10-05 解 byte-一致（`b1b5f38c…`；上游自 10-05 未再触碰该文件）；§2 ⑧ 去重路径按上述残余草图解后 CLEAN（主 props 与完整重放 byte-一致、dedup tip merge-tree CLEAN）。证据：`/data/storage/el2/base/tmp/opencode/ur1007/rt-fix/`（`rehearse-fix.tsv`、`merge-equiv.tsv`、`dedup-verify.tsv`、`resolved-Directory.Build.props`）；worktree 已清、零 ref 创建、未推送。

## 7. 新冲突记录：aspnetcore `eng/Dependencies.props`（2026-10-07；delete/modify）

- **文件/类型**：`eng/Dependencies.props`——上游 **#69631**（`121024a14a`，"Replace custom reference resolution with explicit references and CPM"）**删除**该文件；fork `pr/ohos-aspnet-rids`（`b7070c3748`，单提交）在其上 +4 行 openharmony RID → merge-tree 与 rebase 均报 **delete/modify**（`DU`，非块 union；该文件不会 auto-merge）。
- **解决（草图，已在本机 10-07 复演验证）**：接受上游删除（`git rm eng/Dependencies.props`）；把 4 行 RID 语义移植到新 CPM 目录 `Directory.Packages.props`（`_RuntimePackageVersion` 段）——`Microsoft.NETCore.App.Runtime.openharmony-x64/-arm64`（`linux-musl-arm64` 之后、`freebsd` 之前）与 `Microsoft.NETCore.App.Crossgen2.openharmony-x64/-arm64` 同位置；fork 其余 4 文件（`Directory.Build.props`、`src/Tools/Directory.Build.props`、2 个 E2E csproj）自动合并、无需人工。
- **复演（本机只读，2026-10-07，upstream/main `851622243f`）**：scratch worktree＋detached HEAD；`git rebase --onto upstream/main 7b520eb5d33` → 唯一冲突 `eng/Dependencies.props`（DU）→ 上述移植 → `git rebase --continue` → **CLEAN(resolved)**，rebased tip `2277673c61`，stat 与原始提交同为 5 files/21+/4-（4 行 RID 换宿主、其余不动）；`-U0` patch-id `f33ab6ad…`→`d3cee48f…`（**DIFF 为预期**：仅文件位置变化，非内容丢失）。解后三份 XML parse 通过。
- **影响/落地**：`pr/ohos-aspnet-rids`（1 提交）落地时需解一次（一次性移植）；sdk/aspnetcore 其余面不变。
- **证据**：`/data/storage/el2/base/tmp/opencode/ur1007/`（`asp-fix.log`、`asp-fix-stat.txt`、`asp-resolved-vs-upstream.diff`、`asp-port-hunk.diff`、`asp-patchids.txt`、`asp-rebased-tip.txt`）；worktree 已清、未推送。
