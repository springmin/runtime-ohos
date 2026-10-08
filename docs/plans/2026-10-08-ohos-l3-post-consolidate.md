# L3-POST-CONSOLIDATE：A11Y-SELFCHECK + B6 并入主线 / 门禁 / pin / CI（2026-10-08）

> 口径：ow `master` ← `l3/a11y-selfcheck` @ `887e172a7d0c`（merge `11972de`）+ `l3/b6-nav-veto` @ `d25c0ebfb539`（merge `96267f2`）；
> maui `feature/openharmony` ← `8c7a859c9175`（merge `4910d470db`）+ `b64c477f8e`（merge `caa463434b`）；均 `--no-ff`、普通推送、未强推；
> **不切 kit（#53 待定）**、#49–#52 资产不动；结论域 = 离线门禁 + CI（真机证据引用两卡归档）。

## 1) 清尾 + 合并（一次共存）

- 清尾：ow 共享检出遗留 hybrid 样例（`test/hello-maui-app/App.cs` + `wwwroot/child-hybrid.html`，未提交）移至 scratch
  `/data/storage/el2/base/tmp/opencode/hybrid-dev/sample/`（含 `App.cs.uncommitted.diff` + README），工作树复原干净后合并。
- 唯一冲突 = ow 套件 `verifyCheckTotal` 行（a11y 735 / B6 739）：解析为 **740**（M2–M4 734 + B6 5 + A11Y-SELFCHECK 1）并合并双方注记；
  两卡新增检查（`b6c` 5 条 + `m4 a11y selfcheck pending repaint`）共存。maui 两分支文件互不重叠（a11y `OpenHarmonyAccessibility/WindowHost`、
  B6 `OpenHarmonyWebViewHandler`）自动合并；壳 `SubWindow.ets` 仅 B6 改（a11y 分支未动壳），单源壳一次重编核验。

## 2) packs/abc/provenance（重编 + .28）

- `build-arkts-shell.sh`（ui + headless）合并树重编：ui **542,936 / `f18f08557be5…`**、headless **24,324 / `798b2477…`**，
  与 B6 安装值逐字节一致；`--install-packs`（.22/.23/.24）+ **.28 手动同步** + `~/.dotnet`、`~/.dotnet.rc2-fix` 同步；
  `--check-sources` / `--check-pack-abc` 绿；host `.so` 重编 **367,520 / `ad7ab986…`** 不变。
- `verify-kit` EXPECT `534192 → 542936`（`selftest-verify-kit` **129/0**）；ow `35aa1c3`。

## 3) 门禁（合并树）

- 套件 **`checks=737 total=740 floor=720 assert=True`**（declared==printed、0 Unhandled、perf 全 within；超集 = 731 + B6 5 + a11y 1）；
  红控引用：a11y `a11ysc/suite-red1–4.log`（pending 重绘离线红）、B6 `b6/suite-red.log`（去 child 分派 3×assert=False exit 134）。
- pixel `PIXEL ASSERTIONS PASSED`；host 三件：build-host 契约 **164/164**（DT_NEEDED/UND 过）、`check-host-exports.py --cross-check`
  **164/164**、selftest registry **84/0** / bridge **26/0** / a11y-table **47 PASS**；pack-sync：`selftest-packs` 25/0、
  `lint-packs` 35 files/7 packs、`selftest-ridgraph` 20/0；preflight **PREFLIGHT OK（5/5，interaction 737/floor 720 + pixel）**。

## 4) pin / CI

- 三 workflow pin `277967cc56 → caa463434bc141b1106eb7303e29d225e2491433`（注释：套件 737/740 floor 720、导出 164/164、abc 542,936）；ow `7259a0f`。
- CI 5/5 @ ow `7259a0f`：interaction `37724762076` / pixel `37724762158` / host-export `37724762150` / ridgraph `37724762139` / markdownlint `37724762089`（全 success）。

## 5) 状态

- KIT52 降级单中的 **a11y selfcheck 首发布时机**（`-l3-m3.md` §5）与**子窗 B6 导航否决**（`-l3-b6-modes.md`）两卡**已并入主线**；
  真机证据引用：a11y `a11ysc/round2.log`（`nodes=10` ×2）+ round1 诊断；B6 `b6/` + deny/ok 闭环。
- 余项不变 = 多子窗同槽 hybrid invoke fail-closed（产品级 N=1）、子窗 a11y 动作 e2e（平台）、IME 人工卡；**#53 切包待定**
  （切包时重编 packs/abc/provenance 并按 `verify-kit` 锚定）。
