# 一条命令跑完一轮真机测试（tester-run.sh）

> **2026-10-05 更新（kit #47，当前）**：kit #47 = **kit #46（INTERP-DRAW2 + FIX-A11YBUTTON）+ FlyoutPage 无障碍（FIX-A11YFLYOUT）+ 抢占原文导出（FIX-PREEMPT-RAW）**：①**FIX-A11YFLYOUT**（maui 切片 `d5384d6cc3`）：`PushChildren` 补 `FlyoutPage.Detail`（恒入树）/`FlyoutPage.Flyout`（仅 `IsPresented`）分支（rc.1 FlyoutPage 非 `IContentView`，旧分支覆盖不到 → 只发布根）；headless 断言 `a11y-flyout detail/panel` + 负控制红，真机 `--a11y-probe` **nodeCount 1→70**；②**FIX-PREEMPT-RAW**（ohos-workload `f538c84`）：壳 `pollManagedStatus` 把 `dotnet-status.txt` 新增段中含 `overlay preempted/restored/replay` 的行以 **`[maui-capacity]`** 前缀直写 hilog（trim 时整文件回退）→ 真机低噪声复放取到 5 行原文（`preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`）；③承 #46：**INTERP-DRAW2**（面外剔除：interp draw 14.4→9.4 ms、33.9→60.1 fps、每帧 CPU −27%；JIT 无回归）、**FIX-A11YBUTTON**（自检按钮左下角 + 覆盖层之上，两态真机可达 `[523,1622][607,1668]`）；④承 #45：自动释放（FIX-AUTODISCONNECT）/INTERP-RENDER/动态槽（MAX/HOT 4/2 + 3 控件）/默认 AOT/FRAMEPACING 与 #42… 全部修复；**预签已刷新至 #47**（67,639,132 / `f58c4906…`，asset 610975429；sidecar 88 B / `c95344ac…`，asset 610976421）；壳 abc **370,240（`4b439e83…`）**/24,324、宿主 **297,888（`7b1694d9…`，导出 151/151）**、套件 **593/595 floor 575**；发布实测 tar **67,706,719 / `3d6bb58b…`**、树 `0f266636…`、sidecar `4adb0b60…`、`SHA256SUMS` 18 项 / 1,600 B / `6bbc2235…`；bundle **73,059,625 / `27c54c62…`**（sdk 锚 **`266b196106`**）；CI 5/5 @ `3de9a95fe0` + sdk run `37245230111`；数字以 release「## Integrity（kit #47）」与随包校验为准；判定点 = `docs/plans/2026-10-05-ohos-tester-handoff-kit47.md`。
>
> **2026-10-04 更新（kit #45，上一版）**：kit #45 = **kit #44（动态槽 SLOTS-DYNAMIC + 默认 AOT + FRAMEPACING）+ 自动释放（FIX-AUTODISCONNECT）+ 渲染门控（INTERP-RENDER）**：①**FIX-AUTODISCONNECT**（maui 切片 `189b87ca8a` + ohos-workload `64ee9c4`）：页面/ContentView/Layout 子树 watcher 驱动切片 `IOpenHarmonyOverlaySlotLifetime`——**移除 web 控件即发 hide 并释放槽位**（动态槽在壳内 `web slot destroy` 销毁；热对 [0,1] 保留组件）、**再挂回自动重领槽并重放 load/注册**（`web slot create`）；handler 保持连接、晚到注册被忽略；真机 kit 样例（无显式 DisconnectHandler）Remove C → `web slot destroy: 2`（12:40:50）、re-add → `web slot create: 2`（12:41:00）并恢复交互（c1–c5）；套件 **+3 pin → 587/589 floor 569**；②**INTERP-RENDER**（maui `7c731a7ca3` + ow `8ed35f4`）：布局门控（仅真实失效信号才 Measure/Arrange）→ **interp 22.0→30.1 fps（20.7→30）、meas 13.0→0.0 ms/帧、主线程 CPU 79.6–81.8%→65.5–70.5%（−13pt）**；JIT/AOT 60 fps 不变、draw/pres 不变、交互不变（Count 0→1）；③承 #44：动态槽 3 控件并发/释放重建、默认 AOT（5 MAUI hap 全 NativeAOT）、FRAMEPACING（60.00 fps）；**预签已刷新至 #45**（67,624,950 / `e1ce8ab6…`，asset 609411819；sidecar 88 B / `a7ab0943…`，asset 609416429）；壳 abc **368,812（`1076a700…`）**/24,324、宿主 **297,888（`7b1694d9…`，导出 151/151、UND 241）**、套件 **587/589 floor 569**；发布实测 tar **67,695,181 B / `ca48a93c…`**、树 **`ae0f7fce…`**、sidecar **`9741aced…`**、`SHA256SUMS` 18 项 / 1,600 B / `9f677c40…`；bundle **73,058,366 / `a8334c4c…`**（sdk 锚 **`c7ac81ccdf`**）；CI 5/5 @ `b6ad0b0`；数字以 release「## Integrity（kit #45）」与随包校验为准；判定点 = `docs/plans/2026-10-04-ohos-tester-handoff-kit45.md`（#44 = 上一版：动态槽 + 默认 AOT + FRAMEPACING；tar 67,680,863 / `b777d8d8…`；#43 = 更早：默认 AOT + FRAMEPACING；tar 67,638,015 / `57c7bf44…`）。
>
> **2026-10-04 更新（kit #44，上一版）**：kit #44 = **#43（默认 AOT + FRAMEPACING）+ 动态槽（SLOTS-DYNAMIC）**：①**动态槽**（ohos-workload `88e5aec` + maui 切片 `3feb347414`）：覆盖层池 **MAX/HOT 默认 4/2**（clamp 2..8 / 2..max）、**按需 ensure/destroy**（热对 [0,1] 常驻、释放的动态槽立即拆）、**容量事件降级 + owner-LRU 抢占**（保持 #41 恢复语义）、**延迟命令回放**（壳未 attach 命令按槽排队 ≤32、`onControllerAttached` 按序重放）、**壳 `ForEach` 槽 + `SetShellCapacity`**——**3 控件并发出画/交互**（第 3 槽回收/重建、Blazor 热换）；②**默认 AOT**（承 #43）：5 MAUI hap 全 NativeAOT、`runtime-mode.txt=aot`、无 JIT 运行时（JIT 保形态；release/生产域需 AGC ACL/豁免；`--runtime-mode jit` 可自建）；③**FRAMEPACING**（承 #43，ow `aa6f485`）：宿主 present telemetry + stats harness——17.7 fps 系壳状态轮询伪影，实际 **60.00 fps**；**预签已刷新至 #44**（7 hap；67,627,789 B / `75a40110…`，asset 608782132；sidecar 88 B / `b880a68f…`，asset 608782732）；壳 abc **368,812（`1076a700…`）**/headless 24,324（`798b2477…`）、宿主 **297,888（`7b1694d9…`，导出 151/151、UND 241）**、套件 **584/586 floor 566**；发布实测 tar **67,680,863 B / `b777d8d8…`**、树 **`db2604d5…`**、sidecar **`85d62a6e…`**、`SHA256SUMS` 18 项 / 1,600 B / `41c1f3c3…`；bundle **73,052,763 / `3b3008a4…`**（sdk 锚 **`2abf4fcaa3`**）；CI 5/5 @ `86b0e89`；数字以 release「## Integrity（kit #44）」与随包校验为准；判定点 = `docs/plans/2026-10-04-ohos-tester-handoff-kit44.md`（#43 = 上一版：默认 AOT + FRAMEPACING；tar 67,638,015 / `57c7bf44…`；#42 = 更早：三路径首帧；tar 376,256,128 / `ea4e3b58…`）。
> **2026-10-03 更新（kit #42，更早）**：kit #42 = #41 + **JIT 解锁 + 解释器 rc2b 首帧 + FIX-SLICERACE（8/8）+ L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c/镜像扩展**（①**JIT 解锁**（WX-HOST-PRCTL：宿主 `prctl(0x6a6974)` JITFORT 默认开 + 无 ICU 镜像自动 `InvariantGlobalization`）→ **JIT 首帧**（`canvas presented` 4–8 + UI 截图；探针 `1=OK 2=OK`；逃生口 `DOTNET_OHOS_NO_JITFORT=1`/`DOTNET_OHOS_ICU`）；②**解释器 rc2b**（新资产 `ohos-interpreter-pack-rc2b.tar.gz` 2,410,595/`5974430509…`，asset 606999003；含 WX-PATCH2）→ **解释器首帧**（`canvas presented 2090x1324`；INTERP-NULL 根因 = 旧测试件 rc.1 托管 CoreLib × rc.2 原生 QCall ABI 错配，非 pack 缺陷）；③**FIX-SLICERACE**（切片 handler 并发设置竞争：可重入串行化 + `_ready` 门闩）→ **JIT 8/8 设备轮 PASS**、套件 **578/580 floor 560**；④L6（Screenshot JPEG/Title 心跳；壳 abc **356,468/`dd04dad1…`**）、LEGACY Toolbar 闭合、SAMPLE-FIX（`blzProbe`=`dotnet-ref ok`、Blazor `#app` 恢复挂载、`dotnet.zip` 258 项）、WX-PATCH2 双映射预检+写屏障提交检查、P2c `skills[].uris`、镜像扩展（`m-web-mirror d47f1fcb3b`）；宿主全量重建 **297,888（`08abe185…`，导出 151/151、UND 240）**；**预签未刷新（仍 #41 件，指向 #41 内容）**；FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount/FIX-JSCALL/MULTI-OVERLAY-FULL/DEVCOMPAT 全量保留；发布实测 tar **376,256,128 B / `ea4e3b58…`**、树 **`13f3a086…`**、sidecar **`878d05a1…`**；数字以 release「## Integrity（kit #42）」与随包校验为准；判定点 = `docs/plans/2026-10-03-ohos-tester-handoff-kit42.md`（#41 = 上一版，见其交接文）。
> **2026-10-03 更新（kit #41，上一版）**：kit #41 = #40 + **MULTI-OVERLAY-FULL + DEVCOMPAT-DEFAULT + INTERP-FIX（三大彻底修复）**（①**MULTI-OVERLAY-FULL**（maui `07423dfe93` + ow `0e0129e`）：双槽 ArkWeb 覆盖层池 + **owner 感知 LRU 抢占/恢复**（`IOpenHarmonyOverlaySlotOwner`）、per-slot hybrid serve/message/**invoke 通道**（slot-tagged invoke id）、**激活序 z-order**、payload-in-libs appDir 探测——同页两 Hybrid 各自 invoke/消息闭环，>2 控件按 LRU 抢占退化、activate 恢复重放 load；②**DEVCOMPAT-DEFAULT**（ow `12be59c`）：payload 逐文件码签重写**默认化**（无扩展名→`.so`、恰 4096 B→+4 B）——enforcing 7.0.0.111+ **开箱可装**；kit 现 15 `.so` / 257 zip 条目；③**INTERP-FIX**（ow `c9916cd`）：宿主 **8 MB app 线程栈** + `interp=3` 关 GC 写屏障拷贝；**rc.2 重建解释器 pack** 独立资产 `ohos-interpreter-pack-rc2.tar.gz`（2,409,070 B / `34709a94…`，asset 605924427）；④**预签刷新至 #41**（tester UDID；376,684,381 / `2075650a…`，asset 606183753）；FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount/FIX-JSCALL 全量保留；壳 abc **356,140（`2a90f0d7…`）**/headless 24,324、宿主 **293,792（`8d67def3…`）**、导出 **150**、套件 **563/floor 543**；发布实测 tar **376,036,502 B / `bed460ae…`**、树 **`7ce1946e…`**、sidecar **`2a95e764…`**；数字以 release「## Integrity（kit #41）」与随包校验为准；判定点 = `docs/plans/2026-10-03-ohos-tester-handoff-kit41.md`（#40 = 上一版，见其交接文）。
> **2026-10-02 更新（kit #40，上一版）**：kit #40 = #39 + **FIX-JSCALL**（maui `15d81f31b1` + 套件 pin `2028cc2`/`9073c65`）：**BlazorWebView IPC 出站半边 AOT 扎根**——`IpcSender.BeginInvokeJS` 序列化 `JSCallResultType`/`JSCallType`、`IpcSender.Navigate` 序列化 `NavigationOptions`（均经 WebView 包反射解析器）；NativeAOT 缺 `EnumConverter<T>`/`JsonTypeInfo<T>` 闭合实例原生代码 → attach interop 死在 `IpcCommon.Serialize`（#39 的 FIX-BWVMount 桩 interop 又吞掉后续点击）；切片把三类型并入源生成上下文 + handler 静态构造触碰 type info + 移除桩探针 → **razor 计数往返 0→1→2 真机达成**（截图 r0/r1/r2；`missing native code`=0、`BeginInvokeDotNet` accepted=4）；FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount 全量保留；壳 abc **342,160（`ffda66da…`）**/headless 24,324（未变）、宿主 **293,792（`384e552a…`）**（未变）、导出 **150**、套件 **555/floor 535**；发布实测 tar **375,836,470 B / `31ab8732…`**、树 **`e950de54…`**、sidecar **`9b051247…`**；数字以 release「## Integrity（kit #40）」与随包校验为准；判定点 = `docs/plans/2026-10-02-ohos-tester-handoff-kit40.md`（#39 = 上一版，见其交接文）。
> **2026-10-02 更新（kit #39，上一版）**：kit #39 = #38 + **FIX-BACKSIZE + FIX-BWVMount**（①**FIX-BACKSIZE**（maui `be09a48817` + 壳/宿主 `9e6519e`）：系统 Back 键经壳 `onBackPress(): boolean` → 宿主 `host.backPressed`/`ohos_host_register_back_pressed`（导出 **149→150**）**关闭抽屉**（第二次 Back 交回系统 `#BACKGROUND`）；`BlazorWebView` 覆写 `GetDesiredSize`（真实尺寸——此前 `Standard` 返回 0 → frame 退化被壳忽略、自身不出画）；hybrid 已注册时 Blazor frame 有意 withheld；②**FIX-BWVMount**（maui `52b082a071`）：**NativeAOT 下 `.razor` 组件真机挂载**——handler 静态构造触碰源生成 `JsonElement[]` 类型信息，使 WebView 包反射构造的 `ArrayConverter` 留在 AOT 镜像（此前 `AttachPage` 在包内抛错、组件不挂载）；`[maui] blazor start/connect` + `BLZ_DIAG` 可观测；FIX-HOME/FIX-ITOUCH/FIX-DISMISS/FIX-WVP 全量保留）；壳 abc **342,160（`ffda66da…`）**/headless **24,324（`798b2477…`）**、宿主 **293,792（`384e552a…`）**、导出 **150**、套件 **554/floor 534**；发布实测 tar **375,765,521 B / `e95eed49…`**、树 **`932e7955…`**、sidecar **`e5fc82de…`**；数字以 release「## Integrity（kit #39）」与随包校验为准；判定点 = `docs/plans/2026-10-02-ohos-tester-handoff-kit39.md`（#38 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #38，上一版）**：kit #38 = #37 + **FIX-DISMISS + FIX-WVP**（①**FIX-DISMISS**（maui `86b439ffc8`）：抽屉**外点不关闭**的根因 = `FlyoutPage.Default` 版式在非 Phone idiom/landscape 下关闭被 `InvalidOperationException` 守卫拒绝（异常被触摸回调边界吞掉、面板保持）→ 默认 `Default` 改置 **`Popover`**（overlay 抽屉），外点正常关闭并重绘；②**FIX-WVP**（maui `47d79add01` + 壳 `acbe750`）：Hybrid overlay 坐标 **px→vp**（frame 为设备像素、壳按 ArkUI vp 用 → ×1.9 落窗外）、hybrid origin `https://0.0.0.1/` **注册仲裁**（后到 Blazor 只武装不加载）、`Web` 后置到 `ContentSlot` 之上（z-order 真出画）、抽屉/切 tab 时 **suspend/resume/hide** 状态机 + `WebCommandSent` 诊断）；FIX-HOME/FIX-ITOUCH 全量保留；壳 abc **341,560（`4f02cb1d…`）**/headless **24,324（`798b2477…`）**、宿主 **293,792（`4e9f3c3e…`）**、导出 **149**、套件 **550/floor 530**；**FIX-BACK 波次未入包**（Back 关抽屉 / BlazorWebView 尺寸在途，将随下一版）；发布实测 tar **375,641,619 B / `ced5583f…`**、树 **`307004e1…`**、sidecar **`8982fad0…`**；数字以 release「## Integrity（kit #38）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit38.md`（#37 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #37，上一版）**：kit #37 = #36 + **FIX-HOME + FIX-ITOUCH**（①**FIX-HOME**（maui 切片 `68ec598037`）：`OpenHarmonyNavigationPageHandler.PlatformArrange` 下钻 `CurrentPage`（safe-area walk + arrange 防递归标记）——Home tab（FlyoutPage→TabbedPage→NavigationPage）不再停在 `-1x-1`，AOT 真机首屏整页出画（截图 `fix-home/device/home-cold.jpeg`）；交互套件 +4 pin；②**FIX-ITOUCH**（宿主 `4e9f3c3e`）：`OnTouch` 改读 touch point **element** 坐标（与鼠标同一 surface 空间；free window 的 window 系含 70 px 系统标题栏 → 注入点击整体下移）——uitest 注入点击命中内容元素（"fading out…" → "animations done"）、偏心探针不误命中、tab 切换不变；宿主 UND 240→238）；壳 abc 字节不变 **339,964（`fc54d2b8…`）/24,324（`798b2477…`）**、hap 内宿主 **293,792（`4e9f3c3e…`）**、导出 **149**、套件 **544/floor 524**；发布实测 tar **375,652,577 B / `3a7259d6…`**、树 **`ab517b57…`**、sidecar **`7db60a77…`**；数字以 release「## Integrity（kit #37）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit37.md`（#36 = 上一版，见其交接文）。
> **2026-10-01 更新（kit #36，上一版）**：kit #36 = #35 + **payload 原地直载（AOT 路径真机 BLZ）+ host 预注册缓冲 + 像素 Known 清零 + a11y 渲染帧修复 + rc.2 AOT pack `-r2`**（①壳 `findLibsPayloadDir` 兼容模块布局 `<bundleCodeDir>/<module>/libs/<abi>`——真机 hello-maui-wasm 直接自 `/data/storage/el1/bundle/entry/libs/arm64` 原地启动（`dotnet.zip not unpacked`，pid 49565）且 `BLZ_BOOT`/`BLZ_RENDERED` 双标记齐；②host 缓冲壳 `registerWebSink` 注册前到达的 web 命令（16 条 / 64 KiB，注册即 flush；套件 pin `moduleRoot`/`webPending`）；③像素套件不再有 `Known(...)`（selection tint 改字节量化精确断言 `#3959B3`）；④a11y `nodeCount 0` 根因 = shadow tree 未 publish，S2a pin `renderAttached=True`、`--a11y-probe` 实测 `status=1`、nodeCount 5/24 稳定；⑤rc.2 AOT pack 修正版 `-r2`（28,904,657 B / `542058cf…`，asset 601289590）修复 OpenSSL shim → 撤 rc.1 钉）；新壳 abc **339,964（`fc54d2b8…`）/24,324（`798b2477…`）**、hap 内宿主 **293,792（`cfbbe461…`）**、导出 **149**、套件 **540/floor 520**；发布实测 tar **375,627,841 B / `9eb9cecf…`**、树 **`9764827c…`**、sidecar **`4d7062c3…`**；数字以 release「## Integrity（kit #36）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit36.md`（#35 = 上一版，见其交接文）。
> **2026-09-30 更新（kit #35，上一版）**：kit #35 = #34 + **W9/W10 并入主线**（W9A **B2：MAUI WebView 承载 Blazor WASM**——真机 `BLZ_BOOT`/`BLZ_RENDERED` 打通（pid 6157），#34 的 AOT 入口缺口由 W10 修复；W9B T14 收尾 + T21 字体缩放；W9C T8 不等高 TableView；W9D **T20 媒体传输层**（本机镜像无 MediaKit 属预期，`IsSupported=false` 降级不抛）+ T19 深链判定（热 `delivered=1`）；W10 **AOT 入口修复**（宿主自身 libs 解析 `lib<stem>.so` + `dotnet-status.txt` 可观测、壳 AOT payload 探针/`fs` 别名/静态资源指纹；rc.2 AOT 包 OpenSSL shim 缺陷 → 本地钉 rc.1）；新壳 abc **339,164（`74054e2d…`）**/headless **23,516（`6bce4063…`）**、hap 内宿主 **293,792（`983e8f74…`）**、导出 **149**、套件 **540/floor 520**；发布实测 tar **375,629,423 B / `419d42e2…`**、树 **`d3b1b317…`**、sidecar **`d7e79d39…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `2dd447a7…`**（发布已完成，以 release「## Integrity（kit #35）」与随包校验为准）；判定点 = `docs/plans/2026-09-30-ohos-tester-handoff-kit35.md`（#34 = 上一版，见其交接文）。

