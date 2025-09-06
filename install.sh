#!/bin/bash

# install.sh - Script d'installation complète du projet Big Data UCAO
# Auteur: NGOMDJIBAYE David étudiant Master 1 Bigdata UCAO 2024-2025
# Date: Août 2025

set -e  # Arrêt en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification de l'OS
check_os() {
    print_status "Vérification du système d'exploitation..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        print_success "Linux détecté"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_success "macOS détecté"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        print_success "Windows détecté"
    else
        print_error "Système d'exploitation non supporté: $OSTYPE"
        exit 1
    fi
}

# Vérification des prérequis
check_prerequisites() {
    print_status "Vérification des prérequis..."
    
    # Vérification Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker n'est pas installé"
        print_status "Installation de Docker..."
        install_docker
    else
        print_success "Docker trouvé: $(docker --version)"
    fi
    
    # Vérification Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose n'est pas installé"
        print_status "Installation de Docker Compose..."
        install_docker_compose
    else
        print_success "Docker Compose trouvé: $(docker-compose --version)"
    fi
    
    # Vérification que Docker fonctionne
    if ! docker ps &> /dev/null; then
        print_error "Docker n'est pas démarré ou accessible"
        print_status "Tentative de démarrage de Docker..."
        start_docker
    else
        print_success "Docker est opérationnel"
    fi
    
    # Vérification des ports
    check_ports
    
    # Vérification de l'espace disque
    check_disk_space
}

# Installation de Docker selon l'OS
install_docker() {
    case $OS in
        "linux")
            if command -v apt-get &> /dev/null; then
                # Ubuntu/Debian
                sudo apt-get update
                sudo apt-get install -y ca-certificates curl gnupg lsb-release
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io
                sudo usermod -aG docker $USER
            elif command -v yum &> /dev/null; then
                # CentOS/RHEL
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install -y docker-ce docker-ce-cli containerd.io
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker $USER
            fi
            ;;
        "macos")
            print_warning "Veuillez installer Docker Desktop pour macOS depuis https://docs.docker.com/docker-for-mac/install/"
            exit 1
            ;;
        "windows")
            print_warning "Veuillez installer Docker Desktop pour Windows depuis https://docs.docker.com/docker-for-windows/install/"
            exit 1
            ;;
    esac
}

# Installation de Docker Compose
install_docker_compose() {
    case $OS in
        "linux")
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        "macos"|"windows")
            print_success "Docker Compose est inclus avec Docker Desktop"
            ;;
    esac
}

# Démarrage de Docker
start_docker() {
    case $OS in
        "linux")
            sudo systemctl start docker
            sudo systemctl enable docker
            ;;
        "macos"|"windows")
            print_warning "Veuillez démarrer Docker Desktop manuellement"
            read -p "Appuyez sur Entrée quand Docker Desktop est démarré..."
            ;;
    esac
}

