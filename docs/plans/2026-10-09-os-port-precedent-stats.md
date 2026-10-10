# OS 平台移植先例统计 — dotnet/runtime git 仓全历史口径（2026-10-09）

> 本文把两轮 git 统计合并为独立文档：
> 1. **时间线/规模**：各 OS 平台移植的开始时间、发布时间、作者数、PR 数、时长；
> 2. **归属拆分**：作者按"官方（微软 / 平台厂商）vs 社区"分开计数。
>
> 与 `2026-09-07-ohos-pr-plan-bsd-haiku-model.md` 附录的 **label 口径**先例统计互为补充——
> 两者口径不同、结论一致，对照见 §5。

**结论速览**

- dotnet/runtime 官方仓**没有 OpenHarmony 移植**（0 条提交）；OHOS 仅存在于本 fork。
- 现役平台都经历了"Mono 时代种子 → .NET 统一 → 官方 GA"：Android/iOS/tvOS/Mac Catalyst 于 **.NET 6（2021-11-08）** 获官方支持；s390x 同 .NET 6；ppc64le 于 .NET 7（IBM/Red Hat 口径，微软 supported-os 自 .NET 8 列出）。
- 未 GA 但仓内仍在推进：**WASI**（实验）、**RISC-V**、**LoongArch64**、以及社区系 **FreeBSD / OpenBSD / Solaris(illumos) / Haiku**。
- 作者归属可区分（约 90% 可靠）：**全历史去重 548 人：官方 349（64%）、社区 193（35%）、机器人/AI 6**。iOS/tvOS/watchOS 官方占 88–100%；s390x/ppc64le/Tizen/LoongArch 为厂商主导（77–83%）；RISC-V、OpenBSD、Haiku 是社区占半数的先例。
- OHOS 现状（1 名社区作者）与 **OpenBSD（am11 + sethjackson）/ Haiku（trungnt2910）** 的单/双人社先例同构；差别在首笔合入速度（见先例表附录）。

---

## 1. 数据来源与口径

### 1.1 仓库与快照

- 仓库：`dotnet/runtime` 全历史。官方仓自 2019 年起合并了 **Mono（2001-06 起）、corefx（2014-11 起）、coreclr（2015-01 起）** 的完整历史（路径重写为 `src/mono/`、`src/libraries/`、`src/coreclr/`），因此 Android/iOS 等可追溯到 Mono 时代。
- 本地副本：`springmin/runtime-ohos`（全量 clone，已用 GitHub API 逐 SHA 核验与官方一致）。
- 统计引用：`main` = `719009ac`（= 上游 main @ **2026-09-03**），已排除本 fork 的 OHOS 提交。

### 1.2 平台匹配

对提交信息做全词匹配（`git log -i -E --grep=...`），模式示例：

| 平台 | 匹配模式 |
|---|---|
| Android / iOS / tvOS | `\bandroid\b` / `\bios\b|\biphone\b|\bmonotouch\b` / `\btvos\b` |
| Mac Catalyst | `maccatalyst\|mac.?catalyst` |
| Browser/WASM | `\bwasm\b\|\bwebassembly\b` |
| WASI / Tizen | `\bwasi\b` / `\btizen\b` |
| s390x / ppc64le / RISC-V / LoongArch | `\bs390x\b` / `ppc64le\|ppc64el\|powerpc64le` / `\briscv\b\|\brisc-v\b` / `loongarch(64)?` |
| FreeBSD / OpenBSD / NetBSD | `\bfreebsd\b` / `\bopenbsd\b` / `\bnetbsd\b` |
| Solaris / Haiku / AIX / watchOS | `solaris\|illumos\|sunos` / `haiku` / `aix` / `watchos` |

误报已用 `\b` 词界清洗（例如 `ohos` 曾误匹配 `NoHostNotification`）。该口径会包含"顺带提及平台"的核心维护者提交，见 §7。

### 1.3 作者与 PR 计数

