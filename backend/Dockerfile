FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system app \
    && useradd --system --gid app --create-home --home-dir /home/app app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=app:app . .

RUN mkdir -p /app/media /app/staticfiles \
    && python manage.py collectstatic --noinput 2>/dev/null || true \
    && chown -R app:app /app/media /app/staticfiles

COPY --chown=app:app docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

USER app

EXPOSE 8000

ENTRYPOINT ["/docker-entrypoint.sh"]
