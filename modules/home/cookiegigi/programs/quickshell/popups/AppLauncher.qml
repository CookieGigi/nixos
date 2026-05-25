import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"
import "../theme"

// App launcher popup with search and keyboard navigation.
// Uses PanelWindow with Overlay layer so it works on compositors
// (e.g. niri) where xdg_popup cannot attach to a layer-shell parent.
PanelWindow {
    id: root

    property var visibilities: null

    property string filterText: visibilities ? visibilities.launcherFilter : ""
    onFilterTextChanged: applyFilter()

    property var allApps: []
    property var filteredApps: []
    property var listItems: []

    // Denylist: hide these apps.
    property var denylist: ["kvantum", "gvim"]

    visible: visibilities ? visibilities.launcher : false

    // Overlay layer-shell surface: floats above everything, grabs keyboard.
    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0

    implicitWidth: 500
    implicitHeight: Math.min(400, selectionList.count * 36 + 48)
    color: "transparent"

    onVisibleChanged: {
        if (visible) {
            refreshApps();
            if (visibilities) visibilities.launcherFilter = "";
            focusTimer.start();
        } else {
            closeLauncher();
        }
    }

    function refreshApps() {
        const raw = DesktopEntries.applications.values;
        const denied = denylist.map(s => s.toLowerCase());
        const filtered = raw.filter(entry => {
            const name = (entry.name || "").toLowerCase();
            const exec = (entry.exec || "").toLowerCase();
            return !denied.some(d => name.includes(d) || exec.includes(d));
        });
        filtered.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        allApps = filtered;
        applyFilter();
    }

    function applyFilter() {
        const q = filterText.toLowerCase();
        filteredApps = allApps.filter(entry => {
            const name = (entry.name || "").toLowerCase();
            return name.includes(q);
        });
        // Normalize items for SelectionList
        listItems = filteredApps.map(entry => ({ label: entry.name || "" }));
    }

    function closeLauncher() {
        if (visibilities) {
            visibilities.launcher = false;
            visibilities.launcherFilter = "";
        }
    }

    PopupShell {
        anchors.fill: parent

        onCloseRequested: root.closeLauncher()

        ColumnLayout {
            id: popupContent
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 8

            // App list
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                SelectionList {
                    id: selectionList
                    anchors.fill: parent
                    anchors.margins: 10
                    items: root.listItems

                    onEscapePressed: root.closeLauncher()

                    onItemActivated: (index) => {
                        if (index >= 0 && index < root.filteredApps.length) {
                            root.filteredApps[index].execute();
                            root.closeLauncher();
                        }
                    }
                }
            }

            // No results message
            Text {
                visible: root.filteredApps.length === 0 && root.filterText.length > 0
                Layout.alignment: Qt.AlignHCenter
                text: "No apps found"
                color: Theme.overlay0
                font {
                    family: Theme.fontFamily
                    pixelSize: 13
                }
            }
        }
    }

    // Connect to shared navigation signals from the bar's search input.
    Connections {
        target: root.visibilities || null
        enabled: root.visibilities !== null

        function onLauncherActivate() {
            selectionList.activateCurrent();
        }
        function onLauncherIncrement() {
            selectionList.incrementCurrent();
        }
        function onLauncherDecrement() {
            selectionList.decrementCurrent();
        }
    }

    // Delay focus request slightly so the window is fully shown first
    Timer {
        id: focusTimer
        interval: 100
        repeat: false
        onTriggered: selectionList.forceActiveFocus()
    }
}
