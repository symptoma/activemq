FROM bellsoft/liberica-openjdk-alpine:17

LABEL maintainer="Thomas Lutz <lutz@symptoma.com>"

ENV ACTIVEMQ_VERSION=5.18.6
ENV ACTIVEMQ=apache-activemq-$ACTIVEMQ_VERSION
ENV ACTIVEMQ_HOME=/opt/activemq

RUN apk add --update curl && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /opt && \
    curl -s -S https://archive.apache.org/dist/activemq/$ACTIVEMQ_VERSION/$ACTIVEMQ-bin.tar.gz | tar -xvz -C /opt && \
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
