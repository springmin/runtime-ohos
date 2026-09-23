# ArkTS/ArkCompiler 字节码（abc）版本史与 SDK 映射

> 2026-09-22 研究记录。目标：回答「怎么产出测试设备能接受的壳 abc」。
> 方法：公开资料（OpenHarmony docs、arkcompiler_runtime_core、华为开发者文档、repo.huaweicloud.com）
> + 本机只读检查（harmonybrew SDK 26.0.0.18_2 的 es2abc/ark_disasm、设备 `param`、`libark_jsruntime.so`）
> + 工作区既有构建产物取证。**本文未修改任何构建脚本、未执行仓库构建。**
> 读者对象：需要重出壳 abc / 重出 device-test-kit 的实现者。

## 0. 结论速览（TL;DR）

1. **abc 文件头的 version 是 4 字节**（`主版本.次版本.特性版本.编译版本`，每字节一个分量），位于偏移 12..15
   （magic 8B `PANDA\0\0\0` + adler32 4B 之后）。例：`24.0.0.0` = `18 00 00 00`，`13.0.1.0` = `0d 00 01 00`。
2. **版本由 es2abc 的 `--target-api-version=<API>` 决定**（API 12 另有 `--target-api-sub-version=<betaN>`）；
   `--bc-version` / `--target-bc-version` **只打印、不设置**。
3. **hvigor 把它绑定到工程级 `build-profile.json5` 的 `compatibleSdkVersion`**：SDK 的 ets-loader 直接拼
   `--target-api-version=${projectConfig.compatibleSdkVersion}`（本机 SDK 源码实证）。`compileSdkVersion`
   只决定用哪套 `.d.ts`。
4. 官方映射（`arkcompiler_runtime_core/isa/isa.yaml` + 本机 SDK 26 es2abc 实测）：
   - API 9/10 → `9.0.0.0`；API 11 → `11.0.2.0`；API 12 → `12.0.2.0`（beta1/2）/ `12.0.6.0`（beta3+）；
   - API 13–17 → `12.0.6.0`；**API 18–23 → `13.0.1.0`**；**API ≥24 → `24.0.0.0`**。
5. 我们的设备（HarmonyOS 7.0.0.109 / OpenHarmony-7.0.0.109，API 26）：`const.ark.version=24.0.0.0`。
   测试方设备（本机 SDK ark_disasm 自报上限 `13.0.1.0`，环境 OpenHarmony/HarmonyOS 6.0.2 / API 22）拒收 `24.0.0.0`。
6. **无需更换 SDK**：本工作区实测（2026-09-22）`compatibleSdkVersion:'18'` + `compileSdkVersion:'26.0.0'`
   （SDK 26.0.0.18_2）→ 壳 abc 头 = `13.0.1.0`，`CompileArkTS` 成功。
   → **推荐方案：把壳构建的 `compatibleSdkVersion` 设为 `'22'`（或 18–23 任意值）后重建壳 abc，重出 kit。**
7. 不要用「改 abc 头字节」的办法降版本（见 §6）；也不要指望 `--bc-version` 能设置版本（它只打印）。

## 1. abc 文件头与版本号

### 1.1 Header 布局（官方文档）

来源：OpenHarmony docs《方舟字节码文件格式》
（<https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/arkts-utils/arkts-bytecode-file-format.md>，
镜像 <https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/arkts-utils/arkts-bytecode-file-format.md>）
与 runtime_core 的英文版 <https://gitee.com/openharmony/arkcompiler_runtime_core/raw/master/docs/file_format.md>。

| 偏移 | 名称 | 格式 | 说明 |
|---|---|---|---|
| 0..7 | `magic` | `uint8_t[8]` | 必须是 `P A N D A \0 \0 \0` |
| 8..11 | `checksum` | `uint32_t` | 除 magic 与 checksum 外内容的 adler32（小端） |
| 12..15 | `version` | `uint8_t[4]` | **本文主角**：主.次.特性.编译 四个分量，各 1 字节 |
| 16..19 | `file_size` | `uint32_t` | 文件大小（小端） |

官方对 version 四个分量的定义：主版本=整体架构调整；次版本=局部架构或重大特性调整；特性版本=中小特性；
编译版本=缺陷修复。文档同时说明「任意支持格式版本 N 的工具必须也支持 N-1」。

### 1.2 实测 hexdump（本机产物）

```
# 24.0.0.0（旧壳，compatibleSdkVersion=26.0.0）
00000000: 5041 4e44 4100 0000 d3d5 867e 1800 0000  PANDA......~....
                                        ^^^^^^^^^^ 18 00 00 00 = 24.0.0.0

# 13.0.1.0（compatibleSdkVersion=18，2026-09-22 15:37/15:40 构建）
00000000: 5041 4e44 4100 0000 aca9 31ac 0d00 0100  PANDA.....1.....
                                        ^^^^^^^^^^ 0d 00 01 00 = 13.0.1.0
```

