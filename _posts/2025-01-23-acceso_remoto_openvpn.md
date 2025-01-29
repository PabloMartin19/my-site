---
title: "VPN de acceso remoto con OpenVPN y certificados x509"
date: 2025-01-29 12:00:00 +0000
categories: [Seguridad, VPN]
tags: [VPN]
author: pablo
description: "En este artículo exploraremos cómo configurar una VPN de acceso remoto utilizando WireGuard, una solución moderna y eficiente. Los clientes que se conectarán a la VPN estarán en sistemas operativos Linux, Android y Windows, permitiendo así el acceso seguro a los recursos internos desde diversas plataformas y ubicaciones."
toc: true
comments: true
image:
  path: /assets/img/posts/vpn/portada1.jpg
---

Configura una conexión VPN de acceso remoto entre dos equipos del cloud:

- Uno de los dos equipos (el que actuará como servidor) estará conectado a dos redes 
    - Para la autenticación de los extremos se usarán obligatoriamente certificados digitales, que se generarán utilizando openssl y se almacenarán en el directorio /etc/openvpn, junto con  los parámetros Diffie-Helman y el certificado de la propia Autoridad de Certificación. 
    - Se utilizarán direcciones de la red 10.99.99.0/24 para las direcciones virtuales de la VPN. La dirección 10.99.99.1 se asignará al servidor VPN. 
    - Los ficheros de configuración del servidor y del cliente se crearán en el directorio /etc/openvpn de cada máquina, y se llamarán servidor.conf y cliente.conf respectivamente. 
    - Tras el establecimiento de la VPN, la máquina cliente debe ser capaz de acceder a una máquina que esté en la otra red a la que está conectado el servidor. 


## Escenario

Montaremos el pequeño escenario en GNS3 con tres máquinas Debian 12 y una nube NAT que nos proporcionará Internet para instalaciones necesarias:

- **Servidor**: contará con tres interfaces, `ens4` que conectará con **Cliente1** en la red 192.168.1.0/24, la interfaz `ens5` que conectará con **Cliente2** en la red 192.168.2.0/24 y la interfaz `ens6` que estará conectada a la nube NAT.

- **Cliente1**: conectado a la red 192.168.1.0/24 a través de la interfaz `ens4`.

- **Cliente2**: conectado a la red 192.168.2.0/24 a través de la interfaz `ens4`.

- **NAT**: conectada al **Servidor**.

Quedando de la siguiente forma:

![image](/assets/img/posts/vpn/image1.png)

## Configuración del servidor

Para configurar el servidor OpenVPN, lo primero que debemos hacer es asegurarnos de que las interfaces de red están activas para tener conexión a Internet. Esto es fundamental, ya que necesitaremos instalar el paquete **openvpn** en nuestro sistema. Para ello, ejecutamos los siguientes comandos en la terminal:

```bash
debian@servidor:~$ sudo apt update
debian@servidor:~$ sudo apt install openvpn -y
```

Una vez instalado OpenVPN, es necesario habilitar el reenvío de paquetes en el sistema para permitir que el tráfico fluya correctamente a través de la VPN. Esto se hace modificando el archivo de configuración del kernel `/etc/sysctl.conf`. Para aplicar el cambio inmediatamente, ejecutamos:

```bash
debian@servidor:~$ sudo sysctl -p
```

Este comando verificará y aplicará la configuración, asegurando que el tráfico IP pueda ser reenviado entre las interfaces de red. La salida del comando debería incluir la siguiente línea:

```bash
net.ipv4.ip_forward = 1
```

Ahora procederemos a copiar los archivos de configuración de easy-rsa desde su ubicación predeterminada en `/usr/share/easy-rsa` al directorio de configuración de OpenVPN en `/etc/openvpn`. Este paso es importante porque nos aseguramos de que futuras actualizaciones del paquete no sobrescriban nuestros archivos personalizados:

```bash
debian@servidor:~$ sudo cp -r /usr/share/easy-rsa /etc/openvpn
```

