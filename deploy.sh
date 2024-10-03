#!/bin/bash

# Navega al directorio de tu repositorio de desarrollo
cd /home/pavlo/web/jekyll-theme-chirpy

# Genera el sitio con Jekyll
bundle exec jekyll build

# Navega al repositorio de despliegue
cd /home/pavlo/github/pablomartin19.github.io

# Limpia el contenido anterior (manteniendo .git)
find . -maxdepth 1 ! -name .git ! -name . ! -name .. -exec rm -rf {} +

# Copia el contenido generado al repositorio de despliegue
cp -R /home/pavlo/web/jekyll-theme-chirpy/_site .

# Añade los cambios al repositorio de despliegue
git add .

# Haz commit de los cambios
git commit -m "Actualización del sitio $(date)"

# Empuja los cambios a GitHub
git push origin main
