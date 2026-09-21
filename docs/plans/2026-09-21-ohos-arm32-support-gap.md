# openharmony-arm（32 位）全量支持差距分析（2026-09-21）

**背景：** RID graph（#132953 的 `runtime.json` 与 SDK 快照）里有
`openharmony-arm`，但 pack 列表、SDK/aspnetcore 列表目前只发布 arm64/x64
（N13 于 2026-09-21 按"只发 arm64/x64"删除了 `openharmony-arm`）。本文件盘点
"全面支持 openharmony-arm" 的可行性、差距、工作量与风险，供决策。

---

## 0. 决策（2026-09-21）：暂缓，等设备

- 当前**找不到 32 位 ARM 的 HarmonyOS/OpenHarmony 设备**，没有设备验证路径
  （本机 arm64 设备内核不支持 32 位 ELF，见 §1）。
- 决策：**暂不实现** openharmony-arm 的构建/发布面支持，维持现状：
  - RID graph 保留 `openharmony-arm`（可寻址 RID）；
  - N13/S1a/A1 只发布 arm64/x64（N13 tip `fed16fdbdc9`）；
  - 不投入 runtime/CI 的 arm 构建打通。
- **启动条件**：拿到 32 位设备（或支持 32 位镜像的模拟器）后，按 §3/§4 的
  清单启动实现（runtime arm 构建 + `ARM_SOFTFP` 启用 → amend N13/S1a/A1 →
  arm32 签名器 → 设备验证）。本文件的可行性与验收清单（§2–§7）届时直接复用，
  无需重新调研。
- 记录位置：本文件 + `docs/plans/2026-09-07-ohos-pr-plan-bsd-haiku-model.md`
  §5 决策点 6。

---

## 1. 结论摘要

- **技术上没有硬阻塞**：OHOS 公共 SDK 完整提供 armv7 工具链；上游 .NET 对
  32 位 ARM 的支持已存在（CoreCLR linux-musl-arm、NativeAOT 自 .NET 9 起支持
  `linux-arm`/`linux-musl-arm`、crossgen2 有 ARM target、apphost/host pack 与
  aspnetcore `linux-arm` 都在支持列表里）。
- **真正的瓶颈是"无法验证"**：本机 arm64 OHOS 内核**不支持 32 位 ELF**
  （执行返回 `not executable: 32-bit ELF file`，即 ENOEXEC），且根文件系统没有
  `ld-musl-arm.so.1`。要验证运行时行为，需要真正的 32 位 OHOS 设备或支持
  32 位镜像的模拟器（当前工作区没有）。
- **工作量估计**：无设备时"构建打通（runtime/CI 产出 arm packs）"约 **3–6 天**
  可探明真实难度；"全量支持（三仓发布面 + 设备端签名 + CI）"约 **1.5–3 周**，
  且设备验证环节不可省略；主要风险是 OHOS+arm32 组合下未知的编译/运行问题。

---

## 2. 现状盘点

