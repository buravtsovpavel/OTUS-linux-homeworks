FROM nginx:latest
MAINTAINER buravtsovps
LABEL version="1.0"

ADD ./index* /usr/share/nginx/html

ADD ./default.conf /etc/nginx/conf.d

EXPOSE 80/tcp
EXPOSE 3000/tcp

VOLUME /var/log/nginx
VOLUME /usr/share/nginx/html

CMD ["nginx", "-g", "daemon off;"]
