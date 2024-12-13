---
title: "Cifrado asimétrico con gpg y openssl"
date: 2024-12-12 20:15:00 +0000
categories: [Seguridad, Criptografía]
tags: [Criptografía]
author: pablo
description: "En esta práctica vamos a cifrar ficheros utilizando cifrado asimétrico utilizando el programa gpg. "
toc: true
comments: true
image:
  path: /assets/img/posts/gpg/portadagpg.png
---

## Tarea 1: Generación de claves (gpg)

### 1. Genera un par de claves (pública y privada). ¿En que directorio se guarda las claves de un usuario?

Para generar el par de claves haremos uso de la opción `--gen-key` de gpg:
```bash
pavlo@debian:~()$ gpg --gen-key
gpg (GnuPG) 2.2.40; Copyright (C) 2022 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Nota: Usa "gpg --full-generate-key" para el diálogo completo de generación de clave.

GnuPG debe construir un ID de usuario para identificar su clave.

Nombre y apellidos:
```

Primero, se nos solicitará que ingresemos nuestro nombre completo, incluyendo los apellidos, con el objetivo de diferenciar nuestra clave de las demás. Escribiremos esta información y procederemos al siguiente paso.

```bash
Nombre y apellidos: Pablo Martín Hidalgo
Dirección de correo electrónico: pmartinhidalgo19@gmail.com
```

A continuación, será necesario proporcionar nuestra dirección de correo electrónico. La ingresaremos y continuaremos con el proceso.

```bash
Está usando el juego de caracteres 'utf-8'.
Ha seleccionado este ID de usuario:
    "Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>"

¿Cambia (N)ombre, (D)irección o (V)ale/(S)alir?
```

Cuando hayamos completado estos datos, se nos mostrará un resumen para confirmarlos. Si todo es correcto, seleccionaremos la opción "V" para confirmar.

```bash
¿Cambia (N)ombre, (D)irección o (V)ale/(S)alir? V

Es necesario generar muchos bytes aleatorios. Es una buena idea realizar
alguna otra tarea (trabajar en otra ventana/consola, mover el ratón, usar
la red y los discos) durante la generación de números primos. Esto da al
generador de números aleatorios mayor oportunidad de recoger suficiente
entropía.
```

En este momento, se nos pedirá que configuremos una frase de paso que protegerá nuestra clave privada. Será necesario ingresarla dos veces para confirmar y, una vez hecho esto, se iniciará el proceso de generación del par de claves. Como se indica en el mensaje mostrado, es recomendable realizar alguna actividad en nuestro equipo durante este proceso para ayudar a generar entropía.

```bash
gpg: creado el directorio '/home/pavlo/.gnupg/openpgp-revocs.d'
gpg: certificado de revocación guardado como '/home/pavlo/.gnupg/openpgp-revocs.d/9D0AB661A8C5977C20924020130D7BAF24114BE7.rev'
claves pública y secreta creadas y firmadas.

pub   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      9D0AB661A8C5977C20924020130D7BAF24114BE7
uid                      Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]
```

Una vez completada la generación, nuestro par de claves estará creado y añadido con total confianza a nuestro keyring `pubring.kbx`, que se encuentra ubicado en el directorio personal dentro de la carpeta `.gnupg/`. Además, de manera automática se habrá generado un certificado de revocación en `.gnupg/openpgp-revocs.d/`. Este certificado será útil en caso de que nuestra clave privada sea comprometida o si decidimos dejar de usar este par de claves, permitiendo informar a otros usuarios que la clave pública asociada no debe ser utilizada más para cifrar.

### 2. Lista las claves públicas que tienes en tu almacén de claves. Explica los distintos datos que nos muestra. ¿Cómo deberías haber generado las claves para indicar, por ejemplo, que tenga un 1 mes de validez?

Para listar las claves públicas haremos uso de la opción `--list-keys` de gpg:
```bash
pavlo@debian:~()$ gpg --list-keys
gpg: comprobando base de datos de confianza
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: nivel: 0  validez:   1  firmada:   0  confianza: 0-, 0q, 0n, 0m, 0f, 1u
gpg: siguiente comprobación de base de datos de confianza el: 2026-12-12
/home/pavlo/.gnupg/pubring.kbx
------------------------------
pub   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      9D0AB661A8C5977C20924020130D7BAF24114BE7
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]
```

