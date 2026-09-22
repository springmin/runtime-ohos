# 启动崩溃根因：壳 abc 入口 record 缺失（ReferenceError / exit 254）

> 2026-09-22 记录测试方真机反馈的完整证据链与结论（一手材料：《OpenHarmony MAUI device-test-kit 真机验证反馈报告》）。
> **结论先说**：
> 1. 安装报 `9568257 fail to verify pkcs7 file` 是包内**自签名 hap 的预期拒绝** —— 设备不信任我方调试签名；
>    必须重签 `hello-maui-app-unsigned.hap`（唯一可重签安装的变体）或用发布方预签包，与启动崩溃无关。
> 2. 重签安装成功后启动即崩（约 1 秒 / `exit 254` / `JsError`）的根因是 **ArkTS 壳 `modules.abc` 缺少入口模块
>    record 索引**（记录名与 `module.json` 的 `srcEntry` 不匹配），**不是**宿主缺 `libc++_shared.so`（H1），
>    也不是宿主 dlopen/入口（H2）。修复：PA1 重建壳 abc（`ohos-workload/scripts/build-arkts-shell.sh`）后重出 kit —— 已随 kit #10 落地并被测试方真机确认。
> 3. 修复入口 record 后的同一轮真机复测暴露第二个独立阻塞：**壳 abc 字节码版本 `24.0.0.0` 超出设备的 ark runtime
>    上限 `13.0.1.0`**（hilog `export objects of native so is undefined` / `Cannot read property … of undefined`），
>    已随 kit #11（`compatibleSdkVersion 18`）修复。两个根因的收尾见 §5b。

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

两个独立阻塞都已修复并进入交付：

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
4. **待办**：kit #11 的真机回归（重签 `hello-maui-app-unsigned.hap` 后按 `验收说明.md` 走）；
   两个分支已并入 `2026-09-21-ohos-crash-probes.md` §4.0/§4.0b 与决策表。

## 6. 四类错误的关系（避免混淆）

| 错误 | 含义 | 是否预期 | 处置 |
|---|---|---|---|
| `9568257 fail to verify pkcs7 file` | 自签名 hap 被设备拒绝（签名不受信任/无效） | 是（包内 4 个默认 hap） | 重签 `hello-maui-app-unsigned.hap` 或用预签包 |
| `9568344 install parse profile prop check error` | 调试 profile 未绑定本设备 UDID | 是 | 重签 / 回传 UDID 重签 / `--sign-external` 预签 |
| `ReferenceError … EntryAbility` + `exit 254` | 壳 abc 入口 record 缺陷 | **否**（kit #10 前） | kit #10 起已修复；重签新 kit 重测 |
| `export objects of native so is undefined` / `Cannot read property … of undefined` | 壳 abc 字节码版本高于设备 ark runtime 上限（`24.0.0.0` > `13.0.1.0`） | **否**（kit #11 前） | kit #11 起已修复（`compatibleSdkVersion 18` → `13.0.1.0`）；`xxd -l16 modules.abc` + `hdc shell param get const.ark.version` 复核 |

## 7. 参考

- 测试方反馈原文：`ohos-device-test-kit-feedback.md`（2026-09-22；本机 `~/Download/com.haitai.htbrowser/`）
- 自签与重签：`2026-09-21-ohos-tester-selfsign.md`（包内 `自签说明.md`）、`2026-09-19-ohos-signing-and-udid-guide.md`
- 崩溃探针与决策表：`2026-09-21-ohos-crash-probes.md`（§4.0/§4.0b 已加两个分支）
- abc 版本史与设备查询：`2026-09-22-ohos-arkts-abc-version-history.md`
- 交付与状态：`2026-09-21-ohos-delivery-kit-readme.md`、`2026-09-21-ohos-final-status.md`
