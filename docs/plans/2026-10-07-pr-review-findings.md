# 上游评审通读 — 他人工作与未办项登记（2026-10-07）

> 方法：拉取 `#132953`/`#132827` 的**全部** issue 评论、评审与内联评论（含历史），逐条归类为
> 「我方已闭环 / 我方待办 / 他人工作（等待）」，并对每条给出证据（时间+人+引文）。

## 1. 他人工作（等待项 ⏳）

| # | 谁 | 内容 | 证据 | 影响 |
|---|---|---|---|---|
| B1 | **@jkoritzinsky** | **shared-memory 区域的设计变更**——✅ **已落地**（2026-10-15：#135778，`5891955bdde`；见 §7） | jkotas 09-25 inline `SharedMemoryManager.Unix.cs:418`："I would wait with merging this change. **@jkoritzinsky is working on some design changes in this area** that should address the problem for Harmony as well." | **#132827 `blocked` 的根因**（设计已落地 → **#132827 待按新设计重画** ⏳，见 §7）；也可能解释他未复看 #132953 ⚠️ |
| B2 | **@akoeplinger** | 合并队列（#132827 批准人） | 09-25 APPROVED 评审；09-24 提出过 `NamedMutex.Unix.cs` 合并冲突（**已修** ✓） | 拆分后 PR-B 的合并人候选 ✓ |
| B3 | 外部 | `#132866` 的 **C2/C3 归属答复** | 我方 09-14 计划更新后无维护者回复（23 天） | C2/C3 开 PR 的前置 ⏳ |

## 2. 我方待办（可行动 ✗）

| # | 事项 | 依据 | 建议 |
|---|---|---|---|
| A1 | **拆分 `#132827`** ✅ **已完成并已合并（10-07）** | jkotas 09-25："The changes in this PR that are **not related to shared mutexes are fine — happy to merge them if they are separated**." | **dotnet/runtime#135321 已 MERGED ✓✓**（`2026-10-07T20:14:53Z` ✗；jkotas 复批后即合 ✗；**从创建到合并 ~18.6 小时** ✗✓；净 diff 2 行 ✗）。拆分时修正：`MutexTests.cs` 的 hunk 实为 **shared-memory 目录**（`GlobalSharedMemoryDirectory` ✗）→ **留在 #132827** ✓；#132827 现在只含 SharedMemoryManager + 测试，保持挂起 ✓（等 B1 设计 ✓）。告知评论 ✓（`#issuecomment-6029025699`）——**A1 完整闭环 ✓✓** |
| A2 | `#132953` 的复看推进 | **与其"新设计"无内容依赖**（11 文件全为 infra/RID 图 ✗）→ 可由其他维护者独立签核 ✓ | **① 已执行（10-09 06:01Z）** ✓：请 @jkotas 复核或路由（`#issuecomment-6075280388` ✗）；**② 已执行（10-14 01:22Z）** ✓：团队路由 @dotnet/area-infrastructure-libraries（3 个 PT 工作日静默后 ✗；`#issuecomment-6158765255`）→ **已见效 ✓✓（10-14 ✗）**：04:15Z jkoritzinsky **APPROVED** ✗；04:21Z jkotas **Update branch**（head `be8e6f6988`→`fb3ff1a99b` ✗）——`reviewDecision=APPROVED`、`MERGEABLE` ✓，CI 重跑后即可合并 → **已 MERGED ✓✓（10-14 13:48:36Z，jkotas squash ✗）**：`14399016e4c` ✓ 已验证在 main（`0232cf718cd` ✗）；合并时 2 个非必需检查（runtime / Helix monitor ✗）未阻 ✓——**C3 正式激活** ⏳（bot findings 两线程回复已随合入归档 ✓） |
| A3 | `#132827` 合并冲突 | akoeplinger 09-24 提示；head `4c3b303419`（09-26 04:10 推送）已修，**本地 merge-tree 与 upstream/main CLEAN** ✓ | 已闭环 ✓，无需动作 |
| A4 | `#132953` 的 copilot 2 条 musl-host findings（bot `[COMMENTED]` ✗，不阻塞合并 ✓）——musl 构建宿主会把 `__PortableTargetOS` 覆盖成 linux-musl ✗ | 修复已在 **arcade#17608**（`fff3b6bbf` ✗，`targetOs=linux` 护栏 ✗＋设备端 non-portable RID ✗），随 runtime 的 eng/common 源更新流到位 ✓ | **已回复两线程**（`05:28Z` ✗：`discussion_r4267114051` / `r4267114298`；引 #17608 ✗）——**不推码** ✓；C3 的 eng/common 同步兜底 ✓ ⏳ |

