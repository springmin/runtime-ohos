# 测试方交接：kit #33、Blazor 回归修复（路径命名空间 + dotnet.js + 双 hap A/B）+ MAUI TabbedPage/W5 + AOT v2（2026-09-29）

> 日期口径：文件名按撰写日；**kit #33 已发布**（RELEASE-VALUES FINAL，2026-09-29 17:37）：
> kit #33 发布实测：tar **218,138,546 B / `38e4d57a…`**、树 **`064cb001…`**、sidecar **`8297363e…`**、
> `SHA256SUMS` **17 项 / 1,517 B / `37031b9a…`**（dtk id 597711909 / sidecar 597714378；7 hap 表见 §5；重签/重打包后哈希必变）。
> 对照：#32 实测 tar **207,114,608 B / `8f690949…`**、树 **`645879bc…`**、sidecar **`344760e7…`**（仅作上一版对照）。
> 构建基线以 release 与包内《最终状态.md》为准（rc.2 线：SDK **`11.0.100-rc.2.26451.112`** / workload
> **`1.0.0-preview.28`**；rc.1 线 = preview.24 仍可回滚；rc.2 线细节见 `docs/plans/2026-09-28-rc2-conflict-sharding-plan.md` §9）。

> **发布实测（RELEASE-VALUES FINAL 2026-09-29 17:37）**：MAUI 5 hap 重建 = 新壳 abc **294,976 B / `6cf7dda2…`**；**7 hap** = 5 MAUI + Blazor 默认 **27,216,958 / `69de2eea…`** 与 `-nocsp` **27,216,659 / `c1ef7e06…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）；bundle/`workload-1.0.0-preview.28` = **77,689,347 B / `155960f4…`**（release 398936638，三处同哈希；sdk-ohos 锚 `e7727959cc`（+ test-fix `0e2ee7c9a5`）已 push）；整包 tar **218,138,546 / `38e4d57a…`**、树 **`064cb001…`**、sidecar **`8297363e…`**、`SHA256SUMS` **17 项 / 1,517 B / `37031b9a…`**（dtk id 597711909 / sidecar 597714378）；`verify-kit.sh` **69,355 B / `08fe852c…`**（0 FAIL / 0 WARN，期望 abc 294,976/20,916）；`ohos-workload` tip **`aad545b`**（preview.28 pack + 双 hap 构建支持），slice tip **`dc9b19a6`**；CI **5/5**（interaction 36547872933 / pixel 36547872965 / host-export 36547872909 / ridgraph 36547872911 / markdownlint 36547872864）；AOT v2 不变。

> 结论先行：kit #33 = **kit #32 + ①Blazor 回归修复（FIX-BLZ-PATH 路径命名空间 + FIX-BLZ-JS `_framework/dotnet.js`
> 物化 + 双 hap 默认 CSP/`-nocsp` A/B） + ②MAUI TabbedPage 渲染修复（FIX-TABBED）与无障碍修复（A11Y-TABBED）
> + ③W5 四件（T13/N3/T21/T22，交互套件 **470/floor 450**）+ ④AOT v2 独立资产（不在 kit 内，见 §1.7）**——
> ① 是 **kit #32 的真机回归**：Blazor 宿主读 rawfile 的路径命名空间被 SEC-FIX 重构改坏，全部资源 404、
> 首屏不渲染；② 是测试方 kit #30/#31 结论 2 的根因修复（主体黑屏 = 切片漏枚举 `TabbedPage.CurrentPage`）。
> 本轮判定点见 §2；承接 #32 的 WebView 六项/B1 razor/SEC 与 #31/#30/#29/#28/#27/#26/#25 判定点**继续有效**，
> 本文只覆盖 #33 增量与判读引用（一页卡：`2026-09-29-ohos-blazor-regression-retest-card.md`）。

## 0. 一键执行（tester-run v14；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（同 #32：runtime_mode 键、execmem、a11y 可选）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 回归 A/B（先分别重签两个变体；见 §2 / 一页卡）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段请用 aot-haps-v2；见 §1.7）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v2.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

## 1. kit #33 相对 #32 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **FIX-BLZ-PATH（Blazor 回归修复）** | kit #32 的 Blazor hap 读取**全部 404**（首屏不渲染）——SEC-FIX 把 `resolveRawfilePath` 的返回值改成边界拼写 `resources/rawfile/blazor/<x>`，而 `getRawFileContentSync` 只接受 rawfile 相对名 `blazor/<x>`；修复 = 安全校验仍以 `resources/rawfile/blazor/` 为边界，返回值恢复 `blazor/<x>`（br/gz 同理）。离线单元测试 43 checks 全绿 | 默认 hap 能出首屏（A/B，见 §2） |
| 1.2 | **FIX-BLZ-JS（dotnet.js 物化）** | kit #31/#32 的 Blazor hap 缺稳定名 `_framework/dotnet.js`（被指纹化路由到 `dotnet.<hash>.js`），`blazor.webassembly.js` 动态 import 失败 → `BLZ_ERROR Failed to fetch dynamically imported module`；修复 = 嵌入阶段按 `*.staticwebassets.endpoints.json` 复制 `dotnet.js`/`dotnet.native.js`/`dotnet.runtime.js` 三个稳定名（与指纹版逐字节一致）；`verify-kit.sh` 2c 新增断言（旧包 #31/#32 因此 FAIL，属预期） | `verify-kit.sh` 0 FAIL；`BLZ_BOOT`+`BLZ_RENDERED` |
| 1.3 | **双 hap CSP A/B（诊断对照）** | Blazor 组件提供两个对照变体：默认（SEC-SCAN-3 最小 CSP 头）与 `-nocsp`（`pack-host.sh --no-csp` 去掉 CSP 头，其余同源同站点）；两者各装一次即可判定 CSP 是否次因（实际包含形态以包内 `SHA256SUMS`/release 为准） | A/B 判读表（§2 / 一页卡） |
| 1.4 | **FIX-TABBED（MAUI 主体渲染）** | 切片 `ChildEnumerator` 补 `TabbedPage.CurrentPage`（此前只枚举 NavigationPage 可见页）——FlyoutPage → TabbedPage 链路上的主体页从未进入绘制遍历（kit #30/#31 真机「只画 tab 栏、主体黑屏」的根因）；修复后当前页入画 | TabbedPage 双页签内容出画 + 切页（§2） |
| 1.5 | **A11Y-TABBED（无障碍影子树）** | 同款枚举缺口修复 `OpenHarmonyAccessibility.PushChildren`：无障碍树发布 `TabbedPage.CurrentPage`（选中页节点在、未选中页不在；切页后跟随） | `--a11y-probe` 树含当前页（§2） |
| 1.6 | **W5 四件**（切片 + 套件） | T13 CollectionView `GroupFooter` 视图模板（非 Label）、N3 Picker/Date/TimePicker `IsOpen` 双向映射（开/关 + Opened/Closed）、T21 字体缩放跟随系统字号、T22 MainThread 桥接断言；交互套件 **470/floor 450**（#32 = 398/378），像素套件 `PIXEL ASSERTIONS PASSED` | 四项按 §2 逐条 + 套件自报行 |
| 1.7 | **AOT v2 独立资产**（不在 kit 内） | 新并列资产 `aot-haps-v2.tar.gz`（**17,323,220 B / `265e014f…`**，asset 596991567；sidecar `720da730…`；README `3e2cb2db…`；内含含 TabbedPage 修复的已签/未签 AOT hap，未签 **20,100,211 B / `b869f67b…`**、已签 20,360,777 / `5db9c672…`）；旧 `aot-haps.tar.gz`（17,093,146 / `91e1b9d3…`）保留对照。**MAUI 主包 JIT 若仍 `SEGV_ACCERR` 崩溃，用本资产重签安装判「主体渲染」** | 重签安装 → 启动 → `aot=1` → 双页签出画（§2） |
| 1.8 | **基线/脚本** | 基线 = rc.2 线（SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28`；bundle **77,689,347 B / `155960f4…`**，锚 `e7727959cc`）；MAUI 5 hap 重建 = 新壳 abc **294,976 B / `6cf7dda2…`**；整包 tar **218,138,546 / `38e4d57a…`**、树 `064cb001…`、sidecar `8297363e…`；`verify-kit.sh` 承 2c dotnet.js 断言（selftest **108** 检查）；`tester-run.sh` 以包内 `SCRIPT_VERSION` 为准（#32 = v14） | `verify-kit.sh` 0 FAIL；版本自述 |

