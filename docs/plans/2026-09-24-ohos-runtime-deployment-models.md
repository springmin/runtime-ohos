# 鸿蒙上的 .NET 运行时：部署模型对比（自包含 vs 设备预置共享）

> 2026-09-24。范围：回答「假定设备已预置 runtime-ohos」vs「每个 app 自包含打包」的可行性与代价。
> 证据分级：**A** 官方文档/上游源码（含本仓真机证据）；**B** 上游源码推断；**C** 第三方工程/社区；**U** 未验证。
> 一手材料：测试方《ohos-kit22-verification-summary.md》（`~/Download/com.haitai.htbrowser/`）：
> MateBook Pro HAD-W24 / HarmonyOS 7.0.0.105 / API 26 / arm64，JIT 受阻；另一台 HongMeng Kernel 1.13.0 设备 JIT 全通过。

## 摘要（先给结论）

1. **JIT 不是"绝对平台禁令"，而是「设备/固件策略 + 进程级授权 + 内存来源」三重条件**（A/B）：官方自 API 12 起禁止匿名可执行内存（系统 JS 引擎除外）；本仓实测同一 port 在新旧设备上结论相反（§②）。
2. **解锁 JIT 的钥匙是"进程级特权"，不是"库放哪儿"**：`ALLOW_WRITABLE_CODE_MEMORY`（RWX，面向跨平台框架，仅平板/2in1，ACL）或系统内部/JS 引擎路径（`ALLOW_EXECUTABLE_FORT_MEMORY` + JITFort 接口）。B1 把库放进系统分区**本身不解锁 JIT**。
3. **B1 不可行**：app ns 只允许自己的安装路径 + NDK ns，既看不到 `/system/lib64`（default ns）也看不到其他 HAP 的 libs；第三方无法要求华为改镜像或加入 NDK ns。
4. **B3 对第三方无用**：跨 HAP 共享 `.so` 被 namespace 直接拒绝（设备 6 探针实测）；经 IPC 到另一个第三方服务进程执行托管代码，该进程仍是第三方进程，同样没有 JIT 授权。
5. **B4 只能做"应用内"载体**：应用内/集成态 HSP 与宿主同包名、同进程（无省空间、无 JIT 解锁）；应用间 HSP 需 `AllowAppShareLibrary` 特权（系统预置/厂商），且代码仍在消费方进程执行。
6. **现实组合：A（自包含）+ C（NativeAOT）为主**；2in1/平板若拿到 AGC 的 `ALLOW_WRITABLE_CODE_MEMORY`，A+ACL 是第二条可 JIT 的路；B 是长期平台合作选项，不是第三方可自决路线。

## ① 统一维度对照表（模型 × 维度）

