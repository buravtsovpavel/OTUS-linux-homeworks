## Домашнее задание

Сценарии iptables


#### Описание домашнего задания

---
*  реализовать knocking port
centralRouter может попасть на ssh inetrRouter через knock скрипт
пример в материалах.
*  добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост.
* запустить nginx на centralServer.
пробросить 80й порт на inetRouter2 8080.
дефолт в инет оставить через inetRouter.
Формат сдачи ДЗ - vagrant + ansible
реализовать проход на 80й порт без маскарадинга*


---

1. К схеме из предыдущего задания ("Архитектура сетей") добавляем inetRouter2, соединённый с centralServer сетью 192.168.255.4/30,
После запуска машин по изменённому Vagrantfile(ссылку) получаем следующую схему:

(вставляем схему)

2. Для реализации knocking port на inetRouter устанавливаем пакет knockd, редактируем файл его настроек /etc/knockd.conf (ссылка), редактируем файл конфигурации правил iptables /etc/sysconfig/iptables (ссылка), перезапускаем iptables и network service.

На centralRouter создаём скрипт knock.sh:
```
скрипт
```

Для проверки устанавливаем nmap и запускаем скрипт с соответствующими параметрами:

```
[root@centralRouter ~]# chmod +x knock.sh 
[root@centralRouter ~]# ./knock.sh 192.168.255.1 8881 7777 9991

Starting Nmap 6.40 ( http://nmap.org ) at 2023-08-25 14:26 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.00053s latency).
PORT     STATE    SERVICE
8881/tcp filtered unknown
MAC Address: 08:00:27:54:D6:28 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.57 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2023-08-25 14:26 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.0043s latency).
PORT     STATE    SERVICE
7777/tcp filtered cbt
MAC Address: 08:00:27:54:D6:28 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.55 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2023-08-25 14:26 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.0034s latency).
PORT     STATE    SERVICE
9991/tcp filtered issa
MAC Address: 08:00:27:54:D6:28 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.54 seconds
[root@centralRouter ~]# 
```
```
[root@centralRouter ~]# ssh 192.168.255.1
The authenticity of host '192.168.255.1 (192.168.255.1)' can't be established.
ECDSA key fingerprint is SHA256:Apq6haBCDI+DfcSmiNGmk5AzIEdIJAEu+4DM5xhJEM8.
ECDSA key fingerprint is MD5:0d:52:25:b4:b7:06:71:a9:37:f5:41:d5:ff:05:be:0d.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.255.1' (ECDSA) to the list of known hosts.
root@192.168.255.1's password: 
[root@inetRouter ~]# 
```



3.
 * На centralServer удаляем маршрут по умолчанию, устанавливаем в качестве шлюза по умолчанию 192.168.0.1, устанавливаем epel-release, устанавливаем и запускаем nginx, перезапускаем network service.


* на inetRouter2 удаляем маршрут по умолчанию, устанавливаем в качестве шлюза по умолчанию 192.168.255.5, устанавливаем iptables и iptables-services, редактируем файл конфигурации правил iptables /etc/sysconfig/iptables (ссылка), перезапускаем iptables и network service.

В результате реализован проход на 80 порт centralRouter через 8080 порт inetRouter2 (который в свою очередь прокинут на 8080 порт хостовой машины).

картинку

Подготовлены Vagrantfile и Ansible-playbook, который разворачивает конфигурацию схемы в соответствии с текущим заданием.