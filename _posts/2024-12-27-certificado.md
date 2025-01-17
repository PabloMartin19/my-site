---
title: "Certificados digitales. HTTPS"
date: 2024-12-19 17:30:00 +0000
categories: [Seguridad, Criptografía]
tags: [Criptografía]
author: pablo
description: "En esta práctica vamos a trabajar con certificados digitales para autenticarnos, firmar documentos y securizar una página web con HTTPS. Primero, instalaremos un certificado digital de persona física en nuestro navegador y aprenderemos a hacer copias de seguridad. Luego, validaremos el certificado con Autofirma y la plataforma VALIDe. También utilizaremos nuestra firma digital para firmar y verificar documentos. Finalmente, configuraremos un servidor web con Apache y Nginx usando certificados autofirmados, aprendiendo a generar claves privadas, CSR y certificados X.509 con nuestra propia Autoridad Certificadora. 🔒✅"
toc: true
comments: true
image:
  path: /assets/img/posts/certificado/portada.png
---

## Certificado digital de persona física

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


## HTTPS / SSL

Antes de hacer esta práctica vamos a crear una página web (puedes usar una página estática o instalar una aplicación web) en un servidor web apache2 que se acceda con el nombre `tunombre.iesgn.org`.

### Preparación del sitio web

Para realizar este punto, instalaremos un servidor apache, y lo configuraremos para que nos sirva una página web con https. Para ello, deberemos seguir los siguientes pasos:

- Instalamos el servidor:

```bash
debian@https:~$ sudo apt install apache2
```

- Deshabilitamos el VirtualHost que viene por defecto para que no nos dé problemas:

```bash
debian@https:~$ sudo a2dissite 000-default.conf
Site 000-default disabled.
To activate the new configuration, you need to run:
  systemctl reload apache2
debian@https:~$ sudo systemctl reload apache2
```

- Creamos un nuevo fichero de configuración donde irá el contenido:

```bash
debian@https:~$ sudo mkdir /var/www/html/pablo.iesgn.org
debian@https:~$ sudo nano /var/www/html/pablo.iesgn.org/index.html
debian@https:~$ cat /var/www/html/pablo.iesgn.org/index.html
<!DOCTYPE html>
            <html>
                <head>
                <title>pablo.iesgn.org</title>
                </head>
            <body>
                <h1>pablo.iesgn.org</h1>
                <p>Pagina web sencilla para criptografia - HTTPS/SSL</p>
            </body>
        </html>
```

- Ahora creamos un archivo de configuración para el dominio `pablo.iesgn.org`

```shell
debian@https:~$ cat /etc/apache2/sites-available/pablo.iesgn.org.conf
<VirtualHost *:80>
    ServerName pablo.iesgn.org
    DocumentRoot /var/www/html/pablo.iesgn.org

    <Directory /var/www/html/pablo.iesgn.org>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/pablo.iesgn.org_error.log
    CustomLog ${APACHE_LOG_DIR}/pablo.iesgn.org_access.log combined
</VirtualHost>
```

- Habilitamos el nuevo VirtualHost y reiniciamos el servicio de Apache.

```bash
debian@https:~$ sudo a2ensite pablo.iesgn.org.conf
Enabling site pablo.iesgn.org.
To activate the new configuration, you need to run:
  systemctl reload apache2
debian@https:~$ sudo systemctl reload apache2
```

- Por último tenemos que realizar la resolución estática, pues la página web está en una instancia de OpenStack:

```bash
debian@https:~$ cat /etc/hosts
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

172.22.200.222	pablo.iesgn.org
```

