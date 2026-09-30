# kit #34 本机真机直测（KIT34-LOCAL-VERIFY，2026-09-30）

> 设备：HAD-W32（`HAD-W24 7.0.0.111(SP3ENTC293E104R2P1log)`、API 26、arm64-v8a、UDID `1BCE13C8…AEA0`）；
> hdc 无线 `127.0.0.1:35111`；签名 = rc.2 线 SDK `sign-hap.sh`（`.dotnet.rc2-fix` preview.28 模板 +
> `ohos-sdk 26.0.0.18_2/toolchains/lib`，本机 UDID）；tester-run **v14**（140,197 B / `a174fcd0…`，取自本机
> 镜像副本，sha 与 release「零变更」资产逐字一致）。证据 scratch = `/data/storage/el2/base/tmp/opencode/kit34-local/`
> （`kit/ blazor/ tester-run/ maui/`），本文只归档结论。未改 kit 资产；设备侧临时调过 hilog 缓冲（16M→已还原 512K）。
> 背景：kit #34 = rc.2 基线 + W7/W8 六件 + FIX-SHELL/T12/T14/N1（`2026-09-30-ohos-tester-handoff-kit34.md`）。

## 1. 资产核验 ✅
- 本地 tar 375,181,367 B / sha256 **`55834aeb…`**（== release 期望）；sidecar 89 B / **`c03ea23d…`**（==）。
- 解包 `verify-kit.sh`（69,522 B / `dcd81f33…`）→ **KIT OK，0 FAIL（exit 0）**；`SHA256SUMS` 17/17 OK；
  `--expect-tree-digest d08de3ec…` OK（解压内容与发布方绑定一致）。1 条“★ 警告”为包内安装提示（与交付方自检日志逐字一致）。
- 7 hap 齐：Blazor 默认 27,216,958 / `8e407504…`、nocsp 27,216,659 / `68606606…`；MAUI 未签
  131,304,609 / `f0def954…`（预签 4 变体随 SHA256SUMS 校验，未逐装）。

## 2. Blazor 双 hap A/B ✅✅（承 #33 判定树）
- 各重签一次（本机 UDID）→ `bm uninstall` 后 `hdc install -r` ×2 均 `install bundle successfully`；
  `aa start -b com.example.opendotnet -a EntryAbility` 均成功（新进程 pid 30203/31182/33647/33758…）。
- **默认（CSP）**：流式 hilog 同 pid 同 nonce `[blz:f5dfff8b-…]`：`BLZ_BOOT` → `BLZ_RENDERED`
  （另次运行 `77c292cd-…` 亦双标记）；截图出画且落在 **Counter** 页（count=1，WASM 交互生效）。
- **-nocsp**：同 pid 同 nonce `[blz:52116776-…]` 双标记；首屏截图 “Hello from Blazor WebAssembly”
  （Runtime **.NET 11.0.0-rc.2.26459.117** / OS: Browser）。两变体均无 `BLZ_ERROR`。
- → **默认 ✅ = CSP 非瓶颈**（与 #33 同结论；组件为 rc.2 重建件）。

## 3. tester-run v14 `--blazor-probe` ✅（1 次本机噪声 + 2 次全绿）
- 默认 512K 缓冲：`blazor_install=ok / rendered=yes / boot=no / nonce=absent`，failures=1（sleep 4 与 2 各一轮）；
  同轮**流式** hilog 双标记齐全 → 采集伪影，非渲染缺陷。
- 根因（承 #33 本机结论）：本机桌面日志噪声大，app+core 512K ≈ 4–5 s 保留，`hilog -x` 在 4 s 后已把 BOOT/nonce 挤出。
  **处置**：临时 `hilog -G 16M -t app,core` 重跑 → 两变体全绿：默认 `boot=yes/rendered=yes/nonce=present/
  pid=54570/failures=0`（nonce `af2fa30e-…`），nocsp 同（pid=56011，nonce `5a6d23ae-…`）；跑完已还原 512K。
