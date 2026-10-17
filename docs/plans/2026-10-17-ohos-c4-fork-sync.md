# C4 fork sync — 上游 main `d80abfc4b04`（2026-10-17）

> 目的：把 10-15～10-17 的上游变更（含 shared-memory 重设计 **#135778**）并入 fork，
> 并按 jkotas 定案（#132827 收摊）**删除 fork 的 TMPDIR 适配**。

## 1. 合并

- **合并提交**：`139ca635690`（`feature/openharmony`，已推；第一父 `f7d1b0add9d`＝10-16/17 文档线，第二父 `d80abfc4b04`）。
- **冲突**：**1 个真冲突**——`src/coreclr/clrfeatures.cmake`：N1（#135808）已上游化（含 jkotas 简化注释）→ **整取上游**。
- **按定案删除旧适配**（整取上游）：
  - `src/libraries/System.Private.CoreLib/src/System/IO/SharedMemoryManager.Unix.cs`——撤 `#if TARGET_OPENHARMONY` TMPDIR 分支；
  - `src/libraries/System.Threading/tests/MutexTests.cs`——撤 `GlobalSharedMemoryDirectory` 镜像推导。
  - 依据：jkotas 21:12Z 判定（默认域已好；全局域在 OHOS 无法真支持，抛异常＝期望行为）。
- `src/libraries/System.Private.CoreLib/src/System/Threading/NamedMutex.Unix.cs`：无残留（#135321 已上游）。
- **对齐核对**：上述三文件对上游 **零差**。

## 2. 净差与 payload

- fork vs 上游：**477 文件 / +44924 −70**（含 `docs/plans/` 全量与 OHOS 补丁）。
- 抽样确认 payload 仍在：`clrconfigvalues.h`（6±）、`threads.cpp`（15+）、`zstd.cmake`（4±）、`pal_process.c`（185+）等。

## 3. 门禁

- **编译级门（C3 Plan-B 配方复用）**：**全绿**（PCH ×2＋coreclr/libs TU ×5，**7/7 RC=0**）；证据 `up-rehearse-c3/sync/gate6b.log`（首跑因 cwd 在仓根 → 构建目录重跑；非代码问题）。
- **设备验收** ⏳：新默认域（`$HOME/.dotnet/Runtime/SharedMemory`）＋ `/storage` uid 映射疑点（findings §7.1）需真机 App 场景实测。
- **链接级门**：仍挂起（沿 C3 结论）。

## 4. 后续

- fire 基准更新：**`d80abfc4b04`**（后续上游若再动，逐支重核）。
- #132827 已 CLOSED；fork 不再携带该适配。
