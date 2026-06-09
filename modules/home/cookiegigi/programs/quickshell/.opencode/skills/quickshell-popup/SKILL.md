---
name: quickshell-popup
description: >
  This skill should be used when creating a new popup or editing an existing popup
  in the quickshell bar. Covers the per-popup architecture, visibility control,
  keyboard handling, and the patterns needed to add launchers, menus, or panels.
---

# Quickshell Popup Creator

## Architecture Overview

The quickshell bar uses a **per-popup architecture** where each popup is self-contained:

- **PopupBase** — `PanelWindow` with `isOpen` property, `PopupKeyController` keyboard controller, and a hidden `TextInput` for typing
- **PopupKeyController** — Per-popup instance. Handles `Escape`, `Enter`, `Up`, `Down`. Emits signals for navigation. All other keys fall through to native `TextInput` (copy/paste, cursor movement, IME preserved)
- **PopupRegistry** — Singleton phone book. `register(screen, id, popup)` + `toggle(screen, id)` (closes all other popups on the same screen first)
- **PopupShell** — Styled frame. Only `Escape` is accepted locally. Other keys propagate up to `PopupBase` and then to the hidden `TextInput`

## Keyboard Flow

1. Popup opens → `onVisibleChanged` → `hiddenInput.forceActiveFocus()`
2. User presses a key → `hiddenInput.Keys.onPressed` → `keyController.handleKey(event)`
3. `handleKey()` intercepts only `Escape`, `Enter`, `Up`, `Down` and sets `event.accepted = true`
4. All other keys (typing, copy/paste, cursor movement) fall through to native `TextInput` handling
5. `PopupKeyController` emits signals → `SelectionList` responds (`incrementCurrent`, `decrementCurrent`, `activateCurrent`)

## Adding a New Popup

### Step 1: Create the popup file

Place the new popup in `popups/<Name>.qml`. Inherit from `PopupBase`. Set `popupId` to a unique string.

### Step 2: Wire the popup in Bar.qml

Instantiate the popup inside the `PanelWindow` with a unique `id`. Pass it to `WindowTitleWidget.popups` if it should be tracked by the center widget. Register it with `PopupRegistry` in `Component.onCompleted`.

```qml
// modules/Bar.qml
MyPopup {
    id: myPopup
    screen: modelData
    popupId: "myPopup"
    anchorWidget: myWidget
    alignment: "center"
}

WindowTitleWidget {
    popups: [appLauncher, powerMenu, networkMenu, myPopup]
}

Component.onCompleted: {
    PopupRegistry.register(modelData, "myPopup", myPopup);
}
```

### Step 3: Add an IPC handler (optional)

If the popup should be keyboard-toggleable from niri, add an `IpcHandler` in `shell.qml`:

```qml
IpcHandler {
    target: "myPopup"
    function toggle(): void {
        const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
        PopupRegistry.toggle(screen, "myPopup");
    }
}
```

Bind the niri key in the niri config: `Mod+X { spawn "qs" "-c" "bar" "ipc" "call" "myPopup" "toggle"; }`

### Step 4: Add a toggle widget (optional)

```qml
Button {
    onClicked: {
        PopupRegistry.toggleMyPopup(screen);  // or PopupRegistry.toggle(screen, "myPopup")
    }
}
```

## Popup Patterns

### Pattern A: Display-only popup

No keyboard interaction, no search. Just displays static content.

```qml
// popups/InfoPanel.qml
PopupBase {
    id: root
    popupId: "infoPanel"
    title: "Info Panel"
    popupWidth: 300
    content: ColumnLayout {
        anchors { fill: parent; margins: 12 }
        StyledText { text: "Hello" }
    }
}
```

### Pattern B: List with keyboard navigation

Use `SelectionList` for a keyboard-navigable list. Connect `PopupKeyController` signals on `Component.onCompleted`.

```qml
// popups/ActionMenu.qml
PopupBase {
    id: root
    popupId: "actionMenu"
    title: "Actions"
    popupWidth: 200

    property var actions: [
        { label: "Action 1", cmd: ["cmd1"] },
        { label: "Action 2", cmd: ["cmd2"] }
    ]

    onOpened: {
        menuList.currentIndex = 0;
    }

    Component.onCompleted: {
        controller.navigateDown.connect(menuList.incrementCurrent);
        controller.navigateUp.connect(menuList.decrementCurrent);
        controller.activate.connect(menuList.activateCurrent);
    }

    content: ColumnLayout {
        anchors { fill: parent; margins: 12 }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            SelectionList {
                id: menuList
                anchors.fill: parent
                items: root.actions.map(a => ({ label: a.label }))
                onEscapePressed: root.closePopup()
                onItemActivated: index => {
                    const action = root.actions[index];
                    if (action && action.cmd)
                        Quickshell.execDetached(action.cmd);
                    root.closePopup();
                }
            }
        }
    }
}
```

### Pattern C: Search + list

Same as Pattern B. The hidden `TextInput` in `PopupBase` already handles typing. `filterText` binds to `controller.searchText`.