- **作者数**：不同 Git author 邮箱（上一轮"作者数"为不同姓名且含 merge；本文拆分统一改用 **非 merge 提交 + 邮箱去重**，数值略有差异）。同一人多种邮箱会多计 1–2 人。
- **PR 数（git）**：平台相关提交**标题**中出现的唯一 `#编号`。早期编号来自 mono/coreclr/corefx 各自仓库，跨仓可能碰巧重号，因此是近似值，且是"关联 PR"的上界式估计。
- **PR 数（label）**：GitHub 上 `os-*` 标签的已合并 PR 数（= 先例表口径，含多年维护 PR）。

### 1.4 两种口径的关系

| 口径 | 含义 | 适合回答 |
|---|---|---|
| git 全提交 | 任何提及/触碰该平台的提交 | "历史上谁为这个平台做过事" |
| label `os-*` | 被维护者打上平台标签的 PR | "被承认的专职 PR 工作量"（OpenBSD 38、Haiku 16、SunOS 13、Android 281、iOS 289、macOS 91 …） |

两者**不可直接相加或对比**；本文以 git 口径为主，label 数并列供交叉核对。

---

## 2. 移植时间线总表

### 2.1 官方支持平台

| 平台 | 仓内首次提交 | 首个正式发布 (GA) | 时长 | 作者数 | PR(git) | PR(label) |
|---|---|---|---|---|---|---|
| Windows（基线） | 2014-11-07 `ebabdf94973`（corefx initial；coreclr 2015-01-30） | .NET Core 1.0 · 2016-06-27 | 1年8个月 | —¹ | —¹ | os-windows 68² |
| Linux（基线） | 2014-11-07 同上 | .NET Core 1.0 · 2016-06-27 | 1年8个月 | —¹ | —¹ | os-linux 67² |
| macOS（基线） | 2014-11-07 同上 | .NET Core 1.0 · 2016-06-27 | 1年8个月 | —¹ | —¹ | os-macos 91 |
| Linux Arm32 | 2015-07-24 `0514a157a92`（Ben Pye） | .NET Core 2.1 · 2018-05-30（2.0 为预览） | 2年10个月 | 131³ | 625³ | — |
| Linux Arm64 | 2015-11-24 `aeb62228477`（jashook） | .NET Core 3.0 · 2019-09-23 | 3年10个月 | 269³ | 2799³ | — |
| Windows Arm64 | 2015-05-04 `09143f529b9`（Jan Kotas） | .NET 5 · 2020-11-10 | 5年6个月 | ³ | ³ | — |
| macOS Arm64（Apple Silicon） | 2020-10-07 `fd094a92cdc`（Steve MacLean, #40435） | .NET 6 · 2021-11-08 | 1年1个月 | ³ | ³ | — |
| **Android** | 2009-01-18 `934c9504082`（Zoltan Varga） | .NET 6 · 2021-11-08 | 12年10个月 | 123 | 853 | **281** |
| **iOS** | 2008-03-12 `79aeca85342`（Geoff Norton） | .NET 6 · 2021-11-08 | 13年8个月 | 92 | 705 | **289** |
| **tvOS** | 2015-09-24 `1eaab94c6fd`（Rodrigo Kumpera） | .NET 6 · 2021-11-08 | 6年1个月 | 54 | 261 | **57** |
| **Mac Catalyst** | 2020-11-10 `b45a5a504bd`（#44127） | .NET 6 · 2021-11-08 | 1年 | 35 | 183 | **47** |
| **Browser / WASM** | 2017-08-21 `ff0c60ee5c1`（Rodrigo Kumpera） | Blazor WASM 3.2 · 2020-05-19（.NET 6 起完整工作负载） | 2年9个月 | 148 | 3041 | **624** |
| WASI | 2021-10-08 `ce4eb48eb89`（Zoltan Varga, #59752） | 未 GA（`wasi-experimental`，官方注明 not supported） | 5年（至今） | 38 | 216 | **99** |
| Tizen | 2017-01-04 `6f4e2ccbeb5`（Jiyoung Yun） | Tizen 4.0 · 2017 年底（对齐 .NET Core 2.0） | ≈1年 | 52 | 112 | 2⁴ |
| Linux s390x | 2004-08-05 `abbbc087cca`（Miguel de Icaza） | .NET 6 · 2021-11-08 | 17年3个月（现代线 **1年9个月**）⁵ | 41 | 107 | —⁶ |
| Linux ppc64le | 2014-11-17 `d9a32351129`（Michael Matz） | .NET 7 · 2022-11-08（IBM/Red Hat）；微软 supported-os 自 .NET 8 | 8年（现代线 **5个月**）⁵ | 23 | 40 | —⁶ |

