FROM amazoncorretto:17

LABEL Alamos GmbH <kontakt@alamos-gmbh.com>

COPY backend/target/FE2.jar fe2.jar
COPY backend/target/FE2/files files

EXPOSE 83
ENTRYPOINT ["java", "-javaagent:/fe2.jar", "-jar", "/fe2.jar", "server"]