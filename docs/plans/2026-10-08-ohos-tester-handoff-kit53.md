# 测试方交接：kit #53、POST-L3 合并收口（A11Y-SELFCHECK 子窗首发布修复 + B6 子窗导航否决）+ kit #52 全量（MULTIWINDOW-L3 N=2 多子窗 M1–M4 + L3 尾项；承 #51–#45）（2026-10-08）

> 日期口径：文件名按撰写日；**kit #53 发布实测（release「## Integrity（kit #53）」；发布已完成，一切数字以 release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **68,883,057 B / `dba88961…`**、树 **`9c67b5ec…`**、sidecar **`47ace1d0…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `39489081…`**（#52 = tar 68,853,027 / `9e60fdc0…`、树 `c1fa6421…`、sidecar `d10ae2e7…`；#51 = 68,550,333 / `e5f6541c…`、树 `a06d3897…` 对照）。
> **预签已刷新至 #53**（7 hap；**68,755,353 / `d1732195…`**，asset **620760775**；sidecar 88 B / `35b736b3…`，asset **620762418**；预签树 `422cc15f…`；替换 #52 件 618854752/618855844）——按 tester UDID `60CF7B27…` 预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**（非该 UDID 报 `9568344`）。
> 构建基线（rc.2 线，同 #34–#52）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** / MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。**数字口径注（如实记录，承 #52）**：kit 内 5 MAUI AOT hap 用 **`~/.dotnet.rc2-fix`（SDK `26451.112` = 声明基线）** 打包；构建机默认 `~/.dotnet`（`26451.109`）的 ILCompiler 为 `11.0.0-rc.1.26451.109`（有偏离）——两安装的 preview.28 pack 已逐字节同步（`reg-kit53/pack-sync.log`）。**AOT 包**：rc.2 runtime pack 取 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145）；Crossgen2 rc.2 包（43,792,647 / `6bb8a375…`）与解释器 rc2b（2,410,595 / `5974430509…`，asset 606999003）本波未动。
> **在途/外部（明确）**：①AGC App Linking 登记 + 真机 https 投递；②镜像扩展分支 `m-web-mirror` 并入状态以 sdk 仓库为准（sdk 锚 `64f239eb28`）；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；④stock JIT 长跑/后台唤醒未覆盖（JIT 现非默认）；⑤解释器混合模式（`interp.txt=1|2`）保留默认；⑥子窗 a11y 动作 e2e 与子窗 IME 实敲需外部环境（读屏服务 / 真键鼠）；⑦轮包与 #53 证据归档由发布/轮包波次另行落库（轮包文 = `2026-10-08-ohos-tester-round-kit53.md`，指纹以该文为准；本文不预填）。
> **结论先行**：kit #53 = **kit #52 全量（MULTIWINDOW-L3 N=2 多子窗产品化 M1–M4 + L3 尾项 a11y 分区 release/hybrid-Blazor 资产桥；承 #51 MULTIWINDOW-L2 + SEC-SCAN-6 A/B/C + L2CAP 与 #50/#49/#48–#45）** + **POST-L3 合并收口两卡**：①**A11Y-SELFCHECK 子窗首发布修复**（根因 = per-window 发布门禁的独立 `NativeLibrary` 预探针 `WindowProviderExportAvailable` 在托管 loader 误报 “no export”（`export=False`）而 in-process host 已共享/attached；修法 = `PublishSecondary` 直连 `ohos_host_accessibility_provider_status_for` + `OpenHarmonyWindowHost.OnFrame` 在 `WindowPublishPending` 强制重绘一次；真机诊断 `nodes=0` → 修复 **`nodes=10` ×2**（sub-1/sub-2）+ 定向关/重开 `nodes=10`（instance=sub-2）、主窗零回归）②**B6 子窗导航否决**（壳 `onLoadIntercept` 网关 + managed `Navigating`/一次性批准；真机 deny（无 nav 命令/无批准）与 ok（ask→approve→reload 闭环）双链闭环）。指纹：壳 abc **542,936（`f18f0855…`）/ headless 24,324（`798b2477…`）**、宿主 **367,520（`ad7ab986…`，导出 164/164、UND 252；同 #52 指纹）**、套件 **737/740 floor 720**、预签已刷新至 #53；maui `caa463434b`、ow `7259a0f`、sdk 锚 `64f239eb28`。判定点见 §2；承接 #52/#51/#50/…/#34 的判定点**继续有效**，本文覆盖 #53 增量与判读引用。
> **降级声明（必有，不判失败）**：子窗 a11y **动作 e2e 平台限制**（读屏服务不可得；W0/W2/双窗 status=1/selfcheck nodes=10 已过）· 子窗 hybrid/Blazor 资产桥**真机样例缺**（无现成 child+hybrid 样例 hap；离线红/绿）· uitest Back/alert 注入限制（子窗 Back 未送达、子窗 alert 无样例触发点）· 子窗 B6 导航否决**真机样例**（`//host` 探针受桌面控制台 z-order 抢占；deny/ok data: 链已闭环）· 子窗 IME 实敲人工卡 · a11y `export=False` 预探针**加载器层根因未追**（仅证托管 loader 结论错误）· 多窗同槽 hybrid invoke fail-closed · 子窗池满（>2 控件）不挂载与就绪队列溢出丢 1 行日志 · ArkWeb `loadData` 裸 `#` 截断（平台共性）· SEC-6 原生 a11y 分区常驻（有界）· 应用级 N=2 为壳契约（平台上限 255）。
> kit 编号（#53）是团队跟踪口径，release 本身不带编号；以后续文档与 release 说明为准。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（AOT —— #43 起默认；无需 ACL，属推荐路径）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# #53 主判点 1：a11y selfcheck（两窗各自先开 → selfcheck 读 nodes=10；定向关 + 重开复检同值）
# #53 主判点 2：B6 子窗导航否决（child web 内 deny 链接 → 无 nav 命令/无批准、载荷保留；
#    ok 链接 → ask → managed Navigating → nav approved → 重载）
# 门禁回归：sh verify-kit.sh 0/0；套件 737/740 floor 720；导出 164/164
sh tester-run.sh --kit-dir ./device-test-kit --a11y-probe
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；**已刷新至 #53**）

