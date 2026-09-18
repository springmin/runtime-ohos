# SecureStorage on OpenHarmony — HUKS integration plan (2026-09-18)

## Current state (W22-14/15)

`Microsoft.Maui.Platform.OpenHarmonySecureStorage` stores values in
`<filesDir>/secure.dat`, obfuscated with a per-install XOR key kept in `secure.dat.key`.
This protects against casual reading of the file but is **not** hardware-backed and the key
lives next to the data. It is the documented fallback path.

## Target

Use the OpenHarmony Universal KeyStore (HUKS) so that

* the data-encryption key never leaves the keystore,
* values are encrypted with AES-GCM (HUKS `huks.encryptData`/`huks.decryptData`),
* the key is created with `huks.generateKeyItem` (alias e.g. `dotnet.securestorage.1`) and
  protected by the device credential policy chosen by the app.

## Architecture (three layers, same shape as the text-input bridge)

```
managed: OpenHarmonySecureStorage  (ISecureStorage)
   |  P/Invoke  ohos_host_keystore_*  (new exports)
host:    openharmony_host.c        (keeps a function-pointer table registered by NAPI)
   |  callback
NAPI:    host_napi.cpp             (calls the ArkTS shell's registered sink)
   |  JS call
ArkTS:   Index.ets sink            (await huks.generateKeyItem/encryptData/decryptData)
```

### New host exports (planned)

| Export | Purpose |
|---|---|
| `ohos_host_keystore_set_listener(void (*fn)(int requestId, const char* op, const char* alias, const char* dataBase64))` | managed -> ArkTS requests |
| `ohos_host_keystore_register_result(void* fn)` | ArkTS -> managed results (requestId, rc, dataBase64) |
| `ohos_host_keystore_generate(const char* alias)` | create the key (idempotent) |
| `ohos_host_keystore_encrypt(const char* alias, const char* plainBase64)` | AES-GCM encrypt |
| `ohos_host_keystore_decrypt(const char* alias, const char* cipherBase64)` | AES-GCM decrypt |

Managed side wraps these into a small async queue (request id -> `TaskCompletionSource`)
with a timeout; if no ArkTS sink is registered (tests, headless) the file fallback is used.

### ArkTS side (planned)

```ts
import huks from '@ohos.security.huks';

host.registerKeystoreSink(async (requestId: number, op: string, alias: string, data: string) => {
  // generateKeyItem / encryptData / decryptData with HuksTag.HUKS_TAG_ALGORITHM = AES,
  // HUKS_TAG_KEY_SIZE = 256, HUKS_TAG_BLOCK_MODE = GCM, HUKS_TAG_PADDING = NoPadding
  host.notifyKeystoreResult(requestId, rc, resultBase64);
});
```

The shell needs the `ohos.permission.ACCESS_HUKS`-equivalent entitlement; the demo hap's
`module.json` gains the permission when the bridge is implemented.

## Migration

1. Ship the bridge exports (host + NAPI) and the ArkTS sink; keep the file format as a
   fallback when the keystore is unavailable (older devices, sandboxed test runs).
2. On first read, if `secure.dat` exists in the fallback format, re-encrypt through HUKS and
   delete the fallback file.
3. Remove the XOR path only after the HUKS path has shipped for one release and the upstream
   review confirms the permission model.

## Status

* [x] interface + fallback implementation (file, obfuscated), documented as not hardware-backed
* [ ] host exports + NAPI sink
* [ ] ArkTS HUKS calls + permission in the template `module.json`
* [ ] migration of existing fallback data