# Vérification des ports
check_ports() {
    print_status "Vérification de la disponibilité des ports..."
    
    REQUIRED_PORTS=(5000 8050 8080 8088 9870 9868 27017)
    UNAVAILABLE_PORTS=()
    
    for port in "${REQUIRED_PORTS[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            UNAVAILABLE_PORTS+=($port)
        fi
    done
    
    if [ ${#UNAVAILABLE_PORTS[@]} -ne 0 ]; then
        print_warning "Ports déjà utilisés: ${UNAVAILABLE_PORTS[*]}"
        print_warning "Ces services peuvent être arrêtés lors du déploiement"
        read -p "Continuer quand même? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Tous les ports requis sont disponibles"
    fi
}

# Vérification de l'espace disque
check_disk_space() {
    print_status "Vérification de l'espace disque..."
    
    # Espace requis en MB
    REQUIRED_SPACE=10240  # 10GB
    
    if command -v df &> /dev/null; then
        AVAILABLE_SPACE=$(df / | tail -1 | awk '{print $4}')
        
        if [ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]; then
            print_warning "Espace disque faible: $(($AVAILABLE_SPACE/1024))MB disponible, $(($REQUIRED_SPACE/1024))MB requis"
            read -p "Continuer quand même? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            print_success "Espace disque suffisant: $(($AVAILABLE_SPACE/1024))MB disponible"
        fi
    fi
}

# Création de la structure du projet
create_project_structure() {
    print_status "Création de la structure du projet..."
    
    # Création des répertoires
    mkdir -p {hadoop-master,hadoop-secondary,hadoop-worker,webapp,pig-scripts,hadoop-scripts,scripts,data,mongodb-init}
    mkdir -p hadoop-master/config
    mkdir -p hadoop-master/spark-config
    mkdir -p hadoop-secondary/config
    mkdir -p hadoop-worker/{config,spark-config}
    mkdir -p webapp/templates
    
    print_success "Structure de répertoires créée"
}

# Génération des fichiers de configuration
generate_config_files() {
    print_status "Génération des fichiers de configuration Hadoop..."
    
    # Configuration commune pour tous les nœuds
    for node_dir in hadoop-master hadoop-secondary hadoop-worker; do
        # core-site.xml
        cat > ${node_dir}/config/core-site.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://hadoop-master:8020</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/hadoop/data</value>
    </property>
</configuration>
EOF

        # hdfs-site.xml
        cat > ${node_dir}/config/hdfs-site.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/opt/hadoop/data/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/opt/hadoop/data/datanode</value>
    </property>
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>hadoop-secondary:9868</value>
    </property>
</configuration>
EOF

        # yarn-site.xml
        cat > ${node_dir}/config/yarn-site.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>hadoop-master</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>2048</value>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>2048</value>
    </property>
</configuration>
EOF

        # mapred-site.xml
        cat > ${node_dir}/config/mapred-site.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
EOF

        # workers (seulement pour master)
        if [ "$node_dir" = "hadoop-master" ]; then
            cat > ${node_dir}/config/workers << 'EOF'
hadoop-worker1
hadoop-worker2
hadoop-worker3
EOF
        fi
    done
    
    # Configuration Spark
    for spark_dir in hadoop-master hadoop-worker; do
        mkdir -p ${spark_dir}/spark-config
        
        cat > ${spark_dir}/spark-config/spark-defaults.conf << 'EOF'
spark.master                     spark://hadoop-master:7077
spark.eventLog.enabled           true
spark.eventLog.dir               hdfs://hadoop-master:8020/spark-logs
spark.history.fs.logDirectory    hdfs://hadoop-master:8020/spark-logs
spark.sql.warehouse.dir          hdfs://hadoop-master:8020/spark-warehouse
EOF

        cat > ${spark_dir}/spark-config/spark-env.sh << 'EOF'
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export SPARK_MASTER_HOST=hadoop-master
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080
EOF
    done
    
    print_success "Fichiers de configuration générés"
}

# Génération des données de test
generate_test_data() {
    print_status "Génération des données de test..."
    
    # Données CSV de vente
    cat > data/sales_data.csv << 'EOF'
date,product,category,quantity,price,customer_id,region
2024-01-15,Laptop,Electronics,2,1200.00,C001,North
2024-01-16,Phone,Electronics,1,800.00,C002,South
2024-01-17,Tablet,Electronics,3,500.00,C003,East
2024-01-18,Chair,Furniture,4,150.00,C004,West
2024-01-19,Desk,Furniture,1,300.00,C005,North
2024-01-20,Book,Education,10,25.00,C006,South
2024-01-21,Laptop,Electronics,1,1200.00,C007,East
2024-01-22,Phone,Electronics,2,800.00,C008,West
2024-01-23,Monitor,Electronics,1,400.00,C009,North
2024-01-24,Chair,Furniture,2,150.00,C010,South
EOF
    
    # Script d'initialisation MongoDB
    cat > mongodb-init/init.js << 'EOF'
db = db.getSiblingDB('bigdata');

db.sales.insertMany([
    {
        "_id": ObjectId(),
        "date": "2024-01-15",
        "product": "Laptop",
        "category": "Electronics",
        "quantity": 2,
        "price": 1200.00,
        "customer_id": "C001",
        "region": "North",
        "total_value": 2400.00
    },
    {
        "_id": ObjectId(),
        "date": "2024-01-16",
        "product": "Phone",
        "category": "Electronics",
        "quantity": 1,
        "price": 800.00,
        "customer_id": "C002",
        "region": "South",
        "total_value": 800.00
    },
    {
        "_id": ObjectId(),
        "date": "2024-01-17",
        "product": "Tablet",
        "category": "Electronics",
        "quantity": 3,
        "price": 500.00,
        "customer_id": "C003",
        "region": "East",
        "total_value": 1500.00
    }
]);

db.customers.insertMany([
    {
        "_id": "C001",
        "name": "Alice Johnson",
        "email": "alice@example.com",
        "age": 28,
        "city": "New York"
    },
    {
        "_id": "C002",
        "name": "Bob Smith",
        "email": "bob@example.com",
        "age": 34,
        "city": "Miami"
    },
    {
        "_id": "C003",
        "name": "Carol Davis",
        "email": "carol@example.com",
        "age": 29,
        "city": "Boston"
    }
]);

db.sales.createIndex({"customer_id": 1});
db.sales.createIndex({"date": 1});
db.sales.createIndex({"category": 1});
EOF

    print_success "Données de test générées"
}

# Fonction principale d'installation
main() {
    echo "=================================================="
    echo "  Installation Projet Big Data - UCAO 2024-2025"
    echo "=================================================="
    echo
    
    check_os
    check_prerequisites
    create_project_structure
    generate_config_files
    generate_test_data
    
    print_success "Installation terminée avec succès!"
    echo
    echo "Prochaines étapes:"
    echo "1. Copier les Dockerfiles depuis les artifacts fournis"
    echo "2. Copier les scripts depuis les artifacts fournis"
    echo "3. Exécuter: ./scripts/start-cluster.sh"
    echo
    echo "URLs d'accès une fois démarré:"
    echo "- Application Web: http://localhost:5000"
    echo "- Dashboard: http://localhost:5000/dashboard/"
    echo "- Hadoop NameNode: http://localhost:9870"
    echo "- YARN ResourceManager: http://localhost:8088"
    echo "- Spark Master: http://localhost:8080"
    echo
}

# Point d'entrée
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi