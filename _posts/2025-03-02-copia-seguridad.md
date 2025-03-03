---
title: "Copias de Seguridad y Restauración"
date: 2025-03-02 23:35:00 +0000
categories: [Base de Datos, Administración y Seguridad de Bases de Datos]
tags: [Administración y Seguridad de Bases de Datos]
author: pablo
description: "Garantizar la integridad y disponibilidad de los datos es clave en cualquier sistema. En esta práctica, se explorarán copias de seguridad lógicas y físicas en Oracle, PostgreSQL, MySQL y MongoDB, aplicando compresión, cifrado y segmentación. También se abordará la recuperación ante desastres mediante la restauración de ficheros de datos y control, incluyendo el uso de RMAN en entornos con ArchiveLog habilitado."
toc: true
comments: true
image:
  path: /assets/img/posts/copiaseg/portadita.jpg
---

## Ejercicio 1

Realiza una copia de seguridad lógica de tu base de datos completa, teniendo en cuenta los siguientes requisitos:

- La copia debe estar encriptada y comprimida.
- Debe realizarse en un conjunto de ficheros con un tamaño máximo de 75 MB.
- Programa la operación para que se repita cada día a una hora determinada.

Lo primero que debemos hacer es crear un usuario que tenga los privilegios necesarios para ejecutar la copia de seguridad. En este caso, vamos a crear el usuario `pavlo` y otorgarle el privilegio de DBA para que pueda acceder a todas las funciones necesarias para realizar la copia.

Ingresamos a Oracle como usuario administrador y creamos el usuario pavlo:
```sql
oracle@oracle19c:~$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sun Mar 2 19:10:10 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> ALTER SESSION SET "_ORACLE_SCRIPT"=true;

Sesion modificada.

SQL> CREATE USER pavlo IDENTIFIED BY password;

Usuario creado.
```

Luego, asignamos los privilegios necesarios para que pavlo pueda realizar copias de seguridad. En este caso, le otorgamos el privilegio DBA, que le permitirá acceder a todas las funciones necesarias para la administración de la base de datos, incluida la exportación de datos:
```sql
SQL> GRANT DBA TO pavlo;

Concesion terminada correctamente.
```

Esto concede a `pavlo` los privilegios necesarios para ejecutar las copias de seguridad.

A continuación, vamos a crear un directorio en el sistema de archivos donde almacenaremos las copias de seguridad. En este caso, lo creamos en `/opt/oracle/copias`:

Creamos el directorio en el sistema operativo:
```bash
oracle@oracle19c:~$ sudo mkdir /opt/oracle/copias
```

Luego, cambiamos la propiedad de este directorio para que el usuario de Oracle (y en este caso pavlo, que necesitará acceso) pueda utilizarlo:
```bash
oracle@oracle19c:~$ sudo chown oracle:oinstall /opt/oracle/copias/
```

Seguidamente, creamos un directorio lógico con el nombre COPIAS que apuntará a la ubicación física que hemos creado en el sistema:
```sql
SQL> CREATE DIRECTORY COPIAS AS '/opt/oracle/copias/';

Directorio creado.
```

Por último, le otorgamos permisos de lectura y escritura al usuario pavlo sobre este directorio:
```sql
SQL> GRANT READ, WRITE ON DIRECTORY COPIAS TO pavlo;

Concesion terminada correctamente.
```

Para automatizar la tarea de hacer la copia de seguridad, vamos a crear un servicio de systemd que ejecutará el comando para exportar la base de datos en el formato deseado. En este servicio, especificamos que la exportación se debe realizar con encriptación, compresión y fragmentación de los archivos en bloques de 75 MB.

Creamos un archivo de servicio de systemd para definir cómo debe ejecutarse la copia, donde el contenido de este archivo será el siguiente, donde indicamos que el comando de exportación debe ser ejecutado cuando se active el servicio:
```bash
oracle@oracle19c:~$ sudo cat /etc/systemd/system/copia.service 
[Unit]
Description=Oracle Copias

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'expdp pavlo/password DIRECTORY=COPIAS DUMPFILE=copia_$(date +"%Y%m%d%H%M%S").dmp LOGFILE=copia_$(date +"%Y%m%d%H%M%S").log ENCRYPTION_PASSWORD=PAVLO COMPRESSION=ALL FULL=Y FILESIZE=75M'

[Install]
WantedBy=multi-user.target
```

En este archivo, la clave `ENCRYPTION_PASSWORD=PAVLO` se utiliza para encriptar la copia de seguridad. La opción `COMPRESSION=ALL` asegura que la copia se comprima, y `FILESIZE=75M` limita el tamaño de cada archivo de copia a 75 MB.

Ahora que tenemos el servicio listo, necesitamos programar su ejecución diaria a una hora específica. Para ello, creamos un temporizador de systemd que ejecutará el servicio todos los días a las 19:45.
```bash
oracle@oracle19c:~$ sudo cat /etc/systemd/system/copia.timer
[Unit]
Description=Oracle Copias Temporizador

[Timer]
OnCalendar=*-*-* 19:45:00
Persistent=true

[Install]
WantedBy=timers.target
```

Aquí, `OnCalendar=*-*-* 19:45:00` establece que la copia de seguridad se debe realizar todos los días a las 19:45. La opción `Persistent=true` asegura que, si el sistema está apagado en el momento de la ejecución programada, la tarea se ejecutará tan pronto como el sistema se reinicie.

Una vez que hemos creado el archivo de servicio y el temporizador, necesitamos recargar la configuración de systemd, habilitar el temporizador para que se inicie automáticamente al arrancar el sistema, y arrancar el temporizador para que empiece a funcionar.

Recargamos systemd para que reconozca los nuevos archivos de configuración:
```bash
oracle@oracle19c:~$ sudo systemctl daemon-reload
```

Habilitamos el temporizador para que se ejecute automáticamente al iniciar el sistema:
```bash
oracle@oracle19c:~$ sudo systemctl enable copia.timer
Created symlink /etc/systemd/system/timers.target.wants/copia.timer → /etc/systemd/system/copia.timer.
```

Finalmente, iniciamos el temporizador para que comience a ejecutarse:
```bash
oracle@oracle19c:~$ sudo systemctl start copia.timer
```

Entonces, llegada la hora, se realizará la copia y se guardará en el directorio indicado con su respectiva fecha y hora. Podemos ver el log de la copia:

![image](/assets/img/posts/copiaseg/image1.png)

## Ejercicio 2

Restaura la copia de seguridad lógica creada en el punto anterior.

Para la prueba he eliminado las tablas del esquema scott:

```sql
SQL> CONNECT scott/tiger
Conectado.
SQL> SELECT * FROM dept;
SELECT * FROM dept
              *
ERROR en linea 1:
ORA-00942: la tabla o vista no existe


SQL> SELECT * FROM emp;
SELECT * FROM emp
              *
ERROR en linea 1:
ORA-00942: la tabla o vista no existe
```

Vamos a llevar a cabo la restauración de la copia de seguridad utilizando el siguiente comando. Especificamos el directorio, el archivo dump de la copia que queremos restaurar, y también indicamos el archivo de registro (log) que se generará, el cual se guardará en el mismo directorio donde se realiza la restauración.

```bash
oracle@oracle19c:~$ impdp pavlo/password directory=COPIAS dumpfile=copia_20250302194500.dmp encryption_password=PAVLO full=y logfile=restauracion_$(date +"%Y%m%d%H%M%S").log
```

