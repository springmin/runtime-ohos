# UITEST-INJECT-IMPROVE：IME op6 / Back / B6 `//host` 注入面复核（2026-10-11）

> 口径（测试侧，尽量闭合）：不构建、不改产品代码、#49–#53 资产不动、上游 PR 不在本卡。设备 HAD-W32
> 2in1 / OH debug 域（E1）；hap=设备现状（未安装/未改；轮末 app 停、WMS 子窗 0、锁与 hilog 缓冲还原）；
> 证据 scratch `uii/`（不入库）。注入面盘点（实测）：`uitest uiInput` click/doubleClick/longClick/fling/
> swipe/drag/dircFling/inputText/text/keyEvent（`text`=API≥18 免坐标直发）+ `uitest dumpLayout`（节点
> bounds=物理像素、与 uiInput 同系；可按 bundle/窗口归属过滤）+ `aa start` 前台化 + IME 直发（managed
> op6 焦点通道）+ `uinput`（`/system/bin/uinput`：`-K -d/-u/-l/-r/-t`、`-M` 鼠标（相对移动/`-c` 点击）、`-P`）。

## 1. 结果

| 项 | 结果 | 关键证据（`uii/`） |
|---|---|---|
| IME op6 直点 | **闭合**（op6 链捕获 + 切窗互斥） | click 子窗 Entry（窗 rect 左上+(338,198)）→ `subwindow text input focused` + `text focus forwarded: surface=sub-1 gen=1 show=1 caret=0`；点 sub-2 → `text blur forwarded: surface=sub-1 (focus moved)` + `surface=sub-2 gen=2 show=1`（`imeA/imeB`；`dumpLayout` 隐藏 `sub-N__input` 独立复核同点） |
| Back `window back` | **边界**（平台路由；非纯 uitest 之限） | `keyEvent Back`/`2` 注入成功（`InjectKeyEventSequence keycode:2`）且达子窗节点（`AceFocus 100001 TextInput/page return:0`）但 `consumed:0`、无 `onBackPress`；`BACK`=无效参数；ESC=仅 blur 输入；`dircFling` 只移焦点；边缘 swipe 无动作；`uinput -K -d 2` 同路；主窗持焦时 Back=应用后台化（`main window hidden`）——**皆 `window-back=0`**（`backA–F/backMain/backChild/exuB`） |
| B6 `//host` 点选 | **闭合**（干净指针证据 + deny/ok 同轮再证） | `//host` 链接（app 子窗内；控制台窗 x≥2605 不重叠）点选 → Chromium `userGesture:1` → `about:blank#blocked`（页变 blank：`eval='no-title' tap='NO-H'`）；**0 ask/0 cmd/0 批准**；deny=1 ask/0 cmd/0 批准；ok=ask→`cmd: nav s0`→`nav approved`→DNS `error`→`hide`（`b6-*` + before/after 截图） |

## 2. 尝试矩阵（路径 × 结果）

- IME：①WMS rect+偏移直点 ✅ ②`dumpLayout` 隐藏输入节点定位=同点复核 ✅ ③`uiInput text/inputText` 仅 caret（0→4）无文本事件 ✖ ④逐键 `keyEvent 2042/2009` 达子窗但 `return:0/consumed:0` ✖ ⑤`uinput -K -t` 无事件 ✖ → 焦点链闭合；**文本实敲**仍人工卡。
- Back：①`Back`/`2` ②`BACK`（无效）③ESC ④`dircFling 1 2500` ⑤边缘 swipe ⑥`uinput -K -d/-u 2` ⑦主窗 vs 子窗持焦对照——均无 `window back`/`SUB_EVENT_BACK`；键去向=子窗 `return:0/consumed:0`（平台不转 `onBackPress`）或主窗→能力层后台化。
- B6：①指针点选 deny/ok/veto ✅（app 窗归属过滤 + 每步前台化）②程序化样例（历史 hybrid `openweb/b6/veto` eval）旁证 ✅。

## 3. 边界 / 不确定

- **Back=平台边界（关键结论）**：KEYCODE_BACK 达 app 子窗后被吞（节点 `return:0`、窗 `consumed:0`），平台不调用 ArkUI 子页 `onBackPress`、亦无默认动作；主窗持焦时走能力层（app 后台化）。系统级键注入（uitest/uinput）无面可达子窗 Back → `SUB_EVENT_BACK`/managed `window back` 注入不可达；通道级归属/路由保持离线 pin。
- **`//host` 机理**：`data:` 文档中网络路径引用在引擎层即被替换为 `about:blank#blocked`（全程无 `//evil.invalid/x` 请求/ask，未达壳/managed 网关）；设备证据=结果级 fail-closed（无批准泄漏），网关级 H-C2 拒载=离线 `b6c` pin（设备通道级样例不可达）。
- IME：注入文本/键不产生子窗文本事件（仅 caret/焦点）；实键盘/软键盘实敲=剩余人工卡（按 #50 子窗 IME 卡执行）。
- 仅 2in1 debug 域、单轮；结论不外推手机/release。

## 4. 文档 / 提交

- 更新 `2026-10-05-ohos-platform-limitations.md`（E5 ④/⑤/⑥）+ 本文件 + `README.md` 索引 + `2026-10-11-ohos-unsupported-recheck.md` E5④ 指针 → runtime `feature/openharmony`（`commit-paths.sh` 限路径；直推，被拒 fetch/rebase + 旁路钉，不 force）。
