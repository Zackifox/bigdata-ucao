#!/bin/bash

echo "=== Exécution de l'analyse MongoDB avec Spark ==="

# Vérification des services
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "Erreur: Spark n'est pas démarré"
    exit 1
fi

# Copie du script Python
echo "Copie du script d'analyse MongoDB..."
docker cp hadoop-scripts/mongodb_reader.py hadoop-master:/tmp/

# Installation des dépendances Python si nécessaire
echo "Installation des dépendances..."
docker exec hadoop-master pip3 install pyspark pymongo

# Exécution de l'analyse
echo "Exécution de l'analyse MongoDB..."
docker exec hadoop-master python3 /tmp/mongodb_reader.py

# Affichage des résultats depuis HDFS
echo "=== Résultats sauvegardés sur HDFS ==="
echo ""
echo "Analyse par catégorie:"
docker exec hadoop-master hdfs dfs -cat /mongodb_analysis/category_analysis/*.csv

echo ""
echo "Analyse régionale:"
docker exec hadoop-master hdfs dfs -cat /mongodb_analysis/regional_analysis/*.csv

echo "=== Analyse MongoDB terminée ==="