# 测试方交接：kit #49、应用内子窗（MULTIWINDOW-M：create/move/resize/close + 主窗协同）+ a11y 密码脱敏（SEC-SCAN-4）（承 #48 CG2-R2R / AOT-STARTUP / FPS48 / MULTIWINDOW-S / FIXRR 与 #47/#46/#45 全量）（2026-10-05）

> 日期口径：文件名按撰写日；**kit #49 发布实测（release「## Integrity（kit #49）」；发布已完成，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **67,888,851 B / `477974bb…`**、树
> **`8d03cb4c…`**、sidecar **`3803b3db…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `b142639d…`**
> （#48 = tar 67,735,148 / `5c22704f…`、树 `6b2b493c…`、sidecar `1c51cdbc…`；#47 = 67,706,719 / `3d6bb58b…` 对照）。
> **预签已刷新至 #49**（7 hap；**67,807,185 / `56aaf08f…`**，asset **612929512**；sidecar 88 B /
> `4ba00cf8…`，asset **612930421**；树 `acce2fe9…`；替换 #48 件 612061141/612062470）——按 tester UDID
> `60CF7B27…` 预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**（非该 UDID 报 `9568344`）。
> 构建基线（rc.2 线，同 #34–#48）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（结构修复后重出，承 #42）**：rc.2 runtime pack 现取 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；
> `-r2`（601289590）/原包（`46d221f2…`）仅历史）；Crossgen2 rc.2 包（43,792,647 / `6bb8a375…`，
> `crossgen2-packs-11.0.0-rc.2`，JIT R2R 经 folder feed 消费）沿用 #48。
> **在途/外部（明确）**：AGC App Linking 登记 + 真机 https 投递；镜像扩展分支 `m-web-mirror d47f1fcb3b`
> 尚未并入 `feature/openharmony`；rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；stock JIT 长跑/
> 后台唤醒未覆盖（JIT 现非默认）；解释器混合模式（`interp.txt=1|2`）保留默认；L（真 OpenWindow 多窗：
> per-window renderer/surface/输入/a11y）未做。

> **结论先行**：kit #49 = **kit #48（CG2-R2R + AOT-STARTUP + FPS48 + MULTIWINDOW-S + FIXRR；
> 承 #47 FIX-A11YFLYOUT/FIX-PREEMPT-RAW 与 #46/#45 全量）
> + 应用内子窗（MULTIWINDOW-M：壳子窗控制器 create/move/resize/show/hide→Failed 801/close + 主窗 HIDDEN/SHOWN
> 挂起协同；宿主双导出；切片 OpenHarmonySubWindow；真机 `app://subwindow/demo` id=344 720×480→420,360→900×600→close）
> + a11y 密码脱敏（SEC-SCAN-4：影子树对密码发布等长圆点，不再发布明文）**，并承 #48 的 R2R/JIT 启动/首帧/帧率/多窗 S
> 与 #47–#35 各批。指纹：壳 abc **414,532（`e016db13…`）/ headless 24,324（`798b2477…`）**、宿主
> **301,984（`cf4cc706…`）**、导出 **153/153**、套件 **607/609 floor 589**、预签已刷新至 #49；
> 切片 `b093e33825`（maui，MULTIWINDOW-M ← `5f3efd55e5` SEC-SCAN-4 ← `ed02203bfd` MULTIWINDOW-S）+
> ow `16df9a3e`（pin `e0803bedad`），sdk 锚 `7abaf8132f`。判定点见 §2；承接 #48/#47/#45/#44/…/#34 的判定点
> **继续有效**，本文覆盖 #49 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（AOT —— #43 起默认；无需 ACL，属推荐路径）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# #49 主判点 1：子窗流程（手动；见 §2 —— app://subwindow/demo → create → move → resize → close，
#   再 app://subwindow/open → 点按/swipe，最后主窗最小化/恢复观察 suspended/resumed）
# #49 主判点 2：a11y 密码脱敏（进入含密码 Entry 的页面，`--a11y-probe` 或 `uitest` 抓影子树/
#   a11y dump，确认密码节点文本为等长圆点、明文不出现；离线红/绿已由交付方负控）
# 承 #48 主判点：R2R/JIT 启动数字 / AOT 冷启计时 / 帧率投票 / 多窗 S 尺寸（手动脚本见 §2）
# Blazor 探针（B2 走 MAUI WebView 内嵌 WASM；判定继续有效）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段用 kit 内 AOT hap；JIT 段需自建 jit 变体或 ACL；解释器轮改用 rc2b pack）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；**已刷新至 #49**）

