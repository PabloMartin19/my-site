---
title: "Práctica: Certificados digitales. HTTPS"
date: 2024-12-19 17:30:00 +0000
categories: [Seguridad, Criptografía]
tags: [Criptografía]
author: pablo
description: "...."
toc: true
comments: true
image:
  path: /assets/img/posts/certificado/portada.png
---

## Tarea 1: Instalación del certificado

### 1. Una vez que hayas obtenido tu certificado, explica brevemente como se instala en tu navegador favorito.

Para la instalación del certificado digital en mi navegador (Firefox), debemos dirigirnos al correo que nos manda la Fábrica Nacional de Moneda y Timbre al realizar la solicitud:

![image](/assets/img/posts/certificado/paso1.png)

Pinchamos en el enlace de descarga he introducimos los datos para continuar con la descarga:

![image](/assets/img/posts/certificado/paso2.png)

Una vez que hayamos descargado el certificado digital desde la FNMT, normalmente estará en formato `.p12`. Este archivo contiene tanto la clave pública como la clave privada del certificado.

Por lo que para la instalación:

1. Abrimos Firefox y nos dirigimos al menú principal (ícono de tres líneas horizontales).

2. Hacemos clic en Ajustes y luego seleccionamos la sección **Privacidad & Seguridad**.

3. Nos desplazamos hasta la opción **Certificados** y pulsamos el botón **Ver Certificados**.

4. En la pestaña **Sus Certificados**, seleccionamos **Importar...** y buscamos el archivo `.p12`.

5. Durante la importación, nos pedirá la contraseña que asignamos al descargar el certificado.

Una vez completado, el certificado aparecerá en la lista de certificados personales.

### 2. Muestra una captura de pantalla donde se vea las preferencias del navegador donde se ve instalado tu certificado.

![image](/assets/img/posts/certificado/certificado.png)

### 3. ¿Cómo puedes hacer una copia de tu certificado?, ¿Como vas a realizar la copia de seguridad de tu certificado?. Razona la respuesta.

- En el menú de opciones: **Preferencias** > **Privacidad y seguridad** > **Seguridad** > **Certificados**. 
- Selecciona **Ver certificados**.
- En **Sus Certificados** selecciona **Hacer copia**.

De esta forma se realiza una copia del certificado digital. Y se introduce en un dispositivo externo para tener la copia.

El certificado digital es único y personal. Si perdemos el archivo o la clave privada, no podremos firmar documentos ni realizar trámites online que requieran autenticación. Además, una pérdida implicaría solicitar de nuevo el certificado desde cero a la FNMT.

### 4. Investiga como exportar la clave pública de tu certificado.

En **Preferencias** > **Privacidad y seguridad** > **Seguridad** > **Certificados** > **Ver certificados** hacemos doble click sobre el certificado para que aparezca el visor de certificados. En la pestaña **Detalles** da la opción de **Exportar...**.

Una vez descargado el `.pem` debemos extraer la clave pública, pues en un principio estará cifrado y no podremos ver el contenido. Para ello:

```bash
pavlo@debian:~/certificado()$ ls -l
total 12
-rw-r--r-- 1 pavlo pavlo 7010 dic 20 20:39 MARTIN_HIDALGO_PABLO.p12
-rw-r--r-- 1 pavlo pavlo 3012 dic 27 17:29 martin-hidalgo-pablo.pem
pavlo@debian:~/certificado()$ sudo openssl pkcs12 -in MARTIN_HIDALGO_PABLO.p12 -clcerts -nokeys -out martin-hidalgo-pablo.pem
Enter Import Password:
```

Donde:

- `-in MARTIN_HIDALGO_PABLO.p12`: Especifica el archivo de entrada en formato .p12.
- `-clcerts`: Indica que se extraiga únicamente el certificado del archivo, excluyendo certificados de la cadena o intermedios.
- `-nokeys`: Evita que se exporte la clave privada.
- `-out martin-hidalgo-pablo.pem`: Especifica el nombre del archivo de salida que contendrá la clave pública en formato PEM.

Una vez hecho esto ya podremos ver la clave pública.

## Tarea 2: Validación del certificado

### 1. Instala en tu ordenador el software autofirma y desde la página de VALIDe valida tu certificado. Muestra capturas de pantalla donde se comprueba la validación.

Descargamos el software desde la página https://firmaelectronica.gob.es/Home/Descargas.html. El archivo es un .zip.

Antes de descomprimirlo, es necesario un paquete de java, donde tenemos que instalar los siquientes paquetes:

```bash
pavlo@debian:~()$ sudo apt-get install default-jr
pavlo@debian:~()$ sudo apt-get install default-jdk
```

Una vez instalados los paquetes y descargada la herramienta necesaria:

```bash
pavlo@debian:~/Descargas()$ unzip AutoFirma_Linux_Debian.zip
pavlo@debian:~/Descargas()$ sudo apt install libnss3-tools
pavlo@debian:~/Descargas()$ sudo dpkg -i AutoFirma_1_8_3.deb
```

