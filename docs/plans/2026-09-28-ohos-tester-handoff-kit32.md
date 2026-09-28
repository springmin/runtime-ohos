# 测试方交接：kit #32、WebView 六项接线 + B1 razor 资产 + SEC 修复（2026-09-28）

> 日期口径：文件名按撰写日；kit #32 发布日 = **2026-09-28**（RELEASE-VALUES `date`，FINAL）。
> kit #32 发布实测：tar **207,114,608 B / `8f690949…`**、树 **`645879bc…`**、sidecar **`344760e7…`**、
> `SHA256SUMS` **16 项 / 1,410 B / `2d3f2fad…`**（下载解包复核 = tree OK + KIT OK，0 FAIL / 0 WARN；
> 重签/重打包后哈希必变，以 release「## Integrity（kit #32）」与随包校验为准）。

> 结论先行：kit #32 = **kit #31 + WebView 六项接线（壳 + 切片） + B1 razor 独立资产 + SEC-SCAN-3 收口修复 +
> Blazor 组件 hap 无 INTERNET（重签后保持）** ——
> ① **MAUI WebView/Hybrid/Blazor 三 handler 接线**：`GoBack/GoForward/Reload` + `CanGoBack/CanGoForward`
> （壳 `history|b|f` 状态回传）、Cookie 最小读写（`WebCookieManager`）+ `domStorageAccess(true)`、
> `frame` 非整窗定位（三 handler 统一 `SendPlatformFrame`）、onPageEnd/onErrorReceive →
> `Navigated(Success/Failure)`、JS 桥复用共享 `SendHostRequestAsync`、失败 `hide` 清屏。
> 真机 9 项不确定项 → **《WebView / Blazor Hybrid 真机验证卡》（§3）**。
> ② **B1 razor 独立资产**：`hello-maui-razor`（MAUI Blazor Hybrid，进程内 CoreCLR、**native 模型非 WASM**；
> bundle **`com.example.hellomauirazor`**）本机复跑 `publish -c Release -f net11.0-openharmony26.0
> -r openharmony-arm64` → `sign-profile/sign-app/verify-app success`（本机签名复跑 75,889,768 B 仅证明管线；发布 = 独立资产 `maui-razor-haps.tar.gz` 内未签 hap **73,656,242 B / `b4d305f0…`**，新壳 abc
> **289,992 B / `e005f2366d72…`**，`dotnet.zip` 259 条含 `wwwroot/index.html`、`_framework/blazor.webview.js`、
> `blazor.modules.json`、`js/app.js`；无 wasm/dot.js）；资产 **38,968,818 B / `5e549506…`**（sidecar `3f4cc4d6…`、README 2,617 B / `ff56faff…`），`requestPermissions=0`。
> ③ **SEC-SCAN-3 收口**：深链控制字符注入 + allow-list 竞态、HUKS 空键崩溃/并发丢更新/坏 base64、
> `.key`/`secure.dat` 0600 加固、`BLZ_ERROR` 终端清洗、ArkWeb rawfile 路径段校验 + 安全头（`nosniff`/`Vary`/
> 最小 CSP）+ 启动 nonce、**探针标记 pid 绑定 + session nonce**、`app://../x` 段拒绝。
> ④ **Blazor hap 无 INTERNET**：源侧移除（ohos-workload `2dcd846`）；kit #32 包内 Blazor hap 不声明
> `requestPermissions`，**重签不修改 module.json → 重签后保持无 INTERNET**；`verify-kit.sh` 2c 记录该权限集
> （与源侧期望不一致 → **WARN 不 FAIL**，kit #31 旧包仍可校验）。
> ⑤ **门禁与指纹**：ui/shell abc **289,992 B / `e005f2366d724309…`**（headless **20,916 B / `54a1a201…`** 不变；
> 壳重建 = ArkWeb 接线）、交互套件 **398/floor 378**（+5 w1–w5、SEC3 +2 回归 pin）、导出契约 **143/143**、
> 像素套件 `PIXEL ASSERTIONS PASSED`；`verify-kit.sh` selftest **92 → 102**（脚本 **66,661 B / `f72a4a3c…`**）。
> ⑥ **发布实测（2026-09-28，RELEASE-VALUES FINAL）**：tar **207,114,608 B / `8f690949…`**、树 **`645879bc…`**、
> sidecar `344760e7…`、`SHA256SUMS` **16 项 / 1,410 B / `2d3f2fad…`**；bundle **30,566,929 B / `286a923e…`**
> （sdk-ohos 锚 **`b4e76a6239`**）；tester-run **v14 140,197 B / `a174fcd0…`**（asset 595131362）；razor 资产
> **38,968,818 B / `5e549506…`**（内未签 hap 73,656,242 / `b4d305f0…`）；6 hap 表见 §5；CI：ohos-workload **5/5**
> （interaction 36413679129 等），sdk-ohos `ohos-install-tests` 红（step 6，历史同红；本机安装器测 43/43+10/10+5/5）。
> 本轮判定点见 §2；承接 #31 的 Blazor 段（`2026-09-29-ohos-tester-handoff-kit31.md`）与 #30 的 MS-MODE/
> #29 R3/#28 R2/#27 KIT-EXT2/#26 P2-INTEROP 判定点**继续有效**，本文只覆盖 #32 增量与判读引用。

