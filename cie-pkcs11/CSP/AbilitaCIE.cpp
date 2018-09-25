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
                        DWORD*      pcAttemptsRemaining);

extern "C" {
    CK_RV CK_ENTRY AbilitaCIE(const char*  szPAN, const char*  szPIN, PROGRESS_CALLBACK progressCallBack);
}

CK_RV CK_ENTRY AbilitaCIE(const char*  szPAN1e, const char*  szPIN, PROGRESS_CALLBACK progressCallBack)
{
//    init_p11_func
	
//    std::string container ("CIE-");
//    container += szPAN;

	try
    {
		CSHA256 sha256;
		std::map<uint8_t, ByteDynArray> hashSet;
		uint8_t* data;
		DWORD len = MAX_PATH;
		ByteDynArray CertCIE;
		ByteDynArray SOD;
		ByteDynArray IdServizi;
		
		SCARDCONTEXT hSC;

		long nRet = SCardEstablishContext(SCARD_SCOPE_USER, nullptr, nullptr, &hSC);
		char readers[MAX_PATH];
        
		if (SCardListReaders(hSC, nullptr, (char*)&readers, &len) != SCARD_S_SUCCESS) {
            return CKR_TOKEN_NOT_PRESENT;
		}

		char *curreader = readers;
		bool foundCIE = false;
		for (; curreader[0] != 0; curreader += strnlen(curreader, len) + 1)
        {
            safeConnection conn(hSC, curreader, SCARD_SHARE_SHARED);
            if (conn.hCard == NULL)
                continue;

//            safeTransaction checkTran(conn, SCARD_LEAVE_CARD);
//            if (!checkTran.isLocked())
//                continue;
            
            uint32_t atrLen = 40;
            char ATR[40];
            SCardGetAttrib(conn.hCard, SCARD_ATTR_ATR_STRING, (uint8_t*)ATR, &atrLen);
            
            ByteArray atrBa((BYTE*)ATR, atrLen);
            
            IAS ias((CToken::TokenTransmitCallback)TokenTransmitCallback, atrBa);
            ias.SetCardContext(&conn);
            
            foundCIE = true;
            
//            safeTransaction Tran(conn, SCARD_LEAVE_CARD);
//            if (!Tran.isLocked())
//                continue;
//
//            CCardLocker lockCard(cie->slot.hCard);
            
            ias.token.Reset();
            ias.SelectAID_IAS();
            ias.ReadPAN();
            
            ByteDynArray resp;
            ias.SelectAID_CIE();
            ias.ReadDappPubKey(resp);
            ias.InitEncKey();
            
            ias.SelectAID_IAS();
            ias.SelectAID_CIE();
            
            ByteDynArray IdServizi;
            ias.ReadIdServizi(IdServizi);
        
            ByteArray serviziData(IdServizi.left(12));
            ByteDynArray ba1;
            hashSet[0xa1] = sha256.Digest(serviziData, ba1);

            ByteDynArray SOD;
            ias.ReadSOD(SOD);
            
            ByteDynArray IntAuth;
            ias.ReadDappPubKey(IntAuth);
            ByteArray intAuthData(IntAuth.left(GetASN1DataLenght(IntAuth)));
            ByteDynArray ba2;
            hashSet[0xa4] = sha256.Digest(intAuthData, ba2);
            
			ByteDynArray IntAuthServizi;
            ias.ReadServiziPubKey(IntAuthServizi);
            ByteArray intAuthServiziData(IntAuthServizi.left(GetASN1DataLenght(IntAuthServizi)));
            ByteDynArray ba3;
			hashSet[0xa5] = sha256.Digest(intAuthServiziData, ba3);

            ias.SelectAID_IAS();
            ByteDynArray DH;
            ias.ReadDH(DH);
            ByteArray dhData(DH.left(GetASN1DataLenght(DH)));
            ByteDynArray ba4;
            hashSet[0x1b] = sha256.Digest(dhData, ba4);

//            if (IdServizi != ByteArray((uint8_t*)szPAN, strnlen(szPAN, 20)))
//                continue;

//                            //DWORD id;
//                            HWND progWin = nullptr;
//                            struct threadData th;
//                            th.progWin = &progWin;
//                            th.hDesk = (HDESK)(*desk);
//                            std::thread([&th]() -> DWORD {
//                                SetThreadDesktop(th.hDesk);
//                                CVerifica ver(th.progWin);
//                                ver.DoModal();
//                                return 0;
//                            }).detach();
//
//                            ias->Callback = [](int prog, char *desc, void *data) {
//                                HWND progWin = *(HWND*)data;
//                                if (progWin != nullptr)
//                                    SendMessage(progWin, WM_COMMAND, 100 + prog, (LPARAM)desc);
//                            };
//                            ias->CallbackData = &progWin;

            DWORD attempts = -1;

            DWORD rs = CardAuthenticateEx(&ias, ROLE_USER, FULL_PIN, (BYTE*)szPIN, (DWORD)strnlen(szPIN, sizeof(szPIN)), nullptr, 0, &attempts);
            if (rs == SCARD_W_WRONG_CHV)
            {
                return CKR_PIN_INCORRECT;
//                                if (progWin != nullptr)
//                                    SendMessage(progWin, WM_COMMAND, 100 + 7, (LPARAM)"");
//                                std::string num;
//                                if (attempts > 0)
//                                    num = "Sono rimasti " + std::to_string(attempts ) + " tentativi prima del blocco";
//                                else
//                                    num = "";
//                                CMessage msg(MB_OK,
//                                    "Abilitazione CIE",
//                                    "PIN Errato",
//                                    num.c_str());
//                                msg.DoModal();
            }
            else if (rs == SCARD_W_CHV_BLOCKED)
            {
                return CKR_PIN_LOCKED;
            }
            else if (rs != SCARD_S_SUCCESS)
            {
                return CKR_GENERAL_ERROR;//logged_error("Autenticazione fallita");
            }
            
//            ias.SelectAID_IAS();
//            ias.SelectAID_CIE();
            
            ByteDynArray Serial;
            ias.ReadSerialeCIE(Serial);
            ByteArray serialData = Serial.left(9);
            ByteDynArray ba6;
            hashSet[0xa2] = sha256.Digest(serialData, ba6);
            
            ByteDynArray CertCIE;
            ias.ReadCertCIE(CertCIE);
            ByteArray certCIEData = CertCIE.left(GetASN1DataLenght(CertCIE));
            ByteDynArray ba7;
            hashSet[0xa3] = sha256.Digest(certCIEData, ba7);
            
//            if (progWin != nullptr)
//                SendMessage(progWin, WM_COMMAND, 100 + 5, (LPARAM)"Verifica SOD");
            
            ias.VerificaSOD(SOD, hashSet);

//            if (progWin != nullptr)
//                SendMessage(progWin, WM_COMMAND, 100 + 6, (LPARAM)"Cifratura dati");
            ByteArray pinBa((uint8_t*)szPIN, 4);
//            ias.SetCache(szPAN, CertCIE, pinBa);
            ias.SetCache((char*)IdServizi.data(), CertCIE, pinBa);
//            if (progWin != nullptr)
//                SendMessage(progWin, WM_COMMAND, 100 + 7, (LPARAM)"");

//                Tran.unlock();
//
//                CMessage msg(MB_OK,
//                    "Abilitazione CIE",
//                    "La CIE è abilitata all'uso");
//                msg.DoModal();
//                        }
//                        catch (std::exception &ex) {
//                            std::string dump;
//                            OutputDebugString(ex.what());
//                            CMessage msg(MB_OK,
//                                "Abilitazione CIE",
//                                "Si è verificato un errore nella verifica di",
//                                "autenticità del documento");
//
//                            msg.DoModal();
//                            break;
//                        }
//                    }
//                    break;
//                }
//            }
		}
        
		if (!foundCIE) {
//            if (!desk)
//                desk.reset(new safeDesktop("AbilitaCIE"));
//            std::string num(PAN);
//            num+=" nei lettori di smart card";
//            CMessage msg(MB_OK,
//                "Abilitazione CIE",
//                "Impossibile trovare la CIE con Numero Identificativo",
//                num.c_str());
//            msg.DoModal();
		}
//        SCardFreeMemory(hSC, readers);
	}
	catch (std::exception &ex) {
		OutputDebugString(ex.what());
//        MessageBox(nullptr, "Si è verificato un errore nella verifica di autenticità del documento", "CIE", MB_OK);
	}

    return SCARD_S_SUCCESS;
//    exit_p11_func
//    return SCARD_E_UNEXPECTED;
}



DWORD CardAuthenticateEx(IAS*       ias,
                         DWORD       PinId,
                         DWORD       dwFlags,
                         BYTE*       pbPinData,
                         DWORD       cbPinData,
                         BYTE*       *ppbSessionPin,
                         DWORD*      pcbSessionPin,
                         DWORD*      pcAttemptsRemaining) {
    
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
