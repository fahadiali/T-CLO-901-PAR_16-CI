# Présentation : Déploiement IaaS avec Terraform et GitHub Actions

## Vue d'ensemble du projet

**Objectif** : Déployer automatiquement une application Laravel sur Azure avec une seule commande (`terraform apply`) ou automatiquement via GitHub Actions.

**Technologies utilisées** :
- **Terraform** : Infrastructure as Code (IaC)
- **Azure** : Cloud provider (VM, réseau, etc.)
- **Docker** : Containerisation de l'application
- **GitHub Actions** : CI/CD automatisé

---

## 1. Terraform - Infrastructure as Code

### Qu'est-ce que Terraform ?

Terraform est un outil qui permet de définir l'infrastructure cloud avec du code. Au lieu de créer manuellement des ressources dans Azure, on écrit un fichier de configuration qui décrit ce qu'on veut créer.

### Avantages

- **Reproductibilité** : Même infrastructure à chaque fois
- **Versioning** : Le code est versionné dans Git
- **Automatisation** : Pas besoin de cliquer dans l'interface Azure
- **Documentation** : Le code Terraform documente l'infrastructure

### Structure de notre projet Terraform

```
terraform/iaas/
├── main.tf          # Définit toutes les ressources Azure
├── variables.tf     # Variables configurables
├── outputs.tf       # Informations affichées après déploiement
└── env.tpl          # Template pour le fichier .env Laravel
```

### Fichier `main.tf` - Les ressources créées

1. **Resource Group** (`azurerm_resource_group`)
   - Conteneur logique pour toutes les ressources
   - Région : `francecentral`

2. **Réseau virtuel (VNet)** (`azurerm_virtual_network`)
   - Réseau privé pour isoler la VM
   - Plage d'adresses : `10.10.0.0/16`

3. **Subnet** (`azurerm_subnet`)
   - Sous-réseau dans le VNet
   - Plage d'adresses : `10.10.1.0/24`

4. **Adresse IP publique** (`azurerm_public_ip`)
   - Permet d'accéder à la VM depuis Internet
   - Type : Static (ne change pas)

5. **Groupe de sécurité réseau (NSG)** (`azurerm_network_security_group`)
   - Règles de pare-feu
   - Autorise SSH (port 22) et HTTP (port 80)

6. **Interface réseau** (`azurerm_network_interface`)
   - Connecte la VM au réseau
   - Associe l'IP publique et le NSG

7. **Machine virtuelle** (`azurerm_linux_virtual_machine`)
   - VM Ubuntu 22.04 LTS
   - Taille : Standard_B1s (1 vCPU, 1 GB RAM)
   - Installation Docker automatique via `cloud-init`

8. **Déploiement de l'application** (`null_resource`)
   - Upload du code via SSH
   - Lancement des conteneurs Docker

### Fichier `variables.tf` - Configuration

Variables qui permettent de personnaliser le déploiement :
- `resource_group_name` : Nom du Resource Group
- `vm_size` : Taille de la VM
- `admin_username` : Utilisateur administrateur
- `ssh_public_key` / `ssh_private_key` : Clés SSH (optionnelles)

### Fichier `outputs.tf` - Résultats

Après le déploiement, Terraform affiche :
- `public_ip` : L'adresse IP publique de la VM
- `ssh_command` : Commande pour se connecter en SSH

---

## 2. Azure - Les ressources cloud

### Pourquoi Azure ?

- Abonnement étudiant gratuit disponible
- Région `francecentral` autorisée pour les étudiants
- Services nécessaires disponibles (VM, réseau, etc.)

### Ressources créées dans Azure

1. **Resource Group** : `rg-par_16`
   - Contient toutes les ressources du projet
   - Région : `francecentral`

2. **VM Ubuntu** : `vm-app-XXXX`
   - OS : Ubuntu 22.04 LTS
   - Installation Docker automatique au démarrage
   - Accès SSH avec clés

