# OHOS 移植 · 提交前全扫与「刷新重切」政策（2026-10-14）

> **范围**：对当前移植代码（fork `feature/openharmony` = 内容源）做提交前扫描，产出优化/修复清单；
> 并回答「未提交的 PR 是否重切」。
> **方法**：4 个并行扫描（NA native-libs／NB corehost+CoreCLR／M1 C#／M2 MSBuild×构建面 ✗），
> 判据 = 三 PR 评审评论汇编（`review-lessons.md` ✗）＋仓内规约（`.github/instructions/*` ✗）＋
> skills（analyzing-dotnet-performance 全流程 ✗；hmos-memleak-analysis 取其 C-API 规范面 ✗）。
> **结果**：37 条发现（❌6｜⚠️14｜💡17），明细见 §6 四份报告；关键条目已二次人工复核（下称 ✓/△）。

## 1. 结论（两问）

1. **是否重切未提交的 PR：是——「换基线＋换时点」的刷新重切，不推倒重划** ✗。
   证据：漂移审计显示 28 个 payload 文件**几乎全数**有 9-13→9-23 的后续打磨/重排（review pass、
   centralize TFM、packs scoping、WX 文档、A/B 门、Console 注释 ✗），外加 9-23→10-3 的新工作
   （pal_process /proc 版、TLS/crypto 组、demote-AOT、WX-PATCH2、LINUX 别名 ✗）。
   切片基线 = 9-10 扁平 ✗，直接开 = 拿已被自己迭代掉的措辞/结构去评审 ✗。
2. **扫描已完成** ✗：6 阻提交项（§3 ✗）＋大量应收敛项（§4 ✗）；未改动任何代码（只读扫描 ✓ ✗）。

## 2. 刷新重切政策（开每支 PR 前的固定门）

1. **前提**：先做 C3 fork 主线同步（upstream/main → feature/openharmony ✗），同步时按既定折叠配方
   把 `pal_process.c`（取 fork 的 **/proc/self/fd 版** ✗，非 rehearsal 的 RLIMIT 旧解 ✗）、
   `crossgen-corelib.proj`、`src/libraries/Directory.Build.props` 折叠进上游新形态（`#135753`/
   `#135397`/WASI 块 ✗）；同步时可顺带带入 §3 的 fork 侧修复 ✗。
2. **逐支刷新**：以 fork 现内容为源，按支的文件集重生成 payload ✗ → rebase `--onto upstream/main` ✗
   → 折叠冲突 ✗ → 终验（残标记/XML/patch-id ✗）→ 干净才推/开 ✗。
3. **例外规则（重要 ✗）**：**不是无脑取 fork 现状** ✗——fork 的实验开关/自留物必须换成**中性形态**
   （实证：sfxproj 的 `OpenHarmonyInTreeR2R` A/B 门 ✗ → 用 N13 的无条件中性形态 ✗；
   WX 探针 ✗、TLS fast path ✗ 等自留项不进 PR ✗）。以「计划文档＋支/草稿的中性形态」为准 ✗。
4. **支划分调整**：
   - N7 `pal-process`：只刷新（/proc 版＋探针/fd 修复 ✗），不新增支 ✗；
   - **新增 N17 = TLS/crypto shim 组**（`opensslshim.c`、两处 `extra_libs.cmake`、crypto
     `CMakeLists.txt`、`build-native.proj/.sh` 增量、`threadstatics.cpp`＋pthread 二连 ✗）；
   - **新增 N18 = corehost demote-AOT**（7 文件＋测试 ✗，按 NB 建议分级 ✗）；
   - **A4 LINUX 别名**：按扫描结论**不宜按现状上游** ✗（见 B5 ✗）；
   - **A5 WX-PATCH2**：**拆分** ✗——`Reserve→检查→Commit`＋诊断可上游 ✗，探针自留/加旋钮 ✗；
     leak（B2 ✗）先修 ✗；TLS fast path 按 NB 判定**保持自留** ✗。
5. **顺序**：C3 同步+修复 → 逐支刷新 → N1 起逐支报批开 PR ✗（每支过门 ✗）。

## 3. 阻提交项（❌，开对应支前必须处理）

