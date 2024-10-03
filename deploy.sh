#!/bin/bash

# Navega al directorio de tu repositorio de desarrollo
cd /home/pavlo/web/jekyll-theme-chirpy

# Genera el sitio con Jekyll
bundle exec jekyll build

# Navega al repositorio de despliegue
cd /home/pavlo/github/pablomartin19.github.io

# Limpia el contenido anterior (opcional, pero recomendado)
git rm -rf .
git clean -fxd

# Copia el contenido generado al repositorio de despliegue
cp -R /home/pavlo/github/pablomartin19.github.io/_site* .

# Añade los cambios al repositorio de despliegue
git add .

# Haz commit de los cambios
git commit -m "chore: actualización del blog $(date)"

# Empuja los cambios a GitHub
git push origin main
