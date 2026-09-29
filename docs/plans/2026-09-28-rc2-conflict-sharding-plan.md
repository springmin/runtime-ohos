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
| 迭代 4 | run **36402804291**（~40min 失败，推进更远）。修复 3 机械生效（日志：`bootstrap Ref pack 11.0.0-rc.2.26465.108 ready (dnceng)` + `seeded ... from SDK Ref (rc.2.26465.108)`），但库构建仍报 CS0234/CS0246：**rc2 源码声明的新平台 API（`CompositeMLKem*`、`Hpke*`）连官方 rc2 Ref pack 都还没有**（pack 构建 26465.108 早于这些声明；本机对 pack 内 `System.Security.Cryptography.dll` 做过字符串核验：`MLKem` 在、`CompositeMLKem`/`Hpke` 不在），而 clean bootstrap-layout 构建的库编译用的是 **seed 的 pack**，不是 **in-tree refs**（`X509CertificateKeyAccessors.cs` +150 与 Pkcs ref +29 都是 rc2 独有、ours 无对应）。修复 4（sdk `13d01d70bd`）：新增第三个自愈 `refresh_bootstrap_ref_from_local()` —— 命中 `CS0234/CS0246 + CompositeMLKem/Hpke` 时，把 `artifacts/bin/<lib>/ref/Release/<tfm>/*.dll` 覆盖进 bootstrap ref 目录后重试（seed 本就是"local packs overwrite it"的占位；沙箱已验覆盖行为） |
| 迭代 5 | run **36407542420**（35min 失败）。自愈**已触发**（attempt 3/4：`refreshed bootstrap ref assemblies from in-tree ref outputs (181 file(s))`），但错误持续——因为 clean bootstrap-layout 构建的库编译从 **Ref pack 目录**（`.dotnet/packs/Microsoft.NETCore.App.Ref/<ver>/ref`）解析平台程序集，而不是 bootstrap layout 目录。修复 5（sdk `021fa55c31`，rebase 于并发会话的 kit #32 锚提交之上）：`refresh_bootstrap_ref_from_local()` 把 in-tree ref 输出复制到 **bootstrap layout + 每一个现存 `.dotnet/packs/Microsoft.NETCore.App.Ref/*/ref`**（沙箱验证三处全部刷新） |
| 迭代 6 | run **36411806642**（~42min 失败）。修复 5 生效（6 个位置共 1086 次拷贝：bootstrap layout + 5 个 pack 版本目录），但 CS0234/CS0246 依旧——因为 **pack 解析下没有任何东西会促使构建产出 in-tree 的 S.C.Crypto ref**（Bcl 的依赖由 pack 满足），拷贝清单里根本没有它的新 ref。修复 6（sdk `06585cc9f4`）：自愈分支先 **预构建 `src/libraries/System.Security.Cryptography/ref`**（参数对齐 shim 预构建）再刷新拷贝 |
| 迭代 7 | run **36416698093**（~38min 失败）。预构建**成功**（"S.C.Crypto ref built"）、6 位置 1086 拷贝也执行，但同族错误仍在（条件再次命中 → attempt 4 → die）。修复 7（sdk `8883b8c857`，rebase 前 `62ef87de0b`）：① 刷新列表补充**本地组装 ref 包**（`artifacts/bin/microsoft.netcore.app.ref/ref/<tfm>`）与 **NuGet 还原位置**（`~/.nuget/packages/microsoft.netcore.app.ref/*/ref/<tfm>`）；② 增**诊断**：自愈时打印 in-tree/bootstrap 副本是否含 rc2 类型，失败诊断里跑 Bcl 项目的 diag 构建抓出 csc 实际解析的 `System.Security.Cryptography.dll` 路径 |
| 迭代 8 | run **36422132286**（~30min 失败）。修复 7 生效：诊断确认 **in-tree 与 bootstrap 副本都已含 rc2 类型**（`in-tree S.C.Crypto ref has the rc2 types` / `bootstrap ref copy has the rc2 types`）；本地组装 ref 包与 NuGet 位置也已刷新（1151 拷贝，且本地组装目录与各库 ref 输出是**硬链接**）。但同族错误仍在 → 编译解析的仍是**另一处未被覆盖的位置**（且自愈在 attempt 4 直接 die，我加的失败诊断未跑到）。修复 8（sdk `a78836a56d`）：把**错误行 + Bcl 项目 `-v:diag` 的引用路径抓取**移到 die 之前打印（诊断轮） |
| 迭代 9 | run **36426383897**（诊断轮，~38min 失败）——**拿到确凿根因**：Bcl 项目的 diag 构建显示实际读取路径为 `artifacts/bootstrap/<rid>/microsoft.netcore.app/ref/**ref/net11.0**/System.Security.Cryptography.dll`（`TargetingPackPath` 属性 = `.dotnet/packs/.../11.0.0-rc.1.26425.128` + SDK 追加 `ref/<tfm>`），而修复 5–7 的刷新把 dll 复制到了**裸 `ref/` 目录（浅了一层，没有 `<tfm>` 子目录）**——编译始终读的是 seed 的官方 rc2 pack（本身缺新类型）→ 迭代 4–9 的拷贝全部落在编译器不看的路径上。修复 9（sdk `05ce9ea978`）：刷新目标改为 `<ref-root>/<tfm>/`（bootstrap layout 的 `.../ref/ref/<tfm>`、各 `.dotnet/packs/.../ref/<tfm>`、本地组装包 `.../ref/<tfm>`、NuGet `.../ref/<tfm>`），沙箱验证四处全部命中 |
| 迭代 10 | run **36431074316**（~37min 失败）——深度修复**生效**（库构建全过、ILCompiler/Crossgen2 包已产出），新失败在 **`Microsoft.NETCore.App.Ref.sfxproj` 的共享框架校验**：`illink` 缺 `Mono.Cecil`、`System.Windows.Extensions` 缺 `System.Drawing.Common`——刷新把**全部 181 个 in-tree ref（含非平台库）注入平台 pack**，校验器看到"外来程序集"。修复 10（sdk `589ecfa33f`）：**只替换目标目录已存在的同名文件**（不新增），沙箱确认 `illink` 不再进入 |
| 迭代 11 | run **36436950564**（~23min 失败）。修复 10 生效（进入 packs 后续），新失败：合并树 `PreReleaseVersionIteration=**2**`（take-rc2）→ 产物版本为 **`11.0.0-rc.2.26451.109`**（脚本从产出的 packs 正确推导 ✓），重定版 host pack 也**成功**，但随后 `verify_host_pack_cache` 因**无锚摘要**（buildid 派生版本无法预 pin）把重定版产物**丢弃**→ 下载同样被拒 → in-build 工具缺 host pack。修复 11（sdk `f1b86dcd8a`）：接受带 `.nupkg.metadata {"source":"local"}` 标记的缓存（该标记仅在来源包通过摘要校验后由重定版步骤写入），其余无 pin 情形仍拒绝（沙箱 A 接受 / B、C 拒绝） |
| 迭代 12 | run **36441342069**（~37min 失败，**里程碑**）：修复 11 生效，**runtime 阶段完整通过**（`framework R2R: compiled=180 failed=0`、runtime tarball/pack 均产出）；失败前进到 **aspnetcore 阶段**：`Microsoft.AspNetCore.App.Runtime.sfxproj` NU1102——找不到 `Microsoft.NETCore.App.Runtime.linux-musl-arm64 (= 11.0.0-rc.2.26451.109)`（= stage 1 自产物推导的 **runtime 产物版本**；feed 只有 ref 版本 rc.2.26465.108、dnceng 最近 .112）。修复 12（sdk `28bc1e6f28`）：`stage3()` 进入前用**新产出的 runtime pack**（`artifacts/packages/<cfg>/Shipping/Microsoft.NETCore.App.Runtime.<rid>.<ver>.nupkg`）为**产物版本**补 musl 别名（nuget 缓存 + feed + packs 布局，幂等；沙箱覆盖首跑/幂等/三处产物） |
| 迭代 13 | run **36449981910**（~47min 失败，**再次推进**）：修复 12 生效，**runtime + aspnetcore 阶段全部通过**（markers 显示 `aspnetcore R2R: no App.Runtime pack found - skipped` 为预期分支），失败前进到 **SDK 构建（stage 4）**：`NU1102 Microsoft.NETCore.App.Runtime.win-x86 (= 11.0.0-rc.2.26451.109)` 与 `NU1603 Microsoft.NET.ILLink.Tasks`——**产品版本 `...26451.109` 与上游 rc.2 flight `...26451.112` 只差 revision**（`BUILDID=20260901.109` vs 上游 `.112`）；dnceng 已验证 `.112` 的 win-x86/ILLink/linux-x64 全部存在（`.109` 404）。 |
| 迭代 14 | run **36455830206** **✅ 全绿（43m18s）— rc2 双仓验证首次完整通过**。产物 `dotnet-sdk-11.0.100-rc.2.26451.112-openharmony-arm64.tar.gz`（180,478,544 B，版本与上游 rc.2 flight 对齐）；`framework R2R: compiled=180 failed=0` + pack/tarball overlay；`msbuild-pipe-patch: patched=16 noop=0 skipped=0 tarballs=1`；`sign: 27 ELF`；`verify: ... no dotnet-aot native library`；工作流产物 `ohos-build-openharmony-arm64-36455830206`（515 MB）。**落地前待办**：热路径确认（同 refs/buildid 再派）、pin 组（`versions.env` `SDK_VERSION`/`DEFAULT_BUILDID` → `.112`；`RT_VERSION`=rc.1 参考基线保持；AOT 包与锚点随发布刷新）、首轮发布（`upload_release=true`）、workload bundle 重打（协调 kit）、设备重装 |
| 迭代 15 | run **36461099649**（热路径确认，**11m1s ✅**）：`stage caches: runtime=true aspnetcore=true`、两级缓存以 rc2 线键恢复（runtime `d4a4e25c89f`/aspnetcore `e10d030184`/suffix `a376ca73…`）、SDK 产物重现。**冷 43m18s → 热 11m1s**；item 2 的热路径验证同时闭环。注意：两次运行的 tarball 大小略有差异（180,478,544 vs 180,476,198 B，打包非确定性）——**发布锚点必须取发布资产自身的 sha**，不能用任一次 CI 运行的值 |
| 发布（①） | run **36504623184** ✅（11m58s，缓存命中；`upload_release=true`）：三仓 release 发布——runtime-ohos `v11.0.0-rc.2.26451.112-ohos`（20 资产，含 runtime tar 35,055,587 B + runtime pack 39,778,421 B + AOT/Crossgen2/host packs）、aspnetcore-ohos 同名、sdk-ohos `v11.0.100-rc.2.26451.112-ohos`（11 资产，SDK tar 180,476,414 B；含 SHA256SUMS） |
| 锚点/pin（②） | sdk `02809efa26` + `18c55a2a28`（feature）：`RT_VERSION`/`SDK_VERSION` → `11.0.0-rc.2.26451.112`/`11.0.100-rc.2.26451.112`；`SDK_TARBALL_SHA256=668b5d5b…`、`RUNTIME_TARBALL_SHA256=5783ef3f…`（**两者均按新发布资产重新下载实测一致** ✓）；`DEFAULT_BUILDID` 保持 `.109`（rc.1 线安全）+ 注释（rc.2 派发显式带 `buildid=20260901.112`）；BUILD-GUIDE 示例同步。遗留：`selfsign-ohos-arm64` 未被当前管线产出（安装器**非致命**回退 `binary-sign-tool`，与设备现状一致）；`REFERENCE_RUNTIME_PACK_*` 保持 rc.1（rc.2 R2R-PGO 参考包待生成） |
| ③ 待办（等 kit 空档） | workload bundle 重打（协调 kit）、设备重装 + 冒烟（rc.2 线：`SDK_VERSION=.112` 安装路径）、设备 AOT pin（`fetch-nativeaot-packs.sh` → `.112`）、文档回填。**另发现（低优先，不影响产物）**：发布资产的 `productCommit-openharmony-arm64.txt` 记录的是 sdk 仓声明的上游依赖（`11.0.0-rc.1.26453.118` / `3c8d132bfb`），而不是 fork 构建的 runtime/aspnetcore（`d4a4e25c89f`/`e10d030184`，`11.0.0-rc.2.26451.112`）——可在 SDK pin 重写步骤补 productCommit 元数据 |
| selfsign 管线（①② 追加） | 见下方 §8 记录；另两笔待办：①**host pack 摘要加固**（`host-runtime-packs` release 无 SHA256SUMS，github 版 host pack 的锚依赖 API/瞬时网络——run 36517651718 即因此误拒 `26431.109`；应从 API 摘要补 pin 表：`26431.109`→`446adf8b…`、`26451.109`→`e9d57abe…`，并让 `host_pack_expected_sha256` 优先查 pin）；②**runtime 侧 linux-x64 host ilc 包内容形态**（`runtime.linux-x64.Microsoft.DotNet.ILCompiler` 内 `tools/ilc` 为 aarch64）：探因见 §8——fork 的 `ILCompiler_publish` 按 `$(PortableOS)-$(TargetArchitecture)`（OHOS aarch64）发布，`assemble-ilc-pack.py`（"round-9/16 split-layout，仅此形态设备启动 PASS"）即用该产物组装**设备侧** ilc 包；故该形态是 fork 构型的**有意结果（设备向）**，非简单错标。CI 跨发布改用官方 x64 host ilc（已绕开）；若将来需要真正的 x64 host 包，应另行装配合适产物 |

