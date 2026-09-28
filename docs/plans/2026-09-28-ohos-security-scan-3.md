# runtime-ohos 新攻击面安全复查 #3（SEC-SCAN-3，2026-09-28）

**范围：** runtime-ohos + maui-ohos + ohos-workload（scan-2 后 5 波 kit #22–#31 的新面）；sdk-ohos/aspnetcore-ohos 本窗口无安全代码变更。
**约束：** 扫描窗口 WebView/ArkWeb 源码与模板（maui-ohos 两个 WebView handler、ohos-workload `packs/**/templates/ets/pages/Index.ets` 与 `test/hello-blazorwasm/arkts-host/**`）只审不改（并发代理在接线），本报告给出修复建议与 patch 草图；SEC-FIX 轮在并发接线完成后解除该约束（仅 `arkts-host` 宿主落地，maui WebView handler 与 packs 模板仍未动）。
**性质：** 只读静态审阅 + 离线复现（harness/独立驱动）+ 非 WebView 区最小修复；设备可见结论一律标「设备未验证」。

## Verdict

**PASS WITH FINDINGS（原 6 缺陷已修 + 1 加固 / 6 条报告未修；SEC-FIX 轮再落地 3 修 + 2 加固，余 1 条信息性残余）。** 六个新面逐项结论见下表；原修复集中在深链、HUKS 回退与 probe 解析三面，均为崩溃/注入/竞态类小改，无协议变更；SEC-FIX 轮（同日晚）把 ArkWeb 直供校验 + 安全头、探针标记 pid+nonce 防伪与深链 `..` 段拒绝落成代码与测试（§SEC-FIX）。验证（SEC-FIX 轮）：交互 harness **398 检查 / floor 378**（编译本机 slice 源码）；tester-run selftest **643 项**（S21/S21b/S21c 新增 15 项）；verify-kit selftest **102 项**（S0b/S15 新增）；ArkWeb 宿主 node 单测 **28 项** + `CompileArkTS` 通过；真实 kit #31 复跑 verify-kit → 权限记录 + 1 条 WARN，`KIT OK`。

| 指标 | 数值 |
|---|---|
| 复查面 | 6（深链 / ArkWeb rawfile / HUKS 回退 / 图片 / probe 解析 / 权限） |
| 候选 | 13（中 2 · 低 7 · 加固 1 · 信息 3） |
| 已修 | 原轮 7（深链 2 + HUKS 4 含加固 + probe 1） + 3 回归 pin；SEC-FIX 轮 +3（S3-AW1/AW2 宿主、S3-DL3 深链） |
| 已加固 | 原轮 1（HUKS 0600）；SEC-FIX 轮 +2（S3-PRB2 标记 pid+nonce、S3-PRM1 权限一致性记录） |
| 报告未修 | 1（S3-IMG1 图片残余；S3-PRB2 的「页面回显 nonce」版随下轮站点资产，见 §SEC-FIX） |
| 设备验证 | 无（设备安装受策略限制） |

## 汇总表

| 编号 | 面 | 严重度 | 标题 | 可利用性 | 状态 |
|---|---|---|---|---|---|
| S3-DL1 | 深链 | 低 | want uri 经 JSON 还原裸换行 → dotnet-status.txt 行注入 | 任意应用可发 want；伪造诊断行 | 已修 `7c75b88f (maui-ohos tip)` |
| S3-DL2 | 深链 | 低 | `AllowedHttpsHosts` 暴露可变 List，与激活泵枚举竞态 | 应用自扩列表 + 并发激活 → 泵中断 | 已修 `7c75b88f (maui-ohos tip)` |
| S3-HK1 | HUKS | 中 | 空/截断 `.key` 文件 → `SetAsync` 抛 `DivideByZeroException` | 首写掉电截断后每次 Set 崩溃 | 已修 `7c75b88f (maui-ohos tip)` |
| S3-HK2 | HUKS | 低 | 并发 Set 丢更新（Load/Save 读改写无同步） | 同进程并发调用 | 已修 `7c75b88f (maui-ohos tip)` |
| S3-HK3 | HUKS | 低 | shell sink 坏 base64 → `FormatException` 逸出存储 API | 旧/第三方壳返回值 | 已修 `7c75b88f (maui-ohos tip)` |
| S3-HK4 | HUKS | 加固 | `.key`/`secure.dat` 权限依赖 umask | 沙箱外防御纵深 | 已加固（0600，本机实测） |
| S3-PRB1 | probe | 低 | `BLZ_ERROR` 行原样回显 → 测试端终端转义注入 | 页面 console 文本可控 | 已修 `6347bb0` |
| S3-PRB2 | probe | 低 | `BLZ_*` 标记可被任意页面/进程伪造 | 测试完整性，非运行时 | 已加固 `ohos-workload a083e65`（probe pid+nonce；页面回显版见 §SEC-FIX） |
| S3-AW1 | ArkWeb | 中 | rawfile 直供未做路径段校验（`..`/`\`/NUL） | 依赖浏览器/资源管理器语义（设备） | 已修 `ohos-workload da4eaf2`（宿主源码；包内 hap 修复前，随下一 kit） |
| S3-AW2 | ArkWeb | 低 | 压缩响应无 `Vary`/`nosniff`/CSP | 缓存与内容类型策略 | 已修 `ohos-workload da4eaf2`（同上） |
| S3-IMG1 | 图片 | 信息 | 4096 钳制/溢出/缓存键审查无缺陷；解码峰值内存 | 平台解码器行为 | 未修（残余） |
| S3-PRM1 | 权限 | 信息 | kit #31 Blazor hap 声明 INTERNET（源码已移除） | 合规一致性 | 已加固 `ohos-workload a083e65`（记录+WARN；包内 hap 仍 INTERNET） |
| S3-DL3 | 深链 | 信息 | `app://../x` → route `//../x`（Shell 段名，无文件语义） | 本应用 Shell 内解析 | 已修 `maui-ohos 33b0af79`（拒绝 `..` 段并落状态） |

