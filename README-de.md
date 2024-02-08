# BVB/LRZ Folio/vufind Helm Repository

## Einführung

Diese Helm Repositories und Beispieldateien sollen eine Installation von Folio und vufind in einem Kubernetes Cluster ermöglichen

### Voraussetzungen und Referenzumgebung

Im folgenden wird stichpunktartig beschrieben, welche Voraussetungen notwendig sind, und wie die Umgebung im LRZ konkret konfiguriert wurde.

* Kubernetes Cluster - LRZ: Installation per kubespray, 3 kleinere Nodes als control planes, min. 4 große Server (128GB Ram) mit lokalem schnellen Speicher (je 2TB SSDs)
* StorageClass - LRZ: Longhorn. Mehrere konfigurationen, je nach Festplattentyp und Replikation
* Ingress Controller - LRZ: nginx-ingress controller
* Loadbalancer - LRZ: metallb im Layer 2 mode
* Firewall - LRZ: Checkpoint oder pfsense. Muss die Möglichkeit bereitstellen, auf die metallb Loadbalancer IPs zu NATen
* certmanager oder manuell erstellte Zertifikate - LRZ: Jetstack certmanager mit LetsEncrypt und Sectigo clusterissuern
* DNS - LRZ: manuell eingestellt werden Wildcard Adressen *.folio.bib-bvb.de auf die entsprechenden Loadbalancer IPs
* S3 Storage - LRZ: minio - wird künftig evtl in das Folio helm chart integriert
* Container Registry - LRZ: gitlab CE, für die vom LRZ erzeugten Images kann evtl. Zugriff gewährt werden, alterativ plant das LRZ die Images in Dockerhub bereit zu stellen.
* Zalando Postgres Operator oder externe DB - LRZ: Zalando Postgres Operator
* Solr Operator oder externe Solr (cloud) Installation für vufind - LRZ: Solr Operator 
* Minio Operator oder anderer S3 Zugriff - LRZ: Minio Operator

Und natürlich Zugriff auf den Kubernetes Cluster per kubectl und helm (Installation auf client/admin PC)

Für die Installation muss folgendes Repo eingebunden werden:

    helm repo add --username helm-readonly --password XXXXXXXXXXXX bvb-repo https://gitlab.bib-bvb.de/api/v4/projects/59/packages/helm/stable

Für die o.g. Komponenten werden auch noch folgende Helm Repositories benutzt:

    helm repo list
    NAME                            URL                                                                         
    bitnami                         https://charts.bitnami.com/bitnami                                          
    longhorn                        https://charts.longhorn.io                                                  
    metallb                         https://metallb.github.io/metallb                                           
    jetstack                        https://charts.jetstack.io                                                  
    ingress-nginx                   https://kubernetes.github.io/ingress-nginx                     
    apache-solr                     https://solr.apache.org/charts                                              
    postgres-operator-charts        https://opensource.zalando.com/postgres-operator/charts/postgres-operator                    
    bvb-repo                        https://gitlab.bib-bvb.de/api/v4/projects/59/packages/helm/stable           

### Konzept

* alle Anwendungen kommen in einen Namespace:
  *  Folio, vufind, Postgres, Kafka, Elasticsearch, Solr, Minio
* Operatoren für Postgres, Sor und Minio einmal pro Kubernetes Cluster
* Zugriff von aussen über Firewall-NAT auf Loadbalancer-IP und weiter auf ingress-controller und so auf die Ingresse.
* Für jeden Folio Tenant gibt es zwei Ingresse: einen für Stripes und einen für Okapi
* vufind Deployment pro

## FOLIO Installation

### Vorbereitungen

#### Kubernetes Namespace

Die weiteren Befehle benötigen jeweils die Angabe eines Kubernetes Namespaces. Diesen kann man z.B. nur temporär in der aktuellen shell setzen, so wird später nicht aus versehen der falsche namespace verwendet.

    FOLIONS=<NEW_NAMESPACE>
    kubectl create namespace ${FOLIONS:-undefined}


#### Secrets erstellen/kopieren

Für den Zugriff auf die Container Registry des LRZ sowie auf den zentralen S3 Store benötigt man zwei Secrets.

Wenn es bereits andere folio installationen im cluster gibt, kann man einige secrets kopieren:
    gitlab-folio-group 
    s3storage-access

Manuell z.B. so (bereinigen der yamls ist nötig, siehe Beispiel in `other/gitlab.secret.example.yaml`, vor allem Zeile `namespace:` entfernen):

    kubectl -n <source-namespace> get secret gitlab-folio-group -o yaml > other/gitlab-folio-group.secret.yaml
    vi other/gitlab-folio-group.secret.yaml
    kubectl -n ${FOLIONS:-undefined} apply -f other/gitlab-folio-group.secret.yaml

