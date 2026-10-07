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
| A1 | **拆分 `#132827`** ✅ **已完成（10-07）** | jkotas 09-25："The changes in this PR that are **not related to shared mutexes are fine — happy to merge them if they are separated**." | **已开 PR：dotnet/runtime#135321**（"Skip robust mutexes on OpenHarmony" ✗；**仅 `NamedMutex.Unix.cs`，1 文件 +3/−1** ✓，基于全新 main `b08c345c912` ✓）。拆分时修正：`MutexTests.cs` 的 hunk 实为 **shared-memory 目录**（`GlobalSharedMemoryDirectory` ✗）→ **留在 #132827**（与 TMPDIR 改动同族 ✓）；#132827 现在只含 SharedMemoryManager + 测试，保持挂起 ✓。**待办**：在 #132827 留告知评论（草稿已备 ✗，**待许可** ⚠️） |
| A2 | `#132953` 的复看推进：若 10-09/10-10 仍静默 → **请第二 reviewer** | jkoritzinsky 疑似忙于 B1（避免再 ping 他同一时段） | 备选：@jkotas（已批准）或 BuildArea 其他维护者 ⏳ |
| A3 | `#132827` 合并冲突 | akoeplinger 09-24 提示；head `4c3b303419`（09-26 04:10 推送）已修，**本地 merge-tree 与 upstream/main CLEAN** ✓ | 已闭环 ✓，无需动作 |

## 3. 已闭环（复核确认 ✓）

- **#132953**：命名统一（`ohos`→`openharmony`、`TargetsOpenHarmony` 命名法 ✓）、RID 不假装 Linux（不 `#import linux-musl`，改 `any` ✓）、`runtime.json` 冻结文件回退 ✓、verbose 注释精简 ✓、`eng/common`→**arcade #17608 已合并**（09-24）✓、seccomp 口径（jkotas 09-02："This should be done properly"→ 由 NUMA 排除的正式做法承接，`#134670` ✓）。
- **#132827**：命名/模型问题回应 ✓（`TargetsOpenHarmony` ✓、macOS/BSD named-mutex 模型"fine" ✓、`IsOSPlatform("openharmony")` 已在 head 实现 ✓）、合并冲突已修 ✓。

## 4. 结论

- **"其他人的工作"共 3 项**：B1（jkoritzinsky 设计变更，**真阻塞**）、B2（合并队列）、B3（外部答复）。
- **我方最有价值的动作 = A1 拆分 #132827** ✓——它同时解「blocked 对整笔的封锁」与「jkotas 的明确建议」；
  A2 则应避免与 B1 抢同一人的注意力（改请第二 reviewer）。
