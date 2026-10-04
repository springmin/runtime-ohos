# FIX-A11YFLYOUT + FIX-PREEMPT-RAW：FlyoutPage a11y 分支与抢占原文定向导出（2026-10-05）

> 承接 SOAK-JI（`2026-10-04-ohos-jit-interp-soak.md` §4/§5）两条残余。设备 HAD-W32 /
> OpenHarmony-7.0.0.109（UDID `1BCE13C8…`，hdc `127.0.0.1:35111`，独占 `.device-lock`
> mkdir+owner/rmdir，低噪声复放）。件：probe5（A–E 样例变体，AOT，`92844ad7…` / 签
> `57e4c044…`，abc 370,240/`4b439e83…`），切片 = maui FIX-A11YFLYOUT，壳 = FIX-PREEMPT-RAW。
> 套件 **591/593 floor 573 → 593/595 floor 575**（+2，只增）；切片编译 0 error/0 IL；导出
> 151/151；CI pin 未改（maui `6652017ca5`）。

## 1) a11y FlyoutPage 分支（定因闭环）
- 实现（maui `OpenHarmonyAccessibility.PushChildren`）：补 `FlyoutPage.Detail`（恒入树）与
  `FlyoutPage.Flyout`（仅 `IsPresented`）分支，镜像合成器 `ChildEnumerator`；rc.1 的 FlyoutPage
  非 `IContentView`，原 presented-content 分支覆盖不到 → 只发布根 → `nodeCount=1`。
- headless 断言：`a11y-flyout detail`（detail 入树、ParentId≠0、nodes>1、未展开无 flyout）+
  `a11y-flyout panel`（IsPresented 后 flyout 入树且 detail 保留）；负控制：移除分支重编 →
  `published=False nodes=1`，套件在第一条断言抛异常（红）。
- 真机：自检 `accessibilityStatus: 1`、**nodeCount=70**（Home 内容页节点；此前同路径 1）；
  证据 `fix-a11yflyout/device/{b1-a11y-dialog.json,jpeg,a11y-b.txt}`。

## 2) 抢占原文定向导出（FIX-PREEMPT-RAW）
- 实现（壳 `pollManagedStatus`）：扫描 `dotnet-status.txt` 自上次轮询的新增段，把含
  `overlay preempted/restored/replay` 的行以 `[maui-capacity]` 前缀直写 hilog；文件被 trim
  重写时整文件回退。CEF stderr 挤掉 60 行镜像窗不再丢行。
- 真机复放（07:01:11–14）：加 C/D/E（E 抢 A 槽）→ Activate A。原文（`device2/marker-lines.txt`，
  均 `[maui-capacity]` 前缀）：`preempted: slot 0`（E 抢 A）→ `preempted: slot 1` +
  `restored: slot 1` + `replay: slot 1`（Activate A；另 1 条 `preempted: slot 0` 属 LRU 级联）；
  共 5 行导出（3 preempt + 1 restored + 1 replay）。
- 壳 abc **370,240 B / `4b439e83…`**（Index.ets 326,953 / `69dc09e0…`；headless 24,324 不变），
  provenance `bb5a1758…`，四包 preview.22/23/24/28 同步；`verify-kit.sh` ui 期望 370240。

## 3) 提交 / 不确定
- 提交：maui `d5384d6cc3`（已推 `feature/openharmony`）、ohos-workload `f538c84`（已推
  `master`）、runtime-ohos 本文件 + 索引 + SOAK-JI 指针（`commit-paths.sh`，普通推送）。
- 不确定：设备型号/OS 按本轮记录；定向导出只覆盖 12×3 s 轮询窗内到达的行（低噪声复放按窗内
  节奏）；`nodeCount` 为沙箱自检读数（无读屏客户端），真读屏机复核不变。
