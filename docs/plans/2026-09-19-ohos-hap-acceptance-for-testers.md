# 验收说明（随 hap 一起发送）— .NET/MAUI on OpenHarmony

> 本文档面向**外部测试人员**，不需要开发环境知识。请把本文档与 `hello-maui-app.hap` 一起拿到目标设备上执行。

---

## 1. 交付物

| 项 | 值 |
|---|---|
| 文件名 | `hello-maui-app.hap` |
| 大小 | 21,521,150 字节（约 20.5 MB）|
| SHA-256 | `8da356190b2e7c495dd39bb43de8c83399a300dedce4ca49cea3bfa3125f2d88` |
| 构建版本 | `.NET/OpenHarmony workload 1.0.0-preview.23` |
| 目标框架 | `net11.0-openharmony26.0`（arm64）|
| 内含 | 托管应用负载、自签名宿主库 `libopenharmonyhost.so`、ArkTS 壳归档 |

应用名：`hello-maui-app`；启动后是一个包含大量控件的长列表页面（顶部导航栏标题「Root」）。

---

## 1b. 带权限变体（用于验证联系人/日历/蓝牙/打印）

除默认包外，可提供**带权限变体** `hello-maui-app-permissions.hap`（同一构建，仅 `module.json` 额外声明）：

```
ohos.permission.ACCESS_BLUETOOTH · ohos.permission.PRINT
ohos.permission.READ_CONTACTS · ohos.permission.READ_CALENDAR · ohos.permission.WRITE_CALENDAR
```

- 适用于第 4 节 **G（传感器无关）之外的 H 类新能力**：蓝牙（读配对设备/发现）、打印（系统打印任务）、
  联系人查询、日历查询/新增。首次使用时会**弹出运行时授权**（除 `PRINT` 为 system_grant 不弹）。
- 复现命令（在本仓库 `test/hello-maui-app` 下）：
  ```bash
  dotnet publish -c Release -r openharmony-arm64 \
    -p:OpenHarmonyUIPage=pages/Index \
    -p:OpenHarmonyArktsModulesAbc=<repo>/dist/ets/modules.abc \
    -p:OpenHarmonyHapPackage=true \
    -p:'OpenHarmonyExtraPermissions="ohos.permission.ACCESS_BLUETOOTH;ohos.permission.PRINT;ohos.permission.READ_CONTACTS;ohos.permission.READ_CALENDAR;ohos.permission.WRITE_CALENDAR"'
  ```
  注意：`-p:` 参数**必须用单引号包住整体**，否则 shell 去引号会导致 MSB1006。
- 默认包（不带属性）的 `module.json` 与基线**逐字一致** ✓（不会影响其他应用）。
- **API 20 变体**：`hello-maui-app-api20.hap`（同壳/宿主，运行时使用 `net11.0-openharmony20.0` 通道的 Ref/Runtime 包，
  面向 API 20 设备）。复现：`dotnet publish -c Release -r openharmony-arm64 -p:TargetFrameworks="net11.0-openharmony20.0"
  -p:TargetFramework=net11.0-openharmony20.0 -p:OpenHarmonyUIPage=pages/Index -p:OpenHarmonyArktsModulesAbc=… -p:OpenHarmonyHapPackage=true`。
  ⚠️ 注意：`module.json` 的 `minAPIVersion/targetAPIVersion` 目前仍取打包目标默认值（60001021/60101024），
  如需按目标设备声明可用 `-p:OpenHarmonyMinApiVersion=… -p:OpenHarmonyTargetApiVersion=…` 覆盖。带权限的 API 20 变体
  可由同一命令加 `-p:'OpenHarmonyExtraPermissions="…"'` 产出。
- **变体摘要（实测）**：`module.json` 的 `requestPermissions` 恰为上述 **5 项** ✓；文件 `hello-maui-app-permissions.hap`，
  大小 **21,679,125** 字节，SHA-256 `1a89a3729debe300ff0d0fd2e0bd0b302866adca8833b10c0737e8a068450c0a`（每次重新构建会因签名时间戳变化，请以随包提供的值为准）。

## 2. 环境要求

- HarmonyOS / OpenHarmony 设备，**arm64（aarch64）**
- 系统 API **26** 最佳；API 20 亦可（同版本另有一份 `openharmony20.0` 构建）
- 需要允许安装**调试/自签名**应用（设置 → 安全 → 允许安装外部来源，或开发者模式）

---

## 3. 安装与启动

