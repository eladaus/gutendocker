#!/bin/bash
set -e

echo "Waiting for postgres..."
while ! pg_isready -h db -U gutendex; do
  sleep 1
done
echo "PostgreSQL started"

echo "Running database migrations..."
python manage.py migrate --noinput

echo "Collecting static files..."
python manage.py collectstatic --noinput

# Check if catalog needs to be populated
# Only run if POPULATE_CATALOG env var is set to "true"
if [ "$POPULATE_CATALOG" = "true" ]; then
    echo "Populating catalog (this will take several minutes)..."
    python manage.py updatecatalog
fi

echo "Starting server..."
exec "$@"
