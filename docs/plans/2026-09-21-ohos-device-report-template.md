# 真机回传模板（下一轮设备测试）

> **2026-10-05 更新（kit #48，当前）**：kit #48 = **kit #47（FIX-A11YFLYOUT + FIX-PREEMPT-RAW；承 #46 INTERP-DRAW2/FIX-A11YBUTTON） + R2R/JIT 启动（CG2-R2R） + AOT 首帧省时（AOT-STARTUP） + 帧率投票 60（FPS48） + 多窗 S（MULTIWINDOW-S） + FIXRR**：①**CG2-R2R**（sdk-ohos `crossgen2-packs-11.0.0-rc.2`，43,792,647 / `6bb8a375…`，folder feed）：JIT `PublishReadyToRun=true` 冷启 **1031→710 ms（−31%；n=3）**、in-proc present 575→307；interp 不执行 R2R 原生码且付 +350 ms → host 在 `interp=3` 置 **`DOTNET_ReadyToRun=0`**（FIXRR，ow `08ccbe8`；runtime 对 `InterpMode>=2` 本就强制 `fReadyToRun=false`，显式行同效；JIT/混合 1/2 不变）；②**AOT-STARTUP**（ow `22ca602`/`372c35e`/`92ea222`）：隐藏 ArkWeb 覆盖层**首用才挂载** + 宿主对相同 app-context **跳过 surface 重放**，CEF 初始化（~240 ms）移出首帧路径 → AOT AMS→首帧 **796→534 ms（−262，−33%）**、Main→首帧 386→151、attach→surface 239→13；JIT/interp 不回归；③**FPS48**（ow `67a1de8`）：宿主注册 XComponent 时声明期望 60 Hz（`{60,60,60}`）→ RS 60/30 仲裁消失，第二重绘窗口干扰态 5s 窗均值 **46.2→60.0 fps**（清净态 60.1；app 每帧 work 不变）；④**MULTIWINDOW-S**（maui `ed02203bfd` + ow `c5df1de`）：壳声明 `supportWindowModes` fullscreen/split/floating + `windowSizeChange`/`freeWindowModeChange` 订阅；切片 `CanArrangeSurface`（Created/Changed 尺寸>0 重排、Destroyed/0x0 保末帧）→ 真机 2in1 最大化 **2090×1394→3120×1955**（`surface state=Changed 3120x1885` → `canvas presented`）；套件 +2；⑤kit #47 全部保留（FIX-A11YFLYOUT nodeCount 1→70、FIX-PREEMPT-RAW `[maui-capacity]`、INTERP-DRAW2 60.1 fps、FIX-A11YBUTTON、AUTODISCONNECT、INTERP-RENDER、动态槽 MAX/HOT 4/2、AOT 默认、FRAMEPACING 60.00 fps）；**预签已刷新至 #48**（67,651,331 / `2f2f4c40…`，asset 612061141；sidecar 88 B / `50a1f38e…`，asset 612062470）；壳 abc **375,268（`9cd2b4c3…`）**/24,324、宿主 **297,888（`319db8e5…`，导出 151/151）**、套件 **599/601 floor 581**；发布实测 tar **67,735,148 / `5c22704f…`**、树 `6b2b493c…`、sidecar `1c51cdbc…`、`SHA256SUMS` 18 项 / 1,600 B / `a05caba0…`；bundle **73,053,084 / `3b62cee2…`**（sdk 锚 **`767c03ee71`**）；CI 5/5 @ `c42cfa43` + sdk run `37286847476`；数字以 release「## Integrity（kit #48）」与随包校验为准；判定点 = `docs/plans/2026-10-05-ohos-tester-handoff-kit48.md`。
>
> **2026-10-05 更新（kit #47，上一版）**：kit #47 = **kit #46（INTERP-DRAW2 + FIX-A11YBUTTON）+ FlyoutPage 无障碍（FIX-A11YFLYOUT）+ 抢占原文导出（FIX-PREEMPT-RAW）**：①**FIX-A11YFLYOUT**（maui 切片 `d5384d6cc3`）：`PushChildren` 补 `FlyoutPage.Detail`（恒入树）/`FlyoutPage.Flyout`（仅 `IsPresented`）分支（rc.1 FlyoutPage 非 `IContentView`，旧分支覆盖不到 → 只发布根）；headless 断言 `a11y-flyout detail/panel` + 负控制红，真机 `--a11y-probe` **nodeCount 1→70**；②**FIX-PREEMPT-RAW**（ohos-workload `f538c84`）：壳 `pollManagedStatus` 把 `dotnet-status.txt` 新增段中含 `overlay preempted/restored/replay` 的行以 **`[maui-capacity]`** 前缀直写 hilog（trim 时整文件回退）→ 真机低噪声复放取到 5 行原文（`preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`）；③承 #46：**INTERP-DRAW2**（面外剔除：interp draw 14.4→9.4 ms、33.9→60.1 fps、每帧 CPU −27%；JIT 无回归）、**FIX-A11YBUTTON**（自检按钮左下角 + 覆盖层之上，两态真机可达 `[523,1622][607,1668]`）；④承 #45：自动释放（FIX-AUTODISCONNECT）/INTERP-RENDER/动态槽（MAX/HOT 4/2 + 3 控件）/默认 AOT/FRAMEPACING 与 #42… 全部修复；**预签已刷新至 #47**（67,639,132 / `f58c4906…`，asset 610975429；sidecar 88 B / `c95344ac…`，asset 610976421）；壳 abc **370,240（`4b439e83…`）**/24,324、宿主 **297,888（`7b1694d9…`，导出 151/151）**、套件 **593/595 floor 575**；发布实测 tar **67,706,719 / `3d6bb58b…`**、树 `0f266636…`、sidecar `4adb0b60…`、`SHA256SUMS` 18 项 / 1,600 B / `6bbc2235…`；bundle **73,059,625 / `27c54c62…`**（sdk 锚 **`266b196106`**）；CI 5/5 @ `3de9a95fe0` + sdk run `37245230111`；数字以 release「## Integrity（kit #47）」与随包校验为准；判定点 = `docs/plans/2026-10-05-ohos-tester-handoff-kit47.md`。
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

