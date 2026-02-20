FROM node:20-bookworm-slim

# Instala o Chromium nativo do Debian para poupar espaço e evitar erros
RUN apt-get update && apt-get install -y chromium \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia os ficheiros de configuração e instala as dependências
COPY package*.json ./
RUN npm install

# Copia o resto do código
COPY . .

CMD ["node", "index.js"]
