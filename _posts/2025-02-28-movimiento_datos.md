---
title: "Movimiento de datos"
date: 2025-02-28 20:33:00 +0000
categories: [Base de Datos]
tags: []
author: pablo
description: "En esta práctica, exploraremos diferentes técnicas de exportación e importación de datos entre bases de datos utilizando herramientas de Oracle, MySQL, PostgreSQL y MongoDB. Comenzaremos con la exportación e importación de un esquema de Oracle utilizando Oracle Data Pump, donde se aplicarán filtros específicos y se automatizará la operación. Además, compararemos estos procesos con las herramientas de línea de comandos de MySQL y PostgreSQL, y abordaremos la carga de datos de un archivo de texto a Oracle mediante SQL*Loader, cubriendo todos los pasos y ficheros involucrados en el proceso."
toc: true
comments: true
image:
  path: /assets/img/posts/movimiento/portadita.png
---

## Ejercicio 1

Realiza una exportación del esquema de SCOTT usando Oracle Data Pump con las siguientes condiciones:

- Exporta tanto la estructura de las tablas como los datos de las mismas.
- Excluye la tabla BONUS y los departamentos con menos de dos empleados.
- Realiza una estimación previa del tamaño necesario para el fichero de exportación.
- Programa la operación para dentro de 2 minutos.
- Genera un archivo de log en el directorio raíz.

Lo primero que hacemos es preparar el entorno para la exportación. Creamos un directorio en el sistema de archivos donde se almacenarán los archivos generados por Data Pump:

```bash
sudo mkdir /opt/oracle/export
```

Luego, asignamos los permisos para que el usuario oracle tenga acceso:

```bash
sudo chown oracle:oinstall /opt/oracle/export
```

![image](/assets/img/posts/movimiento/image1.png)

Una vez configurado el sistema de archivos, accedemos a Oracle y definimos un directorio lógico que Data Pump utilizará para almacenar los archivos de exportación. Además, concedemos los permisos necesarios al usuario SCOTT:

```sql
CREATE DIRECTORY EXPORT_BD AS '/opt/oracle/export/';
GRANT READ, WRITE ON DIRECTORY EXPORT_BD TO SCOTT;
```

![image](/assets/img/posts/movimiento/image2.png)

También es necesario otorgar permisos de exportación completos para que pueda realizar la operación:

```sql
GRANT DATAPUMP_EXP_FULL_DATABASE TO SCOTT;
```

![image](/assets/img/posts/movimiento/image3.png)

Para realizar la exportación, utilizamos el comando **expdp**, incluyendo las condiciones establecidas:

- Exportamos la estructura y los datos de todas las tablas del esquema **SCOTT**.
- Excluimos la tabla **BONUS**.
- Filtramos los departamentos que tienen menos de dos empleados.
- Especificamos el directorio creado previamente para almacenar el archivo de exportación.

El comando que utilizamos es el siguiente:

```bash
expdp scott/tiger DIRECTORY=EXPORT_BD SCHEMAS=scott EXCLUDE=TABLE:\"=\'BONUS\'\" QUERY=dept:'"WHERE deptno IN \(SELECT deptno FROM EMP GROUP BY deptno HAVING COUNT\(*\)>2\)"'
```

![image](/assets/img/posts/movimiento/image4.png)

Para ejecutar la exportación dentro de 2 minutos, podemos utilizar el comando at, pero en este caso optamos por un script que se encargará de la espera y la ejecución automática del comando. Creamos el archivo `exportacion.sh`:

```bash
#!/bin/bash
echo "Preparando la exportación del esquema SCOTT..."
sleep 70
echo "Falta menos de un minuto para iniciar el proceso."
sleep 20
echo "Últimos 10 segundos..."
sleep 7
echo "Exportación en 3... 2... 1... ¡Comenzando!"
sleep 3

expdp scott/tiger \
  DIRECTORY=EXPORT_BD \
  SCHEMAS=scott \
  EXCLUDE=TABLE:\"=\'BONUS\'\" \
  QUERY=dept:'"WHERE deptno IN \(SELECT deptno FROM EMP GROUP BY deptno HAVING COUNT\(*\)>2\)"' \
  LOGFILE=export_scott.log
```

Le damos permisos de ejecución:

```bash
sudo chmod +x exportacion.sh
```

Finalmente, ejecutamos el script y verificamos que la exportación se realiza correctamente después del tiempo indicado:

```bash
./exportacion.sh
```

De este modo, garantizamos que la exportación del esquema **SCOTT** se realiza según las condiciones establecidas, almacenando el log de la operación en el directorio raíz para su posterior revisión.

Ejecutamos el script:

![image](/assets/img/posts/movimiento/image5.png)

Una vez terminada la ejecución podemos ver como se han generado dos archivos nuevos:

```bash
oracle@oracle19c:~$ ls -lh /opt/oracle/export/
total 516K
-rw-r----- 1 oracle oinstall 504K feb 28 12:57 expdat.dmp
-rw-r--r-- 1 oracle oinstall  471 feb 28 12:54 export.log
-rw-r--r-- 1 oracle oinstall 2,3K feb 28 12:57 export_scott.log
```

Este es el contenido de `export_scott.log`:

![image](/assets/img/posts/movimiento/image6.png)

