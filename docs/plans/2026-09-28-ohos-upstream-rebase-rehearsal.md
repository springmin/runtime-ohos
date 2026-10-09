# 上游 rebase 预演：pr/* 与 rehearse2/*（2026-09-28）

## 2026-10-09 复演刷新（C3 预演，+218 提交）

> **上游 tip**：runtime `14e8bce614e`（2026-10-08，"Add support for WASM in Disassembler" #135324；较本页
> 09-28 基线 `caf6b2a2243` **+218 commit / 1630 文件**（+84148/−51643），较 10-04 复演 tip `cfe8a6c4600` +70）、
> sdk `bdf6a59a37`（2026-10-09；较 10-04 `590b0970fe` +73）、aspnetcore `91fbd2bdcf`（2026-10-09；较 10-04
> `dc8b384c43` +27）。
> **方法（只读）**：改用隔离 `--shared` clone（主仓零写入；scratch 内先设 `user.name/email`——首遍因缺失被
> 判伪 CONFLICT，已整体重跑）；merge-tree 全量 **40 ref**（22 `pr/*`＋18 `rehearse2/*`，首次纳入新支
> `named-mutex`）；按落地顺序在临时分支上 `rebase --onto`（flat 支剥旧 infra 前缀 `cece42439a1`）＋ `-U0`
> patch-id 对照；对两处新冲突额外做了**手动分辨率重演**（见下）。原分支/远端零改动、未推送、未发评论。

### runtime（22 pr 支）

- **merge-tree：34/40 CLEAN；6 CONFLICT**——全部集中在 **libs-tfm 家族**（活支：`libs-tfm`、`console`、
  `shims-tfm-cleanup`；陈旧 rehearse2 同三支），冲突点均为 `src/libraries/Directory.Build.props`。
- **rebase：16 支 CLEAN-SAME ＋ 1 支 EMPTY ＋ 2 支 CLEAN-DIFF ＋ 3 支 CONFLICT**：
  - **`infra` CLEAN-SAME**（预演 tip `dce1e6a46bd`）——#132953 对本 tip 仍零冲突、逐位保持；其余 15 支
    CLEAN-SAME（预演 tip）：`clrfeatures` `c3ed402e3d3`、`pal` `fff3793bacd`、`zstd` `69cb70992e9`、
    `libs-native` `05d60466a2d`、`apphost` `b9982b308a7`、`tryrun` `f48bbbd2f54`、`pal-process` `059cf5aed91`、
    `ifaddrs` `46342f6ebe0`、`wx-default` `23cbf569019`、`crossgen-corelib` `93285a8ddf2`、`aot-unix` `9564838b040`、
    `aot-singleentry` `6fc984e2f9b`、`packs` `9aad8e71ecf`、`console` `2a9d4455cef`、`illink-ntlm` `f100da3de55`。
  - **`libs-tfm`（N15）CONFLICT（新）⚠️**：上游 #134813（wasi R2R，`fa693c42fb6`）与 N15 在同一插入锚点
    （`<Import Project="..\..\Directory.Build.props" />` 之后）各自新增块 → **机械冲突，两者可共存**；
    手动重演验证：**删冲突标记、保双方即可**（解析后 tip `610cab89d51`；与原件唯一差异 = 空行归属，内容等价）。
  - **`shims-tfm-cleanup`（C2）CONFLICT（新）⚠️**：首提交 `01667c2c6d5` ＝ N15 旧版（仅 1 行条件差异：
    `TargetOS=='openharmony'` vs 修订后 `TargetsOpenHarmony=='true'`）→ 按既定策略**落时丢弃首提交**；
    第二提交 `1157f1daf5c` 落在已解析 N15 上时，`shims/Directory.Build.props` 需**合并**（取新注释＋`SfxTfm`＋
    修订条件）；手动重演验证 tip `af4cd04b5d2`（6 文件，+26/−3）。
  - `tls-flag-cleanup` CONFLICT（`eng/native/configurecompiler.cmake`）——**既定丢弃**，同 10-04。
  - `platform-numa` **EMPTY**（#134670 已上游）——丢弃确认。
  - `named-mutex`（新支）：重演净 diff **为空**（#135321 已上游化）——**可直接弃用/留档**。
  - `sandbox-fixes`：rebase 成功但内容自动去重（`NamedMutex.Unix.cs` +4/−1 → +2：条件部分已随 #135321
    上游，仅余注释行）——**#132827 复活时以重演后形态为准**。
