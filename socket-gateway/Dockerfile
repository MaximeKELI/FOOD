FROM node:20-alpine

WORKDIR /app

RUN addgroup -S app && adduser -S -G app app

COPY package.json ./
RUN npm install --omit=dev && chown -R app:app /app

COPY --chown=app:app src ./src

ENV PORT=3001
USER app

EXPOSE 3001

CMD ["npm", "start"]
