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
ARG VER="8.11.3"

ARG SRC="https://downloads.apache.org/lucene/solr/${VER}/solr-${VER}.tgz"
ARG CW_VER="1.4.5"
ARG CW_SRC="https://project.armedia.com/nexus/repository/arkcase/com/armedia/acm/curator-wrapper/${CW_VER}/curator-wrapper-${CW_VER}-exe.jar"
ARG MARIADB_DRIVER="3.1.2"
ARG MARIADB_DRIVER_URL="https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/${MARIADB_DRIVER}/mariadb-java-client-${MARIADB_DRIVER}.jar"
ARG MSSQL_DRIVER="12.2.0.jre11"
ARG MSSQL_DRIVER_URL="https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/${MSSQL_DRIVER}/mssql-jdbc-${MSSQL_DRIVER}.jar"
ARG MYSQL_DRIVER="8.0.32"
ARG MYSQL_DRIVER_URL="https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${MYSQL_DRIVER}/mysql-connector-j-${MYSQL_DRIVER}.jar"
ARG MYSQL_LEGACY_DRIVER="1.0.0"
ARG MYSQL_LEGACY_DRIVER_URL="https://project.armedia.com/nexus/repository/arkcase/com/armedia/mysql/mysql-legacy-driver/${MYSQL_LEGACY_DRIVER}/mysql-legacy-driver-${MYSQL_LEGACY_DRIVER}.jar"
ARG ORACLE_DRIVER="21.9.0.0"
ARG ORACLE_DRIVER_URL="https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc11/${ORACLE_DRIVER}/ojdbc11-${ORACLE_DRIVER}.jar"
ARG POSTGRES_DRIVER="42.5.4"
ARG POSTGRES_DRIVER_URL="https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_DRIVER}/postgresql-${POSTGRES_DRIVER}.jar"

ARG BASE_REPO="arkcase/base"
ARG BASE_VER="8"
ARG BASE_IMG="${PUBLIC_REGISTRY}/${BASE_REPO}:${BASE_VER}"

FROM "${BASE_IMG}"

ARG ARCH
ARG OS
ARG PKG
ARG VER
ARG SRC
ARG CW_SRC
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

ARG MARIADB_DRIVER
ARG MARIADB_DRIVER_URL
ARG MSSQL_DRIVER
ARG MSSQL_DRIVER_URL
ARG MYSQL_DRIVER
ARG MYSQL_DRIVER_URL
ARG MYSQL_LEGACY_DRIVER
ARG MYSQL_LEGACY_DRIVER_URL
ARG ORACLE_DRIVER
ARG ORACLE_DRIVER_URL
ARG POSTGRES_DRIVER
ARG POSTGRES_DRIVER_URL

RUN yum -y install \
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

RUN curl "${SRC}" | tar -xzvf - && \
    mv "solr-${VER}"/* "${HOME_DIR}" && \
    rmdir "solr-${VER}" && \
    mkdir -p "${DATA_DIR}/logs" && \
    curl -L --fail "${MYSQL_DRIVER_URL}" -o "${WEBAPP_LIBS_DIR}/mysql-connector-j-${MYSQL_DRIVER}.jar" && \
    curl -L --fail "${MYSQL_LEGACY_DRIVER_URL}" -o "${WEBAPP_LIBS_DIR}/mysql-legacy-driver-${MYSQL_LEGACY_DRIVER}.jar" && \
    curl -L --fail "${MARIADB_DRIVER_URL}" -o "${WEBAPP_LIBS_DIR}/mariadb-java-client-${MARIADB_DRIVER}.jar" && \
    curl -L --fail "${MSSQL_DRIVER_URL}" -o "${WEBAPP_LIBS_DIR}/mssql-jdbc-${MSSQL_DRIVER}.jar" && \
    curl -L --fail "${ORACLE_DRIVER_URL}" -o "${WEBAPP_LIBS_DIR}/ojdbc11-${ORACLE_DRIVER}.jar" && \
    curl -L --fail "${POSTGRES_DRIVER_URL}" -o "${WEBAPP_LIBS_DIR}/postgresql-${POSTGRES_DRIVER}.jar" && \
    chown -R "${APP_USER}:${APP_GROUP}" "${HOME_DIR}" "${DATA_DIR}" && \
    chmod -R u=rwX,g=rwX,o= "${HOME_DIR}" "${DATA_DIR}"

#################
# Configure Solr
#################

ENV CONF_DIR="${SERVER_DIR}/solr/configsets"

RUN rm -rf "${CONF_DIR}/sample_techproducts_configs"

# Install the curator wrapper
RUN curl -L --fail -o "/usr/local/bin/curator-wrapper.jar" "${CW_SRC}"

USER "${APP_USER}"
WORKDIR "${HOME_DIR}"

EXPOSE 8983

VOLUME [ "${DATA_DIR}" ]

ENTRYPOINT [ "${HOME_DIR}/bin/solr", "start", "-f", "-cloud" ]
