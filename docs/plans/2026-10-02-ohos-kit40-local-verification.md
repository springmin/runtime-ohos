# kit #40 本机真机复测轮（KIT40-LOCAL-VERIFY，2026-10-02）

> 设备 HAD-W32（OpenHarmony-7.0.0.111 / API 26 / 2in1），hdc 无线 `127.0.0.1:35111`（在线），UDID `1BCE13C8…AEA0`；
> PowerManager 全程 **AWAKE**（未锁屏/无 10106102）。签名 = rc.2 线 preview.28 `sign-hap.sh` + ohos-sdk 26.0.0.18_2；
> tester-run = **v14**（140,197 B / `a174fcd0…`，自 release asset 595131362 独立下载复核）；证据 scratch
> `/data/storage/el2/base/tmp/opencode/kit40-local/`；未改 kit 资产；设备侧仅临时 `hilog -G 16M` → **已还原 512K**（19:16）。

## 1. 资产核验 ✅
- release API digest（dtk 392356147 / latest 392077166）与本地逐字节一致：tar **375,836,470 B / `31ab8732…`**（新 id 605346629/605373164）、
  sidecar **89 B / `9b051247…`**（内容 == tar 摘要；公开直连再拉一份同哈希）；全新解包；`SHA256SUMS` **17 项 / 1,517 B / `7667b6bd…`**、`sha256sum -c` **17/17 OK**。
- `verify-kit.sh`（69,522 B / `0b7dbfe9…`）`--expect-tree-digest e950de54…` → **tree OK；KIT OK（0 FAIL / 0 WARN）**，abc 期望 342160/24324；
  7 hap sha 与 RELEASE-VALUES 全等；抽查 hap 内 abc == `ffda66da…`、host == `384e552a…`。

## 2. Blazor 双 hap A/B ✅✅（kit #40 件重签）
- **默认（CSP）**：重签 **27,252,814 / `733601a2…`** → install OK；pid **53595** / nonce `00fca6fa-…`；`BLZ_BOOT`+`BLZ_RENDERED` 同 pid、`BLZ_ERROR`=0；
  受控点击 Home→counter→Click me：**count 0→1→2**（dumpLayout + 截图）。
- **-nocsp**：重签 **27,252,994 / `f86531eb…`**；pid **55658** / nonce `406efaa0-…`；双标记齐、0→1→2。

## 3. tester-run v14 `--blazor-probe`（tree 绑定 `e950de54…`）
- 512K 基线（默认）：`boot=no / rendered=yes`（nonce absent、failures=1）—— 本机 512K 环 ≈4–5 s 已知采集伪影（承 #34–#39），非应用失败。
- **16M 默认 PASS**（pid 60743、nonce present、failures=0）；**16M nocsp PASS**（pid 62843、failures=0）；`verify_kit=ok`；16M 已还原 512K（19:16）。

## 4. FIX-JSCALL 复核：AOT razor 计数往返 ✅（决定性）
- 件：`hello-maui-razor` AOT（本机 17:00 构建产物，源 **21,893,981 B / `6aa54c5d…`** == 交付方设备件；重签 21,893,906 / `e8b525cf…`）；
  宿主 `384e552a…`；壳 = 按 bundle 补丁的 razor 变体 **342,176 / `1af2e2e70b25`**（发布模板 342,160/`ffda66da`，差 16 B 名称补丁）。
- 首屏/组件：layout 齐 `hello-maui-razor` → host page loaded/shell bridge → `BlazorWebView component (.razor)` → `count: 0` → `Blazor click`（RSTree surface 2090×1324）。
- 注入点击 ×2 命中按钮：**count 0→1→2**（截图 r0-page/r1-click/r2-click2 + dumpLayout r0/r1/r2）；hilog `missing native code`=0、
  `interop-call`=0（桩探针消失，承 #39 的 `EnumConverter…missing native code` 与 `[probe]` 不再出现）、`BLZ_DIAG accepted=20/send=16`、
  `BeginInvokeJS`=12 / `BeginInvokeDotNet`=8、`payload-in-libs` + `managed app hello-maui-razor.dll started`；`touch callback failed`=0。

## 5. 抽屉 / Back 复核 ✅✅（AOT app，壳 342,160 / 宿主 384e552a）
- 件重签 **21,632,076 / `16796100…`**；窗口 rect `[578 344 2091 1394]`（共享桌面已移位；ham=rect+(30,100)、外点=rect+(1500,900)）。
- **FIX-DISMISS**：开抽屉 → 外点关闭 ×2 轮：每轮 `web cmd: suspend`×2 → `resume`；像素 open↔closed mean **0.1365**、closed↔closed **0.0001**（无残影）；
  `touch callback failed`=0；应用全程 `#FOREGROUND`（截图 d1–d4）。
- **FIX-BACKSIZE**：开抽屉 → Back → `web cmd: resume` + **仍 `#FOREGROUND`**；再 Back → **`#BACKGROUND`**（截图 d5/d6/d7 与状态一致）。

## 6. B2 / 深链 / payload 抽验 ✅
- **payload 原地直载**：`payload-in-libs: running from /data/storage/el1/bundle/entry/libs/arm64 (dotnet.zip not unpacked)` + `managed app hello-maui-app.dll started (UI shell)`。
- **深链**：冷启 `seq=1 delivered=0`（设计内）；运行中 `aa start -U 'app://media/probe?from=k40-hot'` → **`seq=3 delivered=1`**（同 pid 10180）。
- **B2**：Blazor 双变体标记/点击（§2）+ app 内页 `https://blazor.local/?blz_nonce=…` + `web sink: true`=1 / `web cmd: hybrid|blazor`=1/1。

## 7. 复用 / 未覆盖
- 复用：tester-run v14 `a174fcd0…`；kit #40 发布/门禁证据（套件 555/535、pixel PASS、导出 150/150、preflight）为本轮发布证据，本轮未重跑。
- 未覆盖：JIT 主包（kit 内 134 MB hap）本机未安装（承 #34–#39 已知限制，主判以 tester 机为准）；`NavigationOptions` 真实 Navigate 点击、
  多覆盖层、pinch element 坐标、tab 双页签/`--mode-matrix`/套件/像素本地重跑 → 承交付方证据或在途；razor 页内 `blzProbe` 为样例不定义（FIX-JSCALL §6）。
- 共享桌面窗口竞态（承 #35）：判定以 hilog/状态/截图/dumpLayout 为准。

> 设备末态：`hellomauiapp` pid 10180 `#BACKGROUND`、`hellomauirazor`（FIX-JSCALL 件）与 `opendotnet`（nocsp A/B 件）已装；hilog 512K 已还原（19:16）；PowerManager 末态 AWAKE。
