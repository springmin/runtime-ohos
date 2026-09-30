# 本机设备回路测试 runbook（OpenHarmony 桌面 + hdc 无线调试）(2026-09-29)
> 本机桌面 HAD-W32 / OpenHarmony-7.0.0.109 / API 26；hdc `127.0.0.1:35111`；UDID `1BCE13C8…AEA0`。流程：装→起→
> 日志/截图/layout/渲染树。关联 `2026-09-29-ohos-aot-v2-rebuild.md`；证据 scratch `/data/storage/el2/base/tmp/opencode/dev-maui/`。
## 1. 变量与 hdc 连接（掉线恢复）
```sh
HDC=/storage/Users/currentUser/ohos-clt/sdk/default/openharmony/toolchains/hdc
LIB=/storage/Users/currentUser/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_2/toolchains/lib
SIGN=/storage/Users/currentUser/.dotnet/packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/templates/scripts/sign-hap.sh
UDID=$( $HDC shell "bm get --udid" | tail -1 )      # 1BCE13C8046F7FCB9E86AC406AC6BB6CA9DFA92120A3CA85931022F4D4ADAEA0
$HDC list targets -v          # 已知 key（含 Offline）；Connected 即 127.0.0.1:35111
$HDC tconn 127.0.0.1:35111    # 重连；端口失效先扫描（~4s，封闭口立即 ECONNREFUSED）：
python3 -c 'import socket
for p in range(1024,65536):
 s=socket.socket(); s.settimeout(0.02)
 print("open",p) if s.connect_ex(("127.0.0.1",p))==0 else None; s.close()'
$HDC tconn 127.0.0.1:<open 端口>    # 候选 11434/48299/49374；设备侧可 awk /proc/net/tcp st=0A
$HDC shell id                       # uid=2000(shell)；smode 被拒（undebuggable version）
```
## 2. 签名 / 安装 / 启动（bundle `com.example.hellomauiapp`）
```sh
sh "$SIGN" "$LIB" <unsigned.hap> out.hap com.example.hellomauiapp "$UDID"   # workload 自签 hap 可直接装
$HDC install -r out.hap; $HDC shell "bm uninstall -n com.example.hellomauiapp"   # 换证书先 uninstall
$HDC shell "aa force-stop com.example.hellomauiapp"; $HDC shell "aa start -b com.example.hellomauiapp -a EntryAbility"
$HDC shell "pidof com.example.hellomauiapp"; $HDC shell "cat /proc/<pid>/status | grep -E 'Threads|VmRSS'"
$HDC shell "for d in /proc/<pid>/task/*; do cat \$d/comm; done | sort | uniq -c"  # OS_GC_Thread/ThreadPool* = .NET 起了
```
## 3. 取证（日志 / 截图 / 窗口 / layout / 渲染树）
```sh
$HDC shell "hilog -r"; timeout 30 $HDC shell "hilog" > dev.log    # 流式抓（-x 缓冲秒级滚掉）
grep -E 'OHOS_DOTNET|OHOS_MAUI' dev.log                           # ArkTS 壳（域 A00002）唯一可靠通道
$HDC shell "snapshot_display -f /data/local/tmp/s.png"; $HDC file recv /data/local/tmp/s.png .
$HDC shell "uitest screenCap -p /data/local/tmp/c.png"; $HDC file recv /data/local/tmp/c.png .
$HDC shell "uitest dumpLayout -p /data/local/tmp/x.json -b com.example.hellomauiapp"; $HDC file recv /data/local/tmp/x.json .
$HDC shell "hidumper -s WindowManagerService -a '-a'" | grep -E 'hellomaui|Focus window'   # 窗口/焦点/WinId
$HDC shell "hidumper -s RenderService -a 'RSTree'" | grep -E 'ohos_dotnet_surface'         # 面 buffer=1 即有像素
$HDC shell "ls -la /data/app/el2/101/base/com.example.hellomauiapp/haps/entry/files/"      # userId=101；0600 读不了
```
## 4. 本机 vs tester 机差异（判读用）
| 项 | 本机（桌面） | tester 机（手机） |
|---|---|---|
| hdc | `tconn 127.0.0.1:<port>` 本地无线调试 | USB/同网，`list targets` 直见 |
| hilog 缓冲 | 512K 环仅 ≈4–5 s；噪声大时 `--blazor-probe`（4 s 窗口）曾丢 `BLZ_BOOT` 误报 `boot=no`——临时 `hilog -G 16M -t app,core` 后全绿（已还原） | **待核对**；必要时临时调大缓冲（事后还原），或先 `--capture 60` 流式复核 |
| host/`[maui]` 日志 | 本镜像无 `libhilog_ndk.z.so` → stderr，hilog 不可见 | 有该库 → `aot=`/`xwe=`/`interp=` 行可见 |
| 应用 filesDir | `/data/app/el2/101/base/<bundle>/haps/entry/files/`（`/data/storage/el2/...` 是 shell 用户自己的） | 同 userId 规则；`tester-run.sh` 可列 |
| 窗口/a11y | PC 窗可被 ✕ 关（退出码 0，非崩溃）；`dumpLayout -b` 空；`snapshot_display` 能截 XComponent | 全屏 ability；`--a11y-probe` 走 kit 自检 |
## 5. AOT hap 发布注意（本轮空白窗根因/fix）
AOT publish **必须**带 UI 壳开关，否则只有 headless abc（无 `loadContent`/XComponent；窗口全白 + `uiContent is null`）：
```sh
dotnet publish test/hello-maui-app/hello-maui-app.csproj -f net11.0-openharmony26.0 -r openharmony-arm64 \
  -c Release -m:1 -p:PublishAot=true -p:PublishAotUsingRuntimePack=true -p:OpenHarmonyHapPackage=true \
  -p:OpenHarmonySdkRoot=$OHOS_SDK -p:OpenHarmonyUIPage=pages/Index    # ← 关键；kit 的 JIT 构建本就带
  # 可选 -p:OpenHarmonyRuntimeMode=aot（仅标记；路由由 lib<stem>.so 探测决定，不加也走 aot）
```
修复后 `ets/modules.abc`=UI 壳（≈290 KB）、`main_pages={"src":["pages/Index"]}`；真机 RSTree 出 `ohos_dotnet_surface`（hasSurfaceBuffer=1）、进程有 .NET 线程、无 `uiContent is null`。
> **2026-09-29 落地**：修复后的 AOT 包已作为 `aot-haps-v3.tar.gz` 发布（device-test-kit release，
> 17,537,186 B / `004ba03c…`，asset 597904340；本机真机出画已验证）；v1/v2 保留对照。判定点回写
> ohos-workload `30a1c7e`（`publish-aot.sh`/`AOT.md`/`make-mode-kit` 默认 UIPage）。见
> `2026-09-29-ohos-aot-v3-rebuild.md`。

