# 测试方交接：kit #51、MULTIWINDOW-L2 并存整合（a 子窗 a11y provider（per-instance 分区）+ b 子窗 ArkWeb 第二宿主）+ SEC-SCAN-6 A/B/C + L2CAP 平台容量探针（承 #50 MULTIWINDOW-L M1–M4 + polish-49，与 #49/#48–#45 全量）（2026-10-07）

> 日期口径：文件名按撰写日；**kit #51 发布实测（release「## Integrity（kit #51）」；发布已完成，一切数字以 release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **68,550,333 B / `e5f6541c…`**、树 **`a06d3897…`**、sidecar **`5c471871…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `5f8c1512…`**（#50 = tar 68,264,136 / `d70dc786…`、树 `b4b5055c…`、sidecar `2ffb3b6a…`；#49 = 67,888,851 / `477974bb…`、树 `8d03cb4c…` 对照）。
> **预签已刷新至 #51**（7 hap；**68,447,288 / `e9fb1e90…`**，asset **617093322**；sidecar 88 B / `96948b04…`，asset **617094016**；替换 #50 件 615517779/615518466）——按 tester UDID `60CF7B27…` 预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**（非该 UDID 报 `9568344`）。
> 构建基线（rc.2 线，同 #34–#50）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** / MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。**数字口径注（如实记录，承 #50）**：kit 内 5 MAUI AOT hap 用 **`~/.dotnet.rc2-fix`（SDK `26451.112` = 声明基线）** 打包；构建机默认 `~/.dotnet`（`26451.109`）的 ILCompiler 为 `11.0.0-rc.1.26451.109`（有偏离）——两安装的 preview.28 pack 已逐字节同步（`reg-kit51/pack-sync.log`）。**AOT 包**：rc.2 runtime pack 取 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145）；Crossgen2 rc.2 包（43,792,647 / `6bb8a375…`）与解释器 rc2b（2,410,595 / `5974430509…`，asset 606999003）本波未动。
> **在途/外部（明确）**：①AGC App Linking 登记 + 真机 https 投递；②镜像扩展分支 `m-web-mirror d47f1fcb3b` 尚未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；④stock JIT 长跑/后台唤醒未覆盖（JIT 现非默认）；⑤解释器混合模式（`interp.txt=1|2`）保留默认；⑥子窗 a11y 动作 e2e 与子窗 IME 实敲需外部环境（读屏服务 / 真键鼠）。
> **结论先行**：kit #51 = **kit #50（MULTIWINDOW-L M1–M4 + SEC-SCAN-5a/5b/5c + polish-49，承 #49 MULTIWINDOW-M/SEC-SCAN-4 与 #48–#45）** + **MULTIWINDOW-L2 并存整合**：**a 子窗 a11y provider**（节点表按 provider instance 分区 `host_a11y_table.c/h`、`RegisterCallbackWithInstance` 全链 + 带窗动作、壳 NodeContent/ContentSlot 双点 attach；导出 157→**163**；真机 W0 并存 / W2 自检 PASS）+ **b 子窗 ArkWeb 第二宿主**（child sink + `OpenHarmonyChildWeb` 按窗槽池 + capacity wire 修复；真机全链闭环、主窗零回归）+ **SEC-SCAN-6 A/B/C 全闭**（C = 关窗 `ReleaseWindow` hooks）+ **L2CAP 容量探针**（平台并发子窗上限 **255**；应用级 N=1 为壳契约）。指纹：壳 abc **473,048（`298622c0…`）/ headless 24,324（`798b2477…`）**、宿主 **347,040（`36acfc1d…`，导出 163/163、UND 250）**、套件 **688/690 floor 670**（超集 663+7+18+2）、预签已刷新至 #51；maui `bb6b06990d`、ow `696ebc0b`、sdk 锚 `a00e810c92`。判定点见 §2；承接 #50/#49/#48/#47/#45/…/#34 的判定点**继续有效**，本文覆盖 #51 增量与判读引用。
> **降级声明（必有，不判失败）**：子窗 a11y **动作 e2e 平台限制**（读屏服务不可得；W0/W2 并存与节点计数已过）· **子窗 ArkWeb hybrid/blazor 资产桥显式拒绝**（不建组件、命令丢弃、eval 即错）· 子窗 B6 导航否决未接（外部导航直载）· **子窗 IME 实敲人工卡** · 子窗池满（>2 控件）不挂载与就绪队列溢出丢 1 行日志 · ArkWeb `loadData` 裸 `#` 截断（平台共性）· SEC-6 余留原生 a11y 分区常驻（有界）· **应用级 N=1 为壳契约**（平台 255 已探明，产品化另行立项、本波不动壳）。
> kit 编号（#51）是团队跟踪口径，release 本身不带编号；以后续文档与 release 说明为准。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（AOT —— #43 起默认；无需 ACL，属推荐路径）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# #51 主判点 1：子窗 a11y provider（open 子窗 → hilog 主 status=1 不回退 + 子窗节点计数；动作需读屏环境）
# #51 主判点 2：子窗 ArkWeb（app://subwindow/openweb → CHILD WEB TAP 全链 + 主窗 60/60 fps 零回归）
# #51 主判点 3：SEC-6/门禁回归（sh verify-kit.sh 0/0；套件 688/690 floor 670；导出 163/163）
# #51 人工卡：子窗 IME 实敲（§1.5/§2；纯人工不阻塞）——承 #50 主判点：L 多窗 M1–M4 全量
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；**已刷新至 #51**）

