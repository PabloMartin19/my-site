---
title: "Auditoría"
date: 2025-02-25 20:00:00 +0000
categories: [Base de Datos]
tags: []
author: pablo
description: "..."
toc: true
comments: true
image:
  path: /assets/img/posts/auditoria/Database-Audit-in-SQL-Server-02.webp
---

## 1. Activa desde SQL*Plus la auditoría de los intentos de acceso no exitosos al sistema. Comprueba su funcionamiento.

Para activar la auditoría de los intentos de acceso no exitosos en Oracle, lo primero que haremos será comprobar si la auditoría está habilitada con el siguiente comando:

```sql
SELECT name, value 
FROM v$parameter 
WHERE name LIKE 'audit_trail';
```

Si la salida muestra:

![image](/assets/img/posts/auditoria/image1.png)

significa que la auditoría está activada a nivel de base de datos (`DB`). Si estuviera desactivada (`NONE`), tendríamos que activarla con:

```sql
ALTER SYSTEM SET audit_trail=DB SCOPE=SPFILE;
```

O si por el contrario queremos desactivarla por alguna razón, sería de la siguiente forma:

```sql
ALTER SYSTEM SET audit_trail=NONE SCOPE=SPFILE;
```

Para que la modificación sea efectiva, debemos reiniciar la base de datos:

```sql
SHUTDOWN IMMEDIATE;
STARTUP;
```

Una vez comprobado que tenemos activada la funcionalidad de auditorías, activamos la auditoría de intentos de acceso fallidos con:

```sql
AUDIT SESSION WHENEVER NOT SUCCESSFUL;
```

![image](/assets/img/posts/auditoria/IMAGE2.png)

Esto registrará en los logs de auditoría todos los intentos fallidos de inicio de sesión en la base de datos.

Para comprobar su funcionamiento, intentaré conectarme con credenciales incorrectas desde SQL*Plus:

![image](/assets/img/posts/auditoria/image3.png)

Después, verificamos los registros de auditoría con:

```sql
SELECT username, action_name, returncode 
FROM dba_audit_trail 
WHERE action_name = 'LOGON' 
ORDER BY timestamp DESC;
```

![image](/assets/img/posts/auditoria/image4.png)

Como vemos la salida indica que hubo un intento fallido de inicio de sesión (`LOGON`) con el usuario `USUARIO_NO_EXISTE`. El código de error `1017` significa "nombre de usuario o contraseña no válidos".

También podemos consultar los intentos de acceso fallidos utilizando la vista `DBA_AUDIT_SESSION`, que nos proporciona información detallada sobre las sesiones auditadas.

Si ejecutamos el siguiente comando:

```sql
SELECT OS_USERNAME, USERNAME, EXTENDED_TIMESTAMP, ACTION_NAME 
FROM DBA_AUDIT_SESSION;
```

obtendremos datos como el usuario del sistema operativo (`OS_USERNAME`), el usuario de la base de datos que intentó iniciar sesión (`USERNAME`), la marca de tiempo exacta del intento (`EXTENDED_TIMESTAMP`) y la acción realizada (`ACTION_NAME`).

Esta es la salida de ejemplo:

![image](/assets/img/posts/auditoria/image5.png)

## 2. Realiza un procedimiento en PL/SQL que te muestre los accesos fallidos junto con el motivo de los mismos, transformando el código de error almacenado en un mensaje de texto comprensible. Contempla todos los motivos posibles para que un acceso sea fallido.

Lo primero que deberíamos hacer es activar la auditoría de intentos de acceso fallidos, pero como en el ejercicio anterior ya lo hicimos, no es necesario.

Para realizar las comprobaciones, voy a provocar distintos accesos fallidos al sistema con usuarios y contraseñas que no existen:

![image](/assets/img/posts/auditoria/image6.png)

También, probaré con un usuario que sí existe pero no concuerda la contraseña:

![image](/assets/img/posts/auditoria/image7.png)

He creado una función llamada `obtener_motivo_error`, que recibe un código de error y devuelve un mensaje explicativo. He utilizado una estructura `CASE` para mostrar una descripción clara a cada código de error posible.

```sql
CREATE OR REPLACE FUNCTION obtener_motivo_error (codigo_error NUMBER) 
RETURN VARCHAR2
IS
    mensaje_error VARCHAR2(150);
BEGIN
    CASE codigo_error
        WHEN 911 THEN mensaje_error := 'El intento contiene caracteres no permitidos.';
        WHEN 1004 THEN mensaje_error := 'Acceso denegado.';
        WHEN 1017 THEN mensaje_error := 'Credenciales incorrectas.';
        WHEN 1033 THEN mensaje_error := 'El usuario no está registrado en la base de datos.';
        WHEN 1045 THEN mensaje_error := 'Falta el permiso CREATE SESSION.';
        WHEN 28000 THEN mensaje_error := 'Cuenta bloqueada por intentos fallidos.';
        WHEN 28001 THEN mensaje_error := 'La contraseña ha caducado, debe actualizarse.';
        WHEN 28002 THEN mensaje_error := 'Advertencia: la contraseña está próxima a caducar.';
        WHEN 28003 THEN mensaje_error := 'La contraseña no cumple los requisitos de seguridad.';
        WHEN 28007 THEN mensaje_error := 'Intento de reutilización de contraseña detectado.';
        WHEN 28008 THEN mensaje_error := 'Contraseña anterior incorrecta.';
        WHEN 28009 THEN mensaje_error := 'Conexión a SYS requiere privilegios SYSDBA o SYSOPER.';
        WHEN 28011 THEN mensaje_error := 'Cuenta a punto de expirar, se recomienda cambiar la contraseña.';
        WHEN 28511 THEN mensaje_error := 'Contraseña caducada, inicie sesión para restablecerla.';
        WHEN 28512 THEN mensaje_error := 'Cuenta bloqueada, contacte con el administrador.';
        ELSE mensaje_error := 'Error desconocido, contacte con soporte técnico.';
    END CASE;
    RETURN mensaje_error;
END obtener_motivo_error;
/
```

![image](/assets/img/posts/auditoria/image8.png)

Luego, he definido el procedimiento `listar_accesos_fallidos`, donde abro un cursor que selecciona los intentos de acceso fallidos desde `dba_audit_session`.

```sql
CREATE OR REPLACE PROCEDURE listar_accesos_fallidos
IS
    CURSOR cursor_accesos IS
        SELECT os_username, username, returncode, timestamp
        FROM dba_audit_session
        WHERE action_name = 'LOGON'
        AND returncode <> 0
        ORDER BY timestamp;
    motivo VARCHAR2(150);
BEGIN
    dbms_output.put_line('Lista de intentos de acceso fallidos:');
    FOR intento IN cursor_accesos LOOP
        motivo := obtener_motivo_error(intento.returncode);
        dbms_output.put_line('------------------------------------------------------------------------------------------------');
        dbms_output.put_line('Usuario SO: ' || intento.os_username || ' | Usuario BD: ' || intento.username || ' | Fecha: ' || TO_CHAR(intento.timestamp, 'YYYY/MM/DD HH24:MI') || ' | Motivo: ' || motivo);
    END LOOP;
END listar_accesos_fallidos;
/
```

![image](/assets/img/posts/auditoria/image9.png)

Hacemos la comprobación y vemos que funciona correctamente:

![image](/assets/img/posts/auditoria/image10.png)


## 3. Activa la auditoría de las operaciones DML realizadas por el usuario Prueba en tablas de su esquema. Comprueba su funcionamiento.

Primero, creamos el usuario PRUEBA y le asignamos una contraseña:

