# NEXTKIT-PREP：并入 polish-49、四包 abc/provenance 刷新、verify-kit 重锚（2026-10-06）

> 口径：把候选分支 `next-kit/polish-49`（`b5928d1`）并入 ow `master`，刷新四个 pack 的
> abc/provenance，供下一次切包使用。本步**不切 kit、不动 #49 release 资产**（仍 414,532 /
> `e016db13…`，测试方校验 #49 件继续用 `verify-kit.sh --expected-abc 414532`）。

## 合并（ow）

- `master` 71fe00c → **`b5928d1`**（`--ff-only`，无 merge commit、未强推）；`origin/master`
  推送后核对 `b5928d1`。diff = 4 包 × `pages/Index.ets`（Parse E 修复 + Home 焦点链；
  EntryAbility 净零）。

## packs / abc / provenance（四包 = preview.22/23/24/28）

| 项 | 之前 | 之后 |
|---|---|---|
| ui abc | 414,532 B / `e016db13…` | **417,416 B / `cee64297…`**（13.0.1.0） |
| headless abc | 24,324 B / `798b2477…` | 24,324 B / `798b2477…`（未变） |
| pages/Index.ets | `02b910d0…` | `4db57f02…` |
| abc-provenance.json | `70bfbcad…` | `99f005df…` |

- 构建（合并树上重编、一次一构建，MemAvailable 9.9–10.2 GB、无并发进程）：UI
  CompileArkTS 9.3 s → `dist/ets/modules.abc` 417,416/`cee64297…`；headless 5.4 s →
  24,324/`798b2477…`。装包前末段 gate 报 dist 与旧 packs 不一致属预期（exit 1）。
- 安装：`--install-packs` 刷新 preview.22/23/24（provenance gate 绿）；按惯例把 .24 的
  `modules.ui.abc`/`modules.abc`/`abc-provenance.json` 手动同步到 preview.28；四包逐字节一致。

## 校验

- T16（`--check-pack-abc`）：合并后未装包 = 4 ERROR（22/23/24 source drift + gate fail）；
  装包后 **绿**（含 `/dist/ets` 对比）；`selftest-build-arkts-shell.sh` **188 checks / 0 failed**。
- verify-kit：`EXPECT_ABC` 默认 414,532 → **417,416**（`verify-kit.sh` 6 处、
  `selftest-verify-kit.sh` 5 处字符串同步）；`selftest-verify-kit.sh` 裸跑 **129 / 0**。
- 设备：本步不需要（T16/verify-kit 离线跑），未触碰 `.device-lock`。

## 下一 kit 步骤

1. 按既有流程切包 + device-round/soak 复核（Home 键 suspend/resume、建窗 E=0、close WARN 1）。
2. 重打 kit / 预签 / 发布；`verify-kit.sh` 已默认 417,416，历史 #49 件加
   `--expected-abc 414532`。
3. `maui-platform-verify` 的 `wShellVersions` 已覆盖四包源（源未再变），无需改动。
