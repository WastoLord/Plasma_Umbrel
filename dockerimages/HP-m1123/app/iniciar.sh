#!/bin/bash
set -e

echo "=========================================="
echo "🚀 INICIANDO SERVIÇOS HP (RUNTIME)"
echo "=========================================="

# 1. FIX DE RECURSOS (Vital para processadores Atom/Docker)
ulimit -n 2048
echo "✅ [1/5] Limite de arquivos ajustado (ulimit)"

# ====================================================
# CONFIGURAÇÃO AUTOMÁTICA DO CUPS E SSL
# ====================================================
echo "🔓 [SETUP] Configurando permissões e segurança do CUPS..."

# 1. Garante que o arquivo de configuração existe
if [ ! -f /etc/cups/cupsd.conf ]; then
    cp /usr/share/cups/cupsd.conf.default /etc/cups/cupsd.conf
fi

# 2. Abre a porta 631 para a rede (em vez de ouvir só localhost)
sed -i 's/Listen localhost:631/Port 631/' /etc/cups/cupsd.conf

# 3. Libera acesso para qualquer IP (Necessário para Docker/Tailscale)
# Remove restrições antigas se existirem para evitar duplicação
sed -i '/Allow all/d' /etc/cups/cupsd.conf
sed -i '/<Location \/>/a \  Allow all' /etc/cups/cupsd.conf
sed -i '/<Location \/admin>/a \  Allow all' /etc/cups/cupsd.conf
sed -i '/<Location \/admin\/conf>/a \  Allow all' /etc/cups/cupsd.conf

# 4. Permite qualquer Hostname (Resolve o erro "Invalid Host" no Tailscale)
grep -q "ServerAlias *" /etc/cups/cupsd.conf || echo "ServerAlias *" >> /etc/cups/cupsd.conf

# 5. Define politica de Criptografia (Aceita se o Android pedir)
# Remove linhas antigas para evitar conflito e adiciona a correta
sed -i '/DefaultEncryption/d' /etc/cups/cupsd.conf
echo "DefaultEncryption IfRequested" >> /etc/cups/cupsd.conf

# 6. GERAÇÃO AUTOMÁTICA DE CERTIFICADOS SSL (Resolve o erro "Unable to create credentials")
if [ ! -f /etc/cups/ssl/server.crt ]; then
    echo "🔑 [SSL] Gerando certificados autoassinados..."
    mkdir -p /etc/cups/ssl
    openssl req -new -x509 -keyout /etc/cups/ssl/server.key -out /etc/cups/ssl/server.crt -days 3650 -nodes -subj '/C=BR/ST=SP/L=Umbrel/O=Plasma/CN=umbrel'
else
    echo "🔑 [SSL] Certificados já existem."
fi

# 7. CORREÇÃO DE PERMISSÕES (Crucial para o CUPS ler as chaves)
echo "🛡️ [PERM] Ajustando dono e permissões da pasta SSL..."
chgrp -R lp /etc/cups/ssl
chmod 750 /etc/cups/ssl
chmod 640 /etc/cups/ssl/*

# ====================================================


# 2. INICIAR O D-BUS
mkdir -p /var/run/dbus
if [ ! -f /var/lib/dbus/machine-id ]; then
    dbus-uuidgen > /var/lib/dbus/machine-id
fi
rm -f /var/run/dbus/pid
dbus-daemon --config-file=/usr/share/dbus-1/system.conf --fork
echo "✅ [2/5] D-Bus iniciado"

# 3. INICIAR O CUPS
if [ ! -f /etc/cups/cupsd.conf ]; then
    cp /usr/share/cups/cupsd.conf.default /etc/cups/cupsd.conf
fi
killall cupsd 2>/dev/null || true
/usr/sbin/cupsd
echo "✅ [3/5] Servidor CUPS iniciado"

# 4. REGISTRAR A IMPRESSORA (O comando que você pediu)
echo "⏳ Aguardando CUPS carregar..."
sleep 5

echo "⚙️  Registrando impressora M1132..."
# Comando exato com o serial e driver corretos
lpadmin -p M1132 -E \
    -v "hp:/usb/HP_LaserJet_Professional_M1132_MFP?serial=000000000SS29HJJPR1a" \
    -m "drv:///hpcups.drv/hp-laserjet_professional_m1132_mfp.ppd"

# Define como padrão (opcional, mas bom)
lpadmin -d M1132
echo "✅ [4/5] Impressora registrada e definida!"

echo "=========================================="
echo "📠 SISTEMA PRONTO PARA USO"
echo "Logando erros abaixo:"
echo "=========================================="

# 5. MANTÉM O CONTAINER VIVO (Com correção do erro 'No such file')
# Cria o arquivo vazio caso o CUPS ainda não tenha escrito nada
touch /var/log/cups/error_log
tail -f /var/log/cups/error_log