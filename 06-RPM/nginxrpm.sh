#! /bin/bash

# 1. Создать свой RPM пакет

sudo yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc

sudo wget -O /root/nginx-1.22.1-1.el8.ngx.src.rpm  https://nginx.org/packages/centos/8/SRPMS/nginx-1.22.1-1.el8.ngx.src.rpm

sudo rpm -i /root/nginx-1.22.1-1.el8.ngx.src.rpm

sudo wget -O /root/OpenSSL_1_1_1-stable.zip  https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip

sudo unzip /root/OpenSSL_1_1_1-stable.zip -d /root/

sudo yum-builddep -y /root/rpmbuild/SPECS/nginx.spec

sudo sed -i 's/--with-debug/--with-openssl=\/root\/openssl-OpenSSL_1_1_1-stable --with-debug/' /root/rpmbuild/SPECS/nginx.spec

sudo rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec

sudo yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el7.ngx.x86_64.rpm 

sudo systemctl start nginx

sudo systemctl status nginx

# 2.Создать свой репозиторий и разместить там ранее собранный RPM

sudo mkdir /usr/share/nginx/html/repo

sudo cp /root/rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/

sudo wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/7/x86_64/percona-orchestrator-3.2.6-2.el7.x86_64.rpm -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm

sudo createrepo /usr/share/nginx/html/repo/

sudo  sed -i 's/index  index.html index.htm;/index  index.html index.htm;autoindex on;/' /etc/nginx/conf.d/default.conf

sudo nginx -t 

sudo nginx -s reload

sudo curl -a http://localhost/repo/

cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

sudo yum install epel-release -y
sudo yum install jq oniguruma -y
sudo yum install percona-orchestrator.x86_64 -y