`device-test-kit` release 的并列预签资产 **`preSigned-haps.tar.gz`** 当前为 **kit #53 件**（2026-10-08 重签；asset **620760775**，**68,755,353 B / `d1732195…`**；sidecar 88 B / `35b736b3…`，asset **620762418**；树 `422cc15f…`；**内容 = kit #53 的 7 hap** + `preSigned-README.md` + `SHA256SUMS` 8/8；ZIP 条目与 kit 原件逐字节一致；7/7 `sign-hap.sh` + `verify-app` success、device-ids 单值 = tester UDID）。按 tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19` 预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**；非 tester UDID 设备报 `9568344`。预签包是并列附加件，完整一轮仍用 kit tar。

## 1. kit #53 相对 #52 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **A11Y-SELFCHECK 子窗首发布修复（#53 主判点 1）** | maui `l3/a11y-selfcheck` `8c7a859c91` → merge `4910d470db`（自 `277967cc56`）。根因：per-window 发布门禁的独立 `NativeLibrary` 预探针 `WindowProviderExportAvailable` 在托管 loader 误报 “no export”（诊断件 `[diag] secondary publish … export=False status=1 … published=False`），in-process host 与壳实际共享、已 attached，3 s 子窗自检读 `status=1 nodes=0`。修法（最小、仅次窗路径）：`PublishSecondary` 门禁直连 `ohos_host_accessibility_provider_status_for`（旧 host 由 `EntryPointNotFound` 缓存一次并保持本地帧降级）+ `OpenHarmonyWindowHost.OnFrame` 在 `WindowPublishPending`（影子帧 + provider attached + 从未发布）强制重绘一次；`ProviderStatusProbe` 仅离线测试缝 | 真机 HAD-W32：诊断件自检 `nodes=0` → 修复件 `published 10 nodes through its own provider instance` + 自检 **`nodes=10` ×2**（sub-1/sub-2）+ **定向关/重开后 `nodes=10`**（instance=sub-2）+ 空闲轮复跑 `nodes=10` ×3（pid 54218 首=末、0 fault）；主窗零回归（主画布 n=297–301、avg 16 ms、pid 首=末）；离线 +1 check（`m4 a11y selfcheck pending repaint`，红控：去掉 pending 重绘 → `repainted=False assert=False`，还原复绿）；证据 `a11ysc/round2.log` + round1 诊断 |
| 1.2 | **B6 子窗导航否决（#53 主判点 2）** | ow `l3/b6-nav-veto` `d25c0eb` + maui `b64c477f8e` → merges `96267f2`/`caa463434b`。壳 `SubWindow.ets` child ArkWeb 加 `onLoadIntercept` 网关——app 来源、本槽 hybrid/blazor origin 与一次性放行标记直接放行；外部主帧导航取消并经子窗事件通道问 managed（`w:<surface>\|s<slot>\|navask\|<id>`，URL 在事件 URL 槽）；managed `nav` 命令按 (slot,id,url) 精确回放一次；pending 有界（8/TTL 5 s/URL 8 KiB），槽销毁丢弃该槽 pending；maui `OpenHarmonyWebViewHandler.HandleChildNavigationRequest` 与主 `__OHNAV` 同校验（绝对 http(s) 带 host、H-C2 拒网络路径/方案样式、控制字符/长度、未知窗口 fail-closed）、对 (window,slot) handler 同步抛 `Navigating`（应用可否决）、批准键 `child\|<win>\|<slot>\|<url>` 共享主表 cap/prune、child `started` 一次性消费（不二次抛）；主窗键/编码/行为不变（主 B6 既有 pin 全绿） | 离线 `b6c` 5 checks（route+one-shot / cancel / fail-closed / window isolation / 源 pin；红控 = 去掉 child 分派 → 3 行 assert=False、套件 Unhandled exit 134）；真机 JIT（子窗 data: 页探针链接）：**deny** 链 ask → 无 `nav` 命令/无批准（应用取消、载荷保留）；**ok** 链 ask → managed `Navigating` → `child web cmd: nav s0\n<id>\n<url>` → 壳 `nav approved` → 重载 DNS 失败 `child web error` → hide（完整 ask→approve→reload 子窗闭环）；`//host` 探针因桌面控制台抢占 z-order 未取到干净点击（记样例） |
| 1.3 | **承 #52：MULTIWINDOW-L3 N=2 多子窗产品化（M1–M4）** | ow `71c7fb6` + 尾项 `f2ff017`/`eac789f` + pin `0685d7b`、maui `277967cc56`：M1 壳会话注册表（`sub-N` 最低空闲复用、`SUB_WINDOW_MAX=2`、全命令按 `cmd.surfaceId` 路由、容量 801 诚实拒绝）+ maui `MaxManagedSubWindows=2`；M2 每窗身份握手（会话 `generation` + per-child claim 表 + managed op7 ack、宿主 op 上限 5→7）；M3 每窗 IME/a11y/overlay/Back（单键盘焦点窗、per-window alert 槽/几何、Back 焦点窗）；M4 按窗 child ArkWeb 槽池（`child:<window>\|<op>`、`unregisterChildWebSink`、两窗同 slot0 不串）；L3 尾项①a11y 分区 release（导出 163→164）②子窗 hybrid/Blazor 资产桥（离线红/绿） | 同 `2026-10-07-ohos-tester-handoff-kit52.md` §2 主判点 1–3；套件/门禁继续以 #52 判定点为准（#53 下数字重锚 542,936/737/740 floor 720） |
| 1.4 | **承 #52：L3 尾项（a11y release + 资产桥）** | 关窗 hook 释放命名分区（selftest 15/15 + 双红控）；hybrid/Blazor 子槽注册 + `onInterceptRequest` serving + bit30 child invoke（离线 +3 checks；**真机样例缺**，沿降级） | 同 handoff52 §2「L3 尾项回归（登记）」；不判失败 |
| 1.5 | **承 #51：MULTIWINDOW-L2 并存整合 + SEC-SCAN-6 + L2CAP** | a 子窗 a11y provider（per-instance 分区，W0/W2 真机 PASS）+ b 子窗 ArkWeb 第二宿主（child sink + capacity wire 修复）+ SEC-6 A/B/C 全闭 + L2CAP 平台容量探针（平台 255；应用级 N=2 壳契约） | 同 `2026-10-07-ohos-tester-handoff-kit51.md` §2；L2 链序与判定点继续有效 |
| 1.6 | **承 #50/#49/#48–#45：MULTIWINDOW-L / M / SEC-4 / R2R / AOT 首帧 / 帧率 / 多窗 S / FIXRR / a11y Flyout / 抢占原文等** | 同 `2026-10-07-ohos-tester-handoff-kit52.md` §1.7 口径（真多窗 M1–M4、M 子窗、JIT R2R 710 ms、AOT 首帧 534 ms、60 fps、interp R2R=0、Flyout nodeCount 70、`[maui-capacity]`） | 同各交接 §2；AOT kit 上继续适用 |
| 1.7 | **门禁/指纹/7 hap/预签** | 交互套件 **737/740 floor 720**（= 731 + B6 5 + a11y 1；declared==printed、0 Unhandled、perf within）、像素 `PIXEL ASSERTIONS PASSED`、宿主导出 **164/164**（registry 84/84 + bridge 26/26 + a11y-table 47/47 v2 15/15）、host UND **252**/DT_NEEDED 5；壳 abc **542,936（`f18f0855…`）**/headless 24,324、host **367,520（`ad7ab986…`，同 #52 指纹）**、provenance `1,166 B/167fa683`；**7 hap**：5 MAUI 全 AOT + Blazor 默认/`-nocsp`；**预签刷新至 #53** | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**（#53 包内脚本默认期望已重锚 **542936,24324**，裸跑即绿；`--expected-abc 542936` 同义；#52=534192、#51=473048、#50=436808、#49=414532 旧值 FAIL 属预期）；`[suite] checks=737 total=740 floor=720 assert=True`；`runtime-mode.txt=aot` |
| 1.8 | **在途/外部项（明确）** | ①AGC App Linking 登记 + 真机 https 投递；②镜像分支并入状态以 sdk 仓库为准；③rc.2 csc 并行活锁（`DOTNET_PROCESSOR_COUNT=1` 绕过）；④stock JIT 长跑/后台唤醒未覆盖；⑤解释器混合模式保留默认；⑥子窗 a11y 动作 e2e / IME 实敲待外部环境；⑦轮包/证据归档另行落库 | ①–⑦ 登记「未测（在途）」，**不判失败** |
| 1.9 | **轮包/证据** | 轮包 **`tester-round-kit53.tar.gz`**（#53 聚合）由轮包波次另行出具（`reg-kit53/round53/` 组装中；指纹/成员以 `2026-10-08-ohos-tester-round-kit53.md` 为准，本文不预填）；#53 证据归档随下轮补；#53 判读入口 = 本交接文 + `reg-kit53/`（发布/门禁/预签日志）+ `a11ysc/`、`b6/` 设备证据（scratch） | 轮包指纹未出**不判失败**；轮包与 release 原件逐件 sha 一致（出包后） |

