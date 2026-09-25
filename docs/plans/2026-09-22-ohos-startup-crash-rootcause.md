# 启动崩溃根因：四个独立阻塞（入口 record / abc 版本 / host undefined / napi 注册名；exit 254 与黑屏）

> 2026-09-22 记录测试方真机反馈的完整证据链与结论（一手材料：《OpenHarmony MAUI device-test-kit 真机验证反馈报告》）；
> §5d/§5e 为 2026-09-23 kit #14 真机进展（里程碑 + 第四个阻塞，一手材料：《kit #14 真机验证结论》）。
> **结论先说**：
> 1. 安装报 `9568257 fail to verify pkcs7 file` 是包内**自签名 hap 的预期拒绝** —— 设备不信任我方调试签名；
>    必须重签 `hello-maui-app-unsigned.hap`（唯一可重签安装的变体）或用发布方预签包，与启动崩溃无关。
> 2. 重签安装成功后启动即崩（约 1 秒 / `exit 254` / `JsError`）的根因是 **ArkTS 壳 `modules.abc` 缺少入口模块
>    record 索引**（记录名与 `module.json` 的 `srcEntry` 不匹配），**不是**宿主缺 `libc++_shared.so`（H1），
>    也不是宿主 dlopen/入口（H2）。修复：PA1 重建壳 abc（`ohos-workload/scripts/build-arkts-shell.sh`）后重出 kit —— 已随 kit #10 落地并被测试方真机确认。
> 3. 修复入口 record 后的同一轮真机复测暴露第二个独立阻塞：**壳 abc 字节码版本 `24.0.0.0` 超出设备的 ark runtime
>    上限 `13.0.1.0`**（hilog `export objects of native so is undefined` / `Cannot read property … of undefined`），
>    已随 kit #11（`compatibleSdkVersion 18`）修复。前两个根因的收尾见 §5b。
> 4. kit #11 真机复测确认 abc 修复生效（`[maui]` 日志出现、崩溃推进到页面/渲染阶段），同时暴露**第三个独立阻塞**：
>    宿主 `.so` 加载失败使壳 `host` 为 undefined，此前唯一未加守卫的 `host.registerXComponent()` 抛 TypeError
>    （`exit 254`）。修复随 kit #12（`ohos-workload 7e71c39` + 壳归档 `2411a8e`）：宿主不在链接期依赖
>    `libhostfxr`（全部经既有 dlopen/dlsym 表）、`build-host.sh` 增加构建期 DT_NEEDED 审计、壳把每个
>    `host.<api>` 调用纳入守卫。见 §5c。
> 5. **里程碑（kit #14，2026-09-23）**：应用首次**正常启动并稳定存活**（60 s+，主进程 + `:gpu` 进程），
>    **零崩溃日志**（无 `TypeError` / `JsError` / `exit 254`）—— 前三个根因（入口 record、abc `13.0.1.0`、
>    运行时原生库随 `libs/arm64-v8a/`，对应本文 §5b/§5c）均已在真机确认修复；但页面**黑屏**（进程不退出）。
>    第四个独立阻塞：宿主 napi 注册名 `nm_modname = "openharmonyhost"` 与 `useNormalizedOHMUrl=false` 下
>    abc 的 import 记录名 `@app:com.example.hellomauiapp/entry/openharmonyhost` 不匹配 → 设备按记录名
>    加载 native 模块失败 → 宿主 exports 为空 → XComponent 表面从未交给 .NET → 黑屏；RH1 修复
>    （别名注册覆盖两种约定 + 标准化壳构建，保留入口 record 修复所用的 bundle 名）**进行中（in flight）**。
>    见 §5d/§5e。
>
> **2026-09-24 状态**：四个启动阻塞均已在 kit #10/#11/#12/#16（+ #17 `libIsolation` repack）修复；当前发布 = **kit #26**（P2-INTEROP 全量 `LibraryImport` hosting + TASK-MIG 打包任务程序集化 + PLAT-GAP 消费方缺省化；`tester-run.sh` v8；自 #21 起含 headless 变体 abc `13.0.1.0` 修复；#24 起含 payload-in-libs + 显式 W^X=0 + exec-memory 探针；#25 含权限链/Share-Scan/AOT），§5d/§5e 的「进行中」均为当时快照。设备侧诊断（app-lib 键、别名注册行、首帧、execmem）已并入 `tester-run.sh`，见 `docs/plans/2026-09-21-ohos-device-crash-diagnostics.md` §2.4–§2.6。
> **2026-09-24 设备证据修正（新增；2026-09-26 更新至 kit #26）**：当前发布已前进到 **kit #26**（#22 设备里程碑回灌（宿主按需 dlsym、`resources.index`、ZIP offset/mkdir、DevEco 工程布局）→ #23 工具刷新 → #24 payload-in-libs + 显式 W^X=0 + exec-memory 探针 → #25 权限链 + Share/Scan 探测 + AOT 启动路径 → #26 LibraryImport hosting 重建 + pack 任务程序集 + PLAT-GAP 缺省化；见 `2026-09-24-ohos-device-milestone.md`、`2026-09-25-ohos-tester-handoff-kit25.md`、`2026-09-26-ohos-tester-handoff-kit26.md` 与 `2026-09-22-ohos-release-manifest.md`）；旧 #4（libIsolation/napi path）降级为「**无害加固、非关键**」——真实直接链 5 项、回灌映射与边界见 §5f。