### 1.3 运行时如何校验（含依据与不确定标注）

- 设备系统库里有明确的比较与报错文案（本机 `strings -a /system/lib64/platformsdk/libark_jsruntime.so`）：
  `Maximum supported version is `、`Minimum supported version is `、
  `is not a compatible version, can't run on system image of version `、
  `Please upgrade the system image or use former version of SDK tools to generate abc files`、
  `and make the version of sdk tools and system image consistent`。
- 测试方现场用 ark_disasm 得到了同族报错（内部证据：
  `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md` §2.3）：
  `abc file version 24.0.0.0, Maximum supported abc file version is 13.0.1.0`。
- **推断（待双探针确认）**：运行时「可接受窗口」= `[min_version, version]`，两个值都直接对应
  `isa.yaml` 的 `min_version` / `version`。设备参数 `const.ark.minVersion` / `const.ark.version`
  就是这两个值（本机分别为 `0.0.0.2` / `24.0.0.0`）。详见 §5.4 的确定性验证法。

## 2. 版本史：abc 版本 → API / SDK / DevEco / 日期

### 2.1 权威映射：`isa.yaml` 的 `api_version_map`

OpenHarmony `arkcompiler_runtime_core/isa/isa.yaml`（runtime 与前端共享的文件格式/ISA 版本定义）：

- 6.0 时代分支（`version: 13.0.1.0`，映射到 API 20 为止）：
  <https://gitee.com/openharmony/arkcompiler_runtime_core/raw/master/isa/isa.yaml>：

  ```yaml
  min_version: 0.0.0.2
  version: 13.0.1.0
  # Due to historical reasons, bytecode version is upgraded to 13.0.1.0 in API18.
  api_version_map: [[0, 13.0.1.0], [9, 9.0.0.0], [10, 9.0.0.0], [11, 11.0.2.0], [12, 12.0.6.0],
                    [13, 12.0.6.0], [14, 12.0.6.0], [15, 12.0.6.0], [16, 12.0.6.0], [17, 12.0.6.0],
                    [18, 13.0.1.0], [19, 13.0.1.0], [20, 13.0.1.0]]
  ```

- 7.0 时代 master（`version: 24.0.0.0`，映射到 API 24）：
  <https://gitcode.com/openharmony/arkcompiler_runtime_core/blob/f0aff7ee251d99753ad8805d63df115e8bdf94dd/isa/isa.yaml>：

  ```yaml
  min_version: 0.0.0.2
  version: 24.0.0.0
  # Due to historical reasons, bytecode version is upgraded to 24.0.0.0 in API24.
  api_version_map: [[0, 24.0.0.0], [9, 9.0.0.0], [10, 9.0.0.0], [11, 11.0.2.0], [12, 12.0.6.0],
                    [13, 12.0.6.0], [14, 12.0.6.0], [15, 12.0.6.0], [16, 12.0.6.0], [17, 12.0.6.0],
                    [18, 13.0.1.0], [19, 13.0.1.0], [20, 13.0.1.0], [21, 13.0.1.0], [22, 13.0.1.0],
                    [23, 13.0.1.0], [24, 24.0.0.0]]
  ```

- 版本一变就必须走兼容性评审：`isa/check_version.py`（CI 脚本，
  <https://gitcode.com/openharmony/arkcompiler_runtime_core/blob/50e6833421118b58047d25025cd18f0dd99956ad/isa/check_version.py>）；
  相关 PR 示例「Fix arklink with target api version」（ABC 版本控制应由 arklink 输出最大版本）：
  <https://gitcode.com/openharmony/arkcompiler_runtime_core/merge_requests/14669>。

### 2.2 本机 es2abc 探针（SDK 26.0.0.18_2 实测，2026-09-22）

工具：`~/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_2/ets/build-tools/ets-loader/bin/ark/build/bin/es2abc`

```console
$ es2abc --bc-version            # 24.0.0.0
$ es2abc --bc-min-version        # 0.0.0.2
$ es2abc --target-bc-version --target-api-version <N>   # 见下表
```

| 目标 API | 9 | 10 | 11 | 12 | 13–17 | 18–23 | 24–26 | 8 |
|---|---|---|---|---|---|---|---|---|
| 输出 abc 版本 | 9.0.0.0 | 9.0.0.0 | 11.0.2.0 | 12.0.2.0 / 12.0.6.0¹ | 12.0.6.0 | **13.0.1.0** | 24.0.0.0 | 24.0.0.0² |

