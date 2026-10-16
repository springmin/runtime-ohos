# ECM（WinForms）迁移到 OpenHarmony 本机：最小代价分析与类库移植清单（2026-10-16）

> 目标：把客户 **ECM**（.NET Framework 4.0 时代 WinForms + DevExpress 11.1 桌面程序，
> 目录 `/storage/Users/currentUser/Desktop/ECM/Debug`，28 个程序集）迁移到**本机**
> （OpenHarmony arm64 + 本仓 .NET 11 端口），成本最小化。
> **结论**：原样运行不可行（代际 / UI / 桥接三重墙）；最小代价路线 = **Web 化（Blazor）重托管**；
> **真正需要移植到 HarmonyOS 的类库仅 SQLite native（e_sqlite3）**；唯一高风险 =
> **ASMPT SIPLACE OIB SDK**（须拿包实测其现代 .NET 兼容性）。**成本大头是 DevExpress UI 重写，不是类库移植。**

## 1. 事实基线

### 1.1 系统侧（本机）
- OpenHarmony arm64 · 官方线 .NET `11.0.100-rc.2.26504.105`（workload `1.0.0-preview.29`）。
- `Microsoft.AspNetCore.App.Runtime.openharmony-arm64` 运行时包**在**（`~/.dotnet.rc2-105/packs`，
  版本标签 `11.0.0-rc.1.26504.105`）→ Web（服务端）路线的技术底在。
- MAUI（本仓 port）在；**无** .NET Framework / Mono / WinForms / Windows API / X11。

### 1.2 应用侧（实测版本 + 联网核实的出身）
| 程序集 | 版本 | 出身 | 动作 |
|---|---|---|---|
| `ECM.exe` / `DataClient` / `DataCommon` / `TestDLL` | 1.0.0.0 | **客户自研** | 源码在手 → net11.0 重编译；TestDLL 丢弃 |
| `ASM.AS.OIB.{Common,SIPLACEPro}.{Contracts,Proxy}`（4 件） | **5.3.0.60** | **ASMPT「SIPLACE OIB SDK」编译代理**（OIB = Operations Information Broker：SIPLACE 产线↔MES 数据中间层；SDK 官方提供 .NET compiled proxies，2016–2019 世代） | ⚠️ **最大不确定项**：查 SDK 的 TFM/绑定（WCF/Remoting/COM？）；若不兼容 CoreCLR → **独立桥进程**（第三方 OIB 集成在 .NET 8 时代亦用 "separate managed wrapper executable"） |
| `DevExpress.*.v11.1`（16 件：XtraGrid/TreeList/Bars/Editors/Charts/RichEdit/Printing/Layout/NavBar…） | **11.1.6.0** | **DevExpress 2011 vol 1（WinForms 套件）** | ❌ 不可移植（Win GDI+ 独占）→ **必须替换**（Blazor 组件；DevExpress 现代 Blazor 套件可平滑选型 / MudBlazor / Radzen） |
| `Npgsql` | **4.0.0.0** | 开源 PostgreSQL .NET 驱动（netstandard2.0） | ✓ 直接可跑；建议升 8/9.x（纯托管，**零移植成本**） |
| `System.Data.SQLite` | **1.0.113.0** | **SQLite 官方团队** ADO.NET 提供者；1.x = 混合模式（内嵌 **Windows x86 native**） | ⚠️ **移植点 #1**：换 **SDS 2.x**（2.x 已改标准 `libe_sqlite3.so` + P/Invoke）或 Microsoft.Data.Sqlite → **为 openharmony-arm64 构建 e_sqlite3**（~0.5–1 人日） |
| `Newtonsoft.Json` | 12.0.0.0 | 开源（MIT；netstandard2.0） | ✓ 直接可用（或换 System.Text.Json） |
| `System.ValueTuple` | 4.0.3.0 | MS 兼容 polyfill | **删**（现代 .NET 内置） |
| System.\* / mscorlib（引用） | 4.0 世代 | .NET Framework 基础 | 由**本仓 OHOS .NET 11 端口**提供 |

## 2. 为什么"原样运行"排除
① 代际：Framework 4.x 程序集身份在 CoreCLR-11 下无 WinForms 实现；② UI：System.Windows.Forms +
DevExpress 11.1 = Windows GDI+ 独占（DevExpress 无 OHOS 目标）；③ 桥接：本机无 Mono（其 WinForms
亦需 X11）、无 Wine——不存在"装个 runtime 就能跑"的路径。

