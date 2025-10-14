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
ARG ARCH="amd64"
ARG OS="linux"
ARG PKG="solr"
ARG VER="9.9.0"
ARG JAVA="17"

ARG KEYS="https://downloads.apache.org/solr/KEYS"
ARG SRC="https://archive.apache.org/dist/solr/solr/${VER}/solr-${VER}.tgz"
ARG CW_VER="1.7.1"
ARG CW_SRC="com.armedia.acm:curator-wrapper:${CW_VER}:jar:exe"
ARG CW_REPO="https://nexus.armedia.com/repository/arkcase"
ARG MARIADB_DRIVER="3.5.6"
ARG MARIADB_DRIVER_SRC="org.mariadb.jdbc:mariadb-java-client:${MARIADB_DRIVER}:jar"
ARG MSSQL_DRIVER="13.2.0.jre11"
ARG MSSQL_DRIVER_SRC="com.microsoft.sqlserver:mssql-jdbc:${MSSQL_DRIVER}:jar"
ARG MYSQL_DRIVER="9.4.0"
ARG MYSQL_DRIVER_SRC="com.mysql:mysql-connector-j:${MYSQL_DRIVER}:jar"
ARG MYSQL_LEGACY_DRIVER="1.0.0"
ARG MYSQL_LEGACY_DRIVER_SRC="com.armedia.mysql:mysql-legacy-driver:${MYSQL_LEGACY_DRIVER}:jar"
ARG MYSQL_LEGACY_DRIVER_REPO="https://nexus.armedia.com/repository/arkcase"
ARG ORACLE_DRIVER="23.9.0.25.07"
ARG ORACLE_DRIVER_SRC="com.oracle.database.jdbc:ojdbc11:${ORACLE_DRIVER}:jar"
ARG POSTGRES_DRIVER="42.7.8"
ARG POSTGRES_DRIVER_SRC="org.postgresql:postgresql:${POSTGRES_DRIVER}:jar"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base-java"
ARG BASE_VER="22.04"
ARG BASE_VER_PFX=""
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}:${BASE_VER_PFX}${BASE_VER}"

FROM "${BASE_IMG}"

ARG ARCH
ARG OS
ARG PKG
ARG VER
ARG JAVA
ARG KEYS
ARG SRC
ARG APP_UID="2000"
ARG APP_GID="${APP_UID}"
ARG APP_USER="${PKG}"
ARG APP_GROUP="${APP_USER}"
ARG BASE_DIR="/app"
ARG HOME_DIR="${BASE_DIR}/${PKG}"
ARG DATA_DIR="${BASE_DIR}/data"
ARG LOGS_DIR="${DATA_DIR}/logs"
ARG SERVER_DIR="${HOME_DIR}/server"
ARG WEBAPP_DIR="${SERVER_DIR}/solr-webapp/webapp"
ARG WEBAPP_LIBS_DIR="${WEBAPP_DIR}/WEB-INF/lib"

ARG CW_SRC
ARG CW_REPO
ARG MARIADB_DRIVER_SRC
ARG MSSQL_DRIVER_SRC
ARG MYSQL_DRIVER_SRC
ARG MYSQL_LEGACY_DRIVER_SRC
ARG MYSQL_LEGACY_DRIVER_REPO
ARG ORACLE_DRIVER_SRC
ARG POSTGRES_DRIVER_SRC

RUN set-java "${JAVA}" && \
    apt-get -y install \
        lsof \
      && \
    apt-get clean

LABEL ORG="ArkCase LLC" \
      MAINTAINER="Armedia Devops Team <devops@armedia.com>" \
      APP="solr" \
      VERSION="${VER}" \
      IMAGE_SOURCE="https://github.com/ArkCase/ark_solr"

ENV APP_UID="${APP_UID}" \
    APP_GID="${APP_GID}" \
    APP_USER="${APP_USER}" \
    APP_GROUP="${APP_GROUP}" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8" \
    BASE_DIR="${BASE_DIR}" \
    DATA_DIR="${DATA_DIR}" \
    HOME_DIR="${HOME_DIR}" \
    PATH="${HOME_DIR}/bin:${PATH}" \
    SOLR_LOGS_DIR="${LOGS_DIR}" \
    SERVER_DIR="${SERVER_DIR}" \
    WEBAPP_DIR="${WEBAPP_DIR}" \
    WEBAPP_LIBS_DIR="${WEBAPP_LIBS_DIR}"

WORKDIR "${BASE_DIR}"

RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}" && \
    useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --groups "${ACM_GROUP}" --create-home --home-dir "${HOME_DIR}" "${APP_USER}"

#################
# Build Solr
#################

WORKDIR "${BASE_DIR}"

#
# Install Solr
#
RUN apache-download "${SRC}" "${KEYS}" "/solr.tar.gz" && \
    tar --strip-components=1 -C "${HOME_DIR}" -xzvf "/solr.tar.gz" && \
    rm -rf "/solr.tar.gz"

#
# Add extra stuff & fix permissions
#
RUN mkdir -p "${DATA_DIR}/logs" && \
    mvn-get "${MYSQL_DRIVER_SRC}" "${WEBAPP_LIBS_DIR}" && \
    mvn-get "${MYSQL_LEGACY_DRIVER_SRC}" "${MYSQL_LEGACY_DRIVER_REPO}" "${WEBAPP_LIBS_DIR}" && \
    mvn-get "${MARIADB_DRIVER_SRC}" "${WEBAPP_LIBS_DIR}" && \
    mvn-get "${MSSQL_DRIVER_SRC}" "${WEBAPP_LIBS_DIR}" && \
    mvn-get "${ORACLE_DRIVER_SRC}" "${WEBAPP_LIBS_DIR}" && \
    mvn-get "${POSTGRES_DRIVER_SRC}" "${WEBAPP_LIBS_DIR}" && \
    chown -R "${APP_USER}:${APP_GROUP}" "${HOME_DIR}" "${DATA_DIR}" && \
    chmod -R u=rwX,g=rwX,o= "${HOME_DIR}" "${DATA_DIR}"

COPY --chown=root:root --chmod=0755 solrpass /usr/local/bin

#################
# Configure Solr
#################

ENV CONF_DIR="${SERVER_DIR}/solr/configsets"

RUN rm -rf "${CONF_DIR}/sample_techproducts_configs"

# Install the curator wrapper
RUN mvn-get "${CW_SRC}" "${CW_REPO}" "/usr/local/bin/curator-wrapper.jar"

COPY --chown=root:root --chmod=0755 fix-jar-sum /usr/local/bin/
COPY --chown=root:root --chmod=0755 CVE /CVE
RUN apply-fixes /CVE

USER "${APP_USER}"
WORKDIR "${HOME_DIR}"

EXPOSE 8983

VOLUME [ "${DATA_DIR}" ]

ENTRYPOINT [ "${HOME_DIR}/bin/solr", "start", "-f", "-cloud" ]
