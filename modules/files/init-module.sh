#!/bin/bash

cd `dirname $0`

set -o pipefail -o noclobber

module_descriptor_file='/tmp/module-descriptor.json'
superusertoken=""

okapi_ready_check() {
  echo -ne "-- Checking if okapi is ready..."
  local returncode=`curl -s -w "%{http_code}" \
    -H "X-Okapi-Token: ${superusertoken}" \
    -o /dev/null \
    ${OKAPI_URL}/_/discovery/modules`;
  case "${returncode}" in
    200|201)
      echo "done"
      return 0
    ;;
  esac
  echo "ERROR, returncode ${returncode}"
  return 1
}

is_module_introduced() {
  echo -ne "-- testing whether module ${SERVICE_ID} is already introduced to ${OKAPI_URL} ...";
  result=`curl -s -w "|%{http_code}" \
    -H "X-Okapi-Token: ${superusertoken}" \
    -o /dev/null \
    "${OKAPI_URL}/_/proxy/modules/${SERVICE_ID}"`;

  case "${result##*|}" in
    200)
      echo "already introduced."
      return 0
      ;;
    404)
      echo "not found."
      return 1
      ;;
    *)
      echo "${result##*|} (${result%|*})"
      return 127
      ;;
  esac
}

fetch_module_descriptor() {
  echo -ne "-- Fetching module descriptor of ${SERVICE_ID}..."

  result=`curl -s -w "|%{http_code}" \
    -X GET \
    -H "Content-type: application/json" \
    "${FOLIO_REGISTRY}/_/proxy/modules/${MODULE}-${TAG}" \
    -o ${module_descriptor_file} 2>&1`;

  case "${result##*|}" in
    200|201)
      echo "done"
      return 0
      ;;
  esac


  echo "${result##*|} ("${result%|*}")"
  return 127
}

# introduces the module in okapi
introduce_module() {
  echo -ne "-- introducing module ${SERVICE_ID} to ${OKAPI_URL} ..."

  if [ ! -e "${module_descriptor_file}" ]; then
    echo "error. module_descriptor does not exist.";
    return 0;
  fi;
  echo "\n"
  cat $module_descriptor_file 
  result=`curl -s -w "|%{http_code}" \
    -X POST \
    -H "X-Okapi-Token: ${superusertoken}" \
    -H "Content-type: application/json" \
    "${OKAPI_URL}/_/proxy/modules" \
    -d @${module_descriptor_file} 2>&1`

  case "${result##*|}" in
    200|201)
      echo "done"
      return 0
      ;;
  esac

  echo "${result##*|} ("${result%|*}")"
  return 127
}

is_service_registered() {
  echo -ne "-- testing whether module ${SERVICE_ID} is already enabled in ${OKAPI_URL} ...";
  result=`curl -s -w "%{http_code}" \
    -H "X-Okapi-Token: ${superusertoken}" \
    -o /dev/null \
    "${OKAPI_URL}/_/discovery/modules/${SERVICE_ID}"`;

  case "${result##*|}" in
    200)
      echo "already enabled."
      return 0
      ;;
    404)
      echo "not found."
      return 1
      ;;
  esac
  echo "${result##*|} (${result%|*})"
  return 127
}

deregister_service() {
  echo -ne "-- removing module ${SERVICE_ID} from ${OKAPI_URL} ...";
  result=`curl \
    -s \
    -X DELETE \
    -w "%{http_code}" \
    -H "X-Okapi-Token: ${superusertoken}" \
    -o /dev/null \
    "${OKAPI_URL}/_/discovery/modules/${SERVICE_ID}"`;

  case "${result##*|}" in
    204)
      echo "done."
      return 0
      ;;
    *)
      echo "${result##*|} (${result%|*})"
      return 127
      ;;
  esac
}


register_service() {
  echo -ne "-- enabling module ${SERVICE_ID} to ${OKAPI_URL} ..."

  local enable_descriptor="{\"srvcId\":\"${SERVICE_ID}\",\"instId\":\"${INSTALL_ID}\",\"url\":\"${SERVICE_URL}\"}"
  echo $enable_descriptor
  result=`echo $enable_descriptor | curl -s -w "|%{http_code}" \
    -X POST \
    -H "Content-type: application/json" \
    -H "X-Okapi-Token: ${superusertoken}" \
    "$OKAPI_URL/_/discovery/modules" \
    -d @- 2>&1`

  case "${result##*|}" in
    200|201)
      echo "done"
      return 0
      ;;
  esac

  echo "${result##*|} ("${result%|*}")"
  return 127
}

deploy_module() {
  echo "--- deploying module ${SERVICE_ID} to ${OKAPI_URL} ..."
  is_module_introduced || ( fetch_module_descriptor && introduce_module )
  return $?
}

enable_service() {
  echo "--- enabling module ${SERVICE_ID} to ${OKAPI_URL} ..."
  is_service_registered && deregister_service
  register_service
  return $?
}

get_superuser_token() {
  echo "ping okapi...."
  sleep 1
  ping -c 1 okapi
  echo -ne "-- Getting superuser token..."
  local payload
  read -r -d '' payload <<EOF
{
  "username": "superuser",
  "password": "${SUPERUSER_PASSWORD}"
}
EOF
  result=`echo "${payload}" | curl -s -w "|%{http_code}" \
    -D - \
    -X POST  \
    -H "Content-type: application/json" \
    -H "X-Okapi-Tenant: supertenant" \
    "${OKAPI_URL}/authn/login" \
    -d@-`

    case "${result##*|}" in
      200|201)
        token=`echo "${result%|*}" | grep -i x-okapi-token`
        superusertoken=`expr "$token" : '[^:]\+:\s*\(.\+\)$'`
        echo "done."
        return 0
        ;;
    esac

  echo "failed: ${result##*|} (${result%|*})"
  echo "okapi still unsecured?"
  echo "continuing with empty superusertoken..."
  return 17
}

main() {
  get_superuser_token
  okapi_ready_check \
  && deploy_module \
  && enable_service
  return $?
}

main
