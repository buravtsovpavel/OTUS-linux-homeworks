#!/bin/bash


#создаём файл с конфигурацией для сервиса

echo '# Configuration file for my watchlog service
# Place it to /etc/sysconfig

# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log' > /etc/sysconfig/watchlog


# создаем /var/log/watchlog.log который будем мониторить на наличие ключевого слова

cp /var/log/secure /var/log/watchlog.log
echo ALERT >> /var/log/watchlog.log 

# cоздаём скрипт
echo '#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi' > /opt/watchlog.sh


# добавляем права на запуск файла
chmod +x /opt/watchlog.sh

# cоздаём юнит для сервиса
echo '[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG' > /etc/systemd/system/watchlog.service


# создаём юнит для таймера
echo '[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
AccuracySec=1s
Unit=watchlog.service

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/watchlog.timer


# перечитываем файлы юнитов после изменений, стартуем timer и смотрим результат

systemctl daemon-reload
systemctl start watchlog.timer
systemctl start watchlog.service
#tail -f /var/log/messages






