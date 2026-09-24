# 验收说明（随 hap 一起发送）— .NET/MAUI on OpenHarmony

> 本文档面向**外部测试人员**，不需要开发环境知识。请把本文档与 `hello-maui-app.hap` 一起拿到目标设备上执行。
> 时间有限的测试者可以先看一页版 **快速上手**：`2026-09-20-ohos-tester-quickstart.md`（如何校验、先测哪 5 条、回传什么）；
> 完整清单与结果模板仍以本文档为准。

---

## 1. 交付物

| 项 | 值 |
|---|---|
| 文件名 | `hello-maui-app.hap` |
| 大小 | **不写死**：每轮重建/重签都会变，以随包 `SHA256SUMS` 为准 |
| SHA-256 | **不做固定约定**：以随包 `SHA256SUMS`（或 kit 的 `.tar.gz.sha256` sidecar）为准；每次重签/重建哈希都会变 |
| 构建版本 | `.NET/OpenHarmony workload 1.0.0-preview.24` |
| 目标框架 | `net11.0-openharmony26.0`（arm64）|
| 内含 | 托管应用负载、ELF 由 SDK ElfSigner 签名的宿主库 `libopenharmonyhost.so`、ArkTS 壳归档 |

校验方式：解包后运行 `sha256sum -c SHA256SUMS`（逐文件校验）；`SHA256SUMS` 由交付方在打包时生成并随包分发。kit 整包与解压内容树的数字见 `device-test-kit` release 说明的「## Integrity」小节（`workload-latest` 镜像同值）或 `.tar.gz.sha256` sidecar。当前发布为 **kit #22**（2026-09-24；设备里程碑回灌：宿主按需 dlsym、每个 hap 带 `resources.index`（restool）、ZIP offset/length + mkdir、DevEco 工程布局；`tester-run.sh` 仍为 v6r2）：包内 5 个 hap 均带 `"libIsolation": true`，并含自 kit #17 起的全部安全/性能/启动修复；主选是 kit #22 本身，对照载荷与 P1–P4 探针按交付方指示取用。

> **签名状态（2026-09-22 真机实测）**：本包 4 个默认 hap 变体（默认 / permissions / api20 / api20-permissions）是
> **自签名（设备会拒绝，需要重签）** —— 用我方调试证书/调试 profile 签名、profile 只绑定示例设备 UDID，真机安装会报
> `9568257 fail to verify pkcs7 file` 或 `9568344 install parse profile prop check error`，属**预期**结果，**不是可安装包**。
>
> **关于包内 `签名说明.txt`**：kit #22 起「PA1 重建壳的下一版 kit」历史句已随源修复（`ohos-workload c6a4cd95e`）；若你手上副本仍出现该句，按历史文案处理，判读以 `签名说明` 其余内容与 release notes 为准。

另有**未签名包** `hello-maui-app-unsigned.hap`（与 26 默认包同一负载、同一 bundle name，未做签名）：**本包唯一可重签安装的变体**，适合用
自己的华为开发者账号自助签名后安装，步骤见同包 `自签说明.md`（重签一行也在 `快速开始.md` §1 与包内 `签名说明.txt`）；其哈希同样在 `SHA256SUMS` 中。

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
  ✅ 波段（2026-09-21 真机修正）：`module.json` 的 `minAPIVersion/targetAPIVersion/apiReleaseType` 随目标 TFM 取值——
  API 20 变体为 min = target = **`60000020`**（平台 6.0.0 / API 20，`Release`）；26.0 变体（本设备波段）为
  min **`50002014`**（平台 5.0.2 / API 14）、target `60101024`、apiReleaseType `Release`，并带
  `compileSdkType=HarmonyOS`、`compileSdkVersion=6.0.2.130`。**min 必须 ≤ 设备的 apiCompatibleVersion**
  （本设备为 `50002014`），否则安装报 `bm 9568297`；可用 `-p:OpenHarmonyMinApiVersion=… -p:OpenHarmonyTargetApiVersion=…`
  （及 `-p:OpenHarmonyApiReleaseType=… -p:OpenHarmonyCompileSdkType=… -p:OpenHarmonyCompileSdkVersion=…`）覆盖。
  带权限的 API 20 变体可由同一命令加 `-p:'OpenHarmonyExtraPermissions="…"'` 产出。
- **变体摘要**：`module.json` 的 `requestPermissions` 恰为上述 **5 项** ✓；5 个 hap 文件名：
  `hello-maui-app.hap`（默认）、`hello-maui-app-permissions.hap`、`hello-maui-app-api20.hap`、
  `hello-maui-app-api20-permissions.hap`、`hello-maui-app-unsigned.hap`（前 4 个自签名、设备会拒绝，需要重签；
  最后 1 个未签名、是重签安装路径）；大小与 SHA-256 不做固定约定，
  以随包 `SHA256SUMS` 为准（解包后 `sha256sum -c SHA256SUMS` 全过即可），kit 整包与内容树见 `device-test-kit` release 说明的「## Integrity」或 `.tar.gz.sha256` sidecar。

