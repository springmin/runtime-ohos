# 测试方交接：kit #47、FlyoutPage 无障碍（FIX-A11YFLYOUT：`PushChildren` 补 Detail/Flyout 分支 → 真机 nodeCount 1→70）+ 抢占原文导出（FIX-PREEMPT-RAW：`[maui-capacity]` 直写 hilog；承 #46 的 INTERP-DRAW2 / FIX-A11YBUTTON 与 #45 全量）（2026-10-05）

> 日期口径：文件名按撰写日；**kit #47 发布实测（release「## Integrity（kit #47）」；发布已完成，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **67,706,719 B / `3d6bb58b…`**、树
> **`0f266636…`**、sidecar **`4adb0b60…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `6bbc2235…`**
> （#46 = tar 67,708,823 / `c7c11814…`、树 `2dc1e86d…`；#45 = tar 67,695,181 / `ca48a93c…` 对照）。
> **预签已刷新至 #47**（7 hap；**67,639,132 / `f58c4906…`**，asset **610975429**；sidecar 88 B /
> `c95344ac…`，asset **610976421**；树 `70775143…`；替换 #46 件 610804181/610805373）——按 tester UDID
> `60CF7B27…` 预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**（非该 UDID 报 `9568344`）。
> 构建基线（rc.2 线，同 #34–#46）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（结构修复后重出，承 #42）**：rc.2 runtime pack 现取 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；
> `-r2`（601289590）/原包（`46d221f2…`）仅历史）。
> **在途/外部（明确）**：AGC App Linking 登记 + 真机 https 投递；镜像扩展分支 `m-web-mirror d47f1fcb3b`
> 尚未并入 `feature/openharmony`；rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；stock JIT 长跑/
> 后台唤醒未覆盖（JIT 现非默认）；解释器混合模式（`interp.txt=1|2`）保留默认。

> **结论先行**：kit #47 = **kit #46（INTERP-DRAW2 + FIX-A11YBUTTON）+ FlyoutPage 无障碍（FIX-A11YFLYOUT）+
> 抢占原文导出（FIX-PREEMPT-RAW）**，并承 #45 的自动释放（FIX-AUTODISCONNECT）/渲染门控（INTERP-RENDER）/动态槽
> （SLOTS-DYNAMIC）/默认 AOT/FRAMEPACING 与 #42–#35 各批。指纹：壳 abc **370,240（`4b439e83…`）/ headless
> 24,324（`798b2477…`）**、宿主 **297,888（`7b1694d9…`）**、导出 **151/151**、套件 **593/595 floor 575**、
> 预签已刷新至 #47；切片 `d5384d6cc3`（maui，FIX-A11YFLYOUT ← `6652017ca5` INTERP-DRAW2）+ ow `f538c84`，
> pin `3de9a95fe0`。判定点见 §2；承接 #45/#44/#42/…/#34 的判定点**继续有效**，本文覆盖 #46–#47 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（AOT —— #43 起默认；无需 ACL，属推荐路径）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# #47 主判点 1：FlyoutPage 无障碍节点数（Home 内容页；此前同路径 =1）
sh tester-run.sh --kit-dir ./device-test-kit --a11y-probe
# #47 主判点 2 与超容量：加满 C/D/E 后 Activate A，抓 [maui-capacity] 抢占/恢复/重放原文（与截图闭环）
# 手动：aa start → 加 C/D/E → Activate A → hdc shell hilog | grep maui-capacity
# Blazor 探针（B2 走 MAUI WebView 内嵌 WASM；判定继续有效）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段用 kit 内 AOT hap；JIT 段需自建 jit 变体或 ACL；解释器轮改用 rc2b pack）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；**已刷新至 #47**）

`device-test-kit` release 的并列预签资产 **`preSigned-haps.tar.gz`** 当前为 **kit #47 件**（2026-10-05 重签；
asset **610975429**，**67,639,132 B / `f58c4906…`**；sidecar 88 B / `c95344ac…`，asset **610976421**；
树 `70775143…`；**内容 = kit #47 的 7 hap** + `preSigned-README.md` + `SHA256SUMS` 8/8；ZIP 条目与 kit
原件逐字节一致；7/7 `sign-hap.sh` + `verify-app` success、device-ids 单值 = tester UDID）。按 tester UDID
`60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19` 预签，`sha256sum -c SHA256SUMS` 后
`hdc install -r` **直装**；非 tester UDID 设备报 `9568344`。预签包是并列附加件，完整一轮仍用 kit tar。

## 1. kit #47 相对 #45 的增量（测试方视角；#46 一并交接）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **FIX-A11YFLYOUT（#47 主判点 1）** | `PushChildren` 补 `FlyoutPage.Detail`（恒入树）/ `FlyoutPage.Flyout`（仅 `IsPresented`）分支，镜像合成器 `ChildEnumerator`；rc.1 FlyoutPage 非 `IContentView`，旧 presented-content 分支覆盖不到 → 只发布根 | kit 主 hap（AOT）`--a11y-probe`：**nodeCount 1→70**（Home 内容页自检读数）、`status=1`；detail 恒发布、flyout 仅展开时发布且**保 detail**；截图 + `a11y/` 两文件 |
| 1.2 | **FIX-PREEMPT-RAW（#47 主判点 2）** | 壳 `pollManagedStatus` 扫描 `dotnet-status.txt` 自上次轮询的**新增段**，把含 `overlay preempted/restored/replay` 的行以 **`[maui-capacity]`** 前缀直写 hilog（文件被 trim 重写时整文件回退）；CEF stderr 挤掉镜像窗不再丢行 | 加 C/D/E（E 抢 A 槽）→ Activate A 后 hilog 取到原文：`preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`（交付方一轮共 5 行导出）+ 截图/JSON 闭环 |
| 1.3 | **承 #46：INTERP-DRAW2（主判点）** | 面外剔除（节点自身 Canvas 矩形不与 surface 相交且无 `shifted` 祖先时跳过自身绘制；子树照走；Image/弹层/TitleView 永不剔除）+ 变换单读 + 叶子免 childMap | 解释器轮：**interp draw 14.4→9.4 ms/帧、33.9→60.1 fps、每帧 CPU −27%**；JIT draw −15%、fps 不变（无回归）；套件 +3 pin |
| 1.4 | **承 #46：FIX-A11YBUTTON（主判点）** | 壳自检按钮改 Edges 绝对定位（左下角，避让区感知）+ `zIndex(webZOrderSeq+1)`（覆盖层之上） | 有/无 web 控件两态都可点：bounds `[523,1622][607,1668]`（窗口相对左下 8/7 px）；`uitest` 点按出对话框 `status=1` |
| 1.5 | **承 #45：自动释放 + INTERP-RENDER** | Remove web 控件 → `web slot destroy`（覆盖层消失）、re-add → `web slot create`（交互恢复）；布局门控：interp 20.7→30 fps（交付方复测 38–44）、meas≈0、CPU −13pt；JIT/AOT 60 fps 不变 | 同 #45 交接 §2（仍为有效回归项） |
| 1.6 | **承 #45/#44：动态槽 3 控件 + 默认 AOT + FRAMEPACING** | MAX/HOT 默认 4/2（clamp 2..8 / 2..max）；3 控件并发出画/交互、释放即拆、延迟命令回放 ≤32；5 MAUI hap 全 NativeAOT（`runtime-mode.txt=aot`、3 `.so`、无 JIT 运行时）；宿主 present 聚合真实 60.00 fps | 同 #44/#45 判定；第 5 槽超容量 LRU 已真机点验（主动抢占→slot 0、Activate→恢复重放、活覆盖层 ≤4） |
| 1.7 | **承 #42：JIT 解锁 / 解释器 rc2b / FIX-SLICERACE / L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c/镜像** | 同 #45 交接 §1.5 | 同 `2026-10-04-ohos-tester-handoff-kit45.md` §2；AOT kit 上继续适用 |
| 1.8 | **承 #41–#35：MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX / FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10** | 见对应交接文；判定点继续有效 | 同前各期望（套件自报行更新为 `593/595 floor 575`） |
| 1.9 | **门禁/指纹/7 hap/预签** | 交互套件 **593/595 floor 575**（#47 +2：a11y-flyout detail/panel；#46 +3：INTERP-DRAW2）、像素 `PIXEL ASSERTIONS PASSED`（43 PASS）、宿主导出契约 **151/151**、host UND 241/DT_NEEDED 5/denylist 0；壳 abc **370,240（`4b439e83…`）**/headless 24,324（`798b2477…`）、host **297,888（`7b1694d9…`）**；**7 hap**：5 MAUI 全 AOT + Blazor 默认/`-nocsp`；**预签刷新至 #47** | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**（ui abc 期望 370240）；`[suite] checks=593 total=595 floor=575 assert=True`；`runtime-mode.txt=aot` |
| 1.10 | **在途/外部项（明确）** | ①AGC App Linking 登记 + 真机 https 投递；②镜像分支 `m-web-mirror d47f1fcb3b` 未并入；③rc.2 csc 并行活锁（`DOTNET_PROCESSOR_COUNT=1` 绕过）；④stock JIT 长跑/后台唤醒未覆盖；⑤解释器混合模式保留默认 | ①–⑤ 登记「未测（在途）」，**不判失败** |

> **2026-10-05 复测回填（交付方口径，交测前以此为准）**：
> ① **a11y Flyout 节点数（#47 主判点 1）**：真机 probe5（AOT）`--a11y-probe` 自检 `accessibilityStatus: 1`、
> **nodeCount=70**（Home 内容页节点；此前同路径 1）；根因 = a11y 走查自 `IWindow.Content`（样例 = FlyoutPage）
> 无 FlyoutPage 分支（`Kit35/门控前/门控后`三件 IL 分支集逐字相同 ⇒ 与 INTERP-RENDER 门控无关；历史 24 =
> kit35-local 自检按钮 owner 误配 `com.cdgss.app` 跨应用读数）。headless 断言 `a11y-flyout detail`（nodes>1、
> 未展开无 flyout）+ `a11y-flyout panel`（IsPresented 后 flyout 入树且 detail 保留）；负控制（移除分支重编）
> `published=False nodes=1`、套件第一条断言红。证据 `fix-a11yflyout/device/{b1-a11y-dialog.json,jpeg,a11y-b.txt}`；
> **nodeCount 为沙箱自检读数（无读屏客户端），真读屏机复核不变**。
> ② **抢占原文（#47 主判点 2）**：低噪声复放（07:01:11–14）加 C/D/E（E 抢 A 槽）→ Activate A；原文
> （`device2/marker-lines.txt`，均 `[maui-capacity]` 前缀）：`preempted: slot 0`（E 抢 A）→ `preempted: slot 1`
> + `restored: slot 1` + `replay: slot 1`（Activate A；另 1 条 `preempted: slot 0` 属 LRU 级联）；共 5 行导出
> （3 preempt + 1 restored + 1 replay）。语义链仍以 `hybrid assets slot=` + 覆盖层出现/消失 + invoke 回显闭环。
> ③ **JIT/interp 45 min 浸泡（SOAK-JI）**：JIT RSS 320.5→342.1 MB（+21.6）、60.1 fps、0 崩/0 冻结/0 失 pid；
> interp（rc2b+INTERP-RENDER 优化件）328.2→225.9 MB（尾段大回收，native heap 42.6→27.3 MB）、34.3 fps（FPH
> 镜像口径）、0 崩 → 与 AOT soak2 对照，三路径 0 崩/0 失 pid，发版浸泡背书沿用（`2026-10-04-ohos-jit-interp-soak.md`）。
> ④ **INTERP-DRAW2 复测**：interp 触 60 Hz 上界（14.4→9.4 ms draw、33.9→60.1 fps、每帧 CPU −27%）；JIT
> draw −15%、fps 不变；首帧截图 base vs opt 平均差 0.018/255（`2026-10-04-ohos-interp-draw.md`）。
> ⑤ **第 5 控件超容量已真机点验**（#45 已闭环）：主动抢占→slot 0、Activate→恢复重放、活覆盖层 ≤4
> （`2026-10-04-ohos-a11y-and-capacity.md` §2）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **FlyoutPage a11y 节点数（主判点 1，FIX-A11YFLYOUT）** | 装默认 kit 主 hap（AOT）→ `--a11y-probe`（或 `uitest` 点 `A11Y` 自检按钮） | `a11y/selfcheck.txt`：`accessibilityStatus: 1 (attached - expected)`、**nodeCount=70**（此前 1）；**带读屏环境**复跑 T2 读屏开启态 / L1 Label / N1 List / F2 滚动焦点保持 / E1 role | `a11y/` 两文件 + 截图 + `summary a11y_*`；无读屏环境按「部分/未测」登记 |
| **抢占/恢复/重放原文（主判点 2，FIX-PREEMPT-RAW）** | 加满 3 控件后加 C/D/E（E 抢 A 槽）→ Activate A；抓 hilog | `[maui-capacity]` 原文：`preempted: slot 0`（E 抢 A）/ `preempted: slot 1` + `restored: slot 1` + `replay: slot 1`（Activate A）；活覆盖层 ≤4；截图/JSON 对应覆盖层出现/消失 | hilog 原文（`hilog | grep maui-capacity`）+ `hybrid assets slot=` 行 + 截图/JSON；512K 环噪声大时按「未测」登记 |
| **INTERP-DRAW2（#46 主判点，承）** | 解释器轮（rc2b pack + rc.2 kit hap + `interp.txt=3`）出画稳定后统计 | interp **draw ≤10 ms/帧、稳态 60 fps**（14.4→9.4、33.9→60.1；JIT/AOT 60 fps 不回归、draw −15%）；交互不变 | `FPH`/帧统计 + 截图 + hilog |
| **FIX-A11YBUTTON（#46 主判点，承）** | 有 web 控件（Home）与 no-web 变体两态点自检按钮 | 按钮在**左下角**且覆盖层之上可点（`[523,1622][607,1668]`）；点按出对话框 `status=1` | `uitest` dump/截图两态 |
| **自动释放（#45 主判点，承）** | 加满 3 控件 → 移除第 3 个 → 再加回 | `web slot destroy: 2`（覆盖层消失）→ `web slot create: 2`（交互恢复）；热对 [0,1] 不受影响 | 移除/重挂截图（c1–c5 同构）+ hilog |
| **INTERP-RENDER（#45 主判点，承）** | 解释器轮出画稳定后统计 | interp 稳态 ≥30 fps（交付方复测 38–44）、meas≈0、主线程 CPU 65.5–70.5%；JIT/AOT 60 fps 不变 | `FPH` + 帧统计 + 截图 |
| **动态槽 3 控件 / AOT 默认 / FRAMEPACING（承 #44/#43）** | 同页 3 控件；默认包冷启；present 聚合 | 3 控件各自出画/交互（`web slot create: 2`、`web capacity: 4`）；`runtime-mode.txt=aot` + 3 `.so`、无 libcoreclr/libclrjit；真实 60.00 fps | 截图 + hilog + `verify-kit` 深度断言 |
| **承 #42：JIT 解锁 / 解释器 rc2b / FIX-SLICERACE / L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c/镜像** | 自建 jit 变体（或 ACL）冷启；rc2b pack + rc.2 kit hap + `interp.txt=3`；JIT 8 轮 | JIT：`jitfort rc=0` + 探针 `1=OK 2=OK` + `canvas presented`；interp：`canvas presented`、无 `SIGSEGV(NULL)`；race=0 | 截图 + hilog |
| **承 #41：MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX** | 双 Hybrid/抢占/恢复（3 控件 + D/E 场景已覆盖）；enforcing 装包；8 MB 栈 | 同 #41 期望 | 截图 + hilog |
| **承 #40–#35：FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10** | 见 `2026-10-04-ohos-tester-handoff-kit45.md`、`…kit42.md`、`…kit36.md` §2 | 同前各期望；套件自报行 `593/595 floor 575` | 截图 + hilog + `dotnet-status.txt` |
| **套件基座** | 有源码测试者跑 `test/maui-platform-verify` | `[suite] checks=593 total=595 floor=575 assert=True`；导出 151/151 | 终端输出 |
| **承 #34/#33：rc.2 自述 + W6/W7/W8 + Blazor A/B + 主体** | 包内自述；各卡 | SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；逐项同 #34/#33 | 自述原文 + 截图 + `--a11y-probe` |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。
> **读屏环境**：交付方沙箱无读屏客户端（AMS `accessible=0`、client=0）→ 朗读/焦点顺序/动作类（T2 开启态/L1/N1/F2/E1 role）
> **不可测**；nodeCount=70 为壳自检读数。测试方请带 ScreenReader 环境复跑并按各卡回传。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#46）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.1.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（结构修复后重出）**：当前用 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；sdk fetch
   现锚）；`c1c85422715` 起 `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分对象库（静态 `.a` 保 shim、共享 `.so`
   静态 OpenSSL；sdk 布局+nupkg 两处校验）；`-r2`（601289590）/原包（`46d221f2…`）仅历史。
