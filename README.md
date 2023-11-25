# RockyLinux-ANSSI-BP-028

## Description

Ce projet a pour but de rendre accessible le déploiement d'installations Rocky Linux répondant aux normes de sécurité établies par l'Agence Nationale de Sécurité des Systèmes d'Information (ANSSI).

# Sécurité

Ce fork de Rocky Linux répond aux exigences de L'ANSSI en matière de configuration sécurisée d'un système GNU/Linux, telles que définies dans leur guide désigné BP-028 version 2.0.

[~~Document ANSSI-BP-028 2.0 (FR) (PDF)~~](https://cyber.gouv.fr/uploads/2019/02/fr_np_linux_configuration-v2.0.pdf) Lien français actuellement mort

[Document ANSSI-BP-028 2.0 (EN) (PDF)](file:///C:/Users/Chelsea/Downloads/linux_configuration-en-v2.pdf)

# Détails techniques

L'image ISO fournie permet d'installation un système Rocky Linux de version 9.2.

Deux comptes sont créés : `root` et `admin`. Leur mot de passe sont `root` et `admin`.

Vous devrez manuellement configurer `rsyslog` et ses certificats, ainsi que `sudo`.

# Création automatisée d'une image avec Docker

L'image disque peut être construite automatiquement par un script fonctionnant dans un conteneur Docker.

Téléchargement de l'image Rocky Linux :

`$ docker pull rockylinux:9.2`

Construction de l'environnement de développement :

`$ docker build -t rockylinux-bp-028-9.2-dev .`

Construction de l'image disque dans l'environnement de développement :

`$ docker run --rm -v $(pwd):/app rockylinux-bp-028-9.2-dev`

L'image doit être reconstruite après chaque modification de `build.sh`

# Utilisation

Insérez l'image disque et allumez la machine. L'installation est automatique.

# Configuration matérielle requise

- Un hyperviseur KVM/qemu/libvirt

- Un processeur x86_64 avec un accélérateur matériel AES

- Une interface réseau

- Un disque "système" de 32 Go

- Un disque "données" de volume arbitraire

# Contributions

Les contributions sont les bienvenues.