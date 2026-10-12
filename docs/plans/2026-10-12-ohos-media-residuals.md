# MEDIA-RESIDUALS：hlsrange BYTERANGE fragLoadError + 冷启首 ack 竞态（2026-10-12）

> 设备 HAD-W32 / OH 7.0.0.109 / hdc 127.0.0.1:36823（锁独占 `mediaresiduals`、常亮 6 h、hilog 16M→512K 还原、fixture `l7m2-s2` 回装 + 锁释放）；#49–#54 资产未动；本 session 不处理上游 PR。
> 载体：ow `fix/media-residuals`（`f66d67c`→**`d7df09c`**，已 FF 并入 master）；maui `fix/media-residuals`（`36da77cba4`→**`44dcef8d15`**，已 FF 并入 feature/openharmony）；干净 AOT 探针构建（`DOTNET=~/.dotnet.rc2-fix`，无手补）；abc **不变 623,784/`58c5829b…`**。

## ① hlsrange `fragLoadError`：根因（平台边界）/ 修法（页面侧规避）

- 证据链（设备 hilog）：hls.js 对单文件 BYTERANGE 播放列表发 `Range: bytes=0-789`（map）与 `bytes=790-39738`（媒体段，共 39739B）。ArkWeb CEF `StreamReaderURLLoader::OnInputStreamOpened` 对非零首偏移先 `Skip(790)`；`NWebResourceHandler::Skip` 只处理 `NWEB_RESOURCE_URL_TYPE`/`NWEB_FILE_TYPE`，壳用 `setResponseData(ArrayBuffer)` 应答 = `NWEB_BUFFER_TYPE` → 落到 `CefResourceHandler::Skip` 基类默认（`bytes_skipped=-2/false`）→ `InputStreamReader::SkipToRequestedRange` → `RunSkipCallback(net::ERR_REQUEST_RANGE_NOT_SATISFIABLE)`（**-328**），请求在 `GetResponseHeaders` 之前即死。
- 旁证：`bytes=0-789`（skip=0）通过——`NWEB_BUFFER_TYPE response_length=790` + `HeadersComplete … status_code=206 … content_length=790`；随后 `InterceptedRequest id 169981, OnDestroy for error_code: -328`（`proxy_url_loader_factory.cc:1603`）→ hls.js `fragLoadError`。服务端两次 206 头均正确（`0-789/39739`、`790-39738/39739`）；`all.mp4` = `hlslocal/init-all.mp4`+`v-0.m4s` 逐字节等价（sha 复核），即内容侧无 defect。
- 修法（ow 四包 `media.html` 同步，hls.js `fLoader`）：`LocalSliceLoader` 对**同源 arraybuffer 区间**请求去掉 Range 整取一次（壳 200 全量），本地 `slice(rangeStart,rangeEnd)` 后 `onSuccess`（stats 记切片长、单条缓存、`destroyHls` 清缓存、`local-slice` 诊断事件）；远端 origin 原样走 stock loader。壳 206/Content-Range 语义保留（对能消费它的客户端仍正确）；≤64MB/MIME/sibling 边界不动；node 单测（纯 JS 合成外层）切片逐字节相等。
- 真机判据：hlsrange `opened=1` + `after-play ended=True state=Completed pos/dur=999/999ms` + 壳侧仅 **2 次整取** `media sibling all.mp4` + `media range`=0 + `fragLoadError`=0。

## ② 冷启首 ack `Unavailable`：根因（slice 侧竞态）/ 修法（有界等待）

- 根因：冷启 `PlayAsync` 紧跟 `SetSource→Register`（shell 正在载页，`_pageReady=false`）→ `RunCommandAsync` 命中 `!IsSupported || !_pageReady` → `Unavailable`（"the media page is not ready"）；页面 `ready` 后 `HandleReady` 重放 play（所以仍能播，但首 ack 不是页面的答案）。
- 修法（maui slice `OpenHarmonyMediaElement.cs`）：`PlayAsync` 先 `WaitForPageReadyAsync()`（50 ms 轮询、上限 1500 ms），仅当"已附加+有源+注册在飞"时武装；无源/已 detach/无页可等 → 立即 `Unavailable`（离线/降级语义不变）。
- 真机判据：两遍冷启首遍均 `me play status=Success message=''`（短样与 hlsrange 各一次；旧态 5/5 复现 Unavailable）。

## ③ 验证 / 零回归 / 门禁

- 静态：unsigned `2a155b45…`/23,455,150 与签后探针 `c59b7908…`/23,885,159 两处断言 PASS——`media.html` **23,043/`9733ce4d…`**（pack 自动入包，无手补）+ slice-loader 标记、`hls.min.js` 619,692/`a12e7ee1…`、`runtime-mode=aot`、abc 623,784/`58c5829b…`、`myapp://callback`/INTERNET。
- 真机（round 09:05–09:12，两遍）：① 冷启短样全链（play/opened/ended/transport/audio/stop/close）；③ hlslocal `ended=True`（回归）；③ hlsrange `ended=True Completed`（修复目标）；`fault-new=0`、pid 恒稳（41253/50311 全程）、fixture 还原 + hilog 512K + 锁释放。
- 离线：maui-platform-verify **checks=798 floor=781**（+2 MEDIA-RESIDUALS pin）；红控 2（去 `fLoader` 接线→page pins=False；去 `await WaitForPageReadyAsync()`→coldstart=False，均 rc=134，已还原）；`lint-packs` OK。
- 旁注：壳的 status 文件镜像（12×3s）本轮未捕获到 `local-slice` 行（CEF stderr 洪泛/窗口限制）——不影响判据：壳日志「整取 2 次 + 0 次 Range + 0 fragLoadError + 播放到 Completed」唯一定位 slice 路径。
- 证据：scratch `…/opencode/mediaresiduals/`（build.log、assert-static-{unsigned,probe}.txt、summary{,2}.txt、round{,2}.log、passA-hlsrange/passB-short/passC-hlslocal lines、截图、fault diff）；提交 = 本文件 + README 行（runtime）、ow `d7df09c`、maui `44dcef8d15`（三仓 origin 已推）。
- 不确定项：平台若给 intercepted BUFFER 型补齐 Skip（或改走 fd/Resource 应答）可让页面回归原生 Range；当前规避对同源单文件源整取一次（单条缓存，≤64MB 内），多文件源按 URL 失效。