```bash
pavlo@debian:~()$ cat /etc/hosts
127.0.0.1	localhost
127.0.1.1	debian
172.22.203.178  django-pablo.com
#172.22.7.9	wordpress.pablo.beer
#172.22.9.234	biblioteca.pablo.org
172.22.123.1	proxmox.gonzalonazareno.org
172.22.200.222	pablo.iesgn.org

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

Y como vemos la página ya se puede ver correctamente:

![image](/assets/img/posts/certificado/paginaweb.png)

## Tarea 1: Certificado autofirmado

Esta práctica la vamos a realizar con un compañero. En un primer momento un alumno creará una Autoridad Certficadora y firmará un certificado para la página del otro alumno. Posteriormente se volverá a realizar la práctica con los roles cambiados.

Para hacer esta práctica puedes buscar información en internet, algunos enlaces interesantes:

[Phil’s X509/SSL Guide](https://www.phildev.net/ssl/)
[How to setup your own CA with OpenSSL](https://gist.github.com/Soarez/9688998)

En esta ocasión voy a ser yo el que haga de autoridad certificadora, de manera que podremos firmar el certificado para que nuestro compañero pueda implementar HTTPS en su servidor.

### Crear una autoridad certificadora

El primer paso consiste en establecer un directorio base para la Autoridad Certificadora (CA), con subdirectorios dedicados a diferentes funciones. Esto ayudará a mantener la organización durante todo el proceso. En este ejemplo, el directorio principal será CA/ y contendrá:

- **certsdb**: Almacén de certificados firmados.

- **certreqs**: Almacén de solicitudes de firma de certificados (CSR).

- **crl**: Almacén de la lista de certificados revocados (CRL).

- **private**: Almacén para la clave privada de la autoridad certificadora.

Para crear esta estructura de directorios, ejecutaremos:

```bash
debian@https:~$ mkdir -p CA/{certsdb,certreqs,crl,private}
```

Una vez creados los directorios, accedemos al directorio principal y visualizamos la estructura:

```bash
debian@https:~/CA$ tree
.
├── certreqs
├── certsdb
├── crl
└── private
```

Como el directorio `private` contendrá información sensible (la clave privada de la CA), es importante restringir su acceso únicamente al propietario. Cambiamos sus permisos a `700`:

```bash
debian@https:~/CA$ chmod 700 ./private
```

La CA necesitará un archivo que actúe como base de datos para registrar los certificados emitidos. Este archivo se creará con:

```bash
debian@https:~/CA$ touch index.txt
```

En este paso, copiaremos el archivo de configuración predeterminado de OpenSSL a nuestro directorio de trabajo y lo personalizaremos para adaptarlo a nuestra CA.

1. Buscamos el archivo de configuración de OpenSSL en nuestro sistema. Las ubicaciones comunes son:

- `/usr/lib/ssl/openssl.cnf`

- `/etc/openssl.cnf`

- `/usr/share/ssl/openssl.cnf`

2. Copiamos el archivo al directorio CA:

```bash
debian@https:~/CA$ cp /usr/lib/ssl/openssl.cnf ./
```

3. Realizamos las siguientes modificaciones para que OpenSSL utilice los directorios creados anteriormente:

```bash
dir             = /home/debian/CA
certs           = $dir/certsdb
new_certs_dir   = $certs

countryName_default             = ES
stateOrProvinceName_default     = Sevilla
localityName                    = Dos Hermanas
0.organizationName              = PabloMartin SL
organizationalUnitName          = Informatica

#challengePassword              = A challenge password
#challengePassword_min          = 4
#challengePassword_max          = 20

