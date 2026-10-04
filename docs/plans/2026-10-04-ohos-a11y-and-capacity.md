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
**判定：通过**（#44/#45 在途项「第 5 槽未真机点验」闭环：主动抢占→slot 0、Activate→恢复重放、活覆盖层 ≤4；
复跑同序）。**局限**：`hybrid overlay preempted/restored/replay` 原文未进 hilog——壳仅 12×3s 轮询 `dotnet-status.txt`
且 CEF stderr 冲刷 60 行尾窗；以 `hybrid assets slot=` + 覆盖层出现/消失 + invoke 回显闭环为判据，
登记待低噪声窗复取原文（不判失败）。

## 3) 产物与待办

- 证据：`/data/storage/el2/base/tmp/opencode/a11y45/{a11y-final,a11y-round2,cap-round,cap-round2,probe5,kit-signed}`；
  probe5 自建件 `70035b39…`（unsigned）/ `6e7c15fc…`（signed），重签 kit hap `3cf2576b…`。
- **测试方复跑指引（需读屏环境）**：本沙箱无读屏客户端（AMS `accessible=0`/client=0）——朗读/焦点顺序/动作类**不可测**；
  请带 **ScreenReader 环境**（真读屏机或读屏客户端）复跑 **T2 读屏开启态 / L1 Label 朗读 / N1 List / F2 滚动焦点保持 /
  E1 role** 等「无法测/部分」项，并按各卡回传截图 + hilog + `--a11y-probe` 两文件。
- **A11Y 按钮可达性**：**已修（FIX-A11YBUTTON，2026-10-05）**——按钮改左下角 Edges 绝对定位 +
  zIndex 覆盖层之上；有/无 web 控件两态真机可达（见 §4）。原「渲染于窗口中心且被覆盖层遮住、
  需 suspend/hide」的现状失效。
- 待办：低噪声窗取 `preempt/restore/replay` 原文；`nodeCount` 低值复核。

## 4) FIX-A11YBUTTON：壳自检按钮左下角 + 覆盖层之上（2026-10-05）

- **定位（复核 DEV-A11Y）**：按钮在 Stack 里用 `.align(Alignment.BottomStart)`——ArkUI 中该属性只对齐
  组件自身内容，Stack 子组件位置由容器 `alignContent` 决定，故实际落在窗口正中（旧 dump
  `[1522,987][1606,1033]`，窗口 `[515,281][2605,1675]`）；且 Web 覆盖层激活后持正 `zIndex`
  （`@State webZOrder`），按钮 zIndex=0 被盖（绘制 + 命中测试），需 suspend/hide 才可达。
- **修复（ohos-workload 壳；四包 22/23/24/28 + provenance 同步）**：按钮改 Edges 绝对定位
  `.position({bottom: 4+overlayBottomInset(), left: 4+avoidLeft})`（保 44x24 小尺寸、避让区感知），
  `.zIndex(webZOrderSeq+1)`；`webZOrderSeq` 改 `@State`（web 激活即刷新）。宿主/托管无改动。
- **壳 abc**：369,472 B / `a0dbad04…`（Index.ets 325,846 B / `7d971a5e…`；headless 24,324 B 不变），
  provenance `446f9215…`，源哈希 `483af84a…`。
- **真机两态**（HAD-W32 / OpenHarmony-7.0.0.109；重签 hap `da48f5c1…`，no-web 变体 `dea55136…`）：
  - 有 web 控件（Home，`rootWebArea=2`）：按钮 `[523,1622][607,1668]`（窗口相对左下 8/7 px，可达）；
    `uitest` 点按出对话框 `accessibilityStatus: 1 (attached - expected)` / `nodeCount=1`。
  - 无 web 控件（no-web 变体：web zone 不挂载，`rootWebArea=0`）：同 bounds 可达，对话框同读数。
  - 证据：`/data/storage/el2/base/tmp/opencode/fix-a11ybtn/device/{home-web,home-web-a11y,noweb-start,noweb-a11y}.{json,jpeg}`。
- **套件/导出/提交**：交互套件 FIX-A11YBUTTON 源钉随 `c31d077`（INTERP-DRAW2）并入（合流 591/593
  floor 573）；`verify-kit.sh` ui abc 期望 369472；宿主导出 151/151 不变；pin 未动；壳提交
  ohos-workload `e1d096a`（已推送 `origin/master`）。
- **不确定项**：本轮设备报 HAD-W32 / OpenHarmony-7.0.0.109（DEV-A11Y 轮记录 HAD-W24 / 7.0.0.111），
  按实际记录；`nodeCount=1` 与 DEV-A11Y 相同，仍待真读屏机复核；`selftest-tester-run.sh` 唯一失败项是
  「repo working tree unchanged」——运行中另有代理提交（c31d077）导致的工作树快照漂移，非本修复回归。