`device-test-kit` release 的并列预签资产 **`preSigned-haps.tar.gz`** 当前为 **kit #49 件**（2026-10-05 重签；
asset **612929512**，**67,807,185 B / `56aaf08f…`**；sidecar 88 B / `4ba00cf8…`，asset **612930421**；
树 `acce2fe9…`；**内容 = kit #49 的 7 hap** + `preSigned-README.md` + `SHA256SUMS` 8/8；ZIP 条目与 kit
原件逐字节一致；7/7 `sign-hap.sh` + `verify-app` success、device-ids 单值 = tester UDID）。按 tester UDID
`60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19` 预签，`sha256sum -c SHA256SUMS` 后
`hdc install -r` **直装**；非 tester UDID 设备报 `9568344`。预签包是并列附加件，完整一轮仍用 kit tar。

## 1. kit #49 相对 #48 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **MULTIWINDOW-M（#49 主判点 1）** | 壳 `Window.createSubWindowWithOptions` 子窗控制器：命令 0 create/1 move/2 resize/3 show/4 hide（无公开 hide API：如实回 Failed 801）/5 close，事件 0 created…10 resumed；`pages/SubWindow.ets` 为壳绘 named-route（`ohos_dotnet_subwindow`，`WindowProperties.name` move guard，touch/drag hilog；无 create 零分配）；主窗 HIDDEN/SHOWN 转 suspended/resumed + 挂起期命令抑制；宿主 `registerSubWindowSink`/`notifySubWindowEvent` NAPI + `ohos_host_sub_window_command`（op 99 可用性探针）/`ohos_host_sub_window_event_listener`（导出 151→**153**）；切片 `OpenHarmonySubWindow`（IsSupported/IsOpen/IsVisible/IsSuspended/IsContentReady/WindowId/Bounds + Changed/Touched，Utf8JsonWriter/JsonDocument AOT 安全，离设备退化 false/无操作）。真机 HAD-W32：`app://subwindow/demo` create **id=344（120,160 720×480）** → page ready `name=ohos_dotnet_subwindow drag=on` → move **420,360** → resize **900×600** → close | 主判点 1 流程逐步成功（每步壳 hilog + 主页面状态行 + 截图：`app://subwindow/demo`；create id、move 坐标、resize 尺寸、close 后子窗消失）；`app://subwindow/open`（id=346）点按 `OHOS_MAUI_SUB touch #`、swipe `drag #` 生效；主窗 HIDDEN/SHOWN → `subwindow suspended/resumed`，主页面 60fps、无新 fault；隐藏 API 的 `hide→Failed 801` 是**如实降级**不判失败；单 surface 边界：子窗内容为壳侧自绘，非第二 MAUI 视觉树 |
| 1.2 | **SEC-SCAN-4：a11y 密码脱敏（#49 主判点 2）** | a11y 影子树不再发布密码明文：`OpenHarmonyAccessibility` 对 `IEntry{IsPassword}`/平台 `IsPassword` 走同一 `MaskPassword`，密码节点只发布等长圆点（绘制此前已脱敏）；套件 +2 pin（`a11y-password` 明文不得出现 + `draw cull edge` 零尺寸/shadow 外延/屏外 Image 不得剔除）；离线红/绿负控（还原切片修复重编 → `plainHidden=False masked=False assert=False`，exit 134；恢复后全 True）；**设备未验证** | 进入含密码 `Entry` 的页面，`--a11y-probe`/`uitest` 抓影子树或 a11y dump：密码节点文本为等长圆点、明文（如测试口令）不出现；读屏环境复跑朗读/焦点顺序/动作类（交付方沙箱无读屏客户端） |
| 1.3 | **承 #48：R2R/JIT 启动（CG2-R2R）** | rc.2 Crossgen2 包（43,792,647 / `6bb8a375…`）作 folder feed，JIT 自建包加 `-p:PublishReadyToRun=true`：IL→R2R 冷启 **1031→710 ms（−321 / −31%；n=3）**，进程内 present 575→307；R2R 件 +11 MB；interp 不启用（FIXRR） | JIT R2R 变体冷启 AMS→首帧 ≈0.71 s 档（≤0.8 s）、`hello-maui-app.dll` 含 `RTR\0`、`canvas presented`；与 IL 件对照 |
| 1.4 | **承 #48：AOT-STARTUP / FPS48 / MULTIWINDOW-S / FIXRR** | AOT 首帧 **796→534 ms（−33%）**、attach→surface 239→13；帧率投票 60（干扰态 46.2→60.0 fps）；多窗 S 最大化 2090×1394→3120×1955；interp R2R=0（`DOTNET_ReadyToRun=0` next to `DOTNET_InterpMode=3`，与 runtime 隐式 `fReadyToRun=false` 同效） | 同 #48 交接 §2 主判点 2–5；AOT kit 上继续适用 |
| 1.5 | **承 #47：FIX-A11YFLYOUT / FIX-PREEMPT-RAW（主判点）** | `PushChildren` 补 FlyoutPage Detail/Flyout 分支 → 真机 `--a11y-probe` **nodeCount 1→70**；`[maui-capacity]` 直写 hilog（`preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`） | 同 #47 交接 §2；读屏环境复跑 T2/L1/N1/F2/E1 |
| 1.6 | **承 #46/#45：INTERP-DRAW2 / FIX-A11YBUTTON / 自动释放 / INTERP-RENDER / 动态槽 / 默认 AOT / FRAMEPACING** | 同 #46/#45 交接 §1：interp draw 14.4→9.4 ms、33.9→60.1 fps；按钮左下角两态可达；Remove→`web slot destroy`→re-add→`web slot create`；interp ≥30 fps、meas≈0；3 控件并发 + 第 5 槽 LRU；`runtime-mode.txt=aot`、无 JIT 运行时；60.00 fps | 同 `2026-10-05-ohos-tester-handoff-kit47.md` / `…kit45.md` §2；AOT kit 上继续适用 |
| 1.7 | **承 #42–#35：JIT 解锁 / 解释器 rc2b / FIX-SLICERACE / L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c / MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX / FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10** | 见对应交接文；判定点继续有效 | 同前各期望（套件自报行更新为 `607/609 floor 589`） |
| 1.8 | **门禁/指纹/7 hap/预签** | 交互套件 **607/609 floor 589**（#49 +6 MULTIWINDOW-M；其中 +2 SEC-SCAN-4）、像素 `PIXEL ASSERTIONS PASSED`（43 PASS）、宿主导出契约 **153/153**、host UND **242**/DT_NEEDED 5/denylist 0；壳 abc **414,532（`e016db13…`）**/headless 24,324（`798b2477…`）、host **301,984（`cf4cc706…`）**；**7 hap**：5 MAUI 全 AOT + Blazor 默认/`-nocsp`；**预签刷新至 #49** | 包内 `sh verify-kit.sh --expected-abc 414532` → **0 FAIL / 0 WARN**（#49 包内脚本默认仍为 #48 的 375268，裸跑会对五个重建壳报 5 条历史 WARN；默认重锚 414532 已提交 ohos-workload `71fe00c`，随下一包生效）；`[suite] checks=607 total=609 floor=589 assert=True`；`runtime-mode.txt=aot` |
| 1.9 | **在途/外部项（明确）** | ①AGC App Linking 登记 + 真机 https 投递；②镜像分支 `m-web-mirror d47f1fcb3b` 未并入；③rc.2 csc 并行活锁（`DOTNET_PROCESSOR_COUNT=1` 绕过）；④stock JIT 长跑/后台唤醒未覆盖；⑤解释器混合模式保留默认；⑥L（真 OpenWindow 多窗：per-window renderer/surface/输入/a11y）未做 | ①–⑥ 登记「未测（在途）」，**不判失败** |

