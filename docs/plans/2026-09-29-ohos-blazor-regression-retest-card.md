# Blazor 回归复测卡（kit #33）：路径命名空间 + dotnet.js + 双 hap A/B + MAUI 主体

> 对象：kit #32 的 Blazor 组件回归（#33 修复）与 MAUI 主体（TabbedPage）判读；数字以 release「## Integrity（kit #33）」与随包 `SHA256SUMS` 为准；细节 `2026-09-29-ohos-tester-handoff-kit33.md`。

> **构建中已知（16:12 骨架）**：**7 hap** = MAUI 5（新壳 abc **294,976 B / `6cf7dda2…`**）+ Blazor 默认（27,216,958 / `69de2eea…`）与 `-nocsp`（27,216,659 / `c1ef7e06…`）；bundle/preview.28 **77,689,347 B / `155960f4…`**；tar/树/sidecar 以 release 为准。

## 1. kit #32 现象 / 根因 / 修复证据

- 现象：#32 的 `hello-blazorwasm-host-unsigned.hap`（重签安装）启动后宿主对全部资源 404，首屏不渲染；另（#31 起）缺 `_framework/dotnet.js` → `BLZ_ERROR Failed to fetch dynamically imported module`。
- 根因 A（路径命名空间，FIX-BLZ-PATH）：SEC-FIX（`da4eaf2`）把 `resolveRawfilePath` 的返回值改成边界拼写 `resources/rawfile/blazor/<x>` 后交给 `ResourceManager.getRawFileContentSync`；该 API 只接受 rawfile 相对名 `blazor/<x>`（#31 旧拼写、设备已验证），故每次读取抛异常、全部 404。
- 根因 B（dotnet.js，FIX-BLZ-JS）：站点静态资产指纹化后稳定名 `_framework/dotnet.js` 不存在；ArkTS 宿主按 rawfile 1:1 直供、无路由表。
- 修复：A = 安全校验仍以 `resources/rawfile/blazor/` 为边界，返回值恢复 `blazor/<x>`（`INDEX_FILE='blazor/index.html'`；br/gz 同理）；B = 打包时按 `*.staticwebassets.endpoints.json` 物化 `dotnet.js`/`dotnet.native.js`/`dotnet.runtime.js`（与指纹版逐字节一致）。
- 修复证据（离线）：`rawfile-path.test.mjs` 43 checks 全绿（新增「返回值必须以 `blazor/` 开头、绝不包含 `resources/rawfile/`」断言）；`verify-kit.sh` 2c 断言 dotnet.js（selftest 108；旧 #31/#32 包 FAIL 属预期）；两变体重建 26 MB / 213 站点文件、abc 含 `blazor/`（no-csp 版无 CSP 字符串）；本机对照 sha256：默认 `69de2eea…`、nocsp `c1ef7e06…`（重编后必变，以包内为准）。

## 2. A/B 操作（默认 vs nocsp，各装一次，记录 BLZ 标记）

1. 解出两个变体（默认 `hello-blazorwasm-host-unsigned.hap` 与包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`），按《自签说明》Blazor 条目分别重签（bundle 必须 `com.example.opendotnet`）。
2. 装默认件 → `sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe` → 记录 `BLZ_BOOT`/`BLZ_RENDERED`（宿主 pid + `[blz:<nonce>]`）/`BLZ_ERROR`；人工首屏 + `/counter` +1 + 截图。
3. 卸载 → 装 `-nocsp` 件 → 同一命令 → 同上记录。
4. 判读：默认 ✅ → 修复成立、CSP 非瓶颈；默认 ❌ 而 nocsp ✅ → CSP 至少是次因；两者 ❌ → 按失败回传（`blazor-hilog.txt` + 截图 + 两 hap sha256）。

## 3. MAUI 主体判读（FIX-TABBED / AOT v2 回退）

- 装 kit #33 默认 MAUI hap（重签；新壳 abc **294,976 B / `6cf7dda2…`**）→ FlyoutPage → TabbedPage：期望**双页签内容出画**（修复前只画 tab 栏、主体黑屏），切页正常；异常时回传截图 + hilog。
- JIT 路线若启动/主体仍崩（`SEGV_ACCERR`）：重签安装 `aot-haps-v2.tar.gz` 内未签 hap（asset 596991567 / `265e014f…`；会顶替 kit 主包）→ 启动 → `start_app: aot=1` → 判「主体渲染」。
- 无障碍：加 `--a11y-probe` 确认影子树含当前页且切页跟随（A11Y-TABBED）；无 hdc/不能重签时自动项登记「未测」、人工项照做。
