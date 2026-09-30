# 用你的 DevEco Studio 给未签名 hap 自签（无需我们介入）

> **2026-09-30 更新（kit #34，当前）**：kit #34 = #33 + **rc.2 基线并入主线**（SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** / MAUI **`11.0.0-rc.2.26478.12`**（dnceng daily：restore 走 dnceng `dotnet11` feed，官方 rc.2 上 nuget.org 后换 pin 并移除 feed）+ CoreLib `LINUX` 别名 → `OS Platform: Linux`）+ **MAUI W6/W7/W8 新特性**（T14 富 Shell flyout / T12 CarouselView 分组 / N1 多指坐标 / FIX-SHELL；T15 富 TitleView / T16 结构化菜单 / N4 TitleBar a11y / T18 Essentials IMap / N5 覆盖层触摸抑制 / N6 标题栏系统装饰；套件 **513/floor 493**、导出 **145**）+ **AOT v3 独立资产**（`aot-haps-v3.tar.gz` 17,537,186 / `004ba03c…`）。数字以 release「## Integrity（kit #34）」与随包校验为准；判定点 = `docs/plans/2026-09-30-ohos-tester-handoff-kit34.md`（#33 = 上一版，见其交接文）。

## 为什么
包内 4 个默认 hap 是**自签名（设备会拒绝，需要重签）**包：用我方调试证书 / 调试 profile 签名，profile 只包含
我们机器的 UDID → 在你的设备上安装会被系统拒绝，报
`9568257 fail to verify pkcs7 file`（设备不信任该签名）或 `9568344 install parse profile prop check error`
（profile 未绑定你的 UDID）。**这是预期结果，重试无用**。用**你自己的华为账号自动签名**即可解决。

本流程签的是包内**未签名变体** `hello-maui-app-unsigned.hap`（与默认包同一负载）——它是 kit 里**唯一**适合重签
安装的 hap；不要直接拿 4 个自签名 hap 重签。签完的 hap 绑定你的证书/UDID，设备才会接受。

> 未签名 hap 随 `device-test-kit` release（镜像在 `workload-latest`）交付；下载/解压前先按该
> release 说明的「## Integrity」小节（整包 sha256、内容树 digest）或 `.tar.gz.sha256` sidecar
> 校验。本文件与包内文档都不写死哈希 —— 一律以 release notes 为准（重签后哈希必变；kit #32 实测 tar **207,114,608 / `8f690949…`**、树 **`645879bc…`**、sidecar **`344760e7…`**、`SHA256SUMS` 16 项 / 1,410 B / `2d3f2fad…`；#31 实测 tar 207,023,588 / `f4325d2f…`、树 `52e77ee8…`、sidecar `7d0cba77…`、`SHA256SUMS` 16 项 / 1,410 B / `f49b9a0e…` 仅作对照；#30（196,992,264 / `a781c25b…`）更早对照）。
> 当前发布 = **kit #34**（2026-09-30；rc.2 基线 + MAUI W6/W7/W8（T12/T14/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6；套件 513/floor 493、导出 145）+ AOT v3；Blazor 双变体各重签一次；数字以 release「## Integrity（kit #34）」为准）；上一版 = **kit #33**（2026-09-29；Blazor 回归修复/双 hap A/B + TabbedPage/A11Y + W5 470/450 + AOT v2）；更早 = **kit #32**（2026-09-28，WebView 六项接线 + B1 razor 独立资产 + SEC 收口：B1 `hello-maui-razor`（bundle `com.example.hellomauirazor`）与 MAUI 5 hap（新壳 abc **289,992**）均需按本文件流程重签；探针标记 pid+nonce、Blazor hap **无 INTERNET**（重签保持）；交互门禁 **398/floor 378**、tester-run **v14**（140,197 B / `a174fcd0…`，asset 595131362）；第 6 个 hap `hello-blazorwasm-host-unsigned.hap`（26,794,931 B / `36010a9c…`，未签名，bundle `com.example.opendotnet`，需按本文件 Blazor 条目重签）承 #31）；#31 = Blazor WASM/ArkWeb 组件 + tester-run v13（`--blazor-probe` 两标记）为对照；MS-MODE 批不变：**runtime-mode 打包开关**（`-p:OpenHarmonyRuntimeMode=jit|aot|interp`（默认 jit）→ hap `libs/<abi>/runtime-mode.txt`；宿主优先级 file>manifest>default、日志 `runtime-mode=<v> source=…`；aot 缺库显式回退 JIT、interp 可带 `-p:OpenHarmonyInterpreterPack`）+ **tester-run v12**（`--mode-matrix` + `--a11y-probe` + `runtime_mode`）+ **MAPFIX harmony 重切**（MapOverlay 真编译：abc 291,628 B/`a637a513…`、tar `9b0506fa…`）；R3 批不变：**CoreSpeechKit TTS**（`canIUse` + `@kit.CoreSpeechKit` 双门；无 Kit 时 `IsSupported=false`、调用降级不抛；真朗读需 HMS 设备 + harmony 壳）+ **HUKS-first SecureStorage**（设备绑定 AES-256-GCM 密钥、**0 权限**；无 HUKS 时回退文件密钥并如实标注非硬件后备）+ **自绘深度五连**（文本编辑/动画/列表/图片/深链）；宿主导出契约 **143/143**；ui/shell abc **281,052 B**（headless 20,916 B）；交互门禁 **387/floor 367 → 391/floor 371**；R2（#28）、KIT-EXT2（#27）、P2-INTEROP/TASK-MIG/PLAT-GAP（#26）、权限链/Share-Scan 探测降级/AOT 启动路径（#25）与 #24 的 payload-in-libs（`libs/arm64-v8a/` 原地携带 254 payload + `.dotnet-payload.json`，`dotnet.zip` 回退）/显式 W^X=0 均不变；含 kit #22 的设备回灌与自 #17 起全部修复）；里程碑与复测判定点见 `docs/plans/2026-09-24-ohos-device-milestone.md`；本轮判定点见 `docs/plans/2026-09-29-ohos-tester-handoff-kit31.md`（§2；#30 见 `docs/plans/2026-09-28-ohos-tester-handoff-kit30.md`，#29 见 `docs/plans/2026-09-28-ohos-tester-handoff-kit29.md` §2），R2 判定点见 `docs/plans/2026-09-26-ohos-tester-handoff-kit28.md`，KIT-EXT2 判定点见 `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md`，P2-INTEROP/PLAT-GAP 判定点仍见 `docs/plans/2026-09-26-ohos-tester-handoff-kit26.md`，权限/Share/Scan/AOT 判定点仍见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`，JIT/NativeAOT 交接见 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`。包内
> `签名说明.txt` 的「PA1 重建壳的下一版 kit」历史句已随源修复（`ohos-workload c6a4cd95e`）；若副本仍出现该句，判读以 `签名说明` 其余内容与 release notes 为准。

