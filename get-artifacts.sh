#!/bin/bash
here=$(realpath "$0")
here=$(dirname "$here")
cd "$here"
SOLR_VERSION="7.7.2"
rm -rf artifacts
mkdir artifacts
echo "Downloading solr version $SOLR_VERSION"
aws s3 cp "s3://arkcase-container-artifacts/ark_solr/artifacts/solr-${SOLR_VERSION}.tgz" artifacts/
