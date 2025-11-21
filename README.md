# Déploiement d'une application Laravel sur Azure (IaaS)

Ce projet permet de déployer automatiquement une application Laravel sur une machine virtuelle Azure en utilisant Terraform et Docker.

## But du projet

Déployer une application web complète (front-end, back-end, base de données) sur Azure avec une seule commande :
- Créer une machine virtuelle Azure
- Installer Docker automatiquement
- Déployer l'application avec Docker Compose
- Rendre l'application accessible via une adresse IP publique

## Prérequis

### 1. Installer Azure CLI

Sur macOS :
```bash
brew install azure-cli
```

Sur Linux :
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 2. Se connecter à Azure

```bash
az login
```

Cette commande ouvrira votre navigateur pour vous authentifier. Une fois connecté, vérifiez votre abonnement actif :

```bash
az account show
```

Si vous avez plusieurs abonnements, sélectionnez celui à utiliser :

```bash
az account list --output table
az account set --subscription "NOM_DE_VOTRE_ABONNEMENT"
```

### 3. Permissions Azure

Le Resource Group sera créé automatiquement par Terraform dans la région `francecentral`. Assurez-vous d'avoir les permissions nécessaires pour créer des ressources dans votre abonnement Azure.

### 4. Installer Terraform

Sur macOS :
```bash
brew install terraform
```

Sur Linux :
```bash
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### 5. Installer Ansible

Le projet utilise Ansible pour déployer l'application sur la VM après sa création.

Sur macOS :
```bash
brew install ansible
```

Sur Linux :
```bash
sudo apt-get update
sudo apt-get install -y python3-pip
pip3 install ansible
```

Vérifiez l'installation :
```bash
ansible-playbook --version
```

### 6. Clés SSH

Le projet utilise automatiquement vos clés SSH locales (`~/.ssh/id_rsa.pub` et `~/.ssh/id_rsa`).

Si vous n'avez pas de clés SSH, créez-les :

```bash
ssh-keygen -t rsa -b 4096 -C "votre-email@example.com"
```

## Déploiement

### Étape 1 : Aller dans le dossier Terraform

```bash
cd terraform/iaas
```

### Étape 2 : Initialiser Terraform

```bash
terraform init
```

Cette commande télécharge les plugins nécessaires pour Azure.

### Étape 3 : Vérifier le plan de déploiement

```bash
terraform plan
```

Cette commande affiche ce qui va être créé sans le créer réellement.

### Étape 4 : Déployer

```bash
terraform apply
```

Tapez `yes` quand Terraform vous le demande. Terraform utilisera automatiquement l'abonnement actif d'Azure CLI (celui configuré avec `az account set`).

Le déploiement prend environ 10-15 minutes :
- 2-5 min : Création de l'infrastructure Azure (VM, réseau, etc.)
- 1-2 min : Attente que SSH soit disponible
- 5-8 min : Ansible installe Docker et déploie l'application

**Important** : Ansible sera appelé automatiquement par Terraform après la création de la VM. Assurez-vous qu'Ansible est installé (voir prérequis).

### Étape 5 : Récupérer l'adresse IP publique

Une fois le déploiement terminé, Terraform affiche l'adresse IP publique. Vous pouvez aussi la récupérer avec :

```bash
terraform output public_ip
terraform output application_url
```

Accédez à votre application dans votre navigateur : `http://VOTRE_IP_PUBLIQUE`

## Tester le déploiement

### Test rapide après déploiement

1. **Vérifier que l'application répond** :
```bash
PUBLIC_IP=$(terraform output -raw public_ip)
curl -I http://$PUBLIC_IP
```
Vous devriez voir un code HTTP `200` ou `302`.

2. **Tester dans le navigateur** :
Ouvrez `http://VOTRE_IP_PUBLIQUE` dans votre navigateur. Vous devriez voir la page d'accueil Laravel.

3. **Vérifier les conteneurs Docker** (optionnel) :
```bash
SSH_CMD=$(terraform output -raw ssh_command)
$SSH_CMD "docker ps"
```
Vous devriez voir les conteneurs `app-web` et `app-mysql` en cours d'exécution.

### Test manuel d'Ansible (pour déboguer)

Si le déploiement automatique échoue, vous pouvez tester Ansible manuellement :

```bash
# Récupérer l'IP de la VM
PUBLIC_IP=$(terraform output -raw public_ip)

# Exécuter Ansible manuellement
cd ansible
./deploy.sh "ssh -i ~/.ssh/id_rsa azureuser@$PUBLIC_IP"
```

### Vérifier les logs

Si quelque chose ne fonctionne pas, vérifiez les logs :