¹ API 12 取决于 `--target-api-sub-version`：`beta1`/`beta2` → `12.0.2.0`；`beta3`/`beta5`/`beta6`/`release`
→ `12.0.6.0`（与 hvigor schema 中「API 12 默认 beta1、只对 API 12 有效」一致）。API 13+ 的 sub-version
实测不影响结果。
² 历史遗留：es2abc 对 API 8 直接返回最新版本；旧 JS 工具链 `ts2abc.js` 里对 API 8 特判输出 `0.0.0.2`。

### 2.3 汇总表（abc → SDK/API → DevEco → 日期）

| abc 版本 | API | 公开 SDK（Public SDK 版本号）| DevEco Studio（对应发布）| 日期 | 依据 |
|---|---|---|---|---|---|
| `0.0.0.2` | API 8（JS 链特判） | — | 3.x 时代 | 2021–2022 | `ts2abc.js` 特判；isa.yaml `min_version` |
| `9.0.0.0` | API 9/10 | — | DevEco 3.1 / 4.0 期 | 2022–2023 | isa.yaml；不确定（未逐版核对 API 9/10 发布说明）|
| `11.0.2.0` | API 11 | Ohos_sdk_public 4.1(11) 系 | DevEco 4.1 Release | 2024-03~ | 不确定（推算）|
| `12.0.2.0` | API 12 beta1/beta2 | 5.0 Beta 系 | DevEco 5.0.0 Beta 系 | 2024 上半年 | isa.yaml 只列 `[12, 12.0.6.0]`；本机 es2abc 实测 stage 差异 |
| `12.0.6.0` | API 12(beta3+)–17 | Ohos_sdk_public 5.0.x（API 12/13/14/15） | DevEco 5.0.0/5.0.1/5.0.2/5.0.3 Release | 2024-09-29（OH 5.0.0）/ 2024-11-22（5.0.1）/ 2025-01-22（5.0.2）/ 2025-03-21（5.0.3） | OpenHarmony release notes Readme + isa.yaml |
| **`13.0.1.0`** | **API 18–23** | Ohos_sdk_public 5.1.0.107(18) / 6.0.0.47(20) / 6.0.0.48(20) / 6.0.0.49(20) / 6.1.0.31(23)；HarmonyOS 6.0.2 SDK = Ohos_sdk_public 6.0.2.130(22) | DevEco 5.1.0 / 5.1.1 / 6.0.0 / 6.0.1 / 6.0.2 / 6.1.0 | 2025-04-30（5.1.0）/ 2025-09-06（6.0）/ 2026-01-21（HarmonyOS 6.0.2）/ 2026-03-07（OH 6.1）| isa.yaml + 各 release notes（§8）|
| `24.0.0.0` | API 24–26 | SDK 26.0.0.18_x（本机 harmonybrew）| DevEco 7.0 系 | 2026（7.0-Release 目录 2026-08-29）| isa.yaml（新 master）+ 本机 SDK 实测；API 25/26 只有本机证据 |

注：**OpenHarmony 6.0 / 6.0.0.1 / 6.0.0.2 都还是 API 20**（Public SDK 6.0.0.47/48/49）；
API 21/22/23 分别对应 HarmonyOS 6.0.1 / HarmonyOS 6.0.2 / OpenHarmony 6.1 Release。
仓内「测试方本机 OpenHarmony 6.0.2 / API 22」应理解为 **HarmonyOS 6.0.2（API 22）SDK**（其 SDK 号 6.0.2.130）。

### 2.4 两个锚点的交叉验证

| 锚点 | 事实 | 来源 |
|---|---|---|
| 本机设备 | HarmonyOS `7.0.0.109(SP3ENTC293E104R2P1log)` / `OpenHarmony-7.0.0.109`，`const.ohos.apiversion=26`；`const.ark.version=24.0.0.0`；`const.ark.minVersion=0.0.0.2`；ark_disasm `--version` 报 Bytecode version 24.0.0.0 | 本会话只读检查（§5） |
| 测试方设备 | 壳 abc `24.0.0.0` 被拒；其 SDK `ark_disasm` 自报上限 `13.0.1.0`；最小壳用其本机工具链编译后**可以装、入口能解析**（E4） | `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md` §2.3、§2.2 |

两者完全吻合 §2.1 的映射：API ≤23 的 runtime 只到 `13.0.1.0`。

## 3. 谁决定发出的版本（问题 2）

### 3.1 es2abc 的版本相关开关（exact syntax + 实测效果）

`es2abc --help` 原文（本机 SDK 26.0.0.18_2）：