| 组件 | 现状 | 32 位可行性 | 差距 |
|------|------|-------------|------|
| NDK / 工具链 | SDK 26.0.0.18 提供 `armv7-unknown-linux-ohos-clang`、`sysroot/usr/lib/arm-linux-ohos`（crt 齐全）、libc++ multilib（`a7_soft`、`a7_softfp_neon-vfpv4`、`a7_hard_neon-vfpv4`） | ✅ | 无 |
| coreclr（JIT/GC/PAL） | 上游 `linux-arm`/`linux-musl-arm` 是受支持配置（`src/coreclr/{jit,vm}/arm` 齐全） | ✅（组合未验证） | 需要用 `-os openharmony -arch arm` 跑通并修未知问题 |
| native libs（System.Native 等） | 上游 musl-arm 支持 | ✅ | 同 coreclr，随构建验证 |
| crossgen2 | `TargetArchitecture.ARM` 存在（`src/coreclr/tools/Common/TypeSystem/Common/TargetArchitecture.cs`）；上游产出 linux-arm R2R | ✅ | fork 脚本把 `--targetarch` 写死为 arm64；PGO mibc 是 arm64 数据（arm 可无 PGO） |
| NativeAOT / ILCompiler | **.NET 9+ 支持 `linux-arm`/`linux-musl-arm`**（SDK `Net90ILCompilerSupportedRids`、`ILCompilerRIDs.props` 内 `Platform=arm`） | ✅ | 需要构建 `openharmony-arm` 的 ILCompiler pack（含 arm32 版 selfsign） |
| apphost / host pack | 上游有 `Microsoft.NETCore.App.Host.linux-arm` | ✅ | 需 runtime 构建产出 `Host.ohos-arm` |
| aspnetcore | 上游支持列表含 `linux-arm` | ✅ | A1 当前删除了 `openharmony-arm`，全量支持需加回（5 个文件） |
| SDK 列表（S1a） | `GenerateBundledVersions.targets` 8 处仅 arm64/x64 | ✅ | 8 处加 `openharmony-arm`；RID 快照图已含 arm |
| RID graph（#132953 + SDK 快照） | `openharmony-arm` 已定义（独立 base RID） | ✅ | 无（如全量支持则保留） |
| 设备端签名器 | `selfsign` 是 C# NativeAOT（现仅有 arm64 资产） | ✅（依赖 arm ILCompiler） | 构建 `selfsign-ohos-arm`；或把 ohos-selfsign 的 C/Rust 版编成 arm32 兜底 |
| **设备/验证** | **本机 arm64 不支持 32 位执行**（ENOEXEC；无 `ld-musl-arm.so.1`） | ❌ | **需要 32 位 OHOS 设备或模拟器；否则只能做构建验证** |

---

## 3. 具体差距清单（按仓）

### 3.1 runtime-ohos

- 构建：`./build.sh -os openharmony -arch arm --cross -subset clr+libs+packs`
  跑通（infra 已提供 `--os openharmony`；`TargetsOpenHarmony` 与架构无关）。
  需验证/修的可能点：OHOS 专属 cmake 分支的 arch 假设、PAL/seccomp/W^X 组合、
  R2R（crossgen2 `--targetarch:arm`）。
- 产物：runtime pack、host pack、ILCompiler pack、crossgen2 pack（R2R 可先 IL-only）。
- 上游已有 linux-musl-arm 绿线，预期问题量中等偏低。

### 3.2 sdk-ohos

- S1a `GenerateBundledVersions.targets`：8 处 openharmony 列表（apphost /
  runtime / crossgen2 / ILCompiler / NativeAOT runtime packs / aspnetcore
  runtime packs）加 arm。
- fork 构建脚本参数化（当前 arch 硬编码）：
  - `build-ohos-all.sh`（18 处）：NDK libcxx 路径（`aarch64-linux-ohos`）、
    ILCompiler 包名（`runtime.openharmony-arm64...`）、cg2 probe
    `--targetarch:arm64` 与 `cg2_probe_rid` 分支（需加 `arm) linux-arm`）、
    RID graph 存在性检查字符串（`'openharmony-arm64'` → 基 RID/架构变量）、
    注释与默认值。
  - `ohos-ci-env.sh`（5 处）：`ARCH=aarch64` 与 ICU/OpenSSL 交叉配置
    （`--host=aarch64-linux-gnu`、NDK wrapper）需支持 armv7。
  - `crossgen-framework.py`（1 处）：`--targetarch:arm64` 改为参数。
- CI：`ohos-full-build` 的 `rid` 已是输入，可传 `openharmony-arm`；env cache
  key 含 rid，不受影响；无需新 workflow，但要新增 arm 的构建矩阵条目（可选）。

### 3.3 aspnetcore-ohos（A1）

