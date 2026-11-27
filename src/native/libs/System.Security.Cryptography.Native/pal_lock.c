#include "pal_lock.h"

#if defined(TARGET_OPENHARMONY)

#include <pthread.h>

static pthread_mutex_t g_cryptoLock;
static pthread_once_t g_cryptoLockOnce = PTHREAD_ONCE_INIT;

static void InitCryptoLock(void)
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&g_cryptoLock, &attr);
    pthread_mutexattr_destroy(&attr);
}

void CryptoNative_Lock(void)
{
    pthread_once(&g_cryptoLockOnce, InitCryptoLock);
    pthread_mutex_lock(&g_cryptoLock);
}

void CryptoNative_Unlock(void)
{
    pthread_mutex_unlock(&g_cryptoLock);
}

#endif
