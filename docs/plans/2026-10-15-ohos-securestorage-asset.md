# SECURE-STORAGE-ASSET：SecureStorage Asset Store 后端 + fail-closed 默认翻（2026-10-15）

> 结论：新写入优先 **Asset Store**（`OH_Asset_*` NDK，DEVICE_FIRST_UNLOCKED；宿主 `host_asset.c` 注入表 + `host_optional.c` dlopen + `host-deps.conf` 禁直引），HUKS `k1:` 为第二强链，弱回退（每安装文件密钥）仅显式 opt-out。`FailClosed` 默认 **true**：双强链都不可用 → `Set` 抛错不落盘；索引值读失败 → `Get` 抛错（不再静默 null/弱存）。
> 载体：maui `feat/securestorage-asset` `adf40b4f11` → merge **`44da5f74f5`**（已推）；ow `ac265d6`（host）+ `da4a2e1`（套件/工作流 pin）（已推）；本文 + README 行 → runtime。

## 1. 后端设计 / 读兼容矩阵

- 索引 = 数据文件（值不落文件）：`a1:` = 值在 Asset Store（新写入）、`k1:` = HUKS 密封（P2a 旧数据）、明文 = 旧文件回退件；读按索引取后端（Asset → 旧链语义），旧数据零迁移可读；`Remove/RemoveAll` 清索引 + 尽力清 store 行（后台，不阻塞）。
- Asset 别名 = `maui.ohos.securestorage.asset.v1.<store-hash>.<key-hash>`（FNV-1a；key 名不落系统库/日志）；put 六属性（ALIAS/SECRET/ACCESSIBILITY=DEVICE_FIRST_UNLOCKED/AUTH_TYPE=NONE/SYNC_TYPE=NEVER/CONFLICT=OVERWRITE），本地界限 1–256 / 1–1024 B 先拒；get 整取或拒（不截断），`FreeResultSet` 恰一次（ParseAttr 视图不单独释放）；remove 仅 ALIAS。
- 宿主侧：`ohos_host_asset_{available,register_result,request}`（op 0/1/2；rc 0 成功 / 1 未找到 / −1 不可用或失败）；原始状态仅进诊断日志（值/别名不落日志）。不可用（无 libasset）→ `host_optional` 组不可用 → 走强链/拒绝。测试缝 `AssetTestMode` = Off/Working/Unavailable/WriteRejected；`KeystoreTestMode` 沿用。

## 2. fail-closed 默认语义

- `Set`：Asset 成功 → 索引 `a1:`；否则 HUKS（`k1:`）；双失败 → **默认抛 `InvalidOperationException`（不落弱存）**；opt-out（`FailClosed=false`）才写每安装文件密钥 + 一次性告警。
- `Get`：索引 `a1:` 读失败/缺失 → 默认抛；`k1:` 解密失败 → 默认抛（原语义保留）；畸形编码仍按既定返回 null。
- `IsHardwareBacked` = Asset ∪ HUKS。既有测试按新默认校准（kit14/SEC3/W22-14 显式 opt-out 后验弱链），红控保留。

## 3. 测试（红绿）

- 单测：`selftest-host-asset` **12 检查 / 单元 49/49**（六属性逐字节、服务拒绝携带原始状态、本地界限、整取、free 恰一次、NOT_FOUND/base64 协议）+ 红控（whole-copy 守卫关闭 ⇒ 必失败）；宿主构建 167/167 导出、UND 252、DT_NEEDED 白名单零变化。
- 套件：**checks=825 / total=828 / floor=808 / assert=True**（+9 ASSET；FAILCLOSED 按默认 ON 重校，均为 True）；红控：`if(FailClosed)`→false ⇒ **2** FAILCLOSED assert=False（rc=134）；`RecordAssetEntry` 关 ⇒ **4** ASSET assert=False；切片 Release 0 error / IL2026·IL3050（-warnaserror）= 0。

## 4. 真机证据（补丁 hdcp4；锁独占→释放）

- HAD-W32 / OH 7.0.0.109：JIT 探针 hap（新宿主 `1e156f42` 替换 + 重签；`app://secure/roundtrip`）：
  `roundtrip failClosed=True hardwareBacked=True assetAvailable=True match=True removed=True gone=True afterSet=bytes=30 file=bytes=0 plainInFile=False`；`report value=<null> file=bytes=0`；0 条 asset 失败日志；pid 稳定；`afterSet=30 B` = 仅 `a1:` 索引行（k1 密封行应 ≈90 B）⇒ Asset 后端服务本次读写；PRE55 还原 rc=0、锁释放。
- 降级路径（无 Asset / 写拒绝）无真机条件：以单测/套件缝口径（Working/Unavailable/WriteRejected 矩阵 + 红控）。

## 5. 重锚影响 / 不确定项

- 宿主重建 **375,712 B / `1e156f42…`**（was 371,616/`33ba896f`；导出 **167/167**、UND 252、DT_NEEDED 不变）；packs `.22/.23/.24/.28/.29` 本地同步（二进制不入仓）；**kit #58 随重锚**（EXPECT/宿主指纹）。
- 工作流 pin → maui `44da5f74f5`（interaction/pixel/host-export）；ac265d6 的 interaction 红因 = 套件 `l2ExportCount=164` vs 新 `host-exports.txt` 167，已随 `da4a2e1` 修复。
- 不确定：设备上 Asset 与 HUKS 同时可用，本次按 `assetAvailable=True` + 0 失败日志 + 30 B 索引行判为 Asset 服务；`a1:` 索引丢失时该 key 视为不可读（以文件为准，不做盲查询）；样例探针 `SecureStorageProbe.cs` 已提交，其 App/Program/csproj 钩子仍随并发会话文件状态（由其提交收口）。
