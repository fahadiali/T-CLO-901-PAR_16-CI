# Azure Cloud Infrastructure Comparison

## Description du projet

Ce projet vise à comparer les modèles d'infrastructure cloud **IaaS** (Infrastructure as a Service) et **PaaS** (Platform as a Service) sur Microsoft Azure. L'objectif est de démontrer les différences en termes de coût, performance, scalabilité et facilité de gestion entre ces deux approches.

## 🎯 Objectifs principaux

- **Déployer** une application hautement disponible sur Azure
- **Comparer** les performances des infrastructures déployées (coût et scalabilité)
- **Implémenter** des techniques IaC pour assurer la reproductibilité
- **Automatiser** le processus de déploiement (spin up/tear down)
- **Gérer** différents environnements avec isolation des états

## 🛠️ Technologies utilisées

| Technologie | Version | Rôle |
|-------------|---------|------|
| **Terraform** | >= 1.0 | Provisioning d'infrastructure |
| **Ansible** | >= 2.9 | Gestion de configuration |
| **Docker** | >= 20.10 | Conteneurisation |
| **Azure Web Apps** | Latest | Plateforme PaaS |
| **GitHub Actions** | Latest | CI/CD |

## 📁 Structure du projet

```
epitech/
├── project-context.yaml    # Contexte détaillé du projet
├── README.md              # Documentation principale
├── terraform/             # Configuration Terraform
│   ├── iaas/             # Infrastructure IaaS (vide)
│   └── paas/             # Infrastructure PaaS (vide)
├── ansible/              # Playbooks Ansible (vide)
├── docker/               # Configuration Docker (vide)
├── scripts/              # Scripts utilitaires (vide)
└── docs/                 # Documentation supplémentaire (vide)
```

## 🏗️ Architecture

### IaaS (Infrastructure as a Service)
- **Machines virtuelles Azure** avec OS choisi
- **Configuration automatique** via Ansible
- **Déploiement d'application** conteneurisée
- **Haute disponibilité** avec Load Balancer
- **Monitoring** et alertes personnalisées

### PaaS (Platform as a Service)
- **Azure Web Apps** pour déploiement d'application
- **Configuration automatique** via Terraform
- **Intégration CI/CD** avec GitHub Actions
- **Scaling automatique** intégré
- **Monitoring** Azure natif

## 🚀 Déploiement

### Prérequis

- [x] Azure CLI installé et configuré
- [x] Terraform installé
- [x] Ansible installé
- [x] Docker installé
- [x] Compte Azure avec permissions appropriées

### Instructions de déploiement

1. **Cloner le repository**
   ```bash
   git clone <repository-url>
   cd epitech
   ```

2. **Configurer les variables d'environnement Azure**
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

3. **Exécuter les scripts de déploiement**
   ```bash
   # Déploiement IaaS
   cd terraform/iaas
   terraform init
   terraform plan
   terraform apply
   
   # Déploiement PaaS
   cd ../paas
   terraform init
   terraform plan
   terraform apply
   ```

## 🧪 Tests et comparaisons

### Tests de stress
- **Apache Bench (ab)** pour tests de charge
- **JMeter** pour tests avancés
- **Artillery** pour tests de performance

### Métriques mesurées
- Temps de réponse (p50, p95, p99)
- Throughput (requêtes/seconde)
- Taux d'erreur
- Utilisation des ressources (CPU, Mémoire, Réseau)

### Analyse des coûts
- Coût par heure/jour/mois
- Coût par requête
- Coût par utilisateur simultané
- Coût de maintenance

## 🌍 Gestion des environnements

Le projet supporte trois environnements :

| Environnement | Ressources | Auto-shutdown | Usage |
|---------------|------------|---------------|-------|
| **Development** | Minimales (1 VM, Basic App Service) | 18h00 | Développement et tests |
| **Staging** | Intermédiaires (2 VMs, Standard App Service) | 20h00 | Tests d'intégration |
| **Production** | Complètes (3+ VMs, Premium App Service) | Manuel | Production simulée |

## 📊 Monitoring et alertes

- **Dashboard de performance** IaaS vs PaaS
- **Dashboard de coûts** en temps réel
- **Alertes automatiques** pour anomalies
- **Rapports de performance** automatisés

## 🔒 Sécurité et conformité

- **Network Security Groups** restrictifs
- **Authentification Azure AD**
- **Secrets management** via Azure Key Vault
- **Audit logs** activés
- **Backup automatique** des configurations

## 📈 Roadmap

- [ ] **Phase 1** : Setup et configuration de base (1-2 semaines)
- [ ] **Phase 2** : Déploiement IaaS avec Terraform/Ansible (2-3 semaines)
- [ ] **Phase 3** : Déploiement PaaS avec Azure Web Apps (1-2 semaines)
- [ ] **Phase 4** : Tests de stress et comparaisons (1-2 semaines)
- [ ] **Phase 5** : Automatisation et CI/CD (1-2 semaines)
- [ ] **Phase 6** : Documentation et bonus features (1 semaine)

## 🎁 Fonctionnalités bonus

- **Terragrunt** pour déploiement multi-environnements
- **Azure VM Templates** pour déploiements rapides
- **Monitoring avancé** avec Azure Monitor
- **Auto-scaling** basé sur les métriques
- **Blue-green deployments**

## 📚 Documentation

- [Guide de déploiement IaaS](docs/iaas-deployment.md)
- [Guide de déploiement PaaS](docs/paas-deployment.md)
- [Procédures de redéploiement](docs/redeployment.md)
- [Best practices](docs/best-practices.md)
- [Rapport de comparaison](docs/comparison-report.md)

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 👥 Équipe

- **Étudiant Epitech** - Développement et architecture
- **Encadrant** - Supervision et validation

## 📞 Support

Pour toute question ou problème, veuillez ouvrir une issue sur GitHub ou contacter l'équipe de développement.

---

**Note importante** : Ce projet utilise des ressources Azure en temps réel. Il est essentiel de gérer les ressources de manière responsable et d'arrêter les machines virtuelles en fin de journée pour optimiser les coûts.