## 逐条证据与修复

### 已修（非 WebView 区）

- **S3-DL1（低）。** `want.uri` 由任意应用可控；shell `JSON.stringify` → 托管 JSON 解码把 `\n` 还原为裸换行，`Flatten` 只截断 512 不替换控制字符 → 注入 `dotnet-status.txt` 行（可伪造 `[maui] deep link applied` 类证据）。复现（`sec3/uri` 独立驱动）：`decoded contains raw newline: True`，旧 `Flatten` 2 行 / 新 1 行。修复：控制字符（含 U+2028/2029）替换为空格、代理对不劈开（`maui-ohos OpenHarmonyAppLinks.cs:450-466`）；合法 URI 行为不变。
- **S3-DL2（低）。** 公共 `AllowedHttpsHosts` 直接暴露 `List<string>`：应用 `Add` 与激活泵 `IsHttpsHostAllowed` 枚举并发 → `Collection was modified` 从 fire-and-forget 泵逸出（激活停止直到下一次 ready）。修复：`SynchronizedHostList : Collection<string>`，全部变更走 `s_sync`，种子去重大小写不敏感（`:135,411,475`）；公共 API 形状不变（`PublicAPI.Unshipped.txt:110` 仍为 `IList<string>`）。
- **S3-HK1（中）。** 构造函数接受任意长度的已存在 `.key`；空文件在 `Encode` 的 `_key[i % _key.Length]` 抛 `DivideByZeroException` 出 `SetAsync`（非原子首写被截断后持久化）。复现：独立驱动逐行执行旧逻辑 → `old Encode throws: DivideByZeroException`。修复：`LoadOrCreateFileKey` 校验 32 字节、坏键重建、读失败不抛（`OpenHarmonySecureStorage.cs:42-69`）。
- **S3-HK2（低）。** `Load`/`Save` 读改写无同步：并发 Set 基于同一快照、后保存丢前值。修复：`_fileSync` 串行化 load-modify-save，keystore 等待在锁外（无 sync-over-async 死锁）。
- **S3-HK3（低）。** `Encrypt/DecryptAsync` 对 `rc=0` 的坏 base64 直接 `Convert.FromBase64String` → `FormatException` 逸出存储 API，违反 "wrapper never throws"。修复：`DecodeBase64` 捕获 `FormatException` 返回 null（`OpenHarmonyKeystore.cs:43-57`）。
- **S3-HK4（加固）。** `.key`/`secure.dat` 写入后强制 0600（`EnsureOwnerOnlyFile`）；本机实测 `-rw-------`（`sec3` harness 产物）。`RemoveAll` 仍只删 HUKS 键、保留文件键（与「清空后无可用键」的注释有差，列残余）。
- **S3-PRB1（低）。** v13 `blazor_probe` 把 hilog 的 `BLZ_ERROR` 行原样 `warn`：页面 console 可带 ESC/CR → 终端转义注入。修复：`tr -d '[:cntrl:]'` + `cut -c1-400`（`tester-run.sh:2166-2167`）；负例见 S21b。
- **回归 pin。** harness 新增 sec3 行为断言：空键恢复（`emptyKey=value shortKey32=True`）、4 写者 × 25 键 `kept=100/100`、allow-list/Flatten/DecodeBase64 源钉；`selftest-tester-run.sh` S21b 注入含 ESC 的 `BLZ_ERROR` 行并断言日志无 ESC（`e3f9aaf`）。

