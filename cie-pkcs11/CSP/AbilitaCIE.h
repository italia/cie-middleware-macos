//
//  AbilitaCIE.h
//  cie-pkcs11
//
//  Created by ugo chirico on 02/09/18.
//  Copyright © 2018 IPZS. All rights reserved.
//
#include "../PKCS11/cryptoki.h"

/* CK_NOTIFY is an application callback that processes events */
typedef CK_CALLBACK_FUNCTION(CK_RV, PROGRESS_CALLBACK)(
                                               const int progress,
                                               const char* szMessage);

typedef CK_RV (*AbilitaCIEfn)(const char*  szPAN,
                               const char*  szPIN,
                               PROGRESS_CALLBACK progressCallBack);


//typedef CK_RV abilitaCIE(const char*  szPAN, const char*  szPIN, PROGRESS_CALLBACK progressCallBack)