> 尺寸预算：以 release 资产表为准（#32 = 207,114,608 B；#33 的 delta = Blazor hap 重建/双变体 + MAUI hap 重建）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **Blazor A/B：默认（CSP）** | 重签默认 `hello-blazorwasm-host-unsigned.hap` → 安装 → `sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe` | `BLZ_BOOT` + `BLZ_RENDERED`（宿主 pid + `[blz:<nonce>]`），无 `BLZ_ERROR`；人工首屏 “Hello from Blazor WebAssembly” + `/counter` +1 | hilog 原文 + 首屏/点击截图 |
| **Blazor A/B：`-nocsp` 对照** | 卸载默认件，重签安装 `…-nocsp.hap`（bundle 同名 `com.example.opendotnet`）→ 同一命令 | 同上；**判读**：默认能渲染 → CSP 非瓶颈、路径修复成立；默认不能而 nocsp 能 → CSP 至少是次因（记录）；两者都不能 → 路径修复未生效，按失败回传 | 同上 + 两个 hap 的 sha256 |
| **MAUI 主体（FIX-TABBED）** | 装 kit #33 默认 MAUI hap（重签）→ 进入 FlyoutPage → TabbedPage 页面 | 双页签内容出画（不再是只画 tab 栏的「主体黑屏」）；切页内容切换、无残影 | 截图（两个页签）+ hilog 崩溃行（若有） |
| **AOT v2 回退（可选/主体）** | 若 JIT 路线启动即崩（`SEGV_ACCERR`）或主体仍黑：重签 `aot-haps-v2.tar.gz` 内未签 hap → 安装（会顶替 kit 主包）→ 启动 | 主体渲染确认（双页签 + 切页）；`start_app: aot=1` 行 | 截图 + hilog（`aot=` 行） |
| **无障碍（A11Y-TABBED）** | 加 `--a11y-probe` 跑任意一轮 | `a11y/selfcheck.txt` 节点含当前页标签；切页后跟随 `CurrentPage` | `a11y/` 两文件 + `summary a11y_*` |
| **W5 四件：T13** | CollectionView 带 GroupFooter 模板的页面 | 页脚按模板视图渲染（非 Label 降级） | 截图 |
| **W5 四件：N3** | Picker/DatePicker/TimePicker 打开/关闭 | `IsOpen` 双向映射；`Opened`/`Closed` 事件成对 | 截图 + 日志 |
| **W5 四件：T21** | 系统设置改字号 → 应用内文本 | 字号跟随系统缩放（控件与绘制同步） | 前后截图对比 |
| **W5 四件：T22** | `tester-run` 套件自报行 | `[suite] checks=470 total=470 floor=450 assert=True` | 终端输出 |
| **回归：WebView/B1/Blazor 无 INTERNET/#30-#32 判定点** | 按 #32 交接 §2–§3 / 一页卡照跑 | 同 #32 期望；Blazor hap 仍无 `ohos.permission.INTERNET`（重签保持） | 同 #32 |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项（首屏/切页/`/counter`/截图）照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. Blazor 回归判读表（A/B）

