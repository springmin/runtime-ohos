# docs/plans 文档索引

> 本目录是 OpenHarmony .NET/MAUI 移植的过程文档库：测试/交付文档、主审计报告、交接状态与历史批次记录。
> 「状态（最后更新）」列 = 用途 + 该文件最近一次 git 提交日期。图例：✅ 当前生效 · 🔄 进行中/计划 · ⏳ 待执行 · 📦 阶段快照（已完成工作的记录）。
> kit #31 日期口径：文件名带 09-29 的交接/一页/复核/调研文按撰写日命名（不改名以免链接漂移），kit #31 发布日 = **2026-09-28**（RELEASE-VALUES `date`）。
> 「包内名」指该文档随设备测试 kit 分发时的文件名。
> kit 自检：解压后在包内运行 `sh verify-kit.sh`（逐文件校验 `SHA256SUMS` + 6 个 hap 摘要；kit #23 起为强化版：逐 hap 深度断言 `resources.index`/abc/libs/`dotnet.zip`/宿主依赖，**kit #24 再加 `libs/arm64-v8a/.dotnet-payload.json` payload-in-libs 断言**，**kit #25 更新期望值（abc `234620`/`18532`、`dotnet.zip` 254 项、`resources.index` ≤ 2 KiB）、kit #26 沿用同一脚本，kit #27 把 abc 期望重锚 `245412`、kit #28 再重锚 `264136`、kit #29 重锚 `281052`/`20916`（#30 沿用）**，FAIL → 退出码 1、WARN → 仍 `KIT OK`；对 kit #22 全过、对旧包如实报 FAIL）。

## 面向测试与交付（外部读者优先）