| 开关 | 类型 | 文档/实测效果 |
|---|---|---|
| `--bc-version` | 打印 | 「Print ark bytecode version.」→ 本机 `24.0.0.0`；**不能设置** |
| `--bc-min-version` | 打印 | 「Print ark bytecode minimum supported version」→ `0.0.0.2`；**不能设置** |
| `--target-bc-version` | 打印 | 「Print the corresponding ark bytecode version for target api version.」需与 `--target-api-version` 组合；**不能设置** |
| `--target-api-version=N` | **设置** | 「Specify the targeting api version for es2abc to generated the corresponding version of bytecode」→ 直接决定输出 abc 的 4 字节 version |
| `--target-api-sub-version=S` | 设置（次要） | 「Specify the targeting api sub version…」→ 仅 API 12 的 beta 阶段影响结果（beta1/2→12.0.2.0；beta3+→12.0.6.0） |

实测（`es2abc --module --target-api-version=22 /tmp/v22.js` → header `0d 00 01 00`）：
`--target-api-version` 是**唯一**能设置输出版本的用户可及开关。

**没有**发现「SDK 里有一个版本文件」能改输出：`es2abc` 是二进制，映射表编译在内；
SDK 的 `oh-uni-package.json` 只描述 SDK 自身（`apiVersion/platformVersion/releaseType`），
不被 es2abc 用于版本输出。

### 3.2 hvigor 的接线（决定 `--target-api-version` 的来源）

1. 工程级 `build-profile.json5` 的 `app.products[].compatibleSdkVersion` 是源头（华为文档：
   「标识应用/元服务运行所需兼容的最低 SDK 版本，应用/元服务不能安装在低于该版本的设备」；
   <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-build-profile-app>，
   镜像文本 <https://github.com/YouniQiao/developer_hos/blob/master/docs/tools/coding-debug/ide-hvigor-build-profile-app.md>）。
2. hvigor 把该值转交 ets-loader；ets-loader 在 module/bundle 两条编译路径里都会拼：
   `<SDK>/ets/build-tools/ets-loader/lib/fast_build/ark_compiler/module/module_mode.js`：
   `this.cmdArgs.push("--merge-abc"), this.cmdArgs.push(\`"--target-api-version=${this.projectConfig.compatibleSdkVersion}"\`)`；
   若配置了 `compatibleSdkVersionStage` 再追加 `--target-api-sub-version=...`（`bundle/bundle_mode.js` 同）。
3. hvigor 的 JSON schema（本机 `hvigor-ohos-plugin/res/schemas/ohos-project-build-profile-schema.json`）对
   `compatibleSdkVersionStage` 的描述直接点名：「Specifies the **abc compiler version** compatible with the
   OpenHarmony application during compilation… applicable only to API version 12」（enum `beta1..beta6/release`）。
4. 该值的另外两个可见后果：
   - 打包进 HAP 的 `minAPIVersion`（packing-tool 文档：`minAPIVersion` ← `compatibleSdkVersion`；
     `targetAPIVersion` ← `targetSdkVersion`/`compileSdkVersion`）。
   - 实测：把 `compatibleSdkVersion` 设为 `'18'` 后，hvigor 生成的 `module.json` 里
     `minAPIVersion=18`、`targetAPIVersion=26`、`compileSdkVersion="26.0.0.18"`。
5. 公开佐证（社区构建日志）里能看到 DevEco 调 es2abc 时确实带这个参数：
   `--merge-abc "–target-api-version=12"`（<https://bbs.itying.com/topic/670618b0bb648a00d09883e0>）。

### 3.3 哪些能降、哪些不能

| 手段 | 能/不能 | 说明 |
|---|---|---|
| 设 `compatibleSdkVersion`（工程级 build-profile.json5） | **能** | 不改 SDK；本机实测 26 工具链发 `13.0.1.0`（§3.4） |
| 直接调 `es2abc --target-api-version=22` | **能** | 单文件/自定义流程可用；但壳是 hvigor 流水线，应改配置 |
| 设 `compatibleSdkVersionStage` | 只对 API 12 有效 | API 12 beta 阶段细分；≥13 无效果（实测 + schema 描述）|
| `--bc-version` / `--target-bc-version` | **不能** | 只打印；传了也不会改输出 |
| 换旧 SDK | 不必需 | 旧 SDK 默认版本低，但新 SDK + `compatibleSdkVersion` 已能发旧版本 |
| 构建后改 abc 头 4 字节 | **不要** | 见 §6 方案 4；还要重算 adler32，且不保证 opcode/结构兼容 |

### 3.4 本工作区实测证据（决定性）

观测时刻 2026-09-22（工作区 `ohos-workload/.arkts-build/project`，SDK 26.0.0.18_2）：

