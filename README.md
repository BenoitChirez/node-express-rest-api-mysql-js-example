# TP Final DevOps - Startup Lacets Connectés

Ce projet vise à mettre en place une infrastructure complète, automatisée et scalable pour le déploiement d'une API REST Node.js.

## 📁 Structure du Projet
```text
.
├── app/                        # Code source de l'API (cloné)
│   └── Dockerfile              # Optimisation de l'image
├── infrastructure/             # Automatisation de l'infra
│   ├── Vagrantfile             # Définition de la VM Debian
│   ├── inventory.ini           # Inventaire pour Ansible
│   ├── install_k3s.yaml        # Playbook d'installation K3s
│   └── setup_infra.sh          # Script d'orchestration global
└── README.md                   # Documentation (ce fichier)
```

---

## 🏗️ Partie 1 : Préparation de l'infrastructure

L'objectif était de créer une infrastructure "Disposable" (jetable) et reproductible.

### Choix techniques
- **Vagrant** : Utilisation d'une box `debian/bookworm64` configurée avec **2 Go de RAM** et **2 CPUs**.
- **Réseau** : Configuration d'une IP statique `192.168.56.10` sur un réseau privé (`private_network`) pour garantir une connectivité SSH stable.
- **Ansible** : Automatisation de l'installation de **K3s** (Kubernetes léger) de manière idempotente.

### Résolution de problèmes (Troubleshooting)
1. **Conflit de nom VirtualBox** : Retrait du nom fixe `vb.name` pour laisser Vagrant gérer l'unicité et éviter l'erreur `VERR_ALREADY_EXISTS`.
2. **Droits SSH (WSL)** : Sous Windows/WSL, les clés SSH sur `/mnt/c` ont des droits trop larges (0777). La clé a été déplacée dans le système de fichiers natif Linux (`~/.ssh/keys/`) avec un `chmod 600` pour permettre la connexion Ansible.
3. **Fingerprint SSH** : Utilisation de `StrictHostKeyChecking=no` dans l'inventaire pour automatiser le déploiement sans intervention manuelle.

### Commandes pour déployer l'infra
```bash
cd infrastructure
chmod +x setup_infra.sh
./setup_infra.sh
```
*Vérification :* `vagrant ssh -c "sudo k3s kubectl get nodes"`

---


## 📦 Partie 2 : Conteneurisation de l'application

L'objectif était de créer une image Docker légère, sécurisée et prête pour la production.

### Choix d'optimisation (Dockerfile)
- **Image de base** : `node:20-alpine` pour réduire la taille de l'image (environ 160 Mo) et limiter la surface d'attaque.
- **Multi-stage build (logique)** : Utilisation de `npm install --production` pour exclure les dépendances de développement.
- **Gestion des processus** : L'application est lancée directement via `node server.js` (ou via le point d'entrée défini) pour une meilleure gestion des signaux système par Docker.

### Publication
L'image est hébergée sur Docker Hub et configurée pour l'architecture `amd64` (Linux) afin d'être compatible avec le cluster K3s.
- **Image** : `benoitchirez/api-lacets:v1`

---

## 🚀 Partie 3 : Orchestration avec Kubernetes

Le déploiement utilise Kubernetes (K3s) pour garantir la haute disponibilité et la scalabilité de l'API.

### Architecture des Manifests (Dossier /k8s)
- **Persistance (MySQL)** :
    - Un `PersistentVolumeClaim` (PVC) de **1Go** garantit que les données de la startup ne sont pas perdues en cas de redémarrage du Pod.
    - Le déploiement MySQL utilise ce volume monté sur `/var/lib/mysql`.
- **Scalabilité (HPA)** :
    - Un `HorizontalPodAutoscaler` surveille l'utilisation CPU.
    - Le nombre de Pods de l'API varie automatiquement entre **1 et 3 réplicas** selon la charge (seuil à 50% CPU).
- **Sécurité Réseau** :
    - Le service `api-lacet` est de type `ClusterIP`. L'API est donc exposée sur le **port 80** à l'intérieur du cluster mais reste **invisible de l'extérieur**.

### Commandes de déploiement
```bash
# Application de la configuration
vagrant ssh -c "sudo kubectl apply -f /vagrant/k8s/"
```

### Vérification du statut final
Le déploiement est validé avec les deux Pods en statut `Running` :
- `api-lacet-xxx` : Opérationnel après résolution automatique des dépendances (RESTARTS: 2 au démarrage pour attendre MySQL).
- `mysql-xxx` : Opérationnel et lié au volume persistant.

```bash
# Commande de vérification
vagrant ssh -c "sudo kubectl get pods,pvc,hpa"
```
```text
NAME                             READY   STATUS    RESTARTS
api-lacet-6d54f75689-lfxx6       1/1     Running   2
mysql-54fcb9488-x7sfj            1/1     Running   0
```

---