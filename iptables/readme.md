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

1.  Подготовлены ![Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/iptables/Vagrantfile) и ![Ansible-playbook](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/iptables/ansible/provision.yml), который разворачивает конфигурацию схемы в соответствии с текущим заданием.

  К схеме из предыдущего задания ("Архитектура сетей") добавляем inetRouter2, соединённый с centralServer сетью 192.168.255.4/30,
После запуска машин по изменённому [Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/iptables/Vagrantfile) получаем следующую схему:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/iptables/png/topology.png)

2. Для реализации knocking port на inetRouter устанавливаем пакет knockd, редактируем файл его настроек [/etc/knockd.conf](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/iptables/ansible/templates/knockd.conf), редактируем файл конфигурации правил iptables [/etc/sysconfig/iptables](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/iptables/ansible/templates/iptables_inetRouter), перезапускаем iptables и network service.

На centralRouter создаём скрипт knock.sh:
```
#!/bin/bash
HOST=$1
shift
for ARG in "$@"
do
        nmap -Pn --host-timeout 100 --max-retries 0 -p $ARG $HOST
done
```

Для проверки устанавливаем nmap, запускаем скрипт с соответствующими параметрами и пробуем зайти по ssh на inetRouter

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/iptables/png/knock.png)


![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/iptables/png/ssh_inetRouter.png)


3.
 * На centralServer удаляем маршрут по умолчанию, устанавливаем в качестве шлюза по умолчанию 192.168.0.1, устанавливаем epel-release, устанавливаем и запускаем nginx, перезапускаем network service.


* на inetRouter2 удаляем маршрут по умолчанию, устанавливаем в качестве шлюза по умолчанию 192.168.255.5, устанавливаем iptables и iptables-services, редактируем файл конфигурации правил iptables ![/etc/sysconfig/iptables](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/iptables/ansible/templates/iptables_inetRouter2), перезапускаем iptables и network service.

В результате реализован проход на 80 порт centralRouter через 8080 порт inetRouter2 (который в свою очередь прокинут на 8080 порт хостовой машины).

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/iptables/png/nginx_1.png)

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/iptables/png/curl.png)

