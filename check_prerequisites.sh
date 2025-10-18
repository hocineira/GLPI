#!/bin/bash

##############################################################################
# Script de vérification des prérequis pour l'installation de GLPI
# Vérifie que le système est prêt pour l'installation
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
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Fonction pour afficher un titre de section
print_section() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Compteurs
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

print_section "VÉRIFICATION DES PRÉREQUIS POUR GLPI"

##############################################################################
# 1. VÉRIFICATION DU SYSTÈME D'EXPLOITATION
##############################################################################

print_section "1. SYSTÈME D'EXPLOITATION"

# Vérifier Ubuntu
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
        print_success "Ubuntu détecté: $VERSION"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        
        # Vérifier la version
        VERSION_ID_NUM=$(echo $VERSION_ID | cut -d'.' -f1)
        if [ "$VERSION_ID_NUM" -ge 24 ]; then
            print_success "Version Ubuntu compatible (>= 24.04)"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
        else
            print_warning "Version Ubuntu < 24.04 - Recommandé: 24.04 LTS"
            CHECKS_WARNING=$((CHECKS_WARNING + 1))
        fi
    else
        print_error "Ce n'est pas Ubuntu - OS détecté: $ID"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
else
    print_error "Impossible de déterminer le système d'exploitation"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Vérifier l'architecture
ARCH=$(uname -m)
print_info "Architecture: $ARCH"

##############################################################################
# 2. VÉRIFICATION DES PRIVILÈGES
##############################################################################

print_section "2. PRIVILÈGES UTILISATEUR"

if [[ $EUID -eq 0 ]]; then
    print_success "Script exécuté en tant que root"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    if sudo -n true 2>/dev/null; then
        print_success "Utilisateur a les privilèges sudo"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        print_error "Privilèges root ou sudo requis"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
fi

##############################################################################
# 3. VÉRIFICATION DE LA CONNEXION INTERNET
##############################################################################

print_section "3. CONNEXION INTERNET"

if ping -c 1 8.8.8.8 &> /dev/null; then
    print_success "Connexion Internet disponible"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    print_error "Pas de connexion Internet - Nécessaire pour télécharger GLPI et les paquets"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Test de résolution DNS
if ping -c 1 github.com &> /dev/null; then
    print_success "Résolution DNS fonctionnelle"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    print_warning "Problème de résolution DNS"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
fi

##############################################################################
# 4. VÉRIFICATION DE L'ESPACE DISQUE
##############################################################################

print_section "4. ESPACE DISQUE"

# Vérifier l'espace disponible sur /
ROOT_SPACE=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
print_info "Espace disponible sur /: ${ROOT_SPACE}GB"

if [ "$ROOT_SPACE" -ge 5 ]; then
    print_success "Espace disque suffisant (>= 5GB recommandé)"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    print_warning "Espace disque faible - Recommandé: au moins 5GB"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
fi

# Vérifier l'espace disponible sur /var
VAR_SPACE=$(df -BG /var | tail -1 | awk '{print $4}' | sed 's/G//')
print_info "Espace disponible sur /var: ${VAR_SPACE}GB"

if [ "$VAR_SPACE" -ge 10 ]; then
    print_success "Espace disque suffisant sur /var (>= 10GB recommandé)"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    print_warning "Espace disque faible sur /var - Recommandé: au moins 10GB"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
fi

##############################################################################
# 5. VÉRIFICATION DE LA MÉMOIRE
##############################################################################

print_section "5. MÉMOIRE RAM"

TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
print_info "RAM totale: ${TOTAL_RAM}MB"

if [ "$TOTAL_RAM" -ge 2048 ]; then
    print_success "RAM suffisante (>= 2GB recommandé)"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
elif [ "$TOTAL_RAM" -ge 1024 ]; then
    print_warning "RAM limitée - Recommandé: au moins 2GB"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
else
    print_error "RAM insuffisante - Minimum requis: 1GB"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

##############################################################################
# 6. VÉRIFICATION DES PORTS
##############################################################################

print_section "6. PORTS RÉSEAU"

# Vérifier si le port 80 est disponible
if netstat -tuln 2>/dev/null | grep -q ":80 " || ss -tuln 2>/dev/null | grep -q ":80 "; then
    print_warning "Port 80 (HTTP) déjà utilisé - Arrêtez le service utilisant ce port avant l'installation"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
else
    print_success "Port 80 (HTTP) disponible"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# Vérifier si le port 443 est disponible
if netstat -tuln 2>/dev/null | grep -q ":443 " || ss -tuln 2>/dev/null | grep -q ":443 "; then
    print_warning "Port 443 (HTTPS) déjà utilisé"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
else
    print_success "Port 443 (HTTPS) disponible"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# Vérifier si le port 3306 est disponible