## 0. 一手材料与验证环境

- 反馈原文（2026-09-22）：`ohos-device-test-kit-feedback.md`（本机 `~/Download/com.haitai.htbrowser/`）；反馈对象 springmin。
- 测试包：GitHub release `springmin/sdk-ohos` tag `device-test-kit`（commit `38a53d7`）。
- 设备：HUAWEI MateBook Pro（HAD-W24），HarmonyOS 7.0.0.105（SP7ENTC293E102R2P1log），`const.ohos.apiversion=26`，arm64-v8a。
- UDID：`60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`；hdc 3.2.0c（DevEco SDK toolchains）。
- 测试方签名：PKI 在线签名（调试证书绑定上述 UDID；bundleName `com.example.hellomauiapp`；profile type=debug；有效期 2026-09-22 ~ 2027-07-21）。
- 交付包校验：`device-test-kit.tar.gz` sha256 与外层 sidecar 一致 ✅；解压后
  `verify-kit.sh --expect-tree-digest e0eea6719c12334285910027cf9dbe0eb0163544f30727f3f55b1057ea64c660` 全部通过 ✅
  （即崩溃与传输/解压损坏无关）。

## 1. 现象（两步）

### 1.1 包内 hap 安装：`9568257`（预期，与崩溃无关）

```
failed to install bundle. code:9568257 error: fail to verify pkcs7 file
```

4 个默认 hap（默认 / permissions / api20 / api20-permissions）与 P1–P4 探针包均如此。测试方拆包检查未发现
可用签名块（无 `HapSignInfo`、`signature/` 目录、`profile.p7b`）；交付方口径是"这 4 个 hap 用我方调试材料自
签名（`sign-profile`/`sign-app` + `verify-app` 只证明**包内自洽**，不等于设备信任）"。两种描述指向同一结论：
**真机以 `9568257`（profile/绑定不通过时为 `9568344`）拒绝属预期**，必须重签或用预签包，不需要把它当崩溃线索。

### 1.2 重签后安装成功，启动即退（真实崩溃）

```
ReferenceError: Cannot find module 'ets/entryability/EntryAbility' , which is application Entry Point
```

hilog 关键行：

```
AppKit: com.example.hellomauiapp is about to exit due to RuntimeError
AppKit: Error type:ReferenceError
AppKit: Error message:Cannot find module 'ets/entryability/EntryAbility' , which is application Entry Point
AppKit: ... ModulePathHelper::ConcatFileNameWithMerge ... HostResolveImportedModuleWithMerge
appspawn: com.example.hellomauiapp with pid xxxx exit with code:254
```

退出耗时约 1 秒；`exit 254`。

## 2. 证据链

### 2.1 基线事实（HAP 内容与声明）

- HAP 内 `ets/` 只有单个文件 `ets/modules.abc`（159,224 字节，kit 版本）。
- `module.json`：`module.mainElement="EntryAbility"`；`module.abilities[0].srcEntry="./ets/entryability/EntryAbility.ets"`；
  `compileMode="esmodule"`；`deviceTypes=["phone","tablet","2in1"]`。
- abc 字符串表里的模块记录名：
  - 短路径 `entry/src/main/ets/entryability/EntryAbility`（**带 `entry/` 前缀**）；
  - 长名 `entry|entry|1.0.0|src/main/ets/entryability/EntryAbility.ts`（**带 `entry|entry|1.0.0|src/main/` 前缀**）；
  - 该名字在 abc 中仅出现 **1~2 处**。

