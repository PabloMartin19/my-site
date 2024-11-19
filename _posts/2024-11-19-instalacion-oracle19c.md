---
title: "Instalación de Oracle 19c en Debian 12"
date: 2024-11-15 17:15:00 +0000
categories: [Base de Datos, Instalación]
tags: [Instalación]
author: pablo
description: "Este post muestra cómo instalar y configurar Oracle 19c en Debian 12, cubriendo los pasos clave desde la instalación hasta la configuración básica. 🚀"
toc: true
comments: true
image:
  path: assets/img/posts/oracle19c/Oracle19c.jpg
---

## Introducción

En este post, voy a detallar el proceso de instalación de Oracle 19c en una máquina virtual con Debian 12, utilizando QEMU/KVM como plataforma de virtualización. Para este tipo de instalación, es fundamental asegurarse de que la máquina virtual tenga recursos suficientes para que Oracle funcione correctamente. En este caso, se recomienda asignar al menos 4096 MB de memoria RAM, 4 núcleos de procesador (cores) y 40 GB de almacenamiento. Estos recursos permitirán que la base de datos funcione de manera estable, incluso en entornos de prueba o desarrollo.

La máquina virtual se configurará con la red "default", lo que le asignará automáticamente una dirección IP dentro del rango 192.168.122.x/24. Esta configuración de red es ideal para comunicaciones internas entre la máquina virtual y el sistema host, así como para facilitar la instalación y acceso remoto, si es necesario, sin complicaciones adicionales en cuanto a configuraciones de red. A continuación, explicaré detalladamente cómo configurar todo el entorno y proceder con la instalación de Oracle 19c paso a paso.

## Instalación

En este caso, se está configurando una red estática en la máquina virtual que va a hospedar Oracle 19c. Esta configuración es importante porque permite tener un control más preciso sobre la dirección IP de la máquina virtual, lo cual es crucial para garantizar que el sistema sea accesible y que la comunicación con otros dispositivos de la red no se vea interrumpida, especialmente cuando se trabaja con bases de datos como Oracle, que requieren un acceso constante y estable.

**Configuración de la interfaz de red estática**

El archivo `/etc/network/interfaces` en Debian es el encargado de definir cómo se gestionan las interfaces de red. En este caso, se está configurando la interfaz de red `enp1s0` con una dirección IP estática:

```bash
pablo@oracle-server:~$ cat /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
#allow-hotplug enp1s0
#iface enp1s0 inet dhcp

auto enp1s0
iface enp1s0 inet static
	address 192.168.122.126
	netmask 255.255.255.0
	gateway 192.168.122.1

```

**Configuración del archivo `/etc/hosts`**

El archivo `/etc/hosts` se utiliza para mapear direcciones IP a nombres de host. En este caso, se ha añadido una entrada para la dirección IP estática que se configuró en el paso anterior, asociándola al nombre `oracle-server`:

```bash
pablo@oracle-server:~$ cat /etc/hosts
127.0.0.1	localhost
127.0.1.1	oracle-server

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
192.168.122.126	oracle-server

```
La combinación de una red estática con la entrada en `/etc/hosts` garantiza que la máquina virtual siempre tendrá la misma dirección IP en la red y que será posible referenciarla mediante un nombre fácil de recordar, como `oracle-server`, tanto en la máquina virtual como en otros dispositivos o aplicaciones que necesiten comunicarse con ella.

Cuando realizas una instalación de Oracle 19c en Debian 12, uno de los primeros pasos que debes hacer es asegurarte de que el sistema esté completamente actualizado y tenga todas las dependencias necesarias para que Oracle funcione sin problemas. Para ello, realizarás dos comandos importantes que explico a continuación:

```bash
pablo@oracle-server:~$ sudo apt update && sudo apt upgrade -y
Obj:1 http://deb.debian.org/debian bookworm InRelease
Obj:2 http://security.debian.org/debian-security bookworm-security InRelease
Obj:3 http://deb.debian.org/debian bookworm-updates InRelease
Leyendo lista de paquetes... Hecho
Creando árbol de dependencias... Hecho
Leyendo la información de estado... Hecho
Todos los paquetes están actualizados.
Leyendo lista de paquetes... Hecho
Creando árbol de dependencias... Hecho
Leyendo la información de estado... Hecho
Calculando la actualización... Hecho
0 actualizados, 0 nuevos se instalarán, 0 para eliminar y 0 no actualizados.
```

