# 五仓 OpenHarmony 移植性能扫描（2026-09-23）

**范围：** `runtime-ohos`、`aspnetcore-ohos`、`ohos-workload`、`maui-ohos`、`sdk-ohos`。
**关联：** 安全面见 [`2026-09-23-ohos-security-scan-2.md`](2026-09-23-ohos-security-scan-2.md)；本报告与安全扫描同日、同机、同一批评测。

## Verdict

**PASS WITH FINDINGS（31 热点全部收口；门禁已加固）。** 两路扫描（A 运行时/宿主/原生 + B 托管/UI/工具链与 CI）共定位 **31 个热点**（A 12 + B 19），全部带量化与 `文件:行` 证据。扫描窗口内修复 **10 个高收益热点**（H1/H2/H4/H5/H6/P1/P3/P4/P6/P8；H9 在 host 侧缓解：measure 成本 -53%），量化收益：**帧分配 241,688 → 72,864 B/帧（-70%）**、a11y Refresh **149,496 → 0 B**/未变帧、HasAnimations **38,632 → 0 B**（N=401 空闲）、text.hot **14.0 → 9.1 µs**/文本、image.steady **6.03 → 1.67 ms**/draw、present **0.74 ms**（缓存）vs **5.34 ms**（每帧 mmap）、measure_text 1.49 → 0.70 µs、effects 0.59 → 0.50 µs/fill，并顺带修复图片 **src_rect 渲染错误（FAIL → PASS）**。回归全绿：交互套件 **308 checks / floor 288**（扫描时值；现为 315 checks / floor 295）、像素套件 **PIXEL ASSERTIONS PASSED**（2,399,395 次像素写与基线逐位一致）、切片独立构建 0 错误。

**后置批次回填（本日晚，分支已推）。** `fix-perf2`/`fix-remain-a/b`/`fix-gates`/`fix-sdk`/`fix-host2` 把留档项中的 **16 个修到验证通过**（H3/H7/H8/H9/H11/H12/P2/P5/P7/P11/P12/P13/P14/P15/P17/P18），**3 个部分**（P9/P10/P19）、**2 个未修**（H10/P16，均低收益）。新增数字：P12 构建期读 **−82.9%**（175.4 MB→29.9 MB）、H7 8 MiB **29–33 ms/35.3 MB → 1.9–2.3 ms/8.4 MB（拷贝 5→2）**、H8 spawn **11.2→0.3 ms**、H11 **1204.8→30–43 µs/行**、H12 id 查找 **49.2 µs→32 ns**、DrawView 迭代器 **68.4 KB/帧→~0**、触摸 **878 KB→0.2 B**、轮播 **1759.7 ms→441.2 ms**（materialize 2.5→0/帧）、P17 启动**跳过解压**；套件帧分配 **72,864 → 4,504 B/帧**（final2 日志）。该段为当日中间态：P9/P10/P19 与 H10/P16 随后由最终回填收口（见下段）。

**最终回填（2026-09-23 深夜；全部剩余项收口）。** **H10** `9af70e9`（CanvasBackend 零分配：`Points(4)` 112→**0 B**、`RoundedPoints` 1104→**0**、`ArcPoints` 1720→**0**、`Flatten` 1264→**1144 B**——余量为 Maui.Graphics `PathF.GetFlattenedPath`，所有权外；130 图元/帧 **98,204→22,822 B**）；**P16** `c660755`（verify-kit 先真实 `sha256sum -c` + inode/size/mtime 快照证明未动，再复用哈希单 awk 建 tree digest；tester-run 复用同结果产出 `meta/kit-hap-sha256.txt`/`main_hap_sha256`；make-device-test-kit 只算一次 tar sha；快照空/变化/校验失败一律回退重算，首次必真实读。实测：163.5 MB kit 每轮 `--tree-digest` **少读 163,529,946 B、中位 4.98→3.48 s**（5 轮交错）、`--kit-tar` 少读 115,969,439 B、设备取证每轮少读 ~163.4 MB）；**P9** `316a1806`（maui；停手空转 19→**1 帧**）；**P10/P19** maui `c05db90f`（`DrawCalendar` 死代码 61 行 + PublicAPI 1 行删除；动画退役帧 184→96 B、`Frame` 委托静态化、颜色复用）+ hosting `54bede0`（无订阅者 **32→0 B / 0.111→0.046 µs**；订阅 churn 有意保留——列表方案会在锁内回调致 ABBA 死锁，审计测试钉住 `s_frameHandlers` 反射缝）。**全项统计：31 热点 → 已修 29 · 残留 2**（"残留 2"即上述 Flatten 1144 B/帧与订阅 churn，其余 29 项无余量）；套件基线 alloc/frame **4,504 B**、门禁 **13,824 B（3.07×）**、CI 实测 **3,720 B/帧**、jitter 2.0（实测 1.21–1.43），**315 checks / floor 295**。

**门禁现状（扫描时 → 后置批次后）。** 扫描时门禁几乎拦不住 2–4× 性能回归且完全不拦分配回归（帧预算只用 20.6%、alloc/frame 只打印不断言、preflight 226 < CI 288、pixel 无缓存跑 2 次、interaction/perf 不上 PR）。后置批次已修：alloc/frame + jitter 断言（`57d18c0`；`abd3451` 按修复后基线收紧）、preflight 解析套件 `[suite] floor` 单一来源（`d336bba`）、interaction 加 `pull_request` + 只读权限（`d4d7cb7`）、SDK/NuGet 缓存 + pixel 单次（`d4d7cb7`）、hvigor tar 成员负测（`5c2afb1`）；余量见 §门禁余量分析。先前留档的 H10（图元分配）、P16（kit 摘要/压缩复用）已由最终回填收口（见上）。所有"每帧"数字都是模型实测 × 频率假设，未在真机跑真实 HAP。

**发布：** kit #18（`device-test-kit`，2026-09-23 发布，115,905,186 B / `29be0590…`，maui-ohos pin `c730226f93`）已含扫描窗口全部已修项（FIX-P1 `46b4e0f`、FIX-P2 `8e4de06f` 及其后的 MB/H-C2 修复）；后置批次（H3/H7/H8/H11/H12/P12/P17/门禁）已提交各自 fork 分支并更新 slice pin（ow `425ecba`/`686bf89`、maui `f2937413`→`0e9d90cd`）；**kit #19**（同日发布，`device-test-kit` 115,968,154 B / `eee4ef55…`；workload bundle 30,482,709 B / `5e84fe21…`）已含后置批次；最终回填（H10 `9af70e9`、P16 `c660755`、P9 `316a1806`、P10/P19 `c05db90f`+`54bede0`）已提交各自 fork 分支；**kit #20**（2026-09-23 发布，tar 115,970,778 B / `0fa2d756…`；bundle 30,499,901 B / `ba43c2e8…`）收口全部最终回填；**kit #21**（2026-09-24 发布，tar 115,971,128 B / `cdb2a813…`、tree `3e9f46a1…`；bundle 30,498,612 B / `41d94901`）随发布修复 headless abc（`modules.headless.abc` `24.0.0.0` → `13.0.1.0`，13,572 B / `70a61636…`）并附带 tester-run v6r2；数字入口见 release `## Integrity` 与 `2026-09-22-ohos-release-manifest.md`。

