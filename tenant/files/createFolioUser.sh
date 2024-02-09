#!/bin/bash

set -o pipefail

# set this for debugging: VERBOSE="-v"
VERBOSE=""

echo "Creating user $USERNAME in Folio"

echo '{
  "username": "'$USERNAME'",
  "active": true,
  "type": "staff",
  "personal": {
    "lastName": "'$USERLASTNAME'",
    "phone": "'$USERPHONE'"
    "email": "'$USEREMAIL'"
  }
}' | ./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --method post --rawpath /users

if [ "$?" != 0 ] ; then
  echo "Error creating new user. User already there? Continuing"
fi

echo "Getting id of created user"

NEW_USERID=`./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --rawpath "/users?query=username=$NEW_USERNAME" |jq -r .users[0].id`

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

echo "done"
# Todo: check if all is set up correctly and exit 1 when not.