E instalamos las dependencias necesarias:

```bash
pablo@oracle-server:~$ sudo apt install libaio1 unixodbc bc ksh gawk -y
```

Este comando instala una serie de paquetes necesarios para el funcionamiento de Oracle 19c. Cada uno de estos paquetes cumple una función específica dentro del entorno de Oracle y en la configuración del sistema:

- `libaio1`: Este paquete instala las bibliotecas de entrada/salida asíncrona (AIO) necesarias para Oracle. Oracle utiliza AIO para realizar operaciones de lectura y escritura sin bloquear el proceso, lo que mejora el rendimiento de la base de datos. Este es un requisito fundamental para que Oracle funcione correctamente en el sistema.

- `unixodbc`: Este paquete proporciona las bibliotecas y herramientas necesarias para gestionar la conectividad con bases de datos mediante ODBC (Open Database Connectivity). Aunque Oracle no siempre utiliza ODBC para la conectividad por defecto, algunas herramientas o configuraciones de Oracle pueden requerir este paquete para establecer conexiones a otras bases de datos o para ciertos procesos internos.

- `bc`: Este paquete instala una calculadora de precisión arbitraria, que es útil en muchos scripts y procesos de Oracle. Se usa, por ejemplo, para realizar cálculos matemáticos en la configuración o en la ejecución de scripts de mantenimiento y automatización de la base de datos.

- `ksh`: Este es el KornShell, un intérprete de comandos compatible con muchos de los scripts utilizados por Oracle. Aunque Oracle puede funcionar con otros shells, como bash, ciertos scripts y herramientas de Oracle requieren específicamente el KornShell para funcionar correctamente.

- `gawk`: Este paquete instala la versión GNU de AWK, que es un potente lenguaje de programación utilizado para procesamiento de texto y manipulación de datos. Oracle utiliza AWK en muchos de sus scripts de configuración y mantenimiento, por lo que es necesario tenerlo instalado para que los scripts internos de Oracle se ejecuten correctamente.

Oracle utiliza un enfoque de administración basado en roles, por lo que es importante crear un grupo y un usuario específico para garantizar que el sistema esté organizado y que las tareas administrativas puedan realizarse de manera controlada. Para ello:

```bash
pablo@oracle-server:~$ sudo groupadd dba
pablo@oracle-server:~$ sudo adduser --ingroup dba --home /home/oracle --shell /bin/bash oracle
Añadiendo el usuario `oracle' ...
Adding new user `oracle' (1001) with group `dba (1001)' ...
Creando el directorio personal `/home/oracle' ...
Copiando los ficheros desde `/etc/skel' ...
Nueva contraseña: 
Vuelva a escribir la nueva contraseña: 
passwd: contraseña actualizada correctamente
Cambiando la información de usuario para oracle
Introduzca el nuevo valor, o pulse INTRO para usar el valor predeterminado
	Nombre completo []: 
	Número de habitación []: 
	Teléfono del trabajo []: 
	Teléfono de casa []: 
	Otro []: 
