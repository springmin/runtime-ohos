# L8-REMAINDER：postMessage 产品双向 + PushModalAsync 落地 + hybrid AOT 真机轮（2026-10-10）

> A 组（L8 余项 + B6/hybrid AOT）。主线 ow `01b426e` / maui `14cc245902`；载体 ow/maui `fix/l8-remainder`
> （ow `373bee0` 2 提交 / maui `31ed839fd6`；不并、禁强推）；#49–#53 未动。真机 HAD-W32/OH 7.0.0.109/API26
> （本轮 hdc 端口 36823；锁协议）；证据 scratch `l8rem/`、`hybrid-aot/`。

## 1) A1 postMessage：根因 = 样例写弹窗的字符串（非壳缺陷）+ 真机双向

- 根因（device6/7 旧件 hilog 定死）：两 writer（sequence/raw）都把 `n` 以字面量写进生成的 `<script>` → 弹窗
  听消息抛 `Uncaught ReferenceError: n is not defined`（4 处），HUD 恒 READY、无 PONG、20 s close 未跑。
- 修（ow `ba15c7f`+`373bee0`）：两 writer 统一 `__L8N__` 占位符于 PD() 调用期 `split/join`；title 带名；
  加 `A TITLE=` window-proxy 回读；套件源 pin 覆盖两 writer、拒裸 `n` 旧形（红控 → `placeholder=False`）。
- 真机 PASS（`l8rem-device2.hap` 134,827,262 B/`0fa1b548…`）：windowopenseq `L8-GOT PONG-A PING-A` ×2、
  `A TITLE=L8POP-A` ×2、reuse ×4、auto-close ×2、ReferenceError=0；windowopen 模态路
  `windowopen hud: "MAIN GOT PONG-A PING-A` ×4、hud `A TITLE` ×3、auto-close、ReferenceError=0。
- 红控（同轮切 pre-fix `l8-default.hap`）：GOT=0 / 标题=0 / `ReferenceError: n` ×4。

## 2) A2 PushModalAsync：deeplink 的 `Mark()` 不覆盖 modal，且渲染根不跟随（两层）

- 结论：`Mark()` 仅在 `OpenHarmonyNavigationPageHandler.Invoke(RequestNavigation)`，modal push 不走；
  且 host `Render()/Arrange()` 一直用 `_window.Content`，从未渲染 modal-aware `RootView` → 弹窗页即使被
  mark 也永不 measure/arrange（真机 windowopen “modal push ok”但不落地）。
- 修（maui `31ed839fd6`）：`Render()/Arrange()` 走 `RootView`（渲染前 `ConnectTree(root)`）；订阅
  `Window.ModalPushed/ModalPopped` → `Mark()`+`RequestRedraw()`；`HasAnimations` 同看 RootView。
- 套件 pin：真实 PushModalAsync → `marksLayout=True arrangedOnRender=True assert=True`（缺失即抛）；红控
  （stash 修）`False/False` rc=134；套件 **765/768 floor 748 assert=True**（含 A1 源 pin）。
- 真机：模态路落地（`web slot create: 2`+`web page (slot 2)`+HUD 轮询 10 次+`popup bound/created`）；
  pre-fix 同轮 `modal push ok` ×7 但 hud=0/bound=0（复现）。

## 3) B6/hybrid AOT 轮（真机 PASS；对照 JIT 轮）

- 件：`test/hello-maui-hybrid`（09d244b 样例代码）在 current mainline 树构建（旧分支 csproj 与现 slice
  不兼容，样例本身不变）：unsigned 30,855,250 B / signed `hello-maui-hybrid-aot-device.hap`
  31,208,671 B/`77211df9…`；`runtime-mode.txt=aot`、`libhello-maui-hybrid.so` 19,278,576 B/`baf3ea28…`；
  IL2026/IL3050/IL3051=0。
- 真机：每相冷启 `OHOS_HOST start_app aot dlopen now=ok`；主窗 `MAIN-echo:Echo:1`+
  `host-received:main-hybrid-host`+raw（零回归）；子窗 hybrid `CH1-echo`+host+raw、Blazor 挂载
  （`blazor.webview.js`+`BlazorWebView component`）；B6 deny ask=1/0 cmd/0 批准、ok ask→`cmd: nav s1`→
  approved→error(DNS)→hide、veto `about:blank#blocked`/0 ask；wms 1→0、faults=0、轮后还原。

## 4) 未决 / 边界

- 设备 09:16 reboot 后 hdcd 缺席；10:04 新端口 36823 恢复后完成。scratch 复制+自签名（ohos-selfsign）+UDS
  路径/参数门补丁（`hdcpatched/hdcp4`）；LD_PRELOAD 被平台忽略；端口随 boot 漂移需重扫；仅 2in1 debug（E1）。
- deny 的 managed `navigating cancelled` 行本轮未捕获（ask→0 cmd/0 批准链齐全）；pre-fix 基线同轮已复现。
