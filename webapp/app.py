# webapp/app.py - Version simplifiée et robuste
from flask import Flask, render_template, jsonify
import os
import time
from datetime import datetime
import threading

# Import conditionnel pour éviter les erreurs
try:
    import dash
    from dash import dcc, html, Input, Output
    import plotly.express as px
    import plotly.graph_objects as go
    import pandas as pd
    DASH_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Dash/Plotly not available: {e}")
    DASH_AVAILABLE = False

try:
    import pymongo
    MONGODB_AVAILABLE = True
except ImportError as e:
    print(f"Warning: MongoDB not available: {e}")
    MONGODB_AVAILABLE = False

# Configuration Flask
flask_app = Flask(__name__)

# Données simulées pour éviter les dépendances
SAMPLE_DATA = {
    "total_sales": 150,
    "total_revenue": 45230.50,
    "realtime_sales": 23,
    "unique_customers": 42
}

@flask_app.route('/')
def home():
    """Page d'accueil"""
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Big Data Analytics - UCAO</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
            .metric-card {{ 
                background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
                color: white; 
                border-radius: 10px; 
                padding: 20px; 
                margin: 10px;
            }}
            .status-up {{ color: #28a745; }}
            .status-down {{ color: #dc3545; }}
        </style>
    </head>
    <body>
        <nav class="navbar navbar-dark bg-dark">
            <div class="container">
                <a class="navbar-brand" href="#">Big Data Analytics Platform</a>
                <div class="navbar-nav">
                    <a class="nav-link" href="/dashboard">Dashboard</a>
                    <a class="nav-link" href="/api/stats">API Stats</a>
                </div>
            </div>
        </nav>
        
        <div class="container mt-4">
            <h1 class="text-center">🚀 Plateforme Big Data UCAO</h1>
            <p class="text-center text-muted">Système distribué Hadoop + Spark + MongoDB</p>
            
            <div class="row mt-4" id="metrics"></div>
            
            <div class="row mt-4">
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h5>État des Services</h5>
                        </div>
                        <div class="card-body" id="services-status"></div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h5>Actions Rapides</h5>
                        </div>
                        <div class="card-body">
                            <a href="/dashboard" class="btn btn-primary mb-2 d-block">📊 Dashboard Interactif</a>
                            <a href="http://localhost:9870" target="_blank" class="btn btn-success mb-2 d-block">🗄️ Hadoop NameNode</a>
                            <a href="http://localhost:8088" target="_blank" class="btn btn-warning mb-2 d-block">📈 YARN ResourceManager</a>
                            <a href="http://localhost:8080" target="_blank" class="btn btn-info d-block">⚡ Spark Master</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <script>
            function updateDashboard() {{
                // Mise à jour des métriques
                fetch('/api/stats')
                    .then(response => response.json())
                    .then(data => {{
                        document.getElementById('metrics').innerHTML = `
                            <div class="col-md-3">
                                <div class="metric-card text-center">
                                    <h3>${{data.total_sales}}</h3>
                                    <p>Total Ventes</p>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="metric-card text-center">
                                    <h3>${'${data.total_revenue.toFixed(2)}'}</h3>
                                    <p>Chiffre d'Affaires</p>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="metric-card text-center">
                                    <h3>${{data.realtime_sales}}</h3>
                                    <p>Ventes Temps Réel</p>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="metric-card text-center">
                                    <h3>${{data.unique_customers}}</h3>
                                    <p>Clients Uniques</p>
                                </div>
                            </div>
                        `;
                    }})
                    .catch(error => {{
                        document.getElementById('metrics').innerHTML = 
                            '<div class="col-12"><div class="alert alert-warning">Impossible de charger les métriques</div></div>';
                    }});
                
                // Vérification des services
                fetch('/api/hadoop_status')
                    .then(response => response.json())
                    .then(data => {{
                        document.getElementById('services-status').innerHTML = `
                            <p><strong>Hadoop NameNode:</strong> <span class="${{data.namenode === 'UP' ? 'status-up' : 'status-down'}}">${{data.namenode}}</span></p>
                            <p><strong>YARN ResourceManager:</strong> <span class="${{data.resourcemanager === 'UP' ? 'status-up' : 'status-down'}}">${{data.resourcemanager}}</span></p>
                            <p><strong>MongoDB:</strong> <span class="${{data.mongodb === 'UP' ? 'status-up' : 'status-down'}}">${{data.mongodb || 'DOWN'}}</span></p>
                            <small class="text-muted">Dernière mise à jour: ${{new Date().toLocaleTimeString()}}</small>
                        `;
                    }})
                    .catch(error => {{
                        document.getElementById('services-status').innerHTML = 
                            '<p class="text-danger">Erreur de connexion aux services</p>';
                    }});
            }}
            
            // Mise à jour initiale et périodique
            updateDashboard();
            setInterval(updateDashboard, 10000);
        </script>
    </body>
    </html>
    """

@flask_app.route('/api/stats')
def get_stats():
    """API pour récupérer les statistiques"""
    try:
        # Simuler des données avec variation
        import random
        data = SAMPLE_DATA.copy()
        data["total_sales"] += random.randint(-5, 10)
        data["realtime_sales"] = random.randint(15, 35)
        data["timestamp"] = datetime.now().isoformat()
        return jsonify(data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@flask_app.route('/api/hadoop_status')
def hadoop_status():
    """Vérification du statut Hadoop"""
    import requests
    status = {"timestamp": datetime.now().isoformat()}
    
    # Test NameNode
    try:
        response = requests.get("http://hadoop-master:9870/jmx", timeout=3)
        status["namenode"] = "UP" if response.status_code == 200 else "DOWN"
    except:
        status["namenode"] = "DOWN"
    
    # Test ResourceManager
    try:
        response = requests.get("http://hadoop-master:8088/ws/v1/cluster/info", timeout=3)
        status["resourcemanager"] = "UP" if response.status_code == 200 else "DOWN"
    except:
        status["resourcemanager"] = "DOWN"
    
    # Test MongoDB
    if MONGODB_AVAILABLE:
        try:
            client = pymongo.MongoClient("mongodb://mongodb:27017/", serverSelectionTimeoutMS=3000)
            client.admin.command('ping')
            status["mongodb"] = "UP"
            client.close()
        except:
            status["mongodb"] = "DOWN"
    else:
        status["mongodb"] = "NOT_CONFIGURED"
    
    return jsonify(status)

@flask_app.route('/dashboard')
def dashboard():
    """Page dashboard simplifiée"""
    if not DASH_AVAILABLE:
        return """
        <h1>Dashboard Non Disponible</h1>
        <p>Les dépendances Dash/Plotly ne sont pas correctement installées.</p>
        <p><a href="/">Retour à l'accueil</a></p>
        """
    
    return """
    <h1>Dashboard Interactif</h1>
    <p>Fonctionnalité en cours de développement...</p>
    <p><a href="/">Retour à l'accueil</a></p>
    """

@flask_app.route('/health')
def health():
    """Endpoint de santé pour Docker"""
    return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()})

if __name__ == '__main__':
    print("🚀 Démarrage de l'application Big Data UCAO")
    print(f"📊 Dash disponible: {DASH_AVAILABLE}")
    print(f"🍃 MongoDB disponible: {MONGODB_AVAILABLE}")
    
    flask_app.run(
        host='0.0.0.0',
        port=5000,
        debug=True,
        use_reloader=False  # Éviter les problèmes avec Docker
    )