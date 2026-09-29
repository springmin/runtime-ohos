# AOT-V3：UIPage 修复后的 slice 重编 NativeAOT 包并发布（2026-09-29）

> 目的：DEV-LOOP-MAUI 定位的**空白窗根因**（AOT publish 缺 `-p:OpenHarmonyUIPage=pages/Index` →
> hap 只带 headless abc + 空 `main_pages.json` → 无 `XComponent` → MAUI 窗口全白 + WMS
> `uiContent is null`）修复后重出 AOT 资产，作为 `aot-haps-v2.tar.gz` 的**替代复测包**（v2 保留
> 对照：它带 TabbedPage 修复但仍是 headless abc）；同时把 UIPage 判定点回写工具链
> （`springmin/ohos-workload` `30a1c7e`）。
>
> 关联：`2026-09-29-ohos-local-device-test-runbook.md` §5（根因/fix 本机证据）、
> `2026-09-29-ohos-aot-v2-rebuild.md`（v2 口径）、`ohos-workload/test/hello-maui-app/AOT.md`
> 与 `ohos-workload/docs/openharmony-hap-packaging.md`「NativeAOT HAP variant」。

## 1. 输入与 provenance

| 项 | 值 |
| --- | --- |
| slice（MAUI 平台层） | `springmin/maui-ohos` `14bdb85f4f705426085fb2fedc3491eda736c979`（"enumerate the TabbedPage's CurrentPage in the compositor walk"，与 v2 相同；fetch 时 origin tip `dc9b19a6` 为后代） |
| slice 冻结副本 | `aot-v3/slice-fix/`（v2 冻结副本的原样拷贝；`OpenHarmonyWindowRenderer.cs` blob `3da77238b6fc36a6b409a191c2e96f1a132bde06` == 提交 blob，发布前校验通过） |
| 工作仓 | `springmin/ohos-workload` @ `30a1c7e`（**本任务回写提交**：`test/hello-maui-app/publish-aot.sh` + `AOT.md`、`make-mode-kit.sh` aot 模式默认 `OpenHarmonyUIPage=pages/Index`、打包文档判定点；publish 用该脚本原样执行） |
| SDK / packs | SDK `11.0.100-rc.2.26451.109`；workload packs `1.0.0-preview.24`（宿主 281,504 B / `f6b3581a…`；UI 壳模板 `templates/ets/modules.ui.abc` 289,992 B / `e005f236…`） |
| 本机环境 hooks | `aot-v3/aot-local-hooks.targets`（与 v2 同一文件 `970cba34…`：rc.2 宿主 `Exec` 批处理包装替换 + kit #32 LocalRun/AspNetCore 重定向）+ `OhosTaskHostOverride=true`，经 `OHOS_AOT_HOOKS` 注入；不落仓 |
| publish 命令 | `dotnet publish test/hello-maui-app/hello-maui-app.csproj -f net11.0-openharmony26.0 -r openharmony-arm64 -c Release -m:1 -p:PublishAot=true -p:PublishAotUsingRuntimePack=true -p:CompressSymbols=false -p:CopyOutputSymbolsToPublishDirectory=false -p:OpenHarmonyHapPackage=true -p:OpenHarmonySdkRoot=$OHOS_SDK -p:OpenHarmonyUIPage=pages/Index -p:OpenHarmonyRuntimeMode=aot -p:OpenHarmonyMauiPlatformDir=<slice-fix> --source <空 feed>`（= `publish-aot.sh` 内部命令） |
| 日志 | `aot-v3/publish-aot.log`（`EXIT=0`，2026-09-29 18:01:56；增量重跑口径见 §2） |

## 2. 产物指纹（发布值）

| 产物 | 大小 (B) | sha256 |
| --- | --- | --- |
| `libhello-maui-app.so`（publish） | 17,709,840 | `9c9658db21a75665f8dcd4d0fa75884967cd93caba72b1616ced712eeac9d60e` |
| `hello-maui-app.hap`（pack 自签，publish 输出） | 20,624,183 | `bc41a97a…` |
| `hello-maui-app-aot.hap`（SDK `sign-hap.sh` + UDID `60CF…` 重签，**发布件**） | 20,624,089 | `46d7a9ee00e8079c9c9f14f9326c45438c5e5045673a32f724bd05cef06aaead` |
| `hello-maui-app-aot-unsigned.hap`（发布件） | 20,369,300 | `5422b683893ec09609288d02c027dc31b6bac4c3b3722a5fa619f0008bdf83a8` |
| hap 内宿主 `libopenharmonyhost.so` | 281,504 | `f6b3581a18720db105352e5da41e928723b4bf07af0467149dff1ee32441be69`（== preview.24 pack，含桥） |
| hap 内 `ets/modules.abc`（**UI 壳**） | 289,992 | `e005f2366d72430979e8cd65477bf6f4d12284421cd4eccd99ee1f5dbeae0c57`（== pack `templates/ets/modules.ui.abc`） |

