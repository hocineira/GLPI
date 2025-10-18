# Installation GLPI 11.0.0 sur Ubuntu 24.04 LTS

## 📋 Description

Ce projet contient des scripts d'installation automatisés pour GLPI 11.0.0 sur Ubuntu 24.04 LTS, avec préparation pour l'intégration LDAPS (Active Directory).

**Basé sur la procédure d'installation de IRATNI Hocine**

---

## 📦 Contenu du projet

- **`install_glpi.sh`** : Script complet d'installation de GLPI avec configuration DNS
- **`configure_dns.sh`** : Script de configuration DNS uniquement (pour préparation LDAPS)
- **`Procédure_GLPI_V11_2025.pdf`** : Procédure complète d'installation

---

## 🎯 Fonctionnalités

### Script `install_glpi.sh` (Installation complète)

1. **Configuration DNS** pour intégration LDAPS
   - Modification de `/etc/systemd/resolved.conf`
   - Configuration du serveur DNS (Active Directory)
   - Configuration du domaine de recherche

2. **Préparation du serveur**
   - Mise à jour du système
   - Installation d'Apache 2.4.63
   - Installation de MariaDB 10.11.13
   - Installation de PHP 8.3.x et extensions requises
   - Configuration du pare-feu (ports 80 et 443)

3. **Configuration de la base de données**
   - Sécurisation de MariaDB
   - Création de la base de données `glpidb`
   - Création de l'utilisateur `glpi`

4. **Installation de GLPI**
   - Téléchargement de GLPI 11.0.0
   - Installation dans `/var/www/html/glpi`
   - Configuration des permissions

5. **Configuration Apache**
   - Création du VirtualHost
   - Configuration du fichier `.htaccess`
   - Activation du module rewrite
   - Activation du site GLPI

6. **Tests de résolution DNS**
   - Test avec nslookup, dig, ping
   - Vérification de l'accessibilité de l'Active Directory

### Script `configure_dns.sh` (DNS uniquement)

- Configuration DNS isolée
- Tests de résolution DNS
- Tests de connectivité LDAP/LDAPS
- Sauvegarde de la configuration existante

---

## ⚙️ Prérequis

