# RockyLinux-ANSSI-BP-028

![](https://img.shields.io/badge/maintained-yes-green) ![](https://img.shields.io/github/license/Chelsea486MHz/RockyLinux-ANSSI-BP-028
) ![](https://img.shields.io/github/v/release/Chelsea486MHz/RockyLinux-ANSSI-BP-028
) ![](https://img.shields.io/badge/SECURITY_LEVEL-enhanced-blue)


## Description

Ce projet a pour but de rendre accessible le déploiement d'installations Rocky Linux répondant aux normes de sécurité établies par l'Agence Nationale de Sécurité des Systèmes d'Information (ANSSI).

## Pourquoi pas le niveau de sécurité maximal ?

Le niveau de sécurité maximal défini par l'ANSSI-BP-028 implique l'activation du flag SELinux responsable de bloquer le chargement de modules sur le noyau. Il est donc nécessaire de compiler son propre noyau.

Cet acte est hors du périmètre du projet, et doit être réalisé selon les exigences de chaque machine.

Il est tout à fait possible d'élever le niveau de sécurité en modifiant les variables d'environment du conteneur de build.

## Documentation

Le manuel d'exploitation, contenant les manuels d'installation, utilisation, et modification, est disponible en PDF dans le répertoire `docs`. Il est également distribué au format PDF avec une signature PGP dans l'onglet "Releases" du dépôt GitHub.

[Manuel d'exploitation v1.1 (Applicable pour OS v10.0-1)](https://github.com/Chelsea486MHz/RockyLinux-ANSSI-BP-028/releases/download/v10.0-1/manuel-exploitation.pdf)

## Conformité aux exigences de sécurité

Ce fork de Rocky Linux répond aux exigences de L'ANSSI en matière de configuration sécurisée d'un système GNU/Linux, telles que définies dans leur guide désigné BP-028 version 2.0.

Cependant, il est important de rapeller que les exigences en question sont très générales et ne peuvent donc être addressées que par des mécanismes automatique. Il sera nécessaire d'apporter manuellement des remédiations de sécurité chaque fois qu'une modification sera effectuée sur le système.

[Document ANSSI-BP-028 2.0 (FR) (PDF)](https://cyber.gouv.fr/sites/default/files/document/fr_np_linux_configuration-v2.0.pdf)

[Document ANSSI-BP-028 2.0 (EN) (PDF)](https://cyber.gouv.fr/sites/default/files/document/linux_configuration-en-v2.pdf)

## Compiler l'image disque

Vous pouvez reproduire l'image disque sécurisée en utilisant Docker Compose.

```
# docker-compose up --build
```

L'image ISO générée sera disponible dans le répertoire `build/`.

## Personaliser l'image

Si vous désirez produire vos propres images, il est possible d'ajouter des paquets en les concaténants à la liste dédiée :

```
$ echo 'PAQUET_A_INSTALLER' >> packages-to-add.txt
```

Il est également possible de changer le niveau de sécurité en modifiant le fichier `.env` :

```
$ sed -i 's/content_profile_anssi_bp28_enhanced/content_profile_anssi_bp28_minimal/g' .env
```

C'est également de cas du serveur depuis lequel l'image est téléchargée :

```
$ sed -i 's/download.rockylinux.org/mon.serveur.tld/g' .env
```

Vous pouvez aussi y configurer la clé publique SSH qui sera utilisée pour se connecter en tant que `root`:

```
$ cat .env | grep SSH
# The SSH key used to login as root on the installed system /!\
SSH_PUBKEY="ssh-rsa AAAA... openpgp:0xdeadbeef"
```

## Contributions

Les contributions sont les bienvenues.

## License

Le projet est sous license GPLv3.

Ce dépôt n'inclut pas de code ou algorithmes "innovants", il s'agit simplement d'intégration de technologies existentes pour facilier leur mise en exploitation.