## 8. selfsign-ohos-arm64 管线补产出（2026-09-29）

目标：把 `selfsign-ohos-arm64`（设备端签名工具，安装器的 `SELFSIGN_ASSET`）重新纳入 sdk release（当前管线只产 `selfsign-linux-x64`，设备安装回退 `binary-sign-tool`）。

**实现**（sdk feature）：
- `eng/ohos-install/Directory.Build.targets`：仅当 `PublishAot=true` 且 RID 为 `openharmony-*` 时，把 RID 追加进 `KnownILCompilerPack.ILCompilerRuntimeIdentifiers` + `KnownRuntimePack.RuntimePackRuntimeIdentifiers`（`%(...)` 自引用；曾因 `$(...)` 属性语法覆盖列表而触发 NETSDK1204），并把 `ILCompilerPackVersion` 钉到 `RuntimeFrameworkVersion`；
- `pack-sdk.sh` 的 `stage_selfsign_release_assets()`：`selfsign-linux-x64`（复用 `ensure_selfsign`）+ `selfsign-ohos-arm64`（NativeAOT 跨发布：RID 图→标准名临时目录、过滤 feed 排除错标的 host ilc 包、静态 OpenSSL LinkerArg 注入、`CompressSymbols=false`）→ 落 sdk Shipping 随 release 上传；暂为 warn-and-continue（验证后翻严格）。

