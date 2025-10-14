#!/bin/bash

# Script para generar PDF desde HTML usando Chrome
echo "Generando PDF desde HTML..."

# Verificar si Chrome está instalado
if ! command -v google-chrome &> /dev/null; then
    echo "Chrome no encontrado, intentando con chromium..."
    if ! command -v chromium-browser &> /dev/null; then
        echo "Error: Ni Chrome ni Chromium están instalados"
        exit 1
    else
        CHROME_CMD="chromium-browser"
    fi
else
    CHROME_CMD="google-chrome"
fi

# Generar PDF usando Chrome
$CHROME_CMD --headless --disable-gpu --print-to-pdf=DOCUMENTACION_TECNICA_COMPLETA.pdf --print-to-pdf-no-header DOCUMENTACION_TECNICA_COMPLETA.html

if [ $? -eq 0 ]; then
    echo "PDF generado exitosamente: DOCUMENTACION_TECNICA_COMPLETA.pdf"
    ls -la DOCUMENTACION_TECNICA_COMPLETA.pdf
else
    echo "Error generando PDF"
    exit 1
fi
