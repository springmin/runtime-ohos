# MAUI on OpenHarmony P0 执行计划（2026-10-28）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 MAUI 移植从“功能完成”推进到“覆盖可验证、第三方可复用、性能可守住”。

**Architecture:** 四条互相独立的 P0 工作流——
(A) 上游差异清单与同步手册（已完成，见 `2026-10-28-ohos-maui-upstream-delta.md`）；
(B) 第三方库兼容矩阵（CommunityToolkit.Maui 优先）；
(C) Reference App（真实 LOB 样例，驱动缺口）；
(D) 性能门禁（把已有实测数字变成红/绿门）。

**Tech Stack:** .NET 11 rc.2 · MAUI 11 rc.2 · OpenHarmony API 26（2in1）· kit #58 ·
`ohos-workload` 构建/切包链 · `maui-ohos` 平台切片。

**Spec:** 本文 + `2026-10-28-ohos-maui-upstream-delta.md` +
`2026-10-10-ohos-maui-remaining-audit.md`（剩余项）+ `2026-09-22-ohos-maui-coverage-matrix.md`。

## Global Constraints

- 构建线：`maui-ohos` `feature/openharmony` · runtime `fix/ohos-rc2` · SDK `11.0.100-rc.2.26504.105` ·
  workload `1.0.0-preview.29`；不得混用 12-alpha 线。
- 设备操作遵守 `.device-lock` 互斥协议；同一时刻只跑一个构建；用后还原并释放锁。
- 不强制推送；构建产物不入库；提交走 `commit-paths.sh` 限路径。
- 文档提交前必须过 `markdownlint`（仓库配置 + MD009/MD013/MD038/MD056）。
- 不触碰另一会话的上游 PR/分支；不做与任务无关的顺手重构。

## Review Focus

- 第三方 behavior 在 NativeAOT 下的反射闭合（CommunityToolkit 已知高发）。
- CollectionView 在 1k+ 项下的虚拟化与滚动帧率。
- 原生依赖泄漏（SQLite / PDF / Skia）——Reference App 必须先证明“零原生也能跑”。
- 深链 + 子窗组合（当前 N=4 壳契约）。
- 第三方资源字典/字体在壳内的加载路径。

---

### Task 1: 上游差异清单与同步手册（已完成）

**Files:**
- Create: `docs/plans/2026-10-28-ohos-maui-upstream-delta.md`

**Interfaces:**
- Produces: 基线提交 `d32b7992870`、差异数字（152 文件 / +50,766 / 4 个侵入文件）、同步节奏表。

- [x] **Step 1: 度量相对 rc.2 上游的差异**（152 文件、148 A / 4 M、+50,766/−3）
- [x] **Step 2: 拆出侵入面**（4 个文件、+77/−3）
- [x] **Step 3: 落档同步策略**（周/月/GA 三级）
- [x] **Step 4: 提交文档**

**验收:** 任何人在 `maui-ohos` 里跑 §4 的命令，能得到与文档一致的数字。

---

### Task 2: 第三方库兼容矩阵（CommunityToolkit.Maui 优先）

**Files:**
- Create: `test/maui-compat-app/`（`ohos-workload` 下，单页 + 控件清单）
- Create: `docs/plans/2026-10-XX-ohos-maui-thirdparty-compat.md`（矩阵结果）

**Interfaces:**
- Consumes: kit #58 的 workload / 构建脚本；`net11.0-openharmony` 目标框架。
- Produces: 矩阵表（库 × 控件 × 状态 × 证据），供 Reference App 与对外文档复用。

- [ ] **Step 1: 解析版本**——从 NuGet 取与 MAUI 11 rc.2 兼容的 `CommunityToolkit.Maui` 版本；
      若其 TFM 不含 `net11.0`，记录并改用源码包含（先记录，不改库）。
- [ ] **Step 2: 建样例工程**——引用 `CommunityToolkit.Maui`，放 4 个控件 + 1 个 behavior：
      `Popup`、`Expander`、`AvatarView`、`DrawingView`、`TouchBehavior`。
- [ ] **Step 3: 离线构建**——`dotnet build -c Release`（AOT 配置），记录警告/错误；
      AOT 反射问题按 `OpenHarmonySliceJsonContext` 的既有模式补根。
- [ ] **Step 4: 真机跑**——每控件至少一张截图 + 交互一次（打开/关闭、滚动、点击）。
- [ ] **Step 5: 落矩阵**——每行 = 库/版本/控件/状态（PASS·LIMIT·FAIL）/证据路径/备注。
- [ ] **Step 6: 提交**（样例 + 文档；产物不入库）。

