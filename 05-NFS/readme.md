# Цель домашнего задания
Научиться самостоятельно развернуть сервис NFS и подключить к нему клиента



---


## Описание домашнего задания
 Основная часть:
- `vagrant up` должен поднимать 2 настроенных виртуальных машины
(сервер NFS и клиента) без дополнительных ручных действий;
- на сервере NFS должна быть подготовлена и экспортирована
директория;
- в экспортированной директории должна быть поддиректория
с именем __upload__ с правами на запись в неё;
- экспортированная директория должна автоматически монтироваться
на клиенте при старте виртуальной машины (systemd, autofs или fstab -
любым способом);
- монтирование и работа NFS на клиенте должна быть организована
с использованием NFSv3 по протоколу UDP;
- firewall должен быть включен и настроен как на клиенте,
так и на сервере.


---
**1. Используя шаблон создаём тестовые виртуальные машины**
```
buravtsovps@otus:~/OTUS/module1/lesson5-NFS$ vagrant status
Current machine states:

nfss                      running (virtualbox)
nfsc                      running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```
**2. Настраиваем сервер NFS**

устанавливаем пакет nfs-utils:
```
[root@nfs-server ~]# yum install nfs-utils
```
включаем firewall,проверяем, что он работает и разрешаем в firewall доступ к сервисам NFS:

```
[root@nfs-server ~]# systemctl enable firewalld --now 
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
[root@nfs-server ~]# firewall-cmd --add-service="nfs3" --add-service="rpc-bind" --add-service="mountd" --permanent 
success
```
перезагружаем файрвол, делаем list-all, чтобы увидеть его в списке сервисов: 
```
[root@nfs-server ~]# firewall-cmd --reload
success
[root@nfs-server ~]# firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources: 
  services: dhcpv6-client mountd nfs3 rpc-bind ssh
  ports: 
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
```

включаем сервер NFS:

```
systemctl enable nfs --now 

[root@nfs-server ~]# systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
   Active: active (exited) since Thu 2023-03-23 15:38:02 UTC; 4min 56s ago
  Process: 22326 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 22310 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 22309 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 22310 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Mar 23 15:38:02 nfs-server systemd[1]: Starting NFS server and services...
Mar 23 15:38:02 nfs-server systemd[1]: Started NFS server and services.
[root@nfs-server ~]# 
```
проверяем наличие слушаемых портов 2049/udp, 2049/tcp, 20048/udp,  20048/tcp, 111/udp, 111/tcp:

```
[root@nfs-server ~]# ss -tnp4lu | grep '20\|111'
udp    UNCONN     0      0         *:111                   *:*                   users:(("rpcbind",pid=344,fd=6))
udp    UNCONN     0      0         *:2049                  *:*                  
udp    UNCONN     0      0         *:20048                 *:*                   users:(("rpc.mountd",pid=22308,fd=7))
tcp    LISTEN     0      64        *:2049                  *:*                  
tcp    LISTEN     0      128       *:111                   *:*                   users:(("rpcbind",pid=344,fd=8))
tcp    LISTEN     0      128       *:20048                 *:*                   users:(("rpc.mountd",pid=22308,fd=8))
[root@nfs-server ~]# 
```
создаём и настраиваем директорию, которая будет экспортирована в будущем: 

```
[root@nfs-server ~]# mkdir -p /srv/share/upload 
[root@nfs-server ~]# chown -R nfsnobody:nfsnobody /srv/share 
[root@nfs-server ~]# chmod 0777 /srv/share/upload 

[root@nfs-server ~]# ls -ld /srv/share/upload/
drwxrwxrwx. 2 nfsnobody nfsnobody 6 Mar 24 15:03 /srv/share/upload/
```

создаём в файле /etc/exports структуру, которая позволит экспортировать ранее созданную директорию: 

```
[root@nfs-server ~]# cat << EOF > /etc/exports 
> /srv/share 192.168.50.11/32(rw,sync,root_squash) 
> EOF
```
экспортируем ранее созданную директорию проверяем экспортированную директорию:

```
[root@nfs-server ~]# exportfs -r 
[root@nfs-server ~]# exportfs -s 
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[root@nfs-server ~]# 
```

**3. Настраиваем клиент NFS**

включаем firewall и проверяем, что он работает:
```
[root@nfs-client ~]# systemctl enable firewalld --now 
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
[root@nfs-client ~]# systemctl status firewalld 
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2023-03-25 10:05:22 UTC; 9s ago
     Docs: man:firewalld(1)
 Main PID: 2652 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─2652 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Mar 25 10:05:22 nfs-client systemd[1]: Starting firewalld - dynamic firewall daemon...
Mar 25 10:05:22 nfs-client systemd[1]: Started firewalld - dynamic firewall daemon.
Mar 25 10:05:23 nfs-client firewalld[2652]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration option. It will be removed in a future release. Please consider disabling it now.
[root@nfs-client ~]# 
```
добавляем в /etc/fstab строку:
```
[root@nfs-client ~]# echo "192.168.56.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
```
(в данном случае происходит автоматическая генерация systemd units в каталоге `/run/systemd/generator/`, которые производят монтирование при первом обращении к катаmcлогу `/mnt/`)

перезапускаем демон systemd и remote-fs:
```
[root@nfs-client ~]# systemctl daemon-reload 
[root@nfs-client ~]# systemctl restart remote-fs.target
```
проверяем успешность монтирования:
```
[root@nfs-client ~]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=26,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=19749)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10,_netdev)
[root@nfs-client ~]# 
```

**4. Проверка работоспособности**

- заходим на сервер 
- заходим в каталог `/srv/share/upload` 
- создаём тестовый файл `touch check_file` 
- заходим на клиент 
- заходим в каталог `/mnt/upload` 
- проверяем наличие ранее созданного файла 
- создаём тестовый файл `touch client_file` 
- проверяем, что файл успешно создан 


