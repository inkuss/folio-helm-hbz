#!/bin/bash

# this script follows the method at https://github.com/folio-org/okapi/blob/master/doc/securing.md
# unchanged since 2019, check if something breaks

cd `dirname $0`

okapi_ready_check() {
  echo -ne "-- Checking if okapi is ready..."
  local returncode=`curl -s -w "%{http_code}" \
    -o /dev/null \
    ${OKAPI_URL}/_/discovery/modules`
  case "${returncode}" in
    200|201)
      echo "done"
      return 0
    ;;
  esac
  echo "ERROR, returncode ${returncode}"
  return 1
}

enable_module() {
  local MODULE=$1
  local JSON='{"id":"'${MODULE}'"}'
  echo "$JSON"
  echo "${OKAPI_URL}"
  echo -ne "-- Enabling Module ${MODULE} for superuser..."
  local result=$(echo "${JSON}" | curl -s \
    -w '|%{http_code}' \
    -X POST \
    -H 'Content-type: application/json' \
    "${OKAPI_URL}/_/proxy/tenants/supertenant/modules" \
    -d @- 2>&1 )
  case "${result##*|}" in
    200|201)
      echo "returncode: ${result##*|}, done"
      return 0
    ;;
    400)
      echo "returncode: ${result##*|}, ${MODULE} already provided?"
      echo "Response: ${result}"
      return 0
    ;;
  esac
  echo "ERROR, returncode: ${result##*|}"
  echo "Response: ${result}"
  return 1
}

post_to_okapi() {
  local APITARGET=$1
  local JSONFILE=$2
  # echo "-- Posting the following JSON settings to $APITARGET:"
  # cat $JSONFILE
  echo "-- Posting JSON settings to $APITARGET"
  local result=$(curl -s \
    -w '|%{http_code}' \
    -X POST \
    -H 'Content-type: application/json' \
    -H 'X-Okapi-Tenant:supertenant' \
    "${OKAPI_URL}${APITARGET}" \
    -d @$JSONFILE 2>&1 )
  local returncode=${result##*|}
  case "${returncode}" in
    200|201)
      echo "${returncode}, done"
      return 0
    ;;
    400)
      echo "returncode: ${returncode}, duplicate key?"
      echo "Response: "
      echo "${result}"
      echo "trying to continue..."
      return 0
    ;;
    422)
      echo "returncode: ${returncode}, already exists?"
      echo "Response: "
      echo "${result}"
      echo "trying to continue..."
      return 0
    ;;
  esac
  echo "ERROR, returncode: ${returncode}"
  echo "Response: "
  echo "${result}"
  return 1
}

main() {
  # Creating needed JSON as temporary files
  PERMSJSON=$(mktemp)
  cat > $PERMSJSON <<EOF
{ 
  "userId":"$USER_ID",
  "permissions":[ "okapi.all" ] 
}
EOF

  USERJSON=$(mktemp) 
  cat > $USERJSON <<EOF
{ 
  "id":"$USER_ID",
  "username":"superuser",
  "active":"true",
  "personal": {
     "lastName": "Superuser",
     "firstName": "Super"
  }
}
EOF

  LOGINJSON=$(mktemp)
  cat > $LOGINJSON <<EOF
{ 
  "username":"superuser",
  "password":"$SUPERUSER_PASSWORD" 
}
EOF


  echo "---- Trying to Secure Okapi..."
  okapi_ready_check \
  && enable_module "mod-permissions" \
  && post_to_okapi "/perms/users" $PERMSJSON\
  && enable_module "mod-users" \
  && post_to_okapi "/users" $USERJSON \
  && enable_module "mod-login" \
  && post_to_okapi "/authn/credentials" $LOGINJSON\
  && enable_module "mod-authtoken"
 
  return $?
}

main

