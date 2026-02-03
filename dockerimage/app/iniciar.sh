#!/bin/bash
set -e

echo "=========================================="
echo "🚀 INICIANDO SERVIÇOS HP (RUNTIME)"
echo "=========================================="

# 1. FIX DE RECURSOS (Vital para processadores Atom/Docker)
# Aumenta o limite de arquivos abertos. Sem isso, o CUPS/HPLIP
# pode falhar com erros de "Bad Address" ou "Memory Alloc".
ulimit -n 2048
echo "✅ [1/4] Limite de arquivos ajustado (ulimit)"

# 2. INICIAR O D-BUS (O "Carteiro" do Sistema)
# O hp-scan precisa do D-Bus para falar com o USB.
mkdir -p /var/run/dbus

# Gera ID da máquina se não existir
if [ ! -f /var/lib/dbus/machine-id ]; then
    dbus-uuidgen > /var/lib/dbus/machine-id
fi

# Remove travas antigas (caso o container tenha desligado forçado)
rm -f /var/run/dbus/pid

# Inicia o daemon em background
dbus-daemon --config-file=/usr/share/dbus-1/system.conf --fork
echo "✅ [2/4] D-Bus iniciado"

# 3. INICIAR O CUPS (Gerenciador de Impressão)
# Garante que as configurações padrão existam
if [ ! -f /etc/cups/cupsd.conf ]; then
    cp /usr/share/cups/cupsd.conf.default /etc/cups/cupsd.conf
fi

# Mata processos antigos e inicia o novo
killall cupsd 2>/dev/null || true
/usr/sbin/cupsd
echo "✅ [3/4] Servidor CUPS iniciado"

# 4. REGISTRAR A IMPRESSORA AUTOMATICAMENTE
# Espera o CUPS acordar
sleep 5

# Verifica se a impressora já existe no sistema
if ! lpstat -p M1132 > /dev/null 2>&1; then
    echo "⚙️  Configurando impressora M1132 pela primeira vez..."
    
    # Adiciona a impressora usando o driver hpcups (que já tem o plugin instalado)
    # Serial fixo conforme seus logs anteriores
    lpadmin -p M1132 -E \
        -v "hp:/usb/HP_LaserJet_Professional_M1132_MFP?serial=000000000SS29HJJPR1a" \
        -m "drv:///hpcups.drv/hp-laserjet_professional_m1132_mfp.ppd"
        
    echo "✅ [4/4] Impressora M1132 registrada com sucesso!"
else
    echo "✅ [4/4] Impressora já está configurada."
fi

echo "=========================================="
echo "📠 SISTEMA PRONTO PARA USO"
echo "Logando erros abaixo:"
echo "=========================================="

# 5. MANTÉM O CONTAINER VIVO
# O tail segura o script rodando e mostra os logs de erro na tela do Docker
tail -f /var/log/cups/error_log