#unstructuredName               = An optional company name
```

Importante recalcar que estas solo son las modificaciones que yo he realizado, no es el fichero de configuración al completo.

Tras ello, ya tendremos todo listo para generar nuestro par de claves y un fichero de solicitud de firma de certificado que posteriormente nos autofirmaremos, ejecutando para ello el comando:

```bash
debian@https:~/CA$ sudo openssl req -new -newkey rsa:2048 -keyout private/cakey.pem -out careq.pem -config ./openssl.cnf
..+...+.+.....+.+.....+....+..+...+.......+.....+...+..........+.........+..+...+.+.................+...................+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...+...........................+.+...+.........+..+..........+...+......+..+...+.......+..+.+.....+.........+....................................+.........+.+......+.....+..........+...+..................+.........+.....+...+.+..+...+....+...+.........+.........+.........+.....+.......+...+..................+...+..+....+......+...+...........+...+.......+...+.....+...+....+......+............+.................+................+..............+....+...........+........................+.+.....+......+..........+.....+....+...............+......+...+..+....+...+...+.........+........+.+.........+..+.+.........+...+..+....+..+...+....+........+.......+..+....+.....+............+...+......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
....+.+........+....+..+....+.........+...............+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...+............+..+.......+.....+....+..+...+....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*..+............+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [ES]:
State or Province Name (full name) [Sevilla]:
Dos Hermanas []:
PabloMartin SL [Internet Widgits Pty Ltd]:
Informatica []:
Common Name (e.g. server FQDN or YOUR name) []:pablo.debian
Email Address []:pmartinhidalgo19@gmail.com
```

El comando para crear un nuevo par de claves y una solicitud de firma de certificado (CSR) incluye estas opciones:

- -new: Genera un par de claves nuevo.
- -newkey: Define el tipo y tamaño del par de claves, en este caso RSA de 2048 bits.
- -keyout: Especifica la ubicación donde se guardará la clave privada (por ejemplo, en private/cakey.pem).
- -out: Define dónde guardar el CSR (por ejemplo, careq.pem).
- -config: Indica a OpenSSL usar un archivo de configuración personalizado (openssl.cnf).

Al ejecutar el comando, se solicita una frase de paso para proteger la clave privada. También se piden algunos datos básicos que deben coincidir con la información previamente configurada en el archivo `openssl.cnf`.

Después de crear el CSR, se puede autofirmar el certificado para usarlo como Autoridad Certificadora (CA). Esto se realiza con el comando:

```bash
debian@https:~/CA$ sudo openssl ca -create_serial -out cacert.pem -days 365 -keyfile private/cakey.pem -selfsign -extensions v3_ca -config ./openssl.cnf -infiles careq.pem
Using configuration from ./openssl.cnf
Enter pass phrase for private/cakey.pem:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number:
            36:15:6a:51:89:82:f6:66:e0:d2:4a:5d:43:61:6f:7b:3b:87:c3:5b
        Validity
            Not Before: Jan 11 11:56:18 2025 GMT
            Not After : Jan 11 11:56:18 2026 GMT
        Subject:
            countryName               = ES
            stateOrProvinceName       = Sevilla
            organizationName          = Internet Widgits Pty Ltd
            commonName                = pablo.debian
            emailAddress              = pmartinhidalgo19@gmail.com
        X509v3 extensions:
            X509v3 Subject Key Identifier: 
                70:63:CD:8F:AD:5E:82:EF:B8:DB:43:10:03:24:CA:AE:EB:6D:2F:5F
            X509v3 Authority Key Identifier: 
                70:63:CD:8F:AD:5E:82:EF:B8:DB:43:10:03:24:CA:AE:EB:6D:2F:5F
            X509v3 Basic Constraints: critical
                CA:TRUE
