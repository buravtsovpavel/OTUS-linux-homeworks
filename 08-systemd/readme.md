## Домашнее задание

**Systemd - создание unit-файла**

**Цель домашнего задания: Научиться редактировать существующие и создавать новые unit-файлы.**

---

#### Описание домашнего задания:
Выполнить следующие задания и подготовить развёртывание результата выполнения с использованием Vagrant и Vagrant shell provisioner (или Ansible, на Ваше усмотрение):

1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig или в /etc/default).
2. Установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).
3. Дополнить unit-файл httpd (он же apache2) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.

---

**1\. Написать сервис**

* Для начала создаём файл с конфигурацией для сервиса в директории /etc/sysconfig - из неё сервис будет брать необходимые переменные.

```
[root@systemd ~]# echo '# Configuration file for my watchlog service
> # Place it to /etc/sysconfig
> 
> # File and word in that file that we will be monit
> WORD="ALERT"
> LOG=/var/log/watchlog.log' > /etc/sysconfig/watchlog
[root@systemd ~]# 
```

* Затем создаем /var/log/watchlog.log и пишем туда строки на своё усмотрение, плюс ключевое слово ‘ALERT’
```
[root@systemd ~]# cp /var/log/secure /var/log/watchlog.log

[root@systemd ~]# echo ALERT >> /var/log/watchlog.log 
```

* Создадим скрипт:
```
[root@systemd ~]# echo '#!/bin/bash
> WORD=$1
> LOG=$2
> DATE=`date`
> 
> if grep $WORD $LOG &> /dev/null
> then
> logger "$DATE: I found word, Master!"
> else
> exit 0
> fi' > /opt/watchlog.sh
[root@systemd ~]# 

```
( Команда logger отправляет лог в системный журнал)

* Добавим права на запуск файла:

```
[root@systemd ~]# chmod +x /opt/watchlog.sh
[root@systemd ~]# 

```

* Создадим юнит для сервиса:
```
[root@systemd ~]# echo '[Unit]
> Description=My watchlog service
> 
> [Service]
> Type=oneshot
> EnvironmentFile=/etc/sysconfig/watchlog
> ExecStart=/opt/watchlog.sh $WORD $LOG' > /etc/systemd/system/watchlog.service
[root@systemd ~]# 

```

* Создадим юнит для таймера:
```
[root@systemd ~]# echo '[Unit]
> Description=Run watchlog script every 30 second
> 
> [Timer]
> # Run every 30 second
> OnUnitActiveSec=30
> AccuracySec=1s
> Unit=watchlog.service
> 
> [Install]
> WantedBy=multi-user.target' > /etc/systemd/system/watchlog.timer
[root@systemd ~]# 
```
(AccuracySec=1s – точность таймера равна 1 секунде. По умолчанию точность таймера равно 1 минуте. Поэтому для заданий, которые выполняются чаще 1 минуты, нужно использовать этот параметр)

* Затем перечитываем файлы юнитов после изменений и потом достаточно только стартануть timer и убедиться в результате:

```
[root@systemd ~]# systemctl daemon-reload
[root@systemd ~]# systemctl start watchlog.timer
[root@systemd ~]# tail -f /var/log/messages
Apr 12 15:22:10 localhost systemd: Starting Session 4 of user vagrant.
Apr 12 15:23:45 localhost yum[2874]: Installed: nano-2.3.1-10.el7.x86_64
Apr 12 15:23:48 localhost systemd: Reloading.
Apr 12 15:23:57 localhost systemd: Started Run watchlog script every 30 second.
Apr 12 15:23:57 localhost systemd: Starting Run watchlog script every 30 second.
Apr 12 15:24:33 localhost chronyd[560]: Selected source 192.171.1.150
Apr 12 15:26:20 localhost systemd: Reloading.
Apr 12 15:26:44 localhost systemd: Starting My watchlog service...
Apr 12 15:26:44 localhost root: Wed Apr 12 15:26:44 UTC 2023: I found word, Master!
Apr 12 15:26:44 localhost systemd: Started My watchlog service.
Apr 12 15:27:14 localhost systemd: Starting My watchlog service...
Apr 12 15:27:14 localhost root: Wed Apr 12 15:27:14 UTC 2023: I found word, Master!
Apr 12 15:27:14 localhost systemd: Started My watchlog service.
Apr 12 15:27:45 localhost systemd: Starting My watchlog service...
Apr 12 15:27:45 localhost root: Wed Apr 12 15:27:45 UTC 2023: I found word, Master!
Apr 12 15:27:45 localhost systemd: Started My watchlog service.
Apr 12 15:28:16 localhost systemd: Starting My watchlog service...
Apr 12 15:28:16 localhost root: Wed Apr 12 15:28:16 UTC 2023: I found word, Master!
Apr 12 15:28:16 localhost systemd: Started My watchlog service.


```

