# C3 fork 主线同步记录（2026-10-15）

> playbook §1 六步之第 6 步。上游 `upstream/main = 7abf5fa1d3c`；同步前 fork tip `e44f574f4dc`；
> 结果支 = `feature/openharmony`（`7e394320e16` 合并 ＋ `5a5dd8b71b8` 修复批）。

## 1. 合并（`7e394320e16`）

- **36 冲突全解析**：eng/common×2、版本/工具×6、pipelines×3、release 重复面×20 → 取上游；
  `Regression_ro_2.csproj` 接受上游删除；`eng/Subsets.props` 取上游＋回挂「OpenHarmony」注释修正；
  `NamedMutex.Unix.cs` 去重取上游（#135321＋上游 .NET 10 布局重构）。
- **四折叠**：`pal_process.c`＝#135753 骨架＋OHOS `/proc/self/fd` 分支（探针弃、界内）；
  `crossgen-corelib.proj`＝#135397 task 形＋`_CrossGenTargetOS` 折入 `_CoreLibCrossgen2Tool` 元数据；
  `libraries/Directory.Build.props`＝WASI∪OH；`gen-buildsys.sh`＝#135028 `--fresh` 逻辑＋复挂 `-C` 前置。
- 工具留档：`up-rehearse-c3/sync/{resolve-folds.py, apply-fixes.py}`；merge-tree 预演与实合并 36=36 一致。

## 2. 修复批（`5a5dd8b71b8`）

15 处编辑：tryrun 门控 env 化（`DEFINED ENV{OHOS_NDK_HOME}`）｜WX 屏障块 Release｜targetingpacks OR 形｜
OS.cs 注释修正＋死子句｜opensslshim 绝对路径强制｜dirent 界检查｜fx_muxer 损坏告警｜shims
`TargetsOpenHarmony`｜Console 多 TFM 守卫｜注释去日期化（build-native.sh/crypto CMakeLists）｜sfxproj 拼写。

**延后项**（登记 ⏳）：AppHostPack TFM 收窄（N13 刷新时）｜CA1416 点内化（N16 刷新时）｜WX 探针
OpenHarmony 限定（行为中性）｜musl tryrun 探针答案｜`-linkstaticopenssl` 离 OHOS 语义｜MutexTests
措辞/断言小件｜N17 侧注释（build-native.proj 等）。

## 3. 门禁

- **门策略（调整）**：MSBuild 编排路线弃用（自旋＋SDK 安装坑）→ **Plan-B 编译级门**（coreclr TU：
  `doublemapping`/`executableallocator`/`threads`/`threadstatics`/`eeconfig`；libs C：`pal_process`/
  `pal_signal`/`pal_interfaceaddresses`/`pal_err`/`pal_hmac`/`opensslshim`；PCH 重建后再编）；
  **链接级门挂起**（宿主 lld↔libxml2↔musl 加载链正处于 kit TOOL-HARDEN 换代中）。**结果（全绿）**：
  - coreclr TU ×5（`doublemapping`/`executableallocator`/`threads`/`threadstatics`/`eeconfig`）全 RC=0（PCH 重建后）；
  - libs C ×5（`pal_process`/`pal_signal`/`pal_interfaceaddresses`/`pal_err`/`pal_hmac`）全 RC=0，产物已落 obj；
  - 未覆盖 ⚠️：`opensslshim.c`（coreclr 树无该目标）、链接级（挂起）；证据 `sync/gate5b.log`＋`sync/gate5c.log`＋`sync/cmds/`。
- **设备构建法备注**：宿主 `uname -s` = `HarmonyOS` → 官方 `eng/common/native/init-os-and-arch.sh`
  不支持，须 **假 uname 垫片**（`uname -s=Linux, -m=aarch64`）＋ **`__PortableTargetOS=openharmony`
  seed**（#17608 未入 eng/common；与 #132953 Copilot findings 同源）。仓 `.dotnet` 的指向与安装
  选择见下方 4 坑（最终 = 符号链接 → `~/.dotnet.rc2-105` ✗）。
  **本次踩坑全录（7 坑）**：① 宿主 `uname=HarmonyOS` → 假 uname 垫片 ✗；② musl 宿主 `__PortableTargetOS`
  污染 → seed `=openharmony` ✗；③ **dotnet 安装选择**：`26451.109/112` 系 SDK（如当时的 `~/.dotnet` ✗）
  在 OHOS 上把 MSBuild 的 `Exec` **误判为 Windows**（生成 `setlocal` 批处理 ✗ → `dotnet tool restore`
  等全挂 ✗；`rc2-105`（26504.105 ✗）与修复线（`rc2-fix*` 26451.112 ✗）**正常** ✗——修复线即为该类
  问题所建 ✗）→ 仓 `.dotnet` 符号链接改为 → `~/.dotnet.rc2-105` ✗，并补
  `sdk/11.0.100-rc.1.26420.103 → 11.0.100-rc.2.26504.105` 符号链接满足 global.json ✗，
  `DOTNET_INSTALL_DIR` 显式 ✗；④ 首次尝试曾触发 arcade 自动下载 linux-arm64 glibc 版 dotnet
  （`Permission denied` ✗），须以安装选择 + `DOTNET_INSTALL_DIR` 规避 ✗。
  构建命令与垫片：scratch `up-rehearse-c3/sync/shim/` ✗；全量日志 `up-rehearse-c3/sync/build-gate4.log` ✗。
- 静态面：残标记 0、XML×4 解析、`bash -n` ✓（执行时）。
- **libs 全量构建未跑** ⚠️（编译级已覆盖其 5 个 C 件；全量与链接级挂起）。

## 4. 后续

- 推送（fetch/rebase 重试）＋本地跟平；
- pr/* 复核（merge-tree 对 post-sync fork）→ N1 起逐支刷新重切；
- 缺口登记回填（`2026-10-14-ohos-pre-submission-scan-and-reslice.md`）。
