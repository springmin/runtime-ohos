# 五仓 OpenHarmony 移植性能扫描（2026-09-23）

**范围：** `runtime-ohos`、`aspnetcore-ohos`、`ohos-workload`、`maui-ohos`、`sdk-ohos`。
**关联：** 安全面见 [`2026-09-23-ohos-security-scan-2.md`](2026-09-23-ohos-security-scan-2.md)；本报告与安全扫描同日、同机、同一批评测。

## Verdict

**PASS WITH FINDINGS（高收益热点已收敛；门禁待加固）。** 两路扫描（A 运行时/宿主/原生 + B 托管/UI/工具链与 CI）共定位 **31 个热点**（A 12 + B 19），全部带量化与 `文件:行` 证据。固定窗口内修复 **10 个高收益热点**（H1/H2/H4/H5/H6/P1/P3/P4/P6/P8；H9 在 host 侧缓解：measure 成本 -53%），量化收益：**帧分配 241,688 → 72,864 B/帧（-70%）**、a11y Refresh **149,496 → 0 B**/未变帧、HasAnimations **38,632 → 0 B**（N=401 空闲）、text.hot **14.0 → 9.1 µs**/文本、image.steady **6.03 → 1.67 ms**/draw、present **0.74 ms**（缓存）vs **5.34 ms**（每帧 mmap）、measure_text 1.49 → 0.70 µs、effects 0.59 → 0.50 µs/fill，并顺带修复图片 **src_rect 渲染错误（FAIL → PASS）**。回归全绿：交互套件 **308 checks / floor 288**、像素套件 **PIXEL ASSERTIONS PASSED**（2,399,395 次像素写与基线逐位一致）、切片独立构建 0 错误。

**门禁现状：** 现有门禁"不会误报"，但**几乎拦不住 2–4× 的性能回归，且完全不拦分配回归**——帧预算只用掉 **20.6%**、a11y 各项余量 1–100×、alloc/frame 只打印不断言、preflight 阈值 226 < CI 288、pixel 套件在 CI 跑 2 次且无缓存、交互/性能门禁不上 PR、`tolerance=0` 用例脆弱。剩余 21 个热点留档，其中 4 个结构性大项：**DrawView `ChildrenOf` 迭代器（修复后 42,766 B/帧的主要残余）**、H3 TLS 优化（需设备验证）、P12 ElfSigner 每文件 `ReadAllBytes` + 无 `Inputs`/`Outputs`、P16 kit 多遍整读。所有"每帧"数字都是模型实测 × 频率假设，未在真机跑真实 HAP。