> 面向拿到 device-test-kit、手上有设备/`hdc` 的测试者：把「校验 kit → 安装 → 启动 → 抓 hilog → 跑 P1–P4 探针 → 打包回传」串成一条命令。
> `tester-run.sh` 是 `device-test-kit` release 上的**独立资产**（不在 kit 的 `SHA256SUMS` 内，kit 本身无需重下）；脚本默认 **dry-run**，不加动作参数不会碰设备。
> 当前脚本 = **v14**（**140,197 B / `a174fcd0…`**、asset **595131362**；v13 = 137,113 B / `2caa06bd…` 为 #31 值；v12 = `script_version=12 (2026-09-28)` / 126,658 B / `87763a3e…` / release asset id 593961018 为 #30 值；v13 = **137,113 B / `2caa06bd…`**、asset **594519342**，增 `--blazor-probe`）：行为与输出字段对旧调用兼容；v6r2 起 `--tree-digest` 复用已校验摘要（P16）明显更快、证据包含 `meta/kit-hap-sha256.txt` 与 `summary.txt` 的 `main_hap_sha256`；v7 新增 bootstrap/rawfile 失败特征、设备侧 payload 状态与 kit hap 自检；v8 再增 exec-memory 证据采集（`hilog/hilog-execmem.txt`，`summary.txt` 记 `execmem_capture`/`execmem_lines`；见 §5、§6）；**v9/v10/v11 增 `aot_route`/`interp_mode` 键与 `aot=`/`interp=` 路由行、`--mode-matrix` 四态一键矩阵（`mode-matrix/summary.txt` + `conclusion`；见判定卡 §2.0）与 `--a11y-probe` 无障碍采集（`a11y/selfcheck.txt` + `a11y/hilog-a11y.txt`，`summary a11y_*`；见无障碍清单）；v12 增 `runtime_mode` 键（读主 hap `libs/<abi>/runtime-mode.txt`：`jit|aot|interp(hap)|invalid(...)|<absent>`）、file>manifest>default 回退（清单包记 `3(manifest)`/`1(manifest)`）、execmem 保留 `runtime-mode=` 行，`--mode-matrix` Run C 在主 hap 标记 interp 时直接跑 stock hap（`run_c_via=manifest`，不写 `interp.txt`、不重打包）；**v13** 增 `--blazor-probe`（装/启重签后的 Blazor hap `com.example.opendotnet`，断言 `BlazorWebHost ... marker: BLZ_BOOT`/`BLZ_RENDERED` 两条 hilog 标记；失败落 `blazor-hilog.txt`）**。
> 逐项清单与判读仍见 `docs/plans/2026-09-19-ohos-hap-acceptance-for-testers.md`（包内名 `验收说明.md`）；探针定义见 `docs/plans/2026-09-21-ohos-crash-probes.md`。
> 当前发布相关：**kit #45**（2026-10-04；#45 = #44 + **自动释放（FIX-AUTODISCONNECT）+ 渲染门控（INTERP-RENDER）**；发布实测 tar **67,695,181 / `ca48a93c…`**、树 `ae0f7fce…`、sidecar `9741aced…`、bundle 73,058,366 / `a8334c4c…`（sdk 锚 `c7ac81ccdf`）；套件 587/589 floor 569；预签刷新至 #45（67,624,950 / `e1ce8ab6…`，asset 609411819）；#44 = #43 + **动态槽（SLOTS-DYNAMIC：MAX/HOT 默认 4/2、按需 ensure/destroy、容量事件降级/LRU、释放即拆、壳 ForEach + defer 队列；**3 控件并发出画/交互**）**；壳 abc **368,812（`1076a700…`）**/headless 24,324（`798b2477…`）、宿主 **297,888（`7b1694d9…`）**、导出 **151**、套件 **584/586 floor 566**；**预签已刷新（#44 件：67,627,789 / `75a40110…`，asset 608782132）**；发布实测 tar **67,680,863 B / `b777d8d8…`**、树 **`db2604d5…`**、sidecar **`85d62a6e…`**、bundle **73,052,763 / `3b3008a4…`**（sdk 锚 **`2abf4fcaa3`**；发布已完成，以 release「## Integrity（kit #44）」与随包校验为准）；更早 = **kit #43**（2026-10-04；#43 = **默认 AOT（5 MAUI hap 全 NativeAOT、`runtime-mode.txt=aot`、无 JIT 运行时；JIT 保形态需 ACL/豁免）+ FRAMEPACING（宿主 present telemetry；17.7 fps 系壳状态轮询伪影、实际 60.00 fps）**；套件 578/580 floor 560、导出 151、abc 356,468（`dd04dad1…`）/24,324、宿主 297,888（`7b1694d9…`）；发布实测 tar **67,638,015 B / `57c7bf44…`**、树 `0c41f071…`、sidecar `bd1f8e33…`、bundle **73,037,790 / `929b7263…`**（sdk 锚 `1c4f21ce13`；预签 67,585,222 / `08412475…`））；更早 = **kit #42**（2026-10-03；#42 = #41 + **JIT 解锁（prctl JITFORT + ICU invariant → JIT 首帧）+ 解释器 rc2b（首帧；`ohos-interpreter-pack-rc2b.tar.gz` 2,410,595/`5974430509…`，asset 606999003）+ FIX-SLICERACE（8/8）+ L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c/镜像扩展**；壳 abc **356,468（`dd04dad1…`）**/headless 24,324、宿主 **297,888（`08abe185…`）**、导出 **151**、套件 **578/580 floor 560**；**预签未刷新（仍 #41 件）**；发布实测 tar **376,256,128 B / `ea4e3b58…`**、树 **`13f3a086…`**、sidecar **`878d05a1…`**、bundle **73,047,352 / `570c0821…`**（sdk 锚 **`35101fe1f5`**；发布已完成，以 release「## Integrity（kit #42）」与随包校验为准）；更早 = **kit #41**（2026-10-03；#41 = #40 + **MULTI-OVERLAY-FULL（双槽 LRU 覆盖层池 + per-slot hybrid invoke/消息 + z-order）+ DEVCOMPAT-DEFAULT（payload 码签重写默认化，enforcing 镜像开箱可装）+ INTERP-FIX（8 MB 栈 + 关写屏障；rc.2 解释器 pack `ohos-interpreter-pack-rc2.tar.gz` 2,409,070 / `34709a94…`）**；壳 abc **356,140（`2a90f0d7…`）**/headless 24,324、宿主 293,792（`8d67def3…`）、导出 150、套件 563/floor 543；**预签刷新至 #41**（376,684,381 / `2075650a…`，asset 606183753）；发布实测 tar **376,036,502 B / `bed460ae…`**、树 **`7ce1946e…`**、sidecar **`2a95e764…`**、bundle **73,040,293 / `c98375a5…`**（sdk 锚 **`2222ba959f`**；发布已完成，以 release「## Integrity（kit #41）」与随包校验为准）；更早 = **kit #40**（2026-10-02；#40 = #39 + **FIX-JSCALL（BlazorWebView IPC 出站 JSCall 枚举/NavigationOptions AOT 扎根 → razor 计数往返 0→1→2 真机；截图 r0/r1/r2）**；壳 abc **342,160（`ffda66da…`）**/headless 24,324（未变）、宿主 293,792（`384e552a…`）（未变）、导出 150、套件 555/floor 535；发布实测 tar **375,836,470 B / `31ab8732…`**、树 **`e950de54…`**、sidecar **`9b051247…`**、bundle **77,750,495 / `434d2b6f…`**（sdk 锚 **`77ffe1dad6`**；发布已完成，以 release「## Integrity（kit #40）」与随包校验为准）；更早 = **kit #39**（2026-10-02；#39 = #38 + **FIX-BACKSIZE（Back 关抽屉：壳 `onBackPress()`→host `host.backPressed`/`ohos_host_register_back_pressed`，导出 150；`BlazorWebView.GetDesiredSize` 覆写）+ FIX-BWVMount（NativeAOT `.razor` 组件挂载出画）**；壳 abc **342,160（`ffda66da…`）**/headless 24,324、宿主 293,792（`384e552a…`）、导出 150、套件 554/floor 534；发布实测 tar **375,765,521 B / `e95eed49…`**、树 **`932e7955…`**、sidecar **`e5fc82de…`**、bundle **77,760,996 / `84d57989…`**（sdk 锚 **`2f1ace0a58`**；发布已完成，以 release「## Integrity（kit #39）」与随包校验为准）；更早 = **kit #38**（2026-10-01；#38 = #37 + **FIX-DISMISS（抽屉外点关闭：`Default`→`Popover`）+ FIX-WVP（Hybrid overlay px→vp / hybrid origin / z-order / 抽屉与切页 suspend）**；壳 abc **341,560（`4f02cb1d…`）**/headless 24,324、宿主 293,792（`4e9f3c3e…`）、套件 550/floor 530、导出 149；**FIX-BACK 波次未入包**（Back 关抽屉/BlazorWebView 尺寸在途，将随下一版）；发布实测 tar **375,641,619 B / `ced5583f…`**、树 **`307004e1…`**、sidecar **`8982fad0…`**、bundle **77,742,112 / `3284e317…`**（sdk 锚 **`ee1163a004`**；发布已完成，以 release「## Integrity（kit #38）」与随包校验为准）；更早 = **kit #37**（2026-10-01；#37 = #36 + **FIX-HOME（NavigationPage arrange 下钻 → Home 页整页出画）+ FIX-ITOUCH（element 坐标：注入/触摸与鼠标同面，页内点击命中）**；套件 544/floor 524、导出 149、abc 339,964/24,324（壳字节不变）、宿主 293,792（`4e9f3c3e…`）；发布实测 tar **375,652,577 B / `3a7259d6…`**、树 **`ab517b57…`**、sidecar **`7db60a77…`**、bundle **77,754,907 / `8abba9b1…`**（sdk 锚 **`d05247b90b`**；发布已完成，以 release「## Integrity（kit #37）」与随包校验为准）；更早 = **kit #36**（2026-10-01；#36 = #35 + **payload 原地直载（AOT 路径真机 BLZ）+ host 预注册缓冲 + 像素 Known 清零 + a11y 渲染帧修复 + rc.2 AOT pack `-r2`**；套件 540/floor 520、导出 149、abc 339,964/24,324、宿主 293,792；发布实测 tar **375,627,841 B / `9eb9cecf…`**、树 **`9764827c…`**、sidecar **`4d7062c3…`**、bundle **77,749,969 / `aeb6888a…`**（sdk 锚 **`b59c3d02e3`**；发布已完成，以 release「## Integrity（kit #36）」与随包校验为准）；更早 = **kit #35**（2026-09-30；W9/W10 并入主线：B2 真机 BLZ 打通（`BLZ_BOOT`/`BLZ_RENDERED`，pid 6157）+ T20 媒体传输层（本机镜像无 MediaKit 属预期）+ T14/T21/T8 余项 + AOT 入口修复（rc.2 AOT 包 shim 缺陷 → 本地钉 rc.1）；套件 540/floor 520、导出 149、abc 339,164/23,516、宿主 293,792；发布实测 tar **375,629,423 B / `419d42e2…`**、树 **`d3b1b317…`**、sidecar **`d7e79d39…`**、bundle **77,754,383 / `acd26821…`**（sdk 锚 **`02a31ef348`**；发布已完成，以 release「## Integrity（kit #35）」与随包校验为准）；更早 = **kit #34**（2026-09-30；rc.2 基线 + MAUI W6/W7/W8（T12/T14/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6；套件 513/floor 493、导出 145）+ AOT v3；发布实测 tar 375,181,367 / `55834aeb…`、树 `d08de3ec…`、sidecar `c03ea23d…`）；更早 = **kit #33**（2026-09-29；Blazor 回归修复/双 hap A/B + TabbedPage/A11Y + W5 470/450 + AOT v2）；更早 = **kit #32**（2026-09-28 发布；WebView 六项接线 + B1 razor 独立资产 + SEC 收口；tester-run **v14**；#31 = Blazor WASM/ArkWeb 组件：第 6 个 hap **`hello-blazorwasm-host-unsigned.hap`**（26,794,931 B / `36010a9c…`，未签名，bundle **`com.example.opendotnet`**）+ **tester-run v13**（`--blazor-probe`，137,113 B / `2caa06bd…`）；整包 tar **207,023,588 B / `f4325d2f…`**、树 **`52e77ee8…`**、sidecar **`7d0cba77…`**、`SHA256SUMS` **16 项 / 1,410 B**；#30：MS-MODE：runtime-mode 打包开关（`-p:OpenHarmonyRuntimeMode=jit|aot|interp`（默认 jit）→ `libs/<abi>/runtime-mode.txt`；宿主 file>manifest>default、`runtime-mode=<v> source=…`；aot 缺库显式回退 JIT；interp 可带 `-p:OpenHarmonyInterpreterPack`）+ tester-run v12（`summary runtime_mode`；清单 interp 的 Run C `run_c_via=manifest`）+ MAPFIX harmony 重切（MapOverlay 真编译：abc 291,628 B/`a637a513…`、tar `9b0506fa…`）；R3 批不变：CoreSpeechKit TTS（`canIUse` + `@kit.CoreSpeechKit` 双门、五 op；无 Kit 时 `IsSupported=false`、调用不抛；真朗读需 HMS 设备 + harmony 壳）+ HUKS-first SecureStorage（设备绑定 AES-256-GCM 密钥、**0 权限**；无 HUKS 时回退文件密钥并如实标注非硬件后备）+ 自绘深度五连（文本编辑/动画/列表/图片/深链）；宿主导出契约 **143/143**；ui/shell abc **281,052 B**（headless 20,916 B）；交互门禁 **387/floor 367 → 391/floor 371**）；R2（#28）、KIT-EXT2（#27）、P2-INTEROP/TASK-MIG/PLAT-GAP（#26）、权限链/Share-Scan 探测降级/AOT 启动路径（#25）不变，并在 #24 的 payload-in-libs 基础上：hap 内 `libs/arm64-v8a/` 原地携带 254 payload + `.dotnet-payload.json`，`dotnet.zip` 回退；整包发布实测 tar **196,992,264 B / `a781c25b…`**、树 **`cc1ca935…`**、sidecar **`a63cd34f…`**（#29 196,990,205 / `e895cc0a…`；以 release「## Integrity（kit #30）」为准）；kit 内强化 verify-kit 自检应报 0 FAIL / 0 WARN，**abc 期望已重锚 `281052`/`20916`**）。2026-09-24 真机里程碑（kit #18 + 测试方 5 项本地修复首次完整运行）见 `docs/plans/2026-09-24-ohos-device-milestone.md`；**stock kit（#22 起，含 #30）尚未上机**，本轮归档即首次复测证据。JIT A/B 与判定表见 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`，kit #25 判定点（权限弹窗文案/Share 面板/Scan 返回/AOT 启动）见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`，kit #26 判定点（新 payload 首次运行/原生桥 ABI/PLAT-GAP 恢复路径）见 `docs/plans/2026-09-26-ohos-tester-handoff-kit26.md`，kit #27 增量判定点（无 HMS 降级不抛/新 payload 首次运行）见 `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md`，kit #28 增量判定点（Map 覆盖层/LiveView/AOT 启动桥/解释器）见 `docs/plans/2026-09-26-ohos-tester-handoff-kit28.md`，kit #29 增量判定点（TTS/HUKS/模式矩阵/a11y/自绘深度）见 `docs/plans/2026-09-28-ohos-tester-handoff-kit29.md`，kit #30 增量判定点（runtime_mode 标记与优先级、模式矩阵清单路线、MAPFIX Map 点亮）见 `docs/plans/2026-09-28-ohos-tester-handoff-kit30.md`。

