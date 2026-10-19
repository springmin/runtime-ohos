# 三仓同步（aspnetcore / maui / sdk）— 2026-10-19

> **口径修正**：`main` 已不在产品线上（aspnetcore main = `12.0.0-alpha`），三仓开发支是
> **11.0 rc.2/RTM 线**。因此同步对象取**对应 11.0 发布支**（非 main）：
> aspnetcore `release/11.0`、maui `release/11.0.1xx-rc2`、sdk `release/11.0.1xx`。
> main 的"距离"仅作趋势参考（见 2026-10-19 前一轮分析），**未合 main**。

## 1. 结果

| 仓 | 上游支 @ tip | 合并提交 | behind | 冲突 | 合并增量 | 解决要点 |
|---|---|---|---|---|---|---|
| `aspnetcore-ohos` | `release/11.0` @ `50f709d1dc`（10-14） | **`44ec71aa7c`** | 26 | 7（6 content＋1 submodule） | 35 文件 ＋3034/−2810 | 版本/dependabot/package-lock/googletest 指针**取上游**（rc.2→**rtm** `11.0.0-rtm.26480.113`） |
| `maui-ohos` | `release/11.0.1xx-rc2` @ `d32b7992870`（10-05） | **`868d3c8727b`** | 9 | **0** | 19 文件 ＋1036/−137 | 干净合并 |
| `sdk-ohos` | `release/11.0.1xx` @ `f91d1ea06e9`（10-16） | **`92e2704acb`** | —（新基 `def202206b`） | 7（全 content） | 286 文件 ＋6144/−6202 | 5 个版本类文件**取上游**（rc→**rtm**）；`NativeEntryPoint.cs` 与 `AotParserTests.cs` **双保留**（OHOS 调用＋上游语言/编码块；我方 test-modules 测试＋上游 package/nuget 测试） |

- 三仓均已推送 `origin/feature/openharmony` ✓；
- sdk 的过程修正：主仓当时在 `feat/aotpack-rebuild`，误合已 `merge --abort` 复原；改用
  专用工作树 `/data/storage/el2/base/tmp/opencode/sdk-sync/wt`；且 origin 已前进 11 笔
  （kit #56/#57/#58 锚定与 ohos-install 修复）→ **重置到 `def202206b` 后重做合并**（同 7 冲突）。

## 2. 预演存档

`/data/storage/el2/base/tmp/opencode/sync-rehearsal-20261019/`（对 **main** 的预演证据，
以及 sdk 对 `release/11.0.1xx` 的冲突清单）。三仓对**发布支**的实际冲突：aspnetcore 7、maui 0、sdk 7。

## 3. 影响与后续

- **kit #58 已发布产物不受影响**（构建自 `def202206b` 之前）；但 sdk 现携带 **RTM 工具链/依赖 pin**
  → **下一次 kit 构建必须重新验证**（构建 + 包图 + 设备冒烟）。
- aspnetcore/maui 的 RTM/rc2 增量较小，后续构建验证按常规排。
- main 线同步（12.0 alpha 迁移）是**产品决策**，未执行。
- 预演方法（只读）：`git merge-tree --write-tree --name-only <dev> <target>`。
