# ZORDER-NAV：多覆盖层重叠置顶 + 真实 Navigate（真机，2026-10-03）

> 设备 HAD-W32（OpenHarmony-7.0.0.111 / API 26 / 2in1），hdc 无线 127.0.0.1:35111；AOT 件按 kit #41
> 线本地重建（maui 切片 `07423dfe93` 干净快照，规避共享工作区并发编辑；壳 abc 356,140/`2a90f0d7…`、
> 宿主 `8d67def3…`；IL2026/3050/3051=0/0/0）；证据 scratch `/data/storage/el2/base/tmp/opencode/zorder-nav/`。

1) **MULTI-OVERLAY-FULL 重叠置顶 ✅**（此前只有纵向不重叠布局）
- 布局（`test/hello-maui-app/App.cs`，ZORDER-NAV）：A/B 同区 270 DIP（固定行 180+90，web handler
  `GetDesiredSize` 不认 `HeightRequest`），B 偏移 (80,90)；A 暴露顶带+左列，B 暴露底带，争夺带 =
  y90-180/x80-end；页面加蓝(A)/橙(B)底色。dump 实测 A=[674,801,2700,981]、B=[754,891,2700,1071]、
  争夺带=[754,891,2700,981]（`device/app/z0.json`）。
- 触 A 暴露带 → 争夺带 **97.2%** 像素翻转 B(橙)→A(蓝)（z0→z1）；触 B → **97.2%** 翻回 A→B（z1→z2）；
  再触 A → **97.2%** 再翻回（z2→z3）；A 专属左列对照 **0.0%**（B 升起不改 A 域）。截图
  `device/app/z0-overlap/z1-raiseA/z2-raiseB/z3-raiseA2.jpeg` + 数值 `device/app/run.out`。
- hilog：`missing native code`=0、`touch callback failed`=0、`web page (slot 0)`+`(slot 1)` 各 1、
  `payload-in-libs` 直载；件 `zorder-app-signed.hap` 22,359,210 B / `3a011474…`（已装）。

2) **NavigationOptions 真实 Navigate ✅**（FIX-JSCALL 预防性 root 首次真机点验）
- `test/hello-maui-razor/BlazorCounter.razor` 加 "Go to second view"（`Nav.NavigateTo("/second")`）+
  "back to counter"。真机点击 → DOM 切 `second view (Navigate OK)` + `location: https://0.0.0.0/second`
  （r1）；返回 → 计数视图（r2）；计数回归 0→1（r3）。
- 直接证据：`BLZ_DIAG send head=__bwv:["Navigate","/second",{"forceLoad":false,"replaceHistoryEntry":
  false,"historyEntryState":null,"relativeToCurrentUri":false}]` 且 `eval out … result="ok"`——即
  `IpcSender.Navigate` 经包反射解析器完整序列化 `NavigationOptions` 并送达 JS；`missing native code`=0、
  `interop-call`=0、BeginInvokeJS/DotNet=12/12、`touch callback failed`=0。
- 件 `zorder-razor-signed.hap` 21,924,317 B / `aaa015b5…`（已装）；证据 `device/razor/`。

**缺口/不确定**：① 重叠布局下的 A/B/C LRU 二次抽验未跑成——设备随后进入 APP_NAP 状态，`aa start`
成功但进程即被系统回收、无 hilog；按钮行与槽池代码未随本轮改动，`2026-10-02-ohos-kit41-local-verification.md`
的 A/B/C LRU 证据仍适用。② 演示树含并发 SAMPLE-FIX 未提交改动，本提交只暂存 ZORDER-NAV hunk（ohos-workload `680f9ed`，4 文件 / +101-12）。
