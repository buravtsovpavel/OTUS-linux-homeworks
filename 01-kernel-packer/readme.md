# Цель домашнего задания
Научиться обновлять ядро в ОС Linux. Получение навыков работы с Vagrant, Packer и публикацией готовых образов в Vagrant Cloud. 


---


## Описание домашнего задания
1. Обновить ядро ОС из репозитория ELRepo
2. Создать Vagrant box c помощью Packer
3. Загрузить Vagrant box в Vagrant Cloud


---
**1. Обновить ядро ОС из репозитория ELRepo**

обновление ядра из elrepo прошло гладко, всё по методичке

версия ядра до и после обновления

вставить 1_1
вставить 1_2

**2. Создать Vagrant box c помощью Packer**

В ходе создания образа возникали различные ошибки, в итоге в  конфигурации добавил такие дополнения:

в centos.json:

(сделать список)

* добавил время ожидания подключения "ssh_timeout": "120m" (первый раз не хватило 20 минут)  

* в "vboxmanage": добавлена секция 
```
        [
              [  "modifyvm",
                 "{{.Name}}",
                 "--nat-localhostreachable1", "on"
                ]  
        ]
```
   (после обновления virtaulbox до 7.2 выскочила ошибка о не возможности подключения к ks.cfg) 

* "disk_size": "20480"

* указал локальный образ на диструбутив 
```
   "iso_urls": [
          "CentOS-Stream-8-x86_64-20220603-boot.iso", 
          "http://mirrors.nipa.cloud/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-20220603-boot.iso"
          ],
```

в файле конфигурации ОС ks.cfg:

* закоментировал #authconfig --enableshadow --passalgo=sha512

* поправил дефис в firewall --disabled

* \#Выбираем набор пакетов которые нужно установить
```
%packages --nocore --excludedocs
@^minimal-environment
yum
yum-utils
sudo
openssh
openssh-server
openssh-clients
sshpass
qemu-kvm-block-ssh
%end
```
(сборка падала сборка с ошибкой `--> centos-8: Error removing temporary script at /tmp/script_198.sh: Timeout during SSH handshake
==> Builds finished but no artifacts were created.`)

так же после отработки скриптов когда на финальном этапе когда packer должен собрать box два раза случался краш пакера, решилось тем что обновил packer до 1.8.6

\#Добавляем пользователя vagrant в sudoers
```
%post
echo "# Allow vagrant to run any commands anywhere" >> /etc/sudoers
echo "vagrant   ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers
%end
```
box собрался

добавил в vagrant




**3. Загрузить Vagrant box в Vagrant Cloud**

ссылка на загруженый образ
(вставить ссылку)

Авторизоваться через логин пароль в vagrant cloude  почему то не получилось.

а через токен авторизовался (картинка)


