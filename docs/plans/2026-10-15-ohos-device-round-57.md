# DEVICE-ROUND-57 + SOAK57 + 三卡：kit #57 发布件真机背书（RC2-OFFICIAL + CG2-R2R / AOT-STARTUP / FIXRR；零构建；HAD-W32；2026-10-15）

> 结论：**kit #57 发布件**（tar 70,428,755 B / `bc0e8c47…`、树 `a1d72306…`（设备侧 `verify-kit` KIT OK/0 FAIL）、sidecar OK；预签 70,242,500 B / `52baf033…`、内层 sums 8/8、`verify-app` 7/7、**本机 install rc=0**（tester-UDID 约束连续第三轮未被执行，见 §9））在 HAD-W32（OpenHarmony-7.0.0.109 / API 26 / UDID `1BCE13C8…`）完成 **零构建发布件冒烟 + 三卡补齐（#56 豁免项）+ 全量轮 + 40 min soak**。**冒烟**：发布 digest 对口（remote `sha256:bc0e8c47…` = 本地，asset **640146927**）→ 预签装机 rc=0 → launcher 身份（labelId 16777217 / iconId 16777231、1×INTERNET granted `grantStatus=0`）→ 主窗 `canvas presented` → fault diff 0。**三卡**：① **CG2-R2R**：JIT IL vs JIT+R2R（本机签名件，静态 `hello-maui-app.dll` 1,040,896 B→2,873,856 B、`RTR\0`×0→×1）冷启 ×3——**main→present：IL 554/508/514 ms vs R2R 248/245/223 ms（−266…−306 ms，−0.3 s 档；#48 基准 −321 ms）**、AMS→present IL 1.37–1.51 s vs R2R 1.05–1.12 s；两路径 0 崩、pid 尾活；② **AOT-STARTUP**：发布 AOT 件 `XComponent AttachToMainTree→native OnSurfaceCreated` = **14 ms / 14 ms**（#48 档 ≈13–14 ms，无回归；主窗 2090×1324 n≈285 avg 16–17 ms）；③ **FIXRR**：interp rc2b 件（`runtime-mode.txt=interp` + `libclrinterpreter.so` 随包）冷启 ×3 平位（main→present 613/580/588 ms、0 崩；宿主 `interp=3→DOTNET_ReadyToRun=0` 语义沿用 #48 判例；宿主 `interp=` 行本镜像 `hilog -x` 不可见，见 §9）。**主判点 1 RC2-OFFICIAL**：装机 AOT 件 `libhello-maui-app.so`（19,659,504 B / `84d09f52…`）含官方 **`11.0.0-rc.2.26504.105`×3（SDK/BCL 线）+ `11.0.0-rc.2.26505.5`（官方 MAUI）**+ rc.1 残留引用；`abc` 637,224 B / `8503a3c2…`；功能面同 #56（§6 全绿）。**全量轮 + soak**（§5）：预签主件（23,760,825 B / `d446d593…`）首装 rc=0、pid **51281** 首=末、`runtime_mode=aot(hap)`、first-frame + tester-run v14 probe ok；双窗 22:27:35 常驻（capacity max=2）；**41 采样 pid_lost=0 / fault_new=0**、RSS 215,436–258,824 kB、threads 69–77、`updateTime` 不变。**工具注记**：本沙箱普通 `hdc`（ohos-clt/SDK 版）看不到设备（历史 UDS 门），全程使用补丁版 **`/data/storage/el2/base/tmp/opencode/hdcpatched/hdcp4`**（smoke/三卡/轮/面/还原一律经它）——见 §1。
> 轮次（设备钟 2026-10-14）：22:08:40 取锁（owner=device-round-57）→ 22:08:54–22:09:00 预签面（sha/sidecar/inner OK、verify-app 7/7、直装 rc=0、卸载待净装）→ 22:09:10–22:09:35 冒烟 → 22:10:07–22:17:30 三卡（IL/R2R/interp 各 ×3 冷启 + AOT-STARTUP ×2；静态 RTR/interp 记录）→ 22:26:24 全量轮开始（树核验 + 装/启/首帧 22:27:13）→ 22:27:35 双窗注入 → 22:27:44–23:08:21 soak（41 采样，23:08:33 归档）→ 23:09:03–23:30:34 面链（faces + fixups + clipboard + matrix）→ 23:39–23:41 matrix-redo + 还原（PRE55 `all` 回装、hilog 512K、23:41:52 释放锁）。

