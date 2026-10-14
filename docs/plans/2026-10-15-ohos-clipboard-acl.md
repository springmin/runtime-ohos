# CLIPBOARD-ACL：剪贴板读的 ACL-gated 特征（ow 可做面 + 外部门槛）（2026-10-15）

> 结论：`clipboard` 特征重新入矩阵，但**只做显式 ACL 门控**——`READ_PASTEBOARD`（system_basic）仅在 `-p:OpenHarmonyFeatures=clipboard` 时声明（条目带 `<Acl>true</Acl>`：默认特征集与 `all` 绝不包含；声明时告警装机风险）。宿主 NDK 读封装（PASTEBOARD-FIX）获 profile 即通、零代码改动；普通签名包声明即装机拒（9568289 类），证书与 profile 在 AGC 侧（外部门槛）。
> 载体：ow `aa0b98b`（master；套件 matrix pin 随动；commit-paths；禁强推）＋ 本文（runtime `docs/plans/`）。

## 1. 申请路径（AGC 侧；材料结构参照 AGC-ACL-PACK）
- 入口：AGC「项目设置 → ACL 权限」申请受限权限（单次 ≤30 条）；`ohos.permission.READ_PASTEBOARD` = `availableLevel system_basic` 的受限 user_grant，审核口径以控制台为准。
- 正文/附件/提交顺序照 `2026-10-03-ohos-agc-acl-application-pack.md` 的结构（该文以 JIT `ALLOW_WRITABLE_CODE_MEMORY` 为例）；剪贴板场景的申请理由 =「用户显式触发的剪贴板读取/粘贴回填」。
- 获批后权限随 Profile 下发：更新 Profile → 用 ACL 证书重签。本仓 `selfsign`/`ohos-selfsign` 调试证书不在 profile 内，装不上属预期。

## 2. 为什么自签 debug 装不上（9568289 类）
- 声明该项的普通签名包在**安装期**即被拒：`bm 9568289 ... grant request permissions failed. PermissionName: ohos.permission.READ_PASTEBOARD`（PASTEBOARD-FIX 真机红控；`contacts/READ_CONTACTS` 同型）。
- 普通 bundle 运行时同样拿不到授权；服务端对 NDK 直读仍 `check permission failed`（`GetPasteDataInner`）——所以「默认/`all` 不带、仅显式开」是唯一安全姿势。

## 3. 获 profile 后：启用 + 验收
- 构建：`dotnet publish -r openharmony-arm64 -p:OpenHarmonyFeatures=clipboard`（可与 `network;...` 叠加）→ module.json 的 `requestPermissions` 含 `READ_PASTEBOARD` + reason/`usedScene`（`$string:permission_reason_clipboard`；模板字符串仍在全部当前包）。
- 真机验收（ACL 签名域）：① `bm dump` 回读含该项且 granted；② `app://clipboard/read|roundtrip` 经宿主 NDK（`OH_Pasteboard`+UDMF）返回真实文本（对照：无 profile 时服务 `GetPasteDataInner# check permission failed` → 托管 null）；③ 既有用户路径零回归——物理键盘 Ctrl+V（系统一次性窗口）与壳级 `PasteButton`（触屏、opt-in）照常。
- 离线门禁：`selftest-hap-targets` T5（默认不含 / `all` 跳过并点名 / 显式含+告警 / Acl-stripped 变异红控）；interaction 套件 matrix pin（四包 `clipboard→READ_PASTEBOARD` 且带 `<Acl>true</Acl>`）。

## 4. 边界 / 不确定
- 证书/profile 的申请与审批在 AGC 侧（时效、粒度、试用调试 Profile 5 天等未实测）；本仓只保证「profile 就绪 → 声明 + 读通」。
- 宿主 NDK 读的离线证据在 `selftest-host-clipboard.sh`（35 单测 + 红控）；ACL 真机域未跑（无 profile/证书）。
