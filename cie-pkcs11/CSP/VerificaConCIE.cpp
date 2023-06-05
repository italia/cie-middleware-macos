//
//  VerificaConCIE.cpp
//  cie-pkcs11
//
//

#include "VerificaConCIE.h"
#include "../PKCS11/PKCS11Functions.h"

extern "C" {
    CK_RV CK_ENTRY verificaConCIE(const char* inFilePath, const char* proxyAddress, int proxyPort, const char* usrPass);
    CK_RV CK_ENTRY estraiP7m(const char* inFilePath, const char* outFilePath);
    CK_RV CK_ENTRY getVerifyInfo(int index, struct verifyInfo_t* vInfos);
}

VERIFY_RESULT verifyResult;

CK_RV CK_ENTRY getNumberOfSign()
{
    return (CK_RV)verifyResult.verifyInfo.pSignerInfos->nCount;
}

CK_RV CK_ENTRY getVerifyInfo(int index, struct verifyInfo_t* vInfos)
{
    if (index >= 0 && index < getNumberOfSign())
    {
        SIGNER_INFO tmpSignerInfo = (verifyResult.verifyInfo.pSignerInfos->pSignerInfo)[index];// +(index * sizeof(SIGNER_INFO)));
        strcpy(vInfos->name, tmpSignerInfo.szGIVENNAME);
        strcpy(vInfos->surname, tmpSignerInfo.szSURNAME);
        strcpy(vInfos->cn, tmpSignerInfo.szCN);
        strcpy(vInfos->cadn, tmpSignerInfo.szCADN);
        strcpy(vInfos->signingTime, tmpSignerInfo.szSigningTime);
        vInfos->CertRevocStatus = tmpSignerInfo.pRevocationInfo->nRevocationStatus;
        vInfos->isCertValid = (tmpSignerInfo.bitmask & VERIFIED_CERT_GOOD) == VERIFIED_CERT_GOOD;
        vInfos->isSignValid = (tmpSignerInfo.bitmask & VERIFIED_SIGNATURE) == VERIFIED_SIGNATURE;
    }
        return 0;
}

CK_RV CK_ENTRY verificaConCIE(const char* inFilePath, const char* proxyAddress, int proxyPort, const char* usrPass)
{
    CIEVerify* verifier = new CIEVerify();

    verifier->verify(inFilePath, (VERIFY_RESULT*)&verifyResult, proxyAddress, proxyPort, usrPass);

    if (verifyResult.nErrorCode == 0)
    {
        printf("verificaConCIE OK");
        
        if(verifyResult.verifyInfo.pSignerInfos != NULL)
            return (CK_RV)verifyResult.verifyInfo.pSignerInfos->nCount;
        
        return 0;
    }
    else
    {
        printf("Errore nella verifica: %lu\n", verifyResult.nErrorCode);
        LOG_ERROR("verificaConCIE - Errore nella verifica: %lu\n", verifyResult.nErrorCode);
        return verifyResult.nErrorCode;
    }
}

CK_RV CK_ENTRY estraiP7m(const char* inFilePath, const char* outFilePath) {

    CIEVerify* verifier = new CIEVerify();

    long res = verifier->get_file_from_p7m(inFilePath, outFilePath);

    return res;

}