Y este es el contenido de `expdat.dmp`:

![image](/assets/img/posts/movimiento/image7.png)

## Ejercicio 2

Importa el fichero obtenido anteriormente usando Oracle Data Pump pero en un usuario distinto de la misma base de datos.

Para realizar la importación, utilizaré un usuario previamente creado. Antes de proceder, es necesario otorgarle los permisos de lectura y escritura sobre el directorio donde se encuentran los archivos de importación, ya que será el destino de la base de datos importada.

Además, es fundamental concederle los privilegios necesarios para llevar a cabo la operación de importación correctamente:

```sql
GRANT READ, WRITE ON DIRECTORY EXPORT_BD TO PABLOLINK;
GRANT IMP_FULL_DATABASE TO PABLOLINK;
```

![image](/assets/img/posts/movimiento/image8.png)

Para importar la base de datos en el usuario PABLOLINK, utilizo la herramienta Oracle Data Pump con el siguiente comando:

```bash
impdp pablolink/password \
  DIRECTORY=EXPORT_BD \
  DUMPFILE=expdat.dmp \
  REMAP_SCHEMA=scott:pablolink \
  TABLE_EXISTS_ACTION=REPLACE \
  LOGFILE=import_pablolink.log
```

- `DIRECTORY=EXPORT_BD`: Indica el directorio lógico donde se encuentra el archivo de volcado (`expdat.dmp`).
- `DUMPFILE=expdat.dmp`: Especifica el archivo de volcado de datos que contiene la exportación previa.
- `REMAP_SCHEMA=scott:pablolink`: Transforma el esquema original (`SCOTT`) en el nuevo usuario (`PABLOLINK`), asegurando que los objetos se importen bajo esta nueva cuenta.
- `TABLE_EXISTS_ACTION=REPLACE`: Si las tablas ya existen, este parámetro las elimina y las vuelve a crear antes de importar los datos.
- `LOGFILE=import_pablolink.log`: Especifica un archivo de registro donde se almacenará el resultado del proceso de importación.

![image](/assets/img/posts/movimiento/image9.png)

Una vez finalizada la importación, accedo con el usuario PABLOLINK para verificar el contenido de la base de datos y comprobar si la tabla BONUS existe o no. 

![image](/assets/img/posts/movimiento/image10.png)

## Ejercicio 3

Realiza una exportación de la estructura de todas las tablas de la base de datos usando el comando expdp de Oracle Data Pump probando al menos cinco de las posibles opciones que ofrece dicho comando y documentándolas adecuadamente.

Para exportar solo la estructura de todas las tablas de la base de datos con **Oracle Data Pump**, usamos el comando **`expdp`**. Vamos a probar cinco opciones diferentes y explicar su función.  

Ejecutamos el siguiente comando:  

```bash
expdp pablolink/password \
  DIRECTORY=EXPORT_BD \
  DUMPFILE=exp_estructura.dmp \
  LOGFILE=exp_estructura.log \
  SCHEMAS=pablolink \
  CONTENT=METADATA_ONLY \
  COMPRESSION=ALL \
  EXCLUDE=STATISTICS \
  PARALLEL=2
```

![image](/assets/img/posts/movimiento/image11.png)

- **`DIRECTORY=EXPORT_BD`**: Especifica la carpeta en la que se guardará el archivo de exportación. Esta carpeta debe estar creada en Oracle y tener permisos adecuados.  
- **`DUMPFILE=exp_estructura.dmp`**: Es el nombre del archivo donde se guardará la exportación.  
- **`LOGFILE=exp_estructura.log`**: Guarda un registro con los detalles del proceso, por si necesitamos revisarlo más tarde.  
- **`SCHEMAS=pablolink`**: Exporta solo las tablas del usuario **PABLOLINK**, sin afectar a otros esquemas de la base de datos.  
- **`CONTENT=METADATA_ONLY`**: Exporta solo la estructura de las tablas, sin incluir los datos.  
- **`COMPRESSION=ALL`**: Comprime la exportación para que ocupe menos espacio en disco.  
- **`EXCLUDE=STATISTICS`**: No exporta las estadísticas de la base de datos, lo que reduce el tamaño del archivo de exportación.  
- **`PARALLEL=2`**: Usa dos procesos en paralelo para hacer la exportación más rápida.  

Con este comando, conseguimos una copia de seguridad de la estructura de las tablas sin guardar los datos, lo que es útil si queremos recrear el esquema en otro lugar sin transferir grandes volúmenes de información.

Podemos ver que se han generado dos archivos:

```bash
oracle@oracle19c:~$ ls -lh /opt/oracle/export/ | grep '19:26'
-rw-r----- 1 oracle oinstall 124K feb 28 19:26 exp_estructura.dmp
-rw-r--r-- 1 oracle oinstall 1,9K feb 28 19:26 exp_estructura.log
```

## Ejercicio 4

Intenta realizar operaciones similares de importación y exportación con las herramientas proporcionadas con MySQL desde línea de comandos, documentando el proceso.

Cuando exportamos una base de datos en MySQL, lo que hacemos es generar un archivo con todas las instrucciones SQL necesarias para reconstruir la base de datos en otro lugar. Este archivo incluirá la estructura de las tablas y, si lo deseamos, también los datos almacenados en ellas.

