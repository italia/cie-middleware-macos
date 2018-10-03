#include "IAS.h"
#include "../PKCS11/wintypes.h"
#include "../PKCS11/PKCS11Functions.h"
#include "../PKCS11/Slot.h"
//#include "CSP.h"
#include "../Util/ModuleInfo.h"
#include "../Crypto/sha256.h"
#include <functional>
#include "../Crypto/ASNParser.h"
#include "../PCSC/PCSC.h"
#include <string>
#include "AbilitaCIE.h"
#include <string>
#include "../Cryptopp/misc.h"

#define ROLE_USER 1
#define ROLE_ADMIN 2

extern CModuleInfo moduleInfo;


#define SCARD_ATTR_VALUE(Class, Tag) ((((uint32_t)(Class)) << 16) | ((uint32_t)(Tag)))
#define SCARD_CLASS_ICC_STATE       9   /**< ICC State specific definitions */
#define SCARD_ATTR_ATR_STRING SCARD_ATTR_VALUE(SCARD_CLASS_ICC_STATE, 0x0303) /**< Answer to reset (ATR) string. */

int TokenTransmitCallback(safeConnection *data, uint8_t *apdu, DWORD apduSize, uint8_t *resp, DWORD *respSize);

DWORD CardAuthenticateEx(IAS*       ias,
                        DWORD       PinId,
                        DWORD       dwFlags,
                        BYTE*       pbPinData,
                        DWORD       cbPinData,
                        BYTE*       *ppbSessionPin,
                        DWORD*      pcbSessionPin,
                        int*        pcAttemptsRemaining);

extern "C" {
    CK_RV CK_ENTRY AbilitaCIE(const char*  szPAN, const char*  szPIN, int* attempts, PROGRESS_CALLBACK progressCallBack);
}