Oder per script: `other/copy-secret.sh`

Für ein neues secret (nach Anlegung im gitlab mit registry-read Berechtigung):

    kubectl -n ${FOLIONS:-undefined} create secret docker-registry gitlab-folio-group --docker-server=gitlab.bib-bvb.de:5050/folio --docker-username=k8s-read --docker-password=<token>

s3storage (z.B. per minio) muss zur Verfügung stehen und die werte im s3stroage-access entsprechend angepasst werden.


#### global-values.yaml anpassen

In der Datei `global-values.yaml` werden Einstellungen vorgenommen, die in mehreren Helm-Repositories relevant sind.
Beispiel Datenbank: 
Benötige Accounts werden hier angegeben, um dann bei der Installation von Postgres erstellt zu werden. 
Beim Installieren von Okapi und Folio-Modulen werden dann die gleichen Daten verwendet.
So gibt es nur eine zentrale Stelle, wo entsprechende Variablen gesetzt werden müssen.



### Installation Basiskomponenten

#### Elasticsearch und Kafka aus bitnami-repo
Einmal pro client-PC: bitnami repo hinzufügen:

    helm repo add bitnami https://charts.bitnami.com/bitnami

Elasticsearch installieren, der `NOTES.txt` output wird mit folgendem Befehl unter `logs/` gespeichert und enthält alle wichtigen informationen:

    helm -n ${FOLIONS:-undefined} install elasticsearch bitnami/elasticsearch -f bitnami/elastic-values.yml

Wichtig: im outputlog nachschaun, unter welchem internen service elasticsearch zu erreichen ist und mit den values von mod-search abgleichen!
Hier gab es bei bitnami chart upgrades in der Vergangenheit Änderungen.

Wie beim letzten Punkt auch Kafka installieren:

    helm -n ${FOLIONS:-undefined} install kafka bitnami/kafka -f bitnami/kafka-values.yml

Dann am besten warten, bis im Dashboard alle pods grün sind.


#### postgres 

postgres wird über den zalando-postgres-operator installiert, mehr unter `https://github.com/zalando/postgres-operator`

    helm -n ${FOLIONS:-undefined} install zal-pg bvb-repo/zalando-pg -f global-values.yaml



### Installation Folio Komponenten


#### okapi

Zum Thema Docker-Container und CI, siehe `https://gitlab.bib-bvb.de/folio/okapi`.

    helm -n ${FOLIONS:-undefined} install okapi bvb-repo/okapi -f global-values.yaiml


#### auth-modules
Man braucht zum installieren der Folio-Module mindestens 2 value files:
- `<RELEASE_TAG>-auth.yaml` für die zur Absicherung nötigen Module mod-users, mod-authtoken, mod-permissions und mod-login
- `<RELEASE_TAG>-no-auth.yaml>` für alle anderen Module eines Folio-Releases.

Zusätzliche Module können auch in einen seperaten Helm-Release

Bei einem neuen Folio-Release kannen das Skript `modules/script/update-helm-module-values.py` verwendet werden.

Die zur Authentifizierung nötigen Module werden in einem seperaten Helm-Release installiert, um Komplikationen beim Upgraden zu vermeiden:

    helm -n ${FOLIONS:-undefined} install mods-auth bvb-repo/modules -f global-values.yaml -f modules/valuesd/<RELEASE_TAG>-auth.yaml


#### secure supertenant

Per Skript Folio-supertenant mit den für die Authorisierung nötigen Modulen versorgen und absichern. Der Job wird per Helm template erzeugt, es sollte keine Konfiguration nötig sein (bei gleicher `global-values.yaml`).

    helm -n ${FOLIONS:-undefined} template secure bvb-repo/secure-supertenant -f global-values.yaml > secure-supertenant/renders/secure-supertenant.yaml
    kubectl -n ${FOLIONS:-undefined} apply -f secure-supertenant/renders/secure-supertenant.yaml


#### andere modules

Die restlichen Module werden sperat im schon abgesicherten System nachinstalliert. 
So kann man diese Installation per `helm upgrade` relative leicht um weitere Module erweitern und Einstellungen der Module ändern.

    helm -n ${FOLIONS:-undefined} install mods bvb-repo/modules -f global-values.yaml -f modules/valuesd/<RELEASE_TAG>-no-auth.yaml --debug > logs/mods-install-${FOLIONS:-undefined}.yaml