```sql
SQL> CREATE USER PRUEBA IDENTIFIED BY password;

Usuario creado.
```

Luego, le otorgamos los permisos necesarios para conectarse y gestionar sus propias tablas:

```sql
SQL> GRANT CONNECT, RESOURCE TO PRUEBA;

Concesión terminada correctamente.

SQL> ALTER USER PRUEBA QUOTA UNLIMITED ON USERS;

Usuario modificado.
```

A continuación, creamos una tabla de prueba dentro del esquema PRUEBA e insertamos algunos datos:

```sql
SQL> CREATE TABLE PRUEBA.CLIENTES (
  2      ID NUMBER PRIMARY KEY,
  3      NOMBRE VARCHAR2(100),
  4      EMAIL VARCHAR2(100),
  5      FECHA_REGISTRO DATE DEFAULT SYSDATE
  6  );

Tabla creada.
```

```sql
SQL> INSERT INTO PRUEBA.CLIENTES (ID, NOMBRE, EMAIL) VALUES (1, 'Chema García', 'chema@example.com');
INSERT INTO PRUEBA.CLIENTES (ID, NOMBRE, EMAIL) VALUES (2, 'Jesús Martín', 'jesús@example.com');
INSERT INTO PRUEBA.CLIENTES (ID, NOMBRE, EMAIL) VALUES (3, 'Roberto Carlos', 'roberto@example.com');

1 fila creada.

SQL> 
1 fila creada.

SQL> 
1 fila creada.
```

Para auditar todas las operaciones DML (INSERT, UPDATE y DELETE) realizadas por el usuario PRUEBA, ejecutamos:

```sql
AUDIT INSERT TABLE, UPDATE TABLE, DELETE TABLE BY PRUEBA BY ACCESS;
```

![image](/assets/img/posts/auditoria/image11.png)

Con esto, cada vez que PRUEBA realice una de estas operaciones, se registrará en la tabla de auditoría.

Para verificar si la auditoría está funcionando, nos conectamos con el usuario PRUEBA y realizamos algunas modificaciones en la tabla:

![image](/assets/img/posts/auditoria/image12.png)

Ahora, consultamos la tabla de auditoría específica de objetos para ver los registros de las operaciones DML realizadas por el usuario PRUEBA en sus tablas:

```sql
SELECT obj_name, action_name, extended_timestamp 
FROM dba_audit_object 
WHERE username = 'PRUEBA'
ORDER BY extended_timestamp DESC;
```

![image](/assets/img/posts/auditoria/image13.png)

Con esta consulta, obtenemos un listado detallado de las tablas modificadas, el tipo de acción ejecutada (**INSERT**, **UPDATE**, **DELETE**) y la fecha y hora exacta en que se realizaron.

De este modo, verificamos que la auditoría de operaciones DML en el esquema de **PRUEBA** está funcionando correctamente.

## 4. Realiza una auditoría de grano fino para almacenar información sobre la inserción de empleados con comisión en la tabla emp de scott.

Para realizar una auditoría de grano fino que registre las inserciones de empleados con comisión en la tabla **EMP** del usuario **SCOTT**, utilizamos el paquete `DBMS_FGA`. En este caso, en lugar de auditar por el salario, configuramos la auditoría para que registre cualquier inserción en la tabla **EMP** donde la columna **COMM** (comisión) no sea nula.

El siguiente bloque PL/SQL crea la política de auditoría:

```sql
BEGIN
  DBMS_FGA.ADD_POLICY (
    object_schema   => 'SCOTT',
    object_name     => 'EMP',
    policy_name     => 'comm_audit',
    audit_condition => 'COMM IS NOT NULL',
    statement_types => 'INSERT'
  );
END;
/
```

![image](/assets/img/posts/auditoria/image14.png)

Este código define una política llamada **comm_audit**, que auditará todas las inserciones (`INSERT`) en la tabla **EMP** cuando la columna **COMM** tenga un valor distinto de NULL.

Ahora nos conectamos con el usuario SCOTT y probamos la auditoría insertando un empleado con comisión (debería ser auditado) y un empleado sin comisión (no debería ser auditado):

```sql
SQL> INSERT INTO EMP VALUES (1600, 'Carlos', 'SALESMAN', 7698, TO_DATE('2025-02-25', 'YYYY-MM-DD'), 1800, 300, 30);

1 fila creada.

SQL> INSERT INTO EMP VALUES (1601, 'Ana', 'CLERK', 7782, TO_DATE('2025-02-25', 'YYYY-MM-DD'), 1200, NULL, 20);

1 fila creada.
```

Luego, consultamos la auditoría:

```sql
SELECT db_user, object_name, object_schema, sql_text, timestamp 
FROM dba_fga_audit_trail 
WHERE policy_name = 'COMM_AUDIT' 
ORDER BY timestamp;
```

![image](/assets/img/posts/auditoria/image15.png)

Y como podemos ver, solo se ha registrado la primera inserción, pues es la que sí tiene comisión.

## 5. Explica la diferencia entre auditar una operación by access o by session ilustrándolo con ejemplos.

Al auditar una operación **by access**, lo que estamos registrando es cada acceso que se hace a un objeto de la base de datos, sin importar si la sesión del usuario ha terminado o no. Esto significa que se genera un registro para cada acción que se realice, como **SELECT**, **INSERT**, **UPDATE** o **DELETE**. Por ejemplo, si configuramos la auditoría para el usuario SCOTT con el siguiente comando:

```sql
SQL> AUDIT INSERT TABLE, UPDATE TABLE, DELETE TABLE BY SCOTT BY ACCESS;

Auditoria terminada correctamente.
```

![image](/assets/img/posts/auditoria/image16.png)

Este comando registrará cada operación de INSERT, UPDATE y DELETE realizada por SCOTT sobre las tablas de la base de datos. Si SCOTT realiza las siguientes operaciones en una sesión:

INSERT:

```sql
SQL> INSERT INTO emp VALUES (1234, 'Juan', 'MANAGER', 7839, to_date('2024-02-25', 'YYYY-MM-DD'), 3000, null, 20);

1 fila creada.
```

DELETE:

```sql
SQL> DELETE FROM emp WHERE empno = 1234;

1 fila suprimida.
```

UPDATE:

```sql
SQL> UPDATE emp SET sal = 4500 WHERE empno = 7654;

1 fila actualizada.
```

![image](/assets/img/posts/auditoria/image17.png)


Al consultar la tabla de auditoría con el siguiente comando:

```sql
SELECT username, owner, obj_name, action, action_name, timestamp
FROM dba_audit_trail
WHERE username = 'SCOTT'
ORDER BY extended_timestamp DESC
FETCH FIRST 3 ROWS only;
```

Se generarán tres registros, uno por cada operación, con los siguientes datos:

![image](/assets/img/posts/auditoria/image18.png)

Cada operación (**INSERT**, **UPDATE**, **DELETE**) se registra por separado con un timestamp detallado.

Por otro lado, cuando auditamos **by session**, se genera un solo registro por sesión del usuario. Aunque dentro de esa sesión el usuario ejecute múltiples operaciones, solo se registrará una entrada para toda la sesión. Este forma es menos detallado, ya que no se registra cada operación individual, sino que se crea un único registro que agrupa todas las operaciones realizadas durante esa sesión.

Si configuramos la auditoría **by session** con el siguiente comando:

```sql
SQL> AUDIT INSERT TABLE, UPDATE TABLE, DELETE TABLE BY SCOTT BY SESSION;

Auditoria terminada correctamente.
```

![image](/assets/img/posts/auditoria/image19.png)