CK_RV CK_ENTRY AbilitaCIE(const char*  szPAN, const char*  szPIN, int* attempts, PROGRESS_CALLBACK progressCallBack)
{
	try
    {
		CSHA256 sha256;
		std::map<uint8_t, ByteDynArray> hashSet;
		
		DWORD len = MAX_PATH;
		ByteDynArray CertCIE;
		ByteDynArray SOD;
		ByteDynArray IdServizi;
		
		SCARDCONTEXT hSC;

        progressCallBack(1, "Connessione alla CIE");
        
		long nRet = SCardEstablishContext(SCARD_SCOPE_USER, nullptr, nullptr, &hSC);
        if(nRet != SCARD_S_SUCCESS)
            return CKR_DEVICE_ERROR;
        
		char readers[MAX_PATH];
        
		if (SCardListReaders(hSC, nullptr, (char*)&readers, &len) != SCARD_S_SUCCESS) {
            return CKR_TOKEN_NOT_PRESENT;
		}

        progressCallBack(5, "Connessione all CIE eseguita");
        
		char *curreader = readers;
		bool foundCIE = false;
		for (; curreader[0] != 0; curreader += strnlen(curreader, len) + 1)
        {
            safeConnection conn(hSC, curreader, SCARD_SHARE_SHARED);
            if (conn.hCard == NULL)
                continue;

            uint32_t atrLen = 40;
            char ATR[40];
            SCardGetAttrib(conn.hCard, SCARD_ATTR_ATR_STRING, (uint8_t*)ATR, &atrLen);
            
            ByteArray atrBa((BYTE*)ATR, atrLen);
            
            IAS ias((CToken::TokenTransmitCallback)TokenTransmitCallback, atrBa);
            ias.SetCardContext(&conn);
            
            foundCIE = false;
            
            ias.token.Reset();
            ias.SelectAID_IAS();
            ias.ReadPAN();
        
            progressCallBack(10, "Lettura dati dalla CIE");
            
            ByteDynArray resp;
            ias.SelectAID_CIE();
            ias.ReadDappPubKey(resp);
            ias.InitEncKey();
            
            ias.SelectAID_IAS();
            ias.SelectAID_CIE();
            
            ByteDynArray IdServizi;
            ias.ReadIdServizi(IdServizi);
        
            ByteArray serviziData(IdServizi.left(12));
            
            hashSet[0xa1] = sha256.Digest(serviziData);

            ByteDynArray SOD;
            ias.ReadSOD(SOD);
            
            ByteDynArray IntAuth;
            ias.ReadDappPubKey(IntAuth);
            ByteArray intAuthData(IntAuth.left(GetASN1DataLenght(IntAuth)));
            
            hashSet[0xa4] = sha256.Digest(intAuthData);
            
			ByteDynArray IntAuthServizi;
            ias.ReadServiziPubKey(IntAuthServizi);
            ByteArray intAuthServiziData(IntAuthServizi.left(GetASN1DataLenght(IntAuthServizi)));
            
			hashSet[0xa5] = sha256.Digest(intAuthServiziData);

            ias.SelectAID_IAS();
            ByteDynArray DH;
            ias.ReadDH(DH);
            ByteArray dhData(DH.left(GetASN1DataLenght(DH)));
            
            hashSet[0x1b] = sha256.Digest(dhData);

            if (szPAN && IdServizi != ByteArray((uint8_t*)szPAN, strnlen(szPAN, 20)))
                continue;

            foundCIE = true;
            
            progressCallBack(20, "Authenticazione...");
            
            DWORD rs = CardAuthenticateEx(&ias, ROLE_USER, FULL_PIN, (BYTE*)szPIN, (DWORD)strnlen(szPIN, sizeof(szPIN)), nullptr, 0, attempts);
            if (rs == SCARD_W_WRONG_CHV)
            {
                return CKR_PIN_INCORRECT;
            }
            else if (rs == SCARD_W_CHV_BLOCKED)
            {
                return CKR_PIN_LOCKED;
            }
            else if (rs != SCARD_S_SUCCESS)
            {
                return CKR_GENERAL_ERROR;
            }
            
            
            progressCallBack(45, "Lettura seriale");
            
            ByteDynArray Serial;
            ias.ReadSerialeCIE(Serial);
            ByteArray serialData = Serial.left(9);
            
            hashSet[0xa2] = sha256.Digest(serialData);
            
            progressCallBack(55, "Lettura certificato");
            
            ByteDynArray CertCIE;
            ias.ReadCertCIE(CertCIE);
            ByteArray certCIEData = CertCIE.left(GetASN1DataLenght(CertCIE));
            
            hashSet[0xa3] = sha256.Digest(certCIEData);
            
            ias.VerificaSOD(SOD, hashSet);

            ByteArray pinBa((uint8_t*)szPIN, 4);
            
            progressCallBack(5, "Nenorizzazione in cache");
            
            ias.SetCache((char*)IdServizi.data(), CertCIE, pinBa);
		}
        
		if (!foundCIE) {
            return CKR_TOKEN_NOT_RECOGNIZED;
            
		}

	}
	catch (std::exception &ex) {
		OutputDebugString(ex.what());
        
        return CKR_GENERAL_ERROR;
	}

    return SCARD_S_SUCCESS;
}