`device-test-kit` release 的并列预签资产 **`preSigned-haps.tar.gz`** 当前为 **kit #51 件**（2026-10-07 重签；asset **617093322**，**68,447,288 B / `e9fb1e90…`**；sidecar 88 B / `96948b04…`，asset **617094016**；**内容 = kit #51 的 7 hap** + `preSigned-README.md` + `SHA256SUMS` 8/8；ZIP 条目与 kit 原件逐字节一致；7/7 `sign-hap.sh` + `verify-app` success、device-ids 单值 = tester UDID）。按 tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19` 预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**；非 tester UDID 设备报 `9568344`。预签包是并列附加件，完整一轮仍用 kit tar。

## 1. kit #51 相对 #50 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **L2-a 子窗 a11y provider（#51 主判点 1）** | ow `c562a32`/`f5a892a`、maui `9faacf3`/`ba7581022c`；新 `host_a11y_table.c/h` 节点表按 provider instance 分区（legacy 主分区逐字保留、`*_for(instance)` 命名分区 ≤8、instance ≤63 可打印 ASCII）；`OH_ArkUI_AccessibilityProviderRegisterCallbackWithInstance` + 带窗动作 `set_window_action_listener`；壳 `SubWindow.ets` NodeContent/ContentSlot 双点 `attachAccessibilityNodeFor`；导出 157→**163**；真机 HAD-W32（OH 7.0.0.111）**W0 并存 PASS**（`subwindow a11y provider status=1 instance=sub-1`，主窗 status=1/72 节点不回退）与 **W2 自检 PASS**（`subwindow a11y selfcheck status=1 nodes=10 instance=sub-1`，主窗 72 节点零回归） | open 子窗后 hilog 见子窗 `status=1 instance=sub-1` + 节点计数；`--a11y-probe` 主 provider 路径零变化；**动作 e2e 需读屏环境**（本镜像 `AccessibleManagerService accessible: 0`，离线 7 checks + 红控 4 条背书，不判失败） |
| 1.2 | **L2-b 子窗 ArkWeb 第二宿主（#51 主判点 2）** | ow `094ad51`/`3c486cf`、maui `086d358`/`2e441c35c9`；`host_napi.cpp` child web/eval sink（`child:` 前缀按窗路由并去前缀、主路径字节不变；`registerChildWebSink`/`registerChildWebEvalSink` 探测降级）；新 `OpenHarmonyChildWeb.cs`（`sub-N` 槽池 Max=2、64 条预就绪队列、`w:<win>|capacity|<n>` 就绪）；切片 5 文件按窗路由；壳全动态子池（`SUB_WEB_SLOT_MAX=2`，`Index.ets` 零改）。首轮暴露 **capacity wire 不一致**（state 携 `capacity` 而 managed 只认 `capacity|<n>` → 事件被丢、队列不冲刷）→ 修复壳发 `w:<win>|capacity|<n>` + 双侧兼容 URL 形 + 套件 `capacity wire` pin | 真机闭环（JIT）：`child web host registered`→`child web capacity: sub-1 2`→`child web cmd: data s0`→`slot create/attached`→`CHILD WEB OK`→`navigated: Success`→`eval title`→click 读回 **`CHILD WEB TAP`**；主窗零回归（双窗 **60.0/60.0 fps**、close slot destroy + WMS 残留 0、0 新 fault） |
| 1.3 | **L2CAP 平台容量探针（登记口径）** | scratch `mw-l/l2cap/`（纯 ArkTS 探针 `com.example.l2cap`，独立 bundle；产品代码/资产零变更）：平台并发子窗上限 **255**（第 256 个 `create` 稳定失败 `1300002`、3 轮一致；destroy 255/255、WMS 残留 0、可恢复；255 子窗 + 1 主窗 = 256 窗/应用疑为硬限，按观测口径记录） | **应用级 N=1 为壳契约而非平台限制**；kit 仍单实例（不预期多子窗入口）；产品化另行立项；探针边界 = 2in1 debug 单机型、不外推手机/release |
| 1.4 | **SEC-SCAN-6 A/B/C（随包加固）** | A：分区分配仅 `begin_for`（node 写改 create=0，合法窗口才拿分区）；B：子通道拒绝主窗 id（`TryParseState`；套件 pin `primary tag rejected`）；C：**`ReleaseWindow` hooks** 挂 `OpenHarmonyWindowHost.Reset()`——关窗清 child web `Capacity/Pending` + a11y frame/first-publish 标记（ow `1ed43d1` / maui `bb6b0699`，+2 checks、红控 3×assert=False） | 非主窗不得改写主窗/输入路由；close/reopen 不残留过期表；套件断言全绿（余留 = ow 原生 a11y 分区常驻，有界） |
| 1.5 | **降级声明（明示，不判失败）** | ①子窗 a11y 动作 e2e（读屏服务不可得，外部复跑）②子窗 ArkWeb hybrid/blazor 资产桥显式拒绝（不建组件、命令丢弃、eval 即错；下波壳侧 `onInterceptRequest` serving + 按窗注册回放）③子窗 B6 导航否决未接（外部导航直载）④子窗 IME 实敲人工卡（uitest 无子窗注入面，`2026-10-06-ohos-multiwindow-l-m4.md` 末节）⑤子窗池满（>2 控件）不挂载 + 就绪队列溢出丢 1 行日志⑥ArkWeb `loadData` 裸 `#` 截断（平台共性、主窗同样如此）⑦SEC-6 余留（原生 a11y 分区常驻、有界） | 上述现象按「降级预期」登记，不判失败；下波路径见 `-l2-consolidate.md` / `-l2-arkweb-subwindow.md` §4 |
| 1.6 | **承 #50：MULTIWINDOW-L M1–M4 + SEC-5a/5b/5c + polish-49** | M1 宿主每窗 surface 注册表（registry 84/84+桥 26/26）；M2 per-window renderer/带窗事件路由；M3 子窗挂 XComponent 第二 MAUI 视觉树（`sub-1` 720×480 `first frame=True`、触摸按窗、churn ×20 无残留）；M4 每窗焦点/IME/生命周期/a11y 分区/pinch；SEC-5a/5b/5c；polish-49（建窗 E=0、close WARN 平台内部、Home 焦点丢失链 suspend）；双窗稳态 60/60 fps、40 min 长稳 RSS 净 −34 MB | 同 `2026-10-06-ohos-tester-handoff-kit50.md` §2 主判点 1–4；L 主路径继续有效（L2 在其上分区/挂接） |
| 1.7 | **承 #49/#48–#45：M 子窗 / SEC-4 / R2R / AOT 首帧 / 帧率 / 多窗 S / FIXRR 等** | M 子窗 create/move/resize/close + 主窗 HIDDEN/SHOWN 协同；a11y 密码等长圆点；JIT R2R 冷启 **1031→710 ms**；AOT 首帧 **796→534 ms**；帧率投票 46.2→**60.0**；多窗 S 3120×1955；interp R2R=0；#47 a11y Flyout nodeCount 1→70、`[maui-capacity]` 抢占原文；#46/#45 全量（INTERP-DRAW2、动态槽、AOT 默认、FRAMEPACING） | 同各交接 §2；AOT kit 上继续适用 |
| 1.8 | **门禁/指纹/7 hap/预签** | 交互套件 **688/690 floor 670**（L2 +27：a11y 7 + child web 18 + SEC6-C 2；declared==printed、0 Unhandled、perf within）、像素 `PIXEL ASSERTIONS PASSED`、宿主导出契约 **163/163**（注册表 84/84 + bridge 26/26 + a11y-table 29/29）、host UND **250**/DT_NEEDED 5/denylist 0；壳 abc **473,048（`298622c0…`）**/headless 24,324（`798b2477…`）、host **347,040（`36acfc1d…`）**；**7 hap**：5 MAUI 全 AOT + Blazor 默认/`-nocsp`；**预签刷新至 #51** | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**（#51 包内脚本默认期望已重锚 **473,048**，裸跑即绿；`--expected-abc 473048` 同义；#50=436808、#49=414532 旧值 FAIL 属预期）；`[suite] checks=688 total=690 floor=670 assert=True`；`runtime-mode.txt=aot` |
| 1.9 | **在途/外部项（明确）** | ①AGC App Linking 登记 + 真机 https 投递；②镜像分支 `m-web-mirror d47f1fcb3b` 未并入；③rc.2 csc 并行活锁（`DOTNET_PROCESSOR_COUNT=1` 绕过）；④stock JIT 长跑/后台唤醒未覆盖；⑤解释器混合模式保留默认；⑥子窗 a11y 动作 e2e / IME 实敲待外部环境 | ①–⑥ 登记「未测（在途）」，**不判失败** |
| 1.10 | **轮包/证据（#51 未重出）** | tester 轮包/证据归档沿用 #50 件：`tester-round-kit50.tar.gz` **156,614,426 / `950c1e04…`**（asset 615575350）、`kit50-evidence-20261006.tar.gz` **52,940,085 / `4baf0b29…`**（asset 616009069）；#51 判读入口 = 本交接文 + `reg-kit51/`（发布/门禁/预签日志） | 未重出轮包/归档不判失败；如需归档随下轮补（可含本文 + L2 证据） |