Este comando registrará solo una entrada por sesión del usuario SCOTT, sin importar cuántas operaciones realice en esa sesión. Si SCOTT ejecuta las siguientes operaciones dentro de una misma sesión:

INSERT:

```sql
SQL> INSERT INTO emp VALUES (7777, 'Torrente', 'MANAGER', 7839, to_date('2025-02-25', 'YYYY-MM-DD'), 3000, null, 20);

1 fila creada.
```

DELETE:

```sql
SQL> DELETE FROM emp WHERE empno = 7777;

1 fila suprimida.
```

UPDATE:

```sql
SQL> UPDATE emp SET sal = 4500 WHERE empno = 7654;

1 fila actualizada.
```

![image](/assets/img/posts/auditoria/image20.png)

Al consultar la tabla de auditoría para la sesión de SCOTT, se generará solo un registro de auditoría que reflejará que se inició una sesión y se realizaron operaciones, pero no se detallarán de manera individual. Lo vemos a continuación:

```sql
SELECT USERNAME,ACTION_NAME,TIMESTAMP, obj_name 
FROM DBA_AUDIT_OBJECT 
WHERE USERNAME='SCOTT';
```

![image](/assets/img/posts/auditoria/image21.png)
![image](/assets/img/posts/auditoria/image22.png)

Esto indica que SCOTT inició una sesión y realizó varias operaciones, pero no las desglosa. El número de ACTION puede variar, pero se registrará solo una vez por sesión.

## 6. Documenta las diferencias entre los valores db y db, extended del parámetro audit_trail de ORACLE. Demuéstralas poniendo un ejemplo de la información sobre una operación concreta recopilada con cada uno de ellos.

En Oracle, el parámetro `audit_trail` controla la configuración de la auditoría. Existen dos valores principales para este parámetro: **db** y **db, extended**, que se diferencian en el nivel de detalle que almacenan durante el proceso de auditoría.

- **db**: Este valor permite auditar las operaciones en la base de datos, pero sin almacenar información detallada sobre los **bind variables** y el **SQL ejecutado**. Solo se guarda la información básica de la operación, como el nombre de la tabla, la acción realizada y la hora del evento.

- **db, extended**: Este valor, en cambio, almacena un nivel de auditoría mucho más detallado. No solo guarda la información básica de la operación, sino que también captura el **SQL ejecutado** (el código SQL original) y las **bind variables** que fueron utilizadas en la operación. Esto proporciona un nivel de detalle mucho mayor, lo que es útil para auditar con precisión las acciones realizadas.

### db

Para ver el valor por defecto de `audit_trail`, deberemos ejecutar la siguiente consulta:

```sql
SHOW PARAMETER audit_trail;
```

![image](/assets/img/posts/auditoria/image23.png)

Como podemos ver, el valor por defecto es "DB". Si el valor de `audit_trail` es **db**, entonces solo se almacenará la información básica de las operaciones. 

Podemos consultar la información que hemos recopilado a través de la auditoría de la base de datos utilizando la consulta correspondiente del ejercicio 3.

```sql
SELECT obj_name, action_name, extended_timestamp 
FROM dba_audit_object 
WHERE username = 'PRUEBA'
ORDER BY extended_timestamp DESC;
```

![image](/assets/img/posts/auditoria/image24.png)

Podemos ver que todos estos datos están almacenados mediante auditoría db.

### db, extended

Para cambiar el parámetro a **db, extended** y habilitar la auditoría extendida, usamos el siguiente comando:

```sql
ALTER SYSTEM SET audit_trail = DB,EXTENDED SCOPE=SPFILE;
```

Luego, debemos reiniciar la base de datos para que los cambios tengan efecto:

```sql
SHUTDOWN IMMEDIATE;
STARTUP;
SHOW PARAMETER audit_trail;
```

![image](/assets/img/posts/auditoria/image25.png)

Para ver cómo se registran las operaciones con la auditoría db, extended, realizaremos algunas acciones sobre una tabla. En este caso, creamos una tabla de prueba y ejecutamos varias operaciones sobre ella (insertar, actualizar y eliminar). Los comandos son los siguientes:

```sql
CONNECT scott/tiger;

CREATE TABLE EMPLOYEES (
    EMP_ID NUMBER(10) NOT NULL,
    EMP_NAME VARCHAR2(50) NOT NULL,
    EMP_SALARY NUMBER(8, 2) NOT NULL,
    PRIMARY KEY (EMP_ID)
);

INSERT INTO EMPLOYEES VALUES (101, 'Alice', 5000);

UPDATE EMPLOYEES SET EMP_SALARY = 5500 WHERE EMP_ID = 101;

DELETE FROM EMPLOYEES WHERE EMP_ID = 101;
```

![image](/assets/img/posts/auditoria/image26.png)

Para ver los registros con el nivel extendido de auditoría, ejecutamos la siguiente consulta:

```sql
SELECT USERNAME, ACTION_NAME, TIMESTAMP, OBJ_NAME, SQL_TEXT, SQL_BIND
FROM DBA_AUDIT_OBJECT
WHERE USERNAME = 'SCOTT'
ORDER BY TIMESTAMP DESC;
```

Con la auditoría **db, extended** activada, veremos que la salida no solo incluirá la información básica (como el nombre de la tabla, la acción realizada y el timestamp), sino también:

- **SQL_TEXT**: El SQL que fue ejecutado. Esto incluye las instrucciones SQL completas.
- **SQL_BIND**: Las bind variables utilizadas en la operación, lo cual nos da información detallada sobre los valores reales procesados por la base de datos.

Esta es la salida que recibimos de la auditoría:

![image](/assets/img/posts/auditoria/image27.png)
![image](/assets/img/posts/auditoria/image28.png)
![image](/assets/img/posts/auditoria/image29.png)

## 7. Averigua si en Postgres se pueden realizar los cuatro primeros apartados. Si es así, documenta el proceso adecuadamente.

Para auditar eventos en PostgreSQL, existen diversas herramientas, entre ellas `pgAudit` y `Audit Trigger`. En este caso, utilizaremos `Audit Trigger`, que permite registrar cambios en las tablas de la base de datos de forma sencilla.

He decidido instalar esta funcionalidad en la base de datos postgres, aunque podría implementarse en cualquier otra base de datos dentro del servidor.

El proceso de instalación es bastante simple. En primer lugar, descargamos el archivo SQL necesario desde el repositorio oficial con el siguiente comando:

```bash
wget https://raw.githubusercontent.com/2ndQuadrant/audit-trigger/master/audit.sql
```

Una vez descargado, accedemos al servidor PostgreSQL con el usuario postgres y ejecutamos el script SQL para instalar la extensión:

```bash
sudo -u postgres psql
\i audit.sql
```

![image](/assets/img/posts/auditoria/image30.png)

La salida indica que el script `audit.sql` ha creado la extensión, el esquema y varias estructuras necesarias para la auditoría, como tablas, índices, funciones y vistas. Además, se han aplicado restricciones de permisos (`REVOKE`) y comentarios (`COMMENT`) para documentar los elementos creados.

### Ejercicio 1: Auditoría de accesos fallidos

Para realizar una auditoría que registre los intentos de acceso fallidos en PostgreSQL, tendremos que configurar el sistema de logs de la base de datos para que almacene este tipo de eventos. PostgreSQL nos da varios parámetros que controlan la generación de registros relacionados con las conexiones y la autenticación.

El primer paso es habilitar el registro de conexiones en el sistema. Para ello, desde la consola de PostgreSQL, ejecutamos el siguiente comando:

```sql
postgres=# ALTER SYSTEM SET log_connections = 'ON';
ALTER SYSTEM
```

Esto permite que PostgreSQL registre cada intento de conexión al servidor, lo que incluye tanto los accesos exitosos como los fallidos. 

Tras aplicar estos cambios, reiniciamos el servicio de PostgreSQL para que la configuración tenga efecto:

```bash
pablo@servidor-postgre1:~$ sudo systemctl restart postgresql
```

Una vez reiniciado, los eventos de autenticación se almacenarán en el archivo de logs de PostgreSQL:

```bash
tail -f /var/log/postgresql/postgresql-15-main.log
```

A continuación, se muestra un ejemplo de un intento de conexión fallido debido a una autenticación incorrecta:

![image](/assets/img/posts/auditoria/image32.png)

Aquí, el mensaje **"FATAL: la autentificación password falló para el usuario «pablomh»"** nos dice que hubo un intento de conexión fallido debido a una contraseña incorrecta. Además, la línea **"DETALLE: La conexión coincidió con la línea 98 de pg_hba.conf"** dice que la autenticación se realizó según la configuración establecida en el archivo `pg_hba.conf`, donde se especifica el método de autenticación `md5`.

### Ejercicio 2: Accesos fallidos junto al motivo

Pues al igual que en el ejercicio anterior, podemos revisar los logs y este nos dirá el motivo del acceso fallido. Aquí un ejemplo:

![image](/assets/img/posts/auditoria/image33.png)

### Ejercicio 3: Operaciones DML

Para llevar a cabo la auditoría de DML, utilizaremos la extensión **Audit Trigger**. Para ello, primero crearemos una tabla en la base de datos de Postgres. Luego, procederemos a insertar, actualizar y eliminar datos dentro de la base de datos SCOTT.

```sql
postgres=# INSERT INTO DEPT VALUES (100, 'VENTAS', 'SEVILLA');
INSERT INTO DEPT VALUES (110, 'COMPRAS', 'CADIZ');
INSERT INTO DEPT VALUES (120, 'CONTABILIDAD', 'GRANADA');
INSERT INTO DEPT VALUES (130, 'VENTAS', 'HUELVA');
    
DELETE FROM DEPT WHERE DEPTNO = 100;
DELETE FROM DEPT WHERE DEPTNO = 110;
DELETE FROM DEPT WHERE DEPTNO = 120;
DELETE FROM DEPT WHERE DEPTNO = 130;

UPDATE DEPT SET LOC = 'SEVILLA' WHERE DEPTNO = 10;
UPDATE DEPT SET LOC = 'CADIZ' WHERE DEPTNO = 20;
UPDATE DEPT SET LOC = 'GRANADA' WHERE DEPTNO = 30;
UPDATE DEPT SET LOC = 'HUELVA' WHERE DEPTNO = 40;
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
DELETE 1
DELETE 1
DELETE 1
DELETE 1
UPDATE 1
UPDATE 1
UPDATE 1
UPDATE 1
```

Una vez que hayamos realizado las operaciones de inserción, actualización y eliminación, procederemos a verificar la extensión Audit Trigger para asegurarnos de que la auditoría se ha ejecutado correctamente. Esto nos permitirá confirmar que las acciones realizadas sobre la base de datos han sido registradas adecuadamente, lo cual es fundamental para revisar el historial de cambios y asegurar la integridad de las operaciones realizadas.

```sql
SELECT audit.audit_table('DEPT');
```

![image](/assets/img/posts/auditoria/image34.png)

Para poder ver los datos de la auditoría, primero nos conectaremos a la base de datos como el usuario postgres. Una vez dentro de la base de datos que estamos auditando, ejecutaremos la consulta correspondiente para visualizar los registros generados por la extensión Audit Trigger. Esto nos permitirá revisar las auditorías de las operaciones DML (inserciones, actualizaciones y eliminaciones) realizadas.

La consulta que debemos ejecutar:

```sql
SELECT session_user_name, action, table_name, action_tstamp_clk, client_query 
FROM audit.logged_actions;
```

![image](/assets/img/posts/auditoria/image35.png)

Como se puede apreciar en la imagen, la información registrada por la auditoría incluye varios detalles clave. Entre ellos, podemos observar el nombre del usuario que ejecutó la acción, el tipo de operación realizada (ya sea un **Insert**, **Update** o **Delete**), la tabla sobre la cual se ejecutó la acción, así como la fecha y la hora exacta en la que se llevó a cabo la operación. Además, también se muestra la consulta SQL que fue ejecutada para realizar la acción, lo que proporciona una trazabilidad completa de las operaciones realizadas en la base de datos.

### Ejercicio 4: Auditoría grano fino

Lo primero que necesitamos hacer es crear una tabla para almacenar la información sobre las inserciones que queremos auditar. En esta tabla vamos a registrar el usuario que realizó la inserción, el nombre de la tabla afectada, el esquema de la tabla, la operación realizada y la fecha y hora de la operación. Para esto, usamos el siguiente comando:

```sql
CREATE TABLE public.audit_emp_commission (
    id SERIAL PRIMARY KEY,
    db_user VARCHAR(50),
    object_name VARCHAR(50),
    object_schema VARCHAR(50),
    operation VARCHAR(10),
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

![image](/assets/img/posts/auditoria/image37.png)

Con esta tabla creamos el esquema básico para registrar las operaciones que vamos a auditar, en este caso, las inserciones de empleados con comisión.

Luego, necesitamos crear una función que se activará cuando se inserte un registro en la tabla `emp`. La función verificará si el campo `comm` (comisión) del nuevo registro es diferente de NULL. Si tiene comisión, insertará un registro en la tabla de auditoría con la información relevante.

La función se escribe así:

```sql
CREATE OR REPLACE FUNCTION public.audit_emp_commission()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.comm IS NOT NULL THEN
        INSERT INTO public.audit_emp_commission (
            db_user,
            object_name,
            object_schema,
            operation
        ) VALUES (
            CURRENT_USER,
            TG_TABLE_NAME,
            TG_TABLE_SCHEMA,
            TG_OP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

![image](/assets/img/posts/auditoria/image36.png)

En esta función, el `IF NEW.comm IS NOT NULL` nos asegura que solo se registre la operación si el campo `comm` (comisión) no es nulo, es decir, si el empleado tiene una comisión.


Con la función lista, necesitamos crear un trigger que se active después de cada inserción en la tabla emp. El trigger llamará a la función de auditoría para registrar la operación en la tabla de auditoría cuando se inserte un empleado con una comisión.

```sql
CREATE OR REPLACE TRIGGER emp_commission_audit_trigger
AFTER INSERT ON public.emp
FOR EACH ROW
EXECUTE FUNCTION public.audit_emp_commission();
```

![image](/assets/img/posts/auditoria/image38.png)

Este trigger se ejecutará después de cada inserción en la tabla `emp`, y si la inserción es de un empleado con una comisión, la función de auditoría insertará un registro en la tabla `audit_emp_commission`.

Ahora, podemos probar que todo funciona correctamente. Vamos a insertar un nuevo empleado en la tabla emp que tenga una comisión. Por ejemplo:

```sql
INSERT INTO public.emp (empno, ename, job, mgr, hiredate, sal, comm, deptno)
VALUES (1001, 'Juan', 'CLERK', 7839, '2025-02-25', 1800, 300, 30);
```

Finalmente, para ver si la auditoría se ha realizado correctamente, podemos consultar la tabla de auditoría. Ejecutamos la siguiente consulta:

```sql
SELECT * FROM public.audit_emp_commission;
```

![image](/assets/img/posts/auditoria/image39.png)

Con esto, hemos configurado la auditoría para registrar todas las inserciones de empleados con comisión en la tabla `emp` del esquema `scott`. Cada vez que se inserte un nuevo empleado con comisión, se registrará una entrada en la tabla de auditoría.

## 8. Averigua si en MySQL se pueden realizar los apartados 1, 3 y 4. Si es así, documenta el proceso adecuadamente.

Para llevar a cabo una auditoría en MySQL, necesitaremos crear dos bases de datos. La auditoría se realizará utilizando el plugin *server_audit*, el cual nos permite registrar y monitorear las acciones que se ejecutan en el servidor de MySQL.

Para instalar este plugin, debemos ejecutar el comando `INSTALL SONAME 'server_audit';` mientras estamos conectados al servidor de bases de datos.

![image](/assets/img/posts/auditoria/image40.png)

### Ejercicio 1: Auditoría de accesos fallidos

Una vez instalado el plugin, será necesario modificar el archivo de configuración de MySQL. Este archivo se encuentra en la ruta `/etc/mysql/mariadb.conf.d/50-server.cnf`. En él, deberemos realizar las configuraciones necesarias para habilitar y personalizar el comportamiento del plugin de auditoría, asegurándonos de que las acciones de auditoría sean registradas adecuadamente según nuestras necesidades.

![image](/assets/img/posts/auditoria/image41.png)

Ahora voy a crear un directorio para almacenar logs, asignar los permisos necesarios para que el servidor de bases de datos pueda escribir en ese directorio y, por último, reiniciar el servicio de MariaDB para que los cambios tengan efecto.

```bash
pablo@servidor-mariadb:~$ sudo mkdir /var/log/mysql/
pablo@servidor-mariadb:~$ sudo chown mysql: /var/log/mysql/
pablo@servidor-mariadb:~$ sudo systemctl restart mariadb.service
```

Después de reiniciar el servicio, verificaremos que la auditoría esté funcionando correctamente. Para esto, realizaremos intentos de acceso fallidos y exitosos, y así comprobar que se registre todo adecuadamente.

![image](/assets/img/posts/auditoria/image42.png)

### Ejercicio 3: Operaciones DML

Este este ejercicio hay que modificar el archivo de configuración de MySQL/MariaDB, que se encuentra en la ruta `/etc/mysql/mariadb.conf.d/50-server.cnf`. Una vez dentro tendremos que añadir las siguientes líneas:

```bash
server_audit_events=CONNECT,QUERY,TABLE
server_audit_logging=ON
server_audit_incl_users=scott
server_audit_file_path=/var/log/mysql/audit.log
```

![image](/assets/img/posts/auditoria/image43.png)

Después de modificar el fichero de configuración, tendremos que reiniciar el servicio:

```bash
pablo@servidor-mariadb:~$ sudo systemctl restart mariadb.service
```

Para las pruebas utilizaré las tablas del esquema [scott](https://github.com/PabloMartin19/schema_scott/blob/main/scott.sql).

Por lo que accedemos con el usuario scott que es el que contiene las tablas, y realizamos alguna operación para que se registren:

```sql
INSERT INTO scott.emp VALUES(7777, 'JACINTO', 'CAUDILLO', 7902, '2025-02-26', 999, NULL, 10);
UPDATE scott.emp SET sal = 1509 WHERE empno = 7777;
DELETE FROM scott.emp WHERE empno = 7777;
```

![image](/assets/img/posts/auditoria/image44.png)

Una vez realizadas las operaciones, nos salimos y miramos el log:

![image](/assets/img/posts/auditoria/image45.png)

Donde podemos observar que se han registrado correctamente.

### Ejercicio 4: Auditoría grano fino

Para la auditoría que registre la inserción de empleados con comisión en la tabla emp de la base de datos scott, 
tendremos que crear una tabla de auditoría. Esta tabla almacenará información clave como el identificador del empleado, su nombre, el monto de la comisión, el momento en que se realizó la inserción y el tipo de acción registrada.

La estructura de la tabla de auditoría se define de la siguiente manera:

```sql
CREATE TABLE scott.emp_auditoria (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    empno INT,
    ename VARCHAR(10),
    comm DECIMAL(7,2),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action_type VARCHAR(10)
);
```

![image](/assets/img/posts/auditoria/image46.png)

Una vez creada la tabla, el siguiente paso es configurar un **trigger** que se active cada vez que se realice una inserción en la 
tabla `emp`. Este trigger verificará si el campo `comm` tiene un valor distinto de `NULL`, lo que indicaría que el empleado 
recibe una comisión. En caso afirmativo, se insertará un nuevo registro en `emp_auditoria` con los datos correspondientes.

El trigger se define de la siguiente forma:

```sql
DELIMITER $$

CREATE TRIGGER audit_emp_insercion
AFTER INSERT ON scott.emp
FOR EACH ROW
BEGIN
    IF NEW.comm IS NOT NULL THEN
        INSERT INTO scott.emp_auditoria (empno, ename, comm, action_type)
        VALUES (NEW.empno, NEW.ename, NEW.comm, 'INSERT');
    END IF;
END $$

DELIMITER ;
```

![image](/assets/img/posts/auditoria/image47.png)

Después de crear el trigger, es momento de comprobar su funcionamiento insertando algunos empleados en la tabla `emp`. Por ejemplo:

```sql
INSERT INTO scott.emp VALUES (7904, 'ERWIN', 'SMITH', 7839, '1981-05-15', 3500, 600, 20);
INSERT INTO scott.emp VALUES (7901, 'MIKASA', 'ACKERMAN', 7839, '1981-06-10', 3200, 450, 30);
INSERT INTO scott.emp VALUES (7905, 'KIPSTA', 'ACKERMAN', 7839, '1981-07-20', 3300, 550, 40);
```

Ahora, si consultamos la tabla `emp_auditoria`, deberíamos ver que los registros de los empleados con comisión han sido almacenados correctamente:

```sql
SELECT * FROM scott.emp_auditoria;
```

![image](/assets/img/posts/auditoria/image48.png)

De este modo, se confirma que la auditoría funciona correctamente, registrando únicamente aquellos empleados que tienen una comisión asignada.

## 9. Averigua las posibilidades que ofrece MongoDB para auditar los cambios que va sufriendo un documento. Demuestra su funcionamiento.

Para auditar los cambios que sufren los documentos en MongoDB, necesitaremos la versión **Enterprise**, ya que solo esta edición permite habilitar la auditoría de eventos. Para la instalación de esta versión he seguido la [página oficial](https://www.mongodb.com/pt-br/docs/manual/tutorial/install-mongodb-enterprise-on-debian/#install-mongodb-enterprise-edition):

Una vez tengamos esta versión instalada, podemos configurar MongoDB para registrar todas las operaciones que se realicen sobre la base de datos. Aquí la comprobación de que realmente tenemos instalado la versión Enterprise:

```bash
vagrant@mongo:~$ mongod --version
db version v8.0.5
Build Info: {
    "version": "8.0.5",
    "gitVersion": "cb9e2e5e552ee39dea1e39d7859336456d0c9820",
    "openSSLVersion": "OpenSSL 3.0.15 3 Sep 2024",
    "modules": [
        "enterprise"
    ],
    "allocator": "tcmalloc-google",
    "environment": {
        "distmod": "debian12",
        "distarch": "x86_64",
        "target_arch": "x86_64"
    }
}
```

MongoDB nos ofrece cuatro formas de almacenar los registros de auditoría: podemos enviarlos directamente a la consola, redirigirlos al **syslog**, guardarlos en un archivo en formato **JSON** o **BSON**, o configurar la auditoría a través del archivo de configuración de MongoDB.

Si queremos ver los registros en la consola mientras ejecutamos MongoDB, podemos iniciar el servicio con:

```bash
mongod --dbpath data/db --auditDestination console
```

Si preferimos que los eventos queden almacenados en el syslog, usamos:

```bash
mongod --dbpath data/db --auditDestination syslog
```

En caso de querer registrar los eventos en un archivo JSON o BSON, podemos utilizar las siguientes opciones:

```bash
mongod --dbpath data/db --auditDestination file --auditFormat JSON --auditPath data/db/auditLog.json
mongod --dbpath data/db --auditDestination file --auditFormat BSON --auditPath data/db/auditLog.bson
```

También podemos configurar la auditoría desde el archivo de configuración de MongoDB (`/etc/mongod.conf`). En nuestro caso, optaremos por almacenar los registros en un archivo **JSON** para facilitar su lectura y análisis. Para ello, editamos el archivo de configuración:

```bash
nano /etc/mongod.conf
```

Y añadimos la siguiente configuración:

```bash
auditLog:
  destination: file
  format: JSON
  path: /var/log/mongodb/auditLog.json
```

Con esto, MongoDB registrará información detallada sobre los cambios que se realicen en los documentos. Para aplicar los cambios, reiniciamos el servicio:

```bash
sudo systemctl restart mongod
```

Antes de comenzar a trabajar con los registros de auditoría, instalaremos jq, una herramienta que nos ayudará a visualizar los archivos JSON desde la terminal:

```bash
sudo apt install jq -y
```

**Creación de una colección y prueba de auditoría**

Primero, vamos a crear una colección llamada "productos", donde definiremos un esquema que validará ciertos campos para asegurar que se ingresen correctamente los datos. En este caso, vamos a exigir que cada producto tenga un código de producto, un nombre, una categoría, y un precio. Los datos deben cumplir con ciertas reglas de longitud para cada campo.

```js
db.createCollection("productos", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["codigo_producto", "nombre", "categoria", "precio"],
            properties: {
                codigo_producto: { bsonType: "string", maxLength: 10 },
                nombre: { bsonType: "string", maxLength: 100 },
                categoria: { bsonType: "string", maxLength: 50 },
                precio: { bsonType: "double" }
            }
        }
    }
})
```

![image](/assets/img/posts/auditoria/image49.png)

Cuando creamos la colección con éxito, esta configuración asegura que solo se puedan insertar documentos que tengan estos campos obligatorios y dentro de los límites establecidos.

**Insertar datos en la colección**

A continuación, insertamos varios productos en la colección productos. Para ello, vamos a insertar algunos documentos representando distintos productos disponibles en la tienda, con su código, nombre, categoría y precio.

```js
db.productos.insertMany([
  { codigo_producto: "A001", nombre: "Camiseta Roja", categoria: "Ropa", precio: 19.99 },
  { codigo_producto: "B002", nombre: "Zapatos de Cuero", categoria: "Calzado", precio: 49.99 },
  { codigo_producto: "C003", nombre: "Gafas de Sol", categoria: "Accesorios", precio: 25.50 },
  { codigo_producto: "D004", nombre: "Chaqueta de Invierno", categoria: "Ropa", precio: 89.99 }
])
```

![image](/assets/img/posts/auditoria/image50.png)

Con estos documentos insertados, hemos registrado una pequeña parte de los productos disponibles en nuestra tienda.

**Realizar cambios en los documentos**

Vamos a actualizar el precio de un producto, por ejemplo, de "Camiseta Roja" de **19.99** a **18.99**.

```js
db.productos.updateOne(
   { codigo_producto: "A001" },
   { $set: { precio: 18.99 } }
)
```

![image](/assets/img/posts/auditoria/image51.png)

Eliminamos el producto con el código de producto "C003" (las gafas de sol):

```js
db.productos.deleteOne({ codigo_producto: "C003" })
```

![image](/assets/img/posts/auditoria/image52.png)

**Crear un rol y un usuario**

En este caso, vamos a crear un rol de solo lectura para la colección **productos**, para que los usuarios con este rol solo puedan consultar los productos, pero no realizar modificaciones. A continuación, creamos un rol llamado "**lectura_productos**" y luego asignamos ese rol a un usuario llamado "**juan**".

Creamos el rol lectura_productos:

```js
db.createRole({
    role: "lectura_productos",
    privileges: [
        {
            resource: { db: "productos", collection: "productos" },
            actions: [ "find" ]
        }
    ],
    roles: []
})
```

![image](/assets/img/posts/auditoria/image53.png)

Creamos el usuario pavlo con el rol lectura_productos:

```js
db.createUser({
    user: "pavlo",
    pwd: "pavlo1234",
    roles: ["lectura_productos"]
})
```

![image](/assets/img/posts/auditoria/image54.png)

Finalmente, una vez que tenemos los datos insertados, los cambios realizados, y el rol/usuario configurado, podemos empezar a revisar los registros de auditoría.

Abrimos el archivo de auditoría en tiempo real usando jq para visualizar los eventos en formato JSON, lo cual nos permite filtrar y entender las operaciones más fácilmente:


```js
vagrant@mongo:~$ sudo tail -f /var/log/mongodb/auditLog.json | jq
{
  "atype": "createIndex",
  "ts": {
    "$date": "2025-02-27T12:15:49.008+00:00"
  },
  "uuid": {
    "$binary": "Gm0NSSdOSuKmDjXIQV/xrw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42096
  },
  "users": [],
  "roles": [],
  "param": {
    "ns": "admin.system.roles",
    "indexName": "role_1_db_1",
    "indexSpec": {
      "v": 2,
      "unique": true,
      "key": {
        "role": 1,
        "db": 1
      },
      "name": "role_1_db_1"
    },
    "indexBuildState": "IndexBuildStarted"
  },
  "result": 0
}
{
  "atype": "createIndex",
  "ts": {
    "$date": "2025-02-27T12:15:49.013+00:00"
  },
  "uuid": {
    "$binary": "Gm0NSSdOSuKmDjXIQV/xrw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42096
  },
  "users": [],
  "roles": [],
  "param": {
    "ns": "admin.system.roles",
    "indexName": "role_1_db_1",
    "indexSpec": {
      "v": 2,
      "unique": true,
      "key": {
        "role": 1,
        "db": 1
      },
      "name": "role_1_db_1"
    },
    "indexBuildState": "IndexBuildSucceeded"
  },
  "result": 0
}
{
  "atype": "directAuthMutation",
  "ts": {
    "$date": "2025-02-27T12:15:49.013+00:00"
  },
  "uuid": {
    "$binary": "Gm0NSSdOSuKmDjXIQV/xrw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42096
  },
  "users": [],
  "roles": [],
  "param": {
    "document": {
      "_id": "admin.lectura_productos",
      "role": "lectura_productos",
      "db": "admin",
      "privileges": [
        {
          "resource": {
            "db": "productos",
            "collection": "productos"
          },
          "actions": [
            "find"
          ]
        }
      ],
      "roles": []
    },
    "ns": "admin.system.roles",
    "operation": "insert"
  },
  "result": 0
}
{
  "atype": "clientMetadata",
  "ts": {
    "$date": "2025-02-27T12:15:56.587+00:00"
  },
  "uuid": {
    "$binary": "lANCxt3YT3O6RPm1/w9kWw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 33144
  },
  "users": [],
  "roles": [],
  "param": {
    "localEndpoint": {
      "ip": "127.0.0.1",
      "port": 27017
    },
    "clientMetadata": {
      "application": {
        "name": "mongosh 2.4.0"
      },
      "driver": {
        "name": "nodejs|mongosh",
        "version": "6.13.0|2.4.0"
      },
      "platform": "Node.js v20.18.3, LE",
      "os": {
        "name": "linux",
        "architecture": "x64",
        "version": "3.10.0-327.22.2.el7.x86_64",
        "type": "Linux"
      }
    }
  },
  "result": 0
}
{
  "atype": "createUser",
  "ts": {
    "$date": "2025-02-27T12:16:46.226+00:00"
  },
  "uuid": {
    "$binary": "Gm0NSSdOSuKmDjXIQV/xrw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42096
  },
  "users": [],
  "roles": [],
  "param": {
    "user": "pavlo",
    "db": "admin",
    "roles": [
      {
        "role": "lectura_productos",
        "db": "admin"
      }
    ]
  },
  "result": 0
}
{
  "atype": "createCollection",
  "ts": {
    "$date": "2025-02-27T12:16:46.226+00:00"
  },
  "uuid": {
    "$binary": "Gm0NSSdOSuKmDjXIQV/xrw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42096
  },
  "users": [],
  "roles": [],
  "param": {
    "ns": "admin.system.users"
  },
  "result": 0
}
{
  "atype": "createIndex",
  "ts": {
    "$date": "2025-02-27T12:16:46.241+00:00"
  },
  "uuid": {
    "$binary": "Gm0NSSdOSuKmDjXIQV/xrw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42096
  },
  "users": [],
  "roles": [],
  "param": {
    "ns": "admin.system.users",
    "indexName": "_id_",
    "indexSpec": {
      "v": 2,
      "key": {
        "_id": 1
      },
      "name": "_id_"
    },
    "indexBuildState": "IndexBuildStarted"
  },
  "result": 0
}
{
  "atype": "createIndex",
  "ts": {
    "$date": "2025-02-27T12:16:46.246+00:00"
  },
  "uuid": {
    "$binary": "Gm0NSSdOSuKmDjXIQV/xrw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42096
  },
  "users": [],
  "roles": [],
  "param": {
    "ns": "admin.system.users",
    "indexName": "_id_",
    "indexSpec": {
      "v": 2,
      "key": {
        "_id": 1
      },
      "name": "_id_"
    },
    "indexBuildState": "IndexBuildSucceeded"
  },
  "result": 0
}
{
  "atype": "createIndex",
  "ts": {
    "$date": "2025-02-27T12:16:46.246+00:00"
  },
  "uuid": {
    "$binary": "Gm0NSSdOSuKmDjXIQV/xrw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42096
  },
  "users": [],
  "roles": [],
  "param": {
    "ns": "admin.system.users",
    "indexName": "user_1_db_1",
    "indexSpec": {
      "v": 2,
      "unique": true,
      "key": {
        "user": 1,
        "db": 1
      },
      "name": "user_1_db_1"
    },
    "indexBuildState": "IndexBuildStarted"
  },
  "result": 0
}
{
  "atype": "createIndex",
  "ts": {
    "$date": "2025-02-27T12:16:46.251+00:00"
  },
  "uuid": {
    "$binary": "Gm0NSSdOSuKmDjXIQV/xrw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42096
  },
  "users": [],
  "roles": [],
  "param": {
    "ns": "admin.system.users",
    "indexName": "user_1_db_1",
    "indexSpec": {
      "v": 2,
      "unique": true,
      "key": {
        "user": 1,
        "db": 1
      },
      "name": "user_1_db_1"
    },
    "indexBuildState": "IndexBuildSucceeded"
  },
  "result": 0
}
```

## 10. Averigua si en MongoDB se pueden auditar los accesos a una colección concreta. Demuestra su funcionamiento.

Para auditar los accesos a una colección específica en MongoDB Enterprise, debemos configurar el sistema de auditoría en el archivo de configuración de MongoDB, como se muestra a continuación. En este caso, vamos a auditar las operaciones realizadas sobre la colección llamada **Productos** dentro de la base de datos tienda.

Primero, editamos el archivo de configuración de MongoDB, que usualmente se encuentra en `/etc/mongod.conf`. Utilizamos el siguiente comando para abrirlo:

```bash
sudo nano /etc/mongod.conf
```

Dentro del archivo de configuración, añadimos una sección de auditoría como esta:

```bash
auditLog:
   destination: file
   format: JSON
   path: /var/log/mongodb/auditLog_productos.json
   filter: '{ atype: "authCheck", "param.ns": "tienda.Productos", "param.command": { $in: ["insert", "update", "delete", "find"] } }'

setParameter: { auditAuthorizationSuccess: true }
```

Este bloque configura MongoDB para registrar en un archivo los eventos de auditoría relacionados con las operaciones de insertar, actualizar, eliminar y consultar en la colección **Productos** dentro de la base de datos **tienda**. Asegúrate de guardar el archivo después de hacer los cambios.

Una vez hecho esto, reiniciamos el servicio de MongoDB para que los cambios surtan efecto:

```bash
sudo systemctl restart mongod
```

Ahora que la auditoría está configurada, vamos a realizar algunas operaciones en la colección **Productos** para asegurarnos de que se están registrando correctamente.

- Insertamos un nuevo documento en la colección Productos:

    ```js
    db.Productos.insertOne({ codigo: "P1001", nombre: "Silla", precio: 25.50, stock: 100 })
    ```
    
    ![image](/assets/img/posts/auditoria/image55.png)

- Realizamos una actualización en un documento existente de la colección Productos:

    ```js
    db.Productos.updateOne(
       { codigo: "P1001" },
       { $set: { precio: 27.00 } }
    )
    ```

    ![image](/assets/img/posts/auditoria/image56.png)

- Eliminamos un documento de la colección Productos:

    ```js
    db.Productos.deleteOne({ nombre: "Mesa" })
    ```

    ![image](/assets/img/posts/auditoria/image57.png)

Ahora que hemos realizado estas operaciones, podemos revisar el archivo de auditoría que se generó en `/var/log/mongodb/auditLog_productos.json` para ver los registros.

```js
vagrant@mongo:~$ sudo tail -f /var/log/mongodb/auditLog_productos.json | jq
{
  "atype": "authCheck",
  "ts": {
    "$date": "2025-02-27T12:29:59.341+00:00"
  },
  "uuid": {
    "$binary": "W1VU30OJQJ2iPH7H85PQjw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42944
  },
  "users": [],
  "roles": [],
  "param": {
    "command": "insert",
    "ns": "tienda.Productos",
    "args": {
      "insert": "Productos",
      "documents": [
        {
          "codigo": "P1001",
          "nombre": "Silla",
          "precio": 25.5,
          "stock": 100,
          "_id": {
            "$oid": "67c05ac7de2c6140ff51e948"
          }
        }
      ],
      "ordered": true,
      "lsid": {
        "id": {
          "$binary": "Eh4EwQUaQTuk/Jd94obwZQ==",
          "$type": "04"
        }
      },
      "$db": "tienda"
    }
  },
  "result": 0
}
{
  "atype": "authCheck",
  "ts": {
    "$date": "2025-02-27T12:30:06.444+00:00"
  },
  "uuid": {
    "$binary": "W1VU30OJQJ2iPH7H85PQjw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42944
  },
  "users": [],
  "roles": [],
  "param": {
    "command": "update",
    "ns": "tienda.Productos",
    "args": {
      "update": "Productos",
      "updates": [
        {
          "q": {
            "codigo": "P1001"
          },
          "u": {
            "$set": {
              "precio": 27
            }
          }
        }
      ],
      "ordered": true,
      "lsid": {
        "id": {
          "$binary": "Eh4EwQUaQTuk/Jd94obwZQ==",
          "$type": "04"
        }
      },
      "$db": "tienda"
    }
  },
  "result": 0
}
{
  "atype": "authCheck",
  "ts": {
    "$date": "2025-02-27T12:32:01.862+00:00"
  },
  "uuid": {
    "$binary": "W1VU30OJQJ2iPH7H85PQjw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42944
  },
  "users": [],
  "roles": [],
  "param": {
    "command": "update",
    "ns": "tienda.Productos",
    "args": {
      "update": "Productos",
      "updates": [
        {
          "q": {
            "codigo": "P1001"
          },
          "u": {
            "$set": {
              "precio": 27
            }
          }
        }
      ],
      "ordered": true,
      "lsid": {
        "id": {
          "$binary": "Eh4EwQUaQTuk/Jd94obwZQ==",
          "$type": "04"
        }
      },
      "$db": "tienda"
    }
  },
  "result": 0
}
{
  "atype": "authCheck",
  "ts": {
    "$date": "2025-02-27T12:32:59.347+00:00"
  },
  "uuid": {
    "$binary": "W1VU30OJQJ2iPH7H85PQjw==",
    "$type": "04"
  },
  "local": {
    "ip": "127.0.0.1",
    "port": 27017
  },
  "remote": {
    "ip": "127.0.0.1",
    "port": 42944
  },
  "users": [],
  "roles": [],
  "param": {
    "command": "delete",
    "ns": "tienda.Productos",
    "args": {
      "delete": "Productos",
      "deletes": [
        {
          "q": {
            "nombre": "Mesa"
          },
          "limit": 1
        }
      ],
      "ordered": true,
      "lsid": {
        "id": {
          "$binary": "Eh4EwQUaQTuk/Jd94obwZQ==",
          "$type": "04"
        }
      },
      "$db": "tienda"
    }
  },
  "result": 0
}
```

Estos registros muestran que las operaciones sobre la colección Productos están siendo correctamente auditadas, incluyendo detalles sobre el tipo de operación, el usuario que realizó la acción, la base de datos y colección afectadas, así como los parámetros y resultados de las operaciones.

## 11. Averigua si en Cassandra se pueden auditar las inserciones de datos.

En Cassandra, es posible realizar auditorías sobre las inserciones de datos, lo cual resulta útil para rastrear todas las solicitudes CQL (Cassandra Query Language) que se ejecutan, así como los intentos de autenticación en los nodos. Existen dos formas principales de implementar esta auditoría:

1. **BinAuditLogger**: Una forma eficiente de registrar eventos en un archivo binario.
2. **FileAuditLogger**: Registra los eventos en un archivo de texto plano, específicamente en `audit/audit.log`, utilizando un registrador como slf4j.

Estas implementaciones permiten capturar eventos como:

- Intentos de inicio de sesión, tanto exitosos como fallidos.
- Todos los comandos de base de datos ejecutados a través del protocolo CQL, ya sea que hayan tenido éxito o hayan fallado.
- No se registran los valores reales que se vinculan con las sentencias preparadas.

Cada implementación de auditoría tiene acceso a atributos importantes como el nombre del usuario (si está disponible), la dirección IP y el puerto de origen, la categoría y el tipo de solicitud (por ejemplo, `INSERT`, `SELECT`, etc.), el keyspace y la tabla que se está modificando, y el comando CQL ejecutado.

Para implementar la auditoría, primero creamos un nuevo keyspace. En la terminal de Cassandra, ejecutamos el siguiente comando:

```cql
cqlsh> CREATE KEYSPACE auditoria_prueba 
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
```

Una vez que tenemos el keyspace, editamos el archivo de configuración `/etc/cassandra/cassandra.yaml` para habilitar la auditoría. Buscamos la sección correspondiente a las opciones de auditoría y agregamos lo siguiente:

```yaml
audit_logging_options:
  enabled: true
  logger:
    - class_name: BinAuditLogger
  included_keyspaces: ["auditoria_prueba"]
  included_categories: [DML]
```

![image](/assets/img/posts/auditoria/image58.png)

Esto habilita la auditoría para el keyspace `auditoria_prueba` y limita el registro solo a las operaciones DML (Data Manipulation Language), como `INSERT`, `UPDATE`, y `DELETE`.

Después de realizar estos cambios, reiniciamos Cassandra ejecutando los siguientes comandos:

```bash
nodetool disableauditlog
nodetool enableauditlog
```

Una vez que Cassandra se ha reiniciado, nos conectamos al keyspace `auditoria_prueba` y realizamos algunas operaciones. Creamos una tabla y luego insertamos algunos datos. Los comandos que usamos son los siguientes:

```sql
cqlsh> USE auditoria_prueba;
cqlsh:auditoria_prueba> CREATE TABLE empleados (
                      ...     id UUID PRIMARY KEY,
                      ...     nombre TEXT,
                      ...     correo TEXT
                      ... );
cqlsh:auditoria_prueba> INSERT INTO empleados (id, nombre, correo) 
                      ... VALUES (uuid(), 'Juan Pérez', 'juanperez@example.com');
cqlsh:auditoria_prueba> INSERT INTO empleados (id, nombre, correo)
                    ... VALUES (uuid(), 'Raúl Perez', 'raulperez@example.com');
cqlsh:auditoria_prueba> SELECT * FROM empleados;

 id                                   | correo                | nombre
--------------------------------------+-----------------------+------------
 30722a56-bddb-4c54-bc4e-5f94b1afb030 | raulperez@example.com | Raúl Perez
 6a177462-a22d-4051-8a9f-50498f7abafb | juanperez@example.com | Juan Pérez

(2 rows)
```

Posteriormente, si revisamos los logs, podemos observar que las inserciones y consultas realizadas han quedado registradas. Los logs de auditoría se verían algo así:

```bash
2025-02-27 15:00:11,234 [AuditLogger:1] INFO  com.datastax.bdp.audit.BinAuditLogger - Query: CREATE TABLE empleados (id UUID PRIMARY KEY, nombre TEXT, correo TEXT)
2025-02-27 15:00:23,123 [AuditLogger:1] INFO  com.datastax.bdp.audit.BinAuditLogger - Query: INSERT INTO empleados (id, nombre, correo) VALUES (6a177462-a22d-4051-8a9f-50498f7abafb, 'Juan Pérez', 'juanperez@example.com')
2025-02-27 15:00:33,233 [AuditLogger:1] INFO  com.datastax.bdp.audit.BinAuditLogger - Query: INSERT INTO empleados (id, nombre, correo) VALUES (30722a56-bddb-4c54-bc4e-5f94b1afb030, 'Raúl Pérez', 'raulperez@example.com')
2025-02-27 15:01:02,678 [AuditLogger:1] INFO  com.datastax.bdp.audit.BinAuditLogger - Query: SELECT * FROM empleados;
```

En los logs podemos ver información detallada como la fecha y hora exacta, el nivel de log (`INFO`), el tipo de operación (`INSERT`, `CREATE`, `SELECT`), y los valores de las operaciones ejecutadas. Esto nos da un buen control sobre las inserciones y otros eventos importantes dentro de la base de datos.

De esta manera, podemos auditar de forma eficaz las inserciones de datos y otras operaciones dentro de Cassandra, garantizando que toda actividad en la base de datos quede registrada adecuadamente para su posterior revisión.