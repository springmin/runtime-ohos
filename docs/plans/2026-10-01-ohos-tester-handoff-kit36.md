# 测试方交接：kit #36、payload 原地直载 / host 预注册缓冲 / 像素 Known 清零 / a11y 修复 / rc.2 AOT pack `-r2`（2026-10-01）

> 日期口径：文件名按撰写日；**kit #36 发布数字以 release「## Integrity（kit #36）」、`.tar.gz.sha256`
> sidecar 与随包 `SHA256SUMS` 为准**（发布在途；#35 实测 = tar **375,629,423 B / `419d42e2…`**、树
> **`d3b1b317…`**、sidecar **`d7e79d39…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `2dd447a7…`**，
> 仅作上一版对照）。重签/重打包后哈希必变；CI run id 以 release 正文为准。
> 构建基线（rc.2 线，同 #34/#35）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（#36 撤钉）**：rc.2 NativeAOT OpenHarmony pack 的 OpenSSL shim 缺陷（EVP/SSL/X509 定义 0 vs
> rc.1 的 5；AOT 镜像 ~401 未决引用 → 设备 `dlopen` 拒绝）已由修正版资产
> **`Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.2.26451.112-r2.nupkg`**
> （**28,904,657 B / `542058cf…`**，release `aot-packs-11.0.0-rc.2` asset **601289590**）修复 →
> **撤销 #35 的本地 rc.1 钉**（详见 `docs/plans/2026-09-30-rc2-aotpack-openssl-shim-fix.md`）。

> 结论先行：kit #36 = **kit #35 + 五项**：①**payload 原地直载**——壳 `findLibsPayloadDir` 兼容模块布局
> `<bundleCodeDir>/<module>/libs/<abi>`（真机 `/data/storage/el1/bundle/entry/libs/arm64`），hello-maui-wasm
> **直接自 libs 原地启动**（hilog `payload-in-libs: running from … (dotnet.zip not unpacked)`，pid 49565）且
> AOT 路径 `BLZ_BOOT`/`BLZ_RENDERED` 双标记齐；②**host 预注册缓冲**——宿主缓存壳 `registerWebSink` 注册前
> 到达的 web 命令（**16 条 / 64 KiB**，注册即 flush），消除原地直载去掉 zip 拷贝延迟后暴露的竞态；
> ③**像素 Known 清零**——selection tint 改字节量化精确断言（`#3959B3`），套件不再有 `Known(...)`；
> ④**a11y 渲染帧修复**——`nodeCount 0` 根因 = shadow tree 未 publish（W10 前托管入口不可达），S2a pin
> `renderAttached=True`、`--a11y-probe` 实测 `status=1`、nodeCount 5/24 稳定；⑤**rc.2 AOT pack `-r2`**
> 发布并撤 rc.1 钉。**新壳 abc 339,964（`fc54d2b8…`）/ headless 24,324（`798b2477…`）、hap 内宿主
> 293,792（`cfbbe461…`）、导出 149/149、套件 540/floor 520**。判定点见 §2；承接 #35 的 W9/W10 与 #34/#33
> 的判定点**继续有效**，本文只覆盖 #36 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（同 #35：runtime_mode 键、execmem、a11y 可选）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 探针（B2 走 MAUI WebView 内嵌 WASM；本轮主判定之一）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段用本轮 AOT 资产；rc.2 pack 用 -r2 feed，撤 rc.1 钉）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；#35/#36 本批未刷新）

