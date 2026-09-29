# 真机验证结论入档（kit #30/#31，REC-VERIFY，2026-09-28）

> **2026-09-29 更新（kit #33）**：本页三条行动项已全部落地并随 kit #33 出包——① `pack-host.sh` 静态资产路由（`_framework/dotnet.js` 等稳定名物化，FIX-BLZ-JS；另修复 kit #32 的读路径命名空间回归 FIX-BLZ-PATH）；② slice `ChildEnumerator` 补 TabbedPage case（`14bdb85f`，FIX-TABBED）+ 无障碍 `PushChildren` 同款修复（`dc9b19a6`，A11Y-TABBED）；③ `aot-haps-v2.tar.gz`（含 TabbedPage 修复，17,323,220 B / `265e014f…`）已发布。真机复测（Blazor A/B、TabbedPage 主体）见 `docs/plans/2026-09-29-ohos-blazor-regression-retest-card.md` 与 `docs/plans/2026-09-29-ohos-tester-handoff-kit33.md`。

> **来源**：测试方《.NET MAUI 鸿蒙真机验证总结（kit #30 → kit #31）》（`ohos-kit30-kit31-verification-summary.md`，420 行，2026-09-28）。
> **口径**：只入档可复核的结论与去向；细粒度日志/参数引用来源总结。真机结论不回改离设备基线，只作状态注记。
> **交叉引用**：覆盖矩阵 §6 真机状态、`2026-09-24-ohos-kit-gap-analysis.md` §5 结论。

## 1. 设备 / 版本 / 签名

- 设备：HUAWEI MateBook Pro（HAD-W32）；HarmonyOS 7.0.0.105（SP7ENTC293E102R2P1log）；`const.ohos.apiversion = 26`；arm64-v8a；UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`。
- 代码与包：`D:\project\ohos-workload`（springmin/ohos-workload，master，`2dcd846`）；kit #30 tar 196,992,264 B / `a781c25b…`；kit #31 tar 207,023,588 B / `f4325d2f…`（与 release asset 逐字节一致）；`aot-haps.tar.gz` 17,093,146 B。
- 签名：W3 在线签名（PKI `pki-hapsign.cbg.huawei.com` remoteSign）；profile = `com.example.hellomauiapp` → `1790043397348debug.p7b`、`com.example.opendotnet` → `1790582565319debug.p7b`（本验证新申请）。

## 2. 三条结论

1. **Blazor WASM 组件 ✅（kit #31 唯一实质新增）**：kit31 的 MAUI hap 与 kit30 字节级一致（host so/abc MD5 同值）；修复打包缺 `_framework/dotnet.js` 后，`BLZ_BOOT` + `BLZ_RENDERED` 全达成（window load → .NET 运行时 → JS interop → 首帧渲染）。
2. **MAUI 主体黑屏根因 = slice 固有缺陷（TabbedPage 枚举缺失）**：BITMAP-DIAG 证实只画 tab 栏；根因 = `ChildEnumerator` 缺 `TabbedPage.CurrentPage`（作者处理了 NavigationPage，漏了 TabbedPage）；springmin 原版 so 同样复现。补丁已写并经 IL 级确认，但本地重编 so 无法运行、效果未验。
3. **AOT 本地重编阻塞 = 工具链差异**：本地重编 so 已打通加载（NetSecurity stub + 模块符号 + `sections.ld` 三修复），MAUI 初始化完成；随后 NativeAOT 运行时初始化崩溃（`GetModuleSection` NULL @0x8）。springmin 预编译 so 能跑、本地重编崩溃，差异在 runtime-ohos 专用 ilc（本地 `--targetos:linux` hack 无法完全复现）。

## 3. 证据索引

| 证据 | 内容 |
|---|---|
| BITMAP-DIAG（`openharmony_host.c` 分块像素统计） | 2090x1106：仅底部 tab 栏 + 顶部少量内容，主体 33 个 cell 全黑 |
| cppcrash 栈（`cppcrash-61076-1790585278693.json`） | SIGSEGV@0x8：`TypeManager::GetModuleSection` ← `StartupCodeHelpers.CreateTypeManagers` ← `InitializeRuntime` |
| IL 级确认（`Microsoft.Maui.Controls.dll`） | `ChildEnumerator.MoveNext` RVA 259384，`isinst TabbedPage: 1`（修复前 0） |
| 设备 hilog（kit #31 修复后） | `marker: BLZ_BOOT` → `marker: BLZ_RENDERED`，无 `BLZ_ERROR` |
| 渲染链路 stderr | `[maui] window created` → `canvas presented via GPU` ×100+ |

## 4. 行动项

| # | 行动 | 负责代理 | 状态（2026-09-29） |
|---|---|---|---|
| ① | `pack-host.sh` 静态资产路由（`_framework/dotnet{,.native,.runtime}.js` → hash 版；kit #31/#32 均缺） | `fix-blzjs`（ohos-workload 打包链） | 进行中：工作区已见路由实现（按 `*.staticwebassets.endpoints.json` 物化），待提交/重出包 |
| ② | slice `ChildEnumerator` 补 TabbedPage case（`OpenHarmonyWindowRenderer.cs`；平台子节点顺延） | `fix-tab`（maui-ohos 切片） | 补丁就绪（设备机已写 + IL 确认）；本仓 `ChildEnumerator` 尚无此 case，待入库 |
| ③ | AOT v2 重编（含 ②，验证主体渲染） | `aot-v2`（runtime-ohos/AOT 工具链） | 等待 ② 的 `FIX-SHA`（watcher 已运行）；工具链差异为已知风险 |

## 5. 已证链路（springmin 预编译 AOT）

ArkTS 壳 bootstrap → host so 加载（196 UND dlsym 降级 + 自定义 `OH_LOG_Print`）→ NativeAOT 启动（managed app started）→ MAUI 初始化（`window created, content=FlyoutPage`）→ XComponent surface（2090x1106）→ GPU 呈现（设备缺 `libnative_window.so`，`canvas presented via GPU` ×100+）。

## 6. 不进包 / 不予固化

- tester 侧把 hash 版 `dotnet.<hash>.js` 复制为 `_framework/dotnet.js` 属**应急补丁，不进包**；正式修复 = ①（`pack-host.sh` 静态资产路由）。
- ① 落地前 kit #31/#32 已发行的 Blazor hap 都缺该映射；下一轮重出包必须包含，或按发行说明复述手工补丁步骤（仅测试用途）。
- kit #32 的 B1 razor / BlazorWebView 资产（`blazor.webview.js`）是另一条路径，不属本页结论；其真机 9 项卡见 `2026-09-28-ohos-webview-blazor-device-card.md`。
