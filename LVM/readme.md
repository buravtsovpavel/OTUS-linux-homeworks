# Цель домашнего задания
### Работа с LVM


---


## Описание домашнего задания
- уменьшить том под / до 8G
- выделить том под /home
- выделить том под /var (/var - сделать в mirror)
- для /home - сделать том для снэпшотов
- прописать монтирование в fstab (попробовать с разными опциями и разными файловыми системами на выбор)
  
    **Работа со снапшотами:**

- сгенерировать файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановиться со снэпшота (залоггировать работу можно утилитой script, скриншотами и т.п.)
 ---
### **Уменьшаем том под / до 8 Gb**

* Сначала проверяем начальную конфигурацию блочных устройств и какие PV, VG и LV уже созданы в системе:
```
[vagrant@lvm ~]$ lsblk 
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```
```
[vagrant@lvm ~]$ sudo pvs
  PV         VG         Fmt  Attr PSize   PFree
  /dev/sda3  VolGroup00 lvm2 a--  <38.97g    0 
```
```
[vagrant@lvm ~]$ sudo vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0 
```
```
[vagrant@lvm ~]$ sudo lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g                                                    
  LogVol01 VolGroup00 -wi-ao----   1.50g                                       
```
  Далее ставим пакет xfsdump (необходим для снятия копии / тома)

* Готовим временный том для / раздела:
```
[vagrant@lvm ~]$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
```
```
[vagrant@lvm ~]$ sudo vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created
```
```
[vagrant@lvm ~]$ sudo lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.
```
* На созданном lvm-разделе создаём ФС и смонтируем его, что бы перенести туда данные:
```
[vagrant@lvm ~]$ sudo mkfs.xfs /dev/vg_root/lv_root
meta-data=/dev/vg_root/lv_root   isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

[vagrant@lvm ~]$ sudo mount /dev/vg_root/lv_root /mnt
```
* Cкопируем все данные с / раздела в /mnt:
```
[root@lvm ~]# xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
xfsdump: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of lvm:/
xfsdump: dump date: Tue Mar 14 15:31:54 2023
xfsdump: session id: db479c7b-a6c6-4dfb-b526-c154799813e9
xfsdump: session label: ""
xfsrestore: searching media for dump
xfsdump: ino map phase 1: constructing initial dump list
xfsdump: ino map phase 2: skipping (no pruning necessary)
xfsdump: ino map phase 3: skipping (only one dump stream)
xfsdump: ino map construction complete
xfsdump: estimated dump size: 855623872 bytes
xfsdump: creating dump session media file 0 (media 0, file 0)
xfsdump: dumping ino map
xfsdump: dumping directories
xfsrestore: examining media file 0
xfsrestore: dump description: 
xfsrestore: hostname: lvm
xfsrestore: mount point: /
xfsrestore: volume: /dev/mapper/VolGroup00-LogVol00
xfsrestore: session time: Tue Mar 14 15:31:54 2023
xfsrestore: level: 0
xfsrestore: session label: ""
xfsrestore: media label: ""
xfsrestore: file system id: b60e9498-0baa-4d9f-90aa-069048217fee
xfsrestore: session id: db479c7b-a6c6-4dfb-b526-c154799813e9
xfsrestore: media id: 6f0b4723-0057-414b-ade6-d3cedcf8db86
xfsrestore: searching media for directory dump
xfsrestore: reading directories
xfsdump: dumping non-directory files
xfsrestore: 2702 directories and 23623 entries processed
xfsrestore: directory post-processing
xfsrestore: restoring non-directory files
xfsdump: ending media file
xfsdump: media file size 832594904 bytes
xfsdump: dump size (non-dir files) : 819421112 bytes
xfsdump: dump complete: 16 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 16 seconds elapsed
xfsrestore: Restore Status: SUCCESS
[root@lvm ~]# 
```
```
[root@lvm /]# ls -l /mnt/
total 12
lrwxrwxrwx.  1 root    root       7 Mar 12 15:02 bin -> usr/bin
drwxr-xr-x.  2 root    root       6 May 12  2018 boot
drwxr-xr-x.  2 root    root       6 May 12  2018 dev
drwxr-xr-x. 79 root    root    8192 Mar 12 13:12 etc
drwxr-xr-x.  3 root    root      21 May 12  2018 home
lrwxrwxrwx.  1 root    root       7 Mar 12 15:02 lib -> usr/lib
lrwxrwxrwx.  1 root    root       9 Mar 12 15:02 lib64 -> usr/lib64
drwxr-xr-x.  2 root    root       6 Apr 11  2018 media
drwxr-xr-x.  2 root    root       6 Apr 11  2018 mnt
drwxr-xr-x.  2 root    root       6 Apr 11  2018 opt
drwxr-xr-x.  2 root    root       6 May 12  2018 proc
dr-xr-x---.  3 root    root     149 Mar 11 11:39 root
drwxr-xr-x.  2 root    root       6 May 12  2018 run
lrwxrwxrwx.  1 root    root       8 Mar 12 15:02 sbin -> usr/sbin
drwxr-xr-x.  2 root    root       6 Apr 11  2018 srv
drwxr-xr-x.  2 root    root       6 May 12  2018 sys
drwxrwxrwt.  8 root    root     193 Mar 12 14:59 tmp
drwxr-xr-x. 13 root    root     155 May 12  2018 usr
drwxrwxr-x.  4 vagrant vagrant   67 Mar 11 13:03 vagrant
drwxr-xr-x. 18 root    root     254 Mar 11 11:34 var
[root@lvm /]# 
```