> **2026-10-07 复测回填（交付方口径，交测前以此为准）**：① **L2-a**：真机 HAD-W32 / OH 7.0.0.111——W0 并存（子 `status=1 instance=sub-1` + 主 `status=1`/72 节点不回退，截图 `w0-coexist.png`）与 W2 自检（子 10 节点、主 72 零回归；pid 47518、VmRSS 270,856 kB）；动作 e2e 因镜像无读屏服务（AMS `accessible: 0`）留平台卡，离线 7 checks + 红控 4 条 `assert=False`。② **L2-b**：真机闭环日志与 `CHILD WEB TAP` 截图；capacity wire 修复前后对照 + 套件 pin。③ **L2CAP**：探针 3 轮 255/255、第 256 个 `1300002`、destroy 后 WMS 0 残留、RECOVER OK；证据 tar `l2cap-evidence-20261006.tar.gz` / `e3e761d7…`（9.3 MB）。④ **SEC-6**：A/B/C 修复 + 红控，C 的 close hook 入 `Reset()`；余留原生分区常驻有界。⑤ **承 #50/#49/#48**：L 全量设备轮 / M 流程 / R2R 四件 A/B / AOT 双窗 publish 同前口径（`device-round-50`、`kit49-soak`、`cg2-r2r/`）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **子窗 a11y provider（#51 主判点 1，L2-a）** | 装默认 kit 主 hap（AOT）→ `aa start -U app://subwindow/open` → 等 `windows=2` + 子窗出帧；主窗 `--a11y-probe` | 子窗 hilog `subwindow a11y provider status=1 instance=sub-1`；主窗 provider **零变化**（status=1、节点数不回退）；有读屏环境再复跑动作（click/scroll/text 带窗） | hilog（`subwindow a11y …`）+ `a11y/` 两文件 + 主窗自检截图；无读屏按「平台限制（B1）」登记 |
| **子窗 ArkWeb 全链（#51 主判点 2，L2-b）** | `aa start -U app://subwindow/openweb`（或包内样例）→ 观察 child web 链 → 子窗内点击读回 | 链序 `child web host registered`→`child web capacity: sub-1 2`→`child web cmd: data s0`→`slot create/attached`→`CHILD WEB OK`→`navigated: Success`→`eval title`→`CHILD WEB TAP`；主窗零回归（双窗 60/60 fps）；close 后 `slot destroy` + WMS 0 残留 | hilog 链 + 子窗截图（`CHILD WEB TAP`）+ 双窗 `WindowFrameStats` |
| **SEC-6 回归 / 门禁基座（#51 主判点 3）** | 有源码测试者跑 `test/maui-platform-verify` 与 `sh verify-kit.sh` | `[suite] checks=688 total=690 floor=670 assert=True`；verify-kit **0 FAIL/0 WARN**；导出 163/163；像素 PASS | 终端输出 |
| **L2CAP 口径核对（登记）** | 无需设备动作；确认 kit 仍单实例子窗 | 应用级 N=1 属壳契约（平台 255 已探明）；不预期多子窗入口 | 引用 `2026-10-06-ohos-l2-subwindow-capacity-probe.md`；不判失败 |
| **子窗 IME 实敲（人工卡，不阻塞）** | 解锁设备 → open 子窗 → 点子窗 Entry → 实敲 `hello-child` + 回车 → 切主窗敲字 → close/reopen | 键盘在子窗、文本只在子窗；跨窗事件=0；close 键盘收起、reopen Entry 回 `seed` | 4 行回传格式（设备/包/时间 + 每步 OK/FAIL + ≤20 行 hilog + 2 截图）；失败附 `hilog -x` 与 `uitest dumpLayout` |
| **承 #50：L 主判点 1–4** | 同 `2026-10-06-ohos-tester-handoff-kit50.md` §2（真多窗 / 每窗帧率长稳 / 每窗焦点生命周期 / 每窗 a11y 分区 / pinch） | 同 #50 期望；L2 落地后子窗 a11y 由「影子帧本地」升级为 provider 分区（W0/W2 已过，动作仍平台限） | 同 #50 交接回传 |
| **承 #49：M 流程 / SEC-4 密码脱敏** | 同 #49 交接 §2 主判点 1–2（`app://subwindow/demo` create/move/resize/close；密码 Entry 影子树） | 同 #49 期望；SEC-4 仍有效 | 同 #49 交接回传 |
| **承 #48：R2R / AOT 首帧 / 帧率 60 / 多窗 S / FIXRR** | 同 #48 交接 §2 主判点 2–5 | R2R 710 ms 档 / AOT 534 ms 档 / ≥58 fps（46.2→60.0）/ 3120×1955 / interp R2R=0 | 冷启计时 + `FPH` + 截图 + hilog |
| **承 #45–#47、动态槽、AOT 默认、FRAMEPACING、Blazor A/B** | 见 `2026-10-05-ohos-tester-handoff-kit47.md`/`…kit45.md`/`…kit42.md` §2 | 同前各期望；套件自报行 `688/690 floor 670` | 截图 + hilog + `dotnet-status.txt` |
| **无 hdc / 不能重签时** | 只有设备文件管理器（预签件仍可直装） | 自动项登记「未测（无 hdc）」；人工项照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。**读屏环境**：交付方沙箱无读屏客户端（AMS `accessible=0`、client=0）→ 子窗 a11y **动作类**实读**不可测**（W0/W2 并存与节点计数已真机过）；测试方请带 ScreenReader 环境复跑并按卡回传。**IME 人工卡**需真实键鼠/触摸设备，见 §1.5 与 `-l-m4.md` 末节。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#50）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；rc.1（`11.0.100-rc.1.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（`-struct1`）**：28,905,116 / `09345f95…`，asset 607541145（sdk fetch 现锚）；`aot-haps-v3-rc2.tar.gz` 18,185,012 / `3d24f716…`（dtk 599996905）本波未动。
3. **Crossgen2 rc.2 包（承 #48）**：`Microsoft.NETCore.App.Crossgen2.openharmony-arm64.11.0.0-rc.2.26451.112.nupkg`（43,792,647 / `6bb8a375…`；release `crossgen2-packs-11.0.0-rc.2`）作本地 folder feed + `RestoreConfigFile` 供 `-p:PublishReadyToRun=true`（消除 NU1100）；只用于 JIT。
4. **解释器 pack（#42 更新；#48 加 R2R=0）**：用 **`ohos-interpreter-pack-rc2b.tar.gz`**（2,410,595 / `5974430509…`，asset 606999003）+ **rc.2 kit hap**（重签）；`interp.txt=3` 时宿主置 `DOTNET_ReadyToRun=0`（FIXRR）；**勿用 rc.1 托管 CoreLib 的旧测试件**（QCall ABI 错配会 NULL 崩）；`interp.txt=1|2` 混合模式保留默认。
5. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`；enforcing 镜像直接装默认 kit 件（DEVCOMPAT-DEFAULT）；AOT 为默认（`-p:OpenHarmonyRuntimeMode=aot`）。
6. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；官方 rc.2 **未发布（WAIT；最近复核 2026-10-04）**：ohos-workload `rc2-watch` 触发后按 `2026-09-30-rc2-mainline-adoption.md` §8 换 pin、删 feed step。
7. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony`（release manifest 刷新 **`594e40d0b6c`**；tester docs 升 **#51** 提交 **`13a03c6236e`**；本交接文再补一笔 docs-only）；maui = **`bb6b06990d`**（L2 a+b 合并 `ba7581022c`/`2e441c35c9` → `9faacf3ca3`/`086d358dc3`，SEC-6 C = `bb6b0699`）；ohos-workload `master` = **`696ebc0b`**（L2 merge `c562a32d`/`094ad51b` + SEC6-C `1ed43d1` + pins `8ba02a8` + lint `696ebc0`）；pin：三 workflow `MAUI_OHOS_REF` = `bb6b06990d`；sdk 锚 **`a00e810c92`**（`WORKLOAD_BUNDLE_SHA256` 6a83c0f3 → **f4b4fe8d**；bundle 73,147,751 / `f4b4fe8d…`；锚提交经 Git Data API 推送、非强推）；aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#50）：本机桌面 HAD-W32/HAD-W24 / OpenHarmony-7.0.0.109–111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`（UDID 随轮次）；SDK `sign-hap.sh` 自签；AOT 为默认路径。
- **#51 本轮证据**（scratch `/data/storage/el2/base/tmp/opencode/reg-kit51/`）：构建 `kit51-build.status`（rc=0）、`build-host.log`（host 347,040/36acfc1d、导出 163/163）、`build-arkts-ui.log`/`build-arkts-headless.log`/`build-arkts-install.log`、`interaction-run.log`（688/690 floor 670）、`pixel-run.log`、`host-targets-check.txt`、`pack-abc-check.txt`（473,048/298622c0 + provenance）、`dist-abc-check.txt`、`preflight-quick-final.log`（gates 全绿）、`verify-kit51-raw.log`（KIT OK 0/0）、`publish51.log` + `verify-publish51.py`、`presign-k51/logs/*`（7/7 verify-app、tester UDID）、`aot-markers.txt`（5 MAUI AOT 标记）、`bundle-values51.env`/`sdk-inner51.env`/`pack-sync.log`、`sdk-anchor51.log`。
- **L2 设备证据**：a11y W0/W2 = `l2-a11y-device/`（`summary-w0w2.txt`、`w0-coexist.png`、`main-layout-selfcheck.json`、`restored-kit49.png`）；child web 全链 = `l2-arkweb/`（`CHILD WEB TAP` 截图 + 套件红/绿日志）；容量探针 = `mw-l/l2cap/`（`l2cap-evidence-20261006.tar.gz` / `e3e761d7…`）；SEC-6 = `sec6-scan/`。
- **设备纪律**：轮内 `.device-lock` 单轮一锁、轮末恢复 kit #49 hap 后释放；锁屏 `10106102` 快速失败 + 有限重试；hilog 16M→512K 还原（L2 两波均已还原）。
- **#50 证据**（scratch `reg-kit50/` + `mw-l/m4b/`）：双窗 60/60 fps、×10 suspend/resume、churn ×20、40 min soak；命令模板 = `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`。
- **工具件（承，未动）**：`tester-run.sh` v14（140,197 / `a174fcd0…`）、`device-round.sh`、a11y-client（kit #47/#48 线）；本波只更新包与文档，不重发工具资产。

