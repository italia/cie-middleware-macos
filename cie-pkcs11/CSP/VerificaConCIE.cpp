//
//  VerificaConCIE.cpp
//  cie-pkcs11
//
//  Created by Pierluigi De Gregorio on 18/02/21.
//  Copyright © 2021 IPZS. All rights reserved.
//

#include "VerificaConCIE.h"
#include "../PKCS11/PKCS11Functions.h"

extern "C" {
    CK_RV CK_ENTRY verificaConCIE(const char* inFilePath, verifyInfos_t* vInfos, const char* proxyAddress, int proxyPort, const char* usrPass);
}

CK_RV CK_ENTRY verificaConCIE(const char* inFilePath, verifyInfos_t* vInfos, const char* proxyAddress, int proxyPort, const char* usrPass)
{
    VERIFY_RESULT verifyResult;
    CIEVerify* verifier = new CIEVerify();

    verifier->verify(inFilePath, (VERIFY_RESULT*)&verifyResult, proxyAddress, proxyPort, usrPass);
    
    if (verifyResult.nErrorCode == 0)
    {
        vInfos->n_infos = verifyResult.verifyInfo.pSignerInfos->nCount;
        
        for(int i = 0; i < vInfos->n_infos; i++)
        {
            SIGNER_INFO tmpSignerInfo = (verifyResult.verifyInfo.pSignerInfos->pSignerInfo)[i];// +(index * sizeof(SIGNER_INFO)));
            strcpy(vInfos->infos[i].name, tmpSignerInfo.szGIVENNAME);
            strcpy(vInfos->infos[i].surname, tmpSignerInfo.szSURNAME);
            strcpy(vInfos->infos[i].cn, tmpSignerInfo.szCN);
            strcpy(vInfos->infos[i].cadn, tmpSignerInfo.szCADN);
            strcpy(vInfos->infos[i].signingTime, tmpSignerInfo.szSigningTime);
            vInfos->infos[i].CertRevocStatus = tmpSignerInfo.pRevocationInfo->nRevocationStatus;
            vInfos->infos[i].isCertValid = (tmpSignerInfo.bitmask & VERIFIED_CERT_GOOD) == VERIFIED_CERT_GOOD;
            vInfos->infos[i].isSignValid = (tmpSignerInfo.bitmask & VERIFIED_SIGNATURE) == VERIFIED_SIGNATURE;
        }
        
        return 0;
    }else
    {
        printf("Errore nella verifica: %lu\n", verifyResult.nErrorCode);
        return verifyResult.nErrorCode;
    }
}
