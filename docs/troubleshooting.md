# Dépannage et Problèmes Courants

## 🔧 Guide de Résolution des Problèmes

### Problèmes d'Infrastructure AWS

#### 1. Instance ne démarre pas

**Symptômes** : Instance reste en état "pending" ou "stopped"

**Solutions** :

```bash
# Vérifier les limites de compte
aws ec2 describe-account-attributes --attribute-names max-instances

# Vérifier les quotas dans la région us-east-1
aws service-quotas list-service-quotas --service-code ec2
```

#### 2. Pas d'IP publique assignée

**Symptômes** : Instance accessible seulement via IP privée

**Solutions** :

1. **Via Console AWS** : EC2 > Instance > Actions > Networking > Manage IP addresses
2. **Via CLI** :

```bash
# Associer une Elastic IP
aws ec2 allocate-address --domain vpc
aws ec2 associate-address --instance-id i-1234567890abcdef0 --public-ip X.X.X.X
```

#### 3. Security Group mal configuré

**Symptômes** : Connexion refusée sur les ports 22, 80, 3389

**Vérification** :

```bash
# Lister les Security Groups
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx

# Ajouter une règle manquante
aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxxxxxx \
    --protocol tcp \
    --port 10050 \
    --cidr 0.0.0.0/0
```

### Problèmes de Connectivité Réseau

#### 1. SSH/RDP ne fonctionne pas

**Diagnostic** :

```bash
# Test de connectivité
telnet IP-PUBLIQUE 22    # Pour SSH
telnet IP-PUBLIQUE 3389  # Pour RDP

# Vérification de la route
traceroute IP-PUBLIQUE
```

**Solutions** :

- Vérifier la Table de Routage (0.0.0.0/0 → Internet Gateway)
- Vérifier les Security Groups
- Vérifier les NACLs (par défaut : autoriser tout)

#### 2. Instances ne peuvent pas communiquer entre elles

**Solutions** :

```bash
# Autoriser la communication interne dans le Security Group
aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxxxxxx \
    --protocol all \
    --source-group sg-xxxxxxxxx
```

### Problèmes Docker/Zabbix Server

#### 1. Conteneurs ne démarrent pas

**Diagnostic** :

```bash
# Vérifier l'espace disque
df -h

# Vérifier la mémoire
free -m

# Logs détaillés
docker-compose logs --details
```

**Solutions** :

```bash
# Nettoyer Docker
docker system prune -a -f

# Augmenter la mémoire swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### 2. Base de données PostgreSQL ne répond pas

**Diagnostic** :

```bash
# Vérifier le conteneur
docker exec -it zabbix-db pg_isready -U zabbix

# Se connecter à la DB
docker exec -it zabbix-db psql -U zabbix -d zabbix -c "SELECT version();"
```

**Solutions** :

```bash
# Redémarrer uniquement la DB
docker-compose restart zabbix-db

# Recréer la DB si nécessaire
docker-compose down
docker volume rm zabbix_zabbix-db-data
docker-compose up -d
```

#### 3. Interface Web Zabbix lente ou inaccessible

**Solutions** :

```bash
# Optimiser PHP
docker exec zabbix-web sed -i 's/memory_limit = 128M/memory_limit = 512M/' /etc/php/*/apache2/php.ini
docker exec zabbix-web sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/*/apache2/php.ini

# Redémarrer l'interface Web
docker-compose restart zabbix-web
```

### Problèmes Agent Linux

#### 1. Agent ne démarre pas

**Diagnostic** :

```bash
# Vérifier la configuration
sudo zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf -t

# Vérifier les logs
sudo tail -f /var/log/zabbix/zabbix_agentd.log

# Vérifier les permissions
ls -la /var/log/zabbix/
ls -la /etc/zabbix/
```

**Solutions** :

```bash
# Corriger les permissions
sudo chown -R zabbix:zabbix /var/log/zabbix/
sudo chmod 644 /etc/zabbix/zabbix_agentd.conf

# Créer les répertoires manquants
sudo mkdir -p /var/run/zabbix
sudo chown zabbix:zabbix /var/run/zabbix
```

#### 2. Items "Not supported"

**Solutions** :

```bash
# Tester l'item manuellement
sudo zabbix_agentd -t system.cpu.load[all,avg1]

# Pour les user parameters
sudo zabbix_agentd -t custom.disk.free[/]

# Vérifier les dépendances
which sensors  # Pour la température CPU
which iostat   # Pour les stats I/O disque
```

### Problèmes Agent Windows

#### 1. Service ne démarre pas

**Diagnostic PowerShell** :

```powershell
# Événements d'erreur
Get-WinEvent -LogName "System" | Where-Object {$_.Id -eq 7000 -and $_.Message -like "*Zabbix*"} | Select-Object -First 5