## 5. 自签与包布局要点（测试方视角；承 #34–#50）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET（重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap（全 AOT）**：payload-in-libs + DEVCOMPAT 重写；`libs/arm64-v8a` 3 `.so`（app.so **22,716,460** hap 内 + host **347,040** + `libc++_shared.so`）、无 JIT 运行时；`ets/modules.abc` **473,048（`298622c0…`）**；kit 根 `runtime-mode.txt=aot`。新 hap sha 以 release/包内 `SHA256SUMS` 为准。
- **多窗边界（#51）**：子窗 a11y 已是 **provider 分区**（W0 并存/W2 自检过；动作 e2e 平台限）；子窗 ArkWeb 有 **第二宿主全链**（hybrid/blazor 资产桥显式拒绝、B6 未接）；平台级上限 = **255**（探针结题；壳仍 N=1）；子窗 IME 实敲为人工卡。见 `2026-10-07-ohos-l2-consolidate.md` 与平台限制 E5/C5。
- **AOT/解释器/Crossgen2 资产**：均为独立资产，不在 kit tar 内；AOT 用 **`-struct1`**（asset 607541145）、`aot-haps-v3-rc2.tar.gz`（dtk 599996905）本波未动；解释器用 **rc2b** + **rc.2 kit hap**；Crossgen2 用 `crossgen2-packs-11.0.0-rc.2`（folder feed）。安装会顶替 kit 主包，回 AOT 重装 kit hap。
- **包内文档口径**：包内 tester 文档（`快速开始.md`、`自签说明.md`、设备校验清单、`验收说明.md` 等）已同步升 #51；修订状态以 release 说明与随包文件为准（本波交接文为当前判读入口）。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #51）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准；**预签件本波已刷新（#51 件）**——非 tester UDID 设备仍 `9568344`，请回传 UDID 代签。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（#51 包内脚本默认期望已重锚 **473,048**，裸跑即绿；`--expected-abc 473048` 同义；深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/payload-in-libs/宿主依赖（UND 250）；5 MAUI hap 期望 `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；abc 期望 = **473,048（`298622c0…`）/24,324（`798b2477…`）**；脚本 76,707 B / `33bc35c8…`，以包内为准；#50=436808、#49=414532 旧值 FAIL 属预期）。
   - 绑定外层/解压树：`sh verify-kit.sh --anchor ../device-test-kit.tar.gz` 或包内 `--expect-tree-digest a06d3897507981c104b0a62618bf8c244518c1735ba9b31780695d3f0bce8843`（`--tree-digest` 可先打印核对）。
