# OpenHarmony 分支卫生 phase-2 分析（2026-10-06）

> 仅分析：不删分支、不推分支、不改远端；命令草案只入本文。主线口径：runtime·maui=feature/openharmony，ow=master，sdk·aspnet=origin/feature/openharmony。方法：`merge-base --is-ancestor`、`git cherry`（patch-id）、`git diff --quiet`、`branch -r --contains`。`≡`=patch-id 等价；`已并线`=主线祖先。runtime 主线在分析窗口内 75161dc6→def08257fd2（并发 docs 提交，不影响结论）。
>
> `保留*`：worktree 占用或主线/基线，仅记录不议删。

## 本地结论表

| 分支 | tip | 与主线关系 | 结论 | 依据 |
|---|---|---|---|---|
| runtime rehearse/{aot-singleentry,aot-unix,apphost,clrfeatures,console,crossgen-corelib,ifaddrs,illink-ntlm,infra,libs-native,libs-tfm,pal,pal-process,shims-tfm-cleanup,tryrun,wx-default,zstd}（17 支） | singleentry=a74e15edffc unix=60649567b59 apphost=173ba858e14 clrfeatures=9914d5f7e12 console=8ebd6b41145 crossgen-corelib=2b6a627be0f ifaddrs=7f81abb794d illink-ntlm=8e43ca518d0 infra=84fc5f4e5b1 libs-native=3593cfe5a25 libs-tfm=0b03c70ee3d pal=b563ca36fe3 pal-process=29a59970d4c shims-tfm-cleanup=a5a8a8884ab tryrun=347ac3d8544 wx-default=0c363ccb35d zstd=9cc4bcdccb2 | 未合并 | 可删 | 每支 cherry origin/rehearse2/同名 全 `-`（1–17 笔 patch-id 等价）；同名 origin/pr/ohos-* 为 PR head 保留；shims/tryrun 另已落主线 |
| runtime rehearse/packs | 9cd9f008216 | 未合并 | 可删 | 15 个独有 commit ≡ origin/rehearse2/infra，tip ≡ origin/rehearse2/packs |
| runtime rehearse/tls-flag-cleanup | f9dffc0cd78 | 未合并 | 可删 | 无 rehearse2；本地=origin/pr/ohos-tls-flag-cleanup 且为其祖先 |
| runtime fix/ohos-rc2 | 417ab220532 | 已并线 | 保留* | worktree runtime-ohos-rc2 占用；origin 同名保留 |
| runtime main / feature/openharmony | 719009acffb / def08257fd2 | 上游 / 主线 | 保留 | 保护线；feature=origin/feature/openharmony |
| maui backup/r1-kit-ext2-tip、backup/r1-preclean-45b44cd4 | 45b44cd475（同 tip） | 未合并 | 可删 | 同 SHA=origin/archive/r1-managed-bridges-45b44cd4（树等） |
| maui l/m2-per-window-renderer、l/m3-per-window-content | 1a15f56b30 / f2fa86cec5 | 已并线 | 可删 | feature/openharmony 祖先 |
| maui l/m4-per-window-focus | 23d98a9615 | 已并线 | 保留* | worktree scan5c/maui 占用 |
| maui t10-integration | 23c498de4c | 内容已落主线 | 可删 | cherry feature/openharmony=`-`（patch-id 已含） |
| maui w2b-int / w2b-t3t5 | f333e24da9 / 48c01d69f1 | 未合并 | 保留（未落内容） | T5 布局语义不在主线、不在任何 origin ref；T3 两笔已并线；w2b-int=T3+T5 集成 |
| maui w9-merge-ebffdd | 27c8ef6540 | 部分已落主线 | 可删 | 6 笔中 4 笔 patch-id 已含主线；T14≡origin/w9b-t14-t21(5d300d96b0)、T8≡origin/w9d-test(7a31fd6dfc) |
| maui main / feature/openharmony | 7de682ea17 / 74e0bde5b9 | 基线 / 主线 | 保留 | main=origin/main(0/0) 且 origin HEAD；feature 为工作线 |
| ow backup/r1-kit-ext2-tip、backup/r1-preclean-8f3ae54 | 8f3ae54（同 tip） | 未合并 | 可删 | 均为 origin/archive/r1-recovery-45c1fb0(45c1fb0) 祖先 |
| ow backup/r1-preclean-45c1fb0 | 45c1fb0 | 未合并 | 可删 | =origin/archive/r1-recovery-45c1fb0 |
| ow feat/payload-zip-optin | 3bfdf97 | 未合并 | 可删 | =origin/archive/payload-zip-optin |
| ow l/m1…l/m3、next-kit/polish-49 | df2a246 / 896f4e3 / fb493e1 / b5928d1 | 已并线 | 可删 | master 祖先 且 =origin 同名 |
| ow l/m4-focus-ime | a1ebde2 | 已并线 | 保留* | worktree scan5c/ow 占用 |
| ow master | afa6d7a | 主线 | 保留 | =origin/master |
| sdk feat/aotpack-rebuild | 18f86ce80f | 已并线（远端主线） | 可删 | =origin/feat/aotpack-rebuild；主工作区当前分支（先切走） |
| sdk fix/rc2-aotpack-openssl-shim | 48c8b210dc | 已并线 | 保留* | worktree sdk-ohos-rc2fix 占用 |
| sdk main / feature/openharmony | 530aaa51fa / caf4a0236e | 上游 / 主线镜像 | 保留 | feature 为 origin/feature/openharmony(a3417a5489) 祖先（behind 14，可 ff） |
| aspnet fix/ohos-rc2 | e10d030184 | =主线 tip | 保留* | worktree aspnetcore-ohos-rc2 占用；origin/fix/ohos-rc2 已不存在 |
| aspnet main / feature/openharmony | afc567f2a0 / e10d030184 | 上游 / 主线 | 保留 | feature=origin/feature/openharmony |

