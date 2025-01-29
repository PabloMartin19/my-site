---
title: "VPN de acceso remoto con WireGuard"
date: 2025-01-27 20:00:00 +0000
categories: [Seguridad, VPN]
tags: [VPN]
author: pablo
description: "En este artículo exploraremos cómo configurar una VPN de acceso remoto utilizando WireGuard, una solución moderna y eficiente.  Los clientes que se conectarán a la VPN estarán en sistemas operativos Linux, Android y Windows, permitiendo así el acceso seguro a los recursos internos desde diversas plataformas y ubicaciones."
toc: true
comments: true
image:
  path: /assets/img/posts/vpn/portada2.png
---

El objetivo de esta práctica es configurar una red privada virtual (VPN) de acceso remoto mediante la implementación de WireGuard en un entorno simulado con GNS3. Esta práctica tiene como fin proporcionar una solución de conectividad segura y eficiente, permitiendo la comunicación remota y cifrada entre los clientes y el servidor VPN.

## Escenario

El escenario consta de lo siguiente:

1. Dispositivos Cliente:

- **Cliente-Windows** (172.22.0.2/24)
- **Cliente-Android** (172.22.0.3/24)
- **Cliente-Linux** (172.22.0.4/24)

2. Un **Servidor** que dispone de dos redes diferentes, la que conecta con los clientes (172.22.0.1/24) y la que conecta con el PC-Local (192.168.1.1/24).

3. Un **PC-Local** (192.168.1.2/24)

4. Cuatro **nubes NAT** (NAT1, NAT2, NAT3 y NAT4) que proporcionan traducción de direcciones de red

5. Un **Switch** central que interconecta todos los clientes con el servidor

La topología está organizada de la siguiente manera:

  - Los tres clientes (Windows, Android y Linux) se conectan al Switch1 a través de diferentes puertos (e0, e1, e2)
  - Cada cliente tiene su propia nube NAT conectada a través de interfaces nat0
  - El servidor está conectado al Switch1 a través del puerto e3
  - El servidor también tiene una conexión directa a la PC local a través de una red separada (192.168.1.0/24)
  - Hay una cuarta nube NAT (NAT4) conectada directamente al servidor

Podemos verlo en imagen:

![image](/assets/img/posts/vpn/escenario.png)

**IMPORTANTE** ⚠️

El cliente Android, como se ve en la imagen, está conectado a dos interfaces de red. Sin embargo, esto **no significa que pueda usarlas simultáneamente**, ya que Android no permite tener activas dos conexiones de red al mismo tiempo cuando una de ellas no es Wi-Fi.  

Inicialmente, utilizaremos la red proporcionada por la **nube NAT** para descargar e instalar las aplicaciones necesarias. Sin embargo, cuando llegue el momento de realizar las pruebas de conectividad con la VPN, será necesario cambiar manualmente a la interfaz que tiene la dirección **172.22.0.3/24**, ya que es la que permite la comunicación con el servidor y el resto de la red en el escenario de GNS3.


## Configuración del Servidor

Primero, actualizamos los paquetes de nuestro sistema e instalamos WireGuard con los siguientes comandos:

```bash
debian@Servidor:~$ sudo apt update && sudo apt upgrade -y && sudo apt install wireguard -y
```

Para que los dispositivos conectados a la VPN puedan comunicarse con otras redes, debemos habilitar el reenvío de paquetes en el kernel. Para que sea persistente, lo agregamos en el archivo `/etc/sysctl.conf`:

```bash
debian@Servidor:~$ sudo sysctl -p
net.ipv4.ip_forward = 1
```

WireGuard utiliza criptografía de clave pública-privada para la autenticación entre los pares. Cada nodo de la VPN necesita generar su propio par de claves.

Nos dirigimos al directorio de configuración de WireGuard:

```bash
debian@Servidor:~$ sudo su
root@Servidor:/home/debian# cd /etc/wireguard/
```

Generamos la clave privada y la almacenamos en un archivo llamado clave_priv_servidor. Simultáneamente, generamos la clave pública derivada de la privada y la almacenamos en clave_pub_servidor:

```bash
root@Servidor:/etc/wireguard# wg genkey | tee clave_priv_servidor | wg pubkey > clave_pub_servidor
```

Verificamos que los archivos se han generado correctamente:

```bash
root@Servidor:/etc/wireguard# ls -l
total 8
-rw-r--r-- 1 root root 45 Jan 28 22:13 clave_priv_servidor
-rw-r--r-- 1 root root 45 Jan 28 22:13 clave_pub_servidor
```

Mostramos el contenido de las claves para asegurarnos de que están bien creadas:

```bash
root@Servidor:/etc/wireguard# cat clave_priv_servidor 
oOWo8ekqChcY31za9QsNHu75NqioypbFqZgFcTc9WEQ=

root@Servidor:/etc/wireguard# cat clave_pub_servidor 
7+qFaDTqy/WIHiPrucnpTdCJRNbqFvlANVQdwsmITCo=
```

La clave privada nunca debe ser compartida, ya que es la que permite el acceso seguro al servidor.

WireGuard utiliza archivos de configuración en formato INI para definir la interfaz de red VPN y sus parámetros.

Creamos el archivo de configuración con:

```bash
nano /etc/wireguard/wg0.conf
```

Añadimos el siguiente contenido:

```bash
root@Servidor:/etc/wireguard# cat wg0.conf 
[Interface]
# Dirección IP que tendrá el servidor dentro de la VPN
Address = 10.99.99.1

# Clave privada generada anteriormente
PrivateKey = oOWo8ekqChcY31za9QsNHu75NqioypbFqZgFcTc9WEQ=

# Puerto de escucha del servidor (por defecto WireGuard usa el 51820)
ListenPort = 51820
```

Este archivo define la interfaz `wg0`, que será utilizada por WireGuard para la comunicación VPN.

Para levantar la VPN, utilizamos el comando `wg-quick`:

```bash
root@Servidor:/etc/wireguard# wg-quick up wg0
[#] ip link add wg0 type wireguard
[ 9304.006929] wireguard: WireGuard 1.0.0 loaded. See www.wireguard.com for information.
[ 9304.007862] wireguard: Copyright (C) 2015-2019 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.1 dev wg0
[#] ip link set mtu 1420 up dev wg0
```

Para verificar el estado de la interfaz WireGuard y confirmar que está activa, usamos:

```bash
root@Servidor:/etc/wireguard# wg
interface: wg0
  public key: 7+qFaDTqy/WIHiPrucnpTdCJRNbqFvlANVQdwsmITCo=
  private key: (hidden)
  listening port: 51820
```

![image](/assets/img/posts/vpn/image7.png)

Esto indica que la interfaz `wg0` está en funcionamiento, tiene la clave pública correcta y está escuchando en el puerto 51820.

Vamos a listar todas las interfaces de red disponibles, donde deberíamos ver algo similar a esto:

```bash
root@Servidor:/etc/wireguard# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:40:52:9a:00:00 brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    inet 192.168.1.1/24 brd 192.168.1.255 scope global ens4
       valid_lft forever preferred_lft forever
    inet6 fe80::e40:52ff:fe9a:0/64 scope link 
       valid_lft forever preferred_lft forever
3: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:40:52:9a:00:01 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 172.22.0.1/24 brd 172.22.0.255 scope global ens5
       valid_lft forever preferred_lft forever
    inet6 fe80::e40:52ff:fe9a:1/64 scope link 
       valid_lft forever preferred_lft forever
4: ens6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:40:52:9a:00:02 brd ff:ff:ff:ff:ff:ff
    altname enp0s6
    inet 192.168.122.51/24 brd 192.168.122.255 scope global dynamic ens6
       valid_lft 2744sec preferred_lft 2744sec
    inet6 fe80::e40:52ff:fe9a:2/64 scope link 
       valid_lft forever preferred_lft forever
5: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN group default qlen 1000
    link/none 
    inet 10.99.99.1/32 scope global wg0
       valid_lft forever preferred_lft forever
```

Aquí podemos confirmar que la interfaz wg0 está activa y que tiene asignada la dirección `10.99.99.1/32`, la cual servirá como puerta de enlace VPN.

## Configuración del Cliente-Linux

Para configurar el cliente Linux en nuestra VPN con WireGuard, primero aseguramos que el sistema esté actualizado e instalamos el paquete necesario. Ejecutamos:

```bash
debian@Cliente-Linux:~$ sudo apt update && sudo apt upgrade -y && sudo apt install wireguard -y
```

Luego, cambiamos al usuario root y nos desplazamos al directorio de configuración de WireGuard:

```bash
debian@Cliente-Linux:~$ sudo su
root@Cliente-Linux:/home/debian# cd /etc/wireguard/
```

Generamos la clave privada del cliente y a partir de ella obtenemos la clave pública:

```bash
root@Cliente-Linux:/etc/wireguard# wg genkey | tee clave_priv_cliente | wg pubkey > clave_pub_cliente
```

Verificamos que los archivos de claves se han generado correctamente:

```bash
root@Cliente-Linux:/etc/wireguard# ls -l
total 8
-rw-r--r-- 1 root root 45 Jan 28 22:33 clave_priv_cliente
-rw-r--r-- 1 root root 45 Jan 28 22:33 clave_pub_cliente
```

Consultamos el contenido de las claves para asegurarnos de que se han creado correctamente:

```bash
root@Cliente-Linux:/etc/wireguard# cat clave_priv_cliente  
kKnEefJbY6wvEwS0Gkj9nPKUDyol6VnguYik11U4AkQ=

root@Cliente-Linux:/etc/wireguard# cat clave_pub_cliente 
F/eZilIdeYh1iY2Fx6GHfVRlAM0AoVvBamiZ/Zbf+Aw=
```

A continuación, creamos el archivo de configuración `wg0.conf` con los siguientes parámetros:

```bash
root@Cliente-Linux:/etc/wireguard# cat wg0.conf
[Interface]

# IP que tomará el cliente en el túnel
Address = 10.99.99.2/24 

# Clave privada del cliente
PrivateKey = kKnEefJbY6wvEwS0Gkj9nPKUDyol6VnguYik11U4AkQ=

# Puerto escucha y por defecto de Wireguard
ListenPort = 51820

[Peer]

# Clave pública del servidor
PublicKey = 7+qFaDTqy/WIHiPrucnpTdCJRNbqFvlANVQdwsmITCo=

# Rango de direcciones permitidas en el túnel.
AllowedIPs = 0.0.0.0/0

#Punto de acceso del servidor
Endpoint = 172.22.0.1:51820

#Tiempo de espera de la conexión
PersistentKeepalive = 25
```

Levantamos la interfaz de WireGuard con:

```bash
root@Cliente-Linux:/etc/wireguard# wg-quick up wg0
[#] ip link add wg0 type wireguard
[ 2154.668085] wireguard: WireGuard 1.0.0 loaded. See www.wireguard.com for information.
[ 2154.670429] wireguard: Copyright (C) 2015-2019 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.2/24 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] wg set wg0 fwmark 51820
[#] ip -4 route add 0.0.0.0/0 dev wg0 table 51820
[#] ip -4 rule add not fwmark 51820 table 51820
[#] ip -4 rule add table main suppress_prefixlength 0
[#] sysctl -q net.ipv4.conf.all.src_valid_mark=1
[#] iptables-restore -n
```

Si todo funciona correctamente, deberíamos ver mensajes indicando que la interfaz se ha creado y configurado con éxito. Podemos verificar el estado de la conexión ejecutando:

```bash
root@Cliente-Linux:/etc/wireguard# wg
interface: wg0
  public key: F/eZilIdeYh1iY2Fx6GHfVRlAM0AoVvBamiZ/Zbf+Aw=
  private key: (hidden)
  listening port: 51820
  fwmark: 0xca6c

peer: 7+qFaDTqy/WIHiPrucnpTdCJRNbqFvlANVQdwsmITCo=
  endpoint: 172.22.0.1:51820
  allowed ips: 0.0.0.0/0
  transfer: 0 B received, 296 B sent
  persistent keepalive: every 25 seconds
```

Y confirmamos que la interfaz `wg0` ha sido añadida correctamente al sistema:

```bash
root@Cliente-Linux:/etc/wireguard# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:89:3b:46:00:00 brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    inet 172.22.0.4/24 brd 172.22.0.255 scope global ens4
       valid_lft forever preferred_lft forever
    inet6 fe80::e89:3bff:fe46:0/64 scope link 
       valid_lft forever preferred_lft forever
3: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:89:3b:46:00:01 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 192.168.122.208/24 brd 192.168.122.255 scope global dynamic ens5
       valid_lft 1416sec preferred_lft 1416sec
    inet6 fe80::e89:3bff:fe46:1/64 scope link 
       valid_lft forever preferred_lft forever
4: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN group default qlen 1000
    link/none 
    inet 10.99.99.2/24 scope global wg0
       valid_lft forever preferred_lft forever
```

