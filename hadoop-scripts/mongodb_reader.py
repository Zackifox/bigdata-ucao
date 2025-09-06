#!/usr/bin/env python3

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
import os

def main():
    # Configuration Spark
    spark = SparkSession.builder \
        .appName("MongoDB-Hadoop-Reader") \
        .config("spark.mongodb.input.uri", "mongodb://mongodb:27017/bigdata.sales") \
        .config("spark.mongodb.output.uri", "mongodb://mongodb:27017/bigdata.results") \
        .config("spark.jars.packages", "org.mongodb.spark:mongo-spark-connector_2.12:3.0.1") \
        .getOrCreate()
    
    # Lecture des données depuis MongoDB
    df_sales = spark.read \
        .format("com.mongodb.spark.sql.DefaultSource") \
        .option("database", "bigdata") \
        .option("collection", "sales") \
        .load()
    
    print("=== Données de ventes depuis MongoDB ===")
    df_sales.show()
    
    # Analyses
    print("=== Analyse des ventes par catégorie ===")
    category_analysis = df_sales.groupBy("category") \
        .agg(
            count("*").alias("total_orders"),
            sum("quantity").alias("total_quantity"),
            sum("total_value").alias("total_revenue"),
            avg("price").alias("avg_price")
        )
    
    category_analysis.show()
    
    # Sauvegarde sur HDFS
    category_analysis.write \
        .mode("overwrite") \
        .option("header", "true") \
        .csv("hdfs://hadoop-master:8020/mongodb_analysis/category_analysis")
    
    # Analyse régionale
    print("=== Analyse régionale ===")
    regional_analysis = df_sales.groupBy("region") \
        .agg(
            count("*").alias("orders_count"),
            sum("total_value").alias("total_revenue"),
            avg("total_value").alias("avg_order_value")
        )
    
    regional_analysis.show()
    
    # Sauvegarde sur HDFS
    regional_analysis.write \
        .mode("overwrite") \
        .option("header", "true") \
        .csv("hdfs://hadoop-master:8020/mongodb_analysis/regional_analysis")
    
    # Lecture des données clients
    df_customers = spark.read \
        .format("com.mongodb.spark.sql.DefaultSource") \
        .option("database", "bigdata") \
        .option("collection", "customers") \
        .load()
    
    # Jointure sales-customers
    sales_with_customers = df_sales.join(df_customers, 
                                       df_sales.customer_id == df_customers._id, 
                                       "inner")
    
    print("=== Ventes avec informations clients ===")
    sales_with_customers.select("date", "product", "quantity", "price", 
                               "name", "email", "city").show()
    
    # Analyse par ville
    city_analysis = sales_with_customers.groupBy("city") \
        .agg(
            count("*").alias("total_orders"),
            sum("total_value").alias("city_revenue")
        ) \
        .orderBy(desc("city_revenue"))
    
    print("=== Top villes par chiffre d'affaires ===")
    city_analysis.show()
    
    spark.stop()

if __name__ == "__main__":
    main()