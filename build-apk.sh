#!/bin/bash

# Script para crear APK de la aplicación Kiosk
# Basado en la rama BUILDS (twilio-proxy)

echo "🚀 Iniciando build de APK desde rama BUILDS..."

# Verificar que estamos en la rama correcta
current_branch=$(git branch --show-current)
if [ "$current_branch" != "BUILDS" ]; then
    echo "⚠️  Cambiando a rama BUILDS..."
    git checkout BUILDS
fi

# Verificar que Flutter esté disponible
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter no está instalado o no está en el PATH"
    exit 1
fi

# Verificar Android SDK
if [ -z "$ANDROID_HOME" ]; then
    echo "❌ ANDROID_HOME no está configurado"
    echo "💡 Instala Android Studio y configura ANDROID_HOME"
    echo "💡 O ejecuta: export ANDROID_HOME=/path/to/android/sdk"
    exit 1
fi

# Verificar que el SDK existe
if [ ! -d "$ANDROID_HOME" ]; then
    echo "❌ Android SDK no encontrado en $ANDROID_HOME"
    exit 1
fi

echo "✅ Android SDK encontrado en: $ANDROID_HOME"

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
flutter clean

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# Aceptar licencias de Android
echo "📋 Aceptando licencias de Android..."
flutter doctor --android-licenses

# Crear APK
echo "🔨 Creando APK..."
flutter build apk --release

# Verificar que el APK se creó
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "✅ APK creado exitosamente: build/app/outputs/flutter-apk/app-release.apk"
    echo "📱 Tamaño del APK: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
else
    echo "❌ Error: No se pudo crear el APK"
    exit 1
fi

echo "🎉 Build completado!"
