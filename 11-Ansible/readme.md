# Цель домашнего задания
Подготовить стенд на Vagrant как минимум с одним сервером. На этом
сервере используя Ansible необходимо развернуть nginx со следующими
условиями:
- необходимо использовать модуль yum/apt
- конфигурационные файлы должны быть взяты из шаблона jinja2 с
переменными
- после установки nginx должен быть в режиме enabled в systemd
- должен быть использован notify для старта nginx после установки
- сайт должен слушать на нестандартном порту - 8080, для этого использовать
переменные в Ansible

\* Сделать все это с использованием Ansible роли



---
Для разнообразия в [стенд на Vagrant](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/11-Ansible/Vagrantfile) добавил 2 машины из разных семейств (Centos и Ubuntu) для группировки заданий в блоки.
[nginx_install.yml](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/11-Ansible/nginx_install.yml) разворачивает nginx используя yum/apt используя [конфигурационный файл из шаблона jinja2](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/11-Ansible/templates/nginx.conf.j2) и notify для старта nginx после установки.
После развёртывания сайт на обоих машинах слушается на нестандартном порту 8080.
[Роль](https://github.com/buravtsovpavel/OTUS-homeworks/tree/master/11-Ansible/roles/nginx_install), которая делает всё это.

```
buravtsovps@otus:~/work-dir/Ansible$ ansible all -i inventory.ini -m command -a "cat /etc/os-release"
vm2 | CHANGED | rc=0 >>
NAME="Ubuntu"
VERSION="20.04.5 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.5 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal
vm1 | CHANGED | rc=0 >>
NAME="CentOS Linux"
VERSION="7 (Core)"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="7"
PRETTY_NAME="CentOS Linux 7 (Core)"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:7"
HOME_URL="https://www.centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"

CENTOS_MANTISBT_PROJECT="CentOS-7"
CENTOS_MANTISBT_PROJECT_VERSION="7"
REDHAT_SUPPORT_PRODUCT="centos"
REDHAT_SUPPORT_PRODUCT_VERSION="7"
buravtsovps@otus:~/work-dir/Ansible$ 
```



```
buravtsovps@otus:~/work-dir/Ansible$ ansible-playbook nginx.yml 

PLAY [NGINX | Install and configure NGINX] ******************************************************************************************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************************************************************************************************************
ok: [vm1]
ok: [vm2]

TASK [nginx_install : Chek and print linux os_family] *******************************************************************************************************************************************************************************
ok: [vm1] => {
    "ansible_os_family": "RedHat"
}
ok: [vm2] => {
    "ansible_os_family": "Debian"
}

TASK [nginx_install : NGINX | Install EPEL Repo package from standart repo] *********************************************************************************************************************************************************
skipping: [vm2]
changed: [vm1]

TASK [nginx_install : NGINX | Install NGINX package from EPEL Repo] *****************************************************************************************************************************************************************
skipping: [vm2]
changed: [vm1]

TASK [nginx_install : Update Repository cache] **************************************************************************************************************************************************************************************
skipping: [vm1]
changed: [vm2]

TASK [nginx_install : NGINX | Install NGINX package] ********************************************************************************************************************************************************************************
skipping: [vm1]
changed: [vm2]

TASK [nginx_install : NGINX | Create NGINX config file from template] ***************************************************************************************************************************************************************
changed: [vm2]
changed: [vm1]

RUNNING HANDLER [nginx_install : restart nginx] *************************************************************************************************************************************************************************************
changed: [vm2]
changed: [vm1]

RUNNING HANDLER [nginx_install : reload nginx] **************************************************************************************************************************************************************************************
changed: [vm2]
changed: [vm1]

PLAY RECAP **************************************************************************************************************************************************************************************************************************
vm1                        : ok=7    changed=5    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0   
vm2                        : ok=7    changed=5    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0   

buravtsovps@otus:~/work-dir/Ansible$ 
```

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/11-Ansible/screenshots/1.png)


![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/11-Ansible/screenshots/2.png)



Примечание

При запуске vagrant up сценарий наполнения будет запущен только после запуска всех виртуальных машин. Vagrant по умолчанию использует разные ключи SSH для разных хостов, поэтому если требуется организовать параллельное выпонение сценария наполнения, необходимо настроить виртуальные машины так, что бы все они использовали один и тот же ключ ssh. Поэтому в для Vagrantfile дописываем строку config.ssh.insert_key = false. (и потом путь до этого приватного ключа нужно указать в [inventory.ini](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/11-Ansible/inventory.ini))
```
buravtsovps@otus:~/work-dir/Ansible$ vagrant ssh-config
Host vm1
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /home/buravtsovps/.vagrant.d/insecure_private_key
  IdentitiesOnly yes
  LogLevel FATAL

Host vm2
  HostName 127.0.0.1
  User vagrant
  Port 2200
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /home/buravtsovps/.vagrant.d/insecure_private_key
  IdentitiesOnly yes
  LogLevel FATAL

```