Certificate is to be certified until Jan 11 11:56:18 2026 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Database updated
```

Parámetros clave:

- -create_serial: Genera un número de serie único de 128 bits para evitar conflictos si se reinicia el proceso.
- -out: Especifica el archivo de salida del certificado firmado (por ejemplo, cacert.pem).
- -days: Define la validez del certificado en días (en este caso, 365 días).
- -keyfile: Utiliza la clave privada creada anteriormente (private/cakey.pem) para la firma.
- -selfsign: Indica que el certificado será autofirmado.
- -extensions: Selecciona las extensiones configuradas en el archivo openssl.cnf (por ejemplo, v3_ca).
- -config: Indica el archivo de configuración de OpenSSL modificado.
- -infiles: Especifica el CSR a firmar (en este caso, careq.pem).

Durante la ejecución, OpenSSL solicita:

1. La frase de paso configurada para la clave privada.
2. Confirmación de la información del certificado antes de firmarlo.
3. Aprobación final para guardar el certificado.

Para verificar que el certificado de la autoridad certificadora se encuentra contenido en el directorio actual, listaremos el contenido del mismo haciendo uso del comando:

```bash
debian@https:~/CA$ ls -l
total 52
-rw-r--r-- 1 root root  4614 Jan 11 11:56 cacert.pem
-rw-r--r-- 1 root root  1045 Jan 11 11:51 careq.pem
drwxr-xr-x 2 root root  4096 Jan 11 11:30 certreqs
drwxr-xr-x 2 root root  4096 Jan 11 11:56 certsdb
drwxr-xr-x 2 root root  4096 Jan 11 11:30 crl
-rw-r--r-- 1 root root   166 Jan 11 11:56 index.txt
-rw-r--r-- 1 root root    21 Jan 11 11:56 index.txt.attr
-rw-r--r-- 1 root root     0 Jan 11 11:37 index.txt.old
-rw-r--r-- 1 root root 12279 Jan 11 11:46 openssl.cnf
drwx------ 2 root root  4096 Jan 11 11:50 private
-rw-r--r-- 1 root root    41 Jan 11 11:56 serial
```

Como vemos existe un fichero **cacert.pem** que es resultado de firmar el fichero de solicitud de firma de certificado **careq.pem**.

Todo está preparado para firmar el certificado del servidor de mi compañero. Por ello, he colocado su archivo de solicitud de firma dentro del directorio `certreqs/`, que es la ubicación designada para estos casos.

```bash
debian@https:~/CA$ ls -l certreqs/
total 4
-rw-r--r-- 1 root root 1074 Jan 11 12:10 joseantoniocgonzalez.csr
```

Ya podemos proceder a firmar usando el siguiente comando:

```bash
debian@https:~/CA$ sudo openssl ca -config openssl.cnf -out certsdb/joseantoniocgonzalez.crt -infiles certreqs/joseantoniocgonzalez.csr
Using configuration from openssl.cnf
Enter pass phrase for /home/debian/CA/private/cakey.pem:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number:
            36:15:6a:51:89:82:f6:66:e0:d2:4a:5d:43:61:6f:7b:3b:87:c3:5d
        Validity
            Not Before: Jan 11 12:37:59 2025 GMT
            Not After : Jan 11 12:37:59 2026 GMT
        Subject:
            countryName               = ES
            stateOrProvinceName       = SEVILLA
            localityName              = SEVILLA
            organizationName          = ASIR
            commonName                = joseantoniocgonzalez.iesgn.org
            emailAddress              = joseantoniocgonzalez83@gmail.com
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Subject Key Identifier: 
                0C:95:B9:A0:01:E3:46:16:7D:FE:4D:E1:6B:54:A4:E0:AA:DC:05:80
            X509v3 Authority Key Identifier: 
                70:63:CD:8F:AD:5E:82:EF:B8:DB:43:10:03:24:CA:AE:EB:6D:2F:5F
