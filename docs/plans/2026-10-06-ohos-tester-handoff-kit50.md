# 测试方交接：kit #50、真多窗 MULTIWINDOW-L 全套（M1–M4 + SEC-SCAN-5a/5b/5c）+ polish-49（承 #49 应用内子窗 + a11y 密码脱敏与 #48–#45 全量）（2026-10-06）

> 日期口径：文件名按撰写日；**kit #50 发布实测（release「## Integrity（kit #50）」；发布已完成，一切数字以 release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **68,264,136 B / `d70dc786…`**、树 **`b4b5055c…`**、sidecar **`2ffb3b6a…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `98fd0dd2…`**（#49 = tar 67,888,851 / `477974bb…`、树 `8d03cb4c…`、sidecar `3803b3db…`；#48 = 67,735,148 / `5c22704f…` 对照）。
> **预签已刷新至 #50**（7 hap；**68,157,557 / `028d29f4…`**，asset **615517779**；sidecar 88 B / `02397318…`，asset **615518466**；树 `440a2cb5…`；替换 #49 件 612929512/612930421）——按 tester UDID `60CF7B27…` 预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**（非该 UDID 报 `9568344`）。
> 构建基线（rc.2 线，同 #34–#49）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** / MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。**数字口径注（如实记录）**：kit 内 5 MAUI AOT hap 用 **`~/.dotnet.rc2-fix`（SDK `26451.112` = 声明基线）** 打包；构建机默认 `~/.dotnet`（`26451.109`）的 ILCompiler 为 `11.0.0-rc.1.26451.109`（有偏离）——两安装的 preview.28 pack 已逐字节同步（`reg-kit50/pack-sync.log`）。**AOT 包**：rc.2 runtime pack 现取 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；`-r2`（601289590）/原包（`46d221f2…`）仅历史）；Crossgen2 rc.2 包（43,792,647 / `6bb8a375…`，`crossgen2-packs-11.0.0-rc.2`，JIT R2R 经 folder feed 消费）沿用 #48。
> **在途/外部（明确）**：AGC App Linking 登记 + 真机 https 投递；镜像扩展分支 `m-web-mirror d47f1fcb3b` 尚未并入 `feature/openharmony`；rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；stock JIT 长跑/后台唤醒未覆盖（JIT 现非默认）；解释器混合模式（`interp.txt=1|2`）保留默认；平台级多子窗上限未探（应用级 N=1）。
>
> **结论先行**：kit #50 = **kit #49（MULTIWINDOW-M + SEC-SCAN-4；承 #48 CG2-R2R + AOT-STARTUP + FPS48 + MULTIWINDOW-S + FIXRR 与 #47 FIX-A11YFLYOUT/FIX-PREEMPT-RAW、#46/#45 全量）** + **MULTIWINDOW-L 全套（真 OpenWindow 多窗：M1 宿主每窗 surface 注册表 / M2 切片 per-window renderer + 带窗事件路由 / M3 子窗挂 XComponent + managed surface id（第二 MAUI 视觉树）/ M4 每窗焦点/IME/生命周期 · a11y 分区 · pinch；SEC-SCAN-5a/5b/5c 加固）** + **polish-49**（建窗 E=0、close WARN 平台内部、Home 焦点丢失链 suspend）。指纹：壳 abc **436,808（`289a5e5d…`）/ headless 24,324（`798b2477…`）**、宿主 **330,656（`fdeb94eb…`）**、导出 **157/157**、套件 **661/663 floor 643**、预签已刷新至 #50；切片 `74e0bde5b9`（maui，M1–M4 + SEC-SCAN-5c ← 合并 L 栈）、ow `afa6d7a4`（pin `23d98a9615`），sdk 锚 `a3417a5489`。判定点见 §2；承接 #49/#48/#47/#45/…/#34 的判定点**继续有效**，本文覆盖 #50 增量与判读引用。
> **降级声明（必有，不判失败）**：子窗 a11y provider、子窗 ArkWeb 第二宿主、平台级多子窗上限（应用级 N=1）、**子窗 IME 实敲人工卡**、SEC-5c B–F 报告项。
> kit 编号（#50）是团队跟踪口径，release 本身不带编号；以后续文档与 release 说明为准。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（AOT —— #43 起默认；无需 ACL，属推荐路径）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# #50 主判点 1：真多窗（aa start -U app://subwindow/open → windows=2 / 子窗 first frame=True 第二 MAUI 视觉树
#   720×480 → 子窗内点按（触摸按窗）→ close→reopen 同 id；再 churn ≥10 次观察 WMS 残留=0）
# #50 主判点 2：每窗焦点/生命周期（Home → subwindow suspended → aa start → resumed；×10 每轮 1/1）
# #50 主判点 3：每窗 a11y 分区（主窗 --a11y-probe：主 provider 零变化；子窗帧本地保持 status 行）
# #50 主判点 4：pinch 按窗（uitest 无多点注入面 → 离线 pin + 宿主单测；有注入面按 §2）
# #50 人工卡：子窗 IME 实敲（§1.4/§2；纯人工不阻塞）；承 #49 主判点：M 子窗流程 / a11y 密码脱敏
# 承 #48 主判点：R2R/JIT 启动数字 / AOT 冷启计时 / 帧率投票 / 多窗 S 尺寸
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；**已刷新至 #50**）