## 范围与方法

- **实测环境（同机）。** HarmonyOS aarch64（RID `ohos-arm64`，.NET **11.0.0-rc.1.26451.109**），20 core，31 GB RAM；扫描时 31 GB 已用、仅 650 MB free → 分配/缺页类数字偏保守。微基准用 NDK clang 26.0.0.18 + `csc`/`dotnet 11` 编译运行，**不构建任何仓库、不改仓库文件**（除复用已构建的 harness 二进制）。
- **频率假设。** 60 fps 空闲帧；官方页 401 节点（`maui-platform-verify` 的 `perfNodes=401`，a11y 探针为 402 节点树）。所有数字标注 **[实测]**（本机命令产出）或 **[推断]**（由代码结构 + 实测总量归因）。
- **两路扫描。** A：运行时/宿主/原生（`host_napi.cpp` 3540 行、`openharmony_host.c` 2902 行、`Microsoft.OpenHarmony.Hosting`/`Maui.Graphics` 全量、maui-ohos OpenHarmony 平台切片、runtime-ohos 全部 129 个 fork delta 文件、aspnet 8 个 delta 文件；另做 7 组本机微基准）。B：托管/UI/工具链与 CI（Platform/OpenHarmony 109 个 `.cs`、`test/{maui-platform-verify,headless-render}`、`scripts/**`、3 个 workflow、sdk 签名任务；复跑两份已构建二进制做基线）。
- **基线复跑。** Debug `verify`：real 14.02 s，帧 avg=4.112 ms、p50=4.229、p95=5.67、max=6.804、max/avg=1.65、**allocDelta 48,337,600 B → 241,688 B/帧**；a11y render skip 0.359 ms / republish 4.444 ms、publish skip 0.033 ms / republish 3.76 ms（ratio 12.37×/114.2×）、budget elapsed 292 ms/2000 ms。Release `headless-render`：real 6.37 s、`PIXEL ASSERTIONS PASSED`、2,399,395 次像素写、1 条 KNOWN（selection tint Δ=1/255）。
- **实测命令摘要（全部在 `/data/storage/el2/base/tmp/opencode/scan2/{perf-a,perf-b}/`）。** `csc` + `dotnet exec PerfBench{,2,3}.dll`；NDK clang `native_draw_bench`/`native_frame_bench2`/`a11y_probe_bench`/`fcntl_bench`（签名后运行）；`cd ohos-workload/test/maui-platform-verify/bin/Debug/net11.0 && time ./verify`；`cd ohos-workload/test/headless-render/bin/Release/net11.0 && time ./headless-render`；`sha256sum`/`tar -czf` 计时；`readelf`/`find` 盘点载荷。

## 热点总表

### A. 运行时 / 宿主 / 原生（12）

