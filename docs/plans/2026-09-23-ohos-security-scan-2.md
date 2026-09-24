# 五仓 OpenHarmony 移植安全扫描 #2（2026-09-23）

**范围：** `runtime-ohos`、`aspnetcore-ohos`、`ohos-workload`、`maui-ohos`、`sdk-ohos`。
**上一轮：** [`2026-09-21-ohos-security-scan.md`](2026-09-21-ohos-security-scan.md)（A1–A8、B1–B7、C1–C8 共 23 条全部解决）。
**性质：** 只读静态审阅 + 离线 toy/stub/mock 复现 + 修复提交核对；本报告写入时重跑了 3 个纯离线测试（无网络、无设备、无仓库写入）。

## Verdict

**PASS WITH FINDINGS（16/16 已修）。** 本轮 3+2 猎手结构共产生 **16 条**新候选（A1–A3、MB-1–MB-3、H-C1–H-C3、D-1–D-6、D 系列补扫的 C3），**16 条已修复**：H-C3 按低/加固策略修复（TLS shim 改绝对路径 `dlopen` + 静态链接开关），其余 15 条如前。5 份独立 PoC 对抗复核：D-1、H-C1、A1、A2、A3 均为 **Reproduced**；H-C2 判定逻辑缺陷 **Reproduced**（端到端依赖 ArkWeb 交付语义，设备未验证，严重度由中降为低/加固）；H-C3 构建/二进制级 **Reproduced**。上轮 23 条逐条复核：**21 条保持有效、B5 保持有效但符号改名（`IsSafeRelativePath` → `IsSafeAssetLayoutPart`）、B6 出现新变种（H-C2）且已修复**。

| 指标 | 数值 |
|---|---|
| 本轮候选 | 16（高 1 · 中 6 · 低/加固 9） |
| 已修复 | 16（含 H-C2 三维:壳 + managed + abc 重建；H-C3 绝对路径 dlopen + 静态链接开关） |
| 文档化决策（未修） | 0 —— H-C3 已按文档化策略修复 |
| 部分修复（进行中） | 无 —— MB-2 宿主侧已收口（`9256305` 守卫 + `92f7555` pin，315 项全过） |
| PoC 报告 | 5 份（poc-a/b/c/d + sec-d/e 内置复现），全部 Reproduced 或 Unsafe-to-run |
| 上轮复核 | 23/23（21 有效 + B5 改名 + B6 新变种 H-C2 已修） |

**设备状态：** 所有修复均未上机（设备安装受组织策略限制）；设备可见结论一律标注设备未验证。

**发布：** kit #21（`device-test-kit`，2026-09-24；headless abc `13.0.1.0` + tester-run v6r2；壳/宿主/脚本 = `ohos-workload master`，托管面 = `maui-ohos 236d18a9`）已含全部修复；首轮修复随 kit #18/#19 出包（壳/宿主/脚本 = `ohos-workload 49cd70f3d1..2857837`，托管面 = `maui-ohos c730226f93`）；`sdk-ohos` 的安装器/签名加固随 sdk 分支及其 release 链发布。此后 **kit #22**（2026-09-24，设备里程碑回灌：宿主按需 dlsym、`resources.index`、ZIP/mkdir、DevEco 工程布局）交付且仍未上机（当前已推进至 **kit #24**，payload-in-libs；见 `2026-09-22-ohos-release-manifest.md`），里程碑见 `2026-09-24-ohos-device-milestone.md`。
**#19–#21 追加修复：** headless abc `24.0.0.0` → `13.0.1.0`（`ohos-workload 4e5491d`）、workload bundle 外锚（`WORKLOAD_BUNDLE_SHA256`，`sdk-ohos/eng/ohos-install/versions.env`）、TLS H-C3（`3d1f6e45102`/`cfdba659d11`/`d7b730e5030`）等已随 kit #19–#21 发布或入库。

## 范围（五仓 + 对上游 delta）

| 仓库 | 分支 | 对上游 delta（扫描时） | 本轮提交 |
|---|---|---|---|
| `runtime-ohos` | `feature/openharmony` | 69 commits（窗口 delta；另有上游继承提交未审） | 扫描窗口无安全代码变更（仅文档/审计记录）；后随修复 `3d1f6e45102`/`cfdba659d11`/`d7b730e5030`（H-C3 + H3 探测） |
| `aspnetcore-ohos` | `feature/openharmony` | 8 files vs upstream | 无（RID/打包/TFM 接线，无运行时安全代码） |
| `ohos-workload` | `master` | 75 commits（窗口 delta） | `46b4e0f`(FIX-P1 宿主性能，兼修 effects/present/图片) `d43dfb5`/`195dd3e`(slice pin) `81b9264`(A1) `0bb7119`(H-C2 壳) `4b74c4c`(A2) `683162a`(A3) `1063374`(H-C2 abc 重建) |
| `maui-ohos` | `feature/openharmony` | 34 commits（窗口 delta） | `8e4de06f`(FIX-P2 托管性能) `c730226f93`(MB-1/MB-2/MB-3/H-C2 managed) |
| `sdk-ohos` | `feature/openharmony` | 215 commits / 84 files vs upstream（扫描时） | `b3f5afa293`(D-1/D-2/D-3/D-5/D-6/C3) `7f820be9b0`(D-4) `690134e706`(H-C1)；修复后 delta = 218 commits / 86 files |

## 方法

- **猎手（3+2）。** A：宿主/原生/构建-发布链（`ohos-workload/src/OpenHarmonyHost/**`、packs 模板、Hosting、19 个脚本、`sdk-ohos/eng/ohos-install/**`、五仓 workflows/pipelines）。B：托管/UI 面（`maui-ohos/src/Core/src/Platform/OpenHarmony/**` 109 个 `.cs`、Hosting/Maui.Graphics、3 份 `Index.ets`、harness/demo）。C：`runtime-ohos`/`aspnetcore-ohos` 全 fork delta + 上轮 23 条复核。D（补扫）：`sdk-ohos` 代码签名/ELF 工具链/安装器。E（补扫）：sdk `SelfSign/**`、OHOS 环境默认、AOT 入口、Layout/redist。
- **PoC 对抗。** 全部在 `/data/storage/el2/base/tmp/opencode/scan2/{poc-a,poc-b,poc-c,poc-d}`，只读、离线、无真机：poc-a 用本地目录源 + 手工 GPF 注入复现 H-C1；poc-b 用 node 原样执行从模板逐字节提取的 `isAppNavigation` 函数体、用 `readelf`/`strings`/`dynsym` 复现 H-C3；poc-c 用 HEAD `ElfSigner.cs` 编译独立驱动 + 真实已签名资产 + 99 例结构化 fuzz + `file://` mock 传输复现 D-1..D-4；poc-d 用 stub `hdc`/`curl`/`node` + guard 仿真复现 A1/A2/A3。
- **修复批次与纪律。** FIX-P1（宿主性能）、FIX-P2（托管性能）、FIX-WORK（A1/A2/A3/H-C2 壳/packs 重建）、FIX-SDK（D-1..D-6、H-C1、sec-e C1/C2/C3）、FIX-MAUI（MB-1..MB-3、H-C2 managed），每项 reproduce-then-fix、逐项负向回归。
- **本报告复核。** 写入时重跑（只读、离线）：`sh sdk-ohos/eng/ohos-install/tests/test-installer-verification.sh` → `passed=14 failed=0`（当时值；当前 tip **43/43**，FIX-R2B 后并入 bundle 外锚用例）；`sh sdk-ohos/eng/ohos-install/tests/test-hostfeed-verification.sh` → `passed=10 failed=0`；`sh ohos-workload/scripts/selftest-tester-run.sh` → `checks: 315, failed: 1`（唯一失败是 "repo working tree unchanged by tester-run.sh" 断言，因为并行进行的 FIX-RESID 在 `OpenHarmonyApp.cs` 留有未提交改动——修复提交时该项为 315/0，详见 §残留风险）。另复跑 H-C2 壳 harness（`node fix-work/h-c2/harness.mjs`）→ `ALL-PASS`。