Si accedemos al archivo de registro (log) de la restauración de la copia y filtramos por el término "SCOTT", podemos observar que las tablas y los datos del esquema han sido importados correctamente, ya que previamente habíamos eliminado ese esquema. 
```bash
oracle@oracle19c:~$ ls -lh /opt/oracle/copias/
total 1,9M
-rw-r----- 1 oracle oinstall 1,9M mar  2 19:46 copia_20250302194500.dmp
-rw-r--r-- 1 oracle oinstall  18K mar  2 19:46 copia_20250302194500.log
-rw-r--r-- 1 oracle oinstall  32K mar  2 20:01 restauracion_20250302200022.log
oracle@oracle19c:~$ cat /opt/oracle/copias/restauracion_20250302200022.log | grep SCOTT
ORA-39151: La tabla "SCOTT"."EMPLOYEES" existe. Todos los metadados dependientes y los datos se omitirán debido table_exists_action de omitir
ORA-39151: La tabla "SCOTT"."EMP_VIEW" existe. Todos los metadados dependientes y los datos se omitirán debido table_exists_action de omitir
ORA-39151: La tabla "SCOTT"."DEPT_VIEW" existe. Todos los metadados dependientes y los datos se omitirán debido table_exists_action de omitir
. . "SCOTT"."EMP"                               5.695 KB      16 filas importadas
. . "SCOTT"."DEPT"                                  5 KB       4 filas importadas
. . "SCOTT"."SALGRADE"                              5 KB       5 filas importadas
. . "SCOTT"."BONUS"                             4.929 KB      14 filas importadas
```

Al restaurar la copia de seguridad, podemos ver que las tablas y los datos se recuperan correctamente, volviendo a estar presentes tal como estaban antes de la eliminación. 

![image](/assets/img/posts/copiaseg/image2.png)

## Ejercicio 3

Pon tu base de datos en modo ArchiveLog y realiza con RMAN una copia de seguridad física en caliente.

El modo `ARCHIVELOG` de Oracle es un mecanismo de protección ante fallos del disco que permite realizar copias de seguridad en caliente. Para activar el modo archivelog reiniciamos la base de datos para montarla directamente en la instancia sin abrirla, si no no nos dejará:
```sql
oracle@oracle19c:~$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sun Mar 2 20:44:34 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> shutdown immediate;
Base de datos cerrada.
Base de datos desmontada.
Instancia ORACLE cerrada.
SQL> startup mount;
ORA-32004: obsolete or deprecated parameter(s) specified for RDBMS instance
Instancia ORACLE iniciada.

Total System Global Area 1644164456 bytes
Fixed Size		    9135464 bytes
Variable Size		 1275068416 bytes
Database Buffers	  352321536 bytes
Redo Buffers		    7639040 bytes
Base de datos montada.
```

También cambiamos el tipo de base de datos:
```sql
SQL> alter database archivelog;

Base de datos modificada.

SQL> alter database open;

Base de datos modificada.
```

Cuando ya tengamos la base de datos en ArchiveLog, lo comprobamos ejecutando esta consulta:
```sql
SQL> SELECT log_mode 
  2  FROM V$DATABASE;

LOG_MODE
------------
ARCHIVELOG
```

También podemos comprobar el estado con el siguiente comando:
```sql
SQL> ARCHIVE LOG LIST;
Modo log de la base de datos		  Modo de Archivado
Archivado automatico		 Activado
Destino del archivo	       /opt/oracle/product/19c/dbhome_1/dbs/arch
Secuencia de log en linea mas antigua	  17
Siguiente secuencia de log para archivar   19
Secuencia de log actual 	  19
```

Tras esto, accederemos como superusuario y crearemos un usuario para la copia de seguridad respectiva.
```sql
SQL> CREATE USER RMAN IDENTIFIED BY RMAN;

Usuario creado.

SQL> GRANT CONNECT, RESOURCE TO RMAN;

Concesion terminada correctamente.

SQL> GRANT RECOVERY_CATALOG_OWNER TO RMAN;

Concesion terminada correctamente.
```

Seguidamente, creamos un tablespace para el usuario RMAN que acabamos de crear:
```sql
SQL> CREATE TABLESPACE TS_RMAN DATAFILE '/opt/oracle/oradata/ORCLCDB/ts_rman.dbf' SIZE 300M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

Tablespace creado.

SQL> ALTER USER RMAN DEFAULT TABLESPACE TS_RMAN QUOTA UNLIMITED ON TS_RMAN;

Usuario modificado.
```

Ahora pasamos a la configuración de rman, donde tendremos que conectarnos a la base de datos mediante el usuario que creamos antes:
```sql
oracle@oracle19c:~$ rman

Recovery Manager: Release 19.0.0.0.0 - Production on Sun Mar 2 20:52:49 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

RMAN> CONNECT CATALOG RMAN/RMAN    

connected to recovery catalog database
```

Una vez dentro, tendremos que crear el catálogo en base al tablespace que hemos creado anteriormente. Para ello ejecutamos el siguiente comando:
```sql
RMAN> CREATE CATALOG TABLESPACE TS_RMAN;

recovery catalog created
```

De esta forma ya lo habremos configurado para poder conectarnos al catálogo RMAN. Nos conectamos a partir del siguiente comando:
```sql
oracle@oracle19c:~$ rman target =/ catalog RMAN/RMAN

Recovery Manager: Release 19.0.0.0.0 - Production on Sun Mar 2 20:57:00 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

connected to target database: ORCLCDB (DBID=2956261615)
connected to recovery catalog database

RMAN> REGISTER DATABASE;

database registered in recovery catalog
starting full resync of recovery catalog
full resync complete
```

Ya estamos registrados correctamente con el usuario RMAN, por lo que podemos pasar a crear la copia de seguridad en caliente:
```sql
oracle@oracle19c:~$ rman target =/ catalog RMAN/RMAN

Recovery Manager: Release 19.0.0.0.0 - Production on Sun Mar 2 20:57:00 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

connected to target database: ORCLCDB (DBID=2956261615)
connected to recovery catalog database

RMAN> REGISTER DATABASE;

database registered in recovery catalog
starting full resync of recovery catalog
full resync complete

RMAN> BACKUP DATABASE PLUS ARCHIVELOG;  


Starting backup at 02-MAR-25
current log archived
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=19 device type=DISK
channel ORA_DISK_1: starting archived log backup set
channel ORA_DISK_1: specifying archived log(s) in backup set
input archived log thread=1 sequence=19 RECID=1 STAMP=1194728348
channel ORA_DISK_1: starting piece 1 at 02-MAR-25
channel ORA_DISK_1: finished piece 1 at 02-MAR-25
piece handle=/opt/oracle/product/19c/dbhome_1/dbs/013jc6ss_1_1 tag=TAG20250302T205908 comment=NONE
channel ORA_DISK_1: backup set complete, elapsed time: 00:00:01
Finished backup at 02-MAR-25

Starting backup at 02-MAR-25
using channel ORA_DISK_1
channel ORA_DISK_1: starting full datafile backup set
channel ORA_DISK_1: specifying datafile(s) in backup set
input datafile file number=00001 name=/opt/oracle/oradata/ORCLCDB/system01.dbf
input datafile file number=00003 name=/opt/oracle/oradata/ORCLCDB/sysaux01.dbf
input datafile file number=00004 name=/opt/oracle/oradata/ORCLCDB/undotbs01.dbf
input datafile file number=00013 name=/opt/oracle/oradata/ORCLCDB/ts_rman.dbf
input datafile file number=00007 name=/opt/oracle/oradata/ORCLCDB/users01.dbf
channel ORA_DISK_1: starting piece 1 at 02-MAR-25
channel ORA_DISK_1: finished piece 1 at 02-MAR-25
piece handle=/opt/oracle/product/19c/dbhome_1/dbs/023jc6su_1_1 tag=TAG20250302T205910 comment=NONE
channel ORA_DISK_1: backup set complete, elapsed time: 00:00:07
channel ORA_DISK_1: starting full datafile backup set
channel ORA_DISK_1: specifying datafile(s) in backup set
input datafile file number=00010 name=/opt/oracle/oradata/ORCLCDB/ORCLPDB1/sysaux01.dbf
input datafile file number=00009 name=/opt/oracle/oradata/ORCLCDB/ORCLPDB1/system01.dbf
input datafile file number=00011 name=/opt/oracle/oradata/ORCLCDB/ORCLPDB1/undotbs01.dbf
input datafile file number=00012 name=/opt/oracle/oradata/ORCLCDB/ORCLPDB1/users01.dbf
channel ORA_DISK_1: starting piece 1 at 02-MAR-25
channel ORA_DISK_1: finished piece 1 at 02-MAR-25
piece handle=/opt/oracle/product/19c/dbhome_1/dbs/033jc6t5_1_1 tag=TAG20250302T205910 comment=NONE
channel ORA_DISK_1: backup set complete, elapsed time: 00:00:25
channel ORA_DISK_1: starting full datafile backup set
channel ORA_DISK_1: specifying datafile(s) in backup set
input datafile file number=00006 name=/opt/oracle/oradata/ORCLCDB/pdbseed/sysaux01.dbf
input datafile file number=00005 name=/opt/oracle/oradata/ORCLCDB/pdbseed/system01.dbf
input datafile file number=00008 name=/opt/oracle/oradata/ORCLCDB/pdbseed/undotbs01.dbf
channel ORA_DISK_1: starting piece 1 at 02-MAR-25
channel ORA_DISK_1: finished piece 1 at 02-MAR-25
piece handle=/opt/oracle/product/19c/dbhome_1/dbs/043jc6tu_1_1 tag=TAG20250302T205910 comment=NONE
channel ORA_DISK_1: backup set complete, elapsed time: 00:00:25
Finished backup at 02-MAR-25

Starting backup at 02-MAR-25
current log archived
using channel ORA_DISK_1
channel ORA_DISK_1: starting archived log backup set
channel ORA_DISK_1: specifying archived log(s) in backup set
input archived log thread=1 sequence=20 RECID=2 STAMP=1194728407
channel ORA_DISK_1: starting piece 1 at 02-MAR-25
channel ORA_DISK_1: finished piece 1 at 02-MAR-25
piece handle=/opt/oracle/product/19c/dbhome_1/dbs/053jc6uo_1_1 tag=TAG20250302T210008 comment=NONE
channel ORA_DISK_1: backup set complete, elapsed time: 00:00:01
Finished backup at 02-MAR-25

Starting Control File and SPFILE Autobackup at 02-MAR-25
piece handle=/opt/oracle/product/19c/dbhome_1/dbs/c-2956261615-20250302-00 comment=NONE
Finished Control File and SPFILE Autobackup at 02-MAR-25
```

