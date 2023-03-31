## Dockerfile to build a ActiveMQ container image.

Based on [bellsoft/liberica-openjdk-alpine:17](https://hub.docker.com/r/bellsoft/liberica-openjdk-alpine), as lightweight as possible AND multiarch (Support for Apple M1 chip / aarch64 aka ARM64). 

Published on the Docker Hub: https://hub.docker.com/r/symptoma/activemq

## Usage

```
docker run -it -p 61616:61616 -p 8161:8161 symptoma/activemq:latest
```
Bind more ports if you need to.

Example with environment variables:
```
docker run -it \
-p 61616:61616 \
-p 8161:8161 \
-e ACTIVEMQ_DISALLOW_WEBCONSOLE=false \
-e ACTIVEMQ_USERNAME=myactivemquser \
-e ACTIVEMQ_PASSWORD=myactivemquserpass \
-e ACTIVEMQ_WEBADMIN_USERNAME=roos \
-e ACTIVEMQ_WEBADMIN_PASSWORD=TestTest \
symptoma/activemq:latest
```

## ActiveMQ version

Current version of ActiveMQ is **5.18.0**: https://archive.apache.org/dist/activemq/5.18.0/

Note: Since ActiveMQ 5.16.0 the Web Console is not reachable by default, as it only listens to 127.0.0.1 inside the container. See [AMQ-8018](https://issues.apache.org/jira/browse/AMQ-8018) for more details.

## Settings

You can define the following environment variables to control the behavior. 

| Environment Variable                    | Default | Description                                                                                                                                                                   |
|:----------------------------------------|:--------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ACTIVEMQ_USERNAME                       | system  | [Security](https://activemq.apache.org/security) (credentials.properties)                                                                                                     |
| ACTIVEMQ_PASSWORD                       | manager | [Security](https://activemq.apache.org/security) (credentials.properties)                                                                                                     |
| ACTIVEMQ_WEBADMIN_USERNAME              | admin   | [WebConsole](https://activemq.apache.org/security) (jetty-realm.properties)                                                                                                   |
| ACTIVEMQ_WEBADMIN_PASSWORD              | admin   | [WebConsole](https://activemq.apache.org/security) (jetty-realm.properties)                                                                                                   |
| ACTIVEMQ_WEBCONSOLE_USE_DEFAULT_ADDRESS | false   | Set default behavior of ActiveMQ Jetty listen address (127.0.0.1). By default, WebConsole listens on all addresses (0.0.0.0), so you can reach/map the WebConsole port (8161) |
| ACTIVEMQ_ADMIN_CONTEXTPATH              | /admin  | [WebConsole](https://github.com/apache/activemq/blob/main/assembly/src/release/conf/jetty.xml) Set contextPath of WebConsole (jetty.xml)                                      |
| ACTIVEMQ_API_CONTEXTPATH                | /api    | [API](https://github.com/apache/activemq/blob/main/assembly/src/release/conf/jetty.xml) Set contextPath of API (jetty.xml)                                                    |
| ACTIVEMQ_ENABLE_SCHEDULER               | false   | Enable the scheduler by setting `schedulerSupport` to `true` in `activemq.xml`|


## Exposed Ports

The following ports are exposed and can be bound:

| Port  | Description |
|:------|:------------|
| 1883  | MQTT        |
| 5672  | AMPQ        |
| 8161  | WebConsole  |
| 61613 | STOMP       |
| 61614 | WS          |
| 61616 | OpenWire    |

## Build

```
./build.sh
```

## Publish

First, commit your change to Git. 

`git commit -m "Update ActiveMQ to 5.18.0"`

Then tag it. 

`git tag -a v5.18.0 -m 'Release 5.18.0'`

Then push it to Github.

`git push && git push origin --tags`

Publishing manually works like this (after `docker login`):

```
docker tag <image> symptoma/activemq:5.18.0
docker push symptoma/activemq
```

## Multi Architecture Docker Build

Prepare the buildx context and use it:

* `BUILDER_NAME=$(docker buildx create) && docker buildx use $BUILDER_NAME`

Then build for multiple platforms:

* `docker buildx build --push --platform linux/arm64,linux/amd64 --tag symptoma/activemq:5.18.0 .`
* `docker buildx build --push --platform linux/arm64,linux/amd64 --tag symptoma/activemq:latest .`