## 3. 已闭环（复核确认 ✓）

- **#132953**：命名统一（`ohos`→`openharmony`、`TargetsOpenHarmony` 命名法 ✓）、RID 不假装 Linux（不 `#import linux-musl`，改 `any` ✓）、`runtime.json` 冻结文件回退 ✓、verbose 注释精简 ✓、`eng/common`→**arcade #17608 已合并**（09-24）✓、seccomp 口径（jkotas 09-02："This should be done properly"→ 由 NUMA 排除的正式做法承接，`#134670` ✓）。
- **#132827**：命名/模型问题回应 ✓（`TargetsOpenHarmony` ✓、macOS/BSD named-mutex 模型"fine" ✓、`IsOSPlatform("openharmony")` 已在 head 实现 ✓）、合并冲突已修 ✓。

## 4. 结论

- **"其他人的工作"共 3 项**：B1（jkoritzinsky 设计变更，**真阻塞**）、B2（合并队列）、B3（外部答复）。
- **我方最有价值的动作 = A1 拆分 #132827** ✓——它同时解「blocked 对整笔的封锁」与「jkotas 的明确建议」；
  A2 则应避免与 B1 抢同一人的注意力（改请第二 reviewer）。

## 5. 分析：停顿是否与"要求的新设计"有关（2026-10-09）

- **#132827：是，直接相关** ✓。jkotas 09-25 inline："wait with merging this change… **@jkoritzinsky is
  working on some design changes in this area** that should address the problem for Harmony as well" ✗——
  被阻塞的正是 `SharedMemoryManager`（`/tmp→TMPDIR`）部分（NamedMutex 部分已拆出并合并 ✓）。处置：
  parked ✓、不催 ✓。
- **#132953：内容上无关** ✗。11 个文件全部是 infra/构建与 RID 图（`eng/*`、
  `PortableRuntimeIdentifierGraph.json`、`src/native/libs/*` 的 build 面 ✗），**不含 shared-memory/
  mutex 代码** ✓；两 PR 线程全文**从未**出现"等待设计"之类的表述 ✓。
- **#132953 沉默的性质 = 评审路由/注意力** ⚠️：被指派的 jkoritzinsky 近三周在**其它领域**高频提交
  （TypeLoader/ilasm/reflection/GC/interpreter ✗，10-08 仍有 ✓）——"太忙"不成立 ✗；但其**自 09-08 起
  对本 PR 零回复** ✗（30 天；早前批准者是 jkotas ✗）。其 open PR（#135250 "single-threaded thread/
  static machinery" 等 ✗）与线程/静态机制相邻 ⚠️，但**无任何证据**表明 #132953 等待该工作 ✓。
- **结论** ✓：**A2（请第二 reviewer）正当且必要** ✓——#132953 与新设计无依赖、可由其他维护者独立
  签核 ✓；而 **#132827 的剩余部分确需等设计** ✗（继续 parked ✓）——两者处置相反，勿混 ✓。

## 6. 2026-10-15 更新：`/tmp` 自 7.0 起可写 → 删除只读适配

