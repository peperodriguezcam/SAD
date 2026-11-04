# Laboratorio SAD · UD3 (cortafuegos) y UD4 (VPN)

Cinco máquinas en Docker que se manejan con `./lab.sh`. No hace falta saber Docker.

```text
  «Internet» 203.0.113.0/24     DMZ 10.10.20.0/24     LAN 10.10.10.0/24
  internet .50 · remoto .60      web .10               pc .5
              \__________ firewall .254 (wan · dmz · lan) + VPN wg0 10.200.200.1 __________/
```

1. `./lab.sh arrancar` (la primera vez tarda unos minutos).
2. `./lab.sh ayuda` para ver todas las órdenes.
3. Lo que editas está en esta carpeta: `firewall/nftables.conf`, `firewall/wireguard/` y `remoto/wireguard/`.
4. `./lab.sh comprobar ud3` y `./lab.sh comprobar ud4` te dicen qué está bien y qué falta.

Las explicaciones completas están en la web de la asignatura (UD3 y UD4).

Necesitas Docker con el plugin `docker compose` y un Linux con WireGuard en el kernel (cualquier Ubuntu o Debian actual).
