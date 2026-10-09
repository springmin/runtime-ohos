# L3/L4 壳侧加固：`loadData` `#` 编码 + 子窗 ask 限速（2026-10-08）

> 口径：ow `feat/loaddata-navrate` @ `e6e4f41`（自 E4 `feat/overlay-capacity8` @ `30a8651`；未并 master、未强推，普通推送 origin）；
> maui 不涉及（纯壳侧）。设备 HAD-W32 / OH 7.0.0.109 / API26 / 2in1（UDID `1BCE13C8…AEA0`）；`.device-lock` 全程互斥
> （A/B/补偿三轮）；#49–#53 资产未动。载体 = 壳四包 `Index.ets`/`SubWindow.ets` + 门禁 + 套件 pin + 样例探针。

## L3 选型（A/B）

- **A（选定）**：data 载荷 `#` → `%23`——主窗 `webDataPayload`、子窗 `childWebDataPayload`（各为 data op 唯一
  `loadData` 调用点）。data: URL 解码把 `%23` 还原为 `#`，文档逐字节回原；无 `#` 载荷不变。边界：载荷内已有
  `%XX` 序列原本就被引擎 data-URL 解码（平台既有语义，未变）。
- **B（未选）**：`onInterceptRequest` 合成 origin 直供。壳已有 hybrid/blazor 拦截先例，但需合成 origin + 每槽载荷表 +
  `isAppNavigation` 放行 + 响应构造，改变导航事件 URL 语义、扩大信任面；相对 A 无可观测收益。
- 门禁：`--check-sources` 增 L3 契约（helper + 主/子两路 wiring；红控 = 去 helper / 回退裸 payload → 拒并命名）；
  套件 `l3-loaddata-encode` 四包 pin。
- 真机 A/B（同 JIT 探针 HAP 仅换壳；轮 C = 状态路径补偿复测）：新壳（550,304）主 `p='tag#value'`/`color='rgb(51, 102, 255)'`、子
  `p='tag#value'`/`tap='CHILD HASH OK 1'` 完整；旧壳（E4 548,192）主 `p='NO-P'`/`color='NO-H'`、子无 eval 行，
  两窗 `web page` 原文均 `background:#101820%22%3E…`（裸 `#` 后整段片段化/编码化）。无 `#` 回归：主
  `p='plain value'`/`rgb(51, 102, 255)`、子 `CHILD-WEB-1`/`CHILD WEB TAP 1`。

## L4 限速（SEC7-F）

- 保留 B6 有界 pending（8 / TTL 5 s / URL 8 KiB）；新增**每槽固定窗** `SUB_WEB_NAV_ASK_BURST_MAX=6` /
  `SUB_WEB_NAV_ASK_WINDOW_MS=1000` + `SUB_WEB_NAV_ASK_DROP_LOGS=3`（`childNavAskAllowed`）。超限 fail-closed 丢弃
  （不建 pending、不通告 managed，导航保持取消）；**一次性批准/回放语义不变**；定长数组，风暴不增长。
- 红控（可测）：①arkts selftest 删准入分支/抽 burst 常量 → gate 拒绝并命名；②真机同一 30 次风暴（~0.9 s，应用
  逐条否决保页）：旧壳 `shell-asks=30`（`drops=0`；managed 22），新壳 `shell-asks=9`、`drops=3`（窗内 6+3，
  丢弃日志封顶 3）。两壳 0 SIGSEGV/SIGABRT，新壳全程无 THREAD_BLOCK。

## 离线证据 / 新 abc

- arkts selftest **203/0**（+8：L3/L4 正反控）；套件 **741/744 floor 724 assert=True**（+2 pin）；selftest-verify-kit、
  packs、cut-kit（38/0）、hap-targets（80/0）、tasks 全绿。
- 四包重编（22/23/24/28 字节一致）：ui abc **550,304 B / sha256 `9365743369b5d912…`**（E4 548,192）；headless
  24,324 不变；provenance 重生成；EXPECT_ABC → **`550304,24324`**（注释注明；cut-kit 同源推导）。

## 真机要点 / 不确定

- 探针 = `hello-maui-app` JIT（`app://web/datahash`、`datanohash`、`app://subwindow/openwebhash`、`openwebstorm`；
  旧壳对照 = E4 abc 同 HAP 换包）；主窗+子窗两路一致，`#` 与限速均有新旧对照。
- 不确定：旧壳首轮主窗 `#` 探针后出现 1 次 `THREAD_BLOCK_6S`（系统重启应用；新壳全程 0），轮 B/C 同流程
  未复现（旧壳 0 次），判为一次性探针时序/环境事件而非旧路径必然；单设备 2in1 debug 域不外推；主窗 data 在
  探针中需一次子窗开合才完成挂载（应用/探针时序观察，非壳契约）；选项 B 未落地（仅论证）。
- 载体：ow `feat/loaddata-navrate`（普通推送；不并 master/强推）；本文件 + 限制表 C5 行 → runtime
  `feature/openharmony`（`commit-paths.sh` 限路径；被拒 fetch/rebase 或旁路）。