### 2.2 社区 / 实验 / 历史平台

| 平台 | 仓内首次提交 | 发布/状态 | 作者数 | PR(git) | PR(label) |
|---|---|---|---|---|---|
| RISC-V | 2018-11-07 `8794c2c0f17`（Bernhard Urban, mono#11593；coreclr 线 2023-04-08 #82379） | 未 GA（进行中，7年11个月） | 47 | 298 | — |
| LoongArch64 | 2022-01-07 `c49c65df805`（Qiao Pengcheng, #62888） | 未 GA（进行中，4年9个月） | 36 | 249 | — |
| FreeBSD | 2001-08-20（Mono）；现代 2015-03-16（Jan Henke, coreclr#453） | 无官方 GA（社区构建，持续至今 11年7个月） | 111 | 290 | **43** |
| OpenBSD | 2002-08-24（Juli Mallett）；现代 2021-05-25 / 2026-02 起集中推进 | 无官方 GA（社区，进行中） | 26 | 56 | **38** |
| Solaris / illumos | 2002-02-14（Jeffrey Stedfast）；现代 2020-03-28 / 2024-06-27（#104118） | 无官方 GA（社区，进行中） | 31 | 63 | **13** |
| Haiku | 2010-03-21（Andreas Färber）；现代 2023-05-17（#86303） | 无官方 GA（社区，进行中 3年5个月） | 9 | 29 | **16** |
| NetBSD | 2002-09-18（Dick Porter） | Mono 时代；已停滞（末次 2020） | 29 | 113 | 0 |
| AIX | 2004-05-06；实质移植 2018-02（mono#6677） | Mono 时代；已停滞（末次 2020） | 8 | 37 | — |
| watchOS | 2015-06-16（Rolf Bjarne Kvinge） | Mono/Xamarin 时代；2021 后停止（.NET 6+ 未支持） | 16 | 29 | — |
| OpenHarmony | 上游 **0** 条 | 仅本 fork：2026-08-26 起，509 个 OHOS 相关提交、1 位作者；fork 超出 upstream main 共 1,322 提交；已提 3 PR（#132827/#132953 open，#134670 merged） | 1（fork） | — | 3 已提 |

**脚注**

1. 基线平台是参照实现，全仓统计无意义。Unix PAL 移植（Linux/macOS 起步）单独看：1,637 提交 / 206 作者 / 953 PR（2015-01-30 起，`src/coreclr/src/pal`）。
2. `os-windows`/`os-linux` 标签很泛（含日常平台维护），仅供参考。
3. Arm64 系列（Linux/Windows/macOS）合计 3,516 提交 / 269 作者 / 2,799 PR；Arm32 合计 916 / 131 / 625。与主线高度交织，未按细分平台拆分。
4. Tizen 的 `os-tizen` 标签使用不完整（仅 2 个已合并 PR），实际工作多在 `Samsung/Tizen.NET` 仓。
5. 现代线起点：s390x `2020-02-20`（#32591），IBM coreclr 构建支持 `2021-05-26`（#53288）；ppc64le `2022-06-10`（#68806）。
6. s390x/ppc64le/RISC-V/LoongArch 是"Linux 上的架构移植"，没有 `os-*` 标签。

### 2.3 "时长"的含义

- 已 GA 平台：**GA − 仓内首次相关提交**；Mono 遗产会显著拉长数字（s390x 17 年、iOS 13 年 8 个月），括号内的"现代线"才是统一 .NET 后的真实移植窗口。
- 未 GA 平台：**至今（2026-10-09）**，状态标注为实验/社区。
- Android/iOS 的代码在 .NET 5 周期已入主线，但**首个官方支持版本是 .NET 6**（先例表的"代码口径 .NET 5 / 支持口径 .NET 6"与此一致）。

---

## 3. 现代段（2020-01-01 起）统计

