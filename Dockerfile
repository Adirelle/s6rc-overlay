FROM alpine

RUN apk update \
&&  apk add \
        bash \
        binutils \
        ca-certificates \
        gcc \
        make \
        musl-dev \
        wget

ADD /src /src/

WORKDIR /src