## 步骤（约 3 分钟）
1. DevEco Studio → 新建任意工程（Empty Ability 即可）→ 在 `AppScope/app.json5` 里把 **bundleName 改为
   `com.example.hellomauiapp`**（必须与我们的 hap 一致，否则同样会因属性校验失败）。
2. File → **Project Structure → Signing Configs** → 勾选 **Automatically generate signature**（需登录华为开发者账号）
   → Studio 会生成 `*.p12` / `*.cer` / `*.p7b`（目录通常在 `~/Documents/ohos/config/`，含 `material/` 子目录）。
3. 用同一 SDK 的 `hap-sign-tool` 给我们的未签名 hap 签名（把下面路径换成你的）：
   ```bash
   hap-sign-tool sign-app -keyAlias debugKey -signAlg SHA256withECDSA -mode localSign -signCode 1 \
     -appCertFile <你的>.cer -profileFile <你的>.p7b \
     -inFile hello-maui-app-unsigned.hap -outFile hello-maui-app-signed.hap \
     -keystoreFile <你的>.p12 -keyPwd "<key密码>" -keystorePwd "<store密码>" -signCode 1
   hap-sign-tool verify-app -inFile hello-maui-app-signed.hap -outCertChain out.cer -outProfile out.p7b
   ```
   > **`-signCode 1` 必须带上（它同时也是默认值）**：`sign-app` 靠它在 HAP 签名块里为 `libs/**`
   > （含 `*.an`）逐个写入 `SoInfoSegment`，这是 app 内 native 库在安装时被使能 fs-verity 的**唯一签名
   > 凭据**（设备 XPM 校验的正是它）。若你的重签包装脚本/模板显式覆盖过 `-signCode`（如写成 `0`），
   > 请显式传 `1`——否则 `libs/**` 不受保护，app 内 `dlopen` 会报 `unsigned file` /
   > `lib_no_signed event waken: -9(E_HM_PERM)`（机制与 kmsg 判读：`docs/plans/2026-09-22-ohos-elf-signing-research.md`）。
   > 包内 `libs/**` 文件里可能带的 `.codesign` keyless 自签（我方 `ElfSigner`）**不是** app 的签名凭据：
   > 安装期不读它，只认上面的 HAP 签名块；重签后可用研究文档 Tester checklist 第 3 条一行命令确认
   > `SoInfoSegment` 出现（期望 ≥1）。
   > 若 `build-profile.json5` 里的密码显示为 `00000020…`（DevEco 加密值），可让 Studio 的 Signing Configs 界面显示/复制明文；
   > 或把该 `config` 目录整体发回给我们，我们用插件离线解密后代签（一条命令：`ohos-workload/scripts/sign-huawei.sh`，
   > 见 `签名与UDID指南.md` 第 4b 节）。
