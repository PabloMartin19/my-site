---
title: "Integridad, firmas y autenticación"
date: 2024-12-19 17:30:00 +0000
categories: [Seguridad, Criptografía]
tags: [Criptografía]
author: pablo
description: "En esta práctica trabajaremos con firmas electrónicas, integridad de ficheros y autenticación."
toc: true
comments: true
image:
  path: /assets/img/posts/integridad/portada.png
---

## Tarea 1: Firmas electrónicas

En este primer apartado vamos a trabajar con las firmas eléctronicas, por lo que vamos a apoyarnos en los siguientes enlaces:

- [Intercambio de claves](https://www.gnupg.org/gph/es/manual/x75.html)
- [Validación de otras claves en nuestro anillo de claves públicas](https://www.gnupg.org/gph/es/manual/x354.html)
- [Firmado de claves (Debian)](https://www.debian.org/events/keysigning.es.html)

### Manda un documento y la firma electrónica del mismo a un compañero. Verifica la firma que tú has recibido.

Antes de comenzar la práctica, voy a listar las claves existentes en mi keyring:

```bash
pavlo@debian:~()$ gpg --list-keys
/home/pavlo/.gnupg/pubring.kbx
------------------------------
pub   rsa3072 2024-12-13 [SC] [caduca: 2026-12-13]
      C2E235639EB3A2A420828C9DED45D8BE85D4DB1A
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa3072 2024-12-13 [E] [caduca: 2026-12-13]
```

Como podemos observar, en mi anillo de claves se encuentra mi clave personal. Por tanto, el siguiente paso será subir esta clave a un servidor de claves, como puede ser **keys.gnupg.net**, utilizando el fingerprint para identificarla de forma precisa.

```bash
pavlo@debian:~()$ gpg --keyserver keys.gnupg.net --send-key C2E235639EB3A2A420828C9DED45D8BE85D4DB1A
gpg: enviando clave ED45D8BE85D4DB1A a hkp://pgp.surf.nl
```

La clave ha sido enviada al servidor de claves, lo que permitirá que cualquier persona que reciba mi archivo firmado pueda descargarla e importarla para verificar la firma.  

Es posible elegir entre dos métodos al firmar un archivo: incluir la firma directamente dentro del archivo utilizando la opción `--sign`, o bien generar la firma en un archivo separado, dejando el original intacto. En este caso, optaremos por la segunda alternativa, usando la opción `--detach-sign`.  

Por lo tanto, procederemos a firmar un documento llamado *UE-Empresa.pdf*, separando la firma en un archivo distinto. Para lograrlo, ejecutaremos el comando correspondiente:  

```bash
pavlo@debian:~()$ gpg --detach-sign UE-Empresa.pdf
```

Durante el proceso de firmado, el sistema solicitará la frase de paso asociada a nuestra clave privada. Una vez ingresada correctamente, el firmado se completará. A continuación, procederemos a listar el documento firmado:

```bash
pavlo@debian:~()$ ls -l | grep 'UE'
-rw-r--r--  1 pavlo pavlo 33734 nov 22 12:09 UE-Empresa.pdf
-rw-r--r--  1 pavlo pavlo   438 dic 18 17:28 UE-Empresa.pdf.sig
```

Para verificar que está firmado por nosotros ejecutamos el siguiente comando:

```bash
pavlo@debian:~()$ gpg --verify UE-Empresa.pdf.sig UE-Empresa.pdf
gpg: Firmado el mié 18 dic 2024 17:28:53 CET
gpg:                usando RSA clave C2E235639EB3A2A420828C9DED45D8BE85D4DB1A
gpg: Firma correcta de "Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>" [absoluta]
```

Podemos observar que tanto el archivo original (*UE-Empresa.pdf*) como su firma (*UE-Empresa.pdf.sig*) están en ficheros independientes. Esto nos permite enviarlos a otra persona, quien podrá verificar la integridad del archivo utilizando nuestra clave pública.  

En este caso, mi compañero también ha seguido un procedimiento similar al nuestro. Por lo tanto, antes de proceder a verificar la firma de su archivo, es necesario importar su clave pública. Para realizar este paso, utilizaré el siguiente comando: 

```bash
pavlo@debian:~()$ gpg --keyserver pgp.rediris.es --recv-keys DB72B640
gpg: clave F78DAA71DB72B640: clave pública "jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Como podemos observar a continuación, la clave pública de mi compañero Jose se ha importado correctamente:

```bash
pavlo@debian:~()$ gpg --list-keys
/home/pavlo/.gnupg/pubring.kbx
------------------------------
pub   rsa3072 2024-12-13 [SC] [caduca: 2026-12-13]
      C2E235639EB3A2A420828C9DED45D8BE85D4DB1A
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa3072 2024-12-13 [E] [caduca: 2026-12-13]

pub   rsa4096 2024-12-18 [SC] [caduca: 2025-12-18]
      7E7ECEAC3D3DF6FDAF903497F78DAA71DB72B640
uid        [desconocida] jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>
sub   rsa4096 2024-12-18 [E] [caduca: 2025-12-18]
```

Jose me ha enviado dos ficheros, un fichero `documento.txt` que es el fichero original, y un fichero `documento.txt.sig`, que contiene la firma del mismo. Para verificar la firma, vamos a hacer uso de la opción `--verify`, pasando como parámetros ambos ficheros:

```bash
pavlo@debian:~()$ gpg --verify documento.txt.sig documento.txt
gpg: Firmado el mié 18 dic 2024 18:42:03 CET
gpg:                usando RSA clave 7E7ECEAC3D3DF6FDAF903497F78DAA71DB72B640
gpg: Firma correcta de "jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>" [desconocido]
gpg: ATENCIÓN: ¡Esta clave no está certificada por una firma de confianza!
gpg:          No hay indicios de que la firma pertenezca al propietario.
Huellas dactilares de la clave primaria: 7E7E CEAC 3D3D F6FD AF90  3497 F78D AA71 DB72 B640
```

Como muestra la salida del comando, la firma es válida. Sin embargo, también aparece un mensaje indicando que la clave no está certificada por una firma confiable. Esto significa que no existen pruebas de que la firma pertenezca realmente al propietario declarado. Esto ocurre porque la clave pública que acabamos de importar carece de validez, ya que no la hemos firmado ni contamos con intermediarios confiables que puedan respaldarla de manera indirecta. Más adelante, explicaremos este concepto con mayor profundidad.  

Antes de continuar con el siguiente paso, he optado por eliminar la clave pública de mi anillo de claves. Esto me permitirá empezar desde cero, asegurándome de que no quede ninguna clave almacenada. Para realizar esta acción, utilizaré la opción `--delete-keys`:  

```bash
pavlo@debian:~()$ gpg --delete-keys 7E7ECEAC3D3DF6FDAF903497F78DAA71DB72B640
gpg (GnuPG) 2.2.40; Copyright (C) 2022 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


pub  rsa4096/F78DAA71DB72B640 2024-12-18 jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>

¿Eliminar esta clave del anillo? (s/N) s
```

Ya he eliminado la clave pública de Jose de mi keyring.

### Crea un anillo de confianza entre los miembros de la clase

Para garantizar la seguridad en el uso de claves GPG, es fundamental asegurarnos de que las claves públicas con las que interactuamos realmente pertenecen a sus supuestos dueños. Sin esta verificación, podríamos estar cifrando información para un atacante en lugar del destinatario legítimo o aceptando firmas falsas sin darnos cuenta. La confianza en las claves es, por tanto, un aspecto esencial en la criptografía.  

Una forma de establecer esta confianza es a través del **anillo de confianza**, un sistema basado en la validación mutua entre personas que confían entre sí. Este mecanismo permite que los usuarios firmen la huella digital (*fingerprint*) de una clave pública utilizando su propia clave privada. Una vez firmada, la clave se devuelve a su propietario, quien puede compartirla con otros, demostrando así que ha sido validada por alguien de confianza.  

Este proceso no solo fortalece la credibilidad de una clave, sino que también facilita la verificación indirecta. Si confiamos en una persona y esta, a su vez, ha certificado la clave de otra, podemos asumir que dicha clave es confiable sin necesidad de validarla directamente. La efectividad de este modelo depende de cómo se configuren las relaciones de confianza y de la fiabilidad de quienes participan en la red.  

Aunque puede parecer complicado al principio, este sistema es muy útil para garantizar la autenticidad de las claves en un entorno seguro. Un ejemplo práctico ayudará a comprender mejor su funcionamiento.

**Pasos para crear un anillo de confianza**

El primer paso es subir nuestra clave pública a un servidor de claves, en este caso lo subiré a `pgp.rediris.es`:

```bash
pavlo@debian:~()$ gpg --keyserver hkp://pgp.rediris.es --send-keys C2E235639EB3A2A420828C9DED45D8BE85D4DB1A
gpg: enviando clave ED45D8BE85D4DB1A a hkp://pgp.rediris.es
```

Luego, procedemos a descargarnos las claves públicas de mis compañeros, usando sus nombres o correos en la búsqueda de `pgp.rediris.es`, con el siguiente comando:

```bash
pavlo@debian:~()$ gpg --keyserver pgp.rediris.es --recv-keys DB72B640
gpg: clave F78DAA71DB72B640: clave pública "jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Básicamente cogemos los últimos dígitos para importar la clave y repetimos el proceso con todos los compañeros.

Seguidamente, tendremos que firmar las claves públicas descargadas para poder validarlas en nuestro anillo de confianza. Lo haremos de la siguiente forma:

```bash
pavlo@debian:~()$ gpg --sign-key 7E7ECEAC3D3DF6FDAF903497F78DAA71DB72B640

pub  rsa4096/F78DAA71DB72B640
     creado: 2024-12-18  caduca: 2025-12-18  uso: SC  
     confianza: desconocido   validez: desconocido
sub  rsa4096/C32521E4109A45D6
     creado: 2024-12-18  caduca: 2025-12-18  uso: E   
[desconocida] (1). jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>


pub  rsa4096/F78DAA71DB72B640
     creado: 2024-12-18  caduca: 2025-12-18  uso: SC  
     confianza: desconocido   validez: desconocido
 Huella clave primaria: 7E7E CEAC 3D3D F6FD AF90  3497 F78D AA71 DB72 B640

     jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>

Esta clave expirará el 2025-12-18.
¿Está realmente seguro de querer firmar esta clave
con su clave: "Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>" (ED45D8BE85D4DB1A)?

¿Firmar de verdad? (s/N) s
```

Repetimos el proceso con **Alejandro Liáñez** y con **Andrés Morales**.

A continuación, será necesario exportar las claves de nuestros compañeros con la firma que hemos generado recientemente. Este paso nos permitirá distribuirlas manualmente a sus propietarios, quienes podrán importarlas en su sistema. Para este propósito, en mi caso, exporté las claves de tres compañeros utilizando los siguientes comandos:

```bash
pavlo@debian:~()$ gpg --armor --export -a "Andrés Morales González" > andres123.asc
pavlo@debian:~()$ gpg --armor --export -a "jose antonio canalo gonzalez" > clave-canalo.asc
pavlo@debian:~()$ gpg --armor --export -a "Alejandro Liáñez Frutos" > ale.asc
```

Y como vemos las claves han sido correctamente exportadas a los correspondientes ficheros:

```bash
pavlo@debian:~()$ ls -l | grep '.asc'
-rw-r--r--  1 pavlo pavlo  4260 dic 18 19:41 ale.asc
-rw-r--r--  1 pavlo pavlo  3069 dic 18 17:48 andres123.asc
-rw-r--r--  1 pavlo pavlo  3780 dic 18 19:34 clave-canalo.asc
```

Mis compañeros han seguido los mismos pasos, así que ellos también me enviaron mi clave con las correspondientes firmas, que debemos importar:

```bash
pavlo@debian:~/firma()$ ls -l
total 12
-rw-r--r-- 1 pavlo pavlo 3244 dic 18 19:37 pablo_firmada.asc
-rw-r--r-- 1 pavlo pavlo 3663 dic 18 18:42 pmh19.asc
-rw-r--r-- 1 pavlo pavlo 3069 dic 18 17:44 pmh.asc
```

Como vemos hay 3 ficheros, pertenecientes a cada uno de los compañeros que han colaborado conmigo en este anillo de confianza, por lo que ahora tendremos que importarlas:

```bash
pavlo@debian:~/firma()$ gpg --import pablo_firmada.asc 
gpg: clave ED45D8BE85D4DB1A: "Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>" 1 firma nueva
gpg: Cantidad total procesada: 1
gpg:         nuevas firmas: 1
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: nivel: 0  validez:   1  firmada:   3  confianza: 0-, 0q, 0n, 0m, 0f, 1u
gpg: nivel: 1  validez:   3  firmada:   0  confianza: 3-, 0q, 0n, 0m, 0f, 0u
gpg: siguiente comprobación de base de datos de confianza el: 2025-12-18
```

Ahora, verificamos que mis compañeros hayan firmado mi clave:

```bash
pavlo@debian:~/firma()$ gpg --list-sig "Pablo Martín Hidalgo"
pub   rsa3072 2024-12-13 [SC] [caduca: 2026-12-13]
      C2E235639EB3A2A420828C9DED45D8BE85D4DB1A
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sig 3        ED45D8BE85D4DB1A 2024-12-13  Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sig          1B80812C7BB9EA86 2024-12-18  Andrés Morales González <asirandyglez@gmail.com>
sig          9E7BEEE532BE0469 2024-12-18  Alejandro Liáñez Frutos <alejandroliafru@gmail.com>
sig          F78DAA71DB72B640 2024-12-18  jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>
sub   rsa3072 2024-12-13 [E] [caduca: 2026-12-13]
sig          ED45D8BE85D4DB1A 2024-12-13  Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
```

Y como vemos a continuación:

```bash
pavlo@debian:~()$ gpg --list-keys
gpg: comprobando base de datos de confianza
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: nivel: 0  validez:   1  firmada:   3  confianza: 0-, 0q, 0n, 0m, 0f, 1u
gpg: nivel: 1  validez:   3  firmada:   0  confianza: 3-, 0q, 0n, 0m, 0f, 0u
gpg: siguiente comprobación de base de datos de confianza el: 2025-12-18
/home/pavlo/.gnupg/pubring.kbx
------------------------------
pub   rsa3072 2024-12-13 [SC] [caduca: 2026-12-13]
      C2E235639EB3A2A420828C9DED45D8BE85D4DB1A
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa3072 2024-12-13 [E] [caduca: 2026-12-13]

pub   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      B39722468D0599C3B62F9AEA9E7BEEE532BE0469
uid        [   total   ] Alejandro Liáñez Frutos <alejandroliafru@gmail.com>
sub   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]

pub   rsa3072 2024-12-16 [SC] [caduca: 2026-12-16]
      B7E822D8FB45BD8BAF2F31561B80812C7BB9EA86
uid        [   total   ] Andrés Morales González <asirandyglez@gmail.com>
sub   rsa3072 2024-12-16 [E] [caduca: 2026-12-16]

pub   rsa4096 2024-12-18 [SC] [caduca: 2025-12-18]
      7E7ECEAC3D3DF6FDAF903497F78DAA71DB72B640
uid        [   total   ] jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>
sub   rsa4096 2024-12-18 [E] [caduca: 2025-12-18]
```

Todas las claves han sido ya firmadas (es posible que nos haya pedido la frase de paso de nuestra clave privada a la hora de llevar a cabo el proceso de firmado), su validez ha cambiado de desconocida a total, por lo que en caso de querer encriptar con dichas claves públicas o comprobar firmas, no se nos mostrará el mensaje de advertencia.

Podemos verificar que todas las claves se encuentran firmadas por todos, por lo que todos hemos validado las claves de todos.

### Comprueba que ya puedes verificar sin “problemas” una firma recibida por una persona en la que confías.

Como podemos observar, el documento firmado anteriormente ya nos muestra el mensaje de que la firma es correcta:

```bash
pavlo@debian:~()$ gpg --verify documento.txt.sig 
gpg: asumiendo que los datos firmados están en 'documento.txt'
gpg: Firmado el mié 18 dic 2024 18:42:03 CET
gpg:                usando RSA clave 7E7ECEAC3D3DF6FDAF903497F78DAA71DB72B640
gpg: Firma correcta de "jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>" [total]
```

### Comprueba que puedes verificar con confianza una firma de una persona en las que no confías, pero sin embargo si confía otra persona en la que tu tienes confianza total.

El primer paso es asignar un nivel de confianza absoluta a la clave de una persona (Andrés Morales González en este caso), bajo el supuesto de que verificará correctamente las claves de otros usuarios. Esto se realiza con los comandos:

```bash
pavlo@debian:~/firma()$ gpg --edit-key "Andrés Morales González"
gpg (GnuPG) 2.2.40; Copyright (C) 2022 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


pub  rsa3072/1B80812C7BB9EA86
     creado: 2024-12-16  caduca: 2026-12-16  uso: SC  
     confianza: desconocido   validez: total
sub  rsa3072/31278448B2A4EFCA
     creado: 2024-12-16  caduca: 2026-12-16  uso: E   
[   total   ] (1). Andrés Morales González <asirandyglez@gmail.com>

gpg> trust
pub  rsa3072/1B80812C7BB9EA86
     creado: 2024-12-16  caduca: 2026-12-16  uso: SC  
     confianza: desconocido   validez: total
sub  rsa3072/31278448B2A4EFCA
     creado: 2024-12-16  caduca: 2026-12-16  uso: E   
[   total   ] (1). Andrés Morales González <asirandyglez@gmail.com>

Por favor, decida su nivel de confianza en que este usuario
verifique correctamente las claves de otros usuarios (mirando
pasaportes, comprobando huellas dactilares en diferentes fuentes...)


  1 = No lo sé o prefiero no decirlo
  2 = NO tengo confianza
  3 = Confío un poco
  4 = Confío totalmente
  5 = confío absolutamente
  m = volver al menú principal

¿Su decisión? 5
¿De verdad quiere asignar absoluta confianza a esta clave? (s/N) s

pub  rsa3072/1B80812C7BB9EA86
     creado: 2024-12-16  caduca: 2026-12-16  uso: SC  
     confianza: absoluta      validez: total
sub  rsa3072/31278448B2A4EFCA
     creado: 2024-12-16  caduca: 2026-12-16  uso: E   
[   total   ] (1). Andrés Morales González <asirandyglez@gmail.com>
Ten en cuenta que la validez de clave mostrada no es necesariamente
correcta a menos de que reinicies el programa.

gpg> quit
```

Seleccionamos el nivel 5 (confianza absoluta) y confirmamos la acción. Esto marca la clave como confiable para firmar otras claves, lo que permite delegar la validación.

Luego, importamos la clave pública del firmante final, en este caso Juan Antonio Pineda Amador, utilizando su identificador:

```bash
pavlo@debian:~/firma()$ gpg --keyserver keyserver.ubuntu.com --recv-keys d30d0b7e734fcf74
gpg: clave D30D0B7E734FCF74: clave pública "Juan Antonio Pineda Amador <juanantpiama@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Esto descarga e importa la clave pública al anillo de claves.

Luego, importamos una versión de la clave firmada por alguien en quien confío (como Andrés Morales González):

```bash
pavlo@debian:~/firma()$ gpg --import clave-firmada-pablo.asc 
gpg: clave ED45D8BE85D4DB1A: "Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>" 1 firma nueva
gpg: Cantidad total procesada: 1
gpg:         nuevas firmas: 1
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: nivel: 0  validez:   2  firmada:   2  confianza: 0-, 0q, 0n, 0m, 0f, 2u
gpg: nivel: 1  validez:   2  firmada:   0  confianza: 2-, 0q, 0n, 0m, 0f, 0u
gpg: siguiente comprobación de base de datos de confianza el: 2025-12-18
```

Por último damos nuestra confianza absoluta en Juan Antonio Pineda:

```bash
pavlo@debian:~/firma()$ gpg --edit-key "Juan Antonio Pineda Amador"
gpg (GnuPG) 2.2.40; Copyright (C) 2022 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


pub  rsa3072/D30D0B7E734FCF74
     creado: 2024-12-13  caduca: 2026-12-13  uso: SC  
     confianza: desconocido   validez: desconocido
sub  rsa3072/BC028BCC730037FF
     creado: 2024-12-13  caduca: 2026-12-13  uso: E   
[desconocida] (1). Juan Antonio Pineda Amador <juanantpiama@gmail.com>

gpg> trust
pub  rsa3072/D30D0B7E734FCF74
     creado: 2024-12-13  caduca: 2026-12-13  uso: SC  
     confianza: desconocido   validez: desconocido
sub  rsa3072/BC028BCC730037FF
     creado: 2024-12-13  caduca: 2026-12-13  uso: E   
[desconocida] (1). Juan Antonio Pineda Amador <juanantpiama@gmail.com>

Por favor, decida su nivel de confianza en que este usuario
verifique correctamente las claves de otros usuarios (mirando
pasaportes, comprobando huellas dactilares en diferentes fuentes...)


  1 = No lo sé o prefiero no decirlo
  2 = NO tengo confianza
  3 = Confío un poco
  4 = Confío totalmente
  5 = confío absolutamente
  m = volver al menú principal

¿Su decisión? 5
¿De verdad quiere asignar absoluta confianza a esta clave? (s/N) s

pub  rsa3072/D30D0B7E734FCF74
     creado: 2024-12-13  caduca: 2026-12-13  uso: SC  
     confianza: absoluta      validez: desconocido
sub  rsa3072/BC028BCC730037FF
     creado: 2024-12-13  caduca: 2026-12-13  uso: E   
[desconocida] (1). Juan Antonio Pineda Amador <juanantpiama@gmail.com>
Ten en cuenta que la validez de clave mostrada no es necesariamente
correcta a menos de que reinicies el programa.

gpg> quit
```

```bash
pavlo@debian:~/firma()$ gpg --list-sig
gpg: comprobando base de datos de confianza
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: nivel: 0  validez:   3  firmada:   2  confianza: 0-, 0q, 0n, 0m, 0f, 3u
gpg: nivel: 1  validez:   2  firmada:   0  confianza: 2-, 0q, 0n, 0m, 0f, 0u
gpg: siguiente comprobación de base de datos de confianza el: 2025-12-18
/home/pavlo/.gnupg/pubring.kbx
------------------------------
pub   rsa3072 2024-12-13 [SC] [caduca: 2026-12-13]
      C2E235639EB3A2A420828C9DED45D8BE85D4DB1A
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sig 3        ED45D8BE85D4DB1A 2024-12-13  Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sig          1B80812C7BB9EA86 2024-12-18  Andrés Morales González <asirandyglez@gmail.com>
sig          9E7BEEE532BE0469 2024-12-18  Alejandro Liáñez Frutos <alejandroliafru@gmail.com>
sig          F78DAA71DB72B640 2024-12-18  jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>
sig          D30D0B7E734FCF74 2024-12-19  Juan Antonio Pineda Amador <juanantpiama@gmail.com>
sub   rsa3072 2024-12-13 [E] [caduca: 2026-12-13]
sig          ED45D8BE85D4DB1A 2024-12-13  Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>

pub   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      B39722468D0599C3B62F9AEA9E7BEEE532BE0469
uid        [   total   ] Alejandro Liáñez Frutos <alejandroliafru@gmail.com>
sig 3        9E7BEEE532BE0469 2024-12-12  Alejandro Liáñez Frutos <alejandroliafru@gmail.com>
sig          1B80812C7BB9EA86 2024-12-17  Andrés Morales González <asirandyglez@gmail.com>
sig          EB11F07AEE22B444 2024-12-18  [ID de usuario no encontrado]
sig          ED45D8BE85D4DB1A 2024-12-18  Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]
sig          9E7BEEE532BE0469 2024-12-12  Alejandro Liáñez Frutos <alejandroliafru@gmail.com>

pub   rsa3072 2024-12-16 [SC] [caduca: 2026-12-16]
      B7E822D8FB45BD8BAF2F31561B80812C7BB9EA86
uid        [  absoluta ] Andrés Morales González <asirandyglez@gmail.com>
sig 3        1B80812C7BB9EA86 2024-12-16  Andrés Morales González <asirandyglez@gmail.com>
sig          ED45D8BE85D4DB1A 2024-12-18  Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa3072 2024-12-16 [E] [caduca: 2026-12-16]
sig          1B80812C7BB9EA86 2024-12-16  Andrés Morales González <asirandyglez@gmail.com>

pub   rsa4096 2024-12-18 [SC] [caduca: 2025-12-18]
      7E7ECEAC3D3DF6FDAF903497F78DAA71DB72B640
uid        [   total   ] jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>
sig 3        F78DAA71DB72B640 2024-12-18  jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>
sig          ED45D8BE85D4DB1A 2024-12-18  Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa4096 2024-12-18 [E] [caduca: 2025-12-18]
sig          F78DAA71DB72B640 2024-12-18  jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>

pub   rsa3072 2023-02-22 [SC] [caduca: 2025-02-21]
      D6E21A8B6ED6E8EF9F7CE81686F55C1E2DA53D65
uid        [desconocida] Raúl Ruiz <raulpruebas21@gmail.com>
sig 3        86F55C1E2DA53D65 2023-02-22  Raúl Ruiz <raulpruebas21@gmail.com>
sub   rsa3072 2023-02-22 [E] [caduca: 2025-02-21]
sig          86F55C1E2DA53D65 2023-02-22  Raúl Ruiz <raulpruebas21@gmail.com>

pub   rsa3072 2024-12-13 [SC] [caduca: 2026-12-13]
      97AAB306BAF9F7A0600C9F7CD30D0B7E734FCF74
uid        [  absoluta ] Juan Antonio Pineda Amador <juanantpiama@gmail.com>
sig 3        D30D0B7E734FCF74 2024-12-13  Juan Antonio Pineda Amador <juanantpiama@gmail.com>
sub   rsa3072 2024-12-13 [E] [caduca: 2026-12-13]
sig          D30D0B7E734FCF74 2024-12-13  Juan Antonio Pineda Amador <juanantpiama@gmail.com>
```

Con ambas claves presentes (la del intermediario y la del firmante final), verificamos el archivo firmado y el archivo original 
para comprobar su autenticidad:

```bash
pavlo@debian:~/firma()$ gpg --verify pinedadocumento.txt.sig pinedadocumento.txt
gpg: Firmado el dom 15 dic 2024 18:36:36 CET
gpg:                usando RSA clave 97AAB306BAF9F7A0600C9F7CD30D0B7E734FCF74
gpg: Firma correcta de "Juan Antonio Pineda Amador <juanantpiama@gmail.com>" [absoluta]
```

Y como vemos el sistema confirma la firma.

## Tarea 2: Correo seguro con evolution/thunderbird

Ahora vamos a configurar nuestro cliente de correo electrónico para poder mandar correos cifrados, para ello:

### Configura el cliente de correo evolution con tu cuenta de correo habitual

Para este apartado lo que haremos será instalar **Thunderbird** con el siguiente comando:

```bash
pavlo@debian:~()$ sudo apt install thunderbird-l10n-es-es
```

Una vez instalado ejecutamos Thunderbird y rellenamos los campos:

![image](/assets/img/posts/integridad/thunderbird.png)

Después de hacer la verificación en dos pasos ya nos dejará entrar sin ningún problema:

![image](/assets/img/posts/integridad/thunderbird2.png)

### Añade a la cuenta las opciones de seguridad para poder enviar correos firmados con tu clave privada o cifrar los mensajes para otros destinatarios

Para este apartado debemos utilizar la clave privada, por lo que primero debemos listarla:

```bash
pavlo@debian:~/firma()$ gpg --list-secret-keys
/home/pavlo/.gnupg/pubring.kbx
------------------------------
sec   rsa3072 2024-12-13 [SC] [caduca: 2026-12-13]
      C2E235639EB3A2A420828C9DED45D8BE85D4DB1A
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
ssb   rsa3072 2024-12-13 [E] [caduca: 2026-12-13]
```

Ahora, utilizando el ID de nuestra clave, debemos exportarla en un fichero para más tarde configurarlo en Thunderbird:

```bash
pavlo@debian:~/firma()$ gpg --export-secret-keys --armor C2E235639EB3A2A420828C9DED45D8BE85D4DB1A > clave-thunderbird.asc
```

Posiblemente nos pida la frase de paso, la introducimos y ya debería generarse el fichero:

```bash
pavlo@debian:~/firma()$ ls -l | grep 'clave'
-rw-r--r-- 1 pavlo pavlo 7187 dic 19 11:57 clave-thunderbird.asc
```

Seguidamente, debemos dirigirnos a la aplicación de correos e importar la clave que acabamos de crear. Para ello nos dirigimos a **Ajustes** >> **Configuración de la cuenta** >> **Cifrado de extremo a extremo**, le damos a añadir clave y seleccionamos la creada anteriormente:

![image](/assets/img/posts/integridad/thunderbird3.png)

Y como vemos ya se ha importado correctamente la clave:

![image](/assets/img/posts/integridad/thunderbird4.png)


### Envía y recibe varios mensajes con tus compañeros y comprueba el funcionamiento adecuado de GPG

Para esta prueba, le he mandado un correo a Andrés Morales (asirandyglez@gmail.com) con su clave pública la cual me ha pasado:

```bash
pavlo@debian:~/firma()$ ls -l
total 28
-rw-r--r-- 1 pavlo pavlo 4256 dic 19 12:10 andy-and1.asc
-rw-r--r-- 1 pavlo pavlo 7187 dic 19 11:57 clave-thunderbird.asc
-rw-r--r-- 1 pavlo pavlo 3244 dic 18 19:37 pablo_firmada.asc
-rw-r--r-- 1 pavlo pavlo 3663 dic 18 18:42 pmh19.asc
-rw-r--r-- 1 pavlo pavlo 3069 dic 18 17:44 pmh.asc
```

Por lo tanto, enviamos un mensaje y seleccionamos el fichero de su clave para que se firme el correo:

![image](/assets/img/posts/integridad/thunderbird5.png)

Por otro lado, Andrés me enviará un correo firmado con mi clave pública:

![image](/assets/img/posts/integridad/thunderbird6.png)

Y como podemos observar, desde gmail no nos dejará ver el contenido:

![image](/assets/img/posts/integridad/thunderbird7.png)

### Enviar un correo electrónico al profesor con un mensaje firmado por vosotros y que solo pueda descifrar yo.

Para la realización de este apartado extra debemos importar la clave del profesor Raúl en nuestro sistema. Para ello nos dirigimos a la página [wiki](https://dit.gonzalonazareno.org/redmine/projects/asir2/wiki/Claves_p%C3%BAblicas_PGP_2024-2025) y nos descargamos su clave:

```bash
pavlo@debian:~/firma()$ gpg --keyserver keyserver.ubuntu.com --recv-keys 86f55c1e2da53d65
gpg: clave 86F55C1E2DA53D65: clave pública "Raúl Ruiz <raulpruebas21@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Como podemos observar, su clave se ha importado correctamente:

```bash
pavlo@debian:~/firma()$ gpg --list-keys 
/home/pavlo/.gnupg/pubring.kbx
------------------------------
pub   rsa3072 2024-12-13 [SC] [caduca: 2026-12-13]
      C2E235639EB3A2A420828C9DED45D8BE85D4DB1A
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa3072 2024-12-13 [E] [caduca: 2026-12-13]

pub   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      B39722468D0599C3B62F9AEA9E7BEEE532BE0469
uid        [   total   ] Alejandro Liáñez Frutos <alejandroliafru@gmail.com>
sub   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]

pub   rsa3072 2024-12-16 [SC] [caduca: 2026-12-16]
      B7E822D8FB45BD8BAF2F31561B80812C7BB9EA86
uid        [   total   ] Andrés Morales González <asirandyglez@gmail.com>
sub   rsa3072 2024-12-16 [E] [caduca: 2026-12-16]

pub   rsa4096 2024-12-18 [SC] [caduca: 2025-12-18]
      7E7ECEAC3D3DF6FDAF903497F78DAA71DB72B640
uid        [   total   ] jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>
sub   rsa4096 2024-12-18 [E] [caduca: 2025-12-18]

pub   rsa3072 2023-02-22 [SC] [caduca: 2025-02-21]
      D6E21A8B6ED6E8EF9F7CE81686F55C1E2DA53D65
uid        [desconocida] Raúl Ruiz <raulpruebas21@gmail.com>
sub   rsa3072 2023-02-22 [E] [caduca: 2025-02-21]
```

Por lo que ahora debemos hacer lo mismo que antes, exportar la clave en un fichero .asc y añadirla en Thunderbird:

```bash
pavlo@debian:~/firma()$ gpg --export --armor 86f55c1e2da53d65 > clave-raul.asc
```

Vamos a enviar un nuevo correo a Raúl a su correo y debemos darle arriba a la izquierda a "Cifrar". Una vez seleccionado esta opción nos saldrá un mensaje abajo en amarillo, en donde debemos darle a "Resolver". Ahí importamos la clave de Raúl y ya estaría:

![image](/assets/img/posts/integridad/thunderbird8.png)

![image](/assets/img/posts/integridad/thunderbird9.png)

Y como podemos comprobar a continuación, el correo ha sido enviado con **OpenGPG**:

![image](/assets/img/posts/integridad/thunderbird10.png)


## Tarea 3: Integridad de ficheros

Vamos a descargarnos la ISO de debian, y posteriormente vamos a comprobar su integridad.

Puedes encontrar la ISO en la dirección: https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/.

### Para validar el contenido de la imagen CD, solo asegúrese de usar la herramienta apropiada para sumas de verificación. Para cada versión publicada existen archivos de suma de comprobación con algoritmos fuertes (SHA256 y SHA512); debería usar las herramientas sha256sum o sha512sum para trabajar con ellos

Pues lo primero que debemos hacer es descargar la ISO de Debian 12 y el fichero de suma de comprobación(SHA512):

```bash
pavlo@debian:~/integridad()$ wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.8.0-amd64-netinst.iso
pavlo@debian:~/integridad()$ wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA512SUMS
```

Utilizamos la herramienta sha512sum para generar el hash de la imagen ISO descargada y comparar el resultado con el hash proporcionado en los archivos de suma de comprobación.

```bash
pavlo@debian:~/integridad()$ ls -l
total 646148
-rw-r--r-- 1 pavlo pavlo 661651456 nov  9 13:46 debian-12.8.0-amd64-netinst.iso
-rw-r--r-- 1 pavlo pavlo       494 nov  9 17:34 SHA512SUMS
pavlo@debian:~/integridad()$ sha512sum --check --ignore-missing SHA512SUMS
debian-12.8.0-amd64-netinst.iso: La suma coincide
```

Y como vemos el contenido de la imagen CD coincide.

### Verifica que el contenido del hash que has utilizado no ha sido manipulado, usando la firma digital que encontrarás en el repositorio. Puedes encontrar una guía para realizarlo en este artículo: [How to verify an authenticity of downloaded Debian ISO images](https://linuxconfig.org/how-to-verify-an-authenticity-of-downloaded-debian-iso-images)

Este paso verifica que el archivo de suma de comprobación no ha sido manipulado y que está firmado por una clave confiable. Por lo que debemos descargarnos la firma digital:

```bash
pavlo@debian:~/integridad()$ wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA512SUMS.sign
```

Verificamos la firma y como vemos a continuación nos saldrá un mensaje de error de que es imposible comprobar la firma:

```bash
pavlo@debian:~/integridad()$ gpg --verify SHA512SUMS.sign SHA512SUMS
gpg: Firmado el sáb 09 nov 2024 17:35:02 CET
gpg:                usando RSA clave DF9B9C49EAA9298432589D76DA87E80D6294BE9B
gpg: Imposible comprobar la firma: No hay clave pública
```

Esto se debe a que no tenemos importada la clave pública de la persona que firmó dicho fichero, por lo que para solucionar esto debemos importar la clave:

```bash
pavlo@debian:~/integridad()$ gpg --keyserver keyserver.ubuntu.com --recv-keys DF9B9C49EAA9298432589D76DA87E80D6294BE9B
gpg: clave DA87E80D6294BE9B: clave pública "Debian CD signing key <debian-cd@lists.debian.org>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Volvemos a verificar la firma:

```bash
pavlo@debian:~/integridad()$ gpg --verify SHA512SUMS.sign SHA512SUMS
gpg: Firmado el sáb 09 nov 2024 17:35:02 CET
gpg:                usando RSA clave DF9B9C49EAA9298432589D76DA87E80D6294BE9B
gpg: Firma correcta de "Debian CD signing key <debian-cd@lists.debian.org>" [desconocido]
gpg: ATENCIÓN: ¡Esta clave no está certificada por una firma de confianza!
gpg:          No hay indicios de que la firma pertenezca al propietario.
Huellas dactilares de la clave primaria: DF9B 9C49 EAA9 2984 3258  9D76 DA87 E80D 6294 BE9B
```

Y efectivamente, el hash del fichero resumen coincide con el hash del fichero resumen que Debian ha firmado, por lo que podemos concluir que no ha habido ninguna manipulación y las imágenes ISO están totalmente limpias. 

Al no tener validada la clave de Debian nos ha mostrado la advertencia de seguridad, pero eso no tiene nada que ver, pues la firma ha sido correctamente verificada.

## Tarea 4: Integridad y autenticidad (apt secure)

APT Secure es el mecanismo utilizado por Debian para garantizar que los paquetes instalados desde sus repositorios oficiales sean legítimos y no hayan sido modificados. Este sistema utiliza criptografía asimétrica para verificar la autenticidad de los paquetes.

### ¿Qué software utiliza apt secure para realizar la criptografía asimétrica?

APT Secure utiliza GNU Privacy Guard (GPG) para realizar la criptografía asimétrica, firmando digitalmente los paquetes y verificando las firmas de los mismos.

### ¿Para que sirve el comando `apt-key`? ¿Qué muestra el comando `apt-key` list?

El comando apt-key es una herramienta que permite gestionar las claves utilizadas por APT para autenticar paquetes, considerando como confiables aquellos paquetes que han sido correctamente autenticados mediante estas claves. Las opciones más comunes son:

- add: Añade una nueva clave a la lista de claves de confianza desde un archivo que se pasa como parámetro.

- del: Elimina una clave de la lista de claves de confianza, especificando el fingerprint de la clave como parámetro.

- export: Muestra la clave a través de la salida estándar, indicando el fingerprint de la misma como parámetro.

- exportall: Muestra todas las claves de confianza por la salida estándar.

- list: Muestra todas las claves de confianza.

- finger: Muestra los fingerprints de todas las claves de confianza.

Por ejemplo, una salida del comando sería:

```bash
pavlo@debian:~()$ apt-key list
Warning: apt-key is deprecated. Manage keyring files in trusted.gpg.d instead (see apt-key(8)).
/etc/apt/trusted.gpg
--------------------
pub   rsa4096 2017-02-22 [SCEA]
      9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
uid        [desconocida] Docker Release (CE deb) <docker@docker.com>
sub   rsa4096 2017-02-22 [S]

pub   dsa1024 2004-09-12 [SC]
      6302 39CC 130E 1A7F D81A  27B1 4097 6EAF 437D 05B5
uid        [desconocida] Ubuntu Archive Automatic Signing Key <ftpmaster@ubuntu.com>
sub   elg2048 2004-09-12 [E]

pub   rsa4096 2024-05-03 [SC]
      3648 37CF 91E0 7091 0231  C2FE 8219 B3A0 AEF3 D498
uid        [desconocida] Launchpad PPA for elementary OS team

pub   rsa1024 2011-10-01 [SC]
      6C87 69CE DC20 F5E6 6C3B  7D37 BF36 996C 4E1F 8A59
uid        [desconocida] Launchpad PPA for elementary OS team

/etc/apt/trusted.gpg.d/debian-archive-bookworm-automatic.asc
------------------------------------------------------------
pub   rsa4096 2023-01-21 [SC] [caduca: 2031-01-19]
      B8B8 0B5B 623E AB6A D877  5C45 B7C5 D7D6 3509 47F8
uid        [desconocida] Debian Archive Automatic Signing Key (12/bookworm) <ftpmaster@debian.org>
sub   rsa4096 2023-01-21 [S] [caduca: 2031-01-19]

/etc/apt/trusted.gpg.d/debian-archive-bookworm-security-automatic.asc
---------------------------------------------------------------------
pub   rsa4096 2023-01-21 [SC] [caduca: 2031-01-19]
      05AB 9034 0C0C 5E79 7F44  A8C8 254C F3B5 AEC0 A8F0
uid        [desconocida] Debian Security Archive Automatic Signing Key (12/bookworm) <ftpmaster@debian.org>
sub   rsa4096 2023-01-21 [S] [caduca: 2031-01-19]

/etc/apt/trusted.gpg.d/debian-archive-bookworm-stable.asc
---------------------------------------------------------
pub   ed25519 2023-01-23 [SC] [caduca: 2031-01-21]
      4D64 FEC1 19C2 0290 67D6  E791 F8D2 585B 8783 D481
uid        [desconocida] Debian Stable Release Key (12/bookworm) <debian-release@lists.debian.org>

/etc/apt/trusted.gpg.d/debian-archive-bullseye-automatic.asc
------------------------------------------------------------
pub   rsa4096 2021-01-17 [SC] [caduca: 2029-01-15]
      1F89 983E 0081 FDE0 18F3  CC96 73A4 F27B 8DD4 7936
uid        [desconocida] Debian Archive Automatic Signing Key (11/bullseye) <ftpmaster@debian.org>
sub   rsa4096 2021-01-17 [S] [caduca: 2029-01-15]

/etc/apt/trusted.gpg.d/debian-archive-bullseye-security-automatic.asc
---------------------------------------------------------------------
pub   rsa4096 2021-01-17 [SC] [caduca: 2029-01-15]
      AC53 0D52 0F2F 3269 F5E9  8313 A484 4904 4AAD 5C5D
uid        [desconocida] Debian Security Archive Automatic Signing Key (11/bullseye) <ftpmaster@debian.org>
sub   rsa4096 2021-01-17 [S] [caduca: 2029-01-15]

/etc/apt/trusted.gpg.d/debian-archive-bullseye-stable.asc
---------------------------------------------------------
pub   rsa4096 2021-02-13 [SC] [caduca: 2029-02-11]
      A428 5295 FC7B 1A81 6000  62A9 605C 66F0 0D6C 9793
uid        [desconocida] Debian Stable Release Key (11/bullseye) <debian-release@lists.debian.org>

/etc/apt/trusted.gpg.d/debian-archive-buster-automatic.asc
----------------------------------------------------------
pub   rsa4096 2019-04-14 [SC] [caduca: 2027-04-12]
      80D1 5823 B7FD 1561 F9F7  BCDD DC30 D7C2 3CBB ABEE
uid        [desconocida] Debian Archive Automatic Signing Key (10/buster) <ftpmaster@debian.org>
sub   rsa4096 2019-04-14 [S] [caduca: 2027-04-12]

/etc/apt/trusted.gpg.d/debian-archive-buster-security-automatic.asc
-------------------------------------------------------------------
pub   rsa4096 2019-04-14 [SC] [caduca: 2027-04-12]
      5E61 B217 265D A980 7A23  C5FF 4DFA B270 CAA9 6DFA
uid        [desconocida] Debian Security Archive Automatic Signing Key (10/buster) <ftpmaster@debian.org>
sub   rsa4096 2019-04-14 [S] [caduca: 2027-04-12]

/etc/apt/trusted.gpg.d/debian-archive-buster-stable.asc
-------------------------------------------------------
pub   rsa4096 2019-02-05 [SC] [caduca: 2027-02-03]
      6D33 866E DD8F FA41 C014  3AED DCC9 EFBF 77E1 1517
uid        [desconocida] Debian Stable Release Key (10/buster) <debian-release@lists.debian.org>

/etc/apt/trusted.gpg.d/deb-multimedia-keyring.gpg
-------------------------------------------------
pub   rsa4096 2014-03-05 [SC]
      A401 FF99 368F A1F9 8152  DE75 5C80 8C2B 6555 8117
uid        [desconocida] Christian Marillat <marillat@debian.org>
uid        [desconocida] Christian Marillat <marillat@free.fr>
uid        [desconocida] Christian Marillat <marillat@deb-multimedia.org>
sub   rsa4096 2014-03-05 [E]

/etc/apt/trusted.gpg.d/google-chrome.gpg
----------------------------------------
pub   rsa4096 2016-04-12 [SC]
      EB4C 1BFD 4F04 2F6D DDCC  EC91 7721 F63B D38B 4796
uid        [desconocida] Google Inc. (Linux Packages Signing Authority) <linux-packages-keymaster@google.com>
sub   rsa4096 2023-02-15 [S] [caduca: 2026-02-14]
sub   rsa4096 2024-01-30 [S] [caduca: 2027-01-29]

/etc/apt/trusted.gpg.d/microsoft.gpg
------------------------------------
pub   rsa2048 2015-10-28 [SC]
      BC52 8686 B50D 79E3 39D3  721C EB3E 94AD BE12 29CF
uid        [desconocida] Microsoft (Release signing) <gpgsecurity@microsoft.com>
```

### ¿En que fichero se guarda el anillo de claves que guarda la herramienta apt-key?

El anillo de claves utilizado por `apt-key` se guarda en el fichero `/etc/apt/trusted.gpg` y en cualquier archivo `.gpg` dentro de `/etc/apt/trusted.gpg.d/`.

### ¿Qué contiene el archivo `Release` de un repositorio de paquetes?. ¿Y el archivo `Release.gpg`?. Puedes ver estos archivos en el repositorio http://ftp.debian.org/debian/dists/Debian10.1/. Estos archivos se descargan cuando hacemos un `apt update`.

El archivo `Release` contiene información sobre el repositorio, como la versión del sistema operativo, la arquitectura, la lista de componentes (main, contrib, non-free) y otra información relevante. También incluye firmas digitales (hashes criptográficos) para cada archivo de paquete (por ejemplo, Packages y Packages.gz) dentro del repositorio. Estos hashes se utilizan para verificar la integridad de los archivos descargados.

El archivo `Release.gpg` contiene la firma digital asociada con el archivo `Release`. Esta firma es generada por la entidad que mantiene el repositorio y se utiliza para verificar la autenticidad del archivo `Release`. Esta firma digital se verifica durante el proceso de `apt update`, asegurando que el archivo `Release` no haya sido modificado y que realmente provenga del repositorio oficial.

### Explica el proceso por el cual el sistema nos asegura que los ficheros que estamos descargando son legítimos.

Este proceso implica el uso de criptografía asimétrica y firmas digitales:

- Descarga del archivo “Release” y su firma (“Release.gpg”): cuando ejecutamos `apt update`, el sistema descarga el archivo `Release` y su firma asociada `Release.gpg` desde el repositorio Debian o el mirror especificado.

- Verificación de la firma digital: el archivo `Release.gpg` contiene la firma digital generada por la clave privada de la entidad que mantiene el repositorio. Utilizando la clave pública correspondiente a esa clave privada (que generalmente ya está instalada en el sistema), se verifica la autenticidad de la firma digital. Si la verificación falla, el proceso se detendrá, ya que indica que el archivo `Release` puede haber sido modificado.

- Verificación de la integridad del archivo “`Release`”: si la firma digital es válida, se procede a verificar la integridad del archivo `Release`. El archivo `Release` contiene hashes criptográficos (generalmente SHA256) de otros archivos importantes en el repositorio, como `Packages` y `Packages.gz`. Se recalcula el hash localmente y se compara con los hashes proporcionados en el archivo `Release`. Si hay alguna discrepancia, se asume que los archivos pueden haber sido modificados y el proceso se detiene.

- Descarga de archivos de índice de paquetes (por ejemplo, Packages o Packages.gz): si la verificación de firma y la integridad del archivo `Release` son exitosas, el sistema procede a descargar los archivos de índice de paquetes mencionados en el archivo `Release`.

- Verificación de la integridad de los archivos de paquetes: similar al paso anterior, se verifica la integridad de los archivos de paquetes utilizando los hashes proporcionados en los archivos de índice de paquetes.

### Añade de forma correcta el repositorio de virtualbox añadiendo la clave pública de virtualbox como se indica en la [documentación](https://www.virtualbox.org/wiki/Linux_Downloads).

En primer lugar añadimos el repositorio con los siguientes comando:

```bash
pavlo@debian:~()$ sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian bookworm contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
```

Y ahora descargamos e importamos la clave pública de Oracle con el siguiente comando:

```bash
pavlo@debian:~()$ wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo gpg --dearmor -o /usr/share/keyrings/oracle-virtualbox-2016.gpg
```

Hacemos un apt update y ya encontramos el repositorio listo para descargar Virtualbox:

```bash
pavlo@debian:~()$ sudo apt update
Obj:2 https://deb.nodesource.com/node_20.x nodistro InRelease                                                                                                               
Obj:4 https://dl.google.com/linux/chrome/deb stable InRelease                                                                                                               
Ign:3 https://ppa.launchpad.net/elementary-os/stable/ubuntu focal InRelease                                                                                                 
Obj:1 https://deb-multimedia.org bookworm InRelease                                                                                                                         
Des:8 https://packages.microsoft.com/repos/code stable InRelease [3.590 B]                                                                                        
Obj:5 https://deb.debian.org/debian bookworm InRelease                                                                             
Obj:6 https://security.debian.org/debian-security bookworm-security InRelease   
Des:9 https://download.virtualbox.org/virtualbox/debian bookworm InRelease [4.434 B]
Obj:7 https://deb.debian.org/debian bookworm-updates InRelease                           
Des:10 https://packages.microsoft.com/repos/code stable/main armhf Packages [18,3 kB]
Des:11 https://packages.microsoft.com/repos/code stable/main arm64 Packages [18,2 kB]
Des:12 https://packages.microsoft.com/repos/code stable/main amd64 Packages [18,2 kB]
Ign:3 https://ppa.launchpad.net/elementary-os/stable/ubuntu focal InRelease
Des:13 https://download.virtualbox.org/virtualbox/debian bookworm/contrib amd64 Packages [1.947 B]
Des:14 https://download.virtualbox.org/virtualbox/debian bookworm/contrib amd64 Contents (deb) [4.375 B]
```

## Tarea 5: Autentificación: ejemplo SSH

### Explica los pasos que se producen entre el cliente y el servidor para que el protocolo cifre la información que se transmite? ¿Para qué se utiliza la criptografía simétrica? ¿Y la asimétrica?

El protocolo SSH utiliza tanto criptografía simétrica como asimétrica para garantizar la seguridad en la comunicación entre el cliente y el servidor. Estos son los pasos que se producen:

1. El cliente inicia la conexión al servidor SSH enviando una solicitud de conexión. Intercambio de identificación y parámetros:

2. El servidor y el cliente intercambian información sobre sus capacidades y parámetros de configuración.

3. Negociación de algoritmos: se realiza una negociación para seleccionar los algoritmos que se utilizarán en la conexión, incluyendo algoritmos para cifrado simétrico, funciones hash, intercambio de claves, etc.

4. Intercambio de claves de sesión (cripografía asimétrica): el cliente y el servidor acuerdan sobre una clave de sesión utilizando criptografía asimétrica. Usualmente, el algoritmo de intercambio de claves utilizado es Diffie-Hellman.

5. Autenticación: en esta fase, se puede realizar la autenticación de las partes. Esto puede involucrar la presentación de credenciales por parte del cliente (como contraseñas o certificados).

6. Generación de la clave de sesión compartida (criptografía simétrica): a partir de la información intercambiada en el paso anterior, ambas partes generan de manera independiente una clave de sesión compartida. Esta clave de sesión será utilizada para cifrar y descifrar los datos durante la sesión.

7. Cifrado de la sesión (criptografía simétrica): a partir de este punto, la conexión SSH utiliza la criptografía simétrica para cifrar los datos durante la transmisión. La clave de sesión compartida se utiliza para este propósito, proporcionando eficiencia y velocidad en el cifrado.

8. Intercambio de mensajes cifrados: Todos los mensajes intercambiados entre el cliente y el servidor, incluyendo comandos, respuestas y otros datos, se cifran utilizando la clave de sesión compartida.

La criptografía simétrica se utiliza para cifrar los datos durante la transmisión debido a su eficiencia. Es más rápida que la criptografía asimétrica, por lo que es ideal para cifrar grandes cantidades de datos. Sin embargo, la criptografía asimétrica se utiliza en la fase de intercambio de claves para asegurar que las claves de sesión compartida se generen de forma segura y sin necesidad de intercambiar claves directamente, lo que sería menos seguro. La combinación de ambos tipos de criptografía en SSH aprovecha las fortalezas de cada uno para proporcionar un entorno de comunicación seguro y eficiente.

### Explica los dos métodos principales de autentificación: por contraseña y utilizando un par de claves públicas y privadas.

- **Autenticación por contraseña**: el usuario inicia una conexión SSH proporcionando un nombre de usuario y contraseña, y son enviados al servidor. El servidor compara la contraseña ingresada con la almacenada para el usuario. Este método es sencillo aunque la seguridad depende de la complejidad y robustez de la contraseña, y puede ser vulnerable a ataques de fuerza bruta o de suplantación de identidad si estas son débiles.

- **Autenticación por par de claves**: el usuario genera un par de claves. La clave pública se inyecta en el servidor SSH y se asocia con el nombre de usuario correspondiente. Al iniciarse la conexión SSH, el cliente debe hacerlo con su clave privada para demostrar la identidad. El servidor utiliza la clave pública asociada al usuario para verificar la autenticidad de la clave privada del cliente. Este método proporciona un alto nivel de seguridad, superior al método de autenticación por contraseña (por ejemplo es resistente a los ataques por fuerza bruta). Además también permite el acceso a un servidor sin necesidad de ingresar una contraseña cada vez que se establece la conexión.

### En el cliente, ¿para que sirve el contenido que se guarda en el fichero `~/.ssh/know_hosts`? 

Este archivo almacena los fingerprints de las claves públicas de los hosts remotos a los que el cliente se ha conectado anteriormente. Cuando el cliente se va a conectar a un host remoto, la clave pública de ese host se almacena en este archivo. Una vez almacenada en el cliente, en la próxima conexión se vuelve a calcular el fingerprint del host remoto y se compara con el que ya estaba almacenado de anteriores conexiones. Si la huella digital coincide con una entrada existente, se considera que el host es auténtico y la conexión procede sin problemas. Si la huella digital no coincide, el cliente emite una advertencia de posible ataque de “man-in-the-middle” (intermediario malicioso) porque la clave pública del host remoto ha cambiado.

### ¿Qué significa este mensaje que aparece la primera vez que nos conectamos a un servidor?

```bash
$ ssh debian@172.22.200.74
 The authenticity of host '172.22.200.74 (172.22.200.74)' can't be established.
 ECDSA key fingerprint is SHA256:7ZoNZPCbQTnDso1meVSNoKszn38ZwUI4i6saebbfL4M.
 Are you sure you want to continue connecting (yes/no)? 
```

En este escenario, el usuario tiene la opción de continuar o no con la conexión, dependiendo de cuánto confíe en el servidor. Si decide aceptar, la clave del servidor se guardará en el archivo situado en `~/.ssh/known_hosts`. Esto asegura que, en futuras conexiones, no se le pedirá nuevamente al cliente que confirme, ya que el sistema verificará si la clave ya está registrada en dicho archivo.

### En ocasiones cuando estamos trabajando en el cloud, y reutilizamos una ip flotante nos aparece este mensaje:

```bash
$ ssh debian@172.22.200.74
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
 Someone could be eavesdropping on you right now (man-in-the-middle attack)!
 It is also possible that a host key has just been changed.
 The fingerprint for the ECDSA key sent by the remote host is
 SHA256:W05RrybmcnJxD3fbwJOgSNNWATkVftsQl7EzfeKJgNc.
 Please contact your system administrator.
 Add correct host key in /home/jose/.ssh/known_hosts to get rid of this message.
 Offending ECDSA key in /home/jose/.ssh/known_hosts:103
   remove with:
   ssh-keygen -f "/home/jose/.ssh/known_hosts" -R "172.22.200.74"
 ECDSA host key for 172.22.200.74 has changed and you have requested strict checking.
```

Esto significa que nos estamos conectando a un host remoto que previamente teníamos su fingerprint almacenada en este archivo, pero al comparar la actual del host remoto con la que teníamos almacenada estas no coinciden, por lo que nos manda la alerta.

### ¿Qué guardamos y para qué sirve el fichero en el servidor `~/.ssh/authorized_keys`?

En este archivo es donde se almacenan las claves públicas de los clientes remotos que desean acceder al servidor. Al realizarse la conexión a un usuario, la clave pública del cliente debe estar presente en el archivo `authorized_keys` del usuario para que tenga permisos de acceso a esa sesión. La seguridad de este archivo es importante, y sus permisos típicos son 600: de lectura y escritura solo para el propietario.