**发布：** kit #18（`device-test-kit`，2026-09-23 发布，115,905,186 B / `29be0590…`，maui-ohos pin `c730226f93`）已含本报告全部已修项（FIX-P1 `46b4e0f`、FIX-P2 `8e4de06f` 及其后的 MB/H-C2 修复）；未修项（H3/H7/H8/H10/H11/H12/P16 等）仍留档。

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
| H3 | OHOS(musl/arm64) 编译期关闭 TLS 优化 → 线程静态访问慢路径 | `runtime-ohos/src/coreclr/vm/threadstatics.cpp:1025-1026,1036`；`jitinterface.cpp:1228,1442-1453`；`jit/helperexpansion.cpp:1048-1051 vs 1077-1111` | [推断] 线程静态访问多 3–4 指令 + 1 分支 → 静态字段密集代码 1.5–3× | 探测已实现（OHOS 参与 `IsValidTLSResolver()`，失败保持现状）；设备实测 musl 解析器为动态序列 → probe=0，仍走慢路径，无回归 |
| H4 | a11y 每帧重建节点表 + 每节点 ≤4 次 native malloc + 4 次 P/Invoke marshal | `maui-ohos/.../OpenHarmonyAccessibility.cs:465-475,481-514,62-87`；`openharmony_host.c:2788-2839` | Refresh **157 KB/帧 + 113 µs**（N=200）；Publish diff+ActionsFor 12.8 KB/帧；合计 220 KB/帧 ≈12.6 MiB/s Gen0@60fps + 每帧约千次 malloc/free | **已修** `8e4de06f` |
| H5 | 每帧全树递归探测动画（无缓存） | `OpenHarmonyWindowRenderer.cs:350,395-413` ← `OpenHarmonyMauiAppHost.cs:69-72` | N=200 17.7 KB/28 µs；N=500 44.1 KB/71 µs（~88 B/节点迭代器）；空闲也跑 | **已修** `8e4de06f`（0 B 空闲） |
| H6 | `ActionsFor(role)` 每次新数组 + 接口枚举器 | `OpenHarmonyAccessibility.cs:62-87,506` | 108 B、105 ns/次 → N=200 每次发布 21.6 KB + 21 µs | **已修** `8e4de06f`（bitmask） |
| H7 | rawfile 8 MiB 整文件 base64（无分块、同步编码） | `packs/.../preview.24/.../Index.ets:1979-1984`；`host_napi.cpp:2067-2098`；`OpenHarmonyFileSystem.cs:212-215` | 单次 13.9 ms / 30.8 MB 分配（PtrToStringUTF8 22.4 MB + FromBase64String 11.7 MB）；shell `encodeToStringSync` 阻塞 UI 35–48 ms/8 MiB | 未修 |
| H8 | OHOS `Process.Start` 走全 fd `fcntl` 扫描 | `runtime-ohos/src/native/libs/System.Native/pal_process.c:253-283,302-309,915` | RLIMIT_NOFILE=32768 → **8.0 ms/次** spawn（≈0.24 µs/fd） | 未修 |
| H9 | `DrawString` 每文本 2 次 native `MeasureText` | `Microsoft.OpenHarmony.Maui.Graphics/OpenHarmonyCanvasBackend.cs:238-268` | measure 1.47 µs/次；30 文本/帧多 45 µs + 多一次 P/Invoke/marshal | **部分** `46b4e0f`（host measure 1.49→0.70 µs；managed 双调用结构未改） |
| H10 | 图元点集每次分配（params 数组/tuple/List+ToArray/闭包） | `OpenHarmonyCanvasBackend.cs:61-73,82-95,181-199,221-235` | `Points(4)` 112 B/49 ns；圆角≈5 次分配；130 图元/帧 50.5 KB/58 µs | 未修 |
| H11 | `WriteStatus` 超 256 KiB 后每行 O(文件) 重写 | `Microsoft.OpenHarmony.Hosting/OpenHarmonyApp.cs:648-673,679-711` | 未满 37 µs/行（617 B）；饱和后 **1205 µs/行 + 763 KB/行**（3354 行 ReadAllLines+WriteAllLines） | 未修 |
| H12 | a11y provider 查询线性/含 O(N²) + 每 probe 4 次字符串拷贝 | `host_napi.cpp:3136-3147,3234,3256,2923-2929`；`openharmony_host.c:2867-2898` | probe 38.6 ns；N=200 最坏 ≈1.5 ms、N=500 ≈9.6 ms（findById+PREFETCH_CHILDREN O(N²)） | 未修 |

### B. 托管 / UI / 工具链与 CI（19）

