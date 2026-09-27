# 测试方交接：kit #29、R3（CoreSpeechKit TTS / HUKS-first SecureStorage / tester-run v11 / devloop / 文本编辑·动画·列表·图片·深链）判定点（2026-09-28）

> 运行时模式判定（JIT/AOT/解释器/渲染四态）：取件清单、判定树与每态步骤/期望/回传见
> `2026-09-27-ohos-runtime-mode-determination.md`（`tester-run.sh` **v11** 的 `--mode-matrix` 一键矩阵 +
> `--a11y-probe` 无障碍采集）；无障碍逐项判据见 `2026-09-27-ohos-accessibility-device-verification.md`。

> 承接 kit #28 交接（`2026-09-26-ohos-tester-handoff-kit28.md`）：R2（Map 覆盖层 / LiveView 特性探测 /
> 壳 `start_app` AOT 启动桥 / 解释器实验）与 #27 的 KIT-EXT2（Push/Account/Map 探测、134 导出、marshal-off）、
> #26 的 P2-INTEROP/TASK-MIG/PLAT-GAP、#25 的权限链/Share/Scan/AOT 判定点**继续有效**（本文 §2 给出口径）；
> JIT A/B 指令与 `probe:`×`xwe` 判定表（kit #24 交接 §3–§5）**一字未改**。本文只覆盖 #29 的增量与判定点。
> 结论先行：kit #29 = **R3 批** —— ① **CoreSpeechKit TTS（A2-TTS）**：壳 `canIUse('SystemCapability.AI.TextToSpeech')`
> + 变量说明符 `@kit.CoreSpeechKit` 双门，`registerTtsSink` 五 op（0 create / 1 speak / 2 stop / 3 locales /
> 4 isBusy），宿主 `ohos_host_tts_{available,request,register_result,result}`（旧单 op `ohos_host_tts_speak` 移除）；
> 托管 `OpenHarmonyTextToSpeech`（`SpeakAsync` 等朗读完成才返回 / `GetLocalesAsync` / `Stop` / `IsSupported`）；
> **无 Kit 或非 HMS 设备时 sink 不注册、调用直接返回/no-op、不抛**。真机朗读需 **HMS 设备 + harmony 壳**
> （`ARKTS_SDK_FLAVOR=harmony`；Kit 本身无 AGC 权益/权限门槛 —— AGC 清单第 13 行 = TTS、门槛是设备语音能力
> 与离线音色数据，`hms/ets` 证据 = `@hms.ai.textToSpeech`，syscap since 4.1.0(11)；harmony 分支编译证据
> ui abc **273,932 B / `e7290ed1…`**、0 ArkTS 错误）。
> ② **HUKS-first SecureStorage（P2a-HUKS）**：宿主原生 AES-256-GCM 引擎（`host_keystore.c`，`libhuks_ndk.z.so`
> 经 dlopen 按需解析）生成并持有**设备绑定**密钥，密文 `k1:<nonce‖ct‖tag>` 落盘，别名
> `maui.ohos.securestorage.v1.<path-hash>`，**不需要任何权限/权益**（`generateKeyItem`/`initSession`/`finishSession`/
> `deleteKeyItem` 均 app-scoped）；无 HUKS/操作失败时回退每安装文件密钥并**如实标注非硬件后备**
> （`IsHardwareBacked` 来自 `ohos_host_keystore_available` 探测），`RemoveAll` 同时清 key。
> ③ **tester-run v11**（119,452 B / `2355e493…`，`script_version=11 (2026-09-27)`）：`--mode-matrix`
> （JIT stock / `xwe.txt` A/B / 解释器 / AOT 四 Run，失败不中断，汇总 `mode-matrix/summary.txt` 含逐 Run
> 安装/启动/probe_1/xwe/首帧/崩溃/报告 tar + `conclusion` 建议行）与 `--a11y-probe`（设备 `uitest` 点按
> 左下角 `A11Y` 自检，读回 `accessibilityStatus`/`accessibilityNodeCount`，归档 `a11y/selfcheck.txt` +
> `a11y/hilog-a11y.txt`，`summary` 增 `a11y_*` 键；采集缺失容忍，不算失败）。
> ④ **devloop（一键增量开发闭环）**：`ohos-workload/scripts/devloop.sh` v1（28,582 B / `7491d0c3…`，
> 2026-09-27）build → (sign) → install → start → logs 一条命令（+ `--watch` 轮询改源重跑、`--follow` 跟随
> hilog），**替代被设备策略挡住 Hot Reload**；测试方按交付方指示取用（开发侧工具，不作为判定点）。
> ⑤ **自绘深度五连**：文本编辑（光标闪烁 500 ms / 选区手柄拖拽 / IME 组合预编辑）、动画（页面转场 /
> 控件状态 / 共享元素 `shared:` / 减少动效）、列表（增量加载 / `ScrollTo` / 分组折叠 / 滚动物理）、
> 图片（低清先出 → 高清替换；解码位图最多约 43× 小）、深链（冷启动 `onCreate` want 经 `notifyActivation`
> 在 `startApp` 前入队回放 + 热激活 `onNewWant` 去重/有序）。
> 指纹（kit #29 实测）：ui/shell abc **281,052 B** / `5c06143a…`（headless **20,916 B** / `54a1a201…`；
> PANDA `13.0.1.0`）、宿主导出契约 **134/134 → 143/143**、交互套件 **387/floor 367**
> （时间线：kit11–kit13 TTS → kit14 HUKS → P0c/P1a/P1b/P2b/P2c 自绘深度五连；各批历史值见
> `2026-09-22-ohos-maui-coverage-matrix.md` §5）。
> **kit #29（数字入口见 release Integrity）**：整包 tar/树摘要/sidecar 与 5 hap 大小/哈希以 release 说明
> 「## Integrity」与随包 `SHA256SUMS` 为准（tar 大小/树摘要见 `2026-09-22-ohos-release-manifest.md` 与
> release 说明；重签、预签或重新打包后的哈希必然不同）。包内 `verify-kit.sh` 的 abc 期望随本包重锚
> （#28 = `264136`/`18532`；本包预期 **`281052`/`20916`**），用 #28 的旧值校验本包会 FAIL —— 属脚本预期。

