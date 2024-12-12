---
title: "Escenario en OpenStack"
date: 2024-12-11 17:15:00 +0000
categories: [Servicios, Cloud]
tags: [Cloud]
author: pablo
description: "En esta tarea se va a crear el escenario de trabajo que se va a usar durante todo el curso, que va a constar inicialmente de 4 máquinas: 2 instancias en OpenStack y dos contenedores LXC que se ejecutarán en una de las instancias."
toc: true
comments: true
image:
  path: /assets/img/posts/openstack/openstack.png
---

## Práctica (1 / 2): Escenario en OpenStack

Para nombrar las máquinas se van a utilizar los siguientes nombres: **luffy**, **zoro**, **nami**, **sanji**. Estos nombres pertenecen la serie manga **One Piece**.

Además el dominio será un subdominio de la forma tunombre.gonzalonazareno.org. De esta forma tendremos:

- Máquina 1: Instancia en OpenStack con **Debian 12 Bookworm** que se llama luffy.tunombre.gonzalonazareno.org.
- Máquina 2: Instancia en OpenStack con **Rocky Linux 9** que se llama zoro.tunombre.gonzalonazareno.org.
- Máquina 3: Contenedor LXC con **Ubuntu 22.04** que se llama nami.tunombre.gonzalonazareno.org.
- Máquina 4: Contenedor LXC con **Ubuntu 22.04** que se llama sanji.tunombre.gonzalonazareno.org.

Todas las operaciones que realices sobre recursos de OpenStack lo tienes que hacer usando OSC.

![image1](/assets/img/posts/openstack/os.drawio.png)

### Creación de la infraestructura de red

- Crea un nuevo router llamado **RouterPractica** conectado a la red externa.

Para crear el router ejecutamos el siguiente comando:

```
(os) pavlo@debian:~/OpenStack()$ openstack router create RouterPractica
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | UP                                   |
| availability_zone_hints   |                                      |
| availability_zones        |                                      |
| created_at                | 2024-12-11T17:32:26Z                 |
| description               |                                      |
| enable_default_route_bfd  | False                                |
| enable_default_route_ecmp | False                                |
| enable_ndp_proxy          | None                                 |
| external_gateway_info     | null                                 |
| external_gateways         | []                                   |
| flavor_id                 | None                                 |
| id                        | c94e22f0-5551-4842-9628-a9d3929b5539 |
| name                      | RouterPractica                       |
| project_id                | 07df99f775d343a58e702b5c99adcbad     |
| revision_number           | 1                                    |
| routes                    |                                      |
| status                    | ACTIVE                               |
| tags                      |                                      |
| tenant_id                 | 07df99f775d343a58e702b5c99adcbad     |
| updated_at                | 2024-12-11T17:32:26Z                 |
+---------------------------+--------------------------------------+
```

Luego, lo añadimos a la red pública que por lo general suele ser *public*, aunque en este caso es *ext-net*:

```
(os) pavlo@debian:~/OpenStack()$ openstack router set RouterPractica --external-gateway ext-net
```

- Crea una red interna que se llame **Red Intra de tu_usuario**, con las siguientes características:

    - Está conectada al router que has creado en el punto anterior.

    - Direccionamiento: `10.0.200.0/24`

    - Con DHCP y DNS `(172.22.0.1)`.
    
    - La puerta de enlace de los dispositivos conectados a esta red será el `10.0.200.1`.


Para este paso debemos crear una red:

```
(os) pavlo@debian:~/OpenStack()$ openstack network create red-intra-pablo
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | UP                                   |
| availability_zone_hints   |                                      |
| availability_zones        |                                      |
| created_at                | 2024-12-11T17:33:53Z                 |
| description               |                                      |
| dns_domain                | None                                 |
| id                        | 260d2b52-38e8-449f-a368-a68824d2474f |
| ipv4_address_scope        | None                                 |
| ipv6_address_scope        | None                                 |
| is_default                | False                                |
| is_vlan_transparent       | None                                 |
| mtu                       | 1442                                 |
| name                      | red-intra-pablo                      |
| port_security_enabled     | True                                 |
| project_id                | 07df99f775d343a58e702b5c99adcbad     |
| provider:network_type     | None                                 |
| provider:physical_network | None                                 |
| provider:segmentation_id  | None                                 |
| qos_policy_id             | None                                 |
| revision_number           | 1                                    |
| router:external           | Internal                             |
| segments                  | None                                 |
| shared                    | False                                |
| status                    | ACTIVE                               |
| subnets                   |                                      |
| tags                      |                                      |
| updated_at                | 2024-12-11T17:33:53Z                 |
+---------------------------+--------------------------------------+
```