| 构建配置 | 产物 | 头部 version | 备注 |
|---|---|---|---|
| 三项均 `26.0.0`（build-arkts-shell.sh 默认） | `dist/ets/modules.abc` 15:09 | `18 00 00 00` = 24.0.0.0 | 当时 kit 的壳 abc 就是它（kit #11 起改为 `compatibleSdkVersion 18` 的 `13.0.1.0`）|
| `compileSdkVersion 26.0.0` + `compatibleSdkVersion '18'` + `targetSdkVersion 26.0.0` | `entry/build/.../loader_out/default/ets/modules.abc` 15:37:28（14,708 B）与 `dist/ets/modules.abc` 15:40:33（191,072 B） | `0d 00 01 00` = **13.0.1.0** | 该次 `@CompileArkTS` **成功**；仅在 `@PackageHap` 因缺 `app_packing_tool.jar` 失败（与本问题无关，.NET workload 打包不走这步）；hvigor 缓存 `project-config.json` 记录 `compatibleSdkVersion: 18` |

> 说明：工作区同时有其他构建在跑，文件时间/大小以实际为准；两个版本的头部字节已独立 hexdump 确认。

## 4. 可下载 SDK 与壳的可编译性（问题 3）

### 4.1 规则

- SDK 的**默认**输出 = 其 `es2abc --bc-version`：**API ≤23 的 SDK 都 ≤ `13.0.1.0`**；
  API ≥24 的 SDK 默认 `24.0.0.0`。
- 即使是 SDK 26，只要 `compatibleSdkVersion` ∈ [18,23]，输出就是 `13.0.1.0`（§3.4 实测）。
  所以「产出 ≤13.0.1.0」有两条路：**新 SDK+低 compatibleSdkVersion（推荐）** 或 直接装旧 SDK。

### 4.2 公开下载（OpenHarmony Public SDK，免账号）

入口：<https://repo.huaweicloud.com/openharmony/os/>（各 Release 目录内有 `ohos-sdk-*.tar.gz` 与同名 `.sha256`）。

| Release 目录 | SDK 版本（API）| 目录内 SDK 包 | Windows/Linux 大小 | macOS 大小 | 日期（目录）|
|---|---|---|---|---|---|
| `5.1.0-Release/` | 5.1.0.107（API 18）| `ohos-sdk-windows_linux-public.tar.gz` / `ohos-sdk-mac-public.tar.gz` | 3.2 GiB | 1.3 GiB | 2025-05-03 |
| `6.0-Release/` | 6.0.0.47（API 20）| 同上 | 2.3 GiB | 1.3 GiB | 2025-12-02 |
| `6.0.0.1-Release/` | 6.0.0.48（API 20）| 同上（mac 1.0 GiB）| 3.0 GiB | 1.0 GiB | 2026-01-20 |
| `6.0.0.2-Release/` | 6.0.0.49（API 20）| 同上 | 3.0 GiB | 1.3 GiB | 2026-03-20/23 |
| `6.1-Release/` | 6.1.0.31（API 23）| 同上 | 2.3 GiB | 1.3 GiB | 2026-03-07 |
| `7.0-Release/` | 未取（API 26 系）| 同上 | 未取 | 未取 | 2026-08-29 |

校验：每个包旁有 `.sha256`（65 B），可直接 `sha256sum -c`；部分目录另给 `L2-SDK-MAC-M1-PUBLIC.tar.gz`。
**API 22（HarmonyOS 6.0.2）的 SDK**：走 DevEco Studio 6.0.2（6.0.2.640，2026-01-21；SDK 基于
Ohos_sdk_public 6.0.2.130 / API 22 Release）——这就是测试方本机工具链的来源；华为侧可能需要账号/DevEco。
结论：**要「旧 SDK」就下 `6.0.0.2-Release`（API 20，`13.0.1.0`）或更早**；但推荐方案并不需要下载。

### 4.3 壳用到的 ArkTS/ArkUI 特性核查

对 `packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/templates/ets/{entryability/EntryAbility.ui.ets,pages/Index.ets}`
的静态盘点：

- **装饰器**：`@Entry`、`@Component`、`@State`(×10)、`@Watch`、`@StorageProp` —— 全是 **状态管理 V1**，
  没有 `@ComponentV2/@Local/@Param/@Once/@Event/@Monitor/@Computed`（**不需要 API 12 的 V2 能力**）。
- **import**：`@kit.AbilityKit`、`@kit.ArkUI`、`@kit.BasicServicesKit`、`@kit.CalendarKit`、
  `@kit.ConnectivityKit`、`@kit.NetworkKit`、`@kit.PerformanceAnalysisKit`（kit 命名空间自 API 12 起）；
  `@ohos.abilityAccessCtrl`、`@ohos.app.ability.{Want,common,wantConstant}`、`@ohos.arkui.node`、
  `@ohos.commonEventManager`、`@ohos.display`、`@ohos.file.fs`、`@ohos.file.picker`、
  `@ohos.geoLocationManager`、`@ohos.multimedia.camera`、`@ohos.pasteboard`、`@ohos.print`、
  `@ohos.util`、`@ohos.web.webview`、`@ohos.window`、`@ohos.zlib`，以及 NAPI `libopenharmonyhost.so`。
