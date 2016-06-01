FROM            java:8

MAINTAINER      Simon Elliston Ball <simon@simonellistonball.com>

ENV             DIST_MIRROR             http://mirror.cc.columbia.edu/pub/software/apache/nifi
ENV             NIFI_HOME               /opt/nifi
ENV             VERSION                 0.6.1

# Install necessary packages, create target directory, download and extract, and update the banner to let people know what version they are using
RUN             mkdir -p /opt/nifi && \
                curl ${DIST_MIRROR}/${VERSION}/nifi-${VERSION}-bin.tar.gz | tar xvz -C ${NIFI_HOME} --strip-components=1

# Expose web port
EXPOSE          8443-8448
VOLUME          ["/opt/certs", "${NIFI_HOME}/custom", "${NIFI_HOME}/flowfile_repository", "${NIFI_HOME}/database_repository", "${NIFI_HOME}/content_repository", "${NIFI_HOME}/provenance_repository"]

ADD             ./sh/ /opt/sh
RUN             chmod a+x /opt/sh/start.sh

CMD             ["/opt/sh/start.sh"]