| 编号 | 热点 | 文件:行 | 量化（[实测] 优先） | 状态 |
|---|---|---|---|---|
| H1 | 每次 `draw_text` 新建 Font+Brush（+TextBlob） | `ohos-workload/src/OpenHarmonyHost/openharmony_host.c:2308-2336` | 54.8 µs/文本；缓存 Font+Brush→22.6（-59%），再缓存 blob→12.6 µs（-77%）；30 文本/帧 1.65→0.38 ms | **已修** `46b4e0f` |
| H2 | `draw_present` 每帧 mmap/munmap + 逐行 memcpy | `openharmony_host.c:2465-2510` | 常驻映射 0.66 ms/帧(15.4 GB/s) vs 每帧重建 6.99 ms/帧(1.45 GB/s，~2580 次缺页)；修复后缓存 0.74 vs mmap 5.34 ms | **已修** `46b4e0f` |
| H3 | OHOS(musl/arm64) 编译期关闭 TLS 优化 → 线程静态访问慢路径 | `runtime-ohos/src/coreclr/vm/threadstatics.cpp:1025-1026,1036`；`jitinterface.cpp:1228,1442-1453`；`jit/helperexpansion.cpp:1048-1051 vs 1077-1111` | [推断] 线程静态访问多 3–4 指令 + 1 分支 → 静态字段密集代码 1.5–3× | **已修** `cfdba659d11`（探测门控）：OHOS 进入 `IsValidTLSResolver()` 分支，静态解析器才启用、失败保持现状；设备实测 musl 为动态序列 → probe=0，今日仍走慢路径，无回归 |
| H4 | a11y 每帧重建节点表 + 每节点 ≤4 次 native malloc + 4 次 P/Invoke marshal | `maui-ohos/.../OpenHarmonyAccessibility.cs:465-475,481-514,62-87`；`openharmony_host.c:2788-2839` | Refresh **157 KB/帧 + 113 µs**（N=200）；Publish diff+ActionsFor 12.8 KB/帧；合计 220 KB/帧 ≈12.6 MiB/s Gen0@60fps + 每帧约千次 malloc/free | **已修** `8e4de06f` |
| H5 | 每帧全树递归探测动画（无缓存） | `OpenHarmonyWindowRenderer.cs:350,395-413` ← `OpenHarmonyMauiAppHost.cs:69-72` | N=200 17.7 KB/28 µs；N=500 44.1 KB/71 µs（~88 B/节点迭代器）；空闲也跑 | **已修** `8e4de06f`（0 B 空闲） |
| H6 | `ActionsFor(role)` 每次新数组 + 接口枚举器 | `OpenHarmonyAccessibility.cs:62-87,506` | 108 B、105 ns/次 → N=200 每次发布 21.6 KB + 21 µs | **已修** `8e4de06f`（bitmask） |
| H7 | rawfile 8 MiB 整文件 base64（无分块、同步编码） | `packs/.../preview.24/.../Index.ets:1979-1984`；`host_napi.cpp:2067-2098`；`OpenHarmonyFileSystem.cs:212-215` | 单次 13.9 ms / 30.8 MB 分配（PtrToStringUTF8 22.4 MB + FromBase64String 11.7 MB）；shell `encodeToStringSync` 阻塞 UI 35–48 ms/8 MiB | **已修** `02726dc`+`7ea2e3b`（ow）+ `0e9d90cd`（maui）：fd 直读字节。8 MiB：29–33 ms/35.3 MB 峰值 → **1.9–2.3 ms（冷 9.0）/8.4 MB**；拷贝 5→2；base64 保留为回退 |
| H8 | OHOS `Process.Start` 走全 fd `fcntl` 扫描 | `runtime-ohos/src/native/libs/System.Native/pal_process.c:253-283,302-309,915` | RLIMIT_NOFILE=32768 → **8.0 ms/次** spawn（≈0.24 µs/fd） | **已修** `7f71107207b`：读 `/proc/self/fd`（getdents64，零分配）+ 每进程一次 close_range 探测。设备 11.2–11.6 ms → **0.29–0.40 ms**/spawn；本机复跑 13.53→0.31 ms（43×） |
| H9 | `DrawString` 每文本 2 次 native `MeasureText` | `Microsoft.OpenHarmony.Maui.Graphics/OpenHarmonyCanvasBackend.cs:238-268` | measure 1.47 µs/次；30 文本/帧多 45 µs + 多一次 P/Invoke/marshal | **已修** `46b4e0f`（host measure 1.49→0.70 µs）+ `f2937413`（(text,size,typeface) 测量缓存：30 标签 124.8 次原生测量/帧 → 预热后 **0**；双调用结构保留） |
| H10 | 图元点集每次分配（params 数组/tuple/List+ToArray/闭包） | `OpenHarmonyCanvasBackend.cs:61-73,82-95,181-199,221-235` | `Points(4)` 112 B/49 ns；圆角≈5 次分配；130 图元/帧 50.5 KB/58 µs | **已修** `9af70e9`：栈上 `Span<float>` + 每形状族复用缓冲（Hosting 侧 span 重载钉住点集、Ellipse 环在栈上）；`Points(4)` 112→**0 B**、`RoundedPoints` 1104→**0**、`ArcPoints` 1720→**0**、`Flatten` 1264→**1144 B**（余量为 Maui.Graphics `PathF.GetFlattenedPath`，所有权外）；130 图元/帧 **98,204→22,822 B**（仅 20 次 path draw 残留）；交互 315/315、像素写 2,399,395 不变 |
| H11 | `WriteStatus` 超 256 KiB 后每行 O(文件) 重写 | `Microsoft.OpenHarmony.Hosting/OpenHarmonyApp.cs:648-673,679-711` | 未满 37 µs/行（617 B）；饱和后 **1205 µs/行 + 763 KB/行**（3354 行 ReadAllLines+WriteAllLines） | **已修** `1e04887`：只读尾部 64 KiB + 重写尾段 → **~30–43 µs/行**（本机复跑 30.3 µs/行，framing byte-exact）；饱和后回归普通 append |
| H12 | a11y provider 查询线性/含 O(N²) + 每 probe 4 次字符串拷贝 | `host_napi.cpp:3136-3147,3234,3256,2923-2929`；`openharmony_host.c:2867-2898` | probe 38.6 ns；N=200 最坏 ≈1.5 ms、N=500 ≈9.6 ms（findById+PREFETCH_CHILDREN O(N²)） | **已修** `dde3037`：发布时增量建 id→index + 复用节点表。id 查找 **49.2 µs → 32 ns**；N=200/500/1000 查询 5.7/11.0/22.3 ms → 3.0/5.4/9.5 ms（每 200 查询；本机复跑 5.08/9.82/16.11→2.67/4.65/7.88 ms） |

### B. 托管 / UI / 工具链与 CI（19）