- **关键 API 的引入版本**（本机 SDK 26 d.ts + 官方 release notes 交叉核对）：
  最高的是 `abilityAccessCtrl.getSelfPermissionStatus` = **API 20**（OpenHarmony 6.0 release notes 链接
  `js-apis-abilityAccessCtrl.md#getselfpermissionstatus20`）；`window.setWindowTitle` API 15；
  `webview.getLastJavascriptProxyCallingFrameUrl` / `registerJavaScriptProxy` API 12 级别；
  `display/pasteboard/util/zlib/picker/geo/camera/print` 等 ≤ API 9–13；
  `XComponent(surface)`、`NodeContent`、`registerJavaScriptProxy`、`MenuElement` 等均为更早版本。
- **编译期判定**：`@kit.*` 要求 **API ≥12**；API 22 SDK 的 d.ts 覆盖上述全部 API。
  → **壳可以在 API 22（甚至 18–20）SDK 下编译**；壳里对高版本 API 的调用已包在 `try/catch` +
  `typeof` 守卫里（`clipboardPermissionGranted`、`getLastJavascriptProxyCallingFrameUrl`、
  `setWindowTitle`、动态 `import()` 的可选 Kit），在低版本设备上走「不可用/降级」分支。
- **若把 compatibleSdkVersion 降到 18/19**：仅 `getSelfPermissionStatus`（API 20）在 **TYPECHECK=1**
  构建时会变成「使用高于 compatibleSdkVersion 的 API」告警/错误；当前发布构建 `TYPECHECK=0` 不受影响
  （但建议选 22，与测试方 runtime 对齐，避免这个坑）。
- **若进一步降到 API ≤17**（abc `12.0.6.0`，无必要）：除上面一项外，`setWindowTitle`(15)、
  `getLastJavascriptProxyCallingFrameUrl`(12) 等也要按 `@Available` 语义加守卫；不建议。

## 5. 怎么查设备支持的 abc 版本（问题 4）

### 5.1 首选：读设备运行时参数

```bash
hdc shell param get const.ark.version      # 设备运行时支持的最大 abc 版本；本机 = 24.0.0.0
hdc shell param get const.ark.minVersion   # 支持的最小 abc 版本；本机 = 0.0.0.2
hdc shell "param get | grep -i ark"        # 兜底：列出设备上所有 ark 相关参数
```

- 语义依据：两参数值与本机设备所配 `isa.yaml` 的 `version/min_version` 完全一致（§2.1/§2.4）；
  **但「参数=运行时上限」目前是强推断**（未读到官方定义常量参数的源码），务必用 §5.4 复核一次。
- 预期：API ≤23 设备（含测试方 6.0.2/API 22）应返回 `13.0.1.0`；API 26 本机返回 `24.0.0.0`。

### 5.2 设备日志/工具侧关键字

```bash
# 设备运行应用时抓 hilog（版本不符会打印 Maximum supported / not a compatible version 等）
hdc shell hilog | grep -iE "bytecode version|file format version|Maximum supported|not a compatible version|former version of SDK tools"
```

工具侧（不是设备）：测试方已用 ark_disasm 得到 `abc file version 24.0.0.0, Maximum supported abc file version is 13.0.1.0`；
本机 SDK 的 `ark_disasm --version` 输出：

```
Ark version 0.0.0
Bytecode version 24.0.0.0
Minimum supported bytecode version 0.0.0.2
```

`strings /system/lib64/platformsdk/libark_jsruntime.so | grep -i "supported version"` 也能看到 §1.3 的文案，
但**不要**用 strings 猜版本号（版本常量不是字符串）。

### 5.3 直接读 abc 头 + SDK 侧自检

```bash
# 本地/回传的 abc：偏移 12..15 即版本（设备无 xxd 时用 od）
xxd -l 16 modules.abc            # 或: od -A x -t x1z -N 16 modules.abc
# 13.0.1.0 -> 0d 00 01 00 ; 24.0.0.0 -> 18 00 00 00

# SDK 工具链（本地，不是设备）：
<SDK>/ets/build-tools/ets-loader/bin/ark/build/bin/es2abc --bc-version
<SDK>/ets/build-tools/ets-loader/bin/ark/build/bin/es2abc --target-bc-version --target-api-version 22
<SDK>/toolchains/ark_disasm --version
```

### 5.4 确定性双探针（推荐在测试设备上做一次）

用本机 `es2abc --target-api-version=26` 和 `=22` 各编一个最小 abc（如 `let x=1; --module --merge-abc`），
分别安装/加载并抓 hilog：设备应**拒绝** 24.0.0.0、**接受** 13.0.1.0。这一步同时验证了
「param 值 = 实际可接受上限」，避免只依赖推断。