3. **Réseau** :
   - VNet : `vnet-XXXX`
   - Subnet : `subnet-app`
   - IP publique : `pip-vm-XXXX`
   - NSG : `nsg-vm-XXXX`

### Cloud-init - Installation automatique de Docker

Le fichier `cloud-init` dans `main.tf` installe Docker automatiquement au démarrage de la VM :

```yaml
#cloud-config
package_update: true
packages:
  - docker-ce
  - docker-compose-plugin
```

Cela permet d'avoir Docker prêt sans intervention manuelle.

---

## 3. Docker - Containerisation

### Pourquoi Docker ?

- Isolation : Chaque service (app, base de données) dans son propre conteneur
- Portabilité : Fonctionne de la même manière partout
- Simplicité : Un seul fichier `docker-compose.yml` pour tout orchestrer

### Fichier `docker-compose.yml`

Deux services :

1. **`db`** : MySQL 8.0
   - Base de données : `laravel`
   - Utilisateur : `laravel` / Mot de passe : `secret`
   - Healthcheck pour vérifier que la DB est prête

2. **`app`** : Laravel (PHP/Apache)
   - Construit depuis le Dockerfile
   - Attend que la DB soit prête (`depends_on`)
   - Génère automatiquement `APP_KEY`
   - Exécute les migrations
   - Expose le port 80

### Déploiement sur la VM

1. Terraform upload le code via SSH
2. Terraform upload `docker-compose.yml`
3. Terraform crée le fichier `.env`
4. Terraform exécute `docker compose build`
5. Terraform exécute `docker compose up -d`

---

## 4. GitHub Actions - CI/CD

### Qu'est-ce que GitHub Actions ?

GitHub Actions permet d'automatiser des tâches à chaque push sur le dépôt Git. Dans notre cas, on automatise le déploiement.

### Workflow : `.github/workflows/deploy-iaas.yml`

**Déclenchement** : À chaque push sur `main` qui modifie :
- `terraform/iaas/**`
- `docker/**`
- `sample-app-master/**`

### Étapes du workflow

#### 1. Setup de l'environnement
- Checkout du code
- Installation de Terraform
- Installation d'Azure CLI

#### 2. Connexion à Azure
- Extraction des credentials depuis le secret GitHub
- Connexion avec `az login --service-principal`
- Configuration de l'abonnement actif

#### 3. Génération de clés SSH
- Génération automatique d'une paire de clés SSH
- Utilisées pour se connecter à la VM

#### 4. Validation Terraform
- Formatage automatique (`terraform fmt`)
- Initialisation (`terraform init`)
- Validation (`terraform validate`)

#### 5. Déploiement
- Plan Terraform (`terraform plan`)
- Application (`terraform apply`)
- Création de toutes les ressources Azure

#### 6. Tests
- Attente que l'application soit prête (jusqu'à 5 minutes)
- Smoke tests :
  - Vérification HTTP 200/302 sur la page d'accueil
  - Test de l'API
  - Vérification du temps de réponse

#### 7. Nettoyage
- Suppression des fichiers Terraform locaux (`.terraform`, `tfplan`)

### Secrets GitHub

Le secret `AZURE_CREDENTIALS` contient un JSON avec :
- `clientId` : ID du Service Principal
- `clientSecret` : Secret du Service Principal
- `subscriptionId` : ID de l'abonnement Azure
- `tenantId` : ID du tenant Azure

### Service Principal Azure

Un Service Principal est un compte de service qui permet à GitHub Actions de se connecter à Azure sans utiliser votre compte personnel.

**Création** :
```bash
az ad sp create-for-rbac --name "github-actions-iaas" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth
```

**Permissions** : `contributor` au niveau de l'abonnement (peut créer/modifier/supprimer des ressources)

---

## 5. Processus de déploiement complet

### Déploiement manuel