| # | 项 | 证据 | 处置 |
|---|---|---|---|
| B1 | `eng/native/tryrun.cmake:24-31` OHOS 门控**不可达** → FIFO pins 死代码 | ✓ 复核：无 `-DCMAKE_SYSTEM_NAME` ✗，toolchain 文件设置之 ✗；`-C` 先于 toolchain 执行 ✗；agent 在设备上实测 ✔ | 修法候选：改 `if(DEFINED OHOS_NDK_HOME)`（`-D` 在 `-C` 前可达 ✓）；同步修掉「command line 传入」的误导注释 ✗；N14 开前复现确认 |
| B2 | `threads.cpp:1207-1215`（WX ✗）：`Commit()==NULL` 丢保留块不 `Release()` → 映射泄漏 | agent 读码（待修时复核 △） | 一行修复 ✗（修完随 WX 拆分进 fork；上游部分不含探针 ✗） |
| B3 | `targetingpacks.targets` OHOS 判据**串联** → 非 OHOS 的本地 runtime-pack 覆盖失效（与 `61503142c87` 意图相反 ✗） | ✓ 目视复核 | 改 OR 形：`('$(TargetsOpenHarmony)' != 'true' or '%(…RuntimeIdentifier)' == '$(TargetRid)') and …` ✗，保住上游行为 ✗ |
| B4 | `Microsoft.NETCore.App.Runtime.CoreCLR.sfxproj:25-32` fork A/B 门＋fork 叙述注释 | ✓ 目视复核 | 刷新重切时取 N13 中性形态（`fed16fdbdc9` ✗） |
| B5 | `IsOSPlatform("linux")` 在 OHOS 为 true（`417ab220532` ✗）**与既定设计相反** ✗；注释还事实错误（称 RID 映射到 linux-musl ✗，实际 `openharmony→any` ✗） | agent 读码＋与 9-15 约定比对 ✔ | **A4 决策**：建议撤（或按约定重设计＋加测试 ✗）；fork 内去留由用户定 ✗ |
| B6 | `opensslshim.c` 绝对路径兄弟 dlopen：仅当 `dli_fname` 为绝对才成立 ✗；相对/裸名启动破坏信任属性 ✗ | agent 读码（中高置信 △） | 随 N17 修复：要求前导 `/` 或 `/proc/self/exe` 解析 ✗ |

## 4. 其余发现（分组摘要）

**NA（native-libs ✗）**
- ⚠️ `pal_process.c` 探针在**父进程**执行 ✗：OHOS 已被 `!defined(TARGET_OPENHARMONY)` 编译掉 ✓（复核 ✓，agent 表述过强 △）；真风险 = 其他 seccomp-trapping 沙箱 Linux ✗——可移入子进程或按平台收敛；
- ⚠️ `/proc/self/fd` 走 `__linux__` 宽守卫 ✗：与「只动 OpenHarmony」规约冲突 → 收窄到 OHOS 或按**通用修复**独立上游（二选一 ✗）；
- ⚠️ fd 号 >2^20 被静默跳过且回报 complete ✗（旧 rlimit 扫描不跳 ✗ 的回归）→ 加界或在 `INT_MAX` 处理；
- ⚠️ `-linkstaticopenssl` 离 OHOS 静默忽略 ✗；musl 敏感探针继承 glibc 答案 ✗（`HAVE_SHM_OPEN…` ✗）；
- 💡 `d_reclen` 越界检查缺 ✗、`volatile` 数据竞争 ✗、多余 `<pthread.h>` ✗；
- ⚠️ `build-native.sh`/crypto `CMakeLists.txt` 含**日期化文档引用与过长理由** ✗（违评审清单 §2 ✗）→ 刷新时收紧 ✗。

**NB（corehost+CoreCLR ✗）**
- ⚠️ WX 预检未 OHOS 限定 ✗（所有非 Apple W^X 平台付探针 ✗、失败静默关 W^X ✗）→ 自留/加旋钮 ✗；
- ⚠️ `fx_muxer.cpp`「optional」把**存在但加载失败**一并吞掉 ✗ → 缺失=info、损坏=warning ✗；
- ⚠️ `threadstatics.cpp` carve-out 理由写错（musl 早退根因是 Android ✗）＋当前无收益 ✗ → 保持自留 ✗；
- 💡 errno 陈旧、`sysconf` 未检、重复报错、`SDKLookup` 断言可空过（✗ 收紧 ✗）、TLS 探针未 memo ✗、`eeconfig` 运行时 setter ✗。

