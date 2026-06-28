import os
import time
from typing import List

import psycopg
from prometheus_fastapi_instrumentator import Instrumentator
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://app_user:app_password@postgres:5432/platform_lab",
)

app = FastAPI(title="Platform Reliability Lab API")

Instrumentator().instrument(app).expose(app, endpoint="/metrics")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_connection():
    return psycopg.connect(DATABASE_URL)


def initialize_database():
    retries = 10

    for attempt in range(1, retries + 1):
        try:
            with get_connection() as connection:
                with connection.cursor() as cursor:
                    cursor.execute(
                        """
                        CREATE TABLE IF NOT EXISTS tasks (
                            id SERIAL PRIMARY KEY,
                            title TEXT NOT NULL,
                            completed BOOLEAN DEFAULT FALSE
                        );
                        """
                    )

                    cursor.execute("SELECT COUNT(*) FROM tasks;")
                    task_count = cursor.fetchone()[0]

                    if task_count == 0:
                        cursor.execute(
                            """
                            INSERT INTO tasks (title, completed)
                            VALUES
                                ('Build Docker images', TRUE),
                                ('Run app with Docker Compose', FALSE),
                                ('Prepare for Kubernetes deployment', FALSE);
                            """
                        )

                    connection.commit()

            print("Database initialized successfully.")
            return

        except Exception as error:
            print(f"Database initialization attempt {attempt} failed: {error}")
            time.sleep(3)

    raise RuntimeError("Could not initialize database after multiple attempts.")


@app.on_event("startup")
def startup_event():
    initialize_database()


@app.get("/api/health")
def health_check():
    return {
        "status": "ok",
        "service": "backend",
    }


@app.get("/api/db")
def database_check():
    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT version();")
                version = cursor.fetchone()[0]

        return {
            "status": "ok",
            "database": "connected",
            "version": version,
        }

    except Exception as error:
        return {
            "status": "error",
            "database": "unreachable",
            "error": str(error),
        }


@app.get("/api/tasks")
def list_tasks():
    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT id, title, completed
                FROM tasks
                ORDER BY id;
                """
            )

            rows = cursor.fetchall()

    tasks: List[dict] = [
        {
            "id": row[0],
            "title": row[1],
            "completed": row[2],
        }
        for row in rows
    ]

    return {
        "tasks": tasks,
    }