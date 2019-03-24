FROM postgres:11-alpine

ENV POSTGIS_VERSION 2.5.1
ENV POSTGIS_SHA256 d380e9ec0aeee87c5d976b9111ea11199ba875f2cd496c49b4141db29cee9557

ENV CGAL_VERSION releases/CGAL-4.13
ENV CGAL_SHA256 c4912a00e99f29ee37cac1d780d115a048743370b9329a2cca839ffb392f3516

ENV SFCGAL_VERSION v1.3.6
ENV SFCGAL_SHA256 5840192eb4a1a4e500f65eedfebacd4bc4b9192c696ea51d719732dc2c75530a

RUN set -ex \
    \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
    \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz" \
    && echo "$POSTGIS_SHA256 *postgis.tar.gz" | sha256sum -c - \
    && wget -O cgal.tar.gz "https://github.com/CGAL/cgal/archive/$CGAL_VERSION.tar.gz" \
    && echo "$CGAL_SHA256 *cgal.tar.gz" | sha256sum -c - \
    && wget -O sfcgal.tar.gz "https://github.com/Oslandia/SFCGAL/archive/$SFCGAL_VERSION.tar.gz" \
    && echo "$SFCGAL_SHA256 *sfcgal.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/src/postgis /usr/src/cgal /usr/src/sfcgal \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && tar \
        --extract \
        --file cgal.tar.gz \
        --directory /usr/src/cgal \
        --strip-components 1 \
    && tar \
        --extract \
        --file sfcgal.tar.gz \
        --directory /usr/src/sfcgal \
        --strip-components 1 \
    && rm postgis.tar.gz cgal.tar.gz sfcgal.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        g++ \
        json-c-dev \
        make \
        perl \
        pcre-dev \
        cmake \
         \
    \
    && apk add --no-cache --virtual .build-deps-edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        gdal-dev \
        geos-dev \
        proj4-dev \
        protobuf-c-dev \
    && apk add libtool \
               libxml2-dev \
               pcre-dev \
               mpfr-dev \
               boost-dev \
               gmp-dev \
    && cd /usr/src/cgal \
    && cmake . && make && make install \
    && cd /usr/src/sfcgal \
    && cmake -DCMAKE_INSTALL_LIBDIR=/usr/local/lib . && make && make install \
    && cd /usr/src/postgis \
    && ./autogen.sh \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-grass/postgis.git/tree/debian/rules?h=jessie
    && ./configure \
#       --with-gui \
    && make \
    && make install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
        pcre2 \
    && apk add --no-cache --virtual .postgis-rundeps-edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        geos \
        gdal \
        proj4 \
        protobuf-c \
        libcrypto1.1 libressl2.7-libcrypto \
    && cd / \
    && rm -rf /usr/src/postgis /usr/src/cgal /usr/src/sfcgal \
    && apk del .fetch-deps .build-deps .build-deps-edge

ADD files/ /

VOLUME /var/lib/postgresql/data

EXPOSE 5432
# ENTRYPOINT ["/docker-entrypoint.sh"]
# CMD ["postgres"]