Luego, crear la subred con las especificaciones:

```
(os) pavlo@debian:~/OpenStack()$ openstack subnet create red-intra-pablo-subnet \
> --network red-intra-pablo \
> --subnet-range 10.0.200.0/24 \
> --dhcp \
> --gateway 10.0.200.1 \
> --dns-nameserver 172.22.0.1
+----------------------+--------------------------------------+
| Field                | Value                                |
+----------------------+--------------------------------------+
| allocation_pools     | 10.0.200.2-10.0.200.254              |
| cidr                 | 10.0.200.0/24                        |
| created_at           | 2024-12-11T17:35:40Z                 |
| description          |                                      |
| dns_nameservers      | 172.22.0.1                           |
| dns_publish_fixed_ip | None                                 |
| enable_dhcp          | True                                 |
| gateway_ip           | 10.0.200.1                           |
| host_routes          |                                      |
| id                   | 7ef74cd9-63bf-4b2e-8479-69250a4a087b |
| ip_version           | 4                                    |
| ipv6_address_mode    | None                                 |
| ipv6_ra_mode         | None                                 |
| name                 | red-intra-pablo-subnet               |
| network_id           | 260d2b52-38e8-449f-a368-a68824d2474f |
| project_id           | 07df99f775d343a58e702b5c99adcbad     |
| revision_number      | 0                                    |
| segment_id           | None                                 |
| service_types        |                                      |
| subnetpool_id        | None                                 |
| tags                 |                                      |
| updated_at           | 2024-12-11T17:35:40Z                 |
+----------------------+--------------------------------------+
```

Por último añadimos la subnet creada en el paso anterior al router creado al principio:

```
(os) pavlo@debian:~/OpenStack()$ openstack router add subnet RouterPractica red-intra-pablo-subnet
```

- Crea una red interna que se llame **Red DMZ de tu_usuario**, con las siguientes características:

    - Direccionamiento: `172.16.0.0/16`

    - **Sin DHCP**.
    
    - **Deshabilitamos la puerta de enlace**. Esto es para que cloud-init no configure la puerta de enlace en las instancias conectada a esta red.

    - La puerta de enlace de los dispositivos conectados a esta red será el `172.16.0.1`.

Para crear esta red hacemos lo mismo que antes:
```
(os) pavlo@debian:~/OpenStack()$ openstack network create red-dmz-pablo
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | UP                                   |
| availability_zone_hints   |                                      |
| availability_zones        |                                      |
| created_at                | 2024-12-11T17:41:36Z                 |
| description               |                                      |
| dns_domain                | None                                 |
| id                        | b6ae55f9-e6fb-4509-bd3b-fd627a3da1d8 |
| ipv4_address_scope        | None                                 |
| ipv6_address_scope        | None                                 |
| is_default                | False                                |
| is_vlan_transparent       | None                                 |
| mtu                       | 1442                                 |
| name                      | red-dmz-pablo                        |
| port_security_enabled     | True                                 |
| project_id                | 07df99f775d343a58e702b5c99adcbad     |
| provider:network_type     | None                                 |
| provider:physical_network | None                                 |
| provider:segmentation_id  | None                                 |
| qos_policy_id             | None                                 |
| revision_number           | 1                                    |
| router:external           | Internal                             |
| segments                  | None                                 |
| shared                    | False                                |
| status                    | ACTIVE                               |
| subnets                   |                                      |
| tags                      |                                      |
| updated_at                | 2024-12-11T17:41:36Z                 |
+---------------------------+--------------------------------------+
```

Luego creamos la subnet indicando que no queremos dhcp ni puerta de enlace:
```
(os) pavlo@debian:~/OpenStack()$ openstack subnet create red-dmz-pablo-subnet \
> --network red-dmz-pablo \
> --subnet-range 172.16.0.0/16 \
> --no-dhcp \
> --gateway none
+----------------------+--------------------------------------+
| Field                | Value                                |
+----------------------+--------------------------------------+
| allocation_pools     | 172.16.0.1-172.16.255.254            |
| cidr                 | 172.16.0.0/16                        |
| created_at           | 2024-12-11T17:44:05Z                 |
| description          |                                      |
| dns_nameservers      |                                      |
| dns_publish_fixed_ip | None                                 |
| enable_dhcp          | False                                |
| gateway_ip           | None                                 |
| host_routes          |                                      |
| id                   | 450496f9-646a-42a4-9a8e-b07b5b3a992d |
| ip_version           | 4                                    |
| ipv6_address_mode    | None                                 |
| ipv6_ra_mode         | None                                 |
| name                 | red-dmz-pablo-subnet                 |
| network_id           | b6ae55f9-e6fb-4509-bd3b-fd627a3da1d8 |
| project_id           | 07df99f775d343a58e702b5c99adcbad     |
| revision_number      | 0                                    |
| segment_id           | None                                 |
| service_types        |                                      |
| subnetpool_id        | None                                 |
| tags                 |                                      |
| updated_at           | 2024-12-11T17:44:05Z                 |
+----------------------+--------------------------------------+
```

