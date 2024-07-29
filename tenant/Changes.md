
Changes in 1.4.1:
* Updated okapicli version

Changes in 1.4.0:
* moved values:
  * tenants[].stripes.imageRepository to image.stripesBaseUrl with default image.imageBaseUrl
  * tenants[].stripes.imagePullPolicy to image.imagePullPolicy
  * tenants[].stripes.imageRepository to image.stripesImageRepository with default "stripes-build"
  * tenants[].stripes.imageTag to image.stripesTag with default AppVersion
  * global.image.* moved to image.*
  * moved global.image.pullsecret and tenants[].stripes.pullsecret to imagePullSecrets
  * global.okapi.* moved to okapi* and okapi url is determined automatically if not set.

