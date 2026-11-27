#ifndef PAL_LOCK_H
#define PAL_LOCK_H

#ifdef __cplusplus
extern "C" {
#endif

// Serializes the OpenSSL calls made by this shim.
//
// OpenHarmony's OpenSSL build double-frees under parallel EVP/X509 use
// (musl jemalloc reports "may double free" and traps). A process-wide
// recursive lock removes the concurrency while keeping the shim's public
// API unchanged. The lock is recursive because the shim's one-shot helpers
// call other locked helpers (for example EvpDigestOneShot calls
// EvpMdCtxCreate/Destroy).
void CryptoNative_Lock(void);
void CryptoNative_Unlock(void);

#ifdef __cplusplus
}
#endif

#endif