### 2.2 E1–E5 真机实验（全部实测，非推断）

| 实验 | 修改 | 结果 |
|---|---|---|
| E1 | 复制 `modules.abc` → `ets/entryability/EntryAbility.abc` | 仍报 `Cannot find module 'ets/entryability/EntryAbility'` |
| E2 | `srcEntry` → `./src/main/ets/entryability/EntryAbility.ets` | 报 `Cannot find module 'src/main/ets/entryability/EntryAbility'`（系统按 srcEntry 去 `./` 后查模块） |
| E3 | `srcEntry` → `./entry\|entry\|1.0.0\|src/main/ets/entryability/EntryAbility.ets` | 报 `Cannot find module 'entry\|entry\|1.0.0\|src/main/ets/entryability/EntryAbility'`（原样查） |
| E4 | 用 `es2abc --module --merge-abc --extension ts --record-name ets/entryability/EntryAbility --target-api-version 26` 编译最小壳替换 | **安装成功、模块名解析通过**（错误变为 `Cannot find module '@kit.AbilityKit' imported from 'ets/entryability/EntryAbility'`） |
| E5 | 在 E4 基础上把源码 import 改为 `@ohos.app.ability.UIAbility` 等点号老式写法 | 报 `Cannot find module '@ohos.app.ability.UIAbility'`（设备只认 DevEco 编译器转换后的 `@ohos:app.ability.*` 冒号格式） |

结论（E4 为关键证据）：**模块名 `ets/entryability/EntryAbility` 正确时设备能解析入口**；kit 的 abc 因模块
记录名/索引与 `srcEntry` 不匹配而入口定位失败。

### 2.3 与可运行工程 `cc-switch-ohos` 的对照（决定性证据）

测试方本机有一个可正常构建、安装、运行的鸿蒙工程 `cc-switch-ohos`（Tauri 应用，
`entry/build/default/intermediates/loader_out/default/ets/modules.abc`）：

- 相同点：记录名同样带 `entry|entry|1.0.0|src/main/…` 前缀；`srcEntry` 同样为 `./ets/entryability/EntryAbility.ets`；
  import 同样是 `@ohos:app.ability.*` 冒号格式（DevEco 编译产物）。
- 关键差异：

```
cc-switch（可运行）abc:
  'entry/src/main/ets/entryability/EntryAbility' 出现 37 次
  含 &entry/src/main/ets/entryability/EntryAbility&.#<唯一ID># 形式的完整 record 索引/引用条目
  本机 SDK ark_disasm 可正常反汇编（输出 286KB）

kit（崩溃）abc:
  'entry/src/main/ets/entryability/EntryAbility' 出现 1~2 次
  无 record 索引条目
  本机 SDK ark_disasm 报：abc file version 24.0.0.0, Maximum supported abc file version is 13.0.1.0
```

即：**kit 的 `modules.abc` 缺少设备运行时所需的 record 索引/映射结构**。`ark_disasm` 的版本差（kit 产物
24.0.0.0，本机 SDK 工具上限 13.0.1.0；本机为 OpenHarmony 6.0.2 / API 22）当时被判为工具侧限制；
**2026-09-22 更正**：入口 record 修复后的真机复测表明该版本差同时是**第二个独立阻塞**（设备 ark runtime
拒收高于 `13.0.1.0` 的 abc），见 §5b 与 `2026-09-22-ohos-arkts-abc-version-history.md`。

### 2.4 官方检索佐证（华为）

- 华为开发者论坛存在**一字不差的同类报错**：`Cannot execute module buffer file 'arkuix/ets/entryability/EntryAbility.abc'`
  + `Cannot find module '...' , which is application Entry Point`；官方答复为：把工程级 `build-profile.json5` 的
  **`useNormalizedOHMUrl` 设为 `false`** 试试。
- 华为 es2abc FAQ：`useNormalizedOHMUrl=true` 时工具链会对模块 URL 做标准化处理；HAR 中 Record 与工程实际依赖
  不一致会触发冲突。
- 华为 arkts-module-faq：`cannot find record` 类报错需检查编译产物（`filesInfo.txt`）与报错路径是否一致。

## 3. 根因

kit 打包时 ArkTS 壳的编译/归档配置（疑似 `useNormalizedOHMUrl=true` 或等价的标准化选项，也可能是
es2abc/hvigor 参数未对齐 `srcEntry`）导致：

1. `modules.abc` 内模块记录名带 `entry|entry|1.0.0|src/main/…` 前缀，与 `module.json` 的
   `srcEntry: ./ets/entryability/EntryAbility.ets` 不匹配；
