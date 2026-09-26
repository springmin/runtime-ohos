# 设备侧启动崩溃：诊断与重测包（JsError / exit 254）

> 对象：本轮真机首发报告的测试方 —— 设备 **OpenHarmony 7.0.0.105 / API 26 / 2in1**，
> UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`。
> 现象：hap 安装成功，`aa start` 后约 1 秒应用退出（exit 254），`AppKilledReporter` 报 `reason=JsError`。
> 本页只做三件事：**换当前 kit 重测** → **取最小崩溃证据** → **回传 §5 清单**。命令可照抄；结论以设备实测为准。
> 相关文档（kit 内）：`真机操作手册.md`（校验/安装/取证）、`验收说明.md`（完整清单与模板）、`签名与UDID指南.md`（9568344）。
>
> **2026-09-24 更新（kit #24）**：本文所写的三类旧崩溃 —— 入口 record（kit #10）、abc 版本（kit #11）、宿主加载（kit #12）—— 均已在当前 kit 修复；此后追加 P17 跳过重复解压、H7 rawfile 文件描述符直读、headless 变体 abc `13.0.1.0`，并在 kit #22 回灌设备里程碑修复：宿主 `DT_NEEDED` 5 库 + 可选 API 按需 dlsym、HAP `resources.index`（restool）、启动解压 ZIP offset/length + mkdir、DevEco 工程布局（kit #23 = 工具刷新：强化 `verify-kit.sh` + `tester-run.sh` v7 入包）。**kit #24**：payload 进 hap `libs/arm64-v8a/` 原地启动（`.dotnet-payload.json`，`dotnet.zip` 回退）、宿主显式 `DOTNET_EnableWriteXorExecute=0` + `xwe.txt` A/B + exec-memory 探针（§2.6，采集为 `hilog/hilog-execmem.txt`）；不含 seccomp 拦截器。**2026-09-24 设备证据修正**：黑屏/失败的直接链是宿主加载 + bootstrap 三项（`resources.index` / ZIP offset / mkdir）+ abc 编译，共 5 项，而非旧 #4（`libIsolation`/napi 记录名；已降级为无害加固）—— 见 `docs/plans/2026-09-24-ohos-device-milestone.md` 与 `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md` §5f。JIT 崩溃（`SEGV_ACCERR`）的判定与 NativeAOT 指引见 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`；`tester-run.sh` **v8** 会自动采集 `hilog/hilog-applib.txt`、`hilog/hilog-dlopen.txt`、`hilog/hilog-bootstrap.txt`、`hilog/hilog-execmem.txt`、`device/app-libs-arm64.txt`、`device/payload-files.txt`/`payload-marker.txt`、`meta/kit-selfcheck.txt`（§2.4–§2.6）；整包/内容树数字以 release「## Integrity」为准。`签名说明.txt` 的 PA1 历史句已随源修复（`c6a4cd95e`），若副本仍出现按历史文案处理。
>
> **2026-09-28 更新（kit #28，当前）**：R2 —— **Map 覆盖层**（`ARKTS_SDK_FLAVOR=harmony` 壳 + AGC 地图 AppKey；默认 flavor 下 `IsSupported` 可为 true 而 `IsOverlayAvailable=false`，show/hide/区域/标记等调用**降级不抛**）、**LiveView 特性探测**（无 Kit/权益时 `IsSupported=false`、Start/Update/Stop `Unavailable` 不抛）、**壳 `start_app` AOT 启动桥**（`lib<stem>.so` → `openharmony_app_main`，日志 `aot=1`；失败 `aot=0` 回退 hostfxr）与**解释器实验**（`<files>/interp.txt` → `DOTNET_InterpMode`，日志 `interp=3 source=file`）。宿主导出契约 **134/134**；ui/shell abc → **264,136 B**。**启动崩溃判定（`probe:`/`xwe`、P1–P4、bootstrap）不变**，kit #28 回归点 = 重建 payload（新 abc + 新宿主 + R2 壳桥）仍正常启动、JIT hap 的 AOT 探针以 `aot=0` 回退不阻塞、原生桥/回调行为与 #27 一致、无 Kit 探测不崩。`verify-kit.sh` 的 abc 期望已重锚 `264136`（用 #27 的 `245412` 或更旧值校验会 FAIL，属预期）。本轮增量判定点见 `docs/plans/2026-09-28-ohos-tester-handoff-kit28.md` §2。
>
> **2026-09-27 更新（kit #27；历史）**：KIT-EXT2 —— 壳对 Push/Account/Map 三个 HMS Kit 做特性探测（无 Kit/AGC/HMS 时 sink 不注册、值 `Unavailable`/null/false，**不抛**）、宿主新增 12 个 kit sink（导出契约 118/118 → **130/130**）+ FIX-R1-NAPI-6D 边界加固、反向条目改走 off-runtime marshaller（`[UnmanagedCallersOnly]` + `delegate* unmanaged[Cdecl]` thunk）；ui/shell abc → **245,412 B**、hap 内宿主 → **265,120 B**、hosting DLL → 55,296 B。kit #27 回归点 = 重建 payload（新 abc + 新宿主 + marshal-off 托管）仍正常启动、原生桥/回调行为与 #26 一致、无 HMS 探测不崩（判定点见 `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md` §2）。
>
> **2026-09-26 更新（kit #26；历史）**：互操作/打包/平台缺口收口 —— hosting 桥全量 `LibraryImport`（125 处，`DllImport` 归零，导出契约 118/118；hap 内 hosting DLL 55,808 B）、hap 打包任务程序集化（pack `tools/Microsoft.OpenHarmony.Tasks.dll`）、AspNetCore KFR/RID/apphost 缺省化（消费方无需工程级规避）；**启动崩溃判定（`probe:`/`xwe`、P1–P4、bootstrap）不变**，kit #26 回归点 = 重建 payload（LibraryImport hosting）仍正常启动、原生桥行为与 #25 一致。kit #25 的权限/Share/Scan/AOT 判定点继续有效（见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`），其增量判定点见 `docs/plans/2026-09-26-ohos-tester-handoff-kit26.md` §2。
>
> **2026-09-25 更新（kit #25）**：新增权限链（`reason`/`usedScene` + 请求点门禁）、Share/Scan 特性探测（OpenHarmony SDK 上 `shareDispatch=False`/`scanSupported=False` 干净降级）与 AOT 启动路径（`lib<stem>.so` → `openharmony_app_main`，hostfxr 回退）；启动崩溃判定（`probe:`/`xwe`、P1–P4、bootstrap）**不变**，kit #25 回归点 = JIT hap 仍走 hostfxr 回退正常启动。本轮判定点（权限弹窗文案 / Share 面板 / Scan 返回 / AOT 启动）见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`。

