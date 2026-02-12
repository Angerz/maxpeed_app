#!/usr/bin/env bash
set -euo pipefail

cd /app

if [[ ! -f /app/manage.py ]]; then
  echo "Error: no existe /app/manage.py. No se puede iniciar en modo producción."
  exit 1
fi

python manage.py migrate --noinput
python manage.py collectstatic --noinput

export DJANGO_WSGI_MODULE="${DJANGO_WSGI_MODULE:-config.wsgi}"
export GUNICORN_WORKERS="${GUNICORN_WORKERS:-3}"
export GUNICORN_THREADS="${GUNICORN_THREADS:-2}"
export GUNICORN_TIMEOUT="${GUNICORN_TIMEOUT:-60}"

exec gunicorn "$DJANGO_WSGI_MODULE:application" \
  --bind 0.0.0.0:8000 \
  --workers "$GUNICORN_WORKERS" \
  --threads "$GUNICORN_THREADS" \
  --timeout "$GUNICORN_TIMEOUT"