用于与 OHOS 当前窗口对照（作者/PR 为 git 口径）：

| 平台 | 现代起点 | 提交 | 作者 | PR(git) |
|---|---|---|---|---|
| Android | 2020-01（#33881 Android 构建配置 2020-03-24） | 734 | 87 | 723 |
| iOS | 2020-02-12（#31953 基础 RID） | 635 | 76 | 624 |
| tvOS | 2020-02-12（#31953） | 249 | 46 | 253 |
| Mac Catalyst | 2020-11-10（#44127） | 177 | 35 | 183 |
| Browser/WASM | 2020-01 | 2,887 | 135 | 2,865 |
| WASI | 2021-10-08 | 219 | 38 | 216 |
| FreeBSD | 2020-01-22（#1602） | 111 | 35 | 108 |
| Linux s390x | 2020-02-20（#32591） | 84 | 22 | 84 |
| Linux ppc64le | 2022-06-10（#68806） | 35 | 16 | 35 |
| RISC-V | 2020-07-30（coreclr 线 2023-04-08 #82379） | 292 | 44 | 294 |
| LoongArch64 | 2022-01-07（#62888） | 229 | 36 | 249 |

---

## 4. 作者归属拆分（官方 vs 社区）

### 4.1 判定方法（三层）

1. **公司邮箱域名**：`microsoft.com`、`ibm.com`、`samsung.com`、`arm.com`、`redhat.com`、`loongson.cn`、`suse.de`、`qualcomm.com`、`sinenomine.net`、`racktopsystems.com`、`xamarin.com`/`novell.com`/`ximian.com`（Mono 历史厂商）等；
2. **GitHub 档案**：120 个 `users.noreply.github.com` 作者逐一查询 `company` 字段；
3. **人工核对**：私人邮箱的重点作者（如 Egor Bogatov、Pavel Savara、Tom Deseyn、Tomasz Sowiński 等）按公开档案/已知归属判定。

分桶：**微软系**（含 Xamarin/Novell/Mono 历史厂商，2016 年后并入微软）、**平台厂商**（IBM/Samsung/Arm/Red Hat/Loongson/SUSE/Qualcomm/Sine Nomine/RackTop 等）、**社区**（未发现平台相关企业归属的个人，即使其雇主与 .NET 无关，如 PNC、OVH）、**机器人·AI**（dotnet-bot、monojenkins、dotnet-maestro、dependabot、github-actions、Copilot）。

> 口径：非 merge 提交、去重邮箱。"官方占比" =（微软系 + 平台厂商）/（合计 − 机器人）；包含"顺带提交"的核心维护者，因此是**参与面**而非专职团队规模。

### 4.2 全历史拆分

| 平台 | 微软系¹ | 平台厂商² | 社区 | 机器人·AI | 合计 | 官方占比 |
|---|---|---|---|---|---|---|
| **全平台去重（总体）** | 226 (+Mono 49) | 74 | 193 | 6 | **548** | **64%** |
| iOS | 86 | 1 | 12 | 3 | 102 | 88% |
| tvOS | 49 | 1 | 2 | 2 | 54 | 96% |
| watchOS | 15 | 0 | 0 | 1 | 16 | 100% |
| Mac Catalyst | 29 | 0 | 4 | 4 | 37 | 88% |
| Android | 93 | 3 | 35 | 3 | 134 | 73% |
| Browser/WASM | 120 | 1 | 39 | 5 | 165 | 76% |
| WASI | 25 | 1 | 9 | 3 | 38 | 74% |
| Linux s390x | 28 | 7 | 7 | 1 | 43 | 83% |
| Linux ppc64le | 7 | 9 | 4 | 1 | 21 | 80% |
| Tizen | 19 | 23 | 9 | 0 | 51 | 82% |
| LoongArch64 | 18 | 9 | 8 | 1 | 36 | 77% |
| RISC-V | 14 | 11 | 23 | 2 | 50 | 52% |
| FreeBSD | 59 | 4 | 38 | 3 | 104 | 62% |
| OpenBSD | 11 | 0 | 12 | 1 | 24 | 48% |
| NetBSD | 11 | 1 | 10 | 0 | 22 | 55% |
| Solaris/illumos | 19 | 2 | 8 | 1 | 30 | 72% |
| Haiku | 4 | 0 | 4 | 0 | 8 | 50% |
| AIX | 5 | 0 | 3 | 1 | 9 | 63% |
| Arm64（Lin/Win/Mac 合计） | 172 | 35 | 66 | 4 | 277 | 76% |
| Arm32（合计） | 85 | 27 | 24 | 1 | 137 | 82% |

