# kit #41 本机真机复测轮（KIT41-LOCAL-VERIFY，2026-10-03）

> 设备 HAD-W32（OpenHarmony-7.0.0.111(SP3ENTC293E104R2P1log) / API 26 / 2in1），hdc 无线 `127.0.0.1:35111`（在线），
> UDID `1BCE13C8…AEA0`；PowerManager 全程 **AWAKE**、无锁屏（各阶段截图可见桌面/应用窗口）。签名 = rc.2 线 preview.28
> `sign-hap.sh` + ohos-sdk 26.0.0.18_2；tester-run = **v14**（140,197 B / `a174fcd0…`）；解释器 pack = **`ohos-interpreter-pack-rc2`**（2,409,070 B / `34709a94…`，下载件复核一致）；
> 证据 scratch `/data/storage/el2/base/tmp/opencode/kit41-local/`；未改 kit 资产；hilog 设备侧 16M → **已还原 512K（03:04:40）**。

## 1. 资产核验 ✅
- tar **376,036,502 B / `bed460ae…`**；sidecar 内容 == tar 摘要（89 B / `2a95e764…`）；全新解包；
  `SHA256SUMS` **17 项 / 1,517 B / `421a819c…`**、`sha256sum -c` **17/17 OK**；tree **`7ce1946e…`** OK。
- `verify-kit.sh` 69,717 B / `efa27d31…` → **KIT OK 0 FAIL / 0 WARN**：15 `.so` / 257 zip / abc 356140/24324 / 宿主 293,792 / UND 239 /
  DT_NEEDED 5 / payload 272；7 hap sha 与 RELEASE-VALUES #41 全等（含 Blazor 双 hap `d6237e96…`/`1d763d35…`）。

## 2. Blazor A/B + tester-run v14 ✅
- **默认**（重签 27,252,814 / `ae501b6f…`）：install OK；pid 2823 / nonce `a75e40f3-…`；`BLZ_BOOT`+`BLZ_RENDERED` 同 pid、`BLZ_ERROR`=0；
  受控点击 Home→counter→Click me：**count 0→1→2**（dumpLayout counter0/1/2 + 截图）。
- **-nocsp**（27,252,998 / `ae853c59…`）：pid 5955 / nonce `59720cde-…`；双标记齐、**0→1→2**。
- tester-run v14（tree 绑定 `7ce1946e…`）：512K 对照 default `boot=no/rendered=yes`（nonce absent、failures=1 —— 本机 512K 环已知采集伪影，
  承 #34–#40）；**16M default PASS**（pid 23174、nonce present、failures=0）；**16M nocsp PASS**（pid 25839、failures=0）；`verify_kit=ok`。

## 3. DEVCOMPAT 默认：JIT 主 hap 直装 ✅ + 启动（JIT 崩属预期）
- kit `hello-maui-app-unsigned.hap` 重签 **134,087,921 / `7e1a9050…`** → `hdc install -r` **install bundle successfully**
  （#40 及以前同镜像为 9568393；未重写对照 `9568393` 的 A/B 见 DEVCOMPAT-DEFAULT 记录，本轮确认修后态）。
- 启动：`payload-in-libs: running from …/libs/arm64 (dotnet.zip not unpacked)` + `managed app hello-maui-app.dll started (UI shell)`
  → ~30 ms 崩 `SIGSEGV(SEGV_ACCERR)@0x5cccfe0000`，栈 `memcpy+312 ← libcoreclr(8df41ced) coreclr_initialize+996`（系统禁 JIT，预期；唯一新 faultlog）。

## 4. 多覆盖层 FULL：双区出画 + LRU/激活序 ✅（AOT 同线件）
- 件 = 本机按 kit #41 线重建的 AOT（abc **356,140/`2a90f0d7…`**、宿主 **`8d67def3…`**、maui `07423dfe93`；unsigned 21,581,269、
  重签 **21,845,398 / `a4ece296…`**）。双区：`web page (slot 0)`+`(slot 1)`、`hybrid assets slot=0/1`、两条 "…origin https://0.0.0.1" 出画；
  页内 Send raw A/B → MAUI 标签 `A raw: A-raw-ping` / `B raw: B-raw-ping`（per-slot 消息闭环）；`canvas presented`=761、`touch callback failed`=0。
