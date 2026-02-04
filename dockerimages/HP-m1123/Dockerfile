FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# 1. Copia a pasta 'app' do Codespace para dentro da imagem
COPY app/ .

# 2. Permissões
RUN chmod +x /app/instalacao.sh /app/iniciar.sh

# 3. BLOCO A: Instala apenas os pacotes do sistema
# Adicionei 'gnupg' e 'file' que o instalador da HP costuma pedir
RUN apt-get update && apt-get install -y \
    cups \
    cups-client \
    sane-utils \
    hplip \
    openssl \
    printer-driver-hpcups \
    wget \
    usbutils \
    python3 \
    dbus \
    gnupg \
    file \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. BLOCO B: Roda o script de instalação do plugin SEPARADO
# Se der erro aqui, saberemos que foi culpa do script/download
RUN ./instalacao.sh

# 5. Comando final
CMD ["/app/iniciar.sh"]