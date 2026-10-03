# AGC ACL 申请材料包：跨平台框架内置 CoreCLR VM 的 JIT（ACL-PACK，2026-10-03）

> 目的：把 WX-TOKENS / WX-PROBE / WX-HOST-PRCTL / DECIDE-BASELINE 的结论固化为 AGC 可提交材料（申请正文 / 技术附件 / App Linking 登记 / 提交顺序）。
> 输入：`2026-10-03-ohos-jit-acl-prerec.md`（权限语义与 AGC 路径）、`2026-09-28-ohos-agc-store-readiness.md`（上架清单与 App Linking）、`2026-10-03-ohos-three-path-baseline.md`（基线数字）、`2026-10-03-ohos-m-web-mirror.md`（`skills[].uris` 实现）。
> 边界：不做控制台登录/越权，仅产出本机材料；字段名与审核口径以 AGC 控制台为准。完整草稿（未入库）：scratch `/data/storage/el2/base/tmp/opencode/acl-pack/`。

## 1. ACL 申请正文（AGC「申请原因」≤256 字符）

- **中文**（198 字符；权限 = `ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`，场景 = 应用/跨平台框架内置 VM）：
  > 跨平台框架内置 CoreCLR 托管 VM 申请 ALLOW_WRITABLE_CODE_MEMORY：JIT 编译是性能必需（AOT 兜底保基本可用）。程序集随签名包分发、非热更新，不下载或加载未签名代码；运行时保持 W^X。系统 JS 引擎的 JIT 豁免仅覆盖系统引擎及其 JITFort 接口，不覆盖自带可执行分配器的第三方托管 VM。目标平台 PC/2in1/平板，先用于调试/内测域。
- **English**（248 字符）：
  > Cross-platform framework's CoreCLR VM needs ALLOW_WRITABLE_CODE_MEMORY: JIT for performance (AOT fallback). Code ships signed; no hot updates/unsigned code; W^X kept. JS-engine JIT exemption excludes third-party managed VMs. Target: PC/2in1/tablet.

## 2. 技术附件要点（1–2 页；提交稿见 `2026-10-03-ohos-agc-acl-technical-attachment.md`）

| 节 | 要点 |
|---|---|
| 三路径基线（同一 2in1/API26/debug 域，各 3 轮） | 冷启动 payload→canvas ≈3.16/3.22/3.17 s（AOT/JIT/interp）三路径同档；帧节奏 ≈17.6 fps、40 s ≈700 帧；VmRSS AOT 233–260 MB、JIT 324–333 MB、interp 328–339 MB（JIT/interp +≈75 MB 属引擎/预热）；31 min 长跑 0 崩/0 失 pid，JIT RSS 342→244 MB 回落（无泄漏） |
| 引擎证据 | JIT = libclrjit 2,720 KiB + libcoreclr 4,816 KiB；interp = libclrinterpreter 268 KiB；AOT = libhello-maui-app 18,372 KiB（无 libclr*） |
| 合规 A/B（fortify 跨 app） | 默认 fortify：anon exec 全拒（EINVAL 22）；`prctl(0x6a6974,0,1)` → 下一 app 探针 `1=22` + CoreLib `0x800701E7`；`(0,0)` → 下一 app `1=OK 2=OK`。状态非调用者隔离且跨 app 生效；NDK 无定义（隐藏接口）→ 不作为分发路径，ACL 为合规路径；坚盾模式全局禁 JIT（已授权亦然）→ AOT 兜底 |
| 官方路径 | 受限权限表：`ALLOW_WRITABLE_CODE_MEMORY` = 应用/跨平台框架内置 VM（CEF/Electron 先例；API14+，PC/2in1/Tablet，system_basic/system_grant）；AGC「项目设置 → ACL 权限」申请+审核；`os_integration` 预置本身不解锁 |
| 期望用途 | 先 debug/内测域（试用调试 Profile 5 天）验证；获批后更新 Profile/重签再进 release；无 ACL/坚盾/手机域保持 AOT |

## 3. App Linking 登记材料（完整版 `acl-pack/applinking-pack.md`）

1. **域名清单**：只登记自有精确 host（无路径/通配），本次候选待填（合成 PASS 例 = `www.example.com`）；`app://` 自定义 scheme 无需域名校验；https host 必须同时进打包 `OpenHarmonyAppLinkHosts`。
2. **`skills[].uris`（已实现）**：构建 `-p:OpenHarmonyAppLinkHosts="host1;host2"` → `OpenHarmonyGenerateModuleJson` 生成第二 skill：`{"entities":["entity.system.browsable"],"actions":["ohos.want.action.viewData"],"uris":[{"scheme":"https","host":"host1"},{"scheme":"https","host":"host2"},{"scheme":"app","host":"<app-host>"}],"domainVerify":true}`（home skill 保留、非法 host fail、未设字节不变）；`app.json` `linkHosts` 与 uris 同源由打包保证。
3. **domainVerify 文件**：部署 `https://<host>/.well-known/applinking.json` = `{"applinking":{"apps":[{"appIdentifier":"<AGC APP ID>"}]}}`（直链 GET、无重定向/鉴权）；AGC「增长 > App Linking」发布精确域名后平台校验。校验器：`check-applink-declaration.sh <hap>`（含可选 `bm dump` 设备侧）。

## 4. 提交清单（做什么/给谁/顺序；完整版 `acl-pack/checklist.md`）

1. **账号/应用（账号主体）**：实名认证 → AGC 项目+应用注册（设备类型只勾 PC/2in1/Tablet；已上架手机者拆包+备注）→ 添加签名证书 SHA256 指纹。
2. **ACL 申请（开发者 → AGC 审核）**：项目设置 → ACL 权限 → 勾 `ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`（单次 ≤30 条）→ 正文（§1）+附件（§2）→ 选使用场景 → 提交。
3. **试用调试 Profile（开发者/测试）**：提交弹窗内建（唯一入口）→ 5 天有效、每应用 ≤5、需调试证书+UDID ≤100 → 签包装机做 debug 域验证；**不可上架**。
4. **获批后（构建）**：权限自动写入 Profile → 更新 Profile → 重签 → release 域归档/上架；App Linking 同步登记域名+部署 domainVerify 文件；版本号/bundleName/隐私标签按 `2026-09-28` §5 自检。
5. **坚盾注意（全部）**：坚盾守护模式全局禁 JIT（含已授权应用，需重启开启）→ 保留 AOT 兜底并两态验收。

## 5. 不确定项

- `ALLOW_WRITABLE_CODE_MEMORY` 对 .NET 托管 VM（非脚本引擎）的批准实例无一手证据；审核结果与入口名以 AGC 为准。
- 基线为单设备 2in1/debug 签名域；release 域、跨重启、坚盾模式、手机域未测。
- App Linking 候选域名与 APP ID 待账号侧确定；https 投递只对 AGC 登记证书的包生效。

## 参考 / 提交

- 华为《受限开放权限》《申请受限权限》《管理 ACL 权限（AGC）》《JSVM-API 申请 JIT 权限/坚盾守护模式》。
- 提交：本文件 + 技术附件（`commit-paths.sh`，`feature/openharmony`，未强推）；完整草稿 scratch `acl-pack/`（未入库）。
