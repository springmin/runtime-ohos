# DEVICE-ROUND-50 + SOAK50：kit #50 发布件真机背书（AOT，HAD-W32；2026-10-06）

> 结论：**kit #50 发布件（tar 68,264,136 B / `d70dc786…`、树 `b4b5055c…`、sidecar ok）在 HAD-W32 2in1（OpenHarmony-7.0.0.109 / API 26 / UDID `1BCE13C8…`，hdc `127.0.0.1:35111`）完成 AOT 真机轮**：安装/启动/首帧 `runtime-mode=aot`；demo 全链 + touch 按窗；L 第二 MAUI 视觉树（`first frame=True` 720×480、`windows=2`、surface unregister）；单/双窗 **60.0 fps** 零回归；churn ×20 无残留；Home 焦点链 suspend/resume ×10 每轮 1/1 + close→Closed；40 min soak **41 采样 pid 恒定、0 pid_lost、0 fault_new、0 重启**；7 hap 抽装 7/7（2 unsigned 重签）。预签件（68,157,557 B / `028d29f4…`）7/7 `verify-app`、tester UDID、条目逐字节一致，未安装。首轮 pid 丢失归因见 §5。
> 轮次：首轮 21:59–22:08（代理 OOM 于 t=8min，t=6min 丢失）→ 并发 L2CAP 轮 22:32–22:55（§5）→ 干净重跑 23:01–23:43 → 23:47+ 抽装/帧率复核 → 23:53 `restore50.sh` 还原 kit #49 hap（`39a2433e…`）并释放锁。

## 1. 资产 / 设备 / 纪律

- kit tar sha `d70dc786…` == 期望；`verify-kit` tree `b4b5055c…`、sums/sidecar ok；干净轮主 hap 本地重签 `87076a236b7c…`。预签 tar `028d29f4…`、sidecar `02397318…`（88 B）、树 `440a2cb5…`、sums 8/8、7/7 verify-app（tester UDID 单值）、entry-invariance PASS。
- 设备 HAD-W32 / OpenHarmony-7.0.0.109 / API 26；常亮 + hilog 16M（轮末还原 512K）。锁：`mkdir .device-lock` owner=soak50；首轮死主锁 22:32 由 L2CAP 会话按协议接管；23:01 干净重跑轮持锁（周期 touch 保活），23:48 释放后本会话 23:49 重取完成抽装/复核，23:53 `restore50.sh` 释放（未抢他人锁、未强拆）。

## 2. 安装 / 启动（AOT，干净轮 23:01）

- verify ok → 重签 → install/start rc=0，**pid 3779**、`runtime_mode=aot(hap)` → first_frame ok（`managed app hello-maui-app.dll started`、`canvas presented (2090x1324)` + `frames/first.jpeg`）→ tester-run v14 probe ok；core 归档 `tester-run-20261006-230226.tar.gz`（`f358943d…`）。
- 路由原文：`jitfort: skipped runtime-mode=aot`、`OHOS_DOTNET probe: 1=OK 2=OK 3=13 4=1`。

## 3. 子窗全链 / touch 按窗 / 帧率（MULTIWINDOW-M + L）

- **demo**（`app://subwindow/demo`）：create id=568（120,160 720×480）→ page ready `name=ohos_dotnet_subwindow drag=on` → move 420,360 → resize 900×600 → closed；WMS `ohos_dotnet_subwindo` 残留 **0**；截图 4 张；touch 窗内 delta=2 / 窗外 delta=0（不串窗）；`uitest swipe` 未触发 PanGesture `drag #`（注入面限制，非失败；#49 用鼠标拖拽取证）。
- **L**：`app://subwindow/open` → `window 'sub-1' registered (windows=2)` + `bound … 720x480 (first frame=True)`；RSTree `ohos_dotnet_subwindow__sub-1` / `sub-1Surface` `hasSurfaceBuffer=1`；close → `unregistered=1` + `subwindow closed`。
- **帧率**（relay 三连 dump，16 s）：单窗 main 60.0（avg 16.7 / max 19 ms）；双窗 main 60.0（max 19 ms）+ sub-1 60.0（max 17 ms）；long/longruns 0；`canvas presented` 主 2090×1324 + `[sub-1]` 720×480；主窗退化 0%。

