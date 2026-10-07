# L3-CONSOLIDATE-FINAL：M2–M4 链并入主线 / 四包一致 / 门禁 / pin / CI（2026-10-07）

> 口径：M2+M3+M4 链（基于 M1 主线 tip）一次并入——ow `master` ← `l3/m4-childweb` @ `544b14952e14`（merge `71c7fb6`）、maui `feature/openharmony` ← `l3/m4-childweb` @ `b833ab144e10`（merge `277967cc56`）；均 `--no-ff` 合并提交、普通推送、未强推；不切 kit（**#52 待切**）、#49–#51 资产不动。结论域 = 2in1 debug（E1）。

## 1) 合并

- 远端链 = 本地链的 tree 一致重放（ow M2 `921c4c6e`/M3 `8c0d9b2`/M4 `544b149`；maui `0ddc81da`/`2bdad3c90c`/`b833ab144e`）；合并树与链 tip tree 逐字节一致、无冲突（packs/SubWindow.ets 共存已含在链内）。
- ow merge `71c7fb6`（parents `a551013`+`544b149`）；maui merge `277967cc56`（parents `d1d485bb67`+`b833ab144e`）。

## 2) 四包一致（preview.22/.23/.24/.28）

- 合并树全量重编：ui abc **534,192 / `e6516424…`**、headless **24,324 / `798b2477…`**；host .so 重建 **367,520 / `ad7ab986…`**（与 M4 真机宿主逐字节一致；`.22/.23` 的 M2 旧宿主已同步）；provenance `3b92874c…`。
- `--install-packs` + .28 手动同步；`--check-sources`/`--check-pack-abc` 绿；`~/.dotnet`、`~/.dotnet.rc2-fix` 与四包一致；hosting DLL `4e86276b…` 同步 Ref/Runtime 8 路径；`verify-kit` EXPECT `534192,24324`、`selftest-verify-kit` **129/0**。

## 3) 门禁（合并树）

- 套件 `checks=731 total=734 floor=714 assert=True`（declared==printed、0 Unhandled、perf within）；pixel **PASS**；红控在案（M4 两轮真实红-绿 + M2/M3 5 组）。
- host：build-host 契约 **164/164**（DT_NEEDED/UND 过）；cross-check **164/164**；registry 84 / bridge 26 / a11y-table 47；preflight 全绿（repo gates + sh -n 51 + markdownlint 0 + 套件 + pixel）。

## 4) 真机轻量复核（HAD-W32 @ 127.0.0.1:35111；锁协议，已释放；引用 M4 40min 数据）

- JIT hap（abc 534,192 + host `ad7ab986`）冷启 pid=40303、主窗在；N=2 → WMS **2 子窗**、各自 eval `CHILD-WEB-1/2`（自点按 TAP 1/2，互不串）；定向关 → 留 1（保留自身文档）；重开 → 2 窗、eval `CHILD-WEB-2`；全程 pid 恒定、0 crash/fault。
- 不重跑 40min soak（引用 M4：RSS 284–363 MB 无单调增长、线程 70–71、0 crash）；证据 scratch `l3-consolidate/`（不落库）。

## 5) pin / CI / 状态

- 三 workflow pin `d1d485bb67 → 277967cc56`（注释：套件 731/734 floor 714、导出 164/164、abc 534,192）；ow `0685d7b`。
- CI 5/5 @ ow `0685d7b`：interaction `37625969429` / pixel `37625969211` / host-export `37625969178` / ridgraph `37625969029` / markdownlint `37625969127`。
- 推送：ow `a551013..0685d7b`、maui `d1d485bb67..277967cc56`；均普通推送、未强推。
- **L3（M1–M4）全部并入主线**；四包一致；**#52 待切**（切包重建并按 `verify-kit` 锚定）；#49–#51 资产未动。