2. `tester-run.sh`（版本以包内自述为准，承 v14：140,197 B / `a174fcd0…`，asset 595131362）：常规轮（AOT）/ `--blazor-probe` / `--mode-matrix`（解释器轮用 **rc2b pack**）/ `--a11y-probe` 四件。
   - 常规一轮：`--kit-dir ./device-test-kit --install --start --capture 60`（AOT 默认）。
   - Blazor：`--blazor-probe`（断言 `BLZ_BOOT`/`BLZ_RENDERED` 两标记，失败落 `blazor-hilog.txt`）。
   - 四态矩阵：`--mode-matrix --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz`。
   - a11y：`--a11y-probe`（`a11y/selfcheck.txt` + `a11y/hilog-a11y.txt` + `summary a11y_*`）。
3. **7 hap 表（kit #51 发布实测；`SHA256SUMS` 18 项 / 1,600 B / `5f8c1512…`）**：`hello-maui-app.hap` **22,716,460 / `973361c9…`**（AOT）、`…-unsigned` **22,413,822 / `e4110d5a…`**、`…-permissions` **22,716,447 / `b5e2379c…`**、`…-api20` **22,716,457 / `270bb1c7…`**、`…-api20-permissions` **22,716,437 / `0c134238…`**、Blazor 默认 **27,218,497 / `5c35c014…`**（未签名）、`-nocsp` **27,218,194 / `0b5872c3…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。整包 tar **68,550,333 / `e5f6541c…`**、树 `a06d3897…`、sidecar `5c471871…`；bundle `openharmony-workload-1.0.0-preview.28.tar.gz` **73,147,751 / `f4b4fe8d…`**（三处同步；dist sums `9014f948…`（212 B）；sdkrc2 合并 sums 见 `reg-kit51/sdkrc2-sums-expected.txt`；sdk-ohos 锚 **`a00e810c92`**）；**解释器 pack rc2b**（asset 606999003）、**`-struct1` AOT pack**（asset 607541145）与 **Crossgen2 rc.2 pack**（43,792,647 / `6bb8a375…`）保持；**预签已刷新（#51 件：asset 617093322 / 617094016）**；发布已完成：kit tar/边车（dtk **617087017** / **617087622**、latest **617087808** / **617088356**）+ bundle 三处（preview.28 617084737/617085345、latest 617085555/617086124、sdkrc2 617086326/617086835）；四条 release body 含 `## Integrity (kit #51)`；by-id 抽验 + 零改动清单（dtk 392356147 2 changed / 54 unchanged、latest 392077166 4/0、sdkrc2 398936638 2/0、镜像 398739326 2/15）见 release。重签/重打包后必变，以 release 与随包校验为准；有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#50）。
4. 离线证据（供复核）：套件 **688/690 floor 670**、像素 PASS、导出 **163/163**、壳 abc **473,048/24,324**（四包一致 + provenance `1,166 B / 4a5ffafd`）、host **`36acfc1d`**/UND 250、preflight 全绿（ridgraph 20 / packs 25 / hap-targets 79 / tasks 9 / repo-hygiene 25 + host registry 84 / bridge 26 / a11y-table 29）、`build-host` 导出 163/163；#51 设备证据见 `l2-a11y-device/`、`l2-arkweb/`、`mw-l/l2cap/`、`sec6-scan/`；#50 见 `reg-kit50/`、`mw-l/m4b/`；#49 见 `reg-kit49/`；#48 见 `cg2-r2r/`、`aot-startup/`、`fps48/`。
5. **轮包/证据归档**：#51 未重出 tester 轮包与证据 tar（#50 件继续有效，见 §1.10）；本轮发布/门禁/预签日志在 `reg-kit51/`，L2 真机证据在 `l2-a11y-device/`、`l2-arkweb/`、`mw-l/l2cap/`、`sec6-scan/`（scratch，未入库）。