`device-test-kit` release 的并列预签资产 **`preSigned-haps.tar.gz`** 当前为 **kit #50 件**（2026-10-06 重签；asset **615517779**，**68,157,557 B / `028d29f4…`**；sidecar 88 B / `02397318…`，asset **615518466**；树 `440a2cb5…`；**内容 = kit #50 的 7 hap** + `preSigned-README.md` + `SHA256SUMS` 8/8；ZIP 条目与 kit 原件逐字节一致；7/7 `sign-hap.sh` + `verify-app` success、device-ids 单值 = tester UDID）。按 tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19` 预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**；非 tester UDID 设备报 `9568344`。预签包是并列附加件，完整一轮仍用 kit tar。

## 1. kit #50 相对 #49 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **MULTIWINDOW-L M1–M4（#50 主判点 1）** | 宿主 **M1** 每窗 XComponent surface 注册表（window-id claim/release/route + stderr 证据；`selftest-host-registry` **84/84**，SEC-5a 66 checks）；**M2** 切片 per-window `OpenHarmonyWindowSurface`/`Renderer` + `OpenHarmonyWindowHost`，`RouteSurface/RouteTouch/RouteFrame` 按 window-id（headless 双窗 22 checks 入套件）；**M3** 子窗挂 XComponent + managed surface id → **第二 MAUI 视觉树**（真机 `sub-1` 720×480 `first frame=True`、触摸按窗、close 回收、reopen 同 id、churn ×20 无 WMS 残留）；**M4** 壳 ACTIVE/INACTIVE → per-window `IWindow.Activated/Deactivated/Stopped/Resumed` 状态机（幂等；Home→suspended→`aa start`→resumed ×10 每轮 1/1）、每窗 a11y 影子帧（主 provider 零变化）、per-window pinch（`ohos_host_notify_window_pinch`→该窗 renderer，导出 156→**157**）；真机双窗稳态 **60.0/60.0 fps**、40 min 长稳（pid 恒定、fault_new=0、RSS 净 −34 MB、threads 70–78）、JIT 与 AOT 各过轮 | 主判点 1：`app://subwindow/open` 后 **`windows=2` + 子窗 `first frame=True`（720×480）**；子窗内点按/滑动只影响子窗；close→子窗消失、reopen 同 id；帧统计主/子均 ≥50/≥40 fps；长稳/churn 按 §2 采证。pinch 无注入面时按离线 pin + 单测 |
| 1.2 | **SEC-SCAN-5a/5b/5c（L 加固，随包）** | 5a：`unregisterXComponent` 非法 id 失败闭合（不再回落主窗）+ surface 事件按组件路由；5b：window-id 校验失败闭合 + `registerXComponent` 身份；5c：主窗→子窗文本 thunk 仅主窗（按窗门禁）+ **跨窗文本泄漏修复**（反转隔离 pin，套件 662→663） | 非主窗不得改写主窗文本/输入路由；报告级 B–F 见 §7（不判失败） |
| 1.3 | **polish-49（承 #49 噪声三件）** | ①建窗 `ParseSubWindowOptions` 三可选布尔补齐（按平台默认）→ 真机 **E=0**；②close `dialogSubwindowMap_` WARN = 平台 `DestroyContainer` 固有（非 double close，仅注释）；③Home 键经**焦点丢失链** suspend（INACTIVE→600 ms 宽限、无 ACTIVE→suspend；`clearSubWindow` 取消定时器），真机 Home suspend→resume 通过 | 建窗无 E；close 可不带该 WARN 或按平台内部说明处理；Home→子窗 suspended 可见（主判点 2 用 `aa start` 恢复） |
| 1.4 | **子窗 IME 人工卡（#50 人工判点）** | 子窗页含隐藏 TextInput + focusable XComponent(onKeyEvent) + onBackPress；AppStorage 焦点通道（op 6→Index→子窗 requestFocus/IME），text/composition/submit/key/back 走 tagged 子窗通道；**uitest `uiInput` 无子窗 XComponent/多点注入面**（click 未达子窗）→ 只能人工实敲 | 按 §2 人工卡 4 步：点 Entry→键盘在子窗；实敲 `hello-child`+回车→文本只在子窗；切主窗敲字→主窗文本不受影响（跨窗事件=0）；close→键盘收起、reopen→Entry 回 `seed` |
| 1.5 | **降级声明（明示）** | 子窗 a11y provider（平台 per-instance provider 需节点表按 instance/window 分区 + 子窗 ContentSlot 导出，>2pd 时间盒 → 主 provider 零变化、子窗影子帧本地保持）；子窗 ArkWeb 第二宿主（槽池/控制器声明在主窗 → 槽池留主窗、子窗 web 不挂载、无回归）；平台级多子窗上限未探（应用级 N=1 真机失败闭合、无残窗）；IME 实敲=人工卡；SEC-5c B–F 报告级 | 上述现象按「降级预期」登记，不判失败；下波路径见 `-l-m4.md` |
| 1.6 | **承 #49：MULTIWINDOW-M / SEC-SCAN-4** | M 壳子窗流程仍在（`app://subwindow/demo` create/move/resize/close、hide→Failed 801 如实）；L 落地后 M 的单 surface 边界**升级为第二 MAUI 视觉树**（子窗渲染由 M3 托管）；SEC-SCAN-4 影子树密码等长圆点继续有效 | 同 #49 交接 §2 主判点 1–2；L 主路径改按 §1.1 判 |
| 1.7 | **承 #48：CG2-R2R / AOT-STARTUP / FPS48 / MULTIWINDOW-S / FIXRR** | JIT R2R 冷启 **1031→710 ms（−31%；n=3）**、in-proc present 575→307；AOT 首帧 **796→534 ms（−33%）**、attach→surface 239→13；帧率投票 60（干扰态 **46.2→60.0 fps**）；多窗 S 最大化 **3120×1955**；interp R2R=0（FIXRR） | 同 #48 交接 §2 主判点 2–5；AOT kit 上继续适用 |
| 1.8 | **承 #47/#46/#45：FIX-A11YFLYOUT / FIX-PREEMPT-RAW / INTERP-DRAW2 / FIX-A11YBUTTON / 自动释放 / INTERP-RENDER / 动态槽 / 默认 AOT / FRAMEPACING** | a11y nodeCount **1→70**；`[maui-capacity]` 原文（`preempted: slot 0/1`、`restored: slot 1`、`replay: slot 1`）；interp draw 9.4 ms/60.1 fps；按钮左下角两态；Remove→`web slot destroy`→re-add→`web slot create`；动态槽 MAX/HOT **4/2** + 3 控件并发；`runtime-mode.txt=aot`；60.00 fps | 同 #47/#45 交接 §2；AOT kit 上继续适用 |
| 1.9 | **门禁/指纹/7 hap/预签** | 交互套件 **661/663 floor 643**（L 全量 pin；declared==printed、0 Unhandled、perf within）、像素 `PIXEL ASSERTIONS PASSED`、宿主导出契约 **157/157**、host UND **249**/DT_NEEDED 5/denylist 0；壳 abc **436,808（`289a5e5d…`）**/headless 24,324（`798b2477…`）、host **330,656（`fdeb94eb…`）**；**7 hap**：5 MAUI 全 AOT + Blazor 默认/`-nocsp`；**预签刷新至 #50** | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**（#50 包内脚本默认期望已重锚 **436,808**，裸跑即绿，无需 `--expected-abc`）；`[suite] checks=661 total=663 floor=643 assert=True`；`runtime-mode.txt=aot` |
| 1.10 | **在途/外部项（明确）** | ①AGC App Linking 登记 + 真机 https 投递；②镜像分支 `m-web-mirror d47f1fcb3b` 未并入；③rc.2 csc 并行活锁（`DOTNET_PROCESSOR_COUNT=1` 绕过）；④stock JIT 长跑/后台唤醒未覆盖；⑤解释器混合模式保留默认；⑥平台级多子窗上限未探（应用级 N=1） | ①–⑥ 登记「未测（在途）」，**不判失败** |