> 复制本页填空白；能填就填，填不了写「不可得 + 原因」。取证命令出处：`docs/plans/2026-09-21-ohos-device-crash-diagnostics.md`（安装/启动/hilog/jscrash/dotnet-status）；探针 P1–P4 与 14 库自检：`docs/plans/2026-09-21-ohos-crash-probes.md`。本页只采集，不重复两文内容。

## 0. 快速事实

| 项 | 值 |
|---|---|
| 设备 UDID（`hdc shell bm get -u`） | `<...>` |
| kit tar.gz sha256（实测） | `<...>`（kit #35 = tar **375,629,423 B / `419d42e2…`**、tree **`d3b1b317…`**、sidecar **`d7e79d39…`**、`SHA256SUMS` 17 项 / 1,517 B / `2dd447a7…`（7 hap）；#34 = tar **375,181,367 B / `55834aeb…`**、tree **`d08de3ec…`**、sidecar **`c03ea23d…`**、`SHA256SUMS` 17 项 / `94fedc66…`；#33 = tar **218,138,546 B / `38e4d57a…`**、tree **`064cb001…`**、sidecar **`8297363e…`**、`SHA256SUMS` 17 项 / 1,517 B / `37031b9a…`（7 hap）；kit #32 = tar **207,114,608 B / `8f690949…`**、tree **`645879bc…`**、sidecar **`344760e7…`**；#31 = tar **207,023,588 B / `f4325d2f…`**、tree **`52e77ee8…`** 仅作对照；见 release「## Integrity（kit #34）」/`docs/plans/2026-09-30-ohos-tester-handoff-kit34.md` 文首；`tester-run.sh` v14 会写入 `meta/kit-hap-sha256.txt` 与 `summary.txt` 的 `main_hap_sha256`） |
| tree digest（实测） | `<...>`（期望 = release「## Integrity（kit #35）」的 tree sha256，kit #35 = **`d3b1b317…`**（#34 = `d08de3ec…`；#33 = `064cb001…`；#32 = `645879bc…`、#31 = `52e77ee8…` 仅作对照）；`summary.txt` 的 `tree_digest` 同值） |
| `tester-run.sh` 版本（`summary.txt` 的 `script_version`） | `<...>`（当前 **v14** = `14`（140,197 B / `a174fcd0…`、asset 595131362）；v13 = `13` 为 #31 值；v12 = `12 (2026-09-28)` 为 #30 值） |
| 应用版本（`最终状态.md`「发布物」原文） | `<...>`（kit #35 = rc.2 线（SDK 同 #34）；#34 = rc.2 线（SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`）；#32 及以前 = `1.0.0-preview.24`） |

> 里程碑背景：2026-09-24 kit #18 + 测试方 5 项本地修复后设备首次完整运行（`managed app hello-maui-app.dll started (UI shell)`）；
> **stock kit（#22 起；#23 为同负载工具刷新、#24 为 payload-in-libs 正式版、#25 为权限链 + Share/Scan 探测 + AOT 启动路径、#26 为 P2-INTEROP/TASK-MIG/PLAT-GAP 收口、#27 为 KIT-EXT2、#28 为 R2、#29 为 R3、#30 为 MS-MODE、#31 为 Blazor WASM/ArkWeb 组件）的首次设备复测就是本轮**，判定点（宿主加载 / bootstrap / 里程碑回归）见 `docs/plans/2026-09-24-ohos-device-milestone.md` §6；#25 判定点见 §4d，#26 增量判定点见 §4e，#27 见 §4f，#28 见 §4g，#29 见 §4h，#30 见 §4i，#31 见 §4j，#32 见 §4k，#33 见文首更新块，#34 见 §4l。

## 1. 下载与校验

```sh
base=https://github.com/springmin/sdk-ohos/releases/download   # 下载时间/来源：<YYYY-MM-DD HH:MM 时区；release 或 workload-latest 镜像>
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz"       # 以及 .tar.gz.sha256
sha256sum -c device-test-kit.tar.gz.sha256                       # 结果：<OK / 失败原文>
sha256sum device-test-kit.tar.gz                                 # 写入 kit-sha256.txt：<实测 sha256>
mkdir -p device-test-kit && tar xzf device-test-kit.tar.gz -C device-test-kit && cd device-test-kit
sh verify-kit.sh --anchor-file ../device-test-kit.tar.gz
sh verify-kit.sh --expect-tree-digest <上面的 tree digest>
# 版本原文（最终状态.md / README-交付说明.md「构建基线」）：<...>｜校验结论：<KIT OK / FAIL/WARN 原文>
```

