# 真机运行操作手册（交付包 + hdc）

> 面向拿到 device-test-kit（或已解压目录）、手上有设备/`hdc` 的测试者：照抄命令与顺序即可；结论以设备实测为准。
> 逐项清单、日志关键字与**回传模板**见 `docs/plans/2026-09-19-ohos-hap-acceptance-for-testers.md`（包内名 `验收说明.md`，重点是 §4b/§5b/§6）；
> 一页版入口 `docs/plans/2026-09-20-ohos-tester-quickstart.md`（包内名 `快速开始.md`）；kit 内容见 `docs/plans/2026-09-21-ohos-delivery-kit-readme.md`。
> 当前发布 = **kit #28**（2026-09-28，R2：**Map 覆盖层**（`ARKTS_SDK_FLAVOR=harmony` 壳 + AGC 地图 AppKey；默认 flavor 下 `IsOverlayAvailable=false`，show/hide/区域/标记等调用**降级不抛**）+ **LiveView 特性探测**（无 Kit/权益时 `IsSupported=false`、Start/Update/Stop `Unavailable` 不抛）+ **壳 `start_app` AOT 启动桥**（`lib<stem>.so` → `openharmony_app_main`，日志 `aot=1`，失败 `aot=0` 回退 JIT）+ **解释器实验资产**（`<files>/interp.txt` → `DOTNET_InterpMode`）；宿主导出契约 **134/134**；ui/shell abc → **264,136 B**（headless 18,532 B）；交互门禁 **334/floor 314**）；KIT-EXT2（#27）、P2-INTEROP/TASK-MIG/PLAT-GAP（#26）、权限链/Share-Scan 探测降级/AOT 启动路径（#25）与 #24 的 payload-in-libs（`libs/arm64-v8a/` 原地携带 254 payload + `.dotnet-payload.json`）/显式 W^X=0/exec-memory 探针均不变；含 kit #22 的设备回灌与自 #17 起全部安全/性能/启动修复。数字入口 = release「## Integrity」；里程碑与复测判定点见 `docs/plans/2026-09-24-ohos-device-milestone.md`；本轮判定点见 `docs/plans/2026-09-28-ohos-tester-handoff-kit28.md`（§2），KIT-EXT2 判定点见 `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md`，P2-INTEROP/PLAT-GAP 判定点见 `docs/plans/2026-09-26-ohos-tester-handoff-kit26.md`（§2），权限/Share/Scan/AOT 判定点仍见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`，JIT/NativeAOT 说明见 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`；并列资产 `aot-haps.tar.gz` 与 `ohos-interpreter-pack.tar.gz`。

## 0. 前置

- 设备 **arm64（aarch64）**；API ≥26 用默认包，只有 API 20 波段设备用 `hello-maui-app-api20*.hap`。
- 开启开发者模式，并允许安装调试/外部来源应用（设置 → 安全，各 ROM 名称略有差异）。
- **无需安装 .NET 运行时**（随 hap 打包在 `resources/rawfile/dotnet.zip`）。

## 1. 校验交付包

```sh
cd device-test-kit          # 解压后的目录（含 SHA256SUMS 与 verify-kit.sh）
sh verify-kit.sh            # 或：sh verify-kit.sh <kit-dir>
```

期望最后一行 `KIT OK`。出现 `FAIL/WARN`（校验和不符、缺 hap/文档）时**先重新下载解压**，不要带病安装。

> **kit #23 起 `verify-kit.sh` 更严（旧包会 FAIL 属预期）**：除逐文件校验外还逐 hap 断言 `resources.index`（缺/空 = FAIL；kit #25 起另有 ≤ 2 KiB 上限 1588/1780，**#26 期望值不变、#27 把 abc 重锚为 `245412`、#28 再重锚为 `264136`**）、abc 版本 `13.0.1.0` 与当前壳大小（**kit #28 = `264136`/`18532`**，`#27` 的 `245412`、`#25/#26` 的 `234620` 旧值会 FAIL —— 属脚本预期）、`libs/arm64-v8a` 14 个 `.so`、`dotnet.zip` 不含 `.so` 且 254 项、宿主 ELF 依赖白名单（FAIL → 退出码 1；WARN → 仍 `KIT OK`）。**kit #24 起再加 payload-in-libs 断言**：`libs/arm64-v8a/.dotnet-payload.json` 必须存在且自洽（入口程序集、条目计数、`zipSha256`；缺失 = FAIL）。kit #22 全部通过；**kit #21 及更早的包会被明确报 FAIL（真实缺陷，不是误报）**——检修旧包用其自带 verify-kit，强化结果用 kit #22+（当前 #28）。可选参数 `--expected-abc` / `--host-deps`。

