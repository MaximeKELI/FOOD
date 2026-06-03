# FOOD / Chez Mama

Food delivery + social video commerce app.

| Part | Stack | Folder |
|------|-------|--------|
| Mobile | Flutter, Riverpod, GoRouter | [`chez_mama/`](chez_mama/) |
| API | Django REST + JWT + OpenAPI | [`backend/`](backend/) |
| Realtime | Socket.io + Redis | [`socket-gateway/`](socket-gateway/) |

## Quick start

```bash
./scripts/start-all.sh              # Docker: Postgres, Redis, MinIO, API, Socket
./scripts/start-all.sh --flutter    # + launch Flutter app
./scripts/start-all.sh --smoke      # + health checks
```

**Docs:** [Getting started guide](docs/GETTING_STARTED.md) · [API inventory](backend/docs/API_INVENTORY.md) · [VPS deploy](docs/DEPLOY_VPS.md)

## Local URLs

- API: http://127.0.0.1:8000/
- Swagger: http://127.0.0.1:8000/api/docs/
- MinIO console: http://127.0.0.1:9001/
