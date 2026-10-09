# BATCH-MERGE-DRYRUN：E4 · L3L4 · WebAuth · L5 · L7 合并彩排（scratch worktree，未动共享检出/既有分支）
> 口径：ow detached `3ecec5c` / maui detached `619c40a483`；逐支累积 `--no-ff`。webauth 与「默认 8」无提交 → 跳过（§3）。
> 复现：`git worktree add --detach <scratch>/ow 3ecec5c && cd <scratch>/ow && git merge --no-ff <sha>`（maui 同理）。

## 1) 各步冲突与建议取舍
| # | 支 | 冲突 | 冲突文件（hunk 摘要） | 建议取舍 |
|---|---|---|---|---|
| 1 | ow cut-kit-2 `3773c64` | 0 | — | 先并；E4 对 cut-kit.sh 的单行注释自动合入 |
| 2 | ow E4 `30a8651` | 0 | — | 自动合并（4 包 Index.ets、verify-kit EXPECT 均无冲突） |
| 3 | ow L3L4 `e6e4f41` | 0 | — | stack 在 E4，自动合并 |
| 4 | webauth | 跳过 | ow/maui 均无提交：maui wt-wa 2 文件、ow 生成器+packs 均在工作区 | 按指令跳过并注明 |
| 5 | ow L5 `95e4a68` | 1 | Program.cs:16-20 verifyCheckTotal（HEAD 744 / L5 747；注释段 +7 SEC-SCAN-5c E/F 前插） | 注释取 L5 段＋原注释；值=744+6=**750**（L7 再 +1 → 终值 751） |
| 6 | ow L7 `343fc21` | 13 | ①4×modules.ui.abc（二进制）②4×abc-provenance.json:24-42（bytes/sha256/sources）③build-arkts-shell.sh 6 块（E4 slot-capacity vs L7 subwindow-capacity gate）④selftest-build-arkts-shell.sh:454-512（E4+C5/L4 vs N 红控件）⑤verify-kit.sh 5 块（EXPECT_ABC 550304/545728）⑥selftest-verify-kit.sh 4 块（同 EXPECT）⑦Program.cs:16-20（750/742） | ①②取 ours 占位、重编后重生成；③④双向保留（三 gate＋两组红控件），调用点与共用尾部续接；⑤⑥取 ours 占位、重编后重锚（两值均非终值）；⑦终值 751 |
| 7 | maui L5 `6f278ee99b` | 0 | — | 3 切片文件自动合并 |
| 8 | maui L7 `8b6d4073cb` | 0 | — | OpenHarmonyMauiAppHost.cs 自动合并 |

## 2) 自动合并热点复核（无冲突但需关注）
- 4 包 Index.ets：E4 派生表（WEB_SLOT_MAX/WEB_SLOT_DEFAULT_MAX/OHOS_OVERLAY_MAX）＋L3L4 webDataPayload＋L7 SUB_WINDOW 标记并存，`--check-sources` 通过。
- App.cs：L3L4（141 行）＋L7（65 行）双向并存；cut-kit.sh：cut-kit-2 重写＋E4 注释并存。

## 3) 预计数 / 实测与跳过项
- 交互套件 total＝741+1+2+6+1＝**751**（合并树常量实测 751）、floor **731**、printed **748**（3 项平台跳过）。
- `selftest-build-arkts-shell` 实测 **204/3**：3 失败全为 T16 abc provenance（占位 abc 与合并源不一致）→ 重编后预计 **204/0**（执行单 ≈210 以实测为准：E4+7/L3L4+8/L7+4 断言）。
- `selftest-verify-kit` 129/0（占位 EXPECT）；`selftest-cut-kit` 52/52；`check-host-exports --cross-check` **164/164**；maui 无套件。
- abc 无法预算：合并后**重编一次**＋`--install-packs`＋EXPECT/provenance 重锚（本轮占位 550,304）。
- 默认 8 全仓无提交（host DefaultMaxOverlays=4、壳 WEB_SLOT_DEFAULT_MAX=4，`git log -S` 无翻转）→ 无法彩排；预期套件计数不变，落点＝OpenHarmonyOverlays.cs＋4 包 Index.ets＋build gate 字面＋重锚。

## 4) 结论 / 风险
- 冲突 14 处（ow 14、maui 0），全可按上表取舍，无双向逻辑互斥；cut-kit-2 先行必要（避开 cut-kit.sh 注释碰撞）。
- 唯一残余验证：合并壳 abc 编译与 T16 provenance，由「默认 8 后唯一一次重编」闭合；Index.ets 为文本合并，务必走 `--check-sources`＋重编双门禁。
- 彩排完成：worktree/临时分支已全清（worktree remove＋prune），共享检出与既有分支未动（本文件提交除外）。