## 2. 安装（二选一）

**方式 A（无 hdc）**：把 hap 拷到设备（U 盘/文件管理器/局域网），在**文件管理器中打开** → 按提示安装。
**方式 B（有 hdc）**：

```sh
hdc list targets                                    # 应列出设备
hdc install hello-maui-app.hap                      # API 20 设备换成 hello-maui-app-api20.hap
```

## 3. 启动

```sh
hdc shell aa start -a EntryAbility -b com.example.hellomauiapp
```

或直接点桌面图标。首帧应为**黑色导航栏 + 标题「Root」**的长列表；若黑屏/闪退，先记录并走第 7 节回传。2026-09-24 里程碑：kit #18 + 测试方 5 项本地修复已跑到 `managed app hello-maui-app.dll started (UI shell)`、进程存活、无崩溃；**stock kit（#22 起，含 #28）的首次设备复测就是本轮**（失败分支判定见 `docs/plans/2026-09-24-ohos-device-milestone.md` §6）。若崩在 CoreCLR 初始化/JIT（`SEGV_ACCERR`）：kit #24 起（含 #28）不含 seccomp 拦截器，先确认没有叠加旧本地补丁，再按 `docs/plans/2026-09-28-ohos-tester-handoff-kit28.md` §3 / `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md` §4 / `docs/plans/2026-09-26-ohos-tester-handoff-kit26.md` §4 / `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md` §3 / `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md` §5 读 `probe:` 行并做 `xwe.txt` A/B。kit #25 另有 AOT 启动路径（app export + hostfxr 回退），kit #28 把 AOT 探针并入壳 `start_app`（`aot=1` 直启）：本包的 JIT hap 应仍走 `aot=0` 回退启动（即最直接的回归检查）。

## 4. 采集证据（有 hdc 时）

先开录（`hdc hilog > log.txt`），再启动/操作应用，全部测完 `Ctrl-C`；然后过滤出要回传的行：

```sh
hdc hilog > log.txt
grep -F '[maui]' log.txt                                  # 两条启动行
grep -E 'HybridWebView|__hwvInvokeDotNet|webview|bluetooth|print|contacts|calendar' log.txt
```

两条启动行（第 7 节必附）：

| 行 | 说明 |
|---|---|
| `[maui] openharmony build <ver> abi=<arch> provider=<n>` | 构建版本 + ABI；启动早期出现，`provider=0` 属预期 |
| `[maui] accessibility provider status=<n>` | provider 附着状态；**1 = 已附着（理想）**，0 = 启动初值（预期）|

`status=<n>`（0–4，界面显示 `unknown status` 的更大值请原样回传）：0 = 未附着（启动初值）· 1 = 已附着、回调注册成功（理想）·
2 = 收到 frame node 但因不是 CUSTOM 节点被拒 · 3 = 收到 NodeContent 但 CUSTOM 节点未创建/加入 · 4 = CUSTOM 节点已加入但 provider 拒绝。

无 hdc 时：截图应用日志区；**A11Y** 自检弹窗（见 §5）可代替 status 行的一部分证据。

## 5. 五分钟冒烟路径（先跑这 5 条）

| # | 操作 | 通过标准 |
|---|---|---|
| 1 | 启动看首帧 | 无花屏/黑块；文字清晰、控件不重叠、安全区不遮挡（A1/J1）|
| 2 | 打开「显示弹窗」`DisplayAlert` | 遮罩 + 对话框出现；「取消/确定」分别返回 false/true；点遮罩不误触下层（B1/B5）|
| 3 | 在 `Entry` 里中英混输 | 键盘弹出、光标可见、上屏无重字/漏字、收起后布局恢复（E1–E5）|
| 4 | 打开 Hybrid 演示页，点按钮触发 JS→.NET | 返回并回显（`Echo`/`Add`，对应 N6）；`BlazorWebView` 本轮包内未含，属已知限制（§5），无需测试 |
| 5 | 点左下角 **`A11Y`** 小按钮 | 自检弹窗给出 `accessibilityStatus` + 节点数，与 §4 status 行对照 |