| 编号 | 热点 | 文件:行 | 量化 | 状态 |
|---|---|---|---|---|
| P1 | 宿主每帧全树遍历（与脏标记无关） | `OpenHarmonyMauiAppHost.cs:69-80` + `OpenHarmonyWindowRenderer.cs:350,395-413` | 401 节点 ≈24 KB/帧 ≈1.4 MB/s 空转；空闲 UI 也全树走查 | **已修** `8e4de06f`（空闲 0 B） |
| P2 | 轮播指示点每帧重建整个 ItemsSource | `OpenHarmonyWindowRenderer.cs:359` → `OpenHarmonyCarouselViewHandler.cs:186-207` | N=1000 项 8 KB/帧 + 1000 次枚举/帧（N=100 ≈0.8 KB/帧）；只为取 Count | **已修** `f2937413`：slide 列表按（源引用 + `ICollection.Count`）缓存，arrange 未移动不重建。500 项：**1759.7 ms/2.08 MB → 441.2 ms/295,793 B**（提交实测；离机 native-miss 仍占大部），materialize 2.5→**0**/帧；分组/IEnumerable 源有意不缓存 |
| P3 | 每次 `FillColor` 赋值触发原生 `ClearEffects` | `Microsoft.OpenHarmony.Maui.Graphics/OpenHarmonyCanvasBackend.cs:35-43` | 每帧数百次 P/Invoke（401 节点页 300–600 次/帧）；effects 0.59→0.50 µs/fill | **已修** `46b4e0f`（脏标记） |
| P4 | 每帧全量重新解码图片 | `OpenHarmonyView.cs:863-882` → `Hosting/OpenHarmonyApp.cs` → `openharmony_host.c:2437-2463` | 1 MB PNG 每帧完整解码（数 ms/图/帧）+ 每帧新建 2 Rect/Sampling；src 矩形误用目标宽高（尺寸 bug） | **已修** `46b4e0f`（缓存 + src_rect 修复） |
| P5 | 文本测量与 TextBlob 重建（无缓存） | `OpenHarmonyStyledViews.cs:336,353,366,422` + `OpenHarmonyLabelHandler.cs:53-62` + `openharmony_host.c:2308-2354,2384-2408` | 单行每帧 3 次原生 measure（各建/毁 Font）+1 次绘制；401 页 ≈1000+ 次/帧；CharacterSpacing≠0 时逐字符 O(n) 分配 | **已修** `f2937413`：成功测量按 `(text,size,typeface 代)` 缓存（字族换文件时代号 +1）；逐字符 glyph 串与 advance 同缓存。30 标签 124.8 次原生 measure/帧 → 预热后 **0** |
| P6 | a11y 每帧重建影子树（2 字典 + 每节点 List + record） | `OpenHarmonyAccessibility.cs:472-480,512-530` | 401 节点 ≈82 KB/帧（skip 只省 host 流量：publish skip 0.033 ms） | **已修** `8e4de06f`（稳态 0 B） |
| P7 | 每次按下 8 次全树递归搜索 | `OpenHarmonyWindowRenderer.cs:565,582,587,670-683,752` | 401 节点 → 8×401 访问 + ≈3200 迭代器/次按下；拖拽每 move 再 401 节点 | **已修** `48b91712`：7 个命中查询合成 1 次谓词遍历 `CollectTouchTargets` + down 时缓存 drop-recognizer 事实。按下 **878,064 B → 0.2 B**、down+up 2.9–3.4 ms → **0.71 ms**；残余：`HandleTouchCore` 仍独立单趟 |
| P8 | 动画循环每帧 `ToArray` 快照 | `OpenHarmonyAnimationLoop.cs:173` | 1 数组/帧（通常 32 B）+ 偶发 finished List；低收益 | **已修** `8e4de06f`（池化） |
| P9 | 滚动偏移每帧 `new WeakReference` + 停止后 300 ms 空转 | `OpenHarmonyScrollPhysics.cs:223,97-111` | fling 60 次/s WeakReference（≈24 B）+ 2 次 lock/帧；停手后再白跑 18 帧 | **已修** `f2937413` + `316a1806`（maui）：WeakReference 仅在滚动视图变化时重建；帧 tick 仅在「指抬 + age≤80 ms + 样本≥3 + `\|v\|`≥320」保留订阅，其余立即退订，新采样/Up/`TryStartFling` 自动重注册；停手空转 **19→1 帧**，边界仍精确停 480 |
| P10 | 下拉/浮层/日历每帧全量绘制全部行 | `OpenHarmonyView.cs:961-990,156-171,209-266` | 200 项 Picker ≈200 次 measure+draw/帧（叠加 P5 → ≈600 原生调用/帧）；DrawCalendar 每帧字符串格式化 | **已修** `48b91712` + `c05db90f`：弹层行/轮播指示点按视口裁剪跳过（像素不变）；`DrawCalendar` 无调用者，方法与其逐帧月/日字符串格式化、PublicAPI 基线行（61 行 + 1 行）一并删除，`CalendarHit`/日历几何常量保留（弹窗命中仍用） |
| P11 | `Describe` 递归 O(n·深度) 字符串复制 | `OpenHarmonyWindowRenderer.cs:1159-1162`；调用点 `OpenHarmonyMauiAppHost.cs:600` 等 7 处 | 深度 d 节点被复制 d 次；verify 用 150 层树取长度 | **已修** `48b91712`：单 `StringBuilder` 追加，O(n·d)→O(n)；flyout 绘制/Describe 不再物化列表 |
| P12 | 每次 Build/Publish 对全部输出文件 `ReadAllBytes` 签名 | `sdk-ohos/src/Tasks/Microsoft.NET.Build.Tasks/ElfSigner.cs:51-58` + `OpenHarmonyCodesign.cs:32` + `Microsoft.NET.Sdk.targets:891-900` | 某 MAUI 应用输出 532 文件/171 MB（26 个 ELF/30 MB；.hap 32 MB 也被整读）→ 每次 175 MB 读 + 2×32 MB LOH + 30 MB Merkle SHA-256 ≈0.5–1 s + GC；无 `Inputs`/`Outputs` → 每次都跑 | **已修** `6ff4f788fc`+`48fdd91aed`：先 64 B ELF magic 探测、流式校验、按需物化、`Inputs/Outputs` stamp。175,381,232 B/377–558 ms → **29,897,505 B/146–261 ms（读 −82.9%）**；字节级不变 |
| P13 | CI 双 workflow 重复 restore/build，无缓存，pixel 跑两遍 | `interaction-regression.yml:58-87`、`pixel-regression.yml:46-84` | 每次 push/PR 重复 2 份 restore + 2 份同程序集构建；pixel 套件本机单次 6.4 s 跑 2 次 | **已修** `d4d7cb7`：`~/.dotnet`+`~/.nuget/packages` 缓存（key=OS+workflow+依赖文件 hash），pixel 单次运行 |
| P14 | 交互/性能门禁不在 PR 上执行 | `interaction-regression.yml:34-35`（仅 push master+dispatch）vs `pixel-regression.yml:18` | 性能回归只能在合并后被 20 ms/250 ms 的宽松预算发现 | **已修** `d4d7cb7`：interaction 加 `pull_request`（只读 token，无 secret）；CI 35858501620 已按 PR 触发 |
| P15 | preflight 阈值弱于 CI 且强制全量重建像素套件 | `scripts/preflight.sh`（`-lt 226` vs CI `-lt 288`；`rm -rf bin` + `dotnet run -c Release`） | 本地可在缺 62 条断言下 PASS；每次预检重建 headless-render（含 P12 签名路径） | **已修** `d336bba`+`57d18c0`：套件自报 `[suite] checks/floor`，preflight 与 CI 解析同一行（315 checks / floor 295），删除第二份字面量 |
| P16 | 110 MB 设备测试包被整读 4–6 遍并重复压缩 | `make-device-test-kit.sh:370-403` + `verify-kit.sh:72-81` + `tester-run.sh:491-518,1214` | SHA-256 0.15–0.22 s/103 MB；`tar -czf`(103 MB 已压缩 hap) 3.24 s→86.6 MB；kit 实存 115,822,672 B → 每轮 ≈4–5 遍整读 + 1–2 次 deflate | **已修** `c660755`：verify-kit 先真实 `sha256sum -c`，以 inode/size/mtime 快照证明未动后复用哈希（单 awk，免逐文件 spawn）建 tree digest；tester-run 复用同结果产出 `meta/kit-hap-sha256.txt`/`main_hap_sha256`、从已校验 sidecar 取 tar 摘要；make-device-test-kit 只算一次 tar sha。快照空/变化/校验失败一律回退重算（首次必真实读）。实测：163.5 MB kit 每轮 `--tree-digest` **少读 163,529,946 B、中位 4.98→3.48 s**（5 轮交错）；`--kit-tar` 少读 **115,969,439 B**；设备取证每轮少读 ~163.4 MB |
| P17 | 应用每次启动都重新 copy+解压 `dotnet.zip` | `packs/.../preview.24/.../EntryAbility.ets:92-101` | 内层 16 MB zip → 40.5 MB/253 文件；每次启动 copy 16 MB + inflate 40 MB + 建 253 文件（[推断] 0.3–1 s/次，手机更高） | **已修** `6f91456`+`062d444`：`dotnet.marker`（长度+mtime+文件数，原子写）命中即跳过；缺失/半解压/变更先清理再解。266 项 harness 全过；fstat 不可用时降级旧行为 |
| P18 | rawfile 回退无缓存 + base64 三份拷贝 + Exists/Read 两次往返 | `OpenHarmonyFileSystem.cs:104-215` | 8 MiB 文件 ≈30 MB 瞬态峰值/次；同一资源 N 次访问 = N 次往返；超时 `Task.Delay(3s)`/次 | **已修** `f2937413`（16 项/12 MiB LRU + 256 项存在缓存含"未找到"；`Task.WaitAsync`：260 B/请求→0）+ `02726dc`/`0e9d90cd`（fd 直读字节替代 base64，拷贝 5→2） |
| P19 | 每帧零散分配（补充 P3/P5） | `OpenHarmonyView.cs:819`（caret 子串）、`OpenHarmonyStyledViews.cs:362`（逐字符 `ToString()`）、`OpenHarmonyAnimationLoop.cs:64`、`OpenHarmonyApp.cs:1046`（每帧 `new FrameEventArgs`） | 焦点 Entry 每帧 1 个 O(n) 子串 + 1 次原生测量 | **已修** `48b91712` + maui `c05db90f` + hosting `54bede0`：caret/选区宽度改用缓存字符宽度前缀和（O(n) 子串消除）；动画退役帧 **184→96 B**、`Frame` 委托静态化、派生颜色每源值一次；hosting 无订阅者时 **32→0 B / 0.111→0.046 µs**；订阅 churn 有意保留——列表方案会锁内回调致 ABBA 死锁，审计测试钉住 `s_frameHandlers` 反射缝 |