3. **解释器 pack（#42 更新；本波未动）**：用 **`ohos-interpreter-pack-rc2b.tar.gz`**（2,410,595 / `5974430509…`，
   asset 606999003）+ **rc.2 kit hap**（重签）+ #42+ 宿主；**勿用 rc.1 托管 CoreLib 的旧测试件**（QCall ABI 错配
   会 NULL 崩）；`interp.txt=1|2` 混合模式保留默认。
4. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`；enforcing 镜像直接装默认 kit 件
   （DEVCOMPAT-DEFAULT）；AOT 为默认（`-p:OpenHarmonyRuntimeMode=aot`）。
5. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 **未发布（WAIT，2026-10-04 复核）**：ohos-workload `rc2-watch`（`1d39eb7`）触发后按
   `2026-09-30-rc2-mainline-adoption.md` §8 换 pin、删 feed step。
6. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（#47 manifest 刷新 **`04b97494d2a`**，父
   `6cc3a161177` = pin 收口文档）；maui = **`d5384d6cc3`**（FIX-A11YFLYOUT 切片；父 `6652017ca5` = INTERP-DRAW2
   ← `189b87ca8a` = AUTODISCONNECT）；ohos-workload `master` **`f538c84`**（FIX-PREEMPT-RAW + FIX-A11YFLYOUT
   内容；pin **`3de9a95fe0`** = 三 workflow 默认 + `MAUI_OHOS_REF` fallback 推 `d5384d6cc3`）；sdk 锚
   **`266b196106`**（`WORKLOAD_BUNDLE_SHA256` f086d161 → **27c54c62**；父 `7024347b42` = #46 锚）；aspnetcore
   `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#46）：本机桌面 HAD-W32 / OpenHarmony-7.0.0.109–111 / API 26；hdc 无线
  `tconn 127.0.0.1:35111`（UDID 随轮次，SOAK-JI 轮 = `1BCE13C8…`）；SDK `sign-hap.sh` 自签；AOT 为默认路径。
