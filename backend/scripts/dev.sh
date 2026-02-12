#!/usr/bin/env bash
set -euo pipefail

cd /app

if [[ ! -f /app/manage.py ]]; then
  echo "No existe /app/manage.py todavía."
  echo "Crea el proyecto Django, por ejemplo:"
  echo "  docker compose -f infra/docker-compose.yml run --rm maxpeed_backend django-admin startproject config /app"
  echo "Contenedor en espera para evitar reinicio en bucle..."
  exec sleep infinity
fi

python manage.py migrate --noinput

python manage.py shell -c "
from django.contrib.auth import get_user_model
import os
User = get_user_model()
u = os.environ.get('DJANGO_SUPERUSER_USERNAME')
e = os.environ.get('DJANGO_SUPERUSER_EMAIL')
p = os.environ.get('DJANGO_SUPERUSER_PASSWORD')
if u and p and not User.objects.filter(username=u).exists():
    User.objects.create_superuser(username=u, email=e or '', password=p)
    print('Superuser created:', u)
else:
    print('Superuser already exists or env missing')
"

export DJANGO_WSGI_MODULE="${DJANGO_WSGI_MODULE:-config.wsgi}"
export GUNICORN_WORKERS="${GUNICORN_WORKERS:-2}"
export GUNICORN_THREADS="${GUNICORN_THREADS:-2}"

exec gunicorn "$DJANGO_WSGI_MODULE:application" \
  --bind 0.0.0.0:8000 \
  --workers "$GUNICORN_WORKERS" \
  --threads "$GUNICORN_THREADS" \
  --reload