Aunque no configuramos la puerta de enlace en la red (para evitar que cloud-init lo haga automáticamente), las instancias pueden configurarla manualmente si es necesario.

La dirección `172.16.0.1` será la puerta de enlace predeterminada que los dispositivos pueden usar.

![image2](/assets/img/posts/openstack/proyecto.png)

### Instalación de las instancias de OpenStack

#### Configuración de las instancias

Las dos instancias que vamos a crear se van a configurar con `cloud-init` de la siguiente manera:

- Deben actualizar los paquetes de la distribución de la instancia.

- El dominio utilizado será del tipo `tunombre.gonzalonazareno.org`. Por lo tanto en la configuración con `cloud-init` habrá que indicar el hostname y el FQDN. 

- Se crearán dos usuarios:

  - Un usuario sin privilegios. Se puede llamar como quieras (pero el nombre será el mismo en todas las máquinas) y accederás a las máquinas usando tu clave ssh privada.

  - Un usuario `profesor`, que puede utilizar `sudo` sin contraseña. Copia de las claves públicas de todos los profesores en las instancias para que puedan acceder con el usuario `profesor`.

- Cambia la contraseña al usuario `root`.

Bueno pues para ello debemos crear el fichero `cloud-init-luffy.yaml` en donde añadiremos las configuraciones que se pide:

```yaml
#cloud-config
package_update: true
package_upgrade: true

hostname: luffy
fqdn: luffy.pablo.gonzalonazareno.org

users:
  - name: pablo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClFcnIhYd1oaEpvGi/f4psQc4+DaAZvSNIxVRRJHtRoJui8wbJybi3Om8yTOflgEcmBaUrJLkfmzmWqVq1j6MpESq72p7J2hdq2lXnvzdt3huYv5evFwyd0p/r72RfpVZzr3ILi/BS//SJqfVKlDEVbZRaOE5MU2XuElmFFY4EO7NiiZAkbatVqUOT8H/nrfXcad0mjZVxroVqHhsHV+06rxiB0xifG0xZv204Qj4zRura8uqZlEVAAwU+NO/SIGdRwpLY7n7xbQGe1DbjHgPUeVPjJX6HpMK41a43eGj4XYdYtZBLugaU8Mq1y6Kl3tE6cvYkQ9WFTYTLLNy3bvNRZpP2p6qAy5qn03ZLFICiXBNXPmrl5+KVrKaSipNaPHkmInvczbYJjXpfyVBsfEabt+0Y1629M+eEKkkl+iZmVr2ySDSS1gHxMC7zlJRaUhG27o26agpNPYPHH3mVXVjqdGg0ryH0YHZk1V8+Gt1Z9hZ7UYWE1UX8DCgFfecqdX0= pavlo@debian"
  - name: profesor
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmjoVIoZCx4QFXvljqozXGqxxlSvO7V2aizqyPgMfGqnyl0J9YXo6zrcWYwyWMnMdRdwYZgHqfiiFCUn2QDm6ZuzC4Lcx0K3ZwO2lgL4XaATykVLneHR1ib6RNroFcClN69cxWsdwQW6dpjpiBDXf8m6/qxVP3EHwUTsP8XaOV7WkcCAqfYAMvpWLISqYme6e+6ZGJUIPkDTxavu5JTagDLwY+py1WB53eoDWsG99gmvyit2O1Eo+jRWN+mgRHIxJTrFtLS6o4iWeshPZ6LvCZ/Pum12Oj4B4bjGSHzrKjHZgTwhVJ/LDq3v71/PP4zaI3gVB9ZalemSxqomgbTlnT jose@debian"
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDf9lnBH2nCT2ezpDZnqSBeDuSsVGGFD1Kzqa4KyIVkzkrD7pNHHkkpSuO4isKcCsUcopYOcA38QtG7wB0v/qn8Jsq731N8bjaKOdQN25vqLjwVj8DpYtvGc+ZA0uaChe7TS+QBzlMC9ypwj4wf15Q/z3v/ip4FF2cORT0cQC04cNRQDgUg4p1rlOs8+ma7OPh3P3UvzlPfLhi2H1yl+/mo4XLOcAMNr/jiZCwYxom6OEOYVBNk8MZX/Zn+qRi71D0RPiKg27AcXSD/FPWdQW9hBH1Zq5xGicUFS4C9yXvHKru7cMmmxV2G80p/ArRscKWq92UT5jIJQpccmHxsxdIi6o25LhcxH1dOnZy6kHcJ2yP24CnBHK5Y3SsovCD0Th6MN1VlTySbl8Ar0ypmY+GYO+oVd4bM3ioHzL0AMqYnS29m0UtEDvFEUUoSkOoLK4uSlcvej+OIVp7X5G7oZ56nZZf+qHEgodv++a6vPmhH2ZSgoOj1sE39DK7InuKSqCE= rafa@eco"
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDASDwvkY5SbIgM+/j14mNQluPV+/HGcM3ZgXrYDWt7zhQKq8KAXqJLs1vw1HcRv5PRV071caZQxV2ssfrNqIDofjSzWM1I1JkVIqIj4NCOsRFsQQFN8HwfkE9ic/X6vRaV+NfkEF+t3VmX2YgBd02ZbmGt53qjDaGMQRS/qxw3MPS+ynf2Fj8ZibT6DZeWnyjEGhFcyrggFWiPDqw77MNaiDr+31SO0TaP1WeIWFMrSwPVMVG1zvSxAQ9L13SQ5XzwK0Xs2A8kBPiZmPuUFRqYlBWeffhUnRPSg4TdOsWqJjEwFb5OwpQmTDCT5z0MSFCNVLV5GGwvvqCrw5jd1Xfdswdqazc8mCaIPIrCmhsiwz7uZvQDYr1HDrKxJ1L8LLo3usp4FM5cCCM5jptK+XffhmIyJSkMrcg6tYawBeNuAiY3dwPRIyKeV1Ku3UUctkN+kbuOpMQ4nSvAK0DyhUiTakc8qMJDNLD8oHhSEp49G2bzsLwFOmaEgb8falVMLyk= javji@Javier"
  - name: root
    passwd: "root"

final_message: "Instancia configurada correctamente."
```

