# 商店元数据草案（中英首稿，AGC 预审口径，2026-10-04）

> 口径 = `app-metadata-audit-skill` §2 审查清单 + `2026-09-28-ohos-agc-store-readiness.md` §1/§5；实际字段名/必填项以 AGC 控制台为准。
> 对象 = 当前交付示例应用（bundle `com.example.hellomauiapp`；最终以 AGC 注册为准）。若提审产品应用，仅替换 §2 文案，§3–§5 维度不变。
> 状态：首稿（未提交控制台）；🟢 合规 · 🟡 待补齐/待确认 · 🔴 阻断项。

## 1. 事实项（预填）

| 字段 | 值 |
|---|---|
| 应用类型 | 应用（HarmonyOS） |
| bundleName | `com.example.hellomauiapp`（提审前与 hap/AGC 对齐，改动须重注册指纹） |
| 支持设备 | phone / tablet / 2in1（= hap `deviceTypes`） |
| API | minAPIVersion 50002014 / targetAPIVersion 60101024（hap 编码值，随构建线可调） |
| 默认语言 | zh-CN（主）+ en-US |
| 测试账号 | 无需账号/登录 |
| versionCode/Name | 提审时按打包值填，必须大于上一版 |

## 2. 文案首稿

| 字段 | 限制 | zh-CN | en-US |
|---|---|---|---|
| 应用名称 | ≤15 汉字 / ≤30 字符；非泛词/热词/竞品/价格/占位符；各语言同义 | **OpenDotNet 演示** | **OpenDotNet Demo** |
| 一句话简介 | 各语言齐全、不得重复、不含其他终端品牌 | 一个用 .NET MAUI 构建、在 OpenHarmony 设备上运行的示例应用。 | A sample app built with .NET MAUI that runs on OpenHarmony devices. |
| 简介 | 与能力相符；不宣传未提供能力；不堆词 | OpenDotNet 演示展示 .NET / .NET MAUI 应用在 OpenHarmony 上的运行效果：声明式页面与自绘控件、列表与滚动、文本输入与编辑、Shell 导航与深链激活，以及内嵌 WebView / Blazor 内容。应用用于开发者体验与兼容性验证，无需注册或登录，不含广告。 | OpenDotNet Demo shows a .NET / .NET MAUI app running on OpenHarmony: declarative pages and custom-drawn controls, lists and scrolling, text input and editing, Shell navigation and deep-link activation, and embedded WebView / Blazor content. It is a developer-experience and compatibility sample with no account, sign-in, or ads. |
| 关键词 | 只填功能相关，宁缺毋滥 | OpenHarmony、.NET、MAUI、示例 | OpenHarmony, .NET, MAUI, sample |
| 新版本特性 | 如实、简短 | 界面交互与无障碍体验改进；启动与渲染路径优化；未新增数据收集。 | Interaction and accessibility improvements; startup and rendering tuning; no new data collection. |

- 备选名称（若需弱化平台词）：`鸿蒙 .NET 演示` / `OpenHarmony .NET Demo`；"OpenDotNet" 为项目自造词，无竞品/热词关联。
- 简介不得复用一句话简介原文（已分写）；文案中未出现 Android/iOS 等其他终端品牌。

## 3. 分类 / 分级 / 标签

| 项 | 首稿 | 说明 |
|---|---|---|
| 分类 | 工具（开发工具/效率；控制台类目为准） | 与"示例/验证"能力一致，不选儿童类目 |
| 年龄分级 | 3+ / 全年龄 | 无广告、无 IAP、无 UGC/社交、无内购 |
| 标签 | 开发工具、示例 | 不堆热词 |
| 图标 | 🟡 待供 | 自研、无系统图样、无误导角标 |

## 4. 隐私标签（数据收集声明首稿）

| 标签项 | 声明 | 依据 |
|---|---|---|
| 是否收集个人数据 | **否** | 无账号；无广告/分析/崩溃上报 SDK |
| 设备/应用信息 | 仅设备本地 | 不离开设备、不上传 |
| 本地存储 | 仅本机（如示例使用 SecureStorage/HUKS，卸载即清除） | 设备绑定，无云端同步 |
| 网络 | 默认不联网；仅用户操作加载内容（如内嵌 Web 页面） | 默认 hap `requestPermissions` = 0 |
| 权限 | 默认 0 项；`-permissions` 变体按实际勾选（BLUETOOTH/READ_CONTACTS/READ_CALENDAR/WRITE_CALENDAR/PRINT/INTERNET），用途与 reason 一致 | `_OpenHarmonyResolvePermissions` 打包生成，随包可核 |
| 第三方 SDK | 无广告/统计 SDK | 交付包无相关依赖 |
| 儿童 | 不适用（非儿童类目） | 分级 3+ |

> 隐私政策：🟡 URL 待定（中文、可打开、开发者自有、含收集目的/方式/范围）；内容必须与上表一致。Map/LiveView/Push/Account 走通态依赖 HMS + AGC 权益，未开通时降级；提审需附说明/录屏（见 §5）。

## 5. app-metadata-audit 预审表

| 字段 | 状态 | 问题说明 | 建议修改方案 |
|---|---|---|---|
| 应用名称 | 🟢 | 非泛词/热词/竞品、无价格/占位符/特殊符号；中英同义 | 注册前查重 |
| 一句话简介 | 🟢 | 中英齐全、不重复、无其他终端品牌 | — |
| 简介/关键词 | 🟢 | 与能力相符；关键词仅 4 个功能词 | 上线前核对实际功能 |
| 分类/分级 | 🟡 | 类目名以控制台为准 | 控制台确认"工具"二级类目 |
| 截图/视频 | 🟡 | 需 ≥3 张不同内容真实 UI；HMS/AGC 权益功能需演示视频 | 真机截图 + 一轮操作录屏 |
| 图标 | 🟡 | 未供 | 自研图标，避免系统图样/角标 |
| 隐私政策 | 🟡 | URL 未定 | 部署后自检 `curl` 200 + 中文内容 |
| 隐私标签/权限 | 🟢 | 默认 0 权限，与包一致；变体按实际勾选 | 提审前用最终 hap 复核 `requestPermissions` |
| 版本/包名/账号 | 🟡 | 最终 bundleName/版本以 AGC 注册与打包为准 | 递增 versionCode；无需测试账号 |

## 6. 待办与不确定项

- 待供：≥3 张截图、图标、演示视频（HMS 走通态）、隐私政策 URL；控制台类目名。
- 不确定：最终提审对象（示例 vs 产品应用）与 bundleName；AGC 是否要求 `client_id`/隐私标签逐项枚举口径。