**已通过的迭代**（热/冷交替，构建保持绿）：图路径（`59984c29ba`）→ RID 列表追加（`58d43f9187`）→ host ilc 过滤（`c40767432f`）→ 静态 OpenSSL（`67981c60d7`）→ **产出成功**（run 36517927659：`5,880,568 B / 8d4f0ee6…`）→ **严格化**（`0445fd0429`，发布失败即红灯）→ **发布重跑**（run 36518982917，11m31s）：`selfsign-linux-x64`（1,464,224 B / `e05cb1db…`）+ `selfsign-ohos-arm64`（5,880,568 B / **`24b8aff1…`**）进 `v11.0.100-rc.2.26451.112-ohos`；selfsign 已**下载实测**（sha 一致 + ELF aarch64 ✓）。注：AOT 链接/打包非确定 → 每次发布重跑后 `SELFSIGN_SHA256`、`SDK_TARBALL_SHA256`、`RUNTIME_TARBALL_SHA256` 三锚都需重测（本轮已重锚，见 §9）。

**设备首装发现（on-device，2026-09-29）**：发布资产的 `selfsign-ohos-arm64` 带 **CI 自动签名块**（SDK 的 `OpenHarmonyCodesign` 对构建产物自动签名 ✓），但**设备拒绝该块**（exec → EPERM），而安装器只对**无 `.codesign`** 的签名器做自举 → 预置/下载的 selfsign 均不可执行 → 首装全部签名失败（29/29）。修复与验证：
- **管线**（sdk `3827516b24`）：`stage_selfsign_release_assets` 在落盘前用 NDK `llvm-objcopy --remove-section .codesign` **剥离**该块（发布**未签名**资产，安装器首次使用时用设备 `binary-sign-tool` 自举 ✓）；失败仅告警。
- **当前发布**：以剥离版替换 release 资产（5,874,376 B / **`8e99c091…`**）+ 更新 release `SHA256SUMS` 条目；`SELFSIGN_SHA256` 重锚（`25eb49a698`）。**注意**：release 资产核验用 API/`gh release download`（直接 curl 同 URL 会命中 CDN 旧缓存 ✗——本轮踩过）。
- **设备工具**：可用 `binary-sign-tool` = `~/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_2/bin/`（`c7d6575d…`）；`~/.harmonybrew/bin` 的 shim（`725ca9b4…`）有 bug（安装器探测顺序会命中它 ✗）→ 安装时 `PATH` 前置 Cellar 目录 ✓；实测该工具**可覆盖** CI 块（普通 ELF ✓），strip+重签后的 selfsign **可执行** ✓。
- **遗留加固**：安装器 `download()` 无 gh-proxy 回退（设备直连 GitHub ~40KB/s 且无总超时 → 自举前的 selfsign 下载长时间挂起）→ 建议同 `ohos-ci-env.sh` 加镜像回退；`BINARY_SIGN_TOOL_SHA256` 建议 pin 可用工具。