**2\. Установить spawn-fcgi и переписать init-скрипт на unit-файл**

* Устанавливаем spawn-fcgi и необходимые для него пакеты:

```
[root@systemd ~]# yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
```

/etc/rc.d/init.d/spawn-fcgi - cам Init скрипт, который будем переписывать

Но перед этим необходимо раскомментировать строки с переменными в /etc/sysconfig/spawn-fcgi

```
[root@systemd ~]# cp  /etc/sysconfig/spawn-fcgi /tmp/sysconfig-spawn-fcgi
[root@systemd ~]# sed -i 's/#SOCKET/SOCKET/' /etc/sysconfig/spawn-fcgi
[root@systemd ~]# sed -i 's/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi
```

После раскомментирования он преобрёл следующий вид:

```
[root@systemd ~]# cat /etc/sysconfig/spawn-fcgi 
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"

[root@systemd ~]# 
```
Создаём юнит следующего вида:

```
[root@systemd ~]# echo '[Unit]
> Description=Spawn-fcgi startup service by Otus
> After=network.target
> 
> [Service]
> Type=simple
> PIDFile=/var/run/spawn-fcgi.pid
> EnvironmentFile=/etc/sysconfig/spawn-fcgi
> ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
> KillMode=process
> 
> [Install]
> WantedBy=multi-user.target' >  /etc/systemd/system/spawn-fcgi.service
[root@systemd ~]#
```

Убеждаемся что все успешно работает:

```
[root@systemd ~]# systemctl daemon-reload
[root@systemd ~]# systemctl start spawn-fcgi
[root@systemd ~]# systemctl status spawn-fcgi.service 
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2023-04-12 16:25:17 UTC; 3min 27s ago
 Main PID: 3901 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─3901 /usr/bin/php-cgi
           ├─3905 /usr/bin/php-cgi
           ├─3906 /usr/bin/php-cgi
           ├─3908 /usr/bin/php-cgi
           ├─3909 /usr/bin/php-cgi
           ├─3910 /usr/bin/php-cgi
           ├─3911 /usr/bin/php-cgi
           ├─3912 /usr/bin/php-cgi
           ├─3913 /usr/bin/php-cgi
           ├─3914 /usr/bin/php-cgi
           ├─3915 /usr/bin/php-cgi
           ├─3916 /usr/bin/php-cgi
           ├─3917 /usr/bin/php-cgi
           ├─3918 /usr/bin/php-cgi
           ├─3919 /usr/bin/php-cgi
           ├─3920 /usr/bin/php-cgi
           ├─3921 /usr/bin/php-cgi
           ├─3922 /usr/bin/php-cgi
           ├─3923 /usr/bin/php-cgi
           ├─3924 /usr/bin/php-cgi
           ├─3925 /usr/bin/php-cgi
           ├─3926 /usr/bin/php-cgi
           ├─3927 /usr/bin/php-cgi
           ├─3928 /usr/bin/php-cgi
           ├─3929 /usr/bin/php-cgi
           ├─3930 /usr/bin/php-cgi
           ├─3931 /usr/bin/php-cgi
           ├─3932 /usr/bin/php-cgi
           ├─3933 /usr/bin/php-cgi
           ├─3934 /usr/bin/php-cgi
           ├─3935 /usr/bin/php-cgi
           ├─3936 /usr/bin/php-cgi
           └─3937 /usr/bin/php-cgi

Apr 12 16:25:17 systemd systemd[1]: Started Spawn-fcgi startup service by Otus.
Apr 12 16:25:17 systemd systemd[1]: Starting Spawn-fcgi startup service by Otus...
[root@systemd ~]# 
```

**3\. Дополнить unit-файл httpd (он же apache2) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.**

* Для запуска нескольких экземпляров сервиса будем использовать шаблон в
конфигурации файла окружения (/usr/lib/systemd/system/httpd.service ):