Este fichero está destinado a la configuración de la instancia *luffy*.

A continuación, crearé el archivo `cloud-init-zoro.yaml` para la posterior creación de la instancia *zoro*.

```yaml
#cloud-config
package_update: true
package_upgrade: true
hostname: zoro
fqdn: zoro.pablo.gonzalonazareno.org
users:
  - name: pablo
    gecos: Usuario sin privilegios
    groups: []
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClFcnIhYd1oaEpvGi/f4psQc4+DaAZvSNIxVRRJHtRoJui8wbJybi3Om8yTOflgEcmBaUrJLkfmzmWqVq1j6MpESq72p7J2hdq2lXnvzdt3huYv5evFwyd0p/r72RfpVZzr3ILi/BS//SJqfVKlDEVbZRaOE5MU2XuElmFFY4EO7NiiZAkbatVqUOT8H/nrfXcad0mjZVxroVqHhsHV+06rxiB0xifG0xZv204Qj4zRura8uqZlEVAAwU+NO/SIGdRwpLY7n7xbQGe1DbjHgPUeVPjJX6HpMK41a43eGj4XYdYtZBLugaU8Mq1y6Kl3tE6cvYkQ9WFTYTLLNy3bvNRZpP2p6qAy5qn03ZLFICiXBNXPmrl5+KVrKaSipNaPHkmInvczbYJjXpfyVBsfEabt+0Y1629M+eEKkkl+iZmVr2ySDSS1gHxMC7zlJRaUhG27o26agpNPYPHH3mVXVjqdGg0ryH0YHZk1V8+Gt1Z9hZ7UYWE1UX8DCgFfecqdX0= pavlo@debian"

  - name: profesor
    gecos: Usuario Profesor
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmjoVIoZCx4QFXvljqozXGqxxlSvO7V2aizqyPgMfGqnyl0J9YXo6zrcWYwyWMnMdRdwYZgHqfiiFCUn2QDm6ZuzC4Lcx0K3ZwO2lgL4XaATykVLneHR1ib6RNroFcClN69cxWsdwQW6dpjpiBDXf8m6/qxVP3EHwUTsP8XaOV7WkcCAqfYAMvpWLISqYme6e+6ZGJUIPkDTxavu5JTagDLwY+py1WB53eoDWsG99gmvyit2O1Eo+jRWN+mgRHIxJTrFtLS6o4iWeshPZ6LvCZ/Pum12Oj4B4bjGSHzrKjHZgTwhVJ/LDq3v71/PP4zaI3gVB9ZalemSxqomgbTlnT jose@debian"
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDf9lnBH2nCT2ezpDZnqSBeDuSsVGGFD1Kzqa4KyIVkzkrD7pNHHkkpSuO4isKcCsUcopYOcA38QtG7wB0v/qn8Jsq731N8bjaKOdQN25vqLjwVj8DpYtvGc+ZA0uaChe7TS+QBzlMC9ypwj4wf15Q/z3v/ip4FF2cORT0cQC04cNRQDgUg4p1rlOs8+ma7OPh3P3UvzlPfLhi2H1yl+/mo4XLOcAMNr/jiZCwYxom6OEOYVBNk8MZX/Zn+qRi71D0RPiKg27AcXSD/FPWdQW9hBH1Zq5xGicUFS4C9yXvHKru7cMmmxV2G80p/ArRscKWq92UT5jIJQpccmHxsxdIi6o25LhcxH1dOnZy6kHcJ2yP24CnBHK5Y3SsovCD0Th6MN1VlTySbl8Ar0ypmY+GYO+oVd4bM3ioHzL0AMqYnS29m0UtEDvFEUUoSkOoLK4uSlcvej+OIVp7X5G7oZ56nZZf+qHEgodv++a6vPmhH2ZSgoOj1sE39DK7InuKSqCE= rafa@eco"
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDASDwvkY5SbIgM+/j14mNQluPV+/HGcM3ZgXrYDWt7zhQKq8KAXqJLs1vw1HcRv5PRV071caZQxV2ssfrNqIDofjSzWM1I1JkVIqIj4NCOsRFsQQFN8HwfkE9ic/X6vRaV+NfkEF+t3VmX2YgBd02ZbmGt53qjDaGMQRS/qxw3MPS+ynf2Fj8ZibT6DZeWnyjEGhFcyrggFWiPDqw77MNaiDr+31SO0TaP1WeIWFMrSwPVMVG1zvSxAQ9L13SQ5XzwK0Xs2A8kBPiZmPuUFRqYlBWeffhUnRPSg4TdOsWqJjEwFb5OwpQmTDCT5z0MSFCNVLV5GGwvvqCrw5jd1Xfdswdqazc8mCaIPIrCmhsiwz7uZvQDYr1HDrKxJ1L8LLo3usp4FM5cCCM5jptK+XffhmIyJSkMrcg6tYawBeNuAiY3dwPRIyKeV1Ku3UUctkN+kbuOpMQ4nSvAK0DyhUiTakc8qMJDNLD8oHhSEp49G2bzsLwFOmaEgb8falVMLyk= javji@Javier"
chpasswd:
  list: |
    root:root
  expire: False
```

