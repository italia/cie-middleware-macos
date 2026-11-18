
#include "MAC.h"
#include "../Cryptopp/hmac.h"


#ifdef WIN32

static char *szCompiledFile=__FILE__;

class init_mac {
public:
	BCRYPT_ALG_HANDLE algo;
	init_mac() {
		if (BCryptOpenAlgorithmProvider(&algo, BCRYPT_3DES_ALGORITHM, MS_PRIMITIVE_PROVIDER, 0) != 0)
			throw logged_error("Errore nell'inizializzazione dell'algoritmo MAC");
	}
	~init_mac() {
		BCryptCloseAlgorithmProvider(algo, 0);
	}
} algo_mac;

void CMAC::Init(const ByteArray &key, const ByteArray &iv)
{
	init_func
	size_t KeySize = key.size();
	ER_ASSERT((KeySize % 8) == 0, "Errore nella lunghezza della chiave MAC (non divisibile per 8)")
	ER_ASSERT(iv.size() == 8, "Errore nella lunghezza dell'Initial Vector")
	ER_ASSERT(KeySize >= 8 && KeySize <= 24, "Errore nella lunghezza della chiave MAC (<8 o >24)")
	ByteDynArray BCrytpKey;
	this->iv = iv;	
	switch (KeySize) {
	case 8:

		BCrytpKey.set(&key, &key, &key);
		break;
	case 16:
		BCrytpKey.set(&key, &key.left(8));
		break;
	case 24:
		BCrytpKey = key;
		break;
	}

	ByteDynArray k1;
	k1.set(&key.left(8), &key.left(8), &key.left(8));

	if (BCryptGenerateSymmetricKey(algo_mac.algo, &this->key1, nullptr, 0, k1.data(), (ULONG)k1.size(), 0) != 0)
		throw logged_error("Errore nella creazione della chiave MAC");

	if (BCryptGenerateSymmetricKey(algo_mac.algo, &this->key2, nullptr, 0, BCrytpKey.data(), (ULONG)BCrytpKey.size(), 0) != 0)
		throw logged_error("Errore nella creazione della chiave MAC");

	exit_func
}

CMAC::CMAC() : key1(nullptr), key2(nullptr) {
}

CMAC::~CMAC(void)
{
	if (key1!=nullptr)
		BCryptDestroyKey(key1);
	if (key2 != nullptr)
		BCryptDestroyKey(key2);
}

		
#else

void CMAC::Init(const ByteArray &key, const ByteArray &iv)
{
	init_func
	size_t KeySize = key.size();
	ER_ASSERT((KeySize % 8) == 0, "Errore nella lunghezza della chiave MAC (non divisibile per 8)")
	ER_ASSERT(iv.size() == 8, "Errore nella lunghezza dell'Initial Vector")

	ER_ASSERT(KeySize >= 8 && KeySize <= 24, "Errore nella lunghezza della chiave MAC (<8 o >24)")
    CryptoPP::memcpy_s(initVec, sizeof(DES_cblock), iv.data(), 8);

    // Copy the three key blocks before expanding the DES key schedules.
    const uint8_t* key1 = key.data();
    const uint8_t* key2 = (KeySize == 8) ? key.data() : key.data() + 8;
    const uint8_t* key3 = (KeySize == 24) ? key.data() + 16 : key.data();
    DES_cblock block1, block2, block3;
    CryptoPP::memcpy_s(block1, sizeof(block1), key1, 8);
    CryptoPP::memcpy_s(block2, sizeof(block2), key2, 8);
    CryptoPP::memcpy_s(block3, sizeof(block3), key3, 8);

    DES_set_key(&block1, &k1);
    DES_set_key(&block2, &k2);
    DES_set_key(&block3, &k3);

	exit_func
}

CMAC::~CMAC(void)
{
}

ByteDynArray CMAC::Mac(const ByteArray &data)
{
	init_func

    ByteDynArray resp(8);
    
	DES_cblock iv;
    CryptoPP::memcpy_s(iv, sizeof(DES_cblock), initVec, sizeof(initVec));

	size_t ANSILen = ANSIPadLen(data.size());
	if (data.size()>8) {
		ByteDynArray baOutTmp(ANSILen - 8);
		DES_ncbc_encrypt(data.data(), baOutTmp.data(), (long)ANSILen - 8, &k1, &iv, DES_ENCRYPT);
	}
	uint8_t dest[8];
	DES_ede3_cbc_encrypt(data.mid(ANSILen - 8).data(), dest, (long)(data.size() - ANSILen) + 8, &k1, &k2, &k3, &iv, DES_ENCRYPT);
	resp.copy(ByteArray(dest, 8));

    return resp;
    
	exit_func    
}

CMAC::CMAC() {
}
#endif


CMAC::CMAC(const ByteArray &key, const ByteArray &iv) {
	Init(key,iv);
}

