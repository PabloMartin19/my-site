---
title: "VPN sitio a sitio con WireGuard"
date: 2025-01-29 20:00:00 +0000
categories: [Seguridad, VPN]
tags: [VPN]
author: pablo
description: "En esta práctica implementamos una solución VPN utilizando WireGuard para establecer una conexión segura y eficiente entre dos redes distintas. La configuración permite la comunicación bidireccional entre un cliente en una red local y otro en una red remota, a través de sus respectivos servidores que actúan como gateways. La implementación demuestra la simplicidad y eficacia de WireGuard y una configuración robusta que garantiza la seguridad en la comunicación entre ambas redes."
toc: true
comments: true
image:
  path: /assets/img/posts/vpn/portada1.jpg
---

## Escenario

Para la realización de esta práctica reutilizaré el escenario creado en el [ejercicio B](https://pablomh.netlify.app/posts/site_to_site_openvpn/), solo que esta vez haciendo uso de WireGuard.

![image](/assets/img/posts/vpn/escenario2.png)


## Configuración ServidorCasa

Comenzamos actualizando el sistema e instalando WireGuard:

```bash
debian@ServidorCasa:~$ sudo apt update && sudo apt upgrade -y && sudo apt install wireguard -y
```

Activamos el bit de forwarding que nos permitirá dejar pasar los paquetes a través de las máquinas para así permitir la conexión entre los dos clientes.

```bash
debian@ServidorCasa:~$ sudo sysctl -p
net.ipv4.ip_forward = 1
```

Nos hemos movido al directorio de WireGuard y generado las claves:

```bash
debian@ServidorCasa:~$ sudo su
root@ServidorCasa:/home/debian# cd /etc/wireguard/
root@ServidorCasa:/etc/wireguard# wg genkey | tee clave_priv_servidor | wg pubkey > clave_pub_servidor
```

Verificamos la creación de las claves:

```bash
root@ServidorCasa:/etc/wireguard# ls -l
total 8
-rw-r--r-- 1 root root 45 Jan 29 18:37 clave_priv_servidor
-rw-r--r-- 1 root root 45 Jan 29 18:37 clave_pub_servidor
```

Vemos las claves generadas:

```bash
root@ServidorCasa:/etc/wireguard# cat clave_priv_servidor 
KCsoaA/EFnFZTHPvy+LLwhS7pzOi8ZZ7XnOWsVFR60E=
root@ServidorCasa:/etc/wireguard# cat clave_pub_servidor 
Rateb4vQZBBr1mTkUcAECpcIPEuHWbMnJA5FWRYrpBA=
```

Ahora pasamos a la configuración inicial del túnel:

```bash
root@ServidorCasa:/etc/wireguard# cat wg0.conf 
[Interface]
Address = 10.99.99.1
PrivateKey = KCsoaA/EFnFZTHPvy+LLwhS7pzOi8ZZ7XnOWsVFR60E=
ListenPort = 51820
```

Donde:

- **Address**: Define la dirección IP del túnel.
- **PrivateKey**: Clave privada del mismo Servidor que sirve para descifrar el tráfico entrante.
- **ListenPort**: Puerto UDP para conexiones WireGuard.

Después de crear el archivo de configuración, levantamos la interfaz del túnel:

```bash
root@ServidorCasa:/etc/wireguard# wg-quick up wg0
[#] ip link add wg0 type wireguard
[  567.662716] wireguard: WireGuard 1.0.0 loaded. See www.wireguard.com for information.
[  567.663520] wireguard: Copyright (C) 2015-2019 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.1 dev wg0
[#] ip link set mtu 1420 up dev wg0
```

Y comprobamos que funciones:

```bash
root@ServidorCasa:/etc/wireguard# wg
interface: wg0
  public key: Rateb4vQZBBr1mTkUcAECpcIPEuHWbMnJA5FWRYrpBA=
  private key: (hidden)
  listening port: 51820
```


## ServidorInsti

Seguimos los mismos pasos de actualización e instalación:

```bash
debian@ServidorInsti:~$ sudo apt update && sudo apt upgrade -y && sudo apt install wireguard -y
```

Habilitamos el bit de forwarding:

```bash
debian@ServidorInsti:~$ sudo sysctl -p
net.ipv4.ip_forward = 1
```

Generamos las claves, tanto privada como pública:

```bash
debian@ServidorInsti:~$ sudo su
root@ServidorInsti:/home/debian# cd /etc/wireguard/
root@ServidorInsti:/etc/wireguard# wg genkey | tee clave_priv_servidor | wg pubkey > clave_pub_servidor
```

Comprobamos que se hayan creado:

```bash
root@ServidorInsti:/etc/wireguard# ls -l
total 8
-rw-r--r-- 1 root root 45 Jan 29 18:43 clave_priv_servidor
-rw-r--r-- 1 root root 45 Jan 29 18:43 clave_pub_servidor
```

Y vemos su contenido:

```bash
root@ServidorInsti:/etc/wireguard# cat clave_priv_servidor 
kBOZ9Y2KQov8MG1abu/GlPAV1zVf+BroKJ0Y11+B+1U=

root@ServidorInsti:/etc/wireguard# cat clave_pub_servidor 
/XRNDwaFmadC4eCe+KtjoxPg4q9nJZnBCVZymBqJBXE=
```

Creamos el fichero de configuración `wg0.conf`:

```bash
root@ServidorInsti:/etc/wireguard# cat wg0.conf 
[Interface]
Address = 10.99.99.2
PrivateKey = kBOZ9Y2KQov8MG1abu/GlPAV1zVf+BroKJ0Y11+B+1U=
ListenPort = 51820

[Peer]
PublicKey = Rateb4vQZBBr1mTkUcAECpcIPEuHWbMnJA5FWRYrpBA=
AllowedIPs = 10.99.99.1/32, 192.168.1.0/24
Endpoint = 10.10.10.33:51820
```

Donde:

- **PublicKey**: Clave pública del ServidorCasa
- **AllowedIPs**:
    - 10.99.99.1/32: IP del túnel del peer
    - 192.168.1.0/24: Red remota accesible

- **Endpoint**: Dirección IP y puerto del ServidorCasa

Seguidamente levantamos la interfaz del túnel:

```bash
root@ServidorInsti:/etc/wireguard# wg-quick up wg0
[#] ip link add wg0 type wireguard
[ 1183.306337] wireguard: WireGuard 1.0.0 loaded. See www.wireguard.com for information.
[ 1183.307164] wireguard: Copyright (C) 2015-2019 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.2 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ip -4 route add 10.99.99.1/32 dev wg0
[#] ip -4 route add 192.168.1.0/24 dev wg0
```

Y compobamos:

```bash
root@ServidorInsti:/etc/wireguard# wg
interface: wg0
  public key: /XRNDwaFmadC4eCe+KtjoxPg4q9nJZnBCVZymBqJBXE=
  private key: (hidden)
  listening port: 51820

peer: Rateb4vQZBBr1mTkUcAECpcIPEuHWbMnJA5FWRYrpBA=
  endpoint: 10.10.10.33:51820
  allowed ips: 10.99.99.1/32, 192.168.1.0/24
```

También podemos ver que se ha añadido la interfaz del túnel correctamente:

```bash
root@ServidorInsti:/etc/wireguard# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:a7:2a:ff:00:00 brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    inet 10.10.10.44/24 brd 10.10.10.255 scope global ens4
       valid_lft forever preferred_lft forever
    inet6 fe80::ea7:2aff:feff:0/64 scope link 
       valid_lft forever preferred_lft forever
3: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:a7:2a:ff:00:01 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 172.22.0.1/24 brd 172.22.0.255 scope global ens5
       valid_lft forever preferred_lft forever
    inet6 fe80::ea7:2aff:feff:1/64 scope link 
       valid_lft forever preferred_lft forever
4: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN group default qlen 1000
    link/none 
    inet 10.99.99.2/32 scope global wg0
       valid_lft forever preferred_lft forever
```


Una vez terminado en **ServidorInsti** debemos volver al fichero de configuración del túnel de **ServidorCasa**

```bash
root@ServidorCasa:/etc/wireguard# cat wg0.conf 
[Interface]
Address = 10.99.99.1
PrivateKey = KCsoaA/EFnFZTHPvy+LLwhS7pzOi8ZZ7XnOWsVFR60E=
ListenPort = 51820

[Peer]
PublicKey = /XRNDwaFmadC4eCe+KtjoxPg4q9nJZnBCVZymBqJBXE=
AllowedIPs = 10.99.99.2/32, 172.22.0.0/24
Endpoint = 10.10.10.44:51820
```

En donde hemos añadido los parámetros necesarios para la conectividad con el otro servidor.

De forma que reiniciamos:

```bash
root@ServidorCasa:/etc/wireguard# wg-quick up wg0
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.1 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ip -4 route add 10.99.99.2/32 dev wg0
[#] ip -4 route add 172.22.0.0/24 dev wg0
```

Comprobamos de nuevo:

```bash
root@ServidorCasa:/etc/wireguard# wg
interface: wg0
  public key: Rateb4vQZBBr1mTkUcAECpcIPEuHWbMnJA5FWRYrpBA=
  private key: (hidden)
  listening port: 51820

peer: /XRNDwaFmadC4eCe+KtjoxPg4q9nJZnBCVZymBqJBXE=
  endpoint: 10.10.10.44:51820
  allowed ips: 10.99.99.2/32, 172.22.0.0/24
```

Y nos damos cuenta que se ha añadido la interfaz del túnel:

```bash
root@ServidorCasa:/etc/wireguard# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:aa:df:00:00:00 brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    inet 192.168.1.1/24 brd 192.168.1.255 scope global ens4
       valid_lft forever preferred_lft forever
    inet6 fe80::eaa:dfff:fe00:0/64 scope link 
       valid_lft forever preferred_lft forever
3: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0c:aa:df:00:00:01 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 10.10.10.33/24 brd 10.10.10.255 scope global ens5
       valid_lft forever preferred_lft forever
    inet6 fe80::eaa:dfff:fe00:1/64 scope link 
       valid_lft forever preferred_lft forever
5: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN group default qlen 1000
    link/none 
    inet 10.99.99.1/32 scope global wg0
       valid_lft forever preferred_lft forever
```


## Pruebas de funcionamiento

Para verificar que la VPN está funcionando correctamente y que los paquetes están siendo enrutados entre ambas redes, realizamos pruebas de traceroute desde **ClienteCasa** hacia **ClienteInsti** y al revés.

De **ClienteCasa** a **ClienteInsti**:

```bash
debian@ClienteCasa:~$ ping -c 2 172.22.0.2
PING 172.22.0.2 (172.22.0.2) 56(84) bytes of data.
64 bytes from 172.22.0.2: icmp_seq=1 ttl=62 time=6.40 ms
64 bytes from 172.22.0.2: icmp_seq=2 ttl=62 time=4.77 ms

--- 172.22.0.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 4.770/5.584/6.399/0.814 ms
debian@ClienteCasa:~$ traceroute 172.22.0.2
traceroute to 172.22.0.2 (172.22.0.2), 30 hops max, 60 byte packets
 1  _gateway (192.168.1.1)  1.157 ms  1.100 ms  1.085 ms
 2  10.99.99.2 (10.99.99.2)  2.813 ms  2.817 ms  2.803 ms
 3  172.22.0.2 (172.22.0.2)  4.195 ms  4.183 ms  4.171 ms
```

![image](/assets/img/posts/vpn/image19.png)

De **ClienteInsti** a **ClienteCasa**:

```bash
debian@ClienteInsti:~$ ping -c 2 192.168.1.2
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
64 bytes from 192.168.1.2: icmp_seq=1 ttl=62 time=1.27 ms
64 bytes from 192.168.1.2: icmp_seq=2 ttl=62 time=4.47 ms

--- 192.168.1.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 1.274/2.873/4.472/1.599 ms
debian@ClienteInsti:~$ traceroute 192.168.1.2
traceroute to 192.168.1.2 (192.168.1.2), 30 hops max, 60 byte packets
 1  _gateway (172.22.0.1)  0.325 ms  0.300 ms  0.295 ms
 2  10.99.99.1 (10.99.99.1)  0.713 ms  0.700 ms  0.697 ms
 3  192.168.1.2 (192.168.1.2)  1.264 ms  1.260 ms  1.255 ms
```

![image](/assets/img/posts/vpn/image20.png)


## Conclusión

Al igual que dije en el apartado anterior, definitivamente WireGuard me parece mucho más cómodo y fácil de usar. Además, es más rápido ya que no tienes que tratar con certificados, tan solo con el intercambio de claves para que funcione el túnel.