## 1. 它做什么

| 步骤 | 内容 | 触发参数 |
|---|---|---|
| 0 | 定位 kit（解压目录或 `.tar.gz`）：sidecar `sha256sum -c` → `sh verify-kit.sh`（含内容树摘要，P16 复用已校验摘要）→ 可选 `--expect-tree-digest` 绑定解压内容 | 无（总是执行，纯本地）|
| 1 | `hdc install -r` 主 hap；记录安装结果码并给出 `9568344` / `9568297` / `E00C001` 提示 | `--install` |
| 2 | `aa start -b <module.json 里的 bundleName> -a EntryAbility`，数秒后用 `pidof`（回退 `ps -ef`）判定进程存活 | `--start` |
| 3 | `hilog -r` → 开录 →（若同时加 `--start`）启动应用 → 录 N 秒 → 按关键字过滤 | `--capture [N]`（默认 30 秒）|
| 4 | 安装并运行 `probe1..probe4`，逐个抓 `PROBE1..PROBE4` 行（含各自的 hilog 原文）| `--probes <dir>` |
| 5 | 采集 hilog/探针日志、`module.json`、`param get` + UDID、kit 哈希、`summary.txt`，打包 `tester-report-<时间戳>.tar.gz` | 有设备动作时总是执行 |

`--device <id>` 会让每条 hdc 命令都带 `-t <id>`；`--out <dir>` 改报告目录（默认 `./tester-report`）；`--hap <hap>` 用指定 hap 代替 kit 默认包（可重复，主包取第一个）。

