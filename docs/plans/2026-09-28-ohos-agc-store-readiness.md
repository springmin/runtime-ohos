# AGC 商店上架准备（OpenHarmony / HarmonyOS，2026-09-28）

> 目的：把 MAUI on OpenHarmony 交付物提交华为应用市场（AGC）前的核对表。元数据口径 = `app-metadata-audit-skill`（AGC 预审），**实际字段名与必填项以 AGC 控制台为准**。
> 关联：签名/UDID 预签 RUNBOOK = `2026-09-19-ohos-signing-and-udid-guide.md` §3–4 + `2026-09-21-ohos-device-run-playbook.md`；
> AGC 服务 13 行清单（Push/Map/Account/LiveView/TTS）= `ohos-workload/docs/openharmony-hap-packaging.md` §AGC；P2c 深链现状与边界 = `2026-09-28-ohos-tester-handoff-kit29.md` §1/§5。

## 1. 元数据合规清单（需填 / 注意 / 常见拒审点）

| 项 | 需填 / 注意 | 常见拒审点 |
|---|---|---|
| 应用名称 | ≤15 汉字或 ≤30 其他语言字符；各语言含义一致；与包内 `app_name` 一致 | 泛词/功能词（手机定位、视频剪辑去水印…）、蹭知名应用/IP、官方/权威/推荐/精品、免费/促销、占位符或特殊符号 |
| 一句话简介 / 简介 | 各语言版本齐全且与所选语言一致；一句话简介不得重复 | 含其他终端/平台品牌（Android 等）；宣传实际不提供的能力（如把非硬件后备写成硬件加密） |
| 关键词 / 搜索词 | 只填与功能相关的词，宁缺毋滥 | 热搜词、竞品名、商标词堆砌 |
| 分类 / 标签 / 年龄分级 | 与内容一致；儿童类目分级 ≤12+ 且文案按儿童口径 | 分类与实际能力不符；漏填或与内容不符 |
| 截图 / 视频 / 图标 | HarmonyOS 要求 ≥3 张不同内容、方向正确、不重复/模糊/拉伸；展示真实 UI；图标自研、无角标等误导点击元素 | 截图数量不足/重复/含系统界面或其他品牌；功能需特殊环境（HMS 设备、AGC 权益）却无演示视频；系统图标或误导角标 |
| 隐私政策链接 | 可正常打开、中文版、开发者自有；含收集目的/方式/范围；与提交内容一致 | 打不开/空白、与提交不一致、套用第三方模板 |
| 隐私标签（数据收集声明） | 按实际收集逐项声明（当前无广告/分析 SDK；崩溃/设备信息按现状如实声明） | 缺失或与代码/权限不一致（判隐瞒收集） |
| 支持设备 / 最低 API | 与 `module.json` 的 `deviceTypes`（phone/tablet/2in1）与 min API 一致 | 声明机型实测跑不起来（HUKS/TTS 依赖设备能力） |
| 测试账号 / 演示说明 | 无需登录则注明；HMS 能力附说明与录屏 | 审核员无法复现关键功能 |

## 2. 签名与 Profile（debug → 发布）

| 阶段 | 材料 / 操作 | 说明与常见失败 |
|---|---|---|
| 自签 debug | SDK 调试模板 p7b + 自签 | `9568257`（自签验签链）与 `9568344`（profile 未绑 UDID）**属预期**；按 RUNBOOK 重签 |
| 华为调试证书 / Profile | p12 + cer + p7b + keyAlias（DevEco 自动签名或 AGC 申请） | `sign-for-device.sh --huawei/--external`、`make-device-test-kit.sh --sign-external` 预签；p7b 的 `device-ids` 必含目标 UDID，`bundle-name` 必等于 hap |
| 发布证书与 AGC 关联 | AGC「证书、App ID 和 Profile」申请发布证书 + Profile；项目设置 > 常规 > 应用 添加 SHA256 指纹 | 指纹与签名材料不一致 → 服务初始化失败；启用 Push/Map/Account/LiveView 后须重申请受限 Profile 并重签 |
| 发布构建 | release Profile（无 UDID 绑定）；`bundleName`=AGC 应用；versionCode/Name 递增 | 拿 debug 材料提审、版本号未递增、bundleName 不一致导致无法关联 |

## 3. 权限与隐私（27 类 MAUI 权限映射 + reason/usedScene）

映射源：`maui-ohos` `OpenHarmonyEssentialsUnsupported.cs`（SDK 26.0.0.18；覆盖 27 个嵌套类型；未映射类型 → `Unknown/Denied`）。

