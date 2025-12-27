
#!/bin/bash
###############################################################################
# Web Checker - Auto Installation Script for Ubuntu 22.04
# EC2 Amazon Optimized Configuration
# CPU: 2 vCPU, RAM: 7.7GB
###############################################################################

set -e  # Exit on error

echo "=========================================="
echo "  Web Checker - Ubuntu 22.04 Installation"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Update system
echo -e "${GREEN}[1/10] Updating system packages...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

# Install required packages
echo -e "${GREEN}[2/10] Installing required packages...${NC}"
apt-get install -y -qq \
    software-properties-common \
    curl \
    wget \
    git \
    unzip \
    build-essential \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libxslt1-dev \
    libgmp-dev \
    libc-client-dev \
    libkrb5-dev \
    libmcrypt-dev \
    libedit-dev \
    libpspell-dev \
    librecode-dev \
    libsnmp-dev \
    libtidy-dev \
    libxslt-dev \
    libyaml-dev \
    libffi-dev \
    libmagickwand-dev \
    ca-certificates \
    gnupg \
    lsb-release

# Add PHP repository (PHP 8.2)
echo -e "${GREEN}[3/10] Adding PHP repository...${NC}"
add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
apt-get update -qq

# Install PHP 8.2 and extensions
echo -e "${GREEN}[4/10] Installing PHP 8.2 and extensions...${NC}"
apt-get install -y -qq \
    php8.2 \
    php8.2-fpm \
    php8.2-cli \
    php8.2-common \
    php8.2-mysql \
    php8.2-zip \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-curl \
    php8.2-xml \
    php8.2-bcmath \
    php8.2-intl \
    php8.2-soap \
    php8.2-readline \
    php8.2-opcache \
    php8.2-json \
    php8.2-tidy \
    php8.2-snmp \
    php8.2-xsl \
    php8.2-imagick

# Install Apache
echo -e "${GREEN}[5/10] Installing Apache...${NC}"
apt-get install -y -qq apache2

# Install Apache modules
echo -e "${GREEN}[6/10] Enabling Apache modules...${NC}"
a2enmod rewrite
a2enmod headers
a2enmod ssl
a2enmod proxy
a2enmod proxy_fcgi
a2enmod setenvif
a2enmod http2
a2enmod deflate
a2enmod expires
a2enmod filter

# Configure PHP-FPM
echo -e "${GREEN}[7/10] Configuring PHP-FPM...${NC}"

# PHP-FPM pool configuration for EC2 (2 vCPU, 7.7GB RAM)
cat > /etc/php/8.2/fpm/pool.d/www.conf << 'EOFPHPFPM'
[www]
user = www-data
group = www-data
listen = /run/php/php8.2-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

; Process manager settings optimized for 2 vCPU, 7.7GB RAM
pm = dynamic
pm.max_children = 20
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 6
pm.max_requests = 500
pm.process_idle_timeout = 10s

; Logging
php_admin_value[error_log] = /var/log/php8.2-fpm.log
php_admin_flag[log_errors] = on

; Security
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen
php_admin_value[open_basedir] = /var/www:/tmp:/var/tmp

; Performance
php_admin_value[realpath_cache_size] = 4096K
php_admin_value[realpath_cache_ttl] = 600
EOFPHPFPM

# PHP.ini configuration
echo -e "${GREEN}[8/10] Configuring PHP settings...${NC}"

# Backup original php.ini
cp /etc/php/8.2/fpm/php.ini /etc/php/8.2/fpm/php.ini.backup
cp /etc/php/8.2/cli/php.ini /etc/php/8.2/cli/php.ini.backup

# Configure php.ini for FPM
sed -i 's/^memory_limit = .*/memory_limit = 256M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 20M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^post_max_size = .*/post_max_size = 20M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^max_execution_time = .*/max_execution_time = 300/' /etc/php/8.2/fpm/php.ini
sed -i 's/^max_input_time = .*/max_input_time = 300/' /etc/php/8.2/fpm/php.ini
sed -i 's/^max_input_vars = .*/max_input_vars = 5000/' /etc/php/8.2/fpm/php.ini
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' /etc/php/8.2/fpm/php.ini
sed -i 's/^;opcache.enable=.*/opcache.enable=1/' /etc/php/8.2/fpm/php.ini
sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=128/' /etc/php/8.2/fpm/php.ini
sed -i 's/^;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=8/' /etc/php/8.2/fpm/php.ini
sed -i 's/^;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=10000/' /etc/php/8.2/fpm/php.ini
sed -i 's/^;opcache.revalidate_freq=.*/opcache.revalidate_freq=2/' /etc/php/8.2/fpm/php.ini
sed -i 's/^;opcache.fast_shutdown=.*/opcache.fast_shutdown=1/' /etc/php/8.2/fpm/php.ini

