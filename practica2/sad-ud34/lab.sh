#!/usr/bin/env bash
#
# lab.sh — Mando a distancia del laboratorio de SAD · UD3 (cortafuegos) y UD4 (VPN).
#
# No necesitas saber Docker: todo lo que hace falta está aquí.
#   ./lab.sh ayuda        -> lista de órdenes
#
set -uo pipefail
cd "$(dirname "$0")"

MAQUINAS="firewall pc web internet remoto"
c() { echo "sad-ud34-$1"; }

# ---------- colores ----------
if [ -t 1 ]; then
    R=$'\e[1;31m'; V=$'\e[1;32m'; A=$'\e[1;33m'; Z=$'\e[1;34m'; N=$'\e[1m'; X=$'\e[0m'
else
    R=""; V=""; A=""; Z=""; N=""; X=""
fi
info()  { echo "${Z}▶${X} $*"; }
bien()  { echo "${V}✔${X} $*"; }
aviso() { echo "${A}!${X} $*"; }
error() { echo "${R}✘ $*${X}" >&2; }

necesita_docker() {
    if ! command -v docker >/dev/null 2>&1; then error "Docker no está instalado en este equipo."; exit 1; fi
    if ! docker info >/dev/null 2>&1; then
        error "Docker está instalado pero no puedo usarlo."
        echo "  - ¿Está arrancado?           sudo systemctl start docker"
        echo "  - ¿Tu usuario está en el grupo docker?  sudo usermod -aG docker \$USER  (y cierra sesión)"
        exit 1
    fi
}
corriendo() { [ "$(docker inspect -f '{{.State.Running}}' "$(c "$1")" 2>/dev/null)" = "true" ]; }
necesita_lab() {
    necesita_docker
    for m in $MAQUINAS; do
        corriendo "$m" || { error "El laboratorio no está arrancado (falta «$m»)."; echo "  Arráncalo con:  ./lab.sh arrancar"; exit 1; }
    done
}
en() { local m=$1; shift; docker exec "$(c "$m")" "$@"; }

# Una prueba: descripción, máquina y orden. Si la orden sale bien, ✔; si no, ✘ y la pista.
OK=0; MAL=0
prueba() {
    local desc=$1 maq=$2 orden=$3 pista=${4:-}
    if en "$maq" bash -c "$orden" >/dev/null 2>&1; then bien "$desc"; OK=$((OK + 1))
    else echo "${R}✘${X} $desc"; [ -n "$pista" ] && echo "    ${A}pista:${X} $pista"; MAL=$((MAL + 1)); fi
}
# curl que espera poco: exit 0 = llega · 7 = rechazado (pasa el cortafuegos, pero no hay servicio) · 28 = no contesta (drop)
CURL="curl -s -o /dev/null --max-time 3"

ayuda() {
    cat <<EOF
${N}Laboratorio SAD · UD3 (cortafuegos nftables) y UD4 (VPN WireGuard)${X}

  «Internet» 203.0.113.0/24     DMZ 10.10.20.0/24     LAN 10.10.10.0/24
  internet .50 · remoto .60      web .10               pc .5
              \\__________ firewall .254 (wan · dmz · lan) + VPN wg0 10.200.200.1 __________/

${N}Arrancar y parar${X}
  ./lab.sh arrancar        crea y arranca las 5 máquinas (la primera vez tarda un par de minutos)
  ./lab.sh parar           las apaga (tus ficheros se quedan en esta carpeta)
  ./lab.sh reiniciar       las apaga y las vuelve a arrancar desde cero (si algo se ha liado)
  ./lab.sh estado          qué máquinas están en marcha

${N}Entrar en una máquina${X} (sales con exit)
  ./lab.sh firewall · pc · web · internet · remoto

${N}Cortafuegos (UD3)${X}
  Edita ${N}firewall/nftables.conf${X} en tu ordenador (o dentro del firewall: nano /etc/nftables.conf)
  ./lab.sh aplicar         comprueba la sintaxis y carga el cortafuegos
  ./lab.sh ver             enseña las reglas cargadas, con sus contadores
  ./lab.sh vaciar          quita todas las reglas (vuelve a dejar pasar todo)

${N}VPN (UD4)${X}
  Configuración en ${N}firewall/wireguard/wg0.conf${X} y ${N}remoto/wireguard/wg0.conf${X}
  ./lab.sh vpn             (re)levanta el túnel en los dos extremos y enseña «wg show»

${N}Comprobar${X}
  ./lab.sh comprobar ud3   pruebas automáticas del cortafuegos
  ./lab.sh comprobar ud4   pruebas automáticas de la VPN
EOF
    [ -d solucion ] && echo -e "\n${N}Profesor${X}\n  ./lab.sh solucion ud3|ud4   carga la solución (guarda antes una copia de lo que hubiera)"
}

