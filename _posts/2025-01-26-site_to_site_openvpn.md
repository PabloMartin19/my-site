---
title: "VPN sitio a sitio con OpenVPN y certificados x509"
date: 2025-01-26 17:00:00 +0000
categories: [Seguridad, VPN]
tags: [VPN]
author: pablo
description: "En esta práctica configuraremos una VPN con OpenVPN en GNS3, implementando tanto una VPN de acceso remoto como una VPN sitio a sitio. Usaremos autenticación con certificados x509 generados con OpenSSL y configuraremos el enrutamiento para permitir la comunicación entre redes a través del túnel VPN. Este ejercicio es útil para comprender el funcionamiento de las VPNs y mejorar la seguridad en redes."
toc: true
comments: true
image:
  path: /assets/img/posts/vpn/portada1.jpg
---

Configura una conexión VPN sitio a sitio entre dos equipos del cloud:

- Cada equipo estará conectado a dos redes, una de ellas en común 
    - Para la autenticación de los extremos se usarán obligatoriamente certificados digitales, que se generarán utilizando openssl y se almacenarán en el directorio /etc/openvpn, junto con con los parámetros Diffie-Helman y el certificado de la propia Autoridad de Certificación. 
    - Se utilizarán direcciones de la red 10.99.99.0/24 para las direcciones virtuales de la VPN. 
    - Tras el establecimiento de la VPN, una máquina de cada red detrás de cada servidor VPN debe ser capaz de acceder a una máquina del otro extremo. 


## Escenario

Comentar que antes de montar el escenario, conectamos una nube a las máquinas para que tengan acceso a Internet y así poder instalar openvpn.

Ya instalado, el escenario tendrá la siguiente forma:

- **ClienteCasa**: interfaz `ens4` con la dirección 192.168.1.2/24 conectada con la interfaz `ens4` de **ServidorCasa**.

- **ServidorCasa**: interfaz `ens4` con la dirección 192.168.1.1/24 conectada con la interfaz `ens4` de **ClienteCasa**. Por otro lado, la interfaz `ens5` con la dirección 10.10.10.33/24 que conecta con la interfaz `ens4` de **ServidorInsti**.

- **ServidorInsti**: interfaz `ens4` con la dirección 10.10.10.44/24 conectada con la interfaz `ens5` de **ServidorCasa**. Por otro lado, la interfaz `ens5` con la dirección 172.22.0.1/24 conectada con la interfaz `ens4` de **ClienteInsti**.

- **ClienteInsti**: interfaz `ens4` con la dirección 172.22.0.2/24 conectada con la interfaz `ens5` de **ServidorInsti**.

![image](/assets/img/posts/vpn/image2.png)

🔗 Red de interconexión VPN: `10.99.99.0/24`

🖧 Objetivo: Tras establecer la VPN, **ClienteCasa** podrá comunicarse con **ClienteInsti** y viceversa.

Antes de comenzar, cada máquina debe tener acceso a Internet para instalar OpenVPN:

```bash
sudo apt update && sudo apt install openvpn easy-rsa -y
```

Una vez instalado estos dos paquetes en las máquinas que nos permitirán realizar la conexión VPN, tendremos que activar el bit de forwarding que nos permitirá dejar pasar los paquete a través de las máquinas (tanto la máquina ServidorCasa como la máquina ServidorInsti) para así permitir la conexión entre los dos clientes.

```bash
debian@ServidorCasa:~$ sudo sysctl -p
net.ipv4.ip_forward = 1
```

```bash
debian@ServidorInsti:~$ sudo sysctl -p
net.ipv4.ip_forward = 1
```

## Configuración del ServidorCasa

Para establecer la VPN con autenticación basada en certificados, necesitamos generar:

- **Una Autoridad de Certificación (CA)**, que firmará los certificados utilizados por los servidores y clientes de OpenVPN.
- **Un certificado y una clave privada para cada servidor** (ServidorCasa y ServidorInsti).
- **Un conjunto de parámetros Diffie-Hellman**, necesarios para establecer un canal de comunicación seguro.

Para esto, utilizaremos Easy-RSA, una herramienta que facilita la generación y administración de certificados.

