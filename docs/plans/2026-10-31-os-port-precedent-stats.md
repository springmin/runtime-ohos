# OS 平台移植先例完整统计（2026-10-31 重算）

> 本文按 `2026-10-09-os-port-precedent-stats.md` 的口径重算，并新增 **每个平台的首个 PR 时间** 与 **首次官方 release 时间**。
> 数据源：`dotnet/runtime` 全历史（`upstream/main` = `8cf4609a`，2026-10-28；本地 fork HEAD `aca8f5fc`，2026-10-30）+ GitHub PR/label API（2026-10-31）。
> 口径：平台提交用全消息匹配（`git log -i -E --grep`）；作者数 = 非 merge 提交的独立 email；PR(git) = 提交标题中的唯一 `#编号`；label = 已合并且带 `os-*` 标签的 PR。

## 0. 结论速览

- 上游仍为 **0 条 OpenHarmony 提交**；OHOS 仅在 fork 中推进。
- 现役平台走的是“Mono 时代种子 → .NET 统一 → 官方 GA”：Android/iOS/tvOS/Mac Catalyst 于 **.NET 6（2021-11-08）** 获官方支持；s390x 同 .NET 6；ppc64le 于 .NET 7（IBM/Red Hat 口径）。
- 未 GA 但仍在推进：**WASI**（实验）、**RISC-V**、**LoongArch64**，以及社区系 **FreeBSD / OpenBSD / Solaris(illumos) / Haiku**。
- 首 PR 与首提交往往相差多年：Mono/coreclr/corefx 早期没有 PR 编号，本文的“首 PR”是**首个标题含平台名且带 PR 编号的提交**，不等于“引入该平台的 PR”。
- **OHOS 最新**：fork **637** 个 OHOS 相关提交、超出 upstream/main **1,437** 提交、**32 个 dotnet org PR（14 已合）**；严格 OHOS PR 变更 **42,798 行**；无官方 GA，fork 首个 release 为 `v11.0.0-dev-ohos`（2026-08-20）。

---

## 1. 数据来源与口径

### 1.1 快照

- 上游：`dotnet/runtime` `upstream/main` = **`8cf4609a`**（2026-10-28）。
- 本地：`springmin/runtime-ohos` `HEAD` = **`aca8f5fc`**（2026-10-30）。
- 初版快照：`719009ac`（2026-09-03）；本文是其 2026-10-31 重算版。

### 1.2 平台匹配

| 平台 | 匹配模式 |
|---|---|
| Android / iOS / tvOS | `\bandroid\b` / `\bios\b\|\biphone\b\|\bmonotouch\b` / `\btvos\b` |
| Mac Catalyst | `maccatalyst\|mac.?catalyst` |
| Browser/WASM | `\bwasm\b\|\bwebassembly\b` |
| WASI / Tizen | `\bwasi\b` / `\btizen\b` |
| s390x / ppc64le / RISC-V / LoongArch | `\bs390x\b` / `ppc64le\|ppc64el\|powerpc64le` / `\briscv\b\|\brisc-v\b` / `loongarch(64)?` |
| FreeBSD / OpenBSD / NetBSD | `\bfreebsd\b` / `\bopenbsd\b` / `\bnetbsd\b` |
| Solaris / Haiku / AIX / watchOS | `solaris\|illumos\|sunos` / `haiku` / `\baix\b` / `\bwatchos\b` |

误报用 `\b` 词界清洗；全消息匹配会纳入“顺带提及平台”的核心维护者提交，统计的是参与面，不是专职编制。

### 1.3 首提交、首 PR、首次 release

- **首提交**：该平台模式在 `upstream/main` 全历史中最早匹配的提交（按 author date）。
- **首 PR（git）**：该平台最早一个**标题含平台名且含 `#编号`** 的提交关联的 PR；旧编号可能来自 `mono/mono`、`dotnet/coreclr`、`dotnet/corefx`，不一定是 `dotnet/runtime` 的 PR，也不一定是“引入平台”的 PR。
- **首 PR（label）**：GitHub 上该平台 `os-*` 标签下最早创建的 PR；`os-*` 标签本身 2019 年后才普及，因此这个时间**晚于**真实移植起点，仅作交叉核对。
- **首次 release**：该平台首次进入官方 .NET 支持版本的发布日期；未 GA 平台标“未 GA”。
- Tizen 的 release 日期为“2017 年底”，表中用 ≈11 个月近似。

