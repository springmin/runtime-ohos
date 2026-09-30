# 测试方交接：kit #35、W9/W10 并入主线（B2 真机 BLZ / T20 媒体传输层 / T14+T21+T8 余项 / AOT 入口修复）（2026-09-30）

> 日期口径：文件名按撰写日；**kit #35 发布实测（release「## Integrity（kit #35）」；发布在途，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **375,629,423 B / `419d42e2…`**、树 **`d3b1b317…`**、sidecar **`d7e79d39…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `2dd447a7…`**；
> **7 hap** 表见 §6.3（#34 = tar 375,181,367 B / `55834aeb…` 对照）。重签/重打包后哈希必变；CI run id 见 §1.6。
> 构建基线（rc.2 线，同 #34）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包注意（上游缺陷）**：rc.2 NativeAOT OpenHarmony pack 的 OpenSSL shim 回归（EVP/SSL/X509 定义
> **0 个 vs rc.1 的 5 个**；rc.2 链接的 AOT 镜像遗留 ~401 未决引用，设备 `dlopen` 拒绝）→ 设备 AOT 构建
> **本地钉 rc.1 `11.0.0-rc.1.26451.109` pack**（暂不落仓；最小复现见 §7 与
> `docs/plans/2026-09-30-ohos-wave10-consolidation.md` §3）。

> 结论先行：kit #35 = **kit #34 + W9/W10 并入主线**：①**W9A B2**（MAUI WebView 承载 Blazor WASM）实装并
> **真机打通**（`BLZ_BOOT`/`BLZ_RENDERED`，pid 6157——#34 时的 AOT 托管入口缺口已由 W10 修复）；
> ②**W9B** T14 富 flyout 收尾 + T21 字体缩放；③**W9C** T8 不等高 TableView；④**W9D T20 媒体传输层**
> （本机镜像无 `@kit.MediaKit` media 命名空间属**预期**，sink `IsSupported=false`/`-1` 降级不抛；真播放需
> Kit 完整镜像/HMS 设备）+ T19 深链判定（want 冷/热投递成立；热 **`delivered=1`**，冷 `delivered=0` 为设计内）；
> ⑤**W10 AOT 入口修复**（宿主自身 libs 解析 `lib<stem>.so` + `dotnet-status.txt` 可观测、壳 AOT payload 探针/
> `fs` 别名/静态指纹映射（双向）；rc.2 AOT 包 shim 缺陷 → 本地钉 rc.1）。**新壳 abc 339,164（`74054e2d…`）/
> headless 23,516（`6bce4063…`）、hap 内宿主 293,792（`983e8f74…`）、导出 149/149、套件 540/floor 520**。判定点见 §2；承接 #34 的 rc.2/W6/W7/W8 与 #33 W5/Blazor A/B 的判定点
> **继续有效**，本文只覆盖 #35 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（同 #34：runtime_mode 键、execmem、a11y 可选）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 探针（#35：B2 走 MAUI WebView 内嵌 WASM；已有资产的路径以包内清单为准）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段请用本轮 AOT 资产；资产名/数字以 release 为准）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；#35 是否加发以 release 为准）

