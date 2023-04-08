
## Домашнее задание  

#### Работа с загрузчиком


---

### Описание домашнего задания

* Попасть в систему без пароля несколькими способами.
* Установить систему с LVM, после чего переименовать VG.
* Добавить модуль в initrd.



**1. Попасть в систему без пароля несколькими способами.**

Открываем GUI VirtualBox запускаем виртуальную машину и при выборе ядра для загрузки жмём e(edit). В открываемом окне можно менять параметры загрузки.

Дальше можно по разному попасть в систему:

**Способ 1. init=/bin/sh**

В конце строки начинающейся с linux16 добавляем init=/bin/sh, убираем параметры console=tty0 console=ttyS0,115200n8 и нажимаем сtrl-x для загрузки в систему. 
(В этом способе мы оказываемся в корневой файловой системе.) 
Но рутовая файловая система при этом монтируется в режиме Read-Only. 

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/screenshots/1_1.jpg)

Если мы хотим перемонтировать её в режим Read-Write можно воспользоваться командой:

**mount -o remount,rw /**

проверяем изменения, меняем пароль root

(после этого необходимо обновить контекст SELINUX - создаём файл touch /.autorelabel для обновления меток, иначе не получится залогиниться.)

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/screenshots/1_2.jpg)

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/screenshots/1_3.jpg)


**Способ 2. rd.break**

В конце строки начинающейся с linux16 добавляем rd.break rd.break enforcing=0, убираем параметры console=tty0 console=ttyS0,115200n8 и нажимаем сtrl-x для загрузки в систему. 
(enforcing=0 загрузка SELinux в permissive режиме)

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/screenshots/rd.jpg)

Попадаем в **emergency mode**. Наша корневая файловая система смонтирована в режиме Read-Only, но мы не в ней. Что бы попасть в неё и поменять пароль администратора:

* перемонтируем файловую систему с возможностью записи:

mount -o remount,rw /sysroot 

* измененяем корневую файловую систему:

chroot /sysroot

* изменяем пароль суперпользователя:

passwd


![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/screenshots/rd_3.jpg)



**Способ 3. rw init=/sysroot/bin/sh**

В строке начинающейся с linux16 заменяем ro на rw init=/sysroot/bin/sh и нажимаем сtrl-x
для загрузки в систему:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/screenshots/1_3_2.jpg)

Так же как в предыдущем способе попадаем в emergency mode. Но файловая система сразу
смонтирована в режим Read-Write.  (В прошлых примерах тоже можно заменить ro на rw)

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/screenshots/1_3_4%20!%203%20%D1%81%D0%BF%D0%BE%D1%81%D0%BE%D0%B1.jpg)


**2. Установить систему с LVM, после чего переименовать VG.**

Первым делом посмотрим текущее состояние системы:

```
[root@systemboot ~]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0 
```
Приступим к переименованию:

```
[root@systemboot ~]# vgs
[root@systemboot ~]# vgrename VolGroup00 OtusRoot
  Volume group "VolGroup00" successfully renamed to "OtusRoot"
```
Далее правим /etc/fstab, /etc/default/grub, /boot/grub2/grub.cfg. Везде заменяем старое
название на новое: 

```
[root@systemboot ~]# sed -i 's/VolGroup00/OtusRoot/g' /etc/fstab

[root@systemboot ~]# sed -i 's/VolGroup00/OtusRoot/g' /etc/default/grub

[root@systemboot ~]# sed -i 's/VolGroup00/OtusRoot/g' /boot/grub2/grub.cfg
```
![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/screenshots/2_3(%D1%81%D1%82%D0%B0%D0%BB%D0%BE).jpg)

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/screenshots/2_5(%D1%81%D1%82%D0%B0%D0%BB%D0%BE).jpg)


Пересоздаем initrd image, чтобы он знал новое название Volume Group:

```
[root@systemboot ~]# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)

*** Constructing AuthenticAMD.bin ****
*** No early-microcode cpio image needed ***
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```
Перезагружаемся и проверяем новое имя Volume Group:

```
[root@systemboot ~]# vgs
  VG       #PV #LV #SN Attr   VSize   VFree
  OtusRoot   1   2   0 wz--n- <38.97g    0 
[root@systemboot ~]# 
```


**3.Добавить модуль в initrd**

Скрипты модулей хранятся в каталоге /usr/lib/dracut/modules.d/. Для того чтобы добавить свой модуль создаем там папку с именем 01test:

```
[root@systemboot ~]# mkdir /usr/lib/dracut/modules.d/01test
```
В нее поместим два скрипта:

1. ![module-setup.sh](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/module-setup.sh) - который устанавливает модуль и вызывает скрипт test.sh
2. ![test.sh](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/test.sh) - собственно сам вызываемый скрипт, в нём у нас рисуется пингвинчик

Пересобираем образ initrd

```
[root@systemboot 01test]# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)

*** Resolving executable dependencies ***
*** Resolving executable dependencies done***
*** Hardlinking files ***
*** Hardlinking files done ***
*** Stripping files ***
*** Stripping files done ***
*** Generating early-microcode cpio image contents ***
*** Constructing AuthenticAMD.bin ****
*** No early-microcode cpio image needed ***
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***

```
Можно проверить/посмотреть какие модули загружены в образ:

```
[root@systemboot 01test]# lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
test
[root@systemboot 01test]# 
```

Отредактируем grub.cfg убрав опции rghb и quiet.

("rhgb quiet". Она означает "тихую графическую загрузку" и будет подавлять загрузочные сообщения ядра.)

```
[root@systemboot 01test]# sed -i "s/rhgb/ /" /boot/grub2/grub.cfg
[root@systemboot 01test]# sed -i "s/quiet/ /" /boot/grub2/grub.cfg
[root@systemboot 01test]# 
```

Перезагружаемся и при загрузке во время  пауза на 10 секунд можно увидеть пингвина в выводе
терминала

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/07-boot-grub2/screenshots/3_2.jpg)










