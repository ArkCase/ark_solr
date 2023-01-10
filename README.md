# ark_solr

## How to build:

docker build -t 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_solr:latest .

docker push 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_solr:latest

## How to run: (Helm)

helm repo add arkcase https://arkcase.github.io/ark_helm_charts/

helm install ark-solr arkcase/ark-solr

helm uninstall ark-solr