未再实测到本地 ref：w9a-b2、w9b-t14-t21、w9c-t8、w9d-t20、w9d-test（phase-1 已删；maui/ow origin 副本保留，不议删）。

## 远端 runtime origin 45（不含 HEAD）：全部不议删

- `pr/ohos-*` ×21：开 PR head 语义。
- `rehearse2/*` ×18：rehearse 远端副本（与本地 rehearse 等价；待 PR/落线后另议）。
- 其余 6：feature/openharmony（工作主线）、main（上游镜像）、feature/ohos-cross-runtime（origin/HEAD 默认）、fix/ohos-rc2（worktree 跟踪）、fix/aotpack-structural（已并线，远端可删候选）、archive/ohos-sandbox-fixes-2511c989（archive）。

## 汇总

- 实测本地 50 支（runtime 22 / maui 11 / ow 10 / sdk 4 / aspnet 3）：可删 **34** / 保留 **16**。
- 保留 16 = 主线·基线 9（各仓 main/master/feature）+ worktree 占用 5（上表 `保留*`）+ 未落内容 2（maui w2b-int、w2b-t3t5）。

## phase-2 命令草案（仅文档，本轮不执行）

```sh
# 本地删除 34 支（tip 复核后再跑）；远端 45 支一律不动
git -C runtime-ohos branch -D rehearse/{aot-singleentry,aot-unix,apphost,clrfeatures,console,crossgen-corelib,ifaddrs,illink-ntlm,infra,libs-native,libs-tfm,packs,pal,pal-process,shims-tfm-cleanup,tls-flag-cleanup,tryrun,wx-default,zstd}
git -C maui-ohos branch -D backup/r1-kit-ext2-tip backup/r1-preclean-45b44cd4 l/m2-per-window-renderer l/m3-per-window-content t10-integration w9-merge-ebffdd
git -C ohos-workload branch -D backup/r1-kit-ext2-tip backup/r1-preclean-8f3ae54 backup/r1-preclean-45c1fb0 feat/payload-zip-optin l/m1-window-registry l/m2-exit l/m3-shell-xcomponent next-kit/polish-49
git -C sdk-ohos switch feature/openharmony && git -C sdk-ohos branch -D feat/aotpack-rebuild
# 不删：worktree 5 支（runtime fix/ohos-rc2、maui l/m4、ow l/m4、sdk fix/rc2、aspnet fix/ohos-rc2）+ 未落 2 支（w2b-int、w2b-t3t5）+ 主线基线 9 支
# 远端：禁止 push --delete；pr/ohos-*、rehearse2/* 语义保留
```

## 执行记录（2026-10-07，经用户批准）

- 范围：仅 **maui-ohos / ohos-workload** 本地可删分支；**runtime / sdk / aspnetcore 全部分支保留**；**远端一律未动**（禁 push --delete）。
- 已删（本地 **14**）：maui 6 = backup/r1-kit-ext2-tip · backup/r1-preclean-45b44cd4 · l/m2-per-window-renderer · l/m3-per-window-content · t10-integration · w9-merge-ebffdd（独有 2 提交经 patch-id 复核由 origin/w9b-t14-t21 + origin/w9d-test 覆盖）；ow 8 = backup/r1-kit-ext2-tip · backup/r1-preclean-8f3ae54 · backup/r1-preclean-45c1fb0 · feat/payload-zip-optin · l/m1-window-registry · l/m2-exit · l/m3-shell-xcomponent · next-kit/polish-49。
- 删前复核：每支按分析稿方法（祖先/patch-id/SHA 等价）二次核验；maui `w9-merge` 额外用远端两分支 patch-id 复核后删除。
- 保留（maui）：w2b-int · w2b-t3t5（未落内容）· l/m4-per-window-focus（worktree）· main/feature/openharmony（主线基线）· l2 工作分支与 worktree。
- 保留（ow）：master · l/m4-focus-ime（worktree）· l2/a11y-provider / l2/arkweb-subwindow（及 worktree）。
- 未动仓分支计数：runtime 23 local / 45 remote · sdk 4 / 9 · aspnetcore 3 / 3。
