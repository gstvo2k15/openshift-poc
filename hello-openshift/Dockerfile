# syntax=docker/dockerfile:1

#
# Step 1: Maven compilation
#
FROM docker.io/library/maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /workspace

COPY pom.xml .
RUN mvn --batch-mode dependency:go-offline

COPY src ./src

RUN mvn --batch-mode clean package \
    && test -f /workspace/target/ROOT.war

#
# Step 2: Tomcat
#
FROM docker.io/library/tomcat:9.0.118-jdk17-temurin-noble

LABEL org.opencontainers.image.title="Hello OpenShift POC"
LABEL org.opencontainers.image.description="Aplicación Maven desplegada en Tomcat 9"

RUN rm -rf "${CATALINA_HOME}/webapps/"* \
    && mkdir -p \
        "${CATALINA_HOME}/webapps" \
        "${CATALINA_HOME}/logs" \
        "${CATALINA_HOME}/temp" \
        "${CATALINA_HOME}/work" \
    && chgrp -R 0 "${CATALINA_HOME}" \
    && chmod -R g=u "${CATALINA_HOME}"

COPY --from=builder \
    /workspace/target/ROOT.war \
    ${CATALINA_HOME}/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]