FROM maven:3-openjdk-11 as mavenbuild

WORKDIR /app

RUN git clone https://github.com/Pugmatt/BedrockConnect
RUN mvn -f /app/BedrockConnect/serverlist-server/pom.xml install

FROM mcr.microsoft.com/java/jre:11-zulu-ubuntu

RUN mkdir -p /brc
COPY --from=mavenbuild /app/BedrockConnect/serverlist-server/target/BedrockConnect-1.0-SNAPSHOT.jar /brc/

WORKDIR /brc
EXPOSE 19132/udp
CMD ["java", "-Xms1G", "-Xmx1G", "-jar", "BedrockConnect-1.0-SNAPSHOT.jar", "nodb=true"]