```
[root@systemd ~]# cat /usr/lib/systemd/system/httpd.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
[root@systemd ~]# 
```
Создадим шаблон:

```
[root@systemd ~]# mv /usr/lib/systemd/system/httpd.service  /usr/lib/systemd/system/httpd@.service
[root@systemd ~]# cp /usr/lib/systemd/system/httpd@.service /tmp/httpd@service-bak
[root@systemd ~]# sed -i "s/EnvironmentFile=\/etc\/sysconfig\/httpd/EnvironmentFile=\/etc\/sysconfig\/httpd-%I/"  /usr/lib/systemd/system/httpd@.service

```
```
[root@systemd ~]# cat /usr/lib/systemd/system/httpd@.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
[root@systemd ~]# 
```

* В самом файле окружения (которых будет два) задается опция для запуска веб-сервера с необходимым конфигурационным файлом:
(# /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf  

# /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf)


```
[root@systemd ~]# cp /etc/sysconfig/httpd  /etc/sysconfig/httpd-first
[root@systemd ~]# mv /etc/sysconfig/httpd  /etc/sysconfig/httpd-second
[root@systemd ~]# ls -l /etc/sysconfig/ | grep httpd
-rw-r--r--. 1 root root  802 Apr 13 14:58 httpd-first
-rw-r--r--. 1 root root  802 Jan 13  2022 httpd-second
[root@systemd ~]# 
```
```
[root@systemd ~]# sed -i "s/#OPTIONS=/OPTIONS=-f conf\/first.conf/"     /etc/sysconfig/httpd-first
[root@systemd ~]# sed -i "s/#OPTIONS=/OPTIONS=-f conf\/second.conf/"    /etc/sysconfig/httpd-second
[root@systemd ~]# 
```
* Соответственно в директории с конфигами httpd (/etc/httpd/conf)
должны лежать два конфига, в нашем случае это будут first.conf и second.conf

```
[root@systemd ~]# cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
[root@systemd ~]# mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
[root@systemd ~]# ls -l  /etc/httpd/conf
total 40
-rw-r--r--. 1 root root 11753 Apr 13 15:12 first.conf
-rw-r--r--. 1 root root 13064 Apr  5 17:19 magic
-rw-r--r--. 1 root root 11753 Jan 13  2022 second.conf
[root@systemd ~]# 
```
* Для удачного запуска, в конфигурационных файлах должны быть указаны
уникальные для каждого экземпляра опции Listen и PidFile. Конфиги можно
скопировать и поправить только второй, в нем должны быть следующие опции:

PidFile /var/run/httpd-second.pid
Listen 8080

```
[root@systemd ~]# echo "PidFile /var/run/httpd-second.pid" >> /etc/httpd/conf/second.conf 
[root@systemd ~]# echo "PidFile /var/run/httpd-first.pid" >> /etc/httpd/conf/first.conf 
[root@systemd ~]# sed -i "s/Listen 80/Listen 8080/"   /etc/httpd/conf/second.conf
```
Этого достаточно для успешного запуска. Запустим:

```
[root@systemd ~]# systemctl start httpd@first
[root@systemd ~]# systemctl start httpd@second
[root@systemd ~]# ss -tnulp | grep httpd
tcp    LISTEN     0      128      :::8080                 :::*                   users:(("httpd",pid=1639,fd=4),("httpd",pid=1638,fd=4),("httpd",pid=1637,fd=4),("httpd",pid=1636,fd=4),("httpd",pid=1635,fd=4),("httpd",pid=1634,fd=4),("httpd",pid=1633,fd=4))
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=1626,fd=4),("httpd",pid=1625,fd=4),("httpd",pid=1624,fd=4),("httpd",pid=1623,fd=4),("httpd",pid=1622,fd=4),("httpd",pid=1621,fd=4),("httpd",pid=1620,fd=4))
[root@systemd ~]# 
```

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/08-systemd/screenshots/3_3.jpg)


**4. Развёртывание результата выполнения с использованием Vagrant и Vagrant shell provisioner**

Развёртываем 3 скритпами  [task1-watchlog-timer.sh](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/08-systemd/task1-watchlog-timer.sh)  [task2-spawn-fcgi-service.sh](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/08-systemd/task2-spawn-fcgi-service.sh) [task3-httpd.sh](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/08-systemd/task3-httpd.sh) с помощью [Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/08-systemd/Vagrantfile), vagrant shell.

