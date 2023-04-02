# Цель домашнего задания
Размещаем свой RPM в своем репозитории






---


## Описание домашнего задания
 Основная часть:
* создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями);
*  создать свой репо и разместить там свой RPM;
*   реализовать это все либо в вагранте, либо развернуть у себя через nginx и дать ссылку на репо.
 
    

---

Сначала по шагам создадим свой rpm-пакет, свой репозиторий и разместим в нём пакет.

**1. Создаём свой RPM пакет**

* Ставим необходимые для сборки пакеты:
```
[root@rpm-lesson ~]# yum install -y \
> redhat-lsb-core \
> wget \
> rpmdevtools \
> rpm-build \
> createrepo \
> yum-utils \
> gcc
```

* Загрузим SRPM пакет NGINX для дальнейшей работы над ним:
```
[root@rpm-lesson ~]# wget -O /root/nginx-1.22.1-1.el8.ngx.src.rpm  https://nginx.org/packages/centos/8/SRPMS/nginx-1.22.1-1.el8.ngx.src.rpm
```

* Создаём дерево каталогов, устновив SRPM пакет:

```
[root@rpm-lesson ~]# rpm -i /root/nginx-1.22.1-1.el8.ngx.src.rpm
```
* Также нужно скачать и разархивировать последние исходники для openssl - он
потребуется при сборке:

```
[root@rpm-lesson ~]# wget -O /root/OpenSSL_1_1_1-stable.zip  https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip


Сохранение в: «OpenSSL_1_1_1-stable.zip»

    [           <=>                                                                                                                                                                              ] 11 928 147  4,82MB/s   за 2,4s   

2023-03-29 15:28:44 (4,82 MB/s) - «OpenSSL_1_1_1-stable.zip» сохранён [11928147]

```
```
[root@rpm-lesson ~]# unzip /root/OpenSSL_1_1_1-stable.zip -d /root/
```
```
[root@rpm-lesson ~]# ls -l
total 12748
-rw-------.  1 root root     5570 апр 30  2020 anaconda-ks.cfg
-rw-r--r--.  1 root root  1099095 окт 19 10:58 nginx-1.22.1-1.el8.ngx.src.rpm
-rw-r--r--.  1 root root 11928147 апр  2 14:09 OpenSSL_1_1_1-stable.zip
drwxr-xr-x. 19 root root     4096 мар 28 12:13 openssl-OpenSSL_1_1_1-stable
-rw-------.  1 root root     5300 апр 30  2020 original-ks.cfg
drwxr-xr-x.  8 root root       89 апр  2 14:10 rpmbuild
[root@rpm-lesson ~]# 
```

* Заранее ставим все зависимости чтобы в процессе сборки не было ошибок:
```
[root@rpm-lesson ~]# yum-builddep -y /root/rpmbuild/SPECS/nginx.spec
```

* Добавим в speck-файле опцию для сборки с openssl:
```
[root@rpm-lesson ~]# sed -i 's/--with-debug/--with-openssl=\/root\/openssl-OpenSSL_1_1_1-stable --with-debug/' /root/rpmbuild/SPECS/nginx.spec
```
-----------------
**Теперь можно приступить к сборке RPM пакета:**

```
[root@rpm-lesson ~]# yum-builddep -y /root/rpmbuild/SPECS/nginx.spec

```
```
    rpm: Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.LDRzMB
    rpm: + umask 022
    rpm: + cd /root/rpmbuild/BUILD
    rpm: + cd nginx-1.22.1
    rpm: + /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.22.1-1.el7.ngx.x86_64
    rpm: + exit 0
```
* Теперь можно установить наш пакет и убедиться что nginx работает:

```
[root@rpm-lesson ~]# yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el7.ngx.x86_64.rpm 
```
```
[root@rpm-lesson ~]# systemctl start nginx
[root@rpm-lesson ~]# systemctl status nginx
```

**2. Теперь приступим к созданию своего репозитория. Директория для статики у NGINX по умолчанию /usr/share/nginx/html. Создадим там каталог repo:**
```
[root@rpm-lesson ~]# mkdir /usr/share/nginx/html/repo
```
* Копируем туда наш собранный RPM и, например, RPM для установки репозитория Percona-Server:

```
[root@rpm-lesson ~]# cp /root/rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/
      
[root@rpm-lesson ~]# wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/7/x86_64/percona-orchestrator-3.2.6-2.el7.x86_64.rpm -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm
```
* Инициализируем репозиторий командой:
```
[root@rpm-lesson ~]# createrepo /usr/share/nginx/html/repo/
```
* Для прозрачности настроим в NGINX доступ к листингу каталога:
В location / в файле /etc/nginx/conf.d/default.conf добавим директиву autoindex on. В результате location будет выглядеть так:
```
    location / {

        root   /usr/share/nginx/html;

        index  index.html index.htm;autoindex on;

    }
```
```
[root@rpm-lesson ~]# sed -i 's/index  index.html index.htm;/index  index.html index.htm;autoindex on;/' /etc/nginx/conf.d/default.conf
```
* Проверяем синтаксис и перезапускаем NGINX:

```
[root@rpm-lesson ~]# sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@rpm-lesson ~]#
```
```
[root@rpm-lesson ~]# sudo nginx -s reload
```
* Теперь ради интереса можно посмотреть в браузере или curl-ануть:

```
[root@rpm-lesson ~]# lynx http://localhost/repo/
```

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/06-RPM/screenshots/1_3.jpg)
```
[root@rpm-lesson ~]# curl -a http://localhost/repo/
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          01-Apr-2023 09:47                   -
<a href="nginx-1.22.1-1.el7.ngx.x86_64.rpm">nginx-1.22.1-1.el7.ngx.x86_64.rpm</a>                  01-Apr-2023 09:38             2209636
<a href="percona-orchestrator-3.2.6-2.el8.x86_64.rpm">percona-orchestrator-3.2.6-2.el8.x86_64.rpm</a>        16-Feb-2022 15:57             5222976
</pre><hr></body>
</html>
```
* Все готово для того, чтобы протестировать репозиторий.

Добавим его в /etc/yum.repos.d:
```
[root@rpm-lesson ~]# cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```
Так как NGINX у нас уже стоит установим репозиторий percona-release:
(сначала устанавливаем необходимые зависимости)
```
error: Failed dependencies:
	jq >= 1.5 is needed by percona-orchestrator-2:3.2.6-2.el7.x86_64
	oniguruma is needed by percona-orchestrator-2:3.2.6-2.el7.x86_64
```

```
yum install epel-release -y
yum install jq oniguruma -y
yum install percona-orchestrator.x86_64 -y
```

**3. Реализовать это все в вагранте**

Для реализции в вагранте добавляем это всё в отдельный [скрипт](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/06-RPM/nginxrpm.sh) для provisioning или делаем provisioning with shell сразу в [Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/06-RPM/Vagrantfile).
