#! /bin/bash

sudo su 

# устанавливаем пакет nfs-utils
yum install nfs-utils 

# включаем firewall и разрешаем в firewall доступ к сервисам NFS
systemctl enable firewalld --now 

firewall-cmd --add-service="nfs3" --permanent 
firewall-cmd --add-service="rpc-bind" --permanent 
firewall-cmd --add-service="mountd" --permanent 
firewall-cmd --reload

# включаем сервер NFS
systemctl enable nfs --now 

# создаём и настраиваем директорию, которая будет экспортирована в будущем
mkdir -p /srv/share/upload 
chown -R nfsnobody:nfsnobody /srv/share 
chmod 0777 /srv/share/upload 

# создаём в файле /etc/exports структуру, которая позволит экспортировать ранее созданную директорию 
cat << EOF > /etc/exports 
/srv/share 192.168.50.11/32(rw,sync,root_squash) 
EOF

# экспортируем ранее созданную директорию
exportfs -r 

systemctl restart nfs-server



