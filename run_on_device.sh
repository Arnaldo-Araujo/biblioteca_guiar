#!/bin/bash
# Script para executar o app no dispositivo conectado (seja celular via USB ou emulador)
echo "Procurando dispositivos conectados..."

DEVICE=$(flutter devices | grep -E 'android|ios|web|windows|linux|macos' | head -n 1 | awk -F ' • ' '{print $2}')

if [ -z "$DEVICE" ]; then
    echo "Nenhum dispositivo encontrado. Tentando executar o flutter run padrao..."
    flutter run
else
    # Remove espacos em branco do ID do dispositivo (caso haja algum, no geral eh seguro)
    DEVICE=$(echo "$DEVICE" | xargs)
    echo "Executando no dispositivo encontrado: $DEVICE"
    flutter run -d "$DEVICE"
fi