## 0. 一页摘要

1. 你报告里用的是 **workload preview.23**；当前交付基线是 **preview.24**，且 2026-09-21 当天落下的
   一批**启动相关修复**（宿主 pending-context 释放、早到生命周期事件排队、宿主失败路径清理等，见安全扫描 A1/A6/A7/N1–N4）
   **只在当前 kit 里**。请先花几分钟用当前 kit 重测一次 —— 这比任何离线分析都快，且可能直接消掉崩溃。
2. 若仍崩：按 §2 录一段 `hilog`（崩溃点前后各 200 行）回传，顺手做 §3 的三个 A/B（各 5 分钟）。
3. 你上轮为安装改过的两处（bundleName 去连字符、module.json 波段对齐）**我们已确认在修**（§4），下轮无需再手改；
   这两点能解释"装不上"，但**不一定**解释 JsError，所以仍以 §1–§3 的证据为准。

## 1. 第一步：用当前 kit 重测（务必先做）

### 1.1 下载 + 校验（先记录 sha256 与 tree digest，再安装）

```sh
base=https://github.com/springmin/sdk-ohos/releases/download
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz"          # 镜像：$base/workload-latest/device-test-kit.tar.gz
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz.sha256"
sha256sum -c device-test-kit.tar.gz.sha256        # ① 外层压缩包校验
sha256sum device-test-kit.tar.gz > kit-sha256.txt # ② 记录（回传用）
mkdir -p device-test-kit && tar xzf device-test-kit.tar.gz -C device-test-kit
cd device-test-kit
sh verify-kit.sh --anchor-file ../device-test-kit.tar.gz              # ③ 包内逐文件 + 外层锚定
sh verify-kit.sh --expect-tree-digest <发布说明给出的 tree sha256>    # ④ 绑定解压内容树
# 发布说明没有 tree sha256 时：先打印，再把它回传
sh verify-kit.sh --tree-digest
```

- 期望最后一行 `KIT OK`；出现 `FAIL/WARN`（校验不符、缺 hap/文档）**先重新下载解压**，不要带病安装。
- ③④ 的区别：`SHA256SUMS` 在包内，只能证明包内自洽；`--anchor` 只绑定下载的 `.tar.gz` 文件本身；
  `--expect-tree-digest` 才绑定**解压后的内容树**（文件被增删改会失败）。