## 0. AGC 最小点亮顺序（harmony 变体；按最小依赖排序）

> 目的：以最少 AGC 操作点亮最多判定点；① 未完成时 ②–⑤ 都会因包名/签名指纹不一致失败（如 `1000900010`）。
> 全流程还需 harmony 壳（`harmony-haps.tar.gz`；2026-09-28 MAPFIX 重切：abc 291,628 B/`a637a513…`，overlay 真编译 ——
> 旧 A1 件 abc 263,784 B/`d3a7b718…` 无 overlay 模块记录、bit1 恒 0）与测试方自备重签材料
> （自签会被 9568257/9568344 拒绝，属预期）。

1. **① App + 签名证书指纹 + Profile（必须先有）**：AGC 创建应用（bundleName `com.example.hellomauiapp`）→ 登记测试方签名证书指纹 → 下载绑定 UDID 的调试 Profile（p7b）随重签使用。
2. **② Map AppKey（可最先验证 harmony overlay）**：AGC 开通地图服务并为该应用配置 AppKey（与 ① 指纹一致）→ 装 harmony hap（MAPFIX 重切件：abc 含 `entry/ets/map/MapOverlay` 模块记录 + `mapOverlayView`/`markerClick`/`cameraIdle` 符号；旧 A1 件缺记录、`IsOverlayAvailable` 不可能为 true）：`IsOverlayAvailable=true`（flags bit1）、地图视图出现、`Ready` 事件可达；无 AppKey 时 overlay 调用降级不抛。
3. **③ Push 权益**：AGC 开通推送 + 含推送权益的 Profile → `GetTokenAsync()` 返回 token（失败按 `1000900010`/`1000900012` 排查）。
4. **④ LiveView 开关**：AGC 申请实况窗 TIMER 权益 + 设备实况窗开关打开 → create/update/stop 出卡片（开关关 `-3`/`1003500004`、权益未批 `1003500005`）。
5. **⑤ Account scope**：AGC 申请 `quickLoginAnonymousPhone` scope 审批 → 授权返回匿名手机号＋`authorizationCode`（未批按 `1001502014`/`1001500001` 排查）。
6. **⑥ TTS（无需权益/权限）**：CoreSpeechKit 无 AGC 门槛；只需 HMS 设备＋harmony 壳，门 = 设备语音能力/离线音色数据（AGC 清单第 13 行）。