Si quisiéramos generar claves con un período de validez específico, podríamos haber utilizado la opción --full-gen-key de GPG. Esto nos habría mostrado un mensaje donde se solicita configurar el tiempo de validez.

```bash
pavlo@debian:~()$ gpg --full-generate-key
gpg (GnuPG) 2.2.40; Copyright (C) 2022 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Por favor seleccione tipo de clave deseado:
   (1) RSA y RSA (por defecto)
   (2) DSA y ElGamal
   (3) DSA (sólo firmar)
   (4) RSA (sólo firmar)
  (14) Existing key from card
Su elección: 
las claves RSA pueden tener entre 1024 y 4096 bits de longitud.
¿De qué tamaño quiere la clave? (3072) 
El tamaño requerido es de 3072 bits
Por favor, especifique el período de validez de la clave.
         0 = la clave nunca caduca
      <n>  = la clave caduca en n días
      <n>w = la clave caduca en n semanas
      <n>m = la clave caduca en n meses
      <n>y = la clave caduca en n años
¿Validez de la clave (0)?
```

En este punto, podríamos haber indicado la duración deseada siguiendo las opciones que se nos presentan. Por ejemplo, para establecer una validez de un mes, podríamos haber ingresado **30**, **4w** o **1m**, ya que todas estas opciones representan el mismo intervalo de tiempo.

### 3. Lista las claves privadas de tu almacén de claves

Para listar las claves privadas haremos uso de la opción `--list-secret-keys` de gpg:
```bash
pavlo@debian:~()$ gpg --list-secret-keys
/home/pavlo/.gnupg/pubring.kbx
------------------------------
sec   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      9D0AB661A8C5977C20924020130D7BAF24114BE7
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
ssb   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]
```

Cuando listamos las claves públicas obtuvimos las siguientes abreviaturas:

- **pub**: Clave primaria pública (public primary key).
- **uid**: Identificador único (unique identifier).
- **sub**: Clave secundaria pública (public sub-key).

Al listar las claves privadas con `gpg --list-secret-keys`, las abreviaturas mostradas fueron:

- **sec**: Clave primaria privada (secret primary key).
- **uid**: Identificador único (unique identifier).
- **ssb**: Clave secundaria privada (secret sub-key).

En criptografía asimétrica trabajamos con pares de claves: una clave pública para encriptar o comprobar firmas, y una clave privada (secreta) para desencriptar o firmar, respectivamente.

Cuando generamos un par de claves OpenPGP con GnuPG, se crean por defecto:

1. **Un par de claves primario** o **master key**: 
   - Contiene uno o más identificadores de usuario (*user-IDs*), como nombre, apellidos y correo electrónico.
   - Se utiliza para firmar o comprobar firmas, ya que es una prueba de identidad.
   - La clave privada de este par debe protegerse cuidadosamente.

2. **Un par de claves secundario**: 
   - Está firmado por el par de claves primario, lo que garantiza que pertenece al *user-ID*.
   - Se utiliza exclusivamente para encriptar o desencriptar información.

La separación entre pares de claves maestros y secundarios permite revocar estos últimos sin afectar a los primeros y almacenarlos por separado. En esencia, los pares de claves secundarios son independientes, pero están vinculados al par maestro.

Cuando ejecutamos `gpg --list-keys`, la salida incluyó información sobre:

- **Claves públicas del par maestro (pub)**.
- **Claves públicas del par secundario (sub)**.

Al ejecutar `gpg --list-secret-keys`, vimos información sobre:

- **Claves privadas del par maestro (sec)**.
- **Claves privadas del par secundario (ssb)**.

En ambos casos, también se mostró un **uid** que representa la identidad del usuario asociada a las claves.

La relación entre los pares de claves es la siguiente:

- **pub ↔ sec**: Clave primaria pública y su clave privada asociada.
- **sub ↔ ssb**: Clave secundaria pública y su clave privada asociada.

Además, la salida incluyó información adicional como:

- El algoritmo utilizado (por ejemplo, `rsa3072`).
- La fecha de creación del par de claves (por ejemplo, `2020-10-07`).
- Los flags de las claves.
- La fecha de caducidad (por ejemplo, `2022-10-07`).

Cada par de claves tiene flags que indican sus funciones:

- **S**: Firmar archivos (Signing).
- **C**: Certificar claves (Certify).
- **A**: Autenticarse (Authenticate), como iniciar sesión en una máquina.
- **E**: Encriptar información (Encrypt).

Por ejemplo:

- El par de claves maestro suele tener los flags **[SC]**, indicando que puede firmar archivos y certificar claves.
- El par de claves secundario tiene el flag **[E]**, utilizado para encriptar y desencriptar información.

El par de claves maestro es utilizado para firmar y comprobar firmas (**[SC]**), mientras que el par de claves secundario es empleado para encriptar y desencriptar información (**[E]**).

## Tarea 2: Importar/exportar clave pública (gpg)

### 1. Exporta tu clave pública en formato ASCII, guárdalo en un archivo “nombre_apellido.asc” y envíalo al compañero con el que vas a hacer esta práctica.

Para exportar nuestras claves públicas, utilizaremos la opción `--export` de `gpg` junto con la opción `-a <nombre>`. Esto generará una salida en formato ASCII que puede ser redirigida a un archivo. 

El `<nombre>` que debemos especificar es el mismo que introdujimos al generar el par de claves (generalmente nuestro nombre o dirección de correo electrónico).

El comando a ejecutar es el siguiente:
```bash
pavlo@debian:~()$ gpg --export -a "Pablo Martín Hidalgo" > pablo_martin.asc
pavlo@debian:~()$ ls -l pablo_martin.asc 
-rw-r--r-- 1 pavlo pavlo 2476 dic 12 18:33 pablo_martin.asc
```

Esta práctica la he realizado junto a **Jose Antonio Canalo**, así que le he enviado mis claves públicas exportadas a través de Discord:

![image](/assets/img/posts/gpg/gpg1.png)

### 2. Importa las claves públicas recibidas de vuestro compañero

Al igual que yo, Jose me ha pasado su clave pública por Discord y como vemos ya la tengo descargada:

![image1](/assets/img/posts/gpg/gpgjose.png)

Para importar las claves públicas de otro usuario, utilizaremos la opción `--import` de `gpg`, seguida del nombre del archivo que contiene la clave pública. En este caso, el archivo a importar es el que hemos recibido, por ejemplo, `alejandro_gutierrez.asc`.

El comando a ejecutar sería:
```bash
pavlo@debian:~()$ gpg --import joseantoniocanalo.asc 
gpg: clave 5DD99C6F8D4E1C65: clave pública "jose antonio Canalo Gonzalez <joseantoniocgonzalez83@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Como vemos nos ha devuelto un mensaje por pantalla informando que las claves públicas de Jose han sido correctamente importadas.

### 3. Comprueba que las claves se han incluido correctamente en vuestro keyring

De nuevo, volveremos a hacer uso de opción `--list-keys` de gpg para verificar que las claves públicas han sido correctamente importadas a nuestro keyring:
```bash
pavlo@debian:~()$ gpg --list-keys
/home/pavlo/.gnupg/pubring.kbx
------------------------------
pub   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      9D0AB661A8C5977C20924020130D7BAF24114BE7
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]

pub   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      279F1D439CE7DA18300BF21D5DD99C6F8D4E1C65
uid        [desconocida] jose antonio Canalo Gonzalez <joseantoniocgonzalez83@gmail.com>
sub   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]
```

Y efectivamente, las claves públicas de Jose han sido correctamente importadas a nuestro keyring en `.gnupg/pubring.kbx`.

## Tarea 3: Cifrado asimétrico con claves públicas (gpg)

### 1. Cifraremos un archivo cualquiera y lo remitiremos por email a uno de nuestros compañeros que nos proporcionó su clave pública

En este ejemplo, tengo un archivo llamado `mensaje_encriptado.txt`, el cual quiero cifrar con la clave pública de Jose para enviárselo de forma segura. Para ello, utilizaremos la opción `-e` de `gpg` junto con:

- `-u <remitente>`: Indica quién es el remitente, especificando la clave privada que se usará para firmar, si es necesario.
- `-r <destinatario>`: Especifica el destinatario, cuya clave pública será usada para cifrar el archivo.

El comando a ejecutar sería:
```bash
pavlo@debian:~()$ gpg -e -u "Pablo Martín Hidalgo" -r "jose antonio Canalo Gonzalez" mensaje_encriptado.txt
gpg: 6CB51A1718E6B9E9: No hay seguridad de que esta clave pertenezca realmente
al usuario que se nombra

sub  rsa3072/6CB51A1718E6B9E9 2024-12-12 jose antonio Canalo Gonzalez <joseantoniocgonzalez83@gmail.com>
 Huella clave primaria: 279F 1D43 9CE7 DA18 300B  F21D 5DD9 9C6F 8D4E 1C65
      Huella de subclave: F8AF 9D20 076C 877E DDEF  DE6B 6CB5 1A17 18E6 B9E9

No es seguro que la clave pertenezca a la persona que se nombra en el
identificador de usuario. Si *realmente* sabe lo que está haciendo,
puede contestar sí a la siguiente pregunta.

¿Usar esta clave de todas formas? (s/N) s
```

Al listar los archivos en el directorio utilizando el comando:

```bash
pavlo@debian:~()$ ls -l | egrep mensaje_encriptado
-rw-r--r--  1 pavlo pavlo   25 dic 12 18:45 mensaje_encriptado.txt
-rw-r--r--  1 pavlo pavlo  507 dic 12 18:46 mensaje_encriptado.txt.gpg
```

Como podemos observar ahora tenemos dos archivos, el original (mensaje_encriptado.txt) y el encriptado (mensaje_encriptado.txt.gpg).

Tras ello, le enviaré dicho fichero a Jose por Discord:

![image](/assets/img/posts/gpg/gpg2.png)

### 2. Nuestro compañero, a su vez, nos remitirá un archivo cifrado para que nosotros lo descifremos.

Al igual que yo, Jose me ha pasado su mensaje cifrado por Discord:

![image](/assets/img/posts/gpg/cifradojose.png)

### 3. Tanto nosotros como nuestro compañero comprobaremos que hemos podido descifrar los mensajes recibidos respectivamente

Para descifrar un archivo que hemos recibido, utilizaremos la opción `-d` de `gpg`, seguida del nombre del archivo a descifrar. En este caso, el archivo que hemos recibido de Jose es `mensaje_cifrado.gpg`.

El comando a ejecutar sería:
```bash
pavlo@debian:~()$ gpg -d mensaje_cifrado.gpg
gpg: cifrado con clave de 3072 bits RSA, ID 8E63E9C3C10E3D32, creada el 2024-12-12
      "Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>"
Espero que ganemos el sábado
```
Tras ejecutar el comando, se nos pedirá la frase de paso para desbloquear la clave privada con la que vamos a descifrar el fichero (pues anteriormente fue cifrado con la clave pública asociada a dicha clave privada).

Como se puede observar, el contenido del archivo descifrado no está en texto plano, sino que corresponde a un archivo `.txt` encriptado. 
```bash
pavlo@debian:~()$ cat mensaje_cifrado.gpg 
���c���=2
         �������42�曄:�1�J;)�	6�>�),��_�-g�g*���pȆ]8@�x
�,K��Ҭ�,��g�W?�m�"��dA0jb��z�\����ݑb��a�5mk�6�
�
 ��c��ޘ_="�e�G�օb}+�3(A&�T��uG�h��?��/5�;D� ֖B������. ���Al�B�[_]�Tno7��ݯ�M��IT���;BtLn���Xqߵ�>�R-�[[Z�D���-������.C��zu���|���/�ˊ��'5&
                                                                                                                                      �2r����>Vq���[ԙ��TK-����N~3Q=�g0C:���XE���U:�`V�~	�0��˴������E$�j�~}�������2���܍�L״��k���d=-���L1T'�bp����rBjq�B�����ad1:�'s��M
2�
  �tw��i%�}A#%Xh�Y`��k�,�mt>|~
                              �]��ɽVV7b^��K
```

Para visualizarlo correctamente, debemos redirigir la salida del archivo descifrado a un archivo de formato `.txt`.

Para ello, volvemos a ejecutar el comando de descifrado, pero esta vez redirigiendo la salida a un archivo con extensión `.txt`, como por ejemplo `descifrado.txt`.

El comando a ejecutar sería:
```bash
pavlo@debian:~()$ gpg -d mensaje_cifrado.gpg > descifrado.txt
gpg: cifrado con clave de 3072 bits RSA, ID 8E63E9C3C10E3D32, creada el 2024-12-12
      "Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>"