2. abc 缺少设备运行时解析所需的 record 索引条目。

设备 ArkTS 运行时按 `srcEntry` 无法定位入口模块记录 → 应用启动即 `ReferenceError` 退出（`exit 254`）。

> 测试方原话保留：本机 `cc-switch` 的 `useNormalizedOHMUrl` 亦为 `true` 且可运行，故该配置是否为**唯一**根因
> 请以构建环境实测为准；**更确定的事实是 kit 的 abc 缺少 record 索引结构**。

## 4. 对既有假设的影响（H1/H2）

- **H1（宿主缺 `libc++_shared.so` → dlopen 失败）与 H2（宿主 dlopen / 入口 / dlsym）是硬化方向，不是本次崩溃
  的原因**：本次崩溃发生在 ArkTS 壳入口解析阶段，宿主 `.so` 尚未被加载。
- kit #5 起的随包 `libs/arm64-v8a/libc++_shared.so`（SDK ElfSigner 重签）、壳对非核心 Kit 的按需 `import()`、
  宿主 8 条 hilog 诊断均保留有效，但都不能修复入口 record 缺陷。
- 判读顺序调整：**先看退出错误**；命中本 ReferenceError 的 kit（截至 PA1 重建前）不需要再跑 P1–P4。P1–P4 阶梯
  仍适用于 dlopen / 缺库 / 宿主入口 / .NET 运行时类崩溃。

## 5. 修复（PA1；已完成，见 §5b）与验证计划

- 修复：`ohos-workload/scripts/build-arkts-shell.sh`（PA1，另一 agent）——让壳 abc 带完整、与 `srcEntry` 匹配的
  入口 record 索引（含试行 `useNormalizedOHMUrl=false` / 对齐 es2abc+hvigor 归档参数）。
- 出包：重建 `dist/ets/modules.abc` → `scripts/make-device-test-kit.sh` 重出 kit（本版同时新增 `签名说明.txt`，
  并让 `verify-kit.sh` 打印自签名警告）。
- 验证（设备侧）：重签 `hello-maui-app-unsigned.hap`（或按 UDID 预签）后安装启动；期望不再出现
  `ReferenceError … EntryAbility`，再按 `验收说明.md` / P1–P4 判读宿主与运行时（回归）。
- 状态：**已修复并验证**（kit #10：入口 record，测试方真机确认；kit #11：abc 版本，待真机回归）——
  收尾结论见 §5b。

## 5b. Resolution（已修复，2026-09-22）

前两个独立阻塞都已修复并进入交付：

1. **入口 record（PA1）**：壳构建改为 `useNormalizedOHMUrl=false` + bundle 前缀 record
   （`ohos-workload c2c4a9a`，壳归档 `6e55ae6`，162,996 B），随 **kit #10** 发布；测试方真机复测确认
   入口可解析（不再报 `ReferenceError … EntryAbility`）。
2. **abc 字节码版本**：修复入口后，真机复测暴露第二个阻塞 —— 壳 abc 头为 `24.0.0.0`，超出测试设备
   ark runtime 上限 `13.0.1.0`（hilog `export objects of native so is undefined` /
   `Cannot read property … of undefined`）。修复：壳构建固定 `compatibleSdkVersion 18`，
   SDK 26 工具链即产出 `13.0.1.0`（`ohos-workload 95c89a7`，壳归档 `ef1c947`，191,072 B），
   随 **kit #11** 发布（当前 kit；校验值见 release 说明「## Integrity」）。
3. **设备侧查询**：`xxd -l16 modules.abc`（期望 `0d 00 01 00` = `13.0.1.0`；`18 00 00 00` = `24.0.0.0`）
   与 `hdc shell param get const.ark.version`（设备运行时上限）；版本→API/SDK 映射与完整版本史见
   `2026-09-22-ohos-arkts-abc-version-history.md` §5。
4. **待办**：kit #12 的真机回归（重签 `hello-maui-app-unsigned.hap` 后按 `验收说明.md` 走）；
   三个分支已并入 `2026-09-21-ohos-crash-probes.md` §4.0/§4.0b/§4.0c 与决策表。

## 5c. 第三个阻塞：`host` undefined（宿主 `.so` 加载失败；kit #11 → kit #12）

kit #11 真机复测确认 abc 修复生效，并暴露第三个独立阻塞：

