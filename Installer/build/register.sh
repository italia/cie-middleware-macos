#!/bin/sh
# Script for registering CIECryptoTokenKit
#
# Author: Ugo Chirico [10/10/2018]

echo -n "Registering CIECryptoTokenKit " > log.txt

exec sudo -u _securityagent pluginkit -a /Applications/AbilitaCIE.app/Contents/PlugIns/CIEToken.appex
