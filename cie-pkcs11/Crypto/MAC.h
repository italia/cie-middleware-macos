#pragma once
#ifdef WIN32
#include "..\stdafx.h"
#include <bcrypt.h>
#else
#include <openssl/des.h>
#endif
#include "../Util/util.h"
#include "../Util/UtilException.h"

class CMAC
{
#ifdef WIN32
	BCRYPT_KEY_HANDLE key1;
	BCRYPT_KEY_HANDLE key2;
	ByteDynArray iv;
    ByteDynArray Mac(const ByteArray &data);
#else
	des_key_schedule k1,k2,k3;
	des_cblock initVec;
    DWORD Mac(const ByteArray &data, ByteDynArray &resp);
#endif
public:
	CMAC();
	CMAC(const ByteArray &key, const ByteArray &iv);
	~CMAC(void);

	void Init(const ByteArray &key, const ByteArray &iv);
	
};
