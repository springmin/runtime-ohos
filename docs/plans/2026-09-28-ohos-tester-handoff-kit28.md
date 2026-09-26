# 测试方交接：kit #28、R2（Map 覆盖层 / LiveView 探测 / `start_app` AOT 桥 / 解释器实验）判定点（2026-09-28）

> 承接 kit #27 交接（`2026-09-27-ohos-tester-handoff-kit27.md`）：KIT-EXT2（Push/Account/Map 探测、130/130 导出、
> marshal-off）与 #26 的 P2-INTEROP/TASK-MIG/PLAT-GAP、#25 的权限链/Share/Scan/AOT 判定点**继续有效**（本文 §2
> 给出口径）；JIT A/B 指令与 `probe:`×`xwe` 判定表（kit #24 交接 §3–§5）**一字未改**。本文只覆盖 #28 的增量与判定点。
> 结论先行：kit #28 = **R2 批** —— ① **Map 覆盖层（方案 (a) 已实现）**：`MapComponent` 覆盖层位于
> harmony-flavor 专属模板模块（`templates/ets/map/MapOverlay.ets`，字面量 `@kit.MapKit`，
> `NodeController`/`BuilderNode` 挂载），托管 `OpenHarmonyMap` 提供 show/hide/close/区域/标记与
> `Ready`/`MarkerClick`/`CameraIdle` 事件；**默认 OpenHarmony flavor 下 overlay 不编译，`IsSupported` 可为 true
> 而 `IsOverlayAvailable=false`，所有 overlay 调用降级不抛**；真机点亮需 `ARKTS_SDK_FLAVOR=harmony` 壳 +
> AGC 地图 AppKey；② **LiveView 特性探测**：壳 `canIUse('SystemCapability.LiveView.LiveViewService')` +
> `@kit.LiveViewKit` 双门，TIMER 场景 create/update/stop（title/text/progress/time）；无 Kit/权益时
> `IsSupported=false`、Start/Update/Stop 返回 `Unavailable` 不抛；③ **壳 `start_app` AOT 启动桥**：宿主先探测
> `<app_dir>/lib<stem>.so` + `dlsym("openharmony_app_main")`，命中即在 bridged app 线程直启（日志 `aot=1`，
> bridge/lifecycle/NodeContent 全沿用），缺库/缺符号/分配失败记 `aot=0` 回退 hostfxr —— JIT payload 行为不变；
> ④ **解释器实验（独立资产）**：`ohos-interpreter-pack.tar.gz` 替换 payload `libcoreclr.so` + 新增
> `libclrinterpreter.so`，宿主读 `<files>/interp.txt`（首字符数字，如 `3`）→ `setenv("DOTNET_InterpMode", 3)`，
> 日志 `interp=3 source=file`。
> 指纹（本轮已核实部分）：ui/shell abc **264,136 B**（headless **18,532 B**）、hap 内宿主 **269,216 B**（本机
> `verify-kit` 整包复核；`DT_NEEDED` 5、UND 239、denylist 0）、宿主导出契约 **134/134**、
> 交互门禁 **334/floor 314**；侧挂 `aot-haps.tar.gz` **17,090,044 B** / `67519d11…`（+ `aot-haps-README.md`）、
> `ohos-interpreter-pack.tar.gz` **2,419,988 B** / `a10699b3…`（+ README/sidecar）。
> **kit #28（数字入口见 release Integrity）**：`device-test-kit.tar.gz`、解压内容树、5 个 hap 与 bundle 的
> tar/树/sidecar 数字一律以 release 说明的「## Integrity」小节或 `.tar.gz.sha256` sidecar 为准（`workload-latest`
> 镜像同值）；本页不写死这些哈希。