### 1.4 行数/规模口径

- 作者数 = 非 merge 提交的独立 email；同一人多邮箱会多计 1–2 人。
- PR(git) = 提交标题中的唯一 `#编号`；跨仓旧编号可能碰撞，是近似值。
- label = 已合并且带 `os-*` 标签的 PR 数。
- §5 的官方/社区作者归属沿用 2026-10-09 的人工分类，本次未重新做 120 个 noreply 作者的 company 查询。

---

## 2. 完整时间线（首提交 / 首 PR / 首次 release）

| 平台 | 首提交 | 首 PR（git） | 首次 release | 首提交→release | 首 PR→release | 备注 |
|---|---|---|---|---|---|---|
| Windows（基线） | 2014-11-07 `ebabdf94973` | —（基线） | .NET Core 1.0 · 2016-06-27 | 1年7个月 | — | corefx initial；coreclr 2015-01-30 |
| Linux（基线） | 2014-11-07 `ebabdf94973` | —（基线） | .NET Core 1.0 · 2016-06-27 | 1年7个月 | — | 同 corefx initial |
| macOS（基线） | 2014-11-07 `ebabdf94973` | —（基线） | .NET Core 1.0 · 2016-06-27 | 1年7个月 | — | 同 corefx initial |
| Linux Arm32 | 2015-07-24 `0514a157a92` | —（聚合口径） | .NET Core 2.1 · 2018-05-30 | 2年10个月 | — | 2.0 为预览 |
| Linux Arm64 | 2015-11-24 `aeb62228477` | —（聚合口径） | .NET Core 3.0 · 2019-09-23 | 3年10个月 | — |  |
| Windows Arm64 | 2015-05-04 `09143f529b9` | —（聚合口径） | .NET 5 · 2020-11-10 | 5年6个月 | — |  |
| macOS Arm64 | 2020-10-07 `fd094a92cdc` | #40435 · 2020-10-07 | .NET 6 · 2021-11-08 | 1年1个月 | 1年1个月 | Apple Silicon |
| Android | 2009-01-18 `934c9504082` | #6860 · 2012-09-19 | .NET 6 · 2021-11-08 | 12年9个月 | 9年1个月 | Mono 时代起算 |
| iOS | 2008-03-12 `79aeca85342` | #1366 · 2011-11-04 | .NET 6 · 2021-11-08 | 13年8个月 | 10年0个月 | Mono 时代起算 |
| tvOS | 2015-09-24 `1eaab94c6fd` | #2922 · 2016-04-19 | .NET 6 · 2021-11-08 | 6年1个月 | 5年7个月 |  |
| Mac Catalyst | 2020-11-10 `b45a5a504bd` | #44127 · 2020-11-10 | .NET 6 · 2021-11-08 | 1年0个月 | 1年0个月 |  |
| Browser / WASM | 2017-08-21 `ff0c60ee5c1` | #5415 · 2017-08-23 | Blazor WASM 3.2 · 2020-05-19 | 2年9个月 | 2年9个月 | .NET 6 起完整 workload |
| WASI | 2021-10-08 `ce4eb48eb89` | #59752 · 2021-10-08 | 未 GA（`wasi-experimental`） | — | — | 官方注明 not supported |
| Tizen | 2017-01-04 `6f4e2ccbeb5` | #14844 · 2017-01-05 | Tizen 4.0 · 2017 年底 | ≈11个月 | ≈11个月 | 对齐 .NET Core 2.0 |
| Linux s390x | 2004-08-05 `abbbc087cca` | #80507 · 2007-03-16 | .NET 6 · 2021-11-08 | 17年3个月 | 14年8个月 | 现代线 1年9个月 |
| Linux ppc64le | 2014-11-17 `d9a32351129` | #1475 · 2014-12-23 | .NET 7 · 2022-11-08 | 8年0个月 | 7年11个月 | 现代线 5个月 |
| RISC-V | 2018-11-07 `8794c2c0f17` | #11593 · 2018-11-07 | 未 GA | — | — | 进行中 7年11个月 |
| LoongArch64 | 2022-01-07 `c49c65df805` | #62888 · 2022-01-07 | 未 GA | — | — | 进行中 4年9个月 |
| FreeBSD | 2001-08-20 | #74698 · 2005-04-25 | 未 GA（社区构建） | — | — | 现代线 2015-03-16 |
| OpenBSD | 2002-08-24 `3e57aed09d3` | #6358 · 2018-01-08 | 未 GA（社区） | — | — | 现代线 2021-05-25 |
| Solaris / illumos | 2002-02-14 `6098e812ba9` | #2866 · 2016-04-11 | 未 GA（社区） | — | — | 现代线 2020-03-28 |
| Haiku | 2010-03-21 `a3c2ad725d0` | #4373 · 2017-03-01 | 未 GA（社区） | — | — | 现代线 2023-05-17 |
| NetBSD | 2002-09-18 `4bfb643696c` | #798 · 2015-04-24 | 未 GA（Mono 时代） | — | — | 末次 2020 |
| AIX | 2004-05-06 `356cee5f168` | #6677 · 2018-02-05 | 未 GA（Mono 时代） | — | — | 末次 2020 |
| watchOS | 2015-06-16 `ea0a7a5c2aa` | #41393 · 2016-06-01 | 未 GA（.NET 6+ 不支持） | — | — | Mono/Xamarin 时代 |
| OpenHarmony / OHOS | 2026-08-13 `1d7d42ae8ac` | #132827 · 2026-08-27 | 无官方 GA；fork `v11.0.0-dev-ohos` · 2026-08-20 | 7天（fork dev） | — | 上游 0 条 OHOS 提交 |

