FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    ssh \
    rsync \
    curl \
    wget \
    python3 \
    python3-pip \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Configuration SSH
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

# Téléchargement et installation de Hadoop
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz && \
    tar -xzf hadoop-3.3.4.tar.gz && \
    mv hadoop-3.3.4 $HADOOP_HOME && \
    rm hadoop-3.3.4.tar.gz

# Téléchargement et installation de Spark
RUN wget https://archive.apache.org/dist/spark/spark-3.4.0/spark-3.4.0-bin-hadoop3.tgz && \
    tar -xzf spark-3.4.0-bin-hadoop3.tgz && \
    mv spark-3.4.0-bin-hadoop3 $SPARK_HOME && \
    rm spark-3.4.0-bin-hadoop3.tgz

# Installation de Pig
RUN wget https://archive.apache.org/dist/pig/pig-0.17.0/pig-0.17.0.tar.gz && \
    tar -xzf pig-0.17.0.tar.gz && \
    mv pig-0.17.0 /opt/pig && \
    rm pig-0.17.0.tar.gz

ENV PIG_HOME=/opt/pig
ENV PATH=$PATH:$PIG_HOME/bin

# MongoDB Hadoop Connector
RUN wget https://repo1.maven.org/maven2/org/mongodb/mongo-hadoop/mongo-hadoop-core/2.0.2/mongo-hadoop-core-2.0.2.jar -O $HADOOP_HOME/share/hadoop/common/lib/mongo-hadoop-core-2.0.2.jar && \
    wget https://repo1.maven.org/maven2/org/mongodb/mongodb-driver/3.12.11/mongodb-driver-3.12.11.jar -O $HADOOP_HOME/share/hadoop/common/lib/mongodb-driver-3.12.11.jar

# Copie des fichiers de configuration
COPY config/ $HADOOP_HOME/etc/hadoop/
COPY spark-config/ $SPARK_HOME/conf/
COPY start-master.sh /start-master.sh
RUN chmod +x /start-master.sh

EXPOSE 9870 8088 8020 7077 8080

CMD ["/start-master.sh"]