> **2026-10-08 复测回填（交付方口径，交测前以此为准）**：① **A11Y-SELFCHECK**：诊断件（`export=False status=1` + 探针 `nodes=0`）→ 修复件（`published 10 nodes` + 自检 `nodes=10` ×2 + 定向关/重开 `nodes=10`、主窗零回归）；离线 +1 check（红控在案）。② **B6**：离线 `b6c` 5 checks（红控 3×assert=False exit 134）；真机 deny/ok 双链闭环（ask→approve→reload 子窗链；`//host` 样本受 z-order 限制）。③ **收口**：A11Y-SELFCHECK（ow `887e172` → merge `11972de`）+ B6（ow `d25c0eb` → merge `96267f2`）并入主线；合并树重编 ui abc **542,936/`f18f0855…`**（四包 22/23/24/28 一致）+ host `ad7ab986` 不变；套件 **737/740 floor 720**；pin `277967cc56→caa463434b`、CI 5/5 @ `7259a0f`；`verify-kit` EXPECT 重锚 542936（ow `35aa1c3`）。④ **承 #52/#51/#50/#49/#48**：L3 N=2 / L2 / L / M / R2R 四件 A/B / AOT 双窗 publish 同前口径（`-l3-post-consolidate.md`、`-l3-m3.md` §5、`-l3-b6-modes.md`、`2026-10-07-ohos-l3-consolidate-final.md`）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **a11y selfcheck 子窗首发布（#53 主判点 1，A11Y-SELFCHECK）** | 开两窗（`app://subwindow/open` ×2 或样例）→ 逐窗读 a11y 自检（`--a11y-probe` 或样例自检入口）→ 定向关一窗 → 重开再读 | 每窗自检 **`nodes=10`**（sub-1/sub-2 各一）+ `published 10 nodes through its own provider instance`；定向关/重开后 `nodes=10`（新 instance）；主窗 72 节点/画布零回归；0 fault | hilog（`[diag] secondary publish`/`published 10 nodes`/`a11y selfcheck status=1 nodes=10`）+ 双窗截图 |
| **B6 子窗导航否决（#53 主判点 2，L3-B6-MODES）** | 开两个子窗 → 各 `openweb`（`child:` 槽）→ 子窗 data: 页内点 deny 链 → 再点 ok 链 → 观察 hilog | deny：ask 无 `nav` 命令/无批准、载荷保留；ok：ask → managed `Navigating` → `child web cmd: nav s0` → `nav approved` → 重载（DNS 失败 `child web error` 属预期）→ hide；主窗导航无回归 | hilog 链（`navask`/`nav approved`/`child web cmd: nav`/`child web error`）+ 双窗截图 |
| **N=2 多子窗全链（承 #52 主判点 1–3）** | 同 `2026-10-07-ohos-tester-handoff-kit52.md` §2（windows=2/identity confirmed/输入分窗/定向关/重开 gen 递进/按窗 child web/每窗 IME/overlay） | 同 #52 期望；**#53 下 a11y selfcheck 期望从 `nodes=0` 余项改为 `nodes=10`**（旧余项已修）；套件数字重锚 737/740 floor 720 | 同 handoff52 回传项 |
| **门禁回归 / 指纹基座** | 有源码测试者跑 `sh verify-kit.sh` 与 `test/maui-platform-verify` | verify-kit **0 FAIL/0 WARN**（默认 542936,24324）；`[suite] checks=737 total=740 floor=720 assert=True`；导出 **164/164**；像素 PASS | 终端输出 |
| **L3 尾项回归（登记）** | 无需额外设备动作；确认导出 164 与 a11y 关窗 release 行为 | 导出 **164/164**；关窗后重开同 id a11y provider 重建、无残留（离线 selftest 15/15 + 门禁） | 引用 `2026-10-07-ohos-l3-tail-fixes.md`；不判失败 |
| **子窗 hybrid/Blazor 资产桥（登记，真机样例缺）** | 无现成 child+hybrid/blazor 样例 hap；本轮不设真机主判点 | 离线红/绿 + 门禁 pin 已覆盖；**真机抽验顺延**（样例波次）；多窗同槽 invoke fail-closed | 引用 `2026-10-07-ohos-l3-tail-fixes.md` §②；不判失败 |
| **子窗 IME 实敲（人工卡，不阻塞）** | 解锁设备 → 开两窗 → 点 `sub-1` Entry 实敲 `hello-child`+回车 → 点 `sub-2` Entry 实敲 → 关窗/reopen | 键盘与文本只落聚焦窗（跨窗事件=0）；关窗键盘收起、reopen Entry 回 `seed` | 5 行回传（设备/包/时间 + 每步 OK/FAIL + ≤20 行 hilog + 2 截图）；失败附 `hilog -x` 与 `uitest dumpLayout` |
| **承 #52：L3 M1–M4 判定点** | 同 `2026-10-07-ohos-tester-handoff-kit52.md` §2 主判点 1–3 | 同 #52 期望；#53 起 a11y selfcheck 改读 `nodes=10` | 同 handoff52 回传 |
| **承 #51/#50：L2 a/b + L2CAP + L 主判点** | 同 `2026-10-07-ohos-tester-handoff-kit51.md` / `2026-10-06-ohos-tester-handoff-kit50.md` §2 | 同期待；容量 255 为交付方结题（tester 无需复跑）；动作 e2e 需读屏环境 | 同各交接回传 |
| **承 #49/#48/#47–#45** | 同各交接 §2（M 流程 / R2R 710 ms / AOT 534 ms / ≥58 fps / 3120×1955 / a11y Flyout / 抢占原文 / 动态槽等） | 同前各期望；套件自报行 `737/740 floor 720` | 截图 + hilog + `dotnet-status.txt` |
| **生命周期/churn 复跑（观察）** | 开两窗 → Home → 恢复 → 快速 open/close ×20 → 关末窗 | 每窗 suspended/resumed 各一次；churn registered/unregistered 1:1、WMS/会话残留 0、pid 恒定、0 fault | hilog + WMS dump + 轮末截图 |
| **无 hdc / 不能重签时** | 只有设备文件管理器（预签件仍可直装） | 自动项登记「未测（无 hdc）」；人工项照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。**读屏环境**：交付方沙箱无读屏客户端（AMS `accessible=0`、client=0）→ 子窗 a11y **动作类**实读**不可测**（W0/W2/双窗 status=1/selfcheck `nodes=10` 与节点计数已真机过）；测试方请带 ScreenReader 环境复跑并按卡回传。**IME 人工卡**需真实键鼠/触摸设备，见 §1.3 与 `2026-10-06-ohos-multiwindow-l-m4.md` 末节。**Back/alert 注入限制**见 `2026-10-07-ohos-l3-m3.md` §3；**B6 `//host` 样例受限**见 `2026-10-07-ohos-l3-b6-modes.md` §4。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#53）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；rc.1（`11.0.100-rc.1.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（`-struct1`）**：28,905,116 / `09345f95…`，asset 607541145（sdk fetch 现锚）；`aot-haps-v3-rc2.tar.gz` 18,185,012 / `3d24f716…`（dtk 599996905）本波未动。
3. **Crossgen2 rc.2 包（承 #48）**：`Microsoft.NETCore.App.Crossgen2.openharmony-arm64.11.0.0-rc.2.26451.112.nupkg`（43,792,647 / `6bb8a375…`；release `crossgen2-packs-11.0.0-rc.2`）作本地 folder feed + `RestoreConfigFile` 供 `-p:PublishReadyToRun=true`（消除 NU1100）；只用于 JIT。
4. **解释器 pack（#42 更新；#48 加 R2R=0）**：用 **`ohos-interpreter-pack-rc2b.tar.gz`**（2,410,595 / `5974430509…`，asset 606999003）+ **rc.2 kit hap**（重签）；`interp.txt=3` 时宿主置 `DOTNET_ReadyToRun=0`（FIXRR）；**勿用 rc.1 托管 CoreLib 的旧测试件**（QCall ABI 错配会 NULL 崩）；`interp.txt=1|2` 混合模式保留默认。
5. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`；enforcing 镜像直接装默认 kit 件（DEVCOMPAT-DEFAULT）；AOT 为默认（`-p:OpenHarmonyRuntimeMode=aot`）。
6. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；官方 rc.2 **未发布（WAIT；最近复核沿用 2026-10-07）**：ohos-workload `rc2-watch` 触发后按 `2026-09-30-rc2-mainline-adoption.md` §8 换 pin、删 feed step。
7. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony`（release manifest 刷新 **`5dc92e73841d`** = kit #53 数字；POST-L3 记录 `26fab38e658`；本交接文再补一笔 docs-only）；maui = **`caa463434b`**（A11Y-SELFCHECK `8c7a859c91` → merge `4910d470db` + B6 `b64c477f8e` → merge `caa463434b`）；ohos-workload `master` = **`7259a0f`**（POST-L3 merges `11972de`/`96267f2` + verify-kit 重锚 `35aa1c3`（EXPECT 534192→542936）+ pins）；pin：三 workflow `MAUI_OHOS_REF` = `caa463434b`；sdk 锚 **`64f239eb28`**（`WORKLOAD_BUNDLE_SHA256` 5a00331f → **031ba342**；bundle 73,213,144 / `031ba342…`；锚提交经 pinned 路由推送、非强推）；aspnetcore `e10d030184`（以 release/仓库页为准）。
8. **包内文档/预签**：包内 tester 文档为 **#52 口径**（随包固化、不可回改；快照重生于 2026-10-08 kit 切包，含 verify-kit.sh 重锚 542936）；runtime 侧 18 篇 tester docs 的 #53 块已随本波补齐；轮包见 §1.9；判读以本文（handoff53）、release 说明与 runtime 侧 #53 文档为准。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#52）：本机桌面 HAD-W32/HAD-W24 / OpenHarmony-7.0.0.109–111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`（UDID 随轮次）；SDK `sign-hap.sh` 自签；AOT 为默认路径。
- **#53 本轮证据**（scratch `/data/storage/el2/base/tmp/opencode/reg-kit53/`）：构建 `kit53-build.status`（rc=0）、`build-host.log`（host 367,520/ad7ab986、导出 164/164、UND 252）、`build-arkts-ui.log`/`build-arkts-headless.log`/`build-arkts-install.log`、`interaction-run.log`（737/740 floor 720）、`pixel-run.log`、`preflight-quick-final.log`（PREFLIGHT OK）、`verify-kit53-raw.log`（KIT OK 0/0）、`publish53.log` + `verify-publish53.py`、`presign-k53/logs/*`（7/7 verify-app、tester UDID、asset 620760775/620762418）、`aot-markers53`、`pack-abc-check.txt`（542,936/f18f0855 + provenance 167fa683）、`pack-sync.log`、`bundle-values53.env`/`sdk-inner53.env`、`sdk-anchor53.log`；轮包 `round53/`（组装中）。
- **POST-L3 设备证据**：a11y `a11ysc/round2.log` + round1 诊断（`nodes=0`→`nodes=10` ×2、reopen、主窗零回归）；B6 `b6/`（离线红控 + 真机 deny/ok 双链）；明细见 `-l3-m3.md` §5、`-l3-b6-modes.md`、`-l3-post-consolidate.md`（scratch 未入库）。
- **L3/l2/l 证据（承）**：`l3m2-devround/`、`l3m3-devround/`、`l3-consolidate/`、`reg-kit52/soak52/` 等（见 #52/#51 交接 §4）。
- **设备纪律**：轮内 `.device-lock` 单轮一锁、轮末恢复参照 hap 后释放；锁屏 `10106102` 快速失败 + 有限重试；hilog 16M→512K 还原（POST-L3 各轮均已还原）。
- **构建纪律**：一次一构建（MemAvailable<2.5GB 等待）；门禁在 pin worktree 上以 `~/.dotnet`（preview.28 已切）执行；kit 的 AOT haps 用 `~/.dotnet.rc2-fix`（SDK .112 声明基线）打包（`reg-kit53/kit53-prep.log`、`gates-1/2b` 日志）。
- **工具件（承，未动）**：`tester-run.sh` v14（140,197 / `a174fcd0…`、asset 595131362）、`device-round.sh`、a11y-client（kit #47/#48 线）；本波只更新包与文档，不重发工具资产。

