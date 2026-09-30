# kit #36 本机真机复测轮（KIT36-LOCAL，2026-10-01）

> 设备 HAD-W32（OpenHarmony-7.0.0.111 / API 26 / 2in1），hdc 无线 `127.0.0.1:35111`，UDID `1BCE13C8…AEA0`（未遇锁屏 10106102）；
> 签名 = rc.2 线 SDK preview.28 `sign-hap.sh` + ohos-sdk 26.0.0.18_2；tester-run = **v14**（140,197 B / `a174fcd0…`，**复用**，与 release 一致）；
> 资产自发布件快照 `reg-kit36`（RELEASE-VALUES **FINAL** 01:38 检出）核验；证据 scratch `/data/storage/el2/base/tmp/opencode/kit36-local/`
> （`kit/ kitmeta/ blazor/ tester-run/ maui/ payload/ a11y/ bin/`）；未改 kit 资产；设备侧仅临时 `hilog -G 16M` → **已还原 512K**。
> 复用标注：AOT 包 `aot-haps-v3-rc2`（`3d24f716…`）与 #35 同字节 → 指纹引用 + 本轮重签重跑；W10 demo 基座 hap 沿用。

## 1. 资产核验 ✅
- tar **375,627,841 B / `9eb9cecf…`** == sidecar 内容（89 B / `4d7062c3…`）；`SHA256SUMS` **17 项 / 1,517 B / `d643493c…`**；
  解包 18 文件、`sha256sum -c` **17/17 OK**；tree digest **`9764827c…` OK**。
- `verify-kit.sh`（69,522 B / `8723394d…`）**KIT OK — 0 FAIL / 0 WARN**（exit 0；abc 期望 **339964/24324**；5 hap 深度断言全过；Blazor 站点断过）。
- AOT 取件 `aot-haps-v3-rc2.tar.gz` **18,185,012 / `3d24f716…`**（未变；复用 #35 指纹）。命令与输出 `kitmeta/assets.txt`、`verify-kit.out`。

## 2. Blazor 双 hap A/B ✅✅（kit #36 新 hap 重签）
- **默认（CSP）**：重签 **27,252,814 / `46fc697c…`** → install OK；pid **7382** / nonce **`d62ae70d-…`**；
  `BLZ_BOOT` + `BLZ_RENDERED` 同 pid、无 `BLZ_ERROR`；受控点击 Home → counter → Click me：**`Current count: 0 → 1`**。
- **-nocsp**：重签 **27,252,998 / `b0f3cf72…`**；pid **8812** / nonce **`cd798329-…`**；双标记齐、0 → 1。→ **CSP 非瓶颈**（承 #33–#35）。
- 证据 `blazor/{default,nocsp}/{sign.log,install.txt,markers-stream.txt,layout-counter*.json,click-*.txt,screenshot-home.jpeg}`。

## 3. tester-run v14 `--blazor-probe`（tree 绑定 `9764827c…`）
- 512K 基线（默认）：`boot=no / rendered=yes`（failures=1）—— 本机 512K 环 ≈4–5 s 的**已知采集伪影**（承 #34/#35），非应用失败。
- **16M 默认 PASS**（pid 16925、nonce present、failures=0）；**16M nocsp PASS**（pid 19657、nonce present、failures=0）；`verify_kit=ok`。
- 证据 `tester-run/probe-*/summary.txt`。

## 4. MAUI AOT ✅（`aot-haps-v3-rc2` 复用 + 重签）
- 重签后 **`e6305eb7…`** → install OK → pid **23062**；VmRSS **184.1 MB / 69 thr**、`OS_GC_Thread`×5；
  RSTree `ohos_dotnet_surface` **hasSurfaceBuffer: 1**、WMS `uiContent is null`=0；`runtime-mode.txt=aot`；截图 OK。
- 注：包内 abc **311,424 / `7c1a3cac…`**（#34 代壳、pre-W10）→ a11y 新点用最终壳 demo 件复核（§5）。
- 证据 `maui/aot/{aot-install.out,pid.txt,rstree.txt,wms.txt,screenshot-aot-home.jpeg}`。

## 5. 新点复核
- **payload 原地直载 ✅**：i1b demo 重装（新 pid **24272**）→ `payload-in-libs: running from /data/storage/el1/bundle/entry/libs/arm64 (dotnet.zip not unpacked)`；
  同 pid `managed app hello-maui-wasm.dll started (UI shell) from …/libs/arm64` + `start_app aot dlopen now=ok`；app-k36 同线（pid 29721）。
- **B2 BLZ ✅**：同轮 `BLZ_BOOT`/`BLZ_RENDERED`（pid 24272）、`BLZ_ERROR`=0；`web sink: true` + `web cmd: blazor|load`
  （注册前命令由 host 预注册缓冲 flush，原地直载竞态被覆盖）。
- **深链热激活 ✅**：冷投 `activation cold seq=1 delivered=0`（设计内）；运行中再投 **`seq=2 delivered=1`**（同 pid 29721）。
  媒体降级：`media sink registered`、`media self-test media-kit=missing media-core-capability=true`、`media request op=0 … media-probe.wav`、`window title applied: media load Unavailable`（E9 预期）。
- **像素 0 KNOWN（引用交付方证据）**：`reg-kit36/pixel-run.log` `[PASS] selection tint: got #3959B3 expected #3959B3` + `PIXEL ASSERTIONS PASSED`、`Known(`=0；
  同源门禁 `[suite] checks=540 total=540 floor=520`、宿主导出 149/149（`reg-kit36/`）。
- **a11y**：wasm 自检 **`status: 1 (attached) / nodeCount: 5` 稳定**（5/5，两次读；与交付方 i3 一致）✅；
  app-k36 自检 **`status=1 / nodeCount=1` 稳定**（3 轮）>0；`--a11y-probe`：`a11y_selfcheck=ok`、`node_count=1`、`provider_status=<unavailable>`（本机无 `libhilog_ndk`，承 #34）。
  **`24` 本轮未复现**：#35 probe2（09-30 23:29 同机）曾得 24；今日同条件复跑 #35 同件亦为 1 → 属环境/状态相关、**非 #36 回归**；登记为未覆盖项。

## 6. 复用 / 差异 / 未覆盖
- **复用**：AOT `3d24f716…`、tester-run v14 `a174fcd0…`、Blazor kit hap 原件、W10 demo 基座（diag5/inv）与交付方 i1b 件（最终 host `cfbbe461` + wasm 变体壳 `07a270fa`）。
- **新证**：资产全量核验、双变体重签 A/B + 点击、tester-run 16M 双 PASS、AOT 重签重跑、app demo（最终壳 `fc54d2b8`+host `cfbbe461` 重打包 **21,626,076 / `ec9c378d…`**）的 payload/深链/媒体/a11y。
- **未覆盖**：JIT 主包本机仍装不上（`9568393`，承 #34/#35；libs 无扩展名/4096 B fs-verity）→ 主判以 tester 机为准；
  无 kit 内 B2/深链入口（用上述 demo 件）；tab 双页签/T14/T21/T8、mode-matrix、本机重跑套件/导出、W6/W7/W8 → 承交付方证据；harmony/Map/LiveView/TTS/HUKS 未覆盖。
- 共享桌面窗口竞态（承 #35）：判定一律以 hilog/status/RSTree 为准。

> 设备末态：`opendotnet`（默认件）pid 43069、`hellomauiapp`（app-k36）pid 42959、`hellomauiwasm`（i1b）pid 24272 运行；hilog 512K 已还原。
