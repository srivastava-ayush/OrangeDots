import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

GridLayout {
    id: root

    required property color colour
    required property int parentSpacing

    columns: Taskbar.horizontal ? 2 : 1
    rows: Taskbar.horizontal ? 1 : 2
    columnSpacing: parentSpacing
    rowSpacing: parentSpacing

    Item {
        visible: Hypr.capsLock
        implicitWidth: capslockIcon.implicitWidth
        implicitHeight: capslockIcon.implicitHeight

        MaterialIcon {
            id: capslockIcon

            anchors.centerIn: parent

            scale: Hypr.capsLock ? 1 : 0.5
            opacity: Hypr.capsLock ? 1 : 0

            text: "keyboard_capslock_badge"
            color: root.colour
            fill: 1
            grade: 25

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    Item {
        visible: Hypr.numLock
        implicitWidth: numlockIcon.implicitWidth
        implicitHeight: numlockIcon.implicitHeight

        MaterialIcon {
            id: numlockIcon

            anchors.centerIn: parent

            scale: Hypr.numLock ? 1 : 0.5
            opacity: Hypr.numLock ? 1 : 0

            text: "looks_one"
            color: root.colour
            fill: 1
            grade: 25

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }
    }
}
