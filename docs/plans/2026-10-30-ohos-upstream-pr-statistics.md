# OpenHarmony / .NET 上游 PR 代码量统计（2026-10-30）

> 统计对象：GitHub 用户 `springmin` 提交到**非自有仓库**的 PR。
> 数据源：GitHub PR API（`additions` / `deletions`），通过 `gh` 读取；统计时间 **2026-10-30**。
> 口径：**变更行数 = additions + deletions**。包含测试、文档、生成文件；不等同于“纯手写生产代码行数”。
>
> **2026-11-02 更新**：§10 增加按仓库拆分（含自有 fork）；§0–§9 仍为 2026-10-30 上游快照。

## 0. 结论摘要

- **全部上游：62 个 PR，99,765 行新增 / 7,880 行删除，合计 107,645 行变更。**
- **已合并：24 个 PR，63,366 行变更（+57,323/−6,043）。**
- **open：16 个 PR，40,428 行；closed：22 个 PR，3,851 行。**
- **.NET 社区：32 个 PR，6,144 行变更（+6,029/−115）。**
- **dotnet/runtime：21 个 PR，895 行变更；其中已合并 11 个，277 行。**
- **`flectar/mail` 一项占 80,235 行（约 74.5%）；排除它后，剩余 53 个上游 PR 合计 27,410 行。**

## 1. 统计范围与口径

### 1.1 纳入

- GitHub 上 `springmin` 提交到**非自有仓库**的 PR；
- 包括 .NET 社区和 non-.NET 社区：
  - `dotnet/runtime`、`dotnet/sdk`、`dotnet/aspnetcore`、`dotnet/msbuild`、`dotnet/arcade`、`dotnet/docs`、`dotnet/dotnet-buildtools-prereqs-docker`
  - `duckdb/duckdb`、`duckdb/duckdb-web`
  - `flectar/mail`
  - `hqzing/ohos-selfsign`
  - `linebender/parley`
  - `oven-sh/bun`
  - `RightNow-AI/openfang`
- 包含 merged / open / closed 三种状态；closed 包含未合并、被替代或关闭的 PR。

### 1.2 排除

- `springmin/*` 自有 fork 的 PR（7 个）：
  - `springmin/bun` 2 个
  - `springmin/maui-ohos` 3 个
  - `springmin/nopCommerce` 2 个
- 因此 GitHub 上 `springmin` 的 PR 总数为 **69**，其中上游 **62** + 自有 fork **7**。

### 1.3 行数口径

- **新增** = PR 的 `additions`
- **删除** = PR 的 `deletions`
- **变更行数** = `additions + deletions`
- 该口径包含测试、文档、生成文件；纯生产代码行数会低一些。
- .NET 部分可进一步按文件路径排除 `docs/`、`*.md`、`tests/`、`test/`，得到约 **5,479 行**非文档/非测试代码；全体非 .NET 部分未给出精确纯代码口径，避免大型 PR 文件列表截断造成误导。

## 2. 总表

| 范围 | PR 数 | 新增 | 删除 | 变更行数 |
|---|---:|---:|---:|---:|
| **全部上游** | **62** | **99,765** | **7,880** | **107,645** |
| 已合并 | 24 | 57,323 | 6,043 | **63,366** |
| 开放中 | 16 | 39,138 | 1,290 | **40,428** |
| 已关闭 | 22 | 3,304 | 547 | **3,851** |

## 3. 按项目拆分

| 项目 | PR 数 | 新增 | 删除 | 变更行数 |
|---|---:|---:|---:|---:|
| dotnet/（.NET 社区） | 32 | 6,029 | 115 | **6,144** |
| flectar/mail | 9 | 74,251 | 5,984 | **80,235** |
| oven-sh/bun | 10 | 14,266 | 1,481 | **15,747** |
| duckdb（duckdb + duckdb-web） | 4 | 2,604 | 5 | **2,609** |
| hqzing/ohos-selfsign | 5 | 1,423 | 283 | **1,706** |
| RightNow-AI/openfang | 1 | 1,183 | 10 | **1,193** |
| linebender/parley | 1 | 9 | 2 | **11** |
| **合计** | **62** | **99,765** | **7,880** | **107,645** |