- **#47 本轮证据（FIX-A11YFLYOUT + FIX-PREEMPT-RAW）**（scratch `fix-a11yflyout/`；HAD-W32 / 7.0.0.109，
  低噪声独占窗 07:01 前后）：probe5（A–E 样例变体，AOT，`92844ad7…` / 签 `57e4c044…`，abc 370,240/`4b439e83…`）；
  `--a11y-probe` **nodeCount=70**（`device/{b1-a11y-dialog.json,jpeg,a11y-b.txt}`）；抢占原文 5 行
  `[maui-capacity]`（`device2/marker-lines.txt`）；语义链 `hybrid assets slot=0`（E 抢 A）→ `slot=1`（恢复，
  B 被抢）复现。
- **#46 复测证据**（scratch `interp-draw2/`、`fix-a11ybtn/`）：interp 面外剔除 A/B（draw 14.4→9.4 ms、
  33.9→60.1 fps、CPU 每帧 −27%；JIT draw −15% 无回归）；A11Y 按钮两态（有 web `[523,1622][607,1668]` +
  对话框、no-web 变体同 bounds）。
- **#45/#44 复测证据**（scratch `autodisconnect/`、`interp-render/`、`kit44-local/`、`slots-dyn/`、
  `a11y45/`）：Remove→`web slot destroy: 2`→re-add→`web slot create: 2`+交互（c1–c5）；interp 30.0–30.1 fps /
  meas 0.0；3 控件并发 + 第 4/5 槽回收/重建；AOT soak 0 崩（1 次无声 pid 丢失归因见 release 域文）。
