# L-CONSOLIDATE：MULTIWINDOW-L（M1–M4 + SEC-SCAN-5a/5b/5c）并入主线 / 门禁 / pin / CI（2026-10-06）

> 口径：把 L 栈并入主线——ow `master` ← `l/m4-focus-ime` @ `a1ebde2`、maui `feature/openharmony` ←
> `l/m4-per-window-focus` @ `23d98a9615`（均为 merge commit、普通推送、未强推）。**不切 kit、不动 #49 资产**
> （#49 release tar 仍 67,888,851 / `477974bb…`、树 `8d03cb4c…`；测试方 `--expected-abc 414532` 口径不变）。

## 1) 合并

- ow `7e7ea06` → **`52af282`**（merge `a1ebde2`，16 提交，tree 与 L tip 相同）；`origin/master` = `52af282` → **`afa6d7a`**。
- maui `b093e33825` → **`74e0bde5b9`**（merge `23d98a9615`，tree 与 L tip 相同）；`origin/feature/openharmony` = `74e0bde5b9`。

## 2) packs / abc / provenance（nextkit 流程）

- 合并树重编两变体并逐字节复现：ui **436,808 / `289a5e5d…`**（任务预记 ~426,304 / `38bdf7de…` 为 M3 旧值，M4 第一波壳改动后实测取代）、headless 24,324 / `798b2477…`。
- `--install-packs`：preview.22/23/24 安装 + provenance 刷新，preview.28 手动同步后四包逐字节一致；`--check-sources` / `--check-pack-abc` 绿。
- `verify-kit.sh` 默认 EXPECT_ABC `417,416 → 436,808`（selftest 同步）；裸跑 selftest-verify-kit **129/0**、selftest-build-arkts-shell **188/0**；提交 ow `009159e`。

## 3) 门禁（合并树 + 收口切换后）

- 套件：`[suite] checks=661 total=663 floor=643 assert=True`（declared==printed、0 Unhandled、perf 两条 within=True）；SEC-5c +1 反转隔离 pin 红控在案（`a1ebde2` 提交信息 + SEC-5c 报告：修前该 thunk 向子窗追加 `main-only`；M4 pinch 红控见 `-l-m4.md`）。
- pixel：`PIXEL ASSERTIONS PASSED`（本机 host quirk 触发 preflight 记录的 fallback 路径，结果一致）。
- host 三件：registry 84/84、bridge 26/26、导出 **157/157**（`check-host-exports.py --cross-check`）。
- preflight：repository gates + interaction/pixel 全 PASS；唯一 FAIL 为未跟踪 `.a11y-build/**` 的 markdownlint 本地误报（CI checkout 不含；跟踪集 20 文件 0 issue）。

## 4) pin / CI

- 三 workflow pin `d4ff7d445e → 23d98a9615`（注释：套件 661/663 floor 643、导出 157/157、abc 436,808、feature merge `74e0bde5b9`）；提交 ow `afa6d7a`。
- CI 5/5 @ `afa6d7a`：interaction 37460790068、pixel 37460790072、host-export 37460790087、ridgraph 37460790138、markdownlint 37460790028。
- 中间提交 `52af282` 的 interaction 一度红：根因 = 该提交仍是 M3 pin、M4 harness 引用新成员（`Inactive/Active`、`DeactivatedCount` 等）；由 pin 提交闭环，无需改码。

## 5) 状态 / 降级声明

- **L 合并完成；kit #50 待切**；#49 资产未动、未并入 release 资产。承 `-l-m4.md` 降级项：子窗 a11y provider（主 provider 零变化）、子窗 ArkWeb 第二宿主、平台级多子窗上限（应用级 N=1）；人工卡 = 子窗 IME 实敲（`-l-m4.md` 末节）；SEC-5c B–F 报告未修项见该报告。
- 边界：2in1 debug 域单设备结论，不外推手机/release。
