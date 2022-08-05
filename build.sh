#!/usr/bin/env bash

docker rmi symptoma/activemq
docker build -t symptoma/activemq .