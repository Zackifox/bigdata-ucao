# hadoop-worker/start-worker.sh
#!/bin/bash

echo "Starting Hadoop Worker Node..."

# Démarrage des services SSH
service ssh start

# Attente que le master soit disponible
echo "Waiting for master node..."
until nc -z hadoop-master 8020; do
    echo "Master node not ready, waiting..."
    sleep 5
done

echo "Master node is ready, starting services..."

# Démarrage du DataNode
$HADOOP_HOME/bin/hdfs --daemon start datanode

# Démarrage du NodeManager
$HADOOP_HOME/bin/yarn --daemon start nodemanager

# Démarrage du Spark Worker
$SPARK_HOME/sbin/start-worker.sh spark://hadoop-master:7077

echo "Worker services started successfully"

# Monitoring des services
while true; do
    # Vérification que les services fonctionnent
    if ! pgrep -f "DataNode" > /dev/null; then
        echo "DataNode stopped, restarting..."
        $HADOOP_HOME/bin/hdfs --daemon start datanode
    fi
    
    if ! pgrep -f "NodeManager" > /dev/null; then
        echo "NodeManager stopped, restarting..."
        $HADOOP_HOME/bin/yarn --daemon start nodemanager
    fi
    
    sleep 30
done

---

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

---

# hadoop-secondary/start-secondary.sh
#!/bin/bash

echo "Starting Hadoop Secondary NameNode..."

# Démarrage des services SSH
service ssh start

# Attente que le master soit disponible
echo "Waiting for master NameNode..."
until nc -z hadoop-master 8020; do
    echo "Master NameNode not ready, waiting..."
    sleep 5
done

echo "Master NameNode is ready, starting Secondary NameNode..."

# Démarrage du Secondary NameNode
$HADOOP_HOME/bin/hdfs --daemon start secondarynamenode

echo "Secondary NameNode started successfully"

# Monitoring du service
while true; do
    if ! pgrep -f "SecondaryNameNode" > /dev/null; then
        echo "Secondary NameNode stopped, restarting..."
        $HADOOP_HOME/bin/hdfs --daemon start secondarynamenode
    fi
    sleep 30
done

---

# scripts/run-spark-tests.sh
#!/bin/bash

echo "=== Exécution des tests Spark ==="

# Vérification que Spark est démarré
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "Erreur: Spark n'est pas démarré"
    exit 1
fi

# Copie du script de test
echo "Copie du script de tests Spark..."
docker cp hadoop-scripts/spark_tests.py hadoop-master:/tmp/

# Installation des dépendances Python
echo "Installation des dépendances..."
docker exec hadoop-master pip3 install pyspark

# Exécution des tests
echo "Lancement des tests Spark..."
docker exec hadoop-master python3 /tmp/spark_tests.py

# Vérification des résultats sur HDFS
echo ""
echo "=== Vérification des résultats sur HDFS ==="
docker exec hadoop-master hdfs dfs -ls /spark_tests/

if docker exec hadoop-master hdfs dfs -test -d /spark_tests/sales_summary; then
    echo "✓ Résultats des tests sauvegardés avec succès"
    echo "Contenu du répertoire de test:"
    docker exec hadoop-master hdfs dfs -ls /spark_tests/sales_summary/
else
    echo "⚠️ Aucun résultat de test trouvé"
fi

echo "=== Tests Spark terminés ==="

---

