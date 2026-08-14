FROM bellsoft/liberica-openjdk-alpine:17@sha256:d2c742e577821c70c97e06156fd089734105a99a73e6785205bb4fe4a02cb19b

LABEL maintainer="Thomas Lutz <lutz@symptoma.com>"

ENV ACTIVEMQ_VERSION=5.19.10
ENV ACTIVEMQ=apache-activemq-$ACTIVEMQ_VERSION
ENV ACTIVEMQ_HOME=/opt/activemq

RUN apk add --no-cache curl && \
    mkdir -p /opt && \
    mkdir -p /tmp/activemq-download && \
    cd /tmp/activemq-download && \
    curl --fail --silent --show-error --location \
      --output "$ACTIVEMQ-bin.tar.gz" \
      "https://archive.apache.org/dist/activemq/$ACTIVEMQ_VERSION/$ACTIVEMQ-bin.tar.gz" && \
    curl --fail --silent --show-error --location \
      --output "$ACTIVEMQ-bin.tar.gz.sha512" \
      "https://archive.apache.org/dist/activemq/$ACTIVEMQ_VERSION/$ACTIVEMQ-bin.tar.gz.sha512" && \
    sha512sum -c "$ACTIVEMQ-bin.tar.gz.sha512" && \
    tar -xzf "$ACTIVEMQ-bin.tar.gz" -C /opt && \
    rm -rf /tmp/activemq-download && \
    mv /opt/$ACTIVEMQ $ACTIVEMQ_HOME && \
    addgroup -S activemq && \
    adduser -S -H -G activemq -h $ACTIVEMQ_HOME activemq && \
    chown -R activemq:activemq $ACTIVEMQ_HOME && \
    chown -h activemq:activemq $ACTIVEMQ_HOME

EXPOSE 1883 5672 8161 61613 61614 61616

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

USER activemq
WORKDIR $ACTIVEMQ_HOME

ENTRYPOINT ["/entrypoint.sh"]