## 2. 重签（三选一）

- [ ] A. 直接用 kit 内已签 hap（profile 绑定示例 UDID；报 `9568344` 即未绑定你的设备）
- [ ] B. 自签：用你自己的证书（p7b/UDID）；命令原文：`<...>`（见包内 `自签说明.md` / `签名与UDID指南.md`）；重签后 hap 名 + sha256（可选）：`<name.hap  sha256>`
- [ ] C. 外部预签：把 **p7b + p12 + cer + keyAlias** 走安全通道发回，由我方按你的 UDID 预签 —— 命令示例：`sh scripts/sign-for-device.sh --external --profile <你的.p7b> --key <你的.p12> --cert <你的.cer> --key-alias <alias> --pwd-input-mode --expect-udid 60CF7B27…`（UDID 换成你的；p7b 的 `debug-info.device-ids` 必须含它，fail closed）。

## 3. 安装

```sh
hdc install <你的 hap 路径>          # 期望 install bundle successfully；失败贴原文（如 9568344 ...）
hdc shell bm dump -a | grep -i <bundleName>          # 确认已安装
hdc shell param get const.product.model              # 机型
hdc shell param get const.product.software.version   # 系统版本
hdc shell param get const.ohos.apiversion            # API level
```
- bundleName：`<实际安装的 bundleName>`；安装结果：`<成功 / 错误码 + 原文>`；机型/系统版本/API：`<...>` / `<...>` / `<...>`

## 4. 启动

```sh
hdc shell hilog -r && hdc shell hilog > hilog-crash.txt   # 先清缓冲、开录
hdc shell aa start -a EntryAbility -b <bundleName>        # 另一终端；结果：<success 或错误码 + 原文>
grep -inE "hellomaui|maui|dotnet|openharmonyhost|AppKilledReporter|appspawn|PROBE" hilog-crash.txt   # Ctrl-C 后过滤
```
- 若崩溃：`aa start` → 退出耗时约 `<...>` 秒；exit 254：`<是/否>`
- `AppKilledReporter` / `JsError` 行（含时间戳）：`<...>`；jscrash 文件名：`<...>`；前后各 200 行或整份 hilog 已附：`<文件名>`
```text
# files/dotnet-status.txt（/data/app/el2/100/base/<bundleName>/files/dotnet-status.txt；不可得写原因）：
<粘贴全文；不存在或未更新也要写明>
```

## 4b. 签名与内核验签（XPM / fs-verity；命令出处：`2026-09-22-ohos-elf-signing-research.md` Tester checklist / §6）

```sh
hdc shell "cat /proc/sys/kernel/xpm/xpm_mode"              # 0=关闭；1..5=各级 XPM
hdc shell "cat /proc/sys/fs/verity/require_signatures"     # 1=fs-verity 文件必须带签名
hdc shell "hilog -t kmsg" > kmsg.log                       # 与 §4 启动复现同一时刻抓
grep -iE "xpm|unsigned file|fs_security_verity|libopenharmonyhost" kmsg.log
# 在测试方 PC 上对重签产物跑（SoInfoSegment magic 命中数；期望 >=1）：
python3 -c 'import re,sys; d=open(sys.argv[1],"rb").read(); print("SoInfoSegment magic hits:", len(re.findall(bytes.fromhex("20e7d20e"), d)))' <重签后的 hap>
# 对照一个能跑的 app（cc-switch）的某个 libs/*.so：
binary-sign-tool display-sign -inFile <cc-switch 的 libs/*.so>
```
- `xpm_mode`：`<0..5 / 不可得 + 原因>`
- `require_signatures`：`<0 / 1>`
- kmsg 过滤输出（逐字粘贴；特别注意含 `unsigned file`、`is not protected by dmverity`、`lib_no_signed event waken: -9(E_HM_PERM)` 的行及其路径）：`<粘贴 / 无此类事件>`
- 重签 hap 的 `SoInfoSegment` magic 命中数：`<n>`（0 = 本次 sign-app 未做 code signing，检查是否漏了 `-signCode 1`）
- cc-switch 某个 lib 的 `display-sign` 输出：`<code signature is not found / self-sign / 证书链原文>`

## 4c. app-lib / 别名注册 / 首帧 / bootstrap / payload（tester-run v8 自动采集；手工命令如下）