- **已知（承 #34–#46）**：JIT 主包 enforcing 镜像可开箱安装（DEVCOMPAT-DEFAULT）；JIT 首帧依赖 JITFORT
  （#42 默认；release 域需 ACL）；状态文件/轮询可能含上一轮残留行——判读以时序内状态为准。
- **本机可直接闭环**：AOT/JIT/interp 出画、多覆盖层 3–5 控件 + 释放/重建 + 抢占原文、Blazor 标记、
  a11y/日志/截图回路；命令模板 = `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`。

## 5. 自签与包布局要点（测试方视角；承 #34–#46）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap（全 AOT）**：payload-in-libs + DEVCOMPAT 重写；`libs/arm64-v8a` 3 `.so`（app.so + host
  297,888 + `libc++_shared.so` 1,267,392）、无 JIT 运行时；`ets/modules.abc` **370,240（`4b439e83…`）**；
  AOT payload `libhello-maui-app.so` 19,217,168；kit 根 `runtime-mode.txt=aot`。新 hap sha 以 release/包内
  `SHA256SUMS` 为准。
- **AOT/解释器资产**：均为独立资产，不在 kit tar 内；AOT 用 **`-struct1`**（asset 607541145）、
  `aot-haps-v3-rc2.tar.gz`（18,185,012 / `3d24f716…`，dtk 599996905）本波未动；解释器用 **rc2b** + **rc.2 kit hap**；
  安装会顶替 kit 主包，回 AOT 重装 kit hap。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #47）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准；
  **预签件本波已刷新（#47 件）**——非 tester UDID 设备仍 `9568344`，请回传 UDID 代签。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs/宿主依赖（UND 241）；5 MAUI hap 期望 `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；
   abc 期望 = **370,240（`4b439e83…`）/24,324（`798b2477…`）**；脚本 76,707 B / `d6008b25…`，以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮（AOT）/ `--blazor-probe` / `--mode-matrix`
   （解释器轮用 **rc2b pack**）/ `--a11y-probe` 四件同 #42。