- 5 个文件把 `openharmony-arm` 加回：`SupportedRuntimeIdentifiers`、
  `BundledToolTargetRuntimeIdentifiers`、`Microsoft.NETCore.App.Runtime` /
  `Crossgen2` 包引用列表（`eng/Dependencies.props` 等）、E2E AOT guard 不变。
- 上游 linux-arm 支持齐全，机械改动。

### 3.4 设备侧签名

- `selfsign`（NativeAOT 单文件）需要 arm 版；依赖 3.1 的 ILCompiler arm pack。
- 备选：用 ohos-selfsign 项目的 C/Rust 实现交叉编译 arm32（零依赖，不依赖 .NET）。

### 3.5 验证（不可省略）

- 本机不可行：32 位 ELF ENOEXEC + 无 arm loader。
- 需要：armv7 标准系统 OHOS 设备或支持 32 位镜像的模拟器。
- 最小验收集：`dotnet --info`、`dotnet build`/console 运行、JIT 冒烟、
  （可选）R2R 与 NativeAOT 各一个样例、签名字段校验。

---

## 4. 工作量与风险

| 工作项 | 估计 | 风险 |
|--------|------|------|
| runtime arm 构建打通（含 arm packs） | 2–5 天 | 中：OHOS+arm32 未知编译/运行问题；上游 musl-arm 绿线降低风险 |
| fork 脚本/CI 参数化（3.2） | 1–2 天 | 低：机械改动 + 冷启缓存 |
| SDK/aspnetcore 列表（3.2/3.3） | 0.5–1 天 | 低 |
| selfsign arm（3.4） | 1–2 天 | 低-中：依赖 ILCompiler arm pack |
| 设备验证 | 依赖设备 | **高：当前无 32 位执行环境** |
| 合计 | 全量 ≈ **1.5–3 周**；仅构建打通 ≈ **3–6 天** | |

---

## 5. 决策选项

| 选项 | 内容 | 成本 | 收益/代价 |
|------|------|------|-----------|
| **A. 全量支持** | runtime+SDK+aspnetcore 列表 + selfsign arm + CI；在拿到设备前标记 experimental | 1.5–3 周 + 设备 | RID 完整、覆盖 32 位设备；若长期没有设备，发布未验证产物 |
| **B. 仅构建打通** | runtime/CI 能产出 arm packs 与 ILCompiler arm；SDK/aspnetcore 列表暂不加 | 3–6 天 | 探明真实难度、为后续铺路；用户侧仍不可用 `-r openharmony-arm` |
| **C. 维持现状** | RID graph 保留 arm（可寻址），pack 列表 arm64/x64（N13 现状）；文档注明不支持 | 0 | 诚实、无未验证承诺；RID graph 与 pack 列表口径不一致（可接受） |
| **D. 删掉 graph 条目** | 从 #132953 与 SDK 快照图移除 `openharmony-arm`（会改动已获批 PR） | 0.5 天 + 重审 | 表面最小；未来若要支持需重加，且要重走 review |

**建议**：若确定有 32 位 OHOS 目标设备 → A；否则先做 **B**（构建打通 + ILCompiler
arm），把 arm 的 SDK/aspnetcore 列表加回放在设备就绪之后。C/D 仅在没有 32 位
目标的规划时选择。

**需要你决定的关键输入：是否已有（或能拿到）32 位 OpenHarmony 标准系统设备/
模拟器？**

---

## 6. 选 A 对现有 PR 的影响

**结论：两个已开 PR 不受影响；三个尚未提交的 prepared 分支需要 amend；N11/N12
可能需要小幅补充（取决于 arm 构建验证）。**

