# rc2 冲突分片与解决计划（runtime，2026-09-28）

> 上游：`2026-09-28-rc2-migration-assessment.md` §5（并行评估）。本页是 **执行清单**：
> 67 个冲突文件的分类、每类策略、分片派工、验证与落地检查单。
> aspnetcore 侧已完成：影子分支 `fix/ohos-rc2` = `e10d030184`（4 个版本文件取 rc2，已推送）。

## 1. 冲突清单与总策略

来源：`git merge-base feature/openharmony upstream/release/11.0-rc2` 上做真实 merge dry-run
（2026-09-28，feature `e19147890d2`）：**67 文件**。完整清单见 §5。

**关键量化（本次新增）**：对每个冲突文件统计两侧对 `openharmony|ohos|harmony` 的提及——
**fork 独有 0 / 两侧都有 0 / 均无 67**。即：rc2 冲突**全部落在通用代码**（release 线回移修复
vs 主线演进），fork 的 OHOS 改动不在冲突面。策略因此可分类化：

| 类别 | 数量 | 策略 |
|---|---|---|
| 版本/Darc：`.config/dotnet-tools.json`、`eng/Version.Details.{props,xml}`、`global.json` | 4 | **取 rc2**（机械；与 aspnetcore 同款） |
| `eng/pipelines/**` + `eng/common/core-templates/**` | 20 | **取 rc2**（CI 配置；落前确认 fork 对同文件无自有改动：`git diff base..feature/openharmony -- <file>` 应为空或仅合并提交） |
| `src/libraries/**` | 32 | **逐 hunk 语义**：若 rc2 的回移已等价存在于主线（fork 侧包含同一修复）→ 取 fork；否则合并两侧 |
| `src/coreclr/**` | 5 | 逐 hunk 语义（JIT/ILCompiler 主线演进 vs 回移） |
| `src/tests` / `src/tasks` / `src/installer` / `src/native` | 3/1/1/1 | 逐 hunk；多为回移对齐，倾向取 rc2 并保留 fork 侧上下文 |

语义类判定规则（对每个冲突文件）：
1. `git diff base..upstream/release/11.0-rc2 -- <f>`：rc2 改了什么（回移修复）。
2. `git diff base..feature/openharmony -- <f>`：fork 侧改了什么（主线演进/合入）。
3. 若 rc2 的改动是 fork 侧改动的**子集**（同一修复、文本等价）→ 取 **fork**（ours）；
   若 fork 侧无对应改动 → 取 **rc2**（theirs）；否则**合并**（both），并逐一标注 hunk。
4. 结果记入"决策表"（§4 模板），应用时按表执行，避免边解边判。

## 2. 分片派工（分类与分析并行，应用单点串行）

| 分片 | 文件 | 方式 |
|---|---|---|
| S0 配置类 | 版本 4 + eng/pipelines 20 = 24 | 机械检查（fork 侧 diff 空 → 取 rc2），可直接应用 |
| S1 libraries-A | `src/libraries/Common/**`、`Microsoft.Bcl.Cryptography/**` 等前半（~16） | 分类子代理：按 §1 规则产出决策表 |
| S2 libraries-B | 其余 `src/libraries/**`（~16） | 同上 |
| S3 运行时类 | coreclr 5 + native 1 + installer 1 + tasks 1 + tests 3 = 11 | 同上（最谨慎，逐 hunk） |

执行模型：
1. 每片起一个**只读分类子代理**（`git show <ref>:<file>`/diff，不改工作树），产出决策表（§4）。
2. 在一个 worktree（`git worktree add /storage/.../runtime-ohos-rc2 -b fix/ohos-rc2 feature/openharmony`
   → `git merge upstream/release/11.0-rc2`）里按决策表**一次性应用**（S0 先行，S1–S3 按表）。
3. `git diff --name-only --diff-filter=U` 归零 + `git diff --check` 干净 → 提交 merge。

## 3. 验证与落地

- 提交后：`git push origin fix/ohos-rc2`；dispatch（upload_release=false，workflow 取自 feature）：
  ```sh
  gh workflow run ohos-full-build.yml -R springmin/sdk-ohos --ref feature/openharmony \
    -f runtime_ref=fix/ohos-rc2 -f aspnetcore_ref=fix/ohos-rc2 \
    -f sdk_ref=feature/openharmony -f rid=openharmony-arm64 -f upload_release=false
  ```
  （runtime/aspnetcore 双 rc2 + 现 sdk；首次冷启动 ~58min，失败按 `--log-failed` 迭代）
- 全绿后按评估文档 §4 推进 pin 组（`RT_VERSION`、bootstrap、crossgen2、参考包/host/AOT 包重发），
  再设备 smoke（本仓已具备：发布版 SDK + 设备脚本）。

### 落地检查单（评估文档 item 8）
1. 首个 rc2 发布轮通过后：重取并刷新 `SDK/RUNTIME_TARBALL_SHA256`（`versions.env`）。
2. workload bundle 随 runtime pack 线重打 → 刷 `WORKLOAD_BUNDLE_VERSION/_SHA256`（**与 kit 会话协调**，
   避免 tester 轮期间移动 bundle）。
3. kit 侧：下一个 kit 轮携带新 runtime 线（必要时重发 `device-test-kit` 资产与 SHA256SUMS）。
4. 文档：本页 + 评估文档 + 交接页回填落地 SHA/日期；`ridgraph-sync.yml` 的 `sdk_ohos_ref` 随 sdk tip 刷新。
5. 设备：从新锚重装 SDK（`install-dotnet-ohos.sh` 本地包 + `TARBALL_SHA256`；
   注意 OHOS 对已签名文件不可覆盖——务必装到**新目录**；签名工具按需用 SDK 自带 `binary-sign-tool`
   或 selfsign，见 2026-09-28 实操）。

## 4. 决策表模板（分类子代理输出）

```
file | category | rc2-delta(sum) | ours-delta(sum) | decision(take-rc2/take-ours/merge) | hunks/notes
```

## 5. 冲突文件全量清单（67）

见本次 dry-run 产物 `/data/storage/el2/base/tmp/opencode/rc2eval-conflicts.txt`（67 行）。分类计数：
`src/libraries` 32、`eng/pipelines` 19、`src/coreclr` 5、`src/tests` 3、`src/tasks` 1、
`src/native` 1（`minipal/thread.c`）、`src/installer` 1、`eng/common` 1、`global.json`、
`eng/Version.Details.{xml,props}`、`.config/dotnet-tools.json`。