### SEC-FIX（2026-09-28 晚：scan-3 报告项的本机落地）

扫描窗口的「WebView/ArkWeb 只审不改」约束在并发接线完成后解除；本轮只改 `arkts-host` 宿主与工具脚本，maui 侧只动深链解析一个分支；不构建/重发 kit。

- **S3-AW1（中，已修 `da4eaf2`）。** `Index.ets` 新增 `resolveRawfilePath`：请求 path 先按有界轮次 `decodeURIComponent`（`%2e%2e`、`%252e%252e`、`%5c`、`%00`、`%2f` 绝对路径等编码变体都在解码文本上判定），拒绝 `..` 段、反斜杠、NUL、首字符 `/` 与无法解码的 `%XX`；`.` 与空段按规范化丢弃；最终路径必须仍在 `resources/rawfile/blazor/` 前缀内（并复查 `/../`）。违规返回裸 404，不回显原因；合法请求行为不变（含 SPA fallback）。**证据**：`test/rawfile-path.test.mjs` 把校验块从宿主源码逐字提取（node 类型剥离，不重写实现）跑 **28 检查全过**（12 恶意 + 9 合法 + 7 源码 pin，`sh test/hello-blazorwasm/arkts-host/test/run-tests.sh`）；`pack-host.sh --slim --unsigned-only` 两次（含 nonce 改动）均 `Finished :entry:default@CompileArkTS`。
- **S3-AW2（低，已修 `da4eaf2`）。** 成功响应统一带 `X-Content-Type-Options: nosniff`、`Vary: Accept-Encoding`、`Cache-Control: no-cache`；`.html` 额外带最小 CSP（`default-src 'self'; script-src 'self' 'wasm-unsafe-eval' 'unsafe-inline'; style/img/font/connect 同源；object-src 'none'; frame-ancestors 'none'; base-uri 'self'`）。`wasm-unsafe-eval` 是 .NET WASM 启动所需，`'unsafe-inline'` 是站点自带内联标记脚本所需（不引入 `unsafe-eval`）。**证据**：node 单测 7 条源码 pin；响应头在 ArkWeb 的真机透传随下一 kit 轮（见「未覆盖」）。
- **S3-PRB2（低，已加固 `a083e65`）。** 宿主新增按启动随机 `session nonce`（`util.generateRandomUUID`）：页面 URL 携带 `?blz_nonce=<n>`、`onPageBegin` 先向 hilog 公告 `session nonce:`、`onConsole` 把每条转发标记写成 `marker: BLZ_* [blz:<n>]`。`tester-run.sh --blazor-probe` 只接受满足三者的行：hilog pid 字段 == `pidof <bundle>` 的宿主 pid、宿主格式 `BlazorWebHost: marker: BLZ_*`、带公告的 nonce——另一进程向 hilog 写 `BLZ_BOOT`（即便复用旧 nonce）都无法让探针通过；旧宿主（无 nonce）降级为 pid+格式过滤并记录 WARN。**证据**：`selftest-tester-run.sh` S21（`blazor_marker_pid=4242`、`blazor_session_nonce=present`）、S21b（外来 pid 携正确 nonce / 宿主 pid 携错误 nonce 都判 no，exit 1）、S21c（pidof 缺失时格式+nonce 仍过，记录 `blazor_marker_pid=unknown`）。**残余**：nonce 由宿主盖章而非页面回显——页面回显版需要改站点资产（`wwwroot/index.html` / `Pages/Home.razor`）并重发 kit hap，留待下一轮站点刷新；届时探针判读无需再改（判据已带 nonce）。
- **S3-PRM1（信息，已加固 `a083e65`）。** `verify-kit.sh` 2c 记录 Blazor hap 的 `requestPermissions` 集合并与源侧期望对比（`BLAZOR_SOURCE_PERMS` 默认空 = `2dcd846` 后的 module.json5；`--blazor-perms`/`KIT_BLAZOR_PERMS` 可覆盖）：不一致为 **WARN 不 FAIL**，历史 kit 不被误杀。**证据**：对真实 kit #31（包内 hap 确实声明 INTERNET）复跑新 `verify-kit.sh` → `权限 requestPermissions=1 [INTERNET]` + 源侧不一致 WARN + `KIT OK（1 条 WARN）`；`selftest-verify-kit.sh` **102 项**，新增 S0b（把嵌入期望钉在源 `module.json5` 上）与 S15（INTERNET 记录/WARN、`--blazor-perms` 覆盖后零 WARN）。
- **S3-DL3（信息，已修 `maui-ohos 33b0af79`）。** `TryBuildRoute` 对 app://（host+path 拼出的段）与 https 白名单路径都拒绝字面 `..` 段，走既有 `[maui] deep link ignored: ...` 状态行（不抛）。**证据**：交互 harness **398 检查 / floor 378 全过**（含 p2c 深链行为段）；新分支未单独加断言——harness `Program.cs` 属并发窗口，改动限于 slice 源码。
- **包内 delta（重要）。** kit #31 内的 `hello-blazorwasm-host-unsigned.hap` 是**修复前**构建：无路径校验/安全头/nonce，且仍声明 INTERNET。本轮**不重新构建 kit**；宿主与脚本改动随下一次 `make-device-test-kit.sh --with-blazor` 出货（kit #32）。对旧包：探针降级为 pid+格式过滤并记录 WARN，`verify-kit` 只记录+WARN，因此已发 kit 仍可照常判读，无需先更新。

