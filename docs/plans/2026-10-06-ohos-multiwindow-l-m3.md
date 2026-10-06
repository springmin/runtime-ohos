# MULTIWINDOW-L M3：壳子窗挂 XComponent + 输入路由 + managed 生产消费方（2026-10-06）

> 口径：M3 退出门禁 = 壳 `OpenWindow`→子窗第二视觉树可交互、触摸按窗归属、主窗 60fps 零回归、关窗回收、重开同 id。
> 载体：ow `l/m3-shell-xcomponent`（基于 `l/m2-exit` @ `896f4e3`）· maui `l/m3-per-window-content`（基于 `l/m2-per-window-renderer` @ `1a15f56b30`）；不并 master、未切 kit、#49 资产未动。
> 提交：ow `9694d38`(壳 abc/模板)+`c0814d6`(宿主)+`6fbfd52`(套件/样例)+`35df4f4`(CI pin) · maui `d4ff7d445e` · 本文档。均普通推送、未强推。
> 真机：HAD-W32 / OpenHarmony 7.0.0.111（UDID `1BCE13C8…`）；证据 scratch `mw-l/m3-*`（截图 + raw hilog），不入库。设备锁按 `.device-lock` protocol 持有，轮末恢复 kit #49 hap 后释放。

## 壳（ow）

- `pages/SubWindow.ets`：managed 模式下挂 `<XComponent libraryname='openharmonyhost'>`，组件 id = managed 会话 id；`onLoad` → `host.registerXComponent(id)`（返回 1 才隐藏降级内容），`onDestroy` → `host.unregisterXComponent(id)`。M 版壳绘页（标题/拖动/触摸计数）完整保留为降级路径（无 id、注册失败或旧壳时不破）。
- `pages/Index.ets`：create 命令新增可选 `surfaceId`；子窗 **window name** 携 `<SUB_WINDOW_NAME>__<surfaceId>`（LocalStorage 在本机不向页面传播，实测），状态 payload 回带 `surfaceId`；单实例壳对第二个 managed id 如实回 Failed 801。
- 模板同步 4 packs（preview.22/23/24/28）并重编 UI abc：426,304 B / `38bdf7de…` / abc 13.0.1.0（provenance 同步，22/23/24 字节一致）；preview.28 与 `~/.dotnet` 安装包同步刷新。

## 宿主 + managed 生产接线

- 宿主新导出 `ohos_host_draw_begin_window` / `ohos_host_draw_present_window`（按 M1 注册表 id 取各自 surface），per-target canvas/bitmap（两窗交替不再互毁画布），present 遥测 `canvas presented [<id>] (WxH)`；失败日志 per-id 只报一次。导出 154→156 全过（DT_NEEDED/UND/nm）。
- `registerXComponent` 现返回 1/0（显式 id 必须登记成功才算 1）；注册表新增 `ohos_host_window_rename_component`，显式 id 权威覆盖自动 id；registry selftest 66→**73/73**。
- hosting：`OpenHarmonyCanvas.BeginWindow/PresentWindow`（managed 导入，156/156）；maui 切片：app host 构造期订阅 tagged 通道（忽略 `main`，主窗走 untagged 零变化）、`OpenWindow` 无面时经子窗 sink 申请 `sub-N` 并 park，`RouteSurface` 到达即绑定+首帧；`OpenHarmonyWindowSurface` 非主窗 Begin/Present 走 per-window 目标；渲染器 present 解析对非主窗绕过进程级 `SurfacePresent`（overlay/tooltip 钩子在 M4 分区前只属主窗）。
- 示例 `app://subwindow/open` 改为真 `Application.OpenWindow`（managed 第二窗；不可用回落 M 壳绘），close 走 `Application.CloseWindow`。

## 真机 M3×5（证据 raw 行 + 截图）

1. 创建并渲染：`xcomponent onLoad id=sub-1`、`registered=1`、`window 'sub-1' registered … windows=2`、`canvas presented [sub-1] (720x480)`、`bound … 720x480 (first frame=True)`；截图 `m3-case1.jpeg`（第二 MAUI 视觉树：Label+Button）。
2. 触摸路由：子窗按钮两次点击 → `child window tap #1/#2`、截图计数 2；点主窗 (1000,300) 无 `#3` 且主窗状态不变（跨窗事件=0）。
3. 主窗 60fps：子窗开启时 `canvas presented (2090x1324) n=301 avg=16ms max=23ms`（对 #49 基线 16–17ms 零回归；#48/#49 判定卡口径）。
4. 关闭清理：`app://subwindow/close` → `DestroyXComponent sub-1` / WMS `Remove/Destroy window` / `subwindow surface sub-1 unregistered=1` / `[maui] subwindow closed`；截图子窗消失、主窗存活。
5. 重开同 id：再次 open → `requested subwindow surface 'sub-1'`、`surface sub-1 registered=1`、第二视觉树重现（截图 `m3-case5.jpeg`）。

- churn ×20（open/close）：pid 恒定（13358）、faultlog 0→0、WMS 结束后恰 1 子窗，无残留。

## 套件抬升 + 离线红控

- `test/maui-platform-verify` +14 checks（M3 生产订阅/deferred 申请/绑定首帧/独立输入/关窗回收/同 id 重开 + 4 packs 壳源 + 宿主/切片 per-window 目标源 pin）：`verifyCheckTotal` 631→645、floor 611→625；实跑 `[suite] checks=643 total=645 floor=625 assert=True`、0 `assert=False`；pixel 套件 `PIXEL ASSERTIONS PASSED`。
- 红控：以 M2-tip 切片（`1a15f56b30` archive）编译 M3 套件即红（CS1061：`AwaitingWindowCount` / `SubWindowSurfaceRequester` / `FrameTicks` 缺失，`m3-redcontrol/redcontrol-build2.log`）。

## AOT（workload .28）与余项

- AOT publish（hooks 本机 Exec 绕行，`m3-aot/publish-aot.log`）：EXIT=0、**IL2026/IL3050/IL3051=0**、`runtime-mode.txt=aot` 且 probe 行 `runtime mode 'aot' written to libs/arm64-v8a/runtime-mode.txt`；hap 31,214,338 B（内嵌 M3 abc `38bdf7de…` + 终版 host `5ff07fde…`）、publish `libhello-maui-app.so` 19,442,448 B / `6e74a1de…`；余下 127 warning 全为基线类（CS0618/NETSDK1188/CA2255 与第三方 IL3053/IL3000/IL2104，类别同 M2-exit 白名单）。
- AOT hap 真机 smoke：`app://subwindow/open` → `windows=2`、`canvas presented [sub-1] (720x480)`、`first frame=True`；close → `unregistered=1`。轮末恢复 kit #49 hap 并释放设备锁。
- 余项：壳仍单 managed 子窗（第二个 id 回 801，数量上限探测留 M4）；键盘/焦点/z-order/IME/a11y/overlay 分区属 M4；status 文件镜像只在启动后有限窗口轮询，长稳证据看向 hilog 原始行。
