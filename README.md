# cie-middleware-macos
Middleware della CIE per MacOS (Carta di identità elettronica) 

# VERSIONE CORRENTE

Il Software CIE è rilasciato ufficialmente su [APP STORE](https://apps.apple.com/it/app/software-cie/id6476510798?mt=12).
Il manuale d'uso è disponibile su [DOCS ITALIA](https://docs.italia.it/italia/cie/cie-middleware-windows-docs/it/master/index.html).


# CASO D’USO

Il middleware CIE per MacOS X è composto da due librerie software che implementano rispettivamente le interfacce crittografiche standard PKCS#11 v2.20 (in sola lettura) e TokenDriver (integrato in CryptoTokenKit). 
Tali librerie consentono agli applicativi integranti di utilizzare il certificato di autenticazione e la relativa chiave privata memorizzati sul chip della CIE astraendo dalle modalità di comunicazione di basso livello.

## Build

### Prerequisiti

1. xcode 9.4.1 o success

2. cocoapods

Per compilare il progetto, dopo il cloning del repository, da terminale, entrare nella cartella dove è stato clonato il repository ed eseguire il comando:

```
pod install
```

Quindi lanciare xcode ed aprire il file di progetto:

```
cie-pkcs11.xcworkspace
```



