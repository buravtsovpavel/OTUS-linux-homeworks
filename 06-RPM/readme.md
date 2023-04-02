# Цель домашнего задания
Размещаем свой RPM в своем репозитории






---


## Описание домашнего задания
 Основная часть:
* создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями);
*  создать свой репо и разместить там свой RPM;
*   реализовать это все либо в вагранте, либо развернуть у себя через nginx и дать ссылку на репо.
 
    *Задание со звездочкой*: реализовать дополнительно пакет через docker


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



Installed:
  createrepo.noarch 0:0.9.9-28.el7     gcc.x86_64 0:4.8.5-44.el7     redhat-lsb-core.x86_64 0:4.1-27.el7.centos.1     rpm-build.x86_64 0:4.11.3-48.el7_9     rpmdevtools.noarch 0:8.3-8.el7_9     wget.x86_64 0:1.14-18.el7_6.1    

Dependency Installed:
  at.x86_64 0:3.1.13-25.el7_9                    bc.x86_64 0:1.06.95-13.el7                   cpp.x86_64 0:4.8.5-44.el7                cups-client.x86_64 1:1.6.3-51.el7    dwz.x86_64 0:0.11-3.el7                                
  ed.x86_64 0:1.9-4.el7                          elfutils.x86_64 0:0.176-5.el7                emacs-filesystem.noarch 1:24.3-23.el7    gdb.x86_64 0:7.6.1-120.el7           glibc-devel.x86_64 0:2.17-326.el7_9                    
  glibc-headers.x86_64 0:2.17-326.el7_9          kernel-headers.x86_64 0:3.10.0-1160.88.1.el7 libmpc.x86_64 0:1.0.1-3.el7              m4.x86_64 0:1.4.16-10.el7            mailx.x86_64 0:12.5-19.el7                             
  mpfr.x86_64 0:3.1.1-4.el7                      patch.x86_64 0:2.7.1-12.el7_7                perl.x86_64 4:5.16.3-299.el7_9           perl-Carp.noarch 0:1.26-244.el7      perl-Encode.x86_64 0:2.51-7.el7                        
  perl-Exporter.noarch 0:5.68-3.el7              perl-File-Path.noarch 0:2.09-2.el7           perl-File-Temp.noarch 0:0.23.01-3.el7    perl-Filter.x86_64 0:1.49-3.el7      perl-Getopt-Long.noarch 0:2.40-3.el7                   
  perl-HTTP-Tiny.noarch 0:0.033-3.el7            perl-PathTools.x86_64 0:3.40-5.el7           perl-Pod-Escapes.noarch 1:1.04-299.el7_9 perl-Pod-Perldoc.noarch 0:3.20-4.el7 perl-Pod-Simple.noarch 1:3.28-4.el7                    
  perl-Pod-Usage.noarch 0:1.63-3.el7             perl-Scalar-List-Utils.x86_64 0:1.27-248.el7 perl-Socket.x86_64 0:2.010-5.el7         perl-Storable.x86_64 0:2.45-3.el7    perl-Text-ParseWords.noarch 0:3.29-4.el7               
  perl-Thread-Queue.noarch 0:3.02-2.el7          perl-Time-HiRes.x86_64 4:1.9725-3.el7        perl-Time-Local.noarch 0:1.2300-2.el7    perl-constant.noarch 0:1.27-2.el7    perl-libs.x86_64 4:5.16.3-299.el7_9                    
  perl-macros.x86_64 4:5.16.3-299.el7_9          perl-parent.noarch 1:0.225-244.el7           perl-podlators.noarch 0:2.5.1-3.el7      perl-srpm-macros.noarch 0:1-8.el7    perl-threads.x86_64 0:1.87-4.el7                       
  perl-threads-shared.x86_64 0:1.43-6.el7        psmisc.x86_64 0:22.20-17.el7                 python-deltarpm.x86_64 0:3.6-3.el7       python-srpm-macros.noarch 0:3-34.el7 redhat-lsb-submod-security.x86_64 0:4.1-27.el7.centos.1
  redhat-rpm-config.noarch 0:9.1.0-88.el7.centos spax.x86_64 0:1.5.2-13.el7                   time.x86_64 0:1.7-45.el7                 unzip.x86_64 0:6.0-24.el7_9          zip.x86_64 0:3.0-11.el7                                

Updated:
  yum-utils.noarch 0:1.1.31-54.el7_8                                                                                                                                                                                                 

