# Location Quick Toggle

Una extensión para GNOME Shell que añade un interruptor **Ubicación** al panel de
**Ajustes rápidos**. El interruptor controla la opción global de GNOME
`org.gnome.system.location enabled`, la misma preferencia que habilita o
deshabilita los servicios de ubicación del sistema.

## Compatibilidad

El código utiliza las APIs de extensiones basadas en ES Modules y Quick
Settings, disponibles desde GNOME Shell 45. Los metadatos incluyen las
versiones 45 a 49. No se usan APIs privadas ni específicas de una versión dentro de este rango.

## Instalación

1. Copie la carpeta `location-quick-toggle@mguel-cr` a:

   ```text
   ~/.local/share/gnome-shell/extensions/
   ```

2. Active la extensión:

   ```bash
   gnome-extensions enable location-quick-toggle@mguel-cr
   ```

3. Abra el menú superior derecho (Quick Settings). El nuevo toggle **Ubicación** aparecerá en "Ajustes rápidos".

> **Nota:** En una sesión X11, reinicie GNOME Shell con `Alt+F2`, escriba `r` y pulse
> Enter. En Wayland cierre e inicie sesión, o active la extensión desde la
> aplicación _Extensiones_.

## Comportamiento y límites

- Muestra el estado activado o desactivado y un icono distinto para cada
  estado.
- Al cambiar el estado desde el toggle, muestra un OSD con el mensaje y el
  icono de ubicación correspondientes. Los cambios externos no generan OSD.
- Se actualiza al cambiar la preferencia desde Configuración de GNOME u otra
  aplicación.
- No solicita la ubicación ni modifica permisos de aplicaciones. Solo cambia
  el interruptor maestro de los servicios de ubicación.
- La ubicación efectiva también requiere que los componentes del sistema,
  como GeoClue, estén disponibles y que las aplicaciones tengan permiso para
  usarla.

## Traducciones

Las cadenas de la interfaz usan gettext con el dominio
`location-quick-toggle`. La plantilla para traductores está en
`po/location-quick-toggle.pot`; use ese archivo para crear un nuevo catálogo
`po/<idioma>.po`.

La traducción inicial al español se encuentra en `po/es.po` y su catálogo
compilado se instala en `locale/es/LC_MESSAGES/location-quick-toggle.mo`.
Por ejemplo, para iniciar una traducción al **francés**:

```bash
msginit --input=po/location-quick-toggle.pot --locale=fr --output-file=po/fr.po
```

Después de editar un archivo PO, compile su catálogo:

```bash
mkdir -p locale/fr/LC_MESSAGES
msgfmt --check --output-file locale/fr/LC_MESSAGES/location-quick-toggle.mo po/fr.po
```

Cuando se añadan cadenas a `extension.js`, regenere la plantilla antes de
actualizar los archivos PO:

```bash
xgettext --language=JavaScript --from-code=UTF-8 --keyword=_ \
  --output=po/location-quick-toggle.pot extension.js
```
