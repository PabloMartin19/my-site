---
title: "Systemd-Boot"
date: 2025-01-14 13:30:00 +0000
categories: [Sistemas, Systemd]
tags: [Systemd]
author: pablo
description: "...."
toc: true
comments: true
image:
  path: /assets/img/posts/systemd-boot/Debian-13-Trixie.png
---

Los desarrolladores de Debian han propuesto el uso de systemd-boot para instalaciones UEFI de Debian Trixie, que se lanzará en 2025. Opción disponible, de momento, en instalaciones debian 13 en modo experto. El objetivo es agregar soporte de arranque seguro firmado a Debian para intentar resolver el problema relacionado con UEFI y Secure Boot con sistemas Debian. Proponen utilizar un gestor de arranque llamado “systemd-boot” para mejorar el proceso de arranque de Debian en sistemas UEFI.

## 1. Instala en máquina virtual, debian 13 con systemd-boot, y familiarízate con este nuevo gestor de arranque.

En esta parte del artículo, aprenderemos a instalar Debian 13 (Trixie) con el gestor de arranque systemd-boot en un sistema UEFI.

Comenzamos descargando la ISO de Debian 13 Trixie desde la página oficial del [proyecto Debian](https://www.debian.org/devel/debian-installer/). En esta sección elegiremos la opción que más nos convenga, en mi caso la **netinst**.

En esta instalación utilizaremos **QEMU/KVM** como plataforma de virtualización para crear la máquina virtual. Es fundamental configurar correctamente UEFI antes de comenzar la instalación, ya que Debian 13 utiliza este modo de arranque junto con `systemd-boot`.

