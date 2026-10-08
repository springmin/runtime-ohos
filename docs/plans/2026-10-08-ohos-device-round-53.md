# DEVICE-ROUND-53 + SOAK53：kit #53 发布件真机背书（AOT，HAD-W32；2026-10-08）

> 结论：**kit #53 发布件（tar 68,883,057 B / `dba88961…`、树 `9c67b5ec…`、sidecar `47ace1d0…`、`verify-kit` KIT OK、sums 18/18）在 HAD-W32 2in1（OpenHarmony-7.0.0.109 / API 26 / UDID `1BCE13C8…`，hdc `127.0.0.1:35111`）完成 AOT 真机轮**：安装/启动 rc=0、首帧 + `runtime-mode=aot(hap)`、tester-run v14 probe ok；**a11y selfcheck 重点**——双窗 `provider status=1`、首发布 `selfcheck nodes=10 ×2`（`nodes=0` 计数 0）、20 s 复 dump 稳定保持、定向关/重开后 `nodes=10` 复现，主窗零回归（pid 恒定、0 fault、单/双窗 60.0 fps）；**B6 导航否决真机双链**——deny：`child web nav ask → child web navigating → child web navigating cancelled`（无 `nav` 命令/无批准，子页转 blocked 占位）；ok：`ask → child web cmd: nav s0 → child web nav approved → child web error(DNS) → child web cmd: hide s0`（完整 ask→approve→reload 闭环）；`//evil.invalid/x` 网络路径拼写 fail-closed（无批准）；N=2 全链（identity sub-1 g2/sub-2 g3、输入分窗 focus→blur→focus + IME 落文本 `seed→seed能查3`、定向关 `remaining=1` + 重开 g4、双窗 web `CHILD-WEB-1/2` eval + 各自 DOM tap 不串、关一窗 slot destroy + 重开 wms=2 rejected=0）；churn ×20 **20/20 exact 1/2/1/0**（pid 37873、0 残留）；Home 每窗 suspend/resume ×10 10/10；**40 min 双窗 web soak 41 采样 pid 28437 首=末、0 pid_lost、0 fault_new、0 重启**（updateTime 不变）；7 hap 抽装 7/7（2 Blazor `BLZ_BOOT`/`BLZ_RENDERED`）；预签件（68,755,353 B / `d1732195…`，asset 620760775/620762418）7/7 `verify-app`（tester UDID 单值、条目逐字节一致，**未安装**）。
> 轮次：13:08:17 取锁（owner=soak53）→ 13:08:24–13:50:37 干净 40 min 轮（13:09:37 注入双窗 child ArkWeb，soak t=0 起双窗常驻）→ 13:52–13:54 a11y selfcheck 轮 → 14:00–14:08 N=2 全链 + IME 复跑 → 14:09–14:13 B6 deny/ok/veto → 14:13–14:19 churn/Home → 14:20–14:22 fps → 14:22–14:27 抽装 → 14:28:51 还原并释放锁。

## 1. 资产 / 设备 / 纪律

- kit tar sha `dba88961…` == 发布（asset 620752460）；in-kit `verify-kit.sh --expect-tree-digest 9c67b5ec…` = KIT OK 0 FAIL/0 WARN、SHA256SUMS 18/18；主 hap 本机重签 `91dcc9be67…`（AOT，bundle com.example.hellomauiapp）。
- 预签：tar/侧车 sha explicit compare PASS、SUMS 8/8、`verify-app` 7/7（UDID `60CF7B27…` 单值）、ZIP 条目与 kit 原件逐字节一致（**未安装**）；assets 620760775/620762418。
- 设备 HAD-W32 / OH 7.0.0.109（API 26）；常亮 + hilog 16M→512K 还原；锁 owner=soak53，14:28:51 释放；#49–#53 资产未动、无构建（一次一构建）。

## 2. 安装 / 启动（AOT，干净轮 13:08:24–13:50:37）

- verify ok（tree `9c67b5ec…`）→ 重签 → install/start rc=0：pid **28437**、`runtime_mode=aot(hap)` → first_frame ok（canvas presented + `frames/first.jpeg`）→ tester-run v14 probe ok；归档 `soak-round-clean-20261008-135031.tar.gz`（48,804,221 B / `2da4371c…`）。

## 3. a11y selfcheck 重点（13:52–13:54）

- 双窗 `provider status=1`（sub-1/sub-2）；**首发布 selfcheck `nodes=10` ×2**、全轮 `nodes=0` 计数 **0**（修复前首发布时序症状消失）；`published 10 nodes through its own provider instance` 镜像窗内 sub-1×15；A1b/A1c 20 s 复 dump 保持 `nodes=10`。
- 定向关（wms=1）→ 重开（wms=2）：新窗 selfcheck `nodes=10`、`nodes=0`=0。主窗零回归：pid 17454 恒定、cpp/js/freeze=0/0/0、AWAKE；fps 见 §5。

## 4. B6 子窗导航否决（离线 pin = POST-L3 套件 737/740 floor 720，b6c ×5；本轮真机注入）

