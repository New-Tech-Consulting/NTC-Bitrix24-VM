#!/bin/sh

cat > /root/run.sh <<\END

set -x
LOG_PIPE=/tmp/log.pipe
mkfifo ${LOG_PIPE}
LOG_FILE=/root/installation.log
touch ${LOG_FILE}
chmod 600 ${LOG_FILE}
tee < ${LOG_PIPE} ${LOG_FILE} &
exec > ${LOG_PIPE}
exec 2> ${LOG_PIPE}

dbconn() {
	cat <<-EOF
		<?php
    \$DBDebug = false;
    \$DBDebugToFile = false;

    // need for old distros
    define('CACHED_b_lang', 3600);
    define('CACHED_b_agent', 3600);
    define('CACHED_b_lang_domain', 3600);

    define("BX_FILE_PERMISSIONS", 0644);
    define("BX_DIR_PERMISSIONS", 0755);
    @umask(~(BX_FILE_PERMISSIONS|BX_DIR_PERMISSIONS)&0777);

    define("BX_UTF", true);
    define("MYSQL_TABLE_TYPE", "INNODB");
    define("BX_DISABLE_INDEX_PAGE", true);

    define("BX_TEMPORARY_FILES_DIRECTORY", "/home/bitrix/.bx_temp/sitemanager/");

    define("SHORT_INSTALL", true);
    define("VM_INSTALL", true);

    define("BX_USE_MYSQLI", true);

    if(!(defined('CHK_EVENT') && CHK_EVENT === true)){
       define('BX_CRONTAB_SUPPORT', true);
    }

    if(isset($_GET["user_lang"]))
    {
          setcookie("USER_LANG", $_GET["user_lang"], time()+9999999, "/");
          define("LANGUAGE_ID", $_GET["user_lang"]);
    }
    elseif(isset($_COOKIE["USER_LANG"]))
    {
          define("LANGUAGE_ID", $_COOKIE["USER_LANG"]);
    }
    ?>
	EOF
}

afterbi() {
	cat <<-EOF
		<?
    $this->queryExecute("SET NAMES 'utf8'");
    $this->queryExecute("SET sql_mode=''");
    ?>
	EOF
}

settings() {
	cat <<-EOF
		<?php
		return array (
		  'utf_mode' =>
		  array (
		    'value' => true,
		    'readonly' => true,
		  ),
		  'cache_flags' =>
		  array (
		    'value' =>
		    array (
		      'config_options' => 3600,
		      'site_domain' => 3600,
		    ),
		    'readonly' => false,
		  ),
		  'cookies' =>
		  array (
		    'value' =>
		    array (
		      'secure' => false,
		      'http_only' => true,
		    ),
		    'readonly' => false,
		  ),
		  'exception_handling' =>
		  array (
		    'value' =>
		    array (
		      'debug' => false,
		      'handled_errors_types' => 4437,
		      'exception_errors_types' => 4437,
		      'ignore_silence' => false,
		      'assertion_throws_exception' => true,
		      'assertion_error_type' => 256,
		      'log' => array (
			  'settings' =>
			  array (
			    'file' => '/home/bitrix/logs/php/exceptions.log',
			    'log_size' => 1000000,
			),
		      ),
		    ),
		    'readonly' => false,
		  ),
		  'crypto' =>
		  array (
		    'value' =>
		    array (
			'crypto_key' => "${PUSH_KEY}",
		    ),
		    'readonly' => true,
		  ),
		  'connections' =>
		  array (
		    'value' =>
		    array (
		      'default' =>
		      array (
			'className' => '\\Bitrix\\Main\\DB\\MysqliConnection',
			'host' => 'localhost',
			'database' => 'sitemanager',
			'login'    => 'bitrix0',
			'password' => '${DB_PASS}',
			'options' => 2,
		      ),
		      'biconnector' =>
          array (
      'className' => '\\Bitrix\\Main\\DB\\MysqliConnection',
      'host' => 'localhost',
      'database' => 'sitemanager',
      'login'    => 'bitrix0',
      'password' => '${DB_PASS}',
      'options' => 2,
      'include_after_connected' => '/home/bitrix/www/bitrix/php_interface/after_connect_bi.php',
          ),
		    ),
		    'readonly' => true,
		  ),
		'pull_s1' => 'BEGIN GENERATED PUSH SETTINGS. DON\'T DELETE COMMENT!!!!',
		  'pull' => Array(
		    'value' =>  array(
			'path_to_listener' => "http://#DOMAIN#/bitrix/sub/",
			'path_to_listener_secure' => "https://#DOMAIN#/bitrix/sub/",
			'path_to_modern_listener' => "http://#DOMAIN#/bitrix/sub/",
			'path_to_modern_listener_secure' => "https://#DOMAIN#/bitrix/sub/",
			'path_to_mobile_listener' => "http://#DOMAIN#:8893/bitrix/sub/",
			'path_to_mobile_listener_secure' => "https://#DOMAIN#:8894/bitrix/sub/",
			'path_to_websocket' => "ws://#DOMAIN#/bitrix/subws/",
			'path_to_websocket_secure' => "wss://#DOMAIN#/bitrix/subws/",
			'path_to_publish' => 'http://127.0.0.1:8895/bitrix/pub/',
			'nginx_version' => '4',
			'nginx_command_per_hit' => '100',
			'nginx' => 'Y',
			'nginx_headers' => 'N',
			'push' => 'Y',
			'websocket' => 'Y',
			'signature_key' => '${PUSH_KEY}',
			'signature_algo' => 'sha1',
			'guest' => 'N',
		    ),
		  ),
		'pull_e1' => 'END GENERATED PUSH SETTINGS. DON\'T DELETE COMMENT!!!!',
		);
	EOF
}

installPkg(){
  apt update -y
  apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2 rsync nftables pwgen make build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev

  echo "deb [signed-by=/etc/apt/trusted.gpg.d/suru.gpg] https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
  curl -s -o /etc/apt/trusted.gpg.d/suru.gpg https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php/apt.gpg
  apt update -y

  # Add Percona repository
  curl -O https://repo.percona.com/apt/percona-release_latest.generic_all.deb
  apt install -y ./percona-release_latest.generic_all.deb
  apt update -y
  percona-release setup ps80


  export DEBIAN_FRONTEND="noninteractive"
  debconf-set-selections <<< 'exim4-config exim4/dc_eximconfig_configtype select internet site; mail is sent and received directly using SMTP'
  apt install -y  php8.2 php8.2-cli \
                  php8.2-common php8.2-gd php8.2-ldap \
                  php8.2-mbstring php8.2-mysql \
                  php8.2-opcache php8.2-curl php-redis \
                  php-pear php8.2-apcu php-geoip \
                  php8.2-mcrypt php8.2-memcache \
                  php8.2-zip php8.2-pspell php8.2-xml \
                  apache2 \
                  percona-server-server percona-server-client \
                  nodejs npm redis \
                  exim4 exim4-config
}

installNginxWithModZip() {
  chmod +r /usr/lib/x86_64-linux-gnu/libpcre.so.3.13.3
  apt update -y

  # Download Nginx source code
  NGINX_VERSION="1.26.1"
  cd /tmp
  wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
  tar -xzvf nginx-$NGINX_VERSION.tar.gz

  # Download mod_zip module
  wget https://github.com/evanmiller/mod_zip/archive/master.zip
  unzip master.zip

  # Compile and install Nginx with mod_zip
  cd nginx-$NGINX_VERSION
  ./configure \
    --with-cc-opt='-g -O2 -ffile-prefix-map=/build/nginx-AoTv4W/nginx-1.26.1=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-z,relro -Wl,-z,now
    --with-pcre=/usr/lib/x86_64-linux-gnu/libpcre.so.3.13.3
 -fPIC' \
    --prefix=/usr/share/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/home/bitrix/logs/nginx/access.log \
    --error-log-path=stderr
 \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/run/nginx.pid \
    --modules-path=/usr/lib/nginx/modules \
    --http-client-body-temp-path=/var/lib/nginx/body \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --http-scgi-temp-path=/var/lib/nginx/scgi \
    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
    --with-compat
 \
    --with-debug \
    --with-pcre-jit \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_auth_request_module \
    --with-http_v2_module \
    --with-http_dav_module \
    --with-http_slice_module \
    --with-threads \
    --with-http_addition_module \
    --with-http_flv_module
 \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_secure_link_module
 \
    --with-http_sub_module \
    --with-mail_ssl_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_realip_module \
    --with-http_geoip_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_perl_module=dynamic \
    --with-http_xslt_module=dynamic \
    --with-mail=dynamic \
    --with-stream=dynamic \
    --with-stream_geoip_module=dynamic
 \
    --add-module=../mod_zip-master \
    --with-openssl-opt='enable-tls1_3'

  make
  make install
}

dplApache(){
		mkdir /etc/systemd/system/apache2.service.d
		cat <<EOF >> /etc/systemd/system/apache2.service.d/privtmp.conf
[Service]
PrivateTmp=false
EOF
		systemctl daemon-reload
	  ln -sf /etc/php/8.2/mods-available/zbx-bitrix.ini  /etc/php/8.2/apache2/conf.d/99-bitrix.ini
    ln -sf /etc/php/8.2/mods-available/zbx-bitrix.ini  /etc/php/8.2/cli/conf.d/99-bitrix.ini
    a2dismod --force autoindex
    a2enmod rewrite
		systemctl stop apache2
		systemctl enable --now apache2
		systemctl start nginx
}

dplNginx(){
	echo -e "\n127.0.0.1 push httpd\n" >> /etc/hosts
	rm /etc/nginx/sites-enabled/default
	ln -s /etc/nginx/sites-available/rtc.conf /etc/nginx/sites-enabled/rtc.conf
	ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
	systemctl stop nginx
	systemctl enable --now nginx
	systemctl start nginx
}

dplRedis(){
		echo -e "pidfile /run/redis/redis-server.pid\ndir /var/lib/redis" >> /etc/redis/redis.conf
		echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
		sysctl vm.overcommit_memory=1
	  usermod -g bitrix redis
    chown root:bitrix /etc/redis/ /home/bitrix/logs/redis/
    [[ ! -d /etc/systemd/system/redis.service.d ]] && mkdir /etc/systemd/system/redis.service.d
    echo -e '[Service]\nGroup=bitrix\nPIDFile=/run/redis/redis-server.pid' > /etc/systemd/system/redis.service.d/custom.conf
    systemctl daemon-reload
    systemctl stop redis
    systemctl enable --now redis || systemctl enable --now redis-server
    systemctl start redis
}

dplPush(){
	cd /opt
	wget -q https://repo.bitrix.info/vm/push-server-0.4.0.tgz
	npm install --production ./push-server-0.4.0.tgz
	rm ./push-server-0.4.0.tgz
	ln -sf /opt/node_modules/push-server/etc/push-server /etc/push-server

	cd /opt/node_modules/push-server
	cp etc/init.d/push-server-multi /usr/local/bin/push-server-multi
	mkdir /etc/sysconfig
	cp etc/sysconfig/push-server-multi  /etc/sysconfig/push-server-multi
	cp etc/push-server/push-server.service  /etc/systemd/system/
	ln -sf /opt/node_modules/push-server /opt/push-server
	useradd -g bitrix bitrix

cat <<EOF >> /etc/sysconfig/push-server-multi
GROUP=bitrix
SECURITY_KEY="${PUSH_KEY}"
RUN_DIR=/tmp/push-server
REDIS_SOCK=/var/run/redis/redis.sock
WS_HOST=127.0.0.1
EOF
	/usr/local/bin/push-server-multi configs pub
	/usr/local/bin/push-server-multi configs sub
	echo 'd /tmp/push-server 0770 bitrix bitrix -' > /etc/tmpfiles.d/push-server.conf
	systemd-tmpfiles --remove --create
	[[ ! -d /home/bitrix/logs/push-server ]] && mkdir /home/bitrix/logs/push-server
	chown bitrix:bitrix /home/bitrix/logs/push-server

	sed -i 's|User=.*|User=bitrix|;s|Group=.*|Group=bitrix|;s|ExecStart=.*|ExecStart=/usr/local/bin/push-server-multi systemd_start|;s|ExecStop=.*|ExecStop=/usr/local/bin/push-server-multi stop|' /etc/systemd/system/push-server.service
	systemctl daemon-reload
	systemctl stop push-server
	systemctl --now enable push-server
	systemctl start push-server
}