Verificamos que la copia de seguridad se haya realizado correctamente con el siguiente comando:
```sql
RMAN> RESTORE DATABASE PREVIEW;

Starting restore at 02-MAR-25
using channel ORA_DISK_1


List of Backup Sets
===================


BS Key  Type LV Size       Device Type Elapsed Time Completion Time
------- ---- -- ---------- ----------- ------------ ---------------
95      Full    1.25G      DISK        00:00:05     02-MAR-25      
        BP Key: 99   Status: AVAILABLE  Compressed: NO  Tag: TAG20250302T205910
        Piece Name: /opt/oracle/product/19c/dbhome_1/dbs/023jc6su_1_1
  List of Datafiles in backup set 95
  File LV Type Ckp SCN    Ckp Time  Abs Fuz SCN Sparse Name
  ---- -- ---- ---------- --------- ----------- ------ ----
  1       Full 3803434    02-MAR-25              NO    /opt/oracle/oradata/ORCLCDB/system01.dbf
  3       Full 3803434    02-MAR-25              NO    /opt/oracle/oradata/ORCLCDB/sysaux01.dbf
  4       Full 3803434    02-MAR-25              NO    /opt/oracle/oradata/ORCLCDB/undotbs01.dbf
  7       Full 3803434    02-MAR-25              NO    /opt/oracle/oradata/ORCLCDB/users01.dbf
  13      Full 3803434    02-MAR-25              NO    /opt/oracle/oradata/ORCLCDB/ts_rman.dbf

BS Key  Type LV Size       Device Type Elapsed Time Completion Time
------- ---- -- ---------- ----------- ------------ ---------------
97      Full    554.47M    DISK        00:00:09     02-MAR-25      
        BP Key: 101   Status: AVAILABLE  Compressed: NO  Tag: TAG20250302T205910
        Piece Name: /opt/oracle/product/19c/dbhome_1/dbs/043jc6tu_1_1
  List of Datafiles in backup set 97
  Container ID: 2, PDB Name: PDB$SEED
  File LV Type Ckp SCN    Ckp Time  Abs Fuz SCN Sparse Name
  ---- -- ---- ---------- --------- ----------- ------ ----
  5       Full 2147831    16-NOV-24              NO    /opt/oracle/oradata/ORCLCDB/pdbseed/system01.dbf
  6       Full 2147831    16-NOV-24              NO    /opt/oracle/oradata/ORCLCDB/pdbseed/sysaux01.dbf
  8       Full 2147831    16-NOV-24              NO    /opt/oracle/oradata/ORCLCDB/pdbseed/undotbs01.dbf

BS Key  Type LV Size       Device Type Elapsed Time Completion Time
------- ---- -- ---------- ----------- ------------ ---------------
96      Full    473.57M    DISK        00:00:07     02-MAR-25      
        BP Key: 100   Status: AVAILABLE  Compressed: NO  Tag: TAG20250302T205910
        Piece Name: /opt/oracle/product/19c/dbhome_1/dbs/033jc6t5_1_1
  List of Datafiles in backup set 96
  Container ID: 3, PDB Name: ORCLPDB1
  File LV Type Ckp SCN    Ckp Time  Abs Fuz SCN Sparse Name
  ---- -- ---- ---------- --------- ----------- ------ ----
  9       Full 3117873    20-JAN-25              NO    /opt/oracle/oradata/ORCLCDB/ORCLPDB1/system01.dbf
  10      Full 3117873    20-JAN-25              NO    /opt/oracle/oradata/ORCLCDB/ORCLPDB1/sysaux01.dbf
  11      Full 3117873    20-JAN-25              NO    /opt/oracle/oradata/ORCLCDB/ORCLPDB1/undotbs01.dbf
  12      Full 3117873    20-JAN-25              NO    /opt/oracle/oradata/ORCLCDB/ORCLPDB1/users01.dbf

List of Archived Log Copies for database with db_unique_name ORCLCDB
=====================================================================

Key     Thrd Seq     S Low Time 
------- ---- ------- - ---------
94      1    20      A 02-MAR-25
        Name: /opt/oracle/product/19c/dbhome_1/dbs/arch1_20_1185200241.dbf

recovery will be done up to SCN 3803434
Media recovery start SCN is 3803434
Recovery must be done beyond SCN 3803434 to clear datafile fuzziness
Finished restore at 02-MAR-25
```

De esta forma hemos configurado la base de datos en modo ArchiveLog y realizado una copia de seguridad en caliente con RMAN. 

## Ejercicio 4

Borra un fichero de datos de un tablespace e intenta recuperar la instancia de la base de datos a partir de la copia de seguridad creada en el punto anterior.

Para restaurar un archivo de un tablespace en la base de datos, eliminaré un archivo del tablespace `USERS`. Para hacerlo, necesitamos conectarnos a la base de datos con privilegios de SYSDBA.

Una vez dentro, podemos ver todos los tablespaces de la base de datos con esta consulta:

```sql
SQL> SELECT TABLESPACE_NAME 
  2  FROM DBA_TABLESPACES;

TABLESPACE_NAME
------------------------------
SYSTEM
SYSAUX
UNDOTBS1
TEMP
USERS
TS_RMAN

6 filas seleccionadas.
```

Después, para ver los archivos asociados a los tablespaces, usamos esta otra consulta:

```sql
SQL> SELECT FILE_NAME 
  2  FROM DBA_DATA_FILES;

FILE_NAME
--------------------------------------------------------------------------------
/opt/oracle/oradata/ORCLCDB/system01.dbf
/opt/oracle/oradata/ORCLCDB/sysaux01.dbf
/opt/oracle/oradata/ORCLCDB/undotbs01.dbf
/opt/oracle/oradata/ORCLCDB/users01.dbf
/opt/oracle/oradata/ORCLCDB/ts_rman.dbf
```

