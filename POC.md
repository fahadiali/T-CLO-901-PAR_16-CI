# Proof of Concept (POC)
## Azure Cloud Infrastructure Comparison - IaaS vs PaaS

**Projet :** T-CLO-901-PAR_16  
**Auteur :** Étudiant Epitech  
**Date :** Septembre 2024  
**Version :** 1.0

---

## 1. Introduction et Motivation

### 1.1 Pourquoi ce projet ?
En tant qu'étudiant en cloud computing, j'ai souvent entendu parler des différences entre IaaS et PaaS, mais j'ai du mal à comprendre concrètement leurs implications pratiques. Ce projet me permettra de :

- **Comprendre réellement** ce que signifie "Infrastructure as a Service" vs "Platform as a Service"
- **Expérimenter** avec les outils cloud modernes (Terraform, Ansible, Docker)
- **Comparer objectivement** les deux approches sur des critères concrets
- **Apprendre** l'Infrastructure as Code de manière pratique

### 1.2 Mes questions initiales
- Qu'est-ce qui différencie vraiment IaaS et PaaS au niveau technique ?
- Quel modèle est le plus adapté pour une application web classique ?
- Comment les coûts évoluent-ils selon l'approche choisie ?
- Est-ce que l'automatisation est plus complexe avec l'une ou l'autre ?

### 1.3 Approche d'apprentissage
Je vais commencer par **IaaS** car c'est plus proche de ce que je connais (serveurs traditionnels), puis explorer **PaaS** pour comprendre les différences. L'objectif est de faire des erreurs, apprendre, et documenter le processus.

---

## 2. Focus IaaS - Mon Point de Départ

### 2.1 Pourquoi commencer par IaaS ?
Je choisis de commencer par IaaS car :
- C'est plus proche des serveurs traditionnels que je connais
- Je peux contrôler chaque aspect de l'infrastructure
- C'est plus facile de comprendre ce qui se passe "sous le capot"
- Je peux apprendre Azure progressivement

### 2.2 Architecture IaaS - Version Simplifiée
```
┌─────────────────────────────────────────────────────────┐
│                    Azure Resource Group                 │
│                      (Mon environnement)               │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Virtual Network                        │ │
│  │  ┌─────────────────────────────────────────────────┐ │ │
│  │  │              Subnet                             │ │ │
│  │  │  ┌─────────────┐  ┌─────────────┐             │ │ │
│  │  │  │     VM 1    │  │     VM 2    │             │ │ │
│  │  │  │  (Ubuntu)   │  │  (Ubuntu)   │             │ │ │
│  │  │  │   Docker    │  │   Docker    │             │ │ │
│  │  │  └─────────────┘  └─────────────┘             │ │ │
│  │  └─────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Storage Account                         │ │
│  │            (Pour les données)                       │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 2.3 Mes Questions sur IaaS
- **Combien de VMs** ai-je vraiment besoin ? (Je pense commencer avec 2)
- **Quelle taille** de VM choisir ? (Je ne veux pas payer trop cher)
- **Comment** gérer la haute disponibilité avec peu de ressources ?
- **Est-ce que** je peux utiliser des VMs plus petites et les faire scaler ?

### 2.4 Composants IaaS - Ce que je vais apprendre
**Virtual Machines :**
- Ubuntu 20.04 LTS (ce que je connais le mieux)
- Taille : Standard_B1s ou B2s (pas trop cher pour commencer)
- Configuration : Docker pré-installé

**Virtual Network :**
- Un seul subnet pour simplifier
- Network Security Groups pour la sécurité
- Public IP pour accéder aux VMs

**Storage Account :**
- Pour stocker les données de l'application
- Backup des configurations

**Load Balancer :**
- Je ne sais pas encore si j'en ai besoin avec 2 VMs
- À tester selon les performances

---

## 3. PaaS - Ce que je vais découvrir ensuite

### 3.1 Pourquoi explorer PaaS après IaaS ?
Une fois que j'aurai maîtrisé IaaS, je veux comprendre :
- Comment PaaS simplifie le déploiement
- Si c'est vraiment plus facile à gérer
- Quels sont les compromis (moins de contrôle vs plus de simplicité)

### 3.2 Architecture PaaS - Version Simplifiée
```
┌─────────────────────────────────────────────────────────┐
│                    Azure Resource Group                 │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐ │
│  │              App Service Plan                       │ │
│  │            (Je ne gère pas les VMs)                │ │
│  └─────────────────────────────────────────────────────┘ │
│                          │                               │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Azure Web App                          │ │
│  │            (Mon application Docker)                 │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Application Insights                   │ │
│  │            (Monitoring automatique)                 │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 3.3 Mes Questions sur PaaS
- **Est-ce que** je perds vraiment le contrôle avec PaaS ?
- **Comment** fonctionne le scaling automatique ?
- **Est-ce que** c'est plus cher que mes VMs ?
- **Peut-on** vraiment déployer la même application ?

