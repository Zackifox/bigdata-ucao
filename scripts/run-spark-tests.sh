
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
