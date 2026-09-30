# 测试方交接：kit #34、rc.2 基线并入主线 + MAUI W6/W7/W8（T12/T14/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6）+ AOT v3（2026-09-30）

> 日期口径：文件名按撰写日；**kit #34 发布实测（release「## Integrity（kit #34）」）**：tar
> **375,181,367 B / `55834aeb…`**、树 **`d08de3ec…`**、sidecar **`c03ea23d…`**（89 B）、
> `SHA256SUMS` **17 项 / 1,517 B / `94fedc66…`**；**7 hap**（MAUI 5 + Blazor 默认/`-nocsp`；MAUI ~133.8 MB/件，
> rc.2 payload 变大）表见 §6.3。重签/重打包后哈希必变；CI run id 以 release 正文为准。
> 构建基线（rc.2 线）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **nuget/daily 注**：MAUI `11.0.0-rc.2.26478.12` 为 **dnceng daily**（nuget.org 尚未上架）→ 交付方 CI/本地
> restore 走 dnceng `dotnet11` feed；**官方 rc.2 包上 nuget.org 后立即换 pin 并移除 feed step**（kit #34 后）。
> 平台修复：CoreLib 接受 `LINUX` 别名（runtime `417ab220532`，随 rc.2 并入 `9b31ed2d08a`）→ 设备/本机构建
> `OS Platform: Linux`；构建环境三坑（MSBuild server / VBCSCompiler / 无超时 restore）见 `ohos-workload/docs/rc2-line-notes.md`。

> 结论先行：kit #34 = **kit #33 + ①rc.2 基线并入主线（五仓 RC2-MERGE） + ②MAUI W6 三件+一修复
> （T14 富 Shell flyout / T12 CarouselView 分组 / N1 多指坐标 / FIX-SHELL CurrentPage）
> + ③W7/W8 六件（T15 富 TitleView / T16 结构化菜单 / N4 TitleBar a11y / T18 Essentials IMap /
> N5 覆盖层触摸抑制 / N6 标题栏系统装饰） + ④AOT v3 独立资产（不在 kit 内，见 §1.9）**。
> 判定点见 §2（新增）与 §3（rc.2）；承接 #33 的 Blazor 双 hap A/B / TabbedPage / W5 与 #32–#25 判定点**继续有效**，
> 本文只覆盖 #34 增量与判读引用（一页卡：`2026-09-29-ohos-blazor-regression-retest-card.md`）。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（同 #33：runtime_mode 键、execmem、a11y 可选）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 回归 A/B（先分别重签两个变体；见 §2 / #33 一页卡）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段请用 aot-haps-v3；见 §1.9）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

