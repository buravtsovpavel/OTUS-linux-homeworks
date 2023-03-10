# Цель домашнего задания
Работа с mdadm


---


## Описание домашнего задания
1. добавить в Vagrantfile еще дисков
2. собрать R0/R5/R10 на выбор
3. сломать/починить raid
4. прописать собранный рейд в конф, чтобы рейд собирался при загрузке
5. создать GPT раздел и 5 партиций

## Доп. задание
Vagrantfile, который сразу собирает систему с подключенным рейдом и смонтированными разделами. После перезагрузки стенда разделы должны автоматически примонтироваться.



---
**1. добавить в Vagrantfile еще дисков**

Добавил два диска в [Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/RAID/Vagrantfile)
```
        :sata5 => {
                        :dfile => './sata5.vdi', 
                        :size => 250, 
                        :port => 5 
                },
                :sata6 => {
                        :dfile => './sata6.vdi', 
                        :size => 250, 
                        :port => 6 
                }
```                
Сначала сборка упала с ошибкой:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/RAID/screenshots/1_1.jpg)

Решилось тем, что создал  /etc/vbox/networks.conf  и дописал в него подесть * 192.168.11.0/24. 

Машина запустилась, диски добавились:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/RAID/screenshots/1_2.jpg)

**2. собрать R0/R5/R10 на выбор**

* Зануляем на всякий случай суперблоки:
```
[vagrant@otuslinux ~]$ sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}

mdadm: Unrecognised md component device - /dev/sdb

mdadm: Unrecognised md component device - /dev/sdc

mdadm: Unrecognised md component device - /dev/sdd

mdadm: Unrecognised md component device - /dev/sde

mdadm: Unrecognised md component device - /dev/sdf
```

* Создаю RAID5:
```
[vagrant@otuslinux ~]$ sudo mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}

mdadm: layout defaults to left-symmetric

mdadm: layout defaults to left-symmetric

mdadm: chunk size defaults to 512K

mdadm: size set to 253952K

mdadm: Defaulting to version 1.2 metadata

mdadm: array /dev/md0 started.
```
* Проверяем, что создался нормально:
```
[vagrant@otuslinux ~]$ cat /proc/mdstat 

Personalities : [raid6] [raid5] [raid4] 

md0 : active raid5 sdf[5] sde[3] sdd[2] sdc[1] sdb[0]

      1015808 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/5] [UUUUU]
```

**3. сломать/починить raid**

* Искусственно зафейлим одно из блочных устройств:
```
[vagrant@otuslinux ~]$ sudo mdadm /dev/md0 --fail /dev/sde

mdadm: set /dev/sde faulty in /dev/md0
```
Это отразилось на нашем RAID:
```
[vagrant@otuslinux ~]$ cat /proc/mdstat

Personalities : [raid6] [raid5] [raid4] 

md0 : active raid5 sdf[5] sde[3](F) sdd[2] sdc[1] sdb[0]

      1015808 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/4] [UUU_U]
```
* Удаляем сломанный диск из массива:
```
[vagrant@otuslinux ~]$ sudo mdadm /dev/md0 --remove /dev/sde

mdadm: hot removed /dev/sde from /dev/md0
```
* Добавляем "новый" диск в RAID:
```
[vagrant@otuslinux ~]$ sudo mdadm /dev/md0 --add /dev/sde

mdadm: added /dev/sde
```
* Процесс rebuild-а прошёл успешно:
```
[vagrant@otuslinux ~]$ cat /proc/mdstat

Personalities : [raid6] [raid5] [raid4] 

md0 : active raid5 sde[6] sdf[5] sdd[2] sdc[1] sdb[0]

      1015808 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/5] [UUUUU]
```

**4. прописать собранный рейд в конф, чтобы рейд собирался при загрузке**
 
Создадим файл mdadm.conf, что бы OC запомнила какой RAID нужно собрать и какие компоненты в него входят:
```
[vagrant@otuslinux ~]$ sudo mkdir /etc/mdadm
[vagrant@otuslinux ~]$ echo "DEVICE partitions" | sudo tee /etc/mdadm/mdadm.conf

DEVICE partitions

[vagrant@otuslinux ~]$ sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' | sudo tee -a /etc/mdadm/mdadm.conf

ARRAY /dev/md0 level=raid5 num-devices=5 metadata=1.2 name=otuslinux:0 UUID=eb807aa2:1b565bd2:0b34641c:1b86f915
```
(изначально сделать запись в mdadm.conf не удалось по причине не хватки прав на запись и чтение, решил это добавлением прав на чтение и запись для всех, но позже нашлось решение с передачей на ввод утилите tee)

**5. Cоздать GPT раздел и 5 партиций**

* Создаём раздел gpt на RAID:
```
[vagrant@otuslinux ~]$ sudo parted -s /dev/md0 mklabel gpt
```
* Создаём партиции:
```
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 0% 20%

Information: You may need to update /etc/fstab.



[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 20% 40%   

Information: You may need to update /etc/fstab.



[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 40% 60%   

Information: You may need to update /etc/fstab.



[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 60% 80%

Information: You may need to update /etc/fstab.



[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 80% 100%  

Information: You may need to update /etc/fstab.
```
* Создаём на этих партициях файловую систему ext4:
```
[vagrant@otuslinux ~]$ for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
```
* Монтируем их по каталогам:
```
[vagrant@otuslinux ~]$ mkdir -p /raid/part{1,2,3,4,5}
[vagrant@otuslinux ~]$ for i in $(seq 1 5); do sudo  mount /dev/md0p$i /raid/part$i; done
```


![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/RAID/screenshots/1_3.jpg)


---

## Дополнительное задание

Что бы [Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/RAID/Vagrantfile) сразу собирал систему с подключенным рейдом и смонтированными разделами нужно в разделе box.vm.provision указать [скрипт](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/RAID/raid5-mdadm-fstab.sh), который выполнится после того, как машина будет развёрнута. 
```
box.vm.provision "shell", path: "raid5-mdadm-fstab.sh"
```
В этот [скрипт](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/RAID/raid5-mdadm-fstab.sh) собирал все ранее проделанные команды и добавил строку, которая сделает запись в fstab для автоматического монтирования при перезагрузке:
```
for i in $(seq 1 5); do echo "/dev/md0p$i /raid/part$i ext4    defaults    1 2" | sudo tee -a /etc/fstab; done
```