## 4. .NET 社区细分

| 仓库 | PR 数 | 新增 | 删除 | 变更行数 |
|---|---:|---:|---:|---:|
| dotnet/runtime | 21 | 820 | 75 | **895** |
| dotnet/sdk | 5 | 4,512 | 30 | **4,542** |
| dotnet/aspnetcore | 1 | 33 | 3 | **36** |
| dotnet/msbuild | 1 | 9 | 1 | **10** |
| dotnet/arcade | 2 | 36 | 6 | **42** |
| dotnet/docs | 1 | 114 | 0 | **114** |
| dotnet/dotnet-buildtools-prereqs-docker | 1 | 505 | 0 | **505** |
| **.NET 合计** | **32** | **6,029** | **115** | **6,144** |

### 4.1 dotnet/runtime

- 21 个 PR，820 行新增 / 75 行删除，合计 **895** 行变更。
- 已合并 11 个，**277** 行变更（+222/−55）。
- 其余为 open/closed；其中包含早期 closed 的 sandbox/fix 分支和后续拆分的 PR。

## 5. 状态分布

| 状态 | PR 数 | 新增 | 删除 | 变更行数 |
|---|---:|---:|---:|---:|
| merged | 24 | 57,323 | 6,043 | **63,366** |
| open | 16 | 39,138 | 1,290 | **40,428** |
| closed | 22 | 3,304 | 547 | **3,851** |
| **合计** | **62** | **99,765** | **7,880** | **107,645** |

## 6. 变更量最大的 10 个 PR