- **Système d'exploitation** : Ubuntu 24.04 LTS ou plus récent
- **Accès** : root ou sudo
- **Réseau** : Connexion Internet pour le téléchargement des paquets
- **Active Directory** : Serveur AD en ligne (pour l'intégration LDAPS)

---

## 🚀 Utilisation

### Installation complète de GLPI

```bash
# 1. Rendre le script exécutable
chmod +x install_glpi.sh

# 2. Exécuter le script en tant que root
sudo ./install_glpi.sh
```

**Le script vous demandera :**
- L'adresse IP du serveur GLPI (ex: 192.168.1.100)
- Le mot de passe pour la base de données MariaDB
- L'adresse IP du serveur DNS (Active Directory) (ex: 192.168.1.10)
- Le nom de domaine (ex: domaines4p2.local)
- Le FQDN de votre serveur AD pour tester le DNS (ex: srv-ad1.domaines4p2.local)

### Configuration DNS uniquement

```bash
# 1. Rendre le script exécutable
chmod +x configure_dns.sh

# 2. Exécuter le script en tant que root
sudo ./configure_dns.sh
```

---

## 📝 Étapes après l'installation

### 1. Accéder à l'interface web GLPI

Ouvrez votre navigateur et accédez à :
```
http://VOTRE_IP_SERVEUR/glpi
```

### 2. Assistant d'installation web

Suivez les étapes de l'assistant :

1. **Sélection de la langue**
2. **Acceptation de la licence**
3. **Vérification des prérequis**
4. **Configuration de la base de données** :
   - Serveur SQL : `localhost`
   - Utilisateur SQL : `glpi`
   - Mot de passe : (celui que vous avez défini)
   - Base de données : `glpidb`

### 3. Comptes par défaut GLPI

**⚠️ À CHANGER après la première connexion :**

| Compte | Mot de passe | Rôle |
|--------|--------------|------|
| glpi | glpi | Administrateur |
| tech | tech | Technicien |
| normal | normal | Utilisateur normal |
| post-only | postonly | Post-only |

### 4. Configuration LDAPS (Active Directory)

Une fois GLPI installé :

1. Connectez-vous avec le compte administrateur
2. Allez dans : **Configuration > Authentification > Annuaire LDAP**
3. Cliquez sur **Ajouter**
4. Remplissez les informations selon votre environnement :

**Exemple de configuration :**

| Paramètre | Valeur |
|-----------|--------|
| Nom | SRV-AD1 |
| Serveur par défaut | Oui |
| Actif | Oui |
| Serveur | `ldaps://srv-ad1.domaines4p2.local` |
| Port | 636 |
| Filtre de connexion | `(&(objectClass=user)(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))` |
| BaseDN | `DC=DOMAINES4P2,DC=local` |
| Utiliser bind | Oui |
| DN du compte | `Administrateur@domaines4p2.local` |
| Mot de passe du compte | (mot de passe AD) |
| Champ de l'identifiant | `samaccountname` |
| Champ de synchronisation | `objectguid` |

5. Cliquez sur **Tester** pour vérifier la connexion
6. Enregistrez la configuration

---

## 📂 Fichiers et répertoires importants

### Configuration

| Fichier/Répertoire | Description |
|-------------------|-------------|
| `/etc/systemd/resolved.conf` | Configuration DNS |
| `/etc/apache2/sites-available/glpi.conf` | VirtualHost Apache pour GLPI |
| `/var/www/html/glpi/` | Répertoire d'installation GLPI |
| `/var/www/html/glpi/public/.htaccess` | Configuration de réécriture d'URL |

### Logs

| Fichier | Description |
|---------|-------------|
| `/var/log/apache2/error.log` | Logs d'erreur Apache |
| `/var/log/apache2/access.log` | Logs d'accès Apache |
| `/var/log/mysql/error.log` | Logs d'erreur MariaDB |

---

## 🔧 Commandes utiles

### Services

```bash
# Redémarrer Apache
sudo systemctl restart apache2

# Redémarrer MariaDB
sudo systemctl restart mariadb

# Redémarrer le service DNS
sudo systemctl restart systemd-resolved

# Vérifier le statut des services
sudo systemctl status apache2
sudo systemctl status mariadb
sudo systemctl status systemd-resolved
```

### DNS

```bash
# Afficher la configuration DNS active
resolvectl status

# Tester la résolution DNS
nslookup srv-ad1.domaines4p2.local

# Tester avec dig
dig srv-ad1.domaines4p2.local

# Tester la connectivité
ping srv-ad1.domaines4p2.local
```

### Base de données

```bash
# Se connecter à MariaDB
sudo mysql -u root -p

# Vérifier la base de données GLPI
sudo mysql -u glpi -p glpidb
```

### GLPI

```bash
# Vérifier les permissions
ls -la /var/www/html/glpi/

# Vérifier la configuration Apache
sudo apache2ctl configtest

# Voir les logs Apache en temps réel
sudo tail -f /var/log/apache2/error.log
```

---

## 🛠️ Dépannage

### GLPI n'est pas accessible

1. Vérifier qu'Apache est en cours d'exécution :
   ```bash
   sudo systemctl status apache2
   ```

2. Vérifier la configuration Apache :
   ```bash
   sudo apache2ctl configtest
   ```

3. Vérifier les logs :
   ```bash
   sudo tail -n 50 /var/log/apache2/error.log
   ```

### Erreur de connexion à la base de données

1. Vérifier que MariaDB est en cours d'exécution :
   ```bash
   sudo systemctl status mariadb
   ```

2. Tester la connexion :
   ```bash
   sudo mysql -u glpi -p glpidb
   ```

### La résolution DNS ne fonctionne pas

1. Vérifier la configuration :
   ```bash
   cat /etc/systemd/resolved.conf
   ```

2. Vérifier le statut du service :
   ```bash
   sudo systemctl status systemd-resolved
   ```

3. Tester la résolution :
   ```bash
   nslookup srv-ad1.domaines4p2.local
   ```

4. Redémarrer le service DNS :
   ```bash
   sudo systemctl restart systemd-resolved
   ```

### Problèmes de permissions

```bash
# Réappliquer les bonnes permissions
sudo chown -R www-data:www-data /var/www/html/glpi
sudo chmod -R 755 /var/www/html/glpi
```

---

## 🔒 Sécurité

### Recommandations après l'installation

1. **Changer tous les mots de passe par défaut** de GLPI
2. **Supprimer le fichier d'installation** :
   ```bash
   sudo rm -f /var/www/html/glpi/install/install.php
   ```
3. **Configurer HTTPS** avec un certificat SSL
4. **Configurer le pare-feu** correctement
5. **Mettre en place des sauvegardes** régulières

### Sauvegarde de la configuration DNS

Le script crée automatiquement une sauvegarde :
```
/etc/systemd/resolved.conf.backup.YYYYMMDD_HHMMSS
```

Pour restaurer :
```bash
sudo cp /etc/systemd/resolved.conf.backup.* /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
```

---

## 📚 Versions utilisées

| Composant | Version |
|-----------|---------|
| Ubuntu | 24.04 LTS |
| GLPI | 11.0.0 |
| Apache | 2.4.63 |
| MariaDB | 10.11.13 |
| PHP | 8.3.x |

---

## 🔗 Liens utiles

- **Site officiel GLPI** : https://glpi-project.org/
- **Documentation GLPI** : https://glpi-install.readthedocs.io/
- **GitHub GLPI** : https://github.com/glpi-project/glpi
- **Site de l'auteur de la procédure** : www.iratnihocine.com

---

## 📄 Licence

Ce script est basé sur la procédure open-source de IRATNI Hocine.
GLPI est un logiciel libre sous licence GPL.

---

## 👤 Auteur de la procédure originale

**IRATNI Hocine**
- Site web : www.iratnihocine.com

---

## 📞 Support

Pour toute question ou problème :
1. Consultez la section **Dépannage** ci-dessus
2. Vérifiez les logs système
3. Consultez la documentation officielle GLPI
4. Référez-vous à la procédure PDF complète

---

## ✅ Checklist d'installation

- [ ] Ubuntu 24.04 LTS installé et à jour
- [ ] Accès root ou sudo disponible
- [ ] Connexion Internet fonctionnelle
- [ ] Serveur Active Directory accessible
- [ ] Script `install_glpi.sh` téléchargé
- [ ] Script rendu exécutable (`chmod +x`)
- [ ] Informations nécessaires préparées :
  - [ ] Adresse IP du serveur GLPI
  - [ ] Mot de passe pour la base de données
  - [ ] Adresse IP du serveur DNS (AD)
  - [ ] Nom de domaine
  - [ ] FQDN du serveur AD
- [ ] Script exécuté avec succès
- [ ] Tests DNS réussis
- [ ] Accès à l'interface web GLPI
- [ ] Installation web GLPI terminée
- [ ] Mots de passe par défaut changés
- [ ] Configuration LDAPS effectuée
- [ ] Tests d'authentification LDAP réussis

---

**🎉 Bonne utilisation de GLPI !**