## 1. kit #29 相对 #28 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1 | **CoreSpeechKit TTS（A2-TTS，R3）**：壳 `probeTtsKit`（`canIUse('SystemCapability.AI.TextToSpeech')` + 变量说明符 `@kit.CoreSpeechKit` 双门）+ `registerTtsSink` 五 op（引擎惰性创建 person 0/离线 1，speak 在完成/停止/报错时应答，stop 清算挂起请求）；宿主 `ohos_host_tts_{available,request,register_result,result}`（旧的单 op `ohos_host_tts_speak` 移除，导出契约 134 → 136）；托管 `OpenHarmonyTextToSpeech` 补齐 `SpeakAsync`（等待朗读完成）/`GetLocalesAsync`（引擎音色 → MAUI `Locale`）/`Stop()`/`IsSupported` | 默认 flavor：`IsSupported=false`、`SpeakAsync` 直接返回、`Stop` no-op、locales 回退设备 locale，**全链路不抛**；harmony 壳 + HMS 设备：真实朗读、停止、语言列表（错误码 `1002300001/2/3/5`、`401` 透传为可读状态） | **TTS**（§2；无入口登记「未测（本包无入口）」，不要判失败） |
| 2 | **HUKS-first SecureStorage（P2a-HUKS）**：host 原生 AES-256-GCM 引擎（`libhuks_ndk.z.so` dlopen 探测；`HUKS_TAG_NONCE`/`HUKS_TAG_AE_TAG`），设备绑定密钥由 HUKS 持有；别名按 store 命名空间；`k1:` 畸形读取视为不存在 | 默认 flavor/headless 均可走 HUKS（in-process，不依赖 ArkTS 页）；无库设备回退文件密钥且 `IsHardwareBacked=false`（诚实文案）；`RemoveAll` 后旧密文不可解 | **HUKS**（§2：重启读回 / 换设备不可解 / 删除清 key / 回退如实） |
| 3 | **tester-run v11（`--mode-matrix` + `--a11y-probe`）**：v10 起四 Run 矩阵（A JIT stock / B `xwe.txt=1` A/B / C 解释器（`--interp-pack`/`--interp-hap`）/ D AOT（`--aot-haps`）），v11 加无障碍自检采集；失败不中断其余 Run | 一条命令拿到 `mode-matrix/summary.txt`（逐 Run 键 + `conclusion`）；无障碍专项拿到 `a11y/selfcheck.txt` + `a11y/hilog-a11y.txt`（`summary a11y_*`） | **模式矩阵 / a11y**（§2；判定树见判定卡与 a11y 清单） |
| 4 | **devloop 一键增量部署（开发侧）**：`devloop.sh` build/sign/install/start/logs（+ `--watch`/`--follow`）；外部签名转调 `sign-for-device.sh --external`（口令不走 argv） | 开发者在无 Hot Reload 的设备策略下仍可一条命令重发布并看日志；bundleName 白名单校验、无设备拒绝执行（退出码 3） | 按交付方指示取用（非设备判定点） |
| 5 | **文本编辑深度（P0c-TEXT-EDIT）**：光标=字符宽度前缀和 + 500 ms 闪烁节拍 + 焦点门；选区高亮 + 两个圆手柄（半径 9 px、命中 24 px slop，只移动被抓端）；IME 组合预编辑（壳 `PreviewText` → `host.notifyTextComposition` → `ohos_host_register_text_composition`，提交推进光标）；托管光标经 `ohos_host_keyboard_set_caret` 同步；`Editor` 补齐 `CursorPosition`/`SelectionLength`（导出契约 136 → 139） | 演示页 Entry/Editor：光标闪、可拖动选择、拼音/预编辑串在画布上高亮+下划线，提交后正确上屏；无组合导出时如实降级（无预编辑、不抛） | **文本编辑**（§2；IME 节拍与隐藏输入框组合需真机确认） |
| 6 | **动画与转场深度（P1a-ANIM）**：push/pop 新页进场（不透明度 0→自身 + 水平轻位移，页宽 5% 上限 48 px；`DurationMs 180`/`CubicOut`/`SlideFactor` 可配）；控件状态（Switch 旋钮+轨道插值、CheckBox 对勾 draw-on、按压反馈）；共享元素（`AutomationId` 前缀 `shared:`，位置+等比缩放+不透明度 morph）；减少动效（`AccessibilityKit` API 23 惰性导入双门 → `host.notifyAnimationReduce` → `OpenHarmonyMotion.ReduceMotion`：转场跳过、控件 snap、ticker 停）（导出契约 139 → 141） | 导航 push/pop 有进场动画；Switch/CheckBox/按压有状态动画；减少动效打开后动画跳过（系统设置可见）；无 `AccessibilityKit` 时按默认动效 | **动画/减少动效**（§2；真机需确认系统设置开关生效） |
| 7 | **列表深度与滚动物理（P1b-LIST；全托管，壳/host 零改动）**：增量加载（`RemainingItemsThresholdReached` 单次触发+重武装）；`ItemsUpdatingScrollMode` 三模式按条目身份锚定；`ScrollTo(index, group, position, animate)` 全参数（已可见项不动、折叠组自动展开、160–420 ms ease-out）；组头/组尾 + `SetGroupCollapsed`/`ToggleGroupCollapsed`（换源/投影变化重排防泄漏）；滚动物理（越界橡皮筋 64 px、回弹、有界过冲、滚动条 hold/fade）；1,200 条窗口 13–22 行、稳态 ≤1 KiB/帧 | 长列表滚动到底自动增量加载（不重复触发）；`ScrollTo` 定位/动画；点组头折叠/展开不跳变；拖拽越界有阻尼回弹；滚动条自动隐藏 | **列表**（§2：入口为演示长列表/探针页；无入口登记「未测」） |
| 8 | **图片解码深度（P2b-IMG）**：低清先出（目标长边 ≥128 px 时首帧按目标/8 预览并请求重绘）→ 下一帧按显示尺寸解码替换；pixelmap 缓存键 = 内容哈希+长度+请求尺寸（LRU 8 项/32 MiB）；单边 clamp 4096（`OH_DecodingOptions_SetDesiredSize`，API 12+，走可选库 shim）；失败画占位一次不逐帧重试；旧 host 回退全尺寸解码（导出契约 141 不变） | 大图先出低清、随后变清晰（≤1 帧差，窗口 resize 命中一次）；解码位图显著变小（本机 bench：4.77 MB 4000×3000 源 1080×810 目标：48.0 MB → 3.5 MB；3.27 MB 3400×2550 源 1032×200：34.7 MB → 0.8 MB）；失败不逐帧重试 | **图片**（§2；需演示页/探针页有大图入口） |
| 9 | **深链与激活（P2c-DEEPLINK）**：冷启动 `onCreate` 捕获 want → `bootstrap` 在 `startApp` **前** `host.notifyActivation`（uri/action/parameters/linkHosts/sequence）→ 宿主注册前按序入队（上限 8、丢最旧）并在注册时回放；热激活 `onNewWant` 同通道（sequence 去重/过期丢弃）；路由 `app://host/path` → `//host/path`、白名单 `https://` = 打包 `OpenHarmonyAppLinkHosts` → app.json `linkHosts`；无 Shell 时已注册路由走 `NavigationPage.PushAsync`，未知路由记状态不抛；Shell 路径过 `GoToAsync`（`Navigating` 可取消、绝不半应用）（导出契约 141 → 143） | 从浏览器/其他应用唤起：冷启动直达目标页、已运行时热激活换页且不重复；未注册路由不崩、有状态记录 | **深链**（§2；`module.json5` 的 `skills[].uris` 清单声明与系统投递为设备后续项） |
| 10 | **门禁与重建**：ui/shell abc 重编 **281,052 B**（headless 20,916 B；三个 preview pack 同源）、导出契约 **143/143**、交互套件 **387/floor 367**（kit11–kit13 TTS、kit14 HUKS，P0c/P1a/P1b/P2b/P2c 各批叠加；`[suite] checks=387 total=387 floor=367 assert=True`）；`verify-kit.sh` abc 期望重锚 `281052`/`20916`；`tester-run.sh` 升 **v11**（119,452 B）；并列资产沿用 `aot-haps.tar.gz` / `ohos-interpreter-pack.tar.gz` / `harmony-haps.tar.gz`（以 release 实际资产为准；**harmony-haps 于 kit 发布后 MAPFIX 重切**：overlay 真编译，abc 291,628 B/`a637a513…`、tar 196,898,796 B/`9b0506fa…`、逐 hap 断言 102/102，CI 门 `HARMONY_REQUIRE_MAP_OVERLAY=1` 由 WARN 转绿 —— 旧 A1 件 abc 263,784/`d3a7b718…` 无 `entry/ets/map/MapOverlay` 模块记录） | 校验步骤、证据字段与 #28 相同，**只换 abc 期望值（281,052/20,916）与脚本版本（v11）**；用 #28 的 `264136` 或更旧值校验本包会 FAIL（脚本预期） | 校验时以 release「## Integrity」与包内 `verify-kit.sh` 为准 |

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **TTS 降级不抛**（默认 flavor，首要判定） | 在 kit #29 的 5 个 hap 上触发 TextToSpeech 入口/自检 | `IsSupported=false`；`SpeakAsync` 直接返回、`Stop` no-op、`GetLocalesAsync` 回退设备 locale；**无异常、无崩溃** | 启动两行日志 + 状态原文 + hilog；无入口登记「未测（本包无入口）」 |
| **TTS speak / stop / locales**（HMS 设备 + harmony 壳，可选） | 用 harmony 壳重签安装 → `SpeakAsync("你好", …)` / 朗读中 `Stop()` / `GetLocalesAsync()` | 实际发声且 `SpeakAsync` 在朗读完成时才返回；`Stop` 立即静音且挂起请求完成、不触发桥超时；locales = 引擎音色集合（如 `zh-CN`/`en-US`）；不支持时 `1002300002/1002300003`、引擎失败 `1002300005`，不抛 | 调用→返回计时 + hilog 原文 + locales 列表 + 截图（判定卡见 `2026-09-24-ohos-kit-gap-analysis.md` §6） |
| **HUKS 重启读回** | 标准 `SecureStorage.SetAsync` 写入 → 杀进程/重启设备 → `GetAsync` 读回 | 值读回成功；密文为 `k1:` 前缀；`IsHardwareBacked=true`（设备有 `libhuks_ndk.z.so` 时） | hilog（keystore 路径）+ 读回值 + status |
| **HUKS 换设备不可解** | 同一 bundle 在另一台设备安装/或另一 store 别名读取同一密文 | 逻辑上不可解（密钥设备绑定）；错误不是静默明文回退 —— 记状态并在可用时重建 | 两设备日志 + 错误原文；无第二台设备时登记「未做」 |
| **HUKS 删除清 key** | `SecureStorage.RemoveAll()` → 重读旧键 / 再写入 | 旧值不可解；再次写入生成新 key 正常；别名已删除（`deleteKeyItem` best effort） | 操作前后 `GetAsync` 结果 + hilog |
| **HUKS 回退如实** | 无 HUKS 库/headless/旧设备路径 | 回退每安装文件密钥；`IsHardwareBacked=false`；文档/状态明确标注**非硬件后备**（不得宣传为硬件加密） | 状态原文 + 说明文案 |
| **模式矩阵（v11 `--mode-matrix`）** | `sh tester-run.sh --mode-matrix --kit-tar <kit> --aot-haps <aot> --interp-pack <interp> --capture 60` | 四 Run 不中断；`summary.txt` 逐 Run 键完整；`conclusion` 给出建议（JIT 直起 / 需 `xwe=1` / 解释器 3(file) / AOT aot=1）；失败 Run 保留报告 tar | `mode-matrix/summary.txt` + 四个 `tester-report-*.tar.gz`（判定树见 `2026-09-27-ohos-runtime-mode-determination.md`） |
| **无障碍采集（v11 `--a11y-probe`）** | 与 `--install --start --capture` 同用；设备有 `uitest` 与 `python3` | `a11y/selfcheck.txt` 读回 `accessibilityStatus: 1` 与正整数 `accessibilityNodeCount`；`a11y/hilog-a11y.txt` 归档无障碍行；缺失只记 `a11y_selfcheck`，不算失败 | `a11y/` 两文件 + `summary a11y_*`（逐项判据见 `2026-09-27-ohos-accessibility-device-verification.md`） |
| **文本编辑** | 演示页 Entry/Editor：聚焦打字/拖动选择/中文拼音预编辑 | 光标闪烁且随输入前进；选区高亮 + 手柄可拖动、只动被抓端；预编辑串高亮+下划线、提交上屏后光标推进；隐藏输入框组合是已知真机待确认项 | 录屏 + hilog（无抛错） |
| **动画/减少动效** | 导航 push/pop、Switch/CheckBox 切换、按压；打开系统「减少动效」后重复 | push/pop 有进场动画、状态切换平滑；开关打开后转场跳过、控件 snap、无残留半透明/错位；无 `AccessibilityKit` 时默认动效 | 录屏（开/关两态）+ 首帧/导航日志 |
| **列表** | 长列表滚动到底、`ScrollTo`、点组头折叠/展开、快速拖拽越界 | 增量加载只触发一次/不重复；`ScrollTo` 定位（含动画）正确；折叠不跳变；越界有 64 px 阻尼回弹；滚动条 hold/fade | 录屏 + 关键状态日志；无入口登记「未测（本包无入口）」 |
| **图片** | 演示/探针页加载大图 | 首帧低清、随后变清晰；窗口 resize 后重解码一次；坏图只画占位一次不逐帧重试；无解码抛错 | 录屏 + 进程内存对比（可选 `hidumper`） |
| **深链（冷启动）** | 从浏览器/`aa start` 带 uri 冷启动 | 直达 `app://host/path` 目标页；启动日志可见 activation（不丢、不与 runtime 竞争）；未知路由记状态不抛 | 截图 + 启动日志 + want 原文 |
| **深链（热激活）** | 应用在前台时再次触发 want | 同通道热激活换页；重复/过期 sequence 丢弃；Shell 取消审批时记录 not applied、绝不半应用 | 截图 + 日志（sequence） |
| **无 HMS 降级不抛**（承 #27） | OpenHarmony SDK 包上触发 Push/Account/Map/TTS 探针 | 值与 #27/#29 口径一致（`Unavailable`/null/false + `IsSupported=false`），**无异常** | 启动日志 + 状态原文 |
| **Map/LiveView/AOT/解释器**（承 #28） | 同 #28 交接 §2（Map/LiveView 降级与点亮；`aot=1`/`aot=0`；`interp=3 source=file`） | 与 #28 一致；mode-matrix 一键跑 | 对应交接/判定卡 |
| **权限弹窗 / Share / Scan / PLAT-GAP / 新 payload 首次运行**（承 #25/#26/#27） | 同对应交接步骤 | 与 #28 相同口径；**本包首次运行判定 = 重签 → 安装默认 hap → 启动 → 5 条冒烟 + verify-kit（abc 281,052/20,916）** | 对应材料 + `tester-run.sh` 证据包 |

