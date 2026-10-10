# BATCH3-MERGE-PLAN：L7-M2（＋L8 余项占位）合并执行单（2026-10-10，只读预演）
> 预演 = scratch detached worktree（未动共享检出/分支 ref）：ow `01b426e` →＋L7-M2 `82a9e4e`（树=`ee95143`）→＋L8 `51d4a94`；maui `14cc245902` → `1eaea248b1`。本预演只做冲突/期望值；套件与 abc 于实测门禁确认。
> 口径：ow = `ohos-workload` master `01b426e`；maui = `maui-ohos` feature/openharmony `14cc245902`；#49–#53 资产不动、不切 kit（#54 待 rc.2）；本 session 无上游 PR。

## 1) 合并顺序（逐支 `--no-ff`：ow→master，maui→feature/openharmony）
1. ow `feat/n-subwindow-m2` `ee9514358dfc`（就绪）：16 文件（四包 Index.ets＋abc＋provenance、build/verify/selftest 脚本、Program.cs）。
2. ow `fix/l8-remainder` `373bee0`（占位·待回执）：`App.cs`＋`Program.cs`。
3. maui `fix/l8-remainder` `31ed839fd6`（占位·待回执）：`OpenHarmonyMauiAppHost.cs`（+40/−4）。L7-M2 maui 零改动（支=主线 `14cc245902`）；仅 L7-M2 就绪时跳过 2/3。

## 2) 预演冲突（文件/hunk/取舍）
| # | 支 | 冲突 | 热点（hunk 摘要） | 取舍 |
|---|---|---|---|---|
| 1 | ow L7-M2 | 0 | — | merge-base=`01b426e`；合并树与 `ee95143` 逐字节一致，769/749 值直接迁移 |
| 2 | ow L8 | 1 文件 1 hunk | `test/maui-platform-verify/Program.cs:16` 计数行（HEAD 769 vs L8 768） | 终值 **771**：注释并集（+3 L7-M2 前插；+1 MODAL-DEEPLINK、+1 L8-REMAINDER 尾接）；App.cs 自动合并 |
| 3 | maui L8 | 0 | — | `OpenHarmonyMauiAppHost.cs` 自动合并 |
热点：计数行为各支同点追加（唯一文本冲突；反向并亦同解）；壳四包零冲突但必须走 `--check-sources`＋重编双门禁。

## 3) 期望值 / 门禁（合并树，按序）
| 项 | 期望 | 说明 |
|---|---|---|
| 套件 | **771/768 floor 751**（=766+3+2） | L7-M2 单独 769/766/749；declared==printed 在合并树跑一次 interaction 确认 |
| abc | **576,664/`e69563c3…`**（占位参考） | 合并树四包同哈希；L8 不触壳→重编一次期望 byte-identical；headless 24,324/`798b2477…` 不变 |
| maui pin | 合并 tip（预演 `1eaea248b1`，实测为准） | 仅 L7-M2 时 pin 维持 `14cc245902` |
| 导出/preflight | 164/164；OK 5/5 | pixel PASS、cut-kit 52/52、arkts selftest 207/0 |
- G0 设备门（前置）：L7-M2 真机未验（设备 Offline）→ 设备恢复后按 `/data/storage/el2/base/tmp/opencode/l7m2/l7m2-round.sh`（N=4 矩阵、churn×20、40min soak、帧率/RSS）全项 PASS＋回填 `2026-10-10-ohos-l7-m2.md` 才放行；L8 真机已 PASS（hdc 36823）。
- G1 合并（§1 顺序；冲突按 §2 取舍）→ G2 **packs/EXPECT 一次重锚**：`build-arkts-shell.sh` 重编一次 → `--install-packs` → 仅字节漂移时重锚 EXPECT（预期不漂移）；`selftest-build-arkts-shell`/`selftest-verify-kit` 绿。
- G3 套件/pixel/导出/preflight 全绿 → G4 三 workflow `MAUI_OHOS_REF` pin 至 maui 合并 tip → CI 6/6。

## 4) 风险 / 不并入
- 风险：设备门在前（未过不放行）；计数器同点（解已定）；abc 漂移仅走单次重锚并记录（勿多次）；L8 未回执→占位，其失败可单独顺延（L7-M2 可独立收口 769/749）。预演 sha 属 scratch（worktree 清理后不可达）。
- 不并入：`feat/l8-popup-probe` `19b02da`（探针件）、`sample/hybrid-subwindow` `09d244b`（样例·无回执）、`wip/l2-consolidate-stale`、`origin/archive/*`、`fix/ohos-rc2`；WEBAUTH 无产品提交（implicit 仅构造未判定，不并）。
