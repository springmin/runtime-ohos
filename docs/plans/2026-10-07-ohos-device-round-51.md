# DEVICE-ROUND-51 + SOAK51：kit #51 发布件真机背书（AOT，HAD-W32；2026-10-07）

> 结论：**kit #51 发布件（tar 68,550,333 B / `e5f6541c…`、树 `a06d3897…`、sidecar ok）在 HAD-W32 2in1（OpenHarmony-7.0.0.109 / 软件 HAD-W24 7.0.0.111 / API 26 / UDID `1BCE13C8…`，hdc `127.0.0.1:35111`）完成 AOT 真机轮**：安装/启动 rc=0、首帧 + `runtime-mode=aot(hap)`；**L2 新面全绿**——子窗 demo create/move/resize(900×600)/close + touch 不串窗、**child ArkWeb 第二宿主三循环**（capacity max=2→slot 0→attached→`CHILD-WEB` 页→managed eval/`CHILD WEB TAP` DOM 截图；a11y 并存 `status=1/nodes=12`；关窗 `slot destroy`+`unregistered=1`+WMS 0；**SEC6-C 重开容量/槽/页再通、rejected=0**）；单/双窗 **60.0/60.0 fps** 主窗零回归；churn ×20 20/20 无残留；Home 焦点链 10/10（suspend/resume + close→WMS 0）；40 min soak **41 采样 pid 恒定、0 pid_lost、0 fault_new、0 重启**；7 hap 抽装 7/7（2 Blazor BLZ_BOOT/RENDERED）。预签件（68,447,288 B / `e9fb1e90…`、assets 617093322/617094016）7/7 `verify-app`、tester UDID 单值、条目逐字节一致，**未安装**。
> 轮次：08:59:56 取锁（owner=soak51）→ 09:00:04–09:42 干净 40 min 轮 → 09:44–09:52 L2/child web → 09:53 帧率 → 09:55–09:57 churn → 09:58–10:00 焦点链 → 10:02–10:07 抽装 → 10:08 还原（kit #49 主 hap + kit #50 Blazor nocsp）并释放锁。

## 1. 资产 / 设备 / 纪律

- kit tar sha `e5f6541c…` == 发布；in-kit `verify-kit` tree `a06d3897…`、sums/sidecar ok；主 hap 本地重签 `61bcf38d0c5f…`。预签 tar `e9fb1e90…`、sidecar `96948b04…`（88 B）、树 `2877f21f…`、sums 8/8、7/7 verify-app（UDID `60CF7B27…` 单值）、entry-invariance PASS。
- 设备 HAD-W32 / OH 7.0.0.109（软件 7.0.0.111）/ API 26；常亮 + hilog 16M（轮末还原 512K）；锁 `mkdir .device-lock` owner=soak51，10:08 释放未强拆。静止核对：l2cap=无、uitest=0、WMS 残留 0、AWAKE。

## 2. 安装 / 启动（AOT，干净轮）

- verify ok → 重签 → install/start rc=0，**pid 14647**、`runtime_mode=aot(hap)`、`aot_route=1` → first_frame ok（`canvas presented` + `frames/first.jpeg`）→ tester-run v14 probe ok；归档 `soak-round-clean-20261007-094208.tar.gz`（43,587,972 B / `adaf800e…`）。

## 3. L2 新面：子窗全链 / child web / a11y 并存 / SEC6-C