| 编号 | 热点 | 文件:行 | 量化 | 状态 |
|---|---|---|---|---|
| P1 | 宿主每帧全树遍历（与脏标记无关） | `OpenHarmonyMauiAppHost.cs:69-80` + `OpenHarmonyWindowRenderer.cs:350,395-413` | 401 节点 ≈24 KB/帧 ≈1.4 MB/s 空转；空闲 UI 也全树走查 | **已修** `8e4de06f`（空闲 0 B） |
| P2 | 轮播指示点每帧重建整个 ItemsSource | `OpenHarmonyWindowRenderer.cs:359` → `OpenHarmonyCarouselViewHandler.cs:186-207` | N=1000 项 8 KB/帧 + 1000 次枚举/帧（N=100 ≈0.8 KB/帧）；只为取 Count | 未修 |
| P3 | 每次 `FillColor` 赋值触发原生 `ClearEffects` | `Microsoft.OpenHarmony.Maui.Graphics/OpenHarmonyCanvasBackend.cs:35-43` | 每帧数百次 P/Invoke（401 节点页 300–600 次/帧）；effects 0.59→0.50 µs/fill | **已修** `46b4e0f`（脏标记） |
| P4 | 每帧全量重新解码图片 | `OpenHarmonyView.cs:863-882` → `Hosting/OpenHarmonyApp.cs` → `openharmony_host.c:2437-2463` | 1 MB PNG 每帧完整解码（数 ms/图/帧）+ 每帧新建 2 Rect/Sampling；src 矩形误用目标宽高（尺寸 bug） | **已修** `46b4e0f`（缓存 + src_rect 修复） |
| P5 | 文本测量与 TextBlob 重建（无缓存） | `OpenHarmonyStyledViews.cs:336,353,366,422` + `OpenHarmonyLabelHandler.cs:53-62` + `openharmony_host.c:2308-2354,2384-2408` | 单行每帧 3 次原生 measure（各建/毁 Font）+1 次绘制；401 页 ≈1000+ 次/帧；CharacterSpacing≠0 时逐字符 O(n) 分配 | 未修 |
| P6 | a11y 每帧重建影子树（2 字典 + 每节点 List + record） | `OpenHarmonyAccessibility.cs:472-480,512-530` | 401 节点 ≈82 KB/帧（skip 只省 host 流量：publish skip 0.033 ms） | **已修** `8e4de06f`（稳态 0 B） |
| P7 | 每次按下 8 次全树递归搜索 | `OpenHarmonyWindowRenderer.cs:565,582,587,670-683,752` | 401 节点 → 8×401 访问 + ≈3200 迭代器/次按下；拖拽每 move 再 401 节点 | 未修 |
| P8 | 动画循环每帧 `ToArray` 快照 | `OpenHarmonyAnimationLoop.cs:173` | 1 数组/帧（通常 32 B）+ 偶发 finished List；低收益 | **已修** `8e4de06f`（池化） |
| P9 | 滚动偏移每帧 `new WeakReference` + 停止后 300 ms 空转 | `OpenHarmonyScrollPhysics.cs:223,97-111` | fling 60 次/s WeakReference（≈24 B）+ 2 次 lock/帧；停手后再白跑 18 帧 | 未修 |
| P10 | 下拉/浮层/日历每帧全量绘制全部行 | `OpenHarmonyView.cs:961-990,156-171,209-266` | 200 项 Picker ≈200 次 measure+draw/帧（叠加 P5 → ≈600 原生调用/帧）；DrawCalendar 每帧字符串格式化 | 未修 |
| P11 | `Describe` 递归 O(n·深度) 字符串复制 | `OpenHarmonyWindowRenderer.cs:1159-1162`；调用点 `OpenHarmonyMauiAppHost.cs:600` 等 7 处 | 深度 d 节点被复制 d 次；verify 用 150 层树取长度 | 未修 |
| P12 | 每次 Build/Publish 对全部输出文件 `ReadAllBytes` 签名 | `sdk-ohos/src/Tasks/Microsoft.NET.Build.Tasks/ElfSigner.cs:51-58` + `OpenHarmonyCodesign.cs:32` + `Microsoft.NET.Sdk.targets:891-900` | 某 MAUI 应用输出 532 文件/171 MB（26 个 ELF/30 MB；.hap 32 MB 也被整读）→ 每次 175 MB 读 + 2×32 MB LOH + 30 MB Merkle SHA-256 ≈0.5–1 s + GC；无 `Inputs`/`Outputs` → 每次都跑 | 未修 |
| P13 | CI 双 workflow 重复 restore/build，无缓存，pixel 跑两遍 | `interaction-regression.yml:58-87`、`pixel-regression.yml:46-84` | 每次 push/PR 重复 2 份 restore + 2 份同程序集构建；pixel 套件本机单次 6.4 s 跑 2 次 | 未修 |
| P14 | 交互/性能门禁不在 PR 上执行 | `interaction-regression.yml:34-35`（仅 push master+dispatch）vs `pixel-regression.yml:18` | 性能回归只能在合并后被 20 ms/250 ms 的宽松预算发现 | 未修 |
| P15 | preflight 阈值弱于 CI 且强制全量重建像素套件 | `scripts/preflight.sh`（`-lt 226` vs CI `-lt 288`；`rm -rf bin` + `dotnet run -c Release`） | 本地可在缺 62 条断言下 PASS；每次预检重建 headless-render（含 P12 签名路径） | 未修 |
| P16 | 110 MB 设备测试包被整读 4–6 遍并重复压缩 | `make-device-test-kit.sh:370-403` + `verify-kit.sh:72-81` + `tester-run.sh:491-518,1214` | SHA-256 0.15–0.22 s/103 MB；`tar -czf`(103 MB 已压缩 hap) 3.24 s→86.6 MB；kit 实存 115,822,672 B → 每轮 ≈4–5 遍整读 + 1–2 次 deflate | 未修 |
| P17 | 应用每次启动都重新 copy+解压 `dotnet.zip` | `packs/.../preview.24/.../EntryAbility.ets:92-101` | 内层 16 MB zip → 40.5 MB/253 文件；每次启动 copy 16 MB + inflate 40 MB + 建 253 文件（[推断] 0.3–1 s/次，手机更高） | 未修 |
| P18 | rawfile 回退无缓存 + base64 三份拷贝 + Exists/Read 两次往返 | `OpenHarmonyFileSystem.cs:104-215` | 8 MiB 文件 ≈30 MB 瞬态峰值/次；同一资源 N 次访问 = N 次往返；超时 `Task.Delay(3s)`/次 | 未修 |
| P19 | 每帧零散分配（补充 P3/P5） | `OpenHarmonyView.cs:819`（caret 子串）、`OpenHarmonyStyledViews.cs:362`（逐字符 `ToString()`）、`OpenHarmonyAnimationLoop.cs:64`、`OpenHarmonyApp.cs:1046`（每帧 `new FrameEventArgs`） | 焦点 Entry 每帧 1 个 O(n) 子串 + 1 次原生测量 | 未修 |

