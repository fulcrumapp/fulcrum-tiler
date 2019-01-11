FROM starefossen/ruby-node:2-6-slim

RUN apt-get update \
    && apt-get install -y git gdal-bin \
    && git clone https://github.com/florianf/tileoven.git /tileoven

WORKDIR /tileoven

RUN npm install

COPY scripts/start.sh /tileoven/start.sh
COPY scripts /tileoven/scripts

RUN cd /tileoven/scripts && bundle install

EXPOSE 20008
EXPOSE 20009

ENTRYPOINT ["/bin/bash", "/tileoven/start.sh"]
