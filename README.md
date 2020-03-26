## Dockerfile to build a ActiveMQ container image.

Based on openjdk:8-jre-alpine, as lightweight as possible. 

Published on the Docker Hub: https://hub.docker.com/r/symptoma/activemq

## ActiveMQ version

Current version of ActiveMQ is **5.15.12**: https://activemq.apache.org/activemq-51512-release

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

First, commit your change to Git. 

`git commit -m "Update ActiveMQ to 5.15.12"`

Then tag it. 

`git tag -a v5.15.12 -m 'Release 5.15.12'`

Then push it to Github.

`git push && git push origin --tags`

Each commit to master is automatically published to Docker Hub in the `latest` label. Tags are published in the corresponding versions.

Publishing manually works like this (after `docker login`):

```
docker tag f1aa123a520f symptoma/activemq:5.15.12
docker push symptoma/activemq
```