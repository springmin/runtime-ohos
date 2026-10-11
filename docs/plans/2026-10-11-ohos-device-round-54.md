# DEVICE-ROUND-54 + SOAK54：kit #54 发布件真机背书（AOT，HAD-W32；2026-10-11）

> 结论：**kit #54 发布件（tar 69,301,436 B / `ecc41f05…`、树 `c0099033…`、sidecar OK、`verify-kit` KIT OK、sums 18/18）在 HAD-W32 2in1（OpenHarmony-7.0.0.109 / API 26 / UDID `1BCE13C8…`，hdc `127.0.0.1:36823`）完成 AOT 真机轮**：安装/启动 rc=0、首帧 + `runtime-mode=aot(hap)`、tester-run v14 probe ok；**本版新增面**：④ 模态 overlay 出画（模态 WebView 带内 DOM 文本像素 dark 0.90/0.81% vs 非模态 hybridA 7.17%）、⑤ 子窗默认 4（open #1–#4 → subs 1/2/3/4 + 第 5 窗 `max 4` 拒 + close remaining=3 + 重开复用 sub-4）、⑥ 深链修复落地 **0s**（`slot defer: 2 data`→`web page (slot 2)` MAIN-DATA-HASH）、① 主窗媒体（slot=2/opened 1000ms 360x240/ended Completed/seek+pause 冻结/audio/stop claimed/close released）、② 子窗媒体（slot=0 win=sub-1/ended/stop claimed/close released）、③ 本地 HLS（hlslocal 与 hlsrange 均 ended Completed 999/999/360x240 + 2×206 Range）、⑦ WebAuth（SECRET1/2 `ok code=… state=…`、cancel、timeout、错误 URI 不完成）；⑧ 承 #53（a11y `nodes=10` ×2 · N=2/web · churn ×20 · Home ×10 · 60.0 fps）；**40 min 双窗 web soak 41 采样 pid 2644 首=末、0 pid_lost、0 fault_new、0 重启**（updateTime 不变）；7 hap 抽装 7/7（2 Blazor `BLZ_BOOT`/`BLZ_RENDERED`）；预签件（69,144,076 / `c4806485…`，tester UDID）7/7 `verify-app` + 条目逐字节一致（**未安装**）。
> 轮次：18:46:19 取锁（owner=soak54）→ 18:46:44–19:29:06 干净 40 min 轮（18:47:57 注入双窗 child ArkWeb，soak t=0 起双窗常驻）→ 19:31–19:40 ⑥/④ → 19:41–19:45 ⑤ + a11y + N=2 → 19:47–20:01 churn×2 + Home + fps → 20:03–20:38 探针 hap ①②③⑦（含一 build）→ 20:38–20:40 抽装 → 20:40:47 还原并释放锁。

## 1. 资产 / 设备 / 纪律
> **rev2 已执行（2026-10-11）**：本文记录的真机轮针对 rev1 字节；rev2 成套替换后的值：kit tar **70,345,291 B / `583d6df43961d371e666dcc078a63a41530d9dc4c74d7c6d7375e0b3c7171f09`**、树 `251d0c43ab5b5146845febc4afee53187e56513ee4a375f4cd7327c2b7462c09`、sidecar 89 B / `094165d72ec079920862bf9ada268da55634a87aba3833f7c3eb1f9a65522543`（预签/轮包见 release rev2 注）。

- kit tar sha `ecc41f05…` == 发布（dtk asset 392356147）；in-kit `verify-kit.sh --expect-tree-digest c0099033…` = KIT OK 0 FAIL/0 WARN（KIT 内 sidecar+anchor 校验）；主 hap 本机重签 `564336bf0765…`（AOT，bundle com.example.hellomauiapp）。
- 预签：tar/侧车 sha 显式比对 PASS、SUMS 8/8、`verify-app` 7/7（UDID `60CF7B27…` 单值）、ZIP 条目与 kit 原件逐字节一致（**未安装**）。
- 设备 HAD-W32 / OH 7.0.0.109（API 26）；常亮 + hilog 16M→512K 还原；#49–#53 资产未动；仅 1 次构建（walk: 20:05–20:07 AOT 探针）+ 早先两次失败探针构建（工具链注 §6）。
- **本版重点面载体**：④⑤⑥⑧ 在**发布 AOT hap** 上跑；①②③⑦ 在**探针 hap**（同一发布 pin：ow `34b53ea`/maui `36da77cba492`，AOT，`-p:MediaElementProbe=true -p:WebAuthProbe=true` 编译探针，手补壳 rawfile `media.html/hls.min.js` + 媒体样本 + `myapp://callback` 清单注入；sha `1cf7fd4f…`）——因发布 hap 未带这些探针/壳资源（§6 发现）。

