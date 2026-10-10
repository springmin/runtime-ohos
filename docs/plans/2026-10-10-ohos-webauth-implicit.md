# WEBAUTH-IMPLICIT：隐式 skill 投递执行轮——设备恢复，但锁屏 10106102 阻断（2026-10-10）

> 设备已恢复（hdc `127.0.0.1:36823`，daemon 正常；stock hdc 可用）。本 session 执行 A 组隐式投递两轮，
> **均在 `aa start` 处被锁屏拦截（10106102），判据未判定（≠ 投递失败）**；需**人工解锁**后原样重跑
> （脚本就绪、两处已修）。产品代码/#49–#53/kit 不动；fixture 已还原、锁已释放、无残留窗口。

## 1) 执行与结果（probe hap `beb55074…` 两轮均安装成功）

- 轮 1（12:43，无解锁门）：cold start 后 `pidof` 为空；hops file/http/data/neg 全 NO-PASS。
- 轮 2（12:57，带解锁门）：门 ×8 失败 → `BLOCKED: screen locked, app cannot start`；hops 全 blocked；
  SUMMARY `implicit_ok=N neg_ok=N pending_lines=0 dispatch_kind0=0`；随后 fixture `f75dfc91…` 还原。
- 证据：`…/opencode/webauth-implicit/evidence/{summary.txt,hop-log.txt,live-hilog.txt,prelock.jpeg,lockfail.jpeg}`。

## 2) 根因（已知平台限制 D6，非 WebAuth 功能问题）

- `aa start` 实测：`Error Code:10106102 ... The device screen is locked during the application launch,
  unlock screen failed. Error cause: The current mode is developer mode, and the screen cannot be
  unlocked automatically`（hilog `C01303/aa/AATool`）。
- 锁屏为 **springmin 密码锁**（`prelock.jpeg`：密码输入框 + 指纹提示）；滑动/Enter/空密码点击均不可解锁
  （`probe-unlock.jpeg` 仍为锁屏）；与 `2026-10-03-ohos-screen-interference.md` §5 一致：**须人工解锁**。

## 3) 顺带修正（仅脚本，非产品代码）

- 浏览器隐式打点须用 `-A ohos.want.action.viewData`；`-a` 是 ability 名（缺 `-b` 时 aa 打印 usage）——
  轮 1/2 的 viewData 实际未发出，已修 `device-round.sh`。
- 路径计划：`file:///data/local/tmp/wa-implicit.html` → loopback `http://127.0.0.1:8789/implicit.html`
  → `data:` 三档，逐档 fresh pending；负控 `myapp-nope://`；判据 = 不经 `aa start -U myapp://`，
  hilog 出现 `[webauth-probe] webauth: ok code=SECRET-IMPLICIT state=st-implicit`。

## 4) 重跑入口（人工解锁屏后一条命令）

- `sh /data/storage/el2/base/tmp/opencode/webauth-implicit/device-round.sh`
  （自带锁/常亮/16M hilog/解锁门/还原 fixture `f75dfc91…` + 启动/释放锁；日志 `round-consoleN.log`）。
- 若解锁后浏览器（`com.huawei.hmos.browser`）仍不把 `myapp://` 交给系统 skill 分发，则按任务预期记录
  **浏览器拦截边界**（截图 + hilog）；app-link https 路径同样依赖解锁后的同一流程。