3. **7 hap 表（kit #47 发布实测；`SHA256SUMS` 18 项 / 1,600 B / `6bbc2235…`）**：`hello-maui-app.hap`
   **22,331,837 / `37c958f2…`**（AOT）、`…-unsigned` **22,032,434 / `c0fa3727…`**、`…-permissions`
   **22,331,836 / `faf84159…`**、`…-api20` **22,331,829 / `c22343fb…`**、`…-api20-permissions`
   **22,331,832 / `5dcbd219…`**、Blazor 默认 **27,216,958 / `8ef34e95…`**（未签名）、
   `-nocsp` **27,216,659 / `2d4cd004…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。
   整包 tar **67,706,719 / `3d6bb58b…`**、树 `0f266636…`、sidecar `4adb0b60…`；bundle
   `openharmony-workload-1.0.0-preview.28.tar.gz` **73,059,625 / `27c54c62…`**（三处同步；dist sums
   `2954ab3d…`；sdkrc2 合并 sums 1,960 B / `c63de22e…`；sdk-ohos 锚 **`266b196106`**，
   `WORKLOAD_BUNDLE_SHA256` f086d161 → 27c54c62）；**解释器 pack rc2b**（asset 606999003）与
   **`-struct1` AOT pack**（asset 607541145）保持；**预签已刷新（#47 件：asset 610975429 /
   610976421）**；发布已完成：kit tar/边车两处（dtk **392356147** / latest **392077166**；asset
   610969198/610970096，latest tar 610970271/边车 610971070）+ bundle 三处（preview.28
   610961477/610964667、latest 610964837/610966356、sdkrc2 610966541/610968963）；四条 release body 含
   `## Integrity (kit #47)`；by-id 抽验 0 FAIL + 公开抽验（gh-proxy）见 release。重签/重打包后必变，以 release
   与随包校验为准；有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#46）。
