##Домашнее задание

**Vagrant-стенд c OSPF**

---
###Цель домашнего задания
Создать домашнюю сетевую лабораторию. Научится настраивать протокол OSPF в Linux-based системах.



---
**Описание домашнего задания**
1. Развернуть 3 виртуальные машины
2. Объединить их разными vlan
- настроить OSPF между машинами на базе Quagga;
- изобразить ассиметричный роутинг;
- сделать один из линков "дорогим", но что бы при этом роутинг был симметричным.

Формат сдачи: Vagrantfile + ansible


---

**1. Разворачиваем 3 виртуальные машины используя Vagrantfile.(ссылку вставить)** 

Результатом развёртывания будут 3 созданные виртуальные машины, которые соединены между собой сетями (10.0.10.0/30, 10.0.11.0/30 и 10.0.12.0/30). У каждого роутера есть дополнительная сеть:
на router1 — 192.168.10.0/24
на router2 — 192.168.20.0/24
на router3 — 192.168.30.0/24

(вставить картинку)

На данном этапе ping до дополнительных сетей (192.168.10-30.0/24) с соседних роутеров недоступен.

**2. Настраиваем OSPF между машинами на базе Quagga**

* В результате действий сделанных согласно методическому пособию получаем отредактированный файл файл /etc/frr/daemons (ссылку вставить), а также на каждом маршрутизаторе сконфигурированный файл файл /etc/frr/frr.conf (ссылку вставить) который будет содержать в себе информацию о требуемых интерфейсах и OSPF.
* проверяем, что владельцем файла является пользователь frr и при необходимости назначаем правильные права 
```
chown frr:frr /etc/frr/frr.conf 
chmod 640 /etc/frr/frr.conf
```
И теперь с любого хоста нам  доступны сети:

192.168.10.0/24
192.168.20.0/24
192.168.30.0/24
10.0.10.0/30 
10.0.11.0/30
10.0.12.0/30

Например с router1:
(вставляем пинги для примера)

Так же при отключении интерфейса enp0s9 сеть 192.168.30.0/24 нам остаётся доступна по другому маршруту:

(вставить скриншот tracer и vtsh)

**3. Настройка ассиметричного роутинга**

Выключаем блокировку ассиметричной маршрутизации: 
```
sysctl net.ipv4.conf.all.rp_filter=0
```
Меняем стоимость интерфейса enp0s8 на router1 и после внесения настроек, мы видим, что маршрут до сети 192.168.20.0/30  теперь пойдёт через router2, но обратный трафик от router2 пойдёт по другому пути:

```
root@router2:~# tcpdump -i enp0s9
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), capture size 262144 bytes
07:51:00.204458 IP 192.168.10.1 > router2: ICMP echo request, id 19, seq 23, length 64
07:51:01.051520 IP router2 > ospf-all.mcast.net: OSPFv2, Hello, length 48
07:51:01.208376 IP 192.168.10.1 > router2: ICMP echo request, id 19, seq 24, length 64
07:51:02.221750 IP 192.168.10.1 > router2: ICMP echo request, id 19, seq 25, length 64
07:51:03.231331 IP 192.168.10.1 > router2: ICMP echo request, id 19, seq 26, length 64
07:51:03.231976 IP 10.0.11.1 > ospf-all.mcast.net: OSPFv2, Hello, length 48
07:51:04.235667 IP 192.168.10.1 > router2: ICMP echo request, id 19, seq 27, length 64
```
```
root@router2:~# tcpdump -i enp0s8
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s8, link-type EN10MB (Ethernet), capture size 262144 bytes
07:53:34.209846 IP router2 > 192.168.10.1: ICMP echo reply, id 20, seq 10, length 64
07:53:35.232089 IP router2 > 192.168.10.1: ICMP echo reply, id 20, seq 11, length 64
07:53:36.238758 IP router2 > 192.168.10.1: ICMP echo reply, id 20, seq 12, length 64
07:53:37.246758 IP router2 > 192.168.10.1: ICMP echo reply, id 20, seq 13, length 64
07:53:37.809272 IP 10.0.10.1 > ospf-all.mcast.net: OSPFv2, Hello, length 48
07:53:38.250641 IP router2 > 192.168.10.1: ICMP echo reply, id 20, seq 14, length 64
```


**4. Настройка симметичного роутинга**

Так как у нас уже есть один «дорогой» интерфейс, нам потребуется добавить ещё один дорогой интерфейс, чтобы у нас перестала работать ассиметричная маршрутизация.  
Делаем интерфейс enp0s8 дорогим и далее проверяем, что теперь используется симметричная маршрутизация, т.е. трафик между роутерами ходит симметрично.

```
router2# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/1000] is directly connected, enp0s8, weight 1, 00:34:50
O   10.0.11.0/30 [110/100] is directly connected, enp0s9, weight 1, 03:28:32
O>* 10.0.12.0/30 [110/200] via 10.0.11.1, enp0s9, weight 1, 00:34:50
O>* 192.168.10.0/24 [110/300] via 10.0.11.1, enp0s9, weight 1, 00:34:50
O   192.168.20.0/24 [110/100] is directly connected, enp0s10, weight 1, 03:28:32
O>* 192.168.30.0/24 [110/200] via 10.0.11.1, enp0s9, weight 1, 03:25:42
router2# 
```
```
oot@router2:~# tcpdump -i enp0s9
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), capture size 262144 bytes
08:36:54.272934 IP router2 > ospf-all.mcast.net: OSPFv2, Hello, length 48
08:36:54.643982 IP 192.168.10.1 > router2: ICMP echo request, id 22, seq 22, length 64
08:36:54.644048 IP router2 > 192.168.10.1: ICMP echo reply, id 22, seq 22, length 64
08:36:55.090957 IP 10.0.11.1 > ospf-all.mcast.net: OSPFv2, Hello, length 48
08:36:55.661338 IP 192.168.10.1 > router2: ICMP echo request, id 22, seq 23, length 64
08:36:55.661453 IP router2 > 192.168.10.1: ICMP echo reply, id 22, seq 23, length 64
08:36:56.664912 IP 192.168.10.1 > router2: ICMP echo request, id 22, seq 24, length 64
```


Для развёртвания стенда подготовлен ansible playbook. 

Для переключения между ассиметричным и симметричным роутингом добавлена переменная symmetric_routing. С выставленным значением false в файле defaults/main.yml в шаблоне jinja2(ссылка) будут применены настройки для ассиметричного роутинга, с высталенныи заначением true - для симметричного.