> **2026-10-06 复测回填（交付方口径，交测前以此为准）**：① **MULTIWINDOW-L（#50 主判点 1–4）**：设备 HAD-W32/W24（2in1，OpenHarmony 7.0.0.109/7.0.0.111）——子窗 open：`windows=2`、`first frame=True`、子窗（`sub-1`）**720×480 第二 MAUI 视觉树**；触摸按窗归属、close 回收（`unregistered=1`）、reopen 同 id；**churn ×20**（pid 恒定、fault +0、WMS 残留 0）；双窗稳态 **60.0/60.0 fps**（JIT 主 max 20–22 ms / 子 max 17 ms；AOT 主 max 20–24 ms；单/双主窗退化 0%）；生命周期 ×10 每轮恰 1 hidden/1 shown；a11y 子窗帧本地保持 + 主 provider 零变化；pinch 离线 pin + 宿主单测（真机多点注入不可用）。
> ② **长稳与 polish**：40 min 长稳 41 采样 pid 恒定、fault_new=0、RSS 310,116→275,664 kB（净 −34 MB）；polish-49 的建窗 E=0、close WARN 平台内部、Home 焦点丢失链 suspend 均真机抽验（`nextkit-polish-prep`）。③ **SEC-5a/5b/5c**：离线读码 + 1 次纯 C host selftest（bridge 12/12 script、14/14 unit）；5c 修复已落 `74e0bde5b9`（反转隔离 pin）；B–F 报告级登记。④ **承 #49/#48 复测**：M 流程 / a11y 密码脱敏（离线红/绿）/ CG2-R2R 四件 A/B / AOT 双窗 publish 与 kit #49 同口径，见对应交接文。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **真多窗（#50 主判点 1，M1–M4）** | 装默认 kit 主 hap（AOT）→ `aa start -U app://subwindow/open`（或包内样例入口）→ 等 `windows=2` | 子窗 `first frame=True`（**第二 MAUI 视觉树 720×480**）；子窗内点按/拖动只影响子窗；close 后子窗消失；reopen 同 id | 每步 hilog（`windows=`/`first frame`/`subwindow closed`）+ 双窗截图（主/子各一） |
| **每窗帧率/长稳（主判点 1 续）** | 双窗 ActivityIndicator 持续出帧 ≥60 s；churn ×10–20；可加 40 min soak | 主/子稳态 **60/60 fps**（冻结阈值：主 ≥50 / 子 ≥40 / 主窗较单窗退化 ≤10% / 连续 >33 ms×3=0）；churn 无 WMS 残留、pid 恒定；soak 无 fault/RSS 单调增长 | `WindowFrameStats` 每窗 5s 行 + pid/fault 采样 + 截图 |
| **每窗焦点/生命周期（主判点 2）** | Home/最小化 → 等 suspended → `aa start` 恢复；重复 ≥10 次；切焦点窗 | `subwindow suspended`→`resumed` 每轮 1/1；焦点只在活动窗；主窗进程生命周期零变化 | hilog 事件序 + 每轮计数 + 截图 |
| **每窗 a11y 分区（主判点 3）** | 主窗 `sh tester-run.sh --kit-dir ./device-test-kit --a11y-probe`；子窗渲染中复跑 | 主 provider 路径**零变化**（status=1、nodeCount 70 档）；子窗帧本地保持（status 行：`keeps its shadow frame locally (no per-window provider yet …)`）、主窗树不被覆盖 | `a11y/` 两文件或 dump + 截图 + `summary a11y_*`；读屏环境复跑朗读/焦点/动作类 |
| **pinch 按窗（主判点 4）** | 有注入面/多指设备：子窗内 pinch；交付方沙箱无多点注入面 | 缩放只作用于该窗 renderer（`ohos_host_notify_window_pinch`→`WindowPinch`）；主窗/未知/空 id 被拒 | 设备有注入面时回传 hilog/截图；否则按「未测（无注入面）」+ 离线 pin/单测（12+14 checks）背书 |
| **子窗 IME 实敲（人工卡，不阻塞）** | 解锁设备 → open 子窗 → 鼠标/触摸点子窗 Entry → 实敲 `hello-child` + 回车 → 切主窗敲字 → close/reopen | 键盘在子窗弹出、文本只在子窗；跨窗事件=0；close 键盘收起、reopen Entry 回 `seed` | 4 行回传格式（设备/包/时间 + 每步 OK/FAIL + ≤20 行 hilog + 2 截图）；失败附 `hilog -x` 与 `uitest dumpLayout` |
| **门禁基座** | 有源码测试者跑 `test/maui-platform-verify` 与 `sh verify-kit.sh` | `[suite] checks=661 total=663 floor=643 assert=True`；verify-kit **0 FAIL/0 WARN**；导出 157/157；像素 PASS | 终端输出 |
| **承 #49：MULTIWINDOW-M / SEC-SCAN-4** | 同 #49 交接 §2 主判点 1–2（`app://subwindow/demo` create/move/resize/close；密码 Entry 影子树） | 同 #49 期望；L 主路径按本表首行判 | 同 #49 交接回传 |
| **承 #48：R2R/JIT 启动 / AOT 首帧 / 帧率投票 60 / 多窗 S / FIXRR** | 同 #48 交接 §2 主判点 2–5 | R2R 710 ms 档 / AOT 534 ms 档 / ≥58 fps（46.2→60.0）/ 3120×1955 / interp R2R=0 | 冷启计时 + `FPH` + 截图 + hilog |
| **承 #45–#47、动态槽、AOT 默认、FRAMEPACING、Blazor A/B、rc.2 自述** | 见 `2026-10-05-ohos-tester-handoff-kit47.md`/`…kit45.md`/`…kit42.md` §2 | 同前各期望；套件自报行 `661/663 floor 643` | 截图 + hilog + `dotnet-status.txt` |
| **无 hdc / 不能重签时** | 只有设备文件管理器（预签件仍可直装） | 自动项登记「未测（无 hdc）」；人工项照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。**读屏环境**：交付方沙箱无读屏客户端（AMS `accessible=0`、client=0）→ 朗读/焦点顺序/动作类与密码节点实读**不可测**；`nodeCount=70` 为壳自检读数、密码脱敏为离线红/绿负控、子窗 a11y 为降级。测试方请带 ScreenReader 环境复跑并按各卡回传。**IME 人工卡**同样需真实键鼠/触摸设备，见 §1.4 与 `-l-m4.md` 末节。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#49）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；rc.1（`11.0.100-rc.1.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（结构修复后重出）**：当前用 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；sdk fetch 现锚）；`c1c85422715` 起 `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分对象库；`-r2`（601289590）/原包（`46d221f2…`）仅历史。
3. **Crossgen2 rc.2 包（承 #48）**：`Microsoft.NETCore.App.Crossgen2.openharmony-arm64.11.0.0-rc.2.26451.112.nupkg`（43,792,647 / `6bb8a375…`；sdk-ohos release `crossgen2-packs-11.0.0-rc.2`，asset `RA_kwDOT39XK84kdPmt`）作本地 folder feed + `RestoreConfigFile` 供 `-p:PublishReadyToRun=true`（消除 NU1100）；只用于 JIT。
4. **解释器 pack（#42 更新；#48 加 R2R=0）**：用 **`ohos-interpreter-pack-rc2b.tar.gz`**（2,410,595 / `5974430509…`，asset 606999003）+ **rc.2 kit hap**（重签）；`interp.txt=3` 时宿主置 `DOTNET_ReadyToRun=0`（FIXRR）；**勿用 rc.1 托管 CoreLib 的旧测试件**（QCall ABI 错配会 NULL 崩）；`interp.txt=1|2` 混合模式保留默认。
5. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`；enforcing 镜像直接装默认 kit 件（DEVCOMPAT-DEFAULT）；AOT 为默认（`-p:OpenHarmonyRuntimeMode=aot`）。
6. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；官方 rc.2 **未发布（WAIT，2026-10-04 复核）**：ohos-workload `rc2-watch`（`1d39eb7`）触发后按 `2026-09-30-rc2-mainline-adoption.md` §8 换 pin、删 feed step。
7. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（release manifest 刷新 **`3e562d4241e…`**，父 `7508605a9c7`；本交接文再补一笔 docs-only）；maui = **`74e0bde5b9`**（M1–M4 + SEC-SCAN-5c 合并；父 `23d98a9615` = M4 焦点/IME ← `c2a59fbf27`）；ohos-workload `master` **`afa6d7a4`**（L 合并 `52af282` + pin；内容提交 `a1ebde2`/`9738d7e`/`06859d4` 等；pin `23d98a9615`）；sdk 锚 **`a3417a5489`**（`WORKLOAD_BUNDLE_SHA256` 7d06e781 → **6a83c0f3**；bundle 73,119,180 / `6a83c0f3…`）；aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#49）：本机桌面 HAD-W32/HAD-W24 / OpenHarmony-7.0.0.109–111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`（UDID 随轮次）；SDK `sign-hap.sh` 自签；AOT 为默认路径。
- **#50 本轮证据**（scratch `/data/storage/el2/base/tmp/opencode/reg-kit50/` 与 L 波 `mw-l/`、`sec5*`）：构建/门禁 `build-host.log`、`build-arkts-*.log`、`interaction-run.log`（661/663 floor 643）、`pixel-run.log`、`host-targets-check.txt`（157/157、UND 249）、`pack-abc-check.txt`（436,808/289a5e5d）、`preflight-quick-final.log`、`verify-kit50-raw.log`（KIT OK 0/0）、`publish50.log` + `verify-publish50.py`（by-id + 零改动清单）、`presign-k50/logs/*`（7/7 verify-app、tester UDID）、`aot-markers.txt`（5 MAUI AOT 标记）。
- **M4 复测证据**（scratch `mw-l/m4b/`）：双窗 60/60 fps、×10 suspend/resume、churn ×20、40 min soak（净 −34 MB）、IME 注入尝试（`uitest uiInput` click/text 未达子窗 → 转人工卡）、AOT publish（IL2026/3050/3051=0）。
- **JIT/AOT 轮**（M4-07）：JIT hap 123,267,728 / `a4a3caac…`（marker=jit）、AOT hap（unsigned）30,909,710 / `335c8ef1…`（marker=aot、0 IL gate）；两模式真机均 `windows=2`、`first frame=True`、双窗稳态 60 fps、0 fault。
- **设备纪律**：L 波以 `.device-lock` 单轮一锁、轮末恢复 kit #49 hap 后释放（当前设备为 kit #49）；锁屏 `10106102` 快速失败 + 有限重试，hilog 16M→512K 还原。
- **#49 复测证据**（scratch `reg-kit49/`）：子窗 M 流程、SEC-SCAN-4 离线红/绿、AOT 轮；**#48 证据**（`cg2-r2r/`、`aot-startup/`、`fps48/`）；命令模板 = `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`。

