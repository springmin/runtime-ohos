# N 组 PR 批量开启清单（预生成，2026-09-28）

> **现况更新（2026-10-14）**：①`#132953` **已 MERGED ✓✓**（jkotas 于 10-14 13:48:36Z **squash** ✗ → `14399016e4c` ✓ 已验证在 main=`0232cf718cd` ✗）——**C3 正式激活** ⏳（复演刷新已完成 ✗；eng/common 同步待做 ✗；`#132866` 仍缺 ✗）；
> ②`upstream/main` = `0232cf718cd`（post-infra ✗）→ **C3 复演刷新已执行** ✓（10-14 ✗，隔离 scratch ✗）：13 支 CLEAN-SAME ✓；
> **4 支冲突已全解析并终验** ✓（`pal-process`/`crossgen-corelib`＝上游新变更（`#135753`/`#135397`）所致 ✗；`libs-tfm`/C2＝机械复现 ✗；
> recipes/tips/pids 见演练文档「10-14 C3 复演刷新」节 ✗）；`infra` 已合并免重放 ✓，`tls`/`platform-numa`/`named-mutex` 弃 ✓；
> `platform-numa`/`named-mutex` 确认可弃、`tls-flag-cleanup` 既定丢弃 ✓；③`eng/common` 前提已清 ✓
> （arcade#17608 于 09-24 合并 ✓）；④**`#135321` 已合并**（10-07 ✓）→ 去重清单中的
> `NamedMutex.Unix.cs` **以上游为准** ✓（`pr/ohos-named-mutex` 重演净 diff 空 → 可弃 ✓）；⑤C2/C3 仍等 `#132866` 答复 ✗；
> ⑥自 2026-10-08 起**所有上游可见动作逐次报批** ✓（playbook §3 ✓）。
> **N1 已开（10-15）**：`#135808`（刷新重切版，净差门 4+/3- 纯 OpenHarmony）；**波次政策**：
> 在飞 ≤3–4 笔、「合 1 补 1」（先例 OpenBSD 38 笔小步快跑、中位 1.7 天；规避洪泛与 CI 成本）。
> **Wave-1 已开（10-15）**：#135838（pal）· #135839（zstd）· #135840（libs-native）——在飞 4 笔＝上限。**N1 已合（06:48Z）**；**N5 已补发（#135863）**；**N2 已合（14:12Z）**；**N8 已补发（#135866）**——在飞 4 笔（N3/N4/N5/N8）＝上限。

> **10-17 开前预检完成（N9＋W4）**：基线 `upstream/main=d80abfc4b04`。
> **N9** `pr/ohos-wx-default` → `770c2c80b6d`（零冲突；1 文件 4+/2-；§7 判定保持）；fire 包 `sync/bodies/N9-fire.md`。
> **W4**（fire 包齐 `sync/bodies/N{7,11,12,13,16}-fire.md`）：N7 `bad2a31158c`（`pal_process.c` **171+/8-**，含 `/proc` 版；OHOS NDK 编译核通过）、N11 `2d25123a366`（6+/1-）、N12 `ac328dbbddb`（4+）、N13 `5e13db906e8`（42+/5-；A/B 注释中性化＋B3 OR 形；残留：`_RemoveDuplicateSymbolFiles` 依赖的新 SDK 目标名本地不可核 ⚠️）、N16 `1297a3335e6`（叠 N15 `79178f8d0fc`；自身 delta 8+/3-；**N15 刷新后须再 rebase** ⚠️）。
> 全部**未推**；按「合 1 补 1」待合入触发。

