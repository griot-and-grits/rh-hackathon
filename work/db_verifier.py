import psycopg2

DB_CONFIG = {
    "host": "postgres",
    "port": "5432",
    "user": "hackathon",
    "password": "hackathon123",
    "database": "hackathon_db"
}

try:
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM users;")
    rows = cursor.fetchall()
    print(f"Data: {rows}")
    
    conn.close()
except Exception as e:
    print(f"Error: {e}")