## 2. 安装 / 启动 + 40 min soak（18:46:44–19:29:06）

- verify ok（tree `c0099033…`）→ 重签 → install/start rc=0：pid **2644**、`runtime_mode=aot(hap)` → first_frame ok（canvas presented + `frames/first.jpeg`）→ tester-run v14 probe ok；归档 `soak-round-clean-20261011-192858.tar.gz`（61,796,633 B / `93ddff70…`）。
- **41 采样**：pid 2644 首=末；pid_lost=0 / fault_new=0；updateTime `1791715624344` 首=末；power 恒 AWAKE；RSS 223,068–292,276 kB（GC 锯齿，t40=226,840）；threads 72–77。双窗常驻：18:47:57 subs=2、capacity `max=2` ×2（sub-1/sub-2），m=10/20/30 按窗 tap 保持 subs=2/pid 恒定（m≥20 DOM dump 记 `[none]`——hishell 前台抢占，已归因）。watcher 仅 1 次 pid 迁移（44540→NA = 装包前 force-stop，非失稳）。

## 3. 重点面（④⑤⑥⑧ 发布 hap；①②③⑦ 探针 hap）

- ④ **模态 overlay 出画**：`app://web/windowopen` 模态 WebView 截图（snapshot_display）带内 DOM 文本（`A REUSE WRITE`）——模态 WebView 带 (896,304)-(2704,700) 白 97.0/97.2%、dark 0.90/0.81%（text cluster 628/526 px；纯占位=全白 0 dark）；HUD 到 `A REUSE WRITE`；非模态对照 boot hybridA 7.17%（Hybrid A/B 出画）。本轮抽屉未呈现（boot 无 `hide/suspend`，模态 ops=`slot,data`，走状态机“无抽屉静默”分支）；抽屉 `resume` 抬升分支沿用 MODAL-OVERLAY-FIX 真机证据（同 slice `36da77cba492`）。
- ⑤ **子窗默认 4**：open #1–#4 → subs 1/2/3/4、`subwindow created` ×4、identity sub-1..4（gen 2–4）、**0 容量覆盖日志**；第 5 窗 `managed child windows already open (max 4)` + subs 保持 4；close → subs=3/`remaining=3`；重开 → subs=4 复用 `sub-4`（gen 5）。faults 0。
- ⑥ **深链修复**：静默 15 s 后 `app://web/datahash` **0s 落地**（`web slot defer: 2 data` → `web page (slot 2): data:…MAIN-DATA-HASH`）；无 `#` 双生 `app://web/datanohash` slot 页 + eval 回读 `title='MAIN-DATA-NOHASH' p='plain value'`。
- ① 主窗媒体（rawfile H.264/AAC）：`me slot=2 supported=True` → `play status=Success` → `opened dur=1000ms size=360x240` → `after-play ended=True state=Completed pos=1000ms seen=804ms states=Prepared/Playing/Playing/Paused/Completed/` → `transport seek=Success resume=Success pause=Success posBeforePause=127ms posAfterPause=127ms pauseState=Paused resumeAgain=Success` → `audio mute/volume/unmute=Success` → `stop=Success slot=2 claimed=True` → `close released=True mainWindowAlive=True`；长样（30 s/853x480）`ended=False state=Playing pos=9809ms` + 模态 M2 截图视频帧出画（band colorful 28.74%；NTSC 853x480 彩条 00:00:08:00 可见）。
- ② 子窗媒体（B-M1）：`cm slot=0 supported=True win=sub-1` → `cm play=Success` → `cm after-play ended=True state=Completed pos=1000ms seen=805ms` → `cm stop=Success claimed=True` → `cm close released=True mainAlive=True win=sub-1 slot=0`（壳 `child web cmd:` 过滤窗内只摘到 `frame s0/32`，slot destroy 行未落窗——以 managed release 为准，单遍镜窗口径）。
- ③ 本地 HLS（hls.js/MSE）：`hlslocal`（分段）`after-play ended=True state=Completed pos=999ms dur=999ms size=360x240`；`hlsrange`（单文件 BYTERANGE）暖路径同 `ended=True Completed 999/999` + `media range (slot 2): bytes=0-789 → bytes 0-789/39739`、`bytes=790-39738 → …/39739`（206）。
- ⑦ WebAuth（真回跳）：`app://webauth/start` → `aa start myapp://callback?code=SECRET1&state=st1` → `webauth: ok code=SECRET1 state=st1`；SECRET2 热复跑同；`webauth: canceled`、`timeout 3s` → `webauth: timeout canceled`、错误 URI（`myapp://notcallback`）ok 增量 0、0 RuntimeError。

