#!/bin/bash
here=$(realpath "$0")
here=$(dirname "$here")
cd "$here"
SOLR_VERSION="7.7.2"
cloud_config_version="2021.03"
rm -rf artifacts
mkdir artifacts
echo "Downloading  solr version $cloud_config_version"
aws s3 cp "s3://arkcase-container-artifacts/ark_solr/artifacts/solr-${SOLR_VERSION}.tgz" artifacts/
