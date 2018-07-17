//
//  cie_pkcs11.cpp
//  cie-pkcs11
//
//  Created by ugo chirico on 17/07/18.
//  Copyright © 2018 IPZS. All rights reserved.
//

#include <iostream>
#include "cie_pkcs11.hpp"
#include "cie_pkcs11Priv.hpp"

void cie_pkcs11::HelloWorld(const char * s)
{
    cie_pkcs11Priv *theObj = new cie_pkcs11Priv;
    theObj->HelloWorldPriv(s);
    delete theObj;
};

void cie_pkcs11Priv::HelloWorldPriv(const char * s) 
{
    std::cout << s << std::endl;
};