> **一键执行（tester-run.sh v11，推荐入口）**：模式四态 = `sh tester-run.sh --mode-matrix --kit-tar <kit>
> --aot-haps <aot> --interp-pack <interp> --capture 60`；常规一轮 = `sh tester-run.sh --kit-dir ./device-test-kit
> --install --start --capture 60`（加 `--a11y-probe` 采集无障碍）；汇总在 `<out>/summary.txt`（v9/v10/v11 键：
> `aot_route`/`interp_mode`/`a11y_*`）。

> 本轮 kit 的 5 个 hap 仍是 **JIT payload**（hostfxr 回退；TTS sink 在默认 flavor 下不注册、HUKS 走 in-process
> 原生引擎）；TTS 真朗读、harmony 壳、HMS 设备与 AGC 权益、深链的清单声明均需测试方侧外部条件，本环境不可代办。
> 没有对应入口时按「未测（本包无入口）」登记，不要判失败。

## 3. 启动路径与 JIT 判定（一字未改，承 #24–#28）

- 启动相关修复不变：P17 跳过重复解压、H7 rawfile fd 直读、headless abc `13.0.1.0`、
  payload-in-libs（`libs/arm64-v8a/` 原地启动 + `.dotnet-payload.json` 校验，`dotnet.zip` 回退）；
  kit #29 重建了壳 abc 与宿主（TTS/HUKS/深链桥），启动判定不变（JIT 路径仍是 hostfxr）。
