# FIXRR 收口：interp R2R 显式关闭 + 本波提交/门禁/CI（FIXRR-CONSOLIDATE，2026-10-05）

> 本波 = CG2-R2R（`42b9d9b`）· AOT-STARTUP（`8e28a74`/`0dc3329`）· FPS48（`80fcb3b`）· OPT4/MULTIWINDOW-S（`24abb8d`）+ 本修。三仓提示：runtime-ohos `feature/openharmony`、ohos-workload `master`、maui-ohos `feature/openharmony`；均已在 origin（maui 本地旧 remote-tracking ref 已 fetch 修正）。

## 1. interp R2R（FIXRR-R2R，ow `08ccbe8`）

- 宿主 `OhosHostApplyExecMemoryPolicy` 在 mode 3 同置 `DOTNET_ReadyToRun=0`（与 `DOTNET_InterpMode`/`UseGCWriteBarrierCopy` 同点；marker 与 interp.txt 两路共用）；`test_host.c` 回读、本地 aot-smoke 两轮断言（marker=0、mixed=unset）、套件 +1 pin。
- 真机复测（HAD-W32，interp+R2R 件，冷启）：Main→首帧修复宿主 6 次 578–682（均 614）≈ IL 件 595/593/640（609）；去掉该行的对照宿主 569/564/612（582）→ 同档。**该行在本 runtime 为显式防御**：`eeconfig.cpp:479-486` 对 `InterpMode>=2` 已强制 `fReadyToRun=false`、`ReadyToRunInfo::Initialize` 直接返回 NULL；旧 +350 ms 未复现，改归因 AMS/时点噪声（AMS→Main 531–1172 ms 主导；固定宿主 AMS→首帧 1.12–1.38 s，同窗 IL 对照 1.10–1.81 s）。
- 证据 scratch `cg2-r2r/`（labels `cginterp-r2rfix`×6 / `cginterp-r2rctl`×3 / `cginterp-purefix`×3 + 解析/流/重签件）。

## 2. 合并树门禁

- 切片：standalone Release + trim/AOT analyzer **0 error / 0 IL**（73 非 IL 警告）。
- 套件：`[suite] checks=599 total=601 floor=581 assert=True`（declared==printed；grep 599==checks，perf/a11y `within=True`，0 Unhandled；+N 对账 = 597/599 基线 + 本修 +1 = 599/601/581）。
- 像素：headless-render Release `PIXEL ASSERTIONS PASSED`。
- 导出：`OK: all 151 expected exports`（managed 152 declarations/145 EntryPoint；宿主 151 全 plain symbol）。
- 四包+provenance：preview.22/23/24/28 ui abc 375,268 B / `9cd2b4c3…`、headless 24,324 / `798b2477…`；`--check-sources`/`--check-pack-abc` 绿。
- 本地 preflight：仓库门禁 + `sh -n` 绿；markdownlint 因未忽略的本地 `.a11y-build/`（已 gitignore、CI 干净树无）报 20 条，改动 md 单独 lint 0 issue。

## 3. pin / CI / 提交

- 三 workflow pin `d5384d6cc3` → `ed02203bfd`（host-export/interaction/pixel；注释链同步到 MULTIWINDOW-S，套件数 599/601）。
- 提交（`commit-paths.sh`，未强推）：ow `08ccbe8`（host+test+docs）、`a491cda`（pins）；runtime 本文件 + CG2-R2R §3/§4 归因修订。
- CI 5/5（a491cda）：interaction `37281295386`、pixel `37281295388`、host-export `37281295382`、markdownlint `37281295380`、ridgraph `37281295354`。

## 4. 不确定

- 单设备共享桌面；AMS→Main 抖动大 ⇒ “1.0–1.1 s 档”不作单次判据，用 Main→首帧同位比较。
- R2R 件的 +11 MB 文件体积仍在（AMS→Main 或有 ~0.1 s 级差，未分离）；对照宿主相对 shipping 仅缺一行，无隐式规则 runtime 未覆盖。
