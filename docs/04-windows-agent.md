# Documentation : Configuration Agent Windows

## 🪟 Installation et Configuration de l'Agent Zabbix sur Windows Server

### Connexion au client Windows

1. **Connexion RDP** : `18.205.116.181:3389`
2. **Utilisateur** : `Administrator`
3. **Mot de passe** : Récupérer via la clé privée dans AWS Console

## Méthode 1 : Installation automatisée

### Utilisation du script PowerShell

1. Ouvrir **PowerShell en tant qu'administrateur**
2. Autoriser l'exécution de scripts :

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
```

3. Télécharger et exécuter le script :

```powershell
# Télécharger le script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/votre-username/aws-zabbix-monitoring/main/scripts/install-windows-agent.ps1" -OutFile "C:\temp\install-windows-agent.ps1"

# Exécuter le script
C:\temp\install-windows-agent.ps1
```

📸 **Figure 16** : Exécution du script d'installation PowerShell

## Méthode 2 : Installation manuelle

### Étape 1 : Téléchargement de l'agent

1. Ouvrir un navigateur web
2. Aller sur : `https://www.zabbix.com/download_agents`
3. Sélectionner :
   - **Platform** : Windows
   - **Zabbix version** : 6.4 LTS
   - **Agent** : Agent 2
   - **Architecture** : 64-bit
4. Télécharger : `zabbix_agent2-6.4.x-windows-amd64-openssl.msi`

### Étape 2 : Installation

1. Lancer le fichier `.msi` téléchargé
2. Suivre l'assistant d'installation :
   - **Server/Proxy** : `13.221.240.167`
   - **Agent service name** : `Zabbix Agent 2`
   - **Hostname** : `EL-MOUTAOUAKIL-Windows-Client`
3. Cliquer sur **Install**

📸 **Figure 17** : Assistant d'installation Zabbix Agent Windows

### Étape 3 : Configuration manuelle

1. Naviguer vers : `C:\Program Files\Zabbix Agent 2\`
2. Éditer le fichier `zabbix_agent2.conf` avec un éditeur de texte

### Configuration personnalisée

```ini
# Configuration de base
LogFile=C:\Program Files\Zabbix Agent 2\zabbix_agent2.log
Server=13.221.240.167
ServerActive=13.221.240.167
Hostname=EL-MOUTAOUAKIL-Windows-Client
ListenPort=10050

# Ou télécharger la configuration complète
# Invoke-WebRequest -Uri "https://raw.githubusercontent.com/votre-username/aws-zabbix-monitoring/main/configs/zabbix_agent2.conf.windows" -OutFile "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"
```

📸 **Figure 18** : Configuration du fichier zabbix_agent2.conf Windows

## Configuration du service Windows

### Gestion du service via Services.msc

1. Ouvrir **services.msc**
2. Chercher **Zabbix Agent 2**
3. Clic droit > **Propriétés**
4. **Type de démarrage** : Automatique
5. **Démarrer** le service

### Gestion via PowerShell

```powershell
# Vérifier le statut du service
Get-Service "Zabbix Agent 2"

# Démarrer le service
Start-Service "Zabbix Agent 2"

# Configurer pour démarrage automatique
Set-Service "Zabbix Agent 2" -StartupType Automatic

# Redémarrer le service
Restart-Service "Zabbix Agent 2"
```

📸 **Figure 19** : Service Zabbix Agent dans Services.msc

## Configuration du pare-feu Windows

### Via l'interface graphique

1. Ouvrir **Windows Defender Firewall with Advanced Security**
2. **Inbound Rules** > **New Rule...**
3. **Port** > **TCP** > **10050**
4. **Allow the connection**
5. **Name** : `Zabbix Agent Inbound`

### Via PowerShell

```powershell
# Autoriser le port 10050 en entrée
New-NetFirewallRule -DisplayName "Zabbix Agent Inbound" -Direction Inbound -Protocol TCP -LocalPort 10050 -Action Allow

# Autoriser la communication vers le serveur Zabbix
New-NetFirewallRule -DisplayName "Zabbix Server Outbound" -Direction Outbound -Protocol TCP -RemotePort 10051 -RemoteAddress "13.221.240.167" -Action Allow

# Vérifier les règles
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Zabbix*"}
```

📸 **Figure 20** : Configuration du pare-feu Windows

## Tests et validation

### Test de l'agent localement

```powershell
# Naviguer vers le répertoire Zabbix
cd "C:\Program Files\Zabbix Agent 2\"

