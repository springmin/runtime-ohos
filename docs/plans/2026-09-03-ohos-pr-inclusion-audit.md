# OHOS Upstream PR — File Inclusion Audit (2026-09-03)

**Repo:** runtime-ohos / sdk-ohos / aspnetcore-ohos (feature branches)
**Purpose:** Record which feature-branch files must **NOT** go into upstream PRs
(before assembling each PR, re-verify against this list — it will drift as the
upstream main advances).
**Method:** per-file diff vs upstream main, ohos-keyword scan, git provenance
(commit that introduced the file), and on-disk nature (binary/script/deploy).

---

## A. Runtime (`feature/ohos-cross-runtime` vs dotnet/runtime main)

Baseline: 42 files differ; after excluding the below, **21 real ohos files**
remain (all contain ohos/openharmony keywords — no strays found on 2026-09-03).

### Exclude from all PRs

| File | Why | Re-check when |
|---|---|---|
| `AGENTS.md` + `src/libraries/AGENTS.md` + `src/mono/AGENTS.md` + `src/tests/AGENTS.md` + `src/tools/AGENTS.md` | Local project knowledge base, commit `3c1d169f381` (2026-08-24); **upstream main has no root AGENTS.md** (dotnet/runtime uses `.github/` instructions) | never upstream |
| `build-local-linux.sh` | Local Linux build helper, same commit `3c1d169f381`; no ohos logic | never upstream |

Note: after the 2026-09-03 upstream sync, upstream added area `AGENTS.md`
files under `src/` on main — those are upstream content pulled in by the
merge and disappear on rebase; do not include.

## B. SDK (`feature/ohos-cross-sdk` vs dotnet/sdk main)

Baseline: 31 files differ; real upstream candidates ≈ **14**.

### Exclude from all PRs

| Path | Why | Re-check when |
|---|---|---|
| `installonohos/` (README×2, 安装/运行记录 md×2, `install-dotnet-runtime.sh`, `dotnet-ohos`, `numa-shim.c/.S`, **`libnuma-shim.so`** binary) | Device-side deployment artifacts: install scripts + shim + **committed binary** — never upstream | never upstream |
| `documentation/ohos-install/` (`README.md`, `selfsign.cs`, `selfsign.csproj`, `install-dotnet-ohos.sh`, `sign-ohos-release.sh`, `Directory.Build.props/.targets`, `.gitignore`) | Host-side signing/install tooling + docs. **Codesign is HarmonyOS-commercial-only enforcement; OpenHarmony ignores it** (see plan §8). Lean: keep downstream unless a reviewer asks for the signer upstream | reviewer call on OpenHarmonyCodesign |
| root `AGENTS.md` | upstream merge (took upstream version, diff=0) | rebase |
| `eng/RuntimeIdentifierGraph.ohos.json`, `eng/PortableRuntimeIdentifierGraph.ohos.json` | Local build-injection override graphs. Upstream SDK derives its RID graph from the Platforms package (runtime.json now carries independent ohos) — the override may be **unnecessary upstream**; needed only while local bootstrap SDK lags | re-check when Platforms package with ohos lands upstream |

### Real ohos upstream candidates (SDK, subject to the codesign/override review)
`Directory.Build.props` (root), `src/Cli/dn/dn.csproj`,
`src/Cli/dotnet-aot/{AotSourceFiles.props,NativeEntryPoint.cs,dotnet-aot.csproj}`,
`src/Cli/dotnet/OpenHarmonyEnvironmentDefaults.cs`, `src/Cli/dotnet/Program.cs`,
`src/Layout/Directory.Build.props`, `src/Layout/redist/redist.csproj`,
`src/Layout/redist/targets/{Crossgen,GenerateBundledVersions,GenerateLayout}.targets`,
`src/Tasks/Microsoft.NET.Build.Tasks/OpenHarmonyCodesign.cs` (+ its
`Microsoft.NET.Sdk.targets` wiring), `test/dotnet-aot.Tests/dotnet-aot.Tests.csproj`.

## C. aspnetcore (`feature/ohos-cross-compile` vs dotnet/aspnetcore main)

Baseline: 12 files differ; real ohos candidates ≈ **4-5**.

### Exclude from all PRs

| Path | Why | Re-check when |
|---|---|---|
| `AGENTS.md`, `src/Shared/AGENTS.md` | upstream merge additions | rebase |
| `docs/plans/2026-08-18-ohos-cross-compile.md` | local plan doc | never upstream |
| `package-lock.json` | npm metadata drift (glibc libc entries) — not ohos | rebase / npm ci |
| `src/JSInterop/Microsoft.JSInterop.JS/src/package.json`, `src/SignalR/clients/ts/signalr/package.json`, `src/SignalR/clients/ts/signalr-protocol-msgpack/package.json` | **version-only noise** (`11.0.0-dev` → `11.0.0-rc.1.26451.1`) — not ohos; upstream dev→rc advance will cover | when upstream moves to rc |
| `src/Framework/App.Ref/src/CompatibilitySuppressions.xml`, `src/Framework/App.Runtime/src/CompatibilitySuppressions.xml` | **pure BOM-encoding noise** (no semantic change) | revert before any PR |

### Real ohos upstream candidates (aspnetcore)
`Directory.Build.props` (root, NativeAOT-for-ohos disable),
`eng/Dependencies.props` (ohos runtime-pack RIDs),
`src/Components/Testing/testassets/NativeAotTestApp/NativeAotTestApp.csproj`,
`src/Tools/Directory.Build.props`.

---

## Open review items (re-verify before each PR is assembled)

1. SDK `eng/*.ohos.json` override graphs — needed upstream, or only local
   bootstrap injection? (depends on Platforms package carrying ohos)
2. SDK `OpenHarmonyCodesign` + `selfsign.cs` — upstream or downstream?
   (HarmonyOS-commercial-only enforcement)
3. Runtime: P3 scope — does `tools/illink` `Microsoft.NET.ILLink.targets`
   belong with the NativeAOT PR or its own tools PR?
4. Any new upstream drift since 2026-09-03 sync (48/28/83 commits merged) that
   touches files on either side of this audit.

## Validation anchor

Device rounds 1-11 + §8 item 3 (NativeAOT publish E2E) exercise the real ohos
candidates; excluded files are not exercised by any upstream test and would
only add noise.
