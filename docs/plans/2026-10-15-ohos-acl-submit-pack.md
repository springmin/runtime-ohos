# ACL-SUBMIT-PACK：`READ_PASTEBOARD` 申请材料包（填表即贴，2026-10-15）

> 目的：把 CLIPBOARD-ACL（ACL-gated `clipboard` 特征）与 RELEASE-FIRST-SIGN（发布材料已落地）固化为 AGC「项目设置 → ACL 权限」可直接粘贴/照做的提交材料——申请正文（中/英，填表即贴）、控制台步骤、附件/证据清单、提交后动作（同一 Profile → 新 `.p7b` → 一键验收）。
> 输入：`2026-10-03-ohos-agc-acl-application-pack.md`（结构与先例）、`2026-10-15-ohos-clipboard-acl.md`（ACL 特征与验收口径）、`2026-10-15-ohos-release-first-sign.md`（证书/Profile 落点）、`2026-10-04-ohos-release-signing-workflow.md` §3（`clipboard-acl-accept.sh`）。
> 边界：不登录 AGC、不代提交；字段名/入口/审核口径以控制台为准；本 session 不处理上游 PR。bundle = **`mauidemo.dotnet.springmin.com`**；发布证书已签发（3 链，Leaf `CN=冉启春(2044064257653363457)\,Release`）；Profile 已建（type=release、无 device-ids、`allowed-acls` 现为空）。
> 现状（不夸大）：Ctrl+V 用户粘贴（系统一次性窗口，零权限）与触屏 `PasteButton` 点击粘贴（安全控件，默认 ON）**已可用**；**ACL 增量 = 程序化读**（读回显/自动化回填等无系统粘贴入口的路径）；当前程序化读被服务拒（`GetPasteDataInner# check permission failed` → 托管 null），这正是本申请要解决的。

## 1. 申请正文（AGC「申请原因」≤256 字符，填表即贴）

- **权限**：`ohos.permission.READ_PASTEBOARD`（受限；`availableLevel=system_basic`、user_grant；入口 = AGC「项目设置 → ACL 权限」，单次 ≤30 条、可附 1 附件 ≤500 MB）。
- **中文**（238 字符）：
  > 跨平台框架（.NET MAUI）应用申请 READ_PASTEBOARD：用于用户显式触发的剪贴板读取与粘贴回填——应用内自绘粘贴入口、读回显（回读刚写入的文本用于校验/展示）与自动化回填（测试/脚本把剪贴板文本填入聚焦输入框）。物理键盘 Ctrl+V 与系统 PasteButton 已覆盖手动粘贴；自绘/自动化路径需程序化读取（系统仅对 ACL 授权应用放行）。仅在前台、用户触发时读取；不后台轮询、不写入/不清空剪贴板、不读取跨应用数据。目标设备 PC/2in1/平板。
- **English**（252 字符）：
  > Cross-platform .NET MAUI app requests READ_PASTEBOARD for user-triggered read-back (in-app paste, echo check, auto-fill) lacking a system paste entry. Ctrl+V/PasteButton cover manual paste. No polling, writes or cross-app reads. Target: PC/2in1/tablet.

- 拆解（供审核追问时展开，不必入表）：

| 要素 | 内容 |
|---|---|
| 用途 | 用户显式触发的剪贴板读取/粘贴回填 |
| 使用场景 | 应用内自绘粘贴入口；读回显（回读刚写入的文本用于校验/展示）；自动化回填（测试/脚本把剪贴板文本填入聚焦输入框） |
| 为何必需 | Ctrl+V 与 PasteButton 已覆盖手动粘贴；无系统粘贴入口的路径需程序化读取，系统仅对 ACL 授权应用放行（普通签名声明即装机拒 `9568289`）；宿主 NDK 读封装已就位、获权即通（零代码改动） |
| 最小化承诺 | 仅前台、用户触发时读取；不后台轮询；不写入/不清空剪贴板；不读取跨应用数据 |

## 2. 控制台步骤（项目设置 → ACL 权限 → 新增 → 提交）

前置（已具备，核对用）：AGC 已建项目与应用（bundle `mauidemo.dotnet.springmin.com`）；「证书、App ID 和 Profile → 证书管理」已登记发布证书（SHA256 指纹与 `maui demo.cer` 一致）；Profile 已建（release、无 UDID、ACL 空）。

1. 「项目设置」→「ACL 权限」→「新增」（申请受限权限）。
2. 搜索/勾选 `ohos.permission.READ_PASTEBOARD`。
3. 「申请原因」粘贴 §1 正文（按控制台语言选中文或 English）。
4. 上传附件（§2.1 清单；可选）。
5. 使用场景/设备类型：PC/2in1/Tablet（与发布 Profile 的设备类型一致）。
6. 「提交」→ 等待审核（时效以控制台为准）。

### 2.1 附件/证据清单（截图 + 视频脚本建议）

