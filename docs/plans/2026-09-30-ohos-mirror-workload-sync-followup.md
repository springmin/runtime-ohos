# `-openharmony` 镜像 workload 同步修复与工作流跟进（MIRROR-FIX，2026-09-30）

> 背景：kit #34 独立复核（见 [`2026-09-28-rc2-conflict-sharding-plan.md`](2026-09-28-rc2-conflict-sharding-plan.md) 的「kit #34 独立复核」段）发现 `-openharmony` 镜像线的 workload bundle/`SHA256SUMS` 仍为 pre-#34 的 `155960f4…`/`a5394037…`，测试者从镜像取件会拿到 pre-#34 包（A/B 与 W7/W8 判定受影响）。本页记录镜像资产的修复（delete-then-upload，release 资产显式 clobber）与镜像工作流扩展跟进项。
> 范围：镜像 release 资产 + 文档；**主发布零改动**。scratch：`/data/storage/el2/base/tmp/opencode/mirror-fix/`（before/after JSON、正确件、上传脚本、回读件）。

## 1. 镜像定位

- 镜像 release = `springmin/sdk-ohos` **`v11.0.100-rc.2.26451.112-openharmony`**（release id **398828457**，"post-rename distribution line"，由 `ohos-release-mirror.yml` 从 `v…-ohos` 冻结线镜像）。
- 同波资产应在三处同字节：`sdk-ohos/workload-1.0.0-preview.28`（release 398936638，asset 599847864）、`sdk-ohos/v11.0.100-rc.2.26451.112-ohos`（release 398739326，asset 599851185）、`sdk-ohos/workload-latest`（release 392077166，asset 599849143）；**镜像件是唯一陈旧处**（本波修复对象）。

## 2. Before/After（release API by-id；其余 15 项零改动）

| 资产 | before id / size / sha256 | after id / size / sha256 |
|---|---|---|
| `openharmony-workload-1.0.0-preview.28.tar.gz` | 598114449 / 77,689,347 / `155960f4…` ✗（陈旧） | **600162995 / 77,668,683 / `338541db…`** ✓ |
| `SHA256SUMS`（merged，1,960 B） | 598114916 / 1,960 / `a5394037…` ✗（陈旧） | **600160522 / 1,960 / `f1c70f44…`** ✓ |

- 正确件来源：`v…-ohos` release 398739326（bundle asset 599851185、merged sums asset 599853204 `f1c70f44…`）；bundle 与 `workload-1.0.0-preview.28` 599847864、`workload-latest` 599849143 逐字节同值；本地构建产物 `ohos-workload/dist/openharmony-workload-1.0.0-preview.28.tar.gz` 同 sha（`338541db…`）。
- 修复方式：**delete-then-upload（显式 clobber）**——API DELETE 旧 asset → POST `uploads.github.com`（HTTP/1.1，pinned IP 20.205.243.161）→ API by-id digest-gated 复核 size+sha256 后才记 OK（`mirror-upload.sh`，重试 12 轮）。
- 回读复核：`SHA256SUMS` 从镜像下载后 `cmp` 逐字节一致 ✓；bundle 以 16 路 ranged GET 重下后 `cmp` 与参考件逐字节一致 ✓（sha256 `338541db…`/77,668,683）。
- 一致性影响：merged `SHA256SUMS` 仅两行变化（`…preview.28` 与 `…latest` 指向新 bundle `338541db…`）；镜像 release 17 项资产中其余 15 项 size/digest 零变化（before/after 全量快照 diff）。

## 3. 跟进项：镜像工作流扩展至 `workload-*` releases

现状（`sdk-ohos/.github/workflows/ohos-release-mirror.yml`；最近全量绿跑 = run 36565484313）：

- 仅 `workflow_dispatch`（手动触发）；源 = `v$RT_VERSION-ohos` / `v$SDK_VERSION-ohos`（版本 pin 来自 `eng/ohos-install/versions.env`）；目标 = `v…-openharmony`；`asset_prefix` 按 `updated_at` 过滤；逐件 size+sha256 校验 + `--clobber`。
- `workload-*` releases（`workload-1.0.0-preview.N` / `workload-latest`）不在源里 → **只重打 workload（未同步刷新 `-ohos` tag）时镜像永不更新**；且无自动触发。本轮属"`-ohos` 也刷新了但工作流没重跑"，手动重跑即可覆盖 ✗ 不自愈；下一类"仅 workload release 更新"场景则永远不会进镜像。

最小改动点：

1. **源扩展**（同文件，sdk band 步骤扩展）：解析最新 workload release（`WL_VERSION` 加入 `versions.env`，或 `gh release list --json tagName,createdAt` 取 `workload-1.0.0-preview.*` 最新），把其 `openharmony-workload-$WL_VERSION.tar.gz` 镜像到同一 `DST`（`--clobber` + size/sha256 校验）。
2. **sums 处理**：workload release 自带 sums 为 preview-only（212 B）；镜像用的 merged 1,960 B sums 在 `-ohos` release。最小实现 = 继续镜像 `-ohos` 的 merged sums，并在上传前把其中 `…preview.N.tar.gz` / `…latest.tar.gz` 两行 digest 重写为新 bundle sha（或按 `DST` 现有资产集重算 merged sums）。
3. **自动触发**：`on:` 增加 `release: types: [published, edited]`（`if: startsWith(github.event.release.tag_name, 'workload-')`，sdk-ohos 本仓 release 事件）或 nightly `schedule:`；保留 `workflow_dispatch` 手动路径。
4. （可选）把 `WL_VERSION` 作为 pin 写入 `versions.env`，与 `RT_VERSION`/`SDK_VERSION` 同波审计（pin 语义统一后，四步可全自动）。

## 4. 证据

- scratch `mirror-fix/`：`before-mirror-sdk-assets.json` / `after-mirror-sdk-assets.json`（release API 全量）、`correct/`（从 `-ohos` 下载的正确件）、`sums-readback`、`bundle-readback.tar.gz`（回读件）、`mirror-upload.sh`（digest-gated delete-then-upload）、`chunk-dl.sh`（16 路并行回读）、`bundle-upload.log`（`upload OK: … sha256=338541db… size=77668683`）。
- 主发布零改动：`workload-1.0.0-preview.28` / `v…-ohos` / `workload-latest` 本波未动。