**说明：**

- Windows/Linux/macOS 是基线平台，首个 PR 不具可比性，标“—”。
- Linux Arm32/Arm64、Windows Arm64 是架构聚合口径，未拆分首 PR。
- Android/iOS 的首提交来自 Mono 时代；它们到 .NET 6 才成为官方支持平台。
- Browser/WASM 的首提交取旧表的 2017-08-21（Wasm 支持）；全消息匹配会命中 2017-06-02 的 NACL 移除提交，不作为 Wasm 起点。
- Browser/WASM 的首个正式 release 取 Blazor WASM 3.2（2020-05-19）；.NET 6 起才是完整 workload。
- 未 GA 平台的“至今”按 2026-10-31 计算；OHOS 无官方 GA，只能列 fork release。`v11.0.0-dev-ohos`（2026-08-20）早于首 PR，是 fork 的 dev release，不是官方支持版本。

## 3. 规模统计（最新）

| 平台 | 提交 | 作者 | PR(git) | 2020+ 提交 | label |
|---|---|---|---|---|---|
| Android | 1,052 | 138 | 882 | 764 | 283 |
| iOS | 856 | 107 | 729 | 660 | 291 |
| tvOS | 279 | 58 | 272 | 262 | 59 |
| Mac Catalyst | 190 | 40 | 195 | 190 | 48 |
| Browser / WASM | 3,403 | 170 | 3,278 | 3,123 | 633 |
| WASI | 310 | 43 | 307 | 310 | 111 |
| Tizen | 156 | 51 | 112 | 34 | 2 |
| Linux s390x | 220 | 43 | 107 | 84 | — |
| Linux ppc64le | 47 | 20 | 39 | 34 | — |
| RISC-V | 305 | 55 | 306 | 300 | — |
| LoongArch64 | 239 | 37 | 258 | 239 | — |
| FreeBSD | 500 | 104 | 291 | 113 | 44 |
| OpenBSD | 115 | 25 | 57 | 45 | 38 |
| NetBSD | 232 | 22 | 113 | 1 | 0 |
| Solaris / illumos | 136 | 30 | 63 | 60 | 13 |
| Haiku | 45 | 10 | 31 | 22 | 16 |
| AIX | 43 | 9 | 37 | 1 | — |
| watchOS | 54 | 16 | 29 | 6 | — |

**最新变化（相对 2026-10-09 快照）：**

