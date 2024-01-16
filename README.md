# RockyLinux-ANSSI-BP-028

![](https://img.shields.io/badge/maintained-yes-green) ![](https://img.shields.io/github/license/Chelsea486MHz/RockyLinux-ANSSI-BP-028
) ![](https://img.shields.io/github/actions/workflow/status/Chelsea486MHz/RockyLinux-ANSSI-BP-028/docker.yml?label=build%20(docker))


## Description

Ce projet a pour but de rendre accessible le déploiement d'installations Rocky Linux répondant aux normes de sécurité établies par l'Agence Nationale de Sécurité des Systèmes d'Information (ANSSI).

## Documentation

Le manuel d'exploitation, contenant les manuels d'installation, utilisation, et modification, est disponible en PDF dans le répertoire `docs`. Il est également distribué au format PDF avec une signature PGP dans l'onglet "Releases" du dépôt GitHub.

[Manuel d'exploitation v1.0 (Applicable pour OS v9.3-1)](https://github.com/Chelsea486MHz/RockyLinux-ANSSI-BP-028/releases/download/v9.3-1/manuel-exploitation.pdf)

# Sécurité

Ce fork de Rocky Linux répond aux exigences de L'ANSSI en matière de configuration sécurisée d'un système GNU/Linux, telles que définies dans leur guide désigné BP-028 version 2.0.

[Document ANSSI-BP-028 2.0 (FR) (PDF)](https://cyber.gouv.fr/sites/default/files/document/fr_np_linux_configuration-v2.0.pdf)

[Document ANSSI-BP-028 2.0 (EN) (PDF)](https://cyber.gouv.fr/sites/default/files/document/linux_configuration-en-v2.pdf)

# Détails techniques

L'image ISO fournie permet d'installation un système Rocky Linux de version 9.3.

Le mot de passe `root` est `root`.

Vous devrez manuellement configurer `rsyslog` et ses certificats, ainsi que `sudo`.

# Création automatisée d'une image avec Docker

L'image disque peut être construite automatiquement par un script fonctionnant dans un conteneur Docker. Une image Docker est construite automatiquement par la pipeline de CI du dépôt GitHub. Pour l'utiliser :

`$ docker run --rm -v $(pwd)/build:/build -v $(pwd)/RockyLinux:/RockyLinux -v $(pwd)/buildlog.txt:/buildlog.txt chelsea486mhz/rockylinux-anssi-bp-028-build:9.3`

Sinon, l'image peut être construire et utilisée en local:

```
$ docker build -t rockylinux-bp-028-build .
$ docker run --rm -v $(pwd)/build:/build -v $(pwd)/RockyLinux:/RockyLinux -v $(pwd)/buildlog.txt:/buildlog.txt rockylinux-bp-028-build
```

L'image doit être reconstruite après chaque modification de `build.sh`.

# Utilisation

Insérez l'image disque et allumez la machine. L'installation est automatique.

# Configuration matérielle requise

- Un hyperviseur KVM/qemu/libvirt

- Un processeur x86_64 avec un accélérateur matériel AES

- Une interface réseau

- Un disque "système" de 32 Go

- Un disque "données" de volume arbitraire

# Packages installés

- EPEL

- Ansible

- OpenSSH

- Agent guest QEMU

- OpenSCAP

# Contributions

Les contributions sont les bienvenues.