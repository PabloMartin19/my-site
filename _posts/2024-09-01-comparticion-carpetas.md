---
title: "Compartición de carpetas"
date: 2024-09-01 13:30:00 +0000
categories: [Redes, Compartición de archivos]
tags: [Compartición de archivos]
author: pablo
description: "Práctica sobre la configuración y gestión de carpetas compartidas en una red local en Windows, Linux y Android."
toc: true
comments: true
image:
  path: /assets/img/posts/comparticion/comparticion.png
---

## 1. Introducción
En esta práctica se abordará la configuración y gestión de la compartición de carpetas entre diferentes sistemas operativos en una red local. La compartición de archivos es una tarea esencial en redes empresariales y domésticas, ya que permite a los usuarios acceder y gestionar recursos compartidos de manera eficiente, independientemente del sistema operativo que utilicen.

El objetivo de esta práctica es demostrar cómo configurar la compartición de carpetas en diversas combinaciones de sistemas: de Windows a Windows, de Windows a Debian, de Debian a Windows, etc. Se utilizarán herramientas nativas y protocolos como Samba para garantizar la interoperabilidad entre estos sistemas.

Al finalizar, se habrá aprendido a configurar adecuadamente permisos de acceso, seguridad y las mejores prácticas para la compartición de recursos en un entorno de red mixto.

## 2. Windows a Windows
Para compartir carpetas entre dos máquinas físicas con Windows
10, podemos utilizar la funcionalidad de red compartida de Windows.
A continuación, te proporciono los pasos generales para hacerlo:

### 2.1. Conexión de red
Asegúrate de que ambas máquinas estén conectadas a la
misma red, ya sea mediante Wi-Fi o Ethernet. Esto es esencial
para que las computadoras se vean entre sí. En mi caso,
realizaré la compartición de carpetas entre dos máquinas
físicas conectadas a una misma red Wi-Fi. Para saber nuestra
IP nos dirigimos al “Cmd” y utilizamos el comando “ipconfig”.
Aquí veremos diferentes IPv4, pero a mi me interesa el
adaptador de LAN inalámbrica Wi-Fi:

![captura1](/assets/img/posts/comparticion/comparticion1.png)

### 2.2. Habilitar el descubrimiento de red
En ambas máquinas, debes asegurarte de que la función de
"Descubrimiento de red" esté habilitada. Para hacerlo: Ve al "Panel de control" > "Redes y recursos compartidos".
En la parte izquierda, haz clic en "Cambiar la configuración de
uso compartido avanzado".
Asegúrate de que la opción "Activar el uso compartido de
archivos e impresoras" esté habilitada y que la opción "Activar
el descubrimiento de red" también esté habilitada.

![captura2](/assets/img/posts/comparticion/comparticion2.png)

### 2.3. Compartir carpetas

En la máquina desde la cual deseas compartir carpetas, sigue
estos pasos:

- Navega a la carpeta que deseas compartir
- Haz clic derecho en la carpeta y selecciona "Propiedades".
- Ve a la pestaña "Uso compartido" y haz clic en "Compartir".
- Elige a quién deseas compartir la carpeta. Puedes seleccionar "Todos" para que sea accesible para todos en la red o agregar usuarios específicos.
- Define los permisos de acceso (lectura, escritura, etc.) según tus necesidades.
- Haz clic en "Compartir" y luego en "Listo".

![captura3](/assets/img/posts/comparticion/comparticion3.png)

### 2.4. Acceso a la carpeta compartida

En la otra máquina, para acceder a la carpeta compartida:
- Abre el Explorador de Windows.
- En la barra de direcciones, escribe \\”IP” (reemplaza "IP" por la ruta de la máquina desde la cual estás compartiendo la carpeta).
- Deberías ver la carpeta compartida. Haz doble clic en ella y podrás acceder a su contenido.

![captura4](/assets/img/posts/comparticion/comparticion4.png)

