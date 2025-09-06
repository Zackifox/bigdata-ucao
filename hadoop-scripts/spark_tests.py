# hadoop-scripts/spark_tests.py
#!/usr/bin/env python3

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *
import os
import time

def test_basic_operations():
    """Test des opérations de base Spark"""
    print("=== Test des opérations de base Spark ===")
    
    spark = SparkSession.builder \
        .appName("Spark-Basic-Tests") \
        .config("spark.sql.adaptive.enabled", "true") \
        .getOrCreate()
    
    # Test 1: Création de DataFrame
    data = [("Alice", 25), ("Bob", 30), ("Carol", 35)]
    schema = ["name", "age"]
    df = spark.createDataFrame(data, schema)
    
    print("DataFrame créé:")
    df.show()
    
    # Test 2: Opérations sur DataFrame
    result = df.filter(df.age > 25).select("name", "age")
    print("Filtrage (age > 25):")
    result.show()
    
    # Test 3: Agrégations
    avg_age = df.agg(avg("age").alias("average_age")).collect()[0]["average_age"]
    print(f"Âge moyen: {avg_age}")
    
    spark.stop()
    print("✓ Tests de base réussis")

def test_hdfs_operations():
    """Test des opérations HDFS"""
    print("\n=== Test des opérations HDFS ===")
    
    spark = SparkSession.builder \
        .appName("Spark-HDFS-Tests") \
        .getOrCreate()
    
    try:
        # Test 1: Lecture depuis HDFS
        df = spark.read \
            .option("header", "true") \
            .option("inferSchema", "true") \
            .csv("hdfs://hadoop-master:8020/data/sales_data.csv")
        
        print("Données lues depuis HDFS:")
        df.show(5)
        print(f"Nombre de lignes: {df.count()}")
        
        # Test 2: Transformations complexes
        sales_summary = df.groupBy("category") \
            .agg(
                count("*").alias("total_orders"),
                sum("quantity").alias("total_quantity"),
                avg("price").alias("avg_price"),
                max("price").alias("max_price")
            ) \
            .orderBy(desc("total_orders"))
        
        print("Résumé des ventes par catégorie:")
        sales_summary.show()
        
        # Test 3: Écriture sur HDFS
        output_path = "hdfs://hadoop-master:8020/spark_tests/sales_summary"
        sales_summary.write \
            .mode("overwrite") \
            .option("header", "true") \
            .csv(output_path)
        
        print(f"✓ Données sauvegardées sur HDFS: {output_path}")
        
        # Test 4: Opérations SQL
        df.createOrReplaceTempView("sales")
        
        sql_result = spark.sql("""
            SELECT region, 
                   COUNT(*) as order_count,
                   SUM(quantity * price) as total_revenue
            FROM sales 
            GROUP BY region 
            ORDER BY total_revenue DESC
        """)
        
        print("Analyse SQL par région:")
        sql_result.show()
        
    except Exception as e:
        print(f"Erreur lors des tests HDFS: {e}")
    finally:
        spark.stop()
    
    print("✓ Tests HDFS terminés")

def test_mongodb_integration():
    """Test de l'intégration MongoDB"""
    print("\n=== Test de l'intégration MongoDB ===")
    
    spark = SparkSession.builder \
        .appName("Spark-MongoDB-Tests") \
        .config("spark.jars.packages", "org.mongodb.spark:mongo-spark-connector_2.12:3.0.1") \
        .getOrCreate()
    
    try:
        # Test 1: Lecture depuis MongoDB
        df_mongo = spark.read \
            .format("com.mongodb.spark.sql.DefaultSource") \
            .option("uri", "mongodb://mongodb:27017/bigdata.sales") \
            .load()
        
        if df_mongo.count() > 0:
            print("Données MongoDB lues avec succès:")
            df_mongo.show(5)
            
            # Test 2: Analyse des données MongoDB
            mongo_analysis = df_mongo.groupBy("category") \
                .agg(
                    count("*").alias("mongo_orders"),
                    sum("total_value").alias("mongo_revenue")
                )
            
            print("Analyse des données MongoDB:")
            mongo_analysis.show()
            
            # Test 3: Jointure avec données HDFS
            df_hdfs = spark.read \
                .option("header", "true") \
                .option("inferSchema", "true") \
                .csv("hdfs://hadoop-master:8020/data/sales_data.csv")
            
            # Agrégation des deux sources
            hdfs_summary = df_hdfs.groupBy("category") \
                .agg(sum(col("quantity") * col("price")).alias("hdfs_revenue"))
            
            combined = mongo_analysis.join(hdfs_summary, "category", "full_outer") \
                .fillna(0) \
                .withColumn("total_combined_revenue", 
                           col("mongo_revenue") + col("hdfs_revenue"))
            
            print("Analyse combinée MongoDB + HDFS:")
            combined.show()
            
        else:
            print("⚠️ Aucune donnée trouvée dans MongoDB")
            
    except Exception as e:
        print(f"Erreur lors des tests MongoDB: {e}")
    finally:
        spark.stop()
    
    print("✓ Tests MongoDB terminés")