## 6. 方案排序（问题 5：在 ≤13.0.1.0 的 runtime 上跑壳）

| # | 方案 | 工作量 | 体积影响 | 风险 | 结论 |
|---|---|---|---|---|---|
| **1** | **改 `compatibleSdkVersion: '22'`（或 18–23），用现有 SDK 26 重建壳 abc，重出 kit** | 1 处配置 + 重建 + 复验（~小时级）| ≈0（同一编译器）| 低：工具链原生支持；本机已实测出 `13.0.1.0`；只影响壳 abc 与 HAP 的 `minAPIVersion` | **推荐** |
| 2 | 用测试方本机 API 22 SDK（或下载 `6.0.0.2-Release`，3.0 GiB）编译壳 | 中（环境/流水线适配）| ≈0 | 中：多一套工具链变量；结果同为 `13.0.1.0` | 备选 |
| 3 | 降到 API ≤17（`12.0.6.0`）再重建 | 大（要加 `@Available` 级别守卫与回归）| ≈0 | 中高 | 不必要（设备接受 13.0.1.0）|
| 4 | 构建后把 abc 头 4 字节改成 `13.0.1.0` | 小 | 0 | **高**：需重算 adler32；且 24.0.0.0 编译产物可能含旧 runtime 不认的 opcode/结构；无官方支持 | **不要** |
| 5 | 请测试方换 API ≥24 设备 | 0（我们）| 0 | 不受控 | 并行沟通项，不能作为唯一方案 |

推荐方案 1 的落地要点（实现细节供后续工单引用）：

1. 在 `ohos-workload/scripts/build-arkts-shell.sh` 生成 `build-profile.json5` 的 python heredoc 里，
   把 `compatibleSdkVersion: '{platform_version}'` 改为固定兼容值（建议 `'22'`，与测试方 runtime 对齐；
   `compileSdkVersion` 保持 `platform_version`，`targetSdkVersion` 可保持 26 或一并降 22——见下面风险）。
2. 复验（构建脚本末尾或 release 校验里加断言）：

   ```bash
   python3 - <<'PY'
   b = open('dist/ets/modules.abc', 'rb').read(16)
   assert b[:8] == b'PANDA\0\0\0', b[:8]
   v = '.'.join(str(x) for x in b[12:16])
   print('abc version', v)          # 期望 13.0.1.0
   assert v == '13.0.1.0'
   PY
   ```

3. 重出 kit 后按 `docs/plans/2026-09-21-ohos-device-run-playbook.md` 的流程请测试方复测；同时带上
   `tester-run.sh` 抓 hilog，确认不再出现 `Maximum supported abc file version is 13.0.1.0` 类报错，
   且 PA1 的入口 record 修复仍在（两个问题是独立的：记录名 + 版本）。

风险/注意：

- `targetSdkVersion` 若保持 26，HAP 的 `targetAPIVersion=26`；安装门限由 `minAPIVersion`（=compatibleSdkVersion）
  决定，但为减少行为差异，建议 `targetSdkVersion` 也设为 22（需一次真机回归）。
- `TYPECHECK=1` 的构建在 `compatibleSdkVersion<20` 时可能因 `getSelfPermissionStatus` 报错；
  选 22 可避免；发布构建默认 `TYPECHECK=0`。
- 本工作区 15:40 已有一个 `compatibleSdkVersion=18` 版 `dist/ets/modules.abc`（13.0.1.0，191,072 B）；
  它能否直接作为交付物取决于当时源码是否已含 PA1 修复——**必须重跑一次构建并复验头部+入口 record 后再用**。

## 7. 不确定项与待办

1. `const.ark.version` = 「运行时最大可接受 abc 版本」为强推断（值吻合 isa.yaml），需 §5.4 双探针确认。
2. `api_version_map` 中 API 21/22/23 行只在 7.0 时代 master 可见；与公开 Release 的对应关系
   （HarmonyOS 6.0.1=21 / 6.0.2=22 / OH 6.1=23）来自各自 release notes，但 API 21 未见单独 SDK 号，标记为
   「推断一致」。
3. DevEco Studio 具体小版本 → API 的完整矩阵（API 12–20 列）部分为按同名发布推断，未逐页取 Version Mapping。
4. API 24/25/26 都映射到 `24.0.0.0` 只有本机 es2abc 证据（公开 master 只列到 `[24, 24.0.0.0]`）。
5. `--target-api-version` 是否同时收敛 opcode 集合（避免旧 runtime 读到新指令）：help 文案说
   「generated the corresponding version of bytecode」，本次未做 disasm 对比；双探针/真机复测即覆盖。