Para ello, utilizamos `mysqldump`, una herramienta que nos permite volcar toda la información en un archivo `.sql`. Antes de comenzar, debemos asegurarnos de que tenemos permisos suficientes para ejecutar la exportación y de que tenemos acceso a la base de datos empresa.

Para la realización de este apartado, estaré utilizando las siguientes tablas:

![image](/assets/img/posts/movimiento/image12.png)

### Exportación e Importación Completa (Estructura + Datos)

Si queremos hacer una copia completa de la base de datos empresa, utilizamos `mysqldump` para generar un archivo que contiene tanto la estructura de las tablas como los datos almacenados en ellas.

Ejecutamos el siguiente comando en la terminal:

```bash
mysqldump -u usuario -p empresa > empresa_completa.sql
```

Este archivo `empresa_completa.sql` contiene todas las instrucciones necesarias para reconstruir la base de datos con su estructura y datos.

Supongamos que queremos importar esta base de datos en un usuario y base de datos diferentes. Primero, en MySQL, creamos una nueva base de datos `empresa_copia` y un usuario `usuario_copia`:

```sql
CREATE DATABASE empresa_copia;
CREATE USER 'usuario_copia'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON empresa_copia.* TO 'usuario_copia'@'localhost';
FLUSH PRIVILEGES;
```

Luego, importamos el backup en la nueva base de datos:

```bash
mysql -u usuario_copia -p empresa_copia < empresa_completa.sql
```

Si accedemos a MySQL con el usuario `usuario_copia` y consultamos la base de datos, veremos que la estructura y los datos de empresa han sido replicados en `empresa_copia`.

![image](/assets/img/posts/movimiento/image13.png)

### Exportación e Importación Solo de la Estructura

Si queremos transferir solo la estructura de la base de datos sin los datos, usamos la opción --no-data:

```bash
mysqldump -u usuario -p --no-data empresa > empresa_estructura.sql
```

Este archivo `empresa_estructura.sql` contiene únicamente las sentencias `CREATE TABLE`, sin los registros de las tablas.

Creamos una base de datos `empresa_vacia` y un usuario `usuario_vacio`:

```sql
CREATE DATABASE empresa_vacia;
CREATE USER 'usuario_vacio'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON empresa_vacia.* TO 'usuario_vacio'@'localhost';
FLUSH PRIVILEGES;
```

Luego, importamos el archivo con la estructura:

```bash
mysql -u usuario_vacio -p empresa_vacia < empresa_estructura.sql
```

Al acceder a `empresa_vacia`, veremos que las tablas están creadas, pero no contienen datos.

![image](/assets/img/posts/movimiento/image14.png)

### Exportación e Importación Solo de los Datos

Si ya tenemos la estructura en otro servidor y queremos trasladar solo los datos sin modificar las tablas, utilizamos la opción `--no-create-info`:

```bash
mysqldump -u usuario -p --no-create-info empresa > empresa_datos.sql
```

Este archivo `empresa_datos.sql` solo contiene las sentencias `INSERT INTO` con los registros.

Supongamos que ya tenemos una base de datos empresa_estructura con las mismas tablas creadas previamente. Creamos un nuevo usuario para este entorno:

```sql
CREATE USER 'usuario_datos'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON empresa_datos.* TO 'usuario_datos'@'localhost';
FLUSH PRIVILEGES;
```

Luego, importamos solo los datos:

```bash
mysql -u usuario_datos -p empresa_datos < empresa_datos.sql
```

Si consultamos las tablas en `empresa_datos`, veremos que ahora contienen datos sin haber modificado su estructura.

![image](/assets/img/posts/movimiento/image15.png)

### Exportación e Importación con Compresión

Si la base de datos es grande, podemos comprimirla antes de almacenarla o transferirla:

```bash
mysqldump -u usuario -p empresa | gzip > empresa_comprimida.sql.gz
```

Esto reduce significativamente el tamaño del archivo.

Antes de importar, primero descomprimimos el archivo:

```bash
gunzip < empresa_comprimida.sql.gz | mysql -u usuario_copia -p empresa_copia
```

Esto ejecutará el contenido del archivo en `empresa_copia`, restaurando toda la base de datos.

## Ejercicio 5 

Intenta realizar operaciones similares de importación y exportación con las herramientas proporcionadas con Postgres desde línea de comandos, documentando el proceso.

Para realizar la exportación e importación de datos de una base de datos en PostgreSQL, se puede utilizar la herramienta `pg_dump`, que permite crear copias de seguridad de bases de datos completas o de objetos específicos (como tablas o esquemas). A continuación, vamos a simular un escenario donde creamos una base de datos, exportamos e importamos datos, utilizando un usuario llamado `pablouser` y una base de datos llamada `pablobd`.

### Creación del Usuario y la Base de Datos

Primero, necesitamos crear un nuevo usuario en PostgreSQL que tendrá privilegios sobre la base de datos que vamos a manejar. Para hacerlo, nos conectamos a la consola de PostgreSQL con el usuario `postgres` (que es el administrador por defecto de PostgreSQL):

```bash
pablo@servidor-postgre1:~$ sudo -u postgres psql
```