- **版本核对**：打开 kit 内 `最终状态.md`（「发布物」一节）或 `README-交付说明.md`（「构建基线」行），
  把版本原文回传（当前官方基线应为 `1.0.0-preview.24`）。
  若你手上没有 `最终状态.md`、或它写的是 **preview.23** → 说明是旧包：请换包重测，旧包的崩溃结论我们不会采用。

### 1.2 安装与启动

沿用你上轮的成功路径（你自己的华为 debug 证书）；当前 kit（#26，P2-INTEROP/TASK-MIG/PLAT-GAP；权限链/Share-Scan/AOT 沿用 #25，含 #24 payload-in-libs）的 5 个 hap 已是合法 bundleName 与设备波段，**无需改名、无需手改 module.json**，其它文件也不要动：

```sh
hdc install hello-maui-app.hap
hdc shell aa start -a EntryAbility -b <你安装时的 bundleName>
```

> 你的重命名与 module.json 对齐是**你侧唯一的改动**（其余条目你已证明与原件 CRC 一致）。
> 请把改动后的 module.json 原样发我们（§5 第 3 项）——它是默认包与崩溃包之间唯一的差异来源。

## 2. 最小崩溃证据（若重测仍崩）

### 2.1 hilog：清缓冲 → 录制 → 启动 → 过滤

```sh
D=60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19   # 你的设备 UDID

hdc -t "$D" shell hilog -r                        # ① 清空日志缓冲，缩短窗口
hdc -t "$D" shell hilog > hilog-crash.txt         # ② 前台录制（保持这个终端不动）
# 另开一个终端：③ 启动（bundleName 用你实际安装的）
hdc -t "$D" shell aa start -a EntryAbility -b <bundleName>
# ④ 等应用退出（约 1 秒），回到录制终端按 Ctrl-C，然后过滤：
grep -inE "hellomaui|hello-maui|maui|dotnet|openharmonyhost|libentry|dlopen|AppKilledReporter|appspawn|JsError|jscrash|napi|EntryAbility|abc" hilog-crash.txt > hilog-filtered.txt
```

- **回传 `hilog-filtered.txt`（命中行）+ 崩溃时间戳前后各 200 行**；整份 `hilog-crash.txt` 更好。
- 崩溃时间点取第一条含 `AppKilledReporter` / `JsError` / `jscrash` 的行，标注出来即可，不必自行解读。
- 若 `hilog -r` 在你的 ROM 上不可用：跳过①，记录 `aa start` 的准确时间即可。
- 若上轮 preview.23 的 hilog 还留着，也发一份 —— 两份对照能直接看出复发与差异。

### 2.2 faultlog（能取就取，取不到属预期）

- `/data/log/faultlog` 在应用沙箱/普通 shell 权限之外，`hdc shell` 读不到是**正常的**，不是你的操作问题；
  不用在这上面耗时间。
- 手上有 DevEco Studio 时：设备在线后用 **FaultLog**（你的版本若有该入口）查看 JS 崩溃记录，能打开就导出；
  若你有 **DevEco 云端调试/云真机**通道，也可在云设备复现后取 faultlog。
- **回传**：只要一个 **jscrash 文件名**（FaultLog 列表里那个）+ 内容/截图（有则附，无则注明"取不到"）。

### 2.3 应用沙箱 `files/dotnet-status.txt`（可选，能取就取）

托管宿主每次启动会写状态文件，路径通常为：

```text
/data/app/el2/100/base/<bundleName>/files/dotnet-status.txt
```

- 优先进沙箱的工具：**DevEco Studio 的文件浏览器（Device File Browser，调试应用可进 `files/`）** → 导出该文件；
- 只有 `hdc shell` 时试：`hdc -t "$D" shell "ls /data/app/el2/100/base/<bundleName>/files"`；被权限拒绝就跳过并注明；
- 文件**不存在或没有新内容本身就是证据**（说明宿主可能还没执行到写状态文件）——请在回传里写明。

### 2.4 app-lib / 别名注册 / 首帧（RM1 诊断；tester-run v8 自动采集）

```sh
hdc -t "$D" shell "hilog -x | grep -E 'SetAppLibPath|appLibPathKey|NativeLibPath|lib path'"   # -> hilog/hilog-applib.txt
hdc -t "$D" shell "hilog -x | grep -E 'dlopen|cannot find library|openharmonyhost'"          # -> hilog/hilog-dlopen.txt
hdc -t "$D" shell "ls -l /data/storage/el1/bundle/libs/arm64/" > app-libs-arm64.txt
```