| # | 证据 | 内容 | 取材 |
|---|---|---|---|
| A | 截图 1 | 应用内聚焦输入框 → 长按 → 粘贴浮层出现（入口态） | TOUCH-PASTE 真机轮（长按 → `bubble shown`） |
| B | 截图 2 | 浮层上安全控件（PasteButton）点按（授权态） | 同上（点按后 `pasted 13 chars`） |
| C | 截图 3 | 文本落入目标输入框（结果态 = 目标行为） | 同上（标题回显 `touchpaste: text='…'`） |
| D | 视频脚本（30–60 s，可选） | 长按 → 浮层 → 点按 PasteButton → 文本落框；如需展示增量路径，补「读回显/自动化回填」界面片段 | 按 A–C 步骤录制 |

- 判读注记（照实写）：A–C 演示的是**当前已可用的用户粘贴入口**（零权限）；申请 ACL 是为了**无系统粘贴入口的程序化读**（读回显/自动化回填）也能放行。当前无 ACL 时程序化读被服务拒绝（`GetPasteDataInner# check permission failed`），不要宣称已读通。
- 既有真机证据指针（可截取/引用，勿重新解读）：`2026-10-15-ohos-touch-paste-default.md` §②（长按浮层 → PasteButton → `pasted 13 chars`）；`2026-10-13-ohos-clipboard-read-ux.md` §①（Ctrl+V 同/跨应用零权限闭环）。

## 3. 获批 → Profile → 新 `.p7b` → 一键验收

1. **获批后**（审核通过）：AGC「证书、App ID 和 Profile → Profile」→ 打开既有 release Profile（`mauidemo.profileRelease.p7b` 同源）→ 在受限权限/ACL 处勾选 `ohos.permission.READ_PASTEBOARD`（若控制台已自动写入则跳过勾选）→ 保存/更新 → **重新下载 `.p7b`**。
2. **落料**：新 `.p7b` 放 `~/Documents/ohos/release/`（与 `release.p12`、`maui demo.cer`、`release.p12.pwd` 同目录）。建议**替换**旧 `mauidemo.profileRelease.p7b`——该目录保留唯一 `*.p7b`，多候选时一键脚本 fail-closed（要求显式 `--profile`）。
3. **通知我方**（runtime 侧）跑一键验收；消息带上「新 p7b 文件名/落点 + 设备是否在线（独占锁）」。命令（在 ow 仓根执行）：

```sh
sh scripts/clipboard-acl-accept.sh --build --sign release \
    --profile "$HOME/Documents/ohos/release/<新下载的>.p7b" \
    --key "$HOME/Documents/ohos/release/release.p12" \
    --cert "$HOME/Documents/ohos/release/maui demo.cer" \
    --key-pwd-file "$HOME/Documents/ohos/release/release.p12.pwd"
# 只验 Profile ACL、不建不签不装：附加 --dry-run
```

4. **验收口径（3 条，全绿才放行）**：① `bm dump` 回读含 `READ_PASTEBOARD` 且 `granted`（`allowed-acls` / `requestPermissions.granted` 两形态皆认）；② `app://clipboard/write/<marker>`（壳写，零权限）→ `app://clipboard/read`（宿主 NDK 读）经 hilog 取回 marker；③ 既有用户路径（Ctrl+V / PasteButton）零回归。
5. **失败形态对照**：装机 `9568289 ... grant request permissions failed` = Profile 未带 ACL（p7b 还是旧件/未获批）；`read null` + `GetPasteDataInner# check permission failed` = 服务侧未放行；预检 fail-closed = `acls.allowed-acls`（或 `restricted-permissions`）不含该权限，脚本不签不装。
6. 备选（若审核要求先上机验证）：提交弹窗内建「试用调试 Profile」（5 天、每应用 ≤5、绑 UDID ≤100、不可上架）→ `--sign external` 复核；本轮以发布链（release Profile）为主路径。

## 4. 边界 / 不确定

- 入口/字段名/附件形式（截图 vs 视频、是否必需）以 AGC 控制台为准；审核时效未知。
- 真机验收依赖设备回线（#57 已记 hdc 波动）；验收脚本对 `bm dump` 两种 ACL 形态容忍，真机形态以首次验收为准。
- 本申请不涉及 JIT（`ALLOW_WRITABLE_CODE_MEMORY` 走独立材料 ACL-PACK）；两申请可并行、互不引用为前置。
- 现状为单机型（HAD-W32 2in1）debug/release 签名域事实；手机域未验。

## 参考 / 提交

- 参考：华为《受限开放权限》《申请受限权限》《管理 ACL 权限（AGC）》；`2026-10-15-ohos-clipboard-acl.md` §1/§3；`2026-10-04-ohos-release-signing-workflow.md` §3；`2026-10-15-ohos-release-first-sign.md`。
- 提交：本文件 + `docs/plans/README.md` 索引行 → runtime `feature/openharmony`（`scripts/commit-paths.sh -m … -- docs/plans/2026-10-15-ohos-acl-submit-pack.md docs/plans/README.md`；`git -c http.version=HTTP/1.1 push`（旁路备用）；禁强推）。
