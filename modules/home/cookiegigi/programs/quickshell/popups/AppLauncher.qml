import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../theme"

// App launcher popup with search and keyboard navigation.
PopupBase {
    id: root

    visibilityProperty: "launcher"
    popupWidth: 500

    property string filterText: visibilities ? visibilities.launcherFilter : ""
    onFilterTextChanged: applyFilter()

    property var allApps: []
    property var filteredApps: []
    property var listItems: []

    // Denylist: hide these apps.
    property var denylist: ["kvantum", "gvim", "nvidia"]

    implicitHeight: Math.min(400, selectionList.count * 36 + 48)

    onOpened: {
        refreshApps();
        if (visibilities)
            visibilities.launcherFilter = "";
        focusTimer.start();
    }

    onClosing: {
        if (visibilities) {
            visibilities.launcherFilter = "";
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
        listItems = filteredApps.map(entry => ({
                    label: entry.name || "",
                    icon: entry.icon || ""
                }));
    }

    focusTimer.onTriggered: selectionList.forceActiveFocus()

    content: ColumnLayout {
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

                onEscapePressed: root.closePopup()

                onItemActivated: index => {
                    if (index >= 0 && index < root.filteredApps.length) {
                        root.filteredApps[index].execute();
                        root.closePopup();
                    }
                }
            }
        }

        // No results message
        StyledText {
            visible: root.filteredApps.length === 0 && root.filterText.length > 0
            Layout.alignment: Qt.AlignHCenter
            text: "No apps found"
            styledColor: Theme.overlay0
            styledSize: 13
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

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            refreshApps();  // data here now, refresh!
        }
    }
}