### 报告（原始建议；条目状态见前缀与 §SEC-FIX）

- **S3-AW1（中，报告）→ 已修（`da4eaf2`）。** `serveFile` 把 `getRequestUrl()` 的 path 直接拼 `ROOT + path` 交 `getRawFileContentSync`（`arkts-host/.../Index.ets:98-104,154-170`），未拒绝 `..`/`\`/NUL；`startsWith(ORIGIN)` 前缀检查本身安全（尾 `/` 使 `blazor.local.evil`、`user@` 变体拒绝）。浏览器 URL 规范化通常先消 `..`/`%2e%2e`/`\`，但直供回调与 `resourceManager` 对 `..` 的语义仅设备可验（scan-2 MB-3 同类残留）。patch 草图：`const segs = path.split('/'); if (path.includes('\\') || path.includes('\0') || segs.some(s => s === '..' || s === '.')) return this.errorResponse(400);`（插在 `serveFile` 取到 path 后）。
- **S3-AW2（低，报告）→ 已修（`da4eaf2`）。** 响应无 `Vary: Accept-Encoding`（br/gzip 两种表示同 URL）、无 `X-Content-Type-Options: nosniff`、index.html 无 CSP；`mimeTypeOf` 仅按扩展名。建议按静态服务器补齐。
- **S3-PRB2（低，报告）→ 已加固（`a083e65`）；nonce 页面回显版待站点资产。** `.onConsole` 只按前缀放行 `BLZ_*`（`:227-236`）：任意页面或设备上其他进程可打 `BLZ_BOOT`/`BLZ_RENDERED` 伪造探针结果。建议宿主用启动 nonce 前缀、probe 侧按 pid 过滤 hilog。
- **S3-PRM1（信息，报告+建议）→ 已加固（`a083e65`）。** kit #31 包内 Blazor hap 声明 `ohos.permission.INTERNET`（dev-only，rawfile 直供），源码已由 ohos-workload `2dcd846` 移除、runtime 文档 `5026610eddc` 已按已发产物表述；建议下一 kit 在 `verify-kit.sh` 2c 增加 `requestPermissions` 断言（当前只打印不校验），避免包/文档再漂移。
- **S3-DL3（信息）→ 已修（`maui-ohos 33b0af79`）。** `app://../x` 的 `Uri.Host='..'` → route `//../x`；Shell 段名解析无文件/越权语义（与文件路径无关），记录不修。

### 无缺陷结论（含残余）

- **深链解析/白名单/长度**：独立驱动矩阵（`sec3/uri`）——host 带 `%2f`/`%41`/空格 → `Uri` 拒绝；IDN 大小写、端口、userinfo、尾点、`//` 变体均 fail-closed；`%2e%2e` 被 `Uri` 归一、`..%2f` 保持编码（不穿越文件系统）；100k URI `TryCreate=False`。序号去重/顺序/PendingLimit 由 harness P2c 断言；注册窗口内「新序先到、旧序被去重」= 最新意图胜出（已记录）。
- **HUKS 主机面**（`host_keystore.c`）：截断密文 `<nonce+tag` 拒绝；GCM tag 校验失败即 null；错误分支只记 rc，无密钥/明文进日志；别名 `maui.ohos.securestorage.v1.<FNV-1a path>` 应用内 64 位稳定哈希（非对抗场景，碰撞不实际）；并发 session 由 HUKS 保证；失败回退文件键有一次性状态提示（弱化可见）。
- **图片**：host 每边 `>4096` 钳制（`openharmony_host.c:4351-4356`），desiredSize 只在两正时设置、失败回退全尺寸；managed float→int 饱和 + `Math.Max(1,..)` 无溢出；缓存键 = 64 位内容哈希 + 长度 + 请求尺寸，按像素字节预算 LRU（32 MiB）。残余 = 解码峰值内存取决于平台解码器对 DesiredSize 的实现（设备未验证）。
- **probe/解析**：bundleName 三来源（kit/`--blazor-bundle`/env）都先过 `require_safe_bundle_name`（v13 新增 `$BLAZOR_BUNDLE`）；`--blazor-hap` 引号化；hilog 落盘固定 `$OUT/blazor/`。