| 默认（CSP）渲染 | `-nocsp` 渲染 | 结论 | 下一步 |
|---|---|---|---|
| ✅ | （不必测） | 路径 + dotnet.js 修复成立，CSP 非瓶颈（默认即通过） | A/B 通过；保留 nocsp 变体备查 |
| ❌ | ✅ | CSP 至少是次因（路径修复已生效但 CSP 阻断） | 回传两者 hilog（`BLZ_ERROR` 原文）+ 两 hap sha256 |
| ❌ | ❌ | 路径修复在本机未生效（或另有阻塞） | 按失败回传：`blazor-hilog.txt` + 截图 + `bm dump -n com.example.opendotnet`（若可用） |

> 失败回传统一：`hilog -x | grep BlazorWebHost`（含 `BLZ_ERROR` 行）+ 截图；重签后哈希必变，回传你产出件的 sha256。

## 4. 自签与包布局要点（测试方视角；承 #32）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（两个变体同名，装前卸载旧件）；仍无 INTERNET（重签保持）；
  标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记（旧宿主降级 + WARN）。
- **MAUI 5 hap**：payload-in-libs 布局不变（`libs/arm64-v8a/` 254 payload + `.dotnet-payload.json`，`dotnet.zip` 回退）；
  `libIsolation` 与自 #17 起全部安全/性能/启动修复不变。
