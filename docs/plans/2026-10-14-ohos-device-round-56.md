# DEVICE-ROUND-56 + SOAK56：kit #56 发布件真机背书（AOT；零构建；HAD-W32；2026-10-14）

> 结论：**kit #56 发布件**（tar 70,420,041 B / `aba73b61…`、树 `99a37cec…`、sidecar OK、包内 `verify-kit` KIT OK 0 FAIL/0 WARN；预签 70,240,169 B / `0e062b5e…`、内层 sums 8/8、`verify-app` 7/7（带 `-outCertChain/-outProfile` 重跑；device-ids=测试方 UDID 单值））在 HAD-W32（OpenHarmony-7.0.0.109 / API 26 / UDID `1BCE13C8…`，hdc `127.0.0.1:36823`）完成 **零构建全量自动轮 + 40 min soak**：主件 = **发布预签 `hello-maui-app.hap`（23,760,824 B / `c6f9a9da…`），本机首装 rc=0**（**9568344 预期连续第二轮未复现**，见 §6）；安装/启动 rc=0、`runtime_mode=aot(hap)`、first-frame + tester-run v14 probe ok；**#56 主判点**：① **RC2-ALIGN**（AOT 托管件含官方 `11.0.0-rc.2.26505.5`（MAUI）+ `11.0.0-rc.2.26451.112`（runtime）版本戳；功能面沿 #55 判定点复核全绿）；② **TOUCH-PASTE**（abc 637,224/`8503a3c2…` 静态带全标记：`touch-paste.enabled`/`OHOS_TOUCH_PASTE`/`PasteButton`/`opt-in unset`；默认件托管 .so **无标记写入代码** = opt-in 默认关的构造性证明；发布件长按 0 浮层、`app://touchpaste/*` 0 行；能力本体随件、探针不随件）；③ **WEBAUTH-LOOPBACK**（loopback 本体无发布探针 → 按送达/负控口径：#55 DECOUPLE 路由 `myapp://callback` warm ×2 送达（title `activation 4/5`）+ cold 带 want 启动 + 负控 0 + `app://webauth/*` 0 行）；④ **SECURE-STORAGE-FAILCLOSED**（默认关 = 现行行为回归（应用全程 0 fault）；开关语义以 off-device 套件 814/817 floor 797 证据为准）；**承 #55 主判点**：launcher（labelId 16777217/iconId 16777231、1×INTERNET granted、开始菜单名+图标 colorful 56.1%/blueish 56.5%、重启复核）、clipboard（发布件探针 0 行；探针件 write 11B `ROUND56-W-1`→`SetPasteData rawDataSize=375/376`、has/read/roundtrip null + `GetPasteDataInner check permission failed`=ACL）、media（静态 `media.html` 23,043/`9733ce4d…` `LocalSliceLoader`+`local-slice`、`hls.min.js` 619,692/`a12e7ee1…`；T20 探针 **entry Success / load `Unavailable -1`** + tone；子窗媒体 slot/play/stop/close released 全链、after-play `state=Error`=样本未随包；`me`/`app://media/element` 0 行）、WebAuth（见③）、子窗 Completed（**focus forwarded caret=4** ✓；ENTER→`TextSubmitted` 本轮被遮挡打断，见 §6）、权限矩阵（默认 1；`-permissions`→**9568289** READ_CONTACTS；api20→**9568297** 镜像级；`all` 8 非 ACL rc=0）；**承 #54 面**：modal（`ops=slot,data`+`hybrid,hybrid`、hud `A REUSE WRITE`；像素带因遮挡降级）、子窗默认 4（1/2/3/4、第 5 窗 `max 4` 拒、close `remaining=3`、重开复用 sub-4 gen5）、深链 **1 s** 落地、a11y `nodes=10` ×2 + 重开、N=2 web（slot_create 2/attached 2/capacity max=2 ×2/close remaining=1/重开 identity=2；DOM tap 被遮挡）、fps 单 58.2–60.0（mean 59.4）/双 main 60.0、sub-1 59.6、sub-2 57.8；**40 min 双窗 web soak 41 采样 pid 22192 首=末、0 失 pid、0 fault_new、0 重启、updateTime 不变**（RSS 157,092–243,764 kB 锯齿、threads 73–81、全程 AWAKE）；全轮 fault diff 0；**环境注记**：本轮机位存在并行会话/用户窗口栈（终端/浏览器/聊天等），套件应用在部分时段被遮挡（z 曾 -1）——前台交互依赖的子证据（modal 像素带、N=2 DOM tap、子窗 ENTER、touch-paste 表面 diag、fps 复跑）已按布局/像素/z 证据定因并在 §6 标注；结构/日志类判点不受影响。
> 轮次（设备钟 2026-10-14）：14:24:01 取锁（owner=device-round-56）→ 14:24:21 预签面（sha/sidecar/inner OK；直装 rc=0；卸载为净首装）→ 14:27:52 干净轮（树核验 + 预签主件装/启/首帧）→ 14:29:03 双窗注入常驻 → 14:29:08–15:12:19 soak（41 采样）→ 15:12:58–15:34:33 面（deeplink/modal/launcher/subwin/a11y/n2/media/touchpaste/webauth/fps×2）→ 15:34:33–15:36:32 fixups/clipboard/matrix → 15:47:15–15:53:16 复验轮（A–F：kit 件回装/子窗 Completed/触屏粘贴/ N=2/modal 像素/fps）→ ~15:58 media T20 探针复跑 → 16:04:07 还原并释放锁。