> **verify-kit 深度断言（kit #23 起；旧包会 FAIL 属预期）**：kit #23 包内的 `verify-kit.sh` 除 `SHA256SUMS` 校验与 5 hap 摘要外，还逐 hap 断言：`resources.index` 存在且非空（缺失/0 B = FAIL）、`ets/modules.abc` 的 PANDA 版本 `13.0.1.0`（FAIL）与当前壳大小（**kit #29 = `281052` UI/壳、`20916` headless（#30 沿用）**；`#28` 的 `264136`、`#27` 的 `245412`、`#25/#26` 的 `234620` 旧值会 FAIL，属脚本预期；`--expected-abc` 固定后 FAIL）、`libs/arm64-v8a` 恰 `.so` 数随运行时模式（JIT 线 14 个；**#44 AOT 线 3 个**（app.so + host + `libc++_shared.so`），无 libcoreclr/libhostfxr/libclrjit）、`resources/rawfile/dotnet.zip` 不含 `.so`（FAIL）且 JIT **254** 项 / **AOT 9 项**（漂移 WARN；#22 为 253）、宿主 ELF 的 `DT_NEEDED` ⊆ `host-deps.conf` 白名单且无 `libhostfxr.so`、动态未定义符号不触 IME/NativeWindow/Vibrator/Sensor/Location/NetConn/AT/ImageSource/Pixelmap/`OH_LOG_` 名单（命中 = FAIL）。**kit #24 起再加 payload-in-libs 断言**：`libs/arm64-v8a/.dotnet-payload.json` 必须存在且自洽（入口程序集已入 libs、条目数与实际文件数一致、`payloadEntries == zipEntries`、`zipSha256` 描述打包字节；`-p:OpenHarmonyHapPayloadInLibs=false` 的包按设计 FAIL）。**kit #25 起 `resources.index` 另有 ≤ 2 KiB 上限（1588/1780），并在本地自检里绑定 abc/dotnet.zip 期望值**（kit #25 包内 `verify-kit.sh` = 53,999 B / `74852e0b…`；kit #26 沿用；**kit #27 同一修订把 abc 期望重锚 `245412`，`ohos-workload 898f4a1`；kit #28 再重锚 `264136`，`ohos-workload 112b6e9`，包内 53,999 B / `8f855ad9…`（#28 修订）；kit #29 重锚 `281052`/`20916`（#30 沿用）；#35 重锚 `339164`/`23516`、#36 重锚 `339964`/`24324`（#37 沿用）、#38 重锚 `341560`/`24324`、#39 重锚 `342160`/`24324`（#40 沿用）、#41 重锚 `356140`/`24324`、#42 重锚 `356468`/`24324`、**#44（AOT 线）重锚 `368812`/`24324` + `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit（#43 为 `356468`/`24324`）**；以包内脚本为准）**）。判定：FAIL → 退出码 1；WARN → 打印但保持 `KIT OK`。**对已发布的 kit #22 上述（#23 版）断言全部通过**（index 579/707 B、abc 212952 B、libs=14、DT_NEEDED=5、denylist 0、dotnet.zip 253/0）；**对 kit #21 及更早的包，新 verify-kit 会明确报 FAIL（缺 index、旧宿主 NEEDED、denylist 命中）并以 1 退出 —— 那是旧包的真实缺陷，不是新脚本误报**；检修旧包请用该包自带的 `verify-kit.sh`，要得到强化结果请用 kit #22+（当前 #30）。新增参数 `--expected-abc <bytes[,bytes]>`、`--host-deps <file>`（env `KIT_EXPECTED_ABC` / `KIT_HOST_DEPS`）；`--anchor`/`--anchor-file`/`--tree-digest`/`--expect-tree-digest` 语义不变。校验器自身有本地 selftest（交付方仓库脚本 `scripts/selftest-verify-kit.sh`，不需要设备/binutils；kit 内不含该脚本；kit #25 批次 72 检查 / 0 失败、kit #27/#28 重锚后复跑 72/0）。

