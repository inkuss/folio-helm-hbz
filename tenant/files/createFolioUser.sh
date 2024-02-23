#!/bin/bash

set -o pipefail

# set this for debugging: VERBOSE="-v"
VERBOSE=""

OKAPICLI_TENANT="./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw"

echo "Creating user $USERNAME in Folio with the following JSON"

echo '{
  "username": "'$USERNAME'",
  "active": true,
  "type": "staff",
  "personal": {
    "lastName": "'$USERLASTNAME'",
    "phone": "'$USERPHONE'",
    "email": "'$USEREMAIL'"
  }
}' | ./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --method post --rawpath /users

if [ "$?" != 0 ] ; then
  echo "Error creating new user. User already there? Continuing"
fi

echo "Getting id of created user"

NEW_USERID=`./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --rawpath "/users?query=username=$USERNAME" |jq -r .users[0].id`

if [ -z "$NEW_USERID" ] ; then
  echo "Error ferching new user id"
  sleep 3600
  exit 1
fi
echo "Userid: $NEW_USERID"

echo "Setting Password"

echo '{
    "userId": "'$NEW_USERID'",
    "password": "'$NEW_PASSWORD'"
}' | ./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --method post --rawpath "/authn/credentials"

if [ "$?" != 0 ] ; then
  echo "Error setting password. Already set? Continuing."
fi

echo "Setting permissions for new user in folio.."
echo '{
  "userId": "'$NEW_USERID'",
  "permissions": [
    "perms.all"
  ]
}' | ./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --method post --rawpath /perms/users

if [ "$?" != 0 ] ; then
  echo "Error setting permissions. Already set?"
fi

echo "Getting $FOLIO_ADMIN_USERNAME Permission Id"
ADMIN_ID=$($OKAPICLI_TENANT --method get --rawpath "/users?query=(username==$FOLIO_ADMIN_USERNAME)" | jq -r '.users[0].id')
ADMIN_PERMID=$($OKAPICLI_TENANT --method get --rawpath "/perms/users?query=(userId==$ADMIN_ID)" | jq -r '.permissionUsers | .[].id')

echo "Getting Permissions Object for $FOLIO_ADMIN_USERNAME, user id: $ADMIN_ID, Permission Id: $ADMIN_PERMID"
ADMIN_PERMOBJ=$($OKAPICLI_TENANT --method get --rawpath "/perms/users/$ADMIN_PERMID" |  jq -c )

echo "Getting $USERNAME permission user id"
NEW_PERMID=$($OKAPICLI_TENANT --method get --rawpath "/perms/users?query=(userId==$NEW_USERID)" | jq -r '.permissionUsers | .[].id'  )
echo "Modifying Permission Object for $USERNAME, user id: $NEW_USERID, permission id: $NEW_PERMID"

echo "$ADMIN_PERMOBJ" | jq --arg newid $NEW_PERMID --arg newuserid $NEW_USERID -r 'del(.metadata) | .id=$newid | .userId=$newuserid' | $OKAPICLI_TENANT -m put -r /perms/users/$NEW_PERMID

echo "done"
# Todo: check if all is set up correctly and exit 1 when not.