## 5. 自签与包布局要点（测试方视角；承 #34–#53）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET（重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap（全 AOT）**：payload-in-libs + DEVCOMPAT 重写；`libs/arm64-v8a` 3 `.so`（app.so **19,520,240** hap 内 + host **367,520** + `libc++_shared.so`）、无 JIT 运行时；`ets/modules.abc` **542,936（`f18f0855…`）**；kit 根 `runtime-mode.txt=aot`。新 hap sha 以 release/包内 `SHA256SUMS` 为准。
- **多窗边界（#53）**：N=2 已产品化（壳契约；平台上限 255 探明）；每窗 IME/a11y/overlay/Back 与按窗 child web 已落地；**a11y selfcheck 首发布已修**（子窗自检 `nodes=10` ×2 + reopen 稳定）、**B6 子窗导航否决已接通**（deny/ok 双链）；hybrid/Blazor 资产桥仍**真机样例缺**；多窗同槽 invoke fail-closed；子窗 a11y 动作 e2e 平台限。见 `-l3-post-consolidate.md`、`-l3-b6-modes.md`、`-l3-tail-fixes.md` 与平台限制 E5。
- **AOT/解释器/Crossgen2 资产**：均为独立资产，不在 kit tar 内；AOT 用 **`-struct1`**（asset 607541145）、`aot-haps-v3-rc2.tar.gz`（dtk 599996905）本波未动；解释器用 **rc2b** + **rc.2 kit hap**；Crossgen2 用 `crossgen2-packs-11.0.0-rc.2`（folder feed）。安装会顶替 kit 主包，回 AOT 重装 kit hap。
- **包内文档口径**：kit 内 tester 文档（`快速开始.md`、`自签说明.md`、设备校验清单、`验收说明.md` 等，8 份）**随包固化（#52 口径）、不可回改**；轮包 `docs/` 快照以轮包文为准；runtime 侧 18 篇 tester docs 的 #53 块已随本波补齐——**判读以本文（handoff53）、release 说明与 runtime 侧 #53 文档为准**（包内文件仅作历史快照）。
- **预签件**：`preSigned-haps.tar.gz`（#53 件，asset 620760775；含 `preSigned-README.md` + `SHA256SUMS` 8/8；7/7 verify-app + device-ids 单值）；非目标 UDID 走重签（§0b）。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #53）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准；**预签件本波已刷新（#53 件）**——非 tester UDID 设备仍 `9568344`，请回传 UDID 代签。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（#53 包内脚本默认期望已重锚 **542936,24324**，裸跑即绿；`--expected-abc 542936` 同义；深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/payload-in-libs/宿主依赖（UND 252）；5 MAUI hap 期望 `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；abc 期望 = **542,936（`f18f0855…`）/24,324（`798b2477…`）**；脚本 76,728 B / `a15292f6…`，以包内为准；#52=534192、#51=473048、#50=436808、#49=414532 旧值 FAIL 属预期）。
   - 绑定外层/解压树：`sh verify-kit.sh --anchor ../device-test-kit.tar.gz` 或包内 `--expect-tree-digest 9c67b5ec56b3698ac0e72f4905b9f4640a99fe0cc7888d281c35823e57888c79`（`--tree-digest` 可先打印核对）。
