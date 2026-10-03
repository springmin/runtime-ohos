# runtime-ohos helper scripts

Fork-only helpers (not part of upstream dotnet/runtime). Run them from the repository root.

| Script | Purpose |
| --- | --- |
| `ohos-csc-spin-repro.sh` | Reproduce the OHOS csc concurrent-compilation spin (frozen I/O counters, one spinning thread). |
| `ohos-runtime-clrinterpreter-build.sh` | Cross-build `libclrinterpreter.so` for openharmony-arm64 (`FEATURE_INTERPRETER=1`) without the full coreclr. |
| `ohos-runtime-clrinterpreter-overlay.sh` | Overlay an interpreter build into a runtime pack/layout so `DOTNET_InterpMode=3` can load it. |
| `ohos-runtime-interp-fullbuild.sh` | Full feature-enabled CoreCLR + libraries build, packed as the interpreter payload. |
| `ohos-conventions-scan.sh` | Scan the added lines of OHOS PR branches for fork-convention violations (`COMPlus_`, pragma/NoWarn, fork-local paths, tabs, TFMs, ...). |

Rescued scratch tools and the 2026-10-03 inventory live in
[`docs/plans/2026-10-03-ohos-scratch-script-rescue.md`](../docs/plans/2026-10-03-ohos-scratch-script-rescue.md).