Después de revisar la información de los tablespaces y sus archivos, procedemos a eliminar el tablespace USERS. Antes de hacerlo, realizamos una copia de seguridad del archivo `users01.dbf` en un directorio destinado a las copias de seguridad, asegurándonos de poder restaurarlo en caso de ser necesario.

Primero, creamos el directorio donde guardaremos la copia:
```bash
oracle@oracle19c:~$ mkdir rman_copia
```

Luego, copiamos el archivo users01.dbf al directorio recién creado:
```bash
oracle@oracle19c:~$ sudo cp /opt/oracle/oradata/ORCLCDB/users01.dbf rman_copia/
```

Una vez hecho el respaldo, eliminamos el archivo original:
```bash
oracle@oracle19c:~$ sudo rm /opt/oracle/oradata/ORCLCDB/users01.dbf
```

Para confirmar que el archivo se eliminó correctamente, verificamos el contenido del directorio donde estaba almacenado con el siguiente comando:
```bash
oracle@oracle19c:~$ sudo ls -lh /opt/oracle/oradata/ORCLCDB/  
total 2,8G
-rw-r----- 1 oracle oinstall  18M mar  2 21:54 control01.ctl
-rw-r----- 1 oracle oinstall  18M mar  2 21:54 control02.ctl
drwxr-x--- 2 oracle dba      4,0K nov 16 14:28 ORCLPDB1
drwxr-x--- 2 oracle dba      4,0K nov 16 14:20 pdbseed
-rw-r----- 1 oracle oinstall 201M mar  2 20:59 redo01.log
-rw-r----- 1 oracle oinstall 201M mar  2 21:00 redo02.log
-rw-r----- 1 oracle oinstall 201M mar  2 21:53 redo03.log
-rw-r----- 1 oracle oinstall 591M mar  2 21:52 sysaux01.dbf
-rw-r----- 1 oracle oinstall 941M mar  2 21:50 system01.dbf
-rw-r----- 1 oracle oinstall  33M mar  2 20:01 temp01.dbf
-rw-r----- 1 oracle oinstall 301M mar  2 21:05 ts_rman.dbf
-rw-r----- 1 oracle oinstall 341M mar  2 21:50 undotbs01.dbf
```

Para verificar si los datos se han eliminado correctamente, nos conectamos nuevamente a la base de datos con privilegios de SYSDBA y realizamos una consulta para comprobar si las tablas del usuario scott siguen existiendo.

Accedemos como SYSDBA e intentamos consultar los datos de las tablas mencionadas:
```sql
SQL> SELECT * FROM scott.dept;
SELECT * FROM scott.dept
                    *
ERROR en linea 1:
ORA-01116: error al abrir el archivo de base de datos 7
ORA-01110: archivo de datos 7: '/opt/oracle/oradata/ORCLCDB/users01.dbf'
ORA-27041: no se ha podido abrir el archivo
Linux-x86_64 Error: 2: No such file or directory
Additional information: 3


SQL> SELECT * FROM scott.emp;
SELECT * FROM scott.emp
                    *
ERROR en linea 1:
ORA-01116: error al abrir el archivo de base de datos 7
ORA-01110: archivo de datos 7: '/opt/oracle/oradata/ORCLCDB/users01.dbf'
ORA-27041: no se ha podido abrir el archivo
Linux-x86_64 Error: 2: No such file or directory
Additional information: 3
```

Al ejecutar estas consultas, observamos que se genera un error indicando que el archivo no se encuentra. Esto confirma que la eliminación previa del archivo `users01.dbf` afectó directamente a estas tablas, ya que la información que contenían estaba almacenada en el tablespace `USERS`.

Después de comprobar que las tablas DEPT y EMP no están accesibles debido a la eliminación del archivo users01.dbf, procedemos a restaurar la base de datos utilizando RMAN y la copia de seguridad previa.

Nos conectamos a RMAN con el siguiente comando:
```sql
oracle@oracle19c:~$ rman target=/ catalog RMAN/RMAN  

Recovery Manager: Release 19.0.0.0.0 - Production on Sun Mar 2 21:59:14 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

connected to target database: ORCLCDB (DBID=2956261615)
connected to recovery catalog database

RMAN>
```

Una vez dentro, verificamos si el archivo eliminado está disponible en la copia de seguridad ejecutando:
```sql
RMAN> list backup of datafile '/opt/oracle/oradata/ORCLCDB/users01.dbf';  


List of Backup Sets
===================


BS Key  Type LV Size       Device Type Elapsed Time Completion Time
------- ---- -- ---------- ----------- ------------ ---------------
95      Full    1.25G      DISK        00:00:05     02-MAR-25      
        BP Key: 99   Status: AVAILABLE  Compressed: NO  Tag: TAG20250302T205910
        Piece Name: /opt/oracle/product/19c/dbhome_1/dbs/023jc6su_1_1
  List of Datafiles in backup set 95
  File LV Type Ckp SCN    Ckp Time  Abs Fuz SCN Sparse Name
  ---- -- ---- ---------- --------- ----------- ------ ----
  7       Full 3803434    02-MAR-25              NO    /opt/oracle/oradata/ORCLCDB/users01.dbf
```

Al ejecutar este comando, vemos que el archivo `users01.dbf` está presente en la copia de seguridad en caliente que realizamos anteriormente. Esto nos confirma que podemos proceder con la restauración para recuperar los datos eliminados.

Para restaurar el archivo users01.dbf que eliminamos, seguimos estos pasos:

Primero, ponemos el tablespace USERS en estado OFFLINE para evitar inconsistencias durante la restauración. Ejecutamos el siguiente comando en RMAN:

```sql
RMAN> SQL "ALTER TABLESPACE USERS OFFLINE IMMEDIATE";  

sql statement: ALTER TABLESPACE USERS OFFLINE IMMEDIATE
```

Una vez que el tablespace está desactivado, procedemos a restaurar el archivo desde la copia de seguridad con el siguiente comando en RMAN:

```sql
RMAN> RESTORE TABLESPACE USERS;  

Starting restore at 02-MAR-25
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=19 device type=DISK

channel ORA_DISK_1: starting datafile backup set restore
channel ORA_DISK_1: specifying datafile(s) to restore from backup set
channel ORA_DISK_1: restoring datafile 00007 to /opt/oracle/oradata/ORCLCDB/users01.dbf
channel ORA_DISK_1: reading from backup piece /opt/oracle/product/19c/dbhome_1/dbs/023jc6su_1_1
channel ORA_DISK_1: piece handle=/opt/oracle/product/19c/dbhome_1/dbs/023jc6su_1_1 tag=TAG20250302T205910
channel ORA_DISK_1: restored backup piece 1
channel ORA_DISK_1: restore complete, elapsed time: 00:00:01
Finished restore at 02-MAR-25
```

Después de la restauración, realizamos la recuperación del tablespace para aplicar los cambios registrados en los archivos de redo logs y dejarlo en un estado consistente:

```sql
RMAN> RECOVER TABLESPACE USERS;

Starting recover at 02-MAR-25
using channel ORA_DISK_1

starting media recovery
media recovery complete, elapsed time: 00:00:00

Finished recover at 02-MAR-25
```

Por último, volvemos a activar el tablespace USERS para que la base de datos pueda acceder nuevamente a los datos almacenados en él:
```sql
RMAN> SQL "ALTER TABLESPACE USERS ONLINE";  

sql statement: ALTER TABLESPACE USERS ONLINE
```

Con esto, el archivo `users01.dbf` ha sido restaurado y ya deberíamos poder acceder a los datos como antes de la eliminación.

Para comprobar que la restauración ha sido exitosa, podemos verificarlo de dos maneras:

Accediendo a la base de datos y ejecutando las consultas previas sobre las tablas `scott.emp` y `scott.dept` para confirmar que devuelven datos correctamente:

![image](/assets/img/posts/copiaseg/image3.png)