- exec-memory 探针与 `xwe.txt` A/B **未变**（v11 仍采集 `hilog/hilog-execmem.txt`，并保留 v9 起的
  `aot=`/`interp=` 路由行与 `summary.txt` 的 `aot_route`/`interp_mode` 键，v10 起有 `--mode-matrix`）；判定表、
  A/B 指令与 NativeAOT 指引见 `2026-09-24-ohos-tester-handoff-kit24.md` §3–§5。
- 最直接的回归检查：应用能起（`[maui] openharmony build …` 出现）、原生桥调用不抛
  `EntryPointNotFoundException`/`DllNotFoundException`、TTS/HUKS/深链探针不崩、JIT payload 的 AOT 探针
  以 `aot=0` 回退不阻塞启动、深链 activation 不阻塞启动。

## 4. 校验与取证（与 #28 相同，只换 abc 期望值）

1. 下载/校验/重签/安装同 `快速开始.md` §1/§3；kit 内 `verify-kit.sh` 逐 hap 断言 abc **`281052`**/`20916`、
   `dotnet.zip` 254 项、`libs/arm64-v8a` 14 个 `.so` + `.dotnet-payload.json` payload-in-libs 断言、
   `resources.index` 1588/1780（≤ 2 KiB）；语义不变（FAIL → 退出码 1；WARN → 仍 `KIT OK`）。**用 #28 的旧期望值
   `264136`（或更早的 `245412`/`234620`）校验本包会 FAIL —— 那是脚本的预期行为，不是包坏。**
   本轮整包数字（tar/树/sidecar/5 hap）以 release「## Integrity」与 `.tar.gz.sha256` sidecar 为准（本页不写死）。
