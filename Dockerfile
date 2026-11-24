# kkFileView for Railway: built from the pinned upstream release (no official 5.x image is published).
# Upstream: https://github.com/kekingcn/kkFileView (Apache-2.0)

# ---- build: compile kkFileView v5.0.3 from the release commit ----
FROM maven:3.9.16-eclipse-temurin-21@sha256:99e61abcff91a9b1333463bd8451fb18495d6eba9250ac66a338b518f8278320 AS build
# v5.0.3 = 3b82689a676e8a7e7d3ec4cc0c74de0676b0dac9
ARG KK_VERSION=5.0.3
ARG KK_COMMIT=3b82689a676e8a7e7d3ec4cc0c74de0676b0dac9
RUN command -v git >/dev/null || (apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*)
WORKDIR /src
# Sparse, blob-less fetch: skips the 825 MB Windows LibreOfficePortable folder in the upstream repo.
RUN git init -q . \
 && git remote add origin https://github.com/kekingcn/kkFileView.git \
 && git config core.sparseCheckout true \
 && printf '/pom.xml\n/server/\n!/server/LibreOfficePortable/\n' > .git/info/sparse-checkout \
 && git fetch -q --depth 1 --filter=blob:none origin "$KK_COMMIT" \
 && git checkout -q FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "$KK_COMMIT" \
 && grep -q "<version>$KK_VERSION</version>" pom.xml
COPY patches/ /patches/
RUN sh /patches/apply.sh /src
RUN mvn -B -q -f pom.xml -DskipTests -Dmaven.test.skip=true -Dassembly.skipAssembly=true package \
 && cp server/target/kkFileView-$KK_VERSION.jar /kkFileView.jar \
 && cp server/src/main/config/application.properties /application.properties.dist \
 && rm -rf /root/.m2

# ---- runtime: JRE 21 + LibreOffice (headless) ----
FROM eclipse-temurin:21.0.13_9-jre-noble@sha256:b4f9d2a0bc273417cf5219b7b832bbf0493ed500b7b57d5001d9f83374659060
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libreoffice-nogui fontconfig tini \
      fonts-liberation2 fonts-crosextra-carlito fonts-crosextra-caladea fonts-dejavu-core \
      fonts-wqy-microhei fonts-wqy-zenhei \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --system --uid 10001 --create-home --home-dir /home/kkfileview kkfileview \
 && mkdir -p /opt/kkFileView/bin /opt/kkFileView/config /data \
 && chown kkfileview:kkfileview /opt/kkFileView/config
COPY --from=build /kkFileView.jar /opt/kkFileView/bin/kkFileView.jar
COPY --from=build /application.properties.dist /opt/kkFileView/application.properties.dist
COPY start.sh /usr/local/bin/kkfileview-start
RUN chmod 755 /usr/local/bin/kkfileview-start
ENV KKFILEVIEW_BIN_FOLDER=/opt/kkFileView/bin \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    MALLOC_ARENA_MAX=2 \
    PORT=8012
EXPOSE 8012
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/kkfileview-start"]