| 文档 | 一句话 | 状态（最后更新）|
|---|---|---|
| `2026-09-24-ohos-nativeaot-maui-slice.md` | MAUI 平台切片可发现性（回应 NativeAOT 阻塞 #4.2）：main=上游镜像不合并的原因、`feature/openharmony` + `ohos-slice-1.0.1` 源码包（含 sha256）、类型名对照（`UseOpenHarmony`/`OpenHarmonyMauiAppHost`/`OpenHarmonyBlazorWebViewHandler`）、csproj 源码包含与 TFM 门控接线、构建/下载验证 | ✅ 当前（2026-09-24）|
| `2026-09-29-ohos-tester-handoff-kit31.md` | **kit #31 测试方交接（当前）**：Blazor WASM/ArkWeb 组件增量（第 6 个 hap `hello-blazorwasm-host-unsigned.hap`（26,794,931 B / `36010a9c…`，未签名，bundle `com.example.opendotnet`，需自签）+ tester-run v13 `--blazor-probe`（`BLZ_BOOT`/`BLZ_RENDERED` 自动断言、失败落 `blazor-hilog.txt` + 截图）+ 人工首屏/`/counter` +1/截图）+ 判定点、校验与取证、仍未验证边界；MAUI 5 hap 与 abc `281052`/`20916`/导出 143/143/套件 391/371 不变；整包：tar **207,023,588 B / `f4325d2f…`**、树 **`52e77ee8…`**、sidecar **`7d0cba77…`**、`SHA256SUMS` **16 项 / 1,410 B / `f49b9a0e…`**；tester-run v13 **137,113 B / `2caa06bd…`**（asset 594519342） | ✅ 当前（2026-09-29）|
| `2026-09-28-ohos-tester-handoff-kit30.md` | **kit #30 测试方交接（历史）**：MS-MODE 增量（runtime-mode 打包开关 `-p:OpenHarmonyRuntimeMode=jit|aot|interp`（默认 jit）→ hap `libs/<abi>/runtime-mode.txt`；宿主优先级 file>manifest>default、日志 `runtime-mode=<v> source=…`；aot 缺库显式回退 JIT、interp 可带 `-p:OpenHarmonyInterpreterPack`；tester-run **v12**（126,658 B / `87763a3e…`，asset 593961018：`summary runtime_mode`、清单 interp 的 Run C `run_c_via=manifest`）；MAPFIX harmony 重切（MapOverlay 真编译：abc 291,628 B/`a637a513…`、tar `9b0506fa…`））+ 判定点（runtime_mode 标记录入/优先级、模式矩阵清单路线、Map 点亮（AGC AppKey + 同指纹重签）、承 #29 回归）+ 校验与取证、仍未验证边界；指纹：abc **281,052**/`5c06143a…`（headless **20,916**/`54a1a201…`）、导出 **143/143**、套件 **391/floor 371**；整包发布实测 tar **196,992,264**/`a781c25b…`、树 **`cc1ca935…`**、sidecar **`a63cd34f…`**、bundle **30,563,349**/`c4647fc8…`（5 hap ~75.91 MB，默认 75,911,491/`333b0436…`；zip 279、`libs` 270 含 `runtime-mode.txt=jit`） | 📦 快照（2026-09-28）|
| `2026-09-28-ohos-tester-handoff-kit29.md` | **kit #29 测试方交接（历史）**：R3 增量（CoreSpeechKit TTS（`@kit.CoreSpeechKit` 双门、五 op；无 Kit 降级不抛；真朗读需 HMS 设备 + harmony 壳；AGC 清单第 13 行无权益/权限门槛）/ HUKS-first SecureStorage（设备绑定 AES-256-GCM 密钥、**0 权限**；无 HUKS 回退文件密钥并如实标注非硬件后备；重启读回/换设备不可解/删除清 key 判定点）/ tester-run **v11**（`--mode-matrix` 四态一键 + `--a11y-probe`；119,452 B / `2355e493…`）/ devloop v1（build/sign/install/start/logs 一键增量，替代 Hot Reload）/ 自绘深度五连（文本编辑光标·选区·IME 组合、页面转场·控件状态·共享元素·减少动效、列表增量加载·ScrollTo·分组折叠·滚动物理、图片低清先出→高清（解码位图最多约 43× 小）、深链冷启动/热激活））+ 判定点（TTS speak/stop/locales + 降级、HUKS 四判、模式矩阵、a11y、文本编辑/动画/列表/图片/深链、承 #25–#28 回归）+ 校验与取证明细、仍未验证边界；指纹：abc **281,052**/`5c06143a…`（headless **20,916**/`54a1a201…`）、导出 **143/143**、套件 **387/floor 367**；整包数字入口 = release「## Integrity」（本页不写死；#28 对照值见下行） | 📦 快照（2026-09-28）|
| `2026-09-29-ohos-blazor-resign-one-pager.md` | **Blazor 组件重签与验收操作卡（kit #31 · 一页版）**：`hello-blazorwasm-host-unsigned.hap`（约 26,794,931 B / `36010a9c…`，bundle `com.example.opendotnet`）重签 → 安装/启动 → 自动判读（`BLZ_BOOT`+`BLZ_RENDERED`；`--blazor-probe` 一键）→ 人工首屏/`/counter` +1/截图 → 失败回传（`blazor-hilog.txt`+截图）与常见问题 | ✅ 当前（kit #31，2026-09-29）|
| `2026-09-28-ohos-retest-taskcard.md` | **复测任务单（一页，kit #31，2026-09-29）**：取件清单（kit tar **207,023,588 B / `f4325d2f…`**、sidecar **`7d0cba77…`**、树 **`52e77ee8…`**、aot-haps 17,093,146 B / `91e1b9d3…`、harmony-haps 196,898,796 B / `9b0506fa…`（MAPFIX 重切 2026-09-28：overlay 真编译，abc 291,628 B/`a637a513…`）、解释器 pack 2,419,988 B / `a10699b3…`、`tester-run.sh` v13 137,113 B / `2caa06bd…`（asset 594519342））→ 执行顺序五步（`verify-kit.sh` → `--mode-matrix` 一键四 Run → harmony 变体（AGC 就绪）→ `--a11y-probe` → Blazor 重签 + `--blazor-probe`）与每步期望/回传 → JIT/XWE/AOT/解释器/harmony/runtime_mode/Blazor 判定表 → 注意（自签 9568257 属预期、重签需华为调试证书；Blazor 重签 bundle `com.example.opendotnet`） | ✅ 当前（2026-09-29）|
| `2026-09-26-ohos-tester-handoff-kit28.md` | **kit #28 测试方交接（历史）**：R2 增量（Map 覆盖层（方案 a，harmony flavor + AGC AppKey；默认 flavor 下 `IsOverlayAvailable=false`、调用不抛）/ LiveView 特性探测（TIMER；无权益 `IsSupported=false`、三调用 `Unavailable` 不抛）/ 壳 `start_app` AOT 启动桥（`aot=1`/`aot=0` 回退）/ 解释器实验（`<files>/interp.txt` → `DOTNET_InterpMode`））+ 判定点（Map show/hide/区域/标记/Ready/MarkerClick/CameraIdle、LiveView create/update/stop、AOT `aot=1`、interp `interp=3 source=file` + maps 无匿名 `r-x`、无 HMS 降级不抛、新 payload 首次运行）+ 并列资产（`aot-haps.tar.gz`、`ohos-interpreter-pack.tar.gz`、`harmony-haps.tar.gz`（harmony-flavor 5 变体，壳 263,784 B / `d3a7b718…`；**2026-09-28 MAPFIX 重切为 291,628 B / `a637a513…`（overlay 真编译）**；前置 = 重签材料 + AGC 权益，见判定卡 §2.5））+ 校验与取证明细、仍未验证边界；指纹：abc 264,136/18,532、导出 134/134、套件 334/floor 314；整包数字：tar 196,220,486 B / `091dcc56…`、树 `0a7a3215…`、sidecar `d7efd251…`、5 hap ~75.67 MB、bundle 30,525,614 B / `7d614517…`（入口 = release「## Integrity」，明细见本页文首指纹块） | 📦 快照（2026-09-28）|
| `2026-09-27-ohos-runtime-mode-determination.md` | **运行时模式判定卡（JIT / AOT / 解释器 / 渲染，2026-09-27）**：取件清单（kit #28 tar 196,220,486 B / `091dcc56…`、`aot-haps.tar.gz` 17,093,146 B / `91e1b9d3…`、`ohos-interpreter-pack.tar.gz` 2,419,988 B / `a10699b3…`、`harmony-haps.tar.gz` 196,898,796 B / `9b0506fa…`（harmony 5 变体，MAPFIX 重切后 overlay 真编译，AGC 前置），asset id 复核）；四态矩阵＋判定树（`probe: 1=`×`xwe` A/B、`aot=1`＋无 `The application to execute does not exist`、`interp=3 source=file`＋maps 无匿名 `r-x`、首帧/触摸/导航/列表+WebView 四项）；每态精确步骤（`xwe.txt`/`interp.txt` 命令模板）＋期望日志＋回传物；AOT 包已内置桥宿主（269,216 B / `bb51826e…`），开箱 `aot=1`；`tester-run.sh` **v12**（`xwe` 判定照旧；v9 起 `aot_route`/`interp_mode`、v10 起 `--mode-matrix` 四态一键、v11 起 `--a11y-probe`、v12 起 `runtime_mode`/`runtime-mode=` 行与 Run C `run_c_via=manifest`）；**kit #31 为当前发布**（新增 Blazor 段 + tester-run v13；#31 实测 tar 207,023,588/`f4325d2f…`、树 `52e77ee8…`、sidecar `7d0cba77…`、`SHA256SUMS` 16 项 / 1,410 B；#30 行（tar 196,992,264/`a781c25b…`）仅作对照；kit #28 行为历史 API 复核快照） | ✅ 当前（2026-09-29）|
| `2026-09-27-ohos-tester-handoff-kit27.md` | **kit #27 测试方交接（历史）**：kit #27 指纹（tar 195,951,029/树 `6abff90e`/hap ~75.56 MB/libs 269=14+254+marker/abc 245,412/宿主 265,120/130 导出契约/bundle 30,508,149）+ KIT-EXT2 增量（壳 Push/Account/Map 特性探测、宿主 12 个 kit sink（118→130）、FIX-R1-NAPI-6D 边界加固、FIX-R1-MARSHAL-OFF 反向条目 marshal off、交互 329/floor 309、payload-zip opt-out pack 同步）与判定点（无 HMS 降级不抛（Push token/Account 授权/Map 能力位）/新 payload 首次运行/权限弹窗/Share/Scan/AOT）；校验与取证步骤、仍未验证边界 | 📦 快照（2026-09-27）|
| `2026-09-26-ohos-tester-handoff-kit26.md` | **kit #26 测试方交接（历史）**：kit #26 指纹（tar 195,748,984/树 `2f247e40`/hap ~75.47 MB/libs 269=14+254+marker/abc 234,620/宿主 240,544/118 导出契约）+ 相对 #25 的三项增量（P2-INTEROP 全量 `LibraryImport` hosting、TASK-MIG 打包任务程序集化、PLAT-GAP 消费方缺省化）与判定点（新 payload 首次运行/原生桥 ABI/PLAT-GAP 恢复路径；kit #28 继续按此判读）| 📦 快照（2026-09-26）|
| `2026-09-25-ohos-tester-handoff-kit25.md` | **kit #25 测试方交接（历史）**：kit #25 指纹（tar 195,567,555/树 `9014b428`/hap ~75.43 MB/libs 269=14+254+marker/abc 234,620/宿主 240,544/118 导出契约）与相对 #24 的 5 项增量（权限链 `reason`/`usedScene`、Share/Scan 探测降级、AOT 启动路径、present 缓存与 targets 加固、打包数字）；判定点（权限弹窗文案/Share 面板/Scan 返回/AOT 启动，kit #26–#28 继续按此判读）| 📦 快照（2026-09-25）|
| `2026-09-24-ohos-tester-handoff-kit24.md` | **kit #24 测试方交接（历史）**：host 里程碑 + 6 项闭环（切片 `ohos-slice-1.0.1`、aot-packs release、NETSDK1203 修复、JIT A/B 与 exec-memory 探针、payload-in-libs、策略文档）；`probe:`×`xwe` 判定表（kit #25 沿用）、A/B 指令、NativeAOT 主路线指引 | 📦 快照（2026-09-24）|
| `2026-09-24-ohos-device-milestone.md` | **真机里程碑**：kit #17→#18 + 测试方 5 项本地修复后首次完整运行（`managed app hello-maui-app.dll started (UI shell)`）；结果与证据、根因链 5 项、我们侧回灌（commit 映射）、kit #22 指纹、仍未验证清单与 stock kit #22 复测判定点 | ✅ 里程碑（2026-09-24）|
| `2026-09-22-ohos-release-manifest.md` | OpenHarmony 交付物总清单（**已刷新至 kit #31**，2026-09-28 快照；tar 207,023,588/`f4325d2f…`、树 `52e77ee8…`、sidecar `7d0cba77…`、bundle 30,570,394/`43a78c8f…`（sdk-ohos 锚 `b2b79e27d9`））：kit 的 tar/树摘要（编号与数值以 release「## Integrity」为准）、release 资产（探针/tester-run.sh v13/Blazor 组件）、bundle、五仓库分支短哈希、校验三步、两条签名路径、SDK 门控与阅读入口 | ✅ 已刷新（2026-09-28，kit #31）|
| `2026-09-20-ohos-tester-quickstart.md` | 外部测试方一页版：下载校验 → 选 hap（4 自签 + 2 未签）→ 安装 → 先测 5 条 → 回传格式；含「自 kit #17 以来的变化」速览（至 kit #31，含 Blazor WASM/ArkWeb 组件/tester-run v13 `--blazor-probe`；#30 的 runtime-mode 开关/v12/MAPFIX）与设备里程碑提示 | ✅ 当前（kit #31，2026-09-29）|
| `2026-09-22-ohos-tester-runner.md` | 一条命令跑完一轮真机测试（`tester-run.sh` **v13**（**137,113 B / `2caa06bd…`**、asset **594519342**；v12 = 126,658 / `87763a3e…`），随 kit release 单独发布；v9 起 `aot=`/`interp=` 采集 + `aot_route`/`interp_mode`，v10 起 `--mode-matrix` 四态一键，v11 起 `--a11y-probe`，v12 起 `runtime_mode` + 清单 interp 的 Run C `run_c_via=manifest`、v13 起 `--blazor-probe`（Blazor 两标记））：本地校验 kit → 安装/启动/抓 hilog（含 applib/dlopen/execmem 路由/bootstrap 证据）→ 跑 P1–P4 → 打包回传；含 verify-kit 深度断言（#24 payload-in-libs、#25 期望值、#26 沿用、#27 abc 重锚 245,412、#28 再重锚 264,136、#29 重锚 281,052/20,916（#30/#31 沿用））与 v7–v13 新键判读；默认 dry-run、无设备拒绝执行 | ✅ 当前（v13，kit #31，2026-09-29）|
| `2026-09-27-ohos-accessibility-device-verification.md` | **无障碍真机验证清单（P0b-A11Y，2026-09-27）**：影子树逐项判定（Entry/Label/Button/CheckBox/Switch/Image/List/WebView(hybrid) + 模态/弹层焦点陷阱 + 滚动焦点保持 + 读屏开/关两态），每项「操作/期望（语义·朗读·角色·焦点·动作·几何）/证据/判据」；采集 = `tester-run.sh` **v13** `--a11y-probe`（v12 亦可）（设备 `uitest` 点 `A11Y` 自检 → `a11y/selfcheck.txt`＋`a11y/hilog-a11y.txt`，`summary a11y_*`；另含 `runtime_mode`）或文末手动命令与关键字表；已知边界（Image/自绘弹层/DOM 文本未发布）登记不判失败 | ✅ 当前（2026-09-28）|
| `2026-09-22-ohos-new-features-device-checklist.md` | 本轮新功能真机验证清单（M1–M13：权限/连通性/剪贴板/邮件短信拨号/截图/地理编码/窗口安全区/图像与单元格/无障碍/Shell 扩展 + 真实缺陷修复/UX 深化/rawfile 桥）：逐项「步骤/期望/证据」+ 探针 hap 与 `tester-run.sh` v13 用法（含 bootstrap/payload/execmem/矩阵/a11y/runtime_mode/kit 自检采集；kit #25–#30 未新增 UI 入口，§0.6 判定点（权限弹窗文案/Share 面板/Scan 返回/AOT 启动）+ §0.7 增量判定点（新 payload 首次运行/原生桥 ABI/PLAT-GAP 恢复路径）+ §0.8 kit #27 判定点（历史）+ §0.9 kit #28 判定点（历史）+ §0.10 kit #29 判定点（历史）+ §0.11 kit #30 判定点（runtime_mode/优先级/模式矩阵清单路线/MAPFIX Map 点亮）+ §0.12 kit #31 判定点（Blazor 组件/`--blazor-probe` 两标记/首屏/`/counter`））| ✅ 当前（kit #31，2026-09-29）|
| `2026-09-21-ohos-device-crash-diagnostics.md` | 启动崩溃分支（JsError / exit 254）：当前 kit（#31）重测与校验记录 + 最小 hilog/faultlog/status 取证 + §2.4 app-lib/别名/首帧 + §2.5 bootstrap/payload + §2.6 execmem 探针与 JIT 判定（v8+ 采集） + 四个 A/B + 回传清单；含 2026-09-24 设备证据修正与 kit #25–#31 更新 | ✅ 当前（kit #31，2026-09-29）|
| `2026-09-21-ohos-crash-probes.md` | 启动崩溃探针 P1–P4（壳 / 宿主 dlopen / 宿主入口 dlsym / 逐依赖）：五层定位决策表 + 免安装 14 库自检；四类历史分支均已在 kit #16/#17 前修复（其中 napi 记录名一路按无害加固保留），kit #31 为当前包（Blazor WASM/ArkWeb 组件 + tester-run v13 `--blazor-probe` + #30 的 MS-MODE runtime-mode 打包开关/tester-run v12/MAPFIX harmony 重切 + #29 R3 CoreSpeechKit TTS + HUKS-first SecureStorage + 自绘深度五连 + R2 Map 覆盖层 + LiveView 探测 + `start_app` AOT 桥 + 解释器实验 + #27 KIT-EXT2 Push/Account/Map 探测/134 导出 + #26 P2-INTEROP/TASK-MIG/PLAT-GAP + #25 权限链/Share-Scan/AOT + #24 payload-in-libs + execmem 采集）；4 个未签名 hap 挂在 `device-test-kit` release | ✅ 当前（kit #31，2026-09-29）|
| `2026-09-22-ohos-startup-crash-rootcause.md` | 启动崩溃根因（测试方证据链）：9568257 自签名被拒属预期；签后启动 `ReferenceError: Cannot find module '…EntryAbility'`（exit 254）= 壳 abc 入口 record 缺陷（E1–E5 + cc-switch 37 vs 1~2 + 华为 FAQ `useNormalizedOHMUrl=false`）；H1/H2 是硬化非本因；修复 = PA1 重建壳 abc；四个阻塞均已在 kit #10–#17 修复；**§5f = 2026-09-24 设备证据修正（旧 #4 降级为无害加固、kit #22 回灌；2026-09-29 更新至 kit #31）** | ✅ 当前（kit #31 注，2026-09-29）|
| `2026-09-21-ohos-device-report-template.md` | 下一轮真机回传一页模板（填补空白即可）：kit 身份/重签（含 p7b+p12+cer 预签路径）/安装/启动/§4b 验签/§4c app-lib 与首帧（含 bootstrap/payload/execmem 栏）/§4d kit #25 判定点/§4e kit #26 增量判定点/§4f kit #27 判定点（历史）/§4g kit #28 判定点（历史）/§4h kit #29 判定点（历史）/§4i kit #30 判定点（runtime_mode/优先级/模式矩阵清单路线/MAPFIX Map 点亮）/§4j kit #31 Blazor 判定点（`BLZ_*` 两标记/首屏/`/counter`/截图）/探针 P1–P4/附件清单，供机器解析归档；数字一律指向 release「## Integrity」与 `tester-run.sh` 摘要 | ✅ 当前（kit #31，2026-09-28）|
| `2026-09-19-ohos-hap-acceptance-for-testers.md` | 完整验收说明：交付物、安装、A1–K2 与 N1–N7 清单、日志关键字与 status 对照、回传模板（包内名 `验收说明.md`；kit #26 判定点、kit #27 KIT-EXT2 增量（历史）、kit #28 R2 增量（历史）、kit #29 R3 增量（历史）和 kit #30 MS-MODE 增量（runtime-mode 开关/tester-run v12/MAPFIX）与 kit #31 Blazor 段（§8i：`BLZ_BOOT`/`BLZ_RENDERED` 自动断言 + 首屏/`/counter` +1/截图）已同步（§8d–§8h），含权限链/Share-Scan 判定点与 payload-in-libs/execmem/矩阵/a11y 与强化 verify-kit 说明）| ✅ 当前（kit #31，preview.24）|
| `2026-09-21-ohos-device-run-playbook.md` | 真机运行操作手册：包内 `sh verify-kit.sh` 校验（#23 起深度断言、#24 加 payload-in-libs、#25 更新期望值、#26 沿用、#27 abc 重锚 245,412、#28 再重锚 264,136、#29 重锚 281,052/20,916（#30 沿用））→ 安装/启动 → hilog 取证（v8 含 execmem，v11 含矩阵/a11y，v12 含 runtime_mode）→ 5 条冒烟 → 9568344/E00C001 失败分支（含预签路径）与回传；含里程碑提示与 kit #25–#31 判定点（含 Blazor `--blazor-probe`） | ✅ 当前（kit #31，v13）|
| `2026-09-19-ohos-signing-and-udid-guide.md` | `9568344` 根因（调试 profile 绑定 UDID）与自助/代签重签流程；含华为自动签名材料代签（`scripts/sign-huawei.sh`，包内名 `签名与UDID指南.md`）| ✅ 当前（2026-09-21）|
| `2026-09-20-ohos-dotnet-getting-started.md` | 第三方开发者英文上手：安装 workload、选 TFM/publish hap、签名与 UDID、故障排查 | ✅ 当前（2026-09-20）|
| `2026-09-21-ohos-tester-selfsign.md` | 未签名 hap 自助签名（DevEco 自动签名 + hap-sign-tool）；包内名 `自签说明.md`；kit #22 起 `签名说明.txt` 的 PA1 历史句已随源修复（kit #31 包内文档修订以 release 说明为准；另含 Blazor `com.example.opendotnet` 条目） | ✅ 当前（kit #31，preview.24）|
| `2026-09-21-ohos-delivery-kit-readme.md` | kit 交付包总说明：基线 preview.24、6 hap 用途、安装与 9568344 指路（含预签路径）；包内名 `README-交付说明.md`；kit #31 已同步（Blazor WASM/ArkWeb 组件 + tester-run v13 `--blazor-probe`；#30 的 MS-MODE runtime-mode 打包开关/tester-run v12/MAPFIX harmony 重切 + #29 R3 CoreSpeechKit TTS/HUKS-first SecureStorage/自绘深度五连 + #28 R2 Map 覆盖层/LiveView/AOT 启动桥/解释器开关 + #27 KIT-EXT2 探测/134 导出/marshal-off + #26 P2-INTEROP/TASK-MIG/PLAT-GAP + #25 权限链/Share-Scan 判定点 + payload-in-libs + 强化 verify-kit（abc 281,052/20,916）+ v11 矩阵/a11y + v12 runtime_mode；并列资产 aot-haps/解释器/harmony haps） | ✅ 当前（kit #31，preview.24）|