```bash
# Se connecter à la VM
SSH_CMD=$(terraform output -raw ssh_command)
$SSH_CMD

# Une fois connecté, vérifier les conteneurs
docker ps
docker logs app-web
docker logs app-mysql

# Vérifier que l'application tourne
curl localhost
```

## Structure du projet

### Dossier `terraform/iaas/`

Ce dossier contient la configuration Terraform pour créer l'infrastructure Azure.

#### `main.tf`
**Rôle** : Définit toutes les ressources Azure à créer.

**Contenu** :
- **Resource Group** : Créé automatiquement dans la région `francecentral`
- **Réseau virtuel (VNet)** : Un réseau privé pour isoler votre VM
- **Subnet** : Une sous-réseau dans le VNet pour la VM
- **Adresse IP publique** : Permet d'accéder à la VM depuis Internet
- **Groupe de sécurité réseau (NSG)** : Règles de pare-feu (autorise SSH port 22 et HTTP port 80)
- **Interface réseau** : Connecte la VM au réseau
- **Machine virtuelle Linux** : La VM Ubuntu avec Docker installé automatiquement (via cloud-init)
- **Déploiement de l'application** : Upload du code et démarrage des conteneurs Docker

#### `variables.tf`
**Rôle** : Définit les variables configurables du projet.

**Variables** :
- `resource_group_name` : Nom du Resource Group Azure (défaut: `rg-par_16`)
- `admin_username` : Nom d'utilisateur pour se connecter à la VM (défaut: `azureuser`)
- `vm_size` : Taille de la VM (défaut: `Standard_B1s` - la plus petite et moins chère)
- `ssh_public_key` et `ssh_private_key` : Clés SSH (lues automatiquement depuis `~/.ssh/` si non spécifiées)

#### `outputs.tf`
**Rôle** : Affiche des informations utiles après le déploiement.

**Sorties** :
- `public_ip` : L'adresse IP publique de la VM
- `ssh_command` : La commande SSH pour se connecter à la VM
- `application_url` : URL complète de l'application (`http://IP_PUBLIQUE`)

#### `env.tpl`
**Rôle** : Template pour le fichier `.env` de Laravel.

Ce fichier est copié sur la VM et devient le `.env` de l'application Laravel. Il contient les variables d'environnement nécessaires :
- Configuration de la base de données (MySQL)
- Environnement de production
- Configuration de l'application

### Dossier `docker/`

Ce dossier contient la configuration Docker pour orchestrer les conteneurs.

#### `docker-compose.yml`
**Rôle** : Définit les services Docker à démarrer.

**Services** :
1. **`db`** : Conteneur MySQL 8.0
   - Base de données `laravel`
   - Utilisateur `laravel` avec mot de passe `secret`
   - Healthcheck pour vérifier que la base est prête

2. **`app`** : Conteneur Laravel (PHP/Apache)
   - Construit depuis le Dockerfile dans `sample-app-master/`
   - Attend que la base de données soit prête (`depends_on`)
   - Génère automatiquement la clé Laravel (`APP_KEY`)
   - Exécute les migrations de base de données
   - Expose le port 80 (HTTP)

### Dossier `sample-app-master/`

Contient le code source de l'application Laravel.

## Comment ça fonctionne ?

### 1. Création de l'infrastructure
Terraform crée l'infrastructure Azure :
- Resource Group
- Réseau virtuel (VNet) et sous-réseau
- Adresse IP publique
- Groupe de sécurité réseau (NSG) avec règles SSH (22) et HTTP (80)
- Machine virtuelle Ubuntu 22.04 LTS

### 2. Déploiement automatique avec Ansible
Une fois la VM créée, Terraform appelle automatiquement Ansible via un provisioner `local-exec` :

