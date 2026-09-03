FROM bellsoft/liberica-openjdk-alpine:25@sha256:b728c08690506dac4ed7150ab40f406236d43f487c51a72f375e817f02d7cbde

LABEL maintainer="Thomas Lutz <lutz@symptoma.com>"

ENV ACTIVEMQ_VERSION=6.3.2
ENV ACTIVEMQ=apache-activemq-$ACTIVEMQ_VERSION
ENV ACTIVEMQ_HOME=/opt/activemq

RUN apk upgrade --no-cache && \
    apk add --no-cache curl && \
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
    mkdir -p $ACTIVEMQ_HOME/tmp && \
    addgroup -S activemq && \
    adduser -S -H -G activemq -h $ACTIVEMQ_HOME activemq && \
    chown -R activemq:activemq $ACTIVEMQ_HOME && \
    chown -h activemq:activemq $ACTIVEMQ_HOME

EXPOSE 1883 5672 8161 61613 61614 61616

COPY entrypoint.sh /
COPY jetty-security-headers.xml $ACTIVEMQ_HOME/conf/jetty/
RUN chmod +x /entrypoint.sh && \
    chown activemq:activemq $ACTIVEMQ_HOME/conf/jetty/jetty-security-headers.xml && \
    sed -i 's#jetty-dos.xml$#jetty-dos.xml,jetty-security-headers.xml#' \
      $ACTIVEMQ_HOME/conf/jetty-spring.properties

USER activemq
WORKDIR $ACTIVEMQ_HOME

ENTRYPOINT ["/entrypoint.sh"]
