# kit #39 本机真机复测轮（KIT39-LOCAL-VERIFY，2026-10-02）

> 设备 HAD-W32（OpenHarmony-7.0.0.111 / API 26 / 2in1），hdc 无线 `127.0.0.1:35111`（在线），UDID `1BCE13C8…AEA0`；
> PowerManager 全程 **AWAKE**（未锁屏/无 10106102）。签名 = rc.2 线 preview.28 `sign-hap.sh` + ohos-sdk 26.0.0.18_2；
> tester-run = **v14**（140,197 B / `a174fcd0…`，自 release asset 595131362 独立下载复核）；证据 scratch
> `/data/storage/el2/base/tmp/opencode/kit39-local/`；未改 kit 资产；设备侧仅临时 `hilog -G 16M` → **已还原 512K**（16:25）。

## 1. 资产核验 ✅
- release API digest 与本地逐字节一致（dtk 392356147 / latest 392077166）：tar **375,765,521 B / `e95eed49…`**、
  sidecar **89 B / `e5fc82de…`**（内容 == tar 摘要）；全新解包；`SHA256SUMS` **17 项 / 1,517 B / `f7871fa8…`**、`sha256sum -c` **17/17 OK**。
- `verify-kit.sh`（69,522 B / `0b7dbfe9…`）`--expect-tree-digest 932e7955…` → **tree OK；KIT OK（无 FAIL/WARN）**，abc 期望 342160/24324；
  抽查包内 5 MAUI hap：abc == `ffda66da…`、host == `384e552a…`（与发布值一致）。

## 2. Blazor 双 hap A/B ✅✅（kit #39 新件重签）
- **默认（CSP）**：重签 **27,252,814 / `755dc8d7…`** → install OK；pid **52519** / nonce `89d4c606-…`；`BLZ_BOOT`+`BLZ_RENDERED` 同 pid、`BLZ_ERROR`=0；受控点击 Home→counter→Click me：**count 0→1→2**（dumpLayout）。
- **-nocsp**：重签 **27,252,997 / `eb00fb6f…`**；pid **53815** / nonce `d889410f-…`；双标记齐、0→1→2。→ CSP 非瓶颈（承 #33–#38）。

## 3. tester-run v14 `--blazor-probe`（tree 绑定 `932e7955…`）
- 512K 基线（默认）：`boot=no / rendered=yes`（nonce absent、failures=1）—— 本机 512K 环 ≈4–5 s 已知采集伪影（承 #34–#38），非应用失败。
- **16M 默认 PASS**（pid 56738、nonce present、failures=0）；**16M nocsp PASS**（pid 58770、failures=0）；`verify_kit=ok`；16M 已还原 512K。

## 4. AOT/razor（`.razor` 挂载 + 首屏）✅ / 计数在途
- 件：`hello-maui-razor` AOT（本机重签 **21,746,446 / `0560431d…`**）；宿主 **384e552a4d03**；壳 = 发布壳源（`b083ca82` 与 reg-kit39 同源）
  按 bundle 打补丁的 razor 变体 **342,176 / `1af2e2e70b25`**（发布模板为 342,160/`ffda66da`，差 16 B = per-bundle 补丁/名长）。
- 首屏/组件 ✅：layout 文本齐 `hello-maui-razor` → `host page loaded; shell bridge: window.external=object, sendMessage=function, receiveMessage=function, Blazor=object`
  → **"BlazorWebView component (.razor)"** + `count: 0` + `Blazor click`；hilog `[maui] blazor connect/start`、`BLZ_DIAG message accepted→dispatch→enqueue→run→send`；
  `payload-in-libs: running from …/libs/arm64 (dotnet.zip not unpacked)`；RSTree `RosenWeb` 控件框 **2026×600**（非整窗，FIX-BACKSIZE 尺寸生效）。
- **注入点击计数（在途，决定性证据）**：两次 `uitest uiInput click` 命中原生 BUTTON（`BLZ_DIAG doc-click trusted=true` + `interop-call DispatchEventAsync`），
  但 count 保持 0；页内 probe `NotSupportedException: EnumConverter\`1[JSCallResultType] missing native code` —— 与 handoff「计数往返在途」一致，**不判失败**。
- 旁证：发布壳 abc 直塞 zip 后启动报 `ReferenceError: Cannot find module 'ets/entryability/EntryAbility'`（发布 abc 内嵌 `com.example.hellomauiapp`）→
  换壳必须走构建期补丁；本轮用原始 razor 件，仓库内该 hap 已逐字节复原。

## 5. 抽屉 / Back 复核 ✅✅（AOT app，壳 342,160 / 宿主 384e552a）
- 窗口 rect `[140 140 2090 1394]`（共享桌面已移位；坐标按 rect 动态计算 ham=rect+(30,100)）。
- **FIX-DISMISS**：开抽屉 → 外点关闭 ×2 轮：每轮 `web cmd: suspend`×2 → `resume`；像素 open↔closed mean **0.1363**、closed↔closed **0.0000**（无残影）；
  `touch callback failed`=0；应用全程 `#FOREGROUND`（截图 e1/e2、e3/e4）。
- **FIX-BACKSIZE**：开抽屉 → Back → `web cmd: resume` + **仍 `#FOREGROUND`**；再 Back → **`#BACKGROUND`**（截图 e5/e6/e7 与状态一致）。

## 6. B2 / 深链 / payload 抽验 ✅
- **payload 原地直载**：`payload-in-libs: running from /data/storage/el1/bundle/entry/libs/arm64 (dotnet.zip not unpacked)` + `managed app hello-maui-app.dll started (UI shell)`。
- **深链**：冷启 `seq=1 delivered=0`（设计内）；运行中 `aa start -U 'app://media/probe?from=k39-hot'` → **`seq=3 delivered=1`**（同 pid 13057）。
- **B2**：Blazor 双变体标记/点击（§2）+ app 内页 `https://blazor.local/?blz_nonce=…`（layout）+ `web sink: true` / `web cmd: hybrid|blazor`。

## 7. 复用 / 未覆盖
- 复用：tester-run v14 `a174fcd0…`；kit #39 发布/门禁证据（套件 554/534、pixel PASS、导出 150/150、abc/host 四包一致）为本轮发布证据，本轮未重跑。
- 未覆盖：JIT 主包本机仍装不上（承 #34–#38，主判以 tester 机为准）；计数往返 >0、多覆盖层、pinch element 坐标、tab 双页签/`--mode-matrix`/套件/像素本地重跑 → 承交付方证据或在途。
- 共享桌面窗口竞态（承 #35）：判定以 hilog/状态/截图/dumpLayout 为准。

> 设备末态：`hellomauiapp`（AOT 复核件）pid 13057 `#BACKGROUND`、`hellomauirazor`（razor 件）与 `opendotnet`（nocsp 变体）已装；hilog 512K 已还原（16:25）。
