# Projet : Infrastructure Cloud de Supervision Centralisée sous AWS

## Déploiement de Zabbix conteneurisé pour le monitoring d'un parc hybride (Linux & Windows)

### 🎯 Objectif

Déployer une infrastructure de monitoring centralisée sur AWS en utilisant Zabbix (Docker) pour surveiller un parc hybride (Linux & Windows).

### 👨‍🎓 Informations du Projet

- **Étudiant** : EL MOUTAOUAKIL Abdellah
- **Encadrant** : Prof. Azeddine KHIAT
- **Année universitaire** : 2025/2026
- **Établissement** : ENSET Media

### 🏗️ Architecture Proposée

#### Infrastructure AWS

- **VPC** : 1 VPC avec un sous-réseau public (10.0.0.0/16)
- **Sécurité** : Security Groups autorisant les ports 80/443, 10050/10051, 3389, 22
- **Instances EC2** :
  - Serveur Zabbix : t3.large (Ubuntu 22.04)
  - Client Linux : t3.medium (Ubuntu 22.04)
  - Client Windows : t3.large (Windows Server)

#### Schéma d'Architecture

```
Internet
    |
[Internet Gateway]
    |
[VPC 10.0.0.0/16]
    |
[Subnet Public 10.0.1.0/24]
    |
    ├── Zabbix Server (52.207.237.42)
    ├── Linux Client (54.152.171.227)
    └── Windows Client (44.201.176.179)
```

### 📋 Prérequis

- Compte AWS avec accès Learner Lab
- Clé SSH pour l'accès aux instances
- Connaissance de base Docker et Zabbix

### 🚀 Déploiement

#### 1. Infrastructure AWS

Suivez les étapes dans [`docs/01-aws-infrastructure.md`](docs/01-aws-infrastructure.md)

#### 2. Installation Zabbix Server

```bash
# Cloner le repository
git clone https://github.com/votre-username/aws-zabbix-monitoring.git
cd aws-zabbix-monitoring

# Déployer Zabbix avec Docker
cd docker/zabbix-server
docker-compose up -d
```

#### 3. Configuration des Agents

- **Linux** : [`docs/03-linux-agent.md`](docs/03-linux-agent.md)
- **Windows** : [`docs/04-windows-agent.md`](docs/04-windows-agent.md)

### 📊 Accès à l'interface Zabbix

- **URL** : http://52.207.237.42
- **Login** : Admin
- **Password** : zabbix

### 📁 Structure du Projet

```
aws-zabbix-monitoring/
├── README.md
├── docs/
│   ├── 01-aws-infrastructure.md
│   ├── 02-zabbix-deployment.md
│   ├── 03-linux-agent.md
│   ├── 04-windows-agent.md
│   └── images/
├── docker/
│   └── zabbix-server/
│       └── docker-compose.yml
├── scripts/
│   ├── install-linux-agent.sh
│   ├── install-windows-agent.ps1
│   └── backup-zabbix.sh
├── configs/
│   ├── zabbix_agentd.conf.linux
│   ├── zabbix_agent2.conf.windows
│   └── zabbix-templates/
└── monitoring/
    ├── dashboards/
    └── alerting/
```

### 🔧 Scripts d'Installation Automatisés

- [`scripts/install-linux-agent.sh`](scripts/install-linux-agent.sh) - Installation automatique agent Linux
- [`scripts/install-windows-agent.ps1`](scripts/install-windows-agent.ps1) - Installation automatique agent Windows
- [`scripts/backup-zabbix.sh`](scripts/backup-zabbix.sh) - Sauvegarde de la configuration Zabbix

### 📈 Monitoring et Tableaux de Bord

- Surveillance CPU, RAM, disque
- Alertes automatiques
- Tableaux de bord personnalisés
- Historique des métriques

### 🔍 Dépannage

Consultez [`docs/troubleshooting.md`](docs/troubleshooting.md) pour les problèmes courants.

### ⚠️ Limitations AWS Learner Lab

- Instances limitées à t3.medium/t3.large
- Région us-east-1 uniquement
- Budget de 50$ à surveiller
- Arrêt automatique des labs

### 🔄 Mise à jour après redémarrage AWS

En cas de changement d'IPs après redémarrage du Learner Lab :

#### IPs actuelles (mise à jour 02/01/2026) :

- **Zabbix Server** : `52.207.237.42`
- **Linux Client** : `54.152.171.227`
- **Windows Client** : `44.201.176.179`

#### Procédure de mise à jour rapide :

1. **Serveur Zabbix** :

```bash
ssh -i "EL-MOUTAOUAKIL-ABDELLAH-ZABBIX-SSH-KEY.pem" ubuntu@NOUVELLE_IP_ZABBIX
cd ~/zabbix && docker-compose restart
```

2. **Client Linux** :

```bash
ssh -i "EL-MOUTAOUAKIL-ABDELLAH-ZABBIX-SSH-KEY.pem" ubuntu@NOUVELLE_IP_LINUX
sudo sed -i 's/Server=.*/Server=NOUVELLE_IP_ZABBIX/' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's/ServerActive=.*/ServerActive=NOUVELLE_IP_ZABBIX/' /etc/zabbix/zabbix_agentd.conf
sudo systemctl restart zabbix-agent
```

3. **Client Windows** (via RDP) :

```powershell
cd "C:\Program Files\Zabbix Agent 2"
(Get-Content zabbix_agent2.conf) -replace 'Server=.*', 'Server=NOUVELLE_IP_ZABBIX' | Set-Content zabbix_agent2.conf
(Get-Content zabbix_agent2.conf) -replace 'ServerActive=.*', 'ServerActive=NOUVELLE_IP_ZABBIX' | Set-Content zabbix_agent2.conf
Restart-Service "Zabbix Agent 2"
```

4. **Interface Zabbix** : Modifier les IPs des interfaces dans Configuration > Hosts

### 📄 Documentation Complète

Le rapport PDF complet avec captures d'écran est disponible dans le dossier [`docs/`](docs/).

### 🎬 Démonstration Vidéo

[Lien vers la vidéo de démonstration](lien-vers-votre-video)

---

**© 2026 - Projet de Cybersécurité ENSET Media**