---

## 4. Mes Outils - Ce que je vais apprendre

### 4.1 Terraform - Infrastructure as Code
**Pourquoi Terraform ?**
- Je veux comprendre comment automatiser la création d'infrastructure
- C'est ce qu'on utilise en entreprise
- Je peux recréer mon environnement facilement

**Ce que je vais apprendre :**
- Créer des VMs Azure avec du code
- Gérer les réseaux et la sécurité
- Comprendre les providers et resources
- Gérer l'état (state) de mon infrastructure

**Mes questions :**
- Comment éviter de perdre mes ressources ?
- Est-ce que je peux tester avant d'appliquer ?
- Comment gérer les différents environnements ?

### 4.2 Ansible - Configuration Management
**Pourquoi Ansible ?**
- Je veux automatiser la configuration de mes VMs
- C'est plus simple que d'écrire des scripts bash
- Je peux réutiliser mes configurations

**Ce que je vais apprendre :**
- Installer Docker sur mes VMs
- Configurer les services
- Déployer mon application
- Gérer les inventaires de machines

**Mes questions :**
- Comment éviter de casser mes VMs ?
- Est-ce que je peux tester mes playbooks ?
- Comment gérer les mots de passe et secrets ?

### 4.3 Docker - Containerisation
**Pourquoi Docker ?**
- Je veux que mon application fonctionne pareil partout
- C'est plus facile de déployer
- Je peux tester localement avant de déployer

**Ce que je vais apprendre :**
- Créer un Dockerfile pour mon app
- Utiliser docker-compose pour le développement
- Optimiser la taille de mes images
- Gérer les volumes et réseaux

**Mes questions :**
- Comment optimiser mes images Docker ?
- Est-ce que je peux débugger facilement ?
- Comment gérer les données persistantes ?

### 4.4 GitHub Actions - CI/CD
**Pourquoi GitHub Actions ?**
- Je veux automatiser mes déploiements
- C'est intégré avec GitHub
- Je peux tester à chaque commit

**Ce que je vais apprendre :**
- Créer des workflows de déploiement
- Tester automatiquement mon code
- Déployer sur Azure automatiquement
- Gérer les secrets et variables

**Mes questions :**
- Comment éviter de déployer du code cassé ?
- Est-ce que je peux rollback facilement ?
- Comment gérer les environnements multiples ?

---

## 5. Mon Application de Test

### 5.1 Pourquoi cette application ?
Je vais créer une application simple mais réaliste pour tester mes déploiements :
- **Pas trop complexe** : Je veux me concentrer sur l'infrastructure
- **Assez réaliste** : Pour avoir des métriques intéressantes
- **Facile à débugger** : Quand ça ne marche pas

### 5.2 Spécifications de l'application
**Type** : API REST simple
- **Framework** : Node.js avec Express (ce que je connais)
- **Base de données** : PostgreSQL (ou SQLite pour simplifier)
- **Fonctionnalités** :
  - CRUD pour des utilisateurs
  - Authentification basique
  - Health check endpoint
  - Logging simple

### 5.3 Ce que je vais mesurer
**Performance :**
- Temps de réponse des API
- Nombre de requêtes par seconde
- Utilisation CPU/RAM

**Coût :**
- Coût par heure de fonctionnement
- Coût par requête
- Coût de maintenance

**Facilité :**
- Temps de déploiement
- Temps de redéploiement
- Complexité de la configuration

---

## 6. Mon Plan d'Apprentissage

### 6.1 Phase 1 : Setup et Premiers Pas (Semaine 1-2)
**Objectif** : Comprendre Azure et installer les outils
- [ ] Créer mon compte Azure et comprendre l'interface
- [ ] Installer Terraform, Ansible, Docker sur ma machine
- [ ] Créer ma première VM Azure manuellement
- [ ] Développer mon application de test simple
- [ ] Tester Docker localement

**Mes défis :**
- Comprendre les concepts Azure (Resource Groups, VMs, etc.)
- Installer les outils sans casser ma machine
- Créer une application qui fonctionne