Después de instalar el software de AutoFirma nos dirigimos a la página web [VALIDe](https://valide.redsara.es/valide/validarCertificado/ejecutar.html) para verificar el certificado.

En donde debemos seleccionar el certificado:

![image](/assets/img/posts/certificado/valide.png)

E introducir el código de seguridad del CAPTCHA. Y ya tendríamos el certificado validado correctamente:

![image](/assets/img/posts/certificado/verificacion.png)

## Tarea 3: Firma electrónica

### 1. Utilizando la página VALIDe y el programa autofirma, firma un documento con tu certificado y envíalo por correo a un compañero.    

Para esta apartado voy a crear dos ficheros para posteriormente firmarlos con nuestro certificado digital. Uno de ellos se llamará `ficherovalide.txt` y otro `ficheroautofirma.txt`

```bash
pavlo@debian:~/certificado()$ echo 'Este fichero está firmado por VALIDe' > ficherovalide.txt
pavlo@debian:~/certificado()$ echo 'Este fichero está firmado por AutoFirma' > ficheroautofirma.txt
```

Una vez generados los ficheros vamos a proceder a firmar el primero de ellos a través de la página [VALIDe](https://valide.redsara.es/valide/). En este caso, pulsaremos en el apartado **Realizar Firma**.

Dentro del mismo, pulsaremos en **Firmar** y acto seguido nos pedirá el fichero que deseamos firmar. En este caso, tendremos que elegir el fichero `ficherovalide.txt`, indicando además el certificado que queremos utilizar para ello.

Si todo ha salido correctamente nos saldrá el siguiente mensaje:

![image](/assets/img/posts/certificado/ficherovalide.png)

Como se puede apreciar, se ha indicado que la firma se ha realizado correctamente, por lo que pulsaremos en **Guardar Firma** para así almacenar en nuestra máquina el fichero resultante de dicho proceso. En mi caso, he decidido asignarle el nombre `ficherovalide.txt_firmado.csig`, para así diferenciarlo.

Bien, ya hemos firmado uno de los dos, así que para el siguiente, volveremos a la aplicación de escritorio AutoFirma y elegiremos en éste caso el fichero `ficheroautofirma.txt`. Tras ello, pulsaremos en Firmar y nos pedirá el certificado a usar para la firma, seguido de la ruta donde almacenar el fichero resultante, que en este caso, he decidido asignarle el nombre `ficheroautofirma.txt_firmado.csig`.

Si todo ha funcionado correctamente obtendremos el siguiente mensaje informativo:

![image](/assets/img/posts/certificado/ficheroautofirma.png)


### 2. Tu debes recibir otro documento firmado por un compañero y utilizando las herramientas anteriores debes visualizar la firma (Visualizar Firma) y (Verificar Firma). ¿Puedes verificar la firma aunque no tengas la clave pública de tu compañero?, ¿Es necesario estar conectado a internet para hacer la validación de la firma?. Razona tus respuestas.

Para verificar estas firmas, accederemos a la plataforma VALIDe y seleccionaremos la opción "Validar Firma". 

En esta sección, elegiremos el archivo firmado que deseamos comprobar. En este caso, seleccionaremos el archivo **hola.txt_signed.csig**, completaremos el Captcha solicitado y haremos clic en "Validar". 

Si el proceso se realiza correctamente, obtendremos un mensaje informativo que confirma que la validación ha sido exitosa: 

![image](/assets/img/posts/certificado/joseautofirma.png)

Este mensaje indica que la firma ha sido validada correctamente, lo que certifica que el archivo ha sido firmado por mi compañero, quien no puede negar haber realizado esta acción. Luego, repetiremos el mismo procedimiento con el archivo **hola2.txt_firmado.csig** y obtendremos el siguiente resultado:

![image](/assets/img/posts/certificado/mensajevalidejose.png)

### 3. Entre dos compañeros, firmar los dos un documento, verificar la firma para comprobar que está firmado por los dos.

![image](/assets/img/posts/certificado/kk.png)

![image](/assets/img/posts/certificado/firmadoporlosdos.png)

## Tarea 4: Autentificación

Accedemos a la web de la [DGT](https://sede.dgt.gob.es/es/permisos-de-conducir/permiso-por-puntos/consulta-de-puntos/) para verificar el funcionamiento de nuestro certificado digital accediendo a nuestro historial de puntos.

![image](/assets/img/posts/certificado/dgt.png)

Podremos elegir entre los distintos tipos de acceso y elegimos Cl@ve. Seguidamente, pulsaremos en DNIe / Certificado electrónico y se abrirá una ventana emergente. En dicha ventana emergente tendremos que seleccionar aquel certificado que queremos utilizar para la autenticación, así que en mi caso, seleccionaré el único disponible, de manera que si no ha habido ningún problema, nos habremos autenticado en la página de la Dirección General de Tráfico sin tener que introducir ningún tipo de credenciales:

![image](/assets/img/posts/certificado/puntosdgt.png)
