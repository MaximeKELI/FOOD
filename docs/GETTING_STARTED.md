# Chez Mama / FOOD — Summary & Launch Guide

Food delivery and social-commerce app: Flutter mobile client + Django REST API + realtime Socket.io gateway.

---

## Project summary

### Architecture

```
Flutter (chez_mama/)  ──HTTPS REST──►  Django API (:8000)
       │                                      │
       └── WSS Socket.io ─────────────►  Socket gateway (:3001)
                                              │
                    Postgres ◄── Django ──► Redis ◄── Socket
                    MinIO (S3 media)
```

| Component | Tech | Location |
|-----------|------|----------|
| Mobile app | Flutter, Riverpod, GoRouter | `chez_mama/` |
| REST API | Django 5 + DRF + JWT | `backend/` |
| Realtime | Node.js Socket.io + Redis adapter | `socket-gateway/` |
| Database | PostgreSQL 16 | Docker / local |
| Cache / pub-sub | Redis 7 | Docker / local |
| Media storage | MinIO (S3-compatible) | Docker / local |
| Reverse proxy (prod) | Nginx + Let's Encrypt | `deploy/nginx/` |

### Backend apps

| App | Purpose |
|-----|---------|
| `accounts` | Users, seller profiles, follow |
| `catalog` | Categories, meals, favorites, reviews |
| `social` | Video/short posts, likes, comments |
| `orders` | Cart checkout, promos, delivery quotes |
| `payments` | Stripe, Wave, Orange Money |
| `chat` | Seller–customer messaging |
| `notifications` | In-app + FCM push |
| `deliveries` | Driver/delivery tracking (feature flag) |

### Key URLs (local Docker)

| Service | URL |
|---------|-----|
| API root | http://127.0.0.1:8000/ |
| Health | http://127.0.0.1:8000/health/ |
| Swagger | http://127.0.0.1:8000/api/docs/ |
| ReDoc | http://127.0.0.1:8000/api/redoc/ |
| Django admin | http://127.0.0.1:8000/admin/ |
| MinIO console | http://127.0.0.1:9001/ (minioadmin / minioadmin123) |
| Socket gateway | http://127.0.0.1:3001/health |

### Payments

| Method | Backend | Flutter |
|--------|---------|---------|
| Cash on delivery | Order only | Checkout chip |
| Stripe (card) | `POST /api/payments/stripe/create/` + webhook | PaymentSheet |
| Wave | `POST /api/payments/initiate/` + webhook | External browser |
| Orange Money | Same flow | External browser |

Set `STRIPE_*`, `WAVE_*`, `ORANGE_MONEY_*` in env for live payments. Without keys, digital payments return configuration errors (no mock provider).

### Realtime events (Socket.io)

Connect with JWT: `auth: { token: "<access_token>" }`

| Event | Room | Description |
|-------|------|-------------|
| `order:status` | `order:<id>`, `vendor:<id>` | Order status updates |
| `chat:message` | `conversation:<id>` | Chat relay |
| `notification` | `user:<id>` | In-app notifications |
| `delivery:location` | `delivery:<id>` | Driver GPS tracking |

### Documentation

- [API inventory](../backend/docs/API_INVENTORY.md) — endpoints + model mapping
- [VPS deployment](./DEPLOY_VPS.md) — production Docker + TLS

---

## Quick start (recommended — Docker)

**Requirements:** Docker Engine + Docker Compose v2, Git, Flutter SDK (for the app).

### One command

```bash
./scripts/start-all.sh
```

Options:

```bash
./scripts/start-all.sh --flutter          # Start stack + launch Flutter app
./scripts/start-all.sh --flutter -d linux # Start stack + Flutter on Linux desktop
./scripts/start-all.sh --stop             # Stop all containers
./scripts/start-all.sh --logs             # Follow container logs
./scripts/start-all.sh --smoke            # Start + run health checks
```

### Manual steps

```bash
# 1. Clone and enter project
cd /path/to/FOOD

# 2. Start backend stack (Postgres, Redis, MinIO, Django, Socket)
docker compose up -d --build --wait

# 3. Verify
curl http://127.0.0.1:8000/health/
curl http://127.0.0.1:3001/health

# 4. Create admin user (optional)
docker compose exec django python manage.py createsuperuser

# 5. Run Flutter app
cd chez_mama
flutter pub get
flutter run
```