Revisando el directorio donde estaba el archivo restaurado con el siguiente comando:
```bash
oracle@oracle19c:~$ sudo ls -lh /opt/oracle/oradata/ORCLCDB/  
total 2,8G
-rw-r----- 1 oracle oinstall  18M mar  2 22:04 control01.ctl
-rw-r----- 1 oracle oinstall  18M mar  2 22:04 control02.ctl
drwxr-x--- 2 oracle dba      4,0K nov 16 14:28 ORCLPDB1
drwxr-x--- 2 oracle dba      4,0K nov 16 14:20 pdbseed
-rw-r----- 1 oracle oinstall 201M mar  2 20:59 redo01.log
-rw-r----- 1 oracle oinstall 201M mar  2 21:00 redo02.log
-rw-r----- 1 oracle oinstall 201M mar  2 22:04 redo03.log
-rw-r----- 1 oracle oinstall 591M mar  2 22:04 sysaux01.dbf
-rw-r----- 1 oracle oinstall 941M mar  2 22:04 system01.dbf
-rw-r----- 1 oracle oinstall  33M mar  2 20:01 temp01.dbf
-rw-r----- 1 oracle oinstall 301M mar  2 22:04 ts_rman.dbf
-rw-r----- 1 oracle oinstall 341M mar  2 22:04 undotbs01.dbf
-rw-r----- 1 oracle oinstall  16M mar  2 22:03 users01.dbf
```

## Ejercicio 5

Borra un fichero de control e intenta recuperar la base de datos a partir de la copia de seguridad creada en el punto anterior.

Para simular la pérdida de un fichero de control y su posterior recuperación utilizando la copia de seguridad de RMAN, seguimos los siguientes pasos:

Primero, eliminamos manualmente el fichero de control con el siguiente comando:
```bash
oracle@oracle19c:~$ sudo rm -rf /opt/oracle/oradata/ORCLCDB/control01.ctl
```

Para confirmar que se ha eliminado correctamente, listamos los archivos en el directorio correspondiente:
```bash
oracle@oracle19c:~$ sudo ls -lh /opt/oracle/oradata/ORCLCDB/  
total 2,8G
-rw-r----- 1 oracle oinstall  18M mar  2 22:24 control02.ctl
drwxr-x--- 2 oracle dba      4,0K nov 16 14:28 ORCLPDB1
drwxr-x--- 2 oracle dba      4,0K nov 16 14:20 pdbseed
-rw-r----- 1 oracle oinstall 201M mar  2 20:59 redo01.log
-rw-r----- 1 oracle oinstall 201M mar  2 21:00 redo02.log
-rw-r----- 1 oracle oinstall 201M mar  2 22:24 redo03.log
-rw-r----- 1 oracle oinstall 591M mar  2 22:24 sysaux01.dbf
-rw-r----- 1 oracle oinstall 941M mar  2 22:20 system01.dbf
-rw-r----- 1 oracle oinstall  33M mar  2 20:01 temp01.dbf
-rw-r----- 1 oracle oinstall 301M mar  2 22:09 ts_rman.dbf
-rw-r----- 1 oracle oinstall 341M mar  2 22:24 undotbs01.dbf
-rw-r----- 1 oracle oinstall  16M mar  2 22:03 users01.dbf
```

A continuación, accedemos a la base de datos como SYSDBA y forzamos su apagado con *shutdown abort*, ya que sin el fichero de control, la base de datos no podrá funcionar correctamente. Luego, la iniciamos en modo nomount:
```sql
oracle@oracle19c:~$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sun Mar 2 22:25:25 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> shutdown abort;
Instancia ORACLE cerrada.
SQL> startup nomount;
ORA-32004: obsolete or deprecated parameter(s) specified for RDBMS instance
Instancia ORACLE iniciada.

Total System Global Area 1644164456 bytes
Fixed Size		    9135464 bytes
Variable Size		 1275068416 bytes
Database Buffers	  352321536 bytes
Redo Buffers		    7639040 bytes
```

Después, nos conectamos a RMAN para restaurar la base de datos desde la copia de seguridad. Como primer paso, intentamos listar los ficheros de control incluidos en la copia con el siguiente comando:

```sql
oracle@oracle19c:~$ rman

Recovery Manager: Release 19.0.0.0.0 - Production on Sun Mar 2 22:26:21 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

RMAN> connect target

connected to target database: ORCLCDB (not mounted)

RMAN> list backup of controlfile;    

using target database control file instead of recovery catalog
RMAN-00571: ===========================================================
RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
RMAN-00571: ===========================================================
RMAN-03002: failure of list command at 03/02/2025 22:26:33
ORA-01507: base de datos sin montar
```

Aquí observamos que, al no tener la base de datos montada, no podemos acceder al catálogo de RMAN directamente. La solución es restaurar el fichero de control manualmente, pero para ello debemos conocer su ubicación en la copia de seguridad. Para verificarlo, usamos el siguiente comando:
```bash
oracle@oracle19c:~$ ls -lh /opt/oracle/product/19c/dbhome_1/dbs/  
total 2,6G
-rw-r----- 1 oracle oinstall 106M mar  2 20:59 013jc6ss_1_1
-rw-r----- 1 oracle oinstall 1,3G mar  2 20:59 023jc6su_1_1
-rw-r----- 1 oracle oinstall 474M mar  2 20:59 033jc6t5_1_1
-rw-r----- 1 oracle oinstall 555M mar  2 20:59 043jc6tu_1_1
-rw-r----- 1 oracle oinstall 375K mar  2 21:00 053jc6uo_1_1
-rw-r----- 1 oracle oinstall 106M mar  2 20:59 arch1_19_1185200241.dbf
-rw-r----- 1 oracle oinstall 372K mar  2 21:00 arch1_20_1185200241.dbf
-rw-r----- 1 oracle oinstall  18M mar  2 21:00 c-2956261615-20250302-00
-rw-r----- 1 oracle oinstall  18M mar  2 22:10 c-2956261615-20250302-01
-rw-rw---- 1 oracle oinstall 1,6K mar  2 22:25 hc_GN25.dat
-rw-rw---- 1 oracle oinstall 1,6K nov 17 17:42 hc_ORCLCDB.dat
-rw-r--r-- 1 oracle dba        64 nov 18 12:48 initGN25.ora
-rw-r--r-- 1 oracle oinstall 3,1K may 14  2015 init.ora
-rw-r----- 1 oracle oinstall   24 nov 16 14:15 lkORCLCDB
-rw-r----- 1 oracle dba      2,0K nov 16 14:17 orapwORCLCDB
-rw-r----- 1 oracle oinstall  18M mar  2 22:10 snapcf_GN25.f
-rw-r----- 1 oracle oinstall 4,5K mar  2 20:45 spfileORCLCDB.ora
```

Al ver que el fichero de control está almacenado en esa ubicación, procedemos a restaurarlo manualmente desde RMAN ejecutando:

```sql
RMAN> restore controlfile from '/opt/oracle/product/19c/dbhome_1/dbs/c-2956261615-20250302-01';        

Starting restore at 02-MAR-25
using target database control file instead of recovery catalog
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=134 device type=DISK

channel ORA_DISK_1: restoring control file
channel ORA_DISK_1: restore complete, elapsed time: 00:00:01
output file name=/opt/oracle/oradata/ORCLCDB/control01.ctl
output file name=/opt/oracle/oradata/ORCLCDB/control02.ctl
Finished restore at 02-MAR-25
```

Después de restaurar el fichero de control correctamente, seguimos con la recuperación de la base de datos. Primero, la montamos nuevamente con el siguiente comando:

```sql
RMAN> alter database mount;  

released channel: ORA_DISK_1
Statement processed
```

Luego, aplicamos la recuperación:

```sql
RMAN> recover database;

Starting recover at 02-MAR-25
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=391 device type=DISK

starting media recovery

archived log for thread 1 with sequence 21 is already on disk as file /opt/oracle/oradata/ORCLCDB/redo03.log
archived log file name=/opt/oracle/oradata/ORCLCDB/redo03.log thread=1 sequence=21
media recovery complete, elapsed time: 00:00:00
Finished recover at 02-MAR-25
```

