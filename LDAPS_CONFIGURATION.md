# Configuration LDAPS pour GLPI - Active Directory

Ce document fournit des exemples de configuration LDAPS pour l'intégration de GLPI avec Active Directory.

## 📋 Configuration de base

### Paramètres principaux

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| **Nom** | SRV-AD1 | Nom de l'annuaire dans GLPI |
| **Serveur par défaut** | ☑️ Oui | Utiliser cet annuaire par défaut |
| **Actif** | ☑️ Oui | Activer l'annuaire |

### Serveur LDAPS

| Paramètre | Valeur exemple | Votre valeur |
|-----------|----------------|--------------|
| **Serveur** | `ldaps://srv-ad1.domaines4p2.local` | `ldaps://____________________` |
| **Port** | `636` | `636` |

> 💡 **Note** : Utilisez `ldaps://` pour une connexion sécurisée (SSL/TLS)

### Configuration de base

| Paramètre | Valeur exemple | Description |
|-----------|----------------|-------------|
| **BaseDN** | `DC=DOMAINES4P2,DC=local` | Racine de votre annuaire AD |
| **Utiliser bind** | ☑️ Oui | Utiliser une authentification |
| **DN du compte** | `Administrateur@domaines4p2.local` | Compte avec accès LDAP |
| **Mot de passe** | `********` | Mot de passe du compte |

### Filtres et champs

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| **Filtre de connexion** | `(&(objectClass=user)(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))` | Filtre les utilisateurs actifs uniquement |
| **Champ de l'identifiant** | `samaccountname` | Nom de connexion Windows |
| **Champ de synchronisation** | `objectguid` | Identifiant unique AD |

---

## 🔍 Explication du filtre de connexion

Le filtre LDAP utilisé :
```
(&(objectClass=user)(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
```

**Décomposition :**
- `(&...)` : Opérateur ET - toutes les conditions doivent être vraies
- `(objectClass=user)` : L'objet doit être un utilisateur
- `(objectCategory=person)` : L'objet doit être une personne
- `(!(userAccountControl:1.2.840.113556.1.4.803:=2))` : Exclut les comptes désactivés

---

## 🌳 Construire votre BaseDN

Le BaseDN dépend de votre nom de domaine Active Directory.

### Exemples de conversion

| Domaine AD | BaseDN |
|------------|--------|
| `domaines4p2.local` | `DC=DOMAINES4P2,DC=local` |
| `entreprise.com` | `DC=entreprise,DC=com` |
| `it.entreprise.local` | `DC=it,DC=entreprise,DC=local` |
| `mon-domaine.fr` | `DC=mon-domaine,DC=fr` |

### Règle de conversion
Remplacez chaque `.` par `,DC=` et ajoutez `DC=` au début :
```
exemple.local → DC=exemple,DC=local
```

---

## 🔑 Types de comptes de liaison (Bind)

### Option 1 : Format UPN (Recommandé)
```
Administrateur@domaines4p2.local
```
✅ Plus simple à utiliser
✅ Format habituel Windows

### Option 2 : Format DN complet
```
CN=Administrateur,CN=Users,DC=domaines4p2,DC=local
```
✅ Plus précis
⚠️ Plus complexe

---

## 📊 Tableau de configuration complet

Voici un tableau que vous pouvez remplir pour votre environnement :

```
╔═══════════════════════════════════════════════════════════════════╗
║                  CONFIGURATION LDAPS - GLPI                       ║
╠═══════════════════════════════════════════════════════════════════╣
║ Nom de l'annuaire                                                 ║
║ → _________________________________________________________       ║
║                                                                   ║
║ Serveur LDAPS                                                     ║
║ → ldaps://_____________________________________________           ║
║                                                                   ║
║ Port                                                              ║
║ → 636                                                             ║
║                                                                   ║
║ BaseDN                                                            ║
║ → DC=____________,DC=____________                                 ║
║                                                                   ║
║ DN du compte (format UPN)                                         ║
║ → _______________________@_______________________                 ║
║                                                                   ║
║ Mot de passe du compte                                            ║
║ → _______________________________________________                 ║
║                                                                   ║
║ Filtre de connexion                                               ║
║ → (&(objectClass=user)(objectCategory=person)                     ║
║    (!(userAccountControl:1.2.840.113556.1.4.803:=2)))            ║
║                                                                   ║
║ Champ de l'identifiant                                            ║
║ → samaccountname                                                  ║
║                                                                   ║
║ Champ de synchronisation                                          ║
║ → objectguid                                                      ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## 🧪 Tests de connexion LDAPS

### Test 1 : Depuis le serveur GLPI (ligne de commande)

```bash
# Test de résolution DNS
nslookup srv-ad1.domaines4p2.local

# Test de connectivité au port LDAPS (636)
nc -zv srv-ad1.domaines4p2.local 636

# Test avec ldapsearch (si installé)
ldapsearch -H ldaps://srv-ad1.domaines4p2.local:636 \
  -D "Administrateur@domaines4p2.local" \
  -W \
  -b "DC=DOMAINES4P2,DC=local" \
  "(sAMAccountName=*)" sAMAccountName
