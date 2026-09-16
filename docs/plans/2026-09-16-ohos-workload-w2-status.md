# OpenHarmony platform workload — W2 status (2026-09-16)

W2 delivers the native runtime host, the ArkTS shell and the `publish -> .hap` pipeline for
the W1 workload (`~/springsources/ohos-workload`).

## Native host
`src/OpenHarmonyHost/`
- `openharmony_host.c` — loads `libhostfxr.so` from the published app directory and runs the
  application through `hostfxr_main_startupinfo` (the apphost contract). Falls back to
  component hosting (framework-dependent only) when the hosting bootstrap is present.
- `host_napi.cpp` — NAPI module (`libopenharmonyhost.so`) exposing
  `startApp(appDir, assemblyFile)` (detached thread) and `runApp` (synchronous).
- `test_host.c` — standalone smoke test, validated on device: the published self-contained
  app ran through the custom host with argument passing and exit code 0.

Hosting facts that cost time (documented for the record):
- `hostfxr_main_startupinfo` is `(argc, argv, host_path, dotnet_root, app_path)` — the
  parameter order is not the obvious one; a wrong order segfaults before any trace output.
- `hostfxr_initialize_for_runtime_config` rejects self-contained components (0x80008093);
  self-contained publishing must use the apphost-style entry point.
- Device sandbox exec policy: `binary-sign-tool ... -selfSign 1` produces the only runnable
  flavour of our own binaries (unsigned => EACCES, profile-signed => EPERM), and signed
  output files are immutable.

## ArkTS shell and packaging
- The shell (`templates/ets/entryability/EntryAbility.ets`) is compiled with `es2abc`
  directly: `--module --merge-abc --extension ts --record-name ets/entryability/EntryAbility`.
  `--record-name` matters: merged compilation otherwise names the record `modules`.
- `targets/OpenHarmony.Hap.targets` stages `module.json` (single-line template with tokens),
  `ets/modules.abc`, `resources/base/**`, `libs/<abi>/libopenharmonyhost.so` and
  `resources/rawfile/{app.json,dotnet.zip}` (the published .NET output zipped with
  `ZipDirectory`), then runs `ohos_packing_tool pack` and `templates/scripts/sign-hap.sh`
  (debug profile + `sign-app` + `verify-app`).
- Verified: `dotnet publish -f net11.0-openharmony26.0 -r openharmony-arm64
  -p:OpenHarmonyHapPackage=true` produces `hello-app.hap` (18.8 MB, 9 entries) and
  `verify-app` reports success.

## Open items (W3)
- Install/launch the hap on a device where `hdc install` is permitted (the current device is
  organization-restricted) to validate the ArkTS shell and the payload extraction path.
- NAPI argument passing, UI story (ArkUI native nodes for MAUI), API-version encoding in
  `module.json`, Windows signing path.