## 已修项 before/after

| 编号 | before | after | 验证 | 提交 |
|---|---|---|---|---|
| H1 | text.hot ≈12.5–14.0 µs/文本 | **9.1–9.7 µs**（单轮 9.4）；主机 bench：热进程每文本 11.6–12.9 → 5.5–5.9 µs | `compare-final.txt` 5 轮交错；text.cold/long 不回归 | ow `46b4e0f` |
| H2 | present 每帧 mmap/munmap 5.34 ms/帧（单轮 4.75–7.00） | **0.74 ms/帧**（缓存；单轮 0.55–0.61）；`present.new_remap` 4.8–5.2 ms 证明是缓存收益 | 同上；设备侧提交记录 4.70→0.55 ms | ow `46b4e0f` |
| P4 | image.steady 6.03 ms/draw（单轮 5.33–7.38）；src_rect **FAIL** | **1.67 ms/draw**（单轮 1.62–1.64）；src_rect **PASS**（四角 00ff/ff00/ff00ff/ffffff 正确） | 3.1 MB PNG；2×2 象限探针 | ow `46b4e0f` |
| P3 | effects.shadow300 0.597 µs/fill | **0.50–0.55 µs/fill** | 同上 | ow `46b4e0f` |
| H9 | measure 1.49 µs/文本 | **0.70 µs/文本**（host 字体缓存；managed 仍每文本 2 次测量） | 同上 | ow `46b4e0f` |
| H4/P6 | a11y Refresh 149,496 B/未变帧（157 KB/帧、113 µs，N=200） | **0 B**/未变帧；单 label 变更 6,616 B/次；render skip 0.359→**0.262 ms**、republish 4.444→**2.782 ms**、ratio 12.37→10.6×（floor 1.25） | 隔离探针 + `final-interaction.txt` | maui `8e4de06f` |
| H5/P1 | HasAnimations N=401 空闲 38,632 B / 146.87 µs（N=200 19,336 B/88.98 µs） | **0 B / 0.04 µs**（N=401）；有 spinner 注册时保持原走查（决策不变） | 动画模型探针（perf-a H5 形状） | maui `8e4de06f` |
| H6 | `ActionsFor` 108 B/105 ns/节点 → N=200 21.6 KB/发布 | bitmask（发布循环 0 B 数组） | a11y publish 探针 0 B/call | maui `8e4de06f` |
| P8 | 动画循环每帧 `ToArray` | 池化快照 | 套件 + 代码 | maui `8e4de06f` |
| 帧分配 | `allocDelta=48,337,600 B → 241,688 B/帧`；avg=7.499 ms（修复前基线） | `allocDelta=14,572,800 B → **72,864 B/帧**`；avg=**5.714 ms**；`./verify` real 20.62→13.03 s（复跑 11.56 s） | 同一 harness（Debug）；308 checks、0 Unhandled | maui `8e4de06f` + pin `d43dfb5`/`195dd3e` |
| 回归 | 像素基线 2,399,395 pixel writes | `PIXEL ASSERTIONS PASSED`、2 条 KNOWN 不变、writes **2,399,395 相同**；切片独立构建 0 错误 | Release headless-render | ow `d43dfb5`/`195dd3e` |

