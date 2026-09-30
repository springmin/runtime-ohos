# JIT 本机实跑（JIT-LOCAL：rc.2 主线 + DeviceCompat 重出包，2026-10-01）

> 设备 HAD-W24 `7.0.0.111(SP3ENTC293E104R2P1log)`（API 26，2in1），hdc 无线 `127.0.0.1:35111`，UDID `1BCE13C8…AEA0`；
> 构建 = rc.2 线（`~/.dotnet.rc2-fix`：SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28`）+ 壳 abc `fc54d2b8…`（339,964）；
> 签名 = preview.28 `sign-hap.sh` + ohos-sdk `26.0.0.18_2/toolchains/lib`；证据 scratch `/data/storage/el2/base/tmp/opencode/jit-local/`（`build/ device/`）。

## 1. 构建 / 签名 / 安装 ✅

- `dotnet publish test/hello-maui-app … -p:OpenHarmonyHapPayloadInLibsDeviceCompat=true`（`OpenHarmonyUIPage=pages/Index`）：
  DeviceCompat 重写 2 处 —— `createdump`→`createdump.so`、`Microsoft.OpenHarmony.dll` 4096→4100 B（`dotnet.zip` 保原名原字节）；
  `libs/arm64-v8a/runtime-mode.txt=jit`；未签 **131,445,380 / `c42efbc1…`**（kit #36 同源 131,445,371，差 = 改名+3、补 4、zip +2）。
- 自签 **133,985,274 / `bcf72baf…`** → `hdc install` **`install bundle successfully`**：enforcing 镜像（≥7.0.0.111）首次由本侧
  rc.2 真构建源端到端复现 E6（`9568393` 不再出现）。
- 两个对照构建/安装亦通过：新 bundle `com.example.hellomauiappjit`（签 133,985,238 / `2fe070b1…`）、
  `-p:AssemblyName=hello-maui-app-jit`（签 133,984,707 / `95f98fd0…`）。

## 2. 首启发现：AOT 旁路 ⚠（安装残留在先）

- 安装后启动未走 JIT：hilog `OHOS_HOST start_app aot=1 lib=…/libhello-maui-app.so`；而 hap 本身无该文件（`unzip` 核 15 个 `.so`，
  kit #36 件同）——该 lib 是同 bundle 更早 AOT 安装残留在模块 `libs/` 目录里的新旧合并副作用 → 宿主优先 AOT。
  该路径应用正常出画（RSTree `hasSurfaceBuffer: 1`、截图 Home/Animations 双页签）。
- 提示：本机复测 JIT 前必须确认 `lib<stem>.so` 不在已装目录，否则结果非 JIT（换名或用 `-r` 覆盖后再核 hilog `aot=`）。

## 3. 真 JIT 实跑：SEGV_ACCERR（禁 JIT，预期复现）❌

- 绕开残留 AOT：`AssemblyName=hello-maui-app-jit`（bundle 不变，壳兼容；探针名 `libhello-maui-app-jit.so` 不存在）→
  `payload-in-libs: running from /data/storage/el1/bundle/entry/libs/arm64 (dotnet.zip not unpacked)` +
  `managed app hello-maui-app-jit.dll started (UI shell) from …/libs/arm64`，约 30 ms 后进程崩（exit=CppCrash，前台）。
- cppcrash（`/data/log/faultlog/faultlogger/`；两件同签名：`…070057218`（512,219 B，jit 名）与 **`…070229558`（505,238 B / `7a212d3f…`，正式名）**）：
  `Reason:Signal:SIGSEGV(SEGV_ACCERR)@0x0000005cccff0000`，Fault thread `le.hellomauiapp`：
  `#00 memcpy+312 (ld-musl) ← #01–#05 libcoreclr.so ← #06 coreclr_initialize+996 ← libhostpolicy ← libhostfxr ←
  libopenharmonyhost.so OhosAppThread`。
- 宿主 exec 内存探针（同镜像）：`1=22 2=22 3=13 4=1`（anon RWX EINVAL / anon RW→RX EINVAL / memfd EACCES / 临时文件 RX EPERM）
  —— HAP 域四条可执行内存路线全拒；JIT 代码页拷贝（memcpy）写入即 SEGV_ACCERR，UI 无法进入。

## 4. 与 tester kit #22/#30/#31 对照

- tester 判决（复测任务单 JIT 行；kit #30/#31 承 #24 的 `probe`×`xwe` 表）：`SEGV_ACCERR` = JIT 不可用 → 以 AOT 资产判主体；
  本机崩溃形态与之**一致**（memcpy→SEGV_ACCERR；`2026-09-24-ohos-runtime-strategy.md` §16 记录的 tester 形即此形）。
  差异候选：本机探针 1/2（匿名 exec）也失败，比「仅 memfd 被拒（W^X=1）」假设更严；HAP 域/镜像差异未证，tester 侧未见同栈件，可拿本条栈对照。
- 排除一个非 JIT 失败：仅换 bundle 名（`…jit`）时壳 abc 与新 bundle 不匹配 → jscrash `Cannot find module 'ets/entryability/EntryAbility'`
  exit 254（壳按 bundle 绑定）；改用 AssemblyName 旁路即可（本次使能前已知）。

## 5. 未决 / 不确定项

- 残留 AOT lib 的清理语义未定：`bm uninstall` + install 后仍在（本次首启先例）；07:00 `install -r` 后再验即无（JIT 生效）。何操作保证清干净未定。
- DeviceCompat 补丁（dll 4100 B）对 JIT 运行无影响的未单独证（崩溃在更早的 `coreclr_initialize`）；E6/E7 安装结论仍有效。
- tester 机（7.0.0.105）JIT 是否同栈待回传；解释器/mode-matrix 未测。

> 设备末态：重装 AOT `aot-rc2-signed.hap`（kit36-local 同件）→ `hellomauiapp` pid 35342 运行（AOT）；`com.example.hellomauiappjit` 已卸载；hilog 缓冲保持 512K。