## 5. 自签与包布局要点（测试方视角；承 #34–#49）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET（重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap（全 AOT）**：payload-in-libs + DEVCOMPAT 重写；`libs/arm64-v8a` 3 `.so`（app.so **19,364,624** + host **330,656** + `libc++_shared.so` 1,267,392）、无 JIT 运行时；`ets/modules.abc` **436,808（`289a5e5d…`）**；kit 根 `runtime-mode.txt=aot`。新 hap sha 以 release/包内 `SHA256SUMS` 为准。
- **多窗边界（#50）**：子窗是**第二 MAUI 视觉树**（M3 托管渲染）；但子窗 a11y 走 provider 降级、子窗 web 不挂载（ArkWeb 第二宿主降级）、平台级多子窗上限未探（应用级 N=1）；子窗 IME 实敲为人工卡。见 `2026-10-06-ohos-multiwindow-l-m4.md` 与平台限制 E2。
- **AOT/解释器/Crossgen2 资产**：均为独立资产，不在 kit tar 内；AOT 用 **`-struct1`**（asset 607541145）、`aot-haps-v3-rc2.tar.gz`（18,185,012 / `3d24f716…`，dtk 599996905）本波未动；解释器用 **rc2b** + **rc.2 kit hap**；Crossgen2 用 `crossgen2-packs-11.0.0-rc.2`（folder feed）。安装会顶替 kit 主包，回 AOT 重装 kit hap。
- **包内文档口径**：包内 tester 文档（`快速开始.md`、`自签说明.md`、设备校验清单、`验收说明.md` 等）的修订状态以 release 说明与随包文件为准（本波交接文为当前判读入口）。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #50）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准；**预签件本波已刷新（#50 件）**——非 tester UDID 设备仍 `9568344`，请回传 UDID 代签。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（#50 包内脚本默认期望已重锚 **436,808**，裸跑即绿；深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/payload-in-libs/宿主依赖（UND 249）；5 MAUI hap 期望 `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；abc 期望 = **436,808（`289a5e5d…`）/24,324（`798b2477…`）**；脚本 76,707 B / `afeaa919…`，以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮（AOT）/ `--blazor-probe` / `--mode-matrix`（解释器轮用 **rc2b pack**）/ `--a11y-probe` 四件同 #42；脚本为 release 上的独立资产（不在 kit `SHA256SUMS` 内）。
   - 常规一轮：`--kit-dir ./device-test-kit --install --start --capture 60`（AOT 默认）。
   - Blazor：`--blazor-probe`（断言 `BLZ_BOOT`/`BLZ_RENDERED` 两标记，失败落 `blazor-hilog.txt`）。
   - 四态矩阵：`--mode-matrix --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz`。
   - a11y：`--a11y-probe`（`a11y/selfcheck.txt` + `a11y/hilog-a11y.txt` + `summary a11y_*`）。