**验收:** 至少 4/5 控件 PASS 或 LIMIT；每个 FAIL 都有最小复现与根因分类（AOT / 平台 / 库不支持）。

---

### Task 3: Reference App（真实 LOB 样例）

**Files:**
- Create: `test/reference-lob/`（Shell + 页面 + 本地存储 + 图表 + 深链）
- Create: `docs/plans/2026-10-XX-ohos-maui-reference-app.md`（验收与测量）

**Interfaces:**
- Consumes: Task 2 的控件兼容结论；kit #58 的 AOT/多窗能力。
- Produces: 可演示 app + 每轮 kit 可复跑的验收清单。

- [ ] **Step 1: 定范围**——5 页：Login（mock）、Dashboard（指标卡）、List（1,000 行）、
      Form（校验 + 键盘）、Settings（主题/关于）；图表用 `GraphicsView` 自绘，**不引入 Skia**。
- [ ] **Step 2: 本地存储**——先用 JSON 文件（`FileSystem.AppDataDirectory`）；
      SQLite 作为独立 spike（不在本任务验收内，避免原生依赖混入）。
- [ ] **Step 3: 深链 + 多窗**——`app://reference/...` 落地到指定页；子窗打开 List 详情。
- [ ] **Step 4: 真机跑**——记录冷启、首帧、列表滚动帧率（1k 行）、内存峰值、崩溃/告警。
- [ ] **Step 5: 落验收**——8 项勾选（登录/列表/表单/图表/深链/子窗/深色/离线启动）+ 截图。
- [ ] **Step 6: 提交**（代码 + 验收文档）。

**验收:** 8/8 通过，且 1k 行滚动 ≥ 55 fps、冷启 ≤ 3.5 s（AOT）；不达标项写成缺口而不是“目测正常”。

---

### Task 4: 性能门禁（把数字变成红/绿）

**Files:**
- Create: `scripts/perf-gate.sh`（`ohos-workload`）
- Create: `test/perf-gate/baseline-kit58.json`、`test/perf-gate/regression.json`
- Modify: `scripts/cut-kit.sh`（P5 之后可选调用；先不阻断，只报告）

**Interfaces:**
- Consumes: kit 报告中的 `startup`、`fps`、`rss`、`tar_bytes`、`suite` 五项。
- Produces: `perf-gate: PASS|FAIL` + 退出码（0/1），供 CI/切包链判断。

- [ ] **Step 1: 固定基线**——kit #58：首帧 534 ms（AOT attach→surface）、冷启 ≈3.2 s、
      滚动 60 fps、RSS 284–363 MB、tar 70,449,999 B、套件 826/829。
- [ ] **Step 2: 写门槛**——首帧 ≤600 ms、冷启 ≤3.5 s、fps ≥55、RSS ≤400 MB、
      tar ≤75 MB、套件通过数 ≥ floor。
- [ ] **Step 3: 写脚本**——`python3` 读取 JSON 与门槛，打印逐项对照，任一越界退出 1。
- [ ] **Step 4: 自测**——基线应 PASS（exit 0）；人为把 fps 改成 40 的 fixture 应 FAIL（exit 1）。
- [ ] **Step 5: 接入切包链**——`cut-kit.sh` 在 P5 后调用（默认仅报告，`--perf-gate-strict` 才阻断）。
- [ ] **Step 6: 提交**（脚本 + 基线 + 文档）。

**验收:** 两个 fixture 的退出码正确；切包 dry-run 能看到性能段落且不改变既有产物。

---

## 执行顺序与理由

1. **T1 已完成**——没有它，后面的“同步成本”无法解释。
2. **T4 先做**——纯离线、无设备、无构建，先把保护网立起来。
3. **T2 次之**——决定 Reference App 能用哪些控件。
4. **T3 最后**——它消费 T2/T4 的结论，产出演示与真实缺口。

## 风险

| 风险 | 应对 |
|---|---|
| CommunityToolkit 版本与 MAUI 11 rc.2 不兼容 | 先解析版本；不兼容则记录并降级为“源码包含”评估 |
| AOT 反射缺口 | 复用 `OpenHarmonySliceJsonContext` 模式补根；每例留红控 |
| SQLite/PDF 原生依赖 | 不在 Reference App P0 范围内；单独立项 |
| 设备被占用/端口漂移 | 遵守锁协议；用 `HDC→PATH→hdcp4` 回退链 |
| 切包链改动影响发布 | perf gate 默认只报告，strict 才阻断 |
