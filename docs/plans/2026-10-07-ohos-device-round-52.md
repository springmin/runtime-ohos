# DEVICE-ROUND-52 + SOAK52：kit #52 发布件真机背书（AOT，HAD-W32；2026-10-07）

> 结论：**kit #52 发布件（tar 68,853,027 B / `9e60fdc0…`、树 `c1fa6421…`、sidecar ok、`verify-kit` KIT OK、sums 18/18）在 HAD-W32 2in1（OpenHarmony-7.0.0.109 / API 26 / UDID `1BCE13C8…`，hdc `127.0.0.1:35111`）完成 AOT 真机轮**：安装/启动 rc=0、首帧 + `runtime-mode=aot(hap)`、tester-run v14 probe ok；**L3 N=2 全链**——双窗 create（identity confirmed ×2，sub-1 gen=3/sub-2 gen=4）、双 a11y `status=1`（instance=sub-1/2 + selfcheck nodes=10 ×2）、输入分窗（focus forwarded sub-1 → inactive/active → blur sub-1 (focus moved)+focus sub-2，inputText caret=4+软键盘落文本 'seed'→'seed能'）、定向关（`closed: surface=sub-2 remaining=1`）+ 重开 gen 4→5；**双窗 child web 并发**（`openweb`×2：eval `CHILD-WEB-1/2`、capacity `max=2` surface=sub-1/2、slot create/attached 各 2、rejected=0；两窗各自 DOM `CHILD WEB TAP 1/2` 不串；关一窗→slot destroy、重开 capacity/slot/page 再通）；主窗 60fps 零回归（单/双 60.0，双窗 sub-1 59.9 / sub-2 60.0）；churn ×20（18/20 exact subs 1/2/1/0、pid 恒定、close2 0/20 残留）；Home 每窗 suspend/resume 10/10；**40 min 双窗 web soak 41 采样 pid 恒定、0 pid_lost、0 fault_new、0 重启**（updateTime 不变）；7 hap 抽装 7/7（2 Blazor `BLZ_BOOT`/`BLZ_RENDERED`）。预签件（68,732,127 B / `5abf7629…`，asset 618854752/618855844）7/7 `verify-app`、tester UDID `60CF7B27…` 单值、条目逐字节一致，**未安装**。
> 轮次：22:16:50 取锁（owner=soak52）→ 22:17:09–22:59:20 干净 40 min 轮（22:18:20 注入双窗 child ArkWeb，soak t=0 起双窗常驻）→ 23:01–23:07 N=2 全链 + IME 聚焦复跑 → 23:08–23:15 churn/Home → 23:19–23:24 fps → 23:24–23:28 抽装 → 23:29 预签 → 23:30 还原并释放锁。

## 1. 资产 / 设备 / 纪律

- kit tar sha `9e60fdc0…` == 发布；in-kit `verify-kit.sh --expected-abc 534192 --expect-tree-digest c1fa6421…` = KIT OK 0 FAIL/0 WARN、SHA256SUMS 18/18；主 hap 本机重签 `0c96c7b59737…`（AOT，bundle com.example.hellomauiapp）。
- 预签：tar sha/size/sidecar(88 B)/tree `b91b0036…` explicit compare PASS、SUMS 8/8、`verify-app` 7/7（UDID `60CF7B27…` 单值）、ZIP 条目不变式 PASS（asset 618854752/618855844 锚定；**未安装**）。
- 设备 HAD-W32 / OH 7.0.0.109（API 26）；常亮 + hilog 16M→512K 还原；锁 owner=soak52，23:30:33 释放；#49–#52 资产未动、无构建。

## 2. 安装 / 启动（AOT，干净轮 22:17:09–22:59:20）

- verify ok → 重签 → install/start rc=0：pid **33109**、`runtime_mode=aot(hap)` → first_frame ok（canvas presented + `frames/first.jpeg`）→ tester-run v14 probe ok；归档 `soak-round-clean-20261007-225913.tar.gz`（50,254,777 B）。

## 3. L3 N=2 全链 / 双窗 child web（23:01–23:07）

