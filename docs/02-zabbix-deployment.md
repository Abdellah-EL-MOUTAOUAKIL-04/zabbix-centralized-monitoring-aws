# Documentation : Déploiement Zabbix Server

## 9️⃣ Installation de Docker et Docker Compose

### Connexion au serveur Zabbix

```bash
# Se connecter à l'instance Zabbix Server via SSH
ssh -i "EL-MOUTAOUAKIL-ABDELLAH-ZABBIX-SSH-KEY.pem" ubuntu@13.221.240.167
```

### Installation des dépendances

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation de Docker
sudo apt install docker.io docker-compose -y

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker ubuntu

# Démarrage et activation de Docker
sudo systemctl start docker
sudo systemctl enable docker

# Vérification de l'installation
docker --version
docker-compose --version
```

### Préparation de l'environnement

```bash
# Créer un répertoire pour Zabbix
mkdir ~/zabbix && cd ~/zabbix

# Télécharger le fichier docker-compose.yml depuis le repository
wget https://raw.githubusercontent.com/votre-username/aws-zabbix-monitoring/main/docker/zabbix-server/docker-compose.yml

# Ou créer le fichier manuellement
nano docker-compose.yml
```

## 🔟 Déploiement des conteneurs Zabbix

### Démarrage des services

```bash
# Démarrer les conteneurs en arrière-plan
docker-compose up -d

# Vérifier que tous les conteneurs fonctionnent
docker-compose ps

# Vérifier les logs
docker-compose logs zabbix-server
docker-compose logs zabbix-web
docker-compose logs zabbix-db
```

📸 **Figure 9** : Conteneurs Zabbix en cours d'exécution

### Vérification des services

```bash
# Vérifier les ports ouverts
sudo netstat -tlnp | grep -E ":(80|10051|5432)"

# Test de connectivité interne
docker exec zabbix-server zabbix_server -R config_cache_reload

# Vérifier les logs pour les erreurs
docker logs zabbix-server | tail -20
```

## 1️⃣1️⃣ Configuration initiale Zabbix

### Accès à l'interface Web

1. Ouvrir un navigateur
2. Aller à : `http://13.221.240.167`
3. **Login** : `Admin`
4. **Password** : `zabbix`

📸 **Figure 10** : Interface de connexion Zabbix réussie

### Configuration initiale

1. **Administration > General > GUI**

   - Default language : `English (en_US)`
   - Default theme : `Blue theme`
   - Default time zone : `Europe/Paris`

2. **Administration > Users > Admin**
   - Modifier le mot de passe par défaut
   - Ajouter votre email pour les notifications

### Configuration des notifications (optionnel)

```bash
# Configuration SMTP pour les alertes email
# Dans l'interface Web : Administration > Media types > Email
```

## 1️⃣2️⃣ Optimisation et Sécurité

### Configuration de performance

```bash
# Éditer le docker-compose.yml pour optimiser
cd ~/zabbix
nano docker-compose.yml

# Ajouter des variables d'environnement pour le serveur Zabbix
ZBX_CACHESIZE=64M
ZBX_HISTORYCACHESIZE=16M
ZBX_HISTORYINDEXCACHESIZE=4M
ZBX_TRENDCACHESIZE=4M
ZBX_VALUECACHESIZE=8M
```

### Sauvegarde automatique

```bash
# Créer un script de sauvegarde
wget https://raw.githubusercontent.com/votre-username/aws-zabbix-monitoring/main/scripts/backup-zabbix.sh

# Rendre le script exécutable
chmod +x backup-zabbix.sh

# Configurer une tâche cron pour sauvegarde quotidienne
crontab -e
# Ajouter : 0 2 * * * /home/ubuntu/backup-zabbix.sh
```

### Sécurisation

```bash
# Changer le mot de passe de la base de données
# Modifier docker-compose.yml avec un mot de passe fort

# Configurer HTTPS (optionnel)
# Installer certbot pour Let's Encrypt
sudo apt install certbot -y
```

## 1️⃣3️⃣ Surveillance du serveur Zabbix

### Monitoring des conteneurs

```bash
# Surveiller l'utilisation des ressources
docker stats

# Surveiller les logs en temps réel
docker-compose logs -f zabbix-server

# Vérifier l'espace disque
df -h
```

### Scripts de maintenance

```bash
# Script de redémarrage automatique
#!/bin/bash
# restart-zabbix.sh
cd /home/ubuntu/zabbix
docker-compose restart

# Script de vérification de santé
#!/bin/bash
# health-check.sh
if ! curl -s http://localhost >/dev/null; then
    echo "Zabbix Web interface down, restarting..."
    cd /home/ubuntu/zabbix
    docker-compose restart zabbix-web
fi
```

## 1️⃣4️⃣ Dépannage

### Problèmes courants

#### Conteneur qui ne démarre pas

```bash
# Vérifier les logs
docker-compose logs nom_du_conteneur

# Vérifier l'espace disque
df -h

# Nettoyer les conteneurs inutiles
docker system prune -f
```

#### Base de données inaccessible

```bash
# Se connecter à la base de données
docker exec -it zabbix-db psql -U zabbix -d zabbix

# Vérifier les connexions
docker exec zabbix-db psql -U zabbix -d zabbix -c "SELECT count(*) FROM sessions;"
```

#### Interface Web lente

```bash
# Optimiser PHP
docker exec zabbix-web sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/*/apache2/php.ini

# Redémarrer l'interface Web
docker-compose restart zabbix-web
```

### Commandes de diagnostic

```bash
# Vérifier la connectivité réseau
docker network ls
docker network inspect zabbix_zabbix-net

# Tester la connectivité entre conteneurs
docker exec zabbix-server ping zabbix-db
docker exec zabbix-web ping zabbix-server

# Vérifier les performances
docker exec zabbix-server zabbix_server -R diaginfo
```

## ✅ Points de contrôle

- [ ] Docker et Docker Compose installés
- [ ] Fichier docker-compose.yml configuré
- [ ] Conteneurs Zabbix démarrés
- [ ] Interface Web accessible
- [ ] Connexion administrative réussie
- [ ] Configuration initiale terminée
- [ ] Script de sauvegarde configuré
- [ ] Monitoring des ressources actif

📸 **Figure 11** : Tableau de bord principal Zabbix opérationnel