**方式 A（推荐，仅设备即可）**
1. 把 `hello-maui-app.hap` 拷到设备（U 盘/文件管理器/局域网）。
2. 在文件管理器中**打开该 hap**（或用系统"应用安装器"打开）→ 按提示安装。
3. 安装失败时**记录完整错误文案**（签名错误 / 策略限制 / 未知来源等）并回传。

**方式 B（若设备侧允许 hdc）**
```bash
hdc list targets          # 能看到设备
hdc install hello-maui-app.hap
hdc shell aa start -a EntryAbility -b com.example.hello-maui-app   # 或直接从桌面图标启动
```

**启动后预期**（首帧）：黑色导航栏 + 标题「Root」，下方依次出现标签、按钮、图片、复选框、开关、滑块、进度条、单选框、步进器、搜索框、日期/时间选择器、集合视图、SwipeView 行、RefreshView 行、WebView、按钮「Sync」在导航栏右侧等。

---

## 4. 测试清单（逐项打勾，记录异常现象）

> 术语：**点按**=单击；**拖动**=按住移动；「鼠标」项需接鼠标。

### A. 渲染与控件
| # | 步骤 | 预期 |
|---|---|---|
| A1 | 观察首帧 | 无花屏/黑块；文字清晰；控件不重叠 |
| A2 | 点按按钮 | 按下时有按下态颜色，抬起恢复；按钮计数变化 |
| A3 | 观察图片 | 居中显示、不变形 |
| A4 | 观察圆角/形状 | 圆角矩形、描边、填充颜色正确 |
| A5 | 拖动滑块 | 手柄跟随手指，数值变化 |
| A6 | 点按复选框 / 开关 | 状态切换，视觉反馈正确 |
| A7 | 点按单选按钮 / 步进器 | 选中态正确 / 数值增减 |
| A8 | 点按日期选择器、时间选择器 | 弹出内置选择面板，可选中 |
| A9 | 点按搜索框 / 选择器（Picker） | 出现输入框 / 内联下拉，可选项并可关闭 |

### B. 弹层（Alert / ActionSheet / Prompt）
| # | 步骤 | 预期 |
|---|---|---|
| B1 | 触发「显示弹窗」（DisplayAlert 两项）| 出现遮罩+对话框；点「取消/确定」分别返回 false/true；弹层关闭 |
| B2 | 触发三项弹窗 | 三个按钮都可见且可点 |
| B3 | 触发操作表（ActionSheet）| 选项列表出现；点某项后弹层关闭且返回值正确 |
| B4 | 触发输入提示（Prompt）| 出现输入框，**可打字**；点确定返回所输文本 |
| B5 | 弹层打开时点遮罩空白处 | 不应误触到下层控件 |

### C. 手势与列表
| # | 步骤 | 预期 |
|---|---|---|
| C1 | 上下拖动页面 | 平滑滚动，无内容错位 |
| C2 | 点按集合视图项 | 选中项高亮 |
| C3 | 在「swipe me」标签上向左/右快速滑动 | 触发 Swipe 事件（应用内会记录方向）|
| C4 | 在 SwipeView 行（"swipeable row"）上向左拖动 | 露出「Delete」按钮；点它执行并收回 |
| C5 | 在 RefreshView 行上向下拉 | 出现刷新指示；松开后执行一次刷新（计数 +1）|
| C6 | **接鼠标**在「hover me」标签上悬停/移开 | 出现悬停反馈（进入/离开事件）|
| C7 | **双指**在「pinch me」标签上捏合/张开 | 触发缩放事件（日志中可见 Started/Running/Completed）|

### D. 导航
| # | 步骤 | 预期 |
|---|---|---|
| D1 | 点导航栏返回/进入子页（若页面提供）| 页面切换正确，返回键可用 |
| D2 | 观察 Shell/TabbedPage/Flyout（若提供了入口）| 底部标签可切换；汉堡菜单可开合 |
| D3 | 点击导航栏右侧「Sync」 | 执行一次命令（计数变化或日志）|

### E. 文本输入（IME）
| # | 步骤 | 预期 |
|---|---|---|
| E1 | 点按 Entry | 系统键盘弹出，出现光标 |
| E2 | 打字（中英混输）| 文本即时上屏，无双字/漏字 |
| E3 | 移动光标 / 选择文本 | 光标可移动；选区可见 |
| E4 | 点按 Editor | 键盘弹出；回车换行 |
| E5 | 收起键盘 | 布局恢复，不遮挡内容 |