> **2026-10-05 复测回填（交付方口径，交测前以此为准）**：
> ① **MULTIWINDOW-M（#49 主判点 1）**：设备 HAD-W32（2in1，OpenHarmony 7.0.0.109 / API 26）——managed 深链
> `app://subwindow/demo`：create **id=344 (120,160 720×480)** → page ready `name=ohos_dotnet_subwindow drag=on`
> → move **420,360** → resize **900×600** → close；每步 shell hilog + 主页面状态行，截图 mw-seq1/2/3。
> `app://subwindow/open` id=346 后设备点击 → `OHOS_MAUI_SUB touch #57`（down/up 坐标）；`uiInput swipe` →
> `drag #51 -> 269,259`（PanGesture 自移动，截图 mw-drag）。协同：主窗 HIDDEN/SHOWN → `subwindow
> suspended/resumed`；主页面 `canvas presented (2090×1324) avg=16ms max=21ms`（60fps），close 后子窗消失，
> 无新 fault。`hide` 无公开 API 如实回 `Failed 801`。
> ② **SEC-SCAN-4（#49 主判点 2）**：离线读码 + 红/绿负控（还原修复重编 → `a11y-password plainHidden=False
> masked=False assert=False` 抛异常 exit 134；恢复后 `plainHidden=True masked=True assert=True`），并加
> `draw cull edge` 边界断言；**未上机**——设备可见结论一律「设备未验证」；另 6 项报告级（WebView 区 2 /
> 供应链 1 / 加固 3）按报告处置。
> ③ **承 #48 复测**：CG2-R2R 4 件 A/B（JIT IL 1031 vs R2R 710 ms、in-proc 575→307）；AOT pilot/aot-opt
> 同载荷 A/B（796→534 ms、attach→surface 239→13）；FPS48 stock/vote60（46.2→60.0）；MULTIWINDOW-S
> 最大化 3120×1955；FIXRR interp+R2R 614 ≈ IL 609。
> ④ **承 #47 复测**：a11y nodeCount 1→70（probe5 AOT）、抢占原文 5 行 `[maui-capacity]`（细节见 #47 交接回填）；
> INTERP-DRAW2 复测触 60 Hz 上界；SOAK-JI 三路径浸泡背书沿用。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **应用内子窗（#49 主判点 1，MULTIWINDOW-M）** | 装默认 kit 主 hap（AOT）→ 打开子窗样例页（`app://subwindow/demo` 流程）：create → move → resize → close；再 `app://subwindow/open` 后点按/拖动 | create **id=344 档（120,160 720×480）** → ready `name=ohos_dotnet_subwindow drag=on` → move 坐标跟随 → resize 尺寸跟随 → close 后子窗消失；touch/drag 事件生效；`hide` 如实 `Failed 801` | 每步壳 hilog + 主页面状态行 + 截图（create/move/resize/close 四态）；`OHOS_MAUI_SUB touch #`/`drag #` 行 |
| **主窗协同/回归（主判点 1 续）** | 最小化/恢复主窗（HIDDEN/SHOWN）→ 观察子窗挂起/恢复与命令抑制；关闭子窗 | `subwindow suspended`/`resumed`；挂起期命令被抑制；主页面 `canvas presented` 60fps、无新 fault；close 后子窗消失 | hilog + 截图 + 主页面状态行 |
| **a11y 密码脱敏（#49 主判点 2，SEC-SCAN-4）** | 打开含密码 `Entry` 的页面 → `sh tester-run.sh --kit-dir ./device-test-kit --a11y-probe` 或 `uitest` 抓影子树/a11y dump | 密码节点文本为等长圆点；明文口令不出现；节点数/桥接照常（nodeCount 70 承 #47） | `a11y/` 两文件或 dump + 截图 + `summary a11y_*`；读屏环境复跑朗读/焦点/动作类 |
| **承 #48：R2R/JIT 启动（CG2-R2R）** | 自建 JIT R2R 变体（rc.2 SDK + `crossgen2-packs-11.0.0-rc.2` folder feed + `-p:PublishReadyToRun=true`，见 §3）→ 冷启 3 次 | AMS→首帧 **≈0.71 s 档**（≤0.8 s；IL 对照 ~1.03 s）；in-proc present ≤350 ms；`canvas presented` | 冷启计时 + 截图 + `hello-maui-app.dll` 含 `RTR\0`（可选） |
| **承 #48：AOT 首帧省时（AOT-STARTUP）** | 装默认 kit 主 hap（AOT）→ 冷启 3 次；观察首帧与覆盖层挂载次序 | AMS→首帧 **≈0.53 s 档**（≤0.6 s）；`web overlays mounted on first use` 出现在首帧后；hybrid 装载照常 | 冷启计时 + hilog（`[startup-shell]`/`web overlays mounted`）+ 截图 |
| **承 #48：帧率投票 60（FPS48）** | 另开持续重绘应用（干扰态）→ kit 主包动画页采样 ≥60 s | 5s 窗稳态均值 **≥58 fps**（交付方 46.2→60.0）；无整段 30 窗；draw/pres 不变 | `FPH`/帧统计 + 截图；无动画态 0 app 帧属预期 |
| **承 #48：多窗 S（MULTIWINDOW-S）** | 2in1：拖拽最大化/分屏/恢复；采 hilog + 截图 | 窗口尺寸跟随（`window size change: WxH free=…` + `[maui] window size WxH` + `canvas presented (WxH)`）；收窗/0×0 **保末帧**；a11y 70 | 截图 + hilog + `surface state=` 行 |
| **承 #48：FIXRR：interp R2R=0** | 解释器轮（rc2b pack + rc.2 kit hap + `interp.txt=3`）冷启；如自建 interp R2R 件对照 | `canvas presented`、无 `SIGSEGV(NULL)`；Main→首帧与 IL 件同档（交付方 614 vs 609） | hilog + 帧统计 + 截图 |
| **承 #47：FlyoutPage a11y 节点数** | 默认 kit 主 hap（AOT）→ `--a11y-probe`（或 `uitest` 点 `A11Y` 自检按钮） | `a11y/selfcheck.txt`：`accessibilityStatus: 1`、**nodeCount=70**；带读屏环境复跑 T2/L1/N1/F2/E1 | `a11y/` 两文件 + 截图 + `summary a11y_*` |
| **承 #47：抢占/恢复/重放原文** | 加满 3 控件后加 C/D/E（E 抢 A 槽）→ Activate A；抓 hilog | `[maui-capacity]` 原文：`preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`；活覆盖层 ≤4 | hilog 原文 + `hybrid assets slot=` 行 + 截图/JSON |
| **承 #46：INTERP-DRAW2 / FIX-A11YBUTTON** | 解释器轮统计；两态点自检按钮 | interp draw ≤10 ms/帧、稳态 60 fps；按钮左下角可达 `[523,1622][607,1668]`、点按出对话框 `status=1` | `FPH` + 截图 + hilog |
| **承 #45：自动释放 / INTERP-RENDER** | 加满 3 控件 → 移除第 3 个 → 再加回；解释器轮 stats | `web slot destroy: 2` → `web slot create: 2` + 交互恢复；interp ≥30 fps、meas≈0、CPU −13pt | 截图 + hilog + `FPH` |
| **动态槽 3 控件 / AOT 默认 / FRAMEPACING（承 #44/#43）** | 同页 3 控件；默认包冷启；present 聚合 | 3 控件各自出画/交互；`runtime-mode.txt=aot` + 3 `.so`、无 libcoreclr/libclrjit；真实 60.00 fps | 截图 + hilog + `verify-kit` 深度断言 |
| **承 #42–#35 各批** | 见 `2026-10-05-ohos-tester-handoff-kit47.md`、`…kit45.md`、`…kit42.md` §2 | 同前各期望；套件自报行 `607/609 floor 589` | 截图 + hilog + `dotnet-status.txt` |
| **套件基座** | 有源码测试者跑 `test/maui-platform-verify` | `[suite] checks=607 total=609 floor=589 assert=True`；导出 153/153 | 终端输出 |
| **承 #34/#33：rc.2 自述 + W6/W7/W8 + Blazor A/B + 主体** | 包内自述；各卡 | SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；逐项同 #34/#33 | 自述原文 + 截图 + `--a11y-probe` |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。
> **读屏环境**：交付方沙箱无读屏客户端（AMS `accessible=0`、client=0）→ 朗读/焦点顺序/动作类（T2 开启态/L1/N1/F2/E1 role）
> **不可测**；nodeCount=70 为壳自检读数，密码脱敏为离线红/绿负控。测试方请带 ScreenReader 环境复跑并按各卡回传。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#48）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.1.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（结构修复后重出）**：当前用 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；sdk fetch
   现锚）；`c1c85422715` 起 `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分对象库；`-r2`（601289590）/原包（`46d221f2…`）仅历史。
3. **Crossgen2 rc.2 包（承 #48）**：`Microsoft.NETCore.App.Crossgen2.openharmony-arm64.11.0.0-rc.2.26451.112.nupkg`
   （43,792,647 / `6bb8a375…`；sdk-ohos release `crossgen2-packs-11.0.0-rc.2`，asset `RA_kwDOT39XK84kdPmt`）
   作本地 folder feed + `RestoreConfigFile` 供 `-p:PublishReadyToRun=true`（消除 NU1100）；只用于 JIT（interp 见 4）。
4. **解释器 pack（#42 更新；#48 加 R2R=0）**：用 **`ohos-interpreter-pack-rc2b.tar.gz`**（2,410,595 / `5974430509…`，
   asset 606999003）+ **rc.2 kit hap**（重签）；`interp.txt=3` 时宿主置 `DOTNET_ReadyToRun=0`（FIXRR）；
   **勿用 rc.1 托管 CoreLib 的旧测试件**（QCall ABI 错配会 NULL 崩）；`interp.txt=1|2` 混合模式保留默认。
5. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`；enforcing 镜像直接装默认 kit 件
   （DEVCOMPAT-DEFAULT）；AOT 为默认（`-p:OpenHarmonyRuntimeMode=aot`）。
6. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 **未发布（WAIT，2026-10-04 复核）**：ohos-workload `rc2-watch`（`1d39eb7`）触发后按
   `2026-09-30-rc2-mainline-adoption.md` §8 换 pin、删 feed step。
7. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（release manifest 刷新 **`a6f5796c104…`**，
   父 `dd2718fd273`；本交接文再补一笔 docs-only）；maui = **`b093e33825`**（MULTIWINDOW-M 切片；
   父 `5f3efd55e5` = SEC-SCAN-4 ← `ed02203bfd` = MULTIWINDOW-S）；ohos-workload `master` **`16df9a3e`**
   （MULTIWINDOW-M 内容提交；pin `e0803bedad`，父 `be70a73` 壳+宿主+套件；verifier 重锚 **`71fe00c`**
   为本交接随行提交）；sdk 锚 **`7abaf8132f`**（`WORKLOAD_BUNDLE_SHA256` 3b62cee2 → **7d06e781**；
   父 `767c03ee71` = #48 锚；bundle 73,085,186 / `7d06e781…`）；aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#48）：本机桌面 HAD-W32 / OpenHarmony-7.0.0.109–111 / API 26；hdc 无线
  `tconn 127.0.0.1:35111`（UDID 随轮次）；SDK `sign-hap.sh` 自签；AOT 为默认路径。
