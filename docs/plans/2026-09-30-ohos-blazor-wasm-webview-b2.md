# B2：MAUI WebView 承载 Blazor WASM（W9A 实装与设备状态）（2026-09-30）

**范围**：backlog B2（`2026-09-29-ohos-blazorwebview-feasibility.md` §3 缺口 1/2）+ 首个真机 spike。
**结论先行**：实现面（staging/壳 wasm 模式/BLZ 转发/演示 app/门禁）全部落地并通过离线门禁；本机 AOT hap
**可安装、可启动**，壳侧与 .NET 运行时均起（见 §4），但**未观察到托管入口到达 `Program.Run`**
（设备侧 `dotnet-status.txt` 只有宿主 probe 行，壳收不到任何 web 命令，无 BLZ 标记）——达到的里程碑 =
「payload 供给链 + 壳 wasm 服务面就绪、hap 可装可起」，未达「`BLZ_BOOT`+`BLZ_RENDERED`」；精确缺口见 §5。

## 1. 实现点（已提交）

| 面 | 提交（repo） | 内容 |
|---|---|---|
| 切片 API | maui `w9a-b2` **8993aa5c10** | `OpenHarmonyWebViewHandler.RegisterWasmSite(contentRoot="wasmsite")`：向壳发 `blazor` 注册 + `mode:"wasm"`（新 origin `https://blazorwasm.local/`），复用 `ResolveContentRoot` 安全守卫；`WasmSiteConfig` 入 source-gen JSON；net-openharmony PublicAPI 补 3 条 |
| 切片宿主 | maui `w9a-b2` **139f745d45** | AOT 启动序修复：`OpenHarmonyMauiAppHost` ctor 重新 `OpenHarmonyBridge.Attach()`（宿主先 dlopen AOT 库、后发布 launch context，模块初始化器缓存了空 Context —— 这是 B2 暴露的**既有缺口**：任何 AOT app 的 `Context.AppDir/FilesDir` 都为空，`WriteStatus`/内容根注册静默降级） |
| 壳 | workload `w9a-b2` **b790f5bc** | `registerBlazorAssets` 支持 `mode==="wasm"`：同 `<base>/<root>` 服务、不注入 Hybrid bootstrap、不自动 load（WebView Source 驱动唯一次加载）；Web `onConsole` 把 `BLZ_*` 转发 hilog `BlazorWebHost`（与 ArkTS 宿主同 grep 名）；诊断：web sink 结果、非 frame web 命令、前 3 次拦截 serve、托管 status 文件尾（壳与 app 同沙箱可读）；abc 314,780 B / `096f99b1`（ui），provenance + preview.28 同步，headless 20,916 不变 |
| staging | workload **44996d3** | `_OpenHarmonyStageWasmSite`（`OpenHarmonyWasmSiteDir` → `<PublishDir>/wasmsite`，fail-fast index.html + safe root）接入 `_OpenHarmonyStageHap`；7 个 pack 保持字节一致；打包文档新增 §B2 |
| 演示 app | workload **6874639** | `test/hello-maui-wasm/`：AOT 变体 + `WASM_ABC`（bundle 专属 abc）+ `WASM_SITE`；启动 breadcrumb + 失败页（经壳 web overlay 可读） |
| 套件 | workload **dac714e** | +3 检查（managed API / wire+壳 wasm 模式+宿主重挂 / staging+演示），**516/516 floor 496** |
| kit 门禁 | workload **d2a51cd** | `verify-kit` EXPECT_ABC 314,780；`selftest-verify-kit` 108/0；`selftest-hap-targets` 50/0（1 skip=设备项） |

## 2. 发布/构建产物（本机 scratch，`/data/storage/el2/base/tmp/opencode/w9a/`）

- 站点：`run-smoke.sh`（rc.2）→ `site/publish/wwwroot` 642 文件 / 52 MB（204 wasm payload；含 `BLZ_BOOT`/`BLZ_RENDERED` 探针页）。
- hap：AOT（UI 壳 + `wasmsite/` staged）**100,296,932 B 未签 / 104,983,712 B 已签**，`libhello-maui-wasm.so` 16.8 MB，
  payload-in-libs 642 文件 47 MB + `dotnet.zip` 回退；`ets/modules.abc` = bundle 专属 313,380 B。
- 切片门禁：0 error / 0 IL2026/3050/3051；套件 516/516。

## 3. 设备现象（kit 证据见 scratch `device/`）

- 安装/启动成功（自签 `com.example.hellomauiwasm`；`snapshot_display` 需 `.jpeg` 后缀、本机桌面可被人工关窗退出码 0）。
- 壳：`[maui] web sink: true` 注册成功（`aboutToAppear`）；payload 解包（zip 回退，因 AOT payload-in-libs 无 `.dll`，
  `findLibsPayloadDir` 探针不命中——记录为附带缺口）；`managed app hello-maui-wasm.dll started`。
- 进程：67 线程含 `OS_GC_Thread`×5/`ThreadPool*` —— **AOT .NET 运行时已起**（dlopen 初始化）。
- **未出现**：任何 `[maui] web cmd: <op>`、托管侧写出的 `dotnet-status.txt` 行（壳轮询只读到宿主 probe 行
  `OHOS_DOTNET probe: 1=22 …`）、`BlazorWebHost` 标记。最后一轮已在 `AotEntryPoint.Main` 用**绕开 Context** 的
  breadcrumb（从 `OHOS_HOST_APP_CONTEXT` 解析 filesDir 直写 status 文件）验证：该行也未出现。

## 4. 精确缺口（下一步）

1. **托管入口不可达/不可观测**（本机 AOT hap）：`.NET` 运行时线程在（库已 dlopen），但 `openharmony_app_main`
   的任何托管 breadcrumb 都不落盘（直写绕过 Context 的探针也不落），且无 web 命令到壳。下一次最小实验二选一：
   （a）在宿主 `OhosHostTryRunAotApp`/bridge 的 aot 分支把 `run_app entering/exited` 的 stderr 路由到 hilog（或加
   `OH_LOG_INFO`），判定「入口未调用」vs「入口调用后静默失败」；（b）用一个只导出 `openharmony_app_main` 并
   `write(2)` 的最小 AOT .so 对比——若同样不出标记，则问题在宿主 AOT 桥；否则在本 app 的托管启动。
   注：宿主 probe 行证明 status 文件可写、start_app 已执行；`OhosHostResolveAppDir`/AOT 库路径依赖 `lib<stem>.so`
   与 app.json 的 `.dll` 名，当前文件名映射链（`hello-maui-wasm.dll` → `libhello-maui-wasm.so`）未获日志确认。
2. **AOT payload-in-libs 探针**：`findLibsPayloadDir` 要求 `<libs>/<assembly>.dll`，AOT 只有 `lib<stem>.so` → 总走 zip 回退；
   修法：探针接受 `lib<stem>.so`（或 marker 记录 AOT 形态）。
3. 上述修后重跑 §3 的四条管线（register→load→serve→BLZ），预期即可到 `BLZ_BOOT`/`BLZ_RENDERED`。

## 5. 备注

- 设备为共享桌面（另有会话在用；窗口曾被人为关闭），截图证据不稳定；所有结论以 hilog + RSTree + 线程表为准。
- 一次 `dotnet publish` 曾挂在 CLI 内部自旋（无 IO、92% CPU、25 min），`kill -9` 后同命令 3 分钟成功——环境噪声，非代码问题。