Certificate is to be certified until Jan 11 12:37:59 2026 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Database updated
```

Donde:

- `-config`: Indica a OpenSSL que utilice un archivo de configuración personalizado, en este caso llamado openssl.cnf, en lugar del predeterminado.
- `-out`: Especifica dónde se guardará el certificado firmado. Aquí, se almacenará en el directorio certsdb/ con el nombre joseantoniocgonzalez.crt.
- `-infiles`: Señala el archivo CSR que se desea firmar. En este caso, es el archivo joseantoniocgonzalez.csr, ubicado en el directorio certreqs/.

Al ejecutar el comando, OpenSSL solicita la frase de paso configurada previamente para proteger la clave privada de la autoridad certificadora. Esto garantiza que, incluso si la clave privada cae en manos equivocadas, no puedan realizar firmas indebidas. Antes de proceder, OpenSSL también muestra la información contenida en el certificado para confirmar que es correcta.

Una vez firmado, el certificado se almacena en el directorio certsdb/. Para confirmar su creación, listamos el contenido de dicho directorio con el comando:

```bash
debian@https:~/CA$ ls -l certsdb/
total 24
-rw-r--r-- 1 root root 4614 Jan 11 11:56 36156A518982F666E0D24A5D43616F7B3B87C35B.pem
-rw-r--r-- 1 root root 4643 Jan 11 12:38 36156A518982F666E0D24A5D43616F7B3B87C35D.pem
-rw-r--r-- 1 root root 4643 Jan 11 12:38 joseantoniocgonzalez.crt
```

El resultado muestra tres archivos:

1. El certificado de la autoridad certificadora.
2. Dos archivos relacionados con el certificado del compañero: uno identificado con un número de serie y otro con un nombre descriptivo, facilitando su identificación.

El archivo que debe entregarse al compañero es certsdb/joseantoniocgonzalez.crt, que contiene su certificado firmado. Además, debe recibir el archivo cacert.pem, que es el certificado de la autoridad certificadora, necesario para verificar la validez del certificado.

El archivo index.txt funciona como una base de datos en texto plano que registra información sobre los certificados emitidos por la CA. Se puede visualizar con:

```bash
debian@https:~/CA$ cat index.txt
V	260111115618Z		36156A518982F666E0D24A5D43616F7B3B87C35B	unknown	/C=ES/ST=Sevilla/O=Internet Widgits Pty Ltd/CN=pablo.debian/emailAddress=pmartinhidalgo19@gmail.com
V	260111123759Z		36156A518982F666E0D24A5D43616F7B3B87C35D	unknown	/C=ES/ST=SEVILLA/L=SEVILLA/O=ASIR/CN=joseantoniocgonzalez.iesgn.org/emailAddress=joseantoniocgonzalez83@gmail.com
```

En el contenido se puede observar:

- Estado de los certificados: En este caso, ambos están marcados como válidos (V).
- Fecha de expiración: Indica hasta cuándo es válido cada certificado.
- Número de serie: Identificador único de cada certificado.
- Información del sujeto: Detalla los campos incluidos en el CSR, como el país, la organización y el correo electrónico.

### Configurar HTTPS

Ahora me toca hacerlo al revés, lo primero será generar una solicitud de firma de certificado (CSR, por sus siglas en inglés). En este caso utilizaremos OpenSSL, aunque también se podrían emplear otras herramientas de software para lograrlo.

Para crear la solicitud, primero necesitamos contar con una clave privada que estará vinculada al certificado. Por lo tanto, procederemos a generar una clave privada RSA de 4096 bits, la cual será almacenada en el directorio `/etc/ssl/private/`. Esto se realiza mediante el siguiente comando:

```bash
debian@https:~$ sudo openssl genrsa 4096 > pablomh.key
debian@https:~$ sudo mv pablomh.key /etc/ssl/private/
```

Después de generar la clave privada, ajustaremos sus permisos a 400, lo que restringirá el acceso para que únicamente el propietario pueda leer su contenido. Dado que se trata de información sensible, este paso, aunque no obligatorio, es altamente recomendable por razones de seguridad.

```bash
debian@https:~$ sudo chmod 400 /etc/ssl/private/pablomh.key
```

A continuación, procederemos a generar un archivo `.csr`, que será la solicitud de firma de certificado destinada a ser validada por la autoridad certificadora (CA) configurada por nuestro compañero. Este archivo no incluye información sensible, por lo que su ubicación y los permisos asignados no son críticos. Por lo tanto:

```bash
debian@https:~$ sudo openssl req -new -key /etc/ssl/private/pablomh.key -out pablomh.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:ES
State or Province Name (full name) [Some-State]:Sevilla
Locality Name (eg, city) []:Dos Hermanas
Organization Name (eg, company) [Internet Widgits Pty Ltd]:ASIR
Organizational Unit Name (eg, section) []:Informatica
Common Name (e.g. server FQDN or YOUR name) []:pablo.debian   
Email Address []:pmartinhidalgo19@gmail.com

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```

Durante la ejecución, nos pedirá una serie de valores para identificar al certificado, que tendremos que rellenar en base a la información que nos proporcionará la autoridad certificadora; excepto los dos últimos valores, los cuales pedirán una serie de valores cuya introducción es opcional.

Para verificar que el fichero de solicitud de firma ha sido correctamente generado listaremos el contenido del directorio actual:

```bash
debian@https:~$ ls -l
total 16
drwxr-xr-x 6 root   root   4096 Jan 11 12:38 CA
-rw-r--r-- 1 root   root   1773 Jan 14 17:00 pablomh.csr
```

Como vemos existe un fichero de nombre `pablomh.csr` que debemos enviar a nuestro compañero, para que así sea firmado por la correspondiente autoridad certificadora que ha creado. Además de dicho certificado firmado, nos debe enviar la clave pública de la entidad certificadora, es decir, el certificado de la misma, para así poder verificar su firma sobre nuestro certificado.

Bien, pues Jose ya me ha enviado ambos ficheros, los cuales voy a almacenar en `/etc/ssl/certs/`.

![image](/assets/img/posts/certificado/discordjose.png)

```bash
debian@https:~$ ls -l /etc/ssl/certs/ | grep 'pablomh'
-rw-r--r-- 1 root root   2090 Jan 14 17:31 pablomh.crt
debian@https:~$ ls -l /etc/ssl/certs/ | grep 'cacert'
-rw-r--r-- 1 root root   2244 Jan 14 17:31 cacert.pem
```

Debe existir un fichero de nombre tunombre.crt que es el resultado de la firma de la solicitud de firma de certificado que previamente le hemos enviado, y otro de nombre cacert.pem, que es el certificado de la entidad certificadora, con el que posteriormente se comprobará la firma de la autoridad certificadora sobre dicho certificado del servidor.

Al igual que apache2 incluía un VirtualHost por defecto para las peticiones entrantes por el puerto 80 (HTTP), contiene otro por defecto para las peticiones entrantes por el puerto 443 (HTTPS), de nombre default-ssl, que por defecto viene deshabilitado, así que procederemos a modificarlo teniendo en cuenta las siguientes directivas:

- ServerName: Al igual que en el VirtualHost anterior, tendremos que indicar el nombre de dominio a través del cuál accederemos al servidor.

- SSLEngine: Activa el motor SSL, necesario para hacer uso de HTTPS, por lo que su valor debe ser on.

- SSLCertificateFile: Indicamos la ruta del certificado del servidor firmado por la CA. En este caso, /etc/ssl/certs/pablomh.crt.

- SSLCertificateKeyFile: Indicamos la ruta de la clave privada asociada al certificado del servidor. En este caso, /etc/ssl/private/pablomh.key.

- SSLCACertificateFile: Indicamos la ruta del certificado de la CA con el que comprobaremos la firma de nuestro certificado. En este caso, /etc/ssl/certs/cacert.pem.

Quedando el archivo final de la siguiente forma:

```bash
debian@https:~$ cat /etc/apache2/sites-available/default-ssl.conf
<VirtualHost *:80> 
  ServerName pablo.iesgn.org

  Redirect permanent / https://pablo.iesgn.org/
