#!/bin/bash
set -e

echo "=========================================="
echo "🚀 INICIANDO SERVIÇOS HP (FULL STACK)"
echo "=========================================="

# 1. FIX DE RECURSOS
ulimit -n 2048
echo "✅ [1/5] Limite de arquivos ajustado"

# 2. CONFIGURAÇÃO CUPS E SSL (CÓDIGO CONSOLIDADO)
echo "🔓 [SETUP] Configurando segurança do CUPS..."
if [ ! -f /etc/cups/cupsd.conf ]; then
    cp /usr/share/cups/cupsd.conf.default /etc/cups/cupsd.conf
fi

# Ajustes de Porta e Acesso
sed -i 's/Listen localhost:631/Port 631/' /etc/cups/cupsd.conf
sed -i '/Allow all/d' /etc/cups/cupsd.conf
sed -i '/<Location \/>/a \  Allow all' /etc/cups/cupsd.conf
sed -i '/<Location \/admin>/a \  Allow all' /etc/cups/cupsd.conf
sed -i '/<Location \/admin\/conf>/a \  Allow all' /etc/cups/cupsd.conf
grep -q "ServerAlias *" /etc/cups/cupsd.conf || echo "ServerAlias *" >> /etc/cups/cupsd.conf

# Criptografia
sed -i '/DefaultEncryption/d' /etc/cups/cupsd.conf
echo "DefaultEncryption IfRequested" >> /etc/cups/cupsd.conf

# SSL
if [ ! -f /etc/cups/ssl/server.crt ]; then
    echo "🔑 [SSL] Gerando certificados..."
    mkdir -p /etc/cups/ssl
    openssl req -new -x509 -keyout /etc/cups/ssl/server.key -out /etc/cups/ssl/server.crt -days 3650 -nodes -subj '/C=BR/ST=SP/L=Umbrel/O=Plasma/CN=umbrel'
fi

# Permissões
chgrp -R lp /etc/cups/ssl
chmod 750 /etc/cups/ssl
chmod 640 /etc/cups/ssl/*

# 3. INICIAR D-BUS
mkdir -p /var/run/dbus
if [ ! -f /var/lib/dbus/machine-id ]; then
    dbus-uuidgen > /var/lib/dbus/machine-id
fi
rm -f /var/run/dbus/pid
dbus-daemon --config-file=/usr/share/dbus-1/system.conf --fork
echo "✅ [2/5] D-Bus iniciado"

# 4. INICIAR CUPS
killall cupsd 2>/dev/null || true
/usr/sbin/cupsd
echo "✅ [3/5] Servidor CUPS iniciado"

# 5. REGISTRAR IMPRESSORA
echo "⏳ Aguardando CUPS..."
sleep 5
echo "⚙️  Registrando HP M1132..."
lpadmin -p M1132 -E -v "hp:/usb/HP_LaserJet_Professional_M1132_MFP?serial=000000000SS29HJJPR1a" -m "drv:///hpcups.drv/hp-laserjet_professional_m1132_mfp.ppd"
lpadmin -d M1132
echo "✅ [4/5] Impressora registrada"

# 6. INICIAR INTERFACE WEB (NODE.JS)
echo "🌐 [WEB] Iniciando interface na porta 9101..."
cd /app/interface
npm start &  # O '&' é vital para rodar em background
echo "✅ [5/5] Interface Web iniciada!"

echo "=========================================="
echo "📠 SISTEMA PRONTO: http://umbrel:9101"
echo "=========================================="

# Mantém container vivo
touch /var/log/cups/error_log
tail -f /var/log/cups/error_log