- **已验证的进展**：本机 `ark_disasm` 成功解析 kit #11 的 `ets/modules.abc`（头 `13.0.1.0`，191,072 B，
  反汇编输出 619,941 B；kit #10 的 `24.0.0.0` 当时被拒绝）；重签安装后 `[maui]` 日志大量出现，
  崩溃从入口模块解析推进到**页面/渲染阶段**；kit #11 已有的 `typeof host !== 'undefined'` 守卫把
  kit #10 的 `aboutToAppear` 崩溃降级为 `[maui] host export unavailable: <api>` 日志（不再抛异常）。
- **崩溃点**：`Index.ets` 的 XComponent `.onLoad` 中 `host.registerXComponent()` 是当时**唯一未纳入守卫**
  的宿主调用；`host` 为 undefined 时按名取属性（`ldobjbyname`）抛
  `TypeError: Cannot read property registerXComponent of undefined`（堆栈含
  `BCStub_HandleLdobjbynameImm8Id16StwCopy`），进程 `exit 254`。
- **归因（测试方报告）**：`host` undefined = `libopenharmonyhost.so` 加载失败。壳在 `EntryAbility.ui.ets` 的
  模块级 `import host from 'libopenharmonyhost.so'` 在 ability 加载时即触发 dlopen，而 `dotnet.zip`
  的解压发生在 `onCreate` 内稍后；宿主 `.so` 的加载期依赖若含只存在于 payload（`dotnet.zip`）中的库，
  加载器就无法解析 → NAPI 模块不初始化 → `host` 为 undefined（报告用 `readelf` 指认该项为
  `libhostfxr.so`）。官方依据：
  - 华为 FAQ `faqs-jsvm-9`：`readelf -d` 读出的依赖 so **必须打包进 HAP 或存在于系统库**，
    缺失会在应用启动过程中闪退；
  - 华为论坛主题「递归加载 DT_NEEDED」：任一依赖缺失、ABI 不符或存在未解析符号，都会在 NAPI 模块
    初始化前后直接闪退；
  - 华为论坛主题「启动时必加载的 .ets 中 import so」：`entryability.ets` 或首页 `.ets` 中 import 的 so
    会在 APP 启动时主动加载；
  - 「`export objects of native so is undefined` = native so 加载失败」的同类实测。
- **修复（kit #12；`ohos-workload 7e71c39` + 壳归档 `2411a8e`，2026-09-22）**：
  1. **链接期不依赖 `libhostfxr`**：宿主全部 `hostfxr_*` 入口保持经 `openharmony_host.c` 既有的
     `dlopen`/`dlsym` 表在 `start_app`/`run_app` 时解析（此时 payload 已解压，从
     `${payloadDir}/libhostfxr.so` 加载）；动态符号表无未定义的 `hostfxr_*` 符号；
  2. `scripts/build-host.sh` 增加**构建期 DT_NEEDED 审计**：`llvm-readelf` 打印加载期依赖面，出现
     `libhostfxr` 即构建失败（本次构建输出 `selfsign ok`，NEEDED 无 `libhostfxr`）；
  3. 宿主 dlopen 成功但入口缺失时，`run_app`/`start_app` 逐名打印缺失的 `hostfxr_*`（stderr + hilog），
     `dlerror` 路径保留；
  4. 壳模板（preview.22/23/24 三份保持一致：`Index.ets`、`EntryAbility.ets`、`EntryAbility.ui.ets`）
     把**每个** `host.<api>` 访问纳入 `hostCall` + `typeof host !== 'undefined'` 守卫，包括此前裸调的
     `host.registerXComponent()`、`pullMenu` 的 `menuCount`/`menuItem` 读与 `publishAppContext` 的
     显式 undefined 早退；宿主缺失时只记一次性 `host export unavailable` 日志，不再从页面/生命周期
     回调抛 TypeError。
- **产物证据（readelf/symbols）**：`readelf -d libopenharmonyhost.so | grep NEEDED` = 14 项
  （`libace_napi.z.so`、`libace_ndk.z.so`、`libhilog_ndk.z.so`、`libnative_window.so`、`libnative_drawing.so`、
  `libimage_source.so`、`libpixelmap.so`、`libohvibrator.z.so`、`libnet_connection.so`、
  `libability_access_control.so`、`liblocation_ndk.so`、`libohsensor.so`、`libc++_shared.so`、`libc.so`），
  **不含 `libhostfxr.so`**；`.dynstr` 无 `hostfxr`，动态符号表无未定义 `hostfxr_*`
  （`libhostfxr.so` 仅作为 dlopen 路径字符串出现）。壳重建：`13.0.1.0` abc（200,508 B，0 ArkTS:ERROR），
  交互套件 284 条 / 0 Unhandled / 性能门 within=True。