```sh
hdc shell "hilog -x | grep -E 'SetAppLibPath|appLibPathKey|NativeLibPath|lib path'"   # -> hilog/hilog-applib.txt
hdc shell "hilog -x | grep -E 'dlopen|cannot find library|openharmonyhost'"          # -> hilog/hilog-dlopen.txt
hdc shell "hilog -x | grep -E 'GetRawFileContent|bootstrap failed|BusinessError|900002|900003|ZIP entry|destination path|Load native module failed|symbol not found|cannot find library'"   # -> hilog/hilog-bootstrap.txt（v7 起）
hdc shell "ls -l /data/storage/el1/bundle/libs/arm64/" > app-libs-arm64.txt          # -> device/app-libs-arm64.txt
hdc shell "ls -l /data/storage/el2/base/haps/entry/files/" | grep -E 'dotnet|payload' # -> device/payload-files.txt（v7 起）
hdc shell "cat /data/storage/el2/base/haps/entry/files/dotnet.marker"                # -> device/payload-marker.txt（v7 起，或为空）
```
- `appLibPathKey` 行（含 `lib path:` 原文）：`<粘贴 / 未出现>`（出现 `appLibPathKey: <bundle>/<module>` = 模块级 app-lib key 已注册，`libIsolation` 生效）
- 别名注册行（`[openharmony-host] … bound via alias '…'`，逐字）：`<粘贴 / 未出现>`
- 首帧判定（`registerXComponent=function` / 首帧出现 / 无 `Load native module failed`）：`<逐条>`
- `summary.txt` 的 v7/v8 键（原文照抄）：`bootstrap_errors=<...> rawfile_errors=<...> libload_errors=<...> payload_present=<...> payload_marker=<...> kit_index_ok=<...> execmem_capture=<...> execmem_lines=<...>`；`kit_index_ok=no` 请换 kit #22+ 再测；`bootstrap/rawfile` 计数 >0 时附 `hilog-bootstrap.txt`；JIT 判定见 `docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §3（#28 见 `docs/plans/2026-09-26-ohos-tester-handoff-kit28.md` §3）/ `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md` §5

## 4d. kit #25 判定点（权限弹窗文案 / Share 面板 / Scan 返回 / AOT 启动；#26–#29 继续按此判读）

