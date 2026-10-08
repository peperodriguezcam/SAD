# Práctica 1 de SAD · SecureCorp — Respuestas

**Nombre y apellidos:** Pepe Rodríguez
**Usuario:** peperodriguezcam

Responde con tus palabras, en 1-3 líneas. En la defensa te preguntaré lo mismo en voz alta.

**Contraseñas que has usado** (solo porque es un laboratorio; en una empresa, jamás en un fichero):

- Tu usuario: Pepe2026
- mtorres: Marta2026

---

**1. (A1)** ¿Quién es el `issuer` de tu `ca.crt`? ¿Hasta qué fecha es válido? ¿Por qué el `subject`
y el `issuer` de la CA son iguales y los de `ldap.crt` no?
- El issuer es `CN = SecureCorp Root CA, O = SecureCorp, DC = securecorp, DC = local` y es 
  válido según la fecha fijada al generarlo (habitualmente 1 o 10 años).

-En la CA son iguales porque es un certificado autofirmado (se valida a sí misma). En `ldap.crt` son distintos porque el `subject` es el servidor LDAP y el `issuer` es la CA que
 lo ha firmado.

**2. (A3)** Pega el comando y el resultado de tus dos búsquedas:

```
a) miembros de rrhh:
  ldapsearch -x -H ldaps://ldap.securecorp.local -b "ou=groups,dc=securecorp,dc=local"
  "(cn=rrhh)" member

	Resultado: dn: cn=rrhh,ou=groups,dc=securecorp,dc=local -> 
		   member: uid=mtorres,ou=people,dc=securecorp,dc=local

b) cn y mail de todas las personas:
  ldapsearch -x -H ldaps://ldap.securecorp.local -b "ou=people,dc=securecorp,dc=local"
  "(objectClass=inetOrgPerson)" cn mail

	Resultado: Me ha devuelto los campos cn y los mail de mi usuario, mtorres y lromero

```

**3. (A4)** ¿Por qué la clave `ldap.key` tiene que ser de `openldap` y tener permisos 600?
	Porque contiene la clave privada del servidor TLS. El usuario `openldap` necesita
	leerla para iniciar el servicio, y los permisos 600 impiden que otros usuarios del
	sistema puedan leerla o comprometer la seguridad.

**4. (A4)** ¿Qué valor has puesto en `SLAPD_SERVICES` y por qué?
	`SLAPD_SERVICES="ldap:/// ldaps:///"` -> Se pone para que el demonio slapd acepte 
	conexiones inseguras y cifrads.

**5. (A4)** Antes de añadir `TLS_CACERT` en el cliente, `ldaps://` no funcionaba. ¿Por qué?
	Porque no confiaba en la CA que firmó el certificado del LDAP.

**6. (B3)** Pega la salida de `klist` con tus dos tickets. ¿Para qué sirve cada uno? ¿Ha 
	viajado tu contraseña por la red?

```
**TGT (`krbtgt/SECURECORP.LOCAL`):** Para demostrar que me he autenticao ante el KDC.

**Service Ticket (`host/web.securecorp.local`):**Nos permite acceder al servicio web sin 
  pedir de nuevo la contraseña

**Contraseña en red:**La contraseña no viaja por la red porque se usa localmente
```

**7. (C)** En el `docker-compose.yml`, ¿qué diferencia hay entre `build:` e `image:`? ¿Qué
significa la línea `- "8081:80"` del servicio `phpldapadmin`?
Que el build construye la imagen desde el Dockerfile local y el image descarga una imagen
que ya existe.

El "- 8081:80" redirige el puerto 8081 de la maquina al 80 del contenedor.

**8. (C)** ¿Por qué en la máquina `web` no has tenido que escribir a mano `TLS_CACERT`, y en el
cliente sí? ¿Qué pasaría con esa línea del cliente si hicieras `./lab.sh reset`?
Porque en web se hizo automaticamente cuando yo edité el Dockerfile y puse el RUN 
y en el cliente lo hice manualmente

Si ejecuto `./lab.sh reset`, el cliente se borra y se perderia `/etc/ldap/ldap.conf`
