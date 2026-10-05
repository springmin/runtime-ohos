# A11Y-CLIENT：最小无障碍客户端（本地读屏语义验证，2026-10-05）

> 所有权/位置：ohos-workload `test/a11y-client/**`（新 hap）+ `scripts/{build,run,enable,selftest}-a11y-client.sh`。
> 设备 HAD-W32 / HarmonyOS 7.0.0.111(SP3) / API 26，UDID `1BCE13C8…AEA0`，独占 `.device-lock`。
> 件：签名 hap **83,279 B / `f3fbfad6…`**（UDID 绑定）；未签 57,702 / `487dd0b9…`；abc 31,820 / `d669c730…`。

## 1) 能力（实现）
- `AccessibilityExtensionAbility`（module.json5 `type: accessibility` + `ohos.accessibleability` →
  `accessibility_config.json`，capabilities `retrieve`+`gesture`）：`onConnect`/`onAccessibilityEvent`
  → `getWindows` → `rootElement` → `attributeValue` 遍历——id/parent/depth/role/label/click/focus/
  a11yFocus/checked/selected/editable/scrollable/visible/window/rect；≤600 节点 / ≤40 深 / ≤12 次，
  写 `<filesDir>/a11y-dump.json` + hilog `A11YCLIENT NODE …`；可选动作：目标窗口首个 label 含
  `Count:` 的可点节点 `performAction('click')` + 回读 text（`A11YCLIENT ACTION`）。
- 纯模型 `A11yModel.ts`（label 优先级 / summary / findClickTarget / JSON）→ 离线 node 单测 6 项。
- 伴生无 UI `EntryAbility` 公开 API 探针：`isOpenAccessibilitySync`/`getAccessibilityExtensionListSync`。

## 2) 启用门槛（本机实测，三路全闭）
- AMS：`accessible=0`、`client num=0`（无读屏客户端）；`shortkeyTarget=none`。
- CLI `accessibility enable -a A11yExtAbility -b com.example.a11yclient -c rg`：本机**无该二进制**
  （stock/开发版才有）。
- 设置 → 辅助功能：PC 版仅 视觉/听觉（无「扩展服务/已安装的服务」）；**全局搜索亦无**。
- `@ohos.accessibility.config.enableAbility`：本 SDK 无该 d.ts；上游为 `@systemapi`，需
  `ohos.permission.WRITE_ACCESSIBILITY_CONFIG` + 系统签名应用。
- 结论：**本影像对第三方 debug hap 关闭扩展启用**（非实现缺陷）；需 stock OH / 读屏机 / 系统签名。

## 3) 本地结果（证据在 `/data/storage/el2/base/tmp/opencode/a11y-client/`）
- 构建/签名/安装：通过。坑：hap 必须用 hvigor `package/default/module.json` 打包（带
  `virtualMachine`/`compileMode`）；误用 `merge_profile` 版 → ability 启动 `LIFECYCLE_HALF_TIMEOUT`。
- AAMS 可见性：`probe.log`（09:21）`installedExtensions=3`，含
  **`com.example.a11yclient/A11yExtAbility` caps=["retrieve","gesture"]**；`enabledExtensions=0`。
- 离线兜底：`selftest-a11y-client` **14/14**（模型 6 + 源/包/abc 断言，abc 含 A11yExtAbility/
  AccessibilityExtensionAbility/getWindowRootElement/attributeValue/performAction/A11YCLIENT）。
- 影子树读数（节点/焦点/动作）本轮**未取得**——扩展未连接（门槛），非语义路径失败。
- 证据：`probe.log`、`ams-{user,clients}.txt`、`settings-accessibility.json`、`settings-search.json`、
  `artifacts.sha256`、`bm-a11yext.txt`。

## 4) tester 步骤（启用后复跑）
1. `sh scripts/build-a11y-client.sh --install`（或 `hdc install -r dist/a11y-client/a11y-client-signed.hap`）。
2. 设置 → 辅助功能 → 已安装的服务 → 「A11y client (dump)」开（过风险倒计时）；或 stock 构建
   `accessibility enable -a A11yExtAbility -b com.example.a11yclient -c rg`。
3. 启动 `com.example.hellomauiapp`，`sh scripts/run-a11y-client.sh --capture 30`；回传含
   `A11YCLIENT dump/NODE/ACTION` 的 `hilog.txt` + 应用 `filesDir/a11y-dump.json`（若可导出）。
4. 判据：dump `nodes>0 targetNodes>0`；NODE 行 role/label/rect 与屏幕一致；ACTION 后 `Count:` +1。

## 5) 不确定 / 边界
- 设开启是否走 `retrieve` 能力门控、读屏焦点顺序与事件过滤，需真启用后复测。
- OPT4 启用旁路探索（2026-10-05，五路全闭，复核 installed=3 / `enabledExtensions=0`）：① Settings 直达失败（`com.huawei.hmos.settings` 8 个 ability 无辅助功能页；「辅助功能」仅视觉/听觉，无「已安装的服务」）；② `aa start` 设置页参数/URI/action 两式仅开主页面或 10103101，直启 `A11yExtAbility` 返回 success 且 `…:accessibility` 进程起、但 AMS `client num=0`（扩展未连接）；③ `settings`/`accessibility` CLI 不存在、`param ls` 对 shell 仅 3 行头（无 access 键）、`bm` 无 ability enable（扩展 bundle 级 `enabled=True/type=4`）；④ AMS dump 仅 `-u/-c/-w` 只读、无 `sa` CLI（SA id=101 无写路径）；⑤ 无 developer ability、无 shell 写 SettingsData 路径、开关不影响 AMS 启用。tester 路径不变：stock 构建 `accessibility enable -a A11yExtAbility -b com.example.a11yclient -c rg`，或「已安装的服务」页 / 系统签名应用调 `@ohos.accessibility.config.enableAbility`。
- 远程 DOM 文本不进影子树（宿主自绘边界）——WebView 仅宿主节点/几何。
- 应用 `filesDir` 沙箱 shell 不可读，dump 以 hilog 行为准；文件需启用后经 app 侧导出。
