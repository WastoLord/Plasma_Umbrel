func handlePrint(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		return
	}

	// 1. Receber o arquivo do form-data (limite de 10MB na memória)
	r.ParseMultipartForm(10 << 20) 
	file, handler, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "Erro ao recuperar arquivo", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// 2. Salvar arquivo temporário no disco (o CUPS precisa de um path físico)
	tempPath := fmt.Sprintf("/tmp/%d-%s", time.Now().Unix(), handler.Filename)
	dst, err := os.Create(tempPath)
	if err != nil {
		http.Error(w, "Erro ao salvar arquivo temporário", http.StatusInternalServerError)
		return
	}
	defer dst.Close()
	
	if _, err := io.Copy(dst, file); err != nil {
		http.Error(w, "Erro ao escrever arquivo", http.StatusInternalServerError)
		return
	}

	// 3. Enviar para o CUPS
	// Nota: Adicionei "-o fit-to-page" que é útil para PDFs não cortarem
	cmd := exec.Command("lp", "-d", PrinterName, "-o", "fit-to-page", tempPath)
	output, err := cmd.CombinedOutput()
	
	// Limpeza do arquivo temporário (importante para não encher o container)
	defer os.Remove(tempPath)

	if err != nil {
		log.Printf("Erro CUPS: %s", string(output))
		http.Error(w, fmt.Sprintf("Erro ao imprimir: %s", string(output)), 500)
		return
	}

	fmt.Fprintf(w, "Job ID enviado: %s", string(output))
}
