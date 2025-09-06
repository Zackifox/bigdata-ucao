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
