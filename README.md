# cie-middleware-macos
Middleware della CIE per MacOS (Carta di identità elettronica) 

Implementazione del modulo PKCS#11 per MacOS necessario per usare la nuova Carta d'Identita Elettronica su computer con sistema operativo MacOS-X


Il modulo implementa le specifiche PKCS#11 v2.20 in sola lettura

## Build

### Prerequisiti

1. xcode 9.4.1 o successivi
2. cocoapods

Per compilare il progetto dopo il cloning del repository eseguire:

'''
pod install
'''

Quindi avviare la build da xcode
