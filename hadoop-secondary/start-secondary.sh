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
