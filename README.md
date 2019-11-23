## Dockerfile to build a ActiveMQ container image.

Based on openjdk:8-jre-alpine, as lightweight as possible. 

Published on the Docker Hub: https://hub.docker.com/r/symptoma/activemq

## ActiveMQ version

Current version of ActiveMQ is **5.15.10**

## Build
```
docker build -t symptoma/activemq . 
```

## Run
```
docker run -it -p 61616:61616 8161:8161 symptoma/activemq:latest
```
Bind more ports if you need to.

## Publish

Each commit to master is automatically published to Docker Hub in the `latest` label. Tags are published in the corresponding versions.