## 验证与命令（只读/离线；scratch `/data/storage/el2/base/tmp/opencode/sec3/`）

```sh
# 深链/URI 矩阵与旧 Flatten 注入复现（独立驱动；new=1 行）
dotnet run --project sec3/uri/probe.csproj
# 交互 harness（编译本机 slice 源码；扫描窗口合并树 398 检查 / floor 376，SEC3 新增 2 行）
cd ohos-workload/test/maui-platform-verify
MAUI_SLICE_DIR=.../maui-ohos/src/Core/src/Platform/OpenHarmony \
  dotnet build -c Release --no-restore -m:1 -nodeReuse:false && dotnet bin/Release/net11.0/verify.dll
#   SEC-FIX 轮复跑（含 S3-DL3 的 slice 改动）：398/398，floor 378，assert=True。
# tester-run 负例（S21/S21b，stub 设备）与 verify-kit 自测
SELFTEST_SKIP_A11Y=1 sh ohos-workload/scripts/selftest-tester-run.sh
#   扫描窗口结果：628 检查 / 1 失败；唯一失败是「repo working tree unchanged」（并发 WebView
#   代理在同一 checkout 重建 packs，前后快照不同），S21b 的清洗断言全过。
#   SEC-FIX 轮：643 检查 / 1 失败，失败同为上述快照类（selftest 运行期间本轮在另一路径提交了
#   宿主改动，前后两份 git status 不同）；S21/S21b/S21c 的 pid+nonce 断言全部通过。
sh ohos-workload/scripts/selftest-verify-kit.sh
#   SEC-FIX 轮：102 项全过（新增 S0b 源侧权限期望 pin、S15 INTERNET 记录/WARN/覆盖）。

# SEC-FIX：宿主 rawfile 校验的 node 单测（提取 Index.ets 的 rawfile-path 块，node 类型剥离）
sh ohos-workload/test/hello-blazorwasm/arkts-host/test/run-tests.sh          # 28 检查全过
# ArkTS 编译门（含路径校验/安全头/nonce）：Finished :entry:default@CompileArkTS
sh ohos-workload/test/hello-blazorwasm/arkts-host/pack-host.sh <site> --slim --unsigned-only
# 真实 kit #31（包内 hap 为修复前构建）：权限记录 + 1 条源侧不一致 WARN，KIT OK
sh ohos-workload/scripts/verify-kit.sh /data/storage/el2/base/tmp/opencode/device-test-kit
```

**未覆盖/不确定：** ArkWeb 直供的 `resourceManager` `..` 语义与 URL 规范化端到端（设备）；解码峰值内存；`.onConsole` 标记来源（设备）；HUKS 真机（引擎在 kit #29 设备探针已验证，本轮改动未上机）；`AllowedHttpsHosts` 竞态为结构 pin（不做 flaky 时序测试）。
**SEC-FIX 追加：** 路径校验/安全头/pid+nonce 绑定都只在本机离线验证（node 单测 + stub selftest + `CompileArkTS`）；ArkWeb 真机行为（响应头透传、`pidof` 多进程语义、`resourceManager` 对已解码路径的查找）随下一 kit 轮；nonce 的「页面回显版」（需改站点资产）未做；kit #31 包内 hap 仍是修复前构建。

## 方法注

单代理复查：按 scan-2 的 6 面清单在新波次提交 diff 中定位（P2c/P2a/P2b/v13/Blazor host/权限），逐面读实现 + 离线复现（URI/JSON 驱动、旧逻辑逐行驱动、harness 行为 pin、tester selftest 负例），非 WebView 区小改后跑 harness + selftest 回归；WebView/ArkWeb 区按约束只出报告与 patch 草图。
SEC-FIX 轮（同日晚）单代理落地本机可做项：宿主 rawfile 校验 + 安全头 + nonce、probe pid+nonce 绑定、verify-kit 权限一致性、深链 `..` 拒绝；kit 内 hap 不重建，包内 delta 已注明（见 §SEC-FIX）。