arrancar() {
    necesita_docker
    info "Arrancando el laboratorio…"
    docker compose up -d --build >/dev/null 2>&1 || { error "No se pudo arrancar. Prueba:  docker compose up --build  (y mira el error)"; exit 1; }
    sleep 2
    for m in $MAQUINAS; do corriendo "$m" && bien "$m en marcha" || error "$m no arrancó: docker logs $(c "$m")"; done
    echo; echo "Ahora: ${N}./lab.sh ayuda${X} para ver qué hacer."
}

aplicar() {
    necesita_lab
    info "Comprobando la sintaxis de firewall/nftables.conf…"
    if ! en firewall nft -c -f /etc/nftables.conf; then
        error "Hay un error en nftables.conf (arriba te dice la línea). No he cargado nada: sigue el cortafuegos de antes."
        exit 1
    fi
    en firewall nft -f /etc/nftables.conf && bien "Cortafuegos cargado. Míralo con ./lab.sh ver"
}

vpn() {
    necesita_lab
    for m in firewall remoto; do
        if ! en "$m" test -s /etc/wireguard/wg0.conf; then error "Falta $m/wireguard/wg0.conf"; exit 1; fi
        en "$m" bash -c 'wg-quick down wg0 >/dev/null 2>&1; wg-quick up wg0' >/dev/null 2>&1 \
            && bien "túnel levantado en $m" || { error "wg-quick no pudo levantar wg0 en $m:"; en "$m" wg-quick up wg0; }
    done
    en remoto ping -c 1 -W 2 10.200.200.1 >/dev/null 2>&1   # provoca el primer saludo
    echo; info "wg show en el firewall:"; en firewall wg show
}

comprobar_ud3() {
    echo "${N}Cortafuegos (UD3)${X}"
    prueba "Hay un cortafuegos cargado con política drop en input y forward" firewall \
        "nft list ruleset | grep -q 'hook input.*policy drop' && nft list ruleset | grep -q 'hook forward.*policy drop'" \
        "las cadenas input y forward necesitan  policy drop;"
    prueba "La LAN sale a Internet" pc "$CURL http://203.0.113.50" \
        "falta permitir lan -> wan en forward, o el masquerade en postrouting"
    prueba "…y sale con la IP del firewall (masquerade)" pc "curl -s --max-time 3 http://203.0.113.50 | grep -q 203.0.113.254" \
        "en la tabla nat, postrouting:  oifname \"wan\" masquerade"
    prueba "Desde Internet se ve la web de la DMZ en la IP pública del firewall (DNAT)" internet \
        "curl -s --max-time 3 http://203.0.113.254 | grep -q DMZ" \
        "en nat/prerouting:  iifname \"wan\" tcp dport { 80, 443 } dnat to 10.10.20.10  y permitirlo en forward"
    prueba "La DMZ NO llega a la LAN (aislamiento)" web "! $CURL http://10.10.10.5" \
        "en forward:  iifname \"dmz\" oifname \"lan\" drop"
    prueba "La DMZ NO entra al firewall por SSH" web "$CURL telnet://10.10.20.254:22; [ \$? -eq 28 ]" \
        "en input, el SSH solo desde la lan (y la política drop hace el resto)"
    prueba "Un puerto no publicado no contesta desde Internet (drop, no reject)" internet "$CURL http://203.0.113.254:8080; [ \$? -eq 28 ]" \
        "con drop el paquete desaparece (timeout); con reject contestaría «rechazado»"
    prueba "El PC hace ping al firewall" pc "ping -c 1 -W 2 10.10.10.254" "permite icmp echo-request en input"
}

