# 🔄 Modifications du script install_glpi.sh

## 📋 Résumé des changements

Le script `install_glpi.sh` a été modifié pour **proposer la configuration DNS à la fin de l'installation** au lieu de la demander au début. Cette approche est plus flexible et recommandée.

---

## ✨ Nouvelles fonctionnalités

### 1. Configuration DNS optionnelle en fin d'installation

**Avant :** Le DNS était configuré au début, obligatoirement.

**Maintenant :** 
- L'installation de GLPI se fait d'abord
- À la fin, le script propose la configuration DNS
- L'utilisateur peut choisir de configurer maintenant ou plus tard

### 2. Détection automatique de la configuration DNS existante

Le script vérifie automatiquement si une configuration DNS personnalisée existe déjà :

```bash
✓ Si DNS déjà configuré :
  → Affiche la configuration actuelle
  → Demande : "Voulez-vous reconfigurer le DNS?"
  → Par défaut : NON

✓ Si DNS non configuré :
  → Message : "Configuration DNS recommandée pour l'intégration LDAPS"
  → Demande : "Voulez-vous configurer le DNS maintenant?"
  → Par défaut : OUI
```

### 3. Tests DNS automatiques (si configuré)

Si l'utilisateur configure le DNS, le script effectue automatiquement :
- Test avec `nslookup`
- Test avec `dig`
- Test de `ping`
- Affichage de la configuration DNS active

### 4. Information claire sur le statut DNS

Dans le résumé final, le script affiche :

**Si DNS configuré :**
```
CONFIGURATION DNS:
  ✓ Serveur DNS configuré: 192.168.1.10
  ✓ Domaine de recherche: domaines4p2.local
  ✓ Fichier de configuration: /etc/systemd/resolved.conf
  ✓ Sauvegarde: /etc/systemd/resolved.conf.backup.*
```

**Si DNS non configuré :**
```
CONFIGURATION DNS:
  ⚠ Configuration DNS non effectuée
  ℹ Pour configurer le DNS plus tard, exécutez:
    sudo ./configure_dns.sh
  ℹ La configuration DNS est nécessaire pour l'intégration LDAPS
```

---

## 🔄 Flux d'exécution du nouveau script

```
┌─────────────────────────────────────────┐
│  1. Collecte des informations          │
│     • IP du serveur GLPI               │
│     • Mot de passe DB                  │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  2. Installation système                │
│     • Mise à jour Ubuntu               │
│     • Installation Apache              │
│     • Installation MariaDB             │
│     • Installation PHP 8.3             │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  3. Configuration MariaDB               │
│     • Sécurisation                     │
│     • Création base glpidb             │
│     • Création utilisateur glpi        │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  4. Installation GLPI 11.0.0            │
│     • Téléchargement                   │
│     • Extraction                       │
│     • Configuration permissions        │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  5. Configuration Apache                │
│     • VirtualHost                      │
│     • .htaccess                        │
│     • Module rewrite                   │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  6. ⭐ Configuration DNS (OPTIONNEL)    │
│                                         │
│  Détection config DNS existante ?       │
│         ↓                 ↓             │
│       OUI               NON             │
│         ↓                 ↓             │
│  Reconfigurer ?    Configurer ?         │
│   [non] / oui     [oui] / non          │
│         ↓                 ↓             │
│         └─────────┬───────┘             │
│                   ↓                     │
│            SI ACCEPTÉ:                  │
│         • Demande IP DNS (AD)           │
│         • Demande domaine               │
│         • Demande FQDN AD               │
│         • Configure resolved.conf       │
│         • Tests DNS                     │
│                                         │
│            SI REFUSÉ:                   │
│         • Continue sans DNS             │
│         • Info: ./configure_dns.sh      │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  7. Résumé final                        │
│     • URL d'accès GLPI                 │
│     • Infos DB                         │
│     • Statut DNS                       │
│     • Prochaines étapes                │
└─────────────────────────────────────────┘
```

---

## 📊 Comparaison Avant / Après

| Aspect | Avant | Après |
|--------|-------|-------|
| **Moment de config DNS** | Au début (obligatoire) | À la fin (optionnel) |
| **Questions au début** | IP GLPI + DB + DNS + Domaine + FQDN | IP GLPI + DB seulement |
| **Flexibilité** | DNS obligatoire | DNS optionnel |
| **Détection DNS existant** | Non | Oui |
| **Tests DNS** | Toujours | Seulement si configuré |
| **Info sur statut DNS** | Toujours "configuré" | "Configuré" ou "Non configuré" |
| **Configuration ultérieure** | Difficile | Facile avec configure_dns.sh |

---

## 💡 Avantages de la nouvelle approche

1. **✅ Plus flexible**
   - L'utilisateur peut choisir de configurer le DNS plus tard
   - Utile si l'AD n'est pas encore prêt

2. **✅ Installation GLPI plus rapide**
   - Moins de questions au début
   - Installation basique fonctionnelle plus rapidement

