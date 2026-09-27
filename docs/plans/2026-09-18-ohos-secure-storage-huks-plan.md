# SecureStorage on OpenHarmony — HUKS integration plan (2026-09-18)

## Current state (W22-14/15)

`Microsoft.Maui.Platform.OpenHarmonySecureStorage` stores values in
`<filesDir>/secure.dat`, obfuscated with a per-install XOR key kept in `secure.dat.key`.
This protects against casual reading of the file but is **not** hardware-backed and the key
lives next to the data. It is the documented fallback path.

## Target

Use the OpenHarmony Universal KeyStore (HUKS) so that

* the data-encryption key never leaves the keystore,
* values are encrypted with AES-256-GCM
  (HUKS `initSession`/`finishSession`, the NDK session API; the
  `huks.encryptData`/`decryptData` names once considered do not exist),
* the key is created with `generateKeyItem` (alias namespaced per store) and
  kept by HUKS itself.

## Architecture (three layers, same shape as the text-input bridge)

```
managed: OpenHarmonySecureStorage  (ISecureStorage)
   |  P/Invoke  ohos_host_keystore_*  (new exports)
host:    openharmony_host.c        (keeps a function-pointer table registered by NAPI)
   |  first: native HUKS engine (host_keystore.c, libhuks_ndk.z.so through host_optional.c)
   |  else:  callback
NAPI:    host_napi.cpp             (calls the ArkTS shell's registered sink)
   |  JS call
ArkTS:   Index.ets sink            (registered fallback; answers rc=-1 until the kit is wired)
```

The realized shape (P2a-HUKS, 2026-09-27) inserts the native engine between the host and the
sink: `ohos_host_keystore_request` answers **in-process** whenever the device ships
`libhuks_ndk.z.so`, so the hardware-backed path also works in a headless shell (no ArkTS page)
and on the default OpenHarmony flavor. Only a device without the library forwards the request
to the ArkTS shell sink; when neither answers, the managed side keeps the file fallback.

### New host exports (planned)

| Export | Purpose |
|---|---|
| `ohos_host_keystore_set_listener(void (*fn)(int requestId, const char* op, const char* alias, const char* dataBase64))` | managed -> ArkTS requests |
| `ohos_host_keystore_register_result(void* fn)` | ArkTS -> managed results (requestId, rc, dataBase64) |
| `ohos_host_keystore_generate(const char* alias)` | create the key (idempotent) |
| `ohos_host_keystore_encrypt(const char* alias, const char* plainBase64)` | AES-GCM encrypt |
| `ohos_host_keystore_decrypt(const char* alias, const char* cipherBase64)` | AES-GCM decrypt |

Managed side wraps these into a small async queue (request id -> `TaskCompletionSource`)
with a timeout; if no answer arrives (tests, headless, older hosts) the file fallback is used.

### Key material and permission model

HUKS keys are **app-scoped**: no entitlement and no `module.json5` permission are needed for
`generateKeyItem`/`initSession`/`finishSession`/`deleteKeyItem`. The SDK declaration
(`@ohos.security.huks.d.ts`, both the OpenHarmony SDK 26.0.0.18 and the HarmonyOS SDK) marks
only the attestation APIs (`exportKeyItem` for certificates, `anonAttestKeyItem`) with
`ohos.permission.ATTEST_KEY`; this plan uses none of them. The earlier
`ohos.permission.ACCESS_HUKS`-equivalent note was wrong and is dropped.

The value protocol stays `k1:<base64(nonce(12) || ciphertext || tag(16))>`; the alias is
namespaced per store (`maui.ohos.securestorage.v1.<FNV-1a(path)>`), replacing the shared
`dotnet.securestorage.1`, so two stores never share one key. `RemoveAll` also deletes the
keystore key (best effort).

## Migration

1. Ship the bridge exports (host + NAPI) and the ArkTS sink; keep the file format as a
   fallback when the keystore is unavailable (older devices, sandboxed test runs).
2. Values written before the upgrade stay in the fallback format and keep reading back; a
   value rewritten through `SetAsync` lands HUKS-sealed. Re-encrypting old values on first
   read is still open (tracked below).
3. Remove the XOR path only after the HUKS path has shipped for one release.

## Status (updated 2026-09-27, P2a-HUKS)

* [x] interface + fallback implementation (file, obfuscated), documented as not hardware-backed
* [x] host exports (`set_listener`/`register_result`/`request`/`complete`) + NAPI sink
  (`registerKeystoreSink`/`notifyKeystoreResult`) shipped in **preview.14**
* [x] managed client (`OpenHarmonyKeystore`) with id queue, timeouts, fail-fast unavailable flag;
  `SecureStorage` prefers the keystore (values written as `k1:<base64>`) and falls back cleanly
* [x] **native HUKS calls** (P2a-HUKS): `host_keystore.c` runs AES-256-GCM through the HUKS NDK
  (`generateKeyItem`, `initSession`/`finishSession` with `HUKS_TAG_NONCE`/`HUKS_TAG_AE_TAG`,
  `deleteKeyItem`), resolved on demand (`libhuks_ndk.z.so`, `OH_Huks_` in the build denylist).
  The ArkTS sink stays the registered fallback layer for an image without the library; no
  permission/entitlement is required.
* [x] managed hardening: namespaced alias, malformed-`k1:` reads as absent, `RemoveAll` drops
  the key, `IsHardwareBacked` reports the probe (`ohos_host_keystore_available`), plus the
  `PublicAPI` baseline entry
* [ ] migration of existing fallback data (re-encrypt on first read once the real path is on);
  old values keep reading back in the meantime
* [ ] full-app on-device pass: the engine was verified on the dev device with a signed
  aarch64 probe over the host sources (seal in one process -> decrypt in the next; rejected
  under a second alias; rejected after `delete`), but not yet through a packaged MAUI hap

The bridge is therefore complete and testable end to end, and the hardware-backed path is live
wherever the device ships the HUKS NDK library; the managed side still degrades by design.
Verified off-device by the interaction suite (`kit14`, 340 checks / floor 320; commit anchors:
`maui-ohos 99ac1818`, `ohos-workload 681bcb9` + `f333856`).
