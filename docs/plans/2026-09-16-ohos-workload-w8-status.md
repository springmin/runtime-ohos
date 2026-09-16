# OpenHarmony platform workload — W8 status (2026-09-16)

W8 brings the **official ArkTS toolchain** into the workload build, so a UI shell
(ability + ArkUI page) can be compiled without DevEco Studio.

## hvigor without DevEco
`ohos-workload/scripts/build-arkts-shell.sh` reproduces the whole path:

1. **hvigor from the Huawei npm mirror** (`https://repo.harmonyos.com/npm`):
   `@ohos/hvigor` + `@ohos/hvigor-ohos-plugin` (6.26.4) are downloaded with curl and
   unpacked (they ship their own `node_modules`).
2. **Version-nested SDK root**: hvigor rejects the plain OpenHarmony SDK layout; it wants
   `<sdkRoot>/<platformVersion>/<component>` (e.g. `26.0.0/ets`). The script builds that
   root with symlinks from `oh-uni-package.json` metadata.
3. **Minimal project** generated from the platform pack templates (UI ability variant +
   `pages/Index.ets` + resources) with the configs the schema requires:
   - `modelVersion: '6.0.0'` in **both** `hvigor-config.json5` and the project-level
     `oh-package.json5` (and they must match);
   - `compileSdkVersion`/`compatibleSdkVersion`/`targetSdkVersion` as **strings**
     (`'26.0.0'`) for API >= 26;
   - `deviceTypes: ['default']` for an OpenHarmony SDK;
   - `local.properties` with `sdk.dir` + `nodejs.dir` (or `OHOS_BASE_SDK_HOME`).
4. **Run hvigor**: `assembleHap -m module -p module=entry@default -p product=default
   -p buildMode=debug`; `CompileArkTS` produces
   `entry/build/default/intermediates/loader_out/default/ets/modules.abc`, which the
   script copies to `dist/ets/modules.abc`.

Gotchas found on the way:
- Driving hvigor from the device's **toybox sh** makes it abort with a V8 fatal
  (`Check failed: 12 == (*__errno_location())`) before any task; the script re-executes
  itself under `bash`.
- hvigor's own `PackageHap` needs java (installed `openjdk@17` via harmonybrew) and is not
  needed here: the workload packages the hap with `ohos_packing_tool`. The script therefore
  only requires `CompileArkTS` to have produced the abc.
- The real ArkTS compiler also fixed our page: `ContentSlot` has no size attributes, so the
  container must carry the layout.

## UI hap
```
scripts/build-arkts-shell.sh                         # -> dist/ets/modules.abc
dotnet publish -f net11.0-openharmony26.0 -r openharmony-arm64 \
  -p:OpenHarmonyHapPackage=true \
  -p:OpenHarmonyUIPage=pages/Index \
  -p:OpenHarmonyArktsModulesAbc=$PWD/dist/ets/modules.abc
```
Verified: the hap carries the ArkTS-compiled `modules.abc` (records for the ability and
`pages/Index`) and `main_pages.json = ["pages/Index"]`; `verify-app` succeeds.

## Next (W9)
- Attach an `XComponent` to the page and hand its surface to the managed side (the
  `OpenHarmonyBridge.NodeContent` hook is in place) — the rendering surface for MAUI.
- MAUI platform slice on top of the lifecycle bridge + surface.
