# OpenHarmony platform workload — W3 status (2026-09-16)

W3 connects the native shell and the managed application: lifecycle events, host paths and
an ArkUI node-content channel now flow between them, and ELF signing follows the SDK's own
algorithm.

## Bridge architecture (reverse registration)
- The shell calls `libopenharmonyhost.so`'s `startApp(appDir, assembly, contextJson)`.
- The host initializes the runtime with `hostfxr_initialize_for_dotnet_command_line` and
  `hostfxr_run_app` **on the calling (main) thread**, publishing the context JSON through
  `OHOS_HOST_APP_CONTEXT`.
- `Microsoft.OpenHarmony.Hosting` attaches through a module initializer, reads the context
  and registers its callbacks by `DllImport("libopenharmonyhost.so")`
  (`ohos_host_register_bridge`). Events that arrive earlier are queued natively and flushed
  on registration; `Initialized`/`LifecycleChanged` are sticky for late subscribers.
- `notifyLifecycle(event)` / `setNodeContent(handle)` / `stopApp()` are exposed to ArkTS;
  the shell forwards ability `onDestroy`/`onForeground`/`onBackground`.

## Constraints discovered on device
- **CoreCLR must be initialized on the process main thread**: initializing it on a spawned
  thread crashes (SIGSEGV). The application model is therefore "Main returns quickly, the
  app keeps running on its own threads" (an app-started worker receives the lifecycle).
- `hdt_get_function_pointer` is not available for the command-line host path, and component
  hosting rejects self-contained components (0x80008093) — hence reverse registration.
- **ELF libraries must be signed**: `dlopen` of an unsigned `.so` fails with EPERM.
- `DateTime.Now` currently fails inside the app payload (TimeZoneInfo/globalization
  initialization); status files are deliberately timestamp-free.

## Signing (SDK-consistent)
ELF binaries/libraries are signed with the SDK's algorithm (`ElfSigner`, shared by the
`OpenHarmonyCodesign` MSBuild task, `dotnet selfsign` and the standalone `selfsign` tool) —
`scripts/selfsign.sh` prefers a `selfsign` binary, otherwise builds it from a `sdk-ohos`
checkout; `binary-sign-tool` self-sign signatures are mutually recognized. The `.hap`
package itself keeps using `hap-sign-tool` with the OpenHarmony test material
(profile + `sign-app`), matching the fork's existing packaging chain.

## Validated on device
- `test_host --bridge` + the app status file:
  `bridge attached: registered=True`, `lifecycle: Create/Foreground/Background/Destroy`,
  `node content set: 0x1234`, `managed exit code = 0`.
- `hello-app.hap` (18.8 MB) rebuilt with the lifecycle-aware ArkTS shell and the selfsigned
  host library; `verify-app` success. Installation/launch validation is still pending an
  install-eligible device path.

## Next (W4)
- ArkUI page with `ContentSlot` (native nodes attached from the managed side) — the page
  source is ready in `templates/`, but the ArkTS declarative syntax needs the ets-loader
  toolchain (or DevEco) rather than `es2abc`.
- Managed UI/rendering story (XComponent + Skia) for MAUI.
- MAUI wiring: `maui-openharmony` workload extending the platform workload.