## 1. 资产 / 设备 / 纪律（hdcp4 工具注记）
- kit：本地 tar sha `bc0e8c47…` == 发布 asset **640146927**（GitHub API digest 口径，冒烟记录 `out/smoke/digest-check.txt`）；设备轮 `--expect-tree-digest a1d72306…` → `verify-kit` = **KIT OK**（0 FAIL/0 WARN、sums ok、sidecar ok）。
- 预签（asset **640169891** / sidecar **640171632**）：tar `52baf033…` / sidecar OK；内层 `SHA256SUMS` 8/8；`verify-app` 7/7（裸调用需 `-outCertChain/-outProfile`）；**直装 rc=0**（见 §9 边界）。
- 三卡件（均为本机 UDID 签名、上游已构建件，零构建只跑）：IL `135,688,505 B`（`hello-maui-app.dll` 1,040,896 B / `RTR\0`=0）、R2R `147,389,459 B`（dll 2,873,856 B / `RTR\0`=1，位置 2088）、interp `136,172,287 B`（dll 1,040,896 B、`libclrinterpreter.so` 在包、`runtime-mode.txt=interp`）。
- 设备：HAD-W32 / `OpenHarmony-7.0.0.109` / API 26 / UDID `1BCE13C8…AEA0`；`const.product.software.version` 字面为 `HAD-W24 7.0.0.111(SP7ENTC293E104R2P1log)`（与 fullname `.109` 两参数字面不一致，原样记录）；uptime ≈3 天 10 h、**系统负载 ≈27**（时序类数字按相对差判读）。
- **hdcp4 工具注记**：`/data/storage/el2/base/tmp/opencode/hdcpatched/hdcp4`（补丁版；`shell/install/uninstall/file send|recv` 实测可用）是沙箱内唯一能看到 `127.0.0.1:36823` 的 hdc；`device-round-57/bin/*` 的 `HDC` 全部指向它，`cut-kit57/hooks` 就绪脚本按需以 HDC 覆盖使用。注意本镜像 `hilog -x` 看不到宿主进程的 `interp=`/`runtime-mode=` OH_LOG 行（仅状态文件镜像可见）——见 §9。
- 纪律：只读已发布件，零构建；#49–#57 资产未动；唯一非发布件 = PRE55-INTEGRATION `all` 探针件（`6a628964…`，clipboard 面 + 还原目标，显式标注）；hilog 16M→512K 还原；互斥锁独占 22:08:40–23:41:52。

## 2. 冒烟（22:09:10–22:09:35；证据 `out/smoke/`）
- digest：remote `sha256:bc0e8c47…` vs 本地 `bc0e8c47…` → **match=YES**（size 70,428,755；asset 640146927）；kit sidecar OK。
- 预签装机：`install -r preSigned/hello-maui-app.hap`（23,760,825 B / `d446d593…`）**rc=0**；净首装（先卸载）再次 rc=0。
- launcher 身份：`bm`: labelId **16777217** / iconId **16777231** / nperms=**1**（`ohos.permission.INTERNET`）；`atm`: `grantStatus=0`（grantFlag=4）；开始菜单节点 `hello-maui-app` 命中。
- 主窗：`aa start` → `canvas presented` ✓（启动行存档）；fault（`hidumper -e --list` before/after）**diff=0**。

