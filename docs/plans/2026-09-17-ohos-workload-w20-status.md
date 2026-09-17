# OpenHarmony platform workload — W20 status (2026-09-17)

W20 packages a **real MAUI application** as an installable OpenHarmony hap.

## `test/hello-maui-app` (workload repo)
- `App.cs` — a `Microsoft.Maui.Controls` application: `ContentPage` + `VerticalStackLayout`
  with two `Label`s and two `Button`s (counter + reset) wired through `Clicked`.
- `Program.cs` — bridge-mode entry: `MauiApp.CreateBuilder().UseOpenHarmony()`
  `.UseMauiApp<App>()`, then `OpenHarmonyMauiAppHost.Run(...)`; waits for the lifecycle.
- The platform slice's sources are compiled in with `-p:OpenHarmonyMauiPlatformDir=...`
  (default: `../maui-ohos/src/Core/src/Platform/OpenHarmony`), so the app runs the same code
  that will live in the MAUI fork.
- Publish: `dotnet publish -p:OpenHarmonyHapPackage=true -p:OpenHarmonyUIPage=pages/Index`
  produces a signed **`hello-maui-app.hap`** (20.3 MB, 242 payload files incl.
  `Microsoft.Maui.Controls.dll`) with `verify-app` success.

## Host behaviour verified headlessly
Bridge regression (`test_host --bridge`) with the published payload:
```
bridge attached: registered=True ...
[hello-maui-app] starting MAUI application
[maui] window created (Window), content=ContentPage
lifecycle: Create / Foreground ...        (window events best-effort for now)
managed exit code = 0
```
Window lifecycle events are logged and exception-guarded until a platform window handler
exists (MAUI's `IWindow.Activated` expects one); the app itself keeps running.

## Install for visual validation
`test/hello-maui-app/bin/Release/net11.0-openharmony26.0/openharmony-arm64/hello-maui-app.hap`
(or the simpler `hello-maui.hap` from the previous phase). Expected on device: dark-slate
canvas with "MAUI on OpenHarmony", the subtitle, a green **Count** button that increments on
tap (red while pressed), a **Reset** button and the status label.

## Next (W21)
- Device validation of the MAUI hap (install-eligible device) - the only step missing to see
  MAUI rendering on OpenHarmony.
- Platform window handler (`IWindowHandler`) so window lifecycle/navigation works fully;
  then more handlers (Entry/Image/ScrollView/Grid) and `Shell`/navigation.
