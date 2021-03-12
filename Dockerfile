FROM golang:1.15-alpine as builder

ENV CARBONAPI_VERSION=0.15.1
ENV GOPATH=/opt/go

RUN \
  apk update  --no-cache && \
  apk upgrade --no-cache && \
  apk add g++ git make musl-dev cairo-dev

WORKDIR ${GOPATH}

WORKDIR ${GOPATH}

RUN \
  export PATH="${PATH}:${GOPATH}/bin" && \
  mkdir -p \
    /var/log/carbonapi && \
  git clone https://github.com/go-graphite/carbonapi.git

WORKDIR ${GOPATH}/carbonapi

RUN \
  export PATH="${PATH}:${GOPATH}/bin" && \
  git checkout "tags/${CARBONAPI_VERSION}" 2> /dev/null ; \
  version=${CARBONAPI_VERSION} && \
  echo "build version: ${version}" && \
  make && \
  mv carbonapi /tmp/carbonapi

# ------------------------------ RUN IMAGE --------------------------------------
FROM alpine:3.13.2

COPY --from=builder /tmp/carbonapi                         /usr/bin/carbonapi

COPY conf/ /etc/carbonapi/
COPY entrypoint.sh /

RUN \
  apk update --no-cache && \
  apk upgrade --no-cache && \
  apk add    --no-cache --virtual .build-deps \
    cairo \
    shadow \
    tzdata \
    libc6-compat \
    ca-certificates \
  && /usr/sbin/useradd \
    --system \
    -U \
    -s /bin/false \
    -c "User for Graphite daemon" \
    carbon && \
  chmod +x /entrypoint.sh && \
  mkdir \
    /var/log/go-carbon && \
  chown -R carbon:carbon /var/log/go-carbon && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

WORKDIR /

ENV HOME /root

EXPOSE 8081

CMD ["/entrypoint.sh"]