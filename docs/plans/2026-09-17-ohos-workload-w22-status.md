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

## Next (W22-2)

- Cursor position/selection mapping (`ITextInput.CursorPosition`/`SelectionLength`), ReturnKey
  type → `Completed`.
- More controls: `CheckBox`/`Switch`/`Slider`/`ProgressBar`/`ActivityIndicator`.
- `Shell`/`NavigationPage` navigation on top of the window handler.
- Device validation of the bridged path (install-eligible device).
