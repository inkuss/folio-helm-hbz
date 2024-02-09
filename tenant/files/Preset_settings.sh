#!/bin/bash

cd `dirname $0`

OKAPICLI="../OkapiCLI.py --url $OKAPI_URL --username $ADMIN_USERNAME --password $ADMIN_PASSWORD --tenant $TENANT"

# usage: post_code_setting module config_name code value
post_code_setting () {
JSON='{
     "module": "'$1'",
     "configName": "'$2'",
     "code": "'$3'",
     "description": "Preset Settings",
     "default": true,
     "enabled": true,
     "value": "'${4}'"
}'

if ! echo "$JSON" | $OKAPICLI raw -m post -r "/configurations/entries" ; then
  # try update
  id=`$OKAPICLI raw -r "/configurations/entries?query=(module=$1 and code=$3)" |jq .configs[0].id`
  if ! echo "$JSON" | $OKAPICLI raw -m put -r "/configurations/entries/${id//\"/}" ; then
    exit 1
  fi
fi
}

# usage: post_setting module config_name value
post_setting () {
JSON='{
     "module": "'$1'",
     "configName": "'$2'",
     "description": "Preset Settings",
     "default": true,
     "enabled": true,
     "value": "'${3}'"
}'

if ! echo "$JSON" | $OKAPICLI raw -m post -r "/configurations/entries" ; then
  # try update
  id=`$OKAPICLI raw -r "/configurations/entries?query=(module=$1)" |jq .configs[0].id`
  if ! echo "$JSON" | $OKAPICLI raw -m put -r "/configurations/entries/${id//\"/}" ; then
    exit 1
  fi
fi
}


# check if we are ready
if $OKAPICLI -v raw -r "/configurations/entries" ; then
  if [ "$EMAIL_SETUP" == "true" ] ; then
    post_code_setting SMTP_SERVER smtp EMAIL_SMTP_PORT "$EMAIL_SMTP_PORT"
    post_code_setting SMTP_SERVER smtp EMAIL_LOGIN_OPTION "$EMAIL_LOGIN_OPTION"
    post_code_setting SMTP_SERVER smtp EMAIL_TRUST_ALL "$EMAIL_TRUST_ALL"
    post_code_setting SMTP_SERVER smtp EMAIL_USERNAME "$EMAIL_USERNAME"
    post_code_setting SMTP_SERVER smtp EMAIL_PASSWORD "$EMAIL_PASSWORD"
    post_code_setting SMTP_SERVER smtp EMAIL_SMTP_HOST "$EMAIL_SMTP_HOST"
    post_code_setting SMTP_SERVER smtp EMAIL_FROM "$EMAIL_FROM"
  fi
  post_code_setting USERSBL "Folio Host" FOLIO_HOST "$OKAPI_URL_INGRESS"
  post_setting ORG localeSettings "$FOLIO_LOCALE"
 
else
  exit 1
fi

