import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../theme"

// App launcher popup with search and keyboard navigation.
PopupBase {
    id: root

    popupId: "launcher"
    popupWidth: 500

    property string filterText: controller.searchText
    onFilterTextChanged: applyFilter()

    property var allApps: []
    property var filteredApps: []
    property var listItems: []

    property int maxItems: 10

    // Denylist: hide these apps.
    property var denylist: ["kvantum", "gvim", "nvidia", "foot client", "foot server", "chromium"]

    implicitHeight: Math.min(400, (selectionList.count < maxItems ? selectionList.count : maxItems) * 36 + 48)

    onOpened: {
        refreshApps();
        controller.searchText = "";
    }

    onClosing: {
        controller.searchText = "";
    }

    Component.onCompleted: {
        controller.navigateDown.connect(selectionList.incrementCurrent);
        controller.navigateUp.connect(selectionList.decrementCurrent);
        controller.activate.connect(selectionList.activateCurrent);
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
        listItems = filteredApps.map(entry => ({
                    label: entry.name || "",
                    icon: entry.icon || ""
                }));
    }

    content: ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

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

        StyledText {
            visible: root.filteredApps.length === 0 && root.filterText.length > 0
            Layout.alignment: Qt.AlignHCenter
            text: "No apps found"
            styledColor: Theme.text
            styledSize: 13
        }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            refreshApps();
        }
    }
}
