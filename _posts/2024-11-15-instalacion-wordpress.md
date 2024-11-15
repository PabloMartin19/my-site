---
title: "Instalación de WordPress en un servidor LEMP"
date: 2024-11-15 17:15:00 +0000
categories: [Implantación Web, Aplicaciones]
tags: [Aplicaciones]
author: pablo
description: "Aprende a instalar y configurar un servidor LEMP para alojar WordPress, incluyendo ajustes en nginx, base de datos, y configuración para URL amigables. 🚀"
toc: true
comments: true
image:
  path: assets/img/posts/wordpress/portada_wordpress.png
---

# ¿Qué vas a aprender en este taller?

- Realizar la instalación de un servidor LEMP.
- Configurar nginx como proxy inverso para pasar las peticiones PHP al servidor de aplicación fpm-php.
- Realizar la instalación de un CMS PHP WordPress.

# Instalación de la pila LEMP

En este taller configuraremos una máquina virtual con Debian 12 y un servidor LEMP.

**¿Qué es LEMP?**

LEMP es un conjunto de software diseñado para alojar aplicaciones web dinámicas. A continuación, desglosamos sus componentes:

- **L**: Linux, el sistema operativo base.
- **E**: Nginx, el servidor web, conocido por su rendimiento y eficiencia. (Se pronuncia "Engine-X")
- **M**: MySQL o MariaDB, sistemas de gestión de bases de datos utilizados para almacenar información.
- **P**: PHP, un lenguaje de programación para generar contenido dinámico en páginas web.

Es una alternativa moderna al stack LAMP (que utiliza Apache como servidor web).

**Pasos para instalar la pila LEMP:**

Ejecuta el siguiente comando para instalar Nginx:
```
pablo@debian:~$ sudo apt install nginx -y
```

Instala MariaDB para gestionar las bases de datos necesarias:
```
pablo@debian:~$ sudo apt install mariadb-server mariadb-client -y
```

Agrega PHP y los módulos imprescindibles para que WordPress funcione correctamente:
```
pablo@debian:~$ sudo apt install php-fpm php-mysql php-xml php-mbstring php-curl php-gd -y
```

Y listo, con estos pasos ya tendrás instalada y configurada la pila LEMP.

# Creación de la base de datos

En este paso, configuraremos la base de datos necesaria para WordPress. Esto incluye crear una base de datos específica, un usuario asociado y otorgarle los permisos necesarios. A continuación, te explico el proceso:

**1.** Accede a la consola de MariaDB como usuario root, para ello ejecuta el siguiente comando en tu terminal:

```
pablo@debian:~$ sudo mysql -u root -p
```

Ingresa la contraseña de root cuando se te solicite. Esto te llevará al monitor de MariaDB.

**2.** Una vez dentro de MariaDB, ejecuta:

```
CREATE DATABASE wordpress_db;
```

Esto crea una base de datos llamada `wordpress_db` donde se almacenarán los datos de WordPress.

**3.** Define un nuevo usuario y una contraseña para gestionar la base de datos. Por ejemplo:

```
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'user'@'localhost';
```

- `user`: Nombre del usuario.
- `password`: Contraseña asociada al usuario.

**4.** Otorga todos los privilegios al usuario sobre la base de datos:

```
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'user'@'localhost';
```

Permite al usuario user gestionar completamente la base de datos `wordpress_db`:

**5.** Finalmente, actualiza los privilegios para asegurarte de que se registren correctamente:

```
FLUSH PRIVILEGES;
```

**6.** Sal del monitor de MariaDB:

```
EXIT;
```

Ahora tienes una base de datos llamada `wordpress_db` y un usuario `user` con todos los privilegios sobre ella. Estos datos serán utilizados durante la configuración de WordPress.

# Configurar un VirtualHost para WordPress

En este paso, crearemos y configuraremos un virtualhost en **nginx** para que el sitio web de WordPress sea accesible a través de un dominio local como `wordpress.pablo.beer`. A continuación, los pasos detallados:

**1.** Crear el archivo de configuración del virtualhost

Edita o crea un nuevo archivo de configuración en `/etc/nginx/sites-available/` con el nombre del dominio deseado:

```
pablo@debian:~$ sudo nano /etc/nginx/sites-available/wordpress.pablo.beer
```

Dentro del archivo, agrega la configuración:

```
server {
    listen 80;
    server_name wordpress.pablo.beer;

    root /var/www/wordpress;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

**2.** Activar el VirtualHost

Crea un enlace simbólico en el directorio `sites-enabled` para que nginx cargue esta configuración:

```
pablo@debian:~$ sudo ln -s /etc/nginx/sites-available/wordpress.pablo.beer /etc/nginx/sites-enabled/
```

**3.** Verificar la configuración de nginx

Antes de reiniciar nginx, verifica que la configuración sea válida:

```
pablo@debian:~$ sudo nginx -t
```

Si todo está correcto, verás un mensaje indicando que la configuración es válida.

**4.** Descargar WordPress

```
pablo@debian:~$ cd /tmp
pablo@debian:/tmp$ wget https://wordpress.org/latest.zip
```

Descomprime el archivo descargado:

```
pablo@debian:/tmp$ sudo apt install unzip
pablo@debian:/tmp$ unzip latest.zip
```

**5.** Mover WordPress a la ruta del servidor web

Mueve los archivos de WordPress al directorio especificado en la configuración del virtualhost (`/var/www/wordpress`):

```
pablo@debian:/tmp$ sudo mv wordpress /var/www/wordpress
```

**6.** Asignar permisos correctos

Asegúrate de que los archivos y directorios tengan los permisos correctos:

```
pablo@debian:~$ sudo chown -R www-data:www-data /var/www/wordpress
pablo@debian:~$ sudo chmod -R 755 /var/www/wordpress
```

**7.** Configurar el archivo hosts

Añade el dominio local `wordpress.pablo.beer` en el archivo `/etc/hosts` de tu host principal (tu máquina física) para que el navegador lo reconozca. Edita el archivo de la siguiente manera:

```
pavlo@debian:~()$ sudo nano /etc/hosts
```

Agrega la línea:

```
<IP_Máquina_Virtual>	wordpress.pablo.beer
```

**8.** Reiniciar nginx

Reinicia el servicio para aplicar los cambios:

```
pablo@debian:~$ sudo systemctl restart nginx
```

Ahora deberías poder acceder a WordPress escribiendo `http://wordpress.pablo.beer` en tu navegador. Desde ahí podrás completar la instalación de WordPress en el navegador.

# Instalación de WordPress

Una vez configurado el servidor, el virtualhost y los permisos, es momento de acceder a la interfaz de instalación de WordPress y configurar el sitio. Aquí tienes los pasos detallados:

**1.** Accede a la URL de instalación

Abre tu navegador web y accede al dominio configurado en tu archivo `/etc/hosts`:

```
http://wordpress.pablo.beer
```

Deberías ver la pantalla inicial de configuración de WordPress:

[Instalación de WordPress](assets/img/posts/wordpress/wordpress2.png)