## 已修项 before/after

| 编号 | before | after | 验证 | 提交 |
|---|---|---|---|---|
| H1 | text.hot ≈12.5–14.0 µs/文本 | **9.1–9.7 µs**（单轮 9.4）；主机 bench：热进程每文本 11.6–12.9 → 5.5–5.9 µs | `compare-final.txt` 5 轮交错；text.cold/long 不回归 | ow `46b4e0f` |
| H2 | present 每帧 mmap/munmap 5.34 ms/帧（单轮 4.75–7.00） | **0.74 ms/帧**（缓存；单轮 0.55–0.61）；`present.new_remap` 4.8–5.2 ms 证明是缓存收益 | 同上；设备侧提交记录 4.70→0.55 ms | ow `46b4e0f` |
| P4 | image.steady 6.03 ms/draw（单轮 5.33–7.38）；src_rect **FAIL** | **1.67 ms/draw**（单轮 1.62–1.64）；src_rect **PASS**（四角 00ff/ff00/ff00ff/ffffff 正确） | 3.1 MB PNG；2×2 象限探针 | ow `46b4e0f` |
| P3 | effects.shadow300 0.597 µs/fill | **0.50–0.55 µs/fill** | 同上 | ow `46b4e0f` |
| H9 | measure 1.49 µs/文本 | **0.70 µs/文本**（host 字体缓存）；managed 重复测量由 `f2937413` 缓存消除（30 标签 124.8 次原生测量/帧 → 0） | 同上 + perf2 探针 | ow `46b4e0f` + maui `f2937413` |
| H4/P6 | a11y Refresh 149,496 B/未变帧（157 KB/帧、113 µs，N=200） | **0 B**/未变帧；单 label 变更 6,616 B/次；render skip 0.359→**0.262 ms**、republish 4.444→**2.782 ms**、ratio 12.37→10.6×（floor 1.25） | 隔离探针 + `final-interaction.txt` | maui `8e4de06f` |
| H5/P1 | HasAnimations N=401 空闲 38,632 B / 146.87 µs（N=200 19,336 B/88.98 µs） | **0 B / 0.04 µs**（N=401）；有 spinner 注册时保持原走查（决策不变） | 动画模型探针（perf-a H5 形状） | maui `8e4de06f` |
| H6 | `ActionsFor` 108 B/105 ns/节点 → N=200 21.6 KB/发布 | bitmask（发布循环 0 B 数组） | a11y publish 探针 0 B/call | maui `8e4de06f` |
| P8 | 动画循环每帧 `ToArray` | 池化快照 | 套件 + 代码 | maui `8e4de06f` |
| 帧分配 | `allocDelta=48,337,600 B → 241,688 B/帧`；avg=7.499 ms（修复前基线） | `allocDelta=14,572,800 B → **72,864 B/帧**`；avg=**5.714 ms**；`./verify` real 20.62→13.03 s（复跑 11.56 s） | 同一 harness（Debug）；308 checks、0 Unhandled | maui `8e4de06f` + pin `d43dfb5`/`195dd3e` |
| 回归 | 像素基线 2,399,395 pixel writes | `PIXEL ASSERTIONS PASSED`、2 条 KNOWN 不变、writes **2,399,395 相同**；切片独立构建 0 错误 | Release headless-render | ow `d43dfb5`/`195dd3e` |

> 数字口径：before/after 取固定批次 `fix-p1` 的 5 轮交错最小/代表值与 `fix-p2` 的套件日志；门禁分析中的 4.112 ms 为 perf-b 扫描时的另一会话负载（同一预修二进制），两者不可直接混比。所有测量均为同机模型/harness，非真机 HAP。

## 后置批次回填（2026-09-23 晚，分支已推；均为离机 harness/设备侧提交记录）