2. 一条命令取证（`tester-run.sh` **v11**）：`sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60`
   → 证据包含 `hilog/hilog-{applib,dlopen,bootstrap,execmem}.txt`、`device/payload-*.txt`、
   `meta/kit-selfcheck.txt`（`kit_index_ok`/`payload=yes|no`）与 `summary.txt`（`aot_route`/`interp_mode` 新键）。
   模式矩阵（四态一键）：`--mode-matrix`；无障碍专项：`--a11y-probe`（`a11y/` + `summary a11y_*`）。
3. 有 harmony flavor / HMS 的测试者请附：壳的构建出处（可直接取 `harmony-haps.tar.gz`，MAPFIX 重切件
   abc 291,628 B/`a637a513…`、含 overlay 模块记录；仍需自备重签材料与
   AGC 权益；TTS 无 AGC 门槛、只要 HMS 设备）、TTS speak/stop/locales 证据（计时 + 列表）、HUKS 重启读回
   与删除清 key 证据、深链冷/热激活截图与日志、Map/LiveView/AOT 证据同 #28、解释器轮附 `interp=` 行与 maps 摘录。
4. AOT hap 不要用 kit `verify-kit.sh` 的 JIT 期望值（14 `.so`）核对（AOT hap 只有 3 个 `.so`）；用
   `aot-haps-README.md` 的 5 条形态判定。

