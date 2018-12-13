## Dockerfile to build a ActiveMQ container image.

Based on openjdk:8-jre-alpine, as lightweight as possible. 

Published on the Docker Hub: https://hub.docker.com/r/tdvorak/activemq/

## ActiveMQ version
Current version of ActiveMQ is **5.15.8**

## Build
```
docker build -t tdvorak/activemq . 
```

## Run
```
docker run -it -p 61616:61616 8161:8161 tdvorak/activemq:latest
```
Bind more ports if you need to. 

## Publish

Get the latest image ID:

``` 
docker images
```

Use this ID to tag the image:

```
docker tag 30537052554f tdvorak/activemq:5.15.8

```

Push to the docker hub:

```
docker push tdvorak/activemq

```