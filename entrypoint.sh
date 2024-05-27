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

# Enable security by adding simpleAuthenticationPlugin
if [ -n "$ACTIVEMQ_USERNAME" ] && [ -n "$ACTIVEMQ_PASSWORD" ]; then
  echo "Enabling security by adding simpleAuthenticationPlugin to activemq.xml"
  if ! grep -q "<simpleAuthenticationPlugin>" conf/activemq.xml; then
    sed -i '/<\/broker>/i \
    <plugins>\
      <simpleAuthenticationPlugin>\
        <users>\
          <authenticationUser username="'"$ACTIVEMQ_USERNAME"'" password="'"$ACTIVEMQ_PASSWORD"'" groups="users,admins"/>\
        </users>\
      </simpleAuthenticationPlugin>\
    </plugins>' conf/activemq.xml
  fi
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

## Modify activemq.xml

if [ "$ACTIVEMQ_ENABLE_SCHEDULER" = "true" ]; then
  echo "Enabling the scheduler"
  sed -i 's#<broker xmlns="http://activemq.apache.org/schema/core" brokerName="localhost" dataDirectory="${activemq.data}">#<broker xmlns="http://activemq.apache.org/schema/core" brokerName="localhost" dataDirectory="${activemq.data}" schedulerSupport="true">#' conf/activemq.xml 
fi

# Start
bin/activemq console
