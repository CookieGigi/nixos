import "../components"
import "../theme"

PopupBase {
    id: root
    title: "Network Menu"
    popupId: "networkMenu"
    popupWidth: 250

    anchorLeft: false
    anchorRight: true

    content: StyledText {
        text: "Test"
    }
}