¿Es correcta la información? [S/n] 
Adding new user `oracle' to supplemental / extra groups `users' ...
Añadiendo al usuario `oracle' al grupo `users' ...
```

En este paso del proceso de instalación de Oracle 19c, es importante mencionar que, aunque Oracle ofrece soporte para varias distribuciones de Linux, no proporciona soporte oficial para Debian. Esto significa que no existe un paquete `.deb` directamente disponible para instalar Oracle en Debian. Sin embargo, existen formas de sortear este inconveniente.

**Obtención del fichero de instalación**

El primer paso es descargar el archivo de instalación desde la página oficial de [Oracle](https://www.oracle.com/es/database/technologies/oracle19c-linux-downloads.html). Para ello, tendrás que acceder a la sección de descargas de Oracle en su sitio web, donde podrás encontrar el instalador correspondiente para Oracle 19c. Generalmente, Oracle proporciona el instalador en formato `.rpm` para sistemas basados en Red Hat, como CentOS o RHEL, pero no ofrece un paquete `.deb` directamente para Debian. Esto se debe a que Debian y sus derivados (como Ubuntu) utilizan un sistema de gestión de paquetes diferente, basado en el formato `.deb`.

**Conversión del paquete `.rpm` a `.deb` usando `alien`**

Dado que Oracle no ofrece un paquete nativo de Debian, una de las opciones es utilizar una herramienta llamada **`alien`** para convertir el paquete `.rpm` (Red Hat Package Manager) a un formato `.deb` compatible con Debian. 

**`alien`** es una herramienta que permite convertir entre diferentes formatos de paquetes de Linux, incluyendo `.rpm` a `.deb`. Aunque la conversión no es perfecta en todos los casos, generalmente funciona bien para muchos paquetes.

Para realizar la conversión, primero necesitas instalar `alien` en tu sistema Debian:

```
sudo apt install alien
```

Una vez instalado `alien`, puedes convertir el archivo `.rpm` a `.deb` con el siguiente comando:

```
sudo alien -d oracle-database-ee-19c-1.0-1.x86_64.rpm
```

- El parámetro `-d` le indica a `alien` que cree un paquete `.deb`. Este proceso generará un archivo `.deb` que podrás instalar de manera estándar en tu sistema Debian utilizando `dpkg`.

**Proceso ya realizado**

Como ya he realizado esta conversión previamente, para aligerar el proceso, he subido el paquete `.deb` a un servicio de almacenamiento en la nube, como **Mega**, para que puedas descargarlo directamente sin necesidad de hacer la conversión tú mismo.

Dejaré el **link de descarga** de este paquete `.deb` para que puedas instalar Oracle 19c sin complicaciones adicionales. Solo tendrás que descargar el archivo:

[Mega](https://mega.nz/folder/EgQzyQDR#HumPGeghjeLgikfy2TLD3A)

Una vez que hayas descargado el archivo .deb de Oracle 19c, el siguiente paso es transferir este fichero a la máquina virtual donde realizarás la instalación. Para ello, utilizaremos el comando scp (Secure Copy), que es una herramienta segura para transferir archivos entre sistemas a través de SSH.

El comando que he utilizado es el siguiente:
```bash
pavlo@debian:~()$ scp /home/pavlo/iso/oracle-database-ee-19c_1.0-2_amd64.deb pablo@192.168.122.126:/home/pablo
pablo@192.168.122.126's password: 
oracle-database-ee-19c_1.0-2_amd64.deb                                                                                                     100% 2409MB 101.4MB/s   00:23
```

Y como podemos ver ya lo tenemos en nuestra máquina virtual:
```bash
pablo@oracle-server:~$ ls
oracle-database-ee-19c_1.0-2_amd64.deb
```

Una vez que hemos transferido el archivo `.deb` de Oracle Database 19c a nuestra máquina virtual, es hora de proceder con la instalación. Para ello, usaremos el comando `dpkg`, que es el gestor de paquetes estándar en Debian. Aquí te dejo cómo hacerlo.
```bash
pablo@oracle-server:~$ sudo dpkg -i oracle-database-ee-19c_1.0-2_amd64.deb 
[sudo] contraseña para pablo: 
Seleccionando el paquete oracle-database-ee-19c previamente no seleccionado.
(Leyendo la base de datos ... 34459 ficheros o directorios instalados actualmente.)
Preparando para desempaquetar oracle-database-ee-19c_1.0-2_amd64.deb ...
ln: fallo al crear el enlace simbólico '/bin/awk': El fichero ya existe
Desempaquetando oracle-database-ee-19c (1.0-2) ...
Configurando oracle-database-ee-19c (1.0-2) ...
[INFO] Executing post installation scripts...
[INFO] Oracle home installed successfully and ready to be configured.
To configure a sample Oracle Database you can execute the following service configuration script as root: /etc/init.d/oracledb_ORCLCDB-19c configure
Procesando disparadores para libc-bin (2.36-9+deb12u9) ...
```

Una vez hecho esto, ya es hora de comenzar la instalación, pero antes recomiendo borrar el contenido del fichero `/etc/init.d/oracledb_ORCLCDB-19c` y añadir el siguiente contenido modificado:

```sh
#!/bin/bash
#
# chkconfig: 2345 80 05
# Description: This script is responsible for taking care of configuring the Oracle Database and its associated services.
#
# processname: oracledb_ORCLCDB-19c
# Red Hat or SuSE config: /etc/sysconfig/oracledb_ORCLCDB-19c
#

