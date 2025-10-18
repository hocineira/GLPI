# 🚀 NOUVEAU : Guide d'utilisation install_glpi.sh v2

## ⭐ Qu'est-ce qui a changé ?

Le script `install_glpi.sh` propose maintenant la **configuration DNS à la FIN** de l'installation, 
avec détection automatique et possibilité de la faire plus tard !

---

## 📋 Utilisation

### Étape 1 : Lancer le script

```bash
sudo ./install_glpi.sh
```

### Étape 2 : Répondre aux questions de base

Le script demande **SEULEMENT** :

```
✏️ Adresse IP du serveur GLPI: _______________
✏️ Mot de passe pour la base de données: _______________
```

**C'est tout !** Pas de questions DNS au début 👍

### Étape 3 : L'installation se déroule automatiquement

```
✓ Mise à jour système
✓ Installation Apache, MariaDB, PHP
✓ Création base de données
✓ Téléchargement GLPI 11.0.0
✓ Configuration Apache
```

### Étape 4 : Configuration DNS (RECOMMANDÉ)

**À la fin de l'installation**, le script demande :

```
╔═══════════════════════════════════════════════════════════╗
║     INSTALLATION GLPI TERMINÉE - CONFIGURATION DNS        ║
╚═══════════════════════════════════════════════════════════╝

[INFO] Pour l'intégration avec Active Directory (LDAPS), 
       il est recommandé de configurer le DNS maintenant.

[WARNING] ⚠ Aucune configuration DNS personnalisée détectée
[INFO] 📌 Configuration DNS recommandée pour l'intégration LDAPS

Voulez-vous configurer le DNS maintenant? (oui/non) [oui]:
```

#### Option A : OUI - Configurer maintenant (Recommandé)

```
→ Entrez l'IP du serveur DNS (AD): _______________
→ Entrez le nom de domaine: _______________
→ Entrez le FQDN de l'AD: _______________

✓ Configuration DNS effectuée
✓ Tests de résolution DNS automatiques
✓ Prêt pour LDAPS !
```

#### Option B : NON - Configurer plus tard

```
[INFO] Configuration DNS ignorée
[INFO] Vous pourrez la configurer plus tard avec:
       sudo ./configure_dns.sh
```

---

## 🎯 Scénarios d'utilisation

### Scénario 1 : Tout configurer maintenant

**Idéal si votre Active Directory est prêt**

```bash
sudo ./install_glpi.sh
# Questions de base → OUI
# Infos GLPI → ✓
# Installation → ✓
# Config DNS ? → OUI ✓
# Infos DNS → ✓
# Tests DNS → ✓

➜ Installation complète avec DNS !
```

---

### Scénario 2 : Installation GLPI d'abord, DNS plus tard

**Idéal si l'AD n'est pas encore prêt**

```bash
# Étape 1 : Installer GLPI
sudo ./install_glpi.sh
# Questions de base → OUI
# Infos GLPI → ✓
# Installation → ✓
# Config DNS ? → NON

➜ GLPI installé et fonctionnel !
   (sans intégration AD pour l'instant)

# Étape 2 : Quand l'AD est prêt
sudo ./configure_dns.sh
# Infos DNS → ✓
# Tests DNS → ✓

➜ DNS configuré, prêt pour LDAPS !
```

---

### Scénario 3 : DNS déjà configuré

**Si vous avez déjà configuré le DNS manuellement**

```bash
sudo ./install_glpi.sh
# Questions de base → OUI
# Infos GLPI → ✓
# Installation → ✓

[INFO] Configuration DNS détectée !
[INFO] Configuration actuelle:
       DNS=192.168.1.10
       Domains=domaines4p2.local

Reconfigurer le DNS ? (oui/non) [non]:
# → NON

➜ Conserve votre configuration DNS existante !
```

---

## 📊 Comparaison avec l'ancienne version

| Aspect | Ancienne version | ⭐ Nouvelle version |
|--------|------------------|---------------------|
| Questions au début | 5 questions | **2 questions** |
| Configuration DNS | Obligatoire | **Optionnelle** |
| Détection DNS existant | Non | **Oui** |
| Config DNS ultérieure | Difficile | **Facile** |
| Flexibilité | Faible | **Élevée** |
| Tests DNS | Toujours | **Si configuré** |

