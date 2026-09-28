# 上游 rebase 预演：pr/* 与 rehearse2/*（2026-09-28）

- **上游 tip**：`caf6b2a2243`（2026-09-28，"…Fix DI generic constraint tests…" #134760）；较 09-23 演练基线 `5b82fc4ae86b` **+75 commit / 501 文件**。
- **方法（只读）**：`git merge-tree --write-tree --name-only upstream/main <ref>` 预测 39 个 ref；再在 scratch 临时 worktree 的 `up-rehearse/*` 临时分支上 `git rebase --onto`（infra 先重锚到新 tip，flat 支剥离旧 infra 前缀 `cece42439a1`）。原分支/远端零改动、未推送；worktree 与临时分支已删除。
- **结论**：merge-tree **39/39 CLEAN**；rebase **20/21 CLEAN**（19 支改动 `-U0` patch-id **SAME** ＋ 1 支 **EMPTY**＝去重证明），唯一冲突 = `tls-flag-cleanup`（既定丢弃）。**0 支需重做**。
- **证据**：scratch `/data/storage/el2/base/tmp/opencode/up-rehearse/`（`mergetree.tsv`、`rebase-results.tsv`、`results-final.tsv`、`logs/*.rebase.log`）。

## 逐支预测与确定落地顺序（pr/*）

| 顺序 | 分支 | base（自有提交 parent） | 提交（自有/总） | merge-tree | rebase 演练 | 前置/依赖 |
|---|---|---|---|---|---|---|
| ① | `pr/ohos-infra` | `04a9b1aa805` | 15/15 | clean | clean・SAME | #132953 评审+rerun；落前同步 `eng/common`（arcade#17608 已合并） |
| ② | `pr/ohos-clrfeatures`（N1） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ② | `pr/ohos-pal`（N2） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ② | `pr/ohos-zstd`（N3） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ② | `pr/ohos-libs-native`（N4） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ② | `pr/ohos-apphost`（N5） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ② | `pr/ohos-tryrun`（N14） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ③ | `pr/ohos-pal-process`（N7） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ③ | `pr/ohos-ifaddrs`（N8） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ③ | `pr/ohos-wx-default`（N9） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ③ | `pr/ohos-crossgen-corelib`（N10） | `cece42439a1` | 1/13 | clean | clean・SAME | ①；upstream 对该 `.proj` 仍活跃，落地前再核上下文 |
| ④ | `pr/ohos-aot-unix`（N11） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ④ | `pr/ohos-aot-singleentry`（N12） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ⑤ | `pr/ohos-packs`（N13） | `7c6ee24c205` | 1/1 | clean | clean・SAME | ①＋④（AOT 形态） |
| ⑥ | `pr/ohos-libs-tfm`（N15） | `cece42439a1` | 1/13 | clean | clean・SAME | ① |
| ⑦ | `pr/ohos-console`（N16） | `2bab0935bf6` | 1/14 | clean | clean・SAME | ⑥（堆叠） |
| ⑧ | `pr/ohos-shims-tfm-cleanup`（C2） | `cece42439a1` | 2/14 | clean | clean・SAME | ①＋#132866 答复；若⑥先落需 rebase 到⑥后并去掉与 N15 重复的首提交 |
| ⑧ | `pr/ohos-illink-ntlm`（C3） | `719009acffb` | 1/1 | clean | clean・SAME | #132866 答复（独立 PR 或折入 N12） |
| — | `pr/ohos-sandbox-fixes` | `bd36a2deb2d` | 1/1 | clean | clean・SAME | 本体即 #132827（open，head=分支 tip）；不阻塞 17 支 |
| — | `origin/pr/ohos-platform-numa` | `513b9cd40dca` | 1/1 | clean | **EMPTY**（rebase 报 patch already upstream） | **丢弃**：#134670（`7408c77328c`）已进 main，patch-id 相同 |
| — | `pr/ohos-tls-flag-cleanup` | `cece42439a1` | 1/13 | clean | **CONFLICT** `eng/native/configurecompiler.cmake` | **丢弃**：改动已被 infra `8ef4e925163` 吸收 |

## 备注

- **#134670 去重提示**：`OperatingSystem.cs` / `numasupport.cpp` / `System.Private.CoreLib.Shared.projitems` 已在上游；`feature/openharmony` 尚未含该提交（09-28 tip `ccade4009c4`，落后 377），按 playbook §1 合并/去重时以上游为准。
- `rehearse2/*` 清单（18 ref，base 均 `5b82fc4ae86b`，提交数=旧 infra 栈＋自有）：infra(15)、clrfeatures/pal/zstd/libs-native/apphost/tryrun/pal-process/ifaddrs/wx-default/crossgen-corelib/aot-unix/aot-singleentry/libs-tfm(16)、console/shims-tfm-cleanup(17)、packs/illink-ntlm(1)；本轮 merge-tree 18/18 CLEAN，但为 09-23 产物且滞后 75 提交，**不要直接当 PR head**（本轮已用 `pr/*` 等价重演）。
- 演练时间：2026-09-28（CST）上午；上游复查命令仅 `git fetch upstream main`（直连可用）。