**M1（C# ✗）**（F1 见 B5 ✗）
- 🟡 `IsLinux()` 死子句 ✗（`TargetsLinux` 已真 ✗）→ 恢复上游原行 ✗；
- 🟡 注释收紧（NamedMutex/SharedMemory 各 1 处 ✗）；ℹ️ NoPThreads 路径正确（PR 正文写明 ✗）；测试用规范大小写＋加一条断言 ✗。

**M2（MSBuild/构建 ✗）**（F1/F2 见 B4/B3 ✗）
- ⚠️ `KnownAppHostPack` Remove 未按 TFM 收窄（且尾部守卫死 ✗）、`shims/Directory.Build.props` 用 `TargetOS` 而非 `TargetsOpenHarmony` ✗、`System.Console.csproj` unix 源判定在多 TFM 下**类重复** ✗（补 `TargetPlatformIdentifier == ''` ✗）、项目级 `NoWarn;CA1416` 违免抑制惯例 ✗（改点内 `#pragma`＋TODO ✗）、`ILCompiler.pkgproj` 引 fork-only `OHOS_CXXRUNTIME_DIR` ✗（去或改名注释 ✗）；
- 💡 crossgen2 映射两处重复可集中 ✗（或留给 R2R PR ✗）、3 处注释小瑕 ✗、oob/apicompat TFM 遍历与 `KnownILCompilerPack` 缺 `openharmony-arm64`（低置信，待核 ✗）。

**越组提醒**：`configurecompiler.cmake:947` 给所有 AMD64 加 `-march=x86-64-v2` ✗（疑似 eng/native 面 ✗，待归属）。

## 5. 行动序列（待批 ⏳）

- **WP1（fork 修复批 ✗，内部 ✗）**：B1 定修法 ✗；B2/B3/B4/B5(注释部分)/B6 落地 ✗；顺手清 §4 小项（死子句/守卫收窄/注释收紧/Console/shims ✗）；
- **WP2（决策 ⏳）**：A4 别名去留 ✗；A5 WX 拆法确认 ✗；TLS fast path 自留确认 ✗；demote-AOT 分级 ✗；`-linkstaticopenssl` 语义 ✗；`-march=x86-64-v2` 归属 ✗；
- **WP3（C3 ✗）**：fork 同步（含 /proc 版折叠 ✗）→ 逐支刷新重切 ✗ → N1 起逐次报批开 PR ✗。
- 建议：**WP1 并入 WP3 的 fork 同步一波完成** ✗；N1 不必等全部，但其支也要过门（漂移轻 ✗）。

## 6. 明细报告与判据

- NA：`/data/storage/el2/base/tmp/opencode/up-rehearse-c3/scan/report-na-native-libs.md`
- NB：`…/scan/report-nb-corehost-coreclr.md`
- M1：`…/scan/report-m1-managed.md`
- M2：`…/scan/report-m2-msbuild.md`
- 判据：`…/scan/review-lessons.md`（三 PR 评审汇编 ✗）
- **入库副本**：`docs/plans/scans/2026-10-14/`（四报告＋判据 ✗，随本文件提交 ✗）。

## 7. 开前注释 pass（2026-10-15 审）

> 由来：N1（#135808）评审中 jkotas 的 "Simplify the comment." 教训——**不维护平台清单、注释求简、不带 fork 叙述**。
> 执行：各支刷新重切/开 PR 前，按下表把注释替换为「成稿」版；复核口径＝对每支 payload（`upstream → fork` 净差）
> 抽全部新增注释行逐条审（2026-10-15 审全 15+2 支与 N17/N18 候选）。

**已直接应用**：**N4 `Net.Security.Native/extra_libs.cmake`（3→2 行）**——Wave-1 支已 amend（`9f49c0c5b04`）：

```cmake
       # OpenHarmony has no krb5 in its sysroot; the shared apphost dlopens libgssapi_krb5 on demand.
       # The static apphost links this macro even though Net.Security.Native is not built for OpenHarmony.
```

**开前逐条应用（成稿）**：

