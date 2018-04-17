FROM centos:7 AS build
# Bitcoin Core version (0.12.1+)
ARG LITECOIN_VER="0.15.1"
ENV BDB_MD5="a14a5486d6b4891d2434039a0ed4c5b7  /tmp/berkley-db.tar.gz"

WORKDIR /build
RUN yum install -y gcc-c++ libtool make autoconf automake openssl-devel libevent-devel boost-devel libdb4-devel libdb4-cxx-devel
RUN yum install -y wget file
RUN mkdir /tmp/src
RUN wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz \
-O /tmp/berkley-db.tar.gz
RUN echo "${BDB_MD5}" | md5sum -c -
RUN tar -xf /tmp/berkley-db.tar.gz -C /tmp/src
RUN cd /tmp/src/db-4.8.30.NC/build_unix \
  && ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=/build \
  && make install

RUN yum install -y which
RUN gpg --keyserver pool.sks-keyservers.net --recv-key FE3348877809386C
RUN gpg --fingerprint FE3348877809386C | grep "59CA F0E9 6F23 F537 4794  5FD4 FE33 4887 7809 386C"
RUN wget https://download.litecoin.org/litecoin-0.15.1/src/litecoin-${LITECOIN_VER}.tar.gz \
    -O /tmp/litecoin-${LITECOIN_VER}.tar.gz
RUN wget https://download.litecoin.org/litecoin-0.15.1/SHA256SUMS.asc \
    -O /tmp/litecoin-${LITECOIN_VER}.tar.gz.asc
RUN gpg --verify /tmp/litecoin-${LITECOIN_VER}.tar.gz.asc
RUN cd /tmp && grep "litecoin-${LITECOIN_VER}.tar.gz\$" /tmp/litecoin-${LITECOIN_VER}.tar.gz.asc | sha256sum -c - 
RUN tar -xf /tmp/litecoin-${LITECOIN_VER}.tar.gz -C /tmp/src
RUN cd /tmp/src/litecoin-${LITECOIN_VER} \
&& export BDB_PREFIX=/build \
&& ./autogen.sh \
&& ./configure LDFLAGS=-L/build/lib/ CPPFLAGS=-I/build/include/ \
--prefix=/build \
--disable-tests \
--disable-bench \
--disable-man \
--disable-zmq \
--with-gui=no \
--enable-hardening \
&& make -j4 install
RUN strip /build/bin/* /build/lib/*.a /build/lib/*.so
RUN rm -rf /build/docs/*

FROM centos:7

ENV RPCUSER="user"
ENV RPCPASS="pass"
ENV RPCALLOWIP="127.0.0.1/8"

WORKDIR /data
RUN yum install -y boost-chrono boost-thread boost-program-options boost-system boost-filesystem libevent libressl sudo && yum clean all
COPY --from=build /build/ /usr/local/
VOLUME [ "/data" ]docker build -t litecoind:testing .
EXPOSE 9332 9333 19332 19333
RUN adduser litecoin -d /data -c 'litecoin node' -r
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "/bin/sh", "/usr/local/bin/entrypoint.sh" ]
