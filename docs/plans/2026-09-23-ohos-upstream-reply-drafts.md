# 上游评论草稿（3 条有效 + 1 条已作废，英文，可直接粘贴：Draft A–C）· 2026-09-23

> **⚠ 状态：全部「待用户许可，未发送」（ALL DRAFTS UNSENT — awaiting user approval）。**
> **未经用户明确许可，不得在本文件之外发布、粘贴或引用这些文本。**
> 来源：2026-09-23 上游 PR 评审扫描（`pr-rev` 报告第 50 行（③）四条要点）。
> 约束：正文**不含任何 @ 提及**；每条含提交/行号证据 + 请求 reviewer 的具体动作。发布时只复制对应代码块内内容，不要带出本页框架文字。
> 对象：`dotnet/runtime#132953`、`dotnet/runtime#132827`、`dotnet/runtime#132866`（tracking issue）；原 `dotnet/arcade#17608` 草稿已随该 PR 合并作废（见 Draft D）。
> 发送前逐条核对文末「发送前置检查清单」。

---

## Draft A — `dotnet/runtime#132953`（重审 + rerun 说明）

- 状态：**待用户许可，未发送**
- 目标 PR head：`be8e6f6988d`
- 待发增量（2026-09-24 03:00Z 复核）：arcade#17608 已合并（`fff3b6bb`，2026-09-23T18:36Z）；`eng/common` 尚未同步进 runtime main（等待项）；osx-arm64 leg 自 09-21 失败后未 rerun；reviewDecision 仍 REVIEW_REQUIRED、4 条 outdated 未 resolve。

```text
Thanks for the review feedback. The head is now `be8e6f6988d`, and all four code items are addressed:

- `__PortableTargetOS`: the redundant propagation was removed in `8ef4e925163` (`eng/build.sh`). The `openharmony)` branch at `eng/build.sh:314` now only sets `os="openharmony"`, and the remaining `__PortableTargetOS` uses are the pre-existing linux-musl / linux-bionic ones owned by `eng/common/native/init-distro-rid.sh`.
- `ohos` -> `openharmony` in `eng/native/build-commons.sh`: `7ae01d9839c`.
- The overly verbose comment in `eng/native/configureplatform.cmake`: trimmed to a single line in `cece42439a1`.
- RID graph: `runtime.json` has no net change on this branch (`git diff 04a9b1aa8051 be8e6f6988d -- src/libraries/Microsoft.NETCore.Platforms/src/runtime.json` is empty). The additions live in `PortableRuntimeIdentifierGraph.json` (`9e4af17017f`), and the top-level `openharmony` RID now imports `any` as requested (`be8e6f6988d`, `PortableRuntimeIdentifierGraph.json:67-71`).
- The no-op `-ftls-model=global-dynamic` was dropped in the same cleanup (`8ef4e925163`, `eng/native/configurecompiler.cmake`); `-fno-emulated-tls` already gives the global-dynamic model, byte-identical code.

On CI: the only non-Helix red check on this head is `runtime (Build osx-arm64 Debug Libraries_CheckedCoreCLR)`, build 1605552 / log 1864 (https://github.com/dotnet/runtime/runs/106431620645): `FAILED: [code=254] jit/CMakeFiles/clrjit.dir/utils.cpp.o` with `sccache: Compiler killed by signal 11` while compiling `src/coreclr/jit/utils.cpp` -> `utils.cpp.o`. That is a compiler-process crash (SIGSEGV) in a file untouched by this PR, so a rerun should clear it; the leg has not been rerun since it failed on 2026-09-21.

Requested actions:
1. Please rerun the failed osx-arm64 leg (or close/reopen the failed job) so the check goes green.
2. Please resolve the four review threads (`eng/build.sh`, `eng/native/build-commons.sh`, `eng/native/configureplatform.cmake`, `PortableRuntimeIdentifierGraph.json`): the code is addressed on the current head — `runtime.json` has a net-zero change and `PortableRuntimeIdentifierGraph.json:67-71` carries the requested `any` import.
3. A re-approval on `be8e6f6988d` would then be appreciated — the existing approval covers `cece42439a1` only, and the head has changed since.

Note: the `eng/common` OpenHarmony support has merged in dotnet/arcade#17608 (`fff3b6bb`, 2026-09-23T18:36Z) and will flow into main through the next arcade sync; this PR does not vendor any `eng/common` change and is complete without it.
```