| PR / 分支 | 影响 | 动作 |
|-----------|------|------|
| **#132953**（open） | **无直接改动**：RID graph 已含 `openharmony-arm`。arm32 需要的 `ARM_SOFTFP` 启用点虽在同一文件（`configureplatform.cmake` 的 openharmony 块），建议放进后续 arm32 支持 PR，避免在等 am11 review 期间改已获批内容 | 不改 |
| **#132827**（open） | **无**：全部是 `TARGET_OPENHARMONY` 条件，与架构无关 | 不改 |
| N1–N10、N14–N16 | 无 | 不改 |
| **N13** `pr/ohos-packs` | 需把 `openharmony-arm` 加回 runtime/apphost 两个 pack 列表；NativeAOT 标签的 runtime pack 列表也应加入（上游 `linux-arm` 在 NativeAOT 面内） | amend + 重演 |
| **S1a** `pr/ohos-sdk-rids` | 8 处 bundled RID 列表加 arm：AppHost、RuntimePack、Crossgen2、ILCompiler、NativeAOT runtime packs、AspNetCore runtime packs 等（RID 快照图已含 arm） | amend + 重演 |
| **A1** `pr/ohos-aspnet-rids` | `SupportedRuntimeIdentifiers`、`BundledToolTargetRuntimeIdentifiers`、`_LatestRuntimePackageReference`（Runtime + Crossgen2）加 `openharmony-arm`；NativeAOT 禁用说明不变 | amend |
| **N11 / N12**（AOT） | 可能：`openharmony-arm` → `CrossCompileArch=armv7`、ABI `ohos`，triple `armv7-linux-ohos`（clang 接受）；但 OHOS armv7 默认 **softfp**（NDK wrapper 强制 `-mfloat-abi=softfp -march=armv7-a`），AOT 编译/链接的 ABI 是否一致（含 `_linuxLibcFlavor=musl` vs `musleabihf`）需在 arm ILCompiler pack 构建时验证，必要时补 flag/flavor | 验证后定 |
| SDK S1b | 无（`TargetsOpenHarmony` 条件） | 不改 |

**顺序建议（避免阻塞现有节奏）：**

1. 先做 runtime 侧 arm 构建打通（纯 fork/CI 工作，不触碰任何 PR）；
2. 用 arm ILCompiler pack 验证 N11/N12 的 ABI/flags，必要时补丁；
3. 一次性 amend N13/S1a/A1 加回 arm，并重跑 2026-09-21 的 rebase 演练；
4. 在 32 位设备就绪前，PR 描述里把 arm 标注为 experimental / 待设备验证。

替代方案：N13/S1a/A1 先按 arm64/x64 提交（当前状态），arm 作为后续增量补丁；
代价是 arm 支持要等第二轮 review。

---

## 7. arm32 设备能否跑 .NET runtime —— ABI 层结论（2026-09-21 追加）

### 7.1 平台 ABI = softfp（实测）

- SDK sysroot 的 `libc.so`/`libm.so` **没有 `Tag_ABI_VFP_args`**（base/softfp
  ABI），`file` 也显示 "soft float"；`armv7-unknown-linux-ohos-clang` 包装器
  固定传 `-mfloat-abi=softfp`（`-march=armv7-a -mtune=generic-armv7-a -mfpu`
  来自工具链）。
- 标准系统存在 32 位 arm 用户态（loader 路径为 `/system/lib/ld-musl-arm.so.1`；
  NDK 提供 arm sysroot 与 `a7_{soft,softfp_neon-vfpv4,hard_neon-vfpv4}` libc++
  multilib）。

### 7.2 CoreCLR 的 softfp（armel）支持是现成的，且有上游在用

- `eng/native/configureplatform.cmake`：`--arch armel`（Tizen）或
  `CLR_CMAKE_TARGET_OS == android` + ARM → `set(ARM_SOFTFP 1)`。
- `eng/native/configurecompiler.cmake`：`ARM_SOFTFP` → `-DARM_SOFTFP` +
  `-mfloat-abi=softfp`（否则 `-mfloat-abi=hard`）；默认 `-mfpu=vfpv3`，与
  OHOS sysroot 的 VFPv3 一致。
