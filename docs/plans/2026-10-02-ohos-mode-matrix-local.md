# MATRIX-LOCAL：kit #40 本机 `--mode-matrix` 实跑（tester-run v14，2026-10-02）

> 设备 HAD-W32 / OpenHarmony-7.0.0.111 / API 26（2in1），hdc 无线 `127.0.0.1:35111`，UDID `1BCE13C8…AEA0`；全程
> 未锁屏（`aa start` 均 success，无 10106102）；hilog 临时 16M（app/core）→ **已还原 512K**（20:10）。件：kit #40
> 树 `e950de54…`（tar `31ab8732…`，`--kit-dir` 复用已核解包）、tester-run **v14** 140,197 B / `a174fcd0…`、
> `aot-haps-v3-rc2.tar.gz` `3d24f716…`（asset 599996905）、`ohos-interpreter-pack.tar.gz` `a10699b3…`；签名
> preview.28 `sign-hap.sh` + ohos-sdk 26.0.0.18_2。证据 scratch `/data/storage/el2/base/tmp/opencode/matrix40-local/`。

## 1. 本机替代（2 处；不改 tester-run 资产，只在 evidence 标注）
- **A/B 主件 = 本机 DeviceCompat 重写件**（133,985,274 / `bcf72baf…`，rc.2 线）：kit stock `hello-maui-app.hap`
  本机 `hdc install -r` → **9568393**（`logs/stock-kit-install.log`；≥7.0.0.111 拒 payload-in-libs，承 JIT-PAYLOAD-POLICY）。
- **C = DeviceCompat 基件 + 官方 interp pack 覆盖 + 清单 `runtime-mode.txt=interp` + 重签**（71,569,474 / `9fd39810…`，
  pack 成员 ok、coreclr 宽字符串齐）：本机 `hdc shell`（uid 2000）写 `<files>/interp.txt`/`xwe.txt` **Permission denied**，
  故用官方清单路线补 file 路线的本地缺位（A/B 的 `xwe.txt` 同理无效）。

## 2. 命令与四 Run（`--capture 30`）
`sh tester-run.sh --kit-dir <kit#40> --expect-tree-digest e950de54… --device 127.0.0.1:35111 --hap <DeviceCompat> --mode-matrix --aot-haps … --interp-pack … --interp-hap <interp> --capture 30 --out out`

| Run | install | start | alive | aot_route | interp_mode | runtime_mode | probe_1 | xwe | frame | crash |
|---|---|---|---|---|---|---|---|---|---|---|
| A | ok | ok | no | `<unavailable>` | `<unavailable>` | jit(hap) | `<unavailable>` | `<unavailable>` | yes | SIGSEGV |
| B | ok | ok | no | `<unavailable>` | `<unavailable>` | jit(hap) | `<unavailable>` | `<unavailable>` | yes | SIGSEGV |
| C | ok | ok | no | `<unavailable>` | `<unavailable>` | jit(hap)* | `<unavailable>` | `<unavailable>` | yes | SIGSEGV |
| D | ok | ok | yes | 1(manifest) | `<unavailable>` | aot(hap) | `<unavailable>` | `<unavailable>` | yes | none |

（*C 变体安装子轮 `run-c-install/summary.txt runtime_mode=interp(hap)`；`run_c_runtime_mode=jit(hap)` 是 c 子轮读默认 kit 主 hap 标记。）

## 3. summary 结论行与失败摘要
- `matrix_failures=3`；`conclusion=JIT 未直起（run-a probe=<unavailable> crash=SIGSEGV）→ 转 AOT/解释器路线；解释器 interp_mode=<unavailable>（run-c）；AOT aot_route=1(manifest)（run-d）。建议：回传 run-a..d 的 tester-report tar + mode-matrix/summary.txt`
- A/B：`payload-in-libs` + `managed app … started` 后 ~0.17 s CppCrash；AMS exit `Signal:SIGSEGV(SEGV_MAPERR)@0x5a79…`（run-a/b）。
- C：同前段，exit `Signal:SIGSEGV(SEGV_ACCERR)@0x0000005cccff0000`（与 2026-10-01 真 JIT 崩点同址）；本机无 `interp=` 行，**解释器是否真激活不可判**（若激活，仍撞 exec-memory 墙——判定卡已记 Precode stub 风险）。
- D：起后存活 ~55 s 至 restore/uninstall 清理（exit_msg 空），AOT 直启成立（`aot=1` 行本机不可见，标记回退 `1(manifest)`）。
- `switch_xwe/interp_write=ok` 为 hdc 不回传远端 rc 的表象；device 日志 `Permission denied`（`out/mode-matrix/switch-*.log`）。

## 4. 与 tester 机差异 / 不可行项（如实）
- **本机镜像限制**：kit #40 stock JIT 主 hap 装不上（9568393，逐文件码签/fs-verity 强制）；tester 7.0.0.105 可直装 stock JIT。
- **JIT 崩**：本机 JIT（含 xwe 轮，实际未写成功）`SEGV_MAPERR` 崩，与 tester「JIT 不可用 → 转 AOT」结论一致；崩点子型（MAPERR vs ACCERR）与 10-01 记录略异，留档。
- **路由行缺失**：本机无 `libhilog_ndk.z.so`，`aot=/interp=/xwe=/probe:` 全 0 行（execmem_lines=0）；`aot_route=1(manifest)` 为标记回退值，非设备行。tester 机可见真行。
- **切换文件不可写**：本机 hdc shell 无权限写 filesDir → xwe A/B 与 file 路线解释器本地无效；tester 上按原流程（Run B/C 写文件）执行。
- C 的解释器真实激活/行为本机不可判（无路由行 + 无 maps 窗口）→ 登记「本机不可判（在途）」，不判 kit #40 失败。

## 5. 证据与未决
- scratch `matrix40-local/`：`EVIDENCE.md`、`out/mode-matrix/summary.txt`（a0c70fe2…）、run-a/b/c/c-install/d/restore tar（b14edcd2/07e51cc8/aa475f40/d7ad5639/28e73603/145dc597）、`out/mode-matrix/*.log`、`logs/`（matrix、precheck、hilog 16M→512K 还原、end-state）。
- 设备末态：`com.example.hellomauiapp`（DeviceCompat 件）已装未运行；hilog 512K；无 10106102。
- 未决：①interp 变体本机是否入解释器（需 tester 机 `interp=3 source=file` + maps 复核）；②MAPERR/ACCERR 子型差；③kit stock 主 hap 在本机镜像的直装证据仅供对照。