- so：`nm -D` 含 `T openharmony_app_main@@V1.0`；`.codesign` sections=1；NEEDED = `libc.so`；
  IL 门禁 **IL2026/IL3050/IL3051 = 0**。
- hap 形态（signed/unsigned 一致）：仅 3 个 `.so`（app so + host + `libc++_shared.so`），**无**
  `libcoreclr.so`/`libhostfxr.so`/`libclrjit.so`；`main_pages={"src":["pages/Index"]}`、
  `runtime-mode.txt=aot`、`libs/arm64-v8a/.dotnet-payload.json`（`assembly=hello-maui-app.dll`）、
  `resources/rawfile/app.json` 在包；`module.json` `libIsolation=true`、无 `requestPermissions`。
- 静态核验：`aot-v3/verify-aot-v3.sh` → **ALL CHECKS PASSED**（59 PASS / 0 FAIL；含 abc == pack
  UI 壳 sha、abc 含 `XComponent`/`loadContent`、marker、三 so 计数；日志 `aot-v3/verify-aot-v3.log`）。
- **增量口径**：本次重跑（写回提交 `30a1c7e` 下，`publish-aot.sh`）为 MSBuild 增量 no-op —— 同命令的
  修复发布已在 16:38（dev-loop）产出这些字节，重跑 `EXIT=0`、输出未变（hap mtime 16:38）；因此发布件
  字节 = 16:38 的 UIPage 修复发布输出，dev-loop 与本轮设备验证都是这组字节。signed 的 20,624,183（pack
  默认 profile）与重签件 20,624,089 仅签名块/profile 不同。

## 3. 根因与修复（一句话）

v2 及更早的 AOT publish（以及 `make-mode-kit` 的 aot 模式）**没带** `-p:OpenHarmonyUIPage=pages/Index`：
hap 打包目标因此 stage `templates/ets/modules.abc`（headless，20,916 B）并写空 `main_pages.json`
（`{"src":[]}`），hap 没有 `XComponent`/`loadContent` → 窗口全白、WMSDecor 反复
`IsHitTitleBar: uiContent is null`（进程/.NET 线程/`start_app` 调用都"像"正常，误导排查）。
v3 的 publish 加上该属性后：abc 换成 UI 壳（289,992 B，含 `XComponent`/`loadContent`）、
`main_pages={"src":["pages/Index"]}`、`runtime-mode.txt=aot`，本机真机出画（§4）。
判定点已回写：`make-mode-kit.sh --mode aot` 默认该属性（`--property` 可覆盖），
`docs/openharmony-hap-packaging.md`「NativeAOT HAP variant」明确 "AOT 与 JIT 必须同带 UIPage"，
`test/hello-maui-app/AOT.md` 是常驻参考卡。

## 4. 本机真机验证（出画）

- **签名/安装**：SDK `sign-hap.sh`（preview.24 模板）+ UDID `60CF7B27…` → profile `device-ids`
  单值（`verify.p7b` 已核）；`hdc install -r` **直装成功**（本机桌面镜像不校验 device-ids），
  `aa start -b com.example.hellomauiapp -a EntryAbility` 起进程（两次跑：pid 48676/50533）。
- **证据**（scratch `aot-v3/device/`）：`install-v3.log`、`aa-start-v3.log`；`VmRSS` 178,692 →
  134,328 kB、`Threads` 61/62（含 `OS_GC_Thread`/`ThreadPool*` ≥4）；`wms-v3-final.txt` 窗口
  `hellomauiapp0 [515 281 2090 1394]`、**`uiContent is null` = 0**；`rstree-v3-final.txt`
  **2 × `Name [ohos_dotnet_surfaceSurface]`、均 `hasSurfaceBuffer: 1`**（v1/v2 headless = 0 个）；
  `hilog-live-v3.txt`：`OHOS_DOTNET: managed app hello-maui-app.dll started (UI shell) from
  <filesDir>/dotnet`；截图 `snap-v3.jpeg`/`win-v3.png`/`snap-v3b.ppm`（窗口 edge-density 0.02%）。