### F. 存储与系统集成
| # | 步骤 | 预期 |
|---|---|---|
| F1 | 触发 Preferences 写入，重启应用 | 值保持 |
| F2 | 触发 SecureStorage 读写 | 读回一致；删除后为空 |
| F3 | 触发 AppInfo/DeviceInfo 显示 | 包名/版本/平台信息正确 |
| F4 | 触发剪贴板复制/粘贴 | 内容一致 |
| F5 | 触发权限请求（如定位）| 出现系统权限弹窗，允许后可获取一次定位 |

### G. 传感器
| # | 步骤 | 预期 |
|---|---|---|
| G1 | 启动加速度计读数 | 数值随设备姿态变化 |
| G2 | 启动陀螺仪读数 | 旋转设备时数值变化 |
| G3 | 快速摇动设备 | 触发摇一摇事件（若界面提供）|

### H. 通知
| # | 步骤 | 预期 |
|---|---|---|
| H1 | 触发「发送通知」 | 通知栏出现标题/正文；内容与传入一致 |

### I. 相机与选择器
| # | 步骤 | 预期 |
|---|---|---|
| I1 | 触发拍照 | 系统相机界面出现；拍照后应用显示所拍图片 |
| I2 | 触发录像 | 同上（视频）|
| I3 | 触发文件选择 / 图片选择 | 系统选择器出现；选中后返回文件 |

### J. 显示与系统栏
| # | 步骤 | 预期 |
|---|---|---|
| J1 | 观察顶部/底部 | 状态栏、手势条不遮挡内容（安全区内缩）|
| J2 | 旋转/改变窗口大小（若支持）| 内容重新排布，无越界 |

### K. WebView
| # | 步骤 | 预期 |
|---|---|---|
| K1 | 打开内嵌网页 | 页面加载并显示；可滚动 |
| K2 | 触发返回 | 回到上一页或关闭 |

---

## 4b. 本轮新增能力（对应测试项）

> 默认包即可测试下列能力；涉及权限的项目请改用 **带权限变体**（见 §1b），首用时按提示授权。

| # | 能力 | 操作 | 预期 |
|---|---|---|---|
| N1 | **蓝牙状态/配对设备** | 触发"蓝牙"入口（读状态、列配对设备）| 状态与已配对设备列表正确；未授权时如实提示不可用 |
| N2 | **蓝牙发现** | 触发"开始发现"，若干秒后停止 | 期间陆续列出附近设备（名称/地址）；停止后不再新增 |
| N3 | **打印** | 触发"打印文本" | 出现**系统打印界面**并显示任务名；取消/确认均正常返回 |
| N4 | **联系人查询** | 输入前缀查询 | 返回匹配联系人（姓名+电话）；拒绝授权时为空且不崩溃 |
| N5 | **日历** | 列出近期日程 / 新增一条事件 | 列表含未来日程；新增后可在系统日历看到 |
| N6 | **Hybrid JS 往返** | 打开 Hybrid 演示页并点击按钮 | JS→.NET 调用返回结果并回显（`Echo`/`Add` 等） |
| N7 | **无障碍状态日志** | 启动应用后查看日志 | 出现 `[maui] accessibility provider status=N`：**1=已附着**（理想）；2/3 请连同该行一起回传 |

**日志采集（如有 hdc）**：`hdc hilog > log.txt` 或过滤应用包名；无 hdc 时请截图该行或应用内日志区域。

## 5. 已知限制（**不是缺陷**，无需上报）

| 项 | 说明 |
|---|---|
| 读屏/无障碍 | 暂未接入系统读屏节点（数据层已完成，平台绑定待做）|
| BlazorWebView / HybridWebView | 尚未实现 |
| Hot Reload / 诊断 overlay | 热重载未实现（诊断描边需应用内开关）|
| Pinch | 需**两根手指**同时接触（单指无效）|
| 悬停 | 需**鼠标**（触摸设备无悬停）|
| 相机/通知/传感器 | 模拟器上读数为模拟值，属正常 |

---

## 6. 结果回传格式（请复制填写）

```
设备型号/系统版本：
hap 安装方式：手动 / hdc
安装是否成功：是 / 否（错误文案：            ）

A1..K2 逐项结果（通过/失败/未测 + 现象）：
  A1 通过
  A2 失败：按下无反馈
  ...
G1 通过（数值随姿态变化）
H1 失败：通知栏无提示
I1 未测（无相机）

严重问题（崩溃/黑屏/无法启动）：
  发生步骤 → 现象 → 是否可复现
日志（可选）：若可用 hdc，请附 `hdc hilog > log.txt` 的片段；否则请截屏。
```

---

## 7. 回传内容清单

1. 填好的第 6 节结果
2. 安装失败时的**完整错误文案**或截图
3. （可选）日志或录屏
