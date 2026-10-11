# MEDIA-Q1-PROBE：ArkWeb 媒体生死门真机探针（2026-10-11，Q1 绿）

> 设备 HAD-W32 / OH 7.0.0.109 / API26 / hdc 127.0.0.1:36823（锁内；常亮；hilog 16M→512K；端口扫 8791 free）。
> 路线 A = 系统浏览器 ArkWeb + loopback 页（`bun serve.mjs 8791`，页内 `fetch /report` 回传）；路线 B = 应用内嵌 ArkWeb
> （探针 hap `af078f4d…`：`-p:MediaWebProbe=true -p:OpenHarmonyFeatures=network -p:OpenHarmonyUIPage=pages/Index
> -p:OpenHarmonyArktsModulesAbc=<repo>/packs/…/preview.28/templates/ets/modules.ui.abc`（C5 `#` 修复件；缺则 loadData 在首个 `#` 截断）；
> `app://media/webprobe` → 模态 WebView，页内自报回 ::8791/report）。证据：scratch `/data/storage/el2/base/tmp/opencode/media-q1/`
> （evidence*/report.log、app-hilog.txt、截图、kit3）；重跑 `round-browser.sh`、`round-app.sh`（KEEP=1 后 `restore.sh`）。T20 A/B 复验：
> `[media-probe] load status=Unavailable message='the platform answered -1'`（C1 维持；ArkWeb 解码走 Chromium→av_codec_service，不经 MediaKit）。

## 1) canPlayType / MSE 原文（应用内 = Chrome/144.0.0.0 ArkWeb/7.0.0.109；括号 = 浏览器 Chrome/132 不同处）

- canPlayType：mp4=maybe · avc1.42E01E / avc1+mp4a.40.2 / avc1.64001F / hvc1=probably · audio mp4a.40.2 / mpeg / mp3 / wav(1) / ogg-vorbis / webm-opus=probably · webm vp8 / vp9=probably · theora=(empty) · HLS apple=maybe[132 empty] · x-mpegURL=maybe[132 empty] · audio/mpegurl=maybe[132 empty] · mp2t=(empty) · application/mpegurl=(empty) · aac / flac=probably。
- MSE：`MediaSource=function`、`ManagedMediaSource=undefined`；isTypeSupported avc1(+mp4a) / avc1.64001F / hvc1 / mp4a.40.2 / audio-mpeg / opus / vp8 / vp9 / aac=true；mp3 / wav / ogg-vorbis / flac / HLS×3 / mp2t=false[132 mp2t true]；`sourceopen=open`。

## 2) 实际播放（判据 currentTime/事件/无手势）

- 应用内 embedded H.264/AAC 360x240 1.0s：`loadedmetadata dur=1.00 vw=360x240` → `play() resolved` → `ended ct=1.00 err=none`；平台 `[h.vdec] Init→Configure 360x240→Start success→OnOutputFormatChanged NV12→[in]/[out] first buffer→running→EOS`（硬解出帧、播完）。
- 浏览器：h264-aac-good 1.0s ct=1.02；long-test 30.03s@854x480 ct=12.02；counting.webm 9.83s ct=8.01；mp3 0.55s 播完；全 err=none（≥5s 连续）。
- 无手势：muted **video** 放行（两处）；**audio-only 一律被拒**（muted 与 unmuted 均 `NotAllowedError: play() failed because the user didn't interact…`，两处一致）；受信 `uitest uiInput click` 后未静音 tone `ct=6.00 ended=true` + `OHAudioRenderer` 创建 + `audio_server AudioVolume AddStreamVolume sessionId=100138`（浏览器；应用内点击未达成，见 §3）。
- 应用内 loopback：`fetch /state=200`（INTERNET 生效）；`counting.mp4`（mp4v=MPEG-4 Part 2）`err=4 不支持`（编解码，非网络）。
- 平台服务在：AudioPolicyService / AVCodecService / AVSessionService / PlayerDistributedService / MediaKeySystemService（`hidumper -ls`）。

## 3) 判定与 A-M1 依据

- **Q1 绿**：本镜像 ArkWeb（Chrome 132/144 两实例）可解/可播 H.264（硬件 vdec）+ VP8/9 webm + MP3/WAV(手势)；MSE 可用；A-M1 放行依据成立；音频管线与浏览器同栈（audio_server）。
- 条件/红线：HLS 不支持（m3u8 须 MSE+HLS.js 或砍掉）；无手势出声被平台手势门拦（audio-only 连 muted 也拦）→ A-M1 必须处理首击或壳侧 `mediaPlayGestureAccess(false)`（壳当前未设任何媒体选项）；MPEG-4 Part 2 不支持。
- A-M1 形制：**模态页 WebView 在切片中视口恒 1×1**（DOM/网络/媒体可跑但不出画不可点，`VISIBLE w=1 h=1`）→ 必须走 overlay 槽 WebView（预研 A 路线；Hybrid/Blazor 先例可渲染/可交互），并配 C5 修复壳 abc；`HeightRequest`/单子页都未改变 1×1。
- 本探针范围=2in1 debug 域；release/手机不外推；探针 hap/脚本为 scratch，仓内仅增本文。