## 当前状态与规划

| 文档 | 一句话 | 状态（最后更新）|
|---|---|---|
| `2026-09-28-ohos-terminal-verification.md` | **终态复核（kit #30，2026-09-28）**：五仓一致性 PASS（线性链、无强推）、bundle/锚 PASS（30,552,107 B / `c2b527d3…` 三处一致）、CI PASS（ohos-workload 5/5 + sdk-ohos 2/2）、安装器锚 PASS；发布后补记完成 —— kit 抽验与四处 `## Integrity` 全部 PASS（`reg-kit30/RELEASE-VALUES.txt` 120 行 0 PENDING）；含文档一致性复核与残余风险清单 | ✅ 已补齐（2026-09-28 发布后补记）|
| `2026-09-28-ohos-agc-store-readiness.md` | **AGC 商店上架准备（2026-09-28）**：元数据合规清单（名称/简介/关键词/分类/截图·视频·图标/隐私政策/隐私标签/支持设备/测试账号，逐项「需填·注意·常见拒审点」，口径 = `app-metadata-audit-skill`）+ 签名与 Profile（自签 9568257/9568344 属预期 → 华为调试 p12+cer+p7b+alias 与 UDID 预签走 RUNBOOK → 发布证书/Profile 与 AGC 指纹关联、受限 Profile 重签）+ 权限与隐私（27 类 MAUI 权限映射 → OH 权限 + 8 条 `$string:permission_reason_*` 中英模板与 usedScene + AGC 隐私标签/ACL 声明位置）+ App Linking（`skills[].uris` 清单声明与 P2c app.json `linkHosts` 协同）+ 提交前自检（运行时 10 项 + 元数据 10 项）；AGC 实际字段以控制台为准，App Linking/清单声明尚未真机验证 | ✅ 当前（2026-09-28）|
| `2026-09-28-ohos-upstream-fork-sync-playbook.md` | **上游同步 playbook（runtime fork，2026-09-28）**：`#132827` 合并后六步（fetch upstream → merge → 去重 **#134670**（`7408c77328c`，已上游）的 OperatingSystem/numa 切片＋#132827 同名 hunk → 构建/merge-tree 校验 → `pr/*`/`rehearse2/*` 基线重锚 → 记录）；`#132953` rerun 与 17 支落地顺序引 branch-map（① infra → ② N1–N5/N14 → ③ N7–N10 → ④ N11/N12 → ⑤ N13 → ⑥ N15 → ⑦ N16 → ⑧ C2/C3）；注明评论需许可、禁强推 | ✅ 当前（2026-09-28）|
| `2026-09-25-ohos-ms-hmos-compliance.md` | 四域 skill 合规审计与彻底修复报告（ArkTS · NAPI · 互操作/AOT · MSBuild）：30 条 = 违例 13 · 偏差 17 + 表外补录 PLAT-GAP；**已彻底修复 27（P2 收口 + PLAT-GAP = 26/30 + 1 补录）/ 域内排期 4（+2 SDK 基建，TASK-MIG 已入包）**；逐条 `文件:行`/规则依据/严重度/最小-最彻底修法/提交与验证数字（交互 326/floor 306、IL 告警 0、118/118 导出契约、P2 125 处 LibraryImport、selftest 全绿）、KIT-GAP/KIT-IMPL（5 条件可补齐/3 仅记录/6 维持门控）、外部条件与文档回填、R1–R11 交叉引用；kit #25 已发布，kit #26 收口 P2/PLAT-GAP/TASK-MIG，**kit #27 落 KIT-EXT2（Push/Account/Map 探测 + 130/130 导出 + marshal-off）** | ✅ 当前（2026-09-27 回填）|
| `2026-09-24-ohos-runtime-strategy.md` | 运行时策略（JIT 现实核查 → 四条路线）：平台策略/ACL 核实（`ALLOW_EXECUTABLE_FORT_MEMORY` 引用错位、对口权限限 2in1/受邀）、CoreCLR 解释器存在性与最小 spike、NativeAOT 主路线两走法、seccomp/补丁不采用、仍未验证项；**R1-INTERP spike 组件级已通过（2026-09-26：`libclrinterpreter.so` 268,320 B/sha256 `8bcb5734…`，stock coreclr 需 `-clrinterpreter` 重建，全量链接待 ICU/OpenSSL 交叉资产）** | ✅ 决议 + spike（2026-09-26）|
| `2026-09-24-ohos-kit-gap-analysis.md` | 鸿蒙 Kit 能力缺口复核（KIT-GAP）+ 三轮落地回填：KIT-IMPL（Share/Scan 探测降级、`ARKTS_SDK_FLAVOR=harmony`）、KIT-EXT2（Push/Account/Map 探测+降级、host 导出 118→130、错误码映射；**已随 kit #27 出包**）、R2-3（**Map 方案 (a) 覆盖层已落地**（harmony flavor + AppKey；默认 flavor 降级不抛）；**kit #28 出包**）、**A2-TTS（CoreSpeechKit 探测+五 op 链路已落地，默认 flavor 降级不抛；真朗读需 HMS 设备 + harmony 壳，AGC 清单第 13 行）**与 **P2a-HUKS（SecureStorage HUKS 优先，0 权限；无 HUKS 回退文件密钥）**；结论 7 项「已实现（特性探测）」、3 仅记录、5 维持门控；外部条件（HMS 设备/AGC/HarmonyOS SDK）未变，真机点亮仍待外部条件（kit #30 门禁 391/floor 371） | ✅ 当前（kit #30，2026-09-28）|
| `2026-09-23-ohos-pr-review-compliance.md` | 上游 PR 评审规则遵循报告：R1–R11 规则表（来源评论/约定）、三份只读审计（runtime / sdk+aspnet / workload+maui）的偏差/违例 → 修复提交 → 脚本化复审计证据（grep/sha256/json/diff/树哈希/远端 ref）、有意保留与结构性清单、待上游动作（arcade 合并 / rerun / 复评 / issue 三问）；结论：硬违例 0、R1–R11 全合规 | ✅ 当前（2026-09-23）|
| `2026-09-28-ohos-security-scan-3.md` | **新攻击面安全复查 #3（SEC-SCAN-3，2026-09-28）**：scan-2 后 5 波（kit #22–#31）的 6 个新面（P2c 深链 / ArkWeb rawfile 直供 / P2a HUKS 回退 / P2b 图片 / tester-run v13 probe / 权限声明）；6 缺陷已修 + 1 加固（深链状态行注入 + allow-list 竞态、SecureStorage 空键崩溃/并发丢更新/坏 base64、BLZ_ERROR 终端转义、.key/secure.dat 0600）+ 6 条报告未修（WebView 区路径段校验/安全头/标记伪造、权限一致性等，附 patch 草图）；harness 398 检查 / floor 376、selftest S21b 负例 | ✅ 当前（2026-09-28）|
| `2026-09-23-ohos-security-scan-2.md` | 五仓库安全扫描 #2（3+2 猎手 + 4 份独立 PoC 对抗）：16 条候选（A1–A3、MB-1–3、H-C1–3、D-1–6、sec-e C3），**16 条全部已修**（含 H-C3 绝对路径 dlopen + 静态链接开关、CLI 已编译验证、binary-sign-tool 可选 pin、tar 成员负测）；上轮 23 条复核 21 有效 / B5 改名 / B6→H-C2 已修；含逐条攻击路径、`文件:行` 证据、复现命令与残留风险 | 📦 历史（2026-09-23）|
| `2026-09-23-ohos-performance-scan.md` | 五仓库性能扫描 #2（宿主/原生 12 + 托管/UI/CI 19 个热点）：31 热点全部收口——扫描窗口 10 + 后置批次 16 + 最终回填 5（H10/P16/P9/P10/P19），**已修 29 · 残留 2**（Flatten 1144 B/帧属 Maui.Graphics、订阅 churn 有意保留）；帧分配 241,688→72,864→**4,504 B/帧**（门禁 13,824 B、CI 实测 3,720 B）、轮播 1759.7→441.2 ms、P12 读 **−82.9%**、P16 每轮少读 163.5 MB，门禁已加固（断言/jitter/缓存/PR/单一阈值） | ✅ 当前（2026-09-23）|
| `2026-09-23-ohos-napi-import-fix-playbook.md` | NAPI 导入形式修复作战手册（黑屏阻塞 #4）：问题复盘、候选修复 A（壳 import 形式，含精确 diff/重建/验证/入包发布链）/ B（`loadNativeModule` 动态加载）/ C（打包侧 pkgContextInfo 待研究落地），以及结果决策表与回滚步骤 | 🔄 待实验定形（2026-09-23）|
| `2026-09-22-ohos-render-route-decision.md` | 渲染路线决议（PJ4）：保持自绘合成器路线（单 XComponent + canvas + 自绘 IView/materializer + 影子无障碍树），不转原生 ArkUI 控件；附理由、混合路线与 UX 深度自实现清单（PJ1/PJ2 进行中，文本编辑/窗口 overlay/阴影未接） | ✅ 决议（2026-09-22）|
| `2026-09-22-ohos-elf-signing-research.md` | OHOS ELF 代码签名研究（PE1）：app 内 `.so` 的凭证是 HAP code signing block（`SoInfoSegment`，app 证书/Profile），不是文件内 `.codesign`；keyless self-sign（flags=0x10）只属独立二进制/PC 场景；新发现 payload 库不经 hap 签名、SDK 厂商 DevID 证书签名被我方重签为 keyless 两个问题；含工具矩阵、真机 kmsg/签名块检查命令与修复排序 | ✅ 当前（2026-09-22）|
| `2026-09-22-ohos-arkts-abc-version-history.md` | abc 版本史与 SDK 映射研究：version 字段/isa.yaml 对照、es2abc 与 `compatibleSdkVersion` 接线、可下载 SDK 清单、设备查询命令；结论：现有 SDK 26 工具链把 `compatibleSdkVersion` 设为 18–23 即产出设备可接受的 `13.0.1.0`（推荐 22 重建壳）| ✅ 当前（2026-09-22）|
| `2026-09-19-ohos-code-audit.md` | 主审计报告 §1–§37：五仓库代码/批次审计、真机前硬化、Blazor 与无障碍、S 系列（S1–S5）收官、T6/T8 补丁（要点见下节）| ✅ 当前主参考（2026-09-21）|
| `2026-09-22-ohos-maui-coverage-matrix.md` | MAUI on OpenHarmony 覆盖矩阵：切片/宿主/套件/演示只读审计——已实现、部分（附代码证据）、未实现、SDK 阻塞与 Top-10 缺口；2026-09-26 回填 §1c（Push/Account/Map 平台桥、Share Kit 多文件、NAPI 边界加固、marshal 迁移），2026-09-27 回填 §1d/§1e（文本编辑/动画/列表/图片/深链）、§2 HUKS 与文本编辑、§4 TTS 转已实现、§5 套件 391/floor 371（MS-MODE）、§7 解释器（构建/发布完成）；真机状态指向 kit #31 与设备里程碑 | ✅ 当前（kit #31 注，2026-09-29）|
| `2026-09-21-ohos-security-scan.md` | 五仓库安全扫描（A1–A8、B1–B7、C1–C8）：23 项全部解决（22 项修复 + B6 构造性修复）、另 16 个区域无发现；修复均未经真机验证 | ✅ 当前（2026-09-21）|
| `2026-09-19-ohos-arkts-handover-status.md` | 交接状态：主线与版本、架构批次（D1–D4）、无障碍配方、操作坑、阻塞与剩余队列 | ✅ 当前（2026-09-20）|
| `2026-09-16-ohos-platform-workload-plan.md` | 以 iOS 为参照的完整平台 workload 迁移规划（终态/pack 拆分/TFM/安装器）| 🔄 规划基线（W1–W22 已据此执行，2026-09-16）|
| `2026-09-18-ohos-arkts-essentials-bridge-plan.md` | ArkTS 桥接 Essentials 的集成模式与逐 API 落地管线 | 🔄 计划（2026-09-19）|
| `2026-09-18-ohos-secure-storage-huks-plan.md` | SecureStorage 改用 HUKS 硬件密钥库的改造计划（当前为 XOR 回退实现）| 🔄 计划（2026-09-18）|
| `2026-09-18-ohos-openharmony-api-proposal.md` | 上游 API 提案草稿（`OSPlatform.OpenHarmony`、`OperatingSystem.IsOpenHarmony` 等）| 🔄 草稿待上游评审（2026-09-18）|
| `2026-09-18-ohos-device-validation-checklist.md` | 设备侧验证清单（英文）：每一步含命令与可观察结果；已更新到 kit #31（2026-09-28，Blazor WASM/ArkWeb 组件 + tester-run v13 `--blazor-probe` + #30 的 MS-MODE runtime-mode 打包开关/tester-run v12/MAPFIX harmony 重切 + #29 R3 CoreSpeechKit TTS/HUKS-first SecureStorage/自绘深度五连 + R2 Map 覆盖层/LiveView 探测/AOT 启动桥/解释器实验 + KIT-EXT2 Push/Account/Map 无 HMS 降级不抛；P2-INTEROP/TASK-MIG/PLAT-GAP 沿用 #26、权限链/Share-Scan/AOT 判定点沿用 #25；verify-kit abc 期望 281,052/20,916；数字指向 release「## Integrity」；含里程碑 §6 判定点与 v12 采集字段）| ⏳ 待设备（stock kit #22 起复测；里程碑已达成于 kit #18 + 本地修复）|

