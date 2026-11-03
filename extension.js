/**
 * Location Quick Toggle
 *
 * This extension controls GNOME's global location-services setting:
 * org.gnome.system.location enabled
 */

import Gio from "gi://Gio";
import GObject from "gi://GObject";

import * as Main from "resource:///org/gnome/shell/ui/main.js";
import * as QuickSettings from "resource:///org/gnome/shell/ui/quickSettings.js";
import { Extension, gettext as _ } from "resource:///org/gnome/shell/extensions/extension.js";

const LOCATION_SCHEMA = "org.gnome.system.location";
const LOCATION_ENABLED_KEY = "enabled";

const LocationToggle = GObject.registerClass(
  class LocationToggle extends QuickSettings.QuickToggle {
    _init() {
      super._init({
        title: _("Location"),
        iconName: "location-services-disabled-symbolic",
        toggleMode: true,
      });

      this._settings = null;
      this._settingsChangedId = 0;
      this._clickedId = 0;
      this._updatingFromSettings = false;

      const schemaSource = Gio.SettingsSchemaSource.get_default();
      const schema = schemaSource?.lookup(LOCATION_SCHEMA, true);

      if (!schema) {
        console.error(_("Location Quick Toggle: the location settings schema is unavailable"));
        this.subtitle = _("Unavailable");
        this.reactive = false;
        return;
      }

      this._settings = new Gio.Settings({ settings_schema: schema });
      this._settingsChangedId = this._settings.connect(`changed::${LOCATION_ENABLED_KEY}`, () =>
        this._syncFromSettings(),
      );
      this._clickedId = this.connect("clicked", () => this._writeSetting());

      this._syncFromSettings();
    }

    _syncFromSettings() {
      if (!this._settings) return;

      this._updatingFromSettings = true;

      const valEnabled = this._settings.get_boolean(LOCATION_ENABLED_KEY);
      this.checked = valEnabled;
      this.iconName = this._getIconName(valEnabled);
      this.subtitle = valEnabled ? _("Enabled") : _("Disabled");

      this._updatingFromSettings = false;
    }

    _writeSetting() {
      if (!this._settings || this._updatingFromSettings) return;

      try {
        const wasWritten = this._settings.set_boolean(LOCATION_ENABLED_KEY, this.checked);

        if (!wasWritten) throw new Error("The location setting could not be written");

        this._showStateOsd(this.checked);
      } catch (error) {
        logError(error, _("Location Quick Toggle: unable to update location services"));
        this._syncFromSettings();
      }
    }

    _getIconName(isEnabled) {
      return isEnabled ? "location-services-active-symbolic" : "location-services-disabled-symbolic";
    }

    _showStateOsd(isEnabled) {
      const icon = new Gio.ThemedIcon({ name: this._getIconName(isEnabled) });
      const message = isEnabled ? _("Location enabled") : _("Location disabled");

      Main.osdWindowManager.show(-1, icon, message, null);
    }

    destroy() {
      if (this._settings && this._settingsChangedId) this._settings.disconnect(this._settingsChangedId);

      if (this._clickedId) this.disconnect(this._clickedId);

      this._settings = null;
      super.destroy();
    }
  },
);

const LocationIndicator = GObject.registerClass(
  class LocationIndicator extends QuickSettings.SystemIndicator {
    _init() {
      super._init();
      this.quickSettingsItems.push(new LocationToggle());
    }
  },
);

export default class LocationQuickToggleExtension extends Extension {
  enable() {
    this._indicator = new LocationIndicator();
    Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);
  }

  disable() {
    this._indicator?.quickSettingsItems.forEach((item) => item.destroy());
    this._indicator?.destroy();
    this._indicator = null;
  }
}