失败就记下步骤、现象与时间点；完整清单（A1–K2、N1–N7）按 `验收说明.md` 继续。

## 6. 失败分支

| 现象 | 处理 |
|---|---|
| `9568344 install parse profile prop check error` | 属**调试 profile 设备绑定**（未含你的 UDID），非应用缺陷。三选一：① 按 `docs/plans/2026-09-21-ohos-tester-selfsign.md` 用你自己的 DevEco 自动签名；② 回传 UDID（`hdc shell bm get -u`，或 DevEco → Device Manager）由签名方重签（哈希会变）；③ 把 p7b + p12 + cer + keyAlias 走安全通道发回，由我方预签：`sh scripts/sign-for-device.sh --external --profile <你的.p7b> --key <你的.p12> --cert <你的.cer> --key-alias <alias> --pwd-input-mode --expect-udid 60CF7B27…`（UDID 换成你的）|
| `E00C001 Operation restricted by the organization` | 设备策略关闭了 hdc（`const.usb.port.user_hdc.disable=true`）：改用**方式 A**（文件管理器安装）；或由设备管理员放开策略 |

签名与 UDID 完整流程见 `docs/plans/2026-09-19-ohos-signing-and-udid-guide.md`（包内名 `签名与UDID指南.md`）。预签的 p7b 必须把目标 UDID 列入 `debug-info.device-ids`（fail closed：不匹配直接拒绝）；kit #22 起 `签名说明.txt` 的 PA1 历史句已随源修复（`ohos-workload c6a4cd95e`），若副本仍出现该句按历史文案处理。

## 7. 回传什么

1. 填好的 `验收说明.md` **§6 模板**：A1–K2、N1–N7 逐项「通过/失败/未测 + 现象」，以及安装方式（手动/hdc）。
2. `log.txt` 片段：两条启动行 + 失败项关键字行（**标注各失败项时间点**）。
3. 安装失败的**完整错误文案**或截图；严重问题（崩溃/黑屏/无法启动）附步骤与是否可复现。
4. 无 hdc 时：应用日志区与 A11Y 自检弹窗截图（可选录屏）。
5. 整轮报告推荐用 `tester-run.sh`（v8）生成 `tester-report-<时间戳>.tar.gz`（连同 `.sha256`）：自动收录 hilog（含 `hilog-applib.txt`/`hilog-dlopen.txt`/**`hilog-bootstrap.txt`**/**`hilog-execmem.txt`**）、kmsg、`device/app-libs-arm64.txt`、`device/payload-files.txt`/`device/payload-marker.txt`、`meta/kit-hap-sha256.txt` 与 `meta/kit-selfcheck.txt`，字段与旧版兼容；若 `summary.txt` 报 `kit_index_ok=no` 请换 kit #22+ 再测，`bootstrap_errors`/`rawfile_errors>0` 时附 `hilog-bootstrap.txt`（不影响退出码）。**JIT 判定（kit #24 起，kit #28 沿用）**：附 `hilog-execmem.txt`（`probe:` 行 + `xwe=` 行）与 `summary.txt` 的 `execmem_lines`；判定表与 A/B 见 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md` §5（kit #25 索引见交接 §3，kit #26 索引见交接 §4，kit #27 索引见交接 §4，kit #28 索引见交接 §3）。注意 kit #24 起 `payload_present=no` 属正常（payload 在 hap `libs/` 原地运行）。kit #25 的权限变体另附弹窗截图 + `module.json` 的 `requestPermissions` 原文（理由文案判定点）；kit #27 另附新 payload 首次运行的启动两行日志与无 HMS 降级证据；kit #28 另附启动日志中的 `aot=0|1` 行、Map 覆盖层/LiveView 降级证据（§2 判定点；本包无对应 UI 入口时按「未测（本包无入口）」登记），解释器轮次另附 `interp=3 source=file` 行与 `/proc/self/maps` 摘录。
