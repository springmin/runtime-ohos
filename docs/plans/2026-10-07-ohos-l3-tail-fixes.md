# L3-TAIL-FIXES：a11y 分区清理 + 子窗 hybrid/Blazor 资产桥（2026-10-07）

> 口径：两线均从 ow `master` `696ebc0` / maui `feature/openharmony` `bb6b06990d` 切出；**未并 master、未强推、#49/#50/#51 资产不动**。
> 分支：ow `l3/a11y-cleanup` @ `19e8cb7`、`l3/web-assets` @ `fc186bf`；maui `l3/a11y-cleanup` @ `70b279548a`、`l3/web-assets` @ `4b9598d9f3`（均本地分支；推送时远端不可达，无强推）。
>
> 2026-10-08 复核：①/② 均已随链并入主线（ow `master` `0685d7b`、maui `feature/openharmony` `277967cc56`）；② 的子窗 hybrid invoke 槽路由在 M4 升级为窗口位
> （`TryDecodeChildInvokeRequestId(windowIndex/slot/seq)` + `ChildHandlerForWindow`，见 `-l3-m4.md`），壳 abc 534,192/`e6516424…`；下方 508,832/`9952229b…` 为切出时口径。

## ① a11y 分区清理（ow + maui，小）——SEC6-C 余留闭环

- 修复：`host_a11y_table.c` 新增 `ohos_host_accessibility_table_release`（表锁内摘链并释放节点串/数组），`host_napi.cpp` 新增导出
  `ohos_host_accessibility_release_for`（导出 163→**164**）：释放该窗命名分区（8 槽 cap 归还）+ 重置 per-instance NAPI 注册态
  （provider/customNode/content=null、status=0；记录保留以维持 `A11yInstanceProviderFor` 的指针稳定，重开同 id 建新 CUSTOM 节点）。触发 = 既有窗关闭 hook
  `OpenHarmonyAccessibility.ReleaseWindow`（maui）→ `ReleaseProviderState`（探测新导出，旧宿主仅 managed 释放）。
- 测试：`selftest-host-a11y-table.sh` v2 `15/15` 绿（+3 用例：release 掉分区/lookups、主分区与未知/重复 no-op、槽位复用+cap 仍守）；
  **双红控**（instance 键忽略 11 FAIL；release no-op 1 FAIL）；host build **164/164**（DT_NEEDED/UND 过）；
  套件 **688/690 floor 670 assert=True**（导出 pin 与 a11y 源 pin 扩到 release，check 数不变）。
- 边界：SDK 无 provider unregister API；旧 CUSTOM 节点随被销毁的 NodeContent 走；同 id 重注册若被 ArkUI 拒则降级无 provider（managed 帧本地保留）。

## ② 子窗 hybrid/Blazor 资产桥（ow + maui，中）——原显式拒绝改为可服务

- 实现（壳 4 packs `SubWindow.ets`）：接受 `hybrid`/`blazor` 注册（按子槽存 base/root/defaultFile/doc-id；替换 `disableChildWebSlot`）；
  `onInterceptRequest` 服务 `https://0.0.0.1/`（含 `_framework/hybridwebview.js`）与 Blazor 源（含 wasm 模式），移植主窗路径守卫/指纹回退/MIME/缓存头/404；
  `dotnetHost` 代理（含调用帧守卫）+ `window.external` shim + Blazor bootstrap（`__dispatchMessageCallback`/`Blazor.start`）按子槽安装；
  `__hwvSendMessage` 走 `notifyJsMessage`+`__OHORIGIN` 信封（managed 按 doc-id 派发，无需新通道）。
- hybrid invoke 跨窗：请求 id 加 child 旗标 bit30（ow `OpenHarmonyOverlays.ChildInvokeFlag/Encode/TryDecodeChildInvokeRequestId`），maui
  `ChildHandlerForSlot` 按子池槽路由（多窗同槽 fail-closed；M4 升级为 `ChildHandlerForWindow(windowIndex, slot)` + bit29 窗口位）；host_napi 新增 NAPI `registerChildHybridInvokeResultSink`，`ohos_host_hwv_invoke_result`
  按旗标分流到子页 sink；主窗编码/导出（163）字节不变。
- 测试（离线红/绿）：套件 **691/693 floor 673 assert=True**（+3：codec、child dispatch 真 invoke `echo:child`、未领槽 fail-closed；shell/host/slice 源 pin 更新为桥标记）；
  host **163/163**；shell abc **508,832（`9952229b…`）/24,324** 四包一致、provenance 过、`verify-kit` EXPECT 473,048→**508,832** 重锚；
  红控：maui 去掉 child 分支 → `child invoke dispatch`/`miss` assert=False（`l3-web-red.log`，已还原复绿）。
