# 上游评审通读 — 他人工作与未办项登记（2026-10-07）

> 方法：拉取 `#132953`/`#132827` 的**全部** issue 评论、评审与内联评论（含历史），逐条归类为
> 「我方已闭环 / 我方待办 / 他人工作（等待）」，并对每条给出证据（时间+人+引文）。

## 1. 他人工作（等待项 ⏳）

| # | 谁 | 内容 | 证据 | 影响 |
|---|---|---|---|---|
| B1 | **@jkoritzinsky** | **shared-memory 区域的设计变更**（进行中） | jkotas 09-25 inline `SharedMemoryManager.Unix.cs:418`："I would wait with merging this change. **@jkoritzinsky is working on some design changes in this area** that should address the problem for Harmony as well." | **#132827 `blocked` 标签的根因**；也可能解释他未复看 #132953 ⚠️ |
| B2 | **@akoeplinger** | 合并队列（#132827 批准人） | 09-25 APPROVED 评审；09-24 提出过 `NamedMutex.Unix.cs` 合并冲突（**已修** ✓） | 拆分后 PR-B 的合并人候选 ✓ |
| B3 | 外部 | `#132866` 的 **C2/C3 归属答复** | 我方 09-14 计划更新后无维护者回复（23 天） | C2/C3 开 PR 的前置 ⏳ |

## 2. 我方待办（可行动 ✗）

| # | 事项 | 依据 | 建议 |
|---|---|---|---|
| A1 | **拆分 `#132827`** ✅ **已完成并已合并（10-07）** | jkotas 09-25："The changes in this PR that are **not related to shared mutexes are fine — happy to merge them if they are separated**." | **dotnet/runtime#135321 已 MERGED ✓✓**（`2026-10-07T20:14:53Z` ✗；jkotas 复批后即合 ✗；**从创建到合并 ~18.6 小时** ✗✓；净 diff 2 行 ✗）。拆分时修正：`MutexTests.cs` 的 hunk 实为 **shared-memory 目录**（`GlobalSharedMemoryDirectory` ✗）→ **留在 #132827** ✓；#132827 现在只含 SharedMemoryManager + 测试，保持挂起 ✓（等 B1 设计 ✓）。告知评论 ✓（`#issuecomment-6029025699`）——**A1 完整闭环 ✓✓** |
| A2 | `#132953` 的复看推进：若 10-09/10-10 仍静默 → **请第二 reviewer**（分析见 §5） | **与其"新设计"无内容依赖**（11 文件全为 infra/RID 图 ✗）→ 可由其他维护者独立签核 ✓ | 备选：@jkotas（已批准）或 BuildArea 其他维护者 ⏳ |
| A3 | `#132827` 合并冲突 | akoeplinger 09-24 提示；head `4c3b303419`（09-26 04:10 推送）已修，**本地 merge-tree 与 upstream/main CLEAN** ✓ | 已闭环 ✓，无需动作 |

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
