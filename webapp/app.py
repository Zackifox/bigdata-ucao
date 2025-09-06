from flask import Flask, render_template, jsonify
import dash
from dash import dcc, html, Input, Output, dash_table
import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
import pymongo
import threading
import time
from datetime import datetime, timedelta
import requests
import json

# Configuration Flask
flask_app = Flask(__name__)

# Configuration MongoDB
mongo_client = pymongo.MongoClient("mongodb://mongodb:27017/")
db = mongo_client.bigdata

# Configuration Dash
dash_app = dash.Dash(__name__, server=flask_app, url_base_pathname='/dashboard/')
dash_app.layout = html.Div([
    dcc.Location(id='url', refresh=False),
    html.Div(id='page-content')
])

# Données simulées en temps réel
def generate_real_time_data():
    """Génère des données en temps réel pour la simulation"""
    import random
    products = ["Laptop", "Phone", "Tablet", "Chair", "Desk", "Book"]
    categories = ["Electronics", "Furniture", "Education"]
    regions = ["North", "South", "East", "West"]
    
    while True:
        # Génération d'une nouvelle vente
        new_sale = {
            "timestamp": datetime.now(),
            "product": random.choice(products),
            "category": random.choice(categories),
            "quantity": random.randint(1, 5),
            "price": round(random.uniform(25, 1200), 2),
            "region": random.choice(regions),
            "customer_id": f"C{random.randint(100, 999)}"
        }
        
        # Insertion en MongoDB
        try:
            db.realtime_sales.insert_one(new_sale)
        except:
            pass
        
        time.sleep(10)  # Nouvelle vente toutes les 10 secondes

# Démarrage du générateur de données en arrière-plan
threading.Thread(target=generate_real_time_data, daemon=True).start()

# Routes Flask
@flask_app.route('/')
def home():
    return render_template('index.html')

