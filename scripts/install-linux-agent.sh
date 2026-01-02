#!/bin/bash

# Script d'installation automatique de l'agent Zabbix sur Ubuntu
# Auteur: EL MOUTAOUAKIL Abdellah
# Date: 2026-01-02

# Configuration
ZABBIX_SERVER_IP="52.207.237.42"  # Nouvelle IP après redémarrage AWS
HOSTNAME="EL-MOUTAOUAKIL-Linux-Client"

echo "🚀 Installation de l'agent Zabbix sur Ubuntu..."

# Mise à jour du système
echo "📦 Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

# Téléchargement et installation du repository Zabbix
echo "📥 Téléchargement du repository Zabbix..."
cd /tmp
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb

echo "📦 Installation du repository..."
sudo dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
sudo apt update

# Installation de l'agent Zabbix
echo "⬇️ Installation de l'agent Zabbix..."
sudo apt install zabbix-agent -y

# Sauvegarde du fichier de configuration original
echo "💾 Sauvegarde de la configuration originale..."
sudo cp /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.backup

# Configuration de l'agent
echo "⚙️ Configuration de l'agent Zabbix..."
sudo tee /etc/zabbix/zabbix_agentd.conf > /dev/null << EOF
# Configuration de l'agent Zabbix
# Projet: AWS Zabbix Monitoring
# Auteur: EL MOUTAOUAKIL Abdellah

PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=${ZABBIX_SERVER_IP}
ServerActive=${ZABBIX_SERVER_IP}
Hostname=${HOSTNAME}
Include=/etc/zabbix/zabbix_agentd.d/*.conf

# Paramètres de performance
StartAgents=3
Timeout=3
UnsafeUserParameters=0
AllowRoot=0

# Paramètres de buffer
BufferSend=5
BufferSize=100

# Paramètres réseau
ListenPort=10050
ListenIP=0.0.0.0

# User parameters pour monitoring custom
UserParameter=custom.ping[*],ping -c 1 \$1 | grep -c "1 received"
UserParameter=custom.disk.free[*],df -h \$1 | awk 'NR==2 {print \$4}'
EOF

# Redémarrage et activation du service
echo "🔄 Redémarrage du service Zabbix Agent..."
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent

# Vérification du statut
echo "✅ Vérification du statut du service..."
sudo systemctl status zabbix-agent --no-pager

# Test de connectivité
echo "🔍 Test de connectivité vers le serveur Zabbix..."
telnet ${ZABBIX_SERVER_IP} 10051 || echo "⚠️ Impossible de se connecter au serveur Zabbix"

# Affichage des informations
echo ""
echo "🎉 Installation terminée !"
echo "========================================"
echo "Serveur Zabbix: ${ZABBIX_SERVER_IP}"
echo "Hostname: ${HOSTNAME}"
echo "Port d'écoute: 10050"
echo "Logs: /var/log/zabbix/zabbix_agentd.log"
echo "Configuration: /etc/zabbix/zabbix_agentd.conf"
echo "========================================"
echo ""
echo "📝 Prochaines étapes:"
echo "1. Ajouter cet hôte dans l'interface Zabbix"
echo "2. Vérifier que le statut ZBX est vert"
echo "3. Configurer les templates de monitoring"
echo ""

# Test final
echo "🧪 Test de l'agent..."
sudo zabbix_agentd -t agent.ping
sudo zabbix_agentd -t agent.version

echo "✨ Script terminé avec succès !"