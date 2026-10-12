# SUBWIN-COMPLETED：子窗 ENTER→Completed 可观测闭环（2026-10-12）

> 触发 = `2026-10-12-ohos-keyboard-input-check.md` 边界（ENTER 后未观测 TextSubmitted→Completed）。
> 载体 = ow `feat/subwin-completed` `34bcaa4`（自 `d7df09c`，验证绿后 ff 并 `master`，分支保留）；**maui/shell 零改动、abc 不变**。

## 1. 定因 / 实现面 / 离线

- 路径（两条都已随 #54 发货）：主窗 = 壳 `Index.ets onSubmit` → `notifyTextSubmitted` →（仅主窗）
  `OnTextSubmitted` → `entry.Completed()`；子窗 = 壳 `SubWindow.ets onSubmit` →
  `SUB_EVENT_TEXT_SUBMITTED(15)` → `OnSubWindowChanged` → `WindowInputRouter.DispatchSubmitted` →
  port → 同一 `OnTextSubmitted`（`IEntry.Completed()`→`SendCompleted`：Completed+ReturnCommand）。
- 缺口 = 探针：样例子窗 Entry 只有 TextChanged、无 Completed 处理器（主窗有）。修
  `test/hello-maui-app/App.cs`：加 `Completed` → label `child entry completed: {text}` +
  WriteStatus（与主窗同构，语义未分叉）。
- 套件 pin `test/maui-platform-verify/Program.cs`：`input submitted contract`（args=EventArgs.Empty
  + ReturnCommand 恰一次）、`input submitted red control`（未知 surface 不置完成）、`input
  submitted source pins`（四包 `SUB_EVENT_TEXT_SUBMITTED`+`.onSubmit(` + 样例钉）。
- 红绿：先落 pin、样例未改 → source pin `assert=False`、rc=134；改后 801/804 floor 784 rc=0。

## 2. 真机（HAD-W32 锁独占；JIT hap = ow `34bcaa4`+maui `44dcef8d15`，`-p:OpenHarmonyUIPage=pages/Index`；证据 `subwin-completed/ev/`）

- 子窗 Entry 聚焦（`sub-1__input focused=true text='seed'`）→ `uinput -K -d/-u 2054`（内核虚拟键盘
  = 物理 ENTER 同路）→ 应用进程 `AceTextField PerformAction 6 / On submit / onSubmitComplete`。
- **Completed 直证**：自绘 `child entry completed: seed`（`crop-child-fresh.jpeg`）+ 状态文件重启
  镜像 hilog：`subwindow event TextSubmitted ... text='seed'` + `child entry completed 'seed'`
  （12:30:27.845）。
- 主窗不回归：主隐藏输入聚焦后 ENTER → `PerformAction 6 / On submit`（12:24:59）；双窗 `canvas
  presented`+framestats 50–60fps；fault diff=0。恢复：`l7m2-s2.hap` 回装 + 子窗/聚焦态还原、
  hilog 512K、锁释放。

## 3. 回填 / backlog

- runbook #55 条目旁注"已修（`34bcaa4`）"，#55 不带该边界；abc 无变化、套件 total 804。
- 不确定项：主窗 `status` label 越出最大化窗可视区（主窗 Completed 直读 UI 未重现，以 `On
  submit`+离线 pin 为准）；子窗镜像回放依赖重启（壳启动后仅 12 次 poll）——既有机制。
