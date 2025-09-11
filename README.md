# Azure Cloud Infrastructure Comparison - IaaS vs PaaS

Comparaison des modèles d'infrastructure cloud IaaS et PaaS sur Microsoft Azure avec implémentation complète IaC.

## Technologies

- **Terraform** - Infrastructure as Code
- **Ansible** - Configuration management  
- **Docker** - Application containerization
- **Azure** - Cloud platform (VMs, Web Apps)
- **GitHub Actions** - CI/CD

## Structure

```
├── project-context.yaml    # Configuration complète du projet
├── terraform/
│   ├── iaas/             # Infrastructure IaaS
│   └── paas/             # Infrastructure PaaS
├── ansible/              # Playbooks Ansible
├── docker/               # Configuration Docker
└── scripts/              # Scripts utilitaires
```

## Déploiement

```bash
# IaaS
cd terraform/iaas
terraform init && terraform apply

# PaaS  
cd terraform/paas
terraform init && terraform apply
```

## Objectifs

- Déployer une application sur Azure (IaaS + PaaS)
- Comparer performances, coûts et scalabilité
- Automatiser le déploiement complet
- Tests de stress automatisés

Voir `project-context.yaml` pour la configuration détaillée.
