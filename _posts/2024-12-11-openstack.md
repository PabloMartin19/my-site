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

La dirección 172.16.0.1 será la puerta de enlace predeterminada que los dispositivos pueden usar.

![image2](/assets/img/posts/openstack/proyecto.png)

kk