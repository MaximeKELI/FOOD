# Food API — Backend Django + PostgreSQL

API REST pour l'application Flutter **Food** : authentification vendeurs, catalogue de plats,
et réseau social (vidéos / shorts, likes, commentaires, abonnements, favoris).

## Stack

- Django 5 + Django REST Framework
- PostgreSQL
- JWT (djangorestframework-simplejwt)
- Upload de médias (photos / vidéos) vers `media/`

## 1. Installation

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # adapte les valeurs si besoin
```

## 2. Base de données PostgreSQL

Crée le rôle et la base (une seule fois) :

```bash
sudo -u postgres bash setup_db.sh
```

Cela crée le rôle `food_user` (mot de passe `food_pass`) et la base `food_db`,
conformément au fichier `.env`. Modifie ces valeurs dans `.env` pour la production.

## 3. Migrations + données initiales

```bash
source venv/bin/activate
python manage.py migrate
python manage.py seed_categories          # crée les catégories de plats
python manage.py createsuperuser          # compte admin
```

## 4. Lancer le serveur

```bash
python manage.py runserver 0.0.0.0:8000
```

- API : http://127.0.0.1:8000/
- Admin : http://127.0.0.1:8000/admin/

## Endpoints principaux

### Auth — `/api/auth/`
| Méthode | URL | Description |
|--------|-----|-------------|
| POST | `register/` | Inscription (email, password, + profil vendeur) |
| POST | `login/` | Connexion → `access` + `refresh` |
| POST | `token/refresh/` | Rafraîchir le token |
| GET/PATCH | `me/` | Profil de l'utilisateur connecté |
| GET/PATCH | `me/profile/` | Profil vendeur détaillé |
| POST | `sellers/<id>/follow/` | S'abonner / se désabonner |

### Catalogue — `/api/catalog/`
| Méthode | URL | Description |
|--------|-----|-------------|
| GET | `categories/` | Liste des catégories |
| GET | `meals/?category=Plats&seller=<id>` | Plats (filtres optionnels) |
| POST | `meals/` | Publier un plat (multipart: `name`, `image`, …) |
| GET/PATCH/DELETE | `meals/<id>/` | Détail / modif / suppression (propriétaire) |

### Social — `/api/social/`
| Méthode | URL | Description |
|--------|-----|-------------|
| GET | `posts/?kind=video\|short&author=<id>` | Fil des posts |
| POST | `posts/` | Publier (multipart: `media`, `kind`, `media_type`, `caption`) |
| GET/DELETE | `posts/<id>/` | Détail / suppression (auteur) |
| POST | `posts/<id>/like/` | Like / unlike |
| POST | `posts/<id>/favorite/` | Favori / retrait |
| GET/POST | `posts/<id>/comments/` | Commentaires (et réponses via `parent`) |

## Authentification

Envoie le token dans l'en-tête :

```
Authorization: Bearer <access_token>
```

## Connexion depuis Flutter

- **Émulateur Android** : `http://10.0.2.2:8000`
- **iOS / Linux desktop** : `http://127.0.0.1:8000`
- **Téléphone réel** : `http://<IP_DU_PC>:8000` (même réseau Wi-Fi)