Una vez dentro de PostgreSQL, podemos crear un nuevo usuario:

```sql
postgres=# CREATE USER pablouser WITH PASSWORD 'password';
```

Luego, creamos una base de datos llamada `pablobd` y le asignamos la propiedad al usuario recién creado:

```sql
postgres=# CREATE DATABASE pablobd WITH OWNER = pablouser;
```

### Creación de Tablas y Población con Datos

Antes de exportar los datos, necesitamos algunas tablas con datos para que podamos exportarlas. Supongamos que queremos crear dos tablas: `clientes` y `pedidos`.

**Tabla de Clientes**

```sql
pablouser=# CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100),
    direccion VARCHAR(255)
);
```

**Tabla de Pedidos**

```sql
pablouser=# CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    producto VARCHAR(100),
    cantidad INTEGER,
    precio DECIMAL
);
```

A continuación, vamos a insertar algunos datos en estas tablas.
```sql
pablouser=# INSERT INTO clientes (nombre, email, direccion)
VALUES
('Juan Pérez', 'juan.perez@email.com', 'Calle Falsa 123'),
('Ana Gómez', 'ana.gomez@email.com', 'Avenida Siempre Viva 456'),
('Luis Martínez', 'luis.martinez@email.com', 'Plaza Mayor 789');
```

```sql
pablouser=# INSERT INTO pedidos (cliente_id, producto, cantidad, precio)
VALUES
(1, 'Laptop', 1, 1200.00),
(2, 'Smartphone', 2, 800.00),
(3, 'Teclado', 3, 150.00),
(1, 'Monitor', 1, 300.00);
```

### Exportación de la Base de Datos

Una vez que tenemos datos en nuestras tablas, podemos exportar la base de datos, ya sea completamente o exportando solo ciertas tablas.

Para exportar toda la base de datos `pablobd`, utilizamos el comando `pg_dump`:

```bash
pablo@servidor-postgre1:~$ pg_dump -U pablouser -h localhost pablobd > pablobd_completa.sql
```

Este comando creará un archivo llamado `pablobd_completa.sql` que contendrá toda la estructura de la base de datos (tablas, índices, funciones, etc.) y los datos. Es importante mencionar que se utilizará la contraseña del usuario `pablouser` durante la ejecución.

Si solo deseamos exportar la estructura de las tablas (sin los datos), podemos usar la opción `-s` de `pg_dump`:

```bash
pablo@servidor-postgre1:~$ pg_dump -U pablouser -h localhost -s pablobd > pablobd_estructura.sql
```

Este comando generará un archivo que solo contendrá la definición de las tablas, sin los datos de las filas.

Si solo queremos exportar una tabla específica (por ejemplo, la tabla `clientes`), utilizamos la opción `-t` de `pg_dump`:

```bash
pablo@servidor-postgre1:~$ pg_dump -U pablouser -h localhost -t clientes pablobd > clientes.sql
```

Este comando exportará solo la tabla `clientes` y sus datos a un archivo llamado `clientes.sql`.

Para importar los datos exportados, primero necesitamos crear una nueva base de datos en PostgreSQL donde importaremos los datos. Supongamos que queremos importar los datos exportados a una nueva base de datos llamada `nuevobd`:

```sql
postgres=# CREATE DATABASE nuevobd WITH OWNER = pablouser;
```

Ahora, la base de datos `nuevobd` está lista para recibir los datos.

### Importación de los Datos

La importación se realiza utilizando el comando `psql`. Para importar el archivo completo de la base de datos, podemos usar el siguiente comando:

```bash
pablo@servidor-postgre1:~$ psql -U pablouser -d nuevobd -h localhost < pablobd_completa.sql
Contraseña para usuario pablouser:
```

Esto restaurará tanto la estructura como los datos de la base de datos original `pablobd` en la nueva base de datos `nuevobd`.

Si solo queremos importar la estructura de las tablas, utilizamos el archivo `pablobd_estructura.sql` de esta manera:

```bash
pablo@servidor-postgre1:~$ psql -U pablouser -d nuevobd -h localhost < pablobd_estructura.sql
```

Esto creará las tablas sin los datos.

Si solo deseamos importar la tabla `clientes`, usamos el siguiente comando con el archivo `clientes.sql`:

```bash
pablo@servidor-postgre1:~$ psql -U pablouser -d nuevobd -h localhost < clientes.sql
```

Una vez realizada la importación, nos conectamos a la base de datos `nuevobd` como el usuario `pablouser` para verificar que los datos y la estructura se han importado correctamente:

```bash
pablo@servidor-postgre1:~$ psql -U pablouser -d nuevobd -h localhost
Contraseña para usuario pablouser:
```

Luego, podemos listar las tablas de la base de datos para verificar que las tablas se han creado correctamente:

```sql
pablouser=> \d
 Esquema | Nombre   | Tipo  | Propietario
---------+----------+-------+-------------
 public  | clientes | tabla | pablouser
 public  | pedidos  | tabla | pablouser
(2 filas)
```

Y verificar que los datos también se han importado correctamente:

```sql
pablouser=> SELECT * FROM clientes;
```

Esto debería mostrar los datos que insertamos previamente en la tabla `clientes`:

```
 id |      nombre      |         email         |          direccion
----+------------------+-----------------------+------------------------------
  1 | Juan Pérez       | juan.perez@email.com   | Calle Falsa 123
  2 | Ana Gómez        | ana.gomez@email.com    | Avenida Siempre Viva 456
  3 | Luis Martínez    | luis.martinez@email.com| Plaza Mayor 789
(3 filas)
```

## Ejercicio 6

Exporta los documentos de una colección de MongoDB que cumplan una determinada condición e impórtalos en otra base de datos.

Supongamos que tenemos una base de datos llamada `tienda` y una colección llamada `productos`. 

![image](/assets/img/posts/movimiento/image16.png)

Queremos exportar todos los documentos de la colección productos cuyo campo precio sea mayor a 100.

Accedemos al servidor de MongoDB, podemos hacerlo de forma remota o local, dependiendo de nuestra configuración.

Utilizamos la herramienta mongoexport para exportar los documentos que cumplan con una condición específica. En este caso, queremos exportar todos los productos cuyo precio sea mayor a 100. Para ello, usaremos el siguiente comando:

```bash
mongoexport --uri="mongodb://localhost:27017" -u pavlo -p pavlo --authenticationDatabase admin --db=tienda --collection=productos --query='{ "precio": { "$gt": 100 } }' --jsonArray --out=productos_exportados.json
```

![image](/assets/img/posts/movimiento/image17.png)

Donde:

- `--uri="mongodb://localhost:27017"`: Especificamos la URI de conexión a nuestro servidor de MongoDB. En este caso, estamos trabajando con una instancia local.
- `--db=tienda`: Indicamos la base de datos desde la cual vamos a exportar los datos.
- `--collection=productos`: Especificamos la colección productos de la cual vamos a exportar los documentos.
- `--query='{ "precio": { "$gt": 100 } }'`: Definimos una consulta que filtre los productos cuyo campo precio sea mayor que 100 ($gt es el operador de "mayor que").
- `--out=productos_exportados.json`: Especificamos el archivo de salida donde se guardarán los documentos exportados, en formato JSON.

Esto generará un archivo llamado `productos_exportados.json` que contendrá todos los productos cuyo precio sea mayor a 100.

Una vez que hemos exportado los documentos que cumplen con la condición, el siguiente paso es importarlos en otra base de datos de MongoDB. Supongamos que queremos importar estos documentos en una nueva base de datos llamada `nueva_tienda`.

Para ello, usamos el siguiente comando:

```bash
mongoimport --uri="mongodb://localhost:27017" -u pavlo -p pavlo --authenticationDatabase admin --db=nueva_tienda --collection=productos --file=productos_exportados.json --jsonArray
```

![image](/assets/img/posts/movimiento/image18.png)

Una vez realizado el proceso de importación, podemos verificar que los documentos se han importado correctamente accediendo a la base de datos `nueva_tienda`. Para verificarlo, utilizamos el siguiente comando:

![image](/assets/img/posts/movimiento/image19.png)

Y tal y como podemos observar, solo se han importado solo los documentos cuyo precio es superior a 100.

## Ejercicio 7 

SQL*Loader es una herramienta que sirve para cargar grandes volúmenes de datos en una instancia de ORACLE. Exportad los datos de una base de datos completa desde MariaDB a texto plano con delimitadores y emplead SQL*Loader para realizar el proceso de carga de dichos datos a una instancia ORACLE. Debéis documentar todo el proceso, explicando los distintos ficheros de configuración y de log que tiene SQL*Loader.

Primero, necesitamos exportar los datos de la base de datos MariaDB a un formato de texto plano con delimitadores, como CSV. Para ello, seleccionamos las dos tablas que queremos exportar: **departamentos** y **empleados**.

```sql
MariaDB [empresa]> SHOW TABLES;
+-------------------+
| Tables_in_empresa |
+-------------------+
| departamentos     |
| empleados         |
+-------------------+
2 rows in set (0,000 sec)

MariaDB [empresa]> SELECT * FROM departamentos;
+----+------------------+-----------+
| id | nombre           | ubicacion |
+----+------------------+-----------+
|  1 | Recursos Humanos | Madrid    |
|  2 | Finanzas         | Barcelona |
|  3 | Desarrollo       | Sevilla   |
|  4 | Ventas           | Valencia  |
+----+------------------+-----------+
4 rows in set (0,000 sec)

MariaDB [empresa]> SELECT * FROM empleados;
+----+--------+------------+------------------------------+---------+-----------------+
| id | nombre | apellido   | email                        | salario | departamento_id |
+----+--------+------------+------------------------------+---------+-----------------+
|  1 | Juan   | Pérez      | juan.perez@empresa.com       | 3000.00 |               1 |
|  2 | María  | López      | maria.lopez@empresa.com      | 3500.00 |               2 |
|  3 | Carlos | Fernández  | carlos.fernandez@empresa.com | 4000.00 |               3 |
|  4 | Ana    | Gómez      | ana.gomez@empresa.com        | 3200.00 |               4 |
+----+--------+------------+------------------------------+---------+-----------------+
4 rows in set (0,000 sec)
```

Antes de esto, debemos crear una carpeta en la ruta `/var/lib/mysql`, la cual tendrá permisos adecuados para que el servicio de MariaDB pueda escribir los archivos.

