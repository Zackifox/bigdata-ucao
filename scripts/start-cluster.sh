#!/bin/bash

echo "=== Démarrage du cluster Big Data ==="

# Vérification de Docker
if ! command -v docker &> /dev/null; then
    echo "Docker n'est pas installé. Installation requise."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose n'est pas installé. Installation requise."
    exit 1
fi

# Nettoyage des conteneurs existants
echo "Arrêt des conteneurs existants..."
docker-compose down -v

# Construction et démarrage
echo "Construction des images Docker..."
docker-compose build

echo "Démarrage des services..."
docker-compose up -d

# Attente du démarrage
echo "Attente du démarrage des services..."
sleep 30

# Vérification des services
echo "=== Vérification des services ==="

# MongoDB
echo "Vérification de MongoDB..."
until docker exec mongodb mongosh --eval "db.runCommand('ping').ok" --quiet; do
    echo "Attente de MongoDB..."
    sleep 5
done
echo "✓ MongoDB opérationnel"

# Hadoop NameNode
echo "Vérification du NameNode..."
until curl -s http://localhost:9870/jmx > /dev/null; do
    echo "Attente du NameNode..."
    sleep 5
done
echo "✓ NameNode opérationnel"

# YARN ResourceManager
echo "Vérification de YARN..."
until curl -s http://localhost:8088/ws/v1/cluster/info > /dev/null; do
    echo "Attente de YARN..."
    sleep 5
done
echo "✓ YARN opérationnel"

# Spark Master
echo "Vérification de Spark..."
until curl -s http://localhost:8080 > /dev/null; do
    echo "Attente de Spark..."
    sleep 5
done
echo "✓ Spark opérationnel"

echo "=== Initialisation des données ==="

# Création des répertoires HDFS
echo "Création des répertoires HDFS..."
docker exec hadoop-master hdfs dfs -mkdir -p /data
docker exec hadoop-master hdfs dfs -mkdir -p /output
docker exec hadoop-master hdfs dfs -mkdir -p /mongodb_analysis
docker exec hadoop-master hdfs dfs -mkdir -p /pig_output

# Copie des données de test
echo "Copie des données de test..."
docker exec hadoop-master hdfs dfs -put /data/sales_data.csv /data/

echo "=== Cluster Big Data démarré avec succès! ==="
echo ""
echo "Services disponibles:"
echo "- Application Web: http://localhost:5000"
echo "- Dashboard: http://localhost:5000/dashboard/"
echo "- Hadoop NameNode: http://localhost:9870"
echo "- YARN ResourceManager: http://localhost:8088"
echo "- Spark Master: http://localhost:8080"
echo "- MongoDB: localhost:27017"
echo ""
echo "Pour exécuter les analyses:"
echo "1. Scripts Pig: ./scripts/run-pig-analysis.sh"
echo "2. Lecture MongoDB: ./scripts/run-mongodb-analysis.sh"
echo "3. Tests Spark: ./scripts/run-spark-tests.sh"