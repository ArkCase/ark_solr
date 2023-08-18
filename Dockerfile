###########################################################################################################
#
# How to build:
#
# docker build -t arkcase/solr:latest .
#
# How to run: (Helm)
#
# helm repo add arkcase https://arkcase.github.io/ark_helm_charts/
# helm install ark-solr arkcase/ark-solr
# helm uninstall ark-solr
#
###########################################################################################################

ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG BASE_REPO="arkcase/base"
ARG BASE_TAG="8.8-01"
ARG ARCH="amd64"
ARG OS="linux"
ARG PKG="solr"
ARG VER="8.11.2"
ARG BLD="01"
ARG SRC="https://downloads.apache.org/lucene/solr/${VER}/solr-${VER}.tgz"

FROM "${PUBLIC_REGISTRY}/${BASE_REPO}:${BASE_TAG}"

ARG ARCH
ARG OS
ARG PKG
ARG VER
ARG SRC
ARG APP_UID="2000"
ARG APP_GID="${APP_UID}"
ARG APP_USER="${PKG}"
ARG APP_GROUP="${APP_USER}"
ARG BASE_DIR="/app"
ARG HOME_DIR="${BASE_DIR}/${PKG}"
ARG DATA_DIR="${BASE_DIR}/data"
ARG LOGS_DIR="${DATA_DIR}/logs"

RUN yum -y update && \
    yum -y install \
        java-11-openjdk-devel \
        jq \
        lsof \
    && \
    yum -y clean all

LABEL ORG="ArkCase LLC" \
      MAINTAINER="Armedia Devops Team <devops@armedia.com>" \
      APP="solr" \
      VERSION="${VER}" \
      IMAGE_SOURCE="https://github.com/ArkCase/ark_solr"

ENV APP_UID="${APP_UID}" \
    APP_GID="${APP_GID}" \
    APP_USER="${APP_USER}" \
    APP_GROUP="${APP_GROUP}" \
    JAVA_HOME="/usr/lib/jvm/java" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8" \
    BASE_DIR="${BASE_DIR}" \
    DATA_DIR="${DATA_DIR}" \
    HOME_DIR="${HOME_DIR}" \
    PATH="${HOME_DIR}/bin:${PATH}" \
    SOLR_LOGS_DIR="${LOGS_DIR}"

WORKDIR "${BASE_DIR}"

RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}" && \
    useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --groups "${ACM_GROUP}" --create-home --home-dir "${HOME_DIR}" "${APP_USER}"

#################
# Build Solr
#################

WORKDIR "${BASE_DIR}"

RUN curl -o solr.tar.gz "${SRC}" && \
    tar -xzvf solr.tar.gz && \
    mv "solr-${VER}"/* "${HOME_DIR}" && \
    rmdir "solr-${VER}" && \
    rm -f solr.tar.gz && \
    mkdir -p "${DATA_DIR}/logs" && \
    chown -R "${APP_USER}:${APP_GROUP}" "${HOME_DIR}" "${DATA_DIR}" && \
    chmod -R u=rwX,g=rwX,o= "${HOME_DIR}" "${DATA_DIR}"

#################
# Configure Solr
#################

ENV CONF_DIR="${HOME_DIR}/server/solr/configsets"

RUN rm -rf "${CONF_DIR}/sample_techproducts_configs"

USER "${APP_USER}"
WORKDIR "${HOME_DIR}"

EXPOSE 8983

VOLUME [ "${DATA_DIR}" ]

ENTRYPOINT [ "${HOME_DIR}/bin/solr", "start", "-f", "-cloud" ]
