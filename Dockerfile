FROM python:alpine3.6

ENV PYMESH_PATH /root/PyMesh
WORKDIR /root/
COPY systime.patch /root/systime.patch

RUN echo "@edge http://alpine.gliderlabs.com/alpine/edge/community" >> /etc/apk/repositories && \
    apk add --no-cache boost boost-thread boost-python3 libgmpxx openblas@edge && \
    apk add --no-cache --virtual .build-deps boost-dev gmp-dev build-base git linux-headers mpfr-dev cmake && \
    apk add --no-cache --virtual .build-deps-edge openblas-dev@edge && \
    git clone https://github.com/cyrilpic/PyMesh.git && \
    cd PyMesh && \
    git submodule update --init && \
    mkdir -p $PYMESH_PATH/third_party/build && \
    mkdir -p $PYMESH_PATH/build && \
    pip install -r $PYMESH_PATH/python/requirements.txt && \
    cd $PYMESH_PATH/third_party/cork && \
    patch -p0 < /root/systime.patch && \
    cd $PYMESH_PATH && \
    CXXFLAGS=-U_FORTIFY_SOURCE ./setup.py build && \
    ./setup.py install && \
    rm -rf build third_party/build && \
    runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local \
                | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                | sort -u \
                | xargs -r apk info --installed \
                | sort -u \
    )" && \
    apk --no-cache add --virtual .rundeps $runDeps && \
    apk --no-cache del .build-deps-edge && \
    apk --no-cache del .build-deps && \
    cd /root && \
    rm -R PyMesh