> 本 kit 的 5 个 hap 是 **JIT payload**（hostfxr 回退路径）；Share/Scan 的 sink 在 OpenHarmony SDK 下
> **不注册**（`shareDispatch=False`/`scanSupported=False`），面板/扫码 UI 需 `ARKTS_SDK_FLAVOR=harmony`
> 的 HarmonyOS SDK 构建 + HMS 设备。没有对应入口的项登记「未测（本包无入口）」，不要判失败。
> 完整判读见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md` §2。

- 权限弹窗文案（权限变体）：`<弹窗是否显示理由文案 + 截图文件名>`
- 权限声明原文（`unzip -p <hap> module.json` 的 `requestPermissions`，含 `reason`/`usedScene`）：`<粘贴 / 未做>`
- Share 面板：`<OpenHarmony 下是否干净降级（shareDispatch=False，不崩）/ HarmonyOS 变体面板结果 / 未测（本包无入口）>`
- Scan 返回：`<scanSupported=False 时 IsSupported/ScanAsync 结果 / HarmonyOS 变体 originalValue / 未测（本包无入口）>`
- AOT 启动：`<AOT hap 启动结果（app export）/ 未提供 AOT hap → JIT hostfxr 回退回归结果>`

## 4e. kit #26 增量判定点（新 payload 首次运行 / 原生桥 ABI / PLAT-GAP 恢复路径；历史，仍按此判读）

> 完整判读见 `docs/plans/2026-09-26-ohos-tester-handoff-kit26.md` §2；§4d 的权限/Share/Scan/AOT 口径不变。
> kit #27/#28/#29/#30 继续沿用本节（重建 payload 首次运行 / 回调路径无 ABI 回归）；kit #28 的 abc 期望为 `264136`（#27 为 `245412`）、kit #29 为 `281052`/`20916`（#30 沿用）；PLAT-GAP 路径同。

- 新 payload 首次运行（LibraryImport hosting 重建）：`<启动两行日志原文 + 是否存活 + 5 条冒烟结果>`
- 原生桥 ABI 抽查（权限请求 / `A11Y` / Hybrid `Echo`·`Add`）：`<结果截图/回显 + 有无 EntryPointNotFound/DllNotFound/参数错乱>`
- PLAT-GAP 消费方路径（用 kit #26 workload 发布引用 `Microsoft.AspNetCore.App` 的项目）：`<dotnet publish 结果 + 是否需要工程级 KFR/RID/apphost 规避 / 未做>`

## 4f. kit #27 增量判定点（无 HMS 降级不抛（Push/Account/Map）/ 新 payload 首次运行）

> KIT-EXT2 **未新增 UI 入口**：5 个 hap 里没有 Push/Account/Map 的按钮。首选判定是**降级不抛**；真 Kit 调用需
> `ARKTS_SDK_FLAVOR=harmony` 构建 + HMS 设备 + AGC 开通/审批。没有对应入口的项登记「未测（本包无入口）」，不要判失败。
> 完整判读见 `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md` §2。

- 无 HMS 降级不抛（Push `GetTokenAsync` / Account `AuthorizeAsync`·`GetQuickLoginAnonymousPhoneAsync` / Map `QueryCapabilitiesAsync`·`MapKitImportable`·`IsSupported`）：`<Unavailable/null/false 原文 + 有无异常/崩溃 + 未测（本包无入口）>`
- Push token（需 HMS/AGC）：`<token 首尾片段 + 错误码 1000900010/1000900012 排查原文 / 未测>`
- Account 授权（需 HMS + scope 审批）：`<匿名手机号 + authorizationCode 结果 + 错误码 1001502014/1001500001 排查原文 / 未测>`
- Map 能力位（需 HMS/AGC + AppKey）：`<capability bits（bit0）+ QueryCapabilitiesAsync 结果原文 / 未测>`
- 新 payload 首次运行（新 abc 245,412 + 新宿主 + marshal-off）：`<启动两行日志原文 + verify-kit 结果（abc=245412）+ 是否存活>`
- 回调路径（marshal-off）：`<权限请求 / A11Y / Hybrid Echo·Add 结果 + 有无 EntryPointNotFound/DllNotFound/参数错乱>`

## 4g. kit #28 增量判定点（Map 覆盖层 / LiveView / AOT 启动桥 / 解释器实验；历史，仍按此判读）

> R2 默认 flavor 的 5 个 hap **无 Map/LiveView UI 入口**；首要判定是**降级不抛**与**重建 payload 首次运行**。
> Map 点亮需 `ARKTS_SDK_FLAVOR=harmony` 构建 + AGC 地图 AppKey；LiveView 需 AGC 实况窗权益 + 设备开关；
> AOT 直启需 `aot-haps.tar.gz` 重签 hap；解释器为独立实验资产。没有对应入口/资产的项登记「未测」，不要判失败。
> 完整判读见 `docs/plans/2026-09-26-ohos-tester-handoff-kit28.md` §2。

- Map 覆盖层降级不抛（`IsOverlayAvailable` / show/hide/close/区域/标记）：`<false/不可用原文 + 有无异常 + 未测（本包无入口）>`
- Map 覆盖层点亮（harmony + AGC AppKey）：`<flags bit1 + 地图截图 + Ready/MarkerClick/CameraIdle 事件日志 / 未做>`
- LiveView 降级不抛（`IsSupported` / Start/Update/Stop）：`<false/Unavailable 原文 + 有无异常 + 未测（本包无入口）>`
- LiveView 点亮（HMS + 权益）：`<卡片截图 + 1003500004/1003500005 错误码原文 / 未做>`
- AOT 启动桥（`aot-haps.tar.gz` 重签）：`<aot=1 日志 + managed 输出 + 有无 The application to execute does not exist>`
- 解释器实验（替换两个 .so + `<files>/interp.txt`）：`<interp=3 source=file + maps 含 libclrinterpreter.so / 无匿名 r-x + managed 输出>`
- 新 payload 首次运行（新 abc 264,136 + R2 壳桥）：`<启动两行日志原文 + verify-kit 结果（abc=264136）+ 是否存活>`

## 4h. kit #29 增量判定点（CoreSpeechKit TTS / HUKS-first SecureStorage / tester-run v11 / 自绘深度五连）

> R3 默认 flavor 的 5 个 hap **无 TTS UI 入口**（sink 不注册）：首选判定是**降级不抛**与**重建 payload 首次运行**。
> TTS 真朗读需 HMS 设备 + harmony 壳（无 AGC 权益/权限门槛）；HUKS 在默认 flavor/headless 均可走（有
> `libhuks_ndk.z.so` 时为硬件后备）；文本编辑/动画/列表/图片需演示或探针页入口；深链需系统 want 投递。
> 没有对应入口的项登记「未测（本包无入口）」，不要判失败。完整判读见 `docs/plans/2026-09-28-ohos-tester-handoff-kit29.md` §2。

- TTS 降级不抛（`IsSupported` / `SpeakAsync` / `Stop` / locales）：`<false/直接返回/no-op/设备 locale 原文 + 有无异常 + 未测（本包无入口）>`
- TTS 点亮（HMS + harmony 壳）：`<实际发声计时 + stop 静音 + locales 列表 + 错误码 1002300002/3/5 排查原文 / 未做>`
- HUKS 重启读回：`<读回值 + 是否 k1: 前缀 + IsHardwareBacked + hilog>`
- HUKS 换设备不可解 / 删除清 key：`<不可解原文 + RemoveAll 后旧值结果 + hilog / 未做>`
- HUKS 回退如实：`<回退文件密钥时 IsHardwareBacked=false 原文>`
- 模式矩阵（v11 `--mode-matrix`）：`<mode-matrix/summary.txt 逐 Run 键 + conclusion 原文>`
- 无障碍（v11 `--a11y-probe`）：`<a11y/selfcheck.txt 的 accessibilityStatus/NodeCount + summary a11y_* / 缺失容忍>`
- 文本编辑 / 动画·减少动效 / 列表 / 图片：`<录屏文件名 + 关键状态原文 / 未测（本包无入口）>`
- 深链（冷启动 / 热激活）：`<截图 + activation 日志（uri/sequence）+ 未知路由状态原文 / 未做>`
- 新 payload 首次运行（新 abc 281,052 + R3 壳桥）：`<启动两行日志原文 + verify-kit 结果（abc=281052/20916）+ 是否存活>`

## 4i. kit #30 增量判定点（runtime-mode 打包开关 / tester-run v12 / MAPFIX harmony 重切）

> MS-MODE 默认 flavor 的 5 个 hap 为 **jit 形态**（`libs/<abi>/runtime-mode.txt=jit`）：首选判定是
> **标记录入 + 优先级**与**重建 payload 首次运行**。MAPFIX 的 Map overlay 点亮需 harmony 壳 + AGC 地图
> AppKey + **与 AGC 证书指纹一致的重签**。没有对应入口/资产时登记「未测（本包无入口）」，不要判失败。
> 完整判读见 `docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2。

