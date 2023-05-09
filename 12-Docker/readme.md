# Цель домашнего задания
1. Написать Dockerfile на базе apache/nginx который будет содержать две статичные web-страницы
на разных портах. Например, 80 и 3000.
2. Пробросить эти порты на хост машину. Обе страницы должны быть доступны по адресам
localhost:80 и localhost:3000
3. Добавить 2 вольюма. Один для логов приложения, другой для web-страниц.

Доп.*
1. Написать Docker-compose для приложения Redmine, с использованием опции build.
2. Добавить в базовый образ redmine любую кастомную тему оформления.
3. Убедиться что после сборки новая тема доступна в настройках.



---

С помощью [vagrant](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/12-Docker/Vagrantfile) поднимаем виртуальную машину и ствим на ней docker
```
[vagrant@docker ~]$ docker --version
Docker version 23.0.5, build bc4487a
[vagrant@docker ~]$ 
```

В директории проекта создаём [Dockerfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/12-Docker/Dockerfile) , статические страницы [index80.html](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/12-Docker/index80.html) [index3000.html](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/12-Docker/index3000.html) и откорректированный файл конфига nginx [default.conf](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/12-Docker/default.conf)
```
[vagrant@docker docker_ver2]$ tree
.
|-- Dockerfile
|-- default.conf
|-- index3000.html
`-- index80.html

0 directories, 4 files
[vagrant@docker docker_ver2]$ 
```
Запускаем сборку image'а

```
[vagrant@docker docker_ver2]$ docker build -t nginx_ver1 .
[+] Building 1.6s (8/8) FINISHED                                                                                 
 => [internal] load .dockerignore                                                                           0.0s
 => => transferring context: 2B                                                                             0.0s
 => [internal] load build definition from Dockerfile                                                        0.0s
 => => transferring dockerfile: 382B                                                                        0.0s
 => [internal] load metadata for docker.io/library/nginx:latest                                             1.5s
 => [internal] load build context                                                                           0.0s
 => => transferring context: 277B                                                                           0.0s
 => [1/3] FROM docker.io/library/nginx:latest@sha256:480868e8c8c797794257e2abd88d0f9a8809b2fe956cbfbc05dcc  0.0s
 => => resolve docker.io/library/nginx:latest@sha256:480868e8c8c797794257e2abd88d0f9a8809b2fe956cbfbc05dcc  0.0s
 => CACHED [2/3] ADD ./index* /usr/share/nginx/html                                                         0.0s
 => CACHED [3/3] ADD ./default.conf /etc/nginx/conf.d                                                       0.0s
 => exporting to image                                                                                      0.0s
 => => exporting layers                                                                                     0.0s
 => => writing image sha256:d0d17c7ce6a5e9cb9d1061809781ba10fe07afbdf45c358aa86454bf881d6b43                0.0s
 => => naming to docker.io/library/nginx_ver1                                                               0.0s
[vagrant@docker docker_ver2]$ 

```
```
[vagrant@docker docker_ver2]$ docker images
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
nginx_ver1   latest    d0d17c7ce6a5   20 hours ago   142MB
[vagrant@docker docker_ver2]$ 
```


Запускаем контенер пробросив два порта и два вольюма:
```
[vagrant@docker docker_ver2]$ docker run --name nginx_ver1 -td -p 80:80 -p 3000:3000   -v /home/vagrant/logs:/var/log/nginx -v /home/vagrant/docker_ver2:/usr/share/nginx/html  nginx_ver1 
381e7cce7b86c20bf7b477df7cb31491c3c02df36e82bef29ebeb602fb3b74ae

```

```
[vagrant@docker docker_ver2]$ docker ps
CONTAINER ID   IMAGE        COMMAND                  CREATED          STATUS          PORTS                                                                          NAMES
381e7cce7b86   nginx_ver1   "/docker-entrypoint.…"   29 seconds ago   Up 27 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp, 0.0.0.0:3000->3000/tcp, :::3000->3000/tcp   nginx_ver1
[vagrant@docker docker_ver2]$ 

```
После старта контейнера страницы доступны на разных портах в браузере на хостовой машине 192.168.11.155:80 192.168.11.155:3000(или можно курлануть на виртуалке loclhost:80 и localhost:3000)


![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/12-Docker/screenshots/1.png)

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/12-Docker/screenshots/2.png)



## Доп.*

Ставим docker-compose

```
[vagrant@docker ~]$ sudo curl -L "https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100 51.9M  100 51.9M    0     0  5292k      0  0:00:10  0:00:10 --:--:-- 4760k
[vagrant@docker ~]$ 
```
```
[vagrant@docker ~]$ sudo chmod +x /usr/local/bin/docker-compose
[vagrant@docker ~]$ sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
[vagrant@docker ~]$ 
```

```
[vagrant@docker ~]$ docker-compose version
Docker Compose version v2.17.3
[vagrant@docker ~]$ 

```

[docker-compose.yml](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/12-Docker/Redmine/docker-compose.yml) (опция build — указание на необходимость сборки из [Dockerfile](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/12-Docker/Redmine/Dockerfile)) для приложения Redmine, который добавляет в базовый образ redmine RTMaterial тему оформления.

Запускаем сборку docker-compose.yml 
```
docker-compose up
```
```
[vagrant@docker Redmine]$ docker images
REPOSITORY        TAG       IMAGE ID       CREATED             SIZE
redmine-redmine   latest    c72b4f504bea   About an hour ago   611MB
mysql             5.7       dd6675b5cfea   3 weeks ago         569MB
[vagrant@docker Redmine]$ 
```

```
[vagrant@docker Redmine]$ docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED          STATUS          PORTS                                       NAMES
e1c4a13fc6de   redmine-redmine   "/docker-entrypoint.…"   49 minutes ago   Up 48 minutes   0.0.0.0:8080->3000/tcp, :::8080->3000/tcp   redmine-redmine-1
960d8f5cd23d   mysql:5.7         "docker-entrypoint.s…"   49 minutes ago   Up 49 minutes   3306/tcp, 33060/tcp                         redmine-db-1
```
Новая тема доступна в настройках для применения и применяется:

![](https://github.com/buravtsovpavel/OTUS-homeworks/blob/master/12-Docker/screenshots/3.png)
