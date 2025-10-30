# Gutendex Docker Setup

This Docker configuration bundles the Gutendex application with all its dependencies into containers.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+

## Quick Start

### 1. Clone the Gutendex Repository

```bash
git clone https://github.com/garethbjohnson/gutendex.git
cd gutendex
```

### 2. Copy Docker Files

Copy these files to the Gutendex root directory:
- `Dockerfile`
- `docker-compose.yml`
- `docker-entrypoint.sh`
- `.dockerignore`

### 3. Update requirements.txt

Add gunicorn to your `requirements.txt`:
```bash
echo "gunicorn==21.2.0" >> requirements.txt
```

### 4. Configure Environment Variables

Copy the example environment file:
```bash
cp .env.docker.example .env
```

Edit `.env` and update these critical values:
- `SECRET_KEY`: Generate a random secret key
- `DATABASE_PASSWORD`: Change from default
- `ALLOWED_HOSTS`: Add your domain(s)
- Email settings (if you want email functionality)

To generate a secret key, you can use:
```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### 5. Build and Start the Containers

```bash
docker-compose up -d
```

This will:
- Build the Gutendex Docker image
- Start a PostgreSQL 16 database
- Run database migrations
- Collect static files
- Start the Gunicorn web server

### 6. Populate the Catalog (First Time Only)

The first time you set up Gutendex, you need to populate the catalog. This takes several minutes:

```bash
docker-compose exec web python manage.py updatecatalog
```

Alternatively, you can set `POPULATE_CATALOG=true` in your `.env` file before the first startup.

### 7. Access the Application

The application will be available at:
- http://localhost:8000

## Daily Catalog Updates

To keep your catalog up-to-date, schedule this command to run daily:

```bash
docker-compose exec web python manage.py updatecatalog
```

You can set up a cron job on your host machine:
```bash
# Run at 2 AM daily
0 2 * * * cd /path/to/gutendex && docker-compose exec -T web python manage.py updatecatalog
```

## Management Commands

### View logs
```bash
docker-compose logs -f web
```

### Stop the application
```bash
docker-compose down
```

### Restart the application
```bash
docker-compose restart
```

### Access Django shell
```bash
docker-compose exec web python manage.py shell
```

### Create a superuser
```bash
docker-compose exec web python manage.py createsuperuser
```

### Rebuild after code changes
```bash
docker-compose down
docker-compose build
docker-compose up -d
```

## Production Deployment

### Using a Reverse Proxy (Recommended)

For production, use Nginx or Apache as a reverse proxy in front of the Docker containers:

1. Update `ALLOWED_HOSTS` in `.env` with your domain
2. Set `DEBUG=false` in `.env`
3. Configure your reverse proxy to forward requests to `localhost:8000`

Example Nginx configuration:
```nginx
server {
    listen 80;
    server_name api.gutendex.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /path/to/gutendex/static/;
    }

    location /media/ {
        alias /path/to/gutendex/media/;
    }
}
```

### Using Different Ports

To use a different port, modify `docker-compose.yml`:
```yaml
ports:
  - "8080:8000"  # Maps host port 8080 to container port 8000
```

### Scaling Workers

To increase the number of Gunicorn workers, modify the CMD in `Dockerfile` or override in `docker-compose.yml`:
```yaml
command: gunicorn gutendex.wsgi:application --bind 0.0.0.0:8000 --workers 8
```

## Troubleshooting

### Database connection errors
Ensure the database service is healthy:
```bash
docker-compose ps
docker-compose logs db
```

### Permission errors
Ensure the volumes have correct permissions:
```bash
sudo chown -R $USER:$USER ./static ./media ./catalog_files
```

### Container won't start
Check the logs:
```bash
docker-compose logs web
```

### Reset everything
```bash
docker-compose down -v  # Warning: This deletes the database!
docker-compose up -d
```

## Volume Persistence

Data is persisted in:
- `postgres_data`: Database data (Docker volume)
- `./static`: Static files (host directory)
- `./media`: User media (host directory)
- `./catalog_files`: Downloaded catalog files (host directory)

## Security Notes

1. Always change the default `DATABASE_PASSWORD` and `SECRET_KEY`
2. Set `DEBUG=false` in production
3. Use HTTPS in production (configure your reverse proxy)
4. Regularly update the Docker images for security patches
5. Keep your `.env` file secure and never commit it to version control

## Architecture

```
┌─────────────────┐
│   Nginx/Apache  │ (Optional reverse proxy)
│   (Host)        │
└────────┬────────┘
         │
    ┌────▼─────┐
    │   web    │ (Gunicorn + Django)
    │ :8000    │
    └────┬─────┘
         │
    ┌────▼─────┐
    │    db    │ (PostgreSQL 16)
    │ :5432    │
    └──────────┘
```