## 1. kit #28 相对 #27 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1 | **Map 覆盖层（方案 (a)，R2-3）**：覆盖层落在 harmony-flavor 专属模块 `MapOverlay.ets`（字面量 `@kit.MapKit`），页面经变量说明符 `'./map/MapOverlay'` 动态导入；托管 `OpenHarmonyMap` 新增 `IsOverlayAvailable`/`ShowAsync`/`HideAsync`/`CloseAsync`/`SetRegionAsync`/`AddMarkerAsync` 与 `Ready`/`MarkerClick`/`CameraIdle`；宿主 `ohos_host_map_command(id, op, args)` 复用同一组 Map 导出（op 0 probe / 1 create / 2 destroy / 3 show / 4 hide / 5 set region / 6 add marker；code 0 应用 / -1 不可用 / -2 overlay 拒绝） | 默认 flavor 的 5 个 hap：capability flags 无 bit1（`IsOverlayAvailable=false`）；所有 overlay 调用返回不可用且**不抛**；harmony flavor 且 AGC AppKey 正确时地图视图出现、事件可达 | **Map 覆盖层**（§2；无入口/无 harmony 包按「未测（本包无入口）」登记） |
| 2 | **LiveView 特性探测与桥（R2-SHELL-EXT）**：壳 `registerLiveViewSink` + `notifyLiveViewResult`，TIMER 场景 create/update/stop；宿主 `ohos_host_liveview_{available,request,register_result,result}`，导出契约 **130/130 → 134/134**；托管 `OpenHarmonyLiveView`（`IsSupported`/`StartAsync`/`UpdateAsync`/`StopAsync`；`-1..-4` 本地码 + `1003500004`/`1003500005` 等 Kit 码透传） | 无 Kit/权益：sink 不注册、`IsSupported=false`、三个调用 `Unavailable` 且不抛；HMS + AGC 实况窗权益 + 设备开关打开：出现 TIMER 实况卡片 | **LiveView**（§2；本包 hap 无对应 UI 入口，首选判定是「降级不抛」） |
| 3 | **壳 `start_app` AOT 启动桥（R2-SHELL-EXT V1）**：宿主在 `start_app` 先探 `lib<stem>.so` → `openharmony_app_main`，命中即直启（`aot=1`）；失败（缺库/缺符号/分配）记 `aot=0` 回退 hostfxr；`run_app` one-shot 行为不变 | 旁挂 `aot-haps.tar.gz` 的 AOT hap 现在也能走 ArkTS 壳 `start_app` 直启（此前只能 `run_app`）；kit 内 5 个 JIT hap 仍走 hostfxr 回退（回归点） | **AOT 启动**（§2：`aot=1` 日志、managed 输出、无 `The application to execute does not exist`） |
| 4 | **解释器实验（R2-INTERP，独立资产）**：`ohos-interpreter-pack.tar.gz`（feature-enabled `libcoreclr.so` + `libclrinterpreter.so` + README/VERIFICATION/SHA256SUMS/build-info）；宿主 `<files>/interp.txt`（首字符为数字）→ 启动前 `setenv("DOTNET_InterpMode", <值>)`，日志 `interp=<v> source=file|default`（无文件不写入、运行时默认 JIT 不变） | 测试方按 §2 组合并签名 HAP 后：纯解释模式启动；`/proc/self/maps` 可判解释器激活与匿名 `r-x` | **interpreter**（§2；实验资产，按交付方指示取用） |
| 5 | **门禁与重建**：ui/shell abc 重编 **264,136 B**（headless 18,532 B 不变）、导出契约 **134/134**、交互套件 **334/floor 314**（kit7 = Map 覆盖层（含 flavor 门）；kit8/kit9/kit10 = LiveView shell/bridge/降级）；包内 `verify-kit.sh` abc 期望重锚 **264136**（`ohos-workload 112b6e9`），`tester-run.sh` 仍为 **v8**（73,375 B，未重传） | 校验步骤、证据字段与 #27 相同，**只换 abc 期望值（264,136/18,532）**；用 #27 的 `245412` 或更旧的 `234620` 校验本包会 FAIL（脚本预期） | 校验时以 release「## Integrity」与包内 `verify-kit.sh` 为准 |
| 6 | **并列资产（不替换 kit 内 5 个 JIT hap）**：`aot-haps.tar.gz`（hello-maui-app NativeAOT 变体：`libhello-maui-app.so` + 宿主 + `libc++_shared.so`，无 CoreCLR 运行库）+ `aot-haps-README.md`；`ohos-interpreter-pack.tar.gz` + README + `.sha256` | 形态判定：AOT hap `libs/arm64-v8a/` 恰 3 个 `.so`（**勿**用 kit `verify-kit.sh` 的 JIT 期望值套 AOT hap）；解释器 pack 用 `sha256sum -c SHA256SUMS` 自检 | 按交付方指示取用（§2） |

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **Map 覆盖层降级不抛**（默认 flavor，本轮核心之一） | 在 kit #28 的 5 个 hap（默认 OpenHarmony flavor）上启动并触发 Map 探针/自检 | `IsSupported` 允许为 true（Kit 可解析）但 **`IsOverlayAvailable=false`**；`ShowAsync`/`HideAsync`/`CloseAsync`/`SetRegionAsync`/`AddMarkerAsync` 全部返回不可用，`Ready`/`MarkerClick`/`CameraIdle` 不触发，**无异常、无崩溃** | 启动两行日志 + `files/dotnet-status.txt`（如有）+ hilog 原文；无入口登记「未测（本包无入口）」 |
| **Map 覆盖层点亮**（harmony flavor + AGC AppKey，可选） | 用 `ARKTS_SDK_FLAVOR=harmony` 构建的壳 + AGC 开通地图服务并配置 AppKey（bundleName/签名指纹一致） | flags bit1=1（`IsOverlayAvailable=true`），地图视图出现；依次触发 **show/hide/设置区域/添加标记**，事件 **Ready / MarkerClick / CameraIdle** 可达；失败（无 AppKey）时无 `Ready` 且日志有 `MapOverlay.ets` 初始化失败 | 界面截图 + flags 值 + 事件顺序日志 + AGC 开通截图 |
| **LiveView 降级不抛**（默认 flavor） | 启动并触发 LiveView 探针/自检 | `IsSupported=false`；`StartAsync`/`UpdateAsync`/`StopAsync` 返回 `Unavailable`，**不抛**；sink 未注册 | 状态原文 + hilog；无入口登记「未测（本包无入口）」 |
| **LiveView 点亮**（HMS + AGC 权益，可选） | HarmonyOS SDK 构建 + AGC 申请实况窗权益（TIMER 场景）+ 设备实况窗开关打开 + 应用前台 | TIMER 模板卡片出现并能更新/停止；开关关闭时 `-3`/`1003500004`、权益未批时 `1003500005`（透传为可读状态而非崩溃） | 卡片截图 + 状态/错误码原文 + 权益审批截图 |
| **AOT 启动（`aot=1`）** | 取 `aot-haps.tar.gz` → 按 kit 签名流程重签 AOT hap → 安装 → `aa start` / 桌面启动 | hilog 出现 **`aot=1`**；`lib<stem>.so` 的 `openharmony_app_main` 被直启；managed 输出/首帧正常；**无 `The application to execute does not exist`**（出现即说明误走 JIT 路由/缺 hostfxr） | 启动日志（`aot=1` 行）+ managed 输出 + 进程存活 |
| **AOT 回退（回归）** | 同一包在 AOT 探针失败路径（如删掉 `lib<stem>.so` 的非正式复现，或直接用 kit 内 JIT hap） | 日志 `aot=0` 后仍走 hostfxr/JIT 正常启动；kit 内 5 个 JIT hap 行为与 #27 相同 | 启动两行日志 + 进程存活 |
| **interpreter（实验）** | ① `sha256sum -c SHA256SUMS` 核对 pack；② 在 payload HAP `libs/arm64-v8a/` 替换 `libcoreclr.so` + 新增 `libclrinterpreter.so` → 重签安装；③ 在应用沙箱 `<files>/interp.txt` 写入首字符为数字的值（如 `3`）后启动 | hilog 出现 **`interp=3 source=file`**；运行中 `/proc/self/maps` 含 `libclrinterpreter.so`；**无匿名 `r-x`**（残余匿名 exec 页可能来自 `Precode`/UMEntryThunk stub —— **先记录、勿改 W^X**）；managed 正常输出/首帧、无 `SEGV_ACCERR` | `interp=` 行原文 + maps 摘录（`libclrinterpreter.so` 行 + 匿名 `r-x` 计数）+ managed 输出 |
| **无 HMS 降级不抛（承 #27）** | OpenHarmony SDK 包上触发 Push/Account/Map 探针 | Push `GetTokenAsync`/`DeleteTokenAsync`、Account `AuthorizeAsync`/`GetQuickLoginAnonymousPhoneAsync`、Map `QueryCapabilitiesAsync`/`IsSupported` 返回 `Unavailable`/null/false，**无异常** | 同 #27（启动日志 + 状态原文） |
| **权限弹窗 / Share / Scan / PLAT-GAP**（承 #25/#26） | 同 #25/#26 交接步骤 | 权限弹窗理由文案、Share/Scan 降级、PLAT-GAP 消费方路径与 #27 相同 | 对应交接文档截图/输出 |
| **新 payload 首次运行**（承 #26/#27） | 重签 → 安装默认 hap → 启动 → 跑 `快速开始.md` §5 的 5 条冒烟 | 正常启动、不崩、首帧正常；`verify-kit.sh` 全过（**abc 264,136/18,532**、`dotnet.zip` 254、index ≤ 2 KiB） | 启动两行日志 + `files/dotnet-status.txt`；失败附 `tester-run.sh` 证据包 |