3. **✅ Meilleure expérience utilisateur**
   - Configuration DNS recommandée mais pas obligatoire
   - Message clair sur l'importance du DNS pour LDAPS

4. **✅ Détection intelligente**
   - Vérifie si DNS déjà configuré
   - Évite de reconfigurer inutilement

5. **✅ Facilite les tests**
   - Permet de tester GLPI sans AD
   - Possibilité de configurer DNS plus tard

---

## 🎯 Cas d'usage

### Cas 1 : Installation complète avec DNS
```bash
sudo ./install_glpi.sh
# → Répond aux questions de base
# → Attend la fin de l'installation
# → Accepte la configuration DNS
# → Fournit infos AD
# → Teste la résolution DNS
# ✓ Installation complète avec DNS configuré
```

### Cas 2 : Installation sans DNS (configuration ultérieure)
```bash
sudo ./install_glpi.sh
# → Répond aux questions de base
# → Attend la fin de l'installation
# → Refuse la configuration DNS
# ✓ GLPI installé, DNS à configurer plus tard

# Plus tard, quand l'AD est prêt:
sudo ./configure_dns.sh
# → Configure le DNS
# → Teste la résolution
# ✓ DNS configuré
```

### Cas 3 : DNS déjà configuré
```bash
sudo ./install_glpi.sh
# → Répond aux questions de base
# → Attend la fin de l'installation
# → Script détecte DNS existant
# → Affiche config actuelle
# → Propose de reconfigurer (par défaut: NON)
# ✓ Conserve la configuration DNS existante
```

---

## 📝 Messages affichés à l'utilisateur

### Si DNS non configuré (recommandation)
```
╔═══════════════════════════════════════════════════════════════╗
║         INSTALLATION GLPI TERMINÉE - CONFIGURATION DNS        ║
╚═══════════════════════════════════════════════════════════════╝

[INFO] Pour l'intégration avec Active Directory (LDAPS), il est
       recommandé de configurer le DNS maintenant pour permettre
       la résolution des noms de domaine.

[WARNING] ⚠ Aucune configuration DNS personnalisée détectée
[INFO] 📌 Configuration DNS recommandée pour l'intégration LDAPS

Voulez-vous configurer le DNS maintenant? (oui/non) [oui]:
```

### Si DNS déjà configuré
```
╔═══════════════════════════════════════════════════════════════╗
║         INSTALLATION GLPI TERMINÉE - CONFIGURATION DNS        ║
╚═══════════════════════════════════════════════════════════════╝

[INFO] Configuration DNS détectée dans /etc/systemd/resolved.conf

[INFO] Configuration DNS actuelle:
DNS=192.168.1.10
Domains=domaines4p2.local

Voulez-vous reconfigurer le DNS? (oui/non) [non]:
```

### Si l'utilisateur refuse
```
[INFO] Configuration DNS ignorée - Vous pourrez la configurer
       plus tard avec:
         sudo ./configure_dns.sh
```

---

## 🔧 Fichiers modifiés

- **`/app/install_glpi.sh`** - Script principal d'installation
  - Suppression de la collecte DNS au début
  - Ajout de la section DNS optionnelle à la fin
  - Ajout de la détection DNS existante
  - Mise à jour du résumé final

---

## ✅ Tests à effectuer

### Test 1 : Installation avec DNS
```bash
sudo ./install_glpi.sh
# Accepter la configuration DNS
# Vérifier que le DNS fonctionne
```

### Test 2 : Installation sans DNS
```bash
sudo ./install_glpi.sh
# Refuser la configuration DNS
# Vérifier que GLPI fonctionne quand même
```

### Test 3 : Configuration DNS ultérieure
```bash
sudo ./configure_dns.sh
# Configurer après l'installation
```

### Test 4 : DNS déjà configuré
```bash
# Configurer manuellement /etc/systemd/resolved.conf
sudo ./install_glpi.sh
# Vérifier la détection
```

---

## 📞 Compatibilité

✅ **Compatible avec :**
- La procédure originale (Procédure_GLPI_V11_2025.pdf)
- Ubuntu 24.04 LTS
- GLPI 11.0.0
- Le script `configure_dns.sh` (toujours disponible)

✅ **Aucun changement sur :**
- Installation d'Apache
- Installation de MariaDB
- Installation de PHP
- Configuration de GLPI
- Configuration Apache

---

## 🎉 Résultat

Le script `install_glpi.sh` est maintenant **plus flexible et plus convivial** :

1. ✅ Installation GLPI rapide (sans DNS si besoin)
2. ✅ Configuration DNS recommandée en fin d'installation
3. ✅ Détection automatique de DNS existant
4. ✅ Tests DNS automatiques si configuré
5. ✅ Possibilité de configurer DNS plus tard
6. ✅ Messages clairs sur le statut DNS

**L'utilisateur a le contrôle total sur la configuration DNS !** 🎯
