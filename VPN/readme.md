## Домашнее задание

**VPN**

---
**Описание домашнего задания**
1. Между двумя виртуалками поднять vpn в режимах:

- tun

- tap

Описать в чём разница, замерить скорость между виртуальными
машинами в туннелях, сделать вывод об отличающихся показателях
скорости.

2. Поднять RAS на базе OpenVPN с клиентскими сертификатами,
подключиться с локальной машины на виртуалку.

Формат сдачи: Vagrantfile + ansible


---

### 1. Между двумя виртуалками поднять vpn в режимах:

- tun

- tap

В результате запуска предподготовленного [Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/VPN/task1/Vagrantfile) поднимаются две виртуальные машины server и client. Для преднастройки написан [ansible-playbook](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/VPN/task1/tun_tap_server.yml). 
Для изменения режима работы (tun или tap) необходимо в конфигарационном файле
[сервера](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/VPN/task1/files/server.conf) и [клиента](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/VPN/task1/files/client.conf) изменять значение директивы dev и заново запустить провижинг:

```
vagrant provision
```
**Замеры скорости в туннеле для режима tap:**

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/VPN/png/tap_iperf.png)

**Замеры скорости в туннеле для режима tun:**

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/VPN/png/tun_iperf.png)

Видно незначительное увеличение объёма переданных данных в режиме tun.


В терминологии компьютерных сетей, TUN и TAP — виртуальные сетевые драйверы ядра системы. Они представляют собой программные сетевые устройства, которые отличаются от обычных аппаратных сетевых карт.

TAP эмулирует Ethernet-устройство и работает на канальном уровне модели OSI, оперируя кадрами Ethernet. TUN (сетевой туннель) работает на сетевом уровне модели OSI, оперируя IP-пакетами. TAP используется для создания сетевого моста, тогда как TUN — для маршрутизации. 

TAP:

Преимущества:
- ведёт себя как настоящий сетевой адаптер (за исключением того, что он виртуальный);
- может осуществлять транспорт любого сетевого протокола (IPv4, IPv6, IPX и прочих);
- работает на 2 уровне, поэтому может передавать Ethernet-кадры внутри тоннеля;
- позволяет использовать мосты.

Недостатки:
- в тоннель попадает broadcast-трафик, что иногда не требуется;
- добавляет свои заголовки поверх заголовков Ethernet на все пакеты, которые следуют через тоннель;
- в целом, менее масштабируем из-за предыдущих двух пунктов;
- не поддерживается устройствами Android и iOS.

TUN:

Преимущества:
- передает только пакеты протокола IP (3й уровень);
- сравнительно (отн. TAP) меньшие накладные расходы и, фактически, ходит только тот IP-трафик, который предназначен конкретному клиенту.

Недостатки:
- broadcast-трафик обычно не передаётся;
- нельзя использовать мосты.

### 2. Поднять RAS на базе OpenVPN с клиентскими сертификатами,

В результате запуска предподготовленного [Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/VPN/task2/Vagrantfile) поднимаются две виртуальные машины server и client. Для преднастройки написан [ansible-playbook](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/VPN/task2/ras.yml). 

Проверяем пинг по внутреннему IP адресу сервера в туннеле.

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/VPN/png/ping.png)


![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/VPN/png/netstat_ip_r.png)

