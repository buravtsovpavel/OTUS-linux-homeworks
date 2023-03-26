#! /bin/bash
sudo su

# устанавливаем пакет nfs-utils
yum install -y nfs-utils 

# включаем firewall 
systemctl enable firewalld --now 

#systemctl status firewalld 


systemctl enable nfs --now 
systemctl start nfs-server

# Добавляем монтирование
echo "192.168.56.10:/srv/share/ /mnt nfs _netdev,vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab

#mount 192.168.50.10:/srv/share/ /mnt

systemctl daemon-reload 
systemctl restart remote-fs.target 

