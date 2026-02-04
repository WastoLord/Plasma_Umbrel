const express = require('express');
const { exec } = require('child_process');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const app = express();
const port = 9101;

// Configuração de Pastas
const UPLOAD_DIR = '/tmp/uploads';
const SCAN_DIR = '/scans';

// Garante que as pastas existem
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });
if (!fs.existsSync(SCAN_DIR)) fs.mkdirSync(SCAN_DIR, { recursive: true });

// Configuração do Multer (Upload de arquivos para imprimir)
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, UPLOAD_DIR),
    filename: (req, file, cb) => cb(null, file.originalname)
});
const upload = multer({ storage: storage });

app.use(express.static('public'));
app.use(express.json());

// --- ROTA 1: LISTAR ARQUIVOS SCANEADOS ---
app.get('/files', (req, res) => {
    fs.readdir(SCAN_DIR, (err, files) => {
        if (err) return res.status(500).json({ error: 'Erro ao ler pasta' });
        // Filtra para não mostrar arquivos ocultos e ordena por data (mais recente primeiro)
        const fileList = files
            .filter(f => !f.startsWith('.'))
            .map(f => {
                const stats = fs.statSync(path.join(SCAN_DIR, f));
                return { name: f, time: stats.mtime, size: stats.size };
            })
            .sort((a, b) => b.time - a.time);
        res.json(fileList);
    });
});

// --- ROTA 2: DOWNLOAD DE ARQUIVO ---
app.get('/download/:filename', (req, res) => {
    const file = path.join(SCAN_DIR, req.params.filename);
    res.download(file);
});

// --- ROTA 3: EXECUTAR SCAN (hp-scan) ---
app.post('/scan', (req, res) => {
    const { filename, mode, resolution, format } = req.body;
    
    // Tratamento do nome do arquivo (se vazio, gera data)
    let finalName = filename.trim();
    if (!finalName) {
        const now = new Date();
        finalName = `scan_${now.toISOString().replace(/[:.]/g, '-')}`;
    }
    // Garante a extensão correta
    if (!finalName.toLowerCase().endsWith(`.${format}`)) {
        finalName += `.${format}`;
    }

    const outputFile = path.join(SCAN_DIR, finalName);
    
    // Constrói o comando hp-scan
    // -m: mode (color, gray) | -r: resolution (dpi) | -o: output
    const cmd = `hp-scan --mode=${mode} --res=${resolution} --dest="${outputFile}"`;

    console.log(`Iniciando Scan: ${cmd}`);

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            console.error(`Erro Scan: ${error.message}`);
            return res.status(500).json({ success: false, error: stderr || error.message });
        }
        // Ajusta permissões para que o Umbrel consiga editar/apagar o arquivo
        fs.chmodSync(outputFile, 0o777); 
        res.json({ success: true, message: 'Digitalização concluída!', file: finalName });
    });
});

// --- ROTA 4: IMPRIMIR (lp) ---
app.post('/print', upload.single('file'), (req, res) => {
    if (!req.file) return res.status(400).send('Nenhum arquivo enviado.');

    const { copies, orientation } = req.body;
    const filePath = req.file.path;

    // Constrói comando lp
    // -d M1132: define impressora
    // -n: número de cópias
    // -o landscape/portrait
    // -o fit-to-page: ajusta ao papel
    let options = `-n ${copies} -o fit-to-page`;
    if (orientation === 'landscape') options += ' -o landscape';

    const cmd = `lp -d M1132 ${options} "${filePath}"`;

    console.log(`Imprimindo: ${cmd}`);

    exec(cmd, (error, stdout, stderr) => {
        // Remove o arquivo temporário após enviar para o CUPS
        fs.unlink(filePath, () => {}); 

        if (error) {
            console.error(`Erro Print: ${stderr}`);
            return res.status(500).json({ success: false, error: stderr });
        }
        res.json({ success: true, message: 'Enviado para impressão!' });
    });
});

app.listen(port, () => {
    console.log(`Interface Web rodando na porta ${port}`);
});