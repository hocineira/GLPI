# 🚀 GUIDE DE DÉMARRAGE RAPIDE - Installation GLPI

## ⚡ Installation en 3 étapes

### Étape 1 : Vérifier les prérequis
```bash
sudo ./check_prerequisites.sh
```

### Étape 2 : Installer GLPI
```bash
sudo ./install_glpi.sh
```

**Le script vous demandera :**
- ✏️ Adresse IP du serveur GLPI
- ✏️ Mot de passe pour la base de données
- ✏️ Adresse IP du serveur DNS (Active Directory)
- ✏️ Nom de domaine
- ✏️ FQDN du serveur AD pour test DNS

### Étape 3 : Accéder à GLPI
Ouvrez votre navigateur : `http://VOTRE_IP/glpi`

---

## 📋 Alternative : Configuration DNS uniquement

Si vous souhaitez uniquement configurer le DNS :
```bash
sudo ./configure_dns.sh
```

---

## 🔑 Comptes par défaut GLPI

| Utilisateur | Mot de passe | Rôle |
|-------------|--------------|------|
| glpi | glpi | Super Admin |
| tech | tech | Technicien |
| normal | normal | Utilisateur |
| post-only | postonly | Post-only |

⚠️ **IMPORTANT : Changez ces mots de passe après la première connexion !**

---

## 🔧 Configuration LDAPS

**Après l'installation web de GLPI :**

1. Connexion avec compte `glpi/glpi`
2. Menu : **Configuration > Authentification > Annuaire LDAP**
3. Cliquez sur **Ajouter**
4. Configurez selon votre environnement :

```
Serveur : ldaps://srv-ad1.votre-domaine.local
Port : 636
BaseDN : DC=votre,DC=domaine,DC=local
DN du compte : Administrateur@votre-domaine.local
Champ identifiant : samaccountname
Champ synchronisation : objectguid
```

5. **Tester** puis **Enregistrer**

---

## 🛠️ Commandes utiles

### Services
```bash
# Redémarrer les services
sudo systemctl restart apache2
sudo systemctl restart mariadb
sudo systemctl restart systemd-resolved

# Vérifier le statut
sudo systemctl status apache2
```

### Logs
```bash
# Voir les logs Apache
sudo tail -f /var/log/apache2/error.log

# Voir les logs MariaDB
sudo tail -f /var/log/mysql/error.log
```

### DNS
```bash
# Tester la résolution DNS
nslookup srv-ad1.domaine.local

# Afficher la config DNS
resolvectl status
```

---

## ❓ Problèmes courants

### ❌ GLPI ne s'affiche pas
```bash
# Vérifier Apache
sudo systemctl status apache2
sudo apache2ctl configtest

# Voir les erreurs
sudo tail -50 /var/log/apache2/error.log
```

### ❌ Erreur de connexion à la base de données
```bash
# Tester la connexion
sudo mysql -u glpi -p glpidb
```

### ❌ DNS ne résout pas
```bash
# Vérifier la configuration
cat /etc/systemd/resolved.conf

# Redémarrer le service
sudo systemctl restart systemd-resolved
```

---

## 📖 Documentation complète

Pour plus de détails, consultez : **README_GLPI.md**

---

## ✅ Checklist rapide

- [ ] Vérifier prérequis avec `check_prerequisites.sh`
- [ ] Préparer les informations (IP, mots de passe, domaine)
- [ ] Exécuter `install_glpi.sh`
- [ ] Vérifier les tests DNS
- [ ] Accéder à `http://VOTRE_IP/glpi`
- [ ] Terminer l'installation web
- [ ] Changer les mots de passe par défaut
- [ ] Configurer LDAPS
- [ ] Tester l'authentification AD

---

## 📞 Besoin d'aide ?

1. Consultez **README_GLPI.md** pour la documentation complète
2. Vérifiez les logs système
3. Consultez la procédure PDF originale
4. Documentation officielle : https://glpi-install.readthedocs.io/

---

**🎉 Installation terminée en quelques minutes !**
