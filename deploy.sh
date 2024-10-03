#!/bin/bash

# Directorio del repositorio de desarrollo
DEV_REPO="/home/pavlo/web/jekyll-theme-chirpy"

# Directorio del repositorio de despliegue
DEPLOY_REPO="/home/pavlo/github/pablomartin19.github.io"

# Navegar al repositorio de desarrollo
cd $DEV_REPO

# Añadir todos los cambios
git add .

# Realizar commit con un mensaje automático
git commit -m "Actualización del sitio $(date)"

# Construir el sitio Jekyll
JEKYLL_ENV=production bundle exec jekyll build

# Copiar todo el contenido necesario al repositorio de despliegue
rm -rf $DEPLOY_REPO/*
cp -R _site/* $DEPLOY_REPO/
cp -R assets $DEPLOY_REPO/
cp -R _javascript $DEPLOY_REPO/

# Navegar al repositorio de despliegue
cd $DEPLOY_REPO

# Añadir todos los cambios
git add .

# Realizar commit con un mensaje
git commit -m "Actualización del sitio desplegado $(date)"

# Push de los cambios
git push origin main

# Volver al repositorio de desarrollo y hacer push
cd $DEV_REPO
git push origin main