4. `hdc install hello-maui-app-signed.hap`，或把 hap 拷到设备用文件管理器打开安装。
   若仍报 `9568257`/`9568344`，说明这次签名的证书/profile 没绑定本设备：检查 profile 的 `debug-info.device-ids`
   是否含你的 UDID、bundleName 是否与包一致（`com.example.hellomauiapp`），再重签。

## Blazor WASM 组件（`com.example.opendotnet`，kit #31 起）

kit #32 起：B1 razor 独立资产（`hello-maui-razor`，bundle `com.example.hellomauirazor`，MAUI Blazor Hybrid/native）与 MAUI 5 hap（新壳 abc 289,992）重签步骤与 MAUI 未签包完全相同；Blazor 组件 hap **无 INTERNET**（重签保持）。

kit #31 新增第 6 个 hap **`hello-blazorwasm-host-unsigned.hap`**（26,794,931 B / `36010a9c…`，未签名）：ArkTS-only 宿主
（ArkWeb `Web` 组件）内嵌 Blazor WASM 站点，bundle = **`com.example.opendotnet`**（与 MAUI 包的
`com.example.hellomauiapp` 不同）。自签步骤与上文完全相同，只需在第 1 步把工程
`AppScope/app.json5` 的 bundleName 改为 **`com.example.opendotnet`**；`hap-sign-tool sign-app` 的
`-signCode 1` 不变。注意：hap 声明 **`ohos.permission.INTERNET`**（宿主工程 dev-only；站点 rawfile 直供、**运行时不需要联网**；**重签后声明是否保留取决于你的签名工程**）。安装后按《验收说明》Blazor 段判读：

- 自动（必过）：`sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe` → hilog 出现
  `BlazorWebHost ... marker: BLZ_BOOT` 与 `marker: BLZ_RENDERED`；失败落盘 `blazor-hilog.txt`。
- 人工：首屏 “Hello from Blazor WebAssembly”；进 `/counter` 点击一次 +1；截图 1 张。
- 失败回传：`blazor-hilog.txt`（`hilog -x` 原文，含 `BlazorWebHost` 与 `BLZ_ERROR` 行）+ 截图
  （可附 `bm dump -n com.example.opendotnet`）。

## 安装后请回传
- 日志两行：`[maui] openharmony build …` 与 `[maui] accessibility provider status=<n>`（期望 1）
- 左下角 **A11Y** 角标弹窗内容（状态 + 节点数）
- `验收说明.md` §4b 的 N1–N7 与 §5b 关键字清单结果
- 一页回传模板：`docs/plans/2026-09-21-ohos-device-report-template.md`；若启动即崩，`ReferenceError: Cannot find module 'ets/entryability/EntryAbility' , which is application Entry Point`（约 1 秒退出 / `exit 254`）是旧 kit（kit #10 之前）的壳 abc 入口 record 缺陷，**kit #31 已不含**（修复历史见 `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md`；2026-09-24 设备证据修正见其 §5f）；其他崩溃附 `docs/plans/2026-09-21-ohos-crash-probes.md` 的 P1–P4 探针结果（含免安装 14 库自检）与 `tester-run.sh` v13 的 app-lib/dlopen/bootstrap/payload/execmem/a11y 证据；里程碑背景见 `docs/plans/2026-09-24-ohos-device-milestone.md`，本轮判定点（**Blazor 段：自动 `BLZ_BOOT`/`BLZ_RENDERED` 两条标记 + 人工首屏/`/counter` +1/截图**；承 #30 的 runtime_mode 标记与优先级、模式矩阵清单路线、MAPFIX Map 点亮 + 承 #29 的 TTS/HUKS/a11y/自绘深度）见 `docs/plans/2026-09-29-ohos-tester-handoff-kit31.md`（#30 见 `docs/plans/2026-09-28-ohos-tester-handoff-kit30.md`），R2 判定点（Map 覆盖层/LiveView/AOT 启动桥/解释器实验）见 `docs/plans/2026-09-26-ohos-tester-handoff-kit28.md`，KIT-EXT2 判定点（无 HMS 降级不抛/新 payload）见 `docs/plans/2026-09-27-ohos-tester-handoff-kit27.md`，P2-INTEROP/PLAT-GAP 判定点见 `docs/plans/2026-09-26-ohos-tester-handoff-kit26.md`，权限弹窗/Share/Scan/AOT 判定点仍见 `docs/plans/2026-09-25-ohos-tester-handoff-kit25.md`，JIT 判定与 NativeAOT 指引见 `docs/plans/2026-09-24-ohos-tester-handoff-kit24.md`。