## 汇总表

| 编号 | 严重度 | 标题 | CWE | PoC 结论 | 修复状态 | 提交 |
|---|---|---|---|---|---|---|
| D-1 | 高 | 单文件发布重签静默丢弃 bundle / 截断正文 | CWE-693 / 20 | Reproduced | 已修 | sdk `b3f5afa293` |
| H-C1 | 中（托管 CI 低） | `/tmp/hostfeed` 本地包源投毒 → 构建期 RCE | CWE-345 / 494 / 732 | Reproduced | 已修 | sdk `690134e706` |
| A1 | 中 | `tester-run.sh` bundleName → `hdc shell` 命令注入 | CWE-78 | Reproduced | 已修 | ow `81b9264` |
| A2 | 中 | hvigor 下载无摘要校验即由 node 执行 | CWE-494 / 829 | Reproduced | 已修 | ow `4b74c4c` |
| D-2 | 中 | 畸形 `.codesign`：报 Signed 却截断正文 | CWE-20 / 693 | Reproduced | 已修 | sdk `b3f5afa293` |
| D-3 | 中 | 签名任务跟随文件/目录符号链接越出输出树（=sec-e C1） | CWE-59 / 61 / 367 | Reproduced | 已修 | sdk `b3f5afa293` |
| D-4 | 中 | 安装器接受 http + 校验和同源自证 → MITM RCE | CWE-494 / 319 | Reproduced | 已修 | sdk `7f820be9b0` |
| H-C2 | 低/加固（原中，PoC 降级） | B6 白名单放行 `//host` 网络路径引用 | CWE-183 / 184 / 20 | 判定缺陷 Reproduced；端到端设备未验证 | 已修（壳 + managed + abc 重建） | ow `0bb7119` + maui `c730226f93` + ow `1063374` |
| MB-1 | 低 | WebView 审批表无界增长 | CWE-400 | 代码级确认（负向 pin） | 已修 | maui `c730226f93` |
| MB-2 | 低 | 反向 P/Invoke 逃逸异常 → CoreCLR fail-fast | CWE-248 / 755 | 代码级确认（负向 pin） | **已修**：maui 12 入口 + 宿主 10 入口守卫 + 负向 pin（315 项全过） | maui `c730226f93` + ohos-workload `9256305`/`92f7555` |
| MB-3 | 低 | rawfile/包内文件路径 `..`、rooted、UNC | CWE-22 / 20 | 代码级确认（13 负例 + 5 正例） | 已修 | maui `c730226f93` |
| A3 | 低 | `release-all.sh` 默认弱化 C4 clobber 摘要守卫 | CWE-345 | Reproduced（修复不完整） | 已修 | ow `683162a` |
| D-5 | 低 | `--force` 重签每轮 +4 KB；安装全量重签 | CWE-404 / 20 | Reproduced | 已修（force 幂等） | sdk `b3f5afa293` |
| D-6 | 低 | 畸形 ELF 自引用 shstrtab → 未捕获异常 | CWE-20 | Reproduced | 已修（设备未验证） | sdk `b3f5afa293` |
| C3（sec-e） | 低 | 显式非 ELF 入参 fail-open、退出码 0 | CWE-390 / 754 | Reproduced | 已修（CLI 已编译验证 `48fdd91aed`） | sdk `b3f5afa293` |
| H-C3 | 低/加固 | TLS shim 裸名 `dlopen("libssl.so")` | CWE-427 | Reproduced（构建/二进制级）；修复后设备负向验证 | **已修**（绝对路径 dlopen + 静态链接开关） | runtime `3d1f6e45102` / `cfdba659d11` / `d7b730e5030` |

## 逐条详情

### 高危

#### D-1 单文件发布：bundle 被静默丢弃、输出被截断（高，已修）

- **攻击路径。** `PublishSingleFile` 把 bundle 追加到已带 `.codesign` 的 apphost/singlefilehost 之后（宿主包 apphost、singlefilehost、obj apphost 均带签名）→ Publish 钩子重签时 `IsValidlySigned` 因 fileSize 不符返回 false → `StripCodesign` 只保留到 `.codesign` 节偏移，bundle 被丢且 `ValidateSigned` 只验签名自洽、查不出 → 构建报成功，产物启动即 `The application to execute does not exist: '<App>.dll'`（runtime-ohos `apphost.c:228`）。CI/release 同样静默。
- **证据。** `sdk-ohos/src/Tasks/Microsoft.NET.Build.Tasks/ElfSigner.cs:298-375`（`keepLen = Math.Min(csSecOff, len)`，`:343`）、`:573-590`（`ValidateSigned`）；`src/Tasks/Microsoft.NET.Build.Tasks/targets/Microsoft.NET.Sdk.targets:891-901`（`_OpenHarmonyCodeSignPublishOutputs` = AfterTargets Publish）；`Bundler.cs:326-345`（非 macOS 不删签名、bundle 接在 host 尾）。触发条件：`_EnableOpenHarmonyCodeSign` 求值期只认 `RuntimeIdentifier.StartsWith('openharmony')`，而 `AppHostRuntimeIdentifier` 直到 `ResolveFrameworkReferences` 目标内才赋值（`FrameworkReferenceResolution.targets:185-188`）。
- **复现（poc-c）。** 真实已签 `singlefilehost`（8,116,672 B，`.codesign`@8,110,080）按 Bundler 语义追加 256 KiB bundle + 尾 marker 后调用 HEAD `SignFileInPlace` → **Signed**、输出 8,120,768 B、marker 消失（-258,081 B）；小 apphost 38,976 → 43,072 同样。反证：先 strip 再追加再签则 marker/bundle 保留。判定命令：`dotnet publish -r openharmony-* -p:PublishSingleFile=true -p:SelfContained=true` **必中**。
- **最小修复与落地。** `b3f5afa293`：重签时按本签名器写入的几何**原位**清零并重写描述符/签名（其余字节不动，尾部 bundle 存活、`--force` 幂等）；strip 与外来布局保留全部原始字节并追加重建的节表；新增"输出不得小于输入正文"字节级断言（`ElfSigner.cs:976`）；外来 `.codesign` 默认保留并告警、仅显式 `--force` 才替换；目录遍历跳过符号链接。
- **回归。** `test/Microsoft.NET.Build.Tasks.Tests/GivenAElfSigner.cs`（合成已签 ELF + 256 KiB 尾块、外来/重复/重叠/自引用布局、链接环、force 幂等）：本机 MSTest `total: 14, failed: 0`；同测试 + 额外断言的本地 harness `passed=37 failed=0`；真实资产用例 `passed=6 failed=0`（签名后大小不变、blob 保留、re-verify `AlreadyValid`、`--force` 不增长）。

### 中危

#### H-C1 `/tmp/hostfeed` 本地包源投毒（中；托管 CI 低，已修）

