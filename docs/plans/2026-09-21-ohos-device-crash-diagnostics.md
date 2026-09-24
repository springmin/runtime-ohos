# 设备侧启动崩溃：诊断与重测包（JsError / exit 254）

> 对象：本轮真机首发报告的测试方 —— 设备 **OpenHarmony 7.0.0.105 / API 26 / 2in1**，
> UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`。
> 现象：hap 安装成功，`aa start` 后约 1 秒应用退出（exit 254），`AppKilledReporter` 报 `reason=JsError`。
> 本页只做三件事：**换当前 kit 重测** → **取最小崩溃证据** → **回传 §5 清单**。命令可照抄；结论以设备实测为准。
> 相关文档（kit 内）：`真机操作手册.md`（校验/安装/取证）、`验收说明.md`（完整清单与模板）、`签名与UDID指南.md`（9568344）。
>
> **2026-09-24 更新（kit #22）**：本文所写的三类旧崩溃 —— 入口 record（kit #10）、abc 版本（kit #11）、宿主加载（kit #12）—— 均已在当前 kit 修复；此后追加 P17 跳过重复解压、H7 rawfile 文件描述符直读、headless 变体 abc `13.0.1.0`，并在 kit #22 回灌设备里程碑修复：宿主 `DT_NEEDED` 5 库 + 可选 API 按需 dlsym、HAP `resources.index`（restool）、启动解压 ZIP offset/length + mkdir、DevEco 工程布局。**2026-09-24 设备证据修正**：黑屏/失败的直接链是宿主加载 + bootstrap 三项（`resources.index` / ZIP offset / mkdir）+ abc 编译，共 5 项，而非旧 #4（`libIsolation`/napi 记录名；已降级为无害加固）—— 见 `docs/plans/2026-09-24-ohos-device-milestone.md` 与 `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md` §5f。`tester-run.sh` v6r2 会自动采集 `hilog/hilog-applib.txt`、`hilog/hilog-dlopen.txt`、`device/app-libs-arm64.txt`（§2.4）；整包/内容树数字以 release「## Integrity」为准。`签名说明.txt` 的 PA1 历史句已随源修复（`c6a4cd95e`），若副本仍出现按历史文案处理。

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

沿用你上轮的成功路径（你自己的华为 debug 证书）；当前 kit（#22）的 5 个 hap 已是合法 bundleName 与设备波段，**无需改名、无需手改 module.json**，其它文件也不要动：

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

### 2.4 app-lib / 别名注册 / 首帧（RM1 诊断；tester-run v6r2 自动采集）

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

## 3. 三个快速 A/B（各 5 分钟，能跑几个跑几个）

| # | 问题 | 怎么做 | 结论怎么读 |
|---|---|---|---|
| AB-1 | 普通 ArkTS hap 能在这台设备起吗？ | 用 DevEco 新建 Empty Ability 工程（API 波段与设备一致）→ 安装 → `aa start` | 能正常起 → 设备/ArkTS 运行时没问题，焦点回到我们的包；同样 JsError → 设备/固件侧问题优先；两者日志都留着做对照 |
| AB-2 | 宿主动态库加载了吗？ | 在 §2 的 hilog 里搜 `libopenharmonyhost` / `dlopen` / `libentry` / `[maui] openharmony build` | 有 `[maui] openharmony build ...` → 托管宿主已启动，崩溃在更后面；只有 `libentry.so`/napi 记录、没有 host 行 → 崩在 napi 加载/入口；两者都没有 → 崩在 ArkTS/Ability 阶段，宿主没起来 |
| AB-3 | 崩溃前最后一行日志是什么？ | 取第一条 `AppKilledReporter`/`JsError` 之前最后的 5–10 行（连同 §2 的 200 行） | 这行通常直接点名失败点（native module 加载失败、abc/运行时版本不符、`pages/Index` 加载失败等）；原样贴回，不用自行解读 |

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
6. [ ] §3 三条 A/B 的结果（每条一行：通过/失败 + 一句话现象）。

> 收到后我们按 `验收说明.md` §6 模板归档；若重测后一切正常，回传 1–2 与一句"已通过"即可。