| # | PR | 状态 | 新增 / 删除 | 变更 |
|---:|---|---|---:|---:|
| 1 | [flectar/mail#76](https://github.com/flectar/mail/pull/76) | merged | 53,382 / −3,504 | **56,886** |
| 2 | [flectar/mail#85](https://github.com/flectar/mail/pull/85) | open | 17,101 / −6 | **17,107** |
| 3 | [oven-sh/bun#30917](https://github.com/oven-sh/bun/pull/30917) | open | 13,789 / −1,239 | **15,028** |
| 4 | [flectar/mail#84](https://github.com/flectar/mail/pull/84) | merged | 2,345 / −1,844 | **4,189** |
| 5 | [dotnet/sdk#56760](https://github.com/dotnet/sdk/pull/56760) | open | 2,271 / −1 | **2,272** |
| 6 | [dotnet/sdk#56735](https://github.com/dotnet/sdk/pull/56735) | open | 1,864 / −0 | **1,864** |
| 7 | [duckdb/duckdb#27884](https://github.com/duckdb/duckdb/pull/27884) | open | 1,313 / −2 | **1,315** |
| 8 | [RightNow-AI/openfang#821](https://github.com/RightNow-AI/openfang/pull/821) | closed | 1,183 / −10 | **1,193** |
| 9 | [duckdb/duckdb#27882](https://github.com/duckdb/duckdb/pull/27882) | open | 1,178 / −2 | **1,180** |
| 10 | [flectar/mail#150](https://github.com/flectar/mail/pull/150) | merged | 457 / −503 | **960** |

## 7. 不同统计口径

| 口径 | PR 数 | 变更行数 | 说明 |
|---|---:|---:|---|
| 全部上游 | 62 | **107,645** | 含 .NET + non-.NET + 测试/文档 |
| 已合并 | 24 | **63,366** | 仅 merged |
| .NET 社区 | 32 | **6,144** | dotnet org 的 7 个仓库 |
| dotnet/runtime | 21 | **895** | runtime 单仓 |
| 排除 flectar/mail | 53 | **27,410** | 去掉占比最大的邮件项目 |

## 8. 逐 PR 明细

### dotnet/runtime（21 PR，+820/−75，变更 895）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#132827](https://github.com/dotnet/runtime/pull/132827) | closed | 15 | 1 | 16 | Use the process temp directory for shared memory on OpenHarmony |
| [#132953](https://github.com/dotnet/runtime/pull/132953) | merged | 123 | 15 | 138 | Add OpenHarmony/HarmonyOS build infrastructure |
| [#134670](https://github.com/dotnet/runtime/pull/134670) | merged | 19 | 5 | 24 | Add OpenHarmony platform identity and exclude unsupported NUMA calls |
| [#135321](https://github.com/dotnet/runtime/pull/135321) | merged | 2 | 2 | 4 | Skip robust mutexes on OpenHarmony |
| [#135808](https://github.com/dotnet/runtime/pull/135808) | merged | 2 | 3 | 5 | coreclr: disable the LTTng event source on OpenHarmony |
| [#135838](https://github.com/dotnet/runtime/pull/135838) | merged | 2 | 2 | 4 | coreclr: PAL build fixes for OpenHarmony |
| [#135839](https://github.com/dotnet/runtime/pull/135839) | merged | 2 | 2 | 4 | native: use the C90 qsort workaround for zstd on OpenHarmony |
| [#135840](https://github.com/dotnet/runtime/pull/135840) | closed | 8 | 0 | 8 | native: skip gssapi on OpenHarmony and use the OpenSSL crypto shim |
| [#135863](https://github.com/dotnet/runtime/pull/135863) | merged | 13 | 6 | 19 | corehost: singlefilehost fixes for OpenHarmony |
| [#135866](https://github.com/dotnet/runtime/pull/135866) | closed | 4 | 0 | 4 | System.Native: read the full ethtool speed on OpenHarmony |
| [#136131](https://github.com/dotnet/runtime/pull/136131) | merged | 4 | 2 | 6 | coreclr: default EnableWriteXorExecute to 0 on OpenHarmony |
| [#136132](https://github.com/dotnet/runtime/pull/136132) | closed | 5 | 0 | 5 | eng/native: pin the OHOS cross-build FIFO probe answers |
| [#136185](https://github.com/dotnet/runtime/pull/136185) | merged | 24 | 17 | 41 | OpenHarmony: NativeAOT and pack integration |
| [#136186](https://github.com/dotnet/runtime/pull/136186) | closed | 24 | 3 | 27 | libraries: OpenHarmony TFM groups and console support |
| [#136187](https://github.com/dotnet/runtime/pull/136187) | closed | 171 | 8 | 179 | System.Native: avoid close_range on OpenHarmony |
| [#136194](https://github.com/dotnet/runtime/pull/136194) | open | 132 | 8 | 140 | native: OpenHarmony native library fixes |
| [#136198](https://github.com/dotnet/runtime/pull/136198) | merged | 6 | 1 | 7 | coreclr: check the GC barrier code page commit |
| [#136206](https://github.com/dotnet/runtime/pull/136206) | open | 178 | 0 | 178 | CI: add an OpenHarmony arm64 build leg |
| [#136211](https://github.com/dotnet/runtime/pull/136211) | closed | 21 | 0 | 21 | CoreLib: accept LINUX as a platform-name alias on OpenHarmony |
| [#136212](https://github.com/dotnet/runtime/pull/136212) | merged | 25 | 0 | 25 | minipal: fail early when the double-mapping backing file cannot be made executable |
| [#136354](https://github.com/dotnet/runtime/pull/136354) | closed | 40 | 0 | 40 | Add a conditional regression test for high-speed NetworkInterface.Speed |

### dotnet/sdk（5 PR，+4,512/−30，变更 4,542）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#56732](https://github.com/dotnet/sdk/pull/56732) | open | 24 | 2 | 26 | RID graphs: add the openharmony RID and the crossgen2 mapping |
| [#56733](https://github.com/dotnet/sdk/pull/56733) | open | 72 | 15 | 87 | OpenHarmony: build the SDK without installers, workloads or NativeAOT |
| [#56735](https://github.com/dotnet/sdk/pull/56735) | open | 1,864 | 0 | 1,864 | OpenHarmony: add the ELF signer and dotnet selfsign |
| [#56760](https://github.com/dotnet/sdk/pull/56760) | open | 2,271 | 1 | 2,272 | OpenHarmony: sign build and publish outputs |
| [#56761](https://github.com/dotnet/sdk/pull/56761) | open | 281 | 12 | 293 | OpenHarmony: apply the sandbox defaults to the SDK tools |

### dotnet/aspnetcore（1 PR，+33/−3，变更 36）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#69952](https://github.com/dotnet/aspnetcore/pull/69952) | open | 33 | 3 | 36 | Add the openharmony RIDs and skip repo-side NativeAOT for openharmony |

### dotnet/msbuild（1 PR，+9/−1，变更 10）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#15342](https://github.com/dotnet/msbuild/pull/15342) | merged | 9 | 1 | 10 | Treat OpenHarmony as Unix-like in MSBuild |

### dotnet/arcade（2 PR，+36/−6，变更 42）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#17608](https://github.com/dotnet/arcade/pull/17608) | merged | 34 | 5 | 39 | Add OpenHarmony support to eng/common |
| [#17723](https://github.com/dotnet/arcade/pull/17723) | merged | 2 | 1 | 3 | Reject OpenHarmony in NativeAotSupported.props |

### dotnet/docs（1 PR，+114/−0，变更 114）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#56529](https://github.com/dotnet/docs/pull/56529) | open | 114 | 0 | 114 | Add NETSDK1247-NETSDK1250 docs for OpenHarmony code signing |

### dotnet/dotnet-buildtools-prereqs-docker（1 PR，+505/−0，变更 505）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#1786](https://github.com/dotnet/dotnet-buildtools-prereqs-docker/pull/1786) | open | 505 | 0 | 505 | Add an OpenHarmony cross-compilation image |

### duckdb/duckdb（2 PR，+2,491/−4，变更 2,495）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#27882](https://github.com/duckdb/duckdb/pull/27882) | open | 1,178 | 2 | 1,180 | Add OpenHarmony (arm64) build support |
| [#27884](https://github.com/duckdb/duckdb/pull/27884) | open | 1,313 | 2 | 1,315 | Add OpenHarmony cross-compilation CI |

### duckdb/duckdb-web（2 PR，+113/−1，变更 114）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#7561](https://github.com/duckdb/duckdb-web/pull/7561) | merged | 78 | 1 | 79 | Document building DuckDB for OpenHarmony |
| [#7600](https://github.com/duckdb/duckdb-web/pull/7600) | merged | 35 | 0 | 35 | Add OpenHarmony to DuckDB Everywhere |

### flectar/mail（9 PR，+74,251/−5,984，变更 80,235）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#76](https://github.com/flectar/mail/pull/76) | merged | 53,382 | 3,504 | 56,886 | fix: stop doubling Sent copies on servers that auto-save |
| [#79](https://github.com/flectar/mail/pull/79) | merged | 255 | 26 | 281 | fix: escalate the content-fetch retry backoff |
| [#80](https://github.com/flectar/mail/pull/80) | merged | 257 | 32 | 289 | refactor: route external links through a platform opener seam |
| [#84](https://github.com/flectar/mail/pull/84) | merged | 2,345 | 1,844 | 4,189 | documents: route attachments, backups and snapshots through the host provider |
| [#85](https://github.com/flectar/mail/pull/85) | open | 17,101 | 6 | 17,107 | ohos: add the OpenHarmony platform host |
| [#139](https://github.com/flectar/mail/pull/139) | open | 216 | 0 | 216 | feat: add a notification publisher seam |
| [#150](https://github.com/flectar/mail/pull/150) | merged | 457 | 503 | 960 | fix: import certificates through the document provider |
| [#151](https://github.com/flectar/mail/pull/151) | merged | 228 | 59 | 287 | fix: keep picked file names |
| [#152](https://github.com/flectar/mail/pull/152) | merged | 10 | 10 | 20 | fix: update pulldown-cmark for RUSTSEC-2026-0414 |

### hqzing/ohos-selfsign（5 PR，+1,423/−283，变更 1,706）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#1](https://github.com/hqzing/ohos-selfsign/pull/1) | closed | 56 | 30 | 86 | 修复段表未覆盖的尾部数据被丢弃，并支持可变 e_shentsize |
| [#2](https://github.com/hqzing/ohos-selfsign/pull/2) | closed | 149 | 127 | 276 | 把尾部数据与 e_shentsize 修复同步到 C/Go/JS/Python 实现 |
| [#3](https://github.com/hqzing/ohos-selfsign/pull/3) | closed | 262 | 114 | 376 | 写入 merkle 树中间层哈希，对齐 binary-sign-tool 的 .codesign 段布局 |
| [#4](https://github.com/hqzing/ohos-selfsign/pull/4) | closed | 295 | 12 | 307 | 新增 --check：校验自签名有效性（五个实现 CLI 一致） |
| [#5](https://github.com/hqzing/ohos-selfsign/pull/5) | closed | 661 | 0 | 661 | 新增 C# 实现（selfsign.cs，来源 dotnet/sdk-ohos 的独立签名器） |

### linebender/parley（1 PR，+9/−2，变更 11）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#913](https://github.com/linebender/parley/pull/913) | merged | 9 | 2 | 11 | fontique: use the dummy system backend on HarmonyOS (OpenHarmony-based) |

### oven-sh/bun（10 PR，+14,266/−1,481，变更 15,747）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#30038](https://github.com/oven-sh/bun/pull/30038) | closed | 80 | 73 | 153 | fix(JSType.zig): add missing JSScriptFetcher(23) and JSScriptFetchParameters(24) |
| [#30315](https://github.com/oven-sh/bun/pull/30315) | closed | 201 | 83 | 284 | fix(node:os): add ARM CPU model decoder and improve /proc/cpuinfo parsing |
| [#30316](https://github.com/oven-sh/bun/pull/30316) | closed | 1 | 0 | 1 | fix(Blob): preserve nested array elements in fromJS |
| [#30343](https://github.com/oven-sh/bun/pull/30343) | closed | 70 | 12 | 82 | fix(spawn): use __NR_exit_group feature check and add vfork→fork fallback |
| [#30914](https://github.com/oven-sh/bun/pull/30914) | closed | 14 | 6 | 20 | fix(resolver): add PermissionDenied/EPERM/EACCES to directory read error handling |
| [#30915](https://github.com/oven-sh/bun/pull/30915) | closed | 12 | 56 | 68 | build: remove unused .zig codegen outputs |
| [#30916](https://github.com/oven-sh/bun/pull/30916) | closed | 19 | 2 | 21 | fix(sys): handle EACCES from fstat on socketpair fds |
| [#30917](https://github.com/oven-sh/bun/pull/30917) | open | 13,789 | 1,239 | 15,028 | feat: add initial HarmonyOS (OHOS) support |
| [#33407](https://github.com/oven-sh/bun/pull/33407) | closed | 13 | 10 | 23 | fix(decorators): evaluate member decorator expressions before class decorators |
| [#37277](https://github.com/oven-sh/bun/pull/37277) | open | 67 | 0 | 67 | fix(cli): support 'bun node <file>' — node emulation via argv[1] |

### RightNow-AI/openfang（1 PR，+1,183/−10，变更 1,193）

| PR | 状态 | 新增 | 删除 | 变更 | 标题 |
|---|---|---:|---:|---:|---|
| [#821](https://github.com/RightNow-AI/openfang/pull/821) | closed | 1,183 | 10 | 1,193 | feat(channels): add WeChat Personal channel adapter |


## 9. 备注

- `flectar/mail` 是第三方邮件项目，9 个 PR 合计 **80,235** 行，占全部上游变更的 **74.5%**；其中 `#76` 单个 PR 就有 **56,886** 行变更。
- `oven-sh/bun` 的 10 个 PR 合计 **15,747** 行；其中 `#30917`（HarmonyOS/OHOS 支持）单个 **15,028** 行。
- `dotnet/sdk` 的 5 个 PR 合计 **4,542** 行，主要由签名相关 PR `#56760`（2,272）和 `#56735`（1,864）贡献。
- 行数来自 GitHub PR 元数据；如果后续 PR 继续提交/更新，本文数字会变化。
- 本文为本地统计文档，未自动加入 `docs/plans/README.md` 索引，也未提交到 git。

## 10. 按仓库拆分（2026-11-02 更新）

> 数据源：GitHub PR API（`additions` / `deletions`），2026-11-02。
> 包含自有 fork；`全部` = merged + open + closed；`已合入` = merged。
> 行数包含测试/文档/生成文件。

| 仓库 | 类型 | 全部 PR | 全部新增 | 全部删除 | 全部变更 | 已合入 PR | 已合入新增 | 已合入删除 | 已合入变更 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| dotnet/runtime | 上游 | 21 | 820 | 75 | 895 | 11 | 222 | 55 | 277 |
| dotnet/sdk | 上游 | 5 | 4,512 | 30 | 4,542 | 0 | 0 | 0 | 0 |
| dotnet/aspnetcore | 上游 | 1 | 33 | 3 | 36 | 0 | 0 | 0 | 0 |
| dotnet/msbuild | 上游 | 1 | 9 | 1 | 10 | 1 | 9 | 1 | 10 |
| dotnet/arcade | 上游 | 2 | 36 | 6 | 42 | 2 | 36 | 6 | 42 |
| dotnet/docs | 上游 | 1 | 114 | 0 | 114 | 0 | 0 | 0 | 0 |
| dotnet/dotnet-buildtools-prereqs-docker | 上游 | 1 | 505 | 0 | 505 | 0 | 0 | 0 | 0 |
| duckdb/duckdb | 上游 | 2 | 2,491 | 4 | 2,495 | 0 | 0 | 0 | 0 |
| duckdb/duckdb-web | 上游 | 2 | 113 | 1 | 114 | 2 | 113 | 1 | 114 |
| flectar/mail | 上游 | 11 | 74,377 | 6,021 | 80,398 | 8 | 74,063 | 5,987 | 80,050 |
| hqzing/ohos-selfsign | 上游 | 5 | 1,423 | 283 | 1,706 | 0 | 0 | 0 | 0 |
| linebender/parley | 上游 | 1 | 9 | 2 | 11 | 1 | 9 | 2 | 11 |
| oven-sh/bun | 上游 | 10 | 14,266 | 1,481 | 15,747 | 0 | 0 | 0 | 0 |
| RightNow-AI/openfang | 上游 | 1 | 1,183 | 10 | 1,193 | 0 | 0 | 0 | 0 |
| springmin/bun | 自有 fork | 2 | 999,995 | 4,987 | 1,004,982 | 1 | 999,981 | 4,981 | 1,004,962 |
| springmin/maui-ohos | 自有 fork | 3 | 125 | 48 | 173 | 3 | 125 | 48 | 173 |
| springmin/nopCommerce | 自有 fork | 2 | 142,403 | 100,320 | 242,723 | 0 | 0 | 0 | 0 |
| **上游合计** | 上游 | **64** | **99,891** | **7,917** | **107,808** | **25** | **74,452** | **6,052** | **80,504** |
| **自有合计** | 自有 fork | **7** | **1,142,523** | **105,355** | **1,247,878** | **4** | **1,000,106** | **5,029** | **1,005,135** |
| **全部合计** | — | **71** | **1,242,414** | **113,272** | **1,355,686** | **29** | **1,074,558** | **11,081** | **1,085,639** |

**要点：**

- **上游 64 个 PR**：25 merged / 17 open / 22 closed；**107,808 行变更**。
- **自有 fork 7 个 PR**：4 merged / 0 open / 3 closed；**1,247,878 行变更**，但主要来自导入/同步型 PR。
- 异常大 PR：`springmin/bun#5`（+999,981）、`springmin/nopCommerce#11`（+120,972/−87,383）、`#12`（+21,431/−12,937）。剔除这 3 个后：**68 个 PR，108,001 行变更；已合入 28 个，80,677 行**。
- `flectar/mail` 最新为 **11 个 PR / 80,398 行**（8 merged / 3 open）；`#85` 已合入，新增 `#162`/`#163` 两个 OHOS PR。
- `dotnet/sdk` 5 个 PR 仍全部 open；`dotnet/runtime` 21 个 PR 中 11 个已合入。
