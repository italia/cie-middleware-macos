# cie-middleware-macos
Middleware della CIE per MacOS (Carta di identità elettronica) 

# VERSIONE BETA

Il middleware qui presente è in fase di sviluppo, ed è da considerarsi in versione beta. È possibile effettuare tutti gli sviluppi e i test, ma è per ora questa base di codice non è consigliabile per l'uso in produzione.

# CASO D’USO

Il middleware CIE è una libreria software che implementa le interfacce crittografiche standard PKCS#11 e TokenDriver integrato in CryptoTokenKit. Esso consente agli applicativi integranti di utilizzare il certificato di autenticazione e la relativa chiave privata memorizzati sul chip della CIE astraendo dalle modalità di comunicazione di basso livello.

Il modulo implementa le specifiche PKCS#11 v2.20 in sola lettura

## Build

### Prerequisiti

1. xcode 9.4.1 o success

2. cocoapods

Per compilare il progetto dopo il cloning del repository, da terminale entrare nella cartella dove è stato clonato il repository ed eseguire il comando:

```
pod install
```

Quindi lanciare xcode ed aprire il file di progetto:

```
cie-pkcs11.xcworkspace
```



