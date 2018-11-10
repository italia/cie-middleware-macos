
Middleware della CIE per MacOS (Carta di identità elettronica) 

VERSIONE BETA

Il middleware in questo repository è in fase di sviluppo ed è da considerarsi in versione beta e pertanto non è consigliabile per l'uso in produzione.

CASO D’USO

Il middleware CIE per MacOS X è composto da due librerie software che implementano rispettivamente le interfacce crittografiche standard PKCS#11 v2.20 (in sola lettura) e TokenDriver (integrato in CryptoTokenKit). 
Tali librerie consentono agli applicativi integranti di utilizzare il certificato di autenticazione e la relativa chiave privata memorizzati sul chip della CIE astraendo dalle modalità di comunicazione di basso livello.