Finalmente, abrimos la base de datos reseteando los logs para asegurar su consistencia:

```sql
RMAN> alter database open resetlogs;

Statement processed
```

Para verificar que todo se ha restaurado correctamente, listamos los archivos en el directorio de la base de datos:
```bash
oracle@oracle19c:~$ sudo ls -lh /opt/oracle/oradata/ORCLCDB/
total 2,8G
-rw-r----- 1 oracle oinstall  18M mar  2 22:38 control01.ctl
-rw-r----- 1 oracle oinstall  18M mar  2 22:38 control02.ctl
drwxr-x--- 2 oracle dba      4,0K nov 16 14:28 ORCLPDB1
drwxr-x--- 2 oracle dba      4,0K nov 16 14:20 pdbseed
-rw-r----- 1 oracle oinstall 201M mar  2 22:38 redo01.log
-rw-r----- 1 oracle oinstall 201M mar  2 22:34 redo02.log
-rw-r----- 1 oracle oinstall 201M mar  2 22:34 redo03.log
-rw-r----- 1 oracle oinstall 591M mar  2 22:34 sysaux01.dbf
-rw-r----- 1 oracle oinstall 941M mar  2 22:34 system01.dbf
-rw-r----- 1 oracle oinstall  33M mar  2 20:01 temp01.dbf
-rw-r----- 1 oracle oinstall 301M mar  2 22:34 ts_rman.dbf
-rw-r----- 1 oracle oinstall 341M mar  2 22:34 undotbs01.dbf
-rw-r----- 1 oracle oinstall  16M mar  2 22:34 users01.dbf
```

Con estos pasos, hemos logrado restaurar la base de datos utilizando la copia de seguridad de RMAN y los archivos de registro de ArchiveLog, asegurando que el sistema vuelva a un estado operativo correcto.

## Ejercicio 6

Documenta el empleo de las herramientas de copia de seguridad y restauración de Postgres.

Para crear una copia de seguridad completa de todas nuestras bases de datos, utilizamos el comando pg_dumpall. Este comando volcará toda la información de nuestras bases de datos en un archivo .sql. A continuación, ejecutamos el siguiente comando:

```bash
postgres@servidor-postgre1:~$ pg_dumpall -U postgres -f copias/copia_$(date +"%Y%m%d%H%M%S").sql
```

Este comando utiliza `pg_dumpall` con el usuario postgres y genera un archivo de copia con un nombre que incluye la fecha y hora exacta en que se crea la copia. El resultado es un archivo `.sql` que contiene todos los datos necesarios para restaurar las bases de datos si fuera necesario. Al ejecutar este comando, el archivo `copia_$(date +"%Y%m%d%H%M%S").sql` se guarda en la ruta especificada.

Al verificar el directorio donde guardamos las copias, encontramos el archivo copia.sql o el archivo con el nombre generado dinámicamente que contiene la copia de seguridad.

```bash
postgres@servidor-postgre1:~$ ls -l copias/
total 108
-rw-r--r-- 1 postgres postgres 109080 mar  2 23:09 copia_20250302230919.sql
```

Antes de realizar una restauración, podemos verificar la existencia de las bases de datos y las tablas correspondientes. En nuestro caso, accedemos a la base de datos empresa con el siguiente comando:

```bash
pablo@servidor-postgre1:~$ psql -U usuario -d empresa -h localhost
Contraseña para usuario usuario: 
psql (15.9 (Debian 15.9-0+deb12u1))
Conexión SSL (protocolo: TLSv1.3, cifrado: TLS_AES_256_GCM_SHA384, compresión: desactivado)
Digite «help» para obtener ayuda.

empresa=> \d
                Listado de relaciones
 Esquema |        Nombre        |   Tipo    |  Dueño  
---------+----------------------+-----------+---------
 public  | asignaciones         | tabla     | usuario
 public  | asignaciones_id_seq  | secuencia | usuario
 public  | departamentos        | tabla     | usuario
 public  | departamentos_id_seq | secuencia | usuario
 public  | empleados            | tabla     | usuario
 public  | empleados_id_seq     | secuencia | usuario
 public  | proyectos            | tabla     | usuario
 public  | proyectos_id_seq     | secuencia | usuario
(8 filas)
```

Aquí podemos ver que las tablas asignaciones, departamentos, empleados y proyectos están presentes.

Para realizar la restauración, vamos a eliminar varias tabla para simular la pérdida de datos. Por ejemplo, eliminamos la tabla asignaciones y empleados:

```sql
empresa=> drop table asignaciones;
DROP TABLE
empresa=> select * from asignaciones;
ERROR:  no existe la relación «asignaciones»
LÍNEA 1: select * from asignaciones;
empresa=> drop table empleados;
DROP TABLE
empresa=> select * from empleados;
ERROR:  no existe la relación «empleados»
LÍNEA 1: select * from empleados;
                       ^
```

Una vez eliminados los datos, podemos proceder a la restauración. Utilizamos el comando psql para restaurar la base de datos desde el archivo de copia de seguridad:

```bash
pablo@servidor-postgre1:~$ sudo -i -u postgres
postgres@servidor-postgre1:~$ psql -U postgres -f copias/copia_20250302230919.sql
SET
SET
SET
psql:copias/copia_20250302230919.sql:14: ERROR:  el rol «empleado» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:16: ERROR:  el rol «kaka» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:18: ERROR:  el rol «pablo» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:20: ERROR:  el rol «pablo1» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:22: ERROR:  el rol «pabloexamen» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:24: ERROR:  el rol «pablomartin» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:26: ERROR:  el rol «pablomh» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:28: ERROR:  el rol «pabloprueba» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:30: ERROR:  el rol «pavlo» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:32: ERROR:  el rol «postgres» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:34: ERROR:  el rol «prueba» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:36: ERROR:  el rol «raul» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:38: ERROR:  el rol «scott» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:40: ERROR:  el rol «usuario» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:42: ERROR:  el rol «usuario1» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:44: ERROR:  el rol «usuario_copia» ya existe
ALTER ROLE
psql:copias/copia_20250302230919.sql:46: ERROR:  el rol «usuario_vacio» ya existe
ALTER ROLE
ALTER ROLE
psql:copias/copia_20250302230919.sql:64: NOTICE:  el rol «usuario1» ya es un miembro del rol «kaka»
GRANT ROLE
psql:copias/copia_20250302230919.sql:65: NOTICE:  el rol «usuario_copia» ya es un miembro del rol «usuario»
GRANT ROLE
Ahora está conectado a la base de datos «template1» con el usuario «postgres».
SET
SET
SET
SET
SET
 set_config 
------------
 
(1 fila)

SET
SET
SET
SET
SET
SET
SET
SET
SET
 set_config 
------------
 
(1 fila)

SET
SET
SET
SET
.....
```

Durante la restauración, se generarán mensajes de advertencia si algunos usuarios ya existen en la base de datos, pero no es un problema grave, ya que se restaurarán todos los datos perdidos o eliminados.

Justo después de haber hecho la restauración, podemos verificar que ambas tablas han sido restauradas a la perfección:
```sql
pablo@servidor-postgre1:~$ psql -U usuario -d empresa -h localhost
Contraseña para usuario usuario: 
psql (15.9 (Debian 15.9-0+deb12u1))
Conexión SSL (protocolo: TLSv1.3, cifrado: TLS_AES_256_GCM_SHA384, compresión: desactivado)
Digite «help» para obtener ayuda.

empresa=> select * from empleados;
 id |    nombre    |     cargo     | id_departamento 
----+--------------+---------------+-----------------
  1 | Ana Pérez    | Gerente       |               1
  2 | Carlos López | Desarrollador |               2
  3 | Elena García | Vendedor      |               3
(3 filas)

empresa=> select * from departamentos;
 id |      nombre      
----+------------------
  1 | Recursos Humanos
  2 | Desarrollo
  3 | Ventas
(3 filas)
```