| 维度 | A 自包含（现状） | B1 系统镜像/系统库 | B2 系统 HAP/签名应用 | B3 普通预装/侧载 HAP | B4 HSP/共享包 | C 混合（A+C：NativeAOT/R2R） | D 解释器（无 JIT） |
|---|---|---|---|---|---|---|---|
| 设备前置条件 | 无（普通 HAP） | 华为改镜像或加入 NDK ns | 系统签名 + 系统特权（`os_integration`）；或市场版拿 AGC ACL | 普通签名；预装渠道 | 应用间 HSP 另需 `AllowAppShareLibrary` 特权 | 无（需 ohos NativeAOT 工具链/SDK 支持） | 无 |
| 能否 JIT | 依设备策略：API26 测试机**否**；旧内核设备**可** | 库共享≠JIT：仍否 | 系统进程可获授权（厂商）；普通应用走 AGC ACL（`ALLOW_WRITABLE_CODE_MEMORY`，仅 2in1/平板）；debug 自签不可用 | 否（消费方进程仍受禁令） | 同 B3（代码运行在消费方进程） | NativeAOT：**不需要 JIT**；R2R 仍依赖 CoreCLR+JIT | 不需要 JIT |
| 包大小/内存/启动 | ≈38.7MB payload + 14 个 `.so`，签名 HAP **75.3MB**；每 app 独立页缓存、冷启动慢 | 运行时只装一次（数十 MB），app 增量≈host（<1MB） | 同 B1；系统服务可预热，最快（IPC 模型） | 同 B1 | 集成态 HSP：每消费方重签一份（**不省**）；应用间 HSP：装一次（省，但受限） | NativeAOT 二进制数 MB 级（未实测），启动快、内存低；R2R 仍需完整 payload | 同 A |
| 更新/分发 | 每 app 锁自己的运行时版本，多版本共存；市场/侧载/调试均可 | 随 OTA，全设备一个版本，回滚难；OEM 渠道 | `os_integration`/市场；ACL 需 AGC 逐 app 审批并重签 | 应用间 HSP 随系统或市场随 app 同装 | 同 B2/B3 | 随 app 自由升级，每 app 重编译；无 ACL 需求，市场审核更易 | 同 A；等解释器成熟 |
| 安全/合规 | 每 app 独立、签名绑定；攻击面按 app 隔离；.NET MIT 可分发 | 单点共享（一洞全设备），但 dm-verity 保护；MIT | 系统进程权限高，攻击面最大；需华为审核 | 跨应用信任问题 | HSP 需签名/特权审核 | 无 JIT 页，动态代码面最小 | 无 JIT 页 |
| 我们的工作量/可验证性 | 打包链已完成（kit #18/#22 上机）；JIT 受设备策略 | 不可控（平台侧）；只能做只读探针 | 不可控（合作）；需签名材料/合作样本 | 跨 HAP dlopen 实验可直接做 | 需特权样本 | 中-大：ohos 平台切片 + ilc（当前阻塞）；E2E 可验证 | 取决于 .NET 11 解释器（dotnet/runtime#112158） |

## ② 证据与判据

### 2.1 命名空间（B1/B3 的决定性判据，A 级）
- 华为官方：default ns=系统库（`/system/lib{abi}`、`/vendor`、`/system/lib64/module*`）；ndk ns=仅 `/system/lib64/ndk`；**app ns 只能访问自己的安装路径 + ndk ns，不能访问 default ns**（`c-cpp-overview`）。
- musl 源码（`third_party_musl/ldso/linux/namespace.c`）：`is_accessible()` 只认 `allowed_libs`、`lib_paths`（直接子文件）、`permitted_paths`（前缀）与继承；同仓 `porting/linux/user/config/ld-musl-namespace-aarch64.ini` 的 default ns 列表**不含**应用目录。
- 设备实测（测试方报告 §2.2）：6 个候选路径只有 `/data/storage/el1/bundle/libs/arm64/libcoreclr.so`（own dir）dlopen 成功；`el2`/`el1/base` 全失败 → **跨 HAP/跨沙箱 `.so` 不可见**。XPM owner 矩阵（`APP×SYSTEM/SHARED=ALLOW`）只在签名层放行，namespace 先拒绝。

### 2.2 系统应用/权限模型（B2 的判据，A 级）
- `HarmonyAppProvision`：`app-feature` 分 `hos_system_app`（系统应用）/`hos_normal_app`；`app-distribution-type` 含 **`os_integration`（系统预置应用）**；app 的 `apl` 最高 **system_basic**（system_core 不允许配置）；`acls.allowed-acls` 可跨级授权受限权限；release 版 profile 由应用市场签发。
- 受限权限清单（`restricted-permissions.md`）：**开放范围为普通应用**但需 ACL，且需 system_basic 级 profile；调试可改 SDK 模板，**不可用于上架**。与 JIT 相关的四个：
  - `ALLOW_WRITABLE_CODE_MEMORY`：允许申请**可写可执行匿名内存**，明确面向「使用跨平台框架开发的应用」，**仅平板/2in1 可申请**（API 14+）；
  - `ALLOW_EXECUTABLE_FORT_MEMORY`：允许**系统 JS 引擎**申请带 `MAP_FORT` 的匿名可执行内存（JIT）；
  - `ALLOW_USE_JITFORT_INTERFACE`：允许应用调用 JITFort 接口更新 MAP_FORT 内存（API 16+）；
  - `LOAD_INDEPENDENT_LIBRARY` / `ALLOW_EXTERNAL_NATIVE_CODE`：加载证书签名的独立库/外部 native 程序（PC/2in1；后者 API 23+，面向普通应用）。
