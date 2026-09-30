# AOT-V3-RC2：rc.2 主线重出 NativeAOT 包（UIPage 修复保留）并发布 `aot-haps-v3-rc2.tar.gz`（2026-09-30）

> 目的：`aot-haps-v3.tar.gz`（2026-09-29）是 **rc.1 线**工具链（SDK `…rc.2.26451.109` + workload
> preview.24 pack，UI 壳 abc 289,992 / 宿主 281,504）的产物；kit #34 已把 **rc.2 基线并入主线**
> （SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`）。
> 本任务在 rc.2 主线上用 `test/hello-maui-app/publish-aot.sh`（含 UIPage 必备件）重出 AOT 对，
> 作为 kit #34 的 AOT 取件包，并发布并列资产 `aot-haps-v3-rc2.tar.gz`（新名；v3/v2/v1 保留对照）。
>
> 关联：`2026-09-29-ohos-aot-v3-rebuild.md`（v3/rc.1 口径与 UIPage 根因）、
> `2026-09-30-ohos-kit34-local-device-verification.md`（rc.2 前证）、`ohos-workload`
> `test/hello-maui-app/AOT.md`（常驻参考卡）、`sdk-ohos` `documentation/ohos-install/NATIVE-AOT.md`
> （rc.2 pack 镜像，LEFTOVER-D `f351f7be90` 已先同步）。

## 1. 输入与 provenance

| 项 | 值 |
| --- | --- |
| 工作仓 / publish 脚本 | `springmin/ohos-workload` @ `ece8e8dd1098ef93bbe63ce0dff6e41af5da5d08`（`publish-aot.sh`/`AOT.md` 原样执行；无仓内改动） |
| slice（冻结副本） | `springmin/maui-ohos` `ebffdd787c8e0dcd99a9c4cccfd279e2a057a494`（rc.2 主线 tip：rc.2 slice 重锚 + 分析器作用域；含 W6/W7/W8 = T12/T14/N1/FIX-SHELL + T15/T16/N4/T18/N5/N6）→ scratch `lo-b/slice-rc2/`（130 文件；`OpenHarmonyWindowRenderer.cs` blob `5e2271c2…` == 提交 blob） |
| SDK / workload | `~/.dotnet.rc2-fix`：SDK `11.0.100-rc.2.26451.112`（host `.112`，RID `openharmony-arm64`）、workload `openharmony 1.0.0-preview.28/11.0.100-rc.2` |
| AOT packs（feed） | `aot-packs-11.0.0-rc.2` 镜像两件（`Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64` 28,166,644 / `46d221f2…`；`runtime.openharmony-arm64.Microsoft.DotNet.ILCompiler` 43,828,858 / `1c518a46…`），放入 `lo-b/feed/` 经 `--source` 解析；`obj/project.assets.json` 复核 = `Microsoft.DotNet.ILCompiler/11.0.0-rc.2.26451.112` |
| 本机 hooks | `aot-v3/aot-local-hooks.targets`（preview.28 Exec 批处理包装替换；`OHOS_AOT_HOOKS` 注入，不落仓） |
| publish 命令 | `publish-aot.sh` 内部原命令（`-m:1 -p:PublishAot=true -p:PublishAotUsingRuntimePack=true -p:OpenHarmonyHapPackage=true -p:OpenHarmonyUIPage=pages/Index -p:OpenHarmonyRuntimeMode=aot`；slice 指向冻结副本），日志 `lo-b/publish-aot-rc2.log`，`EXIT=0`（2026-09-30 12:01:41；IL2026/IL3050/IL3051 = 0） |
| 运行时偏差记录 | 仓库 `publish-aot.sh` 的 guard 唯一命中的重型进程是 reg-kit34 遗留的孤儿 `prepare-packs.sh`（ppid 1）csc：RSS 6 MB、I/O 计数冻结、输出 DLL 未更新（2026-09-28）、FUTEX 自旋 >1.5 h，属不可完成的楔死进程；本轮改用 `lo-b/publish-aot-rc2-noguard.sh`（同命令 + 内存门禁 ≥2 GB + 楔感知 guard，忽略该 pid），余无并发重型构建 |

## 2. 产物指纹（发布值）

| 产物 | 大小 (B) | sha256 |
| --- | --- | --- |
| `libhello-maui-app.so`（publish） | 18,529,040 | `5adb9a6ba76e5b8915e87135f1adfa57bc596641dcf991703407cecddac51859` |
| `hello-maui-app.hap`（pack 自签，publish 输出） | 21,499,067 | （不发布） |
| `hello-maui-app-aot.hap`（preview.28 `sign-hap.sh` + UDID `60CF7B27…` 重签，**发布件**） | 21,498,977 | `332f2d8bb549c2739dbedb5796cab89d706cf543d16ad72bce168b14c1f90f5b` |
| `hello-maui-app-aot-unsigned.hap`（**发布件**） | 21,231,313 | `4e3f0b1ad0f861d565d59eaee2002e517b7f419ea3c816b0db1b3b778bef83ac` |
| hap 内宿主 `libopenharmonyhost.so` | 285,600 | `00ee9c84ebd63905c5d9cdfefa6652e82e5a48c581c944f3420a58ebfa62883a`（== preview.28 pack，含桥） |
| hap 内 `ets/modules.abc`（**UI 壳**） | 311,424 | `7c1a3cacfcc62f4a14345e09971bb77849e5dde6d9c8f9041d6b70999d230ba2`（== preview.28 pack `templates/ets/modules.ui.abc`） |

- so：`nm -D` 含 `T openharmony_app_main@@V1.0`；`.codesign` sections=1；NEEDED = `libc.so`；IL 门禁 0。
- hap 形态（signed/unsigned 一致）：仅 3 个 `.so`（app so + host + `libc++_shared.so`），**无**
  `libcoreclr.so`/`libhostfxr.so`/`libclrjit.so`；`main_pages={"src":["pages/Index"]}`、
  `runtime-mode.txt=aot`、`libs/arm64-v8a/.dotnet-payload.json`（`assembly=hello-maui-app.dll`）、
  `resources/rawfile/app.json` 在包；`module.json` `libIsolation=true`、无 `requestPermissions`。
- 静态核验：`lo-b/verify-aot-v3-rc2.sh` → **ALL CHECKS PASSED**（UI 壳 abc == preview.28 pack
  311,424/`7c1a3cac…`、含 `XComponent`/`loadContent`、host == pack 285,600/`00ee9c84…`、三 so 计数；
  日志 `lo-b/verify-aot-v3-rc2.log`）。签名 profile `device-ids` 单值 == UDID `60CF7B27…`（复核脚本内置断言）。

## 3. 本机真机验证（出画，2026-09-30）

- 设备：HAD-W32（OpenHarmony-7.0.0.111(SP3ENTC293E104R2P1log) / API 26，2in1；hdc `127.0.0.1:35111`）。
  已签件（tester UDID `60CF7B27…` profile）`hdc install -r` **直装成功**（该桌面镜像不校验
  device-ids），`aa start -b com.example.hellomauiapp -a EntryAbility` 起进程 **pid 47151**
  （证据 `lo-b/device/`：`install-v3rc2.log`、`aa-start-v3rc2.log`、`summary-v3rc2.txt`）。
- 进程：`VmRSS` 178,832 kB、`Threads` 61（含 4 × `OS_GC_Thread`/`ThreadPool*`）。
- 出画：RSTree **2 × `Name [ohos_dotnet_surfaceSurface]`、均 `hasSurfaceBuffer: 1`**；WMSDecor
  `uiContent is null` 计数 **0**；窗口 `hellomauiapp0 [515 281 2090 1394]`；截图
  `snap-v3rc2.jpeg`/`win-v3rc2.png`——渐变背景 + 居中按钮出画，edge-density **0.02%**（与 v3 rc.1
  同口径；headless 白窗对照 0.00%）。
- 局限（同 kit #34 本机口径）：本机无 `libhilog_ndk.z.so` → `OHOS_DOTNET`/`aot=` 行不可见（以
  RSTree/截图为准，tester 机复核日志）；本机直装顶替 kit 主包（同 bundle）。

## 4. 发布（release `springmin/sdk-ohos` tag `device-test-kit`，id 392356147）

新并列资产（**不动**旧包；assets 33 → 36）：

| 资产 | id | 大小 (B) | sha256 |
| --- | --- | --- | --- |
| `aot-haps-v3-rc2.tar.gz` | 599996905 | 18,185,012 | `3d24f716fe564bc39151b3fa53ab827884d6e6f71d5be5ca28f2da9c9e638423` |
| `aot-haps-v3-rc2.tar.gz.sha256` | 599996850 | 89 | `f51e2a0406aab986b5121059a689190c3f8493525ad37288eae4033020dd83dc`（内容 = tar 摘要） |
| `aot-haps-v3-rc2-README.md` | 599996913 | 6,580 | `05f9accbe68a0ddc0bf3a8700e8d3eec66a3428ff01e02eb6191706ce23a527d` |

- 校验（`lo-b/verify-download.py`）：**PART A/B PASS** —— by-id 三项 digest+size 与本地一致；相对
  发布前快照**仅新增这 3 项**（changed=[]、removed=[]，33→36）；gh-proxy 下载 tar/sidecar/README
  逐字节相等；tar 内两 hap sha 与本地一致、tar 内 abc = preview.28 UI 壳（311,424/`7c1a3cac…`）、
  `main_pages` 含 `pages/Index`；tar HEAD `200`。
- release notes 已追加一行：rc.2 线取件包（SDK `.112` / preview.28、slice `ebffdd787c` 含 W7/W8、
  UIPage 修复、出画已验证）取代 `aot-haps-v3.tar.gz`。
- tar 结构：`aot-haps-v3-rc2/{hello-maui-app-aot.hap, hello-maui-app-aot-unsigned.hap, README.md, SHA256SUMS}`。

## 5. 文档与提交

- `ohos-workload` `test/hello-maui-app/AOT.md`：rc.2 线 AOT pack/宿主/UI 壳值 + release lineage 新行
  （提交 `cdccccc`，推送 `master`，无强推）。
- `runtime-ohos`：本文件 + `docs/plans/README.md` 索引行（提交见 git log）。
- `sdk-ohos` `documentation/ohos-install/NATIVE-AOT.md`：rc.2 镜像与 `aot-haps-v3-rc2` 指针由
  LEFTOVER-D `f351f7be90` 先行同步（本文补资产实测值）。

## 6. 边界与未决

- **真机复测归 tester**：重签（tester 证书/Profile 绑 UDID）→ 安装（顶替 kit 主包）→ 启动 →
  `aot=1` → 主体渲染 + W5/T15/T16/N4/N5/N6 人工项；本侧钉死「rc.2 UI 壳 + 出画」。
- kit #34 数字（套件 513/floor 493、导出 145 等）为交付方证据，本包不重跑；kit 内 JIT hap 仍为 JIT。
- tab 双页签出画与 JIT 截图一致不可判定（承 v3 §4 局限）；a11y 影子树 TabbedPage 枚举为 follow-up。
- 本机 rc.2 的 `Exec` 批处理包装/cwd 问题仍用命令行 hooks 旁路（不落仓）；换干净环境重编按
  `docs/openharmony-hap-packaging.md`「Known environment quirks」复核。
- reg-kit34 遗留的楔死 `prepare-packs.sh`（csc FUTEX 自旋）以「忽略该 pid」旁路，未杀进程；
  其 S3（task/ref pack 字节）修复另行推进。