```

Y como vemos el contenido es totalmente visible:
```bash
pavlo@debian:~()$ cat descifrado.txt 
Espero que ganemos el sábado
```

### 4. Por último, enviaremos el documento cifrado a alguien que no estaba en la lista de destinatarios y comprobaremos que este usuario no podrá descifrar este archivo

Para este punto hemos pedido ayuda a **Andrés Morales**, al cual le he enviado el fichero y ha comprobado si podía abrirlo o no. Y como podemos observar obtuvo el siguiente error:
```bash
madandy@toyota-hilux:~/Descargas$ gpg -d mensaje_encriptado.txt.gpg 
gpg: cifrado con clave RSA, ID 6CB51A1718E6B9E9
gpg: descifrado fallido: No secret key
```

Como se puede apreciar, el descifrado ha fallado dado que no ha encontrado ninguna clave privada para descifrar dicho fichero.

### 5. Para terminar, indica los comandos necesarios para borrar las claves públicas y privadas que posees

Es importante seguir un orden específico al eliminar un par de claves en GPG para evitar errores. Primero, debemos eliminar la clave privada asociada y, posteriormente, la clave pública.

Para eliminar la clave privada, utilizaremos la opción `--delete-secret-key` de `gpg`, seguida del nombre asociado al par de claves (el mismo que introdujimos al generarlo). El comando sería:

```bash
pavlo@debian:~()$ gpg --delete-secret-key "Pablo Martín Hidalgo"
gpg (GnuPG) 2.2.40; Copyright (C) 2022 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


sec  rsa3072/130D7BAF24114BE7 2024-12-12 Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>

¿Eliminar esta clave del anillo? (s/N) s
¡Es una clave secreta! ¿Eliminar realmente? (s/N) s
```

Una vez eliminada la clave privada, procedemos a eliminar la clave pública con la opción --delete-key:

```bash
pavlo@debian:~()$ gpg --delete-key "Pablo Martín Hidalgo"
gpg (GnuPG) 2.2.40; Copyright (C) 2022 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


pub  rsa3072/130D7BAF24114BE7 2024-12-12 Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>

¿Eliminar esta clave del anillo? (s/N) s
```

Al completar ambos pasos, el par de claves (tanto público como privado) habrá sido eliminado de nuestro sistema.

```bash
pavlo@debian:~()$ gpg --list-keys
gpg: comprobando base de datos de confianza
gpg: no se encuentran claves absolutamente fiables
/home/pavlo/.gnupg/pubring.kbx
------------------------------
pub   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      279F1D439CE7DA18300BF21D5DD99C6F8D4E1C65
uid        [desconocida] jose antonio Canalo Gonzalez <joseantoniocgonzalez83@gmail.com>
sub   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]
```

## Tarea 4: Exportar clave a un servidor público de claves PGP

### 1. Genera la clave de revocación de tu clave pública para utilizarla en caso de que haya problemas

Cuando generamos un par de claves con GPG, el programa crea automáticamente una clave de revocación. Sin embargo, para mostrar el proceso manual, generaremos una nueva clave de revocación.

Para generar una clave de revocación, utilizaremos la opción `--gen-revoke` de `gpg`, seguida del identificador del par de claves (conocido como *fingerprint*). Este identificador es una secuencia de 40 dígitos que podemos encontrar al listar nuestras claves públicas con el siguiente comando:

```bash
pavlo@debian:~()$ gpg --gen-revoke F0BCAC25DBEF1413DA96DFE02F56104F90EDEC18

sec  rsa3072/2F56104F90EDEC18 2024-12-12 Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>

¿Crear un certificado de revocación para esta clave? (s/N) s
Por favor elija una razón para la revocación:
  0 = No se dio ninguna razón
  1 = La clave ha sido comprometida
  2 = La clave ha sido reemplazada
  3 = La clave ya no está en uso
  Q = Cancelar
(Probablemente quería seleccionar 1 aquí)
¿Su decisión? 0
Introduzca una descripción opcional; acábela con una línea vacía:
> Ejercicios de criptografía
> 
Razón para la revocación: No se dio ninguna razón
Ejercicios de criptografía
¿Es correcto? (s/N) s
se fuerza salida con armadura ASCII.
-----BEGIN PGP PUBLIC KEY BLOCK-----
Comment: This is a revocation certificate

