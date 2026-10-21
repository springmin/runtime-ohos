# N 组 PR 批量开启清单（预生成，2026-09-28）

> **现况更新（2026-10-14）**：①`#132953` **已 MERGED ✓✓**（jkotas 于 10-14 13:48:36Z **squash** ✗ → `14399016e4c` ✓ 已验证在 main=`0232cf718cd` ✗）——**C3 正式激活** ⏳（复演刷新已完成 ✗；eng/common 同步待做 ✗；`#132866` 仍缺 ✗）；
> ②`upstream/main` = `0232cf718cd`（post-infra ✗）→ **C3 复演刷新已执行** ✓（10-14 ✗，隔离 scratch ✗）：13 支 CLEAN-SAME ✓；
> **4 支冲突已全解析并终验** ✓（`pal-process`/`crossgen-corelib`＝上游新变更（`#135753`/`#135397`）所致 ✗；`libs-tfm`/C2＝机械复现 ✗；
> recipes/tips/pids 见演练文档「10-14 C3 复演刷新」节 ✗）；`infra` 已合并免重放 ✓，`tls`/`platform-numa`/`named-mutex` 弃 ✓；
> `platform-numa`/`named-mutex` 确认可弃、`tls-flag-cleanup` 既定丢弃 ✓；③`eng/common` 前提已清 ✓
> （arcade#17608 于 09-24 合并 ✓）；④**`#135321` 已合并**（10-07 ✓）→ 去重清单中的
> `NamedMutex.Unix.cs` **以上游为准** ✓（`pr/ohos-named-mutex` 重演净 diff 空 → 可弃 ✓）；⑤C2/C3 仍等 `#132866` 答复 ✗；
> ⑥自 2026-10-08 起**所有上游可见动作逐次报批** ✓（playbook §3 ✓）。
> **N1 已开（10-15）**：`#135808`（刷新重切版，净差门 4+/3- 纯 OpenHarmony）；**波次政策**：
> 在飞 ≤3–4 笔、「合 1 补 1」（先例 OpenBSD 38 笔小步快跑、中位 1.7 天；规避洪泛与 CI 成本）。
> **Wave-1 已开（10-15）**：#135838（pal）· #135839（zstd）· #135840（libs-native）——在飞 4 笔＝上限。**N1 已合（06:48Z）**；**N5 已补发（#135863）**；**N2 已合（14:12Z）**；**N8 已补发（#135866）**——在飞 4 笔（N3/N4/N5/N8）＝上限。

> **10-17 开前预检完成（N9＋W4）**：基线 `upstream/main=d80abfc4b04`。
> **N9** `pr/ohos-wx-default` → `770c2c80b6d`（零冲突；1 文件 4+/2-；§7 判定保持）；fire 包 `sync/bodies/N9-fire.md`。
> **W4**（fire 包齐 `sync/bodies/N{7,11,12,13,16}-fire.md`）：N7 `bad2a31158c`（`pal_process.c` **171+/8-**，含 `/proc` 版；OHOS NDK 编译核通过）、N11 `2d25123a366`（6+/1-）、N12 `ac328dbbddb`（4+）、N13 `5e13db906e8`（42+/5-；A/B 注释中性化＋B3 OR 形；残留：`_RemoveDuplicateSymbolFiles` 依赖的新 SDK 目标名本地不可核 ⚠️）、N16 `1297a3335e6`（叠 N15 `79178f8d0fc`；自身 delta 8+/3-；**N15 刷新后须再 rebase** ⚠️）。
> 全部**未推**；按「合 1 补 1」待合入触发。