- **与 JIT 对照**：同机 dev-loop 16:52 的 JIT 截图（`dev-maui/win-jit.png`，kit33 口径）窗口内容
  同为「渐变 + 居中按钮」，非 AOT 特异；旧 v2 白窗同 metric 0.000% vs v3 0.016%（全屏 crop，
  同脚本同参数）。kit33 发布件本机直装 9568393（需按 tester 证书重签，属交付口径），JIT 侧引用
  dev-loop 证据。
- **tab 双页签判定**：两张本轮截图只见页面主体（渐变 + 按钮），未见 tab 栏/页签标题 →
  **双页签出画无法从截图判定**（与 JIT 截图一致）；本轮钉死的是「UI 壳 + 主体出画」。

## 5. 发布（release `springmin/sdk-ohos` tag `device-test-kit`，id 392356147）

新并列资产（**不动**旧包；assets 30 → 33）：

| 资产 | id | 大小 (B) | sha256 |
| --- | --- | --- | --- |
| `aot-haps-v3.tar.gz` | 597904340 | 17,537,186 | `004ba03cdf8ee0474bff73b6a890064cb724869963731f981c4a57c78fa10cba` |
| `aot-haps-v3.tar.gz.sha256` | 597904338 | 85 | `0e28a2681c0d0bc4812c373529618e7cbe97f8a41f96b73936488373716de980`（内容 = tar 摘要） |
| `aot-haps-v3-README.md` | 597904349 | 6,536 | `abe541ddf60332970bf87cf970fce9268d5227fbed9f79fb8f760ab5c6c68d42` |

- 校验（`aot-v3/verify-publish-v3.py`，日志 `verify-publish-v3.log`）：**PART A/B/C PASS** —— by-id
  三项 digest+size 与本地一致；相对发布前快照**仅新增这 3 项**（changed=[]、removed=[]，30→33）；
  gh-proxy 下载 tar/sidecar/README 逐字节相等；tar 内两 hap sha 与本地一致，tar 内 abc = UI 壳
  （289,992）+ `main_pages` 含 `pages/Index`；tar HEAD `200` + content-length 17,537,186。
- release notes 已追加一行：v3 = UIPage 修复、**出画已验证**、取代 `aot-haps-v2.tar.gz`（v2 17,323,220 /
  `265e014f…` 与旧 `aot-haps.tar.gz` 17,093,146 / `91e1b9d3…` 均保留对照——两者都是 headless、白窗）。
- 上传方式：`gh release upload device-test-kit <file>#<name> --clobber`（显式 clobber；新名无覆盖冲突）。

## 6. 边界与未决

- **真机复测归 tester**：重签（华为调试证书 + Profile 绑定其 UDID）→ 安装（会顶替 kit 主包）→
  启动 → `aot=1` → 主体渲染确认；本侧已把「UI 壳 + 出画」钉死，tester 侧 = 复测主体内容。
- `_framework/dotnet.js` 静态资产路由属 **kit #33**（FIX-BLZ-JS），不在本包口径。
- a11y 影子树的 TabbedPage 枚举缺口（`OpenHarmonyAccessibility.PushChildren`）仍是 follow-up（v2 已记）。
- 本机 rc.2 的 `Exec` 批处理包装/cwd 问题仍用命令行 hooks 旁路（不落仓）；`publish-aot.sh` 保留
  `OHOS_AOT_HOOKS` 注入口，换干净环境重编按 `docs/openharmony-hap-packaging.md`「Known environment
  quirks」复核。
- 签名 UDID：v3 已签 hap 按 **tester UDID `60CF7B27…`**（profile device-ids 单值）；本机桌面镜像
  不校验 debug profile 的 device-ids，故同一 hap 直接装本机验证（§4）。tester 证书/Profile 不同
  时按其流程重签未签件（v2/v3 口径一致）。
- slice pin（ohos-workload CI 的 `MAUI_OHOS_REF`）未随本任务改动；v3 用的是 v2 冻结修复副本，
  不含 `dc9b19a6` 之后的其他切片改动。