> **10-19 N5 评审处置**：jkotas 同意报 CMake（"Yes… make OHOS a first-class across all commonly used tools"）；Copilot bot 2 条 → **Medium 已修**（`4236198a4db`：`runtimeinfo` 恢复为链接目标、保留 raw `--whole-archive` 语义）×High 以 Android 先例＋`#111523` 回复（线程回复 `r4311267124`／`r4311266765`）；**jkotas 已把 main 合入本分支**（`c1a22d8f9a`）；**CMake issue 已提交**（[`cmake/cmake#28188`](https://gitlab.kitware.com/cmake/cmake/-/work_items/28188)）＋**jkotas 回帖已发**（[`discussion_r4311471822`](https://github.com/dotnet/runtime/pull/135863#discussion_r4311471822)）。

> **10-20 N5 续** ✗：jkotas 注释建议已应用 ✓（`985a9ba061` ✗："Workaround for missing OpenHarmony WHOLE_ARCHIVE support in CMake. Remove once the minimum required CMake version is 4.5." ✗）；Copilot 第二轮 High（安全依赖块 191–196 ✗）**有效 ✓** → **已修** ✗（`bdc286176c3` ✗：guard 加 `NOT CLR_CMAKE_TARGET_OPENHARMONY` ✗）＋回复 [`discussion_r4320470576`](https://github.com/dotnet/runtime/pull/135863#discussion_r4320470576) ✓；CI 仍 **4 红**（flake ✗，build `1641156` ✗）。

> **10-20 次波预检（N14/N10/N15＋N16 重叠 ✗）** ✗：基线 `upstream/main=046f365b90c` ✗。N14 `pr/ohos-tryrun` → `13a04c52975` ✗（净差 **1 文件 8+** ✗；§7 注释已成稿 ✓）；N10 `pr/ohos-crossgen-corelib` → `ddfe9c77272` ✗（**1 文件 10+/1-** ✗；注释保留 ✓）；N15 `pr/ohos-libs-tfm` → `767cbcc2330` ✗（**6 文件 25+/3-** ✗；§7 成稿 ✓）；N16 `pr/ohos-console` **重叠至新 N15** → `15b7413acc1` ✗（自身 delta **8+/3-** ✗）。fire 包齐 ✓（`sync/bodies/N{14,10,15}-fire.md` ✗；N16 已更新 ✗）。**均未推** ✓。

> **10-20 N5 MERGED ✓**：`#135863` squash **`b37852e7e2c`**（04:57:08Z ✗）＝main tip ✓；**N9 已开** ✓ **`#136131`** ✗（`pr/ohos-wx-default` 重放至 `b37852e7e2c` → `5f93c6eed25` ✗；净差 **1 文件 4+/2-** ✓）——**在飞 4 笔**（N3/N4/N8/N9 ✗）。

> **10-20 N14 已开** ✓ **`#136132`** ✗：`eng/native: pin the OHOS cross-build FIFO probe answers` ✗；`pr/ohos-tryrun` 重放至 `b37852e7e2c` → **`7c3d4e4ed79`** ✗（净差 **1 文件 8+** ✓；首推遇旧远端支 `c2a5e90db55` 曾拒 ✗，已 force-with-lease 覆盖 ✓）。**在飞 5 笔**（N3/N4/N8/N9/N14 ✗；N9 已批待合 ✗）。

> **10-20 #132866 进度同步已发** ✓：[`#issuecomment-6285162682`](https://github.com/dotnet/runtime/issues/132866#issuecomment-6285162682) ✗——覆盖 6 合入／5 在飞／`#132827` 关闭／队列／三项待答（C3 带默认路径 ✗、C2 跟随 N15 ✗、S1c 仍问 ✗）；全量审计确认 **C2/C3 此前均无上游答复** ✓。

> **10-20 W4 四支已重放** ✓（基线 **`b37852e7e2c`** ✗）：N7 `0caa588edc1`（**1 文件 171+/8-** ✗；lease `c5e1dc3e4aa` ✗）、N11 `e127a79075d`（**6+/1-** ✗；lease `91a2e8e5a62` ✗）、N12 `3a9ce269991`（**4+** ✗；lease `da4dc098a4a` ✗）、N13 `1f860da25eb`（**4 文件 42+/5-** ✗；lease `fed16fdbdc9` ✗）。全部 behind 0／零冲突／净差面与预检一致 ✓，**均未推** ✓。

> **10-20 N14 评审处置** ✓：am11（08:38Z ✗）在 `tryrun.cmake:27` 要求把 OHOS 检测并入 platform probe、沿用既有 `elseif` 模式、删注释 ✓ → 已 amend＋rebase 至 `2422bb8fc1f` → **`fe9a4a1d020`**（净差 **1 文件 5+** ✗；本机 cmake 实测：env 设＝两项 1 ✓／env 空＝未设 ✓）→ force-push ✓；inline 回复 [`r4324508219`](https://github.com/dotnet/runtime/pull/136132#discussion_r4324508219) ✗。

> **用途**：#132953（infra）合并后，按既定顺序把 `pr/ohos-*` 批量 rebase 到 post-infra main 并开 PR。
> **依据**：`2026-09-28-ohos-upstream-fork-sync-playbook.md` §2、`2026-09-28-ohos-upstream-rebase-rehearsal.md`、
> `2026-09-21-ohos-pr-drafts.md`（每支的 Title/Body 全文）。
> **上游状态（2026-09-28）**：#132953 OPEN / REVIEW_REQUIRED；#132827 OPEN / APPROVED（hold，不催）；
> 演练基线 `upstream/main = caf6b2a2243`（merge-tree **39/39 CLEAN**；rebase **20/21 CLEAN**，唯一被丢弃的
> `tls-flag-cleanup` 已被 infra 吸收）。`eng/common` 同步依赖的 arcade#17608 已合并。

## 0. 前置检查（逐项过，缺一不开）

1. `gh pr view 132953 -R dotnet/runtime --json state` = `MERGED`。
   未合并前开 N 组会把 12 个 infra 提交算进各支 diff（playbook §2 的既定约束）。
2. `git fetch upstream main`：`upstream/main` 仍是 `caf6b2a2243`？若不是 → 先按演练文档重跑
   （`merge-tree --write-tree upstream/main <ref>` 全量 + 按顺序 rebase 演练），刷新基线后再继续。
3. 同步 `eng/common`（arcade#17608 已合并）；按 playbook 六步流程。
4. C2/C3 需要 **#132866** 的归属答复；未答复则跳过（不影响 N1–N16）。
5. 工作树干净、`pr/*` 本地与 origin 同步（演练方法是只读的，分支本身未动）。

## 1. 顺序、分支与标题（标题即 pr-drafts 的 Title）

| 序 | 支 | 标题 | 前置 |
|---|---|---|---|
| ① | `pr/ohos-infra` | Add OpenHarmony/HarmonyOS build infrastructure（#132953 本体） | #132953 MERGED |
| ② | N1 `pr/ohos-clrfeatures` | coreclr: disable the LTTng event source on OpenHarmony | ① |
| ② | N2 `pr/ohos-pal` | coreclr: PAL build fixes for OpenHarmony | ① |
| ② | N3 `pr/ohos-zstd` | native: use the C90 qsort workaround for zstd on OpenHarmony | ① |
| ② | N4 `pr/ohos-libs-native` | native: skip gssapi on OpenHarmony and use the OpenSSL crypto shim | ① |
| ② | N5 `pr/ohos-apphost` | corehost: singlefilehost fixes for OpenHarmony | ① |
| ② | N14 `pr/ohos-tryrun` | eng/native: pin the OHOS cross-build FIFO probe answers | ① |
| ③ | N7 `pr/ohos-pal-process` | System.Native: avoid close_range on OpenHarmony | ① |
| ③ | N8 `pr/ohos-ifaddrs` | System.Native: read the full ethtool speed on OpenHarmony | ① |
| ③ | N9 `pr/ohos-wx-default` | coreclr: default EnableWriteXorExecute to 0 on OpenHarmony | ① |
| ③ | N10 `pr/ohos-crossgen-corelib` | coreclr: keep the OpenHarmony CoreLib IL-only in-tree and map the crossgen2 target OS | ① |
| ④ | N11 `pr/ohos-aot-unix` | AOT: use lld and the ohos clang ABI on OpenHarmony | ① |
| ④ | N12 `pr/ohos-aot-singleentry` | AOT: map openharmony to linux/musl in the SingleEntry layout | ① |
| ⑤ | N13 `pr/ohos-packs` | packs: wire the OpenHarmony RID into the local pack graphs | ①＋④ |
| ⑥ | N15 `pr/ohos-libs-tfm` | libraries: compile OpenHarmony in the linux/unix TFM groups | ① |
| ⑦ | N16 `pr/ohos-console` | System.Console: use the unix ConsolePal on OpenHarmony | ⑥（堆叠） |
| ⑧ | C2 `pr/ohos-shims-tfm-cleanup` | （drafts 段）| ①＋#132866；若⑥先落需 rebase 到⑥后并去掉与 N15 重复的首提交 |
| ⑧ | C3 `pr/ohos-illink-ntlm` | （drafts 段）| #132866 |

已决丢弃：`pr/ohos-platform-numa`（= 已合并 #134670，patch-id 相同）、
`pr/ohos-tls-flag-cleanup`（已被 infra 的 `8ef4e925163` 吸收）。

## 2. 执行命令（模板）

```sh
# 0) 基线
git fetch upstream main
git merge-tree --write-tree upstream/main pr/ohos-infra >/dev/null   # 预期无输出（CLEAN）

# 1) 逐支 rebase 到 post-infra main。flat 支（N1/N2/... 的 parent 是旧 infra 前缀 cece42439a1）
#    用 --onto 剥离旧前缀；具体 parent 见 rehearsal 文档的逐支表。
for b in pr/ohos-clrfeatures pr/ohos-pal pr/ohos-zstd pr/ohos-libs-native \
         pr/ohos-apphost pr/ohos-tryrun pr/ohos-pal-process pr/ohos-ifaddrs \
         pr/ohos-wx-default pr/ohos-crossgen-corelib pr/ohos-aot-unix \
         pr/ohos-aot-singleentry pr/ohos-packs pr/ohos-libs-tfm pr/ohos-console; do
  git checkout -B "$b" origin/"$b"
  git rebase --onto upstream/main cece42439a1 "$b"   # 真实 parent 以 rehearsal 表为准
  git merge-tree --write-tree upstream/main "$b" >/dev/null || { echo "CONFLICT: $b"; break; }
  git push --force-with-lease origin "$b"            # pr/* 允许强推
done

# 2) 开 PR（标题/正文从 pr-drafts 各段的 **Title:**/**Body:** 抽取）
gh pr create -R dotnet/runtime --base main --head springmin:"$b" \
  --title "<drafts Title>" --body-file "/tmp/body-$b.md"

# 3) 回填：PR 号/tip 写回 pr-drafts 顶部状态表与 playbook §2
```

自动化建议：写 10 行的抽取脚本从 `2026-09-21-ohos-pr-drafts.md` 生成 `/tmp/body-<branch>.md`
（`**Body:**` 之后的代码块），避免手工复制；开 PR 前对每支断言 `merge-tree` 无输出。

## 3. 开完后的看护

- 堆叠约束：N16 依赖 N15；N13 依赖 ①＋④；C2 若晚于 N15 需处理与 N15 的重复首提交。
- 一支一提交、单关注点；评审返工只落在该支并同步堆叠子支。
- 记录：所有 PR 号、tip SHA、CI 状态回填到 pr-drafts 与 playbook（保持单页可追溯）。