- **攻击路径。** 同机可写 `/tmp/hostfeed` 的进程投放 `*.nupkg`（id/ver 可从 `eng/ohos-install/versions.env` 预测）→ `build-ohos-all.sh:436-438` `find … cp` 拷进 flat `$FEED` 并注册为本地 NuGet 源 → `:465-483` 手工灌入 `~/.nuget/packages`（`.nupkg.sha512` 由同一文件自算）→ `:487-503` 把源**永久写进** `runtime-ohos/NuGet.config`（只 add、不清理）→ `:592-599` 仅凭 GPF 目录存在就跳过 sha256 校验、`:305-306,318-320` 优先使用缓存 crossgen2 → 构建期执行攻击者 host runtime pack（RCE）并污染随后签名/发布的产物。
- **证据（poc-a）。** T4：源为空、仅 GPF 注入即 `Restored`（注入即完全信任）；T5：源 GOOD/GPF PAYLOAD → 产物仍 PAYLOAD、不回源复验；T7b/T8b：篡改 `.nupkg.sha512`、删除 `.nupkg.metadata` 仍 `Restored`；T9：`dotnet nuget list source` 显示 `local-feed [Enabled]`，`/tmp/hostfeed` 缺失时普通 restore 直接 `NU1301`（可靠性与安全双重问题）；提交版 `runtime-ohos/NuGet.config` 无 `local-hostfeed`（"永久写入"是运行期工作区脏写）。托管 CI 为一次性 runner（`sdk-ohos/.github/workflows/ohos-full-build.yml:60` `runs-on: ubuntu-24.04`）→ 官方 CI 风险降为低；本地/自托管构建维持中。
- **最小修复与落地。** `690134e706`：摄取改为私有 `HOSTFEED`（默认 `$WORK/hostfeed`，0700；workflow 用 `$GITHUB_WORKSPACE/hostfeed`）；每个包必须有 `HOSTFEED_<ID>_<VER>_SHA256` 或 `manifest.sha256` 行，未知 id / 未 pin / 组或全局可写目录 / symlink 一律拒绝（`build-ohos-all.sh:248-320`）；删除手工 GPF 播种，host pack 与 crossgen2 使用前按 pin 复验（crossgen2 从已验证 nupkg 重解压覆盖不匹配缓存）；不再改仓库 `NuGet.config`，改用私有 `$WORK/NuGet.config` + `RestoreConfigFile`。
- **回归。** `eng/ohos-install/tests/test-hostfeed-verification.sh`：本报告复跑 `passed=10 failed=0`（含"未 pin 拒绝/未知 id 拒绝/symlink 不摄取/组可写目录拒绝"）。

#### A1 `tester-run.sh` bundleName 命令注入（中，已修）

- **攻击路径。** 恶意 hap 的 `app.bundleName = com.example.legit; <cmd>`（或 `--extra-probes` 注入的 hap）→ 脚本把整串拼进 `hdc shell aa start -a EntryAbility -b <bundle>` / `pidof` / `ps` / 卸载命令；hdc 把 argv 拼成一条设备命令行交 `sh -c` → 以 hdc-shell 身份执行命令（读/写 `/data/local/tmp`、枚举/卸载 bundle 等）；`--uninstall` + `../ESCAPED` 还能逃逸本地输出路径。
- **证据。** pre-fix `ohos-workload/scripts/tester-run.sh:527,531`（读取不校验）、`:666`（拼接）、`:780,804`（主 `--hap`）、`:931,951`（extra-probes）；`verify-kit.sh:365` 同一串打印进"启动"命令；白名单只覆盖 kit 内 5 个 hap（`verify-kit.sh:115,293-305,341-347`），`--hap/--extra-probes` 完全绕过。
- **复现（poc-d）。** 11 payload × 4 模型（space/dquote/squote/escaped）：space 下 P1 `;cmd`、P2 `&&cmd`、P3 `$(cmd)`、P4 反引号、P5 换行执行；dquote/squote 分别让引号类 payload 逃逸；**escaped 正确转义 11/11 不执行**；`--uninstall` 生成 `out/trav/ESCAPED.txt`。
- **最小修复与落地。** `81b9264`：`is_safe_bundle_name()` 先逐字节拒绝控制字符/空格/非 `[A-Za-z0-9._-]`（`tester-run.sh:269-274`，先于 regex——grep 按行匹配会让"第二行合法"的名字漏过），再点分、字母开头白名单（`:273`）；`read_bundle` 输出与 `KIT_BUNDLE_NAME` 回退统一过 `require_safe_bundle_name` 门（`:283-285,288`）；`start_app`/`proc_alive`/`uninstall_one` 每个 hdc 调用前 gate；卸载日志文件名改用消毒后的 `bundle_for_log`（`:278-280`）。
- **回归。** `selftest-tester-run.sh` 新增 S9（11 个恶意 payload 在发任何 hdc 命令前全部拒绝）、S9b/S9c 合法对照、S10 `KIT_BUNDLE_NAME`；本报告复跑 `checks: 315`（1 failed 为工作树断言，见 Verdict 注），修复提交时为 315/0。

#### A2 hvigor 下载无摘要即执行（中，已修）

- **攻击路径。** 控制 `repo.harmonyos.com/npm` 同版本 tgz / DNS-TLS MITM / 本地缓存投毒 → `build-arkts-shell.sh:107-118` `curl -fsSL` 后直接 `tar xzf`（无 sha256）→ `:296-305` 由 node 执行 `@ohos/hvigor/bin/hvigor.js` → 开发机构建链 RCE，并污染 `modules.abc`/hap 构建产物。
- **复现（poc-d）。** 同一 URL 两次投递不同 sha256 的 tgz 均 rc=0，node 执行的首行分别为 `// legit` / `// tampered`；预置投毒缓存时 curl 调用 0 次仍执行（`:114` `[ -f "$tgz" ] ||`）。对照既有做法：`install-dotnet-ohos.sh:251-278` `download_verified`（无摘要即拒）、`build-ohos-all.sh:171-274` `fetch_verified`——本处是遗漏。
- **最小修复与落地。** `4b74c4c`：固定 `HVIGOR_SHA256`/`HVIGOR_OHOS_PLUGIN_SHA256`（`build-arkts-shell.sh:117-118`，已验证与 registry `dist.shasum`/`dist.integrity` 及产出可用构建的缓存一致）；下载到 `.part`、校验后原子入缓存（`:161-171`），缓存 tgz 解包前同样校验（`:143-153`），失败 die 且不污染后续。
- **回归。** `fix-work/a2-negative-tests.sh` + `dl-primary/dl-alt/good-cache/cache` 日志：投毒下载与投毒缓存都必须失败且 node 未被调用。

#### D-2 畸形 `.codesign`：报 Signed 却截断正文（中，已修）

- **攻击路径。** 构建/发布树出现外来或畸形 `.codesign` 的 ELF64（第三方产物，或经 D-3 注入）→ 重签"成功"但可执行正文被替换/截断，产物不可启动或行为错误。
- **复现（poc-c fuzz，99 例结构化变异 + 24 随机位翻转）。** 9 例 Signed 且 body 区间丢失（如 `sh_offset=0x2000`：`.text` 14,328/14,328、`.rodata`、`.data`、`.plt` 全被替换，丢 24,576 B；`0x40/0x100/0x1000/0x4000/0x7000` 同类；把 `.comment`/`.gnu_debuglink` 改名为 `.codesign` 也触发）、76 例 Signed 且 codesign 后尾数据丢失（D-1 机制）、**0 例被 `ValidateSigned` 拦下**。fail-closed 例：`sh_offset=0/8`、`e_shnum=0`、shstrtab 越界、自引用。
- **最小修复与落地。** `b3f5afa293`：对重复/重叠/越界/自引用/唯一节等异常布局抛可读 `InvalidDataException`（`ElfSigner.cs:619-666,915-976`）而非"修复"；重签原位改写、strip 保留全部字节。
- **回归。** poc-c 99 例重跑：before `"Signed but lost" = 85/99` → after **0/99**（fail-closed 45、foreign-retained(warn) 12、signed-preserved 42），fail-closed 用例输入字节原样不动。

#### D-3 签名任务跟随符号链接越出输出树（中，已修；=sec-e C1）