# Test manuel
cd "C:\Program Files\Zabbix Agent 2\"
.\zabbix_agent2.exe -c .\zabbix_agent2.conf -t

# Vérifier les permissions
Get-Acl "C:\Program Files\Zabbix Agent 2\" | Format-List
```

**Solutions** :

```powershell
# Réinstaller le service
cd "C:\Program Files\Zabbix Agent 2\"
.\zabbix_agent2.exe -c .\zabbix_agent2.conf --install

# Corriger les permissions
$acl = Get-Acl "C:\Program Files\Zabbix Agent 2\"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\LOCAL SERVICE","FullControl","Allow")
$acl.SetAccessRule($accessRule)
Set-Acl "C:\Program Files\Zabbix Agent 2\" $acl
```

#### 2. Pare-feu bloque la communication

**Solutions** :

```powershell
# Vérifier les règles existantes
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Zabbix*"}

# Créer les règles si manquantes
New-NetFirewallRule -DisplayName "Zabbix Agent" -Direction Inbound -Protocol TCP -LocalPort 10050 -Action Allow
New-NetFirewallRule -DisplayName "Zabbix Server" -Direction Outbound -Protocol TCP -RemotePort 10051 -Action Allow

# Désactiver temporairement le pare-feu pour test
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
# ATTENTION : Réactiver après test !
```

### Problèmes de Performance

#### 1. Serveur Zabbix consomme trop de ressources

**Solutions** :

```bash
# Modifier docker-compose.yml
environment:
  - ZBX_CACHESIZE=64M
  - ZBX_HISTORYCACHESIZE=32M
  - ZBX_HISTORYINDEXCACHESIZE=8M
  - ZBX_TRENDCACHESIZE=8M
  - ZBX_VALUECACHESIZE=16M

# Optimiser PostgreSQL
docker exec -it zabbix-db psql -U zabbix -d zabbix -c "
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
SELECT pg_reload_conf();
"
```

#### 2. Base de données trop volumineuse

**Solutions** :

```bash
# Configurer la rétention des données
# Dans l'interface Zabbix : Administration > Housekeeping

# Nettoyage manuel (avec précaution)
docker exec -it zabbix-db psql -U zabbix -d zabbix -c "
DELETE FROM history WHERE clock < EXTRACT(EPOCH FROM NOW() - INTERVAL '30 days');
DELETE FROM history_uint WHERE clock < EXTRACT(EPOCH FROM NOW() - INTERVAL '30 days');
VACUUM FULL;
"
```

### Problèmes de Monitoring

#### 1. Données manquantes ou obsolètes

**Vérifications** :

1. **Monitoring > Hosts** : Statut ZBX vert ?
2. **Configuration > Hosts > Items** : Items actifs ?
3. **Monitoring > Latest data** : Timestamp récent ?

**Solutions** :

```bash
# Redémarrer l'agent concerné
sudo systemctl restart zabbix-agent  # Linux
Restart-Service "Zabbix Agent 2"     # Windows

# Vérifier la communication
# Depuis le serveur Zabbix :
docker exec zabbix-server zabbix_get -s IP-AGENT -k agent.ping
```

#### 2. Alertes intempestives

**Solutions** :

1. **Configuration > Triggers** : Ajuster les seuils
2. **Configuration > Actions** : Modifier les conditions
3. Utiliser des **Maintenance periods** pour les maintenances

### Scripts de Diagnostic Automatisé

#### Script de diagnostic complet (Linux)

```bash
#!/bin/bash
# zabbix-diagnostic.sh

echo "=== DIAGNOSTIC ZABBIX COMPLET ==="
echo "Date: $(date)"
echo ""

# 1. Vérification système
echo "1. SYSTÈME"
echo "CPU: $(nproc) cores"
echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $4}') free"
echo ""

# 2. Vérification Docker (si serveur)
if command -v docker &> /dev/null; then
    echo "2. DOCKER"
    echo "Version: $(docker --version)"
    echo "Containers: $(docker ps --format 'table {{.Names}}\t{{.Status}}')"
    echo ""
fi

# 3. Vérification Agent Zabbix
echo "3. AGENT ZABBIX"
if systemctl is-active --quiet zabbix-agent; then
    echo "Service: Running"
    echo "Version: $(zabbix_agentd --version | head -1)"
    echo "Config test: $(sudo zabbix_agentd -t agent.ping)"
    echo "Last error: $(sudo tail -5 /var/log/zabbix/zabbix_agentd.log | grep -i error || echo 'None')"