- **设备侧复核（宿主仍加载失败时）**：
  ```sh
  unzip -p hello-maui-app.hap libs/arm64-v8a/libopenharmonyhost.so > /tmp/host.so
  readelf -d /tmp/host.so | grep NEEDED                  # 加载期依赖面：每项都必须在下面两处之一
  unzip -l hello-maui-app.hap | grep 'libs/arm64-v8a/'   # ① 随 HAP 的 libs/<abi>/
  hdc shell ls -l /system/lib64/<每个 NEEDED 名>          # ② 设备系统库（libc++_shared.so 随包）
  hdc shell hilog | grep -iE "dlopen|not found|cannot find library|export objects of native so"
  ```
- **核验注（与报告 readelf 清单的差异）**：对测试方报告同哈希的 kit #11 tarball 内 5 个 hap 逐一
  `readelf -d`，宿主 NEEDED 均为上述 14 项、均不含 `libhostfxr.so`；宿主源码自始使用 dlopen/dlsym。
  报告的 NEEDED 清单（含 `libhostfxr.so`、缺 `libc.so`）与产物不一致，故本节把**症状链与官方依据**
  记为事实、把“具体缺失哪个加载期依赖”留给设备 hilog 的 `dlopen`/`dlerror` 行确认；kit #12 的守卫
  保证即使宿主再次加载失败也只逐 API 记 `host export unavailable`，不再 `exit 254`。

## 5d. 里程碑：kit #14 启动并稳定存活（2026-09-23）

测试方 kit #14 真机报告（包经 `verify-kit.sh` 树摘要校验通过，abc 被 `ark_disasm` 正常解析）。
**以下为设备实测（测试方日志）**：

- **首次启动成功且进程稳定存活**：`aa start` 返回 `start ability successfully.`；1 分钟+ 后主进程与
  `com.example.hellomauiapp:gpu` 进程仍在（`ps` 实测两行；此前各轮均为启动约 1 s 后 `exit 254`）。
- **零崩溃日志**：`hilog | grep hellomauiapp | grep -iE 'TypeError|JsError|exit with code|PROCESS_KILL|Error message'`
  为空；无 `AppKilledReporter` / jscrash。
- **三个既有根因在真机确认修复**（测试方四轮口径，对应本文 §5b/§5c）：① 入口 record（kit #10，
  `useNormalizedOHMUrl=false` + bundle 前缀 record）；② abc 字节码版本 `13.0.1.0`（kit #11，
  `compatibleSdkVersion 18`）；③ 运行时原生库不再留在 `dotnet.zip`，随 hap `libs/arm64-v8a/` 打包
  （kit #13/#14；`libs/` 实测含 `libhostfxr.so` / `libhostpolicy.so` / `libcoreclr.so` / `libclrjit.so`
  等 13 个 .NET 运行时 `.so` + `libopenharmonyhost.so` + `libc++_shared.so`，`dotnet.zip` 内已无 `.so`，
  宿主 `DT_NEEDED` 已不含 `libhostfxr.so`）—— 即 §5c 的宿主加载序问题在交付侧的最终落地。
- 里程碑句：**kit #14 是第一个「启动成功、进程存活、零崩溃日志」的构建**；黑屏是其后暴露的独立问题（§5e），
  不是崩溃回归。

## 5e. 第四个阻塞：黑屏 —— napi 注册名与 abc import 记录名不匹配（kit #14 暴露；RH1 进行中）

kit #14 的崩溃清零后，新现象是**黑屏（进程不退出）**：

- **设备实测证据（测试方 kit #14 日志）**：
  - ArkUI 侧 XComponent 已创建、挂树、表面已创建：
    `AceXcomponent: XComponent[ohos_dotnet_surface] AttachToMainTree …` 与
    `AceXcomponent: XComponent[ohos_dotnet_surface] triggers onLoad and OnSurfaceCreated callback`；
  - 同时段 `[maui] host export unavailable: <api>` 覆盖全部宿主 API（`setNodeContent`、`registerXComponent`、
    `setBundleInfo`、`register*Sink`、`menuCount` …）→ **host exports 整体为空**；
  - **决定性日志**：`ArkCompiler: [ecmascript] Load native module failed, ModuleName:
    @app:com.example.hellomauiapp/entry/openharmonyhost`，且全量 hilog 中**只有失败行、无任何成功加载行**
    （so 的 `Init` 从未被调用）；
  - 可运行对照工程 `cc-switch`：`useNormalizedOHMUrl=true`，abc 记录名 `@normalized:Y&&&libentry.so&`，
    so 注册名 `libentry.so` —— 两者匹配，正常渲染。