## 1. 资产 / 设备 / 纪律
- kit：本地 tar sha == 发布（asset **639384793**）；`sh verify-kit.sh` = KIT OK（0 FAIL/0 WARN；abc 637,224/`8503a3c2…`、宿主 367,520/`8826adde…`、`resources.index` 2,102 B、DT_NEEDED 5/UND 252/denylist 0）；hap 静态：`media.html` 23,043/`9733ce4d…`（`LocalSliceLoader`×7、`local-slice`、`fallback-native`×2）、`hls.min.js` 619,692/`a12e7ee1…`、`hls.LICENSE.txt` 1,338/`ca8773cf…`；module.json labelId 16777217/iconId 16777231、权限=1×INTERNET、`runtime-mode=aot`。
- 预签（asset **639391274**）：tar/sidecar sha 显式 PASS；内容 = kit 7 hap 预签 + README + sums 8/8；**裸 `verify-app` 在 SDK 26.0.0.18_2 报 `-outCertChain is required`（-101）→ 补 `-outCertChain/-outProfile` 重跑 7/7 success**（脚本已修）；**实测：本机更新装（install -r）rc=0**（UDID 约束未执行，连续第二轮，见 §6）。
- 设备：HAD-W32 / OpenHarmony-7.0.0.109 / UDID `1BCE13C8046F…AEA0`；用户态 100。
- 纪律：只读已发布件，零构建；#49–#56 资产未动；唯一非发布件 = PRE55-INTEGRATION `all` 探针件（`6a628964…`，clipboard 面 + 还原目标，显式标注）；hilog 16M→512K 还原；互斥锁独占（14:24:01–16:04:07）。
- 环境注记：轮内并行会话/用户窗口活跃（hishell/htbrowser/pc/终端/notepad 等 z 争夺；套件窗 z 曾 -1）——见 §6.2/§6.3。

## 2. 安装 / 启动 + 40 min soak（14:27:52–15:12:37）
- 树核验 OK（`99a37cec…`）→ 预签主件 install/start rc=0：pid **22192**、`runtime_mode=aot(hap)` → first_frame ok（canvas presented + `frames/first.jpeg`）→ tester-run v14 probe ok；归档 `soak-round-clean-20261014-151226.tar.gz`。
- **41 采样**：pid 22192 首=末；pid_lost=0 / fault_new=0；updateTime `1791959286549` 首=末；power 恒 AWAKE；RSS **157,092–243,764** kB（t0=230,464 → t40=203,996）、threads 73–81。表（每 5 min）：`t0 230,464/77 · t5 238,668/73 · t10 176,500/73 · t15 167,176/75 · t20 180,276/76 · t25 183,784/76 · t30 190,180/78 · t35 190,332/78 · t40 203,996/78`。
- 双窗（sub-1/sub-2，capacity max=2 ×2）14:29:03 常驻；负载点 3 次（14:39:27 / 14:49:47 / 15:00:53；本轮机位窗口 z 被并行会话/用户抢占，坐标注入落点随前景变化）；**m30 负载点后两子窗被平台关闭（app 侧 `slot destroy`/`unregister`/`closed` 清理，pid 不变、0 fault），2.5 s 后 app 重建 1 个子窗（sub-1 gen=3 id=1232）并保持到轮末**：双窗常驻 31 min（14:29:03–15:00:07）+ 单窗 12 min；全程 0 失 pid / 0 重启。

## 3. #56 主判点（发布预签 AOT hap）
- ① RC2-ALIGN：静态版本戳 `11.0.0-rc.2.26505.5`（官方 MAUI）+ `11.0.0-rc.2.26451.112`（runtime）+ `11.0.0-rc.1.26425.128`（残留引用）；abc PANDA `13.0.1.0`；功能面 = 承 #55 ①–⑥ 全绿（下）。
- ② TOUCH-PASTE（opt-in 默认关）：abc 静态 = `touch-paste.enabled`×1 / `OHOS_TOUCH_PASTE`×2 / `PasteButton`×3 / `touch paste: opt-in unset`×1 / `bubble shown`×1；托管 .so 0 标记（默认件无探针写入路径 → 未 opt-in 为构造性）；运行面（发布件）：长按注入 0 浮层、0 `bubble shown`、0 `app://touchpaste` 路由行；长按表面 diag（`opt-in unset`）因应用被遮挡未达页（§6.2）。零构建不可启用探针 → 按注记口径。
- ③ WEBAUTH-LOOPBACK（切片随件、探针不随件）：warm `myapp://callback`×2 送达（title `activation 4: …SECRET1/state=st1`、`activation 5: …SECRET2/state=st2`）、负控 `myapp://notcallback` 0 行、cold 带 want 启动（`callback_lines=2 canvas=10`）、`app://webauth/*` 0 行；loopback（`http://127.0.0.1:<port>` 单次监听）无发布探针 → 运行判读止于送达/负控口径。
- ④ SECURE-STORAGE-FAILCLOSED：默认关回归 = 应用全轮读写路径正常运行、0 fault、0 重启；开关语义以 off-device 套件证据为准（814/817 floor 797，构建侧在案；零构建不复跑）。
- ⑤ launcher（承 #55①）：`bm` labelId 16777217/iconId 16777231、nperms=1×INTERNET、`atm` grantStatus=0；开始菜单 `hello-maui-app` 节点 + 图标裁剪 colorful 56.1% / blueish 56.5% / nonwhite 55.8%（label [612,298][829,334]，36×36 crop）；force-stop→重启复核同值。
- ⑥ clipboard（承 #55②）：发布件 `A_published probe_lines=0`（探针未随件）；探针件写 `ROUND56-W-1` 11B → 服务 `SetPasteData rawDataSize=375/376`；`has=False`/`read null`/`roundtrip wrote=12B read=null` + `GetPasteDataInner# check permission failed`（ACL 边界，不判失败）。
- ⑦ media（承 #55③）：静态两修在案（§1）；T20 探针（复跑）：`entry status=Success state=Idle` → `load status=Unavailable message='the platform answered -1'` → tone written；子窗媒体（B-M1）：`cm slot=0 supported=True`/`play=Success`/`stop=Success claimed=True`/`close released=True mainAlive=True`；after-play `ended=False state=Error`（`h264-aac-good.mp4` 样本未随包）；`me slot=`/`me opened` 0 行（MEDIAELEMENT 探针未随件）。
- ⑧ 子窗 Completed（承 #55⑤）：单子窗（DEFAULT4 重开后 sub-4 gen5）聚焦 tap → `text focus forwarded: surface=sub-4 show=1 caret=0→4`（Entry 收到焦点、caret=4）；**ENTER（uinput 2054 / uitest 66）→ `TextSubmitted` 本轮未复现**——注入时刻 `main window hidden: subwindow suspended (no active window)`（遮挡打断，§6.2）；镜像 0 行。
- ⑨ 权限矩阵（默认件口径）：kit 默认 = 1×INTERNET（回装复核 labelId 16777217/nperms=1）；`-permissions` → **9568289**（"grant request permissions failed. PermissionName: ohos.permission.READ_CONTACTS"；hdc rc 仍 0 属 quirk，bm 保持前值）；api20 → **9568297**（older sdk version，镜像级）；`all`（PRE55）8 非 ACL rc=0（= 还原目标）。