- **与 10-04 对比：唯一新增 = N15/C2 两处机械冲突**（均由 #134813 引入），其余 19 支状态不变；**0 支需重做**。

### sdk / aspnetcore

- **sdk**：`pr/ohos-sdk-rids`、`pr/ohos-sdk-sandbox` merge-tree CLEAN → rebase **CLEAN-SAME**
  （预演 tip `c3dbf80da7` / `b92fce334a`）。
- **aspnetcore**：`pr/ohos-aspnet-rids` merge-tree **CONFLICT** → rebase **CONFLICT** ⚠️——上游 #69631
  （`121024a14a`，10-07，"…explicit references and CPM"）**删除了 `eng/Dependencies.props`**，本支仍修改它
  （modify/delete 硬冲突）。修复方向：该 4 行迁至 `Directory.Packages.props` 的 `_RuntimePackageVersion`
  列表；其余 4 文件可自动合并。**属 aspnet 线跟进项，不在 C3 范围**。

### 证据与备注

- scratch：`/data/storage/el2/base/tmp/opencode/up-rehearse-1009/`（`mergetree.tsv`、`rebase-results.tsv`、
  `sdk-results.tsv`、`sdk-rebase2.tsv`、`aspnet-results.tsv`、`aspnet-rebase2.tsv`、`logs/`）；隔离 clone
  （`rt/`、`sdk-rt/`、`aspnet-rt/`）用后删除。
- 方法修正：scratch clone 必须设 `user.name/email`，否则 rebase 建提交失败被误判为 CONFLICT（首遍已作废重跑）。
- C3 含义：`infra` 及 15 支 N 支可直接按序重锚；**N15/C2 落时按上述已验证分辨率各解 1 处**（配方在案）；
  `platform-numa`/`named-mutex`/`tls-flag-cleanup` 弃用确认；sdk 两支持续干净；aspnet 单独立项跟进。

## 2026-10-04 复演刷新（RC2-UPSTREAM，重试轮）

> 三仓 `git fetch upstream main`（网络重试）后，按 09-28 只读法重跑 merge-tree + scratch-worktree rebase。
> 当日两遍收口：首遍 tip `4f5c27fbf3b`（+147 commit / 1105 文件），终遍 tip `cfe8a6c4600`；下列数值为终遍，
> 收口后 21:5x 再次 fetch 复查，三仓 tip 均未再动。
>
> - **上游 tip**：runtime `cfe8a6c4600`（2026-10-04，"Fix build break with latest MSVC" #135176；较本页 09-28 基线
>   `caf6b2a2243` **+148 commit / 1107 文件**）、sdk `590b0970fe`（2026-10-03）、aspnetcore `dc8b384c43`（2026-10-03）。
> - **runtime**：merge-tree **39/39 CLEAN**；rebase **20/21 CLEAN**（19 支 `-U0` patch-id **SAME** ＋ `platform-numa` **EMPTY**；
>   唯一冲突 `tls-flag-cleanup`＝既定丢弃）。**0 支需重做；各支落地顺序与下页 §逐支预测一致**；infra 重演产物 tip `e4c51c6f3c6`。
> - **sdk**：`pr/ohos-sdk-rids`（3 提交）/ `pr/ohos-sdk-sandbox`（5 提交）均 merge-tree clean → rebase clean・SAME
>   （预演 tip `bd1beba3b3` / `70321883d8`）。
> - **aspnetcore**：`pr/ohos-aspnet-rids`（1 提交）merge-tree clean → rebase clean・SAME（预演 tip `ecdd478930`）。
> - `rehearse2/*` 18 ref merge-tree **18/18 CLEAN**（仍为 09-23 产物，**不要直接当 PR head**）。
> - **证据**：scratch `/data/storage/el2/base/tmp/opencode/up-rehearse-1004b/`（`mergetree.tsv`、`rebase-results.tsv`、
>   `results-final.tsv`、`sdk/`、`aspnet/`、`logs/`；首遍 `up-rehearse-1004/` 保留）。原分支/远端零改动、未推送；
>   三仓 worktree 与 `up-rehearse-1004b/*` 临时分支已清。
> - **未发任何评论**（对外动作照旧先报备）。

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
