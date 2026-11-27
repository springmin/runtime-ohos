#ifndef PAL_LOCK_H
#define PAL_LOCK_H

// On OpenHarmony the OpenSSL build double-frees under parallel EVP/X509 use
// (musl jemalloc reports "may double free" and traps). The shim serializes
// those calls with a process-wide recursive mutex on that platform only;
// other platforms keep the existing lock-free behavior.
#if defined(TARGET_OPENHARMONY)

#ifdef __cplusplus
extern "C" {
#endif

void CryptoNative_Lock(void);
void CryptoNative_Unlock(void);

#ifdef __cplusplus
}
#endif

#else

#define CryptoNative_Lock() ((void)0)
#define CryptoNative_Unlock() ((void)0)

#endif

#endif
