# WEB-AUTHENTICATOR：Essentials WebAuthenticator 真流程 + 壳 want 构造缺陷（2026-10-09）

> 口径：maui `feat/webauthenticator` @ `2803e15b6c`（基 `b914379269`）· ow `feat/webauthenticator` @ `b49ea76`（基 `ca94b55`）；均普通推送、未并主线、未强推。离线：套件 **745/748 floor 728**（+8 WEB-AUTH，declared==printed、0 Unhandled、红控 ×2 rc=134）、tasks-tests **169/0**、selftest-hap-targets **85/0**（1 skip=T6 设备件未附）；真机 HAD-W32（互斥锁，已释放）。**新壳 abc 542,840 B / `cba85801…`**（原 542,936 / `f18f0855…`）。#49–#53 资产不动、不切 kit。

## 1) 实现（maui 切片 `OpenHarmonyWebAuthenticator.cs`）

- `AuthenticateAsync`：options 校验（null/非绝对）、进程内单请求（第二个抛 `InvalidOperationException`）、caller 取消即超时口径（MAUI 无内建超时）、`PrefersEphemeralWebBrowserSession` 一次性注明。
- 开浏览器走既有 `OpenHarmonyAbilityBridge.TryOpenUri`；**pool 线程派发**（真机实测：激活回调跑在壳 JS 线程上，同步 startAbility 会等同线程应答 → 5 s 超时降级 FeatureNotSupported）。
- 回调经 `OpenHarmonyBridge.Activation`（壳 onCreate/onNewWant → notifyActivation 通道）：scheme/host 忽略大小写、有效端口与非根路径精确匹配（对齐 `WebUtils.CanHandleCallback`）→ `WebAuthenticatorResult`（query+fragment、`ResponseDecoder`）；重复/不匹配投递忽略；无平台宿主保留 `FeatureNotSupportedException` 降级；DI + `Default` 反射安装不变。

## 2) 壳 want 构造缺陷（真机发现，已修）

- 壳 `Index.ets` 能力 sink 的 `new Want()` 在本镜像运行期抛 `Constructor is false`（Panda `newobjrange`）——**Launcher/Browser/Share/Settings 全族从未真机走过该路径**；WebAuth 是首个真机触发者。
- 7 packs `Index.ets` 改对象字面量 `{}`；重编 UI abc（542,840 / `cba85801…`）并 `--install-packs` 落预览包 + provenance（.22/.23/.24/.28；.25–.27 为旧壳不回填模板，仅 targets/tools 同步）。真机复验：`ability start dispatched: kind=0`（round4 ×4、round6 ×2）、`start threw/failed=0`。

## 3) 清单注入（ow）

- 新增 `OpenHarmonyGenerateModuleJson.WebAuthenticatorCallbackUrls` + `OpenHarmonyWebAuthenticatorCallbackUrls`（7 packs targets 字节一致，任务 Dll 同步）：每条 route（`myapp://callback` 或裸 scheme）生成一条 browsable/viewData skill uri；非法 route/host/无 skills 锚报错；app-link + callback **合并单次插入**，两属性同用仍字节确定（离线实测两次生成逐字节相等）。

## 4) 测试（红绿）

- 套件新增 8 条：源/manifest pin、query 完成、fragment + 不匹配守卫、cancel、caller 超时、单请求+重复丢弃、参数校验、launch 失败、无平台降级。红控①：`CanHandleCallback` 恒真 → `pending-on-mismatch=False`、rc=134；红控②：注入去重关闭 → tasks FAIL（expected 3 got 4）、还原后 169/0。
- tasks-tests +14；selftest-hap-targets **T10**（真 targets 打包 fixture hap：home+app-link+callback 三 skill、负控报错）。
- 真机：JIT probe hap（`-p:WebAuthProbe=true`，`com.example.hellomauiapp`，126,032,015 B / `beb55074…`）：触发→pending；`aa start -U 'myapp://callback?code=SECRET1&state=st1'`→`ok code=SECRET1 state=st1`（二次全新进程 SECRET2/st2 同）；cancel→`canceled`；timeout→`timeout canceled`；错误 URI 不完成；0 RuntimeError；壳状态转发 `[maui] status:` 为证据。设备还原：整 fixture 主 hap（`f75dfc91…`）重装 + 启动、WMS 残留 0、锁释放。

## 5) 余项 / 不确定

- 真实端点一跳未做（无公网），回跳用显式 `aa start` 模拟；**隐式 skill 投递**（真浏览器跳 `myapp://`）未测 →
  2026-10-10 执行轮：设备已恢复，但锁屏 `10106102` 阻断（需人工解锁后重跑；就绪脚本/修正见
  [`2026-10-10-ohos-webauth-implicit.md`](2026-10-10-ohos-webauth-implicit.md)）。
- 新 abc 未重锚 kit 侧 `verify-kit --expected-abc`/`cut-kit`（542936 默认值属 kit 资产，不切 kit）；下次切 kit 需同步。
- probe/壳修复随 ow 分支；`WebAuthProbe.cs` 仅 `-p:WebAuthProbe=true` 编译，默认样例不受影响。
