# MAUI P0 常驻门禁（P0-GATES，2026-11-02）

> 目的：把 P0 四条工作流（上游差异、第三方库、Reference App、性能）从“一次性验证”
> 变成**可重复执行、失败即红**的门禁。本文记录门禁结构、接入点、实测结果与边界。
>
> 口径：`ohos-workload` `14562d3` · `runtime-ohos` `feature/openharmony` ·
> `maui-ohos` tip `efe5b823c8e0` · `CommunityToolkit.Maui` 15.0.1 · kit #58 阈值。

## 1. 门禁矩阵

| 检查 | 脚本 | 模式 | 需要设备 | 接入点 |
|---|---|---|---|---|
| perf 比较器 fixture | `scripts/selftest-perf-gate.sh` | quick | 否 | `preflight.sh` 步骤 1 + CI |
| 真实性能指标 | `scripts/perf-gate.sh <metrics.json>` | `--metrics` | 是（产出 metrics） | 设备轮 / 发布 |
| 上游差异漂移 | `scripts/check-upstream-delta.sh` | quick | 否 | `p0-gate.sh --quick`（本地/发布） |
| compat 源码 pin | `p0-gate.sh` 内置 | quick | 否 | CI + 本地 |
| Reference App 源码 pin | `p0-gate.sh` 内置 | quick | 否 | CI + 本地 |
| compat NativeAOT + IL 预算 | `p0-gate.sh --full` | full | 否（host） | 发布/RTM 预演 |
| Reference NativeAOT + IL 预算 | `p0-gate.sh --full` | full | 否（host） | 发布/RTM 预演 |
| 真机 4/4 + 第二 ability | 手工 runbook | device | 是 | `2026-10-30-ohos-maui-reference-app.md` |

## 2. quick 模式（默认）

```sh
cd ohos-workload
sh scripts/p0-gate.sh --quick
```

实测（2026-11-02）：

- perf fixture **21/21** checks（baseline PASS、regression FAIL、`--report-only` 0、
  usage 2、默认阈值路径、缺键 SKIP、自定义阈值）；
- 上游差异 **PASS**：152 文件 / +50,788 / −3；148 A / 4 M；切片 143 文件；
  侵入 4 文件 +77/−3；
- compat pin **PASS**：CommunityToolkit.Maui 15.0.1、`EXPANDER/AVATAR/DRAWING/TOUCH/POPUP`
  五个隔离 case、`OpenHarmonyHandlerConnector.RegisterHandler`、`UseMauiCommunityToolkit`；
- Reference pin **PASS**：`MainTabs`、pending route、`orders/form/settings/subwindow`
  深链、`form saved`、子窗创建、1k 列表、第二 ability 壳源。

`--metrics <json>` 追加真实设备指标比较，例如：

```sh
sh scripts/p0-gate.sh --quick --metrics /path/to/round-metrics.json
```

## 3. full 模式（AOT + IL 预算）

```sh
sh scripts/p0-gate.sh --full
```

实测（2026-11-02，MemAvailable ≈ 11 GB）：

| 应用 | AOT | IL2026 | IL3050 | IL3051 | hap |
|---|---|---|---|---|---|
| `test/maui-compat-app` | PASS | 2 / 预算 2 | 0 / 0 | 0 / 0 | 21,797,680 B |
| `test/reference-lob` | PASS | 0 / 0 | 0 / 0 | 0 / 0 | 21,318,452 B |

- compat 的 2 条 IL2026 是 `Expander..ctor` 的 `RequiresUnreferencedCode`（warning +
  trim-analysis duplicate），与 `2026-10-29-ohos-maui-thirdparty-compat.md` 的记录一致；
  预算固定在 `test/p0-gate/il-budget.json`，新增告警即 FAIL。
- 本轮同时移除了 `Program.cs` 的 `Exception.TargetSite` 诊断（自身触发 IL2026），
  日志仍保留 stack。
- 内存低于 2 GB 时 AOT 阶段返回 **SKIP**（不是 FAIL）：publish 脚本本身也会拒绝启动。

## 4. 上游差异漂移

```sh
sh scripts/check-upstream-delta.sh
```

- 基线：`maui-ohos` 上游 `d32b7992870`（`release/11.0.1xx-rc2`）；
- 期望值与容差：`test/p0-gate/upstream-delta.json`（files ±4、insertions ±200、
  slice_files ±4、intrusive ±20）；
- 2026-11-02 重测：**+50,788 / −3**（10-28 文档为 +50,766；+22 来自 T2
  `OpenHarmonyHandlerConnector.RegisterHandler`），切片代码行 **48,198**；
- 超出容差即 FAIL，并提示同时更新 JSON 与
  `2026-10-28-ohos-maui-upstream-delta.md`；
- `maui-ohos` 或基线 commit 缺失时返回 3（SKIP），不误报。

## 5. 接入点

- **preflight**：`scripts/preflight.sh` 步骤 1 的仓库门禁循环已加入
  `selftest-perf-gate.sh`；`sh scripts/preflight.sh --quick --skip-lint` 实测为
  `PASS (... selftest-perf-gate:21)`。
- **CI**：`.github/workflows/p0-gate.yml` 在 push/PR 运行
  `sh scripts/p0-gate.sh --quick --skip-delta`（只读 checkout、无 secret）。
  delta 需要 `maui-ohos` 全历史，留在本地/发布轮；full 需要 OpenHarmony workload，
  也留在发布轮。
- **发布/RTM**：`p0-gate.sh --full` 作为 RTM 切换前的前置门（见下一条建议的 runbook）。

## 6. 边界

- quick 的 pin 是**源码级 tripwire**，不能替代 AOT/真机；full 才覆盖裁剪与 hap 产出。
- 真机 4/4、第二 ability、冷启 `-U` 仍是手工 runbook；设备指标 JSON 由设备轮产出后
  通过 `--metrics` 进入门禁。
- SKIP 必须带原因（`--skip-*`、内存、缺 maui slice、缺基线），不得用 SKIP 掩盖失败。

## 7. 证据

- 代码：`ohos-workload` `14562d3`（gates + preflight + CI + compat 诊断清理）；
- quick：`p0-gate.sh --quick` rc=0（perf 21/21、delta PASS、compat/reference pin PASS）；
- full：`p0-gate.sh --full` rc=0（compat IL2026 2/2、reference 0/0、两个 hap）；
- preflight：`preflight.sh --quick --skip-lint` rc=0（69 scripts，perf fixture 21）。