Podemos verificar que la copia se ha realizado correctamente listando el contenido del directorio `/etc/openvpn`:

```bash
debian@servidor:~$ ls -l /etc/openvpn/
```

Lo que nos devolverá algo similar a:

```yaml
total 16
drwxr-xr-x 2 root root 4096 Nov 11  2023 client
drwxr-xr-x 3 root root 4096 Jan 23 18:28 easy-rsa
drwxr-xr-x 2 root root 4096 Nov 11  2023 server
-rwxr-xr-x 1 root root 1468 Nov 11  2023 update-resolv-conf
```

A partir de este momento, trabajaremos dentro del directorio `/etc/openvpn/easy-rsa`, ya que este será el entorno donde generaremos los certificados y claves necesarios para nuestra infraestructura de clave pública (PKI).

EasyRSA es una herramienta de línea de comandos diseñada para simplificar la creación y gestión de una PKI (Infraestructura de Clave Pública) utilizada en OpenVPN. También nos permite generar parámetros de **Diffie-Hellman**, que son esenciales para establecer un canal seguro de comunicación en OpenVPN.

El siguiente paso en la configuración será inicializar la infraestructura PKI dentro del directorio de trabajo. Para ello, ejecutamos:

```bash
debian@servidor:~$ cd /etc/openvpn/easy-rsa/
debian@servidor:/etc/openvpn/easy-rsa$ sudo ./easyrsa init-pki
* Notice:

  init-pki complete; you may now create a CA or requests.

  Your newly created PKI dir is:
  * /etc/openvpn/easy-rsa/pki

* Notice:
  IMPORTANT: Easy-RSA 'vars' file has now been moved to your PKI above.
```

Este comando creará la estructura de archivos y directorios necesaria para la gestión de certificados en OpenVPN.

El siguiente paso en la configuración de OpenVPN es la creación de una Autoridad Certificadora (CA, por sus siglas en inglés). La CA es responsable de firmar los certificados de los clientes y del servidor, asegurando la autenticidad de las conexiones dentro de la VPN.

Para iniciar este proceso, ejecutamos el siguiente comando dentro del directorio `/etc/openvpn/easy-rsa`:

```bash
debian@servidor:/etc/openvpn/easy-rsa$ sudo ./easyrsa build-ca
* Notice:
Using Easy-RSA configuration from: /etc/openvpn/easy-rsa/pki/vars

* Notice:
Using SSL: openssl OpenSSL 3.0.15 3 Sep 2024 (Library: OpenSSL 3.0.15 3 Sep 2024)


Enter New CA Key Passphrase: 
Re-Enter New CA Key Passphrase: 
Using configuration from /etc/openvpn/easy-rsa/pki/563317df/temp.f856c430
...+..+......+.+.........+.....+..........+..+....+...............+..............+......+....+.................+..........+...+.........+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.....+.............+..+....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*....+.....+...+...+....+..................+.....+.......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
...+.+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.+.........+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...+..........+.....+.+.....+.........+.+.....+.+......+.....+.......+.....+...+..........+..............+....+...........+..........+...+........+...+......+...+......+......+.+...+..+.......+..+.........+...............+......+....+..+....+...+...........+.......+...+..+.........+...+...............+.+..+.........+.+.....+.............+..............+.+......+...+..+....+..+...+.+.....................+.........+.....+.+..+.+.....+.......+..............+......+...+................+.....+......+...+..........+..+.......+...+...+..............+...+...+............+....+...+..+.............+.....+...+..................+............+.......+...........+.......+..+...............+...+....+......+...+..............+.+......+........+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
/etc/openvpn/easy-rsa/pki/ca.crt
```

Durante el proceso de generación de la Autoridad Certificadora (CA), se nos pedirá establecer una frase de paso para proteger la clave privada. Esta contraseña será requerida cada vez que firmemos certificados nuevos. Como resultado del comando, se han generado dos archivos importantes:

- **El certificado de la CA**, ubicado en `/etc/openvpn/easy-rsa/pki/ca.crt`, el cual será compartido con los clientes y el servidor OpenVPN para validar la autenticidad de los certificados.

