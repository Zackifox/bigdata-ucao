# scripts/monitor-cluster.sh
#!/bin/bash

echo "=== Monitoring du cluster Big Data ==="

check_service() {
    local service_name=$1
    local url=$2
    local container=$3
    
    if curl -s --max-time 5 "$url" > /dev/null 2>&1; then
        echo "✅ $service_name: UP"
        return 0
    else
        echo "❌ $service_name: DOWN"
        if [ ! -z "$container" ]; then
            echo "   Logs du conteneur $container:"
            docker logs --tail 5 "$container" 2>/dev/null || echo "   Impossible de récupérer les logs"
        fi
        return 1
    fi
}

check_container() {
    local container_name=$1
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name.*Up"; then
        echo "✅ Conteneur $container_name: Running"
        return 0
    else
        echo "❌ Conteneur $container_name: Stopped"
        return 1
    fi
}

echo "--- État des conteneurs ---"
check_container "hadoop-master"
check_container "hadoop-secondary"
check_container "hadoop-worker1"
check_container "hadoop-worker2" 
check_container "hadoop-worker3"
check_container "mongodb"
check_container "webapp"

echo ""
echo "--- État des services ---"
check_service "Hadoop NameNode" "http://localhost:9870/jmx" "hadoop-master"
check_service "YARN ResourceManager" "http://localhost:8088/ws/v1/cluster/info" "hadoop-master"
check_service "Spark Master" "http://localhost:8080" "hadoop-master"
check_service "Secondary NameNode" "http://localhost:9868" "hadoop-secondary"
check_service "Application Web" "http://localhost:5000" "webapp"

echo ""
echo "--- Test de connectivité MongoDB ---"
if docker exec mongodb mongosh --eval "db.runCommand('ping').ok" --quiet 2>/dev/null; then
    echo "✅ MongoDB: UP"
else
    echo "❌ MongoDB: DOWN"
fi

echo ""
echo "--- Statistiques HDFS ---"
if docker exec hadoop-master hdfs dfsadmin -report 2>/dev/null | head -10; then
    echo "✅ Rapport HDFS généré"
else
    echo "❌ Impossible de générer le rapport HDFS"
fi

echo ""
echo "--- Statut des DataNodes ---"
docker exec hadoop-master hdfs dfsadmin -printTopology 2>/dev/null || echo "❌ Impossible de récupérer la topologie"

echo ""
echo "--- Applications YARN actives ---"
docker exec hadoop-master yarn application -list -appStates RUNNING 2>/dev/null || echo "❌ Impossible de lister les applications YARN"

echo ""
echo "--- Workers Spark connectés ---"
curl -s http://localhost:8080/json/ | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    workers = data.get('workers', [])
    print(f'Nombre de workers Spark: {len(workers)}')
    for worker in workers:
        print(f'  - {worker[\"host\"]}:{worker[\"port\"]} ({worker[\"state\"]})')
except:
    print('❌ Impossible de récupérer les informations Spark')
" 2>/dev/null

echo ""
echo "=== Fin du monitoring ==="