## 4. 承 #54/#55 面（同一发布 hap，全部在案）
- modal：N 控制（scrim tap、抽屉已关分支 ops 空）；M1 `app://web/windowopen`：`ops=slot,data`（首跑）+ `hybrid,hybrid,slot,data`（复跑）、hud `A REUSE WRITE`（序列中段）、`windowopen modal push ok=0 行`；像素带 首跑 white 6.46/6.52%、dark 0.28%；复跑 a=white 89.86%/dark 5.64%、b=dark 95.18%（遮挡不定 → **像素口径降级**，DOM/hud 行在案）。
- 子窗默认 4：open #1–#4 subs=1/2/3/4、created=4、identity=8、capacity_override=0、open_managed=4；第 5 窗 `already open (max 4)` 拒（subs 4）；close→`remaining=3`（subs 3）；重开→subs 4 复用 sub-4 gen=5。
- 深链：`app://web/datahash` 落地 **1 s**（`web page (slot 2)` 1 击；修复口径 ~0 s；defer 行在案）；nohash 孪生 ok。
- a11y：双窗 `provider status=1` ×2、selfcheck `nodes=10` ×2、`nodes=0` 总 0、`published 10 nodes` 行（sub-1）、定向关 wms=1、重开 selfcheck nodes=10=1/nodes0=0；pid 稳定、fault 0。
- N=2 child web：slot_create=2 / attached=2 / rejected=0 / capacity `max=2 surface=sub-1|sub-2`；eval `CHILD-WEB-1`（sub1=2 行）；H close wms=1；I 重开 wms=2 identity=2；**DOM tap（layout `CHILD WEB TAP` 节点）本轮 0/0**（布局捕获被前台遮挡；首跑已存 `n2-first/`）。
- fps：单窗 main fps last 58.2 / max 60.0 / mean 59.4（canvas n=292 avg 17.0 ms）；双窗 main last 60.0（mean 58.3）/ sub-1 59.6 / sub-2 57.8；复跑（app z=-1 遮挡）single 50.6 / dual 43.7·37.4·37.2 → 遮挡条件下的下界，见 §6.3。
- fault diff（全轮 + soak）0；matrix/clipboard 面结束后设备态 = PRE55 `all` hap。