## 2. 下载与自检

```sh
base=https://github.com/springmin/sdk-ohos/releases/download
curl -L -O "$base/device-test-kit/tester-run.sh"
sh tester-run.sh --help
# 资产摘要以 release 资产页 / API 为准（本文不写死哈希）：
gh api repos/springmin/sdk-ohos/releases/tags/device-test-kit \
  --jq '.assets[] | select(.name=="tester-run.sh") | .digest'
sha256sum tester-run.sh
```

## 3. 一条命令（完整一轮）

```sh
base=https://github.com/springmin/sdk-ohos/releases/download
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz"
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz.sha256"
sh tester-run.sh --kit-tar ./device-test-kit.tar.gz --install --start --capture 30
```

- 建议同时用发布说明「Integrity」的 tree sha256 绑定解压内容：加 `--expect-tree-digest <hex>`（本轮 tree = `0a7a3215…`）。
- **API 20 波段设备**用 api20 包（先解压 kit）：`sh tester-run.sh --kit-dir ./device-test-kit --install --hap ./device-test-kit/hello-maui-app-api20.hap`。
- **启动崩溃排查**（探针 hap 是未签名的，先按 `自签说明.md` 自签到位）：`sh tester-run.sh --kit-dir ./device-test-kit --probes ./probes`。

