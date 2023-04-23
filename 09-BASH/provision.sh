#!/bin/bash

yum install epel-release -y
yum install mailx -y
yum install  postfix -y
sudo chmod a+x /vagrant/access-log-parse.sh
sudo echo "* * * * * root /vagrant/access-log-parse.sh" > /etc/crontab
systemctl reload crond