> 本轮 kit 的 5 个 hap 仍是 **JIT payload**（hostfxr 回退；LiveView/Map overlay 的 sink 在默认 flavor 下不注册/不编译）；
> Map 覆盖层、LiveView、AOT 直启与解释器的**完整点亮**分别需要 HarmonyOS SDK 构建（`ARKTS_SDK_FLAVOR=harmony`）、
> HMS 设备、AGC 开通/审批（地图 AppKey / 实况窗权益 / Push / Account scope）与自签材料，本环境不可代办。
> 没有对应入口时按「未测（本包无入口）」登记，不要判失败。

## 3. 启动路径与 JIT 判定（一字未改，承 #24–#27）

- 启动相关修复不变：P17 跳过重复解压、H7 rawfile fd 直读、headless abc `13.0.1.0`、
  payload-in-libs（`libs/arm64-v8a/` 原地启动 + `.dotnet-payload.json` 校验，`dotnet.zip` 回退）；
  #28 重建了壳 abc 与宿主（R2 桥），启动判定不变（JIT 路径仍是 hostfxr）。
- exec-memory 探针与 `xwe.txt` A/B **未变**（`tester-run.sh` v8 仍采集 `hilog/hilog-execmem.txt`；
  `summary.txt` 仍写 `execmem_capture`/`execmem_lines`）：判定表、A/B 指令与 NativeAOT 指引见
  `2026-09-24-ohos-tester-handoff-kit24.md` §3–§5。