- **demo**（`app://subwindow/demo`，pid 14647）：create id=2579（120,160 720×480）→ move 420,360 → **resize 900×600**（WMS `newRect=[420 360 900 600]`）→ close；touch 窗内 delta=2 / 窗外 delta=0（不串窗）；`uitest swipe` 不触发 PanGesture（drag=0，注入面限制同 #50）；WMS 残留 0。
- **child web**（`app://subwindow/openweb`）×3 循环：`child web capacity advertised: max=2 → slot create: 0 → attached: slot 0 → page (slot 0): …CHILD-WEB…`，chromium `web_render` 子进程起；managed 窗口状态标签与 DOM 标题截图实证 `child web eval='CHILD-WEB' tap='CHILD WEB TAP'`（`l2b-web-crop.png`）；**a11y 并存**：`subwindow a11y provider status=1 instance=sub-1` + `a11y selfcheck status=1 nodes=12`（主窗 72 节点口径承 release）；关窗 `child web cmd: slot destroy`→`slot destroy: 0`→`subwindow surface sub-1 unregistered=1`→`[maui] subwindow closed`，WMS=0、pid 恒定。
- **SEC6-C 复核**：关窗后重开，capacity 再广播（max=2）+ slot create/attached/page 再通、`slot rejected=0`；关窗再次 0 残留 → 关窗池表清理与新实例重建均正常。首过脚本的 `resize/registered/eval timeout` 为 #50 期 needle 与 36 s 状态镜像窗差异（既有 always-on 标记 + 专项复跑全对，见证据 `out/l2/l2-focused-recheck.txt`）；`set window title failed` E（子窗创建瞬时）与 #49 同类已登记。

## 4. churn ×20 / Home 焦点链 ×10 / 帧率

- **churn ×20**（`app://subwindow/open`→close，pid 4744）：20/20 onLoad+surface registered+closed+unregistered 1:1；WMS 残留 **0/20**；threads 70–73、RSS 249,836→259,012 kB（+9.2 MB 热身，无趋势）。
- **Home 焦点链 ×10**：Home→`suspended (no active window)`→`aa start`→`resumed (window active)`；10/10 每轮 1/1；pid 恒定、threads 70–71、RSS +0.5 MB；末次 close→WMS 0 + `unregistered=1`。
- **帧率**（relay 三连 dump）：单窗 main **60.0**（n=301 avg 16.7 / max 21 ms，long=0）；双窗 main **60.0**（max 20 ms）+ sub-1 **60.0**（max 17 ms），`windows=2`/`first frame=True` ×3；主窗退化 0%。

## 5. 40 min soak（09:01:25–09:42:00，单窗安装态）

- **41 采样**：pid 14647 首=末；**pid_lost=0 / fault_new=0**；`updateTime` `1791334822400` 首=末；power 恒 AWAKE；RSS 236,136→203,524 kB（min 193,588 / max 248,332 = GC 锯齿，无累积）；threads 67–70；0 CppCrash/AppFreeze/JSCRASH；watcher 3 s 轮询 0 pid 迁移；**无环境干扰**（无 l2cap/uitest/他方 force-stop；hilog 无 `TerminateAbility` 命中本包）。

## 6. 抽装 / 预签 / 证据 / 提交

- **7 hap 抽装 7/7**（10:02–10:07，unsigned 逐件本机重签）：5 MAUI install OK + first frame/canvas（markers 14/5/5/4/4）；Blazor default/nocsp install OK + `BLZ_BOOT`+`BLZ_RENDERED`；表 `out/spot/spot-all.tsv`。
- **预签（未装）**：sha/sidecar/sums/tree + 7/7 verify-app + ZIP 条目不变式 PASS（详见 §1）。
- 证据 tar：`reg-kit51/soak51/soak51-evidence.tar.gz`（**56,622,678 B / `8d0c9620…`**；含干净轮归档/soak samples+meta/frames、L2 全链与专项复跑 + 截图 + 聚焦记录、churn/suspend CSV+dump、fps 解析、预签、抽装、脚本与 SUMMARY）。
- 提交：本文件 + README 索引（runtime-ohos `feature/openharmony`；commit-paths 限定路径，普通推送，未强推）。

## 7. 边界 / 降级注

- 子窗 a11y **动作 e2e** 与 ArkWeb **hybrid/blazor 资产桥**为 #51 声明降级（不判点）；子窗按钮 tap 在 480 px 视口外无法 uitest 命中（与 swipe/drag 同类注入面限制）；managed `Closed/Suspended` 事件仅页载后 ~36 s 镜像窗进 hilog（以壳侧标记为主证）；单设备 2in1 debug 域。