- **#49 本轮证据**（scratch `reg-kit49/` 与能力波形 scratch `multiwin-m/`、`sec4-*`）：
  子窗 create/move/resize/close + touch/drag + 主窗协同（截图 mw-seq1/2/3、mw-drag）；SEC-SCAN-4 离线红/绿
  负控与 +2 断言（`sec4-mini` 隔离复跑 `[mini] a11y-password plainHidden=True masked=True`、`draw cull edge
  zeroAndShadowText=2 image=True`）；构建/验证日志 `reg-kit49/build-*.log`、`verify-kit49-*.log`。
- **#48 复测证据**（scratch `cg2-r2r/`、`aot-startup/`、`fps48/`、`multiwindow/`）：四件 A/B、双宿主对照、
  2in1 最大化实测。
- **#47 复测证据**（scratch `fix-a11yflyout/`）：probe5 AOT `--a11y-probe` nodeCount=70；抢占原文 5 行
  `[maui-capacity]`。
- **#46/#45 复测证据**（scratch `interp-draw2/`、`fix-a11ybtn/`、`autodisconnect/`、`interp-render/`）：
  interp 60.1 fps / draw 9.4 ms；A11Y 按钮两态；移除/重挂槽；interp 30 fps 门控。
- **已知（承 #34–#48）**：JIT 主包 enforcing 镜像可开箱安装（DEVCOMPAT-DEFAULT）；JIT 首帧依赖 JITFORT
  （#42 默认；release 域需 ACL）；状态文件/轮询可能含上一轮残留行——判读以时序内状态为准。