- **攻击路径。** 在签名目录（共享构建/暂存/发布目录、CI 产物目录）放入指向外部的文件/目录链接 → `OpenHarmonyCodesign.cs:32` `Directory.EnumerateFiles(dir,"*",AllDirectories)`（`AttributesToSkip=0`）跟随目录链接、`ElfSigner.cs:53/58/71` `File.Exists/ReadAllBytes/WriteAllBytes` 跟随文件链接 → 以受害者（CI 下可能 root）权限原地改写任意可写 ELF64；读写间换链的 TOCTOU 可改写非预期路径。
- **复现（poc-c）。** 43 行独立驱动：`TargetDir/evil.so -> ../outside/outside.so` 枚举并 `SignFileInPlace=Signed`，链接仍在、外部文件被改写（34800 → 43072 B，sha256 变化）；目录链接 `linkdir -> ../outside` 被递归；循环链接抛 ELOOP fail-closed。
- **最小修复与落地。** `b3f5afa293`：`ElfSigner.EnumerateFilesWithoutLinks`（`ElfSigner.cs:132,175` 对 `FileAttributes.ReparsePoint` 文件与目录链接跳过并告警；`OpenHarmonyCodesign.cs:37` 改用它）；安装器的 `find -type f` 原本就不跟随链接。
- **回归。** 链接矩阵（文件/目录/循环）+ GivenAElfSigner 增例；目标不被改写。

#### D-4 安装器接受 http + 校验和同源自证（中，已修）

- **攻击路径。** 用户传 `http://` URL（用法明示支持）或使用攻击者可控镜像且未设 pin → 校验和从同一来源解析（`SHA256SUMS` / `<file>.sha256` / GitHub digest，`install-dotnet-ohos.sh:217-278`）→ MITM/恶意镜像同时替换工件与校验和 → 安装期解包并以用户权限执行 `selfsign`/`dotnet`（RCE），"sha256-verified" 完全失效。`curl` 未限制 `--proto-redir`（`:166`，默认允许 https→http 重定向）；外部 pin 仅可选（`:662`）。
- **复现（poc-c）。** 篡改 tar.gz + 同目录重生成 SHA256SUMS，经仓库真实函数：`resolve_expected_sha256(tampered)=35c9e9…`=篡改文件 hash、`download_verified` 输出 `sha256 OK` rc=0；解包出的假 `selfsign` 按 `sign_all` 路径立即执行（marker）。
- **最小修复与落地。** `7f820be9b0`：curl 固定 `--proto '=https' --proto-redir '=https'`（`install-dotnet-ohos.sh:185`）、wget 仅接受支持 `--https-only` 的版本（`:170-171`）；`versions.env` 为 SDK/runtime tarball 与 selfsign 增加外锚 pin（`:62-64`），锚定摘要始终优先、同源自证仅对 pin 的 GitHub release URL 生效（`:242-303`）；用户 URL 必须带显式 pin；已部署 `$INSTALL_DIR/selfsign` 执行前按 pin 复验。
- **回归。** `eng/ohos-install/tests/test-installer-verification.sh`：本报告复跑 `passed=14 failed=0`（当时值；当前 tip **43/43**）；"mismatching anchor refused / same-origin checksums cannot be resolved for non-pinned hosts / selfsign pin" 全部覆盖。

#### H-C2 B6 白名单放行 `//host` 网络路径引用（低/加固，已修）

- **攻击路径。** 页面内 `location.href = '//evil.invalid/x'` 等网络路径引用（浏览器语义 = `https://evil.invalid/x`）被壳 `isAppNavigation` 的 `'/'` 快路径判为"应用内" → `onLoadIntercept` 直接 `return false`，不触发 `__OHNAV`/managed `Navigating` 审批 → 应用 WebView 在无审批下加载任意外源（绕过应用外链策略/钓鱼，非沙箱逃逸）。
- **证据（poc-b，实际执行模板函数）。** pre-fix `packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.{22,23,24}/templates/ets/pages/Index.ets:1006-1021`（`url.charAt(0)==='/'` 即 true）+ 调用点 `:3364-3385`；绕过表 `//evil.invalid/x`、`///evil.invalid`、`/\evil.invalid`、`//\evil.invalid`、`//evil.invalid:8443/x`、`//0.0.0.1@evil.invalid/x` 全部 raw=true 且 WHATWG 解析后异源；managed `OpenHarmonyWebViewHandler.cs:225` 的 `Uri.TryCreate(Absolute)` 实测把 `//evil.invalid/x` 接受为 `file://evil.invalid/x`（对绕过不生效——壳先短路）；`http:/\evil.invalid`、`https:/evil.invalid`、前导空白/控制字符、`%2f%2f` 走 managed（安全方向）。
- **降级理由。** 端到端命中要求 ArkWeb 把**未解析**的网络路径引用原样交给回调；官方文档只写 "Gets the request URL"，与标准浏览器解析相悖，设备证据缺失；命中影响限应用策略层 → 由原报"中（设备未验证）"降为**低/加固**；若真机日志证明回调收到 `//` 原样字符串，应回升中。
- **最小修复与落地。** 壳 `0bb7119`：`'/'` 快路径前先跳过前导 `≤0x20`/DEL，再拒绝 `//`、`/\`、`\\` 对（`Index.ets:1010-1037`；`//evil`、`\t//`、`\u0001//`、`\r//`、`\v/\`、`\f\/` 全部拒绝），相对路径/`#`/`?`/inline/file/about/blob 保持放行；managed `c730226f93` 双保险：`__OHNAV` 决策仅批准带 host 的绝对 http(s) URI（`OpenHarmonyWebViewHandler.cs:235`），应用发起加载拒绝 `//`、`/\`、`\\`、`https:foo`（`:297`）；preview.24 abc 重建 `1063374`（ABC 版本 13.0.1.0、204,780 → **205,352 B**、sha256 `4364a2e9…`；preview.22/23 仅模板修复，不重建旧 abc）。
- **回归。** 壳 harness（`node fix-work/h-c2/harness.mjs`）**ALL-PASS**：30 项 h-c2（绕过表 12 + 基线控制 18）；managed 负向 harness 30 项 h-c2；B6 pins 全绿；交互 308 checks、floor 288；像素 PASSED。

### 低危 / 加固

#### MB-1 WebView 审批表无界增长（低，已修）

- **攻击路径。** 页面脚本循环主框架导航 → `HandleNavigationRequest` 对每个被壳取消的导航写 `s_approvedNavigations[url] = TickCount64 + 10s`（URL ≤ `MaxNavUrlLength = 8192`）；只有同串 URL 真正开始加载才由 `started` 事件 `ConsumeApprovedNavigation` 删除；壳 `navPendingLimit=8`/TTL 5 s 淘汰后 `approveNavigation` 直接返回、不 `loadUrl` → 条目留到进程结束。10 万次 ≈ 800 MB。
- **证据。** `maui-ohos/src/Core/src/Platform/OpenHarmony/OpenHarmonyWebViewHandler.cs:36,230-241,268-283`；壳 `Index.ets:314-315,1095-1098`。
- **修复与回归。** `c730226f93`：插入时清过期；上限 **64**（8× 活跃集，键上界 64×8 KiB=512 KiB；`MaxApprovedNavigations`，`OpenHarmonyWebViewHandler.cs:41,357-375`）；满时淘汰最接近过期项；完成/失败页面事件也清理；一次性语义不变（负向 pin mb1 5 项 + 308 检查）。

#### MB-2 反向 P/Invoke 逃逸异常（低，已修）

