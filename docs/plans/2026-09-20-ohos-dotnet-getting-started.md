# .NET/MAUI on OpenHarmony — third-party developer getting-started guide

> Audience: an external developer who wants to install the OpenHarmony platform workload,
> build a .NET/MAUI application into a `.hap`, and get it onto a device.
> Everything below is based on this repository's real state (2026-09-20) and is written to be
> honest about what is and is not verified — see [Verification status](#1-verification-status).
>
> Chinese-language documents for the test/dev handover: the acceptance guide and the
> signing/UDID guide referenced in [section 7](#7-where-to-go-next) are `zh-CN`; this guide is
> the English entry point.

---

## 1. Verification status

| Area | State |
|---|---|
| Workload bundle (NuGet feed) | verified: manifest-to-feed check passes (`CLEAN INSTALL FEED OK`, 116 packs) |
| Platform TFM build/publish | verified: `net11.0-openharmony20.0` and `net11.0-openharmony26.0` restore, build and publish |
| `.hap` packaging | verified: publish emits a signed hap; `hap-sign-tool verify-app` passes on the produced haps |
| MAUI platform slice | verified **off-device** by the interaction harness (191 checks, 0 unhandled) and a pixel suite |
| ArkTS shells | verified at ArkTS compile/typecheck level (hvigor), not on a device |
| **Real-device install/run** | **not verified in the current environment**: `hdc` is blocked by an organization policy (`E00C001`), so the latest batches have no device run; treat on-device behaviour as unproven |
| BlazorWebView / HybridWebView | HybridWebView JS→.NET round trip works off-device; BlazorWebView is a work in progress (see the audit report) |

Anything a document claims as "device verified" refers to earlier phases where a device was
reachable; do not assume it for the newest packages.

---

## 2. What the workload is

The OpenHarmony platform workload is a **.NET platform workload** (same shape as
`dotnet workload install ios` / `android`): a manifest plus Sdk/Ref/Runtime packs that teach
the .NET SDK a new platform TFM and the OpenHarmony toolchain.

| Item | Value |
|---|---|
| Workload id | `openharmony` |
| Manifest | `microsoft.net.sdk.openharmony` (`WorkloadManifest.json`) |
| Workload version | `1.0.0-preview.24` (each pack can have its own version) |
| Platform TFMs | `net11.0-openharmony20.0`, `net11.0-openharmony26.0` |
| Runtime identifier | `openharmony-arm64` (arm64 only) |
| SDK band | `11.0.100-rc.1` (matches the .NET SDK that ships the packs) |
| Repos | `springmin/sdk-ohos` (SDK fork + releases), `ohos-workload` (workload repo: host/NAPI/shell/packs/scripts), `maui-ohos` (MAUI platform slice), `aspnetcore-ohos`, `runtime-ohos` (runtime + docs) |

The Sdk pack carries the pieces a published app needs:

- the native host `hosts/arm64-v8a/libopenharmonyhost.so` (self-signed with the SDK's ELF signer);
- the prebuilt ArkTS shells `templates/ets/modules.abc` (headless) and
  `templates/ets/modules.ui.abc` (ArkUI page with the rendering surface);
- the `publish → .hap` targets (`targets/OpenHarmony.Hap.targets`) and `hap-sign-tool` glue;
- the `Microsoft.OpenHarmony.Ref`/`Runtime` packs (thin bindings + CoreCLR runtime for
  `openharmony-arm64`).

---

## 3. Published artifacts (`springmin/sdk-ohos` releases)

All public deliverables live as GitHub **release assets** on `springmin/sdk-ohos`:

| Release tag | Kind | Assets | Use it for |
|---|---|---|---|
| `workload-latest` | rolling | `openharmony-workload-latest.tar.gz`, `SHA256SUMS`, plus `device-test-kit.tar.gz` and `device-test-kit.tar.gz.sha256` | newest workload + the test kit |
| `workload-1.0.0-preview.24` | immutable (one per workload version) | `openharmony-workload-1.0.0-preview.24.tar.gz`, `SHA256SUMS` | pinning a known-good version |
| `v11.0.100-rc.1.26451.109-openharmony` | SDK release | the forked .NET SDK tarball, plus the workload bundles attached at various times (newest there: `1.0.0-preview.24`, an earlier snapshot of it) | SDK + a pinned snapshot; for a fresh install prefer `workload-latest`, which carries the current refresh |
| `device-test-kit` | test delivery | `device-test-kit.tar.gz`, `device-test-kit.tar.gz.sha256` (also attached to `workload-latest`) | handing signed haps + acceptance docs to a tester |

Download examples:

```sh
base=https://github.com/springmin/sdk-ohos/releases/download
curl -L -o openharmony-workload-latest.tar.gz \
  "$base/workload-latest/openharmony-workload-latest.tar.gz"
curl -L -o device-test-kit.tar.gz \
  "$base/device-test-kit/device-test-kit.tar.gz"
# verify with the companion checksum file when one is provided:
sha256sum -c SHA256SUMS            # or: sha256sum -c device-test-kit.tar.gz.sha256
```

### 3a. A bundle is a NuGet feed, not a `packs/` directory

This is the most common misunderstanding: the published
`openharmony-workload-<version>.tar.gz` is **a NuGet feed of workload packs** — not the
`packs/<id>/<version>/…` layout that a *locally developed* workload uses (that layout is what
`scripts/prepare-packs.sh` creates in the workload repo).

```
openharmony-workload-1.0.0-preview.24/
├── manifests/microsoft.net.sdk.openharmony/   # WorkloadManifest.json + .targets
├── feed/*.nupkg                                # 116 packs, flat NuGet feed
├── install-ohos-workload.sh                    # installer wrapper (POSIX)
└── README.md
```

- Pack ids/versions come from `WorkloadManifest.json`; the feed files are
  `<PackId>.<PackVersion>.nupkg` and different packs do **not** share one version
  (e.g. `Microsoft.OpenHarmony.Sdk.1.0.0-preview.24.nupkg` next to the BCL runtime pack
  `Microsoft.NETCore.App.Runtime.openharmony-arm64.11.0.0-rc.1.26451.109.nupkg`).
- Feed integrity is checked by `ohos-workload/scripts/verify-clean-install.sh`, which walks the
  manifest and requires every declared pack in the extracted `feed/`, plus checks the Sdk pack
  for the host/shell/hap/signing assets. Current result: `CLEAN INSTALL FEED OK`.

### 3b. Building the test kit (one command)

The workload repo rebuilds the whole tester delivery — the 5 haps, the Chinese acceptance
docs, `SHA256SUMS` and the tarball — with a single script:

```sh
cd ohos-workload
sh scripts/build-arkts-shell.sh              # only when dist/ets/modules.abc is absent
sh scripts/make-device-test-kit.sh           # publish + assemble + pack
```

| Flag | Meaning |
|---|---|
| `--kit-dir <dir>` | kit directory (default `$DEVICE_TEST_KIT_DIR`, else `/data/storage/el2/base/tmp/opencode/device-test-kit`) |
| `--dist-dir <dir>` | directory holding `ets/modules.abc` (default `<repo>/dist`) |
| `--out <tar.gz>` | tarball path (default `<kit-dir>.tar.gz`) |
| `--skip-tar` | assemble the kit directory only, do not pack |
| `--publish` | also publish the tarball through `scripts/publish-workload-release.sh` |

The script publishes `test/hello-maui-app` for both API bands, with and without the 5 delivery
permissions (4 signed haps), keeps the unsigned 26.0 hap for tester self-signing, and reads
`module.json` back out of each permission hap to prove the `requestPermissions` list. It copies
`验收说明.md`, `快速开始.md`, `文档索引.md`, `签名与UDID指南.md`, `自签说明.md` and
`README-交付说明.md` from `runtime-ohos/docs/plans` (the two kit-only docs may instead come
from an existing kit directory), writes `SHA256SUMS` for every hap and doc (self-checked with
`sha256sum -c`), and packs the kit flat. Signing embeds a timestamp, so a rebuilt kit has
fresh hap hashes: `SHA256SUMS` is regenerated, never carried over.

---

## 4. Installing the workload

### 4.1 Prerequisites

- A .NET SDK **11.0.100-rc.1** feature band (the packs were built and validated against
  `11.0.100-rc.1.26451.109`; the band directory of the manifest must match the SDK).
  The forked SDK from the `v11.0.100-rc.1.26451.109-openharmony` release is the tested host;
  a stock SDK of the same band should work, the runtime comes from the workload packs.
- Install into the **dotnet root that owns the SDK**. The muxer resolves its real path, so a
  symlinked root will not see the workload (known limitation).
- The device side needs a HarmonyOS/OpenHarmony device (arm64) with developer mode and
  "allow debug/self-signed installs" enabled; `hdc` is convenient but may be blocked by policy
  (see troubleshooting).

### 4.2 From the bundle (recommended)

```sh
# 1. download + verify (see section 3), then:
tar xzf openharmony-workload-<version>.tar.gz
cd openharmony-workload-<version>

# 2. install: copies the manifest into <dotnet-root>/sdk-manifests/<band>/ and runs the
#    workload installer against the bundled feed
./install-ohos-workload.sh                 # uses `dotnet` from PATH
./install-ohos-workload.sh --dry-run       # show the plan first
./install-ohos-workload.sh --dotnet "$HOME/.dotnet/dotnet" .

# 3. verify
dotnet workload list                       # -> openharmony
```

The manual equivalent, when you want to do the steps yourself:

```sh
DOTNET_ROOT="$HOME/.dotnet"                # the root that owns the SDK
BAND=11.0.100-rc.1                         # must match the SDK feature band

cp -r manifests/microsoft.net.sdk.openharmony "$DOTNET_ROOT/sdk-manifests/$BAND/"
"$DOTNET_ROOT/dotnet" workload install openharmony \
  --skip-manifest-update --source "$PWD/feed"
"$DOTNET_ROOT/dotnet" workload list
```

Notes:

- `--source` points at the extracted **`feed/` directory** (a local NuGet directory feed);
  `--skip-manifest-update` keeps the installer from trying to refresh the manifest online.
- If you already copied the manifest into `sdk-manifests/`, the shorter form
  `dotnet workload install openharmony --source <feed dir>` works as well.
- Uninstall:
  ```sh
  dotnet workload uninstall openharmony
  rm -rf "$DOTNET_ROOT/sdk-manifests/$BAND/microsoft.net.sdk.openharmony"
  ```

---

## 5. Building an app

### 5.1 Pick the target framework

| TFM | API / platform | Built against | Hap API band (defaults) |
|---|---|---|---|
| `net11.0-openharmony20.0` | API 20 / platform 6.0.0 | CI public SDK | min = target = `60000020`, `apiReleaseType=Release` |
| `net11.0-openharmony26.0` | API 26 / platform 7.0.0 | device Beta SDK | min `60001021`, target `60101024`, `Beta1` |

A project can target both (they build into separate output folders); both are `arm64` and
publish with `-r openharmony-arm64`. Use the newer band for current devices and the API 20 band
for older/public-SDK deployments.

### 5.2 Publish a hap

From an app project (the demo app in this ecosystem lives in `ohos-workload/test/hello-maui-app`):

```sh
dotnet publish -c Release -r openharmony-arm64 -f net11.0-openharmony26.0 \
  -p:OpenHarmonyUIPage=pages/Index \
  -p:OpenHarmonyArktsModulesAbc=<path>/dist/ets/modules.abc \
  -p:OpenHarmonyHapPackage=true
```

| Property | Meaning |
|---|---|
| `OpenHarmonyHapPackage=true` | opt in to the hap staging/pack/sign targets; without it publish only produces the app payload |
| `OpenHarmonyUIPage=pages/Index` | page record written to `resources/base/profile/main_pages.json`; when `OpenHarmonyArktsModulesAbc` is not set this also selects the **prebuilt UI shell** (`templates/ets/modules.ui.abc`) |
| `OpenHarmonyArktsModulesAbc=<path>` | supply your own ArkTS shell archive (e.g. rebuilt with hvigor/DevEco, or the workload repo's `scripts/build-arkts-shell.sh`); without it the headless shell is used |
| `-r openharmony-arm64` | the only supported RID |
| `-f <TFM>` | needed when the project multi-targets; without `-f`, all TFMs are built |

Output (signed): `bin/Release/<tfm>/openharmony-arm64/*.hap`.
Install with the file manager on the device or `hdc install <hap>`.

---

## 6. Signing and device binding

### 6.1 Why a hap may be rejected: the debug profile is UDID-bound

The haps produced by the packaging targets are signed with the SDK **debug** profile template
(`toolchains/lib/UnsgnedDebugProfileTemplate.json`). The generated profile's
`debug-info.device-ids` lists the UDIDs that may install it. Installing on any other device
fails with:

```
failed to install bundle. code:9568344 error: install parse profile prop check error
```

Get the target device's UDID:

| Channel | Command / place | Note |
|---|---|---|
| hdc (if allowed) | `hdc shell bm get -u` | 64-hex-char UDID |
| DevEco Studio | Device Manager → device info | device must be connected |
| No debug channel | ask the device admin/IT, or have the tester self-sign | see the unsigned-hap path below |

Check a profile's device list before signing:

```sh
cd ohos-workload
sh scripts/sign-for-device.sh --show-profile-devices                # last profile-work/out.p7b
sh scripts/sign-for-device.sh --show-profile-devices <some.p7b>     # or an explicit profile
sh scripts/sign-for-device.sh --show-profile-devices --huawei <configDir>
```

It prints the profile's `bundle-name`, its `type` (`debug`/`release`) and one line per
`debug-info.device-ids` entry. Without a path it reads the last signed profile
(`profile-work/out.p7b` next to the unsigned hap) and warns when it falls back to the SDK
template's example UDIDs. A `release` profile has no `debug-info.device-ids`, and the command
reports that instead of a list.

Re-sign for a device with the workload repo script:

```sh
cd ohos-workload
sh scripts/sign-for-device.sh <UDID>                    # one device
sh scripts/sign-for-device.sh "<UDID1>,<UDID2>"         # several, comma separated
sh scripts/sign-for-device.sh <UDID> --out /tmp/app-<name>.hap --version 1.0.0-preview.24
```

The script copies the debug template, replaces the bundle name and `device-ids`, runs
`hap-sign-tool sign-profile` + `sign-app`, and prints the new SHA-256 (re-signing always
changes the hash). It warns when the hap's `module.json` bundle name does not match the
`--bundle` value (such a hap installs as `9568344`; pass `--bundle <name>` or rebuild with
`-p:OpenHarmonyBundleName=<name>`).

#### Sign with the tester's DevEco auto-signing material (`--huawei`)

When the tester can auto-sign in DevEco Studio (**Project Structure → Signing Configs →
Automatically generate signature**) but does not want to run `hap-sign-tool` themselves, they
send the Studio `config` directory (normally `~/Documents/ohos/config/`, including
`material/{fd,ac,ce}`); the hap is then signed offline with *their* certificate and profile:

```sh
sh scripts/sign-for-device.sh --huawei                          # default config dir
sh scripts/sign-for-device.sh --huawei <configDir> <encryptedPassword>
sh scripts/sign-for-device.sh --huawei <configDir> --unsigned <hap> --out <hap>
```

- `--huawei` delegates to `scripts/sign-huawei.sh`: it finds the tester's `*.p12` / `*.cer` /
  `*.p7b` under `configDir`, decrypts the Studio `00000020…` password locally through the
  hvigor plugin's own `DecipherUtil` (plaintext stays local, mode 600, reused on the next
  run), signs with `hap-sign-tool sign-app`, and prints the output path + SHA-256 **only after
  `hap-sign-tool verify-app` passes**.
- **Bundle-name check:** before signing it reads `app.bundleName` from `module.json` inside the
  hap and `bundle-info.bundle-name` from the p7b; on a mismatch it refuses with the exact
  rebuild command. Rebuild with `-p:OpenHarmonyBundleName=<profile bundle name>`, or pass
  `--unsigned` pointing at a hap whose `module.json` already matches.
- `--bundle` is rejected in `--huawei` mode (the identity comes from the rebuild) and
  `--version` is ignored (the SDK comes from `OHOS_SDK_ROOT`). The profile binds the tester's
  devices only: check with `--show-profile-devices --huawei <configDir>` first, and remember
  that adding a device requires the tester to regenerate the DevEco signature.

#### Tester self-sign path (unsigned hap)

Every test kit also ships `hello-maui-app-unsigned.hap` (same payload and bundle name as the
default 26.0 hap) plus the Chinese one-pager `自签说明.md`:
create any DevEco project with `bundleName = com.example.hello-maui-app`, enable
**Automatically generate signature**, sign the unsigned hap with `hap-sign-tool sign-app`
using the generated `*.p12`/`*.cer`/`*.p7b`, `verify-app` it and install. That path needs no
UDID exchange and no re-signing by us; the tester may instead send the `config` directory back
and we re-sign it with `--huawei` above. The unsigned hap's SHA-256 is in the kit's
`SHA256SUMS`.

Alternative self-service paths (DevEco auto-signing, release-type self-signing for
OpenHarmony-only devices) are documented in the signing guide
(`docs/plans/2026-09-19-ohos-signing-and-udid-guide.md`; kit copy `签名与UDID指南.md`, self-sign
step-by-step `自签说明.md`).

### 6.2 Opt-in permissions: `OpenHarmonyExtraPermissions`

The shared `module.json` template declares no extra runtime permissions. To inject a
`requestPermissions` list at packaging time:

```sh
dotnet publish -c Release -r openharmony-arm64 \
  -p:OpenHarmonyUIPage=pages/Index \
  -p:OpenHarmonyHapPackage=true \
  -p:'OpenHarmonyExtraPermissions="ohos.permission.ACCESS_BLUETOOTH;ohos.permission.PRINT;ohos.permission.READ_CONTACTS;ohos.permission.READ_CALENDAR;ohos.permission.WRITE_CALENDAR"'
```

**Quoting rule:** the whole `-p:` argument must be single-quoted (`-p:'Prop="a;b"'`). With
`-p:Prop="a;b"` the shell strips the inner quotes and the `;` starts a new argument, producing
`MSB1006: Property is not valid`. `,`/`;` both separate entries; empty items are dropped;
when the property is empty the generated `module.json` is byte-identical to the no-permission
variant.

### 6.3 API-band properties and the version decode rule

`module.json`'s `minAPIVersion`, `targetAPIVersion` and `apiReleaseType` come from three
overridable properties; their defaults follow the **target TFM**:

| Property | `net11.0-openharmony20.0` | `net11.0-openharmony26.0` |
|---|---|---|
| `OpenHarmonyMinApiVersion` | `60000020` | `60001021` |
| `OpenHarmonyTargetApiVersion` | `60000020` | `60101024` |
| `OpenHarmonyApiReleaseType` | `Release` | `Beta1` |

Values are not plain API numbers. The format is
`<major><minor:02><patch:02><api:03>` with leading zeros removed:

| Encoded | Decodes to |
|---|---|
| `60001021` | platform **6.0.1**, API **21** |
| `60101024` | platform **6.1.1**, API **24** |
| `60000020` | platform **6.0.0**, API **20** |

Override per build when your device band differs, e.g. for an API 20 device:

```sh
-p:OpenHarmonyMinApiVersion=60000020 -p:OpenHarmonyTargetApiVersion=60000020
```

Warning: an app whose `minAPIVersion` is higher than the device's API level is rejected with
`bm 9568297 ERR_APPEXECFWK_INSTALL_SDK_INCOMPATIBLE`. The per-TFM defaults above already
account for the API 20/26 split (the old hard-coded defaults declared min API 21 for the API 20
variant; that was fixed in the Q3 packaging work — see the audit report).

---

## 7. Troubleshooting (errors actually seen in this project)

| Exact error / symptom | Root cause | Fix |
|---|---|---|
| `failed to install bundle. code:9568344 error: install parse profile prop check error` | debug signing profile is bound to other devices' UDIDs | re-sign with the target UDID (`scripts/sign-for-device.sh <UDID>`), or have the tester auto-sign in DevEco; see §6.1 |
| `E00C001 Operation restricted by the organization` (from `hdc`) | device management policy disables hdc (`const.usb.port.user_hdc.disable=true`) | device admin must lift the policy; otherwise copy the hap to the device and install from the file manager, or self-sign on a machine with DevEco |
| `MSB1006: Property is not valid.` | unquoted `;`/spaces in an MSBuild property (most often `OpenHarmonyExtraPermissions`) | single-quote the whole switch: `-p:'OpenHarmonyExtraPermissions="a;b"'` |
| hvigor download 404 for `@ohos-hvigor-6.26.4.tgz` (only when rebuilding the ArkTS shell) | the registry URL is dead / not reachable | build against a local file mirror: `HVIGOR_MIRROR=file://<mirror> bash scripts/build-arkts-shell.sh`, with layout `@ohos/<pkg>/-/@ohos-<pkg>-6.26.4.tgz` |
| `NETSDK1083` (unrecognized RID / missing runtime) | the runtime pack's `*.deps.json` (or the SDK RID graph) still says `ohos-arm64` while the platform TFM uses `openharmony-arm64` | `prepare-packs.sh` rewrites `ohos-arm64` → `openharmony-arm64` in the runtime pack's `*.deps.json`; apply the same rewrite to hand-made installed copies |
| `bm 9568297 ERR_APPEXECFWK_INSTALL_SDK_INCOMPATIBLE` | `minAPIVersion` in `module.json` is above the device API level (the API 20 variant used to declare min 21) | set the correct band (§6.3); packages from preview.23 onward default per TFM |
| publish wrote `module.json`/`ets`/`resources`/`libs` into the project directory (**fixed**) | `_OpenHarmonyHapStageDir` was empty at evaluation time because `PublishDir` was not set yet, so staging paths collapsed to project-relative paths | fixed in preview.22/23: `_OpenHarmonyResolveHapStageDir` resolves at execution time, default `$(IntermediateOutputPath)openharmony-hap/`, and errors if it resolves to the project directory; use `OpenHarmonyHapStageDir` only for an explicit override |
| identical publishes produced different haps (`dotnet.zip` differed by 4–8 KB) (**fixed**) | the SDK's codesign target re-signed ELFs in the publish directory after the hap packaging had already picked files, and zip order/mtime varied | fixed in preview.22/23: `_OpenHarmonyResetHapPublishOutputs` rebuilds the publish payload from a single signed copy (one `.codesign` section per ELF) and `dotnet.zip` is written by `OpenHarmonyDeterministicZip` (ordinal sort, fixed `1980-01-01` timestamps); payload hash now stable across repeated publishes |

More older error-code mappings (workload wiring: `NETSDK1139/1147/1140/1083/1082/1067`, and the
signing error table) are in the workload status docs and the signing guide.

---

## 8. Where to go next

| Document (in `runtime-ohos/docs/plans/`) | Contents |
|---|---|
| `2026-09-19-ohos-hap-acceptance-for-testers.md` | device acceptance checklist (zh-CN), shipped in the test kit |
| `2026-09-19-ohos-signing-and-udid-guide.md` | 9568344 / UDID / re-signing / self-signing, incl. `--huawei` and `--show-profile-devices` (zh-CN) |
| `2026-09-21-ohos-tester-selfsign.md` | tester-side self-signing of the unsigned hap (zh-CN; kit name `自签说明.md`) |
| `2026-09-21-ohos-delivery-kit-readme.md` | test-kit contents, install options and the 9568344 pointer (zh-CN; kit name `README-交付说明.md`) |
| `2026-09-19-ohos-arkts-handover-status.md` | current project status, architecture, open recipes (hybrid, accessibility, hot reload) |
| `2026-09-19-ohos-code-audit.md` | five-repo audit: fixes, measurements, per-TFM API band, Blazor/hybrid and S/T-series results |
| `2026-09-18-ohos-device-validation-checklist.md` | step-by-step device validation with artifacts/commands/expected results (S/T-series items in §6) |
| `2026-09-16-ohos-platform-workload-plan.md` | how the workload is structured and where it is heading (W0–W5 plan) |

Workload internals and the off-device verification harness live in the `ohos-workload`
repository (`scripts/`, `packs/`, `test/maui-platform-verify`); the MAUI platform slice lives
in `maui-ohos` (`src/Core/src/Platform/OpenHarmony/`).
