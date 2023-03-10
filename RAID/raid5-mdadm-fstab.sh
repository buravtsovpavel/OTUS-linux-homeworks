#!/bin/bash
# Собирает RAID5, создаёт конфигурационный файл mdadm.conf, GPT раздел, пять партиций и
# монтирует их на диск и делает запись в fstab, что бы после перезагрузки стенда разделы автоматически примонтировались.
 
#зануляем суперблоки и создаём raid
sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
sudo mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}

# создаём конфигурационный файл mdadm.conf
sudo mkdir /etc/mdadm
echo "DEVICE partitions" | sudo tee /etc/mdadm/mdadm.conf
sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' | sudo tee -a /etc/mdadm/mdadm.conf

#создаём gpt раздел, 5 партиций, фс ext4 на них и монтируем их
sudo parted -s /dev/md0 mklabel gpt
sudo parted /dev/md0 mkpart primary ext4 0% 20%
sudo parted /dev/md0 mkpart primary ext4 20% 40%
sudo parted /dev/md0 mkpart primary ext4 40% 60%
sudo parted /dev/md0 mkpart primary ext4 60% 80%
sudo parted /dev/md0 mkpart primary ext4 80% 100%

for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
sudo mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do sudo  mount /dev/md0p$i /raid/part$i; done

#делаем запись в fstab
for i in $(seq 1 5); do echo "/dev/md0p$i /raid/part$i ext4    defaults    1 2" | sudo tee -a /etc/fstab; done