---

## Draft B — `dotnet/runtime#132827`（催复评）

- 状态：**待用户许可，未发送**
- 目标 PR head：`6ed2f9ab9a6`

```text
Friendly ping — all review comments are addressed in code, and the threads are still open (outdated):

- Naming: `TargetOpenHarmony` -> `TargetsOpenHarmony` (`4a5ae9e94f9`), `TARGET_OPENHARMONY` in `src/coreclr/gc/unix/numasupport.cpp` (`cc9ccb34d9e`), and the comments now talk about OpenHarmony rather than HarmonyOS (`d8d97fef69d`).
- `OSPlatformName`: `OperatingSystem.cs` reports `OPENHARMONY` and `IsOSPlatform("openharmony")` works; the shared-memory test uses that spelling (`6ed2f9ab9a6`, `src/libraries/System.Private.CoreLib/src/System/OperatingSystem.cs` +2, `src/libraries/System.Threading/tests/MutexTests.cs:1047`).

The failing checks on this head are Helix / Build-Analysis infrastructure checks (Monitor Helix Jobs, Build Analysis/Insights, parent runtime), not code-level legs.

Requested actions:
1. Please take another look at `6ed2f9ab9a6` and resolve the six outdated threads (`numasupport.cpp`, `OperatingSystem.cs` x2, `System.Private.CoreLib.Shared.projitems` x2, `MutexTests.cs`) if the current shape is acceptable.
2. If anything still looks off, a one-line note is enough — I will fold it in immediately.
```

---

## Draft C — `dotnet/runtime#132866`（三问，第三次请求答复）

- 状态：**待用户许可，未发送**
- 说明：这是 tracking issue（不是 PR）；自 09-14 无回应，阻塞 illink/shims 与 N1–N16 提交顺序

```text
This is a third request for guidance on the three open scope questions; the branch queue is prepared and only the answers are missing.

1. `illink` ownership: we have a one-file change (`src/tools/illink/src/ILLink.Tasks/build/Microsoft.NET.ILLink.targets`, +2 lines, branch tip `f8495f47ae3`). Should it be a standalone `tools/` PR, or folded into the NativeAOT PR (the single-file model used for the other NativeAOT changes)?
2. S1c codesign upstream: should the dotnet signing/codesign slice be upstreamed here, or does it belong on the SDK / wrapper side?
3. Granularity: is the one-concern-per-PR split (15 small runtime branches, 1-7 files each) acceptable as planned, or would grouped PRs be preferred?

Context: two of the branches are already public as PRs (dotnet/runtime#132953 at `be8e6f6988d`, dotnet/runtime#132827 at `6ed2f9ab9a6`), and the prepared queue behind them is clean against current `main` (merge-tree check: 18/18 branches clean, including `shims-tfm-cleanup` and `illink-ntlm`).

Requested action: please answer the three questions above so the queue can be unblocked; if you want a different split, I can restructure before opening anything.
```

---

## Draft D — `dotnet/arcade#17608`（已作废）

- **作废（2026-09-24）：** `dotnet/arcade#17608` 已**批准并合并**（`fff3b6bb`，2026-09-24 02:36 +08；head `4975a234c`，分支 `eng-common-openharmony`）。该草稿不再需要，不再有可发送内容。
- 后续：`eng/common` OpenHarmony 支持将随 arcade 同步自动进入各仓；runtime#132953 的跨仓依赖随之解除，可复评/重跑（见 `2026-09-23-ohos-pr-review-compliance.md` §①/§⑥）。

---

## 发送前置检查清单（发送时逐条确认）

1. 用户明确许可发送（当前为未发送）。
2. 已重新 `gh api` 拉取最新评论/评审事件，确认没有他人新回复（发送时重拉；2026-09-24 arcade#17608 已合并，Draft D 已作废）。
3. 未引入任何 @ 提及（本轮已校验）。
4. #132953 的 rerun 若已由他人触发且已绿，把 Draft A 第 1 条改成「rerun 已绿」的完成式再发。