# Set path if path not set
case $PATH in
    "") PATH=/bin:/usr/bin:/sbin:/etc
         export PATH ;;
esac

# Check if the root user is running this script
if [ $(id -u) != "0" ]
then
    echo "You must be root user to run the configurations script. Login as root user and try again."
    exit 1
fi

# Setting the required environment variables
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export ORACLE_VERSION=19c 
export ORACLE_SID=ORCLCDB
export TEMPLATE_NAME=General_Purpose.dbc
export CHARSET=AL32UTF8
export PDB_NAME=ORCLPDB1
export LISTENER_NAME=LISTENER
export NUMBER_OF_PDBS=1
export CREATE_AS_CDB=true

# General exports and vars
export PATH=$ORACLE_HOME/bin:$PATH
LSNR=$ORACLE_HOME/bin/lsnrctl
SQLPLUS=$ORACLE_HOME/bin/sqlplus
DBCA=$ORACLE_HOME/bin/dbca
NETCA=$ORACLE_HOME/bin/netca
ORACLE_OWNER=oracle
RETVAL=0
CONFIG_NAME="oracledb_$ORACLE_SID-$ORACLE_VERSION.conf"
CONFIGURATION="/etc/sysconfig/$CONFIG_NAME"

# Commands
if [ -z "$SU" ];then SU=/bin/su; fi
if [ -z "$GREP" ]; then GREP=/usr/bin/grep; fi
if [ ! -f "$GREP" ]; then GREP=/bin/grep; fi

# To start the DB
start()
{
    check_for_configuration
    RETVAL=$?
    if [ $RETVAL -eq 1 ]
    then
        echo "The Oracle Database is not configured. You must run '/etc/init.d/oracledb_$ORACLE_SID-$ORACLE_VERSION configure' as the root user to configure the database."
        exit
    fi
    # Check if the DB is already started
    pmon=ps -ef | egrep pmon_$ORACLE_SID'\>' | $GREP -v grep
    if [ "$pmon" = "" ];
    then

        # Unset the proxy env vars before calling sqlplus
        unset_proxy_vars

        echo "Starting Oracle Net Listener."
        $SU -s /bin/bash $ORACLE_OWNER -c "$LSNR  start $LISTENER_NAME" > /dev/null 2>&1
        RETVAL=$?
        if [ $RETVAL -eq 0 ]
        then
            echo "Oracle Net Listener started."
        fi

        echo "Starting Oracle Database instance $ORACLE_SID."
        $SU -s /bin/bash  $ORACLE_OWNER -c "$SQLPLUS -s /nolog << EOF
                                                                connect / as sysdba
                                                                startup
                                                                alter pluggable database all open
                                                                exit;
                                                                EOF" > /dev/null 2>&1
        RETVAL1=$?
        if [ $RETVAL1 -eq 0 ]
        then
            echo "Oracle Database instance $ORACLE_SID started."
        fi
    else
        echo "The Oracle Database instance $ORACLE_SID is already started."
        exit 0
    fi

    echo
    if [ $RETVAL -eq 0 ] && [ $RETVAL1 -eq 0 ]
    then
        return 0
     else
        echo "Failed to start Oracle Net Listener using $ORACLE_HOME/bin/tnslsnr and Oracle Database using $ORACLE_HOME/bin/sqlplus."
        exit 1
    fi
}

# To stop the DB
stop()
{
    check_for_configuration
    RETVAL=$?
    if [ $RETVAL -eq 1 ]
    then
        echo "The Oracle Database is not configured. You must run '/etc/init.d/oracledb_$ORACLE_SID-$ORACLE_VERSION configure' as the root user to configure the database."
        exit 1
    fi
    # Check if the DB is already stopped
    pmon=ps -ef | egrep pmon_$ORACLE_SID'\>' | $GREP -v grep
    if [ "$pmon" = "" ]
    then
        echo "Oracle Database instance $ORACLE_SID is already stopped."
        exit 1
    else

        # Unset the proxy env vars before calling sqlplus
        unset_proxy_vars

        echo "Shutting down Oracle Database instance $ORACLE_SID."
        $SU -s /bin/bash $ORACLE_OWNER -c "$SQLPLUS -s /nolog << EOF
                                                                connect / as sysdba
                                                                shutdown immediate
                                                                exit;
                                                                EOF" > /dev/null 2>&1
        RETVAL=$?
        if [ $RETVAL -eq 0 ]
        then
            echo "Oracle Database instance $ORACLE_SID shut down."
        fi

        echo "Stopping Oracle Net Listener."
        $SU -s /bin/bash  $ORACLE_OWNER -c "$LSNR stop $LISTENER_NAME" > /dev/null 2>&1
        RETVAL1=$?
        if [ $RETVAL1 -eq 0 ]
        then
            echo "Oracle Net Listener stopped."
        fi
    fi

    echo
    if [ $RETVAL -eq 0 ] && [ $RETVAL1 -eq 0 ]
    then
        return 0
    else
        echo "Failed to stop Oracle Net Listener using $ORACLE_HOME/bin/tnslsnr and Oracle Database using $ORACLE_HOME/bin/sqlplus."
        exit 1
    fi
}