if netstat -tuln 2>/dev/null | grep -q ":3306 " || ss -tuln 2>/dev/null | grep -q ":3306 "; then
    print_warning "Port 3306 (MySQL/MariaDB) déjà utilisé - Une base de données est peut-être déjà installée"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
else
    print_success "Port 3306 (MySQL/MariaDB) disponible"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

##############################################################################
# 7. VÉRIFICATION DES LOGICIELS EXISTANTS
##############################################################################

print_section "7. LOGICIELS INSTALLÉS"

# Vérifier Apache
if command -v apache2 &> /dev/null; then
    APACHE_VERSION=$(apache2 -v | head -n1)
    print_warning "Apache déjà installé: $APACHE_VERSION"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
else
    print_info "Apache non installé (sera installé par le script)"
fi

# Vérifier MariaDB/MySQL
if command -v mysql &> /dev/null; then
    MYSQL_VERSION=$(mysql --version)
    print_warning "MySQL/MariaDB déjà installé: $MYSQL_VERSION"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
else
    print_info "MariaDB non installé (sera installé par le script)"
fi

# Vérifier PHP
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -n1)
    print_warning "PHP déjà installé: $PHP_VERSION"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
else
    print_info "PHP non installé (sera installé par le script)"
fi

# Vérifier si GLPI est déjà installé
if [ -d "/var/www/html/glpi" ]; then
    print_error "GLPI semble déjà installé dans /var/www/html/glpi"
    print_error "Sauvegardez vos données et supprimez le répertoire avant de réinstaller"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
else
    print_success "Aucune installation GLPI existante détectée"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

##############################################################################
# 8. VÉRIFICATION DE LA CONNECTIVITÉ RÉSEAU
##############################################################################

print_section "8. CONNECTIVITÉ RÉSEAU"

# Obtenir l'adresse IP
IP_ADDRESS=$(hostname -I | awk '{print $1}')
if [ -n "$IP_ADDRESS" ]; then
    print_success "Adresse IP locale: $IP_ADDRESS"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    print_warning "Impossible de déterminer l'adresse IP"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
fi

# Vérifier le hostname
HOSTNAME=$(hostname)
print_info "Nom d'hôte: $HOSTNAME"

# Vérifier la passerelle par défaut
GATEWAY=$(ip route | grep default | awk '{print $3}')
if [ -n "$GATEWAY" ]; then
    print_success "Passerelle par défaut: $GATEWAY"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    print_warning "Pas de passerelle par défaut configurée"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
fi

##############################################################################
# 9. VÉRIFICATION DES OUTILS NÉCESSAIRES
##############################################################################

print_section "9. OUTILS SYSTÈME"

# Vérifier wget
if command -v wget &> /dev/null; then
    print_success "wget installé"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    print_warning "wget non installé (sera installé par apt)"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
fi

# Vérifier tar
if command -v tar &> /dev/null; then
    print_success "tar installé"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    print_error "tar non installé - Nécessaire pour décompresser GLPI"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Vérifier systemctl
if command -v systemctl &> /dev/null; then
    print_success "systemd disponible"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    print_error "systemd non disponible - Requis pour gérer les services"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

##############################################################################
# 10. VÉRIFICATION DES MISES À JOUR
##############################################################################

print_section "10. MISES À JOUR SYSTÈME"

print_info "Vérification des mises à jour disponibles..."
apt-get update &> /dev/null

UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
if [ "$UPDATES" -gt 0 ]; then
    print_warning "$UPDATES mises à jour disponibles - Le script effectuera les mises à jour"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
else
    print_success "Système à jour"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

##############################################################################
# RÉSUMÉ
##############################################################################

print_section "RÉSUMÉ DE LA VÉRIFICATION"

echo ""
print_info "Résultats de la vérification:"
echo ""
print_success "Tests réussis: $CHECKS_PASSED"
print_warning "Avertissements: $CHECKS_WARNING"
print_error "Tests échoués: $CHECKS_FAILED"
echo ""

if [ "$CHECKS_FAILED" -eq 0 ]; then
    print_success "╔════════════════════════════════════════════════════════════════╗"
    print_success "║  ✓ Le système est PRÊT pour l'installation de GLPI            ║"
    print_success "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [ "$CHECKS_WARNING" -gt 0 ]; then
        print_warning "Quelques avertissements ont été détectés, mais l'installation peut continuer"
        echo ""
    fi
    
    print_info "Pour démarrer l'installation, exécutez:"
    echo "  sudo ./install_glpi.sh"
    echo ""
    
    exit 0
else
    print_error "╔════════════════════════════════════════════════════════════════╗"
    print_error "║  ✗ Le système N'EST PAS prêt pour l'installation              ║"
    print_error "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    print_error "Veuillez corriger les problèmes détectés avant de continuer"
    echo ""
    
    exit 1
fi