`device-test-kit` release 自 #34 起有并列预签资产 **`preSigned-haps.tar.gz`**（#34 = asset 600101072，
375,834,798 B / `b492b284…`）：7 hap 全部按 **tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`**
预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装、无需重签**（同 bundle 换件仍先卸载）；
非 tester UDID 设备报 `9568344` → 回传 UDID 重出或按包内 README 自签。**#35 若加发新预签件，以 release 与
包内 `preSigned-README.md` 为准**；预签包是并列附加件，完整一轮仍用 `device-test-kit.tar.gz`。

## 1. kit #35 相对 #34 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **W9A B2：MAUI WebView 承载 Blazor WASM（真机打通）** | 切片新增 `OpenHarmonyWebViewHandler.RegisterWasmSite(contentRoot="wasmsite")`（新 origin `https://blazorwasm.local/`，复用内容根安全守卫）+ 宿主 AOT 启动桥上下文刷新；壳 `registerBlazorAssets` 的 `mode==="wasm"`（同根目录服务、不注入 Hybrid bootstrap、不自动 load，WebView Source 驱动唯一次加载）+ `BLZ_*` 控制台标记转发 hilog `BlazorWebHost`；staging `_OpenHarmonyStageWasmSite`（`<PublishDir>/wasmsite`，fail-fast `index.html` + safe root）；AOT 入口修复后，真机 **`BLZ_BOOT`/`BLZ_RENDERED` 双标记齐**（pid 6157，`web cmd blazor origin=https://blazorwasm.local/ root=wasmsite mode=wasm`） | MAUI WebView 演示页加载 → 双标记（宿主 pid + nonce）→ 首屏渲染 + 交互（如 `/counter`）；失败落 hilog/截图 |
| 1.2 | **W9B：T14 富 flyout 收尾 + T21 字体缩放** | T14 补齐：flyout 内容模板/`Shell.ItemTemplate` 行（`as-multiple-items`、项行选择 `selected='Beta'` 且关抽屉）、模板内按钮点击不被选择/关闭抢走、菜单项模板回落；T21：字体缩放 `FontScale` API（默认 1、clamp `[0.5,3]`、非法/负值干净处理）+ Label/FormattedString 尺寸随缩放（`w=77→154→77`）、Entry 光标随缩放 | 抽屉富行（头/项/尾 + 按钮）；系统字号变化后 Label/Formatted 尺寸与光标跟随、越界值被钳制 |
| 1.3 | **W9C：T8 不等高 TableView** | `OpenHarmonyTableViewHandler` 支持**行高不等**的 TableView：行 pin 90/高 120 混排、堆叠链一致（`lastBottom=content`）、滚动窗口（`window=9/25`）、`UnevenRows=false` 回落均一行高；单元格 switch/image/明细、分区头、更新/滚动 | 不等高行渲染不重叠、滚动/更新正确；切回等高即恢复 |
| 1.4 | **W9D：T20 媒体传输层 + T19 深链判定** | 切片 `OpenHarmonyMediaPlayer`（ops 0 load/1 play/2 pause/3 stop/4 seek/5 release/6 status；`state\|time\|duration\|error` 事件；请求串行化）；壳 `registerMediaSink`（懒加载 `@kit.MediaKit`、单 AVPlayer、fd 生命周期、状态镜像 + hilog）；宿主导出 `ohos_host_media_*` + NAPI。**本机镜像无 MediaKit media 命名空间属预期**：`canIUse` 为真但运行时无 `createAVPlayer` → sink `-1`（`IsSupported=false`，调用降级不抛）；真播放需 Kit 完整镜像/HMS 设备。T19：`-U`/`--ps` 冷/热投递到 ability 成立（热 `delivered=1`；冷为启动前入队、`delivered=0` 设计内） | 无 Kit 设备：`IsSupported=false` + 各调用 `Unavailable/Failed` **不抛**；有 Kit 设备：load/play/pause/stop/seek/release/status + 事件；深链冷/热各一次看 `delivered` 行 |
| 1.5 | **W10：AOT 入口修复（AOTENTRY）** | ①宿主在**自身 libs** 解析 AOT 启动镜像 `lib<stem>.so`（签名、namespace 允许）并 dlopen；②宿主把 AOT 决策/入口调用/返回镜像进 `<filesDir>/dotnet-status.txt`（本镜像唯一可读通道）；③壳 `findLibsPayloadDir` 接受 AOT 形态（`markerAotEntry`），避免 zip 回退；④壳 `fs` 别名修复（原 `fileIo` 未定义 → 所有 served 资源 404）；⑤静态资源**指纹映射**（双向；.NET 指纹为 10 位字母数字、非 hex：`dotnet.js` → `dotnet.<fp>.js`）；⑥AOT demo 配方加 `InvariantGlobalization`（无 ICU 镜像不再 FailFast）。设备结果：wasm `BLZ_BOOT`+`BLZ_RENDERED`；MAUI 热激活 `delivered=1`；`[media-probe] load=Unavailable(-1)`（E9 镜像无 Media Kit） | 启动后 `dotnet-status.txt` 出现托管入口行（不再只宿主 probe 行）；应用可写 breadcrumb/状态文件；AOT hap 主体出画（承 #34 §2） |
| 1.6 | **门禁/指纹** | 交互套件 **540/floor 520**（declared==printed；perf/a11y 5 线 `within=True`）、像素 `PIXEL ASSERTIONS PASSED`、宿主导出契约 **149/149**（`--cross-check`；新增 T20 媒体四导出；#34 = 145）；**新壳 abc = 339,164 B（`74054e2d…`）/ headless 23,516 B（`6bce4063…`）**、hap 内宿主 **293,792 B（`983e8f74…`）**；四包 `preview.22/23/24/28` 字节一致 + 同 provenance（`sources pages/Index.ets 292,241/`9027f61…``）；`verify-kit` 期望已重锚；切片 **0 error / 0 IL**；CI **5/5** @ `080a63a`（interaction `36725822753` / pixel `36725822670` / host-export `36725822303` / ridgraph `36725822702` / markdownlint `36725822841`） | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**（abc 期望以包内为准）；套件自报行 `[suite] checks=540 total=540 floor=520 assert=True` |

