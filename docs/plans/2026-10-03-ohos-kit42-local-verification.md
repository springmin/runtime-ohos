# kit #42 本机真机复测轮（KIT42-LOCAL-VERIFY，2026-10-03）

> 设备 HAD-W32（OpenHarmony-7.0.0.111(SP3ENTC293E104R2P1log) / API 26 / 2in1），hdc 无线 `127.0.0.1:35111`（在线），
> UDID `1BCE13C8…AEA0`；PowerManager 全程 **AWAKE**、无锁屏（12:51 首拍 + 各轮截图均见桌面/应用窗口）。签名 = rc.2 线 preview.28
> `sign-hap.sh` + ohos-sdk 26.0.0.18_2；tester-run = **v14**（140,197 B / `a174fcd0…`）；解释器 pack = **`ohos-interpreter-pack-rc2b`**
> （2,410,595 B / `5974430509…`）；证据 scratch `/data/storage/el2/base/tmp/opencode/kit42-local/`；未改 kit 资产；
> 设备侧 hilog 16M → **已还原 512K（14:19:54）**。

## 1. 资产核验 ✅
- tar **376,256,128 B / `ea4e3b58…`**（与 release API 上传后 digest 同值）；sidecar 89 B / `878d05a1…` = 标准 sha256sum 行；
- 全新解包；`SHA256SUMS` 17 项（1,517 B）**17/17 OK**；tree **`13f3a086…`**；`verify-kit.sh` 69,717 B / `0995a406…` →
  **KIT OK**（5 hap 深度断言全过；唯一提示 = 自签包需重签，属预期）；rc2b pack sha 复核 OK。

## 2. Blazor A/B（默认/nocsp）✅
- default 重签 27,252,812 / `65838dc5…`：pid 61256 / nonce `a54e4b19-…`；`BLZ_BOOT`+`BLZ_RENDERED`、`BLZ_ERROR`=0；
  受控点击 Home→counter→Click me：**count 0→1→2**（dump + 截图）。
- nocsp 重签 27,252,996 / `a59d3a2b…`：pid 10546 / nonce `626ff685-…`；同上 **0→1→2**。

## 3. tester-run v14（16M 复核 + 512K 还原）✅
- 16M 置位（14:18:39）→ default：`verify_kit=ok`、tree `13f3a086`、boot/rendered=yes、pid 31646；
  nocsp：同上、pid 34444；归档 `d2a331b0…` / `67b6306f…`；**512K 还原 14:19:54**（hilog -g 复核）。

## 4. JIT 路径：装/启 → prctl 解锁 + ICU invariant → CoreLib→MAUI→首帧 ✅
- kit 未签主 hap 重签 **134,191,593 / `81e3c7fc…`** → `hdc install -r` **success**（DEVCOMPAT 默认可装；无 9568393/9568344）。
- pid 19216 存活 10/25/35 s；`payload-in-libs: running from …/libs/arm64 (dotnet.zip not unpacked)`；
  **`OHOS_DOTNET jitfort: rc=0 errno=0 state=off`**；**`globalization: invariant=1 icu=0 source=probe`**；probe `1=OK 2=OK 3=13 4=1`；
  `managed app hello-maui-app.dll started (UI shell)`；**`canvas presented (2090x1324)` ×767**；0 SIGSEGV/coreclr_initialize/ICU 失败/切片竞争签名；
  faultlog（fl-after 全量）最新 hellomauiapp crash 为 11:07，本轮 13:01–13:03 窗口无新增；截图 `frame.jpeg` 见 FULL 演示 UI 首帧。
- race 8/8 复核：r1–r8 每轮 `race=0 pvnull=0 conc=0 unhandled=0 jitfort=1 frames=814`、pid@36s 存活、**8/8 RESULT=PASS**。

## 5. 解释器：rc2b pack 换入 → 首帧 PASS（判据分级）✅
- 换入（kit 未签 hap 重组）：`libcoreclr` ← 5,130,328/`e150558a…`；+`libclrinterpreter` 268,320/`3e4b4d10…`；`runtime-mode.txt=interp`；
  重签 **134,509,532 / `69bb864d…`** → install OK；pid 37773 存活 >40 s。
- **首帧分级 = PASS**：`jitfort rc=0`、invariant、managed started、**`canvas presented (2091x1324)` ×756**、0 新 cppcrash、
  0 SIGSEGV/SIGABRT/CoreLib 装载失败/切片竞争；**smaps 决定性**：进程映射 `libclrinterpreter.so`（4 段）、**无 `libclrjit.so`** → 确为解释器执行；
  截图 `interp/i1.jpeg` 见 UI（宿主 runtime-mode/interp 状态行不回传 hilog，以 smaps 补证）。

## 6. 抽验：抽屉/Back/多覆盖层/razor ✅
- 抽屉/Back（JIT 件）：外点开/关各 2 轮 FOREGROUND、Back 关抽屉 → 再 Back `#BACKGROUND`（d1–d5 截图/状态）。
- 多覆盖层 FULL：Add web C → 区 = B+C（slot0 改服 hybrid-c.html）；Activate A → A+C（slot1 服 hybrid-a.html）；
  Activate B → B+C（slot1 服 hybrid-b.html）（dump 区文本 + hilog web serve）。注：该实例按钮需“首击聚焦、次击生效”双击注入。
- razor 计数：本机按 kit #42 线重建 razor JIT hap（abc 356,480/`738d7e68…`、宿主 `08abe185…`；重签 134,156,912/`e0c12ce2…`）：
  装/启 OK、pid 12584；注入 "Blazor click" ×2 → **count 0→1→2**；`BLZ_DIAG`=3798、`BeginInvokeJS`=12/`BeginInvokeDotNet`=116、
  `blzProbe` eval=`ok`、`missing native code`/`interop-call`/`touch callback failed`=0。

## 7. 复用 / 未覆盖 / 不确定
- 复用：kit #42 发布/门禁证据（交互 578/580 floor 560、pixel PASS、宿主 151/151、preflight、CI 5/5 @`740980d`）为发布证据，未本地重跑。
- 未覆盖：AOT 路径（kit 内无 AOT hap，`aot-haps-v3-rc2` 独立资产未取）、套件/像素本地重跑、预签 hap 本地安装；
  razor 为 JIT 构建（非规范 AOT 线），判读同壳/同切片计数路径。
- 不确定：共享桌面窗口竞态（判定以 hilog/状态/dump/截图为准）；JIT 与解释器首帧截图同页（同一 FULL 演示）；设备末态 =
  `hellomauiapp`（interp，pid 37773）+ `hellomauirazor`（JIT razor，pid 12584）装/运行、`opendotnet` 装未运行；hilog 512K；AWAKE。