#### Creación de las instancias

**máquina1 (luffy)**

- Crea una instancia sobre un volumen de 15Gb (el volumen se crea durante la creación de la instancia), usando una imagen de **Debian 12 Bookworm**. Elige el sabor `vol.medium`. Y configuralá con `cloud-init` como se ha indicado anteriormente.

- Está instancia estará conectada a las dos redes. Recuerda que en la red **Red DMZ** debe tomar la dirección `172.16.0.1` (puerta de enlace las máquinas conectadas a esta red). Asigna a la instancia una IP flotante.

- Deshabilita la seguridad de los puertos en las dos interfaces de red para que funcione de manera adecuada el NAT.

- Configura de forma permanente la regla SNAT para que las máquinas de la **Red DMZ** tengan acceso a internet.


En primer lugar debemos crear la instancia:

```bash
(os) pavlo@debian:~/OpenStack()$ openstack server create luffy \
> --flavor vol.medium \
> --image "Debian 12 Bookworm" \
> --network red-intra-pablo \
> --network red-dmz-pablo \
> --user-data cloud-init-luffy.yaml \
> --boot-from-volume 15 \
> --security-group default
```

Luego, le asignamos una IP flotante, para ello:

```shell
(os) pavlo@debian:~/OpenStack()$ openstack server add floating ip luffy 172.22.200.100
```

Comprobamos que se hayan añadido las interfaces correctamente:

```shell
(os) pavlo@debian:~/OpenStack()$ openstack server list
+--------------------------------------+-------+--------+--------------------------------------------------------------------------+--------------------------+------------+
| ID                                   | Name  | Status | Networks                                                                 | Image                    | Flavor     |
+--------------------------------------+-------+--------+--------------------------------------------------------------------------+--------------------------+------------+
| 91e29177-4a4f-4529-8594-4f867d2dd6bd | luffy | ACTIVE | red-dmz-pablo=172.16.3.142; red-intra-pablo=10.0.200.181, 172.22.200.100 | N/A (booted from volume) | vol.medium |
+--------------------------------------+-------+--------+--------------------------------------------------------------------------+--------------------------+------------+
```