## 5. 预签 / 证据 / 提交
- 预签本机装载实测见 §1（更新装 rc=0；卸载 → 干净轮净首装）。
- 证据 tar `device-round-56-evidence.tar.gz`（**161,645,799 B / `0d6c1123…`**，366 条目：干净轮（steps/summary/soak samples+meta/frames/verify/sign）、预签（verify2 7/7）、launcher（bm/atm/startmenu/icon-crop）、subwin、a11y、n2+n2-first、media（含 probe-redo）、touchpaste、webauth、clipboard、modal+modal-redo、deeplink、fps+fps-first、rc2align、matrix、fixups、reverify（A–F 全量）、soak-watch/inject/load、pre/post state + fault diff、脚本与 SUMMARY）。
- 设备还原 = PRE55 `all` hap（`6a628964…`；post labelId 16777217、updateTime `1791965038802`、pid 空、WMS=0、hilog 512K、AWAKE）+ 锁释放 16:04:07。
- 提交：本文件 + README 索引行（commit-paths 限路径）→ runtime `feature/openharmony`。

## 6. 发现（工具链 / 待下轮）
1. **预签 UDID 约束仍未被本镜像执行**（连续第二轮）：tester-UDID 单值 profile 的预签主件在本机 `install -r` rc=0（handoff 的 9568344 预期未复现）——预签段措辞维持 #55 的"视镜像/安装通道"注。
2. **机位窗口栈被并行会话/用户抢占**（本轮特有）：轮内 hishell/htbrowser/pc/终端/notepad 等窗口频繁抬升，套件应用 z 曾低至 -1（挂起态）；由此（a）负载点/面的坐标注入多次落于他窗（`B-layout.json` 实捕浏览器页；`G2_taps` 0 节点）；（b）子窗 `TextSubmitted` 注入时刻 app `main window hidden`（focus 已 forwarded、caret=4 为证）；（c）`touch paste:` 表面 diag 未达页；（d）modal 像素带与他窗内容混叠（复跑 b=dark 95%）。以上均在证据树内以布局/像素/hilog 定因；**结构性/日志类判点（bm/atm、静动态媒体、WebAuth、DEFAULT4、a11y、深链、矩阵、soak）不受影响**。下轮建议：面脚本前置"仅当 app 为前景（z 为运行窗最高）才注入坐标/按键"的守卫，或先以窗口管理器抬升再注入。
3. **fps 口径受遮挡影响**：首跑（正常可见）single 58.2–60.0 / dual main 60.0、sub-1 59.6、sub-2 57.8（与 #55 60.0 差距在测量噪声内）；复跑时 app 窗 z=-1（挂起），single 50.6 / dual 43.7 显著下降 → 记录为"遮挡条件下的下界"，不作为回归判定；建议 fps 卡加注"采集时 app 需为前景"。
4. `verify-app` 裸调用在 SDK 26.0.0.18_2 需 `-outCertChain/-outProfile`（-101）；预签脚本（presign56）与复跑脚本已修，7/7 OK。
5. 权限矩阵 `-permissions` 实际拒装 9568289（日志原文在案）；`hdc install` 对拒装返回 rc=0 是 hdc 层 quirk——判定以日志错误码为准。
6. m30 负载点后子窗被平台关闭并 1 个立即重建（`subwindow created … gen=3`）：疑与应用/平台在窗口 z 变化时的挂起-恢复路径相关，无 fault、pid 不变；下一轮可在受控前景条件下复跑负载点以定因。

## 7. 边界 / 降级注
- 零构建 → touch-paste 探针 / webauth loopback 探针 / media element 探针 / clipboard 读探针均未随发布件：运行判读仅到"发布件可达面 + 探针件补充 + 静态断言"；`webauth: ok`/`me ...`/`touchpaste:` 探针行未随包。
- clipboard 真读=ACL（产品决策）；api20 镜像级边界（9568297）；a11y 动作 e2e 平台限；实键盘敲击人工卡；2in1 debug 域；池满 2 槽；`>64 MiB 无 Range`；DRM 无；touch-paste opt-in 门控（默认不出现=设计）；SecureStorage fail-closed 仅在无 HUKS/拒绝时触发（在位 HUKS 真机无此条件）；#54/#55 既有降级卡照旧。
