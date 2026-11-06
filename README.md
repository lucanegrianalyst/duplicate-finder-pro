
# 🎵 Cerca Doppioni PRO

Un potente strumento con interfaccia grafica per trovare e gestire file duplicati su Windows, ottimizzato per librerie musicali, cartelle di foto e video.

## 📖 Descrizione

**Cerca Doppioni PRO** è un'applicazione desktop scritta in PowerShell che sfrutta l'algoritmo **SHA-256** per identificare con precisione matematica i file identici byte per byte. Offre un'anteprima interattiva, un sistema di scelta intelligente dell'originale e la possibilità di spostare i file nel cestino in modo sicuro.

## ✨ Funzionalità principali

- **Scansione Multi-Disco**: Analizza più cartelle e dischi contemporaneamente.
- **Filtro per Categorie**: Seleziona quali tipi di file analizzare (Audio, Video, Immagini, Documenti).
- **Scelta Intelligente dell'Originale**: Il file da tenere viene scelto in base a dimensione, data e pulizia del nome.
- **Scansione Incrementale**: Una cache locale rende le scansioni successive fulminee.
- **Filtro Cloud**: Ignora i file "segnaposto" di OneDrive o Google Drive non scaricati.
- **Anteprima Interattiva**: Tabella ridimensionabile con colori (verde = originale, rosso = copia) e doppio clic per aprire i file.
- **Sicurezza**: Sposta i file nel cestino di default. L'eliminazione definitiva richiede conferma.
- **Log delle Operazioni**: Ogni azione viene registrata in output/operazioni.log.

## 🚀 Come usare il programma

1. Avvia CercaDoppioniMultiHD.exe.
2. Seleziona la cartella o il disco da analizzare.
3. Spunta le categorie di file che ti interessano.
4. Clicca **AVVIA ANALISI**.
5. Nell'anteprima, controlla i file trovati e clicca **PROCEDI**.

## 📁 Struttura del Progetto

Il progetto segue un'architettura modulare:

```text
cerca-doppioni/
├── CercaDoppioni.ps1          # Script di avvio
├── Modules/
│   ├── Engine.psm1            # Motore di scansione e Hashing
│   ├── GUI_Main.psm1          # Finestra principale
│   ├── GUI_Preview.psm1       # Finestra di anteprima
│   ├── GUI_Utils.psm1         # Funzioni di utilità per la GUI
│   └── Reporter.psm1          # Gestione cestino e log
├── config/
│   └── settings.json          # Configurazione estensioni
└── output/                    # Report e Log (ignorati da Git)
