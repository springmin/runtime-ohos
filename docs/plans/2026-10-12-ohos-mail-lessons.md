# MAIL-LESSONS：对照 mail M4 平台服务的 MAUI 侧核验（2026-10-12，只读）

> 口径：对照 `mail/docs/plans/2026-10-12-ohos-m4-platform-services.md` + `mail-ohos-port-analysis.md` 附录 D；
> 证据 = maui `src/Core/src/Platform/OpenHarmony/**`、ow `packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.28/**`、
> kit54-rev2 hap 解包（`/data/storage/el2/base/tmp/opencode/reg-kit54-rev2/device-test-kit/`）、本地 restool 复现
> （scratch `mail-lessons-audit/restest`）。无设备、无构建；设备显示引用既有轮次证据；不处理上游 PR。

## 逐项核验

| 项 | mail 结论 | MAUI 现状（证据） | 分类 | 建议 |
|---|---|---|---|---|
| A WebAuth | loopback（系统浏览器→127.0.0.1）同机可达；无 INTERNET 一律 EPERM；非 https 回跳走 chooser | 自定义 scheme 已端到端：`OpenHarmonyWebAuthenticator.cs:94-200/265-292` + 清单注入（`OpenHarmony.Hap.targets:607-615`）+ kit54 rev2 默认 hap 含 `myapp://callback`（`2026-10-11-ohos-webauth-decouple.md`）、隐式 chooser 真机通过（`2026-10-10-ohos-webauth-implicit.md`）；**未实现 loopback**。**INTERNET 默认关闭**：kit54 5 MAUI hap `requestPermissions` 为空（解包 module.json）；仅探针轮 `-p:OpenHarmonyFeatures=network`（`kit54-hap-verify.md` §8）；csproj 无默认 | 可做（loopback ≈1–2 人日）；INTERNET=有风险（默认关、无门禁） | 保留 scheme 主线；加可选 loopback 监听（CallbackUrl host=127.0.0.1 时自起 TcpListener，免 scheme 注册/chooser；仍受 INTERNET 约束）；`network` 特征进样例默认 + 验收清单 |
| B SecureStorage | `OH_Asset_*`（alias `flectar:{acct}:{slot}`、DEVICE_FIRST_UNLOCKED、无用户认证、sync never）；失败 fail-closed，文件回退需显式环境变量 | HUKS-first AES-256-GCM（`OpenHarmonySecureStorage.cs:95-156` + `host_keystore.c`，零权限）；**未用 Asset Store**；HUKS 失败静默落 per-install XOR 文件密钥（`:148-155` 仅一条 status），非 fail-closed | 已有（HUKS）／可做（Asset 后端 3–5 人日；fail-closed 开关 0.5–1 人日） | 低优先；若要凭据策略对齐 mail：host 加 `OH_Asset_*` 后端 + 默认 fail-closed（或至少开关，凭据类 app 禁文件回退） |
| C FilePicker | pickOpen/pickSave 桥；picker URI 仅 ArkTS 触达，拷入沙箱后托管才可见 | 已实现：`OpenHarmonyFilePicker`（`OpenHarmonyPicker.cs:248-263`，单/多选）；壳 `DocumentViewPicker`（`Index.ets:6068/7057`）→ base64 → 托管写沙箱 `OpenHarmonyPaths.CacheDirectory`（`WriteResult:204-223`）——边界同 mail。**无 save**（MAUI IFilePicker 无 save 语义；需 FileSaver 类另行桥） | 已有（边界正确）／save=按需可做（小） | 无即时行动；大文件被 per-result cap 静默丢弃（仅 status 行）→ 文档注明 |
| D 剪贴板（高） | NDK 读写零权限；**声明 READ_PASTEBOARD 安装即失败**（ACL，grant request failed）；ArkTS `getData` 无权限被拒（勿据此判 NDK） | 仅 ArkTS 路径：壳请求 `READ_PASTEBOARD`（`Index.ets:3746-3777`）+ 特征矩阵 `clipboard→READ_PASTEBOARD`（`OpenHarmony.Hap.targets:448-453`），且 **`OpenHarmonyFeatures=all` 含它**（`selftest-hap-targets.sh` T5 pin 10 权限）；SDK 定义 `availableLevel=system_basic`（`toolchains/lib/PermissionDefinitions.json`）。kit54 7 hap 均未声明——现状不炸装机，但 GetTextAsync 恒 null/HasText=false（代码路径推断，未上机）；写 op 零权限可用 | **有风险**：启用 `clipboard`/`all` 构建的 hap 装机即失败；读路径事实不可用 | **即时**：从 `all`/矩阵拆出 READ_PASTEBOARD（ACL-only 明示+门禁）；读改走 host NDK `OH_Pasteboard`（mail 零权限实证），删壳请求点；selftest/文档同步 |
| E launcher（高） | 三连：V2 index（去 compression + 6.1 坐标）、注入 labelId/iconId（ids_map）、resources.index+resources/** STORED；坏条目需卸载重装 | ①STORED=已满足（当前 sample 与 kit54 hap 全条 STORED、0 目录条目）；②labelId/iconId **未注入**（built/kit54 `module.json` 仅 `$string/$media`；ow/maui 无实现）；③index=**legacy**（26.0 带 `Restool 6.1.0.003`，因 minAPIVersion 默认 50002014/`targets:33`）——本地 restool 复现：仅 min→60000023/60100023 即 `RestoolV2`；api20 hap（min=60000020）已是 `RestoolV2`。旁证：系统 chooser 列 `com.example.hellomauiapp` 而非应用名（`2026-10-10`）；模板图标仅 64×64 | **有风险**（2/3 层缺失；应用名/图标与 `$r()` 类型资源解析预期失败，MAUI 侧未上机直证） | **即时**：26.0 默认 band 对齐 V2（或 restool 输入用 V2 坐标、终稿另存）；从 ids 表注入 labelId/iconId/…；图标 ≥512；验收 = `getStringSync($r('app.string.app_name').id)` 探针 + 桌面截图 + 卸载重装 |
| F 键延迟/重绘 | 每键全屏 2.8MP 重绘（NewBuffer 语义）+ debug 构建慢 10–30x | 不同源：XComponent vsync 帧循环、present 缓存无每帧 mmap（`2026-10-03-ohos-framepacing.md`：JIT/AOT p50 16.667ms、60.0fps）；物理键盘实敲 OK（`2026-10-12-ohos-keyboard-input-check.md` §3b）；interp 渲染受限 ≈21–44fps（已有 INTERP-DRAW2 面外剔除） | 不适用（非同一问题）；通用教训可借鉴 | 无即时行动；debug→release/AOT 已内建；脏区/缓存重绘思路仅当再优化 interp 时参考 |
| G 其他可搬 | NEEDED 检查、picker 沙箱、fail-closed、loopback 取舍 | host 依赖纪律已有等价（`host-deps.conf` + dlopen 降级 + `verify-kit` DT_NEEDED 断言）；picker 边界同（C）；fail-closed 缺口=B；loopback=见 A | 多数已有 | PDFium 仅当需要时按 mail 路径（prebuilt 进 `libs/**` 随签 + 先 `readelf -d` NEEDED） |

## Top 行动（按风险/价值）

1. **D（即时）**：拆除 READ_PASTEBOARD 特征/`all` 组合（装机失败面，`all` 被文档化就更危险）；host 加 `OH_Pasteboard` NDK 读（mail 零权限实证），删壳请求点；selftest（T5）/矩阵/文档同步。
2. **E（即时）**：端口 mail 三连修复——26.0 默认 V2 索引、labelId/iconId 注入、≥512 图标；加 `getStringSync`+桌面截图验收；测试改包必卸载重装（SceneBoard 条目缓存）。
3. **A**：`network` 特征进样例默认/验收清单（EPERM 文案对齐 mail）；可选 loopback 监听（≈1–2 人日）作为免 chooser 路线。
4. **B**：SecureStorage 增加 fail-closed 开关（0.5–1 人日）；Asset Store 后端仅在需与 mail 策略对齐时做（3–5 人日）。
5. **C/F/G**：仅文档注明（大文件 cap、release 已默认、NEEDED 纪律）。

## 边界与不确定

- D：mail 的 ACL 装机失败为本设备实证（同 HAD-W32 类设备）；MAUI 侧无「声明 READ_PASTEBOARD 的 hap」实测（7 个 kit hap grep=0），风险面 = 构建开关组合。
- E：legacy 索引在 MAUI 侧的设备行为未直接复验（壳只用 rawfile，`getRawFileContent` 可用；类型资源解析未走查上机）；minAPIVersion 抬高与设备 `apiCompatibleVersion`（50002014）的安装兼容需一次实测（mail 以 60100023 实装成功）。
- 本 session 只读：解包/复现均在 scratch，未构建、未用设备、未改上游。
