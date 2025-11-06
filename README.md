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

### 5. Clés SSH

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

Tapez `yes` quand Terraform vous le demande. Le déploiement prend environ 5-10 minutes.

### Étape 5 : Récupérer l'adresse IP publique

Une fois le déploiement terminé, Terraform affiche l'adresse IP publique. Vous pouvez aussi la récupérer avec :

```bash
terraform output public_ip
```

Accédez à votre application dans votre navigateur : `http://VOTRE_IP_PUBLIQUE`

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

### 1. Création de la VM
Terraform crée une VM Ubuntu et utilise `cloud-init` pour installer Docker automatiquement au démarrage.

### 2. Upload du code
Une fois la VM créée, Terraform :
- Se connecte en SSH à la VM
- Upload le dossier `sample-app-master/` (le code de l'application)
- Upload le fichier `docker-compose.yml`
- Crée le fichier `.env` depuis le template

### 3. Lancement des conteneurs
Terraform exécute ensuite :
```bash
docker compose build    # Construit les images Docker
docker compose up -d    # Lance les conteneurs en arrière-plan
```

### 4. Accès à l'application
L'application est accessible via l'adresse IP publique sur le port 80 (HTTP).

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

**Étapes du workflow** :

1. **Connexion Azure** : Se connecte à Azure avec le Service Principal via Azure CLI
2. **Génération de clés SSH** : Génère automatiquement des clés SSH pour la VM
3. **Formatage Terraform** : Formate automatiquement les fichiers Terraform
4. **Terraform Init** : Initialise Terraform
5. **Terraform Validate** : Valide la syntaxe Terraform
6. **Terraform Plan** : Génère le plan de déploiement
7. **Terraform Apply** : Déploie l'infrastructure (crée le Resource Group, la VM, le réseau, etc.)
8. **Attente de l'application** : Attend que l'application soit prête (jusqu'à 5 minutes)
9. **Smoke Tests** : Vérifie que l'application répond correctement
   - Test de la page d'accueil (HTTP 200 ou 302)
   - Test de l'API (si disponible)
   - Vérification du temps de réponse
10. **Nettoyage** : Nettoie les fichiers Terraform locaux

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
