#pragma once

#ifdef WIN32
#include <bcrypt.h>
#define AES_ENCRYPT 0
#define AES_DECRYPT 1
#define AES_BLOCK_SIZE 16

#else
#import <openssl/aes.h>
//#include <OpenSSL-Static/aes.h>
//#include "../Cryptopp/aes.h"
#endif
#include "../Util/util.h"
#include "../Util/UtilException.h"

#define AESKEY_LENGHT 32

class CAES
{
#ifdef WIN32
	BCRYPT_KEY_HANDLE key;
#else
	ByteDynArray key;
#endif

	ByteDynArray AES(const ByteArray &data, int encOp, ByteDynArray& output);
	ByteDynArray iv;

public:
	CAES();
	CAES(const ByteArray &key, const ByteArray &iv);
	~CAES(void);

	void Init(const ByteArray &key, const ByteArray &iv);
	ByteDynArray Encode(const ByteArray &data, ByteDynArray& output);
	ByteDynArray Decode(const ByteArray &data, ByteDynArray& output);
	ByteDynArray RawEncode(const ByteArray &data, ByteDynArray& output);
	ByteDynArray RawDecode(const ByteArray &data, ByteDynArray& output);
};