- runtime_mode 标记（默认包）：`<summary runtime_mode=jit(hap) + execmem 的 runtime-mode=jit source=manifest 原文>`
- 优先级（file>manifest>default）：`<写/删 <files>/interp.txt 前后的 source=file / source=manifest 原文 + 是否切到 3(file)/3(manifest)>`
- aot 显式回退（aot 形态包，可选）：`<runtime-mode=aot but …; falling back to the JIT route 行 / 无此资产 → 未测>`
- 模式矩阵 Run C 清单路线（v12）：`<run_c_via=manifest + run_c_interp_mode=3(manifest) + conclusion 原文 + 是否未写 interp.txt>`
- Map 覆盖层点亮（MAPFIX harmony + AppKey + 同指纹重签）：`<IsOverlayAvailable=true + 地图截图 + Ready/MarkerClick/CameraIdle 事件日志 / 未做>`
- 新 payload 首次运行（新宿主 MS-MODE + #29 abc）：`<启动两行日志原文 + verify-kit 结果（abc=281052/20916）+ 是否存活>`

## 4w. kit #47 增量（FlyoutPage 无障碍（FIX-A11YFLYOUT）/ 抢占原文（FIX-PREEMPT-RAW）；承 #46）

> 见 `docs/plans/2026-10-05-ohos-tester-handoff-kit47.md` §2：**主判点 1 = a11y Flyout 节点数**——装默认 kit 主 hap（AOT）→
> `--a11y-probe`：`accessibilityStatus: 1`、**nodeCount 1→70**（此前只发布根）；detail 恒发布、flyout 仅 presented 且保 detail；
> 带读屏环境复跑 T2/L1/N1/F2/E1。**主判点 2 = 抢占原文**——加 C/D/E（E 抢 A 槽）→ Activate A → hilog `[maui-capacity]`：
> `preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`（活覆盖层 ≤4）。
> 承 #46：INTERP-DRAW2（interp draw 14.4→9.4 ms、33.9→60.1 fps；JIT 无回归）+ FIX-A11YBUTTON（两态可达 `[523,1622][607,1668]`）。
> 套件 **593/595 floor 575**、导出 **151**、abc **370,240（`4b439e83…`）**/24,324、宿主 297,888（`7b1694d9…`）；
> **预签已刷新（#47 件：67,639,132 / `f58c4906…`，asset 610975429）**；bundle **73,059,625 / `27c54c62…`**
> （sdk 锚 **`266b196106`**；dtk **392356147** / latest **392077166**；manifest **`04b97494d2a`**）。

## 4v. kit #45 增量（上一版：自动释放（FIX-AUTODISCONNECT）/ 渲染门控（INTERP-RENDER））

> 见 `docs/plans/2026-10-04-ohos-tester-handoff-kit45.md` §2：**自动释放主判点**——加满 3 个 Web 控件后移除第 3 个 →
> 动态槽销毁（hilog `web slot destroy: 2`）、覆盖层消失；再加回 → `web slot create: 2` 重建并恢复交互（raw/invoke 回显）。
> **INTERP-RENDER**——解释器轮稳态 30 fps（20.7→30）、meas≈0 ms/帧、主线程 CPU −13pt；JIT/AOT 60 fps 不变。
> 套件 **587/589 floor 569**、导出 **151**、abc 368,812/24,324、宿主 297,888（`7b1694d9…`）；
> **预签已刷新（#45 件：67,624,950 / `e1ce8ab6…`，asset 609411819）**；bundle **73,058,366 / `a8334c4c…`**
> （sdk 锚 **`c7ac81ccdf`**；dtk **392356147** / latest **392077166**；manifest **`7b0c76a5fd6`**）。

## 4u. kit #44 增量（上一版：动态槽（MAX/HOT 4/2 + 3 控件并发）/ 默认 AOT（承 #43）/ FRAMEPACING）

> 见 `docs/plans/2026-10-04-ohos-tester-handoff-kit44.md` §2：动态槽——3 控件并发出画/交互、释放即拆、重建可复现、容量 4；
> AOT 默认——5 MAUI hap 全 AOT（`runtime-mode.txt=aot`、无 JIT 运行时）、首帧回归，JIT 需 ACL/豁免或 `--runtime-mode jit` 自建；
> 套件 **584/586 floor 566**、导出 **151**、abc 368,812/24,324、宿主 297,888（`7b1694d9…`）；**预签已刷新（#44 件：
> 67,627,789 / `75a40110…`，asset 608782132）**；bundle **73,052,763 / `3b3008a4…`**（sdk 锚 **`2abf4fcaa3`**；
> dtk **392356147** / latest **392077166**；manifest **`b486c6561e8`**）。

## 4t. kit #42 增量（JIT 解锁：JITFORT+ICU invariant / 解释器 rc2b 首帧 / FIX-SLICERACE 8/8 / L6/SAMPLE-FIX；上一版）

