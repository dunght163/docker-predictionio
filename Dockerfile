FROM ubuntu:16.04 as base

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm
RUN echo "export > /etc/envvars" >> /root/.bashrc && \
    echo "export PS1='\[\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" | tee -a /root/.bashrc /etc/skel/.bashrc && \
    echo "alias tcurrent='tail /var/log/*/current -f'" | tee -a /root/.bashrc /etc/skel/.bashrc

RUN apt-get update
RUN apt-get install -y locales && locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Fix: debconf: delaying package configuration, since apt-utils is not installed
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD bash -c 'export > /etc/envvars && /usr/sbin/runsvdir-start'

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute python ssh rsync gettext-base

# Install Oracle Java 8
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer || true
### Fix bug: could not download from Oracle
RUN sed -i "s|JAVA_VERSION=8u181|JAVA_VERSION=8u191|" /var/lib/dpkg/info/oracle-java8-installer.*
RUN sed -i "s|PARTNER_URL=http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/|PARTNER_URL=http://download.oracle.com/otn-pub/java/jdk/8u191-b12/2787e4a523244c269598db4e85c51e0c/|" /var/lib/dpkg/info/oracle-java8-installer.*
RUN sed -i 's|SHA256SUM_TGZ="1845567095bfbfebd42ed0d09397939796d05456290fb20a83c476ba09f991d3"|SHA256SUM_TGZ="53c29507e2405a7ffdbba627e6d64856089b094867479edc5ede4105c1da0d65"|' /var/lib/dpkg/info/oracle-java8-installer.*
RUN sed -i "s|J_DIR=jdk1.8.0_181|J_DIR=jdk1.8.0_191|" /var/lib/dpkg/info/oracle-java8-installer.*
RUN apt-get install -f -y && \
    apt-get install -y oracle-java8-set-default
RUN apt install oracle-java8-unlimited-jce-policy
RUN rm -r /var/cache/oracle-jdk8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Spark
RUN wget -O - http://archive.apache.org/dist/spark/spark-2.2.2/spark-2.2.2-bin-hadoop2.7.tgz | tar zx
RUN mv /spark* /spark

# ElasticSearch
RUN wget -O - https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.5.2.tar.gz | tar zx
RUN mv /elasticsearch* /elasticsearch

# HBase
RUN wget -O - http://archive.apache.org/dist/hbase/1.2.7/hbase-1.2.7-bin.tar.gz | tar zx
RUN mv /hbase* /hbase
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> /hbase/conf/hbase-env.sh 

# Python SDK
RUN apt-get install -y python-pip
RUN pip install pytz
RUN pip install predictionio

# For Spark MLlib
RUN apt-get install -y libgfortran3 libatlas3-base libopenblas-base

# PredictionIO
RUN wget -O - http://archive.apache.org/dist/predictionio/0.12.1/apache-predictionio-0.12.1-bin.tar.gz | tar zx
RUN mv PredictionIO* /PredictionIO

RUN useradd elasticsearch
RUN chown -R elasticsearch /elasticsearch

ENV PIO_HOME /PredictionIO
ENV PATH $PATH:$PIO_HOME/bin

# Download SBT
# RUN /PredictionIO/sbt/sbt package 

# Configuration
RUN sed -i 's|SPARK_HOME=.*|SPARK_HOME=/spark|' /PredictionIO/conf/pio-env.sh
RUN sed -i "s|PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=ELASTICSEARCH|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=LOCALFS|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=HBASE|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|PIO_STORAGE_SOURCES_PGSQL|# PIO_STORAGE_SOURCES_PGSQL|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|# PIO_STORAGE_SOURCES_LOCALFS|PIO_STORAGE_SOURCES_LOCALFS|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|# PIO_STORAGE_SOURCES_ELASTICSEARCH_TYPE|PIO_STORAGE_SOURCES_ELASTICSEARCH_TYPE|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|# PIO_STORAGE_SOURCES_ELASTICSEARCH_HOME=.*|PIO_STORAGE_SOURCES_ELASTICSEARCH_HOME=/elasticsearch|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|# PIO_STORAGE_SOURCES_HBASE|PIO_STORAGE_SOURCES_HBASE|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|PIO_STORAGE_SOURCES_HBASE_HOME=.*|PIO_STORAGE_SOURCES_HBASE_HOME=/hbase|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|# HBASE_CONF_DIR=.*|HBASE_CONF_DIR=/hbase/conf|" /PredictionIO/conf/pio-env.sh

COPY hbase-site.xml /hbase/conf/
COPY hbase-env.sh /hbase/conf/
COPY quickstartapp quickstartapp

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
