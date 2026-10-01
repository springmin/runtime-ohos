# FIX-DISMISS：抽屉面板外点击不关闭——根因与修复（2026-10-01）

> 症状（UI-LOCAL-3）：hello-maui-app 抽屉（`Drawer`/`tap outside to close` + 灰面板）出画后，
> 面板外 click/drag/doubleClick 均不关闭；`keyEvent Back` 只把窗口收后台；触摸已投递（eid 0–9）。
> 本轮 scratch：`/data/storage/el2/base/tmp/opencode/fix-dismiss/`（harness、suite 日志、aot、device）。

## 根因
- 面板外按下 → `OpenHarmonyFlyoutPageHandler.FlyoutDismiss` → `flyoutPage.IsPresented = false`；
  MAUI `FlyoutPage.OnIsPresentedPropertyChanging` 在 `ShouldShowSplitMode` 为真时**抛**
  `InvalidOperationException("Can't change IsPresented when setting Default")`。
- `ShouldShowSplitMode` = 非 Phone idiom × `FlyoutLayoutBehavior.Default` × 显示方向 Landscape。
  本机 2in1：surface 2090×1324（idiom Tablet）+ 显示快照 landscape（orientation=1）→ 关闭被拒绝；
  开启（`IsPresented=true`）不受守卫 →「开得了、关不掉」；slice 只画 overlay 抽屉（无 split 版式）。
- 异常被 hosting 触摸回调边界（`OnTouchNative` try/catch → `touch callback failed`）吞掉：应用不崩、
  面板保持——与「外点无效、无崩溃」一致。headless 默认 display=0x0/Unknown 不进 split，套件此前全绿。
- headless 复现（harness 复刻本机显示条件）：未修复时外点 down 即抛上异常；修复后正常关闭。
- Back：`keyEvent Back` 由系统消费（`aa dump` state=BACKGROUND）；宿主/壳只注册触摸、无按键转发，slice 收不到。

## 修复
- maui-ohos `86b439ffc8`：`OpenHarmonyFlyoutPageHandler.ConnectHandler` 对默认 `Default` 改置 `Popover`
  （slice 唯一版式=overlay 抽屉；应用显式值不动）。外点走既有 dismiss 分支 → 托管 `IsPresented` 与
  平台 `FlyoutPresented` 同步写回 + 重绘。
- ohos-workload `d00cf7e`：交互套件 +2 FIX-DISMISS 断言（landscape 快照 + 非 Phone idiom：版式=Popover；
  开 → 外点 → 双 false）；`verifyCheckTotal` 544→546、floor 524→526（只增不降）。

## 验证
- headless：修复前在 FIX-DISMISS 断言处 exit 134（`behavior=Default popover=False` + 未处理异常）；
  修复后 `[suite] checks=546 total=546 floor=526 assert=True`。（并发 FIX-WVP 另行计数，见不确定项。）
- AOT 真机（本机 kit #37 线重发）：`hello-maui-app-fixdismiss-signed.hap` 21,626,170 B / `8d4968c9…`
  （hap 内宿主 `4e9f3c3e…` 293,792 不变；publish so 18,619,152 B；IL2026/IL3050/IL3051=0；rc.1 AOT pack）。
  - d0 冷启 home → d1 tap 汉堡 (545,381) 抽屉出画（整窗 50% scrim + 面板）→ d2 外点 (1500,900) **关闭**；
    d3 再开 → d4 外点 **再关**。像素：d0 vs d2 窗口 mean **0.0000**（无残影）；开(1/3) vs 关(2/4) mean 53.5。
  - hilog：eid 0–9 全投递；0 条 `touch callback failed`；未改宿主/壳。
  - Back（抽屉开）：d6 窗口收后台、`state=BACKGROUND`；`aa start` 后 d7 面板仍开（slice 无 Back 面）。

## 不确定项
- Back 关闭抽屉需宿主/壳新增按键转发（`onBackPress` + host 导出 + 桥事件），超出本切片，未纳入。
- 未改 pin：交互/像素/导出三处 CI pin 仍指 `68ec598037`；须按流程单独推进到 `86b439ffc8`
  （否则 interaction-regression 编译旧 tip 会在新断言处失败）。已 fast-forward push，未强推。
- 共享检出并发（FIX-WVP 同期改同一 `Program.cs` 与 packs）：本提交只含 FIX-DISMISS 行；最终计数以合并后重跑为准。
