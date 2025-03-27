FROM node:23

RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN npx playwright install-deps

WORKDIR /app

RUN mkdir -p /app/node_modules && chown -R node:node /app

USER node

COPY --chown=node:node ./package*.json ./

RUN npm install

COPY --chown=node:node ./ ./

RUN npx playwright install chromium

EXPOSE 3002

CMD ["npm", "start"]