```bash
cd terraform/iaas
terraform init      # Télécharge les plugins
terraform plan      # Voir ce qui sera créé
terraform apply     # Créer les ressources
terraform output    # Voir l'IP publique
```

### Déploiement automatique (CI/CD)

1. **Développeur** fait un `git push` sur `main`
2. **GitHub Actions** détecte le changement
3. **Workflow** se lance automatiquement
4. **Terraform** crée toutes les ressources Azure
5. **Application** est déployée et testée
6. **Résultat** : Application accessible sur l'IP publique

### Timeline du déploiement

- **0-2 min** : Setup et connexion Azure
- **2-5 min** : Création des ressources Azure (VM, réseau, etc.)
- **5-8 min** : Installation Docker sur la VM (cloud-init)
- **8-10 min** : Upload du code et build des images Docker
- **10-12 min** : Lancement des conteneurs et migrations DB
- **12-15 min** : Tests de l'application

**Total** : ~15 minutes pour un déploiement complet

---

## 6. Avantages de cette approche

### Infrastructure as Code (IaC)

✅ **Reproductibilité** : Même infrastructure à chaque fois
✅ **Versioning** : Historique des changements dans Git
✅ **Documentation** : Le code Terraform documente l'infrastructure
✅ **Collaboration** : Plusieurs personnes peuvent travailler sur le même projet

### CI/CD automatisé

✅ **Automatisation** : Déploiement automatique à chaque push
✅ **Tests** : Vérification automatique que l'application fonctionne
✅ **Rapidité** : Pas besoin d'intervention manuelle
✅ **Traçabilité** : Historique des déploiements dans GitHub Actions

### Containerisation

✅ **Isolation** : Chaque service dans son conteneur
✅ **Portabilité** : Fonctionne de la même manière partout
✅ **Simplicité** : Un seul fichier pour orchestrer tous les services

---

## 7. Points techniques importants

### Gestion des clés SSH

- **Localement** : Utilise `~/.ssh/id_rsa` automatiquement
- **GitHub Actions** : Génère des clés automatiquement
- **Sécurité** : Les clés privées ne sont jamais exposées

### Attente de Docker

Le workflow attend que Docker soit installé avant d'exécuter les commandes :
- Attente initiale de 2 minutes
- Vérification avec `until command -v docker`
- Maximum 5 minutes d'attente totale

### Gestion des erreurs

- Si le déploiement échoue, les ressources restent pour debug
- Les fichiers Terraform locaux sont nettoyés
- Les logs sont disponibles dans GitHub Actions

---

## 8. Coûts et limites

### Coûts Azure

- **VM Standard_B1s** : ~5-10€/mois
- **IP publique** : Gratuite (statique)
- **Réseau** : Gratuit
- **Total** : ~5-10€/mois pour l'infrastructure

### Limites

- **Abonnement étudiant** : Limite de 3 IP publiques par région
- **Région** : Seulement certaines régions autorisées (`francecentral`)
- **Quotas** : Limites sur le nombre de VMs par abonnement

---

## 9. Améliorations possibles

### Sécurité

- Limiter les règles NSG à des IPs spécifiques
- Utiliser Azure Key Vault pour les secrets
- Activer les logs d'audit Azure

### Performance

- Utiliser des VMs plus puissantes
- Ajouter un load balancer pour haute disponibilité
- Mettre en cache les images Docker

### Monitoring

- Intégrer Azure Monitor
- Ajouter des alertes
- Dashboard de monitoring

### Scalabilité

- Auto-scaling basé sur la charge
- Plusieurs instances de l'application
- Base de données managée Azure

---

## Conclusion

Ce projet démontre comment :
1. **Définir l'infrastructure avec Terraform** (Infrastructure as Code)
2. **Automatiser le déploiement avec GitHub Actions** (CI/CD)
3. **Containeriser une application avec Docker**
4. **Déployer sur Azure** (Cloud IaaS)

**Résultat** : Un déploiement entièrement automatisé, reproductible et documenté.