1. **Attente SSH** : Terraform attend que la VM soit accessible en SSH (jusqu'à 5 minutes)
2. **Exécution d'Ansible** : Le playbook `ansible/deploy.yml` est exécuté automatiquement :
   - Installation de Docker et docker-compose-plugin
   - Copie du code de l'application (`sample-app-master/`) vers `/opt/sample-app` sur la VM
   - Copie du fichier `docker-compose.yml` depuis `docker/` vers la VM
   - Lancement des conteneurs Docker :
     ```bash
     docker compose up -d db      # Démarre la base de données
     # Attente que MySQL soit prêt
     docker compose run --rm app php artisan migrate --force  # Migrations
     docker compose up -d         # Démarre l'application
     ```

### 3. Accès à l'application
L'application est accessible via l'adresse IP publique sur le port 80 (HTTP).

**Note** : Le déploiement complet prend environ 10-15 minutes (création infrastructure + déploiement Ansible).

## Supprimer les ressources

Pour supprimer tout ce qui a été créé :

```bash
cd terraform/iaas
terraform destroy
```

Tapez `yes` pour confirmer. Cela supprime la VM, le réseau, et toutes les ressources associées.

## CI/CD avec GitHub Actions

Le projet inclut un workflow GitHub Actions qui déploie automatiquement l'infrastructure à chaque push sur la branche `main`.

### Configuration des secrets Azure

Pour que GitHub Actions puisse déployer sur Azure, vous devez créer un Service Principal Azure et l'ajouter comme secret dans GitHub.

#### Étape 1 : Créer un Service Principal Azure

```bash
# Récupérer votre subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Créer le Service Principal avec permissions au niveau de l'abonnement
az ad sp create-for-rbac --name "github-actions-iaas" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth
```

Cette commande affiche un JSON avec les credentials. **Copiez ce JSON**, vous en aurez besoin pour l'étape suivante.

**Important** : Le Service Principal doit avoir les permissions au niveau de l'abonnement pour pouvoir créer le Resource Group automatiquement.

#### Étape 2 : Ajouter le secret dans GitHub

1. Allez sur votre dépôt GitHub : `https://github.com/VOTRE_ORGANISATION/T-CLO-901-PAR_16`
2. Cliquez sur **Settings** → **Secrets and variables** → **Actions**
3. Cliquez sur **New repository secret**
4. Nom : `AZURE_CREDENTIALS`
5. Valeur : Collez le JSON complet obtenu à l'étape 1
6. Cliquez sur **Add secret**

### Fonctionnement du workflow

Le workflow `.github/workflows/deploy-iaas.yml` s'exécute automatiquement à chaque push sur `main` qui modifie :
- Les fichiers Terraform (`terraform/iaas/**`)
- La configuration Docker (`docker/**`)
- Le code de l'application (`sample-app-master/**`)
- Les playbooks Ansible (`ansible/**`)

**Étapes du workflow** :

1. **Connexion Azure** : Se connecte à Azure avec le Service Principal via Azure CLI
2. **Installation d'Ansible** : Installe Ansible pour le déploiement
3. **Génération de clés SSH** : Génère automatiquement des clés SSH pour la VM
4. **Formatage Terraform** : Formate automatiquement les fichiers Terraform
5. **Terraform Init** : Initialise Terraform
6. **Terraform Validate** : Valide la syntaxe Terraform
7. **Terraform Plan** : Génère le plan de déploiement
8. **Terraform Apply** : Déploie l'infrastructure et appelle automatiquement Ansible pour déployer l'application
9. **Attente de l'application** : Attend que l'application soit prête (jusqu'à 5 minutes)
10. **Smoke Tests** : Vérifie que l'application répond correctement
    - Test de la page d'accueil (HTTP 200 ou 302)
    - Test de l'API (si disponible)
    - Vérification du temps de réponse
11. **Nettoyage** : Nettoie les fichiers Terraform locaux

**Durée totale** : Environ 10-15 minutes (déploiement + tests)

### Vérifier l'exécution du workflow

1. Allez sur votre dépôt GitHub
2. Cliquez sur l'onglet **Actions**
3. Vous verrez l'historique des exécutions du workflow
4. Cliquez sur une exécution pour voir les détails de chaque étape

### Notes sur la CI/CD

- **Coûts** : Les ressources Azure restent actives après le déploiement. Pour les supprimer, utilisez `terraform destroy` manuellement.
- **Déploiement manuel** : Vous pouvez toujours déployer manuellement avec `terraform apply` si nécessaire
- **Région** : Le Resource Group et toutes les ressources sont créées dans la région `francecentral`
- **Connexion Azure** : Le workflow utilise Azure CLI directement pour se connecter à Azure (plus fiable que l'action GitHub)

## Notes importantes

- **Coûts** : La VM Standard_B1s génère des coûts tant qu'elle existe. N'oubliez pas de faire `terraform destroy` quand vous n'en avez plus besoin.
- **Région** : Toutes les ressources sont créées dans la région `francecentral` (région autorisée pour les abonnements étudiants Azure).
- **Sécurité** : Les ports SSH (22) et HTTP (80) sont ouverts à tous (`*`). Pour la production, limitez-les à votre IP.
- **Clés SSH** : Si vous n'avez pas de clés SSH dans `~/.ssh/id_rsa`, vous pouvez les spécifier via des variables Terraform. Dans GitHub Actions, les clés SSH sont générées automatiquement.
- **Resource Group** : Le Resource Group est créé automatiquement par Terraform. Si vous le supprimez manuellement, Terraform le recréera au prochain déploiement.
