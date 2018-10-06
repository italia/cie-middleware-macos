//
//  PINManager.cpp
//  cie-pkcs11
//
//  Created by ugo chirico on 06/10/18.
//  Copyright © 2018 IPZS. All rights reserved.
//

#include "PINManager.h"
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

extern "C" {
    CK_RV CK_ENTRY CambioPIN(const char*  szCurrentPIN, const char*  szNuovoPIN, int* pAttempts, PROGRESS_CALLBACK progressCallBack);
    CK_RV CK_ENTRY SbloccaPIN(const char*  szPUK, const char*  szNuovoPIN, int* pAttempts, PROGRESS_CALLBACK progressCallBack);
}

int TokenTransmitCallback(safeConnection *data, uint8_t *apdu, DWORD apduSize, uint8_t *resp, DWORD *respSize);


CK_RV CK_ENTRY CambioPIN(const char*  szCurrentPIN, const char*  szNewPIN, int* pAttempts, PROGRESS_CALLBACK progressCallBack)
{
    try
    {
        DWORD len = MAX_PATH;
        
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
            if (!conn.hCard)
                continue;
            
            uint32_t atrLen = 40;
            char ATR[40];
            SCardGetAttrib(conn.hCard, SCARD_ATTR_ATR_STRING, (uint8_t*)ATR, &atrLen);
            
            ByteArray atrBa((BYTE*)ATR, atrLen);
            
            IAS ias((CToken::TokenTransmitCallback)TokenTransmitCallback, atrBa);
            ias.SetCardContext(&conn);
            ias.attemptsRemaining = -1;
            
            ias.token.Reset();
            ias.SelectAID_IAS();
            ias.ReadPAN();
            
            progressCallBack(10, "Lettura dati dalla CIE");
            
            ByteDynArray resp;
            ias.SelectAID_CIE();
            
            ias.InitEncKey();
            ias.ReadDappPubKey(resp);
            
            foundCIE = true;
            
            // leggo i parametri di dominio DH e della chiave di extauth
            ias.InitDHParam();
            
            ias.InitExtAuthKeyParam();
            
            progressCallBack(20, "Authenticazione...");
            
            ias.DHKeyExchange();
            
            // DAPP
            ias.DAPP();
            
            ByteArray oldPINBa((BYTE*)szCurrentPIN, strlen(szCurrentPIN));
            
            StatusWord sw = ias.VerifyPIN(oldPINBa);
            
            if (sw == 0x6983) {
                return SCARD_W_CHV_BLOCKED;
            }
            if (sw >= 0x63C0 && sw <= 0x63CF) {
                if (pAttempts!=nullptr)
                    *pAttempts = sw - 0x63C0;
                
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
            
            ByteDynArray cert;
            bool isEnrolled = ias.IsEnrolled();
            
            if(isEnrolled)
                ias.GetCertificate(cert);
            
            
            ByteArray newPINBa((BYTE*)szNewPIN, strlen(szNewPIN));
            
            sw = ias.ChangePIN(oldPINBa, newPINBa);
            if (sw != 0x9000) {
                throw scard_error(sw);
            }
            
            if(isEnrolled)
            {
                std::string strPAN;
                dumpHexData(ias.PAN.mid(5,6), strPAN, false);
                ByteArray leftPINBa = newPINBa.left(4);
                ias.SetCache(strPAN.c_str(), cert,     leftPINBa);
            }
        }
        
        if (!foundCIE) {
            return CKR_TOKEN_NOT_RECOGNIZED;
            
        }
    }
    catch(...)
    {
        return CKR_GENERAL_ERROR;
    }
    
    return CKR_OK;
}


CK_RV CK_ENTRY SbloccaPIN(const char*  szPUK, const char*  szNewPIN, int* pAttempts, PROGRESS_CALLBACK progressCallBack)
{
    try
    {
        DWORD len = MAX_PATH;
        
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
            if (!conn.hCard)
                continue;
            
            uint32_t atrLen = 40;
            char ATR[40];
            SCardGetAttrib(conn.hCard, SCARD_ATTR_ATR_STRING, (uint8_t*)ATR, &atrLen);
            
            ByteArray atrBa((BYTE*)ATR, atrLen);
            
            IAS ias((CToken::TokenTransmitCallback)TokenTransmitCallback, atrBa);
            ias.SetCardContext(&conn);
            ias.attemptsRemaining = -1;
            
            ias.token.Reset();
            ias.SelectAID_IAS();
            ias.ReadPAN();
            
            progressCallBack(10, "Lettura dati dalla CIE");
            
            ByteDynArray resp;
            ias.SelectAID_CIE();
        
            ias.InitEncKey();
            ias.ReadDappPubKey(resp);
            
            foundCIE = true;
    
            ias.SelectAID_IAS();
            ias.SelectAID_CIE();
            
            // leggo i parametri di dominio DH e della chiave di extauth
            ias.InitDHParam();
            
            ByteDynArray dappData;
            ias.ReadDappPubKey(dappData);
            
            ias.InitExtAuthKeyParam();
            
            progressCallBack(20, "Authenticazione...");
            
            ias.DHKeyExchange();
            
            // DAPP
            ias.DAPP();
            
            ByteArray pukBa((BYTE*)szPUK, strlen(szPUK));
            
            StatusWord sw = ias.VerifyPUK(pukBa);
            
            if (sw == 0x6983) {
                return SCARD_W_CHV_BLOCKED;
            }
            if (sw >= 0x63C0 && sw <= 0x63CF) {
                if (pAttempts!=nullptr)
                    *pAttempts = sw - 0x63C0;
                
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
            
            ByteDynArray cert;
            bool isEnrolled = ias.IsEnrolled();
            
            if(isEnrolled)
                ias.GetCertificate(cert);
            
            
            ByteArray newPINBa((BYTE*)szNewPIN, strlen(szNewPIN));
            
            sw = ias.ChangePIN(newPINBa);
            if (sw != 0x9000) {
                throw scard_error(sw);
            }
            
            if(isEnrolled)
            {
                std::string strPAN;
                dumpHexData(ias.PAN.mid(5,6), strPAN, false);
                ByteArray leftPINBa = newPINBa.left(4);
                ias.SetCache(strPAN.c_str(), cert,     leftPINBa);
            }
        }
        
        if (!foundCIE) {
            return CKR_TOKEN_NOT_RECOGNIZED;
            
        }
    }
    catch(...)
    {
        return CKR_GENERAL_ERROR;
    }
    
    return CKR_OK;
}
