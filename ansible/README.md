# Déploiement Ansible ultra simple

Ce dossier fournit un tout petit process Ansible pour pousser `sample-app-master` sur une VM, installer Docker, puis lancer `docker compose up -d`.

## Pré-requis
- Ansible installé en local
- Accès SSH vers la VM (clé, user, IP…) testé à la main

## Utilisation
1. Placez-vous à la racine du repo.
2. Lancez :
   ```bash
   ./ansible/deploy.sh "ssh -i ~/.ssh/id_rsa azureuser@4.233.134.144"
   ```
   > Remplacez la commande SSH par celle qui fonctionne déjà pour votre VM. C'est le **seul** paramètre variable.

Le script :
- recrée un inventaire temporaire à partir de la commande SSH
- copie le projet `sample-app-master` sous `/opt/sample-app` sur la VM
- installe Docker via le script officiel + le plugin `docker compose`
- exécute `docker compose up -d` dans ce dossier

## Personnalisation légère
- `REMOTE_PATH=/chemin ./ansible/deploy.sh "ssh ..."` permet de changer le dossier cible.
- Les autres comportements sont volontairement figés pour rester ultra simples.