```bash
pablo@servidor-mariadb:~$ cd /var/lib/mysql/
pablo@servidor-mariadb:/var/lib/mysql$ sudo mkdir datoscsv
pablo@servidor-mariadb:/var/lib/mysql$ sudo chown -R mysql:mysql datoscsv/
```

Ahora, para exportar las tablas a archivos CSV, ejecutamos el siguiente comando para cada una de las tablas:

```sql
MariaDB [empresa]> SELECT * FROM departamentos
    -> INTO OUTFILE '/var/lib/mysql/datoscsv/departamentos.csv'
    -> FIELDS TERMINATED BY ',' 
    -> ENCLOSED BY '"'
    -> LINES TERMINATED BY '\n';
Query OK, 4 rows affected, 1 warning (0,001 sec)

MariaDB [empresa]> SELECT * FROM empleados
    -> INTO OUTFILE '/var/lib/mysql/datoscsv/empleados.csv'
    -> FIELDS TERMINATED BY ',' 
    -> ENCLOSED BY '"'
    -> LINES TERMINATED BY '\n';
Query OK, 4 rows affected, 1 warning (0,001 sec)
```

Ambos archivos se guardan en la carpeta `/var/lib/mysql/datoscsv` anteriormente creada:

```bash
pablo@servidor-mariadb:~$ ls -lh /var/lib/mysql/datoscsv/
total 8,0K
-rw-r--r-- 1 mysql mysql 110 mar  2 17:18 departamentos.csv
-rw-r--r-- 1 mysql mysql 249 mar  2 17:18 empleados.csv
```

Una vez que tenemos los archivos CSV listos, debemos configurar SQLLoader para cargar estos datos en la base de datos Oracle. Para ello, debemos crear un archivo de control (`.ctl`), que es un archivo de configuración que le indica a SQLLoader cómo debe procesar los archivos de datos y cómo deben mapearse a las tablas de destino en Oracle.

Pero antes, debemos transferir los archivos a la máquina donde tenemos Oracle, pues son máquinas distintas:

```bash
pablo@servidor-mariadb:~$ scp /var/lib/mysql/datoscsv/* oracle@192.168.122.195:/home/oracle
oracle@192.168.122.195's password: 
departamentos.csv                                                                                                                          100%  110   286.3KB/s   00:00    
empleados.csv                                                                                                                              100%  249   790.8KB/s   00:00 
```

Una vez tenemos los ficheros aquí, tendremos que crear el archivo de control `departamentos.ctl`, el cual se utilizará para cargar los datos de la tabla departamentos en la base de datos Oracle.

```bash
oracle@oracle19c:~/datoscsv$ ls -lh
total 12K
-rw-r--r-- 1 oracle dba  110 mar  2 17:23 departamentos.csv
-rw-r--r-- 1 root   root 175 mar  2 17:26 departamentos.ctl
-rw-r--r-- 1 oracle dba  249 mar  2 17:23 empleados.csv
oracle@oracle19c:~/datoscsv$ cat departamentos.ctl 
LOAD DATA
INFILE '/home/oracle/datoscsv/departamentos.csv'
INTO TABLE departamentos
FIELDS TERMINATED BY ',' 
TRAILING NULLCOLS
(
  id,
  nombre,
  ubicacion
)
```

Donde:

- **LOAD DATA**: Inicia el proceso de carga de datos.
- **INFILE**: Especifica la ruta del archivo CSV con los datos.
- **INTO TABLE**: Especifica la tabla de destino en Oracle, en este caso, departamentos.
- **FIELDS TERMINATED BY**: Indica que los campos están separados por comas.
- **ENCLOSED BY**: Especifica que los campos están rodeados por comillas dobles.
- **LINES TERMINATED BY**: Indica que cada línea está terminada por un salto de línea.
- **(id, nombre, ubicacion)**: Especifica el orden de los campos en el archivo CSV y su correspondencia con las columnas de la tabla Oracle.

De manera similar, creamos el archivo de control `empleados.ctl` para la tabla empleados:

```bash
oracle@oracle19c:~/datoscsv$ cat empleados.ctl 
LOAD DATA
INFILE '/home/oracle/datoscsv/empleados.csv'
INTO TABLE empleados
FIELDS TERMINATED BY ',' 
TRAILING NULLCOLS
(
  id, 
  nombre, 
  apellido, 
  email, 
  salario   "TO_NUMBER(:salario, '9999.99')",
  departamento_id
)
```

Este archivo de control sigue la misma estructura, pero con los campos correspondientes para la tabla empleados en Oracle.

Antes de cargar los datos en la base de datos Oracle, tendremos que crear las tablas en Oracle con la misma estructura que las tablas de MariaDB, pero sin datos. 

