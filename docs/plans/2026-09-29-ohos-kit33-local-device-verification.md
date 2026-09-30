# kit #33 本机真机自验（KIT33-LOCAL-VERIFY，2026-09-29）

> 设备：HAD-W32（`HAD-W24 7.0.0.111(SP3ENTC293E104R2P1log)`、`OpenHarmony-7.0.0.109`、API 26、UDID `1BCE13C8…AEA0`）；
> hdc 无线 `127.0.0.1:35111`；签名 = SDK `sign-hap.sh`（preview.24 模板，本机 UDID）；tester-run **v14**
> （140,197 B / `a174fcd0…`，asset 595131362，现从 release 取得）。证据 scratch = `/data/storage/el2/base/tmp/opencode/kit33-local/`
> （`logs/ caps/ probe/ hap/ jsons/`），本文只归档结论。设备与并行代理共享：Blazor 窗口曾数次被其安装/强停打断（非崩溃），证据均复取。
## 1. Blazor A/B（默认 CSP 与 nocsp 双胞胎）✅
- kit 完整性：`sha256sum -c SHA256SUMS` 17/17 OK；树摘要 `064cb001…`（`--expect-tree-digest`）通过；未改 kit 资产。
- 重签（各一次）：default 27,216,958 B / `69de2eea…` → `hap/blazor-default-signed.hap` 27,252,813 B / `abe9629b…`；
  nocsp 27,216,659 B / `c1ef7e06…` → `hap/blazor-nocsp-signed.hap` 27,252,998 B / `41a63c8f…`；两次安装均
  `install bundle successfully`（`logs/blz-*-install.txt`）。
- A（默认）流式 hilog：`marker: BLZ_BOOT [blz:8b2b374e-…]` 17:41:39.893 → `marker: BLZ_RENDERED [blz:8b2b374e-…]`
  17:41:40.856，同 pid 48751；二次启动复现（pid 60668、nonce `cf905e5b-…`，+2s/+3s）。截图：Home
  （.NET 11.0.0-rc.2.26459.117 / OS: Browser）与 Counter 页（`caps/blz-default-uitest*.png`）。
- B（nocsp）流式 hilog：pid 10221、`BLZ_BOOT [blz:985068a3-…]` 17:52:24.348 → `BLZ_RENDERED` 17:52:25.268；
  截图 Home + Counter（`caps/blz-nocsp1/2*.png`）。**受控点击**：`uitest uiInput click` 依次点 “Open the interactive
  counter” 与 “Click me” → `Current count: 0 → 1`（`caps/blz-counter-before-after.png`），ArkWeb→WASM 交互闭环。
- 双 hap 均无 `BLZ_ERROR`；宿主 pid + 同一 nonce 双标记齐（宿主行与 ARKWEB-CONSOLE 行各两份）。

## 2. tester-run v14 本机实跑 ✅（含 1 项本机固有噪声）
- 命令：`HDC=<hdc> sh tester-run.sh --kit-dir <kit> --expect-tree-digest 064cb001… --blazor-probe --blazor-hap <signed> --out <dir>`。
- run1 默认（512K 日志缓冲）：`blazor_install=ok`、`blazor_boot=no`、`blazor_rendered=yes`（pid 894；pid 因设备
  pid 回绕已复用）、nonce 行被日志环挤出 → `blazor_session_nonce=absent`、`failures=1`；归档
  `probe/blz-default-20260929-174903.tar.gz` / `3ff1e121…`。根因（本机）：桌面日志 ~1500 行/s、app+core 512K
  缓冲仅保留 ~4–5s，`sleep 4` 后 `hilog -x` 已把 BOOT 挤出（RENDERED 尚存）。
- 处置 + run2：临时 `hilog -G 16M -t app,core`（跑完已还原 512K 并复验）→ 同命令全绿：`blazor_boot=yes`
  `blazor_rendered=yes`、`blazor_marker_pid=6871`、`blazor_session_nonce=present`、`failures=0`；归档
  `probe/blz-default-bigbuf-20260929-175109.tar.gz` / `a2eb0098…`。
