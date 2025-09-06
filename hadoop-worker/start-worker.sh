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




---