## 0. 一键执行（tester-run v14）

```sh
# 常规一轮（承 #30/#31：runtime_mode 键、execmem、a11y 可选）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 组件探针（先按《自签说明》重签 hello-blazorwasm-host-unsigned.hap）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（JIT / XWE / 解释器 / AOT；无需 Blazor 资产）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

> WebView 六项与 B1 razor 的逐项操作/期望/证据/判据 = §3 的 9 项设备卡；每项失败按「原文 + 截图」回传。

## 1. kit #32 相对 #31 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1 | **WebView 六项接线**（切片 `maui-ohos` + 壳 `ohos-workload`，重建 abc **289,992 B**） | MAUI 的 `WebView`/`HybridWebView`/`BlazorWebView` 现在支持返回/前进/刷新与 `CanGoBack/CanGoForward`、Cookie 读写、按控件 frame 定位（不再是整窗覆盖）、成功/失败导航事件（失败清屏）、JS 往返复用 | 9 项真机卡（§3） |
| 2 | **B1 razor 独立资产**（`hello-maui-razor*`，bundle `com.example.hellomauirazor`） | release 上多一个 MAUI Blazor Hybrid hap（进程内 CoreCLR、native 模型；`wwwroot` + Blazor 资产打包在 payload）；真机需按《自签说明》流程重签 | MAUI 窗口内 `BLZ_BOOT`/`BLZ_RENDERED` + `/counter` +1 + JS 往返（§3 #7–#9） |
| 3 | **SEC 修复（SEC-SCAN-3 收口）** | 深链/HUKS/0600/BLZ_ERROR 清洗；Blazor 宿主 rawfile 路径校验 + 安全头 + 启动 nonce；探针只接受**宿主 pid + session nonce** 的标记；`verify-kit.sh` 记录 Blazor 权限集（WARN） | 伪造 `BLZ_*` 不再通过（或记录降级）；`verify-kit.sh` 0 FAIL |
| 4 | **Blazor hap 无 INTERNET** | 第 6 个 hap 不再声明 `ohos.permission.INTERNET`（rawfile 直供本就不需要）；重签后保持无（签名不改 module.json） | `verify-kit.sh` 2c 打印 `requestPermissions`（#32 应为空）；#31 旧包显示 `[INTERNET]` + WARN 属预期 |
| 5 | **门禁与指纹**（承 #31） | abc **289,992**/`20916`、导出 **143/143**、交互 **398/floor 378**；MAPFIX harmony 件、MS-MODE/R3/R2 判定点不变 | 校验步骤与证据字段同 #31，仅 abc 期望值与 Blazor 段增强 |

> 尺寸预算：kit #31 为 207,023,588 B；#32 = MAUI 5 hap 重建 + Blazor hap 重建（去掉 INTERNET）+ 并列 razor 资产
> （+razor 资产 38,968,818 B），整包 = **207,114,608 B（+91,020 B vs #31）**。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **WebView 六项（9 项卡）** | 重签装默认 hap → 按 §3 的 9 项逐条操作 | 每项满足卡内「判据」（frame 几何/历史/CanGoBack/Cookie/HttpOnly/DOM 持久化/失败清屏） | 截图 + `tester-run` 证据包（`hilog`/`summary`） |
| **B1 razor：MAUI 窗口内两条标记** | 重签装 razor hap → MAUI 窗口出现页面 → `hilog -x` 后 `grep BLZ` | `BLZ_BOOT`（window load）与 `BLZ_RENDERED`（Blazor 首帧）均出现；无 `BLZ_ERROR` | hilog 原文 + 首屏截图 |
| **B1 razor：JS 往返** | 进 `/counter` 点一次 `Click me`（或触发一次 `JS.InvokeVoidAsync` 往返） | 计数 0 → 1；往返无异常 | 截图 + 日志 |
| **Blazor 组件：标记真实性** | `sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe` | 两条标记来自**宿主 pid**且带同一 `[blz:<nonce>]`；`summary` 记录 `blazor_marker_pid`/`blazor_session_nonce`（旧宿主无 nonce → 降级 + WARN，不判失败） | `blazor/` 证据 + `summary` 行 |
| **Blazor 组件：无 INTERNET** | `sh verify-kit.sh`（包内）与 `bm dump -n com.example.opendotnet` | 2c 打印权限集为空（重签后同）；`bm dump` 无 `ohos.permission.INTERNET` | `verify-kit.sh` 终端输出 + `bm dump` 摘要 |
| **回归：MAUI 主包与 #31/#30 判定点** | 默认 hap 重签安装后跑常规一轮 | abc 锚 **289992**/`20916`；`runtime-mode=jit source=manifest`；5 条冒烟、`verify-kit.sh` 全过 | 同 #31 交接 §5 |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 9 项中的自动项标注「未测（无 hdc）」；人工项（首屏/`/counter`/截图）照做 | 截图 + 说明 |

> 一页操作卡（Blazor 组件重签）：`2026-09-29-ohos-blazor-resign-one-pager.md`；
> WebView/B1 的设备卡：`2026-09-28-ohos-webview-blazor-device-card.md`。
> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；Blazor 与 B1 razor 互不依赖。

## 3. WebView / Blazor Hybrid 真机验证卡（9 项，摘要）

见 `2026-09-28-ohos-webview-blazor-device-card.md`（一页，每项：操作 → 期望 → 证据 → 判据）：

1. **frame 几何（DIP↔vp）**：WebView 只占控件 frame，与 MAUI 布局对齐（四边误差 ≤ 1 DIP）。
2. **history 事件顺序**：Back/Forward/Refresh 事件种类与操作一致，无重复导航。
3. **CanGoBack/CanGoForward**：与页面前进/后退栈一致。
4. **Cookie 跨页保持**：同源第二页请求携带 cookie，`GetCookieAsync` 读回一致。
5. **Cookie HttpOnly**：JS `document.cookie` 不可见、宿主读回可见。
6. **DOM storage 持久化**：`localStorage` 杀进程重启后读回一致（`domStorageAccess(true)`）。
7. **加载失败清屏**：`error` → 清屏占位 + `Navigated(Failure)`，旧内容不残留。
8. **B1 `BLZ_BOOT`/`BLZ_RENDERED`**：MAUI 窗口内两条标记出现在宿主进程日志。
9. **B1 JS 往返**：`/counter` 0 → 1 或一次 `JS.InvokeVoidAsync` 往返成功。

## 4. 自签与包布局要点（测试方视角）

- **Blazor 组件**：bundle **`com.example.opendotnet`**；**无 INTERNET**（重签保持）；标记带 per-launch nonce，
  自签/安装/判读流程同 #31（《自签说明》Blazor 条目；`-signCode 1` 必带）。
- **B1 razor 资产**：bundle **`com.example.hellomauirazor`**（与 MAUI 主包不同）；自签工程 bundleName 需
  同名；hap 内为 MAUI native 模型（不加载 WASM），判定只用 `BLZ_*` 与 `/counter`，不要套 ArkTS 宿主判据。
- **MAUI 5 hap**：包含 #32 新壳（abc 289,992）；`libs/arm64-v8a/` 仍为 payload-in-libs 布局（254 payload +
  `.dotnet-payload.json`，`dotnet.zip` 回退），`libIsolation` 与全部历史修复不变。
- **重建/重签后哈希必变**：本文数字 = kit #32 发布实测；以 release「## Integrity（kit #32）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准。

## 5. 校验与取证（与 #31 相同骨架，仅 abc 期望与 Blazor 段增强）

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（#32 起：abc 期望 **289992**/`20916`；
   Blazor 2c 记录权限集，与源侧期望不一致 → WARN；selftest **102** 检查）。
   用 #31 的值 `281052` 校验本包会 FAIL —— 那是脚本的预期行为。
2. `tester-run.sh` **v14**（**140,197 B / `a174fcd0…`**，asset 595131362）：常规轮同 #31；Blazor 轮 `--blazor-probe` 现在断言
   **pid + nonce 绑定**的标记（失败/降级信息进 `summary` 与 `blazor/`）；模式矩阵与 a11y 同 #30/#31。
3. 整包数字（tar **207,114,608 B / `8f690949…`**、树 **`645879bc…`**、sidecar **`344760e7…`**、`SHA256SUMS` **16 项 / 1,410 B / `2d3f2fad…`**、bundle **30,566,929 B / `286a923e…`**（锚 **`b4e76a6239`**）、tester-run **v14 140,197 B / `a174fcd0…`**、razor 资产 **38,968,818 B / `5e549506…`**）**以 release「## Integrity（kit #32）」与随包校验为准**

> 6 hap（#32）：`hello-maui-app.hap` **75,866,199 / `ffa545fd…`**（0 权限）；`hello-maui-app-permissions.hap` **75,870,309 / `973f692f…`**（5 权限）；`hello-maui-app-api20.hap` **75,866,219 / `b614f9a2…`**；`hello-maui-app-api20-permissions.hap` **75,870,334 / `71bb121d…`**（5 权限）；`hello-maui-app-unsigned.hap` **73,684,666 / `8658f45a…`**；`hello-blazorwasm-host-unsigned.hap` **26,803,570 / `5011cf73…`**（219 条目、0 权限）。
   （#31 实测值仅作对照，见文首）。
4. 有 harmony flavor / HMS 的测试者请附：壳构建出处（`harmony-haps.tar.gz`，MAPFIX 重切件
   abc 291,628 B/`a637a513…`）、Map/LiveView 点亮证据、TTS/HUKS/深链证据同 #29。

## 6. 风险 / 未验证（诚实清单）

- **WebView 六项与 B1 razor 均未在真机验证**（我方工作区无 UI/无 `hdc`）：几何/事件/Cookie/存储/失败清屏与
  B1 两标记 + JS 往返正是 §3 设备卡要闭环的 9 项。
- B1 razor 发布形态 = 独立资产 `maui-razor-haps.tar.gz`（38,968,818 B / `5e549506…`，内未签 hap 73,656,242 / `b4d305f0…`，0 权限）；本机签名复跑值（75,889,768 B）只证明管线。
- 旧宿主（无 nonce）仍可过 `--blazor-probe`，但记录为**降级绑定**（`blazor_session_nonce=absent` + WARN）。
- `--slim` 站点不带 `.br/.gz`（功能等价）；Blazor #32 hap 无 INTERNET、重签后保持，但**若你从自己的工程
  重建**则权限以你的工程为准。