Ahora volvemos al servidor para añadir la configuración del cliente. En el archivo `wg0.conf` del servidor agregamos la información correspondiente al cliente:

```bash
root@Servidor:/etc/wireguard# cat wg0.conf 
# SERVIDOR
[Interface]

# Aquí ponemos la IP virtual que tomará el túnel
Address = 10.99.99.1

# Clave privada del servidor creada hace momentos
PrivateKey = oOWo8ekqChcY31za9QsNHu75NqioypbFqZgFcTc9WEQ=

# Puerto escucha y por defecto de Wireguard
ListenPort = 51820


# CLIENTE
[Peer]

# Clave pública del cliente

Publickey = F/eZilIdeYh1iY2Fx6GHfVRlAM0AoVvBamiZ/Zbf+Aw=

# IP túnel del cliente

AllowedIPs = 10.99.99.2/32

#Tiempo de espera de respuesta

PersistentKeepAlive = 25
```

Para aplicar los cambios, reiniciamos la interfaz en el servidor:

```bash
root@Servidor:/etc/wireguard# wg-quick down wg0
[#] ip link delete dev wg0
root@Servidor:/etc/wireguard# wg-quick up wg0
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.1 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ip -4 route add 10.99.99.2/32 dev wg0
```

Verificamos el estado de la VPN en el servidor con:

```bash
root@Servidor:/etc/wireguard# wg
interface: wg0
  public key: 7+qFaDTqy/WIHiPrucnpTdCJRNbqFvlANVQdwsmITCo=
  private key: (hidden)
  listening port: 51820

peer: F/eZilIdeYh1iY2Fx6GHfVRlAM0AoVvBamiZ/Zbf+Aw=
  allowed ips: 10.99.99.2/32
  persistent keepalive: every 25 seconds
```

### Comprobación funcionamiento

Para comprobar la conexión desde el cliente, utilizamos traceroute para ver si el tráfico se está enviando correctamente a través del túnel VPN:

![image](/assets/img/posts/vpn/image8.png)

Si todo está configurado correctamente, veremos que los paquetes viajan por la interfaz `wg0`, confirmando que la VPN está funcionando de manera óptima.


## Configuración Cliente-Windows

