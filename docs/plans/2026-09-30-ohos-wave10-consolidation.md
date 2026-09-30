# Wave 10 收口（W10-CONSOLIDATE 执行记录，2026-09-30）

> W10-AOTENTRY 单线（`ohos-workload`）：NativeAOT 入口在自身 libs 解析 + AOT 路由可观测、壳 AOT
> payload 探针/静态资源指纹重出四包、套件 +2、kit 引脚重锚；maui 切片未动（`eec30c01cd`）。
> 线性优先、禁强推；执行 scratch `/data/storage/el2/base/tmp/opencode/w10-consol/`（门禁复跑日志）。

## 1. 改动（ow master `bad7475`；收口注释 `080a63a`）

| 提交 | 内容 |
|---|---|
| `f9e479e` | host：在自身 libs 解析 AOT 启动镜像（`lib<stem>.so`），AOT 路由写 `dotnet-status.txt` |
| `13ef2c9` | shell：AOT-aware payload 探针、`fs` 别名修复、静态资源指纹映射；四包 abc 重出 + provenance |
| `103554e` | 交互套件钉 AOT 入口/payload-serve 契约（+2 → 540/520） |
| `74e582a` | kit 引脚：ui **339164** / headless **23516** |
| `bad7475` | AOT demo publish 加 `InvariantGlobalization`（无 ICU 镜像不 FailFast）；maui 无改动 |
| `080a63a` | ci：interaction/pixel/host-export 注释同步 540/520 与 `eec30c01cd`（本收口） |

## 2. 门禁（合并树复跑，2026-09-30）

- 交互套件 **540/540 floor 520** `assert=True`（declared==printed；perf/a11y 5 线 `within=True`）。
- 导出 **149/149**（`--cross-check`）；切片 **0 error / 0 IL**；设备：wasm `BLZ_BOOT`/`BLZ_RENDERED`
  （pid 6157）、MAUI hot `delivered=1`（W10 EVIDENCE）。
- 壳 abc：ui **339164 B**/`74054e2d…`、headless **23516 B**/`6bce4063…`；四包 22/23/24/28 逐字节一致 +
  同 provenance（selftest-verify-kit 108/0、packs 25/0、repo-hygiene 25/0）。
- CI **5/5**（`bad7475` push：交互 36722556381 / 像素 36722556822 / 导出 36722557065 / ridgraph 36722557300 / markdownlint 36722556890；`080a63a` push 亦 5/5）。

## 3. 上游缺陷最小复现（rc.2 AOT 包 OpenSSL shim 0 定义）

```sh
A=~/.nuget/packages/microsoft.netcore.app.runtime.nativeaot.openharmony-arm64
nm --defined-only $A/11.0.0-rc.1.26451.109/runtimes/openharmony-arm64/native/libSystem.Security.Cryptography.Native.OpenSsl.a | grep -cE 'local_(EVP|SSL|X509)'  # 5
nm --defined-only $A/11.0.0-rc.2.26451.112/runtimes/openharmony-arm64/native/libSystem.Security.Cryptography.Native.OpenSsl.a | grep -cE 'local_(EVP|SSL|X509)'  # 0
```

rc.2 档案 574 定义 / 35 对象 vs rc.1 1184 / 36；rc.2 链接的 AOT 镜像遗留 ~401 OpenSSL 未决引用，设备 dlopen 拒绝（now=err lazy=err）→ 本机 hooks 钉 rc.1.26451.109（不落仓）。

> **已修（2026-09-30，RC2-AOTPACK）**：`aot-packs-11.0.0-rc.2` 新增修正资产
> `...rc.2.26451.112-r2.nupkg`（`542058cf…`，asset 601289590；归档重编 shim 版，
> 判据 5/5），sdk-ohos `48c8b210dc` 换锚并在 fetch 端做 shim 内容校验；
> 详见 `2026-09-30-rc2-aotpack-openssl-shim-fix.md`。下方 §4 首条（rc.1 钉）可撤。

## 4. 未决

- **rc.2 AOT 包路径（✅ 已修，2026-09-30）**：修正资产 `...rc.2.26451.112-r2.nupkg`
  + sdk-ohos `48c8b210dc`（fetch 端 shim 校验）已发布；原「设备 AOT 构建保持
  rc.1 pack 钉（本地 hooks）」可撤，改用 `aot-packs-11.0.0-rc.2` 的 `-r2` feed 即可
  （缓存里已恢复过坏 `.112` 包的机器先删
  `~/.nuget/packages/microsoft.netcore.app.runtime.nativeaot.openharmony-arm64/11.0.0-rc.2.26451.112`）。
- **payload 探针 bundleCodeDir**：壳 `findLibsPayloadDir` 在本机镜像仍探测不到 libs 内 AOT payload（bundleCodeDir 形态无 module 段）；启动已由宿主 libs 解析覆盖，探针优化待后续。
