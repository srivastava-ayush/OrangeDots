import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Modules as Modules

PanelWindow {
    id: bar

    // ---- macOS menu bar dimensions ----
    readonly property int barHeight: 28
    readonly property color bgColor: "#9e16161c"      // translucent dark, vibrancy-like
    readonly property color fgColor: "#ffffff"
    readonly property color accent: "#0a84ff"          // macOS blue
    readonly property color hoverColor: "#26ffffff"

    anchors { top: true; left: true; right: true }
    exclusiveZone: barHeight
    implicitHeight: barHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.namespace: "macos-bar"

    // Full-width macOS-style bar with a hairline bottom border
    Rectangle {
        anchors.fill: parent
        color: bar.bgColor
        border.color: "#2effffff"
        border.width: 1

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: "#26ffffff"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 10

            // ---------------- LEFT ----------------
            Modules.AppMenu {
                fgColor: bar.fgColor
                hoverColor: bar.hoverColor
            }

            Modules.Workspaces {
                fgColor: bar.fgColor
                accent: bar.accent
            }

            Item { Layout.fillWidth: true }

            // ---------------- RIGHT ----------------
            RowLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Modules.Tray {
                    fgColor: bar.fgColor
                    hoverColor: bar.hoverColor
                }

                Modules.Battery {
                    fgColor: bar.fgColor
                    hoverColor: bar.hoverColor
                }

                Modules.Clock {
                    fgColor: bar.fgColor
                    hoverColor: bar.hoverColor
                }

                Modules.ControlCenterToggle {
                    fgColor: bar.fgColor
                    hoverColor: bar.hoverColor
                    onToggled: controlCenter.visible = !controlCenter.visible
                }
            }
        }
    }

    // Popup floats below the bar, right-aligned like macOS
    Modules.ControlCenter {
        id: controlCenter
        anchorWindow: bar
        bgColor: bar.bgColor
        fgColor: bar.fgColor
        accent: bar.accent
    }
}