# Tester la configuration
.\zabbix_agent2.exe -c .\zabbix_agent2.conf -t

# Tester des items spécifiques
.\zabbix_agent2.exe -c .\zabbix_agent2.conf -t agent.ping
.\zabbix_agent2.exe -c .\zabbix_agent2.conf -t agent.version
.\zabbix_agent2.exe -c .\zabbix_agent2.conf -t system.uptime
```

### Test de connectivité réseau

```powershell
# Test ping vers le serveur Zabbix
Test-Connection -ComputerName 13.221.240.167

# Test de connexion TCP
Test-NetConnection -ComputerName 13.221.240.167 -Port 10051

# Vérifier que l'agent écoute
Get-NetTCPConnection -LocalPort 10050
```

## Configuration dans l'interface Zabbix

### Ajout de l'hôte dans Zabbix Web

1. **Configuration > Hosts > Create host**
2. **Paramètres de l'hôte** :

   - **Host name** : `EL-MOUTAOUAKIL-Windows-Client`
   - **Visible name** : `Windows Client - Server 2022`
   - **Groups** : `Windows servers`

3. **Interface** :

   - **Type** : Agent
   - **IP address** : `18.205.116.181`
   - **DNS name** : (laisser vide)
   - **Connect to** : IP
   - **Port** : `10050`

4. **Templates** :
   - Ajouter : `Windows by Zabbix agent`
   - Optionnel : `ICMP Ping`

📸 **Figure 21** : Configuration de l'hôte Windows dans l'interface Zabbix

### Vérification de la connectivité

1. **Monitoring > Hosts**
2. Vérifier que le statut ZBX est **vert**
3. **Latest data** > Rechercher l'hôte
4. Vérifier la réception des données

📸 **Figure 22** : Statut "Vert" (ZBX) du client Windows

## Monitoring personnalisé Windows

### User Parameters pour AWS EC2

```ini
# Ajouts dans zabbix_agent2.conf
UserParameter=aws.ec2.instance.id,powershell -Command "Invoke-RestMethod -Uri 'http://169.254.169.254/latest/meta-data/instance-id' -TimeoutSec 5 2>$null"
UserParameter=aws.ec2.instance.type,powershell -Command "Invoke-RestMethod -Uri 'http://169.254.169.254/latest/meta-data/instance-type' -TimeoutSec 5 2>$null"
UserParameter=aws.ec2.availability.zone,powershell -Command "Invoke-RestMethod -Uri 'http://169.254.169.254/latest/meta-data/placement/availability-zone' -TimeoutSec 5 2>$null"
```

### Monitoring des rôles Windows

```ini
# Active Directory (si installé)
UserParameter=windows.ad.status,powershell -Command "try { Get-Service NTDS -ErrorAction Stop | Select-Object -ExpandProperty Status } catch { 'Not Installed' }"

# IIS (si installé)
UserParameter=windows.iis.status,powershell -Command "try { Get-Service W3SVC -ErrorAction Stop | Select-Object -ExpandProperty Status } catch { 'Not Installed' }"

# DNS Server (si installé)
UserParameter=windows.dns.status,powershell -Command "try { Get-Service DNS -ErrorAction Stop | Select-Object -ExpandProperty Status } catch { 'Not Installed' }"

# DHCP Server (si installé)
UserParameter=windows.dhcp.status,powershell -Command "try { Get-Service DHCPServer -ErrorAction Stop | Select-Object -ExpandProperty Status } catch { 'Not Installed' }"
```

## Surveillance des logs

### Logs de l'agent Zabbix

```powershell
# Surveiller les logs en temps réel
Get-Content "C:\Program Files\Zabbix Agent 2\zabbix_agent2.log" -Wait -Tail 20

# Rechercher les erreurs
Select-String -Path "C:\Program Files\Zabbix Agent 2\zabbix_agent2.log" -Pattern "error|ERROR"

# Vérifier les dernières entrées
Get-Content "C:\Program Files\Zabbix Agent 2\zabbix_agent2.log" | Select-Object -Last 50
```

### Event Logs Windows

```powershell
# Vérifier les événements de l'agent Zabbix
Get-WinEvent -LogName "Application" | Where-Object {$_.ProviderName -eq "Zabbix Agent 2"}

# Vérifier les événements système liés
Get-WinEvent -LogName "System" | Where-Object {$_.Message -like "*Zabbix*"}
```

## Performance et optimisation

### Monitoring des performances système

```powershell
# CPU utilization
Get-Counter "\Processor(_Total)\% Processor Time"

