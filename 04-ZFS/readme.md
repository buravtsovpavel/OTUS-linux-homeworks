### Цели домашнего задания


Научится самостоятельно устанавливать ZFS, настраивать пулы, изучить основные возможности ZFS. 

---

### Описание домашнего задания
1. Определить алгоритм с наилучшим сжатием
* Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);
* Создать 4 файловых системы на каждой применить свой алгоритм сжатия;
* Для сжатия использовать либо текстовый файл, либо группу файлов:
2. Определить настройки пула
* С помощью команды zfs import собрать pool ZFS;
* Командами zfs определить настройки:
    - размер хранилища;
    - тип pool;
    - значение recordsize;
    - какое сжатие используется;
    - какая контрольная сумма используется.
3. Работа со снапшотами
* скопировать файл из удаленной директории.   https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing 
* восстановить файл локально. zfs receive
* найти зашифрованное сообщение в файле secret_message

**1. Определить алгоритм с наилучшим сжатием**

Смотрим список дисков, которые у нас есть:

```
[root@zfs ~]# lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk 
`-sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk 
sdc      8:32   0  512M  0 disk 
sdd      8:48   0  512M  0 disk 
sde      8:64   0  512M  0 disk 
sdf      8:80   0  512M  0 disk 
sdg      8:96   0  512M  0 disk 
sdh      8:112  0  512M  0 disk 
sdi      8:128  0  512M  0 disk 
[root@zfs ~]# 
```

Создаём пул из двух дисков в режиме RAID 1 и ещё 3 пула:

```
[root@zfs ~]# zpool create otus1 mirror /dev/sdb /dev/sdc 
[root@zfs ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
[root@zfs ~]# zpool list -v
NAME        SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1       480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
  mirror    480M   106K   480M        -         -     0%  0.02%      -  ONLINE  
    sdb        -      -      -        -         -      -      -      -  ONLINE  
    sdc        -      -      -        -         -      -      -      -  ONLINE  
[root@zfs ~]# zpool create otus2 mirror /dev/sdd /dev/sde
[root@zfs ~]# zpool create otus3 mirror /dev/sdf /dev/sdg 
[root@zfs ~]# zpool create otus4 mirror /dev/sdh /dev/sdi
[root@zfs ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M  94.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
[root@zfs ~]# zpool list -v
NAME        SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1       480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
  mirror    480M   106K   480M        -         -     0%  0.02%      -  ONLINE  
    sdb        -      -      -        -         -      -      -      -  ONLINE  
    sdc        -      -      -        -         -      -      -      -  ONLINE  
otus2       480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
  mirror    480M  91.5K   480M        -         -     0%  0.01%      -  ONLINE  
    sdd        -      -      -        -         -      -      -      -  ONLINE  
    sde        -      -      -        -         -      -      -      -  ONLINE  
otus3       480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
  mirror    480M   106K   480M        -         -     0%  0.02%      -  ONLINE  
    sdf        -      -      -        -         -      -      -      -  ONLINE  
    sdg        -      -      -        -         -      -      -      -  ONLINE  
otus4       480M  94.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
  mirror    480M  94.5K   480M        -         -     0%  0.01%      -  ONLINE  
    sdh        -      -      -        -         -      -      -      -  ONLINE  
    sdi        -      -      -        -         -      -      -      -  ONLINE  
[root@zfs ~]# 
```
При создании сразу монтируются в корень:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/04-ZFS/screeshots/1_2.jpg?raw=true)


какие алгоритмы сжатия поддерживает zfs можно посмотреть в man:
```
     compression=on|off|gzip|gzip-N|lz4|lzjb|zle
       Controls the compression algorithm used for this dataset.
```
Добавим разные алгоритмы сжатия в каждую файловую систему:
```
[root@zfs ~]# zfs set compression=lzjb otus1
[root@zfs ~]# zfs set compression=lz4 otus2
[root@zfs ~]# zfs set compression=gzip-9 otus3
[root@zfs ~]# zfs set compression=zle otus4
```
Проверим, что все файловые системы имеют разные методы сжатия:

```
[root@zfs ~]# zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
[root@zfs ~]# 
```

Скачаем один и тот же текстовый файл во все пулы: 
```
[root@zfs ~]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
```

```
[root@zfs ~]# ls -l /otus*
/otus1:
total 22044
-rw-r--r--. 1 root root 40912739 Mar  2 09:17 pg2600.converter.log

/otus2:
total 17984
-rw-r--r--. 1 root root 40912739 Mar  2 09:17 pg2600.converter.log

/otus3:
total 10955
-rw-r--r--. 1 root root 40912739 Mar  2 09:17 pg2600.converter.log

/otus4:
total 39982
-rw-r--r--. 1 root root 40912739 Mar  2 09:17 pg2600.converter.log
[root@zfs ~]# 
```
Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов:

```
[root@zfs ~]# zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.6M   330M     21.6M  /otus1
otus2  17.7M   334M     17.6M  /otus2
otus3  10.8M   341M     10.7M  /otus3
otus4  39.2M   313M     39.1M  /otus4
[root@zfs ~]# 
```
```
[root@zfs ~]# zfs get all | grep compressratio | grep -v refotus1 
otus1  compressratio         1.81x                  -
otus1  refcompressratio      1.81x                  -
otus2  compressratio         2.22x                  -
otus2  refcompressratio      2.22x                  -
otus3  compressratio         3.65x                  -
otus3  refcompressratio      3.66x                  -
otus4  compressratio         1.00x                  -
otus4  refcompressratio      1.00x                  -
[root@zfs ~]# 
```
Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный по сжатию. 

**2. Определить настройки пула**

Скачиваем архив в домашний каталог: 
```
[root@zfs ~]# wget -O archive.tar.gz --no-check-certificate 'https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download'
```
Разархивируем его:

```
[root@zfs ~]# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
```
Проверим, возможно ли импортировать данный каталог в пул:
```
[root@zfs ~]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

	otus                         ONLINE
	  mirror-0                   ONLINE
	    /root/zpoolexport/filea  ONLINE
	    /root/zpoolexport/fileb  ONLINE
```
Данный вывод показывает нам имя пула, тип raid и его состав. 


Сделаем импорт данного пула к нам в ОС:
```
[root@zfs ~]# zpool import -d zpoolexport/ otus
[root@zfs ~]# zpool status
  pool: otus
 state: ONLINE
  scan: none requested
config:

	NAME                         STATE     READ WRITE CKSUM
	otus                         ONLINE       0     0     0
	  mirror-0                   ONLINE       0     0     0
	    /root/zpoolexport/filea  ONLINE       0     0     0
	    /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```
```
[root@zfs ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus    480M  2.09M   478M        -         -     0%     0%  1.00x    ONLINE  -
otus1   480M  21.7M   458M        -         -     0%     4%  1.00x    ONLINE  -
otus2   480M  17.7M   462M        -         -     0%     3%  1.00x    ONLINE  -
otus3   480M  10.8M   469M        -         -     0%     2%  1.00x    ONLINE  -
otus4   480M  39.2M   441M        -         -     0%     8%  1.00x    ONLINE  -
```
Запрос сразу всех параметром файловой системы:

```
[root@zfs ~]# zfs get all otus 
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              off                    default
otus  redundant_metadata    all                    default
otus  overlay               off                    default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
```
Уточняем параметры с помощью grep:

```
Размер:
[root@zfs ~]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -

Тип:
[root@zfs ~]# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default

Значение recordsize:
[root@zfs ~]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local

Тип сжатия:
[root@zfs ~]# zfs get compression otus
NAME  PROPERTY     VALUE     SOURCE
otus  compression  zle       local

Тип контрольной суммы:
[root@zfs ~]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
[root@zfs ~]# 
```
**3. Работа со снапшотом, поиск сообщения от преподавателя**

Скачаем файл:
```
wget -O otus_task2.file --no-check-certificate 'https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download'
```
Восстановим файловую систему из снапшота:

```
[root@zfs ~]# zfs receive otus/test@today < otus_task2.file
```
Ищем в каталоге /otus/test файл с именем “secret_message”:

```
[root@zfs ~]# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
[root@zfs ~]# 
```
Смотрим содержимое найденного файла:

```
[root@zfs ~]# cat /otus/test/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome
[root@zfs ~]# 
```

Для конфигурации сервера заносим в отдельный [Bash-скрипт](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/04-ZFS/zfs-install.sh) команды по установке и настройки ZFS и добавляем его в [Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/04-ZFS/Vagrantfile).

```
box.vm.provision "shell", path: "zfs-install.sh"
```
![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/04-ZFS/screeshots/1_3.jpg?raw=true)
