# DEVICE-ROUND-55 + SOAK55：kit #55 发布件真机背书（AOT；零构建；HAD-W32；2026-10-13）

> 结论：**kit #55 发布件**（tar 70,312,042 B / `504ea1ae…`、树 `7a226f9452…`、sidecar OK、包内 `verify-kit` KIT OK 0 FAIL/0 WARN；预签 70,151,840 B / `fcfb6085…`、内层 sums 8/8、`verify-app` 7/7（device-ids=测试方 UDID 单值）、ZIP 条目与 kit 7/7 逐字节一致）在 HAD-W32（OpenHarmony-7.0.0.109 / API 26 / UDID `1BCE13C8…`，hdc `127.0.0.1:36823`）完成 **零构建全量自动轮 + 40 min soak**：主件 = **发布预签 `hello-maui-app.hap`（23,732,082 B / `58601032…`），本机首装/更新均 rc=0**（安装/启动 rc=0、`runtime_mode=aot(hap)`、first-frame + tester-run v14 probe ok）；**主判点**：① launcher 身份（`bm` labelId 16777217/iconId 16777231、1×INTERNET granted、开始菜单名+图标 blueish 56.5% 染色、重启复核不变）；② clipboard（发布件探针未随件 0 行；探针件 write 11B→服务 `SetPasteData rawDataSize=376`、read/has/roundtrip=null + `GetPasteDataInner# check permission failed`）；③ media（发布件静态：`media.html` 23,043/`9733ce4d…` + `LocalSliceLoader`/`local-slice`、`hls.min.js` 619,692/`a12e7ee1…`；`app://media/element` 0 行=探针未随件；子窗媒体达 slot/play 但样本未随包→`Format error`）；④ WebAuth（默认件 skill 在案；warm `myapp://callback` ×2 送达（title `activation 5/6`）+ cold 带 want 启动 + 负控 `notcallback` 0 + 探针 UI 0 行）；⑤ 子窗 Completed（单子窗聚焦→`uinput` ENTER→`subwindow event TextSubmitted text='seed'`→镜像 `child entry completed 'seed'`）；⑥ 权限矩阵（默认 1 INTERNET；`-permissions` 6 含 READ_CONTACTS→**9568289 拒装**；api20→**9568297 镜像级**；`all` 8 非 ACL rc=0）；**40 min 双窗 web soak 41 采样 pid 6361 首=末、0 失 pid、0 fault_new、0 重启、updateTime 不变**（RSS 200,836–250,688 kB GC 锯齿、threads 70–77、双窗常驻 + 3 次按窗 tap）；承 #54 面：④ modal（无抽屉分支 ops=`slot,data`；模态 WebView DOM 文本出画，文本簇 2,481/2,564 px）、⑤ 子窗默认 4（subs 1/2/3/4、第 5 窗 `max 4` 拒、close `remaining=3`、reopen 复用 sub-4 gen5）、⑥ 深链 **0 s** 落地、⑧ a11y `nodes=10` ×2 + N=2 web（eval `CHILD-WEB-1/2`、slot 2/0 rejected、tap 不串、定向关/重开）+ fps 单 60.0 / 双 main+sub-1+sub-2 60.0；全轮 fault diff 0。
> 轮次（设备钟 2026-10-14）：06:12:37 取锁（owner=device-round-55）→ 06:13:53 干净轮（预签直装 + 06:15:05 双窗注入常驻）→ 06:15:13–06:55:54 soak → 06:57–07:17 面（deeplink/modal/launcher/subwin/a11y/n2/media/webauth/fps）→ 07:18–07:22 fixups（单子窗 Completed + 图标复核 + WebAuth 行）→ 07:21–07:23 clipboard + 权限矩阵 → 07:24:29 还原并释放锁。

## 1. 资产 / 设备 / 纪律
- kit：本地 tar sha == 发布（asset **637184336**）；`sh verify-kit.sh --tree-digest --expect-tree-digest 7a226f94…` = KIT OK；hap 内 abc **620,908/`c473b7be…`**、宿主 **367,520/`8826adde…`**、`resources.index` 2,102 B（RestoolV2）、module.json app labelId 16777218/iconId 16777231、权限=1×INTERNET（reason/usedScene）、skills=home+`myapp://callback`、`runtime-mode=aot`。
- 预签（asset **637199153**）：tar/sidecar sha 显式 PASS；内容 = kit 7 hap 预签 + README + sums 8/8；**实测本机（非 tester UDID）更新装与卸载后首装均 rc=0——`9568344` 预期未复现**（见 §6）。
- 纪律：只读已发布件，零构建；#49–#55 资产未动；唯一非发布件 = PRE55-INTEGRATION `all` 探针件（`6a628964…`，clipboard 面 + 还原目标，显式标注）；hilog 16M→512K 还原；互斥锁独占。

## 2. 安装 / 启动 + 40 min soak（06:13:53–06:55:54）
- verify ok（tree `7a226f94…`）→ 预签主件 install/start rc=0：pid **6361**、`runtime_mode=aot(hap)` → first_frame ok（canvas presented + `frames/first.jpeg`）→ tester-run v14 probe ok；归档 `soak-round-clean-20261014-065601.tar.gz`（47,691,178 B / `b27a61d9…`）。
- **41 采样**：pid 6361 首=末；pid_lost=0 / fault_new=0；updateTime `1791929650027` 首=末；power 恒 AWAKE；RSS **200,836–250,688** kB（t40=222,128）；threads 70–77。双窗（sub-1/sub-2，capacity max=2 ×2）常驻；按窗 tap 三次（注：injector 引用 54 脚本名的路径 bug 使首轮 load 晚至 t≈20，t≈27/34 正常；脚本已修，证据在案）。