else
    echo "Service: NOT RUNNING"
fi
echo ""

# 4. Vérification réseau
echo "4. RÉSEAU"
echo "Connectivity to Zabbix server: $(timeout 5 bash -c '</dev/tcp/13.221.240.167/10051' && echo 'OK' || echo 'FAILED')"
echo "Local port 10050: $(ss -tlnp | grep :10050 && echo 'OK' || echo 'NOT LISTENING')"
echo ""

# 5. Recommandations
echo "5. RECOMMANDATIONS"
if [ $(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}') -gt 80 ]; then
    echo "⚠️  Mémoire RAM utilisée > 80%"
fi
if [ $(df / | tail -1 | awk '{print $5}' | sed 's/%//') -gt 85 ]; then
    echo "⚠️  Espace disque utilisé > 85%"
fi
```

#### Script de diagnostic Windows (PowerShell)

```powershell
# zabbix-diagnostic.ps1

Write-Host "=== DIAGNOSTIC ZABBIX COMPLET ===" -ForegroundColor Green
Write-Host "Date: $(Get-Date)" -ForegroundColor Blue
Write-Host ""

# 1. Système
Write-Host "1. SYSTÈME" -ForegroundColor Yellow
$cpu = Get-WmiObject Win32_ComputerSystem
$mem = Get-WmiObject Win32_OperatingSystem
Write-Host "CPU: $($cpu.NumberOfLogicalProcessors) cores"
Write-Host "RAM: $([math]::Round($mem.TotalVisibleMemorySize/1MB,2)) GB total, $([math]::Round($mem.FreePhysicalMemory/1MB,2)) GB free"
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
Write-Host "Disk C:: $([math]::Round($disk.FreeSpace/1GB,2)) GB free / $([math]::Round($disk.Size/1GB,2)) GB total"
Write-Host ""

# 2. Service Zabbix
Write-Host "2. SERVICE ZABBIX" -ForegroundColor Yellow
$service = Get-Service "Zabbix Agent 2" -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "Service: $($service.Status)"
    if (Test-Path "C:\Program Files\Zabbix Agent 2\zabbix_agent2.exe") {
        $version = & "C:\Program Files\Zabbix Agent 2\zabbix_agent2.exe" --version 2>$null | Select-Object -First 1
        Write-Host "Version: $version"
    }
} else {
    Write-Host "Service: NOT INSTALLED" -ForegroundColor Red
}
Write-Host ""

# 3. Réseau
Write-Host "3. RÉSEAU" -ForegroundColor Yellow
$conn = Test-NetConnection -ComputerName "13.221.240.167" -Port 10051 -InformationLevel Quiet
Write-Host "Connectivity to Zabbix server: $(if($conn){'OK'}else{'FAILED'})"
$listening = Get-NetTCPConnection -LocalPort 10050 -ErrorAction SilentlyContinue
Write-Host "Local port 10050: $(if($listening){'LISTENING'}else{'NOT LISTENING'})"
Write-Host ""

# 4. Pare-feu
Write-Host "4. PARE-FEU" -ForegroundColor Yellow
$fwRules = Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Zabbix*" -and $_.Enabled -eq "True"}
Write-Host "Règles Zabbix: $($fwRules.Count) règle(s) active(s)"
Write-Host ""
```

### Contacts et Support

#### Logs importants à collecter

- **Linux** : `/var/log/zabbix/zabbix_agentd.log`
- **Windows** : `C:\Program Files\Zabbix Agent 2\zabbix_agent2.log`
- **Docker** : `docker-compose logs`
- **AWS** : Console AWS > EC2 > Instance > System log

#### Commandes de dépannage rapide

```bash
# Restart tout (serveur)
cd ~/zabbix && docker-compose restart

# Restart agent Linux
sudo systemctl restart zabbix-agent

# Restart agent Windows
Restart-Service "Zabbix Agent 2"

# Test connectivité
telnet SERVER-IP 10051  # Vers serveur
telnet AGENT-IP 10050   # Vers agent
```

## 🆘 Procédure d'Escalade

1. **Niveau 1** : Redémarrage des services
2. **Niveau 2** : Vérification des logs et configuration
3. **Niveau 3** : Réinstallation des composants
4. **Niveau 4** : Recréation de l'infrastructure

En cas de problème persistant, documenter :

- Symptômes exacts
- Messages d'erreur
- Étapes de reproduction
- Configuration actuelle
- Logs pertinents