> 见 `docs/plans/2026-10-03-ohos-tester-handoff-kit42.md` §2：三路径首帧（JIT `canvas presented` + 探针 `1=OK 2=OK`；
> AOT 回归；interp rc2b `canvas presented`）；JIT 8/8 轮 race=0；套件 **578/580 floor 560**、导出 **151**、
> abc 356,468/24,324、宿主 297,888（`08abe185…`）；**预签未刷新（仍 #41 件）**；bundle **73,047,352 / `570c0821…`**
> （sdk 锚 **`35101fe1f5`**；dtk **392356147** / latest **392077166**；manifest **`ed504b85a46`**）。

## 4s. kit #41 增量（MULTI-OVERLAY-FULL；DEVCOMPAT-DEFAULT；INTERP-FIX：8 MB 栈 + rc2 pack；上一版）

> 见 `docs/plans/2026-10-03-ohos-tester-handoff-kit41.md` §2：同页两 Hybrid 各自闭环 → 第三控件 LRU 抢占 → Activate 恢复；
> enforcing 镜像默认可装；解释器轮 rc2 pack 存活；套件 **563/floor 543**、导出 **150**、abc 356,140/24,324、宿主
> 293,792（`8d67def3…`）；**预签刷新至 #41**（376,684,381 / `2075650a…`）；bundle **73,040,293 / `c98375a5…`**
> （sdk 锚 **`2222ba959f`**；dtk **392356147** / latest **392077166**；manifest **`e6ed5d28aa7`**）。

## 4r. kit #40 增量（FIX-JSCALL：`JSCall` 枚举/NavigationOptions AOT 扎根 → razor 计数往返 0→1→2；上一版）

> 见 `docs/plans/2026-10-02-ohos-tester-handoff-kit40.md` §2：点 "Blazor click" 两次 → **count 0→1→2**（截图 r0/r1/r2）；
> `.razor` 挂载/Back 关抽屉/Hybrid 出画 承 #39/#38；套件 **555/floor 535**、导出 **150**、abc 342,160/24,324（未变）、
> 宿主 293,792（`384e552a…`）；bundle **77,750,495 / `434d2b6f…`**（sdk 锚 **`77ffe1dad6`**；dtk **392356147** /
> latest **392077166**；manifest **`27bf46a63df`**）。

## 4q. kit #39 增量（FIX-BACKSIZE：Back 关抽屉 / BlazorWebView 真实尺寸 + FIX-BWVMount：`.razor` 挂载出画；上一版）

> 见 `docs/plans/2026-10-02-ohos-tester-handoff-kit39.md` §2：Back 关抽屉（再 Back 收后台）、BlazorWebView `.razor`
> 挂载（组件区 + count + Blazor click 按钮）、计数往返（在途）、Hybrid 出画/bridge（承 #38）；套件 **554/floor 534**、
> 导出 **150**、abc 342,160/24,324、宿主 293,792（`384e552a…`）；bundle **77,760,996 / `84d57989…`**
> （sdk 锚 **`2f1ace0a58`**；dtk **392356147** / latest **392077166**；manifest **`2e5c45095b0`**）。

## 4p. kit #38 增量（FIX-DISMISS：抽屉外点关闭 / FIX-WVP：Hybrid overlay px→vp / hybrid origin / z-order / 挂起；上一版）

> 见 `docs/plans/2026-10-01-ohos-tester-handoff-kit38.md` §2：抽屉外点关闭（重开/再关）、Hybrid 白区出画 + bridge
> 往返、注入动画、抽屉/切 tab 挂起恢复；套件 **550/floor 530**、导出 **149**、abc 341,560/24,324、宿主 293,792
> （`4e9f3c3e…`）；**FIX-BACK 未入包**（Back 关抽屉/BlazorWebView 尺寸在途）。bundle **77,742,112 / `3284e317…`**
> （sdk 锚 **`ee1163a004`**；dtk **392356147** / latest **392077166**；manifest **`895b5a71339`**）。

## 4o. kit #37 增量（FIX-HOME：Home 整页出画 / FIX-ITOUCH：注入/触摸 element 坐标，页内点击命中；上一版）

> 见 `docs/plans/2026-10-01-ohos-tester-handoff-kit37.md` §2：Home tab 首屏整页出画 + 切走/切回；
> 注入点击页内元素命中（"fading out…" → "animations done" 类）、偏心探针不误命中；套件 **544/floor 524**、
> 导出 **149**、abc 339,964/24,324、宿主 293,792（`4e9f3c3e…`；UND 238）；bundle **77,754,907 / `8abba9b1…`**
> （sdk 锚 **`d05247b90b`**；dtk **392356147** / latest **392077166**；manifest **`cfb13f09aab`**）。

## 4n. kit #36 增量（payload 原地直载（AOT 路径真机 BLZ）/ host 预注册缓冲 / 像素 Known 清零 / a11y 修复 / rc.2 AOT pack `-r2`；上一版）