- **La clave privada de la CA**, almacenada en `/etc/openvpn/easy-rsa/pki/private/ca.key`, que debe mantenerse segura y no compartirse, ya que con ella se firman los certificados dentro de la infraestructura VPN.

El siguiente paso en la configuración será la generación de los **parámetros Diffie-Hellman (DH)**, que OpenVPN utilizará en el proceso de establecimiento de sesión segura entre los nodos de la VPN.

El intercambio de claves Diffie-Hellman es un protocolo criptográfico que permite a dos partes comunicarse de manera segura sobre un canal no confiable, acordando una clave de cifrado común sin necesidad de enviarla explícitamente. Esto proporciona una capa adicional de seguridad en el cifrado de la conexión VPN.

Para generar el certificado y la clave del servidor OpenVPN, utilizamos el siguiente comando dentro del directorio de trabajo de EasyRSA:

```bash
debian@servidor:/etc/openvpn/easy-rsa$ sudo ./easyrsa build-server-full server nopass
* Notice:
Using Easy-RSA configuration from: /etc/openvpn/easy-rsa/pki/vars

* Notice:
Using SSL: openssl OpenSSL 3.0.15 3 Sep 2024 (Library: OpenSSL 3.0.15 3 Sep 2024)

...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*..........+.+.....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*..+..........+.....+.......+......+..............+......+....+...+...+...........+....+.........+........+...+....+..+......+.........+....+..+....+.....+...+...+....+...+.....+...+...+......+...+.......+.........+.....+.+...+.....+...+.......+...........+............+.............+......+...............+.....+...+.............+..+...+...+.+.....+.+.........+...+.................+....+..+.......+...........+.......+..+.+..+...+....+..................+..+...+....+......+..+..........+......+.....+......+...+.......+...+.....+.+.........+...+..+..........+.................+.+.......................+............+.......+...+...+...........+....+.....+.......+..+............+.........+.+...........+...+....+............+.....+.+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
........+...+.+......+............+.....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.+...+...+.........+....+.....+.+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.......+.....+.......+.....+...+.......+........+....+..+...............+..........+...+..+....+......+......+..............+....+.....+.+........+...+....+.....+...+...+...+....+...........................+...+..+...+......+.+...+......+.....+.......+..+...............+.+.....+.+...+..+.+..+...+.............+.................+....+...............+...+.....+.+..+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-----
* Notice:

Keypair and certificate request completed. Your files are:
req: /etc/openvpn/easy-rsa/pki/reqs/server.req
key: /etc/openvpn/easy-rsa/pki/private/server.key


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a server certificate for 825 days:

subject=
    commonName                = server


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: yes

Using configuration from /etc/openvpn/easy-rsa/pki/086ccb9e/temp.95232f12
Enter pass phrase for /etc/openvpn/easy-rsa/pki/private/ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'server'
Certificate is to be certified until Apr 28 18:52:24 2027 GMT (825 days)

Write out database with 1 new entries
Database updated

* Notice:
Certificate created at: /etc/openvpn/easy-rsa/pki/issued/server.crt
```

Este comando realiza dos acciones principales:

1. Genera la clave privada del servidor, que se almacena en:

    ```shell
    /etc/openvpn/easy-rsa/pki/private/server.key
    ```

    Esta clave debe mantenerse segura, ya que se utilizará para cifrar las comunicaciones del servidor VPN.

2. Crea y firma el certificado del servidor, que se guarda en:

    ```shell
    /etc/openvpn/easy-rsa/pki/issued/server.crt
    ```

    Este certificado será utilizado por el servidor OpenVPN para autenticarse ante los clientes VPN.

Como hemos ejecutado el comando con la opción nopass, el certificado no requiere una frase de paso para su uso, lo que facilita la automatización del arranque del servidor VPN sin intervención manual.

Una vez generado el certificado del servidor, el siguiente paso es la creación de los parámetros Diffie-Hellman (DH), esenciales para el cifrado seguro durante el proceso de establecimiento de sesión. Esto se hace con el siguiente comando:


```bash
debian@servidor:/etc/openvpn/easy-rsa$ sudo ./easyrsa gen-dh
* Notice:
Using Easy-RSA configuration from: /etc/openvpn/easy-rsa/pki/vars

* Notice:
Using SSL: openssl OpenSSL 3.0.15 3 Sep 2024 (Library: OpenSSL 3.0.15 3 Sep 2024)

Generating DH parameters, 2048 bit long safe prime
.......+...................................................................................................................................+.............................................................+...............................................................................................................................................................................................................................................................+.............+...................................+.......................................................+...............................................................................................................................................................................................................................................................................................................................................................................................................................+....................................................................................+.......................................................................................................+..........................................................................................................................................................+.............................................................................+...........................................................+...............................................................................+.............................................................................................................................................................................................................+...................................................................................................................................+...................................................................................+...........................+................................................................................................................+...........................................................................++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*++*

* Notice:

DH parameters of size 2048 created at /etc/openvpn/easy-rsa/pki/dh.pem
```

Este proceso puede tardar varios minutos, ya que se generan números primos grandes que serán utilizados en el protocolo de intercambio de claves. Una vez completado, los parámetros DH se guardan en:

```shell
/etc/openvpn/easy-rsa/pki/dh.pem
```

Para que un cliente pueda autenticarse en la VPN, necesita un certificado y una clave privada, que deben ser generados en el 
servidor OpenVPN utilizando Easy-RSA. Esto se realiza con el siguiente comando:

```bash
debian@servidor:/etc/openvpn/easy-rsa$ sudo ./easyrsa build-client-full cliente1 nopass
```

Aquí, `cliente1` es el nombre del cliente y la opción `nopass` indica que la clave privada del cliente no tendrá contraseña.

Una vez generados, los archivos necesarios para la autenticación del cliente son:

- `ca.crt`: Certificado de la Autoridad Certificadora (CA), que permite verificar la autenticidad de los certificados emitidos.
- `cliente1.crt`: Certificado específico del cliente.
- `cliente1.key`: Clave privada del cliente.


Ahora, copiamos los ficheros necesarios a una carpeta temporal que nos servirá para transferir a la máquina **Cliente1**:

```bash
root@servidor:~# cp /etc/openvpn/easy-rsa/pki/ca.crt /home/debian/cliente1/
root@servidor:~# cp /etc/openvpn/easy-rsa/pki/issued/cliente1.crt /home/debian/cliente1/
root@servidor:~# cp /etc/openvpn/easy-rsa/pki/private/cliente1.key /home/debian/cliente1/
```

Cambiamos los permisos para que el usuario debian pueda acceder a ellos:

```bash
debian@servidor:~$ sudo chown -R debian:debian cliente1/
```

Y verificamos que los archivos han sido copiados correctamente:

```bash
debian@servidor:~$ ls -l cliente1/
total 16
-rw------- 1 debian debian 1180 Jan 23 19:22 ca.crt
-rw------- 1 debian debian 4471 Jan 23 19:23 cliente1.crt
-rw------- 1 debian debian 1704 Jan 23 19:23 cliente1.key
```

Para transferir estos archivos al cliente, usaremos scp (Secure Copy Protocol), copiándolos a la IP 192.168.1.2:

```bash
debian@servidor:~$ cd cliente1/
debian@servidor:~/cliente1$ scp * debian@192.168.1.2:/home/debian
The authenticity of host '192.168.1.2 (192.168.1.2)' can't be established.
ED25519 key fingerprint is SHA256:Gojcktfl97qAXF9KaBhKTK93gIYeN/574t8Ph9Zl2D0.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.1.2' (ED25519) to the list of known hosts.
debian@192.168.1.2's password: 
ca.crt                                        100% 1180   486.0KB/s   00:00    
cliente1.crt                                  100% 4471     2.7MB/s   00:00    
cliente1.key                                  100% 1704   763.9KB/s   00:00 
```

