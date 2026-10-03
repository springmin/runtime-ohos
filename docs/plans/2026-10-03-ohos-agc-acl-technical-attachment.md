# 技术附件：跨平台框架内置 CoreCLR VM 的 JIT 权限申请（ACL-PACK 附件草稿，2026-10-03）

> 随 AGC「项目设置 → ACL 权限 → 申请原因（≤256 字符）」提交的技术附件，页面预算 1–2 页。
> 申请权限：`ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`；平台：PC/2in1/Tablet（API 14+）。
> 证据（scratch，未提交）：`decide-baseline/`（三路径基线）、`wx-prctl/`（JITFORT 解锁/回放）、`wx-probe/`（fortify 矩阵）；
> 正文口径见 `2026-10-03-ohos-agc-acl-application-pack.md`，权限语义见 `2026-10-03-ohos-jit-acl-prerec.md`。

## 1. 申请主体与应用场景

- 申请主体 = MAUI/.NET on OpenHarmony 交付件（跨平台框架内置运行时）。
- 场景 = 框架内置 CoreCLR 托管 VM：IL 程序集随签名 HAP 分发，启动后由 VM 的 JIT 编译为本机码执行；AOT 兜底保功能可用。
- 与系统 JS 引擎的区别：系统 JS 引擎的 JIT 豁免（`ALLOW_EXECUTABLE_FORT_MEMORY` / `ALLOW_USE_JITFORT_INTERFACE`）仅覆盖系统引擎及 JITFort 接口；CoreCLR 是第三方托管 VM，使用自有可执行内存分配器，无法复用该豁免，因此申请官方受限权限表中「应用内置 VM / 跨平台框架内置 VM」对应的 `ALLOW_WRITABLE_CODE_MEMORY`。

## 2. JIT 必需性与同设备三路径基线

测量：HAD-W32（MateBook Pro，2in1）/ OpenHarmony 7.0.0.111 / API 26，debug 签名域，同一 harness；每路径 3 轮冷启动 + 31 min 长跑 + 前后台 ×10。

| 路径 | 冷启动 payload→canvas | 帧节奏 | VmRSS（3 轮） | 31 min 长跑 | 引擎证据（smaps） |
|---|---|---|---|---|---|
| AOT（分发默认） | 3.16 s | ~17.7 fps，708 帧/40 s | 233–260 MB | 0 崩、0 失 pid；RSS 平（+19.5 MB 后回落） | libhello-maui-app 18,372 KiB，无 libclr* |
| JIT（本次申请形态） | 3.22 s | ~17.6 fps，705–767 帧/40 s | 324–333 MB | 0 崩、0 失 pid；RSS 342→244 MB 回落 | libclrjit 2,720 + libcoreclr 4,816 KiB |
| 解释器（实验） | 3.17 s | ~17.5 fps，701–759 帧/40 s | 328–339 MB | 0 崩、0 失 pid；RSS 332→281 MB | libclrinterpreter 268 KiB |

- 首帧：r1/r2 冷缓存 ≈3.2 s 三路径同档；r3 全热 ≈0.16–0.5 s。首帧主要由 MAUI 启动与页缓存决定，JIT 未拖慢首帧。
- 帧节奏：三路径同档（5 s 桶 35–236 帧；最大相邻间隔 ~3.0 s = 空闲重绘节拍，非卡顿）。
- JIT 内存增量 ≈+75 MB（相对 AOT）属 JIT 代码/元数据，长跑回落、无泄漏；仅为换取 JIT 性能，且只在获批域启用。
- 本基线在 debug 签名域由宿主解锁后测得；release 域启用前置 = ACL 获批 + Profile 更新 + 重签。

## 3. 合规面 A/B：fortify 状态与跨 app 影响（为何申请 ACL 而非隐藏开关）

- 平台默认（fortify/加固）：应用进程匿名可执行内存全部拒绝（mmap RWX / RW→RX = `EINVAL(22)`），托管 VM 止步 CoreLib 装载。
- 隐藏接口 A/B（仅诊断，不作为分发路径）：`prctl(0x6a6974,0,0)` 解锁后匿名 exec 恢复（OK+exec，`/proc/self/xpm_region` 0→4 GB）；`(0,1)` 加固后**下一应用进程**探针即 `1=22 2=22`、CoreLib 以 `0x800701E7` 失败；反之 `(0,0)` 后下一 app `1=OK 2=OK`。
- 结论：该状态**非调用者隔离且跨 app 生效**，且 NDK 无接口定义（隐藏接口）。以自解锁方式进入 JIT 不符合平台契约，故申请官方 ACL。
- 坚盾守护模式：全局禁 JIT（含已授权应用；需重启开启）。应用保留 AOT 兜底，在其下继续可用。

## 4. 官方路径与安全承诺

- 官方路径：AGC → 开发与服务 → 项目 → 应用 → 项目设置 → ACL 权限（申请制，实名账号；单次 ≤30 条，可选 1 附件 ≤500 MB）；提交弹窗可建试用调试 Profile（5 天有效、每应用 ≤5、调试证书 + UDID ≤100）用于上机验证，**不可上架**。
- 安全承诺：不下载、不加载任何未签名代码；不使用热更新；程序集随签名 HAP 分发（遵循签名链校验）；运行时保持 W^X（`DOTNET_EnableWriteXorExecute`）；无动态代码下载通道。
- 与 `os_integration` 预置的差异：预置/系统签名本身不解锁 JIT，仍需 ACL/厂商豁免写入 profile；本申请不依赖预置。

## 5. 期望用途与范围

- 先 debug/内测域（试用调试 Profile）验证 JIT 形态；获批后更新 Profile、重签，再按发布流程评估 release 域。
- 无 ACL、坚盾模式、手机域：继续 AOT（默认分发形态，帧率与 JIT 同档、内存更低）。
- 申请范围限 PC/2in1/Tablet（手机不开放该权限）。

## 6. 边界与不确定

- 单设备（2in1）、debug 签名域测量；release 域、跨重启、坚盾模式、手机域未测。
- 无 .NET 托管 VM（非脚本引擎）获批一手先例；审核口径以华为为准。
