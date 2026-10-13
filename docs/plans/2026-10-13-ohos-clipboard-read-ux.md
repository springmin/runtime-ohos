# CLIPBOARD-READ-UX：剪贴板「真读」路线调查与指引（2026-10-13；无构建、无 ow/maui 改动）

> 结论：真读两条路——① **用户触发粘贴（推荐）**：物理键盘 Ctrl+V 在 MAUI 文本框**零权限可用**，同/跨应用数据均真机闭环（系统在 Ctrl+V 窗口内一次性放行）；② **ACL profile**（`READ_PASTEBOARD` + system_basic 签名）——常规三方应用装机即拒/需设备侧授权，适合 OEM 预装。触摸屏的「系统粘贴菜单」在 MAUI 自绘文本框不可达（隐藏输入被 XComponent 面盖住）——缺口在壳/切片（非 ArkWeb）；触屏产品化需壳级入口（#56 候选）。应用侧无需任何改动或权限。

## ① 真机证据（HAD-W32 / OH 7.0.0.111 / 2in1，互斥锁独占；app = pre55 合并树 `all`，8 个非 ACL 权限，无 READ_PASTEBOARD/SECURE_PASTE）

- **Ctrl+V（同应用数据）**：`app://clipboard/roundtrip/UXCHK-77` 写后子窗 Entry `seed`→`seedUXCHK-77`（uinput 注入；服务 `IsPermissionGranted denied ×2`（READ_PASTEBOARD/SECURE_PASTE）后读取仍成功）。
- **Ctrl+V（跨应用数据）**：浏览器 `com.huawei.hmos.browser` 复制错误页文本（服务 `SetPasteData rawDataSize=8092`，owner=browser）；MAUI 子窗 Ctrl+V → 隐藏输入 layout dump = `seedUXCHK-77\n无法访问此网站…ERR_NAME_NOT_RESOLVED`，UI 同显（ux14）；服务侧同前（两次 denied 后 `GetLocalData# GetPasteData success`）。
- **系统粘贴菜单（长按）**：自绘 Entry 长按无菜单（ux15）；隐藏输入 `sub-1__input`（pos 0,0 h56，声明在 XComponent 之前）被面盖住、指针不可达 → 触屏无系统粘贴入口。平台粘贴 UI 本身正常：设置搜索框出现系统「粘贴」钮（ux8）、浏览器地址栏「粘贴并搜索 'UXCHK-77'」（ux10，旁证）。
- **机制（OH 源码 `pasteboard_service.cpp`）**：`VerifyPermission` 无权限时检查 `InputEventCallback::IsCtrlVProcess(pid, IsFocusedApp)`——Ctrl+V（CTRL+V 二元组合、发往聚焦窗）后 **2 s 内一次性**放行（查后 `Clear()`），与数据 owner 无关；默认 shareOption=CrossDevice（仅显式 InApp 数据做同 token 校验）。无用户手势的直读（host NDK）仍拒——与本会话对照一致（roundtrip `read=null`）。
- 还原：MAUI 已停、hilog 已清、**锁已释放**；证据 scratch `/data/storage/el2/base/tmp/opencode/clipboard-ux/`（ux0–ux17、ux15.json、hilog-xv.txt、evidence.md）。

## ② App 侧推荐（零权限）

- 2in1/物理键盘：直接用系统 Ctrl+V（本已可用、零改动）；面向用户的话术 =「用户触发粘贴」。
- 触屏（无键盘）：当前无系统入口；如产品需要，做壳级入口（见 #56 建议），**不做 READ_PASTEBOARD**。

## ③ 系统侧路径（ACL profile；适用者与代价）

- `ohos.permission.READ_PASTEBOARD` = `availableLevel: system_basic` 的受限 user_grant；需 **ACL 签名 + 设备授权**（本例声明即装机拒 `grant request failed`，见前轮 PASTEBOARD-FIX）；获权后 host NDK 读封装已就位即通。适合 **OEM/系统集成商预装**；常规三方（debug/普通 release 签名）不可行。

## ④ 对 #55/#56 的建议（供产品决策）

- **#55**：边界句保留（「ACL profile 或用户粘贴触发」），补一句结论——**Ctrl+V 用户粘贴已真机闭环（同/跨应用、零权限）**；#55 内容与权限矩阵不因此改动。
- **#56（候选）**：若触屏粘贴进产品——壳级 `PasteButton`（ArkTS 系统安全控件，用户点击后一次性放行）→ 文本回灌隐藏输入/托管 Entry；估 1–2 人日 + 真机验收；否则文档化「物理键盘 Ctrl+V 或应用自绘入口」。

## 边界 / 不确定

- Ctrl+V 为 uinput 内核虚拟键盘注入（与物理键盘同通路，见 `2026-10-12-ohos-keyboard-input-check.md`）；未人工实敲；右键未单独可注入（鼠标无绝对定位）——架构上与长按同因不可达。
- 单机型/单镜像（HAD-W32 2in1 debug 域）；手机形态的系统菜单行为未验。
- 样例未加 opt-in 粘贴探针（需动 ow 样例 + 构建，规避并发切包）；本文件即本轮全部交付。
