pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property var _registries: ({})
    property string _activePopupId: ""

    function _refreshActivePopupId(screen) {
        var reg = _registries[screen];
        if (reg) {
            for (var key in reg) {
                if (reg[key].isOpen) {
                    root._activePopupId = key;
                    return;
                }
            }
        }
        root._activePopupId = "";
    }

    function register(screen, id, popupInstance) {
        if (!_registries[screen]) {
            _registries[screen] = {};
        }
        _registries[screen][id] = popupInstance;
        popupInstance.isOpenChanged.connect(function () {
            _refreshActivePopupId(screen);
        });
    }

    function _getPopup(screen, id) {
        var reg = _registries[screen];
        return reg ? reg[id] : null;
    }

    function toggle(screen, id) {
        var popup = _getPopup(screen, id);
        if (!popup)
            return;
        var wasOpen = popup.isOpen;
        var reg = _registries[screen];
        if (reg) {
            for (var key in reg) {
                if (key !== id && reg[key].isOpen) {
                    reg[key].isOpen = false;
                }
            }
        }
        popup.isOpen = !wasOpen;
        _refreshActivePopupId(screen);
    }

    function closeAll(screen) {
        var reg = _registries[screen];
        if (reg) {
            for (var key in reg) {
                if (reg[key].isOpen)
                    reg[key].isOpen = false;
            }
        }
        _refreshActivePopupId(screen);
    }

    function getActivePopup(screen) {
        var reg = _registries[screen];
        if (!reg)
            return null;
        for (var key in reg) {
            if (reg[key].isOpen)
                return reg[key];
        }
        return null;
    }

    function getActivePopupTitle(screen) {
        var popup = getActivePopup(screen);
        return popup ? popup.title : "";
    }

    function isLauncherOpen(screen) {
        var popup = _getPopup(screen, "launcher");
        return popup ? popup.isOpen : false;
    }

    function toggleLauncher(screen) {
        toggle(screen, "launcher");
    }
    function togglePower(screen) {
        toggle(screen, "power");
    }
    function toggleNetwork(screen) {
        toggle(screen, "network");
    }
    function toggleCalendar(screen) {
        toggle(screen, "calendar");
    }
    function toggleMedia(screen) {
        toggle(screen, "media");
    }
    function toggleVolume(screen) {
        toggle(screen, "volume");
    }
    function toggleBattery(screen) {
        toggle(screen, "battery");
    }
    function togglePrayer(screen) {
        toggle(screen, "prayer");
    }
    function toggleBluetooth(screen) {
        toggle(screen, "bluetooth");
    }
}
