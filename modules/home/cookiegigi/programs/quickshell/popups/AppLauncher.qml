import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../theme"

// App launcher popup with search and keyboard navigation.
PopupWindow {
    id: root

    property var visibilities: null

    property string filterText: ""
    property var allApps: []
    property var filteredApps: []
    property var listItems: []

    // Denylist: hide these apps.
    property var denylist: ["kvantum", "gvim"]

    visible: visibilities ? visibilities.launcher : false
    grabFocus: true

    implicitWidth: 500
    implicitHeight: Math.min(400, selectionList.count * 36 + searchBox.implicitHeight + 48)
    color: "transparent"

    onVisibleChanged: {
        if (visible) {
            refreshApps();
            filterText = "";
            searchInput.text = "";
            searchInput.forceActiveFocus();
            focusTimer.start();
        } else {
            closeLauncher();
        }
    }

    onGrabFocusChanged: {
        if (!grabFocus && visible) {
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
        }
        filterText = "";
        searchInput.text = "";
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

            // Search input
            Rectangle {
                id: searchBox
                Layout.fillWidth: true
                implicitHeight: searchInput.implicitHeight + 12
                color: Theme.surface0
                radius: 8
                border.width: searchInput.activeFocus ? 2 : 0
                border.color: Theme.teal

                TextInput {
                    id: searchInput
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                        topMargin: 6
                        bottomMargin: 6
                    }
                    text: root.filterText
                    color: "#ffffff"
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.pixelSize
                    }
                    focus: true
                    activeFocusOnTab: true
                    cursorVisible: true

                    onTextChanged: {
                        root.filterText = text;
                        root.applyFilter();
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            root.closeLauncher();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            selectionList.activateCurrent();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            selectionList.incrementCurrent();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            selectionList.decrementCurrent();
                            event.accepted = true;
                        }
                    }
                }
            }

            // App list
            SelectionList {
                id: selectionList
                Layout.fillWidth: true
                Layout.fillHeight: true
                items: root.listItems

                onEscapePressed: root.closeLauncher()

                onItemActivated: (index) => {
                    if (index >= 0 && index < root.filteredApps.length) {
                        root.filteredApps[index].execute();
                        root.closeLauncher();
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

    // Delay focus request slightly so the window is fully shown first
    Timer {
        id: focusTimer
        interval: 100
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }
}