---

## 💡 Avantages

### ✅ Plus rapide
- Moins de questions au début
- Installation GLPI fonctionnelle plus vite

### ✅ Plus flexible
- DNS optionnel
- Configuration ultérieure facile

### ✅ Plus intelligent
- Détecte DNS existant
- Ne reconfigure pas inutilement

### ✅ Plus clair
- Recommandation visible
- Statut DNS affiché dans le résumé

---

## 📝 Résumé final affiché

### Si DNS configuré ✅

```
╔═══════════════════════════════════════════════════════════╗
║             INSTALLATION DE GLPI 11.0.0 TERMINÉE          ║
╚═══════════════════════════════════════════════════════════╝

URL d'accès : http://192.168.1.100/glpi

Configuration base de données :
  • Serveur SQL : localhost
  • Utilisateur : glpi
  • Base de données : glpidb

CONFIGURATION DNS :
  ✓ Serveur DNS configuré : 192.168.1.10
  ✓ Domaine de recherche : domaines4p2.local
  ✓ Fichier : /etc/systemd/resolved.conf

PROCHAINES ÉTAPES :
  1. Accédez à http://192.168.1.100/glpi
  2. Terminez l'installation web
  3. Configurez LDAPS dans GLPI
```

### Si DNS NON configuré ⚠️

```
╔═══════════════════════════════════════════════════════════╗
║             INSTALLATION DE GLPI 11.0.0 TERMINÉE          ║
╚═══════════════════════════════════════════════════════════╝

URL d'accès : http://192.168.1.100/glpi

Configuration base de données :
  • Serveur SQL : localhost
  • Utilisateur : glpi
  • Base de données : glpidb

CONFIGURATION DNS :
  ⚠ Configuration DNS non effectuée
  ℹ Pour configurer le DNS plus tard :
    sudo ./configure_dns.sh
  ℹ La configuration DNS est nécessaire pour l'intégration LDAPS

PROCHAINES ÉTAPES :
  1. Accédez à http://192.168.1.100/glpi
  2. Terminez l'installation web
  3. Configurez le DNS avant LDAPS
```

---

## 🔧 Configuration DNS ultérieure

Si vous avez choisi **NON** lors de l'installation, configurez le DNS facilement :

```bash
sudo ./configure_dns.sh
```

Ce script autonome :
- Configure `/etc/systemd/resolved.conf`
- Redémarre le service DNS
- Teste la résolution vers l'AD
- Teste la connectivité LDAP/LDAPS

---

## ✅ Checklist d'utilisation

### Installation de base
- [ ] Préparer les informations (IP serveur, mot de passe DB)
- [ ] Exécuter `sudo ./install_glpi.sh`
- [ ] Répondre aux 2 questions de base
- [ ] Attendre la fin de l'installation GLPI

### Configuration DNS (recommandé)
- [ ] L'AD est-il prêt et accessible ?
  - **OUI** → Configurer maintenant ✓
  - **NON** → Configurer plus tard avec `configure_dns.sh`

### Après installation
- [ ] Accéder à `http://VOTRE_IP/glpi`
- [ ] Terminer l'installation web
- [ ] Changer les mots de passe par défaut
- [ ] Configurer LDAPS (si DNS configuré)

---

## 🎯 Recommandation

**Si votre Active Directory est prêt** : Configurez le DNS pendant l'installation (répondez **OUI**)

**Si l'AD n'est pas prêt** : Installez GLPI d'abord (répondez **NON**), configurez DNS plus tard

**Dans tous les cas** : Le DNS est **NÉCESSAIRE** pour l'intégration LDAPS !

---

## 📞 Besoin d'aide ?

- **Documentation complète** : `README_GLPI.md`
- **Guide DNS détaillé** : `LDAPS_CONFIGURATION.md`
- **Script DNS seul** : `configure_dns.sh`
- **Changelog** : `CHANGELOG_SCRIPT.md`

---

**🎉 Profitez de la nouvelle flexibilité du script !**