- Android：853 → **1,052** 提交；iOS：705 → **856**；Browser/WASM：3,041 → **3,403**；WASI：216 → **310**；OpenBSD：56 → **115**；Haiku：29 → **45**。
- label：Android 281→**283**、iOS 289→**291**、tvOS 57→**59**、Mac Catalyst 47→**48**、Browser 624→**633**、WASI 99→**111**、FreeBSD 43→**44**、Windows 68→**69**；OpenBSD/Haiku/SunOS/NetBSD/macOS/Linux/Tizen 不变。
- 作者数与非 merge 邮箱去重有关，和旧表的“作者数”可能有 ±1–2 差异。

## 4. label 口径首 PR（交叉核对）

| label | 已合并 PR | 最早创建的 PR |
|---|---|---|
| os-android | 283 | #32800 · 2020-02-25 |
| os-ios | 291 | #33740 · 2020-03-18 |
| os-tvos | 59 | #53370 · 2021-05-27 |
| os-maccatalyst | 48 | #52552 · 2021-05-10 |
| os-browser | 633 | #86994 · 2023-06-01 |
| os-wasi | 111 | #67272 · 2022-03-28 |
| os-tizen | 2 | #55987 · 2021-07-20 |
| os-freebsd | 44 | #34000 · 2020-03-24 |
| os-openbsd | 38 | #124774 · 2026-02-24 |
| os-sunos | 13 | #104118 · 2024-06-27 |
| os-haiku | 16 | #86303 · 2023-05-16 |
| os-netbsd | 0 | — |
| os-macos | 91 | #591 · 2019-12-05 |
| os-windows | 69 | #1270 · 2020-01-03 |
| os-linux | 67 | #381 · 2019-11-28 |

> `os-*` 标签最早从 2019 年使用；例如 `os-android` 的最早标签 PR 是 2020-02-25，而 Android 首提交是 2009-01-18。两者不可混为“首 PR”。

## 5. 作者归属（官方 vs 社区，沿用 2026-10-09 分类）

| 口径 | 微软系 | 平台厂商 | 社区 | 机器人/AI | 合计 | 官方占比 |
|---|---:|---:|---:|---:|---:|---:|
| 全历史去重 | 226 (+Mono 49) | 74 | 193 | 6 | **548** | **64%** |
| 现代段（2020+）去重 | 126 (+Mono 9) | 28 | 90 | 5 | **258** | **64%** |

关键平台官方占比（旧分类，方向性参考）：iOS 88%、tvOS 96%、watchOS 100%、Mac Catalyst 88%、Android 73%、Browser 76%、WASI 74%、s390x 83%、ppc64le 80%、Tizen 82%、LoongArch 77%、RISC-V 52%、FreeBSD 62%、OpenBSD 48%、Haiku 50%。

- **厂商主导**：iOS/tvOS/Mac Catalyst/watchOS（微软/Xamarin 系）、s390x（IBM/Sine Nomine）、ppc64le（IBM/Red Hat/SUSE）、Tizen（Samsung）、LoongArch（Loongson）。
- **社区/厂商各半**：RISC-V、OpenBSD、Haiku、FreeBSD。
- **单人/双人驱动**：OpenBSD、Haiku、SunOS 是典型先例；OHOS 目前也是单人/社区驱动。

> 本节是 2026-10-09 的人工分桶结果；本次只更新提交/作者/PR/label，未重新核验新作者的 company 归属。

## 6. OpenHarmony / OHOS 现状

| 指标 | 2026-10-09 | 2026-10-31 |
|---|---:|---:|
| 上游 OHOS 提交 | 0 | **0** |
| fork OHOS 相关提交 | 509 | **637** |
| fork 超出 upstream/main | 1,322 | **1,437** |
| 作者 | 1 | **1**（2 个邮箱） |
| 首笔 OHOS 提交 | 2026-08-26 | **2026-08-13 `1d7d42ae8ac`** |
| 首 PR | #132827（2026-08-27） | **#132827（2026-08-27）** |
| runtime PR 已提/已合 | 3 / 1 | **21 / 11** |
| dotnet org PR 已提/已合 | — | **32 / 14** |
| 严格 OHOS PR 变更 | — | **42,798 行** |
| 全部 upstream PR 变更 | — | **107,645 行** |
| PR 文件数 | — | .NET **172**；全部 **751** |

