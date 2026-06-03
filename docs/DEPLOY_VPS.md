# Déploiement VPS Linux (production)

Stack : Docker Compose, Nginx (TLS), PostgreSQL, Redis, MinIO, Django (Gunicorn), Socket.io gateway.

## Prérequis

- VPS Ubuntu 22.04+ (2 Go RAM minimum recommandé)
- Nom de domaine pointant vers l’IP du serveur
- Docker Engine + Docker Compose plugin

```bash
sudo apt update && sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER
```

## 1. Cloner et configurer

```bash
git clone <repo> /opt/food
cd /opt/food
cp .env.prod.example .env.prod
nano .env.prod
```

Variables obligatoires dans `.env.prod` :

- `SECRET_KEY` — chaîne aléatoire longue (même valeur que `JWT_SECRET` côté socket)
- `DB_PASSWORD`, `MINIO_ROOT_PASSWORD`, `SOCKET_INTERNAL_SECRET`
- `ALLOWED_HOSTS`, `CORS_ALLOWED_ORIGINS` (URL HTTPS de l’API)
- `STRIPE_*`, `WAVE_*`, `ORANGE_MONEY_*` selon les moyens de paiement activés

Remplace `YOUR_DOMAIN` dans `deploy/nginx/conf.d/food.conf`.

## 2. Certificat Let’s Encrypt (première fois)

```bash
# HTTP only bootstrap — commente le bloc HTTPS dans food.conf temporairement si besoin
docker compose -f docker-compose.prod.yml run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  -d YOUR_DOMAIN \
  --email you@example.com --agree-tos --no-eff-email
```

Puis restaure la config HTTPS complète et relance Nginx.

## 3. Démarrer les services

```bash
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
docker compose -f docker-compose.prod.yml ps
curl -s https://YOUR_DOMAIN/health/
```

## 4. Superuser Django

```bash
docker compose -f docker-compose.prod.yml exec django python manage.py createsuperuser
```

## 5. Volumes et sauvegardes

| Volume | Contenu |
|--------|---------|
| `postgres_data` | Base PostgreSQL |
| `minio_data` | Médias S3 |
| `redis_data` | Cache / présence socket |

Sauvegarde Postgres (cron quotidien) :

```bash
docker compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U food_user food_db | gzip > /backup/food_db_$(date +%F).sql.gz
```

Sauvegarde MinIO :

```bash
docker run --rm -v food_minio_data:/data -v /backup:/backup alpine \
  tar czf /backup/minio_$(date +%F).tar.gz -C /data .
```

## 6. Mises à jour

```bash
git pull
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
```

Les migrations s’exécutent au démarrage du conteneur `django` (`RUN_MIGRATIONS=true`).

## 7. Flutter en production

Configure l’URL API et le socket dans l’app :

- `API_BASE_URL=https://YOUR_DOMAIN`
- WebSocket : `wss://YOUR_DOMAIN/socket.io/`

## Smoke test

```bash
./scripts/smoke-compose.sh
```