* переконфигурируем grub для того, чтобы при старте перейти в новый / :
(Сымитируем текущий root: сделаем в него chroot и обновим grub:)
```
[root@lvm ~]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
( теперь содержимое каталогов /proc/ /sys/ /dev/ /run/ /boot/ из нашей текущей rootfs будет так же доступно в /mnt/proc/   /mnt/sys/   /mnt/dev/   /mnt/run/   /mnt/boot/)
[root@lvm ~]# chroot /mnt/
(временно сменили корень)
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
(обновили конфигурацию загрузчика)
```
- обновляем образ initrd
```
[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
> s/.img//g"` --force; done
```
- чтобы при загрузке был смонтирован нужный root меняем в файле
/boot/grub2/grub.cfg  rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LVM/screenshots/1_2.jpg)

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LVM/screenshots/1_3.jpg)


- выходим из окружения chroot и перезагружаемся новым рут томом. Убеждаемся в этом посмотрев вывод lsblk:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LVM/screenshots/1_4.jpg)


**Теперь нам нужно изменить размер старой VG и вернуть на него рут. Для этого удаляем старый LV размеров в 40G и создаем новый на 8G:**
```
[root@lvm ~]# lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed
[root@lvm ~]# lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
[root@lvm ~]# 
```
* Проделываем на нем те же операции, что и в первый раз:
```
[root@lvm ~]# mkfs.xfs /dev/VolGroup00/LogVol00
meta-data=/dev/VolGroup00/LogVol00 isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm ~]# mount /dev/VolGroup00/LogVol00 /mnt
[root@lvm ~]# xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
```

```
[root@lvm ~]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@lvm ~]# chroot /mnt/
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
> s/.img//g"` --force; done
```
### **Выделим том под /var (/var - делаем в mirror)**
* Не перезагружаясь и не выходя из под chroot свободных дисках sdc и sdd создаём зеркало:

```
[root@lvm /]# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.
[root@lvm /]# vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created
[root@lvm /]# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
```
```
[vagrant@lvm ~]$ lsblk 
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk 
├─sda1                     8:1    0    1M  0 part 
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00  253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
sdb                        8:16   0   10G  0 disk 
└─vg_root-lv_root        253:2    0   10G  0 lvm  
sdc                        8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0  253:3    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0 253:4    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
sdd                        8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1  253:5    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1 253:6    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
sde                        8:64   0    1G  0 disk 
[vagrant@lvm ~]$ 
```
![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LVM/screenshots/1_5.jpg)

* Создаем на этом lv ФС ext4 и перемещаем туда /var:
```
[root@lvm /]# mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
60928 inodes, 243712 blocks
12185 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=249561088
8 block groups
32768 blocks per group, 32768 fragments per group
7616 inodes per group
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

