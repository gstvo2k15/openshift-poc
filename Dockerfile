FROM docker.io/library/tomcat:10.1-jre17-temurin
# Run Tomcat as an unprivileged Kubernetes user.
RUN set -eux; mkdir -p /usr/local/tomcat/webapps /usr/local/tomcat/temp /usr/local/tomcat/work /usr/local/tomcat/logs; chown -R 1001:1001 /usr/local/tomcat; rm -rf /usr/local/tomcat/webapps/*
COPY --chown=1001:1001 app/target/ROOT.war /usr/local/tomcat/webapps/ROOT.war
USER 1001:1001
EXPOSE 8080
CMD ["catalina.sh", "run"]