## 主审计报告要点（`2026-09-19-ohos-code-audit.md`，§1–§37）

- **§1–§5**：探针通过项、本轮修复与建议项落地、对照上游 MAUI / 鸿蒙 Kit 的再次盘点。
- **§6–§13**：工作流 A–G 结果与不确定项（传感器精度、Launcher/Browser/Share、桌面菜单、拖放、触感+主题、ArkWeb JS 桥 + HybridWebView）。
- **§14–§19**：§8 刷新链修正；日历+联系人（H）；权限注入 + HybridWebView 资源服务；`__hwvInvokeDotNet` JS→.NET 闭环与 BlazorWebView 就绪评估。
- **§20–§22**：蓝牙发现/电池/显示/无障碍节点探测（191 项）；无障碍附着修复（host-only）；壳侧风险消除 K-1（14 个 sink 改走 `napi_threadsafe_function`）。
- **§23–§25**：多目标与 API 波段（20.0 → min=target=`60000020`/`Release`；26.0 → `60001021`/`60101024`/`Beta1`）；交付资产 + 版本横幅 + 蓝牙去重 + Blazor 里程碑 1；真机前硬化 Q1–Q3（`.codesign` 漂移根因与确定性打包）。
- **§26**：Q4/Q5 收官——交互回归套件纳入 CI 门禁、确定性 fuzz、上手文档交付。
- **§27–§28**：BlazorWebView 里程碑 2/3——native 模型（非 WASM）；Hap 资产管线与 ArkTS bootstrap 落地；托管 `WebViewManager`/handler 注册（2b）与真机验证待做。
- **§29–§31**：无障碍 provider R2/R2b（方向焦点、editable/checkable、16 参发布契约、range/checked 缺口）与 R3 文档级盘点（DevEco CLT 缺 hvigor、设备访问被策略拦截）。
- **§32–§34**：上游门控收尾项（R7，三分支/补丁就绪）；S3 手电筒（Camera Kit torch 跨三仓）与 S4 分享文件（`sendData` Want + `FLAG_AUTH_READ_URI_PERMISSION`）。
- **§35**：S 系列收官（S1 Blazor 管理器 · S2 无障碍节点数/分组层级 · S3 手电筒 · S4 文件分享 · S5 preview.24 刷新）：workload 1.0.0-preview.24、
  bundle/滚动 release/device-test-kit 重发（4 已签 + 1 未签 hap）、harness 208 条与真机前不确定项。
