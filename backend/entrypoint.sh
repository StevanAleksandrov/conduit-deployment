#!/bin/sh
set -e

echo "Waiting for database..."
python <<EOF
import os
import time
import psycopg2

host = os.environ.get("POSTGRES_HOST", "database")
port = os.environ.get("POSTGRES_PORT", "5432")
dbname = os.environ.get("POSTGRES_DB")
user = os.environ.get("POSTGRES_USER")
password = os.environ.get("POSTGRES_PASSWORD")

while True:
    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            dbname=dbname,
            user=user,
            password=password,
        )
        conn.close()
        print("Database is ready.")
        break
    except Exception as error:
        print("Database is not ready yet. Waiting...")
        time.sleep(2)
EOF

echo "Applying database migrations..."
python manage.py migrate --noinput

echo "Collecting static files..."
python manage.py collectstatic --noinput

if [ -n "${DJANGO_SUPERUSER_USERNAME}" ] && \
   [ -n "${DJANGO_SUPERUSER_EMAIL}" ] && \
   [ -n "${DJANGO_SUPERUSER_PASSWORD}" ]; then
  echo "Ensuring Django superuser exists..."
  python <<EOF
import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "conduit.settings")

import django
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()
username = os.environ.get("DJANGO_SUPERUSER_USERNAME")
email = os.environ.get("DJANGO_SUPERUSER_EMAIL")
password = os.environ.get("DJANGO_SUPERUSER_PASSWORD")

if username and email and password:
    if not User.objects.filter(username=username).exists():
        User.objects.create_superuser(username=username, email=email, password=password)
EOF
fi

echo "Starting Gunicorn WSGI server..."
exec gunicorn conduit.wsgi:application --bind 0.0.0.0:8000