#### tenant erstellen und stripes deployment

Vor der Installation des Tenants prüfen, ob alle Module bei Okapi registriert sind. Das sollte dann der Fall sein, wenn alle init-Jobs aus dem vorigen Schritt erfolgreich abgeschlossen sind.

- erstelle neue stripes branch in gitlab ( https://gitlab.bib-bvb.de/folio/platform-complete ) aus branch mit richtiger version (z.B. lotus-base) und Werte anpassen:
  - unter docker/Dockerfile die ARGS an: OKAPI\_URL auf gewünschten ingress und TENANT\_ID
  - in `stripes.config.js` logo/favicon und Beschreibung anpassen. URL/tenant in dieser Datei werden von den ARGS der Dockerfile überschrieben.
  - docker image bauen (manuell auf eigenem Arbeitsrechner und dann pushen, oder einen git tag vergeben und pushen)
- tenant/values-example.yaml kopieren und anpassen, wichtig: 
  - tenantId
  - stripes.imageVersion   (auf branchname)
  - folgende 3 variablen können gleich sein, und sollten zum ingress der in der stripes Dockerfile angegeben wurde passen:
    - ingress.host
    - ingress.tls.secretName
    - ingress.tls.host
- Installieren in neuem Helm Release, bei nur einem tenant kann dessen id genutzt werden 

Befehl Beispiel:

    helm -n ${FOLIONS:-undefined} install <RELEASENAME> bvb-repo/tenant -f global-values.yaml -f tenant/values-<RELEASENAME>.yaml -f modules/valuesd/<RELEASE_TAG>-all.yaml --debug > tenant/install-debug-${FOLIONS:-undefined}.yml
    aktuelles Besipiel für lotus instanzen:
    helm -n folio-lotus install ubt bvb-repo/tenant -f global-values-lotus-h1.yaml -f tenant/values-lotus-ubt.yaml -f modules/valuesd/2022-r1-all-reduced.yaml


#### Notizen zum deinstallieren

Per `helm -n ${FOLIONS:-undefined} list` installierte Releases checken

Per `helm -n ${FOLIONS:-undefined} uninstall <RELEASENAME>` deinstallieren

Zu beachten: 
- Persistent Volume Claims von Elasticsearch, Kafka und Kubegres werden nicht automatisch gelöscht, muss manuell erledigt werden.
- Secrets mit Kubegres und Supertenant Passwörtern werden nicht automatisch gelöscht und beim neu installieren wieder verwendet. Sollte das nicht gewünscht sein, manuell deinstallieren oder Namespace löschen.


## Installation vufind

### Installation Basiskomponenten

#### Installation DB Cluster

Einmal pro Installation sollte für alle vufind Instanzen/Tenants ein Postgres DB Cluster erstellt werden. Dafür gibt es wie bei Folio ein Helm chart, dass eine custom rosource für den Zalando Postgres Operator erstellt. Installation:

   helm -n ${FOLIONS:-undefined} install vufind-postgres bvb-repo/zalando-vufind-pg -f values.yaml

Für mögliche Werte in values.yaml siehe values.yaml im chart. 

#### Installation Solr Cloud

Für die Installation der Solr cloud mit Hilfe des Solr cloud operators stehen Beispiel-values für das Solr Helm chart in solr-vufind. Wichtig hierbei ist, dass das Image aus gitlab.bib-bvb.de:5050/vufind/vufind-ci/vufind für Solr benutzt wird. Dort sind die Erweiterungen für vufind enthalten.

Installation:

   helm -n ${FOLIONS:-undefined} install solr apache-solr/solr -f solr-vufind/solr-vufind.yaml

### Installation vufind

Pro Tenant wird eine vufind Installation gemacht. Dabei wird in einem Init-container auch die Datenbank im Postgres Cluster angelegt. Der Zugriff auf Solr erfolgt auf den gemeinsamen Index.

Die Verbindung zu Folio wird automatisch konfiguriert (noch ein Todo), dazu muss der Tenantname mit einem Folio Tenant übereinstimmen.

Installation (Beispiel Tenantname bvb):

   helm -n ${FOLIONS:-undefined} install bvb-opac bvb-repo/vufind -f values.yaml

In values.yaml muss dann der Tenantname genannt werden:

    global:
      foliotenant: "bvb"

Um die Konfiguration und die Themes zu verwalten, gibt es zwei Methoden, die die Dateien aus per Netzwerk zugänglichen Ort holen:

* S3 Storage
* git Repository

Beides kann in den Values konfiguriert werden.


### Special: Import Daten aus B3Kat


