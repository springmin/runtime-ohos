# kit #37 本机真机复测轮（KIT37-LOCAL-VERIFY，2026-10-01）

> 设备 HAD-W32（OpenHarmony-7.0.0.111 / API 26 / 2in1），hdc 无线 `127.0.0.1:35111`，UDID `1BCE13C8…AEA0`；
> PowerManager 全程 **AWAKE**（未锁屏/无 10106102）。签名 = rc.2 线 SDK preview.28 `sign-hap.sh` + ohos-sdk 26.0.0.18_2；
> tester-run = **v14**（140,197 B / `a174fcd0…`，复用，与 release 一致）；资产自发布件核验（GitHub API digest 复核
> dtk 392356147 / latest 392077166）；证据 scratch `/data/storage/el2/base/tmp/opencode/kit37-local/`；
> 未改 kit 资产；设备侧仅临时 `hilog -G 16M` → **已还原 512K**（09:12:31，`bin/restore.out`）。

## 1. 资产核验 ✅
- API digest+size 与本地一致：tar **375,652,577 B / `3a7259d6…`**（dtk asset 602091003 / latest 602092868）；
  sidecar **89 B / `7db60a77…`**（内容 == tar 摘要）。
- 新解包 `SHA256SUMS` **17 项 / 1,517 B / `1ce87838…`**、`sha256sum -c` **17/17 OK**；`verify-kit.sh` 69,522 / `8723394d…`。
- `verify-kit.sh --expect-tree-digest` → tree **`ab517b57…` OK**；**KIT OK（0 FAIL/0 WARN；abc 339964/24324；host 293792 UND=238；Blazor 站点断言过）**。
- 抽查包内 hap：abc == `fc54d2b8…`、宿主 == `4e9f3c3e…`（与发布值逐字节一致）。

## 2. Blazor 双 hap A/B ✅✅（kit #37 新 hap 重签）
- **默认（CSP）**：重签 **27,252,812 / `d7f7bc7a…`** → install OK；pid 34619 / nonce `747dd8e7-…`；
  `BLZ_BOOT`+`BLZ_RENDERED` 同 pid、`BLZ_ERROR`=0；受控点击 Home→counter→Click me：**count 0→1→2**（dumpLayout）。
- **-nocsp**：重签 **27,252,998 / `6f1cbcc3…`**；pid 37054 / nonce `26773c31-…`；双标记齐、0→1→2。→ CSP 非瓶颈（承 #33–#36）。

## 3. tester-run v14 `--blazor-probe`（tree 绑定 `ab517b57…`）
- 512K 基线（默认）：`boot=no / rendered=yes`（failures=1）—— 本机 512K 环 ≈4–5 s 已知采集伪影（承 #34–#36），非应用失败。
- **16M 默认 PASS**（pid 42490、nonce present、failures=0）；**16M nocsp PASS**（pid 45108、failures=0）；`verify_kit=ok`。
- 证据 `tester-run/probe-*/summary.txt`；512K 已还原。

## 4. AOT 件（kit #37 线：rc.2 `-r2` 包 `542058cf…` + 切片 `68ec598037` + 壳 `fc54d2b8` + 宿主 `4e9f3c3e`）✅
- 本机重出+重签件 **21,490,919 / `ffd39d4b…`**（publish so 18,483,984 / `2494e4db…`；IL2026/IL3050/IL3051=0；
  in-hap 壳/宿主 == kit #37 发布值）→ install OK、pid 56406、VmRSS 274,892 kB / 69 thr；RSTree `ohos_dotnet_surface`×2 均 `hasSurfaceBuffer: 1`、`uiContent is null`=0。
- **首屏 Home 页内出画 ✅**（K0：标题/Hybrid 白区/Count 0/Entry/开关/形状/边框/媒体区；切回 Home K6 同样出画）—— FIX-HOME 真机复核。
- **Animations 切页 ✅**（K1/K7）；**注入点击「Run animations」✅**：偏靶 (1560,660) 0 变化（K2/K3，像素差 0.03/0.02）；
  绘制位 (1560,719) → **“fading out…”（K4, 0.6 s）→ “animations done”（K5, 3.1 s）** —— FIX-ITOUCH 真机复核。
- hilog：`HandleInputEvent`×12 / `TTHNI page→XComponent`×6 / `Consumed`×14；切页往返 K0→K1→K6→K7 正常。

## 5. 抽验：payload 原地直载 / 深链热激活 / B2 ✅
- 同 AOT 件：`payload-in-libs: running from …/entry/libs/arm64 (dotnet.zip not unpacked)` + `managed app hello-maui-app.dll started`；
  **深链热激活** `activation cold seq=2 uri=app://media/probe?from=k37-hot delivered=1`（冷启 seq=1 delivered=0 设计内）；
  媒体降级 `media load Unavailable`（E9 预期）。
- **B2 抽验**（i1b 重打包换 kit #37 宿主 `4e9f3c3e`，重签 **105,105,455 / `3786213d…`**）：pid 26763；payload-in-libs 同上；
  `web sink: true` + `web cmd: blazor|load`；**BLZ_BOOT/BLZ_RENDERED 同 pid、BLZ_ERROR=0**。

## 6. 复用 / 未覆盖
- **复用**：tester-run v14 `a174fcd0…`；发布/构建侧门禁（套件 544/floor 524、像素 KNOWN 清零、宿主导出 149/149、壳 `fc54d2b8`/`798b2477` 四包一致）为本轮发布证据（reg-kit37），本轮未重跑；a11y 承 #36（未复跑）。
- **未覆盖**：JIT 主包本机仍装不上（承 #34–#36；主判以 tester 机为准）；AOT 本轮为本机 kit #37 线重出件（**未发布**、未顶替 `aot-haps-v3-rc2`）；
  pinch element 坐标未上机（承 FIX-ITOUCH 不确定项）；抽屉/WebView 页内交互、carousel 手势、T8/T14/T21 等承交付方证据。
- 共享桌面窗口竞态（承 #35）：判定一律以 hilog/截图/RSTree 为准。

> 设备末态：`hellomauiwasm`（B2 抽验件）pid 26763；`hellomauiapp`/`opendotnet` 未运行；hilog 512K 已还原。
