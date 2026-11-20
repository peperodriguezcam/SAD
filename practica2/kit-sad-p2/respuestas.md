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

>El IDS Analiza el tráfico de red en crudo (paquetes TCP/IP) buscando patrones de texto o firmas conocidas (como `UNION SELECT`). No comprende la lógica de la aplicación web y puede ser evadido si el atacante ofusca o codifica la carga útil (por ejemplo, con doble codificación URL o fragmentación de paquetes).
>El WAF Inspecciona la petición HTTP completa en la capa de aplicación (Capa 7). Decodifica y normaliza los datos exactamente igual que el servidor web antes de analizarlos, identificando qué parámetro concreto lleva la inyección y bloqueándola antes de que llegue al backend o a la base de datos.
>Porque cubren perímetros distintos (defensa en profundidad): el **WAF** entiende y frena ataques web complejos, pero es ciego ante todo lo que no sea tráfico HTTP/HTTPS; **Suricata** protege toda la infraestructura de red detectando escaneos de puertos, intentos de intrusión por SSH, anomalías DNS o movimientos laterales internos.

## Bloque D · La nota del servidor (D0 y D4)

Nota del análisis **antes** de bastionar (D0):

>

Nota **después** (D4). ¿Por qué no llega a 100? ¿Significa que el servidor sigue inseguro? Comenta un aviso que siga saliendo.

>Porque la herramienta revisa el servidor entero y todavía quedan sugerencias pendientes por tocar (tanto de este bloque como del resto del sistema: kernel, permisos, otros servicios...). Además, llegar al 100 en Lynis es casi imposible sin romper cosas en producción.
>No. Tener un 63/100 solo indica que aún hay margen de mejora, pero el servidor ya tiene medidas aplicadas y la seguridad real depende del contexto, no de sacar un 100 teórico.
>El `HTTP-6710` (*Add HTTPS to nginx virtual hosts...*), que avisa de que los *virtual hosts* de Nginx siguen yendo por HTTP sin cifrar en lugar de usar HTTPS
