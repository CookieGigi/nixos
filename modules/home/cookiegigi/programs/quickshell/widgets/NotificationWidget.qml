import QtQuick
import "../components"
import "../services"
import "../theme"

Percentage {
    property var screen: null
    icon: Notifications.quiet ? "\uf1f6" : "\uf0f3"
    value: !Notifications.available ? "!" : Notifications.active.length > 0 ? String(Notifications.active.length) : ""
    accentColor: Notifications.quiet ? Theme.peach : Theme.teal
    onClicked: PopupRegistry.toggle(screen, "notifications")
}
