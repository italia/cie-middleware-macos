#!/bin/sh
# Script for registering CIECryptoTokenKit
#
# Author: Ugo Chirico [10/10/2018]

echo -n "Registering CIECryptoTokenKit " > log.txt

exec sudo -u _securityagent pluginkit -a /Applications/CIE\ ID.app/Contents/PlugIns/CIEToken.appex

exec sudo -u launchctl load /Library/LaunchAgents/it.ipzs.CIE-ID-Bar.plist
