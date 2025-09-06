#!/bin/bash

echo "=== Exécution des analyses Pig ==="

# Vérification que le cluster est démarré
if ! curl -s http://localhost:9870/jmx > /dev/null; then
    echo "Erreur: Le cluster Hadoop n'est pas démarré"
    exit 1
fi

# Copie des scripts Pig
echo "Copie des scripts Pig..."
docker cp pig-scripts/load_and_explore.pig hadoop-master:/tmp/
docker cp pig-scripts/advanced_analysis.pig hadoop-master:/tmp/

# Nettoyage des répertoires de sortie
echo "Nettoyage des répertoires de sortie..."
docker exec hadoop-master hdfs dfs -rm -r -f /output/category_analysis
docker exec hadoop-master hdfs dfs -rm -r -f /output/top_products
docker exec hadoop-master hdfs dfs -rm -r -f /output/regional_analysis
docker exec hadoop-master hdfs dfs -rm -r -f /output/high_value_sales
docker exec hadoop-master hdfs dfs -rm -r -f /output/monthly_analysis
docker exec hadoop-master hdfs dfs -rm -r -f /output/valuable_customers

# Exécution du premier script Pig
echo "Exécution de l'analyse exploratoire..."
docker exec hadoop-master pig -f /tmp/load_and_explore.pig

# Exécution du second script Pig
echo "Exécution de l'analyse avancée..."
docker exec hadoop-master pig -f /tmp/advanced_analysis.pig

# Affichage des résultats
echo "=== Résultats de l'analyse ==="
echo ""
echo "Analyse par catégorie:"
docker exec hadoop-master hdfs dfs -cat /output/category_analysis/part-r-00000

echo ""
echo "Top produits:"
docker exec hadoop-master hdfs dfs -cat /output/top_products/part-r-00000

echo ""
echo "Analyse régionale:"
docker exec hadoop-master hdfs dfs -cat /output/regional_analysis/part-r-00000

echo ""
echo "Ventes importantes:"
docker exec hadoop-master hdfs dfs -cat /output/high_value_sales/part-r-00000

echo "=== Analyse Pig terminée ==="