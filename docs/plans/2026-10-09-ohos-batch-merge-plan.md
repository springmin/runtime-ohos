# BATCH-MERGE-PLAN：E4 · L3L4 · WebAuth · L5 · L7 批合并执行单（2026-10-09，只读草稿）
> 执行结果（2026-10-09）：已按本单执行（含 webauth 与默认 8 翻转）；合并 SHA、冲突裁决、新 abc（552,876/24,324）、套件 756/759 floor 739、pin/CI 见 `2026-10-09-ohos-batch-consolidate.md`。
> 口径（2026-10-09 实测）：ow = `ohos-workload` master `3ecec5c`（`tooling/cut-kit-2` `3773c64` 待并）· maui = `maui-ohos` feature/openharmony `619c40a483`（preprobe 已并）· runtime = 本仓 feature/openharmony `d249b42a0b9`；#49–#53 资产不动、不切 kit；本单只读。

## 1) 合并顺序（最小冲突；逐支 `--no-ff`，ow 目标 master / maui 目标 feature/openharmony）
0. ow `tooling/cut-kit-2` `3773c64`（仅 scripts：cut-kit/bump-docs/selftest）——先并，避开 E4 对 `cut-kit.sh` 注释的小改。
1. ow `feat/overlay-capacity8` `30a8651`（E4）：四包 `Index.ets` + build/verify 门禁 + 套件；abc 548,192/`ab5da50b…`。
2. ow `feat/loaddata-navrate` `e6e4f41`（已 stack 在 E4 上）：`Index.ets`+`SubWindow.ets`+样例+套件；abc 550,304/`9365743369…`。
3. webauth（实现中，提交并 rebase 后就位；否则顺延）：maui `OpenHarmonyWebAuthenticator.cs`+`MauiOpenHarmonyExtensions.cs`；ow 生成器 `OpenHarmonyGenerateModuleJson.cs`+packs targets/Tasks.dll+套件+`WebAuthProbe.cs`。
4. maui `maint/sec5c-ef` `6f278ee99b` + ow `maint/sec5c-ef` `95e4a68`（L5）：maui slice（pinch/a11y 边界）+ ow 套件 pin；abc 不变。
5. L7 `feat/n-subwindow`（如就绪）：ow `343fc21`（四包 `Index.ets`+门禁+套件）+ maui `8b6d4073cb`（`OpenHarmonyMauiAppHost.cs`）；abc 545,728/`71eb1e0e…`。
6. **最后**落「默认 8」翻转：宿主 `OpenHarmonyOverlays.DefaultMaxOverlays` 与壳 `WEB_SLOT_DEFAULT_MAX` 4→8（四包同值；`build-arkts-shell.sh` gate 字面与套件 pin 随动）——先于唯一一次 abc 重编。

## 2) 期望值（各支实测 → 合并预计）
| 支 | 实测 abc / 套件 | 合并 +N |
|---|---|---|
| 基线（ow `3ecec5c` / maui `619c40a483`） | 542,936/`f18f0855…`；套件 738/741 floor 721（kit #53） | — |
| E4 `30a8651` | 548,192/`ab5da50b…`（四包一致；headless 24,324 不变） | 套件 +1 |
| L3L4 `e6e4f41` | 550,304/`9365743369…` | 套件 +2（相对 E4） |
| L5 `6f278ee99b`+`95e4a68` | abc 不变（纯 slice+套件 pin） | 套件 +6 |
| L7 `343fc21`+`8b6d4073cb` | 545,728/`71eb1e0e…` | 套件 +1 |
| **合并后**（webauth 就绪时再 +N） | **abc＝合并壳重编一次后实测**（勿按字节差相加；EXPECT 重锚实测值；导出恒 **164/164**） | **套件 total 751＝741+1+2+6+1；floor 731＝total−20；checks 预期 748（同 3 项平台跳过）** |

## 3) 门禁（合并树，按序）
1. abc 只重编一次：`build-arkts-shell.sh` → `--install-packs`（四包 + `abc-provenance.json`）→ `verify-kit.sh` EXPECT 重锚（联动 `selftest-verify-kit`；cut-kit 同源推导）。
2. 自测/预检：`selftest-build-arkts-shell.sh`（合并树 ≈210/0＝185+10+8+7，以实测为准）+ `preflight.sh` 全绿（step1 含 cut-kit **52/52**、ridgraph/packs/hap-targets/tasks/host 三件/hygiene；step4 套件 748/751 floor 731 assert=True；step5 pixel PASSED）。
3. 导出 `check-host-exports.py --cross-check` **164/164**；pin 三 workflow `MAUI_OHOS_REF`（interaction/pixel/host-export）→ 合并后 maui tip。
4. CI 5/5：interaction / pixel / host-export / ridgraph / markdownlint；文档：README 索引 + kit 状态。
5. **#54 待切**：等 rc.2 触发，`bump-tester-docs.sh --kit 54` 波次后 `cut-kit.sh --kit 54`；本次合并不切。

## 4) 风险 / 回退
- 冲突热点：四包 `Index.ets`（E4/L7 同区常量+逐槽表）· `SubWindow.ets`（L3/L4）· `verify-kit.sh`/`selftest-verify-kit.sh`（EXPECT 同点）· `test/maui-platform-verify/Program.cs`（各支同文件追加 pin，最易冲突；合并后 total 对账＝751）· `scripts/cut-kit.sh`（E4 注释 vs cut-kit-2 重写——先并后者）。
- abc/EXPECT 仅重编重锚一次且排在默认 8 之后；重编后再动壳＝再构建再重锚（本轮预算 1 次）。
- L7：默认维持 2；M1 未决（env 对壳可见性未隔离、第 3 窗拒绝日志/WMS 计数缺）+M2/M3 未开——不阻塞本并，也不得据此抬默认。
- ridgraph T5 3 项在基线 worktree 亦失败（继承夹具/环境，非本轮回归）；L8 probe 结论仅作 L7-M2 输入。
- 回退：逐支合并、冲突即 `git merge --abort`；已并支 `git revert -m 1 <merge>` 单支回退，未并支原地保留。

## 5) 不并入
- ow `feat/l8-popup-probe` `19b02da`（探针件 abc 38,156 仅 scratch）：探针页/EntryAbility 不得进四包。
- 一切 `/data/storage/el2/base/tmp/opencode/*` scratch（device 日志、probe HAP、state.env）；`wip/l2-consolidate-stale` 与 e4-fix 装置件不并。
