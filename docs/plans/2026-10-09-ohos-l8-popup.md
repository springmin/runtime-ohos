# L8-POPUP：ArkWeb `window.open` 弹窗子窗产品化（2026-10-09）

> 承接 L8-PROBE（可行形态 = `onWindowNew` 内零 await 同步 `new`+`setWebController`，controller 走页模块
> 静态导入；满容/失败一律 `setWebController(null)`）与 L7 N-SUBWINDOW（容量/开关同源）。载体 ow
> `feat/l8-popup`（从 `ab43ba2`；不并 master、禁强推）；maui 零改动；四包 byte-identical；#49–#53 资产
> 未动；#54 切包时按合并树一次重编/重锚。

## 1. 实现（壳四包 `Index.ets`/`SubWindow.ets`，零托管/宿主导出改动，导出 164/164）

- 主窗 overlay Web：`allowWindowOpenMethod(true)`；`onWindowNew` → `handleWindowNew`：容量
  （`subWindows.size + subWindowCreating.size >= subWindowLimit`，与 managed 同表）与 URL 白名单
  先行，通过则同步 `new WebviewController()` → `ShellPopupBridge.stash('web:N')` →
  `handler.setWebController(controller)`（零 await），随后异步建子窗/载弹窗页。
- 弹窗会话并入同一 Map：键 `web:N`、`kind=popup`、窗口名 `ohos_dotnet_webpop__web:N`；不发布 claim、
  不接 IME/a11y/child web、不进 managed 状态/关闭 wire；`findSubWindowSession` 只认 managed。
- 失败/满容/URL 拒绝：一律 `setWebController(null)`；`window.close`（onWindowExit）→ bridge →
  `closePopupWindow` → `destroyWindow` → 会话/桥条目清理；`onActivateContent` → 尽力 `showWindow()`。
- 弹窗页 popup 模式：按窗口名反查桥 controller；`multiWindowAccess(false)`；白名单 `http/https`+
  `about:blank`，长度 `navMaxUrlLength`。

## 2. 测试（离线）

- 套件：`w6` windowOpen pin 改 L8 语义 + 6 行 `l8 popup route/bind/close/capacityNull/nameReuse/
  isolation`（四包 + byte-identity）→ **checks=762 total=765 floor=745 assert=True**；红控三组
  （容量分支去 null 拒绝 → capacityNull=False；同步 bind 换占位 → bind/close/nameReuse=False；还原复绿）
  均抛断言 rc=134。
- `selftest-build-arkts-shell.sh` **207/0**；`selftest-verify-kit.sh` **129/0**；仓库门禁 8 项 PASS。
- abc 实测：ui **573,684 B / `2151fa2a…`**（原 552,876，+20,808）、headless 24,324 不变；四包
  abc+provenance 同步；EXPECT 重锚 573684（**供 #54 一次重编**）。
- 样例新增 `app://web/windowopenseq[/cap]`（hybrid A 内驱动全套弹窗序列并回传 raw message/HUD）。

## 3. 真机（HAD-W32 2in1 / OH 7.0.0.109 / API26；锁协议；JIT 件重签；证据 scratch `l8-impl/device6`、`device7`）

- **第二窗渲染/绑定**：`window.open` → `popup bound key=web:1` → `popup created id=3235`；弹窗截图/dump
  `L8 POPUP A READY`（p1a.jpeg、p1a-all.json）。
- **名称复用**：同名重开未产新窗，web:1 原地重写（dump 变 `L8 POPUP A2-REUSE READY`）；B 才拿 web:2。
- **`window.close` 关窗**：`popup closed key=web:1 remaining=1`、`web:2 remaining=0`；关后 dump 无弹窗
  （p1e，hosts 3）。
- **容量/共存（rawfile=4）**：3 managed（sub-1..3）+ C1 弹窗共存；第 4 窗请求
  `window.open rejected: subwindow capacity 4` + 主窗 HUD `C2 NULL REJECT`（p2a/p2b）。
- **主窗帧率**：弹窗期间 `framestats main … fps=60.0 long=0`（零回归）；无当日新 fault；hilog 16M→512K 还原、锁释放。
- **postMessage**：产品轮弹窗 HUD 无 `GOT PING-A`（写入型弹窗文档内联脚本未执行，两轮复现）→ 双向 postMessage 以 L8-PROBE（同壳机制，PONG 双向 PASS）为准。

## 4. 余项/边界

- 仅 2in1 debug 域（E1）；手机/release 未外推。弹窗 a11y 依赖 ArkWeb 内建；`isAlert`/tab-vs-popup
  未映射；弹窗 IME 走 ArkWeb 内建键盘。
- 环境发现：合并后的 maui 切片上，从深链 `PushAsync`/PushModal 新建页面不落地（web handler 不连接；
  C5 data 探针同样复现）→ 本样例改用 hybrid 触发；疑为切片/引擎回归，建议单独追因（不属 L8 壳改动）。
  未决：同名复用且弹窗非前置时 `onActivateContent` 触发条件（探针未捕获，已尽力实现）。