comprobar_ud4() {
    echo "${N}VPN (UD4)${X}"
    prueba "El firewall tiene la interfaz wg0 (10.200.200.1)" firewall "ip -4 addr show wg0 | grep -q 10.200.200.1" \
        "falta firewall/wireguard/wg0.conf o levantarlo: ./lab.sh vpn"
    prueba "El portátil remoto tiene wg0 (10.200.200.2)" remoto "ip -4 addr show wg0 | grep -q 10.200.200.2" \
        "falta remoto/wireguard/wg0.conf o levantarlo: ./lab.sh vpn"
    en remoto ping -c 1 -W 2 10.200.200.1 >/dev/null 2>&1
    prueba "Ha habido saludo (handshake) entre los dos extremos" firewall \
        "[ \$(wg show wg0 latest-handshakes | awk '{print \$2}' | sort -n | tail -1) -gt 0 ]" \
        "¿las claves públicas están cruzadas? ¿el Endpoint es 203.0.113.254:51820? ¿abriste udp 51820 en input?"
    prueba "Desde el portátil remoto se llega a la intranet de la LAN por el túnel" remoto \
        "curl -s --max-time 3 http://10.10.10.5 | grep -q LAN" \
        "AllowedIPs del remoto debe incluir 10.10.10.0/24, y en forward:  iifname \"wg0\" oifname \"lan\" accept"
    prueba "Sin túnel, Internet NO llega a la LAN" internet "! $CURL http://10.10.10.5" ""
    # Cifrado: mientras el remoto pide la intranet, por la wan solo debe verse UDP 51820, nunca HTTP en claro
    en firewall bash -c 'rm -f /tmp/c.pcap; timeout 6 tcpdump -ni wan -w /tmp/c.pcap host 203.0.113.60 >/dev/null 2>&1 &' 
    sleep 1; en remoto curl -s --max-time 3 http://10.10.10.5 >/dev/null 2>&1; sleep 5
    prueba "Por Internet solo viaja UDP 51820 cifrado (ni rastro de la petición HTTP)" firewall \
        "n=\$(tcpdump -nr /tmp/c.pcap 2>/dev/null | wc -l); u=\$(tcpdump -nr /tmp/c.pcap 'udp port 51820' 2>/dev/null | wc -l); [ \$n -gt 0 ] && [ \$n -eq \$u ]" \
        "si ves tráfico TCP 80 hacia la LAN por la wan, esa petición no ha ido por el túnel"
}

comprobar() {
    necesita_lab
    OK=0; MAL=0
    case "${1:-todo}" in
        ud3) comprobar_ud3 ;;
        ud4) comprobar_ud4 ;;
        *) comprobar_ud3; echo; comprobar_ud4 ;;
    esac
    echo; [ "$MAL" -eq 0 ] && bien "${N}$OK de $OK. ¡Todo bien!${X}" || echo "${A}$OK bien · $MAL por arreglar${X}"
}

solucion() {
    local ud=${1:-}
    [ -d "solucion/$ud" ] || { error "Uso: ./lab.sh solucion ud3|ud4"; exit 1; }
    necesita_lab
    mkdir -p copias; local f="copias/$(date +%H%M%S)"
    mkdir -p "$f"; cp -r firewall remoto "$f"/ 2>/dev/null; aviso "Copia de lo que había en $f/"
    cp "solucion/$ud/nftables.conf" firewall/nftables.conf
    if [ "$ud" = ud4 ]; then
        info "Generando claves de WireGuard para el firewall y el portátil…"
        local fpriv fpub rpriv rpub
        fpriv=$(en firewall wg genkey); fpub=$(echo "$fpriv" | docker exec -i "$(c firewall)" wg pubkey)
        rpriv=$(en remoto wg genkey);   rpub=$(echo "$rpriv" | docker exec -i "$(c remoto)" wg pubkey)
        sed -e "s|@FW_PRIV@|$fpriv|" -e "s|@REMOTO_PUB@|$rpub|" solucion/ud4/wg0-firewall.conf > firewall/wireguard/wg0.conf
        sed -e "s|@REMOTO_PRIV@|$rpriv|" -e "s|@FW_PUB@|$fpub|" solucion/ud4/wg0-remoto.conf > remoto/wireguard/wg0.conf
        chmod 600 firewall/wireguard/wg0.conf remoto/wireguard/wg0.conf
    fi
    aplicar
    [ "$ud" = ud4 ] && vpn
}

case "${1:-ayuda}" in
    arrancar) arrancar ;;
    parar) necesita_docker; docker compose stop >/dev/null 2>&1 && bien "Laboratorio parado" ;;
    reiniciar) necesita_docker; docker compose down >/dev/null 2>&1; arrancar ;;
    estado) necesita_docker; for m in $MAQUINAS; do corriendo "$m" && bien "$m" || aviso "$m parada"; done ;;
    firewall|pc|web|internet|remoto) necesita_lab; docker exec -it "$(c "$1")" bash ;;
    aplicar) aplicar ;;
    ver) necesita_lab; en firewall nft -a list ruleset ;;
    vaciar) necesita_lab; en firewall nft flush ruleset && aviso "Cortafuegos vacío: ahora pasa todo" ;;
    vpn) vpn ;;
    comprobar) comprobar "${2:-todo}" ;;
    solucion) solucion "${2:-}" ;;
    ayuda|-h|--help) ayuda ;;
    *) error "No conozco la orden «$1»."; ayuda; exit 1 ;;
esac
