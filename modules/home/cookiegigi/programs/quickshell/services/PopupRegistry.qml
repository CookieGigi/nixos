pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property var _registries: ({})

    function register(screen, id, popupInstance) {
        if (!_registries[screen]) {
            _registries[screen] = {};
        }
        _registries[screen][id] = popupInstance;
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
    }

    function closeAll(screen) {
        var reg = _registries[screen];
        if (reg) {
            for (var key in reg) {
                if (reg[key].isOpen)
                    reg[key].isOpen = false;
            }
        }
    }

    function getActivePopupTitle(screen) {
        var reg = _registries[screen];
        if (!reg)
            return "";
        for (var key in reg) {
            if (reg[key].isOpen && reg[key].title)
                return reg[key].title;
        }
        return "";
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
}
