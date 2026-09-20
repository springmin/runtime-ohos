# OpenHarmony .NET/MAUI 真机测试快速上手（外部测试方）

> 拿到交付包后：怎么装、先测什么、回传什么。结论以你设备上的实测为准。

## 1. 下载与校验

交付包在 `springmin/sdk-ohos` 的 release **`device-test-kit`**；同一资产也镜像在滚动 release **`workload-latest`**（二选一下载）：

```sh
base=https://github.com/springmin/sdk-ohos/releases/download
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz"   # 镜像：$base/workload-latest/device-test-kit.tar.gz
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz.sha256"
sha256sum -c device-test-kit.tar.gz.sha256        # ① 压缩包传输校验
mkdir -p device-test-kit && tar xzf device-test-kit.tar.gz -C device-test-kit
cd device-test-kit && sha256sum -c SHA256SUMS     # ② 包内逐文件校验（4 个 hap + 文档）
```

包内自带 **`SHA256SUMS`**，含 4 个 hap 与说明文档；**每次重签哈希都会变**，一律以随包的 `SHA256SUMS` / `.sha256` 为准。

## 2. 选哪个 hap

| hap | 用途 |
|---|---|
| `hello-maui-app.hap` | **默认包**（无额外权限）：UI、交互、手势、IME、通知、安全区、WebView、无障碍、Hybrid |
| `hello-maui-app-permissions.hap` | 追加蓝牙/打印/联系人/日历（首次使用弹运行时授权；PRINT 为 system_grant 不弹）|
| `hello-maui-app-api20.hap` | API 20 波段设备；band 值 `60000020` 解码为**平台 6.0.0 / API 20** |
| `hello-maui-app-api20-permissions.hap` | 同上，带权限 |

设备 API ≥26 用默认包；只有 API 20 波段设备才用 api20 包。

## 3. 安装

1. **无需安装 .NET 运行时**：运行时随 hap 打包在 `resources/rawfile/dotnet.zip`。
2. 把 hap 拷到设备（U 盘/文件管理器/局域网），在**文件管理器中打开**该 hap，按提示安装。
3. 需要**开发者模式** + 允许调试/外部来源安装（设置 → 安全，各 ROM 名称略有差异）。
4. 设备允许 hdc 时：`hdc install hello-maui-app.hap`；启动用 `hdc shell aa start -a EntryAbility -b com.example.hello-maui-app`，或直接点桌面图标（首帧为黑色导航栏 + 标题「Root」的长列表）。

## 4. 报 `9568344 install parse profile prop check error`

不是应用缺陷：hap 用调试 profile 签名，**profile 只绑定了示例设备 UDID**。二选一：

- 把本机 **UDID** 发回（`hdc shell bm get -u`，或 DevEco Studio → Device Manager → 设备信息）→ 我们按 UDID 重签发新包（哈希会变）；
- 按 `签名与UDID指南.md` 用 DevEco 自动签名后自助重签。

另：`E00C001 Operation restricted by the organization` = 设备策略关闭了 hdc → 改用文件管理器安装。

## 5. 五分钟测试路径（先跑这 5 条）

| # | 操作 | 通过标准 |
|---|---|---|
| 1 | 启动应用，看首帧 | 无花屏/黑块；文字清晰、控件不重叠、安全区不遮挡 |
| 2 | 打开一个 `DisplayAlert`（应用内「显示弹窗」）| 遮罩+对话框出现；「取消/确定」分别返回 false/true |
| 3 | 在 Entry 里打字（中英混输）| 键盘弹出、光标可见、上屏无重字/漏字、收起后布局恢复 |
| 4 | 打开 Hybrid 演示页，点按钮触发 JS→.NET | 调用返回结果并回显（`Echo`/`Add`）|
| 5 | 点左下角小按钮 **`A11Y`** | 弹出 Accessibility self-check（`accessibilityStatus` + 节点数）|

失败就记下步骤和现象；完整清单见 `验收说明.md`（A1–K2、N1–N7）。

## 6. 回传什么

**两条启动行**（应用日志区；有 hdc 时 `hdc hilog` 过滤应用包名，无 hdc 请截图）：

| 行 | 说明 |
|---|---|
| `[maui] openharmony build <ver> abi=<arch> provider=<n>` | 构建版本 + ABI + provider 值；启动早期出现，`provider=0` 属预期 |
| `[maui] accessibility provider status=<n>` | provider 附着状态；**1 = 已附着（理想）** |

`<n>` 映射（0–4；界面显示 unknown status 的更大值请原样回传）：

| 值 | 含义 |
|---|---|
| 0 | 未附着（启动初值，属预期）|
| 1 | 已附着、回调注册成功（理想）|
| 2 | 收到 frame node，但因不是 CUSTOM 节点被拒 |
| 3 | 收到 NodeContent，但 CUSTOM 节点未创建/加入 |
| 4 | CUSTOM 节点已加入，但 provider 拒绝 |

**关键字摘录**：`bluetooth` / `print` / `contacts` / `calendar` / `HybridWebView`、`__hwvInvokeDotNet` / `webview`、`eval` / `notification` / `picker`、`camera` / IME 输入法系统日志（完整表见 `验收说明.md` §5b）。

**结果模板**：照抄 `验收说明.md` §6 填写；安装失败附**完整错误文案**；有 hdc 时附 `hdc hilog > log.txt` 片段与各失败项时间点。

## 7. 相关文档

- 完整验收：`docs/plans/2026-09-19-ohos-hap-acceptance-for-testers.md`（包内 `验收说明.md`）
- 签名/UDID：`docs/plans/2026-09-19-ohos-signing-and-udid-guide.md`（包内 `签名与UDID指南.md`）
- 上手（开发）：`docs/plans/2026-09-20-ohos-dotnet-getting-started.md`
