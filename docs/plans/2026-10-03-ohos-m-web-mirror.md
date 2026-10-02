# M-WEB-MIRROR：WebAuthenticator `skills[].uris` 声明机制 + 镜像 workload 源（2026-10-03）

> 范围：FINAL-AUDIT §2 **L3 本机部分**（`module.json` `skills[].uris` 生成/注入，真机 want 投递除外）+
> [`2026-09-30-ohos-mirror-workload-sync-followup.md`](2026-09-30-ohos-mirror-workload-sync-followup.md) §3
> 跟进项（`ohos-release-mirror.yml` 覆盖 `workload-*` releases）。各按其门禁，未改任何版本 pin。

## 1. WebAuthenticator/P2c：`skills[].uris` 打包期声明（ohos-workload）

- **实现**：`OpenHarmonyAppLinkHosts`（`;` 分隔 https host，原只写 app.json `linkHosts`）现在同时生成
  `module.json` `module.abilities[0].skills[].uris`：`OpenHarmonyGenerateModuleJson` 新增
  `AppLinkHosts`/`AppLinkDomainVerify` 两参，向首个 ability 的 skills 数组追加
  `{"entities":["entity.system.browsable"],"actions":["ohos.want.action.viewData"],
  "uris":[{"scheme":"https","host":"<host>"}...],"domainVerify":true}`（home skill 保留第一元素；
  host 去空白/去重，非法 host 直接 fail；`OpenHarmonyAppLinkDomainVerify` 默认 true，false 时省略该成员）。
  未设 hosts 时 module.json 字节不变。
- **打包接线**：`packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.{22..28}/targets/OpenHarmony.Hap.targets`
  七个 pack 字节一致（属性默认 + 传参 + 注释/消息），`tools/Microsoft.OpenHarmony.Tasks.dll` 同步重编
  字节一致（sha256 `b7313740…`）。
- **断言（本机可验声明产物）**：tasks 单测 138 项 0 失败（新增 14 项：注入结构/trim+去重/domainVerify 开关/
  非法 host/空 host 列表/缺 skills 锚 + 负例）；`scripts/selftest-hap-targets.sh` T1 接线断言 + T2 fixture
  实测真实 pack targets 生成 `out-link.json`（两 https uri + domainVerify + home 保留）+ T3 非法 host 拒绝；
  两者本机全绿（tasks 9/9、hap-targets 74 checks/0 failed/1 skip(T6 无设备)）。
- **文档**：`ohos-workload/docs/openharmony-hap-packaging.md`「module.json generation」+「Deep links / activation」
  （同源规则/JSON 形状/AGC 门/本机验证入口）。
- **提交**：ohos-workload `d6384ee`（`master`，18 文件；`commit-paths.sh`，未强推）。同 checkout 的并发
  SAMPLE-FIX 改动已隔离保留（本提交只含 app-link 变更；其未跟踪/未提交改动仍在工作区）。
- **外部剩余**：AGC App Linking 登记 + 登记证书签名包的真机 https 投递（`onCreate`/`onNewWant`）与设备
  `bm dump` 断言；自签包仍以显式 want（`aa start -U`）路由。不受本波影响。

## 2. 镜像工作流：`workload-*` 源 + merged sums 两行重写（sdk-ohos）

- **实现**（`.github/workflows/ohos-release-mirror.yml`）：
  1. sdk band 新增步骤：`gh release list` 解析最新 `workload-<x.y.z-preview.N>`；取
     `openharmony-workload-$WL_VERSION.tar.gz`，size+sha256（有 digest 时）+ 上传后 by-tag readback
     （12×5s，digest 未发布即失败）；`--clobber` 到同一 `DST`。
  2. merged `SHA256SUMS`：以 `-ohos` 那份为基线，重写 `…preview.N.tar.gz` 与 `…latest.tar.gz` 两行 digest
     （基线仍命名旧版本时插到最后一个 workload 行之后；空集时追加两行）。
  3. 触发：保留 `workflow_dispatch`，新增 `release: [published, edited]`（job 级 `if` 只放行
     `workload-*` tag，避免 `-openharmony` 自触发）+ nightly `schedule`；workflow 级 `concurrency`
     串行化全量与定时跑；SRC/DST 解析收敐为一步（来自 versions.env，**pin 未改**）。
- **本地校验**：Ruby YAML 解析通过；4 个 `run:` 块 `sh -n` 全过；用真实 release API 干跑抽取出的
  workload 步骤（上传以 stub 拦截）：解析 `.28`、size `73,040,293`、sha `c98375a5…` 全部命中；
  sums 重写结果 = `-ohos` 源 sums 逐字节一致、与镜像旧 sums 仅预期两行不同；另验「插入新版本 .29」
  与「空 sums」两分支。
- **dispatch 冒烟**：临时分支（API 内容提交 48a800d9c7，内容与本地提交一致；冒烟后已删除远端临时分支）
  → run **37074471413**，三个矩阵 job 全 success；asset_prefix 置不匹配值只跑新路径，日志：
  `WORKLOAD: uploaded … (c98375a5…)` / `readback OK` / `SHA256SUMS carries … + …latest -> c98375a5…`。
- **镜像终态**：`v11.0.100-rc.2.26451.112-openharmony` 的 `.28` = `73,040,293 / c98375a5…`（此前
  `77,668,683 / 338541db…` 陈旧），`SHA256SUMS` = 1,960 B / `4be65073…` 与 `-ohos` 源逐字节一致
  （其余 15 项零改动）；即本次冒烟同时自愈了镜像 workload 线。
- **提交**：sdk-ohos `d47f1fcb3b`（分支 `m-web-mirror`，基于 `origin/feature/openharmony`；本地提交，
  本机到 github.com 直连被拒，远端推送待可行通道；临时冒烟分支已删，避免与本地分支分叉）。

## 3. 不确定项

- `release`/`schedule` 触发只有在提交进入默认分支 `feature/openharmony` 后才生效；dispatch 已验证新代码路径。
- 镜像 `openharmony-workload-latest.tar.gz` 资产本身仍不在 `-openharmony` release（与改动前一致；本波按跟进
  文档只镜像版本化 bundle + 重写 sums 两行）；`latest` 下载走 `workload-latest` release。
- `Ohos App Linking` 真机投递与设备 `domainVerify` 断言仍需 AGC 登记证书 + HMS 设备（外部）。
