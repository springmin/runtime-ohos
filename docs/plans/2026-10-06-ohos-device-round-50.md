# DEVICE-ROUND-50 + SOAK50：kit #50 发布件真机背书（AOT，HAD-W32；2026-10-06）

> 结论：kit #50 发布件（tar **68,264,136 B / `d70dc786…`**、树 **`b4b5055c…`**、sidecar ok）在 HAD-W32 2in1（HAD-W24
> **7.0.0.111**(SP3ENTC293E104R2P1log) / API 26 / UDID `1BCE13C8…`）完成 AOT 真机轮：安装/启动/首帧 `runtime-mode=aot`；
> MULTIWINDOW-M demo create/move/resize/close + touch 按窗；MULTIWINDOW-L 第二 MAUI 视觉树（`first frame=True` 720×480、
> `windows=2`、surface unregister）；单/双窗 **60.0 fps** 零回归；churn ×20 无残留；Home 焦点链 suspend/resume ×10 每轮
> 1/1 + close→Closed；40 min soak **41 采样 pid 恒定、0 pid_lost、0 fault_new、0 重启**。预签件（**68,157,557 B /
> `028d29f4…`**）7/7 `verify-app`、tester UDID、条目逐字节一致，**未安装**。降级声明见 §5。

## 1. 资产 / 设备 / 纪律
- kit tar sha `d70dc786…`；`verify-kit` tree `b4b5055c…`、sums/sidecar ok（0 FAIL/0 WARN）；主 hap 本地重签 `55b7a61546ab…`
  （mode=aot）。预签 tar `028d29f4…`、sidecar `02397318…`（88 B）、树 `440a2cb5…`、SHA256SUMS 8/8、7/7 条目一致。
- 设备 HAD-W32 / OpenHarmony-7.0.0.111 / API 26；hdc `127.0.0.1:35111`；常亮 + hilog 16M（轮末还原）。锁：轮初
  `mkdir .device-lock` owner=soak50；22:32 被并行 L2CAP 会话接管，23:01 重取并周期 touch 保活，轮末释放；#49 资产未动。

## 2. 安装 / 启动（AOT，device-round.sh --mode aot）
- 干净轮 verify ok → 重签 → install/start rc=0，**pid 3779**、`runtime_mode=aot(hap)` → first_frame ok（`canvas presented
  (2090x1324)` + `frames/first.jpeg`）→ tester-run v14 probe ok；**6/6 步，failures=0**。
- 路由原文：`jitfort: skipped runtime-mode=aot`、`OHOS_DOTNET probe: 1=OK 2=OK 3=13 4=1`、`OHOS_HOST start_app aot=1
  lib=…/libhello-maui-app.so`。

## 3. 子窗全链 / touch 按窗 / 帧率（MULTIWINDOW-M + L）
- **demo 全链**（`app://subwindow/demo`）：create **id=568（120,160 720×480）** → page ready `drag=on` → move **420,360**
  → resize **900×600** → closed；WMS `ohos_dotnet_subwindo` 残留 close 后 **0**；截图 demo-created/moved/resized/closed。
- **touch 按窗**：子窗内点按 `OHOS_MAUI_SUB subwindow touch #1/#2`（inside delta=2）；主窗区点击同窗期 delta **0**
  （子窗事件不串主窗）；`uitest swipe` 未触发 PanGesture `drag #`（注入面限制，非失败；#49 用鼠标拖拽取证）。
- **L**：`app://subwindow/open` → `window 'sub-1' registered (windows=2)` + `bound … 720x480 (first frame=True)`；RSTree
  `ohos_dotnet_subwindow__sub-1` / `sub-1Surface` `hasSurfaceBuffer=1`；close → `unregistered=1` + `subwindow closed`。
- **帧率**（冷启锚定 relay 窗口三连 dump）：单窗 main **60.0**（avg 16.7 / max 19 ms）；双窗 main **60.0**（max 19 ms）
  + sub-1 **60.0**（max 17 ms）；long/longruns **0**；`canvas presented` 主 2090×1324 + `[sub-1]` 720×480；主窗退化 **0%**。

## 4. churn ×20 / Home 焦点链 ×10 / 40 min soak
- **churn ×20**（open→close）：20/20 `onLoad`+`surface registered`+`closed`+`unregistered` 1:1；**WMS 残留 0/20**；pid
  恒定；threads 70–73、RSS 252,948→257,292 kB（**+4.3 MB**，无累积趋势）；末置开窗。
- **Home 焦点链 ×10**：`uitest keyEvent Home`→`suspended (no active window)`→`aa start`→`resumed (window active)`；**10/10
  每轮恰 1/1**；pid 恒定、threads 70–71、RSS +2.3 MB；末次 close→`[maui] subwindow closed`+`unregistered=1`（Closed 兜底）。
- **40 min soak**（`--soak-min 40`，60 s 采样，单窗安装态；live hilog 窗口 0 条 l2cap/0 击杀）：**41 采样**、pid 3779 恒定、
  **pid_lost=0 / fault_new=0**、`updateTime` 首=末、power=AWAKE；RSS 238,104→243,872 kB（**+5.8 MB**）、threads 68→66（65–68）、
  0 CppCrash/AppFreeze/JSCRASH。

## 5. 干扰 / 降级 / 边界
- **设备互斥被并行会话打断（如实记录）**：`mw-l/l2cap` 平台级多子窗探针在 22:32/22:43/22:49/22:54 连跑多轮，其轮
  `force-stop` park 前台 MAUI → 本会话两次 soak 尝试在 t=1/6 min **pid 丢失**（其 meta `maui_pid_after` 可对照）；
  §4 soak 数据取自其后的**干净一轮**（轮内 live hilog 0 条 l2cap、0 击杀）。
- 降级声明（#50 已声明，不判点）：子窗 a11y provider（主 provider 零变化/子窗影子帧本地）、子窗 ArkWeb 第二宿主、
  平台级多子窗上限（应用级 N=1）、子窗 IME 实敲人工卡、SEC-5c B–F；uitest 无多点注入 → pinch 仅离线/单测（承 dev 轮）。
- 边界：单设备 2in1 debug 域；共享桌面（设备同时被其他会话使用）；未测 split 拖拽与 0×0 收窗保帧；managed
  `subwindow event Suspended/Resumed/Closed` 只在页载后 ~36 s relay 窗进 hilog（壳侧标记为主证）。

## 6. 证据 / 提交
- 证据 tar：`reg-kit50/soak50/soak50-evidence.tar.gz`（**42,516,408 B / `8e484240713e…`**；含 device-round 归档 +
  soak samples/meta、churn/suspend/demo CSV+过滤 hilog、fps relay/parsed、预签校验 7/7、live-hilog 干扰记录、脚本 `bin/`）。
- 提交：本文件（runtime-ohos `feature/openharmony`；`commit-paths.sh` 限定路径、普通推送、未强推）；未改 #49 资产。
