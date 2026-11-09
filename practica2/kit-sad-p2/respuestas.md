# Respuestas · Práctica 2 · Bodegas Atlántico

> Rellena este fichero en tu ordenador. Va en la entrega (`./lab.sh entregar`) y en la defensa te pueden preguntar por él.

## Bloque A · Piensa como un atacante (nmap)

Desde la calle: `./lab.sh cliente` y dentro `nmap -Pn -p 22,80,443,5432,8080 198.51.100.254`. Pega la salida:

```text
PORT     STATE    SERVICE
22/tcp   filtered ssh
80/tcp   open     http
443/tcp  open     https
5432/tcp filtered postgresql
8080/tcp filtered http-proxy
MAC Address: C2:21:68:28:AB:14 (Unknown)

```

## Bloque A · El contador

Después de `./lab.sh comprobar`, mira `./lab.sh ver`. ¿Cuántos paquetes lleva el contador de A6? ¿Quién los ha mandado?

> 17 paquetes, lo ha enviado la tienda online

## Bloque B · La prueba del cifrado

En el firewall (`./lab.sh fw`): `tcpdump -ni wan host 198.51.100.62 -c 6`. Mientras, en otra terminal, el comercial
(`./lab.sh comercial`) hace `curl http://172.16.10.20:8080`. Pega lo que sale en el firewall:

```text
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on wan, link-type EN10MB (Ethernet), snapshot length 262144 bytes
19:42:06.811859 IP 198.51.100.62.51282 > 198.51.100.254.51820: UDP, length 96
19:42:06.811999 IP 198.51.100.254.51820 > 198.51.100.62.51282: UDP, length 96
19:42:06.812075 IP 198.51.100.62.51282 > 198.51.100.254.51820: UDP, length 96
19:42:06.812128 IP 198.51.100.62.51282 > 198.51.100.254.51820: UDP, length 176
19:42:06.812177 IP 198.51.100.254.51820 > 198.51.100.62.51282: UDP, length 96
19:42:06.812273 IP 198.51.100.254.51820 > 198.51.100.62.51282: UDP, length 304
6 packets captured
10 packets received by filter
0 packets dropped by kernel
```

En dos líneas: ¿qué se ve por la calle y qué NO se ve?

>Se ve al comercial pidiendo la intranet

## Bloque C · Para la defensa (C4)

Del **mismo ataque** (la inyección a la web): ¿qué ve el vigilante de la red (el IDS) y qué ve el portero de la web? ¿Por
qué hacen falta los dos?

>

## Bloque D · La nota del servidor (D0 y D4)

Nota del análisis **antes** de bastionar (D0):

>

Nota **después** (D4). ¿Por qué no llega a 100? ¿Significa que el servidor sigue inseguro? Comenta un aviso que siga saliendo.

>
