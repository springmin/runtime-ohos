# Blazor WASM → ArkWeb 承载 demo（2026-09-28）

**目标：** 把设备端 `dotnet publish` 产出的 Blazor WASM 静态站点，用最小的 ArkTS HAP（ArkWeb `Web` 组件）承载。
**结论：** 站点服务与 WebView HAP 两侧**都已在本机构建成功**（HAP 已签名、`verify-app` 通过）；并已产出**自包含变体**（站点内嵌 `resources/rawfile`、`onInterceptRequest` 直供，无需本地服务；宿主工程 dev-only、声明 `ohos.permission.INTERNET`，运行时 rawfile 直供、不需要联网；重签后声明是否保留取决于签名工程），见 §3。真机渲染验证需在带 UI 且可 `hdc` 安装的设备上进行。

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

## 3. 自包含变体：rawfile + onInterceptRequest（已构建 + 签名 + 验证）

站点整包（71 MB / 899 个文件）内嵌进 `resources/rawfile/blazor/`，页面用
`Web.onInterceptRequest` 同步读 rawfile 应答（`ResourceManager.getRawFileContentSync`），
不依赖本机服务；宿主工程 dev-only、声明 `INTERNET`（运行时 rawfile 直供、不需要联网；重签后是否保留取决于签名工程）：

```ets
const ORIGIN: string = 'https://blazor.local/';   // 拦截的伪源
Web({ src: ORIGIN, controller: this.controller })
  .onInterceptRequest((event) => {
    const url: string = event.request.getRequestUrl();       // https://blazor.local/<path>
    if (!url.startsWith(ORIGIN)) return null;                // 其它请求不拦截
    let path: string = url.substring(ORIGIN.length);         // -> rawfile blazor/<path>
    // 去查询串/片段；空路径与未命中都回退 index.html（SPA 路由）
    const bytes: Uint8Array = rm.getRawFileContentSync('blazor/' + path);
    const resp: WebResourceResponse = new WebResourceResponse();   // 全局 ArkUI 类型
    resp.setResponseCode(200);
    resp.setResponseMimeType(mimeTypeOf(path));              // .wasm -> application/wasm
    resp.setResponseEncoding('utf-8');
    resp.setResponseData(bytes.buffer as ArrayBuffer);
    return resp;
  })
```

实测与坑：

- 构建/打包/签名/验证全通过：`CompileArkTS` → 原生 `ohos_packing_tool` pack →
  `hap-sign-tool sign-profile/sign-app/verify-app`；HAP **69.5 MB / 908 成员（899 rawfile）**，
  `verify-app success`。
- `WebResourceResponse`/`Header` 是 `component/web.d.ts` 的**全局声明**，不在
  `@kit.ArkWeb` 的 `webview` 命名空间里（`webview.WebResourceResponse` 会编译失败）。
- API 26 另有 `setWebSchemeHandler`（自定义 scheme，`WebSchemeHandler/WebResourceHandler`），
  本次选了 `onInterceptRequest`：产品内 HybridWebView/BlazorWebView 资产桥就是这条路径
  （`packs/Microsoft.OpenHarmony.Sdk/<ver>/templates/ets/pages/Index.ets` 的 `serveBlazorFile`）。
- 承载页保持仓库 ArkTS 合约：仅 `@kit.*` 导入、无全局 `getContext()`、无 `@ohos.*` 动态导入。
- **本机环境陷阱**：OpenHarmony 环境导出 `NODE=/data/service/hnp/bin/node`（v24），该 node
  跑 hvigor 会在启动期崩（V8 `Check failed: 12 == (*__errno_location())`，表现为
  `hvigor.log` 只有 174 字节的 fatal 输出）。用 `~/.harmonybrew/bin/node`（v26.8.1）即可；
  固化的 `pack-host.sh` 默认避开 hnp node。

**固化资产（ohos-workload 仓）**：
- `test/hello-blazorwasm/`：最小 Blazor WASM 工程 + `run-smoke.sh`（发布 + 站点校验；
  dnceng rc.2 flight 与 task-host override 配方见其 README）
- `test/hello-blazorwasm/arkts-host/`：本变体的 ArkTS 工程 + `pack-host.sh`
  （stage → 内嵌站点 → hvigor → 原生打包 → 签名 → 验证；`--bundle`/`SIGN_*` 可换签名材料）

## 4. 未做 / 待办

- **ArkWeb 渲染验证**（需真机 UI）：`wasm` 加载、`fetch`/`instantiateStreaming`、可选多线程（COOP/COEP）、Service Worker
- `.br`/`.gz` 协商（当前直接提供未压缩同名文件；站点同时带压缩副本，后续可按 `Accept-Encoding` 加 `Content-Encoding`）
- hvigor 插件与 SDK 版本对齐（消除手动打包步骤）
- 与 P0-①（TaskHostFactory 根因）无关：后者影响 wasm **构建**（修复已随 sdk-ohos
  `feature/openharmony` 发布，Roslyn 编译器服务器同修；见
  `2026-09-28-msbuild-taskhost-pipe-rootcause.md`）
