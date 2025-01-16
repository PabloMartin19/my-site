---
title: "Systemd-Boot"
date: 2025-01-14 13:30:00 +0000
categories: [Sistemas, Systemd]
tags: [Systemd]
author: pablo
description: "...."
toc: true
comments: true
image:
  path: /assets/img/posts/systemd-boot/Debian-13-Trixie.png
---

Los desarrolladores de Debian han propuesto el uso de systemd-boot para instalaciones UEFI de Debian Trixie, que se lanzará en 2025. Opción disponible, de momento, en instalaciones debian 13 en modo experto. El objetivo es agregar soporte de arranque seguro firmado a Debian para intentar resolver el problema relacionado con UEFI y Secure Boot con sistemas Debian. Proponen utilizar un gestor de arranque llamado “systemd-boot” para mejorar el proceso de arranque de Debian en sistemas UEFI.

## 1. Instala en máquina virtual, debian 13 con systemd-boot, y familiarízate con este nuevo gestor de arranque.

En esta parte del artículo, aprenderemos a instalar Debian 13 (Trixie) con el gestor de arranque systemd-boot en un sistema UEFI.

Comenzamos descargando la ISO de Debian 13 Trixie desde la página oficial del [proyecto Debian](https://www.debian.org/devel/debian-installer/). En esta sección elegiremos la opción que más nos convenga, en mi caso la **netinst**.

En esta instalación utilizaremos **QEMU/KVM** como plataforma de virtualización para crear la máquina virtual. Es fundamental configurar correctamente UEFI antes de comenzar la instalación, ya que Debian 13 utiliza este modo de arranque junto con `systemd-boot`.

![image](/assets/img/posts/systemd-boot/uefi.png)

Para asegurarnos de que `systemd-boot` se instale correctamente en Debian 13, es imprescindible seleccionar la instalación en modo experto. Esto nos permitirá elegir manualmente el gestor de arranque y realizar configuraciones avanzadas.

En lugar de seleccionar la opción estándar Install, elegimos "Advanced options" y luego "Expert install".

![image](/assets/img/posts/systemd-boot/expert.png)

Una vez elegida esta opción, seguimos con las instalación en donde primero de todo debemos elegir el idioma:

![image](/assets/img/posts/systemd-boot/uefi.png)

Durante la instalación en modo experto de Debian 13, el instalador puede ofrecer una opción llamada "Detectar y montar el medio de instalación". Esta opción es especialmente útil si estamos utilizando una instalación por red o un medio de instalación que no es el disco duro local (por ejemplo, un USB o una ISO montada). Por lo tanto, seleccionamos la que nos muestra automáticamente.

![image](/assets/img/posts/systemd-boot/montar.png)

![image](/assets/img/posts/systemd-boot/usb.png)

Seguidamente nos mostrará una serie de componentes opcionales para descargarlos en caso de ser necesarios. Yo personalmente no he seleccionado ninguno, pues para el objetivo de esta práctica no nos hará falta:

![image](/assets/img/posts/systemd-boot/componentes.png)

Luego, nos pedirá como queremos configurar la red, elegimos automáticamente:

![image](/assets/img/posts/systemd-boot/dhcp.png)

Una vez seleccionado esto, seguiremos con la instalación tal y como estamos acostumbrados. Pero llegados al punto del particionado de discos debemos pararnos.

El particionado del disco es una de las etapas clave en la instalación de Debian, especialmente cuando estamos configurando un sistema UEFI. Al seleccionar el particionado del disco, es importante configurar adecuadamente las particiones para que Debian se instale correctamente y utilice `systemd-boot` como gestor de arranque.

Por lo tanto, debemos seleccionar que queremos un **particionado manual**, pues nos permite tener un control total sobre cómo se organiza el disco.

Luego, seleccionamos el disco donde realizaremos el particionado, en este caso solo disponemos de uno:

![image](/assets/img/posts/systemd-boot/disco.png)

Nos preguntará que si queremos particionar el disco y le diremos que "Sí", luego nos dará a elegir que tipo de tabla de partición vamos a utilizar. En este caso seleccionamos `gpt`:

![image](/assets/img/posts/systemd-boot/gpt.png)

Ahora, debemos realizar el particionado, el cual yo haré de la siguiente forma:

1. Partición EFI:

- **Tipo**: `EFI System Partition`
- **Tamaño recomendado**: Al menos 100 MB, aunque se recomienda entre 300 MB y 500 MB para asegurar un arranque adecuado.
- **Punto de montaje**: `/boot/efi`
- Esta partición es crucial para UEFI, ya que contiene los archivos del cargador de arranque, como `systemd-boot`.

2. Partición raíz (/):

- **Tipo**: `ext4`
- **Tamaño recomendado**: Al menos 20 GB o más
- **Punto de montaje**: `/`
- Esta partición contendrá el sistema operativo y todos los archivos de configuración.

3. Área de intercambio (swap):

- **Tipo**: Linux swap
- **Tamaño recomendado**: el tamaño será el restante, en este caso 142MB.
- Esta partición es utilizada como espacio de intercambio cuando la RAM se llena.

De forma que el particionado quedaría de la siguiente forma:

![image](/assets/img/posts/systemd-boot/particionado.png)

Una vez que hayamos creado y configurado las particiones, el instalador nos pedirá que confirmemos el esquema de particionado. Si todo es correcto, seleccionaremos "Sí" para aplicar los cambios. Esto formateará el disco y creará las particiones seleccionadas.

Bien, pues una vez realizado el particionado debemos instalar el sistema base, el cual nos dará a elegir que núcleo queremos. Yo personalmente he seleccionado la segunda opción:

![image](/assets/img/posts/systemd-boot/base.png)

Después, nos pedirá que opción elegir en cuanto a los controladores se refiere. Yo elegiré "dirigido", pues para esta práctica no me interesa cargar tantos drivers.

![image](/assets/img/posts/systemd-boot/dirigido.png)

Cuando lleguemos a la parte del proceso de instalación donde el instalador te pregunta si deseas analizar medios de instalación adicionales, es importante seleccionar "No".

Esta opción permite al instalador buscar e instalar paquetes adicionales desde otros medios (por ejemplo, discos o dispositivos USB adicionales que contengan paquetes de instalación). Sin embargo, en la mayoría de los casos, no es necesario agregar más medios de instalación si ya estamos utilizando una imagen ISO completa o una instalación por red.

![image](/assets/img/posts/systemd-boot/apt.png)

Cuando lleguemos a la opción de "¿Desea utilizar una réplica en red?" durante la instalación, es importante seleccionar "Sí".

![image](/assets/img/posts/systemd-boot/netiso.png)

En este paso, el instalador te da la opción de utilizar una **réplica en red** (mirror) para obtener paquetes adicionales y actualizaciones durante el proceso de instalación. Dado que estás utilizando una imagen de instalación mínima (**netinst**), el sistema base que se instalará inicialmente será bastante reducido. Al seleccionar "Sí", podrás acceder a una réplica en red que proporcionará los paquetes necesarios para completar la instalación y actualizar el sistema.

Al hacerlo, se descargará software adicional y se instalarán los paquetes que permiten completar un sistema Debian completamente funcional.

Seguidamente seleccionamos HTTP como el protocolo para acceder a la réplica en red.

![image](/assets/img/posts/systemd-boot/http.png)

En esta etapa del proceso de instalación, nos preguntará si queremos usar firmware no libre para que ciertos componentes de hardware (como tarjetas Wi-Fi, chipsets de audio, etc.) funcionen correctamente.

El firmware no libre es necesario para que algunos dispositivos de hardware funcionen, pero no es software libre. Sin embargo, Debian ofrece estos firmwares para garantizar la compatibilidad con una amplia variedad de hardware, aunque sus licencias restringen la libertad de usar, modificar o compartir el software.

Seleccionar "Sí" en esta opción permitirá que el instalador cargue y use los firmwares no libres que puedan ser necesarios para que tu hardware funcione correctamente, especialmente si estás utilizando hardware específico que requiere controladores no libres.

![image](/assets/img/posts/systemd-boot/firmware.png)

![image](/assets/img/posts/systemd-boot/kk.png)

![image](/assets/img/posts/systemd-boot/repo.png)

En esta etapa, se te preguntará si deseas habilitar ciertos servicios de actualización para tu sistema Debian. Debian ofrece dos servicios principales relacionados con las actualizaciones: actualizaciones de seguridad y actualizaciones de la distribución.

1. **Actualizaciones de seguridad**: Estas actualizaciones son fundamentales para mantener el sistema protegido contra vulnerabilidades de seguridad. Debian recomienda encarecidamente habilitar este servicio para recibir actualizaciones que solucionen posibles fallos de seguridad en el sistema.

2. **Actualizaciones de la distribución**: Este servicio ofrece versiones más recientes de los paquetes del sistema que contienen cambios importantes. Mantener este servicio habilitado asegura que el sistema se mantenga actualizado con las últimas versiones estables de los paquetes.

3. **Programas migrados a nuevas versiones (opcional)**: Esta opción permite acceder a programas más recientes que se encuentran en desarrollo o que han sido migrados a una nueva versión. Estos paquetes pueden no ser tan estables, ya que no han sido probados completamente, pero pueden ofrecer nuevas características.

Por lo tanto, dejamos marcadas las dos primeras opciones que vienen por defecto:

![image](/assets/img/posts/systemd-boot/actu.png)

En esta parte nos dirá si queremos que se realicen actualizaciones automáticas, aunque es una opción interesante, para esta práctica seleccionaremos que no:

![image](/assets/img/posts/systemd-boot/auto.png)

En la selección de programas elegiremos a nuestro gusto:

![image](/assets/img/posts/systemd-boot/gnome.png)

Después de varios minutos en los que el instalador descarga e instala los paquetes del sistema, llegamos a uno de los puntos más importantes de la instalación: la selección del cargador de arranque.

El cargador de arranque es un software esencial que permite iniciar el sistema operativo tras encender el equipo. Tradicionalmente, Debian utiliza GRUB como su gestor de arranque por defecto, pero en esta instalación estamos configurando systemd-boot, un gestor más ligero y moderno diseñado específicamente para sistemas UEFI.

![image](/assets/img/posts/systemd-boot/systemd-boot.png)

Después de completar la instalación del sistema y llegar al momento del reinicio, **es necesario desactivar el "Secure Boot" en el firmware UEFI** para que el cargador de arranque `systemd-boot` funcione correctamente.

**¿Por qué desactivar Secure Boot?**

El **Secure Boot** es una característica de UEFI diseñada para evitar que se cargue software no firmado o malicioso al iniciar el sistema. Sin embargo, en algunos casos, como al instalar Debian con `systemd-boot`, el firmware puede bloquear el arranque si el sistema operativo no está firmado digitalmente o no es compatible con el Secure Boot.

`systemd-boot` es un gestor de arranque que no siempre es compatible con **Secure Boot** de forma predeterminada, por lo que es necesario desactivarlo para permitir que el sistema se inicie correctamente.

Para desactivarlo seguimos los pasos de las siguientes capturas:

![image](/assets/img/posts/systemd-boot/bios1.png)

![image](/assets/img/posts/systemd-boot/bios2.png)

![image](/assets/img/posts/systemd-boot/bios3.png)

Guardamos los cambios con F10 y le damos a "Continue", de esta forma ya se iniciará correctamente el sistema:

![image](/assets/img/posts/systemd-boot/debiantrixie.png)

Después de haber reiniciado el sistema con Secure Boot desactivado, es importante verificar que el cargador de arranque `systemd-boot` se ha instalado y configurado correctamente.

Para hacerlo, utilizamos el siguiente comando en la terminal:

```bash
root@debian:~# bootctl status
```

![image](/assets/img/posts/systemd-boot/bootctl.png)

`bootctl` es una herramienta integrada en `systemd` que permite gestionar `systemd-boot`. El subcomando status muestra información sobre el estado actual del gestor de arranque.

Como podemos observar en la imagen, systemd-boot está instalado y configurado correctamente. 

Por último, podemos ver la versión de Debian instalando Neofetch:

![image](/assets/img/posts/systemd-boot/neofetch.png)

Y como vemos nos sale la versión correcta:

![image](/assets/img/posts/systemd-boot/neo.png)

## 2. Cambiar el tradicional gestor de arranque grub por systemd boot en una máquina virtual con debian 12.