- **真机闭环（2026-10-08，HAD-W32 2in1，主线冻结树 ow `0685d7b`+maui `277967cc56`，JIT hap；壳 abc 534,192/`e6516424…` + host `ad7ab986…`）**：
  最小样例 = `test/hello-maui-app`（ow 工作树，未提交）`openweb` 子窗（plain WebView + HybridWebView）+ `openblazor` 子窗（BlazorWebView + HybridWebView），N=2 同进程；
  新增 `wwwroot/child-hybrid.html`（股票 `_framework/hybridwebview.js` + 自证探针）。壳 hilog：`child hybrid assets: origin=https://0.0.0.1/ root=wwwroot slot=0/1`、
  `child web serve hybrid (slot N): https://0.0.1/` 与 `.../_framework/hybridwebview.js`、`child blazor assets: origin=https://0.0.0.0/ root=wwwroot mode=hybrid`、
  `child web serve blazor: .../_framework/blazor.webview.js`、`child web load`、双 `subwindow page ready`（sub-1/sub-2）；子混合页回读
  `api-ok fw-200-text/javascript; charset=utf-8 origin=https://0.0.1 id=<docId> raw-endpoint-204`、`invoke-result:"CH1-echo:Echo:1"`、`host-received:child-hybrid-host-1`
  （页内 + 状态标签截图），managed `[maui] hybrid invoke (child window 0 slot 1): Echo`（窗 0）与 `(child window 1 slot 1): Echo`（窗 1，N=2 窗口位路由）、
  `child hybrid 1/2 raw: child-hybrid-raw-1..3`（`__hwvSendMessage` -> RawMessageReceived）；子 Blazor 回读
  `{"app":"BlazorWebView component…count: 0","dispatch":"function","blazor":"object"}` + `child blazor N: mounted (…)` 标签截图；0 fault/crash。
  边界：页面 parse 期首个 raw 无回执（壳按当前文档 URL 生成信封），加载后（2/4/6 s）发送均达（204 + RawMessageReceived）；09:33 复核轮在空闲锁下复现同组判据（slot=0/1、CH1-echo、raw-1..3、child window 1 路由）。
- 证据留档（scratch，不落库）：`/data/storage/el2/base/tmp/opencode/hybrid-dev/round5/`（hybrid hap 签名/安装成功、`live.raw`/`mirror.raw`、`01-child2-top.jpeg`/`02-child1-hybrid.jpeg`；
  同判据另有 `round3/`、`round4/`）。子窗 web 全链齐：`capacity ×4 / attached ×4 / page ×4 / load ×4 / cmd(hybrid/blazor/frame/slot) / defer(frame/load/data) / serve hybrid ×3+×3 / serve blazor ×3 / release ×1`。
- 边界/余项：子窗 B6 导航否决未接（外部导航直载）；多子窗同槽 hybrid invoke fail-closed（产品级 N=1）；与并行 `l3-multi-subwindow` 的壳改动需一次并存合并重建；
  子窗 a11y 动作 e2e 仍平台限。
- **样例就绪（2026-10-08，B6-HYBRID-SAMPLE）**：② 的"真机样例缺"已闭环——产品化为 ow `test/hello-maui-hybrid`（分支 `sample/hybrid-subwindow` @ `09d244b`，自 `ca94b55`；
  `openweb`/`openblazor`/B6 deny·ok·veto 全自动探针 + JIT/AOT publish 脚本；`test/hello-maui-app` 默认行为不变）；JIT 真机复证与余项见
  `2026-10-08-ohos-hybrid-sample.md`。

## 提交 / 文档

- ow `l3/a11y-cleanup` `76f4eb5`+`19e8cb7`；ow `l3/web-assets` `fc186bf`；maui `l3/a11y-cleanup` `70b279548a`、`l3/web-assets` `4b9598d9f3`（普通提交，无强推）。
- 本页 → runtime `feature/openharmony`（`commit-paths.sh` 限定本文件；fetch/rebase 被拒，旁路未推）。并行 `l3-multi-subwindow` 的未提交 README/计划稿未触碰。
- 真机轮（2026-10-08）：样例 `test/hello-maui-app/App.cs` + `test/hello-maui-app/wwwroot/child-hybrid.html`（ow 工作树，未提交；主线产品代码零改动、无缺陷，**无需改码**——未开 `l3/web-hybrid-device`）；
  本页真机节即本次 runtime 提交（`commit-paths.sh` 限定本文件）。
  **清尾（POST-L3-CONSOLIDATE，2026-10-08）**：两个未提交样例已移至 scratch `/data/storage/el2/base/tmp/opencode/hybrid-dev/sample/`
  （含 `App.cs.uncommitted.diff` 与 README）后合并；B6 分支随后在主线 `App.cs` 上加了导航探针（`c9413a2`），复原混合样例需手工取舍；见 `-l3-post-consolidate.md`。
- 不确定：离线红控 run 不含真机；真机轮（② 节）覆盖 JIT + N=2 同进程，AOT 路由未在本次真机轮覆盖；窗 1 hybrid 的页内 invoke 回读未单独截屏（以 managed 路由行/raw 行为证）。