> **10-19 N5 评审处置**：jkotas 同意报 CMake（"Yes… make OHOS a first-class across all commonly used tools"）；Copilot bot 2 条 → **Medium 已修**（`4236198a4db`：`runtimeinfo` 恢复为链接目标、保留 raw `--whole-archive` 语义）×High 以 Android 先例＋`#111523` 回复（线程回复 `r4311267124`／`r4311266765`）；**jkotas 已把 main 合入本分支**（`c1a22d8f9a`）；**CMake issue 已提交**（[`cmake/cmake#28188`](https://gitlab.kitware.com/cmake/cmake/-/work_items/28188)）＋**jkotas 回帖已发**（[`discussion_r4311471822`](https://github.com/dotnet/runtime/pull/135863#discussion_r4311471822)）。

> **10-20 N5 续** ✗：jkotas 注释建议已应用 ✓（`985a9ba061` ✗："Workaround for missing OpenHarmony WHOLE_ARCHIVE support in CMake. Remove once the minimum required CMake version is 4.5." ✗）；Copilot 第二轮 High（安全依赖块 191–196 ✗）**有效 ✓** → **已修** ✗（`bdc286176c3` ✗：guard 加 `NOT CLR_CMAKE_TARGET_OPENHARMONY` ✗）＋回复 [`discussion_r4320470576`](https://github.com/dotnet/runtime/pull/135863#discussion_r4320470576) ✓；CI 仍 **4 红**（flake ✗，build `1641156` ✗）。

> **10-20 次波预检（N14/N10/N15＋N16 重叠 ✗）** ✗：基线 `upstream/main=046f365b90c` ✗。N14 `pr/ohos-tryrun` → `13a04c52975` ✗（净差 **1 文件 8+** ✗；§7 注释已成稿 ✓）；N10 `pr/ohos-crossgen-corelib` → `ddfe9c77272` ✗（**1 文件 10+/1-** ✗；注释保留 ✓）；N15 `pr/ohos-libs-tfm` → `767cbcc2330` ✗（**6 文件 25+/3-** ✗；§7 成稿 ✓）；N16 `pr/ohos-console` **重叠至新 N15** → `15b7413acc1` ✗（自身 delta **8+/3-** ✗）。fire 包齐 ✓（`sync/bodies/N{14,10,15}-fire.md` ✗；N16 已更新 ✗）。**均未推** ✓。

> **10-20 N5 MERGED ✓**：`#135863` squash **`b37852e7e2c`**（04:57:08Z ✗）＝main tip ✓；**N9 已开** ✓ **`#136131`** ✗（`pr/ohos-wx-default` 重放至 `b37852e7e2c` → `5f93c6eed25` ✗；净差 **1 文件 4+/2-** ✓）——**在飞 4 笔**（N3/N4/N8/N9 ✗）。

> **10-20 N14 已开** ✓ **`#136132`** ✗：`eng/native: pin the OHOS cross-build FIFO probe answers` ✗；`pr/ohos-tryrun` 重放至 `b37852e7e2c` → **`7c3d4e4ed79`** ✗（净差 **1 文件 8+** ✓；首推遇旧远端支 `c2a5e90db55` 曾拒 ✗，已 force-with-lease 覆盖 ✓）。**在飞 5 笔**（N3/N4/N8/N9/N14 ✗；N9 已批待合 ✗）。

> **10-20 #132866 进度同步已发** ✓：[`#issuecomment-6285162682`](https://github.com/dotnet/runtime/issues/132866#issuecomment-6285162682) ✗——覆盖 6 合入／5 在飞／`#132827` 关闭／队列／三项待答（C3 带默认路径 ✗、C2 跟随 N15 ✗、S1c 仍问 ✗）；全量审计确认 **C2/C3 此前均无上游答复** ✓。

> **10-20 W4 四支已重放** ✓（基线 **`b37852e7e2c`** ✗）：N7 `0caa588edc1`（**1 文件 171+/8-** ✗；lease `c5e1dc3e4aa` ✗）、N11 `e127a79075d`（**6+/1-** ✗；lease `91a2e8e5a62` ✗）、N12 `3a9ce269991`（**4+** ✗；lease `da4dc098a4a` ✗）、N13 `1f860da25eb`（**4 文件 42+/5-** ✗；lease `fed16fdbdc9` ✗）。全部 behind 0／零冲突／净差面与预检一致 ✓，**均未推** ✓。

> **10-20 N14 评审处置** ✓：am11（08:38Z ✗）在 `tryrun.cmake:27` 要求把 OHOS 检测并入 platform probe、沿用既有 `elseif` 模式、删注释 ✓ → 已 amend＋rebase 至 `2422bb8fc1f` → **`fe9a4a1d020`**（净差 **1 文件 5+** ✗；本机 cmake 实测：env 设＝两项 1 ✓／env 空＝未设 ✓）→ force-push ✓；inline 回复 [`r4324508219`](https://github.com/dotnet/runtime/pull/136132#discussion_r4324508219) ✗。

> **10-20 N9 MERGED ✓**：`#136131` squash **`d260b5c598a`**（**14:04:04Z** ✗；jkotas 14:01 注 `/ba-g` 非必需 leg 为 flaky network ✗）——W^X 默认已在 main ✓。
> **10-20 N14 CLOSED** ⛔：am11（12:54Z ✗）判 `HAVE_BROKEN_FIFO_KEVENT/SELECT` **均未使用** ✗，其 **#136147「Cleanup unused cmake configs」**（已 MERGED ✗）把两者从 `tryrun*.cmake`／`configure.cmake`／config 头中删除 ✓ → N14 失效，**不重开** ✓。am11 重申方向 ✓：*"instead of these tiny few liner PRs, it would be good to push substantial changes in batches"*（同其 08-30 `#132827` 评论 ✗）→ **剩余队列需重新分批** ⏳。

> **10-20 三批就绪** ✓（基线 **`cf3fbf9c8d1`** ✗，**均未推** ✓）：
> **A** `pr/ohos-batch-aot-packs @ c2f3dcfb68d`（**7 文件 57+/7-** ✗；N10-N13＋C3 ✗；已移除 `OHOS_CXXRUNTIME_DIR` 打包块 ✗；XML 全过 ✓）；
> **B** `pr/ohos-batch-libs @ 8730373688c`（**7 文件 31+/6-** ✗；N15 已内置 C2 ✗；CA1416 抑制保留并带退出条件 ✗；XML 全过 ✓）；
> **C** `pr/ohos-pal-process @ ae3720591c8`（**1 文件 171+/8-** ✗；NA 缺陷已含于现支 ✗；`d_reclen`／INT_MAX／OHOS 收窄 ✓）。
> fire 包：`batchA-fire.md`／`batchB-fire.md`／N7 原包 ✓。

> **10-20 三批已开** ✓：A [`#136185`](https://github.com/dotnet/runtime/pull/136185) ✗、B [`#136186`](https://github.com/dotnet/runtime/pull/136186) ✗、C [`#136187`](https://github.com/dotnet/runtime/pull/136187) ✗（tips `c2f3dcfb68d`／`8730373688c`／`ae3720591c8` ✗；diff 面 **7／7／1** 文件 ✓）——**在飞 6 笔**（N3/N4/N8＋A/B/C ✗）。S1c 追问草稿已备，**未发** ✓。

> **10-20 第二波分支已备并推 fork** ✓（**未开 PR** ✓）：**D** `pr/ohos-crypto-shim @ a374e01e975`（5 文件 **130+/8-** ✗；N17 已剔除 threadstatics／docs ✗；B6 绝对路径修复已含 ✓）、**E** `pr/ohos-demote-aot @ 555ed5c87e8`（8 文件 **102+/8-** ✗）、**F** `pr/ohos-wx-hardening @ d4be873199e`（3 文件 **21+/1-** ✗；WX-PROBE 探针未含 ✗；B2 `Release` 已含 ✓）。fire 包：`batchD-fire.md`／`batchE-fire.md`／`batchF-fire.md` ✓。**I（CI leg）未启动** ✓——依赖带 OHOS NDK 的 prereqs 镜像，且按计划留最后 ✓。

> **10-20 #132866 询问已发** ✓：[`6303946181`](https://github.com/dotnet/runtime/issues/132866#issuecomment-6303946181) ✗——问 N3/N4/N8 是否合并为一个 PR＋剩余 runtime 计划（未含自留项 ✗）。
> **10-20 SDK 两支已重放** ✓：S1a `pr/ohos-sdk-rids @ 41e998e3d0`（4 文件 **545+/3-** ✗）、S1b `pr/ohos-sdk-sandbox @ cd0ed5a950`（自身 **17 文件 182+/15-** ✗，以 S1a 为基 ✗；`NativeEntryPoint.cs` 冲突已解：保留上游 UI 语言初始化＋加 `Apply()` ✗）。目标分支 dotnet/sdk `main`（`6675a7226e` ✗）；fire 包 `sdkS1a-fire.md`／`sdkS1b-fire.md` ✓。**均未开 PR** ✓。

> **10-20 SDK 两笔已开** ✓：S1a [`dotnet/sdk#56732`](https://github.com/dotnet/sdk/pull/56732) ✗（`41e998e3d0` ✗，**4 文件 545+/3-** ✗）、S1b [`dotnet/sdk#56733`](https://github.com/dotnet/sdk/pull/56733) ✗（`cd0ed5a950` ✗，diff 20 文件（含 S1a ✗），自身 **17 文件 182+/15-** ✗，正文注明叠 #56732 ✗）。runtime D/E/F 仍备而未发 ✓。

> **10-21 S1c 分支已切＋追问已发** ✓：`pr/ohos-sdk-codesign @ 0e85179ddcc` ✗（**17 文件 1738+/1-** ✗：`OpenHarmonyCodesign` 79 行＋`ElfSigner` 1331 行＋`Microsoft.NET.Sdk.targets` 钩子 51 行＋`Strings.resx`／13 个 xlf ✗；资源号 **NETSDK1247–1250** ✓；未含 selfsign CLI ✗）；追问 [`6304910366`](https://github.com/dotnet/runtime/issues/132866#issuecomment-6304910366) ✗（点明分支已备 ✓）。**未开 PR** ✓（等 reviewer 表态 ✗）。

> **10-21 native 整合支＋设备证据** ✓：`pr/ohos-native-fixes @ c9ea916469a` ✗（**10 文件 315+/18-** ✗；N3+N4+N7+N8+D 合一 ✗）；设备实测（HarmonyOS aarch64 ✗，SDK rc2-112 ✗）：`dotnet --info` RID ✓、hello world ✓、子进程 `exit=0` ✓、NIC 枚举 ✓（`speed=-1` ✗）、RSA 2048 ✓、TLS 577B ✓；证据存 `sync/evidence/native-2026-10-21/` ✓；fire 包 `native-fire.md` ✓。**未开 PR／未关旧四笔** ✓。

> **10-21 native 合并 PR 已开** ✓：[`#136194`](https://github.com/dotnet/runtime/pull/136194) ✗（`c9ea916469a` ✗，**10 文件 315+/18-** ✗）；旧四笔 `#135839`／`#135840`／`#135866`／`#136187` **已关** ✓；am11 回复 [`6305107651`](https://github.com/dotnet/runtime/pull/136132#issuecomment-6305107651) ✗。runtime 在飞 **3 笔**（A `#136185`／B `#136186`／native `#136194` ✗）＋ SDK 2 笔（`#56732`／`#56733` ✗）✓。

> **10-21 E+F 合并支已备** ✓：`pr/ohos-native-robustness @ d7d1cb32031` ✗（**11 文件 123+/9-** ✗；E＝corehost 可选 SDK 加载降噪＋测试/文档 ✗；F＝写屏障 Commit 检查／W^X 降级 ✗；两笔通用修复，无 OHOS 字样 ✓）；fire 包 `batchEF-fire.md` ✓。**未开 PR** ✓。

> **10-21 E+F 独立 PR 已开** ✓：[`#136198`](https://github.com/dotnet/runtime/pull/136198) ✗（`b3ddf1cf36f` ✗，**11 文件 123+/9-** ✗；正文注明「源自 OHOS 移植、代码通用」✗）；runtime 在飞 **4 笔**（`#136185`／`#136186`／`#136194`／`#136198` ✗）＋ SDK 2 笔 ✓。

> **10-21 E+F 收敛为 F-only** ✓：`#136198` head **`f84e75bcec9`** ✗（**2 文件 20+/1-** ✗；E 全部撤销（`file_exists` 已覆盖缺失 ✗、损坏须报错 ✗）、`executableallocator` 日志删除 ✗、docs 回滚 ✗；仅保留写屏障 Commit 检查＋只读回退 ✗）；3 条 inline 回复＋总结 [`6306622073`](https://github.com/dotnet/runtime/pull/136198#issuecomment-6306622073) ✗；CI 重跑 ✓。

> **10-21 B 关闭** ✓：`#136186` **CLOSED** ⛔——撤掉全部 TFM 特判后支为空 ✗（jkotas：FreeBSD 等无平台 TFM 也正常 ✓，「不应为 openharmony 做这种特殊处理」✗）；inline 回复 `4332459344` ✗＋关闭说明 ✓；runtime 在飞 **3 笔**（`#136185`／`#136194`／`#136198` ✗）✓。

> **10-21 A 通用方案** ✓：`#136185` head **`127135f57d9`** ✗（`eng/targetingpacks.targets` **10+/9-** ✗：apphost 改 `Update`＋`Include` 兜底 ✗、`ResolvedRuntimePack` 收窄对所有 OS 生效 ✗）；2 条 inline 回复＋总结 [`6307048305`](https://github.com/dotnet/runtime/pull/136185#issuecomment-6307048305) ✗；CI 重跑 ✓。

> **10-21 A RID 列表统一** ✓：`#136185` head **`b149dd91585`** ✗（`targetingpacks.targets` **6+/6-** ✗：runtime／NativeAOT／ILCompiler／Crossgen2／apphost 全改用 `_LocalAppHostRuntimeIdentifiers` ✗；属性扩为并集（含 browser／iOS／tvOS／Android ✗）；修掉一处自引用 ✓）；inline 回复 `4332894342` ✗。

> **10-21 F 讨论回复** ✓：[`r4332720955`](https://github.com/dotnet/runtime/pull/136198#discussion_r4332720955) ✗——附设备证据（修复前 `SEGV_ACCERR` ✗；修复后到托管代码 ✗）＋三选项（keep／fail-fast／drop ✗）；等 jkotas 选择 ✓。

> **10-21 F 追问答复** ✓：[`r4332799573`](https://github.com/dotnet/runtime/pull/136198#discussion_r4332799573) ✗——其他调用成功是因为 fork 的**双映射预检**（全局关 W^X ✗）不在本 PR ✗；F 单独只会推迟失败 ✓；提议把**预检**另开 PR ✓；**`#136198` 暂不关** ✓（待他回复 → 开预检 PR → 再关 ✓）。

> **10-21 预检支已备** ✓：`pr/ohos-wx-precheck @ 48b76b66f75` ✗（1 文件 **32+** ✗：`doublemapping.cpp` 的 RW／`PROT_NONE`／`mprotect RX` 预检 ✗；失败日志每进程一次 ✗）；fire 包 `wxprecheck-fire.md` ✓；**按计划等 jkotas 回复后再开 PR ✗、随后关 `#136198`** ✓。

> **10-21 S1c PR 已开＋prereqs issue 已提** ✓：[`dotnet/sdk#56735`](https://github.com/dotnet/sdk/pull/56735) ✗（`0e85179ddcc` ✗，**17 文件 1738+/1-** ✗；正文含 scope note「不要则关」✗；设备证据：`dotnet publish -r openharmony-arm64` → apphost `.codesign` VALID ✗）；[`prereqs-docker#1778`](https://github.com/dotnet/dotnet-buildtools-prereqs-docker/issues/1778) ✗（NDK 入镜像 vs CI 下载 ✗，@dotnet/dotnet-docker-reviewers ✓）。SDK 在飞 **3 笔**（`#56732`／`#56733`／`#56735` ✗）✓。

> **10-21 A1 重做支已备** ✓：`pr/ohos-aspnet-rids-rebuild @ 133b6799f5` ✗（**5 文件 17+/4-** ✗；措辞改为「skip **repo-side** NativeAOT」✗——`NativeAotSupported` 只影响仓库自带工具（`aspnetcoretools`／`dotnet-dev-certs`／`dotnet-user-jwts`／`dotnet-user-secrets` ✗）与 E2E harness ✗，**不影响用户 AOT 发布** ✓；上游删 `eng/Dependencies.props` ✗ → 4 条迁入 `Directory.Packages.props` ✗）；目标 `dotnet/aspnetcore:main` ✗；fire 包 `aspA1-fire.md` ✓。**未开 PR** ✓。

> **10-21 A1 PR 已开** ✓：[`dotnet/aspnetcore#69952`](https://github.com/dotnet/aspnetcore/pull/69952) ✗（`133b6799f5f` ✗，**5 文件 17+/4-** ✗；标题「Add the openharmony RIDs and **skip repo-side NativeAOT**」✗；正文含 Follow-up：等 ILCompiler pack＋交叉工具链再 enable ✗）。全仓在飞：runtime **4**＋sdk **3**＋aspnetcore **1**＝**8 笔** ✗。

> **10-21 A 评审处置（jkotas 6 条 ✗）** ✓：开启 **R2R**（删 IL-only＋pdb 去重 target ✗）、`CommandLineHelpers` 通用映射 `openharmony→Linux` ✗、删局部 `_CrossGenTargetOS`/`_CrossGen2TargetOS` ✗、链路器条件改 `_targetOS` ✗、删 2 处无用注释 ✗；新 head **`7ce2047772e`** ✗（**6 文件 25+/6-** ✗）；6 条 inline 全回复＋总结 [`6306415914`](https://github.com/dotnet/runtime/pull/136185#issuecomment-6306415914) ✗；CI 已在新 head 重跑 ✓。

> **10-21 B 按 `-unix` 重做并已推 PR 支** ✓：`pr/ohos-batch-libs @ 1990b7d6047` ✗（**6 文件 24+/3-** ✗；`LibrariesOpenHarmonySfxTfm` → `net11.0-unix` ✗；System.Console 特判＋CA1416 抑制全移除、文件回到上游 ✗）；jkotas 顶层回复 [`6306586702`](https://github.com/dotnet/runtime/pull/136186#issuecomment-6306586702) ✗＋inline 回复 ✓。**注**：上游 CI 无 OHOS leg，需 fork 构建线确认布局 ✓。

> **用途**：#132953（infra）合并后，按既定顺序把 `pr/ohos-*` 批量 rebase 到 post-infra main 并开 PR。
> **依据**：`2026-09-28-ohos-upstream-fork-sync-playbook.md` §2、`2026-09-28-ohos-upstream-rebase-rehearsal.md`、
> `2026-09-21-ohos-pr-drafts.md`（每支的 Title/Body 全文）。
> **上游状态（2026-09-28）**：#132953 OPEN / REVIEW_REQUIRED；#132827 OPEN / APPROVED（hold，不催）；
> 演练基线 `upstream/main = caf6b2a2243`（merge-tree **39/39 CLEAN**；rebase **20/21 CLEAN**，唯一被丢弃的
> `tls-flag-cleanup` 已被 infra 吸收）。`eng/common` 同步依赖的 arcade#17608 已合并。

## 0. 前置检查（逐项过，缺一不开）

1. `gh pr view 132953 -R dotnet/runtime --json state` = `MERGED`。
   未合并前开 N 组会把 12 个 infra 提交算进各支 diff（playbook §2 的既定约束）。
2. `git fetch upstream main`：`upstream/main` 仍是 `caf6b2a2243`？若不是 → 先按演练文档重跑
   （`merge-tree --write-tree upstream/main <ref>` 全量 + 按顺序 rebase 演练），刷新基线后再继续。
3. 同步 `eng/common`（arcade#17608 已合并）；按 playbook 六步流程。
4. C2/C3 需要 **#132866** 的归属答复；未答复则跳过（不影响 N1–N16）。
5. 工作树干净、`pr/*` 本地与 origin 同步（演练方法是只读的，分支本身未动）。

## 1. 顺序、分支与标题（标题即 pr-drafts 的 Title）

| 序 | 支 | 标题 | 前置 |
|---|---|---|---|
| ① | `pr/ohos-infra` | Add OpenHarmony/HarmonyOS build infrastructure（#132953 本体） | #132953 MERGED |
| ② | N1 `pr/ohos-clrfeatures` | coreclr: disable the LTTng event source on OpenHarmony | ① |
| ② | N2 `pr/ohos-pal` | coreclr: PAL build fixes for OpenHarmony | ① |
| ② | N3 `pr/ohos-zstd` | native: use the C90 qsort workaround for zstd on OpenHarmony | ① |
| ② | N4 `pr/ohos-libs-native` | native: skip gssapi on OpenHarmony and use the OpenSSL crypto shim | ① |
| ② | N5 `pr/ohos-apphost` | corehost: singlefilehost fixes for OpenHarmony | ① |
| ② | N14 `pr/ohos-tryrun` | eng/native: pin the OHOS cross-build FIFO probe answers | ① |
| ③ | N7 `pr/ohos-pal-process` | System.Native: avoid close_range on OpenHarmony | ① |
| ③ | N8 `pr/ohos-ifaddrs` | System.Native: read the full ethtool speed on OpenHarmony | ① |
| ③ | N9 `pr/ohos-wx-default` | coreclr: default EnableWriteXorExecute to 0 on OpenHarmony | ① |
| ③ | N10 `pr/ohos-crossgen-corelib` | coreclr: keep the OpenHarmony CoreLib IL-only in-tree and map the crossgen2 target OS | ① |
| ④ | N11 `pr/ohos-aot-unix` | AOT: use lld and the ohos clang ABI on OpenHarmony | ① |
| ④ | N12 `pr/ohos-aot-singleentry` | AOT: map openharmony to linux/musl in the SingleEntry layout | ① |
| ⑤ | N13 `pr/ohos-packs` | packs: wire the OpenHarmony RID into the local pack graphs | ①＋④ |
| ⑥ | N15 `pr/ohos-libs-tfm` | libraries: compile OpenHarmony in the linux/unix TFM groups | ① |
| ⑦ | N16 `pr/ohos-console` | System.Console: use the unix ConsolePal on OpenHarmony | ⑥（堆叠） |
| ⑧ | C2 `pr/ohos-shims-tfm-cleanup` | （drafts 段）| ①＋#132866；若⑥先落需 rebase 到⑥后并去掉与 N15 重复的首提交 |
| ⑧ | C3 `pr/ohos-illink-ntlm` | （drafts 段）| #132866 |

已决丢弃：`pr/ohos-platform-numa`（= 已合并 #134670，patch-id 相同）、
`pr/ohos-tls-flag-cleanup`（已被 infra 的 `8ef4e925163` 吸收）。

## 2. 执行命令（模板）

```sh
# 0) 基线
git fetch upstream main
git merge-tree --write-tree upstream/main pr/ohos-infra >/dev/null   # 预期无输出（CLEAN）

# 1) 逐支 rebase 到 post-infra main。flat 支（N1/N2/... 的 parent 是旧 infra 前缀 cece42439a1）
#    用 --onto 剥离旧前缀；具体 parent 见 rehearsal 文档的逐支表。
for b in pr/ohos-clrfeatures pr/ohos-pal pr/ohos-zstd pr/ohos-libs-native \
         pr/ohos-apphost pr/ohos-tryrun pr/ohos-pal-process pr/ohos-ifaddrs \
         pr/ohos-wx-default pr/ohos-crossgen-corelib pr/ohos-aot-unix \
         pr/ohos-aot-singleentry pr/ohos-packs pr/ohos-libs-tfm pr/ohos-console; do
  git checkout -B "$b" origin/"$b"
  git rebase --onto upstream/main cece42439a1 "$b"   # 真实 parent 以 rehearsal 表为准
  git merge-tree --write-tree upstream/main "$b" >/dev/null || { echo "CONFLICT: $b"; break; }
  git push --force-with-lease origin "$b"            # pr/* 允许强推
done

# 2) 开 PR（标题/正文从 pr-drafts 各段的 **Title:**/**Body:** 抽取）
gh pr create -R dotnet/runtime --base main --head springmin:"$b" \
  --title "<drafts Title>" --body-file "/tmp/body-$b.md"

# 3) 回填：PR 号/tip 写回 pr-drafts 顶部状态表与 playbook §2
```

自动化建议：写 10 行的抽取脚本从 `2026-09-21-ohos-pr-drafts.md` 生成 `/tmp/body-<branch>.md`
（`**Body:**` 之后的代码块），避免手工复制；开 PR 前对每支断言 `merge-tree` 无输出。

## 3. 开完后的看护

- 堆叠约束：N16 依赖 N15；N13 依赖 ①＋④；C2 若晚于 N15 需处理与 N15 的重复首提交。
- 一支一提交、单关注点；评审返工只落在该支并同步堆叠子支。
- 记录：所有 PR 号、tip SHA、CI 状态回填到 pr-drafts 与 playbook（保持单页可追溯）。