¹ 含 Mono/Xamarin/Novell/Ximian 历史厂商人员；² IBM/Samsung/Arm/Red Hat/Loongson/SUSE/Qualcomm/Sine Nomine/RackTop 等。

### 4.3 现代段（2020+）拆分

| 平台 | 微软系 | 平台厂商 | 社区 | 机器人·AI | 合计 | 官方占比 |
|---|---|---|---|---|---|---|
| iOS | 63 | 1 | 11 | 3 | 78 | 85% |
| tvOS | 41 | 1 | 2 | 2 | 46 | 95% |
| Mac Catalyst | 29 | 0 | 4 | 4 | 37 | 88% |
| Android | 65 | 3 | 22 | 3 | 93 | 76% |
| Browser/WASM | 107 | 1 | 34 | 5 | 147 | 76% |
| WASI | 25 | 1 | 9 | 3 | 38 | 74% |
| Linux s390x | 9 | 7 | 6 | 1 | 23 | 73% |
| Linux ppc64le | 5 | 6 | 4 | 1 | 16 | 73% |
| LoongArch64 | 18 | 9 | 8 | 1 | 36 | 77% |
| RISC-V | 11 | 11 | 22 | 2 | 46 | 50% |
| FreeBSD | 21 | 3 | 10 | 2 | 36 | 71% |
| **现代段去重（总体）** | 126 (+Mono 9) | 28 | 90 | 5 | **258** | **64%** |

### 4.4 要点

- **厂商主导型**：iOS/tvOS/MacCatalyst/watchOS（微软/Xamarin 系 88–100%）；s390x（IBM + Sine Nomine）83%；ppc64le（IBM/Red Hat/SUSE）80%；Tizen（Samsung，23 名厂商作者）；LoongArch（Loongson，5 名）。
- **社区/厂商各半**：RISC-V（社区 23 vs 厂商+微软 25）；OpenBSD（社区 48%，驱动者 am11、sethjackson 均为个人）；Haiku（am11、trungnt2910、calvin）；FreeBSD（零散社区 + 微软维护者）。
- **单人/双人驱动**：与该仓先例表一致——OpenBSD 2 人、Haiku 2 人、SunOS 3 人（label 口径）；git 口径的"社区"名单里同样由 1–3 名主力贡献者扛量。
- **AI/机器人作者**：Copilot（GitHub AI；出现在 riscv/loongarch/wasm/android/solaris/freebsd/maccatalyst/wasi）、dotnet-bot、monojenkins、dotnet-maestro、dependabot、github-actions。

---

## 5. 与 label 口径先例表的交叉核对

label 数（本文实测，2026-10-09）与 `2026-09-07` 附录完全吻合：

| 平台 | label | 已合并 PR | 平台 | label | 已合并 PR |
|---|---|---|---|---|---|
| OpenBSD | `os-openbsd` | 38（表：38） | Haiku | `os-haiku` | 16（表：16） |
| SunOS/illumos | `os-SunOS` | 13（表：13） | Android | `os-android` | 281（表：281） |
| iOS | `os-ios` | 289（表：288，+1） | macOS | `os-macos` | 91（表：90，+1） |
| tvOS | `os-tvos` | 57 | Mac Catalyst | `os-maccatalyst` | 47 |
| Browser | `os-browser` | 624 | WASI | `os-wasi` | 99 |
| FreeBSD | `os-freebsd` | 43 | NetBSD | `os-netbsd` | 0 |
| Tizen | `os-tizen` | 2 | 变体 | alpine 1 / mariner 1 / windows-nano 3 / wsl 0 |

结论：**git 口径与 label 口径互相印证**；差异来源见 §1.4。

---