- AGC 流程（官方 `jsvm-apply-jit-profile`）：JIT ACL 需向 AGC 申请并说明用途，审批后更新 profile、重打包上架；**未申请却声明该权限会导致安装失败**。

### 2.3 JIT 禁令的作用域（关键判据，A/B）
- **不是按"是否自签名"**：按进程策略（XPM/JITFORT）+ 内存来源。上游 `startup_appspawn`：`persist.security.jitfort.disabled` 决定全局 `APP_JITFORT_MODE`，`SetXpmConfig()` 调 `InitXpm(jitfortEnable, idType, ownerId, apiTargetVersionStr)`；`APP_FLAGS_TEMP_JIT=28` → `PROCESS_OWNERID_APP_TEMP_ALLOW`。`security_code_signature` 的 JITFort 是**JIT 代码签名**机制（`JitCodeSigner`/`CopyToJitCode`/`ResetJitCode`，依赖 ARMv8.3-A），系统 JS 引擎即走此路。
- **匿名内存是主要闸门**：官方变更说明「自 HarmonyOS 5.0.0(12) 起禁止匿名内存申请可执行权限，除系统内置 JS 引擎外其他虚拟机不能使用 JIT」；MateBook 上须自装 seccomp 拦截剥离 `PROT_EXEC` 才能越过初始化，保留 `PROT_EXEC` 的 RWX mprotect 被系统拒绝，JIT 代码不可执行（测试报告 §2.4/§4.1）。
- **文件映射也不能绕**：2026-09-14 设备探针 `memfd + PROT_EXEC`（mmap 与 mprotect）均 **EACCES**；即 CoreCLR 的 W^X 双映射（依赖 file-backed RX）在 OHOS 不可用，我们的 `TARGET_OPENHARMONY -> EnableWriteXorExecute=0` 是正确默认。
- **设备相关**：2026-08-31 另一台（HongMeng Kernel 1.13.0）匿名 RWX、RW→RX、JIT-then-execute 全通过，完整 CoreCLR+JIT app 可跑（本仓 §9/§10.4）→ 策略随固件/机型启用，必须按目标设备实测。
- **结论**：B 路线若要让 CoreCLR JIT，只能靠 (i) 进程获得 `ALLOW_WRITABLE_CODE_MEMORY`（RWX）或同等厂商豁免，或 (ii) 把 JIT 移植到 JITFort 接口（`ALLOW_EXECUTABLE_FORT_MEMORY`+`ALLOW_USE_JITFORT_INTERFACE`，工作量大且仅系统 JS 引擎有先例）。仅"预置安装"不会解锁。

### 2.4 HSP/HAR（B4 判据，A 级）
- 应用内 HSP：与宿主同 `bundleName`、**同进程**、随宿主 APP 发布；集成态 HSP 由工具链替换包名并**用消费方签名重签**，本质仍是应用内 HSP → 无跨应用共享、无省包体。
- 应用间 HSP：需 `app-privilege-capabilities.allowAppShareLibrary=true`（默认 false；或产品 `preinstall-config`），随系统预置或由市场与 app 同装；代码运行在消费方进程 → JIT 取决于消费方进程权限（B3 同理）。

### 2.5 各模型判据速览
- **A**：设备无前置条件；已有 kit #18/#22 真机链路（own_dir→hostfxr→hostpolicy→coreclr，payload 253 文件 38.7MB 打包进 `libs/`）；唯一阻塞是目标设备的执行内存策略（JIT）或 NativeAOT 工具链。
- **B1**：唯一"跨 app 可见"路径是平台把库放进 ndk ns 或给 app ns 加 `permitted_paths` —— 平台决定，第三方不可为；且不解决 JIT。
- **B2**：`os_integration`/系统签名 + 特权可让系统进程 JIT（或走 JITFort）；普通应用在 2in1/平板上可经 AGC ACL 自行 JIT（`ALLOW_WRITABLE_CODE_MEMORY`）；两者都需华为侧审批/合作，且 debug/自签包拿不到 ACL（测试报告 §7.2）。
- **B3**：namespace 已判死；IPC 服务化虽可"共享运行时进程"，但托管对象/P-Invoke/NAPI/UI 无法跨进程，且服务进程自身仍需 JIT 授权 → 不建议。
- **C**：NativeAOT 由 ilc 在**构建期**生成原生代码，设备无需安装运行时；动态代码能力受限（如 `Marshal.GetDelegateForFunctionPointer` 依赖动态汇编会崩）。R2R 仍是"带 JIT 的 CoreCLR"，A 的 JIT 阻塞依旧。
- **D**：解释器执行字节码，不需要 `PROT_EXEC`，因此 A 与 B 下都能跑，B 的 JIT 优势对它无意义；代价是性能（测试方按 Mono 解释器经验判定不可接受；CoreCLR 解释器 .NET 11 仍在开发）。

