# Documentation : Configuration Agent Linux

## 🐧 Installation et Configuration de l'Agent Zabbix sur Ubuntu

### Connexion au client Linux

```bash
# Se connecter à l'instance Linux Client via SSH
ssh -i "EL-MOUTAOUAKIL-ABDELLAH-ZABBIX-SSH-KEY.pem" ubuntu@3.83.80.130
```

## Méthode 1 : Installation automatisée

### Utilisation du script automatique

```bash
# Télécharger le script d'installation
wget https://raw.githubusercontent.com/votre-username/aws-zabbix-monitoring/main/scripts/install-linux-agent.sh

# Rendre le script exécutable
chmod +x install-linux-agent.sh

# Éditer les variables si nécessaire
nano install-linux-agent.sh
# Modifier ZABBIX_SERVER_IP si différent de 13.221.240.167

# Exécuter le script
./install-linux-agent.sh
```

📸 **Figure 12** : Exécution du script d'installation automatique

## Méthode 2 : Installation manuelle

### Étape 1 : Mise à jour du système

```bash
# Mise à jour des paquets
sudo apt update && sudo apt upgrade -y
```

### Étape 2 : Installation du repository Zabbix

```bash
# Téléchargement du package de repository
cd /tmp
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb

# Installation du repository
sudo dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
sudo apt update
```

### Étape 3 : Installation de l'agent Zabbix

```bash
# Installation de l'agent
sudo apt install zabbix-agent -y

# Vérification de l'installation
zabbix_agentd --version
```

### Étape 4 : Configuration de l'agent

```bash
# Sauvegarde de la configuration originale
sudo cp /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.backup

# Édition du fichier de configuration
sudo nano /etc/zabbix/zabbix_agentd.conf
```

### Configuration personnalisée

```bash
# Paramètres principaux à modifier
Server=13.221.240.167
ServerActive=13.221.240.167
Hostname=EL-MOUTAOUAKIL-Linux-Client

# Ou utiliser le fichier de configuration complet
sudo wget -O /etc/zabbix/zabbix_agentd.conf https://raw.githubusercontent.com/votre-username/aws-zabbix-monitoring/main/configs/zabbix_agentd.conf.linux
```

📸 **Figure 13** : Configuration du fichier zabbix_agentd.conf Linux

### Étape 5 : Démarrage du service

```bash
# Redémarrage et activation du service
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent

# Vérification du statut
sudo systemctl status zabbix-agent
```

## Configuration avancée

### User Parameters personnalisés

```bash
# Créer un fichier pour les paramètres personnalisés
sudo nano /etc/zabbix/zabbix_agentd.d/custom.conf

# Ajouter des paramètres spécialisés
UserParameter=custom.system.temperature,sensors | grep "Core 0" | awk '{print $3}' | cut -c2-3 2>/dev/null || echo "0"
UserParameter=custom.docker.containers,docker ps -q | wc -l 2>/dev/null || echo "0"
UserParameter=custom.nginx.status,systemctl is-active nginx 2>/dev/null || echo "inactive"

# Redémarrer l'agent pour appliquer
sudo systemctl restart zabbix-agent
```

### Configuration réseau

```bash
# Vérifier les ports ouverts
sudo ss -tlnp | grep 10050

# Test de connectivité vers le serveur Zabbix
telnet 13.221.240.167 10051

# Configuration du pare-feu (si nécessaire)
sudo ufw allow 10050/tcp
sudo ufw allow from 13.221.240.167 to any port 10050
```

## Tests et validation

### Test de fonctionnement local

```bash
# Test des items de base
sudo zabbix_agentd -t agent.ping
sudo zabbix_agentd -t agent.version
sudo zabbix_agentd -t system.uptime

# Test des user parameters
sudo zabbix_agentd -t custom.cpu.usage
sudo zabbix_agentd -t custom.memory.usage
```

### Test de communication avec le serveur

```bash
# Installation de zabbix_get pour les tests
sudo apt install zabbix-get -y

# Tests depuis le serveur Zabbix (à exécuter sur le serveur)
# zabbix_get -s 3.83.80.130 -k agent.ping
# zabbix_get -s 3.83.80.130 -k system.uptime
```

## Surveillance des logs

### Monitoring en temps réel

```bash
# Surveiller les logs de l'agent
sudo tail -f /var/log/zabbix/zabbix_agentd.log

# Surveiller les logs système pour les erreurs
sudo journalctl -f -u zabbix-agent
```

### Analyse des erreurs courantes

```bash
# Vérifier les erreurs de connectivité
sudo grep -i error /var/log/zabbix/zabbix_agentd.log

# Vérifier les timeouts
sudo grep -i timeout /var/log/zabbix/zabbix_agentd.log
```