### 6.2 Phase 2 : IaaS avec Terraform (Semaine 3-4)
**Objectif** : Automatiser la création d'infrastructure IaaS
- [ ] Créer mon premier fichier Terraform
- [ ] Déployer 2 VMs avec Terraform
- [ ] Configurer le réseau et la sécurité
- [ ] Déployer mon application avec Ansible
- [ ] Tester que tout fonctionne

**Mes défis :**
- Comprendre la syntaxe Terraform
- Gérer les erreurs de configuration
- Ne pas perdre mes ressources Azure

### 6.3 Phase 3 : PaaS avec Azure Web Apps (Semaine 5-6)
**Objectif** : Découvrir PaaS et comparer avec IaaS
- [ ] Créer un App Service Plan avec Terraform
- [ ] Déployer mon application sur Azure Web Apps
- [ ] Configurer le monitoring automatique
- [ ] Tester le scaling automatique
- [ ] Comparer avec mon déploiement IaaS

**Mes défis :**
- Comprendre les concepts PaaS
- Adapter mon application pour PaaS
- Comparer objectivement les deux approches

### 6.4 Phase 4 : Tests et Mesures (Semaine 7-8)
**Objectif** : Mesurer les performances et coûts
- [ ] Créer des tests de charge simples
- [ ] Mesurer les performances IaaS vs PaaS
- [ ] Calculer les coûts de chaque approche
- [ ] Documenter mes découvertes
- [ ] Identifier les avantages/inconvénients

**Mes défis :**
- Créer des tests réalistes
- Interpréter les résultats
- Calculer les coûts correctement

### 6.5 Phase 5 : Automatisation (Semaine 9-10)
**Objectif** : Automatiser les déploiements
- [ ] Créer des workflows GitHub Actions
- [ ] Automatiser les tests
- [ ] Automatiser les déploiements
- [ ] Gérer les environnements multiples
- [ ] Documenter les processus

**Mes défis :**
- Comprendre GitHub Actions
- Gérer les secrets et variables
- Créer des workflows fiables

### 6.6 Phase 6 : Documentation et Conclusion (Semaine 11-12)
**Objectif** : Documenter mes apprentissages
- [ ] Rédiger un guide de déploiement
- [ ] Créer un rapport de comparaison
- [ ] Documenter les erreurs et solutions
- [ ] Préparer une présentation
- [ ] Faire des recommandations

**Mes défis :**
- Organiser mes connaissances
- Présenter clairement mes découvertes
- Faire des recommandations pertinentes

---

## 7. Mes Tests - Comment je vais comparer

### 7.1 Tests de Performance - Version Étudiant
**Outils que je vais utiliser :**
- **Apache Bench (ab)** : Simple et efficace pour commencer
- **Artillery** : Plus avancé, je l'apprendrai si j'ai le temps
- **curl et scripts bash** : Pour des tests basiques

