# DEEPLINK-REGRESSION：合并后深链新建页面不落地追因（2026-10-09）

> 症状：主线（ow `ab43ba2`/maui `4fa0170900`）真机（HAD-W32/OH 7.0.0.109/API26/2in1）静默应用里 `app://` 深链
> Push 的新页不落地（C5 `app://web/datahash`；L8 windowopen 同族）；activation 链正常。设备互斥、件重签、
> #49–#53 资产不动；复现脚本/原始证据 = scratch `/data/storage/el2/base/tmp/opencode/dlreg/`（不入库）。

## 1) 复现边界（A/B/C/D 阶梯，`device-probe2.sh`：status+hilog+截图）

- A 冷启静默 15s 后触发 `app://web/datahash`：**45s 不落地**（无 `main data probe hash=… title=`，无
  `web slot defer: 2`/`web page (slot 2)`）；App 侧 `main data probe open: hash=True` ⇒ 路由/`PushAsync` 已发起。
- B（裸 `aa start`）/C（`subwindow/max/2` 仅改环境）均不解阻；D（`subwindow/open`→建窗）**0s 落地**（同刻出现
  `slot defer: 2 data`+`web page (slot 2): data:…MAIN-DATA-HASH`）。结论：**卡在新页 arrange/handler connect**。

## 2) 二分（同探针/同设备会话；✗ = 45s 不落地，[D] = 开子窗后落地）

| 件 | 壳 abc | maui 切片 | A 自落地 | [D] |
|---|---|---|---|---|
| l4new（08 日旧件，今日复跑） | L3L4 550,304 | preprobe-merge（≈`619c40a4`） | ✗ 26s | ✓ |
| l4old（08 日旧件） | E4 548,192 | preprobe-merge | ✗ 26s | ✓ |
| mainline | merged 552,876 | `4fa0170900` | ✗ 45s | ✓ 0s |
| m53shell（差分重签） | kit53 542,936 | `4fa0170900` | ✗ 45s | ✓ 0s |
| k53maui | merged 552,876 | `caa463434b` | ✗ 45s | ✓ 0s |
| k53both（差分重签） | kit53 542,936 | `caa463434b` | ✗ 45s | ✓ 0s |
| fix（maui `9f2b1b06df`） | merged 552,876 | `4fa0170900`+修 | **✓ 0s** | — |

- 壳非因（m53shell 同）；maui 侧旧切片同病（k53maui/k53both）；08 日预合并件今日同病 ⇒ **非 BATCH-MERGE 引入**，
  系 kit #45 INTERP-RENDER 布局门起潜伏、被 C5/L8 新探针暴露的切片缺口。
- WebAuth 的 Want 字面量修复与本路径无关（激活已 `delivered=1`）；L7 只改子窗上限，不涉主窗 Push。

## 3) 根因（maui 切片）

- `OpenHarmonyNavigationPageHandler.Invoke(RequestNavigation)` 只做 `NavigationFinished`+`RequestRedraw`：不 arrange、
  不发布局失效信号。渲染器布局门（`OpenHarmonyWindowRenderer.NeedsLayout`）只在 `OpenHarmonyLayoutInvalidation.Version`
  变化/根 `MeasureInvalidated` 时重排；真机 Push 路径（onNewWant 回调线程）两者都未产生可达信号 → 新页未测量/未 arrange
  → `OpenHarmonyContentArrange.ConnectTree` 不跑 → WebView handler 不连接（无 slot 请求）。任意无关布局指令（建子窗）
  跳变**进程级**版本 → 主窗下一帧补排才上屏；B/C 不产生布局指令，故不解阻。

## 4) 修复（最小）与红绿

- maui `fix/deeplink-regression` `9f2b1b06df`：`RequestNavigation` 分支 `NavigationFinished` 后补
  `OpenHarmonyLayoutInvalidation.Mark()`（一行+注释）→ 下一帧重排→descend→arrange→handler 连接。
- 真机修后 A 0s 落地（`fix A: EVAL after 0s`）：`delivered=1`→`slot defer: 2 data`→`web page (slot 2)` 仅 ≈100ms；未修件同序列须等 D 的建窗布局指令（≈90s）；B/C/D 无新增长、eval `p='tag#value'` 完整。
- 离线：ow suite pin `deeplink push marksLayout=False→True arrangedOnRender=True`（ow `4d7a18a`，suite 757/760
  floor 740）；未修/修后整套 `assert=True`、0 Unhandled。

## 5) 余项 / 不确定

- `PushModalAsync`（L8 windowopen 现用绕行）是否同缺未系统验证；本修只覆盖 NavigationPage 的 RequestNavigation。
- 真机根 `MeasureInvalidated` 未达渲染根（回调线程/门闩次序）未定位，`Mark()` 属等价兜底；CI `MAUI_OHOS_REF`
  指新 tip 属合并动作（本 session 不做上游 PR）。
