# Documentation AWS Infrastructure

## 1️⃣ Création du VPC

### Étapes

1. Se connecter à la console AWS
2. Aller dans **VPC > Your VPCs**
3. Cliquer sur **Create VPC**
4. Configurer :
   - **Name tag** : `VPC-Zabbix-Monitoring`
   - **IPv4 CIDR block** : `10.0.0.0/16`
   - **Tenancy** : `Default`
5. Cliquer sur **Create VPC**

📸 **Figure 1** : Création du VPC pour l'infrastructure de monitoring

## 2️⃣ Création du Sous-réseau Public

### Étapes

1. Aller dans **VPC > Subnets**
2. Cliquer sur **Create subnet**
3. Sélectionner le VPC : `VPC-Zabbix-Monitoring`
4. Configurer :
   - **Subnet name** : `Public-Subnet-Zabbix`
   - **Availability Zone** : `us-east-1a`
   - **IPv4 CIDR block** : `10.0.1.0/24`
5. Cliquer sur **Create subnet**

📸 **Figure 2** : Création du sous-réseau public

## 3️⃣ Configuration de l'Internet Gateway

### Étapes

1. Aller dans **VPC > Internet Gateways**
2. Cliquer sur **Create internet gateway**
3. **Nom** : `IGW-Zabbix`
4. Cliquer sur **Create**
5. Sélectionner l'IGW → **Actions > Attach to VPC**
6. Associer au VPC `VPC-Zabbix-Monitoring`

📸 **Figure 3** : Association de l'Internet Gateway au VPC

## 4️⃣ Table de Routage

### Étapes

1. Aller dans **VPC > Route Tables**
2. Sélectionner la table associée au VPC
3. **Onglet Routes > Edit routes**
4. Ajouter :
   - **Destination** : `0.0.0.0/0`
   - **Target** : Internet Gateway (`IGW-Zabbix`)
5. **Enregistrer**
6. Associer cette table au `Public-Subnet-Zabbix`

📸 **Figure 4** : Configuration de la table de routage

## 5️⃣ Création du Security Group

### Règles Inbound

| Type       | Port  | Source    | Description         |
| ---------- | ----- | --------- | ------------------- |
| HTTP       | 80    | 0.0.0.0/0 | Zabbix Web          |
| HTTPS      | 443   | 0.0.0.0/0 | Zabbix Web sécurisé |
| Custom TCP | 10050 | 0.0.0.0/0 | Agent Zabbix        |
| Custom TCP | 10051 | 0.0.0.0/0 | Zabbix Server       |
| SSH        | 22    | Your IP   | Accès Linux         |
| RDP        | 3389  | Your IP   | Accès Windows       |

### Étapes

1. Aller dans **EC2 > Security Groups**
2. Cliquer sur **Create security group**
3. Paramètres :
   - **Name** : `SG-Zabbix-Monitoring`
   - **VPC** : `VPC-Zabbix-Monitoring`
4. Ajouter les règles Inbound ci-dessus
5. Cliquer sur **Create security group**

📸 **Figure 5** : Configuration des règles du Security Group

## 6️⃣ Lancement des Instances EC2

### Serveur Zabbix

- **Nom** : `Zabbix-Server`
- **AMI** : Ubuntu Server 22.04 LTS
- **Type** : t3.large
- **VPC** : VPC-Zabbix-Monitoring
- **Subnet** : Public-Subnet-Zabbix
- **Security Group** : SG-Zabbix-Monitoring

### Client Linux

- **Nom** : `Linux-Client`
- **AMI** : Ubuntu Server 22.04 LTS
- **Type** : t3.medium
- **Même configuration réseau**

### Client Windows

- **Nom** : `Windows-Client`
- **AMI** : Windows Server 2019/2022
- **Type** : t3.large
- **Même configuration réseau**

📸 **Figure 6** : Instances EC2 en cours d'exécution

## ✅ Vérification

### Commandes de test

```bash
# Test de connectivité depuis votre machine locale
ping IP-PUBLIC-ZABBIX-SERVER
ping IP-PUBLIC-LINUX-CLIENT
ping IP-PUBLIC-WINDOWS-CLIENT

# Test SSH vers les instances Ubuntu
ssh -i "votre-cle.pem" ubuntu@IP-PUBLIC-ZABBIX-SERVER
ssh -i "votre-cle.pem" ubuntu@IP-PUBLIC-LINUX-CLIENT
```

### Points de contrôle

- [ ] VPC créé avec CIDR 10.0.0.0/16
- [ ] Sous-réseau public 10.0.1.0/24
- [ ] Internet Gateway attaché
- [ ] Table de routage configurée
- [ ] Security Group avec règles appropriées
- [ ] 3 instances EC2 en état "Running"
- [ ] IPs publiques assignées
- [ ] Connectivité SSH/RDP fonctionnelle

## 🔧 Dépannage

### Problèmes courants

1. **Pas d'IP publique** : Vérifier l'auto-assign Public IP
2. **Connexion refusée** : Vérifier les Security Groups
3. **Timeout SSH** : Vérifier la table de routage et l'IGW

### Commandes utiles AWS CLI

```bash
# Lister les instances
aws ec2 describe-instances --region us-east-1

# Lister les VPCs
aws ec2 describe-vpcs --region us-east-1

# Lister les Security Groups
aws ec2 describe-security-groups --region us-east-1
```