**Scénarios réalistes :**
- **Test basique** : 10-50 utilisateurs simultanés (réaliste pour un étudiant)
- **Test de stress** : 100+ utilisateurs (pour voir les limites)
- **Test de durée** : 30 minutes (pas 2 heures, je n'ai pas le temps)

### 7.2 Ce que je vais mesurer
**Performance :**
- Temps de réponse moyen
- Nombre de requêtes par seconde
- Taux d'erreur
- Temps de démarrage de l'application

**Coût :**
- Coût par heure de fonctionnement
- Coût par requête (approximatif)
- Coût de maintenance (temps passé)

**Facilité d'utilisation :**
- Temps pour déployer
- Temps pour redéployer
- Complexité de la configuration
- Facilité de debugging

---

## 8. Mes Environnements - Version Étudiant

### 8.1 Environnements que je vais créer
**Development :**
- 1 VM Basic (pas cher)
- Arrêt automatique le soir (pour économiser)
- Monitoring basique (juste pour voir si ça marche)

**Staging :**
- 2 VMs Standard (pour tester la haute disponibilité)
- Arrêt automatique le soir
- Monitoring un peu plus poussé

**Production :**
- Je ne sais pas encore si j'en ai besoin
- Probablement juste pour les tests finaux
- Pas de fonctionnement 24/7 (trop cher)

### 8.2 Gestion des états Terraform
**Ce que je vais apprendre :**
- Comment sauvegarder l'état de mon infrastructure
- Comment éviter de perdre mes ressources
- Comment gérer plusieurs environnements

**Mes questions :**
- Est-ce que je peux utiliser un Storage Account Azure ?
- Comment éviter que mes camarades cassent mon infrastructure ?
- Est-ce que je peux partager l'état entre mes environnements ?

---

## 9. Mes Risques et Comment les Gérer

### 9.1 Risques Techniques - Version Étudiant
**Risque** : Je vais exploser mon budget Azure  
**Comment je gère** : 
- Je vais surveiller mes coûts tous les jours
- J'arrête tout le soir automatiquement
- Je commence avec des VMs très petites

**Risque** : Je vais casser mon infrastructure  
**Comment je gère** :
- Je teste tout localement d'abord
- Je sauvegarde mes configurations
- Je documente mes erreurs

**Risque** : Je ne vais pas comprendre les outils  
**Comment je gère** :
- Je commence simple et j'ajoute de la complexité
- Je cherche de l'aide sur internet
- Je demande de l'aide aux autres étudiants

### 9.2 Risques Opérationnels
**Risque** : Je n'aurai pas le temps de tout faire  
**Comment je gère** :
- Je priorise les parties importantes
- Je commence par IaaS (plus simple pour moi)
- Je documente ce que je fais au fur et à mesure

**Risque** : Je vais me perdre dans la complexité  
**Comment je gère** :
- Je fais des étapes simples
- Je teste chaque étape avant de passer à la suivante
- Je demande de l'aide quand je suis bloqué

---

## 10. Comment je vais savoir si j'ai réussi

### 10.1 Critères de Succès - Version Étudiant
**Technique :**
- [ ] Je peux déployer mon application sur IaaS
- [ ] Je peux déployer mon application sur PaaS
- [ ] Mes deux déploiements fonctionnent
- [ ] Je peux mesurer les performances des deux
- [ ] Je peux comparer les coûts

**Apprentissage :**
- [ ] Je comprends la différence entre IaaS et PaaS
- [ ] Je sais utiliser Terraform pour créer de l'infrastructure
- [ ] Je sais utiliser Ansible pour configurer des machines
- [ ] Je sais containeriser une application avec Docker
- [ ] Je peux expliquer mes choix à quelqu'un d'autre

### 10.2 Ce que je veux apprendre
- **Comprendre** vraiment ce que signifie "cloud computing"
- **Savoir** choisir entre IaaS et PaaS selon le contexte
- **Maîtriser** les outils modernes d'infrastructure
- **Pouvoir** déployer une application de A à Z
- **Être capable** de faire des recommandations basées sur des faits

---

## 11. Ce que je vais livrer

### 11.1 Documentation
- **Guide de déploiement IaaS** : Comment j'ai fait, étape par étape
- **Guide de déploiement PaaS** : Ce que j'ai appris
- **Rapport de comparaison** : Mes découvertes et conclusions
- **Journal d'apprentissage** : Mes erreurs et comment je les ai résolues
- **Recommandations** : Ce que je conseillerais à quelqu'un d'autre

### 11.2 Code et Scripts
- **Fichiers Terraform** : Mon infrastructure en code
- **Playbooks Ansible** : Mes configurations automatisées
- **Dockerfiles** : Mes applications containerisées
- **Scripts de test** : Mes tests de performance
- **Workflows GitHub Actions** : Mon automatisation

### 11.3 Mesures et Résultats
- **Métriques de performance** : Temps de réponse, throughput, etc.
- **Analyse des coûts** : Combien ça coûte vraiment
- **Comparaison** : IaaS vs PaaS sur différents critères
- **Recommandations** : Quand utiliser quoi

---

## 12. Conclusion - Mon Apprentissage

Ce POC est avant tout un **projet d'apprentissage** pour moi. Je veux comprendre concrètement ce que signifie "cloud computing" et comment choisir entre IaaS et PaaS.

**Mes objectifs :**
- **Apprendre** les outils modernes d'infrastructure
- **Comprendre** les différences pratiques entre IaaS et PaaS
- **Savoir** faire des choix éclairés
- **Pouvoir** déployer une application de A à Z

**Ce que j'espère découvrir :**
- Est-ce que PaaS est vraiment plus simple ?
- Est-ce que IaaS donne vraiment plus de contrôle ?
- Quel modèle coûte le moins cher ?
- Quel modèle est le plus facile à maintenir ?

Le succès de ce POC ne dépend pas seulement du résultat final, mais aussi du **processus d'apprentissage** et de ma capacité à **documenter mes découvertes**.

---

**Mes prochaines étapes :**
1. **Valider ce POC** avec l'intervenant
2. **Configurer Azure** et installer les outils
3. **Commencer par IaaS** (plus simple pour moi)
4. **Documenter** chaque étape de mon apprentissage
5. **Comparer** objectivement les deux approches