## 4. ⑧ 承 #53（同一 AOT hap）

- a11y selfcheck：双窗 `provider status=1`、`selfcheck nodes=10` ×2、全轮 `nodes=0`=0、关 1 窗→重开 `nodes=10`、主窗 pid 恒定 0 fault；N=2/web：identity g4/g5、双 web `eval CHILD-WEB-1/2` ×2 + `slot create/attached` 2/0 rejected、两窗各自 DOM `CHILD WEB TAP 1/2`（不串）、定向关 `remaining=1` + 重开 gen6（输入分窗本轮仅 `focus forwarded sub-2` + caret=4 落文本；sub-1 focus 行出镜窗，承 #53 全链）。
- churn ×20：**第二遍 20/20 exact subs 1/2/1/0、0 pid 迁移**（第一遍 19/20 + 1 次 pid 迁移无 fault 记录 = 干扰面，承 #50 归因类；pass1/pass2 均留档）；Home ×10：每轮双窗 `subwindow suspended` + `aa start` resumed 10/10；fps：单窗 main 60.0、双窗 main/sub-1/sub-2 60.0（long=0 longruns=0）。

## 5. 抽装 / 预签 / 证据 / 提交

- 7 hap 抽装 7/7：5 MAUI `managed app … started` + `canvas presented`；Blazor default/nocsp 各 `BLZ_BOOT`+`BLZ_RENDERED`；末步回装前先重置 fixture 再装探针。
- 预签见 §1；设备还原 = fixture `l7m2-s2.hap` `f78695d5…`（pre-state 件；post-restore updateTime `1791722446983`、hilog 512K、WMS=0、AWAKE、app 停止）+ 释放锁 20:40:47。
- 证据 tar：`reg-kit54/soak54/soak54-evidence.tar.gz`（**77,760,631 B / `92d76031…`**，263 件）含干净轮归档/soak samples+meta/注入/按窗负载、④⑤⑥⑧、①②③（含 hls 暖路径/冷启复现对照）、⑦、churn pass1/pass2、探针 build+sign、pre/post state、脚本与 SUMMARY。
- 提交：本文件 + README 索引（commit-paths.sh 限路径）→ runtime `feature/openharmony`。

## 6. 发现（工具链 / 待下轮）

- **kit #54 预置 hap 的 pack 目标过期**：P1 用 `~/.dotnet.rc2-fix` 的 preview.28 pack（targets 为 10-07 版）→ 预置 hap 缺 `resources/rawfile/media.html`（A-M1 壳契约）与 WebAuth 回调清单注入（与 repo pack 对比 0/0 vs 4/2 处）；预置 hap 上 MediaElement 将降级 Failed、WebAuth 回跳不路由。探针 hap 手补复现全链；**建议 #55 cut 前刷新 rc2-fix pack（--install-packs / pack-sync）并把 media.html 列入 P0 校验**。
- `make-mode-kit.sh --mode aot` 不含 `-p:InvariantGlobalization=true`（kit/publish-aot 有）→ 漏传则 AOT 启动即 ICU FailFast（本 session 两件已复现并修复）；建议 mode-kit aot 默认该属性。
- 冷启后立即触发媒体页存在 page-bridge 竞态（`fragLoadError` / 首 `play` ack Unavailable）；**暖路径全通**；同序列在 #54 前 wave hap（JIT `623,732`/maui `54631780a3`）冷启同样复现 → **非本版回归**（MEDIA-MICRO 记的 page-end 竞态族；建议下轮插桩钉 query 注入时序）。

## 7. 边界 / 降级注

- modal 抽屉呈现分支本轮未复现（走无抽屉静默分支；DOM/像素证据见 §3）；子窗 slot destroy 过滤窗缺失（managed release 为准）；churn pass1 的 1 次 pid 迁移为干扰面（无 fault 记录）；冷启媒体竞态见 §6；2in1 debug 域（E1）与既有降级卡照旧。