Para configurar WireGuard en un cliente Windows, comenzamos descargando e instalando el cliente oficial desde su página de [descargas](https://download.wireguard.com/windows-client/wireguard-installer.exe).

Una vez completada la instalación, ejecutamos la aplicación y procedemos a agregar un nuevo túnel vacío. Esto nos permitirá definir manualmente la configuración de nuestra conexión VPN:

![image](/assets/img/posts/vpn/image17.png)

Al crear el túnel, editamos el archivo de configuración con los siguientes parámetros:

```bash
[Interface]
PrivateKey = wHLqf5MSCuBHQ+Gi0kBFCjqIYZVlQC540JtAywT4K04=
ListenPort = 51820
Address = 10.99.99.3/32

[Peer]
PublicKey = 7+qFaDTqy/WIHiPrucnpTdCJRNbqFvlANVQdwsmITCo=
AllowedIPs = 0.0.0.0/1
EndPoint = 172.22.0.1:51820
```

![image](/assets/img/posts/vpn/image9.png)

Analizando esta configuración, observamos que en la sección **[Interface]** se especifica la clave privada del cliente, el puerto en el que escuchará y la dirección IP asignada dentro de la VPN. En la sección **[Peer]**, se define el servidor al que nos conectaremos, incluyendo su clave pública, las IPs permitidas en la VPN y la dirección del endpoint, que corresponde al servidor WireGuard.

Después de guardar la configuración, activamos el túnel y verificamos que la conexión se haya establecido correctamente mediante el handshake:

![image](/assets/img/posts/vpn/image10.png)

También podemos observar que se ha creado una nueva interfaz de red asociada a WireGuard:

![image](/assets/img/posts/vpn/image18.png)

A continuación, nos dirigimos al servidor y añadimos la información del nuevo cliente Windows en su archivo de configuración (`/etc/wireguard/wg0.conf`):

```bash
root@Servidor:/etc/wireguard# cat wg0.conf 
# SERVIDOR
[Interface]

# Aquí ponemos la IP virtual que tomará el túnel
Address = 10.99.99.1

# Clave privada del servidor creada hace momentos
PrivateKey = oOWo8ekqChcY31za9QsNHu75NqioypbFqZgFcTc9WEQ=

# Puerto escucha y por defecto de Wireguard
ListenPort = 51820


# CLIENTE LINUX
[Peer]

# Clave pública del cliente

Publickey = F/eZilIdeYh1iY2Fx6GHfVRlAM0AoVvBamiZ/Zbf+Aw=

# IP túnel del cliente

AllowedIPs = 10.99.99.2/32

#Tiempo de espera de respuesta

PersistentKeepAlive = 25


# CLIENTE WINDOWS

[Peer]

Publickey = Gw9vvlbUvr/Q2t2poFA1R53Y9mYlP718EKPCaWvsTns=

AllowedIPs = 10.99.99.3/32

PersistentKeepAlive = 25
```

Para aplicar los cambios, reiniciamos la interfaz de WireGuard en el servidor:

```bash
root@Servidor:/etc/wireguard# wg-quick up wg0
[#] ip link add wg0 type wireguard
[ 1439.522887] wireguard: WireGuard 1.0.0 loaded. See www.wireguard.com for information.
[ 1439.524019] wireguard: Copyright (C) 2015-2019 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.1 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ip -4 route add 10.99.99.3/32 dev wg0
[#] ip -4 route add 10.99.99.2/32 dev wg0
```

Si ejecutamos `wg`, podemos comprobar que ambos clientes (Linux y Windows) están conectados correctamente, ya que se observa el handshake reciente y tráfico intercambiado con el servidor:

```bash
root@Servidor:/etc/wireguard# wg
interface: wg0
  public key: 7+qFaDTqy/WIHiPrucnpTdCJRNbqFvlANVQdwsmITCo=
  private key: (hidden)
  listening port: 51820

peer: F/eZilIdeYh1iY2Fx6GHfVRlAM0AoVvBamiZ/Zbf+Aw=
  endpoint: 172.22.0.4:51820
  allowed ips: 10.99.99.2/32
  latest handshake: 26 seconds ago
  transfer: 2.20 KiB received, 1.46 KiB sent
  persistent keepalive: every 25 seconds

peer: Gw9vvlbUvr/Q2t2poFA1R53Y9mYlP718EKPCaWvsTns=
  endpoint: 172.22.0.2:51820
  allowed ips: 10.99.99.3/32
  latest handshake: 1 minute, 11 seconds ago
  transfer: 61.41 KiB received, 632 B sent
  persistent keepalive: every 25 seconds
```

### Comprobación funcionamiento

Para finalizar, realizamos una prueba de conectividad ejecutando un traceroute desde el cliente Windows hacia el dispositivo que tenemos en la red local. Esto nos confirmará que el tráfico está siendo correctamente enrutado a través de la VPN.

![image](/assets/img/posts/vpn/image11.png)

Y como podemos ver funciona correctamente. Este proceso garantiza que el cliente Windows pueda comunicarse con el servidor y con otros clientes conectados a la VPN de WireGuard, proporcionando una conexión segura y estable.

## Configuración Android

Para comenzar nuestra configuración en Android, necesitaremos instalar dos aplicaciones fundamentales desde la Play Store. La primera es WireGuard, que nos permitirá crear y gestionar nuestro túnel VPN. La segunda es Termius, un versátil cliente SSH que además nos proporciona una terminal integrada, esta será esencial para realizar nuestras pruebas de conectividad y verificar la correcta creación del túnel.

Una vez que hayamos completado la instalación de ambas aplicaciones, debemos proceder a configurar nuestra conexión Wi-Fi. En este caso, necesitaremos modificar la configuración de red para utilizar la dirección IP `172.22.0.3/24`. Para realizar este cambio, nos dirigiremos a los Ajustes de nuestro dispositivo, donde tendremos que añadir manualmente la configuración:

![image](/assets/img/posts/vpn/image16.png)

Con la red correctamente configurada, procedemos a crear nuestro túnel VPN mediante la aplicación WireGuard. La configuración que utilizaremos sigue el mismo patrón que hemos venido utilizando en nuestras configuraciones anteriores:

![image](/assets/img/posts/vpn/image12.png)

Podemos observar que el handshake está funcionando correctamente, lo cual nos indica que el intercambio inicial de claves se ha realizado con éxito.

Para verificar la creación del túnel, abrimos nuestra terminal en **Termius** y ejecutamos el comando `ip a`. Este nos mostrará todas las interfaces de red, donde podremos confirmar la presencia de nuestro túnel WireGuard:

![image](/assets/img/posts/vpn/image13.png)

El siguiente paso nos lleva de vuelta a nuestro **Servidor**, donde necesitamos actualizar el archivo `wg0.conf` con los parámetros correspondientes a nuestro cliente Android:

```bash
# CLIENTE ANDROID

[Peer]

Publickey = YlKnopzZ1myt29MnP6rZ1WwMgLm1QVSOY+t0vyngtD8=

AllowedIPs = 10.99.99.4/32

PersistentKeepAlive = 25
```

Tras añadir esta configuración, debemos reiniciar la interfaz del túnel para que los cambios surtan efecto. Podemos verificar el estado actual de nuestras conexiones mediante el comando `wg`:

```bash
root@Servidor:/etc/wireguard# wg
interface: wg0
  public key: 7+qFaDTqy/WIHiPrucnpTdCJRNbqFvlANVQdwsmITCo=
  private key: (hidden)
  listening port: 51820

peer: F/eZilIdeYh1iY2Fx6GHfVRlAM0AoVvBamiZ/Zbf+Aw=
  endpoint: 172.22.0.4:51820
  allowed ips: 10.99.99.2/32
  latest handshake: 26 seconds ago
  transfer: 2.20 KiB received, 1.46 KiB sent
  persistent keepalive: every 25 seconds

peer: Gw9vvlbUvr/Q2t2poFA1R53Y9mYlP718EKPCaWvsTns=
  endpoint: 172.22.0.2:51820
  allowed ips: 10.99.99.3/32
  latest handshake: 1 minute, 11 seconds ago
  transfer: 61.41 KiB received, 632 B sent
  persistent keepalive: every 25 seconds

peer: YlKnopzZ1myt29MnP6rZ1WwMgLm1QVSOY+t0vyngtD8=
  allowed ips: 10.99.99.4/32
  persistent keepalive: every 25 seconds
```

### Comprobación funcionamiento

Para asegurarnos de que todo está funcionando correctamente, realizaremos una prueba de conectividad utilizando la terminal de **Termius**. Ejecutamos un `traceroute` para visualizar la ruta que siguen nuestros paquetes:

![image](/assets/img/posts/vpn/image14.png)

Como podemos ver, el túnel está funcionando a la perfección.

Para tener una visión completa del funcionamiento de nuestra red, podemos ver el estado del tráfico entre todos los clientes conectados:

```bash
root@Servidor:/etc/wireguard# wg
interface: wg0
  public key: 7+qFaDTqy/WIHiPrucnpTdCJRNbqFvlANVQdwsmITCo=
  private key: (hidden)
  listening port: 51820

peer: YlKnopzZ1myt29MnP6rZ1WwMgLm1QVSOY+t0vyngtD8=
  endpoint: 172.22.0.3:51820
  allowed ips: 10.99.99.4/32
  latest handshake: 45 seconds ago
  transfer: 3.62 KiB received, 8.24 KiB sent
  persistent keepalive: every 25 seconds

peer: Gw9vvlbUvr/Q2t2poFA1R53Y9mYlP718EKPCaWvsTns=
  endpoint: 172.22.0.2:51820
  allowed ips: 10.99.99.3/32
  latest handshake: 1 minute, 15 seconds ago
  transfer: 205.21 KiB received, 11.40 KiB sent
  persistent keepalive: every 25 seconds

peer: F/eZilIdeYh1iY2Fx6GHfVRlAM0AoVvBamiZ/Zbf+Aw=
  endpoint: 172.22.0.4:51820
  allowed ips: 10.99.99.2/32
  latest handshake: 2 minutes, 8 seconds ago
  transfer: 14.00 KiB received, 6.36 KiB sent
  persistent keepalive: every 25 seconds
```

![image](/assets/img/posts/vpn/image15.png)

## Conclusión

Sin ningún tipo de duda me ha parecido mucho mejor y más práctico esta forma de hacerlo con WireGuard que con OpenVPN. De la otra forma pienso que es más lioso ya que tienes que estar creando y moviendo ficheros de certificado con lo que ello conlleva. Esta forma es mucho más intuitiva y fácil de entender en mi opinión.