> 数字口径：before/after 取固定批次 `fix-p1` 的 5 轮交错最小/代表值与 `fix-p2` 的套件日志；门禁分析中的 4.112 ms 为 perf-b 扫描时的另一会话负载（同一预修二进制），两者不可直接混比。所有测量均为同机模型/harness，非真机 HAP。

## 门禁余量分析

| 门禁 | 阈值 | 实测（扫描时） | 余量 | 问题 |
|---|---|---|---|---|
| 帧 avg | ≤ 20 ms | 4.112 ms | **4.9×（用掉 20.6%）** | 修复后 5.714 ms 仍余 3.5×；宽松预算拦不住 2–4× 回归 |
| 帧 max | ≤ 250 ms | 6.804 ms | 36× | 同上 |
| 帧 max−avg | ≤ 100× | 1.65× | 60× | 同上 |
| alloc/frame | **无断言（只打印）** | 241,688 B ≈ **14 MB/s @60fps**（修复后 72,864 B ≈4.4 MB/s） | — | 分配类回归目前零门禁；P1/P6/H5 属于此类 |
| a11y render skip | avg ≤ 20 ms | 0.359 ms（修复后 0.262） | 56× | 阈值极宽 |
| a11y render republish | avg ≤ 50 ms | 4.444 ms（修复后 2.782） | 11× | 同上 |
| a11y ratio render / publish | ≥ 1.25× / ≥ 2× | 12.37× / 114.2×（修复后 10.6× / 74.89×） | 10× / 57× | 断言的是"跳过有效"，不是成本上限 |
| a11y budget elapsed | ≤ 2000 ms | 292 ms（修复后 191） | 6.8× | 同上 |
| 像素容差 | 默认 ±24/255 | 通过；**1 个用例 `tolerance=0`**（button rounded corner，精确 DarkSlateBlue） | — | 对 1/255 级抗锯齿变化敏感，易碎 |
| 本地 preflight | `-lt 226` | CI 为 `-lt 288` | 本地缺 62 条 | 本地可带缺口 PASS（P15） |
| CI 覆盖 | pixel 在 push/PR | interaction/perf 仅 push master + dispatch | — | PR 阶段看不到 perf 回归（P14） |
| CI 缓存/重复 | 无 NuGet/SDK 缓存；pixel 同 suite 跑 2 次 | 每次 push/PR 双份 restore/build | — | 墙钟与出网流量浪费（P13） |

**结论：** 现有门禁"不会误报"，但**几乎不会拦住 2–4× 的性能回归，且完全不拦分配回归**——本轮 241,688 B/帧、149,496 B/帧、38,632 B/帧 这三类问题在修复前都能静默通过全部门禁。

## 建议后续（按收益排序）

