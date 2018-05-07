FROM node:8.9.0

RUN mkdir /app && chown node:node /app

USER node

COPY index.js /app/.
WORKDIR /app

CMD ["node", "/app/index.js"]
