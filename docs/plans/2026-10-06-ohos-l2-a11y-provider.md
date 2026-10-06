# MULTIWINDOW-L2 a：子窗 a11y provider window 化（W1 离线完成；W0/W2 待上机，2026-10-06）

> 口径：实施 `-l2-options-analysis.md` §a 四步路径的 W1 离线全链；设备被并发会话占用（`.device-lock`
> 00:26 起 owner=`l2-arkweb-subwindow`，此前 soak50），W0 并存首验与 W2 真机自检未跑、留卡。
> 分支：maui `l2/a11y-provider`（`31e7635a89`，从 `74e0bde5b9`）· ow `l2/a11y-provider`
> （`05a8115`+`8fa34ca`，从 `afa6d7a`）；未并 master、未强推、未动 #49/#50 资产。

## window 化边界（实现面）

- **节点表按 provider instance 分区**（ow）：新 `host_a11y_table.c/h`（纯 C，自 `openharmony_host.c`
  迁出）：legacy `begin/node/commit/count/get/index_of` 原样读写主分区（主窗零回归）；新增
  `*_for(instance, …)` 读写命名分区；instance 校验（≤63 可打印 ASCII）、命名分区上限 8、id→index 表与
  per-thread 字符串拷贝按分区保留；`host-exports.txt` 157→**163**（+6 managed 导出），CMake/build-host/
  check-host-exports SOURCES 三处同步。
- **CallbackWithInstance 全链**（ow）：`host_napi.cpp` 新增 per-instance CUSTOM 节点 + provider 注册
  （`OH_ArkUI_AccessibilityProviderRegisterCallbackWithInstance`，instance=子窗 surfaceId），回调携
  instanceId 读该分区；动作经新导出 `set_window_action_listener` 带窗上报；新增
  `attachAccessibilityNodeFor/accessibilityStatusFor/accessibilityNodeCountFor` 供壳自检。
- **影子/nodes/动作按窗**（maui）：`TryFindNode/TryFindView/IsModalNode(windowId,…)` + 每窗 modal；
  `Publish(windowId)` 子窗仅在 provider attached（status=1）时走 `_for`（否则保持本地降级、不部分发布、
  不触主表）；动作核心带窗分发（子窗 click/scroll/text 走该窗 renderer+content，主窗路径不变）；
  SEC-4 密码脱敏随共享 walk 覆盖子窗。
- **壳**：`SubWindow.ets`（4 packs）加 `NodeContent`+`ContentSlot`，surfaceId 解析后与 `onPageShow`
  双点上报 `attachAccessibilityNodeFor`（宿主幂等）；主窗 provider 路径零改动。

## 离线证据（红/绿）

- **套件**（`test/maui-platform-verify`）：`checks=668 total=670 floor=650 assert=True`、0 `Unhandled`、
  0 `assert=False`（green；基线 661/663/643 全保，新增 7 checks）；**红控** = 去掉 lookup 的 window
  参数（4 处 `FrameOf(windowId)` → 主帧）：`a11y window lookup / window action routed / window action
  thunk / secondary provider local` 4 条 `assert=False`、run exit 134；还原后复跑全绿（`l2-a11y-red-run.log`
  / `l2-a11y-green-run2.log`）。
- **宿主表 C 单测**：新 `scripts/selftest-host-a11y-table.sh`：green 11/11（legacy roundtrip、A/B 分区
  互不覆盖、同 id 分区解析、未知/非法 instance、字符串拷贝跨 republish、上限、reset）；红控 = instance key
  忽略变体 → 7 条分区断言 FAIL（exit 1）；设备构建/导出/壳/切片 wiring pins 8/8；已入 preflight 门禁表。
- **宿主全量构建**：`build-host.sh`（NDK 26.0.0.18）：`ok: all 163 expected exports present as plain
  symbols`、DT_NEEDED/UND denylist 0、a11y 22 个符号全 plain `T`（含 legacy 原名，无 `_Z`）。
- **契约**：`check-host-exports.py --cross-check` = 163/163；**AOT 切片**：slice `IsAotCompatible` +
  trim/AOT analyzer + `warnaserror:IL2026,IL3050` → Build succeeded、**0 IL**（余 216 warning 全基线类）。
- 既有 `selftest-host-window-bridge.sh` 12/12、`sh -n` 全过；主窗 provider/legacy 表路径逐字保留。

## 待上机卡（W0/W2；设备锁不可得）

- 锁：`.device-lock` 00:26 owner=`l2-arkweb-subwindow`（此前 soak50；owner 文件在位、非 stale，未抢锁）；
  hdc 目标 `127.0.0.1:35111` 在位但未安装/未启动任何件。
- **W0 并存首验**（0.5pd，失败即收）：装 W1 件 → 开子窗，看 hilog `subwindow a11y provider status=N` 与
  主窗 `accessibility provider status=1`：N=1 且主 status 不回退 = 并存可行；平台拒绝（N=3/4）→ 保持本地
  帧降级、主窗零回归（W1 默认此路径）。
- **W2 真机自检**（1–2pd）：`host.accessibilityStatusFor('sub-1')==1` 且 `accessibilityNodeCountFor` 与
  子窗 dumpLayout/自检一致、主窗 nodeCount 不变；无读屏动作按窗 hilog；读屏 e2e 受平台限制 B1 → 外部复跑。
  轮末恢复 kit #49 hap 并释放锁。

## 余项 / 边界

- W2 未跑（上卡）；`Announce` 仍走主 provider（进程 API，无窗归属）；子窗 provider 关窗不 detach（与主
  provider 同生命周期，SEC-5C-F 有界）；ArkWeb 子窗宿主（option b）由并发会话另轨，本分支不含。
- 并发纪律：本波与 `l2/arkweb-subwindow` 共用 checkout，实施与验证均在独立 git worktree 完成，两分支各自
  只含本波路径（ow `05a8115`/`8fa34ca`、maui `31e7635a89`）。
