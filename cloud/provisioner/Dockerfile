FROM ubuntu:14.04
MAINTAINER Simon Elliston Ball <simon@simonellistonball.com>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

RUN apt-get update
RUN apt-get -y install nginx sed python-pip python-dev uwsgi-plugin-python supervisor openssl

RUN mkdir -p /var/log/nginx/app
RUN mkdir -p /var/log/uwsgi/app/

RUN rm /etc/nginx/sites-enabled/default

COPY basic.conf /etc/nginx/conf.d/
COPY ssl.conf /etc/nginx/conf.d/

RUN ln -s /etc/nginx/sites-available/flask.conf /etc/nginx/sites-enabled/flask.conf
COPY uwsgi.ini /var/www/app/
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY flask.conf /etc/nginx/sites-available/
COPY app /var/www/app/
RUN pip install -r /var/www/app/requirements.txt

# Install jdk for the keytool
#RUN apt-add-repository ppa:webupd8team/java; apt-get update; apt-get install oracle-java8-installer; echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle > /etc/profile.d/java.sh"
COPY jdk-8u91-linux-x64.tar.gz /tmp/
RUN mkdir /usr/local/java; cd /usr/local/java; tar zxvf /tmp/jdk-8u91-linux-x64.tar.gz; rm /tmp/jdk-8u91-linux-x64.tar.gz;  echo "export JAVA_HOME=/usr/local/java/jdk1.8.0_91/ > /etc/profile.d/java.sh"

EXPOSE 443

VOLUME ["/etc/nginx/certs/", "/data"]

CMD ["/usr/bin/supervisord"]
