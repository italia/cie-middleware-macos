#!/bin/sh
# Script for registering CIECryptoTokenKit
#
# Author: Ugo Chirico [10/10/2018]

echo "Registering CIECryptoTokenKit " > ~/packagelog.txt

sudo -u _securityagent pluginkit -a /Applications/CIE\ ID.app/Contents/PlugIns/CIEToken.appex

echo -n "Registering CIECryptoTokenKit OK" > ~/packagelog.txt

launchctl load /Library/LaunchAgents/it.ipzs.CIE-ID-Bar.plist

echo "Loading Bar OK " > ~/packagelog.txt
