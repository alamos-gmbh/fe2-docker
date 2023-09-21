FROM amazoncorretto:17-alpine

LABEL Alamos GmbH <kontakt@alamos-gmbh.com>

# Packages:
# nano text editor as alpine only contains vi
# add network tools dig and nslookup
# htop process manager
# curl for healthchecks
# fonts for Jasper Reports
# cups-client for printing

RUN apk add --no-cache \
  nano \
  bind-tools \
  htop \
  curl \
  msttcorefonts-installer \
  fontconfig \
  cups-client

RUN update-ms-fonts

COPY backend/target/FE2.jar fe2.jar
COPY backend/target/FE2/files files

EXPOSE 83
EXPOSE 64112

ENTRYPOINT ["java", "-javaagent:/fe2.jar", "-jar", "/fe2.jar", "server"]