```
[root@nfs-server share]# cd upload/
[root@nfs-server upload]# touch check_file
[root@nfs-server upload]# ll
total 0
-rw-r--r--. 1 root      root      0 Mar 25 12:43 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Mar 25 12:44 client_file
```
```
[root@nfs-client upload]# ls
check_file
[root@nfs-client upload]# touch client_file
[root@nfs-client upload]# ll
total 0
-rw-r--r--. 1 root      root      0 Mar 25 12:43 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Mar 25 12:44 client_file
[root@nfs-client upload]# 

```
Предварительно проверяем клиент: 

- перезагружаем клиент
- заходим в каталог `/mnt/upload` 
- проверяем наличие ранее созданных файлов 
(файлы на месте)

```
[root@nfs-client ~]# cd /mnt/upload/
[root@nfs-client upload]# ls -lsa
total 0
0 drwxrwxrwx. 2 nfsnobody nfsnobody 43 Mar 25 12:44 .
0 drwxr-xr-x. 3 nfsnobody nfsnobody 33 Mar 25 11:34 ..
0 -rw-r--r--. 1 root      root       0 Mar 25 12:43 check_file
0 -rw-r--r--. 1 nfsnobody nfsnobody  0 Mar 25 12:44 client_file
[root@nfs-client upload]# 
```
Проверяем сервер: 

- заходим на сервер в отдельном окне терминала 
- перезагружаем сервер 
- заходим на сервер 
- проверяем наличие файлов в каталоге `/srv/share/upload/` - проверяем статус сервера NFS `systemctl status nfs` - проверяем статус firewall `systemctl status firewalld` - проверяем экспорты `exportfs -s` 
- проверяем работу RPC `showmount -a 192.168.50.10` 

```
[root@nfs-server ~]# ls -lsa /srv/share/upload/
total 0
0 drwxrwxrwx. 2 nfsnobody nfsnobody 43 Mar 25 12:44 .
0 drwxr-xr-x. 3 nfsnobody nfsnobody 33 Mar 25 11:34 ..
0 -rw-r--r--. 1 root      root       0 Mar 25 12:43 check_file
0 -rw-r--r--. 1 nfsnobody nfsnobody  0 Mar 25 12:44 client_file
[root@nfs-server ~]# 
```
```
[root@nfs-server ~]# systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Sat 2023-03-25 14:01:19 UTC; 22min ago
  Process: 792 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 772 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 766 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 772 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Mar 25 14:01:18 nfs-server systemd[1]: Starting NFS server and services...
Mar 25 14:01:19 nfs-server systemd[1]: Started NFS server and services.
[root@nfs-server ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2023-03-25 14:01:07 UTC; 22min ago
     Docs: man:firewalld(1)
 Main PID: 367 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─367 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Mar 25 14:01:05 nfs-server systemd[1]: Starting firewalld - dynamic firewall daemon...
Mar 25 14:01:07 nfs-server systemd[1]: Started firewalld - dynamic firewall daemon.
Mar 25 14:01:08 nfs-server firewalld[367]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration option. It will be removed in a future release. Please consider disabling it now.
```


```
[root@nfs-server ~]# exportfs -s 
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[root@nfs-server ~]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
```



Проверяем клиент: 

- возвращаемся на клиент 
- перезагружаем клиент 
- заходим на клиент 
- проверяем работу RPC `showmount -e 192.168.50.10` - заходим в каталог `/mnt/upload` 
- проверяем статус монтирования `mount | grep mnt` 
- проверяем наличие ранее созданных файлов 
- создаём тестовый файл `touch final_check` 
- проверяем, что файл успешно создан 

```
[root@nfs-client upload]# showmount -e 192.168.50.10
Export list for 192.168.50.10:
/srv/share 192.168.50.11/32
[root@nfs-client upload]# 
```

```
[root@nfs-client upload]# ls -lsa
total 0
0 drwxrwxrwx. 2 nfsnobody nfsnobody 43 Mar 25 12:44 .
0 drwxr-xr-x. 3 nfsnobody nfsnobody 33 Mar 25 11:34 ..
0 -rw-r--r--. 1 root      root       0 Mar 25 12:43 check_file
0 -rw-r--r--. 1 nfsnobody nfsnobody  0 Mar 25 12:44 client_file
[root@nfs-client upload]# 
```

```
[root@nfs-client upload]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=32,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=11089)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10,_netdev)
```

```
[root@nfs-client upload]# touch final_check
[root@nfs-client upload]# ls -lsa
total 0
0 drwxrwxrwx. 2 nfsnobody nfsnobody 62 Mar 25 14:41 .
0 drwxr-xr-x. 3 nfsnobody nfsnobody 33 Mar 25 11:34 ..
0 -rw-r--r--. 1 root      root       0 Mar 25 12:43 check_file
0 -rw-r--r--. 1 nfsnobody nfsnobody  0 Mar 25 12:44 client_file
0 -rw-r--r--. 1 nfsnobody nfsnobody  0 Mar 25 14:41 final_check
[root@nfs-client upload]# 
```   

**5. Создание автоматизированного Vagrantfile**

Что бы vagrant без дополнительных ручных действий сразу собирал сервер NFS и клиента нужно в [Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/05-NFS/Vagrantfile) указать [скрипт](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/05-NFS/nfss_script.sh) для конфигурирования nfs-сервера и [скрипт](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/05-NFS/nfsc_script.sh) для конфигурирования nfs-клиента, которые выполнятся после того, как машина будет развёрнута. 
```
nfss.vm.provision "shell", path: "nfss_script.sh"

nfsc.vm.provision "shell", path: "nfsc_script.sh"
```