2. `tester-run.sh`（版本以包内自述为准，承 v14：140,197 B / `a174fcd0…`，asset 595131362）：常规轮（AOT）/ `--blazor-probe` / `--mode-matrix`（解释器轮用 **rc2b pack**）/ `--a11y-probe` 四件。
   - 常规一轮：`--kit-dir ./device-test-kit --install --start --capture 60`（AOT 默认）。
   - Blazor：`--blazor-probe`（断言 `BLZ_BOOT`/`BLZ_RENDERED` 两标记，失败落 `blazor-hilog.txt`）。
   - 四态矩阵：`--mode-matrix --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz`。
   - a11y：`--a11y-probe`（`a11y/selfcheck.txt` + `a11y/hilog-a11y.txt` + `summary a11y_*`）；#53 起子窗自检期望 `nodes=10`。
3. **7 hap 表（kit #53 发布实测；`SHA256SUMS` 18 项 / 1,600 B / `39489081…`）**：`hello-maui-app.hap` **22,880,068 / `eb915f1a…`**（AOT）、`…-unsigned` **22,577,890 / `ede4312c…`**、`…-permissions` **22,880,072 / `f254a130…`**、`…-api20` **22,880,056 / `f616bd44…`**、`…-api20-permissions` **22,880,070 / `e95db865…`**、Blazor 默认 **27,218,497 / `98219df8…`**（未签名）、`-nocsp` **27,218,194 / `5a73e0c7…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。整包 tar **68,883,057 / `dba88961…`**、树 `9c67b5ec…`、sidecar `47ace1d0…`；bundle `openharmony-workload-1.0.0-preview.28.tar.gz` **73,213,144 / `031ba342…`**（三处同步；dist sums `90139094…`（212 B）；sdk-ohos 锚 **`64f239eb28`**）；**解释器 pack rc2b**（asset 606999003）、**`-struct1` AOT pack**（asset 607541145）与 **Crossgen2 rc.2 pack** 保持；**预签已刷新（#53 件：asset 620760775 / 620762418）**；发布已完成：kit tar/sidecar（dtk **620750159** / **620751902**、latest **620752460** / **620754074**）+ bundle 三处（preview.28 620744582/620746121、latest 620746406/620747691、sdkrc2 620748166/620749735）；四条 release body 含 `## Integrity (kit #53)`；by-id 抽验 + 零改动清单（dtk 392356147 2 changed / 62 unchanged、latest 392077166 4/0、sdkrc2 398936638 2/0、镜像 398739326 2/15）见 release。重签/重打包后必变，以 release 与随包校验为准。
4. 离线证据（供复核）：套件 **737/740 floor 720**、像素 PASS、导出 **164/164**、壳 abc **542,936/24,324**（四包一致 + provenance `1,166 B / 167fa683`）、host **`ad7ab986`**/UND 252、preflight 全绿（ridgraph 20 / packs 25 / hap-targets 79 / tasks 9 / repo-hygiene 25 + host registry 84 / bridge 26 / a11y-table 47）；#53 设备证据见 `a11ysc/`、`b6/`（scratch）；#52 见 `reg-kit52/`；#51 见 `reg-kit51/`；#50 见 `reg-kit50/`。
5. **轮包/证据归档**：`tester-round-kit53.tar.gz` 由轮包波次另行出具（`reg-kit53/round53/` 组装中；指纹以 `2026-10-08-ohos-tester-round-kit53.md` 为准）；#53 证据归档随下轮补（#52 归档件继续有效，见 handoff52 §1.10）。
6. **轮包取证（出包后）**：外层 sidecar + 包内 `SHA256SUMS` 双层校验、by-id/gh-proxy 抽验与 release 零改动清单；`docs/` 快照以轮包文为准（本交接文为新增当前判读入口）。
7. **本地复跑（源码侧）**：门禁/像素套件入口见 `2026-10-05-ohos-device-round-script.md` 与各 POST-L3 文；#53 基座 = `checks=737 total=740 floor=720`、导出 164/164、pixel PASS、preflight 全绿（以合并树为准）。

