# A11Y-EXPORT-ROOTCAUSE：`export=False` 预探针的加载器层根因（2026-10-08）

> 口径：设备 HAD-W32 @ 127.0.0.1:35111（互斥锁协议，已释放）；诊断 hap = scratch 版 hello-maui-app
> （**独立 bundle `com.example.a11yloader` + 为该 bundle 重编的 shell abc**，产品 hap 全程未动；
> 产品代码零改动，诊断代码只在 scratch `a11yloader/`，不落库）。引用制品 = kit #53 宿主 `ad7ab986…` /
> 导出 164/164（`host-exports.txt:20-21` 含 `provider_status(_for)`）。承 `-l3-m3.md` §5（`export=False
> status=1`）、SEC7-A（同族预探针）。

- **最小复现（同一进程、同一导出）**：`NativeLibrary.TryLoad("libopenharmonyhost.so", out _) = False`
  （kit#53 旧 `WindowProviderExportAvailable` 的原调用）而直呼 `[LibraryImport] provider_status() = 1`；
  `NativeLibrary.Load(short)` 抛 `DllNotFoundException`，内嵌 `dlerror` 原文 =
  `Error loading shared library libopenharmonyhost.so: No such file or directory`。
- **真机对照（late/route 两相 + 相内先后序，结论一致；pid 12559，0 crash）**：
  - 简单重载（raw 路径）：`S1/S3/S4=False`；libc `dlopen(short)=0x0` 同 dlerror；`dlopen("/data/storage/
    el1/bundle/entry/libs/arm64/libopenharmonyhost.so")` 成功且 `dlsym` 命中；`NL.TryLoad(绝对路径)=True`。
    控件：`libcoreclr.so`、`libSystem.Native.so` 裸名同为 False → 平台级，非 host 特有。
  - 高层重载（运行时探测）：`NL.TryLoad(short, asm, AssemblyDirectory)=True`（句柄可查导出）；`H2(null)=True`；
    `I1 P/Invoke=1`。环境：`NATIVE_DLL_SEARCH_DIRECTORIES=<null>`、`LD_LIBRARY_PATH=<null>`。
  - 已加载性/时序非因素：先绝对路径 dlopen 后 `S5=False`；P/Invoke 后 `S6=False`；`/proc/self/maps` 已含
    `…/entry/libs/arm64/libopenharmonyhost.so`（加载路径=绝对路径）；`RTLD_DEFAULT` 可见该导出（G1=True）。
- **机制（为何直呼可行）**：CoreCLR 简单重载 = `LoadFromPath` → `SystemNative_LoadLibrary` →
  `dlopen(name, RTLD_LAZY)`，无任何探测（`NativeLibrary.cs:268`、`pal_dynamicload.c:41`；文档即 “OS loader
  wrapper”）。P/Invoke 与高层重载走 `NativeLibrary::LoadLibraryByName/LoadFromMethodDesc` 探测链（ALC →
  AppDomain 缓存 → **assembly 目录** / `NATIVE_DLL_SEARCH_DIRECTORIES` 绝对路径 → PAL dlopen；
  `nativelibrary.cpp:674/783`）。OHOS 上 app-local `libs/arm64/` 不在加载器裸名搜索路径内，且已加载对象不按
  裸名（soname）匹配（S5），故简单重载必然 False；宿主与托管程序集同目录（`AppContext.BaseDirectory=
  /data/storage/el1/bundle/entry/libs/arm64/`，`file(base)/libopenharmonyhost.so exists=True`），P/Invoke 的
  assembly 目录探测命中 → “直呼可行”。**`export=False status=1` 不是加载器 bug，而是预探针用错了 API 层
  （simple vs high-level）；OHOS 不复现桌面 Linux 的 LD_LIBRARY_PATH/RUNPATH 兜底。**
- **长期建议**：① OHOS 永不用简单重载做导出判定；可选导出统一“直呼 + `EntryPointNotFound`/`DllNotFound`
  一次性缓存”（kit#53 `PublishSecondary`、SEC7-A `ReleaseProviderState` 已示范）。② 同族残留（@ maui
  `b914379269`）待同波次清除：`OpenHarmonyScreenshot.IsAvailable/IsFormatAvailable`、
  `OpenHarmonyWindowHandler.ExportAvailable`、`OpenHarmonyShellExtras.ExportAvailable`、
  `OpenHarmonyAccessibility.AnnounceExportAvailable`——真机上均会静默降级（截图 False、窗口 chrome/flyout
  文本/announce 文本走 managed/无文本兜底）。③ 不建议为此改运行时 `SystemNative_LoadLibrary`（改契约语义），
  如需先走端口侧讨论。④ 旧宿主降级缓存**保留**，只换探测原语，勿整体删除预探针机制。
- **证据/资产**：设备命令 `hdc install -r` / `aa start` / `aa start -U app://diag/a11yloader` / `hilog -x`；
  摘要 `a11yloader/r2-diag-hilog.txt`（`[diag-al]` 33 行去重）+ `build.log`/`build2.log`/`shell-build/
  shell-build.log`；重编 shell abc `shell-build/dist/ets/modules.abc`（542,916 / `c3050f8a…`，已过脚本
  abc-version/探针 gate）。离线符号：`llvm-nm -D` = `T provider_status/_for`，`SONAME=libopenharmonyhost.so`。
- **收尾**：诊断 bundle 已卸载、产品 app（pid 56705）安装态/进程未动、WMS 残留 0、锁释放、常亮已设；
  #49–#53 资产未动。
- **不确定项**：OHOS 加载器“裸名不按已加载 soname 匹配 + 不含 app-local 搜索路径”为该夜实测行为（本机无
  musl/ldso 源可证）；`Program.Main` 前相位经 host 状态→hilog 桥未达（仅 late/route 落 hilog；文件在
  app sandbox `/data/storage/el2/base/cache/`，卸载后不可取），但相内“先加载/后 P/Invoke”与两相位一致，足以
  排除时序/缓存；`provider_status_for('diag-probe')=0` 为未知实例的预期值；同族残留未逐点真机复验（同原语）。