## 3. 三卡（22:10:07–22:17:30；口径 = handoff §1.2 / runbook §2.3；证据 `out/cards/`）
- **CG2-R2R**（冷启 ×3，hilog `[startup]`；`cards-table-final.txt`）：

  | 件 | main→present (ms) | created→present | surfaceCreated→present | AMS→present |
  |---|---|---|---|---|
  | JIT IL | 554 / 508 / 514 | 43/42/42 | 5/3/4 | 1510/1372/1392 |
  | JIT+R2R | 248 / 245 / 223 | 19/20/19 | 30/29/30 | 1123/1080/1054 |

  判定：**R2R ≤ IL（−266…−306 ms，−0.3 s 档）**；两路径 0 崩、pid 尾活；R2R 件静态含 `RTR\0`（IL 无）。
- **AOT-STARTUP**（发布 AOT 主件，冷启 ×2）：`XComponent[ohos_dotnet_surface] AttachToMainTree → native OnSurfaceCreated` = **14 ms**（run1 40.868→40.882、run2 55.894→55.908）；宿主行 `jitfort: skipped runtime-mode=aot`、`OHOS_HOST start_app aot=1`（dlopen ok）；主窗 `canvas presented (2090x1324) n≈285 avg 16–17 ms max 19–278 ms`。判定：**无回归（#48 档 ≈13–14 ms）**。
- **FIXRR**（interp rc2b，冷启 ×3）：main→present 613/580/588 ms、AMS→present 2081/1494/1509 ms；0 崩；宿主路线 `OHOS_HOST start_app aot=0`（JIT 路由，清单 `interp=3` 由宿主代码置 `DOTNET_InterpMode` + `DOTNET_ReadyToRun=0`，与 runtime `InterpMode>=2 → fReadyToRun=false` 同效——判例沿用 #48）。判定：**interp 平位、不执行 R2R 原生码（宿主显式关闭）**；宿主 `interp=` 日志行本镜像不可见（§9），该行以构建侧语义 + 静态面为准。
- 卡件运行全程不新增 fault（faultlist 尾项仍为 10-08/10-09 历史项）。

## 4. #57 主判点 1：RC2-OFFICIAL（装机件 = 官方 .105/.29 线）
- `libs/arm64-v8a/libhello-maui-app.so`（19,659,504 B / `84d09f52…`）：**`11.0.0-rc.2.26504.105`×3**（SDK/runtime 官方线，AOT 原生 + BCL）+ **`11.0.0-rc.2.26505.5`**（官方 MAUI）+ `11.0.0-rc.1.26425.128` 残留引用 ×1。
- `libopenharmonyhost.so` 367,520 B / `8826adde…`；`abc` 637,224 B / `8503a3c2…`（PANDA `0d000100…`）；`dotnet.zip`（rawfile）200,140 B / `eb34f8ba…`（9 项纯 web 资产；BCL 已 AOT 并入原生件）。
- 功能面同 #56（§6 承接口径复核全绿）。

## 5. 全量轮 + 40 min soak（22:26:24–23:08:33；证据 `out/soak-round-clean/`）
- 树核验 OK（`a1d72306…`）→ 预签主件安装/启动 rc=0：pid **51281**、`runtime_mode=aot(hap)` → first_frame ok（`canvas presented` + `frames/first.jpeg`）→ tester-run v14 dry-run probe ok；归档 `soak-round-clean-20261014-230833.tar.gz`（47,834,162 B）。
- 双窗注入 22:27:35（sub-1）/22:27:36（sub-2）：`capacity max=2 surface=sub-1|sub-2`、subs=2 常驻；负载点 m=10/20/30（`soak-load`：m20 DOM 捕到 `CHILD WEB TAP 1`）。
- **41 采样**（60 s tick）：pid 首=末 51281；**pid_lost=0 / fault_new=0**；power 恒 AWAKE；RSS **215,436–258,824 kB**（t0 241,812 → t40 237,644 锯齿）、threads **69–77**；`updateTime` `1791987999053` 首=末。表（每 5 min）：`t0 241,812/77 · t5 258,604/71 · t10 226,720/70 · t15 233,192/71 · t20 238,044/71 · t25 232,356/71 · t30 237,504/70 · t35 237,584/70 · t40 237,644/70`。
- 全轮 fault diff 0（round + soak + faces）。

