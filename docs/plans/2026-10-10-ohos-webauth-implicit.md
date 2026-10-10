# WEBAUTH-IMPLICIT：隐式 skill 投递真机验证通过（2026-10-10）

> 设备 HAD-W32 / OH 7.0.0.109 / API26 / hdc `127.0.0.1:36823`；probe hap `beb55074…`（kit4）。
> 构造 = 设备 loopback HTTP 页（`serve.mjs 8789`，meta refresh + JS 跳
> `myapp://callback?code=SECRET-IMPLICIT&state=st-implicit`）→ 系统浏览器 → 系统「选择打开方式」→
> `uitest dumpLayout` **文本定位点选** `com.example.hellomauiapp`（不盲点/不显式投递）。
> **判据通过**：不经 `aa start -U myapp://…`，App 经 skill 匹配收到回调并完成
> `[maui] status: [webauth-probe] webauth: ok code=SECRET-IMPLICIT state=st-implicit`（点击后 7s，×4）。
> 负控通过；fixture `f75dfc91…` 已还原；锁已释放。证据：scratch `…/webauth-implicit/evidence-final2/`。

## 1) 隐式链证据（final2，17:17–17:18）

- 页加载后浏览器 `com.haitai.htbrowser`（viewData 默认处理者）：
  `ExternalProtocolAdapter#openExternal("myapp://callback?code=SECRET-IMPLICIT&state=st-implicit")`（openExternal=8）。
- 系统层：`ADVMgrClient [(IsValidUrl)] scheme:myapp is not https` + `AMS implicit_start_processor failed`
  → **不自动拉起**，改为弹「选择打开方式」chooser（列出 `com.example.hellomauiapp` + `com.example.webauthprobe`
  = **manifest skill 匹配成立**）。
- `chooser entry at [1560 878]` 点击 → App 激活日志
  `activation seq=3 uri='myapp://callback?code=SECRET-IMPLICIT&state=st-implicit' action='ohos.want.action.viewData'`
  → probe `ok`（`summary.txt`: `PASS implicit delivery (ok +1 after 7s)`；`pending=8`）。
- 截图：`evidence-final2/chooser-final.jpeg`（chooser 含本 App 条目）、`implicit-final.jpeg`。

## 2) 负控（未注册 scheme）

- 同构页跳 `myapp-nope://callback?code=NEG&state=neg`：页面已加载（`checkUrlSafety(http://…/wa-implicit-neg.html)`），
  浏览器 **未转发**（`myapp-nope` 0 次、无 chooser、无激活、无 `ok code=NEG`）。

## 3) 平台边界 / 替代

- 平台对**非 https 自定义 scheme 的隐式启动**：`IsValidUrl … not https` 拒绝自动拉起，再以 chooser 交用户确认；
  点选后按显式 element start 交付——**本平台自定义 scheme 的隐式口径**（app-link https 才可能免确认）。
- `file://`/`data:` 打点被 `IsValidUrl` 拒绝（`scheme:file`/`scheme:data is not https`）；**loopback http 页可行**。
- 同 scheme 多 handler（hellomauiapp + webauthprobe）时 chooser 必现；真实端点一跳（https 302）仍受无公网限制。

## 4) 重跑 / 排障备注

- 一键：`sh …/webauth-implicit/device-round-final2.sh`（自带锁/常亮/16M hilog/还原；chooser 文本定位点击）；
  锁屏 `10106102` 快速失败，需人工解锁。
- 排障：浏览器隐式打点须 `-A ohos.want.action.viewData`（`-a` 是 ability 名）；cold start 后需 ~8s settle
  再触发 `app://webauth/start`（否则 probe 未订阅、pending=0）；toybox sh 不支持 `$(( $(cmd) ))` 嵌套。