- 归档：`tester-run/blazor-16m-20260930-113312.tar.gz`、`…-nocsp-20260930-113357.tar.gz`（512K 失败轮留作对照）。

## 4. MAUI：JIT ⛔ / AOT ✅
- **JIT**：kit 未签 hap 本机 UDID 重签 → `hdc install -r` 报 **`9568393 verify code signature failed`**
  （payload-in-libs 被本机 ≥7.0.0.111 镜像拒）——与预期一致（非 kit 缺陷；JIT 真机判定以 tester 机为准）。
  **根因更正（2026-09-30）**：拒装与“非 ELF”无关，系（a）无扩展名文件 `createdump` 不在 HAP 码签块、
  （b）恰好 4096 B 的 `Microsoft.OpenHarmony.dll` fs-verity 使能失败；对策见
  `2026-09-30-ohos-jit-payload-install-policy.md`。
- **AOT v3**：release 并列资产 `aot-haps-v3`（17,537,186 / `004ba03c…` 已核）未签件本机重签（20,624,093 B）
  → 安装/启动成功（pid 51951）；**RSTree `ohos_dotnet_surfaceSurface` `hasSurfaceBuffer:1`**、`Visible:1`、
  Bounds 2090×1324；截图 = 渐变主体窗口出画（复核 rc.2 前证）。hap 深核：UI 壳 abc **289,992 / `e005f236…`**、
  `main_pages=pages/Index`、`runtime-mode.txt=aot`、`libhello-maui-app.so` 17,709,840（= v3 契约）。
- 注：AOT 安装顶替 kit 主包（同 bundle）；kit JIT 主包未驻留设备。

## 5. 与 kit #33 对照
- #33（tar 218,138,546 / `38e4d57a…`，树 `064cb001…`）本机已验 Blazor A/B、探针大缓冲全绿、JIT 同限；
  #34（375,181,367 / `55834aeb…`，树 `d08de3ec…`）= rc.2 重建（MAUI hap ~76→133.8 MB）+ W7/W8，本轮复测：
  Blazor 双件（rc.2 重建）仍双标记过、探针两变体全绿（同缓冲口径）、AOT 出画（#33 时 v3 未发布，属新增闭环）。
- 未见 #33 判定点回归；差异集中在资产体积/哈希与 rc.2 运行时自述（WASM `.NET 11.0.0-rc.2.26459.117`）。
- 门禁数字（套件 513/floor 493、导出 145/145、像素 PASS）为交付方证据，本机不重跑。

## 6. 本机 vs tester 机差异（本轮实测）
- hilog：本机 512K 缓冲 ≈4–5 s（探针 4 s 窗口竞态，需 16M 口径或流式）；tester 机噪声低、4 s 窗口可用。
- 本机无 `libhilog_ndk.z.so` → 宿主 `aot=`/`[maui]` 行不可见（以 RSTree/截图为准）；tester 机可见。
- 本机镜像（7.0.0.111 系）拒 payload-in-libs → JIT 主包装不上（9568393）、无 JIT 崩溃证据；tester 机可装 JIT。
- 截图后缀：本机 `snapshot_display` 要求 `.jpeg`（runbook 的 `.png` 报 invalid）。
- 本机无地图/系统装饰入口：T14/T15/T16/N4/N5/N6、TabbedPage/W5、`--a11y-probe` 等人工项未测（需 tester 机）。

## 7. 遗留
- ① tester-run v14 探针建议带“512K 缓冲本机”提示/自适应（或先 `--capture` 后判），避免误报（承 #33 遗留②）。
- ② runbook 补 `.jpeg` 截图后缀注记。③ AOT 与 JIT 主包互斥（同 bundle），回 JIT 需重装 kit hap。
- 未改 kit 资产；全部操作 = 重签 / 安装 / 启动 / 日志 / 截图（设备侧仅临时日志缓冲调整，已还原）。