- **攻击路径。** 页面发 `__RawMessage|{…}`、恶意 BLE 外设发特征值、或宿主触摸/帧回调进入应用代码后抛出（JsonException 等）→ 异常从反向 P/Invoke 逃逸进 native 栈，CoreCLR fail-fast 终止进程且应用无法捕获。
- **证据。** `OpenHarmonyWebViewHandler.cs:343-347`、`OpenHarmonyBluetoothGatt.cs:640`、`OpenHarmonyApp.cs:994,1046`；既有正确模式 `OpenHarmonyAccessibility.cs:237-252`。
- **修复与回归（maui 侧）。** `c730226f93`：12 个可运行应用代码的入口全部 try/catch，统一走 `OpenHarmonyStatus.NativeCallbackFailed`（扁平化、600 字符上限、128 键去重，避免日志洪泛），覆盖 WebView JS 消息（`__RawMessage`/`JsMessage`/Navigating）、hybrid invoke、BLE value/state/MTU、电池/显示、已发现设备、剪贴板/网络、传感器、菜单、主题；只完成有界 Task 的入口不在 native 帧上运行应用代码（全部 `RunContinuationsAsynchronously`）。负向 harness 8 项 mb2 + "reported to status (flattened) bytes=936"。
- **宿主侧收口（FIX-RESID，已提交）。** `ohos-workload 9256305`：`OpenHarmonyApp.cs` 10 个原生→托管入口（Pinch/Lifecycle/Touch/TextInput/TextSubmitted/WebEvent/PickerResult/KeystoreResult/Frame/Surface）统一 try/catch + `ReportCallbackFailure`（单行、600 字符截断、按 boundary+异常类型去重、128 键上限，走既有 `dotnet-status.txt`；`OnNodeNative` 无应用回调未改），Touch/Frame 热路径正常路径零新增分配；`92f7555`：harness 负向 pin（mb2 slice 7 + status 落日志 + host 10 入口/10 源守卫/10 状态行），交互套件 **315 项全过（floor 288）**、像素 PASSED。

#### MB-3 rawfile/包内文件路径穿越（低，已修）

- **攻击路径。** 应用把外部输入（深链/网页内容）当包内文件名 → `OpenAppPackageFileAsync`/`AppPackageFileExistsAsync` 直接 `Path.Combine(AppPackageDirectory, filename)`（绝对路径丢弃包前缀、`..` 可穿越；`OpenHarmonyFileSystem.cs:33,56,107-183`）；rawfile 桥把原始 `filename` 交宿主（`:158`），壳只做 `replace(/\\/g,'/')` + 去前导 `/`（`Index.ets:1942-1944`），不拒绝 `..`。影响限本应用沙箱/HAP（同 UID）。
- **修复与回归。** `c730226f93`：`OpenHarmonyPackagePaths.Normalize`（`/` 归一、拒绝 rooted/drive/UNC/`.`/`..`/控制字符含 NUL——NUL 会在 C 字符串边界截断；`OpenHarmonyFileSystem.cs:95-145`），rawfile 与文件 API 同一门；负向 13 例 + 正向 5 例（`fix-maui/neg-output3.txt`：`../secret`、`/etc/passwd`、`//server/share/x`、`C:\…`、`a\..\b`、`a//b`、`a\0b` 等拒绝；`index.html`、`./x/y.html`、`a\b\c.txt` 等放行）。
- **残余。** `resourceManager` 对 `..` 的语义仅设备可验（见 §残留风险）。

#### A3 `release-all.sh` 默认弱化 clobber 摘要守卫（低，已修）

- **攻击路径。** `release-all.sh:269` 无条件把 `--allow-clobber-mismatch` 转发给 `publish-workload-release.sh`，使 C4 的"已发布摘要 ≠ 本地摘要即拒绝"降级为告警 + `--clobber` 覆盖；`--bundle-sha256` 由 wrapper 自算，不能作为独立证明。无新增攻击面，但失去人工显式确认。
- **复现（poc-d）。** dry-run 的 step5 命令含该 flag；guard 仿真（`published≠local`）：flag=0 → rc=1 refuse，flag=1 → rc=0 仅 WARN override。
- **修复与回归。** `683162a`：仅 `ALLOW_CLOBBER_MISMATCH=1` 或显式 `--allow-clobber-mismatch` 才转发并告警；rolling tag（`workload-latest`/`device-test-kit`）可刷新，versioned `workload-<ver>` 默认保持门禁。回归：dry-run 断言默认命令无该 flag；guard flag=0 必须 exit 1；显式开启时日志含双摘要。

#### D-5 `--force` 重签膨胀 / 安装全量重签（低，已修）

- **复现。** 同一文件 4 次 `--force`：8408 → 12504 → 16600 → 20696（每轮 +4096，strip 后重新页对齐注入 `.codesign`）；`install-dotnet-ohos.sh:155,589-610` 的 `sign_all` 每次安装对所有 ELF `--force` 重签，"幂等"声明不成立。
- **修复与回归。** `b3f5afa293` 原位重写使 `--force` **幂等（8408 → 8408）**；安装期全量重签的**成本**残余记录在性能报告（P12 与门禁建议），安全面无新增。

#### D-6 畸形 ELF 自引用 shstrtab 未捕获异常（低，已修）

- **复现。** 构造 `e_shstrndx` 指向名为 `.codesign` 的节（自引用 shstrtab）→ 未捕获 `IndexOutOfRangeException`（400 例 fuzz 中 2 例）；由 MSBuild 任务 catch 记为构建错误（fail-closed），无内存破坏。
- **修复。** `ElfSigner.cs:625,647` 显式 `InvalidDataException`（其余异常布局同类处理）；selfshstr 用例进入 GivenAElfSigner。
- **残余。** 边界守卫已做但**设备未验证**（未在设备上跑 `dotnet publish`）。

#### C3（sec-e）显式非 ELF 入参 fail-open（低，已修）

- **复现。** `dotnet selfsign <file>` 对显式传入的非 ELF64 只累加 `not-elf`，`failed==0` → 进程返回 0 并打印 `not-elf=1`（`SelfSignCommand.cs:52-63,80-93`）；只看退出码的门禁会放行未签名/无效工件。
- **修复。** `b3f5afa293`：显式命名的非 ELF64 计为失败并退出 1（`SelfSignCommand.cs:87-90,70`）；目录扫描内的非 ELF 仍按 `not-elf` 分类（合理，非静默放行）。
- **残余。** `SelfSignCommand.cs` 已按 `48fdd91aed` 独立编译（本机已装 SDK 的 Roslyn + System.CommandLine 3.0.0）并跑 17/17 CLI 用例（见 §残留风险）；设备端未验证；`ElfSigner.cs` 已独立编译并测试。

#### H-C3 TLS shim 裸名 `dlopen`（低/加固，已修）

- **证据（代码）。** `runtime-ohos/src/native/libs/build-native.sh:35,58` `__PortableBuild=1` → `-DFEATURE_DISTRO_AGNOSTIC_SSL=1`（OHOS 未排除）；`src/native/libs/System.Security.Cryptography.Native/CMakeLists.txt:100-105` 编入 `opensslshim.c`；`extra_libs.cmake:34` portable 分支只链 `${CMAKE_DL_LIBS}`，**不链** `OPENSSL_CRYPTO_LIBRARY/OPENSSL_SSL_LIBRARY`；`opensslshim.c:39` `LIBNAME "libssl.so"`、`:52-54` `dlopen(name, RTLD_LAZY)`，裸名序列 `libssl.so.<DOTNET_OPENSSL_VERSION_OVERRIDE>` → `.3` → `.1.1` → `.4`。
- **证据（二进制，poc-b）。** 发行包 `11.0.0-rc.1.26451.109` 的 `libSystem.Security.Cryptography.Native.OpenSsl.so`：`readelf -d` 仅 NEEDED `libc.so`；UND `SSL_/EVP_/X509_` 计数 0；strings 含 `libssl.so.3/1.1/4`、`DOTNET_OPENSSL_VERSION_OVERRIDE`；fork 自编静态 OpenSSL 3.3.1（`docs/plans/2026-08-13-ohos-cross-compile.md:166,485-486` 以 `OPENSSL_*_LIBRARY=*.a` 传入）只满足 find_package/头文件，未参与链接（与 CMake 注释"uses the OpenSSL built for OHOS"不符）。
- **影响与修复。** 修复前设备上先被搜索到的同名库（应用自带/第三方 native 模块）会成为 .NET 的 TLS 实现与信任锚；无跨应用路径、需同信任域/系统能力，且 runtime pack 与 OHOS 26 SDK sysroot 均无 `libssl/libcrypto`（缺库时首次 TLS fail-closed）。**已修（低/加固策略）**：`3d1f6e45102` shim 改用 `dladdr` 求本库目录后按绝对路径 `dlopen`，找不到即 fail-closed、不回退裸名；同时提供 `-linkstaticopenssl` / `/p:LinkStaticOpenSsl=true` 以 `FEATURE_DISTRO_AGNOSTIC_SSL=0` + `CMAKE_STATIC_LIB_LINK=1` 链接静态 OpenSSL（硬化 shim 仍默认）。`cfdba659d11` 同批启用 H3 TLS resolver 探测门控；`d7b730e5030` 记录静态归档 `-fPIC` 保证。策略、编译/链接证据与设备负向测试见 `docs/plans/2026-09-23-ohos-tls-policy.md`。
- **CWE。** CWE-427（不受控搜索路径元素）；CWE-1104 次要。