En primer lugar, copiamos el archivo de configuración base de Easy-RSA:

```bash
debian@ServidorCasa:~$ sudo cp /usr/share/easy-rsa/vars.example /usr/share/easy-rsa/vars
```

Luego, editamos el archivo vars para definir los valores predeterminados de los certificados, donde configuramos los siguientes parámetros:

```bash
debian@ServidorCasa:~$ sudo cat /usr/share/easy-rsa/vars
set_var EASYRSA_REQ_COUNTRY     "ES"
set_var EASYRSA_REQ_PROVINCE    "Sevilla"
set_var EASYRSA_REQ_CITY        "Dos Hermanas"
set_var EASYRSA_REQ_ORG         "PabloMartin SL"
set_var EASYRSA_REQ_EMAIL       "pmartinhidalgo19@gmail.com"
set_var EASYRSA_REQ_OU          "Site to site OpenVPN"
```

Una vez guardados los cambios, inicializamos la infraestructura de claves pública (PKI):

```bash
debian@ServidorCasa:/usr/share/easy-rsa$ sudo ./easyrsa init-pki
* Notice:

  init-pki complete; you may now create a CA or requests.

  Your newly created PKI dir is:
  * /usr/share/easy-rsa/pki
```

A continuación, generamos los parámetros Diffie-Hellman, que se utilizarán para establecer un canal seguro entre los servidores OpenVPN:

```bash
debian@ServidorCasa:/usr/share/easy-rsa$ sudo ./easyrsa gen-dh
```

Para generar nuestra CA, ejecutamos:

```bash
debian@ServidorCasa:/usr/share/easy-rsa$ sudo ./easyrsa build-ca
* Notice:
Using Easy-RSA configuration from: /usr/share/easy-rsa/vars

* WARNING:

  Move your vars file to your PKI folder, where it is safe!

* Notice:
Using SSL: openssl OpenSSL 3.0.13 30 Jan 2024 (Library: OpenSSL 3.0.13 30 Jan 2024)


Enter New CA Key Passphrase: 
Re-Enter New CA Key Passphrase: 
Using configuration from /usr/share/easy-rsa/pki/be063ba2/temp.83878b4b
.+......+......+..+.+.....+.+......+.....+...............+...+...............+........................+..........+.....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*..+...+...+.........+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*..+..+..........+..................+...+...+.....................+...............+.....+.+..+...+....+......+..............+.+...+.........+...........+.+......+..+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
...+.....+...+....+........+.+.....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*............+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.+.+...+.....+.+..+.......+..+....+.....+......+...+...+...+............+.......+.....................+..+.......+.....+.+............+............+.....+.+......+.........+.....+...............+......+.+...+..............+.......+...+......+..+....+...........+.......+.....+.+...........+....+..+...+.........+...+.........+.+.....+...+....+...+.........+...+..+......+...+..........+.....+..........+.....+.......+..............+.+....................+..........+..+.......+...+......+..+....+........+.+.....+.+...+...+........+.......+..+.+...........+...+......+....+..+.+...............+............+...............+...+..+.+..+.............+......+.....+.+.................+......+....+...........+....+..+.+.....+....+...+........+...+.+...+.....+.+..+....+.....+.+...............+..+.+...........+.+.........+...........+...+......+.+.........+........+...+...+.........+.+......+...+..+.....................+.......+...+.....+.........+.+...+.....+....+......+..............+..........+...+........+....+...+..+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:pavlo

* Notice:

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/usr/share/easy-rsa/pki/ca.crt
```

Durante este proceso, se nos pedirá que introduzcamos un nombre común (Common Name) para la CA. También se nos solicitará una contraseña para proteger la clave de la CA.

Ahora generamos la clave privada y la solicitud de certificado para el servidor OpenVPN en **ServidorCasa**:

```bash
debian@ServidorCasa:/usr/share/easy-rsa$ sudo ./easyrsa gen-req server
* Notice:
Using Easy-RSA configuration from: /usr/share/easy-rsa/vars

* WARNING:

  Move your vars file to your PKI folder, where it is safe!

* Notice:
Using SSL: openssl OpenSSL 3.0.13 30 Jan 2024 (Library: OpenSSL 3.0.13 30 Jan 2024)

....+.......+............+....................+...+...+.+......+..+.+..+.......+..+....+.....+.+.....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...........+.......+..+.+...+..+.........+...+..........+.....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...+..+.............+...........+......+...+.+............+............+..+...+................+..+...+...................+.....+...+...+.+......+..+.+.....+.+..............+.+......+..+......+....+...+..+................+...........+.+...+......+...+...........+...............+.+...+..+.........+............+.......+...+..+...+....+...+..+.........+............+............+.+..+.......+...+..+......+.+.....+....+..............+.+......+...........+....+...........+.........+.+............+..+.........+.+........+......+......+.+..+.+...........+......+.......+...........+......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
........+...+....+...+..+.+.......................+....+..+.+..+.......+...+..+.............+..+....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*..+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.+........+...+..........+...+.....+.+.....+...+..........+..+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
Common Name (eg: your user, host, or server name) [server]:
* Notice:

Keypair and certificate request completed. Your files are:
req: /usr/share/easy-rsa/pki/reqs/server.req
key: /usr/share/easy-rsa/pki/private/server.key
```

Luego, firmamos la solicitud con nuestra CA:

```bash
debian@ServidorCasa:/usr/share/easy-rsa$ sudo ./easyrsa sign-req server server
* Notice:
Using Easy-RSA configuration from: /usr/share/easy-rsa/vars

* WARNING:

  Move your vars file to your PKI folder, where it is safe!

* Notice:
Using SSL: openssl OpenSSL 3.0.13 30 Jan 2024 (Library: OpenSSL 3.0.13 30 Jan 2024)


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a server certificate for 825 days:

subject=
    commonName                = server


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: yes

Using configuration from /usr/share/easy-rsa/pki/b5cd863e/temp.ff729ff0
Enter pass phrase for /usr/share/easy-rsa/pki/private/ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'server'
Certificate is to be certified until May  1 17:12:31 2027 GMT (825 days)

Write out database with 1 new entries
Database updated

* Notice:
Certificate created at: /usr/share/easy-rsa/pki/issued/server.crt
```

Se nos pedirá que confirmemos la firma y que ingresemos la contraseña de la CA.

Repetimos el proceso para generar la clave privada y la solicitud de certificado en **ServidorInsti**:

```bash
debian@ServidorCasa:/usr/share/easy-rsa$ sudo ./easyrsa gen-req server2
```

Luego, firmamos la solicitud:

```bash
debian@ServidorCasa:/usr/share/easy-rsa$ sudo ./easyrsa sign-req client server2
```

Una vez generados los certificados y claves, los copiamos a los directorios correspondientes en **ServidorCasa**:

```bash
root@ServidorCasa:/usr/share/easy-rsa/pki# cp ca.crt dh.pem issued/server.crt private/server.key /etc/openvpn/server/
```

Verificamos que los archivos se copiaron correctamente:

```bash
debian@ServidorCasa:~$ ls -l /etc/openvpn/server/
total 20
-rw------- 1 root root 1180 Jan 26 17:16 ca.crt
-rw------- 1 root root  424 Jan 26 17:16 dh.pem
-rw------- 1 root root 4580 Jan 26 17:16 server.crt
-rw------- 1 root root 1854 Jan 26 17:16 server.key
```

Luego, copiamos los certificados de **ServidorInsti**:

```bash
root@ServidorCasa:/usr/share/easy-rsa/pki# cp ca.crt issued/server2.crt private/server2.key /home/debian/ServidorInsti/
```

Y verificamos la copia:

```bash
debian@ServidorCasa:~$ ls -l ServidorInsti/
total 16
-rw------- 1 root root 1180 Jan 26 17:18 ca.crt
-rw------- 1 root root 4466 Jan 26 17:18 server2.crt
-rw------- 1 root root 1854 Jan 26 17:18 server2.key
```

Para garantizar una conexión cifrada y autenticada entre los servidores, primero generamos los certificados y claves necesarias en **ServidorCasa** y luego los transferimos a **ServidorInsti**:

```bash
debian@ServidorCasa:~$ scp -r ServidorInsti/ debian@10.10.10.44:/home/debian
The authenticity of host '10.10.10.44 (10.10.10.44)' can't be established.
ED25519 key fingerprint is SHA256:Gojcktfl97qAXF9KaBhKTK93gIYeN/574t8Ph9Zl2D0.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.10.10.44' (ED25519) to the list of known hosts.
debian@10.10.10.44's password: 
server2.crt                                   100% 4466     2.9MB/s   00:00    
ca.crt                                        100% 1180     1.0MB/s   00:00    
server2.key                                   100% 1854     1.7MB/s   00:00
```

Al realizar la conexión por primera vez, se nos solicita verificar la autenticidad del host remoto mediante su huella ED25519. Aceptamos la conexión y procedemos a ingresar la contraseña del usuario remoto. La transferencia de archivos se completa con éxito.


Verificamos que los archivos han sido transferidos correctamente en **ServidorInsti**:

```bash
debian@ServidorInsti:~$ cd ServidorInsti/
debian@ServidorInsti:~/ServidorInsti$ ls -l
total 16
-rw------- 1 debian debian 1180 Jan 26 17:34 ca.crt
-rw------- 1 debian debian 4466 Jan 26 17:34 server2.crt
-rw------- 1 debian debian 1854 Jan 26 17:34 server2.key
```

En ServidorCasa, configuramos el servicio OpenVPN con el siguiente archivo `/etc/openvpn/server/servidor.conf`:

```bash
debian@ServidorCasa:~$ sudo cat /etc/openvpn/server/servidor.conf
dev tun
ifconfig 10.99.99.1 10.99.99.2
route 172.22.0.0 255.255.255.0
tls-server
ca ca.crt
cert server.crt
key server.key
dh dh.pem
comp-lzo
keepalive 10 120
log /var/log/openvpn/server.log
verb 3
askpass clavepaso.txt
```

Donde:

- **Modo TUN** (`dev tun`), creando un túnel IP punto a punto.
- **Asignación de IPs** (`ifconfig 10.99.99.1 10.99.99.2`).
- **Ruta estática** (`route 172.22.0.0 255.255.255.0`) para permitir acceso a la red interna.
- **Seguridad TLS** (`tls-server`), autenticación con certificados (`ca.crt`, `server.crt`, `server.key`) y clave Diffie-Hellman (`dh.pem`).
- **Compresión LZO** (`comp-lzo`), keepalive (`keepalive 10 120`), y nivel de logs (`verb 3`).
- **Registro de eventos** en `/var/log/openvpn/server.log`.
- **Askpass**: aquí debemos declarar el fichero .txt donde guardaremos la clave de paso para que no nos la pida más. 

Verificamos que los archivos de configuración y certificados están correctamente ubicados en `/etc/openvpn/server/`:

```bash
debian@ServidorCasa:~$ ls -l /etc/openvpn/server/
total 28
-rw------- 1 root root 1180 Jan 26 17:16 ca.crt
-rw-r--r-- 1 root root    6 Jan 26 17:42 clavepaso.txt
-rw------- 1 root root  424 Jan 26 17:16 dh.pem
-rw------- 1 root root 4580 Jan 26 17:16 server.crt
-rw------- 1 root root 1854 Jan 26 17:16 server.key
-rw-r--r-- 1 root root  219 Jan 26 17:41 servidor.conf
```

Habilitamos y arrancamos el servicio OpenVPN en **ServidorCasa**:

```bash
debian@ServidorCasa:~$ sudo systemctl enable --now openvpn-server@servidor
Created symlink /etc/systemd/system/multi-user.target.wants/openvpn-server@servidor.service → /lib/systemd/system/openvpn-server@.service.
debian@ServidorCasa:~$ [ 5609.481659] tun: Universal TUN/TAP device driver, 1.6
```

Verificamos el estado del servicio para asegurarnos de que está corriendo correctamente:

```bash
debian@ServidorCasa:~$ sudo systemctl status openvpn-server@servidor
```

![image](/assets/img/posts/vpn/image3.png)

También comprobamos que la interfaz de túnel `tun0` ha sido creada correctamente:

```bash
debian@ServidorCasa:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:d5:bf:e7:00:00 brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    inet 192.168.1.1/24 brd 192.168.1.255 scope global ens4
       valid_lft forever preferred_lft forever
    inet6 fe80::ed5:bfff:fee7:0/64 scope link 
       valid_lft forever preferred_lft forever
3: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:d5:bf:e7:00:01 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 10.10.10.33/24 brd 10.10.10.255 scope global ens5
       valid_lft forever preferred_lft forever
    inet6 fe80::ed5:bfff:fee7:1/64 scope link 
       valid_lft forever preferred_lft forever
4: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none 
    inet 10.99.99.1 peer 10.99.99.2/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::c25e:9b6e:e6a7:3651/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```


## Configuración del ServidorInsti

En ServidorInsti, aseguramos que los certificados y claves tengan los permisos correctos y sean propiedad de `root`:

```bash
debian@ServidorInsti:~$ sudo chown -R root:root ServidorInsti/
debian@ServidorInsti:~$ ls -l ServidorInsti/
total 16
-rw------- 1 root root 1180 Jan 26 17:34 ca.crt
-rw------- 1 root root 4466 Jan 26 17:34 server2.crt
-rw------- 1 root root 1854 Jan 26 17:34 server2.key
debian@ServidorInsti:~$ sudo mv ServidorInsti/* /etc/openvpn/client/
```

Verificamos los archivos en `/etc/openvpn/client/`:

```bash
debian@ServidorInsti:~$ ls -l /etc/openvpn/client/
total 20
-rw------- 1 root root 1180 Jan 26 17:34 ca.crt
-rw-r--r-- 1 root root    6 Jan 26 18:07 clavepaso.txt
-rw------- 1 root root 4466 Jan 26 17:34 server2.crt
-rw------- 1 root root 1854 Jan 26 17:34 server2.key
```

Configuramos el cliente OpenVPN con `/etc/openvpn/client/client.conf`:

```bash
debian@ServidorInsti:~$ sudo cat /etc/openvpn/client/client.conf
dev tun
remote 10.10.10.33
ifconfig 10.99.99.2 10.99.99.1
route 192.168.1.0 255.255.255.0
tls-client
ca ca.crt
cert server2.crt
key server2.key
comp-lzo
keepalive 10 60
verb 3
askpass clavepaso.txt
```

Habilitamos y arrancamos el cliente OpenVPN:

```bash
debian@ServidorInsti:~$ sudo systemctl enable --now openvpn-client@client
Created symlink /etc/systemd/system/multi-user.target.wants/openvpn-client@client.service → /lib/systemd/system/openvpn-client@.service.
debian@ServidorInsti:~$ [ 7208.575935] tun: Universal TUN/TAP device driver, 1.6
```

Comprobamos que la interfaz tun0 en el cliente se haya creado correctamente:

```bash
debian@ServidorInsti:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:83:0e:cf:00:00 brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    inet 10.10.10.44/24 brd 10.10.10.255 scope global ens4
       valid_lft forever preferred_lft forever
    inet6 fe80::e83:eff:fecf:0/64 scope link 
       valid_lft forever preferred_lft forever
3: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:83:0e:cf:00:01 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 172.22.0.1/24 brd 172.22.0.255 scope global ens5
       valid_lft forever preferred_lft forever
    inet6 fe80::e83:eff:fecf:1/64 scope link 
       valid_lft forever preferred_lft forever
4: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none 
    inet 10.99.99.2 peer 10.99.99.1/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::d8c0:e10c:3d:44f3/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```

Verificamos que la conexión se ha establecido correctamente:

```bash
debian@ServidorInsti:~$ sudo systemctl status openvpn-client@client.service 
```

![image](/assets/img/posts/vpn/image4.png)

## Pruebas de conectividad

Para verificar que la VPN está funcionando correctamente y que los paquetes están siendo enrutados entre ambas redes, realizamos pruebas de traceroute desde **ClienteCasa** hacia **ClienteInsti** y al revés.

Desde **ClienteCasa** a **ClienteInsti**:

![image](/assets/img/posts/vpn/image5.png)

Desde **ClienteInsti** a **ClienteCasa**:

![image](/assets/img/posts/vpn/image6.png)