> 尺寸预算：以 release 资产表为准（#34 = 375,181,367 B；#35 的 delta = 新壳/宿主 + W9/W10 门禁重建 + 本轮产物）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **B2 真机 BLZ（主判点）** | 装 MAUI WebView/WASM 入口（包内演示 hap 或按 release/包内说明构建；AOT 路径）→ 打开嵌入式 Blazor 页 | `BLZ_BOOT` 与 `BLZ_RENDERED` **同 pid 双标记齐**、无 `BLZ_ERROR`；首屏渲染；`/counter` +1 类交互往返成立；壳 hilog `BlazorWebHost` 可见 `web cmd blazor … mode=wasm` | hilog（标记 + pid/nonce）+ 首屏/交互截图 |
| **T14 富 flyout（收尾）** | FlyoutPage 打开抽屉；项行点击；模板内按钮；`Shell.ItemTemplate`/多段项 | 富头/项/尾行出画；点行选中 + 关抽屉；模板按钮可点不误关；项模板文本绑定正确 | 截图（抽屉前后）+ 点击结果 |
| **T21 字体缩放** | 系统字号/`FontScale` 变化（含越界值） | Label/FormattedString 尺寸随缩放（放大/还原）；Entry 光标随缩放；非法/负值钳制/忽略且不崩 | 截图 + 终端/套件自报 |
| **T8 不等高 TableView** | 含不等高行（+与等高切换、滚动、更新）的 TableView 页 | 行不重叠、总高一致；滚动/更新（增删）正确；切回等高恢复 | 截图 + 滚动/更新结果 |
| **T20 媒体（无 Kit 属预期）** | 媒体演示入口 / `app://media/probe` 类热触发 | 无 MediaKit：`IsSupported=false`、load/play/... `Unavailable/Failed` **不抛**；有 Kit/HMS：真实播放 + 事件/状态 | hilog + 状态输出；无入口登记「未测（无 Kit）」 |
| **T19 深链** | `hdc shell aa start -U app://…`（冷）/运行中再投（热） | 冷 = `onCreate` 捕获→`bootstrap` 移交；热 = `onNewWant`；**热 `delivered=1`**；未知路由 ability/壳层无异常 | 壳 hilog `activation cold/hot … delivered=` 行；冷 `delivered=0` 为设计内 |
| **AOT 入口可观测** | AOT hap 启动后读 `<files>/dotnet-status.txt`（壳轮询 tail 打 hilog） | 出现托管入口/AOT 决策行（不再只有宿主 probe 行）；应用 breadcrumb 落盘 | status 文件 + hilog 截图/文本 |
| **承 #34：rc.2 版本自述** | 包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary | SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；无 rc.1 混装告警 | 自述原文 + summary |
| **承 #34：W6/W7/W8** | 按 #34 §2 逐项（T14/T12/N1/FIX-SHELL；T15/T16/N4/T18/N5/N6） | 同 #34 期望；套件自报行改为 **540/floor 520** | 截图 + `--a11y-probe` |
| **承 #33：Blazor 双 hap A/B / TabbedPage / W5** | 按 #33 判定树与一页卡 | 同 #33 期望（默认 ✅ → CSP 非瓶颈；默认 ❌ nocsp ✅ → CSP 至少次因） | `BLZ_BOOT`/`BLZ_RENDERED` + 首屏/`/counter` 截图 |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项（出画/点击/截图）照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.2.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT 包钉（新）**：rc.2 的 NativeAOT OpenHarmony pack OpenSSL shim 回归 → 设备 AOT 构建**本地 pin
   rc.1 `11.0.0-rc.1.26451.109`**（本地 hooks，不落仓）；**pack 修复后复核并撤钉**。最小复现命令见 §7。
3. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`（CoreLib `417ab220532` 起）。
4. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 上架后换 pin、删 feed step（承 #34 注记）。
5. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（本文随附）；maui = **`eec30c01cd`**
   （W9 四线并入：B2/T20/T21/T8；`0dcd972617`/`ae03a1af45`/`640de39638`/`6d6fd92b4b` 等为分支提交）；
   ohos-workload master **`080a63aa`**（W10 收口；其上 `bad7475` 为 W10 功能提交；三 workflow pin `eec30c01cd`）；
   sdk `4e3f16ceb1`（rc.2 AOT 文档两笔，承 #34 锚 `fb6c15e6d1`）；aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力，2026-09-30 起）

- **设备已可直测**（承 #34）：本机桌面 HAD-W32 / OpenHarmony 7.0.0.111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`
  （UDID `1BCE13C8…AEA0`）；SDK `sign-hap.sh` 自签；AOT 路径已验证（rc.2 线；本轮 W10 用 rc.1 AOT 包钉）。
- **W10 本轮证据**（scratch `w10/`、`w10-consol/`）：wasm `BLZ_BOOT`/`BLZ_RENDERED`（pid 6157）；
  MAUI 热激活 `delivered=1`；`[media-probe] load=Unavailable(-1)`（E9 镜像无 Media Kit）；套件 540/520。
- **已知（承 #34，根因见 `2026-09-30-ohos-jit-payload-install-policy.md`）**：JIT payload-in-libs 主包在本机
  新镜像装不上（`9568393`；libs 内无扩展名文件不在码签块 / 恰好 4096 B 文件的 fs-verity）——主包 JIT 真机判定
  仍以 tester 机为准；本机可用 AOT 路径。
- **本机可直接闭环**：AOT 出画、Blazor 标记、a11y/日志/截图回路；命令模板 =
  `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`（窗口竞态与 hilog 缓冲注见其 §4）。

## 5. 自签与包布局要点（测试方视角；承 #34）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap**：payload-in-libs 布局不变（`libs/arm64-v8a/` 原地携带 payload + `.dotnet-payload.json`，
  `dotnet.zip` 回退）；`libIsolation` 与自 #17 起全部安全/性能/启动修复不变；新壳 abc 以包内 `verify-kit.sh`
  期望为准（本轮 **339,164/23,516**）。
- **AOT 资产**：独立资产，不在 kit tar 内；安装会顶替 kit 主包，回 JIT 需重装 kit hap；数字以 release asset
  与 AOT README 为准（本轮 AOT 包若仍为 `aot-haps-v3*` 系列，以 release 为准）。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #35）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs/宿主依赖；abc 期望 = **339,164（`74054e2d…`）/23,516（`6bce4063…`）**，脚本哈希以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮 / `--blazor-probe` / `--mode-matrix` /
   `--a11y-probe` 四件同 #34。