## 上轮 23 条复核（A1–A8 / B1–B7 / C1–C8）

判定尺度：对每个修复点用**当前代码**定位并复查是否回退；未重跑 harness/CI，A/B 设备可见结论仍为设备未验证。

| 编号 | 判定 | 当前证据（`文件:行`） |
|---|---|---|
| A1 | 仍然有效 | `openharmony_host.c:565` `g_context_mutex`、`:858-864` take-once 收养；`host_napi.cpp:44,2536-2540` `g_launch_lock` |
| A2 | 仍然有效 | `openharmony_host.c:2688` `g_a11y_mutex`、`:2705` `pthread_key_create`、`:2789+` 持锁拷贝 |
| A3 | 仍然有效 | `OpenHarmonyAccessibility.cs:119` Volatile 快照、`:181,206,228,247,266` 回调 try/catch |
| A4 | 仍然有效 | `OpenHarmonyHybridWebViewHandler.cs:82` `MaxPagePayloadLength=4MiB`、`:456,692,805,810` 拒绝点 |
| A5 | 仍然有效 | `host_napi.cpp:3496,3502,3528,3532` `OH_ArkUI_DestoryAccessibilityEventInfo`（发布与错误路径） |
| A6 | 仍然有效 | `openharmony_host.c:609,626-636` 有界 pending 队列/桥；`:726` 快照转移 |
| A7 | 仍然有效 | `openharmony_host.c:643,762,767,903` `g_launch_in_progress`；`host_napi.cpp:44,2536` |
| A8 | 仍然有效 | `openharmony_host.c:1351` `ImeUtf8PrefixLength`、`:1362` `ImeAppendUtf8`、`:1393` 代理对折叠 |
| B1 | 仍然有效 | `OpenHarmonyBlazorWebViewHandler.cs:338-351` 信封解析 + origin/id 校验后 `MessageReceivedFromShell(AppOrigin)` |
| B2 | 仍然有效 | `OpenHarmonyHybridWebViewHandler.cs:685` `ResolveMessageHandler`、`:755,799,849,889` `PendingInvoke` 归属校验 |
| B3 | 仍然有效 | Hybrid `:650` `window.__ohHybridId`；Blazor `:86,464` `__ohBlazorId` 标记门 |
| B4 | 仍然有效 | `OpenHarmonyCalendarContacts.cs:408-575` ParseRecords（`MaxFieldLength:411`、`MaxRecords:414`、转义反解）；壳 `Index.ets:1334-1352` `escapeRecordField` |
| B5 | 仍然有效（符号改名） | Hybrid `:314` `IsSafeAssetLayoutPart`（原 `IsSafeRelativePath`）、`:266,271` 注册拒绝；Blazor `:164`；壳 `:2908` `isSafeLayoutPart`、`:3005` 服务期 `..`/`\` 拒绝 |
| B6 | **部分——新变种 H-C2（本轮已修）** | 机制仍在：壳 `:1058` askManaged、`:1026` one-shot、`:1091` approveNavigation、`:3370` isMainFrame；managed `OpenHarmonyWebViewHandler.cs:195,211-240`。缺口 = `//host` 放行（H-C2） |
| B7 | 仍然有效 | `OpenHarmonyApp.cs:641,644,679` 256 KiB/4 KiB/`TrimStatusFile`；`OpenHarmonyWebViewHandler.cs:28,303,426` `SanitizeUrlForLog` |
| C1 | 仍然有效 | `sign-huawei.sh:102-107` 私有 mktemp+trap、`:111-115` 环境传密、`:146` `script -qec` 自动包裹 |
| C2 | 仍然有效 | `install-dotnet-ohos.sh:189` `verify_sha256`、`:251,265-274` `download_verified` fail-closed/`ALLOW_UNVERIFIED` |
| C3 | 仍然有效 | `prepare-packs.sh:25` 64 位固定摘要、`:31` 显式优先、`:74` 无期望即拒绝解包 |
| C4 | 仍然有效 | `publish-workload-release.sh:76,126-139` 独立摘要门、`:159-183` `published_asset_digest`/`guard_clobber` |
| C5 | 仍然有效 | `verify-kit.sh:42-46,86-121` anchor 仅绑 tar、tree-digest fail-closed |
| C6 | 仍然有效 | `build-ohos-all.sh:237` `fetch_verified`、`:274`；workflow 下载均经 `--fetch-verified` |
| C7 | 仍然有效 | `ohos-ci-env.sh:86,117,130,167` verify/resolve/require digest；workflow cache key 绑定三摘要 |
| C8 | 仍然有效 | workflows `permissions: contents: read`、`persist-credentials: false`、actions 固定 SHA（checkout@11d5960、setup-dotnet@67a3573、setup-node@49933ea）；maui 引用固定完整 SHA `31daa37c…` + `workflow_dispatch` 覆盖口 |

**统计：** 21 条有效未回退 + B5 有效（符号改名）+ B6 部分（H-C2，已修）；0 条回退。

## 降级与排除项

调查后无真实攻击路径、未进入修复的项（按面分组，均给出理由）：