| MAUI 权限类型 | OpenHarmony 权限 | 备注 |
|---|---|---|
| Battery · LaunchApp · Reminders | ∅（无权限门槛） | Check/Request 直接按已授予 |
| Bluetooth | ACCESS_BLUETOOTH | 扫描/连接共用，user_grant |
| Camera · Flashlight | CAMERA | 手电筒取 Camera Kit 最接近门 |
| Microphone · Speech · Media | MICROPHONE / READ_MEDIA | 语音识别无 OH 对应，仅麦克风输入 |
| ContactsRead/Write · CalendarRead/Write | READ_CONTACTS / WRITE_CONTACTS / READ_CALENDAR / WRITE_CALENDAR | 敏感，人工复核 |
| LocationWhenInUse | APPROXIMATELY_LOCATION | 粗定位 |
| LocationAlways · Maps | LOCATION + LOCATION_IN_BACKGROUND / LOCATION | Always 需前后台两个 |
| Photos · StorageRead / PhotosAddOnly · StorageWrite | READ_IMAGEVIDEO / WRITE_IMAGEVIDEO | |
| NearbyWifiDevices · NetworkState · Vibrate | GET_WIFI_INFO / GET_NETWORK_INFO / VIBRATE | 系统授权，不弹窗 |
| Phone / Sms / Sensors | GET_TELEPHONY_STATE / SEND_MESSAGES / READ_HEALTH_DATA | 敏感（Sensors 取最接近的用户授权传感器权限） |
| PostNotifications | 非 abilityAccessCtrl | 用通知开关 `isNotificationEnabledSync` + `requestEnableNotification`（系统弹窗） |

reason/usedScene 模板（`$string:permission_reason_*`；usedScene 现有统一为 `abilities=[EntryAbility]`、`when=inuse`）：

| reason 资源 | EN（现有模板） | 中文建议 |
|---|---|---|
| bluetooth | Bluetooth is used to discover, connect to and exchange data with nearby devices. | 用于发现、连接附近设备并交换数据。 |
| location | Approximate location is used to turn coordinates into addresses and to search nearby places. | 用于将坐标转换为地址、搜索附近地点。 |
| clipboard | Clipboard content is read only when the app explicitly asks for it. | 仅在应用明确请求时读取剪贴板内容。 |
| contacts | Contacts are looked up to fill in the names and phone numbers the app asks for. | 用于按应用请求查找联系人的姓名与电话。 |
| calendar_read | Calendar events are read to show the schedule the app requests. | 用于读取并显示应用请求的日程。 |
| calendar_write | Calendar events are created when the app adds an event. | 用于在应用新增日程时创建日历事件。 |
| print | Documents the app renders can be sent to the system print service. | 用于将渲染文档发送到系统打印服务。 |
| internet | Internet access is used when the app loads network content or calls web services. | 用于加载网络内容或调用 Web 服务。 |

> 打包侧由 `OpenHarmony.Hap.targets` 的 `_OpenHarmonyResolvePermissions` 从 feature 矩阵解析并写 `module.json` 的 `requestPermissions`（name+reason+usedScene）；
> 权限变体只含被选中权限，且必须覆盖壳请求点扫描（漂移 strict 可 error）。AGC 声明位置：**隐私标签/数据收集**与应用权限说明必须覆盖上述声明；
> 受限（ACL）权限在 AGC 申请入口提交用途/场景；敏感权限（联系人/日历/定位/健康/短信/电话）人工复核，reason 文案须与 AGC 用途一致（入口名以控制台为准）。

## 4. App Linking 清单声明（与 P2c app.json 白名单协同）

1. 候选 `https://` 域名在 AGC 完成应用链接归属配置/校验（校验文件或 JSON 字段以 AGC 应用链接文档为准）；自定义 `app://` 无需域名校验。
2. `module.json5` 的 `abilities[].skills[]` 增加声明（当前模板只有 home skill，尚无 `uris`）：`{"entities":["entity.system.browsable"],"actions":["ohos.want.action.viewData"],"uris":[{"scheme":"https","host":"<host>","pathPrefix":"<path>"},{"scheme":"app","host":"<host>"}]}`。
3. 打包 `-p:OpenHarmonyAppLinkHosts="host1;host2"` 写入 app.json `linkHosts`（P2c 托管白名单，`AllowedHttpsHosts` 可扩展）；`module.json` 的 uris host 与 `linkHosts` 必须同源。
4. 用 AGC 登记的签名证书出包后，系统才会把 `https://` 链接投递给本应用（冷启动 `onCreate` / 热激活 `onNewWant`）。
5. 验收：`aa start` 带 uri 冷启动直达；浏览器点链接热激活换页；未注册路由不崩（kit #29 §2 深链判定点）。

## 5. 提交前自检

**运行时 10 项**：① release 签名安装无 9568257/9568344；② 冷启动成功且首帧（无黑屏）；③ 5 条冒烟（导航/控件/文本/列表/网络）；④ 深链冷/热激活；⑤ HUKS 重启读回、删除清 key；⑥ TTS 降级不抛（HMS 设备点亮）；⑦ 权限弹窗理由文案显示；⑧ 无 HMS 设备降级不抛；⑨ 断网/弱网启动不崩；⑩ 杀进程重启与覆盖升级后状态正确。

**元数据 10 项**：① 名称合规；② 简介/一句话简介多语言；③ ≥3 张不同截图；④ 特殊功能演示视频；⑤ 隐私政策可打开；⑥ 隐私标签与权限一致；⑦ reason/usedScene 与请求点一致；⑧ 设备类型/API 一致；⑨ 年龄分级已选；⑩ 版本号/包名/测试账号已核。

> 不确定项与边界：AGC 字段与入口名以控制台为准；App Linking 的 HTTPS 投递与 `skills[].uris` 清单声明尚未真机验证（当前只有
> app.json 白名单 + 托管校验）；TTS 真朗读需 HMS 设备 + harmony 壳；包内数字随重签变化，以 release「## Integrity」为准。
