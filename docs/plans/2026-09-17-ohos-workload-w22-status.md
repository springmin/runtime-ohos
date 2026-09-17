# OpenHarmony platform workload — W22 status (2026-09-17)

W22-1 makes `Entry` actually typable on OpenHarmony: the ArkTS shell owns a real `TextInput`
(soft keyboard) and its changes flow into MAUI's `Entry` through a three-layer bridge.
Device validation is assumed OK (per the previous phase); everything below is verified
headlessly plus the managed status-file path.

## Text input pipeline

```
ArkTS shell (TextInput.onChange)
  host.notifyTextInput(text)                    [NAPI]  ─┐
                                                         │ ohos_host_notify_text_input
host core: g_app->bridge_text_input ─────────────────────┘
  managed delegate -> OpenHarmonyBridge.TextInput event
    OpenHarmonyEntryHandler.OnTextInput (only when focused)
      Controls Entry.Text = text  -> TextChanged / Completed (MAUI itself)

managed Entry tap / IView.Focus() / Unfocus()
  OpenHarmonyBridge.RequestTextInput(show) -> ohos_host_request_text_input
    text-input listener -> ArkTS sink (registerTextInputSink) -> focusControl.requestFocus
```

- `registerTextInputSink(fn)` — the ArkTS page registers a callback that shows/hides its input;
  the NAPI layer keeps a `napi_ref` and invokes it from the host core's listener.
- `notifyTextInput(text)` — ArkTS pushes every change (and `onSubmit`) to the managed side.
- `OpenHarmonyBridge.TextInput` / `RequestTextInput(bool)` — managed API (the request is a
  no-op when there is no native host, so tests and tools stay safe).
- `OpenHarmonyEntryHandler` focuses through the platform `Focus` command (`Invoke` +
  `RetrievePlatformValueRequest<bool>`), asks for the keyboard, consumes text, and drops the
  keyboard on `Unfocus`.
- Focus round-trips into the virtual view via `VisualElement.IsFocusedPropertyKey`, so
  `IsFocused`, `Focused`/`Unfocused` and app-level `Unfocus()` work.

## Bug found and fixed: mangled host symbol (preview.9 → preview.10)

`ohos_host_register_text_input` was declared in `openharmony_host.h` **outside** the
`extern "C"` block, and `build-host.sh` compiles the `.c` file with `clang++`, so the export
became `_Z29ohos_host_register_text_inputPv`. Any app built against that library failed at
startup with `EntryPointNotFoundException` from `OpenHarmonyBridge.Attach()`. Fixes:

- declaration moved inside `extern "C"`; the export is now the plain C name;
- the text-input registration in `Attach()` is exception-guarded ("soft keyboard support is
  optional"): an older host library can no longer take an app down.

Packs/manifests bumped to **1.0.0-preview.10** and re-published (versioned release + rolling
`workload-latest` + attached to the SDK release), then re-installed into the device SDK
(`workload list = 1.0.0-preview.10`, `ohos_host_register_text_input` present).

## Verification (headless)

Real MAUI page (Controls `Grid`/`HorizontalStackLayout`/`Entry`/`Image`/`ScrollView`):

```
[verify] window handler=OpenHarmonyWindowHandler       (W21)
[verify] window Created() ok
[verify] entry tap handled(down=True, up=True) platformFocused=True virtualFocused=True
[verify] scroll drag handled(down=True, move1=True, move2=True) -> offsetY=70
[verify] entry text mapped='typed' (virtual='typed')
[verify] RequestTextInput(show/hide) ok (no native host -> no-op)
[verify] entry unfocus platformFocused=False
```

Managed status file with the real host library (one-shot fxr mode + `OHOS_HOST_APP_CONTEXT`):

```
bridge attached: registered=True bundle=com.example.hellomauiapp ability=EntryAbility filesDir=...
[hello-maui-app] starting MAUI application
[maui] window created (Window), content=ContentPage
```

No `text input registration skipped` line: the rebuilt host library exports the callback and
the managed side registers it.

Sandbox limitation: `test_host --bridge` (the `hostfxr_initialize_for_dotnet_command_line`
mode) segfaults right after `run_app entering` in this sandbox for both the old and the new
payload, so the bridged path (lifecycle/surface/touch) still needs a real device run; it is
not app- or slice-specific.

## Deliverables

- `test/hello-maui-app` gained an `Entry` (placeholder + `TextChanged`/`Completed` → status
  label) and a 12-row `ScrollView` so device validation covers W21+W22 together.
- `hello-maui-app.hap` — 20.3 MB, `verify-app success`, built against preview.10 with the new
  ArkTS shell (`modules.ui.abc`, 14 716 bytes, official hvigor toolchain).

## W22-2 value controls

Five handlers added, all drawn by the slice (no platform widgets needed):

| Handler | Interaction |
|---|---|
| `OpenHarmonyCheckBoxHandler` | tap toggles `ICheckBox.IsChecked` -> `CheckedChanged` |
| `OpenHarmonySwitchHandler` | tap toggles `ISwitch.IsOn` -> `Toggled`; track/thumb colours mapped |
| `OpenHarmonySliderHandler` | drag sets the value through the Controls `Slider` (`DragStarted`/`DragCompleted`, min/max track + thumb colours) |
| `OpenHarmonyProgressBarHandler` | track + progress fill |
| `OpenHarmonyActivityIndicatorHandler` | rotating arc; the host advances a shared angle on platform frames while `NeedsAnimation` is true |

Renderer: slider drag target (down/move/up), `HasAnimations(root)` driving the host frame loop,
and `Describe()` now reports `checked`/`on`/`slider`/`progress`/`running`.

Verification (headless, real Controls):

```
CheckBox frame=24,520,28x40 checked=False
Switch frame=64,520,51x40 on=False
Slider frame=127,520,220x40 slider=50/0-100
ProgressBar ... progress=0.25        ActivityIndicator ... running=True
[verify] checkbox CheckedChanged=True  -> checked=True (virtual=True)
[verify] switch Toggled=True           -> on=True (virtual=True)
[verify] slider DragCompleted value=100 -> virtual=100, platform=100
[verify] indicator running=True needsAnimation=True
```

The demo hap was rebuilt with the value-control row (checkbox/switch/slider/spinner +
progress bar) next to the entry and the scrollable list.

## W22-3 navigation

- `OpenHarmonyNavigationPageHandler` (`NavigationPage`): navigation bar (title from
  `CurrentPage.Title`, back chevron when the stack is deeper than one page) and MAUI's
  navigation pipeline (`INavigationPageController.PushRequested`/`PopRequested`/
  `PopToRootRequested` -> `IStackNavigation.NavigationFinished(...)`), refreshing the bar and
  requesting a redraw on `Pushed`/`Popped`.
- `OpenHarmonyPageHandler` (`Page`, matched for all page subclasses): pages draw nothing, but
  they must exist as handlers so MAUI arranges their content; the handler measures/arranges
  `IContentView.PresentedContent` at the page frame.
- `MauiOpenHarmonyExtensions.SliceHandlers`: explicit slice registry, because MAUI registers
  its own platform-partial handlers for the same types; the host resolves exact type ->
  interfaces -> base types.
- Renderer: touches are offered to every platform view (the navigation bar owns the back
  region), `ChildrenOf` yields a navigation page's current page, `Describe()` reports
  `nav='<title>' back=<bool>`.

Verification (headless, real Controls):

```
nav initial: NavigationPage frame=0,0,1080x1920 nav='' back=False
  ContentPage frame=0,48,1080x1872        (page content below the bar)
after push: NavigationPage ... nav='Page Two' back=True   stack=/Page Two
nav down handled=True canGoBack=True inBack=True pressed=True
back tap handled=True                    stack popped back to the root page
```

Fixed on the way: the touch walk only called `OnTouch` for views with a `Tap` callback, so
the navigation bar's back button never received its touch.

Known gap: `await PushAsync/PopAsync` does not complete on this slice yet - MAUI's stock
pipeline also waits for a platform `NavigationView` handler to report its own completion. The
navigation itself happens (stack, bar, rendered page); tracked for the navigation phase.

## Next (W22-4)

- Cursor position/selection mapping (`ITextInput.CursorPosition`/`SelectionLength`), ReturnKey
  type → `Completed`.
- More controls: `CheckBox`/`Switch`/`Slider`/`ProgressBar`/`ActivityIndicator`.
- `Shell`/`NavigationPage` navigation on top of the window handler.
- Device validation of the bridged path (install-eligible device).
