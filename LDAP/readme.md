## Домашнее задание

Vagrant-стенд c LDAP на базе FreeIPA

#### Цель домашнего задания

Научиться настраивать LDAP-сервер и подключать к нему LDAP-клиентов

---


#### Описание домашнего задания

---


1) Установить FreeIPA
2) Написать Ansible-playbook для конфигурации клиента

Дополнительное задание
3)* Настроить аутентификацию по SSH-ключам
4)** Firewall должен быть включен на сервере и на клиенте


---

Для задания подготовлены [Vagrantfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LDAP/Vagrantfile) и [Ansible-playbook](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LDAP/ansible/provision.yml), который делает преднастройку FreeIPA сервера и клиентов, устанавливает FreeIPA-сервер и добавляет клиентские хосты к домену. 

После запуска виртуальных машин выпонения ansible-playbook командой `vagrant up` мы можем зайти в Web-интерфейс нашего FreeIPA-сервера:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LDAP/png/web%20int%20before.png)

Далее проверяем, что мы можем получить билет от Kerberos сервера: `kinit admin` и проверяем работу LDAP, для этого на сервере FreeIPA создадим пользователя и попробуем залогиниться к клиенту:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LDAP/png/create%20user_1.png)

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LDAP/png/web%20int%20after%203.png)

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/LDAP/png/ssh%20client1_2.png)