El servidor OpenVPN está configurado en `/etc/openvpn/server/servidor.conf` con los siguientes parámetros clave:

```bash
debian@servidor:~$ sudo cat /etc/openvpn/server/servidor.conf
port 1194
proto udp
dev tun

ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem

topology subnet


server 10.99.99.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt

push "route 192.168.2.0 255.255.255.0"

keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
verb 3
explicit-exit-notify 1
```

Donde:

- **Puertos y protocolo**: OpenVPN escucha en el puerto `1194` utilizando `UDP`.
- **Configuración de certificados**: Se especifican el certificado de la CA, el certificado del servidor y su clave privada.
- **Topología de red**: Se usa `topology subnet`, lo que permite asignar direcciones IP individuales dentro de la subred VPN.
- **Direcciones IP de la VPN**: Se define la subred `10.99.99.0/24` con `ifconfig-pool-persist` para asignar direcciones IP fijas a clientes recurrentes.
- **Enrutamiento**: Se usa `push "route 192.168.2.0 255.255.255.0"` para permitir a los clientes acceder a la red `192.168.2.0/24`.
- **Seguridad**: Se especifica el cifrado `AES-256-CBC` y parámetros como `persist-key` y `persist-tun` para mantener la sesión en caso de reinicios.
- **Registro y verbosidad**: Se habilita el registro de estado en `/var/log/openvpn/openvpn-status.log` y `verb 3` para obtener información de depuración.


Ahora, habilitamos el servicio OpenVPN para poner en marcha el túnel:

```bash
debian@servidor:~$ sudo systemctl enable --now openvpn-server@servidor
Created symlink /etc/systemd/system/multi-user.target.wants/openvpn-server@servidor.service → /lib/systemd/system/openvpn-server@.service.
debian@servidor:~$ [ 8384.381168] tun: Universal TUN/TAP device driver, 1.6
```

Verificamos su estado y vemos que está funcionando correctamente:

```bash
debian@servidor:~$ sudo systemctl status openvpn-server@servidor
● openvpn-server@servidor.service - OpenVPN service for servidor
     Loaded: loaded (/lib/systemd/system/openvpn-server@.service; enabled; pres>
     Active: active (running) since Thu 2025-01-23 20:44:51 UTC; 1min 53s ago
       Docs: man:openvpn(8)
             https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage
             https://community.openvpn.net/openvpn/wiki/HOWTO
   Main PID: 1024 (openvpn)
     Status: "Initialization Sequence Completed"
      Tasks: 1 (limit: 2348)
     Memory: 1.7M
        CPU: 35ms
     CGroup: /system.slice/system-openvpn\x2dserver.slice/openvpn-server@servid>
             └─1024 /usr/sbin/openvpn --status /run/openvpn-server/status-servi>
```

Si mostramos las interfaces con sus respectivos direccionamientos nos damos cuenta que la interfaz de túnel `tun0` se crea correctamente con la dirección 10.99.99.1, confirmando que OpenVPN está activo.

```bash
debian@servidor:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:fe:ae:66:00:00 brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    inet 192.168.1.1/24 brd 192.168.1.255 scope global ens4
       valid_lft forever preferred_lft forever
    inet6 fe80::efe:aeff:fe66:0/64 scope link 
       valid_lft forever preferred_lft forever
3: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:fe:ae:66:00:01 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 192.168.2.1/24 brd 192.168.2.255 scope global ens5
       valid_lft forever preferred_lft forever
    inet6 fe80::efe:aeff:fe66:1/64 scope link 
       valid_lft forever preferred_lft forever
4: ens6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:fe:ae:66:00:02 brd ff:ff:ff:ff:ff:ff
    altname enp0s6
    inet 192.168.122.222/24 brd 192.168.122.255 scope global dynamic ens6
       valid_lft 2320sec preferred_lft 2320sec
    inet6 fe80::efe:aeff:fe66:2/64 scope link 
       valid_lft forever preferred_lft forever
5: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none 
    inet 10.99.99.1/24 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::774f:979b:9e65:1c85/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```

## Configuración del Cliente1