```

### Test 2 : Depuis l'interface GLPI

1. Allez dans **Configuration > Authentification > Annuaire LDAP**
2. Cliquez sur **Tester** (après avoir configuré l'annuaire)
3. Vérifiez les résultats :

```
✓ Flux TCP : Connexion réussie
✓ Base DN : Configuré
✓ LDAP URI : Vérification réussie
✓ Connexion Bind : Authentification réussie
✓ Recherche : X entrées trouvées
```

---

## 🔐 Certificats SSL/TLS pour LDAPS

### Problème : Certificat auto-signé

Si votre AD utilise un certificat auto-signé, vous pouvez rencontrer des erreurs de connexion.

**Solution :**

1. Récupérer le certificat depuis le serveur AD
2. L'installer sur le serveur GLPI :

```bash
# Copier le certificat
sudo cp certificat_ad.crt /usr/local/share/ca-certificates/

# Mettre à jour les certificats
sudo update-ca-certificates

# Redémarrer Apache
sudo systemctl restart apache2
```

### Configuration PHP pour ignorer les certificats (NON RECOMMANDÉ pour la production)

```bash
# Éditer php.ini
sudo nano /etc/php/8.3/apache2/php.ini

# Ajouter (section [ldap])
ldap.tls_require_cert = never
```

---

## 📁 Synchronisation des utilisateurs

### Import manuel

1. **Configuration > Authentification > Annuaire LDAP**
2. Cliquez sur le nom de votre annuaire
3. Onglet **Utilisateurs**
4. Cliquez sur **Liaison annuaire LDAP > utilisateurs**
5. Sélectionnez les utilisateurs à importer
6. Cliquez sur **Importer**

### Import automatique (Tâche automatique)

1. **Configuration > Actions automatiques**
2. Recherchez **ldap_sync**
3. Configurez la fréquence d'exécution
4. Activez la tâche

---

## 👥 Synchronisation des groupes

### Configuration des groupes LDAP

1. **Configuration > Authentification > Annuaire LDAP**
2. Cliquez sur le nom de votre annuaire
3. Onglet **Groupes**
4. Configurez :
   - **BaseDN des groupes** : `CN=Users,DC=DOMAINES4P2,DC=local`
   - **Filtre de recherche** : `(objectClass=group)`
   - **Attribut du groupe** : `cn`
   - **Attribut des membres** : `member`

---

## 🔧 Dépannage

### Erreur : "Impossible de se connecter au serveur LDAP"

**Causes possibles :**
- ❌ Serveur DNS non configuré correctement
- ❌ Port 636 bloqué par un pare-feu
- ❌ Certificat SSL non valide
- ❌ Service LDAPS non démarré sur l'AD

**Solutions :**
```bash
# Vérifier la résolution DNS
nslookup srv-ad1.domaines4p2.local

# Tester la connectivité
nc -zv srv-ad1.domaines4p2.local 636

# Vérifier les logs Apache
sudo tail -f /var/log/apache2/error.log
```

### Erreur : "Authentification échouée"

**Causes possibles :**
- ❌ DN du compte incorrect
- ❌ Mot de passe incorrect
- ❌ Compte verrouillé dans AD
- ❌ Permissions insuffisantes

**Solutions :**
- Vérifier les identifiants
- Utiliser le format UPN : `utilisateur@domaine.local`
- Vérifier les permissions du compte dans AD

### Erreur : "Aucun utilisateur trouvé"

**Causes possibles :**
- ❌ BaseDN incorrect
- ❌ Filtre LDAP trop restrictif
- ❌ Permissions de lecture insuffisantes

**Solutions :**
```bash
# Tester la recherche LDAP
ldapsearch -H ldaps://srv-ad1.domaines4p2.local:636 \
  -D "Administrateur@domaines4p2.local" \
  -W \
  -b "DC=DOMAINES4P2,DC=local" \
  "(objectClass=user)" sAMAccountName
```

---

## 📝 Champs LDAP additionnels

### Mapping des attributs utilisateur

Vous pouvez synchroniser des champs supplémentaires depuis AD :

| Attribut AD | Champ GLPI | Description |
|-------------|------------|-------------|
| `mail` | Email | Adresse email |
| `telephoneNumber` | Téléphone | Numéro de téléphone |
| `title` | Fonction | Titre/Fonction |
| `department` | Service | Département |
| `mobile` | Mobile | Téléphone portable |
| `manager` | Responsable | Manager hiérarchique |

---

## 🎯 Exemples de filtres avancés

### Filtrer uniquement un groupe spécifique
```
(&(objectClass=user)(objectCategory=person)(memberOf=CN=GLPI_Users,CN=Users,DC=domaines4p2,DC=local))
```

### Filtrer par OU (Unité Organisationnelle)
```
(&(objectClass=user)(objectCategory=person)(|(ou=IT)(ou=Support)))
```

### Exclure des comptes de service
```
(&(objectClass=user)(objectCategory=person)(!(sAMAccountName=svc_*)))
```

---

## 📚 Ressources

- **Documentation officielle GLPI** : https://glpi-install.readthedocs.io/
- **Forum GLPI** : https://forum.glpi-project.org/
- **Documentation Microsoft AD LDAP** : https://docs.microsoft.com/en-us/windows/win32/ad/

---

## ✅ Checklist de configuration LDAPS

- [ ] DNS configuré et testé
- [ ] Connectivité au port 636 vérifiée
- [ ] BaseDN construit correctement
- [ ] Compte de liaison créé dans AD
- [ ] Permissions de lecture LDAP accordées
- [ ] Configuration LDAPS dans GLPI
- [ ] Test de connexion réussi
- [ ] Import d'utilisateurs test effectué
- [ ] Synchronisation automatique configurée
- [ ] Authentification utilisateur testée

---

**🎉 Configuration LDAPS terminée !**