- deny（`https://example.invalid/b6c-deny`，点 369,461）：`child web nav ask (slot 0)` → managed `child web navigating` → `child web navigating cancelled: b6c-deny`；`child web cmd: nav`/`approved` 均 0（应用否决，获批路径不触发）。
- ok（`https://example.invalid/b6c`，点 344,412）：`ask → child web cmd: nav s0 → child web nav approved (slot 0) → child web error (slot 0)`（重载 DNS 失败，预期）`→ child web cmd: hide s0`。
- veto（`//evil.invalid/x`，点 614,364）：managed `about:blank#blocked`、无 ask/命令/批准（fail-closed 拒绝）；deny 后子页转 blocked 占位（`deny_after` 无 `CHILD WEB OK` 节点），ok/veto 以独立冷启轮各自取证。

## 5. L3 N=2 全链 / 双窗 web / churn / Home / fps（14:00–14:22）

- create：WMS=2、`identity confirmed` ×2（sub-1 id2892 g2、sub-2 id2893 g3）；a11y 同 §3；定向关 `closed: surface=sub-2 remaining=1`、重开 g4 id2894。
- 输入分窗（14:05–14:08 复跑）：click sub-1 Entry(480,392) → `text input focused` + `focus forwarded sub-1`；open sub-2 → click(860,660)/(528,440) → `blur forwarded sub-1 (focus moved)` + `focus forwarded sub-2`；inputText → caret 0→4、子窗 Entry `seed→seed能查3`（软键盘组字）、主窗状态镜像；全部经激活竞速注入（见 §8）。
- 双窗 web：capacity `max=2` sub-1/sub-2、slot create=2/attached=2/rejected=0、eval `CHILD-WEB-1/2` 各 2 行；dump 定位各自标题点按 → 两窗各自 DOM `CHILD WEB TAP 1/2`（不串）；关一窗 → `slot destroy` + 剩余文档保持、重开 wms=2 rejected=0（重开期 eval 未再进镜像窗，按 #51 口径以 DOM/pool 常开标记为证）。
- Back：uitest Back 无 `window back` 标记 → 人工卡（承 #50–#52）；Z 的 pid 变化 = G 段按计划冷启（22537→27460），非缺陷。
- churn ×20（openweb A→B→close→close，pid 37873）：**20/20 exact subs 1/2/1/0**、0 残留、RSS 259,136→245,748 kB、threads 73–77。
- Home ×10：每轮 `subwindow suspended ×2` + `main window hidden`、`aa start` 后每窗 resumed；10/10、wms=2、pid 恒定。
- 帧率：单窗 main **60.0**（n=301 avg 16.7ms max 22ms long=0）；双窗 main **60.0** + sub-1 **60.0** + sub-2 **60.0**（long=0）。

## 6. 40 min soak（双窗 web 负载，13:09:47–13:50:25）

- **41 采样**：pid 28437 首=末；**pid_lost=0 / fault_new=0**、0 重启；updateTime `1791436123905` 首=末；power 恒 AWAKE；RSS 250,120→214,532 kB（min 208,468 / max 275,120 = GC 锯齿）；threads 68–74；watcher 3 s 轮询仅记录冷启迁移（已核实）。
- 双窗常驻：capacity `max=2` surface=sub-1/2、slot create/attached、selfcheck `nodes=12 ×2`（web 子窗）；m=5 按窗 tap 命中 sub-2（`CHILD WEB TAP 2`）。环境干扰（如实记录）：同机桌面控制台（hishell）13:55 后被外部占用并持续抢前台，m=25/m=35 DOM dump 命中控制台（`dom=[none]`）；soak 本体指标不受影响。

## 7. 抽装 / 预签 / 证据 / 提交

- 7 hap 抽装 7/7（14:22–14:27）：5 MAUI OK + canvas markers 13/6/5/4/4；Blazor default/nocsp OK + `BLZ_BOOT` + `BLZ_RENDERED`；末步回装 kit #53 AOT 主 hap。
- 预签见 §1；设备还原 = 修复件主 hap `f75dfc91…`（JIT + A11Y-SELFCHECK，pre-state 原件）+ kit #50 Blazor nocsp `ff7a0d0c…`；post-restore：hilog 512K、WMS=0、AWAKE、主 app 已启动（pid 56705）。
- 证据 tar：`reg-kit53/soak53/soak53-evidence.tar.gz`（**62,960,168 B / `107155e6…`**）含干净轮归档/soak samples+meta、注入/按窗负载、a11y selfcheck 轮、B6 deny/ok/veto、N=2+IME 复跑、churn/Home/fps、抽装、预签、脚本与 SUMMARY。
- 提交：本文件 + README 索引（commit-paths.sh 限定路径）；直推 runtime-ohos 被网络路径拒绝，按 Git Data API 旁路（不 force）。

## 8. 边界 / 降级注

- 状态镜像窗（主页面载后 ~36 s）外的 managed eval 行不落 hilog：soak/重开期以 DOM + capacity/attached/selfcheck 常开标记为证（#51/#52 同口径）。
- 同机桌面控制台（hishell）持续抢占前台时，交互注入统一改用「`aa start` 激活 + 立即点击」竞速（实测点击/输入均到达，focus 转发行完整）；soak DOM tick 因此记 `dom=[none]`（已归因，非应用缺陷）。
- 子窗 a11y 动作 e2e、hybrid/Blazor 资产桥真机抽验、IME 人工卡（机制链完整，组字为软键盘行为）、uitest Back/alert 注入限制、同槽 fail-closed、池满队列、`#` 截断、SEC-6 余留：声明降级/继承，不判点；单设备 2in1 debug 域（E1）。
