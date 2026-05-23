import QtQuick
import QtQuick.Layouts
import Quickshell

// A fixed-width app launcher popup anchored below the center widget.
PopupWindow {
    id: root

    property string filterText: ""
    property var allApps: []
    property var filteredApps: []
    property int selectedIndex: 0

    // Denylist: hide these apps.
    property var denylist: ["kvantum", "gvim"]

    // Fixed size, centered below the bar center widget.
    implicitWidth: 500
    implicitHeight: Math.min(400, listView.count * 36 + searchInput.implicitHeight + 24)
    color: "transparent"

    grabFocus: true

    // Anchor below the center widget (set dynamically from Bar.qml).
    // The parentWindow and relative position will be configured in Bar.qml.

    // Close when the compositor clears the grab (outside click, etc.).
    onGrabFocusChanged: {
        if (!grabFocus) {
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
        // Sort alphabetically by name.
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
        selectedIndex = 0;
        listView.positionViewAtBeginning();
    }

    function launchSelected() {
        if (filteredApps.length > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.length) {
            filteredApps[selectedIndex].execute();
            closeLauncher();
        }
    }

    function closeLauncher() {
        root.visible = false;
        filterText = "";
        searchInput.text = "";
        applyFilter();
    }

    function openLauncher() {
        refreshApps();
        filterText = "";
        searchInput.text = "";
        selectedIndex = 0;
        root.visible = true;
        focusTimer.start();
    }

    Component.onCompleted: refreshApps()

    // Main container.
    Rectangle {
        anchors.fill: parent
        color: "#24273a"
        radius: 12
        border.width: 2
        border.color: "#8bd5ca"

        // Global fallback key handler on the root rectangle.
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.closeLauncher();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 8

            // Search input field.
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: searchInput.implicitHeight + 12
                color: "#363a4f"
                radius: 8
                border.width: searchInput.activeFocus ? 2 : 0
                border.color: "#8bd5ca"

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
                        family: "monospace"
                        pixelSize: 14
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
                            root.launchSelected();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            if (root.selectedIndex < root.filteredApps.length - 1) {
                                root.selectedIndex++;
                                listView.positionViewAtIndex(root.selectedIndex, ListView.Center);
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            if (root.selectedIndex > 0) {
                                root.selectedIndex--;
                                listView.positionViewAtIndex(root.selectedIndex, ListView.Center);
                            }
                            event.accepted = true;
                        }
                    }
                }
            }

            // App list.
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.filteredApps
                spacing: 2

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: listView.width
                    implicitHeight: itemText.implicitHeight + 14
                    radius: 6
                    color: index === root.selectedIndex ? "#494d64" : "transparent"

                    Text {
                        id: itemText
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: 10
                        }
                        text: modelData.name || ""
                        color: index === root.selectedIndex ? "#8bd5ca" : "#cad3f5"
                        font {
                            family: "monospace"
                            pixelSize: 13
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selectedIndex = index
                        onClicked: {
                            root.selectedIndex = index;
                            root.launchSelected();
                        }
                    }
                }

                // No results message.
                Text {
                    visible: root.filteredApps.length === 0 && root.filterText.length > 0
                    anchors.centerIn: parent
                    text: "No apps found"
                    color: "#6e738d"
                    font {
                        family: "monospace"
                        pixelSize: 13
                    }
                }
            }
        }
    }

    // Delay focus request slightly so the window is fully shown first.
    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }
}
