#!/bin/bash

set -o pipefail

# read secret

FOLIO_VUFIND_USERNAME=`cat /foliousersecret/username`
FOLIO_VUFIND_PASSWORD=`cat /foliousersecret/password`
# set this for debugging: VERBOSE="-v"
VERBOSE=""

echo "Creating vudind user $FOLIO_VUFIND_USERNAME in Folio"

echo '{
  "username": "'$FOLIO_VUFIND_USERNAME'",
  "active": true,
  "type": "staff",
  "personal": {
    "lastName": "vufinduser",
    "email": "'$FOLIO_VUFIND_EMAIL'"
  }
}' | ./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --method post --rawpath /users

if [ "$?" != 0 ] ; then
  echo "Error creating vufind user. User already there? Continuing"
fi

echo "Getting id of created user"

FOLIO_VUFIND_USERID=`./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --rawpath "/users?query=username=$FOLIO_VUFIND_USERNAME" |jq -r .users[0].id`

if [ -z "$FOLIO_VUFIND_USERID" ] ; then
  echo "Error ferching vufind user id"
  sleep 3600
  exit 1
fi
echo "Userid: $FOLIO_VUFIND_USERID"

echo "Setting Password"

echo '{
    "userId": "'$FOLIO_VUFIND_USERID'",
    "password": "'$FOLIO_VUFIND_PASSWORD'"
}' | ./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --method post --rawpath "/authn/credentials"

if [ "$?" != 0 ] ; then
  echo "Error setting password. Already set? Continuing."
fi

PERMS='{
    "userId": "'$FOLIO_VUFIND_USERID'",
    "permissions": [
      "accounts.collection.get",
      "circulation.loans.collection.get",
      "circulation.renew-by-barcode.post",
      "circulation.renew-by-id.post",
      "circulation.requests.item.get",
      "circulation.requests.item.post",
      "circulation.requests.item.put",
      "circulation-storage.requests.collection.get",
      "inventory.instances.item.get",
      "inventory-storage.holdings.collection.get",
      "inventory-storage.holdings.item.get",
      "inventory-storage.instances.collection.get",
      "inventory-storage.items.collection.get",
      "inventory-storage.items.item.get",
      "inventory-storage.locations.collection.get",
      "inventory-storage.locations.item.get",
      "inventory-storage.service-points.collection.get",
      "inventory-storage.service-points.item.get",
      "manualblocks.collection.get",
      "usergroups.collection.get",
      "users.collection.get",
      "course-reserves-storage.courselistings.collection.get",
      "course-reserves-storage.courselistings.courses.collection.get",
      "course-reserves-storage.courselistings.instructors.collection.get",
      "course-reserves-storage.courselistings.item.get",
      "course-reserves-storage.courselistings.reserves.collection.get",
      "course-reserves-storage.courses.collection.get",
      "course-reserves-storage.departments.collection.get",
      "course-reserves-storage.reserves.collection.get",
      "proxiesfor.collection.get",
      "inventory-storage.loan-types.collection.get",
      "inventory-storage.loan-types.item.get",
      "circulation.requests.allowed-service-points.get"
      ]
    }'

echo "Getting PermissionId from UserId $FOLIO_VUFIND_USERID"
FOLIO_VUFIND_PERMID=`./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --rawpath "/perms/users?query=userId=$FOLIO_VUFIND_USERID" |jq -r .permissionUsers[0].id`

if [ "$FOLIO_VUFIND_PERMID" == "null" ] ; then
  echo "Error ferching vufind permission id, creating permissions."
  echo "Setting permissions for vufind user in folio. See https://vufind.org/wiki/configuration:ils:folio"
  echo $PERMS | ./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --method post --rawpath /perms/users

  if [ "$?" != 0 ] ; then
    echo "Error setting permissions."
    exit 1
  fi
else
  echo "PermissionId: $FOLIO_VUFIND_PERMID"
  echo "Updating permissions for vufind user in folio. See https://vufind.org/wiki/configuration:ils:folio"
  echo $PERMS | ./OkapiCLI.py $VERBOSE --url $OKAPI_URL --username $FOLIO_ADMIN_USERNAME --password $FOLIO_ADMIN_PASSWORD --tenant $FOLIO_TENANTID raw --method put --rawpath /perms/users/$FOLIO_VUFIND_PERMID
  if [ "$?" != 0 ] ; then
    echo "Error updating permissions."
    exit 1
  fi
fi


echo "done"
# Todo: check if all is set up correctly and exit 1 when not.