3. **7 hap 表（kit #35 发布实测；`SHA256SUMS` 17 项 / 1,517 B / `2dd447a7…`）**：`hello-maui-app.hap`
   **133,965,654 / `e0f49a57…`**、`…-unsigned` **131,444,590 / `55d84827…`**、`…-permissions`
   **133,969,645 / `7cf2183c…`**、`…-api20` **133,965,601 / `711374cb…`**、`…-api20-permissions`
   **133,969,757 / `39292e9b…`**、Blazor 默认 **27,216,958 / `6227d0e6…`**（own abc 21,200 B、site 213 files）、
   `-nocsp` **27,216,659 / `a83ea068…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。
   整包 tar **375,629,423 / `419d42e2…`**、树 `d3b1b317…`、sidecar `d7e79d39…`；bundle/anchor 待刷新（以 release 为准）；
   重签/重打包后必变，以 release 与随包校验为准；
   有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#34）。
4. 离线证据（供复核）：套件 **540/520**、像素 PASS、导出 **149/149**、壳 abc **339,164/23,516**（四包一致 +
   provenance）、切片 0 error/0 IL、CI 5/5；W10 设备证据见 `w10/EVIDENCE.md`（BLZ 标记、`delivered=1`、
   `dotnet-status.txt` 根因链、ICU FailFast、`fileIo` 404 根因、指纹映射）；W9 证据见
   `docs/plans/2026-09-30-ohos-wave9-consolidation.md`、`…w9d-media-deeplink.md`、`…blazor-wasm-webview-b2.md`。

## 7. 风险 / 未验证（诚实清单）

- **W9/W10 各 UI 项仍以 tester JIT 机人工判定为主**（交付方本机 AOT 闭环 B2/T19/T20 降级；tab/W6/W7/W8 交互
  证据见 #34 注记）；无入口按「未测」登记，不判失败。
- **rc.2 AOT 包上游缺陷（未决）**：rc.2 NativeAOT OpenHarmony pack OpenSSL shim 0 定义 vs rc.1 5 定义
  （rc.2 档案 574 定义/35 对象 vs rc.1 1184/36），AOT 镜像 ~401 未决引用 → 设备 `dlopen` 拒绝（now=err
  lazy=err）。**最小复现**（本机 NuGet 缓存）：
  ```sh
  A=~/.nuget/packages/microsoft.netcore.app.runtime.nativeaot.openharmony-arm64
  nm --defined-only $A/11.0.0-rc.1.26451.109/runtimes/openharmony-arm64/native/libSystem.Security.Cryptography.Native.OpenSsl.a | grep -cE 'local_(EVP|SSL|X509)'  # 5
  nm --defined-only $A/11.0.0-rc.2.26451.112/runtimes/openharmony-arm64/native/libSystem.Security.Cryptography.Native.OpenSsl.a | grep -cE 'local_(EVP|SSL|X509)'  # 0
  ```
  修复 pack 后**撤 rc.1 钉**并复核；本轮设备 AOT 构建保持 rc.1 pin（本地 hooks，不落仓）。
- **payload 探针 `bundleCodeDir`（未决）**：壳 `findLibsPayloadDir` 在本机镜像仍探测不到 libs 内 AOT payload
  （bundleCodeDir 形态、无 module 段）；**启动已由宿主自身 libs 解析覆盖**，探针优化待后续（不阻塞启动）。
- **ICU/InvariantGlobalization**：无 ICU 镜像的 AOT demo 需 `InvariantGlobalization`（W10 已入 demo 配方；
  应用侧如遇 hosting 模块初始化 FailFast 可参考）。
- **门禁（FINAL）**：交互 540/floor 520、导出 149/149、像素 PASS、包内 `verify-kit.sh` 0 FAIL/0 WARN
  （abc 期望 339,164（`74054e2d…`）/23,516（`6bce4063…`）；脚本 69,522 / `c3cd4d38…`）、`ohos-workload` CI
  5/5 @ `080a63a`（interaction `36725822753` / pixel `36725822670` / host-export `36725822303` / ridgraph
  `36725822702` / markdownlint `36725822841`）；`preflight --quick` 全绿（`selftest-tasks` S3 已修，tasks 9 PASS）。
- 本次构建基线 = **rc.2 线**（SDK `.112` / workload `preview.28` / MAUI `rc2.26478.12`）；应用侧构建请同步该线
  （`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5；rc.1 回滚路径保留）。
