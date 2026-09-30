# AGC 本机可执行盘点与产物（AGC-LOCAL，2026-09-30）

> 目的：把 AGC 13 项清单（`ohos-workload/docs/openharmony-hap-packaging.md` §AGC）中「本机可做」的部分落地成
> 配置骨架/判定脚本/证据；类别 = 本机可做（产物现在生成）| 半可做（模板+账号侧一键）| 仅控制台（入口+操作序列）。
> 总清单 = `2026-09-28-ohos-agc-store-readiness.md`；本波产物在 scratch `/data/storage/el2/base/tmp/opencode/agc-local/`（不入库）。
> 边界：无华为账号/控制台凭证，**未做任何登录或越权尝试**；不装未知工具。

## 1. 环境盘点（详情 `agc-local/evidence/environment.txt`）

- **有**：`~/.harmonybrew/opt/ohos-sdk@26.0.0.18`（hdc/hap-sign-tool/binary-sign-tool/ohos_packing_tool/syscap_tool）、
  `~/ohos-clt/**/hdc`、deveco-cli v1.3.3（`devecocli`，`auth status`=Not logged in）、
  `~/Documents/ohos/config/*.{p12,csr,cer,p7b}`（DevEco 自动签名调试材料，非 AGC 发布证书）、
  `~/Documents/DevEcoStudioProjects/MyApplication`、本机设备 HAD-W24 / 7.0.0.111 / API 26（hdc 127.0.0.1:35111，
  UDID 1BCE13C8…AEA0；**含 HMS 服务与 Push/Map/LiveView/TTS/HuaweiID 5 Kit syscap**）。
- **缺**：agconnect/agcli CLI、DevEco Studio IDE、`hapsigntool`（只有 hap-sign-tool）、AGC 账号与会话、
  AGC 发布证书/受限 Profile、HarmonyOS SDK 根（`ARKTS_HARMONY_SDK_ROOT`/`DEVECO_SDK_HOME` 未设 → 不能本机重编 harmony 壳）。

## 2. 十三项分类计数 = 本机可做 4 · 半可做 3 · 仅控制台 6

| # | 项 | 类别 | 本机产物 / 控制台入口 |
|---|---|---|---|
| 1 | App 注册 | 仅控制台 | 我的项目>添加应用；材料：bundleName/deviceTypes |
| 2 | 签名指纹（SHA256） | 半可做 | `check-map-readiness.sh --p12` 本机算；控制台添加 |
| 3 | 调试/发布 Profile | 仅控制台 | 证书、App ID 和 Profile |
| 4 | Push | 仅控制台 | 增长>推送服务；`02-kits/` 骨架+降级 |
| 5 | Map | 仅控制台 | 开放能力管理>地图服务（无 AppKey）；`01-map/` 材料+snippet+脚本 |
| 6 | Account 一键登录 scope | 仅控制台 | 华为账号服务；`02-kits/` 骨架+错误码 |
| 7 | Account Client ID | 半可做 | 控制台取值+metadata snippet（`01-map/`） |
| 8 | Client Secret（服务端换号） | 半可做 | 控制台值+服务端；`02-kits/` 记录交换边界 |
| 9 | LiveView TIMER 权益 | 仅控制台 | 增长>推送服务>实况窗 |
| 10 | LiveView 设备开关 | 本机可做 | 设备 Settings + `probe-kits-device.sh` |
| 11 | Share | 本机可做 | 无 AGC/无权限；降级行已实测 |
| 12 | Scan | 本机可做 | 无 AGC/无权限；降级行已实测 |
| 13 | TTS | 本机可做 | 无 AGC/无权限；设备 syscap 有，走通待 harmony 壳 |

## 3. 本机产物与实测（scratch `agc-local/`，脚本已跑通）

1. Map：材料清单（AppKey 不适用口径）+ client_id snippet + `check-map-readiness.sh`（真实 hap 判「无 MapOverlay
   记录」= 默认 flavor 预期；`P12PASS` 可算签名指纹）。
2. Push/Account/LiveView/TTS：配置骨架+判定点+错误码（`-1`/1000900010/1001502014/1003500004/1002300002…）+
   `probe-kits-device.sh`（syscap/HMS 服务/bundle skills/两态）。
3. 设备两态实测：降级态 = `[maui] <Kit> unavailable` ×5（不崩，evidence/hilog-*.txt）；设备有 HMS+5 syscap →
   走通态只差 harmony 壳 + AGC 开通/重签。
4. App Linking：`skills[].uris`+`domainVerify` snippet、`applinking.json` 域名校验模板、判定脚本（uris↔app.json
   `linkHosts` 同源；合成 PASS 例已验）；现状 = 安装 hap `uris: []`、`domainVerify: false`。
5. 元数据/隐私：可填表单（名称/简介/关键词/截图/隐私标签/权限理由中英/预审表）；事实项取自 hap 与设备实测
   （默认 hap 0 权限；`-permissions` 变体 5 项：蓝牙/打印/联系人读/日历读写）。

## 4. 不确定项与边界

- AGC 字段名/入口/审核口径以控制台为准；`client_id` 必要性取决于所配 SDK/控制台（新版 MapComponent 已不要求）。
- 走通态证据（Push token/一键登录/地图 Ready/实况窗/真朗读）需 harmony 壳+账号侧开通+重签，本机不能闭环。
- App Linking https 投递只对 AGC 登记证书的包生效；`app://` 已由清单字段承载，UI 路由证据需 kit #29+ 壳。
- 本机镜像 ≥7.0.0.111 的 JIT 主包安装限制（9568393）不影响本波结论（`2026-09-30-ohos-jit-payload-install-policy.md`）。