## 3. 路线取舍（定路线 = 定 80% 成本）
- **A. Web 化重托管（Blazor）——推荐**：服务端跑在本机（ASP.NET Core OHOS 运行时包在），UI 用
  Blazor 重写，浏览器即客户端（本机带浏览器）；不引入任何原生 UI/图形库；数据密集表单/网格最匹配。
- **B. MAUI 原生（本仓 port）**：真原生体验，重写量更大；**可后置于 A——Razor 页面经 Blazor Hybrid
  100% 复用**。
- C. 保留 Windows / 远程：与"迁移到本机"目标不符，排除。

## 4. 类库移植清单（最终答案）
```
【真·移植（native）】仅 1 项：SQLite —— 构建 e_sqlite3（openharmony-arm64 .so）＋ SDS 2.x/Microsoft.Data.Sqlite 驱动
【重新编译】客户自研：ECM.exe / DataClient / DataCommon（源码在手）
【兼容评估】ASMPT SIPLACE OIB SDK 5.3 代理 4 件（不兼容则桥进程方案：本机或 Windows 侧，socket/gRPC 暴露）
【替换（UI 重写，非移植）】DevExpress WinForms 16 件 → Blazor/MAUI 组件
【零成本】Npgsql 升级即用 · Newtonsoft 留用 · ValueTuple 删 · System.* 由运行时提供
```

## 5. ASP.NET 本机冒烟（进行中，留证待续）
- `dotnet publish -r openharmony-arm64 --self-contained` 首败 **NU1101**（普通 `net11.0`+RID 不自动解析
  OHOS 运行时包）→ 以 `-p:RestoreAdditionalProjectSources=<bundle .29 feed>` 重试。
- 现阻 **NU1102**：SDK `KnownFrameworkReference` 期望 aspnetcore 运行时包 `11.0.0-rc.2.26504.105`，
  而 bundle/feed 提供 `11.0.0-rc.1.26504.105`（版本标签不一致）→ 待（a）workload 侧对齐或（b）属性覆写。
- **前置验证项**：Web 路线以"服务端能 publish + 本机跑通一次 HTTP"为准；未通过前 Step 1 并行推进不受阻。

## 6. 执行路径（最小代价节奏）
```
Step 0（源码 + OIB SDK 到手，1–2 天）：依赖扫描（TFM/绑定/COMorWCF/packages.config 全量）→ 移植清单定案
Step 1（独立验收）：数据+接口层升 net11.0（DataClient/DataCommon/SIPLACEPro.*）→ console 对账 DB/接口
Step 2：Blazor 骨架 + 3–5 个高频窗体 spike（XtraGrid→组件映射选型验证）→ 铺开
Step 3：本机部署（self-contained + 常驻/自启机制调研）+ 浏览器验收（报表/打印 → QuestPDF/浏览器打印）
Step 4（可选）：MAUI 壳（Blazor Hybrid）出原生 app
```

## 7. 需客户提供
ECM 源码（.sln/`packages.config`）· **ASMPT OIB SDK 安装包**（≥现有 5.3）· DB 连接/Schema ·
SIPLACE/OIB 线体版本与接口样例 · 报表样例 · 典型工作流截图。

## 8. 风险
- **OIB SDK 现代化程度未知**（若 netfx/WCF/COM → 桥进程，工期与运维形态变化）；
- SQLite native 构建（低，~0.5–1 人日）；
- ASP.NET-on-OHOS 端到端未验证（中，见 §5，已列前置）；
- **DevExpress UI 重写量**（成本大头，需与客户预期管理）；打印/报表栈替换。

## 9. 方法与来源
- 版本实测：`AssemblyName` 探针（本机 `.dotnet.rc2-105` 运行）；PE/引用扫描（WinForms/DevExpress 引用分类）。
- 出身核实（联网）：ASMPT 官网 /SIPLACE OIB SDK 4.3 Version Description（OIB=Operations Information
  Broker；SDK 提供 .NET compiled proxies）· DevExpress Version History/2011 vol 1 · system.data.sqlite.org
  （1.x `SQLite.Interop.dll` vs 2.x `e_sqlite3` + P/Invoke）· PCB-Investigator release notes（.NET 6/8 化的
  OIB connector 用独立 wrapper 进程，佐证桥进程备选）。
- 仓库侧前置：ASP.NET Core OHOS 运行时包与离线 feed（`dist/openharmony-workload-1.0.0-preview.29/feed`）。