Es importante que ambas máquinas tengan configurado un grupo de
trabajo común. Puedes verificar esto y cambiarlo en la configuración de red
de cada máquina si es necesario. Además, asegúrate de que las cuentas de
usuario en ambas máquinas tengan permisos para acceder a las carpetas
compartidas si estás utilizando autenticación basada en cuentas de usuario.

Ten en cuenta que estos son pasos generales y pueden variar según la
configuración específica de tu red y tu sistema. Además, para acceder a las
carpetas compartidas en una red local, ambas máquinas deben estar
encendidas y conectadas a la red al mismo tiempo.

## 3. Windows a Debian

Para compartir carpetas entre una máquina física con Windows 10 y una
máquina virtual Debian 11 se pueden utilizar diferentes métodos, pero en mi caso utilizaré Samba, en los que seguiré estos pasos:

### 3.1. Configuración de la Máquina Virtual Debian 11

Asegúrese de que la máquina virtual Debian 11 esté funcionando
correctamente y tenga acceso a la red. Para ello tendremos que
cambiar el adaptador de red en la configuración de la máquina
virtual, en este caso un adaptador puente.

![captura5](/assets/img/posts/comparticion/comparticion5.png)

Después de esto, tendremos que comprobar que nuestras máquinas
hacen ping entre sí:

Ping de Windows a Debian
![captura6](/assets/img/posts/comparticion/comparticion6.png)

Ping de Debian a Windows
![captura7](/assets/img/posts/comparticion/comparticion7.png)

Instale el paquete de Samba en Debian 11 si aún no está instalado.
Puedes hacerlo ejecutando el siguiente comando en la terminal:

![captura8](/assets/img/posts/comparticion/comparticion8.png)

Creamos la carpeta donde vamos a compartir los archivos.
```
mkdir /home/pavlo/compartida
chmod 777 /home/pavlo/compartida
```

Editamos el archivo de configuración de samba:
```
nano /etc/samba/smb.conf
```

Al final del archivo insertamos el siguiente texto correspondiente a la
configuración de nuestra carpeta compartida:

```
[compartida]
path = /home/pavlo/compartida
comment = Compartida
guest ok = yes
public = yes
writable = yes
```

Guardamos los cambios y después reiniciamos el servicio con el
comando:
```
service smbd restart
```

Después de esto creamos un documento de prueba y ya tendremos
creada una carpeta lista para compartir:
![captura9](/assets/img/posts/comparticion/comparticion9.png)

En nuestro equipo con Windows nos dirigimos al apartado de red y
en el navegador de archivos escribimos la IP que tengamos asignada
en Debian:
![captura10](/assets/img/posts/comparticion/comparticion10.png)

Si se le solicita un nombre de usuario y una contraseña, ingrese las
credenciales de inicio de sesión de su máquina virtual Debian 11.
Con esto realizado, ya podremos empezar a compartir archivos entre los
dos sistemas operativos.

Mencionar, que en este ejemplo hemos utilizado unos permisos para la
carpeta muy permisivos en el que cualquiera puede leer y escribir en el
directorio.

## 4. Debian a Windows

Para compartir carpetas de Debian a Windows tenemos que seguir
exactamente los mismos pasos ya explicados en el apartado anterior.
![captura11](/assets/img/posts/comparticion/comparticion11.png)

![captura12](/assets/img/posts/comparticion/comparticion12.png)

## 5. Debian a Debian

Para compartir carpetas entre Debian y Debian hay que seguir
prácticamente los mismos pasos ya explicados anteriormente. En mi caso
lo haré con dos máquinas virtuales entre sí. Para ello tendremos que seguir una serie de pasos:

1. En primer lugar y muy importante, comprobar que haya conectividad
(ping) entre nuestras máquinas, en donde tendremos que configurar
las IPs para que ambas tengan coherencia. Después de ello
realizaremos la prueba y comprobamos si funciona:
![captura13](/assets/img/posts/comparticion/comparticion13.png)

2. Seguidamente tendremos que instalar Samba en ambas máquinas y
creamos la carpeta donde vamos a compartir los archivos.

```
mkdir /home/pavlo/compartidadebian
chmod 777 /home/pavlo/compartidadebian
```

