# Wave 9 四线并入主线（W9-CONSOLIDATE 执行记录，2026-09-30）

> 把 W9A（B2 WebView/Blazor WASM）、W9B（T14 flyout 收尾 + T21 字体缩放）、W9C（T8 不等高
> TableView）、W9D（T20 媒体桥 + T19 深链判定）四线并入主线；线性优先、禁强推。执行 scratch
> `/data/storage/el2/base/tmp/opencode/w9-consol/`（maui worktree、壳/重建/门禁日志）。

## 1. 合并表

| 仓 / 线 | 源提交 → 主线提交 | 方式 | 合并前 → 合并后 tip | 冲突 |
|---|---|---|---|---|
| maui W9C | `640de39638`（保留原提交） | 已在远端主线 | `ebffdd787c` → `640de39638` | 0 |
| maui W9B | `5d300d96b0`/`5b51e1d448` → `01b2e9718e`/`ae03a1af45` | cherry-pick（onto W9C） | | 1：slice notes 两段并存 |
| maui W9D | `3fda5bdbe6`（集成态；`64e2dc4d92` 保留） → `6d6fd92b4b` | cherry-pick | | 0 |
| maui W9A | `8993aa5c10`/`139f745d45` → `0dcd972617`/`eec30c01cd` | cherry-pick | → `eec30c01cd` | 0（PublicAPI/Host 自动合净） |
| ow W9B/C/D | `90ae690`/`02609a4`/`7c74458`/`6fc22e4`/`66d1c40`/`aaf0ec2` | 已在本地 master（W9C 段已在远端） | `6fc22e4` → | 0 |
| ow W9A | `44996d3`…`26486a9`（6 提交）→ `3df1ccf`…`c7e2c5d` | cherry-pick | | 2 类：Program.cs 计数；Index.ets+abc+provenance |
| ow 壳/包 | 合并壳重建一次 + 22/23/24/28 同步 + provenance | `--install-packs`，28 手动同字节 | → `6dfcbfa`（含 pin） | 语义解（重建） |
| runtime | W9A `a76aa6abd0f` / W9D `1fc41807f40` 文档 | 已在 `feature/openharmony` | — | 0 |

## 2. 对账（合并树 `eec30c01cd` 实测）

- 交互套件 **538/518**：`[suite] checks=538 total=538 floor=518 assert=True`，538 条 `[verify]`
  （declared==printed；513 +5 W9C +13 W9B +3 W9A +4 W9D），两条 perf `within=True`。
- 像素 **PASS**（`PIXEL ASSERTIONS PASSED`；host-quirk 回退 `--no-restore -m:1` + dll）。
- 导出 **149/149**（`check-host-exports.py --cross-check`）；切片 **0 error / 0 IL**（`-warnaserror:IL2026,IL3050`）。
- 壳/abc：ui **336148 B**/`aec84a8f`、headless **22900 B**/`19e1ba97`、sources `388db42b`；
  `--check-sources` + `--check-pack-abc` 绿，四包 `preview.22/23/24/28` 字节一致 + provenance。
- 其他：selftest-verify-kit 108/0、hap-targets 50/0（1 skip）、ridgraph 20/0、packs 25/0、tasks 9/0、
  repo-hygiene 25/0、`sh -n` 全过；CI **5/5**（markdownlint `36705917654`、ridgraph `36705917454`、
  host-export `36705917585`、pixel `36705917527`、interaction `36705917433`）。

## 3. 提交保留（禁强推；全部 FF 推送）

- maui：`w9a-b2`（origin `139f745d45`）、`w9c-t8`（`640de39638`）、`w9d-t20`（`64e2dc4d92`）、
  `w9d-test`（`3fda5bdbe6`）、`w9b-t14-t21`（`5b51e1d448`）、首轮合并 ref `w9-merge-ebffdd`。
- ow：`w9a-b2`（origin `26486a9`）；`master` 保留 W9B/W9C/W9D 原提交。pin：三 workflow →
  `eec30c01cd`（注释同步 538/518、149/149）；`docs/rc2-line-notes.md` 加 W9 行。

## 4. 未决（随设备/后续波）

- **B2 托管入口缺口**：本机 AOT hap 可装可起，但 `Program.Run` 不可达、`dotnet-status.txt` 无托管行
  （宿主 AOT 分支 stderr→hilog 或最小 AOT `.so` 对比；附 `findLibsPayloadDir` 不识别 AOT `lib<stem>.so`）。
- **T19 `delivered=0`**：want 冷/热投递到 ability 成立，host 未见托管激活监听器（AOT 启动时序；
  `139f745d45` 疑已修，待在 tester JIT 机复核）。
- **媒体镜像限制**：本机镜像 `canIUse` 真但 `@kit.MediaKit` 无 media 命名空间 → 不可播放；sink 按 -1
  降级（`IsSupported=false`）；真机播放需 Kit 完整镜像/HMS 设备。
