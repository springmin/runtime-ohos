# JIT ACL 预研 + MAP_JIT 探针（WX-TOKENS，2026-10-03）

> 设备 HAD-W32（MateBook Pro，2in1）/ 7.0.0.111 / API 26 / 127.0.0.1:35111。输入：WX-PROBE 矩阵（`2026-10-03-ohos-wx-probe-matrix.md`）+ WX-RUNTIME 清点 + 华为 AGC/权限文档复核（今日）。证据（scratch，未提交）：`/data/storage/el2/base/tmp/opencode/wx-tokens/`。

## 1. token 8/9 结论（MAP_JIT / JITFort）

- **MAP_JIT 不是解锁通道、也不被 ACL/能力单独门控**：探针 HAP 无任何受限 ACL（debug profile `allowed-acls=[""]`、apl normal）下，`mmap(anon,*,MAP_JIT)` 在非 fortify 态与普通 anon 同效；fortify 态（`prctl(0x6a6974,0,1)` 后）与普通 anon 同拒（mmap RWX `EINVAL(22)`；RW/none→`mprotect(RX)` `EINVAL`），errno 与无 MAP_JIT 一致。
- **MAP_JIT 只对匿名内存有效、且不进 XPM 区**：`anon RWX / RW→RX / PROT_NONE→RW→RX / PROT_NONE→RWX` 均 `OK|exec`（返回地址 `xpm=out`）；`memfd+MAP_JIT` RW mmap=`22`、RX mmap=`EACCES(13)`；签名 .so RX=`22`；`MAP_XPM|MAP_JIT`=`22`；未知 flag 位对照=`22`（说明 flags 有校验，结果可信）。
- **pthread_jit_write_protect(_np) 均不存在**（`dlsym=0`）；JITFort 无第三方 ABI：`/proc/self/xpm_region` 存在（`7ef3e32000-7ff3e32000`），唯一可操作面是 `prctl(0x6a6974,0,0|1)`（WX-PROBE：0=解除 fortify、1=加固；本日 A/B 复现：fortify 收尾的 HAP → 下一 app `1=22`）。
- 合并去重：复验 WX-PROBE 全表的非-JIT 路线（memfd/file/shm/pkey/dlopen/fork/XPM），errno 全部同值；新增 11 条 MAP_JIT 路线（同进程先矩阵后 prctl，避免上次 prctl 影响）。

## 2. 受限权限语义（官方 restricted-permissions）

| 权限（ohos.permission.kernel.） | 语义 | 版本/设备 |
|---|---|---|
| `ALLOW_WRITABLE_CODE_MEMORY` | 可写可执行**匿名内存**；场景=应用内置 VM 或跨平台框架内置 VM（CEF/Electron 先例） | API14+；PC/2in1+Tablet |
| `ALLOW_EXECUTABLE_FORT_MEMORY` | 系统 JS 引擎申请 `MAP_FORT` 匿名可执行内存 | API14+ |
| `ALLOW_USE_JITFORT_INTERFACE` | 应用（自有脚本引擎）调 JITFort 接口更新 `MAP_FORT` | API16+ |
| `DISABLE_CODE_MEMORY_PROTECTION` | 跨平台框架豁免代码运行时完整性保护 | 2in1/平板 |

级别均 system_basic/system_grant。未获 profile 而声明 → 安装失败；**坚盾守护模式全局禁 JIT（含已授权应用，需重启开启）**。

## 3. AGC 申请路径（agc-help-apply-acl / declare-permissions-in-acl）

1. 前置：实名认证个人/企业帐号；AGC 项目+应用；设备类型只勾 PC/2in1/Tablet（已上架手机者拆包+备注）；官方为申请制（社区 2026-04 有 JIT 类 ACL“受邀”反馈，以审核为准）。
2. AGC → 开发与服务 → 项目 → 应用 → **项目设置 → ACL 权限** → 勾选（单次≤30 条）→ 申请原因 **≤256 字符** + 可选 1 附件（≤500MB；部分需选“使用场景”）。
3. 提交弹窗可建**试用调试 Profile**（唯一入口；5 天有效、每应用≤5、需调试证书+UDID≤100）提前上机，**不可上架**；通过后权限自动写入 Profile，需更新 Profile/重签/上架。海外仅亚太/欧洲。

## 4. os_integration 预置 + JIT 豁免

- 预置=`app-distribution-type: os_integration` + `app-feature: hos_system_app`（apl≤system_basic），受限权限靠 profile `acls.allowed-acls` 下发；**预置本身不解锁 JIT**。
- 闸门=appspawn/kernel 的 XPM/JITFort 进程状态（`InitXpm(jitfortEnable,idType,ownerId,apiTargetVersion)`）；系统 app 同样要 ACL/厂商豁免写入系统 profile。本机已证该状态可由任意自签名 native app 用 prctl 翻转（非调用者隔离）——既是“无 ACL 自解锁”的现实路，也说明平台契约未明示。
- 可行形态=与华为/OEM 合作（系统签名 profile 授予 ACL 或平台侧豁免）；无第三方自助入口。

## 5. 材料清单与对客话术

- 材料：包名/设备类型/区域；场景（**MAUI/.NET 跨平台框架内置 CoreCLR VM，JIT 性能必需；代码随包签名分发、非热更新**）；安全（W^X/`EnableWriteXorExecute`）；坚盾回退（AOT/解释器）；架构图/录屏。
- 话术：①JIT 权限限 2in1/平板，手机不开放、须拆包；②已授权仍受坚盾模式全局禁用，以 AOT 兜底；③口径=自带 VM/脚本引擎（CEF/Electron 先例），MAUI 同口径；④~3 工作日但预留 Profile/重签/上架窗口，先走试用调试 Profile。

## 6. 不确定

- `ALLOW_WRITABLE_CODE_MEMORY` 对 .NET 运行时（非脚本引擎）的批准实例无一手证据；系统 profile/厂商豁免落地需华为确认。
- MAP_JIT 仅在 debug_hap 域 + 本镜像实测；`prctl` 状态跨重启未测（未 reboot）；fortify 的持久范围（uid/全局）未界定。

## 参考 / 提交

- 华为《受限开放权限》《申请受限权限》《JSVM-API 申请 JIT 权限指导》《JSVM-API 坚盾守护模式》《管理 ACL 权限（AGC）》；本仓 `2026-09-24-ohos-runtime-strategy.md`、`...-deployment-models.md`、`2026-10-03-ohos-wx-runtime-review.md`、`2026-10-03-ohos-wx-probe-matrix.md`。
- 本文件 + scratch（`wx-tokens/`，未提交）；`commit-paths.sh`，未强推。