iQHRBCABCgA7FiEE8LysJdvvFBPalt/gL1YQT5Dt7BgFAmdbJhkdHQBFamVyY2lj
aW9zIGRlIGNyaXB0b2dyYWbDrWEACgkQL1YQT5Dt7Bgkiwv7BLuEp9rUi3hgiYhJ
hCPyh9FqkD9UJByICZmdVf/wgP9BnKIy0SC9KEEjUF9Fko6N/nDz0EMVAwZ4WtCP
flt3xq0ACJUfzGp9llP2iNujpcCbmdlwHDMwhCkvcI+ri4pb0fmZPRhw3BO9Ad4E
cDMQ2LFffJ29zbBsWS1RqYZzTGEytjB3m5BaoIq+C5HAnM7dImfKbV5DBdCLsqCc
wnwS1zvlHwFzpf9Ap6IhbmpN4Rf4H+ZBL8siVQrUDlOsbybwgBrzxLtLmaq0EZL+
kZL7QHizTHaO9bUJd/PxumfiNiuq3wq5MxdUSnXNEg52bDg4AxPYlWm9IU87wAPB
6fHFpwfzJh/VKyfZi7tD0CSb1fRN4qxg7abXRAS/4aRAprOaRFtbyvXiAswvD9oI
Y8LFxUe5P8OmvuzD9X7npsQX+H3ZbxTvJJZ9RVMn1Oxi1AHWiqqn2ae+jw7CPpgz
y9C+FFWJTL/ME4vNeZ+y+EdRboRO+tx96Q453+jwo/tlLF7u
=Oyi5
-----END PGP PUBLIC KEY BLOCK-----
Certificado de revocación creado.

Por favor consérvelo en un medio que pueda esconder; si alguien consigue
acceso a este certificado puede usarlo para inutilizar su clave.
Es inteligente imprimir este certificado y guardarlo en otro lugar, por
si acaso su medio resulta imposible de leer. Pero precaución: ¡el sistema
de impresión de su máquina podría almacenar los datos y hacerlos accesibles
a otras personas!
```

El certificado de revocación generado por GPG contiene la información necesaria para revocar un par de claves de forma oficial. Este certificado está delimitado por las etiquetas:

-----BEGIN PGP PUBLIC KEY BLOCK----- ... -----END PGP PUBLIC KEY BLOCK-----

### 2. Exporta tu clave pública al servidor pgp.rediris.es

Para compartir nuestra clave pública con otros usuarios, podemos exportarla a un servidor de claves públicas, lo que permite que cualquiera pueda buscarla y utilizarla para cifrar mensajes destinados a nosotros.

Para exportar la clave pública, utilizaremos la opción `--keyserver` para especificar el servidor al cual queremos enviar la clave y `--send-key` para indicar el identificador (ID) de la clave pública. En este caso, se utilizará el servidor `pgp.rediris.es`, y el ID será el *fingerprint* de la clave, que consta de 40 dígitos. También es posible usar únicamente los últimos 8 dígitos del *fingerprint*. El comando sería:

```bash
pavlo@debian:~()$ gpg --keyserver pgp.rediris.es --send-key F0BCAC25DBEF1413DA96DFE02F56104F90EDEC18
gpg: enviando clave 2F56104F90EDEC18 a hkp://pgp.rediris.es
```

Para confirmar que la clave ha sido subida correctamente, se puede acceder al servidor de claves públicas mediante un navegador web. En este caso, al visitar la página de búsqueda de claves de `pgp.rediris.es`, es posible introducir un identificador como el nombre o la dirección de correo electrónico en el campo de búsqueda.

Por ejemplo, al introducir el correo electrónico en el campo de búsqueda y pulsar "Search for a key", aparecerán los resultados que coincidan con la búsqueda realizada.

![image3](/assets/img/posts/gpg/rediris.png)

Si todo ha funcionado correctamente, debería verse la clave pública entre los resultados, lo que confirma que la subida al servidor de claves públicas se ha completado de manera satisfactoria. Exportar claves públicas a servidores como `pgp.rediris.es` facilita el intercambio de claves y asegura que otras personas puedan comunicarse de forma segura.

### 3. Borra la clave pública de alguno de tus compañeros de clase e impórtala ahora del servidor público de rediris

Tal y como hemos visto en uno de los ejercicios anteriores, para eliminar una clave pública de nuestro keyring, utilizaremos la opción `--delete-key` seguida del nombre asociado a la clave. En este caso, el nombre que debemos introducir es el de Jose.

```bash
pavlo@debian:~()$ gpg --delete-key "jose antonio canalo gonzalez"
gpg (GnuPG) 2.2.40; Copyright (C) 2022 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