```qml
// popups/SearchableMenu.qml
PopupBase {
    id: root
    popupId: "searchableMenu"
    popupWidth: 500

    property string filterText: controller.searchText
    onFilterTextChanged: applyFilter()

    property var allItems: []
    property var filteredItems: []
    property var listItems: []

    onOpened: {
        controller.searchText = "";
        refreshItems();
    }

    onClosing: {
        controller.searchText = "";
    }

    Component.onCompleted: {
        controller.navigateDown.connect(selectionList.incrementCurrent);
        controller.navigateUp.connect(selectionList.decrementCurrent);
        controller.activate.connect(selectionList.activateCurrent);
    }

    function refreshItems() {
        // load allItems from some source
        applyFilter();
    }

    function applyFilter() {
        const q = filterText.toLowerCase();
        filteredItems = allItems.filter(item =>
            (item.name || "").toLowerCase().includes(q)
        );
        listItems = filteredItems.map(item => ({
            label: item.name || "",
            icon: item.icon || ""
        }));
    }

    content: ColumnLayout {
        anchors { fill: parent; margins: 12 }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            SelectionList {
                id: selectionList
                anchors.fill: parent
                items: root.listItems
                onEscapePressed: root.closePopup()
                onItemActivated: index => {
                    // activate filteredItems[index]
                    root.closePopup();
                }
            }
        }
        StyledText {
            visible: root.filteredItems.length === 0 && root.filterText.length > 0
            Layout.alignment: Qt.AlignHCenter
            text: "No items found"
        }
    }
}
```

## PopupBase Reference

### Properties
- `popupId: string` — Unique identifier, must match `PopupRegistry.register()`
- `isOpen: bool` — Visibility state. Set to `true` to open, `false` to close.
- `popupWidth: int` — Width of the popup (default 500)
- `title: string` — Title displayed in `WindowTitleWidget` when open
- `anchorWidget: Item` — Widget to anchor the popup under (for left/right/center alignment)
- `alignment: string` — `"left"`, `"center"`, `"right"` relative to `anchorWidget`
- `content: alias` — Children of the `PopupShell` frame (put your popup UI here)
- `controller: PopupKeyController` — Keyboard controller instance

### Signals
- `opened()` — Emitted when popup becomes visible
- `closing()` — Emitted when popup becomes hidden

### Methods
- `closePopup()` — Sets `isOpen = false`

## PopupKeyController Reference

### Properties
- `searchText: string` — Text from the hidden `TextInput`. Bind to `filterText` for search popups.
- `popupTitle: string` — Set automatically from `PopupBase.title`

### Signals
- `navigateDown` — Down arrow pressed
- `navigateUp` — Up arrow pressed
- `activate` — Enter/Return pressed
- `close` — Escape pressed
- `searchTextChanged` — `searchText` property changed

### Methods
- `handleKey(event)` — Call from `Keys.onPressed`. Intercepts only 4 keys; all others fall through.

## WindowTitleWidget Integration

When a popup is listed in `WindowTitleWidget.popups`, the center widget:
1. Shows `activePopup.title` instead of the window title when any popup is open
2. Shows a search input when `popupId === "launcher"` is open
3. Binds the search input bidirectionally to `activePopup.controller.searchText`

To show a popup title in the center widget, set `title` on the popup:
```qml
PopupBase {
    title: "My Menu"
}
```

## Common Pitfalls

1. **Swapped arguments in `PopupRegistry.toggle()`** — The signature is `toggle(screen, id)`, NOT `toggle(id, screen)`. Use the convenience methods (`toggleLauncher`, `togglePower`, `toggleNetwork`) to avoid this.
2. **Keyboard not working** — Ensure `PopupBase.hiddenInput` has `Keys.onPressed` wired to `keyController.handleKey(event)`. `PopupShell` alone does not receive focus.
3. **Title not reactive** — Use `activePopup.title` instead of `PopupRegistry.getActivePopupTitle()` for reactive bindings. The latter reads through plain JS objects which are not reactive.
4. **No `focus: true` on `SelectionList`** — The list does not need `focus: true` because `PopupBase` focuses `hiddenInput` instead. The `PopupKeyController` signals drive the list.
5. **Missing `Component.onCompleted` signal connections** — `SelectionList` must be connected to `controller.navigateDown/Up/activate` in `Component.onCompleted` or `onOpened`.
6. **Forgetting to register with `PopupRegistry`** — Unregistered popups are invisible to IPC and `WindowTitleWidget`.

## File Locations

- `popups/` — Popup implementations
- `components/PopupBase.qml` — Base popup window
- `components/PopupKeyController.qml` — Per-popup keyboard controller
- `components/PopupShell.qml` — Styled popup frame
- `services/PopupRegistry.qml` — Singleton popup registry
- `widgets/WindowTitleWidget.qml` — Center widget that tracks popups
- `modules/Bar.qml` — Per-monitor bar that instantiates popups
- `shell.qml` — IPC handlers
