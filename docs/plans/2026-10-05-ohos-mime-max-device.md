# `.wasm` MIME 补正 + 动态槽 MAX=8 实测（SMALL-FIXES 建议 3，2026-10-05）

> 设备 HAD-W24 / OpenHarmony 7.0.0.111(SP3) / API26 / 2in1（UDID `1BCE13C8…AEA0`，hdc loopback）；全程按
> `mkdir .device-lock` 互斥（与本轮并行代理的 perf-finish 会话交错，见 §4 不确定项）。
> 交付件口径 = kit #47；本波未改 runtime/maui 切片 pin；证据在 scratch `smallfix-mime/`、`smallfix-max/`（未入库）。

## 1) `.wasm` MIME 补正（C3：消除 Blazor ArrayBuffer 回退）

- **实现（已核实）**：产品壳 `hybridMimeType('.wasm') -> application/wasm`（preview.22/23/24/28 均在）；独立
  rawfile 宿主机（`test/hello-blazorwasm/arkts-host`）同样映射。**产品壳无需改动**；宿主新增设备可判定探针：
  首个 `.wasm` 响应记 `BlazorWebHost ... wasm mime: <path> -> <mime>`，Emscripten 的
  `wasm streaming compile failed` / `falling back to ArrayBuffer` 控制台告警转发为 `wasm fallback:`；
  `pack-host.sh --bad-mime`（`BLZ_HOST_BAD_MIME=1`）生成错误 MIME 的负控件（仅改 staged 副本）。
- **真机正向**（host 默认，重签 `fb9b…`/29M；slim 216 文件）：hilog 原文
  `wasm mime: blazor/_framework/dotnet.native.ti998mcjzr.wasm -> application/wasm`、`marker: BLZ_BOOT`、
  `marker: BLZ_RENDERED`，**`wasm fallback:` = 0**（`device/mime-default-markers.txt`、`.jpeg`）。
  → `.wasm` 以 application/wasm 直供、Blazor WASM streaming 正常出画。
- **负控（部分）**：`--bad-mime` 件可装、`BLZ_BOOT` 到；但窗口内未完成渲染（`BLZ_RENDERED`=0）且未捕获到
  `wasm fallback:` 原文（该告警是否经 ArkWeb onConsole 投递未证）→ 只证明「错 MIME 会打断渲染」，负控通路未闭环。
- **门禁**：`test/maui-platform-verify` B2 新增 2 条断言（每包壳 + 宿主的 `.wasm -> application/wasm`、宿主
  `wasm mime:`/`wasm fallback:` 与 `--bad-mime` 源钉）→ 套件 **595/597 floor 577**；`build-arkts-shell
  --check-pack-abc` 的 ui 字面量表新增 `application/wasm`（headless 必须无）→ 通过；宿主 node 单测 43/43。

## 2) 动态槽 MAX=8 实测（E4）

- **实验件**：壳以临时补丁重建 `WEB_SLOT_MAX=8`（abc 370,240 / `e9a9a3d0`，与发布件 `4b439e83` 区分）；
  样例 probe8 = A–I **9 个 HybridWebView**（3×3 extraHost 自动挂载）+ 托管 `OHOS_OVERLAY_MAX=8`
  （`Program.Run` 首行注入；hap 22,479,192 / `fb47070a`，AOT，IL 0/0）。
- **协议面通过**：`[maui] web capacity: 8`；`web slot create: 2..7`（6 动态槽按需建）；第 9 个 claim 触发
  LRU 抢占 `hybrid overlay preempted: slot 0`（边界成立，与 5>4 轮同构）。
- **功能面不稳（关键）**：仅槽 0–3 曾 `hybrid assets … slot=N` 注册并 `web serve (slot N)`；槽 4–7 只有
  `web slot defer: N frame/hybrid`，4+ 分钟未 attach/未服务；a11y dump 最多 4 个 `rootWebArea`；运行中应用
  **重启过一次**（`managed app … started` ×2、pid 变更）。→ **N=8 不成立**；`WEB_SLOT_MAX=8` 的 >4 槽
  创建-挂载链在真机断裂（ArkWeb 组件上限或壳创建路径待定因）。
- **资源占用**：重启后稳态（约 4 覆盖层）RSS **238–252 MB**、线程 **69–70**；fd 经 hdc（uid 2000）不可读，
  8 槽并发态样本缺失 → 记「未取到」。
- **安全上限建议**：维持出厂 **MAX/HOT = 4/2**，**不要**提升默认到 8；先定位 >4 槽 create→attach 失败
  （候选：ArkWeb 并发 Web 组件上限、壳 ForEach 动态组件/控制器 attach 时序），再谈 5–8 的可用性。

## 3) 门禁/提交

- 切片套件 **595/597 floor 577**（+2 WASM-MIME）；`selftest-build-arkts-shell` **185/0**；
  `rawfile-path.test.mjs` **43/43**；`--check-pack-abc` 通过（ui 含 `application/wasm`、headless 无）。
- 改码两仓：ohos-workload（宿主 Index.ets / pack-host.sh / README / 打包文档 / 套件 Program.cs /
  build-arkts-shell.sh）与 runtime-ohos（本文件 + 预研文 + 平台限制清单状态）；按 `commit-paths.sh` 限定路径提交。

## 4) 不确定 / 未闭环

- 负控 `wasm fallback:` 转发未在真机出现（ArkWeb 是否投递 warn 级 console 未证）；补正的正向证据成立。
- 设备为共享 2in1（并行 perf-finish 会话）：锁交错期间应用可能被外部 force-stop（重启归因含此干扰），
  >4 槽断裂需独占窗复跑确认；fd/内存的 8 槽样本缺失。
- MAX=8 壳为 scratch 重建件，未并入发布 abc；产品默认仍 4/2（本波刻意不改默认）。
