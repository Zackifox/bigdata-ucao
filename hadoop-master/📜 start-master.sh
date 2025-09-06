#!/bin/bash

# Démarrage des services SSH
service ssh start

# Formatage du NameNode (seulement la première fois)
if [ ! -d "/opt/hadoop/data/namenode" ]; then
    $HADOOP_HOME/bin/hdfs namenode -format -force
fi

# Démarrage de Hadoop
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

# Démarrage de Spark
$SPARK_HOME/sbin/start-master.sh

# Attente indéfinie
tail -f /dev/null