# 剩余项复核（REMAINING-AUDIT-FINAL，2026-10-10）

> 口径：轻量只读落档（读文档/读码/stdout 复核；不构建、不用设备、不处理上游 PR）。基线 = ow `01b426e` · maui `14cc245902` · runtime `e1e499401e4`（abc 574,336/`930c3efd…`、套件 763/766 floor 746、导出 164/164；#49–#53 资产未动）。前序：`2026-10-08-ohos-maui-coverage-gap-audit.md`（Top-10）· `2026-10-05-ohos-platform-limitations.md` · `2026-10-03-ohos-state-of-the-port.md`。

## 1. 已闭环（10-08 后，简记）

- **已并主线**：PREPROBE-SWEEP（maui `619c40a483`）· SEC7-A（`b914379269`）· WebAuth 真流程含 Want 对象字面量修复（ow `b49ea76` + maui `2803e15b6c`）· E4 默认 8（ow `adf2efb`）· L3/L4 = C5 裸 `#` 缓解 + SEC7-F ask 限速（ow `e6e4f41`）· L5 SEC-5c E/F（maui `6f278ee99b` + ow `95e4a68`）· L7-M1 N 上限开关（ow `343fc21`/`8b6d4073cb`）——以上随批合并 `15f3dc8`。
- **MERGE-BATCH-2 入线**：L8 弹窗 `window.open` 子窗（ow `8ee536a`）· harmony-flavor 运行期 free-window 探测（ow `91eb4fd`；workflow `37945657194` 绿）· deeplink 布局修复（maui `9f2b1b06df`→`14cc245902` + ow `4236f0b`）。
- **分支（离线绿，未并）**：L7-M2 N=4 + defer 前台重放（`feat/n-subwindow-m2` `ee9514358dfc`；套件 766/769 floor 749、abc 576,664）；L8 余项 + B6/hybrid AOT（`fix/l8-remainder` ow `373bee0`/maui `31ed839fd6`；10-10 10:29 分支真机 PASS）。
- **裁决/卫生**：w2b-int/w2b-t3t5 确认删除（无独有载荷；`2026-10-10-ohos-w2b-disposition.md`）。

## 2. 未完成（分组）

**a) 设备待验（脚本/件已备）**：① **L7-M2 矩阵/soak**——设备 10:36 起恢复，已由并行 session 开轮（boot rawfile=4 → `capacity: 4` 已过、1/2/4 窗内存曲线进行中；矩阵含 churn×20 / 40 min / 每窗帧率，结果未落档；脚本 `…/l7m2/l7m2-round.sh`）。② **WEBAUTH 隐式投递**——未判定（≠失败）；构造/脚本就绪（`…/webauth-implicit/`）。③ **L8 余项/B6-AOT**——分支真机已 PASS（余 1 行 deny managed `navigating cancelled` 未捕获）→ 待并入 #54 后随切包轮复跑/重锚。④ **L8-POPUP 余项**——同名复用且弹窗非前置时 `onActivateContent` 条件未捕获（已尽力实现）。
**b) 可本地做**：无新增代码项（本地可执行队列已清）。仅文档尾：`platform-limits` §E4「默认仍 4/2」已过时（默认 8 已随 `adf2efb` 并）；coverage-matrix 头注可刷新（低优先）。
**c) 平台阻塞（编号）**：C1 · B1 · A3–A6 · E3 · TTS/Map/Share（SDK26/HMS）· E5 残余（a11y 动作 e2e / hybrid-blazor 样例 / B6 `//host` / IME 实敲）· Hot Reload（hdc）。
**d) 测试侧（tester/人工卡）**：kit #53 回传（a11y `nodes=10` / B6 / N=2 / 门禁 737/740·164）· 子窗 a11y 动作 e2e · IME 实敲 · uitest Back/alert 注入 · B6 `//host` z-order。
**e) 外部**：rc.2 正式包 → #54 换 pin/切包（10-10 复核仍 WAIT，见末行）· AGC（ACL 提交、App Linking 域名/domainVerify）· tester 轮回传。
**f) 本 session 排除（上游）**：dotnet/runtime PR（#135321 等）· 17 支 `pr/*` 重锚 · MAUI 上游并入 · `#18 ship-the-slice` 平台矩阵。

## 3. 结论

- 覆盖矩阵 **20 项 = 16 全闭合 · 2 部分（均上游：#11 键面 / #18 ship-the-slice）· 2 平台（#13 C1 / #15 SDK26）**；10-08 后新增闭合 = WebAuth 真流程、L8 弹窗、deeplink、harmony-flavor、E4 默认 8、L7-M1、L3/L4、L5、PREPROBE、SEC7。
- 完成度 **≈99%**（本地/离线面；唯一功能缺口 WebAuth 已闭）。**本机还剩什么**：无未做的本地代码/离线验证任务——只剩设备轮回填（L7-M2 进行中、WEBAUTH 隐式）+ L8 余项/B6 分支并入 #54 + tester/AGC/rc.2 外部项。
- rc.2 监测（2026-10-10 实跑 `rc2-official-watch.sh`，exit 0）：**status: WAIT** —— nuget 四包 latest `11.0.0-rc.1.26451.6`（trigger=no）、GitHub `11.0.100-rc.1.26458.5`（trigger=no）。
- 不确定项：设备链路/端口随 boot 漂移（10:36 已恢复，见 §2a①；本 session 未触设备）；L7-M2/L8-REMAINDER 未并主线，数字以分支文档为准。

> 提交：本文件 + `README.md` 索引 → runtime `feature/openharmony`（`commit-paths.sh` 限路径；直推，被拒 fetch/rebase + 旁路钉 `140.82.113.3`，不 force）。