## 6. rc.2 线与本机直测（2026-09-30 更新）

- **rc.2 线本机环境**：`DOTNET=$HOME/.dotnet.rc2-fix/dotnet`（SDK `11.0.100-rc.2.26451.112` + workload
  `1.0.0-preview.28` + rc2 AOT packs；`OS Platform: Linux`）；默认根 `~/.dotnet` 保留 rc.1 回滚线，**勿覆盖**；
  dnceng daily feed 与构建三坑（MSBuild server / VBCSCompiler / 无超时 restore）见 `ohos-workload/docs/rc2-line-notes.md`
  与 `kit-build-env.sh`。
- **已可直测**：hdc 无线 + SDK 自签 + AOT 路径 —— `DOTNET=$HOME/.dotnet.rc2-fix/dotnet AOT_WORKDIR=<scratch>/aot
  OpenHarmonyMauiPlatformDir=<slice> sh test/hello-maui-app/publish-aot.sh` → `scripts/sign-for-device.sh <UDID>` →
  `hdc install -r` + `aa start` + RSTree/截图（2026-09-30 rc2 冒烟：`ohos_dotnet_surface` buffer=1、`uiContent is null`=0）。
- **已知限制（根因更正 2026-09-30）**：**JIT payload-in-libs 主包在本机新镜像（≥7.0.0.111 系）装不上**（`9568393`）。
  实测与“非 ELF”无关：libs 内**无扩展名**文件不在 HAP 码签块、**恰好 4096 B** 文件 fs-verity 使能失败；
  检测 = `hdc install` 后 `hilog -x -e 'CODE_SIGN|ParseNativeLibSignInfo'`。主包 JIT 真机判定仍以 tester 机为准，
  本机可用 `-p:OpenHarmonyHapPayloadInLibsDeviceCompat=true`（重写分包）或 `-p:OpenHarmonyHapPayloadInLibs=false`
  重出包 / `aot-haps-v3` 复测（两种布局本机均已安装通过）；证据与对策见
  `docs/plans/2026-09-30-ohos-jit-payload-install-policy.md`。
- **kit #35 复测入口**：`docs/plans/2026-09-30-ohos-tester-handoff-kit35.md` §2–§4（AOT 包 rc.1 钉注见 §3/§7）与
  `docs/plans/2026-09-28-ohos-retest-taskcard.md`。
