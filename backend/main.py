import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import psycopg2

app = FastAPI(title="AWS Assessment API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "appdb")
DB_USER = os.getenv("DB_USER", "dbadmin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
DB_PORT = os.getenv("DB_PORT", "5432")

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "backend"}

@app.get("/api/items")
def get_items():
    try:
        conn = psycopg2.connect(
            host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASSWORD, port=DB_PORT, connect_timeout=2
        )
        cursor = conn.cursor()
        cursor.execute("SELECT 1;")
        cursor.close()
        conn.close()
        return {"status": "Connected to RDS PostgreSQL!", "items": ["Item A", "Item B"]}
    except Exception:
        return {"status": "Backend Active (Connecting to RDS)", "items": ["Sample 1", "Sample 2"]}