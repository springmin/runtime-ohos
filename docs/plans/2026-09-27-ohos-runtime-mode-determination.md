# 运行时模式判定卡：JIT / AOT / 解释器 / 渲染（2026-09-27）

> 目标：**一轮设备定运行时模式**。三条硬证据：`hilog/hilog-execmem.txt`（路由行）、managed 输出/首帧、`/proc/<pid>/maps`。
> 判定用 `tester-run.sh` **v9**（2026-09-27 重传）：证据包 `tester-report-*.tar.gz` 含 `hilog/hilog-execmem.txt` 与
> `summary.txt` 新键 `aot_route=0|1|0+1|<unavailable>`、`interp_mode=<v>(file|default)|<unavailable>`（缺失容忍）。

## 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`；asset id/尺寸/digest 2026-09-27 API 复核）

| 资产 | asset id | 大小 (B) | sha256（前缀） | 取件注意 |
|---|---|---|---|---|
| `device-test-kit.tar.gz`（kit #28） | 590266238 | 196,220,486 | `091dcc56…`（sidecar `d7efd251…`） | 5 个 JIT hap＋文档＋verify-kit |
| `aot-haps.tar.gz` | 590020146 | 17,090,044 | `67519d11…` | `hello-maui-app-aot{,-unsigned}.hap`＋README（宿主滞后，见 §2.2） |
| `ohos-interpreter-pack.tar.gz` | 590052493 | 2,419,988 | `a10699b3…` | `native/libcoreclr.so`＋`libclrinterpreter.so`＋README/sidecar |
| `tester-run.sh` v9 | 592440134 | 75,917 | `3c2d33bf…` | v8 = 73,375 B / `6ca2093e…`；v9 采集 `aot=`/`interp=` |

## 0. 四态矩阵

| 态 | 取件/前置 | 关键日志（execmem 文件） | 判定 | 回传 |
|---|---|---|---|---|
| JIT | kit #28 stock hap | `xwe=0 source=default`、`probe: 1=OK`、`aot=0 dir=…` | `1=OK` 且 managed 运行 → JIT 可用；`1≠OK` 或 SEGV/`mprotect` 拒 → 走 `xwe.txt=1` A/B | tar |
| AOT | aot-haps＋换 kit #28 宿主＋重签 | `NativeAOT payload … aot=1` | managed 输出，且**无** `The application to execute does not exist` | tar |
| 解释器 | interp pack 替换 payload＋`interp.txt`=3＋重签 | `interp=3 source=file` | maps 含 `libclrinterpreter.so`、匿名 `r-x` 照录（Precode stub 风险，不得改策略）、managed 输出 | tar＋maps |
| 渲染/交互 | 任一态起来后 | —（功能性） | ①首帧 ②触摸→handler ③导航 ④列表/WebView | 截图/录屏/日志 |

## 1. 判定树（自上而下；先证跑通，再判模式）

1. `probe: 1=OK`？否（`1=1|12|13|38` 或启动 SEGV/`mprotect` 拒绝）→ 写 `xwe.txt=1` 复跑 A/B，两轮都记录；仍未通按崩溃分支取证。
2. 应用 managed 起来了（`[maui] openharmony build …`＋首帧）？否 → 按崩溃分支（applib/dlopen/bootstrap + `aot=`/`interp=` 行）取证，不进入后续态。
3. `aot=1`＋managed 输出＋无 `The application to execute does not exist`？是 → AOT 直启成立；若见 `bridged start_app … JIT payloads only` → 宿主滞后（§2.2 第 2 步）。
4. `interp=3 source=file`＋maps 含 `libclrinterpreter.so`？是 → 解释器激活；匿名 `r-x` 只计数（`Precode`/UMEntryThunk 残余先记录）。
5. 之后按 §2.4 做四项功能性判定；每态单独一轮，不混轮。

## 2. 精确步骤 / 期望 / 回传

### 2.1 JIT（kit #28 stock）
```sh
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60 --out tester-report
hdc shell "echo 1 > /data/storage/el2/base/haps/entry/files/xwe.txt"   # A/B：仅当 probe 1≠OK/SEGV 才写
sh tester-run.sh --kit-dir ./device-test-kit --start --capture 60 --out tester-report-xwe1
hdc shell "rm -f /data/storage/el2/base/haps/entry/files/xwe.txt"
```
期望：`summary aot_route=0 interp_mode=0(default)`；`xwe=0 source=default`（A/B 轮为 `xwe=1 source=file`）；`probe: 1=OK`；managed 输出＋首帧。
回传：`tester-report*.tar.gz`（A/B 两轮都发）。

### 2.2 AOT（aot-haps）
> **实测注意**：现资产内宿主是 R2-2 版 **265,120 B / `366720e0…`**，`start_app` 打
> `requires the one-shot run_app route; bridged start_app supports JIT payloads only`，
> **原包 `aa start` 不会有 `aot=1`**；先换 kit #28 宿主再判：
```sh
unzip -p ./device-test-kit/hello-maui-app.hap libs/arm64-v8a/libopenharmonyhost.so > host-k28.so  # 269,216 B / `bb51826e…`
# 把 host-k28.so 写回 hello-maui-app-aot-unsigned.hap 的 libs/arm64-v8a/libopenharmonyhost.so，按《自签说明.md》重签
sh tester-run.sh --kit-dir ./device-test-kit --hap ./hello-maui-app-aot-signed.hap --install --start --capture 60 --out tester-report-aot
```
期望：`summary aot_route=1`；`NativeAOT payload … aot=1`；managed 输出/首帧；无 `The application to execute does not exist`；hap 内无 `libcoreclr.so`/`libhostfxr.so`（AOT 形态）。
注意：AOT hap 的 bundle 与 kit 主包相同（`com.example.hellomauiapp`），装 AOT 会顶替 JIT 主包；回 JIT 需重装 kit 主 hap。

### 2.3 解释器（interp pack）
```sh
tar xzf ohos-interpreter-pack.tar.gz && (cd ohos-interpreter-pack && sha256sum -c SHA256SUMS)
# 取 hello-maui-app-unsigned.hap：libs/arm64-v8a/ 内替换 libcoreclr.so ＋ 加入 libclrinterpreter.so；重签
hdc shell "echo 3 > /data/storage/el2/base/haps/entry/files/interp.txt"
sh tester-run.sh --kit-dir ./device-test-kit --hap ./hello-maui-app-interp.hap --install --start --capture 60 --out tester-report-interp
hdc shell "pidof com.example.hellomauiapp"; hdc shell "cat /proc/<pid>/maps" | grep -E 'libclrinterpreter|r-x.*\[anon' > maps-interp.txt
hdc shell "rm -f /data/storage/el2/base/haps/entry/files/interp.txt"
```
期望：`summary interp_mode=3(file)`；`interp=3 source=file`；maps 含 `libclrinterpreter.so`、匿名 `r-x` 计数照录；managed 输出；无 `SEGV_ACCERR`。
回传：tar（含 execmem）＋maps 摘录＋pack `sha256sum -c` 输出。

### 2.4 渲染/交互（任一态）
① 首帧（截图）→ ② 触摸→managed handler（日志/状态）→ ③ 导航（页面切换）→ ④ 列表滚动＋WebView 加载；各附截图或日志。

## 3. 回传物汇总
`tester-report-*.tar.gz`（`hilog/hilog-execmem.txt`＋`summary.txt`＋install/start 日志）＋解释器轮 maps 摘录＋重签说明；
AOT/解释器轮附被替换 .so 的 sha256。数字以 release「## Integrity」/ `.sha256` sidecar 为准（重签、重打包后必变）。
