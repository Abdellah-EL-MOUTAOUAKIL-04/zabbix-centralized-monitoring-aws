#!/bin/bash

# Script de mise à jour rapide des IPs après redémarrage AWS Learner Lab
# Auteur: EL MOUTAOUAKIL Abdellah
# Date: 2026-01-02

# Couleurs pour le terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MISE À JOUR DES IPs APRÈS REDÉMARRAGE AWS ===${NC}"
echo -e "${YELLOW}Projet: Infrastructure Cloud de Supervision Centralisée${NC}"
echo -e "${BLUE}Auteur: EL MOUTAOUAKIL Abdellah${NC}"
echo ""

if [ $# -ne 3 ]; then
    echo -e "${RED}Usage: $0 <ZABBIX_SERVER_IP> <LINUX_CLIENT_IP> <WINDOWS_CLIENT_IP>${NC}"
    echo ""
    echo "Exemple:"
    echo "$0 52.207.237.42 54.152.171.227 44.201.176.179"
    echo ""
    echo "IPs actuelles (02/01/2026):"
    echo "- Zabbix Server: 52.207.237.42"
    echo "- Linux Client: 54.152.171.227"
    echo "- Windows Client: 44.201.176.179"
    exit 1
fi

ZABBIX_IP=$1
LINUX_IP=$2
WINDOWS_IP=$3

echo -e "${GREEN}Configuration avec les nouvelles IPs:${NC}"
echo -e "📟 Serveur Zabbix: ${BLUE}$ZABBIX_IP${NC}"
echo -e "🐧 Client Linux: ${BLUE}$LINUX_IP${NC}"
echo -e "🪟 Client Windows: ${BLUE}$WINDOWS_IP${NC}"
echo ""

echo -e "${YELLOW}=== PROCÉDURE DE MISE À JOUR ===${NC}"
echo ""

echo -e "${GREEN}1️⃣ SERVEUR ZABBIX:${NC}"
echo -e "   ${BLUE}ssh -i \"EL-MOUTAOUAKIL-ABDELLAH-ZABBIX-SSH-KEY.pem\" ubuntu@$ZABBIX_IP${NC}"
echo -e "   ${BLUE}cd ~/zabbix && docker-compose restart${NC}"
echo -e "   ${BLUE}docker-compose ps${NC}"
echo -e "   Test interface: ${GREEN}http://$ZABBIX_IP${NC}"
echo ""

echo -e "${GREEN}2️⃣ CLIENT LINUX:${NC}"
echo -e "   ${BLUE}ssh -i \"EL-MOUTAOUAKIL-ABDELLAH-ZABBIX-SSH-KEY.pem\" ubuntu@$LINUX_IP${NC}"
echo -e "   ${BLUE}sudo sed -i 's/Server=.*/Server=$ZABBIX_IP/' /etc/zabbix/zabbix_agentd.conf${NC}"
echo -e "   ${BLUE}sudo sed -i 's/ServerActive=.*/ServerActive=$ZABBIX_IP/' /etc/zabbix/zabbix_agentd.conf${NC}"
echo -e "   ${BLUE}sudo systemctl restart zabbix-agent${NC}"
echo -e "   ${BLUE}sudo systemctl status zabbix-agent${NC}"
echo ""

echo -e "${GREEN}3️⃣ CLIENT WINDOWS (RDP: $WINDOWS_IP:3389):${NC}"
echo -e "   ${BLUE}cd \"C:\\Program Files\\Zabbix Agent 2\"${NC}"
echo -e "   ${BLUE}(Get-Content zabbix_agent2.conf) -replace 'Server=.*', 'Server=$ZABBIX_IP' | Set-Content zabbix_agent2.conf${NC}"
echo -e "   ${BLUE}(Get-Content zabbix_agent2.conf) -replace 'ServerActive=.*', 'ServerActive=$ZABBIX_IP' | Set-Content zabbix_agent2.conf${NC}"
echo -e "   ${BLUE}Restart-Service \"Zabbix Agent 2\"${NC}"
echo -e "   ${BLUE}Get-Service \"Zabbix Agent 2\"${NC}"
echo ""

echo -e "${GREEN}4️⃣ INTERFACE ZABBIX (${BLUE}http://$ZABBIX_IP${NC}${GREEN}):${NC}"
echo -e "   ${BLUE}Configuration > Hosts${NC}"
echo -e "   ${BLUE}EL-MOUTAOUAKIL-Linux-Client > Interfaces > IP: $LINUX_IP${NC}"
echo -e "   ${BLUE}EL-MOUTAOUAKIL-Windows-Client > Interfaces > IP: $WINDOWS_IP${NC}"
echo ""

echo -e "${GREEN}5️⃣ TESTS DE CONNECTIVITÉ:${NC}"
echo -e "   ${BLUE}# Depuis le serveur Zabbix:${NC}"
echo -e "   ${BLUE}docker exec zabbix-server zabbix_get -s $LINUX_IP -k agent.ping${NC}"
echo -e "   ${BLUE}docker exec zabbix-server zabbix_get -s $WINDOWS_IP -k agent.ping${NC}"
echo -e "   ${GREEN}Résultat attendu: 1 pour chaque test${NC}"
echo ""

echo -e "${YELLOW}=== TEMPS ESTIMÉ ===${NC}"
echo -e "⏱️  Zabbix Server: 2 minutes"
echo -e "⏱️  Agent Linux: 3 minutes"
echo -e "⏱️  Agent Windows: 5 minutes"
echo -e "⏱️  Interface Zabbix: 3 minutes"
echo -e "⏱️  Tests: 2 minutes"
echo -e "${GREEN}⏱️  TOTAL: 15 minutes maximum${NC}"
echo ""

echo -e "${GREEN}📁 Fichiers à mettre à jour dans GitHub:${NC}"
echo "   - README.md (schéma d'architecture)"
echo "   - docker/zabbix-server/docker-compose.yml"
echo "   - scripts/install-linux-agent.sh"
echo "   - scripts/install-windows-agent.ps1"
echo "   - configs/zabbix_agentd.conf.linux"
echo "   - configs/zabbix_agent2.conf.windows"
echo ""

echo -e "${GREEN}✨ Script terminé ! Bonne chance pour la mise à jour !${NC}"
echo -e "${BLUE}© 2026 - EL MOUTAOUAKIL Abdellah - ENSET Media${NC}"