## 5. 仍未验证（如实边界）

- 本轮增量（TTS 真朗读、HUKS 经打包 hap 的完整回合、深链系统投递、文本编辑 IME 节拍、动画减少动效开关、
  列表/图片的演示入口真机表现）**均未上机**：kit 的 hap 是自签名（`9568257`/`9568344` 属预期，先重签）。
- HUKS 的引擎已在开发设备用**签名的 aarch64 探针**验证（跨进程封/解、换别名拒绝、`delete` 后拒绝），但
  **尚未经打包 MAUI hap 全回合**；迁移旧的 `k1:` 前旧格式数据（首读重加密）仍未做（旧值仍可读回）。
- TTS 真机验收需 HMS 设备 + harmony 壳（Kit 无 AGC 权益/权限门槛；设备语音能力与离线音色数据是门）；
  AGC 清单第 13 行 = TTS、门槛项为「设备语音能力/离线音色数据」。
- 深链的 `module.json5` `abilities[].skills[].uris` 清单声明与系统 App Linking 的实际投递（`onNewWant`
  触发形状）仍待设备；当前只有 app.json 白名单 + 托管校验。
- 商店/AGC 上架准备（元数据合规、签名/Profile、27 类权限映射与 reason 模板、App Linking 清单声明、提交前自检）见
  `2026-09-28-ohos-agc-store-readiness.md`。
- 图片解码 bench 为**设备本机 bench**（signed aarch64 探针，非 MAUI 应用路径）；MAUI 演示页大图回合待做。
- 权限弹窗 / Share 面板 / Scan 返回 / AOT（#25 口径）自 #25 起、PLAT-GAP 消费方路径（#26）与无 HMS 降级
  不抛（#27）、R2（#28）自各自批次起**仍未有真机回传**；stock kit（#22 起，含 #29）的首次设备复测仍待做
  （里程碑与判定点见 `2026-09-24-ohos-device-milestone.md` §6）。
- 批次注记：kit #29 的门禁为交互套件 **387/floor 367**（TTS/HUKS/文本编辑/动画/列表/图片/深链批次；
  `ohos-workload 3e6d9f4` 等）；`tester-run.sh` v11（119,452 B / `2355e493…`，`script_version=11 (2026-09-27)`）、
  `devloop.sh` v1（28,582 B / `7491d0c3…`）；本页所记数字 = 2026-09-28 实测（abc 281,052/20,916、导出 143、
  套件 387/367），重签、预签或重新打包后以 release「## Integrity」与 `.sha256` sidecar 为准。