## 6. 承 #56/#55 面（同一发布 hap；证据 `out/{face}/`）
- deeplink：`app://web/datahash` 落地 **1 s**（slot 2 页 1 击）；nohash 孪生 `hash=False title=MAIN-DATA-NOHASH` ✓。
- modal：N 控制 `ops=`（抽屉外点关闭）；M1 `app://web/windowopen` `ops=slot,data` + hud `A REUSE WRITE`、`push_ok=0` 行；像素带首跑 band white 96.95%（模态面），复拍受遮挡混叠（DOM/hud 为主口径）。
- launcher：A/B 双轮 `bm` 同值（16777217/16777231、1×INTERNET）；A 轮 canvas 超时（窗口竞争）→ B 轮 canvas+开始菜单节点 ✓；图标染色以 fixups 复拍为准：**colorful 56.1% / blueish 56.5% / nonwhite 55.8%**（36×36 crop）。
- 子窗默认 4：open #1–#4（subs 1/2/3/4、identity gen2/3/4、created=4）；第 5 窗拒（subs 保持 4）；close `remaining=3`；重开复用 sub-4 **gen5**；单子窗 ENTER → `subwindow event TextSubmitted: id=1388 surface=sub-4 text='seed很好了'` + 镜像 `child entry completed 'seed很好了'` ✓（fixups 单子窗复跑 `text='seed'` + 镜像 ✓）。
- a11y：双窗 provider `status=1` ×2、selfcheck `nodes=10` ×2、`nodes=0` 总 0、`published 10 nodes`；定向关 wms=1、重开 selfcheck nodes=10 ✓。
- N=2 child web：eval `CHILD-WEB-1/2`、slot_create=2 / attached=2 / rejected=0、capacity max=2 ×2；DOM tap 命中（`tap2_node=1/tap1_node=1`）；close wms=1、重开 wms=2 identity=2 ✓。
- media：静态两修（`media.html` 23,043/`9733ce4d…` `LocalSliceLoader`+`local-slice`、`hls.min.js` 619,692/`a12e7ee1…`、`hls.LICENSE.txt` 1,338/`ca8773cf…`）；T20 探针 `entry Success → load Unavailable（-1）+ tone written`；子窗媒体 `cm slot=0 supported=True`/`play=Success`/`stop=Success claimed=True`/`close released=True mainAlive=True`；主窗 after-play `state=Error`（样本未随包）；`me slot=/me opened` 0 行（探针未随件）。
- touchpaste（opt-in 门控）：abc 标记全在案（`touch-paste.enabled`×1 / `OHOS_TOUCH_PASTE`×2 / `PasteButton`×3 / `opt-in unset`×1 / `bubble shown`×1）；托管 .so 0 标记（默认关构造性）；发布件长按注入 0 浮层、`app://touchpaste/*` 0 行；长按表面 diag 未达页（遮挡，§9）。
- webauth：warm `myapp://callback?code=SECRET1/2` 送达（title `activation 4: …SECRET1`、`activation 5: …SECRET2`）+ 负控 `notcallback` 0 + cold 带 want 启动（`callback_lines=2 canvas=9`）+ `app://webauth/*` 0 行。
- clipboard：发布件 `probe_lines=0`（探针未随件）；探针件（PRE55 `all`，显式标注）写 `ROUND57-W-1` 11B → 服务 `SetPasteData rawDataSize=375`；`has=False`/`read null`/`roundtrip wrote=12B read=null`（ACL 边界，不判失败；`check permission failed` 口径同 #55/#56）。
- 权限矩阵（matrix-redo 干净复跑）：默认件 = **1×INTERNET**；`-permissions` → **9568289**（`grant request permissions failed. READ_CONTACTS`；hdc rc=0 quirk、bm 保持前值）；api20 → **9568297**（镜像级）；`all`（PRE55，8 非 ACL）rc=0 = 还原目标。
- fps（系统负载 ≈27 下）：单窗 main last **57.6**（mean 57.6，n=288 avg 17.4 ms）；双窗 main **57.8**（mean 57.3）/ sub-1 **57.8** / sub-2 **56.2**（mean 54.1）；canvas avg 17.0 ms。与 #55/#56 的 60.0 档差距记入负载/遮挡注（不作为回归判定）。
- fixups：webauth callback 行 20；开始菜单网格图标复拍 56.1%/56.5%；单子窗 ENTER `TextSubmitted text='seed'` + 镜像 completed ✓。

