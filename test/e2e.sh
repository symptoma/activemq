#!/bin/sh

set -eu

IMAGE=${1:-symptoma/activemq:6.3.2-test}
CONTAINER_NAME="activemq-base-e2e-$$"
BROKER_USER=broker-test
BROKER_PASSWORD=broker-test-password
WEB_USER=web-test
WEB_PASSWORD=web-test-password

cleanup() {
  docker rm --force "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

docker run --detach --name "$CONTAINER_NAME" \
  --publish 127.0.0.1::8161 \
  --env ACTIVEMQ_USERNAME="$BROKER_USER" \
  --env ACTIVEMQ_PASSWORD="$BROKER_PASSWORD" \
  --env ACTIVEMQ_WEBADMIN_USERNAME="$WEB_USER" \
  --env ACTIVEMQ_WEBADMIN_PASSWORD="$WEB_PASSWORD" \
  --env ACTIVEMQ_ADMIN_CONTEXTPATH=/console \
  --env ACTIVEMQ_API_CONTEXTPATH=/jmx \
  --env ACTIVEMQ_ENABLE_SCHEDULER=true \
  "$IMAGE" >/dev/null

attempt=1
while [ "$attempt" -le 60 ]; do
  if docker logs "$CONTAINER_NAME" 2>&1 \
    | grep -F 'Apache ActiveMQ 6.3.2' \
    | grep -Fq 'started'; then
    break
  fi
  if [ "$(docker inspect --format '{{.State.Running}}' "$CONTAINER_NAME")" != "true" ]; then
    docker logs "$CONTAINER_NAME"
    echo "ActiveMQ stopped before becoming ready" >&2
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep 1
done

if [ "$attempt" -gt 60 ]; then
  docker logs "$CONTAINER_NAME"
  echo "ActiveMQ did not become ready within 60 seconds" >&2
  exit 1
fi

docker exec "$CONTAINER_NAME" java -version 2>&1 | grep -Fq 'openjdk version "25'
docker exec "$CONTAINER_NAME" bin/activemq --version | grep -Fq 'ActiveMQ 6.3.2'
docker exec "$CONTAINER_NAME" grep -Fq 'schedulerSupport="true"' conf/activemq.xml
docker exec "$CONTAINER_NAME" grep -Fq '<jaasAuthenticationPlugin configuration="activemq" />' conf/activemq.xml

WEB_PORT=$(docker port "$CONTAINER_NAME" 8161/tcp | sed 's/.*://')
WEB_URL="http://127.0.0.1:$WEB_PORT"

status=$(curl --silent --output /dev/null --write-out '%{http_code}' "$WEB_URL/console/")
[ "$status" = "401" ]

curl --fail --silent --show-error --user "$WEB_USER:$WEB_PASSWORD" \
  "$WEB_URL/console/" >/dev/null
curl --fail --silent --show-error --user "$WEB_USER:$WEB_PASSWORD" \
  "$WEB_URL/jmx/jolokia/version" >/dev/null

status=$(curl --silent --output /dev/null --write-out '%{http_code}' \
  --user 'admin:admin' "$WEB_URL/console/")
[ "$status" = "401" ]

headers=$(curl --fail --silent --show-error --head \
  --user "$WEB_USER:$WEB_PASSWORD" "$WEB_URL/console/")
printf '%s\n' "$headers" | grep -Fiq 'X-Content-Type-Options: nosniff'
printf '%s\n' "$headers" | grep -Fiq 'Content-Security-Policy:'
printf '%s\n' "$headers" | grep -Fiq 'Cache-Control: no-store'
printf '%s\n' "$headers" | grep -Fiq 'Referrer-Policy: no-referrer'

docker exec "$CONTAINER_NAME" bin/activemq producer \
  --brokerUrl tcp://127.0.0.1:61616 \
  --user "$BROKER_USER" \
  --password "$BROKER_PASSWORD" \
  --destination queue://ACTIVEMQ.BASE.E2E \
  --messageCount 1 \
  --message activemq-base-e2e >/dev/null 2>&1
docker exec "$CONTAINER_NAME" timeout 30 bin/activemq consumer \
  --brokerUrl tcp://127.0.0.1:61616 \
  --user "$BROKER_USER" \
  --password "$BROKER_PASSWORD" \
  --destination queue://ACTIVEMQ.BASE.E2E \
  --messageCount 1 >/dev/null 2>&1

if docker exec "$CONTAINER_NAME" bin/activemq producer \
  --brokerUrl tcp://127.0.0.1:61616 \
  --user invalid \
  --password invalid \
  --destination queue://ACTIVEMQ.BASE.E2E \
  --messageCount 1 >/dev/null 2>&1; then
  echo "Broker accepted invalid credentials" >&2
  exit 1
fi

if docker run --rm --env ACTIVEMQ_USERNAME=incomplete "$IMAGE" >/dev/null 2>&1; then
  echo "Image accepted incomplete broker credentials" >&2
  exit 1
fi

if docker run --rm \
  --env ACTIVEMQ_USERNAME=shared-user \
  --env ACTIVEMQ_PASSWORD=broker-password \
  --env ACTIVEMQ_WEBADMIN_USERNAME=shared-user \
  --env ACTIVEMQ_WEBADMIN_PASSWORD=web-password \
  "$IMAGE" >/dev/null 2>&1; then
  echo "Image accepted conflicting passwords for a shared JAAS username" >&2
  exit 1
fi

echo "ActiveMQ 6.3.2 base image end-to-end test passed"
