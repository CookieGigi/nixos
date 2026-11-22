import QtQuick
import Quickshell
import Quickshell.Services.Greetd

// Greetd authentication state machine.
//
// Flow (see Quickshell.Services.Greetd docs):
//   createSession(user)
//     -> authMessage(responseRequired) -> respond(password)
//     -> readyToLaunch()                -> launch(session)
//   authFailure / error                 -> reset, show message
//
// Greetd expects the greeter to exit immediately after launch();
// launch() itself terminates quickshell (see the docs warning), so nothing
// should follow it.
Scope {
    id: root

    // Substituted by the derivation in quickshell/default.nix.
    readonly property string sessionCommand: "@niriSession@"
    readonly property string defaultUser: "@defaultUser@"

    readonly property bool available: Greetd.available

    property string userText: root.defaultUser
    property string passwordText: ""
    property bool authInProgress: false
    property bool showFailure: false
    property string failureMessage: ""

    // Any edit clears the previous failure.
    onUserTextChanged: root.showFailure = false
    onPasswordTextChanged: root.showFailure = false

    function tryLogin() {
        if (!root.available) {
            root.showFailure = true;
            root.failureMessage = "Not running under greetd";
            return;
        }
        if (root.authInProgress || root.userText.length === 0 || root.passwordText.length === 0)
            return;

        root.showFailure = false;
        root.authInProgress = true;
        Greetd.createSession(root.userText);
    }

    Connections {
        target: Greetd

        // Prompts that require a response get the entered password;
        // informational/error-only messages (e.g. fingerprint problems)
        // are surfaced without a prompt.
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                Greetd.respond(root.passwordText);
            } else if (error) {
                root.showFailure = true;
                root.failureMessage = message;
            }
        }

        function onAuthFailure(message) {
            root.authInProgress = false;
            root.passwordText = "";
            root.showFailure = true;
            root.failureMessage = message.length > 0 ? message : "Authentication failed";
        }

        function onError(error) {
            root.authInProgress = false;
            root.showFailure = true;
            root.failureMessage = error;
        }

        function onReadyToLaunch() {
            // Must be the greeter's last action: greetd kills the greeter
            // once the session is acknowledged.
            Greetd.launch([root.sessionCommand]);
        }
    }
}