3. Editamos el archivo de configuración de samba:
```
nano /etc/samba/smb.conf
```

Al final del archivo insertamos el siguiente texto correspondiente a la
configuración de nuestra carpeta compartida:
```
[compartidadebian]
path = /home/pavlo/compartidadebian
comment = Comparticion entre Debian y Debian
guest ok = yes
public = yes
writable = yes
```

Guardamos los cambios y después reiniciamos el servicio con el
comando:
```
service smbd restart
```

4. Después de esto creamos un documento de prueba y ya tendremos
creada una carpeta lista para compartir:
![captura14](/assets/img/posts/comparticion/comparticion14.png)

5. Una vez configurado todo se seguirán los mismos sencillos pasos que
en Windows estando en la misma red y utilizando el comando
smb://111.111.1.11
![captura15](/assets/img/posts/comparticion/comparticion15.png)

![captura16](/assets/img/posts/comparticion/comparticion16.png)

Y con esto ya habríamos hecho la compartición de carpetas entre Debian y Debian a través de Samba.

## 6. Windows a Android
Utilizando una aplicación llamada “fx file explorer” nos resultará muy
sencillo compartir carpetas entre Windows y Android.

![captura17](/assets/img/posts/comparticion/comparticion17.png){: w="250" h="200" }{: .normal }

Como en todos los apartados anteriores tendremos que estar conectados a
la misma red para que ambos dispositivos puedan realizar conectividad
entre sí. En mi caso estarán conectados tanto mi portátil como mi teléfono a la red Wi-Fi de mi casa.

Una vez instalada la aplicación y comprobado que ambos dispositivos están en la misma red, creamos una carpeta compartida en Windows dando los permisos que queramos como ya he explicado anteriormente. Después
accedemos al apartado de “Network” y agregamos un nuevo dispositivo en
el que tendremos que poner la IP de nuestro dispositivo Windows.

![captura18](/assets/img/posts/comparticion/comparticion19-1.png){: w="250" h="200" }{: .normal }
![captura19](/assets/img/posts/comparticion/comparticion18.png){: w="250" h="200" }{: .normal }

Una vez realizado todo esto lo único que queda es abrir la carpeta
compartida con permisos y crear un archivo desde Android comprobando
que todo vaya bien.

![captura20](/assets/img/posts/comparticion/comparticion19.png){: w="250" h="200" }{: .normal }
![captura21](/assets/img/posts/comparticion/comparticion20-1.png){: w="250" h="200" }{: .normal }

## 7. Debian y Android
Quizás la forma más fácil de compartir archivos entre Android y Linux de forma inalámbrica sea descargando una aplicación FTP en un dispositivo Android. Ya que nos permite alojar rápidamente un servidor FTP improvisado en nuestro dispositivo Android, que luego puede aceptar
conexiones remotas de forma inalámbrica.

Antes de que podamos hablar sobre la configuración del servidor, deberá
instalar la aplicación WiFi FTP Server en su dispositivo Android. Para
hacer esto, abra la aplicación Google Play Store en Android, busque
“Servidor FTP WiFi” e instálalo.

![captura22](/assets/img/posts/comparticion/comparticionX.png){: w="250" h="200" }{: .normal }

Después de estado tendremos que instalar Filezilla en Debian con el
siguiente comando:
```
apt install Filezilla
```

![captura23](/assets/img/posts/comparticion/comparticion21.png)

Dentro de la aplicación de Android crearemos un servidor con la ubicación de donde queremos crear los archivos.

![captura24](/assets/img/posts/comparticion/comparticion22.png){: w="250" h="200" }{: .normal }

Una vez creamos el servidor dentro de Filezilla ponemos los datos que nos da la aplicación para crear una conexión directa entre ambos dispositivos.

Seguidamente le damos a “Subir” en el archivo o carpeta que queramos
compartir y así respectivamente con cualquier cosa que queramos
compartir entre ambos dispositivos.

![captura25](/assets/img/posts/comparticion/comparticion23.png)