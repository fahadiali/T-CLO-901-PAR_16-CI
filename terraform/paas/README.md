# PaaS stack (Azure App Service + ACR)

## Prérequis
- Terraform >= 1.5
- Azure CLI (`az login` + subscription sélectionnée)
- Droits sur le Resource Group existant (par défaut: `rg-par_16`)

## Déploiement local
```bash
cd terraform/paas
terraform init
terraform apply -auto-approve   -var resource_group_name="rg-par_16"   -var prefix="terracloud"   -var image_name="sample-app"   -var image_tag="latest"
```

> L'image utilisée doit exister dans l'ACR créé au même moment. Utilisez le pipeline GitHub Actions `ci-paas` pour construire et pousser l'image à partir de `sample-app-master/`.

## Variables utiles
- `resource_group_name`: RG cible (existant)
- `plan_sku`: B1 (économe) ou P1v3 (prod)
- `image_name` / `image_tag`: image docker à déployer
- `container_port`: port exposé par votre image (défaut 80)

## Tests de charge (k6)
```bash
# après déploiement, récupérez l'URL
export APP_URL="https://<webapp>.azurewebsites.net/"
k6 run scripts/k6-smoke.js
```
