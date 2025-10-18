#!/bin/bash

##############################################################################
# Script de configuration DNS pour préparation LDAPS
# Configuration de /etc/systemd/resolved.conf pour intégration Active Directory
##############################################################################

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour afficher un titre de section
print_section() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Vérifier que le script est exécuté en tant que root
if [[ $EUID -ne 0 ]]; then
   print_error "Ce script doit être exécuté en tant que root (sudo)"
   exit 1
fi

print_section "CONFIGURATION DNS POUR INTÉGRATION LDAPS"

##############################################################################
# COLLECTE DES INFORMATIONS
##############################################################################

print_info "Ce script va configurer le DNS pour préparer l'intégration avec Active Directory"
echo ""

# Demander l'IP du serveur DNS (Active Directory)
while true; do
    read -p "Entrez l'adresse IP du serveur DNS (Active Directory) (ex: 192.168.1.10): " DNS_SERVER_IP
    if [[ $DNS_SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_success "Serveur DNS: $DNS_SERVER_IP"
        break
    else
        print_error "Adresse IP invalide. Veuillez réessayer."
    fi
done

# Demander le nom de domaine
read -p "Entrez le nom de domaine (ex: domaines4p2.local): " DOMAIN_NAME
print_success "Domaine: $DOMAIN_NAME"

# Demander le FQDN de l'AD pour le test DNS
read -p "Entrez le FQDN de votre serveur AD pour tester la résolution DNS (ex: srv-ad1.domaines4p2.local): " AD_FQDN
print_success "FQDN de l'AD pour test: $AD_FQDN"

echo ""
print_info "Récapitulatif de la configuration:"
echo "  - Serveur DNS (AD): $DNS_SERVER_IP"
echo "  - Domaine: $DOMAIN_NAME"
echo "  - FQDN AD (test): $AD_FQDN"
echo ""
read -p "Voulez-vous continuer avec ces paramètres? (oui/non): " CONFIRM
if [[ ! $CONFIRM =~ ^[Oo][Uu][Ii]$ ]]; then
    print_error "Configuration annulée par l'utilisateur"
    exit 1
fi

##############################################################################
# CONFIGURATION DNS
##############################################################################

print_section "CONFIGURATION DNS"

# Afficher la configuration actuelle
print_info "Configuration DNS actuelle:"
echo ""
cat /etc/systemd/resolved.conf
echo ""

print_info "Sauvegarde de la configuration DNS actuelle..."
cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.backup.$(date +%Y%m%d_%H%M%S)
print_success "Sauvegarde créée: /etc/systemd/resolved.conf.backup.$(date +%Y%m%d_%H%M%S)"

print_info "Configuration de /etc/systemd/resolved.conf..."
cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=${DNS_SERVER_IP}
FallbackDNS=8.8.8.8 8.8.4.4
Domains=${DOMAIN_NAME}
DNSSEC=no
DNSOverTLS=no
Cache=yes
DNSStubListener=yes
EOF

print_success "Fichier /etc/systemd/resolved.conf configuré"

print_info "Nouvelle configuration:"
echo ""
cat /etc/systemd/resolved.conf
echo ""

print_info "Redémarrage du service systemd-resolved..."
systemctl restart systemd-resolved
sleep 2

print_info "Vérification du statut du service..."
systemctl status systemd-resolved --no-pager | head -n 10
echo ""

print_success "Configuration DNS terminée"

##############################################################################
# TEST DE RÉSOLUTION DNS
##############################################################################

print_section "TEST DE RÉSOLUTION DNS"

print_info "Test de résolution DNS pour: $AD_FQDN"
echo ""

# Afficher la configuration DNS active
print_info "Configuration DNS active:"
resolvectl status | grep -A 10 "DNS Servers"
echo ""

# Test avec nslookup
if command -v nslookup &> /dev/null; then
    print_info "Test avec nslookup:"
    nslookup $AD_FQDN
    echo ""
else
    print_warning "nslookup n'est pas installé"
fi

# Test avec dig
if command -v dig &> /dev/null; then
    print_info "Test avec dig:"
    dig $AD_FQDN +short
    echo ""
else
    print_warning "dig n'est pas installé"
fi

# Test avec host
if command -v host &> /dev/null; then
    print_info "Test avec host:"
    host $AD_FQDN
    echo ""
fi

# Test avec ping
print_info "Test de ping (3 paquets):"
if ping -c 3 $AD_FQDN; then
    echo ""
    print_success "✓ La résolution DNS fonctionne correctement!"
    print_success "✓ Le serveur $AD_FQDN est accessible"
else
    echo ""
    print_warning "⚠ La résolution DNS a échoué ou le serveur n'est pas accessible"
    print_info "Vérifications à effectuer:"
    echo "  1. Vérifiez que le serveur DNS $DNS_SERVER_IP est en ligne"
    echo "  2. Vérifiez que le serveur AD $AD_FQDN est démarré"
    echo "  3. Vérifiez les règles de pare-feu"
    echo "  4. Vérifiez la connectivité réseau"
fi

##############################################################################
# TESTS SUPPLÉMENTAIRES
##############################################################################

print_section "TESTS SUPPLÉMENTAIRES"

print_info "Test de résolution du domaine:"
nslookup $DOMAIN_NAME 2>/dev/null || print_warning "Impossible de résoudre $DOMAIN_NAME"
echo ""

print_info "Test de connexion au port LDAPS (636):"
if command -v nc &> /dev/null; then
    timeout 3 nc -zv ${AD_FQDN} 636 2>&1 || print_warning "Le port LDAPS (636) n'est pas accessible"
else
    print_warning "netcat (nc) n'est pas installé - impossible de tester le port LDAPS"
fi
echo ""

print_info "Test de connexion au port LDAP (389):"
if command -v nc &> /dev/null; then
    timeout 3 nc -zv ${AD_FQDN} 389 2>&1 || print_warning "Le port LDAP (389) n'est pas accessible"
else
    print_warning "netcat (nc) n'est pas installé - impossible de tester le port LDAP"
fi
echo ""

##############################################################################
# RÉSUMÉ
##############################################################################

print_section "CONFIGURATION TERMINÉE"

echo ""
print_success "╔════════════════════════════════════════════════════════════════╗"
print_success "║        CONFIGURATION DNS POUR LDAPS TERMINÉE                   ║"
print_success "╚════════════════════════════════════════════════════════════════╝"
echo ""

print_info "INFORMATIONS DE CONFIGURATION:"
echo ""
echo "  🌐 Serveur DNS: ${DNS_SERVER_IP}"
echo "  🌐 Domaine de recherche: ${DOMAIN_NAME}"
echo "  🌐 FQDN de l'AD: ${AD_FQDN}"
echo ""
echo "  📁 Fichier de configuration: /etc/systemd/resolved.conf"
echo "  📁 Sauvegarde: /etc/systemd/resolved.conf.backup.*"
echo ""

print_info "COMMANDES UTILES:"
echo ""
echo "  - Vérifier le statut DNS:"
echo "    sudo systemctl status systemd-resolved"
echo ""
echo "  - Afficher la configuration DNS active:"
echo "    resolvectl status"
echo ""
echo "  - Tester la résolution d'un nom:"
echo "    nslookup nom_serveur.${DOMAIN_NAME}"
echo ""
echo "  - Restaurer la configuration précédente:"
echo "    sudo cp /etc/systemd/resolved.conf.backup.* /etc/systemd/resolved.conf"
echo "    sudo systemctl restart systemd-resolved"
echo ""

print_info "PROCHAINES ÉTAPES:"
echo ""
echo "  1. Si les tests DNS sont réussis, vous pouvez maintenant:"
echo "     - Configurer GLPI pour l'authentification LDAPS"
echo "     - Tester la connexion LDAPS depuis GLPI"
echo ""
echo "  2. Configuration LDAPS dans GLPI:"
echo "     - URL: Configuration > Authentification > Annuaire LDAP"
echo "     - Serveur: ldaps://${AD_FQDN}"
echo "     - Port: 636"
echo "     - BaseDN: DC=...,DC=... (selon votre domaine)"
echo ""

print_section "SCRIPT DE CONFIGURATION DNS TERMINÉ"

print_success "Configuration DNS prête pour l'intégration LDAPS! 🎉"
echo ""
