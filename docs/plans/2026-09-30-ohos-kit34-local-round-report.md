# kit #34 本机「tester 等价」复测轮（KIT34-ROUND，2026-09-30）

> 设备 HAD-W32（OpenHarmony-7.0.0.111(SP3ENTC293E104R2P1log) / API 26 / 2in1），hdc 无线 `127.0.0.1:35111`，
> UDID `1BCE13C8…AEA0`；签名 = rc.2 线 SDK preview.28 `sign-hap.sh` + `ohos-sdk 26.0.0.18_2/toolchains/lib`；
> tester-run 取 release「零变更」资产 **v14**（140,197 B / `a174fcd0…`）。证据 scratch
> `/data/storage/el2/base/tmp/opencode/kit34-round/`（`kit/ blazor/ tester-run/ maui/ a11y/ bin/`）；未改 kit 资产；
> 设备侧仅临时调 hilog 缓冲（16M→已还原 512K）。本机已知限制（JIT payload-in-libs 拒装 / 无 libhilog_ndk）见 §6。

## 1. 资产核验 ✅
- kit tar **375,181,367 B / `55834aeb…`**、sidecar 89 B / **`c03ea23d…`**（内容 == tar 摘要）= release 值；
  `SHA256SUMS` 17/17 OK；tree digest `d08de3ec…` OK；`verify-kit.sh`（69,522 B / `dcd81f33…`）**KIT OK、0 FAIL / 0 WARN**（exit 0）。
- AOT 取件 `aot-haps-v3-rc2.tar.gz`（id 599996905）**18,185,012 / `3d24f716…`**；包内 2 hap `sha256sum -c` OK；
  hap 指纹：UI 壳 abc **311,424 / `7c1a3cac…`**、宿主 **285,600 / `00ee9c84…`**、`runtime-mode.txt=aot`、app so 18,529,040 / `5adb9a6b…`。
- 命令：`sha256sum <tar> <sidecar>`；`(cd <kit> && sh verify-kit.sh --tree-digest --expect-tree-digest d08de3ec…)`。证据 `kit/assets.txt`、`kit/verify-kit.out`。

## 2. Blazor 双 hap A/B ✅✅（承 #33 判定树）
- 各重签（本机 UDID）→ `bm uninstall` → `hdc install -r` OK → `aa start` OK。
  **默认（CSP）**：同 pid 同 nonce 双标记齐、无 `BLZ_ERROR` —— pid 43179 / `653f6ed1-…`（首轮）、pid 27993 / `9eb04520-…`（复轮）。
  **-nocsp**：pid 61101 / `22ea6017-…` 双标记齐、无 `BLZ_ERROR`。
- 受控点击（`uitest uiInput click`，坐标取 `dumpLayout` bounds）：Home → `/counter` → `Click me`；两变体
  `Current count: 0 → 1`（WASM 互操作往返成立）→ **默认 ✅ = CSP 非瓶颈**（与 #33/rc.2 前证一致）。
- 证据：`blazor/default|nocsp/{sign.log,install*.txt,markers-stream*.txt,screenshot-home*.jpeg,screenshot-counter0/1.jpeg,layout-*.json}`。

## 3. tester-run v14 `--blazor-probe`（⚠️ 512K 基线 → ✅ 16M 全绿）
- 512K（默认件）：`boot=no / rendered=yes / nonce=absent / failures=1` —— 本机 512K 环只留 ≈4–5 s，探针 4 s 窗口
  把 BOOT/nonce 挤出（同轮流式双标记齐全，属采集伪影、非渲染缺陷；承 #33/#34 本机注记）。
- 临时 `hilog -G 16M -t app,core`：默认 `failures=0`（pid 44549，`boot=yes / rendered=yes / nonce=present`）；
  nocsp `failures=0`（pid 47134，同键）。跑完 `hilog -G 512K -t app,core`，复核已还原。
- 命令：`HDC=<绝对路径> sh tester-run.sh --kit-dir <kit> --expect-tree-digest d08de3ec… --blazor-probe --blazor-hap <signed>`。
  证据：`tester-run/probe-*/summary.txt` + `probe-*-20260930-*.tar.gz`（512K 失败轮留作对照）。