1. **P5 + P10 + P2（文本/弹层/列表，最大剩余 UI 帧收益）。** managed 侧 `(text,size)→宽高` LRU；host 侧 Font/Typeface/TextBlob 缓存（H1 已提供基础设施）；逐字符路径改整串测量；Picker/日历只画视口行 + 缓存月份/日期串；Carousel 指示点缓存 Count（O(N)/帧 → O(1)/帧）。预期：401 节点页 ≈1000+ 次原生调用/帧降至 1/3。
2. **DrawView `ChildrenOf` 迭代器重构（修复后的主要残余）。** 探针显示修复后帧内分配 46,768 B/帧中 **DrawView 42,766 B/帧**（每节点 `ChildrenOf` 迭代器，Debug 码型），其次 measure+arrange 32 B/帧。改为索引/池化遍历可把 72,864 B/帧再压一个量级。
3. **P7 触摸路径 8 次全树 → 1 次。** 合并 `FindPointerTarget`/`FindOpenPopup`/`FindOpenFlyout`/`FindScrollView`/`FindSlider`/`FindDragTarget`/`FindGestureTarget`/`HandleTouchCore` 为一次带谓词遍历并在 down 时缓存；拖拽 move 复用候选集。预期触摸延迟与 ~3200 迭代器/次归零。
4. **P12 ElfSigner 构建期成本。** 先读 64 B 判 ELF magic 再 `ReadAllBytes`；按扩展名跳过 `.hap/.pdb/.json`；流式 Merkle（不整文件驻留）；加 `Inputs`/`Outputs`/stamp 增量（已签名有效即跳过）。预期每次 Build/Publish 省 175 MB 读 + 64 MB LOH + 0.5–1 s。与安全报告 D-1/D-5 的修复同一文件，改动需保持"已签名有效则跳过"语义与字节级断言。
5. **P17 启动解压跳过。** 已解压目录存在且 zip 大小/mtime 未变则跳过（写 marker），处理升级/半解压。预期每次冷启省 16 MB copy + 40 MB inflate + 253 次建文件（0.3–1 s）。
6. **P16 kit 摘要/压缩复用。** 树摘要复用已验证的 `SHA256SUMS` 内容（不再逐文件读）；证据包只记录已打包 hap 的 hash/路径。预期每次 kit 省 2–3 遍 110 MB 读 + 1 次 deflate（≈3.4 s）。
7. **H7 rawfile fd 直读/分块。** 用已有 `{fd,offset,length}` 走 native `pread`（或 256 KiB 分块 + 复用缓冲）。预期拷贝 4→1、瞬态 -98%、UI 不阻塞（35–48 ms/8 MiB → 接近无感）。
8. **H3 TLS resolver（已实现，设备实测 probe=0）。** OHOS 现走 `IsValidTLSResolver()` 指令序列探测，静态解析器才启用、失败保持现状；实测 musl 的 TLSDESC 解析器为动态序列（`mrs TPIDR_EL0` + 每线程不同地址），probe 返回 0，OHOS 仍走慢路径（无回归）。与安全 H-C3（TLS 裸名 dlopen）一并处理，详见 `docs/plans/2026-09-23-ohos-tls-policy.md`。
9. **H8 close_range 探测缓存。** 首次探测后缓存结果；不可用时改读 `/proc/self/fd` 只处理真实打开的 fd。预期 spawn -8 ms/次。
10. **H11 `WriteStatus` 尾部重建。** 只读文件尾部 64 KiB 重建，或每 32 行才 Trim 一次。预期 1.2 ms→~40 µs/行，消除 763 KB/行。
11. **H12 a11y id→index / 查询去线性。** native 维护 id→index（发布时增量建）；拷贝只在容量不足时 realloc。预期长列表查询 O(N²)→O(N)/O(1)（N=500 9.6 ms → <1 ms）。
12. **P18 rawfile LRU + Exists 缓存 + 共享 Timer。** 与 H7 同批（managed 侧缓存，注意与 8 MiB 上限配合）。
13. **P11 `Describe` O(n·d)、P9 WeakReference、P19 零散分配。** 低风险清理项：`StringBuilder` 累积参数；滚动弱引用改标记/短 TTL；caret 宽度用 CharWidths 前缀和；Frame 参数复用。
14. **门禁加固（与上面并行，低风险高杠杆）。** (a) 交互/性能门禁加 `pull_request`（P14）；(b) preflight 与 CI 阈值统一到单一常量（P15：226 → 288）；(c) **alloc/frame 加断言**（先用修复后 72,864 B 的 3–4× 上限起步，防 P1/P6/H5 类回归）；(d) CI 加 `~/.nuget/packages`/`~/.dotnet` 缓存并删除 pixel 的第二次 run（P13）；(e) 复评 `tolerance=0` 用例与 2 条 KNOWN 的长期策略。