## 6. 对 OHOS 的参照

- **上游 0 条 OHOS 提交**；本 fork：2026-08-26 起 509 个 OHOS 相关提交、**1 名社区作者**（springmin），fork 超出 upstream main 1,322 提交；已提 3 PR（1 已合）。
- 与先例的对应关系：
  - 单/双人社/社区驱动 = OpenBSD（am11 + sethjackson）、Haiku（trungnt2910）、SunOS（gwr）模式；
  - 平台厂商缺位 → 与 RISC-V/LoongArch 的"有厂商投入"路径不同，与 BSD/Haiku 路径相同；
  - 首笔合入速度是当前瓶颈（先例表附录：三先例首笔 0.73/1.33/0.81 天；OHOS #132827 ≈34 天未合、#132953 ≈31 天未合）。
- 规模预估（先例表结论保留）：N1–N16 + SDK S1 + aspnetcore A1 ≈ 20 PR / ≈63 文件，规模介于 SunOS 与 Haiku 之间，远小于 OpenBSD。

---

## 7. 局限与误差来源

1. **关键词口径**：会纳入"顺带提及平台"的核心维护者提交（wasm/Android 的微软作者数因此偏高），也会漏掉完全不提平台名的改动；统计的是"参与面"，不是专职编制。
2. **Mono 时代数据**：Android/iOS/tvOS 的早期提交来自 mono/mono 迁移历史，当时的"官方"是 Novell/Xamarin（本文计入微软系¹并单独标注）。
3. **个人邮箱归属**：靠 GitHub `company` 字段 + 人工判定，个例存疑（如 kg、biosciencenow、robertj 等按公开档案判定为微软系，可能有误；s390x 近期几名未标注公司的贡献者可能属于 IBM 团队，未计入厂商）。
4. **邮箱去重 ≠ 人物去重**：同一人多邮箱（Jay Krell、Filip Navara、Ludovic Henry、Neale Ferguson 等）会各多计 1 人；每平台影响 ±1–2。
5. **PR 编号跨仓碰撞**：`#1234` 可能同时存在于 mono 与 runtime，去重时按同一号处理（罕见，影响微小）。
6. **快照时间**：2026-09-03（main），此后上游提交未纳入；社区/历史平台的"至今"按 2026-10-09 计算。

---

## 附录 A · 复现方法

```bash
# 0) 引用
REF=main        # 719009ac（上游 main @ 2026-09-03）

# 1) 平台首次提交 / 提交数 / 作者数 / PR 数（示例：s390x）
git log --reverse -i -E --grep='\bs390x\b' --format='%h|%ci|%an|%s' $REF | head -1
git rev-list --count -i -E --grep='\bs390x\b' $REF
git log -i -E --grep='\bs390x\b' --format='%an' $REF | sort -u | wc -l
git log -i -E --grep='\bs390x\b' --format='%s' $REF | grep -oE '#[0-9]+' | sort -u | wc -l

# 2) 现代段（2020+）
git rev-list --count -i -E --grep='\bs390x\b' --since=2020-01-01 $REF

# 3) 作者归属拆分（非 merge、去重邮箱）
git log --no-merges -i -E --grep='\bs390x\b' --format='%ae|%an' $REF | sort -u

# 4) label 口径
gh api 'search/issues?q=repo:dotnet/runtime+label:%22os-openbsd%22+is:pr+is:merged&per_page=1' --jq .total_count
```

## 附录 B · 原始数据文件（本机临时目录，用于审计）

`/data/storage/el2/base/tmp/opencode/`

| 文件 | 内容 |
|---|---|
| `ps-*.txt` | 各平台全历史统计（提交/作者/PR + 首末提交） |
| `era-*.txt` | 各平台 2020+ 统计 |
| `auth-*.txt` / `auth20-*.txt` | 各平台作者邮箱清单（全历史 / 2020+） |
| `classified-details.txt` | 每个作者的分桶结果（18 个平台，`桶\|姓名 <邮箱>`） |
| `noreply-profiles.txt` | 120 个 noreply 作者的 GitHub 档案（company） |
| `classify-authors.sh` / `dump-authors*.sh` | 分类与提取脚本 |