```sql
oracle@oracle19c:~$ sqlplus loaderpavlo/password

SQL*Plus: Release 19.0.0.0.0 - Production on Sun Mar 2 17:32:56 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Hora de Ultima Conexion Correcta: Dom Mar 02 2025 16:56:58 +01:00

Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> CREATE TABLE departamentos (
  2      id NUMBER PRIMARY KEY,
  3      nombre VARCHAR2(50),
  4      ubicacion VARCHAR2(50)
  5  );


Tabla creada.

SQL> SQL> CREATE TABLE empleados (
  2      id NUMBER PRIMARY KEY,
  3      nombre VARCHAR2(50),
  4      apellido VARCHAR2(50),
  5      email VARCHAR2(100),
  6      salario NUMBER(10,2),
  7      departamento_id NUMBER,
  8      CONSTRAINT fk_departamento FOREIGN KEY (departamento_id)
  9          REFERENCES departamentos(id)
 10  );


Tabla creada.
```

Una vez que tenemos los archivos de control, podemos utilizar SQL*Loader para cargar los datos en Oracle:

```bash
oracle@oracle19c:~/datoscsv$ sqlldr userid=loaderpavlo/password control=departamentos.ctl log=departamentos.log

SQL*Loader: Release 19.0.0.0.0 - Production on Sun Mar 2 17:45:13 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Path used:      Conventional
Commit point reached - logical record count 4

Table DEPARTAMENTOS:
  4 Rows successfully loaded.

Check the log file:
  departamentos.log
for more information about the load.
```

Como podemos observar, el mensaje indica que las 4 filas del archivo CSV fueron cargadas correctamente. No hubo filas rechazadas ni errores durante la carga.

También podemos ver el archivo de log que se ha generado, donde nos muestra información adicional de la transacción:

```bash
oracle@oracle19c:~/datoscsv$ ls -lh
total 20K
-rw-r--r-- 1 oracle dba   86 mar  2 17:45 departamentos.csv
-rw-r--r-- 1 oracle dba  160 mar  2 17:38 departamentos.ctl
-rw-r--r-- 1 oracle dba 1,7K mar  2 17:45 departamentos.log
-rw-r--r-- 1 oracle dba  249 mar  2 17:23 empleados.csv
-rw-r--r-- 1 oracle dba  199 mar  2 17:29 empleados.ctl
oracle@oracle19c:~/datoscsv$ cat departamentos.log 

SQL*Loader: Release 19.0.0.0.0 - Production on Sun Mar 2 17:45:13 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Control File:   departamentos.ctl
Data File:      /home/oracle/datoscsv/departamentos.csv
  Bad File:     departamentos.bad
  Discard File:  none specified
 
 (Allow all discards)

Number to load: ALL
Number to skip: 0
Errors allowed: 50
Bind array:     250 rows, maximum of 1048576 bytes
Continuation:    none specified
Path used:      Conventional

Table DEPARTAMENTOS, loaded from every logical record.
Insert option in effect for this table: INSERT
TRAILING NULLCOLS option in effect

   Column Name                  Position   Len  Term Encl Datatype
------------------------------ ---------- ----- ---- ---- ---------------------
ID                                  FIRST     *   ,       CHARACTER            
NOMBRE                               NEXT     *   ,       CHARACTER            
UBICACION                            NEXT     *   ,       CHARACTER            


Table DEPARTAMENTOS:
  4 Rows successfully loaded.
  0 Rows not loaded due to data errors.
  0 Rows not loaded because all WHEN clauses were failed.
  0 Rows not loaded because all fields were null.


Space allocated for bind array:                 193500 bytes(250 rows)
Read   buffer bytes: 1048576

Total logical records skipped:          0
Total logical records read:             4
Total logical records rejected:         0
Total logical records discarded:        0

Run began on Sun Mar 02 17:45:13 2025
Run ended on Sun Mar 02 17:45:13 2025

Elapsed time was:     00:00:00.10
CPU time was:         00:00:00.03
```

Tras ejecutar el comando de carga, accedemos a la base de datos para consultar que se hayan importado correctamente los datos:

```sql
oracle@oracle19c:~/datoscsv$ sqlplus loaderpavlo/password

SQL*Plus: Release 19.0.0.0.0 - Production on Sun Mar 2 17:46:49 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Hora de Ultima Conexion Correcta: Dom Mar 02 2025 17:45:13 +01:00

Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> SELECT * FROM departamentos;

	ID
----------
NOMBRE
--------------------------------------------------------------------------------
UBICACION
--------------------------------------------------------------------------------
	 1
Recursos Humanos
Madrid

	 2
Finanzas
Barcelona

	ID
----------
NOMBRE
--------------------------------------------------------------------------------
UBICACION
--------------------------------------------------------------------------------

	 3
Desarrollo
Sevilla

	 4
Ventas

	ID
----------
NOMBRE
--------------------------------------------------------------------------------
UBICACION
--------------------------------------------------------------------------------
Valencia
```

Y como podemos ver, se han añadido correctamente los datos.

Ahora realizamos el mismo proceso pero con la tabla empleados:

```plaintext
SQL> SELECT * FROM empleados;

ninguna fila seleccionada

SQL> exit
Desconectado de Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0
oracle@oracle19c:~/datoscsv$ sqlldr userid=loaderpavlo/password control=empleados.ctl log=empleados.log

SQL*Loader: Release 19.0.0.0.0 - Production on Sun Mar 2 17:59:40 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Path used:      Conventional
Commit point reached - logical record count 4

Table EMPLEADOS:
  4 Rows successfully loaded.

Check the log file:
  empleados.log
for more information about the load.
oracle@oracle19c:~/datoscsv$ ls -lh
total 24K
-rw-r--r-- 1 oracle dba   86 mar  2 17:45 departamentos.csv
-rw-r--r-- 1 oracle dba  160 mar  2 17:38 departamentos.ctl
-rw-r--r-- 1 oracle dba 1,7K mar  2 17:45 departamentos.log
-rw-r--r-- 1 oracle dba  201 mar  2 17:57 empleados.csv
-rw-r--r-- 1 oracle dba  229 mar  2 17:59 empleados.ctl
-rw-r--r-- 1 oracle dba 2,0K mar  2 17:59 empleados.log
oracle@oracle19c:~/datoscsv$ cat empleados.log 

SQL*Loader: Release 19.0.0.0.0 - Production on Sun Mar 2 17:59:40 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Control File:   empleados.ctl
Data File:      /home/oracle/datoscsv/empleados.csv
  Bad File:     empleados.bad
  Discard File:  none specified
 
 (Allow all discards)

Number to load: ALL
Number to skip: 0
Errors allowed: 50
Bind array:     250 rows, maximum of 1048576 bytes
Continuation:    none specified
Path used:      Conventional

Table EMPLEADOS, loaded from every logical record.
Insert option in effect for this table: INSERT
TRAILING NULLCOLS option in effect

   Column Name                  Position   Len  Term Encl Datatype
------------------------------ ---------- ----- ---- ---- ---------------------
ID                                  FIRST     *   ,       CHARACTER            
NOMBRE                               NEXT     *   ,       CHARACTER            
APELLIDO                             NEXT     *   ,       CHARACTER            
EMAIL                                NEXT     *   ,       CHARACTER            
SALARIO                              NEXT     *   ,       CHARACTER            
    SQL string for column : "TO_NUMBER(:salario, '9999.99')"
DEPARTAMENTO_ID                      NEXT     *   ,       CHARACTER            


Table EMPLEADOS:
  4 Rows successfully loaded.
  0 Rows not loaded due to data errors.
  0 Rows not loaded because all WHEN clauses were failed.
  0 Rows not loaded because all fields were null.


Space allocated for bind array:                 387000 bytes(250 rows)
Read   buffer bytes: 1048576

Total logical records skipped:          0
Total logical records read:             4
Total logical records rejected:         0
Total logical records discarded:        0

Run began on Sun Mar 02 17:59:40 2025
Run ended on Sun Mar 02 17:59:40 2025

Elapsed time was:     00:00:00.10
CPU time was:         00:00:00.03
oracle@oracle19c:~/datoscsv$ sqlplus loaderpavlo/password

SQL*Plus: Release 19.0.0.0.0 - Production on Sun Mar 2 18:00:53 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Hora de Ultima Conexion Correcta: Dom Mar 02 2025 17:59:40 +01:00

Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> SELECT * FROM empleados;

	ID
----------
NOMBRE
--------------------------------------------------------------------------------
APELLIDO
--------------------------------------------------------------------------------
EMAIL
--------------------------------------------------------------------------------
   SALARIO DEPARTAMENTO_ID
---------- ---------------
	 1
Juan
P??rez

	ID
----------
NOMBRE
--------------------------------------------------------------------------------
APELLIDO
--------------------------------------------------------------------------------
EMAIL
--------------------------------------------------------------------------------
   SALARIO DEPARTAMENTO_ID
---------- ---------------
juan.perez@empresa.com
      3000		 1


	ID
----------
NOMBRE
--------------------------------------------------------------------------------
APELLIDO
--------------------------------------------------------------------------------
EMAIL
--------------------------------------------------------------------------------
   SALARIO DEPARTAMENTO_ID
---------- ---------------
	 2
Mar??a
L??pez

	ID
----------
NOMBRE
--------------------------------------------------------------------------------
APELLIDO
--------------------------------------------------------------------------------
EMAIL
--------------------------------------------------------------------------------
   SALARIO DEPARTAMENTO_ID
---------- ---------------
maria.lopez@empresa.com
      3500		 2


	ID
----------
NOMBRE
--------------------------------------------------------------------------------
APELLIDO
--------------------------------------------------------------------------------
EMAIL
--------------------------------------------------------------------------------
   SALARIO DEPARTAMENTO_ID
---------- ---------------
	 3
Carlos
Fern??ndez

	ID
----------
NOMBRE
--------------------------------------------------------------------------------
APELLIDO
--------------------------------------------------------------------------------
EMAIL
--------------------------------------------------------------------------------
   SALARIO DEPARTAMENTO_ID
---------- ---------------
carlos.fernandez@empresa.com
      4000		 3


	ID
----------
NOMBRE
--------------------------------------------------------------------------------
APELLIDO
--------------------------------------------------------------------------------
EMAIL
--------------------------------------------------------------------------------
   SALARIO DEPARTAMENTO_ID
---------- ---------------
	 4
Ana
G??mez

	ID
----------
NOMBRE
--------------------------------------------------------------------------------
APELLIDO
--------------------------------------------------------------------------------
EMAIL
--------------------------------------------------------------------------------
   SALARIO DEPARTAMENTO_ID
---------- ---------------
ana.gomez@empresa.com
      3200		 4
```

Se observa de nuevo que los datos han sido cargados correctamente en la tabla.