#!/bin/bash

##############################################################################
# Script d'installation de GLPI 11.0.0 sur Ubuntu 24.04 LTS
# Basé sur la procédure d'installation GLPI V11 2025
# Auteur: Script automatisé basé sur la procédure de IRATNI Hocine
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

print_section "INSTALLATION DE GLPI 11.0.0 SUR UBUNTU"
print_info "Ce script va installer GLPI en suivant la procédure complète"
echo ""

##############################################################################
# COLLECTE DES INFORMATIONS UTILISATEUR
##############################################################################

print_section "COLLECTE DES INFORMATIONS"

# Demander l'adresse IP du serveur GLPI
while true; do
    read -p "Entrez l'adresse IP de ce serveur GLPI (ex: 192.168.1.100): " SERVER_IP
    if [[ $SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_success "Adresse IP: $SERVER_IP"
        break
    else
        print_error "Adresse IP invalide. Veuillez réessayer."
    fi
done

# Demander le mot de passe pour la base de données
while true; do
    read -sp "Entrez le mot de passe pour l'utilisateur 'glpi' de MariaDB: " DB_PASSWORD
    echo ""
    read -sp "Confirmez le mot de passe: " DB_PASSWORD_CONFIRM
    echo ""
    if [ "$DB_PASSWORD" == "$DB_PASSWORD_CONFIRM" ]; then
        print_success "Mot de passe de la base de données configuré"
        break
    else
        print_error "Les mots de passe ne correspondent pas. Veuillez réessayer."
    fi
done

echo ""
print_info "Récapitulatif de la configuration:"
echo "  - IP du serveur GLPI: $SERVER_IP"
echo "  - Mot de passe DB: ********"
echo ""
read -p "Voulez-vous continuer l'installation avec ces paramètres? (oui/non): " CONFIRM
if [[ ! $CONFIRM =~ ^[Oo][Uu][Ii]$ ]]; then
    print_error "Installation annulée par l'utilisateur"
    exit 1
fi

##############################################################################
# 1. PRÉPARATION DU SERVEUR
##############################################################################

print_section "1. PRÉPARATION DU SERVEUR"

print_info "Mise à jour du système..."
apt update && apt upgrade -y
print_success "Système mis à jour"

print_info "Installation des composants nécessaires (Apache, MariaDB, PHP et extensions)..."
apt install -y apache2 mariadb-server php php-cli php-mysql php-curl php-gd php-intl php-mbstring php-xml php-xmlrpc php-ldap php-cas php-apcu php-zip php-bz2 php8.3-bcmath -y
print_success "Composants installés"

print_info "Configuration du pare-feu..."
ufw allow 80
ufw allow 443
print_success "Pare-feu configuré (ports 80 et 443 ouverts)"

##############################################################################
# 2. CONFIGURATION DE LA BASE DE DONNÉES MARIADB
##############################################################################

print_section "2. CONFIGURATION DE LA BASE DE DONNÉES MARIADB"

print_info "Sécurisation de MariaDB..."
print_warning "Vous allez devoir répondre aux questions de sécurisation:"
echo "  - Switch to unix socket authentication [Y/n] : Y"
echo "  - Change the root password? [Y/n] : N"
echo "  - Remove anonymous users? [Y/n] : Y"
echo "  - Disallow root login remotely? [Y/n] : N"
echo "  - Remove test database and access to it? [Y/n] : Y"
echo "  - Reload privilege tables now? [Y/n] : Y"
echo ""
read -p "Appuyez sur Entrée pour continuer avec mysql_secure_installation..."

mysql_secure_installation

print_success "MariaDB sécurisée"

print_info "Création de la base de données et de l'utilisateur GLPI..."

# Créer un fichier temporaire avec les commandes SQL
cat > /tmp/glpi_setup.sql << EOF
CREATE DATABASE glpidb;
CREATE USER 'glpi'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON glpidb.* TO 'glpi'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# Exécuter les commandes SQL
mysql -u root -p < /tmp/glpi_setup.sql

# Supprimer le fichier temporaire
rm /tmp/glpi_setup.sql

print_success "Base de données 'glpidb' et utilisateur 'glpi' créés"

##############################################################################
# 3. INSTALLATION DE GLPI
##############################################################################

print_section "3. INSTALLATION DE GLPI"

print_info "Déplacement vers le répertoire /tmp/..."
cd /tmp/

print_info "Téléchargement de GLPI 11.0.0..."
wget https://github.com/glpi-project/glpi/releases/download/11.0.0/glpi-11.0.0.tgz
print_success "GLPI 11.0.0 téléchargé"

print_info "Décompression de l'archive..."
tar -xvf glpi-11.0.0.tgz > /dev/null 2>&1
print_success "Archive décompressée"

print_info "Déplacement dans le dossier web Apache..."
mv glpi /var/www/html/
print_success "GLPI déplacé vers /var/www/html/"

print_info "Configuration des permissions..."
chmod 755 -R /var/www/html/
chown www-data:www-data -R /var/www/html/
print_success "Permissions configurées"

##############################################################################
# 4. CONFIGURATION DU SERVEUR WEB APACHE
##############################################################################

print_section "4. CONFIGURATION DU SERVEUR WEB APACHE"

print_info "Création du fichier de configuration Apache pour GLPI..."
cat > /etc/apache2/sites-available/glpi.conf << EOF
<VirtualHost *:80>
# On ajoute cette ligne pour que ce site réponde à l'IP du serveur
ServerName ${SERVER_IP}
ServerAdmin webmaster@localhost
DocumentRoot /var/www/html/glpi/public
<Directory /var/www/html/glpi/public>
Require all granted
AllowOverride All
</Directory>
ErrorLog \${APACHE_LOG_DIR}/error.log
CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
print_success "Fichier glpi.conf créé"

print_info "Création du fichier .htaccess..."
cat > /var/www/html/glpi/public/.htaccess << 'EOF'
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteCond %{REQUEST_URI}::$1 ^(/.+)/(.*)::\2$
RewriteRule ^(.*) - [E=BASE:%1]
RewriteCond %{REQUEST_FILENAME} -f
RewriteRule ^ - [L]
RewriteRule ^ %{ENV:BASE}/index.php [L]
</IfModule>
EOF
print_success "Fichier .htaccess créé"

print_info "Configuration des permissions sur .htaccess et dossier GLPI..."
chown www-data:www-data /var/www/html/glpi/public/.htaccess
chown -R www-data:www-data /var/www/html/glpi
print_success "Permissions configurées"

print_info "Activation du module de réécriture d'URL (rewrite)..."
a2enmod rewrite
print_success "Module rewrite activé"

print_info "Désactivation du site par défaut..."
a2dissite 000-default.conf
print_success "Site par défaut désactivé"

print_info "Activation du site GLPI..."
a2ensite glpi.conf
print_success "Site GLPI activé"

print_info "Redémarrage d'Apache..."
systemctl restart apache2
print_success "Apache redémarré"

##############################################################################
# 5. CONFIGURATION DNS ET TESTS (OPTIONNEL - RECOMMANDÉ)
##############################################################################

print_section "5. INSTALLATION GLPI TERMINÉE - CONFIGURATION DNS"

print_success "✓ L'installation de GLPI est terminée avec succès!"
echo ""
print_info "Pour l'intégration avec Active Directory (LDAPS), il est recommandé de"
print_info "configurer le DNS maintenant pour permettre la résolution des noms de domaine."
echo ""

# Vérifier si le DNS est déjà configuré
DNS_CONFIGURED=false
if [ -f "/etc/systemd/resolved.conf" ]; then
    if grep -q "^DNS=" /etc/systemd/resolved.conf && grep -q "^Domains=" /etc/systemd/resolved.conf; then
        print_info "Configuration DNS détectée dans /etc/systemd/resolved.conf"
        
        # Afficher la configuration actuelle
        echo ""
        print_info "Configuration DNS actuelle:"
        grep "^DNS=" /etc/systemd/resolved.conf
        grep "^Domains=" /etc/systemd/resolved.conf
        echo ""
        
        DNS_CONFIGURED=true
    fi
fi

# Demander à l'utilisateur s'il veut configurer le DNS
if [ "$DNS_CONFIGURED" = true ]; then
    read -p "Voulez-vous reconfigurer le DNS? (oui/non) [non]: " CONFIGURE_DNS
    CONFIGURE_DNS=${CONFIGURE_DNS:-non}
else
    print_warning "⚠ Aucune configuration DNS personnalisée détectée"
    print_info "📌 Configuration DNS recommandée pour l'intégration LDAPS"
    echo ""
    read -p "Voulez-vous configurer le DNS maintenant? (oui/non) [oui]: " CONFIGURE_DNS
    CONFIGURE_DNS=${CONFIGURE_DNS:-oui}
fi

if [[ $CONFIGURE_DNS =~ ^[Oo][Uu][Ii]$ ]]; then
    print_section "CONFIGURATION DNS POUR LDAPS"
    
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
    print_info "Configuration DNS:"
    echo "  - Serveur DNS: $DNS_SERVER_IP"
    echo "  - Domaine: $DOMAIN_NAME"
    echo "  - FQDN AD: $AD_FQDN"
    echo ""
    
    read -p "Confirmer la configuration DNS? (oui/non): " CONFIRM_DNS
    if [[ $CONFIRM_DNS =~ ^[Oo][Uu][Ii]$ ]]; then
        
        print_info "Sauvegarde de la configuration DNS actuelle..."
        cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.backup.$(date +%Y%m%d_%H%M%S)
        print_success "Sauvegarde créée"
        
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
        
        print_info "Redémarrage du service systemd-resolved..."
        systemctl restart systemd-resolved
        sleep 2
        
        print_info "Vérification du statut du service..."
        systemctl status systemd-resolved --no-pager | head -n 5
        
        print_success "Configuration DNS terminée"
        
        ##############################################################################
        # TEST DE RÉSOLUTION DNS
        ##############################################################################
        
        print_section "TEST DE RÉSOLUTION DNS"
        
        print_info "Test de résolution DNS pour: $AD_FQDN"
        echo ""
        
        # Test avec nslookup
        if command -v nslookup &> /dev/null; then
            print_info "Test avec nslookup:"
            nslookup $AD_FQDN
            echo ""
        fi
        
        # Test avec dig
        if command -v dig &> /dev/null; then
            print_info "Test avec dig:"
            dig $AD_FQDN +short
            echo ""
        fi
        
        # Test avec ping
        print_info "Test de ping (1 paquet):"
        if ping -c 1 $AD_FQDN &> /dev/null; then
            print_success "✓ La résolution DNS fonctionne correctement!"
            print_success "✓ Le serveur $AD_FQDN est accessible"
        else
            print_warning "⚠ La résolution DNS a échoué ou le serveur n'est pas accessible"
            print_info "Vérifiez votre configuration DNS et assurez-vous que le serveur AD est en ligne"
        fi
        
        # Afficher la configuration DNS active
        print_info "Configuration DNS active:"
        resolvectl status | grep -A 5 "DNS Servers"
        
    else
        print_warning "Configuration DNS annulée"
    fi
else
    print_info "Configuration DNS ignorée - Vous pourrez la configurer plus tard avec:"
    print_info "  sudo ./configure_dns.sh"
fi

##############################################################################
# 6. RÉSUMÉ DE L'INSTALLATION
##############################################################################

print_section "INSTALLATION TERMINÉE"

echo ""
print_success "╔════════════════════════════════════════════════════════════════╗"
print_success "║          INSTALLATION DE GLPI 11.0.0 TERMINÉE                  ║"
print_success "╚════════════════════════════════════════════════════════════════╝"
echo ""

print_info "INFORMATIONS DE CONNEXION:"
echo ""
echo "  🌐 URL d'accès à GLPI:"
echo "     http://${SERVER_IP}/glpi"
echo ""
echo "  📊 Configuration de la base de données (pour l'installation web):"
echo "     - Serveur SQL: localhost"
echo "     - Utilisateur SQL: glpi"
echo "     - Mot de passe: ********"
echo "     - Base de données: glpidb"
echo ""
echo "  📁 Répertoire d'installation:"
echo "     /var/www/html/glpi"
echo ""
echo "  🔧 Logs Apache:"
echo "     /var/log/apache2/error.log"
echo "     /var/log/apache2/access.log"
echo ""

print_info "PROCHAINES ÉTAPES:"
echo ""
echo "  1. Ouvrez votre navigateur web"
echo "  2. Accédez à: http://${SERVER_IP}/glpi"
echo "  3. Suivez l'assistant d'installation web:"
echo "     - Sélectionnez la langue"
echo "     - Acceptez la licence"
echo "     - Vérifiez les prérequis"
echo "     - Configurez la base de données (utilisez les informations ci-dessus)"
echo "  4. Une fois l'installation terminée, configurez LDAPS:"
echo "     - Allez dans Configuration > Authentification > Annuaire LDAP"
echo "     - Configurez la connexion à votre Active Directory"
echo ""

if [[ $CONFIGURE_DNS =~ ^[Oo][Uu][Ii]$ ]] && [[ $CONFIRM_DNS =~ ^[Oo][Uu][Ii]$ ]]; then
    print_info "CONFIGURATION DNS:"
    echo ""
    echo "  ✓ Serveur DNS configuré: ${DNS_SERVER_IP}"
    echo "  ✓ Domaine de recherche: ${DOMAIN_NAME}"
    echo "  ✓ Fichier de configuration: /etc/systemd/resolved.conf"
    echo "  ✓ Sauvegarde: /etc/systemd/resolved.conf.backup.*"
    echo ""
else
    print_warning "CONFIGURATION DNS:"
    echo ""
    echo "  ⚠ Configuration DNS non effectuée"
    echo "  ℹ Pour configurer le DNS plus tard, exécutez:"
    echo "    sudo ./configure_dns.sh"
    echo "  ℹ La configuration DNS est nécessaire pour l'intégration LDAPS"
    echo ""
fi

print_warning "COMPTES PAR DÉFAUT GLPI (à changer après la première connexion):"
echo ""
echo "  - glpi/glpi (compte administrateur)"
echo "  - tech/tech (compte technicien)"
echo "  - normal/normal (compte normal)"
echo "  - post-only/postonly (compte post-only)"
echo ""

print_section "SCRIPT D'INSTALLATION TERMINÉ"

print_info "Pour vérifier les services:"
echo "  - sudo systemctl status apache2"
echo "  - sudo systemctl status mariadb"
echo "  - sudo systemctl status systemd-resolved"
echo ""

print_success "Bonne utilisation de GLPI! 🎉"
echo ""