| 区域 | 候选 | 结论与理由 |
|---|---|---|
| 壳 rawfile | rawfile `..` 不拒绝（`Index.ets:1942` 只去前导 `/`；`OpenHarmonyFileSystem.cs:28-38` 直传） | 无页面可控调用方；`resourceManager` 的 `..` 语义仅设备可验；同应用沙箱自读；MB-3 已在 managed 侧收紧 |
| 壳 rawfile | 8 MiB 上限在 `getRawFileContent` 整读**之后**才检查（`Index.ets:1977-1980`） | 只能由应用自身打包资产触发，自伤性内存峰值，非跨信任面 |
| 宿主 | 符号链接桥写 `app_dir`（`openharmony_host.c:247-345,780`） | 目标为应用私有 filesDir/dotnet；unlink+symlink 覆盖仅同 UID 可争；失败即降级复制 |
| 宿主 | 双 `nm_modname` 别名 + 可重入 `Init`（`host_napi.cpp:2857-2888`） | 仅影响模块查找/日志；未见竞态路径（本轮 import 实验有专门记录） |
| 宿主 | GATT 桥取消路径泄漏 `s_pending`（`host_napi.cpp:766-880`；`OpenHarmonyBluetoothGatt.cs`） | 请求字段白名单 + base64 错误处理在；属应用自伤且为 maui 面 |
| 托管 | Picker 文件名写 cache（`OpenHarmonyPicker.cs:227-245`） | `name` 取 URI 最后 `/` 之后，无法带分隔符；大文件自伤 DoS |
| 模板 | `module.json.template` `libIsolation:true`/`exported:true` | `EntryAbility.ets` 忽略 `want` 参数，无过权；与上轮 module.json5 结论一致 |
| 构建 | `verify-kit.sh` tree-digest 跳过根部传输包（`c80db7f`） | 仍由外层 anchor/`--expect-tree-digest` 绑定；自认证残余已在上轮 C5 记录 |
| CI | `npx markdownlint` 传递依赖未固定（`markdownlint.yml:37-41` 已注释） | 与 A2 不同（不执行构建工具） |
| 安装链 | sdk 安装器/NDK/CI 摘要门（`install-dotnet-ohos.sh:251-290`、`ohos-ci-env.sh:28-209`、`build-ohos-all.sh:179-254`） | C2/C6/C7 在位，9-21 后仅文档/`NoWarn` 注释变更 |
| CI | 三 workflow（interaction/pixel/markdownlint） | 权限/事件/引脚保持；runtime/aspnet/sdk 的 workflows 与 pipelines 继承上游、无新增 |
| runtime | W^X 默认关闭（`clrconfigvalues.h:637-643`，`EnableWriteXorExecute=0`） | OHOS 沙箱拒绝 file-backed PROT_EXEC，平台强制；可被 `DOTNET_` 覆盖列为残余风险而非漏洞 |
| runtime | 移除 `-ftls-model=global-dynamic`（`dc3b15b3fda`） | 本地 clang 23.1.1 实测 `-fno-emulated-tls` 单独即产出 `:tlsdesc`，与加显式 flag 逐行一致、与 ASM `vm/arm64/asmhelpers.S:623` 匹配；非回归 |
| runtime | 共享内存改 `Path.GetTempPath()`（`SharedMemoryManager.Unix.cs:417-424`，仅 `TARGET_OPENHARMONY`） | uid/0600/目录 sticky 校验仍在（`:453,636-679`），TMPDIR 属同进程/同 UID 信任域 |
| runtime | `openharmony` RID 只 `#import: any`（`PortableRuntimeIdentifierGraph.json:67-86`） | 不拉 linux/unix 原生资产，方向安全 |
| illink | `_UseManagedNtlm=true`（`Microsoft.NET.ILLink.targets:59-60`） | OHOS 不构建 `System.Net.Security.Native`，托管 NTLM 是唯一可用实现，非 TLS/证书回退 |
| sdk | 整型溢出路径、`IsValidlySigned` 吞异常、`WriteAllBytes` 非原子 + TOCTOU、`WORKLOAD_BUNDLE=<目录>`、可预测临时目录 | 极端值/回绕全部 fail-closed（toy 已验）；自签名无信任锚、跳过不构成信任跨越；就地写为保 inode 权限的有意设计 |
| sdk | `manifest-packages.csproj`（OSName=openharmony 跳过 workloads）、`ResolveReadyToRunCompilers.cs`（openharmony→linux token）、`OpenHarmonyEnvironmentDefaults` | 无安全缺陷；环境默认不覆盖非空用户值 |
| sdk | SelfSign 定义（无密钥/口令/证书输入）、`SdkRootLocator`（仅 dladdr/模块路径）、`NativeEntryPoint`、`AotSourceFiles.props`、`redist.csproj`、`BundledManifests`/`GenerateBundledVersions`/`GenerateLayout`/`Crossgen.targets` | 逐项审阅无攻击路径；缺包即 restore 失败（fail-closed）；`Microsoft.*` 前缀保留、无抢注/依赖混淆 |
| aspnet | 8 文件 delta（RID/打包/TFM 接线、两个 `PublishAot` 测试资产开关） | 无 OHOS 运行时安全代码；`ASPNETCORE_DIRECTTLS_001` NoWarn 只是实验 API 诊断，与证书校验无关 |

## 残留风险

- **H-C3 已修复（低/加固；`3d1f6e45102`/`cfdba659d11`/`d7b730e5030`；策略与验证见 `docs/plans/2026-09-23-ohos-tls-policy.md`）。** OHOS shim 现在只用 `dladdr` 求本库目录后按绝对路径 `dlopen`，找不到即 fail-closed，不回退裸名；另提供 `-linkstaticopenssl` / `/p:LinkStaticOpenSsl=true` 链接 `-fPIC` 静态 OpenSSL。已验：OHOS NDK clang 编译 + 链接（`NEEDED` 仅 `libc.so`）+ 设备端负向测试（decoy `libssl.so.3` 在 `LD_LIBRARY_PATH` 不被选中，放同目录才被选中）。**仍待做**：随包携带 `libssl.so.3`/`libcrypto.so.3` 或启用静态链接开关，并在设备上跑 SslStream/HTTPS 自检；`ReadMe` 中 `ilasm` 的 `System.Security.Cryptography.Native.OpenSsl-Static` 仅在 host 构建链接，不受本开关影响。
- **MB-2 已收口。** `9256305`（宿主 10 入口守卫 + `ReportCallbackFailure`）+ `92f7555`（harness 负向 pin；315 项全过、像素 PASSED）；设备端 CoreCLR 反向 P/Invoke 终止语义仍属离机不确定项（见下）。
- **FIX-SDK 的 CLI 已编译验证（`48fdd91aed`）。** `SelfSignCommand.cs` 以本机已装 SDK 的 Roslyn + System.CommandLine 3.0.0 独立编译（nullable + warnings-as-errors），17/17 CLI 用例通过（显式非 ELF 退出 1、目录遍历 sign/skip/count、`--force`、`--strip`、目录符号链接跳过）；签名路径也不再整读非 ELF 输入。`ElfSigner.cs` 另有独立编译 + 14/14 MSTest + 37/6 harness 证据。
- **binary-sign-tool 无默认 pin（已加可选锚，`6be3596810`）。** fallback 签名器 finder 只选可执行文件；`BINARY_SIGN_TOOL_SHA256=<hex>` 在首次执行前校验、不匹配即失败，未 pin 的回退仅告警（工具随用户自己的 OpenHarmony SDK/harmonybrew 分发，无单一上游摘要可默认固定）；`test-installer-verification.sh` 当时 25/25（当前 tip **43/43**，FIX-R2B 新增 18 例）。
- **离机不确定项（未上机，设备安装受策略限制）。** D-1 的最后一跳由已装同源 SDK 的宿主包/obj apphost 签名证据 + Bundler 源码推定，需设备端 `dotnet publish -p:PublishSingleFile=true` 复核；A1 设备端 hdc 拼接/转义与 `sh -c` 行为（stub 按官方 `shell [-b] [COMMAND...]` 语义建模，space/dquote/squote 可注入、escaped 不注入，四种模型界定边界）；H-C2 端到端依赖 ArkWeb 交付原始/解析 URL（location/a 点击、loadUrl、表单/重定向各异）；MB-3 的 `resourceManager` `..` 语义；MB-2 依赖 CoreCLR 反向 P/Invoke 终止语义；D-2 截断产物是否可加载；D-6/C3 边界守卫设备未验证。
- **A2 的 pin 值**由发布者实测（与 registry `dist.shasum`/`dist.integrity` 及可用缓存交叉核对），后续 tgz 版本变更需同步；`tar` 成员负测已补（`5c2afb1`：解包前拒绝 `../`、绝对与嵌套逃逸成员，27 项本地用例 + `--check-tgz`），真实 tgz 变更后仍需重跑该门。
- **H-C1 层级本地源不可解析**疑为本 SDK 版本/裁剪特性（NuGet 文档称 3.3+ 支持），需 CI 同 SDK 复核；`$FEED`=`sdk-ohos/eng/ohos-install/.work/feed` 为仓内固定目录，长期残留攻击者副本的可能性未实测。
- **上轮遗留（保持）。** `hap-sign-tool` argv password 仅在"无 tty 且无 `script(1)`"时残留；预摘要 GitHub release 资产需显式 sha256 pin；`npx` 传递依赖未固定；B1/B3/B6/B7 与 a11y/hybrid 流程设备未验证；应用自身文档内 XSS 不设防；B5 "一个 shell docId 每文档"；B6 POST 表单经 `loadUrl` 变 GET。
- **门禁/流程风险（已随性能后置批次修复，交叉引用）。** 交互/性能门禁不上 PR、preflight 阈值弱于 CI、alloc/帧无断言均已修（`d4d7cb7`/`d336bba`/`57d18c0`/`abd3451`，tar 成员负测 `5c2afb1`）；仅像素 `tolerance=0` 用例与 2 条 KNOWN 按策略保留（`d4d7cb7` 文档化，不得随意外删/放松）。详见 `2026-09-23-ohos-performance-scan.md` §门禁余量分析。

