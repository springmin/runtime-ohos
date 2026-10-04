# a11y 真机全轮 + 第 5 控件超容量（kit #45，2026-10-04）

> 设备 HAD-W24 / OpenHarmony 7.0.0.111 / API26（UDID `1BCE13C8…AEA0`），hdc `127.0.0.1:35111`；全程串行持有
> `/data/storage/el2/base/tmp/opencode/.device-lock`。只验证/采集，未改壳/托管源码。件：本地重签 kit 主 hap
> （AOT，abc `1076a700`、宿主 `7b1694d9`，`a11y45/kit-signed/hello-maui-app-local.hap`）；probe5 = 样例加 D/E 两枚
> HybridWebView（5 控件，自建 NativeAOT，`a11y45/probe5/probe5-signed.hap`）。
> **环境限制（如实）**：本沙箱**无读屏**（AMS `accessible=0`、client=0；bundle 仅 screenrecorder/screenshot）
> → 朗读/读屏焦点/双击激活类项只能「无法测」；A11Y 按钮在本沙箱渲染于窗口中心且被 ArkWeb 覆盖层遮住，
> 经抽屉（suspend）或切 tab（hide）后可点。

## 1) a11y 全轮（16 项，逐项）

| # | 结果 | 证据 |
|---|---|---|
| B1 自检基线 | 通过 | `accessibilityStatus: 1 (attached - expected)`、`nodeCount=1`（Home+抽屉态与 Animations 态各一次；`a11y-final/f5-home-dialog.json`、`a11y-round2/t3-dialog.json` + 截图） |
| E1 Entry | 部分 | 点击聚焦（橙色 focus ring，`a11y-final/f7-entry-crop.png`）；自动化输入未上屏（沙箱 IME 桥，非产品判定）；role/朗读无法测 |
| L1 Label | 无法测 | 无读屏；文本正常绘制（截图） |
| B2 Button | 部分 | 单击/双击各恰好 +1（Count 0→2，`f1/f2.jpeg`）；读屏 CLICK 动作路径无法测 |
| C1 CheckBox / S1 Switch | 无法测 | 控件在窗口折叠下方不可达（页面不滚动，无入口） |
| I1 Image | 未测（本包无入口） | 样例无 Image 控件 |
| N1 List | 无法测 | 列表不可达 + 无读屏 |
| W1 WebView | 通过（宿主侧） | 5 个 ArkWeb 页的 `rootWebArea/heading/button` 进 uitest dump（c1–c8）；DOM 不进影子树 = 已知边界 |
| M1 弹层焦点陷阱 | 部分 | 弹层节点齐（AlertDialog/标题/正文/OK）；外点由弹层消费（背景 Count 不触发、弹层关闭）；OK 关闭后恢复操作（f6，覆盖层回到 webareas=2）；读屏焦点不逃逸无法测 |
| M2 自绘弹层 | 未测（本包无入口） | — |
| F2 滚动焦点保持 | 无法测 | 需读屏；列表不可达 |
| T1 读屏关闭态 | 通过 | 普通触摸全功能：Count 0→2、Home/Animations 切换、抽屉开/关、弹层开/关、无崩溃；provider 保持 status=1 |
| T2 读屏开启态 | 无法测 | 沙箱无读屏客户端（AMS 证据见上） |
| T3 TabbedPage 当前页 | 部分 | 切 tab `hide` → 覆盖层 0，切回恢复（webareas 2→0→2）；影子树逐页读数无法区分（两态均 1，疑沙箱无客户端所致） |
| N4 Window.TitleBar | 未测（本包无入口） | 样例不设 TitleBar |

**通过 3 · 部分 4 · 无法测 6 · 未测 3（未过 0）**。`nodeCount=1` 低于 #36 记录的 5/24，登记待真读屏机复核
（本沙箱无 a11y client + INTERP-RENDER 门控为嫌疑）；`[openharmony-host] accessibility` 行本机未出现
（ArkUI 无 client 时 `Not register native accessibility`），status 读数取自壳自检导出。

## 2) 第 5 控件超容量（MAX=4）

时序（`a11y45/cap-round`，probe5 真机）：A/B 热对（slots 0/1）→ C `web slot create: 2` → D `web slot create: 3`
→ **加 E（第 5 控件）→ E 领 slot 0（`hybrid assets … slot=0`），A 覆盖层消失（suspend；c3 截图顶区空白）**
→ D/E 交互回显 `invoke: "D-echo:Echo:1"`、`"E-echo:Echo:1"`（c4 dump）→ **Activate A → A 领 slot 1
（`slot=1`）+ 页面恢复、B 被抢占消失**（c5 截图/JSON）→ 移除 D `web slot destroy: 3` → 重挂 `web slot create: 3`
（c7/c8）。全程活覆盖层 ≤4（dump `rootWebArea=4`）、`web capacity: 4`；复跑（`cap-round2`）同序复现
（assets slots 0,1,2,3,**0**,**1**）。
**局限**：`hybrid overlay preempted/restored/replay` 原文未进 hilog——壳仅 12×3s 轮询 `dotnet-status.txt`
且 CEF stderr 冲刷 60 行尾窗；以 `hybrid assets slot=` + 覆盖层出现/消失 + invoke 回显闭环为判据，
登记待低噪声窗复取原文（不判失败）。

## 3) 产物与待办

- 证据：`/data/storage/el2/base/tmp/opencode/a11y45/{a11y-final,a11y-round2,cap-round,cap-round2,probe5,kit-signed}`；
  probe5 自建件 `70035b39…`（unsigned）/ `6e7c15fc…`（signed），重签 kit hap `3cf2576b…`。
- 待办：真读屏机复跑 B1–T3 的「无法测/部分」项；低噪声窗取 preempt/restore 原文；`nodeCount` 低值复核。