Ahora debemos deshabilitar la seguridad de los puertos en las dos interfaces de red, para ello primero obtenemos las IDs de los puertos:

```shell
(os) pavlo@debian:~/OpenStack()$ openstack port list --server luffy
+--------------------------------------+------+-------------------+-----------------------------------------------------------------------------+--------+
| ID                                   | Name | MAC Address       | Fixed IP Addresses                                                          | Status |
+--------------------------------------+------+-------------------+-----------------------------------------------------------------------------+--------+
| 1505f6e0-7c0f-47d3-b865-1a5420c69246 |      | fa:16:3e:d9:cb:6a | ip_address='172.16.3.142', subnet_id='450496f9-646a-42a4-9a8e-b07b5b3a992d' | ACTIVE |
| 3168307f-1878-4306-a1c3-81256a9dd85a |      | fa:16:3e:ff:1e:6d | ip_address='10.0.200.181', subnet_id='7ef74cd9-63bf-4b2e-8479-69250a4a087b' | ACTIVE |
+--------------------------------------+------+-------------------+-----------------------------------------------------------------------------+--------+
```

Y una vez sabemos las IDs ya podemos deshabilitarlos:

```shell
(os) pavlo@debian:~/OpenStack()$ openstack port set 1505f6e0-7c0f-47d3-b865-1a5420c69246 --no-security-group --disable-port-security
```

```shell
(os) pavlo@debian:~/OpenStack()$ openstack port set 3168307f-1878-4306-a1c3-81256a9dd85a --no-security-group --disable-port-security
```

Antes de aceder al router (luffy) y realizar el SNAT voy a añadir en el `~/.ssh/config` la máquina para poder conectarme de forma más sencilla:

```shell
Host luffy
  HostName 172.22.200.100
  User pablo
  ForwardAgent yes
```

De forma que ya puedo acceder a la instancia:

```shell
(os) pavlo@debian:~/OpenStack()$ ssh luffy 
Linux luffy 6.1.0-28-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.119-1 (2024-11-22) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Wed Dec 11 22:48:14 2024 from 172.29.0.34
pablo@luffy:~$
```

Una vez accedido a luffy habilitamos el bit de forwarding en el fichero `/etc/sysctl.conf`, en donde descomentamos la siguiente línea:

```shell
net.ipv4.ip_forward=1
```

Aplicamos los cambios:
```shell
pablo@luffy:~$ sudo sysctl -p
net.ipv4.ip_forward = 1
```

Ahora debemos configurar la reglas SNAT con `iptables`, pero antes miramos las direcciones IP de las interfaces:

```bash
pablo@luffy:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1442 qdisc fq_codel state UP group default qlen 1000
    link/ether fa:16:3e:8c:07:52 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.200.231/24 metric 100 brd 10.0.200.255 scope global dynamic ens3
       valid_lft 42718sec preferred_lft 42718sec
    inet6 fe80::f816:3eff:fe8c:752/64 scope link 
       valid_lft forever preferred_lft forever
3: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1442 qdisc fq_codel state UP group default qlen 1000
    link/ether fa:16:3e:67:5a:49 brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    inet 172.16.0.16/16 brd 172.16.255.255 scope global ens4
       valid_lft forever preferred_lft forever
    inet6 fe80::f816:3eff:fe67:5a49/64 scope link 
       valid_lft forever preferred_lft forever
```

En base a esta configuración de interfaces de red:

- `ens3`: Interfaz conectada a la red interna (`red-intra-pablo`, 10.0.200.0/24).
- `ens4`: Interfaz conectada a la red DMZ (`red-dmz-pablo`, 172.16.0.0/16).

Dado esto, necesitamos configurar las reglas SNAT para que el tráfico desde Red DMZ pueda salir a Internet a través de ens3. Para ello:

```bash
sudo iptables -t nat -A POSTROUTING -o ens3 -s 172.16.0.0/16 -j MASQUERADE
```

De forma que quede así:
```bash
pablo@luffy:~$ sudo iptables -t nat -L -v
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 MASQUERADE  all  --  any    ens3    172.16.0.0/16        anywhere
```

Para hacer las reglas persistentes instalamos el siguiente paquete:
```bash
sudo apt install iptables-persistent
```

En la misma instalación si detecta reglas existentes las guarda automáticamente, aunque si añadimos otras reglas debemos hacerlo manualmente.

Con esto, ya habríamos terminado la instalación y configuración al completo del router luffy.

**maquina2 (zoro)**

- Crea un volumen de 15Gb con la imagen `Rocky Linux 9`.

- Crea la instancia a partir de este volumen. Elige el sabor `vol.medium`. Y configúrala con `cloud-init` como se ha indicado anteriormente.

