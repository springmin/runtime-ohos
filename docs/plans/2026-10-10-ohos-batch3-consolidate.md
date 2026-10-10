# MERGE-BATCH-3：N-SUBWINDOW M2 · L8-REMAINDER 批合并收口（2026-10-10）

> 口径：ow `master` ← L7-M2（`feat/n-subwindow-m2` @ `ee95143`）→ L8 余项（`fix/l8-remainder` @ `373bee0`），逐支 `--no-ff`；maui `feature/openharmony` ← L8 余项（`fix/l8-remainder` @ `31ed839fd6`），`--no-ff`；普通推送、未强推；不切 kit（#54 待 rc.2）；#49–#53 资产不动。

## 1) 合并 SHA

- ow：L7-M2 merge `a2b3567`；L8 merge `db565fe`；pin `8e871f4`（`8e871f456a91`）。
- maui：`14cc245902` → merge **`625177750f`**（`625177750fb15bf4739ca3453614592bfe22476b`）。

## 2) 冲突与解法

- 唯一文本冲突 = `test/maui-platform-verify/Program.cs` 计数行（L7-M2 `769` vs L8 `768`）→ 终值 **771**（注释并集：`+3 L7-M2` 前插、`+1 MODAL-DEEPLINK`/`+1 L8-REMAINDER` 尾接）；`App.cs` 自动合并；maui 零冲突。
- 合并树 vs L7-M2 = 仅 L8 两文件（`App.cs`/`Program.cs`）；四包 `Index.ets`/abc/provenance 同哈希（壳 L8 零改动）。

## 3) abc / packs（唯一一次重编）

- 重编一次（ui+headless，标准脚本）：ui **576,664/`e69563c3…`**、headless **24,324/`798b2477…`**，与合并树所装四包逐字节一致（**零漂移 → EXPECT 未重锚**，仍 `576664,24324`）。
- `--install-packs`（.22/.23/.24）0 变更；.28 与 .22/.23/.24 四包同源；`selftest-build-arkts-shell` **207/0**、`selftest-verify-kit` **129/0**。

## 4) 门禁（合并树）

- 套件 **768/771 floor 751**（`[suite] checks=768 total=771 floor=751 assert=True`、declared==printed、0 Unhandled、frame+a11y perf within）；红控在案：L7-M2 defer/replay pins=False rc=134、L8 stash 红控 False/False rc=134。
- pixel `PIXEL ASSERTIONS PASSED`（宿主 fallback）；导出 **164/164**；preflight **OK 5/5**（repo gates ridgraph 20 / packs 25 / hap-targets 85 / tasks 9 / hygiene 25 / host 84+26+47 / cut-kit 52；sh -n 54/54；lint 0；interaction+pixel）。

## 5) pin / CI / 状态

- 三 workflow `MAUI_OHOS_REF`（默认+env）→ `625177750fb15bf4739ca3453614592bfe22476b`；pin 提交 `8e871f4`。
- CI 6/6：interaction `38029614967` · pixel `38029614934` · host-export `38029614918` · ridgraph `38029614908` · markdownlint `38029614915` · harmony `38029614926`（全 success）。
- **#54 待 rc.2**（不变）；#49–#53 资产零改动；L7-M2 / L8-REMAINDER 分支文档置「已并入」。
- 不确定项：pixel 首轮 preflight 触发宿主 csc 活锁（IO 冻结 + 单核空转 ~19 min，rc.2-era 已知坑）→ kill 后 `DOTNET_PROCESSOR_COUNT=1` 重跑全绿（CI Linux 无此现象）；L7-M2 deferred 真机未复现 / Back/IME 未捕获（分支文档边界，非本轮门禁）。