- **AOT v2**：独立资产，不在 kit tar 内；安装会顶替 kit 主包，回 JIT 需重装 kit hap；数字以 release asset 与 `aot-v2-README.md` 为准。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #33）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准。

## 5. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（2c 新增 `_framework/dotnet.js` 断言：存在且与指纹版逐字节一致；
   对 #31/#32 旧 hap 会 FAIL 属预期；selftest 108 检查）。
2. `tester-run.sh`（版本以包内自述为准）：常规轮 / `--blazor-probe` / `--mode-matrix`（AOT 段用 `aot-haps-v2.tar.gz`）/
   `--a11y-probe` 四件同 #32。
3. **7 hap 表（kit #33 发布实测；`SHA256SUMS` 17 项 / 1,517 B / `37031b9a…`）**：`hello-maui-app.hap` **76,072,282 / `04b45359…`**；`hello-maui-app-unsigned.hap` **73,880,100 / `218e8ca4…`**；`hello-maui-app-permissions.hap` **76,076,322 / `622c970a…`**；`hello-maui-app-api20.hap` **76,072,243 / `e4cb95f0…`**；`hello-maui-app-api20-permissions.hap` **76,076,383 / `cb50dd04…`**；Blazor 默认 **27,216,958 / `69de2eea…`**；Blazor `-nocsp`（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）**27,216,659 / `c1ef7e06…`**。整包 tar **218,138,546 / `38e4d57a…`**、树 `064cb001…`、sidecar `8297363e…`、bundle **77,689,347 / `155960f4…`**；**以 release「## Integrity（kit #33）」与随包校验为准**（重签/重打包后必变）；
   有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#32）。
4. 离线修复证据（供复核）：FIX-BLZ-PATH 的 `rawfile-path.test.mjs` **43 checks** 全绿 + 双 hap 重建（213 站点文件、abc 路径字符串断言）；FIX-BLZ-JS 的 `verify-kit.sh` selftest **108** + `dotnet.js` 逐字节一致；FIX-TABBED/A11Y-TABBED 的交互/像素负控与 **CI 5/5**；AOT v2 的 `verify-aot-v2.sh` ALL PASSED + 发布校验（by-id/gh-proxy/零改动）。

## 6. 风险 / 未验证（诚实清单）

- **双 hap A/B 与 TabbedPage 主体渲染均未在真机验证**（我方工作区无 UI/无 `hdc`）——正是本轮要闭环的判定点。
- Blazor 修复的拼写结论来自离线单元测试与打包断言；真机若无 hdc/不能重签，只能登记「未测」。
- AOT v2 的 `dotnet.js` 归 kit #33（本资产不含该变更）；AOT hap 只有 3 个 `.so`，勿用 JIT 期望值核对。
- W5 四件按套件自报与新入口判决；T22 为套件级断言（无独立 UI 入口）。
- **门禁（FINAL）**：interaction **470/floor 450** PASS、host 143/143、像素 CI PASS、`verify-kit.sh` 0 FAIL/0 WARN（expect 294,976/20,916）、tester-run full **683/0**、preflight（sh -n 39 + markdownlint 0 + 全 selftest）全绿；CI **5/5** @ `aad545b`（本机 pixel 重跑两次被 MSBuild 锁卡住，以 CI `36547872965` 为准）。
- 本次构建 = **rc.2 线**（SDK `.112` / workload `preview.28`，SDK/workload 安装冒烟已过）；应用侧构建请同步该线（`docs/plans/2026-09-28-rc2-conflict-sharding-plan.md` §9；rc.1 回滚路径保留）。
