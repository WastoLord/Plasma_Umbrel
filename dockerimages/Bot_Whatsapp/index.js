const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');

// Configuração do Cliente WhatsApp
const client = new Client({
    // LocalAuth guarda a sessão para não teres de ler o QR code sempre que o Docker reiniciar
    authStrategy: new LocalAuth({ dataPath: '/app/data' }), 
    puppeteer: {
        executablePath: '/usr/bin/chromium', // Usa o Chromium que instalámos no Dockerfile
        args: ['--no-sandbox', '--disable-setuid-sandbox'] // Essencial para rodar como root no Docker
    }
});

// Quando precisar de login, mostra o QR Code no terminal
client.on('qr', (qr) => {
    console.log('\n=========================================');
    console.log('📸 DIGITALIZE ESTE QR CODE COM O TELEMÓVEL:');
    console.log('=========================================\n');
    qrcode.generate(qr, { small: true });
});

// Quando o WhatsApp conectar com sucesso
client.on('ready', () => {
    console.log('🤖 Bot do Ranking online e pronto a registar vitórias!');
});

// A ouvir as mensagens do grupo
client.on('message', async msg => {
    // Teste simples
    if (msg.body === '!ping') {
        msg.reply('Pong! O juiz está acordado e pronto para a partida. 🏓');
    }
    
    // Esqueleto para os futuros comandos de ranking
    if (msg.body === '!rank') {
        msg.reply('Ainda a construir a tabela classificativa... Aguardem! 🏆');
    }
});

client.initialize();