## 4. 常用组合

| 目的 | 命令 |
|---|---|
| 只看计划（安全，不碰设备）| `sh tester-run.sh --kit-tar ./device-test-kit.tar.gz` |
| 完整一轮 | `sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 30` |
| 只录 hilog 60 秒（自己操作应用）| `sh tester-run.sh --kit-dir ./device-test-kit --capture 60` |
| 只跑 4 个探针 | `sh tester-run.sh --kit-dir ./device-test-kit --probes ./probes` |
| 显式卸载（主应用 + 4 个探针）| `sh tester-run.sh --kit-dir ./device-test-kit --uninstall --probes ./probes` |
| 多设备环境指定目标 | 以上任一命令再加 `--device <hdc list targets 里的 id>` |

## 5. 它执行的命令（精确）

以下 `<D>` 表示 `hdc`，给了 `--device <id>` 时表示 `hdc -t <id>`：

```sh
# 0 本地校验
( cd <kit.tar.gz 所在目录> && sha256sum -c <kit>.tar.gz.sha256 )
tar xzf <kit>.tar.gz -C <临时目录>
( cd <kit> && sh verify-kit.sh --tree-digest [--expect-tree-digest <hex>] )

# 1/4 每个 hap（主包、--hap、以及 probe1..probe4）
<D> install -r <hap>

# 2 启动与存活
<D> shell aa start -a EntryAbility -b <bundle>
<D> shell pidof <bundle>            # 为空时回退 <D> shell ps -ef | grep <bundle>

# 3 hilog（录制 N 秒后停止；先 -r 清缓冲）
<D> shell hilog -r
<D> hilog > <out>/hilog/hilog-full.txt &
grep -E 'hellomaui|maui|dotnet|openharmonyhost|AppKilledReporter|JsError|appspawn|PROBE' \
  hilog-full.txt > hilog-filtered.txt

# 5 设备信息与 UDID
<D> shell param get const.product.model / const.product.brand / … / const.build.characteristics
<D> shell bm get -u

# 仅 --uninstall（显式）
<D> uninstall <bundle>              # 加了 --probes 时也卸载 4 个 probe 包
```

`v6r2` 起在设备窗口内自动采集（v7/v8 沿用；无需手工 grep）：`hilog -t kmsg` → `kmsg/`、`xpm_mode`/`require_signatures`、`SoInfoSegment` 命中数，以及 app-lib 证据 ——
`hilog/hilog-applib.txt`（`SetAppLibPath|appLibPathKey|NativeLibPath|lib path`）、`hilog/hilog-dlopen.txt`（`dlopen|cannot find library|openharmonyhost`）、
`device/app-libs-arm64.txt`（`ls -l /data/storage/el1/bundle/libs/arm64/`）。判读要点：`appLibPathKey: <bundle>/<module>` 出现 = 模块级 app-lib key 已注册（`libIsolation` 生效）；
`[openharmony-host] … bound via alias '…'` 出现 = 宿主加载并绑定到该别名；首帧成功信号 = `registerXComponent=function`、首帧出现、无 `Load native module failed`。
`--extra-probes <dir>` 可把 importprobe/importb/importd 等载荷按与 P1–P4 相同的「装 → 启 → 录」流程一并采集。