| 编号 | before → after | 提交 | 验证 |
|---|---|---|---|
| DrawView（P7 残余） | 迭代器 68,392 B/帧 → **~0**；帧内分配 72,504→**4,144 B**；套件 alloc/frame 72,864→**4,504 B** | maui `48b91712` + pin `425ecba` | `bench-before3/after3`、`final2-summary`（315 checks/floor 295） |
| 触摸 | 878,064 B/次 → **0.2 B**；down+up 2.9–3.4 → **0.71 ms** | maui `48b91712` | 同上 |
| 轮播（P2） | 1759.7 ms/2,080,385 B → **441.2 ms/295,793 B**；materialize 2.5→0/帧 | maui `f2937413` | 提交实测（离机 native-miss 仍占大部） |
| 文本测量（P5/H9） | 30 标签 124.8 次原生 measure/帧 → **0**（预热后）；CharacterSpacing 769.6→0 | maui `f2937413` | 同上 |
| H7 | 8 MiB 29–33 ms/35.3 MB 峰值 → **1.9–2.3 ms（冷 9.0）/8.4 MB**；拷贝 5→2 | ow `02726dc`/`7ea2e3b` + maui `0e9d90cd` | `managed-bridge-test`、abc sha `51b52e7f`→`7d513f72` |
| H8 | 11.2–11.6 ms → **0.29–0.40 ms**/spawn（本机 13.53→0.31 ms，43×） | rt `7f71107207b` | `pal_fd_fallback_test`（本报告复跑） |
| H11 | 饱和 1205 µs/行 + 763 KB/行 → **~30–43 µs/行** | ow `1e04887` | `h11test`（本报告复跑 30.3 µs/行，framing byte-exact） |
| H12 | id 查找 49.2 µs → **32 ns**；查询 5.7/11.0/22.3→3.0/5.4/9.5 ms | ow `dde3037` | `a11y_query_bench`（本报告复跑 5.08/9.82/16.11→2.67/4.65/7.88 ms） |
| P12 | 175,381,232 B/377–558 ms → **29,897,505 B/146–261 ms（读 −82.9%）**；stamp 命中即不遍历 | sdk `6ff4f788fc`/`48fdd91aed` | 20/20 MSTest + 字节级 tree sha |
| P17 | 每次启动 copy 16 MB+inflate 40 MB/253 文件 → **marker 命中跳过** | ow `6f91456`/`062d444` | 266 项 harness（6 模板×2 模式） |
| P18 | 260 B/请求 + 3 s `Task.Delay` → **0 B + `WaitAsync`**；base64 5 拷贝→fd 2 拷贝 | maui `f2937413` + ow `02726dc` | `managed-rawfile-bench`、LRU/存在缓存断言 |
| 门禁 | alloc 无断言 → alloc/frame+jitter 断言；preflight 226→套件 floor；pixel 2→1 次；PR 触发；tar 成员负测 | ow `57d18c0`/`d336bba`/`d4d7cb7`/`abd3451`/`5c2afb1` | CI 35858501620/35858501647、preflight 全绿、tar 27 项负例 |

## 最终回填（2026-09-23 深夜；全部剩余项收口）

| 编号 | before → after | 提交 | 验证 |
|---|---|---|---|
| H10 | `Points(4)` 112 → **0 B**；`RoundedPoints` 1104 → **0**；`ArcPoints` 1720 → **0**；`Flatten` 1264 → **1144 B**；130 图元/帧 98,204 → **22,822 B** | ow `9af70e9` | 离机微基准（`UnsafeAccessor` 进真实 builder、无 native 调用）；交互 315/315、像素写 2,399,395 不变、2 KNOWN 不变 |
| P16 | 每轮 `--tree-digest` 整读 163.5 MB 两遍 → **少读 163,529,946 B、中位 4.98→3.48 s**（5 轮交错）；`--kit-tar` 少读 115,969,439 B；设备取证每轮少读 ~163.4 MB | ow `c660755` | 新旧验证器同一 kit 得同一 tree digest；篡改 hap/新增文件仍改变摘要；`selftest-tester-run.sh` 315/315 + 新生成 kit `KIT OK` |
| P9 | 停手空转 19 → **1 帧**（删除 300 ms 等待；仅可再起 fling 的窗口保留订阅） | maui `316a1806` | 离机 anim-driver harness：stall fallback/释放提示/摩擦衰减/边界钳制全绿（修复前 2 项失败 → 0） |
| P10 | `DrawCalendar` 死代码 61 行 + `PublicAPI.Unshipped` 1 行删除（逐帧月/日字符串格式化随删） | maui `c05db90f` | 交互 315/315、像素 `PIXEL ASSERTIONS PASSED`（写数不变） |
| P19 | 动画退役帧 184 → **96 B**/tick；hosting 无订阅者 32 → **0 B**/0.111 → 0.046 µs；`Frame` 委托静态化、派生颜色复用 | maui `c05db90f` + ow `54bede0` | 离机颜色 harness（与旧 `WithAlpha` 值等价）+ 交互 315/315；订阅 churn 保留有死锁证据与审计钉缝 |
| 套件基线 | alloc/frame **4,504 B**（确定：900,800 B/200 帧）→ 门禁 **13,824 B（3.07×）**、jitter（p95/avg）**≤ 2.0**；**315 checks / floor 295** | ow `abd3451` + 后续 CI | CI 实测 alloc/frame **3,720 B/帧**、jitter **1.21–1.43**；本地与 CI 同源 `[suite]` floor |

## 门禁余量分析

| 门禁 | 阈值 | 实测（扫描时） | 余量 | 问题 |
|---|---|---|---|---|
| 帧 avg | ≤ 20 ms | 4.112 ms | **4.9×（用掉 20.6%）** | 修复后 5.714 ms；后置批后 4.5–9.7 ms（负载敏感）仍余 2–4× |
| 帧 max | ≤ 250 ms | 6.804 ms | 36× | 同上 |
| 帧 max−avg | ≤ 100× | 1.65× | 60× | 同上；仅作单帧挂起兜底 |
| 帧 jitter（p95/avg） | ≤ 2.0（`57d18c0`） | —（扫描时无此断言） | — | CI 实测 **1.21–1.43**；比单帧 max/avg 稳健（对偶发抢占不敏感） |
| alloc/frame | **断言已加**（`57d18c0` 4×72,864 B 起步；`abd3451` 重定基线：**13,824 B = 3×4,504 向上取整到 512 B = 3.07×**） | 241,688 B ≈ **14 MB/s @60fps**（修复后 72,864 → **4,504 B/帧**，final2；基线确定：900,800 B/200 帧） | 3.07×（CI 实测 **3,720 B/帧**，用掉 27%） | 分配类回归已入闸；CI 与本地同源，阈值随套件契约维护 |
| a11y render skip | avg ≤ 20 ms | 0.359 ms（修复后 0.262） | 56× | 阈值极宽 |
| a11y render republish | avg ≤ 50 ms | 4.444 ms（修复后 2.782） | 11× | 同上 |
| a11y ratio render / publish | ≥ 1.25× / ≥ 2× | 12.37× / 114.2×（修复后 10.6× / 74.89×） | 10× / 57× | 断言的是"跳过有效"，不是成本上限 |
| a11y budget elapsed | ≤ 2000 ms | 292 ms（修复后 191） | 6.8× | 同上 |
| 像素容差 | 默认 ±24/255 | 通过；**1 个用例 `tolerance=0`**（button rounded corner，精确 DarkSlateBlue） | — | 对 1/255 级抗锯齿变化敏感；**策略已文档化**（`d4d7cb7`：不删/不放松须先查根因） |
| 本地 preflight | 解析套件 `[suite] floor`（=295） | CI 与本地同源（315 checks） | 0 | **已统一**（`d336bba`+`57d18c0`），不再有 226/288 双字面量 |
| CI 覆盖 | pixel + interaction 均在 push/PR | 已加 `pull_request`（只读 token、无 secret） | — | **已修**（`d4d7cb7`）；CI 35858501620 已按 PR 跑 |
| CI 缓存/重复 | `~/.dotnet`+`~/.nuget/packages` 缓存；pixel 跑 1 次 | key = OS+workflow+依赖文件 hash | — | **已修**（`d4d7cb7`） |

