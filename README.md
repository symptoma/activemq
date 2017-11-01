## Dockerfile to build a ActiveMQ container image.

Based on openjdk:8-jre-alpine, as lightweight as possible. 

## ActiveMQ version
Current version of ActiveMQ is **5.15.2**

## Build
```
docker build -t tdvorak/activemq . 
```

## Run
```
docker run -it -p 61616:61616 8161:8161 tdvorak/activemq:latest
```
Bind more ports if you need to. 