## 4. MAUI：JIT ⛔ / AOT rc.2 ✅（+UI 判定尽力）
- **JIT**：kit 未签 hap 本机重签（133,827,246 B / `01729bd8…`）→ `9568393 verify code signature failed`；
  hilog `CODE_SIGN … Libs signature not found: signMap_ size:270, signMapPreSize:1`（已知 ≥7.0.0.111 镜像限制，非 kit 缺陷）。
- **AOT rc.2**：未签件重签（21,498,976 B / `f4a1e097…`）→ install OK；`aa start` OK（pid 6239；VmRSS 183.8 MB / 68 thr；`OS_GC_Thread`×5）；
  RSTree `ohos_dotnet_surface` **`hasSurfaceBuffer: 1`**（1 节点）、WMSDecor `uiContent is null`=0；截图 = 渐变主体 + 壳 A11Y 按钮（与前证一致）。
- **UI 判定尽力**：AOT 壳页内控件未出画（仅壳按钮）；`click/swipe/fling` 尝试无控件响应（窗口被桌面手势改宽后置底，进程存活）。
  TabbedPage 双页签/切页、T14/T12/N1、T15/T16/N4/T18/N5/N6 交互 **「需人工点击」**（tester JIT 机；kit JIT dll 字符串亦无 T15/T16/N4–N6 专用入口）。
- 证据：`maui/jit/jit-install.out`；`maui/aot/{aot-install.out,pid.txt,rstree.txt,wms.txt,screenshot-aot-*.jpeg,ui-attempts*.txt}`。

## 5. 无障碍（rc2 壳 `nodeCount=0` 复核）
- `uitest dumpLayout`：Blazor ArkWeb 窗口**可取**（web DOM：link/status 等，树 ≈300 节点）；MAUI 窗口仅壳 `Button 'A11Y'` + 根（无 MAUI 控件节点）。
- 壳 A11Y 自检弹窗：`accessibilityStatus: 1 (attached - expected)` / **`accessibilityNodeCount: 0`**（现象复现）。
- `tester-run --a11y-probe`：`a11y_selfcheck=ok`、`a11y_node_count=0`、`a11y_provider_status=<unavailable>`（本机无 `libhilog_ndk`）；归档 `a11y-probe-20260930-132256.tar.gz`。
- 证据：`a11y/layout-maui-aot.json`、`a11y/layout-a11y-dialog.json`、`tester-run/a11y-probe{,.log}/`。

## 6. 本机 vs tester 机差异（本轮实测）
| 项 | 本机 HAD-W32（7.0.0.111 桌面） | tester 机（手机） |
|---|---|---|
| JIT 主包 | ⛔ 9568393（payload-in-libs 码签块） | 预期可装；JIT/模式矩阵主场 |
| hilog 缓冲 | 512K≈4–5 s → 探针 4 s 窗竞态；16M 临时即全绿 | 待核对；大缓冲或先 `--capture` 复核 |
| 宿主 `aot=`/`[maui]` 行 | 不可见（无 libhilog_ndk.z.so） | 可见 |
| AOT 壳 | 渐变主体+壳 A11Y 按钮；页内控件未出画 | JIT 机人工项（tab/W6/W7/W8） |
| 截图 | `snapshot_display` 必须 `.jpeg` | `.png` 常用 |
| a11y | ArkWeb 树可取；MAUI 壳枚举=0（rc2 follow-up） | `--a11y-probe` 正式口径 |

## 7. 未覆盖（需人工/外部）
- tab 双页签/切页、W6（T14/T12/N1/T13/T21/T22）、W7/W8（T15/T16/N4/T18/N5/N6）、W5 交互证据 → tester JIT 机人工点击。
- rc.2 壳 a11y 枚举（nodeCount=0）→ 平台侧 follow-up。harmony/Map/LiveView/TTS/HUKS → AGC/外部环境。mode-matrix（JIT/XWE/解释器/AOT 段）本机因 JIT 拒装未跑。
- 门禁 513/floor 493、导出 145/145、像素 PASS = 交付方证据（handoff §6.4），本轮不重跑。

> 设备末态：`hellomauiapp`(AOT) pid 6239、`opendotnet`(nocsp) pid 47134 运行；hilog 512K 已还原；AOT 顶替 kit 主包（同 bundle，回 JIT 需重装）。