`device-test-kit` release 自 #34 起有并列预签资产 **`preSigned-haps.tar.gz`**（asset 600101072，
375,834,798 B / `b492b284…`）：7 hap 全部按 **tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`**
预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装、无需重签**（同 bundle 换件仍先卸载）；
非 tester UDID 设备报 `9568344` → 回传 UDID 重出或按包内 README 自签。**#35/#36 本批未刷新预签件
（沿 #34 件；#36 如需预签请回传 UDID 代签）**；预签包是并列附加件，完整一轮仍用 `device-test-kit.tar.gz`。

## 1. kit #36 相对 #35 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **payload 原地直载（PAYLOAD-IN-PLACE）** | 壳 `findLibsPayloadDir` 同时探测两种 libs 根：libIsolation 布局 `<bundleCodeDir>/libs/<abi>` 与 7.0.0.111+ 的模块布局 `<bundleCodeDir>/<moduleName>/libs/<abi>`（实测 `/data/storage/el1/bundle/entry/libs/arm64`；旧单根在本镜像探测不到而每次回退解压树）。真机 hello-maui-wasm：`payload-in-libs: running from /data/storage/el1/bundle/entry/libs/arm64 (dotnet.zip not unpacked)`（pid 49565），随后 `BLZ_BOOT`/`BLZ_RENDERED` 双标记齐；miss 时先打一行再回退 `dotnet.zip`（降级不判失败） | hilog `payload-in-libs: running from …`；B2 双标记；`dotnet.zip` 未解压仍出画 |
| 1.2 | **host 预注册缓冲（HOST-PENDING）** | 宿主把壳 `registerWebSink` 注册**前**到达的 web 命令缓存（上限 **16 条 / 64 KiB**，注册回调时按序 flush）；原地直载去掉了 zip 拷贝延迟（此前恰好掩盖该竞态：Blazor 站点注册与 WebView source load 双双丢失）。套件新增 pin `moduleRoot`/`webPending` | 注册前触发的 WebView/B2 流程不丢命令；`BLZ_BOOT`/`BLZ_RENDERED` 齐 |
| 1.3 | **像素 Known 清零（PIXEL-KNOWN-CLEAR）** | selection tint 旧报 `Known`：光栅写 `#3959B3` vs 浮点 Blend 期望 `#395AB3`（绿色差 1 LSB）。根因是 fixture 字节量化（0.35 alpha → 89/255 且逐通道截断）；期望改用同量化 `QuantizedBlend`、容差 0，**套件不再有 `Known(...)`**（`selection tint: got #3959B3 expected #3959B3`；`PIXEL ASSERTIONS PASSED`） | `test/headless-render` 全断言 PASS（无 `[KNOWN]`/`Known(`） |
| 1.4 | **a11y 渲染帧修复（A11Y-FRAME）** | rc.2 的 `nodeCount 0` 自检发现 = **影子树从未发布**：W10 AOT 修复前托管入口不可达，枚举已绘制帧并交给宿主的渲染路径从未运行（**不是导出损坏**）。S2a 检查现 pin 渲染帧挂接（`OpenHarmonyWindowRenderer` 在枚举后立刻 `Refresh(content)` + `Publish()`），注释/README 记录设备复核：`accessibilityStatus 1 (attached)`、`accessibilityNodeCount 5`（wasm 演示页）/ `24`（hello-maui-app），重复读稳定；套件 `renderAttached=True` | `--a11y-probe`：`status=1` + 正整数 nodeCount（5/24）稳定 |
| 1.5 | **rc.2 AOT pack `-r2`（撤 rc.1 钉）** | 修正版 pack 仅替换坏归档（36 成员 / 5 `local_(EVP\|SSL\|X509)` / raw undefined OpenSSL = 0），其余 409 条目原字节；asset **601289590**（28,904,657 / `542058cf…`）。sdk-ohos 侧 `versions.env` 换锚 + `fetch-nativeaot-packs.sh` 新增 shim 内容校验（失败拒入 feed 并删除）；`NATIVE-AOT.md` 记录 NuGet 缓存注意项 | 设备/本机 AOT 构建直接用 `-r2`（无需本地 hooks）；坏包缓存需删 `~/.nuget/packages/microsoft.netcore.app.runtime.nativeaot.openharmony-arm64/11.0.0-rc.2.26451.112` 再 publish |
| 1.6 | **门禁/指纹** | 交互套件 **540/floor 520**（declared==printed；新增 pin `moduleRoot`/`webPending`/`renderAttached`）、像素 `PIXEL ASSERTIONS PASSED`（无 `Known`）、宿主导出契约 **149/149**；**新壳 abc = 339,964 B（`fc54d2b8…`）/ headless 24,324 B（`798b2477…`）**、hap 内宿主 **293,792 B（`cfbbe461…`）**；四包 `preview.22/23/24/28` 字节一致 + 同 provenance；`verify-kit` 期望已重锚（339964/24324）；`build-arkts-shell` 185/0、`verify-kit` 108/0、packs 25/0、repo-hygiene 25/0、hap-targets 50/0+1skip；CI run id 以 release 正文为准 | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**（abc 期望 339964/24324）；套件自报行 `[suite] checks=540 total=540 floor=520 assert=True` |