- **代码/包内事实**：宿主 `src/OpenHarmonyHost/host_napi.cpp` 的 `g_hostModule.nm_modname` 为裸名
  `"openharmonyhost"`；kit #14 壳 abc 在 `useNormalizedOHMUrl=false` 下把
  `import host from 'libopenharmonyhost.so'` 编译为记录名
  `@app:com.example.hellomauiapp/entry/openharmonyhost`，两者字符串形式不一致。
- **官方依据（华为，与设备无关的文档证据）**：ArkTS `import xxx from libxxx.so` 后 `xxx` 为
  undefined / not callable 时，须排查 native 模块注册名与 so / 模块名一致
  （`napi-faq-about-common-basic`；`use-napi-process` / `faqs-ndk-46`：导入模块名与注册模块名大小写一致，
  模块名 `entry` ↔ `libentry.so` ↔ `nm_modname = "entry"`）。
- **机制（设备日志 + 代码推断，非新增设备实验）**：设备按 abc 的 import 记录名查找 native 模块 → 注册名
  不匹配 → 模块从未初始化（无成功加载日志）→ host exports 为空 → `setNodeContent` / `registerXComponent`
  均不可用 → 表面虽已创建但从未交给 .NET/MAUI → 黑屏。
- **修复（RH1，进行中 / in flight；方案，非设备实测）**：宿主侧**别名注册**覆盖两种约定（裸名 +
  bundle 前缀记录名），并出**标准化壳构建**（`useNormalizedOHMUrl=true` 一侧），同时保留入口 record 修复
  所用的 bundle 名（`com.example.hellomauiapp`），**入口 record 需重新核验**。**截至本页写作时 RH1 尚未落地**：
  `ohos-workload` 工作树中 `host_napi.cpp` 仍为 `nm_modname = "openharmonyhost"`，无别名注册；最近提交是
  kit #15 的 rawfile 资源桥（与 RH1 无关）。RH1 落地后按「so 注册名 ↔ abc import 记录名」对照 +
  设备 `hilog | grep 'Load native module failed'` 是否消失来复核。

## 5f. 2026-09-24 设备证据修正（真机完整运行；旧 #4 降级为无害加固）

测试方 kit #17→#18 + 5 项本地修复后，在设备（HUAWEI MateBook Pro HAD-W24 / HarmonyOS 7.0.0.105 /
API 26 / arm64-v8a）**首次完整运行成功**：`managed app hello-maui-app.dll started (UI shell)`、
进程持续存活（主进程 + `:gpu`）、XComponent `native OnSurfaceCreated` 回调触发、ArkUI 渲染层工作
（`AceAppBar: callNative`）、`SmartGC: app cold start just finished`、无崩溃（无 `TypeError` /
`JsError` / `exit 254`）。**边界：这是 kit #18 + 测试方本地修复链的结果，stock kit #22 尚未上机。**

**对 §5d/§5e 第四阻塞（黑屏）的修正**：

- 旧 #4 的两个半边 —— RM1 `libIsolation`（模块级 app-lib `<bundle>/<module>` key）与 RH1
  nm 别名/注册名 —— **并非本次失败的关键**：成功运行的整份日志中没有 `Load native module failed`
  阻断；两项保留为**无害加固**（不撤、不回滚）。
- **直接链是另外 5 项**（按设备证据顺序）：① 宿主 `.so` dlopen 失败（设备缺 10 个系统库 + 62 个符号，
  含 IME `OH_InputMethodProxy_ShowKeyboard`）→ ② `dotnet publish` 的 HAP 缺 `resources.index`
  （`GetRawFileContent failed, name is empty`）→ ③ `fs.copyFile(zip.fd)` 忽略 `getRawFd` 的
  offset/length（`BusinessError 900003`）→ ④ 解压前缺 mkdir（`BusinessError 900002`）→
  ⑤ abc 由 DevEco 新建工程编译（hvigor `00302013`）。完整证据见
  `2026-09-24-ohos-device-milestone.md` §2。