Dependency Updated:
  cups-libs.x86_64 1:1.6.3-51.el7    elfutils-libelf.x86_64 0:0.176-5.el7    elfutils-libs.x86_64 0:0.176-5.el7         glibc.x86_64 0:2.17-326.el7_9        glibc-common.x86_64 0:2.17-326.el7_9    libgcc.x86_64 0:4.8.5-44.el7   
  libgomp.x86_64 0:4.8.5-44.el7      rpm.x86_64 0:4.11.3-48.el7_9            rpm-build-libs.x86_64 0:4.11.3-48.el7_9    rpm-libs.x86_64 0:4.11.3-48.el7_9    rpm-python.x86_64 0:4.11.3-48.el7_9  
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
вставить картинку
```
[root@rpm-lesson ~]# ll
total 12732
-rw-------. 1 root root     5570 апр 30  2020 anaconda-ks.cfg
-rw-r--r--. 1 root root  1086865 ноя 16  2021 nginx-1.20.2-1.el8.ngx.src.rpm
-rw-r--r--. 1 root root 11928147 мар 29 15:28 OpenSSL_1_1_1-stable.zip
-rw-------. 1 root root     5300 апр 30  2020 original-ks.cfg
drwxr-xr-x. 4 root root       34 мар 29 15:14 rpmbuild
[root@rpm-lesson ~]# 
```
```
[root@rpm-lesson ~]# unzip /root/OpenSSL_1_1_1-stable.zip -d /root/
```
* Заранее ставим все зависимости чтобы в процессе сборки не было ошибок:
```
[root@rpm-lesson ~]# yum-builddep -y /root/rpmbuild/SPECS/nginx.spec
```



Добавим в speck-файле опцию для сборки с openssl:
```
[root@rpm-lesson ~]# sed -i 's/--with-debug/--with-openssl=\/root\/openssl-OpenSSL_1_1_1-stable --with-debug/' /root/rpmbuild/SPECS/nginx.spec
```
-----------------
Теперь можно приступить к сборке RPM пакета:

```
[root@rpm-lesson ~]# yum-builddep -y /root/rpmbuild/SPECS/nginx.spec

```
вставить листинг и результат сборки 

```
    rpm: Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.LDRzMB
    rpm: + umask 022
    rpm: + cd /root/rpmbuild/BUILD
    rpm: + cd nginx-1.22.1
    rpm: + /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.22.1-1.el7.ngx.x86_64
    rpm: + exit 0

```
Теперь можно установить наш пакет и убедиться что nginx работает:

```
[root@rpm-lesson ~]# yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el7.ngx.x86_64.rpm 

```

```
[root@rpm-lesson ~]# systemctl start nginx
[root@rpm-lesson ~]# systemctl status nginx
```
Вставить nginx

Теперь приступим к созданию своего репозитория. Директория для статики у NGINX по умолчанию /usr/share/nginx/html. Создадим там каталог repo:
```
[root@rpm-lesson ~]# mkdir /usr/share/nginx/html/repo
```
Копируем туда наш собранный RPM и, например, RPM для установки репозитория
Percona-Server:

```
[root@rpm-lesson ~]# cp /root/rpmbuild/RPMS/x86_64/nginx-1.22.1-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/
      
[root@rpm-lesson ~]# wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/7/x86_64/percona-orchestrator-3.2.6-2.el7.x86_64.rpm -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm
```
Инициализируем репозиторий командой:

Вставить картинку
```
[root@rpm-lesson ~]# createrepo /usr/share/nginx/html/repo/


```

Для прозрачности настроим в NGINX доступ к листингу каталога:
В location / в файле /etc/nginx/conf.d/default.conf добавим директиву autoindex on. В результате location будет выглядеть так:

вставить картинку
```
[root@rpm-lesson ~]# sed -i 's/index  index.html index.htm;/index  index.html index.htm;autoindex on;/' /etc/nginx/conf.d/default.conf
```
Проверяем синтаксис и перезапускаем NGINX:

```
[root@rpm-lesson ~]# sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@rpm-lesson ~]#
```
```
[root@rpm-lesson ~]# sudo nginx -s reload
```
Теперь ради интереса можно посмотреть в браузере или curl-ануть:
Вставить картинку
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
```
[root@rpm-lesson ~]# lynx http://localhost/repo/
```



Все готово для того, чтобы протестировать репозиторий.

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