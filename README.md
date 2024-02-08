Kopiert aus bvb gitlab-Repo folio-public/folio-helm
# BVB/LRZ Folio/vufind Helm Repository


## Introduction


These Helm repositories and sample files are intended to enable an installation of Folio and vufind in a Kubernetes cluster


### Prerequisites and reference environment


The following is a brief description of the necessary prerequisites and how the environment was configured at the LRZ.

* Kubernetes Cluster - LRZ: Installation via kubespray, 3 smaller nodes as control planes, min. 4 large servers (128GB Ram) with local fast storage (2TB SSDs each)
* StorageClass - LRZ: Longhorn. Multiple configurations, depending on hard disk type and replication
* Ingress Controller - LRZ: nginx-ingress controller
* Load balancer - LRZ: metallb in layer 2 mode
* Firewall - LRZ: Checkpoint or pfsense. Must provide the ability to NAT to the metallb load balancer IPs
* certmanager or manually created certificates - LRZ: Jetstack certmanager with LetsEncrypt and Sectigo clusterissuern
* DNS - LRZ: manually set wildcard addresses *.folio.bib-bvb.de to the corresponding load balancer IPs
* S3 Storage - LRZ: minio - may be integrated into the Folio helmet chart in the future
* Container Registry - LRZ: gitlab CE, access may be granted for the images created by the LRZ, alternatively the LRZ plans to provide the images in Dockerhub.
* Zalando Postgres Operator or external DB - LRZ: Zalando Postgres Operator
* Solr Operator or external Solr (cloud) installation for vufind - LRZ: Solr Operator
* Minio Operator or other S3 access - LRZ: Minio Operator

And of course access to the Kubernetes cluster via kubectl and helm (installation on client/admin PC)


The following repo must be included for the installation:

    helm repo add bvb-repo https://gitlab.bib-bvb.de/api/v4/projects/128/packages/helm/stable


The following Helm repositories are also used for the above-mentioned components:

    helm repo list

    NAME URL                                                                         
    bitnami https://charts.bitnami.com/bitnami                                          
    longhorn https://charts.longhorn.io                                                  
    metallb https://metallb.github.io/metallb                                           
    jetstack https://charts.jetstack.io                                                  
    ingress-nginx https://kubernetes.github.io/ingress-nginx                     
    apache-solr https://solr.apache.org/charts                                              
    postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator                    
    bvb-repo https://gitlab.bib-bvb.de/api/v4/projects/128/packages/helm/stable
         


### Concept

* all applications come in one namespace:
  * Folio, vufind, Postgres, Kafka, Elasticsearch, Solr, Minio
* Operators for Postgres, Sor and Minio once per Kubernetes cluster
* Access from outside via firewall NAT to load balancer IP and further to ingress-controller and thus to the ingress.
* There are two ingresses for each Folio tenant: one for Stripes and one for Okapi
* vufind Deployment pro


## FOLIO installation


### Preparations


#### Kubernetes namespace


The other commands each require the specification of a Kubernetes namespace. This can only be set temporarily in the current shell, for example, so that the wrong namespace is not used later by mistake.

    FOLIONS=<NEW_NAMESPACE>
    kubectl create namespace ${FOLIONS:-undefined}
>>>>>>> 593a550 (Start moving to public repo)



Create/copy #### Secrets

Disclaimer: LRZ is trying to make their container registry public avalible. Stay tuned!

Two secrets are at the moment required to access the LRZ container registry and the central S3 store.

If there are already other folio installations in the cluster, you can copy some secrets:

    gitlab-folio-group 
    s3storage-access


Manually e.g. like this (cleaning up the yamls is necessary, see example in `other/gitlab.secret.example.yaml`, especially remove line `namespace:`):


    kubectl -n <source-namespace> get secret gitlab-folio-group -o yaml > other/gitlab-folio-group.secret.yaml
    vi other/gitlab-folio-group.secret.yaml
    kubectl -n ${FOLIONS:-undefined} apply -f other/gitlab-folio-group.secret.yaml


Or via script: `other/copy-secret.sh`

For a new secret (after creation in gitlab with registry-read authorization):


    kubectl -n ${FOLIONS:-undefined} create secret docker-registry gitlab-folio-group --docker-server=gitlab.bib-bvb.de:5050/folio --docker-username=k8s-read --docker-password=<token>


s3storage (e.g. per minio) must be available and the values in s3stroage-access must be adjusted accordingly.



#### adjust global-values.yaml


Settings that are relevant in several Helm repositories are made in the `global-values.yaml` file.

Database example: 

Required accounts are specified here in order to be created during the installation of Postgres. 

The same data is then used when installing Okapi and Folio modules.

This means that there is only one central location where the corresponding variables have to be set.




### Installation of basic components


#### Elasticsearch and Kafka from bitnami-repo

Once per client PC: add bitnami repo:


    helm repo add bitnami https://charts.bitnami.com/bitnami


Install Elasticsearch, the `NOTES.txt` output is saved with the following command under `logs/` and contains all important information:


    helm -n ${FOLIONS:-undefined} install elasticsearch bitnami/elasticsearch -f bitnami/elastic-values.yml


Important: check the output log to see under which internal service elasticsearch can be reached and compare it with the values of mod-search!

There have been changes here with bitnami chart upgrades in the past.


As with the last point, also install Kafka:


    helm -n ${FOLIONS:-undefined} install kafka bitnami/kafka -f bitnami/kafka-values.yml


Then wait until all pods are green in the dashboard.



#### postgres 


