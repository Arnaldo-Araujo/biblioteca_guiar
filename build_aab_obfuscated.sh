#!/bin/bash
# Script para gerar o AAB ofuscado para publicacao do Flutter
echo "Limpando build antigo..."
flutter clean
flutter pub get

echo "Gerando Android App Bundle (AAB) com ofuscacao..."
# Eh recomendado manter a informacao de debug salva para depois poder de-ofuscar crashes na play console
flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols

echo "Build finalizado. O arquivo AAB deve estar em: build/app/outputs/bundle/release/"
