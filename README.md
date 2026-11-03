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

- Muestra “Activada” o “Desactivada” y un icono distinto para cada estado.
- Se actualiza al cambiar la preferencia desde Configuración de GNOME u otra
  aplicación.
- No solicita la ubicación ni modifica permisos de aplicaciones. Solo cambia
  el interruptor maestro de los servicios de ubicación.
- La ubicación efectiva también requiere que los componentes del sistema,
  como GeoClue, estén disponibles y que las aplicaciones tengan permiso para
  usarla.