[root@lvm /]# mount /dev/vg_var/lv_var /mnt
[root@lvm /]# cp -aR /var/* /mnt/ 
[root@lvm /]# mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
```
* Монтируем новый /var и правим fstab для его автоматического монтирования:
```
[root@lvm /]# umount /mnt
[root@lvm /]# mount /dev/vg_var/lv_var /var
```
```
[root@lvm /]# echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```
* Перезагружаемся и удаляем временную Volume Group:

```
[root@lvm ~]# lvremove /dev/vg_root/lv_root
Do you really want to remove active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed
[root@lvm ~]# vgremove /dev/vg_root
  Volume group "vg_root" successfully removed
[root@lvm ~]# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
[root@lvm ~]# 
```
### **Выделяем том под /home**
* Создаём новый lv, ФС на нём и монтируем в /mnt:
```
[root@lvm ~]# lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
[root@lvm ~]# mkfs.xfs /dev/VolGroup00/LogVol_Home
[root@lvm ~]# mount /dev/VolGroup00/LogVol_Home /mnt/
[root@lvm ~]# ls -l /mnt/
total 0
```
* Теперь копируем туда содержимое /home, удаляем всё из /home и перемонтируем наш новый том в /home:
```
[root@lvm ~]# cp -aR /home/* /mnt/
[root@lvm ~]# ls -l /mnt/
total 0
drwx------. 3 vagrant vagrant 74 May 12  2018 vagrant
[root@lvm ~]# 
[root@lvm ~]# rm -rf /home/*
[root@lvm ~]# ls -l /home/
total 0
[root@lvm ~]# umount /mnt/
[root@lvm ~]# mount /dev/VolGroup00/LogVol_Home /home/
```
```
[root@lvm ~]# lsblk 
NAME                       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                          8:0    0   40G  0 disk 
├─sda1                       8:1    0    1M  0 part 
├─sda2                       8:2    0    1G  0 part /boot
└─sda3                       8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00    253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01    253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol_Home 253:2    0    2G  0 lvm  /home
sdb                          8:16   0   10G  0 disk 
sdc                          8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0    253:3    0    4M  0 lvm  
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0   253:4    0  952M  0 lvm  
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sdd                          8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1    253:5    0    4M  0 lvm  
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1   253:6    0  952M  0 lvm  
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sde                          8:64   0    1G  0 disk 
[root@lvm ~]# 
```
* **Правим fstab для автоматического монтирования /home**
```
[root@lvm ~]# echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```
```
[root@lvm ~]# cat /etc/fstab 

#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/VolGroup00-LogVol00 /                       xfs     defaults        0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0
/dev/mapper/VolGroup00-LogVol01 swap                    swap    defaults        0 0
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
#VAGRANT-END
UUID="933b9ba9-b74e-40fd-b812-8263aed7d105" /var ext4 defaults 0 0
UUID="fb1ca7f3-d4f1-48f8-afa6-ce49928d3a92" /home xfs defaults 0 0
[root@lvm ~]# 
```
После всех манипуляций имеем такую конфигурацию блочных устройств:
![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LVM/screenshots/1_6.jpg)

