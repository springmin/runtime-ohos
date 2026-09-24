# 真机里程碑：.NET MAUI 在鸿蒙设备上完整运行（2026-09-24，kit #22 回灌）

> 一手材料：测试方报告《kit #17→#18 真机验证完整报告》（2026-09-23，本机 `~/Download/com.haitai.htbrowser/`）。
> 结论：**kit #18 + 测试方 5 项本地修复后，应用首次在真机上完整运行成功** —— `managed app hello-maui-app.dll started (UI shell)`，
> 进程持续存活，XComponent `OnSurfaceCreated`，ArkUI 渲染层工作，冷启动完成，无崩溃。
> **边界**：这是**特定设备 + 测试方本地修复链**的结果；stock kit #22 尚未上机（§5/§6）。根因叙事修正见
> `2026-09-22-ohos-startup-crash-rootcause.md` §5f。

## 1. 结果与证据（测试方报告原文）

- **设备定义**：HUAWEI MateBook Pro（HAD-W24），HarmonyOS 7.0.0.105（SP7ENTC293E102R2P1log），
  `const.ohos.apiversion = 26`，arm64-v8a；UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`。
- **成功组合**：kit #18 最新代码 + 5 项本地修复（测试方本机 NDK 编译的 dlsym 宿主 so 250,296 B、
  DevEco 新建工程编译的 abc、hvigor HAP 提供的 `resources.index`、ZIP offset 与 mkdir 补丁）。
- 关键日志行：
  - `17:24:58.632 OHOS_DOTNET: managed app hello-maui-app.dll started (UI shell)` ← .NET 运行时启动
  - `AceXcomponent: XComponent[ohos_dotnet_surface] native OnSurfaceCreated` / `onLoad triggers`
  - `17:25:00.210 ArkCompiler: [gc] SmartGC: app cold start just finished`
  - 渲染：`AceAppBar: callNative` + `AddButtonPointLightAnim`；无 `Load native module failed` / `symbol not found`
- 进程：`com.example.hellomauiapp`（PID 18465，CPU 3%）与 `com.example.hellomauiapp:gpu` 均在；
  无 `TypeError` / `JsError` / `exit with code:254`；bootstrap 无 `bootstrap failed`。

## 2. 根因链（5 项；修正此前「#4 = libIsolation / napi path」假设）

| # | 设备现象（原话） | 根因 | 测试方修复 |
|---|---|---|---|
| ① | `Error relocating … OH_InputMethodProxy_ShowKeyboard: symbol not found` | 宿主 so 链接面过大：该设备缺 **10 个系统库 + 62 个符号**（IME/Vibrator/Sensor/Location/NetConn/AT/ImageSource…） | 本机 NDK 编译 dlsym 降级 so，链接库 15→4 |
| ② | `bootstrap failed: GetRawFileContent failed`（`name is empty`） | `dotnet publish` 的 HAP 缺 `resources.index`，ResourceManager 索引不到 rawfile | 用 hvigor/DevEco 编译的 HAP 提供 `resources.index` |
| ③ | `BusinessError 900003: ZIP entry data extraction failed` | `getRawFd` 返回 fd+offset+length，`fs.copyFile(zip.fd)` 忽略 offset/length → ZIP 不完整 | 按 offset/length 分块读写 |
| ④ | `BusinessError 900002: destination path is not an existing directory` | 解压前目标目录不存在 | 解压前 `fs.mkdirSync(payloadDir, true)` |
| ⑤ | `hvigor ERROR: 00302013 The root node is not yet available for build` | 脚本生成工程不完整，abc 无法编译 | DevEco 新建工程 + 替换 ets 源码编译 abc |

- **旧 #4 降级**：`libIsolation`（RM1）与 nm 别名/注册名（RH1）**并非关键** —— 成功运行日志中无
  `Load native module failed` 阻断；两项保留为**无害加固**，不撤。
- **libhostfxr 命名空间**：经宿主自身目录（`libs/arm64-v8a/`，namespace 允许）加载成功，
  `OhosHostOpenHostfxr` 候选 1/2 逻辑生效，不再回退到解压目录（§5c 结论已由设备验证）。

## 3. 我们侧回灌（commit 映射；`ohos-workload`）

| FIX | 内容 | 提交 |
|---|---|---|
| FIX-DEV1 | 宿主 `DT_NEEDED` 白名单收窄为 **5** 库（`host-deps.conf`）；可选系统库/API 全部按需 dlopen/dlsym（任务口径 54 个入口；`nm -D -u` 213、无 denylist 命中）；`build-host.sh` 加 NEEDED + UND 门禁 | `64c989b` |
| FIX-DEV2 | `copyZipRange` 64 KiB 分块、短读 fail-closed；解压前 `fs.mkdirSync`；preview.24 UI/headless abc 重建 | `61e6e81` / `4dd12a2` / `76a6f7a` |
| FIX-DEV3 | HAP 打包经 restool 生成 `resources.index`（`--index-path`；缺 restool 即构建失败；API20 自动 RestoolV2） | `0f26b74` |
| FIX-DEV4 | 生成工程对齐 DevEco（`modelVersion 6.0.2`、依赖守卫）与 00302013 诊断；abc 输出中性（字节不变） | `019ddae` |

- 发布链核对：`ohos-workload master` tip `0f26b74`；preflight **315 条 / floor 295**、像素与 markdownlint 全绿；
  CI（`64c989b`/`0f26b74`）interaction / pixel / markdownlint 三 run 成功。

## 4. kit #22 指纹（2026-09-24；数字入口 = release「## Integrity」）

- `device-test-kit.tar.gz`：**115,996,991 B** / `d21aed11124cb904ce8e2a77586645342f5b78cebf476f9089776ea6a09c71f1`；
  内容树 `472f4323a7e7027664d47c08545815f1bc5aa564cf5554ebdc1a6e42b4e9e4b6`；sidecar `f3dd46c736a16534e0215f7f5c50154ff58a372fe52c6eec6f4b8fcd5b23e54e`。
- 5 个 hap 均 `libIsolation=true`、**23 个 zip 条目（含 `resources.index`）**：UI/shell abc **212,952 B** /
  `6e616f5bb3f9ba47da5a9b485d3cdc4a8e61164b1f98ac141380c0b0a9c3474c` / `13.0.1.0`；headless abc **15,608 B** / `c72990c1…`。
- 宿主 pack **215,968 B** / `3332c8acc7ae8e72af1b348b0fa981b1b34e73c6777992ab1f5f609aa05c75e3`（HAP 内 220,064 B /
  `188f3dae…` = 215,968 + 4096 签名块；`DT_NEEDED` 5 项）；`libs/arm64-v8a/` 14 个 `.so`；`dotnet.zip` 253 项 0 `.so`。
- `resources.index`：26.0 波段 + 未签名 = 579 B / `a898272c…`（legacy），API 20 波段 = 707 B / `4fb9d60f…`（RestoolV2）。
- workload bundle **30,498,838 B** / `04b96cecbedffed7020f2c24b7b035df737d59969b3bed8dbb8fd1abe2cd8b82`
  （sdk-ohos 外锚 `821330d5..5818e1c6b5`）；`tester-run.sh` 未变（v6r2 / `a7db7d8c…`）。

## 5. 仍未真机验证（如实边界）

1. **stock kit #22**：成功运行的是 kit #18 + 本地修复产物；#22 的宿主/abc/resources.index/打包链均换了实现，
   固件与命名空间差异未再跑（本里程碑不可外推为「#22 已上机通过」）。
2. **无 hilog / libnative_window 环境分支**：可选库全部缺失时的降级路径（只剩 stderr 日志、IME disabled 等行为）
   未逐一上机；只在本机以「缺 IME 符号的 so」做过等价加载冒烟。
3. **resources.index 兼容**：#22 的 26 波段用 legacy Restool 格式（579 B）；成功案例用的是 DevEco hvigor 的 index（1162 B），
   legacy 与 RestoolV2（707 B）在设备上的实测均未做。
4. **功能面**：`验收说明.md` A1–K2 / N1–N7、新功能 M1–M13、P1–P4 探针、无障碍 `status=1`、Blazor/hybrid、T6/T8、S3/S4 等
   仍未证（清单见 `2026-09-18-ohos-device-validation-checklist.md`、`2026-09-22-ohos-new-features-device-checklist.md`）。
5. **组合面**：`libIsolation`（RM1）与别名注册（RH1）没有独立设备证据（成功运行未依赖它们）；
   对照载荷 dynpkg/normalized/importb/importd/importprobe a–c 仍未跑。

## 6. 复测建议（用 stock kit #22）

1. 取包：release `device-test-kit` 说明「## Integrity」核对 tar `d21aed11…` + tree `472f4323…`；或一条命令
   `sh tester-run.sh --kit-tar ./device-test-kit.tar.gz --expect-tree-digest <tree> --install --start --capture 30`。
2. 重签 `hello-maui-app-unsigned.hap`（`-signCode 1`，见 `自签说明.md`）后安装 26 波段默认包。
3. **判定点 A（宿主加载）**：无 `Error relocating … symbol not found`；无 `Load native module failed`；
   宿主诊断 hilog 可见（`[openharmony-host]` / hostfxr 行）。
4. **判定点 B（bootstrap）**：无 `GetRawFileContent failed` / `900002` / `900003`；首帧日志出现。
5. **判定点 C（里程碑回归）**：`managed app hello-maui-app.dll started (UI shell)` + 进程存活（主进程 + `:gpu`）
   + `SmartGC: app cold start just finished` + 无 `TypeError`/`JsError`/`exit 254`。
6. 失败分支：A 失败 → 宿主链接面（`readelf -d` + `host-deps.conf`）；B 失败 → `resources.index`/ZIP 路径；
   C 失败 → .NET 运行时/主启动；取证按 `2026-09-21-ohos-device-crash-diagnostics.md` §2.4 与
   `2026-09-21-ohos-crash-probes.md` P1–P4，一并回传 `appLibPathKey`、`MUSL-LDSO`、固件版本行。

## 7. 相关文档

| 文档 | 用途 |
|---|---|
| `2026-09-22-ohos-startup-crash-rootcause.md` | 启动崩溃根因（§5f 为本次设备证据修正；§5d/§5e 为历史节） |
| `2026-09-22-ohos-release-manifest.md` | kit #22 交付清单与数字入口（tar/tree/bundle/tester-run） |
| `2026-09-21-ohos-final-status.md` | 一页版最终状态（§11 收官指向本里程碑） |
| `2026-09-23-ohos-native-import-experiment.md` | RM1/别名实验记录（降级为无害加固的说明） |
| `2026-09-21-ohos-crash-probes.md` | P1–P4 探针与五层定位（失败分支） |
