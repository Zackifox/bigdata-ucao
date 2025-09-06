# Architecture du Système Big Data

## Vue d'ensemble

```mermaid
graph TB
    subgraph "Data Sources"
        CSV[Fichiers CSV]
        MONGO[MongoDB]
        RT[Données Temps Réel]
    end
    
    subgraph "Hadoop Cluster"
        MASTER[Master Node<br/>NameNode + ResourceManager]
        SECONDARY[Secondary Master<br/>Secondary NameNode]
        W1[Worker 1<br/>DataNode + NodeManager]
        W2[Worker 2<br/>DataNode + NodeManager]
        W3[Worker 3<br/>DataNode + NodeManager]
    end
    
    subgraph "Processing Layer"
        SPARK[Spark Cluster]
        PIG[Apache Pig]
        HDFS[HDFS Storage]
    end
    
    subgraph "Application Layer"
        WEBAPP[Application Web Flask]
        DASH[Dashboard Dash]
        API[REST API]
    end
    
    CSV --> HDFS
    MONGO --> SPARK
    RT --> MONGO
    
    MASTER --> W1
    MASTER --> W2
    MASTER --> W3
    SECONDARY --> MASTER
    
    HDFS --> PIG
    HDFS --> SPARK
    SPARK --> HDFS
    PIG --> HDFS
    
    HDFS --> WEBAPP
    MONGO --> WEBAPP
    WEBAPP --> DASH
    WEBAPP --> API