4. 离线证据（供复核）：套件 **593/595 floor 575**、像素 PASS（43）、导出 **151/151**、壳 abc
   **370,240/24,324**（四包一致 + provenance `bb5a1758`）、host **`7b1694d9`**/UND 241、`build-arkts-shell`
   185/0、`verify-kit` 129/0、packs/repo-hygiene/tasks；selftests 全绿（细节 reg-kit47/selftest-*.log）；
   #47 设备证据见 scratch `fix-a11yflyout/`；#46 见 `interp-draw2/`、`fix-a11ybtn/`；#45 见 `autodisconnect/`、
   `interp-render/`；#42 证据见 `2026-10-03-ohos-tester-handoff-kit42.md` §4。

## 7. 风险 / 未验证（诚实清单）

- **a11y Flyout 复核边界**：nodeCount=70 为**沙箱自检读数**（无读屏客户端，AMS `accessible=0`/client=0）；
  真读屏机复核不变。detail 恒发布、flyout 仅 presented 发布且保 detail，由 headless 双断言 + 负控制把关；
  T2 开启态/L1 朗读/N1 List/F2 焦点保持/E1 role 等仍需测试方带 ScreenReader 环境复跑（无入口按「未测」登记）。
- **抢占原文边界**：定向导出只覆盖 **12×3 s 轮询窗内到达的行**（低噪声复放按窗内节奏）；512K hilog 环噪声大时
  仍可能丢行——以 `[maui-capacity]` 原文 + 截图/覆盖层出现消失 + invoke 回显为组合判据；本波原文与语义链均已复现。