## Configuration dans l'interface Zabbix

### Ajout de l'hôte dans Zabbix Web

1. **Configuration > Hosts > Create host**
2. **Paramètres de l'hôte** :

   - **Host name** : `EL-MOUTAOUAKIL-Linux-Client`
   - **Visible name** : `Linux Client - Ubuntu 22.04`
   - **Groups** : `Linux servers`

3. **Interface** :

   - **Type** : Agent
   - **IP address** : `3.83.80.130`
   - **DNS name** : (laisser vide)
   - **Connect to** : IP
   - **Port** : `10050`

4. **Templates** :
   - Ajouter : `Linux by Zabbix agent`
   - Optionnel : `Generic SNMP`, `ICMP Ping`

📸 **Figure 14** : Configuration de l'hôte Linux dans l'interface Zabbix

### Vérification de la connectivité

1. **Monitoring > Hosts**
2. Vérifier que le statut ZBX est **vert**
3. **Latest data** > Rechercher l'hôte
4. Vérifier la réception des données

📸 **Figure 15** : Statut "Vert" (ZBX) du client Linux

## Monitoring personnalisé

### Templates spécialisés pour AWS EC2

```bash
# Créer des items pour monitoring AWS
UserParameter=aws.ec2.instance.id,curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unavailable"
UserParameter=aws.ec2.instance.type,curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo "unavailable"
UserParameter=aws.ec2.availability.zone,curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo "unavailable"
```

### Monitoring des applications

```bash
# Monitoring Apache (si installé)
UserParameter=apache.status,systemctl is-active apache2 2>/dev/null || echo "inactive"
UserParameter=apache.processes,pgrep apache2 | wc -l

# Monitoring MySQL (si installé)
UserParameter=mysql.status,systemctl is-active mysql 2>/dev/null || echo "inactive"
UserParameter=mysql.processes,pgrep mysqld | wc -l

# Monitoring Docker (si installé)
UserParameter=docker.status,systemctl is-active docker 2>/dev/null || echo "inactive"
UserParameter=docker.containers.running,docker ps -q | wc -l 2>/dev/null || echo "0"
```

## Dépannage

### Problèmes courants

#### Agent ne démarre pas

```bash
# Vérifier les erreurs de configuration
sudo zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf -t

# Vérifier les permissions
sudo chown zabbix:zabbix /var/log/zabbix/zabbix_agentd.log
sudo chmod 644 /etc/zabbix/zabbix_agentd.conf

# Redémarrer avec debug
sudo zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf -f
```

#### Connectivité réseau

```bash
# Tester la connectivité réseau
ping 13.221.240.167
telnet 13.221.240.167 10051

# Vérifier les règles de pare-feu AWS Security Group
# Dans la console AWS EC2 > Security Groups
```

#### Items non supportés

```bash
# Tester manuellement un item
sudo zabbix_agentd -t system.cpu.load[all,avg1]

# Vérifier les user parameters
sudo zabbix_agentd -t custom.disk.free[/]
```

## Scripts utiles

### Script de vérification quotidienne

```bash
#!/bin/bash
# check-zabbix-agent.sh
echo "=== Vérification Agent Zabbix ==="
echo "Statut service: $(systemctl is-active zabbix-agent)"
echo "Dernière erreur: $(sudo tail -1 /var/log/zabbix/zabbix_agentd.log | grep -i error || echo 'Aucune')"
echo "Test ping: $(sudo zabbix_agentd -t agent.ping)"
echo "Connectivité serveur: $(timeout 5 bash -c '</dev/tcp/13.221.240.167/10051' && echo 'OK' || echo 'FAILED')"
```

### Script de réinstallation rapide

```bash
#!/bin/bash
# reinstall-agent.sh
sudo systemctl stop zabbix-agent
sudo apt remove zabbix-agent -y
sudo rm -rf /etc/zabbix
wget -O install-linux-agent.sh https://raw.githubusercontent.com/votre-username/aws-zabbix-monitoring/main/scripts/install-linux-agent.sh
chmod +x install-linux-agent.sh
./install-linux-agent.sh
```

## ✅ Points de contrôle

- [ ] Repository Zabbix installé
- [ ] Agent Zabbix installé et configuré
- [ ] Service démarré et activé
- [ ] Communication avec le serveur établie
- [ ] Hôte ajouté dans l'interface Zabbix
- [ ] Templates appliqués
- [ ] Données collectées visibles
- [ ] User parameters fonctionnels
- [ ] Logs sans erreur
- [ ] Tests de connectivité réussis
