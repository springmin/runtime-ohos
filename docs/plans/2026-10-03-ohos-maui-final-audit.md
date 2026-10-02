# MAUI 移植完整性终审（FINAL-AUDIT，2026-10-03）

> 审计源：backlog `2026-09-28-ohos-maui-port-backlog.md`（§2.2 逐项）· 覆盖矩阵 `2026-09-22-ohos-maui-coverage-matrix.md`
> （kit #41 行）· `2026-10-03-ohos-tester-handoff-kit41.md` §1.5/§7（在途/不判失败）· `2026-09-24-ohos-kit-gap-analysis.md` ·
> 近两日报告「剩余/缺口/不确定」段（final-consolidation、interp-frame、interp-fix、payload-sign、multi-overlay、kit39–41-local、
> mode-matrix、wave9/10、rc2-aotpack、mirror-fix、jit-local）。
> 方法：逐项复核到提交/代码/远端/设备记录；分类 = 本地可执行 / 平台或外部依赖 / 样例级。
> **本轮已做（核实类，无代码改动）**：三仓远端 tip 核对（maui `07423dfe93`、ohos-workload `4bfcd68`、sdk `2222ba959f`）；
> 本机 rc2 实跑 `selftest-tasks` **9/9 PASS**；矩阵 §1b 抽查 `OpenHarmonyAppLauncher.cs`/`KeyListener`/`FocusManager`/`Screenshot`；NATIVE-AOT 文档远端核对。
> 结论：**≤S 本地项 = 0（可立即执行项均已闭合）；本地可执行存量 = 5 项（M×4 / L×1）+ 2 项低优先（M/L）**；其余为平台/外部或样例级。

## 1. 已闭合（本轮核实，勿再复提）

1. **backlog W4–W11 全 20 项**（T8/T6/N2/A2/T13/N3/T21/T22/T14/T12/N1/T15/T16/N4/T17/T18/N5/N6/T19/T20）：已由 #33–#35 各波并入主线
   （T6 `93ba1cc3a9`、N2 `f96d484b20`；A2 后由 pin 推进覆盖，现 pin `07423dfe93`、套件 563/floor 543）。
2. **kit #41 在途②「hello-maui-app Blazor `#app` 缺 modules.json」已过期**：`0e0129e` 起该演示页按设计不再承载 BlazorWebView
   （`App.cs` 注释 ~227/272；`.razor` 面由 hello-maui-razor + 套件覆盖）。
3. **kit #41 在途③「stock JIT 未单独复测」已闭合**：KIT41-LOCAL §3 已复测装/启，崩点由 `+440`（栈探针）移到 `+996`（写屏障 memcpy）
   = 平台 exec 内存墙 → 8 MB 栈修复生效（残余属 §3 外部）。
4. **`selftest-tasks` S3 漂移**（rc2-mainline §7#2）：本机 rc2 实跑 9/9，task 程序集已在后续波次重锚。
5. **NATIVE-AOT 文档漂移**（rc2-mainline §7#3）：`origin/feature/openharmony` 已含 `f351f7be90`+`4e3f16ceb1`（rc.2 文档），
   本地旧分支误报。
6. **mode-matrix §5 未决①②、#38/#39「在途」项、W9 §4 B2 入口/T19 `delivered=0`**：已由 #39–#41
   （FIX-BACKSIZE/BWVMount/JSCALL、DEVCOMPAT、MULTI-OVERLAY-FULL；热深链 `delivered=1`）闭合。
7. **矩阵 §1b 部分「仍未闭合」**：Subject/Title 与 `file://` 读授权已落地（`OpenHarmonyAppLauncher.cs` 5 参导出 +
   CONTENT_TITLE_KEY / FLAG_AUTH_READ_URI_PERMISSION）；ConnectionProfiles/SoftInput 已由后续提交修正；焦点/硬件键**内部面已落地**
   （`FocusManager`/`KeyListener` + 壳 `Index.ets:6230` onKeyEvent），公开面待上游 E6。

## 2. 本地可执行剩余（任务卡）

| # | 任务 | 规模 | 目标 | 门禁 |
|---|---|---|---|---|
| L1 | z-order 重叠控件真机截图（两覆盖层重叠 + 激活置顶） | M | hello-maui-app 加重叠布局入口 → AOT 重建/重签/安装 | 既有 z-order 断言 + 截图/hilog |
| L2 | rc.2 csc 并行活锁定位（去掉 `DOTNET_PROCESSOR_COUNT=1` 绕过） | M | runtime-ohos `scripts/ohos-runtime-interp-fullbuild.sh` + sdk-ohos 构建 | 冷/热 `clr.native` 复现 + 全链 |
| L3 | WebAuthenticator 真流程①：`module.json` `skills[].uris` 声明机制 + 深链回调 A/B | M | Hap targets 生成/声明 + 壳 want 路由 | tasks 单测 + 真机 want 投递 |
| L4 | AOT pack 结构性修复（共享 `.so` 静态 OpenSSL vs 静态 `.a` shim 拆分） | L | sdk-ohos `build-ohos-all.sh`/`build-native.sh` | nm 判据 5/5 + cryptotest A/B + 设备 dlopen |
| L5 | `ohos-release-mirror.yml` 覆盖 `workload-*` releases（workload 源 + merged sums 两行重写 + 触发） | M | sdk-ohos CI | workflow_dispatch 干跑 + sums/尺寸校验 |
| L6 | 低优先：Screenshot `Jpeg`（现回 PNG 并记一次状态）；`window.Title` 生命周期心跳（W9D §3） | M | 壳 image packer / 标题重推 | 图像格式断言 + 真机 |
| L7 | 低优先：legacy compatibility renderers / Core Toolbar（矩阵 §3 旧表述；ToolbarItems 已由 ShellChrome 镜像） | L | 切片兼容面 | 切片 + 套件门禁 |

## 3. 平台 / 外部依赖（本地不可闭合）

- **执行内存墙（首因）**：HAP 域拒绝全部 exec 策略（探针 7 项）→ JIT/interp 均止步 CoreLib 装载；需平台放开 anon RX / memfd W^X /
  签名 PE RX 之一。解释器首帧、in-app 匿名映射枚举、`interp.txt=1|2` 差分同归此类。
- **HMS/AGC + HarmonyOS SDK**：Share/Scan/Push/Account/Map/LiveView/TTS 真调用；MediaElement 真机播放（本机镜像无 MediaKit）。
- **tester 机**：三大修复复核、预签包、DEVCOMPAT 4096 B（7.0.0.105）、JIT 主判、冷深链 managed 判定。
- **上游/组织**：MAUI 键契约 E6、Blazor WASM 发布链 dnceng→nuget E7、VisualDiagnosticsOverlay tap E8、Hot Reload E4、arm32 E5、
  真多窗 E3（backlog §3 口径）、ship-the-slice 上游交付（矩阵 §7#2，L）。

## 4. 样例级（不进交付判定）

- `#app` 残留与 `App.cs:227` 旧注释（代码已是 hybrid C）；`blzProbe` 未定义；live `Navigate` 无入口；FULL 演示无同页 Blazor 入口；
  真触摸屏注入/轮播手势未复测（2in1 无触摸）；异 bundle 复用预编译壳的 jscrash（既有，重出壳即解）。

## 5. 结论

- **本地可执行是否=0：≤S 可立即执行项 = 0**（§1 均已闭合/核实）；**剩余本地存量 = 7 项**（§2：M×5、L×2，其中 2 项低优先）。
  其余未闭合项全部属 §3 平台/外部依赖或 §4 样例级，本地不可闭合。
- 提交：本文件（精确路径提交，未强推）。