## 2. 环境要求

- HarmonyOS / OpenHarmony 设备，**arm64（aarch64）**
- 系统 API **26** 最佳；API 20 亦可（同版本另有一份 `openharmony20.0` 构建）
- 需要允许安装**调试/自签名**应用（设置 → 安全 → 允许安装外部来源，或开发者模式）

---

## 3. 安装与启动

**方式 A（推荐，仅设备即可）**
1. 把 `hello-maui-app.hap` 拷到设备（U 盘/文件管理器/局域网）。
2. 在文件管理器中**打开该 hap**（或用系统"应用安装器"打开）→ 按提示安装。
3. 安装失败时**记录完整错误文案**（签名错误 / 策略限制 / 未知来源等）并回传；包内 4 个默认 hap 报 `9568257`（自签名被拒）或 `9568344`（profile 未绑定你的 UDID）属预期，先按 `自签说明.md` 重签 `hello-maui-app-unsigned.hap`，不必回传该错误本身。

**方式 B（若设备侧允许 hdc）**
```bash
hdc list targets          # 能看到设备
hdc install hello-maui-app.hap
hdc shell aa start -a EntryAbility -b com.example.hellomauiapp   # 或直接从桌面图标启动
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
| N7 | **无障碍状态日志** | 启动应用后查看日志 | 出现 `[maui] accessibility provider status=N`：**1=已附着**（理想）；0=未附着（启动初值，属预期）；2/3/4 及更大的 `unknown status` 请连同该行一起回传（含义见 §5b）|

**日志采集（如有 hdc）**：`hdc hilog > log.txt` 或过滤应用包名；无 hdc 时请截图该行或应用内日志区域。

## 5. 已知限制（**不是缺陷**，无需上报）

| 项 | 说明 |
|---|---|
| 读屏/无障碍 | 暂未接入系统读屏节点（数据层已完成，平台绑定待做）|
| BlazorWebView | **进行中**：NuGet 包引用、资产映射、hap 资产管线与 ArkTS bootstrap 已就绪；托管 `WebViewManager`/handler 接线（里程碑 2b）待做，本轮包内未含 Blazor 演示页（故无需测试）|
| HybridWebView | **已实现**：JS→.NET 往返见 N6，资源服务已就绪 |
| Hot Reload / 诊断 overlay | 热重载未实现（诊断描边需应用内开关）|
| Pinch | 需**两根手指**同时接触（单指无效）|
| 悬停 | 需**鼠标**（触摸设备无悬停）|
| 相机/通知/传感器 | 模拟器上读数为模拟值，属正常 |

---

## 5b. 日志关键字对照（回传时请附对应行）

| 测试组 | 关键字（在应用日志/`hdc hilog` 中过滤）| 期望 |
|---|---|---|
| 启动/渲染 | `[maui] accessibility provider status=` | **1 = 已附着**（理想）；2/3/4 请连同该行回传 |
| 无障碍 | 同上（status 行即可）| 读屏能遍历控件（若可开启）|
| 蓝牙（N1/N2）| `bluetooth` | 权限提示 / 设备列表 / 发现事件；失败时可见不可用提示 |
| 打印（N3）| `print` | 出现系统打印界面；任务名正确 |
| 联系人（N4）| `contacts` | 返回姓名+电话；拒绝授权时为空白 |
| 日历（N5）| `calendar` | 近期日程 / 新增成功 |
| Hybrid（N6）| `HybridWebView` / `__hwvInvokeDotNet` | JS→.NET 返回结果回显 |
| WebView（K1/K2）| `webview` / `eval` | 页面加载/返回正常 |
| IME（E1–E5）| 输入法相关系统日志 | 键盘弹出、上屏正常 |
| 通知（H1）| `notification` | 通知栏出现标题/正文 |
| 相机/选择器（I1–I3）| `picker` / `camera` | 系统界面出现并回传结果 |

**status 值对照（0–4；界面/日志对更大值显示 `unknown status`，请原样回传）**：

| 值 | 含义 |
|---|---|
| 0 | 未附着（启动初值，属预期）|
| 1 | 已附着、回调注册成功（**理想**）|
| 2 | 收到 frame node，但因不是 CUSTOM 节点被拒 |
| 3 | 收到 NodeContent，但 CUSTOM 节点未创建/加入 |
| 4 | CUSTOM 节点已加入，但 provider 拒绝 |

**采集建议**：有 hdc 时执行 `hdc hilog > log.txt`（全程录制），并在每个失败项旁标注时间点；无 hdc 时截图或复制应用内日志区。

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

---

## 8. 本轮新增能力（2026-09-22 批次，M1–M10）

> 本轮新增：运行时权限、连通性、剪贴板、邮件/短信/拨号、截图、地理编码、窗口生命周期/安全区、
> FontImageSource 与 SwitchCell/EntryCell/ImageButton、读屏公告与无障碍自检、Shell 扩展。
> **注意**：默认演示页（含 permissions 变体）**没有**这些能力的按钮。逐项点按需要一个**功能探针 hap**
> （由交付方随包提供）。若你的包里没有探针页，请对 M1–M6、M8、M10 登记「未测（本包无入口）」，**不要判失败**；
> M7、M9 现在就能测。（§4b 的 N1–N7 同理以各自入口是否存在为准；没有入口的项按同一口径登记。）
> 完整细节与取证关键字见同批交付的《新功能真机验证清单》（若未随包，本节即可满足填写）。
>
> **当前 kit（#22，2026-09-24）**：自 #17 起的全部安全/性能/启动修复都已在本包（bundleName 白名单校验、hvigor/安装器锚定、ElfSigner 数据保全、符号链接跳过、外来签名不静默洗白、URL 允许列表、反向回调守卫、路径规范化、TLS 绝对路径 `dlopen`；帧分配 **241,688 → 4,504 B/帧**；P17 启动跳过重复解压、H7 rawfile 文件描述符直读、headless 变体 abc `13.0.1.0`），并在 kit #22 追加**设备里程碑回灌**——宿主 `DT_NEEDED` 收窄为 5 库（缺库设备也能 dlopen）、可选系统 API 全部按需 dlsym、HAP 内 `resources.index`（restool）、启动解压 ZIP offset/length + mkdir、DevEco `modelVersion 6.0.2` 工程布局。2026-09-24 真机里程碑（kit #18 + 测试方 5 项本地修复首次完整运行）见 `docs/plans/2026-09-24-ohos-device-milestone.md`；**stock kit #22 尚未上机**，本轮即首次复测。主选为 kit #22 本身，对照载荷（dynpkg/normalized/importb/importd/importprobe a–c）与 P1–P4 仍挂在同一 release。

| # | 能力 | 步骤 | 期望 | 未通过时抓什么 |
|---|---|---|---|---|
| M1 | 权限 | 探针页请求相机 → 允许；再请求一次；看 `CheckStatus` | 首次弹**系统授权框**；允许后为 `Granted`；拒绝后再请求**不再弹窗**且为 `Denied`；应用不崩溃 | `files/dotnet-status.txt` 的 `[maui] permission request …` 行；hilog `[maui] permission request failed:`；弹窗截图 |
| M2 | 连通性 | 探针页看 `NetworkAccess`；关/开 Wi-Fi 或飞行模式 | `Internet` ↔ `None`/`Local`；变化事件次数增加；不崩溃（`ConnectionProfiles` 为空属预期）| 数值前后截图；hilog `[maui] networkKit unavailable…` |
| M3 | 剪贴板 | 应用写文本 → 读文本（首次弹 `READ_PASTEBOARD`）→ 切到别的应用复制后再回来 | 读回一致；变化事件触发；拒绝授权后读为 `null`、不再弹窗；不崩溃 | 弹窗/结果截图；hilog `[maui] clipboard op …` / `clipboard permission request failed` |
| M4 | 邮件/短信/拨号 | 探针页三个按钮（带收件人/号码/正文）| 系统邮件/短信/拨号应用打开且字段预填；设备无对应应用时应用保持稳定 | 系统应用截图；hilog `[maui] ability start dispatched: kind=0` / `failed: kind=0 …` |
| M5 | 截图 | 探针页点「截图」，显示尺寸与字节数 | 有效 PNG；`Width×Height` = 窗口快照尺寸；临时文件不残留；不崩溃 | 导出 PNG + 尺寸截图；hilog `[maui] screenshot rejected: …` / `screenshot failed:` |
| M6 | 地理编码 | 地址→坐标、坐标→地址各一次 | 有结果，或**干净的空结果**（无网络/拒绝定位权限时）；绝不抛异常 | 结果截图；hilog `[maui] geocode op …` / `location permission request failed:` |
| M7 | 窗口/安全区 | 启动看日志；观察状态栏/刘海是否遮挡；点 Entry 弹出键盘 | 生命周期 `Created` 先于 `Activated`；状态栏/手势条/刘海不遮内容；键盘不改变安全区内缩（已知限制）| `dotnet-status.txt` 的 `[maui] window created` / `[maui] lifecycle …` 行；截图（键盘前后）|
| M8 | 图像/单元格/ImageButton | 探针页看 FontImageSource 与 ImageButton；点 SwitchCell、EntryCell | 字形清晰不空白；按下/点击有反馈；开关与文本双向同步 | 截图/录屏 |
| M9 | 无障碍 | 点壳左下角 `A11Y` 自检；开启系统读屏后遍历控件 | 自检显示 `1 (attached - expected)`；控件可聚焦朗读、双击激活；不崩溃 | 自检弹窗截图；`dotnet-status.txt` 的 `[maui] accessibility provider status=<n>` 行 |
| M10 | Shell 扩展 | 探针页切 TabBar/FlyoutBehavior；看 header/footer；带 SearchHandler 的页 | 底栏/抽屉行为符合设置；header/footer 为抽屉首/末**纯文本**行；本版**不出现**搜索框（已知缺口）| 截图/录屏；`dotnet-status.txt` 的 `[maui] shell search attached …` / `flyout header=…` 行 |

**权限声明注意**：剪贴板读取 `ohos.permission.READ_PASTEBOARD` 与坐标→地址 `ohos.permission.APPROXIMATELY_LOCATION`
默认包**未声明**。探针包构建时在 §1b 命令上加
`-p:'OpenHarmonyExtraPermissions="ohos.permission.READ_PASTEBOARD;ohos.permission.APPROXIMATELY_LOCATION"'`
（`-p:` 参数整体用单引号包住，否则 MSB1006）。声明本身不会授权：首次使用仍会弹窗。

**日志提示**：托管侧的 `[maui]` 行写在应用沙箱 `files/dotnet-status.txt`（不在 hilog）；壳侧 `[maui]` 行（如
`[maui] permission request failed:`、`[maui] ability start failed:`、`[maui] screenshot rejected:`）在 hilog。
两者都取到最好；只能取其一时请在回传里注明。

**下一批（M11–M13，2026-09-23）**：另有 12 项——真实缺陷修复（窗口 `Activated` 必触发；分组 `CarouselView` 展平且页码一致；阴影按偏移/模糊/颜色渲染；`SecureStorage` 在 HUKS 静默时回退并写一次性状态；应用内资源按 payload 优先 + `resources/rawfile` 兜底解析）、UX 深化（滚动惯性/边缘夹紧、自动隐藏滚动条、焦点环、悬停 Tooltip、键盘加速键、窗口 Overlay 与 `IPlatformApplication.Current`）与原始 HAP 资源桥（`resources/rawfile/**`，8 MiB 上限，缺文件 `FileNotFoundException`）。
这些项目前**只有离机验证**（编译 + 交互套件源码契约 pin + rawfile scratch 驱动），无真机证据。默认包可直接观察滚动惯性与滚动条（长列表页）；其余需**功能探针 hap**或重打包 hap，没有入口请登记「未测（本包无入口）」，不要判失败。逐项步骤/期望/取证关键字（含加速键键码）见随包《新功能真机验证清单》M11–M13。

### 8b. 若应用启动即崩（JsError / exit 254）

**先对错误分类**：若 hilog 报 `ReferenceError: Cannot find module 'ets/entryability/EntryAbility' , which is application Entry Point`（约 1 秒退出 / `exit 254`），那是旧 kit（kit #10 之前）的 ArkTS 壳 abc 入口 record 缺陷，已在 kit #10 修复并获真机确认（见 `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md`）；abc 版本（kit #11）与宿主加载（kit #12）分支也已清除，**kit #22 不含这些旧缺陷**。当前 kit 的启动相关修复：P17 跳过重复解压、H7 rawfile 文件描述符直读、headless 变体 abc `13.0.1.0`，以及 kit #22 的设备回灌（宿主 5 个 `DT_NEEDED` + 可选 API 全部 dlsym、HAP `resources.index`、ZIP offset/length + mkdir；stock kit #22 未上机）。安装阶段的 `9568257` 是自签名包的预期拒绝（见 §1 签名状态），先重签再谈启动。

**其他启动崩溃先别做 M1–M13**：按 §5b 采集 hilog（`hdc shell hilog -r` 后重录）与沙箱 `files/dotnet-status.txt`，然后用
`sh tester-run.sh --kit-dir ./device-test-kit --probes ./probes` 跑 P1–P4 启动探针（探针 hap 未签名，需先按
`自签说明.md` 自签），按「五层决策表」回传结论：P1 失败 = 设备/框架/包波段；P2 失败 = 宿主 `.so` dlopen；
P3 失败 = 宿主导出/链接命名空间；P4 失败 = 缺依赖（`PROBE4` 行里的库名即答案）；P1–P4 全过 = 崩在
.NET 运行时/主启动。探针与决策表：`docs/plans/2026-09-21-ohos-crash-probes.md`。`tester-run.sh` v6r2 会自动采集
`hilog/hilog-applib.txt`、`hilog/hilog-dlopen.txt`、`device/app-libs-arm64.txt`（含别名注册行
`[openharmony-host] … bound via alias '…'` 与首帧判定），无需手工 grep。