- **§36**：静态 Web 资产指纹回退与响应缓存头（shell T6）：hybrid/Blazor 共用负载路径按 `name.<hash>.ext → name.ext` 只回退一次；
  指纹请求 `immutable`、其余 `no-cache`；ArkTS 探查证明对象字面量 header map 可编译（被拒的是 `RegExpMatchArray` 显式标注）。
- **§37**：`DeviceDisplay.KeepScreenOn` 跨三仓（T8）：托管 `ohos_host_keep_screen_on` → 宿主单向 sink → 壳
  `window.getLastWindow` + `setWindowKeepScreenOn`；类型检查与 216 条 harness 断言通过，真机常亮行为待验证。

## 运行时 / SDK 上游移植阶段（历史：2026-08-13 → 2026-09-15）

> 记录 dotnet/runtime、sdk、aspnetcore 上游化过程中已完成的工作与决策（RID 命名、syscall、版本对齐、PR 拆分等）；当前状态以审计报告与交接文档为准。

| 文档 | 一句话 | 状态（最后更新）|
|---|---|---|
| `2026-08-13-ohos-cross-compile.md` | 路线②交叉编译 dotnet/runtime 执行计划（仿 linux-bionic NDK；执行纪律/问题循环）| 📦 历史（2026-09-01）|
| `2026-08-27-ohos-upstream-pr-prep.md` | 上游 PR 准备：`linux-ohos` RID 范围与全量交叉构建验证 | 📦 历史（2026-08-31）|
| `2026-08-28-ohos-pr-plan-post-132827.md` | PR#132827 之后剩余 3 个 PR 的拆分、29 文件清单与依赖 | 📦 历史（2026-08-31）|
| `2026-08-28-ohos-pr-plan-revised.md` | NativeAOT E2E 后修订的 runtime+SDK PR 计划（含评审反馈）| 📦 历史（2026-09-14）|
| `2026-09-01-ohos-ondevice-verification.md` | runtime/sdk/aspnetcore 真机验证（交叉构建产物 + NativeAOT）| 📦 历史（2026-09-02）|
| `2026-09-01-ohos-syscall-audit.md` | `TARGET_LINUX` / `__NR_*` 系统调用审计（回答评审问题）| 📦 历史（2026-09-16）|
| `2026-09-02-cxx-runtime-handoff.md` | cxx-runtime 第三轮重建/重发交接（ilc 缺库往返）| 📦 历史（2026-09-06）|
| `2026-09-03-nativeaot-platform-analysis.md` | NativeAOT 平台分流机制分析（macOS / linux-musl / OpenHarmony 独立旁支）| 📦 历史（2026-09-03）|
| `2026-09-03-ohos-openharmony-rename-impact.md` | RID 改名 `ohos` → `openharmony` 的影响分析与决策过程 | 📦 历史（2026-09-13）|
| `2026-09-03-ohos-pr-inclusion-audit.md` | 上游 PR 文件纳入审计（不得进入 PR 的文件清单）| 📦 历史（2026-09-04）|
| `2026-09-04-26451-109-device-verify.md` | 26451.109 pure-IL CoreLib 真机验证 | 📦 历史（2026-09-05）|
| `2026-09-04-openharmony-rename-build-verify.md` | 改名分支的构建侧验证清单 | 📦 历史（2026-09-04）|
| `2026-09-05-26451-109-fresh-install.md` | 全新安装 SDK 验证与 console 回归阻塞记录 | 📦 历史（2026-09-06）|
| `2026-09-06-porting-code-compliance-audit.md` | 移植代码规范合规审计（对照上游 conventions）| 📦 历史（2026-09-16）|
| `2026-09-06-version-alignment-darc-vmr.md` | 版本对齐策略（darc/VMR 研究 + 手工 fork 方案）| 📦 历史（2026-09-06）|
| `2026-09-07-ohos-pr-plan-bsd-haiku-model.md` | 按 BSD/Haiku 落地模型重排的上游 PR 计划 | 📦 历史（2026-09-16）|
| `2026-09-15-ohos-platform-identity.md` | 平台身份决策记录（`IsOSPlatform("openharmony")` 语义）| 📦 决议（2026-09-15）|
| `2026-09-16-maui-ohos-feasibility.md` | MAUI → OpenHarmony 可行性分析（Tizen 先例、UI 层工作量）| 📦 历史（2026-09-16）|
| `2026-09-16-maui-ohos-p0.md` | 应用内 host 探针 P0（设备节点可达 + ArkUI NDK 节点创建）| 📦 历史（2026-09-16）|