## 7. 风险 / 未验证（诚实清单）

- **A11Y-SELFCHECK 边界（#53）**：修复后子窗自检在 3 s 窗内 `nodes=10`；`export=False` 只证明预探针在托管 loader 的结论错误，**未追到平台加载器层根因**；attach 晚于末帧的时序由 `OnFrame` 重绘覆盖、未单独造真机红例；真机无读屏服务，动作 e2e 沿用平台限制 B1。
- **B6 边界（#53）**：`//host` 设备点击样本受桌面控制台 z-order 抢占（deny/ok data: 链已闭环）；pending 有界（8/TTL 5 s/URL 8 KiB）、槽销毁丢 pending；主窗 B6 键/编码/行为不变。
- **L3-M1/M2 边界（承）**：N=2 为壳契约（`SUB_WINDOW_MAX=2`；平台 255 已探明，产品化到 K>2 未立项）；身份握手依赖 claim 表/窗口名（错名 fail-closed）；主窗路径零回归为不变量。
- **L3-M3/M4 边界（承）**：IME 实敲人工卡（uitest 无子窗注入面）；Back/alert 真机受注入限制（离线 pin 覆盖归属/路由）；`child:<window>|<op>` 坏 tag/未注册窗 fail-closed；hybrid/blazor 资产桥**真机样例缺**（离线红/绿）；多窗同槽 hybrid invoke fail-closed；ArkWeb `loadData` 裸 `#` 截断为平台共性。
- **L3 尾项边界（承）**：a11y 分区 release 依赖关窗 hook；SDK 无 provider unregister API（旧 CUSTOM 节点随 NodeContent 销毁走）；SEC-6 原生 a11y 分区常驻（有界）。
- **L2CAP/平台边界**：255 为探针观测上限（`1300002` 为通用窗状态错误码；疑 256 窗/应用硬限未获源码常量）；2in1 debug 域、单机型（HAD-W32 7.0.0.109/7.0.0.111），不外推手机/release。
- **#53 数字口径注（不确定项）**：kit 的 5 MAUI AOT hap 用 `~/.dotnet.rc2-fix`（SDK `26451.112` = 声明基线）打包；构建机默认 `~/.dotnet`（`26451.109`）的 ILCompiler 为 `11.0.0-rc.1.26451.109`，存在偏离——两安装的 preview.28 pack 已逐字节同步。
- **文档口径（不确定项）**：kit 内 8 份 tester 文档为 **#52 口径**（随包固化、不可回改）；runtime `docs/plans/` 的 18 篇 tester docs 已升 #53 块（2026-10-08 docs 补丁）——数字以 release `## Integrity (kit #53)` 与本文为准。
- **承 #51/#50 多窗边界**：per-window pinch 真机多点注入不可用（离线 pin + 单测背书）；SEC-5c B–F 报告级；单设备 2in1 debug 域结论不外推。
- **R2R / AOT-STARTUP / FPS48 / MULTIWINDOW-S 边界**：同 #48 交接 §7（单设备 n=3 冷启、+11 MB 文件体积、Crossgen2 复用 rc.2 主线 CI 字节、R2R 只用于 JIT、release 域 JIT 受 ACL/发布 Profile 限制、RS 投票 dump 未直证、`freeWindowModeChange`/split 真形态与手机域未测）。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递；②镜像分支并入状态以 sdk 仓库为准；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；④stock JIT 长跑/后台唤醒未覆盖（JIT 现非默认形态）；⑤解释器混合模式（`interp.txt=1|2`）保留默认；⑥子窗 a11y 动作 e2e / IME 实敲待外部环境；⑦轮包/证据归档另行落库。
- **AOT 默认边界**：JIT/解释器均需动态码；release/生产域请走 AOT 或申请 ACL（`ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）；手机只发 AOT。**发布域实测（2026-10-04）**：自签 release×AOT 正常；release×JIT `coreclr_initialize` 后 ~44 ms 崩（需华为发布 Profile + ACL/JIT 豁免后复验）；覆盖装先卸载（`9568286`）、过期 p7b=`9568329`（`2026-10-04-ohos-release-domain-and-pidloss.md`）。
- **动态槽边界**：热对 [0,1] 常驻；空闲 >2 不养 ArkWeb 引擎/文档；容量下调按 suspend 抢占超容量 claim；env 不可按应用注入；N=8 实测 >4 不挂（安全上限 4）。
- **解释器口径**：rc2b pack 只配 rc.2 kit hap + #42+ 宿主；旧 rc.1 托管 CoreLib 测试件会 QCall ABI NULL 崩（测试件问题）。**ICU/InvariantGlobalization（承 #42）**：本镜像无系统 ICU——宿主自动 invariant；应用侧如遇 hosting FailFast 可参考。
- **hilog 缓冲/状态伪影**：512K 环噪声大时 ≈4–5 s；`dotnet-status.txt`/轮询可能含上一轮残留行——以时序内状态为准；临时 `hilog -G 16M` 复核后请还原 512K。
- **门禁（本轮已跑）**：交互 737/740 floor 720、像素 PASS、导出 164/164、preflight OK（ridgraph 20 / packs 25 / hap-targets 79 / tasks 9 / repo-hygiene 25 + host registry 84 / bridge 26 / a11y-table 47），CI 5/5 @ pin `7259a0f`（interaction `37724762076` / pixel `37724762158` / host-export `37724762150` / ridgraph `37724762139` / markdownlint `37724762089`）+ sdk `ohos-install-tests` @ `64f239eb28` run `37728679048`；runtime manifest 提交 `5dc92e73841d` 与本交接文为 docs-only（无 workflow run）。
