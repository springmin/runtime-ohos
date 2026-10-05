# OpenHarmony 分支卫生（2026-10-05）

清理原则：本地=已合并主线或与 origin 同 SHA；远端=仅删已并入主线者（未合并一律保留）。
保护：main/master/feature/*/release/*、worktree 占用、近两日分支。

## 结果

- 本地删除：**74**（已合并 42 + 远程有副本 32）
- 远端删除：**4**（含补删 `fix/rc2-aotpack-openssl-shim`；`feature/ohos-cross-sdk` 远端已先不存在）
- 保留未合并本地：**30**（backup/rehearse/wIP/开 PR 分支语义）
- 实体 worktree 保留：`fix/ohos-rc2`（runtime-ohos-rc2）、`fix/rc2-aotpack-openssl-shim`（sdk-ohos-rc2fix）
- 分支复核：runtime 49→22 · ow 18→5 · maui 23→8 · sdk 21→4 · aspnet 5→3（local）

## 删除清单（本地，按类）

```
a11y-tab a11y-tab-suite ci-sdk/arch-guard-fix consol-pins consol-t3 docs/blazor-rc2-notes docs/blazor-webview-demo docs/msbuild-pipe-rootcause docs/ohos-static-device-verified feature/ohos-cross-compile feature/ohos-cross-runtime feature/ohos-cross-sdk fix-dev1-optional-dlsym fix-tab-suite fix/aotpack-structural fix/ohos-maui-rc2 fix/ohos-msbuild-pipe-patch fix/rc2-pins interp-fix-host interp-fix-pack kit32-anchor kit36-anchor kit37-anchor kit38-anchor kit39-anchor lo-b/aot-asset-pointer lo-d/aot-doc-rc2 m-web-mirror merge/ohos-rc2-master p1b-list p2c-deeplink t3-graphics w2b-t5 w4b-t6 w5b-suite w5b-t21 w6b-suite w6b-t12 w9c-t8
---
archive/ohos-sandbox-fixes-2511c989 fix/aotpack-structural fix/host-pack-pins fix/ohos-rc2 pr/ohos-aot-singleentry pr/ohos-aot-unix pr/ohos-apphost pr/ohos-aspnet-rids pr/ohos-clrfeatures pr/ohos-console pr/ohos-crossgen-corelib pr/ohos-ifaddrs pr/ohos-illink-ntlm pr/ohos-infra pr/ohos-libs-native pr/ohos-libs-tfm pr/ohos-packs pr/ohos-pal pr/ohos-pal-process pr/ohos-sandbox-fixes pr/ohos-sdk-rids pr/ohos-sdk-sandbox pr/ohos-shims-tfm-cleanup pr/ohos-tls-flag-cleanup pr/ohos-tryrun pr/ohos-wx-default pr/ohos-zstd w9a-b2 w9b-t14-t21 w9d-t20 w9d-test
```

## 删除清单（远端 origin）

```
feature/ohos-cross-compile
fix/ohos-rc2
fix/rc2-aotpack-openssl-shim
m-web-mirror

> `feature/ohos-cross-sdk`：远端已先不存在（仅删本地副本）。
```

## 保留的未合并本地分支

```
backup/r1-kit-ext2-tip
backup/r1-preclean-45b44cd4
backup/r1-preclean-45c1fb0
backup/r1-preclean-8f3ae54
feat/payload-zip-optin
feature/openharmony
rehearse/aot-singleentry
rehearse/aot-unix
rehearse/apphost
rehearse/clrfeatures
rehearse/console
rehearse/crossgen-corelib
rehearse/ifaddrs
rehearse/illink-ntlm
rehearse/infra
rehearse/libs-native
rehearse/libs-tfm
rehearse/packs
rehearse/pal
rehearse/pal-process
rehearse/shims-tfm-cleanup
rehearse/tls-flag-cleanup
rehearse/tryrun
rehearse/wx-default
rehearse/zstd
t10-integration
w2b-int
w2b-t3t5
w9-merge-ebffdd

```

> 注：原日志 `/data/storage/el2/base/tmp/opencode/hygiene-1005.log`（scratch，随清理淘汰）。