3. **7 hap 表（kit #50 发布实测；`SHA256SUMS` 18 项 / 1,600 B / `98fd0dd2…`）**：`hello-maui-app.hap` **22,580,658 / `2b8d39ba…`**（AOT）、`…-unsigned` **22,279,282 / `60b559c3…`**、`…-permissions` **22,580,648 / `7a2b9913…`**、`…-api20` **22,580,647 / `ddf54f31…`**、`…-api20-permissions` **22,580,653 / `bcd0afbf…`**、Blazor 默认 **27,218,497 / `769c81f1…`**（未签名）、`-nocsp` **27,218,194 / `0761973e…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。整包 tar **68,264,136 / `d70dc786…`**、树 `b4b5055c…`、sidecar `2ffb3b6a…`；bundle `openharmony-workload-1.0.0-preview.28.tar.gz` **73,119,180 / `6a83c0f3…`**（三处同步；dist sums `ff3d5550…`（212 B）；sdkrc2 合并 sums 见 `reg-kit50/sdkrc2-sums-expected.txt`；sdk-ohos 锚 **`a3417a5489`**，`WORKLOAD_BUNDLE_SHA256` 7d06e781 → 6a83c0f3）；**解释器 pack rc2b**（asset 606999003）、**`-struct1` AOT pack**（asset 607541145）与 **Crossgen2 rc.2 pack**（43,792,647 / `6bb8a375…`）保持；**预签已刷新（#50 件：asset 615517779 / 615518466）**；发布已完成：kit tar/边车两处（dtk **615507454** / latest **615508545**；asset 615507454/**615508271**、615508545/**615509231**）+ bundle 三处（preview.28 615504519/615505218、latest 615505489/615506292、sdkrc2 615506528/615507247）；四条 release body 含 `## Integrity (kit #50)`；by-id 抽验 0 FAIL + 零改动清单（dtk 2 changed / 50 unchanged、latest 4 changed、sdkrc2 2 changed / 15 unchanged）见 release。重签/重打包后必变，以 release 与随包校验为准；有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#49）。
4. 离线证据（供复核）：套件 **661/663 floor 643**、像素 PASS、导出 **157/157**、壳 abc **436,808/24,324**（四包一致 + provenance `1,166 B / 3e787048`）、host **`fdeb94eb`**/UND 249、`build-arkts-shell` selftest 全绿、`verify-kit` 129/0、host registry 84/84 + bridge 26/26、preflight 全绿（ridgraph 20 / packs 25 / hap-targets 79 / tasks 9 / repo-hygiene 25）；#50 设备证据见 `reg-kit50/` + `mw-l/m4b/`；#49 见 `reg-kit49/`；#48 见 `cg2-r2r/`、`aot-startup/`、`fps48/`。

