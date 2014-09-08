#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
ARCH=$(arch)
HOME="/var/www/WebPanel"

HOME=${HOME%/}
if [ "$HOME" == "" ]; then
	echo "Home directory can't be '/' itself."
	exit 1
fi

# check if webpanel is already installed
if [ -f "/etc/default/webpanel" ]; then
	echo "WebPanel is already installed."
	exit 1
fi

# Allow only root execution
if [ $(id -u) -ne 0 ]; then
    echo "This script requires root privileges"
    exit 1
fi

################## repos
\cp "$SCRIPT_DIR/repos/CentOS-Base/etc/yum.repos.d/CentOS-Base.repo" "/etc/yum.repos.d/CentOS-Base.repo"

\cp "$SCRIPT_DIR/repos/epel/etc/yum.repos.d/epel.repo" "/etc/yum.repos.d/epel.repo"
\cp "$SCRIPT_DIR/repos/epel/etc/rpm/macros.ghc-srpm" "/etc/rpm/macros.ghc-srpm"

\cp "$SCRIPT_DIR/repos/ius/etc/yum.repos.d/ius.repo" "/etc/yum.repos.d/ius.repo"
\cp "$SCRIPT_DIR/repos/ius/etc/yum.repos.d/ius-archive.repo" "/etc/yum.repos.d/ius-archive.repo"

\cp "$SCRIPT_DIR/repos/nginx/etc/yum.repos.d/nginx.repo" "/etc/yum.repos.d/nginx.repo"

\cp "$SCRIPT_DIR/repos/rpmforge/etc/yum.repos.d/rpmforge.repo" "/etc/yum.repos.d/rpmforge.repo"

################# yum plugins
# yum -y install yum-plugin-priorities yum-plugin-rpm-warm-cache yum-plugin-local yum-presto yum-plugin-fastestmirror yum-plugin-replace yum-cron

#installing packages
# yum -y install iftop iotop bind-utils htop nmap openssh-clients memcached mysql httpd php54 php54-bcmath php54-cli php54-common php54-fpm php54-gd php54-intl php54-mbstring php54-mcrypt php54-mysqlnd php54-odbc php54-pdo php54-pear php54-pecl-mongo php54-pecl-memcached php54-pecl-zendopcache php54-tidy php54-xml perl-Net-SSLeay mod_fastcgi nginx quota webalizer

#installing mysql55
# yum -y replace mysql --replace-with mysql55
# yum -y install mysql55-server

# installing packages
touch "/etc/default/mod-pagespeed"
touch "/etc/default/webpanel"
yum -y remove mysql mysql-libs mysql-server
rpm -Uvh --force $(find $SCRIPT_DIR/packages/$ARCH -name "*" | grep -e .rpm$)

# Quota
TMP_DIR="/$HOME"
QUOTA_DIR=""
QUOTA_DIR_ESC=""
while [ "$TMP_DIR" != "" ]
do
	if [ "$TMP_DIR" != "/" ]; then
		QUOTA_DIR=$(echo "$TMP_DIR" | sed -r -e"s/^\/(.+)$/\1/");
	else
		QUOTA_DIR="/"
	fi
	
	if grep -qs " $QUOTA_DIR " "/proc/mounts"; then
		QUOTA_DIR_ESC=$(sed 's/[\*\.&\/]/\\&/g' <<<"$QUOTA_DIR")
		sed -i -r -e"s/( $QUOTA_DIR_ESC .*?defaults)/\1,usrjquota=aquota\.user,grpjquota=aquota\.group,jqfmt=vfsv0/I" "/etc/fstab"
		mount -o remount "$QUOTA_DIR" 1>/dev/null
		break
	fi
	
	TMP_DIR=$(echo "$TMP_DIR" | sed -r -e"s/^(.*)\/.*?$/\1/")
done

quotacheck -avugm 1>/dev/null
quotaon -avug 1>/dev/null

echo -e "#!/bin/bash\ntouch /forcequotacheck" > "/etc/cron.weekly/forcequotacheck"
chmod +x "/etc/cron.weekly/forcequotacheck"

# config after install
sh "$SCRIPT_DIR/config_install.inc"