### **Работа со снапшотами.**
* Наполним каталог /home файлами
```
[root@lvm ~]# cp -aR /var/* /home/
[root@lvm ~]# ls -l /home/
total 8
drwxr-xr-x.  2 root    root       6 Apr 11  2018 adm
drwxr-xr-x.  5 root    root      44 May 12  2018 cache
drwxr-xr-x.  3 root    root      34 May 12  2018 db
drwxr-xr-x.  3 root    root      18 May 12  2018 empty
drwxr-xr-x.  2 root    root       6 Apr 11  2018 games
drwxr-xr-x.  2 root    root       6 Apr 11  2018 gopher
drwxr-xr-x.  3 root    root      18 May 12  2018 kerberos
drwxr-xr-x. 28 root    root    4096 Mar 14 16:02 lib
drwxr-xr-x.  2 root    root       6 Apr 11  2018 local
lrwxrwxrwx.  1 root    root      11 Mar 14 16:03 lock -> ../run/lock
drwxr-xr-x.  8 root    root    4096 Mar 16 14:58 log
drwx------.  2 root    root       6 Mar 14 16:22 lost+found
lrwxrwxrwx.  1 root    root      10 Mar 14 16:03 mail -> spool/mail
drwxr-xr-x.  2 root    root       6 Apr 11  2018 nis
drwxr-xr-x.  2 root    root       6 Apr 11  2018 opt
drwxr-xr-x.  2 root    root       6 Apr 11  2018 preserve
lrwxrwxrwx.  1 root    root       6 Mar 14 16:03 run -> ../run
drwxr-xr-x.  8 root    root      87 May 12  2018 spool
drwxrwxrwt.  4 root    root     164 Mar 16 14:58 tmp
drwx------.  3 vagrant vagrant   74 May 12  2018 vagrant
drwxr-xr-x.  2 root    root       6 Apr 11  2018 yp
[root@lvm ~]# 
```
* Снимаем снапшот, что бы потом с него восстановиться:
```
[root@lvm ~]# lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.
```
* Снапшот создан:
```
[root@lvm ~]# lvs
  LV          VG         Attr       LSize   Pool Origin      Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00    VolGroup00 -wi-ao----   8.00g                                                         
  LogVol01    VolGroup00 -wi-ao----   1.50g                                                         
  LogVol_Home VolGroup00 owi-aos---   2.00g                                                         
  home_snap   VolGroup00 swi-a-s--- 128.00m      LogVol_Home 0.01                                   
  lv_var      vg_var     rwi-aor--- 952.00m             
```
* Удалим из /home все объекты начинающиеся на l:
```
[root@lvm ~]# rm -rf /home/l*
```
* После удаления имеем такой использующийся объём:
```
[root@lvm ~]# df -h /home/
Filesystem                          Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol_Home  2.0G  204M  1.8G  10% /home
```

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LVM/screenshots/1_7.jpg)

* Теперь отмонтируем восстонавливаемый lv и сделаем в него merge снапшота:
```
[root@lvm ~]# umount /home/
[root@lvm ~]# lvconvert --merge /dev/VolGroup00/home_snap
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LogVol_Home: Merged: 100.00%
[root@lvm ~]# mount /home/
```
* В результате восстановления получаем всё удалённые ранее объекты на l:
```
[root@lvm ~]# ls -ls /home/
total 8
0 drwxr-xr-x.  2 root    root       6 Apr 11  2018 adm
0 drwxr-xr-x.  5 root    root      44 May 12  2018 cache
0 drwxr-xr-x.  3 root    root      34 May 12  2018 db
0 drwxr-xr-x.  3 root    root      18 May 12  2018 empty
0 drwxr-xr-x.  2 root    root       6 Apr 11  2018 games
0 drwxr-xr-x.  2 root    root       6 Apr 11  2018 gopher
0 drwxr-xr-x.  3 root    root      18 May 12  2018 kerberos
4 drwxr-xr-x. 28 root    root    4096 Mar 14 16:02 lib
0 drwxr-xr-x.  2 root    root       6 Apr 11  2018 local
0 lrwxrwxrwx.  1 root    root      11 Mar 14 16:03 lock -> ../run/lock
4 drwxr-xr-x.  8 root    root    4096 Mar 16 14:58 log
0 drwx------.  2 root    root       6 Mar 14 16:22 lost+found
0 lrwxrwxrwx.  1 root    root      10 Mar 14 16:03 mail -> spool/mail
0 drwxr-xr-x.  2 root    root       6 Apr 11  2018 nis
0 drwxr-xr-x.  2 root    root       6 Apr 11  2018 opt
0 drwxr-xr-x.  2 root    root       6 Apr 11  2018 preserve
0 lrwxrwxrwx.  1 root    root       6 Mar 14 16:03 run -> ../run
0 drwxr-xr-x.  8 root    root      87 May 12  2018 spool
0 drwxrwxrwt.  4 root    root     164 Mar 16 14:58 tmp
0 drwx------.  3 vagrant vagrant   74 May 12  2018 vagrant
0 drwxr-xr-x.  2 root    root       6 Apr 11  2018 yp
```
и использующийся объём восстановился в размере:
```
[root@lvm ~]# df -h /home/
Filesystem                          Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol_Home  2.0G  256M  1.8G  13% /home
```
![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LVM/screenshots/1_8.jpg)
