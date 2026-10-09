# N 组 PR 批量开启清单（预生成，2026-09-28）

> **现况更新（2026-10-09）**：①`#132953` **仍未合** ✗（A2-a 二次推进已发，等 jkoritzinsky/jkotas ✓）；
> ②`upstream/main` 已前进到 `14e8bce614e`（**+218 提交** ✗）→ **前置 2 触发：必须先重演** ⚠️
> （merge-tree 全量 + 17 支 rebase 演练，方法见 playbook §2 与本页 §2 ✓）；③`eng/common` 前提已清 ✓
> （arcade#17608 于 09-24 合并 ✓）；④**`#135321` 已合并**（10-07 ✓）→ 去重清单中的
> `NamedMutex.Unix.cs` **以上游为准** ✓（fork 同名 hunk 直接丢弃 ✓）；⑤C2/C3 仍等 `#132866` 答复 ✗；
> ⑥自 2026-10-08 起**所有上游可见动作逐次报批** ✓（playbook §3 ✓）。

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