- **本机可直接闭环**：AOT/JIT（含 R2R 自建）/interp 出画、子窗流程与主窗协同、多覆盖层 3–5 控件 +
  释放/重建 + 抢占原文、Blazor 标记、a11y/日志/截图回路、多窗尺寸跟随；命令模板 =
  `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`。

## 5. 自签与包布局要点（测试方视角；承 #34–#48）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap（全 AOT）**：payload-in-libs + DEVCOMPAT 重写；`libs/arm64-v8a` 3 `.so`（app.so + host
  301,984 + `libc++_shared.so` 1,267,392）、无 JIT 运行时；`ets/modules.abc` **414,532（`e016db13…`）**；
  AOT payload `libhello-maui-app.so` **19,258,128**；kit 根 `runtime-mode.txt=aot`。新 hap sha 以 release/包内
  `SHA256SUMS` 为准。
- **子窗边界（#49）**：管理侧仍是单 surface/renderer，子窗内容为壳侧 ArkUI 自绘 named-route；子窗不进
  MAUI a11y 树（单 surface 边界）；per-window surface/renderer 与真 OpenWindow 属 L（见
  `2026-10-05-ohos-multiwindow-m.md` 末节与平台限制 E2）。
- **AOT/解释器/Crossgen2 资产**：均为独立资产，不在 kit tar 内；AOT 用 **`-struct1`**（asset 607541145）、
  `aot-haps-v3-rc2.tar.gz`（18,185,012 / `3d24f716…`，dtk 599996905）本波未动；解释器用 **rc2b** + **rc.2 kit hap**；
  Crossgen2 用 `crossgen2-packs-11.0.0-rc.2`（folder feed）。安装会顶替 kit 主包，回 AOT 重装 kit hap。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #49）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准；
  **预签件本波已刷新（#49 件）**——非 tester UDID 设备仍 `9568344`，请回传 UDID 代签。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 显式 `--expected-abc 414532` 时期望 **0 FAIL / 0 WARN**（深度断言逐 hap：
   `resources.index`/abc/libs/`dotnet.zip`/payload-in-libs/宿主依赖（UND 242）；5 MAUI hap 期望
   `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；abc 期望 = **414,532（`e016db13…`）/24,324
   （`798b2477…`）**；脚本 76,707 B / `c25945d9…`，以包内为准）。#49 包内脚本的默认期望仍是 #48 的
   375,268，裸跑会对五个重建壳各报一条历史 WARN（不阻断）；默认重锚 414532 已提交 ohos-workload
   `71fe00c`（selftest 129/0、对 kit #49 树裸跑 0 FAIL/0 WARN），随下一包生效。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮（AOT）/ `--blazor-probe` / `--mode-matrix`
   （解释器轮用 **rc2b pack**）/ `--a11y-probe` 四件同 #42。
3. **7 hap 表（kit #49 发布实测；`SHA256SUMS` 18 项 / 1,600 B / `b142639d…`）**：`hello-maui-app.hap`
   **22,422,722 / `39a2433e…`**（AOT）、`…-unsigned` **22,121,783 / `3e9adba2…`**、`…-permissions`
   **22,422,716 / `a825629b…`**、`…-api20` **22,422,704 / `6183f813…`**、`…-api20-permissions`
   **22,422,700 / `a050e0a0…`**、Blazor 默认 **27,218,497 / `3a82a082…`**（未签名）、
   `-nocsp` **27,218,194 / `eb14048e…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。
   整包 tar **67,888,851 / `477974bb…`**、树 `8d03cb4c…`、sidecar `3803b3db…`；bundle
   `openharmony-workload-1.0.0-preview.28.tar.gz` **73,085,186 / `7d06e781…`**（三处同步；dist sums
   `443061e7…`（212 B）；sdkrc2 合并 sums 1,960 B / `4c1ec616…`；sdk-ohos 锚 **`7abaf8132f`**，
   `WORKLOAD_BUNDLE_SHA256` 3b62cee2 → 7d06e781）；**解释器 pack rc2b**（asset 606999003）、
   **`-struct1` AOT pack**（asset 607541145）与 **Crossgen2 rc.2 pack**（43,792,647 / `6bb8a375…`）保持；
   **预签已刷新（#49 件：asset 612929512 / 612930421）**；发布已完成：kit tar/边车两处（dtk **612922031** /
   latest **612923086**；asset 612922031/612922832、612923086/612923769）+ bundle 三处（preview.28
   612918212/612919038、latest 612919415/612920711、sdkrc2 612921037/612921767）；四条 release body 含
   `## Integrity (kit #49)`；by-id 抽验 0 FAIL + 零改动清单（dtk 44 资产 2 changed、latest 4 全 changed、
   sdkrc2 17 资产 2 changed）见 release。重签/重打包后必变，以 release 与随包校验为准；有 harmony flavor /
   HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#48）。
