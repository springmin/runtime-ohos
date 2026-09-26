#!/usr/bin/env bash
# ============================================================================
# ohos-runtime-clrinterpreter-overlay.sh
#
# Overlay `libclrinterpreter.so` (CoreCLR interpreter, built with
# `./build.sh ... -clrinterpreter`) into a shipped OpenHarmony runtime pack or
# an extracted runtime layout so the interpreter can be enabled with
# `DOTNET_InterpMode=3`. Local development aid: nothing is published and the
# stock pack in the NuGet cache is only touched when --install-cache is passed.
#
# Background: the interpreter is a separate native library loaded on demand by
# libcoreclr.so (`ExecutionManager::GetInterpreterName()` -> MAKEDLLNAME
# ("clrinterpreter"), overridable with DOTNET_InterpreterName). Runtime packs
# only contain it when built for Debug/Checked or with FeatureInterpreter=true
# (src/installer/pkg/sfx/Microsoft.NETCore.App/Directory.Build.props).
#
# IMPORTANT: overlaying the .so is necessary but NOT sufficient. The load path
# (InterpreterJitManager::LoadInterpreter, GetInterpreterName) and the
# DOTNET_InterpMode/DOTNET_Interpreter parsing live under `#ifdef
# FEATURE_INTERPRETER` in libcoreclr.so. The stock Release pack's libcoreclr.so
# is NOT interpreter-aware (no clrinterpreter/InterpMode/InterpreterName wide
# strings) -> it must be replaced by one built with `./build.sh ...
# -clrinterpreter` (scripts/ohos-runtime-clrinterpreter-build.sh) or come from a
# Debug/Checked build. This script checks the target coreclr and warns loudly
# when interpreter support is missing (it still stages the file safely).
#
# Usage:
#   ohos-runtime-clrinterpreter-overlay.sh <libclrinterpreter.so> --pack <runtime-pack.nupkg> [--install-cache]
#   ohos-runtime-clrinterpreter-overlay.sh <libclrinterpreter.so> --dir  <layout-dir>
#
# --pack:            adds runtimes/openharmony-arm64/native/libclrinterpreter.so
#                    to the nupkg (in place, .nupkg.orig kept once).
# --install-cache:   also re-extract the modified pack into
#                    ~/.nuget/packages/<id>/<ver>/ so the SDK consumes it.
# --dir:             copies the .so next to libcoreclr.so found under <dir>
#                    (searched recursively; also fills
#                    runtimes/openharmony-arm64/native when present).
#
# Device/app settings (set before coreclr starts; see the strategy doc):
#   DOTNET_InterpMode=3        full interpreter-only (implies DOTNET_ReadyToRun=0,
#                              DOTNET_EnableHWIntrinsic=0; tiered compilation off)
#   DOTNET_Interpreter=<set>   opt-in method set when InterpMode is 0/1
#   DOTNET_InterpreterName=<x> load lib<x>.so instead of libclrinterpreter.so
#   DOTNET_EnableWriteXorExecute=0   required on OpenHarmony for the JIT/stub
#                              paths that still allocate executable pages
#
# NOTE: libclrinterpreter.so has DT_NEEDED libc++_shared.so; make sure it is
# resolvable in the app linker namespace (system lib or bundled next to it).
# ============================================================================
set -euo pipefail

SOURCE_SO="${1:-}"
[ -n "$SOURCE_SO" ] && [ -f "$SOURCE_SO" ] || { echo "usage: $0 <libclrinterpreter.so> --pack <nupkg>|--dir <dir> [--install-cache]" >&2; exit 2; }
shift

MODE=""
TARGET=""
INSTALL_CACHE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --pack)          MODE=pack; TARGET="${2:-}"; shift 2 ;;
    --dir)           MODE=dir;  TARGET="${2:-}"; shift 2 ;;
    --install-cache) INSTALL_CACHE=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$MODE" ] && [ -n "$TARGET" ] || { echo "one of --pack/--dir is required" >&2; exit 2; }

RID="openharmony-arm64"
PACK_REL="runtimes/$RID/native/libclrinterpreter.so"

echo "== source =="
ls -l "$SOURCE_SO"
sha256sum "$SOURCE_SO"
file "$SOURCE_SO"

# 0 when libcoreclr.so was built with FEATURE_INTERPRETER=1. Wide strings on
# Unix are UTF-32LE (wchar_t), Windows uses UTF-16LE; check both.
coreclr_has_interpreter() {
  python3 - "$1" <<'PYEOF'
import sys
data = open(sys.argv[1], "rb").read()
hits = [w for w in ("clrinterpreter", "InterpMode", "InterpreterName")
        if w.encode("utf-32-le") in data or w.encode("utf-16-le") in data]
if hits:
    print("coreclr interpreter support: YES (" + ", ".join(hits) + ")")
    sys.exit(0)
print("coreclr interpreter support: NO (no clrinterpreter/InterpMode/InterpreterName string)")
sys.exit(1)
PYEOF
}
WARN_NOCORECLR=0

if [ "$MODE" = "pack" ]; then
  [ -f "$TARGET" ] || { echo "not a file: $TARGET" >&2; exit 1; }
  case "$TARGET" in *.nupkg) ;; *) echo "warning: $TARGET does not end in .nupkg" >&2 ;; esac
  [ -f "$TARGET.orig" ] || cp -p "$TARGET" "$TARGET.orig"
  python3 - "$SOURCE_SO" "$TARGET" "$PACK_REL" <<'PYEOF'
