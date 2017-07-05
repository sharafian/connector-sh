FROM ubuntu:trusty
RUN apt-get update
RUN apt-get install -y bsdmainutils jq curl nginx

RUN mkdir -p /opt
WORKDIR /opt

COPY ./connector.sh connector.sh
COPY ./routing.txt routing.txt
COPY ./in.log in.log

CMD [ "/bin/bash", "connector.sh" ]