dplMYSQL() {
	echo 'innodb_strict_mode=off' >> /etc/mysql/my-bx.d/zbx-custom.cnf
	mysql -e "create database sitemanager;create user bitrix0@localhost;grant all on bitrix.* to bitrix0@localhost;set password for bitrix0@localhost = PASSWORD('${DB_PASS}')"
	systemctl stop mysql
	systemctl --now enable mysql
	systemctl start mysql
}

nfTabl(){
	cat <<EOF > /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
	chain input {
		type filter hook input priority 0; policy drop;
		iif "lo" accept comment "Accept any localhost traffic"
		ct state invalid drop comment "Drop invalid connections"
		ip protocol icmp limit rate 4/second accept
		ip6 nexthdr ipv6-icmp limit rate 4/second accept
		ct state { established, related } accept comment "Accept traffic originated from us"
		tcp dport 22 accept comment "ssh"
		tcp dport { 80, 443, 8893, 8894} accept comment "web"
		tcp dport 2050 accept comment "zabbix passive check"
	}
	chain forward {
		type filter hook forward priority 0;
	}
	chain output {
		type filter hook output priority 0;
	}
}
EOF
	systemctl restart nftables
	systemctl enable nftables.service
}

deployConfig() {

	wget -q- 'https://raw.githubusercontent.com/New-Tech-Consulting/NTC-Bitrix24-VM/master/repositories/bx-files/debian.zip'
  unzip debian.zip && rm debian.zip
  rsync -a --exclude=php.d ./debian/ /etc/
  rsync -a ./debian/php.d/ /etc/php/8.2/mods-available/
  rsync -a ./debian/php.d/ /etc/php/7.4/mods-available/
	mkdir -p /home/bitrix/www
	mkdir -p /home/bitrix/logs/php
	mkdir -p /home/bitrix/logs/apache2
	mkdir -p /home/bitrix/logs/nginx
	mkdir -p /home/bitrix/logs/mysql
	mkdir -p /home/bitrix/logs/bitrix-debug

	nfTabl
	dplApache
	dplNginx
	dplRedis
	dplPush
	dplMYSQL

  systemctl --now enable mysql
}

deployInstaller() {
	cd /home/bitrix/www
	wget -q 'https://raw.githubusercontent.com/New-Tech-Consulting/NTC-Bitrix24-VM/master/repositories/bx-files/bitrixsetup.php'
	wget -q 'https://raw.githubusercontent.com/New-Tech-Consulting/NTC-Bitrix24-VM/master/repositories/bx-files/restore.php'
	wget -q 'https://raw.githubusercontent.com/New-Tech-Consulting/NTC-Bitrix24-VM/master/repositories/bx-files/index.php'
	mkdir -p bitrix/php_interface
	dbconn > bitrix/php_interface/dbconn.php
	afterbi > bitrix/php_interface/after_connect_bi.php
	settings > bitrix/.settings.php
	chown -R bitrix:bitrix /home/bitrix/
}

installPkg
installNginxWithModZip

PUSH_KEY=$(pwgen 24 1)
DB_PASS=$(generate_password 24)

deployConfig
deployInstaller

END


