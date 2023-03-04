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

версия ядра до перезагрузки:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/01-kernel-packer/screenshots/1_2.jpg)

после перезагрузки:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/01-kernel-packer/screenshots/1_1.jpg)

**2. Создать Vagrant box c помощью Packer**

В ходе создания образа возникали различные ошибки, в итоге в  конфигурации добавил такие дополнения:

в [centos.json](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/01-kernel-packer/centos.json):


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

в файле конфигурации ОС [ks.cfg](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/01-kernel-packer/http/ks.cfg):

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

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/01-kernel-packer/screenshots/2_4.jpg)

\#Добавляем пользователя vagrant в sudoers
```
%post
echo "# Allow vagrant to run any commands anywhere" >> /etc/sudoers
echo "vagrant   ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers
%end
```
box собрался:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/01-kernel-packer/screenshots/2_1.jpg)

добавил в vagrant:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/01-kernel-packer/screenshots/2_2.jpg)

создал [Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/01-kernel-packer/Vagrantfile)

**3. Загрузить Vagrant box в Vagrant Cloud**

[ссылка на загруженый образ centos8-kernel6](https://app.vagrantup.com/psbur/boxes/centos8-kernel6)


Авторизоваться через логин пароль в vagrant cloude  почему то не получилось.
```
Vagrant Cloud request failed - This endpoint is restricted as this account is linked through HCP. Please log into the web interface at https://app.vagrantup.com to manage your API tokens. (VagrantCloud::Error::ClientError::RequestError)
```
![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/01-kernel-packer/screenshots/3_2.jpg)

а через токен авторизовался:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/01-kernel-packer/screenshots/3_1.jpg)