6. 测试方 kit 的 `modules.abc` 新壳是否已修复入口 record（见 `2026-09-22-ohos-startup-crash-rootcause.md` §2）
   与本文的版本问题是**两个独立阻塞**，需同时满足。

## 8. 来源

公开资料：

- abc 文件格式（官方）：<https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/arkts-utils/arkts-bytecode-file-format.md>
  · 英文 runtime_core 版：<https://gitee.com/openharmony/arkcompiler_runtime_core/raw/master/docs/file_format.md>
- isa.yaml/版本映射：<https://gitee.com/openharmony/arkcompiler_runtime_core/raw/master/isa/isa.yaml>
  · 24.0.0.0 版：<https://gitcode.com/openharmony/arkcompiler_runtime_core/blob/f0aff7ee251d99753ad8805d63df115e8bdf94dd/isa/isa.yaml>
  · CI 版本检查：<https://gitcode.com/openharmony/arkcompiler_runtime_core/blob/50e6833421118b58047d25025cd18f0dd99956ad/isa/check_version.py>
  · arklink 版本控制 PR：<https://gitcode.com/openharmony/arkcompiler_runtime_core/merge_requests/14669>
- OpenHarmony 发布说明（API/SDK/日期）：5.1.0（API 18）<https://gitee.com/openharmony/docs/raw/master/en/release-notes/OpenHarmony-v5.1.0-release.md>
  · 6.0（API 20）<https://gitee.com/openharmony/docs/raw/master/en/release-notes/OpenHarmony-v6.0-release.md>
  · 6.0.0.1（API 20）<https://gitee.com/openharmony/docs/raw/master/zh-cn/release-notes/OpenHarmony-v6.0.0.1-release.md>
  · 6.0.0.2（API 20）<https://gitee.com/openharmony/docs/raw/master/zh-cn/release-notes/OpenHarmony-v6.0.0.2-release.md>
  · 6.1（API 23）<https://gitee.com/openharmony/docs/raw/master/zh-cn/release-notes/OpenHarmony-v6.1-release.md>
  · 版本索引：<https://gitee.com/openharmony/docs/raw/master/en/release-notes/Readme.md>
- HarmonyOS 6.0.2（API 22，DevEco 6.0.2/SDK 6.0.2.130）：
  <https://developer.huawei.com/consumer/cn/doc/doccenter-release-notes/overview-602>
  · 英文：<https://developer.huawei.com/consumer/en/doc/harmonyos-releases/deveco-studio-new-features-602>
- 工程级 build-profile.json5（compatibleSdkVersion/compatibleSdkVersionStage）：
  <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-build-profile-app>
  · 镜像文本：<https://github.com/YouniQiao/developer_hos/blob/master/docs/tools/coding-debug/ide-hvigor-build-profile-app.md>
- packing-tool（minAPIVersion ← compatibleSdkVersion）：
  <https://gitcode.com/openharmony/docs/blob/OpenHarmony-6.0-Release/zh-cn/application-dev/tools/packing-tool.md>
- SDK 下载：<https://repo.huaweicloud.com/openharmony/os/>（5.1.0/6.0/6.0.0.1/6.0.0.2/6.1/7.0 目录）
- 社区佐证（hvigor 传 `--target-api-version`）：<https://bbs.itying.com/topic/670618b0bb648a00d09883e0>

仓内证据：

- `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md` §2.2/§2.3（测试方 E1–E5、ark_disasm 版本报错）。
- `ohos-workload/.arkts-build/project/build-profile.json5`、`.hvigor/cache/project-config.json`
  （`compatibleSdkVersion: 18`，`compileSdkVersion: 26`）。
- 本机只读检查（2026-09-22）：
  - SDK `~/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_2`（`ets/oh-uni-package.json`: apiVersion 26/platformVersion 26.0.0.18/releaseType Beta；
    `es2abc --bc-version`=24.0.0.0、`--bc-min-version`=0.0.0.2；`es2abc --target-bc-version --target-api-version <N>` 全表）；
  - ets-loader 源码 `.../ets-loader/lib/fast_build/ark_compiler/module/module_mode.js`、
    `.../bundle/bundle_mode.js`；hvigor schema `.../hvigor-ohos-plugin/res/schemas/ohos-project-build-profile-schema.json`；
  - 设备：`param get const.ark.version|const.ark.minVersion|const.ohos.apiversion|const.product.software.version`、
    `strings /system/lib64/platformsdk/libark_jsruntime.so`、`ark_disasm --version`；
  - 产物 hexdump：`dist/ets/modules.abc`（15:09 → 24.0.0.0；15:40 → 13.0.1.0）、
    `loader_out/default/ets/modules.abc`（15:37 → 13.0.1.0）、
    `packs/.../templates/ets/modules.{shell,ui}.abc`（13:18 → 24.0.0.0）。