# To call DBCA to configure the DB
configure_perform()
{
    # Unset the proxy env vars before calling dbca
    unset_proxy_vars

    echo "Configuring Oracle Database $ORACLE_SID."

    # Add the -J-Doracle.assistants.dbca.validate.ConfigurationParams=false to bypass the memory validation error
    $SU -s /bin/bash  $ORACLE_OWNER -c "$DBCA -silent -createDatabase -gdbName $ORACLE_SID -templateName $TEMPLATE_NAME -characterSet $CHARSET -createAsContainerDatabase $CREATE_AS_CDB -numberOfPDBs $NUMBER_OF_PDBS -pdbName $PDB_NAME -createListener $LISTENER_NAME:$LISTENER_PORT -datafileDestination $ORACLE_DATA_LOCATION -sid $ORACLE_SID -autoGeneratePasswords -emConfiguration DBEXPRESS -emExpressPort $EM_EXPRESS_PORT -J-Doracle.assistants.dbca.validate.ConfigurationParams=false"

    RETVAL=$?

    echo
    if [ $RETVAL -eq 0 ]
    then
        echo "Database configuration completed successfully. The passwords were auto generated, you must change them by connecting to the database using 'sqlplus / as sysdba' as the oracle user."
        return 0
    else
        echo "Database configuration failed."
        exit 1
    fi
}

# Enh 27965939 - Unsets the proxy env variables
unset_proxy_vars()
{
    if [ "$http_proxy" != "" ]
    then
        unset http_proxy
    fi

    if [ "$HTTP_PROXY" != "" ]
    then
        unset HTTP_PROXY
    fi

    if [ "$https_proxy" != "" ]
    then
        unset https_proxy
    fi

    if [ "$HTTPS_PROXY" != "" ]
    then
        unset HTTPS_PROXY
    fi
}

# Check if the DB is already configured
check_for_configuration()
{
    configfile=$GREP --no-messages $ORACLE_SID:$ORACLE_HOME /etc/oratab > /dev/null 2>&1
    if [ "$configfile" = "" ]
    then
        return 1
    fi
    return 0
}

read_config_file()
{
    if [ -f "$CONFIGURATION" ]
    then
        . "$CONFIGURATION"
    else
        echo "The Oracle Database is not configured. Unable to read the configuration file '$CONFIGURATION'"
        exit 1;
    fi
}

# Entry point to configure the DB
configure()
{
    check_for_configuration
    RETVAL=$?
    if [ $RETVAL -eq 0 ]
    then
        echo "Oracle Database instance $ORACLE_SID is already configured."
        exit 1
    fi
    read_config_file
    check_port_availability
    check_em_express_port_availability
    configure_perform
}

check_port_availability()
{
    port=netstat -n --tcp --listen | $GREP :$LISTENER_PORT
    if [ "$port" != "" ]
    then
        echo "Port $LISTENER_PORT appears to be in use by another application. Specify a different port in the configuration file."
        exit 1
    fi
}

check_em_express_port_availability()
{
    port=netstat -n --tcp --listen | $GREP :$EM_EXPRESS_PORT
    if [ "$port" != "" ]
    then
        echo "Port $EM_EXPRESS_PORT appears to be in use by another application. Specify a different port in the configuration file."
        exit 1
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    configure)
        configure
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|configure}"
        exit 1