- **INTERP-DRAW2 边界**：面外剔除只做 surface 级（ScrollView 子树仍随 `shifted` 走；clip 级可再降 draw 但已触
  60 Hz 上限）；interp 60.1 fps 为共享桌面测得、JIT 后段争用 48 为噪声；未复测手机域/release/AOT；单设备/共享 2in1。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递（P2c 本机产物已可验；自签包仍走显式 want）；
  ②镜像分支 `m-web-mirror d47f1fcb3b` 未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1`
  绕过未定位；④stock JIT 长跑/后台唤醒未覆盖（JIT 现非默认形态）；⑤解释器混合模式（`interp.txt=1|2`）保留默认。
- **AOT 默认边界**：JIT/解释器均需动态码；release/生产域请走 AOT 或申请 ACL
  （`ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）；手机只发 AOT。**发布域实测（2026-10-04）**：
  自签 release×AOT 正常；release×JIT `coreclr_initialize` 后 ~44 ms 崩（需华为发布 Profile + ACL/JIT 豁免后复验）；
  覆盖装先卸载（`9568286`）、过期 p7b=`9568329`（`2026-10-04-ohos-release-domain-and-pidloss.md`）。
- **动态槽边界**：热对 [0,1] 常驻；空闲 >2 不养 ArkWeb 引擎/文档（重建只付一次组件+加载，无定时器）；容量下调按
  suspend 抢占超容量 claim（旧 2 槽壳安全降级）；env 不可按应用注入。
- **解释器口径**：rc2b pack 只配 rc.2 kit hap + #42+ 宿主；旧 rc.1 托管 CoreLib 测试件会 QCall ABI NULL 崩（测试件问题）。
- **AOT pack 结构性缺陷（已修复入源）**：`c1c85422715` 拆分对象库；当前资产 = **`-struct1`**（asset 607541145）。
- **ICU/InvariantGlobalization（承 #42）**：本镜像无系统 ICU——宿主自动 invariant；应用侧如遇 hosting FailFast 可参考。
- **hilog 缓冲/状态伪影**：512K 环噪声大时 ≈4–5 s；`dotnet-status.txt`/轮询可能含上一轮残留行——以时序内状态为准；
  临时 `hilog -G 16M` 复核后请还原 512K。
- **门禁（本轮已跑）**：交互 593/595 floor 575、像素 PASS（43 PASS / 0 FAIL）、导出 151/151、preflight OK
  （ridgraph 20 / packs 25 / hap-targets 79 / tasks 9 / repo-hygiene 25）、host 151/151，CI 5/5 @ `3de9a95fe0`
  （interaction `37243299311` / pixel `37243299320` / host-export `37243299309` / ridgraph `37243299327` /
  markdownlint `37243299305`）+ sdk `ohos-install-tests` @ `266b196106` run `37245230111`；runtime manifest
  提交 `04b97494d2a` 为 docs-only（无 workflow run）。