- run3（nocsp 孪生，同 16M 口径）：全绿 `pid=9817`、nonce `705ddb39-…`；归档 `probe/blz-nocsp-20260929-175213.tar.gz`
  / `16d81fc8…`。summary 键（三份）：`blazor_hap/bundle/install/boot/rendered/hilog_lines/marker_lines/marker_pid/session_nonce`
  + `failures`；kmsg/payload/lib 路由键在无录制窗口时为 `<unavailable>`（容忍）。
- **结论：工具本体路径可用；BOOT 竞态 = 桌面日志噪声，非 kit 缺陷。**

## 3. MAUI（JIT / AOT）⛔ 本机条件不足
- kit33 MAUI 5 hap 为 **payload-in-libs**（`libs/arm64-v8a/` 254 载荷 + 14 `.so` + `.dotnet-payload.json`）。实测
  `hdc install -r`：未签底本重签（本机 UDID）→ `9568393 verify code signature failed`；kit 预签 `hello-maui-app.hap`
  → 同码；`-permissions` 变体 → 先报 `9568289`（READ_CONTACTS 授权失败，签名关顺序不同）。查证：**本镜像不接受
  `libs/<abi>/**` 内非 ELF 载荷**——同机 `device-run/receipt.md`（CDGSS，2026-09-29）用诊断重打包定位：载荷移出 libs
  即 PASS。故 JIT 启动 / `SEGV_ACCERR`（禁 JIT）本轮本机不可得，需 payload-in-libs=false 的重出包或旧镜像。
- AOT v3：资产尚未发布（同机 `aot-v3/` 仍处构建等待期；release 仍只有 v2 / `265e014f…`），未复测出画。
- 反证一条（有利）：同机 locally-built、无 payload-in-libs 的 `ui-fix-60cf.hap` 可装可启动 —— 签名链本身通，堵点在布局。
- **根因更正（2026-09-30）**：并非“本镜像拒 `libs/` 内非 ELF”（AOT hap 含非 ELF 且可装）。实测为两个文件级陷阱：
  无扩展名文件（`createdump`）不在 HAP 码签块、恰好 4096 B 文件（`Microsoft.OpenHarmony.dll`）fs-verity 使能失败；
  完整证据与对策见 `2026-09-30-ohos-jit-payload-install-policy.md`。

## 4. 本机 vs tester 机（本轮实测，判读用）
| 项 | 本机桌面（HAD-W24 7.0.0.111 SP3 / API 26） | tester 机（HAD-W32 7.0.0.105） |
|---|---|---|
| hdc | `tconn 127.0.0.1:35111` 无线 | USB/同网直连 |
| hilog 通道 | 壳日志可达（`BlazorWebHost`/ARKWEB-CONSOLE）；512K 缓冲≈4–5s，`hilog -x` 竞态 | 音量低，`tester-run` 4s 窗口可用 |
| a11y | `uitest dumpLayout` 仅桌面节点（9 节点），ArkWeb DOM 不上屏 | 同工具，按套件判读 |
| 截图 | `uitest screenCap` 3120×2080 全屏可靠；窗口可被并行会话关掉/抢焦点 | 全屏 ability，稳定 |
| 签名/安装 | SDK 调试链可装且不校验 profile device-ids；**payload-in-libs 被拒** | 在线签名（PKI）+ 旧镜像接受 payload-in-libs |
| MAUI JIT | 无法装 kit hap → 无 `SEGV_ACCERR` 证据 | 期望 SEGV_ACCERR 禁 JIT（待其复测） |

## 5. 遗留
- ① handoff / `自签说明.md` 建议补注：新 HarmonyOS 镜像（≥7.0.0.111 系）拒绝 `libs/**` 非 ELF 载荷，kit MAUI hap 需
  `-p:OpenHarmonyHapPayloadInLibs=false` 重出，或注明 JIT 真机项仅限旧镜像/tester 机。
- ② 本机跑 `tester-run.sh --blazor-probe` 需加大日志缓冲（或调 `BLAZOR_PROBE_SLEEP`）；已在本文记录，未改 kit。
- ③ AOT v3 出包后（同机代理）建议按 `device-run.sh` 模板复测出画；本轮未测。
- 未改 kit 资产；全部操作 = 重签 / 安装 / 启动 / 日志 / 截图（设备侧仅有 app 安装与临时日志缓冲调整，已还原）。