import sys, zipfile, shutil, os
so, pack, rel = sys.argv[1], sys.argv[2], sys.argv[3]
tmp = pack + ".tmp"
with zipfile.ZipFile(pack) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
    replaced = False
    for item in zin.infolist():
        data = zin.read(item.filename)
        if item.filename == rel:
            replaced = True
            with open(so, "rb") as fh:
                data = fh.read()
        zout.writestr(item, data)
    if not replaced:
        with open(so, "rb") as fh:
            zout.writestr(rel, fh.read(), compress_type=zipfile.ZIP_DEFLATED)
shutil.move(tmp, pack)
print(("replaced " if replaced else "added    ") + rel)
PYEOF
  echo "== pack updated: $TARGET (original: $TARGET.orig) =="

  CORECLR_REL="runtimes/$RID/native/libcoreclr.so"
  TMP_SO="$(mktemp)"
  EXTRACT_RC=0
  python3 - "$TARGET" "$TMP_SO" "$CORECLR_REL" <<'PYEOF' || EXTRACT_RC=$?
import sys, zipfile
pack, out, rel = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with zipfile.ZipFile(pack) as z:
        data = z.read(rel)
except KeyError:
    sys.exit(3)
open(out, "wb").write(data)
PYEOF
  if [ "$EXTRACT_RC" = "0" ]; then
    coreclr_has_interpreter "$TMP_SO" || WARN_NOCORECLR=1
  elif [ "$EXTRACT_RC" = "3" ]; then
    echo "note: pack has no $CORECLR_REL; cannot verify interpreter support" >&2
  else
    echo "warning: could not inspect $TARGET (python3 exit $EXTRACT_RC)" >&2
  fi
  rm -f "$TMP_SO"

  if [ "$INSTALL_CACHE" = "1" ]; then
    python3 - "$TARGET" <<'PYEOF'
import sys, zipfile, os, hashlib, base64, json, glob, shutil
pack = sys.argv[1]
base = os.path.basename(pack)
# <id>.<ver>.nupkg ; id contains dots as well -> split on the last two dot segments
parts = base[:-len(".nupkg")].split(".")
ver = parts[-1]
if ver.isdigit() or ("-" in ver and ver[0].isdigit()):
    # version like 11.0.0-rc.1.26451.109 -> last two segments
    ver = ".".join(parts[-3:])
pkg_id = base[:-len(".nupkg")][: -(len(ver) + 1)]
dest = os.path.expanduser(f"~/.nuget/packages/{pkg_id.lower()}/{ver}")
os.makedirs(dest, exist_ok=True)
shutil.copyfile(pack, os.path.join(dest, base))
h = base64.b64encode(hashlib.sha512(open(pack, "rb").read()).digest()).decode()
open(os.path.join(dest, base + ".sha512"), "w").write(h)
open(os.path.join(dest, ".nupkg.metadata"), "w").write(json.dumps({"version": 2, "contentHash": h, "source": "local"}))
with zipfile.ZipFile(pack) as z:
    z.extractall(dest)
for n in glob.glob(os.path.join(dest, "*.nuspec")):
    shutil.copyfile(n, os.path.join(dest, pkg_id + ".nuspec"))
    break
print(f"installed into NuGet cache: {dest}")
PYEOF
  fi
else
  [ -d "$TARGET" ] || { echo "not a directory: $TARGET" >&2; exit 1; }
  mapfile -t coreclrs < <(find "$TARGET" -name libcoreclr.so -type f | sort)
  if [ "${#coreclrs[@]}" -eq 0 ]; then
    echo "no libcoreclr.so under $TARGET; copying to the root only" >&2
    cp -f "$SOURCE_SO" "$TARGET/libclrinterpreter.so"
  else
    for c in "${coreclrs[@]}"; do
      cp -f "$SOURCE_SO" "$(dirname "$c")/libclrinterpreter.so"
      echo "copied -> $(dirname "$c")/libclrinterpreter.so"
      coreclr_has_interpreter "$c" || WARN_NOCORECLR=1
    done
  fi
  if [ -d "$TARGET/runtimes/$RID/native" ]; then
    cp -f "$SOURCE_SO" "$TARGET/runtimes/$RID/native/libclrinterpreter.so"
    echo "copied -> $TARGET/runtimes/$RID/native/libclrinterpreter.so"
  fi
fi

if [ "$WARN_NOCORECLR" = "1" ]; then
  cat >&2 <<'EOW'

WARNING: the target libcoreclr.so was NOT built with FEATURE_INTERPRETER.
  libclrinterpreter.so was staged anyway, but the runtime will not load it:
  InterpreterJitManager::LoadInterpreter (codeman.cpp) and the
  DOTNET_InterpMode/DOTNET_Interpreter parsing (eeconfig.cpp) are compiled out.
  Replace libcoreclr.so with one built via `./build.sh ... -clrinterpreter`
  (see scripts/ohos-runtime-clrinterpreter-build.sh) or use a Debug/Checked pack.
EOW
fi

echo "== done. enable with DOTNET_InterpMode=3 (see header) =="
