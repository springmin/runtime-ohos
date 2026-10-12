# CUT-KIT-HARDEN-R2：cut-kit 工具坑修复（KIT54 findings）（2026-10-12）

> 目标：让 kit #55 全链无手工绕行；本 session 零构建、#49–#54 资产未动、不处理上游 PR。
> 载体：ow `tooling/cut-kit-harden`（`449aa5c` cut-kit + `2f6633b` kits）→ merge `34f87cb`（pin 不变、maui 零改动，origin/master 已推）。

## ① P3 锚 regex：`=` / `:=` / JSON（finding 1）

- 读取与替换共用一条锚 regex：`WORKLOAD_BUNDLE_SHA256=<hex>`、`: "${WORKLOAD_BUNDLE_SHA256:=<hex>}"`（真实 versions.env 形态，旧 grep "found 0"）、JSON `"WORKLOAD_BUNDLE_SHA256": "<hex>"`；恰好 1 处才动，替换只改 hex 值。
- 对 sdk-ohos `origin/feature/openharmony` versions.env 复核：解析 1 处 + 单行 diff；锚已等于新 sha 时 resume no-op（重复 commit/push 免除）。

## ② P3 累计 seed 自动解析（finding 3）

- 无 `--seed-bundle` 时：读 sdk `versions.env` 锚（sha+版本）→ 本地候选按 sha 精确匹配（`CUT_KIT_SEED_DIR`、sdk/ow `dist`、`<scratch>/seed`）→ 未中则下载 sdk-ohos release（`workload-<ver>`/`workload-latest`，HTTP/1.1 + pin IP + gh-proxy 旁路，sha 校验后缓存）；`CUT_KIT_SEED_OFFLINE=1` 纯离线。
- 缺失/不符 → P3 rc=4 fail-closed（不再退化成 7 成员 feed）；显式 `--seed-bundle` 与锚不符仅 WARN；state 记 `seed_path/seed_sha256/seed_source`。

## ③ P4–P6 dry 预演 + hook 解析自检（finding 4）

- `--phase P4,P5,P6 --dry-run`：P4 打印 clobber 上传清单 + Integrity notes 模板 + 上传 hook 解析；P5 打印 RELEASE-VALUES 全量块 + presign/manifest hook 解析；P6 打印 CI 查询计划；零写、零 API、零 hook 执行。
- hook 缺失/语法错 → 立即 fail-closed（execute 也在动作前解析）。

## ④ AOT InvariantGlobalization（finding 2）

- `make-mode-kit --mode aot` 默认注入 `-p:InvariantGlobalization=true`（`--property` 可覆盖，同 OpenHarmonyUIPage 的 props_has 模式）；`make-device-test-kit` 保持注入并加 `DEVICE_TEST_KIT_INVARIANT_GLOBALIZATION=0/false/no/off` 显式退出。

## 验证 / 合并 / CI

- selftest 全绿（零构建）：cut-kit **185**（was 109；T7 锚三形态 + seed 自动/显式/缺失 + resume；T8 P4–P6 dry 零写）、make-mode-kit 89（顺修一条被换行吞掉的 SHA256SUMS 断言）、make-device-test-kit 52。
- ow merge `34f87cb` 推 origin/master（直连 SSL EOF → pin IP 140.82.112.3 成功）；CI @34f87cb：ridgraph/markdownlint/host-export/pixel success，interaction run `38215361043` **failure 属既有**（`mediaresiduals coldstart wait=False` → "MEDIA-RESIDUALS cold-start page-ready wait drifted"；与 34bcaa4 的 `38204552669` 同签名——suite 源扫撞 stale maui pin `36da77cba4`，maui 侧修复 `44dcef8d15` 未在 pin 内；非本轮 scripts/docs 改动）。
- 不确定项：seed 下载依赖 github.com/gh-proxy（本机抖动时靠 pin IP）；NOTES finding 3（fresh worktree hosts payload）不在本次范围；#55 是 P4–P6 首次实跑。
