FROM 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_base:latest

LABEL ORG="Armedia LLC" \
      APP="solr" \
      VERSION="1.0" \
      IMAGE_SOURCE="https://github.com/ArkCase/ark_solr" \
      MAINTAINER="Armedia LLC"
#################
# Build JDK
#################
ARG JAVA_VERSION="11.0.12.0.7-0.el7_9"

ENV JAVA_HOME=/usr/lib/jvm/java \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    SOLR_OPTS="-Dpdfbox.fontcache=/tmp"

RUN yum update -y && \
    yum -y install java-11-openjdk-devel-${JAVA_VERSION} unzip && \
    $JAVA_HOME/bin/javac -version
#################
# Build Solr
#################
ARG SOLR_VERSION="8.11.1"

ENV SOLR_USERID=2000 \
    SOLR_GROUPID=2020 \
    SOLR_GROUPNAME=solr \
    SOLR_USER=solr \
    SOLR_PORT=8983 \
    PATH=/opt/solr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    SOLR_URL="https://apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz"
RUN groupadd -g ${SOLR_GROUPID} ${SOLR_GROUPNAME} && \
    useradd -u ${SOLR_USERID} -g ${SOLR_GROUPNAME} ${SOLR_USER} &&\
    yum install -y lsof
WORKDIR /opt
ADD ${SOLR_URL} /opt/

RUN set -ex;\
    yum update -y;\
    tar -xzvf solr-${SOLR_VERSION}.tgz;\
    mv solr-${SOLR_VERSION} solr;\
    rm solr-${SOLR_VERSION}.tgz;\
    rm -f /opt/solr/server/solr/configsets/_default/conf/managed-schema /opt/solr/*.txt ;\
    chown -R ${SOLR_USER}:${SOLR_USER} /opt/solr;\
    yum clean all 

USER solr

EXPOSE $SOLR_PORT

CMD [ "solr","start","-f","-cloud" ]