- `appLibPathKey: <bundle>/<module>`（含 `lib path:` 原文）出现 => 模块级 app-lib key 已注册（`libIsolation` 生效）；
  只有 `default`/app 级路径 => 非隔离安装；完全没有 `appLibPathKey`/`lib path` => 注册代码未跑到（窗口错或应用早退）。
  `GetEtsHapSoPath` 在 DEBUG 级别，必要时先 `hdc -t "$D" shell hilog -b D`。
- `[openharmony-host] native module register function bound via alias '…'` 出现 => 宿主 `.so` 已加载并注册到该别名；
  别名字符串（裸 `openharmonyhost` vs 文件别名 `libopenharmonyhost.so`）是决定性信号。
- 首帧判定（通过）：`registerXComponent=function`、首帧出现、无 `Load native module failed`。

判读与回退见 `docs/plans/2026-09-23-ohos-native-import-experiment.md` §8.4/§8.5。

### 2.5 bootstrap / rawfile / payload（v7 起采集、v8 沿用；黑屏或早退时的第一手证据）

```sh
hdc -t "$D" shell "hilog -x | grep -E 'GetRawFileContent|bootstrap failed|bootstrap retry|BusinessError|900002|900003|ZIP entry|destination path|Load native module failed|symbol not found|cannot find library'"   # -> hilog/hilog-bootstrap.txt
hdc -t "$D" shell "ls -l /data/storage/el2/base/haps/entry/files/" | grep -E 'dotnet|payload'   # -> device/payload-files.txt
hdc -t "$D" shell "cat /data/storage/el2/base/haps/entry/files/dotnet.marker"                   # -> device/payload-marker.txt
```

- `summary.txt` 对应键：`bootstrap_errors`/`rawfile_errors`/`libload_errors`（命中计数）与 `payload_present`/`payload_marker`，另有本地 hap 自检键 `kit_index_ok`/`payload=yes|no`（`meta/kit-selfcheck.txt`）。这些键**只提示、不改退出码**。
- `GetRawFileContent failed, name is empty` + `kit_index_ok=no` => hap 缺 `resources.index`（早于 kit #22 的旧包），**换当前 kit 再测**，不是设备问题。
- `ZIP entry`/`destination path` => 启动解压/路径问题（对照 kit #22 的 ZIP offset/mkdir 修复）。
- `Load native module failed`/`symbol not found`/`cannot find library` => 宿主/依赖加载问题，转 P1–P4 阶梯（§5）。
- **kit #24 起 payload 在 hap `libs/arm64-v8a/` 原地运行**：`payload_present=no` 属常态（这些键只反映回退布局的 filesDir 解包）；`payload_marker=empty` 只在回退布局有意义。真正的 payload-in-libs 信号是 `meta/kit-selfcheck.txt` 的 `payload=yes|no`（marker 缺失 = 该 hap 会回退到被 namespace 拒绝的 data 目录解包，`verify-kit.sh` 直接 FAIL）。

### 2.6 exec-memory 探针与 JIT 判定（kit #24；崩溃为 `SEGV_ACCERR` 时先看这里）

```sh
hdc -t "$D" shell "hilog -x | grep -E 'OHOS_DOTNET probe:|xwe='"     # -> hilog/hilog-execmem.txt
grep -E 'probe:|xwe=' <证据包>/hilog/hilog-execmem.txt               # 归档内同文件
grep execmem_lines <证据包>/summary.txt                              # 0 = 未捕获，加长 --capture 重跑
```

- 每个探针 token 为 `OK` 或失败 `errno`：**1** = 匿名 `mmap(RWX)`（W^X=0 的 JIT 路径）· **2** = 匿名 `mmap(RW)`→`mprotect(RX)` · **3** = `memfd` + `mprotect(RX)`（W^X=1 路径）· **4** = 临时文件 `mmap(RX)`。典型 errno：`1` EPERM · `12` ENOMEM · `13` EACCES · `38` ENOSYS。
- 判定：`1=OK` ⇒ 匿名可执行在 HAP 域可用，JIT（默认 `EnableWriteXorExecute=0`）应可用，报证 = managed app 运行 + 无 `SEGV_ACCERR`；若 `1=OK` 仍 `SEGV_ACCERR`，附 probe 行/xwe 行/崩溃栈继续定位。`1≠OK` ⇒ 本固件 HAP 域拒绝匿名可执行，JIT 不可用，转 NativeAOT。
- A/B：在 `<filesDir>/xwe.txt` 写入首字节 `1`（DevEco Device File Browser）→ hilog 出现 `xwe=1 source=file`，复现 W^X=1 的同形崩溃；删除后恢复 `xwe=0 source=default`。完整判定表与 NativeAOT 步骤见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md` §3 与 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md` §5。
- 注意 kit #24 起（含 #26）**不含 seccomp 拦截器**（不再需要，且会 strip `PROT_EXEC` 破坏 JIT）；请确认未叠加旧本地补丁后再判读。