> 尺寸预算：以 release 资产表为准（#35 = 375,629,423 B；#36 的 delta = 新壳/宿主 + 门禁/pin 重建 + 本轮产物）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **payload 原地直载（主判点）** | 装 MAUI 演示 hap（hello-maui-wasm 或包内说明的入口）→ 冷启 | hilog `payload-in-libs: running from /data/storage/el1/bundle/entry/libs/arm64 (dotnet.zip not unpacked)`；`dotnet.zip` 未解压；应用出画 | hilog 行 + 首屏截图 |
| **host 预注册缓冲 + B2 BLZ** | 打开嵌入式 Blazor 页（AOT 路径） | `BLZ_BOOT` 与 `BLZ_RENDERED` **同 pid 双标记齐**、无 `BLZ_ERROR`；首屏 + `/counter` 交互成立；壳 `BlazorWebHost`/`web cmd blazor … mode=wasm` 可见 | hilog（标记 + pid/nonce）+ 首屏/交互截图 |
| **像素 Known 清零（套件侧）** | 交付方/有源码测试者跑 `test/headless-render` | `PIXEL ASSERTIONS PASSED`；无 `Known(...)`（selection tint `#3959B3` 精确） | 终端输出 |
| **a11y 渲染帧** | `--a11y-probe`（A11Y 自检入口） | `a11y/selfcheck.txt`：`status=1`（attached）+ 正整数 nodeCount（wasm 页 **5** / 主包 **24**）稳定；影子树含当前页节点 | `a11y/selfcheck.txt` + `hilog-a11y.txt` + 截图 |
| **rc.2 AOT pack `-r2`** | 设备/本机 AOT 构建（feed 用 `-r2`）→ 启动 | publish rc=0；`aot=1` + 主体渲染；不再需要 rc.1 本地钉 | publish 日志 + 启动 hilog |
| **承 #35：W9/W10** | 按 `2026-09-30-ohos-tester-handoff-kit35.md` §2 逐项（B2/T14/T21/T8/T20/T19/AOT 入口） | 同 #35 期望；套件自报行 `540/floor 520` | 截图 + hilog + `dotnet-status.txt` |
| **承 #34：rc.2 版本自述 + W6/W7/W8** | 包内《最终状态.md》/`README-交付说明.md`；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6 | SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；逐项同 #34 | 自述原文 + 截图 + `--a11y-probe` |
| **承 #33：Blazor 双 hap A/B / TabbedPage / W5** | 按 #33 判定树与一页卡 | 同 #33 期望（默认 ✅ → CSP 非瓶颈；默认 ❌ nocsp ✅ → CSP 至少次因） | `BLZ_BOOT`/`BLZ_RENDERED` + 截图 |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项（出画/点击/截图）照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34/#35）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.2.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（#36 更新：撤 rc.1 钉）**：改用 `-r2` 修正版 pack（asset 601289590）——设备/本机 AOT 构建
   不再需要本地 hooks；最小复现与判据见 `docs/plans/2026-09-30-rc2-aotpack-openssl-shim-fix.md` §1/§4。
3. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`（CoreLib `417ab220532` 起）。
4. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 上架后换 pin、删 feed step（承 #34 注记）。
5. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（本文随附）；maui = **`eec30c01cd`**
   （本波未动；W9 四线并入：B2/T20/T21/T8）；ohos-workload master **`ce4588c`**（#36 三笔：
   `7c2bb60` payload 原地直载 + `7190940` 像素精确 + `ce4588c` a11y；其上 `080a63a` 为 W10 收口）；
   sdk **`48c8b210dc`**（`-r2` 换锚 + shim 内容校验；合并/锚以 release 为准）；aspnetcore `e10d030184`
   （以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34/#35）：本机桌面 HAD-W32 / OpenHarmony 7.0.0.111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`
  （UDID `1BCE13C8…AEA0`）；SDK `sign-hap.sh` 自签；AOT 路径已验证（rc.2 线；#36 用 `-r2` feed）。
- **#36 本轮证据**（scratch `small-left/`）：原地直载 hilog 行 + `BLZ_BOOT`/`BLZ_RENDERED`
  （hello-maui-wasm pid 49565，10-01 00:07:39/41）；像素 `PIXEL ASSERTIONS PASSED`（无 `Known`）；
  a11y `status=1`/nodeCount 5/24；交互套件 540/540 floor 520；`[suite]` 自报与本地门禁全绿。
- **已知（承 #34/#35）**：JIT payload-in-libs 主包在本机新镜像装不上（`9568393`；libs 内无扩展名文件不在
  码签块 / 恰好 4096 B 文件的 fs-verity）——主包 JIT 真机判定仍以 tester 机为准；本机可用 AOT 路径。
- **本机可直接闭环**：AOT 出画、Blazor 标记、a11y/日志/截图回路；命令模板 =
  `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`（窗口竞态与 hilog 缓冲注见其 §4）。

## 5. 自签与包布局要点（测试方视角；承 #34/#35）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap**：payload-in-libs 布局不变（`libs/arm64-v8a/` 原地携带 payload + `.dotnet-payload.json`，
  `dotnet.zip` 回退；#36 起模块布局探测命中后**原地启动、不解压**）；`libIsolation` 与自 #17 起全部安全/性能/
  启动修复不变；新壳 abc 以包内 `verify-kit.sh` 期望为准（本轮 **339,964/24,324**）。
