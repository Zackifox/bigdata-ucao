# hadoop-secondary/Dockerfile
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    ssh \
    rsync \
    curl \
    wget \
    netcat \
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

# Copie des fichiers de configuration
COPY config/ $HADOOP_HOME/etc/hadoop/
COPY start-secondary.sh /start-secondary.sh
RUN chmod +x /start-secondary.sh

EXPOSE 9868

CMD ["/start-secondary.sh"]