pub  rsa3072/5DD99C6F8D4E1C65 2024-12-12 jose antonio Canalo Gonzalez <joseantoniocgonzalez83@gmail.com>

¿Eliminar esta clave del anillo? (s/N) s
```

Y listo, la clave pública de Jose ya se encuentra borrada:

```bash
pavlo@debian:~()$ gpg --list-keys
/home/pavlo/.gnupg/pubring.kbx
------------------------------
pub   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      F0BCAC25DBEF1413DA96DFE02F56104F90EDEC18
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]
```
Una vez que la clave pública ha sido totalmente eliminada, es momento de volver a importarla desde el servidor de claves públicas. Para ello, utilizaremos la opción `--keyserver` para especificar el servidor del que queremos descargar la clave y `--recv-keys` para indicar el identificador (*fingerprint*) de la clave pública. 

En este caso, el servidor a utilizar será `pgp.rediris.es`, y el ID será el *fingerprint* de 40 dígitos de la clave de Alejandro. También se pueden usar los últimos 8 dígitos del *fingerprint*.

```bash
pavlo@debian:~()$ gpg --keyserver pgp.rediris.es --recv-keys 5D55680C
gpg: clave A93FC51D5D55680C: clave pública "jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Como vemos, la clave pública de Jose ha sido importada de nuevo:

```bash
pavlo@debian:~()$ gpg --list-keys
/home/pavlo/.gnupg/pubring.kbx
------------------------------
pub   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      F0BCAC25DBEF1413DA96DFE02F56104F90EDEC18
uid        [  absoluta ] Pablo Martín Hidalgo <pmartinhidalgo19@gmail.com>
sub   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]

pub   rsa3072 2024-12-12 [SC] [caduca: 2026-12-12]
      B93E1746A5B533527796FC9DA93FC51D5D55680C
uid        [desconocida] jose antonio canalo gonzalez <joseantoniocgonzalez83@gmail.com>
sub   rsa3072 2024-12-12 [E] [caduca: 2026-12-12]
```

## Tarea 5: Cifrado asimétrico con openssl

### 1. Genera un par de claves (pública y privada)

Para generar el par de claves utilizando el algoritmo RSA, emplearemos la opción `genrsa`. Además, configuraremos una frase de paso para proteger la clave privada, utilizando el algoritmo AES128, lo que requiere incluir la opción `-aes128`. Este par de claves se almacenará en un único archivo con extensión `.pem`, y para especificar dicho archivo de salida usaremos la opción `-out <fichero>`. En este caso, el archivo de salida se llamará `key.pem`. Finalmente, indicaremos el tamaño de la clave, siendo recomendable un mínimo de 2048 bits. 

```bash
pavlo@debian:~()$ sudo openssl genrsa -aes128 -out clave.pem 2048
[sudo] contraseña para pavlo: 
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
```

Tras habernos preguntado dos veces la frase de paso, el par de claves se habrá generado en un fichero **.pem**.

### 2. Envía tu clave pública a un compañero

Dado que `openssl` genera tanto la clave privada como la pública en un único archivo, es necesario extraer la clave pública para enviársela al compañero. Esto se debe a que no es seguro compartir el archivo que contiene ambas claves. Para realizar esta extracción, utilizaremos la opción `-in <pardeclaves>` para especificar el archivo que contiene el par de claves, junto con la opción `-pubout` para indicar que se extraiga únicamente la clave pública. Además, emplearemos la opción `-out <ficherosalida>` para guardar la clave pública en un archivo separado con la extensión `.public.pem`. Por último, indicaremos el algoritmo RSA, que es el que estamos utilizando.

En este caso, el archivo del par de claves es `clave.pem` y el archivo de salida para la clave pública será `clave-publica.pem`.

```bash
pavlo@debian:~()$ sudo openssl rsa -in clave.pem -pubout -out clave-publica.pem
Enter pass phrase for clave.pem:
writing RSA key
```

Nos ha solicitado la frase de paso y justo después ha generado el fichero con la clave pública:

```bash
pavlo@debian:~()$ cat clave-publica.pem 
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwTaSZx2rgZxL8H0XoU48
Orzus0tpPn64xw/ftf0Sk5sh6MMnkVgbdug1Iydxun28rs8L1iULPoGDZUUZARMc
6oa4CuW6gu6gsfvul4bktpSps9NjJmHA0Vd2Gehp7PMncxzXFPokwwinetSZi85J
9uL2/RSJes2AxxRVxBIonOurpuBxWuaAB50ptDL2v6h0B3+A/1dtOdsSY1KmSuTq
QFKVYry3sYKvPOJMy4JX78GSCzy5E/SPwnv3f6oD22Ual7MqIcDgNZsQ6tHjCZXP
z/4VRA9SAkQ5yTIcSkb5IT/NxxkuiItHp1rwEnkfbxP2tymaUj5udVp5uQ6YT1/S
sQIDAQAB
-----END PUBLIC KEY-----
```

Ahora, Jose y yo nos pasamos nuestra clave pública: 

![image4](/assets/img/posts/gpg/gpg3.png)

### 3. Utilizando la clave pública cifra un fichero de texto y envíalo a tu compañero

Lo primero que haremos será generar un fichero de texto con el contenido que deseemos:
```bash
pavlo@debian:~()$ echo "Hoy pierde el Betis" > archivo.txt
```

Tras la extracción de la clave pública, podremos proceder a cifrar un archivo utilizando la clave pública del destinatario. Esto se logra mediante el uso de las opciones de `openssl`. Específicamente:

- La opción `-encrypt` indica que deseamos cifrar el archivo.
- La opción `-in <fichero>` especifica el archivo de entrada que se desea cifrar.
- La opción `-out <ficherosalida>` define el archivo de salida que contendrá los datos cifrados, con una extensión habitual como `.enc`.
- La opción `-inkey <clavepublica>` especifica la clave pública que se usará para el cifrado.
- La opción `-pubin` se utiliza para señalar que estamos trabajando con una clave pública.
- Finalmente, el comando `pkeyutl` se emplea para realizar operaciones de firma, verificación, cifrado o descifrado con RSA.

En este caso, el archivo de entrada será `archivo.txt`, el archivo de salida será `mensaje_encriptado.enc`, y la clave pública utilizada será la de Jose, contenida en `clave_publica.pem`.

```bash
pavlo@debian:~()$ openssl pkeyutl -encrypt -in archivo.txt -out mensaje_encriptado.enc -inkey clave_publica.pem -pubin
```

Como vemos, el mensaje encriptado utiliza carácteres no reconocidos:

```bash
pavlo@debian:~()$ cat mensaje_encriptado.enc 
��h�u*�3�ݔL��;"v��T������_f.VH4�C��y!
                                     �ei�0dKs   �����T������'>�����Dd�F��-

�^}�	
��t�p���j@ݓ�Dg�P�a3N�bE��I�Ҝ��U����cL�@�FKa�2e��z[?3�l���4
```

De nuevo, yo le paso mi mensaje cifrado para que lo averigüe y yo me descargo el suyo:

![image5](/assets/img/posts/gpg/gpg4.png)

### 4. Tu compañero te ha mandado un fichero cifrado, muestra el proceso para el descifrado

Para descifrar un archivo previamente cifrado, utilizamos la herramienta `openssl` con las siguientes opciones:

- La opción `-decrypt` indica que queremos realizar la operación de descifrado.
- La opción `-in <fichero>` especifica el archivo cifrado que deseamos descifrar.
- La opción `-out <ficherosalida>` define el archivo donde se guardará el contenido descifrado.
- La opción `-inkey <claveprivada>` señala la clave privada que se utilizará para descifrar el archivo.
- Al igual que en el cifrado, la opción `pkeyutl` se usa para realizar operaciones de firma, verificación, cifrado o descifrado con el algoritmo RSA.

En este caso, el archivo de entrada será `mensajenuevo_cifrado.enc`, el archivo de salida será `documento.txt`, y la clave privada utilizada será `clave.pem`, la cual generamos previamente.

```bash
pavlo@debian:~()$ sudo openssl pkeyutl -decrypt -in mensajenuevo_cifrado.enc -out documento.txt -inkey clave.pem
```

Y como vemos, podemos visualizar el contenido:

```bash
pavlo@debian:~()$ cat documento.txt 
ojala eliminen al betis
```