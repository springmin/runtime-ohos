# HYBRID-SAMPLE：子窗 hybrid/Blazor 真机样例就绪（2026-10-08）

> 口径：ow `sample/hybrid-subwindow` @ `09d244b`（自 master `ca94b55`；**未并 master、未强推**；#49–#53 资产不动，上游 PR 不在本卡范围）；
> 样例 = **新增** `test/hello-maui-hybrid`（`test/hello-maui-app`/`hello-maui-razor` 默认行为不变）；设备 HAD-W32 @ `127.0.0.1:35111`。
> 闭环 `-l3-tail-fixes.md` ② 的"真机样例缺"余项；能力本身（子窗 hybrid/Blazor 资产桥 + B6 导航否决）POST-L3 已入主线，本卡只做样例与真机复证。

## 样例用法（`test/hello-maui-hybrid`）

- 主窗：一个 HybridWebView 探针（`MAIN-echo`）+ 子窗按钮；子窗：`openweb` = HybridWebView（`wwwroot/child-hybrid.html`，股票 `_framework/hybridwebview.js` + invoke/raw/host 自证）+ plain WebView（B6 探针链接），`openblazor` = BlazorWebView（`#app` 挂载）+ hybrid。
- 触发：`app://subwindow/openweb` · `openweb/b6/deny|ok|veto`（managed eval 自动点对应链接一次）· `openblazor` · `open` · `close`；探针全自动，一轮读 hilog 即可判读（脚本 `/data/storage/el2/base/tmp/opencode/hybrid-sample/round.sh`）。
- 构建/签名：`sh test/hello-maui-hybrid/publish-jit.sh`（JIT 真机轮）；`publish-aot.sh` 按 `test/hello-maui-app` 惯例备 AOT 路由 → `scripts/sign-for-device.sh <UDID> --unsigned ...`。
- Bundle 说明：保持 `com.example.hellomauiapp`（复用包内预编译 UI shell abc；换名需 `ARKTS_SHELL_BUNDLE_NAME` 重建 abc）；安装顶替设备上的 demo，轮后还原。

## 真机证据（JIT hap，2026-10-08 19:53–19:56；`hybrid-sample/round/`）

- 件：`hello-maui-hybrid-signed.hap` 125,972,772 B / `c509332c0b43…`（unsigned 123,481,235 B；`runtime-mode.txt=jit`）；install rc=0；签名轮换 `f75dfc91…` 前态 → 轮后还原。
- 子窗 hybrid（窗池 slot 0）：`child hybrid assets: origin=https://0.0.1/ root=wwwroot slot=0`、`child web serve hybrid (slot 0): https://0.0.1/` 与 `.../_framework/hybridwebview.js`、`subwindow page ready ... sub-1 gen=1`；页内回读
  `title='CHILD-HYBRID-INVOKED' probe='api-ok fw-200-text/javascript; charset=utf-8 origin=https://0.0.1 id=<docId> raw-endpoint-204' result='invoke-result:"CH1-echo:Echo:1"' host='host-received:child-hybrid-host-1'`；
  `child hybrid 1 raw: child-hybrid-raw-1..3`（`__hwvSendMessage` → RawMessageReceived）；子窗 plain web slot 1（B6 `nav ask (slot 1)`）。
- 子窗 Blazor：`child blazor assets: origin=https://0.0.0.0/ root=wwwroot mode=hybrid`、`child web serve blazor: https://0.0.0.0/`+`/_framework/blazor.webview.js`+`js/app.js`；回读
  `{"app":"BlazorWebView component\ncount: 0 …","dispatch":"function","blazor":"object"}`（挂载证据）。
- B6（同一子窗 plain web）：deny `nav ask (slot 1) → [maui] child web navigation cancelled → 应用 child web navigating → navigating cancelled: b6c-deny`，0 `cmd: nav`/0 批准；
  ok `ask → child web cmd: nav s1 → nav approved → child web error (DNS) → cmd: hide s1`（managed 决策即批准，`navigating` 行被 status 尾窗挤掉，非行为缺口）；
  veto `about:blank#blocked`、0 ask/命令/批准（`//host` fail-closed）。
- 主窗零回归（零改动代码 + 复证）：`main hybrid … result='MAIN-echo:Echo:1' host='host-received:main-hybrid-host'`；A1 pid 12419 / A2 pid 12756 各自开/关子窗恒定、WMS 1→0、`faults=0`（全轮 0 crash/fault/freeze）。
- 截图：`00-main`（主窗探针）、`01-child1-hybrid`（子窗 CH1 回读 + 背景主窗 MAIN 回读同帧）、`02-child2-blazor`（`origin https://0.0.0.0/` + bridge test 页）、`04-b6-ok`（openweb/b6/ok 轮）；deny/veto 截图被桌面控制台抢前台（B6 以 hilog 为准）。

## 分支 / 文档 / 提交

- ow `sample/hybrid-subwindow`：`09d244b` = `test/hello-maui-hybrid/**`（样例 17 文件 1718 行；新增、普通提交、无强推、未并 master）。
- 本页 → runtime `feature/openharmony`（`commit-paths.sh` 限定本文件 + `-l3-tail-fixes.md`）。

## 余项 / 不确定

- 单设备 2in1 debug（E1）域；AOT 样例脚本已备但本轮只跑 JIT 路由。
- 子窗 hybrid 与主窗同 origin（https://0.0.1/）的跨窗隔离以 echo tag/raw 行为证；截图为主窗/两子窗抽验。
- B6 deny/ok/veto 各占一次子窗启动（重载/拒载会替换子文档，无法同页串跑）；ok 的 managed `navigating` 行有状态尾窗丢失（批准链完整）。
