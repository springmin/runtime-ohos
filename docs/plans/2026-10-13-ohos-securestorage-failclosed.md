# SECURE-STORAGE-FAILCLOSED：SecureStorage fail-closed 开关（2026-10-13）

> 结论：`OpenHarmonySecureStorage.FailClosed`（API 级、进程内全局）——置真时 HUKS 不可用/操作被拒 → `SetAsync` 抛 `InvalidOperationException` 且**不写入数据文件**；`k1:` 密封值解密失败 → `GetAsync` 抛错而非静默 null（畸形 base64 仍按既定返回 null）。置假（**默认**）保持现行每安装文件密钥回退与一次性状态告警（PI1 原文不动）。
> 默认论证（opt-in + 文档）：切片现行契约即「HUKS-first + 文档化回退」（覆盖矩阵、PI1 pin、kit14 降级断言）；默认翻转会让无 HUKS 宿主（headless/缩减镜像/旧壳）上的既有 app 从「弱存」变为「Set 抛错」——属行为破坏，先由凭据类 app 显式声明；安全默认翻转候选记 §4。

## 1. 实现（maui `ad15ff83a3`，3 文件 +100/−1）
- `OpenHarmonySecureStorage.FailClosed` 公开静态开关（与 `OpenHarmonyDiagnostics.Enabled` 同形）；Set 在 HUKS 路径失败后、回退写盘**前**判真抛错；Get 对 `k1:` 解密失败判真抛错（消息含 key 名）；`PublicAPI.Unshipped` +get/+set 两行。
- `OpenHarmonyKeystore` 测试缝 `KeystoreTestMode`（`Working`/`OperationFailed`/`Unavailable`，internal；Working 为内存 XOR 往返）——设备无法按需制造的两种形态；置 `Off` 即真实宿主，仅套件编译可见。
- HUKS 成功路径逐字不变（Working 正控证明 k1: 落盘 + 读回）。

## 2. 测试（ow `feat/securestorage-failclosed` `5ecf0b2`；`test/maui-platform-verify`）
- 绿：**checks=806 / total=804 / floor 784，assert=True**（原 801，+5：source / off-device 拒绝且不落盘 / sealed 读拒绝 / HUKS-在但拒绝 / Working 正控，全 True）；perf within；rc=0；kit14·SEC3·PI1 原条零回归。
- 红控：两处门禁 `if (FailClosed)`→`if (false)`（保留 API 面与文案）→ **恰 3 条 assert=False**（off-device / sealed / op-failure）、rc=134，source 与 Working 保持 True。
- 切片独立编译（Release，`IsAotCompatible+EnableTrimAnalyzer+EnableAotAnalyzer`、`-warnaserror:IL2026,IL3050`）：0 error，IL 门禁绿。

## 3. 载体 / 提交
- maui：`feat/securestorage-failclosed` `ad15ff83a3` → `feature/openharmony` merge **`ffa9f68a77`**（--no-ff、普通推送；branch + merge 两 ref 已推）。
- ow：`5ecf0b2`（新分支已推；**未并 master**，pin 与套件重锚留合并波统一做）。
- 本文 + README 行 → runtime `feature/openharmony`。

## 4. 真机 / 边界 / 不确定
- **未上机**（本会话无 hdc/设备通路；设备锁与并发构建未取）：fail-closed 仅在「无 HUKS/操作失败」触发，在位 HUKS 的真机无此条件；正常路径行为逐字不变，跨进程真机证据沿用 kit14/P2a-HUKS。
- fail-closed 仍保留 codec 密钥文件（随机、非秘密）的创建/修复：「不落盘」指**凭据值**不落盘；旧 fallback 条目读语义保持（迁移仍开放）。
- 后续切可评估：默认翻转（安全默认 + 显式 opt-out）与 Asset Store 后端（mail 对齐，3–5 人日）。
