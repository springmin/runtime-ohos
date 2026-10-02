# payload 逐文件码签兼容默认化（DEVCOMPAT-DEFAULT，2026-10-02）

> 目标：默认构建的 hap 在 ≥7.0.0.111（enforcing）开箱可装。改动 = ohos-workload packs/**/targets +
> `OpenHarmonyStagePayloadLibs` + selftest + 打包文档；设备 HAD-W24 `7.0.0.111(SP3ENTC293E104R2P1log)`，
> hdc `127.0.0.1:35111`；证据 scratch `/data/storage/el2/base/tmp/opencode/devcompat-default/`。

## 1. 默认化实现
- `OpenHarmonyHapPayloadInLibsDeviceCompat` 默认 `false → true`（DEVCOMPAT-DEFAULT；7 个 preview pack 副本
  字节一致，targets `c44b3192…`、DLL `beb05577…`）：无扩展名 → `.so`（ELF）/`.bin`；恰 4096 B → +4 B；
  `dotnet.zip` 回退保原名原字节；marker（entries/payloadEntries/zipSha256）计数语义不变。
- 构建输出新增一行状态（`device compat: enabled … (N rewrite(s))`）；`false` 为逃生口：原名原字节 + 告警点名。

## 2. selftest / 断言
- 单元 `[tasks-tests] checks=123 failed=0 assert=True`（floor 95；新增状态行、规范化后 marker 计数、zip
  回退字节不变、逃生口不打印状态行等）。
- `selftest-hap-targets` T8（19 断言）：默认解析 `[true]`、`createdump.so`/`notes.bin`、4096→4100、嵌套
  `wwwroot` 保留、marker 计数 + zip 回退身份、逃生口告警/原名原字节、AOT/interp 预置 natives 不改动。
- 全 selftest 绿（隔离 worktree）：ridgraph 20 / packs 25 / hap-targets 68 / tasks 9 / repo-hygiene 25 /
  build-arkts 182 / commit-paths 29 / devloop 109 / make-mode-kit 82 / sign-for-device 209 / tester-run 683 /
  verify-kit 108（全部 failed=0）。

## 3. 本机端到端（enforcing 7.0.0.111，默认设置）
- hello-app JIT（默认）：2 rewrite（`createdump→createdump.so`、`Microsoft.OpenHarmony.dll` 4096→4100）→
  **install bundle successfully**；同源未重写对照包 → **9568393**（A/B 证明默认化即修复）。
- hello-maui-app JIT（`AssemblyName=hello-maui-app-jit`）：安装成功 → 原地直载（`dotnet.zip not unpacked`）+
  `managed app … started` → ~30 ms 崩 `SIGSEGV(SEGV_ACCERR)`，栈 `memcpy+312 ← libcoreclr ←
  coreclr_initialize+996 ← libhostpolicy ← libhostfxr ← libohoshost`（系统禁 JIT 预期；`b0a6087b…`）。
- hello-maui-app AOT：安装成功、pid 存活、`[maui] canvas presented (2090x1324)`、RSTree
  `ohos_dotnet_surface hasSurfaceBuffer=1`、截图有 Home/BlazorWebView 出画（`20cf66f7…`）。
- interp 换入：安装成功、`runtime-mode.txt=interp` + 两库换入；起步后崩 `SIGSEGV(SEGV_MAPERR)`
  （interp libcoreclr `coreclr_initialize+440`；rc.2 运行时/pack 兼容性，非打包；`b923695a…`）。
- `--with-blazor` 组件 hap 无 `libs/`/payload（222 条目 ArkTS-only）→ 规范化无输入；MAUI BlazorWebView 资产
  （`wwwroot/index.html`、`_framework/blazor.webview.js`）随 JIT/AOT payload 入 libs 并被断言保留。

## 4. 门禁 / 文档 / 提交
- 隔离 worktree preflight 全绿：repo gates + sh -n + markdownlint + 交互 **555/555 floor 535**
  （declared==printed、双 perf within）+ 像素 PASS；交互构建 0 error、IL2026/3050/3051=0；导出 **150/150**。
- 文档：ohos-workload 打包文档「Enforcing images」+ 任务注释；runtime-ohos JIT 策略文 DEVCOMPAT-DEFAULT 块。
- 提交：ohos-workload `12be59c`（已推 `master`）；runtime-ohos = JIT 策略文 + 本报告（本提交）。

## 5. 不确定项
- 4096 B 规则仍只本镜像实测；7.0.0.105 对重写包未复测（预计兼容）。
- 预置 shell abc 内嵌 bundle `com.example.hellomauiapp`：异 bundle hello-app 可装但启动 jscrash
  `Cannot find module 'ets/entryability/EntryAbility'`（既有壳绑定，与 DEVCOMPAT 无关）。
- 本机安装用到 rc2-fix preview.28 pack 本地刷新（旧文件备份在 `e2e/installed-pack-backup/`）；bundle/发布资产未重打。
