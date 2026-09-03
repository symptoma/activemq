#!/bin/sh

set -eu

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

validate_username() {
  case "$1" in
    ''|*[!A-Za-z0-9._@-]*)
      fail "ActiveMQ usernames may contain only letters, numbers, '.', '_', '@', and '-'"
      ;;
  esac
}

validate_context_path() {
  case "$1" in
    /|/*[!A-Za-z0-9._~/-]*|[!/]*)
      fail "Context paths must start with '/' and contain only URL path characters"
      ;;
  esac
}

escape_property_value() {
  printf '%s' "$1" | sed 's#\\#\\\\#g'
}

set_property() {
  file=$1
  key=$2
  value=$(escape_property_value "$3")
  AMQ_PROPERTY_KEY=$key AMQ_PROPERTY_VALUE=$value awk '
    index($0, ENVIRON["AMQ_PROPERTY_KEY"] "=") == 1 { next }
    { print }
    END { print ENVIRON["AMQ_PROPERTY_KEY"] "=" ENVIRON["AMQ_PROPERTY_VALUE"] }
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

delete_property() {
  file=$1
  key=$2
  AMQ_PROPERTY_KEY=$key awk '
    index($0, ENVIRON["AMQ_PROPERTY_KEY"] "=") != 1 { print }
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

add_group_member() {
  file=$1
  group=$2
  username=$3
  AMQ_GROUP=$group AMQ_USERNAME=$username awk '
    BEGIN { found = 0 }
    index($0, ENVIRON["AMQ_GROUP"] "=") == 1 {
      found = 1
      value = substr($0, length(ENVIRON["AMQ_GROUP"]) + 2)
      count = split(value, members, ",")
      present = 0
      for (i = 1; i <= count; i++) {
        candidate = members[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", candidate)
        if (candidate == ENVIRON["AMQ_USERNAME"]) present = 1
      }
      if (!present && value != "") value = value "," ENVIRON["AMQ_USERNAME"]
      if (!present && value == "") value = ENVIRON["AMQ_USERNAME"]
      print ENVIRON["AMQ_GROUP"] "=" value
      next
    }
    { print }
    END {
      if (!found) print ENVIRON["AMQ_GROUP"] "=" ENVIRON["AMQ_USERNAME"]
    }
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

remove_group_member() {
  file=$1
  group=$2
  username=$3
  AMQ_GROUP=$group AMQ_USERNAME=$username awk '
    index($0, ENVIRON["AMQ_GROUP"] "=") == 1 {
      value = substr($0, length(ENVIRON["AMQ_GROUP"]) + 2)
      count = split(value, members, ",")
      result = ""
      for (i = 1; i <= count; i++) {
        candidate = members[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", candidate)
        if (candidate != "" && candidate != ENVIRON["AMQ_USERNAME"]) {
          result = result (result == "" ? "" : ",") candidate
        }
      }
      print ENVIRON["AMQ_GROUP"] "=" result
      next
    }
    { print }
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

set_context_path() {
  old_path=$1
  new_path=$2
  validate_context_path "$new_path"
  echo "Setting ActiveMQ context path to $new_path"
  sed -i "s#<Set name=\"contextPath\">$old_path</Set>#<Set name=\"contextPath\">$new_path</Set>#" conf/jetty/jetty-webapps.xml
  sed -i "s#<Arg>$old_path/\\*</Arg>#<Arg>$new_path/*</Arg>#" conf/jetty/jetty-security.xml
  sed -i "s#<Set name=\"pattern\">$old_path/xml/\\*</Set>#<Set name=\"pattern\">$new_path/xml/*</Set>#" conf/jetty/jetty-security-headers.xml
}

webadmin_username=${ACTIVEMQ_WEBADMIN_USERNAME:-admin}
webadmin_password=${ACTIVEMQ_WEBADMIN_PASSWORD:-admin}

if [ ! "${ACTIVEMQ_WEBCONSOLE_USE_DEFAULT_ADDRESS:-false}" = "true" ]; then
  echo "Allowing the Web Console to listen on container interfaces"
  if ! grep -q '^jetty.http.host=0.0.0.0$' conf/jetty-spring.properties; then
    printf '\njetty.http.host=0.0.0.0\n' >> conf/jetty-spring.properties
  fi

  # Retain Jetty 12's IP filter while allowing requests forwarded by common
  # Docker and Kubernetes private networks.
  if ! grep -q '<Item>10.0.0.0/8</Item>' conf/jetty/jetty-security.xml; then
    sed -i '/<Item>::1<\/Item>/a\
              <Item>10.0.0.0/8</Item>\
              <Item>172.16.0.0/12</Item>\
              <Item>192.168.0.0/16</Item>' conf/jetty/jetty-security.xml
  fi
fi

if [ -n "${ACTIVEMQ_ADMIN_CONTEXTPATH:-}" ]; then
  set_context_path /admin "$ACTIVEMQ_ADMIN_CONTEXTPATH"
fi

if [ -n "${ACTIVEMQ_API_CONTEXTPATH:-}" ]; then
  set_context_path /api "$ACTIVEMQ_API_CONTEXTPATH"
fi

if [ -n "${ACTIVEMQ_WEBADMIN_USERNAME:-}" ] || [ -n "${ACTIVEMQ_WEBADMIN_PASSWORD:-}" ]; then
  validate_username "$webadmin_username"
  echo "Configuring the Web Console administrator"
  if [ "$webadmin_username" != "admin" ]; then
    delete_property conf/users.properties admin
    remove_group_member conf/groups.properties admins admin
  fi
  set_property conf/users.properties "$webadmin_username" "$webadmin_password"
  add_group_member conf/groups.properties admins "$webadmin_username"
fi

if { [ -n "${ACTIVEMQ_USERNAME:-}" ] && [ -z "${ACTIVEMQ_PASSWORD:-}" ]; } || \
   { [ -z "${ACTIVEMQ_USERNAME:-}" ] && [ -n "${ACTIVEMQ_PASSWORD:-}" ]; }; then
  fail "ACTIVEMQ_USERNAME and ACTIVEMQ_PASSWORD must be set together"
fi

if [ -n "${ACTIVEMQ_USERNAME:-}" ]; then
  validate_username "$ACTIVEMQ_USERNAME"
  if [ "$ACTIVEMQ_USERNAME" = "$webadmin_username" ] && \
     [ "$ACTIVEMQ_PASSWORD" != "$webadmin_password" ]; then
    fail "Broker and Web Console users with the same name must use the same password"
  fi

  echo "Enabling JAAS authentication for the broker"
  set_property conf/users.properties "$ACTIVEMQ_USERNAME" "$ACTIVEMQ_PASSWORD"
  add_group_member conf/groups.properties users "$ACTIVEMQ_USERNAME"
  add_group_member conf/groups.properties admins "$ACTIVEMQ_USERNAME"

  if ! grep -q 'configured by symptoma/activemq' conf/activemq.xml; then
    sed -i '/^[[:space:]]*<managementContext>/i\
        <!-- Broker authentication configured by symptoma/activemq. -->\
        <plugins>\
            <jaasAuthenticationPlugin configuration="activemq" />\
        </plugins>\
' conf/activemq.xml
  fi
fi

if [ "${ACTIVEMQ_ENABLE_SCHEDULER:-false}" = "true" ]; then
  echo "Enabling the scheduler"
  if ! grep -q 'schedulerSupport=' conf/activemq.xml; then
    sed -i '/^[[:space:]]*<broker xmlns=/s/>$/ schedulerSupport="true">/' conf/activemq.xml
  fi
fi

exec bin/activemq console