</VirtualHost>
<VirtualHost *:443>
	ServerAdmin webmaster@localhost
	ServerName pablo.iesgn.org
	DocumentRoot /var/www/html

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined

	SSLEngine on
	
	SSLCertificateFile      /etc/ssl/certs/pablomh.crt
	SSLCertificateKeyFile /etc/ssl/private/pablomh.key
	SSLCACertificateFile /etc/ssl/certs/cacert.pem
</VirtualHost>
```

Dado que éste VirtualHost no viene habilitado por defecto, tendremos que hacerlo manualmente:

```bash
debian@https:~# sudo a2ensite default-ssl
Enabling site default-ssl.
To activate the new configuration, you need to run:
  systemctl reload apache2
```

Además, lo que queremos hacer es forzar el uso de HTTPS (https://), de manera que estableceremos una redirección permanente en el VirtualHost accesible en el puerto 80 para que se así no se permita servir la página por HTTP (http://). De forma que tendremos que hacer lo siguiente en el fichero:

```bash
debian@https:~$ cat /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
        ServerName pablo.iesgn.org

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        Redirect 301 / https://pablo.iesgn.com/
</VirtualHost>
```

Reiniciamos:

```bash
debian@https:~$ sudo systemctl restart apache2
```

![image](/assets/img/posts/certificado/redirect.png)

Podemos observar que se ha generado una advertencia de seguridad, lo que confirma que la redirección de `http://` a `https://` se ha realizado con éxito.  