- **首提交**：2026-08-13 `1d7d42ae8ac`（`build.sh` 增加 linux-ohos target）；**首 PR**：`#132827` 2026-08-27。
- **首次 release**：无官方 GA；fork 首个 release `v11.0.0-dev-ohos` 2026-08-20；后续 `v11.0.0-rc.1.26451.1-ohos`（2026-09-01）等。
- **runtime 首合入**：`#134670`（2026-09-26，平台身份 + NUMA）；`#132953`（build infra）2026-10-14 合入；`#132827` 为 closed（后拆分由 `#135321` 等落地）。
- **规模**：21 个 runtime PR / 52 文件；32 个 dotnet org PR / 172 文件；严格 OHOS PR 42,798 行，全部 upstream PR 107,645 行。

## 7. 结论

1. **官方支持平台的规律**：首提交往往早于首 PR 很多年（Mono 时代没有 PR 编号）；真正“首 PR”更多是后来的修复/构建 PR，不能当作移植起点。首次 official release 才是支持口径的分界线。
2. **社区平台的规律**：OpenBSD/Haiku/SunOS 都是“首提交很早、现代线集中推进、首 PR 很晚、未 GA”的形态；OHOS 目前与它们同构。
3. **OHOS 的位置**：runtime 21 PR / 11 merged，介于 Haiku（label 16）与 OpenBSD（label 38）之间；仍是单作者、无平台厂商投入。上游仍 0 提交。
4. **时间尺度**：Android/iOS 从首提交到 .NET 6 GA 用了 12–14 年；OHOS 从 2026-08-13 开始，目前仅 2.5 个月，仍处于早期。
5. **首 PR/首 release 的意义**：首 PR 是“进入代码评审/社区协作”的时间，首 release 是“官方支持承诺”的时间；两者之间通常还有多年维护。

## 8. 局限

1. **首 PR 口径**：旧 Mono/coreclr/corefx 的 PR 编号无法在 dotnet/runtime 直接解析；首 PR 取“标题含平台名且带 PR 编号的最早提交”，不保证是引入平台的 PR。
2. **label 首 PR**：`os-*` 标签 2019 年后才普及，不能代表真实首 PR；仅用于交叉核对。
3. **作者归属**：官方/社区拆分仍是 2026-10-09 的人工分类；新增作者未重新分桶。
4. **关键词口径**：全消息匹配会纳入“顺带提及平台”的提交；统计的是参与面，不是专职人数。
5. **release 时间**：Tizen 为“2017 年底”近似；Browser 取 Blazor WASM 3.2，而非 .NET 6 workload；OHOS 无官方 GA，只能列 fork release。
6. **快照**：上游 `8cf4609a`（2026-10-28）；fork `aca8f5fc`（2026-10-30）；此后的提交未纳入。

## 附录 A · 复现命令

```bash
REF=upstream/main   # 8cf4609a（2026-10-28）

# 首提交 / 提交数 / 作者数 / PR(git)（示例：OpenBSD）
git log --reverse -i -E --grep='\bopenbsd\b' --format='%h|%ci|%an|%s' $REF | head -1
git rev-list --count -i -E --grep='\bopenbsd\b' $REF
git log --no-merges -i -E --grep='\bopenbsd\b' --format='%ae' $REF | sort -u | wc -l
git log -i -E --grep='\bopenbsd\b' --format='%s' $REF | grep -oE '#[0-9]+' | sort -u | wc -l

# 首 PR（标题含平台名 + #编号）
git log -i -E --grep='\bopenbsd\b' --format='%h|%ci|%s' $REF | grep -E '#[0-9]+' | tail -1

# label 数（已合并）
gh api 'search/issues?q=repo:dotnet/runtime+label:%22os-openbsd%22+is:pr+is:merged&per_page=1' --jq .total_count

# label 首个 PR
gh api 'search/issues?q=repo:dotnet/runtime+label:%22os-openbsd%22+is:pr&sort=created&order=asc&per_page=1' --jq '.items[0] | [.number,.created_at,.title] | @tsv'
```