## 7. 门禁（off-device，在案不复跑）
- 套件 814/817 floor 797；导出 164/164；abc 637,224/`8503a3c2…`、宿主 367,520/`8826adde…`（发布说明在案）。设备侧 kit 树 `a1d72306…` = KIT OK。零构建不复跑套件。

## 8. 证据 / 还原 / 提交
- 证据：`device-round-57-evidence.tar.gz`（**111,587,782 B / `d8dfa83b…`**，354 条目：smoke（digest/install/identity/hilog）、presign（verify-app 7/7/inner sums/install-attempt）、cards（12 组 hilog+lines+静态表 `cards-table-final.txt`）、soak-round-clean（summary/steps/samples/meta/frames/core/sign）、soak-watch/inject/load、faces（deeplink/modal/launcher/subwin/a11y/n2/media/touchpaste/webauth/fps×2）、fixups、clipboard、matrix + matrix-redo、rc2align、keep（pre-state/fault）、bin/logs、SUMMARY.md、doc-draft.md）。
- 还原：PRE55 `all` hap（`6a628964…`）回装 rc=0 + 停 app（pid 空/WMS 0）+ hilog **512K** + 锁释放 **23:41:52**（owner=device-round-57）；post `maui_updateTime=1791992511107`、labelId 16777217。
- 提交：本文件 + README 索引行（commit-paths 限路径）→ runtime `feature/openharmony`（HTTP/1.1；API 旁路备用；禁强推）。

## 9. 边界 / 降级注
- **预签 UDID 约束本镜像未执行（第三轮）**：tester-UDID 单值预签件 `install -r` rc=0——维持"视镜像/安装通道"注。
- **宿主 `interp=`/`runtime-mode=` OH_LOG 行在本镜像 `hilog -x` 不可见**（仅状态文件镜像的 `jitfort:`/`start_app:` 行可见；`/proc/<pid>/environ` 亦不可读）→ FIXRR/AOT 的"宿主行"证据以状态行 + 静态面 + 构建语义为准（工具注记，非产品缺陷；建议下轮在宿主侧把 mode 行也写入状态文件，或提供可读通道）。
- 零构建 → touch-paste 运行负控的长按未达页（遮挡/坐标）、webauth 激活状态行以 title 通道为准、media 样本/探针未随件——探针类面沿用 #56 口径。
- 系统负载 ≈27 持续（uptime 3 天+，并行会话窗口活跃）→ fps 57–58 档与 launcher A 轮 canvas 超时按环境注记录，不判回归；结构性/日志类判点（digest/install/bm/atm/卡表/soak/a11y/n2/subwin/矩阵）不受影响。
- 权限矩阵 face 首跑从探针件在位态开始（A 行实捕 8 权限）→ 以 **matrix-redo**（发布件干净复跑）为矩阵口径。
- 其余 #56/#55 降级卡照旧（clipboard 真读=ACL、api20 镜像级、池满 2 槽、2in1 debug 域、>64 MiB 无 Range、DRM 无、touch-paste opt-in 门控等）。
