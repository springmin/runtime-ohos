# 最终收口：三项彻底修复合并（MAUI-CONSOLIDATE-FINAL，2026-10-02）

> 合并树 = ohos-workload `master`：MULTI-OVERLAY-FULL `0e0129e`（父 `ff4559c`）与 INTERP-FIX
> `c9916cd` 合并为 `04d2199`；pin 提交 `4674eba`（interaction/pixel/host-export 三 workflow
> 默认与 fallback → maui 切片 `07423dfe93`，注释 563/543、150/150）。全部线性、禁强推。
> DEVCOMPAT-DEFAULT `12be59c`、sdk-ohos `3842c25b2ef3` 已在各自 origin。

## 1. 三大修复（合并表）

| 修复 | 仓库 / 提交 | 内容 |
|---|---|---|
| MULTI-OVERLAY-FULL | maui-ohos `07423dfe93`（父 `75c410e798`）+ ohos-workload `0e0129e` | LRU 槽复用（owner 抢占/挂起/恢复重放）、同页多 Hybrid 全通道按槽（消息/invoke id 编码）、激活序 z-order、payload-in-libs appDir 探测；壳四包 abc 356,140/`2a90f0d7…` |
| DEVCOMPAT-DEFAULT | ohos-workload `12be59c` | payload 逐文件码签重写默认化（无扩展名→`.so`/`.bin`、恰 4096 B→+4 B、`dotnet.zip` 回退保原字节；逃生口保留） |
| INTERP-FIX | ohos-workload `c9916cd` + sdk-ohos `3842c25b2ef3` | 宿主 8 MB app 线程栈 + `interp=3` 关 GC 写屏障拷贝；rc.2 重建解释器产物 → `ohos-interpreter-pack-rc2.tar.gz`（2,409,070 B/`34709a94…`） |

## 2. 对账（合并树 `04d2199` + pin，maui `07423dfe93`）

- 切片 trim/AOT 分析器：0 error / 0 IL warning（IL2026/IL3050 = 0/0）。
- 交互套件：`[suite] checks=563 total=563 floor=543 assert=True`；`grep -c '[verify]'` = 563（declared==printed）；frame/a11y perf 全 `within=True`。
- 像素 `PIXEL ASSERTIONS PASSED`；导出 `OK: all 150 expected exports`（150/150）。
- 壳：preview.22/23/24 `abc-provenance.json` clean + preview.28 同源（ui 356,140 B sha256 `2a90f0d7…`；headless 24,324）；`selftest-verify-kit 108/0`；preflight 5/5。
- CI 5/5（push `4674eba`）：interaction `37037006009` / pixel `37037006283` / host-export `37037005900` / ridgraph `37037006008` / markdownlint `37037006135`。

## 3. 剩余缺口

- z-order 动态置顶只有断言/编译实测，重叠控件真机截图未取；hello-maui-app 的 Blazor `#app` 仍缺 `modules.json` 未挂载（razor 样例已挂载）。
- INTERP-FIX：stock JIT 路径未单独复测；匿名可执行映射未在 app 内枚举；rc.2 csc 并行活锁仅以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位。
- DEVCOMPAT-DEFAULT：4096 B 规则仅本镜像实测（7.0.0.105 未复测）；壳内嵌 bundle 绑定致异 bundle 启动 jscrash（既有，与本轮无关）。