4. 离线证据（供复核）：套件 **607/609 floor 589**、像素 PASS（43）、导出 **153/153**、壳 abc
   **414,532/24,324**（四包一致 + provenance `1166 B / 70bfbcad`）、host **`cf4cc706`**/UND 242、
   `build-arkts-shell` selftest 全绿、`verify-kit` 129/0、packs/repo-hygiene/tasks（make-device-test-kit 复跑）；
   selftests 全绿（细节 `reg-kit49/selftest-*.log`）；#49 设备证据见 `reg-kit49/` + `multiwin-m/`、`sec4-*`；
   #48 见 `cg2-r2r/`、`aot-startup/`、`fps48/`；#47 见 `fix-a11yflyout/`；#46 见 `interp-draw2/`、`fix-a11ybtn/`；
   #45 见 `autodisconnect/`、`interp-render/`；#42 证据见 `2026-10-03-ohos-tester-handoff-kit42.md` §4。

## 7. 风险 / 未验证（诚实清单）

- **MULTIWINDOW-M 边界**：管理侧仍是单 surface/renderer，子窗内容为壳侧 ArkUI 自绘（非第二 MAUI 视觉树），
  子窗不进 MAUI a11y 树；`freeWindowModeChange` 真形态、手机域、多子窗上限、子窗软键盘/焦点与 z-order 未测；
  L（真 OpenWindow：per-window renderer/surface/输入/a11y + `ApplicationHandler.OpenWindow` 映射）未做
  （`2026-10-05-ohos-multiwindow-m.md` 末节；平台限制 E2）。
