### Цели домашнего задания

Настройка мониторинга

---
### Описание домашнего задания
Что нужно сделать:
Настроить дашборд с 4-мя графиками

  - память;
  - процессор;
  -  диск;
  -  сеть.

Настроить на одной из систем:
zabbix (использовать screen (комплексный экран);
prometheus - grafana.


**1. Настройка на Zabbix (Ubuntu 20.04)**

Ставим Zabbix-server

Для установки выбрана следующая конфигурация: Zabbix 6.0 LTS, Ubuntu 20.04, PostgreSQL, nginx


Устанавливаем PostgreSQL:
```
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-14
```
Устанавливаем репозиторий Zabbix:

```
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu20.04_all.deb
dpkg -i zabbix-release_6.0-4+ubuntu20.04_all.deb
apt update
```

Устанавливаем Zabbix сервер, веб-интерфейс и агент: 

```
apt install zabbix-server-pgsql zabbix-frontend-php php7.4-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
```

Создаём базу данных:
```
sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix 
```
На хосте Zabbix сервера импортируем начальную схему и данные. (вводим ранее созданный пароль):
```
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix 
```
Редактируем файл /etc/zabbix/zabbix_server.conf
```
DBPassword=12345
```
Запускаем процессы Zabbix сервера и агента и настраиваем их запуск при загрузке ОС:
```
sudo systemctl restart zabbix-server zabbix-agent nginx php7.4-fpm
sudo systemctl enable zabbix-server zabbix-agent nginx php7.4-fpm
``` 

Далее на агенте:

Устанавливаем репозиторий Zabbix:
```
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu20.04_all.deb
sudo dpkg -i zabbix-release_6.0-4+ubuntu20.04_all.deb
sudo apt update
```
Устанавливаем Zabbix агент
```
sudo  apt install zabbix-agent
```
Запускаем процесс Zabbix агента и настраиваем его запуск при загрузке ОС:
```
systemctl restart zabbix-agent
systemctl enable zabbix-agent 
```
В /etc/zabbix/zabbix_agentd.conf указываем параметры 

Server=192.168.11.170 
ServerActive=192.168.11.170 
Hostname=agent1

и добавляем агента в web-интерфейсе на сервере:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/Monitoring/screenshots/27.jpg)

теперь он добавился в hosts, сбор метрик пошёл.

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/Monitoring/screenshots/29.jpg)

и можно настроить свой дашборд:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/Monitoring/screenshots/28.jpg)

**2.Настройка на prometheus - grafana. CentOS 7**  

**Установка Prometheus**

* Устанавливаем вспомогательные пакеты и скачиваем Prometheus:
```
$ yum update -y
$ yum install wget vim -y
$ wget https://github.com/prometheus/prometheus/releases/download/v2.44.0/prometheus-2.44.0.linux-amd64.tar.gz
```
* Создаем пользователя и нужные каталоги, настраиваем для них владельцев
```
$ useradd --no-create-home --shell /bin/false prometheus
$ mkdir /etc/prometheus
$ mkdir /var/lib/prometheus
$ chown prometheus:prometheus /etc/prometheus
$ chown prometheus:prometheus /var/lib/prometheus
```
*  Распаковываем архив, для удобства переименовываем директорию и копируем бинарники в /usr/local/bin
```
$ tar -xvzf prometheus-2.44.0.linux-amd64.tar.gz
$ mv prometheus-2.44.0.linux-amd64 prometheuspackage
$ cp prometheuspackage/prometheus /usr/local/bin/
$ cp prometheuspackage/promtool /usr/local/bin/
```
* Меняем владельцев у бинарников:
```
$ chown prometheus:prometheus /usr/local/bin/prometheus
$ chown prometheus:prometheus /usr/local/bin/promtool
```
* По аналогии копируем библиотеки:
```
$ cp -r prometheuspackage/consoles /etc/prometheus
$ cp -r prometheuspackage/console_libraries /etc/prometheus
$ chown -R prometheus:prometheus /etc/prometheus/consoles
$ chown -R prometheus:prometheus /etc/prometheus/console_libraries
```
* Создаем файл [конфигурации](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/Monitoring/Prometheus/prometheus.yml) и меняем владельца
```
chown prometheus:prometheus /etc/prometheus/prometheus.yml
```
* Настраиваем [сервис](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/Monitoring/Prometheus/prometheus.service) и запускаем
```
systemctl daemon-reload
$ systemctl start prometheus
$ systemctl status prometheus
```

**Установка Node Exporter**
* Скачиваем и распаковываем Node Exporter
```
wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
tar xzfv node_exporter-1.5.0.linux-amd64.tar.gz
```
* Создаем пользователя, перемещаем бинарник в /usr/local/bin
```
useradd -rs /bin/false nodeusr
mv node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/
```
* Создаем [сервис](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/Monitoring/Prometheus/node_exporter.service) и запускаем

```
$ systemctl daemon-reload
$ systemctl start node_exporter
$ systemctl enable node_exporter
```
* Обновляем конфигурацию Prometheus и перезапускаем сервис(ссылка)
```
systemctl restart prometheus
```
**Ставим Grafana**
```
$ yum -y install grafana-enterprise-9.5.2-1.x86_64.rpm
# Стартуем сервис
$ systemctl daemon-reload
$ systemctl start grafana-server
```
* Далее интегрируем с Prometheus, импортируем готовый Dashboard или делаем свой

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/Monitoring/screenshots/32.jpg)

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/Monitoring/screenshots/18.jpg)