## 9. ③ 设备/捆绑落地清单（rc.2 线，等 kit 空档）

**前置**：kit/tester 无进行中的轮次（不移动 workload bundle）；本清单的所有 pin 素材已备。

| 步骤 | 内容 | 素材/命令 |
|---|---|---|
| 1 | **selfsign 收尾**：selfsign 管线通过后 → 翻"必须成功"（`stage_selfsign_release_assets` 的 warn 分支改 die）→ 热跑一次 `upload_release=true` 发布 `selfsign-linux-x64`/`selfsign-ohos-arm64` 到 `v11.0.100-rc.2.26451.112-ohos` | run 命令同前（`buildid=20260901.112`） |
| 2 | **pin 批次**（一次冷跑）：`fix/host-pack-pins`（`c8e4d516b5`，host pack 摘要加固：`26431.109`→`446adf8b…`、`26451.109`→`e9d57abe…`）＋ AOT pin（`fetch-nativeaot-packs.sh`/`aot_pack_sha256` → rc.2：OHOS 两包摘要 `ce5cfbe0…`（NativeAOT）/`2bb27f0e…`（ILCompiler）；官方 fallback `@.112` 在 dnceng 均可用）＋ `SELFSIGN_SHA256`（取发布资产实测） | 合并到 feature 后跑一次冷验证 | **已执行（锚+host pin）**：feature `e114268339`（锚 `c90f758e…`/`1e068b05…`/`24b8aff1…` + host pin 表合并）；冷验证 run **36520418811**（构建前步骤即验证 pin 路径）。**AOT 镜像发布（`aot-packs-11.0.0-rc.2`：2 fork OHOS 包 + 3 官方 fallback + SHA256SUMS）仍待做**（摘要已备，建议 ③ 窗口在网络稳定时执行） |
| 3 | **workload bundle 重打**（协调 kit 会话）：更新 `WORKLOAD_BUNDLE_VERSION`/`WORKLOAD_BUNDLE_SHA256`，发布 `openharmony-workload-*.tar.gz` | kit 窗口 | **已完成**（窗口开放后，两个版本）：<br>**`.25`**：manifest 双 band → `1.0.0-preview.25`（runtime pack `11.0.0-rc.2.26451.112`）；bundle = `openharmony-workload-1.0.0-preview.25.tar.gz`（71,627,760 B / `c15c8e6c…`）→ 发布 `workload-1.0.0-preview.25` + `workload-latest` + **attach 到 SDK release**；sdk pin 更新 `eb767a207a`；ohos-workload 提交 `f9af1e9`。<br>**`.26`（修 `.25` 缺陷）**：设备冒烟发现 workload-TFM restore 解析到 **`.24`**（`Microsoft.OpenHarmony.Sdk` pack 的 `targets/OpenHarmony.PlatformItems.targets` **硬编码**了 `1.0.0-preview.24`+`11.0.0-rc.1.26425.128`——`.24→.25` 目录复制未更新 ✗）→ 修正三处版本值并自增到 **`.26`**（全 pack + 双 band manifest + `prepare-packs.sh`/README）→ bundle `openharmony-workload-1.0.0-preview.26.tar.gz`（72,058,902 B / `724a4f48…`）→ 发布 `workload-1.0.0-preview.26` + `workload-latest` + attach；sdk pin `5b7254ce73`；ohos-workload 提交 `1d009ff`。注：本机 `dotnet build`（Ref/Hosting/Maui/Tasks）挂起问题仍以目录复制+手动解包绕过（**待修**） |
| 4 | **设备重装**：新目录安装发布 rc.2 SDK（tar sha `c90f758e…` 已锚），安装期签名用 **OHOS SDK `binary-sign-tool`**（既定）；selfsign 资产发布后验证安装器**自动下载 + 自举签名**路径 | 设备 | **进行中**：三件（SDK 172.1MB / bundle 68.3MB / selfsign 5.6MB）经 **gh-proxy** 预取 + 摘要校验 ✓（本机直连/8899 代理仅 ~40KB/s，gh-proxy ~5MB/s——已记录）；首跑因本地 tar 的 fail-closed 校验（需 `TARBALL_SHA256`/sidecar）停在安装前（按设计）→ 带 pin 重跑，目录 `~/.dotnet.rc2-112`，selfsign 预置（安装器自举签名） |
| 5 | **设备冒烟**：`dotnet --info`（RID/版本 `11.0.100-rc.2.26451.112`）、tiny 构建 + 自包含 publish、真机运行（写文件）、`dotnet workload list` | 设备 | **已完成 ✓**（`~/.dotnet.rc2-112`）：`dotnet --info` → `11.0.100-rc.2.26451.112` / RID `openharmony-arm64` ✓；workload `openharmony 1.0.0-preview.26/11.0.100-rc.2` ✓；workload-TFM（`net11.0-openharmony20.0`）**build+publish ✓**（publish 需 `-p:DisableTransitiveFrameworkReferenceDownloads=true` 跳过 AspNetCore 传递 pack ✗），runtimeconfig = `Microsoft.NETCore.App 11.0.0-rc.2.26451.112` + `Microsoft.OpenHarmony 1.0.0-preview.26` ✓；**真机运行 rc=0**，输出 `hello rc2 11.0.0` ✓。安装签名用可用 `binary-sign-tool`（selfsign 已撤下 ✓）；publish 产物无 apphost（OHOS 形态：以 SDK muxer + `*.dll` 启动 ✓） |
| 6 | **文档回填**：本计划 §7 记录设备结果、锚点/版本表更新 | runtime docs |

**备查（并行已备）**：host pack 加固 = 分支 `fix/host-pack-pins`（`c8e4d516b5`，含 `host_pack_sha256()` 表 + `host_pack_expected_sha256` 优先查 pin）；rc.2 AOT 资产摘要（API）＝ `Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.2.26451.112`→`ce5cfbe0…`、`runtime.openharmony-arm64.Microsoft.DotNet.ILCompiler.11.0.0-rc.2.26451.112`→`2bb27f0e…`；发布自产出摘要（API）＝ meta `80ccb91e…`、`runtime.linux-x64…ILCompiler`（错标包）`123efb21…`。

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