## 覆盖声明与命令

**覆盖（逐猎手）。**

- **A（宿主/原生/构建-发布链）：** `git log --since=2026-09-21` 逐提交 `--stat`（ohos-workload 75、sdk 7），重点 diff `b3d2538`(rawfile)、`830a5eb`(符号链接桥)、`0fe20c4`/`9ff58b8`(libs 暂存+签名)、`7e71c39`(dlopen 面)、`cb7bc3e`(别名)、`e0cfc24`(新桥加固)、`b7fa6da`/`a1c95eb`/`29f1fbf`/`57e3373`/`56617a1`/`4040d48`(权限/剪贴板/设置/窗口/软键盘/GATT)；`Index.ets` preview.22/23/24 各 ~3588 行 rawfile/GATT/picker/ability/announce 邻域；宿主 `openharmony_host.c`(2902)/`host_napi.cpp`(3540) 新增 hunks + 关键全局 grep；19 个脚本；`sdk-ohos/eng/ohos-install/**` 与两 RID 图；五仓 workflows/pipelines 变更面。未查：其它仓类库实现（其他猎手）、`modules.*.abc` 二进制内容（仅 md5/大小）、`.arkts-build/**`/node_modules、设备端语义。
- **B（托管/UI）：** 109 个 `.cs` 全 grep 定向 + 30+ 文件精读（WebView/Hybrid/Blazor/FileSystem/Keystore/SecureStorage/AppLauncher/Communication/EssentialsBridges/Extras/Unsupported/Picker/CalendarContacts/BluetoothGatt/Printing/Screenshot/Geocoding/Accessibility/WindowOverlay/Tooltip/Accelerator/Focus/Key/AnimationLoop/ScrollPhysics/MauiAppHost/ApplicationHandler/Paths）；Hosting 3 文件、壳 `Index.ets` 桥/导航/资产/kit/权限/rawfile 段、3 份模板、4 个 harness + 2 个 demo。限制：静态审阅，未构建/未上机。
- **C（runtime/aspnet + 复核）：** runtime 全部 `TARGET_OPENHARMONY` 标记（15 处）逐一审阅（pal_process/pal_interfaceaddresses/SharedMemoryManager/NamedMutex/OperatingSystem/illink/RID 图/`dc3b15b3fda`/单文件与 AOT 分支）；aspnet `git diff upstream/main...HEAD` 全 delta（8 文件 358 行）逐条审阅；上轮 23 条逐项 grep/定位当下行号。未覆盖：OHOS 无关的上游提交、coreclr JIT/GC 非 OHOS 代码、on-device 行为。
- **D（sdk 签名/ELF/安装器）：** `ElfSigner.cs` 全 592 行、`OpenHarmonyCodesign.cs`、`Sdk.targets` OHOS 段、`eng/ohos-install/*`、`sign-ohos-pre.py`/`sign-ohos-release.sh`、`selfsign.cs`、CLI SelfSign、Workloads 清单与 R2R 分支；测试面 GivenAElfSigner（原缺畸形 ELF/符号链接/force 尾部丢失/膨胀覆盖，证据不计漏洞）。未覆盖：无法用 HEAD SDK 跑真实 `PublishSingleFile`（本机缺 ILLink 与 openharmony runtime pack，且禁网）。
- **E（sdk 补扫）：** `git diff 0e16377c..f2ada2da` 中 `SelfSign/**`、`Definitions/SelfSign/**`、`ElfSigner`/`OpenHarmonyCodesign`、`OpenHarmonyEnvironmentDefaults.cs`、`dotnet-aot/**`、`Layout/redist/**` 5 个改动文件。不确定：OHOS 内核对 `FLAG_SELF_SIGN`/厂商签名的校验策略在仓外；Layout 未实际构建验证；merge-base 用本地 `upstream/main`，未 fetch 最新。

**代表性命令（安全、只读；临时输出在 `/data/storage/el2/base/tmp/opencode/scan2/`）。**

```sh
# 枚举与定位
for r in runtime-ohos aspnetcore-ohos ohos-workload maui-ohos sdk-ohos; do
  git -C "$r" log --oneline --since=2026-09-21
done
git -C aspnetcore-ohos diff upstream/main...HEAD            # 8 文件 delta
grep -rInE 'TARGET_OPENHARMONY|openharmony' runtime-ohos/src runtime-ohos/eng --include='*.cs' --include='*.c' --include='*.cmake' --include='*.json'
grep -rnE 'raw_file|rawfile|RawFile' ohos-workload/src/OpenHarmonyHost ohos-workload/packs/*/templates/ets/pages/Index.ets
grep -rnE 'sha256.*hvigor|HVIGOR_SHA' ohos-workload/scripts ohos-workload/.github   # A2 修复前：无结果

# PoC（离线 toy/stub/mock）
sh  scan2/poc-d/a1/run_matrix.sh                       # A1 11 payload × 4 拼接模型
sh  scan2/poc-d/a2/run.sh                              # A2 stub curl/node
GH=scan2/poc-d/a3/bin/gh sh ohos-workload/scripts/release-all.sh --sdk-release ''  # A3 dry-run
python3 scan2/poc-a/repro/mkpkgs.py && sh scan2/poc-a/repro/run.sh                  # H-C1
node   scan2/poc-b/h-c2/isAppNavigation-harness.mjs    # H-C2
readelf -d / strings / nm -D  …/libSystem.Security.Cryptography.Native.OpenSsl.so   # H-C3
dotnet scan2/poc-c/drv/drv.dll sign real/apphost.bundled                             # D-1
python3 scan2/poc-c/run-d2.py && python3 scan2/poc-c/analyze-d2.py                   # D-2
sh run-d3.sh && sh run-d3b.sh                                                        # D-3
sh run-d4.sh                                                                         # D-4

# 本报告复核（离线）
sh sdk-ohos/eng/ohos-install/tests/test-installer-verification.sh   # 当时 passed=14 failed=0；当前 tip 43/43
sh sdk-ohos/eng/ohos-install/tests/test-hostfeed-verification.sh    # passed=10 failed=0
sh ohos-workload/scripts/selftest-tester-run.sh                      # checks: 315, failed: 1（工作树断言）
node fix-work/h-c2/harness.mjs                                       # ALL-PASS
```

## 方法注

本轮采用与上轮一致的"猎手候选 → PoC 对抗 → reproduce-then-fix → 复核"流水线；3 名猎手覆盖三面 + 2 名补扫猎手覆盖 sdk 深面，4 份独立 PoC 报告（poc-a..d）与 2 份补扫报告（sec-d/e）交叉验证。修复提交与验证证据在各自的提交信息与本报告表格中给出；本报告是扫描窗口快照，MB-2 的宿主侧收口（`9256305`/`92f7555`，315 项）已回填。
