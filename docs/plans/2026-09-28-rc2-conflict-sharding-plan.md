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

## 6. 执行记录（2026-09-28）

| 项 | 值 |
|---|---|
| aspnetcore 影子分支 | `fix/ohos-rc2` = `e10d030184`（4 文件取 rc2；归一化对比证明除版本号外仅一处上游重命名，且自闭环） |
| runtime 影子分支 | `fix/ohos-rc2` = `d4a4e25c89f`（merge 于 feature `856b8047159`，已推送） |
| 分类产物 | 4 张决策表（`s0–s3.md`）+ `apply-list.tsv`：67/67 覆盖 = 42 take-rc2 / 21 take-ours / 4 merge |
| 自动应用 | 63 文件（applier 输出 `applied=63 merge=4 no-decision=0 table-not-unmerged=0`） |
| merge 项 | `gentree.cpp`（theirs 变体 = ours+3 个主线修复，逐字节重放验证）、`Crossgen2.props`（并集）、`Regression_ro_2.csproj`（ours + `Runtime_133550` 条目）、`SCG.csproj`（theirs + 在 `Interop.AsymmetricEncryption.Types.cs` 后插回 ours-only 的 `Interop.BCrypt.Types.cs`） |
| 跨文件修正 | `ReadyToRunTypeMapManager.cs` 保留 ours（见 §7） |
| 校验 | `--diff-filter=U`=0、`git diff --check` 干净、take-ours==HEAD / take-rc2==theirs（抽样逐字节）、`gentree.cpp`==`s3/resolved/gentree.cpp.resolved` |
| CI 验证 | 双仓 ref 派发 run **36392095576**（`upload_release=false`；runtime+aspnetcore=`fix/ohos-rc2`，sdk=`feature/openharmony`） |
| 迭代 1 | run 36392095576 **失败**（23m48s，runtime 构建 XCROSS ILC publish）：`NETSDK1112: The runtime pack for Microsoft.NETCore.App.Runtime.linux-musl-arm64 was not downloaded`。根因：取 rc2 的 `eng/Version.Details.props` 后 `MicrosoftNETCoreAppRefPackageVersion` 由 `rc.1.26431.109` → **`rc.2.26465.108`**，而 musl alias seed 列表（`VERSION_BAND`/`BOOTSTRAP_RUNTIME_VERSION`/`HOST_PACK_BRANCH_VERSION`/`RT_VERSION`，全 rc.1 pin）不覆盖它（pre-merge 的 26431.109 恰在列表里，故此前不炸）。修复：`build-ohos-all.sh` 的 `seed_musl_runtime_pack_alias_from_release()` 从 runtime/aspnetcore checkout 的 `Version.Details.props` **动态解析该属性**并入 seed 列表（幂等，随 band 前进自动生效）——sdk commit `55473eec99` |
| 迭代 2 | run **36394814751**（23m25s 失败，同款 NETSDK1112）。修复 1 实际生效（日志确认 seed 了 6 个版本，含 `rc.2.26465.108`/`rc.2.26473.112`），但仍缺一个版本：**各仓 `global.json` 的 bootstrap SDK 内置运行时版本**——rc2 合并同时取了 rc2 的 `global.json`（S0 take-rc2），SDK pin 由 `11.0.100-rc.1.26420.103` → **`11.0.100-rc.1.26425.128`**；自包含的 in-build 工具发布（`ILCompiler_publish`/`ILCompiler_inbuild`）按该 SDK 的内置运行时版本解析目标 RID pack，而 26420.103 恰好由 `BOOTSTRAP_RUNTIME_VERSION` 覆盖、26425.128 没有（pre-merge 因此不炸）。修复 2（sdk `d8b05d86de`）：从 runtime/aspnetcore 的 `global.json` 推导 `11.0.0-<rest>` 加入别名 seed 列表（幂等），并在 NETSDK1112 诊断中打印 `linux-musl-arm64` 别名缓存 |
| 迭代 3 | run **36398500043**（25m40s 失败）。修复 2 生效（musl 别名 8 个版本齐、NETSDK1112 消失），新失败点：**libraries 构建** `Microsoft.Bcl.Cryptography.Forwards.cs`（S1 take-rc2）转发 rc2 新增平台类型 `Hpke*`/`CompositeMLKemCng`，而 bootstrap **Ref pack 仍是 rc.1**（`seed_bootstrap_ref()` 从现有 packs 挑到 rc.1），8× CS0234。根因：合并后的源码 pin `MicrosoftNETCoreAppRefPackageVersion=11.0.0-rc.2.26465.108`，bootstrap targeting pack 必须同步。修复 3（sdk `97e66f93ea`）：新增 `ensure_bootstrap_ref_pack()` —— 从 runtime checkout 解析该版本，缺失时自 **dnceng public dotnet11 feed** 拉取 `Microsoft.NETCore.App.Ref`（sha256 已 pin 入 `versions.env` 的 `dnceng_ref_pack_sha256()`）并解到 bootstrap packs；`seed_bootstrap_ref()` 优先选它。本机验证：pin 查询/解析/提取布局/`bash -n` 全过 |
| 迭代 4 | run **36402804291**（冷启动，预期 ~58min）|

产物索引：`/data/storage/el2/base/tmp/opencode/rc2-decisions/{s0,s1,s2,s3}.md`、`apply-list.tsv`、
`apply.py`、S3 resolved 文件 `.../s3/resolved/`。

## 7. R2R 类型映射簇判定记录（#133038 vs #132984）

`ReadyToRunTypeMapManager.cs` **不在** 67 冲突表内：rc2 改了它（+119/−2），fork 没改
（`base..ours` 为空），git 会**静默取 rc2 版本**——但 rc2 的 manager 调 **5 参** node 主构造
（rc2 给 node 主构造新增 `bool requiresRuntimeProcessing`），而 ours 的 node 是 4 参 +
`ReadyToRunTypeMapEncoding`（序列化类型名）机制，两侧不兼容 → CS1729/CS1061。
合并后执行：`git checkout HEAD -- src/coreclr/tools/aot/ILCompiler.ReadyToRun/Compiler/ReadyToRunTypeMapManager.cs`。

**为什么不是"把 node 升到上游版本、整簇以上游为准"：**

- ours = 主线正式修复 **#133038**；rc2 = release-only 权宜 **#132984**（rc2 自己的提交信息写明
  "正式修复是 #133038"）。本簇的 take-ours 是"升级方向"，不是回避。
- #133038 不止两个 node 文件：合并树中 `ReadyToRunTypeMapEncoding` 出现在 **4 个文件**；
  整簇取 rc2 需连同 `TypeMapMetadata`/`ExternalTypeMapEntry` 等消费方一起回退，
  否则就是本静默冲突的镜像版（rc2 node/manager 与 ours 元数据形状互斥）。
- 本 fork 是**主线基线**（11 带 + A 合并 main 尾部），rc2 合并本质是"回移并集"；
  整簇取 rc2 = 主动降级，且下次合 main 会再次冲突。
- 自洽性核验（合并树）：`requiresRuntimeProcessing` 出现 **0 次**、
  `ReadyToRunTypeMapEncoding` 4 文件在位、manager 为 4 参调用（与 ours node 配对）。

若将来线切换为**严格跟踪 release 分支**（不带 main 演进），才适合"整簇以上游为准"；
届时应单独影子分支实验（回退 #133038 机制），不动 `fix/ohos-rc2`。
