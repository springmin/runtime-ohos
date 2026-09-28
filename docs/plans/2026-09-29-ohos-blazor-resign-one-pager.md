# Blazor 组件重签与验收操作卡（kit #32 · 一页版）

> 日期口径：文件名按撰写日；kit #32 发布日与数字以 release「## Integrity（kit #32）」为准（#31 发布日 = 2026-09-28）。

> 对象：kit #32 第 6 个 hap `hello-blazorwasm-host-unsigned.hap`（#31 起；**#32 起无 INTERNET**，重签保持；约 26,794,931 B / `36010a9c…` 为 #31 值，以 release 为准；bundle **`com.example.opendotnet`**）；流程 = 重签 → 安装 → 启动 → 自动/人工判读 → 失败回传；细节见包内《自签说明》与 `2026-09-28-ohos-tester-handoff-kit32.md` §2。

## 1. 取件

- 解出 `hello-blazorwasm-host-unsigned.hap`（只拿这一个文件也可操作）；**kit #32 起该 hap 无 `ohos.permission.INTERNET`**（rawfile 直供；重签不修改 module.json，重签后保持）；kit #32 整包数字以 release「## Integrity（kit #32）」与随包 `SHA256SUMS`/`.tar.gz.sha256` 为准（#31 实测 tar **207,023,588 B / `f4325d2f…`**、Blazor hap 26,794,931 B / `36010a9c…` 仅作对照）；重签后哈希必变，以新产出 + 新验签为准。

## 2. 重签（与 MAUI 未签包同流程）

1. **bundle + 材料/UDID**：自签工程 `AppScope/app.json5` 的 `bundleName` = `com.example.opendotnet`（否则属性校验失败）；DevEco「Automatically generate signature」得 `*.p12`/`*.cer`/`*.p7b` + `keyAlias`（默认 `debugKey`），profile 的 `debug-info.device-ids` 必须含 `hdc shell bm get -u` 的 UDID。
2. **签名 + 验签**：`hap-sign-tool sign-app -keyAlias <alias> -signAlg SHA256withECDSA -mode localSign -signCode 1 -appCertFile <cer> -profileFile <p7b> -inFile hello-blazorwasm-host-unsigned.hap -outFile blazor-signed.hap -keystoreFile <p12> -pwdInputMode 1`（**`-signCode 1` 必带**；**口令不进 argv**）→ 同 SDK `hap-sign-tool verify-app -inFile blazor-signed.hap -outCertChain out.cer -outProfile out.p7b`。
3. 路线 B（材料发回、我方预签）：p7b + p12 + cer + keyAlias 走安全通道 → `sh scripts/sign-for-device.sh --external --profile <p7b> --key <p12> --cert <cer> --key-alias <alias> --pwd-input-mode --expect-udid <UDID>`（口令不进 argv，fail closed）。

## 3. 安装 / 启动

```sh
hdc install -r blazor-signed.hap        # 或：hdc shell bm install -p /data/local/tmp/blazor-signed.hap
hdc shell aa start -b com.example.opendotnet -a EntryAbility
```

## 4. 自动判读（必过；启动后 3–5 s）

```sh
hdc shell "hilog -x | grep BlazorWebHost"    # 期望：marker: BLZ_BOOT 与 marker: BLZ_RENDERED
```

- 两条都在 = 通过；出现 `marker: BLZ_ERROR <msg>` = 失败（原文记录并回传）。一键版（推荐）：`sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe`（**kit #32 随包 v14**；标记只认宿主 pid + session nonce；失败自动落 `blazor-hilog.txt`）。

## 5. 人工判读（截图 1 张）

- 首屏 = “Hello from Blazor WebAssembly”（无白屏 / 错误页 / 持续加载）；进入 `/counter` 点一次 `Click me`：计数 0 → 1（路由 + 事件 + interop 全通）。

## 6. 失败回传

- `hdc shell hilog -x > blazor-hilog.txt`（须含 `BlazorWebHost` / `BLZ_ERROR` 行）+ 截图 1 张；可附 `hdc shell bm dump -n com.example.opendotnet`。

## 7. 常见问题

| 现象 | 原因 / 处理 |
|---|---|
| 安装失败（bundle 不一致） | 第 2.1 步：自签工程 bundleName 必须 = `com.example.opendotnet` |
| `9568257`（未重签）/ `9568344`（profile 未绑 UDID） | 属预期：按第 2 节重签后再装 |
| 有 `BLZ_BOOT` 无 `BLZ_RENDERED`（首帧超时） | 先看 `BLZ_ERROR` 原文：多为 WASM/ArkWeb 能力或 rawfile 供给；原样回传 hilog + 截图 |
| 白屏排查序 | ① `aa start` 已启动 → ② 有 `BLZ_BOOT`（宿主页面已载）→ ③ 看 `BLZ_ERROR` → ④ 截图 + `blazor-hilog.txt` 回传 |
