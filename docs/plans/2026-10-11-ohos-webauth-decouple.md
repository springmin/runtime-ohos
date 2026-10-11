# WEBAUTH-DECOUPLE：回调路由注入与 WebAuthProbe 解耦（2026-10-11）

> 结论：ow **master `f66d67c`**（分支 `fix/webauth-decouple`，基 `77fc502`，ff 并主线后同推）把 `hello-maui-app.csproj` 的 `OpenHarmonyWebAuthenticatorCallbackUrls=myapp://callback` 从 `WebAuthProbe` 条件上解耦为**无条件**；`-p:WebAuthProbe=true` 仅余探针 UI/触发器。两变体 JIT 实测：**默认件 module.json 也含回调 skill**；探针件不回归；abc 无变化；无设备、#49–#54 资产未动、maui 零改动。

## 1) 绑定点 / 根因
- 绑定：`test/hello-maui-app/hello-maui-app.csproj` 的 route 属性带 `Condition=" '$(WebAuthProbe)' == 'true' "`（kit #54 rev2 形态）→ 默认 publish 的 module.json 只有 home skill，浏览器回跳不路由；`make-device-test-kit.sh` 的 `DEVICE_TEST_KIT_WEBAUTH_PROBE=1` 只是把 `-p:WebAuthProbe=true` 传给每个 MAUI publish 的旁路（默认关）。
- 门禁盲区：P0 只对 pack（targets/tasks/abc/rawfile），不对 hap 清单 → 默认漏注入静默出厂（#54 亦如此）；而回调路由属产品语义（系统 skill 分发），探针属测试入口，二者不应共开关（A-M1 rawfile staging 已按无条件先例）。

## 2) 解耦改法（ow，3 文件）
- csproj：route 无条件（删除 Condition）；`WEBAUTH_PROBE` define 与 `WebAuthProbe.cs` 的 `#if` 仍由 `-p:WebAuthProbe=true` 门控（探针 UI 与自动用例）。
- `make-device-test-kit.sh`：`DEVICE_TEST_KIT_WEBAUTH_PROBE` 文档收窄为探针 UI；新增 **`check_webauth()`**（python 解 hap 的 `module.json`，`abilities[0].skills` 缺 `(myapp, callback)` → exit 1），在 26.0 默认 + unsigned 两处调用——kit 组装 fail-closed。
- `selftest-make-device-test-kit.sh`：v3 + **T2c** 静态 5 检（route 无条件 / 无 Condition / define 仍门控 / `#if WEBAUTH_PROBE` 仍在 / gate 仍在）；T2/T2b 原样（默认无 `-p:WebAuthProbe=true`；env=1 四 publish 全带）。

## 3) 两变体静态断言（JIT，rc2-fix，一次一构建）
- 命令：`make-mode-kit.sh --mode jit --property OpenHarmonyUIPage=pages/Index --property OpenHarmonyArktsModulesAbc=<repo>/dist/ets/modules.abc`（探针变体追加 `--property WebAuthProbe=true`）。
- **默认件** `54e60de9…`（135,609,528 B）：skills = home + `{"entities":["entity.system.browsable"],"actions":["ohos.want.action.viewData"],"uris":[{"scheme":"myapp","host":"callback"}]}`；`hello-maui-app.dll` **无** `[webauth-probe]`/`app://webauth/`（UTF-16 串检）。
- **探针件** `93b49f71…`（135,618,803 B）：同 skill + dll 含 `[webauth-probe]`、`app://webauth/`、`webauth: pending`、`webauth: timeout canceled` → 探针不回归。
- gate 自身：真默认件 rc=0；去 skill 负控件 rc=1（含 `carries no myapp://callback skill`）。
- **abc：两变体 hap `ets/modules.abc` 均 623,784 / `58c5829b…`**（= repo `dist/` = 两安装 pack = FINAL）→ **无变化**，下一 kit 的 `verify-kit --expected-abc` 锚不动。

## 4) 合并 / CI / 提交
- ow：`selftest-make-device-test-kit` **47/0**（原 42/0，+T2c）、`selftest-hap-targets` **85/0**（1 skip=T6 设备件）→ `master 77fc502→f66d67c` ff 合并 + 推送（HTTP/1.1），分支同推；maui 本次无改动。
- runtime：本文件 + README 索引（commit-paths 限路径）→ `feature/openharmony`。
- 边界/不确定：无设备（静态足够；探针行为承 round54 真机）；AOT 未单独构建——module.json 生成与 runtime-mode 无关、kit AOT 走同一 csproj；**下个 kit（#55）默认 hap 即带回调路由**，轮次文档的 `aa start -U myapp://callback?...` 步骤不再需要 `DEVICE_TEST_KIT_WEBAUTH_PROBE`。
