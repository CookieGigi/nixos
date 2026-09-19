# Notification Center

The bell beside the clock and prayer widgets opens a per-monitor notification
center. It follows the bar's Macchiato palette, teal accents, translucent panel,
and JetBrains Mono typography. Critical notifications have peach borders.

## Controls

- The bell count shows active notifications, not unread history.
- **Active** shows current notifications, with individual dismissal and application actions.
- **Dismiss all** moves active notifications into Mako history.
- **History** shows recently dismissed or expired notifications.
- **Restore** brings back the latest history entry, as supported by Mako.
- The **mute/unmute bell** in the header hides or enables Mako popups without
  discarding notifications; its tooltip describes the action.
- Escape closes the center; left/right switches tabs; up/down scrolls the list.
- The list also supports pointer scrolling and a scrollbar.

The installed bar exposes an IPC toggle:

```sh
qs -c bar ipc call notifications toggle
```

## Backend

Mako remains the notification server and toast renderer. A shared Quickshell
singleton reads `makoctl list -j`, `history -j`, and `mode`. It refreshes every
five seconds when closed, every second while a center is open, and immediately
on opening or completing an action. Notification text is rendered as plain text,
not executable markup or externally loaded images.

History is bounded to 100 entries in the declarative Mako configuration. It is
session-only and disappears when Mako restarts; this adds no persistent state.
History actions are intentionally unavailable until a notification is restored.
The center does not implement deletion of individual history entries because
Mako does not expose that operation through `makoctl`.

## Preview And Activation

From this worktree, preview the bar with:

```sh
qs -p modules/home/cookiegigi/programs/quickshell/shell.qml
```

This launches another bar; stop the preview with Ctrl-C. It reads the same Mako
state as the installed bar, so dismissals and application actions are real.
Quiet mode and the larger history limit require applying the changed Nix
configuration first. No rebuild is performed by the preview command.

## Verification

- QML formatted with `qmlformat`.
- Popup exercised under Wayland with fixture notifications, including action
  buttons, history switching, quiet-mode indicator, width clamping, and lifecycle.
- Isolated D-Bus/Mako integration exercised notification receipt, dismissal,
  history, restoration, quiet-mode toggling, and dismiss-all without touching
  the desktop session's notifications.
- Home Manager Mako settings and generated configuration evaluated with Nix.

Application-specific action handling still needs testing with real applications.
Standalone `qmllint` could not resolve the environment's Qt/Quickshell imports;
runtime loading was used to validate the QML instead.