## 4. churn ×20 / Home 焦点链 ×10 / 40 min soak

- **churn ×20**：20/20 onLoad+surface registered+closed+unregistered 1:1；WMS 残留 **0/20**；pid 8654 恒定；threads 70–73、RSS 252,948→257,292 kB（+4.3 MB 无趋势）。
- **Home 焦点链 ×10**：Home→`suspended (no active window)`→`aa start`→`resumed (window active)`；10/10 每轮 1/1；pid 恒定、threads 70–71、RSS +2.3 MB；末次 close→`subwindow closed`+`unregistered=1`。
- **40 min soak**（23:02:44–23:43:27，单窗安装态；live hilog 0 条 l2cap/0 击杀）：41 采样、pid 3779 首=末、pid_lost=0 / fault_new=0、`updateTime` 首=末、power=AWAKE；RSS 238,104→243,872 kB（+5.8 MB，min 238,104 / max 252,632 @t≈29）、threads 65–68（68→66）；0 CppCrash/AppFreeze/JSCRASH。

## 5. pid 丢失归因（首轮 t=6min）+ 干扰 / 降级 / 边界

- **首轮实亡 22:06:01.179：appspawn `exit with code:0`（非崩；faultlog 无 10-06 新条目）**。因果链：22:05:59 硬件触控板（`LibinputAdapter hid-over-i2c Touchpad`；`inject=0`）→ 22:06:00.873 button-down → 22:06:01.055 壳标题栏 `win_close_event`/`OnCloseBtnClick` → `MainWindowCloseInner` → SceneBoard `terminateReason:2` → AMS `TerminateAbility`。**判定 = 外部物理点击窗口关闭按钮（环境干扰），非运行时缺陷**；与 2026-10-04 #44 §3 同类机制闭环；证据 `out/soak-round-aborted/pidloss-window/`（hilog/kmsg 窗口 + markers + ANALYSIS.md）。
- **并发干扰**：L2CAP 探针（`mw-l/l2cap`，`com.example.l2cap`）22:32–22:55 连跑，其轮 `aa force-stop com.example.hellomauiapp` park 前台 → 并发 soak（22:41–22:51）t=1/7 min 丢失；该轮不作数；记录 `out/concurrent-l2cap/README.txt`。
- 降级/边界：#50 已声明降级不判点（子窗 a11y provider、子窗 ArkWeb 第二宿主、应用级 N=1、子窗 IME 人工卡、SEC-5c B–F）；uitest 无多点注入 → pinch 仅离线/单测；单设备 2in1 debug 域；共享桌面；managed `Suspended/Resumed/Closed` 仅页载后 ~36 s relay 窗进 hilog（壳侧标记为主证）。

## 6. 抽装 / 证据 / 提交

- **7 hap 抽装 7/7**（23:49–23:53，unsigned 逐件重签本机 UDID）：5 MAUI install OK + managed started + canvas presented（pid 60791/63078/63210/65458/282）；Blazor default/nocsp install OK + BLZ_BOOT（pid 4046/6200）；表 `out/spot/spot-all.tsv`。
- 证据 tar：`reg-kit50/soak50/soak50-evidence.tar.gz`（**52,937,361 B / `4e674660…`**，终版 = 前序 `42,516,408 / 8e484240…` 超集；含干净轮归档 `soak-round-20261006-234335.tar.gz`（43,331,874 / `15b68f56…`）+ samples/meta、首轮损失窗口、并发记录、churn/suspend/demo（含 dump）、fps、预签、7 hap 抽装、脚本与 SUMMARY）。
- 提交：本文件 + README 索引（runtime-ohos `feature/openharmony`；commit-paths，普通推送、未强推）。