`v7` 起再增三类采集（v8 沿用；全部缺失容忍，不改退出码）：

- **bootstrap/rawfile 失败特征** → `hilog/hilog-bootstrap.txt`：对所有已录制 hilog 窗口再过滤 `GetRawFileContent|bootstrap failed|bootstrap retry|BusinessError|900002|900003|ZIP entry|destination path|Load native module failed|symbol not found|cannot find library|Museum|MUSL-LDSO|check ns accessible`；计数写入 `summary.txt` 的 `bootstrap_capture`（ok/not_captured）、`bootstrap_lines`、`bootstrap_errors`、`rawfile_errors`、`libload_errors`（无录制窗口记 `<unavailable>`）。
- **设备侧 payload 状态** → `device/payload-files.txt`（`ls -l <filesDir>/` 中 `dotnet|payload` 行）与 `device/payload-marker.txt`（`<filesDir>/dotnet.marker` 首行）；`summary.txt` 记 `payload_present`（yes/no）、`payload_files`（行数）、`payload_marker`（ok/empty）。**kit #24 起 payload 在 hap `libs/arm64-v8a/` 原地运行**，这些键只反映回退布局的 filesDir 解包：`payload_present=no` 属常态；本地 kit 自检的 `payload=yes|no`（marker 是否在包内）才是 payload-in-libs 信号。
- **kit hap 自检**（本地，dry-run 也打印，设备轮才归档）→ `meta/kit-selfcheck.txt`：逐 kit hap 的 `resources.index` 有无/大小、`libs/arm64-v8a` 计数与 `.dotnet-payload.json`（`payload=yes|no`）、`ets/modules.abc` 头版本；`summary.txt` 记 `kit_index_ok`（yes/no）。
- **exec-memory 证据**（v8 起；kit #24 起，kit #30/#31 沿用）→ `hilog/hilog-execmem.txt`：把同一批 hilog 窗口按 `OHOS_DOTNET probe:|xwe=|runtime-mode=` 过滤，保留 `OHOS_DOTNET probe: 1=… 2=… 3=… 4=…` 与 `[openharmony-host] … xwe=0|1 source=…` 行（v9 起同一文件还含 `aot=`/`interp=` 路由行、v12 起含 `runtime-mode=` 行）；`summary.txt` 记 `execmem_capture`（ok/not_captured）、`execmem_lines`（0 = 未捕获，加长 `--capture` 重跑）。判定表见 `docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §3（#29 见 `docs/plans/2026-09-28-ohos-tester-handoff-kit29.md` §3）与 `docs/plans/2026-09-27-ohos-runtime-mode-determination.md`（JIT 表沿用 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md` §5）。

**判读建议（v7–v14 新键；均为提示性，不改退出码）**：

| 键/文件 | 含义与处置 |
|---|---|
| `bootstrap_errors>0` / `rawfile_errors>0` / `libload_errors>0` | bootstrap/rawfile/库加载路径出现失败特征（原文在 `hilog/hilog-bootstrap.txt`，请随归档回传）。常见对照：`GetRawFileContent failed, name is empty` + `kit_index_ok=no` = hap 缺 `resources.index`（早于 kit #22 的旧包，换当前 kit）；`ZIP entry`/`destination path` = 解压/路径问题；`Load native module failed`/`symbol not found`/`cannot find library` = 宿主/依赖加载问题（转 P1–P4 阶梯）|
| `kit_index_ok=no` | 当前 kit 至少一个 hap 缺 `resources.index`：换 **kit #22+（当前 #26）** 再测（这类包会在托管 bootstrap 前失败）。`<unavailable>` = 本机缺 `python3`/`unzip` 或 kit 无 hap，自检未完成，不影响安装流程 |
| `payload=no`（kit 自检） | 包内 hap 缺 `.dotnet-payload.json`（该 hap 会回退到 data 目录解包，在被 namespace 拒绝的设备上必然起不来）：换当前 kit；`verify-kit.sh` 对此会直接 FAIL |
| `payload_present=no` | **kit #24 起属正常**（payload 在 hap `libs/` 原地运行，本键只看 `<filesDir>/dotnet`/`dotnet.marker` 回退布局）；回退布局/旧包首次启动前也为 no，已启动仍为 no（尤其伴随 `bootstrap_errors>0`）= payload 未解包成功 |
| `execmem_lines=0` | 未捕获到 `probe:`/`xwe=` 行（录制窗口未覆盖首次启动或 ROM hilog 缓冲问题）：加长 `--capture` 重跑；无此行不能判定 JIT 可用性 |
| `--blazor-probe` 报 `boot=no`（而 `rendered=yes`） | **先核对 hilog 缓冲再判失败**：小缓冲（如 512K）在噪声大的机器上只保留 ≈4–5 s，4 s 探针窗口会把 `BLZ_BOOT`/nonce 滚出 → 误报。本机实测（2026-09-30）：512K 环丢 `BLZ_BOOT`；临时 `hilog -G 16M -t app,core` 重跑后两变体全绿（跑完已还原 512K）。**tester 机缓冲待核对**——必要时临时调大缓冲（事后还原），或先 `--capture 60` 流式复核再判 |

## 6. 回传什么

脚本最后会打印归档绝对路径：

```sh
# 形如 ./tester-report-<YYYYmmdd-HHMMSS>.tar.gz，旁边有同名 .sha256
sha256sum -c ./tester-report-<时间戳>.tar.gz.sha256
```

把 `tester-report-<时间戳>.tar.gz`（连同 `.sha256`）通过**收到 device-test-kit 的同一渠道**（邮件/IM/工单）发回给交付方；GitHub 用户可在 `springmin/sdk-ohos` 开 issue 附归档。
归档内固定包含：`summary.txt`（机器可读，`KEY=value`：`script_version`（v14 = `14`；v13 = `13` 为 #31 值；v12 = `12` 为 #30 值）、kit/tree 摘要、`main_hap_sha256`、bundle、安装/启动/存活结果、每条 hilog 行数、app-lib/dlopen 证据行数、`bootstrap_capture`/`bootstrap_lines`/`bootstrap_errors`/`rawfile_errors`/`libload_errors`/`payload_present`/`payload_files`/`payload_marker`/`kit_index_ok`、**`execmem_capture`/`execmem_lines`（v8 / kit #24）**、**`aot_route`/`interp_mode`（v9+）、`runtime_mode`（v12+）**、**`a11y_*`（v11 `--a11y-probe`）**、`probe1..probe4` 结果、`failures`）；**v13 `--blazor-probe`** 另落 `blazor-hilog.txt`（失败时）并在回传里附 Blazor 两标记行（`BLZ_BOOT`/`BLZ_RENDERED`）、`hilog/`（含 `hilog-applib.txt`、`hilog-dlopen.txt`、`hilog-bootstrap.txt`、**`hilog-execmem.txt`**）、`probes/`、`kmsg/`、`device/param-get.txt`、`device/udid.txt`、`device/app-libs-arm64.txt`、`device/payload-files.txt`、`device/payload-marker.txt`、`meta/module.json`、`meta/SHA256SUMS`、`meta/kit-hap-sha256.txt`、`meta/kit-selfcheck.txt`；（v10+ `--mode-matrix` 轮另出 `mode-matrix/summary.txt` 与逐 Run 日志，v11 `--a11y-probe` 另出 `a11y/`，v12 起矩阵摘要含 `run_*_runtime_mode` 与 `run_c_via`）。v8+ 的字段/文件对旧版归档是超集（v7 起 bootstrap/payload/kit 自检，v8 增 `hilog-execmem.txt` 与两个 execmem 键，v9+ 增路由键/矩阵/a11y，v12 增 `runtime_mode`/`runtime-mode=` 行），解析方按 `KEY=value` 读即可。
若安装报 `9568344`，归档里的 UDID 可直接用于重签；`summary.txt` 的 `main_install_result=code:9568344` 即为凭据。

