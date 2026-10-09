# MERGE-BATCH-2：DEEPLINK-REGRESSION · HARMONY-FLAVOR · L8-POPUP 批合并收口（2026-10-09）

> 口径：ow `master` ← deeplink pin → harmony → L8（逐支 `--no-ff`：`4236f0b`→`91eb4fd`→`8ee536a`）＋唯一一次 abc 重编（`e9edcb1`）＋pin（`01b426e`）；maui `feature/openharmony` ← deeplink（合并 `14cc245902`）；普通推送、未强推；不切 kit（#54 待 rc.2）；#49–#53 资产不动。

## 1) 合并 SHA

- ow：deeplink `4d7a18a`→`4236f0b` · harmony `ee6e754`→`91eb4fd` · L8 `bce2bcb`→`8ee536a` · abc/EXPECT `e9edcb1` · pin `01b426e`。
- maui：deeplink `9f2b1b06df`→`14cc245902`（`14cc245902a9ce7260f49664ea80d020cbe2ad4a`）。

## 2) 冲突与解法

- 唯一文本冲突 = `test/maui-platform-verify/Program.cs` 计数行（deeplink 760 vs L8 765）→ 终值 **766**（两条注释并存，floor 自算 746）；套件超集 = 759+1+6。
- 四包 `Index.ets` 自动合并（`FreeWindowProbe` 与 `kind=popup`/弹窗路径同文件并存）；`SubWindow.ets` 仅 L8；四包逐字节一致。
- abc 二进制/provenance 随 L8 侧进入，后由本次重编统一覆盖；`verify-kit.sh`/`selftest-verify-kit.sh` EXPECT 重锚。

## 3) abc / packs（一次重编）

- 源码契约 `26ec8cfa…`；ui abc **574,336 B / `930c3efd…`**（L8 573,684 ＋ harmony probe），headless **24,324 / `798b2477…`**（不变）。
- `--install-packs`（.22/.23/.24）＋ .28 同步；`--check-sources` / `--check-pack-abc` 过、四包一致。
- hosting DLL 无源码改动：`7ff748da…`（.28 Ref/Runtime ＋ 本机 workload）核对一致、未动。

## 4) 门禁（合并树）

- 套件 **763/766 floor 746**（declared==printed、0 Unhandled、perf within；`deeplink push marksLayout=True`、`l8 popup …=True identical=True`）；pixel `PIXEL ASSERTIONS PASSED`；导出 **164/164**。
- preflight **OK 5/5**（repo gates：ridgraph 20 / packs 25 / hap-targets 85 / tasks 9 / hygiene 25 / host 84+26+47 / cut-kit 52；sh -n 54；lint 0；interaction+pixel）；`selftest-build-arkts-shell` **207/0**、`selftest-verify-kit` **129/0**。
- CI 6/6：interaction `37950000293` · pixel `37950000284` · host-export `37950000282` · ridgraph `37950000286` · markdownlint `37950000206` · harmony-flavor `37950086069`（全 success）。

## 5) pin / 状态

- 三 workflow `MAUI_OHOS_REF`（默认+env）→ `14cc245902a9ce7260f49664ea80d020cbe2ad4a`；pin 提交 `01b426e`。
- **#54 待切**（rc.2 后 `bump-tester-docs.sh --kit 54` → `cut-kit.sh --kit 54`）；#49–#53 资产零改动。
- 不确定项：像素/套件走宿主 csc（本轮一次「cryptographic operation」瞬态读取失败、重试即过；CI Linux 无此现象）；无真机轮（本轮不需要）。
