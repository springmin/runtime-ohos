# PACK-FULL-SYNC：Ref/Runtime/BCL 全量对齐 + P0 扩展 + P1 hosts 物化（2026-10-12）

> 目标：收尾 KIT54 留档两坑——rev2 只同步 SDK pack（Ref/Runtime/BCL 仍 #51 代）、NOTES finding 3 的 fresh-worktree 缺 git-ignored `hosts/*.so`。零构建、#49–#54 资产未动、不处理上游 PR；载体 ow `tooling/pack-full-sync`（`fb06c81`）→ merge **`6addaba`**（pin 不变、maui 零改动）。

## ① Ref/Runtime/BCL 全量对齐（两安装）

- 源 = repo/pin 件（`packs/`；锚 = WorkloadManifest preview.28 + BCL rc.2/rc.1）；把 6 个关键 DLL 同步进 `~/.dotnet` 与 `~/.dotnet.rc2-fix`：Ref.20/26 + Runtime.20/26 的 `Microsoft.OpenHarmony.dll` `0d80bdcb→04e73c31`、`Maui.Graphics.dll` `1fd0f53c→2786f691`；Hosting `7ff748da`、BCL `System.Private.CoreLib` `c1727b53`、FrameworkList/RuntimeList 与两安装本已同。
- 前后全量指纹（545 件/安装 + 关键 dll/manifest 28 件）：payload diffs **6→0**；余 18 条已知元数据（`*.nupkg`、生成 nuspec、容器件 `[Content_Types]`/`_rels`/`psmdcp`）；两安装互差仅 4 个 nupkg。SDK pack 回归 28/28 逐字节同（abc 623,784/`58c5829b`、host 367,520/`ad7ab986`）。

## ② P0 门禁扩展（Ref/Runtime/BCL 关键件，fail-closed）

- cut-kit P0 install-pack 增 6 family × 20 关键件（Ref 2 dll+FrameworkList；Runtime 3 dll+RuntimeList；BCL CoreLib+versions+RuntimeList；Asp.NET Components.Web+versions+RuntimeList），版本从 `WorkloadManifest.json` 锚解析；逐文件 repo/install 缺失或 repo≠install 即 FAIL。
- selftest：fixture 加 workload manifest + 六 family 镜像；T1d 漂移（Ref dll）/ T1e install 缺失（BCL CoreLib）/ T1f repo 缺失（Maui.Graphics）。

## ③ P1 hosts payload（fresh worktree 自动物化）

- `p1_prep` 物化 git-ignored `packs/Microsoft.OpenHarmony.Sdk/<ver>/hosts/arm64-v8a/libopenharmonyhost.so`：主 checkout → 构建用安装（pin 件）→ 均缺显式报错（fail-closed）；P3 打同一 worktree，Sdk nupkg 不再丢原生宿主。
- selftest T9a–d：dry plan / 主 checkout 拷贝 / 安装回退 / 缺失拒绝（不触发构建）。

## 验证 / 合并 / CI

- selftest-cut-kit 全绿 **208**（was 185；零构建）；证据 `/data/storage/el2/base/tmp/opencode/pack-full-sync/`（fp/key/sync/cmp/sdk-regression/selftest-run2.log）。
- ow `fb06c81`（tooling/pack-full-sync）→ merge **`6addaba`** 推 master（HTTP/1.1 直推；仅两脚本，pin 不变、maui 零改动）。
- CI 6/6 @`6addaba`：interaction `38222829449`（`checks=801 total=804 floor=784 assert=True`、coldstart wait=True）· pixel `38222829444` · host-export `38222829480` · ridgraph `38222829431` · markdownlint `38222829446` · harmony 手动 dispatch `38222892341`。

## 不确定项

- 安装位 4 个旧 nupkg（元数据）与 repo/彼此不一致属已知边界；workload 安装不回读它们，如需完全一致随下轮 bundle 重建（非 kit 阻断）。
- `materialize_sdk_hosts` 仅 P1 执行（worktree 归属 phase）；P3 对主 checkout 独跑时宿主本就在，无动作。