## 1. kit #34 相对 #33 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **rc.2 基线（五仓并入主线）** | kit 与设备测试栈升级到 rc.2 线：SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`（dnceng daily）；宿主/壳按 rc.2 重建（新壳 abc 以 release/包内为准）；应用侧请同步 rc.2 线构建（rc.1 回滚保留） | §3（版本自述 + `OS Platform: Linux`） |
| 1.2 | **T14 富 Shell flyout** | FlyoutHeader/Footer 的 `View`/模板（Grid 行）与 `Shell.ItemTemplate` 项行**物化进抽屉面板**（此前仅文本）：头/尾/项行按模板渲染并绑定（如 Shell.Title）；点项行选中并关抽屉；**模板行内按钮点击不被选择/关闭抢走** | 抽屉打开 → 富头/尾/项行可见；点行选中+关闭；模板内按钮可点 |
| 1.3 | **T12 CarouselView 分组头/尾** | `OpenHarmonyCarouselView.GroupHeaderTemplate/GroupFooterTemplate` → 滑片流变为 `GroupHeader, Item…, GroupFooter`（可含多组）；指示器数量按同一流；水平滑动可跨组；清除模板回落 items+footers | 分组头/尾滑片出现且内容正确；滑动后 `CurrentItem` 跟随分组对象 |
| 1.4 | **N1 多指坐标 + FIX-SHELL** | N1：宿主 `OnTouch` 由「只报 point 0」改为**逐指针上报 id + 坐标**（多指拖拽/悬停/笔/双指手势不再坍缩到单指）；FIX-SHELL：Shell 的 `CurrentPage` 补进绘制遍历与 a11y（修复前 Shell 根只画 chrome/底栏，**页面主体黑**） | 多指手势（如 Pinch）两指轨迹正确；Shell 页面主体出画、切底部页签重绘；a11y 含当前页 |
| 1.5 | **T15 富 Shell.TitleView** | `Shell.TitleView` 非 Label 视图**物化进标题带**并替换标题文本（隐藏时回退页标题、清除销毁）；视图内按钮可点（命中带归行）；像素：金色 BoxView 视图在带中心出画 | 标题带出模板视图（非文本）；按钮点击生效；清除后回退/消失 |
| 1.6 | **T16 结构化菜单** | `MenuBar` 标题成为分组头；子菜单头展开其直接子项（按层级嵌套、可递归）；启用门控（bar/submenu/item 禁用不响应）；叶节点激活、头不激活；无新宿主时回落旧平铺 | 桌面菜单：分组头/嵌套子菜单/禁用态/叶激活逐项 |
| 1.7 | **N4 TitleBar 进行 a11y 影子树** | `Window.TitleBar` 行 + 模板子树进影子树（渲染根首个 a11y 子节点，含 bounds 0,0,300,64 风格）；模板按钮节点带 button 角色并可 `TryFindView` 回真实控件；隐藏/恢复/清除跟随 | 读屏可遍历 TitleBar 行/标题/按钮；隐藏后节点消失、恢复再现 |
| 1.8 | **T18 Essentials IMap + N5 覆盖层触摸抑制 + N6 系统装饰** | T18：`Map.Default` / DI `IMap` 解析到切片 `OpenHarmonyMapLauncher`，`OpenAsync` 以文档化 `geo:` URI 拉起系统地图（无处理 app 时 `TryOpenAsync=false`，**不抛**）；N5：诊断覆盖层元素选择器激活时**消费触摸**（下层控件不被激活），关闭即恢复穿透；N6：应用自管装饰时把系统 min/max/close + 标题带拖拽映射到 `Window.TitleBar` 行（全屏手机窗口不交付装饰；像素 = 三个 caption 字形） | T18 设备上拉起地图/无 app 降级不抛；N5 选择器下 Entry 不聚焦、关闭可聚焦；N6 桌面窗最小化/最大化/关闭 + 拖拽 + `TitleBar.Content` 按钮不被拖走 |
| 1.9 | **AOT v3 独立资产**（不在 kit 内） | `aot-haps-v3.tar.gz`（**17,537,186 B / `004ba03c…`**，asset 597904340；sidecar `0e28a268…`；README `abe541dd…`；含 TabbedPage 修复 + **UIPage 修复**：UI 壳 abc `289992`/`e005f236…`、`main_pages=pages/Index`；已签 **20,624,089 / `46d7a9ee…`**、未签 **20,369,300 / `5422b683…`**；本侧本机真机出画已验证：RSTree `ohos_dotnet_surface` buffer=1、`uiContent is null`=0）。v2/v1 保留对照。**MAUI 主包 JIT 若仍 `SEGV_ACCERR` 崩溃，用本资产重签安装判「主体渲染」**；如本轮另有 AOT 资产发布，以 release 为准 | 重签安装 → 启动 → `aot=1` → 主体出画 |
| 1.10 | **门禁/指纹** | 交互套件 **513/floor 493**（#33 = 470/450）、像素 `PIXEL ASSERTIONS PASSED`、宿主导出契约 **145/145**（#33 = 143）；新壳 abc = **311,424 B**（`7c1a3cac…`；headless 20,916；hap 内宿主 285,600 / `00ee9c84…`；包内 `verify-kit.sh` 69,522 / `dcd81f33…`）；`tester-run.sh` 承 **v14**（140,197 / `a174fcd0…`），`verify-kit.sh` 以包内为准 | `verify-kit.sh` 0 FAIL；版本自述 |

