# FOOD / Chez Mama

Application de livraison de plats et réseau social (vidéos, shorts) pour vendeurs et clients.

| Partie | Techno | Dossier |
|--------|--------|---------|
| Mobile | Flutter, Riverpod, GoRouter | [`chez_mama/`](chez_mama/) |
| API | Django REST, JWT, OpenAPI | [`backend/`](backend/) |
| Temps réel | Socket.io, Redis | [`socket-gateway/`](socket-gateway/) |

## Prérequis

- Docker et Docker Compose
- Flutter SDK 3.7+ ([installation](https://docs.flutter.dev/get-started/install))
- Pour un téléphone Android : câble USB, débogage USB activé, `adb` (platform-tools)

## Lancer le projet (recommandé)

### 1. Backend (Docker)

```bash
cd FOOD
docker compose up -d
docker compose exec django python manage.py migrate
```

Vérifier :

```bash
curl http://127.0.0.1:8000/health/
./scripts/test-weather-api.sh
```

### 2. Application Flutter

**Émulateur Android ou Linux :**

```bash
./scripts/start-all.sh --flutter
```

**Téléphone physique (USB, le plus fiable) :**

```bash
./scripts/flutter-run-phone.sh
```

Ce script :

- démarre le backend si besoin ;
- configure `adb reverse` (le téléphone utilise `127.0.0.1:8000`) ;
- lance Flutter (notifs météo : **1 fois / 5 h** par défaut).

**Wi‑Fi seulement** (sans câble) : même script sans téléphone branché, ou :

```bash
cd chez_mama
flutter run --dart-define=API_LAN_HOST=TON_IP_WIFI
```

L’IP du PC : `./scripts/detect-lan-ip.sh`

### 3. Compte admin (optionnel)

```bash
docker compose exec django python manage.py createsuperuser
```

Admin : http://127.0.0.1:8000/admin/

## URLs locales

| Service | URL |
|---------|-----|
| API | http://127.0.0.1:8000/ |
| Santé | http://127.0.0.1:8000/health/ |
| Swagger | http://127.0.0.1:8000/api/docs/ |
| MinIO (optionnel, profil `s3`) | `docker compose --profile s3 up -d` puis port-forward si besoin |
| Socket | http://127.0.0.1:3001/health |

## Météo et notifications

L’app propose des messages selon le temps (chaud → jus de fruit, froid → foutou, etc.).

**Tester l’API :**

```bash
./scripts/test-weather-api.sh
```

**Envoyer une notif à tous les utilisateurs :**

```bash
docker compose exec django python manage.py send_weather_nudges
```

**Intervalle par défaut : 5 h** (`WEATHER_NUDGE_INTERVAL_SECONDS=18000` dans `backend/.env.docker`).

**Mode test (10 s)** : `WEATHER_NUDGE_INTERVAL_SECONDS=10` + `docker compose restart django weather-cron`, et sur Flutter `--dart-define=WEATHER_NUDGE_INTERVAL_SECONDS=10`.

Sur le téléphone : accepte les **notifications** Android et connecte-toi pour voir aussi les messages dans l’écran **Notifications** de l’app.

## Scripts utiles

| Script | Rôle |
|--------|------|
| `./scripts/start-all.sh` | Stack Docker complète |
| `./scripts/start-all.sh --flutter` | Stack + Flutter |
| `./scripts/flutter-run-phone.sh` | Téléphone USB + API auto |
| `./scripts/phone-connect.sh` | `adb reverse` + instructions |
| `./scripts/test-weather-api.sh` | Test endpoint météo |
| `./scripts/smoke-compose.sh` | Tests de santé compose |

## Dépannage connexion téléphone

1. Backend : `docker compose up -d` puis `docker compose restart django`
2. USB : `adb reverse tcp:8000 tcp:8000` puis relance l’app (**R** majuscule dans Flutter)
3. Si échec Wi‑Fi : PC et téléphone sur le **même réseau**, IP via `./scripts/detect-lan-ip.sh`
4. Logs Flutter : cherche `[ApiConfig] API reachable at ...`

## Documentation

- [Guide détaillé](docs/GETTING_STARTED.md)
- [Inventaire API](backend/docs/API_INVENTORY.md)
- [Déploiement VPS](docs/DEPLOY_VPS.md)
- [Backend](backend/README.md)