## 7. 风险 / 未验证（诚实清单）

- **MULTIWINDOW-L 边界**：子窗 a11y provider（降级：主 provider 零变化、子窗影子帧本地保持；下波需节点表按 instance/window 分区 + 子窗 ContentSlot 导出）；子窗 ArkWeb 第二宿主（降级：槽池留主窗、子窗 web 不挂载）；平台级多子窗上限未探（应用级 N=1 失败闭合、无残窗）；**子窗 IME 实敲为人工卡**（uitest 无子窗 XComponent/多点注入面）；SEC-5c B–F 报告级（B 子窗 prompt 键盘全局、C 状态机顺序假设、D Back/按键无消费者、E pinch 非有限几何、F 子窗 a11y 帧常驻）；2in1 debug 域单设备结论，不外推手机/release。
- **SEC-5a/5b/5c 边界**：离线读码 + 1 次纯 C host selftest（未上机、未构建 C#）；5c 的 B 需真机复核、D 未接线；修复反转 pin 未经 C# 构建执行（下轮 CI pin 生效）。
- **#50 数字口径注（不确定项）**：kit 的 5 MAUI AOT hap 用 `~/.dotnet.rc2-fix`（SDK `26451.112`，声明基线）打包；构建机默认 `~/.dotnet`（`26451.109`）的 ILCompiler 为 `11.0.0-rc.1.26451.109`，存在偏离——两安装的 preview.28 pack 已逐字节同步；如需完全可复现请以 `26451.112` 安装出包。
- **R2R 边界（承 #48）**：单设备 n=3 冷启（pre-fix 窗口）；+11 MB 文件体积仍在；Crossgen2 包未本机重编（复用 rc.2 主线 CI 字节）；R2R 只用于 JIT，interp 抑制（FIXRR）；release 域 JIT 仍受 ACL/发布 Profile 限制。
- **AOT-STARTUP / FPS48 / MULTIWINDOW-S 边界**：同 #48 交接 §7（非轮交替 ±20 ms 漂移、RS 投票 dump 未直证、`freeWindowModeChange`/split 真形态与手机域未测）。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递；②镜像分支 `m-web-mirror d47f1fcb3b` 未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；④stock JIT 长跑/后台唤醒未覆盖（JIT 现非默认形态）；⑤解释器混合模式（`interp.txt=1|2`）保留默认；⑥平台级多子窗上限未探。
- **AOT 默认边界**：JIT/解释器均需动态码；release/生产域请走 AOT 或申请 ACL（`ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）；手机只发 AOT。**发布域实测（2026-10-04）**：自签 release×AOT 正常；release×JIT `coreclr_initialize` 后 ~44 ms 崩（需华为发布 Profile + ACL/JIT 豁免后复验）；覆盖装先卸载（`9568286`）、过期 p7b=`9568329`（`2026-10-04-ohos-release-domain-and-pidloss.md`）。
- **动态槽边界**：热对 [0,1] 常驻；空闲 >2 不养 ArkWeb 引擎/文档；容量下调按 suspend 抢占超容量 claim；env 不可按应用注入；N=8 实测 >4 不挂（安全上限 4）。
- **解释器口径**：rc2b pack 只配 rc.2 kit hap + #42+ 宿主；旧 rc.1 托管 CoreLib 测试件会 QCall ABI NULL 崩（测试件问题）。**ICU/InvariantGlobalization（承 #42）**：本镜像无系统 ICU——宿主自动 invariant；应用侧如遇 hosting FailFast 可参考。
- **hilog 缓冲/状态伪影**：512K 环噪声大时 ≈4–5 s；`dotnet-status.txt`/轮询可能含上一轮残留行——以时序内状态为准；临时 `hilog -G 16M` 复核后请还原 512K。
- **门禁（本轮已跑）**：交互 661/663 floor 643、像素 PASS、导出 157/157、preflight OK（ridgraph 20 / packs 25 / hap-targets 79 / tasks 9 / repo-hygiene 25 + host registry 84 / bridge 26），CI 5/5 @ pin `afa6d7a`（interaction `37460790068` / pixel `37460790072` / host-export `37460790087` / ridgraph `37460790138` / markdownlint `37460790028`）+ sdk `ohos-install-tests` @ `a3417a5489` run `37465689708`；runtime manifest 提交 `3e562d4241e` 为 docs-only（无 workflow run）。