> 见 `docs/plans/2026-10-01-ohos-tester-handoff-kit36.md` §2：payload 原地直载（`entry/libs/arm64` 原地启动 +
> `BLZ_BOOT`/`BLZ_RENDERED`）、host 预注册缓冲（16 条 / 64 KiB）、像素无 `Known(...)`、a11y `status=1`
> 与 nodeCount 5/24、rc.2 AOT pack `-r2`（撤 rc.1 钉）；套件 **540/floor 520**、导出 **149**、abc **339,964**/24,324；bundle **77,749,969 / `aeb6888a…`**（sdk 锚 **`b59c3d02e3`**；dtk **392356147** / latest **392077166**；manifest **`90371046940`**）。

## 4m. kit #35 增量（W9/W10：B2 真机 BLZ 打通 / T20 媒体传输层 / T14+T21+T8 余项 / AOT 入口修复；上一版）

> 见 `docs/plans/2026-09-30-ohos-tester-handoff-kit35.md` §2：B2（MAUI WebView 内嵌 Blazor WASM，`BLZ_BOOT`/`BLZ_RENDERED`）、
> T20 媒体传输层（无 MediaKit 属预期）、T14 收尾 / T21 字体缩放 / T8 不等高 TableView、AOT 入口修复
> （`dotnet-status.txt`；rc.2 AOT 包 shim 缺陷 → 本地钉 rc.1）；套件 **540/floor 520**、导出 **149**、abc **339,164**/23,516；bundle **77,754,383 / `acd26821…`**（sdk 锚 **`02a31ef348`**；dtk **392356147** / latest **392077166**；manifest **`f5fe6f35dc5`**）。

## 4l. kit #34 增量（rc.2 基线 + MAUI W6/W7/W8 + AOT v3；上一版）

> 见 `docs/plans/2026-09-30-ohos-tester-handoff-kit34.md` §2/§3：rc.2 版本自述（SDK `11.0.100-rc.2.26451.112` /
> workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`）；W6（T14/T12/N1/FIX-SHELL）+ W7/W8（T15/T16/N4/T18/N5/N6）
> 逐项勾选（套件 **513/floor 493**、导出 **145**）；JIT 主包崩溃/黑屏时重签 `aot-haps-v3.tar.gz` 判主体。

## 4k. kit #32 增量（WebView 六项 / B1 razor / SEC 收口 / Blazor 无 INTERNET）

> 9 项设备卡：`docs/plans/2026-09-28-ohos-webview-blazor-device-card.md`；判定点：`docs/plans/2026-09-28-ohos-tester-handoff-kit32.md` §2–§3；tester-run **v14**（`summary` 增 `blazor_marker_pid`/`blazor_session_nonce`）。

## 4j. kit #31 Blazor 段（第 6 个 hap / tester-run v13 `--blazor-probe`；历史）

> Blazor 组件与 MAUI 包互不依赖；没有 hdc/无法重签时登记「未测」，不判失败。完整判读见
> `docs/plans/2026-09-29-ohos-tester-handoff-kit31.md` §2/§4。

- Blazor 重签（`com.example.opendotnet`，工程 bundleName 必须同名）：`<签出文件名 + verify-app 结果 + hdc install 结果原文>`
- 两条 `BLZ_*` 标记（必过；`sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe`）：`<hilog 里 BlazorWebHost ... marker: BLZ_BOOT / BLZ_RENDERED 原文 / 未测（无 hdc）>`
- 失败采集：`<blazor-hilog.txt 文件名（含 BLZ_ERROR 行原文）+ bm dump -n com.example.opendotnet 原文 / 无>`
- 人工首屏：`<截图文件名 + 是否显示 “Hello from Blazor WebAssembly”>`
- 人工 `/counter` +1：`<0→1 原文（截图）>`

## 5. 探针阶梯（仍崩溃时；签装与判读见 crash-probes）

```sh
hdc install hello-mauiapp-probeN-unsigned.hap        # N=1..4
hdc shell aa start -a EntryAbility -b com.example.hellomauiapp.probeN
```
- P1 `PROBE1` 链：`<通过 / 停在哪一行>`；P2 `PROBE2 HOST_DLOPEN_RESULT`：`<...>`；P3 `PROBE3 HOST_ENTRY_RESULT`：`<...>`
```text
# P4 全部 PROBE4|... 行逐字（含 deps|N/14、host|...，勿截断）：
<粘贴>
# 免安装自检（命令见 crash-probes §2.1）：hdc shell ls -l /system/lib64/<14 库>
<14 行原样粘贴；缺失打印 No such file>
```

## 6. 附件清单

- [ ] 实际安装的 `module.json`（从 hap 解出 / 你手改后的那份）
- [ ] `hilog-crash.txt` 或 `hilog-filtered.txt`（含崩溃点前后各 200 行）
- [ ] jscrash 文件名（+ 内容或截图，有则附）
- [ ] 4 个探针 hap 重签后的 sha256
- [ ] `tester-report-<时间戳>.tar.gz`（+ `.sha256`；含 `summary.txt`、`hilog/hilog-applib.txt`、`hilog/hilog-dlopen.txt`、`hilog/hilog-bootstrap.txt`、`device/app-libs-arm64.txt`、`device/payload-files.txt`、`device/payload-marker.txt`、`meta/kit-hap-sha256.txt`、`meta/kit-selfcheck.txt`）

## 7. 未测项

- 我没测：`<如 P3/P4 未跑、AB-1 未做、faultlog 取不到；原因>`；其它：`<...>`
