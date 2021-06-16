//
//  VerificaConCIE.h
//  cie-pkcs11
//
//  Copyright © 2021 IPZS. All rights reserved.
//

#ifndef VerificaConCIE_h
#define VerificaConCIE_h

#include <stdio.h>
#include "AbilitaCIE.h"
#include "../Sign/CIEVerify.h"

//typedef CK_RV (*verificaConCIEfn)(const char* inFilePath, verifyInfos_t* vInfos);
typedef CK_RV (*verificaConCIEfn)(const char* inFilePath, verifyInfos_t* vInfos, const char* proxyAddress, int proxyPort, const char* usrPass);

typedef CK_RV (*estraiP7mfn)(const char* inFilePath, const char* outFilePath);


#endif /* VerificaConCIE_h */
