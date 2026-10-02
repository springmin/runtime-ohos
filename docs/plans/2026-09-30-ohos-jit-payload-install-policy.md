# 本机镜像拒绝 JIT payload-in-libs 的根因与对策（JIT-PAYLOAD-POLICY，2026-09-30）

> **2026-10-02 更新（DEVCOMPAT-DEFAULT）**：打包侧已把本轮对策从可选改为**默认开启**——
> `OpenHarmonyHapPayloadInLibsDeviceCompat` 默认 `true`（ohos-workload 全 7 个 preview pack 副本
> 同源）：默认构建即把 libs 内无扩展名文件落为 `.so`/`.bin`、恰 4096 B 文件补 4 B（`dotnet.zip`
> 保原名原字节，marker 计数/语义不变），构建输出加一行状态；`-p:...DeviceCompat=false` 保留为
> 逃生口（原名原字节 + 告警点名）。默认构建的本机 enforcing 安装/启动复测见
> `docs/plans/2026-10-02-ohos-payload-sign-default.md`。

> 设备：HAD-W24 `7.0.0.111(SP3ENTC293E104R2P1log)`（API 26，UDID `1BCE13C8…AEA0`，无线 hdc `127.0.0.1:35111`）。
> 证据 scratch：`/data/storage/el2/base/tmp/opencode/lo-c/`（各轮 `e*-install-stream.txt` 安装流日志、探针
> `test/e*-signed.hap`、离线签名器解析脚本）。背景：kit #33/#34 JIT hap（`libs/arm64-v8a/` 270 文件）本机
> `hdc install` 报 `9568393 verify code signature failed`；tester 机（7.0.0.105）可装；AOT / 无 payload-in-libs
> hap 本机可装。未改发布资产（kit 未重切）。

## 1. 复现（本机，kit #34 JIT 重签件）

- `hdc install -r` → `error: failed to install bundle. code:9568393 error: verify code signature failed`。
- hilog `CODE_SIGN`（C05A06）链：`SaveHapToInstallPath:7022 codesign start` →
  `EnforceCodeSignForAppWithPluginId … entryPathMap size:270` →
  `ParseNativeLibSignInfo: Libs signature not found: signMap_ size:270, signMapPreSize:1` →
  `enable code signature failed: 8519738` → bm `9568393`。HAP 级签名有效（`hap-sign-tool verify-app success`），
  排除签名链/UDID/profile/minAPIVersion。

## 2. 差异点（A/B 与探针）

- **“镜像拒 libs 内非 ELF”旧结论不成立**：AOT v3 hap 的 libs 含 10 文件（json/js/txt 非 ELF）本机安装成功，
  逐文件 `EnableCodeSignForFile … ret=0`。
- **陷阱 1（无扩展名）**：HAP 码签块 `NativeLibInfoSegment` 里 AOT 10/10、JIT **269/270**——`libs/arm64-v8a/createdump`
  缺失。SDK `hap-sign-tool -signCode 1` 只签**带扩展名**的 libs 条目（离线探针：`noext/UPPERDL/createdump` 全漏，
  `foo.bin/tiny.so/*.json/wwwroot/**` 全签）。
- **陷阱 2（恰好 4096 B）**：逐文件使能对**大小恰为 4096 B** 的文件 `ret=-768`（`CS_ERR_ENABLE`），与内容无关
  （4095/4097/8192 B 与 MZ/ELF/文本探针均过；kit payload 的 4096 B `Microsoft.OpenHarmony.dll` 命中）。

## 3. 判定

- 属**镜像策略差异**：≥7.0.0.111 起装入强制“libs 内每个文件都有逐文件代码签名并使能 fs-verity”；无扩展名文件
  拿不到签名条目、单块（4096 B）文件使能失败。7.0.0.105 无此强制 → tester 可装。
- 本机同签名链复装验证：E6 = `createdump`→`createdump.so` + `Microsoft.OpenHarmony.dll` 4096→4100 B → **OK**；
  E7 = `OpenHarmonyHapPayloadInLibs=false` 布局（载荷只在 dotnet.zip，宿主 symlink 桥）→ **OK**。

## 4. 对策

- **打包（已实施，ohos-workload；DEVCOMPAT-DEFAULT 后默认 true）**：`OpenHarmonyHapPayloadInLibsDeviceCompat`
  默认 `true`：staging 把无扩展名文件落为 `.so`（ELF）/`.bin`（其它）、把 4096 B 文件补 4 B；dotnet.zip 保持
  原名原字节，码签（OpenHarmonyCodesign）随后覆盖补丁后的 ELF；构建输出一行状态。`false` 为逃生口（原名原
  字节 + 不兼容文件点名告警），不会静默出货坏包。
- **设备复测**：JIT 真机判定仍以 tester 7.0.0.105 为准；≥7.0.0.111 上测 JIT 用 DeviceCompat 重写包或
  `-p:OpenHarmonyHapPayloadInLibs=false` 重出包；AOT（aot-haps-v3）不受影响。

## 5. 不确定项

- 4096 B 陷阱仅在本镜像逐点实测（4095/4097/8192 通过），其它 enforcing 版本是否同规则未验证。
- 未验证 7.0.0.105 对重写包（改名/补字节）的接受度（预计兼容，未实测）；本机 JIT 启动证据未取得（设备锁屏，
  `aa start` 10106102）。
- “只签带扩展名条目”为对 SDK 二进制行为的反推（离线探针 + 码签块解析），未见公开文档。
