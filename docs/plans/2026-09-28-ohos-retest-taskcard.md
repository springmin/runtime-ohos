# 复测任务单（一页）：kit #29 一轮设备判定（2026-09-28）

> 目标：一轮拿全 JIT / XWE / AOT / 解释器 / harmony 五态证据，一并采无障碍。
> 执行入口 = `tester-run.sh` **v12**（126,658 B / `87763a3e…`；`summary runtime_mode` 读 hap 的
> `libs/<abi>/runtime-mode.txt`，优先级 file（interp.txt）> manifest（清单）> default）；判定树与细节见
> `2026-09-27-ohos-runtime-mode-determination.md`，逐项勾选见 `2026-09-28-ohos-tester-handoff-kit29.md` §2。
> 本页只给「取件 → 执行 → 回传 → 判定」。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #29） | 196,990,205 | `e895cc0a…` | 5 个 JIT hap＋`verify-kit.sh`＋文档 |
| `aot-haps.tar.gz` | 17,093,146 | `91e1b9d3…` | AOT hap（已内置桥宿主，开箱 `aot=1`） |
| `harmony-haps.tar.gz` | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；MAPFIX 重切：overlay 真编译，abc 291,628 B/`a637a513…`；旧 196,118,871/`f7a4faa2…` 无 overlay 记录已替换） |
| `ohos-interpreter-pack.tar.gz` | 2,419,988 | `a10699b3…` | 解释器 payload（`interp.txt=3`） |
| `tester-run.sh` v12 | 126,658 | `87763a3e…` | 执行器（`--mode-matrix` / `--a11y-probe`；`summary runtime_mode=jit|aot|interp(hap)|invalid(...)|<absent>`） |

## 2. 执行顺序（每步「期望 → 回传」）

1. **校验 kit**：解压后在包内 `sh verify-kit.sh` → 期望 0 FAIL / 0 WARN（abc 锚 **281,052/20,916**）→ 回传终端输出。
2. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./aot-haps.tar.gz --interp-pack ./ohos-interpreter-pack.tar.gz --capture 60`
   → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全（`run_*_install/start/probe_1/xwe/aot_route/interp_mode/runtime_mode/frame/crash`＋`conclusion`）
   → 回传 `mode-matrix/` 全目录＋四个 `tester-report-*.tar.gz`。
3. **harmony 变体（AGC 就绪时）**：解压 `harmony-haps.tar.gz`，按《自签说明》重签 →
   `sh tester-run.sh --kit-dir ./device-test-kit --hap ./hello-maui-app.hap --install --start --capture 60`
   → 期望 `IsOverlayAvailable=true`（flags bit1；MAPFIX 后 abc 已含 `entry/ets/map/MapOverlay` 模块记录，
   无 AGC 权益时才按降级路径登记）、Map `Ready/MarkerClick/CameraIdle`、LiveView create/update/stop
   → 回传截图/录屏＋状态原文＋AGC 开通截图。
4. **无障碍采集（可并入任一轮）**：加 `--a11y-probe` → 期望 `a11y/selfcheck.txt`（`accessibilityStatus: 1`＋正整数节点数）与 `a11y/hilog-a11y.txt`（缺失容忍、不算失败）→ 回传 `a11y/` 两文件＋`summary a11y_*`。

## 3. 判定表（逐 Run 填）

| 态 | 判据 | 结论 |
|---|---|---|
| JIT | `run_a_probe_1=OK`＋managed 输出/首帧＋`xwe=0 source=default` | JIT 直起可用 |
| XWE | A 不通（probe≠OK/SEGV）时看 B：`xwe=1 source=file` 且能起 | 需 `xwe.txt=1` |
| AOT | `run_d_aot_route=1`＋`NativeAOT payload … aot=1`＋无 `The application to execute does not exist` | AOT 直启成立 |
| 解释器 | `run_c_interp_mode=3(file)`＋maps 含 `libclrinterpreter.so`＋managed 输出 | 解释器激活 |
| harmony | `IsOverlayAvailable=true`＋Map/LiveView 实际点亮 | Map/LiveView 可用 |

> 失败 Run 保留对应报告 tar，`summary conclusion` 给建议行；无入口项登记「未测（本包无入口）」，不判失败。

## 4. 注意

- 包内 hap 为自签：安装失败码 **9568257**（及 `9568344`）**属预期**，先重签；重签需**华为调试证书**（Profile 绑定 UDID）。
- AOT hap 只有 3 个 `.so`，勿用 kit 的 JIT 期望值核对；AOT/harmony 安装会顶替 kit 主包，回 JIT 需重装 kit hap。
- 所有数字以 release「## Integrity」与 `.tar.gz.sha256` sidecar 为准（重签/重打包后哈希必变）。
- 细判（TTS/HUKS/文本编辑/动画/列表/图片/深链）：`2026-09-28-ohos-tester-handoff-kit29.md` §2；无障碍逐项判据：`2026-09-27-ohos-accessibility-device-verification.md`。