- En un primer momento, para que la instancia se configure mediante cloud-init conecta esta instancia a un red con DHCP.

- Posteriormente, desconecta la interfaz de red de esa red y conéctala a la red **Red DMZ** a la dirección `172.16.0.200`.  

- Recuerda, que esa configuración no se hará de forma automática por lo que deberas, de forma manual, configurar la red en esta máquina. recuerda que Rocky Linux tiene instalado por defecto NetwokManager.

- Deshabilita la seguridad de los puertos en la interfaz de red para que funcione de manera adecuada el NAT.

- Comprueba que tiene acceso a internet.


Empezamos creando el volumen a partir de la imagen:

```bash
(os) pavlo@debian:~/OpenStack()$ openstack volume create --size 15 --image "Rocky Linux 9" volumen-zoro
+---------------------+------------------------------------------------------------------+
| Field               | Value                                                            |
+---------------------+------------------------------------------------------------------+
| attachments         | []                                                               |
| availability_zone   | nova                                                             |
| bootable            | false                                                            |
| consistencygroup_id | None                                                             |
| created_at          | 2024-12-12T07:44:39.479661                                       |
| description         | None                                                             |
| encrypted           | False                                                            |
| id                  | 786b9400-013c-4bf3-9986-1896891628bf                             |
| multiattach         | False                                                            |
| name                | volumen-zoro                                                     |
| properties          |                                                                  |
| replication_status  | None                                                             |
| size                | 15                                                               |
| snapshot_id         | None                                                             |
| source_volid        | None                                                             |
| status              | creating                                                         |
| type                | lvmdriver-1                                                      |
| updated_at          | None                                                             |
| user_id             | a74499e28f7622936621adb74c2b02fe4a18a1f6964a32bdbb23af09b776065f |
+---------------------+------------------------------------------------------------------+
```

Seguidamente creamos la instancia a partir del volumen, conectándola en un principio a una red con DHCP como `red-intra-pablo`.

```bash
(os) pavlo@debian:~/OpenStack()$ openstack server create zoro \
    --flavor vol.medium \
    --volume volumen-zoro \
    --network red-intra-pablo \
    --user-data cloud-init-zoro.yaml \
    --security-group default
```

Comprobamos que se haya creado correctamente:

```bash
(os) pavlo@debian:~/OpenStack()$ openstack server list
+--------------------------------------+-------+--------+-------------------------------------------------------------------------+--------------------------+------------+
| ID                                   | Name  | Status | Networks                                                                | Image                    | Flavor     |
+--------------------------------------+-------+--------+-------------------------------------------------------------------------+--------------------------+------------+
| 82692c6d-9d36-4bdd-86b6-46e90bea1892 | zoro  | ACTIVE | red-intra-pablo=10.0.200.132                                            | N/A (booted from volume) | vol.medium |
| 9c9e8c12-7712-404e-aa3b-2e2bf566ca0c | luffy | ACTIVE | red-dmz-pablo=172.16.0.16; red-intra-pablo=10.0.200.231, 172.22.200.100 | N/A (booted from volume) | vol.medium |
+--------------------------------------+-------+--------+-------------------------------------------------------------------------+--------------------------+------------+
```

Ya que se ha creado la instancia y el cloud-init se ha configurado correctamente, añadimos en el fichero `~/.ssh/config` la nueva configuración **temporal**:
```shell
Host luffy
  HostName 172.22.200.100
  User pablo
  ForwardAgent yes

Host zoro
  HostName 10.0.200.244
  User pablo
  ForwardAgent yes
  ProxyJump luffy
```

Además, añadimos la nueva interfaz que estará conectada a la **Red DMZ** con la dirección `172.16.0.200`, la que posteriormente vamos a configurar manualmente:
```bash
(os) pavlo@debian:~/OpenStack()$ openstack server add port zoro \
> $(openstack port create --network red-dmz-pablo --fixed-ip subnet=red-dmz-pablo-subnet,ip-address=172.16.0.200 puerto-zoro -f value -c id)
```

Accedemos a la instancia:
```bash
(os) pavlo@debian:~/OpenStack()$ ssh zoro 
The authenticity of host '10.0.200.244 (<no hostip for proxy command>)' can't be established.
ED25519 key fingerprint is SHA256:JrbuXBRRZ4JoLGdRCCiKNThDEKWqINQtX2NVLKP7Gvo.
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:421: [hashed name]
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.0.200.244' (ED25519) to the list of known hosts.
Last login: Thu Dec 12 07:52:34 2024 from 10.0.200.231
```

