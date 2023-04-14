#!/bin/bash

#Создадим шаблон
mv /usr/lib/systemd/system/httpd.service  /usr/lib/systemd/system/httpd@.service
cp /usr/lib/systemd/system/httpd@.service /tmp/httpd@service-bak
sed -i "s/EnvironmentFile=\/etc\/sysconfig\/httpd/EnvironmentFile=\/etc\/sysconfig\/httpd-%I/"  /usr/lib/systemd/system/httpd@.service

#В самом файле окружения (которых будет два) задается опция для запуска веб-сервера с необходимым конфигурационным файлом
cp /etc/sysconfig/httpd  /etc/sysconfig/httpd-first
mv /etc/sysconfig/httpd  /etc/sysconfig/httpd-second

sed -i "s/#OPTIONS=/OPTIONS=-f conf\/first.conf/"     /etc/sysconfig/httpd-first
sed -i "s/#OPTIONS=/OPTIONS=-f conf\/second.conf/"    /etc/sysconfig/httpd-second

# Соответственно в директории с конфигами httpd (/etc/httpd/conf) должны лежать два конфига, в нашем случае это будут first.conf и second.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf

#Для удачного запуска, в конфигурационных файлах должны быть указаны уникальные для каждого экземпляра опции Listen и PidFile
echo "PidFile /var/run/httpd-second.pid" >> /etc/httpd/conf/second.conf 
echo "PidFile /var/run/httpd-first.pid" >> /etc/httpd/conf/first.conf
sed -i "s/Listen 80/Listen 8080/"   /etc/httpd/conf/second.conf


#запускаем и проверяем
systemctl start httpd@first
systemctl start httpd@second

systemctl status httpd@first.service
systemctl status httpd@second.service 