## ③ 结论

- **B1/B3 不可行、B4 不足以承载跨应用运行时**；**B2 才可能解锁 JIT，但需要系统签名/华为合作**（普通应用替代路径 = AGC ACL，仅 2in1/平板、需逐 app 审批）。
- **商店分发现实下 A+C（NativeAOT）为主**：A 保兼容与动态能力，C 保"任何设备可运行、无需运行时安装、无 JIT 审核风险"；两者共用同一 port 代码库。
- 若目标设备确认为 API 26 且执行内存受限，**NativeAOT 应是默认发布形态**；只有在 2in1/平板且 ACL 可获批时，才把 A+JIT 作为增强选项。

## ④ 若选 B 的落地清单（平台合作向）

1. 载体二选一：**系统镜像 `ndk` ns 库**（全 app 可 dlopen）或**系统 HAP + Service Ability**（IPC）；后者需重设计运行时进程模型。
2. 资质：系统签名/`os_integration` profile；`allowAppShareLibrary`（若用应用间 HSP）；AGC 受限 ACL 白名单（`ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）或厂商 JIT 豁免。
3. 镜像要求：运行时 `.so` 全部纳入 dm-verity/fs-verity；库路径加入 app ns `permitted_paths`（若不放 ndk ns）；与 `apiTargetVersion` 挂钩的 XPM/JITFort 策略确认。
4. ABI/版本：稳定 soname + 版本化目录（如 `/system/lib64/ndk/dotnet/11/`）；app↔runtime 兼容矩阵（最低/最高 API）；OTA 升级与回滚方案。
5. 安全：共享库 owner id/签名、跨应用攻击面、JIT 代码签名（JITFort）或解释器兜底；对第三方 app 的 API 面最小化。
6. 合规：MIT 通知与再分发材料；市场审核预沟通；debug/自签无法拿 ACL 的开发者预览通道。

## ⑤ 可上机验证的实验清单（测试机可直接做）

1. **跨 HAP dlopen**：HAP-A 在 `libs/arm64/` 放 `libprobe.so`；HAP-B 依次 dlopen A 的 `el1/bundle/libs/arm64`、`el2` 沙箱路径、`/system/lib64/module/...` 任一库；判读 `MUSL-LDSO ... check ns accessible failed / namespace moduleNs_default`（预期全失败）。
2. **策略开关**：`param get persist.security.jitfort.disabled`、`cat /proc/sys/kernel/xpm/xpm_mode`、`ls /proc/<pid>/xpm_region`；与 JIT 探针结果对照（定位是 sysprop 还是其他 LSM）。
3. **内存来源探针**（C，独立进程）：匿名 `mmap(RWX)`、`mmap(RW)+mprotect(RX)`、`memfd+PROT_EXEC`、`shm/tmpfs 文件+PROT_EXEC` 各跑一次并记录 errno；判读哪条闸门被启用。
4. **ACL 探针（debug，2in1/平板）**：用本地 profile 模板加 `acls.allowed-acls=["ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY"]` + `apl=system_basic`，本地签 profile+HAP 安装；重跑 #3 与 CoreCLR JIT smoke。判读：RWX 成功且 JIT 桩可执行则 ACL 生效；安装被拒则证明 debug 不可用（与测试报告一致）。
5. **ACL 探针（release，流程）**：在 AGC 提交受限权限申请（材料写"跨平台框架 .NET MAUI 运行时 JIT"），记录是否受理/驳回——决定 A+ACL 路线的现实性。
6. **JITFort 探针**：无权限时调 `prctl(PR_SET_JITFORT)`、访问 JITFort 接口（`CopyToJitCode`）记录返回码；验证"系统 JS 引擎专属"边界。
7. **预置库可见性**：用系统 preinstall 样本（或 `os_integration` 包）确认第三方 app 能否 dlopen 其 `libs/`；再确认 `/system/lib64/ndk` 自定义库是否可见（对照 namespace 结论）。
8. **NativeAOT E2E**：修复 ilc/平台切片后 `dotnet publish -r ohos-arm64 -p:PublishAot=true`，装 HAP 直跑；判读"设备无需安装运行时"即可 `managed app ... started`。
9. **解释器冒烟**：若 .NET 11 构建含 CoreCLR 解释器开关，禁用 JIT 跑冒烟 app + 计时，量化 D 的性能代价。
10. **HSP 载体**：把 host+payload 打成应用内 HSP 由 entry HAP 依赖，验证 native `.so` 的加载路径与签名；记录是否可省包体（预期不能）。

## ⑥ 不确定项

- **U1**：MateBook 上被剥离 `PROT_EXEC` 的具体闸门（JITFORT sysprop / 匿名 exec 钩子 / memfd EACCES / 厂商 LSM）未隔离；实验 #2/#3 可判。
- **U2**：`ALLOW_WRITABLE_CODE_MEMORY` 能否真正让 CoreCLR JIT 在此设备工作，只有第三方工程（HotSpot）旁证（C），未有本仓一手证据。
- **U3**：AGC 对非 JSVM 用途（.NET 运行时）是否批准 `ALLOW_WRITABLE_CODE_MEMORY`/`ALLOW_EXECUTABLE_FORT_MEMORY`；dev/自签不可用已由测试方确认。
- **U4**：系统预置/HSP 的 native 库在 app ns 下的真实可见性（文档未描述 `.so` 细节），实验 #7。
- **U5**：R2R-only 能否作为"无 JIT"形态（R2R 仍可能回退 JIT；无强证据）。
- **U6**：NativeAOT 在 ohos 的动态能力缺口清单（`GetDelegateForFunctionPointer` 等）与 MAUI 平台切片缺失的修复排期，本次未评估。
- **U7**：`persist.security.jitfort.disabled` 是否可由企业/开发者策略改写（不同固件默认值不同）。

## 引用

- 华为《C/C++ 标准库机制概述》（namespace 规则）：<https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/c-cpp-overview>
- 官方变更《针对所有应用的变更》（API12 JIT 禁令）：<https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/changelogs-for-all-apps-b031>
- 官方《JSVM-API 申请 JIT 权限指导》+《受限开放权限》/受限权限（HSP、特权）：<https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/jsvm-apply-jit-profile>、<https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/restricted-permissions>
- OpenHarmony 上游源码（A/B）：`third_party_musl`（`ldso/linux/namespace.c`、`ld-musl-namespace-aarch64.ini`）、`startup_appspawn`（`appspawn_common.c`、`standard/appspawn_manager.h`、`interfaces/innerkits/include/appspawn.h`）、`security_code_signature/README_zh.md`、docs（`app-provision-structure.md`、`subsys-app-privilege-config-guide.md`、`in-app-hsp.md`、`integrated-hsp.md`）。
- 第三方工程（C）：AMCL（`ALLOW_WRITABLE_CODE_MEMORY` 对 HotSpot JIT 是必需项）：<https://github.com/LZZLHY/amcl>；PsychoPy-OH ACL 审批记录：<https://github.com/Aik358/psychopy-studio-harmonyos>。
- 本仓：`2026-08-28-ohos-pr-plan-revised.md` §9/§10、`2026-09-01-ohos-syscall-audit.md`、`2026-09-22-ohos-elf-signing-research.md`、`2026-09-24-ohos-device-milestone.md`。
- 交叉引用：JIT/解释器/ACL 路线的同期分析见 `docs/plans/2026-09-24-ohos-runtime-strategy.md`（另一代理在写，勿改）。