**结论：** 扫描时门禁"不会误报"，但**几乎不会拦住 2–4× 的性能回归，且完全不拦分配回归**——241,688 B/帧、149,496 B/帧、38,632 B/帧 三类问题当时都能静默通过全部门禁。后置批次已补 alloc/jitter 断言、单一阈值来源、PR 触发与缓存（见上表）；帧预算余量仍大（用掉 ~20–50%），后续按 3–4× 上限维护、新增瓶颈需继续收窄。最终回填后 31 热点全部收口（残留 2 项为所有权外/有意保留，见 §最终回填）。

## 建议后续（按收益排序）

1. **P5 + P10 + P2（文本/弹层/列表，最大剩余 UI 帧收益）。** managed 侧 `(text,size)→宽高` LRU；host 侧 Font/Typeface/TextBlob 缓存（H1 已提供基础设施）；逐字符路径改整串测量；Picker/日历只画视口行 + 缓存月份/日期串；Carousel 指示点缓存 Count（O(N)/帧 → O(1)/帧）。预期：401 节点页 ≈1000+ 次原生调用/帧降至 1/3。**［已修：P2/P5 `f2937413`；P10 弹层视口跳过 `48b91712` + 死日历路径删除 `c05db90f`；H10 见第 15 条］**
2. **DrawView `ChildrenOf` 迭代器重构（修复后的主要残余）。** 探针显示修复后帧内分配 46,768 B/帧中 **DrawView 42,766 B/帧**（每节点 `ChildrenOf` 迭代器，Debug 码型），其次 measure+arrange 32 B/帧。改为索引/池化遍历可把 72,864 B/帧再压一个量级。**［已修 `48b91712`（`ChildEnumerator`；68.4 KB/帧→~0）］**
3. **P7 触摸路径 8 次全树 → 1 次。** 合并 `FindPointerTarget`/`FindOpenPopup`/`FindOpenFlyout`/`FindScrollView`/`FindSlider`/`FindDragTarget`/`FindGestureTarget`/`HandleTouchCore` 为一次带谓词遍历并在 down 时缓存；拖拽 move 复用候选集。预期触摸延迟与 ~3200 迭代器/次归零。**［已修 `48b91712`；`HandleTouchCore` 单趟残余］**
4. **P12 ElfSigner 构建期成本。** 先读 64 B 判 ELF magic 再 `ReadAllBytes`；按扩展名跳过 `.hap/.pdb/.json`；流式 Merkle（不整文件驻留）；加 `Inputs`/`Outputs`/stamp 增量（已签名有效即跳过）。预期每次 Build/Publish 省 175 MB 读 + 64 MB LOH + 0.5–1 s。与安全报告 D-1/D-5 的修复同一文件，改动需保持"已签名有效则跳过"语义与字节级断言。**［已修 `6ff4f788fc`/`48fdd91aed`］**
5. **P17 启动解压跳过。** 已解压目录存在且 zip 大小/mtime 未变则跳过（写 marker），处理升级/半解压。预期每次冷启省 16 MB copy + 40 MB inflate + 253 次建文件（0.3–1 s）。**［已修 `6f91456`/`062d444`］**
6. **P16 kit 摘要/压缩复用。** 树摘要复用已验证的 `SHA256SUMS` 内容（不再逐文件读）；证据包只记录已打包 hap 的 hash/路径。预期每次 kit 省 2–3 遍 110 MB 读 + 1 次 deflate（≈3.4 s）。**［已修 `c660755`：实测每轮 `--tree-digest` 少读 163,529,946 B（中位 4.98→3.48 s）、`--kit-tar` 少读 115,969,439 B；tar 只算一次，deflate 本身未省］**
7. **H7 rawfile fd 直读/分块。** 用已有 `{fd,offset,length}` 走 native `pread`（或 256 KiB 分块 + 复用缓冲）。预期拷贝 4→1、瞬态 -98%、UI 不阻塞（35–48 ms/8 MiB → 接近无感）。**［已修 `02726dc`/`7ea2e3b` + maui `0e9d90cd`］**
8. **H3 TLS resolver（已实现，设备实测 probe=0）。** OHOS 现走 `IsValidTLSResolver()` 指令序列探测，静态解析器才启用、失败保持现状；实测 musl 的 TLSDESC 解析器为动态序列（`mrs TPIDR_EL0` + 每线程不同地址），probe 返回 0，OHOS 仍走慢路径（无回归）。与安全 H-C3（TLS 裸名 dlopen）一并处理，详见 `docs/plans/2026-09-23-ohos-tls-policy.md`。**［已修 `cfdba659d11`］**
9. **H8 close_range 探测缓存。** 首次探测后缓存结果；不可用时改读 `/proc/self/fd` 只处理真实打开的 fd。预期 spawn -8 ms/次。**［已修 `7f71107207b`］**
10. **H11 `WriteStatus` 尾部重建。** 只读文件尾部 64 KiB 重建，或每 32 行才 Trim 一次。预期 1.2 ms→~40 µs/行，消除 763 KB/行。**［已修 `1e04887`（实测 30–43 µs/行）］**
11. **H12 a11y id→index / 查询去线性。** native 维护 id→index（发布时增量建）；拷贝只在容量不足时 realloc。预期长列表查询 O(N²)→O(N)/O(1)（N=500 9.6 ms → <1 ms）。**［已修 `dde3037`］**
12. **P18 rawfile LRU + Exists 缓存 + 共享 Timer。** 与 H7 同批（managed 侧缓存，注意与 8 MiB 上限配合）。**［已修 `f2937413` + `02726dc`］**
13. **P11 `Describe` O(n·d)、P9 WeakReference、P19 零散分配。** 低风险清理项：`StringBuilder` 累积参数；滚动弱引用改标记/短 TTL；caret 宽度用 CharWidths 前缀和；Frame 参数复用。**［已修：P11 `48b91712`、P9 `316a1806`（空转 19→1 帧）、P19 `c05db90f`+`54bede0`（退役帧 184→96 B；无订阅者 0 分配；churn 有意保留）］**
14. **门禁加固（与上面并行，低风险高杠杆）。** (a) 交互/性能门禁加 `pull_request`（P14）；(b) preflight 与 CI 阈值统一到单一常量（P15：226 → 288）；(c) **alloc/frame 加断言**（先用修复后 72,864 B 的 3–4× 上限起步，防 P1/P6/H5 类回归）；(d) CI 加 `~/.nuget/packages`/`~/.dotnet` 缓存并删除 pixel 的第二次 run（P13）；(e) 复评 `tolerance=0` 用例与 2 条 KNOWN 的长期策略。**［a–d 已修 `d4d7cb7`/`d336bba`/`57d18c0`/`abd3451`/`5c2afb1`（tar 成员负测 27 项）；e 已文档化保留（不删/不放松）；alloc 门禁重定 13,824 B（3.07×）、jitter ≤ 2.0，CI 实测 3,720 B/帧 / jitter 1.21–1.43］**
15. **H10 图元点集零分配（原未列入清单，最终回填）。** CanvasBackend 的 `Points`/`RoundedPoints`/`ArcPoints` 改栈 `Span<float>`/复用缓冲、`Flatten` 复用多边形缓冲；130 图元/帧 98,204→**22,822 B**，余量 1144 B/帧属 Maui.Graphics `PathF.GetFlattenedPath`（所有权外）。**［已修 `9af70e9`］**