postgres is installed via the zalando-postgres-operator, more at `https://github.com/zalando/postgres-operator`


    helm -n ${FOLIONS:-undefined} install zal-pg bvb-repo/zalando-pg -f global-values.yaml




### Installation Folio components



#### okapi


On the topic of Docker containers and CI, see `https://gitlab.bib-bvb.de/folio/okapi`.


    helm -n ${FOLIONS:-undefined} install okapi bvb-repo/okapi -f global-values.yaiml



#### auth-modules

You need at least 2 value files to install the Folio modules:

- `<RELEASE_TAG>-auth.yaml` for the mod-users, mod-authtoken, mod-permissions and mod-login modules required for security.
- `<RELEASE_TAG>-no-auth.yaml>` for all other modules of a Folio release.


Additional modules can also be included in a separate Helm release.


For a new Folio release, the script `modules/script/update-helm-module-values.py` can be used.


The modules required for authentication are installed in a separate Helm release to avoid complications when upgrading:

    helm -n ${FOLIONS:-undefined} install mods-auth bvb-repo/modules -f global-values.yaml -f modules/valuesd/<RELEASE_TAG>-auth.yaml



#### secure supertenant


Use a script to supply Folio-supertenant with the modules required for authorization and secure it. The job is created via Helm template, no configuration should be necessary (with the same `global-values.yaml`).


    helm -n ${FOLIONS:-undefined} template secure bvb-repo/secure-supertenant -f global-values.yaml > secure-supertenant/renders/secure-supertenant.yaml

    kubectl -n ${FOLIONS:-undefined} apply -f secure-supertenant/renders/secure-supertenant.yaml



#### other modules


The remaining modules are installed sperately in the already secured system. 

This makes it relatively easy to add further modules to this installation using `helm upgrade` and to change the module settings.


    helm -n ${FOLIONS:-undefined} install mods bvb-repo/modules -f global-values.yaml -f modules/valuesd/<RELEASE_TAG>-no-auth.yaml --debug > logs/mods-install-${FOLIONS:-undefined}.yaml



#### create tenant and stripes deployment


Before installing the tenant, check that all modules are registered with Okapi. This should be the case if all init jobs from the previous step have been successfully completed.


- create new stripes branch in gitlab ( https://gitlab.bib-bvb.de/folio/platform-complete ) from branch with correct version (e.g. lotus-base) and adjust values:
  - under docker/Dockerfile set the ARGS to: OKAPI\_URL to desired ingress and TENANT\_ID
  - in `stripes.config.js` adjust logo/favicon and description. URL/tenant in this file are overwritten by the ARGS of the Dockerfile.
  - build docker image (manually on your own workstation and then push, or assign a git tag and push)
- Copy and adapt tenant/values-example.yaml, important: 
  - tenantId
  - stripes.imageVersion (to branch name)
  - the following 3 variables can be the same, and should match the ingress specified in the stripes Dockerfile:
    - ingress.host
    - ingress.tls.secretName
    - ingress.tls.host
- Install in new Helm release, with only one tenant its id can be used 


Command example:


    helm -n ${FOLIONS:-undefined} install <RELEASENAME> bvb-repo/tenant -f global-values.yaml -f tenant/values-<RELEASENAME>.yaml -f modules/valuesd/<RELEASE_TAG>-all.yaml --debug > tenant/install-debug-${FOLIONS:-undefined}.yml

    current example for lotus instances:

    helm -n folio-lotus install ubt bvb-repo/tenant -f global-values-lotus-h1.yaml -f tenant/values-lotus-ubt.yaml -f modules/valuesd/2022-r1-all-reduced.yaml



#### Notes for uninstalling

Use `helm -n ${FOLIONS:-undefined} list` to check installed releases


Use `helm -n ${FOLIONS:-undefined} uninstall <RELEASENAME>` to uninstall


Please note: 

- Persistent volume claims of Elasticsearch, Kafka and Kubegres are not deleted automatically, must be done manually.
- Secrets with Kubegres and Supertenant passwords are not deleted automatically and are reused when reinstalling. If this is not desired, uninstall manually or delete the namespace.



## Installation vufind


### Installation of basic components


#### Installation DB Cluster


Once per installation, a Postgres DB cluster should be created for all vufind instances/tenants. As with Folio, there is a Helm chart that creates a custom rosource for the Zalando Postgres operator. Installation:


    helm -n ${FOLIONS:-undefined} install vufind-postgres bvb-repo/zalando-vufind-pg -f values.yaml


For possible values in values.yaml see values.yaml in the chart. 


#### Installation Solr Cloud


Example values for the Solr Helm chart are provided in solr-vufind for the installation of the Solr cloud using the Solr cloud operator. It is important that the image from gitlab.bib-bvb.de:5050/vufind/vufind-ci/vufind is used for Solr. The extensions for vufind are included there.


Installation:


    helm -n ${FOLIONS:-undefined} install solr apache-solr/solr -f solr-vufind/solr-vufind.yaml


### Installation vufind

One vufind installation is made per tenant. The database is also created in the Postgres cluster in an init container. Solr is accessed via the shared index.


The connection to Folio is configured automatically (another todo), the tenant name must match a Folio tenant.


Installation (example tenant name bvb):


    helm -n ${FOLIONS:-undefined} install bvb-opac bvb-repo/vufind -f values.yaml


The tenant name must then be specified in values.yaml:

    global:
      foliotenant: "bvb"

To manage the configuration and the themes, there are two methods that retrieve the files from a network-accessible location:


* S3 Storage
* git repository


Both can be configured in the values.



### Special: Import data from B3Kat




