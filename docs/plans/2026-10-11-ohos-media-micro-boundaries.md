# MEDIA-MICRO：弹窗媒体 + m3u8 Range（两项微边界补全，2026-10-11）

> 设备 HAD-W32 / OH 7.0.0.109 / API26 / hdc 127.0.0.1:36823（锁协议；轮末 fixture 已恢复、hilog 还原、锁释放）；#49–#53 资产未动。
> 载体 ow `feat/media-micro`（`a118ed8`；合流 `1d7ec00`）；maui 零改动（pin `54631780a3` 不变）；普通推送、禁强推。
> 套件 **793/796 floor 776 assert=True**（+5 MEDIA-MICRO pin；红控 3：移除多区间拒绝→parser=False、移除页面 `?hls=1`→pins=False、移除页面读取→stamp=False，均 rc=134）。
> abc **623,732/`98aa6e7a…`**（headless 24,324 不变）；四包 byte-identical；verify-kit EXPECT 重锚；证据 scratch `mediamicro/{device,evidence,server}`（hap `be8f0bf4…`）。

## 1) ① 弹窗媒体（判定 = 仅"弹窗页可用媒体源"，不接命令/同源服务/MediaElement 映射）

- 判定（代码）：弹窗会话 `web:N`/kind=popup 无托管树/面、非命令目标（`findSubWindowSession` 只认 managed），MediaElement 与 `media` 命令无从挂接；缺口 = 弹窗 Web 是壳内唯一未 opt-out 手势门的 Web 面（主 overlay/子槽均已 opt-out）。
- 实现：`SubWindow.ets` 弹窗 Web 增 `.mediaPlayGestureAccess(false)`（`L8-POPUP (MEDIA-MICRO)`）；kind=popup 隔离（无 claim/托管 wire/media origin）、容量与 `window.close`→destroy 释放链不动。
- 真机：`app://web/popupmedia`（hybrid A `window.open('http://127.0.0.1:8791/popmedia.html')`）→ 服务端链 `popmedia.html→ready→sample.mp4(range=bytes=0-)→loadedmetadata dur=1 size=360x240→playing→play-resolved→ended t=1.00 dur=1.00`（无 NotAllowedError，无第二次弹窗内手势；截图为辅）。

## 2) ② m3u8 Range（/__src__ 单区间 + 播放列表 sibling + rawfile HLS 路由）

- `/__src__`（主/子同规）读请求 Range：单区间 `bytes=a-b|a-|-suffix` → **206 + `Content-Range` + `Accept-Ranges: bytes`**（end 截断）；外国单位/多区间/畸形/越界 → **416 + `bytes */size`**（fail-closed）；200 整答带 `Accept-Ranges`；≤64MB + 扩展名 MIME + fd finally 释放保留；206/416/sibling 有界日志 16/slot。
- 本地 m3u8：注册位置 `.m3u8` 时同源 sibling 路径解析到播放列表目录（rawfile/沙箱；解码后拒绝 `..`/`\`/空段/超长），走同一 Range/MIME 路径；壳把播放列表写进页面 query（`?s=N&hls=1`）并注入 `window.__ohMediaHls`，页面据此让无扩展名的 `/__src__` 走 hls.js（`.m3u8` URL 路径检测保留）。首轮实测暴露 page-end 注入与 load eval 的竞态（页面原生拉取 `/__src__`），query 标记为确定性修复。
- 真机：`app://media/element/hlslocal`（CMAF 分段：`video.m3u8`+`init-all.mp4`+`v-0.m4s` sibling）与 `/hlsrange`（单文件 byte-range：`byte.m3u8`→`all.mp4` BYTERANGE）均 `ended=True state=Completed pos=999ms dur=999ms size=360x240`；206 行 `media range (slot 2): bytes=0-789 -> bytes 0-789/39739`、`bytes=790-39738 -> bytes 790-39738/39739`。

## 3) 零回归 / 门禁

- A-M1 主窗短样 `after-play ended=True pos=1000ms dur=1000ms size=360x240`、pause/seek/volume/stop/槽释放照旧；B-M1 子窗 `cm after-play ended=True pos=1000ms` + `cm close released=True win=sub-1 slot=0`；pid 12844 恒稳、fault 0→0。
- 离线：arkts selftest 207/0、verify-kit selftest 129/0；preflight --quick PASS（repo gates + sh -n 56 + lint 0）；CI 5/5（interaction `38124458426` / pixel `38124458402` / host-export `38124458406` / ridgraph `38124458400` / markdownlint `38124458392`）+ harmony-flavor dispatch（`38124503393`）；cut-kit P0 dry-run PASS。

## 4) 边界 / 余项

- 弹窗仍无托管 MediaElement 映射（设计内）；sibling 服务仅在"注册为播放列表"时开放（目录即边界）；Range = 整流读 + 切片（≤64MB 内，未做 fd segmented read）。
- 多文件分段本地 m3u8 依赖 sibling 解析（无 playlist 改写）；modal overlay 像素余项沿用 A-M1；#49–#53 未动；kit #54 未切（rc.2 WAIT）。
