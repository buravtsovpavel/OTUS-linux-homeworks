#!/bin/bash

#Устанавливаем spawn-fcgi и необходимые для него пакеты:
yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y

#раскомментируем строки с переменными в /etc/sysconfig/spawn-fcgi
sed -i 's/#SOCKET/SOCKET/' /etc/sysconfig/spawn-fcgi
sed -i 's/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi

#Создаём юнит
echo '[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target' >  /etc/systemd/system/spawn-fcgi.service


#запускаем и проверяем
systemctl daemon-reload
systemctl start spawn-fcgi
systemctl status spawn-fcgi