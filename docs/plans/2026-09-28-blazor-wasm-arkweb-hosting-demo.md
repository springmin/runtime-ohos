# Blazor WASM → ArkWeb 承载 demo（2026-09-28）

**目标：** 把设备端 `dotnet publish` 产出的 Blazor WASM 静态站点，用最小的 ArkTS HAP（ArkWeb `Web` 组件）承载。
**结论：** 站点服务与 WebView HAP 两侧**都已在本机构建成功**（HAP 已签名、`verify-app` 通过）；真机渲染验证需在带 UI 且可 `hdc` 安装的设备上进行。

## 1. 站点侧（已实测）

发布产物（发布配方见 `2026-09-28-blazor-wasm-on-device-feasibility.md`）：
`bin/Release/net11.0/publish/wwwroot`，`_framework/` 753 个文件，资源为**指纹命名**（如 `dotnet.native.ti998mcjzr.wasm`）。

服务脚本 `serve-blazor.py`（Python 标准库，无依赖）：
- `.wasm` → **`application/wasm`**（`instantiateStreaming` 需要；否则 Blazor 退化为 ArrayBuffer 加载）
- `.br`/`.gz` 按 `Accept-Encoding` 协商返回，附 `Content-Encoding`

实测（curl，服务在 `127.0.0.1:8199`）：

```
$ curl -sI http://127.0.0.1:8199/_framework/dotnet.native.ti998mcjzr.wasm
HTTP/1.0 200 OK
Content-type: application/wasm
Content-Length: 3149604

$ curl -sI -H "Accept-Encoding: br" .../dotnet.native.ti998mcjzr.wasm
HTTP/1.0 200 OK
Content-Type: application/wasm
Content-Encoding: br
```

## 2. 承载侧（已构建 + 签名 + 验证）

最小 ArkTS 工程（以 ohos-workload 的 `.arkts-build/project` scaffold 为底，去掉 `libopenharmonyhost.so` 依赖）：

`entry/src/main/ets/pages/Index.ets`
```ets
import web_webview from '@ohos.web.webview';

const BLAZOR_URL: string = 'http://127.0.0.1:8199/';

@Entry
@Component
struct Index {
  controller: web_webview.WebviewController = new web_webview.WebviewController();

  build() {
    Column() {
      Web({ src: BLAZOR_URL, controller: this.controller })
        .width('100%')
        .height('100%')
        .javaScriptAccess(true)
        .domStorageAccess(true)
    }
    .width('100%').height('100%')
  }
}
```

`entry/src/main/ets/entryability/EntryAbility.ets`：仅 `windowStage.loadContent('pages/Index', ...)`；`module.json5` 增加 `requestPermissions: [{ name: 'ohos.permission.INTERNET' }]`。

### 构建链与两个环境坑
1. `hvigor assembleHap`：**`CompileArkTS` 通过**（产出 `.../loader_out/default/ets/modules.abc`）
2. `PackageHap` 失败 `00308018`：hvigor 插件调用 `$SDK/toolchains/lib/app_packing_tool.jar`，而 SDK `26.0.0.18` 提供的是**原生** `ohos_packing_tool`（版本错配，workload 的脚本同样容忍此步）
   - 规避（实测可用）：直接调用原生工具（参数与 hvigor 调试日志一致）：
     ```sh
     "$SDK/toolchains/lib/ohos_packing_tool" pack --mode hap --force true \
       --lib-path .../stripped_native_libs/default \
       --json-path .../package/default/module.json \
       --resources-path .../res/default/resources \
       --index-path .../res/default/resources.index \
       --pack-info-path .../outputs/default/pack.info \
       --out-path .../outputs/default/entry-default-unsigned.hap \
       --rpcid-path .../syscap/default/rpcid.sc \
       --ets-path .../loader_out/default/ets \
       --pkg-sdk-info-path .../loader/default/pkgSdkInfo.json
     ```
3. 签名（复用 SDK 的调试材料，思路同 workload 的 `templates/scripts/sign-hap.sh`）：
   - `hap-sign-tool sign-profile`：`UnsgnedDebugProfileTemplate.json`（bundle 名 `com.example.opendotnet`，有效期 10 年）→ `debug.p7b`
   - `hap-sign-tool sign-app`：`OpenHarmony.p12` / `OpenHarmonyApplication.pem` / `debug.p7b` → `entry-default-signed.hap`（102 KB）
   - `hap-sign-tool verify-app` → `verify-app success`
   - HAP 内容：`ets/modules.abc`、`module.json`、`resources.index`、`resources/base/profile/main_pages.json`、`rpcid.sc`、`pack.info`

### 安装/启动（需在带 UI 的主机执行；本环境无 `hdc`/`aa`）
```sh
hdc install entry-default-signed.hap
aa start -b com.example.opendotnet -a EntryAbility
# 设备上需先运行站点服务（或把 BLAZOR_URL 指向可达地址）：
#   python3 serve-blazor.py <publish>/wwwroot 8199
```

## 3. 未做 / 待办

- **ArkWeb 渲染验证**（需真机 UI）：`wasm` 加载、`fetch`/`instantiateStreaming`、可选多线程（COOP/COEP）、Service Worker
- **站点与 HAP 一体化**：把 `wwwroot` 打进 HAP `resources/rawfile` 并用 `onInterceptRequest` 提供 `application/wasm`（免依赖 127.0.0.1 服务），或应用内起本地服务
- hvigor 插件与 SDK 版本对齐（消除手动打包步骤）
- 与 P0-①（TaskHostFactory 根因）无关：后者影响 wasm **构建**，承载侧不涉及