esac
```
Esto es porque por defecto el contenido del script del fichero configure me daba problemas, por lo que con estas modificaciones me funciona correctamente.

Ahora, ya solo nos queda ejecutar el comando de la instalación y esperar. Este proceso puede tardar varios minutos.
```bash
pablo@oracle-server:~$ sudo /etc/init.d/oracledb_ORCLCDB-19c configure
/etc/init.d/oracledb_ORCLCDB-19c: línea 243: -n: orden no encontrada
/etc/init.d/oracledb_ORCLCDB-19c: línea 253: -n: orden no encontrada
Configuring Oracle Database ORCLCDB.
Preparar para funcionamiento de base de datos
8% finalizado
Copiando archivos de base de datos
31% finalizado
Creando e iniciando instancia Oracle
32% finalizado
36% finalizado
40% finalizado
43% finalizado
46% finalizado
Terminando creación de base de datos
51% finalizado
54% finalizado
Creando Bases de Datos de Conexión
58% finalizado
77% finalizado
Ejecutando acciones posteriores a la configuración
100% finalizado
Creación de la base de datos terminada. Consulte los archivos log de /opt/oracle/cfgtoollogs/dbca/ORCLCDB
 para obtener más información.
Información de Base de Datos:
Nombre de la Base de Datos Global:ORCLCDB
Identificador del Sistema (SID):ORCLCDB
Para obtener información detallada, consulte el archivo log "/opt/oracle/cfgtoollogs/dbca/ORCLCDB/ORCLCDB.log".

Database configuration completed successfully. The passwords were auto generated, you must change them by connecting to the database using 'sqlplus / as sysdba' as the oracle user.
```

## Configuración

Al finalizar la ejecución del script de configuración de Oracle Database, se indica que la base de datos ha sido configurada exitosamente. Sin embargo, antes de poder usar Oracle como el usuario oracle, es necesario configurar las variables de entorno adecuadas para garantizar que el sistema pueda encontrar las herramientas y archivos correctos de Oracle. Estas variables definen el entorno en el que Oracle se ejecuta, y se deben configurar correctamente para que los comandos de Oracle funcionen sin problemas. Por lo tanto, nos cambiamos al usuario `oracle` y en el fichero `~/.bashrc` añadimos las variables al final:

```bash
pablo@oracle-server:~$ sudo su - oracle
oracle@oracle-server:~$ tail -6 ~/.bashrc 
#Oracle environments
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export ORACLE_SID=ORCLCDB
export ORACLE_BASE=/opt/oracle
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
oracle@oracle-server:~$ source ~/.bashrc
```

Una vez que hemos añadido las variables de entorno necesarias en el archivo .bashrc del usuario oracle y hemos recargado dicho archivo, las herramientas de Oracle deberían estar completamente configuradas para su uso. Esto nos permite acceder a la base de datos utilizando comandos como sqlplus, que es la herramienta de línea de comandos de Oracle para interactuar con la base de datos.

```bash
oracle@oracle-server:~$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Nov 19 13:33:37 2024
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL>
```

💡 Tip: El comando `rlwrap` es una herramienta muy útil que mejora la experiencia de uso de programas de línea de comandos que no tienen soporte nativo para edición de texto o historial de comandos. En el contexto de Oracle y herramientas como SQL*Plus, rlwrap puede ser un gran aliado al proporcionar características de edición y autocompletado que, de otra manera, no estarían disponibles.

Primero de todo lo instalamos:

```bash
oracle@oracle-server:~$ sudo apt install rlwrap
```

Para aprovechar la funcionalidad de rlwrap de manera automática cada vez que iniciemos SQL*Plus, podemos añadir el comando rlwrap a las variables de entorno del usuario oracle. Esto hará que SQL*Plus siempre se ejecute con las ventajas de rlwrap, sin tener que escribir el comando completo cada vez. Por lo tanto, en el `~/.bashrc` añadimos la siguiente línea:

```bash
alias sqlplus='rlwrap sqlplus'
```

Recargamos:

```bash
oracle@oracle-server:~$ source ~/.bashrc
```

Y ahora cada vez que accedamos a la terminal de sqlplus lo tendremos a modo terminal, donde podremos recuperar comandos, hacer Ctrl + l, etc.

**Añadir usuario principal**

En el proceso de configuración de la base de datos Oracle, hemos visto que podemos acceder a la base de datos desde el usuario oracle, dado que previamente le otorgamos los permisos necesarios. Sin embargo, generalmente no vamos a querer realizar todas las tareas administrativas directamente desde el usuario oracle, ya que este es un usuario dedicado principalmente a gestionar Oracle, y preferimos usar nuestro propio usuario principal para interactuar con el sistema, a menos que se nos indique lo contrario.

Para poder administrar la base de datos desde nuestro usuario principal, necesitamos agregarlo al grupo dba que creamos anteriormente. Esto nos permitirá tener acceso a las herramientas y permisos necesarios para gestionar Oracle como si fuéramos administradores, sin tener que cambiar de usuario constantemente.

Además, debemos asegurarnos de que las variables de entorno relacionadas con Oracle estén configuradas correctamente en nuestro usuario principal, de manera que podamos acceder a las herramientas de Oracle (como SQL*Plus) y ejecutar comandos administrativos desde nuestro propio entorno de usuario.

```bash
pablo@oracle-server:~$ sudo usermod -a -G dba pablo
[sudo] contraseña para pablo: 
pablo@oracle-server:~$ sudo nano ~/.bashrc
pablo@oracle-server:~$ source ~/.bashrc
pablo@oracle-server:~$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Nov 19 13:49:52 2024
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> 
```

## Creación de un usuario en Oracle 19c

Al trabajar con Oracle Database, una de las tareas más comunes es la creación de usuarios. Sin embargo, en algunas configuraciones recientes, como la que estamos utilizando en Oracle 19c, puede surgir un error relacionado con el parámetro _ORACLE_SCRIPT. Aquí te explicamos cómo crear un usuario y cómo resolver este problema si aparece.

**Creación de un usuario en Oracle**

Para crear un usuario en Oracle Database, seguimos estos pasos:

Accedemos a la base de datos con privilegios de administrador utilizando SQL*Plus:

```
pablo@oracle-server:~$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Nov 19 13:58:52 2024
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0
```

Y creamos el nuevo usuario:
```sql
SQL> CREATE USER pablo IDENTIFIED BY password;
CREATE USER pablo IDENTIFIED BY password
            *