@flask_app.route('/api/stats')
def get_stats():
    """API pour récupérer les statistiques"""
    try:
        # Stats depuis MongoDB
        total_sales = db.sales.count_documents({})
        total_revenue = list(db.sales.aggregate([
            {"$group": {"_id": None, "total": {"$sum": "$total_value"}}}
        ]))[0]['total'] if total_sales > 0 else 0
        
        # Stats temps réel
        realtime_count = db.realtime_sales.count_documents({})
        
        return jsonify({
            "total_sales": total_sales,
            "total_revenue": total_revenue,
            "realtime_sales": realtime_count,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({"error": str(e)})

@flask_app.route('/api/hadoop_status')
def hadoop_status():
    """Vérification du statut Hadoop"""
    try:
        # Vérification du NameNode
        namenode_response = requests.get("http://hadoop-master:9870/jmx", timeout=5)
        namenode_status = "UP" if namenode_response.status_code == 200 else "DOWN"
        
        # Vérification du ResourceManager
        rm_response = requests.get("http://hadoop-master:8088/ws/v1/cluster/info", timeout=5)
        rm_status = "UP" if rm_response.status_code == 200 else "DOWN"
        
        return jsonify({
            "namenode": namenode_status,
            "resourcemanager": rm_status,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            "namenode": "DOWN",
            "resourcemanager": "DOWN",
            "error": str(e)
        })

# Layout Dash
def get_dashboard_layout():
    return html.Div([
        html.H1("Big Data Analytics Dashboard", className="text-center mb-4"),
        
        dcc.Interval(
            id='interval-component',
            interval=5000,  # Mise à jour toutes les 5 secondes
            n_intervals=0
        ),
        
        # Métriques en temps réel
        html.Div(id="metrics-cards", className="row mb-4"),
        
        # Graphiques
        html.Div([
            html.Div([
                dcc.Graph(id="sales-by-category")
            ], className="col-md-6"),
            
            html.Div([
                dcc.Graph(id="sales-timeline")
            ], className="col-md-6")
        ], className="row mb-4"),
        
        html.Div([
            html.Div([
                dcc.Graph(id="regional-analysis")
            ], className="col-md-6"),
            
            html.Div([
                dcc.Graph(id="realtime-sales")
            ], className="col-md-6")
        ], className="row mb-4"),
        
        # Tableau des données récentes
        html.Div([
            html.H3("Ventes récentes", className="mb-3"),
            html.Div(id="recent-sales-table")
        ], className="mb-4")
    ], className="container-fluid")

@dash_app.callback(
    [Output('page-content', 'children')],
    [Input('url', 'pathname')]
)
def display_page(pathname):
    return [get_dashboard_layout()]

@dash_app.callback(
    [Output('metrics-cards', 'children'),
     Output('sales-by-category', 'figure'),
     Output('sales-timeline', 'figure'),
     Output('regional-analysis', 'figure'),
     Output('realtime-sales', 'figure'),
     Output('recent-sales-table', 'children')],
    [Input('interval-component', 'n_intervals')]
)
def update_dashboard(n):
    # Récupération des données MongoDB
    try:
        # Données historiques
        sales_data = list(db.sales.find())
        df_sales = pd.DataFrame(sales_data)
        
        # Données temps réel (dernières 24h)
        yesterday = datetime.now() - timedelta(days=1)
        realtime_data = list(db.realtime_sales.find({"timestamp": {"$gte": yesterday}}))
        df_realtime = pd.DataFrame(realtime_data)
        
        # Métriques
        total_sales = len(sales_data)
        total_revenue = df_sales['total_value'].sum() if not df_sales.empty else 0
        realtime_count = len(realtime_data)
        
        metrics_cards = html.Div([
            html.Div([
                html.Div([
                    html.H4(f"{total_sales}", className="card-title"),
                    html.P("Total des ventes", className="card-text")
                ], className="card-body")
            ], className="card bg-primary text-white col-md-3"),
            
            html.Div([
                html.Div([
                    html.H4(f"${total_revenue:,.2f}", className="card-title"),
                    html.P("Chiffre d'affaires", className="card-text")
                ], className="card-body")
            ], className="card bg-success text-white col-md-3"),
            
            html.Div([
                html.Div([
                    html.H4(f"{realtime_count}", className="card-title"),
                    html.P("Ventes temps réel (24h)", className="card-text")
                ], className="card-body")
            ], className="card bg-info text-white col-md-3"),
            
            html.Div([
                html.Div([
                    html.H4(f"{df_sales['customer_id'].nunique() if not df_sales.empty else 0}", className="card-title"),
                    html.P("Clients uniques", className="card-text")
                ], className="card-body")
            ], className="card bg-warning text-white col-md-3")
        ], className="row")
        
        # Graphique ventes par catégorie
        if not df_sales.empty:
            category_sales = df_sales.groupby('category')['total_value'].sum().reset_index()
            fig_category = px.pie(category_sales, values='total_value', names='category',
                                title="Répartition des ventes par catégorie")
        else:
            fig_category = px.pie(title="Aucune donnée disponible")
        
        # Timeline des ventes
        if not df_sales.empty:
            df_sales['date'] = pd.to_datetime(df_sales['date'])
            daily_sales = df_sales.groupby('date')['total_value'].sum().reset_index()
            fig_timeline = px.line(daily_sales, x='date', y='total_value',
                                 title="Évolution des ventes dans le temps")
        else:
            fig_timeline = px.line(title="Aucune donnée disponible")
        
        # Analyse régionale
        if not df_sales.empty:
            regional_sales = df_sales.groupby('region')['total_value'].sum().reset_index()
            fig_regional = px.bar(regional_sales, x='region', y='total_value',
                                title="Ventes par région")
        else:
            fig_regional = px.bar(title="Aucune donnée disponible")
        
        # Ventes temps réel
        if not df_realtime.empty:
            df_realtime['hour'] = df_realtime['timestamp'].dt.hour
            hourly_sales = df_realtime.groupby('hour').size().reset_index(name='count')
            fig_realtime = px.bar(hourly_sales, x='hour', y='count',
                                title="Ventes par heure (dernières 24h)")
        else:
            fig_realtime = px.bar(title="Aucune donnée temps réel")
        
        # Tableau des ventes récentes
        if not df_realtime.empty:
            recent_sales = df_realtime.tail(10)[['timestamp', 'product', 'category', 'quantity', 'price', 'region']]
            table = dash_table.DataTable(
                data=recent_sales.to_dict('records'),
                columns=[{"name": i, "id": i} for i in recent_sales.columns],
                style_table={'overflowX': 'auto'},
                style_cell={'textAlign': 'left'}
            )
        else:
            table = html.P("Aucune vente récente")
        
        return metrics_cards, fig_category, fig_timeline, fig_regional, fig_realtime, table
        
    except Exception as e:
        # En cas d'erreur, retourner des éléments par défaut
        error_card = html.Div([
            html.Div([
                html.H4("Erreur", className="card-title"),
                html.P(str(e), className="card-text")
            ], className="card-body")
        ], className="card bg-danger text-white")
        
        empty_fig = px.bar(title="Données indisponibles")
        
        return error_card, empty_fig, empty_fig, empty_fig, empty_fig, html.P("Erreur de chargement")

if __name__ == '__main__':
    flask_app.run(host='0.0.0.0', port=5000, debug=True)