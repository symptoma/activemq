#!/bin/sh

activemq_webadmin_username="admin"
activemq_webadmin_pw="admin"

## Modify jetty.xml

# WebConsole to listen on all addresses (beginning with 5.16.0, it listens on 127.0.0.1 by default, so is unreachable in Container)
# Bind to all addresses by default. Can be disabled setting ACTIVEMQ_WEBCONSOLE_USE_DEFAULT_ADDRESS=true
if [ ! "$ACTIVEMQ_WEBCONSOLE_USE_DEFAULT_ADDRESS" = "true" ]; then
  echo "Allowing WebConsole listen to 0.0.0.0"
  sed -i 's#<property name="host" value="127.0.0.1"/>#<property name="host" value="0.0.0.0"/>#' conf/jetty.xml
fi

if [ -n "$ACTIVEMQ_ADMIN_CONTEXTPATH" ]; then
  echo "Setting activemq admin contextPath to $ACTIVEMQ_ADMIN_CONTEXTPATH"
  sed -iv "s#<property name=\"contextPath\" value=\"/admin\" />#<property name=\"contextPath\" value=\"${ACTIVEMQ_ADMIN_CONTEXTPATH}\" />#" conf/jetty.xml
fi

if [ -n "$ACTIVEMQ_API_CONTEXTPATH" ]; then
  echo "Setting activemq API contextPath to $ACTIVEMQ_API_CONTEXTPATH"
  sed -iv "s#<property name=\"contextPath\" value=\"/api\" />#<property name=\"contextPath\" value=\"${ACTIVEMQ_API_CONTEXTPATH}\" />#" conf/jetty.xml
fi

if [ -n "$ACTIVEMQ_USERNAME" ]; then
  echo "Setting activemq username to $ACTIVEMQ_USERNAME"
  sed -i "s#activemq.username=system#activemq.username=$ACTIVEMQ_USERNAME#" conf/credentials.properties
fi

if [ -n "$ACTIVEMQ_PASSWORD" ]; then
  echo "Setting activemq password"
  sed -i "s#activemq.password=manager#activemq.password=$ACTIVEMQ_PASSWORD#" conf/credentials.properties
fi

if [ -n "$ACTIVEMQ_WEBADMIN_USERNAME" ]; then
  activemq_webadmin_username=$ACTIVEMQ_WEBADMIN_USERNAME
  has_modified_webadmin_username="username"
fi

if [ -n "$ACTIVEMQ_WEBADMIN_PASSWORD" ]; then
  activemq_webadmin_pw="$ACTIVEMQ_WEBADMIN_PASSWORD"
  has_modified_webadmin_pw=" and password"
fi

if [ -n "$ACTIVEMQ_WEBADMIN_USERNAME"  ] || [ -n "$ACTIVEMQ_WEBADMIN_PASSWORD" ]; then
    echo "Setting activemq WebConsole $has_modified_webadmin_username $has_modified_webadmin_pw"
    sed -i "s#admin: admin, admin#$activemq_webadmin_username: $activemq_webadmin_pw, admin#" conf/jetty-realm.properties
fi

# Start
bin/activemq console