- create：WMS=2，`identity confirmed` ×2（sub-1 id=2746 gen=3、sub-2 id=2747 gen=4）；a11y `provider status=1 instance=sub-1/2` + `selfcheck nodes=10` ×2。
- 输入分窗：click sub-1 Entry(480,392) → `text input focused`+`focus forwarded surface=sub-1 caret=0`；click sub-2 暴露条(860,660)→Entry(528,440) → `inactive sub-1`/`active sub-2`、`blur forwarded surface=sub-1 (focus moved)`+`focus forwarded surface=sub-2 show=1`；inputText → caret 0→4、软键盘起、子窗 Entry 'seed'→'seed能'、主窗状态 `subwindow TextComposition id=2754`（`ime-after.jpeg`）。注：#49 期坐标 (140,300)/(780,620) 在合并 L3 布局不再命中 Entry（见证据 `n2/ime-focused.txt`）。
- 定向关/重开：`closed: surface=sub-2 remaining=1`、剩余窗存活；重开 → sub-2 gen=5 确认、WMS=2。
- 双窗 web：冷启后 `openweb`×2 → eval `CHILD-WEB-1/2` 回读、capacity `max=2 surface=sub-1/2`（各 2）、slot create=2/attached=2/rejected=0；dump 定位各自标题点按后 `CHILD WEB TAP 2`/`CHILD WEB TAP 1` 节点各自出现（不串）。关一窗 → `slot destroy`+remaining 文档保持、WMS=1；重开 → capacity+slot+attached+page `CHILD-WEB-2` 再通、rejected=0（重开期 eval 未再进状态镜像窗，按 #51 口径以 DOM/pool 常开标记为证）。
- Back：uitest Back 无 `window back: surface=` 标记 → 按 UI 注入限制记人工卡（离线 pin 覆盖路由）；子窗 alert 无样例 → 人工卡（承 #50/#51）。Z：G 期按计划冷启（33109→19574），非缺陷。

## 4. churn ×20 / Home 每窗 / 帧率（23:08–23:24）

- churn ×20（openweb A→B→close→close，pid 19574 恒定）：18/20 恰为 subs **1/2/1/0**；iter 9/10 两次 openweb 未成形（0/0/0/0，0 残留/0 fault，11 起恢复连续 10 轮 exact）；close2=0/20、RSS −15.9 MB、threads 76–79。
- Home 焦点链 ×10：每轮 `main window hidden`+`subwindow suspended surface=sub-1/sub-2`、`aa start` 后 `shown`+每窗 resumed；10/10 全计、WMS=2、pid 恒定。
- 帧率：单窗 main **60.0**（n=300 avg 16.7ms max 19ms long=0）；双窗 main **60.0** + sub-1 **59.9**（min 59.8）/ sub-2 **60.0**；`windows=2`/`first frame=True` ×3。

## 5. 40 min soak（双窗 web 负载，22:18:29–22:59:06）

- **41 采样**：pid 33109 首=末；**pid_lost=0 / fault_new=0**、0 重启；updateTime `1791382645104` 首=末；power 恒 AWAKE；RSS 254,768→233,548 kB（min 217,720 / max 271,564 = GC 锯齿，无趋势）；threads 71–76；watcher 3 s 轮询 0 迁移（唯一迁移 = 干净轮冷启 40303→33109，已核实）。
- 双窗常驻：capacity `max=2` surface=sub-1/2、a11y selfcheck ×2；DOM 实证 sub-1 `TAP 1`（22:20/22:37/t=25/t≈34 各次回读）与 sub-2 `TAP 2`（t=5 dump + 22:18 注入截图 managed 标签 `eval='CHILD-WEB-2' tap='CHILD WEB TAP 2'`）。
- 环境干扰核实：同机桌面控制台（hishell）会压到应用之上（z 122>119）；22:37 起 soak 负载先 `aa start` 抬升应用再点按（z 121/122/123），m=15 一次 dump 仅 691 B 为 hdc/hilog 瞬时（DOM 由 m=5/m=25/t≈34 复证）；churn 9/10 轮空开窗按同类扰动记录，均无 pid 丢失/崩溃归因。

## 6. 抽装 / 预签 / 证据 / 提交

- 7 hap 抽装 7/7（23:24–23:28）：5 MAUI OK + canvas markers 13/7/7/6/6；Blazor default/nocsp OK + `BLZ_BOOT`+`BLZ_RENDERED`；末步回装 kit #52 AOT 主 hap。
- 预签（未装）见 §1；释放锁后设备还原 = L3 JIT 主 hap `ac1005acbc…` + kit #50 Blazor nocsp `ff7a0d0c…`（post-restore：hilog 512K、WMS=0、AWAKE）。
- 证据 tar：`reg-kit52/soak52/soak52-evidence.tar.gz`（**61,631,779 B / `c7ff6f50…`**，153 件；含干净轮归档/soak samples+meta、注入与按窗负载、N=2 全链+IME 复跑、churn/Home/fps、抽装、预签、脚本与 SUMMARY）。
- 提交：本文件 + README 索引（commit-paths.sh 限定路径）；直推 runtime-ohos 被网络路径拒绝，按 Git Data API 旁路（不 force）。

## 7. 边界 / 降级注

- 状态镜像窗（主页面载后 ~36 s）外的 managed eval 行不落 hilog：soak 双窗以 DOM + capacity/attached/selfcheck 常开标记为证；重开期 eval 同此口径（#51 同款）。
- 子窗 a11y 动作 e2e、hybrid/Blazor 资产桥真机抽验、IME 人工卡、uitest Back/alert 注入限制、B6 未接、同槽 fail-closed、池满队列、`#` 截断、SEC-6 余留：#52 声明降级/继承，不判点；单设备 2in1 debug 域（E1）；同机控制台干扰已如实记录。
