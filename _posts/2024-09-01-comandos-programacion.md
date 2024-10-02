---
title: "Comandos para programación de tareas"
date: 2024-09-02 18:00:00 +0000
categories: [Sistemas, Automatización]
tags: [Automatización]
author: pablo
description: "Explora los comandos esenciales para programar tareas en Linux. Aprende a automatizar procesos y optimizar tu flujo de trabajo en el sistema operativo, asegurando que las tareas críticas se realicen de manera eficiente y sin intervención manual."
toc: true
comments: true
image:
  path: /assets/img/posts/comando-progra/comando-progra.jpg
---

## Introducción
En el entorno Linux, la programación de tareas es una habilidad fundamental que permite a los usuarios automatizar la ejecución de comandos y scripts en momentos específicos o en intervalos regulares. Esta capacidad no solo mejora la eficiencia, sino que también asegura que las tareas críticas se realicen sin intervención manual, lo que es especialmente útil para mantenimiento del sistema, copias de seguridad y actualizaciones programadas.

Este post explorará los comandos más utilizados para programar tareas en Linux, tales como cron, at y systemd timers. Aprenderemos cómo configurarlos y utilizarlos de manera efectiva, proporcionando ejemplos prácticos que facilitarán la comprensión de su funcionamiento. Al final, tendrás las herramientas necesarias para automatizar tareas y optimizar tu flujo de trabajo en el sistema operativo Linux.

## 1. Sleep
El comando sleep en Linux se utiliza para pausar la ejecución de un proceso o script durante un período de tiempo especificado por el usuario. Este comando está disponible en todas las distribuciones de Linux, incluyendo Debian, y no requiere instalación adicional.

**Opciones y Parámetros**

Las opciones más comunes para el comando sleep son:
- -h o --help: Muestra información de ayuda sobre el comando sleep.
- -v o --version: Muestra información sobre la versión del comando y detalles relacionados con su desarrollo.

Los parámetros que se pueden utilizar con sleep para especificar el tiempo de pausa son:

- s: Segundos (por defecto).
- m: Minutos.
- h: Horas.
- d: Días.

Es posible utilizar números enteros o decimales para especificar el tiempo de pausa.

**Ejemplos de Uso**

Aquí hay algunos ejemplos de cómo se puede utilizar el comando sleep:
1. Pausar un proceso durante 10 segundos:
![captura1](/assets/img/posts/comando-progra/comando-progra1.jpg)
2. Pausar un proceso durante 2 minutos:
![captura2](/assets/img/posts/comando-progra/comando-progra2.jpg)
3. Pausar un proceso durante 1 hora y media:
![captura3](/assets/img/posts/comando-progra/comando-progra3.jpg)
4. Pausar un proceso durante 3 días:                             
![captura4](/assets/img/posts/comando-progra/comando-progra4.jpg)
5. Pausar un proceso durante una combinación de tiempos (1 día, 2 horas, 3 minutos y 4 segundos):
![captura5](/assets/img/posts/comando-progra/comando-progra5.jpg)
6. Pausar un proceso durante 0.5 segundos (usando un número decimal):
![captura6](/assets/img/posts/comando-progra/comando-progra6.jpg)
7. Ejecutar varios comandos sleep de forma consecutiva o utilizar el operador && para ejecutar otro comando después de sleep:
![captura7](/assets/img/posts/comando-progra/comando-progra7.jpg)
8. Este script se ejecutará en un bucle infinito, pero se pausará durante 10 minutos en cada iteración utilizando sleep.
```
echo "Este script se ejecutará cada 10 minutos."
while true; do
# Comandos que deseas ejecutar
sleep 10m
done
```

El comando sleep es especialmente útil en scripts de shell para introducir retrasos
entre la ejecución de diferentes comandos, para reintentar operaciones fallidas después de un tiempo, o para esperar a que se cumplan ciertas condiciones, como la disponibilidad de una conexión de red.

