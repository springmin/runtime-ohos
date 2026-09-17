# OpenHarmony platform workload — W15 status (2026-09-17)

W15 adds the two hooks MAUI handlers need — input and a frame tick — plus a demo "view tree"
drawn through the Microsoft.Maui.Graphics backend.

## Input
- `OH_NativeXComponent_Callback.DispatchTouchEvent` reads the touch event
  (`OH_NativeXComponent_GetTouchEvent`, window-space coordinates via
  `OH_NativeXComponent_GetTouchPointWindowX/Y`) and forwards
  `(type, x, y, pointerCount, pointerId)` to the host core
  (`ohos_host_notify_touch`).
- `OH_NativeXComponent_RegisterMouseEventCallback` maps mouse press/release/move onto the
  same touch path, so 2in1/desktop input works.
- Managed: `OpenHarmonyBridge.Touch` (`OpenHarmonyTouchEventArgs` with
  `OpenHarmonyTouchAction`), registered from `Attach()` via `ohos_host_register_input`.

## Frame tick
- `OH_NativeXComponent_RegisterOnFrameCallback` forwards `(timestamp, targetTimestamp)` to
  the host core (`ohos_host_notify_frame`) and to `OpenHarmonyBridge.Frame`.
- The demo uses it as a minimal render loop: touch sets a dirty flag, the next frame redraws
  and presents.

## Handler-pattern demo
`hello-app` now draws an `ICanvas` UI (full-bleed rectangle, rounded "button", two strings),
highlights the button on touch-down and repaints on the frame tick, logging each frame to
its status file. This is the shape the real MAUI handlers take:
`LabelHandler` -> `DrawString`, `ButtonHandler` -> `FillRoundedRectangle` + `DrawString` +
hit testing, `LayoutHandler` -> measure/arrange driving the same backend calls.

Porting MAUI's actual handler types still needs the MAUI source tree and its platform build;
the platform-side contract they consume is now complete (lifecycle, surface, canvas, input,
frames).

## Verified
- Host library rebuilt with the input/frame symbols (present in the pack and the installed
  SDK); managed libraries and `hello-app` build clean; UI hap + `verify-app` succeeds with
  `OpenHarmonyUIPage=pages/Index`; lifecycle bridge regression passes (`registered=True`,
  managed exit 0).
- Workload `1.0.0-preview.7` published (versioned + rolling `workload-latest` + SDK release
  attachment).

## Next (W16)
- Wire MAUI's real handlers in the MAUI fork (needs its platform build), starting with
  Label/Button/Layout over this contract.
- `PatternPaint` (tile image shader) is the remaining ICanvas gap.
- Device validation of the rendered UI + touch (needs an install-eligible device).
