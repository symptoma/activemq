## Dockerfile to build a ActiveMQ container image.

Based on [bellsoft/liberica-openjdk-alpine:13](https://hub.docker.com/r/bellsoft/liberica-openjdk-alpine), as lightweight as possible AND multiarch (Support for Apple M1 chip / aarch64 aka ARM64). 

Published on the Docker Hub: https://hub.docker.com/r/symptoma/activemq

## ActiveMQ version

Current version of ActiveMQ is **5.17.1**: https://archive.apache.org/dist/activemq/5.17.1/

Note: Since 5.16.0 the Web Console is not reachable by default, as it only listens to 127.0.0.1 inside the container. See [AMQ-8018](https://issues.apache.org/jira/browse/AMQ-8018) for more details.

## Build
```
docker build -t symptoma/activemq .
```

## Run
```
docker run -it -p 61616:61616 -p 8161:8161 symptoma/activemq:latest
```
Bind more ports if you need to.

## Publish

First, commit your change to Git. 

`git commit -m "Update ActiveMQ to 5.17.1"`

Then tag it. 

`git tag -a v5.17.1 -m 'Release 5.17.1'`

Then push it to Github.

`git push && git push origin --tags`

Each commit to master is automatically published to Docker Hub in the `latest` label. Tags are published in the corresponding versions.

Publishing manually works like this (after `docker login`):

```
docker tag f1aa123a520f symptoma/activemq:5.17.1
docker push symptoma/activemq
```

## Multi Architecture Docker Build

Prepare the buildx context and use it:

* `docker buildx create`
* `docker buildx use <name>`

Then build for multiple platforms:

* `docker buildx build --push --platform linux/arm,linux/arm64,linux/amd64 --tag symptoma/activemq:5.17.1 .`
* `docker buildx build --push --platform linux/arm,linux/arm64,linux/amd64 --tag symptoma/activemq:latest .`