## workload 工作项 W 系列快照（历史：2026-09-16 → 2026-09-18）

> W1–W22 逐工作项的交付记录（无 W4 文档）；后续演进与真机结论见主审计报告、交接状态。

| 文档 | 一句话 | 状态（最后更新）|
|---|---|---|
| `2026-09-16-ohos-workload-w1-status.md` | 本地 DevEco-less workload 骨架（Sdk/Ref/Runtime pack + manifest）| 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w2-status.md` | 原生宿主 + ArkTS 壳 + `publish → hap` 管线 | 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w3-status.md` | 壳↔托管打通（生命周期/宿主路径/NodeContent 通道 + ELF 签名）| 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w5-status.md` | workload 可安装（本地 feed）+ MAUI 自动检测闭环 | 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w6-status.md` | workload 打包为可交付 bundle 并接入 SDK 安装/构建流 | 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w7-status.md` | 发布通道（版本化 + 滚动 `workload-latest`）与安装器加固 | 📦 快照（2026-09-16）|
| `2026-09-16-ohos-workload-w8-status.md` | 官方 ArkTS 工具链（hvigor，无需 DevEco）构建 UI 壳 | 📦 快照（2026-09-17）|
| `2026-09-16-ohos-workload-w9-status.md` | 渲染表面握手：ArkUI `XComponent` 到达托管 | 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w10-status.md` | W9 收尾（预构建 UI 壳随包等）+ W10 渲染器点亮（首帧/宿主填面 API）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w11-status.md` | XComponent 表面上的渲染器路径（`native_drawing` 画布）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w12-status.md` | `Microsoft.Maui.Graphics` 画布后端 | 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w13-status.md` | `ICanvas` 语义补全（近似/no-op → 真实实现）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w14-status.md` | 渐变与阴影（清除最后的绘图 no-op）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w15-status.md` | 输入与帧 tick 钩子 + Graphics 视图树 demo | 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w16-status.md` | pattern paints（最后的 `ICanvas` 缺口）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w17-status.md` | MAUI 双轨启动：平台切片 A + 可真机验证 demo B | 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w18-status.md` | 首批真实 MAUI handlers 与合成器 | 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w19-status.md` | 真实 MAUI 应用接入平台契约（应用宿主）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w20-status.md` | 真实 MAUI 应用打包为可安装 hap（`test/hello-maui-app`）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w21-status.md` | window handler 完成 + 控件面扩展（headless 验证）| 📦 快照（2026-09-17）|
| `2026-09-17-ohos-workload-w22-status.md` | 最大一批：Entry 输入、值控件/导航/动画/Picker/Shell/虚拟化、Essentials、像素 harness 与缺陷定位（W22-1…-28）| 📦 快照（2026-09-18）|
