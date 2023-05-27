# Цель домашнего задания
Научиться создавать пользователей и добавлять им ограничения



---


## Описание домашнего задания
1) Запретить всем пользователям, кроме группы admin, логин в выходные (суббота и воскресенье), без учета праздников

* дать конкретному пользователю права работать с докером
и возможность рестартить докер сервис


---



Создаём пользователя otusadm и otus:
```
[root@pam ~]# sudo useradd otusadm && sudo useradd otus
[root@pam ~]# 
```
Создаём пользователям пароли:

```
[root@pam ~]# echo "Otus2022!" | sudo passwd --stdin otusadm && echo "Otus2022!" | sudo passwd --stdin otus
Changing password for user otusadm.
passwd: all authentication tokens updated successfully.
Changing password for user otus.
passwd: all authentication tokens updated successfully.
[root@pam ~]# 

```
Создаём группу admin:

```
[root@pam ~]# groupadd -f admin
```
Добавляем пользователей vagrant,root и otusadm в группу admin:

usermod otusadm -a -G admin && usermod root -a -G admin && usermod vagrant -a -G admin

```
[root@pam ~]# cat /etc/group | grep admin
printadmin:x:994:
admin:x:1003:otusadm,root,vagrant
[root@pam ~]# 

```
После создания пользователей, нужно проверить, что они могут подключаться по SSH к нашей ВМ. Для этого пытаемся подключиться с хостовой машины: 
ssh otus@192.168.57.10

```
buravtsovps@otus:~/OTUS/module2/lesson-13-PAM$ ssh otus@192.168.57.10
The authenticity of host '192.168.57.10 (192.168.57.10)' can't be established.
ED25519 key fingerprint is SHA256:q3jOTBaR5GDSInOSkkG/yNGTtz0gSt+fkpez4IKppSk.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? y
Please type 'yes', 'no' or the fingerprint: yes
Warning: Permanently added '192.168.57.10' (ED25519) to the list of known hosts.
otus@192.168.57.10's password: 
[otus@pam ~]$ 
[otus@pam ~]$ 
[otus@pam ~]$ 
[otus@pam ~]$ 
[otus@pam ~]$ 
[otus@pam ~]$ w
 09:48:25 up 19 min,  2 users,  load average: 0.04, 0.03, 0.07
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
vagrant  pts/0    10.0.2.2         09:40    1:29   0.82s  0.15s sshd: vagrant [priv]                           
otus     pts/1    192.168.57.1     09:48    0.00s  0.13s  0.03s w
[otus@pam ~]$ whoami
otus
[otus@pam ~]$ 
[otus@pam ~]$ 
[otus@pam ~]$ exit 
logout
Connection to 192.168.57.10 closed.
buravtsovps@otus:~/OTUS/module2/lesson-13-PAM$ ssh otusadm@192.168.57.10
otusadm@192.168.57.10's password: 
[otusadm@pam ~]$ whoami 
otusadm
[otusadm@pam ~]$ exit 
logout
Connection to 192.168.57.10 closed.
buravtsovps@otus:~/OTUS/module2/lesson-13-PAM$ ssh vagrant@192.168.57.10
vagrant@192.168.57.10's password: 
Last login: Thu May 25 09:40:01 2023 from 10.0.2.2
[vagrant@pam ~]$ whoami 
vagrant
[vagrant@pam ~]$ 
```

Выберем метод PAM-аутентификации, так как у нас используется только ограничение по времени, то было бы логично использовать метод pam_time, однако, данный метод не работает с локальными группами пользователей, и, получается, что использование данного метода добавит нам большое количество однообразных строк с разными пользователями. В текущей ситуации лучше написать небольшой скрипт контроля и использовать модуль pam_exec


Создадим файл-скрипт /usr/local/bin/login.sh

```
[root@pam ~]# nano /usr/local/bin/login.sh

#!/bin/bash
#Первое условие: если день недели суббота или воскресенье
if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
 #Второе условие: входит ли пользователь в группу admin
 if getent group admin | grep -qw "$PAM_USER"; then
        #Если пользователь входит в группу admin, то он может подключиться
        exit 0
      else
        #Иначе ошибка (не сможет подключиться)
        exit 1
    fi
  #Если день не выходной, то подключиться может любой пользователь
  else
    exit 0
fi

```
Добавим права на исполнение файла:

```
[root@pam ~]# chmod +x /usr/local/bin/login.sh
```
Укажем в файле /etc/pam.d/sshd модуль pam_exec и наш скрипт:

account    required     pam_exec.so /usr/local/bin/login.sh

```
[root@pam ~]# cat /etc/pam.d/sshd 
#%PAM-1.0
auth       substack     password-auth
auth       include      postlogin
account    required     pam_sepermit.so
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    optional     pam_motd.so
session    include      password-auth
session    include      postlogin
[root@pam ~]# nano /etc/pam.d/sshd
[root@pam ~]# cat /etc/pam.d/sshd 
#%PAM-1.0
auth       substack     password-auth
auth       include      postlogin
account    required     pam_sepermit.so
account    required     pam_nologin.so
account    required     pam_exec.so /usr/local/bin/login.sh
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    optional     pam_motd.so
session    include      password-auth
session    include      postlogin
[root@pam ~]# 

```
На этом настройка завершена, нужно только проверить, что скрипт отрабатывает корректно. 


Пользователь otusadm должен подключается в выходной день без проблем: 
```
buravtsovps@otus:~/OTUS/module2/lesson-13-PAM$ ssh otusadm@192.168.57.10
otusadm@192.168.57.10's password: 
Last login: Thu May 25 09:49:24 2023 from 192.168.57.1
[otusadm@pam ~]$ 
```
При логине в выходной день пользователя otus появляется ошибка:

```
buravtsovps@otus:~/OTUS/module2/lesson-13-PAM$ ssh otus@192.168.57.10
otus@192.168.57.10's password: 
/usr/local/bin/login.sh failed: exit code 1
Connection closed by 192.168.57.10 port 22
buravtsovps@otus:~/OTUS/module2/lesson-13-PAM$ 
```


**\* дать конкретному пользователю права работать с докером
и возможность рестартить докер сервис**

Это можно реализовать добавив правило для polkitd для политики org.freedesktop.systemd1.manage-units

заходим в /etc/polkit-1/rules.d/  и создаём там правило следующего содержания:
```
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "docker.service" &&
        subject.user == "otus")
    {
     	return polkit.Result.YES;
    }
})
```

```
[root@pam rules.d]# touch 01-systemd-docker.rules
[root@pam rules.d]# ll
total 8
-rw-r--r--. 1 root root   0 May 27 12:07 01-systemd-docker.rules
-rw-r--r--. 1 root root 974 May 11  2019 49-polkit-pkla-compat.rules
-rw-r--r--. 1 root root 326 Sep  4  2017 50-default.rules
```
Правило сразу подхватывается и можно управлять сервисом. Заходим под обычного пользователя otus и управляем сервисом docker.service

```
[otus@pam vagrant]$ systemctl stop docker.service 
Warning: Stopping docker.service, but it can still be activated by:
  docker.socket
[otus@pam vagrant]$ systemctl start docker.service 
[otus@pam vagrant]$ systemctl restart  docker.service 
[otus@pam vagrant]$ systemctl status  docker.service 
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2023-05-27 12:17:07 UTC; 7s ago
     Docs: https://docs.docker.com
 Main PID: 25227 (dockerd)
    Tasks: 8
   Memory: 27.9M
   CGroup: /system.slice/docker.service
           └─25227 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
[otus@pam vagrant]$ 
```