- **SEC-SCAN-4 边界**：密码脱敏为离线修复 + 红/绿负控，**未上机**；读屏服务实际可达性取决于用户启用
  （修复直接消除暴露面，不依赖可达性判定）；其余 6 项报告级（SEC4-SLOT1/2 需真机 churn 复演、SEC4-CG2
  建议入 feed 前 `sha256sum -c`、SEC4-A11Y2/3 加固、SEC4-FPS 省电项）。
- **R2R 边界（承 #48）**：单设备 n=3 冷启（pre-fix 窗口）；+11 MB 文件体积仍在；Crossgen2 包未本机重编
  （复用 rc.2 主线 CI 字节）；R2R 只用于 JIT，interp 抑制（FIXRR）；release 域 JIT 仍受 ACL/发布 Profile 限制。
- **AOT-STARTUP / FPS48 / MULTIWINDOW-S 边界**：同 #48 交接 §7（非轮交替 ±20 ms 漂移、RS 投票 dump 未直证、
  `freeWindowModeChange`/split 真形态与手机域未测）。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递；②镜像分支 `m-web-mirror d47f1fcb3b`
  未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；④stock JIT
  长跑/后台唤醒未覆盖（JIT 现非默认形态）；⑤解释器混合模式（`interp.txt=1|2`）保留默认。
- **AOT 默认边界**：JIT/解释器均需动态码；release/生产域请走 AOT 或申请 ACL
  （`ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）；手机只发 AOT。**发布域实测（2026-10-04）**：
  自签 release×AOT 正常；release×JIT `coreclr_initialize` 后 ~44 ms 崩（需华为发布 Profile + ACL/JIT 豁免后复验）；
  覆盖装先卸载（`9568286`）、过期 p7b=`9568329`（`2026-10-04-ohos-release-domain-and-pidloss.md`）。
- **动态槽边界**：热对 [0,1] 常驻；空闲 >2 不养 ArkWeb 引擎/文档；容量下调按 suspend 抢占超容量 claim；
  env 不可按应用注入；N=8 实测 >4 不挂（安全上限 4）。
- **解释器口径**：rc2b pack 只配 rc.2 kit hap + #42+ 宿主；旧 rc.1 托管 CoreLib 测试件会 QCall ABI NULL 崩（测试件问题）。
- **AOT pack 结构性缺陷（已修复入源）**：`c1c85422715` 拆分对象库；当前资产 = **`-struct1`**（asset 607541145）。
- **ICU/InvariantGlobalization（承 #42）**：本镜像无系统 ICU——宿主自动 invariant；应用侧如遇 hosting FailFast 可参考。
- **hilog 缓冲/状态伪影**：512K 环噪声大时 ≈4–5 s；`dotnet-status.txt`/轮询可能含上一轮残留行——以时序内状态为准；
  临时 `hilog -G 16M` 复核后请还原 512K。
- **门禁（本轮已跑）**：交互 607/609 floor 589、像素 PASS（43 PASS / 0 FAIL）、导出 153/153、preflight OK
  （ridgraph 20 / packs 25 / hap-targets 79 / tasks 9 / repo-hygiene 25）、host-export 153/153，CI 5/5 @ pin `e0803bedad`
  （interaction `37321721695` / pixel `37321721683` / host-export `37321721786` / ridgraph `37321722030` /
  markdownlint `37321721810`）+ sdk `ohos-install-tests` @ `7abaf8132f` run `37331391778`；runtime manifest
  提交 `a6f5796c104` 为 docs-only（无 workflow run）；verifier 重锚 `71fe00c` 为 docs 随行工具提交。