Y hacemos algunas comprobaciones:
```bash
[pablo@zoro ~]$ hostname -f
zoro.pablo.gonzalonazareno.org
[pablo@zoro ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1442 qdisc fq_codel state UP group default qlen 1000
    link/ether fa:16:3e:78:8b:9e brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    altname ens3
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1442 qdisc fq_codel state UP group default qlen 1000
    link/ether fa:16:3e:87:ca:cd brd ff:ff:ff:ff:ff:ff
    altname enp0s7
    altname ens7
    inet 10.0.200.244/24 brd 10.0.200.255 scope global dynamic noprefixroute eth1
       valid_lft 43120sec preferred_lft 43120sec
    inet6 fe80::7f34:f482:b58c:edcc/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

Como vemos la interfaz `eth0` está sin direccionamiento, por lo que vamos a añadir la IP para luego poder eliminar la `red-intra-pablo`.

Para ello, creamos el fichero `/etc/NetworkManager/system-connections/dmz.nmconnection` con la siguiente configuración:
```bash
[connection]
id=dmz
type=ethernet
interface-name=eth0

[ipv4]
method=manual
addresses=172.16.0.200/16
gateway=172.16.0.16
dns=8.8.8.8;1.1.1.1

[ipv6]
method=ignore
```

Seguidamente reiniciamos los servicios:
```shell
[pablo@zoro ~]$ sudo nmcli connection reload
[pablo@zoro ~]$ sudo systemctl restart NetworkManager
[pablo@zoro ~]$ sudo nmcli connection up dmz
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/4)
```

Y ya tenemos dirección IP:
```shell
[pablo@zoro ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1442 qdisc fq_codel state UP group default qlen 1000
    link/ether fa:16:3e:78:8b:9e brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    altname ens3
    inet 172.16.0.200/16 brd 172.16.255.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::f816:3eff:fe78:8b9e/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1442 qdisc fq_codel state UP group default qlen 1000
    link/ether fa:16:3e:87:ca:cd brd ff:ff:ff:ff:ff:ff
    altname enp0s7
    altname ens7
    inet 10.0.200.244/24 brd 10.0.200.255 scope global dynamic noprefixroute eth1
       valid_lft 43193sec preferred_lft 43193sec
    inet6 fe80::7f34:f482:b58c:edcc/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

Ahora, nos salimos de la instancia y revocamos la `red-intra-pablo`:

```bash
pavlo@debian:~/OpenStack()$ openstack server remove network zoro red-intra-pablo
```

Más tarde, modificamos el fichero `~/.ssh/config` para que acceda con la nueva IP:
```bash
Host luffy
  HostName 172.22.200.100
  User pablo
  ForwardAgent yes

Host zoro
  HostName 172.16.0.200
  User pablo
  ForwardAgent yes
  ProxyJump luffy
```

Y ya nos dejaría acceder:
```shell
pavlo@debian:~/OpenStack()$ ssh zoro 
The authenticity of host '172.16.0.200 (<no hostip for proxy command>)' can't be established.
ED25519 key fingerprint is SHA256:JrbuXBRRZ4JoLGdRCCiKNThDEKWqINQtX2NVLKP7Gvo.
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:421: [hashed name]
    ~/.ssh/known_hosts:424: [hashed name]
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '172.16.0.200' (ED25519) to the list of known hosts.
Last login: Thu Dec 12 08:30:57 2024 from 10.0.200.231
[pablo@zoro ~]$
```

Antes de probar la conexión a Internet debemos deshabilitar la seguridad de los puertos para que el NAT funcione correctamente:

```bash
pavlo@debian:~/OpenStack()$ openstack port list --server zoro
+--------------------------------------+-------------+-------------------+-----------------------------------------------------------------------------+--------+
| ID                                   | Name        | MAC Address       | Fixed IP Addresses                                                          | Status |
+--------------------------------------+-------------+-------------------+-----------------------------------------------------------------------------+--------+
| 3dd6bcc3-0c30-4f37-ae10-3d70767efff1 | puerto-zoro | fa:16:3e:78:8b:9e | ip_address='172.16.0.200', subnet_id='450496f9-646a-42a4-9a8e-b07b5b3a992d' | ACTIVE |
+--------------------------------------+-------------+-------------------+-----------------------------------------------------------------------------+--------+
```

```bash
pavlo@debian:~/OpenStack()$ openstack port set 3dd6bcc3-0c30-4f37-ae10-3d70767efff1 --no-security-group --disable-port-security
```

Pudiendo de esta forma acceder a Internet:
```bash
[pablo@zoro ~]$ ping -c 4 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=103 time=18.0 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=103 time=17.8 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=103 time=17.6 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=103 time=17.1 ms

--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 17.086/17.607/17.958/0.325 ms
```