def test_streaming_simulation():
    """Test de simulation de streaming"""
    print("\n=== Test de simulation de streaming ===")
    
    spark = SparkSession.builder \
        .appName("Spark-Streaming-Tests") \
        .getOrCreate()
    
    try:
        # Création de données de test pour simulation
        streaming_data = []
        for i in range(100):
            streaming_data.append({
                "timestamp": f"2024-01-{(i % 30) + 1:02d}",
                "product": f"Product_{i % 5}",
                "quantity": (i % 10) + 1,
                "price": round(100 + (i * 3.14) % 500, 2)
            })
        
        # Conversion en DataFrame
        schema = StructType([
            StructField("timestamp", StringType(), True),
            StructField("product", StringType(), True),
            StructField("quantity", IntegerType(), True),
            StructField("price", DoubleType(), True)
        ])
        
        df_stream = spark.createDataFrame(streaming_data, schema)
        
        # Simulation d'analyse temps réel
        df_stream = df_stream.withColumn("total_value", col("quantity") * col("price"))
        
        # Analyse par fenêtre temporelle (simulation)
        window_analysis = df_stream.groupBy("timestamp") \
            .agg(
                count("*").alias("transactions_count"),
                sum("total_value").alias("daily_revenue"),
                avg("total_value").alias("avg_transaction")
            ) \
            .orderBy("timestamp")
        
        print("Simulation d'analyse streaming par jour:")
        window_analysis.show(10)
        
        # Top produits dans la simulation
        product_analysis = df_stream.groupBy("product") \
            .agg(
                sum("quantity").alias("total_sold"),
                sum("total_value").alias("product_revenue")
            ) \
            .orderBy(desc("product_revenue"))
        
        print("Top produits (simulation):")
        product_analysis.show()
        
    except Exception as e:
        print(f"Erreur lors des tests streaming: {e}")
    finally:
        spark.stop()
    
    print("✓ Tests streaming terminés")

def performance_benchmark():
    """Benchmark de performance"""
    print("\n=== Benchmark de performance ===")
    
    spark = SparkSession.builder \
        .appName("Spark-Performance-Benchmark") \
        .config("spark.sql.adaptive.enabled", "true") \
        .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
        .getOrCreate()
    
    try:
        # Génération d'un dataset plus large pour le benchmark
        large_data = []
        for i in range(10000):
            large_data.append({
                "id": i,
                "category": f"Category_{i % 10}",
                "value": (i * 1.23) % 1000,
                "timestamp": f"2024-{(i % 12) + 1:02d}-{(i % 28) + 1:02d}"
            })
        
        df_large = spark.createDataFrame(large_data)
        
        # Test 1: Cache performance
        start_time = time.time()
        df_large.cache()
        df_large.count()  # Action pour déclencher le cache
        cache_time = time.time() - start_time
        
        # Test 2: Agrégations complexes
        start_time = time.time()
        complex_agg = df_large.groupBy("category") \
            .agg(
                count("*").alias("count"),
                sum("value").alias("sum_value"),
                avg("value").alias("avg_value"),
                stddev("value").alias("stddev_value"),
                min("value").alias("min_value"),
                max("value").alias("max_value")
            )
        complex_agg.collect()  # Action pour déclencher le calcul
        agg_time = time.time() - start_time
        
        # Test 3: Jointure avec elle-même (test intensif)
        start_time = time.time()
        df_alias = df_large.alias("a")
        df_alias2 = df_large.alias("b")
        join_result = df_alias.join(df_alias2, 
                                   col("a.category") == col("b.category")) \
                                .select("a.id", "a.category", "b.value")
        join_count = join_result.count()
        join_time = time.time() - start_time
        
        print(f"=== Résultats du benchmark ===")
        print(f"Temps de cache (10k records): {cache_time:.2f}s")
        print(f"Temps d'agrégation complexe: {agg_time:.2f}s")
        print(f"Temps de jointure ({join_count} résultats): {join_time:.2f}s")
        
        # Affichage des métriques Spark
        print(f"\nConfiguration Spark utilisée:")
        print(f"- Adaptive Query Execution: {spark.conf.get('spark.sql.adaptive.enabled')}")
        print(f"- Default Parallelism: {spark.sparkContext.defaultParallelism}")
        
    except Exception as e:
        print(f"Erreur lors du benchmark: {e}")
    finally:
        spark.stop()
    
    print("✓ Benchmark terminé")

def main():
    """Fonction principale pour lancer tous les tests"""
    print("🚀 Démarrage des tests Spark complets")
    print("=" * 50)
    
    try:
        test_basic_operations()
        test_hdfs_operations()
        test_mongodb_integration()
        test_streaming_simulation()
        performance_benchmark()
        
        print("\n" + "=" * 50)
        print("✅ Tous les tests Spark ont été exécutés avec succès!")
        print("=" * 50)
        
    except Exception as e:
        print(f"\n❌ Erreur générale lors des tests: {e}")
        print("=" * 50)

if __name__ == "__main__":
    main()