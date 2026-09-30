# kit #35 本机「tester 等价」复测轮（KIT35-LOCAL，2026-09-30）

> 设备 HAD-W32（OpenHarmony-7.0.0.111(SP3ENTC293E104R2P1log) / API 26 / 2in1），hdc 无线 `127.0.0.1:35111`，
> UDID `1BCE13C8…AEA0`；签名 = rc.2 线 SDK preview.28 `sign-hap.sh` + `ohos-sdk 26.0.0.18_2/toolchains/lib`；
> tester-run = **v14**（140,197 B / `a174fcd0…`，与 release 一致）；证据 scratch `/data/storage/el2/base/tmp/opencode/kit35-local/`
> （`kit/ kitmeta/ blazor/ tester-run/ maui/ a11y/ bin/`）；未改 kit 资产；设备侧仅临时调 hilog 缓冲（16M → 已还原 512K）；
> `RELEASE-VALUES.txt` 轮询到 **FINAL**（STATUS 标 23:45；本机 23:32 检出，其后无改）。

## 1. 资产核验 ✅
- kit tar **375,629,423 B / `419d42e2…`**、sidecar 89 B / **`d7e79d39…`**（内容 == tar 摘要）= FINAL 值；解包 18 文件、
  `SHA256SUMS` **17/17 OK**（1,517 B）、tree digest **`d3b1b317…`** OK；`verify-kit.sh`（69,522 B / `c3cd4d38…`）
  **KIT OK、0 FAIL / 0 WARN**（exit 0；深度断言 abc 339,164 / 23,516、host 293,792、payload 269、DT_NEEDED 5 / UND 240 / denylist 0）。
- AOT 取件 `aot-haps-v3-rc2.tar.gz` **18,185,012 / `3d24f716…`**；包内 2 hap `sha256sum -c` OK。
- 命令：`sha256sum <tar> <sidecar>`；`(cd <kit> && sh verify-kit.sh --tree-digest --expect-tree-digest d3b1b317…)`。证据 `kitmeta/`。

## 2. Blazor 双 hap A/B ✅✅（承 #33/#34 判定树）
- 各重签（本机 UDID）→ `bm uninstall` → `hdc install -r` OK → `aa start` OK；**同 pid 同 nonce 双标记齐、无 `BLZ_ERROR`**：
  **默认（CSP）** pid 5689 / `9321a327-…`；**-nocsp** pid 9221 / `26e214b1-…`（`BlazorWebHost` 行 + ARKWEB-CONSOLE 转发）。
- 受控点击（`uitest dumpLayout -b` 窗内坐标 + `uiInput click`；共享桌面每步先 `aa start` 置前）：Home → “Open the interactive
  counter” → “Click me”；两变体 **`Current count: 0 → 1`**（WASM 互操作往返成立）→ **默认 ✅ = CSP 非瓶颈**（与 #33/#34 前证一致）。
- 证据：`blazor/default|nocsp/{sign.log,install.txt,markers-stream.txt,screenshot-home.jpeg,layout-counter0/1.json,click-*.txt}`。

## 3. tester-run v14 `--blazor-probe`（⚠️ pid 竞态 → ✅ 复跑全绿）
- 512K 基线（默认件）：`boot=no / rendered=yes` —— 本机 512K 环 ≈4–5 s，属采集伪影（承 #34）。
- 16M：默认首轮 `failures=1`（**探针 pid 竞态假阴性**：dump 内标记 pid 52699，`pidof` 已见 53671 → host-markers 过滤后 0 B）；
  **默认复跑 PASS（pid 25131）**、**nocsp PASS（pid 56763）**，均双标记齐。
- 命令：`HDC=<绝对路径> sh tester-run.sh --kit-dir <kit> --expect-tree-digest d3b1b317… --blazor-probe --blazor-hap <signed>`；
  证据 `tester-run/probe-*/summary.txt` + `probe-*-20260930-*.tar.gz`（含失败轮对照）。