| # | 支/文件 | 动作 | 成稿（按行 ✗） |
|---|---|---|---|
| 1 | N17 `opensslshim.c` | 12→4 行 | `// OpenHarmony allows more than one OpenSSL in a process, and a bare soname could pick up` ｜ `// one from the loader search path (silently changing the process-wide TLS trust anchors).` ｜ `// Open only the sibling libssl/libcrypto next to this shim, by absolute path; fail closed.` |
| 2 | N15 `libraries/Directory.Build.props` | 4→2 行 | `<!-- OpenHarmony has no -openharmony TFM yet; compile managed libraries in the linux` ｜ `     group, and the shims in the same group so sfx-src keeps them in the layout. -->` |
| 3 | C2 `shims/Directory.Build.props` | 4→2 行 | `<!-- No -openharmony TFM: compile in the linux group, the same TFM as the shared-framework` ｜ `     traversal (LibrariesOpenHarmonySfxTfm) so sfx-src keeps the shims in the layout. -->` |
| 4 | N14 `eng/native/tryrun.cmake` | 4→3 行 | `# OpenHarmony cross builds cannot run the FIFO probes; pin the two answers here` ｜ `# (the remaining linux-family answers come from the code below). OHOS_NDK_HOME,` ｜ `# which this initial-cache script can read, identifies the build.` |
| 5 | N18 `pal.unix.c` | 6→3 行 | `// Same as pal_load_library, but a load failure is an expected outcome and is logged at` ｜ `// info level instead of error. Use for optional components whose absence should not` ｜ `// produce error output on every invocation.` |
| 5b | N18 `pal.windows.c` ×2 处 | 3→2 行 | `// Logs a library load failure; probing for an optional library is an expected outcome,` ｜ `// so it is reported at info level instead of error.` |
| 6 | N17 crypto `CMakeLists.txt` | 6→4 行 | `# The static archive is linked directly into NativeAOT apps by ilc, which does not link` ｜ `# libcrypto/libssl, so the archive always needs the dlopen shim. When the shared library` ｜ `# links OpenSSL statically (OpenHarmony -linkstaticopenssl) the archive gets its own` ｜ `# shim-enabled object set, selected by FEATURE_DISTRO_AGNOSTIC_SSL_STATIC.` |
| 7 | N5 `apphost/static/CMakeLists.txt` | 3→2 行 | `<!-- Force the whole runtimeinfo archive into the link; the WHOLE_ARCHIVE generator` ｜ `     expression is not usable with the OpenHarmony NDK toolchain, so use --whole-archive. -->` |
| 8 | N7 `pal_process.c` 引言 ×2 | 6→4、3→2 行 | ① `// OpenHarmony traps close_range in seccomp (SIGSYS), so list the open descriptors in` ｜ `// /proc/self/fd and touch only the real ones instead of scanning up to RLIMIT_NOFILE.` ｜ `//` ｜ `// This runs inside the forked child, where malloc is not safe, so the listing is read` ｜ `// with getdents64 into a stack buffer.` ② `// Sets FD_CLOEXEC on every open descriptor when no bulk close_range is usable` ｜ `// (OpenHarmony: seccomp traps it with SIGSYS), via /proc/self/fd with an rlimit fallback.` |
| 9 | N17 `threadstatics.cpp` | **整件移出 N17**（NB 判定：保持自留）＋`_GNU_SOURCE` 块 4→2 行 | `// dladdr() needs _GNU_SOURCE before the first system header; the native-libs build already` ｜ `// passes -D_GNU_SOURCE, and this keeps the shim buildable stand-alone.` |
| 10 | C3 `src/tools/illink/…/Microsoft.NET.ILLink.targets` | 1 行，轻 ⏳ | 去冗余括号可选：`<!-- OpenHarmony also lacks GSSAPI/krb5 in its sysroot, so use the managed implementation -->` |

**判定保持原样**（与相邻上游句式一致/事实必要）：N2（贴相邻条件）、N3（沿上游句式）、N8、N9（安全理由）、
N10（交叉引用有用）、N11/N12（映射理由）、N16（CA1416 退出条件）、N13 其余注释（另：N13 的 A/B 门注释按
既有政策换中性形）。全库仅 N1 出现过「平台清单式」注释，已修。