- **libhostfxr 的 dlopen 候选 1/2 已由设备验证**：经宿主自身目录（`libs/arm64-v8a/`，namespace 允许）
  成功加载，未回退到解压目录（§5c 的候选逻辑生效）。
- **回灌映射（随 kit #22）**：`ohos-workload 64c989b`（宿主 NEEDED 5 库 + 可选 API dlsym + 门禁）·
  `61e6e81`/`4dd12a2`（ZIP offset / mkdir）+ `76a6f7a`（abc 重建）· `0f26b74`（`resources.index` via restool）·
  `019ddae`（DevEco 工程布局 + 00302013 诊断）；里程碑 §3 有权重与回归证据。
- **仍未验证**：stock kit #22、无 hilog/libnative_window 环境分支、`resources.index` legacy（579 B）与
  RestoolV2（707 B）的设备兼容、其余功能面与对照载荷 —— 见里程碑 §5/§6。

> §5b–§5e 保留当时的判断、证据与时间线，不改写；本节只做增量修正。

## 6. 六类错误的关系（避免混淆）

| 错误 | 含义 | 是否预期 | 处置 |
|---|---|---|---|
| `9568257 fail to verify pkcs7 file` | 自签名 hap 被设备拒绝（签名不受信任/无效） | 是（包内 4 个默认 hap） | 重签 `hello-maui-app-unsigned.hap` 或用预签包 |
| `9568344 install parse profile prop check error` | 调试 profile 未绑定本设备 UDID | 是 | 重签 / 回传 UDID 重签 / `--sign-external` 预签 |
| `ReferenceError … EntryAbility` + `exit 254` | 壳 abc 入口 record 缺陷 | **否**（kit #10 前） | kit #10 起已修复；重签新 kit 重测 |
| `export objects of native so is undefined` / `Cannot read property … of undefined` | 壳 abc 字节码版本高于设备 ark runtime 上限（`24.0.0.0` > `13.0.1.0`） | **否**（kit #11 前） | kit #11 起已修复（`compatibleSdkVersion 18` → `13.0.1.0`）；`xxd -l16 modules.abc` + `hdc shell param get const.ark.version` 复核 |
| `[maui] host export unavailable: <api>` / `Cannot read property registerXComponent of undefined` + `exit 254` | 宿主 `.so` 加载失败 → 壳 `host` 为 undefined（加载期 DT_NEEDED 在 `dotnet.zip` 解压前解析） | **否**（kit #12 前） | kit #12 起：宿主无 `libhostfxr` 链接依赖（dlopen/dlsym）+ 构建期 DT_NEEDED 审计；壳全部 `host.<api>` 守卫；`readelf -d … \| grep NEEDED` 对照 hap `libs/<abi>/` 与设备系统库（§5c） |
| `Load native module failed, ModuleName: @app:<bundle>/entry/openharmonyhost` + 全部 `[maui] host export unavailable: <api>`，应用启动后**黑屏但不崩** | napi 注册名（`nm_modname`）与 `useNormalizedOHMUrl=false` 下 abc 的 import 记录名不匹配 → host exports 为空 → XComponent 表面未交给 .NET | **否**（kit #14） | RH1（宿主别名注册覆盖两种约定 + 标准化壳构建、保留 bundle 名）**进行中（in flight）**；复核 so 注册名 ↔ abc 记录名，并用 `hilog \| grep 'Load native module failed'` 看失败行是否消失（§5e） |

## 7. 参考

- 测试方反馈原文：`ohos-device-test-kit-feedback.md`（2026-09-22；本机 `~/Download/com.haitai.htbrowser/`）
- 测试方 kit #11 报告：`ohos-device-test-kit-kit11-verification.md`（2026-09-22；同目录；第三个阻塞与官方依据出处）
- 测试方 kit #14 报告：`ohos-device-test-kit-kit14-verification.md`（2026-09-23；同目录；里程碑、黑屏根因、
  host exports 为空与 XComponent 日志、`cc-switch` 对照、华为 napi 注册名依据）
- 自签与重签：`2026-09-21-ohos-tester-selfsign.md`（包内 `自签说明.md`）、`2026-09-19-ohos-signing-and-udid-guide.md`
- 崩溃探针与决策表：`2026-09-21-ohos-crash-probes.md`（§4.0/§4.0b/§4.0c/§4.0d 已加四个分支）
- abc 版本史与设备查询：`2026-09-22-ohos-arkts-abc-version-history.md`
- 交付与状态：`2026-09-21-ohos-delivery-kit-readme.md`、`2026-09-21-ohos-final-status.md`
