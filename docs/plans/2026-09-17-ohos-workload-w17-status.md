# OpenHarmony platform workload — W17 status (2026-09-17)

W17 starts the MAUI line on both tracks requested: **A** (the platform slice in the MAUI
fork) and **B** (a device-verifiable MAUI-style demo app).

## B — `hello-maui` (workload repo, `test/hello-maui`)
A handler-shaped view model without the MAUI repo: `Element` with `Measure`/`Draw`/`HitTest`,
`Label`, `Button` (pressed state + `Clicked`), `VerticalStackLayout` (padding/spacing), all
rendered through the `Microsoft.Maui.Graphics` backend and driven by the platform contract
(lifecycle, XComponent surface, touch, frame ticks). `dotnet publish -p:OpenHarmonyHapPackage=true
-p:OpenHarmonyUIPage=pages/Index` produces a signed `hello-maui.hap` (19 MB, UI shell,
`verify-app` success); the bridge regression runs the app to `lifecycle Destroy` with exit 0.
This lets the handler pattern be validated on device before MAUI itself is wired.

## A — platform slice in the MAUI fork (`82…`/`81c8031`)
`src/Core/src/Platform/OpenHarmony/Microsoft.Maui.Platform.OpenHarmony.csproj` (net11.0,
references `Microsoft.Maui.Core`/`Microsoft.Maui.Graphics` 11.0.0-rc.1.26451.6 — the same
version as this runtime — plus the platform bridge):
- `OpenHarmonyDispatcher : IDispatcher` — queues work, drains on XComponent frame ticks with
  a safety-net timer; `CreateTimer()` returns a frame-driven `IDispatcherTimer`.
- `OpenHarmonyWindowSurface` — tracks `SurfaceChanged`, hands out `ICanvas` instances over the
  `OHNativeWindow*` and `Present()`.
- `MauiOpenHarmonyExtensions.UseOpenHarmony()` — registers both with `MauiAppBuilder`.
Verified to compile standalone against the official packages (10 KB assembly). The in-tree
build needs the repo's `eng/` files, which the sparse clone does not carry (the three needed
ones were fetched for the attempt and are locally excluded from git).

## Notes
- `Microsoft.Maui.Dispatching` is not a standalone package; the dispatcher interfaces live in
  `Microsoft.Maui.Core` (plain `net11.0` assets exist), which is what made A verifiable.
- MAUI package assets have no `openharmony` TFM, so MAUI's own build still needs the platform
  TFM to participate in its matrix (`IncludeOpenHarmonyTargetFrameworks` already does that).

## Next (W18)
- MAUI `WindowHandler` + first view handlers (Label/Button/Layout) in the fork over this
  slice; touch from `OpenHarmonyBridge.Touch`.
- Device validation: install `hello-maui.hap` (or the MAUI app) and check the rendered UI +
  touch (needs an install-eligible device).