# Configure php.ini for CLI (same settings)
sed -i 's/^memory_limit = .*/memory_limit = 256M/' /etc/php/8.2/cli/php.ini
sed -i 's/^max_execution_time = .*/max_execution_time = 0/' /etc/php/8.2/cli/php.ini
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' /etc/php/8.2/cli/php.ini

# Configure Apache
echo -e "${GREEN}[9/10] Configuring Apache...${NC}"

# Create Apache virtual host configuration
cat > /etc/apache2/sites-available/webchecker.conf << 'EOFAPACHE'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # PHP-FPM configuration
    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php8.2-fpm.sock|fcgi://localhost"
    </FilesMatch>

    # Security headers
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"

    # Compression
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
    </IfModule>

    # Caching
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/jpg "access plus 1 year"
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType image/gif "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType text/css "access plus 1 month"
        ExpiresByType application/javascript "access plus 1 month"
    </IfModule>

    # Logging
    ErrorLog ${APACHE_LOG_DIR}/webchecker_error.log
    CustomLog ${APACHE_LOG_DIR}/webchecker_access.log combined

    # Timeouts (for long-running requests)
    Timeout 300
</VirtualHost>
EOFAPACHE

# Disable default site and enable our site
a2dissite 000-default.conf
a2ensite webchecker.conf

# Apache MPM configuration for EC2 (2 vCPU, 7.7GB RAM)
cat > /etc/apache2/conf-available/mpm.conf << 'EOFMPM'
# MPM Event configuration optimized for 2 vCPU, 7.7GB RAM
<IfModule mpm_event_module>
    StartServers             4
    MinSpareThreads          25
    MaxSpareThreads          75
    ThreadsPerChild           25
    MaxRequestWorkers         100
    MaxConnectionsPerChild    1000
    ServerLimit               4
    ThreadLimit               25
</IfModule>
EOFMPM

a2enconf mpm

# Apache main configuration
sed -i 's/^ServerTokens.*/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
sed -i 's/^ServerSignature.*/ServerSignature Off/' /etc/apache2/conf-available/security.conf

# Set proper permissions
echo -e "${GREEN}[10/10] Setting permissions...${NC}"
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
mkdir -p /var/www/html/data
chmod -R 775 /var/www/html/data
chown -R www-data:www-data /var/www/html/data

# Create systemd service for worker_loop.php (optional)
cat > /etc/systemd/system/webchecker-worker.service << 'EOFSERVICE'
[Unit]
Description=Web Checker Worker Loop
After=network.target php8.2-fpm.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/html
ExecStart=/usr/bin/php /var/www/html/worker_loop.php
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Restart services
echo -e "${GREEN}Restarting services...${NC}"
systemctl daemon-reload
systemctl restart php8.2-fpm
systemctl restart apache2
systemctl enable php8.2-fpm
systemctl enable apache2

# Check services status
echo ""
echo -e "${GREEN}Checking services status...${NC}"
systemctl is-active --quiet php8.2-fpm && echo -e "${GREEN}✓ PHP-FPM is running${NC}" || echo -e "${RED}✗ PHP-FPM is not running${NC}"
systemctl is-active --quiet apache2 && echo -e "${GREEN}✓ Apache is running${NC}" || echo -e "${RED}✗ Apache is not running${NC}"

# Display PHP version
echo ""
echo -e "${GREEN}PHP Version:${NC}"
php -v | head -n 1

# Display Apache version
echo ""
echo -e "${GREEN}Apache Version:${NC}"
apache2 -v | head -n 1

# Final instructions
echo ""
echo -e "${GREEN}=========================================="
echo "  Installation Completed Successfully!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Upload your Web Checker files to /var/www/html/"
echo "2. Set proper permissions:"
echo "   sudo chown -R www-data:www-data /var/www/html"
echo "   sudo chmod -R 755 /var/www/html"
echo "   sudo chmod -R 775 /var/www/html/data"
echo ""
echo "3. (Optional) Enable worker service:"
echo "   sudo systemctl enable webchecker-worker"
echo "   sudo systemctl start webchecker-worker"
echo ""
echo "4. Configure firewall (if needed):"
echo "   sudo ufw allow 'Apache Full'"
echo ""
echo "5. Check Apache error log:"
echo "   sudo tail -f /var/log/apache2/webchecker_error.log"
echo ""
echo -e "${GREEN}Installation complete!${NC}"