En la máquina cliente Cliente1, instalamos OpenVPN:

```bash
sudo apt update
sudo apt install openvpn -y
```

Los archivos de certificado y clave los movemos a `/etc/openvpn/client/` y le cambiamos los permisos a root:

```bash
debian@cliente1:~$ sudo mv cliente/* /etc/openvpn/client/
debian@cliente1:~$ sudo chown -R root:root /etc/openvpn/client/
```

Verificamos que tengan los permisos correctos:

```bash
debian@cliente1:~$ ls -l /etc/openvpn/client/
total 16
-rw------- 1 root root 1180 Jan 23 20:37 ca.crt
-rw------- 1 root root 4471 Jan 23 20:37 cliente1.crt
-rw------- 1 root root 1704 Jan 23 20:37 cliente1.key
```

Y pasamos a la configuración del cliente, el cual se encuentra en `/etc/openvpn/client/client.conf`:

```bash
debian@cliente1:~$ sudo cat /etc/openvpn/client/client.conf
client
dev tun
proto udp

remote 192.168.1.1 1194
resolv-retry infinite
nobind

persist-key
persist-tun

ca /etc/openvpn/client/ca.crt
cert /etc/openvpn/client/cliente1.crt
key /etc/openvpn/client/cliente1.key

remote-cert-tls server
cipher AES-256-CBC
verb 3
```

Donde:

- **Modo cliente**: client
- **Interfaz virtual**: dev tun
- **Protocolo y puerto**: proto udp en el puerto 1194
- **Dirección del servidor**: remote 192.168.1.1 1194
- **Persistencia**: persist-key y persist-tun para mantener la sesión
- **Seguridad**: Se especifican los archivos ca.crt, cliente1.crt y cliente1.key, además del cifrado AES-256-CBC.
- **Verbosidad**: verb 3 para registros detallados.

Conectamos el cliente a la VPN y verificamos su estado:

```bash
debian@cliente1:~$ sudo systemctl enable --now openvpn-client@client
debian@cliente1:~$ sudo systemctl status openvpn-client@client
● openvpn-client@client.service - OpenVPN tunnel for client
     Loaded: loaded (/lib/systemd/system/openvpn-client@.service; enabled; pres
     Active: active (running) since Thu 2025-01-23 21:41:41 UTC; 1min 25s ago
       Docs: man:openvpn(8)
             https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage
             https://community.openvpn.net/openvpn/wiki/HOWTO
   Main PID: 713 (openvpn)
     Status: "Initialization Sequence Completed"
      Tasks: 1 (limit: 2349)
     Memory: 1.9M
        CPU: 39ms
     CGroup: /system.slice/system-openvpn\x2dclient.slice/openvpn-client@client
             └─713 /usr/sbin/openvpn --suppress-timestamps --nobind --config cl
```

Y si la conexión es exitosa, la interfaz `tun0` aparecerá con la IP 10.99.99.2, lo que indica que el cliente está dentro de la red VPN:

```bash
debian@cliente1:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:3a:24:e0:00:00 brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    inet 192.168.1.2/24 brd 192.168.1.255 scope global ens4
       valid_lft forever preferred_lft forever
    inet6 fe80::e3a:24ff:fee0:0/64 scope link 
       valid_lft forever preferred_lft forever
3: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none 
    inet 10.99.99.2/24 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::d9f3:6eaa:7b14:2952/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```

## Comprobación

Para comprobar que el cliente puede alcanzar la red remota 192.168.2.0/24 a través del servidor VPN, se usa traceroute:

```bash
debian@cliente1:~$ traceroute 192.168.2.2
traceroute to 192.168.2.2 (192.168.2.2), 30 hops max, 60 byte packets
 1  10.99.99.1 (10.99.99.1)  1.910 ms  1.824 ms  1.814 ms
 2  192.168.2.2 (192.168.2.2)  2.734 ms  2.755 ms  2.755 ms
```

Si el tráfico sigue el camino esperado a través de la VPN, significa que la configuración ha sido exitosa.