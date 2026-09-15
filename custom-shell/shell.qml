import QtQuick
import Quickshell

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
