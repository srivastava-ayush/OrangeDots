import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: root
    property var anchorWindow: null
    property color bgColor: "#e616161c"
    property color fgColor: "white"
    property color accent: "#0a84ff"

    visible: false
    color: "transparent"

    anchors { top: true; right: true }
    margins { top: 36; right: 8 }
    implicitWidth: 340

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "macos-bar-cc"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        id: grab
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    // macOS-style control center card
    Rectangle {
        id: card
        anchors.fill: parent
        color: root.bgColor
        radius: 20
        border.color: "#26ffffff"
        border.width: 1

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 16
            anchors.bottomMargin: 14
            spacing: 12

            Text {
                text: "Control Center"
                color: root.fgColor
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            // ---- Connectivity tile grid (2x2, macOS style) ----
            GridLayout {
                columns: 2
                rowSpacing: 8
                columnSpacing: 8
                Layout.fillWidth: true

                ToggleTile {
                    label: "Wi-Fi"
                    icon: "\uf1eb"
                    accent: root.accent
                    active: true
                    onClicked: Quickshell.execDetached(["nmcli", "radio", "wifi", active ? "off" : "on"])
                }
                ToggleTile {
                    label: "Bluetooth"
                    icon: "\uf293"
                    accent: root.accent
                    active: false
                    onClicked: Quickshell.execDetached(["bluetoothctl", "power", active ? "off" : "on"])
                }
                ToggleTile {
                    label: "Focus"
                    icon: "\uf0f3"
                    iconActive: "\uf0f3"
                    accent: root.accent
                    active: false
                    onClicked: Quickshell.execDetached(["makoctl", "mode", "-t", "do-not-disturb"])
                }
                ToggleTile {
                    label: "Night Light"
                    icon: "\uf186"
                    accent: root.accent
                    active: false
                    onClicked: Quickshell.execDetached(["hyprctl", "hyprsunset", "toggle"])
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#26ffffff" }

            // ---- Sound ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Text { text: "\uf028"; color: root.fgColor; font.pixelSize: 15 }
                SliderControl {
                    id: volSlider
                    Layout.fillWidth: true
                    accent: root.accent
                    from: 0; to: 100; value: 60
                    onMoved: Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (value / 100).toString()])
                }
            }

            // ---- Display brightness ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Text { text: "\uf185"; color: root.fgColor; font.pixelSize: 15 }
                SliderControl {
                    id: brightSlider
                    Layout.fillWidth: true
                    accent: root.accent
                    from: 0; to: 100; value: 80
                    onMoved: Quickshell.execDetached(["brightnessctl", "set", value + "%"])
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#26ffffff" }

            // ---- Power row ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PowerButton {
                    icon: "\uf023"; label: "Lock"; accent: root.accent
                    onClicked: Quickshell.execDetached(["hyprlock"])
                }
                PowerButton {
                    icon: "\uf186"; label: "Sleep"; accent: root.accent
                    onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                }
                PowerButton {
                    icon: "\uf164"; label: "Power"; accent: "#ff453a"
                    onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }
        }
    }
}