En resumen, **sleep** es una herramienta simple pero poderosa para controlar el flujo
de ejecución en scripts y procesos en sistemas operativos basados en Linux.

## 2. Watch
El comando **watch** en Linux es una herramienta que permite a los usuarios
monitorizar continuamente los cambios en un archivo o el resultado de un comando en tiempo real. Este comando ejecuta otros comandos de forma repetitiva y muestra los resultados en tiempo real. Por defecto, watch ejecuta el comando especificado cada 2 segundos y muestra los resultados en la terminal.

**Opciones y Parámetros**

Las opciones más comunes para el comando watch son:

- **-n segundos**: Esta opción permite especificar el intervalo de tiempo en segundos entre cada ejecución del comando.
- **-d**: Esta opción es usada para destacar las diferencias entre las actualizaciones
- **-t**: Esta opción elimina el encabezado que muestra el intervalo, el comando y la hora actual
- **-g** o **--chgexit**: Esta opción permite que watch termine la ejecución en el caso de que se haya modificado la salida

**Ejemplos de Uso**

Aquí hay algunos ejemplos de cómo se puede utilizar el comando watch:

1. Monitorizar el uso de la memoria del servidor cada segundo:
![captura8](/assets/img/posts/comando-progra/comando-progra8.jpg)
![captura9](/assets/img/posts/comando-progra/comando-progra9.jpg)
2. Ejecutar el comando ls cada 5 segundos:
![captura10](/assets/img/posts/comando-progra/comando-progra10.jpg)
![captura11](/assets/img/posts/comando-progra/comando-progra11.jpg)
3. Resaltar las diferencias entre las actualizaciones al ejecutar el comando date:
![captura12](/assets/img/posts/comando-progra/comando-progra12.jpg)
![captura13](/assets/img/posts/comando-progra/comando-progra13.jpg)
4. Eliminar el encabezado al ejecutar el comando free:
![captura14](/assets/img/posts/comando-progra/comando-progra14.jpg)
![captura15](/assets/img/posts/comando-progra/comando-progra15.jpg)
5. Terminar la ejecución si el uso de memoria ha cambiado:
![captura16](/assets/img/posts/comando-progra/comando-progra16.jpg)
6. Observar el estado de la memoria con free, refrescando cada décima de segundo:
![captura17](/assets/img/posts/comando-progra/comando-progra17.jpg)
![captura18](/assets/img/posts/comando-progra/comando-progra18.jpg)
7. Observar las conexiones de red con netstat cada segundo:
![captura19](/assets/img/posts/comando-progra/comando-progra19.jpg)
![captura20](/assets/img/posts/comando-progra/comando-progra20.jpg)

El comando watch es una herramienta muy útil para realizar monitorización en tiempo real en Linux, especialmente para observar la disponibilidad de recursos de red, CPU, memoria, entre otros.

## 3. At
El comando **at** en Linux es una herramienta que permite programar tareas únicas para que se ejecuten en un momento específico. Este comando es útil para programar tareas como apagar el sistema a una hora específica, realizar una copia de seguridad única, enviar un correo electrónico como recordatorio a la hora especificada, entre otras cosas.

**Opciones y Parámetros**

Las opciones más comunes para el comando at son:
- atq: Lista los trabajos programados.
- atrm: Elimina trabajos programados. Se utiliza seguido del número de
trabajo, por ejemplo, atrm.
- **at [hora] [fecha]**: Programa una tarea para que se ejecute en la hora y fecha
especificadas.

**Ejemplos de Uso**

Aquí hay algunos ejemplos de cómo se puede utilizar el comando **at**:

1. Programar una tarea para que se ejecute a las 10:00 PM:
![captura21](/assets/img/posts/comando-progra/comando-progra21.jpg)
2. Programar una tarea para que se ejecute a las 04:00 AM, copiando un
archivo, eliminándolo del directorio original y apagando el PC:
```
at 04:00
cp /home/usuario/Escritorio/imagen.iso /home/usuario/isos
rm /home/usuario/Escritorio/imagen.iso
shutdown -h now
```
Luego presionar Ctrl + D para terminar de ingresar las instrucciones.
3. Listar los trabajos programados:                               
![captura22](/assets/img/posts/comando-progra/comando-progra22.jpg)
4. Eliminar un trabajo programado, por ejemplo, el trabajo número 3:
![captura23](/assets/img/posts/comando-progra/comando-progra23.jpg)
5. Programar una tarea para que se ejecute a las 11:40 del 26 de febrero de 2023, listando los archivos en la ruta /tmp:
```
at 11:40 2023-02-26
ls -ltr /tmp > "~/prueba_comando_at.txt"
echo 'finalizado ' >> "~/prueba_comando_at.txt"
```
Luego presionar ctrl + D para terminar de ingresar las instrucciones.

Ten en cuenta que para que el comando at funcione correctamente, lo tendremos que instalar con un *sudo apt install at* y debe estar corriendo el servicio atd (at daemon). Para habilitarlo en sistemas que usan systemd, puedes ejecutar: *sudo systemctl enable --now atd*.

## 4. Crontab
El comando **crontab** en Linux es una herramienta que permite programar tareas para que se ejecuten automáticamente a intervalos regulares. Este comando es útil para automatizar tareas como realizar copias de seguridad, enviar correos electrónicos, limpiar directorios, entre otras cosas.

**Opciones y Parámetros**

Las opciones más comunes para el comando crontab son:
- **crontab -e**: Permite editar el archivo crontab del usuario actual.
- **crontab -l**: Muestra la lista de trabajos programados para el usuario actual.
- **crontab -r**: Elimina todos los trabajos programados para el usuario actual.
- **crontab -u [usuario] -e**: Permite editar el archivo crontab de otro usuario (requiere privilegios de superusuario).

**Ejemplos de Uso**

Aquí hay algunos ejemplos de cómo se puede utilizar el comando **crontab**:

1. Programar una tarea para que se ejecute todos los días a las 5:00 PM:
```
crontab -e
0 17 * * * /ruta/del/script.sh
```
Luego presionar ctrl + X y luego Y para guardar y salir (si estás utilizando el editor nano).
2. Listar los trabajos programados:                               
![captura23](/assets/img/posts/comando-progra/comando-progra23.jpg)
3. Eliminar todos los trabajos programados:
![captura24](/assets/img/posts/comando-progra/comando-progra24.jpg)
4. Programar una tarea para que se ejecute cada minuto:
```
crontab -e
* * * * * /ruta/del/comando
```
5. Programar una tarea para que se ejecute cada lunes a las 6:30 AM:
```
crontab -e
30 6 * * 1 /ruta/del/comando
```

En los ejemplos anteriores, la sintaxis de los cinco asteriscos en las entradas de crontab representa minuto (0-59), hora (0-23), día del mes (1-31), mes (1-12) y día de la semana (0-7, donde tanto 0 como 7 representan el domingo), respectivamente.

## 5. Conclusión
En resumen, los comandos **sleep**, **watch**, **at** y **crontab** son herramientas esenciales en sistemas operativos basados en Linux, como Debian, para la gestión del tiempo y la automatización de tareas.

Estas herramientas proporcionan a los usuarios y administradores de sistemas una
gran flexibilidad para programar y automatizar tareas, optimizando así el flujo de
trabajo y la eficiencia del sistema.

## 6. Bibliografía
[IONOS](https://www.ionos.es/digitalguide/servidores/configuracion/comando-de-linux-sleep/)

[Montblanczone](https://montblanczone.com/es/que-hace-el-comando-sleep-en-linux/)

[Hostgator](https://www.hostgator.mx/blog/comando-watch-linux/)