## 3. #55 主判点（发布预签 AOT hap）
- ① launcher：`bm dump` labelId/iconId >0（16777217/16777231）、reqPermissions=1×INTERNET 且 `atm` grantStatus=0；开始菜单（hoskey）layout+截图含名称节点、图标带 36×36 蓝底（colorful 56.1%/blueish 56.5%）；force-stop→重启后复核不变。
- ② clipboard：发布件 `app://clipboard/*` 0 行（`-p:ClipboardProbe=true` 未随件）；探针件写通（`wrote 11B 'ROUND55-W-1'` + 服务 `SetPasteData rawDataSize=376`）、读路径恒 null（`check permission failed`，ACL 边界，不判失败）。
- ③ media：静态两修面在发布件在案（见结论③）；`app://media/probe`（T20 AVPlayer）load `Unavailable / platform answered -1`（非 #55 判点，记边界）；子窗媒体 `cm slot=0/play=Success/stop/close released` 全链达壳，源样本 `h264-aac-good.mp4` 未随包→页面 `NotSupportedError/Format error`（样本资产边界）。
- ④ WebAuth：默认件 module.json 带 `(myapp, callback)` skill（静态）；运行中 `aa start -U 'myapp://callback?code=SECRET1/2…'` → `activation 5/6`（title 通道，状态行异步 flush 未全量入 dump）；卸载/冷启带 callback want 启动（canvas ok）；`myapp://notcallback` 无激活行（负控 0）；`app://webauth/*` 0 行（探针 UI 未随件）。
- ⑤ 子窗 Completed：单子窗（open 1 个）聚焦 sub-1 Entry → `uinput -K -d/-u 2054` → `TextSubmitted id=1125 surface=sub-1 text='seed'` → 重启镜像 `child entry completed 'seed'`。
- ⑥ 权限矩阵：默认 1（INTERNET）；`-permissions`（6，含 READ_CONTACTS）install 9568289 拒装（ACL，与 `all`-skip-ACL 设计一致）；api20/api20-permissions 9568297（镜像级，不判失败）；PRE55 `all`（8 非 ACL）rc=0。

## 4. 承 #54 面（同一发布 hap，全部在案）
- ④ modal：`app://web/windowopen` 模态 WebView 出画（白模态面 + DOM 文本；主窗 rect dark 0.43%，文本簇 y603–643=2,481 px、y990–1040=2,564 px；`ops=slot,data` = 无抽屉分支，同 #54 本版分支）；⑤ 默认 4（见结论）；⑥ `app://web/datahash` **0 s** 落地 + nohash 回读；⑧ a11y provider/selfcheck sub-1/sub-2（`nodes=10` ×2、nodes0=0、关/重开复现）+ N=2（eval/slot/tap/remaining=1/重开）+ fps 单/双 60.0；3 hap 抽面（launcher/perms/api20）见上；fault diff（soak + 全轮）0。

## 5. 预签 / 证据 / 提交
- 预签本机装载实测见 §1（更新+首装 rc=0，条目不变）；证据 tar `device-round-55-evidence.tar.gz`（**92,664,162 B / `aacc26db…`**，272 条目：干净轮 + soak 样本/meta/归档、面输出（launcher/subwin/fixups/a11y/n2/media/webauth/clipboard/matrix/modal/deeplink/fps）、watch/inject/load、pre/post state + fault diff、脚本与 SUMMARY）。
- 设备还原 = PRE55 `all` hap（`6a628964…`；post labelId 16777217、updateTime `1791933866627`、pid 空、WMS=0、hilog 512K、AWAKE）+ 锁释放 07:24:29。
- 提交：本文件 + README 索引行（commit-paths 限路径）→ runtime `feature/openharmony`。

## 6. 发现（工具链 / 待下轮）
- **预签的 UDID 约束在本镜像未执行**：tester-UDID 单值 profile 的 7 件在本机更新装与首装均 rc=0（handoff/README 的「非该 UDID 报 9568344」未复现）——预签段措辞应按实机证据修正（或注明"视镜像/安装通道"）。
- **发布 hap 不带媒体样本与媒体探针**：kit/presign 的 5 MAUI hap 仅带壳 `media.html`/`hls.min.js`（static 两修在案），不带 `h264-aac-good.mp4`/`hlslocal/`/`hlsrange/` 样本与 `-p:MediaElementProbe=true` 触发器 → handoff §2 的 media 运行判读需探针建（或将样本入包）；子窗媒体链因缺样本止于 `Format error`。
- `-permissions` 变体带 READ_CONTACTS 在本镜像拒装（9568289）——矩阵"permissions 6"行应注明拒装边界（与 PASTEBOARD red-control 同因）。
- soak injector 路径 bug（引用 54 文件名）修复在案；`fd` 采样列本机恒 0（脚本列口径，非内存面）。
- T20 AVPlayer WAV load `-1`：非本版判点，记边界待下轮复核（#55 媒体面 = ArkWeb MediaElement）。

## 7. 边界 / 降级注
- 零构建 → 媒体两修/WebAuth ok/clipboard 读的运行时判读仅到"发布件可达面 + 探针件补充"；`webauth: ok`/`me ...` 探针行未随包；clipboard 真读=ACL（产品决策）；api20 镜像级边界；a11y 动作 e2e 平台限；2in1 debug 域；#54 既有降级卡照旧。