DWORD CardAuthenticateEx(IAS*       ias,
                         DWORD       PinId,
                         DWORD       dwFlags,
                         BYTE*       pbPinData,
                         DWORD       cbPinData,
                         BYTE*       *ppbSessionPin,
                         DWORD*      pcbSessionPin,
                         int*      pcAttemptsRemaining) {
    
    ias->SelectAID_IAS();
    ias->SelectAID_CIE();
    
    
    // leggo i parametri di dominio DH e della chiave di extauth
    if (ias->Callback != nullptr)
        ias->Callback(0, "Init", ias->CallbackData);
    
    ias->InitDHParam();
    
    ByteDynArray dappData;
    ias->ReadDappPubKey(dappData);
    
    ias->InitExtAuthKeyParam();
    
    // faccio lo scambio di chiavi DH
    if (ias->Callback != nullptr)
        ias->Callback(1, "DiffieHellman", ias->CallbackData);
    
    ias->DHKeyExchange();
    // DAPP
    if (ias->Callback != nullptr)
        ias->Callback(2, "DAPP", ias->CallbackData);
    
    ias->DAPP();
    
    // verifica PIN
    StatusWord sw;
    if (ias->Callback != nullptr)
        ias->Callback(3, "Verify PIN", ias->CallbackData);
    if (PinId == ROLE_USER) {
        
        ByteDynArray PIN;
        if ((dwFlags & FULL_PIN) != FULL_PIN)
            ias->GetFirstPIN(PIN);
        PIN.append(ByteArray(pbPinData, cbPinData));
        sw = ias->VerifyPIN(PIN);
    }
    else if (PinId == ROLE_ADMIN) {
        ByteArray pinBa(pbPinData, cbPinData);
        sw = ias->VerifyPUK(pinBa);
    }
    else
        return SCARD_E_INVALID_PARAMETER;
    
    if (sw == 0x6983) {
        if (PinId == ROLE_USER)
            ias->IconaSbloccoPIN();
        return SCARD_W_CHV_BLOCKED;
    }
    if (sw >= 0x63C0 && sw <= 0x63CF) {
        if (pcAttemptsRemaining!=nullptr)
            *pcAttemptsRemaining = sw - 0x63C0;
        return SCARD_W_WRONG_CHV;
    }
    if (sw == 0x6700) {
        return SCARD_W_WRONG_CHV;
    }
    if (sw == 0x6300)
        return SCARD_W_WRONG_CHV;
    if (sw != 0x9000) {
        throw scard_error(sw);
    }
    
    return SCARD_S_SUCCESS;
}

int TokenTransmitCallback(safeConnection *conn, BYTE *apdu, DWORD apduSize, BYTE *resp, DWORD *respSize) {
    if (apduSize == 2) {
        WORD code = *(WORD*)apdu;
        if (code == 0xfffd) {
            long bufLen = *respSize;
            *respSize = sizeof(conn->hCard)+2;
            CryptoPP::memcpy_s(resp, bufLen, &conn->hCard, sizeof(conn->hCard));
            resp[sizeof(&conn->hCard)] = 0;
            resp[sizeof(&conn->hCard) + 1] = 0;
            
            return SCARD_S_SUCCESS;
        }
        else if (code == 0xfffe) {
            DWORD protocol = 0;
            ODS("UNPOWER CARD");
            auto ris = SCardReconnect(conn->hCard, SCARD_SHARE_SHARED, SCARD_PROTOCOL_Tx, SCARD_UNPOWER_CARD, &protocol);
            
            
            if (ris == SCARD_S_SUCCESS) {
                SCardBeginTransaction(conn->hCard);
                *respSize = 2;
                resp[0] = 0x90;
                resp[1] = 0x00;
            }
            return ris;
        }
        else if (code == 0xffff) {
            DWORD protocol = 0;
            auto ris = SCardReconnect(conn->hCard, SCARD_SHARE_SHARED, SCARD_PROTOCOL_Tx, SCARD_RESET_CARD, &protocol);
            if (ris == SCARD_S_SUCCESS) {
                SCardBeginTransaction(conn->hCard);
                *respSize = 2;
                resp[0] = 0x90;
                resp[1] = 0x00;
            }
            ODS("RESET CARD");
            return ris;
        }
    }
    //ODS(String().printf("APDU: %s\n", dumpHexData(ByteArray(apdu, apduSize), String()).lock()).lock());
    auto ris = SCardTransmit(conn->hCard, SCARD_PCI_T1, apdu, apduSize, NULL, resp, respSize);
    if (ris != SCARD_S_SUCCESS) {
        ODS("Errore trasmissione APDU");
    }
    //else
    //ODS(String().printf("RESP: %s\n", dumpHexData(ByteArray(resp, *respSize), String()).lock()).lock());
    
    return ris;
}
