FROM 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_base_java8:latest

LABEL ORG="Armedia LLC" \
      VERSION="1.0" \
      IMAGE_SOURCE="https://github.com/ArkCase/ark_solr" \
      MAINTAINER="Armedia LLC"

ENV SOLR_VERSION="7.7.2" \
    SOLR_USER="solr" 
    

ENV SOLR_DOWNLOAD_URL https://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz
ENV SOLR_PORT 8983

ADD $SOLR_DOWNLOAD_URL /tmp


RUN useradd  --system --user-group $SOLR_USER  && \
    cd /tmp && \
    #install lsof dependency
    yum install lsof -y && \
    tar -xzf solr-$SOLR_VERSION.tgz -C /opt && \
    rm solr-$SOLR_VERSION.tgz && \
    cd /opt && \
    mv solr-$SOLR_VERSION solr && \
    chown -R $SOLR_USER:$SOLR_USER /opt/solr && \
    rm -f /opt/solr/server/solr/configsets/_default/conf/managed-schema /opt/solr/*.txt && \
    rm -Rf /opt/solr/example /opt/solr/docs 

ENV PATH=/opt/solr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

USER solr

EXPOSE $SOLR_PORT

WORKDIR /opt/solr

CMD [ "solr","start","-f" ]