Esta advertencia se debe a que el navegador no ha podido verificar la firma del certificado recibido desde el servidor, ya que no dispone de la clave pública o del certificado de la Autoridad Certificadora (CA). Para solucionar esto, es necesario importar manualmente dicho certificado en el navegador.  

En el caso de Firefox, para llevar a cabo esta importación, primero debemos hacer clic en el icono de las tres barras ubicado en la parte superior del navegador. Luego, accedemos a **Preferencias** (o **Ajustes**) y buscamos la sección **Privacidad & Seguridad**. Desplazándonos hasta la parte inferior, encontraremos el apartado **Certificados**, donde haremos clic en **Ver certificados**. A continuación, en la pestaña **Autoridades**, seleccionamos la opción **Importar**, lo que nos permitirá añadir el certificado de la CA.  

Una vez elegido el certificado a importar, aparecerá un mensaje informándonos de que se nos solicita confiar en una nueva Autoridad Certificadora (CA). En este punto, simplemente confirmamos la acción haciendo clic en **Aceptar**.  

Después de completar estos pasos, podremos comprobar que el certificado ha sido importado correctamente.

![image](/assets/img/posts/certificado/autoridadjose.png)

Una vez importado el certificado recargamos la página para mostrar el contenido:

![image](/assets/img/posts/certificado/infoapache.png)

Como podemos notar, la advertencia de seguridad ha vuelto a aparecer. Si observamos junto a la barra de direcciones, veremos un icono de candado. Al hacer clic en él, se desplegará la información correspondiente.

Además, si le damos a **Ver Certificado** nos mostrará información del mismo:

![image](/assets/img/posts/certificado/infocertificado.png)

**¿Por qué el sitio no es seguro a pesar de usar HTTPS?**  

El navegador sigue indicando que el sitio no es seguro porque el certificado utilizado ha sido emitido por una Autoridad Certificadora (CA) que no es reconocida como confiable por los navegadores. Esto ocurre porque el certificado ha sido generado por la CA de mi compañero, y aunque la conexión esté cifrada mediante HTTPS, navegadores como Chrome o Firefox no confiarán en una entidad que no esté validada a nivel internacional.  

Hemos verificado que con Apache2 hemos logrado que HTTPS funcione, aunque sin una certificación oficial no será reconocido como seguro. Ahora realizaremos la misma prueba con la otra alternativa: Nginx.

El primer paso será desinstalar apache2 para evitar posibles conflictos, y tras ello, instalar nginx.

Después de esto, podemos proceder con la configuración del nuevo servidor web. Este servicio también incluye un VirtualHost por defecto, pero a diferencia de Apache2, permite unificar en un solo archivo la configuración tanto del VirtualHost que opera en el puerto 80 como el del puerto 443. Este archivo se encuentra en la ruta `/etc/nginx/sites-available/default`.

De forma que el fichero quedaría de la siguiente forma:

```bash
debian@https:~$ sudo cat /etc/nginx/sites-enabled/default 
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        server_name pablo.iesgn.org;

        return 301 https://$host$request_uri;
}

server {
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;

        ssl    on;
        ssl_certificate    /etc/ssl/certs/pablomh.crt;
        ssl_certificate_key    /etc/ssl/private/pablomh.key;

        root /var/www/html/pablo.iesgn.org;

        index index.html index.htm index.nginx-debian.html;

        server_name pablo.iesgn.org;

        location / {
                try_files $uri $uri/ =404;
        }
}
```

Reiniciamos para que se efectúen los cambios:

```bash
debian@https:~$ sudo systemctl reload nginx
```

Tras ello, ya estará todo listo para acceder a `pablo.iesgn.org` desde el navegador.

![image](/assets/img/posts/certificado/nginx.png)


Y como podemos observar, el certificado de mi compañero está funcionando correctamente.
