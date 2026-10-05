# NEXTKIT-POLISH-PREP：子窗三噪声定位与备料（候选分支 `next-kit/polish-49`，2026-10-06）

> 口径：DEVICE-ROUND-49 / SOAK49 三项（①建窗 `ParseSubWindowOptions` E×3、②close
> `AceSubWindow dialogSubwindowMap_` WARN×1、③Home 键不触发 `WINDOW_HIDDEN`）的定位与最小修。
> 候选分支**未并入 master、未重打 kit、未更新 packs 内 abc/provenance**（#49 资产保持
> 414,532/`e016db13…`）。验证 = 平台源码定因 + 源码门禁 + ArkTS ui 构建 + **真机抽验**（HAD-W32
> OH 7.0.0.111/2in1，UDID `1BCE13C8…`，`.device-lock` 06:40 自持/07:08 释放；签名测试 hap = kit #49
> unsigned + 候选 abc，`verify-app success`）。候选 abc **417,416 B / `cee64297…`**（13.0.1.0）；
> 证据 scratch `reg-kit49/polish49-device/` + `polish49-evidence.tar.gz`（1,399,861 B / `2821f39c…`）。

## ① 建窗 E ×3 —— 壳侧补齐三可选布尔（真机 E=0）

- 平台（window_manager `js_window_utils.cpp::ParseSubWindowOptions`）：`maximizeSupported`、
  `outlineEnabled`、`zLevelAboveParentLoosened` 逐个 `ParseJsValue`，缺字段打 E 后保持默认 false，
  **建窗仍成功**；`title`/`decorEnabled` 缺失才会失败。与 round49 的 3 条 E 一一对应。
- 修：Index.ets 的 options 显式 `maximizeSupported:false`、`outlineEnabled:false`、
  `zLevelAboveParentLoosened:false`；第三项 SDK d.ts 未公开，用本地
  `interface ShellSubWindowOptions extends window.SubWindowOptions` 钉住（行为=平台默认，仅消音）。
- 真机（07:00:15 建窗 id=430）：`Failed to convert` **0** 条，仅平台的
  `ParseSubWindowOptions: zLevelAboveParentLoosened: 0` INFO 1 条。

## ② close WARN ×1 —— 平台内部，非我方 double close（仅注释）

- 平台（arkui_ace_engine）：`AceContainer::DestroyContainer` 对每个被销毁容器先无条件
  `SubwindowManager::CloseDialog(instanceId)`；`dialogSubwindowMap_` 只登记发起 dialog 的容器，
  app 子窗容器不登记 → 命中失败打 WARN（每 close 1 条，不影响销毁）。我方每 close 仅一次
  `child.destroyWindow()`（幂等）；真机 close `subwindow closed`、WARN 1、pid 不变 → 不改码仅注释。

## ③ Home 键 suspend —— 实测 onBackground/窗口级 HIDDEN 均不触发，改用焦点丢失链（真机通过）

- **逐项实测排除**（diag 构建 + 真机）：Home 后 ability 仍 `aa dump #FOREGROUND`，`onBackground/onForeground`
  不调用；`windowStageEvent` 只有建窗 INACTIVE(3)/恢复 ACTIVE(2)、无 HIDDEN；主窗无 `WINDOW_HIDDEN`
  （恢复才 SHOWN/ACTIVE）；`isWindowShowing()` 恒 true。**唯一 Home 信号** = 持焦窗的 `WINDOW_INACTIVE`。
- 判别：窗口间内部换焦在同一 tick 伴随另一窗 `WINDOW_ACTIVE`（真机实测点击主窗：child
  INACTIVE→main ACTIVE 同毫秒）；Home 后无 ACTIVE。
- 修（Index.ets，仅壳）：主/子窗事件汇入同一链——ACTIVE→取消候选并 resume；INACTIVE→600 ms
  宽限，期内无 ACTIVE 则 suspend（`no active window`）；HIDDEN 仍立即 suspend（标题栏最小化，
  `main window hidden`）；`clearSubWindow` 取消待定定时器。日志保留测试脚本 grep 前缀、后缀标来源。
- 真机（07:00:29/34）：Home→`main window hidden: subwindow suspended (no active window)`；
  `aa start`→`main window shown: subwindow resumed (window active)`；点击主窗无多余转换。
- 安全：纯 ArkTS 定时器/窗口事件，无 managed IL；事件缺失退化为原 HIDDEN/SHOWN 路径，不崩。

## 验证程度 / diff / 提交

- 验证：`--check-sources` 绿 + 一次 ui 构建绿（CompileArkTS 13.5 s、abc 417,416/`cee64297…`/
  13.0.1.0）+ 上述真机矩阵；T16 4 失败 = 预期 source drift，`--install-packs` 即复绿。
- diff：ow `next-kit/polish-49`（本分支头 `b5928d1`，局部改动 = 4 包 × `pages/Index.ets`；#1
  `f83549e` 的 Ability/eventHub 版被 #2 按真机结论替换，EntryAbility 净零回 master），普通推送、
  未并 master、未强推。文档：本文件（runtime-ohos `feature/openharmony`）。
- 边界：单设备 2in1 debug 域；Home 键为 `uitest uiInput keyEvent Home` 路径；未经 device-round
  全套回归（仅子窗三项 + pid/崩溃观察）。

## 下一 kit 并入步骤

1. 取 `next-kit/polish-49` 的 4 包 `pages/Index.ets`（与 master 无冲突）；可选把 build 脚本
   `--install-packs` 循环扩到 preview.28，或按惯例手动同步第 4 包。
2. `ARKTS_SHELL_VARIANT=ui` 与 `=headless` 各构建一次 → `--install-packs`（abc+provenance 四包
   刷新，T16 复绿）→ `verify-kit.sh` 期望 abc 重锚新 ui 值。
3. 常规 device-round/soak 复核（Home 键 suspend/resume、建窗 E=0、close WARN 仍 1）。
4. 重打 kit / 预签 / 发布按既有流程（本分支不含资产变更）。