> 尺寸预算：以 release 资产表为准（#33 = 218,138,546 B；#34 的 delta = rc.2 重建 + 新壳 abc + Blazor 双件重建）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **rc.2 版本自述** | 包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary | SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；运行时日志无 rc.1 混装告警 | 自述原文 + summary |
| **T14 富 flyout** | 重签装默认 MAUI hap → FlyoutPage 打开抽屉 | 富头/尾/项模板行出画；点行选中 + 关闭；Alpha 模板行内按钮可点且不误关；`FlyoutHeaderTemplate` 绑定 Shell.Title | 截图（抽屉前后）+ 点击结果 |
| **T12 CarouselView 分组** | 分组 CarouselView + Header/Footer 模板 | 滑片流含 `GroupHeader`/`GroupFooter`；滑动跨组、指示器同步、`CurrentItem` 跟随；清除模板回落 | 截图 + 终端/套件自报 |
| **FIX-SHELL 主体** | Shell 双页签页面 | 当前页主体出画（不再只画 chrome/底栏）；切页重绘；a11y 影子树含当前页、不含另一页 | 截图 + `--a11y-probe` 两文件 |
| **T15 富 TitleView** | Shell 页设非 Label `TitleView` | 标题带出模板视图（标题文本被替换）；视图内按钮可点；隐藏 → 回退页标题；清除 → 行消失 | 截图 + hilog（若有命中日志） |
| **T16 结构化菜单** | 桌面菜单（MenuBar + 子菜单 + 禁用项） | 组头=栏标题；子菜单按层级嵌套；禁用 bar/submenu/item 不响应；叶激活、头不激活 | 截图（展开/禁用）+ 点击结果 |
| **N4 TitleBar a11y** | `Window.TitleBar` + 模板按钮页面，`--a11y-probe` | 影子树含 TitleBar 行（根首子节点 + bounds）与模板按钮节点；隐藏/恢复/清除跟随 | `a11y/` 两文件 + 截图 |
| **T18 IMap** | 调用 `Map.Default.OpenAsync(位置/命名地点)`（可带 `geo:` URI） | 设备有处理 app → 拉起系统地图；无 → `TryOpenAsync=false`、**不抛**；URI 构造符合 `geo:` 形状 | hilog/终端输出 + 截图（如拉起） |
| **N5 覆盖层触摸抑制** | 打开诊断覆盖层元素选择器 → 点下方 Entry；再关闭选择器复点 | 打开时 Entry **不**聚焦（触摸被消费）；关闭后正常聚焦 | 前后截图/状态 + 说明 |
| **N6 系统装饰** | 桌面窗口（app-managed 装饰）实体按钮区 | 最小化/最大化恢复/关闭 + 标题带拖拽生效；`TitleBar.Content` 按钮可点不被拖拽抢占；全屏手机窗口不出装饰 | 截图（caption 字形）+ 操作结果 |
| **AOT v3 回退（可选/主体）** | 若 JIT 路线启动即崩（`SEGV_ACCERR`）或主体仍黑：重签 `aot-haps-v3.tar.gz` 内未签 hap → 安装（会顶替 kit 主包）→ 启动 | 主体出画确认；`start_app: aot=1` 行（本侧本机已验：`ohos_dotnet_surface` buffer=1、`uiContent is null`=0） | 截图 + hilog（`aot=` 行） |
| **承 #33：Blazor 双 hap A/B** | 按 #33 判定树：默认 CSP 与 `-nocsp` 各重签各装一次（同名 bundle，装前卸载） | 默认 ✅ → CSP 非瓶颈；默认 ❌ 而 nocsp ✅ → CSP 至少是次因；两者 ❌ → 失败回传 | `BLZ_BOOT`/`BLZ_RENDERED` + 首屏/`/counter` 截图 |
| **承 #33：TabbedPage / W5** | 按 #33 §2：主体双页签、切页；T13/N3/T21/T22 | 同 #33 期望；套件自报行改为 **`[suite] checks=513 total=513 floor=493 assert=True`** | 截图 + 终端输出 |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项（出画/点击/截图）照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 AOT packs；
   rc.1（`11.0.100-rc.2.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **应用侧构建**：请同步 rc.2 线发布（不混装）；平台修复后设备/本机 `OS Platform: Linux`（CoreLib `417ab220532` 起），
   设备本地 AOT/打包路径才可用（此前 `Exec` 走 Windows 风格 `.exec.cmd`，链接器探针误报）。
3. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 尚未上 nuget.org；交付方 CI 两个 workflow 在 restore 前加
   dnceng `dotnet11` feed（workload `004b7f8`）。**官方 rc.2 上架后换 pin、删 feed step**（kit #34 后立即）。
4. **回归基线**：rc2 前后门禁层面 0 漂移（套件/像素/导出同数通过）；#33 的 Blazor/TabbedPage/W5 判定点照跑。
5. **五仓 tip（本波）**：runtime `9b31ed2d08a`（rc.2 五仓线并入 merge）+ 本仓 docs；maui **`ebffdd787c`**（rc.2 re-anchor + CA 作用域；
   W7/W8 链 `5a24b0c597`(T15)/`038449e803`(T16)/`43996268ff`(N4)/`b386b1c451`(T18)/`163e7554cf`(N5)/`63d6fe7019`(N6)）；
   ohos-workload `5305873`（三 workflow pin `ebffdd787c`）；sdk `469eae2734`；aspnetcore `e10d030184`。

## 4. 本机直测（交付方自验能力，2026-09-30 起）

- **设备已可直测**：本机桌面 HAD-W32 / OpenHarmony 7.0.0.109 / API 26；hdc 无线 `tconn 127.0.0.1:35111`
  （UDID `1BCE13C8…AEA0`）；SDK `sign-hap.sh` 自签；**AOT 路径已验证**（rc2 线：`publish-aot.sh` → `sign-for-device.sh`
  → `hdc install -r` → `aa start` → RSTree `ohos_dotnet_surface` 出画）。
- **rc2 线本机环境**：`DOTNET=$HOME/.dotnet.rc2-fix/dotnet`（SDK `.112` + workload `preview.28` + rc2 AOT packs；
  `OS Platform: Linux`）；dnceng feed/离线 `RestoreConfigFile` 按 `ohos-workload/docs/rc2-line-notes.md`；
  构建环境三坑（MSBuild server / VBCSCompiler / 无超时 restore）先用 `kit-build-env.sh` 规避。
- **已知（非 kit 缺陷）**：**JIT payload-in-libs 主包在本机新镜像装不上**（≥7.0.0.111 系拒绝 `libs/**` 非 ELF 载荷，
  安装报 `9568393`）——主包 JIT 真机判定仍以 tester 机（旧镜像/在线签名）为准；本机可用 AOT 路径或
  `-p:OpenHarmonyHapPayloadInLibs=false` 重出包复测。
- **本机可直接闭环**：Blazor 双 hap A/B（#33 已验）、AOT 出画、a11y/日志/截图回路；命令模板 =
  `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`（窗口竞态与 hilog 缓冲注见其 §4）。

## 5. 自签与包布局要点（测试方视角；承 #33）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（两个变体同名，装前卸载旧件）；仍无 INTERNET（重签保持）；
  标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记（旧宿主降级 + WARN）。
- **MAUI 5 hap**：payload-in-libs 布局不变（`libs/arm64-v8a/` 254 payload + `.dotnet-payload.json`，`dotnet.zip` 回退）；
  `libIsolation` 与自 #17 起全部安全/性能/启动修复不变；新壳 abc 以包内 `verify-kit.sh` 期望为准。
- **AOT v3**：独立资产，不在 kit tar 内；安装会顶替 kit 主包，回 JIT 需重装 kit hap；数字以 release asset 与
  `aot-haps-v3` README 为准。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #34）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs/宿主依赖；abc 期望 = **311,424/20,916**；包内脚本 69,522 / `dcd81f33…`，selftest 108/0）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮 / `--blazor-probe` / `--mode-matrix`（AOT 段用
   `aot-haps-v3.tar.gz`）/ `--a11y-probe` 四件同 #33。
3. **7 hap 表（kit #34 发布实测；`SHA256SUMS` 17 项 / 1,517 B / `94fedc66…`）**：`hello-maui-app.hap` **133,827,313 / `9614f69d…`**、
   `…-unsigned` **131,304,609 / `f0def954…`**、`…-permissions` **133,831,417 / `a7a3391c…`**、
   `…-api20` **133,831,490 / `701104e8…`**、`…-api20-permissions` **133,831,449 / `d3bf37f6…`**、
   Blazor 默认 **27,216,958 / `8e407504…`**、`-nocsp` **27,216,659 / `68606606…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。
   整包 tar **375,181,367 / `55834aeb…`**、树 `d08de3ec…`、sidecar `c03ea23d…`；bundle = `workload-1.0.0-preview.28`（**rc.2 重打包进行中，新 sha 以 release 为准**；#33 = 77,689,347 / `155960f4…`，锚 `e7727959cc`）；重签/重打包后必变，以 release 与随包校验为准；
   有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#33）。
4. 离线证据（供复核）：套件 **513/493**、像素 PASS、导出 **145**（CI run 36656123464 / 36656123473 / 36656123543
   + 本地同树复跑）；FIX-SHELL/T12/T14/T15/T16/N4/T18/N5/N6 的交互/像素断言与负控（`w7/`、`w8/` scratch）；
   AOT v3 的 `verify-aot-v3.sh` 与发布校验（by-id/gh-proxy/零改动）。

## 7. 风险 / 未验证（诚实清单）

- **W6/W7/W8 各 UI 项均未在真机验证**（我方本机仅闭环 AOT/Blazor；JIT 主包受本机镜像载荷限制）——正是本轮要闭环的判定点。
- **rc.2 应用侧**本机未重跑（内存纪律）；以 CI/发布/设备证据为准（§3、§6.4）。
- **T18 真拉起、N6 系统装饰、T15/T16 的交互细节**依赖设备是否具备对应窗口/地图能力；无入口按「未测」登记，不判失败。
- Blazor 双 hap 与 #33 相同（rc.2 重建后哈希必变）；主包 JIT `SEGV_ACCERR` 仍可能（平台禁 JIT），以 AOT v3 回退判主体。
- **门禁（FINAL）**：交互 513/floor 493、导出 145/145、像素 PASS、包内 `verify-kit.sh` 0 FAIL/0 WARN
  （69,522 / `dcd81f33…`，abc 期望 311,424/20,916）、`ohos-workload` CI 5/5 @ `5305873`（ridgraph 20/20；run id 以 release 正文为准）；
  `selftest-tasks` S3 为预存项（与本次并入 0 diff，建议随 kit 窗口重锚）。
- 本次构建 = **rc.2 线**（SDK `.112` / workload `preview.28` / MAUI `rc2.26478.12`）；应用侧构建请同步该线
  （`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5；rc.1 回滚路径保留）。