Para realizar copias de seguridad automáticas, podemos configurar un servicio y un temporizador en systemd. El servicio ejecutará el comando `pg_dumpall` diariamente, y el archivo de la copia tendrá un nombre único con la fecha y hora de la creación.

Creación del servicio: Creamos un archivo de servicio que ejecute la copia de seguridad:
```bash
pablo@servidor-postgre1:~$ sudo cat /etc/systemd/system/copia_postgres.service
[Unit]
Description=Postgres Copias

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'psql -U postgres -f copias/copia_$(date +"%Y%m%d%H%M%S").sql'

[Install]
WantedBy=multi-user.target
```

En este archivo, especificamos que el servicio ejecutará el siguiente comando para crear la copia de seguridad.

Luego, creamos un temporizador que ejecute el servicio todos los días a las 22:00:
```bash
pablo@servidor-postgre1:~$ sudo cat /etc/systemd/system/copia_postgres.timer
[Unit]
Description=Postgres Copias Temporizador

[Timer]
OnCalendar=*-*-* 22:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Finalmente, recargamos systemd y habilitamos el temporizador para que se ejecute diariamente:

```bash
pablo@servidor-postgre1:~$ sudo systemctl daemon-reload
pablo@servidor-postgre1:~$ sudo systemctl enable copia_postgres.timer
Created symlink /etc/systemd/system/timers.target.wants/copia_postgres.timer → /etc/systemd/system/copia_postgres.timer.
pablo@servidor-postgre1:~$ sudo systemctl start copia_postgres.timer
```

Con esto, las copias de seguridad se realizarán automáticamente a las 22:00 todos los días, y se guardarán con un nombre único basado en la fecha y hora.

## Ejercicio 7

Documenta el empleo de las herramientas de copia de seguridad y restauración de MySQL.

Para realizar copias de seguridad y restauraciones en MySQL, utilizamos la herramienta mysqldump. En nuestro caso, vamos a 
hacer una copia de todas las bases de datos del servidor y luego restaurarlas en caso de ser necesario.

Para generar un respaldo de todas las bases de datos, ejecutamos el siguiente comando:

```bash
pablo@servidor-mariadb:~$ sudo mysqldump -u root -p --all-databases > respaldo.sql
```

Una vez finalizado el proceso, podemos comprobar que el archivo de copia se ha generado correctamente:
```bash
pablo@servidor-mariadb:~$ ls -lh respaldo.sql
-rw-r--r-- 1 pablo pablo 5,7M mar  3 08:28 respaldo.sql
```

Para comprobar que la restauración funciona correctamente, vamos a eliminar algunas bases de datos:
```sql
pablo@servidor-mariadb:~$ sudo mysql
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 33
Server version: 10.11.6-MariaDB-0+deb12u1-log Debian 12

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| Examen             |
| datoscsv           |
| empresa            |
| empresa_copia      |
| empresa_datos      |
| empresa_vacia      |
| information_schema |
| mysql              |
| performance_schema |
| practica1_abd      |
| sakila             |
| scott              |
| sys                |
+--------------------+
13 rows in set (0,001 sec)

MariaDB [(none)]> DROP DATABASE empresa_copia;
Query OK, 2 rows affected (0,038 sec)

MariaDB [(none)]> DROP DATABASE empresa_datos;
Query OK, 2 rows affected (0,014 sec)

MariaDB [(none)]> DROP DATABASE empresa_vacia;
Query OK, 2 rows affected (0,016 sec)
```

Ya hemos eliminado varias bases de datos, por lo tanto, para recuperar todas las bases de datos eliminadas, utilizamos el 
archivo de respaldo que creamos anteriormente:
```bash
pablo@servidor-mariadb:~$ sudo mysql -u root -p < respaldo.sql
```

Una vez finalizada la restauración, verificamos que las bases de datos han sido recuperadas:
```sql
pablo@servidor-mariadb:~$ sudo mysql
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 35
Server version: 10.11.6-MariaDB-0+deb12u1-log Debian 12

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| Examen             |
| datoscsv           |
| empresa            |
| empresa_copia      |
| empresa_datos      |
| empresa_vacia      |
| information_schema |
| mysql              |
| performance_schema |
| practica1_abd      |
| sakila             |
| scott              |
| sys                |
+--------------------+
13 rows in set (0,001 sec)
MariaDB [(none)]> USE empresa_copia;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [empresa_copia]> SHOW TABLES;
+-------------------------+
| Tables_in_empresa_copia |
+-------------------------+
| departamentos           |
| empleados               |
+-------------------------+
2 rows in set (0,001 sec)
```

Y como podemos ver, las tablas y los datos se han restaurado correctamente.

Para asegurarnos de que se realicen copias de seguridad de forma automática todos los días, creamos un servicio en systemd 
que ejecutará el comando `mysqldump` y guardará la copia con la fecha y la hora en el nombre del archivo.

```bash
pablo@servidor-mariadb:~$ sudo cat /etc/systemd/system/backup_mysql.service
[Unit]
Description=Copia de seguridad de MySQL

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'mysqldump -u root -p --all-databases > /home/debian/backups/mysql_backup_$(date +"%Y%m%d%H%M%S").sql'

[Install]
WantedBy=multi-user.target
```

Guardamos los cambios y creamos un temporizador para que la copia se realice automáticamente todos los días a las 03:00.
```bash
pablo@servidor-mariadb:~$ sudo cat /etc/systemd/system/backup_mysql.timer
[Unit]
Description=Temporizador para la copia de seguridad de MySQL

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Guardamos el archivo, recargamos systemd, habilitamos y activamos el temporizador:
```bash
pablo@servidor-mariadb:~$ sudo systemctl daemon-reload
pablo@servidor-mariadb:~$ sudo systemctl enable backup_mysql.timer
Created symlink /etc/systemd/system/timers.target.wants/backup_mysql.timer → /etc/systemd/system/backup_mysql.timer.
pablo@servidor-mariadb:~$ sudo systemctl start backup_mysql.timerPodemos comprobar que el temporizador está activo con:
```

Podemos comprobar que el temporizador está activo con:
```bash
pablo@servidor-mariadb:~$ sudo systemctl list-timers --all
NEXT                        LEFT          LAST                        PASSED              UNIT                         ACTIVATES                     
Mon 2025-03-03 11:57:51 CET 3h 15min left Mon 2025-01-20 13:29:53 CET 1 month 11 days ago man-db.timer                 man-db.service
Mon 2025-03-03 21:34:40 CET 12h left      Mon 2025-03-03 08:34:57 CET 7min ago            apt-daily.timer              apt-daily.service
Tue 2025-03-04 00:00:00 CET 15h left      -                           -                   dpkg-db-backup.timer         dpkg-db-backup.service
Tue 2025-03-04 00:00:00 CET 15h left      Mon 2025-03-03 08:25:50 CET 16min ago           logrotate.timer              logrotate.service
Tue 2025-03-04 03:00:00 CET 18h left      -                           -                   backup_mysql.timer           backup_mysql.service
Tue 2025-03-04 06:21:11 CET 21h left      Mon 2025-03-03 08:29:27 CET 13min ago           apt-daily-upgrade.timer      apt-daily-upgrade.service
Tue 2025-03-04 08:40:47 CET 23h left      Mon 2025-03-03 08:40:47 CET 1min 40s ago        systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
Sun 2025-03-09 03:10:08 CET 5 days left   Sun 2025-03-02 15:51:15 CET 16h ago             e2scrub_all.timer            e2scrub_all.service
Mon 2025-03-10 00:06:34 CET 6 days left   Mon 2025-03-03 08:41:36 CET 51s ago             fstrim.timer                 fstrim.service

9 timers listed.
```

Con esta configuración, aseguramos que las copias de seguridad se realicen automáticamente y podamos restaurarlas en caso de pérdida de datos.

## Ejercicio 8

Documenta el empleo de las herramientas de copia de seguridad y restauración de MongoDB.

