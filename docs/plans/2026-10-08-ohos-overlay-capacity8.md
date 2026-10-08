# 覆盖层容量 8 产品化（E4-FIX，2026-10-08）

> 设备 HAD-W32 / OpenHarmony-7.0.0.109 / API26 / 2in1（UDID `1BCE13C8…AEA0`）；本地 `.device-lock`
> 互斥 + 结束释放。装置 = probe8（9×HybridWebView，托管容量 8）+ 新壳四包 abc；主线 ow `3ecec5c` ·
> maui `619c40a483`（preprobe 后；套件 738/741 floor 721、abc 542,936）。原始件 =
> `/data/storage/el2/base/tmp/opencode/e4-fix/`（device/ 全量截获；haplog 均含时间戳）。
> 分支 ow `feat/overlay-capacity8`（从 `3ecec5c`；未并 master、未强推）；#49–#53 资产未动。

## 修法（ow `feat/overlay-capacity8`：壳四包 Index.ets + 门禁）

- **逐槽表全派生**：`WEB_SLOT_MAX=8`（表长上界）+ `WEB_SLOT_DEFAULT_MAX=4`；18 张逐槽表 + nav
  两组由 `slotBooleans/hotSlotBooleans/slotNumbers/slotStrings/slotControllers/slotNavigations`
  按常量生成，禁止硬编码长度（E4 根因 = 只改常量、18 张表仍长度 4 → 槽≥4 建而不挂）。
- **哨兵越界防护**：`slotController/ensure/destroy` 的 `=== null` → 真值判断；nav 标记表加
  `navSlotIndexable` 显式边界 + `!x`（消除 R1 的 `navProgrammatic[slot].url` 越界 TypeError 类）；
  suspend/resume 用 `copySlotBooleans` 复制可见性向量。
- **默认 4 + 显式开关**：服务容量默认 4；`OHOS_OVERLAY_MAX`（env，与托管池同源，首个托管命令时惰性
  读，避开页面先于 `Program.Run` 的时序）或 HAP rawfile `ohos-overlay-max.txt`（同值，页面加载即读）
  抬升到 8；容量事件按有效值广播、抬升时补发。AOT/降级语义不变（`webOverlaysMounted` 门未动）。

## 离线门禁（新 abc）

- arkts selftest **195/0**（+10：E4 派生/开关正反控；红控 = 追加一个硬编码 `[false×4]` 表 → 拒绝）；
  `--check-sources` 增 E4 契约（缺 helper/开关或残留 5 种 4 元素字面量即失败）。套件
  **739/742 floor 722 assert=True**（+1 `e4-capacity8` 四包 pin；原 MULTI-OVL/FIX-WVP 旧字面量 pin
  随动）。selftest-verify-kit 129/0、cut-kit 38/0、packs 25/0、hap-targets 80/0、tasks 9/0。
- 四包重编：ui abc **548,192 B / `ab5da50b…`**（原 542,936/`f18f0855…`），headless 24,324 不变，
  provenance 重生成、四包逐字节一致；`verify-kit.sh` EXPECT_ABC → `548192,24324`（注释注明）。

## 真机（cap8 = probe8 + 壳 + rawfile=8；default = 无 rawfile）

| 轮 | 装置 | 结果 |
|---|---|---|
| rA-default | probe8 + 新壳 | `web capacity: 4`；仅 create 2–3、serve 槽 0–3；槽 4–7 被容量夹取抢占；rootWebArea=4；0 app fault；app 253,684 kB/70 thr、render×5 |
| rB1/rB2-cap8 | 同件 ×2 冷启 | `web capacity: 8`；create 2–7、serve 槽 0–7 全覆盖；rootWebArea=8 ×2；pid 稳定；0 app fault；app 260,968/271,420 kB、render×9 |
| rC-churn10 | 同 cap8 ×10 冷启 | 10/10 轮 `capacity8/create7=1/serve7/render=9/appErr=0`，pid 每轮新（61373→7038）；明细 `rC-churn10b-churn.txt` |
| rD-soak | 同 cap8 40 min | 60 s×40 采样：app pid 10977 恒定、RSS 258,236→266,612 kB（无单调增长）、线程 68–69；9 个 render pid 全程恒定（合计 574.6–577.0 MB）；终态 rootWebArea=8、0 fault |
| rE-main | kit #53 主窗件 + 新壳 | 主窗零回归：capacity 4、serve 槽 0–1（A/B）、`window title applied`、rootWebArea=2、0 app fault；app 250,744 kB/70 thr、render×3 |

- 8 槽 vs 4 槽：render 进程 **5→9**，render RSS 合计 **318→598 MB**（每个 ~69–70 MB）；app RSS
  254→261–271 MB、线程 70 恒定、主窗 fps 无新异常；平台侧 8 ArkWeb 实例并挂（`rootWebArea=8`）。

## 默认建议与余项

- **默认维持 4/2**（发布件不动）；需要 5–8 的应用显式 `OHOS_OVERLAY_MAX=8`（托管 + 壳同源；不能设
  env 的包用 rawfile 同值）。依据：8 槽常驻多 ~4 个 render（~+280 MB 实测），且本波仅 2in1/debug 单机。
- 余项：5–8 手机域/release 未验；env 注入路径未走独立 managed 探针（本波真机走 rawfile=同解析/夹取
  代码，env 只做静态 pin）；render 内存为 pid 采样、非 cgroup 口径。

## 恢复 / 纪律

- 设备恢复：卸载探针、重装 e4 恢复件 `a11ysc/fix-hap.hap`、hilog 缓冲回 512 K、本锁释放、
  `/data/local/tmp` 清理。未动 runtime/maui 切片与 #49–#53 资产；本文件提交 runtime-ohos
  `feature/openharmony`（普通提交，路径限定）。
