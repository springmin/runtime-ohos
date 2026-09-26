# 真机测试交付包

构建基线：`.NET/OpenHarmony workload 1.0.0-preview.24`（arm64）。4 个已签 hap 用 SDK 自签材料签名（profile 绑定示例 UDID），1 个未签 hap 供自助签名。当前发布 = **kit #27**（2026-09-26，KIT-EXT2：壳对 Push/Account/Map 三个 HMS Kit 做特性探测（无 Kit/AGC/HMS 时 sink 不注册、值 null，**不抛**），宿主新增 12 个 kit sink（导出契约 118/118 → **130/130**）+ FIX-R1-NAPI-6D 边界加固，反向条目改走 off-runtime marshaller（`[UnmanagedCallersOnly]` + `delegate* unmanaged[Cdecl]` thunk）；ui/shell abc → **245,412 B**、hap 内宿主 → **265,120 B**、hosting DLL → **55,296 B**；交互门禁 329/floor 309；`OpenHarmonyHapPayloadZip` opt-out 三套 pack 同步）；P2-INTEROP/TASK-MIG/PLAT-GAP（#26）、权限链/Share-Scan 探测降级/AOT 启动路径（#25）与 #24 的 payload-in-libs（hap `libs/arm64-v8a/` 原地携带 254 payload + `.dotnet-payload.json`，`dotnet.zip` 回退，签名 hap ~75.56 MB）/显式 W^X=0/exec-memory 探针均不变；含 `libIsolation` 与自 kit #17 起全部安全/性能/启动修复）；数字入口见 release「## Integrity」；里程碑见 `docs/plans/2026-09-24-ohos-device-milestone.md`；本轮判定点见 `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md`，P2-INTEROP/PLAT-GAP 判定点见 `docs/plans/2026-09-26-ohos-tester-handoff-kit26.md`，权限/Share/Scan/AOT 判定点见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`，JIT 判定与 NativeAOT 指引见 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`。

## 内容
| 文件 | 说明 |
|---|---|
| `hello-maui-app.hap` | 默认包（API 26 波段，无额外权限）：界面/交互/手势/IME/通知/安全区/WebView/无障碍/Hybrid |
| `hello-maui-app-permissions.hap` | 带权限变体（蓝牙/打印/联系人/日历 5 项权限，kit #25 起逐项带 `reason`/`usedScene`，弹窗显示理由文案）；用于验收说明 §4b 的 N1–N4 与 §8c–§8e 判定点 |
| `hello-maui-app-api20.hap` | API 20 波段（`minAPIVersion=targetAPIVersion=60000020`，Release）；给 API 20 设备 |
| `hello-maui-app-api20-permissions.hap` | 同上，带权限 |
| `hello-maui-app-unsigned.hap` | **未签名**（与默认包同一负载、同一 bundle name）；按 `自签说明.md` 用你自己的自动签名安装 |
| `验收说明.md` | 逐项测试清单（A1–K2、N1–N7）、日志关键字与 status 对照、回传模板 |
| `快速开始.md` | 一页版：下载校验 → 选 hap → 安装 → 先测 5 条 → 回传格式 |
| `文档索引.md` | 文档库索引（含主审计报告 §1–§35 的要点与状态）|
| `签名与UDID指南.md` | **安装报 9568344 时按此处理**：提供目标设备 UDID 用 `scripts/sign-for-device.sh "<UDID>"` 重签；含华为自动签名材料代签（`scripts/sign-huawei.sh`）|
| `自签说明.md` | 用你自己的 DevEco Studio 自动签名给未签名 hap 自签（无需我们介入）|
| `SHA256SUMS` | 上述**全部 hap 与文档**的校验和（`sha256sum -c SHA256SUMS` 逐文件校验）|
| `verify-kit.sh` | 一键自检：校验 SHA256SUMS + 汇总 5 个 hap，并**逐 hap 深度断言**（`resources.index` 存在/非空且 ≤ 2 KiB（1588/1780；#26 期望值不变、**#27 abc 重锚 `245412`**）、abc 版本 `13.0.1.0` 与当前壳大小（**kit #27 = `245412`/`18532`**；旧值（含 #25/#26 的 `234620`）会 FAIL，属脚本预期）、`libs/arm64-v8a` 14 个 `.so`、`dotnet.zip` 不含 `.so` 且 254 项、宿主 ELF `DT_NEEDED`/未定义符号白名单，**kit #24 起再加 `libs/arm64-v8a/.dotnet-payload.json` payload-in-libs 断言**（缺失/计数/zip sha 不一致 = FAIL）；FAIL → 退出码 1，WARN → 仍 `KIT OK`）；`--anchor` 校验外层 `.tar.gz` 文件，`--expect-tree-digest` 绑定解压内容树（`--tree-digest` 打印）；可选 `--expected-abc` / `--host-deps` |

