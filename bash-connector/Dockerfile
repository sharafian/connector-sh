FROM ubuntu:trusty
RUN apt-get update
RUN apt-get install -y bsdmainutils jq curl nginx

RUN mkdir -p /opt
WORKDIR /opt

COPY ./connector.sh connector.sh
COPY ./routing.txt routing.txt
COPY ./in.log in.log

COPY ./default /etc/nginx/sites-enabled/default
COPY ./rpc /usr/share/nginx/html/rpc

COPY ./init.sh init.sh

EXPOSE 80
CMD [ "/bin/bash", "init.sh" ]