## 覆盖声明与不确定项

**覆盖。**

- **A：** `ohos-workload`（`host_napi.cpp` 3540 行、`openharmony_host.c` 2902 行、Hosting/Maui.Graphics 全量）；`maui-ohos` OpenHarmony 平台切片（渲染/事件/a11y/rawfile 相关文件，109 个 `.cs` 中抽查热路径）；`runtime-ohos` 全部 129 个 fork delta 文件（含 mono——确认 `src/mono` 仅有 AGENTS.md、无 OHOS 源码 delta，不硬凑；aspnet 8 个 delta 文件确认无运行时热路径）；另做 7 组本机微基准。未覆盖：MAUI 控件层自身 measure/arrange 成本、Skia 实际栅格化（无 surface）、设备端真机帧率。
- **B：** `maui-ohos` Platform/OpenHarmony 全部 109 个 `.cs` 的绘制/帧/a11y/列表/轮播/下拉/手势拖放/浮层/rawfile 路径（抽样精读 ~20 文件 + 全目录 grep）；`ohos-workload` 的 `test/{headless-render,maui-platform-verify}`、`scripts/{preflight,make-device-test-kit,verify-kit,release-all,tester-run,pack-workload-bundle}`、`.github/workflows` 全部 3 个、宿主原生绘制段（`openharmony_host.c` 的 draw_text/measure_text/image_bytes/polyline）；`sdk-ohos` 的 `OpenHarmonyCodesign`/`ElfSigner`/targets/`installnode`/`devcontainer`；Maui.Graphics 后端 `OpenHarmonyCanvasBackend.cs`。

**不确定项。**

- ① native 图元创建成本：无 canvas 版（Rect+Brush 0.23 µs）与有 canvas 版（2.8 µs/矩形、6.9 µs/折线）差异大，前者不代表真实绘制；② H2 的 mmap 模型是匿名页，真实路径为 fd-backed（页缓存缺页更便宜），6.99 ms 的实际值可能更低，但"每帧 mmap/munmap"结构性问题成立；③ 微基准机 31 GB 内存已满（仅 650 MB free），缺页/分配被放大；④ 手机端 `RLIMIT_NOFILE` 是否同为 32768 未验证（H8 成本按 0.24 µs/fd 线性放大）；⑤ 未在设备上跑真实 HAP，所有"每帧"数字是模型实测 × 频率假设。
- ⑥ ArkTS 完整 shell 源码不在五仓内（只有预编译 `modules.abc` + 精简 EntryAbility 模板），TSFN 往返、base64 编码、消息频率等 shell 侧开销不可静态确认（P4/P18/H7 的 shell 侧只到模型级）；⑦ 241,688 B/帧的逐项归因是推断（未加插桩、未新建测量程序以免触发构建），P1/P6/P7 的迭代器字节数是编译器实现估计；⑧ 未在真机运行，设备 IO/GPU 表现可能与 OpenHarmony host（Debug harness）不同；⑨ `OpenHarmonyBlazorWebView.cs:96-118` 的逐请求 `File.Exists`+字符串归一化仅记为低收益（每页加载数百次），未列入热点表；⑩ 除复用的两份已构建 harness 二进制外无其他动态测量，唯一"新测量"是 `sha256sum`/`tar` 与 NDK/csc 微基准。
- 与安全报告的交叉项：P12 的签名任务同时是安全 D-1/D-5 的修复面；H3 与 H-C3 同属 TLS 配置域（性能固定与安全加固应一并上机验证）。