> 注：kit #22 起 `签名说明.txt` 的「PA1 重建壳的下一版 kit」历史句已随源修复（`ohos-workload c6a4cd95e`）；若副本仍出现该句，按历史文案处理，判读以其余内容与 release notes 为准。

## 校验（先做）
```sh
sha256sum -c device-test-kit.tar.gz.sha256       # ① 外层传输校验（随 release 的 .sha256 资产）
mkdir -p device-test-kit && tar xzf device-test-kit.tar.gz -C device-test-kit
cd device-test-kit
sh verify-kit.sh --anchor-file ../device-test-kit.tar.gz   # ② 包内校验 + tar.gz 文件锚定（读取 .sha256）
# 也可显式传哈希：sh verify-kit.sh --anchor "$(awk '{print $1}' ../device-test-kit.tar.gz.sha256)"
sh verify-kit.sh --expect-tree-digest <发布说明中的 tree sha256>   # ③ 绑定解压内容树（见下）
# 发布说明没给 tree sha256 时：先 sh verify-kit.sh --tree-digest 打印，再人工比对
```
`SHA256SUMS` 与文件在同一个包里，只能证明包内自洽；`--anchor`（或 `KIT_ANCHOR`）只校验下载的
`.tar.gz` 文件本身，**不**验证解压后的目录（解压在本脚本之外发生）。要绑定解压内容，用交付方在发布
说明中给出的 `tree sha256` 配合 `--expect-tree-digest`（或 `KIT_TREE_DIGEST`）：它对排序后的相对
路径 + 每个文件的 sha256 计算摘要，文件被增删改（即使包内 `SHA256SUMS` 被同步改写）都会不匹配并失败。
不带 `--anchor`/`--expect-tree-digest` 时脚本会提示只做了包内校验。

> **verify-kit 更严（kit #23 起，#24 再加 payload-in-libs，#25 更新期望值，#26 沿用，#27 把 abc 重锚 `245412`）**：`FAIL` 会以退出码 1 失败；`WARN` 只打印、结果仍是 `KIT OK`。对 kit #22 上述（#23 版）断言全部通过；**对 kit #21 及更早的包会明确报 FAIL（缺 `resources.index`、旧宿主依赖等真实缺陷，非误报）** —— 检修旧包用其自带 verify-kit，强化结果用 kit #22+（当前 #27）。

`tester-run.sh`（当前 **v8**，内嵌 `script_version="8 (2026-09-24)"`；kit #27 沿用、未重传）可把以上步骤串成一条命令，并把 `meta/kit-hap-sha256.txt`/`main_hap_sha256` 写进证据包；v7 新增 `hilog/hilog-bootstrap.txt`、`device/payload-files.txt`/`payload-marker.txt`、`meta/kit-selfcheck.txt` 与 `summary.txt` 的 `bootstrap_errors`/`rawfile_errors`/`libload_errors`/`payload_present`/`payload_marker`/`kit_index_ok` 等键；**v8（kit #24 起，kit #27 沿用）再增 `hilog/hilog-execmem.txt` 与 `execmem_capture`/`execmem_lines`，kit 自检另加 `payload=yes|no`**（判定：`kit_index_ok=no` → 换 kit #22+ 再测；`bootstrap/rawfile` 计数 >0 时附 `hilog-bootstrap.txt`，不影响退出码；`payload_present=no` 在 kit #24 起属正常 —— payload 在 hap `libs/` 原地运行；JIT 判定见 `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md` §4 / `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md` §5）。`--tree-digest` 因 P16 复用已校验摘要明显更快（结果不变）。

## 安装
1. 把 hap 拷到设备，在文件管理器中打开 → 按提示安装（需允许调试/外部来源安装）。
2. 若报 `9568344 install parse profile prop check error`：这是**调试 profile 的设备绑定**（不含你的设备 UDID），
   请把 **UDID**（`hdc shell bm get -u`，或 DevEco → Device Manager）发回，我们会重签并发新包；
   也可按 `自签说明.md` 用你自己的华为账号自动签名（或按 `签名与UDID指南.md` 处理）。
   第三条路径：把 **p7b + p12 + cer + keyAlias** 走安全通道发回，由我方预签 ——
   `sh scripts/sign-for-device.sh --external --profile <你的.p7b> --key <你的.p12> --cert <你的.cer> --key-alias <alias> --pwd-input-mode --expect-udid 60CF7B27…`（UDID 换成你的）。
3. 启动后按 `验收说明.md` 逐项执行，并把结果（含 `[maui] accessibility provider status=N` 一行）回传。

## 环境
- 目标：HarmonyOS / OpenHarmony 设备，arm64，API 26 最佳（API 20 设备用 `api20` 变体）；
- 需要允许安装调试/自签名应用的设置；建议同时开启“允许调试安装”。
