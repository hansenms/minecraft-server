FROM ubuntu:20.04

ARG BEDROCKVERSION="1.14.60.5"
RUN echo "https://minecraft.azureedge.net/bin-linux/bedrock-server-${BEDROCKVERSION}.zip"

RUN apt-get update && apt-get -y install wget unzip curl screen rsync

RUN wget -q -O /tmp/bds.zip "https://minecraft.azureedge.net/bin-linux/bedrock-server-${BEDROCKVERSION}.zip"

WORKDIR /data

RUN mkdir mkdir -p /opt/bedrock
RUN mkdir -p /backups
COPY *.sh /opt/bedrock/
RUN chmod +x /opt/bedrock/*.sh

ENTRYPOINT ["/opt/bedrock/entrypoint.sh"]