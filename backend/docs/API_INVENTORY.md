# API inventory & model alignment

Cartographie des endpoints DRF existants et correspondance avec le cahier des charges.

## Endpoints par domaine

### Auth — `/api/auth/`

| Spec entity | Django model | Method | Path | Auth | Notes |
|-------------|--------------|--------|------|------|-------|
| User register | `accounts.User` + `SellerProfile` | POST | `register/` | Public | email, password, seller fields |
| User login | JWT | POST | `login/` | Public | returns `access`, `refresh` |
| Token refresh | JWT | POST | `token/refresh/` | Public | |
| Current user | `User` | GET/PATCH | `me/` | Bearer | `display_name`, `phone`, `avatar` |
| Vendor profile | `SellerProfile` | GET/PATCH | `me/profile/` | Bearer | shop, geo, delivery fees |
| Vendor map | `SellerProfile` | GET | `sellers/` | Read | lat/lng list |
| Vendor public | `User` + profile | GET | `sellers/<id>/` | Read | no email |
| Follow vendor | `Follow` | POST | `sellers/<id>/follow/` | Bearer | toggle |

### Catalog (products) — `/api/catalog/`

| Spec entity | Django model | Method | Path | Auth |
|-------------|--------------|--------|------|------|
| FoodCategory | `catalog.Category` | GET | `categories/` | Read |
| Product/Meal | `catalog.Meal` | GET/POST | `meals/` | POST: seller |
| Product detail | `Meal` | GET/PATCH/DELETE | `meals/<id>/` | Owner for write |
| Meal gallery | `MealImage` | via meal serializer | — | — |
| Favorites | `MealFavorite` | GET | `favorites/` | Bearer |
| Favorite toggle | `MealFavorite` | POST | `meals/<id>/favorite/` | Bearer |
| Reviews | `Review` | GET/POST | `meals/<id>/reviews/` | POST: auth |

### Social (videos) — `/api/social/`

| Spec entity | Django model | Method | Path | Auth |
|-------------|--------------|--------|------|------|
| VideoPost | `social.Post` | GET/POST | `posts/` | POST: auth |
| Post detail | `Post` | GET/DELETE | `posts/<id>/` | DELETE: author |
| Like | `social.Like` | POST | `posts/<id>/like/` | Bearer |
| Favorite | `social.Favorite` | POST | `posts/<id>/favorite/` | Bearer |
| Comment | `social.Comment` | GET/POST | `posts/<id>/comments/` | POST: auth |

### Orders — `/api/orders/`

| Spec entity | Django model | Method | Path | Auth |
|-------------|--------------|--------|------|------|
| Order | `orders.Order` | GET/POST | `orders/` | Customer |
| Order detail | `Order` | GET | `orders/<id>/` | Customer/seller |
| Seller inbox | `Order` | GET | `orders/received/` | Seller |
| Seller stats | — | GET | `orders/stats/` | Seller |
| Status update | `Order` | PATCH | `orders/<id>/status/` | Seller |
| Cancel | `Order` | POST | `orders/<id>/cancel/` | Customer |
| Delivery quote | — | POST | `orders/delivery-quote/` | Bearer |
| Promo | `PromoCode` | POST | `orders/promo-validate/` | Bearer |

### Payments — `/api/payments/`

| Spec entity | Django model | Method | Path | Auth |
|-------------|--------------|--------|------|------|
| Payment | `payments.PaymentIntent` | POST | `payments/initiate/` | Customer |
| Payment status | `PaymentIntent` | GET | `payments/<id>/` | Customer |
| Stripe intent | `PaymentIntent` | POST | `payments/stripe/create/` | Customer |
| Stripe webhook | — | POST | `payments/webhook/stripe/` | Signature |
| Wave webhook | — | POST | `payments/webhook/wave/` | Signature |
| Orange webhook | — | POST | `payments/webhook/orange/` | Signature |
| Wave return | — | GET | `payments/wave/return/` | Public (deep-link) |
| Orange return | — | GET | `payments/orange/return/` | Public (deep-link) |

### Chat — `/api/chat/`

| Method | Path | Description |
|--------|------|-------------|
| GET | `chat/conversations/` | List threads |
| POST | `chat/conversations/start/` | Open thread with seller |
| GET/POST | `chat/conversations/<id>/messages/` | Messages |
| GET | `chat/unread/` | Unread count |

### Notifications — `/api/notifications/`

| Method | Path | Description |
|--------|------|-------------|
| GET | `notifications/` | In-app notifications (no pagination) |
| POST | `notifications/read/` | Mark all read |
| POST | `notifications/<id>/read/` | Mark one |
| POST `action=delete` | `notifications/<id>/read/` | Delete one (preferred) |
| POST `action=clear` | `notifications/read/` | Delete all (preferred) |
| DELETE / POST | `notifications/<id>/` | Delete one (legacy) |
| DELETE / POST | `notifications/clear/` | Delete all (legacy) |
| POST | `notifications/push/register/` | FCM device token |

### Deliveries (ready, optional feature flag) — `/api/deliveries/`

| Spec entity | Django model | Method | Path |
|-------------|--------------|--------|------|
| Driver | `deliveries.Driver` | GET/PATCH | `drivers/me/` |
| Delivery | `deliveries.Delivery` | GET | `deliveries/<id>/` |
| Driver location | — | PATCH | `deliveries/<id>/location/` |
| Tracking | — | realtime via Socket.io `delivery:location` |

### System

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | API root |
| GET | `/health/` | DB health |
| GET | `/api/schema/` | OpenAPI schema |
| GET | `/api/docs/` | Swagger UI |
| GET | `/api/redoc/` | ReDoc |

## Model mapping (spec → codebase)

| Spec | Implementation | Gap / action |
|------|----------------|--------------|
| `User` | `accounts.User` | Added `first_name`, `last_name`, `avatar` |
| `VendorProfile` | `accounts.SellerProfile` | Added `cover`, `logo`, `address`, `business_phone` |
| `FoodCategory` | `catalog.Category` | Aligned |
| `Product` | `catalog.Meal` + `MealImage` | Name kept for backward compat |
| `VideoPost` | `social.Post` | `kind` short/video |
| `Like` / `Comment` | `social.Like`, `social.Comment` | Aligned |
| `Order` / `OrderItem` | `orders.Order`, `OrderItem` | Aligned |
| `Payment` | `payments.PaymentIntent` | Stripe + Wave + Orange; MOCK removed |
| `Driver` / `Delivery` | `deliveries.Driver`, `Delivery` | New app, inactive until enabled |

## Realtime events (Socket.io)

| Event | Room | Direction |
|-------|------|-----------|
| `order:status` | `order:<id>`, `vendor:<id>` | server → clients |
| `chat:message` | `conversation:<id>` | bidirectional |
| `notification` | `user:<id>` | server → client |
| `delivery:location` | `delivery:<id>` | driver → customer |