## 覆盖声明与不确定项

**覆盖。**

- **A：** `ohos-workload`（`host_napi.cpp` 3540 行、`openharmony_host.c` 2902 行、Hosting/Maui.Graphics 全量）；`maui-ohos` OpenHarmony 平台切片（渲染/事件/a11y/rawfile 相关文件，109 个 `.cs` 中抽查热路径）；`runtime-ohos` 全部 129 个 fork delta 文件（含 mono——确认 `src/mono` 仅有 AGENTS.md、无 OHOS 源码 delta，不硬凑；aspnet 8 个 delta 文件确认无运行时热路径）；另做 7 组本机微基准。未覆盖：MAUI 控件层自身 measure/arrange 成本、Skia 实际栅格化（无 surface）、设备端真机帧率。
- **B：** `maui-ohos` Platform/OpenHarmony 全部 109 个 `.cs` 的绘制/帧/a11y/列表/轮播/下拉/手势拖放/浮层/rawfile 路径（抽样精读 ~20 文件 + 全目录 grep）；`ohos-workload` 的 `test/{headless-render,maui-platform-verify}`、`scripts/{preflight,make-device-test-kit,verify-kit,release-all,tester-run,pack-workload-bundle}`、`.github/workflows` 全部 3 个、宿主原生绘制段（`openharmony_host.c` 的 draw_text/measure_text/image_bytes/polyline）；`sdk-ohos` 的 `OpenHarmonyCodesign`/`ElfSigner`/targets/`installnode`/`devcontainer`；Maui.Graphics 后端 `OpenHarmonyCanvasBackend.cs`。
- **后置批次（回填）：** `fix-perf2`（maui 渲染/触摸/轮播/文本/rawfile 缓存）、`fix-remain-a/b`（P17、H7、头注、RID 图、pin）、`fix-gates`（断言/阈值/缓存/PR/tar 负测）、`fix-sdk`（P12/CLI/pin）、`fix-host2`（H8/H11/H12 harness）；本报告复跑 h11/pal_fd/a11y_query 三个 harness 验证数字。
- **最终回填：** H10 `9af70e9`、P16 `c660755`（ow）、P9 `316a1806`、P10/P19 `c05db90f`（maui）+ `54bede0`（ow hosting）；数字来自各仓提交记录与离机 harness（CanvasBackend 微基准、163.5 MB kit 5 轮交错、anim-driver/颜色 harness），本报告未再上机复跑。

**不确定项。**

- ① native 图元创建成本：无 canvas 版（Rect+Brush 0.23 µs）与有 canvas 版（2.8 µs/矩形、6.9 µs/折线）差异大，前者不代表真实绘制；② H2 的 mmap 模型是匿名页，真实路径为 fd-backed（页缓存缺页更便宜），6.99 ms 的实际值可能更低，但"每帧 mmap/munmap"结构性问题成立；③ 微基准机 31 GB 内存已满（仅 650 MB free），缺页/分配被放大；④ 手机端 `RLIMIT_NOFILE` 是否同为 32768 未验证（H8 成本按 0.24 µs/fd 线性放大）；⑤ 未在设备上跑真实 HAP，所有"每帧"数字是模型实测 × 频率假设。
- ⑥ ArkTS 完整 shell 源码不在五仓内（只有预编译 `modules.abc` + 精简 EntryAbility 模板），TSFN 往返、base64 编码、消息频率等 shell 侧开销不可静态确认（P4/P18/H7 的 shell 侧只到模型级）；⑦ 241,688 B/帧的逐项归因是推断（未加插桩、未新建测量程序以免触发构建），P1/P6/P7 的迭代器字节数是编译器实现估计；⑧ 未在真机运行，设备 IO/GPU 表现可能与 OpenHarmony host（Debug harness）不同；⑨ `OpenHarmonyBlazorWebView.cs:96-118` 的逐请求 `File.Exists`+字符串归一化仅记为低收益（每页加载数百次），未列入热点表；⑩ 除复用的两份已构建 harness 二进制外无其他动态测量，唯一"新测量"是 `sha256sum`/`tar` 与 NDK/csc 微基准。
- 与安全报告的交叉项：P12 的签名任务同时是安全 D-1/D-5 的修复面；H3 与 H-C3 同属 TLS 配置域（性能固定与安全加固应一并上机验证）。
- **后置批次数字口径：** 来自修复代理的提交记录/离线 harness（`fix-remain-b/managed-bridge-test`、`fix-host2/h11test`、`fix-perf2/final2-summary`、CI 35858501620/35858501647），本报告复跑 h11/pal/a11y 三个 harness 得出 30.3 µs/行、0.31 ms、2.67/4.65/7.88 ms；轮播 after 以提交实测 441.2 ms 为准（本机 off-device 复跑的 1670.7 ms 受 native-miss 路径支配，两者口径不同）。均未上真机：轮播缓存语义（分组/IEnumerable 不缓存）、H11 尾部重建在设备 IO 下的表现、P17 的 fstat/rename 语义、H8 手机端 `RLIMIT_NOFILE` 仍属不确定项。最终回填同为离机口径：H10 的 `Flatten` 余量 1144 B/帧归 Maui.Graphics（本仓不可消）、P19 订阅 churn 为有意保留（锁内回调死锁证据 + `s_frameHandlers` 审计钉缝）、P16 复用以「快照证明未动 + 首次必真实读」为前提（设备侧失败即回退重算）。