## 7. 风险 / 未验证（诚实清单）

- **L2-a 边界**：子窗 a11y 分区已在（导出 163/163、W0/W2 真机过），但 **动作 e2e 受平台读屏服务限制**（`accessible: 0`；离线 7 checks + 红控 4 条）；`Announce` 仍走主 provider（进程 API 无窗归属）；子窗 provider 关窗不 detach（与主 provider 同生命周期，SEC-5C-F 有界）。
- **L2-b 边界**：子窗 hybrid/blazor 资产桥显式拒绝（下波 = 壳侧 `onInterceptRequest` serving + managed 按窗注册回放）；B6 导航否决未接；池满（>2 控件）不挂载；就绪队列溢出丢 1 行日志；ArkWeb `loadData` 裸 `#` 截断为平台共性（主窗同样；样例以 `rgb()` 规避，未改壳语义）。
- **L2CAP 边界**：255 为探针观测上限（`1300002` 为通用窗状态错误码、非专用超限码；疑「256 窗/应用」硬限未获源码常量）；2in1 debug 域、单机型（HAD-W32 7.0.0.109），不外推手机/release；产品化（多 managed 子窗）另立项、本波不动壳单实例/801 契约。
- **SEC-6 边界**：A/B/C 修复 + 套件 pin（C 的 close hook 有红控）；余留 = ow 原生 a11y 分区常驻（有界）；B 的 device 侧未单独上机（CI/preflight pin 生效）。
- **#51 数字口径注（不确定项）**：kit 的 5 MAUI AOT hap 用 `~/.dotnet.rc2-fix`（SDK `26451.112` = 声明基线）打包；构建机默认 `~/.dotnet`（`26451.109`）的 ILCompiler 为 `11.0.0-rc.1.26451.109`，存在偏离——两安装的 preview.28 pack 已逐字节同步。
- **承 #50 多窗边界**：2in1 debug 域单设备结论，不外推手机/release；per-window pinch 真机多点注入不可用（离线 pin + 单测背书）；SEC-5c B–F 报告级（B 子窗 prompt 键盘全局、C 状态机顺序假设、D Back/按键无消费者、E pinch 非有限几何、F 子窗 a11y 帧常驻）。
- **R2R 边界（承 #48）**：单设备 n=3 冷启（pre-fix 窗口）；+11 MB 文件体积仍在；Crossgen2 包未本机重编（复用 rc.2 主线 CI 字节）；R2R 只用于 JIT，interp 抑制（FIXRR）；release 域 JIT 仍受 ACL/发布 Profile 限制。
- **AOT-STARTUP / FPS48 / MULTIWINDOW-S 边界**：同 #48 交接 §7（非轮交替 ±20 ms 漂移、RS 投票 dump 未直证、`freeWindowModeChange`/split 真形态与手机域未测）。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递；②镜像分支 `m-web-mirror d47f1fcb3b` 未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；④stock JIT 长跑/后台唤醒未覆盖（JIT 现非默认形态）；⑤解释器混合模式（`interp.txt=1|2`）保留默认；⑥子窗 a11y 动作 e2e / IME 实敲待外部环境。
- **AOT 默认边界**：JIT/解释器均需动态码；release/生产域请走 AOT 或申请 ACL（`ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）；手机只发 AOT。**发布域实测（2026-10-04）**：自签 release×AOT 正常；release×JIT `coreclr_initialize` 后 ~44 ms 崩（需华为发布 Profile + ACL/JIT 豁免后复验）；覆盖装先卸载（`9568286`）、过期 p7b=`9568329`（`2026-10-04-ohos-release-domain-and-pidloss.md`）。
- **动态槽边界**：热对 [0,1] 常驻；空闲 >2 不养 ArkWeb 引擎/文档；容量下调按 suspend 抢占超容量 claim；env 不可按应用注入；N=8 实测 >4 不挂（安全上限 4）。
- **解释器口径**：rc2b pack 只配 rc.2 kit hap + #42+ 宿主；旧 rc.1 托管 CoreLib 测试件会 QCall ABI NULL 崩（测试件问题）。**ICU/InvariantGlobalization（承 #42）**：本镜像无系统 ICU——宿主自动 invariant；应用侧如遇 hosting FailFast 可参考。
- **hilog 缓冲/状态伪影**：512K 环噪声大时 ≈4–5 s；`dotnet-status.txt`/轮询可能含上一轮残留行——以时序内状态为准；临时 `hilog -G 16M` 复核后请还原 512K。
- **门禁（本轮已跑）**：交互 688/690 floor 670、像素 PASS、导出 163/163、preflight OK（ridgraph 20 / packs 25 / hap-targets 79 / tasks 9 / repo-hygiene 25 + host registry 84 / bridge 26 / a11y-table 29），CI 5/5 @ pin `696ebc0`（interaction `37548888210` / pixel `37548888313` / host-export `37548888169` / ridgraph `37548888051` / markdownlint `37548888104`）+ sdk `ohos-install-tests` @ `a00e810c92` run `37553127808`；runtime manifest 提交 `594e40d0b6c` 与 tester docs 提交 `13a03c6236e` 为 docs-only（无 workflow run）。
