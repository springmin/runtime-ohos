# OpenHarmony platform API — upstream proposal draft (2026-09-18)

Status: **draft for upstream review** (per the project rule that no new public API is
introduced without an approved proposal). Until approved, user-visible helpers stay in the
workload assembly (`Microsoft.OpenHarmony.dll`, `OpenHarmonyRuntime.IsOpenHarmony`).

## 1. `dotnet/runtime` — BCL platform value

### Proposal

```csharp
// System.Runtime.Versioning
namespace System.Runtime.Versioning;

public static class OSPlatform
{
    // existing ...
    // new:
    public static OSPlatform OpenHarmony { get; }
}

// System
public static class OperatingSystem
{
    // new:
    public static bool IsOpenHarmony() => IsOSPlatform(OSPlatform.OpenHarmony);
    public static bool IsOpenHarmonyVersionAtLeast(int major, int minor = 0, int build = 0,
                                                   int revision = 0);
}
```

Rationale: OpenHarmony is a distinct OS (like FreeBSD/Linux); apps and libraries need to
branch on it the same way they do for the existing values. It is *not* an Android platform.

### Patch sites (verified on the fork)

| File | Change |
|---|---|
| `src/libraries/System.Private.CoreLib/src/System/Runtime/Versioning/OSPlatform.cs` | add the static property (lazy, alongside `FreeBSD`/`Linux`) |
| `src/libraries/System.Private.CoreLib/src/System/OperatingSystem.cs` | add `IsOpenHarmony` (+ version overload if desired) |
| `src/libraries/System.Runtime/ref/System.Runtime.cs` | reference-assembly surface |
| `src/libraries/System.Runtime/tests/.../OSPlatformTests.cs` | unit tests for the new value/method |
| `src/libraries/System.Private.CoreLib/src/System/Runtime/InteropServices/RuntimeInformation.cs` | map the RID/OS description if reporting is desired |

Runtime detection: the platform is identified by the OS description/RID
(`openharmony-<arch>`); the current port already teaches the host/build logic about it, so the
interpreter can pass the same signal used for `RuntimeInformation.RuntimeIdentifier`.

### Compatibility

* Additive only; no existing behaviour changes.
* `OperatingSystem.IsOSPlatform("OPENHARMONY")` (string form) works without any change once
  the RID is `openharmony` (string matching is RID-driven).

## 2. `dotnet/maui` — `DevicePlatform` value

### Proposal

```csharp
namespace Microsoft.Maui.Devices;

public readonly struct DevicePlatform
{
    // existing values ...
    // new:
    public static DevicePlatform OpenHarmony { get; }
}
```

Patch sites (verified on the fork):

| File | Change |
|---|---|
| `src/Essentials/src/DeviceInfo/DevicePlatform.shared.cs` | add the static value + `ToString` mapping |
| `src/Essentials/src/DeviceInfo/DeviceInfo.shared.cs` | platform detection for the new value |
| `src/Essentials/src/Types/DevicePlatform.cs` (if split) | keep alphabetical order with the others |
| `src/Essentials/test/DeviceInformation/DeviceInfo_Tests.cs` | unit tests |

The platform slice already implements `IDeviceInfo` (`OpenHarmonyDeviceInfo`); it reports
`DevicePlatform.Unknown` today and can switch to the new value the moment it lands.

## 3. Workload-side shims (already shipping, no upstream dependency)

* `Microsoft.OpenHarmony.Hosting.OpenHarmonyRuntime.IsOpenHarmony` — the interim helper.
* `OpenHarmonyDeviceInfo` — reports `Unknown` until the MAUI value exists.
* Both are marked for replacement in the porting guide once the proposals are approved.

## 4. Tracking

1. File the runtime proposal (`api-proposal` skill format: motivation, API shape, usage
   examples, compatibility, drawbacks).
2. File the MAUI proposal for `DevicePlatform.OpenHarmony`.
3. After approval: replace the shims, delete the interim helper, and update the platform docs.