- **AOT 资产**：独立资产，不在 kit tar 内；安装会顶替 kit 主包，回 JIT 需重装 kit hap；数字以 release asset
  与 AOT README 为准（本轮 AOT 包若仍为 `aot-haps-v3*` 系列，以 release 为准；pack 用 `-r2`）。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #36）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs/宿主依赖；abc 期望 = **339,964（`fc54d2b8…`）/24,324（`798b2477…`）**，脚本哈希以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮 / `--blazor-probe` / `--mode-matrix` /
   `--a11y-probe` 四件同 #35。
3. **7 hap 表（kit #36 以 release「## Integrity（kit #36）」与包内 `SHA256SUMS` 为准）**：#35 表仅作上一版
   对照 —— `hello-maui-app.hap` **133,965,654 / `e0f49a57…`**、`…-unsigned` **131,444,590 / `55d84827…`**、
   `…-permissions` **133,969,645 / `7cf2183c…`**、`…-api20` **133,965,601 / `711374cb…`**、
   `…-api20-permissions` **133,969,757 / `39292e9b…`**、Blazor 默认 **27,216,958 / `6227d0e6…`**、
   `-nocsp` **27,216,659 / `a83ea068…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。
   整包 tar/树/sidecar/bundle 以 release 为准（#35 = tar **375,629,423 / `419d42e2…`**、树 `d3b1b317…`、
   sidecar `d7e79d39…`；bundle `openharmony-workload-1.0.0-preview.28.tar.gz` **77,754,383 / `acd26821…`**；
   sdk-ohos 锚 **`02a31ef348`**；dtk **392356147** / latest **392077166**）；
   重签/重打包后必变，以 release 与随包校验为准；
   有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#35）。
4. 离线证据（供复核）：套件 **540/520**、像素 PASS（Known 清零）、导出 **149/149**、壳 abc **339,964/24,324**
   （四包一致 + provenance）、`build-arkts-shell 185/0`、`verify-kit 108/0`、packs/repo-hygiene 25/0、
   hap-targets 50/0+1skip；#36 设备证据见 scratch `small-left/`（原地直载 + BLZ 双标记 + a11y + 像素）；
   #35 证据见 `docs/plans/2026-09-30-ohos-wave10-consolidation.md`、`…w9d-media-deeplink.md`、
   `…blazor-wasm-webview-b2.md`。

## 7. 风险 / 未验证（诚实清单）

- **W9/W10 各 UI 项仍以 tester JIT 机人工判定为主**（交付方本机 AOT 闭环 B2/T19/T20 降级；tab/W6/W7/W8 交互
  证据见 #34 注记）；无入口按「未测」登记，不判失败。
- **payload 探针 `bundleCodeDir`（#36 已缓解）**：壳现同时探测模块布局（`<bundleCodeDir>/<module>/libs/<abi>`）
  与 libIsolation 布局；本机镜像命中且原地启动。若个别机型两者皆 miss，会打一行提示并回退 `dotnet.zip`
  （功能不丢，仅回到解压路径）——请附该行 hilog 回传。
- **AOT pack 结构性缺陷（上游面，未彻底）**：一次 `build-native.sh` 同时产出共享 `.so`（静态 OpenSSL）与
  静态 `.a`（需 shim），二者需求相反；当前以 fetch 端 shim 内容校验兜底（`-r2`），彻底解法见
  `docs/plans/2026-09-30-rc2-aotpack-openssl-shim-fix.md` §5。
- **ICU/InvariantGlobalization**：无 ICU 镜像的 AOT demo 需 `InvariantGlobalization`（W10 已入 demo 配方；
  应用侧如遇 hosting 模块初始化 FailFast 可参考）。
- **门禁（本轮已跑）**：交互 540/floor 520（pin 重锚 `moduleRoot`/`webPending`/`renderAttached`）、
  像素 PASS（无 `Known(...)`）、导出 149/149、包内 `verify-kit.sh` 0 FAIL/0 WARN（abc 期望
  339,964（`fc54d2b8…`）/24,324（`798b2477…`））、`ohos-workload` master **`ce4588c`**（#36 三笔）；
  CI/selftests 明细与 run id 以 release 正文为准。
- 本次构建基线 = **rc.2 线**（SDK `.112` / workload `preview.28` / MAUI `rc2.26478.12`）；应用侧构建请同步该线
  （`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5；rc.1 回滚路径保留）。
