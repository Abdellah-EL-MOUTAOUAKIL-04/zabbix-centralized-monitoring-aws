# Script d'installation automatique de l'agent Zabbix sur Windows Server
# Auteur: EL MOUTAOUAKIL Abdellah
# Date: 2026-01-02

# Configuration
$ZabbixServerIP = "52.207.237.42"  # Nouvelle IP après redémarrage AWS
$Hostname = "EL-MOUTAOUAKIL-Windows-Client"
$ZabbixAgentURL = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.0/zabbix_agent2-6.4.0-windows-amd64-openssl.msi"
$TempDir = "$env:TEMP\zabbix"
$ZabbixDir = "C:\Program Files\Zabbix Agent 2"

Write-Host "🚀 Installation de l'agent Zabbix sur Windows Server..." -ForegroundColor Green

# Création du répertoire temporaire
Write-Host "📁 Création du répertoire temporaire..." -ForegroundColor Yellow
if (!(Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

# Téléchargement de l'agent Zabbix
Write-Host "📥 Téléchargement de l'agent Zabbix..." -ForegroundColor Yellow
$InstallerPath = "$TempDir\zabbix_agent2.msi"

try {
    Invoke-WebRequest -Uri $ZabbixAgentURL -OutFile $InstallerPath -UseBasicParsing
    Write-Host "✅ Téléchargement terminé" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du téléchargement: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Installation silencieuse de l'agent
Write-Host "📦 Installation de l'agent Zabbix..." -ForegroundColor Yellow
$InstallArgs = @(
    "/i"
    "`"$InstallerPath`""
    "/quiet"
    "SERVER=$ZabbixServerIP"
    "SERVERACTIVE=$ZabbixServerIP"
    "HOSTNAME=$Hostname"
    "INSTALLFOLDER=`"$ZabbixDir`""
)

try {
    Start-Process -FilePath "msiexec.exe" -ArgumentList $InstallArgs -Wait -NoNewWindow
    Write-Host "✅ Installation terminée" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de l'installation: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Attendre que l'installation soit complète
Write-Host "⏳ Attente de la finalisation de l'installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Vérification de l'installation
if (Test-Path "$ZabbixDir\zabbix_agent2.exe") {
    Write-Host "✅ Agent Zabbix installé avec succès" -ForegroundColor Green
} else {
    Write-Host "❌ Échec de l'installation" -ForegroundColor Red
    exit 1
}

# Configuration personnalisée
Write-Host "⚙️ Configuration de l'agent..." -ForegroundColor Yellow
$ConfigPath = "$ZabbixDir\zabbix_agent2.conf"

# Création du fichier de configuration personnalisé
$ConfigContent = @"
# Configuration de l'agent Zabbix 2
# Projet: AWS Zabbix Monitoring
# Auteur: EL MOUTAOUAKIL Abdellah

LogFile=C:\Program Files\Zabbix Agent 2\zabbix_agent2.log
Server=$ZabbixServerIP
ServerActive=$ZabbixServerIP
Hostname=$Hostname
ListenPort=10050

# Paramètres de performance
BufferSend=5
BufferSize=100
Timeout=3

# Paramètres Windows spécifiques
PerfCounter=\Processor(_Total)\% Processor Time,900
PerfCounter=\Memory\Available MBytes,60

# User parameters personnalisés
UserParameter=custom.windows.version,ver
UserParameter=custom.windows.uptime,powershell -Command "(Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime | Select-Object -ExpandProperty Days"
UserParameter=custom.disk.free[*],powershell -Command "Get-WmiObject -Class Win32_LogicalDisk | Where-Object {`$_.DeviceID -eq '$1'} | Select-Object -ExpandProperty FreeSpace"
"@

try {
    $ConfigContent | Out-File -FilePath $ConfigPath -Encoding UTF8 -Force
    Write-Host "✅ Configuration créée" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de la configuration: $($_.Exception.Message)" -ForegroundColor Red
}

# Configuration du service Windows
Write-Host "🔧 Configuration du service Windows..." -ForegroundColor Yellow

# Arrêt du service s'il fonctionne
try {
    Stop-Service -Name "Zabbix Agent 2" -Force -ErrorAction SilentlyContinue
    Write-Host "🛑 Service arrêté" -ForegroundColor Yellow
} catch {
    Write-Host "ℹ️ Service n'était pas en cours d'exécution" -ForegroundColor Blue
}

# Configuration du service pour démarrage automatique
try {
    Set-Service -Name "Zabbix Agent 2" -StartupType Automatic
    Write-Host "✅ Service configuré pour démarrage automatique" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de la configuration du service: $($_.Exception.Message)" -ForegroundColor Red
}

# Démarrage du service
Write-Host "🔄 Démarrage du service Zabbix Agent..." -ForegroundColor Yellow
try {
    Start-Service -Name "Zabbix Agent 2"
    Write-Host "✅ Service démarré avec succès" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du démarrage: $($_.Exception.Message)" -ForegroundColor Red
}

# Vérification du statut du service
Write-Host "🔍 Vérification du statut du service..." -ForegroundColor Yellow
$ServiceStatus = Get-Service -Name "Zabbix Agent 2" -ErrorAction SilentlyContinue

if ($ServiceStatus) {
    Write-Host "Service Status: $($ServiceStatus.Status)" -ForegroundColor Blue
    if ($ServiceStatus.Status -eq "Running") {
        Write-Host "✅ Service fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Service n'est pas en cours d'exécution" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Service non trouvé" -ForegroundColor Red
}

# Test de connectivité réseau
Write-Host "🌐 Test de connectivité réseau..." -ForegroundColor Yellow
try {
    $TestConnection = Test-NetConnection -ComputerName $ZabbixServerIP -Port 10051 -InformationLevel Quiet
    if ($TestConnection) {
        Write-Host "✅ Connectivité vers le serveur Zabbix OK" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Impossible de se connecter au serveur Zabbix" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur lors du test de connectivité: $($_.Exception.Message)" -ForegroundColor Red
}

# Configuration du pare-feu Windows
Write-Host "🔥 Configuration du pare-feu Windows..." -ForegroundColor Yellow
try {
    # Autoriser le port 10050 en entrée
    New-NetFirewallRule -DisplayName "Zabbix Agent Inbound" -Direction Inbound -Protocol TCP -LocalPort 10050 -Action Allow -ErrorAction SilentlyContinue
    # Autoriser le port 10051 en sortie vers le serveur
    New-NetFirewallRule -DisplayName "Zabbix Server Outbound" -Direction Outbound -Protocol TCP -RemotePort 10051 -RemoteAddress $ZabbixServerIP -Action Allow -ErrorAction SilentlyContinue
    Write-Host "✅ Règles de pare-feu configurées" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Erreur lors de la configuration du pare-feu: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Nettoyage
Write-Host "🧹 Nettoyage des fichiers temporaires..." -ForegroundColor Yellow
try {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Nettoyage terminé" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Erreur lors du nettoyage: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Affichage des informations finales
Write-Host ""
Write-Host "🎉 Installation terminée avec succès !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Serveur Zabbix: $ZabbixServerIP" -ForegroundColor White
Write-Host "Hostname: $Hostname" -ForegroundColor White
Write-Host "Port d'écoute: 10050" -ForegroundColor White
Write-Host "Répertoire d'installation: $ZabbixDir" -ForegroundColor White
Write-Host "Fichier de logs: $ZabbixDir\zabbix_agent2.log" -ForegroundColor White
Write-Host "Configuration: $ConfigPath" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Prochaines étapes:" -ForegroundColor Yellow
Write-Host "1. Ajouter cet hôte dans l'interface Zabbix Web" -ForegroundColor White
Write-Host "2. Vérifier que le statut ZBX est vert" -ForegroundColor White
Write-Host "3. Configurer les templates Windows" -ForegroundColor White
Write-Host "4. Tester la collecte de métriques" -ForegroundColor White
Write-Host ""
Write-Host "✨ Agent Zabbix prêt pour le monitoring !" -ForegroundColor Green