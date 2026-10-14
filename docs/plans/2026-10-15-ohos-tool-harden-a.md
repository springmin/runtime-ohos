# TOOL-HARDEN-A：`.105` NativeAOT/Crossgen2 镜像补齐 + P3 fresh-worktree 载荷物化（2026-10-15）

> 两个工具面硬化：① sdk-ohos 新增 `.105` AOT/ILC + Crossgen2 镜像 release，解析改为按线自动选线（kit #57 P1 首跑 NU1100 根因）；② cut-kit P3 在 fresh worktree 物化已知载荷（AspNet 桩件 14,862 B → 完整 4,772,511 B；含 P3-only 的 SDK 原生宿主），三源全缺 fail-closed。本 session 不处理上游 PR；#49–#57 资产只读。

## ① `.105` 镜像 + 解析（sdk-ohos `feat/aotpacks-105` → `feature/openharmony` `96380943`）

- 新 release `aot-packs-11.0.0-rc.2.26504.105`（id **412971339**）：`Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.2.26504.105.nupkg` **28,269,716 B / `cfd2eab6…`**（asset 641045827）、`runtime.openharmony-arm64.Microsoft.DotNet.ILCompiler.11.0.0-rc.2.26504.105.nupkg` **43,828,764 B / `04c239af…`**（asset 641045833）、`SHA256SUMS` 300 B / `57338d3e…`。
- 新 release `crossgen2-packs-11.0.0-rc.2.26504.105`（id **412972544**）：`Microsoft.NETCore.App.Crossgen2.openharmony-arm64.11.0.0-rc.2.26504.105.nupkg` **43,792,502 B / `11f87f0c…`**（asset 641048707）+ `SHA256SUMS` 144 B / `c91a6c85…`。三件与 runtime-ohos `v11.0.0-rc.2.26504.105-openharmony` 同名资产字节一致（api digest 已复核）。
- 解析：`versions.env` 增 `AOT_PACKS_VERSION`（默认 `RT_VERSION`）+ `aot_packs_tag/_tag_version/_assets` + `.105` 钉；`crossgen2_packs_tag`/`crossgen2_pack_sha256`；`fetch-nativeaot-packs.sh` 按线解析（`AOT_PACKS_TAG` 覆盖且已知 tag 反选线），未映射线 fail-closed 并列出已知线，`--crossgen2` 取同线 Crossgen2。
- 测试：新 `test-fetch-aot-packs-resolution.sh`（17 检查，离线）+ workflow 步骤；5 套 install-tests 本地全绿（43/10/5/21/17）；`.112`/rc.1 既有 release 不动（增量：新 release/新资产）。

## ② P3 载荷物化（ow `e364570` → master）

- `p3_bundle` 在 prepare-packs 前：`materialize_sdk_hosts`（SDK 原生宿主；P3-only 不再丢）+ `materialize_known_payloads`（AspNet pack：主 checkout → 构建用安装 pack → release 镜像（钉 tag/sha256）；`CUT_KIT_PAYLOAD_PINS/_RELEASE_BASE` 供测试/自定义镜像）；全缺 **rc=4** 且不跑任何 pack 步。
- 自测：selftest-cut-kit **T11a–e**（dry/主 checkout/安装包/全缺/release 经 file:// 镜像）**238 全绿**（was 217）；selftest-packs **T9**（镜像表 ⊇ manifest 钉 + 未钉负例）**30 全绿**。
- 真实验证（一次 P3 本地模式、fresh worktree @6b62a49、不发布）：宿主 + AspNet 132 文件物化；重建 `.29` bundle **46,365,067 B / `d262bf4d…`** vs 已发布 46,365,380 B / `21e2d128…`；feed 对比 **AspNet 140 件 / BCL 385 件内容逐字节一致**，SDK 宿主 + Ref/Runtime 托管 DLL 因源 pin 比发布切点新而异（可解释）；字节差 = tar/zip 元数据。

## 不确定项

- 本沙箱直连 release-assets CDN 仍被阻断（302 后超时）；镜像下载经 gh API 路径实测（字节/sha 已核），`fetch` 脚本的 curl 直连在受限网络按文档走 gh-proxy/`--local`。
- P3 的 AspNet release 源只钉 `.105`/`.112`；新线随 manifest bump 补 `known_payload_release_tag/sha256`（selftest-packs T9 先行拦截）。
- 重建 bundle 的逐字节一致不可得（tar/zip 时间戳 + 源 pin 更新，非本刀引入），以内容对比为准。