En este caso, vamos a realizar una copia de seguridad de la base de datos tienda en MongoDB utilizando el comando mongodump. 
Posteriormente, eliminaremos la base de datos y la restauraremos utilizando mongorestore. Además, configuraremos un servicio y un 
temporizador en systemd para automatizar la realización de copias de seguridad diarias.


Primero, ejecutamos el comando `mongodump` para crear una copia de seguridad de la base de datos tienda. 
Utilizamos las credenciales del usuario pavlo, que tiene permisos para acceder a la base de datos. La copia se guardará en un 
directorio específico con la fecha y hora actuales.

```bash
pablo@servidor-mongo:~$ mongodump -u pavlo -p pavlo --db tienda --authenticationDatabase admin --out /home/pablo/copia_mongo/copia$(date +%Y%m%d%H%M%S)
2025-03-03T08:57:01.729+0100	writing tienda.productos to /home/pablo/copia_mongo/copia20250303085701/tienda/productos.bson
2025-03-03T08:57:01.730+0100	done dumping tienda.productos (5 documents)
```

Este comando generará archivos `.bson` y `.metadata.json` en la ruta especificada, conteniendo los datos y metadatos de las colecciones de la base de datos tienda.

```bash
pablo@servidor-mongo:~$ ls -lh copia_mongo/
total 4,0K
drwxr-xr-x 3 pablo pablo 4,0K mar  3 08:57 copia20250303085701
pablo@servidor-mongo:~$ ls -lh copia_mongo/copia20250303085701/
total 4,0K
drwxr-xr-x 2 pablo pablo 4,0K mar  3 08:57 tienda
pablo@servidor-mongo:~$ ls -lh copia_mongo/copia20250303085701/tienda/
total 8,0K
-rw-r--r-- 1 pablo pablo 501 mar  3 08:57 productos.bson
-rw-r--r-- 1 pablo pablo 298 mar  3 08:57 productos.metadata.json
```

Para simular una situación en la que necesitamos restaurar la base de datos, primero la eliminaremos. Nos conectamos a MongoDB usando `mongosh` y ejecutamos el comando `db.dropDatabase()`.
```js
pablo@servidor-mongo:~$ mongosh -u pavlo -p pavlo --authenticationDatabase admin
Current Mongosh Log ID:	67c56120c2c54a2a69fe6910
Connecting to:		mongodb://<credentials>@127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&authSource=admin&appName=mongosh+2.3.2
Using MongoDB:		6.0.18
Using Mongosh:		2.3.2
mongosh 2.4.0 is available for download: https://www.mongodb.com/try/download/shell

For mongosh info see: https://www.mongodb.com/docs/mongodb-shell/

------
   The server generated these startup warnings when booting
   2025-03-03T08:49:29.506+01:00: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem
   2025-03-03T08:49:29.819+01:00: /sys/kernel/mm/transparent_hugepage/enabled is 'always'. We suggest setting it to 'never' in this binary version
   2025-03-03T08:49:29.819+01:00: vm.max_map_count is too low
------

test> use tienda;
switched to db tienda
tienda> db.dropDatabase()
{ ok: 1, dropped: 'tienda' }
```

Esto eliminará la base de datos tienda y todas sus colecciones.

Ahora, utilizaremos el comando `mongorestore` para restaurar la base de datos a partir de la copia de seguridad que creamos anteriormente. Especificamos la ruta donde se encuentra la copia y las credenciales del usuario.
```bash
pablo@servidor-mongo:~$ mongorestore -u pavlo -p pavlo --db tienda --authenticationDatabase admin /home/pablo/copia_mongo/copia20250303085701/tienda/
2025-03-03T09:00:29.797+0100	The --db and --collection flags are deprecated for this use-case; please use --nsInclude instead, i.e. with --nsInclude=${DATABASE}.${COLLECTION}
2025-03-03T09:00:29.798+0100	building a list of collections to restore from /home/pablo/copia_mongo/copia20250303085701/tienda dir
2025-03-03T09:00:29.798+0100	reading metadata for tienda.productos from /home/pablo/copia_mongo/copia20250303085701/tienda/productos.metadata.json
2025-03-03T09:00:29.823+0100	restoring tienda.productos from /home/pablo/copia_mongo/copia20250303085701/tienda/productos.bson
2025-03-03T09:00:29.834+0100	finished restoring tienda.productos (5 documents, 0 failures)
2025-03-03T09:00:29.835+0100	restoring indexes for collection tienda.productos from metadata
2025-03-03T09:00:29.836+0100	index: &idx.IndexDocument{Options:primitive.M{"name":"precio_1_categoria_1", "v":2}, Key:primitive.D{primitive.E{Key:"precio", Value:1}, primitive.E{Key:"categoria", Value:1}}, PartialFilterExpression:primitive.D(nil)}
2025-03-03T09:00:29.860+0100	5 document(s) restored successfully. 0 document(s) failed to restore.
```

Este comando leerá los archivos `.bson` y `.metadata.json` y restaurará las colecciones y sus datos en la base de datos tienda.

Como podemos ver, se ha restaurado correctamente:
```js
pablo@servidor-mongo:~$ mongosh -u pavlo -p pavlo --authenticationDatabase admin
Current Mongosh Log ID:	67c561a3dde0282076fe6910
Connecting to:		mongodb://<credentials>@127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&authSource=admin&appName=mongosh+2.3.2
Using MongoDB:		6.0.18
Using Mongosh:		2.3.2
mongosh 2.4.0 is available for download: https://www.mongodb.com/try/download/shell

For mongosh info see: https://www.mongodb.com/docs/mongodb-shell/

------
   The server generated these startup warnings when booting
   2025-03-03T08:49:29.506+01:00: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem
   2025-03-03T08:49:29.819+01:00: /sys/kernel/mm/transparent_hugepage/enabled is 'always'. We suggest setting it to 'never' in this binary version
   2025-03-03T08:49:29.819+01:00: vm.max_map_count is too low
------

test> show dbs;
admin            424.00 KiB
biblioteca       100.00 KiB
config           108.00 KiB
ex_usuario       200.00 KiB
examen           200.00 KiB
kk               200.00 KiB
local             80.00 KiB
nueva_tienda      40.00 KiB
practica1_abd    120.00 KiB
prueba           120.00 KiB
pruebas          184.00 KiB
restaurantes_db   60.00 KiB
tienda            60.00 KiB
```

Para asegurarnos de que las copias de seguridad se realicen automáticamente cada día, crearemos un servicio y un temporizador en systemd.

Primero, creamos un archivo de servicio en `/etc/systemd/system/mongo_copia.service` con el siguiente contenido:
```bash
[Unit]
Description=Realiza copias de seguridad de la base de datos tienda en MongoDB

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'mongodump -u pavlo -p pavlo --db tienda --authenticationDatabase admin --out /home/pablo/copia_mongo/copia$(date +%%Y%%m%%d%%H%%M%%S)'
```

Este servicio ejecutará el comando `mongodump` para crear una copia de seguridad de la base de datos tienda en una carpeta con la fecha y hora actuales.

A continuación, creamos un archivo de temporizador en `/etc/systemd/system/mongo_copia.timer` con el siguiente contenido:
```sh
[Unit]
Description=Ejecuta el servicio de copia de seguridad de MongoDB diariamente a las 03:00

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Este temporizador programará la ejecución del servicio `mongo_copia.service` todos los días a las 03:00.

Finalmente, recargamos el demonio de systemd, habilitamos y activamos el temporizador:
```sh
pablo@servidor-mongo:~$ sudo systemctl daemon-reload
pablo@servidor-mongo:~$ sudo systemctl enable mongo_copia.timer
Created symlink /etc/systemd/system/timers.target.wants/mongo_copia.timer → /etc/systemd/system/mongo_copia.timer.
pablo@servidor-mongo:~$ sudo systemctl start mongo_copia.timer
```

Podemos comprobar que el temporizador está activo con:

```sh
pablo@servidor-mongo:~$ sudo systemctl list-timers --all | grep mongo
Tue 2025-03-04 03:00:00 CET 17h left      -                           -                  mongo_copia.timer            mongo_copia.service
```