#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Docker image for apache kylin
FROM centos:6.9

MAINTAINER DuyHuynh <duyhuynh61@gmail.com>

ENV HIVE_VERSION 1.2.1
ENV HADOOP_VERSION 2.7.0
ENV HBASE_VERSION 1.1.2
ENV SPARK_VERSION 2.3.1
ENV ZK_VERSION 3.4.6
ENV KAFKA_VERSION 1.1.1
ENV KYLIN_VERSION 2.6.3

ENV JAVA_HOME /home/admin/jdk1.8.0_141
ENV MVN_HOME /home/admin/apache-maven-3.6.1
ENV HADOOP_HOME /home/admin/hadoop-$HADOOP_VERSION
ENV HIVE_HOME /home/admin/apache-hive-$HIVE_VERSION-bin
ENV HADOOP_CONF $HADOOP_HOME/etc/hadoop
ENV HBASE_HOME /home/admin/hbase-$HBASE_VERSION
ENV SPARK_HOME /home/admin/spark-$SPARK_VERSION-bin-hadoop2.6
ENV ZK_HOME /home/admin/zookeeper-$ZK_VERSION
ENV KAFKA_HOME /home/admin/kafka_2.11-$KAFKA_VERSION
ENV KYLIN_HOME /home/admin/apache-kylin-$KYLIN_VERSION
ENV PATH $PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HIVE_HOME/bin:$HBASE_HOME/bin:$MVN_HOME/bin:spark-$SPARK_VERSION-bin-hadoop2.6/bin:$KAFKA_HOME/bin:$KYLIN_HOME/bin

USER root

WORKDIR /home/admin

# install tools
RUN yum -y install lsof.x86_64 wget.x86_64 tar.x86_64 git.x86_64 mysql-server.x86_64 mysql.x86_64

# install mvn
RUN wget http://mirrors.ocf.berkeley.edu/apache/maven/maven-3/3.6.1/binaries/apache-maven-3.6.1-bin.tar.gz \
    && tar -zxvf apache-maven-3.6.1-bin.tar.gz \
    && rm -f apache-maven-3.6.1-bin.tar.gz
COPY conf/maven/settings.xml $MVN_HOME/conf/settings.xml

# install npm
RUN curl -sL https://rpm.nodesource.com/setup_8.x | bash - \
    && yum install -y nodejs

# setup jdk
RUN wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/jdk-8u141-linux-x64.tar.gz" \
    && tar -zxvf /home/admin/jdk-8u141-linux-x64.tar.gz \
    && rm -f /home/admin/jdk-8u141-linux-x64.tar.gz

# setup hadoop
RUN wget https://archive.apache.org/dist/hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz \
    && tar -zxvf /home/admin/hadoop-$HADOOP_VERSION.tar.gz \
    && rm -f /home/admin/hadoop-$HADOOP_VERSION.tar.gz \
    && mkdir -p /data/hadoop
COPY conf/hadoop/* $HADOOP_CONF/

# setup hbase
RUN wget https://archive.apache.org/dist/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz \
    && tar -zxvf /home/admin/hbase-$HBASE_VERSION-bin.tar.gz \
    && rm -f /home/admin/hbase-$HBASE_VERSION-bin.tar.gz \
    && mkdir -p /data/hbase \
    && mkdir -p /data/zookeeper
COPY conf/hbase/hbase-site.xml $HBASE_HOME/conf

# setup hive
RUN wget https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz \
    && tar -zxvf /home/admin/apache-hive-$HIVE_VERSION-bin.tar.gz \
    && rm -f /home/admin/apache-hive-$HIVE_VERSION-bin.tar.gz \
    && wget -P $HIVE_HOME/lib https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.24/mysql-connector-java-5.1.24.jar
COPY conf/hive/hive-site.xml $HIVE_HOME/conf

# setup spark
RUN wget https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.6.tgz \
    && tar -zxvf /home/admin/spark-$SPARK_VERSION-bin-hadoop2.6.tgz \
    && rm -f /home/admin/spark-$SPARK_VERSION-bin-hadoop2.6.tgz \
    && cp $HIVE_HOME/conf/hive-site.xml $SPARK_HOME/conf \
    && cp $SPARK_HOME/yarn/*.jar $HADOOP_HOME/share/hadoop/yarn/lib

# setup kafka
RUN wget https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_2.11-$KAFKA_VERSION.tgz \
    && tar -zxvf /home/admin/kafka_2.11-$KAFKA_VERSION.tgz \
    && rm -f /home/admin/kafka_2.11-$KAFKA_VERSION.tgz

# setup kylin
RUN wget http://mirror.downloadvn.com/apache/kylin/apache-kylin-$KYLIN_VERSION/apache-kylin-$KYLIN_VERSION-bin-hbase1x.tar.gz \
    && tar -zxvf /home/admin/apache-kylin-$KYLIN_VERSION-bin-hbase1x.tar.gz \
    && mv apache-kylin-$KYLIN_VERSION-bin-hbase1x apache-kylin-$KYLIN_VERSION \
    && rm -f /home/admin/apache-kylin-$KYLIN_VERSION-bin-hbase1x.tar.gz

COPY ./entrypoint.sh /home/admin/entrypoint.sh
RUN chmod u+x /home/admin/entrypoint.sh

ENTRYPOINT ["/home/admin/entrypoint.sh"]
