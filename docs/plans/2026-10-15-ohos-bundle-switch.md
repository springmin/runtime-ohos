# BUNDLE-SWITCH：产品 bundle 落定（`mauidemo.dotnet.springmin.com`，2026-10-15）

> 结论：demo/脚本/套件/壳 abc 全线切到 AGC 应用（= 发布 Profile）bundle；随 #58，不处理上游 PR。

## 变更面（ow `master`）
- csproj 默认 → 新 bundle（旧值留注释成 override 示例）；同默认源：`build-arkts-shell.sh`（BUNDLE_NAME）、`sign-for-device.sh`（device 默认）、`verify-kit.sh`（BUNDLE_EXPECT）、`tester-run.sh`（FALLBACK/probe）、`device-round.sh`（BUNDLE/fault grep）、a11y-client（TARGET_BUNDLE）、hello-maui-hybrid（随 abc）。
- abc：`.22/.23/.24/.28/.29` 五包 ui/headless abc + `abc-provenance.json` 同源重建（同字节；`.25–.27` harmony 历史包不动）；构建位 `.dotnet`/`.rc2-105`/`.rc2-fix` 安装包同步（不入仓）。
- pin/文档：套件新增 `bundle-switch defaults` 并重锚 abc；`verify-kit` EXPECT `637300,24340`、selftest `ABC_SIZE`/断言、`docs/rc2-line-notes.md`、三 workflow 注释随动；历史轮/交接文档保留旧值。
- bundle 保持不动的样例：Blazor WASM hap `com.example.opendotnet`、razor `com.example.hellomauirazor`、wasm `com.example.hellomauiwasm`（后两者自带 abc 编译步骤；wasm README/publish-aot 的包内 abc 引用已更新）。

## 重锚值
ui abc **637,256/`ab02cc20…` → 637,300/`4070204a4dc8…`**；headless **24,324/`798b2477…` → 24,340/`944529ae9335…`**；套件 **825/828 floor 808 → 826/829 floor 809**（+1：bundle 默认值 pin）；host `1e156f42…` 不变（so 内无 bundle 字符串）；五包 provenance gate（`--check-pack-abc`）通过。

## 发布签名通道（免 UDID）
- 主 app 与 release profile 同 bundle → 库存发布件可直接 `sign-for-device.sh --release <hap>`（首签链与 PKCS12/csc 两坑见 `2026-10-15-ohos-release-first-sign.md`）；真机安装/冒烟待设备回线。
- **切包 TODO（#58）**：轮包是否随带 release-signed 主 hap（免 UDID）——若带，预签走 `--release`；否则维持自签调试件口径。

## 验证与不确定项
套件 **826/829 floor 809 assert=True**（0 assert=False）、相关 selftests 全绿、样例 JIT 构建 `module.json` bundleName = 新 bundle 且 hap 内 `ets/modules.abc` 逐字节 = 包内 ui abc、CI 5/5（+harmony 如需）；ow 提交见本波 commit message。release 链真机接受性（安装/冒烟）未闭环——与 RELEASE-FIRST-SIGN 同悬；harmony 历史包 abc 仍带旧 bundle，仅显式走 harmony 分支重建时需 `ARKTS_SHELL_BUNDLE_NAME=`。