## 7. 安全说明

- **默认 dry-run**：不加 `--install` / `--uninstall` / `--start` / `--capture` / `--probes`，只做本地 kit 校验并打印计划，不创建报告目录、不打包。
- **无设备拒绝执行**：`hdc list targets` 为空（或 `--device` 指定的 id 不在列表）时——带动作参数立即退出 3；不带动作参数则只做本地校验、打印计划后退出 3。
- **卸载只认 `--uninstall`**，且只卸载主应用（给 `--probes` 时加 4 个探针包），绝不隐式卸载。
- `--kit-tar` 缺 sidecar 时**拒绝解压**（fail closed）；校验失败先重新下载，不要带病安装。
- 探针 hap 未签名，需要先自签（`自签说明.md`）；脚本不做签名、不生成密钥、不上传任何东西。
- `--extra-probes <dir>`（可重复，或逗号分隔多个目录；重复目录只处理一次）：把目录内全部 `*.hap`（importprobe a–c、importb/importd 载荷等）按 P1–P4 相同的「装 → 启 → 录」流程采集，命中行并入 `probes/probe-all-lines.txt`。

## 8. 退出码

| 码 | 含义 |
|---|---|
| 0 | 成功（有设备时的完整一轮，或 dry-run 计划打印完成）|
| 1 | 有步骤失败：归档仍会生成，详情见 `summary.txt` 的 `failures` 与各步骤键 |
| 2 | 用法错误（缺参数值、路径不存在、找不到 kit 等）|
| 3 | 无设备 / 拒绝执行（含无设备时的 dry-run）|

## 9. 相关文档

- 快速上手（一页版）：`docs/plans/2026-09-20-ohos-tester-quickstart.md`（包内名 `快速开始.md`）
- kit #29 交接（R3 CoreSpeechKit TTS / HUKS-first SecureStorage / tester-run v11 / 自绘深度五连判定点）：`docs/plans/2026-09-28-ohos-tester-handoff-kit29.md`
- **kit #47 交接（a11y Flyout 节点数（FIX-A11YFLYOUT：nodeCount 1→70）+ 抢占原文（FIX-PREEMPT-RAW：`[maui-capacity]`）；承 #46 INTERP-DRAW2 + FIX-A11YBUTTON 与 #45 自动释放/INTERP-RENDER/动态槽/AOT/FRAMEPACING；判定点；当前）：`docs/plans/2026-10-05-ohos-tester-handoff-kit47.md`**
- **kit #45 交接（上一版：自动释放（FIX-AUTODISCONNECT：Remove→`web slot destroy`→re-add→`web slot create`+交互恢复）+ INTERP-RENDER（interp 22.0→30.1 fps / CPU −13pt；JIT/AOT 不变）；承 #44 动态槽/AOT/FRAMEPACING）：`docs/plans/2026-10-04-ohos-tester-handoff-kit45.md`**
- **kit #44 交接（上一版：动态槽（MAX/HOT 4/2 + 按需创建/释放销毁 + 3 控件并发）；默认 AOT（承 #43；含 FRAMEPACING））：`docs/plans/2026-10-04-ohos-tester-handoff-kit44.md`**
- **kit #42 交接（JIT 解锁（JITFORT+ICU invariant）→ 三路径首帧；解释器 rc2b 首帧；FIX-SLICERACE 8/8；判定点；更早）：`docs/plans/2026-10-03-ohos-tester-handoff-kit42.md`**
- **kit #41 交接（MULTI-OVERLAY-FULL + DEVCOMPAT-DEFAULT（enforcing 开箱可装）+ INTERP-FIX；上一版）：`docs/plans/2026-10-03-ohos-tester-handoff-kit41.md`**
- **kit #40 交接（FIX-JSCALL（`JSCall` 枚举/NavigationOptions AOT 扎根 → razor 计数往返 0→1→2 真机）；上一版）：`docs/plans/2026-10-02-ohos-tester-handoff-kit40.md`**
- **kit #39 交接（FIX-BACKSIZE（Back 关抽屉 + BlazorWebView 真实尺寸）+ FIX-BWVMount（NativeAOT `.razor` 挂载出画）；上一版）：`docs/plans/2026-10-02-ohos-tester-handoff-kit39.md`**
- **kit #38 交接（FIX-DISMISS（抽屉外点关闭）+ FIX-WVP（Hybrid 出画/bridge/挂起）；上一版）：`docs/plans/2026-10-01-ohos-tester-handoff-kit38.md`**
- **kit #37 交接（FIX-HOME（Home 整页出画）+ FIX-ITOUCH（注入/触摸 element 坐标 = 与鼠标同面；tab 切页/页内点击可直接注入复测）；上一版）：`docs/plans/2026-10-01-ohos-tester-handoff-kit37.md`**
- **kit #36 交接（payload 原地直载（AOT 路径真机 BLZ）+ host 预注册缓冲 + 像素 Known 清零 + a11y 修复 + rc.2 AOT pack `-r2`；上一版）：`docs/plans/2026-10-01-ohos-tester-handoff-kit36.md`**
- **kit #35 交接（W9/W10：B2 真机 BLZ 打通 + T20 媒体传输层 + T14/T21/T8 余项 + AOT 入口修复；上一版）：`docs/plans/2026-09-30-ohos-tester-handoff-kit35.md`**
- **kit #34 交接（rc.2 基线 + MAUI W6/W7/W8 + AOT v3 + 本机直测；上一版）：`docs/plans/2026-09-30-ohos-tester-handoff-kit34.md`**
- kit #33 交接（Blazor 回归修复/双 hap A/B + TabbedPage/A11Y + W5 470/450 + AOT v2；上一版）：`docs/plans/2026-09-29-ohos-tester-handoff-kit33.md`
- Blazor A/B 与 MAUI 主体一页卡（承 #33）：`docs/plans/2026-09-29-ohos-blazor-regression-retest-card.md`
- kit #32 交接（WebView 六项接线 / B1 razor / SEC 收口；上一版）：`docs/plans/2026-09-28-ohos-tester-handoff-kit32.md`
- kit #31 交接（Blazor WASM/ArkWeb 组件 / tester-run v13 `--blazor-probe` / `BLZ_*` 判读；历史）：`docs/plans/2026-09-29-ohos-tester-handoff-kit31.md`
- kit #30 交接（MS-MODE：runtime-mode 打包开关 / tester-run v12 / MAPFIX harmony 重切判定点；历史）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md`
- kit #28 交接（R2 Map 覆盖层 / LiveView / AOT 启动桥 / 解释器实验判定点；历史）：`docs/plans/2026-09-26-ohos-tester-handoff-kit28.md`
- kit #27 交接（KIT-EXT2 + 无 HMS 降级不抛（Push/Account/Map）/新 payload 首次运行判定点；历史）：`docs/plans/2026-09-27-ohos-tester-handoff-kit27.md`
- kit #26 交接（P2-INTEROP/TASK-MIG/PLAT-GAP + 新 payload 首次运行判定点；历史）：`docs/plans/2026-09-26-ohos-tester-handoff-kit26.md`
- kit #25 交接（权限弹窗文案 / Share 面板 / Scan 返回 / AOT 启动判定点；历史）：`docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`
- kit #24 交接（JIT A/B、`probe:` 判定表、NativeAOT 主路线）：`docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`
- 真机操作手册：`docs/plans/2026-09-21-ohos-device-run-playbook.md`（包内名 `真机操作手册.md`）
- 完整验收清单：`docs/plans/2026-09-19-ohos-hap-acceptance-for-testers.md`（包内名 `验收说明.md`）
- 启动崩溃探针 P1–P4：`docs/plans/2026-09-21-ohos-crash-probes.md`
- 回传模板：`docs/plans/2026-09-21-ohos-device-report-template.md`
