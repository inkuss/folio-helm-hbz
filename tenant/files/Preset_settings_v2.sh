#!/bin/bash

cd `dirname $0`

OKAPICLI="../OkapiCLI.py --url $OKAPI_URL --username $ADMIN_USERNAME --password $ADMIN_PASSWORD --tenant $TENANT"

# usage: post_code_setting 
post_email_setting () {
echo "email settings..."
smtpConfigId='id2db040b-3247-4b2b-8db4-5ef449e092ad'
JSON='{
    "host": "'$EMAIL_SMTP_HOST'",
    "port": '$EMAIL_SMTP_PORT',
    "username": "'$EMAIL_USERNAME'",
    "password": "'$EMAIL_PASSWORD'",
    "ssl": false,
    "trustAll": '$EMAIL_TRUST_ALL',
    "loginOption": "'$EMAIL_LOGIN_OPTION'",
    "startTlsOptions": "OPTIONAL",
    "from": "'$EMAIL_FROM'"
}'

echo "trying to post to /smtp-configuration:"
# echo $JSON
if ! echo "$JSON" | $OKAPICLI raw -m post -r "/smtp-configuration" ; then
  echo "seems to already exist, trying to get existing id..."
  id=`$OKAPICLI raw -r "/smtp-configuration" |jq .smtpConfigurations[0].id`
  echo "trying to put to /smtp-configuration/"$id
  if ! echo "$JSON" | $OKAPICLI raw -m put -r "/smtp-configuration/${id//\"/}" ; then
    echo "putting failed, exiting with code 1"
    exit 1
  fi
fi
}

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
echo "current smtp-configuration to check readyness:"
if $OKAPICLI -v raw -r "/smtp-configuration" ; then
  if [ "$EMAIL_SETUP" == "true" ] ; then
    post_email_setting
  fi
  post_code_setting USERSBL "Folio Host" FOLIO_HOST "$OKAPI_URL_INGRESS"
  post_setting ORG localeSettings "$FOLIO_LOCALE"
 
else
  exit 1
fi