- **设备实证 ✗**：本机 = **`HAD-W24 7.0.0.111(SP10…)`**（≈HarmonyOS/OpenHarmony 7.0 ✗，api 26 ✗）；`/tmp` **可写 ✓**（`touch` 通过 ✗）。
- **处置 ✗**：删除 runtime fork 的 `/tmp` 只读适配（共 2 文件 ✗）：
  - `src/libraries/System.Private.CoreLib/src/System/IO/SharedMemoryManager.Unix.cs`——撤 `#if TARGET_OPENHARMONY → Path.GetTempPath()` 分支 ✗，恢复上游 `return "/tmp/";` ✗；
  - `src/libraries/System.Threading/tests/MutexTests.cs`——撤 `GlobalSharedMemoryDirectory` 的 OHOS 镜像推导 ✗，恢复上游常量 ✗。
- **#132827 影响 ✗**：**已更正（同日 ✗）**——后续发现 `/tmp` **可写但不可锁** ✗（`fcntl.lockf` 无竞争亦 `EACCES` ✗；SQLite `database is locked` 复现 ✗；userdata 锁正常 ✓），而 OHOS 命名互斥走**文件锁路径** ✗（musl 无 robust pthread mutex ✗）→ **底层诉求仍成立 ✓**：**fork 适配已重挂 ✓**（`SharedMemoryManager.Unix.cs` 注释改为锁理由 ✗＋`MutexTests.cs` 复原 ✗；对上游净差 16+/1- ✗）；**#132827 已重开 ✓**（2026-10-15 14:48:09Z ✗；保留 `blocked` 等 B1 ✗）——更正评论（[`#issuecomment-6194806938`](https://github.com/dotnet/runtime/pull/132827#issuecomment-6194806938) ✗）所载证据继续作为设计输入 ✓；重开说明评论已发 ✓（[`#issuecomment-6201780106`](https://github.com/dotnet/runtime/pull/132827#issuecomment-6201780106) ✗）；B1 落地告警保留 ✓。

## 7. 2026-10-15 追加：B1 设计已落地（#135778）

- **事件**：`5891955bdde`（*Fix shared mutex privliges/permissions/defaults to be secure*，#135778，**MERGED 2026-10-15T17:50:01Z**，jkoritzinsky）——即 jkotas 09-25 所指、"should address the problem for Harmony as well" 的 shared-memory 设计。
- **要点**（`SharedMemoryManager.Unix.cs` +415/−247，另 `NamedMutex`/`Mutex`/`MutexTests`＋interop/pal）：
  - **默认改 user-scoped**（`Mutex.UnsafeDefaultMutexScopeGlobal` 开关可回退全局，默认关）；
  - **用户域目录**：Apple＝容器/TMPDIR；**Linux＝`XDG_RUNTIME_DIR`**；**其余（含 OHOS）＝`$HOME/.dotnet/Runtime/SharedMemory` 家目录回退**——OHOS 上为 userdata 型、可锁 ✓；
  - **全局域仍 `/tmp/`**（`InitalizeSharedFilesPath` 未变）→ OHOS 全局域仍落**不可锁**挂载 ⚠️；
  - 路径改 fd/`O_NOFOLLOW`、**禁符号链接**；不再改目录权限（假定正确）；锁文件目录随运行时目录句柄；
  - 我方 `#135321` 存活 ✓（`UsePThreadMutexes` 仍排除 OHOS）。
- **对 #132827**：park 理由（等设计）**已消**；剩余内容（`InitalizeSharedFilesPath` TMPDIR＋MutexTests 镜像）需按新结构 **rebase/重画** ⏳——默认用户域在 OHOS 已可工作 ✓（**待设备验证 HOME 已设** ⚠️），剩余价值主要在**全局域**。
- **对 fork**：`17e5300242d` 重挂的适配与新结构不对齐 ⏳（下次 fork 同步合并时将冲突/需重做）。
- **对 #135863（N5）**：与 #135778 无文件交集 ✓；jkotas 17:38Z 追问"CMake bug 与否"✗——**已实证为 CMake 侧缺项**（`Platform/Linker/` 无任何 `OHOS-*` 键；加载名＝`${CMAKE_EFFECTIVE_SYSTEM_NAME}-${COMPILER_LINKER_ID}[-lang]`），回复草稿已备 ⏳。
