# FIX-ITOUCH：uitest 注入触摸→MAUI 内容无响应——根因与修复（2026-10-01）

> 症状（UI-LOCAL-2）：uitest `uiInput click/doubleClick/longClick` + Tab/Space/Enter 点「Run animations」0 变化；
> 事件已投递（`TTHNI page→XComponent`、`Consumed`）；同窗底部 tab 栏注入点击有效、真鼠标点同一按钮有效。
> 本轮 scratch：`/data/storage/el2/base/tmp/opencode/fix-itouch/`（exp1–exp5 脚本、诊断件、K0–K7 截图、hilog）。

## 根因（注入 vs 鼠标的差异 = 坐标系）
- host `OnTouch` 用 `OH_NativeXComponent_GetTouchPointWindowX/Y` 上报坐标。自由窗口（2in1）的
  “window” 系含页面之上的系统标题栏（本机 70 px = 窗口 1394 − 画布 1324），而 XComponent/MAUI
  画布与鼠标事件（`MouseEvent.x/y`）在 **element（surface）系**。
- 诊断件（`[touch-diag]`，临时插桩）实测同一注入点：`disp=(1560,719) → win=(1045,438) → elem=(1045,368)`，
  即到达 MAUI 的坐标整体下移 70 px；小面积有界控件（绿色按钮 surface y≈334..403）被点在其下方 35 px → 不命中。
- 底部 tab 栏“仍可用”是巧合：`TabIndexAt` 只判 y ≥ 栏顶（无上界），win/屏幕系坐标照样命中 →
  形成“tab 能切、页内不能点”的假象；真鼠标走鼠标回调（element 系）故从未错位。
- 实拍坐标证据（探针）：旧件下 `(1560,660)` 命中按钮、绘制位 `(1560,719)` 反而 miss —— 偏移恰为一个标题栏。

## 修复
- ohos-workload `30d2adf`：`OnTouch` 改读 touch point 自身 `x/y`（element/surface 系，与鼠标同一空间），
  changed-pointer 主坐标与 pinch 中心一并归一；`openharmony_host.h` 契约注释同步（window 访问器不再使用）。
- 套件 N1 native pin 加固（要求 element x/y 读取、禁止 `GetTouchPointWindowX(component`）；无新增行 →
  套件 `544/544 floor 524`（≥540/520，只增），导出契约 `149/149`，build-host 门禁（DT_NEEDED/UND/149 导出）全过。
- 未改 pin、未改切片（maui-ohos 0 变更）。

## 真机验证（本机，kit #36 线 AOT 基座 + 修复宿主重打包 `fix1.hap` 21,626,085 B / `c5cf86e8…`）
- 注入 `(2030,1650)` 切 Animations → 页内出画（K1）；偏靶探针 `(1560,660)` **0 变化**（K3）；
  绘制位 `(1560,719)` → **“tap the button”→“fading out…”（K4, 0.6 s）→“animations done”（K5, 3.1 s）**；
  `(1030,1650)`→Home、`(2030,1650)`→Animations 往返正常（K6/K7）。
- hilog：4 次注入均 `HandleInputEvent eid 0..9 / TTHNI page→XComponent / Consumed`（与修复前同路径，差异只在载荷坐标）。
- headless：`[suite] checks=544 total=544 floor=524 assert=True`，0 Unhandled；修复宿主 `4e9f3c3e…`（原 `cfbbe461…`）。

## 不确定项
- 正式发布线需按流程重编宿主/重打包（本轮 `fix1.hap` 为验证件；kit #36 发布件不变）。
- pinch 中心改用 element 系未上机复核（与主路径同源、仅坐标系归一；双指未注入）。
- 真触摸屏设备未复测（2in1 无触摸；注入语义现与鼠标/element 一致）→ 复测按 K1–K7 序列一键复核（可复用 `exp5-fix.sh`）。