Migrations and category seed run automatically on first Django container start (`RUN_MIGRATIONS=true`, `SEED_CATEGORIES=true` in `docker-compose.yml`).

---

## Flutter app

### API base URL

The app auto-detects the backend:

| Platform | Default API URL |
|----------|-----------------|
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator / Linux / macOS | `http://127.0.0.1:8000` |
| Physical phone | `http://<YOUR_PC_IP>:8000` (same Wi‑Fi) |

Override for production or custom host:

```bash
flutter run --dart-define=API_BASE_URL=https://your-domain.com
```

### Physical device on Wi‑Fi

1. Find your PC IP: `ip addr` or `hostname -I`
2. Add the IP to Django `ALLOWED_HOSTS` (in `backend/.env.docker` or compose env)
3. Run: `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000`

### Run targets

```bash
cd chez_mama
flutter pub get
flutter run                    # default device
flutter run -d chrome          # web
flutter run -d linux           # Linux desktop
flutter test
flutter analyze
```

---

## Local development without Docker

Use this if you prefer running Django directly on the host.

### 1. PostgreSQL

```bash
cd backend
sudo -u postgres bash setup_db.sh   # creates food_user / food_db
```

Or point `DB_*` in `.env` to an existing Postgres instance.

### 2. Backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env              # edit as needed
python manage.py migrate
python manage.py seed_categories
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

For MinIO locally, set in `.env`:

```env
USE_S3=True
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin123
AWS_STORAGE_BUCKET_NAME=food-media
AWS_S3_ENDPOINT_URL=http://127.0.0.1:9000
AWS_S3_USE_SSL=False
```

Run MinIO separately: `docker run -p 9000:9000 -p 9001:9001 minio/minio server /data --console-address ":9001"`

### 3. Socket gateway (optional)

```bash
cd socket-gateway
npm install
REDIS_URL=redis://127.0.0.1:6379/1 \
JWT_SECRET=your-django-secret-key \
SOCKET_INTERNAL_SECRET=socket-internal-dev \
npm start
```

Set in backend `.env`:

```env
REDIS_URL=redis://127.0.0.1:6379/0
SOCKET_EMIT_URL=http://127.0.0.1:3001/internal/emit
SOCKET_INTERNAL_SECRET=socket-internal-dev
```

### 4. Flutter

Same as Docker path — `flutter run` from `chez_mama/`.

---

## Production (VPS)

```bash
cp .env.prod.example .env.prod    # fill secrets
# Edit deploy/nginx/conf.d/food.conf — replace YOUR_DOMAIN
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
docker compose -f docker-compose.prod.yml exec django python manage.py createsuperuser
```

Full guide: [DEPLOY_VPS.md](./DEPLOY_VPS.md)

---

## Tests

```bash
# Backend (needs Postgres running)
cd backend
pytest

# Docker smoke test
./scripts/smoke-compose.sh

# Flutter
cd chez_mama && flutter test
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Connection refused` from Flutter | Ensure Docker stack is up; use `10.0.2.2` on Android emulator |
| Port 5432 already in use | Stop local Postgres or change compose port mapping |
| Django unhealthy | `docker compose logs django` — usually DB not ready yet |
| Upload fails | Check MinIO is running; bucket `food-media` exists |
| Stripe/Wave errors at checkout | Add API keys to `backend/.env.docker` or `.env` |
| Socket auth fails | `JWT_SECRET` in socket must match Django `SECRET_KEY` |

### Useful commands

```bash
docker compose ps
docker compose logs -f django
docker compose down                 # stop, keep volumes
docker compose down -v              # stop + delete data volumes
docker compose exec django python manage.py shell
```

---

## Environment files

| File | Use |
|------|-----|
| `backend/.env.example` | Local dev template (copy to `.env`) |
| `backend/.env.docker` | Used by `docker-compose.yml` |
| `.env.prod.example` | Production template (copy to `.env.prod`) |
