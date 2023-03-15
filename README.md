# ark_solr

Solr is a standalone enterprise search server with a REST-like API. You put documents in it (called "indexing") via JSON, XML, CSV or binary over HTTP. You query it via HTTP GET and receive JSON, XML, CSV or binary results.

Solr Documentation is available at https://solr.apache.org/

## How to build:

docker build -t ark_solr:latest .

Repository pushes occur automatically when code is checked in.

## How to run: (Helm)

helm repo add arkcase https://arkcase.github.io/ark_helm_charts/

helm install ark-solr arkcase/ark-solr

helm uninstall ark-solr
