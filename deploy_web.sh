#!/bin/bash

# Script para desplegar la aplicación web a GitHub Pages
# Asegúrate de estar en la rama correcta y tener permisos de push

echo "🚀 Iniciando despliegue a GitHub Pages..."

# 1. Construir la aplicación web
echo "📦 Construyendo aplicación web..."
flutter build web

# 2. Verificar que el build se completó correctamente
if [ ! -d "build/web" ]; then
    echo "❌ Error: No se encontró el directorio build/web"
    exit 1
fi

# 3. Copiar archivos a la rama gh-pages
echo "📁 Preparando archivos para GitHub Pages..."

# Crear directorio temporal
mkdir -p ../temp_gh_pages

# Copiar archivos del build
cp -r build/web/* ../temp_gh_pages/

# 4. Cambiar a la rama gh-pages
echo "🌿 Cambiando a rama gh-pages..."
git checkout gh-pages

# 5. Limpiar archivos existentes (excepto .git)
echo "🧹 Limpiando archivos existentes..."
find . -maxdepth 1 -not -name '.git' -not -name '.' -exec rm -rf {} \;

# 6. Copiar archivos nuevos
echo "📋 Copiando archivos nuevos..."
cp -r ../temp_gh_pages/* .

# 7. Limpiar directorio temporal
rm -rf ../temp_gh_pages

# 8. Agregar y hacer commit
echo "💾 Haciendo commit de los cambios..."
git add .
git commit -m "Deploy: Actualización de la aplicación web $(date '+%Y-%m-%d %H:%M:%S')"

# 9. Hacer push a GitHub
echo "🚀 Subiendo a GitHub Pages..."
git push origin gh-pages

# 10. Volver a la rama original
git checkout fix-cors-api-connection

echo "✅ ¡Despliegue completado!"
echo "🌐 Tu aplicación estará disponible en: https://jeffbozu.github.io/kiosk_app/"
echo "📝 Nota: Puede tomar unos minutos en actualizarse en GitHub Pages"
