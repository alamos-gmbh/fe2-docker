FROM amazoncorretto:17

LABEL Alamos GmbH <kontakt@alamos-gmbh.com>

COPY fe2/fe2.jar fe2.jar
COPY backend/target/FE2/files files

EXPOSE 83
ENTRYPOINT ["java", "-javaagent:/fe2.jar", "-jar", "/fe2.jar", "server"]

# docker build -t fe2:2.28.157 .
# docker tag fe2:2.27.258 fe2:latest

# docker build -f fe2/Dockerfile -t fe2_app:2.28.157 .
# docker image tag fe2_app:2.28.157 docker-registry.alamos-gmbh.com/public/fe2_app:2.28.157
# docker image push docker-registry.alamos-gmbh.com/public/fe2_app:2.28.157