- VM/JIT 侧有完整 softfp 分支：`CORJIT_FLAG_SOFTFP_ABI`（`jitinterface.cpp`
  在 `ARM_SOFTFP` 下设置）、JIT `compUseSoftFP`（HFA/FP 参数按 core 寄存器）、
  `callingconvention.h`/`callstubgenerator.cpp` 的 `#ifndef ARM_SOFTFP` 分支、
  `switches.h` 中 softfp 关闭 `FEATURE_HFA`。
- 上游 CI 存在 softfp 平台：`tizen_armel`（`archType: armel`）与
  `linux-bionic-arm`——说明这条路径是被构建过、有覆盖的。

### 7.3 OHOS arm32 还缺什么（相比 Tizen armel/Android）

| 项 | 状态 | 改动 |
|----|------|------|
| `openharmony` + `arm` → `ARM_SOFTFP` | ❌ 目前只对 android/armel 生效 | 在 openharmony 的 target 分支加 `set(ARM_SOFTFP 1)`（几行）；建议作为紧随 #132953 之后的 arm32 支持 PR，不动已获批内容 |
| NativeAOT（ILCompiler）armel ABI | 工具链有 `TargetAbi.NativeAotArmel`（Android arm 在用） | 加 `("openharmony", "arm") => NativeAotArmel` 映射（AOT targets） |
| CoreCLR R2R（app `PublishReadyToRun`）softfp | crossgen2 的 ABI 选择未覆盖 openharmony-armel | 可先不做：OHOS 框架本来就是 IL-only；app R2R 后置 |
| 设备端签名器 | 只有 arm64 资产 | 构建 `selfsign-ohos-arm`（依赖 arm ILCompiler pack）；或用 C 版自签器编 arm32 |
| 设备/CI 验证 | 无 32 位设备 | 需要 armv7 标准系统设备/模拟器 |

### 7.4 目标设备的条件清单（拿到 32 位设备时按此验收）

1. **CPU**：ARMv7-A + VFPv3（NDK 默认 `-mfpu=vfpv3`；Cortex-A7/A53-32 满足）。
2. **系统**：OpenHarmony 标准系统、Linux 内核（SDK UAPI 5.10；设备 4.19+ 预期
   也可）、API ≥ 10（clang15 ABI 的下限）、用户态 musl、`/system/lib/ld-musl-arm.so.1`
   存在。
3. **ABI**：`readelf -A /system/lib/libc.so | grep VFP_args` → 无该 tag = softfp
   （与预期一致）；若带 VFP registers 则是硬浮点设备（CoreCLR 也可，按 linux-arm
   处理）。
4. **内存/存储**：标准系统最低 128MiB，但跑 CoreCLR 建议 ≥512MiB；安装 SDK 需
   ~200MB 空间 + 可写 TMPDIR。
5. **内核策略**（arm64 上已确认，32 位设备需复验）：seccomp 是否 trap
   `close_range`/`get_mempolicy`（有 N7/运行时修复）；文件映射 `PROT_EXEC` 是否
   被拒（N9 默认 RWX 依赖匿名可执行内存）；`/tmp` 是否只读（TMPDIR 修复）。
6. **代码签名**：`code_protect` 是否对 32 位 ELF 生效/支持未知；若生效，需要
   32 位可用的签名器（arm32 selfsign/C 版）。
7. **验证集**：`dotnet --info`、hello console（JIT）、`DOTNET_EnableWriteXorExecute`
   冒烟、跨进程/线程冒烟、（可选）NativeAOT hello。

**结论**：硬件/内核/工具链层面 32 位 OHOS 标准系统设备**满足**跑 .NET runtime；
ABI 层面平台是 softfp，而 CoreCLR 的 softfp 路径（Tizen armel 模式）现成，
OHOS 侧只差“openharmony+arm → ARM_SOFTFP”的少量启用改动 + arm32 签名器 +
真机验证。真正的不确定项集中在 32 位内核的签名/沙箱策略，需要设备实测。
