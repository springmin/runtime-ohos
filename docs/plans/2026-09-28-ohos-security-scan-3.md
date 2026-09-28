# runtime-ohos 新攻击面安全复查 #3（SEC-SCAN-3，2026-09-28）

**范围：** runtime-ohos + maui-ohos + ohos-workload（scan-2 后 5 波 kit #22–#31 的新面）；sdk-ohos/aspnetcore-ohos 本窗口无安全代码变更。
**约束：** WebView/ArkWeb 源码与模板（maui-ohos 两个 WebView handler、ohos-workload `packs/**/templates/ets/pages/Index.ets` 与 `test/hello-blazorwasm/arkts-host/**`）只审不改（并发代理在接线），本报告给出修复建议与 patch 草图。
**性质：** 只读静态审阅 + 离线复现（harness/独立驱动）+ 非 WebView 区最小修复；设备可见结论一律标「设备未验证」。

## Verdict

**PASS WITH FINDINGS（6 处已修 / 5 条报告未修）。** 六个新面逐项结论见下表；修复集中在深链、HUKS 回退与 probe 解析三面，均为崩溃/注入/竞态类小改，无协议变更。验证：交互 harness **398 检查 / floor 376**（新增 sec3 行为断言，编译本机 slice 源码）；`selftest-tester-run.sh` 新增 S21b 控制字符负例；`selftest-verify-kit.sh` 92 项。

| 指标 | 数值 |
|---|---|
| 复查面 | 6（深链 / ArkWeb rawfile / HUKS 回退 / 图片 / probe 解析 / 权限） |
| 候选 | 12（中 2 · 低 8 · 信息 2） |
| 已修 | 6（深链 2 + HUKS 3 + probe 1） + 3 回归 pin |
| 报告未修 | 6（WebView 区 3 + probe 完整性 1 + 权限 1 + 深链 route 信息 1） |
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
| S3-PRB2 | probe | 低 | `BLZ_*` 标记可被任意页面/进程伪造 | 测试完整性，非运行时 | 未修（建议） |
| S3-AW1 | ArkWeb | 中 | rawfile 直供未做路径段校验（`..`/`\`/NUL） | 依赖浏览器/资源管理器语义（设备） | 未修（报告） |
| S3-AW2 | ArkWeb | 低 | 压缩响应无 `Vary`/`nosniff`/CSP | 缓存与内容类型策略 | 未修（报告） |
| S3-IMG1 | 图片 | 信息 | 4096 钳制/溢出/缓存键审查无缺陷；解码峰值内存 | 平台解码器行为 | 未修（残余） |
| S3-PRM1 | 权限 | 信息 | kit #31 Blazor hap 声明 INTERNET（源码已移除） | 合规一致性 | 未修（报告+建议） |
| S3-DL3 | 深链 | 信息 | `app://../x` → route `//../x`（Shell 段名，无文件语义） | 本应用 Shell 内解析 | 未修（记录） |

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

### 报告（未修）

- **S3-AW1（中，报告）。** `serveFile` 把 `getRequestUrl()` 的 path 直接拼 `ROOT + path` 交 `getRawFileContentSync`（`arkts-host/.../Index.ets:98-104,154-170`），未拒绝 `..`/`\`/NUL；`startsWith(ORIGIN)` 前缀检查本身安全（尾 `/` 使 `blazor.local.evil`、`user@` 变体拒绝）。浏览器 URL 规范化通常先消 `..`/`%2e%2e`/`\`，但直供回调与 `resourceManager` 对 `..` 的语义仅设备可验（scan-2 MB-3 同类残留）。patch 草图：`const segs = path.split('/'); if (path.includes('\\') || path.includes('\0') || segs.some(s => s === '..' || s === '.')) return this.errorResponse(400);`（插在 `serveFile` 取到 path 后）。
- **S3-AW2（低，报告）。** 响应无 `Vary: Accept-Encoding`（br/gzip 两种表示同 URL）、无 `X-Content-Type-Options: nosniff`、index.html 无 CSP；`mimeTypeOf` 仅按扩展名。建议按静态服务器补齐。
- **S3-PRB2（低，报告）。** `.onConsole` 只按前缀放行 `BLZ_*`（`:227-236`）：任意页面或设备上其他进程可打 `BLZ_BOOT`/`BLZ_RENDERED` 伪造探针结果。建议宿主用启动 nonce 前缀、probe 侧按 pid 过滤 hilog。
- **S3-PRM1（信息，报告+建议）。** kit #31 包内 Blazor hap 声明 `ohos.permission.INTERNET`（dev-only，rawfile 直供），源码已由 ohos-workload `2dcd846` 移除、runtime 文档 `5026610eddc` 已按已发产物表述；建议下一 kit 在 `verify-kit.sh` 2c 增加 `requestPermissions` 断言（当前只打印不校验），避免包/文档再漂移。
- **S3-DL3（信息）。** `app://../x` 的 `Uri.Host='..'` → route `//../x`；Shell 段名解析无文件/越权语义（与文件路径无关），记录不修。

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
# tester-run 负例（S21/S21b，stub 设备）与 verify-kit 自测
SELFTEST_SKIP_A11Y=1 sh ohos-workload/scripts/selftest-tester-run.sh
#   结果：628 检查 / 1 失败；唯一失败是「repo working tree unchanged」（并发 WebView
#   代理在同一 checkout 重建 packs，前后快照不同），S21b 的清洗断言全过。
sh ohos-workload/scripts/selftest-verify-kit.sh
```

**未覆盖/不确定：** ArkWeb 直供的 `resourceManager` `..` 语义与 URL 规范化端到端（设备）；解码峰值内存；`.onConsole` 标记来源（设备）；HUKS 真机（引擎在 kit #29 设备探针已验证，本轮改动未上机）；`AllowedHttpsHosts` 竞态为结构 pin（不做 flaky 时序测试）。

## 方法注

单代理复查：按 scan-2 的 6 面清单在新波次提交 diff 中定位（P2c/P2a/P2b/v13/Blazor host/权限），逐面读实现 + 离线复现（URI/JSON 驱动、旧逻辑逐行驱动、harness 行为 pin、tester selftest 负例），非 WebView 区小改后跑 harness + selftest 回归；WebView/ArkWeb 区按约束只出报告与 patch 草图。
