#pragma once

#ifdef WIN32
#include <bcrypt.h>
#define MD5_DIGEST_LENGTH 16
#else
#include "../Cryptopp/md5.h"
#endif

#include "../Util/util.h"
#include "../Util/UtilException.h"

class CMD5
{
#ifdef WIN32
	BCRYPT_HASH_HANDLE hash;
#else
	bool isInit;	
#endif
public:
	CMD5();
	~CMD5(void);

	ByteDynArray Digest(ByteArray data);

	void Init();
	void Update(ByteArray data);
	ByteDynArray Final();
};