# Memory usage
Get-Counter "\Memory\Available MBytes"

# Disk usage
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}}

# Network statistics
Get-Counter "\Network Interface(*)\Bytes Total/sec"
```

### Optimisation de l'agent

```ini
# Paramètres de performance dans zabbix_agent2.conf
BufferSend=5
BufferSize=100
Timeout=3

# Plugins spécifiques Windows
Plugins.WindowsEventlog.MaxLinesPerSecond=1000
Plugins.WindowsServices.Timeout=30
```

## Dépannage

### Problèmes courants

#### Service ne démarre pas

```powershell
# Vérifier les événements d'erreur
Get-WinEvent -LogName "System" | Where-Object {$_.Id -eq 7000 -and $_.Message -like "*Zabbix*"}

# Tester la configuration manuellement
cd "C:\Program Files\Zabbix Agent 2\"
.\zabbix_agent2.exe -c .\zabbix_agent2.conf -f

# Vérifier les permissions
Get-Acl "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf" | Format-List
```

#### Connectivité réseau

```powershell
# Diagnostic réseau complet
Test-NetConnection -ComputerName 13.221.240.167 -Port 10051 -InformationLevel Detailed

# Vérifier les règles de pare-feu
Get-NetFirewallRule | Where-Object {$_.Enabled -eq "True" -and $_.Direction -eq "Inbound" -and $_.LocalPort -eq "10050"}

# Traçage réseau
tracert 13.221.240.167
```

#### Items non supportés

```powershell
# Tester les items manuellement
.\zabbix_agent2.exe -c .\zabbix_agent2.conf -t perf_counter[\Processor(_Total)\% Processor Time]
.\zabbix_agent2.exe -c .\zabbix_agent2.conf -t system.uptime
```

### Outils de diagnostic Windows

#### Performance Monitor (PerfMon)

1. Ouvrir **perfmon.exe**
2. Ajouter les compteurs Zabbix
3. Surveiller l'impact sur les performances

#### Resource Monitor

1. Ouvrir **resmon.exe**
2. Surveiller l'utilisation CPU/mémoire de Zabbix Agent

## Scripts utiles PowerShell

### Script de vérification quotidienne

```powershell
# check-zabbix-agent.ps1
Write-Host "=== Vérification Agent Zabbix ===" -ForegroundColor Green
$service = Get-Service "Zabbix Agent 2"
Write-Host "Statut service: $($service.Status)" -ForegroundColor Yellow

$logPath = "C:\Program Files\Zabbix Agent 2\zabbix_agent2.log"
if (Test-Path $logPath) {
    $lastErrors = Get-Content $logPath | Select-String "error|ERROR" | Select-Object -Last 5
    if ($lastErrors) {
        Write-Host "Dernières erreurs:" -ForegroundColor Red
        $lastErrors | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
    } else {
        Write-Host "Aucune erreur récente" -ForegroundColor Green
    }
}

# Test connectivité
$conn = Test-NetConnection -ComputerName 13.221.240.167 -Port 10051 -InformationLevel Quiet
Write-Host "Connectivité serveur: $(if($conn){'OK'}else{'FAILED'})" -ForegroundColor $(if($conn){'Green'}else{'Red'})
```

### Script de réinstallation

```powershell
# reinstall-agent.ps1
Stop-Service "Zabbix Agent 2" -Force
$app = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Zabbix*"}
if ($app) { $app.Uninstall() }
Remove-Item "C:\Program Files\Zabbix Agent 2\" -Recurse -Force -ErrorAction SilentlyContinue

# Télécharger et réinstaller
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/votre-username/aws-zabbix-monitoring/main/scripts/install-windows-agent.ps1" -OutFile "C:\temp\install-windows-agent.ps1"
C:\temp\install-windows-agent.ps1
```

## ✅ Points de contrôle

- [ ] Agent Zabbix 2 téléchargé et installé
- [ ] Fichier de configuration édité
- [ ] Service Windows configuré et démarré
- [ ] Pare-feu configuré (ports 10050/10051)
- [ ] Tests locaux réussis
- [ ] Connectivité réseau vérifiée
- [ ] Hôte ajouté dans l'interface Zabbix
- [ ] Templates Windows appliqués
- [ ] Données collectées visibles
- [ ] Performance monitoring actif
- [ ] Logs sans erreur critique
- [ ] User parameters fonctionnels

📸 **Figure 23** : Monitoring Windows complet dans l'interface Zabbix