- 最直接的回归检查：应用能起（`[maui] openharmony build …` 出现）、原生桥调用不抛
  `EntryPointNotFoundException`/`DllNotFoundException`、无 HMS 的 Kit 探测不崩、JIT payload 的 AOT 探针
  以 `aot=0` 回退不阻塞启动。

## 4. 校验与取证（与 #27 相同，只换 abc 期望值）

1. 下载/校验/重签/安装同 `快速开始.md` §1/§3；kit 内 `verify-kit.sh` 逐 hap 断言 abc **`264136`**/`18532`、
   `dotnet.zip` 254 项、`libs/arm64-v8a` 14 个 `.so` + `.dotnet-payload.json` payload-in-libs 断言、
   `resources.index` 1588/1780（≤ 2 KiB）；语义不变（FAIL → 退出码 1；WARN → 仍 `KIT OK`）。**用 #27 的旧期望值
   `245412`（或更早的 `234620`）校验本包会 FAIL —— 那是脚本的预期行为，不是包坏。**
   本轮本机对 kit #28 tar 的整包复核已 `KIT OK`（15/15 `SHA256SUMS`、树摘要与 5 hap 深度断言全过；hap 内宿主
   **269,216 B**、`dotnet.zip` 254/0 `.so`、index 1588/1780）——**整包 tar/树哈希仍以 release「## Integrity」为准**。
2. 一条命令取证（`tester-run.sh` **v8**，未变）：`sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60`
   → 证据包含 `hilog/hilog-{applib,dlopen,bootstrap,execmem}.txt`、`device/payload-*.txt`、
   `meta/kit-selfcheck.txt`（`kit_index_ok`/`payload=yes|no`）与 `summary.txt`。
3. 有 harmony flavor / HMS 的测试者请附：`ARKTS_SDK_FLAVOR=harmony` 的构建出处、AGC 开通/审批截图、
   Map flags/事件日志、LiveView 卡片截图与错误码、AOT hap 的 `aot=1` 日志；解释器轮次附 `interp=` 行、
   maps 摘录与 `SHA256SUMS` 自检输出。
4. AOT hap 不要用 kit `verify-kit.sh` 的 JIT 期望值（14 `.so`）核对（AOT hap 只有 3 个 `.so`）；用
   `aot-haps-README.md` 的 5 条形态判定。

## 5. 仍未验证（如实边界）

- 本轮全部增量（Map 覆盖层、LiveView 桥、`start_app` AOT 直启、解释器 pack、`interp.txt` 开关）**均未上机**：
  kit 的 hap 是自签名（`9568257`/`9568344` 属预期，先重签）。
- Map 覆盖层的**真机点亮**需 HarmonyOS SDK + AGC 地图 AppKey；LiveView 需 AGC 实况窗权益 + 设备开关；
  AOT 直启需签名后的 AOT hap；解释器需替换 payload 后重签 —— 当前只有**离线/本机证据**（kit7/kit8/kit9/kit10
  断言、AOT smoke 的 one-shot/`--bridge` 两路由、`interp.txt` 解析与 setenv 日志对）。
- 解释器的残余匿名 `r-x`（Precode/UMEntryThunk stub）与 `DOTNET_InterpreterName` 负对照**未在真机取证**；
  先记录判定点，勿改 W^X/启动策略。
- 权限弹窗 / Share 面板 / Scan 返回 / AOT（#25 口径）自 #25 起**仍未有真机回传**；PLAT-GAP 消费方路径自 #26
  起仍待真机复测；无 HMS 降级不抛（#27）自 #27 起仍待真机复测；stock kit（#22 起，含 #28）的首次设备复测
  仍待做（里程碑与判定点见 `2026-09-24-ohos-device-milestone.md` §6）。
- 批次注记：kit #28 的门禁为交互套件 **334/floor 314**（kit7/kit8/kit9/kit10；`ohos-workload 626f4bc`/`112b6e9`）；
  `tester-run.sh` 未重传（仍 v8，73,375 B）；kit 整包数字以 release「## Integrity」为准（本页保持哈希无关）。