- LRU/激活序（坐标点击，dump 区文本判定）：A+B → **Add web C** 后 A 被抢（区 = B+C，slot0 改服 hybrid-c.html）；
  **Activate A** → A 恢复、B 被抢（A+C，slot1 重服 hybrid-a.html）；**Activate B** → B 恢复（B+C，slot1 重服 hybrid-b.html）。
- FULL 演示页按设计不含 BlazorWebView（`0e0129e` 注释），"同页 hybrid+Blazor"无对应入口；Blazor 面由 §2/§6 覆盖。

## 5. 解释器：rc.2 pack 换入 → 装/启存活 ✅（崩溃点消失；首帧未出，如实登记）
- 件 = kit 线 interp variant（`-p:OpenHarmonyRuntimeMode=interp -p:OpenHarmonyInterpreterPack=<rc2 pack>`；unsigned 123,332,300）
  内件 abc 356,140/`2a90f0d7…`、宿主 `8d67def3…`、`libcoreclr` BuildID `bc5ff740…`、`libclrinterpreter` `ba83106b…`、`runtime-mode.txt=interp`；
  重签 **125,803,699 / `44ea0d46…`**。
- install OK；启动后 pid 存活 >25 s–5 min；faultlogger **0 条新 `cppcrash`**（最新仍是 §3 的 02:31 JIT 记录）→ `coreclr_initialize+440`/写屏障崩溃点消失。
- **不确定（登记，不判失败）**：本轮 FULL 件与 23:39 pre-FULL e2e interp 件同镜像均"存活但未出首帧"（窗口停在 shell/launch 画面、`canvas presented`=0）；
  与 INTERP-FIX §4 正文的 411 行（23:35 一次）不一致、与其 final 快照（canvas=0）一致 → interp 首帧呈现为本镜像未决/偶发项。

## 6. razor 计数 + 抽屉/Back 回归（kit #41 线）✅
- razor AOT 重建（maui `07423dfe93` + 壳 abc **356,152/`6782cee3…`**（`hellomauirazor` bundle 名变体）+ 宿主 `8d67def3…`；
  unsigned 21,601,720 / `3c1419df…`；重签 **21,916,791 / `6c8e16fd…`**；IL2026/3050/3051=0）。
- 页面 `BlazorWebView component (.razor)` + `count: 0`；注入 "Blazor click" ×2 → **count 0→1→2**；`missing native code`=0、`interop-call`=0、
  `BLZ_DIAG accepted=20/send=16`、`BeginInvokeJS`=12/`BeginInvokeDotNet`=8、`touch callback failed`=0；`blzProbe` JSException 为样例未定义（`| plain ok`，承 #40）。
- 抽屉/Back（§4 件）：外点关 ×2 轮每轮 `web cmd: suspend`×2→`resume` 且 `#FOREGROUND`；开抽屉→Back 仍 `#FOREGROUND`；再 Back→`#BACKGROUND`；
  另抽验 `web sink: true`、`web cmd: hybrid`、热深链 `seq=3 uri=app://media/probe?from=k41-hot delivered=1`。

## 7. 复用 / 未覆盖 / 不确定
- 复用：kit #41 发布/门禁证据（交互 563/543、pixel PASS、导出 150/150、preflight、CI 5/5 @ `4bfcd68`）为本轮发布证据，未重跑。
- 未覆盖：JIT 9568393 原包 A/B（用发布记录）、interp 首帧、真机 live Navigate、套件/像素本地重跑、tester 机预签包。
- 不确定：共享桌面窗口竞态（判定以 hilog/状态/截图/dumpLayout 为准）；interp 首帧（§5）；FULL 演示无同页 Blazor（§4）。设备末态：`hellomauiapp` AOT pid 11768 `#BACKGROUND`、`hellomauirazor` pid 16882 `#FOREGROUND`、`opendotnet`（nocsp 件）已装未运行；hilog 512K 已还原（03:04:40）；PowerManager AWAKE。
