import Gio from "gi://Gio";
import GObject from "gi://GObject";

import * as Main from "resource:///org/gnome/shell/ui/main.js";
import * as QuickSettings from "resource:///org/gnome/shell/ui/quickSettings.js";
import { Extension, gettext as _ } from "resource:///org/gnome/shell/extensions/extension.js";

const LOCATION_SCHEMA = "org.gnome.system.location";
const LOCATION_ENABLED_KEY = "enabled";

const LocationToggle = GObject.registerClass(
  class LocationToggle extends QuickSettings.QuickToggle {
    constructor() {
      super({
        title: _("Location"),
        iconName: "location-services-disabled-symbolic",
        toggleMode: true,
      });

      this._settings = null;
      this._settingsChangedId = 0;
      this._clickedId = 0;
      this._updatingFromSettings = false;
      this._valSchema = null;

      this._getValueSchema();

      if (!this._valSchema) {
        console.error(_("Location Quick Toggle: the location settings schema is unavailable"));
        this.subtitle = _("Unavailable");
        this.reactive = false;
        return;
      }

      this._setConnections();
      this._syncFromSettings();
    }

    _getValueSchema() {
      const schemaSource = Gio.SettingsSchemaSource.get_default();
      this._valSchema = schemaSource?.lookup(LOCATION_SCHEMA, true);
    }

    _setConnections() {
      this._settings = new Gio.Settings({ settings_schema: this._valSchema });
      this._settingsChangedId = this._settings.connectObject(
        `changed::${LOCATION_ENABLED_KEY}`,
        () => this._syncFromSettings(),
        this,
      );
      this._clickedId = this.connectObject("clicked", () => this._writeSetting(), this);
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

        if (!wasWritten) throw new Error(_("The location setting could not be written"));

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
      const label = isEnabled ? _("Location enabled") : _("Location disabled");
      const index = Main.layoutManager.primaryIndex;

      if (Main.osdWindowManager.showOne) {
        Main.osdWindowManager.showOne(index, icon, label);
      } else {
        Main.osdWindowManager.show(index, icon, label);
      }
    }

    destroy() {
      if (this._settings && this._settingsChangedId) this._settings.disconnectObject(this._settingsChangedId);

      if (this._clickedId) this.disconnectObject(this._clickedId);

      this._valSchema = null;
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