## 3. 四个快速 A/B（各 5 分钟，能跑几个跑几个）

| # | 问题 | 怎么做 | 结论怎么读 |
|---|---|---|---|
| AB-1 | 普通 ArkTS hap 能在这台设备起吗？ | 用 DevEco 新建 Empty Ability 工程（API 波段与设备一致）→ 安装 → `aa start` | 能正常起 → 设备/ArkTS 运行时没问题，焦点回到我们的包；同样 JsError → 设备/固件侧问题优先；两者日志都留着做对照 |
| AB-2 | 宿主动态库加载了吗？ | 在 §2 的 hilog 里搜 `libopenharmonyhost` / `dlopen` / `libentry` / `[maui] openharmony build` | 有 `[maui] openharmony build ...` → 托管宿主已启动，崩溃在更后面；只有 `libentry.so`/napi 记录、没有 host 行 → 崩在 napi 加载/入口；两者都没有 → 崩在 ArkTS/Ability 阶段，宿主没起来 |
| AB-3 | 崩溃前最后一行日志是什么？ | 取第一条 `AppKilledReporter`/`JsError` 之前最后的 5–10 行（连同 §2 的 200 行） | 这行通常直接点名失败点（native module 加载失败、abc/运行时版本不符、`pages/Index` 加载失败等）；原样贴回，不用自行解读 |
| AB-4 | 匿名可执行内存与 W^X 哪条路可用？（kit #24 起，`SEGV_ACCERR` 时必做）| 读 §2.6 的 `probe:` 行；再按 A/B 写 `<filesDir>/xwe.txt`=首字节 `1` 复跑一轮 | `1=OK` = JIT 可用路径；`xwe=1 source=file` 下复现 `SEGV_ACCERR`、默认 `xwe=0` 下不崩 = 平台 W^X memfd 路径被拒，默认 0 是正确设置；`1≠OK` = HAP 域禁匿名可执行，转 NativeAOT。判定表见交接文档 |

## 4. 我们已确认在修的两点（你不必排查）

| 项 | 你上轮的取值 | 我们侧的处理 |
|---|---|---|
| bundleName | 原包 `com.example.hello-maui-app` 含连字符不合法，你重命名为无连字符 | 打包侧改为合法 bundleName（与 profile 一致），下轮安装无需改名 |
| module.json 波段/profile | 你改为 `minAPIVersion=50002014`、`apiReleaseType=Release`、`compileSdkType=HarmonyOS`、`compileSdkVersion=6.0.2.130`、`virtualMachine=ark13.0.1.0`、`debug=false` | 打包侧按设备波段生成合法 profile，避免手改引入变量 |

> 目的：让下一版开箱即装，并把你侧的变量（改名/profile 手改）从崩溃等式中移除。
> 本轮请仍保留这两处改动记录（module.json 原件）以便我们核对。

## 5. 回传清单（照抄勾选）

1. [ ] kit 外层 `.tar.gz` 的 sha256（`kit-sha256.txt`）+ `verify-kit.sh --tree-digest` 输出。
2. [ ] kit 内 `最终状态.md` / `README-交付说明.md` 的版本原文（若为 preview.23 或没有该文件，请注明）。
3. [ ] 你实际安装的 `module.json` 原文（从 hap 解出/你改后的那份）+ 重命名后的 bundleName。
4. [ ] 一个 jscrash 文件名（+ 内容/截图，若有）。
5. [ ] §2 的 hilog 过滤片段（含崩溃点前后各 200 行）与崩溃时间戳；旧包日志若有也附。
6. [ ] §3 四条 A/B 的结果（每条一行：通过/失败 + 一句话现象）。
7. [ ] **JIT 相关（kit #24 起，kit #28 沿用）**：`hilog-execmem.txt` 原文（`probe:` 行 + `xwe=` 行）与 `summary.txt` 的 `execmem_lines`；做过 A/B 的附两轮对照。判定表见 `docs/plans/2026-09-28-ohos-tester-handoff-kit28.md` §3 / `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md` §5。

> 收到后我们按 `验收说明.md` §6 模板归档；若重测后一切正常，回传 1–2 与一句"已通过"即可。
