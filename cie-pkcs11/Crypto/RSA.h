#pragma once

#ifdef WIN32
#include <bcrypt.h>
#else
#include <openssl/rsa.h>
#endif
#include "../PKCS11/wintypes.h"
#include "../Util/Array.h"

class CRSA
{
#ifdef WIN32
	BCRYPT_KEY_HANDLE key;
    void GenerateKey(DWORD size, ByteDynArray &module, ByteDynArray &pubexp, ByteDynArray &privexp);
#else
	RSA* keyPriv;
    DWORD GenerateKey(DWORD size, ByteDynArray &module, ByteDynArray &pubexp, ByteDynArray &privexp);
#endif

public:
	CRSA(ByteArray &mod, ByteArray &exp);
	~CRSA(void);

	ByteDynArray RSA_PURE(ByteArray &data, ByteDynArray& output);
	
	size_t KeySize;
};
