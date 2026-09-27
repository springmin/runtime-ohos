# runtime feature/openharmony 合并 main 11 段尾（29afde215f6）

**日期：** 2026-09-27
**目的：** 在"runtime 保持 11 带"的前提下，补齐上游 main 的 11 段尾（09-03 → 09-09），与 sdk/aspnetcore 集成分支的 09-25 upstream merge 对齐；不跨入 12 带。

## 1. 目标与范围

- 合并目标：`29afde215f6`（2026-09-09，"Enable supported UnmanagedCallersOnly tests on NativeAOT (#133399)"），即 12 带 bump `dfcb726e234`（#133344）的父提交 —— 11 带的最后一个提交
- fork 基点：`719009acffb`（2026-09-03，#133095）
- 带入：**91 个** 11 带 main 提交（JIT/Mono 修复、WASM R2R 新模型、NativeAOT interop 对齐、crypto/SNI、CI/darc 更新等）
- 明确排除：`dfcb726e234` 及其后的 12 带主线、`release/11.0-rc2`/`release/11.0` 的 rc2 回移线

## 2. 冲突与解决（排练 1 处，实际 1 处）

- 文件：`src/installer/pkg/sfx/Microsoft.NETCore.App/Microsoft.NETCore.App.Runtime.CoreCLR.sfxproj`
- 上游侧：`c3c1cc3201d`（#133111 "Use SDK pipeline for WebAssembly framework R2R"）把 browser framework R2R 从关闭改为 SDK 管线，`PublishReadyToRun` 条件改为仅 `wasi`
- fork 侧：同一区域新增 OHOS 的 `PublishReadyToRun=false`（out-of-tree stock-crossgen2 overlay）
- 解决：保留 OHOS 行；采用上游 `wasi` only 行（删除 browser/wasi 关闭行与旧 TODO-WASM 注释）
- 其余 hunk 自动合并（`_CrossGen2TargetOS` OHOS→linux 映射、`_RemoveDuplicateSymbolFiles` 去重 IL pdb 均保留；上游 `_ConfigureBrowserFrameworkR2R` 等新目标在位）

## 3. 结果

- merge 提交：`4f967fad2a1`（第一父 `ace4aa8a4da` = fork tip；第二父 `29afde215f6`）
- 净变更：528 文件，+14381/−5862；上游删除 9 个 WASM coreclr helper 文件（预期）
- fork OHOS 支持面完整（eng/src 47 个文件含 openharmony；`_CrossGen2TargetOS`/`_RemoveDuplicateSymbolFiles`/`OpenHarmonyInTreeR2R` 在位）
- 版本号不变：runtime/aspnetcore `11.0.0-rc.1.<buildid>`、sdk `11.0.100-rc.2.<buildid>`（`eng/Versions.props` 未被这 91 个提交改动；rc2 只在 `release/11.0-rc2` 线）
- 对已提交 PR（#132827/#132953）与计划 PR（N1–N16）无影响：`pr/*` 为独立 ref；N1–N16 的 09-22 排练基线 `6f4751a142c` 已含本段全部提交且排练 CLEAN；仅 `pr/ohos-packs` 与 `CoreCLR.sfxproj` 有文件交集（其 patch 已针对 #133111 预先解冲突）

## 4. 后续

- 用 `runtime_ref=feature/openharmony` 重跑三仓 CI 验证（当前发布轮为 pre-A 制品）
- 若发布包含本合并的制品：注意 versions.env 的资产 sha256 锚点与版本串策略（同版本串重发需更新锚点，或换新 buildid）
- rc2 迁移（合 `release/11.0-rc2` + 换 pin 组）另案