## 4. MAUI：JIT ⛔（本机限制）/ AOT rc.2 ✅
- **JIT**：kit 未签 hap 重签 → `9568393 verify code signature failed`；hilog `CODE_SIGN … Libs signature not found: signMap_ size:270, signMapPreSize:1`（已知载荷布局限制，非 kit 缺陷）。
- **AOT（aot-haps-v3-rc2）**：未签件重签 → install OK；`aa start` OK（pid 58027；VmRSS 187.9 MB / 70 thr；`OS_GC_Thread`×5）；
  RSTree `ohos_dotnet_surface… hasSurfaceBuffer: 1`、WMSDecor `uiContent is null`=0；`runtime-mode.txt=aot`。
- 证据：`maui/jit/jit-install.out`；`maui/aot/{aot-install.out,pid.txt,rstree.txt,wms.txt,screenshot-aot-home.jpeg}`。

## 5. 新壳/新特性（W9/W10 线，本机 AOT 真机复核）
> kit tar 无 B2/深链演示 hap；本节用 W10 演示 hap（宿主 `983e8f74` **== kit35 包内宿主**）：wasm 件
> `hello-maui-wasm-diag5.hap`（abc 339,168/`1178c541…`，与 080a63aa 现树重建**逐字节一致**）；app 件 = inv hap 换入
> **kit35 最终壳 abc（339,164/`74054e2d…`）** 重打包重签（21,618,684/`bb0d859c…`）。
- **B2 真机 BLZ**：MAUI WebView 载 Blazor WASM → **`BLZ_BOOT` + `BLZ_RENDERED`**（同 pid 59647，无 `BLZ_ERROR`）；壳 `web sink: true`；
  托管入口 `hello-maui-wasm.dll started`；站点经壳 `NWebResourceHandler` 直供。证据 `maui/wasm/{run.out,stream.txt}`。
- **深链热激活**：冷 `-U app://media/probe?from=k35-cold` → `activation cold seq=1 delivered=0`（设计内）；运行中再投 → **`delivered=1`**（seq=2，同 pid 6251）。
- **媒体降级行**：`media sink registered`、`media self-test media-kit=missing media-core-capability=true`、
  `[media-probe] load status=Unavailable message='the platform answered -1'`（无 MediaKit 不抛，E9 预期）。
- **AOT 入口可观测**：`managed app hello-maui-app.dll started (UI shell)` + `dotnet-status.txt lines=1345 meaningful=1343` + `canvas presented`（W10 通道成立）。证据 `maui/app/deeplink-media.out`。

## 6. 无障碍（rc2 壳 `nodeCount` 复核）
- 发货 AOT rc2 资产（pre-W10 壳）自检：`accessibilityStatus: 1` / **`accessibilityNodeCount: 0`** —— #34 现象**复现**（`a11y/rc2/`）。
- kit35 最终壳 + W10 宿主 + AOT rc.1 应用：自检 **`nodeCount: 1`（手动）/ `24`（--a11y-probe 稳定态）**、`a11y_selfcheck=ok`；
  → rc2 的 0 节点与「托管入口未达、树未发布」一致，W10 入口修复后该现象消失（同机对照）。
- `--a11y-probe`：`a11y_provider_status=<unavailable>`（本机无 `libhilog_ndk`，承 #34）；归档 `a11y/probe2-20260930-232958.tar.gz`（`7646783e…`）。

## 7. 差异 / 未覆盖
- 共享桌面：窗口会被他人抢焦点/遮挡（探针 pid 竞态、截图不净、点击需每步置前）；判定以 hilog/status/RSTree 为准。
- kit 包内无 B2/深链/媒体入口 → 以 W10 演示 hap 复核（宿主与 kit35 同）；JIT 与主判仍以 tester 机为准。
- tab 双页签/T14/T21/T8、W6/W7/W8 交互、mode-matrix、套件 540/floor 520、导出 149/149、像素 PASS → 承交付方证据，本轮不重跑。
- harmony/Map/LiveView/TTS/HUKS → 外部环境，未覆盖。

> 设备末态：`hellomauiapp`(AOT rc2) 已卸（JIT 9568393 拒装）；`opendotnet`(默认) pid 25131、`hellomauiwasm`(B2) pid 56907 运行；hilog 512K 已还原。
