FROM amazoncorretto:17-alpine

LABEL Alamos GmbH <kontakt@alamos-gmbh.com>

# add nano text editor as alpine only contains vi
RUN apk add --no-cache nano
# add network tools dig and nslookup
RUN apk add --no-cache bind-tools
# htop process manager
RUN apk add --no-cache htop
# curl for healthchecks
RUN apk add --no-cache curl

COPY backend/target/FE2.jar fe2.jar
COPY backend/target/FE2/files files

EXPOSE 83
EXPOSE 64112

ENTRYPOINT ["java", "-javaagent:/fe2.jar", "-jar", "/fe2.jar", "server"]