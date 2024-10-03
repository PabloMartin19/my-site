#!/bin/bash

# Directorio del repositorio de desarrollo
DEV_REPO="/home/pavlo/web/jekyll-theme-chirpy"

# Directorio del repositorio de despliegue
DEPLOY_REPO="/home/pavlo/github/pablomartin19.github.io"

# Navegar al repositorio de desarrollo
cd $DEV_REPO

# Construir el sitio Jekyll
bundle exec jekyll build

# Copiar la carpeta _site al repositorio de despliegue
rm -rf $DEPLOY_REPO/*
cp -R _site/* $DEPLOY_REPO/

# Navegar al repositorio de despliegue
cd $DEPLOY_REPO

# Añadir todos los cambios
git add .

# Realizar commit con un mensaje
git commit -m "Actualización del sitio $(date)"

# Push de los cambios
git push origin main
