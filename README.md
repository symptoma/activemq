# Dockerfile to build a ActiveMQ container image

Based on [bellsoft/liberica-openjdk-alpine:25](https://hub.docker.com/r/bellsoft/liberica-openjdk-alpine), as lightweight as possible and multi-architecture (including Apple Silicon / ARM64).

Published on the Docker Hub: <https://hub.docker.com/r/symptoma/activemq>

## Usage

```bash
docker run -it -p 61616:61616 -p 8161:8161 symptoma/activemq:latest
```

Bind more ports if you need to.

Example with environment variables:

```bash
docker run -it \
-p 61616:61616 \
-p 8161:8161 \
-e ACTIVEMQ_USERNAME=myactivemquser \
-e ACTIVEMQ_PASSWORD=myactivemquserpass \
-e ACTIVEMQ_WEBADMIN_USERNAME=roos \
-e ACTIVEMQ_WEBADMIN_PASSWORD=TestTest \
symptoma/activemq:latest
```

## ActiveMQ version

Current version of ActiveMQ is **6.3.2**: <https://activemq.apache.org/components/classic/download/classic-06-03-02>

ActiveMQ 6 uses Java 17 or later and a modular Jetty 12 configuration. This image uses Java 25, the Java version recommended by ActiveMQ when virtual threads are available.

## Settings

You can define the following environment variables to control the behavior.

| Environment Variable                    | Default | Description                                                                                                                                                                   |
| :-------------------------------------- | :------ | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ACTIVEMQ_USERNAME                       | unset   | Enables broker JAAS authentication when set together with `ACTIVEMQ_PASSWORD`                                                                                          |
| ACTIVEMQ_PASSWORD                       | unset   | Password for `ACTIVEMQ_USERNAME`                                                                                                                                       |
| ACTIVEMQ_WEBADMIN_USERNAME              | admin   | Web Console administrator in the shared JAAS user store                                                                                                                |
| ACTIVEMQ_WEBADMIN_PASSWORD              | admin   | Web Console administrator password                                                                                                                                     |
| ACTIVEMQ_WEBCONSOLE_USE_DEFAULT_ADDRESS | false   | Preserve the upstream Jetty bind address and loopback-only IP filter when `true`; otherwise listen on container interfaces and allow private container networks         |
| ACTIVEMQ_ADMIN_CONTEXTPATH              | /admin  | [Web Console](https://github.com/apache/activemq/blob/main/assembly/src/release/conf/jetty/jetty-webapps.xml) context path                                               |
| ACTIVEMQ_API_CONTEXTPATH                | /api    | [Jolokia API](https://github.com/apache/activemq/blob/main/assembly/src/release/conf/jetty/jetty-webapps.xml) context path                                               |
| ACTIVEMQ_ENABLE_SCHEDULER               | false   | Enable the scheduler by setting `schedulerSupport` to `true` in `activemq.xml`                                                                                          |

Broker authentication is disabled unless both broker credential variables are set. ActiveMQ 6 uses the same JAAS property files for broker and Web Console authentication. Broker and Web Console users may be different; if the same username is used for both, its passwords must also match.

## Exposed Ports

The following ports are exposed and can be bound:

| Port  | Description |
| :---- | :---------- |
| 1883  | MQTT        |
| 5672  | AMPQ        |
| 8161  | WebConsole  |
| 61613 | STOMP       |
| 61614 | WS          |
| 61616 | OpenWire    |

## Build

```bash
./build.sh
```

## Publish

First, commit your change to Git.

`git commit -m "Update ActiveMQ to 6.3.2"`

Then tag it.

`git tag -a v6.3.2 -m 'Release 6.3.2'`

Then push it to Github.

`git push && git push origin --tags`

Publishing manually works like this (after `docker login`):

```bash
docker tag <image> symptoma/activemq:6.3.2
docker push symptoma/activemq
```

## Multi Architecture Docker Build

Prepare the buildx context and use it:

* `BUILDER_NAME=$(docker buildx create) && docker buildx use $BUILDER_NAME`

Then build for multiple platforms:

* `docker buildx build --push --platform linux/arm64,linux/amd64 --tag symptoma/activemq:6.3.2 .`
* `docker buildx build --push --platform linux/arm64,linux/amd64 --tag symptoma/activemq:latest .`
