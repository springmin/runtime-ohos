# POST-SEC7-LIGHT-MERGE：CUT-KIT + SEC-SCAN-7 修复并入主线（2026-10-08）

> 口径：ow `master` ← `tooling/cut-kit` @ `5baf2bef6294`（**--no-ff** merge `86fb3d4`）· maui `feature/openharmony` ← `sec7-fixes` @ `9aaa3b40f4`（**--no-ff** merge `b914379269`）；普通推送、未强推；**不切 kit**（#54 待 rc.2，触发时经 `cut-kit.sh` 走）；#49–#53 资产零改动；无设备轮、无 kit 构建。

## 1) 合并内容

- ow：仅脚本 4 文件（`scripts/cut-kit.sh` + `selftest-cut-kit.sh` + `preflight.sh` 接线 + `scripts/README.md`；壳/packs/verify-kit 零改动）。
- maui：`OpenHarmonyAccessibility.cs` 单文件（SEC7-A 直呼 `ohos_host_accessibility_release_for`；`EntryPointNotFound`/`DllNotFound` 缓存保持旧宿主 managed-only 降级；+9/−27）。

## 2) 门禁（合并树，`PREFLIGHT OK` 5/5）

- 套件 **`checks=737 total=740 floor=720 assert=True`**（declared==printed、0 Unhandled、perf 全 within）；pixel `PIXEL ASSERTIONS PASSED`（首轮 csc 宿主 SIGTRAP 抖动，按 preflight host fallback 重跑通过——rc.1 OpenSSL shim 双释放，非断言失败）。
- `selftest-cut-kit` **38/38**（step 1 内）；host 三件 registry **84** / bridge **26** / a11y-table **47**；pack-sync/lint/ridgraph 绿。
- 导出 **164/164**（`check-host-exports.py --cross-check`）；abc/EXPECT：四包（.22/.23/.24/.28）ui **542,936 / `f18f0855…`**、headless 24,324 / `798b2477…`，`EXPECT_ABC=542936,24324` 不变（未重锚）。

## 3) pin / CI

- 三 workflow `MAUI_OHOS_REF` → `b91437926906242764ad64955409f080a4cb206f`（注释同步：SEC7-A + 737/740 floor 720、164/164、542,936）；pin 提交 ow `ca94b55`。
- CI 5/5 @ ow `ca94b55`：interaction `37746316516` / pixel `37746316479` / host-export `37746316472` / ridgraph `37746316462` / markdownlint `37746316504`（全 success）。

## 4) 推送 / 状态

- maui `caa463434b → b914379269`（origin/feature/openharmony）；ow `7259a0f → 86fb3d4 → ca94b55`（origin/master）；本文件 + README 索引 → runtime `feature/openharmony`（commit-paths 限路径）。
- #53 仍为当前 kit（数字以 release `## Integrity (kit #53)` 为准）；**#54 待 rc.2**（RC2-ALIGN-RUNBOOK WAIT；触发后 `cut-kit.sh --kit 54`，先补 tester docs 波次）。
- 不确定：SEC7-A 的 loader 误报根因仍未追（沿用 #53 降级单）；pixel 的宿主 csc 抖动为环境层（与合并内容无关，CI Linux 无此现象）。