ERROR en linea 1:
ORA-65096: nombre de usuario o rol comun no valido
```

Pero como podemos ver nos ha dado error. Este error ocurre porque Oracle 12c y versiones posteriores introdujeron el concepto de **bases de datos multitenant**, donde una única instancia puede contener múltiples bases de datos "pluggable" (PDB). De forma predeterminada, Oracle espera que los nombres de usuario sigan ciertas convenciones especiales para usuarios "comunes" que se compartan entre las bases de datos contenedoras (CDB) y las bases de datos pluggable (PDB).

Si no estamos configurando un usuario común, sino uno específico para nuestra base de datos pluggable, necesitamos desactivar temporalmente esta restricción.

Para solucionarlo tendremos que ejecutar el siguiente comando:

```sql
ALTER SESSION SET "_ORACLE_SCRIPT"=TRUE;
```

Y ya nos dejará crear el usuario sin problemas:

```sql
SQL> ALTER SESSION SET "_ORACLE_SCRIPT"=TRUE;

Sesion modificada.

SQL> CREATE USER pablo IDENTIFIED BY password;

Usuario creado.
```

Le damos permisos para conectarnos:

```sql
SQL> GRANT CONNECT, RESOURCE TO pablo;

Concesion terminada correctamente.
```

Y probamos a conectarnos con el nuevo usuario:

```sql
pablo@oracle-server:~$ sqlplus pablo/password

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Nov 19 14:05:34 2024
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL>
```

Con esto concluimos la instalación y configuración de Oracle Database 19c sobre una máquina virtual con Debian 12, utilizando QEMU/KVM como hipervisor. A lo largo de este proceso, hemos cubierto todos los aspectos necesarios para poner en marcha la base de datos, desde la configuración inicial del sistema operativo hasta los pasos específicos para preparar y personalizar el entorno de Oracle. 

Hemos abordado detalles importantes como la instalación de dependencias, la creación de usuarios y grupos, la gestión de variables de entorno y la resolución de errores comunes. Además, vimos cómo realizar tareas básicas de administración, como el acceso a SQL*Plus, la adición de usuarios y el uso de herramientas útiles como rlwrap para mejorar la experiencia en la línea de comandos.